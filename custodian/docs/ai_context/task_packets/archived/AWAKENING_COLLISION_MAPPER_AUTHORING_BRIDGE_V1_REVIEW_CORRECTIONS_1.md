# AWAKENING COLLISION MAPPER AUTHORING BRIDGE V1 REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-collision-mapper-authoring-bridge-v1-review-corrections-1`
- Authoring handoff: `auto`
- Kind: `correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-awakening-collision-mapper-authoring-bridge-v1`
- Locks: `awakening-runtime, authored-level`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-awakening-collision-mapper-authoring-bridge-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `the two recorded findings concern lossless authoring state and exact handoff evidence; independent proof must cover save/reopen and export behavior`
- Reviewed main: `3d835aea2f2a7ffc7d85931ad96a59639e9eac1f`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Close the original Awakening mapper findings by preserving source-art/snap metadata across draft reopen and providing exact clipboard plus annotated PNG/JSON handoff from the current draft.
- Completion boundary: Correct only the mapper draft serialization/readback and author export/capture seams identified by R0-01 and R0-02. Keep the workflow proposal-only and prove no production geometry or art changes.
- Current measured state: The original fresh review recorded R0-01 and R0-02 in `review-awakening-collision-mapper-authoring-bridge-v1`, closed as findings at `3d835aea2f2a7ffc7d85931ad96a59639e9eac1f`. Its reviewer-authored summary SHA-256 is `e981033fa07b7ae7b1fe5fdfa50389e90a7c6a87311aeba77ed12e8557e45db5`; original failed validation remains at run `20261016T095141Z-bf971dc50521`.
- Findings addressed: `R0-01, R0-02`
- Evidence: Archived parent implementation and review packets; original reviewer summary and findings closeout; `custodian/tools/level_authoring/mapper/awakening_first_return_collision_mapper.gd`; `custodian/tools/level_authoring/mapper/awakening_collision_mapper_bridge.gd`; `custodian/tools/validation/awakening_collision_mapper_bridge_smoke.gd`.
- Task-specific authority: The archived parent packet's draft-only A1–A9 contract and the archived findings review's exact R0-01/R0-02. AwakeningLayout, scene collision and production art remain authoritative and read-only.
- Work surface: `custodian/tools/level_authoring/mapper/awakening_first_return_collision_mapper.gd`; `custodian/tools/level_authoring/mapper/awakening_collision_mapper_bridge.gd`; narrowly scoped mapper UI/overlay export hooks if required; `custodian/tools/validation/awakening_collision_mapper_bridge_smoke.gd`; root closing summary.
- Publication inputs: `custodian/docs/ai_context/task_packets/archived/AWAKENING_COLLISION_MAPPER_AUTHORING_BRIDGE_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AWAKENING_COLLISION_MAPPER_AUTHORING_BRIDGE_V1.md`; `custodian/tools/level_authoring/mapper/awakening_first_return_collision_mapper.gd`; `custodian/tools/level_authoring/mapper/awakening_collision_mapper_bridge.gd`; `custodian/tools/validation/awakening_collision_mapper_bridge_smoke.gd`; `design/04_architecture/AUTHORED_MAPPER_EDITOR_RELIABILITY_V1.md`; `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`.
- Required correction: R0-01: serialize and restore the exact snap interval plus source-art resource, transform, and source-pixel coordinates, preserving stable proposal IDs and world vertices through real mapper save/reopen. R0-02: provide explicit copy-exact-vertices and annotated PNG/JSON capture operations over the current draft, with deterministic geometry/provenance in the JSON and faithful source-art/collision/proposal layers in the PNG.
- Preserve: Draft-only authority; exact source/layout/scene hashes; proposal ownership and stable IDs; production scene, `awakening_layout.gd`, runtime colliders, source art, routes, registered assets, and Asset Pipeline V2 bytes; original finding IDs/provenance and historical failed report.
- Non-goals: Drawing or approving new collision geometry; applying a draft to runtime; gameplay changes; new art assets; broad mapper redesign; changing Sundered Keep, Carrow, or generic mapper behavior.
- Acceptance:
  - A1: A real mapper save/reopen of fixtures with 1px and 4px snap restores identical snap, ordered world vertices, source-art resource/transform/pixel coordinates, proposal metadata, and stable IDs.
  - A2: Editing a saved draft then reopening does not recalculate or discard source-art provenance; malformed/unsupported draft input fails closed without changing the last valid draft.
  - A3: Copy Exact Vertices emits deterministic clipboard text for the selected proposal with stable ID, zone/owner, world-pixel coordinates, and source-pixel coordinates when available; absent clipboard support gives an actionable failure.
  - A4: Annotated capture writes one PNG and one JSON from the same immutable draft snapshot; JSON identifies exact source/layout/scene SHAs, snap, proposal identity/vertices and export paths; PNG uses the actual registered production artwork and overlays only authored draft geometry distinctly from source colliders.
  - A5: Repeated capture from unchanged inputs is deterministic; a changed source SHA is reported and never silently rebased; capture/export do not mutate runtime scene, layout, art, or draft bytes.
  - A6: Existing bridge and first-return geometry controls remain green, and negative controls cover missing source-art metadata, unsupported schema, stale base hashes, empty selection, invalid output path, and clipboard/capture failure.
- Validation: Extend `custodian/tools/validation/awakening_collision_mapper_bridge_smoke.gd` for actual save/reopen and capture behavior; run `awakening_first_return_smoke.gd`, `awakening_first_return_geometry_smoke.gd`, and the bridge suite through canonical validation. Then run changed-file validation from `origin/main`, packet/index/context checks, review pairing validation, and `git diff --check`.
- Task overrides: `none`
- Deferred: User-authored collision drafting, any subjective visual ergonomics decision, and production collision cutover remain separately gated.

## Handoff

- Next workstream: `review-awakening-collision-mapper-authoring-bridge-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `n/a`
- Refresh reason: `none`
- Next action: `After the correction lands, run its fresh-context paired review and re-evaluate whether the original root review can be legitimately superseded for mapper dependencies.`
- Blockers or open questions: `The original root review remains findings until a new accepted disposition is authorized; this correction pair does not relabel it as passed.`


## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Changed-file validation passed 39/39 tests; focused interactive capture and bridge smoke passed; review remains independently required.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The first changed-file sweep exposed a GDScript indentation parse error in the expanded real save/reopen fixture.`
- Root cause / contributing factors: `A loop expansion left one cleanup statement over-indented; canonical changed-file validation caught it before landing.`
- Prevention / pipeline improvement: `Keep the real mapper round-trip fixture inside changed-file validation; do not rely only on source import checks.`
- Tooling / docs drift discovered: `The bridge smoke instantiates production scenes and imported art, but its manifest entry had needs_import=false; changed to true.`
- Follow-up: `fixed-in-scope`
- What worked: `Focused canonical and Xvfb renderer checks covered exact export/capture behavior; changed-file validation rerun was fully green.`
