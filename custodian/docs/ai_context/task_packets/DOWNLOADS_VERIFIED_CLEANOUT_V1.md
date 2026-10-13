# DOWNLOADS VERIFIED CLEANOUT V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `downloads-verified-cleanout-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-downloads-asset-reconciliation-v1, review-dropbox-asset-lifecycle-reconciler-v1`
- Locks: `downloads-housekeeping, dropbox-handoff`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, workflow, code`
- Paired review workstream: `review-downloads-verified-cleanout-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `destructive local cleanup requires independent evidence and non-overlapping lifecycle ownership`
- Reviewed main: `48646ce06a630d8d524353df6d335d53fbef1747`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Goal: Execute the reviewed Downloads tidy-up, retain Kenney isometric source under dev/, preserve missing unique project inputs in Dropbox and remove verified clutter without losing any unrecoverable data.
- Completion boundary: Consume the exact SHA-256-pinned reviewed inventory plan. Apply only immutable-proven operations: move the two original Kenney isometric archives to the selected `~/dev/kenney_isometric/` target, preserve source-only unique CUSTODIAN assets via hash-backed source handoffs, and remove backed-up/reproduced obsolete duplicates from Downloads with an immutable per-file move/trash receipt. Verify resulting directory and remote/runtime state. Any unproven item is protected and named in the residual list.
- Current measured state: Predecessor is responsible for per-item local hashes, counterpart remote proofs and proposed operations. `Dropbox Asset Lifecycle` audit is published but its independent review currently protects `post_exit_recovery`; that review must complete before this packet may claim Dropbox source publication. There are files in Downloads that are not proven CUSTODIAN assets; user requests cleanup after verification, not permission to destroy private/unknown bytes.
- Evidence: Reviewed exact inventory `plan.json` + immutable SHA-256 signatures/summary from downloads-asset-reconciliation-v1; existing `custodian/tools/assets/dropbox_asset_stage.py`, `dropbox_asset_publish.py`, `custodian/tools/iteration/implementation_handoff.py`, `custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md`, Kenney inventory, current `asset.py status` and requirements.
- Task-specific authority: Reviewed predecessor report and local-host file SHA verification; Dropbox immutable upload registry and existing source-work family manifest; local `~/dev/kenney_isometric/` out of Downloads; narrow asset sweep CLI `apply --plan <file>` with fail-closed checks; per-file operation receipts saved in ignored host state and human report.
- Work surface:   1. From the **same user host**, re-scan every planned path/inode/size/SHA256 immediately before execution. Refuse stale plans and any path outside the resolved Downloads root; reject symlink escapes, traversal, wrong devices and unexpected new/modified files.
  2. Move `kenney_isometric-miniature-prototype.zip` and `kenney_isometric-miniature-bases.zip` intact into `~/dev/kenney_isometric/` (or an existing `dev/` root after reconciling ownership). Preserve included licenses. Never move into Godot's `custodian/game/world/levels/authored/dev/` or touch already-ingested 16 textures. Use copy+fsync+hash verify then exact-source unlink if cross-filesystem.
  3. For CUSTODIAN source-only ZIPs/folders not backed up, package versioned raw full-resolution source and manifest/checksums under canonical Dropbox source batches via existing handoff transport; verify remote SHA and member identities. Do **not** equate remote preservation with artwork approval or run runtime ingest unless separately authorized by the owning task. If a required input has a live packet, record it in that owner instead of duplicating asset families.
  4. Files that are truly redundant by SHA (and backed by either verified immutable remote or a complete Git source/runtime import provenance) may be moved to the host Trash using `gio trash` or safe equivalent. Never `rm -rf ~/Downloads`, do not recursively delete a directory until all contained entries are individually accounted for, do not empty Trash automatically, and do not overwrite target files. Make each action atomic/idempotent and journaled with success/failure and restoring location when available.
  5. Preserve unknown/personal files in place unless the user explicitly requests an otherwise destination; do not assume `clip.mp4`, `tailscale`, scripts or raw source folders are CUSTODIAN downloads. If unresolved, report them as blockers to an entirely empty Downloads rather than deleting. User-approved exact duplicate scripts/art may be safely removed only after proof; `ASSET_MANIFEST.json` / `License.txt` with no linked archive must remain until attribution is verified.
  6. After operations, rerun scan/health checks and report retained/new/unresolved paths, actual bytes removed from Downloads, exact Dropbox batches published, hashes for moved/trashed items, any asset-family owner newly queued, actual dev target and restoration receipt. No change to runtime or existing review workstreams except truthful non-destructive documentation updates.
- Change: Apply only the independently reviewed SHA-pinned cleanup plan, moving Kenney isometric archives to dev, publishing unique sources and trashing verified duplicate clutter.
All safe actions from reviewed plan applied with byte-identical destination or remote proof; original two Kenney isometric ZIPs and licenses verified under dev; all new source uploads registered and hashed; Downloads reduced only by provably redundant files, not personal/unique content; residual list exhaustive and includes reasons; Trash recoverable; runtime remains unchanged; rerun of apply is no-op; no duplicate Dropbox families or collisions.
- Preserve: User's non-CUSTODIAN/private files; source masters and originals lacking proven remote backup; repo asset ingest/presentation ownership; existing Dropbox immutable batches/receipts; current claimed worktree and unrelated asset metadata.
- Non-goals: Any unproved and sensitive file remains outside automatic deletion scope; provide a precise residual list instead of a misleading 'Downloads empty' claim.
- Acceptance: Revalidate plan exact local bytes and remote content before actions; per-item filesystem and journal replay/partial failure tests; `python3 custodian/tools/assets/asset.py doctor` and `needs --check` for relevant families; audit Dropbox derived index; source family receipt checks; changed-file and no-stale-index gates; compare before/after file trees.
- Validation: No permanent recursive delete, no Trash emptying, no private media removal without exact provenance, no automatic runtime integration of unreviewed source, no interference with blocked paired-review runner.
- Task overrides: `none`
- Deferred: undefined

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh instruction: Reconcile this seed and the current independent Dropbox lifecycle review against fresh live `origin/main`; do not treat a stale user filename list as exact or complete local inventory.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Execute exact-hash evidence and leave one immutable cleanup plan/receipt; downstream deletion must use the reviewed proof and no other inventory.
- Blockers or open questions: Local Downloads access is necessary in the claimed Codex host; do not guess file hashes from names.
