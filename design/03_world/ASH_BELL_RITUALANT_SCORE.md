# Ash-Bell Forlorn Ritualant Score

This note records the current runtime routing for the four user-approved
Ritualant music cues. Ash-Bell continuity and the encounter specification remain
the authorities for story and simulation state. This score is scoped to the
authored Forlorn Ritualant Underground; it does not fulfill the separate SFX or
room-ambience requirement.

| Cue | Runtime route | Playback |
| --- | --- | --- |
| The Ninth Was Never Cast (gentler-attacks v2) | `CHAPEL_APPROACH` / `CHAPEL_GAMEPLAY_RELEASE` camera reveal | Loop |
| The Ninth Answers Nothing | committed `PROVOKED_RITUALANT` | Loop |
| Stilling Release | fresh `SET_STILLING_PIN` action or final WEST/NORTH/EAST anchor | One-shot |
| The Ninth Was Taken | fresh `SITE_DEFILED` | One-shot |

`RITUALANT_DISSOLVED` is nonlethal survival and fades the scoped score to
silence. Historical restore never replays a resolution one-shot. Leaving the
Underground releases its exclusive `MusicManager` claim and restores the prior
playlist only while the scene still owns that claim; a successor zone can take
authority without being overwritten by teardown.

The Ninth Answer receives a configurable, brief -8 dB music duck. Dialogue has
its own configurable duck. These controls affect the shared music player only;
combat SFX remain on their existing route. Human in-game level, intelligibility,
and loop-boundary audition remains pending and is not represented as completed.

Runtime ownership:

- `custodian/autoload/music_manager.gd`: exclusive scoped music lease,
  fade/duck, one-shot completion, and conditional restoration.
- `custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_music_director.gd`:
  scene event routing and fresh-transition suppression.
- `custodian/content/audio/music/ash_bell/audio_handoff_manifest.json`:
  source archives, hashes, codecs, durations, sample rate, loop semantics, and
  target state for all four byte-preserved runtime files.

See `custodian/tools/validation/ritualant_four_cue_music_smoke.gd` for the
machine-checked routing, route restore, one-shot, duck, and successor ownership
contract. Music assets remain independent from `ash-bell-audio-cues`, which
continues to track thread, silence, pin-drag, and room-bed SFX/ambience.

The exploration source is `forlorn_ritualant_the_ninth_was_never_cast_loop_v2.ogg`,
from `CUSTODIAN_Eight_Bells_Main_Scene_Gentler_Attacks_v2.zip`. Its SHA-256 and
source mix details are recorded in the runtime handoff manifest. This v2 cue
supersedes the prior exploration-loop source; the other three cue arrangements
are unchanged.
