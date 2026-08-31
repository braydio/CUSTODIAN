#!/usr/bin/env python3
"""Generate a static Godot wall catalog from meridian_civic_wall.semantic.json.

Usage:
  python3 tools/art/build_meridian_civic_wall_runtime_catalog.py \
    content/metadata/assets/meridian_civic_wall.semantic.json \
    game/world/levels/authored/ash_bell/common/meridian_civic_wall_runtime_catalog.gd
"""
import json
import sys
from pathlib import Path

def gd(v):
    if v is None: return "null"
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, str): return json.dumps(v)
    if isinstance(v, (int, float)): return repr(v)
    if isinstance(v, list):
        if len(v) == 2 and all(isinstance(x, int) for x in v):
            return f"Vector2i({v[0]}, {v[1]})"
        return "[" + ", ".join(gd(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{\n" + ",\n".join(
            f"\t{json.dumps(k)}: {gd(value)}" for k, value in v.items()
        ) + "\n}"
    raise TypeError(type(v))

def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: build_meridian_civic_wall_runtime_catalog.py <manifest> <output.gd>")

    doc = json.loads(Path(sys.argv[1]).read_text())
    if doc.get("schema") != "custodian.semantic_wall_manifest.v2":
        raise SystemExit(f"expected v2 manifest, got {doc.get('schema')}")

    rows = []
    auto = {}

    for e in doc["entries"]:
        c = e["composer"]
        slim = {
            "coord": e["runtime_coord"],
            "name": e["semantic_name"],
            "family": e["family"],
            "geometry": e["geometry_class"],
            "condition": e["condition"],
            "auto": c["auto_compose"],
            "ports": c["ports"] or [],
            "topology": c["topology"],
            "scope": c["selection_scope"],
        }
        rows.append((e["id"], slim))
        if c["auto_compose"]:
            key = f'{c["topology"]}|{e["family"]}'
            auto.setdefault(key, []).append(e["runtime_coord"])

    lines = [
        "class_name MeridianCivicWallRuntimeCatalog",
        "extends RefCounted",
        "",
        "const CELL_SIZE := 32",
        "const LOGICAL_GRID := Vector2i(14, 14)",
        "const RUNTIME_GRID := Vector2i(16, 16)",
        "const INVALID := Vector2i(-1, -1)",
        "",
        "const ENTRIES := {",
    ]

    for i, (eid, data) in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f'\t{json.dumps(eid)}: {gd(data)}{comma}')

    lines += ["}", "", "const AUTO_VARIANTS := {"]
    items = list(auto.items())
    for i, (key, coords) in enumerate(items):
        arr = ", ".join(f"Vector2i({c[0]}, {c[1]})" for c in coords)
        comma = "," if i < len(items) - 1 else ""
        lines.append(f'\t{json.dumps(key)}: [{arr}]{comma}')

    lines += [
        "}",
        "",
        "static func get_entry(id: StringName) -> Dictionary:",
        '\treturn (ENTRIES.get(String(id), {}) as Dictionary).duplicate(true)',
        "",
        "static func variants(topology: StringName, family: StringName) -> Array:",
        '\tvar key := "%s|%s" % [String(topology), String(family)]',
        "\treturn (AUTO_VARIANTS.get(key, []) as Array).duplicate()",
        "",
        "static func is_valid_runtime_coord(coord: Vector2i) -> bool:",
        "\treturn coord.x >= 0 and coord.y >= 0 and coord.x < 14 and coord.y < 14",
        "",
        "static func source_region(coord: Vector2i) -> Rect2i:",
        "\tif not is_valid_runtime_coord(coord):",
        "\t\treturn Rect2i()",
        "\treturn Rect2i(coord * CELL_SIZE, Vector2i.ONE * CELL_SIZE)",
    ]

    out = Path(sys.argv[2])
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines))
    print(f"WROTE {out}")
    print(f"entries={len(rows)} auto-groups={len(auto)}")

if __name__ == "__main__":
    main()
