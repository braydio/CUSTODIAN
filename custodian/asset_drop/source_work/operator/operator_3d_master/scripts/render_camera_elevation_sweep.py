#!/usr/bin/env python3
"""Camera-only diagnostic. blender -b experiments/exp-007/operator_exp007.blend --python scripts/render_camera_elevation_sweep.py -- OUT_DIR
Renders the UNMODIFIED mesh in neutral rest at several camera elevations (degrees ABOVE horizontal), same ortho scale,
shift_y, resolution, lights, root (64,106). Never saves the .blend. Also dumps true 3D anatomy numbers and the projected root."""
import json, math, pathlib, sys
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import create_blend as cb

_a = sys.argv[sys.argv.index('--') + 1:]
out = pathlib.Path(_a[0]); out.mkdir(parents=True, exist_ok=True)
# optional (Task 009): `--projection ELEV PX_PER_M` renders all 8 directions at one common elevation/scale; legacy sweep otherwise
PROJ = (float(_a[_a.index('--projection') + 1]), float(_a[_a.index('--projection') + 2])) if '--projection' in _a else None
scene = bpy.context.scene; rig = bpy.data.objects['RIG__Operator_3D']; rigl = bpy.data.objects['LIGHT_RIG_follows_camera']
# neutral rest, identical to create_blend.neutral_pose
for s in 'LR': rig.pose.bones['Shin.' + s].constraints['Foot_plant_IK'].influence = 0.0
rig.animation_data.action = None
for pb in rig.pose.bones:
    pb.location = (0, 0, 0); pb.rotation_mode = 'QUATERNION'; pb.rotation_quaternion = (1, 0, 0, 0); pb.scale = (1, 1, 1)
scene.render.resolution_x = scene.render.resolution_y = cb.FRAME; scene.render.filter_size = 0.0
scene.frame_set(1); bpy.context.view_layer.update()

frames = {}
def shoot(el, d):
    cam = bpy.data.objects['CAM_2D_' + d]
    if PROJ: cam.data.ortho_scale = cb.FRAME / PROJ[1]
    cb.ELEV = math.radians(el); cb.place_camera(cam, cb.AZIMUTH[d])
    rigl.rotation_euler = (0, 0, math.radians(cb.AZIMUTH[d])); scene.camera = cam; bpy.context.view_layer.update()
    name = f'el{el:02d}_{d}.png'; scene.render.filepath = str(out / name); bpy.ops.render.render(write_still=True)
    p = world_to_camera_view(scene, cam, Vector((0, 0, 0)))
    frames[name] = {'elevation_deg_above_horizon': el, 'direction': d, 'ortho_scale': cam.data.ortho_scale, 'shift_y': cam.data.shift_y,
                    'projected_root_px': [round(p.x * cb.FRAME, 2), round((1 - p.y) * cb.FRAME, 2)]}
if PROJ:
    for d in cb.AZIMUTH: shoot(int(PROJ[0]), d)
    for d in ('S', 'E'): shoot(0, d)
else:
    for el in (30, 40, 50, 60):
        for d in ('N', 'NE', 'E', 'SE', 'S'): shoot(el, d)
    for d in ('S', 'E'): shoot(0, d)       # reference-only eye-level anatomy views

def bounds(prefixes):
    pts = [o.matrix_world @ Vector(c) for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith(prefixes) for c in o.bound_box]
    return [(round(min(p[i] for p in pts), 3), round(max(p[i] for p in pts), 3)) for i in range(3)] if pts else None
allm = bounds(('',)); hood = bounds(('Head__hood_shell',)); sh = bounds(('Shoulder_',)); belt = bounds(('Hips__belt',)); leg = bounds(('Thigh_L', 'Knee_L', 'Shin_L', 'Boot_L'))
anat = {'units': 'metres, authoring Z up, mesh geometry in neutral rest (not inferred from 128px)',
        'total_height': allm[2][1] - allm[2][0], 'overall_width_x': allm[0][1] - allm[0][0],
        'shoulder_plate_span_x': sh[0][1] - sh[0][0], 'belt_width_x': belt[0][1] - belt[0][0],
        'hood_height_z': hood[2][1] - hood[2][0], 'hood_width_x': hood[0][1] - hood[0][0], 'hood_top_z': hood[2][1],
        'leg_length_ground_to_thigh_top_z': leg[2][1], 'hood_height_over_total': round((hood[2][1] - hood[2][0]) / (allm[2][1] - allm[2][0]), 3),
        'shoulder_span_over_height': round((sh[0][1] - sh[0][0]) / (allm[2][1] - allm[2][0]), 3), 'leg_over_height': round(leg[2][1] / (allm[2][1] - allm[2][0]), 3)}
anat = {k: (round(v, 3) if isinstance(v, float) else v) for k, v in anat.items()}
json.dump({'frames': frames, 'anatomy_3d': anat}, open(out / 'sweep_raw.json', 'w'), indent=1)
print('SWEEP_DONE', len(frames))
