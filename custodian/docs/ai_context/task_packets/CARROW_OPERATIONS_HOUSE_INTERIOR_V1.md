# CARROW OPERATIONS HOUSE INTERIOR V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `carrow-operations-house-interior-v1`
- Authoring handoff: `auto`
- Status: `draft`
- Dispatch: `manual`
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
- Current measured state: Only East is currently produced by pre-W1 main. W1 defines new `active_interior_id` and room registration and must land/pass review before this packet starts. Generator site `structure_sites["operations_house"]` uses `command_keep` asset 11×10. Original `CARROW_YARD.md` expressly defines civilian dispatch, inventories and emergency response, not a fortress throne hall or faction command HQ. See `design/05_levels/CARROW_YARD_STRUCTURES_EXPANSION_V1.md` for exact 20×14 symbol grid.
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
- Next action: Fresh-context Ops interior acceptance review with cross-room restoration regression.
- Blockers or open questions: `Blocked on genuine accepted West Draft review; preserve pending world route migration ownership.`
