# ARRN Tutorial Integration

Status: Implemented on 2026-03-03.

## Overview

Add ARRN (Adaptive Relay Recovery Network) to the tutorial system:
1. New `RELAY` tutorial topic
2. Integration into QUICKSTART flow (after Phase 16)

## New Tutorial Topic: RELAY

### Content

```python
    "RELAY": [
        "TUTORIAL > RELAY",
        "-----",
        "THE ARRN NETWORK RECOVERS FRAGMENTED KNOWLEDGE FROM RELAY NODES.",
        "RELAYS DECAY OVER TIME; ACTIVE ASSAULTS ACCELERATE DECAY.",
        "-----",
        "COMMANDS:",
        "SCAN RELAYS (COMMAND) - REVEALS RELAY STATUS AND STABILITY.",
        "STABILIZE RELAY <ID> (FIELD) - TAKES TIME, ADDS TO PACKET QUEUE.",
        "SYNC (COMMAND) - CONVERTS PACKETS TO KNOWLEDGE INDEX.",
        "-----",
        "RELAY STATUS:",
        "- LOCATED: RECENTLY DETECTED, REQUIRES STABILIZATION.",
        "- UNSTABLE: STABILIZING, NOT YET RELIABLE.",
        "- STABLE: FULLY OPERATIONAL, GENERATES PACKETS.",
        "- WEAK: OPERATIONAL BUT RISK OF PACKET LOSS ON SYNC.",
        "- DORMANT: OFFLINE, CONTRIBUTES TO DORMANCY PRESSURE.",
        "-----",
        "DORMANCY PRESSURE:",
        "- MORE DORMANT RELAYS = HIGHER PRESSURE.",
        "- HIGH PRESSURE: MORE FREQUENT ASSAULTS, FIDELITY SUPPRESSION.",
        "- KNOWLEDGE LEVEL 7 (ARCHIVAL SYNTHESIS) HALVES PRESSURE.",
        "-----",
        "KNOWLEDGE UNLOCKS (PROGRESS: 1-7):",
        "- TIER 1: SIGNAL_RECONSTRUCTION_I - BETTER DEGRADED FIDELITY.",
        "- TIER 2: MAINTENANCE_ARCHIVE_I - REMOTE REPAIR DISCOUNT.",
        "- TIER 3: THREAT_FORECAST_I - +1 TICK ASSAULT WARNING.",
        "- TIER 4: FAB_BLUEPRINTS_I - NEW FABRICATION RECIPE.",
        "- TIER 5: LOGISTICS_OPTIMIZATION_I - +10% EFFICIENCY.",
        "- TIER 6: SIGNAL_RECONSTRUCTION_II - NEVER BELOW DEGRADED.",
        "- TIER 7: ARCHIVAL_SYNTHESIS - HALVE DORMANCY PRESSURE.",
        "-----",
        "EXAMPLE:",
        "[OPERATOR] SCAN RELAYS",
        "[SYSTEM] RELAY NETWORK:",
        "[SYSTEM] - R_NORTH: STABLE | SECTOR NORTH TRANSIT | STABILITY 85",
        "[OPERATOR] DEPLOY NORTH",
        "[OPERATOR] STABILIZE R_NORTH",
        "[OPERATOR] RETURN",
        "[OPERATOR] SYNC",
        "[SYSTEM] KNOWLEDGE INDEX: 1/7",
    ],
```

### Topics List Update

Add to index: `"[RELAY] SCAN, STABILIZE, SYNC AND KNOWLEDGE PROGRESSION"`

---

## Quickstart Integration

### Current Flow (16 phases)

```
PHASE 1-2:    Setup → STATUS, POLICY PRESET
PHASE 3-6:    Configuration → DOCTRINE, DEFENSE, FORTIFY
PHASE 7-9:    Resources → SCAVENGE, FAB, WAIT
PHASE 10-11:  Contact prep → STATUS ASSAULT, WAIT UNTIL ASSAULT
PHASE 12-15:  Combat → BOOST, REROUTE, PRIORITIZE, WAIT
PHASE 15B:    Stand down → WAIT
PHASE 16:     Aftermath → STATUS SYSTEMS
PHASE 18:     Repair → REPAIR (optional)
```

### Proposed Flow (19 phases)

```
PHASE 1-2:    Setup → STATUS, POLICY PRESET
PHASE 3-6:    Configuration → DOCTRINE, DEFENSE, FORTIFY
PHASE 7-9:    Resources → SCAVENGE, FAB, WAIT
PHASE 10-11:  Contact prep → STATUS ASSAULT, WAIT UNTIL ASSAULT
PHASE 12-15:  Combat → BOOST, REROUTE, PRIORITIZE, WAIT
PHASE 15B:    Stand down → WAIT
PHASE 16:     Aftermath → STATUS SYSTEMS
PHASE 17:     RELAY SCAN → SCAN RELAYS [NEW]
PHASE 18:     RELAY FIELD → DEPLOY, STABILIZE [NEW]
PHASE 19:     RELAY SYNC → RETURN, SYNC [NEW]
PHASE 20:     Repair → REPAIR (optional)
```

### New Tutorial Steps

```python
    TutorialStep(
        key="PHASE 17: RELAY SCAN",
        prompt=[
            "[PROMPT] RUN: SCAN RELAYS",
            "[WHY] DISCOVER RELAY STATUS AND STABILITY BEFORE FIELD OPS.",
        ],
        expected="SCAN RELAYS",
        condition=lambda _state, last, _result: _is_verb(last, "SCAN") and _arg_at(last, 0) == "RELAYS",
    ),
    TutorialStep(
        key="PHASE 18: RELAY DEPLOY",
        prompt=[
            "[PROMPT] RUN: DEPLOY NORTH",
            "[WHY] LEAVE COMMAND TO PERFORM FIELD RELAY OPERATIONS.",
        ],
        expected="DEPLOY <SECTOR>",
        condition=lambda _state, last, _result: _is_verb(last, "DEPLOY"),
    ),
    TutorialStep(
        key="PHASE 18B: RELAY STABILIZE",
        prompt=[
            "[PROMPT] RUN: STABILIZE R_NORTH",
            "[WHY] STABILIZE A RELAY TO GENERATE A KNOWLEDGE PACKET.",
        ],
        expected="STABILIZE RELAY <ID>",
        condition=lambda _state, last, _result: _is_verb(last, "STABILIZE"),
    ),
    TutorialStep(
        key="PHASE 19: RELAY SYNC",
        prompt=[
            "[PROMPT] RUN: RETURN THEN SYNC",
            "[WHY] RETURN TO COMMAND AND SYNC PACKETS TO KNOWLEDGE INDEX.",
        ],
        expected="SYNC",
        condition=lambda _state, last, _result: _is_verb(last, "SYNC"),
    ),
```

---

## File Changes

| File | Change |
|------|--------|
| `game/simulations/world_state/terminal/commands/tutorial.py` | Add `RELAY` topic to `TOPIC_LINES` |
| `game/simulations/world_state/terminal/tutorial_flow.py` | Add 4 new steps to `QUICKSTART_STEPS` |

---

## Backward Compatibility

- Existing topics unchanged
- QUICKSTART still works if user skips ARRN steps
- No breaking changes to existing flows

---

## Testing Checklist

- [x] RELAY topic displays correctly via `TUTORIAL RELAY`
- [x] QUICKSTART advances through new ARRN phases
- [x] SCAN RELAYS command recognized
- [x] DEPLOY → STABILIZE → RETURN → SYNC flow works
- [x] Existing tests pass
