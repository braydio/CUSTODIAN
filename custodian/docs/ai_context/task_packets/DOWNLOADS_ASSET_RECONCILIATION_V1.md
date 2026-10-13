# DOWNLOADS ASSET RECONCILIATION V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `downloads-asset-reconciliation-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `downloads-housekeeping`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, workflow, code`
- Paired review workstream: `review-downloads-asset-reconciliation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `destructive local cleanup requires independent evidence and non-overlapping lifecycle ownership`
- Reviewed main: `48646ce06a630d8d524353df6d335d53fbef1747`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Goal: Audit the user's entire real Downloads directory against Dropbox source lanes and live CUSTODIAN runtime, classifying every byte before any removal or move.
- Completion boundary: Produce a comprehensive **read-only** local hash and archive-member inventory, exact manifest/same-content duplicate groups, Dropbox counterpart status and per-state runtime disposition, risk classification, immutable JSON/Markdown cleanup plan and targeted tests; do not modify Downloads, remote files or runtime.
- Current measured state: User provided 98 Downloads names, without bytes/hashes/stat information. This chat container cannot access the user's home Downloads. Current repo Kenney K3D1 inventory pins seven archive identities; 16 selected Kenney isometric states were already ingested and pixel-verified; prior `asset-downloads-intake-sweep` published Awakening fixture outputs from three Dropbox handoffs. Both facts are historical, not proof of current local bytes. Existing live Dropbox 3-lane listing exposes some but not all listed package names; missing name is not evidence of lost unique content.
- Evidence: `custodian/docs/ai_context/reports/assets/downloads_seed_inventory_20261013.json` (user-supplied names); `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json` (SHA256, member hashes and chosen 16 runtime outputs); `KENNEY_ISOMETRIC_BLOCKOUT_FEASIBILITY_CLAUDE_SUMMARY.md`; `ASSET_DOWNLOADS_INTAKE_SWEEP_CLAUDE_SUMMARY.md`; `custodian/docs/ai_context/reports/assets/dropbox_unstaged_asset_intake.json`; `custodian/tools/assets/dropbox_asset_audit.py`; `custodian/tools/assets/asset_status.py`.
- Task-specific authority: Real $XDG_DOWNLOAD_DIR (read from `xdg-user-dir DOWNLOAD` or `~/.config/user-dirs.dirs`, fallback `~/Downloads` only when verified); immutable Dropbox objects, per-batch SHA receipts and Asset Pipeline V2 runtime catalog for exact imported state; FS hashes and archive content for local truth. `~/dev` is a user-requested non-runtime destination, NOT CUSTODIAN's Godot dev scene tree.
- Work surface: New standalone `custodian/tools/maintenance/downloads_asset_sweep.py` or similarly narrow CLI; fixture tests under `custodian/tools/maintenance/`; scoped ignored host-private plan/receipts under `~/.local/state/custodian/downloads-cleanup/`; committed small redacted summary at `custodian/docs/ai_context/reports/assets/` and no confidential absolute user paths in Git.
- Change: Implement a comprehensive no-write Downloads audit, remote/runtime crosscheck, deterministic delete-safe plan and tests.
  1. Resolve the actual Downloads directory; collect every regular file, nested directory, symlink, file type, size, mtime, SHA-256 and inode link information. Parse ZIP central directories safely (CRC/zip-slip/symlink/bomb protections) and hashes of listed members, plus manifests, licenses and directories containing source/art. Compare full folder trees with companion ZIPs rather than assuming a directory named after an archive is duplicate.
  2. Derive exact-content duplicate groups for `(1)`–`(4)` and variant filenames. Compare to 3 Dropbox source lanes plus legacy source and audit index (full pagination) using Dropbox content-hash **and independent SHA-256 of downloaded bytes** where needed; filename matching alone never suffices. Identify any unique content not in Dropbox or repository, and record proposed immutable handoff family/state/manifest under existing Asset Pipeline V2.
  3. Resolve Kenney source ZIP hashes against `k3d1_source_inventory.json`, associated CC0 licenses and runtime pixel-hash receipts, including the original two 256×512-cell miniature families (10+6 states). The user specifically requests preservation of `kenney_isometric-miniature-prototype.zip` and `kenney_isometric-miniature-bases.zip` under `~/dev/kenney_isometric/` (prefer an existing user-approved `dev/` root). Record exact target, hashes, and license copies. Kenney Shape tool is a future tool input, not automatically disposable.
  4. Cross-check each Awakening, Operator, Ritualant, audio, Alpine/Bridged Falls, Vaultwing, Kenney and prototype asset against current `source_work`, inbox, Asset V2 catalog, generated .import resources, bound consumers and archived/active packet ownership. Distinguish `source_backed_up`, `art_present`, `imported`, `bound`, `runtime_verified`; do not treat any as synonyms. Where a ZIP lacks a counterpart, identify what it contains and whether one of the current asset-family packets owns it. No unreviewed art auto-approval or new runtime ingestion here.
  5. Explicitly classify nonasset/personal-or-unknown entries such as `clip.mp4`, `tailscale`, `del`, `handoff`, `PNG`, `Tilesheet`, `Vector`, and bare `License.txt`; preserve any unproven/sensitive content. Likewise inspect Lua/Python/scripts/patches for unique uncommitted working source versus committed duplicates before proposing disposition.
  6. Produce one deterministic, itemized read-only `plan.json` and `REPORT.md` with: original exact path, file type, bytes, SHA, archive members count/CRC, remote fq_path/file ID/revision/size/hashes, exact Git authority, runtime state/scene consumer, action (`move-dev`, `preserve-and-publish`, `delete-verified-duplicate`, `archive-stale`, `unknown-protected`), proof and blocker. Report total count/bytes per category and preview proposed target/saved space. No cleanup or cloud mutation in this slice.
  7. Test recursive tree walking and symlinks, empty directories, multi-GB/duplicate ZIP handling, MIME mismatch, case collisions, ZIP bombs/path traversal, stale Dropbox listing, remote hash disagreement, current runtime state absent, unique user file, and idempotent report diff. Keep no high-res binary assets in Git.
- Preserve: User's non-CUSTODIAN/private files; source masters and originals lacking proven remote backup; repo asset ingest/presentation ownership; existing Dropbox immutable batches/receipts; current claimed worktree and unrelated asset metadata.
- Non-goals: Do not delete, move, upload, ingest or modify the real Downloads in audit slice. Do not reimplement existing Asset V2 or Dropbox transport; do not rewrite Kenney licensed source files. Do not use destructive cleanup while unresolved review is protected.
- Acceptance: Every real Downloads file gets exactly one disposition with evidence; all user-listed names are reconciled or explicitly marked absent; local ZIP+expanded tree identity verified before delete classification; exact hashes and runtime proof required for `delete-verified-duplicate`; required two Kenney isometric ZIPs go to move-dev rather than delete; Kenney K3D1 16-state receipts are checked against live runtime; unbacked unique source classified preserve-and-publish; no files moved/deleted/uploaded/ingested in this packet; clean read-only rerun gives same plan.
- Validation: Focused offline unit tests and a full `scan --dry-run` on actual user Downloads, source checks via `python3 custodian/tools/assets/asset.py needs --check`, `python3 custodian/tools/assets/asset.py doctor`, optional read-only Dropbox CLI scan, `python3 custodian/tools/agent/task_packet_index.py`, `git diff --check`.
- Task overrides: `none`
- Deferred: Unique user-private/unclassified materials never become auto-deletable. Apply cleanup only from the independently reviewed exact plan in successor.

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
