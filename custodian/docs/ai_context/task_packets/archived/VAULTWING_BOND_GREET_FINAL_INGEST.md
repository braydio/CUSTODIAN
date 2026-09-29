# VAULTWING BOND GREET FINAL INGEST

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vaultwing-bond-greet-final-ingest`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `asset-catalog`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `193e8b28c2d80364ecde42bfdea8a293616c34e0`
- Goal: Finish Common Vaultwing Slice-B bonding body art by converging the accepted prior bonding-art checkpoint onto current main, ingesting the four newly generated `bond_greet` E/N/S/W strips through source_work → inbox → Asset Pipeline V2, and reducing the same-host Downloads import workflow to one fail-safe, repeatable staging path.
- Completion boundary: This workstream owns only Vaultwing bonding-art convergence, the four `bond_greet` source strips, the focused Vaultwing staging convenience/hardening needed to import them safely, Asset V2 publication, focused validation/first-bond evidence, and consequence-driven Vaultwing/asset-requirement documentation. It is done when current main contains the accepted prior bonding strips plus production-ready `bond_greet` runtime coverage in all four directions, the local Downloads path no longer requires hand-copying/source-map reconstruction, and all required focused gates are green. The older `vaultwing-bonding-art-final-ingest` branch remains a checkpoint source, not an independently resumed implementation target for this packet.
- Current measured state: On synchronized `main@193e8b28c`, `ambient_vaultwing_common` retains the 256×256, 4-direction, `auto_mirror: true` contract; `bond_greet` remains 8 frames/10 FPS/non-looping with required authored N/S/E. The accepted checkpoint was selectively reconciled without rejected inputs or stale packet prose. Corrected named Downloads sheets are RGBA 5792×724 canvases with eight 724×724 cells and clear transparent seams. Final Asset V2 status is 24/24 bonding runtime directions and 80/80 family runtime strips; `bond_greet` E/N/S/W are all authored.
- Evidence: `custodian/content/metadata/assets/families/ambient_vaultwing_common.asset.json` owns the live 256×256 / 8f / 10 FPS / N-S-E / auto-mirror contract; `custodian/docs/ASSET_LAYOUT_CONVENTION.md` and shared ingest docs state that explicitly authored directional counterparts override generated mirrors; `custodian/tools/assets/stage_vaultwing_bonding_source_work.py` is the existing task-specific normalizer/stager; `origin/agent/vaultwing-bonding-art-final-ingest@2eb4e719` is the recoverable prior checkpoint; the four generated source sheets are expected to be 5792×724 RGBA horizontal sheets; the batch profile validates 724×724 fixed cells and transparent seams before mutation.
- Task-specific authority: `custodian/content/metadata/assets/families/ambient_vaultwing_common.asset.json`; `custodian/tools/assets/stage_vaultwing_bonding_source_work.py` and its focused tests; current Asset Pipeline V2 CLI/help and shared directional ingest behavior; `design/02_features/ambient/VAULTWING_SYSTEM.md`; `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md`; `custodian/content/metadata/assets/required_assets.registry.json`.
- Work surface: Primary owner is the existing Vaultwing bonding source stager plus `ambient_vaultwing_common`. Expected writes are the stager and focused regression coverage, `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/`, `custodian/asset_drop/inbox/ambient_vaultwing_common/`, Asset V2-generated Vaultwing bonding runtime/catalog outputs, the requirement registry/generated view when fulfillment changes, and only active Vaultwing docs made false by the completed ingest. Read the old checkpoint branch for accepted artifacts/tooling but do not treat its stale packet/status prose as current authority.
- Change: Reconcile only the accepted prior checkpoint work needed to bring current main to the measured pre-greeting state; add one bounded same-host Downloads import profile/entry point to the existing Vaultwing stager; preflight all four files before any write; map named direction files `vw_east_facing.png`, `vw_north_facing.png`, `vw_south_facing.png`, and `vw_west_facing.png`; preserve raw accepted files as semantic source masters; normalize all four to exact 8×1 256×256 RGBA strips; stage E/N/S/W inbox assets; ingest through Asset Pipeline V2 so explicit W wins over generated W; emit concise structured provenance/geometry output and the exact next Asset V2 command rather than requiring manual source-map reconstruction; close the bonding-art requirement and stale active docs only after verified ingest.
- Preserve: Existing wild Vaultwing runtime art and behavior; existing accepted bonding art; same-instance bond mechanics/timing/allegiance/persistence/spawn behavior; family ID/runtime domain; `bond_greet` 8f/10 FPS/non-looping contract; `auto_mirror: true` and required N/S/E directions for other/future intake; Asset Pipeline V2 ownership of canonical runtime filenames; accepted immutable source masters; unrelated current-main work.
- Non-goals: No art generation/repainting; no generic Asset Pipeline redesign; no new family; no change to required directional policy merely because authored W exists; no production feed/bond SFX; no bait inventory work; no global save orchestration; no Slice-C commands/companion AI; no mounting; no broad historical packet cleanup; no automatic deletion of local Downloads inputs by default.
- Acceptance: The prior checkpoint's accepted bonding-art/tooling value is present on current-main lineage without resurrecting rejected/quarantine artifacts or stale docs. The four semantically named files in `~/Downloads` are direction/hash/alpha/frame-count preflighted before mutation. Canonical raw source masters exist as `bond_greet_{e,n,s,w}_source.png`. Normalized inbox strips exist as `bond_greet__{e,n,s,w}.png`, each exactly 2048×256 with eight 256×256 cells, true alpha, stable grounded registration, safe edge margins, correct orientation, and no matte/background. Asset V2 publishes all four `bond_greet` runtime directions; authored W is proven to win over an auto-mirrored E result. Required bonding coverage is measured at 24/24 runtime directions and 80/80 total Vaultwing runtime strips. The old rejected `inspect_bait_s` quarantine file is deleted; no rejected bonding image is present in `source_work`, inbox, runtime, or quarantine. Focused staging/asset/runtime/bond tests pass; first-bond evidence is generated at `reports/moment_forge/combat/vaultwing_first_bond/20260929T044349-0400`; requirements/docs reflect measured final truth.
- Validation: Run stager/import regressions and an all-four dry-run/preflight first. Inspect current `asset.py --help`, then run the narrow `ambient_vaultwing_common` plan/status/ingest/doctor path rather than inventing commands. Run `vaultwing_asset_contract`, `vaultwing_runtime`, and `vaultwing_bond` focused validation. Run `combat/vaultwing_first_bond` in evidence mode after publication; use one full capture only if required for final audiovisual inspection, never auto-approve a baseline. Run `run_validation.py --changed --json` once at closeout after focused checks are green. Regenerate root `REQUIRED_ASSETS.md` from the registry with the current `asset.py needs --write` path; never hand-edit it.
- Task overrides: The user corrected the semantic filenames after initially mixing north and south. The final named mapping was visually reviewed and preflighted; no main-branch art was used as an input.
- Deferred: Production Vaultwing feed/recognition SFX; bait inventory consumption; global save ownership; Slice-C companion commands/behavior; optional authored-W policy changes for other states; cleanup of the superseded old workstream branch after its unique useful history is demonstrably captured.

## Input Contract

The Downloads filenames carry semantic directions:

| Local input | Direction | Semantic source_work target | Normalized inbox target |
| --- | --- | --- | --- |
| `~/Downloads/vw_east_facing.png` | east / right-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_e_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__e.png` |
| `~/Downloads/vw_north_facing.png` | north / front-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_n_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__n.png` |
| `~/Downloads/vw_south_facing.png` | south / rear-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_s_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__s.png` |
| `~/Downloads/vw_west_facing.png` | west / left-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_w_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__w.png` |

Visual identity and all four direction names were checked before staging. The user corrected the north/south filenames; the final hashes are recorded in the source-work README.

The normalized contract for every direction is:

```text
state: bond_greet
frames: 8
fps: 10
loop: false
layout: 8x1 horizontal
frame: 256x256 RGBA
sheet: 2048x256
background: true alpha only
registration: stable grounded anchor
edge safety: no beak, crest, wing, foot, or tail clipping
```

Do not resize the whole generated canvas to 2048×256. Use the established per-frame alpha/registration normalizer so scale and anatomy are preserved.

## Checkpoint Convergence

The old workstream is already claimed by the existence of
`origin/agent/vaultwing-bonding-art-final-ingest`; do not try to claim or
resume it from this packet.

Use that branch only as a recoverable checkpoint. Reconcile its accepted
source/runtime/tooling changes onto this workstream against fresh current main.
Prefer the smallest conflict-safe method supported by the live diff: selective
cherry-pick, file-level recovery, or a reviewed merge. Do not wholesale import
stale packet/status prose. In particular:

- retain accepted `notice_bait`, corrected `inspect_bait`, `feed_accept`,
  and `watch_player` work that still validates;
- retain useful explicit source-map/stager regression improvements when they
  remain compatible with current main;
- preserve the user's later decision that rejected/wrong-facing bonding images
  are deletion-only, not durable quarantine;
- do not recreate obsolete rejected files merely to preserve old branch history;
- remeasure source/runtime coverage after reconciliation before claiming the
  prior 76/80 checkpoint count.

If current main already contains any equivalent accepted change, keep main and
avoid duplicate replacement history.

## Exact Workflow Hardening

Keep this improvement bounded to the existing Vaultwing bonding stager.

1. Add a named local-batch path, profile, or equivalent compact interface that
   accepts a Downloads directory and applies the four `bond_greet` semantic
   mappings without requiring four hand-written `--source-map` arguments.
   Reuse existing source-map internals rather than creating parallel staging
   logic.

2. Make preflight atomic: verify all four paths, unique/current hashes, readable
   RGBA, real transparency/no matte, eight frame groups, orientation sanity,
   normalization geometry, destination conflicts, and reference-runtime
   availability before writing any source_work or inbox file.

3. Rejection is fail-closed and non-destructive. A bad input remains in
   Downloads for correction and creates no canonical source, inbox, runtime, or
   quarantine artifact.

4. Preserve immutable accepted source masters. If an existing semantic source
   target has a different hash, stop with a precise conflict rather than silently
   overwriting it.

5. Add a structured `--json`/equivalent report from the existing stager instead
   of a second provenance database. Include local path, SHA-256, semantic
   direction, source dimensions, normalized dimensions/bounds/scale,
   source_work target, inbox target, and disposition. Existing Asset V2 job logs
   remain ingest provenance authority.

6. After successful staging, print the exact current Asset V2 next command(s)
   for `ambient_vaultwing_common`. Do not reimplement generic ingest inside the
   Vaultwing stager merely to obtain a one-command illusion.

7. Add focused regression coverage for the Downloads profile, all-or-nothing
   preflight, source conflict refusal, absent-file blocking, and E/N/S/W mapping.
   Use current shared-pipeline tests for generic authored-counterpart-over-mirror
   behavior unless a Vaultwing-specific regression is needed to prove W
   publication.

8. Optional local cleanup may be offered only behind an explicit flag and only
   after verified canonical preservation. Default behavior leaves
   `~/Downloads/vw*.png` untouched.

## Documentation Drift Closeout

Current main still contains Pass-1/Pass-2 Vaultwing art prose and the older
manual final-ingest packet. After validated convergence:

- update `VAULTWING_SYSTEM.md`, `VAULTWING_SLICE_B_BONDING.md`,
  `CURRENT_STATE.md`, `FILE_INDEX.md`, and the Vaultwing source-work README
  only where their present-tense claims are false;
- update `custodian/content/metadata/assets/required_assets.registry.json` from
  measured fulfillment and regenerate root `REQUIRED_ASSETS.md`;
- do not rewrite historical summaries merely for terminology;
- leave the old `vaultwing-bonding-art-final-ingest` branch recoverable until
  this convergence workstream has landed and its accepted history is proven
  captured; record branch-residue cleanup as deferred if it cannot be proven
  safely in-scope.

## Ownership And Timing

- Owner: Common Vaultwing bonding Asset V2 presentation
- Agent/session: Codex auto-dispatch
- Created: 2026-09-29
- Last updated: 2026-09-29

## Completion

- Result: complete; accepted checkpoint value is on the synchronized branch and four named greeting sheets are published through Asset V2.
- Measured: bonding actions 24/24 runtime directions; Common Vaultwing 80/80 runtime strips; registry requirement `vaultwing-bonding-animation-suite` is fulfilled and omitted from the generated root view.
- Authored-direction proof: `bond_greet` catalog directions are E/N/S/W with no mirror provenance; W publication did not change the family contract.
- Local named batch profile: `python3 custodian/tools/assets/stage_vaultwing_bonding_source_work.py --downloads-batch [DIRECTORY]`; defaults to `~/Downloads`, performs all-four preflight, and leaves Downloads inputs intact.
- The older `agent/vaultwing-bonding-art-final-ingest` branch remains recoverable until this workstream lands; cleanup is deferred to branch hygiene.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The packet's original numbered filenames and expected canvas were stale; the alpha-cluster path could not model the corrected eight-cell sheets, and two extra runtime attempts initially used mistaken source provenance.
- Root cause / contributing factors: Local filenames and sheet spacing changed after packet authoring; the existing stager had no named fixed-cell batch profile. Main and the accepted checkpoint also had diverged, requiring selective asset-only reconciliation.
- Prevention / pipeline improvement: The named profile now validates all four files and cell seams before writing, rejects source/destination conflicts, reports hashes and geometry as stable JSON, and has missing-file, conflict, mapping, and full-batch tests.
- Tooling / docs drift discovered: The packet's preflight and coverage statements were stale; LFS payloads were available in the local cache, so no network LFS fetch was needed. The changed-unit gate reported 7/8 passed; the unrelated `review_pairing_contract` failure is an Awakening packet that lists a future preferred smoke path as missing. Task-specific checks passed.
- Follow-up: fixed-in-scope; old checkpoint branch cleanup deferred until reachability is verified after landing. The unrelated Awakening packet-validation mismatch remains a separate follow-up.
- What worked: Asset V2 handled final publication and generated W mirrors for the other actions without family-contract changes.
