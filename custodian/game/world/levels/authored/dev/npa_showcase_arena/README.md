# NPA Showcase Arena

Generated through the canonical authored-level scaffold. Production geometry, markers and labeled actor sockets live in `npa_showcase_arena.tscn` and `npa_showcase_arena.gd`; the standalone wrapper owns the one Operator and gameplay systems. The scene-local debug overlay is read-only for live actor state and routes button actions through actor and DroneManager owners. It only works when this registered dev scene is active. Existing Marine, Savage, and Vaultwing scenes can be spawned here; Broken Warrant and Escort Frame M-7 remain `NOT LANDED` and unavailable until their packets land. Reset removes only scenario actors. The overlay does not consume Operator or DroneManager gameplay keys and does not add actors to campaign or wave spawning.

The Broken Warrant actor is available through the development console's
`spawn_broken_warrant` command for focused playtests. Arena actor sockets remain
empty until a later integration slice owns their scenario lifecycle; the actor
uses provisional Grunt donor visuals pending its own reviewed Asset V2 family
and source art.
