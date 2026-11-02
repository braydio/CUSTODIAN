from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any

from PIL import Image

TRAJECTORY_NAMES = (
    "head_center", "hip_center", "knee_near", "knee_far", "ankle_near", "ankle_far",
    "toe_near", "toe_far", "weapon_grip", "weapon_tip", "cloak_tip_near", "cloak_tip_far",
)


def _occupied(image: Image.Image) -> list[tuple[int, int, tuple[int, int, int, int]]]:
    pixels = list(image.getdata())
    return [(index % image.width, index // image.width, pixel) for index, pixel in enumerate(pixels) if pixel[3]]


def _isolated_pixels(occupied: list[tuple[int, int, tuple[int, int, int, int]]]) -> list[list[int]]:
    points = {(x, y) for x, y, _ in occupied}
    isolated = [
        [x, y] for x, y in points
        if not any((x + dx, y + dy) in points for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)))
    ]
    isolated.sort()
    return isolated


def frame_metrics(path: Path) -> dict[str, Any]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
        alpha = image.getchannel("A")
        bbox = alpha.getbbox()
        occupied = _occupied(image)
        opaque = sum(pixel[3] == 255 for _, _, pixel in occupied)
        semi = sum(0 < pixel[3] < 255 for _, _, pixel in occupied)
        centroid = (
            [sum(x for x, _, _ in occupied) / len(occupied), sum(y for _, y, _ in occupied) / len(occupied)]
            if occupied else None
        )
        width = 0 if not bbox else bbox[2] - bbox[0]
        height = 0 if not bbox else bbox[3] - bbox[1]
        lowest_y = max((y for _, y, _ in occupied), default=None)
        isolated = _isolated_pixels(occupied)
        components = connected_components(image)
        return {
            "size": [image.width, image.height],
            "alpha_bbox": list(bbox) if bbox else None,
            "opaque_pixels": opaque,
            "semi_transparent_pixels": semi,
            "visual_centroid": centroid,
            "lowest_occupied_y": lowest_y,
            "highest_occupied_y": min((y for _, y, _ in occupied), default=None),
            "width": width,
            "height": height,
            "palette_size": len({pixel for _, _, pixel in occupied}),
            "pixel_sha": hashlib.sha256(image.tobytes()).hexdigest(),
            "baseline_y": lowest_y,
            "alpha_area": width * height,
            "isolated_opaque_pixels": isolated,
            "single_pixel_components": len(isolated),
            "opaque_components": [
                {key: value for key, value in component.items() if key != "pixels"}
                | ({"pixels": component["pixels"]} if component["area"] <= 8 else {})
                for component in components
            ],
        }


def connected_components(image: Image.Image, *, connectivity: int = 8) -> list[dict[str, Any]]:
    """Return deterministic alpha-connected components and exact small-component pixels."""
    if connectivity not in (4, 8):
        raise ValueError("component connectivity must be 4 or 8")
    rgba = image.convert("RGBA")
    width, height = rgba.size
    alpha = rgba.getchannel("A")
    occupied = {(x, y) for y in range(height) for x in range(width) if alpha.getpixel((x, y)) > 0}
    neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    if connectivity == 8:
        neighbors += [(-1, -1), (1, -1), (-1, 1), (1, 1)]
    result = []
    while occupied:
        seed = min(occupied, key=lambda point: (point[1], point[0]))
        occupied.remove(seed)
        pending = [seed]
        points = []
        while pending:
            x, y = pending.pop()
            points.append((x, y))
            for dx, dy in neighbors:
                point = (x + dx, y + dy)
                if point in occupied:
                    occupied.remove(point)
                    pending.append(point)
        xs = [point[0] for point in points]
        ys = [point[1] for point in points]
        component = {
            "area": len(points),
            "bounds": [min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1],
        }
        if len(points) <= 8:
            component["pixels"] = [list(point) for point in sorted(points, key=lambda item: (item[1], item[0]))]
        result.append(component)
    result.sort(key=lambda item: (item["bounds"][1], item["bounds"][0], -item["area"]))
    return result


def _bounds(points: set[tuple[int, int]]) -> list[int] | None:
    if not points:
        return None
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    return [min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1]


def _point_clusters(points: set[tuple[int, int]]) -> list[dict[str, Any]]:
    pending = set(points)
    clusters = []
    while pending:
        seed = min(pending, key=lambda point: (point[1], point[0]))
        pending.remove(seed)
        stack = [seed]
        cluster = []
        while stack:
            point = stack.pop()
            cluster.append(point)
            x, y = point
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1),
                             (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1), (x + 1, y + 1)):
                if neighbor in pending:
                    pending.remove(neighbor)
                    stack.append(neighbor)
        item = {"area": len(cluster), "bounds": _bounds(set(cluster))}
        if len(cluster) <= 8:
            item["pixels"] = [list(point) for point in sorted(cluster, key=lambda value: (value[1], value[0]))]
        clusters.append(item)
    return sorted(clusters, key=lambda item: (item["bounds"][1], item["bounds"][0], -item["area"]))


def _external_boundary(image: Image.Image) -> set[tuple[int, int]]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    width, height = rgba.size
    occupied = {(x, y) for y in range(height) for x in range(width) if alpha.getpixel((x, y)) > 0}
    return {
        (x, y) for x, y in occupied
        if any((x + dx, y + dy) not in occupied for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)))
    }


def _region_pixels(mask: dict[str, Any], size: tuple[int, int]) -> set[tuple[int, int]]:
    points: set[tuple[int, int]] = set()
    for span in mask.get("spans", []):
        y, x0, x1 = int(span["y"]), int(span["x0"]), int(span["x1"])
        if not 0 <= y < size[1] or x0 < 0 or x1 < x0 or x1 >= size[0]:
            raise ValueError("semantic mask span is outside the frame")
        points.update((x, y) for x in range(x0, x1 + 1))
    return points


def temporal_metrics(paths: list[Path], *, masks: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    """Measure adjacent silhouette, external-boundary, and semantic-region color drift."""
    images = [Image.open(path).convert("RGBA") for path in paths]
    if not images:
        return {"adjacent_frames": [], "loop_seam": None, "regions": []}
    size = images[0].size
    if any(image.size != size for image in images):
        raise ValueError("temporal metrics require matching frame dimensions")

    def pair_metrics(left: Image.Image, right: Image.Image, left_frame: int, right_frame: int) -> dict[str, Any]:
        la, ra = left.getchannel("A"), right.getchannel("A")
        silhouette_delta = {
            (x, y) for y in range(size[1]) for x in range(size[0])
            if (la.getpixel((x, y)) > 0) != (ra.getpixel((x, y)) > 0)
        }
        lb, rb = _external_boundary(left), _external_boundary(right)
        boundary_delta = lb ^ rb
        return {
            "from_frame": left_frame,
            "to_frame": right_frame,
            "silhouette_delta_pixels": len(silhouette_delta),
            "silhouette_delta_bounds": _bounds(silhouette_delta),
            "external_boundary_delta_pixels": len(boundary_delta),
            "external_boundary_delta_bounds": _bounds(boundary_delta),
            "external_boundary_clusters": _point_clusters(boundary_delta),
        }

    adjacent = [pair_metrics(images[index - 1], images[index], index, index + 1)
                for index in range(1, len(images))]
    seam = pair_metrics(images[-1], images[0], len(images), 1) if len(images) > 1 else None
    regions = []
    for mask in masks or []:
        points = _region_pixels(mask, size)
        if not points:
            continue
        series = []
        for index in range(1, len(images)):
            left, right = images[index - 1], images[index]
            before = [left.getpixel(point)[:3] for point in points if left.getpixel(point)[3] > 0]
            after = [right.getpixel(point)[:3] for point in points if right.getpixel(point)[3] > 0]
            if not before or not after:
                continue
            def mean_rgb(values):
                return [sum(color[channel] for color in values) / len(values) for channel in range(3)]
            rgb_before, rgb_after = mean_rgb(before), mean_rgb(after)
            luma_before = sum(0.2126 * color[0] + 0.7152 * color[1] + 0.0722 * color[2] for color in before) / len(before)
            luma_after = sum(0.2126 * color[0] + 0.7152 * color[1] + 0.0722 * color[2] for color in after) / len(after)
            changed = {
                point for point in points
                if left.getpixel(point) != right.getpixel(point)
            }
            series.append({"from_frame": index, "to_frame": index + 1,
                           "mean_luminance_delta": round(luma_after - luma_before, 4),
                           "mean_rgb_delta": [round(b - a, 4) for a, b in zip(rgb_before, rgb_after)],
                           "changed_pixels": len(changed), "changed_bounds": _bounds(changed),
                           "changed_clusters": _point_clusters(changed)})
        regions.append({"mask_id": mask.get("mask_id"), "part": mask.get("part"), "layer": mask.get("layer"), "metrics": series})
    return {"adjacent_frames": adjacent, "loop_seam": seam, "regions": regions}


def reference_metrics(paths: list[Path], references: list[Path]) -> list[dict[str, Any]]:
    """Compare corresponding current/reference frames with exact changed bounds."""
    if len(paths) != len(references):
        raise ValueError("reference and Workbench frame counts differ")
    result = []
    for index, (current_path, reference_path) in enumerate(zip(paths, references), 1):
        with Image.open(current_path) as source, Image.open(reference_path) as reference:
            current, baseline = source.convert("RGBA"), reference.convert("RGBA")
            if current.size != baseline.size:
                raise ValueError("reference and Workbench frame canvases differ")
            changed = set()
            for y in range(current.height):
                for x in range(current.width):
                    if current.getpixel((x, y)) != baseline.getpixel((x, y)):
                        changed.add((x, y))
            result.append({"frame": index, "changed_pixels": len(changed),
                           "changed_ratio": len(changed) / max(current.width * current.height, 1),
                           "changed_bounds": _bounds(changed)})
    return result


def _loop_seam_metrics(points: list[list[int]]) -> dict[str, Any] | None:
    if len(points) < 3:
        return None
    ordered = sorted(points, key=lambda item: item[0])
    steps = [
        ((current[1] - previous[1]) ** 2 + (current[2] - previous[2]) ** 2) ** 0.5
        for previous, current in zip(ordered, ordered[1:])
    ]
    seam = ((ordered[0][1] - ordered[-1][1]) ** 2 + (ordered[0][2] - ordered[-1][2]) ** 2) ** 0.5
    sorted_steps = sorted(steps)
    mid = len(sorted_steps) // 2
    median_step = sorted_steps[mid] if len(sorted_steps) % 2 else (sorted_steps[mid - 1] + sorted_steps[mid]) / 2
    return {
        "loop_seam_displacement": seam,
        "median_internal_step": median_step,
        "max_internal_step": max(steps),
        "normalized_seam_ratio": seam / max(median_step, 1.0),
    }


def _mask_summary(mask: dict[str, Any]) -> dict[str, Any] | None:
    spans = mask.get("spans") or []
    if not spans:
        return None
    xs = [x for span in spans for x in (span["x0"], span["x1"])]
    ys = [span["y"] for span in spans]
    span_pixel_count = sum(span["x1"] - span["x0"] + 1 for span in spans)
    return {
        "mask_id": mask.get("mask_id"),
        "part": mask.get("part"),
        "frame": mask.get("frame"),
        "layer": mask.get("layer"),
        "bbox": mask.get("bounds"),
        "centroid": [sum(xs) / len(xs), sum(ys) / len(ys)],
        "span_pixel_count": span_pixel_count,
    }


def animation_metrics(
    paths: list[Path],
    landmarks: list[dict[str, Any]] | None = None,
    *,
    masks: list[dict[str, Any]] | None = None,
    layer_frame_paths: dict[str, list[Path]] | None = None,
) -> dict[str, Any]:
    frames = [frame_metrics(path) for path in paths]
    hashes = [item["pixel_sha"] for item in frames]
    duplicate = [i + 1 for i in range(1, len(hashes)) if hashes[i] == hashes[i - 1]]

    trajectories: dict[str, list[list[int]]] = {}
    for point in landmarks or []:
        trajectories.setdefault(point["name"], []).append([point["frame"], point["x"], point["y"]])
    for points in trajectories.values():
        points.sort(key=lambda item: item[0])

    for index, frame in enumerate(frames, 1):
        frame["landmarks"] = {
            name: [item[1], item[2]]
            for name, points in trajectories.items()
            for item in points
            if item[0] == index
        }

    loop_seam_metrics = {}
    for name in TRAJECTORY_NAMES:
        points = trajectories.get(name)
        if not points:
            continue
        seam = _loop_seam_metrics(points)
        if seam is not None:
            loop_seam_metrics[name] = seam

    layer_shas = {
        layer: [frame_metrics(path)["pixel_sha"] for path in layer_paths]
        for layer, layer_paths in (layer_frame_paths or {}).items()
    }

    mask_summaries = [item for item in (_mask_summary(mask) for mask in masks or []) if item is not None]

    return {
        "schema": "custodian.operator_art_metrics.v2",
        "frames": frames,
        "duplicate_adjacent_frames": duplicate,
        "trajectories": trajectories,
        "loop_seam_metrics": loop_seam_metrics,
        "layer_shas": layer_shas,
        "masks": mask_summaries,
    }
