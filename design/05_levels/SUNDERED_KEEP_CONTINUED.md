<html><head></head><body><p>Below is a full end-to-end Codex instructional. It assumes the current repo state we already verified: Sundered Keep has a live connected-map slice, key-gated Main Gate, Return Mooring, Great Hall door, and debug state in <code inline="">sundered_keep_map.gd</code>; <code inline="">interact</code> and <code inline="">repair</code> input actions already exist in <code inline="">project.godot</code>; and the packet/docs path cleanup may still need to be normalized before implementation.</p><p>You are working in the CUSTODIAN repo.</p><p>Task: complete the playable Sundered Keep gatehouse siege feature end-to-end.</p><p>This is not a docs-only pass. Implement the runtime feature, validate it, and update the docs/task packet afterward.</p><p>The goal is to extend the existing Sundered Keep front-gate/key/Return Mooring slice into a playable siege scenario with:</p><ul><li><p>gate-open-triggered siege lifecycle</p></li><li><p>multi-wave pressure</p></li><li><p>defendable objectives</p></li><li><p>objective integrity damage</p></li><li><p>repair interaction</p></li><li><p>defensive helper / turret / placeholder defense node</p></li><li><p>debug state visibility</p></li><li><p>validation</p></li><li><p>AI context docs updates</p></li></ul><p>Do not create production art. Use existing assets, simple placeholder nodes, or debug-visible behavior.</p><p>Do not rewrite the whole player, enemy, procgen, inventory, or combat architecture.</p><p>Do not block on perfect enemy AI/pathing. If real enemy integration is too risky, implement deterministic pressure entities now and document real enemy visuals/AI as follow-up.</p><hr><h1>0. Start And Read Context</h1><p>Start from repo root:</p><pre><code class="language-bash">cd ~/Projects/CUSTODIAN
git status --short
</code></pre><p>Read routing and active context:</p><pre><code class="language-bash">sed -n '1,260p' AGENTS.md
sed -n '1,260p' custodian/AGENTS.md

if [ -f custodian/docs/ai_context/task_packets/PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md ]; then
PACKET=custodian/docs/ai_context/task_packets/PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md
else
PACKET=custodian/docs/ai_context/task_packets/playable_siege_loop_gatehouse_slice.md
fi

sed -n '1,440p' "$PACKET"
sed -n '1,320p' custodian/docs/ai_context/CURRENT_STATE.md
sed -n '1,360p' custodian/docs/ai_context/FILE_INDEX.md
sed -n '1,260p' custodian/docs/ai_context/VALIDATION_RECIPES.md
sed -n '1,120p' custodian/docs/ai_context/task_packets/README.md
</code></pre><p>Important current foundation:</p><ul><li><p>Active runtime is <code inline="">custodian/</code>.</p></li><li><p>Existing Sundered Keep runtime lives under <code inline="">custodian/game/world/sundered_keep/</code>.</p></li><li><p>The current Sundered Keep map already has key-gated gate behavior and Return Mooring behavior.</p></li><li><p>Extend the existing Sundered Keep implementation unless discovery proves a cleaner existing reusable system is available.</p></li></ul><hr><h1>1. Lightweight Pre-Implementation Cleanup</h1><p>Do this quickly, then proceed to runtime implementation.</p><h2>1.1 Normalize packet name if needed</h2><pre><code class="language-bash">if [ -f custodian/docs/ai_context/task_packets/playable_siege_loop_gatehouse_slice.md ] &amp;&amp; [ ! -f custodian/docs/ai_context/task_packets/PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md ]; then
git mv custodian/docs/ai_context/task_packets/playable_siege_loop_gatehouse_slice.md \
 custodian/docs/ai_context/task_packets/PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md
PACKET=custodian/docs/ai_context/task_packets/PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md
fi
</code></pre><h2>1.2 Fix stale design path references</h2><p>In the packet, replace stale references to:</p><pre><code class="language-text">design/20_features/in_progress/
</code></pre><p>with the current structure:</p><pre><code class="language-text">design/
design/00_meta/
design/01_systems/
design/02_features/
design/04_architecture/
</code></pre><p>Do not spend more than a few minutes polishing this. Make the packet accurate enough and move on.</p><h2>1.3 Ensure packet README lists this work</h2><p>Update:</p><pre><code class="language-text">custodian/docs/ai_context/task_packets/README.md
</code></pre><p>Add under Active Packets / In Progress if missing:</p><pre><code class="language-markdown">- `PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md` — Implements the Sundered Keep gatehouse siege loop: gate-open-triggered wave pressure, defendable objective integrity, repair interaction, defensive helper behavior, debug state, validation, and docs updates.
</code></pre><hr><h1>2. Runtime Discovery</h1><p>Run broad searches, but do not get trapped in analysis. The Sundered Keep files are the primary work surface.</p><pre><code class="language-bash">find design -maxdepth 4 -type f | sort

find custodian/game -type f \
 \( -name '_.gd' -o -name '_.tscn' -o -name '\*.tres' \) | sort

find custodian/content -type f \
 \( -name '_.json' -o -name '_.gd' -o -name '\*.tres' \) | sort

rg -n \
"wave|spawn|spawner|enemy_spawn|objective|director|assault|turret|repair|sector|damage|gate|door|sundered|keep|interact|InputMap|collision|blocker|InventoryManager|VaultManager|enemy|grunt|drone|defense|ally|health|integrity|event|mission|encounter" \
design custodian/game custodian/scenes custodian/content custodian/docs custodian/project.godot
</code></pre><p>Inspect Sundered Keep first:</p><pre><code class="language-bash">sed -n '1,400p' custodian/game/world/sundered_keep/sundered_keep_map.gd
sed -n '400,800p' custodian/game/world/sundered_keep/sundered_keep_map.gd
sed -n '800,1200p' custodian/game/world/sundered_keep/sundered_keep_map.gd

sed -n '1,260p' custodian/game/world/sundered_keep/sundered_keep_interactable.gd
sed -n '1,320p' custodian/game/world/sundered_keep/sundered_keep_tilemap_loader.gd
</code></pre><p>Inspect likely related systems discovered by search:</p><pre><code class="language-bash">find custodian/game -type f | grep -Ei 'enemy|grunt|wave|spawn|director|objective|assault|turret|defense|drone|repair|sector|damage|inventory|vault' | sort
</code></pre><p>Read relevant discovered files with <code inline="">sed -n</code>.</p><hr><h1>3. Preferred Implementation Architecture</h1><p>Keep this local to Sundered Keep unless a clearly reusable existing system is already present.</p><p>Preferred files:</p><pre><code class="language-text">custodian/game/world/sundered_keep/sundered_keep_map.gd
custodian/game/world/sundered_keep/sundered_keep_interactable.gd
custodian/game/world/sundered_keep/sundered_keep_siege_controller.gd
</code></pre><p>Create this new controller unless the map file remains very small after edits:</p><pre><code class="language-text">custodian/game/world/sundered_keep/sundered_keep_siege_controller.gd
</code></pre><p>Optional, only if useful:</p><pre><code class="language-text">custodian/game/world/sundered_keep/gatehouse_defense_node.gd
</code></pre><p>Avoid introducing a broad generic objective framework. This feature should be a focused Sundered Keep siege loop.</p><p>Recommended division:</p><ul><li><p><code inline="">sundered_keep_map.gd</code></p><ul><li><p>owns map construction</p></li><li><p>owns existing gate/key/Return Mooring interactions</p></li><li><p>creates and wires siege controller</p></li><li><p>forwards repair interaction</p></li><li><p>exposes debug state</p></li></ul></li><li><p><code inline="">sundered_keep_siege_controller.gd</code></p><ul><li><p>owns siege lifecycle</p></li><li><p>owns wave progression</p></li><li><p>owns objective integrity</p></li><li><p>owns pressure ticks</p></li><li><p>owns repair cooldown</p></li><li><p>owns defensive helper state</p></li><li><p>optionally spawns enemies if safe</p></li><li><p>returns a debug dictionary</p></li></ul></li></ul><hr><h1>4. Implement <code inline="">sundered_keep_siege_controller.gd</code></h1><p>Create:</p><pre><code class="language-text">custodian/game/world/sundered_keep/sundered_keep_siege_controller.gd
</code></pre><p>Suggested implementation contract:</p><pre><code class="language-gdscript">extends Node
class_name SunderedKeepSiegeController

signal siege_started(reason: String)
signal siege_completed()
signal siege_failed(reason: String)
signal wave_started(index: int, target: String)
signal wave_completed(index: int)
signal objective_damaged(id: String, value: int)
signal objective_repaired(id: String, value: int)
signal defense_activated()

const OBJECTIVE_MAX := 100

const WAVE_CONFIG := [
{
"name": "Breach Probe",
"enemy_count": 3,
"target": "gate",
"pressure_damage": 4,
"pressure_ticks_to_complete": 5,
},
{
"name": "Courtyard Push",
"enemy_count": 5,
"target": "sector",
"pressure_damage": 5,
"pressure_ticks_to_complete": 6,
},
{
"name": "Mooring Sabotage",
"enemy_count": 6,
"target": "mooring",
"pressure_damage": 6,
"pressure_ticks_to_complete": 7,
},
]

@export var pressure_tick_seconds := 2.0
@export var repair_amount := 20
@export var repair_cooldown_seconds := 2.0
@export var defense_tick_seconds := 2.5
@export var defense_pressure_reduction := 2
@export var spawn_real_enemies := false

var connected_map: Node = null

var siege_started_flag := false
var siege_complete := false
var siege_failed_flag := false
var siege_phase := "idle"

var wave_active := false
var wave_index := -1
var active_siege_enemies := 0
var current_pressure_target := ""
var current_wave_pressure_ticks := 0
var current_wave_required_ticks := 0

var objectives := {
"gate": OBJECTIVE_MAX,
"mooring": OBJECTIVE_MAX,
"sector": OBJECTIVE_MAX,
}

var repair_cooldown_remaining := 0.0
var defense_active := false
var defense_kills := 0
var defense_efficiency := 1.0

var \_pressure_accum := 0.0
var \_defense_accum := 0.0
var \_spawned_enemies: Array[Node] = []

func configure(map: Node) -&gt; void:
connected_map = map

func \_process(delta: float) -&gt; void:
if repair_cooldown_remaining &gt; 0.0:
repair_cooldown_remaining = maxf(0.0, repair_cooldown_remaining - delta)

    if not siege_started_flag or siege_complete or siege_failed_flag:
    	return

    if wave_active:
    	_pressure_accum += delta
    	if _pressure_accum &gt;= pressure_tick_seconds:
    		_pressure_accum = 0.0
    		_apply_pressure_tick()

    if defense_active and wave_active:
    	_defense_accum += delta
    	if _defense_accum &gt;= defense_tick_seconds:
    		_defense_accum = 0.0
    		_apply_defense_tick()

func start_siege(reason: String) -&gt; void:
if siege_started_flag:
return
if siege_complete or siege_failed_flag:
return

    siege_started_flag = true
    siege_phase = "breach"
    defense_active = true
    defense_activated.emit()
    print("[SunderedKeepSiege] Siege started: %s" % reason)
    siege_started.emit(reason)
    start_wave(0)

func start_wave(index: int) -&gt; void:
if index &gt;= WAVE_CONFIG.size():
\_complete_siege()
return

    wave_index = index
    var config: Dictionary = WAVE_CONFIG[index]
    wave_active = true
    current_pressure_target = str(config.get("target", "sector"))
    current_wave_pressure_ticks = 0
    current_wave_required_ticks = int(config.get("pressure_ticks_to_complete", 5))
    active_siege_enemies = int(config.get("enemy_count", 3))
    _pressure_accum = 0.0
    _defense_accum = 0.0

    print("[SunderedKeepSiege] Wave %d started: %s target=%s enemies=%d" % [
    	index + 1,
    	str(config.get("name", "Wave")),
    	current_pressure_target,
    	active_siege_enemies,
    ])
    wave_started.emit(index, current_pressure_target)

    if spawn_real_enemies:
    	_spawn_wave_enemies(config)

func \_apply_pressure_tick() -&gt; void:
if not wave_active:
return

    var config: Dictionary = WAVE_CONFIG[wave_index]
    var damage := int(config.get("pressure_damage", 5))
    if defense_active:
    	damage = maxi(1, damage - defense_pressure_reduction)

    if active_siege_enemies &lt;= 0:
    	damage = 1

    damage_objective(current_pressure_target, damage)
    current_wave_pressure_ticks += 1

    print("[SunderedKeepSiege] Pressure tick target=%s damage=%d enemies=%d tick=%d/%d" % [
    	current_pressure_target,
    	damage,
    	active_siege_enemies,
    	current_wave_pressure_ticks,
    	current_wave_required_ticks,
    ])

    if _has_failed_objective():
    	_fail_siege("objective_destroyed")
    	return

    if current_wave_pressure_ticks &gt;= current_wave_required_ticks or active_siege_enemies &lt;= 0:
    	_complete_wave()

func \_apply_defense_tick() -&gt; void:
if active_siege_enemies &lt;= 0:
return

    active_siege_enemies = maxi(0, active_siege_enemies - 1)
    defense_kills += 1
    print("[SunderedKeepSiege] Defense reduced enemy pressure. enemies=%d kills=%d" % [
    	active_siege_enemies,
    	defense_kills,
    ])

func damage_objective(id: String, amount: int) -&gt; void:
if not objectives.has(id):
return

    var value := int(objectives[id])
    value = clampi(value - maxi(0, amount), 0, OBJECTIVE_MAX)
    objectives[id] = value
    objective_damaged.emit(id, value)

    if value &lt;= 25:
    	print("[SunderedKeepSiege] Objective critical: %s=%d" % [id, value])

func repair_objective(id: String, amount: int) -&gt; void:
if not objectives.has(id):
return

    var value := int(objectives[id])
    value = clampi(value + maxi(0, amount), 0, OBJECTIVE_MAX)
    objectives[id] = value
    objective_repaired.emit(id, value)
    print("[SunderedKeepSiege] Repaired %s to %d" % [id, value])

func repair_most_damaged_objective() -&gt; bool:
if repair_cooldown_remaining &gt; 0.0:
print("[SunderedKeepSiege] Repair cooling down: %.1fs" % repair_cooldown_remaining)
return false

    var target := get_lowest_integrity_objective()
    if target == "":
    	return false

    if int(objectives[target]) &gt;= OBJECTIVE_MAX:
    	print("[SunderedKeepSiege] Nothing to repair.")
    	return false

    repair_objective(target, repair_amount)
    repair_cooldown_remaining = repair_cooldown_seconds
    return true

func get_lowest_integrity_objective() -&gt; String:
var lowest_id := ""
var lowest_value := OBJECTIVE_MAX + 1

    for id in objectives.keys():
    	var value := int(objectives[id])
    	if value &lt; lowest_value:
    		lowest_value = value
    		lowest_id = str(id)

    return lowest_id

func \_complete_wave() -&gt; void:
if not wave_active:
return

    var completed_index := wave_index
    wave_active = false
    active_siege_enemies = 0
    current_pressure_target = ""
    current_wave_pressure_ticks = 0
    current_wave_required_ticks = 0

    print("[SunderedKeepSiege] Wave %d complete." % [completed_index + 1])
    wave_completed.emit(completed_index)

    start_wave(completed_index + 1)

func \_complete_siege() -&gt; void:
wave_active = false
siege_complete = true
siege_phase = "complete"
current_pressure_target = ""
active_siege_enemies = 0
print("[SunderedKeepSiege] Siege complete.")
siege_completed.emit()

func \_fail_siege(reason: String) -&gt; void:
if siege_failed_flag:
return

    wave_active = false
    siege_failed_flag = true
    siege_phase = "failed"
    print("[SunderedKeepSiege] Siege failed: %s" % reason)
    siege_failed.emit(reason)

func \_has_failed_objective() -&gt; bool: # Keep failure lenient enough for testing. Fail when any core objective hits zero.
return int(objectives.get("gate", OBJECTIVE_MAX)) &lt;= 0 \
 or int(objectives.get("mooring", OBJECTIVE_MAX)) &lt;= 0 \
 or int(objectives.get("sector", OBJECTIVE_MAX)) &lt;= 0

func \_spawn_wave_enemies(config: Dictionary) -&gt; void: # Optional hook. Keep disabled unless a known safe enemy scene/factory is discovered. # If implemented later, spawn existing enemy scenes at Sundered Keep-specific spawn points, # add them to group "sundered_keep_siege_enemy", and decrement active_siege_enemies when they die.
pass

func debug_damage_objective(id: String, amount: int = 25) -&gt; void:
damage_objective(id, amount)

func debug_repair_all() -&gt; void:
for id in objectives.keys():
objectives[id] = OBJECTIVE_MAX
repair_cooldown_remaining = 0.0

func debug_complete_wave() -&gt; void:
\_complete_wave()

func get_debug_state() -&gt; Dictionary:
return {
"siege_started": siege_started_flag,
"siege_complete": siege_complete,
"siege_failed": siege_failed_flag,
"siege_phase": siege_phase,
"wave_active": wave_active,
"wave_index": wave_index,
"wave_number": wave_index + 1 if wave_index &gt;= 0 else 0,
"remaining_waves": max(0, WAVE_CONFIG.size() - wave_index - 1) if wave_index &gt;= 0 else WAVE_CONFIG.size(),
"active_siege_enemies": active_siege_enemies,
"gate_integrity": int(objectives.get("gate", OBJECTIVE_MAX)),
"mooring_integrity": int(objectives.get("mooring", OBJECTIVE_MAX)),
"sector_integrity": int(objectives.get("sector", OBJECTIVE_MAX)),
"repair_ready": repair_cooldown_remaining &lt;= 0.0,
"repair_cooldown_remaining": repair_cooldown_remaining,
"defense_active": defense_active,
"defense_kills": defense_kills,
"defense_efficiency": defense_efficiency,
"pressure_target": current_pressure_target,
}
</code></pre><p>Adjust for exact Godot/GDScript syntax if the repo uses a slightly different Godot version. Keep class name and API stable.</p><hr><h1>5. Wire Controller Into <code inline="">sundered_keep_map.gd</code></h1><p>Edit:</p><pre><code class="language-text">custodian/game/world/sundered_keep/sundered_keep_map.gd
</code></pre><p>Add preload near existing constants:</p><pre><code class="language-gdscript">const SUNDERED_KEEP_SIEGE_CONTROLLER := preload("res://game/world/sundered_keep/sundered_keep_siege_controller.gd")
</code></pre><p>Add runtime fields:</p><pre><code class="language-gdscript">var \_siege_controller: Node = null
var \_repair_interaction: Node2D = null
</code></pre><p>After map build completes, create the controller and repair interaction.</p><p>A safe place is at the end of <code inline="">\_build_from_level_data(data)</code> after <code inline="">\_add_return_gate()</code> and in the fallback <code inline="">\_build_once()</code> path after <code inline="">\_add_return_gate()</code>.</p><p>Add helper:</p><pre><code class="language-gdscript">func \_ensure_siege_controller() -&gt; void:
if \_siege_controller != null and is_instance_valid(\_siege_controller):
return

    _siege_controller = SUNDERED_KEEP_SIEGE_CONTROLLER.new()
    _siege_controller.name = "SunderedKeepSiegeController"
    add_child(_siege_controller)

    if _siege_controller.has_method("configure"):
    	_siege_controller.call("configure", self)

    if _siege_controller.has_signal("siege_started"):
    	_siege_controller.connect("siege_started", Callable(self, "_on_siege_started"))
    if _siege_controller.has_signal("siege_completed"):
    	_siege_controller.connect("siege_completed", Callable(self, "_on_siege_completed"))
    if _siege_controller.has_signal("siege_failed"):
    	_siege_controller.connect("siege_failed", Callable(self, "_on_siege_failed"))

</code></pre><p>Add event handlers:</p><pre><code class="language-gdscript">func \_on_siege_started(reason: String) -&gt; void:
print("[SunderedKeep] Siege controller started: %s" % reason)

func \_on_siege_completed() -&gt; void:
print("[SunderedKeep] Gatehouse siege complete.")

func \_on_siege_failed(reason: String) -&gt; void:
print("[SunderedKeep] Gatehouse siege failed: %s" % reason)
</code></pre><p>Call <code inline="">\_ensure_siege_controller()</code> after the map has built its interactables/layers.</p><p>Example:</p><pre><code class="language-gdscript">func \_build_from_level_data(data: Dictionary) -&gt; void:
...
\_build_stateful_gates_from_level_data()
\_build_traversal_stubs()
\_add_return_gate()
\_ensure_siege_controller()
\_add_siege_repair_interaction()
</code></pre><p>Also update fallback build path:</p><pre><code class="language-gdscript">func \_build_once() -&gt; void:
...
\_build_traversal_stubs()
\_add_return_gate()
\_ensure_siege_controller()
\_add_siege_repair_interaction()
debug_print_layout_summary()
</code></pre><p>Make sure <code inline="">\_ensure_siege_controller()</code> does not depend on level-data-only fields.</p><hr><h1>6. Start Siege When Main Gate Opens</h1><p>In <code inline="">sundered_keep_map.gd</code>, update the successful gate-open flow.</p><p>Find <code inline="">\_try_open_main_gate()</code> and/or <code inline="">\_set_main_gate_open(open: bool)</code>.</p><p>Preferred:</p><pre><code class="language-gdscript">func \_try_open_main_gate() -&gt; void:
if \_main_gate_open:
return
if not \_player_has_sundered_gate_key():
print("[SunderedKeep] Requires %s. The portcullis winch is locked." % SUNDERED_GATE_KEY_NAME)
return
\_set_main_gate_open(true)
\_start_siege_once("main_gate_opened")
</code></pre><p>Add:</p><pre><code class="language-gdscript">func \_start_siege_once(reason: String) -&gt; void:
\_ensure_siege_controller()
if \_siege_controller != null and \_siege_controller.has_method("start_siege"):
\_siege_controller.call("start_siege", reason)
</code></pre><p>Make sure siege starts once only; the controller should guard this.</p><hr><h1>7. Add Repair Interaction</h1><p>Use the existing <code inline="">SunderedKeepInteractable</code> pattern.</p><p>Add a repair interactable near the Return Mooring or gate winch. Preferred tile: near <code inline="">return_mooring_origin_tile + Vector2i(2, 4)</code> or near <code inline="">key_pickup_tile + Vector2i(-1, 1)</code>.</p><p>Add helper:</p><pre><code class="language-gdscript">func \_add_siege_repair_interaction() -&gt; void:
if \_repair_interaction != null and is_instance_valid(\_repair_interaction):
return

    var repair_tile := return_mooring_origin_tile + Vector2i(2, 4)
    _repair_interaction = _add_interactable(
    	"SiegeRepairInteraction",
    	&amp;"repair_siege_objective",
    	"REPAIR SIEGE DAMAGE",
    	repair_tile,
    	88.0
    )

</code></pre><p>Update <code inline="">\_handle_sundered_interaction(kind, actor)</code>:</p><pre><code class="language-gdscript">func \_handle_sundered_interaction(kind: StringName, actor: Node) -&gt; void:
match kind:
&amp;"return_mooring":
return_to_main(actor)
&amp;"sundered_gate_key":
\_grant_sundered_gate_key()
&amp;"main_gate":
\_try_open_main_gate()
&amp;"great_hall_door":
\_try_open_great_hall_door()
&amp;"repair_siege_objective":
\_repair_siege_objective()
</code></pre><p>Add:</p><pre><code class="language-gdscript">func \_repair_siege_objective() -&gt; void:
\_ensure_siege_controller()
if \_siege_controller != null and \_siege_controller.has_method("repair_most_damaged_objective"):
var repaired := bool(\_siege_controller.call("repair_most_damaged_objective"))
if not repaired:
print("[SunderedKeep] No siege repair applied.")
</code></pre><p>Do not require a resource cost in this pass. This is a playable interaction validation pass.</p><hr><h1>8. Expand Debug State</h1><p>Update <code inline="">get_sundered_keep_debug_state()</code>.</p><p>Current state already includes fields like <code inline="">main_gate_open</code>, <code inline="">great_hall_door_open</code>, <code inline="">has_sundered_gate_key</code>, etc. Keep those.</p><p>Add siege state:</p><pre><code class="language-gdscript">var siege_state := {}
if \_siege_controller != null and is_instance_valid(\_siege_controller) and \_siege_controller.has_method("get_debug_state"):
siege_state = \_siege_controller.call("get_debug_state")

return {
...
"siege": siege_state,
"siege_started": bool(siege_state.get("siege_started", false)),
"siege_complete": bool(siege_state.get("siege_complete", false)),
"siege_failed": bool(siege_state.get("siege_failed", false)),
"siege_phase": str(siege_state.get("siege_phase", "idle")),
"wave_active": bool(siege_state.get("wave_active", false)),
"wave_index": int(siege_state.get("wave_index", -1)),
"active_siege_enemies": int(siege_state.get("active_siege_enemies", 0)),
"gate_integrity": int(siege_state.get("gate_integrity", 100)),
"mooring_integrity": int(siege_state.get("mooring_integrity", 100)),
"sector_integrity": int(siege_state.get("sector_integrity", 100)),
"repair_ready": bool(siege_state.get("repair_ready", true)),
"defense_active": bool(siege_state.get("defense_active", false)),
"defense_kills": int(siege_state.get("defense_kills", 0)),
"pressure_target": str(siege_state.get("pressure_target", "")),
}
</code></pre><p>Use exact syntax compatible with the existing return dictionary.</p><p>Also update <code inline="">debug_print_layout_summary()</code> to include concise siege fields if useful, but avoid overloading the log.</p><hr><h1>9. Optional: Add Map Debug Methods</h1><p>Add lightweight debug helper methods in <code inline="">sundered_keep_map.gd</code>:</p><pre><code class="language-gdscript">func debug_start_siege() -&gt; void:
\_start_siege_once("debug")

func debug_damage_siege_objective(id: String = "gate", amount: int = 25) -&gt; void:
\_ensure_siege_controller()
if \_siege_controller != null and \_siege_controller.has_method("debug_damage_objective"):
\_siege_controller.call("debug_damage_objective", id, amount)

func debug_repair_siege_all() -&gt; void:
\_ensure_siege_controller()
if \_siege_controller != null and \_siege_controller.has_method("debug_repair_all"):
\_siege_controller.call("debug_repair_all")

func debug_complete_siege_wave() -&gt; void:
\_ensure_siege_controller()
if \_siege_controller != null and \_siege_controller.has_method("debug_complete_wave"):
\_siege_controller.call("debug_complete_wave")
</code></pre><p>Only add these if they do not conflict with project style. They are useful for manual validation.</p><hr><h1>10. Real Enemy Integration Decision</h1><p>During discovery, if there is a safe known enemy scene/factory, integrate it lightly.</p><p>Acceptable real-enemy integration:</p><ul><li><p>Use discovered existing enemy scene.</p></li><li><p>Spawn at fixed Sundered Keep tile positions.</p></li><li><p>Add to group <code inline="">sundered_keep_siege_enemy</code>.</p></li><li><p>Set global position.</p></li><li><p>Track active count in controller.</p></li><li><p>If enemy has a death signal, decrement count when it dies.</p></li><li><p>If not, do not overbuild. Let deterministic pressure count drive the gameplay for this pass.</p></li></ul><p>Suggested fixed spawn tiles:</p><pre><code class="language-gdscript">const SIEGE_SPAWN_TILES := [
Vector2i(52, 52),
Vector2i(58, 52),
Vector2i(48, 46),
Vector2i(62, 46),
]
</code></pre><p>But prefer tiles based on the actual large front-gate layout.</p><p>If real enemy integration is too risky, leave <code inline="">spawn_real_enemies = false</code> and implement deterministic pressure through <code inline="">active_siege_enemies</code>.</p><p>Document the limitation.</p><hr><h1>11. Defensive Helper Behavior</h1><p>The controller’s default defense behavior may simply reduce enemy pressure every <code inline="">defense_tick_seconds</code>. This is acceptable.</p><p>If a real allied drone/turret system is easy to activate, use it. Otherwise the controller’s deterministic defense behavior is enough for this feature.</p><p>The defense must be visible in debug state:</p><pre><code class="language-gdscript">"defense_active"
"defense_kills"
"defense_efficiency"
</code></pre><p>Debug prints should show when it reduces enemy pressure.</p><hr><h1>12. Failure And Completion</h1><p>Implement both outcomes.</p><p>Failure:</p><ul><li><p>If any core objective reaches 0, set <code inline="">siege_failed = true</code>.</p></li><li><p>Stop wave pressure.</p></li><li><p>Print a clear message.</p></li></ul><p>Completion:</p><ul><li><p>If all configured waves complete, set <code inline="">siege_complete = true</code>.</p></li><li><p>Stop wave pressure.</p></li><li><p>Print a clear message.</p></li></ul><p>Do not overbuild end screens. Debug-visible state is enough.</p><hr><h1>13. Add Validation Smoke Test</h1><p>If feasible, add:</p><pre><code class="language-text">custodian/tools/validation/sundered_keep_siege_smoke.gd
</code></pre><p>Use existing validation style from nearby files under <code inline="">custodian/tools/validation/</code>.</p><p>The smoke test should load/instantiate the controller directly if possible and verify the core deterministic API.</p><p>Suggested checks:</p><pre><code class="language-gdscript">extends SceneTree

const SIEGE_CONTROLLER := preload("res://game/world/sundered_keep/sundered_keep_siege_controller.gd")

func \_init() -&gt; void:
var controller := SIEGE_CONTROLLER.new()
get_root().add_child(controller)

    var state := controller.get_debug_state()
    assert(state["siege_started"] == false)
    assert(state["gate_integrity"] == 100)

    controller.start_siege("smoke")
    state = controller.get_debug_state()
    assert(state["siege_started"] == true)
    assert(state["wave_active"] == true)

    controller.damage_objective("gate", 50)
    state = controller.get_debug_state()
    assert(state["gate_integrity"] == 50)

    controller.repair_objective("gate", 20)
    state = controller.get_debug_state()
    assert(state["gate_integrity"] == 70)

    controller.debug_repair_all()
    state = controller.get_debug_state()
    assert(state["gate_integrity"] == 100)

    print("[sundered_keep_siege_smoke] PASS")
    quit(0)

</code></pre><p>Adjust for the repo’s actual validation idioms. Do not add a brittle scene-level smoke test if direct controller test is enough.</p><hr><h1>14. Run Validation</h1><p>Run the narrowest useful validation.</p><p>First, try GDScript/Godot validation from <code inline="">VALIDATION_RECIPES.md</code>.</p><p>Likely:</p><pre><code class="language-bash">cd custodian
godot --headless --check-only project.godot
</code></pre><p>If unsupported, record exact result and use closest existing repo command.</p><p>If you added the smoke test, try:</p><pre><code class="language-bash">cd custodian
godot --headless --script res://tools/validation/sundered_keep_siege_smoke.gd
</code></pre><p>If Godot is unavailable or crashes due to unrelated project/editor issues, do not pretend success. Record:</p><ul><li><p>command attempted</p></li><li><p>failure output summary</p></li><li><p>whether failure appears related to this change</p></li></ul><p>Also run simple text checks:</p><pre><code class="language-bash">rg -n "SunderedKeepSiegeController|repair_siege_objective|\_start_siege_once|gate_integrity|mooring_integrity|sector_integrity" \
 custodian/game/world/sundered_keep custodian/tools/validation custodian/docs/ai_context
</code></pre><hr><h1>15. Update Docs</h1><p>After runtime implementation, update:</p><pre><code class="language-text">custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/task_packets/PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md
custodian/docs/ai_context/task_packets/README.md
</code></pre><h2>15.1 CURRENT_STATE.md</h2><p>Add a concise bullet under the current implemented slice / Sundered Keep section:</p><pre><code class="language-markdown">- Sundered Keep gatehouse siege loop is now live: opening the item-gated Main Gate starts a deterministic multi-wave siege controller, tracks gate/mooring/sector integrity, applies pressure ticks, exposes repair interaction near the Return Mooring/gatehouse, activates a defensive helper pressure-reduction loop, supports siege completion/failure states, and exposes the full state through `get_sundered_keep_debug_state()`. Real enemy scene spawning remains optional/deferred if the current implementation uses deterministic pressure entities.
</code></pre><p>Adjust to match what was actually implemented.</p><h2>15.2 FILE_INDEX.md</h2><p>Add/refresh entries:</p><pre><code class="language-markdown">- `custodian/game/world/sundered_keep/sundered_keep_siege_controller.gd` — local Sundered Keep siege lifecycle controller for gate-open-triggered waves, objective integrity, pressure ticks, repair cooldown, defensive helper behavior, completion/failure state, and debug state export.

- `custodian/tools/validation/sundered_keep_siege_smoke.gd` — headless smoke test for the Sundered Keep siege controller API, objective damage/repair, and debug state.
  </code></pre><p>Only include the smoke test entry if added.</p><p>Update the existing <code inline="">sundered_keep_map.gd</code> entry to mention siege controller wiring and repair interaction.</p><h2>15.3 Task packet</h2><p>Update:</p><pre><code class="language-text">custodian/docs/ai_context/task_packets/PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md
  </code></pre><p>Set or add:</p><pre><code class="language-markdown">## Implementation Notes

- Existing Sundered Keep map/key/gate/Return Mooring implementation reused.
- Added gate-open-triggered siege lifecycle.
- Added multi-wave pressure progression.
- Added objective integrity for gate, mooring, and sector.
- Added repair interaction.
- Added defensive helper behavior.
- Added debug state fields.
- Added validation attempt/results.
- Deferred:
  - real enemy scene spawning / AI objective routing, if not implemented
  - production art/audio/UI polish
  - save/load persistence for siege state
    </code></pre><p>Add or update:</p><pre><code class="language-markdown">## Completion Notes

- Implemented:
- Validated:
- Deferred:
  </code></pre><p>Add or update:</p><pre><code class="language-markdown">## Next Steps

- Next action:
- Best starting files:
- Required context:
- Validation to run:
- Blockers or open questions:
  </code></pre><p>If acceptance checks are mostly met, set packet status to <code inline="">complete</code> or <code inline="">review</code> depending on repo convention. If Godot validation failed due to unrelated project state, use <code inline="">in_progress</code> or <code inline="">blocked</code> and explain.</p><h2>15.4 Task packet README</h2><p>Update the packet summary in <code inline="">custodian/docs/ai_context/task_packets/README.md</code>.</p><p>If the feature is complete, move it from In Progress to Recently Complete. If validation is incomplete, leave it In Progress and state exactly what remains.</p><hr><h1>16. Required Behavior Acceptance Checklist</h1><p>Before final response, verify and report each item:</p><ul><li><p>Gate remains key-gated.</p></li><li><p>Opening gate starts siege once.</p></li><li><p>Siege has multiple waves or at least a multi-step wave configuration.</p></li><li><p>Pressure targets objectives.</p></li><li><p>Gate/mooring/sector integrity exists.</p></li><li><p>Integrity decreases under pressure.</p></li><li><p>Repair interaction restores damaged objective state.</p></li><li><p>Defense helper participates by reducing pressure or enemies.</p></li><li><p>Siege can complete.</p></li><li><p>Siege can fail.</p></li><li><p><code inline="">get_sundered_keep_debug_state()</code> exposes siege data.</p></li><li><p>Validation was attempted.</p></li><li><p>Docs were updated.</p></li></ul><hr><h1>17. Final Response Format</h1><p>When done, respond exactly in this structure:</p><pre><code class="language-markdown">## Implemented

- Siege lifecycle:
- Wave system:
- Objective integrity:
- Repair gameplay:
- Defensive helper:
- Debug state:
- Documentation:

## Files Changed

- ...

## Key Runtime APIs Added

```gdscript
# Include the main method names/signatures only, not giant code blocks.
</code></pre><h2>How To Test</h2><ol><li><p>Start the game.</p></li><li><p>Enter Sundered Keep.</p></li><li><p>Pick up the Sundered Gate Key.</p></li><li><p>Open the Main Gate.</p></li><li><p>Confirm siege starts.</p></li><li><p>Watch integrity decrease in debug state/logs.</p></li><li><p>Use repair interaction.</p></li><li><p>Confirm defense helper reduces pressure.</p></li><li><p>Confirm siege completes or fails.</p></li></ol><h2>Validation Run</h2><ul><li><p>Command:</p></li><li><p>Result:</p></li></ul><h2>Documentation Drift Found</h2><ul><li><p>Fixed:</p></li><li><p>Still open:</p></li></ul><h2>Deferred / Follow-up</h2><ul><li><p>...</p></li></ul><h2>Current Focus / Last Completed / Next</h2><ul><li><p>Current focus:</p></li><li><p>Last completed:</p></li><li><p>Next:</p></li></ul><pre><code>
Be honest about any validation failure or deferred integration.
</code></pre><p>Current focus: implement the Sundered Keep gatehouse siege loop end-to-end. Last completed: the feature was scoped around existing key-gated gate/Return Mooring runtime. Next: Codex should add the local siege controller, wire it to gate opening, add repair/defense/debug state, validate, and update docs.</p></body></html>
```
