structure_command_keep_gothic_large

- Type: major structure / landmark
- Collision: yes
- Gameplay role: command core, mission objective, compound center
- Suggested Godot form: StaticBody2D scene or decorative Node2D with collision children

structure_utility_fan_roof_block

- Type: utility structure
- Collision: yes
- Gameplay role: power/HVAC/industrial support building, possible repair or sabotage target
- Suggested Godot form: StaticBody2D scene

structure_machine_house_gothic_industrial

- Type: utility structure / machinery building
- Collision: yes
- Gameplay role: generator room, power relay, fabricator support, objective building
- Suggested Godot form: StaticBody2D or interactable scene if used for gameplay

platform_stone_plain_large

- Type: terrain/platform tile block
- Collision: no
- Gameplay role: courtyard floor, build pad, staging area
- Suggested Godot form: TileMap terrain or large decorative floor sprite

platform_stone_symbol_large

- Type: terrain/platform decal
- Collision: no
- Gameplay role: command pad, ritual/anchor point, objective marker floor
- Suggested Godot form: TileMap tile or floor decal

platform_hazard_striped_large

- Type: industrial platform / hazard pad
- Collision: no by default
- Gameplay role: landing pad, build pad, machine pad, danger zone
- Suggested Godot form: TileMap floor or Area2D if it has gameplay behavior

gate_arch_open_gothic

- Type: gate architecture
- Collision: partial
- Gameplay role: decorative open passage, entry landmark
- Suggested Godot form: StaticBody2D with collision on side pillars only; center passable

structure_dry_fountain_basin_octagonal

- Type: small structure / landmark
- Collision: yes
- Gameplay role: courtyard centerpiece, lore marker, cover obstruction
- Suggested Godot form: StaticBody2D scene

bell_frame_gothic_small

- Type: landmark / interactable candidate
- Collision: yes
- Gameplay role: bell shrine, alarm object, lore node
- Suggested Godot form: StaticBody2D or interactable Area2D scene

obelisk_spire_marker_tall

- Type: marker / monument
- Collision: yes
- Gameplay role: processional marker, boundary marker, lore prop
- Suggested Godot form: StaticBody2D scene

lamp_post_amber_single

- Type: light prop
- Collision: optional small
- Gameplay role: ambient light source, path marker
- Suggested Godot form: Node2D scene with PointLight2D child

doorway_gothic_small

- Type: doorway / small structure
- Collision: partial
- Gameplay role: entrance marker, locked door visual, structure attachment
- Suggested Godot form: StaticBody2D if blocked; Area2D if interactable/passable

terminal_compound_control_console

- Type: interactable
- Collision: yes
- Gameplay role: gate control, compound control, power/fabricator UI object
- Suggested Godot form: Area2D interactable + StaticBody2D collision

gate_threshold_closed_blocking

- Type: gate state
- Collision: yes
- Gameplay role: closed/locked gate, clear blocked passage
- Suggested Godot form: StaticBody2D scene or TileMap obstacle layer

gate_threshold_open_walkable

- Type: gate state
- Collision: no center collision
- Gameplay role: open/passable gate threshold
- Suggested Godot form: TileMap floor/prop; side posts only if separated

cover_low_wall_long_h

- Type: cover / barrier
- Collision: yes
- Gameplay role: low cover, boundary divider, defensive barricade
- Suggested Godot form: StaticBody2D; mark as cover if you add cover logic
