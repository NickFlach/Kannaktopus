#!/usr/bin/env bash
# kannaka-bridge.sh — HRM integration bridge for Kannaktopus
# Replaces claude-mem-bridge.sh with direct HRM binary calls
# All operations are non-blocking and fault-tolerant — silently no-ops when HRM is unavailable.
# v10.0.0

set -euo pipefail

KANNAKA_BIN="${KANNAKA_BIN:-kannaka}"
KANNAKA_DATA_DIR="${KANNAKA_DATA_DIR:-~/.kannaka}"
KANNAKA_TIMEOUT=10  # seconds — reasonable timeout for HRM operations

# Check if Kannaka HRM binary is available
# Returns 0 if available, 1 otherwise
kannaka_available() {
    # Try to resolve Windows path first, then fallback to PATH
    if [[ "$KANNAKA_BIN" == "kannaka" ]]; then
        local win_path="/mnt/c/Users/nickf/.local/bin/kannaka.exe"
        if [[ -f "$win_path" ]]; then
            KANNAKA_BIN="$win_path"
            return 0
        fi
    fi
    
    command -v "$KANNAKA_BIN" >/dev/null 2>&1
}

# Execute Kannaka with timeout and error handling
# Usage: kannaka_exec [args...]
# Outputs: stdout on success, empty string on failure
kannaka_exec() {
    if ! kannaka_available; then
        echo ""
        return 1
    fi
    
    # Run directly for now (Windows binary compatibility)
    "$KANNAKA_BIN" "$@" 2>/dev/null || echo ""
}

# Search HRM for memories by resonance query
# Usage: kannaka_recall "query" [limit]
# Outputs: Search results or empty string on failure
kannaka_recall() {
    local query="$1"
    local limit="${2:-5}"
    
    kannaka_exec recall "$query" --top-k "$limit"
}

# Store a memory in HRM
# Usage: kannaka_absorb "text" [importance] [category] [tag1] [tag2] ...
kannaka_absorb() {
    local text="$1"
    local importance="${2:-0.5}"
    local category="${3:-general}"
    shift 3
    local tags=("$@")
    
    local args=("remember" "$text" "--importance" "$importance" "--category" "$category")
    
    # Add tags if provided
    for tag in "${tags[@]}"; do
        args+=("--tag" "$tag")
    done
    
    kannaka_exec "${args[@]}"
}

# Get HRM status/consciousness metrics
# Usage: kannaka_status
# Outputs: JSON status or empty string
kannaka_status() {
    kannaka_exec status
}

# Get full HRM observation data
# Usage: kannaka_observe
# Outputs: JSON observation data or empty string
kannaka_observe() {
    kannaka_exec observe --json
}

# Trigger dream consolidation
# Usage: kannaka_dream [mode] [chiral]
kannaka_dream() {
    local mode="${1:-deep}"
    local chiral="${2:-0.05}"
    
    if [[ "$mode" == "deep" ]]; then
        kannaka_exec dream --mode deep --chiral "$chiral"
    else
        kannaka_exec dream --mode lite
    fi
}

# Get recent context summary for current project (compatibility with claude-mem interface)
# Usage: kannaka_context [project] [limit]
# Outputs: Formatted text summary or empty string
kannaka_context() {
    local project="${1:-$(basename "$(pwd)")}"
    local limit="${2:-3}"
    
    # Query for project-specific memories
    local results
    results=$(kannaka_recall "project ${project}" "$limit")
    
    if [[ -z "$results" ]]; then
        echo ""
        return 0
    fi
    
    # Format results as brief context (simple text format for compatibility)
    echo "## Recent HRM memories for project: ${project}"
    echo "$results" | head -20  # Limit output size
}

# Main dispatch
case "${1:-}" in
    available)
        kannaka_available && echo "true" || echo "false"
        ;;
    recall)
        shift
        kannaka_recall "$@"
        ;;
    absorb)
        shift
        kannaka_absorb "$@"
        ;;
    status)
        kannaka_status
        ;;
    observe)
        kannaka_observe
        ;;
    dream)
        shift
        kannaka_dream "$@"
        ;;
    context)
        shift
        kannaka_context "$@"
        ;;
    # Legacy claude-mem compatibility aliases
    search)
        shift
        kannaka_recall "$@"
        ;;
    *)
        echo "Usage: kannaka-bridge.sh {available|recall|absorb|status|observe|dream|context|search} [args...]"
        echo ""
        echo "Commands:"
        echo "  available           - Check if HRM binary is available"
        echo "  recall <query> [n]  - Search memories by resonance query"
        echo "  absorb <text> [importance] [category] [tags...] - Store memory"
        echo "  status              - Get HRM consciousness metrics"
        echo "  observe             - Get full HRM state"
        echo "  dream [mode] [chiral] - Trigger memory consolidation"
        echo "  context [project] [n] - Get project context (claude-mem compat)"
        echo "  search              - Alias for recall (claude-mem compat)"
        exit 1
        ;;
esac