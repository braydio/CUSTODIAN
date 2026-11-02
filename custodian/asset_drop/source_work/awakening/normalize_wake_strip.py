def split_wake_grid(source: Image.Image) -> list[Image.Image]:
    expected_size = (2172, 724)

    if source.size != expected_size:
        raise RuntimeError(
            f"Unexpected wake source size {source.size}; "
            f"expected {expected_size}. Refusing to guess."
        )

    cols = 4
    rows = 2
    cell_w = 543
    cell_h = 362

    frames = []

    for row in range(rows):
        for col in range(cols):
            x0 = col * cell_w
            y0 = row * cell_h

            frames.append(
                source.crop(
                    (
                        x0,
                        y0,
                        x0 + cell_w,
                        y0 + cell_h,
                    )
                )
            )

    return frames


def normalize_wake_strip(
    source: Image.Image,
) -> tuple[Image.Image, list[Image.Image]]:

    source_frames = split_wake_grid(source)

    descriptors = [describe_frame(frame) for frame in source_frames]

    fw, fh = WAKE_FRAME_SIZE
    padding = calculate_padding(WAKE_FRAME_SIZE)

    # ONE scale across every frame.
    # Never allow animation frames to resize independently.
    max_w = max(d["content_size"][0] for d in descriptors)

    max_h = max(d["content_size"][1] for d in descriptors)

    common_scale = min(
        (fw - padding * 2) / max_w,
        (fh - padding * 2) / max_h,
    )

    baseline = fh - padding

    normalized_frames = []

    for index, desc in enumerate(descriptors):
        crop = desc["crop"]

        nw = max(
            1,
            round(crop.width * common_scale),
        )

        nh = max(
            1,
            round(crop.height * common_scale),
        )

        resized = premultiplied_lanczos(
            crop,
            (nw, nh),
        )

        # Opaque mechanical structure is the registration authority.
        structure_center_x = desc["structure_center_x"] * common_scale

        structure_bottom = desc["structure_bottom"] * common_scale

        x = round((fw / 2.0) - structure_center_x)

        y = round(baseline - structure_bottom)

        # Safety only. If this clamps heavily, we want to know.
        unclamped_x = x
        unclamped_y = y

        x = max(
            0,
            min(x, fw - nw),
        )

        y = max(
            0,
            min(y, fh - nh),
        )

        if (x, y) != (unclamped_x, unclamped_y):
            print(
                f"WARNING: wake frame {index + 1} "
                f"required bounds clamp: "
                f"{(unclamped_x, unclamped_y)} -> {(x, y)}"
            )

        cell = Image.new(
            "RGBA",
            WAKE_FRAME_SIZE,
            (0, 0, 0, 0),
        )

        cell.alpha_composite(
            resized,
            (x, y),
        )

        normalized_frames.append(cell)

    strip = Image.new(
        "RGBA",
        (
            fw * len(normalized_frames),
            fh,
        ),
        (0, 0, 0, 0),
    )

    for index, frame in enumerate(normalized_frames):
        strip.alpha_composite(
            frame,
            (index * fw, 0),
        )

    if strip.size != (1536, 256):
        raise RuntimeError(
            f"Wake output ended at {strip.size}; " "expected exactly 1536x256."
        )

    return strip, normalized_frames
