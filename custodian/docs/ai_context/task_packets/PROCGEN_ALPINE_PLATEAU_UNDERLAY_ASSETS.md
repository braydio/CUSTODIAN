# PROCGEN ALPINE PLATEAU UNDERLAY ASSETS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-plateau-underlay-assets`
- Status: `blocked`
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
- Reviewed main: `a672effbaba3905ed60eadd8b714d03265f72443`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Publish the six production Asset Pipeline V2 images for the first `ALPINE_PLATEAU` permanent underlay, bind them to the reviewed Region Frame profile, remove the explicit Endless Forest compatibility fallback for that frame, and obtain human visual approval of the cliff-fog-distant-world composition.
- Completion boundary: Done when the `procgen_underlay_alpine_plateau` Asset V2 family exists and passes the live asset doctor; all six required 1536x1024 static states are ingested/bound/verified; `alpine_plateau_underlay.tres` deterministically selects FAR/MIDDLE/NEAR A/B variants by accepted procgen seed through the existing `ProcgenUnderlayProfile` path; the reviewed `ALPINE_PLATEAU` Region Frame selects that resource with fallback telemetry cleared; the runtime keeps Archive Resolve separate; and the user/human review accepts the gameplay-scale permanent edge composition.
- Current measured state: RF1 landed as `49cbd3982d145283ef7aeb85a921057f854ea88e`. Live `presentation/region_frames/alpine_plateau.tres` now exists and explicitly selects `profile_id=alpine_plateau`, binds `presentation/underlays/endless_forest_underlay.tres` only as a stand-in, sets `visual_fallback=true`, and names this workstream in `fallback_reason`. `ProcgenRegionFrameProfile` is presentation-only and validated; the starting-region scene explicitly selects Alpine while reusable generator defaults remain neutral. Exterior/internal CHASM partitioning and exterior-only DepthBackdrop behavior are implemented and covered by `procgen_region_frame_smoke.gd`. No Alpine runtime underlay PNG family or `alpine_plateau_underlay.tres` exists yet. The live Asset V2 backdrop precedent remains `drowned_basilica_underlay.asset.json`: `custodian.asset_family.v2`, kind `backdrop`, 1536x1024 canvas, omni, no auto-mirror, copy layout. RFR1 is ready/auto but has not yet produced its Independent Review receipt, and the six approved Alpine source PNGs still do not exist.
- Evidence: `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; RF1 landed commit `49cbd3982d145283ef7aeb85a921057f854ea88e`; `presentation/procgen_region_frame_profile.gd`; `presentation/region_frames/alpine_plateau.tres`; `procgen_region_frame_smoke.gd`; live `drowned_basilica_underlay.asset.json`; `procgen_underlay_profile.gd`; `drowned_basilica_underlay.tres`; Asset Pipeline V2 tooling at `custodian/tools/assets/asset.py`.
- Task-specific authority: Asset Pipeline V2 live family schema/tooling; `PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; reviewed Region Frame foundation.
- Work surface: New family metadata `custodian/content/metadata/assets/families/procgen_underlay_alpine_plateau.asset.json`; source masters under `custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_plateau/`; normalized intake under `custodian/asset_drop/inbox/procgen_underlay_alpine_plateau/`; runtime domain `custodian/content/backgrounds/procgen/alpine_plateau/`; new `custodian/game/world/procgen/presentation/underlays/alpine_plateau_underlay.tres`; narrow reviewed Region Frame profile binding only.
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
- Acceptance: (1) All six family states are `ingested/bound/verified` under the current Asset V2 tracker/doctor. (2) Runtime images are exactly 1536x1024 with no accidental scaling/matte/registration shift. (3) Fixed seeds select deterministic A/B combinations. (4) Alpine frame no longer reports fallback and uses the Alpine profile. (5) Internal ravines do not cause the global underlay to appear; exterior plateau border does. (6) No Archive Resolve state/material is used by this family. (7) One gameplay-scale edge capture demonstrates readable plateau/cliff, obscuring fog, and only faint distant lower world. (8) Human review explicitly accepts the final art balance; if not, packet remains open.
- Validation: Before ingest, inspect `python3 custodian/tools/assets/asset.py --help` and use the current commands, not stale guessed syntax. Run current family plan/status/doctor equivalents before and after ingest. Run Godot import as required by the live pipeline. Then run the reviewed Region Frame smoke, Drowned underlay regression, elevated-world asset contract, and changed-file/asset validation. Visual evidence economy: one representative fixed-seed plateau edge capture plus at most targeted FAR/MIDDLE/NEAR isolation crops if the combined frame cannot identify which layer is wrong.
- Task overrides: `none`
- Deferred: Additional region frames and additional Alpine variants beyond A/B.

## Source Art Blocker

This packet is fully authored but must remain blocked until **both** conditions are true: (1) RFR1 has landed a clean/non-blocking Region Frame review receipt, and (2) six user-approved source PNGs exist at the exact `source_work` paths above. Do not fabricate substitute runtime art in Codex. Once both conditions are true, return to the recorded planning chat with the RFR1 summary plus source-art decisions, refresh `Reviewed main`/live API bindings in place, then set `Status: ready`.

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

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh instruction: Bring the landed predecessor implementation/review summary and any new live-state evidence back to this ChatGPT conversation. Re-derive this packet here with the user against current `main` before changing it to `ready/auto`. Do not let the execution agent silently reinterpret architecture, scope, sequencing, visual direction, or acceptance during the refresh.

## Handoff

- Next action: Produce/approve the six source images, then refresh and ingest through Asset Pipeline V2.
- Best starting files: family metadata precedent, reviewed Region Frame profile, `procgen_underlay_profile.gd`.
- Blockers or open questions: Six approved source images and final human art-direction sign-off.
