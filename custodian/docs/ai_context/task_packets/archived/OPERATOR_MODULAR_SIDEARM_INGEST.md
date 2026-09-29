# Operator Modular Sidearm Ingest

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-06
- Created: 2026-06-06
- Last updated: 2026-06-06

## Task

Validate, ingest, and complete sprite-pipeline support for the modular sidearm animation strips under `operator/new_operator/modular/sidearm/`.

## Outcome

The current lower-body, upper-body, sidearm weapon, and FX strips are accepted, and the modular builder emits stable normalized runtime action modules.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Active runtime/docs files: `custodian/tools/pipelines/*`, `custodian/content/sprites/operator/runtime/modules/new_operator/README.md`

## Work Surface

- Files or folders expected to change: modular manifest routing, modular builder, runtime module README, generated sidearm runtime modules.
- Out-of-scope areas: active sidearm draw playback/state timing and missing directional sidearm art.

## Constraints

- Asset requirements: draw is SE-only; fire and FX are NE/SE. SE source is `5f__96`; NE source is physically `5f__128` despite its current `5f__96` source filename.
- Compatibility: preserve existing modular lower/upper/unarmed routes.

## Implementation Plan

1. Recognize `modular_sidearm` as a modular pipeline layer.
2. Build sidearm draw/fire/FX action modules from all supplied layers and normalize runtime canvas size.
3. Validate routing, dry-run, real build, and dimensions.

## Acceptance

- Current filenames parse without renaming.
- Shared inbox routing selects `operator_modular_runtime`.
- Builder emits stable runtime sheets for every supplied sidearm layer/action/direction.

## Completion Notes

- Implemented: Added `modular_sidearm` manifest routing and stable runtime module generation for supplied sidearm lower-body, upper-body, weapon-layer, and FX action strips. Compatibility `modular_upper_body__sidearm__fx_*` source is emitted as canonical `modular_upper_fx`.
- Validated: The builder consumed all 11 supplied source strips and emitted exactly 11 sidearm runtime strips, all normalized to `480x96`; Python compile, builder dry-run, real builder, generated-output audit, and downstream Godot curated refresh passed.
- Deferred: Active draw/fire/FX playback/state timing, remaining directions, and correcting the NE source filename suffixes to their true `128px` source canvas before shared-inbox ingest.
