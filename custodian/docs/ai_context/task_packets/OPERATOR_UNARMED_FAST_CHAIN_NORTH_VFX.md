# OPERATOR UNARMED FAST CHAIN NORTH VFX

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-unarmed-fast-chain-north-vfx`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-assets, operator-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, visual`
- Paired review workstream: `review-operator-unarmed-fast-chain-north-vfx`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `4fd73d43c8480ec63c492fc182bac484279f4825`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Replace the North-facing Fists Fast 01-04 FX tracks with the four visually approved Black-Gold Afterimage / Amber Vector source masters from immutable handoff `north-vfx-20261006-a1`, normalize them to the live 96×96-per-frame Operator contract, publish them through the existing guarded Operator asset pipeline, and prove source/runtime/selector/timing integrity without changing gameplay or other directions.
- Completion boundary: Done when all four approved handoff sources are fetched and hash-verified, preserved as source-work evidence, normalized with one whole-strip transform per animation to exact 6/6/7/8 96px-cell contracts, replace only the four North `fx` semantic identities through the specialized Operator replacement pipeline, rebuild canonical runtime/catalog resources, pass focused asset/runtime validation, and produce one compact North Fast 01→04 BODY+FX review showing the intended escalation and readable body silhouette.
- Immutable implementation input:
  - Remote manifest: `/CUSTODIAN/implementation_inputs/operator-unarmed-fast-chain-north-vfx/north-vfx-20261006-a1/HANDOFF_MANIFEST.json`
  - Schema: `custodian.implementation_handoff.v1`
  - Handoff ID: `north-vfx-20261006-a1`
  - Payload: `payload/CUSTODIAN_operator_unarmed_fast_north_vfx_handoff_20261006.zip`
  - Payload size: `1768949` bytes
  - Payload SHA-256: `e021b421682b2f9c8d395853cae8df4e3e0b0fcd84ea49c35ae960c65c921107`
  - Manifest authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
  - Dropbox is transport only. Fetch with `implementation_handoff.py`; do not use Dropbox as runtime/source authority.
- Current measured state:
  - `design/VFX_DESIGN_LOCK.md` is the active player VFX authority: Black-Gold Afterimage / Amber Vector; motion reads before power; dark afterimage first, amber vector second, compact white-hot contact third, sparse angular breakup last; character silhouette remains dominant.
  - Fists North Fast 01-04 body clocks are already canonical at 6 / 6 / 7 / 8 frames with 96×96 cells. Gameplay/contact/timing authority is already live and is not part of this task.
  - Fast 01 North already has a real authored FX source/runtime identity. The user explicitly requested this newly generated approved set as the replacement family; replacement must therefore use the guarded same-semantic REPLACE path rather than direct file copying.
  - Fast 02-04 North FX currently exist as canonical/runtime true-alpha-zero authoring placeholders from the reviewed North/South continuity slice. They are the intended replacement targets, not evidence of finished VFX.
  - The handoff package contains four generated source masters, a package manifest, `VISUAL_REVIEW.md`, and `CODEX_IMPLEMENTATION_INSTRUCTIONS.md`. All four sources were visually reviewed in the authoring conversation and passed; zero candidates were excluded.
  - These handoff PNGs are source masters, not runtime-final strips. Their native canvases exceed the final 96px-per-frame contract and must be normalized through the repository's Operator Source Session path. Do not copy the generated masters directly into canonical source/runtime.
  - The separate `operator-workbench-fx-layer-adoption` tooling packet is still dependency-gated by Browser/PREVIEW disconnect ownership review. This task does **not** depend on that future tooling because these are externally supplied source masters replacing already-existing semantic `fx` identities through the currently supported Source Session / specialized Operator intake path.
- Evidence:
  - `design/VFX_DESIGN_LOCK.md`
  - `custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md`
  - `custodian/tools/operator/README.md` Pre-canonical Source Sessions and guarded `source-handoff --replace` contract
  - `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`
  - `custodian/docs/ai_context/task_packets/archived/OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY.md`
  - `REVIEW_OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY_CLAUDE_SUMMARY.md`
  - current canonical/runtime Fast 01-04 North body and FX identities under `custodian/content/sprites/operator/{source,runtime}/animations/unarmed/attack/`
- Task-specific authority: `design/VFX_DESIGN_LOCK.md` for art direction; canonical Operator source/runtime schema and Source Session tooling for normalization/replacement; current fast-chain runtime profiles for immutable frame/timing contracts.
- Asset family / naming:
  - This is an existing specialized Operator animation family, not a new generic Asset V2 runtime family. Do not invent a parallel asset family or direct Asset V2 runtime path.
  - Preserve each approved generated master as source-work evidence before normalization:
    - `custodian/asset_drop/source_work/operator/unarmed/attack/fast_01/north/operator_unarmed_fast_01_n_vfx_generated_master.png`
    - `custodian/asset_drop/source_work/operator/unarmed/attack/fast_02/north/operator_unarmed_fast_02_n_vfx_generated_master.png`
    - `custodian/asset_drop/source_work/operator/unarmed/attack/fast_03/north/operator_unarmed_fast_03_n_vfx_generated_master.png`
    - `custodian/asset_drop/source_work/operator/unarmed/attack/fast_04/north/operator_unarmed_fast_04_n_vfx_generated_master.png`
  - Family schema: owner=`operator`, profile=`unarmed`, group=`attack`, actions=`fast_01..fast_04`, direction=`n`, semantic layer=`fx`, runtime frame size=`96`, clocks=`6/6/7/8`, non-looping.
  - Source Session `source-handoff --replace` stages exact specialized inbox identities; do not manually copy normalized outputs between inbox/source/runtime trees.
- Required canonical targets:
  - Fast 01 N: `operator__fx__unarmed__attack__fast_01__n__6f__96.png` → 576×96
  - Fast 02 N: `operator__fx__unarmed__attack__fast_02__n__6f__96.png` → 576×96
  - Fast 03 N: `operator__fx__unarmed__attack__fast_03__n__7f__96.png` → 672×96
  - Fast 04 N: `operator__fx__unarmed__attack__fast_04__n__8f__96.png` → 768×96
- Change:
  1. Fetch the immutable handoff with `python3 custodian/tools/iteration/implementation_handoff.py fetch --workstream operator-unarmed-fast-chain-north-vfx --handoff-id north-vfx-20261006-a1`. Verify manifest identity, exact payload set, payload size, and SHA before using any bytes.
  2. Extract the ZIP only into temporary/untrusted staging outside production content. Read its `PACKAGE_MANIFEST.json`, `VISUAL_REVIEW.md`, and `CODEX_IMPLEMENTATION_INSTRUCTIONS.md`. Verify the four source-master files match the package-declared hashes before promotion.
  3. Copy the four verified generated masters byte-for-byte into the authorized `asset_drop/source_work/operator/unarmed/attack/<action>/north/` paths above. Record their hashes as provenance. Do not treat source-work files as runtime content.
  4. For each action, create a pre-canonical Operator Source Session from its preserved source master. Use the live Operator registration profile and one shared whole-strip crop/scale/placement transform per animation. Use crisp method 1 / current equivalent. No independent per-frame scaling, repositioning, repainting, or timing edits.
  5. Normalize to exact 96×96 cells and 6/6/7/8 clocks. Preserve true RGBA transparency. Reject any crop that removes visible VFX pixels, any cross-cell bleed, matte/opaque background, or frame-registration teleport unrelated to the supplied body motion.
  6. Use `operator art source-handoff ... --replace --dry-run` first, then guarded `--replace` for the four exact semantic targets. This user-approved handoff authorizes Fast 01 N replacement as well as replacement of Fast 02-04 N alpha-zero placeholders.
  7. Run the existing specialized Operator manifest/ingest/runtime build. Do not hand-edit generated runtime PNGs, imports, runtime manifest, SpriteFrames resources, or reachability/catalog output.
  8. Preserve South and all East/West FX bytes. Preserve all body layers. Do not auto-mirror North into any other direction.
  9. Preserve Fists gameplay semantics byte-for-byte/semantically: attack profiles, 6/6/7/8 body clocks, contact/commit/queue windows, damage, stamina, hitstop, camera feedback, drive, buffering, targeting, chain order, and posture settle.
  10. Art-direction acceptance at final 96px scale:
      - Fast 01 remains smallest/cleanest, a compact probing jab/thrust;
      - Fast 02 reads as a longer driving vector, not a broad sweep;
      - Fast 03 preserves the incomplete rotational black-gold crescent and is the first meaningfully heavy link;
      - Fast 04 preserves the broken pressure-halo terminal payoff without burying the Operator silhouette;
      - combo escalation is obvious by breadth/contact clarity/brightness/fragmentation rather than simple size inflation;
      - white-hot pixels peak only at contact and recovery simplifies rather than grows noisier.
  11. Generate the smallest useful North Fast 01→04 BODY+FX preview from canonical/runtime assets after rebuild. Use objective image checks first, then publish one compact review artifact only if needed for final gameplay-scale aesthetic confirmation.
- Preserve:
  - Existing body/source/runtime art for all directions.
  - South/E/W FX identities and hashes.
  - Fast-chain gameplay/timing/profile data.
  - Canonical PNG source authority and generated runtime/catalog/resource ownership.
  - Source Session and specialized Operator replacement/rollback guards.
  - Existing Fast 01 South protected authority.
- Non-goals:
  - No South/E/W VFX creation or restyling.
  - No fast-chain gameplay retune.
  - No Workbench FX-layer-adoption tooling.
  - No new semantic animation identities.
  - No frame-count/canvas-contract migration.
  - No body animation edits.
  - No heavy attack, guard/parry, weapon, camera, audio, or procgen changes.
- Acceptance:
  1. Immutable handoff fetch succeeds and exact ZIP hash/size match this packet.
  2. Four preserved source-work masters match handoff package hashes byte-for-byte.
  3. Final canonical North FX sheets are exactly 576×96, 576×96, 672×96, and 768×96 with exact 6/6/7/8 clocks, RGBA alpha, and no cross-cell visible bleed.
  4. Fast 02-04 North are no longer alpha-zero placeholders; Fast 01 North is replaced only through explicit same-semantic guarded replacement.
  5. Canonical source and generated runtime pixels/hash pairs match for all four affected identities after the build.
  6. Only the four North FX semantic identities plus expected generated/import/catalog projections change; South/E/W FX and all body art remain unchanged.
  7. Runtime selector resolves exact North FX for all four links with clocks synchronized to North lower/upper body.
  8. Gameplay/profile/timing source is unchanged.
  9. Strict Operator animation contract and focused modular-layer/fast-chain selection/runtime smokes pass.
  10. Final North BODY+FX preview satisfies the live VFX lock: 01 < 02 < 03 < 04 escalation, motion-first readability, compact contact peaks, body silhouette preserved, no fire/smoke/anime-wave drift.
  11. Changed-file validation and `git diff --check` pass.
- Validation:
  - `python3 custodian/tools/validation/operator_animation_contract_report.py --strict`
  - `godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd`
  - `godot --headless --path custodian --script res://tools/validation/operator_modular_fast_attack_smoke.gd`
  - `godot --headless --path custodian --script res://tools/validation/operator_unarmed_fast_chain_smoke.gd -- --selection-only`
  - `python3 custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --sequence fast_01,fast_02,fast_03,fast_04 --include-fx`
  - Add one focused image-contract check if current tests do not prove alpha/cell-bound/source-runtime parity for these four strips.
  - `python3 custodian/tools/validation/run_validation.py --changed --json`
  - `git diff --check`
- Task overrides: `USER OVERRIDE (2026-10-06): implement the four visually approved North Fast 01-04 VFX from immutable handoff north-vfx-20261006-a1; exclude visually failed candidates (none failed); preserve real alpha; replace Fast 01 North plus Fast 02-04 North placeholders only; do not wait for the separate generic Workbench FX-adoption tooling lane.`
- Deferred: South-facing matching VFX and any diagonal expansion remain separate future art batches.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: Re-read live VFX lock, Source Session/replacement tooling, current North FX source/runtime identities, and the immutable handoff manifest before mutation. Mechanical path/tool spelling drift may be reconciled. If any handoff hash differs, the semantic target no longer exists, or current main has already replaced these exact North identities from another reviewed source, stop and return to this chat rather than overwriting newer art.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `pending`
- Completion boundary satisfied: `pending`
- Acceptance satisfied: `pending`
- Superseded/legacy production path disposition: `pending`
- Evidence: `pending`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `pending`
- What went wrong: `pending`
- Root cause / contributing factors: `pending`
- Prevention / pipeline improvement: `pending`
- Tooling / docs drift discovered: `pending`
- Follow-up: `pending`
- What worked: `pending`

## Handoff

- Next action: Claim `operator-unarmed-fast-chain-north-vfx`, fetch `north-vfx-20261006-a1`, normalize and replace the four North FX identities, validate, land, then run the paired review.
- Best starting files: `design/VFX_DESIGN_LOCK.md`, `custodian/tools/operator/README.md`, `custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md`, archived North/South continuity packet/review, and the immutable handoff package.
- Blockers or open questions: None. The Workbench FX-layer-adoption packet is a separate tooling lane and is not a dependency for this external-source replacement batch.
