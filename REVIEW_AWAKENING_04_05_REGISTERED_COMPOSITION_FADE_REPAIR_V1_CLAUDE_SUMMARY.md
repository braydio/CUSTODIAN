# Awakening 04→05 Registered Composition Fade Repair V1 — Independent Review

## Findings

**R0-01 — stale repair/review prose (non-blocking).** `design/04_architecture/AWAKENING_FIRST_RETURN.md:144` still describes the shared parent as the current fade target and calls the repair pending through line 155. `custodian/docs/ai_context/CURRENT_STATE.md:2190` still says the registered-composition correction is pending paired review, immediately before correctly describing the completed fade repair.

- Class: non_blocking_issue
- Domain: implementation
- Affected contract: archived implementation Change item 12 (reconcile active fade/review truth); Acceptance 7 evidence discoverability and the repository documentation handoff contract.
- Evidence: source text above versus landed `aaa1236840884332b2759e029bb829bfa519fa97`, archived completed correction review, live cached child fade targets, and the fresh validation below.
- Disposition: next_slice — `awakening-handoff-readiness-art-convergence-v1-r1`.
- Rationale: Runtime/asset/visual acceptance is proven independently and the current-state repair paragraph is accurate. The immediate successor explicitly owns reconciliation of stale Awakening documentation in its Goal, Completion boundary, and Documentation Drift scope. This prose does not warrant a runtime correction cycle or human escalation. The reviewer did not edit design/runtime files.

## Verdict and provenance

Technical review passes with one non-blocking documentation issue: zero blocking defects, zero material evidence gaps, zero unresolved human decisions. Receipt status is `findings`; no correction packet is required. Reviewed target: `aaa1236840884332b2759e029bb829bfa519fa97` on main. Reviewer context: `fresh`; reviewer provenance: `different-agent` — a separately spawned Codex reviewer rebuilt context from durable repository evidence. The reviewer is the same model family; no distinct model-family claim is made.

The code changes only cached fade target ownership: Locker follows Zone04, Dust follows Zone05 plus the existing lower→upper hold, Connector follows the merged A/B/C envelope, and the common parent is untouched. Static inspection confirms the stationary early-out and thresholded writes remain intact, with no new update-time discovery, image reads, resource loads, or telemetry emission. Exact target diff contains no scene, Layout, registered PNG/source, collision, camera, lighting, or gameplay edits.

## Validation and visual evidence

Six fresh focused `run_validation.py --test <id> --json` runs pass: `awakening_first_return`, `awakening_first_return_progression`, `awakening_registered_composition_traversal`, `awakening_connector_asset_contract`, `awakening_registered_composition_render`, and `awakening_lower_upper_spine_traversal`. Registered traversal passes 1,025 samples. Lower→upper traversal passes 1,153 movement samples and 38 passage samples into Zones05–08 and Road South Reach. The repaired scene smoke observes the live Dust sprite for passage coverage and proves the visible parent remains at alpha 1 while distant children fade independently. P-9 progression proves stable Locker room art through closed, authorization/opening, open_loaded, and empty.

Asset checks preserve the 1502×2048 canvas, root `(349,-2585)`, native scale, zero rotation, Dust→Connector→Locker order, 17,979/10,979 overlap counts, and source hashes:

- Dust: `fa8637992bfc0b1ff1b0d009fbe463e098a4adbfe97031c67d2276d2fe94172e`
- Connector: `489b49615ba53b0073519d5a261f736321ba69b95019bb54ec02ff408a9ffd76`
- Locker: `76cc103eda059974f8f279e8e4e10fdb1b388030ea26f2a7b659075c45ceb48d`

Fresh Moment Forge `traversal/awakening_late_seams_v1 --capture-mode none` passes all 68 assertions at `reports/moment_forge/traversal/awakening_late_seams_v1/20261009T105422-0400`. Stable fingerprint: `5fb0e6779a0f65dd0ce433b6332309e070b2622ddab65ad6a6e4ea846cbcc4fd`. Its actual parent/child effective-alpha and bounds probes establish the forward/reverse correspondence; evidence does not depend on the Observatory event tail.

The supplied manifest is `/CUSTODIAN/visual_review/awakening-04-05-registered-composition-fade-repair-v1/20261009T135021Z/REVIEW_MANIFEST.json`. The reviewer consumed its existing compact five-ROI sheet rather than regenerating equivalent views. Sheet SHA-256 is exactly `b1f0356e814d67c19aec6fc1d60ffb5f94b77dc3169e1da7995f8314663ae36f`; all five supplied matte/void checks pass with `void_ratio=0`. Visual inspection shows the locked registered floor composition still present at the two room interiors and A/B/C, consistent with fresh live probes and unchanged art/registration. The manifest was generated before the final commit, so its Git field alone is not accepted as target provenance; exact immutable-surface diff/hash checks and the fresh none-mode/runtime reruns establish correspondence with the landed target.

The already recorded human visual lock remains valid. No ambiguous capture or contradiction with that lock was found, and no second human approval is required.

- Review-evidence cleanup: the exact manifest-emitted command completed with `status=deleted`, `retention_policy=delete-after-review`, and `latest_pointer_removed=true`. `reviewed_by=chatgpt-user` is the emitted cleanup identity reflecting the prior recorded human lock and current delegated review authorization; technical review was performed by the fresh Codex reviewer above. The manifest path is a historical receipt after deletion, not a live download location.
- Final review-artifact `run_validation.py --changed --json`: 2 selected, 2 passed (`review_pairing_contract`, `visual_review_handoff`), complete changed-file coverage. `git diff --check` passes. Finish report: `/tmp/awakening-fade-review-closeout.json`. Targeted authoring preflight rejects archived packet paths by design, so lifecycle pairing/index validation is the applicable closeout check rather than a new packet-promotion preflight.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Artifact lookup initially omitted the remote artifacts subdirectory; a fresh Godot import created nine unrelated reference-art .import sidecars. Finish encountered a conflict only in the generated README queue block after concurrent living-world review changes landed.
- Root cause / contributing factors: Manifest records names/source paths without explicit remote child paths; fresh imports scan reference assets.
- Prevention / pipeline improvement: Resolve the artifacts subdirectory first and remove only classified generated sidecars before finish. Regenerate the managed index from the merged packet tree to preserve both lanes; validate the result after sync rather than resolving generated rows by hand.
- Tooling / docs drift discovered: R0-01 as above.
- Follow-up: awakening-handoff-readiness-art-convergence-v1-r1
- What worked: Compact existing visual evidence plus fresh state/traversal checks gave independent proof without repeated full-frame capture.

## Next Handoff
- Next workstream: awakening-handoff-readiness-art-convergence-v1-r1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Re-check dispatcher after review archive/landing, claim the existing art-convergence successor, and reconcile R0-01 in its explicit documentation scope.
- Blockers or open questions: none for this review. Preserve the successor's separate acceptance/visual contract.
