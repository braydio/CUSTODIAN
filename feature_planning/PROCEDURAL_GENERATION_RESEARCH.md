# Procedural Description Generation in CUSTODIAN: Deterministic Event Logic with Constrained, High-Variation Terminal Text

## Repo-derived constraints

The repo’s current “spine” is a command-driven world simulation with a terminal-first UI, where **simulation state is authoritative** and presentation is downstream. That separation is already visible in the structure: `GameState` (authoritative world state), `step_world` (authoritative tick), and terminal `/command` processing that returns a `CommandResult` payload with a primary line plus optional detail lines (`text`, `lines`, `warnings`). The browser terminal is explicitly a thin client that posts commands and renders the returned lines rather than inferring changes client-side.  

A concise list of **design constraints & invariants** that matter directly for event + description generation:

- **Knowledge-first, reconstruction-first tone and progression**: the “north star” is preservation/reconstruction rather than extermination, and “knowledge changes what exists” rather than acting as XP. (Design intent is explicit in `docs/Broad_Overview_Design_Rules.md`.)  
- **Static, sectorized base form factor is locked**: the base is not an infinite builder; it’s a fixed/sectorized outpost where capability loss matters more than “HP.” (`docs/Broad_Overview_Design_Rules.md`, `docs/PROJECT_MAP.md`, and the current Phase 1 sector set in `game/simulations/world_state/core/config.py`.)  
- **Terminal-first interface; minimal, scannable, operational output**: “terse, grounded output,” all-caps conventions for STATUS, and “avoid verbose narration or speculative text.” (`docs/_ai_context/AI_CONTEXT.md`, `docs/README.md` and the actual command outputs in `terminal/commands/status.py` and `terminal/commands/wait.py`.)  
- **Time advances only via explicit operator action in terminal mode**: STATUS is read-only; WAIT/WAIT NX advance time in discrete ticks (5 ticks per WAIT unit) and emit observed lines. (`docs/_ai_context/AI_CONTEXT.md`, `game/simulations/world_state/docs/terminal-repl.md`, `terminal/commands/wait.py`.)  
- **Authority is location-/mode-based**: command/field asymmetry is enforced in the processor (e.g., field mode denies FOCUS/HARDEN/SCAVENGE). (`docs/_ai_context/AI_CONTEXT.md`, `terminal/processor.py`, plus move/deploy/return support.)  
- **Information degradation is a hard rule (not vibes)**: COMMS state drives fidelity: `FULL > DEGRADED > FRAGMENTED > LOST`. STATUS is “filtered truth” (never lies), WAIT is “filtered inference” (may be wrong at low fidelity but must remain plausible). STATUS certainty must always be ≥ WAIT certainty at the same fidelity. STATUS must never imply trends; trend/interpretation is WAIT-only. (`docs/INFORMATION_DEGRADATION.md` and implemented in `terminal/commands/status.py` and `terminal/commands/wait.py`.)  
- **Output composition rules are strict**: fixed section ordering for STATUS; WAIT output order is primary line then detail lines; WAIT may include at most one interpretive line per WAIT; LOST fidelity suppresses detail lines; FRAGMENTED suppresses subsystem naming and constrains assault signaling. (`docs/INFORMATION_DEGRADATION.md`, `terminal/commands/wait.py`.)  
- **Failure is latched and changes command affordances**: when COMMAND breach or archive loss limit hits, the session latches failure and only RESET/REBOOT are accepted, with a fixed failure phrasing strategy. (`terminal/processor.py`, `core/state.py`, `game/simulations/world_state/docs/terminal-repl.md`.)  
- **Damage model is structure-level, sectors are an aggregate view**: structures are in one of `OPERATIONAL / DAMAGED / OFFLINE / DESTROYED`, and sectors (in STATUS) are derived from structures (damaged structure forces sector “DAMAGED” aggregation). (`docs/SystemDesign.md` “Locked Decisions”; implemented in `core/structures.py` and `GameState.snapshot()` in `core/state.py`.)  
- **Repairs cost resources and advance on ticks**: repairs are explicit tasks tracked as `active_repairs` with per-tick decrement; repair visibility itself is fidelity-bound. (`core/repairs.py`, `terminal/commands/repair.py`, `terminal/commands/status.py`.)  

### How events are represented now

Events in the current world-state simulation are “ambient events” defined as **callable effects** applied to `GameState` + a chosen `SectorState`.

- **Event definition shape (current)**: `AmbientEvent(name, min_threat, weight, cooldown, sector_filter, effect, chains=...)`. (`game/simulations/world_state/core/events.py`.)  
- **Catalog construction**: `EVENT_ARCHETYPES` is a list of dict archetypes (key, min_threat, weight, cooldown, tags, optional min_damage/max_power, effect fn, and naming templates). `build_event_catalog()` binds faction-profile label/tech into templates and builds a list of `AmbientEvent`s, stored in `state.event_catalog`. (`core/events.py`, `core/factions.py`.)  
- **Selection**: candidates are all (event, sector) pairs that pass `can_trigger()` (threat threshold, sector filter, cooldown). A probability gate based on ambient threat (and a hangar damage bonus) decides whether *an* event triggers this tick. Chosen event uses weight replication and `random.choice`. (`core/events.py`, `core/config.py`.)  
- **State changes**: effects directly mutate scalar state and sector metrics (damage/alertness/power/occupied), may alter the assault timer, and may add persistent effects via `add_sector_effect` / `add_global_effect` that decay over time and apply per tick. (`core/events.py`, `core/effects.py`, `core/state.advance_time()`.)  

### What the simulation needs from events (as implemented)

The simulation’s “needs” from events are already evident in what the effects mutate and what the terminal layer observes:

- **Timing and pacing**: events are constrained by `min_threat`, per-(event, sector) cooldown tracking (`state.event_cooldowns`), and a probability gate tied to ambient threat. (`core/events.py`.)  
- **State mutation surface** (authoritative outcomes):  
  - Per-sector: `damage`, `alertness`, `power`, `occupied`, `effects`, `last_event`. (`core/state.py`, `core/events.py`, `core/effects.py`.)  
  - Global: `ambient_threat`, `assault_timer`, `global_effects`. (`core/state.py`, `core/events.py`.)  
- **Observability hooks** (what player output currently keys on): `sector.last_event` + `state.event_cooldowns` for event detection, COMMS status for fidelity, repair completion lines, and assault timer “warning window” behavior. (`terminal/commands/wait.py`, `terminal/commands/status.py`.)  
- **Persistence**: sector/global effects are persistent/decaying; repairs are persistent and complete on ticks; assaults have a lifecycle and apply damage to structures at the end. (`core/effects.py`, `core/repairs.py`, `core/assaults.py`.)  

## Recommended architecture

What you want—**explicit, deterministic event logic** with **highly variable but never-lying textual presentation**—maps cleanly onto the repo’s existing separation. The key is to introduce one additional intermediate artifact between simulation and text: a **canonical event record** and a **canonical “narrative surface”** that enumerates allowed facts and redactions.

A concrete pipeline that matches your example structure and fits the current code layout:

1. **Event selection / instantiation (seeded)**  
   - Use a deterministic RNG owned by the simulation (e.g., `state.sim_rng`) for: ambient event trigger tests, weighted selection, assault timer values, assault duration, tactical bridge randomness, scavenge yields, etc.  
   - Produce an `EventInstance` record when an event triggers (event id/key, tick, sector id/name, and *pre/post* or explicit deltas).  
   - Important: the event record is not prose; it is an audit-friendly artifact.

2. **Simulation resolution (authoritative state transition)**  
   - Apply the event’s effect function(s) to `GameState`.  
   - Apply per-tick decay/effects (`advance_time()` already does this).  
   - Resolve repairs and assault lifecycle.  
   - This stage remains the only place that changes truth.

3. **Observability layer (fidelity + authority + location)**  
   - Compute a `Fidelity` from COMMS status using the same mapping already embedded in `STATUS`/`WAIT`:  
     - `COMMS STABLE → FULL`  
     - `COMMS ALERT → DEGRADED`  
     - `COMMS DAMAGED → FRAGMENTED`  
     - `COMMS COMPROMISED → LOST`  
   - Reduce `EventInstance` and other tick outputs (repair completion, assault warning/start/end, movement task completion) into an `ObservedSignal` list that contains only facts the player is allowed to perceive.  
   - This is where you enforce “STATUS certainty ≥ WAIT certainty,” “no subsystem names below DEGRADED,” “LOST yields no detail lines,” etc. It should be a pure function.

4. **Description generation (variable text, constrained by #2 and #3)**  
   - Take each `ObservedSignal` and render it into 0–2 terminal lines using a seeded text RNG that is **separate from the simulation RNG**.  
   - All text is generated from curated templates/grammar and typed slots; no free-form hallucination.  
   - Variation comes from choosing among equivalent templates/synonyms, not from inventing new facts.

5. **Output formatting (terminal UI surface)**  
   - Enforce canonical ordering and suppression rules: primary line first (`TIME ADVANCED.` / `TIME ADVANCED xN.`), then event/warning lines, then at most one interpretive line.  
   - Keep all caps and bracket tags exactly as defined.  
   - Retain immediate-duplicate suppression behavior (already implemented in `cmd_wait_ticks`).  

## Schemas (event + narrative surface)

Below are schemas that align with your current implementation while adding the minimum structure needed to support variable narration safely.

```python
# Canonical simulation artifact (authoritative, deterministic)
@dataclass(frozen=True)
class EventDef:
    id: str                  # e.g. "power_brownout"
    min_threat: float
    weight: int
    cooldown_ticks: int
    tags: set[str]           # mirrors sector tags usage
    # Optional filters to match current _build_sector_filter:
    min_damage: float | None = None
    max_power: float | None = None
    # Deterministic effect function:
    apply: Callable[[GameState, SectorState], None]
    # Optional deterministic chaining (still sim-owned):
    chain_ids: list[str] = field(default_factory=list)

@dataclass(frozen=True)
class EventInstance:
    instance_id: str         # stable id per trigger (tick + counter)
    event_id: str            # EventDef.id
    tick: int                # state.time when applied
    sector_id: str           # e.g. "PW"
    sector_name: str         # e.g. "POWER"
    # Outcome facts for downstream use (debugging + observability)
    deltas: dict[str, Any]   # e.g. {"sector.power": -0.2, "sector.alertness": +0.6, "add_effect": "power_drain"}
    # Optionally: pre/post snapshots for dev tooling (not required for runtime)
```

```python
# Presentation artifact (what the renderer is allowed to express)
class Fidelity(Enum):
    FULL = "FULL"
    DEGRADED = "DEGRADED"
    FRAGMENTED = "FRAGMENTED"
    LOST = "LOST"

@dataclass(frozen=True)
class NarrativeSurface:
    fidelity: Fidelity
    # What kind of signal this is (maps to bracket tags)
    channel: Literal["EVENT", "WARNING", "ASSAULT", "STATUS_SHIFT", "REPAIR", "SYSTEM"]
    # Allowed facts (already redacted as needed)
    facts: dict[str, Any]
    # Required content guarantees
    must_include: set[str]   # e.g. {"channel_tag", "actionable_keyword"}
    # Prohibitions / redactions
    forbid: set[str]         # e.g. {"sector_name", "numbers", "precise_counts"}
    # Confidence is a presentation property (not a sim property)
    confidence: Literal["confirmed", "reported", "possible", "no_signal"]
```

The practical rule: **the generator never sees raw `GameState`**, only `NarrativeSurface`. That prevents “cool prose” from accidentally leaking banned information.

## Generation strategy

A hybrid of **templating + grammar + typed slot-filling** fits your constraints better than runtime free-form generation, because it is deterministic, testable, and debuggable.

A useful external pattern here is **author-focused generative text via grammars**, exemplified by entity["people","Kate Compton","tracery creator"]’s Tracery ecosystem (and ports like Allison Parrish’s Python port). These systems generate variation through rule expansion and modifiers, and they can expose a “trace” to debug why a line appeared. citeturn12search0turn12search10  

Another useful pattern is treating narrative scripting as **middleware** that “slots into your own game and UI,” as described for entity["organization","Inkle Studios","interactive narrative studio"]’s Ink: text is primary, logic is inserted, and the runtime returns lines/choices that the game renders. That conceptual boundary (logic vs rendered text) maps closely to your `CommandResult` contract and the “simulation authoritative” rule. citeturn12search6turn12search9  

A concrete strategy for CUSTODIAN:

- **Template families per channel**: EVENT/WARNING/ASSAULT/STATUS_SHIFT/REPAIR each gets a small family of templates with controlled synonym sets.  
- **Typed slots, not free strings**: slots like `PHENOMENON`, `SYSTEM`, `INTENSITY`, `EFFECT_CLASS` are enums or controlled vocab.  
- **Fidelity gates are compile-time constraints**: templates declare `min_fidelity` and `forbidden_tokens`. Example: a template that includes `{system}` cannot be eligible under FRAGMENTED.  
- **Bounded length**: each template declares `max_chars` (or computed), and the renderer picks the shortest that still satisfies “must include.”  
- **Bounded randomness without repetition**: keep a rolling window in a `TextVariantMemory` keyed by (event_id, channel, fidelity) to avoid repeating the same template/synonym choices in adjacent outputs.  
- **Two independent seeds**:  
  - `event_seed` (simulation RNG): controls what happens.  
  - `description_seed` (text RNG): controls which phrasing is chosen among equivalent renderings.  
  - Derive per-line text RNG via a stable hash like `hash(description_seed, instance_id, channel)` so replay is deterministic and testable.

This achieves what you asked for: you explicitly author events and outcomes, while the textual surface stays fresh and non-repetitive without ever contradicting truth.

## Consistency + observability rules

Your repo already encodes the fundamental distinction: **STATUS is filtered truth; WAIT is filtered inference** (`docs/INFORMATION_DEGRADATION.md`) and the implementation in `cmd_status`/`cmd_wait` follows it. The architecture above formalizes this into enforceable rules:

- **Single source of truth**: only simulation writes truth (`GameState`, `EventInstance`, structure state transitions, resource deltas). The generator cannot mutate state.  
- **Observability is a pure projection**: `observe(state, event_instance, fidelity, player_mode) -> NarrativeSurface[]`. If it’s not in `NarrativeSurface.facts`, it cannot be said.  
- **Fidelity-driven redaction is keyed off COMMS status** exactly as already implemented in `STATUS` and `WAIT`.  
- **No contradictions rule becomes structural**:  
  - Templates are only allowed to reference `facts` keys.  
  - Facts keys are derived from authoritative event outcomes.  
  - Therefore, the generator cannot invent “extra outcomes.”  
- **Uncertainty language is not creative writing; it is a mapping table**:  
  - `FULL → confirmed/detected`  
  - `DEGRADED → reported/appears`  
  - `FRAGMENTED → possible/may`  
  - `LOST → no-signal`  
  This mirrors the current wording shift in `terminal/commands/wait.py` and the canonical degradation spec.  
- **Actionability without advice**: “critical actionable information” in CUSTODIAN’s output is primarily: *that a meaningful change occurred*, *which system class is implicated (if allowed)*, and *that stability/hostility is worsening (at most one interpretive line)*. You preserve clarity by ensuring at least one of these appears when meaningful changes occur, while still forbidding explicit recommendations (which the docs prohibit).  
- **Debuggability is a first-class mechanism**: every generated line should carry a debug trace record in dev mode: template id, chosen synonyms, and the fact keys used. Tracery-style systems explicitly support traces of expansion; adopting that idea for your template engine makes “why did this text appear?” answerable. citeturn12search10turn12search0  

## Examples

Single canonical event: **Power brownout** (maps to `power_brownout` in `game/simulations/world_state/core/events.py`, which reduces power, increases alertness, and applies a decaying `power_drain` effect).

To satisfy “same event seed → same state change” and “different description seeds → different text,” each example below treats:

- **Event seed**: drives that the event triggers and picks the target sector (simulation RNG).  
- **Description seed**: drives phrasing choice only (text RNG).  

For readability, each example shows three layers: canonical outcome (debug), observability surface, and terminal output.

### Example A

**Event seed:** `4242`  
**Description seed:** `1001`  
**Fidelity:** FULL (COMMS stable)

**Canonical outcome (authoritative; debug view)**  
- Event: `power_brownout`  
- Sector: `POWER`  
- State deltas (illustrative of the effect function):  
  - `POWER.alertness += 0.6`  
  - `POWER.power -= 0.2` (clamped to ≥ 0.4)  
  - `POWER.effects += power_drain(severity=1.4, decay=0.04)`

**Narrative surface (allowed facts)**  
- channel: `EVENT`  
- facts: `{ phenomenon: "brownout", system: "power", confirmation: "detected" }`  
- forbid: `{numbers}`

**Generated terminal output (FULL)**  
```
TIME ADVANCED.

[EVENT] POWER BUS INSTABILITY DETECTED
[STATUS SHIFT] SYSTEM STABILITY DECLINING
```

### Example B

**Event seed:** `4242` (same authoritative event and deltas as Example A)  
**Description seed:** `9009`  
**Fidelity:** FULL

**Narrative surface** (same facts as Example A)

**Generated terminal output (FULL; different realization)**  
```
TIME ADVANCED.

[EVENT] LOCAL BROWNOUT CONFIRMED
[STATUS SHIFT] SYSTEM STABILITY DECLINING
```

### Example C

**Event seed:** `4242` (same authoritative event and deltas)  
**Description seed:** `1001`  
**Fidelity:** DEGRADED (COMMS alert)

**Observability changes (what gets omitted / softened)**  
- Subsystem naming is still allowed, but certainty must be hedged (“REPORTED”) and directional verbs softened.  
- Still no numeric values in WAIT output.

**Generated terminal output (DEGRADED)**  
```
TIME ADVANCED.

[EVENT] POWER FLUCTUATIONS REPORTED
[STATUS SHIFT] SYSTEM STABILITY APPEARS TO BE DECLINING
```

### Example D

**Event seed:** `4242`  
**Description seed:** `9009`  
**Fidelity:** FRAGMENTED (COMMS damaged)

**Observability changes (stronger redaction)**  
- No subsystem names.  
- Event becomes generic (“IRREGULAR SIGNALS DETECTED”).  
- Trend language becomes “MAY” level.

**Generated terminal output (FRAGMENTED)**  
```
TIME ADVANCED.

[EVENT] IRREGULAR SIGNALS DETECTED
[STATUS SHIFT] INTERNAL CONDITIONS MAY BE WORSENING
```

### Example E

**Event seed:** `4242`  
**Description seed:** `1001`  
**Fidelity:** LOST (COMMS compromised)

**Observability changes**  
- No detail lines (optionally a rare `[NO SIGNAL]` line, per spec).  

**Generated terminal output (LOST)**  
```
TIME ADVANCED.
```

These examples preserve your hard rules: text never contradicts the underlying outcome, never invents new actionable facts, never emits advice, and degrades information exactly as your canonical degradation rules specify.

## Implementation plan

A minimal viable path that fits your current implementation and avoids UI creep:

**Minimal viable path (tight loop, high confidence)**  
1. **Make simulation randomness explicit and testable**  
   - Add `state.sim_rng` (a `random.Random`) seeded once at session start.  
   - Replace direct `random.*` calls in `events.py`, `assaults.py`, and `scavenge.py` with `state.sim_rng.*` so replay with `event_seed` is stable.

2. **Replace “event name string as the only record” with a canonical `EventInstance`**  
   - When an event triggers, create an `EventInstance` with `event_id`, `tick`, `sector_id`, `sector_name`, and a small “delta facts” payload (at least: phenomenon/system class/severity class).  
   - Store it in `state.last_tick_events` (cleared each tick) and/or a bounded ring buffer for debugging.

3. **Introduce an explicit observability function**  
   - Implement `fidelity = fidelity_from_comms(state)` once (you already have it duplicated in WAIT/REPAIR; centralize).  
   - Implement `observe_event(event_instance, state, fidelity) -> NarrativeSurface[]`.  
   - Encode prohibitions directly from `docs/INFORMATION_DEGRADATION.md` (LOST: no details; FRAGMENTED: no subsystem names; etc.).

4. **Implement a constrained text renderer**  
   - Implement a lightweight template engine in Python (you can start with plain format-strings + synonym sets).  
   - If you want a grammar-based expansion approach, a Tracery-style library can be used, but keep it sandboxed: it should expand only from safe, typed slot values. citeturn12search0turn12search10  
   - Add `state.text_seed` (session-level) and derive per-event text RNG with a stable hash of `(text_seed, event_instance_id, channel)`.

5. **Wire into WAIT output without changing the command contract**  
   - Replace `_format_event_line`, `_format_warning_line`, `_format_assault_line`, `_format_status_shift`, and `_format_repair_line` with calls to the renderer fed by `NarrativeSurface`.  
   - Keep the existing suppression logic (immediate-duplicate suppression and “no more than one interpretive line”).

6. **Add narrow, high-value tests**  
   - Snapshot tests per fidelity ensuring:  
     - LOST emits no detail lines.  
     - FRAGMENTED never includes sector names or subsystem tokens.  
     - WAIT emits at most one interpretive line.  
     - STATUS never includes trend verbs.  
   - Property-style tests for “forbidden tokens” (numbers at low fidelity, sector names in summaries, etc.).  

**Extensions that stay consistent with your constraints**  
- **“WHY” / “TRACE” dev-only introspection**: a command that returns the last N `EventInstance`s and their generation traces (template ids + slot values) in a compact format. This strengthens debugging and tuning without adding UI surfaces.  
- **Event taxonomy + severity normalization**: formalize a small enum for phenomenon classes (power, intrusion, structural, comms) so you can select language consistently and maintain tone.  
- **Avoid repetition across sessions**: incorporate a “recent phrase memory” per event type so repeated brownouts do not spam identical lines, while still keeping deterministic replay when the same text seed is used.  
- **Optional ink-like authored “micro-scripts” for rare cases**: if you later need multi-line scripted sequences (e.g., boot sequences, tutorial callouts), Ink provides a model for text-first scripts with embedded logic and a runtime that yields lines in order. This is compatible with your “text is downstream” rule because Ink content still consumes a known state and returns deterministic outputs. citeturn12search6turn12search9  
- **Storyteller-style pacing knobs as configuration, not prose**: your current system already resembles a “storyteller” in the sense that global pressure and timers influence event frequency and severity. If you later want named pacing profiles (steady vs spiky), keep them as parameter sets (rates, cooldown multipliers) rather than narrative logic—similar to how colony sims expose storyteller choices as event pacing/difficulty layers. citeturn12search18turn12search15
