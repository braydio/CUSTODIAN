```text
design/20_features/in_progress/SOUNDTRACK_APPROACH_TRACK.md
```

That location matches the active design-doc convention from the project guidance, where Godot-native implementation specs live under `design/20_features/in_progress/`, while active runtime code lives under `custodian/`.

# CUSTODIAN Soundtrack — Approach Track

## Status

- Status: draft
- Owner: audio/design
- Track ID: `return_causeway_explore_01`
- Working title: **Return to Post**
- Area: **The Return Causeway**
- Runtime target: Godot 4.x
- Source DAW: Ableton Live Suite / Ableton Live Pro
- Initial format: 32-bar loop
- Export target: `.ogg` for runtime, `.wav` for source/master archive

---

## Purpose

The approach track establishes the first musical identity of **CUSTODIAN**.

It is not a heroic opening theme, combat cue, or cinematic trailer track. It is the first playable-world loop: the sound of the Custodian returning to a dead institutional civilization at the edge of cosmic collapse.

The track should communicate:

- ruined procedural authority
- dead infrastructure still carrying signal
- cosmic ocean / void pressure
- gothic institutional scale
- lonely recognition
- preservation rather than conquest

The player should feel that the world is not welcoming them. The world is identifying them.

Core emotional phrase:

> The world is dead, but one old system still recognizes you.

---

## Musical Identity

The track is built from a short institutional signal motif:

```text
D  Eb  A  Bb  A  Eb  D
```

Scale-degree interpretation:

```text
1  b2  5  b6  5  b2  1
```

The flat second gives the cue its ancient, wrong, procedural color. The return to D reinforces the theme of duty, looped mandate, and “return to post.”

This motif should be reused across future cues in corrupted, clarified, fragmented, or militarized forms.

Examples:

- exploration: sparse bell / terminal ping
- threat: sub pulse rhythm derived from motif spacing
- combat: motif fragmented into low ostinato
- hub: warmer reharmonized motif
- terminal discovery: motif rendered as clean signal tones followed by degraded machine response

---

## Tempo, Meter, and Length

```text
Tempo:          64 BPM
Time signature: 4/4
Loop length:    32 bars
Runtime length: 2:00
Render start:   1.1.1
Render length:  32.0.0
Loop endpoint:  33.1.1
```

At 64 BPM, 32 bars of 4/4 equals 128 beats, or exactly 120 seconds.

The cue should loop cleanly without a hard cadence. The loop restart should feel like the world breathing in again.

---

## Harmonic Structure

The harmonic bed uses slow chord changes, one chord every four bars.

Main loop:

```text
Bars 1–4:    Dm(add9)
Bars 5–8:    Ebmaj7
Bars 9–12:   Bb/D
Bars 13–16:  A5
Bars 17–20:  Dm(add9)
Bars 21–24:  Ebmaj7
Bars 25–28:  Bb/D
Bars 29–32:  A5
```

Suggested MIDI voicings:

```text
Dm(add9):   D2  F2  A2  E3
Ebmaj7:     Eb2 G2  Bb2 D3
Bb/D:       D2  F2  Bb2
A5:         A1  E2  A2
```

The pad should not pulse, arpeggiate, or become melodic in the first version. It should behave like harmonic architecture: slow, heavy, ruined, and nearly static.

---

## Track Layout

The Ableton project should use the following core tracks:

```text
01_DRONE_void_ocean
02_PAD_institution_ruin
03_SIGNAL_terminal_bell
04_SUB_threat_pulse
05_METAL_distant_impacts
06_NOISE_wind_static
```

Each track is designed so it can later become an adaptive stem in Godot.

---

## Track 01 — DRONE_void_ocean

### Function

The drone is the cosmic pressure underneath the approach.

It represents:

- void ocean
- impossible horizon
- dead space around the keep
- planetary / cosmic scale
- pressure rather than melody

### MIDI / Pitch

Use a long sustained drone:

```text
D1 held for 32 bars
A1 held for 32 bars
```

The A1 should be quieter than the D1.

### Sound Design

Recommended Ableton instruments:

- Wavetable
- Drift
- Analog
- Operator
- any dark low synth pad

Recommended processing:

```text
Auto Filter: low-pass, dark
Hybrid Reverb: large
Saturator: very light
Utility: mono-compatible low end
```

### Mix Target

```text
Starting fader: -18 dB
Usable range:   -22 dB to -16 dB
```

The drone should be felt more than consciously heard. If it sounds like a bass part, it is too loud or too active.

---

## Track 02 — PAD_institution_ruin

### Function

The pad is the sound of the ruined institution.

It represents:

- civic machinery
- dead command systems
- broken cathedral-like authority
- the keep as architecture
- historical weight

This is not the melody. It is the emotional stonework.

### MIDI

Use the harmonic structure listed above. One chord every four bars.

Do not retrigger every bar. Do not arpeggiate.

### Sound Design

Recommended sound sources:

- dark choir pad
- filtered organ-like synth
- brass pad
- degraded civic horn texture
- Wavetable/Analog/Drift pad

Suggested envelope:

```text
Attack:   1–4 seconds
Release:  4–8 seconds
Filter:   dark / low-passed
Reverb:   large
```

### Mix Target

```text
Starting fader: -16 dB
Usable range:   -20 dB to -14 dB
Busy level:     2/10
```

Mute test:

- If muting this track makes the cue feel thin and less tragic, it is working.
- If unmuting it makes the pad feel like the main musical part, it is too loud or too busy.

---

## Track 03 — SIGNAL_terminal_bell

### Function

The signal bell is the main identity of the track.

It represents:

- terminal recognition
- buried signal
- procedural memory
- “Return to post.”
- the Custodian being identified by the system

### Motif

```text
D5  Eb5  A5  Bb5  A5  Eb5  D5
```

Recommended first entrance:

```text
Bar 17 beat 1: D5
Bar 18 beat 1: Eb5
Bar 19 beat 1: A5
Bar 20 beat 1: Bb5
Bar 21 beat 1: A5
Bar 22 beat 1: Eb5
Bar 23 beat 1: D5
```

Let each note ring.

### Sound Design

Recommended Ableton instruments:

- Operator
- Collision
- Electric
- Wavetable glass pluck
- FM bell
- music-box-like signal tone

Recommended processing:

```text
Echo: subtle
Hybrid Reverb: large
Redux: very light
Auto Filter: slightly dark
```

### Mix Target

```text
Starting fader: -10 dB
Usable range:   -14 dB to -8 dB
```

The signal should be the clearest element, but not loud like a UI notification. It should feel distant, lonely, and procedural.

---

## Track 04 — SUB_threat_pulse

### Function

The sub pulse provides restrained danger.

It represents:

- something huge below the causeway
- the keep waking up
- pressure under the map
- enemy presence before enemy music begins

### Pattern

Sparse version:

```text
Bar 1
Bar 9
Bar 17
Bar 25
```

Slightly more active version:

```text
Bar 1
Bar 5
Bar 9
Bar 13
Bar 17
Bar 21
Bar 25
Bar 29
```

### Sound Design

Use:

- sine sub
- low tom
- dark kick without click
- processed impact
- low synth pulse

Avoid making this a beat.

### Mix Target

```text
Starting fader: -22 dB
Usable range:   -26 dB to -18 dB
```

If the pulse feels like drums, it is too loud or too frequent.

---

## Track 05 — METAL_distant_impacts

### Function

The metal impacts provide ruined scale.

They represent:

- distant machinery
- shifting keep structures
- broken gates
- collapsed institutional infrastructure
- massive things moving far away

### Placement

Suggested sparse hits:

```text
Bar 7
Bar 15
Bar 23
Bar 31
```

### Sound Design

Use:

- chain hit
- metal scrape
- reversed cymbal
- processed clang
- pitched-down debris impact
- far-off gate sound

Recommended processing:

```text
Pitch down
Huge reverb
Low dry level
Optional reverse swell
```

### Mix Target

```text
Starting fader: -24 dB
Usable range:   -28 dB to -18 dB
```

If the impacts jump out like horror stingers, they are too loud. They should create scale, not startle the player every loop.

---

## Track 06 — NOISE_wind_static

### Function

The noise layer glues the world together.

It represents:

- wind over the causeway
- cosmic sea air
- static from dead infrastructure
- space between musical events

### Source

Use:

- wind recording
- ocean noise
- filtered white/pink noise
- static bed
- room tone
- heavily processed field recording

### Automation

Suggested volume movement:

```text
Bars 1–8:    quiet
Bars 9–16:   slight rise
Bars 17–24:  quiet again
Bars 25–32:  slight swell into loop restart
```

### Mix Target

```text
Starting fader: -30 dB
Usable range:   -36 dB to -26 dB
```

If the listener hears obvious hiss, the noise is too loud.

---

## Arrangement

The first version should follow this simple 32-bar structure:

```text
Bars 1–8:
Drone + noise only.
The world is dead and vast.

Bars 9–16:
Pad enters.
The ruined institution becomes visible.

Bars 17–24:
Signal motif enters.
The Custodian detects recognition.

Bars 25–32:
Sub pulse and distant metal appear.
The keep feels dangerous and awake.
```

The loop should return to bar 1 without sounding like a song ending.

Avoid a final cadence. Avoid a cymbal crash at the end. Avoid resolving the emotional tension.

---

## Initial Mix Targets

Starting fader levels:

```text
01_DRONE_void_ocean        -18 dB
02_PAD_institution_ruin    -16 dB
03_SIGNAL_terminal_bell    -10 dB
04_SUB_threat_pulse        -22 dB
05_METAL_distant_impacts   -24 dB
06_NOISE_wind_static       -30 dB
Master                       0 dB
```

Master meter target during full playback:

```text
Peak target: -8 dB to -6 dB
Normalize:   Off
Limiter:     Not required for first draft
```

The first draft should not be mastered loud. It should leave headroom for later runtime balancing.

Mix priority:

```text
1. Signal bell must be readable.
2. Pad must make the scene feel tragic and architectural.
3. Drone must add weight without becoming a bassline.
4. Noise must be nearly invisible.
5. Sub and metal must suggest danger without becoming action music.
```

---

## Ableton Export Settings

Export the master WAV first.

```text
Render Track:    Master
Render Start:    1.1.1
Render Length:   32.0.0
Loop Endpoint:   33.1.1
Sample Rate:     48000
Bit Depth:       24
Normalize:       Off
Render as Loop:  On
File Type:       WAV
```

Source export filename:

```text
return_causeway_explore_01_full.wav
```

Suggested source export location:

```text
audio/source/ableton/exports/return_causeway_explore_01_full.wav
```

Runtime conversion target:

```text
custodian/content/audio/music/return_causeway/return_causeway_explore_01_full.ogg
```

Conversion command:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

mkdir -p custodian/content/audio/music/return_causeway

ffmpeg -y \
  -i audio/source/ableton/exports/return_causeway_explore_01_full.wav \
  -c:a libvorbis \
  -q:a 6 \
  custodian/content/audio/music/return_causeway/return_causeway_explore_01_full.ogg
```

---

## Godot Runtime Import

In Godot:

```text
FileSystem
→ content/audio/music/return_causeway/
→ select return_causeway_explore_01_full.ogg
→ Import tab
→ Loop: On
→ Reimport
```

Temporary test node:

```text
Node: AudioStreamPlayer
Name: ReturnCausewayMusic
Stream: res://content/audio/music/return_causeway/return_causeway_explore_01_full.ogg
Autoplay: On
Bus: Music
Volume dB: -8
```

If the `Music` bus does not exist yet, create it in the Audio panel or temporarily route the player to `Master`.

---

## Runtime Stem Plan

The first implementation can use a single full-loop `.ogg`.

Later, split the track into stems:

```text
return_causeway_drone_01.ogg
return_causeway_pad_01.ogg
return_causeway_signal_01.ogg
return_causeway_threat_01.ogg
return_causeway_noise_01.ogg
```

Potential adaptive behavior:

```text
Exploration baseline:
Drone + noise + low pad

Terminal proximity:
Fade in signal motif stem

Enemy proximity:
Fade in threat pulse stem

Gate / keep reveal:
Raise pad and metal impact stem

Safe return point:
Reduce sub threat, clarify signal motif
```

Do not implement adaptive music until the static loop works emotionally.

---

## Acceptance Criteria

The first draft is acceptable when:

- The loop runs for exactly 32 bars / 2 minutes at 64 BPM.
- The loop restarts cleanly without an obvious pop, silence gap, or hard ending.
- The bell motif is readable.
- The pad is slow, sustained, and not rhythmically busy.
- The drone creates low pressure without overwhelming the mix.
- The track feels like CUSTODIAN, not generic dark fantasy or generic sci-fi ambience.
- The player can walk the Return Causeway with the cue repeating without fatigue.
- The cue leaves enough headroom for SFX and later runtime mixing.

---

## What Not To Do

Avoid:

- heroic brass melody
- busy percussion
- trailer risers
- EDM pulse
- bright fantasy choir
- obvious horror stingers every loop
- full combat drums
- happy major resolution
- too much melodic activity in the pad
- over-mastering the first export

The approach track should feel enormous, procedural, lonely, and unresolved.

---

## Future Cue Derivatives

After this cue works, derive additional music from the same motif:

```text
terminal_awaken_stinger_01
sundered_keep_interior_01
threat_nearby_layer_01
combat_grunt_wave_01
return_mooring_safe_01
```

All of these should reuse or mutate the `D Eb A Bb A Eb D` identity so the soundtrack feels cohesive.

---

## Documentation Drift / Follow-up

This document assumes the runtime audio convention:

```text
custodian/content/audio/music/
```

If the repository already contains a different audio folder convention, use the existing convention and update this document accordingly.

Recommended follow-up once audio enters runtime:

```text
custodian/docs/ai_context/CURRENT_STATE.md
```

Add a short note that the first soundtrack cue has been defined, exported, and imported into the Return Causeway scene.

One drift issue to flag: I’m assuming `custodian/content/audio/music/` because it fits the active `custodian/` runtime structure, but I did not verify the latest GitHub tree in this turn. The uploaded project guidance says GitHub may be fresher than Drive, so Codex should check existing audio paths before committing this exact folder convention.
