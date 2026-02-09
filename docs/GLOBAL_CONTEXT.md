This global context file details the relationship between the persistent Hub World and the transient Campaign Worlds

1. **States the structure precisely** (to make sure we lock it correctly)
2. **Designates the systems that sit inside that structure** (scenarios, rewards, partial success)
3. **Describes a concrete implementation roadmap** that fits your existing engine without blowing it up


---

# 0. Canonical Structure (Locked)

## Terminology (Normalized)

- Contract: the interface object that formalizes the Custodian's operational commitment.
- Scenario: a generated configuration bundle surfaced by the hub.
- Campaign: an instantiated transient world created from a scenario.
- Reward: a hub mutation (unlock, capability, archive entry), justified by accumulated context.

## Two Worlds, Two Timescales

### 1. **The Hub (Persistent World)**

* Exists across campaigns
* Accumulates *meta-progress*
* Surfaces campaign scenario proposals
* Is the only place where permanence exists

### 2. **Campaign World (Transient World)**

* One per accepted campaign
* Has its own base, sectors, threats, rules
* Is **discarded** on completion / failure / abandonment
* Cannot be revisited

> The campaign world is *expendable*.
> The hub world is *historical*.

This distinction is critical and correct.

---

## State Transitions (Authoritative)

```
HUB
 ├─ generate campaign scenario proposals
 ├─ player selects scenario
 └─ ACCEPT → instantiate CampaignWorld

CAMPAIGN WORLD
 ├─ run expeditions
 ├─ collect loot / progress victory condition
 ├─ WIN | LOSE | ABANDON
 └─ RETURN → apply rewards → destroy campaign state

HUB (mutated)
```

There is **no free travel**.
There is **no shared map**.
There is **no rollback**.

---

# 1. Campaign Scenarios (Procedural, Rated, Selectable)

This replaces the idea of “worsening conditions over time” with something *cleaner*.

## Campaign Scenario Definition

A scenario is a **contract interface**, not a social fiction.

### Scenario Fields (Spec)

```python
CampaignScenario:
  id
  difficulty_rating        # e.g. 1–5, descriptive not numeric-only
  biome / setting
  core_threat_type
  victory_condition
  constraints              # modifiers / rules
  reward_profile           # types + ranges
```

### Difficulty ≠ Linear Punishment

Difficulty controls:

* enemy density / aggression
* expedition risk
* resource scarcity
* victory condition complexity

But:

* you *choose* it
* higher difficulty → higher *potential* rewards
* not all rewards are strictly better

This gives **agency without power creep**.

---

## Victory Conditions (Procedural but Typed)

Victory conditions should be **structured templates**, not bespoke logic.

Examples:

* **Stabilization**

  * hold key sectors for X ticks
* **Recovery**

  * extract N artifacts of type Y
* **Neutralization**

  * eliminate / suppress threat source
* **Containment**

  * prevent escalation beyond threshold

Each campaign rolls:

* 1 primary condition
* 0–2 modifiers (time pressure, attrition, hidden info)

---

# 2. Rewards: Two Categories, Cleanly Separated

This is the most important correction you made, and it’s right.

---

## A. Campaign Rewards (Hub-Persistent)

These are granted **only at campaign resolution**.

They:

* unlock things at the Hub
* permanently modify future possibilities
* are *the real progression*

### Campaign Reward Types

These should be **thematically tied to the victory condition**.

Examples:

#### 1. Hub Unlocks

* new scenario archetypes
* new difficulty tiers
* new victory condition templates

#### 2. Meta-Upgrades

* increased campaign slot count
* better scenario intel before acceptance
* reduced penalties for abandonment

#### 3. Archive / Knowledge Entries

* unlock lore
* unlock *interpretive context* for future scenarios
* affect final evaluation / ending

> These rewards answer:
> **“What does the Hub learn from this campaign?”**

---

## B. Expedition Loot (Campaign-Scoped)

These exist **only inside the active campaign**.

They are:

* tools to complete the operational commitment
* not progression in themselves

### Expedition Loot Types (Locked)

1. **Upgrades (Campaign-Only)**

   * defense improvements
   * efficiency boosts
   * local tech
   * discarded at campaign end

2. **Consumables**

   * emergency reroutes
   * temporary suppressions
   * one-time rescues

3. **Victory Condition Advancement Items**

   * keys
   * data fragments
   * control nodes
   * partial objectives

These are **procedurally themed** to the campaign.

---

# 3. Partial Success / Incomplete Victories (Both Levels)

This is where your design gets teeth without cruelty.

---

## A. Campaign-Level Partial Victory

Campaigns do **not** need binary outcomes.

### Resolution States

* **Complete Victory**

  * full hub rewards
* **Partial Victory**

  * reduced or altered hub rewards
* **Failure**

  * no reward, but *recorded*
* **Abandonment**

  * penalties, but sometimes strategic

### Example

Victory condition: *Recover 3 Archives*

* Recovered 3 → full reward
* Recovered 2 → partial reward
* Recovered 1 → minor unlock
* Recovered 0 → failure

This encourages:

* cutting losses
* tactical withdrawal
* risk assessment

---

## B. Expedition-Level Partial Completion

Same logic, smaller scale.

An expedition might:

* retrieve a damaged artifact
* lose part of the payload
* extract intel but not material

Which then feeds into:

* partial progress toward campaign victory
* degraded rewards
* new constraints

---

# 4. How This Fits Your Existing Engine (Important)

You do **not** need to rewrite what you’ve built.

### What Changes

* `GameState` becomes **CampaignState**
* Hub gets its own **HubState**
* CampaignState is instantiated *from* HubState
* On resolution:

  * produce a `CampaignOutcome`
  * apply it to HubState
  * discard CampaignState

### What Stays the Same

* terminal command processing
* deterministic ticks
* assault logic
* expedition logic
* transient bases / sectors

This is a **layering change**, not a rewrite.

---

# 5. Concrete Roadmap (Ordered, Buildable)

## Phase 1 — Structural Split

* Introduce `HubState`
* Wrap current world sim as `CampaignState`
* Implement accept / resolve flow (no rewards yet)

## Phase 2 — Scenario Generator

* Implement `CampaignScenario` templates
* Difficulty-based parameter scaling
* Scenario selection UI (terminal list)

## Phase 3 — Campaign Rewards

* Add Hub unlocks
* Add persistent capability flags
* Track campaign history

## Phase 4 — Partial Victory System

* Resolution grading
* Reward scaling
* Abandonment rules

## Phase 5 — Thematic Procedural Rewards

* Tie reward profiles to victory conditions
* Add incomplete / degraded artifacts
* Let the Hub remember *how* you won

---

# 6. Why This Is Strong (Reality Check)

This structure gives you:

* **Finite, winnable arcs** (campaigns)
* **Long-term meaning** (hub persistence)
* **Procedural replayability without grind**
* **Failure that still informs history**
* **A natural endgame** (Hub saturation / closure)

And — most importantly —

> The player is not accumulating power.
> They are accumulating *context*.

That’s rare, and it fits your tone perfectly.

---

If you want next, the best follow-up would be one of:

* a formal `CampaignScenario` + `CampaignOutcome` data model
* terminal command flow for accepting / abandoning campaigns
* or a concrete tutorial campaign (airfield) rewritten using this structure as the template

This is no longer fuzzy. You’ve got a real game shape now.
