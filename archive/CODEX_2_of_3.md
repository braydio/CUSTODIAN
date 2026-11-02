CUSTODIAN IMPLEMENTATION PASS 2
PROGRESSION + TERMINAL + COGNITIVE SYSTEMS + INVENTORY

IMPLEMENT NOW. Do not return a plan.

Repository:
braydio/CUSTODIAN

Baseline inspected:
4e1b5e57080d53be2ea8ebd005bab6d4e2025bcf

Assume Pass 1 has landed.
Re-read current HEAD and adapt paths only if Pass 1 legitimately changed them.

MISSION

Resolve remaining gameplay implementation for NOTES:
4, 7, 9, 10, 12, 13

Work:

1. make Home/lost-terminal scene the actual game opening
2. fix terminal content/map ordering bug
3. implement a real command-terminal repair tutorial
4. let selected enemies locally seek reachable cognitive residue
5. expose cognitive accumulation through immediate/threshold visual feedback
6. add GLANCE / DETAIL inspection modes to current inventory

Do not rebuild systems that already exist.

============================================================
A. PROMOTE HOME TO ACTUAL GAME BOOT
============================================================

CURRENT:

custodian/project.godot

    run/main_scene="res://scenes/game.tscn"

But the authored pre-procgen beginning already exists:

    custodian/scenes/home_custodian_begin.tscn

with:

    custodian/game/world/home/
        custodian_home_begin.gd
        field_terminal_interactable.gd

CustodianHomeBegin already:

- positions Operator
- presents the signal needle
- tracks signal bands
- establishes witness on first Field Terminal interaction
- receives terminal_access_requested on later interaction

Do not build another introduction.

EDIT:
custodian/project.godot

Set:

    run/main_scene=\
        "res://scenes/home_custodian_begin.tscn"

EDIT:
custodian/game/world/home/custodian_home_begin.gd

Add:

    @export_file("*.tscn")
    var next_scene_path := \
        "res://scenes/game.tscn"

    var _transition_committed := false

The FIRST Field Terminal interaction must continue to establish witness.

The SECOND interaction, which already produces
terminal_access_requested, becomes the handoff.

Implement:

    func _on_terminal_access_requested(
        _actor: Node
    ) -> void:
        if _transition_committed:
            return

        _transition_committed = true

        if hud != null:
            hud.set_debug_overlay_visible(false)
            hud.show_interaction(
                "ARCHIVE PARTIAL",
                "Operational Custodian node located.",
                _get_interact_prompt_key(),
                Catalog.ICON_OBJECTIVE
            )

        call_deferred("_enter_operational_world")

    func _enter_operational_world() -> void:
        if (
            next_scene_path.is_empty()
            or not ResourceLoader.exists(
                next_scene_path
            )
        ):
            push_error(
                "[CustodianHomeBegin] Missing next scene: %s"
                % next_scene_path
            )
            _transition_committed = false
            return

        get_tree().change_scene_to_file(
            next_scene_path
        )

Do not transition merely by proximity.
Do not skip witness establishment.

Game-over restart currently reloads the current scene, so dying inside game.tscn will restart operational game rather than unexpectedly replaying Home. Preserve that behavior.

Extend:
custodian_home_begin_smoke.gd

Assert:

- ProjectSettings main scene == Home beginning
- first terminal interaction establishes witness
- first interaction does NOT transition
- second interaction commits transition
- transition cannot fire twice
- target is game.tscn

============================================================
B. FIX TERMINAL PAGE FLIPPING AT THE ACTUAL ROOT CAUSE
============================================================

EDIT:
custodian/game/ui/hud/ui.gd

CURRENT BUG:

\_apply_terminal_page_layout() reparents MapPreviewTitle and MapPreview individually and then does:

    var widget_index :=
        terminal_widget_stack.get_index()

    content_column.move_child(
        terminal_map_preview_title_label,
        widget_index
    )

    content_column.move_child(
        terminal_map_preview,
        mini(
            widget_index + 1,
            content_column.get_child_count() - 1
        )
    )

This is unstable because the first move changes sibling indexes before the second move and before the next refresh.
Repeated calls can invert which content is above/below the map.

DEFENSE, POWER and SENSORS are therefore not allowed to mutate sibling ordering during snapshot refresh.

Create one stable container:

    var _terminal_map_preview_block: \
        VBoxContainer = null

During terminal scroll-layout construction, ensure:

    MainContentScroll
    └── Content
        ├── WidgetStack
        └── MapPreviewBlock
            ├── MapPreviewTitle
            └── MapPreview

Create MapPreviewBlock once.

Reparent title + preview INTO THE BLOCK once.

For OVERVIEW:
reparent the WHOLE MapPreviewBlock to:
terminal_overview_map_slot

For every non-overview page:
reparent the WHOLE MapPreviewBlock back under:
MainContentScroll/Content

and keep it after WidgetStack.

Never individually move MapPreviewTitle and MapPreview around Content again.

Recommended helper:

    func _ensure_terminal_map_preview_block(
        content_column: VBoxContainer
    ) -> VBoxContainer:
        if (
            _terminal_map_preview_block != null
            and is_instance_valid(
                _terminal_map_preview_block
            )
        ):
            return _terminal_map_preview_block

        _terminal_map_preview_block = \
            VBoxContainer.new()
        _terminal_map_preview_block.name = \
            "MapPreviewBlock"

        content_column.add_child(
            _terminal_map_preview_block
        )

        terminal_map_preview_title_label.reparent(
            _terminal_map_preview_block
        )
        terminal_map_preview.reparent(
            _terminal_map_preview_block
        )

        return _terminal_map_preview_block

Then \_apply_terminal_page_layout() changes only the block's parent.

Also:
REMOVE unconditional:

    _terminal_main_scroll.scroll_vertical = 0

from layout-refresh code.

Scroll may reset to zero on an ACTUAL page transition in \_set_terminal_page(), not on every data refresh.

Add regression:

    terminal_page_order_regression_smoke.gd

Cycle:

    POWER
    DEFENSE
    SENSORS
    POWER
    SENSORS
    DEFENSE

with refreshes between transitions.

Assert:

- one MapPreview exists
- one MapPreviewTitle exists
- both retain MapPreviewBlock parent
- non-overview block remains after WidgetStack
- content order never flips
- snapshot refresh does not reset user scroll
- actual page transition may reset scroll

============================================================
C. COMMAND TERMINAL TUTORIAL
============================================================

IMPORTANT CURRENT-RUNTIME CORRECTIONS:

Do NOT teach:
REPAIR COMMAND

Current game.tscn static sectors are:
POWER
DEFENSE
ARCHIVE
STORAGE
transit sectors

There is no static COMMAND sector.

Teach:
REPAIR DEFENSE

Also DO NOT drain stored power to zero.

Power.gd currently charges:

    emergency_repair_power_cost = 25.0

and rejects repair when stored power is below that cost.

The tutorial should produce a BROWNOUT, not a mechanically impossible zero-power state.

CREATE:

    custodian/game/tutorial/
        command_terminal_tutorial.gd

Add it as a Node under GameRoot in:

    custodian/scenes/game.tscn

Use:

    const EVENT_ID := \
        &"command_terminal_repair_tutorial_complete"

Gate with existing:
/root/WorldEventMemory

which exposes:
is_completed()
mark_completed()

This is run-scoped persistence, which is sufficient for the current runtime.

Tutorial startup should wait until:

- GameRoot/Power exists
- World/Sectors/DEFENSE exists
- UI exists

If event already complete:
disable tutorial immediately.

SETUP:

Use the real DEFENSE Sector API:

    defense.take_damage(55.0)

Do not directly set its state string.

This takes 100 HP -> 45 HP, putting the actual Damageable state into "damaged".

Set stored tutorial reserve to a low but valid amount:

    power.total_power = maxf(
        power.emergency_repair_power_cost + 15.0,
        40.0
    )

Do not modify emergency_repair_power_cost.

============================================================
D. EXPOSE TERMINAL COMMAND COMPLETION
============================================================

EDIT:
custodian/game/ui/hud/ui.gd

Add:

    signal terminal_command_executed(
        normalized_command: String,
        handled: bool
    )

In:

    _execute_terminal_command_buffered(
        parsed
    )

the current flow already calls:

    var handled :=
        _terminal_command_router.execute(
            self,
            parsed
        )

Immediately after that call:

    terminal_command_executed.emit(
        cmd_upper,
        handled
    )

Add a small public wrapper for tutorial copy rather than making the tutorial call private methods:

    func append_terminal_tutorial_line(
        text: String,
        kind: String = "info"
    ) -> void:
        _append_terminal_line(text, kind)

Tutorial flow:

STATE 0
wait for player to access terminal
display:
LOCAL POWER RESERVE DEGRADED.
RUN STATUS.

STATE 1
player must execute:
STATUS

    Any other valid command still works normally.
    It simply does not advance tutorial.

After STATUS:
display:
DEFENSE GRID INTEGRITY DEGRADED.
EMERGENCY REPAIR AUTHORIZED.
RUN: REPAIR DEFENSE

STATE 2
record defense HP immediately before repair command

    require normalized command:
        REPAIR DEFENSE

    handled == true is not alone sufficient.

After command:
verify:
defense.current_health >
hp_before_repair

Only then:

    WorldEventMemory.mark_completed(
        EVENT_ID,
        {
            "sector": "DEFENSE",
            "command": "REPAIR DEFENSE",
        }
    )

and output:
REPAIR CONFIRMED.
LOCAL COMMAND AUTHORITY ACCEPTED.

The tutorial must use:
TerminalCommandRouter
UI's real command execution
Power.apply_emergency_repair()
Sector.heal()/repair()

Do not fake the repair.

============================================================
E. COGNITIVE RESIDUE BECOMES A LOCAL ENEMY OBJECTIVE
============================================================

CURRENT AUTHORITIES:

    cognitive_pickup.gd
        physical residue pickup

    InventoryItemCatalog
        item definition / cognitive_axis

    EnemyObjectiveSensor
        strategic objective scoring

    EnemyBehaviorStateMachine
        strategic state ownership

    EnemyBlackboard
        current objective state

    NavigationSystem
        reachability/path authority

Do not create a global cognitive-residue manager.

EDIT:
custodian/game/actors/items/cognitive_pickup.gd

Preload:
res://game/ui/inventory/
inventory_item_catalog.gd

\_ready():

    add_to_group("cognitive_residue_pickup")

Add:

    func get_cognitive_axis() -> StringName:
        var definition := \
            InventoryItemCatalog.get_definition(
                item_id
            )

        return StringName(
            str(
                definition.get(
                    "cognitive_axis",
                    ""
                )
            )
        )

    func can_enemy_consume(
        enemy: Node
    ) -> bool:
        return (
            enemy != null
            and is_instance_valid(enemy)
            and not is_queued_for_deletion()
        )

    func consume_by_enemy(
        enemy: Node
    ) -> Dictionary:
        if not can_enemy_consume(enemy):
            return {}

        var result := {
            "item_id": item_id,
            "axis": get_cognitive_axis(),
            "quantity": quantity,
        }

        queue_free()
        return result

Enemy consumption MUST NOT call:
InventoryManager.add_item()
CognitiveState.add_from_item()

============================================================
F. PROFILE-GATE RESIDUE INTEREST
============================================================

EDIT:
custodian/game/actors/enemies/components/
enemy_behavior_profile.gd

Add:

    @export_category("Cognitive Residue")
    @export var can_seek_cognitive_residue := false
    @export var cognitive_residue_weight := 0.0
    @export var cognitive_residue_awareness_radius_px := 360.0
    @export var cognitive_residue_consume_range_px := 26.0
    @export var cognitive_residue_buff_duration_sec := 8.0

Do NOT enable this for every hostile.

For first implementation:

- enable for zealot_wanderer
- leave default raider_grunt disabled
- leave marine disabled
- leave savage disabled unless existing design specifically says otherwise

Recommended zealot values:

    can_seek_cognitive_residue = true
    cognitive_residue_weight = 0.80
    cognitive_residue_awareness_radius_px = 380.0
    cognitive_residue_consume_range_px = 26.0
    cognitive_residue_buff_duration_sec = 8.0

This establishes the ecology without making every hostile omniscient.

============================================================
G. OBJECTIVE SCORING
============================================================

EDIT:
custodian/game/actors/enemies/components/
enemy_objective_sensor.gd

Add:
cognitive_residue

to choose_objective scores.

Implement:

    _score_cognitive_residue_objective(
        enemy,
        profile,
        blackboard
    ) -> Dictionary

Rules:

Return zero if:

- can_seek_cognitive_residue == false
- enemy is carrying stolen loot
- enemy is currently alerted to Operator
- no residue inside awareness radius

Inspect only nearby candidates from:
cognitive_residue_pickup

Cap candidate scoring to a sane count, e.g. nearest 12-16.

A residue candidate is valid only if:

1. within cognitive_residue_awareness_radius_px
2. valid Node2D
3. NavigationSystem can produce an authoritative path to it

Do not score merely by Euclidean distance and then discover it is across a chasm.

Recommended score:

    base =
        cognitive_residue_weight * 100.0

    distance_ratio =
        distance / awareness_radius

    score =
        maxf(
            0.0,
            base - distance_ratio * 45.0
        )

Return:
{
"score": score,
"target": residue
}

Set the returned target when best_type is:
&"cognitive_residue"

============================================================
H. BEHAVIOR STATES FOR RESIDUE
============================================================

EDIT:
custodian/game/actors/enemies/
enemy_blackboard.gd

Add:

    var target_cognitive_residue: Node = null
    var cognitive_residue_axis: StringName = &""
    var cognitive_residue_buff_timer := 0.0

Include them in debug snapshot.

EDIT:
custodian/game/actors/enemies/
enemy_behavior_state_machine.gd

Add:

    const SEEK_COGNITIVE_RESIDUE := \
        &"seek_cognitive_residue"

    const CONSUME_COGNITIVE_RESIDUE := \
        &"consume_cognitive_residue"

Teach objective selection:
type == &"cognitive_residue"
stores the target and changes to SEEK_COGNITIVE_RESIDUE.

SEEK behavior:

FIRST:
evaluate existing immediate Operator interrupts

Operator combat always wins.

Then:

- validate target
- if invalid -> clear objective -> PATROL/IDLE
- if farther than consume range:
  behavior_move_toward(
  residue.global_position,
  profile.objective_speed
  )
- if movement returns false:
  clear target
  record unreachable navigation
  return to PATROL
- if within range:
  CONSUME_COGNITIVE_RESIDUE

CONSUME:
result =
residue.consume_by_enemy(enemy)

    if result empty:
        clear and return PATROL

    blackboard.cognitive_residue_axis =
        result.axis

    blackboard.cognitive_residue_buff_timer =
        profile.cognitive_residue_buff_duration_sec

Then clear target/current cognitive objective and resume normal behavior.

No enemy can continue chasing an already-freed pickup.

============================================================
I. SMALL, BOUNDED RESIDUE BUFF
============================================================

Keep v1 modest.

Store the temporary state on EnemyBlackboard.

While timer > 0:

RECOLLECTION:
EnemyPerceptionComponent:
+10% effective hearing/vision range
+20% investigation memory

INSTINCT:
EnemyBehaviorStateMachine:
multiply movement speeds it requests by 1.12

BEARING:
increase non-alerted operator-awareness bubble by 12%
while scoring Operator

Do not mutate the shared behavior profile resource in-place.

Compute temporary multipliers at read-time based on blackboard.cognitive_residue_axis.

Timer expires in BehaviorStateMachine physics_update:
decrement
when <= 0:
axis = &""

Add Observatory events:
enemy_cognitive_residue_targeted
enemy_cognitive_residue_consumed
enemy_cognitive_residue_unreachable

============================================================
J. PLAYER COGNITIVE THRESHOLD PRESENTATION
============================================================

EDIT:
custodian/game/systems/cognitive/
cognitive_state_system.gd

Current gameplay modifiers use NORMALIZED axis weights.
Do not change those balance semantics.

Presentation thresholds should use RAW axis magnitude.

Add:

    signal cognitive_threshold_changed(
        axis: StringName,
        old_tier: int,
        new_tier: int,
        value: float
    )

Add:

    @export var feedback_threshold := 3.0
    @export var saturation_threshold := 6.0

Track:

    var _axis_tiers := {
        &"recollection": 0,
        &"instinct": 0,
        &"bearing": 0,
    }

Expose:

    func get_axis_value(
        axis: StringName
    ) -> float

    func get_axis_tier(
        axis: StringName
    ) -> int

    func get_axis_intensity(
        axis: StringName
    ) -> float:
        return clampf(
            get_axis_value(axis)
            / maxf(
                saturation_threshold,
                0.001
            ),
            0.0,
            1.0
        )

Tier:
0: < feedback_threshold
1: >= feedback_threshold
2: >= saturation_threshold

On each value mutation/decay:
compare old/new tier and emit only when tier changes.

Preserve:
cognitive_item_collected

That signal drives the immediate pickup flash.

============================================================
K. WORLD-ONLY COGNITIVE FEEDBACK OVERLAY
============================================================

CREATE:

    custodian/game/ui/cognitive/
        cognitive_feedback_overlay.tscn
        cognitive_feedback_overlay.gd
        shaders/cognitive_feedback_overlay.gdshader

Root:
CanvasLayer
layer = 10

Operational UI in game.tscn is layer 20.
Therefore the effect modifies world presentation while terminal/inventory remain readable above it.

Inside:
full-screen ColorRect
mouse_filter = IGNORE

Shader:

- screen texture sampling
- subtle lateral/UV displacement
- axis tint
- vignette/peripheral strength
- intensity parameter

Use existing cognitive color identity:

    recollection:
        Color(0.62, 0.82, 1.0)

    instinct:
        Color(0.95, 0.55, 0.38)

    bearing:
        Color(0.86, 0.72, 1.0)

Presentation:

cognitive_item_collected:
0.20 sec pulse
intensity ~0.18-0.25

tier 0 -> 1:
0.45 sec stronger pulse

tier 1 -> 2:
0.8-1.0 sec major overlay event
then settle to subtle persistent
intensity ~0.08-0.12

tier decrease:
fade persistent contribution down

Do not permanently obscure combat.
No bitmap assets required.

Add instance under GameRoot in game.tscn.

============================================================
L. INVENTORY GLANCE / DETAIL
============================================================

DO NOT rebuild inventory.

Current:
inventory_ui.gd

already has:
STATUS
EQUIPMENT
LEDGER
HISTORY

and a Ledger detail panel with:
icon
name
class
count
description
use
provenance
equip action

Use this.

Add:

    enum InspectionMode {
        GLANCE,
        DETAIL,
    }

    var _inspection_mode := \
        InspectionMode.GLANCE

When Ledger page is active:
TAB keyboard
JOY_BUTTON_Y controller

toggles GLANCE/DETAIL.

GLANCE displays:

- item portrait/icon
- name
- category/class
- quantity
- one concise mechanical/use summary

For cognitive items also display:

- cognitive axis
- current raw value from /root/CognitiveState
- current dominant state
- currently applicable player bonuses

For equipment:

- headline stats already supported by actual item/weapon definition
- equipped status

For resources:

- quantity / known use category

DETAIL adds:

- full authored description
- provenance
- secondary/mechanical detail
- cognitive modifier breakdown
- equipment deltas where actual data exists

DO NOT invent stats missing from item definitions.

Prefer helper methods:
\_build_glance_summary(...)
\_build_detail_summary(...)
\_build_cognitive_item_summary(...)

Use:
InventoryItemCatalog
InventoryAssetCatalog
CognitiveState

Do not add another item-definition dictionary inside InventoryUI.

Update footer prompts:
[TAB] DETAIL / GLANCE
or controller Y equivalent.

============================================================
VALIDATION
============================================================

Create/run:

    terminal_page_order_regression_smoke.gd
    command_terminal_tutorial_smoke.gd
    cognitive_residue_enemy_objective_smoke.gd
    cognitive_threshold_feedback_smoke.gd
    inventory_inspection_mode_smoke.gd

Run existing:

    custodian_home_begin_smoke.gd
    terminal_overview_layout_smoke.gd
    sensors_terminal_smoke or current equivalent
    inventory_ui_smoke.gd
    cognitive_state_smoke.gd if present
    enemy_behavior_state_machine smoke suite

Acceptance:

HOME

- application boots into Home
- first terminal interaction establishes witness
- second enters operational game exactly once

TERMINAL LAYOUT

- POWER/DEFENSE/SENSORS never invert map/content ordering
- refresh cannot mutate layout order

TUTORIAL

- tutorial uses STATUS
- tutorial teaches REPAIR DEFENSE
- DEFENSE HP really increases
- real power cost is paid
- tutorial never depends on zero stored power

RESIDUE ECOLOGY

- only opted-in profiles seek residue
- no global omniscient seeking
- unreachable residue ignored/abandoned
- Operator alert interrupts residue pursuit
- enemy consumes reachable nearby residue
- temporary buff expires

COGNITIVE PRESENTATION

- normal pickup has brief feedback
- raw threshold crossing has stronger feedback
- terminal/inventory remain unaffected by world shader

INVENTORY

- GLANCE is concise
- DETAIL exposes full authored information
- cognitive quantities/state are visible
- no duplicate item data source

DOCUMENTATION:
Update relevant active design specs first where semantics changed.
Then update:
custodian/docs/ai_context/CURRENT_STATE.md

Do not do the final root NOTES cleanup yet.
Pass 3 owns final reconciliation.
