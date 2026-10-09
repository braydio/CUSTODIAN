# Task Packet Queue Reconciliation V1 Ledger

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

## Reconciliation boundary

- Original claim-time live counts were recorded as 236 raw active Markdown files, 23 ready/auto, 6 claimed, 96 dependency/lock blocked, 1 manual ready, 16 parked draft and 94 invalid/recovery. The exact origin SHA and remote-ref snapshot for that dispatcher invocation were not recorded; therefore these are retained as an **unbound historical observation**, not a tree-bound before count. The prior historical `d6028a6d` counts are likewise not current truth.
- Reproducible tree inventory (run `git ls-tree -r --name-only <tree> custodian/docs/ai_context/task_packets/`, count exact top-level `.md` files excluding `README.md`, then parse active and archived `Workstream:` identities with `task_packet_contract.parse_packet`):

| Exact tree | Raw active files | Active identities | Archived identities | Active ∪ archived identities |
| --- | ---: | ---: | ---: | ---: |
| `52135e3401a9efd49b011e676171373c3bef37b2` (claim checkout baseline) | 234 | 146 | 191 | 337 |
| `b5ce4e52bbd352b4d88fb61a4ac73d57098915ae` (upstream pre-archive snapshot) | 239 | 151 | 192 | 343 |
| `7f43556150ca170f0d84f29771d5feb34dbabd18` (corrected candidate and landed implementation) | 213 | 149 | 194 | 343 |
| `105c2541fd1c4dd7bf3dab688b64c3da76a4310b` (reviewed main) | 214 | 150 | 195 | 345 |
| `37b84831079c2205197e4f86ddf0b71cefd0a6f6` (current correction audit main) | 219 | 156 | 211 | 367 |

The table and baseline-to-landed identity delta can be regenerated with this read-only script from the repository root:

```bash
python3 - <<'PY'
import subprocess
import sys
sys.path.insert(0, "custodian/tools/agent")
from task_packet_contract import parse_packet

refs = [
    "52135e3401a9efd49b011e676171373c3bef37b2",
    "b5ce4e52bbd352b4d88fb61a4ac73d57098915ae",
    "7f43556150ca170f0d84f29771d5feb34dbabd18",
    "105c2541fd1c4dd7bf3dab688b64c3da76a4310b",
]
def git(*args):
    return subprocess.run(["git", *args], text=True, capture_output=True, check=True).stdout.strip()
def inventory(ref):
    paths = git("ls-tree", "-r", "--name-only", ref, "--", "custodian/docs/ai_context/task_packets").splitlines()
    root = "custodian/docs/ai_context/task_packets/"
    active = [p for p in paths if p.startswith(root) and p.endswith(".md") and "/" not in p[len(root):] and p != root + "README.md"]
    archived = [p for p in paths if p.startswith(root + "archived/") and p.endswith(".md")]
    ids = {}
    for path in active + archived:
        workstream = parse_packet(path, git("show", f"{ref}:{path}")).workstream
        if workstream:
            ids.setdefault(workstream, set()).add("active" if path in active else "archived")
    active_ids = {identity for identity, locations in ids.items() if "active" in locations}
    archived_ids = {identity for identity, locations in ids.items() if "archived" in locations}
    return {"ref": ref, "raw_active": len(active), "active_ids": len(active_ids),
            "archived_ids": len(archived_ids), "all_ids": set(ids)}
snapshots = [inventory(ref) for ref in refs]
for row in snapshots:
    print(row["ref"], row["raw_active"], row["active_ids"], row["archived_ids"], len(row["all_ids"]))
baseline, landed = snapshots[0], snapshots[2]
print("baseline_to_landed_added", *sorted(landed["all_ids"] - baseline["all_ids"]))
removed = sorted(baseline["all_ids"] - landed["all_ids"])
print("baseline_to_landed_removed", *(removed or ["none"]))
PY
```

- The old “final live audit” counts of 239 raw / 139 managed / 23 claimable were from `b5ce4e52`, before the 24 safe archive moves; they are not the repaired result. The landed result is the exact `7f435561` tree: 213 raw active files and 343 unique active-plus-archived workstream identities. `b5ce4e52` and `7f435561` have the same 343-identity set. Compared with baseline `52135e34`, the landed tree adds exactly `awakening-04-05-registered-composition-fade-repair-v1`, `review-awakening-04-05-registered-composition-fade-repair-v1`, `loot-toast-hud-clearance-v1`, `review-loot-toast-hud-clearance-v1`, `procgen-archive-resolve-playtest-polish-v1`, and `review-procgen-archive-resolve-playtest-polish-v1`; it removes **zero** baseline identities. The 24 archive moves preserve bytes, and the 22 ambiguous legacy records remain active and unchanged.
- The `105c2541` review tree contains two further upstream identities (`living-world-entity-reification-handoff` and its paired review), with zero identity removals from baseline. These changes are outside the original implementation result and are recorded separately from the `7f435561` acceptance snapshot.
- Current live dispatcher snapshot was taken from the correction worktree against fetched `origin/main@1aaeba23d3ad1a758d53e1224045951ff543e227`, using the corrected candidate `dispatch.py audit --json`: raw=219, managed=156, claimable-auto=24; classes are claimed=6, dependency/lock-blocked=105, invalid/recovery=64, parked-draft=20, ready-auto=24; interrupted claims=0 and claim-only orphan claims=0. Its exact eligible IDs were:

  `asset-workbench-review-studio-r1`, `baby-opossum-runtime-hardening-r1`, `hub-awakening-context-handoff`, `kenney-pattern-lines-source-library`, `loot-toast-hud-clearance-v1`, `operator-2-5d-workbench-polish-automation`, `operator-unarmed-defense-source-promotion`, `procgen-alpine-cliff-presentation-v1`, `procgen-archive-resolve-playtest-polish-v1`, `procgen-authored-claim-registry-extraction`, `reciprocal-continuity-canon-drift-guard`, `review-bidirectional-dropbox-handoff`, `review-contract-world-placement-foundation-r1`, `review-isometric-2-5d-presentation-foundation`, `review-lords-of-pain-test-gallery`, `review-operator-art-registration-profile-review-corrections-1-r1`, `review-operator-workbench-fx-layer-adoption-review-corrections-1`, `review-startup-world-entry-spine-v1-r1`, `twin-solaria-crown-incident-forensics`, `twin-solaria-development-preview-consistency-r1`, `twin-solaria-route-vista-samples-v1`, `ultra-codex-packet-worker`, `vaultwing-bonding-local-history-recovery`, `visual-review-question-answer-capture-v1`.

- At this same ref snapshot, `remote_dispatch_claims` was empty. The correction's canonical `origin/agent/task-packet-queue-reconciliation-v1-review-corrections-1` branch was `c2dac570fc0d002144b292e199837ad5b8ac6c5d`, six commits behind main with no unique commits, attached to this active dirty worktree; no temporary `dispatch-claims/task-packet-queue-reconciliation-v1-review-corrections-1` ref existed. These are current refs, not reconstructed historical claim counts. Re-run the command pair below to reproduce a later live snapshot:

```bash
git rev-parse origin/main
python3 custodian/tools/agent/dispatch.py audit --json
```

- The managed README index is generated output, not an independent count authority. At each measured tree, raw files, parsed identity sets and any live claim/ref audit are kept distinct so upstream arrivals, packet archival, and current ownership cannot be conflated.

## Invalid and newly surfaced packet repairs

- `vehicle-diagnosis-knowledge-v1`, `review-vehicle-diagnosis-knowledge-v1`, `vehicle-part-fabrication-recovery-v1`, and `review-vehicle-part-fabrication-recovery-v1`: removed unsupported `persistence` from `Review modes`; retained persistence/save-load requirements in acceptance and review prose.
- `sundered-keep-overlook-alternate-vertical-slice`: corrected the header to `Visual review: required`, retaining reviewer instructions/questions in the body.
- Additional ready V2 metadata drift discovered during active queue checks: two Procgen Alpine packets now use the required `Reviewed main` field (same recorded SHA); Vehicle Field Scout correction now uses `Current measured state` (same recorded evidence).
- Newly published latest-main packets repaired mechanically: Awakening fade packet validation script points at `custodian/tools/validation/run_validation.py`; Loot Toast HUD and Procgen Archive Resolve paired review packets now have canonical target metadata, fresh reviewer context/provenance, and the exact bounded review override. Pairing and targeted authoring preflight pass for all three pairs.
- Ready V2 implementation/correction packets missing required fields now receive a precise invalid reason and cannot be claimed. Existing historical review packets are not bulk-stranded by retroactive provenance requirements; new/changed review authoring preflight does require those fields. Archived packets are not re-graded as active authoring candidates.

## Lossless lifecycle cleanup

Moved by deterministic `dispatch.py repair --apply --archive-completed` (exact `Status: complete`, no Workstream/Dispatch, non-empty `Completed:`; bytes preserved):

- `ASH_BELL_LOWER_QUARTER_FIRST_PASS.md`
- `ASH_BELL_THREADWAY_POLISH.md`
- `COMMAND_PRESSURE_SCENARIO_V1.md`
- `CONTROLLER_INPUT_HARDENING.md`
- `DEV_OBSERVATORY_AUDIT_REMEDIATION.md`
- `ENEMY_GRUNT_ASSET_V2_RUNTIME_MODULARIZATION.md`
- `MELEE_SOFT_TARGETING_AND_RANGE_READABILITY.md`
- `MODULAR_NEXT_ACTIONS_AND_DEV_MODE.md`
- `OPERATOR_ALIGNMENT_REPAIR_V2_HARDENING.md`
- `OPERATOR_FIELD_PATCH_V1.md`
- `OPERATOR_FRAME_AWARE_WEAPON_SOCKETS.md`
- `OPERATOR_MODULAR_INGEST_HARDENING.md`
- `PARRY_CRITICAL_BRANCHING_AND_VFX.md`
- `PROCGEN_PRETERRAIN_DIAGNOSTICS_EXTRACTION.md`
- `RANGED_COMBAT_BALANCE_AND_STEALTH.md`
- `RUNTIME_READY_ASSET_DROP.md`
- `RUNTIME_STUTTER_PERFORMANCE_PASS.md`
- `SUNDERED_KEEP_FRONTAGE_CORRECTNESS.md`
- `SUNDERED_KEEP_MAPPER_CONSOLIDATION.md`
- `SUNDERED_KEEP_ROUTE_MASTER_APPROACH.md`
- `TERMINAL_SENSORS_INTELLIGENCE_V1.md`
- `TERRAIN_GAMEPLAY_ART_RUNTIME_VISUALS.md`
- `VIGIL_PATTERN_DAGGER_ATTACK_DRIVE.md`
- `WORLD_ORIGIN_BRANCH_ISOLATION.md`

Authoritative path references were updated in `FILE_INDEX.md`, archived `PROCGEN_PERFORMANCE_BASELINE_V1.md`, `PARRY_CRITICAL_BRANCHING_AND_VFX.md`, and `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`. Generated historical reports were not rewritten. The repair plan includes exact preimage hashes and byte-safe moves; a repeated apply reported only `already canonical` / `changed: false` for all candidates and made no lifecycle changes.

The following 22 complete-looking legacy records remain in the active directory because no explicit top-level completion evidence was present. Their status/content was not promoted or rewritten:

`BLACK_RELIQUARY_UI.md`, `ELEVATION_SUITE_V1.md`, `ENEMY_BEHAVIOR_VAULT_THEFT_V1.md`, `ENEMY_MARINE_DASH_TUNING.md`, `ENEMY_MARINE_TACTICAL_DASH_V2.md`, `EXPEDITION_RESOURCE_PLACEMENT_STEP_1.md`, `GOTHIC_COMPOUND_OCCLUSION_AND_SCALE.md`, `HUD_MINIMAP_STAMINA_CONTEXT_UI.md`, `LAST_ROUTEKEEPER_EVENT.md`, `MAIN_MAP_ROADS_AND_SPEED_SURFACES.md`, `MELEE_ATTACK_PROFILE_CONSOLIDATION.md`, `OPERATOR_DODGE_RANGED_MODULAR_WIRING.md`, `PROCGEN_INTENT_GRAPH_ASCENT_V1.md`, `RELIQUARY_UI_TO_INVENTORY_STATUS_LOG.md`, `RESOURCE_NODE_SPRITE_WIRING.md`, `ROAD_SURFACE_ROLE_RENDERER.md`, `SUNDERED_KEEP_CHEATSHEET_RELAYOUT.md`, `SUNDERED_KEEP_LARGE_FRONT_GATE.md`, `SUNDERED_KEEP_LEVEL_EXPANSION.md`, `SUNDERED_KEEP_RUNTIME_REGRESSION_FIXES.md`, `TERMINAL_INPUT_FOCUS_FIX.md`, `VEHICLE_REGISTRY_IMPLEMENTATION.md`.

## Branches, claims, and protected ownership

The implementation's contemporaneous live branch audit reported zero interrupted remote dispatch claims and released no claim, branch, mutex, or worktree. Its exact Git/ref snapshot was not persisted, so that report is an unbound historical observation. The separately reproducible packet-tree identity evidence above does not depend on that live-ref report.

- `ash-bell-ritualant-runtime-truth-closeout`: `origin/agent/...`, 0 ahead / 304 behind, attached clean worktree; local and published diagnostic traces exist. Protected as attached/live.
- `awakening-handoff-readiness-art-convergence-v1-r1`: remote branch, 0/92, attached clean; protected as plausible active Awakening owner.
- `operator-mobile-guard-composition`: remote branch, 0/277, attached clean; protected as attached.
- `review-bridged-falls-generated-region-lifecycle-review-corrections-1`: remote branch, 0/234, attached clean; diagnostic evidence exists; protected as attached.
- `procgen-authored-claim-registry-extraction`: local-only branch, 0/602, attached clean; remote ref absent. Protected because its worktree is attached and ownership cannot be inferred from zero-ahead ancestry.
- `vehicle-field-scout-buggy-class-v1`: local-only branch, 1/453, attached and dirty, with a unique commit and dirty `BRANCH_ARCHIVE.md`; protected, no cleanup attempted.
- `review-living-world-abstract-activity-foundation-review-corrections-1`: remote branch, 2/3, attached clean; unique commits and an attached worktree; protected.
- `npa-4-standard-enemy-melee-extraction`: completed/archived by upstream commit `b5ce4e52`; no live branch disposition action was needed here.
- This task's own branch remains attached until `workstream.py finish` safely lands it.

The protected rows are concrete ownership blockers for claim release only. They do not block the safe packet/index repairs. Trace availability is corroboration, not proof that a branch is abandoned or safe to remove.

## Prevention and evidence

- Added deterministic human/JSON `dispatch.py audit` from the shared dispatcher decision, including exact ineligibility reasons, dependencies/pairing/claims, separate raw/managed/claimable counts, and local/remote branch ownership diagnostics. Queue index remains a generated view.
- Added fail-closed, dry-run-first, idempotent `dispatch.py repair` for explicitly enumerated safe metadata/index/archive repairs. It does not mutate branch/worktree/claim state.
- Shared V2 required-field validation now blocks malformed ready implementations/corrections; authoring preflight and active context validation use the same contract.
- CI now runs context, index, review-pairing and focused agent tooling tests. Root/custodian instructions, task template, lifecycle guide and CUSTODIAN Next document the same audit/repair/dispatcher authority.
- Focused tests passed individually: `test_task_packet_contract` (26), `test_task_packet_index` (12), `test_dispatch` (79), `test_task_packet_repair` (3), `test_run_trace` (1), `test_workstream` (38), `test_validate_task_packet_authoring` (9): 168 tests total.
- Also passed: `validate_review_pairing.py` (48 current auto pairs), `task_packet_index.py` (PASS), `check_ai_context.py --json` (`finding_count: 0`), changed-packet authoring preflight, repair idempotence, and `git diff --check`.
- One earlier combined unittest invocation exposed order-sensitive capture failures in `test_run_trace` and authoring CLI fixtures; each affected module passed in isolation and the final per-module suite passed. The noisy `git show NEVER_EXISTED_CLAUDE_SUMMARY.md` line is an expected negative-path fixture in `test_workstream`; the suite result was green.

## Remaining protected blockers

- Attached agent worktrees listed above remain under their owners' control; release requires affirmative owner/claim resolution through normal branch-hygiene lifecycle.
- The 22 legacy completion-looking files need source-owner evidence before archive; their identities remain searchable and visible.
- At the pre-archive `b5ce4e52` live audit, 101 entries were classified invalid/recovery, including legacy schema residue and upstream-specific defects. This count is tied to that exact tree/ref observation, not to the repaired `7f435561` result or current main. The task did not fabricate a complete contract for ambiguous historical entries; newest-main invalid references found during review were repaired as itemized above.

## Process receipt

- Implementation status: complete, pending safe landing and independent paired review.
- Reconciliation result: safe repairs applied; ambiguous ownership preserved.
- The implementation summary's before/after machine outputs were not retained with their exact Git and remote-ref snapshots. The original claim-time raw count remains explicitly unbound above; the source-tree counts and identity sets in this correction are reproducible from their full Git SHAs.


## Correction 1 reconciliation refresh

- The correction implementation refreshed the live snapshot at `origin/main@1aaeba23d3ad1a758d53e1224045951ff543e227`. Its queue counts and eligible identity set are unchanged from `37b84831`: 219 raw active files, 156 managed packets, 24 claimable auto packets, 0 interrupted claims and 0 claim-only orphan claims. The correction branch was six commits behind main at that exact audit; it remained attached to its dirty worktree and no claim refs were present.
- The raw/managed/eligible counts above are live dispatcher output from the corrected candidate code, while the exact source-tree inventory remains bound to each source tree listed earlier. Current live branch ownership is volatile and must be refreshed by the paired reviewer at its own captured SHA.
- R0-01 is corrected in the candidate dispatcher: temporary claims without canonical agent branches suppress named/next eligibility, count an active packet exactly once as invalid/recovery, and expose claim-only orphans in a separate field. The tests assert repeated JSON stability and preserve the recovery ref. R0-02 is corrected by removing concurrent patches to process-global `builtins.print`; the exact committed five-module CI command passes 122 tests. R0-03 is corrected by the exact-tree inventory and identity delta above. These findings remain subject to independent paired re-review.
