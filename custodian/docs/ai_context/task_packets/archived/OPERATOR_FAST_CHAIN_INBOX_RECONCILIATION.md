# OPERATOR FAST CHAIN INBOX RECONCILIATION

- Workstream: `operator-fast-chain-inbox-reconciliation`
- Kind: `correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `operator-assets`
- Review: `none`
- Goal: Remove the persistent Asset Doctor warning for 12 unregistered Operator fast-chain inbox PNGs by proving whether they are stale duplicate intake or real unprocessed assets, then reconcile them without reprocessing valid runtime art or bypassing current asset-pipeline doctrine.
- Current measured state: Asset Doctor repeatedly reports exactly 12 PNGs under `custodian/asset_drop/inbox/operator/`. They are the east-facing Fast 01–04 lower-body, upper-body, and FX strips. Matching canonical Operator source/runtime outputs and historical specialized-pipeline archive/log records already exist for the same semantic filenames.
- Task-specific authority: live Operator asset pipeline/tooling; `custodian/tools/operator/README.md`; Operator runtime manifest; Asset Pipeline V2 doctor/intake policy; current project rule that genuinely new/unprocessed assets must enter through Asset Pipeline V2 rather than becoming an undocumented second intake path.
- Change: Hash/metadata-reconcile all 12 inbox files against canonical source/runtime/archive records; delete/retire only proven stale duplicate intake; leave runtime/source truth unchanged. If any inbox file differs materially and is genuinely unprocessed, fail closed and queue a separate V2-compatible Operator intake/adapter packet rather than silently running a legacy ingest.
- Preserve: Fast 01–04 runtime 6/6/7/8 frame timing, east-authored/west-derived behavior, source/runtime manifests, Workbench/MCP tooling, existing runtime hashes unless a proven missing update is found.
- Non-goals: No Fast-chain game-feel retune; no animation regeneration; no VFX redesign; no broad Operator pipeline migration; no creation of speculative V2 families for already-processed files.
- Acceptance: Asset Doctor no longer reports the unregistered Operator inbox warning; all 12 files have a documented disposition; canonical source/runtime fast-chain outputs remain byte-identical to pre-task unless the task stops for a real unprocessed mismatch; no runtime manifest regression.

## The 12 Files

All are under:

`custodian/asset_drop/inbox/operator/`

### FX

- `operator__fx__unarmed__attack__fast_01__e__6f__96.png`
- `operator__fx__unarmed__attack__fast_02__e__6f__96.png`
- `operator__fx__unarmed__attack__fast_03__e__7f__96.png`
- `operator__fx__unarmed__attack__fast_04__e__8f__96.png`

### Lower body

- `operator__lower_body__unarmed__attack__fast_01__e__6f__96.png`
- `operator__lower_body__unarmed__attack__fast_02__e__6f__96.png`
- `operator__lower_body__unarmed__attack__fast_03__e__7f__96.png`
- `operator__lower_body__unarmed__attack__fast_04__e__8f__96.png`

### Upper body

- `operator__upper_body__unarmed__attack__fast_01__e__6f__96.png`
- `operator__upper_body__unarmed__attack__fast_02__e__6f__96.png`
- `operator__upper_body__unarmed__attack__fast_03__e__7f__96.png`
- `operator__upper_body__unarmed__attack__fast_04__e__8f__96.png`

These names already encode the intended 96×96 frame canvas and 6/6/7/8 frame counts.

## Reconciliation Procedure

For each file:

1. resolve actual LFS content;
2. compute SHA-256;
3. compare to the matching canonical Operator source strip under:
   `custodian/content/sprites/operator/source/animations/unarmed/attack/fast_0X/`;
4. compare semantic dimensions/frame count;
5. compare runtime manifest entry and canonical runtime strip;
6. inspect specialized pipeline archive/log provenance.

Classify:

- `STALE_DUPLICATE_INTAKE`: content is already represented by canonical processed source/runtime history;
- `DIVERGENT_UNPROCESSED`: content differs and is not represented by current source/runtime;
- `AMBIGUOUS`: provenance cannot be proven.

Only `STALE_DUPLICATE_INTAKE` may be removed from the inbox in this packet.

For divergent/ambiguous files, stop destructive cleanup and report exact hashes/differences.

## Asset Pipeline V2 Boundary

Do not invent a family schema in this reconciliation task merely to silence Doctor.

If a divergent/unprocessed Operator file exists, create a follow-up packet that first defines the appropriate Asset Pipeline V2 integration/adapter against the live schemas and Operator semantic-layer contract.

Any future normalized new asset should retain the same semantic naming under an explicitly defined V2 inbox family, with source-work provenance, before publication.

## Validation

- Operator runtime manifest/build validation;
- fast-chain continuity/timing smokes;
- any Operator asset audit relevant to source/runtime hashes;
- `asset.py doctor` must clear this warning;
- `git diff --check`.

Record before/after hashes and dispositions in the closing summary.

## Completion

Archive complete and write
`OPERATOR_FAST_CHAIN_INBOX_RECONCILIATION_CLAUDE_SUMMARY.md`.


## Completion Record

- All 12 specified PNGs were resolved from Git LFS and their names, decoded dimensions, frame counts, and runtime manifest entries were checked.
- Nine entries have byte-identical archived intake PNGs and corresponding specialized pipeline logs. Fast 01–03 FX entries have byte-distinct PNG encodings but decoded pixels exactly match canonical source and runtime; canonical source carries an `sRGB` chunk absent from the inbox copy.
- Removed the 12 stale duplicate inbox files. Canonical source/runtime PNG hashes, runtime manifest, and generated Operator catalog are unchanged.
- `asset.py doctor`: healthy, zero issues (before: one `operator (12 PNGs)` warning).
- `sync_operator_runtime_assets.py --dry-run --strict`: pass; 586 runtime sheets, zero warnings. `operator_animation_contract_report.py --strict --json`: pass; no missing required art (3 optional rows remain missing). Timing smoke passed.
- The unarmed fast-chain continuity smoke passed after seeding the worktree's ignored Godot cache with the existing imported sample from the project-root checkout. Source WAV and `.import` metadata were byte-identical between worktrees. A first run before that cache seed timed out while Godot rejected the existing non-PCM WAVE import; the passing rerun emitted only the runner-classified ObjectDB/resource shutdown warnings. No audio or runtime files were changed.
- Moment Forge not run: no runtime or presentation changes. `git diff --check` passed.
