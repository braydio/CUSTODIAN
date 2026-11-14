# RITUALANT — HIGHLAND STATION DOCUMENTATION DRIFT RECONCILIATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ritualant-highland-station-doc-drift-reconciliation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `ritualant-design-docs`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture`
- Paired review workstream: `review-ritualant-highland-station-doc-drift-reconciliation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `active canonical lore has overlapping old implementations and future authority; fresh-context check is material`
- Reviewed main: `39d9613937c1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Goal: Find and reconcile remaining **active** lore/spec documentation that mistakenly presents the old Stilling Pin/basin implementation as the approved final Highland Station design, without falsely claiming the Receiver Key migration has shipped.
- Completion boundary: One scoped active-document drift inventory and bounded edits to affected active lore, level, AI context and asset-intent references; historical/archived packets retained as historical records; exact runtime migration gaps named with candidate follow-up packet boundaries, not implemented here.
- Current measured state: The new Highland Station design lock approves Receiver Key outside chapel and a station-original receiver gallery; runtime still uses Stilling Pin pickup/basin, passive historic materials and separate terminal state, with no new receiver component. `THE_ASH-BELL_CONTINUITY.md` has older Ninth-Station Pin prose; detailed encounter spec has old Bell-Clapper illustration; historical `ASH_BELL_IMPROVEMENTS.md` prioritizes Stilling Pin; route north seal has visual fade but egress is tracked separately.
- Evidence: `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_DESIGN_LOCK.md`; `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_ASSET_BRIEF.md`; `design/02_features/enemy_objective/FORLORN_RITUALANT_DIALOGUE_IDLE_AMBIENT_AUDIT.md`; active detailed spec; `custodian/game/world/events/ash_bell/forlorn_ritualant_site.gd`; `custodian/game/ui/inventory/inventory_item_catalog.gd`; `custodian/content/dialogue/ash_bell/forlorn_ritualant_dialogue.json`; `custodian/docs/ai_context/CURRENT_STATE.md`.
- Task-specific authority: `RECIPROCAL_CONTINUITY_DOCTRINE.md` and `THE_ASH-BELL_CONTINUITY.md` govern canon; new Highland Station lock governs approved future scene; live Godot code governs current implementation truth.
- Work surface: Active Ritualant / Ash-Bell `design/` docs; `custodian/docs/ai_context/CURRENT_STATE.md` and relevant `FILE_INDEX.md` references; active requirements/art handoff docs only if demonstrably misleading.
- Change:
  1. Inventory active occurrences of `Stilling Pin`, `Bell-Clapper Without a Bell`, `Ninth-Station Stilling Pin`, `SET PIN IN BASIN`, Highland station identification, chapel provenance and north egress statements. Separate CURRENT-RUNTIME, APPROVED-FUTURE, HISTORICAL-SUPERSEDED and unresolved canon statements; give path/line evidence.
  2. Resolve misleading **active** prose minimally. Use clear status headers/backlinks and bounded paragraph replacement. Do not globally rename `stilling_pin` state/data or historical design examples in a way that changes current runtime semantics.
  3. Detect contradiction with Station IX's distinct canonical location, its three-stage isolation, already-accepted Ninth Answer and geographically distinct Bridged Falls/Highlands.
  4. Validate that the Receiver Key is outside the chapel and its receiving socket belongs to station-original machinery, not the wrong Dry Fountain. Mark the exact I–VIII station numeral as reserved, not an invented fact.
  5. Identify runtime migration work needing its own task packet(s): key item and save flags, receiver authority, scene mapper/layout/art and north-route egress, dialogue/input and idle, presentation VFX, outcome audio. Do not implement those systems in this documentation packet.
  6. Add focused documentation-only regression protection for the authority split if the existing canon docs smoke supports it without broadening to unrelated scripts.
- Preserve: Historical archived packet evidence, current Stilling Pin mechanics and IDs, Station IX gameplay, lore ambiguity, all existing soundtrack files, route state and asset pipeline ownership.
- Non-goals: No new art, item or gameplay runtime changes; no new receiver simulation; no migration of Stilling Pin flags; no unrelated repo-wide lore editing; no edits to current queued runtime implementation packet contract without a separate authorized refresh.
- Acceptance: No active authority presents Stilling Pin as approved future design; current runtime state is accurately described as un-migrated; new design and dependency references resolve; Station IX/Highlands geography preserved; scope-limited canon docs tests and `git diff --check` pass.
- Validation: Start with targeted `rg -n 'Stilling Pin|Bell-Clapper|Receiver Key|Station IX|Ritualant' design/ custodian/docs/ai_context/` narrowed to active docs; run `python3 custodian/tools/validation/reciprocal_continuity_canon_docs_smoke.py`; focused `python3 custodian/tools/agent/validate_task_packet_authoring.py` for this pair before promotion; `python3 custodian/tools/validation/run_validation.py --changed --json` only when relevant.
- Task overrides: `none`
- Deferred: All physical room, item, combat, dialogue, actor, art, VFX, audio and route implementation.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh instruction: Fetch fresh `main`, run packet pair's authoring preflight and recheck all packet metadata; promote to `ready/auto` only when valid. This is authoring validation, not a new design decision.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Summary backlink: Include this exact URL in the implementation/review/correction closeout.
- Next action: Report remaining current-vs-future drift and propose bounded runtime migration workstreams for later approval.
- Blockers or open questions: Authoring preflight has not run in the execution repository; packet intentionally parked draft/manual until validated.
