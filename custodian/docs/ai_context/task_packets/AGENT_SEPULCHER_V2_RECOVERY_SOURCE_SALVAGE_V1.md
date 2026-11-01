# SOURCE SALVAGE: Sepulcher V2 Host Validation Recovery, Exact Historical Replay

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-sepulcher-v2-recovery-source-salvage-v1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `sepulcher-canonical-operator-floor-v2-preview-v1`
- Locks: `sepulcher-v2-recovery-source-salvage`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, workflow`
- Paired review workstream: `review-agent-sepulcher-v2-recovery-source-salvage-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Replaying stranded source onto a new authenticated workstream must not erase original claim/evidence, allow unauthorized parallel edits, or accept the missing pre-merge lifecycle witness; original failed-report controls require independent review.`
- Reviewed main: `878009b2ba90e801b3d20a4abd675732e51f137a`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: `Safely land the exact three corrected V2 host-validation source files already committed to the preserved remote branch, using a NEW witnessed claim and immutable source comparison instead of rewriting/force-pushing the old branch or fabricating a pre-resume checkpoint.`
- Completion boundary: `Source-preserving non-destructive replay of exactly three pinned files into a fresh dispatcher-authorized correction branch, one changed-file green validation report and normal finish, then fresh paired independent review. The old claim/branch, its held V2 review and all evidence remain byte-for-byte unchanged; their subsequent disposition is separate.`
- Current measured state: `As of 878009b2ba90e801b3d20a4abd675732e51f137a, original recovery implementation source was committed at de43568f51125fe49bc5ca3915b3f348ad3d35a3 and post-source smoke fix/packet transition at 332ecf8bd7fdb4a46bc931dc49071911213d3d04. Its active preserved branch is reported at f48fe5f62e6f0b4c99c2437f459311c81c30ff3d. During resume, merge bfc7ad394818eae9b48598085dd56dba3ea6981c introduced main f38d7f405014960072e10feeb93f339e1ba7067e with first parent 332ecf8bd7fdb4a46bc931dc49071911213d3d04, but the active lifecycle trace lacks the checkpoint_completed witness before that merge. workstream.py::_source_span_sync_merge_witness_error requires a unique exact pre-merge checkpoint for that first parent, so an after-the-fact checkpoint cannot repair the old branch history. An existing original reviewer remains held on V2 implementation SHA 58f52ac2b8f7e5ea60b48a00a3af57f55ee32c79 and has no verdict.`
- Evidence: `Git source trees de43568f51125fe49bc5ca3915b3f348ad3d35a3, 332ecf8bd7fdb4a46bc931dc49071911213d3d04, bfc7ad394818eae9b48598085dd56dba3ea6981c, f48fe5f62e6f0b4c99c2437f459311c81c30ff3d; f38d7f405014960072e10feeb93f339e1ba7067e main; three exact file blob identities below; workstream.py source-span producer gate; AGENT_WORKSTREAM_LIFECYCLE.md checkpoint/resume contract; original host report hashes user reverified unchanged.`
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/tools/agent/workstream.py; custodian/tools/agent/workstream_recovery.py; custodian/tools/agent/dispatch.py; the old workstream source commit and immutable Git trees; current test validation manifest. This salvage has NO authority to weaken source-span policy or settle the old claim without an authorized separately reviewed disposition.`
- Work surface: `custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/test_paired_review_runner.py; custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd; AGENT_SEPULCHER_V2_RECOVERY_SOURCE_SALVAGE_V1_CLAUDE_SUMMARY.md; the automatically required task-packet completion and index closeout metadata for this NEW workstream only. No changes to workstream.py, the archived original packet, old reviewer, Godot scene, content sprites or Asset V2.`
- Publication inputs: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md; custodian/docs/ai_context/task_packets/AGENT_SEPULCHER_V2_HOST_VALIDATION_RECOVERY_V1.md; custodian/docs/ai_context/task_packets/REVIEW_AGENT_SEPULCHER_V2_HOST_VALIDATION_RECOVERY_V1.md; custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/test_paired_review_runner.py; custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd; custodian/tools/agent/workstream.py; custodian/tools/agent/workstream_recovery.py; custodian/tools/agent/dispatch.py; custodian/tools/agent/paired_review_host_validation.py; custodian/tools/validation/validation_manifest.json; 332ecf8bd7fdb4a46bc931dc49071911213d3d04 historical source tree; f48fe5f62e6f0b4c99c2437f459311c81c30ff3d preserved remote head`
- Change: `(1) Read-only verify no active original owner/writer, immutable old remote SHA, clean preserved worktree and source blobs; if ambiguity, stop without claiming. (2) Claim THIS DISTINCT salvage workstream under normal dispatcher without touching original. (3) Replay exactly the three Git blobs from 332ecf8bd7fdb4a46bc931dc49071911213d3d04 into the newly claimed checkout only, checking the old-main baseline for each path and exact target object SHA; do not cherry-pick historical packet/index/summary/merge commits. (4) Run focused cold Godot and runner adversarial tests and changed-file validation; keep the genuine failed report as failed evidence, not a passing receipt. (5) If current main advanced, checkpoint this new workstream BEFORE any resume auto-sync merge (workstream.py checkpoint <id> with retained checkout) and verify lifecycle witness before finish; do not create a second missing-witness problem. (6) Land and hand to the new independent reviewer. (7) Report the original held recovery claim and original V2 reviewer as distinct preserved/unresolved obligations; do not mark them complete or free their locks.`
- Preserve: `Entire old remote branch origin/agent/agent-sepulcher-v2-host-validation-recovery-v1@f48fe5f62e6f0b4c99c2437f459311c81c30ff3d, all original diagnostic refs, run trace and timestamps, existing old review claim and report pair, independent V1 review, original and current Sepulcher/Operator game scenes/art, source root and metadata outside three files. No force push, reset, rebase, duplicate original-ID claim, stale checksum overrides or unreviewed exception.`
- Non-goals: `No relaxation of _source_span_sync_merge_witness_error, no reconstruction/injection of missing checkpoint event, no direct GitHub main merge, no retroactive PASS, no original claim retirement/parking/deletion, no new V2 visual art, no source-scope override, no copy of 332ecf8 original archived packet or historical README, no automatic downstream review approval.`
- Acceptance: `A1 Verify source lineage with exact remote old branch head and these three old/new blobs, independently confirm original checkout has no live/conflicting writer; stop if changed or uncertain. A2 New claimed branch inherits current main and the only content code deltas are these THREE path-exact source blobs; preserve current main versions of all unrelated files. A3 Original old branch/ref/worktree/trace/review report hashes and original review no-verdict state preserved. A4 Replayed smoke proves fixed spawn/position without masking genuine movement; runner's failed-host-report authentication proves negative/positive cases and never reports a failed report as PASS. A5 Full focused tests, changed-file manifest, source-span preflight and lifecycle validation green; check for absent pre-sync checkpoint before every new resume sync; no evidence rewrite. A6 Fresh independent paired review after newly landed source, explicit return of outstanding old claim disposition and fresh V2 review dependencies. Human visual/art approval remains separate.`
- Validation: `Verify Git source objects using git cat-file/git ls-tree and git hash-object; check exact 3-path diff with git diff --name-only; python3 -m py_compile custodian/tools/agent/paired_review_runner.py; focused runner unittest cases including failed-report forgery negatives; Godot editor-import preflight and headless sepulcher_material_operator_v2_smoke.gd at least three cold runs plus neighboring V1 smoke; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; python3 custodian/tools/agent/workstream.py preflight agent-sepulcher-v2-recovery-source-salvage-v1 --validation-report <green-report> --json; git diff --check. Do not run overlapping unbounded CI suites.`
- Task overrides: `none`
- Deferred: `Separate proof-preserving disposition of original agent-sepulcher-v2-host-validation-recovery-v1 claim, independent fresh V2 review against newly landed code, and preventive change to workstream.py producer so resume will refuse any uncapped auto-sync missing a prior exact checkpoint witness. These are not silently declared completed by replay.`

## Exact three-file salvage manifest

**Old source branch:** `origin/agent/agent-sepulcher-v2-host-validation-recovery-v1`, pinned head `f48fe5f62e6f0b4c99c2437f459311c81c30ff3d`. Original source tree `332ecf8bd7fdb4a46bc931dc49071911213d3d04` must be its ancestor. **These three Git blobs, not the whole commit history, are the inputs:**

| Repo-relative code path | Expected original main Git blob | Required replacement Git blob |
|---|---|---|
| `custodian/tools/agent/paired_review_runner.py` | `bc22136b7692f57aeaf01c6f2863ed9b2b140f7c` | `c151ea9e573568568943659ff96f31035b94c421` |
| `custodian/tools/agent/test_paired_review_runner.py` | `a372d7df00c9fefd529829f14ca26d311d768fcd` | `cedf4d733274812ed39e1872d0384db9a6876ef7` |
| `custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd` | `a6d58798de13475931b56e0b4305e491945f3a38` | `e6eed4561b84712c4db0d9e170837c2093d1ec60a` |

Never stage the old archived original packet, original README/CLAUDE_SUMMARY, sync merge, or trace in the new worktree. The replayer inherits current main packet/index state and uses its own workstream closeout.

### One-time *new claimed checkout only* byte-exact replay

These commands MUST run **after successful new dispatcher claim** in its exact returned worktree and only after the original old source claim/writer audit is green. They are intentionally not an implementation of any changed policy:

```bash
set -euo pipefail
git fetch origin
git merge-base --is-ancestor "332ecf8bd7fdb4a46bc931dc49071911213d3d04" "refs/remotes/origin/agent/agent-sepulcher-v2-host-validation-recovery-v1" || { echo "BLOCKED: historical source commit not an ancestor of pinned old remote"; exit 2; }
test "$(git rev-parse "refs/remotes/origin/agent/agent-sepulcher-v2-host-validation-recovery-v1")" = "f48fe5f62e6f0b4c99c2437f459311c81c30ff3d" || { echo "BLOCKED: preserved original branch changed"; exit 2; }
test -z "$(git status --porcelain --untracked-files=all)" || { echo "BLOCKED: new checkout not clean"; exit 2; }
# custodian/tools/agent/paired_review_runner.py
test "$(git rev-parse "HEAD:custodian/tools/agent/paired_review_runner.py")" = "bc22136b7692f57aeaf01c6f2863ed9b2b140f7c" || { echo "BLOCKED: latest main diverged for custodian/tools/agent/paired_review_runner.py"; exit 2; }
test "$(git rev-parse "332ecf8bd7fdb4a46bc931dc49071911213d3d04:custodian/tools/agent/paired_review_runner.py")" = "c151ea9e573568568943659ff96f31035b94c421" || { echo "BLOCKED: original source blob mismatch"; exit 2; }
git show "332ecf8bd7fdb4a46bc931dc49071911213d3d04:custodian/tools/agent/paired_review_runner.py" > "custodian/tools/agent/paired_review_runner.py"
test "$(git hash-object "custodian/tools/agent/paired_review_runner.py")" = "c151ea9e573568568943659ff96f31035b94c421" || { echo "BLOCKED: replayed bytes mismatch"; exit 2; }
# custodian/tools/agent/test_paired_review_runner.py
test "$(git rev-parse "HEAD:custodian/tools/agent/test_paired_review_runner.py")" = "a372d7df00c9fefd529829f14ca26d311d768fcd" || { echo "BLOCKED: latest main diverged for custodian/tools/agent/test_paired_review_runner.py"; exit 2; }
test "$(git rev-parse "332ecf8bd7fdb4a46bc931dc49071911213d3d04:custodian/tools/agent/test_paired_review_runner.py")" = "cedf4d733274812ed39e1872d0384db9a6876ef7" || { echo "BLOCKED: original source blob mismatch"; exit 2; }
git show "332ecf8bd7fdb4a46bc931dc49071911213d3d04:custodian/tools/agent/test_paired_review_runner.py" > "custodian/tools/agent/test_paired_review_runner.py"
test "$(git hash-object "custodian/tools/agent/test_paired_review_runner.py")" = "cedf4d733274812ed39e1872d0384db9a6876ef7" || { echo "BLOCKED: replayed bytes mismatch"; exit 2; }
# custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd
test "$(git rev-parse "HEAD:custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd")" = "a6d58798de13475931b56e0b4305e491945f3a38" || { echo "BLOCKED: latest main diverged for custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd"; exit 2; }
test "$(git rev-parse "332ecf8bd7fdb4a46bc931dc49071911213d3d04:custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd")" = "e6eed4561b84712c4db0d9e170837c2093d1ec60a" || { echo "BLOCKED: original source blob mismatch"; exit 2; }
git show "332ecf8bd7fdb4a46bc931dc49071911213d3d04:custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd" > "custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd"
test "$(git hash-object "custodian/tools/validation/levels/sepulcher_material_operator_v2_smoke.gd")" = "e6eed4561b84712c4db0d9e170837c2093d1ec60a" || { echo "BLOCKED: replayed bytes mismatch"; exit 2; }
git diff --check
git diff --name-only
```

After this, independently validate the actual committed content and test it. If any of the three current-main blobs changed since `878009b2ba90e801b3d20a4abd675732e51f137a`, stop for a narrow three-file reconciliation instead of blindly replacing new source. `git show` reads existing pinned immutable Git data; no missing external ZIP, uncommitted user image or private-only tool is required.

## Review/recovery sequencing

- **Old claim remains preserved, not accepted.** This replacement is a separate source-landing operation only because the existing first-parent history is unverifiable under strict published lifecycle policy.
- **New implementation** must use its own canonical claim, fresh verified source span and independent reviewer. A source hash comparison is not itself a reviewer verdict.
- **Original held V2 technical review** retains pinned 58f52ac and failed report. Do not resume it by substituting corrected main bytes.
- **After new paired review PASS,** obtain a separately authorized plan for truthful original-claim disposition, and a fresh V2 technical review of the new corrected code if not covered by the paired salvage review. Human Operator/floor art acceptance remains entirely open.

## Next Handoff

- Next workstream: `review-agent-sepulcher-v2-recovery-source-salvage-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none; deterministic source recovery with reviewer approval does not require a new artistic design decision`
- Next action: `Fresh independent review exact three-file salvage source and lifecycle, then separately plan original stranded claim disposition and fresh V2 tech review. Do not mark previous reviews passing.`
- Blockers or open questions: `Original host claim/no-writer audit must pass before creating another checkout; if original is actively edited or the remote source branch changes, stop and report. No host-only run identity is guessed.`
