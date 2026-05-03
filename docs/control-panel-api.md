# Control panel API contract

Replit's QueenSync control panel drives Kannaktopus over the public NATS
swarm bus. This document is the contract for what subjects to publish to
and what payloads to send. Pair with [observatory-presence.md](observatory-presence.md)
which covers the read-side (how Kannaktopus shows up on the observatory).

## Architecture

```
┌──────────────────────────┐   KANNAKTOPUS.command.<arm_id>   ┌───────────────────────────────┐
│ QueenSync control panel  │ ────────────────────────────────►│ scripts/kannaktopus_listener.py│
│ (Replit)                 │   reply on _INBOX.*              │ subscribes + dispatches        │
│                          │ ◄────────────────────────────────│ to local handlers              │
│                          │                                  └───────────────────────────────┘
│                          │   queen.event.join (every 30s)   ┌───────────────────────────────┐
│                          │ ◄────────────────────────────────│ scripts/queensync_presence.py │
│                          │   QUEEN.phase.<arm_id> (per work)│ orchestrate.sh phase pulses   │
│                          │ ◄────────────────────────────────│ via lib/nats-publish.sh       │
└──────────────────────────┘                                  └───────────────────────────────┘
```

## Command channel

### Subjects

| Subject                              | Purpose                                              | Anon publish? |
| ------------------------------------ | ---------------------------------------------------- | ------------- |
| `KANNAKA.ask.<arm_id>`               | **Recommended** for the Replit Console — anon-publishable per the bus's ADR-0026 ACL. | ✅            |
| `KANNAKA.ask.broadcast`              | Anon-publishable fan-out to every arm.               | ✅            |
| `KANNAKTOPUS.command.<arm_id>`       | Internal / authenticated — same handlers, kannaka_internal-only publish. | ❌            |
| `KANNAKTOPUS.command.broadcast`      | Internal / authenticated fan-out.                    | ❌            |

The Replit control panel should use the `KANNAKA.ask.*` subjects so it
can connect to the bus without holding `kannaka_internal` credentials —
the bus allows anonymous publish on `KANNAKA.ask.>` and anonymous
subscribe on `_INBOX.>`, which is enough for the standard NATS
request-reply pattern. The same listener handles all four subjects
identically; no per-subject behavior differences.

### Request schema

```json
{
  "cmd": "<command-name>",
  "args": { "...": "command-specific" }
}
```

### Reply schema

The listener replies on whatever NATS reply inbox the request carried (the
standard request-reply pattern). Both shapes are valid:

```json
{ "ok": true,  "result": { "...": "..." } }
{ "ok": false, "error": "<message>" }
```

### Supported commands

| `cmd`           | Args                                          | Result                                                                                       |
| --------------- | --------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `ping`          | none                                          | `{pong: true, arm_id, ts}` — liveness probe.                                                 |
| `status`        | none                                          | `{arm_id, mcp_listen_port, orchestrate_available, kannaka_bin_available, platform}`.         |
| `capabilities`  | none                                          | `{capabilities: [...], skills: [...]}` — for rendering quick-action buttons.                 |
| `version`       | none                                          | `{kannaktopus, python, nats_py}`.                                                            |
| `wake`          | `{[reason]}`                                  | `{awake: true, arm_id, ts, status: {…}}` — wake-from-idle handshake for the Console; pairs with `KANNAKTOPUS_WAKE_URL`. Always succeeds (Kannaktopus is always-on while systemd is enabled). |
| `run`           | `{skill, prompt, [timeout_seconds]}`          | **RESERVED** — returns `{implemented: false}` today; will spawn `orchestrate.sh` when shipped. |

Unknown commands reply with `{ok: false, error: "unknown_command: ...", supported: [...]}`.

## Example: ping from the control panel

Using the `nats` CLI to mock what the panel will do:

```bash
nats --server nats://swarm.ninja-portal.com:4222 \
  req KANNAKTOPUS.command.kannaktopus-01 \
  '{"cmd":"ping"}'
# {"ok": true, "result": {"pong": true, "arm_id": "kannaktopus-01", "ts": 1746432000.123}}
```

From a Node client:

```ts
import { connect, JSONCodec } from "nats";

const nc = await connect({ servers: "nats://swarm.ninja-portal.com:4222" });
const codec = JSONCodec();

const reply = await nc.request(
  "KANNAKTOPUS.command.kannaktopus-01",
  codec.encode({ cmd: "status" }),
  { timeout: 5000 },
);
console.log(codec.decode(reply.data));
```

## Authentication

**Listener side** (Kannaktopus): authenticates as `kannaka_internal` via
`NATS_USER` + `NATS_PASSWORD` env vars so it can subscribe to the
`KANNAKTOPUS.command.>` subjects (those are restricted to authenticated
publishers, not subscribers — but `kannaka_internal` simplifies things).

**Replit control panel side**: connect anonymously and use the
`KANNAKA.ask.<arm_id>` subjects. No credentials required.

```
KANNAKTOPUS_WAKE_URL=nats://swarm.ninja-portal.com:4222
```

(That's the public TCP endpoint of the constellation NATS bus. The
Console's Node server uses [`nats.js`](https://github.com/nats-io/nats.js)
as the client. No auth params needed; default user is `anon`.)

If the constellation operators ever tighten the anon ACL on
`KANNAKA.ask.>`, the Console will need to set `NATS_USER` /
`NATS_PASSWORD` env vars too — single change, no redesign.

## Versioning policy

The `cmd` strings are stable. New commands are additive — old ones won't
disappear without an explicit deprecation window. Args within a command
may grow new optional fields; required fields will not change.

The `run` command shape is **reserved** — its args may evolve before it
ships. Treat any `run`-shaped contract as draft until `implemented: true`
is in the reply.

## Deployment

### Listener (run somewhere always-on, e.g. Oracle)

```bash
pip install nats-py
python scripts/kannaktopus_listener.py
```

Or as a systemd service:

```bash
sudo cp scripts/systemd/kannaktopus-listener.service \
        /etc/systemd/system/kannaktopus-listener.service
sudo systemctl daemon-reload
sudo systemctl enable --now kannaktopus-listener.service
```

### Pair with the presence daemon

For the full bidirectional control surface, run **both** the presence
beacon and the command listener:

```bash
sudo systemctl enable --now \
  kannaktopus-presence.service \
  kannaktopus-listener.service
```

The presence daemon makes the arm visible on the observatory; the
listener makes it controllable.
