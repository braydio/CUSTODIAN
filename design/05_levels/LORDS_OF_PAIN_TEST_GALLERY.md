# Lords of Pain Test Gallery

**Level ID:** `lords_of_pain_test_gallery`
**Region:** `dev`
**Status:** functional DEMO-pack blockout

## Intent

Provide an in-game gallery for the available Lords of Pain DEMO assets without promoting them to production art. The scoped manifest and task packet are authoritative for asset coverage: seven semantic entries, five animation entries, and explicit user-approved exclusions for Cursor Gauntlet, Rocks, and Mushrooms.

## Entry And Return

- Main entry: `Spawn_Main`
- Return anchor: `Return_Main`
- Ingress prompt: `ENTER LORDS OF PAIN GALLERY`
- Gallery return: interact with the District Transfer Frame at `return_world`.

## DEMO Gallery

- Stone Court: Ground Stone tiles with base/variant/darken tint comparisons.
- Hardstand: repeating runtime `meridian_hardened_floor` base art.
- Actor displays: Warrior armed idle/walk and Skeleton default walk/special death; arrow keys cycle state and all 16 directions.
- Pickup/VFX: E toggles the Gold Drop sample; Glint plays as a loop.
- UI lab: Highlight and Loot Indicator render as fixed screen-space samples.
- Entry and return use the normal registered `WorldIngressSite` and `InteractableLevelExit2D` route lifecycle. District Transfer Frame assets provide presentation only.
- A standalone playtest wrapper owns the Operator/controller/camera. The production scene does not.

## Authoring

- Production scene: `res://game/world/levels/authored/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery.tscn`
- Playtest scene: `res://game/world/levels/authored/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery_playtest.tscn`
- Collision/POI mapper: `res://game/world/levels/authored/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery_authoring.tscn`
