"""Canonical filename generation — the single source for output filenames."""

from __future__ import annotations

import sys
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_key import AssetKey


def canonical_filename(key: AssetKey) -> str:
    """Generate canonical runtime filename from semantic identity.

    Format: <owner>__<layer>__<action_group>__<variant>__<direction>__<N>f__<WxH>.png
    """
    if key.frame_width == key.frame_height:
        size = str(key.frame_width)
    else:
        size = f"{key.frame_width}x{key.frame_height}"

    return "__".join(
        (
            key.owner,
            key.layer,
            key.action_group,
            key.variant,
            key.direction,
            f"{key.frames}f",
            size,
        )
    ) + ".png"
