# PROCGEN ARCHIVE RESOLVE SHADER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-shader`
- Status: `blocked`
- Dispatch: `manual`
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
- Reviewed main: `797cd56b8e46d724294db71cf05d6346d53e4e8d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Turn the landed AR1 flat diagnostic veil into the locked Archive Resolve visual language: graphite/soot uncertainty, coherent world-space irregular resolution, ordered pixel dither, restrained brass/amber registration, and a brief phase-alignment effect that disappears completely after settlement.
- Completion boundary: Done when the landed AR1 request/commit/unload/safety/pause scheduler is unchanged; its single `ArchiveResolveVeil` MultiMesh owns one shared pause-safe ShaderMaterial; render-only instance payload supports deterministic irregular dissolve without becoming a second state machine; reduced-effects controls exist; objective shader/material invariants pass; gameplay-scale evidence reads as continuous Archive resolution rather than chunk loading; and settled terrain returns to ordinary authored world presentation with zero persistent tint/overlay.
- Current measured state: AR1 is live on `main` from landed commit `83d89fd85`. `ProcGenRevealPresentation` is one `MultiMeshInstance2D` mounted as `ArchiveResolveVeil` at `z_index=2`, over generated terrain/walls and below actors. It owns REQUESTED -> READY -> RESOLVING -> settled presentation state, one fixed 8192-slot pool, deterministic ready/resolving queues, lifecycle-derived first-resolve vs reacquisition identity, a presentation clock advanced only from unpaused procgen processing, and committed-only Operator safety-halo settlement. AR1 currently writes only instance transform + `Color`; `Color.a` is the existing per-instance veil/progress channel. The MultiMesh uses `use_colors=true` and does **not** yet enable custom data. No Archive Resolve shader/material exists. Slot overflow intentionally fails open and increments `overflow_count`. Startup-disabled mode is covered; ARR1 is separately probing live enabled->disabled behavior and the carried road-decal reacquisition proof. The AR1 smoke is registered as `procgen_reveal_presentation`; AR1 reported passing pause/lifecycle/cache/unload/runtime-health/candidate-materializer/region-frame regressions and S1 `determinism_ok=true`.
- Evidence: `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`; `proc_gen_map.tscn`; `procgen_reveal_presentation_smoke.gd`; `PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE_CLAUDE_SUMMARY.md`; archived AR1 packet; live ARR1 packet; `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; shared CanvasItem precedent `custodian/game/world/procgen/foliage_life.gdshader`; `VISUAL_REVIEW_HANDOFF.md`.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`; landed AR1 runtime API/state; clean/non-blocking ARR1 receipt once available. If ARR1 requires a correction that changes AR1 render/state semantics, stop and return to the recorded planning chat before implementing this packet.
- Work surface: Add `custodian/game/world/procgen/streaming/archive_resolve.gdshader`; make narrow render-payload/material changes in `procgen_reveal_presentation.gd`; bind exactly one shared `ShaderMaterial` to the existing `ArchiveResolveVeil`; update `proc_gen_map.tscn` only for explicit presentation tuning defaults if useful; add/register one focused AR2 shader/material smoke or extend the existing AR1 smoke only where ownership remains clear; update only directly stale presentation docs/validation ownership.
- Change: Preserve AR1 scheduling and state transitions byte-for-byte in behavior. Do not add a second queue, timer, phase scheduler, lifecycle observer, commit observer, or semantic registry. AR2 may extend only how an already-owned veil slot is encoded/rendered.
- Change: Enable MultiMesh custom data only if needed for deterministic render identity. Preferred payload is one write on slot assignment/reassignment, not a per-frame CPU rewrite: `INSTANCE_CUSTOM.r` = deterministic world-cell hash/jitter in [0,1]; `INSTANCE_CUSTOM.g` = reacquisition flag (0 first resolve, 1 reacquisition) if the landed AR1 seam can supply it without changing ownership; `INSTANCE_CUSTOM.b` reserved for later AR3 presentation class and must remain neutral in AR2; `INSTANCE_CUSTOM.a` reserved. If ARR1 or live code proves the reacquisition bit cannot be supplied cleanly without architectural bleed, leave it neutral and defer reacquisition styling to AR3. Existing instance `COLOR.a` remains the authoritative render-progress/veil-opacity channel. Never copy lifecycle state into shader-owned authority.
- Change: Add one shared CanvasItem shader/material. The shader receives the owner's pause-safe `presentation_time` through a uniform; do not use shader-global `TIME` for any pause-sensitive motion. The owner may update that one material uniform once per ordinary unpaused `advance()` call. No per-instance materials or per-cell uniform writes.
- Change: Implement the unresolved field as soot/graphite with low-frequency world-space variation derived from `MODEL_MATRIX`/world position plus deterministic instance identity. REQUESTED/READY coverage must remain visually opaque enough to hide authoritative commit timing. Variation must not reveal a 32 px cell grid, chunk boundary, checkerboard, or navigable detail behind unresolved cells.
- Change: During RESOLVING, replace AR1's simple linear alpha fade with an ordered pixel/dither breakup controlled by existing `COLOR.a` progress and coherent world-space variation. The shader may use a small Bayer-style threshold or equivalent deterministic ordered matrix plus low-frequency noise, but the result must read as material certainty resolving irregularly in connected local fronts, not a screen wipe or random sparkle field.
- Change: Add a thin intermittent aged-brass/archive-amber registration trace at the active dissolve boundary. It should be derived from the same deterministic threshold/progress rather than a second effect object. Allow sparse copper calibration ticks/hairlines only when they remain subordinate to world art. No neon, full-cell outline, permanent grid, particles, or floating mechanical motifs.
- Change: Add an optional <=1 px phase-misregistration treatment during the first portion of RESOLVING using veil/dither/registration sampling offsets only. Do **not** introduce a screen-texture/full-screen post-process or repaint/move underlying terrain just to achieve misregistration. If the batched veil cannot produce a convincing version without scene sampling, omit the effect in V1 rather than widening architecture.
- Change: Add presentation-only node controls consistent with the design lock: `registration_intensity`, `unresolved_haze_intensity`, `phase_misregistration_intensity`, and a reduced-effects toggle/profile. Reduced effects suppresses phase misregistration and substantially reduces registration intensity while leaving AR1 request/commit/order/timing and the unresolved safety cover intact. Existing `archive_resolve_enabled` remains the master effect switch; AR2 must not redefine its semantics.
- Change: Preserve AR1 slot overlap and z-layering. Hidden/released slots remain fully invisible. Settled terrain has no Archive Resolve shader object left over it, so final authored color/material/lighting is untouched.
- Change: Add compact render telemetry only if it materially improves validation: shared material count, shader enabled/reduced-effects flags, and optionally custom-data enabled. Do not add per-cell logs or per-frame debug spam. Existing AR1 counters remain the scheduling truth.
- Preserve: AR1 request-before-commit coverage; committed-only settlement; shared immediate/queued commit adapter; M3 PREPARE/COMMIT and M4 lifecycle semantics; M5 cache; M6 unload/residency; safety halo; deterministic frontier order; first-resolve/reacquisition identity; fixed slot-capacity/fail-open behavior; Region Frame/permanent exterior ownership; world generation, collision, navigation, biome/surface/route authority; actor/UI readability; existing terrain/art bytes; ordinary settled presentation.
- Non-goals: No semantic pre-echo or presentation-class styling; no spawn/ingress choreography; no final reacquisition timing change; no audio; no particles; no terrain scaling; no gameplay/discovery state; no new semantic registry; no full-screen screen-texture pipeline; no AR1 live-disable correction inside this packet; no tuning of chunk sizes/radii/streaming budgets.
- Acceptance: (1) AR1 scheduling snapshots/order/lifecycle fingerprints are identical with AR2 shader enabled vs diagnostic/simple rendering. (2) Exactly one shared ShaderMaterial serves the existing batched veil; no per-cell Nodes/Tweens/Timers/materials are created. (3) MultiMesh custom data, if enabled, is deterministic for the same world cell/reacquisition identity and is written only on slot assignment/reuse, not scanned/rebuilt full-frontier each frame. (4) Shader visual phase derives from existing AR1 progress + pause-safe owner time; pausing freezes every animated shader component and resume has no time jump. (5) REQUESTED/READY cells remain safely obscured; shader noise/dither never reveals uncommitted or not-yet-resolved authoritative pixels. (6) Resolve reads irregularly without visible 32 px checkerboard or 16x16 chunk rectangles. (7) Brass/amber registration is thin/intermittent and disappears completely at settlement. (8) Phase misregistration is <=1 px, presentation-only, optional/reduced-effects suppressible, and requires no screen-texture architecture. (9) Reduced-effects mode changes only presentation intensity; streaming/lifecycle/order/fingerprints remain exact. (10) Disabled mode retains the reviewed ARR1 semantics and has zero active visible veil treatment. (11) Slot overflow remains fail-open, bounded, telemetry-visible, and semantically inert. (12) Settled world pixels/materials/lighting are ordinary authored presentation with no persistent tint. (13) Human gameplay-scale review describes the effect as resolving/stabilizing/registering rather than chunks loading, squares popping, fog simply fading, a shader wipe, or a holographic grid.
- Validation: **Dependency gate first:** ARR1 must land clean/non-blocking. If ARR1 creates a correction that changes AR1 owner/render/state semantics, do not claim AR2; return to `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7` and refresh this packet again. Otherwise no second planning refresh is required. Add/register focused AR2 shader/material validation proving one shared material, optional custom-data contract, deterministic identity, pause-safe `presentation_time`, REQUESTED/READY concealment, settled transparency, reduced-effects/disabled parity, and no per-cell object/material growth. Re-run registered `procgen_reveal_presentation`, `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_distant_chunk_unload`, `procgen_runtime_health`, `procgen_candidate_materializer_parity`, `procgen_region_frame`, and S1 quick with the accepted fingerprint recorded. Inspect active/hidden instance counts and material identity directly instead of inferring from screenshots. Use changed-file validation, review-pairing/docs/manifest checks, and `git diff --check`.
- Visual review: After objective validation is green, capture the smallest gameplay-scale motion evidence that can answer continuity/readability. Prefer a short Moment Forge evidence run and compact keyframes/contact sheet; include one MP4 only if motion itself is necessary. Publish through `python3 custodian/tools/iteration/publish_review_artifacts.py --important` under workstream `procgen-archive-resolve-shader` following `VISUAL_REVIEW_HANDOFF.md`. Ask: (a) does the frontier read as continuous Archive resolution rather than chunk catch-up/square pop; (b) are graphite/soot and brass/amber accents subordinate to terrain and Operator readability; (c) does settled terrain return completely to ordinary world art; (d) is reduced-effects mode materially calmer without becoming a plain loading fade? Record the Dropbox manifest path and explicit user decision in the completion summary. The execution agent cannot self-approve aesthetics.
- Task overrides: `none`
- Deferred: AR3 owns bounded semantic pre-echo, presentation-class differentiation, stronger initial ingress/spawn resolve, and final shortened/weaker reacquisition choreography. Audio remains optional future polish.

## Dependency Gate — ARR1

This packet has been **refreshed in the recorded planning chat** against landed AR1. The old temporary planning-refresh gate is retired.

Do not implement until `review-procgen-archive-resolve-presentation-spine` lands clean/non-blocking.

If ARR1 passes without an AR1 correction that changes the owner/render/state contract:

1. update `Reviewed main` mechanically to the reviewed `main` SHA if desired;
2. set `Status: ready` and `Dispatch: auto`;
3. no additional ChatGPT/user planning refresh is required.

If ARR1 creates correction work or changes any assumption used above, leave this packet blocked and return to:

`https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`

with the ARR1 receipt + corrected AR1 summary before implementation.

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
- Refresh instruction: This packet was refreshed here against landed AR1. A further planning refresh is required only if ARR1/correction work changes the AR1 owner/render/state contract described above.

## Handoff

- Next workstream: `review-procgen-archive-resolve-shader`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none after clean/non-blocking ARR1; return here only if ARR1 correction changes AR1 assumptions`
- Next action: After ARR1 passes clean/non-blocking, mechanically promote this packet to ready/auto, implement AR2, complete objective validation and Dropbox human visual review, then let the paired fresh-context AR2 review claim automatically.
- Blockers or open questions: ARR1 is still required. Final shader aesthetics remain human-owned.
