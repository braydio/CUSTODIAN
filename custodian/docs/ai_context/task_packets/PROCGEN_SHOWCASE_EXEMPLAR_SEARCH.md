# Procgen Showcase Exemplar Search

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-exemplar-search`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-showcase-exhibit-catalog, review-procgen-showcase-generation-controls, review-procgen-showcase-runtime-inspector`
- Locks: `procgen-showcase-exemplar`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-showcase-exemplar-search`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `none`
- Goal: Make SHOW IN GENERATED WORLD locate a truthful accepted seed containing an inspectable semantic exhibit without forcing unsupported generation features.
- Completion boundary: Ship the exact PGA-6 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: Catalog will declare candidate_query capability; real candidate materialization is expensive and can reject generated candidates; no generic force-feature hook is verified.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exemplar_resolver.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_controls.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_session.gd`, `custodian/content/data/dev/procgen_showcase/exhibits.v1.json`, `procgen_showcase_exemplar_smoke.gd` (planned in `custodian/tools/validation/levels/`), `custodian/tools/validation/validation_manifest.json`.
- Change: Implement bounded, cancellable deterministic seed search over the ACTUAL accepted generation API and read-only semantic predicates. Only manifest entries with proven canonical predicate support enable the button; inspect_only stays disabled with explanation. Enumerate seed candidates by fixed documented order and explicit cap, record attempts/results/failure, then select matching accepted map and navigate Operator to valid nearby clear spawn if available. Cache only immutable seed+profile+version=>matched metadata; reject cache after semantic/model version changes. Never insert an exhibit directly, override terrain, reroll invisibly, or claim a hit from preview-only snapshots.
- Preserve: Candidate acceptance, map/profile seed determinism, no indefinite loops/performance runaway, no unseen manipulation of gameplay generation.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: Positive fixture reproduces same matching seed and actual in-world semantic proof; negative fixture stops with NOT_FOUND and no map mutation; cancellation releases work; unsupported entries remain truthful unavailable.
- Validation: NEW exemplar-smoke with bounded positive/negative/cancel and actual accepted-map identity; candidate evaluator/materializer and playability focused tests; changed/diff.
- Task overrides: `none`
- Deferred: Potential topology forcing requires a separate explicit production generator design, not a dev-only hack.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Preparatory implementation audit (2026-10-15; live main `96c44f5444abb87eb5c054ad883e69d023ff845f`)

**This is a preparatory exact-path implementation plan, not the final realized-API refresh.** PGA-6 is still `draft/manual`; the relevant predecessor reviews and direct API checks named below remain mandatory. Do not add `Authoring handoff: auto`, promote, or claim as a result of this section.

### Predicate/accepted-world search boundary (pre-PGA-2/PGA-5 freeze)
- `custodian/content/data/dev/procgen_showcase/exhibits.v1.json` must first supply a **reviewed** `candidate_query` capability for the selected entry. `inspect_only` and unknown predicates always remain UI-disabled as `UNSUPPORTED`; never silently synthesize a query from a plinth label or image.
- `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exemplar_resolver.gd` owns a bounded candidate list, `search_id` revision, explicit candidate iteration order and result statuses `MATCH`, `NOT_FOUND`, `UNSUPPORTED`, `FAILED`, `CANCELLED`. An accepted map + actual inspector semantic proof is mandatory for MATCH. Reject 'match' on a pre-acceptance candidate or renderer similarity.
- Use **landed PGA-4** session/host for generation and cancellation and **landed PGA-5** detached inspector fields for the truth predicate. The resolver may drive those interfaces but must not call lower-level `ProcGenTilemap` mutation or override `CustodianContractMap` candidate order, ingress constraints or rejection logic.
- Choose a finite configurable maximum attempts and a serialized execution budget *after* measuring real generation latency; no invented low-latency default or unbounded retry after slow/failing seeds. Keep only one resident accepted map. An externally cancelled or newer search invalidates previous completions; cleanup stays with the session/host.
- Cache only a positive verified acceptance receipt keyed by seed, complete effective profile/settings, semantic predicate ID/version and generator/runtime contract version. Revalidate in the newly realized map; a stale/missing key is a MISS, not fabricated HIT. Return detailed reasons for failed acceptance vs no matching accepted world.
- Planned `procgen_showcase_exemplar_smoke.gd` under `custodian/tools/validation/levels/`: actual positive world, guaranteed unsupported entry, finite negative budget, cancellation during build, stale callback, no map/actor leak and unchanged accepted-world fingerprint; register exact owners in `validation_manifest.json`.

### Required *final* refresh after PGA-2/PGA-4/PGA-5 reviews
List *only* catalog entries with verified read-only predicates from landed PGA-5 and measure their accepted-world generation costs. If none is genuinely queryable, do not release a fake 'show me' implementation; retain `draft/manual`, report a scoped missing predicate authority, and bring the decision back to the planning chat.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `not-recorded`
- Refresh instruction: `Refresh actual exhibit predicate capability and live accepted-map/candidate costs; decide feasibility for requested exemplar categories without fake forcing.` Bring the exact predecessor closing summary/review finding IDs plus refreshed `origin/main` code paths to this planning chat. Reconcile ownership and test paths; then run targeted paired authoring preflight, promote both to ready/auto and regenerate managed README. Never self-promote this draft from dependency completion alone.

## Next Handoff
- Next workstream: `review-procgen-showcase-exemplar-search`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
