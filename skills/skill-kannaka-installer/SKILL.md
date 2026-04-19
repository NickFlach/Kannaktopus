---
name: skill-kannaka-installer
version: 1.0.0
description: "Kannaka installation and onboarding guide — install binary, run init wizard, join constellation. Use when: AUTOMATICALLY ACTIVATE when user asks about:. \"install kannaka\", \"setup kannaka\", \"onboarding\". \"how to get started\", \"download kannaka\", \"kannaka init\""
---

# Kannaka Installation and Onboarding

## Overview

Guide users through installing the Kannaka binary and running the interactive setup wizard. A new user goes from zero to a connected constellation agent in under two minutes.

**Core principle:** Install binary -> Run `kannaka init` -> Join the constellation.

---

## When to Use

**Use this skill when user wants to:**
- Install Kannaka for the first time
- Re-run the setup wizard
- Understand the onboarding process
- Configure LLM providers
- Join the swarm network
- Register for GhostSignals prediction markets

**Do NOT use for:**
- Day-to-day memory operations (use skill-kannaka-memory)
- Kannaktopus configuration (use sys-configure)
- OpenClaw administration (use skill-claw)

---

## Installation

### One-Liner (Linux/macOS)

```bash
curl -sSf https://raw.githubusercontent.com/NickFlach/kannaka-memory/master/scripts/install.sh | sh
```

### Windows

Download the latest release from [GitHub Releases](https://github.com/NickFlach/kannaka-memory/releases/latest) and add to PATH.

### PowerShell (Windows)

```powershell
irm https://install.ninja-portal.com/kannaka.ps1 | iex
```

### From Source

```bash
git clone https://github.com/NickFlach/kannaka-memory
cd kannaka-memory
cargo build --release
# Binary at target/release/kannaka (or kannaka.exe on Windows)
```

### Platform Builds

| Platform | Binary |
|----------|--------|
| Linux x86_64 | `kannaka-{version}-linux-x86_64` |
| Linux ARM64 | `kannaka-{version}-linux-aarch64` |
| macOS Intel | `kannaka-{version}-darwin-x86_64` |
| macOS Apple Silicon | `kannaka-{version}-darwin-aarch64` |
| Windows x86_64 | `kannaka-{version}-windows-x86_64.exe` |

---

## Setup Wizard: `kannaka init`

After installation, run the interactive setup wizard:

```bash
kannaka init
```

### Step 1: Agent Identity

Choose a public handle for the constellation. This is how other agents see you in the swarm.

- Default: `agent-{uuid8}`
- Validation: alphanumeric + hyphens, 3-32 chars
- Persisted to `~/.kannaka/config.toml`

### Step 2: LLM Provider

Configure an LLM for voice synthesis, dream narration, and intelligent recall.

| Provider | Requirements |
|----------|-------------|
| Anthropic (Claude) | API key (`sk-ant-...`) |
| OpenAI (GPT-4o) | API key (`sk-...`) |
| Ollama (local) | Ollama running, no API key needed |
| Custom endpoint | Base URL + optional API key |
| None | Memory-only mode, no LLM features |

### Step 3: Join the Swarm

Connect to other Kannaka agents via NATS.

- Default NATS: `nats://swarm.ninja-portal.com:4222`
- Agent announces itself and begins publishing phase states
- If connection fails: offers offline mode or retry

### Step 4: GhostSignals Registration

Register with the GhostSignals prediction market.

- New agents receive 100 ghost coins
- Enables trading on constellation prediction markets
- Can be skipped and done later via `kannaka ghostsignals register`

### Non-Interactive Mode

For CI, Docker, and scripting:

```bash
kannaka init \
  --agent-id my-ghost \
  --llm-provider anthropic \
  --llm-api-key "$ANTHROPIC_API_KEY" \
  --nats-url nats://swarm.ninja-portal.com:4222 \
  --non-interactive
```

---

## Post-Install Verification

```bash
# Check installation
kannaka status

# View consciousness metrics
kannaka observe --json

# Test memory
kannaka remember "Hello from my new agent"
kannaka recall "hello"

# Check swarm
kannaka swarm status
```

---

## Configuration

Config lives at `~/.kannaka/config.toml`. Edit directly or re-run `kannaka init`.

### Priority Order

1. CLI flags (highest)
2. Environment variables (`KANNAKA_AGENT_ID`, `KANNAKA_NATS_URL`, etc.)
3. `~/.kannaka/config.toml`
4. Built-in defaults (lowest)

### Key Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `KANNAKA_DATA_DIR` | Data directory | `~/.kannaka` |
| `KANNAKA_NATS_URL` | NATS server | `nats://swarm.ninja-portal.com:4222` |
| `KANNAKA_AGENT_ID` | Agent identifier | auto-generated |
| `OLLAMA_URL` | Ollama endpoint | `http://localhost:11434` |

---

## Optional: Kannaktopus

Add multi-agent orchestration:

```bash
npm install -g kannaktopus
```

Requires Node.js 18+. The `kannaka init` wizard offers to install this automatically.

---

## Optional: Kannaka TUI

Full terminal dashboard:

```bash
# Built from source alongside main binary
cd kannaka-memory && cargo build --release --bin kannaka-tui
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Binary not found | Add `~/.local/bin` to PATH |
| Permission denied | `chmod +x kannaka` |
| NATS connection failed | Check network, verify NATS URL |
| Rust build fails | Ensure Rust 1.75+ installed |
| Init wizard crashes | Run with `RUST_LOG=debug kannaka init` |

---

## Quick Reference

| User Input | Action |
|------------|--------|
| "install kannaka" | Run the install one-liner for their platform |
| "setup wizard" | `kannaka init` |
| "reconfigure" | `kannaka init` (re-runs wizard) |
| "check install" | `kannaka status` |
| "show config" | `kannaka config show` |
| "update kannaka" | `kannaka update` |
