---
description: "Probe a claim — point all providers at one assertion and surface the strongest reasons it might be wrong, ranked by severity."
---

# Probe

Adversarial sanity check on a single claim. All available providers attack
the assertion from their best angle and return their sharpest counterargument.
Claude synthesizes into a ranked weakness list so you can see — at a glance —
which way the claim is most likely to break.

Use when you've drafted a decision, a plan, or a statement and want a single
honed second opinion (not a four-way meandering debate). Faster than
`/octo:debate`, sharper than `/octo:think`.

## 🤖 INSTRUCTIONS FOR CLAUDE

### MANDATORY COMPLIANCE — DO NOT SKIP

**When the user invokes `/octo:probe`, you MUST execute the probe workflow
below.** You are PROHIBITED from answering the question directly or skipping
the multi-provider attack. The whole point of probe is that the user wants
*adversarial* perspectives surfaced before they commit.

---

### Execution

1. Follow the `skill-probe` instructions exactly.
2. Step 1: extract the claim from the user's arguments. If ambiguous, ask
   one clarifying question via AskUserQuestion (do NOT proceed without a
   crisp single-sentence claim — probe quality depends on probe target).
3. Step 2: check provider availability and display the indicator banner.
4. Step 3: dispatch the same adversarial prompt to all available providers
   (Codex, Gemini, Sonnet, Claude, optional Copilot / Qwen / OpenRouter).
   Each provider returns ONE strongest counterargument with severity (high
   / medium / low) and an "what would make this fatal" hypothesis.
5. Step 4: synthesize results into a single ranked weakness list. Each
   weakness gets one line: severity badge, one-sentence claim, source
   provider(s). High-severity weaknesses found by 2+ providers are flagged
   as "consensus risk".
6. Step 5: surface the synthesis to the user. Do NOT recommend a decision
   — the user makes the call after seeing the weaknesses.

### Post-Completion — Interactive Next Steps

**CRITICAL: After the probe completes, you MUST ask the user what to do next.**

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Probe complete. What now?",
      header: "Next Steps",
      multiSelect: false,
      options: [
        {label: "Probe the strongest weakness", description: "Run a second probe targeted at the top-ranked risk to see if it really is fatal"},
        {label: "Debate the claim", description: "Run /octo:debate to explore the claim from multiple positions, not just adversarially"},
        {label: "Remember the result", description: "Absorb the probe verdict into Kannaka HRM as a tagged memory so future work can recall this risk landscape"},
        {label: "Act on it anyway", description: "I've seen the weaknesses; proceeding with the original claim"},
        {label: "Drop the claim", description: "Weaknesses are fatal; abandoning"}
      ]
    }
  ]
})
```

### Cost & Scope

Probe is a single round per provider (not a debate's 3+ rounds). Cost is
roughly 1/3 of a full debate. If the user wants depth, suggest piping the
top-ranked weakness back through `/octo:probe` as a second-order check.
