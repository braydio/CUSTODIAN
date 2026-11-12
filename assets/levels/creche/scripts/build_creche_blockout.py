"""Build the Creche architectural blockout in Blender 4.x.

Run:
 blender --background --factory-startup --python scripts/build_creche_blockout.py

This builds ORIGINAL editable placeholder geometry. All AI assets are reserved as
sockets and are NOT assumed to have the dimensions or topology specified here.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parent.parent
REFS = ROOT / 'references'
BUILD = ROOT / 'build'
BUILD.mkdir(parents=True, exist_ok=True)

SOURCE_W = 960
SOURCE_H = 704
PPM = 32.0
WALL_H = 5.25
WALL_T = 0.75
NORTH_WALL_Y = 4.75
SOUTH_WALL_Y = -9.0
WEST_WALL_X = -13.375
EAST_WALL_X = 13.375
INTERIOR = {'xmin': -13.0, 'xmax': 13.0, 'ymin': -8.625, 'ymax': 4.375}


def wx(px):
    return (px - 480.0) / PPM


def wy(py):
    return (352.0 - py) / PPM


def v2px(x, y):
    return (480.0 + PPM*x, 352.0 - PPM*y)


def collection(name):
    c = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(c)
    return c


def move(obj, c):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    c.objects.link(obj)
    return obj


def material(name, rgba, metallic=0.0, roughness=0.85):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = rgba
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    return mat


def image_material(name, path):
    mat = material(name, (0.8, 0.8, 0.8, 1.0))
    nodes = mat.node_tree.nodes
    tex = nodes.new('ShaderNodeTexImage')
    tex.image = bpy.data.images.load(str(path), check_existing=True)
    mat.node_tree.links.new(tex.outputs['Color'], nodes.get('Principled BSDF').inputs['Base Color'])
    return mat


def box(name, center, dimensions, coll, mat=None, wire=False, hide_render=False):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    move(obj, coll)
    if mat:
        obj.data.materials.append(mat)
    if wire:
        obj.display_type = 'WIRE'
        obj.show_in_front = True
    obj.hide_render = hide_render
    return obj


def textured_plane(name, bounds, z, coll, mat):
    xmin, xmax, ymin, ymax = bounds
    verts = [(xmin,ymin,z),(xmax,ymin,z),(xmax,ymax,z),(xmin,ymax,z)]
    mesh = bpy.data.meshes.new(name + '_mesh')
    mesh.from_pydata(verts,[],[(0,1,2,3)])
    mesh.update()
    uv_layer = mesh.uv_layers.new(name='UVMap')
    # Source image occupies 30 by 22 world units with its pixel center at (0,0).
    for poly in mesh.polygons:
        for loop_index in poly.loop_indices:
            v = mesh.vertices[mesh.loops[loop_index].vertex_index].co
            uv_layer.data[loop_index].uv = ((v.x + 15.0)/30.0, (v.y + 11.0)/22.0)
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    mesh.materials.append(mat)
    return obj


def empty_group(name, center, coll):
    obj = bpy.data.objects.new(name, None)
    obj.location = center
    coll.objects.link(obj)
    obj.empty_display_type = 'CUBE'
    obj.empty_display_size = 0.25
    return obj


def socket(name, center, dims, hint, kind='architectural', source_px=None):
    obj = box('SOCKET__' + name, center, dims, SOCKETS, MAT_SOCKET,
              wire=True, hide_render=True)
    obj['asset_hint'] = hint
    obj['socket_type'] = kind
    obj['size_m'] = list(dims)
    obj['authoritative_asset'] = False
    if source_px:
        obj['reference_center_px'] = list(source_px)
    SOCKET_DEFS.append({
        'id': name, 'type': kind, 'center_m': list(center),
        'size_m': list(dims), 'asset_hint': hint,
        'source_center_px': list(source_px) if source_px else None,
        'status': 'RESERVED_NOT_POPULATED',
    })
    return obj


def zone(name, center, dimensions, notes):
    ob = box('ZONE__' + name, center, dimensions, ZONES,
             MAT_ZONE, wire=True, hide_render=True)
    ob['notes'] = notes
    ZONE_DEFS.append({'id':name, 'center_m':list(center), 'size_m':list(dimensions), 'notes':notes})
    return ob


bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
    if c.name in bpy.data.collections and not c.objects and not c.children:
        bpy.data.collections.remove(c)

scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene.unit_settings.length_unit = 'METERS'

REF = collection('00_REFERENCES_2D')
FLOORS = collection('01_FLOOR_AND_COLLISION')
SHELL = collection('02_STRUCTURAL_WALLS_AND_PIERS')
SOCKETS = collection('03_ART_SOCKETS__REPLACE_WITH_GLB')
ZONES = collection('04_GAMEPLAY_AND_CLEARANCE_ZONES')
CAMERAS = collection('05_CAMERAS_AND_LIGHTS')
ART = collection('06_IMPORTED_ART__EMPTY')
SOCKET_DEFS=[]
ZONE_DEFS=[]

MAT_STONE = material('M_BLOCKOUT_DARK_STONE', (0.24,0.25,0.27,1))
MAT_PIER = material('M_BLOCKOUT_LIGHT_PIER', (0.35,0.36,0.37,1))
MAT_SOCKET = material('M_SOCKET_ORANGE', (0.95,0.45,0.08,1))
MAT_ZONE = material('M_ZONE_BLUE', (0.08,0.50,0.80,1))
MAT_FLOOR = image_material('M_SOURCE_FLOOR_PROJECTED', REFS/'creche_floor_960x704.png')

# Reference plane for easy toggling. It is deliberately outside the game export.
ref_floor = textured_plane('REF__Full_Floor_2D_Source', (-15,15,-11,11), -0.08, REF, MAT_FLOOR)
ref_floor.hide_render = True
# Actual walkable art uses the source pixel-to-meter UV mapping, WITHOUT stretching.
textured_plane('GEO__Interior_Floor_Mapped', (-13,13,-8.625,4.375), 0.0, FLOORS, MAT_FLOOR)
box('COLLIDER__Interior_Floor', (0,-2.125,-0.125), (26,13,.25), FLOORS,
    None, wire=True, hide_render=True)
# Entry continuation beyond the south wall, to reserve a playable threshold.
textured_plane('GEO__South_Threshold_Floor_Mapped',(-1.25,1.25,-10.25,-8.625),0.0,FLOORS,MAT_FLOOR)
box('COLLIDER__South_Threshold_Floor',(0,-9.4375,-0.125), (2.5,1.625,.25),FLOORS,
    None,wire=True,hide_render=True)

# North wall, three REAL through-window rectangles. Pointed/ornamental arches
# remain artistic assets to replace the conservative rectangular blockout.
window_bays = [(-1.85,1.35),(0.0,1.35),(1.85,1.35)]
sill_h, opening_top = 1.35, 4.05
x0 = -13.75
for n, (cx,w) in enumerate(window_bays):
    left, right = cx-w/2, cx+w/2
    if left > x0:
        box(f'GEO__North_FullHeight_{n}',((x0+left)/2,NORTH_WALL_Y,WALL_H/2),
            (left-x0,WALL_T,WALL_H),SHELL,MAT_STONE)
    box(f'GEO__North_Window_{n}_Sill',(cx,NORTH_WALL_Y,sill_h/2),
        (w,WALL_T,sill_h),SHELL,MAT_STONE)
    box(f'GEO__North_Window_{n}_Header',(cx,NORTH_WALL_Y,(opening_top+WALL_H)/2),
        (w,WALL_T,WALL_H-opening_top),SHELL,MAT_STONE)
    socket(f'WINDOW_APERTURE_{n+1}', (cx,4.375,(sill_h+opening_top)/2),
           (w,0.55,opening_top-sill_h), 'Gothic glazing / mullions',
           kind='window_aperture',source_px=v2px(cx,4.375))
    x0=right
if x0 < 13.75:
    box('GEO__North_FullHeight_Right',((x0+13.75)/2,NORTH_WALL_Y,WALL_H/2),
        (13.75-x0,WALL_T,WALL_H),SHELL,MAT_STONE)

# South wall has one 1.75 m wide, 3.45 m high real opening.
ENTRY_HALF_W=0.875
ENTRY_H=3.45
for tag, lo, hi in [('West',-13.75,-ENTRY_HALF_W),('East',ENTRY_HALF_W,13.75)]:
    box('GEO__South_Wall_'+tag,((lo+hi)/2,SOUTH_WALL_Y,WALL_H/2),
        (hi-lo,WALL_T,WALL_H),SHELL,MAT_STONE)
box('GEO__South_Door_Lintel',(0,SOUTH_WALL_Y,(ENTRY_H+WALL_H)/2),
    (2*ENTRY_HALF_W,WALL_T,WALL_H-ENTRY_H),SHELL,MAT_STONE)

# Side walls. Full height, deliberately no invented side openings.
for side,xx in [('West',WEST_WALL_X),('East',EAST_WALL_X)]:
    box('GEO__'+side+'_Wall',(xx,-2.125,WALL_H/2),
        (WALL_T,14.5,WALL_H),SHELL,MAT_STONE)

# Primary pilaster rhythm derived from visible wall relief at pixel y~215 and y~620.
NORTH_PIERS_PX = [164,348,608,792]
SOUTH_PIERS_PX = [180,358,602,779]
for i,p in enumerate(NORTH_PIERS_PX,1):
    x=wx(p)
    box(f'GEO__North_Pier_{i:02}',(x,4.45,WALL_H/2),
        (1.25,1.10,WALL_H),SHELL,MAT_PIER)
    socket(f'NORTH_PIER_SKIN_{i:02}',(x,4.12,WALL_H/2),
           (1.45,0.85,WALL_H),'01/02/03_Column family',source_px=(p,215))
for i,p in enumerate(SOUTH_PIERS_PX,1):
    x=wx(p)
    box(f'GEO__South_Pier_{i:02}',(x,-8.8,WALL_H/2),
        (1.75,1.14,WALL_H),SHELL,MAT_PIER)
    socket(f'SOUTH_PIER_SKIN_{i:02}',(x,-8.35,WALL_H/2),
           (1.8,0.85,WALL_H),'01/02/03_Column family',source_px=(p,620))

# Side piers: silhouette-derived marker positions. Recess/column placement should
# be checked in perspective against the 2D source before locking art.
for wall,xx in [('WEST',-13.08),('EAST',13.08)]:
    for i,pxy in enumerate([335,487,605],1):
        yy=wy(pxy)
        box(f'GEO__{wall}_Pier_{i:02}',(xx,yy,WALL_H/2),
            (1.05,1.15,WALL_H),SHELL,MAT_PIER)
        socket(f'{wall}_PIER_SKIN_{i:02}',(xx,yy,WALL_H/2),
               (1.2,1.25,WALL_H),'Structural side buttress / 03_Column',
               source_px=(64 if wall=='WEST' else 896,pxy))

# Four crèche/sleeping alcoves, front (room-facing) y ~= 4.375. Wall remains
# solid as a deliberate BACKING surface. Do not cut physical wall until art is fit.
for n,p in enumerate([104,260,700,856],1):
    x=wx(p)
    hint='09_Wall_Creche_01_Simple.png'
    if n==4:
        hint='09_Wall_Creche_01_Detailed.png'
    socket(f'NORTH_SLEEP_ALCOVE_{n:02}',(x,3.95,2.55),
           (2.95,1.10,3.55),hint,kind='alcove',source_px=(p,120))
    # Keep occupancy/clearance consistent around the proposed alcoves.
    zone(f'ALCOVE_CLEARANCE_{n:02}',(x,3.54,1.25),(3.05,1.15,2.5),
         'Reservation only; not a physical collider. Leave access in gameplay layout.')

# One grouped triple-window decorative kit, on top of individual apertures.
socket('NORTH_TRIPLE_GOTHIC_WINDOW_KIT',(0,4.22,2.80),
       (6.2,0.85,4.6),'02_Back_Window_Detailed.png (or Simple)',
       kind='assembly',source_px=(480,105))

# Main southern opening: door/body/art arch. It is a gameplay opening, not
# permanently closed by an imported decorative mesh unless opening is intended.
socket('SOUTH_DOOR_ARCH',(0,-8.78,2.62),(3.0,1.15,5.24),
       '05_Door_Archway_01.png + 07_LeftArm_ArchLeg_01.png',
       kind='door_arch',source_px=(480,640))
socket('SOUTH_DOOR_LEAF',(0,-8.72,1.72),(1.75,0.28,3.44),
       '06_Door_Body_01.png (door should be separate/openable)',
       kind='door_leaf',source_px=(480,646))

# Gold trim/crown shared across facades. Segments are intentionally replaceable.
for label,y in [('NORTH',4.34),('SOUTH',-8.7)]:
    socket(label+'_CROWN_TRIM',(0,y,4.85),(25.5,0.42,0.65),
           '08_Stone_Crown_Molding.png / 04_Decorative_Crown_Molding.png',
           kind='trim')

# Source art suggests rubble toward corners. Proxies must stay out of core walk lanes.
for s,x in [('W',-11.65),('E',11.65)]:
    for t,y in [('N',2.7),('S',-7.15)]:
        socket('RUBBLE_'+s+'_'+t,(x,y,.32),(2.15,1.5,.65),
               '02_Stone_Rubble_01.png',kind='set_dressing',
               source_px=v2px(x,y))

# Gameplay/authoring zones, purely editor guides.
zone('CENTRAL_EMBLEM_KEEP_CLEAR',(0,wy(404),.03),(4.65,4.65,.06),
     'Central circular floor emblem; avoid permanent tall props here.')
zone('WEST_CHAMBER_BAY',(-7.1,-1.9,.03),(7.65,8.1,.06),
     'Primary open floor west bay for future crèche set dressing and gameplay.')
zone('EAST_CHAMBER_BAY',(7.1,-1.9,.03),(7.65,8.1,.06),
     'Primary open floor east bay for future crèche set dressing and gameplay.')
zone('SOUTH_ENTRY_CLEARANCE',(0,-7.3,1.65),(2.35,3.65,3.3),
     'Clear corridor to the south door, no fixed wall ornaments in its path.')
zone('NORTH_WINDOW_APPROACH',(0,3.0,.04),(5.8,2.0,.08),
     'Keep sightlines to north triple gothic windows.')

# Labels/help text for scene metadata.
scene['creche_reference_size_px'] = '960x704'
scene['pixels_per_meter'] = 32.0
scene['room_clear_dimensions_m'] = '26x13'
scene['room_outer_dimensions_m'] = '27.5x14.5'
scene['wall_height_m'] = WALL_H
scene['wall_thickness_m'] = WALL_T
scene['entry_opening_m'] = 'width 1.75, height 3.45, south center'
scene['construction_note'] = 'Z heights and depths are DESIGN ASSUMPTIONS. XY based on source pixel measurements.'

# Image-aligned true top-down camera, same 960x704 output as split artwork.
camera_data = bpy.data.cameras.new('CAMERA__Creche_Ortho_Source_Aligned')
camera = bpy.data.objects.new(camera_data.name, camera_data)
CAMERAS.objects.link(camera)
camera.location = (0,0,40)
camera.rotation_euler = (0,0,0)  # Blender camera local -Z, local +Y upward
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 30.0
camera_data.lens = 50
scene.camera = camera

light_data = bpy.data.lights.new('LIGHT__Soft_Sun', 'SUN')
light_data.energy = 2.0
sun = bpy.data.objects.new(light_data.name, light_data)
CAMERAS.objects.link(sun)
sun.rotation_euler = (math.radians(25),math.radians(-20),math.radians(45))
scene.world.color = (0.3,0.3,0.3)
scene.render.resolution_x = SOURCE_W
scene.render.resolution_y = SOURCE_H
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = str(BUILD/'creche_blockout_topdown.png')
scene.render.film_transparent = False
try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except Exception:
    try:
        scene.render.engine = 'BLENDER_EEVEE'
    except Exception:
        pass

# Default behavior is 'useful production scene': sockets visible in viewport,
# hidden from renders; no invented detailed assets are added.
for o in bpy.context.selected_objects:
    o.select_set(False)
if bpy.context.view_layer.objects.active:
    bpy.context.view_layer.objects.active = None

bundle_data={
    'source_image_px':[SOURCE_W,SOURCE_H],
    'pixel_scale_px_per_meter':PPM,
    'origin_image_px':[480,352],
    'interior_bounds_m':INTERIOR,
    'interior_dimensions_m':[26.0,13.0],
    'outer_dimensions_m':[27.5,14.5],
    'wall_height_m':WALL_H,
    'wall_thickness_m':WALL_T,
    'door_south_m':{'center_x':0,'width':1.75,'clear_height':3.45},
    'window_openings': [{'x_center_m':x,'width_m':w,'sill_z_m':sill_h,'top_z_m':opening_top}
                        for x,w in window_bays],
    'sockets':SOCKET_DEFS,
    'zones':ZONE_DEFS,
    'warnings':['Physical heights and depths are authoring decisions, not photogrammetric measurements.',
                'Decorative source is not a metric-consistent orthographic drawing.',
                'Raw generated GLBs require per-asset bounding-box inspection and non-destructive fitting.',
                'Sockets are NON-COLLIDING placeholders, NOT art that has been populated.'],
}
(BUILD/'creche_manifest.json').write_text(json.dumps(bundle_data,indent=2),encoding='utf-8')

scene.render.filepath = str(BUILD/'creche_blockout_topdown.png')
bpy.ops.wm.save_as_mainfile(filepath=str(BUILD/'creche_blockout.blend'))

# Export exactly scene geometry, not art sockets, guidance zones, reference plates,
# cameras, or wireframe collider duplicates.
bpy.ops.object.select_all(action='DESELECT')
for c in (FLOORS,SHELL):
    for o in c.objects:
        if o.type == 'MESH' and o.name.startswith('GEO__'):
            o.select_set(True)
try:
    bpy.ops.export_scene.gltf(filepath=str(BUILD/'creche_blockout.glb'),
                              export_format='GLB', use_selection=True)
except Exception as e:
    print('[WARN] GLB export failed. .blend still saved:', repr(e), flush=True)
finally:
    bpy.ops.object.select_all(action='DESELECT')

try:
    bpy.ops.render.render(write_still=True)
except Exception as e:
    print('[WARN] Preview render failed. .blend still saved:', repr(e), flush=True)

print('CRECHE_BUILD_COMPLETE',str(BUILD),flush=True)
print('Main sockets:',len(SOCKET_DEFS),'Zones:',len(ZONE_DEFS),flush=True)
