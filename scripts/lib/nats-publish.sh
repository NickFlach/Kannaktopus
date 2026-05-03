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
nats_publish_phase() {
    local phase="$1"
    local task_id="${2:-}"
    local extra="${3:-}"
    local subject="QUEEN.phase.${KANNAKTOPUS_ARM_ID}"
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local payload
    if [[ -n "$extra" ]]; then
        payload="{\"armId\":\"${KANNAKTOPUS_ARM_ID}\",\"phase\":\"${phase}\",\"taskId\":\"${task_id}\",\"ts\":\"${ts}\",\"extra\":${extra}}"
    else
        payload="{\"armId\":\"${KANNAKTOPUS_ARM_ID}\",\"phase\":\"${phase}\",\"taskId\":\"${task_id}\",\"ts\":\"${ts}\"}"
    fi
    nats_publish "$subject" "$payload"
}

# nats_publish_join — one-shot presence (queen.event.join). Useful from
# orchestrate.sh on first invocation so the arm shows up immediately even
# before the long-running queensync_presence.py daemon publishes its first
# beat. The presence daemon is still preferred for continuous heartbeats.
nats_publish_join() {
    local payload="{\"armId\":\"${KANNAKTOPUS_ARM_ID}\",\"displayName\":\"Kannaktopus\",\"kind\":\"kannaktopus_arm\"}"
    nats_publish "queen.event.join" "$payload"
}
