## 1️⃣ CODEX MIGRATION DIRECTIVE

## Documentation Architecture Consolidation Plan

This directive defines the *target documentation architecture* and gives Codex authority to resolve conflicts, duplication, and archival decisions.

Codex has final say on file-level placement because it can read full contents.

---

## 🎯 OBJECTIVE

Unify all planning, design, audit, and AI context documentation into a single coherent design architecture.

Eliminate:

* Duplicate canonical sources
* “FINAL / V1 / V2” parallel documents
* Fragmented feature_planning
* Redundant AI context layers
* Root-level implementation artifacts

Preserve:

* System knowledge
* Decision history (archived)
* Completed feature documentation
* Future engine transition planning

---

# 🧱 TARGET DOCUMENT STRUCTURE

Codex must migrate documentation into the following structure:

```plaintext
design/
│
├── 00_foundations/
│   ├── ARCHITECTURE.md
│   ├── SIMULATION_RULES.md
│   ├── CORE_DESIGN_PRINCIPLES.md
│   └── ENGINE_TRANSITION_STRATEGY.md
│
├── 10_systems/
│   ├── assault/
│   ├── economy/
│   ├── infrastructure/
│   ├── procgen/
│   └── hub_campaign/
│
├── 20_features/
│   ├── planned/
│   ├── in_progress/
│   └── completed/
│
├── 30_playable_game/
│   ├── PLAYER_CONTROL_MODEL.md
│   ├── DRONE_BEHAVIOR.md
│   ├── RTS_LAYER.md
│   └── ENGINE_PORT_PLAN.md
│
├── archive/
│   ├── audit/
│   ├── deprecated/
│   └── historical/
│
└── CHANGELOG.md
```

Additionally:

```plaintext
ai/
  CONTEXT.md
  CURRENT_STATE.md
  FILE_INDEX.md
```

---

# 📦 MIGRATION RULES (Codex Has Final Authority)

## Rule 1 — Canonical Documents

Codex must determine which document version is canonical.

If multiple variants exist (e.g. FINAL, V1, V2):

* Keep the most correct and internally consistent version
* Archive others under:

  ```
  design/archive/deprecated/
  ```

---

## Rule 2 — feature_planning Elimination

All documents under:

```plaintext
feature_planning/
```

Must be moved into:

* `design/10_systems/...` if system-level
* `design/20_features/...` if feature lifecycle
* `design/archive/` if superseded

The directory `feature_planning/` must be removed after migration.

---

## Rule 3 — docs/ Consolidation

Under `docs/`:

* `_ai_context/` → move minimal projection to `/ai`
* `audit/` → move to `design/archive/audit/`
* System-level documents → migrate into appropriate `design/10_systems/`

`docs/` must not remain a parallel canonical source.

---

## Rule 4 — No Duplicate Canonical Files

After migration:

There must be **exactly one authoritative version** of:

* Architecture
* Simulation Rules
* Assault Design
* Infrastructure Design
* Power Systems
* Policy Layer
* Repair Mechanics

If two documents overlap:

Codex must merge or archive one.

---

## Rule 5 — Archive Policy

Archive only if:

* Superseded
* Historical reference
* Audit artifact
* Redundant draft

Never archive the only surviving copy of a system.

---

## Rule 6 — Root Cleanup

The following must be evaluated and likely archived:

* IMPLEMENTATION.txt
* IMPLEMENTATION-V1.txt
* COMMANDS.txt (if redundant to canonical command contract)

---

## Rule 7 — Do Not Modify Runtime Code During Migration

This migration is documentation-only.

---

## END CONDITION

Migration is complete when:

* `design/` contains all canonical design
* `ai/` contains only projection summaries
* No duplicate final versions exist
* feature_planning/ and docs/ no longer act as canonical sources
* Archive contains historical artifacts only

Codex must report:

* Which documents were merged
* Which were archived
* Which were removed
* Which were renamed

