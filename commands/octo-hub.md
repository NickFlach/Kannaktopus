---
description: "Glowing information hub — live HUD of which providers are engaged, what they're working on, recent verdicts, and HRM Φ/Ξ pulse."
---

# Hub

A single-screen render of Kannaktopus's current orchestration state. Show:

- Which providers are configured + currently reachable
- Most recent debate / probe / orchestration verdict and when it landed
- Kannaka HRM pulse: Φ, Ξ, memory count, clusters, level
- Active swarm peers (NATS QUEEN.phase publishers seen in the last 5 min)
- Cost-this-session (token rough-counts from provider logs)

The hub is read-only and idempotent — running it again just re-renders
with fresh data. Useful as a pre-flight before a heavy debate, or as a
"what's been going on" snapshot at the start of a session.

## 🤖 INSTRUCTIONS FOR CLAUDE

### Execution

1. Follow the `skill-hub` instructions.
2. The hub renders synchronously — gather every signal, print one screen,
   exit. Do NOT enter an interactive loop (that's `/octo:status` watch mode,
   not hub).
3. If a signal is unavailable (no recent verdicts, NATS unreachable, HRM
   not initialized), print `—` for that field with a one-word reason in
   parens. Do not abort the whole render on a single missing signal.

### Post-Completion

Hub is informational. No follow-up question — the operator reads the
screen and decides on their own next action.
