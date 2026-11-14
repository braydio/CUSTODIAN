# PROCGEN ALPINE CLIFF PRESENTATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-cliff-presentation-v1`
- Status: `ready`
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
- Reviewed main: `b086e552de00cea8551d62884c996558d33f12e6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Goal: Make the permanent Alpine exterior frontier read as a large geological escarpment physically attached to the playable plateau rather than a repeated generic 32 px fascia strip, while retaining exterior CHASM, Region Frame selection and `ProcgenVoidCliffFace` as presentation/semantic authorities.
- Completion boundary: Done when the approved `alpine-cliff-source-family-v1` source-master batch is fetched and verified; Codex derives and normalizes the exact 12-state `procgen_alpine_cliff_fascia` family, 10-state `procgen_alpine_cliff_contact` family and four new `procgen_depth_chunks` states through Asset Pipeline V2; the resulting exact 26-state Gate B handoff is published/verified as the AP2 closeout receipt; Alpine Region Frame data selects the frame-specific fascia vocabulary while the generic six-state `void_cliff_face` remains fallback; large contact compositions derive from the same exterior frontier/outward-direction evidence; directional visual depth is coherent; cliff bottoms disappear into the permanent fog stack; collision/navigation/topology remain unchanged; and compact fixed-seed multi-direction edge evidence receives human approval.
- Current measured state: Generic `void_cliff_face` is a six-state 32×32 Asset V2 family consumed by `procgen_world_tileset.tres` and `ProcgenVoidCliffFace`. The presenter currently hard-codes source IDs 149–154 for `top`, three body roles and two bottom roles, already derives outward direction, supports wall-backed frontiers, deterministic clustered role/depth variation, and paints only presentation TileMap cells. This is the correct owner to extend rather than replace. The visual audit found that six repeated generic roles cannot carry the Alpine geographic scale by themselves. Existing Macro Presentation and `procgen_depth_chunks` already provide the correct BACK-band system for larger CHASM compositions. AP1 is now complete/landed. The approved AP2 source-master batch is present in Dropbox at `CUSTODIAN/asset_batches/procgen-alpine-presentation/alpine-cliff-source-family-v1/`; its primary ZIP SHA-256 is `e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3`. The final Gate B runtime handoff is intentionally not present yet because AP2 produces it after source derivation and validation.
- Evidence: `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; `PROCGEN_REGION_FRAME_PROFILES.md`; `ELEVATED_WORLD_PRESENTATION.md`; `PROCGEN_DEPTH_CHUNKS.md`; `custodian/content/metadata/assets/families/void_cliff_face.asset.json`; `custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd`; `procgen_region_frame_profile.gd`; `terrain_stamp_profile.gd`; `procgen_macro_presentation_composer.gd`; `terrain_stamp_catalog_v1.tres`; existing void-cliff and macro smokes.
- Task-specific authority: Alpine presentation manifest; `DROPBOX_ASSET_BATCH_REGISTRY.md`; Region Frame profile; generic `ProcgenVoidCliffFace`; Asset Pipeline V2; Macro Presentation; `IMPLEMENTATION_HANDOFF.md`; `VISUAL_REVIEW_HANDOFF.md`.
- Work surface: `custodian/game/world/procgen/presentation/{procgen_void_cliff_face.gd,procgen_region_frame_profile.gd}`; `presentation/region_frames/alpine_plateau.tres`; `custodian/content/tiles/tilesets/procgen_world_tileset.tres`; new family metadata for Alpine fascia/contact; existing `procgen_depth_chunks.asset.json`; new/updated `TerrainStampProfile` resources; `terrain_stamp_catalog_v1.tres`; focused validation.
- Source derivation input: The exact active source-master batch is `CUSTODIAN/asset_batches/procgen-alpine-presentation/alpine-cliff-source-family-v1/`. Read `custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md` first, verify the ZIP checksum, extract only into temporary staging outside the checkout, then read the package `ASSET_MANIFEST.md` / `HANDOFF_MANIFEST.json`. Preserve approved masters into their declared `asset_drop/source_work/procgen/...` destinations before deriving normalized runtime states. Use the project pixel-art resizer/normalizer where reduction is needed; do not smooth-scale, nonuniformly squash, or infer gameplay masks from image alpha. The eight fascia body/bottom masters map directly by semantic role. Derive the four `top_*` states from suitable crown regions of the four approved large contact masters so crown/fascia/contact remain one geological family. Derive/recompose the directional contact and depth-chunk outputs from the same large masters while preserving projection/lighting; do not treat each source master as a final canvas.
- Change: Add a small data-driven cliff-fascia profile seam rather than a second Alpine hard-coded source table. `ProcgenRegionFrameProfile` may optionally select a fascia profile; `ALPINE_PLATEAU` selects the Alpine profile; a missing frame-specific profile preserves the current generic `void_cliff_face` behavior. The Alpine profile supplies deterministic weighted crown/body/bottom variant pools and presentation-only outward-direction depth bias. South may present the deepest visible face, east/west intermediate, north shallowest; exact depths belong in data and must stay within existing presentation bounds. Extend `procgen_world_tileset.tres` with the 12 Alpine fascia sources without renumbering/removing existing stable sources. Add deterministic large cliff-contact placement tied to the same exterior frontier and outward direction; a focused helper is acceptable but must not create competing exterior-edge semantics. Contact plates must qualify on suitable frontier length/space, avoid incompatible wall/claim overlap, own no collision/navigation, and obey streaming visibility. Extend `procgen_depth_chunks` with the four manifest states, matching `TerrainStampProfile` resources and catalog entries; keep them BACK-band CHASM only.
- Preserve: CHASM/OCEAN/floor classification; exterior/internal CHASM distinction; wall-aware fascia behavior; `RuntimeWalkableBoundary`; generated wall authority; collision/navigation; terrain semantics; Archive Resolve; generic void-fascia fallback; streaming determinism; accepted-seed determinism; current non-Alpine frames.
- Non-goals: No local-biome rewrite; no playable plateau-floor macro vocabulary; no weather/lighting tuning; no camera changes; no cliff gameplay physics; no traversal/elevation change; no replacement of `ProcgenVoidCliffFace` with a parallel renderer.
- Acceptance: (1) active source-master batch identity and ZIP SHA-256 verify before mutation; (2) exact closeout Gate B handoff verifies 26 final PNG payloads, hashes, sizes, dimensions and this authoring chat; (3) 12 Alpine fascia, 10 contact, and four depth states are Asset V2 verified; (4) Alpine frame selects frame-specific fascia while a neutral/non-Alpine frame retains generic source IDs/behavior; (5) no fascia/contact/depth art paints authoritative floor or OCEAN; (6) wall-backed frontiers remain correct; (7) fixed-seed north/east/south/west cases prove deterministic directional presentation and bounded depth; (8) large contact plates are deterministic, placement-limited and streaming-safe; (9) generic cliff tests and Region Frame tests remain green; (10) lower cliff termination is visually swallowed by permanent fog rather than a hard strip; (11) normal gameplay-scale evidence no longer reads primarily as a repeating purple/generic cliff band; (12) objective checks precede and pass before one compact human visual review handoff.
- Validation: Fetch/verify the exact source-master ZIP from the registered Dropbox asset batch before mutation. Stage/extract outside the checkout, verify its package checksum and internal checksums, then derive assets through the documented source-work/resizer/inbox flow. At closeout, publish/fetch the final Gate B with `implementation_handoff.py` and verify its exact 26-state payload. Run Asset V2 plan/status/doctor. Run `procgen_void_cliff_face_smoke.gd`, `procgen_void_cliff_wall_integration_smoke.gd`, `procgen_region_frame_smoke.gd`, `procgen_macro_presentation_smoke.gd`, `elevated_world_asset_contract_smoke.gd`, affected streaming/materializer parity, changed-file validation and `git diff --check`. Add focused fascia-profile/contact-placement coverage for fallback behavior, direction cases, deterministic selection and no semantic mutation. Publish the smallest edge-direction evidence bundle and ask whether the upper plane/cliff/contact/fog read as one geographic structure without obscuring gameplay.
- Task overrides: `none`
- Deferred: Large playable Rocky Upland/Meridian surface vocabulary is `procgen-alpine-surface-plates-v1`; final environment tuning is `procgen-alpine-environment-cohesion-v1`; dynamic camera pitch remains separate.

## Required External Input — Approved Source Masters

This exact Dropbox batch is sufficient to claim AP2:

```text
CUSTODIAN/asset_batches/
  procgen-alpine-presentation/
    alpine-cliff-source-family-v1/
      custodian_alpine_cliff_source_family_v1.zip
      HANDOFF_MANIFEST.json
      ASSET_MANIFEST.md
      CHECKSUMS.sha256
      README.md
      CONTACT_SHEET.png
```

Primary ZIP SHA-256:

```text
e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3
```

Dropbox discovery authority:

```text
CUSTODIAN/asset_batches/_registry/
custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md
```

The previous `alpine-assets-11-20-v2` batch is superseded and must not be used.

The source batch contains 12 approved high-resolution masters. These are source authority, not final runtime canvases. Codex must derive exact runtime states through the Alpine presentation manifest and Asset Pipeline V2.

### AP2 closeout Gate B

After derivation and objective validation, AP2 produces/verifies:

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-cliff-presentation-v1/
    alpine-cliff-presentation-v1/
      HANDOFF_MANIFEST.json
      payload/
        procgen_alpine_cliff_fascia/     # 12 final PNGs
        procgen_alpine_cliff_contact/    # 10 final PNGs
        procgen_depth_chunks/            # 4 final PNGs
```

Exactly 26 final PNGs. This is a closeout/downstream receipt, not the prerequisite source input.

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
- Refresh instruction: AP1 is complete. No design refresh is required before claim if the registered `alpine-cliff-source-family-v1` batch and checksum match this packet. At claim time, re-derive exact source IDs/profile seams and public helper names from live main. Escalate only if live cliff ownership materially changes the authority boundary or the registered source batch cannot be verified.

## Handoff

- Next workstream: `procgen-alpine-surface-plates-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: After AP2 completes, verify Gate C and allow the surface-plate packet to become claimable.
- Blockers or open questions: none at claim time if the registered source-master ZIP verifies. Gate B is produced at AP2 closeout.