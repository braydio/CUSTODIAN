# AI Artwork Generation and Review Protocol V1

**Status:** Active source-art production workflow guidance (2026-11-01).  
**Applies to:** New image-generator-authored, non-Operator CUSTODIAN environment plates, modular seams, support silhouettes, props, decals and ambient sprite strips.  
**Does not supersede:** `custodian.asset_family.v2` / Asset Pipeline V2; specific design/level layout authorities; specialized Operator pixel-art/animation tooling; the existing reviewed handoff installer; active workstream dispatch, review gates or human approval.  
**Current production example:** [Hub Sepulcher, First-Set Hub and Awakening Artwork V1](HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.md) and its [84-entry JSON](HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.json).

## Candidate-only automated art lane (2026-11-03; controlling dispatch rules)

**Codex's only artwork instructions:** `GENERATE_ASSET`, `REVIEW_ASSET`, `UPLOAD_ASSET_TO_DROPBOX`, each with exact current manifest `set_id` and `asset_id`(s). No other Codex command is valid inside this browser artwork session. The ChatGPT coordination session owns design/manifest reconciliation separately. Never confuse an AI candidate review with user art approval.

A source with independent actual image bytes, a **PASS_CANDIDATE** visual/objective screen and a verified `/CUSTODIAN/candidate_staging/hub-sepulcher-awakening-art-v1` upload (file ID, revision, path, checksum) completes **candidate production for that state**, even if human_image_approval is pending. It does not authorize source_work/inbox, asset family registration, Asset V2, gameplay, or source approval. A failing candidate must regenerate the SAME manifest asset, not advance. A true geometry/neighbor/owner dependency is **DEFERRED_REQUIRED** with exact set/asset, blocker, owner and resolution; only independent later candidates may proceed; deferred required states remain incomplete and must be revisited. All 72 required states must be staged before candidate-complete; 12 optional states require separate explicit authorization.

CAL-01 candidate-only staging: SHA-256 `5bf414069ea9c70139fa0ffe5ceee3378e2c226f22fb76e8a55e46a7e14773d2`, Dropbox `id:8NXqdXuW6GUAAAAAAAAHEw`, revision `65f57a8e1c486915cdd61`; AI-screened PASS_CANDIDATE, **NOT human source approved**. CAL-02 `hub_first_set_sepulcher_gardens_environment/structural_presentation` has an obsolete 1152×1408 source/prompt and remains DEFERRED_REQUIRED pending a valid modular structure/footprint. Next independently candidate-eligible set: **CAL-03**, `hub_sepulcher_grave_evidence_art/memorial_slab`. This does not mean CAL-02 is skipped or approved. Only actual complete candidate receipts can advance the staging cursor. User production approvals are separately tracked.

For transparent assets report visually apparent transparency, any matte/checkerboard, and uncertainty, then verify true alpha from actual bytes. For opaque CAL-01: transparency NOT APPLICABLE. Existing paving reference sources remain unapproved; no image-conditioning claim without actual input evidence.

## Decision in one sentence (source-production baseline)

**Queue 5–10 manifest states for organized planning, generate high-consequence states one independently reviewed image at a time, and after visual calibration use only small, compatible generation groups (usually 2–3), while approving and recording each actual asset individually.** Never generate ten different production assets as one combined atlas and treat its crops as ten approved images.

Batching the *queue*, batching *tool requests*, batching *individual image variants*, and batching the *eventual Dropbox package* are different actions. A ten-state task queue never implies ten images requested in one generation or one shared approval decision. An image-generator service may or may not support multiple independent outputs; if it does not, make sequential calls. If it does, each response still needs independently addressable raw image bytes, one family/state identity and its own review receipt.

## Which generation batch size to use

| Asset class | Initial default | Post-style-lock upper bound | Why |
|---|---:|---:|---|
| World/Hub district underlays and large zone compositions | 1 | 1 | Exact camera, composition, real passages and cross-district registration |
| Connectors, edge transitions, registration-dependent overlays | 1 | 1 | Must fit actual accepted neighbor pixels; never independently invent a seam |
| Memorial slabs, unique hero markers and high-salience fixtures | 1 | 2 | Important silhouette, identity and legibility |
| Small independently positioned world props / garden dressing | 1 | 2–3 | Shared material reference supports efficient, bounded consistency |
| Low-salience repeatable decals, roots and minor vegetation | 1 | 3–4 | Lower risk if each remains a separate addressable source image |
| Animation clips or strips | 1 full action/state | 1 full action/state | Frame count, anchor and motion continuity demand concentrated correction |

These are **operating defaults, not an override of an active source manifest or packet**. If two props depend on different style anchors, camera models, transparency requirements, placement mechanics or source contracts, do not group them. If one is especially complex or recently rejected, fall back to one. *Never* reduce the number of required human approvals when generating several candidate sources together.

**Variants versus states:** You may compare two distinct candidate variants **of the same named state** when useful. Preserve both source identities as candidates until a human selects one. Do not count variants as fulfilled separate manifest states. A contact sheet is review presentation only, never a normalized source master. Do not slice a newly generated ten-asset collage into individually approved Asset V2 sources.

## Floor-first source generation (2026-11-01)

For authored environments, FIRST lock the live playable footprint, collision, connector and interaction coordinates. Generate a strict overhead orthographic **walkable ground-only underlay** without walls, stairs, raised terraces or depth props. THEN generate separate independently registered **true RGBA architectural presentation**, **scenic depth**, and only when needed **foreground occlusion**. Keep one 1:1 world/pixel origin, scale and orientation; no per-layer camera fitting. Each independently consumed layer needs its own manifest state, source/inbox path, prompt and human source approval. Artwork NEVER grants collision authority. If solids would visibly obstruct currently walkable cells, the architecture layer is BLOCKED until an approved spatial/solid footprint update authorizes it.

The live Sepulcher Gardens instead use a 3072×2688 authoring envelope and authoritative irregular 96×84 walkability mask. `CAL-01` now produces only ONE **512×512 opaque repeatable floor-material** image; a future approved renderer repeats it at 512px native scale and clips to the existing mask, with no art-owned collision, water or routes. Its previous 1152×1408 mixed architectural source remains rejected. **The separate modular-paving imagery is not an approved style anchor:** `SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.json` records `paving_base.source_approved=false`; the original 1254×1254 RGB candidate SHA-256 `62341f6850cd526b5b03187d9c9035318453c2b7cf2d6e213f19f1597af967bf` failed 3×3 repetition. No authoritative V3 human-approval SHA/receipt is verified. Existing paving is unapproved reference material only, and no image-conditioning claim is justified without evidence of the exact reference bytes supplied. The required `CAL-02` `hub_first_set_sepulcher_gardens_environment/structural_presentation` retains its historical 1152×1408 prompt only for provenance and is **BLOCKED** until a new modular architectural/solid-footprint source contract is approved. Other first-set Hub regions require a floor/solid audit before their first full-scene underlay. Dust Lung V2 already separates traversal, hard void and scenic-depth doctrine, but its existing eight-state source prompts still mix art passes: reconcile in separate DL0 authority, not by silently editing that manifest here.

## Named command: "generate the next set"

**This is an executable shorthand, not a request to discuss the next images.** When the user says **"generate the next set"**, **"next art set"**, or **"next image set"** within CUSTODIAN without specifying another named art program, use the active default `hub-sepulcher-awakening-art-v1` and its JSON at `design/04_architecture/HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.json`. A user may instead explicitly name a different program; do not silently apply this program's asset queue to it.

The JSON has `generation_sets_contract` plus a complete ordered `generation_sets` list. **Each set specifies its exact image IDs and cardinality.** It already excludes the six CAL-A states when they recur in downstream stage lists. The `checkpoint.next_generation_set_id` is a convenience hint, not the sole authority.

### Deterministic dispatch steps

1. Read current GitHub `main`, this protocol, the JSON, and any more recent genuine source/approval receipts. Reconcile actual saved source hashes, verified Dropbox revisions, current active workstream claims and Asset V2 status. Never infer absence solely from an empty original JSON checkpoint.
2. For candidate-only staging, select the earliest required set without real PASS_CANDIDATE staging receipts. If a true geometry/neighbor/owner blocker exists, record it DEFERRED_REQUIRED with exact asset ID, preserve it as incomplete, and proceed only to a later independent eligible state. Human source approval is tracked separately. Review existing candidate bytes before creating duplicates.
3. Enforce all HARD geometry/scene/neighbor requirements for candidates, not human production source approval. Six CAL-A sets remain one distinct image each. Preserve existing AP1–AP4 and Dust Lung DL0 owners; defer required states whose actual candidate source contract is unsafe.
4. For each eligible missing candidate **invoke the image generator immediately**, using that state entry's **complete** `image_generation_prompt` and format/anchor/alpha/frame constraints. Use approved reference imagery if accessible, but never claim image conditioning if the reference could not actually be supplied. Multi-state sets require **two independent outputs**, ideally separate per-state tool calls: `n=2` of a single prompt is *not* two different state images. Never substitute a labeled 2-up or ten-up atlas.
5. REVIEW_ASSET must inspect the actual independent PNG and record visual/artistic screening distinctly from byte-level format, alpha, frame and geometry checks. A candidate failure returns REGENERATE of the SAME asset; PASS_CANDIDATE is not human approval.
6. UPLOAD_ASSET_TO_DROPBOX uploads only a PASS_CANDIDATE to the authorized candidate lane, verifies real file ID/revision/path/checksum, and records it. Once every state in a set has a verified receipt, advance the candidate cursor even if human production approval is pending. Do not claim all core candidates complete while any required set is deferred. Optional states excluded unless explicitly authorized.

### Initial deterministic answer

Current candidate resume: **CAL-01** has verified PASS_CANDIDATE candidate-staging receipt, **CAL-02** is DEFERRED_REQUIRED for obsolete structure footprint/source; **CAL-03** with exactly `hub_sepulcher_grave_evidence_art/memorial_slab` is next independent candidate production set. Human production source approval cursor remains at CAL-01.

**Do not conflate**: a *planning queue* may hold 5–10 forthcoming states; a *generation set* is the fixed next 1- or 2-image execution group; a *handoff batch* can consolidate multiple already-approved sources. These separate units eliminate ambiguity in ordinary conversational commands.

## First six: mandatory one-image calibration gate for this program

The Hub/Sepulcher/Awakening CAL-A queue requires one independent image per set. During candidate automation, stage each screened candidate before advancing; human source approval is still required separately for production:

1. `hub_first_set_sepulcher_gardens_environment/underlay` — one 512×512 opaque repeatable walkable-ground-only candidate, clipped to the authored irregular mask at runtime, no walls.
2. `hub_first_set_sepulcher_gardens_environment/structural_presentation` — separately aligned RGBA architecture; blocked pending structural/collision plan.
3. `hub_sepulcher_grave_evidence_art/memorial_slab` — lock the event's hero object and the physical scale relative to approved Gardens.
4. `awakening_creche_perimeter_support/structural_support` — verify industrial interior family, seamless outer edges and existing Crèche plate.
5. `awakening_gate_of_dust_perimeter_support/distant_structures` — verify ruined exterior silhouette, the real east/west stair mouths and true alpha.
6. `awakening_road_south_reach_perimeter_support/edge_transition` — verify the South Reach existing five-module Road handoff, nonplayable edge and true alpha.

The six CAL-A assets are already members of the 72 required core states, **not five additional images**. After the six approvals, promote a **reference lock** for each relevant architectural language (Sepulcher burial, established Hub civic, Awakening institutional interiors, Awakening exteriors). A single Garden image must not overrule a distinct Crèche or Gate plate. For each source request, show/attach the approved neighboring source/master where supported, plus exact prompt and occupancy/clearance notes. If the reference cannot be supplied to the generator, record that limitation and increase review scrutiny; do not claim it was image-conditioned.

## Reusable production cycle

### 0. Resume truth from current GitHub, not chat assumptions

- Start with `AGENTS.md`, `custodian/AGENTS.md`, the applicable design authority, current `main`, `custodian/docs/ai_context/CURRENT_STATE.md` and `custodian/docs/ai_context/FILE_INDEX.md`. For this program read both V1 manifest files and this protocol before producing new art. For CAL-01 also consult `SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.json`; unapproved paving source availability is not artistic approval.
- Reconcile the manifest's planned `checkpoint` against any actual approved source hashes, connected Dropbox file IDs/revisions, Asset V2 catalog, active branch/packet claims and current consumer scene. A stale no-art checkpoint is not evidence that art has never been generated elsewhere.
- Confirm the exact family/state, resolution, frame layout, orientation, runtime use, alpha/opacity and placement footprint from authoritative contracts. For proposed families, do not claim registration; do not silently change a requested size or consumer.
- Reuse already-approved sources when present. Do not regenerate a completed state or overwrite an existing immutable master because the chat restarted. CAL-01 has **no verified approved V3 style anchor**. Treat earlier paving candidates as unapproved references and record actual image-input bytes before claiming image conditioning.

### 1. Build a queue, then generate with reference control

- Choose a **planning queue of 5–10** compatible unfulfilled manifest states, preserving documented phase order and original active-workstream ownership.
- For a high-consequence state, produce **one independent image**. For approved low-risk compatible items, choose at most the table's group limit, requesting individually identifiable assets, **not a collage**.
- Keep the full manifest-specific prompt, exact target size, frame information and constraints for each state. Reference real accepted adjacent scene art; never let prompt shorthand replace state identity or architectural geometry.
- Generate independent images at the best supported source resolution and aspect ratio; when exact pixel dimensions or transparency cannot be guaranteed, treat the generator result as a raw *candidate*, not a normalized Asset V2 output. Do not stretch or fake transparency on a bad candidate.
- Independently version every raw candidate and its origin/prompt information. A possible variant or rejected attempt is not the approved final.

### 2. Apply cheap technical checks first

Before subjective visual review, inspect (ideally via deterministic tooling):

- File existence and unique family/state identity, decodeability, pixel size and aspect; source versus required normalized canvas; color mode/real alpha (not an illustrated checkerboard or dark-color key).
- For animation, declared count/layout/FPS, uniform frame cells, stable foot/feature anchor, no frame bleed, no unintended cropping or double imagery.
- For seamless repeated tiles, all four sides and corners in an actual tiling preview; no obvious discontinuities or lighting vignettes.
- For connectors, actual neighbor-pixel contact alignment and authored open path; for scene plates, exact world-to-pixel registration, footprint, route width, obstruction/occlusion and camera visibility; for scenery, no painted new walkable path.
- For any transparency-requiring candidate, explicitly report apparent transparency, visible matte/checkerboard or uncertainty. Only byte-level RGBA/alpha checks establish true transparency; for CAL-01 opaque, alpha is NOT APPLICABLE. Candidate-only Dropbox staging may proceed after objective AI screening under the user-authorized `/CUSTODIAN/candidate_staging/hub-sepulcher-awakening-art-v1` lane, but is NOT human source approval or production handoff.
- For sources to be normalized, require aspect-preserving scale/crop/pad only when physically safe. Reject/regenerate when the true geometry would otherwise be altered. Keep the raw untouched, and calculate SHA-256 of source and accepted normalized candidates.

Technical failure is `needs-correction` *within the authoring queue*, not a fabricated handoff `RUNTIME_READY` status. Agents may automatically detect objective failures; they do not subjectively approve canon, composition or style.

### 3. Human art decision per candidate

Present the **single full-resolution source or smallest useful crop/tiling proof** with the accepted reference, intended gameplay placement and exact review question. State objective findings distinctly from judgment calls.

- **Approve:** human explicitly approves the actual image for source/intake; lock chosen candidate hash, required dimensions and reviewed reference identity.
- **Correct:** document concrete adjustments to the same state and regenerate or edit it, then inspect again; do not silently approve because an attempt meets PNG constraints.
- **Reject:** record the reason and start a new version of the same state. Preserve rejected provenance without importing it as production.

Do not combine multiple generated images into one blanket approval, even if they were generated in one request. **Style anchors are reviewed imagery, never just a verbal claim of style lock.**

### 4. Package and publish only accepted sources

After per-image approval, stage reviewed raw `custodian/asset_drop/source_work/...` and corresponding accepted normalized `custodian/asset_drop/inbox/...` from the state manifest. Preserve both SHA-256 hashes and real dimensions.

For a connected Dropbox `custodian.asset_handoff.v1` use the real current packaging contract and installer:

- Source and normalized assets, `README.md`, `MANIFEST_GAME32.md`, `MANIFEST.json`, `CODEX_IMPLEMENTATION.md` and the byte-identical current `custodian/tools/assets/asset_handoff_installer.py` copied as `INSTALL_INTO_REPO.py`.
- The handoff status vocabulary is **only** `RUNTIME_READY`, `SOURCE_READY_NEEDS_TUNE` or `REJECT_REGENERATE` per the live manifest schema. A planning-list internal correction state is *not* one of these. Transport flags must match source review reality.
- A reviewed, approved batch may be **uploaded together** to Dropbox, with a receipt for every constituent asset: exact Dropbox path, file ID, revision and checksum. A single archive upload never replaces individual approvals. Never rely on an attachment or chat download as the sole transport.
- Treat `CUSTODIAN/visual_review/` as the **outbound transient render-evidence lane** managed by `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`, distinct from approved **inbound implementation sources**. Follow the active `custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md` where applicable.

### 5. Source delivery is not runtime approval

A successful upload, ZIP installer or source hash is not a scene binding. Under the existing workstream and Asset Pipeline V2, check registration/manifest demand, run `plan`, `status` and `doctor` before reviewed `ingest`, then verify final Asset V2 catalog, scene consumer, deterministic gameplay behavior and independent/human visual closeout. Do not bypass `custodian/content/metadata/assets/required_assets.registry.json` or manually edit generated `REQUIRED_ASSETS.md`.

For this program: retain the **nine already registered** generic Awakening perimeter families, keep Zone 05's **Dust Lung V2** source set under separate DL0 authority, preserve the five authored Road module pairs, protect the Gate's actual stair exits and avoid racing the Sepulcher grave-resolution review.

## After every individual decision: restart-safe evidence

Update the authoritative per-state ledger or an immutable linked receipt when there is real new information. The document may be updated in a bounded GitHub commit through the normal repository workflow. Minimum persisted evidence:

| Field | Required evidence |
|---|---|
| Identity | Family/state ID, source prompt/version and chosen candidate revision |
| Generation | Source reference/art-style anchor IDs, generator limitations and candidate content identity |
| Validation | Actual original/normalized dimensions, alpha/frame/seam/geometry outcome, failed checks and corrections |
| Human review | Explicit approve/correct/reject decision, decision date and exact source hash |
| Delivery | Source and inbox paths, SHA-256 hashes, Dropbox file IDs/revisions/verified paths, full bundle manifest |
| Integration | Asset V2 job, consumer binding/commit, validation proof, open independent-review questions |
| Resume | Next unfulfilled ordered state, current active stage, workstream ownership/claims and blocker |

No field may be backfilled with a guess. Always distinguish user approval of the 72-core-state *program* from acceptance of each generated image. The JSON manifest's initial empty receipt fields are not completed work.

## When uncertain, follow this decision tree

1. **Which image or what size/prompt?** Open `HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.json` (or the applicable newer program manifest); inspect family/state entry and source authority.
2. **How many images should be generated together?** Use the table and style-lock prerequisites in this document; choose 1 whenever dependency, architecture or provenance is uncertain.
3. **What reference or style?** Use the latest *human-approved* specific family reference and live adjacent art; if absent, stay at 1 and seek visual approval.
4. **Can it be uploaded?** For candidate staging require PASS_CANDIDATE and verified source identity, dimensions/hash and Dropbox receipt. For production source handoff require explicit human image approval and the full asset handoff contract.
5. **Can Codex ingest or bind it?** Check Asset Pipeline V2, active packet/dispatcher and scene authority; source approval alone does not authorize a runtime cutover.
6. **What already happened?** Read latest GitHub ledger plus actual Dropbox and pipeline records, not last chat's optimistic summary. If there is a conflict, record discrepancy and investigate it before proceeding.

**Next candidate-only action:** CAL-03 `hub_sepulcher_grave_evidence_art/memorial_slab` (one independent source), while CAL-02 remains deferred required. Keep 72 core states in scope, optional states excluded.
