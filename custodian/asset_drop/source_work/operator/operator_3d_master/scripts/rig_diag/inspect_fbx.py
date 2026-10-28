import bpy, sys, json
from mathutils import Vector
fbx = sys.argv[sys.argv.index('--') + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=fbx, automatic_bone_orientation=False)
sc = bpy.context.scene
print('FPS', sc.render.fps, sc.render.fps_base, 'frame_range', sc.frame_start, sc.frame_end)
for o in bpy.data.objects: print('OBJ', o.type, o.name, tuple(round(x, 4) for x in o.scale), tuple(round(x, 3) for x in o.location), [m.type for m in o.modifiers])
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
print('BONES', len(arm.data.bones)); print([b.name for b in arm.data.bones if 'Finger' not in b.name and 'Hand' not in b.name[-12:-1] or b.name.endswith('Hand')])
print('anim_data action', arm.animation_data.action.name if arm.animation_data and arm.animation_data.action else None)
for a in bpy.data.actions:
    fcs = [fc for l in a.layers for st in l.strips for cb in st.channelbags for fc in cb.fcurves]
    ks = sum(len(fc.keyframe_points) for fc in fcs)
    print('ACTION', a.name, 'range', tuple(a.frame_range), 'slots', len(a.slots), 'fcurves', len(fcs), 'keys', ks)
    kf = sorted({round(k.co[0]) for fc in fcs for k in fc.keyframe_points}); print('  keyed frames', len(kf), kf[:5], '...', kf[-3:])
sc.frame_set(sc.frame_start); h0 = arm.matrix_world @ arm.pose.bones['mixamorig:Hips'].head
print('hips t0', tuple(round(x, 3) for x in h0), 'bone-space rest hips', tuple(round(x, 3) for x in (arm.matrix_world @ arm.data.bones['mixamorig:Hips'].head_local)))
tr = []
for f in range(int(sc.frame_start), int(sc.frame_end) + 1, 5):
    sc.frame_set(f); tr.append(tuple(round(x, 3) for x in (arm.matrix_world @ arm.pose.bones['mixamorig:Hips'].head)))
print('hips traj every 5f', tr)
