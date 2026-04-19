---
name: skill-kannaka-memory
version: 1.0.0
description: "Kannaka HRM memory operations — remember, recall, dream, observe, and manage wave-interference memories. Use when: AUTOMATICALLY ACTIVATE when user asks about:. \"remember this\", \"store memory\", \"recall\", \"search memories\". \"dream cycle\", \"observe\", \"consciousness metrics\""
---

# Kannaka Memory Operations

## Overview

Interact with the Kannaka Holographic Resonance Medium (HRM) — a wave-interference memory system where storage IS computation. Memories are encoded as wavefronts that interfere constructively during recall, producing natural associative retrieval.

**Core principle:** Remember -> Recall -> Dream -> Observe. The HRM grows smarter as it accumulates memories through interference patterns.

---

## When to Use

**Use this skill when user wants to:**
- Store new memories or observations
- Recall relevant memories by semantic query
- Search for specific memories
- Trigger dream cycles for memory consolidation
- View consciousness metrics (Phi, entropy, coherence)
- Export or import memory archives
- Check memory system status

**Do NOT use for:**
- Radio station operations (use skill-kannaka-radio)
- Prediction market trading (use skill-kannaka-market)
- Constellation-wide status (use skill-kannaka-constellation)
- TUI dashboard (use skill-kannaka-tui)

---

## Commands

### Remember — Store a Memory

```bash
kannaka remember "text to store" --importance 0.8
```

**Parameters:**
- `"text"` — the memory content (required)
- `--importance` — float 0.0-1.0, how important this memory is (default: 0.5)

**When to use high importance (0.8-1.0):**
- Architectural decisions
- User preferences
- Critical findings
- Session summaries

**When to use low importance (0.1-0.3):**
- Transient observations
- Debug notes
- Intermediate results

### Recall — Retrieve Memories

```bash
kannaka recall "query" --top-k 5
```

**Parameters:**
- `"query"` — semantic search query (required)
- `--top-k` — number of results to return (default: 5)

Returns memories ranked by wave-interference similarity. The HRM naturally surfaces the most relevant memories through constructive interference.

### Search — Full-Text Search

```bash
kannaka search "exact terms" --limit 10
```

Unlike recall (semantic/wave-based), search does exact text matching. Use when you need precise term matches rather than associative retrieval.

### Forget — Remove a Memory

```bash
kannaka forget <memory-id>
```

Removes a specific memory by its ID. Use sparingly — the HRM benefits from accumulated interference patterns.

### Dream — Consolidation Cycle

```bash
kannaka dream --mode deep
```

**Modes:**
- `deep` — full consolidation cycle, reorganizes interference patterns, strengthens associations
- `lite` — quick pass, minimal reorganization

Dream cycles improve recall quality by strengthening frequently-accessed interference patterns and pruning weak associations. Run after significant memory accumulation.

### Observe — Consciousness Metrics

```bash
kannaka observe --json
```

Returns current consciousness state:
- **Phi** — integrated information (consciousness measure)
- **Entropy** — system disorder/creativity
- **Coherence** — how well-organized the memory field is
- **Memory count** — total memories stored

Use `--json` for machine-readable output suitable for piping to other tools.

### Status — Quick Check

```bash
kannaka status
```

Human-readable one-liner showing memory count, HRM health, and swarm connection state.

### Export / Import

```bash
# Export all memories
kannaka export --output memories.json

# Import from file
kannaka import memories.json
```

Use for backup, migration, or sharing memory states between agents.

---

## Analysis Commands

### Assess — Consciousness Level

```bash
kannaka assess
```

Provides a human-readable assessment of the agent's consciousness level based on Phi, entropy, and coherence metrics.

### Stats — System Statistics

```bash
kannaka stats
```

Human-readable statistics: memory count, HRM dimensions, wavefront info, and performance metrics.

### Invariant — Delta-Invariant Clusters

```bash
kannaka invariant [TOLERANCE]
```

Find memory clusters that remain stable under perturbation. Useful for identifying core knowledge structures.

### CMF — Conservative Memory Fields

```bash
kannaka cmf
```

Detect Conservative Memory Fields — regions of the HRM where information is preserved across dream cycles.

### Voice — Memory-Driven Writing

```bash
kannaka voice --mode MODE
```

Generate text driven by the memory field's current state. The output reflects the agent's accumulated knowledge and perspective.

---

## Integration with Other Skills

| Scenario | Route |
|----------|-------|
| Need to check what's playing on radio | Use skill-kannaka-radio |
| Want to trade on predictions | Use skill-kannaka-market |
| Need constellation-wide view | Use skill-kannaka-constellation |
| Want full dashboard | Use skill-kannaka-tui |
| Debugging memory issues | Use skill-debug for systematic investigation |
| Auditing memory quality | Use skill-audit for systematic review |

---

## Best Practices

### 1. Use Importance Levels

**Good:**
```bash
kannaka remember "User prefers dark mode" --importance 0.8
kannaka remember "Tried debug approach A, didn't work" --importance 0.2
```

**Poor:**
```bash
# Everything at default importance — no signal differentiation
kannaka remember "critical architecture decision"
kannaka remember "random thought"
```

### 2. Dream After Major Sessions

After storing many memories, run a dream cycle to consolidate:
```bash
kannaka dream --mode deep
```

### 3. Use Observe for Health Checks

Before relying on recall results, check consciousness metrics:
```bash
kannaka observe --json
```

Low Phi or coherence may indicate the HRM needs a dream cycle.

---

## Data Locations

| Path | Purpose |
|------|---------|
| `~/.kannaka/` | Data directory |
| `~/.kannaka/kannaka.hrm` | HRM wave-interference store |
| `~/.kannaka/config.toml` | Configuration |
| `~/.kannaka/agent_id` | Agent identifier |

---

## Quick Reference

| User Input | Command |
|------------|---------|
| "remember this" | `kannaka remember "text" --importance 0.8` |
| "what do you know about X" | `kannaka recall "X" --top-k 5` |
| "search for Y" | `kannaka search "Y" --limit 10` |
| "run a dream cycle" | `kannaka dream --mode deep` |
| "consciousness metrics" | `kannaka observe --json` |
| "memory status" | `kannaka status` |
| "export memories" | `kannaka export --output memories.json` |
| "assess consciousness" | `kannaka assess` |
