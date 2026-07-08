# Terrain Pack Ingest Report

- **Generated**: 2026-07-08 14:19:13
- **Repo Root**: `/home/braydenchaffee/Projects/CUSTODIAN`

## Summary

| Pack | Source | Runtime Dir | Tiles | Alpha Preserved | Status |
|---|---|---|---|---|---|
| connector | `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/source/generated/connector/indexed_tiles` | `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/runtime/connector` | 18 | yes (checker cleanup → transparent background) | **PASS** |
| ascent | `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/source/generated/ascent/ascent_pack_ai_source.png` | `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/runtime/ascent` | 20 | yes (alpha component detection preserves alpha, black void pixels kept) | **PASS** |
| chasm_bridge | `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/source/generated/chasm_bridge/chasm_bridge_pack_ai_source.png` | `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/runtime/chasm_bridge` | 24 | yes (alpha component detection preserves alpha, black void pixels kept) | **PASS** |

## Per-Pack Details

### Connector Pack

- **Script**: `normalize_connector_pack_tiles.py`
- **Exit Code**: 0
- **Source**: `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/source/generated/connector/indexed_tiles`
- **Runtime Dir**: `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/runtime/connector`
- **Tiles Generated**: 18
- **Alpha Preserved**: yes (checker cleanup → transparent background)
- **Warnings/Errors**: (none)
- **Result**: **PASS**

### Ascent Pack

- **Script**: `normalize_ascent_pack_sheet.py`
- **Exit Code**: 0
- **Source**: `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/source/generated/ascent/ascent_pack_ai_source.png`
- **Runtime Dir**: `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/runtime/ascent`
- **Tiles Generated**: 20
- **Alpha Preserved**: yes (alpha component detection preserves alpha, black void pixels kept)
- **Warnings/Errors**: (none)
- **Result**: **PASS**

### Chasm_Bridge Pack

- **Script**: `normalize_chasm_bridge_pack_sheet.py`
- **Exit Code**: 0
- **Source**: `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/source/generated/chasm_bridge/chasm_bridge_pack_ai_source.png`
- **Runtime Dir**: `/home/braydenchaffee/Projects/CUSTODIAN/content/tiles/terrain/runtime/chasm_bridge`
- **Tiles Generated**: 24
- **Alpha Preserved**: yes (alpha component detection preserves alpha, black void pixels kept)
- **Warnings/Errors**: (none)
- **Result**: **PASS**

---

## Combined Result: **PASS**

