# Claude continuation: Operator 3D master, Blender MCP, and bounded exp-006/007

**Decision type:** user-authorized continued source-work experimentation; **not** visual acceptance, an FPS decision, a selected best candidate, a runtime promotion, or a request to merge.  
**Working branch:** `agent/operator-3d-master-modeling-proof-v1`  
**Working worktree:** `/home/braydenchaffee/Projects/.custodian-worktrees/operator-3d-master-modeling-proof-v1-20261027T094310Z-29f13eccf5dc`  
**Reference first report:** commit `9fdf41116e14ff67521ca1c5673e5b98158e3f94`, root `OPERATOR_3D_MASTER_MODELING_PROOF_CLAUDE_SUMMARY.md`, and `CANDIDATES.md`.

## 0. Mandatory continuation / preservation

This is a continuation of the existing Claude modeling experiment, **not another parallel Operator authority or another branch/worktree**. Before doing anything, inspect `git status`, branch HEAD, and whether the existing worktree has uncommitted work. The user may have the local branch open. A read-only discrepancy audit comes first. The present handoff is committed remotely; while in the **clean** art worktree, fetch and fast-forward carefully, without reset, checkout -f, stash, or overwriting local changes. If dirty, preserve the local work and reconcile instead of forcing a pull.

Preserve all frozen experiment directories and byte hashes, including exp-001 REJECTED, exp-002 fixed baseline, exp-003 superseded, exp-004 stocky negative contrast, and exp-005 review candidate. Keep `scripts/create_blend_v1_exp001.py`, the corrected `scripts/create_blend.py`, `CANDIDATES.md`, candidate manifests, and rollback journal. **None is selected or human-approved**; never call `experiments.py select-best --reviewed-by-human` without a specific actual user judgment after visual review. A mean silhouette IoU 0.678 is a triage metric, not an art pass.

Protected: canonical locked design SHA256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`; authored idle SHA256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`. Resolve Git LFS **real bytes**, not 131-byte pointers. Remain `operator_2_5d_128`, 128x128, x=64, projected root (64,106), ground y=107, body height target 84–88px, ordered 8 independent cameras/directions. No mirrored views. FPS remains deliberately unapproved; 15 frames / 15 FPS is a **preview**, not canon.

No modifications to `operator.gd`, generation policy, selector, runtime PNGs, manifest/catalog/SpriteFrames, canonical idle, or NE rejected cutout workstream. No main merge, packet archive, worktree deletion, or automatic runtime promotion.

## 1. Blender tool integration: official Blender Lab MCP, not a substitute for scripted proof

Use the **Blender Lab MCP** first: https://www.blender.org/lab/mcp-server/ (source https://projects.blender.org/lab/blender_mcp). It is distinct from similarly named third-party `blender-mcp` projects. Blender 5.2.3 LTS already worked in this workstream; **do not reinstall Blender** just to satisfy this instruction. Do not install two competing Blender MCP add-ons.

**Security:** Blender Lab states that MCP can execute LLM-generated Python **without guards**, including filesystem/network-capable code. Restrict it to loopback, an isolated art-only Blender session with a disposable copy of a candidate, and preferably a separate unprivileged Linux user/container with no SSH credentials, personal files, tokens, production mounts or unnecessary network access. Never expose port 9876 to LAN/Tailscale/public interfaces. Do not grant MCP blanket shell/system access or run `--dangerously-skip-permissions`. Inspect code before executing scripts from the network. No `curl | sh`.

**Install/read-only diagnostics, Arch host:**
1. Inspect existing `blender --version`, `uv --version`, `git --version`, `claude mcp list`, `codex mcp list`, active extension IDs and listener ports before installing anything. Avoid duplicate installation. If `uv` is absent, obtain explicit local authorization for `sudo pacman -S --needed uv` (Arch's official Extra package); if sudo is unavailable, report the exact manual action, don't fabricate success.
2. In Blender UI, open https://www.blender.org/lab/mcp-server/#addon . Use **the official Blender Lab add-on**. Drag the install link into Blender twice if instructed, first to register Blender Lab's extension repository and then to install the extension, or install from disk via Blender Preferences. Enable the single `mcp` add-on and manually **Start MCP Server** in the add-on UI for this session. If the exact menu changes, follow the source documentation; don't guess UI actions or install unrelated add-ons.
3. If needed, clone the official server to a **user-owned tools path outside CUSTODIAN**, after inspecting its repository/version; for example:
   ```bash
   MCP_REPO="$HOME/.local/share/blender_mcp"
   # Only when this path does not already exist; inspect existing state first:
   git clone https://projects.blender.org/lab/blender_mcp.git "$MCP_REPO"
   # Verify the checkout contains mcp/pyproject.toml and the documented blender-mcp entry point.
   ```
   Do not git-pull an unrelated or locally modified directory. Record the exact upstream commit, add-on version and command. The server-side dependency environment belongs outside CUSTODIAN and must not write to the project's `.venv`, `.mcp.json`, or render/worktree infrastructure.
4. Prefer **Claude Code local scope** within this art worktree to avoid changing root coordination configuration. Provided the checkout structure/entry point are confirmed:
   ```bash
   cd /home/braydenchaffee/Projects/.custodian-worktrees/operator-3d-master-modeling-proof-v1-20261027T094310Z-29f13eccf5dc
   MCP_REPO="$HOME/.local/share/blender_mcp"
   claude mcp add --scope local blender -- uv --directory "$MCP_REPO/mcp" run blender-mcp
   claude mcp list
   claude mcp get blender
   ```
   A process restart/new Claude session may be needed to load a new MCP config. Use real absolute arguments expanded by the shell; **literal `$HOME` in MCP config does not expand**. Never overwrite an existing server named `blender` without identifying its provider and asking. Codex is secondary: if requested later, inspect existing `codex mcp list`, then `codex mcp add blender -- uv --directory "$MCP_REPO/mcp" run blender-mcp` only if supported by the installed CLI; avoid editing `~/.codex/config.toml` by hand if an existing definition already applies.
5. Verify **both halves**. Blender-side start must be running and bound to `127.0.0.1:9876`/localhost only (check `ss -ltn` and Blender preferences), MCP client tool discovery must succeed, and execute a **harmless read-only** `bpy.app.version_string`/object count through the actual MCP server in a disposable scene. A listed MCP registration without a successful Blender round trip is not a working integration. Capture versions, commands, connection test results, and any failures in `TOOLING_SETUP_RECEIPT.md`. If official MCP setup fails after one focused fix attempt, **fall back to existing headless Blender scripts**; do not burn the art budget debugging connectors.

MCP is for convenient *interactive inspect/model/pose/review*. **Deterministic, replayable production proofs still run from committed scripts using `blender -b`** with explicit input hashes. No arbitrary MCP-mutated open scene is accepted as candidate until exported to deterministic source parameters/meshes, saved as a new experiment, reopened and regenerated/re-verified in a fresh Blender session.

## 2. Art strategy: material improvements without another primitive treadmill

Reference the real eight-cell design lock + the accepted 15f idle in every direction. Exp-005 is a **useful implementation parent, not an accepted best**. The first failure is recognizability, not an IoU number; prioritize silhouette, anatomy, cloth construction and source value hierarchy. **Do not add a second whole-body model or iterate endlessly on numeric silhouette score.**

Create exactly **exp-006** as the principal controlled geometric revision, with discrete named submeshes and deterministic parameters:
- **Hood:** soft, forward-peaked cowl, thick fabric folds around a recessed face/visor; remove gold opening ring/halo *from all directions*, especially rear. Keep reference face/hood proportions; no oversized rigid helmet.
- **Shoulders/arms:** replace reflective ball pauldrons and bead-jointed tube segments with overlapping directional hard-surface plates and tapering upper-arm, elbow/forearm and wrist armor. Preserve articulation range, near/far order, and sleeve gaps hidden with actual undercloth volumes.
- **Chest/waist/legs:** strengthen anatomical transition and separation of chest plates, abdominal layer, belt/tabard, thighs, knees and greaves. No uniformly stacked cylinders. Correct stockiness without drifting into rejected exp-004.
- **Clothing:** model the reference's layered **gold-edged tunic/tabard panels** as contoured geometry, with folds, stitched edges and actual material boundaries. Keep cloak/mantle separate and coherent; reject a giant flat gray hanging sheet. Avoid fake rings around masses.
- **Feet:** boots align to measured ground plane in both static and walk; make heel/toe volumes and sole articulation credible. Explicitly resolve prior ~2cm hover before optimizing stride.
- **Materials:** source-derived deep neutral values, selectively restrained gold **panel-edge trim**, source-consistent visor shape/highlight, rough rather than spherical gloss. Do not use simple outlines as a substitute for credible geometry or silhouette; add an optional **separate** controlled render/material lookdev branch after geometry.
- **Camera & lighting:** keep eight exact facing sectors, camera orthographic/canonical fixed registration and root, transparent RGBA, no east/west flips, no per-direction shrink/recenter, stable exposure and directional lighting. Native 128px readability is decisive. Optional 4x source render/downsizing must preserve the physical target and camera proof.

If exp-006 passes objective integrity and looks directionally more accurate **in an actual side-by-side preview**, create at most **exp-007** as a controlled lookdev/render contrast from exp-006, **not** a complete redesign: tuned material response, fabric fold/readability and optional cel/outline post-process. If it becomes geometrically worse, stop without exp-007.

## 3. Walk audit: geometric solver pass != contact pass

Run a 15-frame NE loop **only after** the exp-006 static geometry is reviewable, reusing the real saved rig where possible. Do not imply IK reach error = 0 means planted support is free of skating. Output for left and right separately:
- Detect stance from explicit contact timing/sole height, and **exclude foot lift and transition windows**; report foot 3D world position, ground-plane displacement and speed for each genuine planted sample.
- Report left/right contact-to-contact cycle, support handoffs, opposing swing, toe/heel roll, clearance and knee pole stability; show any foot mesh hover/penetration along with root/pelvis motion and forward velocity. Include uncertainty if clip is in-place rather than moving in world.
- Test contiguous F15->F01 seam, repeated loop cycles, near/far occlusion and cloth/foot silhouette. Preserve Knight NE donor as motion reference only. Do not retarget sparse 2D pixel cutouts.
- Compare 128px playback with the accepted idle for identity and scale; preview speed configurable and labeled NOT AUTHORED FPS.

Stop after one serious geometry attempt and at most one lookdev alternative. No auto-iteration until metric passes; subjective recognizability is a human gate.

## 4. Deliverables and human review

Make **one small visual-review package** comparing **exp-005 vs exp-006** and optional exp-007 against each canonical direction at native 128px. Include a separately viewable high-res geometry/material turntable or sheet if it helps, and a real NE 15-frame animated GIF/MP4 with clear stepping and feet visible. Include objective metrics per direction, not mean IoU alone: aligned masks, overlays/differences, height/root, facing, foot plane, silhouette, motion support, render hashes and failures. Ensure LFS references resolve to actual bytes.

Publish via the project's existing `publish_review_artifacts.py` workflow to **`/CUSTODIAN/visual_review/operator-3d-master/`** if compatible, with verified manifest/links/hashes, preserving local immutable evidence; don't claim upload if it fails. Present a succinct **findings-first** decision request to the user: “Does exp-006 (or exp-007) preserve the canonical Operator's identity from all eight directions and look anatomically credible? Is the NE walk believable?” **Do not independently decide the user’s answer.** If bad, stop and identify exact remaining blockers rather than iterate indefinitely.

Freeze and receipt/hash any new exp before reporting it as complete. Do not mutate any frozen exp-001..005. Leave all original assets and journals. No `best_candidate.json` until user explicitly accepts one. CI/validation scoped to changed files. After push, leave the named art worktree intact and switch shell back to `~/Projects/CUSTODIAN` on clean main as requested; do not modify or reset main.

## 5. Success/failure threshold

Success for this continuation = official MCP configured **and actually tested** (or documented guarded fallback), exp-006 built/saved/reopened & rendered in **real Blender**, visual comparisons and explicit foot-skating evidence produced, proof frozen and inspectable in Dropbox, and human review requested. **Not** proof of final artistic approval.

Fail early if a stable volumetric hood + undercloth + tunic cannot be made recognizably reference-faithful at 128px after the two bounded experiments. In that case report that the primitive-builder route has reached its limit and propose a controlled mesh-sculpt/reference reconstruction alternative, preserving exp-005 and exp-006 evidence. Never call a mechanistic PASS an art PASS.
