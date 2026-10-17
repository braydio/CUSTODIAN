# Ritualant — Dialogue, Idle and Ambient Audit / Rewrite Contract

**Status:** approved narrative/behavior direction; runtime dialogue remains unchanged pending authored rewrite.
**Workstream:** ritualant-highland-station-redesign
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
**Authority:** `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_DESIGN_LOCK.md`
**Existing text:** `custodian/content/dialogue/ash_bell/forlorn_ritualant_dialogue.json`
**Existing presenter:** `custodian/game/world/events/ash_bell/forlorn_ritualant_dialogue_presenter.gd`
**Existing actor:** `custodian/game/world/events/ash_bell/forlorn_ritualant_npc.gd`

## Core character voice

The Ritualant is a displaced, distressed former person, trying to finish something recognizable. He is not an engineer explaining dual realities to the player, nor a fantasy prophet. Confusion appears in procedural corrections, interrupted counting, remembered responsibilities and very ordinary loss. He may vaguely recall the receiver's empty seat; his rite's importance to him is independent of knowing the machine's full function. Preserve grief and the original Orra moral ambiguity. Avoid portentous metaphors and dialogue whose main function is to supply a quest hint.

### Existing content: preserve/review/rewrite

| Existing node or content | Disposition |
| --- | --- |
| `first_interaction` | Preserve the correction "bell is wrong / basin is wrong"; review blocking duration and the old assumption that the basin is the final socket |
| `ask_bell`, `ask_thread`, `ask_orra` | Preserve the historical Ninth Answer, custody practice and Orra's impossible choice. Do not imply the Highland station is IX |
| `inspect_fountain` and fountain pressure lines | Preserve the physical wrong basin vs remembered Dry Fountain distinction; don't convert the basin into a receiver machine |
| `core_synopsis_pin_waiting`, `core_synopsis_pin_taken` | **Rewrite** after Receiver Key implementation: refer to something out of place / receiver seat, no Stilling Pin |
| `take_stilling_pin_response`, `set_stilling_pin_pre`, `set_stilling_pin_resolve` | Rename/replace on runtime migration, preserving final psychological cadence and one-shot ownership |
| `stabilized_exit` | Preserve brevity and "Enough." Only edit if staging makes it contradictory |
| `attack_response`, `cut_thread_response`, attack barks | Preserve moral cost, no lore dump; check that hostility cannot consume same input that advances dialogue |
| `ritualant_root` menu | Migrate toward non-obstructive, free-roaming dialogue choices without hijacking movement axes |

The player-facing **Receiver Key** definition should start with a normal object and a normal job. Proposed text, subject to in-game fit:

> A removable iron-and-ceramic key from a Meridian station receiver. It locks the return contacts in their isolated position. The grip is polished where the user's thumb would rest.

No explanation of its cosmology, no promise of redemption, and no "anchors silence" line.

## Beat and discoverability

- Lift/service tunnel: optional environmental placard/locker record introduces isolation gear before meeting the Ritualant.
- Key alcove: inspect then collect; the pickup is not in chapel and does not require finishing three dialogue topics.
- Receiver gallery: receiver missing keyed contact has readable shape/collar and compatible socket; safe, optional examine prompt before recovery.
- Chapel: Ritualant's hand movements and attention point toward the empty seat. One brief contextual response if key is present, not a forced recitation.
- Installation: short physical turn and machinery response; the Ritualant stops, a quiet ordinary closing line, then existing dissolution and terminal state.
- Players can infer that something is wrong even if they choose hostile action or skip side inspectables. Avoid giant instructional text panels.

## Free-roaming dialogue acceptance (separate implementation)

Movement (WASD / left stick) remains possible during ordinary dialogue. Dedicated menu-choice inputs must not double as `move_up`/`move_down`; choose input context owns E/confirm and Esc/cancel/B safely without firing world interact or dodge the same frame. The presenter's screen-space area must not swallow the chapel; preserve target legibility and subtitles. Long interruptible lore doesn't immobilize the Operator except a separately justified authored event; preserve safety/cancel distance.

## Ritualant idle audit / animation intent

Current kneel/idle still works as the baseline, but loop transitions should become less repetitive and more human:

- `count_on_fingers`: occasional low-frequency small hand gesture, interruptible.
- `adjust_white_thread`: nervous correction of a real tied strand, no magical rope.
- `glance_to_receiver`: gaze/head turn to machinery, sometimes when player carries the key.
- `freeze_on_overlap`: static held existing frame when spatial echo occurs; no new art necessarily.
- `settle_before_release`: a short single authored motion before dissolve, not another boss defeat flourish.

No idle plays during damage/windup/death, out of camera relevance, while actor lock is engaged, or during terminal restoration. State and signals remain owned by NPC/site; separate presenter only observes. Proposed frame-contract candidates are in the companion asset brief; no image has been produced yet.

## Ambient actors / apparition policy

Use at most one station-duty echo near a workstation, selectively seen during an overlap event, and one chapel/procession beat (prefer reuse of existing `GhostProcession`). No permanent extra living quest NPC, combat mob, speech tree or dense walking ghost population in this scope. Any character-shaped echo must be visibly noninteractive and cannot mislead the player into thinking it can be rescued. Keep the Ritualant singular and emotionally legible.

## Review criteria

A first-time player should understand **this is a worked-on installation, the Ritualant is lost, the item belongs in a machine, and placing it changes the space** without receiving an explicit lecture on reciprocal continuity. A return visit shouldn't replay the story or epilogue. User approval is required for final dialogue tone, idle presentation and ambient population.
