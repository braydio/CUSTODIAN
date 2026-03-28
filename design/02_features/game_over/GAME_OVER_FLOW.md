# GAME-OVER UX SPEC (READY TO IMPLEMENT)

**File target**

```
design/20_features/in_progress/GAME_OVER_FLOW.md
```

---

# Purpose

Define the **player defeat experience** when the Custodian facility fails.

Trigger conditions:

```
Command Post destroyed
OR
Total power grid collapse
OR
Custodian death (optional mode)
```

Primary MVP trigger:

```
Command Post destroyed
```

---

# Player Experience Flow

Game flow should be:

```
Facility under attack
        ↓
Command Post destroyed
        ↓
World pauses
        ↓
Game-over modal appears
        ↓
Player chooses action
```

---

# Modal Layout

Centered UI panel.

```
+--------------------------------+
|        FACILITY LOST           |
|                                |
| The command nexus has fallen.  |
|                                |
| Waves Survived: 12             |
| Enemies Destroyed: 183         |
| Power Failures: 3              |
|                                |
| [Restart Facility]             |
| [Return to Menu]               |
+--------------------------------+
```

---

# Implementation Architecture

### Scene

```
ui/
└ game_over_modal.tscn
```

Node structure:

```
GameOverModal (Control)
 ├ Panel
 ├ TitleLabel
 ├ StatsContainer
 │   ├ WavesLabel
 │   ├ EnemiesLabel
 │   └ PowerFailuresLabel
 └ ButtonContainer
     ├ RestartButton
     └ MenuButton
```

---

# Game-Over Trigger System

Create:

```
game_state.gd
```

This script is the **single authority** for win/lose state.

---

### Example

```
func on_command_destroyed():

    trigger_game_over()
```

---

### Game-over logic

```
func trigger_game_over():

    get_tree().paused = true

    var modal = preload("res://ui/game_over_modal.tscn").instantiate()

    get_tree().current_scene.add_child(modal)
```

---

# Restart Flow

Restart should **fully reload the scene**.

```
func restart():

    get_tree().paused = false
    get_tree().reload_current_scene()
```

---

# Return to Menu

```
func go_to_menu():

    get_tree().paused = false
    get_tree().change_scene_to_file("res://ui/main_menu.tscn")
```

---

# Statistics Collection

Track basic stats in a **GameStats singleton**.

```
waves_survived
enemies_destroyed
power_failures
turrets_lost
```

Example:

```
GameStats.waves_survived += 1
```

---

# Visual Effects on Defeat

Immediately when command post dies:

```
screen shake
alarm sound
lights flicker
turrets power down
```

Example:

```
GlobalEffects.trigger_alarm()
```

---

# Player UX Goals

Game-over must feel:

```
dramatic
sudden
recoverable (fast restart)
```

Restart should take **< 1 second**.
