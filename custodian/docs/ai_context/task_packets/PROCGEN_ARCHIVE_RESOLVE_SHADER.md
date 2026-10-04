# PROCGEN ARCHIVE RESOLVE SHADER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-shader`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-archive-resolve-presentation-spine`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-procgen-archive-resolve-shader`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial shared-shader/presentation change; objective technical review plus separate human visual approval`
- Reviewed main: `4d49fdc3c86f9c423745d947a37cc380e8041d29`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Turn the landed AR1 flat diagnostic veil into the locked Archive Resolve visual language: graphite/soot uncertainty, coherent world-space irregular resolution, ordered pixel dither, restrained brass/amber registration, and a brief phase-alignment effect that disappears completely after settlement.
- Completion boundary: Done when the landed AR1 request/commit/unload/safety/pause scheduler is unchanged; its single `ArchiveResolveVeil` MultiMesh owns one shared pause-safe ShaderMaterial; render-only instance payload supports deterministic irregular dissolve without becoming a second state machine; reduced-effects controls exist; objective shader/material invariants pass; gameplay-scale evidence reads as continuous Archive resolution rather than chunk loading; and settled terrain returns to ordinary authored world presentation with zero persistent tint/overlay.
- Current measured state: AR1 is live on `main` from landed commit `83d89fd85`, and ARR1 has passed with 0 blocking defects / 0 material evidence gaps. `ProcGenRevealPresentation` is one `MultiMeshInstance2D` mounted as `ArchiveResolveVeil` at `z_index=2`; it owns REQUESTED -> READY -> RESOLVING -> settled presentation state, one fixed 8192-slot pool, deterministic ready/resolving queues, lifecycle-derived first-resolve vs reacquisition identity, a presentation clock advanced only from unpaused procgen processing, and committed-only Operator safety-halo settlement. AR1 currently writes only instance transform + `Color`; `Color.a` is the existing per-instance veil/progress channel. The MultiMesh uses `use_colors=true` and does not yet enable custom data. No Archive Resolve shader/material exists. ARR1 proved supported `set_effect_enabled(false)` is safe, production overflow is fail-open/fingerprint-inert, queued + immediate road-decal reacquisition works, request-before-commit mutation is caught, and S1 remains fingerprint `1773840677`. ARR1 also found two next-slice implementation issues: direct writes to bare exported `effect_enabled` can bypass the safe setter, and equal-z scene ordering puts `World/Enemies` under the veil because `Enemies` precedes `ContractMap` while `Operator` follows it. Two optional proof-hardening items remain: no committed production-map live-toggle/undersized-pool integration case and the M6 road reload assertion remains conditional.
- Evidence: `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`; `proc_gen_map.tscn`; `procgen_reveal_presentation_smoke.gd`; `PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE_CLAUDE_SUMMARY.md`; archived AR1 packet; live ARR1 packet; `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; shared CanvasItem precedent `custodian/game/world/procgen/foliage_life.gdshader`; `VISUAL_REVIEW_HANDOFF.md`.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`; landed AR1 runtime API/state; completed/passed ARR1 receipt on the archived AR1 packet; refreshed AR2 decisions in this authoring chat. ARR1 required no correction cycle and changed no AR1 owner/render/state semantics.
- Work surface: Add `custodian/game/world/procgen/streaming/archive_resolve.gdshader`; make narrow render-payload/material changes in `procgen_reveal_presentation.gd`; bind exactly one shared `ShaderMaterial` to the existing `ArchiveResolveVeil`; update `proc_gen_map.tscn` only for explicit presentation tuning defaults if useful; add/register one focused AR2 shader/material smoke or extend the existing AR1 smoke only where ownership remains clear; update only directly stale presentation docs/validation ownership.
- Change: Preserve AR1 scheduling and state transitions in behavior. Do not add a second queue, timer, phase scheduler, lifecycle observer, commit observer, or semantic registry. AR2 may extend only how an already-owned veil slot is encoded/rendered, plus the bounded ARR1 hardening below for live effect control, explicit world draw ordering, and committed proof coverage.
- Change: Enable MultiMesh custom data only if needed for deterministic render identity. Preferred payload is one write on slot assignment/reassignment, not a per-frame CPU rewrite: `INSTANCE_CUSTOM.r` = deterministic world-cell hash/jitter in [0,1]; `INSTANCE_CUSTOM.g` = reacquisition flag (0 first resolve, 1 reacquisition) if the landed AR1 seam can supply it without changing ownership; `INSTANCE_CUSTOM.b` reserved for later AR3 presentation class and must remain neutral in AR2; `INSTANCE_CUSTOM.a` reserved. If ARR1 or live code proves the reacquisition bit cannot be supplied cleanly without architectural bleed, leave it neutral and defer reacquisition styling to AR3. Existing instance `COLOR.a` remains the authoritative render-progress/veil-opacity channel. Never copy lifecycle state into shader-owned authority.
- Change: Add one shared CanvasItem shader/material. The shader receives the owner's pause-safe `presentation_time` through a uniform; do not use shader-global `TIME` for any pause-sensitive motion. The owner may update that one material uniform once per ordinary unpaused `advance()` call. No per-instance materials or per-cell uniform writes.
- Change: Close ARR1 R0-01 in the supported accessibility/debug control path. Make `ProcGenRevealPresentation.effect_enabled` safe when written directly by routing the exported property through the same disable/settle behavior as `set_effect_enabled()` (or one equivalent single implementation with no bypass). Add a narrow live `ProcGenTilemap` API such as `set_archive_resolve_enabled(enabled: bool)` that updates the configured flag and the existing veil when it is already initialized. Toggling off while REQUESTED/READY/RESOLVING cells exist must immediately leave zero active veil slots, permit later authoritative commits to remain visible, preserve lifecycle/streaming fingerprints, and support clean re-enable. Do not create a second enable state.
- Change: Close ARR1 R0-02 by preserving the locked rule that Archive Resolve is below gameplay actors/interactive world objects while remaining above terrain/walls. Do **not** globally raise actor z-indices, because that would disturb existing foliage/front-wall occlusion. In `custodian/scenes/game.tscn`, move the `World/ContractMap` sibling before the dynamic world presentation containers that may own z2 gameplay visuals (`Enemies`, `Projectiles`, `Allies`, `Items`, and `Operator`) while preserving node names/paths and all gameplay initialization. This makes equal-z actors/items/projectiles render after the ContractMap subtree, while existing procgen foliage-front/wall-overlay layers at z3/z4 continue to occlude actors normally. If live scene structure proves one listed container cannot safely move, preserve the same effective ordering through the narrowest equivalent scene-level mechanism; do not solve this by inflating global actor z hierarchy.
- Change: Implement the unresolved field as soot/graphite with low-frequency world-space variation derived from `MODEL_MATRIX`/world position plus deterministic instance identity. REQUESTED/READY coverage must remain visually opaque enough to hide authoritative commit timing. Variation must not reveal a 32 px cell grid, chunk boundary, checkerboard, or navigable detail behind unresolved cells.
- Change: During RESOLVING, replace AR1's simple linear alpha fade with an ordered pixel/dither breakup controlled by existing `COLOR.a` progress and coherent world-space variation. The shader may use a small Bayer-style threshold or equivalent deterministic ordered matrix plus low-frequency noise, but the result must read as material certainty resolving irregularly in connected local fronts, not a screen wipe or random sparkle field.
- Change: Add a thin intermittent aged-brass/archive-amber registration trace at the active dissolve boundary. It should be derived from the same deterministic threshold/progress rather than a second effect object. Allow sparse copper calibration ticks/hairlines only when they remain subordinate to world art. No neon, full-cell outline, permanent grid, particles, or floating mechanical motifs.
- Change: Add an optional <=1 px phase-misregistration treatment during the first portion of RESOLVING using veil/dither/registration sampling offsets only. Do **not** introduce a screen-texture/full-screen post-process or repaint/move underlying terrain just to achieve misregistration. If the batched veil cannot produce a convincing version without scene sampling, omit the effect in V1 rather than widening architecture.
- Change: Add presentation-only node controls consistent with the design lock: `registration_intensity`, `unresolved_haze_intensity`, `phase_misregistration_intensity`, and a reduced-effects toggle/profile. Reduced effects suppresses phase misregistration and substantially reduces registration intensity while leaving AR1 request/commit/order/timing and the unresolved safety cover intact. Existing `archive_resolve_enabled` remains the master effect switch; AR2 must not redefine its semantics.
- Change: Preserve AR1 slot overlap and z-layering. Hidden/released slots remain fully invisible. Settled terrain has no Archive Resolve shader object left over it, so final authored color/material/lighting is untouched.
- Change: Add compact render telemetry only if it materially improves validation: shared material count, shader enabled/reduced-effects flags, and optionally custom-data enabled. Do not add per-cell logs or per-frame debug spam. Existing AR1 counters remain the scheduling truth.
- Preserve: AR1 request-before-commit coverage; committed-only settlement; shared immediate/queued commit adapter; M3 PREPARE/COMMIT and M4 lifecycle semantics; M5 cache; M6 unload/residency; safety halo; deterministic frontier order; first-resolve/reacquisition identity; fixed slot-capacity/fail-open behavior; Region Frame/permanent exterior ownership; world generation, collision, navigation, biome/surface/route authority; actor/UI readability; existing terrain/art bytes; ordinary settled presentation.
- Non-goals: No semantic pre-echo or presentation-class styling; no spawn/ingress choreography; no final reacquisition timing change; no audio; no particles; no terrain scaling; no gameplay/discovery state; no new semantic registry; no full-screen screen-texture pipeline; no tuning of chunk sizes/radii/streaming budgets. The ARR1 R0-01 live-toggle hardening and R0-02 scene-order correction are explicitly in scope and are not permission for broader streaming or actor-layer refactors.
- Acceptance: (1) AR1 scheduling snapshots/order/lifecycle fingerprints are identical with AR2 shader enabled vs diagnostic/simple rendering. (2) Exactly one shared ShaderMaterial serves the existing batched veil; no per-cell Nodes/Tweens/Timers/materials are created. (3) MultiMesh custom data, if enabled, is deterministic for the same world cell/reacquisition identity and is written only on slot assignment/reuse, not scanned/rebuilt full-frontier each frame. (4) Shader visual phase derives from existing AR1 progress + pause-safe owner time; pausing freezes every animated shader component and resume has no time jump. (5) REQUESTED/READY cells remain safely obscured; shader noise/dither never reveals uncommitted or not-yet-resolved authoritative pixels. (6) Resolve reads irregularly without visible 32 px checkerboard or 16x16 chunk rectangles. (7) Brass/amber registration is thin/intermittent and disappears completely at settlement. (8) Phase misregistration is <=1 px, presentation-only, optional/reduced-effects suppressible, and requires no screen-texture architecture. (9) Reduced-effects mode changes only presentation intensity; streaming/lifecycle/order/fingerprints remain exact. (10) Both the exported owner enable property and the live ProcGenTilemap enable API use one safe transition path: disabling with REQUESTED/READY/RESOLVING state immediately yields zero active veils, late commits remain visible, re-enable works, and lifecycle/fingerprints remain exact. (11) `ContractMap` renders before z2 gameplay actors/items/projectiles so enemies/allies/Operator/readable interactives cannot be hidden by Archive Resolve solely because of equal-z scene order; existing z3/z4 foliage/front-wall occlusion remains unchanged. (12) Slot overflow remains fail-open, bounded, telemetry-visible, and semantically inert. (13) Settled world pixels/materials/lighting are ordinary authored presentation with no persistent tint. (14) The committed production-map smoke covers a live enable->disable->re-enable transition and an undersized slot pool, not only owner-level fixtures. (15) The committed distant-unload proof guarantees a real road decal/piece exists before unload and unconditionally asserts removal + queued/immediate reacquisition restoration; no `if had_road_decal` escape remains for the claimed parity assertion. (16) S1 quick remains `1773840677` unless an independently approved baseline change lands first. (17) Human gameplay-scale review describes the effect as resolving/stabilizing/registering rather than chunks loading, squares popping, fog simply fading, a shader wipe, or a holographic grid.
- Validation: ARR1 is complete/passed, so this packet is executable. **Headless success is insufficient for this shader packet; complete the Real Renderer Gate below before commit/land.** Add/register focused AR2 shader/material validation proving one shared material, optional custom-data contract, deterministic identity, pause-safe `presentation_time`, REQUESTED/READY concealment, settled transparency, reduced-effects parity, and no per-cell object/material growth. Fold ARR1 R0-03 into committed integration coverage: on the production map, create REQUESTED/READY work, toggle Archive Resolve off through the supported map API, require zero active veils and fingerprint parity, re-enable, and complete a subsequent reveal; also force a deliberately undersized slot pool and prove bounded fail-open parity with exact overflow accounting. Fold ARR1/RFR1 R0-04 into `procgen_distant_chunk_unload_smoke.gd` or the narrowest authoritative fixture by constructing a guaranteed real road decal/piece before unload and asserting unconditional removal plus queued and immediate reacquisition restoration. Add a scene-structure/effective-z assertion proving `ContractMap` precedes z2 actor/item/projectile containers while z3/z4 procgen foreground occlusion remains above them. Re-run registered `procgen_reveal_presentation`, `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_distant_chunk_unload`, `procgen_runtime_health`, `procgen_candidate_materializer_parity`, `procgen_region_frame`, and S1 quick; require fingerprint `1773840677` unless the accepted baseline changed independently. Inspect active/hidden instance counts and material identity directly instead of inferring from screenshots. Use changed-file validation, review-pairing/docs/manifest checks, `check_ai_context.py` only for newly introduced failures versus its known baseline, and `git diff --check`.
- Visual review: After objective validation is green, capture the smallest gameplay-scale motion evidence that can answer continuity/readability. Prefer a short Moment Forge evidence run and compact keyframes/contact sheet; include one MP4 only if motion itself is necessary. Publish through `python3 custodian/tools/iteration/publish_review_artifacts.py --important` under workstream `procgen-archive-resolve-shader` following `VISUAL_REVIEW_HANDOFF.md`. Ask: (a) does the frontier read as continuous Archive resolution rather than chunk catch-up/square pop; (b) are graphite/soot and brass/amber accents subordinate to terrain and Operator readability; (c) does settled terrain return completely to ordinary world art; (d) is reduced-effects mode materially calmer without becoming a plain loading fade? Record the Dropbox manifest path and explicit user decision in the completion summary. The execution agent cannot self-approve aesthetics.
- Task overrides: `none`
- Deferred: AR3 owns bounded semantic pre-echo, presentation-class differentiation, stronger initial ingress/spawn resolve, and final shortened/weaker reacquisition choreography. Audio remains optional future polish.

## Dependency Gate — ARR1 CLOSED

ARR1 is complete/passed with 0 blocking defects and 0 material evidence gaps. It changed no AR1 owner/render/state contract, so the planning refresh already performed in this chat remains valid and this packet is now `ready/auto`.

ARR1 findings are folded into this packet:
- R0-01: safe live enable/disable property + map API;
- R0-02: explicit actor/veil ordering through scene sibling order rather than z-index inflation;
- R0-03: committed live-toggle + undersized-pool integration coverage;
- R0-04: unconditional committed road-decal unload/reacquisition proof.

No AR1 correction packet is required.

## Real Renderer Gate — REQUIRED BEFORE COMMIT / LAND

Headless Godot uses a dummy renderer and does not prove that `archive_resolve.gdshader` parses, links, renders, or behaves correctly on the production CanvasItem path. AR2 may not be committed/finished/landed based only on headless smoke success.

Before closeout:

1. reconcile the isolated AR2 worktree against current `origin/main` while preserving the task diff; renderer proof must exercise the code state that is intended to land;
2. run the cheapest graphical-renderer proof on the user's active X11/Wayland session and require zero shader compile/link/runtime errors;
3. use Moment Forge with `--capture-mode evidence` for the final representative motion proof. First run `python3 custodian/tools/iteration/run_moment.py --changed` in the AR2 worktree. If no existing scenario actually exercises the production procgen `ArchiveResolveVeil`, add one narrowly scoped AR2 scenario/fixture under `custodian/tools/iteration/scenarios/procgen/` rather than misusing an unrelated authored-reveal scenario;
4. the renderer-backed scenario must exercise at least REQUESTED/READY concealment, visible RESOLVING motion, full settlement, pause freeze, reduced-effects presentation, and actor-over-veil ordering at gameplay scale. It should also force at least one reacquisition if practical without broadening the fixture;
5. capture the minimum evidence budget needed to judge motion. Because dissolve continuity is the acceptance question, one short MP4 is justified if sparse keyframes cannot establish it; otherwise prefer evidence-mode keyframes/contact sheet;
6. publish the compact evidence through `publish_review_artifacts.py --important` and stop for explicit user/ChatGPT visual approval. Do not self-approve the look;
7. only after real-renderer compile/run success, objective validation, and explicit visual approval may the agent fill Completion Truth, commit, and run `workstream.py finish`.

If the graphical renderer reports a shader parse/link/runtime error, fix it in the AR2 worktree and rerun the focused renderer proof before any landing attempt. If the visual effect is technically valid but fails human aesthetic/readability review, keep the workstream open for bounded AR2 tuning; do not defer a failed AR2 visual baseline into AR3.

## Recommended Implementation Order

1. Add the shared shader/material with flat-output parity first; prove no scheduling/fingerprint change.
2. Add deterministic render payload/custom data without changing queues or state transitions.
3. Add world-space graphite variation + ordered dither resolve.
4. Add restrained registration trace and optional <=1 px misregistration.
5. Add reduced-effects controls and pause-safe material-uniform synchronization.
6. Run objective validation; only then capture/publish compact human visual evidence.

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

## Refresh Planning Authority

- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh instruction: This packet was refreshed here against landed AR1 and then updated again after passed ARR1. No further planning refresh is required before implementation.

## Handoff

- Next workstream: `review-procgen-archive-resolve-shader`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none after clean/non-blocking ARR1; return here only if ARR1 correction changes AR1 assumptions`
- Next action: Claim AR2 now, implement the shader plus the four bounded ARR1 follow-ups, complete objective validation and Dropbox human visual review, then let the paired fresh-context AR2 review claim automatically.
- Blockers or open questions: Real-renderer shader compile/runtime proof and explicit human visual approval are mandatory pre-land gates. Headless validation alone does not satisfy AR2.
