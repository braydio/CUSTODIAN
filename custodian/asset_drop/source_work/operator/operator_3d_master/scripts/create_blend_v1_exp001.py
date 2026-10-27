#!/usr/bin/env python3
"""Execute with Blender 4.3+ / 5.x: create editable armature, preview walk, render proof.

Usage: blender -b -t 2 --python scripts/create_blend.py -- --glb assets/operator_volumetric_v001.glb \
    --out experiments/exp001/operator_experiment.blend --proof experiments/exp001/proof

The output is a *candidate* and is never runtime/canonical art.
"""
import argparse, json, math, pathlib, sys
import bpy
from mathutils import Vector

def arguments():
    parser=argparse.ArgumentParser();parser.add_argument('--glb',required=True);parser.add_argument('--out',required=True);parser.add_argument('--proof',required=True);parser.add_argument('--skip-render',action='store_true')
    return parser.parse_args(sys.argv[sys.argv.index('--')+1:])

def point(obj,loc):
    direction=Vector(loc)-obj.location
    obj.rotation_euler=direction.to_track_quat('-Z','Y').to_euler()

def camera(name,az_deg,scene,col):
    elev=math.radians(31)
    a=math.radians(az_deg)
    cdat=bpy.data.cameras.new(name);cobj=bpy.data.objects.new(name,cdat);col.objects.link(cobj)
    cobj.location=(5.0*math.sin(a)*math.cos(elev),-5.0*math.cos(a)*math.cos(elev),1.04+5.0*math.sin(elev))
    point(cobj,(0,0,1.04));cdat.type='ORTHO';cdat.ortho_scale=2.70
    cdat.lens=35;return cobj

def light(name,at,energy,area,col):
    d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=area
    obj=bpy.data.objects.new(name,d);col.objects.link(obj);obj.location=at;point(obj,(0,0,1.1))

def build_rig(objects,col):
    arm=bpy.data.armatures.new('Operator_3D_skeleton');rig=bpy.data.objects.new('RIG__Operator_3D',arm)
    col.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bones=[
      ('Hips',None,(0,.0,1.04),(0,.0,1.18)),
      ('Spine','Hips',(0,0,1.18),(0,0,1.61)),
      ('Head','Spine',(0,0,1.61),(0,0,1.87)),
      ('Cloak','Spine',(0,.16,1.54),(0,.34,1.12)),
      ('UpperArm.L','Spine',(.34,0,1.54),(.46,-.015,1.20)),
      ('Forearm.L','UpperArm.L',(.46,-.015,1.20),(.48,-.06,.88)),
      ('UpperArm.R','Spine',(-.34,0,1.54),(-.46,-.015,1.20)),
      ('Forearm.R','UpperArm.R',(-.46,-.015,1.20),(-.48,-.06,.88)),
      ('Thigh.L','Hips',(.165,0,1.02),(.19,-.12,.60)),
      ('Shin.L','Thigh.L',(.19,-.12,.60),(.19,0,.18)),
      ('Foot.L','Shin.L',(.19,0,.18),(.19,-.19,.12)),
      ('Thigh.R','Hips',(-.165,0,1.02),(-.19,-.12,.60)),
      ('Shin.R','Thigh.R',(-.19,-.12,.60),(-.19,0,.18)),
      ('Foot.R','Shin.R',(-.19,0,.18),(-.19,-.19,.12))
    ]
    for name,_,head,tail in bones:
        b=arm.edit_bones.new(name);b.head=head;b.tail=tail;b.use_connect=False
    for name,parent,_,_ in bones:
        if parent:arm.edit_bones[name].parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');bpy.context.view_layer.update()
    rig['status']='BLOCKOUT_NOT_CANONICAL';rig['authoritative_gameplay']=False
    for obj in objects:
        if obj.type!='MESH':continue
        # Geometry names begin with the semantic owner prefixes.
        name=obj.name.split('.')[0]
        n=obj.name
        owner='Spine'
        if n.startswith('Head__'): owner='Head'
        elif n.startswith('Cloak__'):owner='Cloak'
        elif n.startswith('Hips__') or n.startswith('Tabard__'):owner='Hips'
        elif n.startswith('Knee_L') or n.startswith('Shin_L'):owner='Shin.L'
        elif n.startswith('Knee_R') or n.startswith('Shin_R'):owner='Shin.R'
        elif n.startswith('Thigh_L'):owner='Thigh.L'
        elif n.startswith('Thigh_R'):owner='Thigh.R'
        elif n.startswith('Boot_L'):owner='Foot.L'
        elif n.startswith('Boot_R'):owner='Foot.R'
        elif n.startswith('Shoulder_L') or n.startswith('UpperArm_L'):owner='UpperArm.L'
        elif n.startswith('Shoulder_R') or n.startswith('UpperArm_R'):owner='UpperArm.R'
        elif n.startswith('Elbow_L') or n.startswith('Forearm_L') or n.startswith('Hand_L'):owner='Forearm.L'
        elif n.startswith('Elbow_R') or n.startswith('Forearm_R') or n.startswith('Hand_R'):owner='Forearm.R'
        elif n.startswith('Pelvis__'):owner='Hips'
        # Rigid art-segment-to-bone attachment: all meshes have true closed volumes.
        # Preserve world transform after linking; avoids rest-pose coordinate drift.
        transform=obj.matrix_world.copy();obj.parent=rig;obj.parent_type='BONE';obj.parent_bone=owner;obj.matrix_world=transform
        obj['rig_group']=owner
    return rig

def walk_targets_and_animation(rig,scene,col):
    action=bpy.data.actions.new('PREVIEW__NE_Walk_15F__NOT_APPROVED')
    rig.animation_data_create()
    rig.animation_data.action=action
    targets={}
    for side,s in (('L',1),('R',-1)):
        obj=bpy.data.objects.new('IK_Foot_Target_'+side,None);col.objects.link(obj)
        obj.empty_display_type='SPHERE';obj.empty_display_size=.09
        obj.location=(.19*s,-.07,.18)
        targets[side]=obj
        shin=rig.pose.bones['Shin.'+side]
        ik=shin.constraints.new('IK');ik.name='Foot_plant_IK';ik.target=obj;ik.chain_count=2
        ik.use_stretch=False
    for frame in range(1,16):
        phase=(frame-1)/15.0*math.tau
        hip=rig.pose.bones['Hips'];hip.location=(0,0,0.018*math.cos(2*phase))
        hip.keyframe_insert('location',frame=frame,group='Hips')
        spine=rig.pose.bones['Spine'];spine.rotation_mode='XYZ';spine.rotation_euler=(.025*math.sin(phase),0,.030*math.sin(phase))
        spine.keyframe_insert('rotation_euler',frame=frame,group='Spine')
        head=rig.pose.bones['Head'];head.rotation_mode='XYZ';head.rotation_euler=(-.018*math.sin(phase),0,-.012*math.sin(phase))
        head.keyframe_insert('rotation_euler',frame=frame,group='Head')
        cape=rig.pose.bones['Cloak'];cape.rotation_mode='XYZ';cape.rotation_euler=(.018*math.sin(phase-.6),0,.024*math.sin(phase-.8))
        cape.keyframe_insert('rotation_euler',frame=frame,group='Cloak')
        for side,offset,sign in (('L',0,1),('R',.5,-1)):
            # 62% stance, 38% swing. Stance foot tracks rearward at z=.18;
            # swing foot follows a raised arc forward. Body stays in place for preview.
            q=((frame-1)/15.0+offset)%1.0
            if q<.62:y=-.19+.38*q/.62;z=.18
            else:
                t=(q-.62)/.38;y=.19-.38*t;z=.18+.12*math.sin(math.pi*t)
            target=targets[side];target.location=(sign*.19,y,z)
            target.keyframe_insert('location',frame=frame)
            upper=rig.pose.bones['UpperArm.'+side];upper.rotation_mode='XYZ'
            upper.rotation_euler=(sign*.18*math.sin(phase+math.pi),0,sign*.025*math.sin(phase))
            upper.keyframe_insert('rotation_euler',frame=frame,group='UpperArm.'+side)
            elbow=rig.pose.bones['Forearm.'+side];elbow.rotation_mode='XYZ'
            elbow.rotation_euler=(.06+0.11*max(0,math.sin(phase+offset*math.tau)),0,0)
            elbow.keyframe_insert('rotation_euler',frame=frame,group='Forearm.'+side)
    scene.frame_start=1;scene.frame_end=15;scene.frame_set(1)
    return action,targets

def main():
    a=arguments()
    if pathlib.Path(a.out).exists():raise RuntimeError('Refusing to overwrite existing .blend; create a new experiment ID')
    if pathlib.Path(a.proof).exists() and any(pathlib.Path(a.proof).iterdir()):raise RuntimeError('Refusing to overwrite an existing render proof directory')
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(pathlib.Path(a.glb).resolve()))
    meshes=[x for x in bpy.context.scene.objects if x.type=='MESH']
    if len(meshes)<60:raise RuntimeError(f'Expected >60 independently editable armor/cloth pieces, saw {len(meshes)}')
    root=bpy.context.scene.collection;rig_col=bpy.data.collections.new('02 RIG and walk IK');root.children.link(rig_col)
    render_col=bpy.data.collections.new('03 Cameras and lights');root.children.link(render_col)
    rig=build_rig(meshes,rig_col)
    for mat in bpy.data.materials:
        if not mat.use_nodes:continue
        if 'visor' in mat.name.lower():continue
        for n in mat.node_tree.nodes:
            if n.type=='BSDF_PRINCIPLED':
                n.inputs['Metallic'].default_value=.68
                n.inputs['Roughness'].default_value=.53
    for o in meshes:
        if o.name.startswith('Head__visor_amber'):
            special=bpy.data.materials.new('VISOR__emissive_amber');special.diffuse_color=(1,.38,.055,1)
            special.use_nodes=True;nodes=special.node_tree.nodes;nodes.clear();output=nodes.new('ShaderNodeOutputMaterial');em=nodes.new('ShaderNodeEmission');em.inputs['Color'].default_value=(1,.35,.035,1);em.inputs['Strength'].default_value=1.8
            special.node_tree.links.new(em.outputs[0],output.inputs['Surface']);o.data.materials.clear();o.data.materials.append(special)
    scene=bpy.context.scene
    try:
        scene.render.engine='BLENDER_EEVEE_NEXT'
    except Exception:
        scene.render.engine='BLENDER_EEVEE'
    scene.render.film_transparent=True;scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.render.film_transparent=True
    scene.world.color=(.12,.12,.12)
    light('Key_softbox',(-3,-4,6),700,4,render_col);light('Fill',(+3,-2,3),270,3,render_col);light('Rim',(1,3,5),1000,3,render_col)
    angles={'N':180,'NE':135,'E':90,'SE':45,'S':0,'SW':-45,'W':-90,'NW':-135}
    cameras={name:camera('CAM_2D_'+name,az,scene,render_col) for name,az in angles.items()}
    walk_targets_and_animation(rig,scene,rig_col)
    scene.camera=cameras['NE'];scene['candidate_status']='NOT APPROVED FOR RUNTIME';scene['frame_contract']='128x128 root 64,106 y ground 107';scene['source_master']='volumetric geometry generated from shape_v001 parameters; exact canonical reference not yet sculpt-matched'
    out=pathlib.Path(a.out).resolve();out.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out),compress=True)
    if not a.skip_render:
        proof=pathlib.Path(a.proof).resolve();proof.mkdir(parents=True,exist_ok=True)
        scene.frame_set(1)
        for name,camera_obj in cameras.items():
            scene.camera=camera_obj;scene.render.filepath=str(proof/('rest_'+name+'.png'));bpy.ops.render.render(write_still=True)
        scene.camera=cameras['NE']
        for i in range(1,16):
            scene.frame_set(i);scene.render.filepath=str(proof/f'walk_NE_{i:02d}.png');bpy.ops.render.render(write_still=True)
    print(json.dumps({'status':'candidate_not_canonical','mesh_parts':len(meshes),'saved_blend':str(out),'camera_count':len(cameras),'walk_frames':15,'foot_ik_targets':2},indent=2))
if __name__=='__main__':main()
