# Streaming Reveal Presentation V1 — Archive Resolve

**Project:** CUSTODIAN  
**Status:** Design locked; AR1/ARR1 complete; AR2 implementation landed with renderer-recovery pending; AR3 refresh-gated  
**Last updated:** 2026-10-03  
**Runtime authority:** presentation only  
**Parent streaming contract:** `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`

## Purpose

Turn procgen streaming reveal from a visible loading cadence into a deliberate
CUSTODIAN world-presentation signature.

The player should not perceive chunk logistics. The world should read as if it
already exists beyond the Operator but is being locally **resolved, attested,
and stabilized into visible certainty** as access advances.

The locked presentation name is **Archive Resolve**.

This document governs the reveal's visual/presentation behavior. It does not
replace seeded procgen, chunk lifecycle, PREPARE/COMMIT scheduling, collision,
navigation, residency, or world semantics.

## Core Design Lock

> **Chunks are logistics. They must never be choreography.**

The runtime may continue using tile chunks for request, cache, lifecycle,
residency, and unload/reload. No visible animation may reveal chunk boundaries
or use a whole chunk as its presentation unit.

Visible resolution is continuous in world space and driven by tile-level
availability plus a separate presentation frontier.

The effect communicates:

> the world is not being created by the player; unstable access to an existing
> place is being resolved into an attested state.

This matches current Lattice/Archive doctrine: Archive systems stabilize and
resolve damaged reality rather than manufacturing disposable worlds.

## Visual Identity — Archive Resolve

Archive Resolve uses five restrained ingredients:

1. **Graphite unresolved veil**
   - unrevealed/queued space reads as soot-dark graphite haze rather than empty
     black map;
   - low-frequency world-space variation prevents flat rectangles;
   - no checkerboard and no visible 32 px grid.

2. **Evidence echo**
   - immediately ahead of full materialization, a barely visible structural
     hint may appear: terrain edge, wall/cliff contour, hardstand seam, route
     axis, or major landmark silhouette;
   - evidence precedes certainty;
   - this stage is subtle enough that exact content is not yet readable.

3. **Registration trace**
   - a thin intermittent amber/brass acquisition edge rides the resolving
     boundary;
   - occasional one-pixel calibration ticks or short hairline registration
     marks are allowed;
   - no permanent holographic grid.

4. **Pixel-material resolution**
   - terrain does not simply alpha-fade in;
   - an opaque/dark veil breaks away through deterministic world-space dither
     and coherent noise, exposing progressively more of the actual pixel art;
   - the visual read should suggest 2-tone -> 4-tone -> full material
     decompression without repainting or replacing the underlying art;
   - a very brief 1 px phase misregistration may collapse into alignment during
     the first half of the resolve.

5. **Settlement**
   - full authored color/material becomes ordinary world presentation;
   - foliage/props may finish a fraction later than ground/structure;
   - all registration marks and special treatment disappear completely after
     settlement.

The final visible world must look normal. Archive Resolve is a transition, not
a persistent sci-fi overlay.

## Steampunk Veneer

The effect carries a **hint** of CUSTODIAN steampunk instrumentation, never a
costume layer.

Allowed accents:

- warm aged-brass / archive-amber hairlines;
- restrained copper registration ticks;
- faint soot/pressure haze in the unresolved field;
- tiny analog-calibration cadence in major registration events;
- occasional aggregate relay/pressure character in later audio work.

Avoid:

- floating gears;
- exposed clockwork pasted over terrain;
- bright hazard striping;
- neon cyber-grid language;
- particle storms;
- repeated per-tile mechanical icons;
- anything that competes with world art or combat readability.

The steampunk contribution should feel like old precision machinery performing
a reality survey, not like themed decoration.

## Presentation Phases

A newly committed local patch resolves through:

| Phase | Approx. local timing | Visual role |
| --- | ---: | --- |
| Echo | -120 to 0 ms | faint contour / unresolved evidence |
| Registration | -30 to +70 ms | amber/brass acquisition edge, tiny calibration marks |
| Resolve | 0 to +160 ms | graphite veil breaks through deterministic dither/noise; brief phase alignment |
| Dressing settlement | +90 to +210 ms | walls/macros/foliage/props complete their local read |
| Settled | by ~300 ms | no special effect remains |

These are authoring defaults, not simulation timing authority. Final tuning is
visual/game-feel work and may vary by accessibility/performance profile.

Do not create one Tween per cell.

## Reveal Composition

### Ground first, dressing second

Use a small visual offset between presentation classes:

1. floor / surface material;
2. road / hardstand / terrain edge;
3. wall / cliff / macro presentation;
4. foliage / props / dressing.

The delay is deliberately short. The player should read coherent resolution,
not watch the map assemble object-by-object.

### Connected micro-fronts, not square pops

The visible frontier should resolve in small irregular connected patches,
roughly 3–12 cells at a time, produced by:

- player/world distance;
- current deterministic reveal priority;
- coherent world-space noise;
- local adjacency;
- bounded semantic priority.

Do not scale individual terrain squares from zero. Do not animate 16×16 chunk
rectangles. Do not expose a rasterized board-game cadence.

### Semantic pre-echo

Important reads may announce themselves slightly early without gaining gameplay
authority:

- Meridian infrastructure: restrained geometric registration line;
- cliffs/walls: faint silhouette/height contour;
- ruined road: interrupted route vector;
- major/hero landmark: silhouette before full material resolution.

This is presentation priority only. It does not change generation,
walkability, collision, navigation, discovery state, or quest knowledge.

## Three-Radius Runtime Model

Archive Resolve deliberately separates data readiness from visible resolution.

### 1. Streaming / request radius

Existing chunk/tile streaming prepares work ahead of the player.

This radius is logistical and invisible.

### 2. Gameplay-ready radius

Committed floor/wall/collision/navigation state exists far enough ahead that
the player is never walking into unresolved authority.

### 3. Visual resolution frontier

The visible Archive Resolve front trails inside the gameplay-ready buffer and
advances at a controlled presentation rate.

A short load stall should therefore cause the unresolved field to hold, not a
whole rectangular chunk to suddenly appear.

The Operator must maintain a resolved safety halo. If movement approaches the
frontier, presentation accelerates/force-settles nearby already-committed cells;
it never reveals cells that have not committed.

## Spawn Presentation

Initial contract entry may use a slightly stronger one-time resolve:

1. spawn/ingress safety pocket is immediately gameplay-ready;
2. local unresolved field surrounds it;
3. a subdued registration impulse leaves the ingress;
4. nearby route/structure echoes appear;
5. ground resolves outward;
6. the effect transitions into ordinary player-driven irregular frontier
   behavior.

Target duration: roughly 1–1.5 seconds, tuned for playability.

This is not a loading screen and must not delay player control after the safety
pocket is valid.

## Reload / Reacquisition

A chunk that was previously resolved and later unloaded for residency reasons
must not replay the full first-contact ritual.

Use a shorter **reacquisition** treatment:

- little or no evidence-echo stage;
- reduced registration intensity;
- shorter resolve duration;
- same deterministic final presentation.

The world is being reacquired, not discovered for the first time.

Presentation memory may be generation/session-scoped only; it is not save-game
semantic authority.

## Runtime Ownership Contract

Create a focused presentation owner, recommended:

```text
custodian/game/world/procgen/streaming/
  procgen_reveal_presentation.gd
  archive_resolve.gdshader
```

Final names may follow the live post-refactor seam, but ownership is fixed.

`ProcGenRevealPresentation` owns only:

- requested/eligible presentation cells;
- committed-but-not-yet-settled presentation cells;
- deterministic presentation start ordering/jitter;
- local reveal phase;
- unresolved veil instances;
- Archive Resolve shader/material parameters;
- reveal/reacquisition visual telemetry.

It does **not** own:

- chunk state;
- PREPARE/COMMIT queue;
- generated floor/wall semantics;
- collision;
- navigation;
- blocker state;
- residency policy;
- biome/surface authority;
- route authority;
- macro/landmark placement authority;
- save state.

## Recommended V1 Render Technique

Use one pooled/batched presentation primitive, not one Node/Tween per cell.

Preferred first implementation:

- one `MultiMeshInstance2D` or equivalent batched CanvasItem owner for the
  currently unresolved/resolving frontier;
- one quad per active frontier cell, slightly overlapping the 32 px semantic
  cell so seams never reveal a checkerboard;
- per-instance custom data for deterministic jitter, phase/start time, semantic
  presentation class, and first-resolve vs reacquire;
- one shared CanvasItem shader using world-space coherent noise + ordered dither;
- graphite/soot veil covers committed pixels until the visual scheduler resolves
  them;
- amber/brass registration edge is derived in shader from local reveal phase;
- custom presentation time is supplied by the owner so pause can freeze the
  effect; do not rely on uncontrolled shader `TIME` for gameplay pause parity.

V1 should avoid a full-screen screen-texture post-process unless the batched
veil prototype cannot achieve the locked visual. Sampling the scene behind the
effect is optional future polish, not an architecture requirement.

## Live Streaming Integration Contract

Archive Resolve consumes existing tile-level seams.

### Request / queued

When a tile enters the streaming request set, presentation may create/retain an
opaque unresolved veil record for that tile.

This hides later commit timing and prevents chunk availability from becoming
visible choreography.

### PREPARE

PREPARE remains pure streaming work. Archive Resolve may observe readiness for
telemetry/echo scheduling but must not cause authoritative mutation.

### COMMIT

Immediately after a tile successfully commits:

- mark that tile presentation-ready;
- do not necessarily expose it immediately;
- the presentation scheduler chooses when the veil resolves, subject to safety
  halo and committed-only rules.

Chunk lifecycle COMMIT remains authoritative streaming truth. Visual settlement
is not chunk lifecycle state.

### Unload

When reviewed residency policy unloads disposable presentation:

- remove/hide Archive Resolve settled/frontier presentation state as needed;
- retain only minimal generation/session reacquisition memory;
- re-request/recommit uses the shortened reacquisition path.

Archive Resolve must never prevent or authorize an unload.

## Determinism

For a fixed:

- generation seed;
- committed tile sequence;
- player trajectory sampled at the same fixed ticks;
- presentation configuration;

the selected patch order, jitter, phase class, and semantic pre-echo choices
must be deterministic.

The shader may use deterministic world-position hash/noise. It may not use
unseeded per-frame randomness.

Presentation timing may interpolate in render time, but ordering and phase
identity must remain reproducible.

## Pause Contract

While the game is paused:

- streaming COMMIT remains frozen by existing M3 authority;
- Archive Resolve visual phase also freezes;
- already-visible settled world stays visible;
- no unresolved patch silently finishes behind the pause menu.

Use the presentation owner's pausable clock/uniform rather than shader-global
time.

## Performance Contract

Archive Resolve exists to hide streaming mechanics, not create a new source of
stutter.

V1 targets:

- no per-cell Nodes;
- no per-cell Tweens;
- shared material(s);
- bounded active frontier instances only;
- stable reusable buffers;
- no full-map texture rebuild per frame;
- no navigation/collision rebuild caused by presentation phase;
- no extra semantic query scan over the entire map each frame.

Telemetry should expose aggregate active frontier count, queued-ready count,
forced-safety settles, average/max resolve age, and reacquisition count.

## Accessibility / Debug

Provide presentation-only controls for development and accessibility:

- effect enabled;
- reveal duration multiplier;
- registration intensity;
- unresolved haze intensity;
- phase-misregistration intensity;
- debug frontier/phase visualization.

A reduced-effects profile may shorten/disable phase misregistration and amber
registration while preserving the underlying streaming behavior.

Disabling Archive Resolve must reveal committed world normally without changing
streaming semantics.

## Prohibited Implementations

Do not:

- animate whole chunks;
- scale terrain cells from zero;
- use chunk state as the visible effect phase;
- block gameplay on presentation completion;
- make fog collision/navigation authority;
- let unresolved appearance hide a player-reachable committed hazard without a
  resolved safety halo;
- reveal uncommitted cells to make the animation look smoother;
- add per-cell Nodes/Tweens;
- permanently tint settled world;
- turn Archive Resolve into a bright cyberpunk grid;
- make visual presentation responsible for procedural generation truth.

## Implementation Dependency

The streaming-residency prerequisite is satisfied: M6/MR6, M6C1/MR6R1 and RF1/RFR1 have landed/reviewed their relevant request/commit/unload and permanent Region Frame seams. AR1/ARR1 are complete. AR2 implementation is landed on main, but its original closeout lacked the mandatory graphical-renderer and explicit human visual evidence; `procgen-archive-resolve-shader-recovery-1` now closes that gate after the ingress-spawn hotfix review, and the AR2 paired review depends on the recovery. AR3 must not start until that review passes and AR3 is refreshed in `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`. The later procgen decomplexification series must preserve Archive Resolve as a presentation consumer rather than absorbing it into generation/state authorities.

## Recommended Implementation Slices

### AR1 — Reveal Presentation Spine

- add `ProcGenRevealPresentation`;
- wire reset/request/commit/unload observations;
- batched unresolved veil;
- deterministic presentation queue;
- resolved safety halo;
- first-resolve vs reacquire identity;
- no elaborate shader polish yet.

Acceptance: chunk boundaries become visually unobservable in a diagnostic flat
veil mode, streaming semantics/fingerprints unchanged.

### AR2 — Archive Resolve Shader

- graphite/soot unresolved field;
- coherent world-space irregular dissolve;
- ordered pixel dither;
- amber/brass registration edge;
- brief 1 px phase misregistration;
- semantic presentation-class offsets;
- pause-safe presentation clock.

Acceptance: gameplay-scale capture reads as a continuous resolving frontier,
not chunk catch-up or per-cell pop.

### AR3 — Semantic Echo + Spawn Resolve

- semantic pre-echo for limited high-value classes;
- one-time ingress/spawn resolve;
- reduced reacquisition treatment;
- aggregate optional audio hook if desired later.

Acceptance: major spatial information reads early without becoming gameplay
authority or visual clutter.

## Visual Acceptance

Final V1 requires human-owned gameplay-scale review.

A successful result should make an observer describe the world as:

- resolving;
- stabilizing;
- registering;
- emerging through an Archive process.

It should **not** be described as:

- chunks loading;
- squares popping;
- fog simply fading;
- a shader wiping across the screen;
- a holographic grid filling in.

The final effect should be memorable during movement and nearly invisible once
settled.
