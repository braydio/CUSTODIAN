# VEHICLE RECOVERY FX PRODUCTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-recovery-fx-production-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-recovery-presentation-manifests-v1`
- Locks: `asset-pipeline-effect, vehicle-recovery-presentation, vehicle-restoration-runtime, operator-vehicle-scanner`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, asset-pipeline`
- Paired review workstream: `review-vehicle-recovery-fx-production-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `production Asset V2 normalization plus cross-system runtime presentation wiring should receive an independent acceptance pass`
- Reviewed main: `f12717e61213d7d30ae6b3e670d45e71507cd784`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Promote the six human-selected shared vehicle-recovery FX sources into the reviewed `vehicle_recovery_fx_common` Asset Pipeline V2 family and wire them to the real diagnosis and component-restoration runtime so scanning, installation, failure feedback, power routing, bootstrap, and successful recovery are readable without creating a second vehicle-state authority.
- Completion boundary: Done when the exact six approved Dropbox source masters are preserved under source-work with hash receipts, deterministically normalized to the reviewed 256 px family contract, ingested through Asset V2, published into one generated `SpriteFrames` resource, and consumed by one reusable `VehicleRecoveryFxPresenter` that is mounted on the Field Scout and driven by the real scanner/restoration signals. Presentation must fail soft and remain cosmetic: scan/progression, payment/component consumption, wreck lifecycle, restored health, and enterability remain owned by their reviewed systems and must succeed identically if the FX presenter or art is absent.
- Current measured state: On reviewed main, V7 production art is explicitly un-authored. `VEHICLE_RECOVERY_ART_MANIFEST.md` defines six required omni FX states at 256×256 but no production family art is present yet; V6/V6R own family registration and are dependency predecessors. `PilotableVehicle` emits `vehicle_destroyed`/`vehicle_restored`, creates `VehicleRestorationInteraction` dynamically for wreckage, and has no recovery-FX presenter. `VehicleRestorationInteraction` exposes `restoration_completed` and `restoration_cancelled` but has no successful-hold-start signal. The Field Scout scene has one body `AnimatedSprite2D` at `Vector2(0, -8)` and no recovery FX child. The `effect` Asset V2 kind routes canonical runtime files but has no default post-process. The six human-selected source masters are now consolidated in one immutable Dropbox handoff and are not runtime-complete until this packet normalizes, ingests, binds, and validates them.
- Evidence: `design/02_features/vehicles/VEHICLE_RECOVERY_ART_MANIFEST.md`; `design/02_features/vehicles/VEHICLE_RECOVERY_IMPLEMENTATION_ROADMAP.md`; `design/04_architecture/ASSET_PIPELINE_V2.md`; `custodian/content/metadata/assets/schemas/effect.json`; V6/V6R packet pair; `custodian/game/vehicles/{pilotable_vehicle,vehicle_restoration_interaction}.gd`; `custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn`; diagnosis and component-recovery packet contracts; `custodian/tools/assets/asset.py`; existing family-specific `forlorn_ritualant_spriteframes` post-process + `build_forlorn_ritualant_spriteframes.py` precedent; external source handoff `/CUSTODIAN/implementation_inputs/custodian_vehicle_recovery_fx_common_production_source_handoff_v1_20261017.zip`, Dropbox file ID `id:8NXqdXuW6GUAAAAAAAAESA`, outer SHA256 `0bb201621172869a223fddbe79301b2ae576a0e7b748e048fd79c952e55e0623`, inner `MANIFEST.json` with per-source hashes.
- Task-specific authority: Reviewed V6 `vehicle_recovery_fx_common` family contract for exact Asset V2 state identity; `VEHICLE_RECOVERY_ART_MANIFEST.md` for frame/FPS/canvas/visual role; Asset Pipeline V2 for source/inbox/runtime publication; `OperatorVehicleScanner`/reviewed diagnosis seam for scan ownership; `VehicleRestorationInteraction` for held-install events; `PilotableVehicle` for wreck/restore lifecycle; this packet's immutable source handoff for selected source bytes only.
- Work surface: External V7 source handoff; `custodian/asset_drop/source_work/effects/vehicle_recovery_fx_common/`; `custodian/asset_drop/inbox/vehicle_recovery_fx_common/`; reviewed `custodian/content/metadata/assets/families/vehicle_recovery_fx_common.asset.json`; `custodian/tools/assets/asset.py`; new deterministic normalization receipt/tooling under `custodian/tools/pipelines/migrations/`; new `custodian/tools/pipelines/build_vehicle_recovery_fx_spriteframes.py`; generated `custodian/content/sprites/effects/vehicles/recovery/vehicle_recovery_fx_common_frames.tres`; new `custodian/game/vfx/vehicles/{vehicle_recovery_fx_presenter.gd,vehicle_recovery_fx_presenter.tscn}`; narrow integration in `pilotable_vehicle.gd`, `vehicle_restoration_interaction.gd`, the reviewed Operator vehicle-scanner file, and `field_scout_buggy_mk1.tscn`; focused validation + validation manifest; recovery art manifest/required-assets truth only where successful ingest makes them stale.
- Change: Stage the exact source handoff, normalize and ingest all six required FX states, generate one canonical shared SpriteFrames resource, add one reusable runtime presenter, and bind it to existing scan/install/recovery events exactly as specified below. Prefer existing Asset V2 and sprite-import helpers where they satisfy the contract; do not create a parallel generic asset pipeline.
- Preserve: VehicleKnowledgeState remains the only durable scan-knowledge authority; OperatorInputRouter remains the raw input owner; FabPipeline/InventoryManager/ResourceLedger retain payment and item mutation authority; VehicleRestorationInteraction retains held-install/consumption semantics; PilotableVehicle retains wreck/health/enterability transitions; Field Scout body art/facing/movement timing stays untouched; all V6 family IDs/state IDs remain stable; runtime code never reads Dropbox or `asset_drop`.
- Non-goals: No new vehicle body animation; no destruction/body/wreck/post-destroy-smoke work; no component icons or world props; no `restore_failure_01`; no audio; no new research UI; no new R2/R3 vehicle; no rebalance of scan XP, fabrication costs, install duration, restored health, or component requirements; no gameplay delay waiting for a cosmetic FX animation; no artistic regeneration/recoloring of the approved source masters.
- Acceptance: (1) All six approved source bytes are preserved under canonical source-work names and hash-match the immutable handoff manifest. (2) Normalized inbox strips are RGBA, exact 256×256 cells, exact frame counts and sheet dimensions, stable center registration, and preserve source progression using one common scale per source sheet. (3) `scan_sweep_01` 8f@12, `fault_ping_01` 4f@8, `install_sparks_01` 6f@12, `power_route_01` 8f@10, `bootstrap_01` 8f@10, and `restore_success_01` 6f@10 ingest through the reviewed family and Asset V2 status/doctor are green. (4) A deterministic generated `vehicle_recovery_fx_common_frames.tres` exposes exactly those six animation names; only `install_sparks_01` loops. (5) The Scout has exactly one recovery presenter aligned to the existing body visual origin, and no gameplay script hard-codes Dropbox/source/inbox paths. (6) A valid service scan plays `scan_sweep_01` without changing scan acceptance, XP/evidence, HP, resources, or inventory. (7) Starting the real held install starts looping `install_sparks_01`; ordinary user/range/target cancellation stops it and consumes nothing. (8) Actual requirement/contract failure may play one `fault_ping_01`, while ordinary voluntary/spatial cancellation does not. (9) Successful production restoration emits no spurious cancellation and plays `power_route_01 -> bootstrap_01 -> restore_success_01` once in order after the mechanical restoration succeeds. (10) Vehicle restoration/enterability is not gated on the FX sequence; deleting/withholding the presenter or generated frames fails presentation soft while mechanical recovery still passes. (11) Existing diagnosis, component-recovery, Scout/lifecycle, and Asset V2 focused validations remain green. (12) Required-assets/art-manifest status is updated only for states proven imported/bound/runtime-verified; no source-only state is falsely marked complete.
- Validation: Run focused source-normalization tests/receipt checks first, then `python3 custodian/tools/pipelines/build_vehicle_recovery_fx_spriteframes.py --check`, `res://tools/validation/vehicle_recovery_fx_smoke.gd`, current Asset V2 request/plan/status for `vehicle_recovery_fx_common`, `python3 custodian/tools/assets/asset.py doctor`, `python3 custodian/tools/assets/asset.py needs --check`, `python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py`, and `python3 custodian/tools/validation/asset_pipeline_cli_ux_smoke.py`. Re-run the live diagnosis/knowledge, part-fabrication/recovery, Scout class/restoration, and vehicle lifecycle smokes that own the touched seams. Only after focused checks are green, run `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`. Do not run a broad actor/full suite merely to prove six VFX states.
- Task overrides: `none`
- Deferred: `restore_failure_01`; shared component icons; optional component world props; the already-created post-destroy smoke handoff; Field Scout engine-start/idle/brake/impact polish; body destroy/restore source intake owned by its separate vehicle-art work; first R2 TECHNICAL vehicle.

## Context Pack

- Repomix: `recommended`
- Include: `design/02_features/vehicles/VEHICLE_RECOVERY_{ART_MANIFEST,IMPLEMENTATION_ROADMAP}.md,custodian/content/metadata/assets/{schemas/effect.json,families/vehicle_recovery_fx_common.asset.json},custodian/tools/assets/asset.py,custodian/tools/pipelines/build_forlorn_ritualant_spriteframes.py,custodian/game/vehicles/{pilotable_vehicle,vehicle_restoration_interaction}.gd,custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn,custodian/game/actors/operator/interaction/*vehicle*scanner*.gd,custodian/tools/validation/*vehicle*`
- Purpose: `one bounded view of the reviewed FX contract, existing Asset V2 post-process precedent, and the only gameplay seams allowed to emit presentation events`

## External Production Source Handoff

Use this exact package as the only art source for the six states in this packet:

- Dropbox path: `/CUSTODIAN/implementation_inputs/custodian_vehicle_recovery_fx_common_production_source_handoff_v1_20261017.zip`
- Dropbox file ID: `id:8NXqdXuW6GUAAAAAAAAESA`
- Outer SHA256: `0bb201621172869a223fddbe79301b2ae576a0e7b748e048fd79c952e55e0623`
- Inner manifest: `custodian_vehicle_recovery_fx_common_production_source_handoff_v1_20261017/MANIFEST.json`
- Handoff schema: `custodian.asset_handoff.v1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`

At claim, inspect `custodian/tools/iteration/implementation_handoff.py --help` and the current Asset V2 handoff installer. Fetch/stage through the supported verified handoff path. Fail closed on outer SHA or inner source-hash mismatch. Dropbox is transport only and must never become runtime/source authority after verified staging.

Canonical source destinations after verification:

```text
custodian/asset_drop/source_work/effects/vehicle_recovery_fx_common/
  scan_sweep_01__omni_source.png
  fault_ping_01__omni_source.png
  install_sparks_01__omni_source.png
  power_route_01__omni_source.png
  bootstrap_01__omni_source.png
  restore_success_01__omni_source.png
```

Canonical normalized inbox targets:

```text
custodian/asset_drop/inbox/vehicle_recovery_fx_common/
  scan_sweep_01__omni.png
  fault_ping_01__omni.png
  install_sparks_01__omni.png
  power_route_01__omni.png
  bootstrap_01__omni.png
  restore_success_01__omni.png
```

Source SHA256 authority from the handoff manifest:

| State | Source geometry | SHA256 | Runtime contract |
|---|---:|---|---|
| `scan_sweep_01` | 2048×256 | `5e6dc6f48804381bed23de535ca14c8d6b668b837cd8f7d83c34f932650884cb` | 8×256² @12 |
| `fault_ping_01` | 1254×1254 | `24835c23a72e11efcf8cffed3aa1210035a2396fd8c2fdbcb0722f0b526b64b4` | 4×256² @8 |
| `install_sparks_01` | 2172×724 | `b49fb27c4d0145e1bfcf8e17808ea82cc05454b4140836494d42260046bf5256` | 6×256² @12 |
| `power_route_01` | 1774×887 | `85bbe5876272715044ca4810d2be9b10ec06902d06daefaf17b5914d31909b9d` | 8×256² @10 |
| `bootstrap_01` | 2048×227 | `b4c4f53d10f7c5e61147b18022b9bef0862255a5656e029514645f3eb753eea6` | 8×256² @10 |
| `restore_success_01` | 2048×341 | `e218011a7b0f2d7105e6d0b7794929ba19fabd74fd8493618d86e3eba08d0eb2` | 6×256² @10 |

## Required Implementation Shape

### 1. Deterministic one-time normalization

Do not ask image generation to hit exact runtime geometry again. Preserve source bytes and perform deterministic technical normalization.

Preferred implementation is a bounded, reproducible migration utility:

`custodian/tools/pipelines/migrations/normalize_vehicle_recovery_fx_v1.py`

It should use Pillow/current sprite-import helpers and produce both the six inbox strips and a committed or source-adjacent JSON normalization receipt. It must:

1. verify each source SHA before processing;
2. treat alpha, not RGB-black, as exterior-background authority;
3. detect the intended source regions/clusters and preserve their temporal order;
4. derive one common scale per state from the largest retained frame that must fit within 256×256 with a small nonzero safety margin;
5. apply that same scale to every retained frame in that state;
6. register the same semantic effect origin to `(128,128)` in every normalized cell;
7. use transparent padding only, never per-frame stretch or independent scale;
8. record source regions, retained-frame order, scale, destination placements, resampling mode, and output SHA256;
9. offer `--check` so the committed result is reproducible and stale output is detectable.

State-specific rules:

- `scan_sweep_01`: source is already exactly 2048×256. First prove it is eight isolated 256×256 cells with no cross-cell alpha. If valid, preserve geometry and bytes when possible; otherwise recompose only to correct registration.
- `fault_ping_01`: detect four source effect clusters from the 1254×1254 source and normalize to 1024×256.
- `install_sparks_01`: detect six ordered clusters from the 2172×724 source and normalize to 1536×256.
- `power_route_01`: detect eight ordered clusters from the 1774×887 source and normalize to 2048×256.
- `bootstrap_01`: detect all nine source stages in the 2048×227 source, identify exactly one closest/redundant adjacent stage by deterministic image-difference/alpha-bounds evidence, drop only that stage, and record the 9->8 mapping and rationale. Do not artistically edit the remaining frames.
- `restore_success_01`: detect six ordered clusters from the 2048×341 source and normalize to 1536×256.

If current shared sprite-import tooling already supports the needed explicit source regions + common transform, consume it instead of duplicating its implementation. Keep any new migration helper task-specific rather than adding a second general-purpose sprite pipeline.

### 2. Asset V2 family and ingest

Consume the reviewed V6 family. Do not create another family ID.

Expected family identity after V6R:

```text
id: vehicle_recovery_fx_common
kind: effect
runtime domain: sprites/effects/vehicles/recovery
canvas: 256×256
direction: omni
auto_mirror: false
```

Preserve V6 state IDs/frames/FPS exactly. Add only the consumer/post-process metadata required by this packet after inspecting the landed schema.

Run the live Asset V2 request/plan/status/ingest workflow. Never hand-copy canonical runtime outputs. After ingest, `asset status vehicle_recovery_fx_common` must prove all six required states imported/bound/runtime-verified according to current lifecycle semantics before docs/requirements call them complete.

### 3. Generate one canonical SpriteFrames resource

Use the existing family-specific post-process precedent rather than making gameplay code slice PNGs ad hoc.

Add post-process hook:

`vehicle_recovery_fx_spriteframes`

Create:

`custodian/tools/pipelines/build_vehicle_recovery_fx_spriteframes.py`

Generated resource:

`custodian/content/sprites/effects/vehicles/recovery/vehicle_recovery_fx_common_frames.tres`

Implementation recommendation:

- mirror the deterministic structure of `build_forlorn_ritualant_spriteframes.py`;
- resolve the six runtime PNG paths through the generated Asset V2 catalog/family semantic identities, not guessed filenames;
- validate each PNG is exactly `frames * 256` by `256` before rendering the resource;
- create 256×256 `AtlasTexture` slices;
- support `--check` and `--dry-run`;
- generate these exact animations:

```python
ANIMATIONS = (
    Animation("scan_sweep_01", 8, 12.0, False),
    Animation("fault_ping_01", 4, 8.0, False),
    Animation("install_sparks_01", 6, 12.0, True),
    Animation("power_route_01", 8, 10.0, False),
    Animation("bootstrap_01", 8, 10.0, False),
    Animation("restore_success_01", 6, 10.0, False),
)
```

Extend the existing `asset.py` family post-process dispatch minimally so the new hook participates in the same rollback-aware transaction pattern as the Ritualant hook. Do not redesign post-processing globally in this packet. The reviewed family should declare the hook and a SpriteFrames consumer if the landed schema supports that exact consumer form.

### 4. Add one reusable runtime presenter

Create:

```text
custodian/game/vfx/vehicles/vehicle_recovery_fx_presenter.gd
custodian/game/vfx/vehicles/vehicle_recovery_fx_presenter.tscn
```

Recommended scene shape:

```text
VehicleRecoveryFxPresenter (Node2D, script)
└── AnimatedSprite2D
    sprite_frames = res://content/sprites/effects/vehicles/recovery/vehicle_recovery_fx_common_frames.tres
    centered = true
    visible = false
```

Use a presentation z-order consistent with existing one-shot VFX (the shared `one_shot_animated_vfx.gd` currently uses absolute z 20); do not change vehicle collision/interaction ordering.

Recommended public surface:

```gdscript
func play_once(state_id: StringName) -> void
func play_loop(state_id: StringName) -> void
func play_sequence(state_ids: Array[StringName]) -> void
func stop() -> void
func bind_restoration_interaction(interaction: VehicleRestorationInteraction) -> void
```

Presenter ownership rules:

- owns only animation queue/visibility/playback;
- `animation_finished` advances queued one-shot states and hides after the last state;
- `install_sparks_01` may loop indefinitely until stopped;
- a missing SpriteFrames resource or missing animation warns once/fails soft and never changes vehicle mechanics;
- no HP, inventory, resources, scan knowledge, interaction availability, or control-state mutation;
- no direction variants; all six are omni.

### 5. Give restoration one clean presentation event seam

In the reviewed `VehicleRestorationInteraction`, add only the event needed to distinguish a real held install from preflight failure:

```gdscript
signal restoration_started(target: Node, actor: Node)
```

Emit it only after preflight succeeds and `_active_actor`, `_hold_elapsed`, and held-state ownership are established. Do not emit it for out-of-range/missing-requirement failures.

Preserve existing:

```gdscript
signal restoration_completed(target: Node)
signal restoration_cancelled(reason: StringName)
```

Ensure a successful restoration cannot also emit `restoration_cancelled(TARGET_UNAVAILABLE)` as a side effect of disabling its own interaction. On reviewed main before V3/V4C, `restore_from_wreck()` disables the interaction while `_active_actor` is still set, so this is a known claim-time check. If the reviewed predecessors have not already corrected it, use the smallest completion guard/order fix that yields exactly `started -> completed` on success and never changes payment/refund/lifecycle semantics.

### 6. Bind install/failure/bootstrap effects in the presenter

`bind_restoration_interaction()` should connect once and implement this mapping:

```text
restoration_started
    -> play_loop(install_sparks_01)

restoration_cancelled(INPUT_RELEASED | TARGET_LOST | OUT_OF_RANGE | ordinary TARGET_UNAVAILABLE)
    -> stop()
    -> no fault ping

restoration_cancelled(actual missing-requirement / contract-changed / reviewed mechanical-preflight failure)
    -> stop()
    -> play_once(fault_ping_01)

restoration_completed
    -> stop install_sparks
    -> play_sequence([power_route_01, bootstrap_01, restore_success_01])
```

Do not invent a second canonical failure enum. At claim, consume the exact final reason names from the reviewed V3/V4C interaction and classify only presentation behavior around them.

Mechanical restoration remains complete when `restoration_completed` fires. The three-state success sequence is cosmetic follow-through and must not delay 40 HP restoration, group re-enable, entry, or field repair.

### 7. Add the smallest vehicle delegation seam

Do not grow `PilotableVehicle` into a VFX state machine.

Recommended narrow additions:

```gdscript
@onready var recovery_fx_presenter: Node = get_node_or_null("VehicleRecoveryFxPresenter")

func present_recovery_fx(state_id: StringName) -> void:
    if is_instance_valid(recovery_fx_presenter) and recovery_fx_presenter.has_method("play_once"):
        recovery_fx_presenter.call("play_once", state_id)
```

After `_initialize_as_wreckage()` creates/configures `VehicleRestorationInteraction`, call the presenter's `bind_restoration_interaction()` exactly once when the presenter exists. If reviewed predecessor refactors interaction creation, bind at its final single ownership seam rather than recreating it.

No recovery-FX timing/queue logic belongs in `pilotable_vehicle.gd`.

### 8. Wire service scan through the reviewed scanner

Do not add input reads or scan logic to the vehicle.

In the landed `operator_vehicle_scanner.gd` (or the exact reviewed successor path), after it has selected a valid `PilotableVehicle` target for a service scan attempt, invoke:

```gdscript
target.present_recovery_fx(&"scan_sweep_01")
```

when that method exists.

Play the scan effect for a legitimate scan attempt even if the knowledge authority later reports `ALREADY_SCANNED`; scanning occurred, but no new knowledge is granted. Do not use `fault_ping_01` for anti-farm/no-new-information results. The scan effect must not alter result dictionaries or progression state.

### 9. Mount the presenter on the Field Scout

Instance `vehicle_recovery_fx_presenter.tscn` as exactly one child of `FieldScoutBuggyMk1`.

The existing body `AnimatedSprite2D` is positioned at `Vector2(0, -8)`. Set the presenter child to the same `Vector2(0, -8)` visual origin so center-registered 256px effects align to the vehicle art without baking a Scout-specific translation into the shared presenter script.

Future vehicle classes may choose their own presenter child offset. Do not add a global Scout offset constant to the shared FX family.

### 10. Focused runtime proof

Create:

`custodian/tools/validation/vehicle_recovery_fx_smoke.gd`

Register it in `custodian/tools/validation/validation_manifest.json` with ownership over the new presenter, builder/generated resource, narrow signal/delegation seams, and recovery FX family/runtime outputs.

The smoke must instantiate a real Scout or production-equivalent reviewed fixture and prove:

1. six exact animations/frame counts/FPS/loop flags exist;
2. presenter starts hidden and fails soft with a deliberately missing animation;
3. service scan delegates `scan_sweep_01` without knowledge/HP/resource mutation;
4. held restoration start loops install sparks;
5. release/range/target cancellation stops it, emits no fault ping, and consumes nothing;
6. mechanical requirement/contract failure plays one fault ping and consumes nothing;
7. successful held restoration produces one `started`, zero cancellation, one completion, then the exact three-state visual sequence;
8. vehicle is mechanically restored/enterable before the cosmetic sequence finishes;
9. removing/omitting the presenter does not alter recovery success;
10. no runtime path or loaded resource points into Dropbox or `asset_drop`.

Use structured animation/state assertions and minimal pixel/alpha metrics before any rendered visual inspection. The source art is already human-selected in the authoring chat, so no new subjective visual approval gate is required unless deterministic normalization exposes a genuinely ambiguous frame grouping.

## Documentation Drift Closeout

After successful ingest/wiring, reconcile only active truth made stale by this work:

- `design/02_features/vehicles/VEHICLE_RECOVERY_ART_MANIFEST.md`: record the immutable V7 source handoff and mark the six states source-complete/ingested only at the lifecycle actually proven; retain `restore_failure_01` optional.
- `design/02_features/vehicles/VEHICLE_RECOVERY_IMPLEMENTATION_ROADMAP.md`: V7 is this workstream and is not complete until its paired review passes.
- `custodian/content/metadata/assets/required_assets.registry.json` and generated `REQUIRED_ASSETS.md`: mark only proven six FX fulfilled; leave icons/props and other art gaps honest.
- `custodian/docs/ai_context/FILE_INDEX.md`: add the new presenter and deterministic SpriteFrames builder if project indexing conventions require it.

Do not rewrite historical Dropbox ZIPs or archived packets to make their old measured state look current.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile the landed V6 family JSON, final V3/V4C restoration reason names/API, and final V2 scanner path before mutation. Preserve this packet's human-approved source bytes, six state identities, event-to-FX mapping, and presentation-only authority. Escalate only if a landed predecessor materially changed the visual state contract or removed the single held-restoration/scanner seams this packet consumes.

## Handoff

- Next workstream: `review-vehicle-recovery-fx-production-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Land the six-state Asset V2 production ingest and reusable runtime presenter, then hand the exact source/normalization/runtime evidence to the fresh-context paired reviewer.
- Blockers or open questions: `none; packet remains dependency-gated until V6R archives complete and the reviewed predecessor APIs exist on main.`