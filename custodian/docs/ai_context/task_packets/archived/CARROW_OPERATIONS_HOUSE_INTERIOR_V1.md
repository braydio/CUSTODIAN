# CARROW OPERATIONS HOUSE INTERIOR V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `carrow-operations-house-interior-v1`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-carrow-west-draft-house-interior-v1`
- Locks: `carrow-yard-route`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-carrow-operations-house-interior-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `larger interior and cross-room return state need independent visual/geometry review`
- Reviewed main: `06c8a7445b2da3bc206390e7b5a33340db031143`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Add distinct accessible 20×14 Operations House dispatch/control/records room to Carrow using the W1-accepted named-interior mechanism, while leaving Machine and West rooms and the municipal site identity unchanged.
- Completion boundary: Ops exterior `operations_house` 11×10 placed site opens a 640×448px (280 tile) civic-industrial room with functional north controls, west dispatch, east records/stock, open center and one safe three-cell south return; correct lighting/weather/camera and limited diegetic inspect/storage anchors, all via existing reusable Carrow room seam.
- Current measured state: At execution start, current main included the independently passed W1 named-room seam: East Machine House 14×10 and West Draft House 12×10. The generated `structure_sites["operations_house"]` remained an 11×10 `command_keep` anchor without an accessible interior. Original `CARROW_YARD.md` defines civilian dispatch, inventories and emergency response, not a fortress throne hall or faction command HQ. The separate `carrow-yard-route-authority-migration` remains gated and unchanged. See `design/05_levels/CARROW_YARD_STRUCTURES_EXPANSION_V1.md` for the exact 20×14 grid.
- Evidence: Proposed Carrow structures design; `gothic_compound_map.gd`, `gothic_compound_generator.gd` and `gothic_compound_asset_defs.gd`; W1 accepted new Carrow room seam; relevant `carrow_machine_house_{floor,walls,props}.asset.json` states; current Carrow lighting, weather and storage smokes.
- Task-specific authority: Approved named Carrow-room builder/registry from W1; exterior site metadata from generator; existing world environment/lighting, VaultStorage and Carrow door interactions. Do not create an Operations-only global travel system or implicitly launch pending `carrow-yard-route-authority-migration`.
- Work surface: New Operations House room definition, focused decoration/config and optional matching light profile under `custodian/content/lighting/profiles/`; minimal Carrow map wiring; focused Carrow environment/re-entry tests and validation manifest registration. No new world route, sprite PNG, asset family or NPC/quest behavior.
- Change:
  1. On accepted W1 authority, register `operations_house` from its real exterior site with safe southern entry and return, allocate non-overlapping off-map Rect2 and camera region. If W1 room API differs, adapt this content to its real accepted API rather than adding parallel state.
  2. Build the **exact 20×14 32px proposed grid** from `design/05_levels/CARROW_YARD_STRUCTURES_EXPANSION_V1.md`: 280 floor sprites, three-cell southern passable door, north control/record wall, west dispatch benches, eastern stock, west logistics strip and large clear central circulation. Use 64 registered Carrow floor variants sparingly, functional bays/desk/shelves from existing production families, low collision around furniture feet and tall wall silhouettes behind Operator where applicable.
  3. Preserve civic-industrial restraint: maintenance paperwork/route status/stock inventories, not political command, religious altar or tactical weapon armory. Limit to 1 bounded physical supply cache and up to 3 no-new-system inspection/control anchors; if no reusable inspect interaction exists, show as inert art instead of inventing a new UI/quest.
  4. Use dedicated but subtle profile (e.g. weaker daylight/0 rain, one amber practical glow and restrained blue-gray status panel) without bleeding into other rooms. Camera pans nowhere outside the Ops room; outdoor return restores exposure/weather.
  5. Validate visiting East → Ops → West → outside and reverse, including persistent depleted caches, return offset, same Operator, backdrop isolation, no reentrant room switch or conflicting room signals. All three site bindings must derive from exterior structure placement.
- Preserve: W1 accepted structure and its direct tests, original East 14×10 visual/collision/storage behavior, South Gate route/Transfer Frame, generator placement/seed/invariants and per-room separation; current source art and Asset V2 registrations.
- Non-goals: New Ops equipment/faction artwork, tactical NPCs, alarm logic, invented narrative decisions, Gatehouse/Gantry interior, runtime world route migration, expanding the 480-line map monolith without need.
- Acceptance:
  - A1. Named `operations_house` site is present; 20×14 grid, 640×448px, 280 floor sprites; south 3-cell passage and exterior doorway are aligned, physical return lands outside building.
  - A2. North controls/records, dispatch and inventory areas read as separate purposes; visible room furniture obeys collision and unblocked walkway; no generic duplicate chest.
  - A3. Environmental weather and light, camera, backdrop isolation, name-based region queries work for Ops, West, East, outside, and return with no time/weather reset.
  - A4. Missing Ops site/room definition/texture fails closed, cannot teleport out of bounds, leak weather, hide another room's interaction resources or duplicate visible equipment.
  - A5. Cross-room resources remain depleted after visit/re-entry where policy requires; Operator identity and main Carrow travel unchanged; fixed seed + variant seed generator validation green.
  - A6. No new asset family/batch, game alarm state, faction canon, or separate route manager; focused smokes and changed-file validation green.
- Validation: Focused new Ops room test under `custodian/tools/validation/` checking grid, passable 3-cell exit, 280 floor art, collision/backdrop/weather/camera, room-to-room transitions and same-runtime storage; existing W1, `carrow_yard_interior_smoke.gd`, `carrow_backdrop_isolation_smoke.gd`, generator/Carrow route smoke, then changed-file validation and `git diff --check`.
- Task overrides: `none`
- Deferred: Gatehouse annex and Alarm Gantry/Service Court remain design-only after Ops review; no 2026-10-14 proposed image states are considered required until visuals verify missing coverage.

## Next Handoff

- Next workstream: `review-carrow-operations-house-interior-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: After this implementation lands and archives complete, run the paired fresh-context Operations House review and verify its native-scale presentation and collider/doorway geometry.
- Blockers or open questions: `none; preserve pending world route migration ownership.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: n/a
- Evidence: `operations_house` now binds the generated 11×10 site to a 20×14/640×448 room with exactly 280 floor sprites, aligned three-cell south exit, non-overlapping camera/environment region, civic dispatch/records/stock presentation, one art-bound persistent spares cache, and existing-room state preserved. The focused smoke and complete changed-file report passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first smoke run used a fresh worktree before Godot initialized its global-class cache. After initialization, it found that the shared room-grid validator omitted the design's `K` dispatch symbol; a fixture also initially checked the wrong x-coordinate for the south exit.
- Root cause / contributing factors: The new room symbol vocabulary was not represented in the generic named-room allowlist, and the initial fixture's doorway coordinates did not match the accepted grid.
- Prevention / pipeline improvement: Add each accepted layout symbol to the common validator and derive test coordinates directly from the authored row; initialize project metadata before focused Godot validation in a fresh checkout.
- Tooling / docs drift discovered: `CURRENT_STATE.md` still described only the East Machine House after W1 had landed; it now records all three interiors. The new Carrow backdrop smoke is included in manifest owner coverage.
- Follow-up: review-carrow-operations-house-interior-v1
- What worked: The focused smoke covers the exact grid/collider mapping, clear aisle and door, multiple generated seeds, all three named rooms in forward/reverse order, same-Operator and camera/weather restoration, and same-runtime cache depletion.

## Validation Evidence

- `carrow_operations_house_interior`: PASS, 1/1; exact 20×14 grid, 280 floors, generated-site/door binding, collider-cell mapping, clear central aisle, fail-closed malformed/missing inputs, camera/weather/backdrop isolation, both traversal directions, and persistent cache depletion.
- `carrow_yard_interior`: PASS; existing East/West and route behavior preserved.
- `persistent_compound_layout`: PASS; fixed-seed and alternate-seed generator layout contracts.
- `carrow_backdrop_isolation_smoke.gd`: PASS; eight Carrow/room/procgen transitions.
- Changed-file validation: PASS, 39 selected / 39 passed / 0 failed / 0 timed out / 0 skipped; coverage complete. Report: `/tmp/carrow-operations-changed-final.json`.
- `git diff --check`: PASS.

## Independent Review

### Review Receipt: review-carrow-operations-house-interior-v1
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-carrow-operations-house-interior-v1`
- Review target workstream: `carrow-operations-house-interior-v1`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `fea61dc39c34e7a2d5bc50c8f5fd1a34e29713d1`
- Reviewed implementation commit: `fea61dc39c34e7a2d5bc50c8f5fd1a34e29713d1`
