# Awakening First Return Score Integration

“A Command Still Speaking” is the user-approved Awakening exploration score. Its authoritative WAV source remains on the user's host; the repository stores only the Ogg Vorbis runtime encode and its provenance record at `custodian/content/audio/music/awakening/audio_handoff_manifest.json`.

`AwakeningMusicDirector` claims the existing `MusicManager` scoped lease when the production Awakening scene enters and starts cue `awakening_01_command_still_speaking` once. It loops through sections 01–10, including the optional Chapel of Late Service. Cue selection metadata (context `awakening`, role `exploration`) and runtime gain (-2.5 dB initially) stay in the Awakening adapter; deck playback, crossfades, ducking and ownership remain in `MusicManager`.

On a successful Awakening-to-Hub handoff, the source scene releases its lease with an 0.8-second fade and no playlist restoration. Failed handoff leaves the source scene and its lease intact. Release is idempotent while a fade is pending, and a successor music owner invalidates its stale completion callback. Ordinary teardown keeps the existing snapshot restoration behavior. The default restoration policy for all other scoped music users is unchanged.

The source mix is not normalized or otherwise processed. User artistic approval, technical runtime integration, and listening approval are separate states: technical checks cover resource loading and lifecycle behavior, while in-game listening and loop-seam audition remain pending.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9bc56-9e1c-83ea-8ff9-285be4092acb
