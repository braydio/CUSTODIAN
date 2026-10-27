# Claude execution queue: Operator 3D / smallest useful next proof

**This file is the NEXT ACTIONS entrypoint.** On branch `agent/operator-3d-master-modeling-proof-v1` work in the **existing** worktree only. Long-form authority and constraints are in `CLAUDE_CONTINUATION_MCP_AND_EXP006.md`; `CANDIDATES.md` records prior experiments. Do not re-audit the repository. Start at **T0**, proceed only when each gate passes. Execute, don't re-plan.

**Absolute rule:** The Operator has **NO CAPE, NO CLOAK, NO SHOULDER MANTLE**. Retain source-grounded hood and gold-edged **tunic/tabard panels**. Exp-005 is an **unapproved** geometry parent. No best selection, no runtime promotion, no main merge. All frozen exp-001..005 are immutable. Canonical 8-view design and idle SHA256 are already verified in the previous report: recheck local bytes only if references change.

**Environment vars used below** (run in your shell, not a parent/root checkout):
```bash
W=/home/braydenchaffee/Projects/.custodian-worktrees/operator-3d-master-modeling-proof-v1-20261027T094310Z-29f13eccf5dc
A="$W/custodian/asset_drop/source_work/operator/operator_3d_master"
BR=agent/operator-3d-master-modeling-proof-v1
cd "$W"
```

## T0. Sync safely and preserve baseline (no code changes)

```bash
git status --short --branch
git fetch origin "$BR"
git merge-base --is-ancestor HEAD "origin/$BR" || { echo "DIVERGED; STOP AND REPORT"; exit 1; }
test -z "$(git status --porcelain)" || { echo "DIRTY WORKTREE; STOP; DO NOT RESET OR STASH"; exit 1; }
git merge --ff-only "origin/$BR"
blender --version | head -3
python "$A/scripts/experiments.py" status
```
**Gate:** clean existing worktree, all old experiments present, blender 5.2.3 LTS as previously reported. If different, document it; do not reinstall automatically. Do not rewrite any `.blend`, manifest, proof or source reference in exp-001..005.

## T1. Configure optional interactive Blender MCP; cap setup effort

Official docs **https://www.blender.org/lab/mcp-server/**. Blender 5.1+ required; existing 5.2.3 satisfies. **Security: MCP can run unrestricted Blender Python.** Use a separate unprivileged/isolated art-only Blender session with no tokens or sensitive paths, and loopback-bound transport. Never bind public/LAN/Tailscale. Do not download/run unreviewed shell scripts or alter project-wide `.mcp.json` or `~/.codex/config.toml`.

1. Inspect `claude mcp list`, `uv --version`, installed Blender add-ons and `ss -ltn`. If the official Blender Lab add-on/client server is **already configured and makes one safe read-only round trip**, record that and skip installation.
2. Otherwise install the official Blender Lab MCP add-on **per current official docs**, and only its necessary server dependencies to a *user-owned tools folder outside this repo*. If `uv` or system dependency installation would need sudo, **request the user's permission** rather than escalating or changing the system. Configure **Claude local scope in this art worktree**, not a global/default workspace. If official repo uses the documented `mcp/pyproject.toml` entry point, configure the Claude command as `claude mcp add --scope local blender -- uv --directory /ABSOLUTE/PATH/TO/blender_mcp/mcp run blender-mcp`; check that this exact command is supported by installed client, and never create a duplicate named `blender`.
3. In a disposable Blender session, confirm the listener is only localhost, Claude discovers the tools, and perform one actual **read-only** scene/object count. Store proof and exact versions in `TOOLING_SETUP_RECEIPT.md`.

**Gate:** working isolated MCP, OR one focused troubleshooting pass followed by **fallback to the already-proven headless `blender -b` workflow**. Never block modeling on MCP. MCP must never mutate a frozen experiment. Only scripted files/parameters produce accepted proof.

## T2. One serious geometry revision: exp-006

**Files to inspect (only these first):** `scripts/generate_mesh.py`, `scripts/create_blend.py`, `scripts/run_blender.py`, `scripts/experiments.py`, `config/shape_v005.json`, `experiments/exp-005/shape.json`, `CANDIDATES.md`; canonical images for visual comparison. Do not explore other subsystems.

1. Before editing `scripts/generate_mesh.py`, preserve the exact prechange generator as `scripts/generate_mesh_v1_exp001_to005.py`. Preserve the sha of the old code in exp-006 provenance, so earlier candidates remain reproducible. Keep `scripts/create_blend_v1_exp001.py` unchanged.
2. Copy exp-005's **immutable `shape.json` snapshot**, not a later-mutated config, to new `config/shape_v006.json` (assert destination absent first). Add *explicit* `cape_enabled:false` / clean garment flags if useful; eliminate all **invented cape and back mantle meshes** from exp-006 `scripts/generate_mesh.py`. Retain source-faithful tabard and hood. Preserve old `cape_hem_z` and `cloak_spread` fields only as legacy inert inputs needed to understand old candidate config.
3. Target precisely **five** visual issues: (a) peaked soft hood (no halo `Trim__hood_opening`); (b) flatten/surface-shape spherical pauldrons and articulate arm and leg armor rather than beads; (c) gold at tunic/plate **edges**, not toroidal limb rings; (d) coherent layered front tabard/tunic, **no cape**; (e) boots actually contact ground, including heel and toe. Keep rig groups stable; any renamed/removed objects must be accounted for by the builder.
4. Build only **one** named candidate:
```bash
cd "$A"
test ! -e config/shape_v006.json || { echo 'Already exists; inspect instead of overwrite'; exit 1; }
cp experiments/exp-005/shape.json config/shape_v006.json
# Apply exp-006 config changes and deterministic generator edits before 'new':
python scripts/experiments.py new --id exp-006 --config config/shape_v006.json
python scripts/run_blender.py --experiment exp-006
python scripts/build_review.py --experiment exp-006
python scripts/build_candidate_sheet.py review_pack/source_exp005_exp006.png exp-005 exp-006
```
Stop on failed command and report its log; no hidden automatic retry or unbounded shape search. If exp-006 is partially generated, repair without falsifying a frozen proof; if changing candidate geometry materially after a completed build, use a new ID rather than pretending same hashes describe it.

**Geometry gate:** real reopenable Blender file; 8 *unmirrored* 128px camera views, 15 NE frames, image root (64,106), ground row 107, expected ~84–88px body. Source comparison must show **no cape in any direction**. Reject floating gold halo/spherical shoulder/beaded limb and feet-hover regressions even when IoU improves. IoU is triage only.

## T3. Make a motion/contact review and freeze only once

Inspect `experiments/exp-006/blender_proof` and `scripts/build_review.py`. Add a **small deterministic** stance diagnostic if absent: report separately per foot true stance frames (exclude lift/transitions), sole height, 3D world-frame X/Y planar displacement, mean/max world-space planted movement per frame, foot penetration/hover, left/right support handoff, and F15→F1 seam. If walking in-place, say which coordinate frame and root motion you used. IK reach=0 by itself is not a skate test. Do not change canonical timing: the 15 fps GIF is a preview.

```bash
cd "$A"
# Only after the actual renders, QA report, review sheets/GIF and provenance exist:
python scripts/freeze_proof.py --experiment exp-006 --notes 'No-cape canonical modeling proof; NOT artist-approved; 15f NE preview FPS provisional'
```

**Gate:** receipt hashes every evidence file, previous receipts still verify, no unapproved candidate selected. If failure, stop with exact issue.

## T4. Optional exp-007 lookdev ONLY, then publish one comparison

**Condition:** create exp-007 ONLY if exp-006 clearly fixes missing cape, hood silhouette, pauldron anatomy and garment topology but still needs value/material tuning. Limit changes to shading/readability/gold edge response, not a complete anatomy redesign. If exp-006 is still far from canonical identity, **skip exp-007**, document why, and recommend a sculpt/retopology path rather than another procedural primitive sweep. Same immutable creation/render/review/freeze steps if created, substituting exp-007 and a fresh config.

**Publish one compact review packet**, **not** thousands of generated images. At minimum include:
- source vs exp-005 vs exp-006 (and exp-007 if justified), eight directions at native 128px, high-res/contact sheet, image hashes
- genuine 15-frame NE strip and animated GIF (label FPS PROVISIONAL), stance contact table and seam result
- one-page blunt failures and "technical proof != artist approval", frozen hashes and local paths, exact Dropbox review links if uploaded

Run the repo's **existing** publisher, no custom Dropbox upload code. Before upload check `python "$W/custodian/tools/iteration/publish_review_artifacts.py" --doctor`; run `--dry-run --important --reason ... --workstream operator-3d-master --source "$A/review_pack" --question 'Does the capeless Operator match the canonical 8-direction identity and is NE walking believable?'`; then if correct use `--important --retain-after-review` with the same args, using existing configured remote. Capture returned manifest and verify files actually uploaded. If publisher cannot include GIF, attach it explicitly with `--artifact`. A failed upload is a reported failure, not success.

## T5. Exit contract and token budget

**Do not** run a broad architecture audit, graph refresh, full Godot CI, unrelated formatting, another agent delegation, or an exhaustive model search. Work from the listed files. One setup fix, one geometry candidate, and at most one lookdev contrast; no looping autonomous polish. Do not install additional AI/image/video tools. Commit source scripts/configs, hashes, summary and selective review artifacts to the **same branch**, not main. **Do not touch** runtime Operator sprites/gates or archive/rework the older NE cutout packet. If a new design isn't recognizably closer at 128px, say so.

Final Claude response **<=250 words** with EXACT sections: **Tooling** (MCP success/fallback), **Candidates** (what changed, hashes), **QA** (notably no-cape/contact), **Review** (one Dropbox link and 2-3 filenames or failure), **Blockers**, **Git** (branch/commit). Do not paste command output, repo history, or giant manifests. Leave art worktree intact and return shell to clean `~/Projects/CUSTODIAN` `main` when done.
