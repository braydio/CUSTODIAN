# Forlorn Ritualant — Highland Station Design Lock

**Status:** approved design authority; implementation pending
**Workstream:** ritualant-highland-station-redesign
**Design decision:** 2026-10-12
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
**Related:** `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`, `design/03_world/THE_ASH-BELL_CONTINUITY.md`, `design/05_levels/FORLORN_RITUALANT_UNDERGROUND_MIGRATION.md`, `design/05_levels/ASH_BELL_BRIDGED_FALLS_APPROACH.md`, `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`.

## Authority and implementation boundary

This document locks the **intended redesign**, not a claim that it is live. The active Godot route, scene, interaction flags, old Stilling Pin item, and three terminal outcomes remain operational until implementation and independently reviewed migration. Where historical encounter/approach descriptions conflict with this approved direction, this document governs **future Highland Station content**; the older files still report existing behavior. Do not rewrite archived packets or mark unimplemented art/features complete.

The Highland cavern is in the mountain region **before the Alpine Highlands and Bridged Falls** approach. The Meridian Lower Quarter and **Station IX remain across Bridged Falls**, not inside the Ritualant cavern. This is not a transplanted Lower Quarter annex. The exact station number is reserved as one of **I–VIII**; never call it IX or allocate a numeral without checking the nine-station network. Its historical Answer was already issued. Orra's late Ninth Answer ended the **original** Open Interval; the Operator cannot cause or repeat that historic closure.

## Internal truth: physical and psychological mechanisms

A portion of an Ash-Bell Meridian Office mountain synchronization station, its material, and the Forlorn Ritualant were displaced/overlaid into the active Highland caverns during the Open Interval. A surviving local receiver assembly is stuck with an exposed reciprocal return connection and a reference mismatch. The original regional coupling ended; this is a bounded **residual local fault** associated with displaced hardware and reciprocal instability. It neither certifies a counterpart's identity nor proves an active passage-sized gateway.

The Ritualant is a displaced person who has ceased trying to reconcile his coherent memories with incompatible surroundings. He has built an improvised funerary/counting rite from remembered work, custody practice, and grief. The rite is **not** a new magical power or a reliable technical procedure. He fixates on an out-of-place station part because its correct seat is remembered or sensed as important. His mental fixation and the local physical defect share a cause, rather than his mind creating or sustaining the universe.

**Receiver Key** is approved as the replacement key item and in-world name. It is a durable keyed, insulated component with **two coupled actions on proper seating and turning**: it terminates/islands the exposed return contact **and** seats the receiver against its local reference alignment. This is not merely a metal cover or a generic magical artifact. The key is found **outside the chapel arena** in a plausible maintenance/recovery location within the approach. Its receiving socket is on real receiver machinery, **not automatically in the Dry Fountain basin**.

Returning it to the correct seat allows the residual local configuration to settle. The Ritualant, faced with an accomplished action that finally makes sense to him, stops his panicked repetition and peacefully passes on. The northern obstruction clears after the terminal encounter outcome, granting onward movement to the **generated Alpine Highlands and then Bridged Falls**, as governed by existing route/egress design. Never collapse those two regions or move Meridian across the mountains.

### Spatial provenance: distinguish four layers

A layer being **original to the facility** does not automatically mean it originated in the active continuity; the facility itself was displaced or overlapped. Asset placement and environmental clues must respect this distinction.

| Layer | Provenance | Expected reads |
| --- | --- | --- |
| H0 | Active-Highland geology / pre-existing access context, subject to route evidence | Mountain walls, natural voids, external ingress; any existing lift segment must be classified from evidence, not guessed |
| H1 | Ash-Bell station-original construction, present in displaced Highland site | Receiver support gallery, frame, primary conduit, switchgear, anchorage, duty/work spaces, industrial service supports |
| H2 | Cross-continuity architectural overlap, **not original to station** | Chapel shape, displaced thresholds, remembered fountain silhouette, conflicting gate/archway and registration |
| H3 | The Ritualant's later arrangement of real materials | White Thread custody objects repurposed in a rite, black banners, ashes, hand-tied memorials, improvised counting arrangements |

The physical wrong basin remains real, distinct from the **Dry Fountain** memorial remembered from Ash-Bell. Its apparition, black-water state and contradiction survive the redesign. Ordinary chapel bell-frame imagery is **not** a literal Ninth Bell.

## Authored route, play, and pacing

Preserve the current authored-level scene, 112×128 at 32px, extant collision/nav ownership, camera profiles, lift and south return. Reuse floor/underlay and 37-state environment where still suitable. Do not lengthen the corridor merely to lengthen playtime. Target **13–20 minutes** for an investigative first visit, not a required timed gate; returns should be fast.

| Sequence | Proposed content | Interaction/evidence | Provenance |
| --- | --- | --- | --- |
| 1. Lift landing | Worked stone, shaft dock, fixtures, power/conduit traces, station access identity | Inspect service plaque; introduce abandoned facility | H0/H1 as proved |
| 2. Service tunnel | Reinforcements, drainage, cable run, rail/service works and small side recess | A recognizable maintenance clue; first controllable local overlay | H1 with sparse H2 |
| 3. Key recovery alcove | Collapsed inspection bay or abandoned tool locker, **off the critical chapel floor** | Inspect and acquire Receiver Key; optional evidence explaining how/why it was removed | H1 with H2 displacement |
| 4. Receiver support / Isolation Gallery | Strong visual hero assembly on station-original load-bearing frame; ceramic contacts, insulated guide/shaft and an empty keyed receiver seat | Discover missing socket independently of dialogue; verify that component fits | H1, locally malfunctioning |
| 5. Chapel overlap threshold | Station bones visibly continue under alien chapel architecture | Short geometry echo, discontinuity; no blocking exposition | H1 + H2 |
| 6. Ritualant chapel | Wrong basin, mundane chapel bell, thread, banners, Ritualant; receiver apparatus visible/physically connected to gallery | Free-roaming dialogue, tactile objects, key installation, alternate hostility | H1–H3 |
| 7. Resolved north throat | Local receiver goes quiet; Ritualant departs; obstruction visibly recedes | Safe, persisted egress to Highlands, with reverse traversal | H0/H1/H2 resolved |

The route topology may place the key alcove before the receiver gallery or allow a short return after discovering the empty socket. Preferred game-read is **see empty seat → recall/find keyed part → return it**; avoid excessive backtracking. At least one clear visual cue must link the item and socket without requiring all Bell/Thread/Orra topics. Existing world White Thread Knot ingress should remain compatible; do not add a second invented universal gate.

## Outcome and gameplay contracts

- **SITE_STABILIZED / peaceful key installation:** explicit receiver contact + reference restoration; non-obstructive final dialogue, local flicker ceases, Ritualant stops his rite and dissolves; egress becomes available. The score's Stilling Release cue belongs to a fresh successful resolution, not reload.
- **RITUALANT_DISSOLVED / nonviolent alternate:** preserve its distinct current terminal identity; design/implementation must decide what physically calms the site when the key is not installed. Do not silently make this identical to the keyed peaceful action.
- **SITE_DEFILED / violent outcome:** killing/defiling is **not** a repair of the receiver. The Operator must not be progression-softlocked; any north opening must be justified as the Ritualant obstruction lifting while local instability may remain and presentation/music differ.
- Merely provoking hostility is **not** the violent terminal outcome. The named Thread, attack and pressure mechanics retain one runtime authority until explicitly migrated.
- All terminal transitions, key pickup/install state, local receiver alignment, one-shot audio/VFX and egress must restore safely after route snapshot/unload. Never replay on re-entry.
- Do not implement a second Lattice simulation or a separate continuity physics authority inside the UI/VFX. Encounter state owns gameplay; receiver state has one explicit owner; presentation observes it.
- The historical Ninth Answer stays accepted. No Station IX receiver prompt/logic is cloned; Highland repair is small and tactile, Station IX isolation remains its three-step operation.

## Presentation and dual-reality effect

Favor local **depth/geometry double-vision** rather than perpetual global distortion: 1–3px scene-relative duplicate offsets, brief occluder/parallax disagreement, localized value splitting and displaced threshold ghosts, with a rarer stronger keyed restoration pulse. Timing should be intermittent, deterministic/seeded where helpful for tests, and never hide traversable collision truth. Avoid hard full-screen strobing, persistent chromatic fringes, aggressive camera shake, or flashing dialogue text. Provide a reduced-flicker mode that substitutes slow alpha/opacity shifts.

Reuse existing `ForlornRitualantShaderFX`, authored camera-zone and hazard presenters where possible. One bounded additional **localized overlap presenter** can observe station/encounter state; never add competing mutation authorities. Strongest pre-resolution overlap is at receiver/church seam, not every part of the cave. The grounded service tunnel starts nearly normal.

## Ritualant dialogue and activity

The character speaks from incomplete memory and compulsive duty, not omniscient continuity theory. Preserve the good Bell / Thread / Orra lines, Orra's moral contradiction, and the wrong basin. Remove future instructional references to **Pin in basin**; he may say that the **key belongs there** without diagnosing both electrical and continuity functions. Item prose should describe recognizable material/use, then one concrete unsettling detail; avoid abstractions such as "anchoring silence" or counterfeit epic names. Dialogue must be free-roaming: WASD/left stick movement and combat ownership cannot share choice navigation; dedicated dialogue focus/confirm/cancel semantics are required.

Behavior palette: current kneel/idle is a valid baseline, but add sparse, interruptible counting on fingers, thread adjustment, gaze toward receiver seat, a freeze when geometry flickers, and resting posture before release. No constant pantomime, telepathy, teleporting prop, or exposition animation. Source sprite runtime currently uses 128×128 Ritualant cells; additional animations require specific source/stem/frame-count contracts and Asset V2 before implementation.

Ambient population is optional and restrained: **one** station-duty echo on service route and **at most one** chapel/procession silhouette event, presentation-only unless later separately authorized. No extra quest vendors, boss adds, combat patrols, or talking explanatory ghosts. Existing apparition/ghost procession may satisfy the chapel slot.

## Dependencies and remaining decisions

- The **Receiver Key** label, off-chapel location, dual-action function, station-original receiver structure, non-original chapel, rare dual-reality VFX, ritualant psychological foundation, and user-facing ambiguity are **approved**.
- Deliberately reserve the precise station number I–VIII, how much of the lift belongs to H0/H1, precise machine anatomy, exact key-room coordinates and extra NPC identities until a mapper/art review proves them. These do **not** block this design lock.
- Honor `ritualant-north-egress-and-chapel-vista` and generated Highlands/Bridged Falls dependencies; do not author a competing route or assume the north exit is already playable.
- Existing music cue integration is separate: exploration loop, peaceful one-shot, proposed hostile terminal cue.
- Design-first implementation sequence: 1) drift inventory/reconciliation; 2) mapper-backed provenance/blockout and off-chapel key; 3) receiver mechanics/state migration; 4) source-art Asset V2 intake; 5) localized VFX; 6) dialogue + idle / ambient presentation; 7) route/outcome gamefeel and independent review.
