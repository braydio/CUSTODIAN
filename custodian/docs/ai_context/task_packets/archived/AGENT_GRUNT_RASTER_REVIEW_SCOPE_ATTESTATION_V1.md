# Grunt Raster Review Source-Scope Attestation V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-grunt-raster-review-scope-attestation-v1`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-grunt-attestation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-grunt-raster-review-scope-attestation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `high-impact historical source-scope attestation exception must receive fresh adversarial review`
- Reviewed main: `217f41093802b8c74cf88f986076e4e26acc8e77`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f`
- Visual review: `none`
- Goal: Unblock the already-claimed Grunt raster paired review using a narrowly auditable, post-hoc authorization of exactly six original-archive files (three Markdown documentation files and three source/data files), without rewriting history or opening any directory, glob, or generic suffix escape hatch.
- Completion boundary: Author a mechanically verified, immutable, exact SIX-file historical source-scope attestation and the minimal coordinator gate support. This support is inactive until its own independent paired review PASS is recorded on main. Preserve the currently claimed Grunt review and stop after publishing the correction; that exact run's subsequent recovery is outside this packet.
- Current measured state: `review-grunt-candidate-raster-workflow-v1` coordinator run `20261019T173219Z-d9252b20c85f`, dispatcher claim `20261019T173233Z-d3f4bbc8869f`; implementation archived source-bearing commit `e29847bb2dc409ad994ac59ee3e8bb4db637142e`; landed implementation `55918d257cb3c663fb066f56eb79b23d174b7ae2`. Host validation rejects three Markdown files not present as exact Work surface paths of the original immutable archived packet; after the attestation implementation passed the Markdown gate, full replay also rejected three source/data files absent by exact path in that same archived packet. The review claim and clean worktree remain protected, no reviewer ran. The prior `.gd.uid` gate correction landed at `236e036b4be2c7bb3d2702f0db3a515ee346468b`.
- Evidence: archived packet blob `73dc311261f396b1636d117730fdffb18be9965e` at `e29847bb2dc409ad994ac59ee3e8bb4db637142e`; three paths and blob SHAs at that commit: `custodian/docs/ai_context/CURRENT_STATE.md` => `1a9368fa1d293570c968fd486972d69f73a1a687` (12 added lines documenting Grunt raster tooling); `custodian/docs/ai_context/FILE_INDEX.md` => `4a7f88cc00689dd55ab080230e2c43b58cf6e0c5` (two Grunt raster references); `custodian/tools/iteration/raster_pipeline/README.md` => `364f0b366c6c7f25d893ca3957c05238278c0fb7` (new raster workflow README). Further exact changed original-archive source/data files: `custodian/tools/iteration/raster_pipeline/__init__.py` => `bd5b6ae6d224c86909372b1710d51efe7c3a289a` (100644); `custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json` => `4e2ecb1b333c1d95d5b3b468dbcd9b7b7162a9ae` (100644); `custodian/tools/validation/validation_manifest.json` => `f99d1deec38aac1757838bd52bee102740597808` (100644). The archived Work surface lists the raster_pipeline and validation directories and says `update only actually stale docs`, but does NOT authorize all six files by exact path. The historical gate must accurately report the omission of exact paths, not pretend directory and role descriptions are exact names.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span`; `custodian/tools/agent/test_paired_review_runner.py::PairedReviewHostValidationTests`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_DECLARED_DOC_ARCHIVE_GATE_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json` (new immutable post-hoc exception evidence); any helper in `custodian/tools/agent/` MUST be named precisely in a packet amendment before touching.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/task_packets/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_DECLARED_DOC_ARCHIVE_GATE_V1.md`
- Change: Continue the checkpointed `d0e44dd859d8fb497c9139dd418a9d3c019d377b` work, extending its pinned `custodian.review_source_scope_attestation.v1` source_files mapping from the THREE Markdown paths to EXACTLY SIX original-archive paths/blob SHAs, with original workstream, source-bearing archive SHA, target archived packet path/blob, reason and candid `post_hoc` nature. Enforce canonical path, trusted repository provenance, exact object bytes, regular 100644 file modes, original claim/trace/ancestry/source-test coverage, and no directory, glob, prefix, substring, future commit or unbounded exception matching. The attestation is supplementary authorization ONLY: it must not pretend to have existed in the original Work surface or mutate that historical blob.
- Change: Preserve the archive-landing exact-Markdown gate and extend the independent code/test documentation gate to recognize only the THREE added .py/.json paths when all SIX attested blobs/modes and the correction's independent review acceptance are verified through existing durable review receipt/authority; do not infer acceptance from this packet's `Status: complete`, an unverified text PASS, the mere existence of the attestation, or the author's own assertion. Bind the accepted attestation commit/blob/digest to the coordinator validation provenance so verification is reproducible and detects alteration or deletion. If this cannot be done with the current trustworthy verifier without a new general authority, STOP, document the exact missing primitive and propose a bounded alternate review process rather than relaxing current gates.
- Preserve: Original archived packet `73dc3112`, e298 source commit, claim + run + metadata of `20261019T173219Z-d9252b20c85f`, remote review branch, clean reviewer worktree, all validation reports, original rasters, original human visual-review manifest `/CUSTODIAN/visual_review/grunt-candidate-raster-workflow-v1/20261019T101558Z/REVIEW_MANIFEST.json`; no reviewer launch or verdict; no resurrection of abandoned `20261019T105028Z-45d22380ee25`.
- Non-goals: NO accepting arbitrary Markdown files, accepting files merely mentioned outside Work surface, relaxing source/test suffix rules, retroactively editing the e298 or 55918 commits, rewriting the archived target, bypassing review claim validation, modifying Grunt implementation, running reviewer, or applying the held host-recovery plan.
- Acceptance: A1 an immutable historical replay at e298 fails on the three Markdown paths without an accepted attestation, then fails on the three named source/data paths with a Markdown-only attestation, and passes every gate only when all SIX paths/blobs plus independent approval are verified in a synthetic accepted-review history. Actual held Grunt review remains ineligible until THIS correction review really lands. A2 if any target SHA/path/blob, attestation origin, approval authority/digest, file mode, source span or run claim differs, fail closed. A3 negative fixtures reject arbitrary .md/.json/.py, directories/globs, renamed/case-changed paths, swapped Markdown/code/data blobs, unrelated workstream, arbitrary historic commit, wrong target packet, unreviewed/proposed attestation and forged PASS. A4 historical source-bearing and declared-Markdown gate regressions, UID regression and reviewed Grunt implementation coverage remain unchanged and green; no test ownership bypass. A5 demonstrated deterministic coordinator evidence hashes/reverification; no mutation of original run files or shared claim. A6 code/tests/attestation commit independently from archive-only closeout, then launch THIS packet's fresh paired review. A7 finish truthful documentation-drift report: prior packet scope omitted three exact .md and three exact source/data file entries; explain why attestation is later authorization, not proof of prior authorization.
- Validation: Focused `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` (or current correct test entrypoint), `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py`, new positive+negative read-only historical Grunt SIX-file scope replay, `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`, and `git diff --check`. All CI required gates must be green. Preserve the original run; no direct validation call against its files.
- Task overrides: `none`
- Deferred: After THIS correction's fresh independent review PASSES and lands, the human/agent holding `review-grunt-candidate-raster-workflow-v1` may run the exact existing `--recover-host-validation --plan` on the original `20261019T173219Z-d9252b20c85f` from synchronized clean main. An `--apply` is separately gated by plan digest, current preserved claim and coordinator authorization.
## Execution recipe
1. Resume the clean checkpointed claim/worktree at `d0e44dd8` after synchronizing this revised authority; do not create a replacement workstream or delete existing evidence. Inspect current main and source-scope code ownership. Baseline replay rejects three Markdown paths; accepted Markdown-only replay rejects exactly three additional source/data paths.
2. Amend the existing attestation JSON, exact-file verifier and focused regressions for six immutable entries. The Markdown allowlist must compare only the THREE attested Markdown entries; the documentation gate may accept the THREE source/data entries ONLY when the same verified attestation/independent PASS authority is present, and must not expand `_IMPLEMENTATION_SUFFIXES`, a directory matcher, or the unrelated file acceptance. Preserve original archive byte-for-byte.
3. Run focused tests, publish source/test/attestation in a committed implementation slice, then an archive-only closeout. Never co-commit code/test with archive metadata.
4. Independent reviewer of THIS packet must try forged, mutable and missing-approval cases. Do not resume the held Grunt review until accepted.

## Planning Refresh: Six-file historical scope (2026-10-19)

**Authorized refresh:** The original Grunt packet omitted six exact original-archive paths. The existing checkpoint `d0e44dd859d8fb497c9139dd418a9d3c019d377b` has already implemented and synthetically validated the three-Markdown portion, so **continue that same claim** rather than discarding it or creating another attestation authority.

The original immutable archive is `e29847bb2dc409ad994ac59ee3e8bb4db637142e`, and the archived target packet blob is `73dc311261f396b1636d117730fdffb18be9965e`. Supplemental authorization must match these SIX exact blob IDs and regular file modes, not just the filenames:

| Path | Git blob at e298 | Type |
|---|---|---|
| `custodian/docs/ai_context/CURRENT_STATE.md` | `1a9368fa1d293570c968fd486972d69f73a1a687` | historical documentation |
| `custodian/docs/ai_context/FILE_INDEX.md` | `4a7f88cc00689dd55ab080230e2c43b58cf6e0c5` | historical documentation |
| `custodian/tools/iteration/raster_pipeline/README.md` | `364f0b366c6c7f25d893ca3957c05238278c0fb7` | historical workflow README |
| `custodian/tools/iteration/raster_pipeline/__init__.py` | `bd5b6ae6d224c86909372b1710d51efe7c3a289a` | raster package initializer |
| `custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json` | `4e2ecb1b333c1d95d5b3b468dbcd9b7b7162a9ae` | exact Grunt raster plan |
| `custodian/tools/validation/validation_manifest.json` | `f99d1deec38aac1757838bd52bee102740597808` | focused validation ownership |

All six appear in the canonical original source-bearing archive. Nothing else is authorized. These exact files remain historical evidence and must NOT be edited just to pass host validation. This refresh itself authorizes editing only the CURRENT correction's already-declared tooling source/test and attestation JSON.

**Proof path:** Run the full e298 historical replay in a synthetic accepted-review history, not only the first rejection; assert the original Grunt source/test coverage, UID checks, archive provenance, and source file modes remain intact. Negative tests must demonstrate that a seventh unrelated `.py`, `.json`, or `.md` still fails. Full approval is unavailable until the correction's independent real PASS; do not bootstrap a pass from this amended packet.

**Preserve:** Held Grunt coordinator run `20261019T173219Z-d9252b20c85f`, claim `20261019T173233Z-d3f4bbc8869f`, reviewer worktree, visual review manifest, archived source and original review-packet bytes. No second Grunt review or claim.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f

## Handoff
- Next workstream: `review-agent-grunt-raster-review-scope-attestation-v1`
- Next action after passed review: read-only exact-run Grunt host-recovery plan.


## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The exact six-file attestation at `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json` is verified against original archive `e29847bb2dc409ad994ac59ee3e8bb4db637142e`; accepted independent review receipts are required before activation. Six-file historical replay, pre-approval rejection, altered blob/path/mode and seventh-file negatives, forged PASS and attestation-mutation negatives, coordinator provenance digest/reverification, UID and historical source-bearing regressions passed. `run_validation.py --changed --base origin/main --json` passed both selected groups; paired-review unit suite: 125 tests.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first changed-file validation timed out because the new negative fixture created a separate temporary Git worktree for each mutation.
- Root cause / contributing factors: Repeated worktree setup was unnecessary for sequential mutation cases.
- Prevention / pipeline improvement: Reuse one fixture checkout and reset between mutation variants; the negative test fell from about 20.5 seconds to 4.2 seconds and required validation passed.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Synthetic canonical PASS history exercised the real provenance gates without touching the held Grunt review.
