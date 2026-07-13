# CURRENT_STATE note — Developer Observatory

Add this note into `custodian/docs/ai_context/CURRENT_STATE.md` when the feature lands.

## Developer Observatory

A developer-only Observatory autoload now exists at:

- `res://scripts/debug/dev_observatory.gd`

It creates a lightweight F9 overlay from:

- `res://scenes/debug/dev_observatory_overlay.tscn`

Runtime systems can log shared debug visibility through:

- `DevObservatory.log_event(kind, data)`
- `DevObservatory.increment(name, amount)`
- `DevObservatory.set_gauge(name, value)`
- `DevObservatory.mark_warning(message, data)`

Current first-pass scope:

- runtime counters
- runtime gauges
- recent event ring buffer
- FPS / uptime / node-count sampling
- player position gauge when a node is in group `player`
- enemy/projectile counts when groups exist

Not yet implemented:

- heatmap overlay
- replay export
- AI vision cones
- world-state graph visualization
- performance enforcement
