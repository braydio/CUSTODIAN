# Asset Workbench Roadmap

**Status:** active implementation roadmap  
**Baseline reviewed main:** `a9be70ded8c7d0f63cfc471d684086ef1c5ed287`  
**Owner:** tooling / Asset Pipeline V2  
**Runtime target:** CUSTODIAN non-Operator asset authoring and review  
**Last updated:** 2026-09-29

## Purpose

Build a general visual Asset Workbench over Asset Pipeline V2 without turning
Operator-specific animation tooling into a universal asset authority.

The Workbench is a UI/control-plane layer. Existing authorities remain
authoritative:

- `custodian.asset_family.v2` family contracts define non-Operator asset semantics.
- `custodian/tools/assets/` owns family parsing, status, planning, routing,
  transactions, catalog, requirements, and doctor behavior.
- Asset Pipeline V2 runtime outputs and catalog remain production truth.
- Operator keeps its specialized animation schema, Workbench, runtime builder,
  and publisher.
- Shared UI primitives may be extracted only when both workbenches can consume
  them without importing one domain's backend into the other.

This roadmap owns sequencing and closure boundaries. It does not duplicate
technical schema truth already owned by Asset Pipeline V2.

## Product Shape

The intended end-state is one general Asset Workbench with domain-aware lenses,
not separate applications for NPCs, enemies, fauna, props, vehicles, and FX.

```text
                        SHARED WORKBENCH UI PRIMITIVES
                                   |
                  +----------------+----------------+
                  |                                 |
          OPERATOR WORKBENCH                 ASSET WORKBENCH
          specialized backend                Asset Pipeline V2
                  |                                 |
      Operator semantic/runtime            family/status/plan/catalog
      modular animation authoring          non-Operator asset families
      Aseprite round-trip/publish          transactional ingest/publish
                  |                                 |
                  +--------- shared review UX ------+
```

Actor/NPC workflows are a lens inside Asset Workbench. They do not receive a
parallel asset database or publisher.

## V1 Boundary

Asset Workbench V1 is complete after **Slices 1–3**:

1. FAMILY navigator and truthful read model;
2. REVIEW studio for static/animated source/runtime art;
3. PIPELINE planning, ingest, validation, and safe one-action landing.

Slices 4+ are additive capability after the V1 control plane is proven.

## Roadmap Maintenance Contract

This file is a live implementation roadmap.

Every Asset Workbench implementation packet must:

1. read this roadmap against current `origin/main` before editing;
2. update the slice table and relevant slice section in the **same workstream**
   whenever implementation changes status, scope, ownership, dependencies,
   acceptance, or later-slice assumptions;
3. record concrete landed evidence rather than optimistic completion claims;
4. revise future slices when live architecture proves a better boundary;
5. never mark a future slice complete merely because lower-level plumbing
   happens to exist;
6. preserve Asset Pipeline V2 and Operator docs as the technical authorities
   for their respective backends;
7. update this document's `Last updated` and `Last reconciled main` fields
   before closing a slice.

If a later investigation shows that a planned slice is too large, split it and
renumber the remaining roadmap explicitly. If two slices collapse into one
coherent implementation boundary, document that decision here rather than
silently skipping a number.

## Current Architecture Facts

As of the baseline above:

- Asset Pipeline V2 is already the preferred human-facing non-Operator intake
  authority and supports `new`, `families`, `status`, `request`, `plan`,
  `ingest`, `needs`, and `doctor`.
- `asset_contract.py` exposes validated immutable family/state contracts.
- `asset_status.py` exposes family/state lifecycle truth including pending
  source, runtime art, authored/mirrored directions, import, binding, and
  runtime-validation evidence.
- `asset_plan.py` exposes a pure plan with inspected source geometry,
  semantic resolution, backend choice, target paths, mirror provenance,
  replacement/conflict state, and blocking errors.
- `asset.py` currently combines CLI presentation and transaction orchestration;
  a Workbench must call real Python authorities rather than parse CLI text.
- Operator's preview canvas, filmstrip, controls, and review concepts are proven
  UX references, but they currently live under the Operator package and may not
  become Asset Pipeline authority.
- `ambient_baby_opossum` is a useful acceptance family: 96×96, 4-direction,
  auto-mirror, many semantic groups, body plus `barrel_prop` states, static
  holds, animated states, and incomplete/unresolved production coverage.

## Slice Status

| Slice | Workstream | Status | Completion focus | Evidence |
|---|---|---|---|---|
| **1. Family Navigator Foundation** | `asset-workbench-family-foundation` | ready | Read-only Asset V2 family/state cockpit and stable UI/read-model boundary | `ASSET_WORKBENCH_FAMILY_FOUNDATION.md` queued on main |
| **2. Review Studio** | `asset-workbench-review-studio` | ready · dependency-gated | Raster preview, playback, filmstrip, source/runtime comparison and diagnostics | `ASSET_WORKBENCH_REVIEW_STUDIO.md` queued on main; depends on Slice 1 |
| **3. Safe Pipeline Actions** | `asset-workbench-pipeline-actions` | planned | Plan/ingest UI, isolated mutation checkout, validation, commit/land, refresh | pending |
| **4. Actor Lens + Sequence Review** | `asset-workbench-actor-sequences` | planned | NPC/enemy/fauna ergonomics and disposable behavioral review sequences | pending |
| **5. Design Mode** | `asset-workbench-design-mode` | planned | Schema-aware family/state contract editing and reviewed contract publication | pending |
| **6. Creation + Source Intake** | `asset-workbench-creation-source-intake` | planned | New family/state creation, source staging, crisp conversion and authoring handoff | pending |
| **7. Platform Hardening + Domain Expansion** | `asset-workbench-platform-hardening` | planned | Proven shared UI extraction, large-family performance, broader domains, docs/QA | pending |

**Last reconciled main:** `24690f8`

---

## Slice 1 — Family Navigator Foundation

### Goal

Create the first useful read-only Asset Workbench surface over Asset Pipeline V2.

The user can launch a Textual UI, browse registered families, search/filter,
select states, and understand current production status without running several
CLI commands or reading JSON.

### Expected contents

- A dedicated Asset Workbench UI package under the Asset tooling domain.
- A thin read-model/service layer that composes existing:
  - `load_all_families()`;
  - `get_family_status()`;
  - requirement evaluation only where it adds direct status context.
- Immutable UI projections. Textual widgets must not become asset truth.
- Family navigation by family with visible kind and required completeness.
- State navigation/detail with:
  - required / recommended / optional role;
  - layer and action group;
  - frame canvas;
  - animation/static contract;
  - expected frames and FPS when declared;
  - direction policy and required directions;
  - authored and mirrored runtime directions;
  - inbox/source-pending state;
  - runtime path when present;
  - imported, bound, runtime-verified state.
- Search that filters accepted in-memory projections and does not rescan or
  mutate the repository on every keystroke.
- A clear read-only status/action bar.
- A stable launcher with explicit optional-UI dependency handling.
- `ambient_baby_opossum` as the first production acceptance family.
- Focused UI/service smoke coverage and validation ownership.

### Explicitly not in Slice 1

- raster image preview;
- playback or filmstrip;
- source/runtime diff;
- Aseprite editing;
- plan/ingest mutation;
- Git publication;
- contract editing;
- new-family creation;
- actor-specific sequence mode.

### Exit criteria

Slice 1 is complete when the UI truthfully reproduces Asset V2 family/state
status for fixture data and the real Baby Opossum family, survives missing
inboxes/runtime outputs without crashing, and performs no tracked or runtime
mutation.

---

## Slice 2 — Review Studio

### Goal

Make selected asset states visually reviewable at native pixel fidelity.

### Expected contents

- Static and animated runtime/source frame loading.
- Native RGBA rendering with integer zoom by default.
- Filmstrip and frame scrubbing for animated states.
- Play/pause, loop and contract FPS playback.
- Source/staged/runtime view selection when those representations exist.
- Side-by-side, overlay and pixel-diff comparison where meaningful.
- Alpha/bounds/frame-dimension diagnostics.
- Graceful handling of missing, unresolved, malformed, and LFS-pointer inputs.
- Extract only genuinely generic Operator preview primitives into a neutral
  shared Workbench UI package; keep Operator backend/service code specialized.
- Regression coverage proving Operator preview behavior is unchanged by any
  shared-widget extraction.

### Exit criteria

A static family and `ambient_baby_opossum` can be reviewed without leaving the
UI, animation playback uses family-contract timing, and no visual-review action
changes production files.

---

## Slice 3 — Safe Pipeline Actions

### Goal

Complete Asset Workbench V1 by making Asset V2 planning and ingestion available
through a safe reviewed UI flow.

### Expected contents

- Visual projection of the existing pure Asset V2 plan:
  source -> state -> inspected geometry -> backend -> target -> operation.
- Blocking conflicts/warnings surfaced before confirmation.
- Replace/mirror semantics delegated to existing Asset V2 authorities.
- Before the first tracked mutation capability ships, isolate interactive Asset
  Workbench mutation from the coordination checkout using the proven persistent
  art-worktree pattern or a cleaner equivalent supported by current main.
- One user confirmation for the normal completion flow:
  ingest -> required validation -> verified staging/commit -> safe landing to
  `origin/main` -> UI refresh.
- No separate normal commit/push/land ritual.
- Failed landing remains resumable without repeating a successful ingest.
- Allowlisting must derive from Asset V2 transaction/plan truth, not arbitrary
  `git add -A`.
- Existing Asset V2 rollback behavior remains authoritative.

### Exit criteria

A reviewable fixture family can be planned, ingested, validated, landed, and
reflected back in the UI with one reviewed user action while unrelated dirty
work and Codex worktrees remain isolated.

---

## Slice 4 — Actor Lens + Sequence Review

### Goal

Give actor-like families an NPC/enemy/fauna-friendly presentation without
creating separate NPC or Enemy Workbench applications.

### Expected contents

- Actor-aware grouping using existing semantic action groups/layers rather than
  a second contract schema.
- Coverage views for locomotion, reaction, combat, interaction, ambient,
  posture, fear/flee, friendship/utility, or whatever groups the family
  actually declares.
- Layer composition awareness for body/prop/FX families.
- Direction coverage and mirrored/authored provenance at a glance.
- Disposable saved review sequences under ignored Workbench state.
- Sequence playback across selected states to inspect transitions and behavior
  readability.
- Review sequences are never gameplay timing or behavior authority.
- Baby Opossum is the primary fauna acceptance family; at least one enemy/NPC
  family must prove the lens does not encode opossum-specific assumptions.

### Exit criteria

An actor family can be reviewed as a coherent behavior vocabulary while the
underlying family contract remains the only semantic asset authority.

---

## Slice 5 — Design Mode

### Goal

Allow safe schema-aware editing of Asset V2 family contracts from the Workbench.

### Expected contents

- Form-based editing for family identity, kind, runtime owner/domain, canvas,
  direction policy, mirroring, states, aliases and consumers supported by the
  live V2 schema.
- Contract changes validated through `parse_family()` before they can be
  published.
- Structured before/after diff.
- Existing-family edits only at first if creation adds excessive scope.
- Contract publication uses the mutation isolation and one-action landing
  behavior established in Slice 3.
- Requirement projection/doctor drift updated or surfaced when contract changes
  affect those authorities.

### Exit criteria

A valid contract edit can be reviewed, rejected without mutation, or safely
published; invalid schema changes fail before canonical replacement.

---

## Slice 6 — Creation + Source Intake

### Goal

Make missing assets and new families/states producible from the same control
plane without bypassing Asset Pipeline V2.

### Expected contents

- Guided `asset new`/new-family flow or equivalent service authority.
- New state/source intake with explicit proposed contract.
- Human-friendly source naming; canonical names remain generated outputs.
- `asset_drop/inbox/<family>/...` remains the unprocessed Asset V2 intake
  boundary.
- High-resolution/source-work handoff and exact frame/canvas/alpha inspection.
- Pixel-art conversion uses the repository `pixelart` command with **crisp
  method 1 as the default**; exceptional method overrides require an explicit
  active design reason.
- Optional Aseprite/source-work launch may be added if it can remain outside
  production authority and publish only through Asset V2.
- Existing-target races fail closed.

### Exit criteria

A genuinely absent family/state can be created from source intake through
reviewed Asset V2 publication without hand-authoring canonical runtime paths.

---

## Slice 7 — Platform Hardening + Domain Expansion

### Goal

Turn the proven V1+ capabilities into a durable general Workbench platform.

### Expected contents

- Extract shared UI primitives only where both Operator and Asset Workbench
  already prove the same contract.
- No shared backend that merges Operator and Asset V2 authorities.
- Large-family navigation/performance hardening.
- Recovery from malformed/missing source and catalog drift.
- Stable keyboard/focus behavior and accessibility/readability pass.
- Domain acceptance across:
  - actor/creature;
  - world prop/structure;
  - animated machinery;
  - FX;
  - vehicle/turret or another multi-layer family.
- Current docs, file index, validation ownership, and launcher conventions
  reconciled.
- Reassess whether a unified top-level `workbench` launcher is useful only
  after both applications are production-proven.

### Exit criteria

Asset Workbench is a stable general non-Operator visual authoring/review front
door, with shared UI code justified by real reuse rather than speculative
framework extraction.

---

## Deferred / Candidate Future Work

These are not committed slices until a real production ask requires them:

- AI Art Agent/autopilot for non-Operator families;
- prompt generation or image-generation orchestration;
- cross-machine synchronization of ignored Workbench state;
- live gameplay behavior editing;
- audio/Tiled editors under the same UI shell;
- replacing Asset Pipeline V2 CLI or family contracts.

## Architecture Guardrails

Across every slice:

- Asset Pipeline V2 remains the non-Operator technical authority.
- Operator remains specialized.
- Never scrape human CLI output when a Python authority already exposes data.
- Never create NPC/enemy/fauna-specific asset truth in UI state.
- UI projections are disposable and rebuildable.
- Search/filtering operates on accepted projections, not repeated filesystem
  mutation/discovery.
- No tracked mutation is added before its rollback and validation path exists.
- No generic shared package may import Operator gameplay/runtime authority.
- Production pixel conversion defaults to crisp method 1.
- Documentation changes describe current truth, not aspirational completion.

## Roadmap Change Log

| Date | Main | Change |
|---|---|---|
| 2026-09-29 | `a9be70d` | Initial roadmap created from current Asset V2 and Operator Workbench architecture; V1 defined as Slices 1–3. |
| 2026-09-29 | `972ea75` | Slice 1 promoted to ready; V2 task packet indexed for auto-dispatch with roadmap maintenance required during implementation. |
| 2026-09-29 | `24690f8` | Slice 2 Review Studio packet authored from stable Asset V2 review inputs and queued dependency-gated behind Slice 1; Slice 3 intentionally remains unauthored until landed UI/review seams are known. |
