#!/usr/bin/env python3
"""Validate the Hub/Sepulcher/Awakening/Dust Lung V2 art source roadmap.

Read-only; no source approval, asset ingestion, image generation, or runtime edits.
Run from any directory: python3 custodian/tools/validation/validate_hub_art_manifest.py
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "design" / "04_architecture"
MANIFEST = BASE / "HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.json"
MIRROR = BASE / "HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.md"
GEOMETRY = BASE / "SEPULCHER_GARDENS_GEOMETRY_V1.json"
EXPECTED = {"core": 198, "optional": 36, "all_prompts": 234, "generation_sets": 193}
LEGACY_SETS = (
    [f"CAL-{n:02d}" for n in range(1, 7)]
    + [f"B1-{n:02d}" for n in range(1, 10)]
    + [f"B2-{n:02d}" for n in range(1, 21)]
    + [f"AP-{n:02d}" for n in range(1, 25)]
    + [f"DL-{n:02d}" for n in range(1, 9)]
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def validate() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    geometry = json.loads(GEOMETRY.read_text(encoding="utf-8"))
    markdown = MIRROR.read_text(encoding="utf-8")
    core = manifest["assets"]
    optional = manifest["optional_assets"]
    sets = manifest["generation_sets"]
    families = manifest["family_contracts"]
    counts = manifest["counts"]

    for name, n in EXPECTED.items():
        actual = len(core) if name == "core" else len(optional) if name == "optional" else (
            len(sets) if name == "generation_sets" else len(core) + len(optional)
        )
        require(actual == n, f"{name}: expected {n} actual {actual}")
        require(counts[name] == n, f"manifest counts.{name} drifted")

    ids = [a["id"] for a in core]
    optional_ids = [a["id"] for a in optional]
    all_ids = ids + optional_ids
    family_ids = [f["id"] for f in families]
    set_ids = [s["set_id"] for s in sets]
    require(len(set(ids)) == len(ids), "duplicate core state identity")
    require(len(set(all_ids)) == len(all_ids), "duplicate optional/core state identity")
    require(len(set(family_ids)) == len(family_ids), "duplicate family")
    require(len(set(set_ids)) == len(set_ids), "duplicate generation-set ID")
    require(all(k in set_ids for k in LEGACY_SETS), "previous 67 generation-set IDs not preserved")
    require(len(LEGACY_SETS) == 67, "legacy set baseline drifted")
    require(all(s["order"] == i for i, s in enumerate(sets, start=1)), "generation-set order not contiguous")

    assigned = [aid for s in sets for aid in s["asset_ids"]]
    require(len(assigned) == len(core), "set cardinality does not cover each required state once")
    require(set(assigned) == set(ids), "set contains unknown/missing required asset")
    require(len(set(assigned)) == len(assigned), "a required state dispatched by multiple sets")
    require(not set(optional_ids).intersection(assigned), "optional state auto-dispatched")
    require(all(len(s["asset_ids"]) >= 1 for s in sets), "empty generation set")

    required_fields = (
        "id", "family_id", "state_id", "area", "kind", "source_work_path",
        "inbox_path", "family_contract_path", "normalized_canvas", "frame_size",
        "frames", "layout", "alpha", "anchor", "placement_rule",
        "image_generation_prompt", "human_image_approval", "registration_status",
    )
    for a in core + optional:
        aid = a["id"]
        require(all(k in a for k in required_fields), f"missing fields in {aid}")
        require(aid == f'{a["family_id"]}/{a["state_id"]}', f"family/state mismatch {aid}")
        require(a["family_id"] in family_ids, f"unlisted family {aid}")
        require(a["family_contract_path"].endswith(f'{a["family_id"]}.asset.json'), f"schema path {aid}")
        require(a["source_work_path"].startswith("custodian/asset_drop/source_work/"), f"source path {aid}")
        require(a["source_work_path"].endswith(f'/{a["state_id"]}_source.png'), f"source filename {aid}")
        require(a["inbox_path"] == f'custodian/asset_drop/inbox/{aid}.png', f"inbox identity {aid}")
        require(a["image_generation_prompt"].strip() and len(a["image_generation_prompt"]) >= 150, f"short/empty prompt {aid}")
        require(a["anchor"].strip() and a["placement_rule"].strip(), f"unbounded geometry {aid}")
        width, height = a["normalized_canvas"]["width"], a["normalized_canvas"]["height"]
        fw, fh = a["frame_size"]["width"], a["frame_size"]["height"]
        frames = a["frames"]
        require(all(isinstance(v, int) and v > 0 and v % 32 == 0 for v in (width, height, fw, fh)), f"32px canvas violation {aid}")
        require(isinstance(frames, int) and 1 <= frames <= 4, f"invalid frame count {aid}")
        if a["layout"] == "copy":
            require(frames == 1 and (width, height) == (fw, fh), f"copy layout mismatch {aid}")
        elif a["layout"] == "horizontal_strip":
            require((width, height) == (fw * frames, fh), f"strip layout mismatch {aid}")
        else:
            raise AssertionError(f"unexpected frame layout {aid}: {a['layout']}")
        approved = str(a["human_image_approval"]).lower() in {"approved", "source_approved"}
        if approved:
            require(bool(a.get("source_sha256")), f"human approval missing source hash {aid}")
        require(f"#### \`{aid}\`".replace("\\", "") in markdown, f"missing Markdown entry {aid}")
        require("**Generation prompt:** " + a["image_generation_prompt"] in markdown, f"prompt mirror drift {aid}")

    markdown_ids = re.findall(r"^#### \`([^\`]+)\`", markdown, flags=re.MULTILINE)
    require(len(markdown_ids) == EXPECTED["all_prompts"], "Markdown state count differs")
    require(set(markdown_ids) == set(all_ids), "Markdown IDs differ from JSON")

    current = manifest["checkpoint"].get("next_candidate_generation_set_id")
    require(current in set_ids, "candidate cursor points to unknown set")
    valid_assets = set(ids)
    for receipt in manifest["checkpoint"].get("candidate_staging_receipts", []):
        require(receipt.get("asset_id") in valid_assets, "candidate receipt asset unknown")
        require(receipt.get("candidate_status") == "PASS_CANDIDATE", "unreviewed candidate receipt")
        require(receipt.get("candidate_upload_verified") is True, "candidate receipt not verified")
        require(receipt.get("dropbox_file_id") and receipt.get("dropbox_revision"), "Dropbox ID/revision missing")
        require(re.fullmatch(r"[0-9a-f]{64}", receipt.get("candidate_source_sha256", "")), "candidate SHA invalid")
        require(receipt.get("candidate_dropbox_path", "").startswith(
            "/CUSTODIAN/candidate_staging/hub-sepulcher-awakening-art-v1/"
        ), "candidate outside authorized Dropbox lane")

    cal02 = next(a for a in core if a["id"] == "hub_first_set_sepulcher_gardens_environment/structural_presentation")
    require(cal02["normalized_canvas"] == {"width": 384, "height": 576}, "CAL-02 canvas drift")
    require("RGBA" in cal02["alpha"], "CAL-02 alpha drift")
    require(cal02["geometry_authorization"]["obstacle_id"] == "D6", "CAL-02 footprint drift")
    d6 = next(o for o in geometry["obstacles"] if o["id"] == "D6")
    require(cal02["geometry_authorization"]["polygon_world"] == d6["world_polygon"], "CAL-02 polygon diverged")
    require(geometry["envelope"]["grid_wh"] == [96, 84], "Gardens live-mask reference changed")
    zones = manifest["new_world_roadmap"]["inner_architectural_zones"]
    require(len(zones) == 4 and {z["id"] for z in zones} == {"I01", "I02", "I03", "I04"},
            "four interior zones missing")
    interiors = [a for a in core if a["family_id"] == "hub_first_set_sepulcher_interiors_v2"]
    require(len(interiors) == 16, "four interior suites missing assets")
    require(len([a for a in core if a["family_id"] == "hub_first_set_sepulcher_shoreline_v2"]) == 20,
            "shoreline profile inventory drift")

    for k in ("L01", "L02", "L03", "L04", "L05", "L06", "L07", "L08", "L09", "L10"):
        require(any(k in a.get("geometry_binding", "") for a in core),
                f"landmark {k} has no new geometry-bound art")
    for k in ("S1", "S2", "S3", "S4", "S5"):
        require(len([a for a in core if a["family_id"] == "hub_first_set_sepulcher_story_cues_v2"
                     and k in a.get("geometry_binding", "")]) == 2,
                f"secret visual cues incomplete for {k}")

    print("PASS: 198 core, 36 optional, 234 individual prompts, 193 ordered sets, "
          "67 legacy set IDs, 4 interiors, 20 shore states, 10 landmark IDs, "
          "5 story sites, CAL-02 D6 geometry and Markdown parity")


if __name__ == "__main__":
    validate()
