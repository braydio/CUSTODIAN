# Severance Unarrival Lore Revision

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-17
- Created: 2026-05-17
- Last updated: 2026-05-17

## Task

Revise active documentation so "lack of shared context" is no longer treated as the root cause of the Severance. Lock The Unarrival as the internal metaphysical cause and reframe information collapse as the civilization-facing symptom of a cosmic provenance wound.

## Outcome

Active lore, Hub/campaign, faction, procedural lore, and AI-context docs consistently distinguish:

- Root cause: supernatural/cosmic provenance wound caused by The Unarrival.
- Observable symptom: information collapse, contradictory archives, fragmented history, and unstable shared context.
- Gameplay expression: knowledge recovery as provenance stabilization across object, origin, witness, time, use, and meaning.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`, `design/03_architecture/HUB_SYSTEM_META_PROGRESSION.md`, `design/03_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`, `design/03_content/PROCEDURAL_LORE_GENERATION.md`, `design/03_content/FACTION_PROFILES.md`
- Active runtime/docs files: `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/CONTEXT.md`, `custodian/docs/ai_context/FILE_INDEX.md`, `custodian/docs/ai_context/task_packets/README.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: active design/content docs, AI context docs, Ash-Bell runtime/content names, and asset trackers.
- Files or folders expected to be read but not changed: local routing docs and validation recipes.
- Out-of-scope areas: runtime GDScript, production assets, save data, and legacy Python-era docs.

## Constraints

- Determinism concerns: none; doc-only change.
- Simulation/UI boundary concerns: none; mechanical implications should remain design-level.
- Asset requirements: no new asset requests; existing Unarrived Saint assets remain tracked separately.
- Compatibility or migration concerns: avoid overwriting existing knowledge/provenance mechanics; demote old shared-context language to symptom-level framing.
- Clarifying questions or assumptions: The Unarrival is locked as the internal name/cause, while player-facing content should still reveal it indirectly through anomalies and competing interpretations.

## Implementation Plan

1. Update the content canon doc with the new Severance hierarchy, Custodian relationship, tone rule, and anomaly grammar.
2. Align Hub, campaign, procedural lore, and faction docs with provenance stabilization and Unarrival-derived anomalies.
3. Rename Bell-Kneeler references to Forlorn-Ritualant across the active Ash-Bell docs, runtime/content files, smoke validation, and asset trackers.
4. Update AI context docs and packet indexes, then validate with markdown grep for stale root-cause wording.

## Acceptance

- Runtime behavior: unchanged.
- Documentation: active docs distinguish root cause, observable symptom, and gameplay expression.
- Path/reference validation: changed docs are discoverable from AI context indexes.
- Manual validation: grep confirms no active doc still frames shared-context loss as the sole root cause.
- Automated/headless validation: not applicable for doc-only change.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: Locked The Unarrival/provenance wound as the internal Severance root cause in `GAME_PROTOCOLS_AND_WORLD_LORE.md`; reframed shared context collapse as an observable symptom; aligned Hub, Campaign, Procedural Lore, Choir of Provenance, Ash-Bell continuity, AI context, and file indexes; renamed Bell-Kneeler to Forlorn-Ritualant across active docs, runtime scene/scripts, dialogue JSON, special-room JSON, smoke validation, and required asset trackers.
- Validated: stale Bell-Kneeler grep returned no matches; stale shared-context-root-cause grep only found explicit deprecation/context lines; JSON syntax checks passed for Forlorn-Ritualant dialogue and special-room files; required asset tracker copies are byte-identical; targeted Godot script checks passed for touched Ash-Bell scripts; Ash-Bell smoke script passed with renamed scene; `godot --headless --path custodian --quit` passed with existing leak/resource warnings; LFS-neutral `git diff --check` passed for the touched files.
- Deferred: no runtime behavior redesign beyond the rename; production Ash-Bell art/audio and procgen special-room insertion remain in the existing follow-up lane.

## Next Steps

- Next action: Use the new canon wording in future lore, Hub, campaign, procedural generation, and terminal-copy work.
- Best starting files: `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`, `design/03_content/PROCEDURAL_LORE_GENERATION.md`, `custodian/docs/ai_context/CURRENT_STATE.md`.
- Required context: user-provided lore revision in current session.
- Validation to run: for future runtime edits, repeat `godot --headless --path custodian --script res://tools/validation/ash_bell_scene_smoke.gd` and `godot --headless --path custodian --quit`.
- Blockers or open questions: none.
