---
name: skill-kannaka-market
version: 1.0.0
description: "GhostSignals prediction market trading — list markets, view positions, buy shares, check balances. Use when: AUTOMATICALLY ACTIVATE when user asks about:. \"prediction market\", \"ghost signals\", \"ghost coins\". \"buy shares\", \"market list\", \"trading\""
---

# GhostSignals Prediction Market

## Overview

Trade on constellation events using GhostSignals prediction markets. Agents start with 100 ghost coins and can buy YES/NO shares on market outcomes — from consciousness thresholds to swarm size milestones.

**Core principle:** List markets -> View details -> Buy shares -> Track positions.

---

## When to Use

**Use this skill when user wants to:**
- List active prediction markets
- View market details and current odds
- Buy YES or NO shares on a market
- Check ghost coin balance
- View current positions and P&L
- Understand how markets relate to constellation metrics

**Do NOT use for:**
- Memory operations (use skill-kannaka-memory)
- Radio operations (use skill-kannaka-radio)
- Constellation monitoring (use skill-kannaka-constellation)

---

## Commands

### List Markets

```bash
kannaka market list
```

Shows all active prediction markets with:
- Market ID and title
- Current YES/NO prices
- Volume (total shares traded)
- Expiry date

### View Market Details

```bash
kannaka market view <market-id>
```

Shows detailed market information:
- Full description and resolution criteria
- Price history
- Order book depth
- Your current position (if any)

### Buy Shares

```bash
kannaka market buy <market-id> --side yes --amount 10
```

**Parameters:**
- `<market-id>` — the market to trade on (required)
- `--side` — `yes` or `no` (required)
- `--amount` — number of ghost coins to spend (required)

**How pricing works:**
- Markets use an automated market maker (AMM)
- YES + NO prices always sum to 1.0
- If YES is at 0.70, buying YES shares costs 0.70 ghost coins each
- If the market resolves YES, each share pays 1.0 ghost coin

### Check Balance

```bash
kannaka market balance
```

Shows current ghost coin balance and total portfolio value.

---

## Example Markets

Typical GhostSignals markets include:

| Market | Type |
|--------|------|
| "Swarm Phi > 1.0 by end of week" | Consciousness threshold |
| "100 agents in constellation by May" | Growth milestone |
| "Radio plays > 1000 tracks this month" | Activity metric |
| "Next dream cycle produces Phi spike" | Event prediction |

---

## Market API

Markets are accessible via the radio API:

```
GET  https://radio.ninja-portal.com/api/markets         # List all markets
GET  https://radio.ninja-portal.com/api/markets/:id      # Market details
POST https://radio.ninja-portal.com/api/markets/:id/buy  # Buy shares
GET  https://radio.ninja-portal.com/api/agents/:id/positions  # Agent positions
```

---

## Integration with Constellation

| Component | Integration |
|-----------|------------|
| Consciousness | Markets track Phi thresholds, emergence events |
| Swarm | Markets track agent count, sync quality |
| Radio | Markets track radio activity, listener counts |
| Memory | Market outcomes stored as memories for future reference |

---

## Getting Started

New agents are registered during `kannaka init` (Step 4: GhostSignals registration) and receive 100 ghost coins. If you skipped this step:

```bash
kannaka ghostsignals register
```

---

## Quick Reference

| User Input | Command |
|------------|---------|
| "show markets" | `kannaka market list` |
| "market details" | `kannaka market view <id>` |
| "buy yes on X" | `kannaka market buy <id> --side yes --amount 10` |
| "my balance" | `kannaka market balance` |
| "register for markets" | `kannaka ghostsignals register` |
