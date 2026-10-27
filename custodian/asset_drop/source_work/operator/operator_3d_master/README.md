# CUSTODIAN Operator volumetric 3D starter | candidate v001

**Working model available immediately:** `assets/operator_volumetric_v001.glb` is a Blender-importable true 3D mesh with individually named submeshes. It is **not the canonical Operator yet**. It has not been visually matched to the approved eight-direction source.

**No Blender binary was present in the environment used to make this bundle.** `scripts/create_blend.py` is therefore an executable Blender source file, **not a claim that a `.blend` file or animation has been built/tested here**. A `.blend` file will appear only after running the next command in actual Blender.

## Open the mesh now
Blender → File → Import → glTF 2.0 → `assets/operator_volumetric_v001.glb`. You can inspect/reposition/edit each armored volume, boot, hood, visor and one-piece cloak.

## Create an editable rigged .blend locally
From this unpacked bundle's root, with Blender 4.3+ or 5.x installed:

```bash
blender -b -t 2 --python scripts/create_blend.py -- \
  --glb assets/operator_volumetric_v001.glb \
  --out experiments/exp-001/operator_v001.blend \
  --proof experiments/exp-001/blender_proof
```

This is intended to produce `operator_v001.blend`, an editable named character armature, two foot-IK targets, 15-frame NE walk preview action, eight fixed-angle orthographic cameras, eight neutral PNGs and 15 walk PNGs. **This step still requires actual execution and correction/validation on your machine.**

## Generate experiments safely

```bash
python scripts/experiments.py new --id exp-002 --config config/shape_v001.json
python scripts/experiments.py status
# after visual review / explicit user selection only:
python scripts/experiments.py select-best --id exp-002 \
  --reviewed-by-human --reason 'User approved silhouette + NE walk comparison'
```

Every `new` refuses to overwrite an existing experiment. Shape snapshot, mesh, machine QA and manifest are kept together. The selected best ID/hash is in `best_candidate.json`, and `selection_history.jsonl` is append-only. To roll back, select a prior hash-verified experiment. No command publishes to Godot runtime.

## Rebuild the supplied mesh deterministically

```bash
python scripts/generate_mesh.py --config config/shape_v001.json --out /tmp/operator_check.glb
python scripts/verify_candidate.py --glb /tmp/operator_check.glb --config config/shape_v001.json
# optional non-Blender geometry previews, requires VTK and Pillow
python scripts/preview_offline.py assets/operator_volumetric_v001.glb proof
```

## Scope and review
The source image references are locked by SHA and are in the project's Git LFS / Dropbox implementation inputs. Because they are not included in this downloadable prototype, this model is a **procedural geometric proposal**, not a faithful reconstruction. It needs direct visual comparison and manual/iterated mesh refinement. The VTK sheet is mechanical proof only.

Performance rule: **two or three reviewable modeling passes maximum before a go/no-go on this approach.** Prioritize read-at-128px silhouette and a convincing NE walk rather than adding microscopic details or converting the entire game to live 3D. See `CODEX_HANDOFF.md` for scoped instructions.

Once the actual Blender render has succeeded, freeze its `.blend` and proof hashes:

```bash
python scripts/freeze_proof.py --experiment exp-001 \
  --notes 'First true Blender walk proof; visual acceptance still pending'
```

The Blender builder refuses to overwrite an existing `.blend` or render proof. To make a new attempt, use the next `exp-00N` directory and keep the previous files intact.
