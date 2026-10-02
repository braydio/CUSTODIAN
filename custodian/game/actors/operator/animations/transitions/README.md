# Operator Action Arbitration

`combat/operator_action_controller.gd` owns only mutually exclusive action
arbitration and lifecycle signals. It has no sprite, animation, input or combat
domain references. Attack timing, guard behavior, equipment transactions,
damage reactions and death presentation remain with their existing owners.

Locomotion is orthogonal: idle, walk and sprint presentation derives from
movement facts, with no locomotion action state. The controller rejects unknown
action names and keeps death terminal until the Operator explicitly resets it
for respawn.
