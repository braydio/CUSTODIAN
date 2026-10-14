# ASH-BELL RITUALANT FOUR-CUE SCORE INTEGRATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-ritualant-four-cue-score-integration`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `ash-bell-music, ritualant-underground-audio`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, asset-pipeline`
- Paired review workstream: `review-ash-bell-ritualant-four-cue-score-integration`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `93f99b6088a9aa4bf354bb739a42bee770db6948`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Goal: Integrate the four approved Forlorn Ritualant music cues into the authored Ash-Bell Underground with state-correct, exclusive playback and safe restoration.
- Completion boundary: All four supplied OGGs are present at their canonical runtime paths with audio provenance; a scoped encounter director transitions exploration, combat, peaceful resolution, hostile resolution, survival aftermath, restore, and exit without changing the global playlist; focused deterministic tests prove trigger and ownership invariants; implementation lands on `origin/main`.
- Current measured state: The four-cue runtime/director implementation is complete. The exploration candidate is the approved Gentler Attacks v2 OGG at its canonical audio inbox and runtime paths; the other three cues remain byte-identical. The existing SFX/room-bed requirement `ash-bell-audio-cues` remains `needed` and is not fulfilled by music. Focused music/runtime checks and complete changed-file validation pass. Human in-game audition remains a separate post-implementation quality review, not an implementation acceptance gate.
- Evidence: `design/03_world/THE_ASH-BELL_CONTINUITY.md`; `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`; `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_DESIGN_LOCK.md`; `custodian/autoload/music_manager.gd`; authored Underground scene/script; Ritualant site/NPC/event-state scripts; required-assets registry; the three original cue handoffs, `~/Downloads/CUSTODIAN_Eight_Bells_Main_Scene_Gentler_Attacks_v2.zip` (SHA-256 `b7e8e37eb058e5a116966a288389afe0691c633e80eedbb727f7b307148e0f90`), and this implementation-directed audit.
- Task-specific authority: Active Ash-Bell continuity and Forlorn Ritualant encounter/level design own story and transition meaning. `MusicManager` owns global playlist policy. The authored Underground wrapper owns scoped lifecycle. Audio handoff manifests own codec, sample rate, duration, loop points, gain and provenance. The already-active `ash-bell-ritualant-runtime-truth-closeout` owns passive fountain stabilization; do not modify that correction or its test assertions here.
- Work surface: Four runtime OGGs and one checked audio handoff manifest under the existing specialized audio intake; `MusicManager`; a focused Underground music director/controller and minimal state-event seams; focused audio/encounter validation; required-assets registry, validation manifest, current state and audio documentation.
- Change:
  1. Import the four current cue OGGs without remixing or re-encoding; verify archive hashes, codec, stereo 48 kHz rate and declared durations. The approved Gentler Attacks v2 archive supersedes only The Ninth Was Never Cast exploration-loop source; keep its exact OGG bytes and leave the other three cues unchanged. Record loop/one-shot semantics, state target, source archive, and SHA-256 in one documented audio-specific handoff manifest. Do not create visual Asset V2 metadata.
  2. Extend `MusicManager` with an exclusive, owner-scoped cue claim supporting loop, one-shot, fade/duck, cancellation and conditional restoration. Existing Causeway playlist ordering, non-loop behavior and global authority remain unchanged. No second permanent AudioStreamPlayer or per-encounter global override.
  3. Add a small Underground-scoped director. Start the exploration loop at the authored ChapelApproach reveal, once per scene claim. Transition only when hostile state actually commits, not when dialogue is merely interrupted or combat is requested. The Ninth Answer gets a conservative configurable duck/hush which cannot suppress combat SFX.
  4. Start Stilling Release at the explicit peaceful stagecraft/anchor transition for both Set Stilling Pin and WEST/NORTH/EAST anchor completion. Do not wait for the terminal completion signal for the cue onset. Ensure one-shot is fresh-transition-only and never replayed by save/restore/re-entry.
  5. On `SITE_DEFILED`, stop/crossfade combat and play The Ninth Was Taken exactly once. `RITUALANT_DISSOLVED` is nonlethal survival: fade combat to quiet aftermath without selecting either resolution cue. Leaving during fades/one-shots cancels scoped audio and restores prior policy only if this level still owns the claim.
  6. Preserve the fountain-correction workstream's ownership. Add only nonconflicting audio signals/edges; coordinate the precise peaceful transition hook with the active correction branch before editing the same site file. Audio tests must distinguish explicit fresh route actions from passive residence and must not turn the known passive-stabilization defect into audio authority.
  7. Add an independent music requirement/fulfillment record. Keep the existing SFX/room-bed row `needed`. Update current-state/audio notes without claiming subjective in-game sound quality was reviewed.
- Preserve: Ash-Bell canon (Orra gave the Ninth Answer; no original ninth cast bell); encounter resolution state authority, dialogue timing, combat mechanics, route/scene ownership, Causeway playlist semantics, SFX and room-bed requirements, authored cue mixes.
- Non-goals: No composition/mastering changes, fifth cue, SFX/ambience fulfillment, global soundtrack rewrite, encounter redesign, passive fountain correction, route/procgen work, or art changes.
- Acceptance: All four runtime artifacts match the supplied approved bytes and metadata. Exploration loop activates only at the named reveal; combat loop only after hostile commitment; Stilling Release only on a fresh explicit peaceful route; hostile one-shot only on fresh `SITE_DEFILED`; survival selects quiet aftermath; no one-shot restarts, restore/re-entry duplicates, successor-zone clobber, parallel music player or global playlist regression. Ninth Answer hush remains bounded and does not suppress critical SFX. Focused import, director, save/restore, early-exit, cancellation and existing playlist tests pass. Required-assets truth remains granular. Human in-game audition is recorded as a post-implementation quality review and is not a prerequisite to wiring or landing.
- Validation: Verify supplied ZIP integrity and OGG SHA-256/ffprobe metadata; Godot editor import; focused music director and existing music/scene/route/encounter smokes; test all state/restore/exit cases in the acceptance; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; registry/managed view checks; `git diff --check`. Do not self-certify subjective mix or loudness perception; record human in-game audition as pending if unavailable.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; it must not edit the reviewed implementation or unrelated files.`
- Deferred: Human in-game listening and final sound-level/synchronization quality review after implementation; separate Ash-Bell SFX/room-bed production; any later music composition changes.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Audio provenance and requirement disposition: All four runtime cue files match the specialized audio handoff manifest and their inbox copies. The Gentler Attacks v2 exploration OGG matches SHA-256 `51a64027a61ea8db5704e08036bfeb6babdb4c54c130edbaa000db325788f6aa`; its source ZIP SHA-256 is `b7e8e37eb058e5a116966a288389afe0691c633e80eedbb727f7b307148e0f90`. The three other cues are unchanged. The score requirement is fulfilled; separate SFX/room-bed requirement remains needed.
- Evidence: ZIP integrity and member checksums pass; `ffprobe` reports Ogg Vorbis, stereo, 48 kHz and 185.806271 seconds. Godot 4.7.2 project import, `ritualant_four_cue_music`, `asset_requirements_smoke.py`, `forlorn_ritualant_mapper_semantics`, and `forlorn_ritualant_runtime` pass. Full `run_validation.py --changed --base origin/main --json` report at `/tmp/ritualant-score-final-validation.json` has complete coverage: 46 passed, 0 failed, 0 skipped. `git diff --check` passes.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: After the geometry dimensions were corrected on main, the completion smoke still sampled x offsets ±68 that overlapped the current front wings.
- Root cause / contributing factors: The smoke treated obstructed edge positions as walkable even though the revised collision geometry leaves a narrower clear boarding corridor.
- Prevention / pipeline improvement: Keep geometry-size assertions and sample runtime clearance only at positions inside the authored open corridor; no collision or traversal behavior was changed.
- Tooling / docs drift discovered: none
- Follow-up: `fixed-in-scope`

## Next Handoff

- Next workstream: `review-ash-bell-ritualant-four-cue-score-integration`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: `none`
- Next action: Run the paired fresh-context independent review after implementation lands and archives.
- Blockers or open questions: Human in-game audio quality review remains post-implementation; do not describe it as completed until performed.

## Independent Review

### Review Receipt: review-ash-bell-ritualant-four-cue-score-integration
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-ash-bell-ritualant-four-cue-score-integration`
- Review target workstream: `ash-bell-ritualant-four-cue-score-integration`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `3bcbbcd788e008612c0d3d653a1474f8bde54b17`
- Reviewed implementation commit: `3bcbbcd788e008612c0d3d653a1474f8bde54b17`
