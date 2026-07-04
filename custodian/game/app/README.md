# App

- Belongs here: startup mode selection, runtime entrypoint coordination, boot-time routing between Home, contract sandbox, and debug previews.
- Does not belong here: procgen construction, combat simulation, UI page rendering, actor behavior.
- Current migration status: scaffold only; active boot still lives in `project.godot` and scene startup.
- Current source of truth: `custodian/project.godot`, `custodian/scenes/game.tscn`, `custodian/scenes/home_custodian_begin.tscn`.
