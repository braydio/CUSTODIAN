# Resource Loop & Storage Raiding

**Type:** Feature request / Instructional spec  
**Status:** draft  
**Last Updated:** 2026-05-19  
**Cross-references:** `resource_collection/`, `resource_fabrication/`, `enemy_objective/`, `props/`, `procgen/gothic_compound/`  

---

## Framing

> **The player scavenges outside. Harvested resources are secured inside the compound. Enemies raid the compound to destroy infrastructure, steal stored loot, and escape.**

This is a much stronger objective loop than "harvest node → number goes up." It gives the player a reason to care about the indoor/base area, makes enemies feel purposeful, and turns resources into physical things in the world.

---

## Core Gameplay Loop

```
Leave indoor/base area
→ harvest resource nodes outside
→ resources get deposited into indoor storage props
→ enemies detect/raid storage
→ player defends, repairs, or intercepts thieves
→ stored resources are spent on upgrades/progression
```

The important part: **loot should become visible in the indoor area.** Do not make it only a number in a menu. The player should see the room filling with scrap piles, alloy racks, power cells, resin containers, etc.

---

## Indoor Storage Props

Each resource type should have a physical storage prop.

| Resource | Indoor storage prop | Visual states |
|---|---|---|
| `ruin_scrap` | scrap bin / wreckage crate | empty → half-full → full → damaged |
| `structural_alloy` | alloy rack / ingot shelf | empty rack → stacked bars → glowing tagged stockpile |
| `power_components` | power parts cabinet | closed crate → exposed components → sparking damaged cabinet |
| `resin_clot` | sealed resin vat | dark jar → amber-black filled vat → leaking cracked vat |
| `capacitor_dust` | sealed powder canister | small canisters → full containment box → spilled dust |
| `signal_filament` | hanging filament spool | empty hooks → glowing threads → tangled broken threads |
| `memory_glass_fragment` | locked reliquary drawer | empty tray → blue-gray shards → cracked exposed tray |

### First implementation — 3 state sprites per prop

```
empty
stored
damaged
```

### Later additions

```
full
looted
destroyed
```

---

## Enemy Objective Behavior

Give enemies explicit goals. The grunt should not just path toward the player forever.

### Enemy objective priorities

```
1. If player is close: fight or pressure player.
2. If storage prop is visible/reachable: attack or steal from it.
3. If carrying loot: flee to extraction point.
4. If storage is destroyed/empty: attack another prop.
5. If no objective exists: patrol/search.
```

This creates better combat immediately because the player has to decide:

```
Do I chase the thief?
Do I stop the vandal smashing the power cabinet?
Do I finish harvesting outside?
Do I retreat into the indoor area?
```

---

## Enemy Roles

Start with just your base grunt, but give it objective modes.

### `grunt_vandal`

**Purpose:** smashes storage and infrastructure.

**Animations needed:**
```
attack_prop_windup
attack_prop_strike
attack_prop_recovery
```

**Behavior:**
```
Path to storage prop
→ wind up
→ hit prop
→ damage prop
→ repeat until interrupted or prop destroyed
```

### `grunt_thief`

**Purpose:** steals stored loot and runs.

**Animations needed:**
```
loot_start
loot_hold
carry_run
escape
```

**Behavior:**
```
Path to storage prop
→ loot interaction
→ attach loot bundle to hand/back
→ run to escape point
→ remove resource from player storage if it escapes
```

### `grunt_raider`

**Purpose:** fights the player but opportunistically attacks storage.

This can be your first enemy.

**Behavior:**
```
If player close: attack player
Else if storage nearby: attack/steal
Else chase/search
```

---

## Objective Examples

### 1. Basic storage defense

```
Objective: Secure 12 ruin_scrap in the indoor depot.
Failure pressure: Enemies raid the scrap bin.
Win condition: Store 12 ruin_scrap and survive the raid.
```

### 2. Stop thieves

```
Objective: Prevent enemies from escaping with stored resources.
Failure pressure: Thieves carry loot toward exits.
Win condition: Kill or interrupt all thieves before they escape.
```

### 3. Repair the indoor area

```
Objective: Restore the indoor depot after a raid.
Requirement:
- 6 ruin_scrap
- 3 structural_alloy
- 1 power_component
```

### 4. Protect a key prop

```
Objective: Keep the Power Cabinet above 50% integrity.
Failure condition: Cabinet destroyed.
Win condition: Survive until extraction / complete harvest quota.
```

### 5. Fill the archive

For CUSTODIAN, make the indoor area feel like an **archive/storehouse**, not just a base.

```
Objective: Deposit memory_glass_fragment into the Archive Reliquary.
Result: Unlock lore/progression.
Raid behavior: Enemies prioritize the reliquary over common scrap.
```

---

## Implementation Architecture

Use three clean systems.

### 1. `ResourceLedger`

Autoload or manager that tracks global stored resources.

```gdscript
# ResourceLedger.gd
extends Node

signal resource_changed(resource_id: String, amount: int)
signal resource_stolen(resource_id: String, amount: int)
signal resource_deposited(resource_id: String, amount: int)

var stored := {}

func deposit(resource_id: String, amount: int) -> void:
	stored[resource_id] = stored.get(resource_id, 0) + amount
	resource_deposited.emit(resource_id, amount)
	resource_changed.emit(resource_id, stored[resource_id])

func remove(resource_id: String, amount: int) -> int:
	var current := stored.get(resource_id, 0)
	var taken := min(current, amount)
	stored[resource_id] = current - taken
	resource_changed.emit(resource_id, stored[resource_id])
	return taken
```

### 2. `StorageProp`

Physical prop in the indoor area.

```gdscript
# StorageProp.gd
extends Node2D

signal damaged(prop)
signal destroyed(prop)
signal looted(prop, resource_id: String, amount: int)

@export var resource_id: String = "ruin_scrap"
@export var max_integrity: int = 100
@export var loot_per_steal: int = 1

var integrity: int

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	integrity = max_integrity
	update_visual_state()


func damage(amount: int) -> void:
	integrity = max(0, integrity - amount)
	damaged.emit(self)

	if integrity <= 0:
		destroyed.emit(self)

	update_visual_state()


func steal() -> int:
	var taken := ResourceLedger.remove(resource_id, loot_per_steal)
	if taken > 0:
		looted.emit(self, resource_id, taken)
	return taken


func update_visual_state() -> void:
	var amount := ResourceLedger.stored.get(resource_id, 0)

	if integrity <= 0:
		# set destroyed sprite/frame
		return

	if amount <= 0:
		# set empty sprite/frame
		return

	if integrity < max_integrity * 0.5:
		# set damaged/stored sprite/frame
		return

	# set stored/full sprite/frame
```

### 3. `EnemyObjectiveBrain`

This chooses whether the enemy fights, smashes, steals, or flees.

```gdscript
enum ObjectiveMode {
	CHASE_PLAYER,
	ATTACK_STORAGE,
	STEAL_STORAGE,
	FLEE_WITH_LOOT,
	PATROL,
}

var objective_mode: ObjectiveMode = ObjectiveMode.PATROL
var target_storage: StorageProp = null
var carried_resource_id := ""
var carried_amount := 0


func choose_objective() -> void:
	if carried_amount > 0:
		objective_mode = ObjectiveMode.FLEE_WITH_LOOT
		return

	if player_is_close():
		objective_mode = ObjectiveMode.CHASE_PLAYER
		return

	target_storage = find_best_storage_target()

	if target_storage:
		if should_steal():
			objective_mode = ObjectiveMode.STEAL_STORAGE
		else:
			objective_mode = ObjectiveMode.ATTACK_STORAGE
		return

	objective_mode = ObjectiveMode.PATROL
```

---

## Storage Targeting

The enemies should prefer valuable or vulnerable storage.

**Scoring formula:**
```
target_score =
stored_amount * value_weight
+ damaged_bonus
+ proximity_bonus
+ mission_priority_bonus
```

**Example:**
```gdscript
func score_storage_target(prop: StorageProp) -> float:
	var amount: int = ResourceLedger.stored.get(prop.resource_id, 0)
	var score := 0.0

	score += amount * 10.0
	score += 100.0 / max(global_position.distance_to(prop.global_position), 32.0)

	if prop.integrity < prop.max_integrity * 0.5:
		score += 15.0

	if prop.resource_id == "memory_glass_fragment":
		score += 30.0

	return score
```

---

## How Stealing Should Work

Do not instantly delete the resource when the enemy touches the prop unless you want a harsher game. Better:

```
Enemy reaches storage
→ plays loot_start
→ steals 1 bundle
→ bundle becomes visible on enemy
→ enemy flees
→ resource is only permanently lost if enemy reaches exit
```

That gives the player a fair chance to recover it.

**On thief death:**
```
if carried_amount > 0:
	spawn ResourceDrop at enemy position
```

---

## Indoor Area Visual Upgrade

Your indoor area needs to become a **readable depot/compound interior**. Split it into functional zones.

### Required indoor zones

```
1. Entry threshold / airlock
2. Storage depot
3. Archive/reliquary corner
4. Workbench/fabricator area
5. Power cabinet / generator wall
6. Damaged wall/floor details
```

### Tile/prop list (initial set)

```
floor_concrete_32
floor_panel_32
floor_grate_32
threshold_metal_32

wall_military_32
wall_military_top_32
wall_military_corner_32
doorway_military_32

storage_scrap_bin_01
storage_alloy_rack_01
storage_power_cabinet_01
storage_resin_vat_01
storage_reliquary_01

cable_bundle_01
warning_light_01
broken_console_01
locker_01
crate_stack_01
floor_decal_oil_01
floor_decal_scratches_01
```

---

## Make the Indoor Area Look Better Immediately

The biggest improvement is **layering**.

### TileMap/Node layers

```
FloorBase
FloorDecals
LowerWalls
WallCaps
Doorways
PropsBehindPlayer
StorageProps
PropsInFrontOfPlayer
Lighting
Occluders
```

### Visual rules

```
Concrete floor should not be one repeated tile everywhere.
Break it with panel seams, grates, stains, scratches, and cable strips.

Walls need top caps and corner pieces.
A room without wall caps looks like outdoor tiles pretending to be indoors.

Storage props should sit against walls or on marked floor pads.
Do not scatter them randomly.

Important props need silhouette space.
Give the storage depot clear open floor around it so enemies and the player
can path around it.

Use light pools.
Put cyan/green light near working storage, amber/red light near damaged storage.
```

---

## Best First Vertical Slice

Implement one room and one resource first.

### First objective

```
Objective:
Harvest 6 ruin_scrap and secure it in the indoor scrap bin.

Enemy behavior:
2 grunts enter the indoor area.
One attacks the scrap bin.
One attacks/chases the player.

Failure pressure:
If the scrap bin is destroyed, stored scrap spills as drops.
If a thief escapes with scrap, subtract the carried amount.
```

### First props

```
storage_scrap_bin_01_empty
storage_scrap_bin_01_stored
storage_scrap_bin_01_damaged
storage_scrap_bin_01_destroyed
```

### First enemy interactions

```
attack_prop
steal_prop
carry_loot_run
drop_loot_on_death
escape_with_loot
```

---

## Design Rule

Stored resources should be **safe from ordinary loss**, but **not safe from raids**.

That gives the indoor area a real purpose:

```
Outside = risk while gathering.
Inside = risk while defending.
Storage = progression pressure.
Enemies = objective-driven threats, not just bodies to kill.
```

---

## Next Implementation Pass

Build exactly this:

```
1. ResourceLedger autoload
2. StorageProp scene
3. One scrap bin prop with 4 visual states
4. Enemy objective targeting for storage props
5. Enemy steal/carry/flee behavior
6. Indoor depot tile/prop pass
7. One test objective: "Secure 6 ruin_scrap"
```
