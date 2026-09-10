# Asset Pipeline V2 — Unified Asset Intake System

**Status:** Active production implementation, V2.1 unified non-Operator intake
**Scope:** Orchestration layer above existing backends
**Authority:** This document + `custodian/tools/assets/`

---

## Overview

Asset Pipeline V2 provides a single human-facing workflow for adding production art to CUSTODIAN. It sits above the existing specialized backends (runtime-ready, sprite ingest, Operator) and handles:

- **Semantic contracts** — family definitions declare artistic intent
- **Inspection & inference** — frame dimensions and layouts derived from pixels
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

No canonical naming required. Use human-readable state names. Asset Pipeline V2 owns canonical runtime routing and naming.

### 3. Preview the Plan

```bash
asset plan field_fabricator_mk1
```

Shows:

- source file → resolved state
- frame inference
- canonical filename
- target runtime path
- backend selection
- replacement/conflict warnings

### 4. Ingest

```bash
asset ingest field_fabricator_mk1 --yes
```

Or omit `--yes` for interactive confirmation.

### 5. Check Status

```bash
asset status field_fabricator_mk1
```

Status is layered rather than binary. A family/state can be:

```text
SOURCE_PENDING
ART_PRESENT
IMPORTED
BOUND
RUNTIME_VERIFIED
```

Required completeness is based on catalog-backed runtime art, not inbox presence.

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
| `asset doctor` | Health checks for contracts, inboxes, catalog, and consumers |

### Terminal information architecture

The CLI is answer-first. Default output presents, in order: the subject, answer or status, blockers, attention items, changes, and the next command.

Pipeline evidence such as classifier confidence, resolution reason, backend, layout, provenance paths, binding, and validation evidence belongs under `--verbose`. Expected successful inference stays quiet; ambiguity and unsafe replacement remain prominent.

`plan`, `status`, `request`, `families`, and `doctor` support `--json` for stable machine-readable output. Human output is not an API and must not be scraped.

Symbols have consistent non-color semantics: `✓` ready/success, `→` pending, `·` not performed or unavailable, `⚠` inspect/non-blocking, `✗` blocking, and `◐` partial. Absent runtime validation evidence is reported as `not verified`, never as a failed verification.

Errors include the rejected subject and a concrete recovery command, example, or registration path. `new` prints resolved defaults so kind, direction, mirroring, domain, owner, and canvas mistakes are visible immediately. `ingest` ends with a receipt summary before archive and job identifiers.

---

## Family Contract Schema

Current production family contracts use `custodian.asset_family.v2`. V1 remains readable for migration compatibility, but new and actively maintained families should use V2.

```json
{
  "schema": "custodian.asset_family.v2",
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
  "auto_mirror": false,

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
      "layout": "horizontal_strip",
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
      "layout": "horizontal_strip",
      "fps": 8
    }
  },

  "aliases": {
    "working": "fabricate",
    "powered": "fabricate_fx"
  },

  "consumers": [
    {
      "type": "scene",
      "path": "res://game/infrastructure/structures/field_fabricator_mk1.tscn"
    }
  ]
}
```

`frames` is an optional exact source-frame contract. Missing optional or recommended states remain non-blocking, but once a matching source is supplied the planner rejects a strip whose inferred frame count differs from the contract.

### State Fields

| Field | Purpose |
|-------|---------|
| `layer` | `body`, `fx`, `weapon`, etc. |
| `action_group` | `locomotion`, `attack`, `interaction`, `state`, etc. |
| `variant` | Canonical semantic variant |
| `required` | Must be present for required completeness |
| `recommended` | Warned when missing but not required for completeness |
| `animation` | Whether the state is animated |
| `layout` | Explicit `copy`, `horizontal_strip`, `vertical_strip`, or `grid` contract when needed |
| `frames` | Optional exact frame count, enforced when a source is supplied |
| `fps` | Playback hint for animated states |
| per-state canvas override | Allows a state to override the family default frame size |
| direction requirements | Declare authored direction requirements for the state |

### Aliases

Aliases map human-friendly source names to canonical state IDs, for example:

- `working` → `fabricate`
- `fabricating` → `fabricate`
- `powered` → `fabricate_fx`

---

## Canonical Filename Grammar

Canonical runtime filenames are generated from semantic identity:

```text
<owner>__<layer>__<action_group>__<variant>__<direction>__<N>f__<WxH>.png
```

Examples:

- `field_fabricator_mk1__body__interaction__idle__omni__8f__156.png`
- `field_fabricator_mk1__body__interaction__fabricate__omni__8f__156.png`
- `field_fabricator_mk1__fx__interaction__fabricate__omni__8f__156.png`

**Humans do not hand-author canonical runtime names.** They are derived output.

---

## Frame Inference and Layout Rules

Given family canvas `128×96`:

| Source Dimensions | Layout | Frames | V2.1 behavior |
|-------------------|--------|-------:|---------------|
| 128×96 | `copy` | 1 | Supported |
| 512×96 | `horizontal_strip` | 4 | Supported |
| 128×384 | `vertical_strip` | 4 | Supported; normalized losslessly in transaction staging |
| 384×384 | ambiguous without explicit grid dimensions | — | Fail closed until grid dimensions are declared |

Grid inference is deliberately not guessed from a square sheet. Explicit dimensions are required so ambiguous input never silently becomes the wrong animation.

---

## Backend Selection

| Condition | Backend |
|-----------|---------|
| Single frame (`copy`) | `runtime_ready` |
| Multi-frame strip/grid | `sprite_ingest` |
| Operator semantic asset | `operator` adapter/delegation |

The existing heavy backends are preserved:

- `runtime_ready_assets.py` — conflict detection, SHA-256, archive, Godot import
- `generate_inbox_manifests.py` + `ingest_runtime.gd` — frame slicing, mirroring, post-process
- `operator_asset_schema.py` — Operator animation identity and profiles

---

## Transaction Model

Every ingest creates a job staging area:

```text
asset_drop/staging/job_YYYYMMDDTHHMMSSZ_xxxxxxxx/
    ├── backup_of_replaced_target.png
    └── transaction journal state
```

On failure after commit:

1. Remove created V2-controlled targets.
2. Restore replaced V2-controlled targets from backups.
3. Restore/remove repository-owned `.png.import` sidecars according to their pre-transaction state.
4. Restore archived inputs as required by the transaction record.
5. Clean staging state.

Only outputs declared by the V2 plan, generated catalog, archived human inputs, and repository-owned import sidecars are transactionally bounded. Specialized post-process hooks that mutate undeclared outputs remain delegated/non-transactional and must not be presented as rollback-safe.

### Godot `.import` sidecars

Repository-owned `.import` sidecars participate in rollback. For every planned runtime output and superseded runtime target, the transaction journals `<target>.png.import` alongside the PNG.

- Existing sidecars are backed up and restored byte-for-byte.
- Sidecars absent before the transaction are treated as created targets and removed on rollback if Godot writes them.

The sidecar path is built as `Path(str(target) + ".import")`, never `with_suffix(".import")`, which would incorrectly yield `<target>.import`.

Godot's `.godot/imported/` cache is disposable, outside repository coverage, and deliberately not journaled.

---

## Provenance

Current ingest receipts use `custodian.asset_ingest_job.v2` and are written to `asset_drop/logs/job_<id>.json`.

Representative shape:

```json
{
  "schema": "custodian.asset_ingest_job.v2",
  "job_id": "job_20260908T145927Z_40a9ee82",
  "timestamp": "2026-09-08T14:59:27Z",
  "family": "field_fabricator_mk1",
  "kind": "world_prop",
  "inputs": [
    {
      "path": "asset_drop/inbox/field_fabricator_mk1/idle.png",
      "sha256": "..."
    }
  ],
  "outputs": [
    {
      "state_id": "idle",
      "direction": "omni",
      "path": "content/sprites/...png",
      "provenance": "authored",
      "operation": "create",
      "backend": "runtime_ready",
      "sha256": "..."
    }
  ],
  "godot_import": {
    "attempted": false,
    "ok": null
  },
  "validation_evidence": [],
  "result": "success"
}
```

Successful V2 inputs move to `asset_drop/archive/<job_id>/<family>/`. Dry-run, ambiguity, conflict, and failure do not archive inputs as successful work.

---

## Generated Catalog

Current generated catalog:

```text
content/metadata/assets/generated/asset_catalog.generated.json
```

uses `custodian.asset_catalog.v2` and keys assets by `<state_id>::<direction>`.

Representative shape:

```json
{
  "schema": "custodian.asset_catalog.v2",
  "families": {
    "field_fabricator_mk1": {
      "kind": "world_prop",
      "assets": {
        "idle::omni": {
          "state_id": "idle",
          "direction": "omni",
          "semantic_identity": [
            "field_fabricator_mk1",
            "world_prop",
            "body",
            "interaction",
            "idle",
            "omni"
          ],
          "path": "content/sprites/environment/props/field_fabricator_mk1/runtime/body/...",
          "frames": 1,
          "frame_size": [156, 156],
          "provenance": "authored",
          "sha256": "..."
        }
      }
    }
  }
}
```

The generated catalog is tooling metadata, not a gameplay dependency.

---

## Compatibility

| Old Workflow | Status |
|--------------|--------|
| `asset_drop/runtime_ready/inbox/` | Preserved backend |
| `content/sprites/_pipeline/inbox/` | Preserved sprite backend |
| `generate_inbox_manifests.py` | Preserved sprite backend tooling |
| `runtime_ready_assets.py` | Preserved runtime-ready backend tooling |
| `operator_asset_schema.py` | Preserved Operator adapter/authority |
| `dryjson`, `runjson`, `runsprite`, `opingest` aliases | Preserved compatibility aliases |

The `asset` CLI is the preferred human interface for non-Operator Asset V2 intake.

`asset_drop/.gdignore` keeps human inbox, staging, archive, and receipt data outside Godot resource authority.

`asset ingest --godot-import` explicitly runs headless import. The default timeout is **300 seconds**, owned by `DEFAULT_GODOT_IMPORT_TIMEOUT_SEC` in `adapters/godot_import.py`; the CLI flag reads that default rather than defining a second authority. Override per run with:

```bash
asset ingest <family> --godot-import --godot-import-timeout <seconds>
```

A timeout reports the configured value.

`BOUND` remains separate from `ART_PRESENT`. A family can be fully ingested but unbound when no declared consumer references its canonical `res://` output. `RUNTIME_VERIFIED` likewise requires explicit validation evidence.

---

## Field Fabricator Mk1 Acceptance Fixture

This fixture is a production Asset V2 family rather than the original 128×96 scaffold example.

### Input

```text
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

```text
content/sprites/environment/props/field_fabricator_mk1/runtime/
    body/interaction/*__8f__156.png
    fx/interaction/*__8f__156.png
```

### Backend Selection

| File | Layout | Backend |
|------|--------|---------|
| all nine lifecycle sheets | horizontal strip (8f) | sprite ingest |

---

## Known Limitations (V2.1)

1. **Grid dimensions are explicit.** Ambiguous grid inference deliberately fails closed rather than guessing.
2. **Consumer wiring is explicit.** Asset V2 does not automatically rewrite arbitrary Godot consumers.
3. **Post-process rollback is bounded.** V2-controlled outputs and repository-owned import sidecars are journaled, but undeclared side effects of specialized hooks are not generally transactional.
4. **No watch daemon is required or active.** Intake remains explicit through the CLI.
5. **Operator remains delegated.** Operator identity and runtime building remain owned by `OperatorAssetKey` and `build_operator_runtime.py` rather than a parallel Asset V2 implementation.

---

## V2.1 Production Contract

The `asset` CLI is the normal intake interface for non-Operator art. Registered `custodian.asset_kind.v2` schemas cover `world_prop`, `enemy`, `tile`, `effect`, `vehicle`, `weapon`, `ui`, and `backdrop`; adding a simple kind does not require an `asset.py` branch.

Family V2 adds direction requirements, automatic mirror policy, explicit copy/horizontal/vertical/grid layouts, and per-state canvas overrides while retaining V1 read compatibility.

Plans declare every authored and mirrored output before mutation. The generated tooling catalog uses `custodian.asset_catalog.v2` keys of `<state_id>::<direction>`, records provenance, and is never gameplay authority.

Vertical strips are losslessly normalized in transaction staging; grids require explicit dimensions. The orchestration layer delegates sprite slicing, frame-safe mirroring, and runtime import hooks to the mature sprite backend and static copies to the runtime-ready backend.

Consumer gameplay binding remains explicit. Godot's `.godot/` import cache is not transactional. Declared post-process hooks that mutate outputs beyond the plan are reported as delegated/non-transactional rather than being presented as rollback-safe.

---

## Milestone State

| Milestone | Scope | State |
|-----------|-------|-------|
| 5 | Stronger/full backend rollback | Partial; V2-controlled outputs and repository-owned `.png.import` sidecars are covered, arbitrary delegated hook effects are not |
| 6 | Safe consumer binding / typed scene adapters | Remaining |
| 7 | `asset watch` automatic intake | Deferred / not required for current production workflow |
| 8 | Schema-driven enemy, tile, effect, vehicle, weapon, UI, and backdrop intake | Complete in V2.1 |
| 9 | Bounded consumer-migration adapters for semantic replacements that rename concrete files | Remaining |

---

## Primary Implementation Files

| Path | Purpose |
|------|---------|
| `custodian/tools/assets/asset.py` | CLI entry point |
| `custodian/tools/assets/asset_key.py` | Semantic identity (`AssetKey`) |
| `custodian/tools/assets/asset_naming.py` | Canonical filename generation |
| `custodian/tools/assets/asset_contract.py` | Family contract model + loading |
| `custodian/tools/assets/asset_inspector.py` | PNG inspection + frame/layout inference |
| `custodian/tools/assets/asset_classifier.py` | State resolution + confidence |
| `custodian/tools/assets/asset_router.py` | Schema-driven routing |
| `custodian/tools/assets/asset_plan.py` | Plan generation and mutation boundary |
| `custodian/tools/assets/asset_status.py` | Layered status reporting |
| `custodian/tools/assets/asset_doctor.py` | Health checks |
| `custodian/tools/assets/asset_catalog.py` | V2 generated catalog |
| `custodian/tools/assets/asset_transaction.py` | Transaction journal + rollback |
| `custodian/tools/assets/adapters/runtime_ready.py` | Runtime-ready backend wrapper |
| `custodian/tools/assets/adapters/sprite_ingest.py` | Sprite pipeline wrapper |
| `custodian/tools/assets/adapters/godot_import.py` | Godot import trigger |
| `custodian/content/metadata/assets/generated/asset_catalog.generated.json` | Generated V2 catalog |
| `custodian/content/metadata/assets/families/*.asset.json` | Registered family contracts |

---

## Validation

Use focused current validation first:

```bash
python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py
python3 custodian/tools/validation/asset_pipeline_cli_ux_smoke.py
```

Then exercise the CLI as appropriate:

```bash
python3 custodian/tools/assets/asset.py families
python3 custodian/tools/assets/asset.py plan field_fabricator_mk1
python3 custodian/tools/assets/asset.py status field_fabricator_mk1
python3 custodian/tools/assets/asset.py request field_fabricator_mk1
python3 custodian/tools/assets/asset.py doctor
```
