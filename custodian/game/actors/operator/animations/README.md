# Operator Animation Identity

Operator gameplay actions and animation presentation are separate authorities.
`combat/operator_action_controller.gd` arbitrates attack, guard, equip/sheathe,
damage reaction and death. Locomotion remains derived from fixed-tick movement
facts and is never an action.

Presentation uses three focused authorities:

- `operator_animation_selector.gd` resolves canonical semantic identities.
- `presentation/operator_animation_player.gd` plays an already-resolved
  identity without choosing gameplay or animation semantics.
- `presentation/operator_presentation_controller.gd` translates semantic
  animation requests into body-owner plans and routes them through the selector,
  player and `OperatorBodyPresenter`.

`OperatorBodyPresentationPlan` remains mechanical: owner, body layers and
owner-scoped overlays. It carries no action, input, timing or animation fields.
The Operator owns combat timing and decides when action presentation begins and
ends; rendered frames never become combat authority.

Use the focused Operator validation recipes in
`custodian/docs/ai_context/VALIDATION_RECIPES.md` when changing action or
presentation behavior. The former reflection-driven state machine and its
per-action state scripts have been removed.
