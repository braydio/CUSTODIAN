# CUSTODIAN — MASTER DESIGN DOCTRINE

> **Status:** active project doctrine
> **Last reconciled:** 2026-08-19

This is the project-wide design doctrine for the active Godot era. Feature and
architecture specifications under `design/` refine it; they do not override its
core constraints without an explicit doctrine revision.

## Identity

CUSTODIAN is a Godot-based, 2.5D isometric tactical systems-defense game. The
player directly embodies one Operator inside a failing, recoverable machine:
they fight, explore, repair, fabricate, and make infrastructure decisions under
pressure. The experience is systemic and strategic without becoming a
squad-command RTS, a pure base-builder sandbox, or a stat-inflation treadmill.

Its central promise is reconstruction over extermination: information, routes,
infrastructure, and survival decisions must be visible and consequential.

## Runtime and authority

- Godot 4.x is the only active runtime authority.
- The active authority chain is `design/`, then `custodian/docs/ai_context/`,
  then `custodian/docs/`, then the live runtime and content under `custodian/`.
- Simulation state, fixed-step systems, command ingress, and snapshots are
  owned by the Godot runtime. Rendering and UI consume state; they do not own
  simulation rules.
- Determinism is a hard constraint for simulation-relevant combat, damage,
  power, logistics, fabrication, progression, and AI decisions.
- Presentation may interpolate or decorate state, but it must not silently
  become gameplay, collision, navigation, save, or simulation authority.

## Play model

- The Operator is the only directly controlled unit at launch.
- The Operator has melee, ranged, and utility capabilities. Utility expands
  systemic interaction such as repair, relay work, and fabrication rather than
  serving as a second damage channel.
- Tactical pause is a strategic tool: simulation progression freezes while the
  player may inspect and issue supported commands.
- Combat prioritizes readable commitment, spatial intent, authored weapon
  identity, and deterministic resolution. Physical projectiles and hitboxes
  remain the final combat authorities where their feature contracts require it.
- Infrastructure systems include power, logistics, fabrication, defenses,
  route/relay knowledge, and structural recovery. They interact visibly with
  the embodied play space.

## Campaign and progression

- Campaign knowledge and retained capabilities provide the long arc.
- Run-level choices can change available fabrication, sector improvements, and
  temporary tactical options.
- Upgrades should broaden options, operational reach, or systemic capability;
  raw-stat escalation is not the primary progression language.
- Assaults and aftermath form a readable cycle of reconnaissance, escalation,
  defense, damage/recovery, and renewed stabilization.

## Narrative and environmental storytelling

- **Write a causal history before clues.** For each substantial location, define its original function, the people and institutions involved, a specific action or failure, its material cost, and what survives for the player to discover or change. Do not rely on a contradiction to stand in for an unwritten event.
- Favor recognizable labor, maintenance, scarcity, adaptation, political decisions, ordinary lives, and physical consequences. Make each site's purpose and lived history distinct; not every ruin needs a continuity anomaly or a moral referendum.
- Let architecture, stripped components, repairs, routes, wear, ecology, and human arrangements carry discovery. Readouts, testimony, and documents should add grounded information or change a decision, not merely claim that two records disagree.
- **Do not default to incompatible logs, impossible timestamps, unexplained occupancy, dead machinery answering, or an authority system mysteriously recognizing the player.** Such devices are rare tools for an established, causally specified continuity event, not a repeatable site template.
- Ambiguity must follow from a defined event and a deliberate limit on what its witnesses could know. Give comprehensible answers to local questions when earned. Preserve the actual reserved cosmological mysteries without reproducing their structure in every side encounter.
- A discovery should change the player's understanding of someone, a place, or a practical choice. Avoid interchangeable “keep it running or shut it down” dilemmas and false binaries without identifiable costs and alternatives.
- Preserve **functional distinction between institutions**. While Twin Solaria remains canonical, Crown-class reconstruction and adjudication of lost routes belong there; smaller sites should not duplicate that role when their own engineering, inhabitants, logistics, and local emergencies offer stronger stories.

For content-generation details, see `design/03_world/PROCEDURAL_LORE_GENERATION.md` and `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md`. These are authoring standards, not retroactive changes to locked lore, reserved mysteries, or runtime ownership.

## Spatial and visual doctrine

- `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md` separates local biome, permanent region-frame/border/underlay presentation, and Archive Resolve. The first generated starting region selects the locked `ALPINE_PLATEAU` frame from `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; future generated regions may select different frames without changing the local-biome or Archive Resolve authorities.
- The game uses continuous local movement inside authored or generated spaces,
  with a fixed isometric presentation, readable collision, and stable camera
  ownership.
- Visual clarity beats spectacle: silhouettes, operational signals, and
  player-relevant state must remain readable at play distance.
- Art direction is stylized, industrial, restrained, and schematic. Avoid
  photorealism, visual noise, and effects that obscure tactical truth.

## Scope guardrails

CUSTODIAN is tactical, systemic, embodied, and strategic. It is not a
squad-based RTS at launch, an action shooter detached from systems, or a pure
wave-defense testbed. Continuous campaign-world play and recoverable systems
are the production direction.

## Development doctrine

- Build Godot-native systems and validate the smallest relevant contract.
- Keep pure state and system logic testable in isolation.
- Establish feel and player-readable feedback before adding deep feature layers.
- Preserve one clear owner for every behavior; use adapters only as
  non-authoritative bridges.
- Update active design and current-state documentation with implementation or
  authority changes.
- Historical pre-Godot material is archaeology only and never overrides this
  doctrine or active implementation authority.

Design changes that alter these principles require explicit review and an
update to this document.
