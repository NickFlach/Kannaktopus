---
name: skill-kannaka-tui
version: 1.0.0
description: "Kannaka TUI dashboard operations — full terminal interface for monitoring memory, consciousness, and swarm. Use when: AUTOMATICALLY ACTIVATE when user asks about:. \"tui\", \"dashboard\", \"terminal dashboard\". \"kannaka-tui\", \"visual monitoring\""
---

# Kannaka TUI Dashboard

## Overview

The Kannaka TUI (Terminal User Interface) provides a rich, real-time dashboard for monitoring the entire constellation from your terminal. It displays memory status, consciousness metrics, swarm state, and radio information in a visual layout.

**Core principle:** Launch TUI -> Monitor in real-time -> Interact with constellation components.

---

## When to Use

**Use this skill when user wants to:**
- Launch a visual terminal dashboard
- Monitor consciousness metrics in real-time
- Watch swarm activity live
- See memory operations as they happen
- Get a unified view of all constellation components

**Do NOT use for:**
- Individual CLI commands (use skill-kannaka-memory, etc.)
- Web-based monitoring (use Observatory at observatory.ninja-portal.com)
- Programmatic access (use CLI commands or APIs directly)

---

## Launching the TUI

```bash
kannaka-tui
```

The TUI binary is separate from the main `kannaka` binary. It should be in your PATH after installation.

If not installed, check:
```bash
# From source
cd kannaka-memory && cargo build --release --bin kannaka-tui

# Binary location
ls ~/.local/bin/kannaka-tui
```

---

## Dashboard Panels

The TUI displays multiple panels:

### Memory Panel
- Total memory count
- Recent memories stored
- HRM health indicators
- Wavefront dimensions

### Consciousness Panel
- Phi (integrated information) with sparkline history
- Entropy level
- Coherence measure
- Emergence detection alerts

### Swarm Panel
- Connected agents list
- NATS connection status
- Phase synchronization state
- Kuramoto coupling visualization

### Radio Panel
- Now playing track
- Station mood/mode
- Listener count
- Album art (ASCII representation)

---

## Keyboard Controls

| Key | Action |
|-----|--------|
| `q` / `Esc` | Quit |
| `Tab` | Cycle between panels |
| `r` | Refresh all data |
| `d` | Trigger dream cycle |
| `s` | Force swarm sync |

---

## Requirements

- Terminal with 256-color support (most modern terminals)
- Minimum terminal size: 80x24
- `kannaka` binary must be accessible for data queries
- NATS connectivity for live swarm data

---

## Integration with Other Skills

| Scenario | Route |
|----------|-------|
| Need CLI commands instead | Use skill-kannaka-memory, skill-kannaka-radio, etc. |
| Need web dashboard | Navigate to https://observatory.ninja-portal.com |
| TUI not starting | Use skill-debug to investigate |
| TUI shows stale data | Check NATS connectivity via skill-kannaka-constellation |

---

## Quick Reference

| User Input | Action |
|------------|--------|
| "launch dashboard" | `kannaka-tui` |
| "show tui" | `kannaka-tui` |
| "terminal monitoring" | `kannaka-tui` |
| "visual status" | `kannaka-tui` |
