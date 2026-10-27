#!/usr/bin/env python3
"""Run inside Blender 4.3+/5.x: rig the candidate GLB, key a 15-frame NE walk preview, render proof.

blender -b --python scripts/create_blend.py -- --glb experiments/exp-002/candidate.glb \
    --manifest experiments/exp-002/candidate.manifest.json \
    --out experiments/exp-002/operator_exp002.blend --proof experiments/exp-002/blender_proof

v2 (exp-002) fixes over the v1 builder (kept as create_blend_v1_exp001.py) that produced exp-001:
  * refuses a GLB that imports lying down (author with `export_y_up: true`);
  * builds shaders from the Color vertex attribute (sRGB bytes -> linear) so the palette survives;
  * camera azimuths follow the facing convention (E = character faces screen-right);
  * native 128x128 contract frame with projected root (64,106), plus a 4x 512 look-dev render;
  * lights ride with the camera so screen-space lighting is the same in all eight directions;
  * Hips keys are in bone-local axes (Y is up); boots are level-locked against shin pitch;
  * neutral views are rendered with IK/animation disabled, not in walk frame 1.
Output is a CANDIDATE only; it is never runtime art.
"""
import argparse, json, math, pathlib, sys
import bpy
from mathutils import Vector

ELEV = math.radians(30)
FRAME = 128
ROOT_PX = (64, 106)
# Camera sits at (sin a, -cos a); the character faces -Y, so a=0 sees the front (S) and
# a=-90 puts the camera at -X where the character faces screen-right (E).
AZIMUTH = {'N': 180, 'NE': -135, 'E': -90, 'SE': -45, 'S': 0, 'SW': 45, 'W': 90, 'NW': 135}
METAL = {'armor': .55, 'armor_light': .62, 'armor_dark': .45, 'bronze': .85, 'bronze_dim': .7}
ROUGH = {'armor': .5, 'armor_light': .42, 'armor_dark': .6, 'bronze': .32, 'bronze_dim': .45}


def arguments():
    p = argparse.ArgumentParser()
    p.add_argument('--glb', required=True); p.add_argument('--out', required=True)
    p.add_argument('--proof', required=True); p.add_argument('--manifest')
    p.add_argument('--px-per-m', type=float, default=50.0)
    p.add_argument('--hip-drop', type=float, default=.06)
    p.add_argument('--scale-xy', type=float, default=1.0); p.add_argument('--scale-z', type=float, default=1.0)
    p.add_argument('--half-stride', type=float, default=.20); p.add_argument('--lift', type=float, default=.13); p.add_argument('--arm-swing', type=float, default=.30)
    p.add_argument('--ankle-z', type=float, default=.158); p.add_argument('--stance-offset', type=float, default=.02)
    p.add_argument('--metal-scale', type=float, default=1.0)
    p.add_argument('--skip-render', action='store_true')
    return p.parse_args(sys.argv[sys.argv.index('--') + 1:])


def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat('-Z', 'Y').to_euler()


def make_camera(name, col, ortho):
    cd = bpy.data.cameras.new(name); co = bpy.data.objects.new(name, cd); col.objects.link(co)
    cd.type = 'ORTHO'; cd.ortho_scale = ortho
    cd.shift_y = (ROOT_PX[1] - FRAME / 2) / FRAME   # root lands below frame centre
    return co


def place_camera(co, az_deg):
    a = math.radians(az_deg)
    co.location = (10 * math.sin(a) * math.cos(ELEV), -10 * math.cos(a) * math.cos(ELEV), 10 * math.sin(ELEV))
    aim(co, (0, 0, 0))


def build_rig(meshes, col, sxy=1.0, sz=1.0):
    arm = bpy.data.armatures.new('Operator_3D_skeleton'); rig = bpy.data.objects.new('RIG__Operator_3D', arm)
    col.objects.link(rig); bpy.context.view_layer.objects.active = rig; rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bones = [
        ('Hips', None, (0, 0, 1.04), (0, 0, 1.18)), ('Spine', 'Hips', (0, 0, 1.18), (0, 0, 1.61)),
        ('Head', 'Spine', (0, 0, 1.61), (0, 0, 1.87)), ('Cloak', 'Spine', (0, .16, 1.54), (0, .34, 1.12)),
        ('UpperArm.L', 'Spine', (.34, 0, 1.54), (.46, -.015, 1.20)), ('Forearm.L', 'UpperArm.L', (.46, -.015, 1.20), (.48, -.06, .88)),
        ('UpperArm.R', 'Spine', (-.34, 0, 1.54), (-.46, -.015, 1.20)), ('Forearm.R', 'UpperArm.R', (-.46, -.015, 1.20), (-.48, -.06, .88)),
        ('Thigh.L', 'Hips', (.165, 0, 1.02), (.19, -.12, .60)), ('Shin.L', 'Thigh.L', (.19, -.12, .60), (.19, 0, .18)),
        ('Foot.L', 'Shin.L', (.19, 0, .18), (.19, -.19, .12)),
        ('Thigh.R', 'Hips', (-.165, 0, 1.02), (-.19, -.12, .60)), ('Shin.R', 'Thigh.R', (-.19, -.12, .60), (-.19, 0, .18)),
        ('Foot.R', 'Shin.R', (-.19, 0, .18), (-.19, -.19, .12)),
    ]
    for name, _, head, tail in bones:
        b = arm.edit_bones.new(name); b.head = (head[0]*sxy, head[1]*sxy, head[2]*sz); b.tail = (tail[0]*sxy, tail[1]*sxy, tail[2]*sz)
    for name, parent, _, _ in bones:
        if parent: arm.edit_bones[name].parent = arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT'); bpy.context.view_layer.update()
    rig['status'] = 'BLOCKOUT_NOT_CANONICAL'; rig['authoritative_gameplay'] = False
    rules = [('Head__', 'Head'), ('Cloak__', 'Cloak'), ('Hips__', 'Hips'), ('Tabard__', 'Hips'), ('Pelvis__', 'Hips'),
             ('Torso__abdomen', 'Hips'), ('Knee_L', 'Shin.L'), ('Shin_L', 'Shin.L'), ('Knee_R', 'Shin.R'), ('Shin_R', 'Shin.R'),
             ('Thigh_L', 'Thigh.L'), ('Thigh_R', 'Thigh.R'), ('Boot_L', 'Foot.L'), ('Boot_R', 'Foot.R'),
             ('Shoulder_L', 'UpperArm.L'), ('UpperArm_L', 'UpperArm.L'), ('Shoulder_R', 'UpperArm.R'), ('UpperArm_R', 'UpperArm.R'),
             ('Elbow_L', 'Forearm.L'), ('Forearm_L', 'Forearm.L'), ('Hand_L', 'Forearm.L'),
             ('Elbow_R', 'Forearm.R'), ('Forearm_R', 'Forearm.R'), ('Hand_R', 'Forearm.R')]
    for obj in meshes:
        owner = next((b for pre, b in rules if obj.name.startswith(pre)), 'Spine')
        m = obj.matrix_world.copy(); obj.parent = rig; obj.parent_type = 'BONE'; obj.parent_bone = owner; obj.matrix_world = m
        obj['rig_group'] = owner
    return rig


def shade(meshes, classes, metal_scale=1.0):
    cache = {}
    for o in meshes:
        cls = classes.get(o.name.split('.')[0], 'armor')
        if cls not in cache:
            mat = bpy.data.materials.new('M__' + cls); mat.use_nodes = True
            nt = mat.node_tree; nt.nodes.clear()
            out = nt.nodes.new('ShaderNodeOutputMaterial')
            if cls == 'visor':
                em = nt.nodes.new('ShaderNodeEmission'); em.inputs['Color'].default_value = (1, .33, .03, 1); em.inputs['Strength'].default_value = 2.5
                nt.links.new(em.outputs[0], out.inputs['Surface'])
            else:
                attr = nt.nodes.new('ShaderNodeAttribute'); attr.attribute_name = 'Color'
                gam = nt.nodes.new('ShaderNodeGamma'); gam.inputs['Gamma'].default_value = 2.2   # sRGB bytes -> linear
                bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
                bsdf.inputs['Metallic'].default_value = METAL.get(cls, 0.0) * metal_scale; bsdf.inputs['Roughness'].default_value = ROUGH.get(cls, .9)
                nt.links.new(attr.outputs['Color'], gam.inputs['Color']); nt.links.new(gam.outputs[0], bsdf.inputs['Base Color'])
                nt.links.new(bsdf.outputs[0], out.inputs['Surface'])
            cache[cls] = mat
        o.data.materials.clear(); o.data.materials.append(cache[cls])
        for poly in o.data.polygons: poly.use_smooth = cls != 'visor'


def add_walk(rig, scene, col, hip_drop, sxy=1.0, sz=1.0, hs=.20, lift=.13, arm=.30, ankle0=.158, stance_off=.02):
    action = bpy.data.actions.new('PREVIEW__NE_Walk_15F__NOT_APPROVED')
    rig.animation_data_create(); rig.animation_data.action = action
    hip_drop *= sz
    ankle_z = ankle0 * sz          # ankle bone tail sits ~.158 above the sole bottom (boot mesh geometry)
    targets, iks = {}, {}
    for side, s in (('L', 1), ('R', -1)):
        t = bpy.data.objects.new('IK_Foot_Target_' + side, None); col.objects.link(t)
        t.empty_display_type = 'SPHERE'; t.empty_display_size = .09; t.location = (.19 * s * sxy, 0, ankle_z + stance_off)
        ik = rig.pose.bones['Shin.' + side].constraints.new('IK'); ik.name = 'Foot_plant_IK'; ik.target = t
        ik.chain_count = 2; ik.use_stretch = False
        targets[side] = t; iks[side] = ik
    for f in range(1, 16):
        phase = (f - 1) / 15.0 * math.tau
        pb = rig.pose.bones
        pb['Hips'].location = (0, -hip_drop + .016 * math.cos(2 * phase), 0)   # bone-local Y is world up
        pb['Hips'].keyframe_insert('location', frame=f, group='Hips')
        for name, eul in (('Spine', (.03 * math.sin(2 * phase), 0, .035 * math.sin(phase))),
                          ('Head', (-.02 * math.sin(2 * phase), 0, -.02 * math.sin(phase))),
                          ('Cloak', (.04 * math.sin(phase - .6), 0, .03 * math.sin(phase - .8)))):
            pb[name].rotation_mode = 'XYZ'; pb[name].rotation_euler = eul; pb[name].keyframe_insert('rotation_euler', frame=f, group=name)
        for side, off, sign in (('L', 0, 1), ('R', .5, -1)):
            q = ((f - 1) / 15.0 + off) % 1.0
            if q < .62:
                y = (-hs + 2 * hs * q / .62) * sxy; z = ankle_z + stance_off
            else:
                tt = (q - .62) / .38; y = (hs - 2 * hs * tt) * sxy; z = ankle_z + stance_off + lift * sz * math.sin(math.pi * tt)
            targets[side].location = (sign * .19 * sxy, y, z); targets[side].keyframe_insert('location', frame=f)
            up = pb['UpperArm.' + side]; up.rotation_mode = 'XYZ'
            up.rotation_euler = (sign * arm * math.sin(phase + math.pi), 0, 0); up.keyframe_insert('rotation_euler', frame=f, group='UpperArm.' + side)
            fo = pb['Forearm.' + side]; fo.rotation_mode = 'XYZ'
            fo.rotation_euler = (.10 + .16 * max(0, math.sin(phase + off * math.tau + math.pi)), 0, 0)
            fo.keyframe_insert('rotation_euler', frame=f, group='Forearm.' + side)
    scene.frame_start, scene.frame_end = 1, 15
    return action, targets, iks


def level_boots(rig, scene, targets):
    """Counter shin pitch so soles stay level; returns per-frame ankle positions and IK reach error."""
    report = {'ik_reach_error_m': [], 'ankle_world': {'L': [], 'R': []}}
    for f in range(1, 16):
        scene.frame_set(f); bpy.context.view_layer.update()
        ev = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
        for side in ('L', 'R'):
            shin = ev.pose.bones['Shin.' + side]; foot = rig.pose.bones['Foot.' + side]
            delta = shin.matrix.to_quaternion() @ shin.bone.matrix_local.to_quaternion().inverted()
            qf = foot.bone.matrix_local.to_quaternion()
            foot.rotation_mode = 'QUATERNION'; foot.rotation_quaternion = qf.inverted() @ delta.inverted() @ qf
            foot.keyframe_insert('rotation_quaternion', frame=f, group='Foot.' + side)
            ankle = ev.matrix_world @ shin.tail
            report['ankle_world'][side].append([round(v, 4) for v in ankle])
            report['ik_reach_error_m'].append(round((ankle - targets[side].location).length, 4))
    return report


def neutral_pose(rig, iks, on, action):
    for ik in iks.values(): ik.influence = 0.0 if on else 1.0
    rig.animation_data.action = None if on else action
    if on:
        for pb in rig.pose.bones:
            pb.location = (0, 0, 0); pb.rotation_mode = 'QUATERNION'; pb.rotation_quaternion = (1, 0, 0, 0); pb.scale = (1, 1, 1)


def main():
    a = arguments()
    if pathlib.Path(a.out).exists(): raise RuntimeError('Refusing to overwrite existing .blend; create a new experiment ID')
    if pathlib.Path(a.proof).exists() and any(pathlib.Path(a.proof).iterdir()): raise RuntimeError('Refusing to overwrite existing proof dir')
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(pathlib.Path(a.glb).resolve()))
    meshes = [x for x in bpy.context.scene.objects if x.type == 'MESH']
    if len(meshes) < 60: raise RuntimeError(f'Expected >60 parts, saw {len(meshes)}')
    pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    zs = [p.z for p in pts]; ys = [p.y for p in pts]
    if not (1.4 < max(zs) - min(zs) < 2.4 and (max(ys) - min(ys)) < 1.6):
        raise RuntimeError(f'Imported model is not upright (z extent {max(zs)-min(zs):.2f}, y extent {max(ys)-min(ys):.2f}); set export_y_up')
    classes = {}
    if a.manifest:
        classes = {p['name']: p['material_class'] for p in json.loads(pathlib.Path(a.manifest).read_text())['mesh_parts']}
    classes['Head__visor_amber'] = 'visor'
    root = bpy.context.scene.collection
    rig_col = bpy.data.collections.new('02 RIG and walk IK'); root.children.link(rig_col)
    cam_col = bpy.data.collections.new('03 Cameras and lights'); root.children.link(cam_col)
    rig = build_rig(meshes, rig_col, a.scale_xy, a.scale_z); shade(meshes, classes, a.metal_scale)
    scene = bpy.context.scene
    try: scene.render.engine = 'BLENDER_EEVEE'
    except TypeError: scene.render.engine = 'BLENDER_EEVEE_NEXT'
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'; scene.render.image_settings.color_mode = 'RGBA'
    scene.render.fps = 15; scene['preview_fps_provisional_not_canonical'] = True
    scene.view_settings.view_transform = 'Standard'
    scene.world = scene.world or bpy.data.worlds.new('W'); scene.world.use_nodes = False; scene.world.color = (.10, .10, .11)
    ortho = FRAME / a.px_per_m
    cams = {n: make_camera('CAM_2D_' + n, cam_col, ortho) for n in AZIMUTH}
    rigl = bpy.data.objects.new('LIGHT_RIG_follows_camera', None); cam_col.objects.link(rigl)
    for nm, at, en, size in (('Key', (-3, -4, 6), 900, 4), ('Fill', (3, -2, 3), 300, 3), ('Rim', (1, 3, 5), 1100, 3)):
        d = bpy.data.lights.new(nm, 'AREA'); d.energy = en; d.shape = 'DISK'; d.size = size
        o = bpy.data.objects.new(nm, d); cam_col.objects.link(o); o.parent = rigl; o.location = at; aim(o, (0, 0, 1.1))
    action, targets, iks = add_walk(rig, scene, rig_col, a.hip_drop, a.scale_xy, a.scale_z, a.half_stride, a.lift, a.arm_swing, a.ankle_z, a.stance_offset)
    qa = level_boots(rig, scene, targets)
    scene['candidate_status'] = 'NOT APPROVED FOR RUNTIME'
    scene['frame_contract'] = '128x128 root 64,106 ground y107 (operator_2_5d_128)'
    out = pathlib.Path(a.out).resolve(); out.parent.mkdir(parents=True, exist_ok=True)
    if not a.skip_render:
        proof = pathlib.Path(a.proof).resolve()

        def shoot(label):
            for sub, res, filt in (('px128', FRAME, 0.0), ('look512', FRAME * 4, 1.5)):
                d = proof / sub; d.mkdir(parents=True, exist_ok=True)
                scene.render.resolution_x = scene.render.resolution_y = res; scene.render.filter_size = filt
                scene.render.filepath = str(d / f'{label}.png'); bpy.ops.render.render(write_still=True)
        neutral_pose(rig, iks, True, action)
        for n, co in cams.items():
            place_camera(co, AZIMUTH[n]); rigl.rotation_euler = (0, 0, math.radians(AZIMUTH[n])); scene.camera = co
            bpy.context.view_layer.update(); shoot('rest_' + n)
        neutral_pose(rig, iks, False, action)
        place_camera(cams['NE'], AZIMUTH['NE']); rigl.rotation_euler = (0, 0, math.radians(AZIMUTH['NE'])); scene.camera = cams['NE']
        for f in range(1, 16):
            scene.frame_set(f); shoot(f'walk_NE_{f:02d}')
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(out), compress=True)
    qa.update({'mesh_parts': len(meshes), 'cameras': len(cams), 'walk_frames': 15, 'blender': bpy.app.version_string})
    out.with_suffix('.rig_qa.json').write_text(json.dumps(qa, indent=1, sort_keys=True) + '\n')
    print(json.dumps({'saved_blend': str(out), 'parts': len(meshes), 'max_ik_reach_error_m': max(qa['ik_reach_error_m'])}, indent=1))


if __name__ == '__main__':
    main()
