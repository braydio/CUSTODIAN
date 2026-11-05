# PixelPlanets Retirement: Exact Held-Review Source-Scope Attestation V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-pixelplanets-review-source-scope-attestation-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `paired-review-source-provenance, paired-review-host-validation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-pixelplanets-review-source-scope-attestation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `A historical source-path/validation-manifest exception touches the independent-review trust boundary. It must be exactly scoped, immutable, fail-closed until separately accepted by an independent reviewer, and tested against the real Git history.`
- Reviewed main: `5991a89b7aa52c2fd87d00d3032ed506453e9a54`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Visual review: `none`
- Goal: `Enable a safe, explicitly authorized same-run host-validation recovery plan for the already-claimed PixelPlanets retirement review, whose immutable target packet omitted exact paths for its new focused smoke and validation-manifest change.`
- Completion boundary: `Land one exact historical source-scope/manifest attestation record and narrowly gated verifier/test support through this implementation's own canonical workstream; obtain its distinct independent paired-review PASS before the original review may be replanned. Do not apply recovery, launch the original reviewer, or mutate its claim, checkout, archived packet or evidence in this implementation.`
- Current measured state: `The PixelPlanets retirement implementation landed on main at 5991a89b7aa52c2fd87d00d3032ed506453e9a54 (source commit 25a7f6d1c1d6e995d8cefed2a5b0865de481b217). The preserved paired-review runner run 20261105T150829Z-655fc0421dbb claimed the exact review through dispatcher claim run 20261105T150852Z-da80bd813558, then failed pre-launch host validation because its immutable archived target packet described focused tests generically. Source-span verification rejects precisely custodian/tools/validation/planet_contract_retirement_smoke.gd and custodian/tools/validation/validation_manifest.json as undocumented. No reviewer was launched or accepted, and the original claim and execution lock remain held. The source commit contains both paths, each as a regular Git file; smoke blob 330735696b13a1365eb2124715c69e2bcb8a027e and manifest blob c1e10bbfef6a31fa030a8c1f5f1691e463b8e49e. After the path gate, the changed-manifest coverage gate independently requires a recognized accepted exact attestation.`
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span and _source_path_documented and _attested_manifest_comparison; custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/test_paired_review_runner.py; custodian/docs/ai_context/task_packets/archived/PROCGEN_PIXELPLANETS_LEGACY_RETIREMENT_V1.md; custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_PIXELPLANETS_LEGACY_RETIREMENT_V1.md; Git source commit 25a7f6d1c1d6e995d8cefed2a5b0865de481b217 and archive main 5991a89b7aa52c2fd87d00d3032ed506453e9a54; preserved host run .git/custodian-review-runs/review-procgen-pixelplanets-legacy-retirement-v1/20261105T150829Z-655fc0421dbb/; existing Grunt and Operator source-scope attestations.`
- Task-specific authority: `AGENTS.md; custodian/AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/paired_review_runner.py; archived original implementation packet and exact review run; accepted post-hoc attestation and independent-review acceptance contracts.`
- Work surface: `custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/test_paired_review_runner.py; new custodian/docs/ai_context/review_scope_attestations/pixelplanets_retirement_review_scope_v1.json; only minimal supporting fixtures within existing tests if needed. Do not edit the original Godot implementation, its archived packet, current review packet, original review claim/worktree/evidence, unrelated attestation cases or validation_manifest.json.`
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py, custodian/tools/agent/paired_review_runner.py, custodian/tools/agent/test_paired_review_runner.py, custodian/tools/agent/review_outcome.py, custodian/tools/agent/review_receipt_delta.py, custodian/tools/agent/task_packet_contract.py, custodian/tools/validation/run_validation.py, custodian/tools/validation/validation_manifest.json, custodian/docs/ai_context/task_packets/archived/PROCGEN_PIXELPLANETS_LEGACY_RETIREMENT_V1.md, custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_PIXELPLANETS_LEGACY_RETIREMENT_V1.md, custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
- Change: `Implement one exactly pinned post-hoc source-scope attestation for the existing PixelPlanets implementation/review run and the two omitted source/test paths, using the established approval_main and independent canonical correction-review PASS/receipt lineage checks. Bind immutable source base/head/archive parent/tree/packet blob, exact source-path inventory, both omitted regular-file path/blobs/modes, original claim/ref/run and reviewer claim/run identities, and exact old/new manifest test-registration delta. Add the exact case in split-landing documentation verification AND in _attested_manifest_comparison; otherwise a path-only patch simply moves the blocker to manifest coverage. The record must remain inert until THIS correction's independent review is genuinely accepted on origin/main. Never weaken generic path/manifest rules, allow a directory/glob, accept other archives or pretend the original reviewer passed.`
- Preserve: `Original PixelPlanets source/main and original archived packet bytes, six planet profiles and runtime migration, the already-held review claim, branch, checkout, runner run/RECOVERY.md/validation evidence, execution lock, existing user relay scripts, all other source-scope attestations, existing review verdict and recovery gates. The protected declared-doc review and WIRE review are separate and must not be altered or released.`
- Non-goals: `No retroactive edit to historical implementation packet or source commit; no original review re-claim/relaunch, verdict, plan apply, generic policy relaxation, manifest omission, test-waiver, unrelated lock parking, old worktree cleanup, Godot changes or new artwork.`
- Acceptance: `A failing-first real-Git regression replays the exact historical source span and original two-path rejection. The correction authenticates the pinned original source/review and exactly these two omitted files, returning accepted-post-hoc-exact-source-attestation provenance ONLY after real canonical independent PASS and accepted receipt for THIS correction; forged or unaccepted PASS remains rejected. Positive case authenticates the exact manifest before/after test registration and retains complete canonical test-selection/coverage rules. Negative cases reject any changed path/blob/mode/commit/parent/tree/packet/review/claim/run, any added third path, absent or altered attestation, stale approval main, fake reviewer outcome, unrelated workstream, or change to other manifest fields. Historical run evidence remains byte-exact and no original reviewer is launched. Focused unit and canonical changed-file validation pass.`
- Validation: `Add failing-first disposable Git repository fixtures for exact pinned history and revised manifest, then run PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v; python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. Verify exact original run/claim/checkout files unchanged before/after read-only inspection; do not apply recovery during this task.`
- Task overrides: `none`
- Deferred: `After THIS correction's fresh independent paired review passes and is canonically accepted on main, run one fresh read-only plan for the preserved original review with --continue-run 20261105T150829Z-655fc0421dbb --recover-host-validation --plan. Do not apply without a separately authorized SHA-pinned plan and genuine fresh reviewer context.`

## Implementation Notes

- The original archived packet is immutable and a later documentation-only edit cannot change what the original run validated. Use approval_main on verified current main as established by the Operator/admin historical scope exceptions.
- The exact pair of missing paths is a historical omission, not authority to skip the manifest's changed-test definition gate. Add both recognition points and prove tamper rejection.
- The current host reports the protected review checkout still claimed. Inspect its immutable run evidence only once for pin verification, then implement and land code; no repeated worktree archaeology.
- Respect the existing execution lock. This packet is mechanically ready but cannot dispatch until the authority lock is actually free; never rename a lock to defeat contention.

## Next Handoff

- Next workstream: `review-agent-pixelplanets-review-source-scope-attestation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Refresh reason: `Independent review of the exact exception is required; no new human design choices are pending.`
- Next action: `Run a genuinely fresh paired review of this specific correction after canonical implementation finish and accept only a real PASS; afterward prepare a read-only original-review recovery plan. Do not apply that plan as part of this packet.`
- Blockers or open questions: `The paired-review-source-provenance lock is reportedly held by a separate claimed review; dispatcher must establish eligibility before any implementation claim. Exact original run identity must be verified without mutation before implementation.`
