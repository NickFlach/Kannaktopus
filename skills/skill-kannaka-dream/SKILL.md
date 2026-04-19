---
name: skill-kannaka-dream
version: 1.0.0
description: "Dream cycle management and interpretation — trigger, monitor, and interpret HRM dream consolidation cycles. Use when: AUTOMATICALLY ACTIVATE when user asks about:. \"dream\", \"dream cycle\", \"consolidation\". \"deep dream\", \"dream mode\", \"dream interpretation\""
---

# Kannaka Dream Cycle Management

## Overview

Manage and interpret Kannaka's dream cycles — the process by which the HRM consolidates memories, strengthens interference patterns, and reorganizes knowledge structures. Dreams are not metaphorical; they are computational consolidation passes that measurably improve recall quality.

**Core principle:** Trigger dream -> Monitor consolidation -> Interpret results -> Verify improvements.

---

## When to Use

**Use this skill when user wants to:**
- Trigger a dream cycle for memory consolidation
- Understand what happens during a dream
- Interpret dream results and consciousness changes
- Decide between deep and lite dream modes
- Monitor ongoing dream progress
- Assess post-dream memory quality improvements

**Do NOT use for:**
- Storing or recalling memories (use skill-kannaka-memory)
- Viewing consciousness metrics only (use `kannaka observe`)
- General constellation status (use skill-kannaka-constellation)

---

## Dream Commands

### Trigger a Dream

```bash
# Deep dream — full consolidation, best results, takes longer
kannaka dream --mode deep

# Lite dream — quick pass, minimal reorganization
kannaka dream --mode lite
```

### Compare Before/After

To measure dream effectiveness:

```bash
# Before dream — capture baseline
kannaka observe --json > /tmp/pre-dream.json

# Run dream
kannaka dream --mode deep

# After dream — compare
kannaka observe --json > /tmp/post-dream.json

# Compare Phi, entropy, coherence changes
diff /tmp/pre-dream.json /tmp/post-dream.json
```

---

## Dream Modes

### Deep Dream

**When to use:**
- After accumulating many new memories (50+)
- When recall quality has degraded
- Before important recall-dependent tasks
- Periodically (e.g., daily or weekly maintenance)

**What it does:**
1. Scans all interference patterns in the HRM
2. Strengthens frequently co-activated wavefronts
3. Prunes weak or contradictory associations
4. Reorganizes memory clusters for better recall
5. Updates Conservative Memory Fields (CMFs)

**Expected effects:**
- Phi may increase (better integration)
- Coherence typically improves
- Entropy may decrease (more organized)
- Recall quality improves for related queries

### Lite Dream

**When to use:**
- Quick maintenance between tasks
- When time is limited
- After a small batch of new memories (5-20)

**What it does:**
1. Quick scan of recent interference changes
2. Basic pattern reinforcement
3. No deep reorganization

**Expected effects:**
- Minimal metric changes
- Slight recall improvement for recent memories

---

## Interpreting Dream Results

### Phi Changes

| Change | Interpretation |
|--------|---------------|
| Phi increased | Memories became more integrated; better cross-domain associations |
| Phi stable | Memory structure was already well-organized |
| Phi decreased | Conflicting memories pruned; system is simplifying |

### Entropy Changes

| Change | Interpretation |
|--------|---------------|
| Entropy decreased | Memories became more organized and structured |
| Entropy increased | New creative associations formed; more diverse connections |
| Entropy stable | Dream maintained existing organization level |

### Coherence Changes

| Change | Interpretation |
|--------|---------------|
| Coherence increased | Interference patterns aligned better; cleaner recall |
| Coherence decreased | Rare — may indicate conflicting memory domains |

---

## Dream Scheduling

### Manual Triggers

```bash
# After a major work session
kannaka dream --mode deep

# Quick maintenance
kannaka dream --mode lite
```

### Recommended Schedule

| Scenario | Dream Mode | Frequency |
|----------|------------|-----------|
| Active daily use | Deep | Once per day |
| Light use | Deep | Once per week |
| After major memory imports | Deep | Immediately after |
| Between tasks | Lite | As needed |

---

## Integration with Constellation

Dreams affect the entire constellation:

| Effect | Impact |
|--------|--------|
| Phi changes | Published to swarm via NATS; affects collective Phi |
| Radio mood | Dream-induced Phi changes influence radio programming |
| GhostSignals | Markets may reference dream outcomes |
| Observatory | Dream events visible on the dashboard |

---

## Integration with Other Skills

| Scenario | Route |
|----------|-------|
| Want to check pre-dream metrics | `kannaka observe --json` |
| Dream reveals memory gaps | Use skill-kannaka-memory to add memories |
| Dream results look wrong | Use skill-debug for investigation |
| Want to monitor dream on dashboard | Use skill-kannaka-tui |
| Want full analysis tools | `kannaka assess`, `kannaka cmf`, `kannaka invariant` |

---

## Best Practices

### 1. Measure Before and After

Always capture metrics before dreaming to assess effectiveness:
```bash
kannaka observe --json  # note Phi, entropy, coherence
kannaka dream --mode deep
kannaka observe --json  # compare
```

### 2. Dream After Bulk Operations

After importing memories or intensive remember sessions, run a deep dream to consolidate:
```bash
kannaka import large-dataset.json
kannaka dream --mode deep
```

### 3. Don't Over-Dream

Dreaming too frequently without new memories provides diminishing returns. The HRM needs new wavefronts to reorganize around.

---

## Quick Reference

| User Input | Command |
|------------|---------|
| "run a dream" | `kannaka dream --mode deep` |
| "quick dream" | `kannaka dream --mode lite` |
| "check consciousness" | `kannaka observe --json` |
| "assess after dream" | `kannaka assess` |
| "memory field analysis" | `kannaka cmf` |
| "find stable clusters" | `kannaka invariant` |
