# Worktree Backlog Recovery, 2026-10-17

Status: **reported baseline awaiting host-local verification**, not a cleanup authorization or statement that any workstream is abandoned.
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
Planning base: `origin/main@c02747856055d38cb8ea6871b49257cfcee82dad`.
Worktree root reported: `/home/braydenchaffee/Projects/.custodian-worktrees/`.

## Critical accounting correction

The supplied host audit states **36 unfinished attached worktrees**, **17 dirty** and **19 clean**, but actually **names only 17 dirty + 18 clean = 35**. Do NOT infer the 36th identity or delete anything until the host-local census resolves that gap. The ahead-of-main list contains `transit-lift-runtime-foundation-v1`, absent from both unfinished-worktree name lists; establish whether it is the missing checkout or separately attached. The 10 ahead-head cases overlap dirty/clean and must **not** be summed to the 36.

Reported other scopes: two attached archived-complete packet worktrees (`review-agent-next-execution-boundary-v1` dirty; `review-compound-connected-bunker-blockout` clean); 11 additional detached worktrees including two Alpine cliff capture names; 65 dispatcher `invalid_recovery` packet records; 2 dispatch claim refs without agent branches; the coordination checkout is clean on `main`. These categories may overlap remote claim records and must be separately reconciled.

## Named unfinished, dirty (17)

### Implementations (7)
- `living-world-population-slot-reservations`
- `operator-ranged-domain-extraction`
- `procgen-alpine-cliff-presentation-v1`
- `procgen-archive-resolve-playtest-polish-v1`
- `procgen-streaming-near-player-priority-v1`
- `ritualant-npc-silhouette-readability-shader-v1`
- `vehicle-field-scout-buggy-class-v1`

### Reviews (10)
- `review-agent-paired-review-godot-cache-access-v1`
- `review-awakening-collision-mapper-authoring-bridge-v1`
- `review-codex-art-import-shared-transform`
- `review-isometric-2-5d-presentation-foundation`
- `review-operator-2-5d-composition-mode-guard-v1`
- `review-procgen-ambient-real-world-spawn-recovery-v1`
- `review-procgen-showcase-exhibit-catalog`
- `review-reciprocal-continuity-canon-drift-guard`
- `review-ritualant-score-direction-correction-v1`
- `review-vaultwing-runtime-hardening`

## Named unfinished, clean (18, despite reported 19)

### Implementations (12)
- `agent-mission-control-data-model-v1`
- `ash-bell-ritualant-runtime-truth-closeout`
- `contract-world-encounter-placement-extraction`
- `downloads-asset-reconciliation-v1`
- `hub-muster-continuity-port-deployment`
- `npa-showcase-broken-warrant-actor`
- `operator-2-5d-ne-walk-retargeting`
- `operator-elevation-traversal-enforcement-v1`
- `operator-unarmed-defense-source-promotion`
- `procgen-authored-claim-registry-extraction`
- `procgen-showcase-generated-arena`
- `twin-solaria-crown-incident-forensics`

### Reviews (6)
- `review-bidirectional-dropbox-handoff`
- `review-bridged-falls-generated-region-lifecycle-review-corrections-1`
- `review-compound-connected-bunker-blockout-review-corrections-1`
- `review-lords-of-pain-test-gallery`
- `review-npa-showcase-dev-overlays`
- `review-npa-showcase-existing-drone-hardening`

## Worktree HEADs reported with commits absent from origin/main (10)

| Workstream | Ahead commits at inspected attached HEAD |
|---|---:|
| `hub-muster-continuity-port-deployment` | 9 |
| `npa-showcase-broken-warrant-actor` | 1 |
| `operator-2-5d-ne-walk-retargeting` | 20 |
| `procgen-alpine-cliff-presentation-v1` | 26 |
| `review-lords-of-pain-test-gallery` | 1 |
| `review-npa-showcase-dev-overlays` | 1 |
| `review-npa-showcase-existing-drone-hardening` | 1 |
| `ritualant-npc-silhouette-readability-shader-v1` | 1 |
| `transit-lift-runtime-foundation-v1` | 1 |
| `vehicle-field-scout-buggy-class-v1` | 1 |

These are reported local HEAD counts, not verified published branch protection or complete uncommitted-file capture. For each, compare `git rev-list --count origin/main..HEAD`, `git branch -r --contains HEAD`, canonical remote ref, merge-base, root/head metadata and evidence. Preserve unique commits before recommending retirement.

## Five paired workstreams

| Sequence | Implementation workstream | Responsible outcome |
|---|---|---|
| W1 | `worktree-backlog-census-and-safety-ledger-v1` | Read-only census: reconcile 36/35 discrepancy, states, owners and exact identity |
| W2 | `worktree-backlog-dirty-and-unique-preservation-v1` | Private byte-verified evidence for dirty files and unique HEADs, no original checkout mutation |
| W3 | `worktree-backlog-owned-work-recovery-v1` | Claim-aware existing-work continuation/finishing plan; actual execution only on supported original identity |
| W4 | `worktree-backlog-archived-and-detached-reconciliation-v1` | Proof-gated cleanup of archived leftover and detached support checkouts |
| W5 | `worktree-backlog-queue-invalid-claim-triage-v1` | Separate exact evidence-based classification for 65 invalid packets and two interrupted dispatch claims |

All packet pairs begin `draft/manual`, with explicit `Authoring handoff: auto` to run targeted validation and automatic promotion. Promotion is NOT a claim, owner lease, reviewer acceptance or deletion authorization.

## Required machine-local evidence row schema

Exactly one record per canonical attached/detached worktree path, with no inferred row merges:

`worktree_path, worktree_porcelain_identity, packet_workstream, packet_path, kind, packet_status, dispatch_class, claim_ref, claim_sha, remote_agent_branch_sha, attached_HEAD, main_SHA, merge_base, ahead_count, behind_count, staged_count, unstaged_count, untracked_count, dirtiness_fingerprint_or_blocker, unique_commits_proven, execution_process_provenance, last_run_id, review_outcome, reviewer_receipt_provenance, protected_user_files, classification, action, authority, approval_required, preservation_receipt, next_workstream`.

Permitted conservative classifications: `ACTIVE_PROTECT`, `RECOVERABLE_ORIGINAL_CLAIM`, `DIRTY_OR_UNIQUE_PRESERVE_FIRST`, `DRAFT_PARK_NO_MUTATION`, `BLOCKED_REVIEW_DISPOSITION`, `ARCHIVED_RESIDUE_CANDIDATE`, `DETACHED_SUPPORT_PRESERVE`, `CLAIM_ONLY_INTERRUPTED`, `INVALID_QUEUE_RECORD`, `UNKNOWN_PROTECT`. An absent process, clean worktree or age does not prove abandonment. Proposed mutations must identify exact tool/authority and independent acceptance gates.

## Never do in census / evidence capture

No `git reset --hard`, `git clean`, default `git stash`, force push, branch deletion, archive/tag pretending acceptance, packet `Status: complete` substitution, reviewer PASS fabrication, worktree removal with dirty/unlanded bytes, invalid-recovery blanket waiver, new claim for an existing owned run, OR2 lease parking before its independently accepted authority, or mass edits in the user's persistent checkout.
