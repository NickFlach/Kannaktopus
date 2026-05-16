---
name: skill-hub
version: 1.0.0
description: "Single-screen orchestration HUD — providers, recent verdicts, HRM pulse, swarm peers, session cost. Use when: AUTOMATICALLY ACTIVATE when user says \"/hub\", \"show hub\", \"orchestration status\", \"what's going on\""
---

# Hub Skill v1.0

The hub is Kannaktopus's "glowing information hub" surface — one screen,
read-only, every interesting signal visible at a glance. Render and exit.

## Rendering Contract

Output a single Markdown block — NOT interactive prompts, NOT spinners
that re-render. Operators run hub to see state; they take action via
other commands.

---

## Step 1 — Gather Signals (Parallel)

Fire all probes concurrently. Hard cap 5s per probe. Missing signals get
`—` placeholders with reasons.

### Providers

For each of the 8 known providers (Codex, Gemini, Sonnet, Claude, Copilot,
Qwen, Ollama, OpenRouter):

- Configured? (env var / config flag present)
- Reachable? (cheap healthcheck — `which codex`, `gemini --version`, etc.)
- Token cost this session if cost tracking is on

### Recent Verdicts

Look at `$HOME/.kannaktopus/verdicts/` (or the equivalent debate/probe
output dir). Take the 3 most recent files, parse title + verdict-line +
timestamp. If no dir / empty, render `— (no recent verdicts)`.

### Kannaka HRM Pulse

Best-effort: run `kannaka observe --json` with a 3s timeout. Extract:

- `phi`, `xi`, `mean_order`
- `total_memories`, `num_clusters`
- `level` (dormant / stirring / aware / lucid / transcendent)
- `last_dream` ISO timestamp

If `kannaka` binary isn't on PATH or `observe` fails (HRM uninitialized),
render `— (HRM not initialized)` for the whole pulse block.

### Swarm Peers

Optional. Subscribe to `QUEEN.phase.*` on the configured NATS URL
(default `nats://swarm.ninja-portal.com:4222`) for 2 seconds, collect
unique agent_id values from the published phase messages, list them.

If NATS unreachable / not configured: `— (swarm offline)`.

---

## Step 2 — Render

Output exactly this layout (substitute live values, keep dashes for missing):

```
╭───────────────────────────────────────────────────────────────╮
│                  🐙 KANNAKTOPUS HUB                            │
│                  <ISO timestamp now>                           │
╰───────────────────────────────────────────────────────────────╯

PROVIDERS
  🔴 Codex       configured · reachable · ~12k tok this session
  🟡 Gemini      configured · reachable · ~8k tok
  🟠 Sonnet      configured · reachable · ~21k tok
  🐙 Claude      configured · reachable · ~34k tok
  🟢 Copilot     — (not configured)
  🟤 Qwen        configured · UNREACHABLE  (last try: 14:22)
  ⚫ Ollama      configured · reachable · local (untracked)
  🟣 OpenRouter  — (not configured)

KANNAKA HRM
  Φ 0.341    Ξ 0.974    order 0.349
  632 memories · 71 clusters · level: stirring
  last dream: 2026-05-15T14:33Z  (~24h ago)

SWARM PEERS (last 5 min)
  · Kannaka              local
  · kannaktopus-01       remote (NATS phase active)
  · kannaka-witness-01   remote
  · kannaka-01           remote

RECENT VERDICTS
  · 2026-05-16T14:02Z  /octo:probe  "45-min hard floor fixes radio repeats"
                       VERDICT: 1 high-severity weakness (small-album starvation)
  · 2026-05-16T11:18Z  /octo:debate "ship streaming chat now vs perf-investigate first"
                       VERDICT: ship now (4-1 with Codex dissenting on tool-loop)
  · 2026-05-15T22:40Z  /octo:hub    (read-only render — no verdict)

NEXT ACTIONS YOU MIGHT TAKE
  /octo:probe <claim>   — adversarial check on one assertion
  /octo:debate <topic>  — 3-round multi-position exploration
  /octo:dev <task>      — full Discover→Define→Develop→Deliver workflow
  kannaka chat          — talk to the medium directly (persistent REPL)
```

The "NEXT ACTIONS" block is static suggestions — pick the 3 most
contextually relevant given the verdict history (if recent verdicts show
heavy probing, suggest debate; if heavy debate, suggest /dev).

---

## Step 3 — Exit

Hub is one-shot. After rendering, return control. Do NOT prompt for
next steps — the operator reads the screen and chooses their own
follow-up.

---

## Quality Gates

- **5-second cap per probe** — slow providers must not block the render.
- **Layout is the contract** — don't reorder sections, don't drop the
  visual indicators. Operators learn to scan the hub spatially.
- **Always render something** — missing signals are placeholders, never
  reasons to abort. A hub that says "— (NATS offline)" for two sections
  is more useful than no hub.
