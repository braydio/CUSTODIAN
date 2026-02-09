# Broad Overview and Design Rules

## Core Fantasy (North Star)

You are the last mechanitor, maintaining a static command post in a collapsed interstellar civilization. Information systems are gone. History is fragmented. Factions fight over myths, scraps, and half-understood tech. You do not win by killing them all. You win by preserving, reconstructing, and defending knowledge.

## Why This Theme Works Mechanically

Post-apoc + spacer tech + Foundation-like ideas create procedural permission:

- Enemies can vary wildly without feeling random.
- Tech levels can regress, hybridize, or mutate.
- Ideology can matter as much as biology.
- Knowledge is the scarce resource.

This lets you generate who attacks, why they attack, and how they attack without hand-authoring factions.

## Campaign Goal

Reconstruction, not domination. End campaigns when enough truth is recovered, not when enemies are gone.

Examples of long-term objectives:

- Rebuild a lost star map.
- Reactivate a dormant network.
- Restore an archive AI.
- Assemble a transmission that can outlast you.

## Progression Pillars (Three Tracks)

### 1) Knowledge (Primary Progress)

- Fragments of history, science, culture, and technology.
- Unlocks systems and changes enemy behavior.
- Knowledge is not XP. It changes what exists in the world.

### 2) Infrastructure (Base Growth)

Physical manifestation of recovered knowledge. Infrastructure answers: "What can my command post now sustain?"

Core systems:

- Power: reactors, scavenged generators, unstable relic tech. Scarcity creates tradeoffs.
- Fabrication: converts materials into defenses. Advanced fabrication requires knowledge.
- Defense Grid: walls, turrets, drone bays, shield emitters. Defenses degrade or malfunction.
- Data Core: stores recovered knowledge. Losing it is catastrophic but not instant-fail.
- Automation: the mechanitor's strength. The base functions when you are absent.

Key rule: infrastructure is vulnerable. You defend capabilities, not hit points.

### 3) Capability / Doctrine (How You Play)

Personal progression via rules, not stats. Examples:

- "Turrets may operate without line-of-sight."
- "Drones can self-sacrifice to delay enemies."
- "You may reroute power mid-assault."
- "One structure per assault may auto-repair."

Unlocked via knowledge synthesis, not leveling.

## Meta-Progression Hub

An archive between campaigns that persists outside any single base.

Persists:

- Discovered truths (canon unlocks).
- New enemy archetypes (yes, even threats persist).
- Global doctrines.
- New expedition biomes.
- Starting base layouts.

You do not get stronger. You get more informed. This prevents power creep and keeps early assaults meaningful.
Unlocks exist, but they are justified by accumulated context, not raw success.

## Enemy Generation Rules (Ideology > Form > Tech)

Enemies are generated in layers:

1. Ideology (why they attack)
   - Preservationists (want your data)
   - Iconoclasts (destroy old tech)
   - Cult mechanists (worship broken machines)
   - Expansionists (resource hunger)

2. Form (what they are)
   - Humans
   - Post-humans
   - Bio-engineered remnants
   - Autonomous warforms
   - Hybrid scavenger constructs

3. Technology expression (how they fight)
   - Crude kinetic weapons
   - Ritualized tech misuse
   - Reverse-engineered relics
   - Elegant but fragile systems

This yields enemies that feel authored without lore dumps.

## Assaults Are Arguments

An assault is a faction saying: "Your way of preserving the past is wrong."

Mechanically:

- They counter what you rely on.
- They exploit weaknesses your base has revealed.
- They adapt over time.

Examples:

- Overuse shields leads to EMP cultists.
- Overuse drones leads to signal-jammers.
- Overuse walls leads to burrowers and sappers.

## Base Form Factor (Lock This)

A static base for a campaign is the correct call. It creates attachment, long-term planning, and meaningful loss. You are anchored. The world comes to you.

Winning hybrid: sectorized static outpost.

- Fixed footprint.
- Divided into sectors (rooms/zones) connected by chokepoints and corridors.
- Outside terrain matters.
- You place systems, not infinite walls.
- Enemies attack from directions, not arbitrary tiles.

Concrete base rules:

- Core sector plus 4-6 peripheral sectors (tutorial uses 10 total).
- Each sector has entry points, power capacity, defense slots.
- You cannot expand infinitely.
- You can reinforce, reroute, or abandon sectors.

## Initial Base Layout (Strong Starting State)

Start with:

- 1x Fabricator
- 1x Power Bank
- 1x Basic Defense
- The mechanitor

This forces expeditions immediately and keeps early assaults personal. The base should feel like it will not survive long without intervention.

## Mechanitor as Combatant (Soft Fail)

- Powerful but fragile.
- Can engage enemies directly, repair defenses, reroute systems, trigger emergency abilities.
- If downed: base continues autonomously; some systems become unavailable; you reconstitute after the assault (costly, not free).

Campaign does not end when the mechanitor goes down. Loss reduces agency, not existence.

## Recon and Gathering (Concrete)

Early expeditions should be:

- Short (3-5 minutes)
- Close to base
- Low enemy density
- High information yield

Activities:

- Scan wreckage
- Recover loose materials
- Activate dormant sensors
- Fight small patrols
- Discover faction presence

Outputs:

- Scrap (fabrication fuel)
- Power components
- Sensor data
- Threat indicators

You are learning where danger will come from.

## First 30-60 Minutes (Tutorial Flow)

1. Campaign start: drop pods, brief scan, power bank online, fabricator partial, one automated turret.
2. Establish sensors: perimeter sensors, motion scanners, signal intercepts. Until this is done, assaults are unpredictable.
3. Initial recon expeditions: 2-3 short trips, light resistance, learn who is nearby.
4. Base reinforcement: add one defense, upgrade power, reinforce a weak angle.
5. First assault: small wave, tests one axis, survivable, teaches positioning and repair.
6. Loop begins: recon, build, assault, repair, learn.

## Failure and Pressure

Failure should hurt but not end the campaign immediately.

- Lose a wing of the base.
- Corrupt stored knowledge.
- Force a doctrine reset.
- Lock a tech branch.

Campaign ends when the core archive is destroyed or the reconstruction goal is completed.

## Campaign Arc

1. Stabilization: weak base, small assaults, scraps of truth.
2. Escalation: factions specialize, assaults become targeted, base identity solidifies.
3. Revelation: truths contradict assumptions, enemies shift behavior, endgame objective emerges.
4. Final pressure: sustained assaults, permanent tradeoffs, last reconstruction push.

## Presentation and Scope

Start with 3D presentation and 2.5D gameplay.

- Isometric or fixed camera.
- No free-look at first.
- Grid or sector placement.
- Readability over realism.

Avoid early:

- Full physics.
- Free camera.
- Complex pathing.

## What Persists vs Resets

- Lose: resources, ship progress, peripheral sectors.
- Keep: knowledge, schematics, doctrines.

Matter is fragile. Knowledge endures.

## Decisions to Lock Next

Pick one in each category to unblock implementation:

1. Base form factor: circular outpost, linear facility, or asymmetric ruin.
2. First reconstruction objective type: archive, network, AI, or defense system.
3. Early combat lethality: arcade, tactical, or lethal-but-forgiving.
