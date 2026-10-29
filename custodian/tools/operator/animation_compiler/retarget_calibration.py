"""Pure quaternion operations for the validated Mixamo neutral-reference mapping."""
from __future__ import annotations

import math


def stable_contact_frame_indices(landmark_samples, speed_limit_m=0.005):
    """Return both endpoints of source-relative landmark steps within the contact threshold."""
    if speed_limit_m <= 0 or any(len(sample) != 3 for sample in landmark_samples):
        raise ValueError("CONTACT_LANDMARK_INPUT_INVALID")
    planted = set()
    for index, (left, right) in enumerate(zip(landmark_samples, landmark_samples[1:])):
        distance = math.sqrt(sum((float(right[axis]) - float(left[axis])) ** 2 for axis in range(3)))
        if distance <= speed_limit_m:
            planted.update((index, index + 1))
    return planted


def source_ground_contact_indices(stable_indices, source_foot_heights, max_height_m=0.04):
    """Keep stable samples whose source foot/toe sole is near the source ground plane."""
    if max_height_m < 0 or any(index < 0 or index >= len(source_foot_heights) for index in stable_indices):
        raise ValueError("CONTACT_HEIGHT_INPUT_INVALID")
    return {index for index in stable_indices if float(source_foot_heights[index]) <= max_height_m}


def normalize_xyzw(value):
    q = tuple(float(component) for component in value)
    if len(q) != 4:
        raise ValueError("QUATERNION_MUST_HAVE_FOUR_COMPONENTS")
    length = math.sqrt(sum(component * component for component in q))
    if length <= 1e-12:
        raise ValueError("ZERO_LENGTH_QUATERNION")
    return tuple(component / length for component in q)


def multiply_xyzw(left, right):
    """Hamilton product; applying right then left to a vector."""
    x1, y1, z1, w1 = normalize_xyzw(left)
    x2, y2, z2, w2 = normalize_xyzw(right)
    return normalize_xyzw((
        w1*x2 + x1*w2 + y1*z2 - z1*y2,
        w1*y2 - x1*z2 + y1*w2 + z1*x2,
        w1*z2 + x1*y2 - y1*x2 + z1*w2,
        w1*w2 - x1*x2 - y1*y2 - z1*z2,
    ))


def inverse_xyzw(value):
    x, y, z, w = normalize_xyzw(value)
    return (-x, -y, -z, w)


def calibrated_target_world_xyzw(source_pose, source_reference, target_rest):
    """Apply the source world-space delta from a fixed calibrated reference pose.

    Q_target(t) = (Q_source(t) * inverse(Q_source_reference)) * Q_target_rest.
    """
    source_delta = multiply_xyzw(source_pose, inverse_xyzw(source_reference))
    return multiply_xyzw(source_delta, target_rest)
