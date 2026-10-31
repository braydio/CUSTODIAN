#!/usr/bin/env python3
"""Verify AP2 Alpine cliff Asset V2 outputs and optionally record evidence.

Default mode is read-only. ``--record`` writes a compact verification receipt
and links its hash from the 26 matching generated asset-catalog entries.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PREP = ROOT / "asset_drop/production_prep/alpine_cliff_presentation_v1"
DERIVATION = PREP / "derivation_report.json"
RECEIPT = PREP / "asset_contract_verification.json"
CATALOG = ROOT / "content/metadata/assets/generated/asset_catalog.generated.json"
EXPECTED_ZIP_SHA256 = "e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3"
ALPHA_CUTOFF = 8
EXPECTED_CONTACT_SIZES = {
    "south_broad_01": [1024, 512], "south_broken_01": [1024, 512], "south_rooted_01": [1024, 512],
    "east_broad_01": [512, 1024], "west_broad_01": [512, 1024], "north_broad_01": [1024, 320],
    "corner_se_01": [768, 768], "corner_sw_01": [768, 768], "corner_ne_01": [768, 768], "corner_nw_01": [768, 768],
}
SOCKET_INWARD_DIRECTIONS = {
    "south_broad_01": ((0, -1),), "south_broken_01": ((0, -1),), "south_rooted_01": ((0, -1),),
    "east_broad_01": ((-1, 0),), "west_broad_01": ((1, 0),), "north_broad_01": ((0, 1),),
    "corner_se_01": ((-1, 0), (0, -1)), "corner_sw_01": ((1, 0), (0, -1)),
    "corner_ne_01": ((-1, 0), (0, 1)), "corner_nw_01": ((1, 0), (0, 1)),
}
MIN_SOCKET_EMBED_PX = 24
SOCKET_EMBED_MIN_BY_STATE = {
    "south_broad_01": 96, "south_broken_01": 96, "south_rooted_01": 96,
}
def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--record", action="store_true", help="write receipt and record evidence on matching catalog entries")
    args = parser.parse_args()
    derivation = json.loads(DERIVATION.read_text(encoding="utf-8"))
    if derivation.get("source_master_batch") != "alpine-cliff-source-family-v1":
        raise SystemExit("unexpected source-master batch identity")
    if derivation.get("source_master_zip_sha256") != EXPECTED_ZIP_SHA256:
        raise SystemExit("derivation report does not retain the approved source-master ZIP checksum")
    if derivation.get("contact_socket_min_embed_px") != MIN_SOCKET_EMBED_PX:
        raise SystemExit("derivation report has a stale contact socket support threshold")
    if derivation.get("contact_socket_min_embed_by_state") != SOCKET_EMBED_MIN_BY_STATE:
        raise SystemExit("derivation report has stale state-specific socket support thresholds")
    families = {
        "procgen_alpine_cliff_fascia": json.loads((ROOT / "content/metadata/assets/families/procgen_alpine_cliff_fascia.asset.json").read_text()),
        "procgen_alpine_cliff_contact": json.loads((ROOT / "content/metadata/assets/families/procgen_alpine_cliff_contact.asset.json").read_text()),
        "procgen_depth_chunks": json.loads((ROOT / "content/metadata/assets/families/procgen_depth_chunks.asset.json").read_text()),
    }
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    derivation_items = derivation.get("outputs", [])
    if len(derivation_items) != 26:
        raise SystemExit(f"expected 26 derivation outputs, found {len(derivation_items)}")
    verified = []
    errors = []
    for item in derivation_items:
        family_id = str(item["family"])
        state = str(item["state"])
        family = families[family_id]
        state_contract = family["states"].get(state)
        if state_contract is None:
            errors.append(f"{family_id}/{state}: missing family state")
            continue
        output = ROOT / str(item["output"]).removeprefix("custodian/")
        if not output.is_file():
            errors.append(f"{family_id}/{state}: missing runtime file {output}")
            continue
        digest = sha256(output)
        with Image.open(output) as image:
            dimensions = list(image.size)
            mode = image.mode
            if family_id == "procgen_alpine_cliff_contact":
                alpha = image.convert("RGBA").getchannel("A")
                alpha_histogram = alpha.histogram()
                if sum(alpha_histogram[1:255]) > 0:
                    errors.append(f"{family_id}/{state}: geological alpha contains feathered/partial pixels")
                alpha_bounds = alpha.getbbox()
                if alpha_bounds is None:
                    errors.append(f"{family_id}/{state}: contact has no visible pixels")
                else:
                    left, top, right, bottom = alpha_bounds
                    margins = [left, top, dimensions[0] - right, dimensions[1] - bottom]
                    if min(margins) < 16:
                        errors.append(f"{family_id}/{state}: transparent contact margin below 16 px: {margins}")
                    opaque = sum(alpha.histogram()[ALPHA_CUTOFF + 1 :])
                    if opaque / max(1, dimensions[0] * dimensions[1]) >= 0.98:
                        errors.append(f"{family_id}/{state}: contact silhouette is near-rectangular and opaque")
                if dimensions != EXPECTED_CONTACT_SIZES.get(state):
                    errors.append(f"{family_id}/{state}: exact runtime dimensions mismatch: {dimensions}")
                if not item.get("alpha_crop_wall_ok", False):
                    errors.append(f"{family_id}/{state}: derivation did not pass irregular alpha/crop-wall validation")
                socket_sides = set(item.get("socket_sides", []))
                if alpha_bounds is not None:
                    left, top, right, bottom = alpha_bounds
                    edge_pixels = {
                        "left": [alpha.getpixel((left, y)) > ALPHA_CUTOFF for y in range(top, bottom)],
                        "right": [alpha.getpixel((right - 1, y)) > ALPHA_CUTOFF for y in range(top, bottom)],
                        "top": [alpha.getpixel((x, top)) > ALPHA_CUTOFF for x in range(left, right)],
                        "bottom": [alpha.getpixel((x, bottom - 1)) > ALPHA_CUTOFF for x in range(left, right)],
                    }
                    for edge, values in edge_pixels.items():
                        longest = run = 0
                        for visible in values:
                            run = run + 1 if visible else 0
                            longest = max(longest, run)
                        if edge not in socket_sides and longest >= max(8, round(len(values) * 0.25)):
                            errors.append(f"{family_id}/{state}: runtime has unowned straight crop wall on {edge} edge ({longest}/{len(values)} px)")
                socket = item.get("socket_px")
                if not isinstance(socket, list) or len(socket) != 2:
                    errors.append(f"{family_id}/{state}: authored frontier socket is missing")
                elif alpha_bounds is not None:
                    sx, sy = int(socket[0]), int(socket[1])
                    if not (0 <= sx < dimensions[0] and 0 <= sy < dimensions[1]) or alpha.getpixel((sx, sy)) <= ALPHA_CUTOFF:
                        errors.append(f"{family_id}/{state}: socket does not land on opaque geology: {socket}")
                    else:
                        embed_depths = []
                        for dx, dy in SOCKET_INWARD_DIRECTIONS[state]:
                            depth = 0
                            x, y = sx, sy
                            while 0 <= x < dimensions[0] and 0 <= y < dimensions[1] and alpha.getpixel((x, y)) > ALPHA_CUTOFF:
                                depth += 1
                                x += dx
                                y += dy
                            embed_depths.append(depth)
                            minimum_embed = SOCKET_EMBED_MIN_BY_STATE.get(state, MIN_SOCKET_EMBED_PX)
                            if depth < minimum_embed:
                                errors.append(f"{family_id}/{state}: socket only touches silhouette on inward axis ({depth}px < {minimum_embed}px)")
                        reported_depths = item.get("socket_embed_depth_px", {})
                        expected_axes = {"x" if dx else "y" for dx, dy in SOCKET_INWARD_DIRECTIONS[state]}
                        if set(reported_depths) != expected_axes:
                            errors.append(f"{family_id}/{state}: derivation report has incomplete socket support depths")
                        elif any(int(value) < SOCKET_EMBED_MIN_BY_STATE.get(state, MIN_SOCKET_EMBED_PX) for value in reported_depths.values()):
                            errors.append(f"{family_id}/{state}: derivation report records insufficient socket support: {reported_depths}")
        if digest != item["output_sha256"]:
            errors.append(f"{family_id}/{state}: runtime checksum differs from derivation report")
        if dimensions != item["output_size"]:
            errors.append(f"{family_id}/{state}: runtime dimensions differ from derivation report")
        if mode != "RGBA":
            errors.append(f"{family_id}/{state}: runtime PNG mode is {mode}, expected RGBA")
        source = ROOT / "asset_drop/source_work" / str(item["source"])
        if not source.is_file() or sha256(source) != item["source_sha256"]:
            errors.append(f"{family_id}/{state}: source master missing or changed")
        entry = catalog.get("families", {}).get(family_id, {}).get("assets", {}).get(f"{state}::omni")
        if not entry or entry.get("path") != item["output"].removeprefix("custodian/"):
            errors.append(f"{family_id}/{state}: Asset V2 catalog binding missing or mismatched")
        elif entry.get("sha256") != digest:
            errors.append(f"{family_id}/{state}: Asset V2 catalog checksum mismatch")
        if not output.with_name(output.name + ".import").is_file():
            errors.append(f"{family_id}/{state}: missing Godot import sidecar")
        verified.append({
            "family": family_id,
            "state": state,
            "path": output.relative_to(ROOT).as_posix(),
            "size_bytes": output.stat().st_size,
            "dimensions": dimensions,
            "mode": mode,
            "sha256": digest,
            "alpha_bounds": list(alpha_bounds) if family_id == "procgen_alpine_cliff_contact" and alpha_bounds is not None else None,
            "source_sha256": item["source_sha256"],
            "imported": output.with_name(output.name + ".import").is_file(),
        })
    expected = {"procgen_alpine_cliff_fascia": 12, "procgen_alpine_cliff_contact": 10, "procgen_depth_chunks": 4}
    for family, count in expected.items():
        actual = sum(item["family"] == family for item in verified)
        if actual != count:
            errors.append(f"{family}: expected {count} verified states, found {actual}")
    if errors:
        raise SystemExit("Asset V2 verification failed:\n  " + "\n  ".join(errors))
    receipt = {
        "schema": "custodian.alpine_cliff_presentation_asset_verification.v1",
        "source_master_batch": "alpine-cliff-source-family-v1",
        "source_master_zip_sha256": EXPECTED_ZIP_SHA256,
        "verified_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "state_counts": expected,
        "total_states": len(verified),
        "states": verified,
    }
    if args.record:
        RECEIPT.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        evidence = {"path": RECEIPT.relative_to(ROOT).as_posix(), "sha256": sha256(RECEIPT)}
        for item in verified:
            entry = catalog["families"][item["family"]]["assets"][f"{item['state']}::omni"]
            entry["validation_evidence"] = [evidence]
        CATALOG.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
        print(f"Recorded evidence {evidence['sha256']} for {len(verified)} Asset V2 states")
    else:
        print(f"Verified {len(verified)} AP2 states from source-master batch; use --record to persist catalog evidence")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
