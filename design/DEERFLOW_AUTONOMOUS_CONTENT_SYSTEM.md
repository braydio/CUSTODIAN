# DeerFlow Autonomous Content System

**Project:** CUSTODIAN
**Status:** Design
**Created:** 2026-03-24

---

## Overview

A closed-loop autonomous content system that generates game events dynamically based on game state. The system creates events from specs, generates executable code, validates it, and injects it into the game.

---

## Pipeline Architecture

```
[Game State Snapshot]
        ↓
[Event Designer Skill] → JSON Event Spec
        ↓
[Code Generator Skill] → Executable Code
        ↓
[Validator] → Syntax + Safety + API Check
        ↓
[Sandbox Execution] → Test Run
        ↓
[Approved → Inject into CUSTODIAN]
```

**Key Principle:** Split thinking from coding. Never combine them.

---

## Step 1: Game State Snapshot

A minimal, clean schema that captures the current game state for AI analysis.

```json
{
  "tick": 420,
  "phase": "ASSAULT_ACTIVE",
  "sector": "POWER_CORE",
  "threat_level": 7,
  "entities": [
    {"type": "operator", "hp": 80},
    {"type": "turret", "status": "damaged", "count": 4},
    {"type": "enemy", "count": 12, "types": ["drone", "fast"]}
  ],
  "resources": {
    "power": 40,
    "materials": 120
  },
  "active_events": ["minor_breach"],
  "difficulty_score": 5.4
}
```

**Rules:**
- Keep it tight — LLMs degrade with noise
- Update every tick or on significant events
- Include only actionable state

---

## Step 2: Event Designer Skill

Generates a **pure spec**, NOT code. Creates JSON event definitions.

### Input
- Game state snapshot
- Allowed effect types (constrained)

### Output Example

```json
{
  "event_name": "POWER_SURGE_OVERLOAD",
  "trigger": "low_power",
  "effects": [
    {"type": "disable_entity", "target": "random_turret"},
    {"type": "modify_stat", "target": "enemy_speed", "multiplier": 1.2}
  ],
  "duration": 15,
  "risk_level": "HIGH",
  "difficulty_impact": 0.8
}
```

### Allowed Effect Types (Whitelist)

| Effect Type | Parameters | Description |
|-------------|-------------|--------------|
| `spawn_enemy` | type, count, location | Spawn enemies |
| `modify_stat` | target, stat, value | Change entity stats |
| `disable_entity` | target, duration | Disable turrets/structures |
| `trigger_timer` | duration, effect | Delayed effect |
| `spawn_item` | type, location | Spawn pickups |
| `modify_difficulty` | delta | Adjust threat level |

### Constraints

- Return ONLY valid JSON
- Must be implementable in code
- No vague descriptions
- Pick from allowed effect types only

---

## Step 3: Code Generator Skill

Converts spec → executable logic for CUSTODIAN's backend.

### Output Example (Python)

```python
def power_surge_overload(state):
    """Trigger power surge overload event.
    
    Args:
        state: Current game state dict
    
    Returns:
        dict with triggered_effects and state_changes
    """
    if state.get("resources", {}).get("power", 100) < 50:
        return {
            "triggered": True,
            "effects": [
                {"type": "disable_entity", "target": "random_turret", "duration": 15},
                {"type": "modify_stat", "target": "enemy_speed", "multiplier": 1.2, "duration": 15}
            ]
        }
    return {"triggered": False}
```

### Constraints

- Output ONLY Python function
- Must accept `state` parameter
- Must call ONLY allowed engine functions
- Max 20 lines per function
- One responsibility per function

---

## Step 4: Validator (CRITICAL — DO NOT SKIP)

Three-stage validation before execution:

### A. Syntax Check

```python
compile(code, "<string>", "exec")
```

### B. Static Safety Filter

**REJECT if contains:**
- `import os`, `import sys`, `import subprocess`
- `open(`, `file.`, `read(`
- `exec(`, `eval(`
- Network calls
- Direct file system access

### C. Allowed API Check

```python
ALLOWED_FUNCTIONS = {
    "disable_entity",
    "modify_stat",
    "spawn_enemy",
    "spawn_item",
    "trigger_timer",
    "modify_difficulty",
    "log_event",
}

# Reject any call not in ALLOWED_FUNCTIONS
```

---

## Step 5: Sandbox Execution

Test in isolated environment before full injection:

```python
sandbox_globals = {
    "disable_entity": safe_disable_entity,
    "modify_stat": safe_modify_stat,
    "spawn_enemy": safe_spawn_enemy,
    # ... other safe wrappers
}

try:
    exec(code, sandbox_globals)
    result = sandbox_globals["event_function"](test_state)
    validate_result(result)
except Exception as e:
    reject_and_log(e)
```

---

## Step 6: Inject into CUSTODIAN

Register dynamically in the event registry:

```python
EVENT_REGISTRY[event_name] = generated_function
```

Trigger later via:

```python
if event_name in EVENT_REGISTRY:
    EVENT_REGISTRY[event_name](current_state)
```

---

## Simulation (Optional Enhancement)

Before committing to an event, run a simulation:

```python
def simulate_event(state, event_spec, ticks=30):
    """Simulate event outcomes forward in time.
    
    Returns:
        dict with difficulty_impact, potential_damage, success_rate
    """
    # Run forward N ticks
    # Measure outcomes
    return {
        "difficulty_impact": 0.7,
        "potential_damage": "moderate",
        "success_rate": 0.85
    }
```

### Enhanced Pipeline with Simulation

```
1. Generate 3 event ideas (Event Designer)
2. Simulate each (Simulation Tool)
3. Pick best based on metrics
4. THEN generate code (Code Generator)
5. Validate → Execute
```

---

## Hard Constraints for Local Models

Local models (Ollama) need strict guardrails or they'll fail.

### Limit Creativity

**BAD:**
> "Invent anything cool"

**GOOD:**
> "Choose from: overload, breach, reinforcement, sabotage, emergency, malfunction"

### Enforce Schemas

```
INVALID OUTPUT = REJECTED
Always validate against expected schema
```

### Keep Functions Small

- Max 10-20 lines
- One responsibility
- Single exit point preferred

---

## Allowed API Surface

The complete whitelist of functions the AI can call:

### Entity Management
- `spawn_enemy(type, count, location)`
- `despawn_enemy(entity_id)`
- `disable_entity(target, duration)`
- `enable_entity(target)`

### Stat Modification
- `modify_stat(target, stat, value)`
- `set_stat(target, stat, value)`
- `modify_difficulty(delta)`

### Spawning
- `spawn_item(type, location)`
- `spawn_effect(effect_type, location, duration)`

### Timing
- `trigger_timer(delay, effect)`
- `cancel_timer(timer_id)`

### Utilities
- `log_event(message)`
- `get_entity_count(type)`
- `get_resource_amount(resource)`

---

## Minimal Version (Build First)

Start simple, iterate:

1. **ONE event type:** `power_surge`
2. **ONE skill:** Generate event spec
3. **ONE code generator:** Spec → Python function
4. **NO simulation yet:** Just log outputs
5. **Manual validation initially:** Review before injection

Then expand:
- Add more event types
- Add more effect types
- Add automated validation
- Add simulation

---

## Event DSL Schema

For strict, type-safe event definitions:

```yaml
event:
  name: string (unique identifier)
  trigger:
    type: enum (low_power, high_threat, time_elapsed, random, manual)
    params: dict
  effects: list of effect objects
  duration: int (ticks) or null (instant)
  risk_level: enum (LOW, MEDIUM, HIGH, CRITICAL)

effect:
  type: enum (from Allowed API Surface)
  target: string (entity type or specific)
  params: dict (type-specific parameters)

example:
  name: POWER_SURGE
  trigger:
    type: low_power
    threshold: 30
  effects:
    - type: disable_entity
      target: random_turret
      duration: 10
    - type: modify_stat
      target: enemy
      stat: speed
      multiplier: 1.3
  duration: 15
  risk_level: HIGH
```

---

## Implementation Checklist

### Phase 1: Core Infrastructure
- [x] Event registry system (`deerflow_event_registry.gd`)
- [x] State snapshot generator (`deerflow_state_snapshot.gd`)
- [x] Event Designer skill (JSON output) (`deerflow_event_designer.gd`)
- [x] Code Generator skill (Python output) (`deerflow_code_generator.gd`)
- [x] Basic validator (`deerflow_validator.gd`)
- [x] Pipeline orchestrator (`deerflow_orchestrator.gd`)

### Phase 2: Automation
- [ ] Syntax validator (integrated in validator)
- [ ] Safety filter (integrated in validator)
- [ ] API whitelist checker (integrated in validator)
- [ ] Sandbox environment (TBD - requires execution backend)

### Phase 3: Intelligence
- [ ] Simulation tool
- [ ] Event picker (best outcome)
- [ ] Auto-injection into game

### Phase 4: Expansion
- [ ] More event types
- [ ] More effect types
- [ ] Difficulty balancing
- [ ] Learning from outcomes

---

## Implemented Files

| File | Purpose |
|------|----------|
| `core/systems/deerflow_event_registry.gd` | Central event storage and registration |
| `core/systems/deerflow_state_snapshot.gd` | Generates minimal game state for AI |
| `core/systems/deerflow_event_designer.gd` | Analyzes state → generates JSON event spec |
| `core/systems/deerflow_code_generator.gd` | Converts spec → executable Python code |
| `core/systems/deerflow_validator.gd` | Validates code syntax, safety, API compliance |
| `core/systems/deerflow_orchestrator.gd` | Main pipeline controller |
- [ ] Manual validation workflow

### Phase 2: Automation
- [ ] Syntax validator
- [ ] Safety filter
- [ ] API whitelist checker
- [ ] Sandbox environment

### Phase 3: Intelligence
- [ ] Simulation tool
- [ ] Event picker (best outcome)
- [ ] Auto-injection into game

### Phase 4: Expansion
- [ ] More event types
- [ ] More effect types
- [ ] Difficulty balancing
- [ ] Learning from outcomes

---

## Related Documents

- `PLACEABLE_TURRETS.md` — Existing placement systems
- `ATTACK_HIT_TIMING.md` — Combat event system
- `COMBAT_FEEL_SYSTEM.md` — Feel tuning

---

## What This Unlocks

### Dynamic Content Generation
- New events mid-game
- No pre-scripted content limits

### Self-Evolving Gameplay
- AI adapts difficulty dynamically
- Emergent scenarios based on player actions

### Modular Expansion
- Add new tools → new behaviors instantly
- Easy to add new event types
- Safe sandboxed experimentation