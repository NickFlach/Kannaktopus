# Observatory presence

Kannaktopus participates in the Kannaka Constellation by publishing a
periodic "I am alive" message on the public NATS swarm bus. Once the
presence beacon is running, this Kannaktopus instance shows up as an
agent on
[observatory.ninja-portal.com](https://observatory.ninja-portal.com)
and the matching `kannaktopus_arm` card on the QueenSync Queen Console
flips from `offline` to `idle`.

## Architecture

```
Kannaktopus host                                Kannaka constellation
┌────────────────────────────────┐              ┌───────────────────────────┐
│ scripts/queensync_presence.py  │  publishes   │ swarm.ninja-portal.com    │
│   every 30s →                  │ ───────────► │ NATS :4222                │
│     queen.event.join           │              │  ├─► observatory swarm    │
│                                │              │  │    /api/state agents{} │
│ scripts/orchestrate.sh         │  per phase   │  └─► QueenSync NATS bridge│
│   QUEEN.phase.<armId>          │ ───────────► │       arm card heartbeat  │
│   (probe/grasp/tangle/ink)     │              │                           │
└────────────────────────────────┘              └───────────────────────────┘
```

QueenSync's bridge treats every `queen.event.join` as a heartbeat for the
named arm. The 3-minute staleness sweep demotes the card back to `offline`
if joins stop arriving, so a 30-second interval gives plenty of headroom.

## Prerequisites

| Requirement                       | Why                                                                 |
| --------------------------------- | ------------------------------------------------------------------- |
| Outbound TCP to `:4222`           | The bus has no inbound flow; everything is publish.                 |
| `pip install nats-py`             | Used by `scripts/queensync_presence.py`.                            |
| (optional) `nats` CLI on `PATH`   | Lets `orchestrate.sh` emit `QUEEN.phase.*` events via `nats-publish.sh`. |

The public bus is read-only-ish: no auth is required to **publish** join
events for your own arm id, but the constellation operators reserve the
right to drop noisy publishers. Keep the interval ≥ 30s.

## Configuration

| Env var                          | Default                                  | Effect                                                     |
| -------------------------------- | ---------------------------------------- | ---------------------------------------------------------- |
| `NATS_URL`                       | `nats://swarm.ninja-portal.com:4222`     | Override to point at a private bus during dev.             |
| `KANNAKTOPUS_ARM_ID`             | `kannaktopus-01`                         | Becomes the agent key in `swarm.agents` and the QueenSync arm row. Use `kannaka-prime` to take over the existing seeded card. |
| `KANNAKTOPUS_DISPLAY_NAME`       | `Kannaktopus`                            | Label rendered in the Queen Console.                       |
| `KANNAKTOPUS_PRESENCE_SECONDS`   | `30`                                     | Beacon interval. Don't go below 10s.                       |
| `KANNAKTOPUS_LOG_LEVEL`          | `INFO`                                   | `DEBUG` to see every publish.                              |

## Running

### Foreground (dev)

```bash
pip install nats-py
python scripts/queensync_presence.py
```

You should see

```
INFO  kannaktopus.presence connected to NATS nats://swarm.ninja-portal.com:4222
INFO  kannaktopus.presence published initial queen.event.join for kannaktopus-01
```

### systemd (Linux host)

A unit file ships at `scripts/systemd/kannaktopus-presence.service`.
Adjust `WorkingDirectory=` and `ExecStart=` to match your install, then:

```bash
sudo cp scripts/systemd/kannaktopus-presence.service \
        /etc/systemd/system/kannaktopus-presence.service
sudo systemctl daemon-reload
sudo systemctl enable --now kannaktopus-presence.service
sudo journalctl -u kannaktopus-presence -f
```

### Phase pulses (optional)

If you want Kannaktopus to *pulse* as it works (probe → grasp → tangle →
ink), source `scripts/lib/nats-publish.sh` from `orchestrate.sh` and call
`nats_publish_phase <phase> "<task_id>"` at each phase boundary. The
helper silently no-ops when the `nats` CLI isn't installed, so adding the
calls is safe even on hosts that don't want to publish.

## Verification

After the daemon has been running for ~30s:

```bash
# 1. The observatory shows you in its swarm map
curl -s https://observatory.ninja-portal.com/api/state \
  | jq '.swarm.agents | keys'
# expected: ["kannaka-01", "kannaktopus-01"]

# 2. (If you have access) The QueenSync arm card flipped to idle
curl -s https://console.ninja-portal.com/api/arms \
  | jq '.[] | select(.id=="kannaka-prime") | {status,lastHeartbeat}'
```

If the arm doesn't appear within ~60s, in order:

1. Confirm outbound TCP to `swarm.ninja-portal.com:4222` is allowed.
2. Run with `KANNAKTOPUS_LOG_LEVEL=DEBUG` and check that the connect log
   line prints.
3. Verify the subject name is exactly `queen.event.join` (typos here are
   silent — NATS will accept the publish but no one is subscribed).

## Stopping cleanly

`SIGTERM` / `SIGINT` triggers a final `queen.event.leave` publish and
then drains the connection. The Queen Console card flips to `offline`
immediately rather than waiting for the 3-minute staleness sweep.
