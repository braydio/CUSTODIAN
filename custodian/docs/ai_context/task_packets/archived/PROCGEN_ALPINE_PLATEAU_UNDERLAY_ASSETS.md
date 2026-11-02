# PROCGEN ALPINE PLATEAU UNDERLAY ASSETS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-plateau-underlay-assets`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-region-frame-presentation-foundation`
- Locks: `procgen-presentation, asset-pipeline`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `human-owned final composition approval remains required after objective Asset V2/runtime checks`
- Reviewed main: `1ef9201f31f108afdfed5065ee736bc101008c23`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Prior authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Goal: Continue the already-proven Alpine Region Frame underlay foundation with an omnidirectional aerial-oblique FAR/MIDDLE/NEAR art set that remains believable around every exterior edge of the normal top-down gameplay camera, while preserving the existing six-state Asset V2 identity, deterministic profile binding, exterior-only presentation semantics, Archive Resolve separation, and Moment Forge review path.
- Completion boundary: Done when the exact Gate A implementation handoff from `ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md` is verified; the existing `procgen_underlay_alpine_plateau` family publishes all six revised 1536×1024 states through Asset Pipeline V2; `alpine_plateau_underlay.tres` consumes them with deterministic A/B selection; optional per-layer parallax/overscan is data-driven and bounded; north/east/south/west exterior approaches show no fixed side-scroller horizon or exposed canvas; non-Alpine underlay behavior remains compatible; and compact gameplay-scale evidence receives human visual approval.
- Current measured state: RF1/RFR1 are complete/passed and remain stable Region Frame authority. The currently active `agent/procgen-alpine-plateau-underlay-assets` branch contains two useful implementation commits from the first-pass art integration: the six-state Asset V2 family, first-pass runtime textures, `alpine_plateau_underlay.tres`, Region Frame binding, proof hardening, and an Alpine Moment Forge review scenario. That branch is now behind live main and predates this continuation design; preserve it as implementation/donor evidence rather than landing it wholesale. The first-pass visual audit validated atmospheric scale and the FAR/MIDDLE/NEAR concept but identified a composition constraint: the current source art carries a strong bottom-screen scenic horizon and is not suitable as an unrestricted omnidirectional top-down underlay. This is scoped continuation, not a failure disposition. The required immutable Gate A Dropbox handoff is not currently present.
- Evidence: `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; `design/02_features/procgen/ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; `design/02_features/procgen/ELEVATED_WORLD_PRESENTATION.md`; `custodian/game/world/procgen/presentation/procgen_underlay_profile.gd`; `custodian/game/world/procgen/presentation/procgen_depth_backdrop.gd`; `custodian/game/world/procgen/presentation/region_frames/alpine_plateau.tres`; active branch `agent/procgen-alpine-plateau-underlay-assets`; outbound review evidence under `CUSTODIAN/visual_review/procgen-alpine-plateau-underlay-assets/`.
- Task-specific authority: `ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; Asset Pipeline V2 live schema/tooling; `PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; reviewed Region Frame foundation; `IMPLEMENTATION_HANDOFF.md`; `VISUAL_REVIEW_HANDOFF.md`.
- Work surface: Existing family metadata `custodian/content/metadata/assets/families/procgen_underlay_alpine_plateau.asset.json` once refreshed from donor work; source masters under `custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_plateau/`; normalized intake under `custodian/asset_drop/inbox/procgen_underlay_alpine_plateau/`; runtime domain `custodian/content/backgrounds/procgen/alpine_plateau/`; `custodian/game/world/procgen/presentation/{procgen_underlay_profile.gd,procgen_depth_backdrop.gd}`; `presentation/underlays/alpine_plateau_underlay.tres`; `presentation/region_frames/alpine_plateau.tres`; focused validation and Alpine Moment Forge scenario.
- Change: Reuse the existing six semantic states exactly: `far_world_a`, `far_world_b`, `depth_fog_a`, `depth_fog_b`, `near_cliff_mist_a`, `near_cliff_mist_b`. Fetch them only from the immutable Gate A handoff. Preserve fetched raw bytes as untrusted staging until this packet and Asset Pipeline V2 promote them. Reuse the existing family id and runtime domain; do not create an Alpine-underlay-v2 family. Replace/refine source/runtime art only through Asset Pipeline V2. Keep FAR/MIDDLE/NEAR opacity data-driven. If depth needs camera-relative motion, extend `ProcgenUnderlayProfile` with optional per-layer parallax strengths whose default preserves current non-Alpine behavior, and implement bounded layer displacement in `ProcgenDepthBackdrop`. Preserve native-scale camera-following behavior; use sufficient overscan/coverage to make gray/unpainted exposure impossible over supported viewport sizes and camera motion. Update the review scenario to exercise multiple exterior directions rather than validating only a south-facing scenic composition.
- Preserve: Region Frame exterior/internal CHASM semantics; accepted-seed determinism; A/B selection; Drowned Basilica override; Endless Forest compatibility behavior; M3-M6 streaming; Archive Resolve; local biome field; collision/navigation; `RuntimeWalkableBoundary`; gameplay camera authority; pixel/gameplay readability.
- Non-goals: No cliff-fascia art change; no large playable-surface plates; no environment/weather tuning; no dynamic camera pitch/rotation; no 3D conversion; no generation/topology change; no new local biome; no new gameplay surface authority.
- Acceptance: (1) exact Gate A `HANDOFF_MANIFEST.json` verifies workstream/id, authoring chat, six expected payload paths, hashes, sizes and dimensions; (2) all six revised states are 1536×1024 RGBA one-frame assets and Asset V2 status/doctor are green; (3) `alpine_plateau_underlay.tres` uses the revised family with deterministic fixed-seed A/B selection; (4) Alpine frame reports the intended underlay and no compatibility fallback once the asset family is valid; (5) internal ravines do not activate the permanent underlay; (6) north/east/south/west exterior review positions reveal no conventional fixed horizon; (7) supported viewport/camera motion cannot expose gray/unpainted canvas; (8) FAR reads as subdued non-navigable lower world, MIDDLE hides cliff termination, NEAR bridges cliff-root depth; (9) non-Alpine underlay profiles retain prior behavior; (10) no Archive Resolve state/material is used by this family; (11) objective checks are green before visual review; (12) one compact Dropbox review bundle receives explicit human approval.
- Validation: Fetch Gate A only with `custodian/tools/iteration/implementation_handoff.py` and validate the immutable manifest before repository mutation. Run current Asset V2 family plan/status/doctor commands using live `asset.py --help`; run `procgen_region_frame`, `elevated_world_asset_contract`, nonwalkable-surface coverage, Drowned underlay regression, changed-file validation and `git diff --check`. Add a focused coverage assertion for supported viewport/overscan if existing tests do not prove it. Then run the smallest multi-direction Alpine Moment Forge evidence scenario and publish only the necessary contact sheet/keyframes through `publish_review_artifacts.py --important`. Ask whether the underlay works from all exterior directions, the far world remains subordinate/non-navigable, fog hides the depth terminus, and no canvas boundary is perceptible.
- Task overrides: `none`
- Deferred: Alpine frame-specific cliff/fascia/contact art is `procgen-alpine-cliff-presentation-v1`; large Rocky Upland/Meridian plates are `procgen-alpine-surface-plates-v1`; final weather/lighting/wind tuning is `procgen-alpine-environment-cohesion-v1`; directional cinematic/vista camera framing is a separate future design.

## Required External Input — Gate A

The only valid input is:

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-plateau-underlay-assets/
    alpine-underlay-final-six-v3/
      HANDOFF_MANIFEST.json
      payload/
        procgen_underlay_alpine_plateau/
          far_world_a.png
          far_world_b.png
          depth_fog_a.png
          depth_fog_b.png
          near_cliff_mist_a.png
          near_cliff_mist_b.png
```

The manifest must use schema `custodian.implementation_handoff.v1` and record this exact authoring chat URL. The payload set must be exact: six PNGs, no substitutions.

This packet remains `blocked` until that exact committed handoff exists and verifies. The earlier `/CUSTODIAN/visual_review/` artifacts and any local `~/Downloads` bundle are review/provenance evidence only and cannot satisfy this implementation gate.

## Gate A Provenance Note (user-directed, final)

The earlier `alpine-underlay-omnidirectional-v2` upload and the `generated_asset_batches` first-10 ZIP are **superseded donor/provenance**. After a 30-candidate exploration (`alpine_underlay_last3_generations_review_bundle.zip`), seven curated combinations, and eight A/B permutations of the final six rendered through the Alpine edge Moment Forge scenario, the user approved this exact six-plate set as the canonical AP1 baseline:

| State | Donor plate (generation / file) |
| --- | --- |
| `far_world_a` | gen2 `alpine_ruins_among_fog_islands.png` |
| `far_world_b` | gen3 `snowy_custodian_ruins_above_the_clouds.png` |
| `depth_fog_a` | gen3 `misty_alpine_ruins_overlay.png` |
| `depth_fog_b` | gen2 `translucent_alpine_ruins_cloudscape.png` |
| `near_cliff_mist_a` | gen3 `floating_alpine_cliffs_in_mist.png` |
| `near_cliff_mist_b` | gen2 `misty_ruined_alpine_plateau_cutout.png` |

These were published as the immutable handoff `CUSTODIAN/implementation_inputs/procgen-alpine-plateau-underlay-assets/alpine-underlay-final-six-v3/` (schema `custodian.implementation_handoff.v1`, this packet's authoring chat, SHA-256 + donor mapping per payload) and verified with `implementation_handoff.py fetch` before ingest. The runtime PNGs are byte-identical to the approved donor plates. The remaining 24 permissible donor plates (18 ordinary alternates, 6 scenic landmarks) are not wired here; they stay in the donor ZIP with original bytes for `procgen-alpine-underlay-variety-v1`. The four cliff-fascia tiles from the earlier first-10 ZIP belong to `procgen-alpine-cliff-presentation-v1` and were not consumed.

## Existing Branch Disposition

`agent/procgen-alpine-plateau-underlay-assets` is preserved as donor/reference evidence. When Gate A becomes available, resume from current main and selectively reuse/rebase proven implementation pieces rather than merging the stale branch wholesale. Re-derive any touched public API against live main first.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: Gate A is the immutable `alpine-underlay-final-six-v3` handoff (schema `custodian.implementation_handoff.v1`, authoring chat `6ac3be53…`, six payloads with SHA-256 + donor mapping), verified with `implementation_handoff.py fetch` before any repository mutation; runtime PNGs are byte-identical to the approved donor plates (`cmp`). All six states in `procgen_underlay_alpine_plateau` are 1536x1024 RGBA one-frame, `asset doctor` healthy and `asset status` 6/6 ready after `ingest --replace --godot-import`. `alpine_plateau_underlay.tres` selects A/B per layer by accepted seed, adds optional per-layer parallax (0.04/0.08/0.12, bounded 64 px), `guarantee_viewport_coverage` and an atmospheric `base_fill_color` (0.42,0.47,0.54); non-Alpine profiles keep zero defaults. `procgen_region_frame_smoke` proves: Alpine frame resolves with no fallback, internal chasm does not activate the underlay, deterministic A/B over a 24-seed sweep, viewport/zoom coverage sweep (4 viewports x 6 zooms), bounded deterministic parallax, non-Alpine defaults unchanged, RFR1 R0-01 (real generated production scene reports `alpine_plateau` + Alpine underlay) and R0-02 (ocean pocket / exterior-interior partition fixture). Also green: `procgen_macro_presentation`, `procgen_meridian_hardstand_macro`, `elevated_world_asset_contract`, `procgen_nonwalkable_surface`, `asset_pipeline_v2`, `awakening_underlays_zones_01_05`, Drowned underlay smoke, `git diff --check`. Renderer evidence: four-direction (N/E/S/W) Moment Forge captures for seven curated combinations and all eight A/B permutations of the final six, plus the production profile (Dropbox `/CUSTODIAN/visual_review/procgen-alpine-plateau-underlay-assets/20261006T072124Z/REVIEW_MANIFEST.json`; combos under `/CUSTODIAN/visual_review/procgen-alpine-plateau-underlay-combos/`). Human decision: the user explicitly approved the six Gate A plates as the canonical baseline (chat, 2026-10-06). Archive Resolve is not touched; the 24 other donor plates are intentionally not wired (reserved for `procgen-alpine-underlay-variety-v1`).

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: Stale initial claim blocked the lock; the first-pass art was superseded twice (omnidirectional pack, then a 30-candidate exploration); the first Gate A manifest recorded a different authoring chat than the packet; the sparse cutout art exposed engine-default gray through transparent gaps and the initial camera lookup lagged 0.5 s; `review_pairing_contract` fails on main for an unrelated Operator-workbench packet.
- Root cause / contributing factors: Dropbox handoffs were prepared before the packet's authoring chat settled; the backdrop assumed opaque-ish plates and a fixed 1.08 overscan; branch hygiene was run with a line-wrapped note.
- Prevention / pipeline improvement: Verify manifest authoring-chat/id against the packet before claim; keep review-only candidate wiring (`ALPINE_REVIEW_*` fixture env, `.gdignore` staging) for future art swaps; coverage/parallax/base-fill are now data in the underlay profile.
- Tooling / docs drift discovered: `review_pairing_contract` red on `origin/main` (`review-operator-workbench-publish-readiness-recovery-review-corrections-1-review-corrections-2` malformed bounded TASK OVERRIDE) skips later changed-file tiers; the packet's "implementation_inputs only" Gate A wording had to be reconciled with a user-directed ZIP source.
- Follow-up: `procgen-alpine-cliff-presentation-v1`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh instruction: No design refresh is required if Gate A exactly matches the manifest. Once the handoff exists, verify its immutable identity/payload, re-check live main and donor-branch drift, then change only the claim gate to `ready` if the implementation contract remains valid. Escalate to this chat only if live APIs or the supplied art materially change the projection/authority decision.

## Handoff

- Next workstream: `procgen-alpine-cliff-presentation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none`
- Next action: AP1 is complete. Verify Gate B and allow the Alpine cliff packet to become claimable; `procgen-alpine-underlay-variety-v1` stays post-AP4 and consumes the preserved 24 donor plates.
- Blockers or open questions: none for AP1. Gate B (26 cliff-fascia PNGs) is owned by the cliff packet.