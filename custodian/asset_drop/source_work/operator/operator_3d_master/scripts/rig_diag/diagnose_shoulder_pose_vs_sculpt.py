#!/usr/bin/env python3
"""Render a reversible pose-only shoulder diagnostic from the ITER005 source."""

import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector
from PIL import Image, ImageDraw


DIRECTIONS = {"N": 180, "NE": -135, "E": -90, "SE": -45,
              "S": 0, "SW": 45, "W": 90, "NW": 135}
DIRS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
FOCUS_DIRS = ("S", "N", "NE", "NW")
CONDITIONS = ("ORIGINAL", "ROTATION_ONLY", "POSITION_AND_ROTATION")
SCALE = 1.23547
ELEVATION = math.radians(45)
PPM = 50.0
ROOT_PIXEL = (64, 106)
BG = (30, 32, 37)
CENTER_X = 0.0023857727646827698


def matrix_rows(m):
    return [[float(v) for v in row] for row in m]


def vec(v):
    return [float(x) for x in v]


def trs(p):
    return Matrix.Translation(p)


def vector_sha(values):
    a = np.asarray(values, dtype="<f4")
    return hashlib.sha256(a.tobytes()).hexdigest()


def action_fcurves(action):
    if hasattr(action, "fcurves"):
        return list(action.fcurves)
    curves = []
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                curves.extend(bag.fcurves)
    return curves


def data_signature(mesh, arm, action):
    curves = action_fcurves(action)
    weight_records = []
    for vertex in mesh.data.vertices:
        for membership in vertex.groups:
            weight_records.append((vertex.index, membership.group, float(membership.weight)))
    weight_records.sort()
    return {
        "mesh_vertex_count": len(mesh.data.vertices),
        "mesh_polygon_count": len(mesh.data.polygons),
        "mesh_coordinates_sha256": vector_sha([tuple(v.co) for v in mesh.data.vertices]),
        "mesh_polygon_index_sha256": hashlib.sha256(
            b"".join(np.asarray(p.vertices, dtype="<u4").tobytes() for p in mesh.data.polygons)).hexdigest(),
        "vertex_group_names": [g.name for g in mesh.vertex_groups],
        "vertex_group_weights_sha256": hashlib.sha256(json.dumps(weight_records,separators=(",",":" )).encode()).hexdigest(),
        "armature_rest_matrices_sha256": hashlib.sha256("".join(
            b.name + repr(matrix_rows(b.matrix_local)) for b in arm.data.bones).encode()).hexdigest(),
        "action_name": action.name,
        "action_fcurve_count": len(curves),
        "action_fcurve_sha256": hashlib.sha256("".join(
            f.data_path + str(f.array_index) + repr([(k.co.x, k.co.y, k.handle_left_type, k.handle_right_type)
                                                       for k in f.keyframe_points])
            for f in curves).encode()).hexdigest(),
    }


def get_source():
    mesh = bpy.data.objects["output_unwrapped"]
    arm = bpy.data.objects["SmartRigArmature"]
    action = bpy.data.actions["operator_run_mixamo_iter005_contact_ik"]
    return mesh, arm, action


def corrections(arm):
    left = arm.data.bones["mixamorig:LeftShoulder"]
    right = arm.data.bones["mixamorig:RightShoulder"]
    h_l, t_l = left.head_local.copy(), left.tail_local.copy()
    h_r, t_r = right.head_local.copy(), right.tail_local.copy()
    target_h = Vector((2 * CENTER_X - h_l.x, h_l.y, h_l.z))
    target_t = Vector((2 * CENTER_X - t_l.x, t_l.y, t_l.z))
    delta = target_h - h_r
    direction_r = (t_r - h_r).normalized()
    target_direction = (target_t - target_h).normalized()
    q = direction_r.rotation_difference(target_direction)
    rotation = q.to_matrix().to_4x4()
    rot_about_head = trs(h_r) @ rotation @ trs(-h_r)
    position_rotation = trs(delta) @ rot_about_head
    rot_tail = h_r + q @ (t_r - h_r)
    length_gap = right.length - left.length
    return {
        "left": left, "right": right,
        "h_l": h_l, "t_l": t_l, "h_r": h_r, "t_r": t_r,
        "target_h": target_h, "target_t": target_t, "delta": delta,
        "direction_r": direction_r, "target_direction": target_direction,
        "q": q, "rot_about_head": rot_about_head,
        "position_rotation": position_rotation, "rot_tail": rot_tail,
        "length_gap": length_gap,
    }


def set_neutral(arm):
    if arm.animation_data:
        arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()


def apply_neutral_condition(arm, cond, corr):
    set_neutral(arm)
    pb = arm.pose.bones[corr["right"].name]
    original = pb.matrix.copy()
    if cond == "ROTATION_ONLY":
        pb.matrix = corr["rot_about_head"] @ original
    elif cond == "POSITION_AND_ROTATION":
        pb.matrix = corr["position_rotation"] @ original
    bpy.context.view_layer.update()
    return original, pb.matrix.copy(), pb.head.copy(), pb.tail.copy()


def apply_frame_condition(arm, action, frame, cond, corr):
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = action
    bpy.context.scene.frame_set(frame - 1)
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    pb = arm.pose.bones[corr["right"].name]
    original = pb.matrix.copy()
    h = pb.head.copy()
    if cond == "ROTATION_ONLY":
        pb.matrix = trs(h) @ corr["q"].to_matrix().to_4x4() @ trs(-h) @ original
    elif cond == "POSITION_AND_ROTATION":
        pb.matrix = trs(corr["delta"]) @ trs(h) @ corr["q"].to_matrix().to_4x4() @ trs(-h) @ original
    bpy.context.view_layer.update()
    return original, pb.matrix.copy()


def setup_render(mesh, arm, scene, scale):
    bounds = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
    lo = Vector(tuple(min(p[i] for p in bounds) for i in range(3)))
    hi = Vector(tuple(max(p[i] for p in bounds) for i in range(3)))
    cx, cy = (lo.x + hi.x) / 2, (lo.y + hi.y) / 2
    root = bpy.data.objects.new("POSE_DIAGNOSTIC_ROOT", None)
    scene.collection.objects.link(root)
    mesh.parent = root
    arm.parent = root
    root.scale = (scale, scale, scale)
    root.location = (-cx * scale, -cy * scale, -lo.z * scale)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    world = bpy.data.worlds.new("pose_diagnostic_world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.10, 0.11, 0.13, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scene.world = world
    light_data = bpy.data.lights.new("pose_diagnostic_sun", "SUN")
    light_data.energy = 3.0
    light = bpy.data.objects.new("pose_diagnostic_sun", light_data)
    scene.collection.objects.link(light)
    camera_data = bpy.data.cameras.new("pose_diagnostic_camera")
    camera_data.type = "ORTHO"
    camera = bpy.data.objects.new("pose_diagnostic_camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return root, light, camera, lo, hi


def render(scene, light, camera, direction, res, path):
    scene.render.resolution_x = scene.render.resolution_y = res
    scene.render.filter_size = 0 if res == 128 else 1.5
    camera.data.ortho_scale = 128 / PPM
    camera.data.shift_y = (ROOT_PIXEL[1] - ROOT_PIXEL[0]) / 128
    az = math.radians(DIRECTIONS[direction])
    camera.location = (10 * math.sin(az) * math.cos(ELEVATION),
                      -10 * math.cos(az) * math.cos(ELEVATION), 10 * math.sin(ELEVATION))
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    light.rotation_euler = (math.radians(50), 0, az - math.radians(35))
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def set_camera_view(light, camera, direction):
    az = math.radians(DIRECTIONS[direction])
    camera.location = (10 * math.sin(az) * math.cos(ELEVATION),
                       -10 * math.cos(az) * math.cos(ELEVATION), 10 * math.sin(ELEVATION))
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    light.rotation_euler = (math.radians(50), 0, az - math.radians(35))


def composite(path):
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", im.size, (*BG, 255))
    bg.alpha_composite(im)
    return bg.convert("RGB")


def camera_pixel(camera, point, resolution):
    v = world_to_camera_view(bpy.context.scene, camera, point)
    return [v.x * resolution, (1 - v.y) * resolution]


def mask_metrics(path, roi_center=None, roi_half=24):
    a = np.asarray(Image.open(path).convert("RGBA"))[:, :, 3] > 8
    ys, xs = np.where(a)
    out = {"silhouette_bbox_px": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())] if len(xs) else None,
           "silhouette_pixels": int(a.sum())}
    if roi_center:
        x, y = [int(round(t)) for t in roi_center]
        x0, x1 = max(0, x-roi_half), min(a.shape[1], x+roi_half+1)
        y0, y1 = max(0, y-roi_half), min(a.shape[0], y+roi_half+1)
        out["roi_xyxy"] = [x0, y0, x1-1, y1-1]
        out["roi_silhouette_pixels"] = int(a[y0:y1, x0:x1].sum())
    return out


def centered_mask_patch(mask, center, half=18):
    x, y = [int(round(v)) for v in center]
    patch = np.zeros((half*2+1, half*2+1), dtype=bool)
    x0, x1 = max(0, x-half), min(mask.shape[1], x+half+1)
    y0, y1 = max(0, y-half), min(mask.shape[0], y+half+1)
    if x0 < x1 and y0 < y1:
        dx0, dy0 = x0-(x-half), y0-(y-half)
        patch[dy0:dy0+(y1-y0), dx0:dx0+(x1-x0)] = mask[y0:y1, x0:x1]
    return patch


def sheet(out, path_map, resolutions, columns, crop=None):
    tile_w = resolutions if not crop else crop[2]-crop[0]
    tile_h = resolutions if not crop else crop[3]-crop[1]
    label_h = 20
    rows = list(path_map)
    result = Image.new("RGB", (tile_w*len(columns), (tile_h+label_h)*len(rows)), BG)
    d = ImageDraw.Draw(result)
    for ri, row in enumerate(rows):
        for ci, col in enumerate(columns):
            p = path_map[row][col]
            im = composite(p)
            if crop:
                im = im.crop(crop)
            x, y = ci*tile_w, ri*(tile_h+label_h)
            result.paste(im, (x,y+label_h))
            row_label = {"ORIGINAL":"ORIGINAL", "ROTATION_ONLY":"ROT ONLY",
                         "POSITION_AND_ROTATION":"POS + ROT"}.get(row, row)
            d.text((x+4,y+3), f"{row_label} · {col}", fill="white")
    result.save(out, optimize=True)


def add_anatomical_note(path):
    im = Image.open(path).convert("RGB")
    canvas = Image.new("RGB", (im.width, im.height+20), BG)
    canvas.paste(im, (0,0))
    ImageDraw.Draw(canvas).text((5,im.height+4),
        "Anatomical RIGHT = image-left in S (target: mixamorig:RightShoulder)", fill="white")
    canvas.save(path, optimize=True)


def projected_delta(d, corr, direction):
    az = math.radians(DIRECTIONS[direction])
    cam_loc = Vector((math.sin(az)*math.cos(ELEVATION), -math.cos(az)*math.cos(ELEVATION), math.sin(ELEVATION)))
    q = (Vector((0,0,0))-cam_loc).to_track_quat("-Z","Y")
    right = q @ Vector((1,0,0))
    up = q @ Vector((0,1,0))
    factor = PPM*SCALE
    corrected_tail = corr["target_h"] + corr["q"] @ (corr["t_r"] - corr["h_r"])
    return {
        "head_delta_px": [float(corr["delta"].dot(right)*factor), float(-corr["delta"].dot(up)*factor)],
        "rotation_only_tip_delta_px": [float((corr["rot_tail"]-corr["t_r"]).dot(right)*factor), float(-(corr["rot_tail"]-corr["t_r"]).dot(up)*factor)],
        "position_plus_rotation_tip_delta_px": [float((corrected_tail-corr["t_r"]).dot(right)*factor), float(-(corrected_tail-corr["t_r"]).dot(up)*factor)],
        "target_vs_preserved_length_tip_residual_px": [float((corr["target_t"]-(corr["target_h"]+(corr["t_r"]-corr["h_r"]).length*corr["target_direction"])).dot(right)*factor), float(-(corr["target_t"]-(corr["target_h"]+(corr["t_r"]-corr["h_r"]).length*corr["target_direction"])).dot(up)*factor)]
    }


def evaluated_world_vertices(mesh):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = mesh.evaluated_get(depsgraph)
    evaluated_mesh = evaluated.to_mesh()
    try:
        return np.asarray([tuple(evaluated.matrix_world @ v.co) for v in evaluated_mesh.vertices], dtype=np.float64)
    finally:
        evaluated.to_mesh_clear()


def group_vertex_indices(mesh, names, exclude_names=(), require_names=()):
    group_ids = {g.index for g in mesh.vertex_groups if g.name in names}
    excluded_ids = {g.index for g in mesh.vertex_groups if g.name in exclude_names}
    required_ids = {g.index for g in mesh.vertex_groups if g.name in require_names}
    if not group_ids:
        return []
    result = []
    for vertex in mesh.data.vertices:
        memberships = {g.group for g in vertex.groups if g.weight > 0}
        if memberships & group_ids and not memberships & excluded_ids and (not required_ids or memberships & required_ids):
            result.append(vertex.index)
    return result


def displacement_metrics(before, after, indices):
    if not indices:
        return {"vertex_count": 0, "max_displacement_mm": 0.0, "rms_displacement_mm": 0.0}
    distances = np.linalg.norm(after[indices] - before[indices], axis=1) * 1000
    return {"vertex_count": len(indices), "max_displacement_mm": float(distances.max()),
            "rms_displacement_mm": float(np.sqrt(np.mean(distances ** 2)))}


def edge_strain_metrics(before, after, mesh_edges, affected_vertex_ids):
    edges = np.asarray(mesh_edges, dtype=np.int64)
    affected = np.asarray(sorted(affected_vertex_ids), dtype=np.int64)
    if not len(edges) or not len(affected):
        return {"edge_count":0}
    use = np.zeros(before.shape[0], dtype=bool)
    use[affected] = True
    edges = edges[use[edges].any(axis=1)]
    old_len = np.linalg.norm(before[edges[:,0]]-before[edges[:,1]],axis=1)
    new_len = np.linalg.norm(after[edges[:,0]]-after[edges[:,1]],axis=1)
    valid = old_len > 0.0005
    pct = (new_len[valid]/old_len[valid]-1)*100
    absolute = np.abs(pct)
    return {"edge_count":int(len(pct)),"max_absolute_length_change_percent":float(absolute.max()),
        "p95_absolute_length_change_percent":float(np.percentile(absolute,95)),
        "edges_over_5_percent":int((absolute>5).sum()),
        "edges_over_10_percent":int((absolute>10).sum()),
        "edges_over_20_percent":int((absolute>20).sum())}


def main():
    args = sys.argv[sys.argv.index("--")+1:]
    source, out = Path(args[0]).resolve(), Path(args[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(source))
    mesh, arm, action = get_source()
    original_signature = data_signature(mesh, arm, action)
    corr = corrections(arm)
    records = {}
    render_paths = {c: {} for c in CONDITIONS}
    metric = {"schema": "custodian.operator_shoulder_pose_sculpt_diagnostic.v1",
              "source_blend": str(source), "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
              "mirror_plane_armature_local_x_m": CENTER_X,
              "camera_contract": {"directions_degrees": DIRECTIONS, "elevation_deg": 45,
                                  "pixels_per_meter_at_128": PPM, "uniform_scale": SCALE,
                                  "root_pixel": ROOT_PIXEL, "same_fixed_camera_for_all_conditions": True},
              "source_integrity_before": original_signature,
              "coordinates_armature_local_m": {"left_head":vec(corr["h_l"]),"left_tail":vec(corr["t_l"]),
                  "right_head":vec(corr["h_r"]),"right_tail":vec(corr["t_r"]),
                  "target_right_head":vec(corr["target_h"]),"target_right_tail":vec(corr["target_t"])},
              "correction": {"head_delta_xyz_m":vec(corr["delta"]),
                  "current_right_direction":vec(corr["direction_r"]), "target_right_direction":vec(corr["target_direction"]),
                  "shortest_arc_quaternion_wxyz":vec(corr["q"]), "shortest_arc_axis_xyz":vec(corr["q"].axis),
                  "shortest_arc_angle_deg":math.degrees(corr["q"].angle),
                  "left_length_m":float(corr["left"].length), "right_length_m":float(corr["right"].length),
                  "right_minus_left_length_m":float(corr["length_gap"]),
                  "target_tip_minus_current_tip_xyz_m":vec(corr["target_t"]-corr["t_r"]),
                  "rotation_only_evaluated_tip_xyz_m":vec(corr["rot_tail"]),
                  "rotation_only_tip_error_to_target_xyz_m":vec(corr["rot_tail"]-corr["target_t"]),
                  "rotation_about_original_head_matrix_armature_local":matrix_rows(corr["rot_about_head"]),
                  "position_plus_rotation_matrix_armature_local":matrix_rows(corr["position_rotation"]),
                  "projected_deltas_px_by_direction":{d:projected_delta(d,corr,d) for d in DIRS}},
              "neutral_conditions":{}, "render_metrics":{}, "bilateral_front_back_patch_metrics":{}, "motion_probes":{},
              "interpretation_boundary":"Measurements and renders are diagnostic evidence. Artistic acceptability remains human-owned."}

    root, light, camera, lo, hi = setup_render(mesh, arm, bpy.context.scene, SCALE)
    scene = bpy.context.scene
    # Render each neutral condition from exactly the same loaded source, with pose-only edits.
    for condition in CONDITIONS:
        original_m, result_m, h, t = apply_neutral_condition(arm, condition, corr)
        records[condition] = {"original_pose_matrix":matrix_rows(original_m),"evaluated_pose_matrix":matrix_rows(result_m),
                              "evaluated_head_armature_local":vec(h),"evaluated_tail_armature_local":vec(t),
                              "evaluated_left_head_armature_local":vec(arm.pose.bones["mixamorig:LeftShoulder"].head)}
        render_paths[condition] = {}
        for res, dirs in ((128, DIRS), (512, FOCUS_DIRS)):
            render_paths[condition][str(res)] = {}
            for direction in dirs:
                path = out/"renders"/condition/str(res)/f"{res}_{direction}.png"
                path.parent.mkdir(parents=True,exist_ok=True)
                render(scene,light,camera,direction,res,path)
                render_paths[condition][str(res)][direction]=str(path)
                # fixed joint-centered ROI in the 128 image; coordinates remain anchored to ORIGINAL right shoulder.
                if condition == "ORIGINAL" and res == 128:
                    pass
    metric["neutral_conditions"] = records
    metric["render_metrics"] = {c:{} for c in CONDITIONS}
    for condition in CONDITIONS:
      for direction in DIRS:
        p=render_paths[condition]["128"][direction]
        set_camera_view(light, camera, direction)
        right_h=Vector(records[condition]["evaluated_head_armature_local"])
        left_h=Vector(records[condition]["evaluated_left_head_armature_local"])
        right_px=camera_pixel(camera,arm.matrix_world @ right_h,128)
        left_px=camera_pixel(camera,arm.matrix_world @ left_h,128)
        # The detailed-change ROI stays anchored to ORIGINAL right-shoulder position;
        # bilateral patch similarity is separately joint-centered per condition.
        fixed_px=camera_pixel(camera,arm.matrix_world @ corr["h_r"],128)
        current=mask_metrics(p,fixed_px)
        alpha=np.asarray(Image.open(p).convert("RGBA"))[:,:,3]>8
        left_patch=centered_mask_patch(alpha,left_px)
        right_patch=centered_mask_patch(alpha,right_px)
        reflected_left=np.fliplr(left_patch)
        intersection=np.logical_and(reflected_left,right_patch).sum()
        union=np.logical_or(reflected_left,right_patch).sum()
        current["bilateral_patch_metrics"]={"pixel_patch_size":[37,37],
            "anatomical_left_patch_center_px":left_px,"anatomical_right_patch_center_px":right_px,
            "left_patch_horizontally_reflected_before_compare":True,
            "silhouette_iou":float(intersection/max(1,union)),
            "silhouette_xor_pixels":int(np.logical_xor(reflected_left,right_patch).sum())}
        if direction in ("S","N"):
            metric["bilateral_front_back_patch_metrics"].setdefault(condition,{})[direction]=current["bilateral_patch_metrics"]
        metric["render_metrics"][condition][direction]=current
        if condition == "ORIGINAL":
            continue
        orig_path=render_paths["ORIGINAL"]["128"][direction]
        baseline=mask_metrics(orig_path,fixed_px)
        a=np.asarray(Image.open(orig_path).convert("RGBA"))[:,:,3]>8
        b=alpha
        current["global_mask_xor_pixels_vs_original"]=int(np.logical_xor(a,b).sum())
        current["global_mask_iou_vs_original"]=float(np.logical_and(a,b).sum()/max(1,np.logical_or(a,b).sum()))
        current["roi_pixel_delta_vs_original"]=current["roi_silhouette_pixels"]-baseline["roi_silhouette_pixels"]

    # Static three-way sheets and shoulder crop views, with no image rescaling.
    path_map={c:{d:render_paths[c]["128"][d] for d in DIRS} for c in CONDITIONS}
    sheet(out/"neutral_128_all8_three_conditions.png",path_map,128,DIRS)
    path_map512={c:{d:render_paths[c]["512"][d] for d in FOCUS_DIRS} for c in CONDITIONS}
    sheet(out/"neutral_512_shoulder_closeups.png",path_map512,320,FOCUS_DIRS,crop=(96,82,416,242))
    add_anatomical_note(out/"neutral_128_all8_three_conditions.png")
    add_anatomical_note(out/"neutral_512_shoulder_closeups.png")

    # Probe each condition and requested source-action frames; frame_set re-evaluates curves before each correction.
    motion_paths={c:{} for c in CONDITIONS}
    motion_metrics={c:{} for c in CONDITIONS}
    motion_transform_records={c:{} for c in CONDITIONS}
    frame_baseline_positions={}
    right_bone = arm.data.bones["mixamorig:RightShoulder"]
    right_chain = {right_bone.name}
    pending = [right_bone]
    while pending:
        parent = pending.pop()
        children = [b for b in arm.data.bones if b.parent == parent]
        right_chain.update(b.name for b in children)
        pending.extend(children)
    affected_groups={
        "right_shoulder_weighted_vertices": group_vertex_indices(mesh, {"mixamorig:RightShoulder"}),
        "right_arm_weighted_vertices": group_vertex_indices(mesh, {"mixamorig:RightArm"}),
        "spine2_vertices_shared_with_right_chain": group_vertex_indices(mesh, {"mixamorig:Spine2"}, require_names=right_chain),
        "spine2_vertices_outside_right_chain": group_vertex_indices(mesh, {"mixamorig:Spine2"}, right_chain),
        "vertices_outside_right_shoulder_chain": [v.index for v in mesh.data.vertices
            if not any(g.group in {vg.index for vg in mesh.vertex_groups if vg.name in right_chain} and g.weight > 0
                       for g in v.groups)],
    }
    right_chain_vertices=set(group_vertex_indices(mesh,right_chain))
    mesh_edges=[tuple(e.vertices) for e in mesh.data.edges]
    for condition in CONDITIONS:
        for frame in (6,13,16):
            motion_paths[condition][str(frame)]={}
            motion_metrics[condition][str(frame)]={}
            original_pose, corrected_pose = apply_frame_condition(arm,action,frame,condition,corr)
            pb=arm.pose.bones[corr["right"].name]
            motion_transform_records[condition][str(frame)]={
                "source_evaluated_pose_matrix":matrix_rows(original_pose),
                "diagnostic_evaluated_pose_matrix":matrix_rows(corrected_pose),
                "diagnostic_head_armature_local":vec(pb.head),
                "diagnostic_tail_armature_local":vec(pb.tail),
            }
            positions=evaluated_world_vertices(mesh)
            if condition == "ORIGINAL":
                frame_baseline_positions[str(frame)] = positions
                motion_metrics[condition][str(frame)]["evaluated_geometry_displacement"] = {
                    name: {"vertex_count":len(ids),"max_displacement_mm":0.0,"rms_displacement_mm":0.0}
                    for name,ids in affected_groups.items()}
            else:
                baseline_positions=frame_baseline_positions[str(frame)]
                motion_metrics[condition][str(frame)]["evaluated_geometry_displacement"] = {
                    name: displacement_metrics(baseline_positions,positions,ids)
                    for name,ids in affected_groups.items()}
                motion_metrics[condition][str(frame)]["right_chain_edge_length_change_vs_original_percent"] = edge_strain_metrics(
                    baseline_positions,positions,mesh_edges,right_chain_vertices)
            for direction in FOCUS_DIRS:
                path=out/"motion"/condition/f"frame_{frame}"/f"128_{direction}.png"
                path.parent.mkdir(parents=True,exist_ok=True)
                render(scene,light,camera,direction,128,path)
                motion_paths[condition][str(frame)][direction]=str(path)
                motion_metrics[condition][str(frame)][direction]=mask_metrics(path)
    for frame in (6,13,16):
        pm={c:{d:motion_paths[c][str(frame)][d] for d in FOCUS_DIRS} for c in CONDITIONS}
        sheet(out/f"motion_frame_{frame}_128_four_directions.png",pm,128,FOCUS_DIRS)
    metric["motion_probes"]={"frames": [6,13,16], "conditions": CONDITIONS,
        "per_frame_direction_paths":motion_paths,"per_frame_metrics":motion_metrics,
        "per_frame_shoulder_pose_matrices":motion_transform_records,
        "tracked_weight_regions":list(affected_groups),
        "correction_reapplied_after_each_frame_evaluation":True,
        "source_action_name":action.name}
    metric["source_integrity_after"] = data_signature(mesh,arm,action)
    metric["source_integrity_unchanged"] = metric["source_integrity_before"] == metric["source_integrity_after"]
    metric["render_artifacts"]={"neutral_128":"neutral_128_all8_three_conditions.png",
        "neutral_512":"neutral_512_shoulder_closeups.png",
        "motion_frames":{str(f):f"motion_frame_{f}_128_four_directions.png" for f in (6,13,16)}}
    (out/"shoulder_pose_correction.json").write_text(json.dumps(metric,indent=2)+"\n")
    print(json.dumps({"source_integrity_unchanged":metric["source_integrity_unchanged"],
                      "head_delta_m":vec(corr["delta"]),"angle_deg":math.degrees(corr["q"].angle),
                      "length_gap_m":corr["length_gap"],"output":str(out)},indent=2))


if __name__ == "__main__":
    main()
