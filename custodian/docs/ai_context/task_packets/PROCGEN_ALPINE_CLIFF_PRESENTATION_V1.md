# PROCGEN ALPINE CLIFF PRESENTATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-cliff-presentation-v1`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-alpine-plateau-underlay-assets`
- Locks: `procgen-presentation, asset-pipeline`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `asset-pipeline, code, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `frame-specific edge art and final gameplay-scale composition require human visual approval after objective technical checks`
- Reviewed main: `1ef9201f31f108afdfed5065ee736bc101008c23`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Goal: Make the permanent Alpine exterior frontier read as a large geological escarpment physically attached to the playable plateau rather than a repeated generic 32 px fascia strip, while retaining exterior CHASM, Region Frame selection and `ProcgenVoidCliffFace` as presentation/semantic authorities.
- Completion boundary: Done when the exact Gate B handoff is verified; the 12-state `procgen_alpine_cliff_fascia` family, 10-state `procgen_alpine_cliff_contact` family and four new `procgen_depth_chunks` states are published through Asset Pipeline V2; Alpine Region Frame data selects the frame-specific fascia vocabulary while the generic six-state `void_cliff_face` remains fallback; large contact compositions derive from the same exterior frontier/outward-direction evidence; directional visual depth is coherent; cliff bottoms disappear into the permanent fog stack; collision/navigation/topology remain unchanged; and compact fixed-seed multi-direction edge evidence receives human approval.
- Current measured state: Generic `void_cliff_face` is a six-state 32×32 Asset V2 family consumed by `procgen_world_tileset.tres` and `ProcgenVoidCliffFace`. The presenter currently hard-codes source IDs 149–154 for `top`, three body roles and two bottom roles, already derives outward direction, supports wall-backed frontiers, deterministic clustered role/depth variation, and paints only presentation TileMap cells. This is the correct owner to extend rather than replace. The visual audit found that six repeated generic roles cannot carry the Alpine geographic scale by themselves. Existing Macro Presentation and `procgen_depth_chunks` already provide the correct BACK-band system for larger CHASM compositions. The exact Gate B implementation handoff is not currently present.
- Evidence: `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; `PROCGEN_REGION_FRAME_PROFILES.md`; `ELEVATED_WORLD_PRESENTATION.md`; `PROCGEN_DEPTH_CHUNKS.md`; `custodian/content/metadata/assets/families/void_cliff_face.asset.json`; `custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd`; `procgen_region_frame_profile.gd`; `terrain_stamp_profile.gd`; `procgen_macro_presentation_composer.gd`; `terrain_stamp_catalog_v1.tres`; existing void-cliff and macro smokes.
- Task-specific authority: Alpine presentation manifest; Region Frame profile; generic `ProcgenVoidCliffFace`; Asset Pipeline V2; Macro Presentation; `IMPLEMENTATION_HANDOFF.md`; `VISUAL_REVIEW_HANDOFF.md`.
- Work surface: `custodian/game/world/procgen/presentation/{procgen_void_cliff_face.gd,procgen_region_frame_profile.gd}`; `presentation/region_frames/alpine_plateau.tres`; `custodian/content/tiles/tilesets/procgen_world_tileset.tres`; new family metadata for Alpine fascia/contact; existing `procgen_depth_chunks.asset.json`; new/updated `TerrainStampProfile` resources; `terrain_stamp_catalog_v1.tres`; focused validation.
- Change: Add a small data-driven cliff-fascia profile seam rather than a second Alpine hard-coded source table. `ProcgenRegionFrameProfile` may optionally select a fascia profile; `ALPINE_PLATEAU` selects the Alpine profile; a missing frame-specific profile preserves the current generic `void_cliff_face` behavior. The Alpine profile supplies deterministic weighted crown/body/bottom variant pools and presentation-only outward-direction depth bias. South may present the deepest visible face, east/west intermediate, north shallowest; exact depths belong in data and must stay within existing presentation bounds. Extend `procgen_world_tileset.tres` with the 12 Alpine fascia sources without renumbering/removing existing stable sources. Add deterministic large cliff-contact placement tied to the same exterior frontier and outward direction; a focused helper is acceptable but must not create competing exterior-edge semantics. Contact plates must qualify on suitable frontier length/space, avoid incompatible wall/claim overlap, own no collision/navigation, and obey streaming visibility. Extend `procgen_depth_chunks` with the four manifest states, matching `TerrainStampProfile` resources and catalog entries; keep them BACK-band CHASM only.
- Preserve: CHASM/OCEAN/floor classification; exterior/internal CHASM distinction; wall-aware fascia behavior; `RuntimeWalkableBoundary`; generated wall authority; collision/navigation; terrain semantics; Archive Resolve; generic void-fascia fallback; streaming determinism; accepted-seed determinism; current non-Alpine frames.
- Non-goals: No local-biome rewrite; no playable plateau-floor macro vocabulary; no weather/lighting tuning; no camera changes; no cliff gameplay physics; no traversal/elevation change; no replacement of `ProcgenVoidCliffFace` with a parallel renderer.
- Acceptance: (1) exact Gate B handoff verifies 26 PNG payloads, hashes, sizes, dimensions and this authoring chat; (2) 12 Alpine fascia, 10 contact, and four depth states are Asset V2 verified; (3) Alpine frame selects frame-specific fascia while a neutral/non-Alpine frame retains generic source IDs/behavior; (4) no fascia/contact/depth art paints authoritative floor or OCEAN; (5) wall-backed frontiers remain correct; (6) fixed-seed north/east/south/west cases prove deterministic directional presentation and bounded depth; (7) large contact plates are deterministic, placement-limited and streaming-safe; (8) generic cliff tests and Region Frame tests remain green; (9) lower cliff termination is visually swallowed by permanent fog rather than a hard strip; (10) normal gameplay-scale evidence no longer reads primarily as a repeating purple/generic cliff band; (11) objective checks precede and pass before one compact human visual review handoff.
- Validation: Fetch Gate B with `implementation_handoff.py` and verify exact payload before mutation. Run Asset V2 plan/status/doctor. Run `procgen_void_cliff_face_smoke.gd`, `procgen_void_cliff_wall_integration_smoke.gd`, `procgen_region_frame_smoke.gd`, `procgen_macro_presentation_smoke.gd`, `elevated_world_asset_contract_smoke.gd`, affected streaming/materializer parity, changed-file validation and `git diff --check`. Add focused fascia-profile/contact-placement coverage for fallback behavior, direction cases, deterministic selection and no semantic mutation. Publish the smallest edge-direction evidence bundle and ask whether the upper plane/cliff/contact/fog read as one geographic structure without obscuring gameplay.
- Task overrides: `none`
- Deferred: Large playable Rocky Upland/Meridian surface vocabulary is `procgen-alpine-surface-plates-v1`; final environment tuning is `procgen-alpine-environment-cohesion-v1`; dynamic camera pitch remains separate.

## Required External Input — Gate B

Only this immutable handoff satisfies the art gate:

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-cliff-presentation-v1/
    alpine-cliff-presentation-v1/
      HANDOFF_MANIFEST.json
      payload/
        procgen_alpine_cliff_fascia/     # 12 exact manifest states
        procgen_alpine_cliff_contact/    # 10 exact manifest states
        procgen_depth_chunks/            # 4 exact manifest states
```

Exactly 26 PNGs are required. The manifest must be `custodian.implementation_handoff.v1` and record this exact authoring chat URL. No review artifact, generated placeholder, local Downloads file or alternative family satisfies this gate.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `none | fixed-in-scope | procgen-alpine-surface-plates-v1 | manual-follow-up`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh instruction: No design refresh is required if AP1 lands within contract and Gate B exactly matches the manifest. At claim time, re-derive exact source IDs/profile seams and public helper names from live main. Escalate only if AP1 or live cliff ownership materially changes the authority boundary.

## Handoff

- Next workstream: `procgen-alpine-surface-plates-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: After AP2 completes, verify Gate C and allow the surface-plate packet to become claimable.
- Blockers or open questions: Gate B art is not yet present in the immutable Dropbox implementation-input lane; AP1 must complete first.