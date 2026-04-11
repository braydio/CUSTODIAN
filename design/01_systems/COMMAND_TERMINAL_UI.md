# CUSTODIAN Command Terminal UI Concept Archive

**Status:** concept archive  
**Last Updated:** 2026-04-08  
**Implementation Authority:** `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`  
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`

This file is preserved as an inspiration/concept sheet, not the current implementation spec.

Use it for:

- rough layout inspiration
- panel composition ideas
- dual-scale presentation intuition

Do **not** use it as the authoritative source for:

- player-facing language
- archive/recon semantics
- confidence wording
- contract fiction
- implementation contracts

Those now live in the canonical docs above.

Here’s a **high-fidelity concept of your CUSTODIAN command terminal UI**, based on what you described and aligned with your Godot-first architecture (render separated from simulation per your repo doctrine ).

---

## 🧠 CUSTODIAN Command Terminal – UI Concept

![Image](https://i.etsystatic.com/32708337/r/il/24fc0e/4273988884/il_570xN.4273988884_6h1a.jpg)

![Image](https://p.turbosquid.com/ts-thumb/My/5IsTu3/DM/futuristichologramcontrolpanelblackc4dmodel001/jpg/1728859870/1920x1080/fit_q87/9bad3f96bd2d4e2182846be9aa4ffd8313192c76/futuristichologramcontrolpanelblackc4dmodel001.jpg)

![Image](https://imagizer.imageshack.com/img922/3813/uyvVrw.jpg)

![Image](https://i.imgur.com/iCVlmxG.png)

---

## 🧩 Layout Breakdown (Implementation-Ready)

### 1. **Top Bar — System State Header**

* **Left:** `CUSTODIAN NODE // CONTRACT ACTIVE`
* **Center:** Planet name + contract ID
* **Right:**

  * Tick rate (e.g. `SIM: 60 TPS`)
  * Threat level (color-coded: green → red)
  * Power utilization %

---

### 2. **Left Panel — Activity Feed (Terminal Core)**

This is your **legacy terminal evolved into UI form**.

**Structure:**

```
[ACTIVITY FEED]
> [12:04:33] Relay Sync Stabilized (+2 fidelity)
> [12:04:36] Sector 3 breach detected
> [12:04:38] Turret Grid: Power deficit (–12%)
> [12:04:41] Assault wave inbound (ETA: 00:18)
```

**Key behaviors:**

* Scrollable, newest at bottom
* Color-coded:

  * Green = success
  * Yellow = warning
  * Red = combat-critical
* Supports **click-to-focus event → highlights map sector**

**Canon note:** feed language should remain procedural and denotative, not conversational or lore-dump heavy.

---

### 3. **Center Panel — Contracted Planet (Strategic Layer)**

This is your **high-level render**, not gameplay space.

**Visual:**

* Slowly rotating planet
* Overlay elements:

  * Orbital markers (relays, satellites)
  * Threat vectors (incoming assault trajectories)
  * Contract zones highlighted

**Interaction:**

* Click → zoom into region → transitions to local map
* Displays:

  * Global integrity
  * Relay network status
  * Incoming assault origin

**Canon note:** this view should reinforce contract/world identity and context recovery, not just act as decorative sci-fi spectacle.

---

### 4. **Right Panel — Local Tactical Map (Gameplay Layer)**

This is your **actual combat grid / sector map**.

**Features:**

* Tile-based (matches your 30–40 tile sectors)
* Shows:

  * Turrets (state: idle/firing/damaged)
  * Enemies (pathing + targeting)
  * Operator (player position)
  * Sector damage overlays

**Overlay Layers (toggleable):**

* Power grid
* Pathing/nav
* Threat heatmap
* Repair targets

---

### 5. **Bottom Bar — Command Interface**

This preserves your **terminal DNA but modernized**.

```
> allocate_defense sector=3 weight=high
> deploy turret_sniper x=14 y=22
> focus relay_network priority=stability
```

**Enhancements:**

* Autocomplete (from command tree)
* Inline validation
* Ghost preview on map before commit

---

## 🔁 Interaction Flow (Critical Design Insight)

This UI is **not just cosmetic — it enforces your architecture**:

| Layer         | Role                             |
| ------------- | -------------------------------- |
| Activity Feed | Event stream (simulation output) |
| Planet View   | Strategic abstraction            |
| Tactical Map  | Real-time execution              |
| Command Bar   | Input → simulation mutation      |

This directly respects:

> “Keep simulation logic separate from rendering and UI logic” 

---

## 🎯 What Makes This Work (Important)

### 1. **Dual-Scale Awareness**

* Planet = macro (why things happen)
* Map = micro (how they happen)

### 2. **Terminal → UI Evolution (NOT replacement)**

* You didn’t lose the terminal
* You **embedded it as a first-class system**

### 3. **Click-through Cohesion**

* Feed → Map highlight
* Planet → Sector zoom
* Command → Visual preview

---

## 🔧 If You Build This in Godot (Exact Node Layout)

```plaintext
Control (root)
├── TopBar (HBoxContainer)
├── MainSplit (HBoxContainer)
│   ├── ActivityFeed (VBoxContainer)
│   ├── PlanetView (SubViewportContainer)
│   └── TacticalMap (SubViewportContainer)
└── CommandBar (LineEdit + RichTextLabel)
```

---

## ⚠️ One Design Decision You Need to Lock

Right now you’re mixing:

* **RTS real-time combat**
* **Terminal command latency**

You need to choose:

**A. Immediate execution (arcade feel)**

* Commands apply instantly

**B. Buffered execution (simulation feel)**

* Commands queue into tick system

👉 Given your deterministic sim goals, **B is the correct choice**

This is no longer an open design question; treat buffered execution as the default direction unless a later explicit doctrine change overturns it.

Below is a **complete, drop-in `.tscn` layout** for your CUSTODIAN command terminal.
It includes:

* Activity Feed (wrapped text)
* Planet View (SubViewport container)
* Tactical Map (SubViewport container)
* Command Input bar
* Proper panel/header structure
* Theme hook (expects your `custodian_theme.tres`)

---

# 📦 `custodian_terminal.tscn`

Save this as:

```bash
custodian/ui/scenes/custodian_terminal.tscn
```

---

```tscn
[gd_scene load_steps=8 format=3]

[ext_resource type="Theme" path="res://custodian/ui/theme/custodian_theme.tres" id="1"]

[node name="CustodianTerminal" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme = ExtResource("1")

[node name="RootMargin" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 24
theme_override_constants/margin_top = 24
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 24

[node name="MainVBox" type="VBoxContainer" parent="RootMargin"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 16

# =========================
# TOP BAR
# =========================

[node name="TopBar" type="HBoxContainer" parent="RootMargin/MainVBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 40)

[node name="SystemLabel" type="Label" parent="RootMargin/MainVBox/TopBar"]
text = "CUSTODIAN NODE // CONTRACT ACTIVE"
size_flags_horizontal = 3

[node name="StatusLabel" type="Label" parent="RootMargin/MainVBox/TopBar"]
text = "SIM: 60 TPS | THREAT: LOW | POWER: 82%"

# =========================
# MAIN CONTENT
# =========================

[node name="MainSplit" type="HBoxContainer" parent="RootMargin/MainVBox"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 16

# =========================
# LEFT PANEL (ACTIVITY FEED)
# =========================

[node name="ActivityPanel" type="PanelContainer" parent="RootMargin/MainVBox/MainSplit"]
layout_mode = 2
custom_minimum_size = Vector2(420, 0)
size_flags_vertical = 3

[node name="ActivityVBox" type="VBoxContainer" parent="RootMargin/MainVBox/MainSplit/ActivityPanel"]
layout_mode = 2

[node name="ActivityHeader" type="PanelContainer" parent="RootMargin/MainVBox/MainSplit/ActivityPanel/ActivityVBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 28)

[node name="ActivityHeaderLabel" type="Label" parent="RootMargin/MainVBox/MainSplit/ActivityPanel/ActivityVBox/ActivityHeader"]
text = "ACTIVITY FEED"
horizontal_alignment = 0

[node name="ActivityScroll" type="ScrollContainer" parent="RootMargin/MainVBox/MainSplit/ActivityPanel/ActivityVBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="ActivityLog" type="RichTextLabel" parent="RootMargin/MainVBox/MainSplit/ActivityPanel/ActivityVBox/ActivityScroll"]
layout_mode = 2
bbcode_enabled = true
scroll_active = true
fit_content = false
autowrap_mode = 3  # WORD WRAP ENABLED
text = "[color=#58C4DD][12:04:33][/color] Relay Sync Stabilized\n[color=#E0A94A][12:04:36][/color] Sector 3 breach detected\n[color=#D85C5C][12:04:38][/color] Turret Grid power deficit\n"

# =========================
# CENTER PANEL (PLANET VIEW)
# =========================

[node name="PlanetPanel" type="PanelContainer" parent="RootMargin/MainVBox/MainSplit"]
layout_mode = 2
custom_minimum_size = Vector2(520, 0)
size_flags_vertical = 3

[node name="PlanetVBox" type="VBoxContainer" parent="RootMargin/MainVBox/MainSplit/PlanetPanel"]
layout_mode = 2

[node name="PlanetHeader" type="PanelContainer" parent="RootMargin/MainVBox/MainSplit/PlanetPanel/PlanetVBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 28)

[node name="PlanetHeaderLabel" type="Label" parent="RootMargin/MainVBox/MainSplit/PlanetPanel/PlanetVBox/PlanetHeader"]
text = "CONTRACTED PLANET"

[node name="PlanetViewportContainer" type="SubViewportContainer" parent="RootMargin/MainVBox/MainSplit/PlanetPanel/PlanetVBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="PlanetViewport" type="SubViewport" parent="RootMargin/MainVBox/MainSplit/PlanetPanel/PlanetVBox/PlanetViewportContainer"]
size = Vector2i(512, 512)
render_target_update_mode = 3

# =========================
# RIGHT PANEL (TACTICAL MAP)
# =========================

[node name="MapPanel" type="PanelContainer" parent="RootMargin/MainVBox/MainSplit"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="MapVBox" type="VBoxContainer" parent="RootMargin/MainVBox/MainSplit/MapPanel"]
layout_mode = 2

[node name="MapHeader" type="PanelContainer" parent="RootMargin/MainVBox/MainSplit/MapPanel/MapVBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 28)

[node name="MapHeaderLabel" type="Label" parent="RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/MapHeader"]
text = "LOCAL MAP"

[node name="MapViewportContainer" type="SubViewportContainer" parent="RootMargin/MainVBox/MainSplit/MapPanel/MapVBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="MapViewport" type="SubViewport" parent="RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/MapViewportContainer"]
size = Vector2i(768, 768)
render_target_update_mode = 3

# =========================
# COMMAND BAR
# =========================

[node name="CommandBar" type="HBoxContainer" parent="RootMargin/MainVBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 60)

[node name="Prompt" type="Label" parent="RootMargin/MainVBox/CommandBar"]
text = ">"
custom_minimum_size = Vector2(20, 0)

[node name="CommandInput" type="LineEdit" parent="RootMargin/MainVBox/CommandBar"]
layout_mode = 2
size_flags_horizontal = 3
placeholder_text = "enter command..."
```

---

# 🧠 Key Things You Now Have

### ✔ Proper panel architecture

* Header + content separation
* Expandable containers

### ✔ Wrapped activity feed

```tscn
autowrap_mode = 3
```

### ✔ Real render targets

* `PlanetViewport`
* `MapViewport`

### ✔ Clean scaling

* MarginContainer outer frame
* Fixed column widths for left/center
* flexible right map

---

# 🔧 Next Step (you will need this)

### Hook up activity feed logging

Attach script to root:

```gdscript
func log_event(text: String, color: String):
    var log = $RootMargin/MainVBox/MainSplit/ActivityPanel/ActivityVBox/ActivityScroll/ActivityLog
    log.append_text("[color=" + color + "]" + text + "[/color]\n")
```

---

# ⚠️ Important Implementation Notes

### 1. SubViewports are EMPTY right now

You must attach:

* planet scene → `PlanetViewport`
* tactical scene → `MapViewport`

---

### 2. Scroll performance

If feed grows large:

* periodically trim lines
* or switch to buffered log system

---

### 3. Command system

You’ll want:

* signal on enter pressed
* command parser → simulation layer

---

# If you want next step

I can wire:

* full **command parser → simulation hook**
* or **clicking feed entries highlights map sectors**
* or **planet → map zoom transitions**

Pick one.
