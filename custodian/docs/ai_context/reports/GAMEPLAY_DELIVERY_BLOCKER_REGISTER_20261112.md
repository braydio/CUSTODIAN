# CUSTODIAN Gameplay Delivery Blocker Register
**Recorded:** 2026-11-12 (America/New_York)  
**Status:** Historical evidence + explicit continuation gates; **not** a claim, review receipt, CI waiver, or live host inventory.  
**Owner-facing orchestration chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af4b8b0-23b4-83e9-aded-a22c81f73ded  
**Repository:** `braydio/CUSTODIAN`  
**Purpose:** Stop repetition of the same Crèche/ES-1/worktree investigations, preserve the evidence required to resume safely, and return development to actual playable gameplay.

> **Read this before opening any new recovery task, cleaning a worktree, changing PR #146, or claiming ES-2.** This register is a dated report drawn from Codex/host executor findings and independently checked GitHub repository documents. Revalidate mutable Git refs, claims, policy, CI, and host ownership before acting. A historical successful test is not current CI acceptance.

## 0. Executive decision and stop rules

- **Crèche**: nearly complete implementation exists on retained feature branch and [draft PR #146](https://github.com/braydio/CUSTODIAN/pull/146). The owner wants the authored artwork *in the game*, not a reimplementation. Keep #146 open until a verified source-preserving replacement PR is available and a superseded-close action is authorized; do not confuse it with unrelated, already merged [PR #143](https://github.com/braydio/CUSTODIAN/pull/143). No Crèche merge, close, cleanup, or V2 bypass was executed during this campaign.
- **ES-1 / Refused Passage**: ES-1 implementation is landed; its independent review is **not accepted**. ES-2 Refused Passage is designed and packeted but has not been implemented in this campaign. Do not fabricate a review PASS or claim ES-2 is complete.
- **Capacity**: 38 attached worktrees in the last host census, zero safe retirement candidates under supported GC preview, and policy requiring two proven-safe retirements before allocating another checkout. Preserve the existing 38; do not repeatedly run broad GC/ownership sweeps absent new evidence.
- **No third broad recovery campaign.** A narrowly targeted resolution may be justified when an actual owner, lifecycle contract, or fresh evidence provides a viable path. Do not create administrative packets simply to restart the same diagnosis.
- **Separate bookkeeping from game delivery:** 20-turn queue-reduction campaign baseline was **522 active task Markdown records** at `main@121706c5bfe6b2ee363da5855ee55d0ab9d4e77e`, target <=507 (15 fewer). Through Turn 9, **0/15 verified reductions** and **no gameplay feature merged by this campaign**. Recount on fresh main before future claims.

## 1. Evidence provenance and time bounds

| Evidence | As-of identity | Meaning / limitation |
|---|---|---|
| Latest host preflight and census reported by Codex | `origin/main@0268a56c8f578779199cbdc39c98c9a12574b19b`; Turns 7-9, Nov 11-12 | Host-specific worktree/process facts; ChatGPT GitHub access cannot independently inspect this host |
| Crèche feature head | `15cd25791e3dcf3e0bbf647800520c5cbb5c0064` | Branch `agent/awakening-creche-console-sprite-reauthor-v1`; historically matches #146 head |
| PR validation | [Validate Repository #43123330604](https://github.com/braydio/CUSTODIAN/actions/runs/43123330604) | Fast PR and filenames passed; downstream selected 38/38 assertions, but overall failed source-integrity check |
| Sundered Keep baseline | [main run #43119801971](https://github.com/braydio/CUSTODIAN/actions/runs/43119801971) | Same four Sundered Keep failures reproduced independently on main |
| PR level pipeline | [run #43123330599](https://github.com/braydio/CUSTODIAN/actions/runs/43123330599) | Four baseline-matching Sundered Keep failures |
| Crèche branch push | [run #43123323609](https://github.com/braydio/CUSTODIAN/actions/runs/43123323609) | Old branch-side workflow's LFS checkout failures, distinct from PR checks |
| Private Crèche UID preservation | `/home/braydenchaffee/Projects/.custodian-review-preservation/creche-turn7-untracked-uid-preservation-20261112/PRESERVATION_MANIFEST.json` | Reported byte-identical preservation; not in Git, not a sandbox download |
| Protected ES-1 review run | `20261028T152859Z-9efb8b4be8ba` | Historical `host_validation_recovery`; reviewer was not launched and no verdict exists |
| Host worktree inventory | `worktree_backlog_census.py --json` at host main `0268a56c...` | Snapshot, **not** a live telemetry feed |

## 2. Crèche artwork and gameplay implementation: PRESERVED / NOT LANDED

**Workstream:** `awakening-creche-console-sprite-reauthor-v1`  
**Git branch:** `agent/awakening-creche-console-sprite-reauthor-v1`  
**PR:** https://github.com/braydio/CUSTODIAN/pull/146 (last confirmed open/draft/unmerged)  
**Current referenced head:** `15cd25791e3dcf3e0bbf647800520c5cbb5c0064`  
**Claimed checkout:** `/home/braydenchaffee/Projects/.custodian-turns/turn-awakening-creche-console-sprite-reauthor-v1-e366349adb2e`

### Existing tested work: do not redo

- Approved 1464x1074 RGBA environment masters, underlay SHA-256 `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`; foreground SHA-256 `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`. Asset V2 family `awakening_creche_environment`; preserve source/inbox/ingest/catalog provenance and rollback identities.
- Existing 128x128 approved console body SHA-256 `01716bcdf4a3d7169e52149f495f91830106df93f94736e3c2aee8d910a30acb`. Preserve exactly one console, its separate Sprite2D/ScreenAnchor, 8-frame 8-FPS FX, interactions and progress/reset.
- Existing implementation includes authored Zone01 walkability, 128px `01_02` north connector and north/return smoke. Historic scene registration `Vector2(0,-96)`, underlay z=-10 / foreground z=10 must be *verified*, not assumed current.
- Local focused changed validation reportedly passed 38/38 with complete coverage and `source_changed=false`. CI downstream also passed all 38 assertions but failed `source_changed_during_validation=true`, exit 4. **Exact file altered during CI was never established.** The CI `changed_files`/`excluded_files` entries (including `.gd.uid` or `.import`) are **not** a before/after Git status diff. Do not assert a particular UID/import caused this.
- Godot Level Pipeline failures: `sundered_keep_ingress_smoke.gd`, `sundered_keep_level_chain_smoke.gd`, `sundered_keep_approach_smoke.gd`, `sundered_keep_vista_polish_smoke.gd`. Matched main baseline. Branch-side push failures were LFS hydration/asset checkout problems.
- Gameplay-scale art acceptance was recorded in the packet, with a connector/destination-frame inspection limitation. Never convert that into an unqualified full visual inspection claim.

### Current exact lifecycle obstruction (host report)

`workstream_recovery.py audit` classified attached checkout `UNMANAGED_UNKNOWN`; no proven supervised journal. No task writer cwd was found attached. Tracked status clean, **two unrelated untracked .gd.uid files still present**, **20,186 ignored entries**, ~7.0 GiB of checkout material. This is **not** permission to delete files.

Preservation copies were created without touching originals:

| Original UID identity | SHA-256 / bytes | Known matching Git provenance |
|---|---|---|
| Operator 3D comparison smoke UID | `721bb1af7b70e17921355a4f39e10f30f6d29078f69acbebbc2db4ea527bd0af` / 19 | Same bytes tracked on `origin/main`, Git blob `f7897e089c2f80ba0d34b3e0412c9f864dba39de` |
| Procgen tilesetless ingress smoke UID | `686316850aabb2f426913bc8f7ffb82ab1d7d381e272d62662e88b46a76d2c5e` / 20 | Same bytes on retained `origin/worktree-cleanup/pursuit-frame-3d-playable-preview-v1-20261108T201853Z-945cc0e297a9`, commit `9eeff4b4575e69f59a09603424a7ff4fe5473648` |

Both original mtimes reported Nov 11, 2026, 15:29:57 EST. Manifest and copies were reported hash-equal to originals. **Preserving a copy does not itself authorize removing the original.**

Attempted canonical command:

```bash
python3 custodian/tools/agent/workstream.py resume awakening-creche-console-sprite-reauthor-v1 --repo /home/braydenchaffee/Projects/CUSTODIAN
```

Result: **`canonical branch agent/awakening-creche-console-sprite-reauthor-v1 is already attached; preserving existing checkout`**. Thus the practical blocker is existing attached canonical branch + dirty checkout, not merely missing supervisor history.

**Next defensible step:** Identify an explicitly supported, non-destructive already-attached checkout continuation/reconciliation operation in the *current* V2 lifecycle, including ownership proof. If none exists, retain and report this exact invariant. Do not detach, reset, stash, delete originals, delete ignored Godot caches, create an unapproved competing claim, or close #146 early. If a source-preserving replacement PR is later verified, #146 may be closed as superseded under the owner's direction without deleting the branch. Owner controls merges.

## 3. ES-1 protected review: UNACCEPTED / NO VERDICT

**Review workstream:** `review-procgen-environmental-evidence-v1`  
**Implementation:** `procgen-environmental-evidence-v1` (landed/archived)  
**Dependent gameplay:** `procgen-environmental-evidence-refused-passage-v1` (ES-2)  
**Original run:** `20261028T152859Z-9efb8b4be8ba`  
**Reviewer remote branch:** `1917c8940d3d980b5ee58a73da8a2e57eec08bf4`  
**Missing historical checkout:** `/home/braydenchaffee/Projects/.custodian-worktrees/review-procgen-environmental-evidence-v1-20261028T152927Z-5fdcca16e6c2`

Review metadata is `host_validation_recovery`, with `archive-only landing contains unrelated paths`. The original `RECOVERY.md` says reviewer **never launched**, verdict **not requested**. An attempted read-only recovery plan without attestations said missing pre-validation checkout requires two attestations. A plan with both exact flags then failed to inspect process ownership for PID `3206896`. On the interrogated host this PID appeared as `/system/bin/hw/android.system.suspend@1.0-service`, but that observation is **not** an authenticated assertion about reviewer ownership across relevant hosts. Do not manufacture missing attestations, infer process death from PID age, or mark PASS.

**Next defensible step:** A narrow, authority-supported reviewer ownership/attestation reconciliation, using the *existing* review run and runner. If the tool still fails, preserve exact failure and stop. Do not modify ES-1 implementation in reviewer context or create a substitute review PASS.

## 4. Refused Passage ES-2: READY DESIGN / IMPLEMENTATION BLOCKED

**Packet:** `custodian/docs/ai_context/task_packets/PROCGEN_ENVIRONMENTAL_EVIDENCE_REFUSED_PASSAGE_V1.md`  
**Design:** `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES2_REFUSED_PASSAGE.md`  
**Workstream:** `procgen-environmental-evidence-refused-passage-v1`

Planned player-facing output: optional deterministic 16x12 native 32px-cell (512x384px) abandoned checkpoint in an accepted F02 ES-1 story reservation; three causal variants (`emergency_quarantine`, `controlled_drawdown`, `disputed_diversion`), real impassable gate, >=3-cell safe bypass, distinct visible evidence, and two reachable repeatable `WorldReadoutInteractable` readouts. Existing packet allows clearly provisional blockout, without new Asset V2 production-art ingestion.

ES-2 packet expressly depends on **accepted** ES-1 independent review. At Turn 7, host dispatcher audit classified it ineligible because `review-procgen-environmental-evidence-v1` was not archived complete; paired ES-2 review also waits on implementation. V2 `dispatch.py claim` does **not** schedule by legacy audit metadata, but **that does not waive the actual independent-review acceptance ordering or active claim/ownership safeguards**. No ES-2 checkout or implementation branch created in this campaign.

**Next defensible step:** Recheck current authoritative V2 claim/review sequencing after ES-1 receives authentic acceptance, or produce an exact documented eligibility/ownership result without bypass.

## 5. Worktree capacity: CENSUS FINISHED / ZERO SAFE RETIREMENTS

At the host's Turn 9 read-only census (`origin/main@0268a56c...`):

| `worktree_backlog_census.py` classification | Count |
|---|---:|
| `ACTIVE_PROTECT` | 2 |
| `ARCHIVED_RESIDUE_CANDIDATE` | 1 |
| `BLOCKED_REVIEW_DISPOSITION` | 3 |
| `DETACHED_SUPPORT_PRESERVE` | 11 |
| `DIRTY_OR_UNIQUE_PRESERVE_FIRST` | 4 |
| `UNKNOWN_PROTECT` | 17 |
| **Total attached** | **38** |

19 were under `.custodian-turns` or `.custodian-worktrees`. Two safe retirements are required by project policy before a new checkout; none were proven. Supported command

```bash
python3 custodian/tools/agent/transient_worktree_gc.py --repo /home/braydenchaffee/Projects/CUSTODIAN --limit 2
```

returned `eligible=[]`, `blocked=[]`, `removed=[]`. Do not interpret an empty `blocked` array as proof of universal safety. **Zero retired, zero created.**

Only plausible archived residue:
`/home/braydenchaffee/Projects/.custodian-turns/turn-agent-owner-review-exception-closeout-recovery-v1-e675dd2bc8ed`
at `8b8c038678eafb4e7883141f85dc008deb650cc9`, clean with 0 untracked, behind main 83/ahead 0, archived packet. Its disposition is **not independently accepted**, process provenance is UNKNOWN, and no preservation receipt exists. Paired review checkout
`/home/braydenchaffee/Projects/.custodian-turns/turn-review-agent-owner-review-exception-closeout-recovery-v1-58f334caa88a`
is `BLOCKED_REVIEW_DISPOSITION`. Do not remove either. Even safely retiring one would leave the two-retirement requirement unmet.

**Stop rule:** Bounded census/GC pass is complete. Do not launch another broad sweep unless new specific evidence yields two real candidates or the owner separately authorizes an exact scoped lifecycle repair.

## 6. Known documentation drift and non-actions

- Historic `custodian/docs/ai_context/CURRENT_STATE.md` describes Crèche as 960x704 before the PR; this is not evidence that #146's 1464x1074 source cutover landed. Update current runtime truth **only after actual landing**; preserve historical evidence.
- ES-2 packet contains old ES-1-review blocker text about five undeclared docs. Current run state is the more specific `host_validation_recovery` + source scope and process inspection problem. Do not rewrite review outcome based on packet prose.
- Rope, hitbox, and surface-normal packets reportedly have stale `draft/manual` promotion paragraphs while their headers say `ready/auto`. This is documentation drift, not automatic dispatcher claim approval.
- Prior agent branch CI on Crèche lacks correct LFS setup; do not confuse it with current-main PR-side hydration or assume every red workflow is a Crèche source defect.
- The 20-turn target and active count are dated. Never reduce counts because a task packet was moved, a branch pushed, a test passed, or a worktree was removed without confirming canonical durable records.

## 7. Continuation decision table (avoid re-investigation)

| Trigger / new fact | Supported next step | Do **not** repeat |
|---|---|---|
| Current V2 gains an audited non-destructive continuation for an already-attached branch | Verify Crèche checkout/process/UID ownership; resume same branch under supported lifecycle | Generic `workstream.py resume` against dirty attached branch with no policy change; deleting UIDs; fresh Crèche reimplementation |
| New provenance conclusively localizes downstream PR source mutation | One bounded fix to exact writer, preserve identity guard, validate again | Guess `.uid`/`.import` writer from changed-file inventory |
| Owner has verified source-preserving replacement Crèche PR | Confirm exact commits/Asset V2 identities and approval, then close #146 **as superseded** if authorized | Closing #146 before replacement exists; deleting original remote branch |
| Original ES-1 review obtains authentic prevalidation/process ownership resolution | Resume same protected fresh-context review and record real verdict | Attestation by inference; manual review PASS; duplicate reviewer |
| ES-1 review accepted and real ES-2 claim gates clear | Implement existing ES-2 packet (not new packet) with positive seeded spawn and native readouts | Invent new narrative authority or ingest unapproved production art |
| Two worktrees independently prove all retirement predicates | Retire via canonical tool and recheck capacity/claimability | Worktree GC broad sweep, force-remove, reset, stash |
| No new evidence for either blocker | Keep workstreams protected; select an already-owned executable gameplay task if available; otherwise report capacity stop | More administrative loops without a concrete newly satisfiable invariant |

## 8. Required handoff format for future agents

Every continuation should give a **delta**, not replay the full investigation:

```text
Register reviewed: custodian/docs/ai_context/reports/GAMEPLAY_DELIVERY_BLOCKER_REGISTER_20261112.md
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af4b8b0-23b4-83e9-aded-a22c81f73ded
Fetched origin/main SHA:
Crèche #146 state/head + checkout dirty/untracked/ignored delta:
Crèche canonical lifecycle new fact (or unchanged exact refusal):
ES-1 protected review new fact (or unchanged exact refusal):
ES-2 claimability from current review authority:
Worktree count, eligible safe retirements, actual retired:
Changed file(s)/tests/CI and which outcomes are genuinely new:
Real main-merged gameplay features / active packet count:
ONE next supported action, or STOP reason:
```

**This is not authorization** to waive CI, change review verdicts, merge code, release worktrees, close #146 prematurely, or bypass Asset Pipeline V2. Resume only through the live repository policy and exact user authority.
