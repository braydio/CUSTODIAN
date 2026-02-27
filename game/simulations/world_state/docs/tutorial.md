# World-State Tutorial

This guide is for the terminal-driven world-state sim (`python -m game --repl`).

## Live Terminal Tutorial Command

- Run `TUTORIAL` (or `/TUTORIAL`) for the in-terminal guide.
- Use `TUTORIAL <TOPIC>` to drill into a system family.
- Topics mirror the `HELP` tree: `CORE`, `MOVEMENT`, `SYSTEMS`, `GRID`, `POLICY`, `FABRICATION`, `ASSAULT`, `STATUS`.

## 1) Core Mental Model

- Nothing advances unless you run a time-bearing command.
- Main time-bearing commands:
  - `WAIT`, `WAIT NX`, `WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>`
  - `SCAVENGE`, `SCAVENGE NX`
- Most other commands configure systems or queue work, then you `WAIT` to see results.

Quick pacing rule:

- Outside assault: `WAIT` = 5 internal ticks.
- During active assault: `WAIT` = 1 internal tick.

## 2) Session Goal and Fail States

You are trying to preserve command authority and archive integrity long enough to recover capability.

Failure latches:

- `COMMAND CENTER LOST` (COMMAND damage stays at breach threshold too long).
- `ARCHIVAL INTEGRITY LOST` (archive-loss limit reached).

When failed, only `RESET` or `REBOOT` is accepted.

## 3) Read the Sim in This Order

Use this order every cycle:

1. `STATUS` for immediate posture.
2. `STATUS ASSAULT` for approaches/active engagement.
3. `STATUS SYSTEMS` for damaged sectors/structures.
4. `STATUS POLICY` and `STATUS FAB` for your current strategy and throughput.
5. Pick one change, then `WAIT`.

## 4) Authority and Presence (Very Important)

- `COMMAND` mode: strategic commands available.
- `FIELD` mode: movement/local actions available, many strategic verbs blocked.

Transitions:

- `DEPLOY <target>` leaves command authority and starts a movement task.
- `MOVE <target>` traverses adjacent routes.
- `RETURN` queues return to COMMAND.

Practical rule: do strategic planning in COMMAND; do relay stabilization and local/manual actions in FIELD.

## 5) How Systems Interact

### Power -> Fidelity -> Information Quality

- COMMS effectiveness drives fidelity: `FULL`, `DEGRADED`, `FRAGMENTED`, `LOST`.
- Lower fidelity makes `WAIT`/`STATUS` less precise and can delay/obscure warnings.
- If runs feel chaotic, check COMMS/POWER first and repair them early.

### Policy/Doctrine/Allocation -> Assault Outcomes

- `SET` policy sliders shift repair/defense/surveillance behavior.
- `CONFIG DOCTRINE` changes defense posture tradeoffs by target type.
- `ALLOCATE DEFENSE` biases protection by group (`COMMAND`, `POWER`, `SENSORS`, `PERIMETER`).
- `FORTIFY` reduces incoming pressure:
  - `FORTIFY <SECTOR> <0-4>` affects sector damage pressure.
  - `FORTIFY T_NORTH|T_SOUTH <0-4>` helps transit intercept effectiveness.

### Repairs/Fabrication/Logistics Coupling

- Repairs cost `materials`; fabrication uses `inventory` resources and produces stock/inventory.
- High load/pressure reduces repair and fabrication throughput.
- Heavy fortification and overloaded systems can slow your queues.
- During assault, repair speed is penalized unless supported.

### Assault Loop

- Approaches spawn and move through transit lanes.
- Intercepts consume turret ammo before full engagement.
- Active assault applies multi-tick pressure, then resolves with after-action impact.
- Tactical commands (`REROUTE POWER`, `BOOST DEFENSE`, `DRONE DEPLOY`, `LOCKDOWN`, `PRIORITIZE REPAIR`) only work during active assault.

### Relay Loop

- `SCAN RELAYS` from command.
- Move to relay sector and `STABILIZE RELAY <ID>`.
- Return to command and `SYNC` to convert packets into knowledge progress.
- Relay knowledge grants benefits (example: remote repair cost discount at sufficient progress).

## 6) First 10-Minute Operator Script

Run:

```text
HELP
STATUS
STATUS POLICY
STATUS FAB
```

Set a stable opening:

```text
POLICY PRESET BALANCED
CONFIG DOCTRINE COMMAND_FIRST
ALLOCATE DEFENSE COMMAND 40
FORTIFY T_NORTH 2
FORTIFY T_SOUTH 2
```

Start material and queue posture:

```text
SCAVENGE 2X
FAB ADD COMPONENTS_BATCH
FAB ADD TURRET_AMMO
WAIT 2X
```

If an approach appears:

```text
STATUS ASSAULT
WAIT UNTIL ASSAULT
```

During assault:

```text
BOOST DEFENSE COMMAND
REROUTE POWER COMMAND
PRIORITIZE REPAIR COMMAND
WAIT 3X
```

After assault:

```text
STATUS SYSTEMS
REPAIR <STRUCTURE_ID>
WAIT UNTIL REPAIR_DONE
STATUS
```

## 7) Choice Guide (What to Expect)

- Focus on COMMAND early:
  - Safer command-center survival, but other sectors may degrade faster.
- Over-invest in PERIMETER:
  - Better transit/intercept pressure relief, less protection for command/power/comms.
- Aggressive doctrine:
  - Stronger offense in fights, but can increase incoming threat pressure.
- High surveillance:
  - Better awareness/consistency, but shifts policy budget from other priorities.
- Frequent field deployment:
  - Enables relay/local interventions, but you lose command-authority verbs while deployed.
- Queue too much fabrication during stress:
  - Throughput slows and recovery can lag if logistics pressure rises.

## 8) If It Starts Feeling Confusing Again

- Run `STATUS FULL`.
- Run `HELP <TOPIC>` for the command family you are using.
- Return to the cycle:
  1. observe (`STATUS...`)
  2. one deliberate change
  3. `WAIT`
  4. reassess
