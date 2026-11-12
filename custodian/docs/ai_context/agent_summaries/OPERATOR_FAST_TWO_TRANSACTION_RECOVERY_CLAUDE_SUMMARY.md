# operator fast two transaction recovery

Recovered local unarmed/attack/fast_02/e transaction 20261002T191732 on 2026-10-03. The journal still reported RECOVERY_REQUIRED after source_swap/runtime_build. Original stderr was not retained, so the precise historical subprocess failure cannot be established from this receipt alone. The stage history resembles the supporting LFS preflight failures repaired earlier.

Proved all six east/west lower/upper/FX source hashes match the transaction's old hashes, all six source/runtime pixel pairs agree, and the generated runtime resource matches its old hash. Current LFS import preflight passes. The saved edited document and manifest both retain six frames and no pending migration; source freshness was verified. Backed up journal, manifest, and edited document under `unarmed/attack/fast_02/e/backups/transaction_recovery_20261003T230436`. A real Aseprite-backed six-target dry publish passed with 576x96 editable layer strips. The edited Aseprite bytes were unchanged. Marked the old journal ROLLED_BACK with explicit recovery evidence rather than suppressing a genuinely unresolved transaction.

Found an additional actual publication blocker: one generated return_causeway music WAV import sidecar differed only in its UID. Preserved its complete local bytes under `.ai/operator_animation_workbench/recovery/fast_two_20261003/music_import_metadata`, then restored the tracked metadata. No music audio bytes were changed. The dedicated art checkout became clean and the normal ensure route synchronized it safely to current origin/main.

Verified the real UI service sees ROLLED_BACK, enables the actual Publish review, reports 6 -> 6 frames, and leaves the checkout clean. Canonical animation art was not published by this repair; reopen OPUI/Publish to perform the reviewed publication. No frames or saved pixels were removed. Local ignored recovery files stay on this machine; this summary is the durable repository receipt.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: an old unresolved journal survived completed source/resource rollback; a generated music UID drift also blocked clean-checkout publication
- Root cause / contributing factors: original error details were absent from the journal; historical ignored state remained authoritative until explicitly reconciled
- Prevention / pipeline improvement: verify source/resource rollback before resolving receipts; preserve original subprocess error details in future transaction journals
- Tooling / docs drift discovered: journal lacked original failure diagnostics
- Follow-up: fixed-in-scope
- What worked: original hashes, runtime pixels, actual saved-document export, and actual UI publish review established safe recovery
