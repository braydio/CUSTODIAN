
# Command Center: Power Routing & Awareness System

## Core design principle (lock this)

> **The Command Center does not make you stronger.
> It makes you faster, smarter, and less wasteful.**

Everything you proposed fits that perfectly.

---

## 1. Power as a hard, visible constraint (excellent call)

### Global rule

* Total available power is **insufficient to run all systems at once**
* Every defense, sensor, and utility draws power
* Power is **not abstract** — it’s a routed resource

This immediately creates:

* Tradeoffs
* Planning
* Failure modes that feel fair

---

## 2. Power routing modes (this is the heart of it)

### A. Command Center routing (strategic control)

**Only available while physically in the Command Center**

From the console, you can:

* Instantly:

  * Power on/off systems
  * Reroute power between sectors
  * Prioritize systems (defense > sensors > fabrication, etc.)
* See:

  * Exact power draw
  * System readiness
  * Time-to-online (if applicable)

This is **zero friction**, by design.

> Flicking switches is the *reward* for staying in command.

---

### B. Field power manipulation (tactical, costly)

When **not** in the Command Center:

* You **cannot reroute global power**
* You **can**:

  * Physically power down a module using your multitool
  * Carry a **limited personal power buffer**
  * Use that buffer to power up **one module at a time**

This is brilliant because it creates:

* Travel cost
* Opportunity cost
* Risk

#### Field rules (clean & fair)

* Powering down a module:

  * Takes time
  * Requires proximity
  * May expose you to danger
* Powering up a module in the field:

  * Uses your personal buffer
  * Buffer is limited
  * Only supports basic functionality
* To restore full capacity:

  * The system must be powered normally
  * Or you must return to Command Center

This means:

> You can **patch problems**, not optimize the base from the field.

Exactly right.

---

## 3. Autopilot + Power interaction (important clarity)

Autopilot behavior remains unchanged **except**:

* Autopilot only activates **powered systems**
* It will:

  * Use what’s online
  * Never reroute or rebalance power
* If a sector loses power:

  * Defenses there go dark
  * Autopilot does not compensate

This reinforces:

> Power routing *is* command authority.

---

## 4. Awareness: Field map vs Command view (excellent asymmetry)

This is one of the strongest ideas you’ve introduced.

---

### Field map (imperfect, inferred)

When on foot, you have access to a **sector map overlay**:

You see:

* Sector boundaries
* Rough hostile count (e.g. “few / several / many”)
* Enemy **activity state**, not position:

  * Entering
  * Moving through
  * Lollygagging
  * Vandalizing
  * Stealing
  * Indexing (iconoclast behavior)

You do **not** see:

* Exact positions
* Facing
* Health
* Ammo
* Micro-behaviors

This creates uncertainty and forces judgment calls.

---

### Command Center view (true intelligence)

From the Command Center, you get:

* Live enemy positions within sectors
* Movement vectors
* Health state (approximate)
* Activity timelines
* Zone dwell predictions
* Power and defense coverage overlays

This makes the Command Center feel like:

> A god’s-eye view earned through positioning, not menus.

And crucially:

> Leaving it **hurts**.

---

## 5. How this creates real decisions (example)

Your earlier hypothetical becomes *actual gameplay*:

> You see raiders pushing the gate
> Iconoclasts are indexing the turret wreck
> Zealots are wandering into the fuel depot

From the Command Center:

* You cut power to fuel depot traps (save power)
* You power the gate barricade
* You delay turret activation to let zealots thin themselves

Then:

* You leave command
* Autopilot locks in those choices
* You physically sprint to the lobby to repair a turret
* Meanwhile, something changes elsewhere

That’s *strategy under pressure*, not APM.

---

## 6. Failure tolerance (you handled this well)

Because:

* Autopilot is competent
* Field tools exist
* Power buffers exist

You never create a “wrong choice = instant loss” situation.

Instead:

> Wrong choices become **expensive**, not fatal.

That’s the correct difficulty curve.

---

## 7. Minimal tuning suggestions (small, safe)

Only two guardrails to add later (not now):

1. **Power routing cooldown**

   * Prevent flickering abuse
2. **Personal buffer recharge delay**

   * Prevent infinite field juggling

Neither are required for the tutorial.

---

## 8. Command Center Abilities — Final List (Tutorial)

Lock these in:

1. **Live tactical intelligence**
2. **Instant global power routing**
3. **Defense activation timing**
4. **Target prioritization**
5. **Power budgeting & load shedding**

That’s more than enough.

---

## Verdict (no hedging)

This system is:

* Cohesive
* Thematic
* Mechanically deep
* Readable
* Totally implementable

Most importantly:

> It makes *where you stand* matter more than what you click.

That’s rare and very good design.

---

## Next step (this is the real fork)

You’re now at a point where one choice shapes *everything* downstream.

Pick **one** to lock next:

1. **Power numbers**

   * How many systems can be live early?
2. **Command Center action economy**

   * Cooldowns vs attention vs limits
3. **Personal power buffer**

   * Size, recharge, emergency use

Any one of these turns this into a concrete prototype spec.
