# VISUAL VALIDATION ECONOMY TOOLING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `visual-validation-economy-tooling-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `second-pass-review-contract-v2`
- Locks: `moment-forge-tooling`
- Kind: `implementation`
- Review: `auto`
- Reviewed main: `a76736f`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-visual-validation-economy-tooling-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Make CUSTODIAN presentation validation code-first and low-token by replacing repeated model inspection of full-resolution captures with reusable structured probes, deterministic image metrics, targeted ROI/contact-sheet evidence, and explicit escalation only when renderer pixels or subjective judgment are actually necessary.
- Completion boundary: Extend the existing Moment Forge / validation stack rather than creating a parallel visual-QA system. Add reusable presentation probes and assertions, offline code-based image metrics, ROI/contact-sheet generation, and direct scenario adapters for the currently queued high-visual-cost workstreams. Update active tooling/docs so implementation and paired-review agents consume structured evidence first and only inspect minimal renderer evidence when machine checks cannot settle acceptance. Done means the named upcoming packets can prove most objective visual requirements in `capture-mode none` or from machine-generated metrics, and their optional renderer evidence is compact, targeted, reusable by paired review, and human-gated for subjective acceptance.
- Current measured state: Moment Forge already has fixed-tick scenarios, a generic `moment_probe_collector.gd`, dotted-value reads, probe assertions, `capture-mode none/evidence/full`, keyframes/contact sheets, image/audio analysis hooks, and reports. However the current probe collector exposes only a small set of presentation fields, the assertion layer cannot directly compare two probe records/ticks, and packet authors still request multiple full-frame captures for objective facts such as registration, alpha/visibility, duplicated presentation, seam continuity, overlay bounds, or state correspondence. High-load queued examples include five late Awakening seam captures plus an independent review; Twin Solaria forensic baseline/Stage-B/Stage-F captures plus review; Solarium I dormant/candidate/resolve/stable/warning captures plus review; Operator mobile-guard runtime-scale enter/hold/exit evidence; and Vaultwing bonding closure where geometry/alpha/registration can be measured without inspecting every direction/frame manually.
- Evidence: `custodian/tools/iteration/godot/moment_probe_collector.gd` currently reads role fields plus position/animation/frame but not effective presentation bounds/alpha/z/texture metrics; `moment_assertion_evidence.gd` supports one-record `probe_compare` but not direct forward/reverse or cross-tick probe equality/delta; `moment_schema.json` already has probes/assertions and should be extended rather than replaced; `VALIDATION_RECIPES.md` and AGENTS now require visual-evidence economy; active packets `AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md`, `TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS.md`, `TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION.md`, `OPERATOR_MOBILE_GUARD_COMPOSITION.md`, and `VAULTWING_BOND_GREET_FINAL_INGEST.md` contain renderer-evidence requirements that can be substantially reduced with reusable probes/metrics.
- Task-specific authority: `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; root and local `AGENTS.md` Visual Validation Economy rules; `custodian/tools/iteration/` live schema/runner/probe/report code; `design/02_features/testing/AGENT_HEADLESS_TEST_LAYER.md`.
- Work surface: Primary owners are `custodian/tools/iteration/godot/moment_probe_collector.gd`, `moment_assertion_evidence.gd`, `moment_value_reader.gd`, `custodian/tools/iteration/moment_schema.json`, `run_moment.py`, report generation, and focused Moment Forge validation. Add one small reusable offline presentation-image metrics/crop helper under `custodian/tools/iteration/` or `custodian/tools/analysis/` rather than task-local scripts. Add narrowly scoped scenarios/fixtures for the direct adopter packets below where doing so avoids repeated bespoke captures. Update FILE_INDEX/tooling docs/validation recipes only as owned truth changes.
- Change:
  1. Extend generic Moment probes with stable presentation facts needed by multiple tasks: visibility, modulate/self-modulate/effective alpha, texture/frame size, global and screen-space presentation rect/bounds where well-defined, z-index/z-as-relative/effective draw order where safely derivable, AnimatedSprite2D animation/frame/frame-progress, and collision/navigation ownership presence where a presentation node must remain non-authoritative. Do not hard-code Twin/Awakening-specific node names into the generic collector.
  2. Add generic cross-record assertions so scenarios can compare one probe field across ticks/roles, including exact equality, numeric delta/range, and forward/reverse steady-state equivalence. Preserve existing scenario compatibility.
  3. Add a deterministic offline presentation-image metrics helper that accepts one or more PNGs plus named ROIs/expected seam lines and emits JSON. At minimum support alpha bounding box/coverage, opaque-border or matte/void detection, ROI changed-pixel ratio / mean absolute difference, edge/seam discontinuity across a declared horizontal/vertical boundary, and exact crop extraction. Metrics must be threshold-configurable and report raw values; they are technical evidence, not aesthetic scoring.
  4. Add compact ROI/contact-sheet output so an evidence run can turn several full renderer frames into one small review sheet of only the relevant regions. Reports should surface structured metrics/probes first and list raw full-frame evidence as secondary artifacts. Agent instructions must not imply the images need model inspection when all objective assertions are already green.
  5. Keep `capture-mode none` as the iteration default. Add the smallest convenient mechanism to run metrics/ROI evidence only when renderer pixels are actually requested by the scenario or after deterministic checks are green. Do not add a second scenario runner or duplicate Moment Forge scheduling.
  6. Build direct reusable adopters:
     - **Awakening late joins:** one deterministic seam scenario/fixture covering 05→06, 06→07, 07→08, 08→10, and optional 08↔09. In no-capture mode record room/foreground visibility, alpha, registered bounds, draw order, Operator/path sample coverage, and forward/backtracking equivalence. In evidence mode emit one compact five-cell seam ROI sheet, not five full-screen images for routine agent inspection.
     - **Twin Crown forensics:** one progression scenario/probe for baseline, Stage B, and Stage F. Prove overlay hidden/visible state, expected world registration/bounds, no collision/navigation authority, no duplicate landmark runtime node/resource, and deterministic restore. Renderer evidence, when needed, is one tight Second-Crown ROI contact sheet across the three states.
     - **Twin Solarium I acquisition:** one state-sequence scenario/probe for dormant, candidate, resolve midpoint, stable, and warning/shutdown. Prove presentation-state mapping, animation/state/progress, aperture/anchor/witness registration, route-authority snapshot immutability, no Passage/exit, and stale-one-shot cancellation. Renderer evidence, when needed, is one tight aperture/instrument ROI contact sheet across the requested states.
     - **Operator mobile guard:** reuse the generic cross-tick probes to verify lower/upper semantic actions, lower-frame/progress continuity, movement-vs-aim direction divergence, and enter→hold→exit without requiring full-frame review on every iteration. One small runtime-scale contact sheet is sufficient for final technical evidence if the deterministic probes are green.
     - **Vaultwing bonding ingest:** expose/reuse alpha/silhouette/registration/frame-cell metrics so 24/24 runtime closure can be proven mechanically. Generate a compact direction/contact sheet only for final human spot-check or when metrics flag a suspect strip; do not visually inspect all cells by default.
  7. Update reusable docs/tool indexes and add focused schema/probe/metrics/scenario tests. Keep all subjective baseline/art-direction decisions outside automated scoring.
- Preserve: Existing Moment Forge scenario IDs and V1 compatibility; fixed-tick determinism; current `none/evidence/full` semantics; raw evidence availability for a human when needed; existing focused smokes as authority for gameplay/state contracts; human ownership of subjective visual baselines; Asset V2 ownership of runtime art; no presentation metric may mutate simulation/runtime state.
- Non-goals: No computer-vision aesthetic grader; no automatic art-quality score; no mandatory baseline replacement; no broad rewrite of Moment Forge; no removal of screenshots/video when genuinely necessary; no converting pixel metrics into collision/gameplay authority; no task-specific art fixes; no automatic subjective approval.
- Acceptance:
  - Existing Moment Forge scenarios remain schema-valid and current focused suite stays green.
  - Generic probes can machine-report the new presentation fields without requiring task-local inspection helpers.
  - Cross-tick/role assertions can prove forward/reverse or state-equivalence cases without reading screenshots.
  - The image-metrics helper emits deterministic JSON for synthetic fixtures covering alpha bounds, matte/void, seam discontinuity, ROI diff, and crop generation, with negative controls that fail as expected.
  - A compact ROI/contact-sheet path exists and does not require an agent to ingest the original full frames when objective metrics already settle acceptance.
  - The five direct-adopter scenarios/probe paths above are either implemented in this slice or, where a dependency makes live scenario construction impossible, a tested reusable fixture/spec is committed that the dependent packet can instantiate without new tooling design.
  - The Awakening seam adopter can cover all five late joins with one structured run and at most one compact ROI sheet for final technical review.
  - Twin forensic and acquisition adopters expose their required staged presentation facts as JSON and use targeted ROI sheets instead of three/five routine full-screen inspections.
  - Paired reviews can reuse the implementation report/metrics/evidence paths and are not instructed to regenerate equivalent captures.
  - FILE_INDEX, VALIDATION_RECIPES, AGENT_TOOLING_BY_ASK, and Moment Forge design/README truth match the implemented tool surface.
- Validation: Start with unit/schema tests for probe fields, cross-record assertions, and image metrics using synthetic images. Run the Moment Forge schema/report/runtime focused suite, then each new direct-adopter scenario in `--capture-mode none`. Run exactly one evidence-mode proof per adopter only where the scenario can execute on current main; verify the generated ROI/contact sheet and metrics manifest without model-vision review. Finish with one `run_validation.py --changed --json` closeout sweep. No `--capture-mode full` is required for this tooling task.
- Task overrides: `none`
- Deferred: Sophisticated perceptual/aesthetic scoring; automatic baseline approval; broad migration of historical packets; GPU/computer-vision models; audio-only optimization beyond existing Moment Forge analysis; any direct product-art correction discovered by the new metrics.

## Direct Adopter Inventory

Measured high-visual-cost queued work at authoring time:

| Packet / workstream | Existing visual burden | Tooling target |
| --- | --- | --- |
| `AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1` + review | five late join captures, then independent re-inspection | structured registration/alpha/coverage/seam metrics + one five-ROI sheet |
| `TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS` + review | baseline / Stage B / Stage F captures | overlay bounds/authority/state probes + one three-state Second-Crown ROI sheet |
| `TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION` + review | dormant / candidate / resolve / stable / warning captures | state/animation/authority probes + one five-state aperture ROI sheet |
| `OPERATOR_MOBILE_GUARD_COMPOSITION` | moving enter / hold / exit runtime-scale evidence | lower/upper action + frame/progress continuity probes, optional three-state ROI sheet |
| `VAULTWING_BOND_GREET_FINAL_INGEST` | potential multi-direction/frame manual closure | alpha/silhouette/registration/frame metrics, one compact direction sheet only if useful |

## Handoff

- Next action: Auto-claim and implement the generic probe/metric primitives first, then the direct-adopter scenarios in the order above.
- Best starting files: `moment_probe_collector.gd`, `moment_assertion_evidence.gd`, `moment_schema.json`, `run_moment.py`, report builder, existing Moment Forge schema/runtime/report smokes, and the named packet scenarios/fixtures.
- Blockers or open questions: Dependency only on `second-pass-review-contract-v2`, so paired review artifact completion is hardened before this tooling enters its own review cycle. If a direct adopter is impossible to instantiate because its runtime feature has not landed yet, commit the reusable generic tool plus a schema-valid fixture/scenario template and leave feature-specific wiring to that dependency packet.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: a fresh ephemeral worktree silently rendered degenerate (1x1 fallback) textures instead of failing loud, which almost let a false-positive registration-match assertion through before real art was confirmed.
- Root cause / contributing factors: worktree creation does not run `git lfs pull`, so the git-lfs-tracked LimboAI GDExtension `.so` stayed an unsmudged pointer stub, failed to load, and cascaded into ~9000 unrelated texture/audio import failures; `Sprite2D.get_rect()` degrades to a non-null `1x1` rect rather than erroring when its texture failed to load.
- Prevention / pipeline improvement: `workstream.py`/`dispatch.py` worktree setup should run `git lfs pull` (or verify LFS smudge state) before any Godot invocation in a new worktree.
- Tooling / docs drift discovered: `AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1`'s `Validation` line forward-references a smoke script its own implementation is meant to create; the current packet-index/validator tooling flags that as a hard "missing validation script" block on a `ready`, not-yet-implemented packet.
- Follow-up: `manual-follow-up` — both findings are good small correction packets under `agent-workstream-lifecycle` and `ai-context-task-packet-validator` ownership respectively; neither is fixed in this scope.
- What worked: the generic-probe design needed zero bespoke fixture logic for registration/alpha/collision facts in the Awakening seam adopter — only camera-positioning commands — because probes read the real production `Sprite2D` nodes directly.

See `VISUAL_VALIDATION_ECONOMY_TOOLING_V1_CLAUDE_SUMMARY.md` at the repository root for the full closing summary, including copy-paste templates for the four adopters whose runtime doesn't exist yet.
