#!/usr/bin/env bash
# kannaka-bridge.sh — HRM (Holographic Resonance Memory) bridge for Kannaktopus
# Replaces claude-mem-bridge.sh with wave-based holographic memory
# v1.0.0

set -euo pipefail

KANNAKA_BIN="${KANNAKA_BIN:-kannaka}"
KANNAKA_TIMEOUT=10

# Check if kannaka binary is available
kannaka_available() {
    command -v "$KANNAKA_BIN" >/dev/null 2>&1
}

# Absorb a memory into HRM
# Usage: kannaka_absorb "text" [importance] [category] [tags...]
kannaka_absorb() {
    local text="$1"
    local importance="${2:-0.5}"
    local category="${3:-knowledge}"
    shift 3 2>/dev/null || true
    
    local args=("remember" "$text" "--importance" "$importance" "--category" "$category")
    
    # Remaining args are tags
    for tag in "$@"; do
        args+=("--tag" "$tag")
    done
    
    timeout "$KANNAKA_TIMEOUT" "$KANNAKA_BIN" "${args[@]}" 2>/dev/null || true
}

# Search memories by resonance
# Usage: kannaka_recall "query" [limit]
# Outputs: Memory results or empty string
kannaka_recall() {
    local query="$1"
    local limit="${2:-5}"
    
    timeout "$KANNAKA_TIMEOUT" "$KANNAKA_BIN" recall "$query" --top-k "$limit" 2>/dev/null || echo ""
}

# Get quick status (JSON)
kannaka_status() {
    timeout "$KANNAKA_TIMEOUT" "$KANNAKA_BIN" status 2>/dev/null || echo '{"error":"unavailable"}'
}

# Trigger dream consolidation
# Usage: kannaka_dream [mode] [chiral]
kannaka_dream() {
    local mode="${1:-deep}"
    local chiral="${2:-0.05}"
    
    timeout 60 "$KANNAKA_BIN" dream --mode "$mode" --chiral "$chiral" 2>/dev/null || true
}

# Absorb session context — call on session start to load relevant memories
# Usage: kannaka_load_context "project-name" "current-task"
kannaka_load_context() {
    local project="${1:-}"
    local task="${2:-}"
    
    if ! kannaka_available; then
        return 0
    fi
    
    local context=""
    
    if [[ -n "$project" ]]; then
        context=$(kannaka_recall "project: $project" 3)
    fi
    
    if [[ -n "$task" ]]; then
        local task_memories
        task_memories=$(kannaka_recall "$task" 3)
        context="${context}${task_memories:+\n---\n$task_memories}"
    fi
    
    if [[ -n "$context" ]]; then
        echo "$context"
    fi
}

# Absorb session results — call on session end to store lessons
# Usage: kannaka_save_session "summary" [importance]
kannaka_save_session() {
    local summary="$1"
    local importance="${2:-0.6}"
    
    if ! kannaka_available; then
        return 0
    fi
    
    kannaka_absorb "$summary" "$importance" "experience" "session" "coding"
}

# Compatibility wrapper: search (matches claude-mem-bridge interface)
claude_mem_search() {
    kannaka_recall "$1" "${2:-5}"
}

# Compatibility wrapper: observe (matches claude-mem-bridge interface)
claude_mem_observe() {
    local obs_type="$1"
    local title="$2"
    local text="$3"
    
    kannaka_absorb "${title}: ${text}" "0.6" "$obs_type" "session" "observation"
}

# Compatibility: check availability
claude_mem_available() {
    kannaka_available
}
