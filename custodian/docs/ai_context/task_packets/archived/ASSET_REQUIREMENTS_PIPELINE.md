# ASSET REQUIREMENTS PIPELINE

- Workstream: `asset-requirements-pipeline`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `asset-requirements`
- Goal: Harden the landed production-requirements control plane and convert the obvious already-registered Asset V2 requirements from manual status to live family/catalog-derived status.
- Current measured state: The registry has 115 durable requirements; 13 now use V2-derived fulfillment. At closeout, 113 are active and 2 are fulfilled. Ten additional requirements derive status from existing V2 family contracts/catalog evidence.
- Task-specific authority: `design/04_architecture/ASSET_PIPELINE_V2.md`, `custodian/content/metadata/assets/required_assets.registry.json`, `custodian/tools/assets/{asset_requirements.py,asset_status.py,asset.py}`, and referenced live family contracts.
- Change: Fix lifecycle/validation; add `required_states` family-scope targets, request-local status caching, source-pending-aware next actions, section-note projection, and compact agent guidance; remove reverse migration code; correct three misrouted effect rows; map ten existing requirements to complete live V2 closure conditions.
- Preserve: Family contracts remain technical art authority; catalog/runtime evidence remains production-state authority; V2 completion stays derived-only; ingest/naming/transaction behavior stays unchanged; mixed requirements stay manual when a family contract does not fully express closure.
- Non-goals: No `asset next`, priority model, requirement UI, audio/Tiled ingest, Operator genericization, automatic art generation, watch daemon, consumer rewrites, new production art, or new V2 families solely to increase mapping count.
- Acceptance: Non-V2 requirements can close without deletion; malformed records fail cleanly; family-scope requirements derive from live contracts; next actions reflect staged/missing evidence; lost section guidance is restored; reverse migration is removed; three route errors are corrected; ten additional requirements derive from V2 truth; generated Markdown remains deterministic; focused tests and changed-unit validation pass.
- Task overrides: `none`
- Deferred: Requirement CRUD/prioritization, `asset next`, audio/Tiled adapters, Operator requirement derivation, runtime-verification evidence, broader data-only V2 mapping.

## Ownership And Timing

- Owner: Asset Pipeline V2 production-demand control plane
- Agent/session: Codex auto-dispatch
- Created: 2026-09-28
- Last updated: 2026-09-28

## Work Surface

Primary: `asset_requirements.py`, `asset.py`, `asset_doctor.py`, `required_assets.registry.json`, root `REQUIRED_ASSETS.md`, `asset_requirements_smoke.py`, and `custodian/AGENTS.md`.

Active drift targets only where stale: `LAST_ROUTEKEEPER_EVENT.md`, `VAULTWING_SYSTEM.md`, `CRITICAL_OPEN_OPTIONAL_VFX.md`. Do not edit `CURRENT_STATE.md` or `FILE_INDEX.md` unless implementation makes their current high-level requirement-authority wording false.

## Implementation Contract

### Lifecycle and validation

1. Declared routes `manual|audio|tiled|operator|review` may use `needed|partial|bound|deferred|fulfilled`. `fulfilled` stays in the registry, is omitted from active Markdown, and direct `asset needs <id>` reports complete/no action. V2 remains derived-only.
2. Validate `id`, `section`, `title`, `target`, `purpose`, `notes`, `fulfillment`: kebab-case non-empty ID; non-empty section/title; string target/purpose/notes; duplicate IDs and duplicate normalized V2 targets inside one requirement fail. Malformed records return clean CLI/doctor errors, never tracebacks.
3. If structural validation fails, `asset doctor` stops requirement projection rather than emitting cascading errors.
4. Reject ambiguous CLI combinations instead of silently ignoring arguments: ID + `--write/--check`, and `--write/--check` + `--json`.

### V2 target model and evaluation

Keep explicit targets:

```json
{"family":"ambient_baby_opossum","state":"waddle","directions":["s"]}
```

Add:

```json
{"family":"awakening_creche_environment","scope":"required_states"}
```

Rules: exactly one of `state`/`scope`; V1 scope only `required_states`; expand from live `state.required == true`; `directions` only with explicit state; reject scope on zero-required-state families; expose `satisfied`, `satisfied_states`, `missing_states`, `source_pending`; do not duplicate frame/FPS/layout/naming/state-list contracts in the registry.

Memoize `get_family_status()` once per family per evaluation. No persistent cache.

### Next action

Do not use `needed -> request` / `partial -> plan` as truth.

- missing target + no relevant staged source -> `asset request <family>`
- relevant staged source -> `asset plan <family>`
- staged source plus other unstaged gaps may show both
- fulfilled -> no production action
- `asset status <family>` may remain as inspection support

Explicit state targets use that state's `source_pending`; `required_states` is source-pending when any currently missing required state has source pending.

### Section notes / agent guidance / migration cleanup

Add optional top-level `section_notes` mapping. Render each note after its section heading and before its table; keys must name existing registry sections and values must be strings.

Recover useful pre-migration prose from `9273e305:REQUIRED_ASSETS.md` for:

- Awakening / The First Return (sections 01-10)
- Common Vaultwing Bonding Presentation
- Baby Opossum Ambient Creature
- Combat Resource Feedback (Milestone A)
- Persistent Compound Authored Rooms

Preserve production meaning while keeping the registry, not Markdown, as editable authority.

Add a compact `Production Asset Requirements` rule to `custodian/AGENTS.md`:

```text
Discovery -> update required_assets.registry.json -> choose real route -> regenerate/check -> report added need.
Fulfillment -> V2 completion is derived; non-V2 may become fulfilled only after real fulfillment; retain history -> regenerate/check.
Never hand-edit generated REQUIRED_ASSETS.md.
```

Remove completed Markdown -> registry production code from `asset_requirements.py`, including migration-only `migrate_markdown`, `_split_markdown_row`, `semantic_id`, and their smoke fixture/imports. Git history and the existing closing summary preserve migration evidence.

### Route correction

Change these `operator` requirements to `manual` without creating V2 families:

- `posture-break-flash-editable-source`
- `critical-window-expiry-editable-source`
- `operator-parry-miss-world-vfx`

## V2 Coverage Expansion

Promote only these ten requirements; do not guess additional mappings.

| Requirement | V2 closure |
|---|---|
| `p0-p1-zone-plates-nine-awakening-environment-families` | `required_states` for nine environment families |
| `p1-awakening-late-service-relay-lamp` | `awakening_late_service_relay_lamp` required states |
| `p1-zone-fixture-families` | `required_states` for eight fixture families |
| `p1-awakening-authority-inlay` | `awakening_authority_inlay` required states |
| `p1-awakening-ruin-decal` | `awakening_ruin_decal` required states |
| `p1-ambient-awakening-fx-families` | required states of dust motes, falling ash, gate wind dust |
| `baby-opossum-ambient-threat-re-export` | `look/s`, `hiss/s`, `startle/s` |
| `baby-opossum-reaction-friendship-re-export` | `disapprove/s`, `eat/s`, `friend_happy/s` |
| `baby-opossum-hide-exit-re-export-body-barrel` | `hide_exit/s`, `hide_exit__barrel_prop/s` |
| `baby-opossum-barrel-prop-hide-layer-consistent-framing` | barrel `hide_enter/hold/peek/exit`, all south |

Nine environment families:

```text
awakening_creche_environment
awakening_ambulatory_environment
awakening_attestation_environment
awakening_locker_reliquary_environment
awakening_dust_lung_environment
awakening_undergate_environment
awakening_gate_plaza_environment
awakening_custodian_approach_environment
awakening_late_service_environment
```

Eight fixture families:

```text
awakening_creche_fixtures
awakening_ambulatory_fixtures
awakening_attestation_fixtures
awakening_reliquary_fixtures
awakening_dust_lung_structures
awakening_undergate_machinery
awakening_approach_fixtures
awakening_late_service_fixtures
```

Ambient FX: `awakening_dust_motes`, `awakening_falling_ash`, `awakening_gate_wind_dust`.

Reviewed-main evidence, not constants: all nine environment families currently have production underlay/foreground outputs, so zone plates should derive `fulfilled`; Crèche required fixtures are present while Ambulatory lacks `service_basin_b` and later fixture families remain incomplete, so fixture aggregate should derive `partial`. Derive all statuses live.

Target overlap across different requirements is intentional. Duplicate targets are invalid only inside one requirement.

Keep these manual because current contracts do not express their full human closure condition:

```text
forlorn-ritualant-npc-runtime-sprites
enemy-grunt-sabotage-animation-suite
enemy-grunt-loot-carry-escape-animation-suite
```

Apply the same rule to other tempting rows: promote only when the V2 contract fully represents closure.

## Documentation Drift

Correct active wording in the three drift targets above that still treats root `REQUIRED_ASSETS.md` as editable/canonical.

```text
custodian/content/metadata/assets/required_assets.registry.json = editable requirement authority
REQUIRED_ASSETS.md = generated human view
```

Do not churn archived/completed packets solely to rewrite historical wording.

## Focused Validation

Extend `asset_requirements_smoke.py` to prove:

1. non-V2 `fulfilled` is valid, retained, filtered from active Markdown, and direct inspection gives no action;
2. malformed/missing fields, invalid IDs, and duplicate targets fail cleanly;
3. explicit state/direction behavior remains correct;
4. `required_states` expands dynamically and reports satisfied/missing states;
5. zero-required-state scope and directions+scope fail;
6. section notes validate/render deterministically;
7. partial/no-source recommends `request`; relevant staged source exposes `plan`;
8. ambiguous CLI modes fail;
9. three generic combat-effect rows are not Operator-routed;
10. existing connector/Vaultwing/Opossum fixtures remain green.

Remove the permanent legacy-Markdown migration test.

Implementation loop:

```bash
python3 custodian/tools/validation/asset_requirements_smoke.py
python3 custodian/tools/validation/asset_pipeline_cli_ux_smoke.py
python3 custodian/tools/validation/asset_pipeline_v2_smoke.py
python3 custodian/tools/assets/asset.py needs --check
python3 custodian/tools/assets/asset.py doctor
git diff --check
```

Closeout once:

```bash
python3 custodian/tools/validation/run_validation.py --changed --max-tier unit --json
```

No broad local Godot/actor/integration sweep. Let repository CI perform broader changed-file checks after landing. Moment Forge is not applicable.

## Completion

Before `workstream.py finish`:

- do not delete fulfilled requirement records;
- regenerate root `REQUIRED_ASSETS.md` and pass `asset needs --check`;
- record registry/active/fulfilled counts and derived statuses of the ten new mappings;
- mark this packet `complete`, archive it as `task_packets/archived/ASSET_REQUIREMENTS_PIPELINE.md`, and remove its active README entry;
- refresh `ASSET_REQUIREMENTS_PIPELINE_CLAUDE_SUMMARY.md` with measured results;
- provide green focused validation JSON.

Completion report: files changed; registry/active/fulfilled counts; mappings added; ten derived statuses; tests/results; remaining control-plane blocker or deliberately deferred adapter.

## Handof

- Next action: Continue with the next eligible packet through `dispatch.py` after this packet lands.
- Best starting files: `asset_requirements.py`, `required_assets.registry.json`, `asset_status.py`, `asset_requirements_smoke.py`.
- Blockers or open questions: None for this workstream. Audio, Tiled, Operator, and review adapters remain deliberately non-derived unless their existing workflows update declared registry status; no new art or family design was added.

## Completion Notes

- Registry: 115 total requirements; 113 active and 2 fulfilled. Fulfillment routes: 13 Asset V2, 56 manual, 17 Operator, 18 Tiled, 8 audio, and 3 review.
- Added ten family-scope/state-target mappings. Live derived status: zone plates `fulfilled`; late-service relay lamp `needed`; zone fixtures `partial`; authority inlay `needed`; ruin decal `needed`; ambient Awakening FX `needed`; Opossum threat re-export `needed`; Opossum reaction/friendship re-export `needed`; hide-exit body/barrel re-export `needed`; barrel hide-layer framing `needed`.
- Non-V2 `fulfilled` is now valid and retained but filtered from generated Markdown. Asset V2 status supports `required_states`, evaluates each family once per registry evaluation, and exposes satisfied/missing/source-pending evidence.
- CLI next actions use staged family source evidence, fulfilled inspection reports no production action, invalid mode combinations fail, and doctor stops requirement projection after structural validation errors.
- Restored the five migrated section notes, corrected the three combat-effect fulfillment routes, removed one-time Markdown migration code and its permanent test, updated active asset-authority docs, and regenerated root `REQUIRED_ASSETS.md`.
- Validation: requirement smoke, Asset Pipeline CLI UX/V2/V2.1, plan/status/ingest/replacement/transaction/backend, Vaultwing and Opossum contract smokes, `asset needs --check`, `asset doctor`, Python compile, and changed-unit validation all passed. Doctor reports one existing warning: unregistered `operator` inbox with 12 PNGs; there are no requirement errors.
- The first requirements-smoke iteration exposed a temporary fixture omission (the written registry lacked the completed and source-action rows); the fixture was corrected. An extra attempted path `asset_pipeline_hardening_smoke.py` does not exist; the packet's named focused tests and actual asset pipeline smokes were run instead.
- Moment Forge: not run — production-demand tooling and documentation only; no runtime or presentation behavior changed.
