# AGENT VALIDATION GATE DRIFT REPAIR

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-validation-gate-drift-repair`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow, task-packet-validation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-validation-gate-drift-repair`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `440dccbb274707869eb0a9eebf109e6588a4f26c`
- Goal: Restore truthful green agent landing gates after two independent pieces of repository metadata/tooling drift began blocking unrelated completed workstreams: the agent workflow smoke still requires an intentionally deleted expiry workflow, and the task-packet validation-reference gate mis-resolves valid Godot/project-root validation paths.
- Completion boundary: This slice is complete when `agent_workflow_contract` validates the post-expiry repository state without requiring the deleted temporary workflow; `review_pairing_contract` accepts valid `res://tools/...` / project-root `tools/...` validation references by resolving them to tracked repository paths while still rejecting genuinely missing scripts; the one currently ready packet that truly forward-references a not-yet-created smoke is repaired without weakening the gate; the eight current false-positive workstream failures disappear; focused dispatcher/packet/workflow tests and both manifest-backed gate IDs pass on current main; and no gameplay/runtime implementation is changed.
- Current measured state:
  - Commit `761d901c9ffe6c919f52168acecef24a9c7e95c6` intentionally expired Git LFS degraded mode and temporary procgen routing. It deleted `.github/workflows/expire-lfs-degraded-mode.yml`, removed the temporary routing/LFS marker blocks from `custodian/AGENTS.md`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/land_main.py`, and `tools/custodian_aliases.sh`.
  - `custodian/tools/validation/agent_workflow_smoke.py::validate_procgen_packet_routing_expiry()` still unconditionally opens that deleted workflow and asserts the now-expired marker text is present. `validation_manifest.json` still lists the removed workflow as an `agent_workflow_contract` owner. As a result, `agent_workflow_contract` fails on clean current main because its test asserts the *pre-expiry* state after the expiry commit has deliberately removed it.
  - `custodian/tools/agent/task_packet_contract.py` currently extracts validation references with `VALIDATION_SCRIPT_RE = ...((?:custodian/)?tools/...)`. A packet command such as `res://tools/validation/foo.gd` is therefore stored as `tools/validation/foo.gd`, losing the `res://` context.
  - `validate_packet_validation_references()` then lists only `custodian/tools/**` from Git and compares the extracted string literally. Therefore a live Godot resource such as `res://tools/validation/world_contract_prewarm_smoke.gd` is reported missing even though the tracked file is `custodian/tools/validation/world_contract_prewarm_smoke.gd`.
  - The resulting false positives currently affect seven ready packets whose validation files exist but are written in project-root/Godot form: `contract-world-placement-foundation`, `contract-world-resource-placement-extraction`, `contract-world-vehicle-placement-extraction`, `contract-world-relay-placement-extraction`, `contract-world-encounter-placement-extraction`, `contract-world-ingress-placement-extraction`, and `procgen-render-attribution-v1`.
  - The eighth current failure, `operator-art-registration-profile`, is different: its ready packet literally names `custodian/tools/validation/operator_art_registration_profile_smoke.py`, but that script is intentionally implementation-created and does not exist yet. This is a real ready-packet metadata defect, not a path-normalization false positive.
  - `validate_review_pairing.py` is only the wrapper selected by `review_pairing_contract`; the path behavior comes from shared `task_packet_contract.py::validate_packet_validation_references()`. Fix the shared authority rather than special-casing the wrapper.
  - Multiple unrelated implementation branches have now reported the same pair of failures after syncing with latest main, including `agent/enemy-marine-dash-ability-extraction@885310706` and the Operator blocking-art workstream. Their task-specific runtime checks are not implicated by either failure.
- Evidence: `761d901c9ffe6c919f52168acecef24a9c7e95c6`; `custodian/tools/validation/agent_workflow_smoke.py`; `custodian/tools/validation/validation_manifest.json` entries `agent_workflow_contract` and `review_pairing_contract`; `custodian/tools/agent/task_packet_contract.py::{VALIDATION_SCRIPT_RE,_validation_script_references,validate_packet_validation_references}`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/validate_review_pairing.py`; `custodian/tools/agent/test_task_packet_contract.py`; `custodian/tools/agent/test_dispatch.py`; the eight ready packets named above; checkpoint `885310706` as an unaffected-runtime landing blocker example.
- Task-specific authority: `custodian/tools/agent/task_packet_contract.py` is the one shared packet grammar/validation authority; `dispatch.py` owns eligibility using that authority; `validate_review_pairing.py` exposes the same authority as the manifest-backed gate; `agent_workflow_smoke.py` owns the agent-workflow regression bundle; `validation_manifest.json` owns changed-file selection; `AGENT_TASK_PACKET_TEMPLATE.md` / task-packet README own ready-packet authoring rules.
- Work surface:
  - Primary code: `custodian/tools/agent/task_packet_contract.py`.
  - Workflow smoke: `custodian/tools/validation/agent_workflow_smoke.py`.
  - Focused unit coverage: `custodian/tools/agent/test_task_packet_contract.py`, `custodian/tools/agent/test_dispatch.py`; touch `test_review_contract.py` only if a directly affected shared-contract assertion belongs there.
  - Validation ownership: `custodian/tools/validation/validation_manifest.json`.
  - Ready-packet metadata repair: `custodian/docs/ai_context/task_packets/OPERATOR_ART_REGISTRATION_PROFILE.md`.
  - Authoring guidance if needed for recurrence prevention: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, `custodian/docs/ai_context/task_packets/README.md`, `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`.
  - Do not edit Marine, Operator gameplay, procgen runtime, ContractWorldLoader, or any task-specific production/runtime files.
- Change:
  1. **Replace the obsolete positive expiry assertion with a post-expiry invariant.** In `custodian/tools/validation/agent_workflow_smoke.py`, remove/replace `validate_procgen_packet_routing_expiry()`. The new focused check should verify the intentionally expired state instead of opening a deleted file. Recommended shape:
     
     ```python
     def validate_expired_lfs_routing_absent() -> None:
         assert not (ROOT / ".github/workflows/expire-lfs-degraded-mode.yml").exists()

         marker_targets = {
             ROOT / "custodian/AGENTS.md": (
                 "TEMP_PROCGEN_PACKET_ROUTING_START",
                 "TEMP_LFS_DEGRADED_MODE_START",
             ),
             ROOT / "custodian/tools/agent/workstream.py": ("TEMP_LFS_DEGRADED_MODE_START",),
             ROOT / "custodian/tools/agent/land_main.py": ("TEMP_LFS_DEGRADED_MODE_START",),
             ROOT / "tools/custodian_aliases.sh": ("TEMP_LFS_DEGRADED_MODE_START",),
         }
         for path, markers in marker_targets.items():
             text = path.read_text()
             for marker in markers:
                 assert marker not in text
     ```
     
     Call that check from `main()`. Do not re-create the scheduled workflow or temporary blocks merely to satisfy the smoke. The deleted state is the intended live state.
  2. **Reconcile changed-file ownership with the live state.** In `custodian/tools/validation/validation_manifest.json` under `agent_workflow_contract.owners`, remove `.github/workflows/expire-lfs-degraded-mode.yml`. If the new absence check reads `tools/custodian_aliases.sh`, add that live path as an owner so reintroducing a temporary marker there selects the workflow contract. Preserve `.github/workflows/validate-repository.yml` and other live owners.
  3. **Preserve validation reference syntax instead of dropping `res://`.** In `task_packet_contract.py`, make `VALIDATION_SCRIPT_RE` capture the full supported validation-path forms. Recommended contract:
     
     ```python
     VALIDATION_SCRIPT_RE = re.compile(
         r"(?<![A-Za-z0-9_])"
         r"((?:res://tools|custodian/tools|tools)/"
         r"[A-Za-z0-9_./-]+\.(?:py|gd|sh))"
         r"(?=$|[\s`),.;:])"
     )
     ```
     
     `_validation_script_references()` should keep the original reference spelling in `Packet.validation_scripts` for diagnostics instead of silently rewriting packet text.
  4. **Resolve references against repository paths through one deterministic helper.** Add a private helper in `task_packet_contract.py` (name may vary, e.g. `_validation_reference_candidates(reference)`) with this exact semantic mapping:
     
     ```text
     custodian/tools/...  -> custodian/tools/...
     res://tools/...      -> custodian/tools/...
     tools/...            -> tools/... OR custodian/tools/...
     ```
     
     The last form is intentionally dual because repository-root commands use the tracked root `tools/` directory while commands executed after `cd custodian` use project-root `tools/`. Prefer an exact tracked `tools/...` match when it exists; otherwise accept the tracked `custodian/tools/...` candidate. Never resolve arbitrary `res://` paths outside `res://tools/` through this gate.
  5. **Validate against both legal tool roots.** Update `validate_packet_validation_references()` to list tracked paths under both `custodian/tools` and root `tools`, resolve each original packet reference through the candidate helper, and pass when at least one legal candidate exists. Continue checking only ready packets and honoring `exclude_workstreams`.
  6. **Keep fail-closed behavior for real missing references.** If no candidate exists, preserve the original reference in the error and include nearest live repository-path diagnostics. A typo like `custodian/tools/validation/operator_art_registraton_smoke.py` must still block claim. Do not weaken the rule to "anything under tools is acceptable" and do not skip validation-reference checking globally just to unblock current workstreams.
  7. **Repair the actual forward-reference defect in `OPERATOR_ART_REGISTRATION_PROFILE.md`.** Its ready packet must not literally name `custodian/tools/validation/operator_art_registration_profile_smoke.py` before the implementation creates that file. Rewrite the first validation bullet to describe creation/registration of a dedicated focused smoke under `custodian/tools/validation/` without an exact nonexistent script filename. State that once the workstream creates the file, it must update its own task-branch packet to name the exact live path before closeout. Keep the currently existing `operator_art_source_smoke.py`, `operator_art_agent_semantic_smoke.py`, `operator_art_agent_mcp_smoke.py`, and `operator_art_agent_aseprite_smoke.py` references intact.
  8. **Do not churn the seven valid packets.** `CONTRACT_WORLD_PLACEMENT_FOUNDATION.md`, the five placement extraction packets, and `PROCGEN_RENDER_ATTRIBUTION_V1.md` use legitimate Godot/project-root notation. They should become valid because the shared validator understands repository/project path equivalence, not because seven packets are mechanically rewritten. If one of those paths is actually absent after canonical resolution, treat that as a real packet defect and report it instead of hiding it.
  9. **Add direct grammar/resolution regression coverage.** In `test_task_packet_contract.py`, prove extraction preserves `res://tools/validation/foo.gd`, `custodian/tools/validation/foo.py`, and `tools/validation/foo.gd` as distinct original references. Test the candidate mapper directly if exposed within the module.
  10. **Add temporary-repository behavioral coverage.** In `test_dispatch.py`, extend the existing stale-validation tests with at least:
      - a tracked `custodian/tools/validation/live.gd` satisfying packet reference `res://tools/validation/live.gd`;
      - the same tracked file satisfying project-root `tools/validation/live.gd` when no root `tools/validation/live.gd` exists;
      - a tracked root `tools/example_check.sh` satisfying exact root reference without being remapped to `custodian/tools`;
      - a genuinely missing path still blocking status/claim with nearest-path output;
      - no regression to claimed-workstream exclusion or review-pairing validation.
  11. **Clarify the authoring contract.** In `AGENT_TASK_PACKET_TEMPLATE.md` and/or `task_packets/README.md`, document that ready packets may reference an already-live validation script as repository-root `custodian/tools/...`, Godot `res://tools/...`, or project-root `tools/...`; the validator resolves those to tracked repo paths. Implementation-created future validation should be described generically until the file exists, then named exactly on the task branch before completion. Prefer repository-root paths in prose where no command context requires project-root/Godot syntax.
  12. **Prove the exact current false-positive set is gone.** After the code/doc changes, run `validate_review_pairing.py` against current main/HEAD and explicitly verify none of these workstreams are reported for validation-reference errors: `operator-art-registration-profile`, `contract-world-placement-foundation`, `contract-world-resource-placement-extraction`, `contract-world-vehicle-placement-extraction`, `contract-world-relay-placement-extraction`, `contract-world-encounter-placement-extraction`, `contract-world-ingress-placement-extraction`, `procgen-render-attribution-v1`.
- Preserve: Remote-claim atomicity; paired review semantics; ready-packet fail-closed validation-reference checks; nearest-path diagnostics; current packet parser metadata behavior outside validation paths; workstream completion truth; current `land_main.py` and `workstream.py` runtime behavior; Git LFS state after expiry; all task-specific runtime/gameplay files; unrelated packet dependencies/locks; changed-file validation selection outside the corrected owner paths.
- Non-goals: Do not restore temporary Git LFS degraded mode or procgen routing. Do not recreate `expire-lfs-degraded-mode.yml`. Do not disable `agent_workflow_contract` or `review_pairing_contract`. Do not bulk-rewrite all task-packet validation commands to repository-root syntax. Do not edit Marine dash implementation or Operator blocking assets. Do not change Godot project root conventions. Do not redesign dispatcher/review architecture beyond the path-resolution defect.
- Acceptance:
  - `python3 custodian/tools/validation/agent_workflow_smoke.py` passes on the post-expiry repository with the expiry workflow absent and temporary markers absent.
  - `validation_manifest.json` no longer lists the removed expiry workflow as a live owner; changed `tools/custodian_aliases.sh` still selects `agent_workflow_contract` if the new absence check depends on it.
  - Packet parsing preserves all three supported validation reference spellings: `custodian/tools/...`, `res://tools/...`, and `tools/...`.
  - Reference validation accepts a live tracked `custodian/tools/validation/foo.gd` for `res://tools/validation/foo.gd`; accepts project-root `tools/validation/foo.gd` through the `custodian/` candidate when no root file exists; and still accepts an actual tracked root `tools/foo.sh` as root-owned.
  - A genuinely missing validation script still blocks a ready packet and reports the original reference plus a useful nearest live path.
  - `OPERATOR_ART_REGISTRATION_PROFILE.md` no longer forward-references a nonexistent focused smoke while ready; its workstream remains responsible for creating/registering/naming that smoke during implementation.
  - The seven legitimate Godot/project-root packets named above require no textual path churn and no longer fail validation-reference checking.
  - `python3 custodian/tools/agent/validate_review_pairing.py` passes on current main/HEAD with none of the previous eight workstreams reported.
  - `agent_workflow_contract` and `review_pairing_contract` both pass via `run_validation.py --test ... --json`.
  - Existing `test_task_packet_contract.py`, `test_dispatch.py`, `test_review_contract.py`, and landing/workstream tests invoked by `agent_workflow_smoke.py` remain green.
  - No files under `custodian/game/`, `custodian/content/sprites/`, Marine runtime, Operator runtime, or procgen runtime are modified.
- Validation:
  - Run `python3 custodian/tools/agent/test_task_packet_contract.py`.
  - Run `python3 custodian/tools/agent/test_dispatch.py`.
  - Run `python3 custodian/tools/agent/test_review_contract.py`.
  - Run `python3 custodian/tools/agent/validate_review_pairing.py`.
  - Run `python3 custodian/tools/validation/agent_workflow_smoke.py`.
  - Run `python3 custodian/tools/validation/run_validation.py --test agent_workflow_contract --json`.
  - Run `python3 custodian/tools/validation/run_validation.py --test review_pairing_contract --json`.
  - Then run one `python3 custodian/tools/validation/run_validation.py --changed --max-tier unit --json` closeout and `git diff --check`.
  - No Godot/runtime/visual validation is required; this is agent workflow metadata/tooling repair.
- Task overrides: `none`
- Deferred: Any separate AI-context index drift not selected by these two gates; LFS diagnostic-push timeout improvements; broader worktree import/LFS hydration work; task-specific implementation changes in currently blocked Marine/Operator/procgen workstreams.

## Handoff

- Next action: Claim this P0 workstream before attempting to land more unrelated branches blocked by the same two gates. Fix the expiry smoke and shared path resolver first, then repair the one genuine Operator packet forward reference and prove the eight-workstream failure set disappears.
- Best starting files: `custodian/tools/validation/agent_workflow_smoke.py`, `custodian/tools/agent/task_packet_contract.py`, `custodian/tools/agent/test_task_packet_contract.py`, `custodian/tools/agent/test_dispatch.py`, `custodian/tools/validation/validation_manifest.json`, `custodian/docs/ai_context/task_packets/OPERATOR_ART_REGISTRATION_PROFILE.md`.
- Blockers or open questions: None. Both failures are reproducible repository gate drift on current main; task-specific Marine/Operator runtime is not required to repair them.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `none`
- What went wrong: `pending`
- Root cause / contributing factors: `pending`
- Prevention / pipeline improvement: `pending`
- Tooling / docs drift discovered: `pending`
- Follow-up: `pending`
- What worked: `pending`
