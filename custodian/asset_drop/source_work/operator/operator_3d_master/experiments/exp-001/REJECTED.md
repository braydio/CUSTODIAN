# exp-001 — REJECTED (technical run only)

Blender 5.2.3 executed `scripts/create_blend.py` unmodified; the .blend and 8 + 15 renders exist.
They are **not usable**:
- Character lies on its side: mesh is authored Z-up but written to glTF unconverted; Blender's importer treats it as Y-up.
- Vertex colours never reach a shader (single `DefaultMaterial`), so everything renders flat grey.
- Cloak is a huge flared fan unlike the reference's short tunic and hood drape.
- E/W-side camera azimuths are mirrored relative to the facing convention (camera at +X shows the character facing screen-left).
- Framing is a 512px/2.70m ortho box, not the 128px root (64,106) contract.
Kept as evidence per handoff rules. Fixes go into exp-002; this record is not rewritten.
