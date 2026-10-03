# operator fast three LFS recovery

Recovered local unarmed/attack/fast_03/e publication prerequisites on 2026-10-03. Transaction 20261003T040433 reached source_swap/runtime_build then failed Godot import preflight. Rollback encountered the same preflight block and left RECOVERY_REQUIRED. Supporting audio/environment/effect assets were still LFS pointers in the replacement checkout created during earlier recovery; that prior recovery hydrated Operator animation assets only. This was a recovery omission, not a frame-contract problem with fast_03.

Materialized supporting assets from the existing local LFS cache. The general git lfs checkout expanded omitted files and was stopped; the remaining 1,544 checked-out pointers were materialized directly after verifying cache object size and SHA256. No cache objects were missing. Godot preflight and a real project-locked Godot import succeeded.

Godot import produced tracked metadata drift and untracked sidecars. Archived generated metadata under the ignored recovery directory, restored tracked metadata, and reapplied the authored sparse profile. Hydration changed executable mode on two WAV files; restored their HEAD modes after verifying unchanged content. Refreshed LFS index stat entries via scoped git add after proving an empty actual diff; verified no staged or working changes afterward. No asset edits were committed.

Verified all six source hashes against the failed transaction backups, all six restored source/runtime pixel pairs, and the generated runtime resource hash. Preserved the original transaction receipt as transaction.before_recovery.json and marked its journal ROLLED_BACK after recovery checks. Actual Aseprite-backed dry publication passed for all six east/west lower/upper/FX targets. The edited Aseprite document remains byte-identical. This restores publication prerequisites without publishing the edit; reopen Workbench and retry.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: previous replacement checkout recovery omitted supporting LFS hydration; generic checkout expanded sparse content and import produced metadata churn during this repair
- Root cause / contributing factors: Operator-only hydration does not cover project-wide import preflight requirements; generic LFS checkout affects omitted sparse paths
- Prevention / pipeline improvement: verify zero checked-out LFS pointers after replacement checkout recovery; hydrate only present pointers from verified local cache; retain sparse profile and clean status
- Tooling / docs drift discovered: transaction exposed generic subprocess exit status rather than actionable preflight details
- Follow-up: fixed-in-scope
- What worked: deterministic pointer, hash, pixel, import, and dry-publication checks preserved the edited document
