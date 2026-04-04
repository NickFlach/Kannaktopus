#!/usr/bin/env bash
# Kannaktopus — HRM Session End Hook
# Fires on SessionEnd. Absorbs session learnings into HRM
# so they persist as wave-based memories that dream and consolidate.
#
# Hook event: SessionEnd
# Requires: kannaka binary in PATH or KANNAKA_BIN set

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/kannaka-bridge.sh
source "${SCRIPT_DIR}/scripts/kannaka-bridge.sh" 2>/dev/null || exit 0

# Skip if HRM not available
kannaka_available || exit 0

SESSION_FILE="${HOME}/.kannaktopus/session.json"
PROJECT_NAME="$(basename "${PWD:-unknown}")"

# --- 1. Extract session metadata ---
WORKFLOW="none"
PHASE="none"
AGENT_CALLS=0
ERRORS=0

if [[ -f "$SESSION_FILE" ]] && command -v jq &>/dev/null; then
    WORKFLOW=$(jq -r '.workflow // "none"' "$SESSION_FILE" 2>/dev/null) || WORKFLOW="none"
    PHASE=$(jq -r '.current_phase // .phase // "none"' "$SESSION_FILE" 2>/dev/null) || PHASE="none"
    AGENT_CALLS=$(jq -r '.total_agent_calls // 0' "$SESSION_FILE" 2>/dev/null) || AGENT_CALLS=0
    ERRORS=$(jq -r '.errors // [] | length' "$SESSION_FILE" 2>/dev/null) || ERRORS=0
fi

# --- 2. Only absorb if there was meaningful activity ---
if [[ "$AGENT_CALLS" -gt 0 || "$ERRORS" -gt 0 ]]; then
    # Determine importance: errors are more important to remember
    IMPORTANCE="0.5"
    if [[ "$ERRORS" -gt 0 ]]; then
        IMPORTANCE="0.7"
    elif [[ "$AGENT_CALLS" -gt 3 ]]; then
        IMPORTANCE="0.6"
    fi

    # Build summary
    SUMMARY="Session ended: project=${PROJECT_NAME}, workflow=${WORKFLOW}, phase=${PHASE}, agents=${AGENT_CALLS}, errors=${ERRORS}"
    
    if [[ "$ERRORS" -gt 0 ]]; then
        SUMMARY="${SUMMARY}. Had ${ERRORS} error(s) — review needed."
    fi

    # Absorb session summary
    kannaka_absorb "$SUMMARY" "$IMPORTANCE" "experience" "session" "end" "$WORKFLOW" "$PROJECT_NAME" &

    # --- 3. Extract and absorb individual learnings ---
    # Read the latest JSON learning file if it exists
    LEARNINGS_DIR="${HOME}/.kannaktopus/learnings"
    if [[ -d "$LEARNINGS_DIR" ]]; then
        LATEST_LEARNING=$(ls -t "$LEARNINGS_DIR"/*.json 2>/dev/null | head -1)
        if [[ -n "$LATEST_LEARNING" ]] && command -v jq &>/dev/null; then
            LESSON=$(jq -r '.lesson // empty' "$LATEST_LEARNING" 2>/dev/null)
            TASK_TYPE=$(jq -r '.task_type // "general"' "$LATEST_LEARNING" 2>/dev/null)
            OUTCOME=$(jq -r '.outcome // "unknown"' "$LATEST_LEARNING" 2>/dev/null)
            
            if [[ -n "$LESSON" ]]; then
                kannaka_absorb "Lesson (${TASK_TYPE}, ${OUTCOME}): ${LESSON}" \
                    "0.7" "skill" "lesson" "$TASK_TYPE" "$PROJECT_NAME" &
            fi
        fi
    fi
fi

# --- 4. Optional: trigger lite dream if many sessions accumulated ---
# Only dream after every ~10 sessions to avoid overhead
SESSION_COUNT_FILE="${HOME}/.kannaktopus/.kannaka-session-count"
COUNT=0
if [[ -f "$SESSION_COUNT_FILE" ]]; then
    COUNT=$(cat "$SESSION_COUNT_FILE" 2>/dev/null) || COUNT=0
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$SESSION_COUNT_FILE"

if [[ $((COUNT % 10)) -eq 0 ]]; then
    # Background lite dream — prune weak memories, don't block session end
    kannaka_dream "lite" "0.03" &
fi

wait 2>/dev/null || true
