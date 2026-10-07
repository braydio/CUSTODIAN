# DROPBOX UNSTAGED ASSET INTAKE SWEEP

- Packet schema: `custodian.task_packet.v2`
- Workstream: `asset-downloads-intake-sweep`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `asset-pipeline, awakening-art-registration`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Reviewed main: `c4c56d175d4e66528b450b6872d888d3ced7eab6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Branch: `agent/asset-downloads-intake-sweep`
- Goal: `Consume every currently actionable, unimplemented production asset handoff under /CUSTODIAN/implementation_inputs without treating the Dropbox folder itself as runtime authority, publish all valid supplied states through their existing Asset V2 families, preserve source provenance, and leave already-landed, partial, superseded, smoke-test, or design-ambiguous payloads with their existing owners.`
- Completion boundary: `Twenty-one supplied required Awakening states across five existing families are hash-verified, source-preserved, ingested through Asset V2, imported, and reflected in current status/catalog truth; any objectively contaminated PNG is corrected only by the bounded alpha-island rule below or fails closed; the Dropbox audit receipt truthfully classifies every current implementation_inputs entry; no duplicate Operator/Alpine work or speculative scene binding is introduced.`
- Current measured state: `Live main does not contain service_basin_b and has no runtime/body directories for awakening_attestation_fixtures, awakening_reliquary_fixtures, awakening_dust_lung_structures, or awakening_undergate_machinery. Dropbox currently contains three complete actionable Awakening ZIP handoffs totaling 21 required states. Operator North VFX and North/South body handoffs are already landed/reviewed; Alpine underlay final-six is landed; Alpine cliff payload is explicitly partial 4/26 and remains owned by procgen-alpine-cliff-presentation-v1; bidirectional smoke payloads are non-production.`
- Evidence: `Dropbox /CUSTODIAN/implementation_inputs audit; live main c4c56d175d4e66528b450b6872d888d3ced7eab6; existing Asset V2 family contracts; archived Operator/Alpine implementation summaries; current runtime directory absence for the four later Awakening fixture families.`
- Task-specific authority: `custodian/content/metadata/assets/families/awakening_ambulatory_fixtures.asset.json; awakening_attestation_fixtures.asset.json; awakening_reliquary_fixtures.asset.json; awakening_dust_lung_structures.asset.json; awakening_undergate_machinery.asset.json; design/04_architecture/AWAKENING_ASSET_MANIFEST.md; live custodian/tools/assets/asset.py CLI.`
- Work surface: `custodian/asset_drop/source_work/awakening/{awakening_ambulatory_fixtures,awakening_attestation_fixtures,awakening_reliquary_fixtures,awakening_dust_lung_structures,awakening_undergate_machinery}/; matching Asset V2 inbox/runtime/catalog/archive surfaces; current generated required-asset/status views; custodian/docs/ai_context/reports/assets/dropbox_unstaged_asset_intake.json.`
- Change: `Fetch and verify the three immutable Awakening handoffs below, preserve any prior canonical source before replacement, stage the supplied normalized PNGs unchanged except for the single bounded art-integrity correction rule, ingest each existing family with the live Asset V2 pipeline, then classify post-ingest scene consumption conservatively without inventing placement authority.`
- Preserve: `Existing family IDs/runtime naming; prior source history; current zone plates; BAKED_ONLY doctrine; specialized Crèche/P-9/Dust Lung lift/Gate systems; already-landed Operator and Alpine work; partial Alpine-cliff ownership; all Dropbox originals.`
- Non-goals: `No new Asset V2 family; no broad Dropbox cleanup; no deletion of remote files; no art redesign; no speculative placement database; no blind scene instancing; no duplicate execution of already-complete Operator/Alpine work; no consumption of the 4/26 Alpine cliff partial as if Gate B were complete.`
- Acceptance: `All three handoff ZIP hashes match; all supplied per-file hashes/dimensions/alpha match after extraction; Basin B publishes and awakening_ambulatory_fixtures reaches 6/6 required; Attestation reaches 7/7 required; Reliquary 3/3; Dust Lung structures 4/4; Undergate machinery 6/6; runtime/import/catalog/archive/receipt truth agree; current required-asset/status views no longer report these required states missing; fixture-consumption classifications are recorded; focused validation plus changed-file closeout pass.`
- Validation: `Verify package + manifest SHA-256 first; inspect PNG dimensions/mode/alpha and disconnected alpha components; run live plan/ingest/status/doctor per family; verify Godot imports; run Awakening focused asset/runtime smokes only where changed consumption requires them; regenerate current required-assets/status views through their tooling; run git diff --check and current changed-file validation.`
- Deferred: `Subjective reauthoring of older Awakening art against the new Dust Lung/Undergate family language; optional/recommended family states; actual fixture placement where Layout/scene authority does not already establish a truthful independent prop; procgen-alpine-cliff-presentation-v1 completion.`

## Immutable Dropbox Inputs

### A1 — Recovery Ambulatory Basin B

Remote:
`/CUSTODIAN/implementation_inputs/awakening_service_basin_b_handoff_v1.zip`

ZIP SHA-256:
`749cba1851e5bae8e5c68cbb0293b1b0b58ac447204b024fadc911b7665e189c`

Handoff:
`awakening-service-basin-b-handoff-v1`

Publishes:
- `awakening_ambulatory_fixtures/service_basin_b` — 128×128

Expected supplied hashes:
- source: `506f36de93096f32b37991fc7a4a5b27d0bb476c00afe7d47d3b608f010efc15`
- normalized: `b8e068ced61b6a7416b8b5be6ed2da881e5d7861e48faf7e4ea46a2e7cba6924`

Preserve the currently tracked pre-handoff `service_basin_b_source.png` before replacing it.

### A2 — Attestation + Reliquary Required Fixtures

Remote:
`/CUSTODIAN/implementation_inputs/awakening_next10_required_fixtures_handoff_v1.zip`

ZIP SHA-256:
`7192a7e2a2c291d5db11c70e5027fbeea9d5597e24d32a8033b428b6c3a9c4b3`

Handoff:
`awakening-next10-required-fixtures-handoff-v1`

Publishes all required states:
- `awakening_attestation_fixtures` — 7/7
  - `stele_intact` 96×160
  - `stele_scorched` 96×160
  - `stele_empty` 96×160
  - `stele_shattered` 96×160
  - `attestation_dais` 256×192
  - `torn_civic_banner` 128×256
  - `designation_sigil_fragment` 64×64
- `awakening_reliquary_fixtures` — 3/3
  - `central_dry_basin` 192×192
  - `welded_locker` 128×160
  - `recalled_not_verified_locker` 128×160

Use the package `MANIFEST.json` as exact source/inbox/hash authority.

#### Bounded art-integrity correction: attestation_dais

Visual preflight found a small disconnected edge fragment in the current supplied `attestation_dais` extraction.

Before staging that state:
1. compute connected components on the normalized PNG alpha mask;
2. identify the principal authored component by alpha-pixel area;
3. an automatic correction is allowed **only** when every satellite component is disconnected from the principal component, touches an outer image edge or sits wholly outside the principal component's expanded bounding region, and all satellites together are <1% of nontransparent alpha pixels;
4. remove only those satellite alpha components, preserving RGB/alpha bytes of the principal component exactly;
5. preserve the original supplied PNG as provenance and write a tiny correction receipt with before/after SHA-256 and component areas;
6. apply the same objective island removal to the canonical source master only if its alpha segmentation proves the same condition.

If those conditions do not hold, fail closed on `attestation_dais` and report the art blocker. Do not redraw or generatively repair it inside this workstream.

No other A2 state may be artistically modified by this packet.

### A3 — Dust Lung + Undergate Required Fixtures

Remote:
`/CUSTODIAN/implementation_inputs/awakening_dustlung_undergate_next10_handoff_v1.zip`

ZIP SHA-256:
`7bceeb24022613515ec65d05da5a6b6f2acee31c9920edb552c7a48936eda612`

Handoff:
`awakening-dustlung-undergate-next10-handoff-v1`

Publishes all required states:
- `awakening_dust_lung_structures` — 4/4
  - `broken_bridge_a` 256×160
  - `broken_bridge_b` 256×160
  - `giant_duct` 256×256
  - `lift_lever` 128×128
- `awakening_undergate_machinery` — 6/6
  - `transit_drum` 256×192
  - `route_coil` 192×192
  - `mechanism_plinth` 160×160
  - `blind_route_housing` 160×160
  - `register_shelving` 256×192
  - `register_route_map` 384×256

Use its `MANIFEST.json`, `CODEX_IMPLEMENTATION.md`, and per-file hashes directly. Do not recompress or reinterpret supplied normalized inputs unless live family validation proves a contract mismatch.

## Dropbox Audit Classification

The execution receipt must classify current `/CUSTODIAN/implementation_inputs` entries.

Known authoring-time dispositions:

- `awakening_service_basin_b_handoff_v1.zip` — **implement**
- `awakening_next10_required_fixtures_handoff_v1.zip` — **implement**, subject to the bounded dais integrity gate
- `awakening_dustlung_undergate_next10_handoff_v1.zip` — **implement**
- `custodian_operator_unarmed_fast_chain_ns_body_asset_handoff_v1.zip` — **already implemented/reviewed**, do not repeat
- `operator-unarmed-fast-chain-north-vfx/north-vfx-20261006-a1` — **already implemented/reviewed**, do not repeat
- `procgen-alpine-plateau-underlay-assets/alpine-underlay-final-six-v3` — **already implemented/reviewed**
- `procgen-alpine-plateau-underlay-assets/alpine-underlay-omnidirectional-v2` — **superseded by final-six-v3**
- `procgen-alpine-plateau-underlay-assets/alpine_underlay_last3_generations_review_bundle.zip` — **reference/donor review bundle**, not runtime intake
- `procgen-alpine-cliff-presentation-v1/alpine-cliff-presentation-v1-partial-first4-20261005-a1` — **owned by existing packet; partial 4/26 only; do not publish as Gate B**
- `bidirectional-dropbox-handoff/*smoke*` — **transport smoke only**, never production content

If Dropbox changed after this packet was authored, classify new entries by repository ownership and fail closed on anything without an existing authority.

## Asset V2 Execution

For each actionable handoff:

1. fetch/copy the immutable ZIP without mutating the Dropbox original;
2. verify ZIP SHA-256 and packaged manifest before extraction;
3. verify every source/inbox file against the package manifest;
4. preserve any currently tracked source target under a clearly named `pre_handoff_*` history folder before replacement;
5. copy source masters to the manifest's canonical source-work targets;
6. copy normalized PNGs to the manifest's canonical inbox targets;
7. discover the **current** CLI via:
   `python3 custodian/tools/assets/asset.py --help`
8. run the live equivalent of plan → ingest/replace → status → doctor for each family;
9. verify runtime PNG dimensions, RGBA/real alpha, imports, catalog and receipt;
10. consume/clear inbox according to the pipeline's normal archive behavior.

Do not hand-author runtime filenames when Asset V2 can publish them.

## Post-Ingest Fixture Consumption

Publishing an asset does not prove that it should become a new scene node.

For every newly published state, classify it using the existing Awakening vocabulary:

- `BAKED_ONLY`
- `INDEPENDENT_WORLD_PROP`
- `FOREGROUND_OCCLUDER`
- `INTERACTABLE`
- `STATEFUL_PROP`
- `NOT_READY`

Rules:
- inspect the current zone plate before binding anything;
- do not double-render architecture already baked into the underlay/foreground;
- only place an independent asset when current Layout/scene authority already provides a truthful location and role;
- do not invent markers, collision, interaction, or gameplay just to consume a newly available PNG;
- specialized existing systems remain authoritative.

Record classifications in:
`custodian/docs/ai_context/reports/assets/dropbox_unstaged_asset_intake.json`

If no newly published state is truthfully bindable, successful Asset V2 publication plus an honest `BAKED_ONLY`/`NOT_READY` classification satisfies this packet's runtime-wiring boundary.

## Documentation Drift

After ingest:
- regenerate current required-assets/status outputs through their owning tooling;
- `custodian/docs/reports/awakening_runtime_ingest_status.md` currently still says Basin B is missing and must be reconciled if that file remains active current-truth documentation;
- do not treat `custodian/asset_drop/inbox/awakening_ingest_manifest.json` or historical `next10_*` bundle manifests as current authority;
- preserve historical packet/summary evidence.

## Validation

Run focused checks first:
- package/hash/dimension/alpha verification;
- Asset V2 plan/ingest/status/doctor for all five families;
- Godot import/parse for newly published runtime PNGs;
- any focused Awakening smoke required by actual new scene bindings;
- generated required-assets/status consistency.

Then:
- `git diff --check`
- current `run_validation.py --changed --json`

Do not start with a full-project sweep.

## Completion Report

Report:
- exact Dropbox handoffs consumed and ZIP hashes;
- Asset V2 job IDs per family;
- final runtime paths + SHA-256 for all 21 states;
- final required completeness for all five families;
- any `attestation_dais` correction receipt or blocker;
- post-ingest consumption classifications and any actual bindings;
- Dropbox entries deliberately skipped and why;
- documentation drift corrected;
- focused validation results.

## Next Handoff

After this packet lands, refresh the active Awakening scene/art-convergence work from current main. The next planning question is **visual reauthoring**, not more blind intake: compare older live/baked fixture and hero-prop art against the new Dust Lung/Undergate family language, preserve already-strong room plates/inlays/decals, and author replacement art only where the visual gain is real.
