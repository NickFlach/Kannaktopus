#!/usr/bin/env bash
# Tests for strategy-rotation PostToolUse hook
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$PROJECT_ROOT/hooks/strategy-rotation.sh"
HOOKS_JSON="$PROJECT_ROOT/.claude-plugin/hooks.json"

TEST_COUNT=0; PASS_COUNT=0; FAIL_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT+1)); PASS_COUNT=$((PASS_COUNT+1)); echo "PASS: $1"; }
fail() { TEST_COUNT=$((TEST_COUNT+1)); FAIL_COUNT=$((FAIL_COUNT+1)); echo "FAIL: $1 — $2"; }

# ── Hook file exists and is executable ───────────────────────────────

if [[ -f "$HOOK" ]]; then
    pass "Hook script exists"
else
    fail "Hook script exists" "file not found: $HOOK"
fi

if [[ -x "$HOOK" ]]; then
    pass "Hook script is executable"
else
    fail "Hook script is executable" "not executable: $HOOK"
fi

# ── Dispatched by post-tool-dispatch.sh (v9.20.0 consolidation) ──────
# strategy-rotation.sh is invoked via post-tool-dispatch.sh, not directly
# registered in hooks.json. Verify both the dispatcher invocation and the
# dispatcher's own PostToolUse + Bash|Edit|Write registration.

DISPATCHER="$PROJECT_ROOT/hooks/post-tool-dispatch.sh"
if grep -q 'strategy-rotation.sh' "$DISPATCHER" 2>/dev/null; then
    pass "Hook dispatched by post-tool-dispatch.sh"
else
    fail "Hook dispatched by post-tool-dispatch.sh" "strategy-rotation.sh not found in dispatcher"
fi

# Verify post-tool-dispatch.sh is under PostToolUse section
if python3 -c "
import json, sys
with open('$HOOKS_JSON') as f:
    hooks = json.load(f)
post_hooks = hooks.get('PostToolUse', [])
found = False
for entry in post_hooks:
    for h in entry.get('hooks', []):
        if 'post-tool-dispatch.sh' in h.get('command', ''):
            found = True
            break
sys.exit(0 if found else 1)
" 2>/dev/null; then
    pass "Dispatcher is in PostToolUse section"
else
    fail "Dispatcher is in PostToolUse section" "post-tool-dispatch.sh not found under PostToolUse"
fi

# ── Dispatcher matcher includes Bash|Edit|Write ──────────────────────

if python3 -c "
import json, sys
with open('$HOOKS_JSON') as f:
    hooks = json.load(f)
post_hooks = hooks.get('PostToolUse', [])
for entry in post_hooks:
    for h in entry.get('hooks', []):
        if 'post-tool-dispatch.sh' in h.get('command', ''):
            tool_matcher = entry.get('matcher', {}).get('tool', '')
            has_bash = 'Bash' in tool_matcher
            has_edit = 'Edit' in tool_matcher
            has_write = 'Write' in tool_matcher
            sys.exit(0 if (has_bash and has_edit and has_write) else 1)
sys.exit(1)
" 2>/dev/null; then
    pass "Dispatcher matcher includes Bash, Edit, and Write"
else
    fail "Dispatcher matcher includes Bash, Edit, and Write" "expected matcher with Bash|Edit|Write"
fi

# ── Threshold env var documented ─────────────────────────────────────

if grep -q 'OCTO_STRATEGY_ROTATION_THRESHOLD' "$HOOK" 2>/dev/null; then
    pass "Threshold env var OCTO_STRATEGY_ROTATION_THRESHOLD documented"
else
    fail "Threshold env var documented" "OCTO_STRATEGY_ROTATION_THRESHOLD not found in hook"
fi

# Verify default threshold is 2
if grep -qE 'THRESHOLD.*:-2|default.*2' "$HOOK" 2>/dev/null; then
    pass "Default threshold is 2"
else
    fail "Default threshold is 2" "expected default of 2 for threshold"
fi

# ── Kill switch env var documented ───────────────────────────────────

if grep -q 'OCTO_STRATEGY_ROTATION' "$HOOK" 2>/dev/null; then
    pass "Kill switch env var OCTO_STRATEGY_ROTATION documented"
else
    fail "Kill switch env var documented" "OCTO_STRATEGY_ROTATION not found in hook"
fi

if grep -qE 'OCTO_STRATEGY_ROTATION.*off' "$HOOK" 2>/dev/null; then
    pass "Kill switch checks for 'off' value"
else
    fail "Kill switch checks for 'off' value" "expected off check for OCTO_STRATEGY_ROTATION"
fi

# ── State file uses session ID ───────────────────────────────────────

if grep -q 'octopus-failures-' "$HOOK" 2>/dev/null; then
    pass "State file uses octopus-failures prefix"
else
    fail "State file uses octopus-failures prefix" "expected /tmp/octopus-failures- pattern"
fi

if grep -q 'CLAUDE_SESSION_ID' "$HOOK" 2>/dev/null; then
    pass "State file scoped to session ID"
else
    fail "State file scoped to session ID" "expected CLAUDE_SESSION_ID in state file path"
fi

# ── Tracks consecutive failures ──────────────────────────────────────

if grep -q 'consecutive' "$HOOK" 2>/dev/null; then
    pass "Tracks consecutive failure count"
else
    fail "Tracks consecutive failure count" "missing consecutive tracking"
fi

# ── Resets on success ────────────────────────────────────────────────

if grep -qE 'consecutive.*0|Reset on success' "$HOOK" 2>/dev/null; then
    pass "Resets counter on success"
else
    fail "Resets counter on success" "missing success reset logic"
fi

# ── Emits additionalContext ──────────────────────────────────────────

if grep -q 'additionalContext' "$HOOK" 2>/dev/null; then
    pass "Returns additionalContext in hook output"
else
    fail "Returns additionalContext in hook output" "missing additionalContext"
fi

if grep -q 'STRATEGY ROTATION' "$HOOK" 2>/dev/null; then
    pass "Rotation message contains STRATEGY ROTATION label"
else
    fail "Rotation message contains STRATEGY ROTATION label" "missing label"
fi

# ── Conservative failure detection ───────────────────────────────────

if grep -q 'exit_code\|exitCode' "$HOOK" 2>/dev/null; then
    pass "Checks exit code for Bash failures"
else
    fail "Checks exit code for Bash failures" "missing exit code check"
fi

if grep -qE 'error|failed' "$HOOK" 2>/dev/null; then
    pass "Checks for error/failed in tool output"
else
    fail "Checks for error/failed in tool output" "missing error pattern check"
fi

# ── Stdin timeout guard ──────────────────────────────────────────────

if grep -q 'timeout.*cat\|timeout 3 cat' "$HOOK" 2>/dev/null; then
    pass "Has timeout-guarded stdin read"
else
    fail "Has timeout-guarded stdin read" "missing timeout cat pattern"
fi

# ── Skill files mention strategy rotation ────────────────────────────

SKILL_LOOP="$PROJECT_ROOT/.claude/skills/skill-iterative-loop.md"
SKILL_DEBUG="$PROJECT_ROOT/.claude/skills/skill-debug.md"
SKILL_TDD="$PROJECT_ROOT/.claude/skills/skill-tdd.md"

if grep -qi 'strategy rotation' "$SKILL_LOOP" 2>/dev/null; then
    pass "skill-iterative-loop.md mentions strategy rotation"
else
    fail "skill-iterative-loop.md mentions strategy rotation" "missing section"
fi

if grep -qi 'strategy rotation' "$SKILL_DEBUG" 2>/dev/null; then
    pass "skill-debug.md mentions strategy rotation"
else
    fail "skill-debug.md mentions strategy rotation" "missing section"
fi

if grep -qi 'strategy rotation' "$SKILL_TDD" 2>/dev/null; then
    pass "skill-tdd.md mentions strategy rotation"
else
    fail "skill-tdd.md mentions strategy rotation" "missing section"
fi

# ── Rotation advice content quality ──────────────────────────────────

if grep -q 'different approach\|fundamentally different' "$HOOK" 2>/dev/null; then
    pass "Rotation advice suggests different approach"
else
    fail "Rotation advice suggests different approach" "missing different approach guidance"
fi

if grep -q 'root cause' "$HOOK" 2>/dev/null; then
    pass "Rotation advice mentions root cause investigation"
else
    fail "Rotation advice mentions root cause investigation" "missing root cause guidance"
fi

# ── No prohibited references ─────────────────────────────────────────

if grep -qi 'temm1e\|FailureTracker' "$HOOK" 2>/dev/null; then
    fail "No prohibited attribution references" "found prohibited name in hook"
else
    pass "No prohibited attribution references"
fi

echo ""
echo "======================================================="
echo "strategy-rotation: $PASS_COUNT/$TEST_COUNT passed"
[[ $FAIL_COUNT -gt 0 ]] && echo "FAILURES: $FAIL_COUNT" && exit 1
echo "All tests passed."
