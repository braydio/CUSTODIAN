# Asset Pipeline V2 — Unified Asset Intake System

**Status:** Active production implementation, V2.1 unified non-Operator intake
**Scope:** Orchestration layer above existing backends
**Authority:** This document + `custodian/tools/assets/`

---

## Overview

Asset Pipeline V2 provides a single human-facing workflow for adding production art to CUSTODIAN. It sits above the existing specialized backends (runtime-ready, sprite ingest, Operator) and handles:

- **Semantic contracts** — family definitions declare artistic intent
- **Inspection & inference** — frame dimensions, layouts derived from pixels
- **Canonical naming** — generated, never hand-authored
- **Schema-driven routing** — targets computed from semantic identity
- **Transactional staging** — dry-run → confirm → apply with rollback
- **Provenance & catalog** — every job logged, outputs tracked

---

## Architecture

```
ASSET INTAKE SYSTEM
        |
        v
semantic asset contract (.asset.json)
        |
        v
inspection / classification (pure functions)
        |
        v
ingest plan (read-only, testable)
        |
        +---------------------+
        |                     |
        v                     v
runtime-ready backend    sprite-ingest backend
(copy + import)          (strip/grid + post-process)
        |                     |
        +----------+----------+
                   |
                   v
            Godot import
                   |
                   v
         validation / catalog / status
```

---

## User Workflow

### 1. Create a Family Contract (one-time)

```bash
asset new field_fabricator_mk1 --kind world_prop --size 156x156
```

Creates:
- `content/metadata/assets/families/field_fabricator_mk1.asset.json`
- `asset_drop/inbox/field_fabricator_mk1/`

### 2. Drop Art Files

```text
custodian/asset_drop/inbox/field_fabricator_mk1/
    idle.png       # 1248x156 (8-frame horizontal strip)
    fabricate.png  # 1248x156 (8-frame horizontal strip)
    fabricate_fx.png
```

No canonical naming required. Just human-readable state names.

### 3. Preview the Plan

```bash
asset plan field_fabricator_mk1
```

Shows:
- Source file → resolved state
- Frame inference (8x 156x156 strip detected)
- Canonical filename generated
- Target runtime path
- Backend selection
- Replacement/conflict warnings

### 4. Ingest

```bash
asset ingest field_fabricator_mk1 --yes
```

Or without `--yes` for interactive confirmation.

### 5. Check Status

```bash
asset status field_fabricator_mk1
```

```
FIELD_FABRICATOR_MK1

  required
      ✓ idle
      ✓ startup
      ✓ fabricate
      ✓ fabricate_complete
      ✓ offline
  recommended
      ✓ idle_fx
      ✓ startup_fx
      ✓ fabricate_fx
      ✓ fabricate_complete_fx
  optional
      ○ damaged
      ○ destroyed
  consumer
    res://game/infrastructure/structures/field_fabricator_mk1.tscn
  production completeness: 5/5 required
```

---

## Commands

| Command | Purpose |
|---------|---------|
| `asset plan [family]` | Read-only preview of ingest |
| `asset ingest [family] [--yes] [--dry-run] [--replace]` | Apply plan |
| `asset status [family]` | Production completeness + runtime binding |
| `asset families` | List registered families |
| `asset new <family> --kind <kind> [--size WxH] [--direction omni]` | Create family contract + inbox |
| `asset request <family> [--write]` | Print art request checklist |
| `asset doctor` | Health checks (contracts, inbox, consumers) |

---

## Family Contract Schema

```json
{
  "schema": "custodian.asset_family.v1",
  "id": "field_fabricator_mk1",
  "kind": "world_prop",

  "runtime": {
    "domain": "sprites/environment/props",
    "owner": "field_fabricator_mk1"
  },

  "canvas": {
    "width": 156,
    "height": 156
  },

  "direction_policy": "omni",

  "states": {
    "idle": {
      "required": true,
      "layer": "body",
      "action_group": "interaction",
      "variant": "idle"
    },
    "fabricate": {
      "required": true,
      "layer": "body",
      "action_group": "interaction",
      "variant": "fabricate",
      "animation": true,
      "frames": 8,
      "fps": 8
    },
    "fabricate_fx": {
      "required": false,
      "recommended": true,
      "layer": "fx",
      "action_group": "interaction",
      "variant": "fabricate",
      "animation": true,
      "fps": 8
    }
  },

  "aliases": {
    "working": "fabricate",
    "powered": "fabricate_fx"
  },

  "consumers": [
    { "type": "scene", "path": "res://game/infrastructure/structures/field_fabricator_mk1.tscn" }
  ]
}
```

`frames` is an optional exact source-frame contract. Missing optional or recommended states remain non-blocking, but once a matching source is supplied the planner rejects a strip whose inferred frame count differs from this value.

### State Fields

| Field | Purpose |
|-------|---------|
| `layer` | `body`, `fx`, `weapon`, etc. |
| `action_group` | `locomotion`, `attack`, `interaction`, `state`, etc. |
| `variant` | Canonical variant name (used in filename) |
| `required` | Must be present for completeness |
| `recommended` | Should be present, warned if missing |
| `animation` | True if multi-frame strip expected |
| `frames` | Optional exact frame count, enforced when a source is supplied |
| `fps` | Playback hint for animated states |

### Aliases

Map human-friendly names to canonical state IDs:
- `working` → `fabricate`
- `fabricating` → `fabricate`
- `powered` → `fabricate_fx`

---

## Canonical Filename Grammar

Generated automatically from semantic identity:

```
<owner>__<layer>__<action_group>__<variant>__<direction>__<N>f__<WxH>.png
```

Examples:
- `field_fabricator_mk1__body__interaction__idle__omni__8f__156.png`
- `field_fabricator_mk1__body__interaction__fabricate__omni__8f__156.png`
- `field_fabricator_mk1__fx__interaction__fabricate__omni__8f__156.png`

**Humans never type these.** They are derived output.

---

## Frame Inference Rules

Given family `canvas: {width: 128, height: 96}`:

| Source Dimensions | Inferred Layout | Frames |
|-------------------|-----------------|--------|
| 128×96 | `copy` | 1 |
| 512×96 | `horizontal_strip` | 4 (512÷128) |
| 128×384 | `vertical_strip` | — (unsupported V1) |
| 384×384 | `ambiguous` | — (requires grid policy) |

**Ambiguous** → never auto-ingested. Reported in plan.

---

## Backend Selection

| Condition | Backend |
|-----------|---------|
| Single frame (`copy` layout) | `runtime_ready` |
| Multi-frame strip/grid | `sprite_ingest` |
| Operator semantic asset | `operator` |

The existing heavy backends are preserved:
- `runtime_ready_assets.py` — conflict detection, SHA-256, archive, Godot import
- `generate_inbox_manifests.py` + `ingest_runtime.gd` — frame slicing, mirroring, post-process
- `operator_asset_schema.py` — Operator V2 animation profiles

---

## Transaction Model

Every ingest creates a job:

```
asset_drop/staging/job_YYYYMMDDTHHMMSSZ_xxxxxxxx/
    ├── backup_of_replaced_target.png
    └── (journal written to asset_drop/logs/)
```

On failure after commit:
1. Remove created targets
2. Restore replaced targets from backups
3. Clean staging directory

Only outputs directly declared by the V2 plan, the generated catalog, and archived
human inputs are covered. Side effects of specialized post-process hooks are not yet
fully transactional. Pre-existing duplicate outputs are never recorded as creates and
therefore are never deleted during rollback.

---

## Provenance

Each job logs to `asset_drop/logs/job_<id>.json`:

```json
{
  "job_id": "job_20260819T120000Z_abc12345",
  "timestamp": "2026-08-19T12:00:00Z",
  "family": "field_fabricator_mk1",
  "schema": "custodian.asset_ingest_job.v1",
  "inputs": [{"path": "asset_drop/inbox/field_fabricator_mk1/idle.png", "sha256": "..."}],
  "assets": [{"state": "idle", "operation": "create", "backend": "runtime_ready",
              "output": "content/sprites/...png", "output_sha256": "..."}],
  "godot_import": {"attempted": false, "ok": null},
  "result": "success"
}
```

---

## Generated Catalog

`content/metadata/assets/generated/asset_catalog.generated.json`

```json
{
  "schema": "custodian.asset_catalog.v1",
  "families": {
    "field_fabricator_mk1": {
      "kind": "world_prop",
      "states": {
        "idle": {
          "semantic_identity": ["field_fabricator_mk1", "world_prop", "body", "interaction", "idle", "omni"],
          "path": "content/sprites/environment/props/field_fabricator_mk1/runtime/body/...",
          "frames": 1,
          "frame_size": [128, 96],
          "sha256": "..."
        }
      }
    }
  }
}
```

**Not a gameplay dependency.** Tooling metadata only.

---

## Compatibility

| Old Workflow | Status |
|--------------|--------|
| `asset_drop/runtime_ready/inbox/` | Preserved (backend) |
| `content/sprites/_pipeline/inbox/` | Preserved (sprite backend) |
| `generate_inbox_manifests.py` | Preserved (sprite backend) |
| `runtime_ready_assets.py` | Preserved (runtime-ready backend) |
| `operator_asset_schema.py` | Preserved (Operator adapter) |
| `dryjson`, `runjson`, `runsprite`, `opingest` aliases | Preserved |

The new `asset` command is now the **preferred** human interface.

`asset_drop/.gdignore` keeps all human inbox, staging, archive, and receipt data
outside Godot resource authority. Successful V2 inputs move to
`asset_drop/archive/<job_id>/<family>/`; dry-run, ambiguity, conflict, and failure do
not archive them. `asset ingest --godot-import` explicitly runs headless import.

Status is layered: `SOURCE_PENDING`, `ART_PRESENT`, `IMPORTED`, `BOUND`, and
`RUNTIME_VERIFIED`. Required completeness uses catalog-backed runtime art, never inbox
presence. `BOUND` requires a declared consumer to reference the canonical `res://`
path; runtime verification requires explicit validation evidence.

---

## Field Fabricator Mk1 — Acceptance Fixture

This fixture is now a production Asset V2 family rather than the original
128×96 scaffold example.

### Input
```
asset_drop/inbox/field_fabricator_mk1/
    idle.png                  (1248×156 → 8×156×156 strip)
    startup.png               (1248×156 → 8×156×156 strip)
    fabricate.png             (1248×156 → 8×156×156 strip)
    fabricate_complete.png    (1248×156 → 8×156×156 strip)
    offline.png               (1248×156 → 8×156×156 strip)
    idle_fx.png               (1248×156 → 8×156×156 strip)
    startup_fx.png            (1248×156 → 8×156×156 strip)
    fabricate_fx.png          (1248×156 → 8×156×156 strip)
    fabricate_complete_fx.png (1248×156 → 8×156×156 strip)
```

### Generated Output
```
content/sprites/environment/props/field_fabricator_mk1/runtime/
    body/interaction/*__8f__156.png
    fx/interaction/*__8f__156.png
```

### Backend Selection
| File | Layout | Backend |
|------|--------|---------|
| all nine lifecycle sheets | horizontal_strip (8f) | sprite_ingest |

---

## Known Limitations (V1)

1. **Grid inference is deliberately not automatic** — grids require explicit columns and rows so ambiguous sheets fail closed.
3. **No auto-wiring of Godot scenes** — consumer binding remains manual
4. **Transaction rollback limited to V2-controlled outputs** — GDScript post-process hooks not yet transactional
5. **No watch mode** — `asset watch` deferred to Milestone 5
6. **Operator remains delegated** — Operator identity and runtime building remain owned by `OperatorAssetKey` and `build_operator_runtime.py`.

## V2.1 production contract

The `asset` CLI is the normal intake interface for non-Operator art. Registered
`custodian.asset_kind.v2` data schemas currently cover `world_prop`, `enemy`,
`tile`, `effect`, `vehicle`, `weapon`, `ui`, and `backdrop`; adding a simple kind
does not require an `asset.py` branch. Family V2 adds direction requirements,
automatic mirror policy, explicit copy/horizontal/vertical/grid layouts, and
per-state canvas overrides while retaining V1 read compatibility.

Plans declare every authored and mirrored output before mutation. The generated
tooling catalog uses `custodian.asset_catalog.v2` keys of
`<state_id>::<direction>`, records provenance, and is never gameplay authority.
Vertical strips are losslessly normalized in transaction staging; grids require
explicit dimensions. The orchestration layer delegates sprite slicing,
frame-safe mirroring, and runtime import hooks to the mature sprite backend and
static copies to the runtime-ready backend.

Consumer gameplay binding remains explicit. Godot's `.godot/` import cache is
not transactional, and bounded PNG/catalog/archive outputs are rolled back by
V2. Declared post-process hooks that mutate outputs beyond the plan are reported
as delegated/non-transactional rather than being presented as rollback-safe. A
watch daemon is not required.

---

## Next Milestones

| Milestone | Scope |
|-----------|-------|
| 5 | Strong transactions (full backend rollback) |
| 6 | Safe consumer binding (typed scene adapters) |
| 7 | `asset watch` (auto-ingest on EXACT drops) |
| 8 | Complete: schema-driven enemy, tile, effect, vehicle, weapon, UI, and backdrop intake |
| 9 | Bounded consumer-migration adapters for semantic replacements that rename concrete files |

---

## Files Added

| Path | Purpose |
|------|---------|
| `custodian/tools/assets/__init__.py` | Package root |
| `custodian/tools/assets/asset.py` | CLI entry point |
| `custodian/tools/assets/asset_key.py` | Semantic identity (AssetKey) |
| `custodian/tools/assets/asset_naming.py` | Canonical filename generation |
| `custodian/tools/assets/asset_contract.py` | Family contract model + loading |
| `custodian/tools/assets/asset_inspector.py` | PNG inspection + frame inference |
| `custodian/tools/assets/asset_classifier.py` | State resolution + confidence |
| `custodian/tools/assets/asset_router.py` | Schema-driven routing |
| `custodian/tools/assets/asset_plan.py` | Plan generation (mutation boundary) |
| `custodian/tools/assets/asset_status.py` | Status reporting |
| `custodian/tools/assets/asset_doctor.py` | Health checks |
| `custodian/tools/assets/asset_catalog.py` | Generated catalog |
| `custodian/tools/assets/asset_transaction.py` | Transaction journal + rollback |
| `custodian/tools/assets/adapters/__init__.py` | Adapters package |
| `custodian/tools/assets/adapters/runtime_ready.py` | Runtime-ready backend wrapper |
| `custodian/tools/assets/adapters/sprite_ingest.py` | Sprite pipeline wrapper |
| `custodian/tools/assets/adapters/godot_import.py` | Godot import trigger |
| `custodian/content/metadata/assets/families/field_fabricator_mk1.asset.json` | First production family |
| `custodian/content/metadata/assets/schemas/world_prop.json` | First kind schema |
| `custodian/tools/validation/asset_pipeline_v2_smoke.py` | Smoke tests |

## Files Modified

| Path | Change |
|------|--------|
| `tools/custodian_aliases.sh` | Added `asset` alias |

---

## Validation

```bash
# All smoke tests pass
python3 custodian/tools/validation/asset_pipeline_v2_smoke.py

# Existing pipelines still work
python3 custodian/tools/pipelines/runtime_ready_assets.py --dry-run
python3 custodian/tools/pipelines/generate_inbox_manifests.py --dry-run

# New workflow
asset new test_prop --kind world_prop
asset plan field_fabricator_mk1
asset ingest field_fabricator_mk1 --yes
asset status field_fabricator_mk1
asset request field_fabricator_mk1
asset doctor
```
