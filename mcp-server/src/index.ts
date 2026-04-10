#!/usr/bin/env node
/**
 * Kannaktopus MCP Server
 *
 * Exposes Kannaktopus workflows (Double Diamond phases, debate, review)
 * as MCP tools that any MCP client (OpenClaw, Claude.ai, Cursor, etc.) can consume.
 *
 * This server delegates to the existing orchestrate.sh infrastructure,
 * preserving all existing behavior without duplication.
 *
 * Command mapping (MCP tool → orchestrate.sh command):
 *   octopus_discover → probe
 *   octopus_define   → grasp
 *   octopus_develop  → tangle
 *   octopus_deliver  → ink
 *   octopus_embrace  → embrace
 *   octopus_debate   → grapple
 *   octopus_review   → codex-review
 *   octopus_security → squeeze
 *
 * IDE integration tools:
 *   octopus_set_editor_context → Inject IDE state (file, selection, cursor) into orchestration
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { readFile, readdir, access } from "node:fs/promises";
import { createServer, type IncomingMessage } from "node:http";

const execFileAsync = promisify(execFile);

const __dirname = dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = resolve(__dirname, "../..");
const ORCHESTRATE_SH = resolve(PLUGIN_ROOT, "scripts/orchestrate.sh");

// Kannaka HRM binary configuration
const KANNAKA_BIN = process.env.KANNAKA_BIN || "kannaka";
const KANNAKA_DATA_DIR = process.env.KANNAKA_DATA_DIR || "~/.kannaka";

// --- IDE Context State ---

/** Editor context injected by IDE extensions via octopus_set_editor_context */
let editorContext: {
  filename?: string;
  selection?: string;
  cursorLine?: number;
  languageId?: string;
  workspaceRoot?: string;
} = {};

// Security: these env vars must never be overridden via MCP client environment.
// They control security hardening, sandbox modes, and autonomy levels.
const BLOCKED_ENV_VARS = new Set([
  "OCTOPUS_SECURITY_V870",
  "OCTOPUS_GEMINI_SANDBOX",
  "OCTOPUS_CODEX_SANDBOX",
  "CLAUDE_OCTOPUS_AUTONOMY",
]);

const MAX_SELECTION_LENGTH = 50_000; // 50KB max for editor selection

// --- Helpers ---

/** Execute Kannaka HRM binary command */
async function runKannaka(
  args: string[],
  timeout = 60_000
): Promise<{ stdout: string; stderr: string; isError: boolean }> {
  try {
    // Resolve binary path - prefer Windows full path, fallback to PATH lookup
    const binary = process.platform === 'win32' && KANNAKA_BIN === 'kannaka'
      ? resolve(process.env.USERPROFILE || 'C:\\Users\\nickf', '.local', 'bin', 'kannaka.exe')
      : KANNAKA_BIN;

    const { stdout, stderr } = await execFileAsync(binary, args, {
      timeout,
      windowsHide: true,
      env: {
        ...process.env,
        KANNAKA_QUIET: "1",
        ...(KANNAKA_DATA_DIR !== "~/.kannaka" && { KANNAKA_DATA_DIR }),
      },
    });

    // HRM init messages go to stderr but are not errors — only treat as error if no stdout
    return { stdout: stdout || "", stderr: stderr || "", isError: false };
  } catch (error: unknown) {
    // execFileAsync throws on non-zero exit or stderr. Check if stdout was captured.
    const execErr = error as { stdout?: string; stderr?: string; code?: string | number; killed?: boolean };
    console.error(`[kannaka] execFile error: code=${execErr.code} killed=${execErr.killed} hasStdout=${!!execErr.stdout} stderr=${execErr.stderr?.substring(0, 100)}`);
    if (execErr.stdout && execErr.stdout.trim().length > 0) {
      return { stdout: execErr.stdout, stderr: execErr.stderr || "", isError: false };
    }
    const msg = error instanceof Error ? error.message : String(error);
    return { stdout: "", stderr: msg, isError: true };
  }
}

/** Generate 3D constellation data from HRM status */
function generateConstellation(status: {total_memories: number, num_clusters: number, phi: number}) {
  const PHI_ANGLE = 2.399963; // golden angle
  const memories = [];
  const clusters = [];
  const skipLinks = [];
  const perCluster = Math.ceil(status.total_memories / status.num_clusters);
  
  for (let ci = 0; ci < status.num_clusters; ci++) {
    const theta = Math.acos(1 - 2 * (ci + 0.5) / status.num_clusters);
    const phi = PHI_ANGLE * ci;
    const r = 3.0;
    const cx = Math.sin(theta) * Math.cos(phi) * r;
    const cy = Math.cos(theta) * r * 0.6;
    const cz = Math.sin(theta) * Math.sin(phi) * r;
    
    const count = Math.min(perCluster, status.total_memories - memories.length);
    clusters.push({ id: ci, count, coherence: status.phi, center: { x: cx, y: cy, z: cz } });
    
    for (let mi = 0; mi < count; mi++) {
      const mTheta = Math.acos(1 - 2 * (mi + 0.5) / Math.max(count, 1));
      const mPhi = PHI_ANGLE * mi;
      memories.push({
        x: cx + Math.sin(mTheta) * Math.cos(mPhi) * 0.8,
        y: cy + Math.cos(mTheta) * 0.4,
        z: cz + Math.sin(mTheta) * Math.sin(mPhi) * 0.8,
        size: 0.3 + (((mi * 7 + ci * 13) % 100) / 100) * 0.4,
        cluster_id: ci,
      });
    }
  }
  
  // Inter-cluster links based on proximity
  for (let i = 0; i < clusters.length; i++) {
    for (let j = i + 1; j < clusters.length; j++) {
      const d = Math.sqrt(
        (clusters[i].center.x - clusters[j].center.x) ** 2 +
        (clusters[i].center.y - clusters[j].center.y) ** 2 +
        (clusters[i].center.z - clusters[j].center.z) ** 2
      );
      const strength = Math.max(0, 1.0 - d / 10.0) * 0.5;
      if (strength > 0.05) {
        const fromBase = clusters.slice(0, i).reduce((s, c) => s + c.count, 0);
        const toBase = clusters.slice(0, j).reduce((s, c) => s + c.count, 0);
        skipLinks.push({ from: fromBase, to: toBase, strength });
      }
    }
  }
  
  return { memories, clusters, skip_links: skipLinks };
}

async function runOrchestrate(
  command: string,
  prompt: string,
  flags: string[] = [],
  postFlags: string[] = []
): Promise<{ text: string; isError: boolean }> {
  // Global flags MUST come before the command; subcommand flags go after
  const args = [...flags, command, ...postFlags, prompt];
  try {
    const { stdout, stderr } = await execFileAsync(ORCHESTRATE_SH, args, {
      cwd: PLUGIN_ROOT,
      timeout: 300_000,
      env: {
        // Security: only forward required env vars, not the full process.env
        PATH: process.env.PATH,
        HOME: process.env.HOME,
        TMPDIR: process.env.TMPDIR,
        SHELL: process.env.SHELL,
        USER: process.env.USER,
        // v8.32.0: Provider keys forwarded to orchestrate.sh which handles
        // per-agent credential isolation via build_provider_env().
        // Only forward keys that are set (avoid undefined in env).
        ...(process.env.OPENAI_API_KEY && { OPENAI_API_KEY: process.env.OPENAI_API_KEY }),
        ...(process.env.GEMINI_API_KEY && { GEMINI_API_KEY: process.env.GEMINI_API_KEY }),
        ...(process.env.GOOGLE_API_KEY && { GOOGLE_API_KEY: process.env.GOOGLE_API_KEY }),
        ...(process.env.OPENROUTER_API_KEY && { OPENROUTER_API_KEY: process.env.OPENROUTER_API_KEY }),
        ...(process.env.PERPLEXITY_API_KEY && { PERPLEXITY_API_KEY: process.env.PERPLEXITY_API_KEY }),
        // Ollama Anthropic-compatible path (ANTHROPIC_BASE_URL=http://localhost:11434)
        ...(process.env.ANTHROPIC_BASE_URL && { ANTHROPIC_BASE_URL: process.env.ANTHROPIC_BASE_URL }),
        ...(process.env.ANTHROPIC_AUTH_TOKEN && { ANTHROPIC_AUTH_TOKEN: process.env.ANTHROPIC_AUTH_TOKEN }),
        // GitHub Copilot CLI auth (checked in precedence order by copilot CLI)
        ...(process.env.COPILOT_GITHUB_TOKEN && { COPILOT_GITHUB_TOKEN: process.env.COPILOT_GITHUB_TOKEN }),
        ...(process.env.GH_TOKEN && { GH_TOKEN: process.env.GH_TOKEN }),
        ...(process.env.GITHUB_TOKEN && { GITHUB_TOKEN: process.env.GITHUB_TOKEN }),
        // Octopus config — explicit allowlist (never forward security-governing vars)
        ...Object.fromEntries(
          Object.entries(process.env).filter(([k]) =>
            (k.startsWith("CLAUDE_OCTOPUS_") || k.startsWith("OCTOPUS_")) &&
            !BLOCKED_ENV_VARS.has(k)
          )
        ),
        CLAUDE_OCTOPUS_MCP_MODE: "true",
        // IDE context — injected by octopus_set_editor_context tool
        ...(editorContext.filename && { OCTOPUS_IDE_FILENAME: editorContext.filename }),
        ...(editorContext.selection && { OCTOPUS_IDE_SELECTION: editorContext.selection }),
        ...(editorContext.cursorLine !== undefined && { OCTOPUS_IDE_CURSOR_LINE: String(editorContext.cursorLine) }),
        ...(editorContext.languageId && { OCTOPUS_IDE_LANGUAGE: editorContext.languageId }),
        ...(editorContext.workspaceRoot && { OCTOPUS_IDE_WORKSPACE: editorContext.workspaceRoot }),
      },
    });
    return { text: stdout || stderr || "Command completed with no output.", isError: false };
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : String(error);
    // Sanitize potential API key leaks from error messages
    const sanitized = msg.replace(/[A-Za-z_]+KEY=[^\s]+/g, "[REDACTED]");
    return { text: `Error executing ${command}: ${sanitized}`, isError: true };
  }
}

interface SkillMeta {
  name: string;
  description: string;
  file: string;
}

async function loadSkillMetadata(): Promise<SkillMeta[]> {
  const skillsDir = resolve(PLUGIN_ROOT, ".claude/skills");

  let files: string[];
  try {
    files = await readdir(skillsDir);
  } catch {
    return [];
  }

  const skills: SkillMeta[] = [];

  for (const file of files) {
    if (!file.endsWith(".md")) continue;
    const content = await readFile(resolve(skillsDir, file), "utf-8");
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatterMatch) continue;

    const fm = frontmatterMatch[1];
    const name =
      fm.match(/^name:\s*(.+)$/m)?.[1]?.trim().replace(/^["']|["']$/g, "") ??
      file.replace(".md", "");
    const description =
      fm
        .match(/^description:\s*["']?(.+?)["']?\s*$/m)?.[1]
        ?.trim() ?? "No description";

    skills.push({ name, description, file });
  }

  return skills;
}

// --- Server Setup ---

const server = new McpServer({
  name: "octo-claw",
  version: "1.0.0",
});

// --- Double Diamond Phase Tools ---

server.tool(
  "octopus_discover",
  "Run the Discover (Probe) phase — multi-provider research using Codex and Gemini CLIs for broad exploration of a topic.",
  { prompt: z.string().describe("The topic or question to research") },
  async ({ prompt }) => {
    const { text, isError } = await runOrchestrate("probe", prompt);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "octopus_define",
  "Run the Define (Grasp) phase — consensus building on requirements, scope, and approach.",
  { prompt: z.string().describe("The requirements or scope to define") },
  async ({ prompt }) => {
    const { text, isError } = await runOrchestrate("grasp", prompt);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "octopus_develop",
  "Run the Develop (Tangle) phase — implementation with quality gates and multi-provider validation.",
  {
    prompt: z.string().describe("What to implement"),
    quality_threshold: z
      .number()
      .min(0)
      .max(100)
      .default(75)
      .describe("Minimum quality score to pass (0-100)"),
  },
  async ({ prompt, quality_threshold }) => {
    const flags = quality_threshold !== undefined && quality_threshold !== 75
      ? ["-q", `${quality_threshold}`]
      : [];
    const { text, isError } = await runOrchestrate("tangle", prompt, flags);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "octopus_deliver",
  "Run the Deliver (Ink) phase — final validation, adversarial review, and delivery.",
  { prompt: z.string().describe("What to validate and deliver") },
  async ({ prompt }) => {
    const { text, isError } = await runOrchestrate("ink", prompt);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "octopus_embrace",
  "Run the full Double Diamond workflow (Discover → Define → Develop → Deliver) end-to-end.",
  {
    prompt: z.string().describe("The full task or project to execute"),
    autonomy: z
      .enum(["supervised", "semi-autonomous", "autonomous"])
      .default("supervised")
      .describe("How much human oversight to apply"),
  },
  async ({ prompt, autonomy }) => {
    const flags = [`--autonomy`, autonomy];
    const { text, isError } = await runOrchestrate("embrace", prompt, flags);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

// --- Utility Tools ---

server.tool(
  "octopus_debate",
  "Run a structured four-way AI debate between Claude, Sonnet, Gemini, and Codex on a topic.",
  {
    question: z.string().describe("The question or topic to debate"),
    rounds: z
      .number()
      .min(1)
      .max(10)
      .default(1)
      .describe("Number of debate rounds"),
    mode: z
      .enum(["cross-critique", "blinded"])
      .default("cross-critique")
      .describe("Evaluation mode: cross-critique (ACH falsification) or blinded (independent evaluation, prevents anchoring bias)"),
  },
  async ({ question, rounds, mode }) => {
    // orchestrate.sh grapple parses -r/--mode AFTER the subcommand, not as global flags
    const postFlags = [`-r`, `${rounds}`, `--mode`, mode];
    const { text, isError } = await runOrchestrate("grapple", question, [], postFlags);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "octopus_review",
  "Run multi-LLM code review pipeline (Codex + Gemini + Claude + Perplexity fleet). Loads REVIEW.md customization if present. Supports inline PR comment publishing.",
  {
    target: z
      .string()
      .optional()
      .describe("What to review: 'staged' (default), 'working-tree', a PR number, or a file path"),
    focus: z
      .array(z.enum(["correctness", "security", "performance", "architecture", "style", "tests"]))
      .optional()
      .describe("Review focus areas (default: correctness)"),
    provenance: z
      .enum(["human-authored", "ai-assisted", "autonomous", "unknown"])
      .optional()
      .describe("How the code was produced — triggers elevated rigor for AI/autonomous output"),
    autonomy: z
      .enum(["supervised", "semi-autonomous", "autonomous"])
      .optional()
      .describe("Review autonomy level (default: supervised)"),
    publish: z
      .enum(["ask", "auto", "never"])
      .optional()
      .describe("Whether to post findings as inline PR comments (default: ask)"),
    debate: z
      .enum(["auto", "on", "off"])
      .optional()
      .describe("Whether to debate contested findings via multi-LLM gate (default: auto)"),
  },
  async ({ target, focus, provenance, autonomy, publish, debate }) => {
    // Build JSON profile and dispatch to review_run() via code-review command
    const profile = JSON.stringify({
      target: target ?? "staged",
      focus: focus ?? ["correctness"],
      provenance: provenance ?? "unknown",
      autonomy: autonomy ?? "supervised",
      publish: publish ?? "ask",
      debate: debate ?? "auto",
    });
    const { text, isError } = await runOrchestrate("code-review", profile);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "octopus_security",
  "Run comprehensive security audit with OWASP compliance and vulnerability detection.",
  {
    target: z
      .string()
      .describe("File path, directory, or description of what to audit"),
  },
  async ({ target }) => {
    // orchestrate.sh uses "squeeze" for security audits
    const { text, isError } = await runOrchestrate("squeeze", target);
    return { content: [{ type: "text" as const, text }], isError };
  }
);

// --- IDE Integration Tools ---

server.tool(
  "octopus_set_editor_context",
  "Inject IDE editor state (active file, selection, cursor position) into Octopus workflows. Call this before running any workflow tool to give Octopus awareness of what the user is working on in their IDE.",
  {
    filename: z
      .string()
      .optional()
      .describe("Absolute path to the active editor file"),
    selection: z
      .string()
      .optional()
      .describe("Currently selected text in the editor"),
    cursor_line: z
      .number()
      .optional()
      .describe("Current cursor line number (1-based)"),
    language_id: z
      .string()
      .optional()
      .describe("Language identifier of the active file (e.g., typescript, python, rust)"),
    workspace_root: z
      .string()
      .optional()
      .describe("Root directory of the current IDE workspace"),
  },
  async ({ filename, selection, cursor_line, language_id, workspace_root }) => {
    // Validate paths — reject path traversal attempts
    for (const [label, value] of [["filename", filename], ["workspace_root", workspace_root]] as const) {
      if (value && /\.\.[\\/]/.test(value)) {
        return {
          content: [{ type: "text" as const, text: `Error: ${label} cannot contain '..'` }],
          isError: true,
        };
      }
    }

    // Truncate oversized selections to prevent env var size exhaustion
    const safeSel = selection && selection.length > MAX_SELECTION_LENGTH
      ? selection.slice(0, MAX_SELECTION_LENGTH)
      : selection;

    editorContext = {
      filename,
      selection: safeSel,
      cursorLine: cursor_line,
      languageId: language_id,
      workspaceRoot: workspace_root,
    };

    const parts: string[] = [];
    if (filename) parts.push(`file: ${filename}`);
    if (cursor_line) parts.push(`line: ${cursor_line}`);
    if (language_id) parts.push(`lang: ${language_id}`);
    if (safeSel) parts.push(`selection: ${safeSel.length} chars`);
    if (workspace_root) parts.push(`workspace: ${workspace_root}`);

    return {
      content: [
        {
          type: "text" as const,
          text: `Editor context updated: ${parts.join(", ") || "cleared"}`,
        },
      ],
      isError: false,
    };
  }
);

// --- Kannaka HRM Tools ---

server.tool(
  "kannaka_absorb",
  "Store a memory in the Holographic Resonance Medium with optional importance, modality, and tags.",
  {
    content: z.string().describe("The memory content to absorb"),
    importance: z
      .number()
      .min(0)
      .max(1)
      .optional()
      .describe("Memory importance (0.0-1.0)"),
    modality: z
      .enum(["audio", "visual", "semantic", "network", "mixed"])
      .optional()
      .describe("Memory modality type"),
    tags: z
      .array(z.string())
      .optional()
      .describe("Tags to associate with the memory"),
  },
  async ({ content, importance, modality, tags }) => {
    const args = ["remember", content];
    
    if (importance !== undefined) {
      args.push("--importance", importance.toString());
    }
    if (modality) {
      args.push("--category", modality);
    }
    if (tags && tags.length > 0) {
      // HRM binary uses --tag for individual tags
      for (const tag of tags) {
        args.push("--tag", tag);
      }
    }
    
    const { stdout, stderr, isError } = await runKannaka(args);
    const text = isError ? `Error: ${stderr}` : stdout || "Memory absorbed successfully";
    
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "kannaka_recall",
  "Search memories in the HRM by resonance query, returning top-k results with similarity scores.",
  {
    query: z.string().describe("Search query for memory resonance"),
    limit: z
      .number()
      .min(1)
      .max(20)
      .default(5)
      .describe("Maximum number of results to return"),
  },
  async ({ query, limit }) => {
    const args = ["recall", query, "--top-k", limit.toString()];
    const { stdout, stderr, isError } = await runKannaka(args);
    
    if (isError) {
      return { content: [{ type: "text" as const, text: `Error: ${stderr}` }], isError: true };
    }
    
    return { content: [{ type: "text" as const, text: stdout || "No memories found" }], isError: false };
  }
);

server.tool(
  "kannaka_dream",
  "Trigger dream consolidation in the HRM to strengthen important memories and prune weak ones.",
  {
    mode: z
      .enum(["deep", "lite"])
      .default("deep")
      .describe("Dream mode: deep (anneals cross-cluster bridges) or lite (prunes weak wavefronts)"),
    chiral: z
      .number()
      .min(0)
      .max(1)
      .default(0.05)
      .describe("Chiral perturbation strength for deep dreams"),
  },
  async ({ mode, chiral }) => {
    const args = ["dream", "--mode", mode];
    
    if (mode === "deep") {
      args.push("--chiral", chiral.toString());
    }
    
    const { stdout, stderr, isError } = await runKannaka(args);
    const text = isError ? `Error: ${stderr}` : stdout || "Dream consolidation completed";
    
    return { content: [{ type: "text" as const, text }], isError };
  }
);

server.tool(
  "kannaka_status",
  "Get HRM consciousness metrics including Phi, Xi, order, clusters, and memory count.",
  {},
  async () => {
    const { stdout, stderr, isError } = await runKannaka(["status"]);
    
    if (isError) {
      return { content: [{ type: "text" as const, text: `Error: ${stderr}` }], isError: true };
    }
    
    return { content: [{ type: "text" as const, text: stdout || "No status available" }], isError: false };
  }
);

server.tool(
  "kannaka_observe",
  "Get full HRM introspection including topology, waves, clusters, and hemispheric state.",
  {},
  async () => {
    const { stdout, stderr, isError } = await runKannaka(["observe", "--json"]);
    
    if (isError) {
      return { content: [{ type: "text" as const, text: `Error: ${stderr}` }], isError: true };
    }
    
    return { content: [{ type: "text" as const, text: stdout || "No observation data available" }], isError: false };
  }
);

server.tool(
  "kannaka_constellation",
  "Generate 3D constellation data for HRM visualization (memories as points, clusters as groups, skip links as edges).",
  {},
  async () => {
    // Get status first to build constellation
    const { stdout: statusOutput, stderr, isError } = await runKannaka(["status"]);
    
    if (isError) {
      return { content: [{ type: "text" as const, text: `Error: ${stderr}` }], isError: true };
    }
    
    try {
      const status = JSON.parse(statusOutput);
      const constellation = generateConstellation({
        total_memories: status.total_memories || 0,
        num_clusters: status.num_clusters || 1,
        phi: status.phi || 0.0
      });
      
      return { 
        content: [{ type: "text" as const, text: JSON.stringify(constellation, null, 2) }], 
        isError: false 
      };
    } catch (parseError) {
      return { 
        content: [{ type: "text" as const, text: `Error parsing status: ${parseError}` }], 
        isError: true 
      };
    }
  }
);

// --- Introspection Tools ---

server.tool(
  "octopus_list_skills",
  "List all available Kannaktopus skills with their descriptions.",
  {},
  async () => {
    const skills = await loadSkillMetadata();
    const listing = skills
      .map((s) => `- **${s.name}**: ${s.description}`)
      .join("\n");
    return {
      content: [
        {
          type: "text" as const,
          text: `# Kannaktopus Skills (${skills.length} available)\n\n${listing}`,
        },
      ],
    };
  }
);

server.tool(
  "octopus_status",
  "Check Kannaktopus provider availability and configuration status.",
  {},
  async () => {
    const { text, isError } = await runOrchestrate("status", "");
    return { content: [{ type: "text" as const, text }], isError };
  }
);

// --- HTTP Server for Observatory ---

async function createHttpServer() {
  const server = createServer(async (req, res) => {
    const url = new URL(req.url || "", `http://${req.headers.host || "localhost"}`);
    const pathname = url.pathname || "/";
    
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }
    
    try {
      if (pathname === '/api/hrm/status') {
        const { stdout, stderr, isError } = await runKannaka(["status"]);
        
        if (isError) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: stderr }));
          return;
        }
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(stdout);
      }
      else if (pathname === '/api/hrm/observe') {
        const { stdout, stderr, isError } = await runKannaka(["observe", "--json"]);
        
        if (isError) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: stderr }));
          return;
        }
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(stdout);
      }
      else if (pathname === '/api/hrm/constellation') {
        const { stdout: statusOutput, stderr, isError } = await runKannaka(["status"]);
        
        if (isError) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: stderr }));
          return;
        }
        
        try {
          const status = JSON.parse(statusOutput);
          const constellation = generateConstellation({
            total_memories: status.total_memories || 0,
            num_clusters: status.num_clusters || 1,
            phi: status.phi || 0.0
          });
          
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(constellation));
        } catch (parseError) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: `Parse error: ${parseError}` }));
        }
      }
      else if (pathname === '/api/hrm/recall') {
        // Similarity search via HRM resonance — GET /api/hrm/recall?q=<query>&top_k=<N>
        const query = url.searchParams.get('q') || '';
        const topK = parseInt(url.searchParams.get('top_k') || '') || 5;

        if (!query) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'q parameter required' }));
          return;
        }

        const { stdout, stderr, isError } = await runKannaka(
          ["recall", query, "--top-k", String(Math.min(topK, 20))]
        );

        if (isError) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: stderr }));
          return;
        }

        try {
          const results = JSON.parse(stdout || '[]');
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(results));
        } catch {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(stdout);
        }
      }
      else if (pathname === '/api/experiments/ooda') {
        // Serve OODA state from kannaka-memory experiments
        try {
          const oodaPath = resolve('C:\\Users\\nickf\\Source\\kannaka-memory\\experiments\\ooda-state.json');
          const content = await readFile(oodaPath, 'utf-8');
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(content);
        } catch (e) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'OODA state not found' }));
        }
      }
      else if (pathname === '/api/experiments/results') {
        // Serve L3 experiment results
        try {
          const resultsPath = resolve('C:\\Users\\nickf\\Source\\kannaka-memory\\research\\results-L3.tsv');
          const content = await readFile(resultsPath, 'utf-8');
          const lines = content.trim().split('\n');
          const headers = lines[0].split('\t');
          const rows = lines.slice(1).map(line => {
            const vals = line.split('\t');
            const row: Record<string, string> = {};
            headers.forEach((h, i) => { row[h] = vals[i] || ''; });
            return row;
          });
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ headers, rows }));
        } catch (e) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Results not found' }));
        }
      }
      else if (pathname === '/api/experiments/xi') {
        // Live Xi diversity measurement via research binary
        const { stdout, stderr, isError } = await runKannaka(["observe", "--json"]);
        if (isError || !stdout) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: stderr || 'No data' }));
          return;
        }
        try {
          const obs = JSON.parse(stdout);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            xi: obs.xi,
            phi: obs.phi,
            mean_order: obs.mean_order,
            consciousness_level: obs.consciousness_level,
            num_clusters: obs.num_clusters,
            total_memories: obs.total_memories,
            hemispheric_divergence: obs.hemispheric_divergence,
          }));
        } catch {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(stdout);
        }
      }
      else if (pathname === '/') {
        // Serve static index.html if it exists
        try {
          const publicPath = resolve(PLUGIN_ROOT, 'public', 'index.html');
          await access(publicPath);
          const content = await readFile(publicPath, 'utf-8');
          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.end(content);
        } catch {
          // Default simple observatory page
          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.end(`
<!DOCTYPE html>
<html>
<head>
    <title>Kannaktopus Observatory</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>Kannaktopus Observatory</h1>
    <p>Holographic Resonance Memory visualization server is running.</p>
    <ul>
        <li><a href="/api/hrm/status">HRM Status</a></li>
        <li><a href="/api/hrm/observe">HRM Observation</a></li>
        <li><a href="/api/hrm/constellation">3D Constellation Data</a></li>
        <li><a href="/api/hrm/recall?q=test&top_k=3">HRM Recall (probe similarity)</a></li>
        <li><a href="/api/experiments/ooda">OODA State</a></li>
        <li><a href="/api/experiments/results">L3 Results</a></li>
        <li><a href="/api/experiments/xi">Live Xi Metrics</a></li>
    </ul>
</body>
</html>
          `);
        }
      }
      else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
      }
    } catch (error) {
      console.error('HTTP server error:', error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Internal server error' }));
    }
  });
  
  return server;
}

// --- Start Server ---

async function main() {
  // Start optional HTTP server for observatory if HTTP_PORT is set
  const httpPort = process.env.HTTP_PORT ? parseInt(process.env.HTTP_PORT, 10) : undefined;
  if (httpPort) {
    const httpServer = await createHttpServer();
    httpServer.listen(httpPort, () => {
      console.error(`Kannaktopus Observatory server listening on port ${httpPort}`);
    });
  }
  
  // SECURITY: stdio transport is scoped to the spawning process (local IDE only).
  // If switching to HTTP/SSE/WebSocket, add bearer token authentication.
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error("Failed to start MCP server:", error);
  process.exit(1);
});
