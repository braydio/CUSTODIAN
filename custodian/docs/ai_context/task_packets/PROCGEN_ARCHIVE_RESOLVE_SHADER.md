# PROCGEN ARCHIVE RESOLVE SHADER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-shader`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-archive-resolve-presentation-spine`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `bc3e354bb20641d4c6ce9317c38002b9e3449ca0`
- Goal: Turn the proven AR1 flat veil into the locked Archive Resolve visual language: graphite/soot uncertainty, coherent world-space irregular resolution, ordered pixel dither, restrained brass/amber registration, and a brief phase-alignment effect that disappears completely after settlement.
- Completion boundary: Done when the AR1 scheduler/ownership is unchanged, one shared pause-safe shader/material path renders the locked Archive Resolve phases without per-cell materials/tweens, the frontier reads as continuous world-space resolution rather than chunk loading or square pop-in, reduced-effects controls exist, and settled terrain returns to its ordinary authored appearance.
- Current measured state: No Archive Resolve runtime owner or shader exists yet. The hardened design is locked in `STREAMING_REVEAL_PRESENTATION_V1.md`; AR1 is expected to provide batched frontier instances, deterministic per-cell phase/start identity, first-resolve/reacquisition state, and a presentation clock.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; AR1 packet; existing shared CanvasItem shader patterns such as `foliage_life.gdshader`; current world atmosphere and pause-aware presentation conventions.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`; landed AR1 runtime API/state after refresh.
- Work surface: Expected `custodian/game/world/procgen/streaming/archive_resolve.gdshader`, the AR1 presentation owner/material setup, focused shader/presentation smoke, development controls, and one minimal gameplay-scale visual-evidence harness.
- Change: Keep AR1 scheduling untouched. Add one shared CanvasItem shader driven by presentation-owner time, world position, deterministic instance custom data, and current phase. Implement graphite/soot unresolved field, coherent low-frequency variation, ordered dither reveal, thin intermittent aged-brass/archive-amber registration edge, restrained copper calibration ticks, and optional 1-pixel phase misregistration that collapses before settlement. Slightly overlap cell veil quads so the 32 px grid never appears. Settled cells must remove all special treatment.
- Preserve: AR1 committed-only/safety-halo rules; all streaming/gameplay authority; pixel-art crispness; Operator/UI readability; world lighting/atmosphere; performance budget; current terrain/art bytes.
- Non-goals: No semantic echo; no ingress-specific spawn choreography; no audio; no particles; no floating gears; no permanent cyber-grid; no terrain scaling; no gameplay-state dependence on shader state; no full-screen screen-texture pipeline unless a measured prototype proves the batched veil cannot meet the locked design.
- Acceptance: Same AR1 phase/order identity with shader enabled/disabled; no chunk rectangles or visible checkerboard; no final-world tint once settled; pause freezes effect time; reduced-effects mode can suppress phase misregistration/registration intensity without touching streaming; active frontier stays batched/shared-material; gameplay-scale motion evidence reads as resolving/stabilizing rather than loading/catching-up.
- Validation: Refresh against landed AR1. Add focused shader/material contract checks for shared material, deterministic custom data, pause clock, disabled/reduced-effects fallbacks, settled transparency, and no per-cell material/tween creation. Re-run AR1 smoke and changed-file closeout. Human visual review uses the smallest representative gameplay-scale motion capture needed to judge frontier continuity and distraction.
- Task overrides: `none`
- Deferred: Semantic pre-echo, spawn resolve, and shortened reacquisition polish are AR3. Audio remains optional future polish.

## Temporary Refresh Gate — REMOVE WHEN THIS PACKET IS REFRESHED

This packet is intentionally pre-authored before AR1 exists.

After `review-procgen-archive-resolve-presentation-spine` lands clean/non-blocking:

1. fetch current `origin/main` and read the archived AR1 independent-review receipt;
2. inspect the actual reviewed AR1 owner, render primitive, custom-data schema, pause clock, performance evidence, and validation;
3. update `Reviewed main`, measured state, exact work surface, shader inputs, validation, and any performance constraints;
4. remove this entire **Temporary Refresh Gate** section;
5. only then set `Status: ready`.

Do not redesign AR1 scheduling merely because this pre-authored packet guessed a different private representation.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: Refresh only after the paired AR1 review lands clean/non-blocking and its flat-veil architecture is proven.
- Best starting files: landed AR1 presentation owner; `STREAMING_REVEAL_PRESENTATION_V1.md`; existing shared CanvasItem shader conventions.
- Blockers or open questions: Final shader tuning is human-owned visual judgment, not an auto-approval criterion.
