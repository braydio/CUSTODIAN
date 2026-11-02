# PRIMARY SECONDARY ATTACK MODEL TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Align operator attack mode routing to the current model: three attack modes (`unarmed`, `melee`, `ranged`) and two attack types per mode (`primary`, `secondary`).

## Outcome

Light attack is no longer selected by live input resources. Unarmed and melee map primary/secondary to fast/heavy; ranged maps primary/secondary to unfocused/focused fire intent names while preserving current shot behavior until focused-shot tuning is implemented.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime files: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/operator/*_definition.tres`
- Active design reference: `design/features/implementation/UNARMED_TOGGLE.md`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`

## Work Surface

- Files expected to change: operator attack routing, operator weapon definitions, AI context docs.
- Files read but not changed: operator animation state scripts and current combat docs.
- Out of scope: authored focused ranged shot behavior, deletion of legacy light animation assets.

## Constraints

- Determinism concerns: input intent resolution remains explicit and profile-driven.
- Simulation/UI boundary concerns: HUD text should describe primary/secondary modes, not deprecated light attack.
- Asset requirements: no new animation assets required for this routing change.
- Compatibility concerns: legacy `melee_light` remains as a fallback code path only until old state docs/assets are cleaned up.

## Implementation Plan

1. Set melee weapon primary intent to `melee_fast` and secondary to `melee_heavy`.
2. Add explicit ranged focused/unfocused intent aliases and map both to the current firing behavior.
3. Update default fallback intent/range preview to prefer fast over light.
4. Update docs/context and validate.

## Acceptance

- Runtime behavior: melee primary starts fast attack; melee secondary starts heavy attack.
- Runtime behavior: unarmed primary remains fast; unarmed secondary remains heavy.
- Runtime behavior: ranged primary and secondary both still fire, with distinct intent names ready for focused/unfocused behavior.
- Documentation: current state reflects the two-type, three-mode model.
- Automated/headless validation: operator script parse and main scene headless boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: melee primary now routes to `melee_fast`, melee secondary to `melee_heavy`; ranged primary/secondary are named `ranged_unfocused_fire` and `ranged_focused_fire`; operator intent matching accepts the new ranged names; HUD debug prompt now says primary/secondary instead of generic attack.
- Validated: `godot --headless --check-only --script res://game/actors/operator/operator.gd`; `godot --headless --check-only --script res://game/ui/hud/ui.gd`; `godot --headless --quit`.
- Deferred: focused ranged fire still uses the current ranged shot implementation until focused-shot mechanics are designed/tuned; legacy light attack state/assets remain for compatibility but are no longer selected by live attack resources.

## Next Steps

- Next action: live-test M1 and Shift+M1 in unarmed, melee, and ranged modes.
- Best starting files: `operator.gd`, `fallen_star_katana_definition.tres`, `carbine_rifle_mk1_definition.tres`.
- Required context: primary/secondary input fix already maps M1 to primary and Shift+M1 to secondary.
- Validation to run: `cd custodian && godot --headless --check-only --script res://game/actors/operator/operator.gd`; `cd custodian && godot --headless --quit`.
- Blockers or open questions: focused ranged behavior still needs design/tuning.
