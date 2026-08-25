CUSTODIAN IMPLEMENTATION PASS 3
GAMEPLAY NOTES RECONCILIATION + PRESENTATION CONTRACTS + DEBUGGING + DOCS

IMPLEMENT NOW. Do not return a plan.

Repository:
braydio/CUSTODIAN

Start from current HEAD after Passes 1 and 2.

This pass should be economical.
Do not redesign systems that the previous passes have made correct.

MISSION

Finish NOTES:
1, 2, 3, 16, 17

Then reconcile root NOTES and current documentation against reality.

============================================================
A. CANONICALIZE COGNITIVE PICKUP ICON AUTHORITY
============================================================

CURRENT:

cognitive_pickup.gd correctly separates:

- ITEM_ANIMATION_TEXTURES
- ITEM_TOAST_ICONS

So the original note claiming the toast literally uses the world spritesheet is stale.

However, cognitive_pickup.gd still hardcodes its own toast icon table.

The canonical inventory authority already exists:

    custodian/game/ui/inventory/
        inventory_asset_catalog.gd

and exposes:

    item_icon_path(item_id)
    item_icon(item_id)
    item_portrait(item_id)

Canonical runtime inventory icons already exist for Shrumb cognitive items, including:

    content/ui/inventory/runtime/icons/
        icon_faint_recollection.png

and equivalent item IDs.

EDIT:
custodian/game/actors/items/
cognitive_pickup.gd

Add:

    const InventoryAssets := preload(
        "res://game/ui/inventory/"
        + "inventory_asset_catalog.gd"
    )

Delete:
ITEM_TOAST_ICONS

Replace toast icon lookup with:

    var toast_icon := InventoryAssets.item_icon(
        String(item_id)
    )

    _show_loot_toast(
        item_id,
        _get_display_name(),
        quantity,
        ITEM_COLORS.get(
            item_id,
            Color.WHITE
        ),
        toast_icon,
        "Cognitive imprint secured"
    )

Do not alter world animation textures.

Run loot toast and inventory asset validation.

============================================================
B. PROCGEN ENDLESS-FOREST / VOID PRESENTATION
============================================================

DO NOT commission replacement art in this pass.

The live runtime already contains the architecture that the old note said still needed to be built:

    custodian/game/world/procgen/presentation/
        procgen_depth_backdrop.gd
        procgen_void_cliff_face.gd

    custodian/game/world/procgen/presentation/
        underlays/endless_forest_underlay.tres

Existing Endless Forest profile already uses three authored:
1536x1024
1-frame
layers:

    content/backgrounds/procgen/endless_forest/
        endless_forest_depth_haze_1536x1024.png
        endless_forest_canopy_mass_1536x1024.png
        endless_forest_wall_growth_1536x1024.png

Current DepthBackdrop:

- lives at absolute z -300
- follows camera
- supports explicit chasm cells
- uses world-fallback only as compatibility

Current VoidCliffFace:

- only paints explicit chasm cells
- uses dedicated presentation source IDs 149-154
- does not own gameplay navigation/collision

The remaining job is contract hardening and visual evidence.

Extend:

    custodian/tools/validation/
        procgen_void_cliff_face_smoke.gd

Create if useful:

    procgen_wall_role_separation_smoke.gd

Assert:

1. regular Walls layer never uses source IDs 149-154
2. VoidCliffFace cells are members of explicit chasm semantics
3. fascia never paints playable floor
4. VoidCliffFace collision_enabled == false
5. VoidCliffFace navigation_enabled == false
6. normal wall source remains separate from void fascia
7. underlay profile resolves all three textures
8. explicit chasm generation selects chasm presentation rather than world fallback
9. no raw clear-color edge is visible within supported camera bounds

Do not replace regular ruin walls with fascia.
Do not replace fascia with regular ruin walls.
They have different semantic roles.

Run representative multi-seed presentation capture.

If a visual defect remains after semantic tests pass:
fix the compositor/z/presentation bug demonstrated by the capture.
Do not merge wall/fascia asset roles.

============================================================
C. PORTALS: CANONIZE EXISTING V1 ROLE
============================================================

Do not implement a new portal network in this pass.

Current:
custodian/game/world/procgen/
portal_teleporter.gd

already has:

- linked portals
- deterministic cooldown
- activation/arrival animation
- transition veil
- player teleport
- arrival positioning

The previous completed portal packet defines current v1 scope as paired traversal INSIDE the active tactical map.

Canonize the gameplay role as:

    Procgen portals are local tactical traversal shortcuts.
    They provide long-range repositioning across the current generated map.

Do NOT deliberately force:
portal at player spawn
↔
portal inside Sundered Keep

through the local procgen-pair implementation.

Cross-map / Home / Sundered Keep portal travel requires authored world-route authority and remains a separate future design.

Update CURRENT_STATE / relevant active portal design wording if needed.
Do not edit historical archived completion packets except to add a clear pointer from active docs.

Mark root NOTES #3 resolved for current v1 scope.

============================================================
D. LOCK WALL / FASCIA ROLE SEPARATION
============================================================

This is NOTES #16.

Current architecture already distinguishes them.

ProcGenMap has ordinary gameplay Walls.

Void fascia uses dedicated presentation IDs 149-154.

Make that distinction regression-proof.

Add validation that fails if:

    regular wall cells use any source 149-154

or:

    VoidCliffFace is given collision/navigation authority

or:

    fascia paints a non-chasm cell

or:

    gameplay walkability is derived from fascia presentation.

Do not blindly swap assets during this pass.

If the original reported regression can still be reproduced,
capture the exact tile/source/layer at the bad location and fix the responsible renderer.

============================================================
E. RITUALANT DEBUG MINIMAP MARKER
============================================================

EDIT:
custodian/game/world/approaches/ash_bell/
ash_bell_lift_ingress_site.gd

In \_ready():

    super._ready()

    if OS.is_debug_build():
        add_to_group(
            "debug_minimap_ritualant_ingress"
        )

The surface AshBellLiftIngressSite is the useful debug destination.
Do not mark the underground room itself as the procgen map POI.

EDIT:
custodian/game/ui/minimap/
minimap_controller.gd

Add:

    @export var debug_marker_group_name: \
        StringName = \
        &"debug_minimap_ritualant_ingress"

In \_refresh_dynamic_nodes():

    var debug_markers: Array[Node2D] = []

    if OS.is_debug_build():
        for node in get_tree().get_nodes_in_group(
            debug_marker_group_name
        ):
            if node is Node2D:
                debug_markers.append(
                    node as Node2D
                )

    if minimap_view.has_method(
        "set_debug_markers"
    ):
        minimap_view.call(
            "set_debug_markers",
            debug_markers
        )

EDIT:
custodian/game/ui/minimap/
minimap_view.gd

Add:

    @export var debug_marker_color := \
        Color(0.95, 0.35, 0.95, 1.0)

    var debug_marker_nodes: Array = []

    func set_debug_markers(
        nodes: Array
    ) -> void:
        debug_marker_nodes = \
            _filter_valid_node2d_array(nodes)
        _request_redraw()

Include them in \_get_dynamic_signature().

In \_draw(), before player pip:

    _draw_debug_markers(map_rect)

Implement using existing primitive helpers.
Use a distinctive ring + cross or ring + diamond.
Do not require a bitmap asset.

Example:

    func _draw_debug_markers(
        map_rect: Rect2
    ) -> void:
        if not OS.is_debug_build():
            return

        for marker in debug_marker_nodes:
            if not _is_valid_node2d(marker):
                continue

            var tile := _global_to_tile(
                marker.global_position
            )

            if not _is_tile_inside(tile):
                continue

            var p := _tile_to_panel(
                tile,
                map_rect
            )

            draw_arc(
                p,
                utility_marker_radius_px + 3.0,
                0.0,
                TAU,
                16,
                debug_marker_color,
                1.5
            )

            _draw_cross_marker(
                p,
                debug_marker_color
            )

No release-build marker.

Add:
ritualant_debug_minimap_marker_smoke.gd

============================================================
F. ROOT NOTES RECONCILIATION
============================================================

Now update root:
NOTES

Do not simply delete historical intent.
Turn Gameplay Notes into an actual current backlog.

Recommended status labels:

    [DONE]
    [PARTIAL]
    [ACTIVE]
    [DESIGN]

After Passes 1-3, reconcile:

#1
DONE:
pickup toast infrastructure + canonical icon authority

#2
PARTIAL/DESIGN:
underlay/fascia architecture implemented;
visual composition/presentation continues as art-direction polish if captures warrant it

#3
DONE V1:
local tactical portal traversal
Cross-map network remains future design.

#4
DONE:
Home/lost-terminal beginning is actual boot flow

#6/#8
DONE runtime contract:
ambient actor spawning projects to runtime-safe walkability;
pathfinding remains authoritative

#7
DONE:
selected profiles locally seek reachable cognitive residue

#9
DONE:
cognitive pickup/threshold presentation + inspectable state

#10
DONE current pass:
inventory GLANCE/DETAIL hierarchy

#11
DONE:
point-blank melee dead zone repaired
Sidearm spacing remains optional design consideration, not required fix.

#12
DONE:
terminal page ordering stable

#13
DONE:
live STATUS -> REPAIR DEFENSE tutorial

#14
DONE runtime:
Buggy safe exit + turn_response
Leave further feel tuning as DESIGN if needed.

#15
DONE runtime:
camp scale fixed
direct-hit notice guaranteed
gun noise preserved
noncombat patrol verified
startup debug grunt disabled

#16
DONE contract:
ordinary walls and void fascia separated and regression-tested

#17
DONE debug:
Ritualant surface ingress minimap marker

Preserve any genuinely unresolved art/playtest questions as DESIGN rather than pretending all subjective polish is finished.

============================================================
G. DOCUMENTATION DRIFT REVIEW
============================================================

Required review/update:

    custodian/docs/ai_context/CURRENT_STATE.md
    custodian/docs/ai_context/FILE_INDEX.md

Also inspect active design docs touched by Passes 1/2.

Known drift to explicitly correct:

1. Shrumb docs that imply CognitiveState or inventory integration does not exist.
2. Home beginning docs that call actual boot promotion "deferred".
3. Portal active docs that imply no gameplay role despite working paired local teleport.
4. Any procgen docs that conflate ordinary gameplay walls with void fascia.
5. Any NOTES language that describes implemented toast plumbing as absent.

Do not rewrite historical python-sim/archive material as current truth.
Historical docs may remain historical.

============================================================
VALIDATION
============================================================

Run:

    loot_toast_queue_smoke.gd
    inventory_ui_smoke.gd
    procgen_void_cliff_face_smoke.gd
    elevated_world_asset_contract_smoke.gd
    ritualant_debug_minimap_marker_smoke.gd
    forlorn_ritualant_completion_smoke.gd

Also run the repository changed-file validation suite.

For procgen presentation:
capture at least 5 representative seeds or the existing repository-standard presentation evidence equivalent.

Final report must distinguish:

    CODE FIXED
    CONTRACT PROVEN
    DESIGN/POLISH STILL OPEN

Do not mark subjective art-direction work complete merely because a smoke test passed.

Return:

1. changed files
2. tests
3. updated NOTES status
4. documentation drift corrected
5. any genuinely remaining gameplay-note item
