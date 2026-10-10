# MASTER ROADMAP DESIGN

**Project:** CUSTODIAN  
**Created:** 2026-04-04  
**Status:** active  
**Last Updated:** 2026-10-07

---

## Purpose

This is the **single source of truth** for CUSTODIAN feature planning. All new features, systems, and milestones must be added here first before implementation begins.

---

## Adding New Features

### Process

```
[new idea/request]
        │
        ▼
┌───────────────────┐
│ Check this doc   │  ← MANDATORY FIRST STEP
│ (MASTER_ROADMAP) │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ Feature exists?   │
│ - YES → Update    │
│ - NO → Create     │
│   new entry       │
└───────────────────┘
        │
        ▼
[Add to appropriate milestone]
        │
        ▼
[Create design doc]
        │
        ▼
[Implement]
```

### When to Add

- **New feature request** → Add to roadmap BEFORE design doc
- **Bug fix with design impact** → Add to roadmap if it changes system behavior
- **Technical debt** → Add to appropriate milestone
- **Research/spike** → Add as research task, convert to feature on completion

---

## Roadmap Structure

### Milestones

Milestones are major release checkpoints. Each has:
- **Target date** (soft)
- **Status** (backlog → planned → design → in_progress → complete)
- **Feature list** (linked to design docs)
- **Dependencies** (prerequisites)

### Feature Entry Format

```markdown
### [Feature Name]
**Doc:** `path/to/design.md`  
**Status:** backlog | planned | design | in_progress | complete  
**Priority:** P0 (critical) | P1 (high) | P2 (medium) | P3 (low)  
**Depends on:** [other features or none]  

**Summary:** 1-2 sentences on what this feature does

**Subtasks:**
- [ ] Subtask 1
- [ ] Subtask 2
```

### Status Legend

| Status | Meaning |
|--------|---------|
| backlog | Not yet scheduled |
| planned | Scheduled for future milestone |
| design | Design doc in progress |
| in_progress | Actively being implemented |
| complete | Implemented and verified |

### Priority Legend

| Priority | Meaning |
|----------|---------|
| P0 | Blocker / Core functionality - must ship |
| P1 | Important but not blocking |
| P2 | Nice to have |
| P3 | Future consideration |

---

## Current Roadmap

### Milestone v0.3.0 - Procgen Handoff Fixes
**Target:** TBD (remaining: shadow + weapon data integration)  
**Status:** in_progress

| Feature | Status | Priority |
|---------|--------|----------|
| Camera derives bounds from ProcGenRuntime | complete | P0 |
| Camera snaps to player spawn on load | complete | P0 |
| Terminal repositioned to procgen coords | complete | P1 |
| Ammo caches repositioned to procgen coords | complete | P1 |
| Camera joins "camera" group | complete | P0 |
| Mouse aim uses correct world position | complete | P1 |
| Shadow system integration | pending | P2 |
| Weapon data system integration | pending | P2 |

---

### Milestone v0.4.0 - Mission State Machine
**Target:** 2026-04-01  
**Status:** planned

| Feature | Status | Priority |
|---------|--------|----------|
| GameState phase enum | planned | P0 |
| Phase transition logic | planned | P0 |
| WaveManager phase binding | planned | P1 |
| Phase indicator in HUD | planned | P2 |

**Depends on:** v0.3.0

---

### Milestone v0.5.0 - Free-Roam Pre-Assault
**Target:** 2026-04-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| Traverse procgen compound | design | P0 |
| Scavenge/pickup system | design | P1 |
| Resource collection & fabrication | design | P1 |
| Power routing between structures | design | P1 |
| Fortification placement | design | P1 |
| Terminal prep commands | design | P1 |
| Manual assault trigger | design | P0 |

**Doc:** `02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`  
**Depends on:** v0.4.0

---

### Milestone v0.6.0 - Compound Sectors as Entities
**Target:** 2026-04-30  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| COMMAND sector as entity | design | P0 |
| POWER sector as entity | design | P0 |
| DEFENSE sector as entity | design | P1 |
| FABRICATION sector as entity | design | P1 |
| Sector damage integration | design | P0 |

**Doc:** `02_features/sector_damage/implementation.md`

---

### Milestone v0.7.0 - ARRN (Relay Network)
**Target:** 2026-04-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| ARRN Manager & data model | design | P1 |
| Relay entities (4 nodes) | design | P1 |
| SCAN RELAYS command | design | P1 |
| STABILIZE RELAY interaction | design | P1 |
| SYNC & knowledge progression | design | P1 |
| Tick/decay system | design | P2 |
| Benefit activation (7 unlocks) | design | P2 |

**Doc:** `02_features/arrn/implementation.md`

---

### Milestone v0.8.0 - World Expansion & The Hub
**Target:** 2026-05-30  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| World Manager system | design | P1 |
| Hub data structures | design | P1 |
| Scenario generation (seed-based) | design | P1 |
| Terminal Hub UI | design | P1 |
| Compound tiles (wall entities) | design | P0 |
| Power conduit walls | design | P0 |
| Region world generation | design | P2 |

**Doc:** `02_features/world_expansion/implementation.md`

---

### Milestone v0.9.0 - Animation & Polish
**Target:** 2026-03-30  
**Status:** in_progress

Operator animation production order is now authored in
`design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json`.
Its rank and plan state are human authority; catalog coverage, validation
health, and generated next-action reports are evidence only and may never
silently reorder the plan. Workbench V3 adds PLAN, WORKBENCH, PREVIEW, and
TIMELINE cockpit modes. Preview and saved review sequences remain disposable
`.ai/` tooling artifacts and do not own gameplay timing or runtime animation
state.

| Feature | Status | Priority | Source |
|---------|--------|----------|--------|
| Reload state animation | in_progress | P2 | Design doc |
| Reload state with movement speed penalty | **NEW - design** | P1 | GAMEPLAY_NOTES.md |
| Interact state animation | in_progress | P2 | Design doc |
| Pickup state animation | in_progress | P2 | Design doc |
| Repair state animation | planned | P2 | Design doc |
| Crouch state animation | planned | P3 | Design doc |
| Walk NW animation bounce fix | **NEW - backlog** | P2 | GAMEPLAY_NOTES.md |
| Animation base idle | **NEW - backlog** | P2 | GAMEPLAY_NOTES.md |
| Animation base stance (melee/ranged) | **NEW - backlog** | P2 | GAMEPLAY_NOTES.md |
| Shadow system | pending | P2 | Design doc |
| **Operator sidearm draw/fire animation** | complete | P1 | Pipeline — 32 sheets (4 layers × 4 diagonal dirs × draw+fire) wired to modular frame system |
| **Marine dash 128×128 split-phase** | complete | P1 | Pipeline — 3-phase charge/inflight/recovery from 156px single strip; only E direction available |
| **Operator sidearm: remaining directions** | backlog | P2 | N, S, E, W cardinal directions needed for all 4 layers × 2 actions = 32 missing sheets |
| **Operator sidearm: reload animation** | backlog | P3 | No dedicated reload art exists |
| **Operator sidearm: recovery animation** | backlog | P3 | No recovery art after firing |
| **Marine dash: 8-direction split art** | backlog | P2 | Currently only E direction; needs SE/SW/NE/NW/N/S/W to match idle coverage |

**Docs:** `02_features/operator/implementation.md`, `02_features/shadow/implementation.md`

---

### Milestone v0.9.1 - Gameplay Bug Fixes (NEW)
**Target:** 2026-04-07  
**Status:** planned

| Feature | Status | Priority | Source |
|---------|--------|----------|--------|
| Spawn collision prevention | planned | P1 | GAMEPLAY_NOTES.md - Run 002 |
| Sector visual differentiation | planned | P2 | GAMEPLAY_NOTES.md - Run 002 |
| Command terminal live minimap | planned | P1 | GAMEPLAY_NOTES.md - Run 001 |
| Reduce assault waves to 3-5 for testing | planned | P2 | GAMEPLAY_NOTES.md - Run 001 |

**Note:** These are quick fixes/improvements from gameplay notes that don't warrant a full milestone but need tracking.

**Docs:** 
- `01_systems/COMMAND_TERMINAL_UI.md`
- `03_architecture/COMPOUND_TILE_SYSTEM.md`

---

### Cross-cutting Procgen Runtime Optimization
**Status:** in_progress  
**Priority:** P1  
**Doc:** `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`  
**Depends on:** none for baseline measurement; per-slice dependencies in the detailed roadmap

**Summary:** Measure, optimize, and decomplexify deterministic contract-world generation and runtime streaming without shrinking the game, weakening validation, or moving gameplay authority into presentation.

| Slice | Status | Priority |
|---------|--------|----------|
| S1 Performance baseline + benchmark contract | complete | P0 |
| S2 Candidate evaluator extraction | complete | P1 |
| S3 Semantics-only candidate generation | planned (G3 delivered narrower eval-mode realization skips; true semantics-first construction is now packetized as a post-D1/D2/D3 GenerationGrid initiative: audit → reviewed grid foundation → measured migration-series authoring → generated migration DAG) | P0 |
| S4 Accepted-candidate materializer | complete | P1 |
| S5 Runtime mutation scheduler | complete | P0 |
| S6 Pause-aware streaming | complete | P1 |
| S7 Chunk lifecycle + cache | complete (M6/MR6 correction cycle closed; MR6R1 passed) | P1 |
| S8 ProcGenTilemap decomplexification | in_progress (D1 reviewed complete; D3 complete; D2 ready/auto now; X1 waits on reviewed D2 → reviewed GenerationGrid foundation → measured migration DAG → D4 façade contraction) | P1 |
| S9 Contract-world placement extraction | planned | P2 |
| S10 Renderer / node-load consolidation | planned | P1 |
| S11 End-to-end performance soak + regression budget gate | planned | P1 |

The detailed roadmap owns execution status and evidence. Every completed slice must update that file in its landed change; this master entry tracks the program at feature-planning granularity.

V1 remains dependency-driven and evidence-gated. RF1/RFR1 and AP1 are complete/landed. AP2 is now ready/auto from the registered approved `alpine-cliff-source-family-v1` Dropbox source-master batch; AP2 derives and validates the final 26 cliff/contact/depth runtime states and publishes Gate B at closeout. AP3 remains blocked only on AP2; its full 16-state image-art input is now complete in the registered `rocky-upland-10-source-family-v1` + `meridian-hardstand-6-source-family-v1` source-master batches, and AP3 will produce Gate C at closeout. AP4 remains dependency-gated behind AP1-AP3. AP5 is a post-closeout, non-blocking variety extension behind AP4; it preserves the AP1 six-state baseline while adding deterministic ordinary alternates and rare scenic-landmark seed plates from a separate 24-plate immutable handoff. Archive Resolve AR1/ARR1, AR2, AR3 and AR4 implementation/review/correction lineage are complete; AR4's human disposition is waive-to-playtest. The remaining live-play blocker is the separate ready/auto P0 `game-tscn-operator-startup-integrity-v1`: a literal `game.tscn` Dev Observatory session showed the player still at the scene-authored legacy Operator coordinates despite an active generated ProcGenMap. Archive Resolve should not be reopened to solve that startup defect. In the decomplexification lane, D1 is reviewed complete, D3 is complete, and D2 is now ready/auto with its D1 review gate satisfied. X1 is pre-authored but remains dependency-gated on reviewed D2; X2/X3 are explicitly blocked/manual refresh gates so stale pre-audit/pre-foundation assumptions cannot auto-dispatch. P1/PR1 independently gate placement extractions; renderer-consolidation retains its existing refresh rule. The detailed roadmap owns packet-level dependencies and refresh gates; this master table remains the macro feature-status mirror.

---

### Cross-cutting Procgen World Presentation
**Status:** in_progress  
**Priority:** P1  
**Docs:** `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`, `design/02_features/procgen/ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`, `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`, `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`  
**Depends on:** reviewed M6/MR6 streaming-residency seam for runtime presentation integration

**Summary:** Keep three visual concepts independent: local ecological biome, permanent region-frame/border/underlay presentation, and Archive Resolve streaming/reacquisition. The first generated starting region uses `ALPINE_PLATEAU`; future generated regions may select other frame profiles.

| Feature | Status | Priority |
|---------|--------|----------|
| RF1 Region Frame presentation foundation | complete / landed | P1 |
| RFR1 Region Frame paired review | complete / passed | P1 |
| AP1 Alpine Plateau omnidirectional underlay continuation | complete / landed | P1 |
| AP2 Alpine cliff / contact / depth presentation | ready / auto; approved Dropbox source-master batch registered | P1 |
| AP3 Alpine Rocky Upland + Meridian surface plates | blocked / AP2 only; Rocky 10 + Meridian 6 source art complete/registered | P1 |
| AP4 Alpine environment cohesion / final visual closeout | blocked / AP1+AP2+AP3; no new art gate | P2 |
| AP5 Alpine underlay variety + rare scenic landmarks | blocked / AP4 + immutable 24-plate variety handoff; non-blocking to AP1–AP4 | P2 |
| AR1 Archive Resolve presentation spine | complete / landed | P2 |
| ARR1 Archive Resolve paired technical review | complete / passed | P2 |
| AR2 Archive Resolve shader | implementation + real-renderer recovery + human visual + paired review complete/passed | P1 |
| AR3 Archive Resolve semantic echo / spawn / reacquisition | complete / landed / paired review passed | P2 |
| AR4 Archive Resolve frontier restraint | complete / corrected / paired review passed; human disposition waive-to-playtest | P1 |
| P0 literal game.tscn Operator startup integrity | ready / auto; blocks deferred Archive Resolve live playtest, not AR code closeout | P0 |

**Implementation packets:** `PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md`, `REVIEW_PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md`, `PROCGEN_ALPINE_PLATEAU_UNDERLAY_ASSETS.md`, `PROCGEN_ALPINE_CLIFF_PRESENTATION_V1.md`, `PROCGEN_ALPINE_SURFACE_PLATES_V1.md`, `PROCGEN_ALPINE_ENVIRONMENT_COHESION_V1.md`, `PROCGEN_ALPINE_UNDERLAY_VARIETY_V1.md`, `PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md`, `REVIEW_PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md`, `PROCGEN_ARCHIVE_RESOLVE_SHADER.md`, `PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md`, `PROCGEN_ARCHIVE_RESOLVE_FRONTIER_RESTRAINT.md`, `REVIEW_PROCGEN_ARCHIVE_RESOLVE_FRONTIER_RESTRAINT.md`.


### Cross-cutting Isometric 2.5D / Sundered Overlook
**Status:** in_progress

| Feature | Status | Priority |
|---------|--------|----------|
| K3D-1P walkable precursor | complete / landed | P2 |
| 2.5D presentation foundation | ready / auto | P2 |
| 2.5D foundation paired review | ready / auto behind foundation | P2 |
| Forum 2.5D vertical slice | ready / behind reviewed foundation | P2 |
| Sundered Keep overlook alternate SKO-1 | ready / behind reviewed foundation | P2 |
| Sundered overlook optional Asset V2 polish | blocked / manual after SKO-1 review | P2 |
| Sundered production/procgen integration planning | blocked / authoring-chat refresh after reviewed standalone proof | P2 |

**Docs:** `01_systems/ISOMETRIC_2_5D_REALIZATION_ROADMAP.md`, `05_levels/SUNDERED_KEEP_OVERLOOK_ALTERNATE_ROADMAP.md`  
**Authoring chat for Sundered overlook:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7

---

### Cross-cutting Combat Resource and Readability
**Status:** in_progress

| Feature | Status | Priority |
|---------|--------|----------|
| Typed ammo, magazines, range/falloff | complete | P0 |
| Weapon heat, overheat, positional gunshot noise | complete | P0 |
| Production combat-pressure feedback | in_progress | P1 |
| Field Patch healing | planned | P1 |
| Hit taxonomy / reactions | complete-v1 | P1 |
| Dedicated semantic riposte | queued | P1 |
| Durability and field repair | backlog | P2 |
| Physical vault theft | complete | P1 |
| Portable turret placement | complete | P1 |
| Trap deployment | backlog | P2 |
| Allied combat drone V1 | complete | P1 |
| Drone battery/repair/redeployment | backlog | P2 |

**Doc:** `02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`
**Depends on:** Combat system, resource fabrication, enemy objectives, turret placement

---

### Milestone v1.0 - Power & Logistics Systems
**Target:** 2026-05-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| Power generation | design | P1 |
| Power routing | design | P0 |
| Load management | design | P1 |
| Blackout mechanics | design | P1 |
| Logistics economy | design | P2 |
| Fabrication system | design | P2 |

**Doc:** `02_features/power/POWER_SYSTEMS_GODOT.md`

---

### Milestone v1.1 - Vehicle System
**Target:** 2026-06-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| ControllableActor interface | design | P0 |
| PilotableVehicle lifecycle authority | complete | P0 |
| Player controller routing | design | P0 |
| Enter/exit mechanics | design | P0 |
| Light Hover Buggy archetype | design | P1 |
| Vehicle health/destruction | design | P1 |
| Vehicle weapon integration | design | P1 |

**Doc:** `02_features/vehicles/implementation.md`  
**Depends on:** Combat system, Repair mechanics, Free-roam (v0.5.0)

---

### Milestone v1.2 - Command Terminal UI
**Target:** 2026-07-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| Four-zone layout (Header, Nav, Content, Transcript) | design | P0 |
| 12-page terminal structure | design | P0 |
| Information fidelity system | design | P0 |
| Boot sequence flow | design | P1 |
| Mode-dependent behavior (Hub/Command/Field) | design | P1 |
| Power routing page | design | P0 |
| Sector management page | design | P0 |
| Archive/knowledge system page | design | P1 |
| Command palette | design | P2 |

**Doc:** `02_features/terminal/COMMAND_TERMINAL_SPEC.md`  
**Depends on:** Power routing (v1.0), Free-roam (v0.5.0)

---

### Cross-cutting F15 Procedural World Semantics and Codex Idea Graduation

**Status:** design/dependency-gated; **priority:** P1 architectural planning, not an implementation claim.  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31  
**Design/tracking:** [F14-C2/F15 production geography refresh](../04_architecture/F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md), [Hall dependency register](../04_architecture/codebase_systems_audit/CODEX_IDEA_DEPENDENCY_REFRESH_REGISTER.md), [Codex Hall](../90_codex/01_hall_of_great_ideas.md).  
**Depends on:** accepted F14-C1, **F15-A independently reviewed evidence**, F15 design lock and each later runtime owner.

| Idea family | Earliest design gate | State / required action |
| --- | --- | --- |
| Encounter Language; Landmark Hierarchy; Spatial Compression; Mystery Budget | **F15-B geography/procgen spec and packet refresh**, after F15-A | **Design candidate:** decide placement semantics, source truth, repeatable camera/travel tests; no immediate new feature packet |
| Procedural Ruin Generator + World Autopsy | After stable site/room geometry, material metadata and canonical history | **Deferred design:** choose failure cause/physical damage, clue reconstruction and repair mechanics |
| Line-of-Communication Graph + Faction Knowledge | Geographic network identities + F14-C2 population/residency | **Deferred design:** grounded physical links and sourced reports, no competing F14 clock/graph |
| World Event Timeline, Resource Economy Graph, Ambient Scheduler, Morale, Director Memory | After specific site/history/resource/biome/faction gates | **Deferred with explicit triggers** in Hall register |
| WorldHistory, WorldStateGraph, Material Intelligence, Observatory, Heatmaps, Interest; Replay and Performance Budget | **Extend verified live owners**, after F15-A perf and multi-site evidence | **Hardening/extension review**, do not start second systems without verified gap |

**Graduation requirement:** Once the relevant dependency closes, refresh mechanics, ownership, game-feel/lore choices and negative tests with ChatGPT/user; graduate/extend active design authority; only then author paired V2 implementation/review packets. This entry authorizes neither code nor art.

### Backlog

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Save system | backlog | P1 | Campaign persistence |
| Contract history | backlog | P2 | Track completed |
| Player progress (XP/unlocks) | backlog | P2 | Progression |
| Resource economy | backlog | P2 | Credits, materials |
| Market/trade system | backlog | P3 | Buy/sell |

---

## Completed Milestones

| Milestone | Completed | Notes |
|-----------|-----------|-------|
| Wave spawning system | 2026-03-08 | Lane spawns, variants |
| Enemy director | 2026-03-08 | Threat, budget, routing |
| Turret system | 2026-03-06 | 4 archetypes |
| Player ranged combat | 2026-03-10 | Ammo, cooldowns |
| Player melee combat | 2026-03-12 | Timing, hit-stop |
| Sprint & stamina | 2026-03-10 | Stamina HUD |
| Repair gameplay | 2026-03-07 | Hold repair |
| Supply drops | 2026-03-11 | Resource drops |
| Contract world loader | 2026-03-14 | Procgen promotion |
| Runtime wall collision | 2026-03-15 | Explicit colliders |

---

## Design Doc Integration

Every feature in the roadmap must have:

1. **Design doc** in `design/` folder
2. **Implementation doc** in the appropriate numbered subdirectory
3. **Status field** matching roadmap status

### Doc Path Convention

```
design/
├── 00_meta/                       ← Meta/tracking (THIS FILE)
├── 01_systems/                    ← Core systems
├── 02_features/                   ← Feature specs
│   └── [feature]/
│       ├── spec.md
│       └── implementation.md
├── 03_world/                      ← World lore & content
├── 04_architecture/               ← High-level architecture
├── 05_levels/                     ← Level designs
└── 06_reference/                  ← Research & reference
```

### Linking Format

Every design doc must include:

```markdown
**Roadmap:** [Milestone name - Feature name]
**Status:** [status from roadmap]
**Depends on:** [other features or none]
```

---

## Quick Reference

### Adding a Feature

1. Read this MASTER_ROADMAP.md first
2. Check if feature already exists
3. If new: add to appropriate milestone
4. Create design doc
5. Link design doc in roadmap entry

### Updating Status

1. Update status in this MASTER_ROADMAP.md
2. Update status in design doc

### Finding Design Docs

- Search `design/02_features/[feature_name]/`
- Search `design/05_levels/` for level designs
- Search `design/04_architecture/` for architecture docs

---

## Reference Files

| File | Purpose |
|------|---------|
| `TEMPLATE_SYSTEM.md` | System design template |
| `TEMPLATE_FEATURE.md` | Feature design template |

---

*All new features must be added to this MASTER_ROADMAP.md first. This is the single source of truth.*
