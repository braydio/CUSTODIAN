
Yes — **resources should mostly require traveling away from the compound**, but I would not make that true immediately for V1.

Best structure:

```text
Compound = staging / fabrication / defense / storage
Nearby perimeter = tutorial scraps + emergency fallback
Away maps = real resource income
```

## My recommendation

The compound should have **limited, low-grade, non-respawning resources**:

* broken crates
* deadfall / ruined blackwood
* collapsed wall rubble
* old machine wreckage
* exposed scrap piles

That lets the player learn chopping/mining/salvaging without needing a whole expedition loop first.

But the **actual resource economy** should come from away sites:

* ruined forest groves
* old battlefield wreckage
* collapsed industrial corridors
* ore seams under dead cities
* crashed Custodian-era machines
* corrupted fab depots
* abandoned outposts

This fits CUSTODIAN better than “go chop trees next to your base forever.”

## Why away maps are better

If resources are right beside the compound, the player’s decision is boring:

```text
Need turret → chop nearby tree → build turret
```

If resources are off-site, the decision becomes tactical:

```text
Need turret → choose risky salvage sortie → gather scrap → extract → build turret before next assault
```

That creates pressure, planning, and consequences.

## V1 implementation path

Do this in stages:

### Stage 1 — Compound test nodes

Add a few nodes inside or just outside the compound:

```text
3 ruined trees
2 ore/rubble deposits
2 wreckage salvage piles
```

These are for testing the mechanic. They should **not respawn**.

### Stage 2 — Perimeter resource patch

Add a small “compound perimeter” map or sub-area.

This is not a full expedition yet. It is basically:

```text
Leave compound gate → small exterior ruin zone → collect → return
```

This gives you the travel loop without building the full world map.

### Stage 3 — Resource expedition maps

Later, add actual expedition destinations:

```text
Blackwood Verge       → timber-heavy
Collapsed Foundry     → ore-heavy
Dead Convoy Field     → scrap-heavy
Signal-Wrecked Relay  → power components / rare salvage
```

Each map should have a **resource identity** so the player chooses where to go based on what the Fabricator needs.

## Important design rule

Do **not** make trees and ore feel like generic Minecraft resources.

For CUSTODIAN, these should be framed as:

```text
Tree chopping = cutting deadfall / petrified root / corrupted blackwood
Mining = extracting exposed ruin-metal / alloy vein / collapsed structural ore
Salvage = stripping dead machines / old defense wreckage / fab conduit remains
```

## The loop I’d aim for

```text
1. Compound warns: next assault is coming.
2. Player checks Fabricator needs.
3. Player chooses a resource site.
4. Player travels out.
5. Player gathers under danger.
6. Player returns with materials.
7. Player builds defenses / repairs systems.
8. Assault hits.
```

That is much stronger than keeping all harvesting inside the base.

## Final call

Yes: **real resources should require leaving the compound.**

But for implementation, start with:

```text
Compound = a few tutorial/development nodes
Perimeter = first actual harvesting area
Away maps = long-term resource economy
```

That gives you the mechanic now without forcing you to build the whole expedition system before the fab pipeline works.
