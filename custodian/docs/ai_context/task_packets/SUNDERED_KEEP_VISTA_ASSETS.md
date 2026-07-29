# SUNDERED_KEEP_VISTA_ASSETS

- Status: `in_progress`
- Authority: `design/02_features/` (Sundered Keep approach design specs)
- Goal: Create all required assets for Sundered Keep Vista reveal and lock biome/profile to prevent Forlorn Ritualant contamination
- Files: See Asset Manifest below
- Constraints: Assets must follow `custodian/content/` paths, not legacy `custodian/assets/sprites/`; vista must never render Forlorn Ritualant/Ash-Bell content
- Acceptance: All 16 assets created, profile/lock JSONs in place, approach scene uses locked biome
- Completed: Documentation drift remediation (animation path references); Asset 2 First Reveal Light Sweep runtime sheet and editable six-frame Aseprite source
- Deferred: None

## Core Problem

The vista reveal is rendering over the wrong authored/world context. The Forlorn Ritualant/Ash-Bell system has its own authored-scene authority reservation (canonical `35x27` room footprint and procgen-authority clearing), but future generic special-room insertion still needs to call that API.

**Solution:**
- Sundered Keep vista = authored exterior approach profile
- Forlorn Ritualant = underground/special-room authored scene
- Never render both in the same visual layer/context

## Full Packet Expansion

### Ownership And Timing

- Owner: User (asset creation) + Agent (implementation)
- Agent/session: Current session
- Created: 2026-07-28
- Last updated: 2026-07-28

### Work Surface

- Read: `custodian/content/backgrounds/sundered_keep/`, `custodian/content/procgen/world_profiles/`, `custodian/content/world/regions/`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Change: Create assets, JSON profiles, and region lock metadata
- Out of scope: Forlorn Ritualant underground relocation (separate task)

### Plan

1. Create required reveal assets (7 assets)
2. Create optional enhancement assets (4 assets)
3. Create biome/profile lock data (2 JSON files)
4. Create Forlorn Ritualant underground assets (3 assets)
5. Wire assets into SunderedKeepApproach and VistaController

### Drift Review

- Primary authority: `design/02_features/` (active implementation specs)
- `CURRENT_STATE.md`: Updated to reflect correct `custodian/content/` paths
- `CONTEXT.md`: No changes needed
- `FILE_INDEX.md`: No changes needed
- Local routing/readmes: Updated `ASSET_LAYOUT_CONVENTION.md` to clarify paths

### Handoff

- Next action: Create Asset 1 (First Reveal Fog Rollaway Veil), then wire the completed Asset 2 moonlight sweep during the reveal cue
- Best starting files: `custodian/content/backgrounds/sundered_keep/approach/fog/`
- Validation to run: `python custodian/tools/validation/content_asset_audit.py --limit 20`
- Blockers or open questions: None

---

## ASSET MANIFEST

### A. Required Reveal Assets (Priority 1)

#### 1. First Reveal Fog Rollaway Veil
**Purpose:** Main "camera snaps upward and the fog peels away" asset

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/approach/fog/first_vista_fog_rollaway_01__8f__1024x512.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/approach/fog/first_vista_fog_rollaway_01.aseprite` |
| **Frame Size** | 1024x512 |
| **Frame Count** | 8 |
| **Sheet Size** | 8192x512 |
| **Playback** | 18–24 fps, non-looping |
| **Blend** | Alpha blend / screen-ish (shader-controlled) |
| **Anchor** | First reveal camera center / route threshold |

**Frame Intent:**
1. Dense fog curtain still covering the keep silhouette
2. Fog begins splitting from centerline
3. Fast lateral/downward rollaway, strongest directional motion
4. Keep silhouette begins reading through center
5. Fog pulled toward edges; central path opens
6. Mid fog trails remain
7. Edge wisps and low haze remain
8. Settled fog band, not totally clear

**Important:** Should NOT erase all atmosphere. Should clear the center read while leaving edge depth.

---

#### 2. First Reveal Light Sweep
**Purpose:** "Cool moonlight catches the stone" cue

**Status:** Complete — generated and validated 2026-07-28.

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/approach/light/first_vista_moonlight_sweep_01__6f__1024x512.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/approach/light/first_vista_moonlight_sweep_01.aseprite` |
| **Frame Size** | 1024x512 |
| **Frame Count** | 6 |
| **Sheet Size** | 6144x512 |
| **Playback** | 12–18 fps, non-looping |
| **Blend** | Additive or screen, very low opacity |
| **Anchor** | Same as first vista reveal plane |

**Frame Intent:**
1. Almost invisible
2. Thin cold rim light catches cliff/stone top edges
3. Brightest moonlit reveal accent
4. Light sweeps across keep silhouette
5. Fades back into ambient storm light
6. Settled, nearly gone

**Note:** Should be subtle. Think "exposure lift," not explosion.

---

#### 3. First Reveal Edge Mist Wrap
**Purpose:** Hides rectangle seams, makes route feel suspended in fog

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/approach/fog/first_vista_edge_mist_wrap_01.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/approach/fog/first_vista_edge_mist_wrap_01.aseprite` |
| **Size** | 2048x768 |
| **Frame Count** | 1 static plate |
| **Usage** | Persistent foreground/edge fog mask around route and lower screen |

**Priority:** High - this is one of the highest-value assets because screenshots show hard compositing seams.

---

#### 4. Grand Vista Labyrinth Distance Plate A
**Purpose:** First "large labyrinthine keep fading into distance" layer

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/grand_vista/landmarks/grand_vista_labyrinth_far_01.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/grand_vista/landmarks/grand_vista_labyrinth_far_01.aseprite` |
| **Size** | 2048x1024 |
| **Frame Count** | 1 |
| **Depth** | Far background |
| **Alpha** | 35–55% |
| **Color** | Dark blue-gray, low detail, low contrast |

**Purpose:** Make the keep feel bigger than the playable platform.

---

#### 5. Grand Vista Labyrinth Distance Plate B
**Purpose:** Second, deeper keep layer

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/grand_vista/landmarks/grand_vista_labyrinth_far_02.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/grand_vista/landmarks/grand_vista_labyrinth_far_02.aseprite` |
| **Size** | 2048x1024 |
| **Frame Count** | 1 |
| **Depth** | Farther than plate A |
| **Alpha** | 18–35% |
| **Color** | Nearly silhouette, fog-eaten |

**Purpose:** Layered distance. Sells "city-sized ruined keep," not just one wall plate.

---

#### 6. Grand Vista Seam Fog / Tile Breakup Mask
**Purpose:** Hides visible hard tiles/rectangular edges

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_rect_seam_fog_mask_01.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_rect_seam_fog_mask_01.aseprite` |
| **Size** | 2560x1440 |
| **Frame Count** | 1 |
| **Usage** | Full-screen-ish alpha fog mask, placed above distant plates and below player route |

**Note:** Boring but extremely important. Third screenshot has cool scale, but rectangular seams kill the illusion.

---

#### 7. Enter Prompt Plate
**Purpose:** Clean, intentional prompt after reveal settles

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/ui/world/sundered_keep_enter_prompt_01.png` |
| **Source Path** | `custodian/content/ui/world/source/sundered_keep_enter_prompt_01.aseprite` |
| **Size** | 384x72 |
| **Frame Count** | 1 |
| **Text** | ENTER SUNDERED KEEP > |
| **Usage** | Shown only after reveal settles |

**Optional Animated Version:**
- Runtime: `custodian/content/ui/world/sundered_keep_enter_prompt_01__4f__384x72.png`
- 4 frames, 384x72 each, 1536x72 sheet
- Subtle pulse / cyan threshold shimmer

---

### B. Optional But Strong Assets

#### 8. Storm Parallax Sky Correction Plate
**Purpose:** Fix obviously pasted/repeated sky

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_storm_sky_deep_01.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_storm_sky_deep_01.aseprite` |
| **Size** | 2560x1440 |
| **Frame Count** | 1 |

---

#### 9. Moon Occlusion Halo
**Purpose:** Let moon silhouette the keep without flattening the image

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_moon_occlusion_halo_01.png` |
| **Source Path** | `custodian/content/_aseprite/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_moon_occlusion_halo_01.aseprite` |
| **Size** | 1024x1024 |
| **Frame Count** | 1 |
| **Blend** | Screen/additive, low opacity |

---

#### 10. Keep Window Ember Specks
**Purpose:** Subtle orange points in distant keep (helps scale)

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/sprites/vfx/world/sundered_keep/sundered_keep_window_embers_01__8f__512x256.png` |
| **Source Path** | `custodian/content/sprites/vfx/world/sundered_keep/source/sundered_keep_window_embers_01.aseprite` |
| **Frame Size** | 512x256 |
| **Frame Count** | 8 |
| **Sheet Size** | 4096x256 |
| **Playback** | 6–10 fps, looping subtle |

---

#### 11. Wind Rain Streak Overlay
**Purpose:** Atmospheric rain (only if subtle)

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/sprites/vfx/world/sundered_keep/sundered_keep_wind_rain_streaks_01__12f__1024x512.png` |
| **Source Path** | `custodian/content/sprites/vfx/world/sundered_keep/source/sundered_keep_wind_rain_streaks_01.aseprite` |
| **Frame Size** | 1024x512 |
| **Frame Count** | 12 |
| **Sheet Size** | 12288x512 |
| **Playback** | 12 fps looping |

**Note:** Too much rain will make the vista noisy.

---

### C. Biome / World-Profile Lock Assets & Data

#### 12. Vista Approach World Profile
**Purpose:** Separate profile so authored approach identifies itself as Sundered Keep exterior threshold

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/procgen/world_profiles/sundered_keep_vista_approach.json` |

**Content:**
```json
{
  "id": "sundered_keep_vista_approach",
  "origin_cell": [0, 0],
  "blend_width_tiles": 16,
  "bands": [
    {
      "id": "vista_threshold",
      "distance_min": 0,
      "distance_max": 99999,
      "height_bias": 9,
      "ascent_gain": 9,
      "style_weights": {
        "wind_cut_stair": 0.25,
        "ridge_trail": 0.20,
        "collapsed_keep_exterior": 0.35,
        "ruined_observatory": 0.20
      },
      "faction_presence": {
        "iconoclast": 0.20,
        "cult_mechanist": 0.35,
        "scavenger": 0.10
      },
      "story_room_chance": 0.0
    }
  ]
}
```

**Why `story_room_chance: 0.0`:** Vista should not spawn Ash-Bell / Forlorn Ritualant / random story content in this presentation context.

---

#### 13. Vista Approach Biome Lock Metadata
**Purpose:** Clean "don't put the ritual scene under the vista" contract

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/world/regions/sundered_keep/vista_approach_region_lock.json` |

**Content:**
```json
{
  "region_id": "sundered_keep_vista_approach",
  "region_kind": "authored_vista_approach",
  "world_profile": "res://content/procgen/world_profiles/sundered_keep_vista_approach.json",
  "locked_band": "vista_threshold",
  "allowed_styles": [
    "wind_cut_stair",
    "ridge_trail",
    "collapsed_keep_exterior",
    "ruined_observatory"
  ],
  "blocked_story_rooms": [
    "ash_bell_forlorn_ritualant",
    "forlorn_ritualant_site",
    "generic_harvest_site"
  ],
  "hud_mode": "vista_approach",
  "minimap_mode": "authored_approach_only",
  "allow_harvest_nodes": false,
  "allow_procgen_foliage": false,
  "allow_procgen_health_bars": false
}
```

---

### D. Forlorn Ritualant Underground Relocation Assets

#### 14. Underground Ritual Chamber Background Plate

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/backgrounds/ash_bell/forlorn_ritualant/forlorn_ritualant_chamber_bg_01.png` |
| **Source Path** | `custodian/content/backgrounds/ash_bell/forlorn_ritualant/source/forlorn_ritualant_chamber_bg_01.aseprite` |
| **Size** | 1536x1024 |
| **Frame Count** | 1 |

---

#### 15. Ritual Floor Sigil VFX

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/sprites/vfx/world/ash_bell/forlorn_ritualant_sigil_01__12f__512x512.png` |
| **Source Path** | `custodian/content/sprites/vfx/world/ash_bell/source/forlorn_ritualant_sigil_01.aseprite` |
| **Frame Size** | 512x512 |
| **Frame Count** | 12 |
| **Sheet Size** | 6144x512 |
| **Playback** | 8–12 fps, looping subtle |

---

#### 16. Underground Ash Fog Loop

| Field | Value |
|-------|-------|
| **Runtime Path** | `custodian/content/sprites/vfx/world/ash_bell/forlorn_ritualant_ash_fog_01__10f__768x384.png` |
| **Source Path** | `custodian/content/sprites/vfx/world/ash_bell/source/forlorn_ritualant_ash_fog_01.aseprite` |
| **Frame Size** | 768x384 |
| **Frame Count** | 10 |
| **Sheet Size** | 7680x384 |
| **Playback** | 8 fps, looping |

**Purpose:** Gives the ritual its own biome identity instead of contaminating the Keep vista.

---

## Implementation Notes

### Step 1: Add Required Reveal Assets
```
custodian/content/backgrounds/sundered_keep/approach/fog/first_vista_fog_rollaway_01__8f__1024x512.png
custodian/content/backgrounds/sundered_keep/approach/light/first_vista_moonlight_sweep_01__6f__1024x512.png
custodian/content/backgrounds/sundered_keep/approach/fog/first_vista_edge_mist_wrap_01.png
custodian/content/backgrounds/sundered_keep/grand_vista/landmarks/grand_vista_labyrinth_far_01.png
custodian/content/backgrounds/sundered_keep/grand_vista/landmarks/grand_vista_labyrinth_far_02.png
custodian/content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_rect_seam_fog_mask_01.png
custodian/content/ui/world/sundered_keep_enter_prompt_01.png
```

### Step 2: Add Biome/Profile Lock Data
```
custodian/content/procgen/world_profiles/sundered_keep_vista_approach.json
custodian/content/world/regions/sundered_keep/vista_approach_region_lock.json
```

### Step 3: In SunderedKeepApproach
- Expose `region_id = "sundered_keep_vista_approach"`
- Load/apply the vista approach region lock
- Suppress procgen harvest/aspect/story-room overlays while this authored approach is active
- Ensure Forlorn Ritualant/Ash-Bell story room cannot render inside this scene

### Step 4: In SunderedKeepRevealDirector / VistaController
- Use `first_vista_fog_rollaway_01` during first camera snap/reveal
- Use `first_vista_moonlight_sweep_01` as a short low-energy light cue
- Delay the prompt until `reveal_completed`
- Keep far fog/haze after rollaway

### Step 5: Move Forlorn Ritualant Presentation Underground
- Keep its existing authored authority reservation behavior
- Add separate underground chamber/fog/sigil assets
- Do not allow it as a vista approach story room

---

## Recommended Repo Context for Codex

**Command:**
```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

repomix \
  --include "custodian/game/world/approaches/sundered_keep/**/*.gd,custodian/game/world/approaches/sundered_keep/**/*.tscn,custodian/content/procgen/world_profiles/**/*.json,custodian/game/world/procgen/progression/**/*.gd,custodian/game/world/procgen/proc_gen_tilemap.gd,custodian/game/world/events/ash_bell/**/*,custodian/docs/ai_context/task_packets/ASH_BELL_FORLORN_RITUALANT.md,design/04_architecture/REGION_GENERATION_SYSTEM.md,design/02_features/procgen/WORLD_ASCENT_STYLE_TRANSITION.md" \
  --output /tmp/custodian_sundered_keep_vista_asset_biome_context.md
```

---

## Summary

**Bottom Line:** Make the vista package Sundered Keep exterior-only, lock it to a `sundered_keep_vista_approach` profile, and move Forlorn Ritualant into an underground Ash-Bell scene with its own chamber assets.

**Asset Count:** 16 total assets
- **Required:** 7 assets (priority 1)
- **Optional:** 4 assets (enhancement)
- **Biome/Profile Data:** 2 JSON files
- **Underground Relocation:** 3 assets (for Forlorn Ritualant)

**Documentation Drift Note:** Updated `custodian/assets/sprites/...` references to `custodian/content/sprites/...` in:
- `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- `custodian/docs/change_control/GOTHIC_COMPOUND_LAYOUT_GRAMMAR.md`
- `custodian/docs/change_control/GOTHIC_COMPOUND_CONNECTED_MAP.md`
- `custodian/docs/change_control/list.md`
- `custodian/docs/change_control/CHANGE_CONTROL_BUNDLE_SCRIPT.md`
