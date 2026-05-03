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

| Subject                              | Purpose                                              |
| ------------------------------------ | ---------------------------------------------------- |
| `KANNAKTOPUS.command.<arm_id>`       | Targeted command for one arm (default `kannaktopus-01`). |
| `KANNAKTOPUS.command.broadcast`      | Fan-out to every Kannaktopus arm subscribed to the bus.  |

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

The listener inherits NATS auth from `NATS_USER` / `NATS_PASSWORD` env vars.
On the public bus, anonymous subscribe is allowed (the listener works
without credentials). The control panel publisher works the same way — no
credentials needed for the request side. If the constellation operators
tighten the ACL on `KANNAKTOPUS.command.>`, both sides will need
credentials and the change is one env var.

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
