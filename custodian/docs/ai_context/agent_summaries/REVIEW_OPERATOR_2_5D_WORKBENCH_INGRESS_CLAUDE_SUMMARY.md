# WB25-2 Independent Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

Review verdict: findings — four confirmed blocking implementation defects. Correction cycle 1 is ready/auto. The implementation remains landed; this workstream changes only review receipts, packet lifecycle metadata, and the bounded correction/re-review pair.

- Reviewed implementation: bc469feb1e68ed16b915110d5a554403e600f006
- Reviewed main: 0d4612f52e064b48c2cf5a157a6c95aec4a553a8
- Reviewer context: fresh
- Reviewer provenance: same-agent-fresh-context
- Reconstruction: archived WB25-2 packet, implementation summary, WB25-1/R0-01 durable receipts, active migration/visual/Workbench authorities, landed diff, live code, implementation validation JSON, seven freshly rerun focused smokes, and disposable independent mutation probes. No implementation-session reasoning was carried into this reviewer context.

## Findings

### R0-01 — Handoff crash cannot resume a READY Source Session

- Class: blocking_defect
- Domain: implementation
- Affected acceptance: restart/resume is idempotent; verified Source Sessions/receipts are reused without repeated destructive conversion/handoff.
- Evidence: `custodian/tools/operator/operator_2_5d_ingress.py:213` accepts REVIEWED but rejects READY. `SourceArtService.handoff` persists READY before the package terminal receipt is written. After a real 15f/128px NE import, resetting only the package terminal state to SOURCE_STAGED models an interruption after the successful handoff. Resume reports `Source Session is in unsupported resumable state 'READY'` and changes the cell to BLOCKED, although its reviewed candidate, handoff and editable Workbench exist.
- Disposition: correction
- Rationale: a crash at a normal persistence boundary strands valid completed work. Resume must validate and reuse READY handoff proof and preserve Workbench edits without rerunning conversion.

### R0-02 — Completed package hints bypass current proof and Workbench existence

- Class: blocking_defect
- Domain: implementation
- Affected acceptance: changed source/session/profile/reference proof fails closed; a completed cell truthfully means an editable target Workbench exists; package truth derives from Source Session evidence.
- Evidence: `custodian/tools/operator/operator_2_5d_ingress.py:178` returns EDITABLE_WORKBENCH before `start_cell` or any Source Session/target/Workbench check. On the real completed fixture, appending bytes to its selected source still returns EDITABLE_WORKBENCH. Separately removing `workbench.aseprite` also returns EDITABLE_WORKBENCH with `document_exists: false`. `validate_package` likewise trusts only terminal strings.
- Disposition: correction
- Rationale: persisted orchestration state cannot override live source/session/authority and document proof. Validate current proof before reuse and package completion; preserve valid artist edits rather than comparing edited pixels to the original candidate.

### R0-03 — One blocked direction prevents all later package progress

- Class: blocking_defect
- Domain: implementation
- Affected acceptance: an eight-direction mixed-state package truthfully resumes completed/pending/blocked cells; each required cell reaches an editable Workbench or a durable BLOCKED reason.
- Evidence: `custodian/tools/operator/ui/service.py:551` processes directions in a dict comprehension that stops at the first exception. A disposable actual package already containing completed NE was passed through the service with first direction N returning a durable fixture failure. Only N was attempted; E/SE/S/SW/W/NW remained PENDING. A retry reattempts N first and cannot progress later directions while N remains blocked. The service then also unconditionally expects the selected cell to have a Workbench.
- Disposition: correction
- Rationale: this is the artist-facing eight-direction route. Handle each direction independently, retain blocked reasons, continue eligible pending cells, and report aggregate status without fabricating or opening a missing selected Workbench.

### R0-04 — OPUI NEW misses same-generation alternate-frame collisions

- Class: blocking_defect
- Domain: implementation
- Affected acceptance: same-generation canonical authoring/semantic/frame-contract collisions fail closed while legacy counterparts remain compatible.
- Evidence: `custodian/tools/operator/animation_workbench_model.py:115` appends `generations/operator_2_5d_128/animations` to the configured source root. OPUI's default `model.SOURCE_ROOT` already ends in `source/animations`, producing the nonexistent `source/animations/generations/...` scan path. With an existing same-generation 12f/128px NE source and a requested 15f target, the OPUI-shaped root produces READY; the same fixture with the correct source parent produces COLLISION. Exact 15f filename checks cannot detect the 12f semantic counterpart.
- Disposition: correction
- Rationale: the acceptance explicitly includes frame-contract semantic conflicts. Resolve the generation source scan from the canonical schema/source authority for both supported source-root shapes; cover the real default OPUI path.

## Evidence and limits

Fresh required tests: operator_2_5d_ingress, operator_asset_schema, operator_art_source, operator_art_registration_profile, operator_animation_workbench, Textual-enabled operator_workbench_ui, and direct operator_animation_targets_smoke.py all passed (7/7). The ingress integration used available Aseprite and a real 128px production conversion. Existing legacy-96 source/creation regression fixtures passed; the ingress fixture verified legacy source/runtime counterparts do not collide, Source Session v1 is backward-readable, stale profile/reference sessions fail, and 2.5D backend publication refuses before mutation.

Implementation reports `/tmp/wb25-2-changed-validation-final.json` and `/tmp/wb25-2-changed-validation-after-sync.json` each contain 29 passed checks and complete owned-path coverage. They establish the ordinary paths but omit these four regressions. The fresh focused aggregate is `/tmp/wb25-2-review-validation.json`; independent probe outputs are `/tmp/wb25-2-review-probes.json` and `/tmp/wb25-2-review-collision-probe.json`. Temporary fixtures were deleted automatically. The source files under review and production art/resources/selectors were never edited.

The graph was consulted first. It reported its build at 77a4df7 rather than reviewed HEAD; targeted live diff/source reads supplied the current code and new-ingress coverage. Its broad numeric risk/test-gap counts were not treated as acceptance evidence.

Moment Forge: not run — tooling/workflow review, no runtime presentation change. Visual review: none under the packet; no subjective approval was attempted. No optional polish findings or new human design choices were introduced.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Existing happy-path smokes passed despite four resume/collision acceptance failures; a repeated --test CLI option selected only the final test on the first review invocation; finish required the receipt Status value in its documented backtick syntax.
- Root cause / contributing factors: The ingress smoke verifies helper-level READY reuse rather than orchestrator interruption recovery, manually terminalizes pending package cells, and uses the source parent instead of OPUI's default animations root. The validation runner accepts one test filter; the finish receipt parser enforces the template formatting.
- Prevention / pipeline improvement: Correction acceptance explicitly requires the four independent regressions, including actual UI/default-root and persistence-boundary controls. Required focused tests were rerun with separate official invocations and aggregated unchanged test records; receipt formatting was corrected before landing.
- Tooling / docs drift discovered: none
- Follow-up: operator-2-5d-workbench-ingress-review-corrections-1
- What worked: Disposable real Source Session/Aseprite fixtures exposed persistence gaps without mutating production art.

## Next Handoff

- Next workstream: operator-2-5d-workbench-ingress-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the bounded correction for R0-01 through R0-04, validate and land it, then start the cycle-1 paired re-review in fresh context.
- Blockers or open questions: none for the correction; WB25-3 remains draft/refresh-required after successful re-review.

