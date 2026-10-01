# CUSTODIAN Persistent Recovery, Armament Registration, and Field Continuity Design

> **Status:** persistent design authority — future implementation target
> **Scope:** Custodian death/recovery, local recovery infrastructure, field-acquired equipment, recovered armory persistence, armament registration, deployment capacity, and registration progression
> **Related lore:** `design/03_world/lore/CUSTODIAN_MANDATE_AND_HUB.md`, `design/03_world/lore/CRECHE_AND_LOCKER_LORE.md`
> **Related systems:** `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`, `design/04_architecture/HUB_SYSTEM_META_PROGRESSION.md`, `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`
> **Runtime note:** current one-life Custodian game-over behavior is transitional and does not supersede this target design.

This document defines the intended relationship between:

- Custodian death and recovery
- local and fabricated recovery infrastructure
- field-acquired equipment
- recovered persistent inventory
- registered weaponry
- deployment loadouts
- equipment-loss behavior
- armament registration capacity
- registration-capacity progression
- the underlying continuity philosophy

It does not define the exact physical mechanism by which a Custodian is recovered, reconstructed, restored, replaced, or otherwise returned to operational service.

That ambiguity is intentional.

---

## 1. Core Design Principle

CUSTODIAN does not treat player death as a conventional reload.

A Custodian may die.

The **Custodian designation can nevertheless return to operational service** through surviving recovery infrastructure.

This does not mean the Custodian is an eternal metaphysical entity, nor does reality inherently require the Custodian to exist.

The relevant philosophical boundary is:

> **Custodian continuity is not an intrinsic law of the universe. It is an institutional continuity claim enforced through advanced Lattice-era infrastructure strongly enough to produce real physical and operational consequences.**

The Custodian institution was a late-stage human institution.

It developed procedures and machinery capable of resolving continuity ambiguity for practical purposes.

Its systems behave as though the currently recovered Custodian is the valid continuation of the designation because maintaining that operational continuity is what those systems were built to accomplish.

The game should not explain this mechanism in greater detail than necessary.

---

## 2. Death Is Not Normally Game Over

Operator death should normally be a **recoverable campaign event**, not a terminal game state.

The consequence depends on available recovery infrastructure.

### No Local Recovery Available

```text
Operator death
    ↓
Campaign failure or partial resolution
    ↓
Campaign outcome captured
    ↓
Designation recovered at Post
    ↓
Return reintegration
    ↓
Compound / Hub
```

Progress completed before death may still matter.

A death after completing part of a Contract does not automatically erase that work.

Campaign resolution may preserve:

- completed objectives
- synchronized evidence
- opened routes
- infrastructure changes
- faction consequences
- partial recoveries
- persistent Domain changes

Death is therefore a **failure condition**, not a rewind.

---

## 3. Local Recovery Infrastructure

Some Campaign Domains may contain recovery infrastructure capable of returning the Custodian to service without terminating the campaign.

This produces a second death path:

```text
Operator death
    ↓
Valid local recovery infrastructure found
    ↓
Designation recovery
    ↓
Return at local recovery point
    ↓
Campaign continues
```

The world does not reset.

Previously completed actions remain completed.

Previously consumed resources remain consumed.

Previously failed objectives remain failed.

Enemies, doors, structures, hazards, and other persistent local state follow their normal persistence rules.

The player has not loaded an earlier save.

**The Custodian returned.**

---

## 4. Recovery Infrastructure Classes

### 4.1 Existing Custodian Crèches

Some Domains may contain old Custodian recovery infrastructure.

These may be:

- functioning
- dormant
- damaged
- underpowered
- inaccessible
- repairable

Discovering one is strategically significant.

Restoring a local crèche may transform a dangerous long-form operation from a single-life expedition into a locally recoverable campaign.

A crèche is therefore infrastructure, not merely a checkpoint.

### 4.2 Fabricated Field Recovery Crèche

Later progression may allow the Custodian to fabricate a bounded **Field Recovery Crèche**.

This should be a meaningful infrastructure investment.

It should require some combination of:

- structural materials
- signal components
- memory-glass-derived components
- fabrication capability
- stable power
- suitable local continuity conditions
- a validated placement site

It must not function as a freely placeable combat respawn beacon.

A Field Recovery Crèche represents the decision:

> This operation matters enough to establish Custodian continuity infrastructure here.

Its fabrication and deployment should therefore carry a reasonable but consequential cost.

### 4.3 Designation Mooring

A lighter recovery structure may also exist.

Working name:

**Designation Mooring**

A Mooring is cheaper and more limited than a full Field Recovery Crèche.

Possible distinctions include:

- single-use or low-use capacity
- greater dependence on remote recovery infrastructure
- less resilience
- lower power requirement
- easier field deployment
- narrower valid placement conditions

The Mooring provides tactical recovery insurance without replacing the strategic value of full local recovery infrastructure.

---

## 5. Recovery Capacity Is Physical, Not an Arcade Life Counter

Local recovery infrastructure should not expose:

```text
LIVES: 3
```

If recovery is limited, the limitation should arise from infrastructure state.

Examples:

- recovery capacity
- stored recovery medium
- accumulated system degradation
- power demand
- damaged components
- coherence load
- required servicing

Player-facing presentation might instead show:

```text
FIELD RECOVERY CRÈCHE

STATUS: READY
RECOVERY CAPACITY: AVAILABLE
POWER: NOMINAL
```

or, after repeated use:

```text
FIELD RECOVERY CRÈCHE

STATUS: DEGRADED
RECOVERY CAPACITY: LIMITED
SERVICE REQUIRED
```

Exact mechanics can be tuned later.

---

## 6. Persistent Equipment Model

Equipment exists in three meaningful persistence states.

### 6.1 Field-Acquired

The player has physically acquired the item during the current deployment.

It may be used immediately.

It is not yet guaranteed to survive loss of the current Custodian.

Examples:

- scavenged rifles
- enemy heavy weapons
- recovered experimental equipment
- unfamiliar cross-continuity weapons
- unusual tools
- captured armaments

Field-acquired gear should be fun **immediately**.

The player does not need to return home before using a weapon they just found.

### 6.2 Recovered

The player successfully extracts the item to persistent Custodian storage.

It now exists in the **Recovered Armory** or equivalent persistent equipment inventory.

Recovered equipment remains available between deployments.

However, recovery alone does not make the item part of the Custodian designation.

An unregistered recovered weapon can still be lost if taken into the field and the Custodian dies while carrying it.

### 6.3 Registered

A recovered weapon may be assigned to the Custodian through an institutional registration process.

A registered weapon becomes part of the designation's recoverable armament provision.

Registration means the institution recognizes:

> The active Custodian is entitled to this armament assignment.

Registered equipment gains special persistence behavior after death.

Registration is intentionally scarce.

---

## 7. Registration Is Identity-Bound

Registration is not simply weapon insurance.

It creates a continuity-bound relationship between:

- the Custodian designation
- the currently valid Custodian
- an institutional armament assignment

The exact technical mechanism is not exposed to the player.

The consequence is simple:

> **A registered weapon carried by a Custodian remains the valid registered weapon available to the recovered Custodian.**

When the Custodian dies and is recovered, their registered loadout is available again through the appropriate recovery provisioning system.

The game does not need to explain whether this occurs through fabrication, reconstruction, replacement, continuity manipulation, pre-provisioning, or some combination of those processes.

---

## 8. Previous Registered Weapon Instances

A registered weapon left behind at a death site may remain physically present.

It does not disappear.

It does not need to visibly explode.

It may even use the same exact world presentation as the weapon the player currently carries.

However, the abandoned instance is no longer usable as an operational registered weapon.

The game should **not** expose detailed continuity diagnostics for this.

Do not display:

```text
INSTANCE CLAIM INVALID
BEARER LINK EXPIRED
CONTINUITY ID MISMATCH
```

That explains too much.

Instead, inspection remains concrete and restrained.

Example:

```text
HEAVY REPEATING HUNTING RIFLE

This weapon has been rendered unusable.
```

Or:

```text
P-9 FIELD SIDEARM

This weapon is no longer operational.
```

Or simply:

```text
SERVICE STATE: INOPERABLE
```

The player can infer the pattern over time.

The underlying logic is deeper than the UI reveals.

---

## 9. Why This Prevents Registered-Weapon Duplication

A registered weapon's persistence is not based on creating another freely usable copy.

After death:

- the recovered Custodian possesses the valid registered armament
- the abandoned field instance may remain in the world
- the abandoned instance is unusable
- therefore only one operational registered instance exists

This preserves environmental evidence from previous deaths without introducing a duplication exploit.

The game should treat this as an ordinary consequence of Custodian registration, not as an explicit metaphysical tutorial.

---

## 10. Unregistered Weapons Behave Differently

Unregistered weapons do **not** receive designation recovery protection.

If the Custodian dies while carrying an unregistered weapon:

- the weapon remains where it was lost, subject to local persistence rules
- the recovery system does not provide another one
- the weapon may potentially be retrieved
- enemies, factions, hazards, or world changes may complicate recovery

This creates a meaningful distinction.

Registered weapon:

> Safe institutionally.

Unregistered weapon:

> Safe only if you physically bring it home.

A powerful unregistered heavy weapon can therefore produce immediate tension:

> I have this weapon now.  
> I can use it now.  
> If I die, I may have to come back for it.

---

## 11. Death-Site Retrieval

Where local recovery is available, death can create a retrieval problem inside the active campaign.

Example:

The Custodian enters an industrial complex carrying:

- registered P-9
- registered Vigil
- unregistered heavy cannon

The Custodian dies.

Local recovery succeeds.

On recovery:

- the registered P-9 is available
- the registered Vigil is available
- the heavy cannon is not

The heavy cannon remains at or near the death site.

The player may choose to retrieve it.

This can create emergent situations:

- the weapon lies beside the original fight
- an enemy occupies the area
- another actor has moved it
- access to the area has changed
- the player abandons the recovery attempt
- the weapon is eventually extracted and registered

This is preferred over abstract currency loss.

---

## 12. Recovered Armory

Persistent equipment storage is distinct from registration.

The Custodian may recover more weapons than can be registered.

Example:

```text
RECOVERED ARMORY

SIDEARMS      4 / 6
PRIMARIES     5 / 8
HEAVY         1 / 2
RELICS        3 / 4
```

These numbers are illustrative.

The Recovered Armory represents physical persistent storage.

A weapon in the Armory remains owned and available between deployments.

Removing an unregistered weapon from storage and carrying it into a Campaign exposes it to field loss.

---

## 13. Registration Capacity

Registration capacity is intentionally much smaller than storage capacity.

Example:

```text
DESIGNATION ARMAMENT ASSIGNMENTS

SIDEARM       1 / 1
PRIMARY       1 / 1
FIELD         1 / 1
HEAVY         0 / 0
```

Later:

```text
SIDEARM       1 / 1
PRIMARY       2 / 2
FIELD         1 / 1
HEAVY         1 / 1
```

The player should never trivially reach a state where every owned weapon can be registered.

Registration remains a meaningful allocation decision.

---

## 14. Registration Capacity Progression

Capacity increases should **not** come from ordinary level progression.

Do not use:

```text
LEVEL 10
+1 REGISTERED WEAPON
```

Instead, the Custodian recovers institutional capabilities that expand what the designation can support.

Possible progression items include:

- Armament Ledger Fragment
- Heavy Custody Warrant
- Provisioning Annex
- Custody Matrix Segment
- Foreign Equipment Attestation Schema
- Hazardous Custody Seal
- Recovery Locker Extension
- Designation Register Extension

These names are provisional.

The important design principle is:

> **The player does not gain abstract inventory points. The surviving institution regains the capability to recognize, provision, or retain additional classes of equipment.**

This preserves CUSTODIAN's progression philosophy.

---

## 15. Registration Gates

Not every weapon should be immediately registrable.

Registration may require:

- sufficient registration capacity
- successful extraction
- known weapon identity
- acceptable provenance
- compatible Custodian systems
- recovered institutional authority
- a relevant attestation schema
- category-specific registration capability

A captured weapon may therefore be:

```text
USABLE: YES
RECOVERABLE: YES
REGISTRATION: UNAVAILABLE
```

until the necessary institutional capability is recovered.

This creates progression through understanding and recovered authority rather than conventional character levels.

---

## 16. Heavy Weapon Registration

Heavy equipment should initially be unavailable for designation registration.

Early state:

```text
HEAVY ASSIGNMENT: UNAUTHORIZED
```

A later recovery may unlock:

```text
HEAVY ASSIGNMENT CAPACITY: 1
```

The player may have already recovered heavy weapons before this occurs.

Those weapons remain usable and storable.

They simply cannot yet receive designation persistence.

This allows exciting equipment to appear before the player's institution is capable of fully supporting it.

---

## 17. Initial Deployment Loadout

Initial deployment should remain constrained enough that weapon choice matters.

Baseline target:

```text
PRIMARY        1
SIDEARM        1
FIELD / MELEE  1
HEAVY          UNAVAILABLE
```

This produces three meaningful carried weapon roles without turning the Custodian into a mobile armory.

### Primary

Examples:

- rifle
- shotgun
- carbine
- conventional two-handed ranged weapon

### Sidearm

Examples:

- P-9
- equivalent compact designation weapon

### Field / Melee

Examples:

- Vigil
- cleaver
- compact utility weapon
- comparable melee or field implement

---

## 18. Heavy Deployment

Heavy equipment should not simply become another unrestricted fourth weapon slot.

Once unlocked, Heavy equipment should carry meaningful logistical consequences.

Possible implementations include:

### Option A: Separate Heavy Assignment

```text
PRIMARY       1
SIDEARM       1
FIELD         1
HEAVY         1
```

Heavy weapons then impose disadvantages such as:

- movement burden
- limited ammunition
- slower handling
- inability to use some traversal interactions while carried
- specialized resupply requirements

### Option B: Heavy Replaces Primary

Some especially large weapons may occupy the Primary deployment allocation.

This can coexist with Option A.

A compact heavy weapon may use the Heavy allocation.

An enormous system may consume both:

```text
PRIMARY + HEAVY
```

The exact equipment taxonomy can be determined during weapon roster development.

---

## 19. Three Separate Capacity Systems

These limits must remain conceptually separate.

### Deployment Capacity

What the Custodian can physically bring into a Campaign.

### Recovered Storage Capacity

What the Post can physically retain between Campaigns.

### Registration Capacity

What the Custodian designation can guarantee through recovery.

This separation produces meaningful decisions without requiring arbitrary RPG inventory weight everywhere.

---

## 20. Registration Workflow

Registration should require deliberate action at the Post.

Basic flow:

```text
Recover weapon
    ↓
Weapon enters Recovered Armory
    ↓
Inspect weapon
    ↓
Registration eligibility checked
    ↓
Registration capacity available
    ↓
Assign weapon to designation
    ↓
Weapon becomes registered
```

The system should present this as **attestation / assignment**, not mystical bonding.

Example UI:

```text
HEAVY REPEATING HUNTING RIFLE

RECOVERED
REGISTRATION AVAILABLE

[ ASSIGN TO DESIGNATION ]
```

After registration:

```text
HEAVY REPEATING HUNTING RIFLE

REGISTERED
HEAVY ASSIGNMENT 1 / 1
```

Keep terminology simple.

Do not expose the deeper continuity mechanism.

---

## 21. Registration Changes Should Have Friction

Registration should not become an instant insurance toggle before every mission.

Possible constraints:

- registration changes only at the Post
- weapon must be physically present
- assignment capacity must be available
- some weapon classes require specific institutional capability
- assignment changes finalize during reintegration
- restricted equipment may require additional evidence or authority

The goal is to make registration feel like changing the Custodian's institutional provisioning profile, not clicking a favorite icon.

Exact timing and costs remain open for tuning.

---

## 22. Persistent Knowledge Versus Physical Equipment

Physical equipment and informational discoveries should follow related but distinct persistence rules.

Knowledge synchronized to the Hub survives death.

Unsynchronized evidence may remain at risk.

This suggests a strong general rule:

> **Extraction secures objects. Synchronization secures knowledge. Registration secures armament identity.**

These three verbs should form part of the larger Campaign economy.

---

## 23. Field Synchronization

A functioning terminal, relay, or similar infrastructure may permit the Custodian to synchronize recovered information before extraction.

This creates tactical decisions:

> Continue deeper with unsynchronized evidence?

or:

> Return to a relay and preserve what has already been learned?

Field synchronization should not necessarily function as a conventional checkpoint.

It protects information, not the physical Custodian.

---

## 24. Player-Facing Language

The UI should remain restrained.

Prefer:

- REGISTERED
- UNREGISTERED
- RECOVERED
- FIELD ACQUIRED
- ASSIGNED
- AVAILABLE
- UNAVAILABLE
- INOPERABLE
- SERVICE REQUIRED
- RECOVERY AVAILABLE
- RECOVERY UNAVAILABLE

Avoid routine exposure of terms such as:

- continuity claim ID
- bearer instance
- metaphysical identity state
- replacement body
- clone generation
- timeline rewrite
- object continuity hash

Those concepts may exist internally in implementation or lore reasoning, but ordinary player-facing systems should communicate only what the Custodian institution would need an operator to know.

---

## 25. Registered Weapon Death-Site Presentation

A previous registered weapon instance should visually remain recognizable.

No special ghost effect is required.

No obvious continuity anomaly needs to surround it.

Inspection should be mundane.

Example:

```text
P-9 FIELD SIDEARM

This weapon is no longer operational.
```

Or:

```text
HEAVY REPEATING HUNTING RIFLE

This weapon has been rendered unusable.
```

The mundane presentation is important.

The player can see that the weapon exists.

The player can see the same class of weapon currently in their possession.

The game does not explain the contradiction.

---

## 26. Player Corpse Handling

The game should not routinely instantiate a recoverable copy of the player's corpse after recovery.

The death site may preserve:

- environmental damage
- blood
- dropped unregistered equipment
- unusable prior registered equipment
- ordinary combat aftermath
- other field evidence

But the player's body need not remain.

No definitive explanation is required.

The absence should not be turned into an explicit lore answer.

---

## 27. True Game Over

Because Custodian death is normally recoverable, actual Game Over becomes more meaningful.

True terminal failure should arise from conditions such as:

- recovery infrastructure becoming permanently unavailable
- Post continuity becoming unrecoverable
- Hub Archive loss exceeding tolerable bounds
- an explicit campaign-ending event
- other persistent failure conditions

The key distinction is:

> **The current Custodian body failing is not necessarily the end. The institution losing the ability to continue the designation can be.**

This aligns game-over state with the persistent campaign layer rather than ordinary combat death.

---

## 28. Relationship to Current Runtime

Current runtime behavior treats Custodian death as immediate one-life game over.

That should be considered transitional.

Current relevant systems already provide useful foundations:

- Operator death animation and cleanup
- GameState failure authority
- Campaign failure/resolution concepts
- Return Reintegration
- persistent InventoryManager
- Equipment slots
- Recovered inventory presentation
- fabrication recipes
- Ready Build deployment
- InfrastructureRegistry
- physical Field Fabricator
- designation-keyed P-9 lore

Implementation should migrate these systems toward this document rather than create a parallel standalone recovery game.

---

## 29. Implementation Order

### Phase 1: Death Routing

Replace immediate Custodian death → Game Over with:

```text
Operator death
→ Campaign failure handling
→ Post recovery
→ Reintegration
```

Keep true Game Over available for persistent terminal failure.

### Phase 2: Equipment Persistence Classes

Add equipment persistence metadata:

```text
FIELD_ACQUIRED
RECOVERED
REGISTERED
```

Separate persistent Armory ownership from registration.

### Phase 3: Registered Loadout Recovery

Ensure registered equipment is provisioned after recovery.

Previous field instances remain present but unusable where persistence permits.

### Phase 4: Unregistered Retrieval

Allow unregistered weapons to remain recoverable from active Campaign state after local death and recovery.

### Phase 5: Local Existing Crèches

Introduce repairable local recovery infrastructure in selected authored or generated Domains.

### Phase 6: Fabricated Recovery Infrastructure

Add:

- Field Recovery Crèche
- optional Designation Mooring

through existing fabrication / Ready Build / infrastructure systems.

### Phase 7: Registration Capacity Progression

Introduce recovered institutional components that expand:

- weapon-category registration capability
- registration capacity
- Recovered Armory capacity
- restricted equipment support

Avoid conventional level-based inventory expansion.

---

## 30. Reserved Questions

Do not answer yet:

- whether recovery restores the same biological body
- whether another body is produced
- whether bodies are reconstructed from surviving matter
- whether continuity infrastructure selects among adjacent compatible states
- why the previous body does not ordinarily remain
- how registered weapon replacement physically occurs
- whether all Crèches use identical recovery mechanisms
- whether every historical designation recovery was equally reliable

These questions remain available for later narrative development.

They are not required for the gameplay systems to function.

---

## 31. Deferred Concept

Evidence demonstrating **imperfect designation resolution**, failed historical recoveries, contradictory Custodian instances, or similar edge cases is deliberately shelved.

Do not build an explicit "recovery system sometimes fails metaphysically" narrative pass at this stage.

The current design benefits more from letting the normal operation establish itself first.

---

## 32. Design Summary

The intended persistent loop is:

```text
DEPLOY
    ↓
use registered starting loadout
    ↓
find weapons and equipment
    ↓
use field-acquired gear immediately
    ↓
establish recovery infrastructure if worthwhile
    ↓
synchronize knowledge
    ↓
survive / extract
    ↓
equipment becomes RECOVERED
    ↓
store in Recovered Armory
    ↓
choose scarce equipment to REGISTER
    ↓
recover institutional capability
    ↓
expand registration / storage / equipment-class authority
    ↓
deploy again
```

Death modifies that loop rather than resetting it.

Without local recovery:

```text
DEATH
→ campaign resolution
→ Post recovery
```

With local recovery:

```text
DEATH
→ local designation recovery
→ campaign continues
```

Registered equipment returns with the recovered Custodian.

Unregistered equipment does not.

Previous registered field instances may remain physically present but unusable.

The deeper continuity mechanism remains deliberately unexplained.

---

## 33. Thematic Lock

The persistent equipment system should continually reinforce three different questions:

> **What are you carrying?**

> **What have you successfully brought home?**

> **What has the institution accepted as part of the Custodian?**

Those are three different categories.

The same is true of the protagonist.

The body is one thing.

The designation is another.

The relationship between them is what the old institution is attempting to preserve.

CUSTODIAN should let the player live inside that distinction long before it attempts to explain it.
