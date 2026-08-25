#!/usr/bin/env python3

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]

SOURCE = (
    ROOT
    / "asset_drop/source_work/meridian_civic_floor"
    / "meridian_civic_floor_atlas.png"
)

OUTPUT = (
    ROOT
    / "asset_drop/source_work/meridian_civic_floor"
    / "meridian_civic_floor_atlas__alpha_clean.png"
)

CELL = 32

# These are actual opaque ground materials. Never punch transparency through
# them: they are drawn as the continuous civic floor beneath detail cells.
KEEP_OPAQUE = {
    # Clean civic.
    (0, 0), (1, 0), (2, 0), (3, 0), (10, 0),
    (8, 1), (11, 1), (12, 1),
    (0, 2), (10, 2),

    # Worn civic.
    (4, 0), (5, 0), (6, 0), (7, 0),

    # Road base.
    (0, 5), (1, 5), (2, 5), (3, 5), (11, 5), (12, 5),

    # Market / rough ground.
    *{(x, 8) for x in range(16)},
    *{(x, 9) for x in range(14)},
    (15, 9),
}

FLOOD_THRESHOLD = 30
HALO_THRESHOLD = 48


def dark(pixel, threshold):
    r, g, b, a = pixel
    return a > 0 and max(r, g, b) <= threshold


def neighbors4(x, y):
    yield x - 1, y
    yield x + 1, y
    yield x, y - 1
    yield x, y + 1


def main():
    image = Image.open(SOURCE).convert("RGBA")

    if image.size != (512, 512):
        raise SystemExit(
            f"Expected 512x512 atlas, got {image.width}x{image.height}"
        )

    pixels = image.load()

    for cy in range(16):
        for cx in range(16):
            if (cx, cy) in KEEP_OPAQUE:
                continue

            left = cx * CELL
            top = cy * CELL
            right = left + CELL
            bottom = top + CELL

            queue = deque()
            visited = set()
            remove = set()

            # Seed every outside edge of this cell independently.
            for x in range(left, right):
                queue.append((x, top))
                queue.append((x, bottom - 1))

            for y in range(top, bottom):
                queue.append((left, y))
                queue.append((right - 1, y))

            while queue:
                x, y = queue.popleft()

                if (x, y) in visited:
                    continue

                visited.add((x, y))

                if not (
                    left <= x < right
                    and top <= y < bottom
                ):
                    continue

                if not dark(pixels[x, y], FLOOD_THRESHOLD):
                    continue

                remove.add((x, y))

                for nx, ny in neighbors4(x, y):
                    if (
                        left <= nx < right
                        and top <= ny < bottom
                        and (nx, ny) not in visited
                    ):
                        queue.append((nx, ny))

            for x, y in remove:
                pixels[x, y] = (0, 0, 0, 0)

            halo = set()

            for y in range(top, bottom):
                for x in range(left, right):
                    if pixels[x, y][3] == 0:
                        continue

                    if not dark(pixels[x, y], HALO_THRESHOLD):
                        continue

                    touching_alpha = False

                    for nx, ny in neighbors4(x, y):
                        if not (
                            left <= nx < right
                            and top <= ny < bottom
                        ):
                            touching_alpha = True
                            break

                        if pixels[nx, ny][3] == 0:
                            touching_alpha = True
                            break

                    if touching_alpha:
                        halo.add((x, y))

            for x, y in halo:
                pixels[x, y] = (0, 0, 0, 0)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT)

    print(f"WROTE {OUTPUT}")
    print("Ground cells preserved opaque.")
    print("Border-connected black negative space removed from detail cells.")


if __name__ == "__main__":
    main()
