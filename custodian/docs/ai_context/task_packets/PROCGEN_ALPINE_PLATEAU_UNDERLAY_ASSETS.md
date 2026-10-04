# PROCGEN ALPINE PLATEAU UNDERLAY ASSETS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-plateau-underlay-assets`
- Status: `ready`
- Dispatch: `manual`
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
- Review rationale: `manual human visual approval + local ~/Downloads source bundle; technical ingest remains deterministic`
- Reviewed main: `9093c9ff1613de39d37a876246f6ab61f24f5938`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Publish the six production Asset Pipeline V2 images for the first `ALPINE_PLATEAU` permanent underlay, bind them to the reviewed Region Frame profile, remove the explicit Endless Forest compatibility fallback for that frame, and obtain human visual approval of the cliff-fog-distant-world composition.
- Completion boundary: Done when the `procgen_underlay_alpine_plateau` Asset V2 family exists and passes the live asset doctor; all six required 1536x1024 static states are ingested/bound/verified; `alpine_plateau_underlay.tres` deterministically selects FAR/MIDDLE/NEAR A/B variants by accepted procgen seed through the existing `ProcgenUnderlayProfile` path; the reviewed `ALPINE_PLATEAU` Region Frame selects that resource with fallback telemetry cleared; the runtime keeps Archive Resolve separate; and the user/human review accepts the gameplay-scale permanent edge composition.
- Current measured state: RF1 landed as `49cbd3982d145283ef7aeb85a921057f854ea88e`; RFR1 passed on `07d2277e8` with 0 blocking defects and 0 material evidence gaps, making Region Frame stable presentation authority. Live `presentation/region_frames/alpine_plateau.tres` explicitly selects `profile_id=alpine_plateau`, binds Endless Forest only as an explicit `visual_fallback=true` stand-in, and uses exterior-only DepthBackdrop behavior. The user has now approved/provided the six generated source candidates as one local archive expected at `~/Downloads/alpine_plateau_underlay_assets.zip`. The archive contract is exact: six root-level RGBA PNGs named `far_world_a.png`, `far_world_b.png`, `depth_fog_a.png`, `depth_fog_b.png`, `near_cliff_mist_a.png`, `near_cliff_mist_b.png`, each 1536×1024, one frame, true alpha. Final gameplay-scale composition approval remains human-owned after runtime integration. RFR1 next-slice findings R0-01 (registered end-to-end production-scene frame assertion) and R0-02 (ocean-as-conduit exterior-mask pocket) are owned by this packet as technical proof hardening before final visual approval.
- Evidence: `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; RF1 landed commit `49cbd3982d145283ef7aeb85a921057f854ea88e`; `presentation/procgen_region_frame_profile.gd`; `presentation/region_frames/alpine_plateau.tres`; `procgen_region_frame_smoke.gd`; live `drowned_basilica_underlay.asset.json`; `procgen_underlay_profile.gd`; `drowned_basilica_underlay.tres`; Asset Pipeline V2 tooling at `custodian/tools/assets/asset.py`.
- Task-specific authority: Asset Pipeline V2 live family schema/tooling; `PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; reviewed Region Frame foundation.
- Work surface: Local source bundle `~/Downloads/alpine_plateau_underlay_assets.zip`; new family metadata `custodian/content/metadata/assets/families/procgen_underlay_alpine_plateau.asset.json`; source masters under `custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_plateau/`; normalized intake under `custodian/asset_drop/inbox/procgen_underlay_alpine_plateau/`; runtime domain `custodian/content/backgrounds/procgen/alpine_plateau/`; new `custodian/game/world/procgen/presentation/underlays/alpine_plateau_underlay.tres`; narrow reviewed Region Frame profile binding only.
- Change: Register this exact family contract using the current live schema:
  - schema: `custodian.asset_family.v2`
  - id: `procgen_underlay_alpine_plateau`
  - kind: `backdrop`
  - runtime domain: `backgrounds/procgen/alpine_plateau`
  - owner: `alpine_plateau`
  - filename policy: same current template policy used by Drowned Basilica
  - canvas: `1536x1024`
  - direction_policy: `omni`
  - auto_mirror: `false`
  - every state: required, static, one frame, layout `copy`, layer `background`, action_group `display`.
- Change: Required states and semantics:
  - `far_world_a`, `far_world_b`: very subdued distant lower-world ridges/valleys, forest masses, snow bands and sparse far infrastructure; no readable gameplay routes.
  - `depth_fog_a`, `depth_fog_b`: broad obscuring valley fog/cloud shelf that hides the cliff terminus without reading as Archive Resolve graphite veil.
  - `near_cliff_mist_a`, `near_cliff_mist_b`: near depth haze with restrained descending conifer/rock silhouette, subordinate to world-positioned cliff fascia.
- Source-work save paths:
  - `custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_plateau/far_world_a_source.png`
  - `.../far_world_b_source.png`
  - `.../depth_fog_a_source.png`
  - `.../depth_fog_b_source.png`
  - `.../near_cliff_mist_a_source.png`
  - `.../near_cliff_mist_b_source.png`
- Normalized inbox names, each exactly `1536x1024`, one frame, RGBA PNG, preserve true alpha/no matte and never stretch:
  - `custodian/asset_drop/inbox/procgen_underlay_alpine_plateau/far_world_a.png`
  - `.../far_world_b.png`
  - `.../depth_fog_a.png`
  - `.../depth_fog_b.png`
  - `.../near_cliff_mist_a.png`
  - `.../near_cliff_mist_b.png`
- Expected canonical runtime outputs are pipeline-owned; for review they should resolve under `custodian/content/backgrounds/procgen/alpine_plateau/` to the current template equivalents of `alpine_plateau_<variant>_1536x1024.png`. Do not hand-author runtime filenames or copy raw generated art directly into runtime.
- Change: Build `alpine_plateau_underlay.tres` with FAR = far_world A/B, MIDDLE = depth_fog A/B, NEAR = near_cliff_mist A/B. Keep opacity values data-driven in the resource; initial values should be tuned against gameplay capture, not copied blindly from Endless Forest or Drowned Basilica. Region Frame selection clears `visual_fallback` only when all six runtime assets and the profile validate.
- Preserve: Region Frame exterior-mask semantics; M3-M6 streaming; Archive Resolve; local biome; collision/navigation; existing Drowned Basilica and Endless Forest resources; deterministic seed variant selection; pixel/gameplay readability.
- Non-goals: No Archive Resolve shader/effect work; no new cliff-fascia tile art; no future region-frame assets; no minimap/compass; no generation/topology change.
- Acceptance: (1) The exact `~/Downloads/alpine_plateau_underlay_assets.zip` contract is verified before ingest and raw generated bytes are preserved in `source_work`. (2) All six family states are `ingested/bound/verified` under the current Asset V2 tracker/doctor. (3) Runtime images are exactly 1536×1024 with true alpha and no accidental scaling/matte/registration shift. (4) Fixed seeds select deterministic A/B combinations. (5) Alpine frame no longer reports fallback and uses the Alpine profile. (6) Internal ravines do not cause the global underlay to appear; exterior plateau border does. (7) RFR1 R0-01 is closed by a registered end-to-end production-scene assertion that a real generated starting scene reports `frame_id=alpine_plateau` and the correct bound Alpine underlay after integration. (8) RFR1 R0-02 is closed by a deterministic classifier fixture proving an OCEAN pocket touching/bisecting exterior CHASM does not become a CHASM flood conduit or corrupt the exterior/internal partition. (9) No Archive Resolve state/material is used by this family. (10) Objective asset checks are green before subjective review. (11) One compact gameplay-scale edge evidence bundle demonstrates readable plateau/cliff, obscuring fog, and only faint distant lower world. (12) Human review explicitly accepts the final art balance; if not, packet remains open.
- Validation: Before ingest, verify the exact local ZIP contract and inspect `python3 custodian/tools/assets/asset.py --help`; use current commands, not stale guessed syntax. Run current family plan/status/doctor equivalents before and after ingest and Godot import as required by the live pipeline. Extend/register focused Region Frame coverage for RFR1 R0-01 production-scene frame/binding truth and R0-02 ocean-as-conduit exclusion, then run `procgen_region_frame`, nonwalkable-surface coverage, Drowned underlay regression, `elevated_world_asset_contract`, asset validation, changed-file validation, and `git diff --check`. Only after objective checks pass, create the smallest representative fixed-seed plateau-edge evidence bundle and publish it through `python3 custodian/tools/iteration/publish_review_artifacts.py --important ...` under workstream `procgen-alpine-plateau-underlay-assets`, following `VISUAL_REVIEW_HANDOFF.md`. Ask specifically whether the three-depth composition keeps the playable cliff readable, fog convincingly hides the lower terminus, and the far world remains subordinate/non-navigable. Record the Dropbox manifest path in the completion summary; the execution agent does not self-approve aesthetics.
- Task overrides: `none`
- Deferred: Additional region frames and additional Alpine variants beyond A/B.

## Local Source Bundle

The user-provided/generated source bundle is expected at:

```text
~/Downloads/alpine_plateau_underlay_assets.zip
```

Before touching repository asset state:

1. verify that exact file exists locally; do not search arbitrary Downloads archives or substitute another bundle;
2. inspect the ZIP without mutating the repository and require exactly these six root-level PNG entries:
   - `far_world_a.png`
   - `far_world_b.png`
   - `depth_fog_a.png`
   - `depth_fog_b.png`
   - `near_cliff_mist_a.png`
   - `near_cliff_mist_b.png`
3. verify every image is RGBA, exactly 1536×1024, one static frame, and contains a real alpha channel; reject rather than stretch/reformat a dimension mismatch;
4. copy/extract each raw generated file first into the exact `source_work` path below using the `*_source.png` name, then stage normalized semantic copies under `asset_drop/inbox/procgen_underlay_alpine_plateau/`; never extract directly into runtime;
5. preserve original generated bytes in `source_work`. Any normalization that materially changes composition, crop, alpha edge, or color requires user review rather than silent correction.

This local ZIP is an input artifact, not repository authority and not a runtime dependency.

## Source Art Gate

The dependency/review gate is satisfied: RFR1 passed. The six source candidates are now provided through the exact local ZIP contract above, so this packet is `ready/manual` for a local agent that can access `~/Downloads`. Do not fabricate substitute art if the ZIP is missing or malformed. Final gameplay-scale visual acceptance remains a completion gate, not a pre-implementation blocker.

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
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`


## Refresh Planning Authority

- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh instruction: This packet has now been refreshed in the recorded planning chat against passed RFR1 and the local six-image ZIP contract. No further planning refresh is required before implementation unless live Asset Pipeline V2 or Region Frame APIs materially diverge; if they do, return to this same chat before changing architecture/scope.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none`
- Next action: Claim this packet manually on the local machine with access to `~/Downloads/alpine_plateau_underlay_assets.zip`; complete deterministic Asset V2 ingest/binding first, then publish the compact Dropbox visual-review handoff for user approval.
- Blockers or open questions: Final human art-direction approval remains required before completion; no implementation blocker remains if the exact ZIP is present.
