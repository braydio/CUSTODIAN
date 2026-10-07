# AWAKENING HANDOFF READINESS + ART CONVERGENCE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-handoff-readiness-art-convergence-v1-r1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-awakening-room-connectors-polish, review-awakening-lower-upper-spine-connection`
- Locks: `awakening-runtime, awakening-art-registration`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-handoff-readiness-art-convergence-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `777c1b1d4a1642ba3921b2b569d8864b32cea9f6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Make the complete Awakening / The First Return scene a trustworthy production handoff source for the later Hub runtime by locking its current art registration and seam behavior to the Layout authority, closing objective overlap/registration defects found by visual evidence, exposing a clean completion/handoff signal without performing the Hub transition, and reconciling stale Awakening documentation with live runtime truth.
- Completion boundary: Validate and, only where evidence proves a defect, correct presentation registration/seams across Zones 01–10 while preserving authored gameplay geometry; formalize the South Reach completion API that the next world-lifecycle slice can consume; add focused structural/visual validation; reconcile the Awakening asset-consumption ledger and known art gaps; repair current documentation drift. Done means the current scene can be traversed from Crèche wake to South Reach with production art registered to the existing spatial authority, all mandatory joins have explicit evidence, completion requires the opening console plus P-9, and a later Hub transition can subscribe to one production-named completion seam without depending on debug/blockout wording.
- Current measured state: This packet now follows two explicit P0 corrections. First, `awakening-room-connectors-polish` replaces the wrong legacy 04→05 crop-derived sprite with the exact approved `connector.png`, preserving the full alpha silhouette and re-deriving canvas/transform rather than assuming 1024×576 at `(352,-2464)`. Second, `awakening-lower-upper-spine-connection` converts the split Dust Lung→Undergate route into one semantic 128×96 05→06 passage and proves real-Operator continuity into the later half. Claim only after both paired reviews pass. On claim, reconstruct the exact landed connector canvas/transform and 05→06 passage from archived evidence/current main, then perform the remaining full-scene art/seam/South-Reach convergence. No manual ChatGPT refresh is required unless those reviewed corrections expose a new unresolved art/design choice.
- Evidence: `custodian/game/world/awakening/awakening_layout.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_first_return.gd`; `AWAKENING_04_05_CONNECTOR_VISUAL_CLOSEOUT_CLAUDE_SUMMARY.md`; `custodian/tools/assets/compose_awakening_connector_full_plate.py`; `reports/awakening_gate_collision/QA.md`; `reports/awakening_visual_walkthrough/QA.md`; `custodian/game/world/hub/road_of_witnesses_prototype.gd`; `custodian/tools/validation/road_of_witnesses_production_smoke.gd`; live Asset V2 family contracts/catalog; `custodian/content/metadata/assets/required_assets.registry.json`.
- Task-specific authority: `design/04_architecture/AWAKENING_FIRST_RETURN.md`; `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`; `custodian/game/world/awakening/awakening_layout.gd`; live Asset Pipeline V2 family contracts; `design/05_levels/TWIN_SOLARIA.md` only for the next-stage boundary that Awakening must not bypass.
- Work surface: Primary runtime owner is `custodian/game/world/awakening/awakening_first_return.gd` plus its scene and Layout-backed tests. Presentation inputs are the existing Awakening zone plates, 04→05 connector, and Road prototype/module families. Expected docs/tests: Awakening focused smokes, validation manifest/recipes, CURRENT_STATE, FILE_INDEX, and only the minimum design notes needed to record live truth. Do not modify Twin Solaria runtime in this slice.
- Change: Add a machine-checkable art-registration/seam contract for the complete Awakening, code-first seam probes/metrics for the late-level joins, and bounded presentation corrections only when structured evidence proves an objective seam/overlap error. Before creating new detail art or scene bindings, inspect the stranded `awakening-detail-assets-batch-01` checkpoint against current Asset V2/catalog truth; reuse only current-valid ingested assets/provenance. Do not merge the stale branch or recreate a generic placement system solely to consume them. Renderer output is secondary evidence: use targeted seam ROIs only when pixel continuity cannot be established from registration/alpha/coverage metrics, and never require repeated full-screen model inspection. Add one production-named completion signal/API for South Reach that preserves legacy compatibility. Update the asset-consumption ledger to distinguish baked-only fixture states, specialized live props, unpublished registered families, and later-Hub assets. Correct stale docs that still describe the rejected connector dimensions or otherwise contradict live placement.
- Preserve: `awakening_layout.gd` as sole spatial authority; mandatory route/collision coordinates unless focused evidence proves the authority wrong; the reviewed direct-connector Asset V2 identity/registration established by `awakening-room-connectors-polish`; the reviewed one-passage lower→upper continuity established by `awakening-lower-upper-spine-connection`; Gate pylon blockers and central Gate traversability; Road-owned collision; opening does not prewarm a Contract; no Field Terminal/Forum/Continuity Port added to Awakening; no direct Awakening→Twin jump. Do not restore retired 04→05 room-overlap strips, whole-room partial-alpha fading, or the old 32 px feather / 128 px visible crossfade contract unless the landed dependency explicitly preserved a bounded compatibility path with evidence.
- Non-goals: No Hub runtime scene; no world-context transition implementation; no Twin Solaria gameplay changes; no procgen handoff; no Contract prewarm; no new generic fixture art; no speculative rescaling of valid plates; no extraction of a fake 04→05 foreground from flattened RGB; no Gate central-body collision enlargement; no redesign of the ten-section Layout; no procgen performance/pause work.
- Acceptance: Every active Awakening environment family and the live 04→05 presentation prove their exact reviewed direct-source canvas, registration, alpha/visibility, z-order, and route-coverage contracts from current Asset V2/runtime truth; no retired overlap-strip/crop/reconstruction or whole-room dissolve path is silently reintroduced. The reviewed 05→06 `128×96` semantic passage remains one continuous real-Operator route into the later half. Mandatory joins 01→02, 02→03, 03→04, 04→05, 05→06, 06→07, 07→08, and 08→10 plus optional 08↔09 have machine-checkable structural coverage and only the minimum targeted renderer evidence still needed after metrics. Road South Reach still aligns to the authored Approach handoff; Gate collision remains truthful; South Reach completion fails closed until console acknowledgement + P-9 recovery, emits one production-named completion event once, preserves any required legacy listener during migration, and never starts Contract generation. Docs and asset-gap state match live runtime, and any human visual question is reduced to one compact external review handoff rather than a claim gate.
- Validation: Add focused registration/seam coverage first as a new dedicated smoke this slice creates under `custodian/tools/validation/` (named for the contract it proves, e.g. an art-registration smoke), and register changed-file ownership. It should prove plate centers/canvases, overlap envelopes, underlay/foreground registration, alpha/visibility state, effective presentation order, and route/Operator coverage at representative join samples without renderer inspection. Keep `awakening_first_return_smoke.gd`, `awakening_first_return_geometry_smoke.gd`, `awakening_first_return_progression_smoke.gd`, `road_of_witnesses_production_smoke.gd`, and Asset V2 requirement/status checks green. Use the reusable visual-validation/Moment Forge presentation probes when available to cover 05→06, 06→07, 07→08, 08→10 and optional 08↔09 in `capture-mode none`; only after those checks are green run one sparse evidence pass that computes seam metrics and emits a compact five-ROI contact sheet if rendered-pixel proof is still required. Do not run five independent full-screen visual inspections. Run focused checks before `run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: Actual Awakening→Hub transition; Hub runtime host; Ashen Forum/Field Terminal/Continuity Port; Hub→Twin Solaria route; missing registered Awakening P1 art; authored Gate central-passage composition; Twin forensic/route/acquisition slices; procgen pause/optimization.


## Claim-Time Dependency Refresh

This packet is `ready/auto`; its dependencies control eligibility. After both `review-awakening-room-connectors-polish` and `review-awakening-lower-upper-spine-connection` archive complete, the claiming execution agent must read both implementation/review pairs, re-read the current Awakening scene/controller/Layout/Asset V2 contracts, and update stale packet/docs facts as part of this workstream before mutation. Private helper names and exact post-polish dimensions are derived from live main, not from the historical pre-polish values above. Stop for the user only if the landed evidence exposes a real art/design choice that existing authority does not answer.
Zone04/05 foreground completeness, the reviewed direct connector's actual source-preserving canvas/transform, 05→06 passage continuity, visibility/z-order behavior, and any changed Zone04 set-piece blockers/P-9 placement. Do not simply delete the old feather/fade clauses without rechecking the rest of this packet's full-scene acceptance.

## Registration Contract

Do not eyeball-resize the nine production room plates. Their current registration pattern is intentional:

| Zone | Layout envelope | Production canvas | Center | Required art rect |
|---|---:|---:|---:|---|
| 01 Crèche | 832×576 | 960×704 | (0,-32) | envelope + 64 px each side |
| 02 Ambulatory | 1024×832 | 1152×960 | (0,-864) | envelope + 64 px each side |
| 03 Attestation | 704×800 | 832×928 | (0,-1744) | envelope + 64 px each side |
| 04 Locker Reliquary | 576×576 | 704×704 | (704,-1984) | envelope + 64 px each side |
| 05 Dust Lung | 1088×1088 | 1216×1216 | (0,-3200) | envelope + 64 px each side |
| 06 Undergate | 1408×1088 | 1536×1216 | (0,-4320) | envelope + 64 px each side |
| 07 Gate of Dust | 1408×640 | 1536×768 | (0,-5184) | envelope + 64 px each side |
| 08 Custodian Approach | 896×736 | 1024×864 | (0,-5872) | envelope + 64 px each side |
| 09 Late Service | 576×640 | 704×768 | (-736,-5728) | envelope + 64 px each side |

The underlay and foreground for a zone must share exact canvas size, center, scale 1, and registration.

### 04→05 direct connector exception

Do **not** hard-code the historical 1024×576 canvas or `(352,-2464)` center here. The preceding P0 connector correction now owns the source-preserving canvas and measured world transform. On claim, copy those exact reviewed values from the archived implementation/review evidence and current Asset V2 family/runtime state.

Required invariant:

```text
asset family: awakening_reliquary_dust_lung_connector
state: full_plate_underlay
source authority: exact approved connector.png receipt
runtime canvas: reviewed measured output
world transform: reviewed measured registration
silhouette: complete; no nontransparent crop
legacy room-strip feather/reconstruction: not production authority
```

Do not restore either the rejected 832×384 plate or the legacy crop-derived 1024×576 registration merely because older docs/tests mention them.

### Approach → Road seam

The Road is not another Awakening room plate.

Current transform:

```text
Road world offset: (6,-6626)
Road local south entry: (-6,482)
Road world south entry: (0,-6144)
south gate gap: 192 px

south_reach_civic_axis
  local center: (0,34)
  world center: (6,-6592)
  canvas: 768×896
  world bounds: x[-378,390], y[-7040,-6144]

Custodian Approach production plate
  center: (0,-5872)
  canvas: 1024×864
  visual bounds: x[-512,512], y[-6304,-5440]
```

The two visual canvases therefore overlap from y=-6304 through y=-6144. Treat that 160 px as a seam-review region, not as permission to move either gameplay authority.

If capture proves visible duplication/hard-edge conflict, correct presentation at the seam with the smallest deterministic mask/alpha/overlap treatment. Do not move the Road offset, Approach envelope, Road collision, or south-entry anchor merely to hide a visual join.

## Gate of Dust

Preserve current validated pylon correction:

```text
west pylon art canvas: 256×512
east pylon art canvas: 256×512
current blocker: 240×496 each
central required route: remains open
```

The central `body_idle_sealed` 768×512 and `sealed_aperture` 512×512 presentation still visually covers part of that route.

This is an **authored composition/art-state issue**. Do not expand collision across it.

If a technically unambiguous alpha/z-order correction using existing source can make the required route readable without altering intended sealed-state composition, it may be proposed in review evidence, but do not invent a new Gate state in this packet. A new/passable state requires a later Asset V2 art decision.

## South Reach Handoff API

The current progression semantics are correct:

```text
console acknowledged
AND
P-9 recovered
AND
Operator reaches South Reach completion trigger
→ Awakening complete
```

Replace blockout-only naming as production authority without breaking compatibility.

Preferred contract:

```gdscript
signal awakening_completed(snapshot: Dictionary)
```

or a cleaner live-project equivalent.

Snapshot should be data only and include enough for the next world lifecycle owner to validate the handoff, e.g. completion flag, console acknowledgment, P-9 recovery, final zone identity, and Operator position. Do not include Node references.

If `blockout_completed` has live consumers/tests, retain it temporarily as a deprecated compatibility emission from the same one-shot authority. There must still be exactly one completion decision.

Do not change scenes in this slice.

## Asset Consumption Ledger

Reconcile against the live generated catalog and family contracts, not old prose.

Known current classes to preserve unless main has advanced when claimed:

- **specialized live:** Crèche recovery alcove; P-9 Designation Locker; Dust Lung lift; required Gate of Dust component composition.
- **BAKED_ONLY:** all seven published `awakening_creche_fixtures`; five published Ambulatory fixture states. Do not double-render them.
- **partial:** `awakening_ambulatory_fixtures`, missing required `service_basin_b`.
- **registered / currently unpublished:** Attestation fixtures, Reliquary fixtures, Dust Lung structures, Undergate machinery, Approach fixtures, Late Service fixtures, Late Service relay lamp, authority inlay, ruin decals, and required ambient FX.
- **later Hub, not Awakening-scene debt:** Field Terminal production prop/art, Field Terminal chamber dressing, Continuity Port, and first-Contract presentation.

Do not publish missing generic art as part of this packet.

If any state has landed on current main by execution time, update the ledger to reality rather than preserving this snapshot as dogma.

## Documentation Drift To Repair

At minimum:

1. Reconcile every active doc that still treats either the rejected 832×384 plate or the legacy crop-derived 1024×576/`(352,-2464)` transform as current authority. Replace those claims with the reviewed direct-source connector canvas/transform and explicitly note that nontransparent source cropping/room-strip feather reconstruction are retired.
2. Remove/update any statement that the five Road modular presentation families still require native-size art. All five environment families are registered, ingested, and used by `RoadOfWitnessesPrototype`; the north processional continuation remains deferred.
3. Reconcile old “blockout complete” language with the production completion seam without implying the Hub transition exists.
4. Treat `custodian/docs/ai_context/task_packets/AWAKENING_SCENE_CORRECTNESS_HARDENING.md` as stale historical planning if it still asks for already-live A1–A5 work. Do not rerun completed hardening. Update/index/supersede it only according to current packet-lifecycle rules; do not silently leave two active authorities for the same work.
5. `custodian/asset_drop/inbox/awakening_ingest_manifest.json` currently records `awakening_undergate_environment` as 896×1216 even though the live V2 family contract and production scene use 1536×1216. Determine whether this manifest is an active/generated intake index or preserved historical batch record. If active/generated, regenerate it from current catalog/family truth; if historical, relabel/archive it so it cannot masquerade as current authority. Do not change the live 1536×1216 family/scene to match the stale manifest.

## Visual Evidence + Human Approval Gate

Structured proof remains first. The coding agent must generate the renderer evidence but must **not visually adjudicate it**.

For the five late joins, preserve this review order:

```text
01  05→06 Dust Lung / Undergate
02  06→07 Undergate / Gate of Dust
03  07→08 Gate of Dust / Custodian Approach
04  08→10 Custodian Approach / Road South Reach
05  08↔09 Approach / Late Service optional branch
```

Use this order:

1. Registration smoke proves exact plate/canvas/center and expected overlap geometry.
2. Runtime/presentation probes prove visibility, alpha, draw order, and that an Operator/path sample is not incorrectly covered.
3. Reusable seam metrics evaluate the rendered join ROIs for hard-edge discontinuity, transparent walkable holes, doubled threshold/rail/stair regions, and unexpected opaque coverage.
4. Generate one deterministic PNG per required seam ROI, plus an optional contact sheet for archival convenience.
5. **Do not use coding-agent vision/model judgment to accept or reject those PNGs.**
6. When all required images are ready, print their absolute paths and announce:
   `AWAKENING VISUAL CAPTURES READY FOR HUMAN REVIEW`.
7. Create an ephemeral local launcher outside the repository, preferably:
   `/tmp/custodian_awakening_visual_review.sh`.
8. The coding agent must then **run that launcher itself** and wait for the human review sequence to finish before continuing final closeout.

### Required launcher behavior

The launcher must:

- verify `kitty` and `xdg-open` exist;
- verify every expected capture exists before starting;
- use absolute, safely shell-quoted image paths;
- preserve the exact order above;
- print `[N/TOTAL] <absolute path>` before each image;
- launch one dedicated kitty process in the foreground per image;
- inside that kitty, call `xdg-open` on that image and then remain alive;
- treat closing/terminating that kitty process as **approve this image and advance**;
- start the next image only after the prior kitty process exits;
- after the final approved image, print:
  `HUMAN VISUAL REVIEW SEQUENCE COMPLETE`.

Conceptual implementation:

```bash
#!/usr/bin/env bash
set -euo pipefail

images=(
  "/absolute/path/01_dust_lung_undergate.png"
  "/absolute/path/02_undergate_gate.png"
  "/absolute/path/03_gate_approach.png"
  "/absolute/path/04_approach_road.png"
  "/absolute/path/05_approach_late_service.png"
)

command -v kitty >/dev/null
command -v xdg-open >/dev/null

for i in "${!images[@]}"; do
  image="${images[$i]}"
  test -f "$image"
  n=$((i + 1))
  printf '[%d/%d] %s\n' "$n" "${#images[@]}" "$image"

  kitty \
    --title "CUSTODIAN Awakening review $n/${#images[@]} — close = approve/next" \
    sh -lc '
      image="$1"
      xdg-open "$image"
      printf "\nReviewing:\n%s\n\n" "$image"
      printf "%s\n" "Close/terminate THIS kitty window when approved."
      printf "%s\n" "To reject/stop, interrupt the parent review command instead of advancing."
      while :; do sleep 3600; done
    ' sh "$image"
done

printf '%s\n' 'HUMAN VISUAL REVIEW SEQUENCE COMPLETE'
```

The exact shell may differ if required by the local kitty configuration, but the control contract may not.

### Human approval semantics

For this task:

```text
close/terminate current review kitty
    = approve current capture
    = advance to next capture
```

If a capture is not approved, the user will interrupt/terminate the **parent review sequence** rather than advance through the remaining images, then provide correction feedback.

After an interrupted/rejected review:

- remain on this workstream;
- make only the requested correction;
- regenerate only affected evidence plus any dependent captures;
- rerun structural/probe/metric checks;
- relaunch the human sequence from the first affected capture or, if simpler and deterministic, from capture 01.

Do not infer approval from file existence, green metrics, or successful `xdg-open`.

### Objective pass criteria presented to the human

The images should make these visual questions easy to inspect:

- no straight rectangular crop discontinuity;
- no doubled architectural threshold/stair/rail;
- no transparent hole exposing void where walkable floor exists;
- no opaque foreground masking the Operator where the required route says the Operator can stand;
- no presentation discontinuity that warrants an art correction.

Machine checks still own what can be proven structurally. Human inspection is the final visual acceptance gate, not a substitute for the structural validation.

Paired review must reuse the committed registration report, seam metrics, capture manifest, and the recorded completion of this human gate. It must not perform a second subjective model-vision review.

If objective seam correction is needed, preserve editable/generation source under the existing family source-work path and route normalized replacements through the existing Asset Pipeline V2 family/inbox. Do not hand-edit runtime output.

## Relationship To Twin Solaria

This packet deliberately stops at South Reach handoff readiness.

The production route remains:

```text
Awakening
→ Road of Witnesses continuation / Hub runtime
→ Ashen Forum
→ Hub destinations, including Twin Solaria
→ Field Terminal / ordinary Continuity Port
→ first Contract world
```

Twin Solaria is `hub_twin_solaria` with `Spawn_CrownCauseway`. It is not a procgen `world_ingress` and must not be wired directly from Awakening.

The already-queued Twin forensic/route-review/acquisition packets remain separate and may proceed independently under their own lock/dependencies.

## Handoff

- Next action: after this packet lands and its review passes, implement the actual Awakening→Hub world-context transition and persistent Hub runtime host. That slice should depend on this workstream and on the App/Boot spine where required.
- Best starting files: Awakening controller/layout/scene and focused smokes; Road prototype; world lifecycle architecture; `hub_twin_solaria` level definition for the later destination contract.
- Blockers or open questions: Gate central sealed-body route readability remains a human/art composition decision if existing presentation cannot be corrected without changing the intended state. Missing P1 generic fixture/inlay/decal/ambient art is not a blocker for handoff readiness.