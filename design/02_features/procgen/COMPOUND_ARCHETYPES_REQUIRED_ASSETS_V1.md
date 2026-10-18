# Compound Archetypes Sprint V1: Required Assets

**Status:** Demand manifest, not Asset V2 family registration or art approval.
**Baseline:** 512226d488d3b5db63335b2357b4b566e44ccb03
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
**Canonical required-assets authority:** custodian/content/metadata/assets/required_assets.registry.json

## Reuse first

Existing registered Carrow machine house floor/walls/props, interior 32px floors, gothic gates, current turret and Capacitor Bank are valid reference donors. Preserve their IDs and source provenance. Existing authored .tmj room-template deficits are tracked elsewhere in the canonical registry; no duplicate rows. Sprint geometry and security tests may use existing art and non-shipping debug primitives.

## Proposed Asset V2 families (all human-approval gated)

| Requirement | Proposed family and kind candidate | States | Pixels and frames | Target |
|---|---|---|---|---|
| compound-yard-perimeter-kit-v1 | compound_yard_perimeter_v1 (tile, verify supported kind/schema) | straight, corner, endcap, junction, threshold, breach | 32x32; 6 states; 1 frame omni | custodian/content/tiles/compound_yard/runtime/{state}_32.png |
| compound-secure-gate-kit-v1 | compound_secure_gate_v1 (world_prop, verify supported kind/schema) | closed, open, locked, breached | 160x128; 4 states; 1 frame omni RGBA | custodian/content/sprites/environment/structure/compound_security/runtime/compound_secure_gate_{state}.png |
| compound-bunker-tunnel-kit-v1 | compound_bunker_tunnel_v1 (tile, verify supported kind/schema) | floor, floor_worn, wall_straight, wall_corner, wall_end, threshold, conduit, warning_mark | 32x32; 8 states; 1 frame omni | custodian/content/tiles/compound_bunker/runtime/{state}_32.png |
| compound-security-fixtures-v1 | compound_security_fixtures_v1 (world_prop, verify supported kind/schema) | panel_idle, panel_denied, panel_granted, light_on, light_off, intrusion_indication | 64x64; 6 states; 1 frame omni RGBA | custodian/content/sprites/environment/structure/compound_security/runtime/compound_security_fixture_{state}.png |
| compound-bunker-surface-access-v1 | compound_bunker_surface_access_v1 (world_prop, verify supported kind/schema) | entry_closed, entry_open, entry_damaged | 192x160; 3 states; 1 frame omni RGBA | custodian/content/sprites/environment/structure/compound_bunker/runtime/compound_bunker_entry_{state}.png |

Verified family-kind availability (not fulfillment): `custodian/content/metadata/assets/schemas/tile.json` and `world_prop.json` define valid Asset V2 kinds. Exact target paths in the table are **proposed consumer destinations**; the generated Asset V2 router owns final runtime names, so do not hard-code these paths as fulfilled output. The five canonical requirements remain `manual/needed` pending real reviewed family registrations and asset-source intake. No art/asset authoring packet is justified before its human style/footprint approval.

## Intake contract

For EACH unregistered family, propose a schema custodian.asset_family.v2 contract at custodian/content/metadata/assets/families/<family_id>.asset.json with explicit state IDs, frame_width, frame_height, frames: 1, direction_policy: omni, and current kind/schema verified from Asset Pipeline V2 before commit. Stage source masters at custodian/asset_drop/source_work/compound_archetypes_v1/<family_id>/<state>_source.png; validated human-named normalized inputs at custodian/asset_drop/inbox/<family_id>/<state>.png. Do not create these files or claim asset approval yet. Use the actual asset.py plan / status / doctor / ingest and provenance hashes when source art is provided.

## Dependency and acceptance

No new PNG blocks profile/geometry/security/assault/repair/construction acceptance. Art can become required before final visual polish after user design lock. Validate 32px canonical pixel geometry, true alpha when appropriate, 100% zoom entrance readability, frame counts, exact mapping between visual door state and actual collision; register only approved states. No animations, directional sprites or camera feed assets requested now.
