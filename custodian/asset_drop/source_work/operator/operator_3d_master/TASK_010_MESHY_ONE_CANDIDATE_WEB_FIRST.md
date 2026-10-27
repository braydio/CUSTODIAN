# TASK 010: One Meshy image-to-3D candidate, web-first, NO automatic spend

**Read this once, execute mechanically, stop at any required user action.** The user has approved testing ONE external image-to-3D alternative for the CUSTODIAN Operator. This is **not** art approval, a change to canonical design, or permission to spend money. No extra model generations, no autonomous purchases or subscriptions, no external asset publishing.

## Source & asset delivery (prepared by ChatGPT, not yet in local CUSTODIAN)

User downloads **CUSTODIAN_Meshy_Operator_References.zip** from this chat and saves it under `~/Downloads/` (or provides the unzipped folder). SHA256 of zip: `e087c1b5c440e8fd8087fab5bdd40f3989d9dceb9939173352be7c91c15a732f`. If not found, ask **once** for the ZIP/location and stop. Do not search the entire filesystem, assume ChatGPT sandbox paths exist on Arch, or attempt to create replacement AI art.

When available, verify ZIP hash, unpack in a disposable, untracked **art worktree** staging dir. Read `MANIFEST.json` and `README.txt`. Main files already cropped to equal 1024×1024 canvases:
- `01_front.png` eye-level front.
- `02_three_quarter_front.png` eye-level near front, **single-image default**.
- `03_left_side.png` eye-level side.
- `05_back.png` eye-level back.
- `04_three_quarter_back.png` optional, only if clearly consistent.
- `00_realistic_concept_board.png` visual-style guide and detail views, **NOT** Meshy input.
- `99_user_provided_8dir_sprite_reference.png` real user-supplied 8-direction reference. For canonical identity/registration use locked source in repo at `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png` (SHA256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`). The tiny “original 8-direction” row in the generated concept board is **NOT CANONICAL**; never use it as such.
- AI-generated turnaround views may be *inconsistent* in anatomy or side details. Verify basics visually; do not invent matching unseen geometry.

## Identity constraints

Capeless Operator: dark graphite/black articulated armor, thin muted gold edging (not glowing thick outline everywhere), compact layered angular pauldrons, broad **rounded hood with subtle forward brow peak** and clearly modeled underlying head/neck, dark completely enclosed mask/neck and narrow amber visor; separate belt-attached pointed tabard/tunic panels with gold-bound edges, believable leg lengths and armored grounded boots. **NO cape, mantle, superhero drape, exposed skin, floating gold hood ring, wizard cone hood, or medieval floor-length skirt.** The realistic illustration is a *candidate anatomical/material guide*; don't bake elevated 2.5D perspective into body shape.

## Provider check and user decision gate (ONE small check only)

**Preferred: user's Meshy website (no API required).** Current official docs: https://docs.meshy.ai/en/webapp/image-to-3d , https://help.meshy.ai/en/articles/15696428-what-is-included-on-the-free-plan , https://help.meshy.ai/en/articles/10421033-why-can-t-i-download-my-model .

- **Free:** 100 credits/month, web app only. A Free user can download up to 10 **UN-TEXTURED Meshy 6 Lite** outputs per month; textured models or Meshy 6/7 downloads are paywalled, and API access is not included. Multi-view and pose options may have limited previews / paid restrictions. **Do not tell the user that generating on the website guarantees a free downloadable GLB.**
- Paid multi-view option (if the user already has it): Image to 3D → Meshy 7.1 Multi-view → main `01_front.png` plus `03_left_side.png`, `05_back.png` (optional `02_three_quarter_front.png` if consistent). Import one unified model, NOT batch image-to-model (which generates separate models).
- Free-download option: Image to 3D → Meshy 6 Lite (not flagship), single `02_three_quarter_front.png` input, **untextured**, settings shown by actual site. This is a *geometry viability probe*, not final textured model.
- If website exposes different controls or costs, follow visible UI and never claim nonexistent options. Inspect price and download rights **before** initiating. If the needed GLB is behind paywall, STOP and ask user; don't pay, buy credits or start paid API automatically.
- Optional API/MCP route ONLY if user already has paid developer access AND explicitly approves the quoted **credit cost of one generation**. Official https://docs.meshy.ai/en/api/ai . Do not install Meshy MCP or request a secret for the website route. If API approved, store secret only in existing secure local env/secret manager; never commit, print or transmit key into GitHub/chat. Submit exactly one creation. Never retry a nonfailed result or chain texture/smart rig jobs unless separately approved.
- **Interaction boundary:** Claude Code may not have user-authenticated web access. If so, prepare reference folder and send user the exact web steps, asking them to generate and provide **one** downloadable GLB + texture maps if available. Stop rather than pretending generation occurred.

## Quick manual web handoff (give to user verbatim as appropriate)

1. Go to https://www.meshy.ai/ and sign in → **Model → Image to 3D**.
2. On Free, select **Meshy 6 Lite**, upload `02_three_quarter_front.png`, use **one** generation and no-texture if that is required for download. Check credits displayed **before** Generate.
3. If already paid with Multi-view, use `01_front.png` plus `03_left_side.png`, `05_back.png` in Multi-view, ensure one fused model, confirm generation credit cost and export entitlements.
4. Inspect resulting model for full backside, hood, panel topology, boots and no cape; download **GLB** (and textures if available); provide file path to Claude. If paywall, report exact model mode and cost and stop.

## Import and prove (ONLY after a real GLB has arrived; no artificial success receipts)

Use **existing** `agent/operator-3d-master-modeling-proof-v1` art worktree. Do NOT touch `~/Projects/CUSTODIAN` root main, runtime art, select-best, or frozen `exp-001..008` SHA receipts. Preserve its existing review branch history and safely fast-forward clean local branch only.

Keep this one candidate in a separate experimental namespace `external_candidates/meshy-001/` (do not call `experiments.py new` or `scripts/run_blender.py`, which require 60+ procedural named parts and preview IK). Include source ZIP SHA, input view SHA, Meshy task/model identifier, plan/mode if known, whether download was textured, licensing/attribution and user generation timestamp. No generated licensing claims beyond displayed plan terms.

Run a safe headless Blender import on a **disposable** scene in a restricted, unprivileged workflow. Read scene object meshes/materials; check nonempty triangle geometry, normals, dimensions, disconnected objects, outward silhouette, backside, hollow cloak lookalikes and texture UV availability. Do not execute untrusted embedded scripts or asset code. Preserve the raw imported GLB unchanged with SHA256. Copy/import a working variant in new path; orient front to -Y, Z up, feet at world Z=0, translate root, **uniform scale only** to same 3D reference height for comparisons (~2.075m if the imported model has credible feet/hood extents); record transformation rather than mutating original.

Render real front, side, back eye-level checks and eight neutrals (`N NE E SE S SW W NW`) at **working 45° above horizontal, common 50 px/m** (`ortho_scale=128/50`), 128×128 RGBA projected root (64,106), ground row 107, consistent lighting. If external mesh cannot hold 84–88px apparent height at fixed matching world dimensions, report deviation instead of direction-by-direction zoom hacks. Produce `look512` crop(s) and one **side-by-side** sheet with canonical locked 8 directions, **exp-008** (if available) / latest procedural model at identical 45°/50px, and Meshy candidate. Distinguish untextured GLB from textured GLB: no unfair material scoring when untextured. Include measures for shoulder span/height and hood/neck proportions. Art judgment is human; IoU is triage, not acceptance.

**Do NOT auto-rig, animate or retopologize** until user approves shape; one solid mesh from AI won't have procedural rig_groups and does not imply a usable 15F walk. Do not set best_candidate, do not update gameplay, never merge to main.

Produce a small `MESHY_TRIAL_RECEIPT.json` listing provenance, mode, billable credits as user-reported (not guessed), original and normalized file hashes, Blender import success, object counts, and PNG proof paths. Publish small actual proof (if generated) via existing Dropbox visual review pipeline, safely commit and push only required source-work to art branch. **STOP** for human review. Final Claude answer <=180 words, links first.

## Absolute spend/token budget

**One** Meshy generation max. No account setup or API subscription without user action. No re-analysis of old image generation iterations, no broad codebase audit, no new modeling experiments, no duplicate Blender MCP configuration, no speculative research loop. If no GLB, do ONLY prepared input handoff and STOP; do not waste tokens on downstream import code.
