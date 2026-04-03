extends Node2D

const TILE_SIZE = 10

const TILE_MAP = {
    "#": 0,   # wall
    ".": 1,   # floor
    "D": 2,   # door
    "G": 3,   # gateway (enemy spawn)
    "H": 4,   # hangar
    "C": 5,   # command
    "P": 6,   # power
    "F": 7,   # fabrication
    "S": 8,   # storage
    "A": 9,   # archive
    "M": 10,  # comms
    "T": 11,  # defense grid
    "K": 12,  # combat (killzone)
}

const SECTOR_TYPE_MAP = {
    "C": "COMMAND",
    "T": "DEFENSE",
    "M": "COMMS",
    "A": "ARCHIVE",
    "S": "STORAGE",
    "P": "POWER",
    "F": "FABRICATION",
    "H": "HANGAR",
    "G": "GATEWAY",
}

@onready var tile_map = $TileMap
@onready var sectors_container = $Sectors
@onready var doors_container = $Doors
@onready var enemies_container = $Enemies
@onready var operator = $Operator

var map_width := 0
var map_height := 0

func _ready():
    # Wait for children to be ready
    await ready
    load_map("res://game/world/maps/tutorial_v1.map")

func load_map(path: String):
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("Failed to open map: " + path)
        return
    
    var y = 0
    var door_positions: Array[Vector2i] = []
    var gateway_positions: Array[Vector2i] = []
    
    while not file.eof_reached():
        var line = file.get_line()
        
        if line.begins_with("WIDTH"):
            map_width = int(line.split(" ")[1])
            continue
        elif line.begins_with("HEIGHT"):
            map_height = int(line.split(" ")[1])
            continue
        elif line.is_empty():
            continue
            
        for x in range(line.length()):
            var char = line[x]
            var pos = Vector2i(x, y)
            
            if TILE_MAP.has(char):
                var tile_id = TILE_MAP[char]
                tile_map.set_cell(0, pos, 0, Vector2i(tile_id % 4, tile_id / 4))
                
                # Track special tiles for object spawning
                if char == "D":
                    door_positions.append(pos)
                elif char == "G":
                    gateway_positions.append(pos)
                elif SECTOR_TYPE_MAP.has(char):
                    _spawn_sector(char, pos)
        
        y += 1
    
    file.close()
    
    # Spawn doors after sectors (so we can place them between rooms)
    for door_pos in door_positions:
        _spawn_door(door_pos)
    
    # Spawn enemies at gateways
    for gw_pos in gateway_positions:
        _spawn_enemy(gw_pos)
    
    # Position operator at COMMAND
    _position_operator()
    
    print("Map loaded: ", map_width, "x", map_height)
    print("Sectors: ", sectors_container.get_child_count())
    print("Doors: ", doors_container.get_child_count())
    print("Enemies: ", enemies_container.get_child_count())

func _spawn_sector(char: String, pos: Vector2i):
    var sector_type = SECTOR_TYPE_MAP[char]
    var sector = _create_sector()
    sector.sector_name = sector_type
    sector.sector_type = sector_type
    sector.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
    sectors_container.add_child(sector)

func _spawn_door(pos: Vector2i):
    var door = _create_door()
    door.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
    doors_container.add_child(door)

func _spawn_enemy(pos: Vector2i):
    var enemy = _create_enemy()
    enemy.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
    enemies_container.add_child(enemy)

func _position_operator():
    # Find COMMAND sector and place operator there
    for sector in sectors_container.get_children():
        if sector.sector_type == "COMMAND":
            operator.position = sector.position
            return
    
    # Fallback: center of map
    operator.position = Vector2(map_width * TILE_SIZE / 2, map_height * TILE_SIZE / 2)

func _create_sector() -> Node:
    var sector_scene = load("res://game/actors/sector/sector.tscn")
    return sector_scene.instantiate()

func _create_door() -> Node:
    var door_scene = load("res://game/actors/door/door.tscn")
    return door_scene.instantiate()

func _create_enemy() -> Node:
    var enemy_scene = load("res://game/actors/enemies/enemy.tscn")
    return enemy_scene.instantiate()
