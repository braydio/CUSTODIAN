# THE FOLLOWING IS A SERIES OF AUDITS OF THE DEV OBSERVATORY AND ANALYSIS PROCEDURES. REVIEW AND IMPLEMENT RECOMMENDED CHANGES.

AUDIT

## Playtest verdict

This was a **successful combat-system smoke test with two serious runtime defects**:

1. **Ranged-fire failure handling is generating excessive failed attempts.**
2. **Procgen is still producing player-trapping collision pockets despite runtime remediation.**

Combat itself appears functional: enemies attacked, attacks resolved into damaged/blocked/parried outcomes, four enemies died, the player took damage, and the session held approximately 59 FPS. The report is therefore useful evidence that the gameplay loop runs, but it is not yet clean enough for balance conclusions.

## Priority 0 — Ranged firing is failing far too often

The observatory recorded:

- 71 successful shots
- 35 failed fire attempts
- 106 total attempted firing actions
- **33.0% of attempts failed**
- Final ammunition: `0 loaded / 0 reserve`

That is the strongest negative signal in the session.

The operator currently initializes standard ammunition at 48, with a 24-round magazine and a 1.7-second reload duration. The active runtime also exposes several overlapping ranged-fire presentation and combat states. fileciteturn4file0L92-L111 fileciteturn4file0L201-L214

### Most likely interpretation

Some failures near the end were probably legitimate dry-fire attempts after ammunition exhaustion. However, the report does not tell us whether each failure was caused by:

- empty magazine
- no reserve ammunition
- reload already active
- cooldown active
- weapon not equipped
- invalid weapon profile
- animation/state lock
- input blocked by field patch, dodge, hit reaction, or parry
- projectile spawn failure
- another readiness predicate

That makes `player_ranged_fire_failures = 35` actionable only as a symptom.

### Required observability patch

Every `player_ranged_fire_failed` event should carry a stable reason enum:

```gdscript
enum RangedFireFailureReason {
	NONE,
	NO_WEAPON,
	EMPTY_MAGAZINE,
	NO_RESERVE_AMMO,
	RELOADING,
	FIRE_COOLDOWN,
	ACTION_LOCKED,
	DODGING,
	FIELD_PATCH_ACTIVE,
	DEAD,
	INVALID_PROFILE,
	PROJECTILE_SPAWN_FAILED,
}
```

Emit both the aggregate counter and reason-specific counters:

```gdscript
func _record_ranged_fire_failure(
		reason: RangedFireFailureReason,
		extra: Dictionary = {}
) -> void:
	var reason_name := RangedFireFailureReason.keys()[reason].to_lower()

	_obs_increment(&"player_ranged_fire_failures")
	_obs_increment(StringName("player_ranged_fire_failure_%s" % reason_name))

	var snapshot := {
		"reason": reason_name,
		"loaded_ammo": player_loaded_ammo,
		"reserve_ammo": player_reserve_ammo,
		"reload_active": _reload_active,
		"cooldown_remaining": fire_cooldown_remaining,
		"weapon_equipped": primary_weapon_equipped,
		"weapon_id": equipped_primary_weapon_id,
	}
	snapshot.merge(extra, true)
	_obs_log(&"player_ranged_fire_failed", snapshot)
```

Also separate **trigger input** from **actual fire attempts**. Holding fire during cooldown should not necessarily count as repeated gameplay failures. Recommended counters:

```text
player_ranged_trigger_samples
player_ranged_fire_requests
player_ranged_shots_fired
player_ranged_fire_failure_empty
player_ranged_fire_failure_state_locked
player_ranged_fire_failure_internal
```

A failure caused by an empty gun is player feedback. A failure caused by an invalid profile or spawn failure is a defect. They should not share one undifferentiated metric.

### Acceptance threshold

For the next test:

- Internal/system failures: **0**
- Invalid profile/spawn failures: **0**
- Non-empty state-lock failures: **under 2% of requests**
- Empty-ammo attempts may remain high, but must be reported separately
- Dry-fire feedback should be rate-limited to avoid audio and observatory spam

---

## Priority 0 — Procgen produced repeated hard traps

The report contains:

- 4 stuck pockets detected
- 4 pockets remediated
- 2 operator stuck detections
- 2 automatic rescues
- rescues at approximately 208.955 and 213.442 seconds

The second rescue happened only **4.487 seconds after the first**. That suggests one of three conditions:

1. The rescue destination was adjacent to or still inside a defective collision region.
2. Runtime blocker changes recreated a trap almost immediately.
3. The operator was returned to the same local geometry and retriggered the detector.

The current detector waits while movement input is present, checks low displacement and low velocity, then requires fewer than two escape neighbors plus a runtime prop blocker or nearby collision body before rescuing. fileciteturn6file0L97-L129 It then searches for a nearby runtime-walkable location and teleports the operator there. fileciteturn6file0L130-L152

The detector is doing its job. The generator or runtime blocker system is not.

### Required remediation change

Do not treat successful rescue as successful pocket remediation. After selecting a rescue tile:

1. Validate a minimum reachable area around it.
2. Require at least two independent escape neighbors.
3. Reject candidates within the original defective pocket’s local component.
4. Add a temporary exclusion radius around the original rescue source.
5. Re-run validation after the operator is moved.
6. Record source and destination walkability details.

Example candidate gate:

```gdscript
func _is_safe_unstuck_destination(
		provider: Node,
		candidate_global: Vector2,
		origin_tile: Vector2i
) -> bool:
	var report: Dictionary = provider.call(
		"debug_get_stuck_report_at_global",
		candidate_global
	)

	if report.is_empty():
		return false

	var candidate_tile: Vector2i = report.get("tile", Vector2i.ZERO)
	if candidate_tile.distance_to(origin_tile) <= 1.0:
		return false

	if int(report.get("escape_neighbor_count", 0)) < 2:
		return false

	if bool(report.get("runtime_prop_blocked", false)):
		return false

	var nearby_bodies: Array = report.get("nearby_collision_bodies", [])
	if not nearby_bodies.is_empty():
		return false

	return true
```

The better long-term correction belongs in procgen validation: any committed blocker set that reduces a player-accessible tile to fewer than two escape neighbors should be rejected or repaired **before gameplay**.

### Acceptance threshold

For a 10-minute traversal test:

- Generated stuck pockets: **0**
- Operator rescues: **0**
- Post-generation remediation: ideally **0**
- Any generated pocket should export its seed, sector, tile, blocker sources, and local collision mask

---

## Priority 1 — The report itself has consistency defects

The header says `8 warnings`, but only five warning entries are printed:

```text
Procgen remediation: 1
Operator detector: 2
Operator rescue: 2
Total displayed: 5
```

That is either:

- an exporter truncation that is not labeled,
- warning deduplication without disclosure,
- or a summary/list disagreement.

The report must say something like:

```text
WARNINGS (8 total, 5 displayed, 3 deduplicated)
```

or print all eight. Otherwise users will reasonably assume the report is malformed.

There is another terminology problem:

```text
procgen_stuck_pockets_detected     4
procgen_stuck_pockets_remediated   4
operator_stuck_detections          2
operator_unstuck_rescues           2
```

These appear to represent two different stages, but the distinction is unclear. Rename or document them as:

```text
procgen_validation_pockets_detected
procgen_validation_pockets_repaired
runtime_operator_traps_detected
runtime_operator_traps_rescued
```

---

## Priority 1 — Enemy AI instrumentation indicates a legacy path

The final behavior sample reports:

```json
{
  "carrying_loot": false,
  "enabled": false,
  "profile_id": "raider_grunt",
  "state": "legacy"
}
```

At the same time:

- 7 enemies were active
- 6 enemy attacks resolved
- 24 simulation-tier changes occurred
- `behavior_agents = 0`

This means combat is functioning through a legacy or non-agent path while the newer behavior-agent gauge remains empty. That is not necessarily broken, but the observatory is presenting mutually confusing concepts.

Choose one of these:

- Rename `behavior_agents` to `director_behavior_agents` and explicitly expose `legacy_combat_agents`.
- Stop sampling `enemy_behavior_sample` from enemies that do not participate in the current behavior system.
- Migrate the remaining raider-grunt runtime path and make `state = legacy` an explicit warning.
- Declare the legacy path as the current authority in the active AI context documents.

Until this is clarified, the report cannot reliably answer whether the Enemy Behavior Director is functioning.

---

## Priority 2 — Dodge data is too sparse to validate iframes

Only two dodges occurred and there were zero iframe avoids. That is insufficient evidence of a defect. The operator is configured with:

- 0.20-second dodge movement
- 0.16-second iframe duration
- 0.16-second recovery
- 0.42-second cooldown
- 16 stamina cost fileciteturn4file0L161-L167

The next targeted playtest should deliberately execute at least 20 dodge-through-hit attempts. Add:

```text
incoming_hit_during_dodge
incoming_hit_during_iframe
incoming_hit_during_dodge_recovery
dodge_iframe_avoid
dodge_timing_miss_early
dodge_timing_miss_late
```

Zero avoids across two incidental dodges does not justify tuning the iframe window.

---

## Priority 2 — Field-patch healing was never exercised

The player ended at `43.45 / 100 HP`, had one patch remaining, and committed zero patches. The field-patch system therefore received no meaningful test despite the player losing 56.55 health.

The configured behavior is currently:

- maximum count: 2
- starting count: 1
- use duration: 1.25 seconds
- restores 35% health
- recovery: 0.20 seconds
- movement multiplier during use: 0.35 fileciteturn4file0L193-L199

This should be a dedicated test case, not interpreted as a failure. Validate:

- activation
- cancellation by damage
- cancellation by dodge
- cancellation by input
- successful commit
- count decrement exactly once
- 35 HP restoration at current maximum health
- inability to use at full health
- death during use
- observatory active/commit/cancel reason events

---

## Performance note

`12,046` nodes with 7 enemies, 7 ambient critters, one projectile, and 59 FPS is acceptable as an initial smoke-test result, but the node count is high relative to the visible simulation population.

Instrument these before optimizing:

```text
node_count_world
node_count_procgen
node_count_props
node_count_collision
node_count_vfx
node_count_ui
physics_body_count
collision_shape_count
process_enabled_node_count
physics_process_enabled_node_count
```

A stable 59 FPS on one machine does not show whether 12,000 nodes are cheap static nodes or thousands of processing nodes.

---

## Recommended fix order

1. Add ranged-fire failure reason taxonomy.
2. Export exact stuck-pocket seed, tile, blocker sources, and rescue destination validation.
3. Fix warning count/list consistency.
4. Clarify legacy enemy behavior versus behavior-agent metrics.
5. Run targeted dodge and field-patch tests.
6. Add node-count ownership breakdown.
7. Only then perform weapon, enemy-damage, or healing balance changes.

Do **not** tune combat balance from this run. The run was dominated by ammunition exhaustion and traversal defects, and several systems were barely exercised.

## Documentation drift check

Repository guidance says current Godot implementation authority lives in `design/`, with meaningful runtime changes also reflected in `custodian/docs/ai_context/CURRENT_STATE.md`; the Python runtime is historical. fileciteturn0file1

Potential drift revealed by this report:

- `enemy_behavior_sample.state = legacy` may conflict with any documentation claiming the new Enemy Behavior Director is the active authority.
- Runtime procgen apparently still requires automatic player rescue; any document describing blocked-pocket prevention as complete should be downgraded.
- Observatory docs should define the difference between procgen validation pockets and actual runtime operator traps.
- Ranged-fire failure metrics currently lack enough semantic detail to support a claim that ranged telemetry is complete.

Update these paths as part of the fix:

```text
design/20_features/in_progress/ENEMY_BEHAVIOR_DIRECTOR.md
design/20_features/in_progress/COMBAT_FEEL_SYSTEM.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/CONTEXT.md
custodian/docs/ai_context/FILE_INDEX.md
```

The active runtime is correctly identified as `custodian/`, and Godot-native specs take precedence over older documentation. fileciteturn0file1 The playtest source and repository-access guidance are also captured in the supplied project context. fileciteturn0file0

## Best Repomix collection command

Run this from the live repository root to package the exact code and documentation needed for an implementation-grade patch:

```bash
npx repomix \
  custodian/game/actors/operator \
  custodian/game/actors/projectiles \
  custodian/game/systems/combat \
  custodian/game/world/procgen \
  custodian/game/systems/dev_observatory \
  custodian/docs/ai_context \
  design/20_features/in_progress/COMBAT_FEEL_SYSTEM.md \
  design/20_features/in_progress/ENEMY_BEHAVIOR_DIRECTOR.md \
  --include "**/*.gd,**/*.tscn,**/*.tres,**/*.md" \
  --ignore "**/.godot/**,**/*.import,**/assets/**,**/content/sprites/**" \
  --style markdown \
  --output custodian_dev_observatory_diagnostic_repomix.md
```

If the observatory directory has a different current path, locate it first:

```bash
rg -l \
  "player_ranged_fire_failed|operator_stuck_detected|procgen_stuck_pocket|observatory_session_exported" \
  custodian design
```

Then substitute the discovered directories into the Repomix command.

AUDIT 2

## This run is materially better on ranged reliability, but much worse on survivability

Compared with the 19:38 session:

| Metric                 | Previous | Current |                        Change |
| ---------------------- | -------: | ------: | ----------------------------: |
| Uptime                 |   215.5s |  115.5s |                   shorter run |
| Shots fired            |       71 |      46 |                  lower volume |
| Fire failures          |       35 |       4 |         **major improvement** |
| Failure rate           |    33.0% |    8.0% | **down 25 percentage points** |
| Enemies destroyed      |        4 |       8 |                       doubled |
| Damage taken           |    56.55 |   115.2 |             more than doubled |
| Deaths                 |        0 |       1 |                   player died |
| Enemy attacks resolved |        6 |       9 |                     increased |
| Blocks/parries         |  4 total |       0 |          collapsed completely |
| Runtime stuck rescues  |        2 |       0 |         **major improvement** |
| FPS                    |       59 |      60 |                        stable |
| Node count             |   12,046 |  10,759 |              down about 10.7% |

## Strong positive signals

### Ranged-fire failures improved substantially

You now have:

- 46 successful shots
- 4 failed attempts
- 50 total fire attempts
- **8% failure rate**

That is dramatically healthier than the prior 35 failures against 71 successful shots.

The remaining four failures may simply be dry-fire attempts because the session ended at:

```text
loaded ammo:  0
reserve ammo: 0
```

If all four happened after ammunition exhaustion, the ranged system may now be functioning correctly. You still need failure-reason telemetry to prove that, but this report no longer suggests a severe firing-state defect.

### No runtime operator trap occurred

The generator detected and repaired two pockets during initialization, but there were:

```text
operator_stuck_detections: 0
operator_unstuck_rescues:  0
```

That is a meaningful improvement over the previous run’s two rescues.

The remaining warnings happened at 7.310 and 7.311 seconds, indicating startup validation repaired two pockets almost simultaneously. That is much preferable to trapping the player during active play.

### Combat throughput improved

Eight enemies were destroyed in under two minutes versus four enemies in more than three and a half minutes previously.

Approximate kill rates:

```text
Previous: 1.11 enemies/minute
Current:  4.16 enemies/minute
```

That is approximately **3.7 times the previous kill rate**.

This could reflect improved play, better encounter density, stronger ranged output, or enemies entering active simulation more consistently. It is too large a difference to treat as pure balance evidence without encounter context, but the combat loop was clearly more active.

## Critical problem: defensive play disappeared

Every one of the nine resolved enemy attacks produced damage:

```text
enemy attack results: damaged=9
```

There were:

- zero blocked attacks
- zero parried attacks
- zero whiffs
- one dodge
- zero iframe avoids

The player took four registered incoming hits and died.

This is a sharp regression from the previous session:

```text
Previous:
blocked = 1
parried = 3
damaged = 2

Current:
damaged = 9
```

The discrepancy between nine enemy attacks marked `damaged` and only four incoming damage events needs explanation. Possibilities include:

- multiple enemy attack resolution events mapping to one player damage event
- attacks resolving against another target
- multi-stage attacks
- duplicate attack-result logging
- damage suppressed after death or invulnerability
- enemy attack results recording intended rather than applied outcomes

Add identifiers to both events:

```gdscript
{
	"attack_id": attack_instance_id,
	"attacker_id": attacker.get_instance_id(),
	"target_id": target.get_instance_id(),
	"result": result,
	"damage_attempted": attempted_damage,
	"damage_applied": applied_damage,
	"target_health_before": health_before,
	"target_health_after": health_after
}
```

Then reconcile:

```text
enemy_attack_resolved.attack_id
    ↕
incoming_hit_result.attack_id
    ↕
player_damage.attack_id
```

Every damaging attack should have an auditable chain.

## Damage tuning may be too punitive

The player received 115.2 observed damage over four player-damage events:

```text
Average damage per registered hit = 28.8
```

At 100 maximum health, that means roughly four successful hits kill the player.

That may be intentional for CUSTODIAN, but this session had:

- eight active enemies
- nine active-tier transitions
- no successful defense
- stamina ending at zero
- no healing used

The death may therefore be a legitimate failure state rather than overtuning. Still, an average of 28.8 damage per hit leaves little room for the player to learn when surrounded.

Before changing damage, capture:

```text
damage by attacker profile
damage by attack type
damage before mitigation
damage after mitigation
time between player hits
simultaneous attackers targeting player
nearby enemy count at each hit
stamina at each hit
```

The most important value is **time-to-kill**, not average damage alone. Four hits over 45 seconds feels different from four hits in 1.5 seconds.

## Stamina deserves investigation

The player ended at zero stamina.

Only one dodge was recorded, so dodge expenditure alone did not drain it. Likely contributors are:

- sustained sprinting
- parry or block attempts that did not resolve successfully
- heavy attacks
- another stamina-consuming action
- stamina state freezing after death

Because `player_sprinting` only reflects the final state, the report cannot tell us what drained the bar.

Add counters:

```text
stamina_spent_sprinting
stamina_spent_dodging
stamina_spent_blocking
stamina_spent_parrying
stamina_spent_heavy_attack
stamina_regenerated
stamina_exhaustion_events
```

And event snapshots whenever stamina reaches zero:

```gdscript
_obs_log(&"player_stamina_exhausted", {
	"cause": exhaustion_cause,
	"active_enemies": active_enemy_count,
	"health": health,
	"current_action": current_action_name,
})
```

## Field-patch healing remains functionally untested

The player died while still holding one field patch:

```text
field patches remaining: 1
committed: 0
cancelled: 0
```

This is now more important than in the earlier session because the player actually reached zero health.

Potential causes:

- the player intentionally did not use it
- the input was unclear
- the healing affordance was not noticeable
- combat pressure never permitted a 1.25-second heal
- the system was unavailable but did not log failure
- the user forgot it existed

Add:

```text
field_patch_input_attempted
field_patch_use_rejected
field_patch_rejection_reason
field_patch_available_while_below_50_percent
seconds_below_50_percent_with_patch_available
player_died_with_patch_remaining
```

The last counter is especially useful. Repeated deaths with healing inventory unused usually indicate an affordance or usability problem, not merely player choice.

## Procgen is improved, but blocker density rose sharply

Current runtime blocker state:

```text
Previous blocker cells: 36
Current blocker cells: 143
```

That is almost a fourfold increase despite fewer blocker registrations:

```text
Previous sources: 8
Current sources: 10
Previous registrations: 14
Current registrations: 12
```

The average blocked cells per active source increased from:

```text
Previous: 4.5 cells/source
Current: 14.3 cells/source
```

Yet there were no runtime traps. That suggests the remediation or placement logic may be working better even with denser blockers.

Still, two startup pockets were created and repaired. The long-term target remains zero generated invalid pockets, even though automatic startup repair is acceptable during development.

## Enemy simulation appears more active

The previous final state had:

```text
interest_active: 0
interest_background: 3
interest_dormant: 4
```

The current run ended with:

```text
interest_active: 5
interest_background: 3
interest_dormant: 0
```

That aligns with:

- more attacks
- more kills
- more assault-state transitions
- higher incoming pressure

The assault director was notably active:

```text
commit:   10
probing:   9
regroup:   7
```

That likely explains why this run felt much more combat-dense.

However, `behavior_agents` is still zero and the sampled raider remains:

```json
{ "enabled": false, "profile_id": "raider_grunt", "state": "legacy" }
```

So the active combat behavior is still not passing through the newer behavior-agent instrumentation.

## New instrumentation concern: world-state event volume

`world_state_changed` rose from 10 events in 215 seconds to 47 events in 115 seconds.

Rates:

```text
Previous: 2.8 events/minute
Current:  24.4 events/minute
```

That is approximately an **8.7× increase**.

Likewise:

```text
world_history_recorded: 28
sector_damage:          15
```

This may be legitimate because the session included much more combat and eight kills, but it is worth checking whether world-state records are being emitted redundantly.

Each world-state event should include:

```text
change_reason
entity_id
sector_id
old_value
new_value
dedupe_key
persistent_or_transient
```

Transient combat events should not necessarily create persistent world-history records.

## Overall assessment

### Improved

- Ranged-fire reliability
- Runtime stuck-pocket safety
- Combat throughput
- Frame rate stability
- Node count
- Warning-list consistency: 2 reported and 2 displayed

### Regressed or newly exposed

- Player survivability
- Defensive action use or effectiveness
- Stamina exhaustion
- Death with unused healing
- Enemy attack-to-damage telemetry mismatch
- High world-state/history event volume
- Legacy enemy behavior path remains active

## Next playtest protocol

Run a deliberately controlled three-minute test:

1. Fire until the first reload and record whether any failures occur before empty ammunition.
2. Successfully block five attacks.
3. Successfully parry five attacks.
4. Attempt ten timed dodges through attacks.
5. Use one field patch successfully below 50 health.
6. Attempt one field patch and intentionally cancel it.
7. Avoid killing enemies for the first 60 seconds so incoming attack cadence can be measured.
8. Then kill the encounter normally.

Success criteria:

```text
internal ranged failures             0
runtime stuck rescues                0
blocked attacks                      >= 5
parried attacks                      >= 5
iframe avoids                        >= 3
field patches committed              >= 1
field patches cancelled              >= 1
enemy damaging results without
matching incoming-hit records        0
player deaths                        optional
```

I would prioritize the **attack-result reconciliation patch** and **field-patch usability telemetry** before making any combat balance changes.
