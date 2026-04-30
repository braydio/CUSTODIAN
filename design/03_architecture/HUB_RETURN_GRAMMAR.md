# HUB RETURN EVENT GRAMMAR

**Status:** draft
**Parent:** HUB_DOCTRINE.md
**Last Updated:** 2026-04-22

---

## Overview

Defines how each return to the hub communicates what the player learned or lost in the previous campaign. Every return should answer: **What kind of truth did this campaign make visible?**

---

## 1. Campaign Outcome Categories

| Category | Meaning | Chroma Effect | Fidelity Dimensions Affected |
|----------|---------|---------------|---------------------------|
| **Hypothesis Validated** | A theory was confirmed | Authority (gold) | Legibility + Access |
| **Hypothesis Invalidated** | A belief was proven wrong | Temporary dimming → synthesis reveals | Legibility (clarifies what remains) |
| **Hypothesis Survived** | Uncertainty preserved | Persistence (green) | Access (paths open) |
| **Hypothesis Destroyed** | A truth was lost forever | Sacrifice (red) | Instability + (can recover) |
| **New Discovery** | Something unknown was learned | Cognition (blue/violet) | Legibility + Scenario intelligence |
| **Total Revelation** | All truths converged | Synthesis (white) | All + Chromatic pressure spike |

---

## 2. Return Event Structure

Each return follows this pattern:

```
1. Arrival
   - Player returns via Custodian's Approach
   - Ambient state check (current chroma domains)
   
2. Transition
   - Brief cinematic or ui moment
   - Category announced (not spelled out - implied)
   
3. Mutation
   - One or more hub elements change
   - Change is proportional to outcome significance
   
4. Revelation
   - Player can now perceive something new
   - May unlock interpretation options
```

---

## 3. Mutation Types

### Chromatic (Visual)
- District color shifts
- Statue detail emerges
- Material differentiation
- Sky effects activate

### Spatial (Geometric)
- A path clears
- A view opens
- A collapsed structure reveals interior
- New access to district

### Interpretive (Narrative)
- A statue can now be identified
- A mural resolves into readable content
- A celestial event becomes visible
- A hypothesis becomes available for interpretation

### Mechanical (Optional)
- New scenario types become available
- Archive access expands
- (Avoid: don't make this about vendors/unlocks)

---

## 4. Fidelity Dimensions Raised Per Outcome

### Legibility Increases
- Hypothesis Validated
- Hypothesis Invalidated
- New Discovery
- Total Revelation

### Access Increases
- Hypothesis Validated (civic archives open)
- Hypothesis Survived (traversal paths open)
- New Discovery (observatories accessible)
- Total Revelation

### Instability Increases
- Hypothesis Destroyed (brief destabilization)
- Total Revelation (significant pressure spike)

---

## 5. Scenario Intelligence Evolution

Each return can improve campaign intelligence:

| Outcome | Intelligence Gain |
|---------|------------------|
| Hypothesis Validated | Confirms category patterns, narrows future proposals |
| Hypothesis Invalidated | Reveals false assumptions, expands unknowns |
| Hypothesis Survived | Preserves uncertainty, maintains options |
| Hypothesis Destroyed | Marks loss, future proposals acknowledge absence |
| New Discovery | Reveals new campaign category or relationship |
| Total Revelation | All prior campaigns now cross-reference |

---

## 6. Chromatic Pressure Impact

Each outcome affects `chromatic_pressure`:

| Outcome | Pressure Effect |
|---------|----------------|
| Hypothesis Validated | +10-15% (moderate gain) |
| Hypothesis Invalidated | +5% (clarification, not new signal) |
| Hypothesis Survived | +5% (uncertainty persists as signal) |
| Hypothesis Destroyed | +20% (destruction is unstable) |
| New Discovery | +10-15% (new information) |
| Total Revelation | +30-40% (massive spike) |

---

## 7. Example Returns

### Example 1: Hypothesis Validated

> Player completes a campaign that confirms a theory about the world's origins.

**Return:**
- Approach is unchanged (familiar)
- Road of Witnesses: gold flecks emerge in pediments
- Archive Heights: amber light in library windows
- Scenario proposals become more specific
- Pressure: +10%
- Narrative: "The archives speak your confirmation"

---

### Example 2: Hypothesis Destroyed

> Player completes a campaign where a critical truth was lost.

**Return:**
- Brief desaturation pulse (the world acknowledges loss)
- One statue crumbles in Witness sector
- A sealed door collapses permanently
- **BUT** — can be recovered in future campaign
- Pressure: +20% (unstable destruction)
- Narrative: "Something that was can no longer be read — yet"

---

### Example 3: New Discovery

> Player discovers an unknown phenomenon.

**Return:**
- Prism Margin: new sky refraction appears
- Archive Heights: observatory reveals new star pattern
- Cognition (blue/violet) spreads through architecture
- Scenario proposals now reference cross-domain patterns
- Pressure: +12%
- Narrative: "The sky has new writing"

---

### Example 4: Total Revelation

> Player completes final campaign, all truths converge.

**Return:**
- Massive chromatic surge across all districts
- Statues briefly regain full form before fragmenting
- Sky erupts in prismatic fire
- City becomes temporarily magnificent and actively failing
- Pressure: +35% (huge spike, likely triggers end-state)
- Narrative: "All truths speak at once — and the city struggles to hold them"

---

## 5. What NOT to Do

**No:**
- "You got a new weapon" notifications
- Vendor announcements
- Faction reputation updates
- Experience point displays

**Yes:**
- Environmental storytelling
- Subtle chromatic shifts
- Player-driven exploration to discover what changed

---

## 6. Implementation Notes

- Track `hub_state` dictionary with:
  - `active_domains`: Array of domain keys
  - `unlocked_views`: Array of viewpoint IDs
  - `revealed_hypotheses`: Array of hypothesis IDs
  - `district_states`: Dictionary per-district with per-prop-type restoration levels
- On return: evaluate campaign outcome → apply mutation → trigger revelation

### Granularity: Per-District + Per-Prop-Type

Each district tracks restoration state for prop types:
- Statues: silhouette → detail → pigment
- Materials: undifferentiated → differentiated
- murals: obscured → revealed → fully readable
- Structures: collapsed → cleared → accessible

---

## 7. Clarifications

- **No permanently lost truths** — lost truths can be recovered through specific campaigns
- **No maximum returns** — synthesis stage triggered by narrative, not count
- **Granularity:** Per-district AND per-prop-type within district

---

## 8. Related

- Parent: `HUB_DOCTRINE.md`
- Related: `HUB_CHROMA_PROGRESSION.md`, `HUB_SPATIAL_LAYOUT.md`
- Integrates with: Campaign system, hypothesis/knowledge system