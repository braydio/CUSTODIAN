# Vaultwing bond greet final ingest

## Result

Completed `vaultwing-bond-greet-final-ingest` on the synchronized main base
`193e8b28c`. Selectively restored the accepted prior Vaultwing source masters,
archived inputs, and runtime art, then republished through Asset Pipeline V2.
No rejected art or stale checkpoint packet prose was imported.

The corrected local sources are `vw_east_facing.png`,
`vw_north_facing.png`, `vw_south_facing.png`, and `vw_west_facing.png`. North
and south filenames were swapped at the user's direction. All four are 5792×724
RGBA sheets with eight 724×724 cells and clear transparent seams. Their raw
bytes remain in Downloads and in canonical source_work masters. Normalized
inbox strips are 2048×256 RGBA; the existing frame normalizer supplies
per-frame scale and grounded registration.

Asset V2 ingested 12 sources into 15 runtime outputs, creating four greeting
directions, restoring accepted checkpoint coverage, and mirroring W for the
other three E-authored states in the ingest batch. The final catalog reports:

- Six bonding states: 24/24 runtime directions.
- Full Common Vaultwing family: 80/80 runtime strips.
- `bond_greet`: authored E/N/S/W; W has `authored` catalog provenance.
- `vaultwing-bonding-animation-suite`: fulfilled in the registry and omitted
  from generated `REQUIRED_ASSETS.md`.

Removed the old rejected `inspect_bait_s_vw8` quarantine artifact. The stager
now leaves rejected inputs at their user-provided local path and creates no
source_work, inbox, runtime, or quarantine copy for them. Its new named
`--downloads-batch [DIRECTORY]` profile preflights all four sources,
transparent cell seams, frame geometry, references, unique hashes, and
source/inbox conflicts before writing. It emits deterministic JSON provenance
and the next Asset V2 commands.

Updated the active Vaultwing design, current-state and index docs, source-work
README, requirement registry/view, and archived the completed task packet.
First-bond evidence passed at
`reports/moment_forge/combat/vaultwing_first_bond/20260929T044349-0400`.
The evidence contact sheet was reviewed; no baseline was approved or replaced.

## Validation

- `python3 custodian/tools/assets/test_stage_vaultwing_bonding_source_work.py` — 8 passed.
- `python3 custodian/tools/validation/vaultwing_asset_contract_smoke.py` — passed, 80 strips.
- `python3 custodian/tools/validation/run_validation.py --test vaultwing_runtime --json` — passed.
- `python3 custodian/tools/validation/run_validation.py --test vaultwing_bond --json` — passed.
- `python3 custodian/tools/iteration/run_moment.py combat/vaultwing_first_bond --capture-mode evidence` — passed.
- `python3 custodian/tools/assets/asset.py needs --check` — passed.
- `python3 custodian/tools/assets/asset.py doctor` — healthy after Godot import.
- `git diff --check` — passed.
- `python3 custodian/tools/validation/run_validation.py --changed --max-tier unit --json` — 7/8 passed; unrelated `review_pairing_contract` failed because the active Awakening packet lists a future preferred smoke path that is not present. All task-specific validations passed. A focused `--test vaultwing_asset_contract --json` report passed and is provided to workstream finish.

The initial doctor run warned that four new runtime files lacked Godot import
sidecars. A Godot editor import generated them, after which doctor passed. LFS
payloads were already in the local cache; no LFS fetch/pull was run. The old
checkpoint branch remains recoverable until reachability is established after
landing.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The packet's numbered filenames and expected sheet geometry were stale. The old alpha-cluster path could not model the corrected eight-cell sheets. Earlier local payload provenance was also mistaken once before it was corrected.
- Root cause / contributing factors: User filenames and spacing changed after packet authoring; the existing stager lacked a named fixed-cell profile; the accepted art checkpoint had diverged from current main.
- Prevention / pipeline improvement: Added a named batch profile with full preflight, destination conflict checks, structured geometry/hash JSON, rejection-without-quarantine behavior, and focused tests.
- Tooling / docs drift discovered: Active Vaultwing docs, registry notes, generated projection, and task packet all described stale partial coverage; the local cache held the required reference LFS objects. The changed-unit gate also found an unrelated Awakening packet's future validation path incorrectly treated as required by `review_pairing_contract`.
- Follow-up: fixed-in-scope; checkpoint branch cleanup deferred to branch hygiene; unrelated Awakening packet validation mismatch is a separate follow-up.
- What worked: Asset V2 retained ownership of normalization outputs, canonical paths, mirroring, and provenance.
