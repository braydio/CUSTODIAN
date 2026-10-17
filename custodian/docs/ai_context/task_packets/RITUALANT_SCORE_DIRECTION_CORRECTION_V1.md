# RITUALANT — SCORE DIRECTION CORRECTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ritualant-score-direction-correction-v1`
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: none
- Locks: ash-bell-music, ritualant-underground-audio
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime
- Paired review workstream: review-ritualant-score-direction-correction-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: real-time audio transitions, global playlist leasing, restoration, and race cancellation need independent state/runtime falsification
- Reviewed main: 2f69588a5825eb3212f1b7f0ac0e4782e2384fee
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: none
- Goal: Make the four already-landed Ritualant cues start, change, and finish at the correct scene beats with coherent musical transitions, robust dialogue ducking, terminal quiet, and correct zone handoff.
- Completion boundary: Implement and land the explicit seven-beat cue/aftermath policy below, nonzero-duration real-time transition tests, bounded docs correction, and paired independent review. Do not stop at an audit or require another composition approval.
- Current measured state: Current `MusicManager` has one `AudioStreamPlayer`, a shared `_transition_tween`/`_transition_generation` for both music switching and ducking, and fade-out-then-fade-in rather than overlapping crossfade. `ForlornRitualantMusicDirector._on_scoped_track_finished()` restarts the exploration loop after both terminal one-shots. Scene music is first claimed on chapel reveal, permitting a prior area playlist to remain audible through cavern arrival. The site requests `stilling_release` at the beginning of `set_stilling_pin()` before its preliminary dialogue, and on the third valid anchor. Existing smoke explicitly expects the post-one-shot exploration restart and sets `transition_seconds = 0` on its cue-switch checks, so it does not test duck/switch cancellation with real fades. Four imported OGGs, source/provenance manifests, scene ownership, and the original implementation/review are already landed.
- Evidence: `custodian/autoload/music_manager.gd`; `custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_music_director.gd`; `custodian/game/world/events/ash_bell/forlorn_ritualant_site.gd`; `custodian/tools/validation/ritualant_four_cue_music_smoke.gd`; `design/03_world/ASH_BELL_RITUALANT_SCORE.md`; archived `ASH_BELL_RITUALANT_FOUR_CUE_SCORE_INTEGRATION.md` and its passed paired review.
- Task-specific authority: Live `MusicManager` owns exclusive music playback/zone snapshot, the scene-local director owns when to request each cue, `ForlornRitualantSite` and `AshBellEventState` own encounter truth, `design/03_world/ASH_BELL_RITUALANT_SCORE.md` records the music policy. Approved future Highland Station migration is in `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_DESIGN_LOCK.md`, not a current-runtime trigger.
- Work surface: `custodian/autoload/music_manager.gd`; `custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_music_director.gd`; minimal cue-emission seam in `custodian/game/world/events/ash_bell/forlorn_ritualant_site.gd`; `custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.gd` only for proven arrival/departure ownership needs; focused music smoke and validation manifest; active score design/current-state docs where behavior changes.
- Change:
  1. Underground arrival: acquire exclusive scoped music ownership when this authored level becomes active and fade the previous area playlist to silence over about 0.8 s. Do **not** start the full exploration cue in the lift/service cavern. Keep cavern acoustics/ambience independent; no new ambience asset is required in this slice. Avoid seizing successor-zone ownership after teardown.
  2. Exploration: at first committed `CHAPEL_APPROACH` or `CHAPEL_GAMEPLAY_RELEASE` camera reveal play approved `the_ninth_was_never_cast_loop_v2.ogg` once and continuously loop with approximately 1.8–2.0 s entrance from silence. Never restart solely because of camera-profile chatter, dialogue, or resolved re-entry. Duck spoken dialogue separately, retaining intelligible voice.
  3. Combat: on the committed `PROVOKED_RITUALANT` transition **after dialogue releases control**, overlap exploration and `the_ninth_answers_nothing_combat_loop_v2.ogg` for approximately 0.6–0.7 s during the 0.8 s rise. Combat loops until terminal resolution; no warning, pressure bump or cancelled dialogue starts it. `Ninth Answer` retains a bounded approximately -8 dB, 0.7 s music duck without muting combat SFX. Ducking must never cancel a queued switch.
  4. Peaceful stabilization: a fresh successful explicit Stilling Pin/receiver-commit interaction or the **third genuinely valid** WEST/NORTH/EAST anchor starts `stilling_release_v1.ogg` as a one-shot. Align its entrance with the physical resolution action, not the onset of a preliminary dialogue that can continue for an arbitrary duration. Use about 0.4–0.6 s changeover from exploration or 0.3–0.5 s from combat. Never replay for restored/saved terminal state. When Highland Receiver Key migration eventually lands, move the source to a semantic fresh successful receiver-commit event; do not pre-implement unlanded key mechanics or create two conflicting event authorities.
  5. Violent outcome: fresh `SITE_DEFILED` during `death_violent` starts `the_ninth_was_taken_hostile_resolution_v1.ogg` **once**, never on mere provocation or dissolve; replace combat sharply in about 0.1–0.25 s so drums do not continue under death. Avoid needless silence gaps and double triggering.
  6. Nonviolent survival: `RITUALANT_DISSOLVED` without completed stabilization fades combat to environmental quiet in roughly 0.7 s, with neither violent nor peaceful one-shot. For either terminal one-shot, **after it finishes leave scene music silent** rather than restart pre-resolution exploration. Keep the room's existing independent ambience and mechanical quiet; do not fabricate a fifth composition.
  7. Departure/recovery: begin a ~0.6–1.0 s fade at lift departure or next-zone handoff, never hold traversal until a ~31–39 s one-shot completes. On scene exit conditionally release exclusive music and resume prior playlist only if no successor has taken ownership; restore saved position/level where legitimate, not stale or unrelated scene. Saved terminal re-entry is quiet, never replays one-shots; hostile state re-entry may reestablish combat correctly; failed exit rollback restores the appropriate current music state.
  8. Audio architecture: keep one authoritative `MusicManager`, but provide independently gain-controlled overlapping deck/player playback for real crossfades and a **separate shared scoped duck gain/controller**. Duck activity, dialogue activation, and changed duck target cannot invalidate transition generation or abort pending playback; rapid consecutive cues/preemption cannot resurrect outdated tracks; stopping/releases destroy stale delayed callbacks; volume and base playlist snapshots survive zone ownership changes. Prefer existing bus/volume authority; add no per-scene MusicManager clone.
  9. Tune approximate timing values through explicit director/resource configuration, not unrelated gameplay constants. Update only `ASH_BELL_RITUALANT_SCORE.md`/directly stale current runtime notes, including that prior smoke's post-one-shot exploration assertion is obsolete.
- Preserve: All four approved original OGG **bytes** including Gentler Attacks v2; their hashes/Asset V2 intake, authoring provenance and manifest; no additional music composition, no sprite/room art, no gameplay state change, no ritual dialogue rewrite, no spawn/geometry/AI/attack retime. Existing separate `ash-bell-audio-cues` SFX/room-bed registry remains unfinished and is not marked fulfilled. The legacy passive fountain stabilization defect has its **own existing runtime-truth workstream**; do not block audio correction awaiting it and do not change its gameplay authority here. No duplicate music players persisting after release.
- Non-goals: No source remix, fifth cue, global audio overhaul outside scoped playback, broad scene redesign, Highland Receiver Key implementation, passive fountain bug patch, north egress, shader approval, or replacing the existing Godot music manager with unrelated systems.
- Acceptance: Normal arrival has no previous-zone score after entry fade; first chapel approach begins exactly one exploration loop; dialogue during each nonzero crossfade does not cancel destination cue; no silence discontinuity from artificial single-player fade-then-cut; combat enters on committed hostility and stops cleanly on each distinct outcome; two terminal one-shots play once with no exploration replay; survival resolves to quiet; multiple rapidly competing resolution/exit signals cannot resurrect music; saved terminal state never replays; successor zone survives old owner teardown; stable volume/duck handling without effect on SFX; focused and changed-file validation green.
- Validation: Extend `custodian/tools/validation/ritualant_four_cue_music_smoke.gd` with **real nonzero fades and timed frames** for (a) lift/cavern silence, reveal once, repeated profile, (b) dialogue activated in middle of exploration→combat and peaceful cue fades, (c) actual overlapping decks and target volume, (d) final one-shot completion → scene silence, (e) survival quiet vs kill/anchor/pin outcomes, (f) interrupted/preempted cue transitions, (g) exit, failed exit rollback, successor-zone ownership, restore/scene teardown. Keep deterministic simulation/resource assertions where practical; add smallest human audiovisual sanity capture only if timing audibly ambiguous. Run `python3 custodian/tools/validation/run_validation.py --test ritualant_four_cue_music --json`, affected existing Ash-Bell scene/completion smoke, `python3 custodian/tools/validation/run_validation.py --changed --json`, `git diff --check`, and standard scoped lifecycle checks. Record subjective in-game audition as pending if not performed, without blocking objective implementation.
- Task overrides: none
- Deferred: Human in-game listening/tuning; separate scene design migration and SFX commissioning; Awakening AP0 recommendations are tracked independently and are not part of this packet.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `<fill at closeout>`
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
- Next workstream: review-ritualant-score-direction-correction-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Summary backlink: Include this exact Authoring chat URL in all durable implementation/review/correction/closeout summaries.
- Refresh reason: none
- Next action: Implement all numbered changes, validate, commit, land to origin/main, and launch the dependency-gated fresh-context review; do not stop at more planning.
- Blockers or open questions: none for implementation. Human listening remains a post-implementation qualitative check.
