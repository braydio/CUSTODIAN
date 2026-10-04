# PROCGEN_ARCHIVE_RESOLVE_SHADER (AR2) — landed, partial acceptance

## Delivered
- `archive_resolve.gdshader`: graphite/soot cover, world-space ordered dither resolve in coherent fronts, thin brass trace, <=1 px misregistration lattice offset; opaque when fully veiled; no global `TIME`.
- `procgen_reveal_presentation.gd`: one shared `ShaderMaterial`, once-per-assignment custom-data identity, `presentation_time` sync from unpaused `advance()`, intensity controls + `reduced_effects`, telemetry; `effect_enabled` property writes now settle (R0-01). AR1 scheduling unchanged.
- `ProcGenTilemap.set_archive_resolve_enabled()` live toggle (R0-01); `World/ContractMap` moved before z2 actor containers in `game.tscn` (R0-02).
- Smoke `procgen_archive_resolve_shader` registered; `AGENTS.md` "Naming Work: The Task Packet Is the Brief".

## Validation
Green: new AR2 smoke, `procgen_reveal_presentation`, pause_aware_streaming, chunk_lifecycle, chunk_payload_cache, distant_chunk_unload, runtime_health, candidate_materializer_parity, region_frame; S1 quick `determinism_ok=true`, fp `1773840677`. `--changed` sweep: only `visual_review_handoff` failed (opt-in artifact publication SKIP, owner AGENTS.md); many actor/integration tests skipped by the runner.

## Not done / risks
- Shader compile and look are unverified (headless dummy renderer); user playtest pending before next slice.
- ARR1 R0-03 and R0-04 test hardening not built; no Moment Forge/Dropbox review. Packet Acceptance = `partial`.

## Process Feedback
- Outcome: partial. Friction: low. Went wrong: coded from a stale local packet that omitted R0-01..R0-04; added R0-01/R0-02 late. Prevention: re-read the packet in the claimed worktree before coding (now in AGENTS.md). Drift: headless Godot cannot compile shaders or read MultiMesh buffers. Follow-up: paired review, human playtest, R0-03/R0-04.

Reminder: other worktrees hold unrelated in-progress work (e.g. `claude/operator-c2b-final` in CUSTODIAN-operator); switch back to them.
