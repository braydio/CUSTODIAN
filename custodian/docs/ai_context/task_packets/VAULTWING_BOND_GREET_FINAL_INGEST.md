# VAULTWING BOND GREET FINAL INGEST

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vaultwing-bond-greet-final-ingest`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `asset-catalog`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `a9be70ded`
- Goal: Finish Common Vaultwing Slice-B bonding body art by converging the accepted prior bonding-art checkpoint onto current main, ingesting the four newly generated `bond_greet` E/N/S/W strips through source_work → inbox → Asset Pipeline V2, and reducing the same-host Downloads import workflow to one fail-safe, repeatable staging path.
- Completion boundary: This workstream owns only Vaultwing bonding-art convergence, the four `bond_greet` source strips, the focused Vaultwing staging convenience/hardening needed to import them safely, Asset V2 publication, focused validation/first-bond evidence, and consequence-driven Vaultwing/asset-requirement documentation. It is done when current main contains the accepted prior bonding strips plus production-ready `bond_greet` runtime coverage in all four directions, the local Downloads path no longer requires hand-copying/source-map reconstruction, and all required focused gates are green. The older `vaultwing-bonding-art-final-ingest` branch remains a checkpoint source, not an independently resumed implementation target for this packet.
- Current measured state: On reviewed `main@a9be70ded`, `ambient_vaultwing_common` is a 256×256, 4-dir, `auto_mirror: true` family; `bond_greet` is an 8-frame, 10 FPS, non-looping bonding action with required authored N/S/E directions. Shared sprite ingest permits an explicitly authored counterpart to win over auto-mirroring, so an authored W may be ingested without changing the family requirement contract. Main still carries the older manual Vaultwing final-ingest packet and its pre-convergence state. Remote checkpoint `origin/agent/vaultwing-bonding-art-final-ingest@2eb4e719` contains unlanded accepted bonding-art/tooling progress previously measured at 15/18 required E/S/N bonding masters, 20/24 bonding runtime strips, and 76/80 total Vaultwing runtime strips; remeasure after reconciliation rather than trusting stale docs. The user is saving four new same-host local inputs as `~/Downloads/vw1.png` through `vw4.png`.
- Evidence: `custodian/content/metadata/assets/families/ambient_vaultwing_common.asset.json` owns the live 256×256 / 8f / 10 FPS / N-S-E / auto-mirror contract; `custodian/docs/ASSET_LAYOUT_CONVENTION.md` and shared ingest docs state that explicitly authored directional counterparts override generated mirrors; `custodian/tools/assets/stage_vaultwing_bonding_source_work.py` is the existing task-specific normalizer/stager; `origin/agent/vaultwing-bonding-art-final-ingest@2eb4e719` is the recoverable prior checkpoint; the four generated source sheets are expected to be approximately 2172×724 RGBA horizontal strips and must be verified from the actual local files before mutation.
- Task-specific authority: `custodian/content/metadata/assets/families/ambient_vaultwing_common.asset.json`; `custodian/tools/assets/stage_vaultwing_bonding_source_work.py` and its focused tests; current Asset Pipeline V2 CLI/help and shared directional ingest behavior; `design/02_features/ambient/VAULTWING_SYSTEM.md`; `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md`; `custodian/content/metadata/assets/required_assets.registry.json`.
- Work surface: Primary owner is the existing Vaultwing bonding source stager plus `ambient_vaultwing_common`. Expected writes are the stager and focused regression coverage, `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/`, `custodian/asset_drop/inbox/ambient_vaultwing_common/`, Asset V2-generated Vaultwing bonding runtime/catalog outputs, the requirement registry/generated view when fulfillment changes, and only active Vaultwing docs made false by the completed ingest. Read the old checkpoint branch for accepted artifacts/tooling but do not treat its stale packet/status prose as current authority.
- Change: Reconcile only the accepted prior checkpoint work needed to bring current main to the measured pre-greeting state; add one bounded same-host Downloads import profile/entry point to the existing Vaultwing stager; preflight all four files before any write; map `vw1=e`, `vw2=n`, `vw3=s`, `vw4=w`; preserve raw accepted files as semantic source masters; normalize all four to exact 8×1 256×256 RGBA strips; stage E/N/S/W inbox assets; ingest through Asset Pipeline V2 so explicit W wins over generated W; emit concise structured provenance/geometry output and the exact next Asset V2 command rather than requiring manual source-map reconstruction; close the bonding-art requirement and stale active docs only after verified ingest.
- Preserve: Existing wild Vaultwing runtime art and behavior; existing accepted bonding art; same-instance bond mechanics/timing/allegiance/persistence/spawn behavior; family ID/runtime domain; `bond_greet` 8f/10 FPS/non-looping contract; `auto_mirror: true` and required N/S/E directions for other/future intake; Asset Pipeline V2 ownership of canonical runtime filenames; accepted immutable source masters; unrelated current-main work.
- Non-goals: No art generation/repainting; no generic Asset Pipeline redesign; no new family; no change to required directional policy merely because authored W exists; no production feed/bond SFX; no bait inventory work; no global save orchestration; no Slice-C commands/companion AI; no mounting; no broad historical packet cleanup; no automatic deletion of local Downloads inputs by default.
- Acceptance: The prior checkpoint's accepted bonding-art/tooling value is present on current-main lineage without resurrecting rejected/quarantine artifacts or stale docs. `~/Downloads/vw1.png`–`vw4.png` are orientation/hash/alpha/frame-count preflighted as E/N/S/W before mutation. Canonical raw source masters exist as `bond_greet_{e,n,s,w}_source.png`. Normalized inbox strips exist as `bond_greet__{e,n,s,w}.png`, each exactly 2048×256 with eight 256×256 cells, true alpha, stable grounded registration, safe edge margins, correct orientation, and no matte/background. Asset V2 publishes all four `bond_greet` runtime directions; authored W is proven to win over an auto-mirrored E result. Required bonding coverage is remeasured and reaches 24/24 runtime directions and 80/80 total Vaultwing runtime strips if the accepted checkpoint reconciles as expected. No rejected Vaultwing bonding image is added to `source_work`, inbox, runtime, or a new quarantine. Focused staging/asset/runtime/bond tests pass; first-bond evidence is generated; requirements/docs reflect measured final truth.
- Validation: Run stager/import regressions and an all-four dry-run/preflight first. Inspect current `asset.py --help`, then run the narrow `ambient_vaultwing_common` plan/status/ingest/doctor path rather than inventing commands. Run `vaultwing_asset_contract`, `vaultwing_runtime`, and `vaultwing_bond` focused validation. Run `combat/vaultwing_first_bond` in evidence mode after publication; use one full capture only if required for final audiovisual inspection, never auto-approve a baseline. Run `run_validation.py --changed --json` once at closeout after focused checks are green. Regenerate root `REQUIRED_ASSETS.md` from the registry with the current `asset.py needs --write` path; never hand-edit it.
- Task overrides: `TASK OVERRIDE: this auto-dispatch packet intentionally depends on four same-host local files under ~/Downloads. At task start, expand the actual user's home directory and verify vw1.png through vw4.png. If any are absent, unreadable, duplicated unexpectedly, or fail orientation/alpha/frame preflight, set this packet blocked on the task branch, checkpoint cleanly, and do not synthesize/substitute art.`
- Deferred: Production Vaultwing feed/recognition SFX; bait inventory consumption; global save ownership; Slice-C companion commands/behavior; optional authored-W policy changes for other states; cleanup of the superseded old workstream branch after its unique useful history is demonstrably captured.

## Input Contract

The four Downloads filenames are batch order, not semantic names:

| Local input | Direction | Semantic source_work target | Normalized inbox target |
| --- | --- | --- | --- |
| `~/Downloads/vw1.png` | east / right-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_e_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__e.png` |
| `~/Downloads/vw2.png` | north / front-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_n_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__n.png` |
| `~/Downloads/vw3.png` | south / rear-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_s_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__s.png` |
| `~/Downloads/vw4.png` | west / left-facing | `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/bond_greet_w_source.png` | `custodian/asset_drop/inbox/ambient_vaultwing_common/bond_greet__w.png` |

Preflight visual/orientation identity before using the filename mapping. If the files were saved in a different order, stop and report the mismatch rather than guessing.

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

## Handoff

- Next action: Claim this packet, preflight `~/Downloads/vw1.png` through `vw4.png`, then inspect the old checkpoint diff before making writes.
- Best starting files: `ambient_vaultwing_common.asset.json`, `stage_vaultwing_bonding_source_work.py`, its focused tests, and `origin/agent/vaultwing-bonding-art-final-ingest`.
- Blockers or open questions: None if all four Downloads inputs are present and valid. Missing/invalid local inputs are a fail-closed task blocker, not permission to regenerate.
