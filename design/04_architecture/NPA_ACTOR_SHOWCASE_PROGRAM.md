# NPA Actor Showcase Program

**Status:** program planning and 10 draft implementation/review pairs published; no packet promoted, claimed or implemented by this publication.
**Program identity:** `npa-actor-showcase`
**Reviewed main:** `6a5a60ddbf044d5838c8a5bb1cc504993e3f4690`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Objective
Produce a complete, playable NPA proving ground modeled after the existing Lords of Pain registered authored-level test gallery. Five actual actor types: new **Broken Warrant** (reuses Grunt/Enemy authorities, without double-counting the donor Grunt), new **Escort Frame M-7** (reuses AlliedInfantryDroid/CombatDrone), existing **Marine**, **Savage**, and **Common Vaultwing**. Every actor must be instantiated and driven through real gameplay systems, not staged as inert displays. The end product has read-only developer overlays, deterministic scenario reset, world ingress/return, final original art for both new actors and independent review.

## Investigated current runtime
- NPA-6 implementation/review at `4fda2ffa` / `a9b4e0b9` with zero findings, 42/42 post-sync checks. EnemyLifecycle is the single health/death/corpse/payload owner; CorpseLoot awards once.
- Grunt, Marine and Savage already use standard melee, reaction, parry critical and focused MarineDash/SavagePounce/SavageChain authorities. New Warrant extends their mechanics, not a universal NPC base.
- DroneManager owns commands and squad; DroneTargeting consumes ActorRelationshipResolver; AlliedInfantryDroid inherits CombatDrone. Explicit passive `drone_command_target` must remain available while automatic passive targeting is invalid. NPA-7 pair is *absent* from main and cannot be assumed landed.
- Common Vaultwing's live wild/bonded allegiance and targeting exist. `review-vaultwing-runtime-hardening` is a live dependency; do not smuggle NPA-8 commanded-bonded creature policy into this showcase.
- Lords of Pain gallery is a scoped dev level with registry/scene/wrapper, one Operator only in wrapper, WorldIngressSite + InteractableLevelExit2D return, and focused validation. Its third-party art assets are not the new actors' art.
- Asset Pipeline V2 has registered `enemy` kind but no `allied_actor` kind as of this audit; new actor art is absent. Art status `SOURCE_PENDING` is not `RUNTIME_VERIFIED`. Existing direct drone smoke scripts are not all registered manifest test IDs.
- Docs drift: NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md and CURRENT_STATE.md still describe NPA-6 paired review as pending. Update those against a9b4e0b9 in the first safe execution pass.

## Dependency-aware ten-slice roadmap
| Slice | Implementation + required paired review | Declared implementation dependency | Refresh/promotion barrier |
| --- | --- | --- | --- |
| 1 | `npa-showcase-arena-foundation` + `review-npa-showcase-arena-foundation` | `none` | repo-local authoring validation |
| 2 | `npa-showcase-existing-enemy-hardening` + `review-npa-showcase-existing-enemy-hardening` | `none` | repo-local authoring validation |
| 3 | `npa-showcase-existing-drone-hardening` + `review-npa-showcase-existing-drone-hardening` | `none` | Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here. |
| 4 | `npa-showcase-existing-vaultwing-proof` + `review-npa-showcase-existing-vaultwing-proof` | `review-vaultwing-runtime-hardening` | Refresh actual runtime APIs AFTER review-vaultwing-runtime-hardening archives complete. Its review is currently a ready/auto predecessor. |
| 5 | `npa-showcase-broken-warrant-actor` + `review-npa-showcase-broken-warrant-actor` | `npa-showcase-existing-enemy-hardening` | repo-local authoring validation |
| 6 | `npa-showcase-escort-frame-m7-actor` + `review-npa-showcase-escort-frame-m7-actor` | `npa-showcase-existing-drone-hardening` | Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here. |
| 7 | `npa-showcase-dev-overlays` + `review-npa-showcase-dev-overlays` | `npa-showcase-arena-foundation` | repo-local authoring validation |
| 8 | `npa-showcase-actor-art-intake` + `review-npa-showcase-actor-art-intake` | `npa-showcase-broken-warrant-actor, npa-showcase-escort-frame-m7-actor` | Refresh from landed two actor presentation consumers AND actual human-reviewed original art source; source creation is a real outside input and not available at authoring. |
| 9 | `npa-showcase-artwork-completion-audit` + `review-npa-showcase-artwork-completion-audit` | `npa-showcase-actor-art-intake` | Refresh from landed two actor presentation consumers AND actual human-reviewed original art source; source creation is a real outside input and not available at authoring. |
| 10 | `npa-showcase-complete-arena` + `review-npa-showcase-complete-arena` | `npa-showcase-arena-foundation, npa-showcase-existing-enemy-hardening, npa-showcase-existing-drone-hardening, npa-showcase-existing-vaultwing-proof, npa-showcase-broken-warrant-actor, npa-showcase-escort-frame-m7-actor, npa-showcase-dev-overlays, npa-showcase-artwork-completion-audit` | Refresh after every predecessor has passed independent review, especially NPA-7, Vaultwing and real Asset V2 completion. Do not close on stand-ins. |

**Execution principle:** each paired fresh-context review must be archived *complete/passed* before any dependent implementation claims. During targeted authoring validation, update `Depends on` with the exact paired-review workstream where required by the dispatcher. Do not guess uncreated NPA-7 IDs. All pairs are draft/manual from this remote-only authoring pass and are not claimable until repo-local validation + safe promotion/managed-index publication.

## Three progress gates
1. **Playability:** arena foundation + real Operator wrapper + test zone access, before original art.
2. **Real actor mechanics:** existing actor hardening, Warrant, M-7, live overlay and real command/relationship proof, following NPA-7/Vaultwing review gates.
3. **Full art + closure:** two Asset V2 original families, objective + human art gate, all five live actors in gallery, deterministic end-to-end smoke and independent final review.

## Asset V2 design contract, source and target paths
New family `npa_broken_warrant`, existing supported Asset V2 `enemy` kind. New family `npa_escort_frame_m7`, use newly registered/validated `allied_actor` kind only after schema/back-end check. Contracts at `custodian/content/metadata/assets/families/<family>.asset.json`.
Source-work masters: `custodian/asset_drop/source_work/actors/<family>/<state>_source.png`. Normalized true-alpha horizontal strips: `custodian/asset_drop/inbox/<family>/<state>.png`. Asset Pipeline V2 produces canonical runtime filenames and ingestion receipts. No artwork is generated or approved by these packets.

| Family | Required proposed E/W states | Frames per direction | 96px strip width | FPS |
| --- | --- | --- | --- | --- |
| Broken Warrant | idle, run, melee, flinch, stagger, death | 5, 6, 9, 5, 8, 5 | 480, 576, 864, 480, 768, 480 | 8, 10, 12, 10, 9, 8 |
| Escort Frame M-7 | idle, run, fire, hit, destroyed | 5, 6, 4, 3, 5 | 480, 576, 384, 288, 480 | 5, 5, 12, 12, 8 |

All above are 96×96 cells, 1 horizontal row per E/W strip, two directions. If Warrant requires unique parry-execution victim canvas, add E/W 12f × 156px = 1872×156; Falcon-reversal victim E/W 8f × 156px = 1248×156 **only if enabled by the landed actor**. Do not accidentally inherit Grunt Falcon Punch. Actual required presentation names/counts/FPS must be refreshed against the landed real actor and animation consumer before acceptance. True alpha, ground registration, bounded per-cell edges, no stretching; authored W/mirroring must be explicit. If real sources are missing, art packet stops and records exact inputs.

## Final arena acceptance
Five distinct *real* actor instances at their own labeled live pads, not screenshots: Warrant (melee/parry/one death & corpse award), Marine (Dash), Savage (Pounce/Chain), Vaultwing (wild HIGH untargetable vs attackable then same-instance allied), M-7 (follow/hold/guard/recall, explicit Shrumb, no target after hostility changes and no queued hostile shots). Read-only overlay projects real per-instance state, dev-only reset and input routing preserve Operator and DroneManager ownership, no broad campaign spawn change. World registry and re-entry use current loader; Asset V2 must report required new artwork imported, bound and runtime verified, followed by final focused + changed-file checks and fresh review.

## Promotion protocol / why drafts are on main
Publishing task text from an isolated GitHub-only environment is **not** equivalent to running `python3 custodian/tools/agent/validate_task_packet_authoring.py` or Godot. For each pair: fetch latest main, check AGENTS and dispatcher audit, verify live dependencies/locks, run the targeted authoring validator in a real repo checkout, promote mechanically unlocked pairs to `ready/auto` together and revalidate, regenerate and verify `task_packet_index.py`, land through normal safe workstream lifecycle, then verify the dispatcher audit. Keep NPA-7/Vaultwing/art/final consumer pairs draft/manual until explicit refresh is done; this publication does not require a new invented predecessor workstream.

**Next action:** have a repository-side Codex promotion run for the arena foundation, existing enemy hardening and diagnostic packet pairs, while retaining the external NPA-7/art refresh gates. Exact authoring backlink for every implementation and review summary: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
