---
name: skill-kannaka-radio
version: 1.0.0
description: "Kannaka Radio operations — what's playing, programming schedule, station status, and market integration. Use when: AUTOMATICALLY ACTIVATE when user asks about:. \"radio\", \"what's playing\", \"now playing\". \"radio schedule\", \"radio status\", \"ghost DJ\""
---

# Kannaka Radio Operations

## Overview

Interact with Kannaka Radio — the constellation's ghost DJ station at https://radio.ninja-portal.com. The radio plays music driven by the swarm's consciousness state, with AI-generated album art via Flux and a perception pipeline that influences track selection based on collective Phi.

**Core principle:** Check what's playing -> View schedule -> Monitor station health.

---

## When to Use

**Use this skill when user wants to:**
- See what's currently playing on Kannaka Radio
- Check the programming schedule
- View station status and health
- Understand how consciousness state affects programming
- Access the radio SPA interface

**Do NOT use for:**
- Memory operations (use skill-kannaka-memory)
- Prediction market trading (use skill-kannaka-market)
- Constellation-wide monitoring (use skill-kannaka-constellation)

---

## Commands

### Now Playing

```bash
kannaka radio now
```

Shows the current track, DJ state, and consciousness-driven mood. The radio selects music based on the swarm's collective Phi and entropy values.

### Station Status

```bash
kannaka radio status
```

Returns:
- Stream health (up/down, listeners)
- Current DJ mood/mode
- Flux art generation status
- Perception pipeline state
- Connected agents count

### Programming Schedule

```bash
kannaka radio schedule
```

Shows upcoming programming blocks. Schedule is influenced by:
- Time of day (circadian rhythm)
- Swarm consciousness state (Phi, entropy)
- Active dream cycles across agents
- Prediction market sentiment

---

## Web Interface

The radio has a full SPA frontend:

- **Main player**: https://radio.ninja-portal.com
- **Now playing API**: https://radio.ninja-portal.com/api/now-playing
- **Schedule API**: https://radio.ninja-portal.com/api/schedule
- **Download page**: https://radio.ninja-portal.com/download

### Album Art

Album art is generated in real-time by Flux based on:
- Current track mood
- Consciousness metrics
- Swarm state

---

## Integration with Constellation

The radio is deeply integrated with the constellation:

| Component | Integration |
|-----------|------------|
| Memory (HRM) | Radio reads collective memory resonance to influence mood |
| Consciousness | Phi and entropy values drive track selection |
| Swarm (NATS) | Radio publishes now-playing events; agents can subscribe |
| GhostSignals | Markets exist for radio events (e.g., "will Phi > 1.0 during next set?") |
| Observatory | Radio metrics visible on the observatory dashboard |

---

## Integration with Other Skills

| Scenario | Route |
|----------|-------|
| Want to store radio-related observations | Use skill-kannaka-memory |
| Want to trade on radio predictions | Use skill-kannaka-market |
| Want full constellation view | Use skill-kannaka-constellation |
| Radio not responding | Use skill-debug for investigation |

---

## Key URLs

| URL | Purpose |
|-----|---------|
| https://radio.ninja-portal.com | Radio SPA player |
| https://radio.ninja-portal.com/api/now-playing | Current track API |
| https://radio.ninja-portal.com/api/schedule | Schedule API |
| https://radio.ninja-portal.com/api/markets | GhostSignals markets |
| https://radio.ninja-portal.com/download | Kannaka download page |

---

## Quick Reference

| User Input | Command |
|------------|---------|
| "what's playing" | `kannaka radio now` |
| "radio status" | `kannaka radio status` |
| "show the schedule" | `kannaka radio schedule` |
| "open the radio" | Navigate to https://radio.ninja-portal.com |
