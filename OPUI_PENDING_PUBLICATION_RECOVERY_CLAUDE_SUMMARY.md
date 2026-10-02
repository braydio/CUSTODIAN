# opui pending publication recovery

Recovered the failed idle_relaxed_01 east publication and west mirror on current main. The pending receipt named 84c3b7338, but an earlier rebase left the dedicated art branch at 96c4fce19. Both commits have identical stable patch IDs and identical final bytes for all eight affected PNGs. The old art branch was heavily diverged; replaying its entire history would include unrelated work.

Cherry-picked only the eight-file publication into this isolated workstream. Verified byte equality against the old hydrated art, 480x96 dimensions (five 96x96 cells), and exact per-cell east/west mirroring for both body layers in source and runtime. No visual approval or new artwork was inferred.

Preserved the entire old checkout, including ignored workspaces and pending receipt, at `/home/braydenchaffee/Projects/CUSTODIAN-operator-art-preserved-20261002-pending` on `recovery/operator-art-pending-20261002`. The original receipt remains there for audit. The recovered publication landed through workstream.py finish (08aba5213, art commit db681a96c). Restored the canonical workbench/operator-art checkout from origin/main and copied 2,650 ignored workspace files byte-for-byte. Archived the obsolete pending receipt under `.ai/operator_animation_workbench/recovery/20261002/` with a resolution record. Verified clean checkout, current main relation, healthy sparse profile, publish_allowed=True, no active pending receipt, actual opui --help, and Textual MainScreen startup without exceptions. The original branch history and all ignored state remain in the preserved checkout.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: earlier rebase changed the publish commit ID without updating its ignored pending receipt; divergent history prevented ordinary recovery
- Root cause / contributing factors: pending publication is identified by exact HEAD; startup repair restored access but did not reconcile publication history
- Prevention / pipeline improvement: preserve full checkout and recover only the verified publication patch through the normal lifecycle
- Tooling / docs drift discovered: pending receipt referenced pre-rebase commit
- Follow-up: fixed-in-scope
- What worked: stable patch identity, byte equality, and frame-cell mirror checks established the original publication without republishing
