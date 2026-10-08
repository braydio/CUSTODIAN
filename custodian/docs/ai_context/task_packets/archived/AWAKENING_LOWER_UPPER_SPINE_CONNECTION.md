# AWAKENING LOWER→UPPER SPINE CONNECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-lower-upper-spine-connection`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-awakening-04-05-registered-composition-correction-v1`
- Locks: `awakening-runtime, awakening-art-registration, awakening-05-06-spine`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-awakening-lower-upper-spine-connection`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `b3352e0860930861efc8dda839a3e078321585c6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Make the lower Awakening and the later/upper Awakening read and behave as one continuous authored route by turning the Dust Lung→Undergate seam into one explicit 05→06 passage authority and proving uninterrupted real-Operator traversal from Zone05 into Zones06–10 without loading, teleporting, invisible floor gaps, or presentation occlusion.
- Completion boundary: Done when the current split 05→06 route primitives are represented as one semantic passage, the exact existing walkable union remains continuous, the 96px Dust/Undergate art overlap covers that passage without a transparent/opaque break, collision cannot seal it, and a real Operator can walk from Dust Lung through Undergate and continue through Gate of Dust, Custodian Approach, and Road South Reach in one scene.
- Current measured state: `AwakeningLayout.PASSAGES["lower_upper_spine_05_06"]` is the only 05→06 route authority and equals `Rect2(-64,-3840,128,96)`, preserving the exact union of the retired connector and south-door threshold. It is included exactly once in `traversal_rects()` and therefore in runtime wall carving and walkability. Source-pixel inspection and 12 centerline samples found both Dust Lung and Undergate underlays opaque across the passage, with no opaque foreground centerline; runtime holds both room layers at full alpha through the passage neighborhood. A live Operator moved from south of the daylight split through Zones05, 06, 07, 08, and 10 to South Reach in 1,153 physics samples, including 38 samples inside the passage. No teleport, reload, or optional Zone09 entry occurred.
- Evidence: `custodian/game/world/awakening/awakening_layout.gd`; `custodian/scenes/awakening_first_return.tscn`; `awakening_first_return_geometry_smoke.gd`; `awakening_late_seams_v1.json`; `awakening_late_seams_moment.gd`; current Zone05/Zone06 plate centers/canvases.
- Task-specific authority: `awakening_layout.gd` for route geometry; live scene art registration for the 96px visual overlap; real Operator collision/clearance for traversability; no new art authority.
- Work surface: `awakening_layout.gd`; `awakening_first_return.gd` only if visibility/zone presentation actually breaks the seam; scene only if z/alpha registration requires correction; focused geometry/progression/late-seam validation and docs.
- Change:
  1. Consolidate the semantic 05→06 passage around the exact current union `Rect2(-64,-3840,128,96)`. Prefer one named authority such as `05_06`/lower-upper passage rather than a 32px connector plus a separately named 64px doorway. Preserve the exact current union unless real Operator-clearance evidence proves it is insufficient.
  2. Keep Zone05 exit `(0,-3744)`, Zone06 entry `(0,-3776)`, both envelopes, and all later zone anchors fixed. No moving the upper half to hide the join.
  3. Ensure connector/threshold carving and wall generation cannot leave a 32px seam, blocker sliver, or duplicated boundary rail inside the 128×96 passage.
  4. Treat the Dust/Undergate 96px underlay overlap as the intended visual bridge. While traversing the passage, at least one correct room underlay covers every walkable sample, neither foreground may opaque-mask the Operator centerline, and room alpha must not simultaneously fade below full readable coverage.
  5. Do not create new image art for this seam. If the two registered room plates cannot cover their own measured 96px overlap without a genuine source-art hole, stop with a precise visual-art gap instead of painting/generated patch pixels.
  6. Add a real-Operator traversal proof from a Dust Lung interior sample south of the daylight split through the passage into Undergate, then continue through the existing mandatory route to Gate of Dust, Custodian Approach, and South Reach. The proof must use ordinary movement/collision, not teleporting between test points.
  7. Keep optional Late Service a branch only. The mandatory lower→upper route must not depend on entering Zone09.
  8. Update geometry/progression/late-seam fixtures so the same one-passage authority is used by runtime and tests. Remove duplicate numeric seam constants where the live Layout can be queried.
  9. Update active design/current-state/index docs to describe one continuous lower→upper spine and the exact 128×96 05→06 passage.
- Preserve: all Zone05–10 room anchors/envelopes; exact Dust Lung/Undergate room plates; Gate/Approach/Road geometry; P-9/console progression; optional Zone09 semantics; no scene loads between Awakening sections.
- Non-goals: No 04→05 connector art changes; no new environment art; no Hub transition; no South Reach completion API redesign; no Gate of Dust redesign.
- Acceptance:
  - One semantic 05→06 passage authority covers exactly the current `128×96` union unless an evidence-backed clearance correction is explicitly required.
  - A real Operator can walk Dust Lung → 05→06 passage → Undergate → Gate of Dust → Custodian Approach → Road South Reach continuously with no teleport or scene reload.
  - Collision/rails/set pieces leave the full critical passage usable at live Operator clearance.
  - The 96px Dust/Undergate visual overlap covers the walkable passage with no transparent void stripe, doubled threshold, or opaque foreground barrier.
  - Late Service remains optional and cannot become a mandatory bridge.
  - Existing geometry/progression and late-seam tests use Layout authority and remain green.
- Validation: Run Awakening geometry/progression smokes; add/update a focused 05→06 real-Operator traversal smoke; run `awakening_late_seams_v1` in no-capture mode; use compact 05→06 ROI only if pixel coverage cannot be settled structurally; changed-file validation and `git diff --check`.
- Task overrides: `none`
- Deferred: full Awakening art/handoff convergence and actual Awakening→Hub world-context transition remain downstream. The reviewed interaction-feedback/console-activation predecessor is presentation authority and must not regress while proving the spine.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: Geometry, first-return boot, progression, and live real-Operator traversal smokes passed. Changed-file validation passed all 22 selected checks with complete implementation coverage. `awakening_late_seams_v1` passed with `--capture-mode none`; `git diff --check` passed.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first new geometry run exposed an overstrict clearance assertion sampling the 16px erosion boundary; the assertion was narrowed to the actual eroded interior core. A fresh checkout required Godot import initialization before runtime checks.
- Root cause / contributing factors: The fixture's safe-grid proof erodes occupancy by one full cell to model Operator clearance; samples on the authored passage boundary are outside that safe core. New worktrees also start without Godot's generated import cache.
- Prevention / pipeline improvement: Keep clearance assertions aligned with the grid erosion model and initialize project imports before runtime smokes in fresh worktrees.
- Tooling / docs drift discovered: The late-seams fixture duplicated the 05→06 checkpoint coordinate; it now derives that position from Layout passage authority.
- Follow-up: none
- What worked: Pixel-alpha sampling and continuous physics-driven traversal established the visual and collision contracts without renderer capture.

## Independent Review Receipt

- Status: `passed`
- Review workstream: `review-awakening-lower-upper-spine-connection`
- Reviewed on main: `590c7293fa9dc29ebdfe55be03d5c172d43ac9c9`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_AWAKENING_LOWER_UPPER_SPINE_CONNECTION_CLAUDE_SUMMARY.md`
- Reviewer independence: `A fresh reviewer reconstructed the target from the archived implementation packet, implementation summary, active design, landed diff, and live runtime evidence. The reviewed implementation was not modified.`
- Focused validation: `awakening_first_return_geometry_smoke`, `awakening_first_return_smoke`, `awakening_first_return_progression_smoke`, and `awakening_lower_upper_spine_traversal_smoke` passed. The traversal used 1,153 physics samples, including 38 within the passage, and visited Zones05/06/07/08/10 without Zone09. `awakening_late_seams_v1` passed with `--capture-mode none`; `git diff --check` passed.
