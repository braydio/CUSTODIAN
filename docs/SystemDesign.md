# System Design (Simulation First)

This project is not a wave-defense game. It is a pressure-based survival simulation. The design hinges on continuous time, uncertainty, and asymmetric information.

## Time Layers

The loop is defined by three overlapping time layers:

1. Ambient time: always running.
2. Assault time: high-intensity spikes.
3. Field time: player absence and risk transfer.

Battles do not have clean boundaries. Threat is continuous. Safety is inferred, not guaranteed.

## Five Core Systems

### A) Power as a Campaign Resource

Power is more than moment-to-moment energy. It is a victory requirement and a persistent bottleneck.

Two kinds of power:

- Operational power: moment-to-moment use (turrets, traps, barriers).
- Strategic power capacity: power cells/generators that determine how many systems can exist.

Strategic power is accumulated and protected, not spent.

### B) Field Power Cells (Forcing Recon)

Power cells:

- Exist in the world.
- Are procedurally placed after the tutorial.
- Must be repaired, extracted, and installed.
- Cannot be fabricated at base.

This keeps recon relevant in the late game.

### C) Ambient Threat (Always-On Pressure)

A hidden scalar that rises over time and faster when:

- You expand power.
- You complete recon runs.
- You defeat assaults decisively.

Ambient threat manifests as solo attackers, small groups, saboteurs, and environmental hazards. These are not assaults. They are the world pressing in.

### D) Major Assaults (Gated, Not Scripted)

Major assaults:

- Are triggered by a hidden assault timer.
- Start the moment you return from recon.
- Do not stop if you leave again.
- Lock down safe recon and consume resources.

Key rule: recon runs trigger assaults, and assaults gate recon runs.

### E) "Quiet Enough" State (Soft Feedback)

The player should only see qualitative state, not timers:

- "Tense"
- "Unstable"
- "Quiet enough"

This keeps uncertainty without unfairness.

## Implementation Order (Do This First)

Do not add recon gameplay, ambient enemies, or real-time ticks yet. Build the clock and pressure model in text first.

### Step 1: Add a global GameState

Single source of truth:

```python
class GameState:
    def __init__(self):
        self.time = 0
        self.ambient_threat = 0.0
        self.assault_timer = None
        self.in_major_assault = False
        self.player_location = "Command Center"
```

### Step 2: Advance time every tick

```python
def advance_time(state, delta=1):
    state.time += delta
    state.ambient_threat += 0.01 * delta
```

### Step 3: Implement ambient events only

```python
def maybe_trigger_ambient_event(state):
    if state.ambient_threat > 5 and random.random() < 0.1:
        print("Ambient event: lone scavenger enters the perimeter")
```

### Step 4: Add the hidden assault timer

```python
def maybe_start_assault_timer(state):
    if state.assault_timer is None:
        state.assault_timer = random.randint(30, 60)
```

```python
def tick_assault_timer(state):
    if state.assault_timer is not None:
        state.assault_timer -= 1
        if state.assault_timer <= 0:
            state.in_major_assault = True
```

Do not print the timer. Only print when the assault starts.

### Step 5: Gate recon with state, not UI

```python
def can_go_on_recon(state):
    return not state.in_major_assault and state.ambient_threat < THRESHOLD
```

## Why This Ordering Matters

If you implement time and pressure first:

- Ambient events stop feeling random.
- Assaults feel earned.
- Recon feels dangerous.
- Power acquisition feels meaningful.
- The base feels alive even in text.

## Validation Target

Run `python game/simulations/world_state/sandbox_world.py` and confirm:

- Quiet stretches.
- Sudden incidents.
- Assaults emerging naturally.
- Qualitative status messages only.

## World-State Command Endpoint

The world-state server exposes a simple POST endpoint for command execution.

Endpoint: `POST /command`

JSON request:

- `command`: string input.

JSON response (CommandResult):

- `ok`: bool.
- `text`: primary output.
- `lines`: optional list of lines.
- `warnings`: optional list.
