# BRIDGED FALLS — VISTA + WATERFALL PRESENTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `bridged-falls-vista-waterfall-presentation`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-bridged-falls-bridge-grammar-asset-v2`
- Locks: `bridged-falls-vista, bridged-falls-waterfall-art, procgen-region-frame`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-bridged-falls-vista-waterfall-presentation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `required`
- Goal: Deliver the locked Bridged Falls atmosphere in live generated gameplay: colossal falls and mist, Lower Quarter lowland basin, sunset depth, and Station IX skyline, while keeping top-down routes immediately readable.
- Completion boundary: Add a location-specific Bridged Falls region-frame/underlay treatment plus world-positioned generated waterfall/mist presentation driven by BF4 geometry and BF5 bridge presentation. Provide deterministic review compositions for first basin reveal, bridge traverse and Lower Quarter approach. Do not change topology or authored Lower Quarter gameplay.
- Current measured state: The existing region-frame seam supports FAR/MIDDLE/NEAR underlays and `alpine_plateau` has a production family. No Bridged Falls frame/underlay/waterfall family exists on reviewed main. BF4/BF5 are assumed landed before execution and must be re-read before this draft is promoted.
- Evidence: `design/05_levels/ASH_BELL_BRIDGED_FALLS_APPROACH.md`; `PROCGEN_REGION_FRAME_PROFILES.md`; current `procgen_underlay_alpine_plateau` family/profile; BF4/BF5 live geometry/asset IDs after refresh.
- Task-specific authority: Region Frame owns permanent exterior presentation only; BF4 owns generated gameplay topology; BF5 owns bridge art; Asset Pipeline V2 owns published visual assets; waterfall/mist presentation never owns collision/navigation.
- Work surface: Bridged Falls underlay family/profile, waterfall/mist families, generated presentation attachment/composer, deterministic Moment Forge/renderer fixtures, region-frame tests.
- Change:
  1. Register `procgen_underlay_ash_bell_bridged_falls` with six one-frame 1536×1024 RGBA states: `far_lower_quarter_a/b`, `middle_waterfall_haze_a/b`, `near_bridge_mist_a/b`.
  2. Source path: `custodian/asset_drop/source_work/procgen/procgen_underlay_ash_bell_bridged_falls/`; inbox: `custodian/asset_drop/inbox/procgen_underlay_ash_bell_bridged_falls/`; runtime: `custodian/content/backgrounds/procgen/ash_bell_bridged_falls/`; metadata: `custodian/content/metadata/assets/families/procgen_underlay_ash_bell_bridged_falls.asset.json`; underlay profile: `custodian/game/world/procgen/presentation/underlays/ash_bell_bridged_falls_underlay.tres`; region frame: `custodian/game/world/procgen/presentation/region_frames/ash_bell_bridged_falls.tres`.
  3. Add a world-positioned `ash_bell_bridged_falls_waterfall_v1` family. Provisional states: lip 96×64 static; narrow fall 96×256 6f@8 FPS; wide fall 192×256 6f@8 FPS; grand fall 320×384 6f@8 FPS; mist 192×128 8f@6 FPS; grand mist 384×192 8f@6 FPS. Refresh exact attachment/canvas needs from BF4/BF5 before ready.
  4. Attach waterfall presentation to generated eligible CHASM/exterior edges and civic-spillway tags without mutating surface kinds, floor, collision or navigation.
  5. Lower Quarter/Station IX remain low-contrast far presentation until the final approach. Station IX is a silhouette cue, not a close hero facade.
  6. Lock warm sunset as the canonical review state while preserving functional compatibility with broader time/weather systems.
  7. Produce three deterministic review moments: FIRST BASIN REVEAL, BRIDGE TRAVERSE, LOWER QUARTER APPROACH. Each must show clear near/mid/far separation and immediate walkability.
- Preserve: BF4 topology hashes/reachability; BF5 bridge registration; generic Alpine frame; Archive Resolve; all gameplay semantics.
- Non-goals: No Lower Quarter route cutover. No new weather system. No side-view camera. No waterfall physics.
- Acceptance: Asset V2 doctor/status green; Bridged Falls frame is explicitly selected only where intended; waterfalls/mist correspond deterministically to generated geometry and own no gameplay authority; required review moments are stable/reproducible; human review accepts the sunset-waterfall ruin-city atmosphere and top-down readability.
- Validation: Mandatory authoring-chat refresh. Run Asset V2 checks, `res://tools/validation/procgen_region_frame_smoke.gd`, BF4 topology proof, BF5 bridge presentation proof, and new focused Bridged Falls presentation checks. Publish one compact review handoff at `/CUSTODIAN/visual_review/bridged-falls-vista-waterfall-presentation/` containing only the three required compositions plus one overview/contact sheet. Reviewer questions: (1) does the basin/falls/bridge scale match the locked reference, (2) is Station IX distant but legible, (3) is playable ground obvious in top-down view, (4) does the sunset/mist preserve near/mid/far separation?
- Task overrides: `none`
- Deferred: Lower Quarter route handoff/cutover and future time-of-day variants.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh instruction: Bring reviewed BF4 topology dimensions and BF5 asset family/module identities to this chat. Re-lock waterfall attachment/canvas details and exact frame/profile integration before setting ready.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill>`
- Completion boundary satisfied: `<fill>`
- Acceptance satisfied: `<fill>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill>`
- Friction severity: `<fill>`
- What went wrong: `<fill>`
- Root cause / contributing factors: `<fill>`
- Prevention / pipeline improvement: `<fill>`
- Tooling / docs drift discovered: `<fill>`
- Follow-up: `<fill>`

## Handoff
- Next workstream: `bridged-falls-lower-quarter-handoff`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable summary and final Next Handoff.
- Refresh reason: BF7 must consume the reviewed final generated terminal, bridge/falls presentation and existing Lower Quarter live route without duplicating state authority.
- Next action: Return BF6 visual decision + technical evidence to this chat and re-author BF7 against live main.
- Blockers or open questions: Lower Quarter handoff mechanism intentionally remains uncommitted until the landed lifecycle/topology route is visible.
