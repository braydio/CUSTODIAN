Below is a **game scene implementation spec** for a curated Ash-Bell encounter that can be dropped into your procgen world as a rare authored room. I’m treating the Ash-Bell source as canonical: internally it is “The Ash-Bell Continuity,” but the player should **not** be told that label or be told “alternate universe.” The repeated motifs should surface through matching contradictions: Ninth Bell, ash, Dry Fountain, black banners, white thread, and Saint Orra / the Unarrived Saint.

Repo/process note: your active runtime is Godot under `custodian/`, with active docs in `custodian/docs/` and Godot implementation specs under `design/`; AGENTS also says runtime behavior changes should update design docs first, then relevant AI context docs. Your tree map confirms the current project already has `custodian/content`, `custodian/assets`, `custodian/addons`, and Godot plugin/runtime structure available for this kind of feature work.

---

# Feature Spec: Ash-Bell Encounter — “The Bell-Kneeler and the Unarrived”

## 0. One-line pitch

A ruined chapel chamber appears in the explorable world: an empty bell-frame, a kneeling drifter, black banners, white thread, a missing fountain, and a funeral ritual for a saint who “arrives too late.” The player is never told what is happening. The encounter teaches that some temporal drifters remember the same catastrophe.

## 1. Design goal

This should feel like an Elden Ring side-room, not a quest marker.

The player enters a place that appears physically impossible but emotionally specific. The encounter is not “time travel explained.” It is a ritual site from a near-continuity bleeding into the current world.

The core feeling:

> Something terrible happened here, but not exactly here.

The player should walk away thinking:

> I keep hearing about the Ninth Bell, the Dry Fountain, white thread, black banners, and someone called Orra. These fragments are connected.

## 2. Non-negotiable tone rules

Do **not** use dialogue like:

```text
"This version..."
"This timeline..."
"In my world..."
"Last time you..."
"Alternate continuity..."
```

Use:

```text
"The west gate was shut before the third ringing."
"The Fountain should be beneath us."
"The banners are gone. Then the order was obeyed."
"The Unarrived has not come. The coffins remain light."
"The Bell is close tonight."
```

The NPC should speak as if their memory is true and the environment is wrong.

---

# 3. Encounter summary

## Public/player-facing name

Do not show “Ash-Bell Continuity.”

Use one of:

```text
Bell-Kneeler
Bell-Kneeler of the Empty Frame
Ash-Wrapped Penitent
Kneeler Beneath No Bell
```

## Internal feature id

```text
ash_bell_bell_kneeler_encounter
```

## Internal tags

```yaml
continuity_origin: ash_bell
near_continuity_tag: ash_bell
motifs:
  - ninth_bell
  - dry_fountain
  - black_banners
  - white_thread
  - unarrived_saint
  - ash_instead_of_snow
```

## Intended placement

Use as a **curated room inserted into procgen**, preferably:

```text
Hub-adjacent ruin: rare
Free-roam exterior: uncommon
Interior chapel/basilica: ideal
Underground threshold region: excellent
Early game: possible, but partial only
Mid game: ideal
Late game: expanded variant
```

## Encounter completion states

```gdscript
enum EncounterResolution {
    UNSEEN,
    SEEN,
    SPOKE_TO_KNEELER,
    TOUCHED_THREAD,
    TOOK_CLAPPER,
    CUT_THREAD,
    RANG_SILENCE,
    PROVOKED_KNEELER,
    KNEELER_DISSOLVED,
    SITE_STABILIZED,
    SITE_DEFILED
}
```

---

# 4. Map implementation spec

## Scene path

```text
custodian/game/world/events/ash_bell/bell_kneeler_site.tscn
```

## Main script path

```text
custodian/game/world/events/ash_bell/bell_kneeler_site.gd
```

## Event state script

```text
custodian/game/world/events/ash_bell/ash_bell_event_state.gd
```

## Dialogue data

```text
custodian/content/dialogue/ash_bell/bell_kneeler_dialogue.json
```

## Item data

```text
custodian/content/items/lore/ash_bell_items.json
```

## Room size

Use a **35×27 tile room**, assuming 32×32 tiles.

```text
Width:  35 tiles = 1120 px
Height: 27 tiles = 864 px
Tile:   32 px
```

## Camera framing

The player enters from the south. The empty bell-frame should be visible near the top center before the NPC is fully legible.

Ideal camera reveal:

1. Player enters ruined nave.
2. Ash particles drift upward.
3. Empty bell-frame appears.
4. White threads become visible.
5. Bell-Kneeler speaks before the player reaches them.

## Coordinate convention

```text
(0,0) = top-left tile
X increases east/right
Y increases south/down
```

## Layout legend

```text
# = wall / collapsed chapel boundary
. = cracked stone floor
, = ash drift floor
~ = black water / impossible seep
B = black banner
t = white thread strands
F = dry fountain ghost zone
K = Bell-Kneeler
C = bronze clapper pickup
E = empty bell-frame footprint
S = sealed arch / implied west gate
H = child handprints
R = ritual candles
P = player entry
G = ghost procession trigger
```

## Tile map

```text
00  ###################################
01  ###########.....EEE.....###########
02  ##########......EEE......##########
03  #########.......EEE.......#########
04  #######....B....ttt....B....#######
05  ######.........ttKtt.........######
06  #####..........ttCtt..........#####
07  ####.....R......ttt......R.....####
08  ###.............................###
09  ###....H...................H....###
10  ##.............FFFFF.............##
11  ##............FFFFFFF............##
12  ##............FFFFFFF............##
13  ##............FFFFFFF............##
14  ##.............FFFFF.............##
15  ###.............................###
16  ###....B...................B....###
17  ####.........S.....S.........####
18  #####........S.....S........#####
19  ######.......S.....S.......######
20  #######...................#######
21  ########........G........########
22  #########...............#########
23  ##########.............##########
24  ###########.....P.....###########
25  ############.........############
26  ###################################
```

## Physical collision

### Walls

All `#` tiles are solid.

### Empty bell-frame

`E` tiles are **not fully solid**. Use thin collision strips for the frame legs only.

```text
Frame legs:
- left post:  1 tile wide, collision enabled
- right post: 1 tile wide, collision enabled
- center: no collision
```

### Bell-Kneeler

The Bell-Kneeler body should block movement lightly before becoming hostile or dissolving.

```gdscript
collision_layer: NPC
collision_mask: PLAYER
```

### White thread strands

White threads are not normal blockers. They are **soft interaction hazards**.

```text
Walking through thread:
- no hard collision
- slows movement by 12%
- increases thread_tension slightly
- plays faint fiber strain audio
```

### Dry Fountain ghost zone

The `F` region is physically empty at first. After certain dialogue, a transparent dry fountain appears. It never becomes fully solid unless the player chooses to “Anchor the Thread.”

---

# 5. Environmental storytelling requirements

## 5.1 Empty bell-frame

Asset:

```text
custodian/content/props/ash_bell/empty_bell_frame_96x96.png
```

Description:

A massive oxidized iron bell-frame without a bell. It should look too heavy for the room. The frame has four vertical supports, a cracked yoke, and an empty hook where a bell should hang. Pale ash accumulates on top surfaces. A few strands of white thread climb from the floor to the hook.

Important: no bell. No silhouette of a missing bell unless extremely subtle.

## 5.2 Bronze clapper

Asset:

```text
custodian/content/props/ash_bell/bell_clapper_without_bell_32x32.png
```

Description:

A heavy bronze clapper lying across the Bell-Kneeler’s lap or just in front of them. It should be visually readable as a bell component even though there is no bell.

Gameplay:

The player can take it only after either:

```text
- completing the full dialogue
- cutting the thread
- defeating/provoking the Bell-Kneeler
```

## 5.3 White thread web

Assets:

```text
custodian/content/props/ash_bell/white_thread_floor_a_32.png
custodian/content/props/ash_bell/white_thread_floor_b_32.png
custodian/content/props/ash_bell/white_thread_hanging_32x64.png
custodian/content/props/ash_bell/white_thread_knot_16x16.png
```

Description:

Thin, almost-too-bright thread stretched between nails, bones, banner poles, bell-frame legs, and the Bell-Kneeler’s wrists. It must not look like spiderweb. It should read as human ritual craft: knots, deliberate wraps, tied loops.

## 5.4 Black banners

Assets:

```text
custodian/content/props/ash_bell/black_banner_hanging_32x64.png
custodian/content/props/ash_bell/black_banner_torn_32x48.png
custodian/content/props/ash_bell/black_banner_floor_32x32.png
```

Description:

Matte black military/funerary cloth, ash-stained, stitched with single white vertical thread lines. No readable insignia. Avoid clean heraldry. These should look like emergency containment banners raised during a catastrophe.

## 5.5 Child handprints

Asset:

```text
custodian/content/decals/ash_bell/ash_child_handprints_32.png
```

Description:

Small pale handprints in ash near the lower sides of the chamber, not gore. They should be subtle and visible only when the player slows down or the ash light flickers.

## 5.6 Dry Fountain apparition

Assets:

```text
custodian/content/props/ash_bell/dry_fountain_ghost_96x96.png
custodian/content/props/ash_bell/dry_fountain_black_water_96x96.png
custodian/content/props/ash_bell/dry_fountain_cracked_96x96.png
```

Description:

Initially invisible. After dialogue line “The Fountain should be beneath us,” a translucent ruined fountain fades in at the `F` region. Later, black water may appear in its basin if thread tension gets high.

Important:

The fountain should not look like it belongs to the active map. It should look like an overlapping civic monument from somewhere adjacent.

## 5.7 Sealed west gate markers

Assets:

```text
custodian/content/props/ash_bell/west_gate_seal_marker_32x64.png
custodian/content/decals/ash_bell/sealed_gate_scratches_32.png
```

Description:

Two archway stubs on the west/southwest side of the room. They should imply a gate used to exist, but the current architecture does not support it. A player should think: “Why would a gate be here?”

---

# 6. Character asset specs

Per your repo guidance, do **not** silently rely on invented production art. Wire placeholders first, then generate/replace these exact assets. The AGENTS file explicitly says new gameplay animation assets should be requested with exact save paths and intent.

## 6.1 Bell-Kneeler idle sprite

Path:

```text
custodian/content/sprites/npcs/ash_bell/bell_kneeler_idle_48x64.png
```

Sprite description:

A gaunt kneeling figure in black funeral cloth, viewed top-down 3/4. Hood low over face. Shoulders narrow. Spine bent. Hands wrapped together with white thread until the fingers look gray and bloodless. Cloth hem pools like ash-soaked robes. A bronze clapper rests before their knees. No visible weapon. Eyes should be faint pale slits only if readable at gameplay scale.

Palette:

```text
black cloth: #10100f / #1a1816
ash gray:    #b8b3a6 / #d8d2bf
thread:      #eee8d6
bronze:      #80613a / #b48a52
faint glow:  #d6cfb2
```

## 6.2 Bell-Kneeler rise animation

Path:

```text
custodian/content/sprites/npcs/ash_bell/bell_kneeler_rise_48x64.png
```

Frames:

```text
8 frames, 48x64 each
```

Intent:

The kneeler rises slowly, not aggressively. The white thread pulls taut before the body moves. The robe hangs too long. The bronze clapper drags against stone.

## 6.3 Bell-Kneeler hostile idle

Path:

```text
custodian/content/sprites/npcs/ash_bell/bell_kneeler_hostile_idle_48x64.png
```

Description:

Standing figure, slightly hunched, head lowered. White thread still wrapped around wrists, but now stretched outward as if attached to unseen points. The clapper is held like a ritual weight, not a weapon.

## 6.4 Bell-Kneeler attack animation

Path:

```text
custodian/content/sprites/npcs/ash_bell/bell_kneeler_clapper_swing_48x64.png
```

Frames:

```text
10 frames, 48x64 each
```

Intent:

A slow, heavy, readable arc. The attack should feel like a bell being swung by a person, not a normal mace swing. At impact, the screen/audio should briefly mute rather than play a loud hit.

## 6.5 Unarrived Saint apparition

Path:

```text
custodian/content/sprites/npcs/ash_bell/unarrived_saint_apparition_64x96.png
```

Description:

Do not make this a normal ghost woman. Make it almost non-figurative: a tall vertical absence wrapped in faint veil shapes, with a late-arriving halo offset behind the head, like the halo missed its timing. No face. White thread trails downward from the empty face area.

Use sparingly. It should appear for less than two seconds.

## 6.6 Unarrived procession silhouettes

Path:

```text
custodian/content/sprites/npcs/ash_bell/unarrived_procession_ghosts_32x48.png
```

Description:

Small, pale, half-transparent civic silhouettes: children, soldiers, mourners. No detailed faces. They should be readable as people only in aggregate.

---

# 7. Dialogue spec

## Dialogue design principle

The Bell-Kneeler is not trying to be mysterious. They are performing a rite and assuming the world still has the same ritual structure they remember.

## First proximity trigger

Trigger radius: 5 tiles.

```text
Bell-Kneeler:
“Do not speak during the toll.”
```

No bell sound should play.

Then after 2.5 seconds:

```text
Bell-Kneeler:
“The west gate was shut before the third ringing.”
```

Then after 3 seconds:

```text
Bell-Kneeler:
“Mothers pressed their children beneath the banners.”
```

Then after 2 seconds:

```text
Bell-Kneeler:
“And still the ash came.”
```

## First interaction

```text
Bell-Kneeler:
“The Fountain should be beneath us.”

Bell-Kneeler:
“Dry stone. Black water. Names counted without mouths.”

Bell-Kneeler:
“But the basin is gone.”

Bell-Kneeler:
“Then the dead are uncounted.”
```

Effect:

The Dry Fountain apparition fades in for 6 seconds, then disappears unless the player has taken the Thread Knot.

## Ask about the bell

Player prompt:

```text
“Bell?”
```

NPC:

```text
Bell-Kneeler:
“There were eight for the living.”

Bell-Kneeler:
“One for the misplaced.”

Bell-Kneeler:
“The Ninth had no bronze, no rope, no tower.”

Bell-Kneeler:
“Yet all knelt when it answered.”
```

## Ask about the thread

Player prompt:

```text
“Thread?”
```

NPC:

```text
Bell-Kneeler:
“For the wrist.”

Bell-Kneeler:
“For the name.”

Bell-Kneeler:
“For the poor child who wakes before her mother is born.”

Bell-Kneeler:
“When the thread snaps, Orra knows you are loose.”
```

## Ask about Orra / Unarrived Saint

Player prompt:

```text
“Orra?”
```

NPC:

```text
Bell-Kneeler:
“Saint Orra comes late.”

Bell-Kneeler:
“After the blade.”

Bell-Kneeler:
“After the order.”

Bell-Kneeler:
“After the gate is shut.”

Bell-Kneeler:
“She blesses only what cannot be saved.”
```

Then, after short pause:

```text
Bell-Kneeler:
“Do not pray for her arrival.”

Bell-Kneeler:
“That is how the Bell learns your name.”
```

## If player stands in the Dry Fountain zone

```text
Bell-Kneeler:
“Step aside.”

Bell-Kneeler:
“The unburied are counted there.”
```

If player stays:

```text
Bell-Kneeler:
“Ahh.”

Bell-Kneeler:
“You stand where the empty coffins stood.”
```

Effect:

Add `continuity_pressure += 1`.

## If player takes the clapper peacefully

```text
Bell-Kneeler:
“No sound will come.”

Bell-Kneeler:
“That is its mercy.”
```

## If player attacks

```text
Bell-Kneeler:
“Ahh, Custodian.”

Bell-Kneeler:
“So fear found you early.”
```

Then hostile phase begins.

## If player cuts thread

```text
Bell-Kneeler:
“No.”

Bell-Kneeler:
“Not the thread.”

Bell-Kneeler:
“The Unarrived will come looking.”
```

Effect:

The Unarrived apparition appears behind the player, not in front of them. It vanishes when the camera tries to center it.

## If player leaves without touching anything

On exit trigger:

```text
Bell-Kneeler:
“Go gently.”

Bell-Kneeler:
“Some gates are closed by footsteps.”
```

---

# 8. Mechanics

## 8.1 Silence pressure

The room has a hidden value:

```text
silence_pressure: 0–100
```

It rises when the player:

```text
- attacks
- fires a gun
- dodge-rolls through white thread
- cuts white thread
- takes the clapper before completing dialogue
- stands in the Dry Fountain zone too long
```

It decreases slowly when the player:

```text
- walks, not runs
- does not attack
- listens to full dialogue
- uses “touch thread” instead of “cut thread”
```

At high pressure, the room changes:

```text
25+  ash particles reverse direction
45+  dry fountain flickers into visibility
60+  black water appears
75+  procession ghosts appear
90+  hostile Bell-Kneeler phase starts automatically
```

## 8.2 White thread tension

White thread has its own value:

```text
thread_tension: 0–100
```

Actions:

```text
walk through thread:        +3
run through thread:         +7
dodge through thread:       +12
attack near thread:         +10
touch thread interaction:   -12
cut thread interaction:     set to 100
```

Thread tension effects:

```text
30+  thread sprites visibly tauten
60+  faint creaking/fiber audio
80+  player movement reduced by 8% while inside thread zone
100  thread snap event
```

Thread snap event:

```text
- all thread sprites briefly flash white
- audio cuts out completely for 0.75 seconds
- Unarrived apparition appears behind the player
- Bell-Kneeler becomes hostile unless already dissolved
```

## 8.3 Dry Fountain contradiction

The Dry Fountain has three visual states:

```gdscript
enum FountainState {
    ABSENT,
    GHOST,
    BLACK_WATER,
    CRACKED_ANCHORED
}
```

State rules:

```text
ABSENT:
  default

GHOST:
  after first dialogue about the Fountain
  or silence_pressure >= 45

BLACK_WATER:
  silence_pressure >= 60
  or player carries Bell-Clapper Without a Bell

CRACKED_ANCHORED:
  if player touches thread at low pressure and then interacts with Fountain
```

## 8.4 Unarrived apparition

The Unarrived Saint should not be a normal NPC.

It appears only under these conditions:

```text
- thread snaps
- player cuts thread
- player rings the clapper in the Fountain zone
- player defeats Bell-Kneeler violently
```

Behavior:

```text
- appears behind player
- no collision
- no health
- visible for 1.5–2.0 seconds
- never pathfinds
- never speaks directly
- emits one low reversed chime
```

Effect:

```text
continuity_pressure += 15
unlock_lore_flag("saw_unarrived_apparition")
```

## 8.5 Optional hostile phase

Do not force combat unless the player violates the ritual.

Boss title:

```text
Bell-Kneeler of the Empty Frame
```

Combat style:

The Bell-Kneeler is slow but changes the room rules.

Attacks:

```text
1. Soundless Clapper Swing
   - slow heavy arc
   - hit causes brief audio mute
   - small knockback
   - no huge damage spike

2. Thread Pull
   - white thread lines tighten
   - pulls player slightly toward center
   - dodgeable if moving perpendicular

3. Ninth Answer
   - kneeler raises clapper
   - no bell sound
   - Dry Fountain flashes black water
   - ghost procession crosses room
   - player must step out of procession lane

4. Orra Comes Late
   - delayed punish
   - after player heals or uses item, apparition appears behind them
   - not damage; applies “misplaced” status for 6 seconds
```

Misplaced status:

```text
- screen desaturates slightly
- player afterimage lags behind by 0.2 seconds
- enemy targeting uses current position, not afterimage
- purely disorienting, not unfair
```

Win condition:

```text
- reduce Bell-Kneeler HP to 0
OR
- survive 90 seconds after hostile phase starts
OR
- touch all three white-thread anchor knots while avoiding attacks
```

If survived/anchored, the Bell-Kneeler dissolves instead of dying.

---

# 9. Rewards and knowledge unlocks

Keep rewards informational, not pure power. This matches the CUSTODIAN principle that long-term rewards make the universe more legible, not necessarily safer. The existing docs describe persistent bonuses as improved classification, earlier pattern recognition, reduced ambiguity, and access to better questions rather than raw stat boosts.

## Item: Bell-Clapper Without a Bell

```json
{
  "id": "bell_clapper_without_bell",
  "display_name": "Bell-Clapper Without a Bell",
  "type": "lore_relic",
  "stackable": false,
  "tags": ["ash_bell", "ninth_bell", "continuity"],
  "description": "A bronze clapper from a bell no archive admits was cast. When moved, it makes no sound. Nearby grief briefly arranges itself into memory.",
  "mechanical_effects": {
    "unlock_knowledge_node": "ash_bell_ninth_bell",
    "increase_ash_bell_weight": 0.05
  }
}
```

## Item: White Thread Knot

```json
{
  "id": "white_thread_knot",
  "display_name": "White Thread Knot",
  "type": "lore_relic",
  "stackable": true,
  "tags": ["ash_bell", "white_thread", "saint_orra"],
  "description": "A funerary knot tied for those who had not yet arrived at their own death.",
  "mechanical_effects": {
    "unlock_knowledge_node": "ash_bell_white_thread",
    "reduce_future_drifter_ambiguity": 0.05
  }
}
```

## Item: Prayer to the Unarrived Saint

```json
{
  "id": "prayer_to_unarrived_saint",
  "display_name": "Prayer to the Unarrived Saint",
  "type": "lore_text",
  "stackable": false,
  "tags": ["ash_bell", "saint_orra", "unarrived"],
  "description": "Saint Orra, arrive late. Arrive after the blade. Arrive after the order. Arrive after the gate is shut. Witness what we could not stop.",
  "mechanical_effects": {
    "unlock_knowledge_node": "ash_bell_unarrived_saint"
  }
}
```

## Knowledge unlocks

```text
ash_bell_ninth_bell:
  Player can start recognizing Ninth Bell references in later drifter dialogue.

ash_bell_white_thread:
  Later white-thread objects become interactable rather than decorative.

ash_bell_dry_fountain:
  Dry Fountain references are indexed in archive/context UI.

ash_bell_unarrived_saint:
  Saint Orra / Unarrived Saint references are grouped without explanation.

ash_bell_bellfall_containment:
  Late-game only. Never use this label in ordinary NPC dialogue.
```

---

# 10. Data file: `bell_kneeler_dialogue.json`

```json
{
  "id": "ash_bell_bell_kneeler",
  "internal_name": "The Bell-Kneeler and the Unarrived",
  "public_name": "Bell-Kneeler",
  "continuity_origin": "ash_bell",
  "forbidden_terms": [
    "timeline",
    "alternate universe",
    "this version",
    "last time",
    "multiverse",
    "parallel world"
  ],
  "motifs": [
    "ninth_bell",
    "dry_fountain",
    "black_banners",
    "white_thread",
    "unarrived_saint",
    "ash_instead_of_snow"
  ],
  "nodes": {
    "proximity_intro": [
      {
        "speaker": "Bell-Kneeler",
        "text": "Do not speak during the toll.",
        "delay": 0.0
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "The west gate was shut before the third ringing.",
        "delay": 2.5
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "Mothers pressed their children beneath the banners.",
        "delay": 3.0
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "And still the ash came.",
        "delay": 2.0
      }
    ],
    "first_interaction": [
      {
        "speaker": "Bell-Kneeler",
        "text": "The Fountain should be beneath us."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "Dry stone. Black water. Names counted without mouths."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "But the basin is gone."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "Then the dead are uncounted."
      }
    ],
    "ask_bell": [
      {
        "speaker": "Bell-Kneeler",
        "text": "There were eight for the living."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "One for the misplaced."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "The Ninth had no bronze, no rope, no tower."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "Yet all knelt when it answered."
      }
    ],
    "ask_thread": [
      {
        "speaker": "Bell-Kneeler",
        "text": "For the wrist."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "For the name."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "For the poor child who wakes before her mother is born."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "When the thread snaps, Orra knows you are loose."
      }
    ],
    "ask_orra": [
      {
        "speaker": "Bell-Kneeler",
        "text": "Saint Orra comes late."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "After the blade."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "After the order."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "After the gate is shut."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "She blesses only what cannot be saved."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "Do not pray for her arrival."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "That is how the Bell learns your name."
      }
    ],
    "attack_response": [
      {
        "speaker": "Bell-Kneeler",
        "text": "Ahh, Custodian."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": So fear found you early."
      }
    ],
    "cut_thread_response": [
      {
        "speaker": "Bell-Kneeler",
        "text": "No."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "Not the thread."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "The Unarrived will come looking."
      }
    ],
    "peaceful_exit": [
      {
        "speaker": "Bell-Kneeler",
        "text": "Go gently."
      },
      {
        "speaker": "Bell-Kneeler",
        "text": "Some gates are closed by footsteps."
      }
    ]
  }
}
```

---

# 11. Godot scene tree

```text
BellKneelerSite (Node2D)
├── TileMaps
│   ├── GroundTileMap
│   ├── WallTileMap
│   ├── DecalTileMap
│   └── OverlayTileMap
├── Props
│   ├── EmptyBellFrame (StaticBody2D)
│   ├── DryFountainGhost (Sprite2D)
│   ├── DryFountainBlackWater (Sprite2D)
│   ├── BlackBanners (Node2D)
│   ├── WhiteThreadWeb (Node2D)
│   ├── ChildHandprints (Node2D)
│   └── BronzeClapperPickup (Area2D)
├── NPCs
│   └── BellKneeler (CharacterBody2D)
├── Triggers
│   ├── ProximityIntroTrigger (Area2D)
│   ├── DryFountainZone (Area2D)
│   ├── ExitTrigger (Area2D)
│   └── GhostProcessionTrigger (Area2D)
├── VFX
│   ├── UpwardAshParticles (GPUParticles2D)
│   ├── DownwardAshParticles (GPUParticles2D)
│   ├── SilencePulseCanvas (CanvasLayer)
│   ├── UnarrivedApparition (Sprite2D)
│   └── GhostProcession (Node2D)
├── Audio
│   ├── AshRoomBed (AudioStreamPlayer2D)
│   ├── ThreadStrainPlayer (AudioStreamPlayer2D)
│   ├── ReverseChimePlayer (AudioStreamPlayer2D)
│   └── SilenceBusController (Node)
└── Debug
    └── AshBellDebugLabel (Label)
```

---

# 12. GDScript: event state

Path:

```text
custodian/game/world/events/ash_bell/ash_bell_event_state.gd
```

```gdscript
class_name AshBellEventState
extends Resource

signal pressure_changed(silence_pressure: int, thread_tension: int)
signal fountain_state_changed(new_state: int)
signal resolution_changed(new_resolution: int)
signal knowledge_unlocked(knowledge_id: StringName)

enum FountainState {
	ABSENT,
	GHOST,
	BLACK_WATER,
	CRACKED_ANCHORED
}

enum Resolution {
	UNSEEN,
	SEEN,
	SPOKE_TO_KNEELER,
	TOUCHED_THREAD,
	TOOK_CLAPPER,
	CUT_THREAD,
	RANG_SILENCE,
	PROVOKED_KNEELER,
	KNEELER_DISSOLVED,
	SITE_STABILIZED,
	SITE_DEFILED
}

@export var silence_pressure: int = 0
@export var thread_tension: int = 0
@export var fountain_state: FountainState = FountainState.ABSENT
@export var resolution: Resolution = Resolution.UNSEEN

var seen_dialogue: Dictionary = {}
var unlocked_knowledge: Dictionary = {}
var has_clapper: bool = false
var has_thread_knot: bool = false
var apparition_seen: bool = false
var kneeler_hostile: bool = false

func add_silence_pressure(amount: int, reason: StringName = &"unknown") -> void:
	if amount == 0:
		return

	var previous := silence_pressure
	silence_pressure = clampi(silence_pressure + amount, 0, 100)

	if silence_pressure != previous:
		pressure_changed.emit(silence_pressure, thread_tension)

	_apply_pressure_thresholds(reason)


func add_thread_tension(amount: int, reason: StringName = &"unknown") -> void:
	if amount == 0:
		return

	var previous := thread_tension
	thread_tension = clampi(thread_tension + amount, 0, 100)

	if thread_tension != previous:
		pressure_changed.emit(silence_pressure, thread_tension)

	if thread_tension >= 100:
		set_resolution(Resolution.CUT_THREAD)
		add_silence_pressure(25, &"thread_snap")


func calm_thread(amount: int) -> void:
	if amount <= 0:
		return

	var previous := thread_tension
	thread_tension = clampi(thread_tension - amount, 0, 100)

	if thread_tension != previous:
		pressure_changed.emit(silence_pressure, thread_tension)


func mark_dialogue_seen(node_id: StringName) -> void:
	seen_dialogue[node_id] = true


func has_seen_dialogue(node_id: StringName) -> bool:
	return seen_dialogue.get(node_id, false)


func unlock_knowledge(knowledge_id: StringName) -> void:
	if unlocked_knowledge.get(knowledge_id, false):
		return

	unlocked_knowledge[knowledge_id] = true
	knowledge_unlocked.emit(knowledge_id)


func set_fountain_state(new_state: FountainState) -> void:
	if fountain_state == new_state:
		return

	fountain_state = new_state
	fountain_state_changed.emit(fountain_state)


func set_resolution(new_resolution: Resolution) -> void:
	if resolution == new_resolution:
		return

	resolution = new_resolution
	resolution_changed.emit(resolution)


func _apply_pressure_thresholds(reason: StringName) -> void:
	if silence_pressure >= 60 and fountain_state < FountainState.BLACK_WATER:
		set_fountain_state(FountainState.BLACK_WATER)
	elif silence_pressure >= 45 and fountain_state < FountainState.GHOST:
		set_fountain_state(FountainState.GHOST)

	if silence_pressure >= 90 and not kneeler_hostile:
		kneeler_hostile = true
		set_resolution(Resolution.PROVOKED_KNEELER)
```

---

# 13. GDScript: main site controller

Path:

```text
custodian/game/world/events/ash_bell/bell_kneeler_site.gd
```

```gdscript
class_name BellKneelerSite
extends Node2D

signal encounter_completed(resolution: int)
signal request_dialogue(dialogue_id: StringName, node_id: StringName)
signal request_item_grant(item_id: StringName)
signal request_knowledge_unlock(knowledge_id: StringName)

@export var dialogue_id: StringName = &"ash_bell_bell_kneeler"
@export var event_state: AshBellEventState

@export_group("Node Paths")
@export var bell_kneeler_path: NodePath
@export var dry_fountain_ghost_path: NodePath
@export var dry_fountain_black_water_path: NodePath
@export var upward_ash_path: NodePath
@export var downward_ash_path: NodePath
@export var unarrived_apparition_path: NodePath
@export var bronze_clapper_pickup_path: NodePath
@export var ghost_procession_path: NodePath
@export var debug_label_path: NodePath

@onready var bell_kneeler: Node = get_node_or_null(bell_kneeler_path)
@onready var dry_fountain_ghost: CanvasItem = get_node_or_null(dry_fountain_ghost_path)
@onready var dry_fountain_black_water: CanvasItem = get_node_or_null(dry_fountain_black_water_path)
@onready var upward_ash: GPUParticles2D = get_node_or_null(upward_ash_path)
@onready var downward_ash: GPUParticles2D = get_node_or_null(downward_ash_path)
@onready var unarrived_apparition: CanvasItem = get_node_or_null(unarrived_apparition_path)
@onready var bronze_clapper_pickup: Area2D = get_node_or_null(bronze_clapper_pickup_path)
@onready var ghost_procession: Node2D = get_node_or_null(ghost_procession_path)
@onready var debug_label: Label = get_node_or_null(debug_label_path)

var _intro_triggered: bool = false
var _player_inside_fountain: bool = false
var _fountain_stand_time: float = 0.0
var _completed: bool = false


func _ready() -> void:
	if event_state == null:
		event_state = AshBellEventState.new()

	event_state.pressure_changed.connect(_on_pressure_changed)
	event_state.fountain_state_changed.connect(_on_fountain_state_changed)
	event_state.resolution_changed.connect(_on_resolution_changed)
	event_state.knowledge_unlocked.connect(_on_knowledge_unlocked)

	_set_initial_visibility()
	_update_debug()


func _process(delta: float) -> void:
	if _player_inside_fountain:
		_fountain_stand_time += delta
		if _fountain_stand_time >= 2.0:
			_fountain_stand_time = 0.0
			event_state.add_silence_pressure(1, &"standing_in_dry_fountain")

	_update_debug()


func trigger_intro() -> void:
	if _intro_triggered:
		return

	_intro_triggered = true
	event_state.set_resolution(AshBellEventState.Resolution.SEEN)
	request_dialogue.emit(dialogue_id, &"proximity_intro")


func interact_with_kneeler() -> void:
	event_state.mark_dialogue_seen(&"first_interaction")
	event_state.set_resolution(AshBellEventState.Resolution.SPOKE_TO_KNEELER)
	event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)
	event_state.unlock_knowledge(&"ash_bell_dry_fountain")
	request_dialogue.emit(dialogue_id, &"first_interaction")


func ask_about_bell() -> void:
	event_state.mark_dialogue_seen(&"ask_bell")
	event_state.unlock_knowledge(&"ash_bell_ninth_bell")
	request_dialogue.emit(dialogue_id, &"ask_bell")


func ask_about_thread() -> void:
	event_state.mark_dialogue_seen(&"ask_thread")
	event_state.unlock_knowledge(&"ash_bell_white_thread")
	request_dialogue.emit(dialogue_id, &"ask_thread")


func ask_about_orra() -> void:
	event_state.mark_dialogue_seen(&"ask_orra")
	event_state.unlock_knowledge(&"ash_bell_unarrived_saint")
	request_dialogue.emit(dialogue_id, &"ask_orra")


func touch_thread() -> void:
	event_state.calm_thread(12)
	event_state.add_silence_pressure(-4, &"thread_touched")
	event_state.set_resolution(AshBellEventState.Resolution.TOUCHED_THREAD)

	if event_state.fountain_state == AshBellEventState.FountainState.GHOST:
		event_state.set_fountain_state(AshBellEventState.FountainState.CRACKED_ANCHORED)


func cut_thread() -> void:
	event_state.thread_tension = 100
	event_state.set_resolution(AshBellEventState.Resolution.CUT_THREAD)
	event_state.add_silence_pressure(25, &"thread_cut")
	request_dialogue.emit(dialogue_id, &"cut_thread_response")
	_show_unarrived_apparition()
	_start_hostile_phase()


func take_clapper() -> void:
	if event_state.has_clapper:
		return

	event_state.has_clapper = true
	event_state.set_resolution(AshBellEventState.Resolution.TOOK_CLAPPER)
	event_state.unlock_knowledge(&"ash_bell_ninth_bell")
	request_item_grant.emit(&"bell_clapper_without_bell")

	if bronze_clapper_pickup != null:
		bronze_clapper_pickup.queue_free()


func player_attacked_in_room() -> void:
	event_state.add_silence_pressure(15, &"player_attack")
	if not event_state.kneeler_hostile:
		request_dialogue.emit(dialogue_id, &"attack_response")
		_start_hostile_phase()


func player_fired_weapon_in_room() -> void:
	event_state.add_silence_pressure(22, &"player_firearm")
	if not event_state.kneeler_hostile:
		request_dialogue.emit(dialogue_id, &"attack_response")
		_start_hostile_phase()


func player_crossed_thread(move_kind: StringName) -> void:
	match move_kind:
		&"walk":
			event_state.add_thread_tension(3, &"walk_thread")
		&"run":
			event_state.add_thread_tension(7, &"run_thread")
		&"dodge":
			event_state.add_thread_tension(12, &"dodge_thread")
		_:
			event_state.add_thread_tension(3, &"cross_thread")


func set_player_inside_fountain(is_inside: bool) -> void:
	_player_inside_fountain = is_inside
	if not is_inside:
		_fountain_stand_time = 0.0


func exit_site() -> void:
	if _completed:
		return

	if event_state.resolution == AshBellEventState.Resolution.SPOKE_TO_KNEELER:
		request_dialogue.emit(dialogue_id, &"peaceful_exit")

	_complete_if_ready()


func stabilize_site() -> void:
	event_state.set_resolution(AshBellEventState.Resolution.SITE_STABILIZED)
	event_state.unlock_knowledge(&"ash_bell_bellfall_containment")
	_complete_if_ready()


func defile_site() -> void:
	event_state.set_resolution(AshBellEventState.Resolution.SITE_DEFILED)
	event_state.add_silence_pressure(100, &"site_defiled")
	_show_unarrived_apparition()
	_complete_if_ready()


func _start_hostile_phase() -> void:
	event_state.kneeler_hostile = true
	event_state.set_resolution(AshBellEventState.Resolution.PROVOKED_KNEELER)

	if bell_kneeler != null and bell_kneeler.has_method("become_hostile"):
		bell_kneeler.call("become_hostile")

	_set_downward_ash_enabled(true)
	_trigger_ghost_procession()


func _show_unarrived_apparition() -> void:
	event_state.apparition_seen = true
	event_state.unlock_knowledge(&"ash_bell_unarrived_saint")

	if unarrived_apparition == null:
		return

	unarrived_apparition.visible = true

	var tween := create_tween()
	tween.tween_property(unarrived_apparition, "modulate:a", 0.85, 0.15)
	tween.tween_interval(1.35)
	tween.tween_property(unarrived_apparition, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func() -> void:
		if is_instance_valid(unarrived_apparition):
			unarrived_apparition.visible = false
	)


func _trigger_ghost_procession() -> void:
	if ghost_procession == null:
		return

	if ghost_procession.has_method("play_once"):
		ghost_procession.call("play_once")
	else:
		ghost_procession.visible = true


func _set_initial_visibility() -> void:
	if dry_fountain_ghost != null:
		dry_fountain_ghost.visible = false
		dry_fountain_ghost.modulate.a = 0.0

	if dry_fountain_black_water != null:
		dry_fountain_black_water.visible = false
		dry_fountain_black_water.modulate.a = 0.0

	if unarrived_apparition != null:
		unarrived_apparition.visible = false
		unarrived_apparition.modulate.a = 0.0

	_set_downward_ash_enabled(false)


func _set_downward_ash_enabled(enabled: bool) -> void:
	if upward_ash != null:
		upward_ash.emitting = not enabled

	if downward_ash != null:
		downward_ash.emitting = enabled


func _on_pressure_changed(_silence_pressure: int, _thread_tension: int) -> void:
	if event_state.silence_pressure >= 25:
		# Ash contradiction begins: upward ash becomes unstable.
		if upward_ash != null:
			upward_ash.speed_scale = 0.55

	if event_state.silence_pressure >= 75:
		_trigger_ghost_procession()

	if event_state.silence_pressure >= 90 and not event_state.kneeler_hostile:
		_start_hostile_phase()


func _on_fountain_state_changed(new_state: int) -> void:
	match new_state:
		AshBellEventState.FountainState.ABSENT:
			_fade_canvas_item(dry_fountain_ghost, false)
			_fade_canvas_item(dry_fountain_black_water, false)

		AshBellEventState.FountainState.GHOST:
			_fade_canvas_item(dry_fountain_ghost, true)
			_fade_canvas_item(dry_fountain_black_water, false)

		AshBellEventState.FountainState.BLACK_WATER:
			_fade_canvas_item(dry_fountain_ghost, true)
			_fade_canvas_item(dry_fountain_black_water, true)

		AshBellEventState.FountainState.CRACKED_ANCHORED:
			_fade_canvas_item(dry_fountain_ghost, true)
			_fade_canvas_item(dry_fountain_black_water, false)


func _fade_canvas_item(item: CanvasItem, show: bool) -> void:
	if item == null:
		return

	item.visible = true
	var target_alpha := 1.0 if show else 0.0

	var tween := create_tween()
	tween.tween_property(item, "modulate:a", target_alpha, 0.45)
	if not show:
		tween.tween_callback(func() -> void:
			if is_instance_valid(item):
				item.visible = false
		)


func _on_resolution_changed(new_resolution: int) -> void:
	match new_resolution:
		AshBellEventState.Resolution.KNEELER_DISSOLVED, \
		AshBellEventState.Resolution.SITE_STABILIZED, \
		AshBellEventState.Resolution.SITE_DEFILED:
			_complete_if_ready()


func _on_knowledge_unlocked(knowledge_id: StringName) -> void:
	request_knowledge_unlock.emit(knowledge_id)


func _complete_if_ready() -> void:
	if _completed:
		return

	_completed = true
	encounter_completed.emit(event_state.resolution)


func _update_debug() -> void:
	if debug_label == null:
		return

	debug_label.text = "ASH-BELL\npressure=%s\nthread=%s\nfountain=%s\nres=%s" % [
		event_state.silence_pressure,
		event_state.thread_tension,
		event_state.fountain_state,
		event_state.resolution
	]
```

---

# 14. GDScript: Bell-Kneeler NPC

Path:

```text
custodian/game/world/events/ash_bell/bell_kneeler_npc.gd
```

```gdscript
class_name BellKneelerNPC
extends CharacterBody2D

signal defeated_nonlethal
signal defeated_violent
signal attack_started
signal clapper_impact
signal thread_pull_started

enum Phase {
	KNEELING,
	RISING,
	HOSTILE,
	DISSOLVING,
	GONE
}

@export var max_hp: int = 160
@export var move_speed: float = 42.0
@export var attack_range: float = 46.0
@export var attack_cooldown: float = 2.2
@export var survive_to_dissolve_seconds: float = 90.0

@export var target_path: NodePath
@export var site_path: NodePath
@export var animated_sprite_path: NodePath

@onready var target: Node2D = get_node_or_null(target_path)
@onready var site: BellKneelerSite = get_node_or_null(site_path)
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path)

var phase: Phase = Phase.KNEELING
var hp: int
var _attack_timer: float = 0.0
var _hostile_elapsed: float = 0.0


func _ready() -> void:
	hp = max_hp
	_play_anim(&"kneel_idle")


func _physics_process(delta: float) -> void:
	if phase != Phase.HOSTILE:
		return

	_hostile_elapsed += delta
	if _hostile_elapsed >= survive_to_dissolve_seconds:
		dissolve()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)

	if target == null:
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()

	if distance > attack_range:
		velocity = to_target.normalized() * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_choose_attack(distance)


func become_hostile() -> void:
	if phase == Phase.HOSTILE or phase == Phase.GONE:
		return

	phase = Phase.RISING
	_play_anim(&"rise")

	await get_tree().create_timer(0.8).timeout

	if phase == Phase.RISING:
		phase = Phase.HOSTILE
		_attack_timer = 0.5
		_play_anim(&"hostile_idle")


func apply_damage(amount: int, damage_tags: Array[StringName] = []) -> void:
	if phase == Phase.GONE or phase == Phase.DISSOLVING:
		return

	if phase != Phase.HOSTILE:
		become_hostile()

	hp = maxi(0, hp - amount)

	if hp <= 0:
		if damage_tags.has(&"thread_anchor"):
			dissolve()
		else:
			die_violently()


func dissolve() -> void:
	if phase == Phase.GONE:
		return

	phase = Phase.DISSOLVING
	velocity = Vector2.ZERO
	_play_anim(&"dissolve")

	if site != null:
		site.event_state.set_resolution(AshBellEventState.Resolution.KNEELER_DISSOLVED)

	defeated_nonlethal.emit()

	await get_tree().create_timer(1.25).timeout

	phase = Phase.GONE
	queue_free()


func die_violently() -> void:
	phase = Phase.GONE
	velocity = Vector2.ZERO
	defeated_violent.emit()

	if site != null:
		site.defile_site()

	queue_free()


func _choose_attack(distance: float) -> void:
	_attack_timer = attack_cooldown

	if site != null and site.event_state.thread_tension >= 60:
		_thread_pull()
		return

	if distance <= attack_range:
		_clapper_swing()


func _clapper_swing() -> void:
	attack_started.emit()
	_play_anim(&"clapper_swing")

	await get_tree().create_timer(0.42).timeout

	clapper_impact.emit()

	if site != null:
		site.event_state.add_silence_pressure(8, &"clapper_impact")


func _thread_pull() -> void:
	thread_pull_started.emit()
	_play_anim(&"thread_pull")

	if site != null:
		site.event_state.add_thread_tension(5, &"kneeler_thread_pull")


func _play_anim(anim_name: StringName) -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
```

---

# 15. GDScript: white thread hazard

Path:

```text
custodian/game/world/events/ash_bell/white_thread_hazard.gd
```

```gdscript
class_name WhiteThreadHazard
extends Area2D

@export var site_path: NodePath
@export var slow_multiplier: float = 0.88

@onready var site: BellKneelerSite = get_node_or_null(site_path)

var _bodies_inside: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	for body: Node in _bodies_inside.keys():
		if not is_instance_valid(body):
			_bodies_inside.erase(body)
			continue

		if not body.is_in_group("player"):
			continue

		var move_kind := _infer_move_kind(body)
		if site != null:
			site.player_crossed_thread(move_kind)

		_apply_slow(body)


func _on_body_entered(body: Node) -> void:
	_bodies_inside[body] = true


func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)


func _infer_move_kind(body: Node) -> StringName:
	if body.has_method("is_dodging") and body.call("is_dodging"):
		return &"dodge"

	if body.has_method("is_sprinting") and body.call("is_sprinting"):
		return &"run"

	return &"walk"


func _apply_slow(body: Node) -> void:
	if body.has_method("apply_external_speed_multiplier"):
		body.call("apply_external_speed_multiplier", slow_multiplier, 0.15)
```

---

# 16. GDScript: interactable routing

Path:

```text
custodian/game/world/events/ash_bell/ash_bell_interactable.gd
```

```gdscript
class_name AshBellInteractable
extends Area2D

enum InteractionKind {
	KNEELER,
	ASK_BELL,
	ASK_THREAD,
	ASK_ORRA,
	TOUCH_THREAD,
	CUT_THREAD,
	TAKE_CLAPPER,
	DRY_FOUNTAIN,
	RING_CLAPPER
}

@export var interaction_kind: InteractionKind = InteractionKind.KNEELER
@export var site_path: NodePath

@onready var site: BellKneelerSite = get_node_or_null(site_path)


func interact(_actor: Node) -> void:
	if site == null:
		push_warning("AshBellInteractable has no site reference.")
		return

	match interaction_kind:
		InteractionKind.KNEELER:
			site.interact_with_kneeler()

		InteractionKind.ASK_BELL:
			site.ask_about_bell()

		InteractionKind.ASK_THREAD:
			site.ask_about_thread()

		InteractionKind.ASK_ORRA:
			site.ask_about_orra()

		InteractionKind.TOUCH_THREAD:
			site.touch_thread()

		InteractionKind.CUT_THREAD:
			site.cut_thread()

		InteractionKind.TAKE_CLAPPER:
			site.take_clapper()

		InteractionKind.DRY_FOUNTAIN:
			site.event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)
			site.event_state.add_silence_pressure(3, &"fountain_touched")

		InteractionKind.RING_CLAPPER:
			site.event_state.set_resolution(AshBellEventState.Resolution.RANG_SILENCE)
			site.event_state.add_silence_pressure(35, &"rang_silence")
```

---

# 17. Procgen integration

This room should be treated as a rare special room, not a normal prop cluster.

## Room definition

Path:

```text
custodian/content/procgen/special_rooms/ash_bell_bell_kneeler_room.json
```

```json
{
  "id": "ash_bell_bell_kneeler_room",
  "display_name": "Ruined Bell Chapel",
  "scene_path": "res://game/world/events/ash_bell/bell_kneeler_site.tscn",
  "size_tiles": [35, 27],
  "entry_edges": ["south"],
  "exit_edges": ["north", "east"],
  "rarity": "rare",
  "min_depth": 2,
  "max_instances_per_run": 1,
  "tags": [
    "special_room",
    "ash_bell",
    "lore",
    "temporal_drifter",
    "low_combat",
    "ritual_site"
  ],
  "spawn_conditions": {
    "requires_flags_absent": ["ash_bell_bell_kneeler_completed"],
    "preferred_biomes": [
      "ruined_capital",
      "underground_chapel",
      "ash_waste",
      "collapsed_transit"
    ],
    "avoid_biomes": ["tutorial_compound", "high_tech_cleanroom"]
  },
  "reward_profile": {
    "primary": "knowledge",
    "secondary": "lore_relic",
    "combat_reward": "none"
  }
}
```

## Spawn weighting

Base:

```text
rare room chance: 3%
if player has seen any Ash-Bell drifter: +2%
if player has White Thread Knot: +3%
if player has Bell-Clapper Without a Bell: do not spawn again
```

Late-game:

```text
if custodian_instability >= high:
    ash_bell_special_room_weight += 0.10
```

This follows your Ash-Bell source recommendation that Ash-Bell appearances should be weighted enough for pattern recognition, but not so common that the game explains itself.

---

# 18. Suggested implementation proposal files

Because AGENTS has both `design/20_features/in_progress` and `design/features/implementation` conventions, I would create the implementation proposal here:

```text
design/features/implementation/ASH_BELL_BELL_KNEELER.md
design/features/implementation/ASH_BELL_BELL_KNEELER_CODE.md
```

Then add a lightweight index/link file here if your current workflow expects active features under `20_features/in_progress`:

```text
design/20_features/in_progress/ASH_BELL_BELL_KNEELER.md
```

## Documentation drift check

There is a small repo-governance drift in `AGENTS.md`: it first says Godot implementation specs live in `./design/20_features/in_progress`, but the required process later says new feature proposals should use `design/features/implementation/FEATURE_NAME.md` and `FEATURE_NAME_CODE.md`.

Recommended action:

```text
Make design/features/implementation the canonical proposal location.
Use design/20_features/in_progress only for active implementation tracking / index files.
Update AGENTS.md to say this explicitly.
```

This avoids agents creating duplicate specs in two incompatible places.

---

# 19. What makes this mechanically fresh

The encounter is not just dialogue.

It has four overlapping mechanics:

1. **Silence pressure**
   The player’s aggression makes the room more wrong.

2. **Thread tension**
   Movement through ritual space has consequences without hard-blocking exploration.

3. **Architecture contradiction**
   The Dry Fountain appears because the NPC remembers it, not because the map originally had it.

4. **Nonlethal ritual resolution**
   The player can solve the room by respecting, touching, and anchoring the thread instead of killing the NPC.

That is the important part: the player is not rewarded for “understanding the lore.” They are rewarded for noticing that this place has rules.

---

# 20. Minimum shippable version

Do this first:

```text
1. Static room scene
2. Bell-Kneeler NPC, non-hostile
3. Proximity dialogue
4. Dry Fountain apparition
5. White Thread Knot pickup
6. Bell-Clapper Without a Bell pickup
7. One knowledge flag unlock
8. No combat
```

Then add:

```text
9. Silence pressure
10. Thread tension
11. Unarrived apparition
12. Hostile Bell-Kneeler
13. Procgen rare-room injection
```

That gets you the atmosphere quickly without blocking on boss AI. The full version is worth building, but the static ritual-room version alone is already strong enough to appear in-game.
