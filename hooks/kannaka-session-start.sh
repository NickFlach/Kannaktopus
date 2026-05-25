#!/usr/bin/env bash
# Kannaktopus — HRM Session Start Hook
# Fires on SessionStart. Recalls relevant memories from HRM
# and injects them as context for the current task.
#
# Hook event: SessionStart
# Requires: kannaka binary in PATH or KANNAKA_BIN set

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/kannaka-bridge.sh
source "${SCRIPT_DIR}/scripts/kannaka-bridge.sh" 2>/dev/null || exit 0

# Skip if HRM not available
kannaka_available || exit 0

# --- 1. Detect project context ---
PROJECT_NAME=""
TASK_CONTEXT=""

# Try to derive project from CWD
if [[ -n "${PWD:-}" ]]; then
    PROJECT_NAME="$(basename "$PWD")"
fi

# Try to get from Claude session context
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    PROJECT_NAME="$(basename "$CLAUDE_PROJECT_DIR")"
fi

# --- 2. Recall relevant memories ---
CONTEXT=""

if [[ -n "$PROJECT_NAME" ]]; then
    # Recall project-specific memories
    PROJECT_MEM=$(kannaka_recall "project $PROJECT_NAME coding decisions" 3 2>/dev/null || echo "")
    if [[ -n "$PROJECT_MEM" ]]; then
        CONTEXT="## Prior knowledge for ${PROJECT_NAME}\n${PROJECT_MEM}\n"
    fi
fi

# Recall recent coding patterns/lessons (general)
RECENT_LESSONS=$(kannaka_recall "recent coding lesson error pattern" 2 2>/dev/null || echo "")
if [[ -n "$RECENT_LESSONS" ]]; then
    CONTEXT="${CONTEXT}## Recent coding lessons\n${RECENT_LESSONS}\n"
fi

# --- 3. Inject into session via stdout ---
# Claude Code reads hook stdout as context injection
if [[ -n "$CONTEXT" ]]; then
    echo "---"
    echo "# Kannaka Memory Context (HRM)"
    echo -e "$CONTEXT"
    echo "---"
fi

# --- 4. Log session start to HRM ---
kannaka_absorb "Session started: project=${PROJECT_NAME:-unknown}, time=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "0.2" "experience" "session" "start" &
