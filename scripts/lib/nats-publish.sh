#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# lib/nats-publish.sh — Optional fire-and-forget NATS publishing for
# Kannaktopus orchestrate.sh phase events.
#
# When the `nats` CLI (https://github.com/nats-io/natscli) is installed,
# orchestrate.sh emits per-phase signals on `QUEEN.phase.<armId>` so the
# Kannaka Constellation observatory (and QueenSync Queen Console) can show
# this Kannaktopus instance pulsing as it works.
#
# When the `nats` CLI is missing the helper silently no-ops — Kannaktopus
# itself never blocks on the bus.
# ─────────────────────────────────────────────────────────────────────────────

# Public bus by default. Override with NATS_URL=nats://localhost:4222 etc.
KANNAKTOPUS_NATS_URL="${NATS_URL:-nats://swarm.ninja-portal.com:4222}"
KANNAKTOPUS_ARM_ID="${KANNAKTOPUS_ARM_ID:-kannaktopus-01}"

# nats_available — returns 0 if the `nats` CLI is on PATH.
nats_available() {
    command -v nats >/dev/null 2>&1
}

# _json_escape <string>
# Emit a string properly escaped as a JSON string value (no surrounding quotes).
# Prefers `jq` when available; falls back to a pure-bash escaper that handles
# the characters that actually appear in arm ids / task ids / phases.
_json_escape() {
    local s="$1"
    if command -v jq >/dev/null 2>&1; then
        # -Rs: read raw, slurp; jq itself adds the surrounding quotes — strip them
        # so callers can decide whether to wrap in quotes.
        local quoted
        quoted=$(printf '%s' "$s" | jq -Rs .)
        # jq prints "..."\n — strip the leading/trailing quote and trailing newline.
        quoted="${quoted%$'\n'}"
        printf '%s' "${quoted:1:${#quoted}-2}"
        return
    fi
    # Pure-bash fallback. Escape order matters — backslash first.
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\b'/\\b}"
    s="${s//$'\f'/\\f}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# nats_publish <subject> <payload>
# Fire-and-forget. Backgrounded so we never delay a phase boundary.
nats_publish() {
    local subject="$1"
    local payload="$2"
    nats_available || return 0
    (
        printf '%s' "$payload" \
            | nats --server "$KANNAKTOPUS_NATS_URL" pub "$subject" \
                >/dev/null 2>&1 \
            || true
    ) &
    disown 2>/dev/null || true
}

# nats_publish_phase <phase> [taskId] [extra_json]
# Emits a QUEEN.phase.<armId> event, e.g.
#   {"armId":"kannaktopus-01","phase":"probe","taskId":"abc","ts":"2026-..."}
#
# All string fields are JSON-escaped. `extra_json` is treated as a raw JSON
# fragment (object/array/scalar) — caller is responsible for it being valid
# JSON. Pass nothing or an empty string to omit it.
nats_publish_phase() {
    local phase="$1"
    local task_id="${2:-}"
    local extra="${3:-}"
    local arm_id_e phase_e task_e ts subject payload
    subject="QUEEN.phase.$(_json_escape "$KANNAKTOPUS_ARM_ID")"
    # Subject names should be plain ASCII identifiers, but if someone sets a
    # weird arm id, NATS will still accept whatever we send — just don't let
    # quotes or whitespace break the publish CLI invocation.
    subject="${subject//[^A-Za-z0-9._-]/_}"

    arm_id_e=$(_json_escape "$KANNAKTOPUS_ARM_ID")
    phase_e=$(_json_escape "$phase")
    task_e=$(_json_escape "$task_id")
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    if [[ -n "$extra" ]]; then
        payload=$(printf '{"armId":"%s","phase":"%s","taskId":"%s","ts":"%s","extra":%s}' \
            "$arm_id_e" "$phase_e" "$task_e" "$ts" "$extra")
    else
        payload=$(printf '{"armId":"%s","phase":"%s","taskId":"%s","ts":"%s"}' \
            "$arm_id_e" "$phase_e" "$task_e" "$ts")
    fi
    nats_publish "$subject" "$payload"
}

# nats_publish_join — one-shot presence (queen.event.join). Useful from
# orchestrate.sh on first invocation so the arm shows up immediately even
# before the long-running queensync_presence.py daemon publishes its first
# beat. The presence daemon is still preferred for continuous heartbeats.
nats_publish_join() {
    local arm_id_e display_e payload
    arm_id_e=$(_json_escape "$KANNAKTOPUS_ARM_ID")
    display_e=$(_json_escape "${KANNAKTOPUS_DISPLAY_NAME:-Kannaktopus}")
    payload=$(printf '{"armId":"%s","displayName":"%s","kind":"kannaktopus_arm"}' \
        "$arm_id_e" "$display_e")
    nats_publish "queen.event.join" "$payload"
}
