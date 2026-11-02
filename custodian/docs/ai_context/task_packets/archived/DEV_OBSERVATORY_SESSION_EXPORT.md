# Developer Observatory Session Export

- Status: `complete`
- Authority: `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`
- Goal: Extend the existing `DevObservatory` autoload with stable and timestamped JSON playtest-session exports plus an F10 shortcut.
- Files: `game/systems/debug/dev_observatory.gd`, `project.godot`, the existing overlay script, focused validation, and active design/context docs.
- Constraints: Do not create a second observatory; preserve bounded buffers; export must not alter gameplay authority or clear telemetry; do not add the deferred analyzer script.
- Acceptance: F10 is registered, exports are JSON-safe and include metadata/scene/uptime/telemetry, success logs an event, failures log warnings, buffers remain intact, and focused/project validation passes.
- Completed: Extended the existing autoload with stable/timestamped JSON export, F10 input, JSON-safe Variant conversion, metadata/scene/session payloads, success/failure telemetry, absolute-path console and overlay confirmation, project input registration, focused failure/success validation, and active documentation updates.
- Deferred: `custodian/tools/analysis/analyze_dev_observatory_session.py` remains the next reporting slice.
