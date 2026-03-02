# Game Identity Lock

> **Permanently locked design decisions. These are not up for debate or iteration.**

This document captures the core identity of CUSTODIAN as a defensive machine simulation. It serves as a filter against feature creep and scope drift.

---

## This IS (Core Identity)

- **Fixed facility footprint** — static command post, not a growing colony
- **Defensive geometry** — interior layout matters for tactical defense
- **Power/logistics as hard constraints** — you cannot power/fortify everything
- **Assault-centric design** — the core gameplay loop is defend → repair → learn
- **The base is a machine** — you are chief infrastructure architect under siege

---

## This IS NOT (Anti-Patterns)

These are explicitly rejected design directions:

| Rejected | Why |
|----------|-----|
| Colony sim | No colonists, no moods, no social graphs |
| RimWorld-style open sandbox | Fixed footprint, not infinite expansion |
| Population management | Only the Custodian + automated systems |
| Farming/comfort systems | Irrelevant to defensive machine identity |
| Infinite wall spam | Defense slots per sector are capped |

---

## Spatial Scope

### Current State
- 9 macro-sectors (fixed footprint)
- 12x12 tactical grid per sector (1,296 total cells)

### Target State
- 8-9 macro-sectors (fixed footprint)
- 30-40x tactical grid per sector (7,200-14,400 cells per sector)
- Connected by corridors/chokepoints
- Total footprint comparable to mid-sized RimWorld map, but defensive purpose

### Scope Justification

> "You can have 'RimWorld-sized total space' without becoming RimWorld. The difference is what the space is for."

The space exists for:
- Turret placement strategy
- Wall angle and choke point design
- Cover geometry
- Line-of-sight tactical decisions
- Attack vector awareness

---

## Guardrails (Permanent Constraints)

These constraints are **locked** and cannot be removed without explicit design review:

### Guardrail A: No Colonists

Only the Custodian and automated systems exist in the facility. No human population to manage.

### Guardrail B: Defense Slot Caps

Each sector has a maximum number of defense structures. You cannot turtle infinitely by spamming turrets.

### Guardrail C: Power Routing is Hard Constraint

Space is abundant. Power is not. You cannot power everything. This prevents turtling and forces prioritization.

### Guardrail D: Expansion Increases Vulnerability

Adding more sectors/structures increases your attack surface, not your safety. This is the inverse of colony sim where more buildings = more safety.

---

## Camera & Presentation

### Approved Features
- Isometric or fixed camera
- Zoom capability
- Sector focus mode
- Floor slicing (future enhancement)

### Not Approved
- Free camera (at least initially)
- Full physics (avoid early)

---

## Design Lineage

This document was created following an external design review (2026-02) that clarified:

- The distinction between "base expansion" and "intra-sector depth and layout control"
- The philosophical difference between a defensive machine and a colony
- The engineering challenges of larger interior spaces (pathfinding, performance, turret targeting)

---

## Related Documents

- `CORE_DESIGN_PRINCIPLES.md` — foundational design rules
- `GRID-SURFACE-DESIGN.md` — spatial structure implementation
- `ASSAULT_DESIGN.md` — assault mechanics
- `POWER_SYSTEMS.md` — power constraint system
