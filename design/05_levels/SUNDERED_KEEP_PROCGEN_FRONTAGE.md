# Sundered Keep Procgen Frontage

- **Status:** active production authority; layering review required
- **Owner:** generated Sundered Keep frontage and distant reveal
- **Runtime:** `custodian/` Godot 4.x
- **Last updated:** 2026-08-09

## Production Boundary

The generated frontage, its collision-safe terrain authority, and its distant
reveal presentation are production content. The presentation is subordinate to
generated gameplay geometry and may never cover the playable frontage.

Production traversal is:

```text
generated campaign terrain
-> generated playable Sundered Keep frontage and distant reveal
-> terminal ingress at the generated gate anchor
-> ordinary fade
-> authored Sundered Keep Vista Approach
-> ordinary fade
-> Sundered Keep Front Gate
```

## Production Procgen Ownership

Procgen owns:

- playable generated frontage floor, cliff/blocker, navigation, prop, and enemy
  placement authority;
- the generated shore/cliff boundary;
- the distant ocean/storm/fortress reveal presentation;
- registered terminal ingress placement at `sundered_keep_frontage.gate_anchor`.

Generated floor cells are the single traversal source. `ProcGenTilemap` derives
a merged, non-destructible cardinal-edge collision frontier from the final
authoritative floor set after playability remediation. Navigation consumes that
same floor set. Stochastic cliff/wall tiles remain visual/destructible dressing
and are never the security perimeter between walkable terrain and void/ocean.

The frontage grammar emits `vista_commit_cells`,
`mandatory_separator_cells`, and `terminal_apron_cells`. All generated paths
may vary below the commit line, but removing the intended commit passage must
disconnect the world-side frontage entry from `gate_anchor`. The terminal apron
must contain the gate anchor.

The ingress uses `procgen_landmark_terminal` with the
`sundered_keep_frontage` landmark data key.
It starts the `sundered_keep` route with the `production` profile. Production
continues to enter `sundered_keep_vista_approach`; it must not bypass that
authored level by selecting the direct-keep debug edge.

The procgen vista owns presentation only. `VistaPresentationRoot` has absolute
negative depth, contains no collision or navigation descendants, and clips its
ocean/storm/fortress imagery to the exterior side of the generated gate
boundary. It must not cover generated playable-floor bounds. Gameplay remains
owned by generated floor/collision/navigation and ordinary actor systems.

The world-side camera uses one continuous spatial envelope: takeover begins at
`first_influence_start`, the horizon resolves at `first_reveal_apex`, fortress
presentation begins at `frontage_reveal_start`, fortress composition reaches
its apex at `frontage_apex`, and authority returns by `gameplay_return`.
Presentation targets interpolate from the reveal apex toward the generated gate
instead of using a fixed Operator-relative offset. Traversal remains unlocked;
the fortress apex receives a 0.9-second minimum presentation hold and triggers
the existing six-frame moonlight sweep once per presentation instance.

## Authored approach boundary

After the terminal ingress, the authored Vista Approach owns Shore Parish,
the near-Keep route, outer-wall checkpoint, east traverse, local collision and
dressing, and the Front Gate handoff. It does not replace the generated world
frontage or distant reveal.

## Lifecycle

`WorldIngressSite` remains the transition authority. It captures and isolates
all `world_origin_branch` nodes, including `ProcGenRuntime`, starts the
registered route, and restores world visibility, processing, Operator state,
camera follow, and presentation bounds on return or entry failure.

## Validation

Run from the repository root:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_procgen_vista_layering_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/procgen_walkable_boundary_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_frontage_bypass_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_ingress_smoke.gd
```

Acceptance requires generated playable frontage, a terminal ingress on its gate
anchor, collision/navigation-free vista presentation below gameplay, an
exterior clip disjoint from playable floor bounds, authored-approach activation,
and exact world/camera restoration on exit or failure.

## Next Agent Slice

Capture and visually approve entry, takeover, first apex, fortress apex,
gameplay return, and terminal-apron frames across production seeds and viewport
sizes. Extend clip geometry only from generated boundary metadata; do not
replace procgen gameplay authority with a full-map presentation plate.
