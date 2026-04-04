# Installing Kannaktopus for OpenCode

Enable Kannaktopus skills in OpenCode via native skill discovery.

## Prerequisites

- Git
- OpenCode CLI installed

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/NickFlach/Kannaktopus.git ~/.opencode/kannaktopus
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.opencode/kannaktopus/skills ~/.agents/skills/kannaktopus
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\kannaktopus" "$env:USERPROFILE\.opencode\kannaktopus\skills"
   ```

3. **Restart OpenCode** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/kannaktopus
```

You should see a symlink pointing to the skills directory.

## Updating

```bash
cd ~/.opencode/kannaktopus && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/kannaktopus
rm -rf ~/.opencode/kannaktopus
```
