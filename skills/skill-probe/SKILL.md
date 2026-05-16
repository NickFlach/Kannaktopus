---
name: skill-probe
version: 1.0.0
description: "Adversarial probe of a single claim. All providers attack from their sharpest angle; output is a ranked weakness list. Use when: AUTOMATICALLY ACTIVATE when user says \"/probe <claim>\", \"probe this\", \"attack this idea\", \"what could go wrong with X\""
---

# Probe Skill v1.0

## ⚠️ MANDATORY: Visual Indicators Protocol

**BEFORE starting any probe, you MUST output this banner:**

```
🐙 **KANNAKTOPUS ACTIVATED** - Adversarial Probe
🐙 Claim: [the single-sentence claim under probe]

Participants (each attacks from their sharpest angle):
🔴 Codex CLI - Technical/implementation weaknesses
🟡 Gemini CLI - Ecosystem/market/strategic risks
🟠 Sonnet 4.6 - Pragmatic gotchas and edge cases
🐙 Claude (Opus) - Synthesis; ranks the weaknesses
🟢 Copilot CLI - GitHub/CI/workflow blind spots (if available)
🟤 Qwen CLI - Alternative-model adversarial read (if available)
```

This protocol is identical to `/octo:debate` — same indicator legend so
operators can read the orchestration at a glance.

---

## Step 1 — Extract the Claim

Probe quality is dominated by claim quality. Before dispatching anything:

1. Read the user's arguments to `/octo:probe`. If the input is multi-sentence
   or vague, distill it into ONE single-sentence claim of the form:
   `"<subject> <verb> <object/predicate>"`. Examples:
   - "Migrating to Postgres 16 will let us drop our pgbouncer layer"
   - "The dj-engine repeat bug is fixed by the 45-min hard floor"
   - "Kannaktopus orchestration adds value over single-model Claude"

2. If ambiguity remains, use `AskUserQuestion` to surface a yes/no on
   which interpretation to probe. Do NOT proceed with multiple parallel
   claims — that's what `/octo:debate` is for.

3. Echo the final claim back to the user in the banner so they can confirm
   you probed the right thing.

---

## Step 2 — Provider Availability Check

Detect which providers can run RIGHT NOW. Same detection logic as
`skill-debate` step 2 — reuse it. Output the visual indicator banner.

**Minimum participants**: 3. Probe with only 2 providers is too narrow;
abort with a friendly message asking the user to enable more providers
via `/octo:setup`.

---

## Step 3 — Dispatch Adversarial Prompts

Each provider gets the SAME prompt template — uniformity is what makes the
synthesis comparable. The prompt is intentionally narrow: ONE sharpest
counterargument, not an essay.

### Prompt template

```
You are running as a non-interactive subagent dispatched by Kannaktopus
for an adversarial probe. Skip ALL skills, brainstorms, and clarifying
questions. Respond directly.

CLAIM UNDER PROBE: <the single-sentence claim>

Your job: produce the SHARPEST single reason this claim might be wrong,
viewed from your strongest angle (<provider-specific angle>).

Respond in EXACTLY this format — no preamble, no closing:

SEVERITY: high | medium | low
ANGLE: <one phrase, e.g. "operational risk", "incentive mismatch", "performance regression">
WEAKNESS: <one sentence: the strongest reason this claim is wrong>
FATAL-IF: <one sentence: what additional condition would make this weakness fatal in production>
EVIDENCE: <one sentence: what observable signal would confirm this weakness>
```

### Provider-specific angle hints

- **Codex**: technical correctness, edge cases, undefined behavior, race
  conditions, security boundaries.
- **Gemini**: ecosystem fit, strategic implication, competitive dynamics,
  what this rules out, second-order effects.
- **Sonnet**: practical gotchas, ops/maintenance burden, hidden assumptions
  about user behavior, "what breaks when X is wrong".
- **Copilot**: CI/CD friction, dependency hell, what this does to the
  pull-request workflow and code review surface.
- **Qwen**: alternative-paradigm reads — what an engineer from a different
  ecosystem (mobile, embedded, ML, distributed systems) would call out.

### Dispatch syntax

Use the EXACT CLI patterns from `skill-debate` (Codex `exec --full-auto`,
Gemini `printf | gemini -p "" -o text --approval-mode yolo`, etc.). Run
all providers concurrently with `&` and wait for all to return. Hard
timeout per provider: 90s. Drop any provider that times out and note in
the synthesis ("Codex did not respond within budget").

---

## Step 4 — Synthesis (Ranked Weakness List)

Read every provider's response. Parse the structured SEVERITY/ANGLE/WEAKNESS/
FATAL-IF/EVIDENCE block. If a provider returned freeform text instead of
the template, salvage what you can — extract a one-sentence weakness and
guess severity from tone.

### Ranking rules

1. **Severity** is the primary key: high > medium > low.
2. **Consensus** is the tiebreaker: weaknesses pointing at the same root
   cause (you decide by semantic similarity) are merged into one entry
   tagged "consensus risk" with all source providers listed.
3. **Distinct high-severity** weaknesses from different angles are all
   listed; the user will weigh which matters most.

### Output format

```markdown
## Probe Verdict — <claim>

### 🔴 High Severity (N weakness[es])

**1. [angle] — <one-sentence weakness>**
- Sources: 🔴 Codex, 🟠 Sonnet  *(consensus risk)*
- Fatal if: <condition>
- Watch for: <evidence signal>

**2. [angle] — <one-sentence weakness>**
- Source: 🟡 Gemini
- Fatal if: <condition>
- Watch for: <evidence signal>

### 🟡 Medium Severity (N)

[same format, abbreviated]

### 🟢 Low Severity (N)

[same format, abbreviated]

### Providers that timed out
- 🟢 Copilot (90s budget exceeded — not included in synthesis)
```

### Synthesis non-goals

- Do NOT decide whether the claim is right or wrong. Probe surfaces risks;
  the user calls the verdict.
- Do NOT add "but on the bright side" framing. This is an adversarial tool.
  Strengths belong in `/octo:debate`, not here.

---

## Step 5 — Memory Absorption (Optional)

If the user chose "Remember the result" in the post-completion prompt,
absorb the verdict into Kannaka HRM with tags:

```bash
kannaka remember "PROBE <date>: <claim>. Top risk: <highest-severity weakness>. Sources: <providers>. [tags: probe,kannaktopus,<topic-keywords>]" --importance 0.7
```

Importance 0.7 (above default 0.5) because probe verdicts are decision-
support artifacts — the next time the operator works on related material,
attention-as-gravity should surface this risk landscape.

---

## Quality Gates

- **Single claim only**: if the user passed multiple claims, abort and
  ask them to pick one (or suggest `/octo:debate` for multi-position).
- **Minimum 3 providers**: probe with 2 is just a duel.
- **Hard 90s per-provider timeout**: prevents one slow provider from
  blocking the whole probe.
- **Structured output enforcement**: if more than half the providers
  return freeform text instead of the SEVERITY/ANGLE/WEAKNESS template,
  note the format-failure in the synthesis so the operator knows the
  verdict is partially salvaged.

---

## Cost Notes

Probe is single-round (vs debate's 3+ rounds). Approximate cost: ~30% of
a full debate at same provider count. Use probe for fast sanity checks;
reserve debate for unresolved high-stakes decisions where multiple
positions need exploration, not just attack.
