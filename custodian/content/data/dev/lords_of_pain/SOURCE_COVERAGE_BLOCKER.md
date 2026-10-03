# Lords of Pain source coverage preflight

- Hydrated archive: `archive/dev/LordsOfPain/LordsOfPain.zip` (539 PNGs).
- Archive scope: `(DEMO) Lords Of Pain - Old School Isometric Assets`.
- Required scope: both checked-in FULL indexes.
- FULL asset-index entries with no source-file match: 25 of 32.
- FULL animation states with no source frames: 30 of 34.
- Decision: fail closed. No gallery runtime, Asset V2 families, or registry entry was retained because that would present partial coverage as complete.

## Missing semantic asset entries

- Knight
- Fighter
- Subservient
- Demonlord
- Cursor Gauntlet x5
- Filter Vignette
- Bones x3
- Rocks
- Mushrooms
- Barrel + Break
- Wall x3
- Tiles
- Column x2
- Bricks
- Crate + Break
- Gemstones x4
- Brazier + Lit + Break
- Torch
- Zone
- Flame + Glow
- Flames + Glow
- Glow
- Swoosh
- Ground Variation x2
- Ground Darken

## Missing animation states

- `warrior_default_idle`
- `warrior_default_walk`
- `warrior_armed_attack`
- `warrior_special_select`
- `warrior_special_death`
- `knight_default_idle`
- `knight_default_walk`
- `knight_armed_idle`
- `knight_armed_walk`
- `knight_armed_attack`
- `knight_special_select`
- `knight_special_death`
- `fighter_default_idle`
- `fighter_default_walk`
- `fighter_armed_idle`
- `fighter_armed_walk`
- `fighter_armed_attack`
- `fighter_special_select`
- `fighter_special_death`
- `subservient_special_working`
- `subservient_special_worship`
- `skeleton_default_idle`
- `skeleton_default_attack`
- `demonlord_default_idle`
- `demonlord_default_walk`
- `demonlord_default_attack1`
- `demonlord_default_attack2`
- `demonlord_special_intro`
- `demonlord_special_laugh`
- `demonlord_special_death`

The full row-by-row source path, dimensions, frame-file count, and direction inventory is in `gallery_source_coverage.json`. The hydrated archive contains only its DEMO subset; provide the corresponding complete licensed source pack and rerun this preflight before implementation resumes.
