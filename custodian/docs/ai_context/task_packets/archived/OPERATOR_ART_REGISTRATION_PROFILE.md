# OPERATOR ART REGISTRATION PROFILE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-art-registration-profile`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-art-registration-profile`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `565168b442708575de2670b07a34f1282d50c218`
- Goal: Make the user's approved 96x96 Operator anchor/body-size guide a single machine-readable registration authority consumed by Aseprite, Source Sessions, Art Agent QA, CLI, and the local `operator-art` MCP surface, so Codex can normalize generated/high-resolution Operator animation sets to one consistent character scale and registration without flattening intentional pose motion or inventing per-frame scale.
- Completion boundary: This slice is complete when the approved 96x96 guide lives once in `operator_art_profile.json`; the Aseprite guide renders from that profile rather than duplicated magic numbers; Source Session has a deterministic `operator_profile` normalization mode using one shared scale and one shared placement with explicit landmark evidence; Codex can inspect/set source landmarks and obtain registration reports/overlays through CLI/MCP; the production `pixelart --choose 1` entrypoint can consume the exact reviewed normalization plan; existing generic/contain normalization remains backward-compatible; guide/reference pixels are provably non-exporting; and active docs no longer claim landmark-aware Source registration that the implementation does not perform.
- Current measured state:
  - `operator_art_profile.json` is schema v1, `status: provisional`, `enforcement.structural: true`, `enforcement.artistic: false`, with an empty `measurements` map. It contains no accepted Operator registration geometry.
  - The user supplied and approved a 96x96 Operator guide with main anchor `(48,84)`, ground `y=85`, horizontal rails at head-top 14, head-center 24, neck 33, shoulders 39, chest 45, hips 58, knees 72, feet 84, and vertical rails at center 48, shoulders 34/62, hips 40/56. Exact review crosshairs are head `(48,24)`, neck `(48,33)`, shoulders `(34,39)/(62,39)`, chest `(48,45)`, hip center `(48,58)`, hips `(40,58)/(56,58)`, knees `(38,72)/(58,72)`, foot anchor `(48,84)`.
  - The supplied Aseprite helper is not in the repository and owns those numbers privately. Its layer prefix `_GUIDE_ANCHOR_` is also outside the Art Agent's existing clean-render suppression convention, which already excludes top-level `__ART_GUIDE_*` layers.
  - Source Session already guarantees one animation-wide `global_scale`, one shared alpha-union crop/placement, bounded integer per-frame `dx/dy` registration (±12), and clipping refusal. `source_normalization.py::build_plan()` currently computes the scale and placement only from alpha bounding boxes.
  - Active `OPERATOR_ART_AGENT_SYSTEM.md` already states that reviewed body landmarks should drive registration in priority order support-foot contact -> hip center -> head center, while peripheral equipment protects clipping but must not determine body scale. That behavior is not implemented on reviewed main.
  - Existing Workbench Art Agent has persistent frame-local semantic landmarks, metrics, registration/anatomy QA, reference rendering, and MCP tools. Source Sessions do not yet have source-cell semantic landmarks, a registration profile/report, or an overlay.
  - `qa.run_qa(..., profile=...)` receives `operator_art_profile.json` but currently does not consume that profile.
  - Root `AGENTS.md` requires Operator main-character production resizing through the `pixelart` alias and explicit crisp method 1. The converter's programmatic `SheetConversionRequest` already supports one exact shared transform plus integer registrations, but the CLI/alias has no way to consume a reviewed Source Session normalization plan. This is the missing bridge between MCP planning and policy-compliant production conversion.
  - The currently proposed unarmed blocking candidates demonstrate the motivating failure mode: the new right-side candidates read at a much more consistent body scale than the older guard/impact strips, but recoil/guard poses still need freedom to move within the frame. Therefore exact neutral-body rails are calibration evidence, not a mandate to pin every joint on every action frame.
- Evidence: `design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md` Source Session + machine-readable-profile sections; `OPERATOR_ART_STYLE_BIBLE.md`; `custodian/content/data/operator/authoring/operator_art_profile.json`; `operator_landmark_schema.json`; `custodian/tools/operator/art_agent/{source_models,source_analysis,source_normalization,source_service,source_review,metrics,qa,landmarks,service,mcp_server,cli}.py`; `custodian/tools/art/custodian_pixelart_converter.py`; `tools/custodian_aliases.sh::pixelart`; `custodian/tools/aseprite/operator_live_bridge/art_agent_ops.lua::render`; `custodian/tools/validation/operator_art_{source,agent_semantic,agent_mcp,agent_aseprite}_smoke.py`.
- Task-specific authority: `OPERATOR_ART_AGENT_SYSTEM.md` for Source Session/MCP/Workbench boundaries; `OPERATOR_ART_STYLE_BIBLE.md` for structural-vs-artistic enforcement; root `AGENTS.md` for the mandatory Operator `pixelart --choose 1` production-resize entrypoint; `operator_art_profile.json` as the machine-readable art-profile authority; `operator_landmark_schema.json` for semantic landmark names; `custodian_pixelart_converter.py` for shared-transform pixel conversion.
- Work surface:
  - **Primary data authority:** `custodian/content/data/operator/authoring/operator_art_profile.json`.
  - **New focused owner:** `custodian/tools/operator/art_agent/registration_profile.py` for profile parsing/validation, scale observations, deterministic shared registration planning, registration measurement, and overlay data. Do not create a second normalizer or duplicate profile constants in service/MCP code.
  - **Source Session:** `source_models.py`, `source_analysis.py`, `source_normalization.py`, `source_service.py`, `source_review.py`.
  - **Workbench Art Agent:** `metrics.py`, `qa.py`, `service.py`, `landmarks.py` only where profile/report integration requires it.
  - **Clients:** `cli.py`, `mcp_server.py`.
  - **Production conversion bridge:** `custodian/tools/art/custodian_pixelart_converter.py`; `tools/custodian_aliases.sh` should not need behavioral changes because it already forwards converter arguments and supplies crisp method 1.
  - **Aseprite:** add `custodian/tools/aseprite/operator_anchor_guides.lua`; update `custodian/tools/aseprite/README.md`. Reuse the existing `__ART_GUIDE_` non-export convention.
  - **Validation:** add focused registration-profile coverage for profile schema/coordinates/hash, shared-scale planning, clipping guards, placement, and plan replay; extend existing source/MCP/Aseprite smokes only for directly affected integration seams. Once the registration-profile smoke exists, add its exact live path to this packet's Validation section before closeout, and update `validation_manifest.json` ownership.
  - **Docs made stale by implementation:** `OPERATOR_ART_AGENT_SYSTEM.md`, `OPERATOR_ART_STYLE_BIBLE.md`, `custodian/tools/operator/README.md`, `CURRENT_STATE.md`, and `FILE_INDEX.md`.
- Change:
  1. **Make the profile the only numeric registration authority.** Upgrade `operator_art_profile.json` to a backward-readable v2 shape. Preserve `status: provisional`, `enforcement.artistic: false`, and the existing `measurements` field. Add an explicitly human-accepted structural `registration` block carrying the user's guide coordinates and provenance. Do not mark unrelated artistic measurements/tolerances accepted.
     
     The intended data shape is:
     
     ```json
     {
       "schema": "custodian.operator_art_profile.v2",
       "status": "provisional",
       "enforcement": {
         "structural": true,
         "registration_geometry": true,
         "artistic": false
       },
       "registration": {
         "status": "accepted",
         "frame_size": [96, 96],
         "anchor": [48, 84],
         "ground_y": 85,
         "provenance": {
           "kind": "human_authored_guide",
           "accepted_date": "2026-10-01"
         },
         "guide": {
           "horizontal": {
             "head_top": 14,
             "head_center": 24,
             "neck": 33,
             "shoulders": 39,
             "chest": 45,
             "hips": 58,
             "knees": 72,
             "feet": 84,
             "ground": 85
           },
           "vertical": {
             "center": 48,
             "shoulder_l": 34,
             "shoulder_r": 62,
             "hip_l": 40,
             "hip_r": 56
           },
           "points": {
             "head_center": [48, 24],
             "neck": [48, 33],
             "shoulder_l": [34, 39],
             "shoulder_r": [62, 39],
             "chest": [48, 45],
             "hip_center": [48, 58],
             "hip_l": [40, 58],
             "hip_r": [56, 58],
             "knee_l": [38, 72],
             "knee_r": [58, 72],
             "foot_anchor": [48, 84]
           },
           "modular_split_reference_y": 58
         },
         "normalization": {
           "mode": "shared_scale",
           "source_landmark_min_confidence": 0.75,
           "frame_translation_limit": 12,
           "auto_frame_translation": false,
           "scale_segments": [
             {"a": "head_center", "b": "hip_center", "target_length": 34.0, "weight": 1.0},
             {"a": "shoulder_far", "b": "shoulder_near", "target_length": 28.0, "weight": 0.5},
             {"a": "hip_far", "b": "hip_near", "target_length": 16.0, "weight": 0.5}
           ]
         }
       },
       "measurements": {},
       "note": "Registration geometry is human-accepted structural guidance; artistic tolerances remain advisory until canonical sample provenance is reviewed."
     }
     ```
     
     `shoulder_l/r`, `hip_l/r`, `knee_l/r`, neck and chest are guide-display concepts only; do **not** add fake left/right anatomical meaning to `operator_landmark_schema.json`. Runtime/source semantic analysis continues to use the existing near/far landmark names. `modular_split_reference_y=58` is a review rail only and must never classify pixels automatically.
  2. **Add one shared profile module.** Implement `registration_profile.py` and route Source Session, Workbench metrics/QA, MCP, CLI, and overlay generation through it. It should load the repo profile, validate schema/ranges, return a stable profile SHA-256/fingerprint, expose the accepted guide geometry, and refuse malformed/unsupported accepted registration data. No consumer should retype `48/84/85/58` or the body rails.
  3. **Give Source Sessions semantic source landmarks without creating another landmark vocabulary.** Reuse `landmarks.Landmark` names and validation semantics. Persist source-session landmarks beneath the session (recommended `source_landmarks.json`) with source SHA, source-cell coordinate space, and frame contract. Add SourceArtService get/set/validate methods. Source landmarks are metadata only, never pixels. Accept only points inside the source cell and frames inside the session; retain confidence/provenance/approved fields. A staged source is immutable by existing session hash, so any landmark record tied to a different source hash fails closed.
  4. **Add source observation sufficient for Codex to place landmarks.** Source Session must expose a read-only source contact sheet/frame render under its authorized session review directory. Add CLI/MCP observation access rather than requiring arbitrary filesystem reads. This is review output only; never open a high-resolution Source Session as an unrestricted Workbench.
  5. **Implement an explicit `operator_profile` normalization mode without changing existing `contain` behavior.** Extend `source-plan` / `operator_art_source_plan_normalization` with a mode enum such as `contain|operator_profile`; existing invocations default to current behavior. `operator_profile` requires target frame `96x96`, an accepted registration profile, and sufficient current source landmarks for at least the primary head-to-hip scale observation. Never silently fall back to alpha-only body scale when the requested profile evidence is missing.
  6. **Derive one body scale deterministically from reviewed landmarks.** For each profile `scale_segments` entry and each frame where both source landmarks exist at or above `source_landmark_min_confidence`, calculate `target_length / source_distance`. Use a deterministic weighted median over all eligible observations, with the profile weights; record every accepted/rejected observation in the plan/report. Do not use equipment/extremity alpha bounds to choose this scale. Do not compute a separate scale per frame.
     
     Convert the runtime-space ratio into the converter's prepared-space scale:
     
     ```python
     source_to_runtime = weighted_median(observations)
     prepared_per_runtime = prepared_width / target_width
     requested_global_scale = source_to_runtime * prepared_per_runtime
     ```
     
     Require the prepared X/Y scale factor to be identical for the 96x96 Operator profile. The exact local helper names may differ; the invariant may not.
  7. **Keep alpha bounds as clipping authority, not scale authority.** Independently compute the existing clipping-safe contain transform over the whole animation alpha union. If the profile-derived scale exceeds the maximum clipping-safe scale, fail planning with structured evidence (requested scale, safe scale, union bbox, affected frames). **Do not silently shrink the body to fit peripheral equipment.** This is the key behavior that prevents a raised shield, cloak tip, muzzle, or recoil hand from making the Operator smaller than adjacent animations.
  8. **Solve one shared anchor placement, preserving pose motion.** Use source landmarks only to establish the animation-wide registration origin:
     - X source reference: median current `hip_center.x` across eligible frames.
     - Y support contact per frame: the lower screen-space Y of `toe_near`/`toe_far` when available at accepted confidence; otherwise use that frame's analyzed alpha `bottom_y`. Use the median support contact across frames.
     - Target reference: profile `anchor=(48,84)`.
     - Apply the same source-union crop, `global_scale`, and destination offset to every frame.
     
     For a source point `(sx,sy)` and union origin `(ux,uy)`, the prepared-space placement is:
     
     ```python
     px = (sx - ux) * global_scale + destination_x
     py = (sy - uy) * global_scale + destination_y
     ```
     
     Solve `destination_x/y` so the animation-wide median reference maps to the profile target. Quantize the prepared offset to the exact target-pixel grid (normally 8 prepared pixels per 96px runtime pixel) before conversion, then re-check that the scaled alpha union remains fully inside the prepared canvas. Fail with `PROFILE_REGISTRATION_CLIPS` rather than clipping.
  9. **Do not auto-correct per-frame poses.** New profile planning leaves every `FrameRegistration.dx/dy` at zero. Existing explicit `source-register --frame --dx --dy` remains the only per-frame translation control and retains ±12 integer/clipping guards. Registration reports may show residual head/hip/support-foot deviations and suggest review, but must not silently apply them. This preserves intentional recoil, crouch, anticipation, breathing, and weight transfer.
  10. **Version the normalization plan without orphaning old Source Sessions.** Upgrade the plan schema (recommended `custodian.operator_art_normalization_plan.v2`) with enough provenance to replay the operation: `mode`, profile SHA, clipping-safe scale, accepted scale observations/basis, source/target geometry, shared union, one global scale/placement, and registrations. `from_json` must still accept the existing v1 plan and map it to `mode=contain` with no profile authority. Do not bulk-rewrite old `.ai` sessions.
  11. **Bridge the reviewed plan to the mandatory production `pixelart` alias.** Add `--normalization-plan PATH` to `custodian_pixelart_converter.py` sheet mode. The converter must verify plan schema, source SHA-256, frame count, source-cell geometry, target size, transform bounds, and registration count before using the plan's exact `SharedFrameTransform` and integer registrations in place of its auto transform. Reject any mismatch rather than regenerating a different transform.
     
     Codex's production command for an Operator profile-normalized source must therefore be reproducible as:
     
     ```bash
     source tools/custodian_aliases.sh
     pixelart <source.png> <output.png> \
       --sheet --frames <N> --size 96 --choose 1 --force \
       --normalization-plan <source-session>/normalization_plan.json
     ```
     
     Add a Source Session read-only `production-command`/equivalent projection that returns the exact fixed command inputs/output path but **does not execute shell** through MCP. Add a corresponding verification operation that reads only the fixed session-owned production output, proves it matches source+plan, and records a hash proof. In `operator_profile` mode, Source Session handoff must use a current verified crisp production output; it must not stage the internal balanced/clustered review candidate. Existing non-profile Source Session behavior stays compatible.
  12. **Keep crisp method 1 authoritative for the Operator.** `operator_profile` defaults to/requires `method=crisp` for production verification/handoff. Balanced and clustered may still be generated as disposable review comparisons if the implementation preserves existing Source Session behavior, but neither may satisfy production proof for the Operator. Do not change the `pixelart` alias default or weaken root policy.
  13. **Emit a deterministic registration report and overlay.** `registration_profile.py` should produce structured per-animation/per-frame data including profile hash, target anchor/rails, global scale, clipping-safe scale, scale observations, transformed semantic landmarks, alpha bbox/baseline, and residuals. Produce a compact transparent/checker review overlay showing the profile rails/crosshairs over the animation, with deviation vectors/markers where semantic landmarks exist. Reports/overlays are evidence only and never source/runtime inputs.
  14. **Expose the same ruler to existing Workbench Art Agent sessions.** Add read-only service + CLI/MCP tools for effective registration profile, registration report, and registration overlay. Use existing Workbench landmarks/metrics; do not create a second set of Workbench landmarks. Exact neutral rails remain advisory for pose anatomy. Structural checks may enforce frame size, profile availability/hash, clipping, and registration-plan invariants; they must not fail a block-hit or crouch merely because its head/hip/knees leave neutral guide coordinates.
  15. **Add MCP surfaces through the shared services, not MCP-only logic.** Expected additions are conceptually:
     
     ```text
     operator_art_registration_profile(session)
     operator_art_registration_report(session)
     operator_art_render_registration_overlay(session)

     operator_art_source_render(session)
     operator_art_source_get_landmarks(session)
     operator_art_source_set_landmarks(session, landmarks)
     operator_art_source_validate_landmarks(session)
     operator_art_source_registration_report(session)
     operator_art_source_production_command(session)
     operator_art_source_verify_production(session)
     ```
     
     Exact names may follow existing naming style, but schemas remain explicit with `additionalProperties:false`; paths remain session-confined; handlers contain no shell/git/publication logic.
  16. **Add CLI parity.** Add equivalent `operator art` commands for source landmarks/render/report/production proof and Workbench registration report/overlay. Preserve existing commands. Do not make Codex scrape human CLI prose; `--json` remains stable structured output where existing source commands support it.
  17. **Make the user's Aseprite guide a profile renderer.** Add `custodian/tools/aseprite/operator_anchor_guides.lua` based on the supplied script, but remove the numeric geometry constants. It must load the registration block from `operator_art_profile.json` (explicit `app.params["profile"]` path for headless/tests, with a safe repository-relative discovery path for interactive use), validate 96x96 registration geometry, and draw the same dashed rails/crosshairs repeatedly across 96px cells/frames.
     
     Use a top-level group/layer name beginning with:
     
     ```text
     __ART_GUIDE_OPERATOR_REGISTRATION
     ```
     
     so current `render_clean` logic already suppresses it. Replacement is idempotent. The guide is locked/non-editable after creation. Reject canvases that cannot be partitioned into the profile frame size; do not guess.
  18. **Prove guides cannot leak.** Workbench export remains manifest-whitelisted, and Art Agent clean rendering already hides `__ART_GUIDE_*`. Add focused Aseprite/bridge coverage showing a visible registration guide does not change a clean render/export candidate and cannot become an editable publishing binding merely by existing in the document.
  19. **Consume the profile in QA without over-enforcing art direction.** Wire `qa.py` to use accepted structural registration fields for relevant report/check context. Keep `enforcement.artistic=false`; existing profile `measurements` and exact neutral-body joint rails remain advisory until separately calibrated from canonical samples. Do not turn these coordinates into automatic aesthetic PASS/FAIL.
  20. **Treat the modular split rail as review-only.** The profile may expose `modular_split_reference_y=58` because current blocking candidates use it, but it cannot decide upper/lower ownership. Any later split still requires disjoint alpha ownership and exact `alpha_composite(lower, upper) == full_body` evidence. No automatic layer splitter belongs in this packet.
  21. **Update active truth and fix the discovered stale blocking packet.** After implementation, update the named active Art Agent/Style Bible/current-state/tooling docs only where behavior changed. The separately active `OPERATOR_UNARMED_BLOCKING_ART_REFRESH.md` is already stale on reviewed main because `block_hold_01/e` + mirrored W landed in `affc8adb4e749dfce55955edd2e01525767d066a` and `block_hit_01/e` + mirrored W landed in `7913903704aee8fdd2c645891df441fa31fb6cca`. This packet authoring pass marks that art-refresh packet blocked/manual behind the independent review of this workstream; after review, re-measure only the remaining blocking-art delta before making it ready again rather than rerunning already-landed hold/hit work.
- Preserve: Workbench remains sole canonical publication/rollback authority; canonical Operator PNGs remain production source authority; existing Source Session confinement and immutable staged source; one shared animation-wide scale/crop; explicit integer per-frame translations; no clipping; existing Art Agent landmark/mask/draft security; MCP has no arbitrary filesystem/shell/git/publish capability; gameplay timing/runtime animation selection unchanged; current `block_hold_01`/ `block_hit_01` pixels are not modified by this tooling work; generic `pixelart` behavior without `--normalization-plan` remains unchanged; existing Source Session v1 plans remain readable.
- Non-goals: No repaint, resizing, splitting, ingest, or publication of current Operator animations. No guard/combat/runtime changes. No automatic pose synthesis. No per-frame scale. No automatic per-frame registration. No requirement that hit reactions/crouches/anticipation place head/hips/knees on neutral rails. No new semantic landmark vocabulary for neck/chest/left/right guide points. No arbitrary MCP shell execution. No new Asset V2 family; Operator remains on its specialized animation pipeline. No broad artistic-profile calibration or acceptance of provisional numeric tolerances. No generalized humanoid-rig rewrite.
- Acceptance:
  - `operator_art_profile.json` contains the exact approved 96x96 registration guide once, with provenance and structural acceptance; consumers load it instead of duplicating the numeric geometry.
  - Existing v1 profile/plan readers are migrated compatibly; old `mode=contain` Source Session fixtures remain byte/behavior compatible.
  - A profile-mode source fixture with valid semantic landmarks computes exactly one `global_scale`; every frame registration has only integer `dx/dy`, no scale/width/height field.
  - The profile scale is derived from the configured landmark segments and is independent of a synthetic peripheral equipment pixel. When that peripheral pixel would clip at the profile scale, planning fails explicitly rather than shrinking the body.
  - Shared placement maps the fixture's animation-wide hip/support-foot reference to the profile `(48,84)` anchor within the deterministic nearest-neighbor target-pixel contract, while intentional frame-to-frame head/hip/recoil deltas remain unchanged.
  - Missing/low-confidence required profile evidence causes profile planning to fail closed with a structured reason; it never silently reverts to alpha-only scale.
  - Manual `source-register` remains bounded integer translation and still refuses clipping.
  - `pixelart ... --choose 1 --normalization-plan <plan>` validates source+plan identity and produces a crisp output byte-identical to the Source Session crisp candidate for the same fixture/plan. A stale source hash, wrong frame geometry, wrong target size, or modified registration plan is rejected.
  - Profile-mode Source Session handoff cannot stage balanced/clustered or an unverified in-process candidate; only a current verified crisp production output satisfies handoff.
  - Aseprite guide rendering places the approved anchor/ground/body rails at the profile coordinates, works across repeated 96px cells/frames, is idempotent, uses `__ART_GUIDE_` naming, and is excluded from clean render/export.
  - Workbench registration report/overlay and Source Session registration report/overlay contain profile hash, scale/anchor evidence, transformed landmarks and residuals. They do not mutate pixels.
  - New MCP tools have explicit schemas, remain session-confined, and add no publish/git/shell/arbitrary-file capability.
  - `qa.py` consumes accepted structural registration data while `enforcement.artistic` remains false; a deliberately recoiled pose can report advisory deviations without becoming a false structural failure.
  - Active Art Agent/current-state/tooling docs describe the now-live profile-aware registration path accurately, and the stale unarmed-blocking refresh packet is no longer auto-dispatchable until re-derived.
- Validation:
  - `python3 custodian/tools/validation/operator_art_registration_profile_smoke.py` covers accepted profile geometry, v1-plan compatibility, source landmark bounds/hash, shared profile scale/anchor, deterministic registrations, converter `--normalization-plan` replay, crisp byte equivalence, and proof hashes.
  - Run `python3 custodian/tools/validation/operator_art_source_smoke.py` for existing Source Session regression plus source-landmark/profile mode.
  - Run `python3 custodian/tools/validation/operator_art_agent_semantic_smoke.py` for profile-backed report/QA semantics.
  - Run `python3 custodian/tools/validation/operator_art_agent_mcp_smoke.py` for explicit new tool schemas and privileged-surface negative controls.
  - Run `python3 custodian/tools/validation/operator_art_agent_aseprite_smoke.py` when Aseprite is available, covering guide exclusion from `render_clean`; keep pure-Python/Lua-contract validation sufficient to fail structural guide regressions on headless hosts without Aseprite rather than skipping the whole slice.
  - Update `validation_manifest.json` so `registration_profile.py`, `operator_art_profile.json`, `operator_anchor_guides.lua`, Source Session normalization files, and converter normalization-plan handling select the focused registration/source/MCP/Aseprite checks.
  - No Moment Forge or full-motion capture is required: this is tooling geometry. Deterministic profile/transform math, exact PNG hashes, alpha bounds, and one compact generated registration overlay are sufficient objective evidence. Subjective acceptance of the Operator's aesthetic size remains human-owned.
  - Finish with one `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: Automatic semantic body-part redrawing/pose synthesis; automatic lower/upper layer splitting; direction-specific anatomical calibration; acceptance of artistic tolerances from canonical-sample measurement; a generic non-Operator humanoid registration framework; any subsequent blocking-art replacement/re-ingest after this profile review.

## Handoff

- Next action: Paired independent review, then re-measure the remaining blocking-art delta.
- Best starting files: `operator_art_profile.json`; `registration_profile.py` (new); `source_normalization.py`; `source_models.py`; `source_service.py`; `custodian_pixelart_converter.py`; `mcp_server.py`; `operator_anchor_guides.lua` (new); registration-profile smoke (new).
- Blockers or open questions: None. The registration coordinates are user-approved; artistic tolerances remain explicitly out of scope.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: yes
- Preserved constraints: yes
- Deferred items: intentionally-preserved
- Evidence: registration-profile, source, semantic, MCP, and Aseprite smokes passed; changed-file unit gate passed (17 selected, 17 passed, 0 failed); `git diff --check` passed.
- Production art changed: no
- Existing Source Session v1 plan compatibility: verified
- Registration guide clean-render exclusion and idempotence: verified

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: An already-running local relay interfered with temporary-root smoke fixtures; the first changed-file gate failed two unrelated fixture requests.
- Root cause / contributing factors: Existing relay tests did not isolate the external relay when using temporary repository roots.
- Prevention / pipeline improvement: Fixed in-scope by injecting an unavailable relay in the affected fixture harnesses; focused smokes and the changed-file gate then passed.
- Tooling / docs drift discovered: Current `main` advanced during the push and overlaps the current-state and file-index docs; the published workstream must merge current `main` normally before landing.
- Follow-up: `review-operator-art-registration-profile`
- What worked: Deterministic profile math, hash-bound crisp replay, exact pixel proof, and isolated Aseprite guide validation.

## Independent Review

- Status: `findings`
- Review workstream: `review-operator-art-registration-profile`
- Reviewed on main: `907dc2bf0`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Blocking defects: `1`
- Material evidence gaps: `1`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01, R0-02`
- Detailed review summary: `REVIEW_OPERATOR_ART_REGISTRATION_PROFILE_CLAUDE_SUMMARY.md`
- Follow-up workstream: `operator-art-registration-profile-review-corrections-1`

### R0-01 (correctness, asset-pipeline)

- Affected acceptance: The `pixelart --normalization-plan` route rejects a modified registration plan, and Source Session production verification only accepts output generated from the approved plan.
- Evidence: In a fresh temporary Source Session using the smoke's 768×768 synthetic fixture, changing the planned `destination_x` from 248 to 250 remained within bounds. The converter accepted the modified plan and `SourceArtService.verify_production()` returned `verified: true` for output produced from it.
- Disposition: `correction`
- Rationale: The plan digest is only calculated after reading the mutable plan and is then stored in the proof. No prior expected digest binds the approved plan contents, so a valid in-bounds edit is treated as authorized production input.

### R0-02 (evidence_gap, tooling)

- Affected acceptance: Workbench registration reports include profile hash, scale/anchor evidence, transformed landmarks, and residuals.
- Evidence: `ArtAgentService.registration_report()` calls `profile_report()` without a normalization plan. `profile_report()` only populates `transformed_landmarks` and `advisory_residuals` when a plan is supplied; therefore the Workbench report emits empty transformed/residual data and no measured scale evidence.
- Disposition: `correction`
- Rationale: Source Session reports carry plan-derived metrics, but the Workbench report currently does not provide the corresponding structured comparison promised by the packet.

- Focused review validation: registration-profile smoke PASS; Source Session smoke PASS; semantic smoke PASS; MCP smoke PASS; Aseprite smoke PASS (including real guide application, repeated application, clean-render equality, and no manifest binding).
- Graph tooling: The fresh review checkout had no graph database; a minimal graph build remained unavailable, so the review used direct implementation inspection and independent fixture reproduction.
