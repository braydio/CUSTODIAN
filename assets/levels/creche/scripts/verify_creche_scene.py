"""Blender runtime assertions for the scene produced by build_creche_blockout.py.

blender --background build/creche_blockout.blend --python scripts/verify_creche_scene.py
"""
from math import isclose
import bpy

O=bpy.data.objects
C=bpy.data.collections

def close(a,b):
    assert isclose(float(a),float(b),abs_tol=1e-4),(a,b)

def check_box(name, center, size):
    assert name in O, 'missing '+name
    obj=O[name]
    assert obj.type=='MESH',name
    for a,b in zip(obj.location,center):close(a,b)
    for a,b in zip(obj.dimensions,size):close(a,b)
    print('PASS',name)

check_box('GEO__West_Wall',(-13.375,-2.125,2.625),(.75,14.5,5.25))
check_box('GEO__East_Wall',(13.375,-2.125,2.625),(.75,14.5,5.25))
check_box('GEO__South_Wall_West',(-7.3125,-9,2.625),(12.875,.75,5.25))
check_box('GEO__South_Wall_East',(7.3125,-9,2.625),(12.875,.75,5.25))
check_box('GEO__South_Door_Lintel',(0,-9,4.35),(1.75,.75,1.8))
check_box('GEO__North_Window_0_Sill',(-1.85,4.75,.675),(1.35,.75,1.35))
check_box('GEO__North_Window_1_Sill',(0,4.75,.675),(1.35,.75,1.35))
check_box('GEO__North_Window_2_Sill',(1.85,4.75,.675),(1.35,.75,1.35))
assert 'GEO__Interior_Floor_Mapped' in O
assert 'UVMap' in O['GEO__Interior_Floor_Mapped'].data.uv_layers
assert '03_ART_SOCKETS__REPLACE_WITH_GLB' in C
sockets=[o for o in C['03_ART_SOCKETS__REPLACE_WITH_GLB'].objects if o.name.startswith('SOCKET__')]
assert len(sockets)>=25, len(sockets)
for obj in sockets:
    assert obj.hide_render, 'Socket should not render: '+obj.name
    assert 'asset_hint' in obj, 'Socket missing semantic mapping: '+obj.name
assert '04_GAMEPLAY_AND_CLEARANCE_ZONES' in C
assert len(C['04_GAMEPLAY_AND_CLEARANCE_ZONES'].objects)>=8
# Geometric point test: neither the actual doorway nor the north windows may
# be filled with a wall mesh. Ignore editor-only wire sockets and colliders.
def point_inside(o,point):
    from mathutils import Vector
    local=o.matrix_world.inverted() @ Vector(point)
    return all(abs(local[i]) < o.dimensions[i]/2-1e-4 for i in range(3))
struct=[o for o in C['02_STRUCTURAL_WALLS_AND_PIERS'].objects if o.type=='MESH']
for p in [(0,-9,1.6),(-1.85,4.75,2.7),(0,4.75,2.7),(1.85,4.75,2.7)]:
    obstructions=[o.name for o in struct if point_inside(o,p)]
    assert not obstructions, f'Opening blocked at {p}: {obstructions}'
    print('PASS clear opening',p)
assert bpy.context.scene.unit_settings.system == 'METRIC'
close(bpy.context.scene['pixels_per_meter'],32)
assert bpy.context.scene.render.resolution_x==960
assert bpy.context.scene.render.resolution_y==704
print('CRECHE_GEOMETRY_VERIFIED',len(sockets),'art sockets')
