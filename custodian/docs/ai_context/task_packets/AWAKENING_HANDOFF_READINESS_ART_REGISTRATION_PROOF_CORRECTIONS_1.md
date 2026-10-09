# CORRECTION: Awakening Handoff Readiness Art Registration Proof — Review Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-handoff-readiness-art-registration-proof-corrections-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `awakening-handoff-readiness-art-convergence-v1-r1, review-awakening-handoff-readiness-art-convergence-v1`
- Locks: `awakening-runtime, awakening-art-registration`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, asset-pipeline`
- Paired review workstream: `review-awakening-handoff-readiness-art-registration-proof-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `3374efec219d`
- Parent implementation: `awakening-handoff-readiness-art-convergence-v1-r1` — `custodian/docs/ai_context/task_packets/archived/AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md`
- Parent review: `review-awakening-handoff-readiness-art-convergence-v1` — `custodian/docs/ai_context/task_packets/archived/REVIEW_AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md`
- Findings addressed: `R0-01`
- Affected acceptance: Parent review acceptance #1: prove live Layout-to-art registration and underlay/foreground parity for all zones, while preserving the reviewed 04→05 composition.
- Current defect/evidence: `awakening_art_registration_smoke.gd` checks seven standalone plates and the shared 04→05 composition, but hard-codes expected dimensions/centers and does not derive the standalone art rectangles from `AwakeningLayout.ZONES`. The broader smoke hard-codes separate 04/05 1502×2048 zone textures, though those legacy nodes are hidden; the active approved presentation is the shared three-layer composition at `(349,-2585)`. Zone04 foreground is intentionally unbound. The committed composition report proves hashes, alpha overlap, shared transform, and floor samples, but does not state the seven standalone `grow(64)` registrations plus explicit 04/05 exception as one complete contract.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a`
- Goal: Close the parent review's material registration-proof gap with a deterministic contract that distinguishes ordinary Layout-registered room plates from the approved source-preserving 04→05 shared composition.
- Completion boundary: Done when validation derives the seven ordinary plate rectangles from live Layout envelopes, proves exact 64px expansion and underlay/foreground parity, and machine-checks 04/05's explicit composition exception and intentional foreground deferral without changing runtime art or transforms.
- Current measured state: Seven ordinary zones use expected envelope+64 canvases and registered centers. Zones04/05 retain hidden legacy room nodes while the accepted visible art is the shared 1502×2048 Dust→Connector→Locker composition at root `(349,-2585)`, scale 1, rotation 0. Existing focused checks pass; proof is split across unrelated assertions and duplicated constants.
- Evidence: Parent review finding `R0-01`; `custodian/tools/validation/awakening_art_registration_smoke.gd`; `custodian/tools/validation/awakening_first_return_smoke.gd`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/docs/ai_context/reports/assets/awakening_04_05_registered_composition_v1.json`; prior human lock in archived `AWAKENING_04_05_REGISTERED_COMPOSITION_FADE_REPAIR_V1.md`.
- Task-specific authority: `design/04_architecture/AWAKENING_FIRST_RETURN.md`; `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`; the archived parent implementation packet and `R0-01` review receipt.
- Work surface: `custodian/tools/validation/awakening_art_registration_smoke.gd`, `custodian/tools/validation/validation_manifest.json` only if ownership changes, and the narrow Awakening registration section of `custodian/docs/ai_context/VALIDATION_RECIPES.md` if the proved contract or command changes. No runtime, art, Layout, collision, or progression files.
- Required correction: Derive each ordinary plate's expected rectangle as its live Layout envelope grown by 64 pixels, then compare texture bounds/center, scale, rotation, and underlay/foreground canvas and registration. For Zones04/05 explicitly assert the shared accepted composition's root transform, 1502×2048 child canvases, z-order, source family identities/hashes, and complete connector silhouette; assert legacy zone plates remain hidden and Locker foreground remains intentionally unbound. Make any 04/05 exception explicit in validation output and the active recipe. Do not resize or reauthor assets to satisfy the generic grow64 formula.
- Preserve: The human-locked 04→05 source composition and order; exact Layout authority; 05→06 passage; all collision, route, gameplay and Asset V2 ownership; no scene transition or Contract prewarm.
- Non-goals: No art-direction review, new capture sequence, art/source/runtime asset changes, Layout redesign, resizing, foreground invention, or gameplay modification.
- Acceptance: (1) Every non-composite zone 01–03 and 06–09 derives its exact grow64 art rectangle from live Layout and proves underlay/foreground parity. (2) Zones04/05 prove the reviewed shared composition exception from live scene and source-report truth, with hidden legacy art and deferred Locker foreground asserted. (3) A deliberate Layout envelope, sprite transform, foreground size, composition child, or source-state mutation fails the focused test. (4) Existing Awakening registration, composition traversal, geometry, and progression checks pass; no production/runtime authority changes.
- Validation: Run `awakening_art_registration`, `awakening_first_return`, `awakening_registered_composition_traversal`, `awakening_first_return_geometry`, `awakening_first_return_progression`, `awakening_connector_asset_contract`, and `git diff --check`; then changed-file validation.
- Task overrides: `none`
- Deferred: Any new Gate art/composition or subjective art review remains human-owned and outside this correction.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success | partial | blocked
- Friction severity: none | low | medium | high
- What went wrong: none | ...
- Root cause / contributing factors: none | ...
- Prevention / pipeline improvement: none | ...
- Tooling / docs drift discovered: none | ...
- Follow-up: none | fixed-in-scope | <workstream-id> | manual-follow-up
- What worked: optional
