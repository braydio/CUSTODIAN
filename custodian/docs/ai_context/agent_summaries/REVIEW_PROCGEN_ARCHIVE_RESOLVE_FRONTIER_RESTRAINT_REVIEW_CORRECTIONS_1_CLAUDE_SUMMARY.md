# Review: ProcGen Archive Resolve Frontier Restraint Corrections 1

Two blocking implementation findings remain. The canonical R1-01 existing-cell and later-COMMIT wall fixtures are fixed, but overall correction acceptance cannot close. This fresh different-agent review inspected correction `f66722ca9c5d3bfa1bec969716b8851ab203e088` on claimed main `911e8871e77c7505a574334d5ab714b5458c7b94`. Only review receipts, lifecycle/index metadata, this summary, and bounded correction/re-review packets are changed; reviewed implementation is untouched.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73

## Findings

### R1-02 — stale pending ingress COMMIT exposes uncommitted reacquisition

- Class: `blocking_defect`
- Domain: `implementation`
- Disposition: `correction`
- Affected acceptance: correction 1 acceptance 5 (uncommitted tiles stay veiled), request-before-COMMIT, and AR4 committed-only settlement.
- Source: `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd:289`, `:378`, `:720`.
- Evidence: `note_tile_committed()` saves a pending key. `_release_tile()` erases its veil/state but leaves that key. After unload and reacquisition REQUEST with no COMMIT, `_settle_visible_ingress_pocket_commits()` checks only `_states.has(tile)` and removes the new REQUESTED veil. One advance changes state 1 -> 0 and veil true -> false. The clean REQUESTED negative control stays state 1/veiled.
- Rationale: Pending eligibility belongs to the committed identity, and cannot authorize a new uncommitted identity. The public owner API sequence deterministically violates that invariant. The probe does not claim the complete production scheduler presently executes this exact interleaving.

### R1-03 — absent visibility center bypasses ingress deferral

- Class: `blocking_defect`
- Domain: `implementation`
- Disposition: `correction`
- Affected acceptance: explicit correction requirement to defer unknown visibility; correction 1 acceptance 3 (hidden later COMMIT stays veiled until visibility opens).
- Source: `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd:329`, `:337`, `:379`; production adapter `custodian/game/world/procgen/proc_gen_tilemap.gd:10737`.
- Evidence: A hidden pocket COMMIT becomes READY. Updating with NO_OPERATOR_TILE removes the mask center; pending immediate settlement correctly waits, but the ungated ordinary READY fallback starts resolving anyway. After 0.6 presentation seconds, veil=false with has_center=false. The production adapter supplies that sentinel if its player reference is absent/invalid.
- Rationale: Checking unknown visibility in only the immediate-settlement helper is insufficient while another start path admits the same ingress record. This is a deterministic owner-level failure of the specified fail-safe behavior, with no design/art decision required.

### R1-01 disposition and preserved behavior

Original already-committed and later-COMMIT hidden-pocket reproductions pass. `begin_ingress_resolve()` invalidates/rebuilds the read-only visibility mask at the ingress center before settling visible cells. Hidden records retain cover until visibility opens; RESOLVING records continue monotonically. Visible existing pocket cells settle synchronously; a visible later COMMIT settles on its next initialized update. The correction changes only the presentation owner and its smoke; canonical wall inputs, tilemap COMMIT, generation, collision/navigation, shader and timing budgets are unchanged by its runtime diff.

## Validation

| Registered test | Outcome | Runtime ms |
| --- | --- | --- |
| `procgen_archive_resolve_frontier_restraint` | passed | 3703 |
| `contract_world_archive_resolve_ingress` | passed | 13657 |
| `procgen_reveal_presentation` | passed | 9672 |
| `procgen_archive_resolve_semantic_echo` | passed | 10009 |
| `procgen_pause_aware_streaming` | passed | 3530 |
| `procgen_performance_baseline_quick` | passed | 81618 |

S1 reports `determinism_ok=true`; both 48x48 samples retain fingerprint `1773840677`. Registered checks pass but omit the two reproduced edge sequences. The additional probe intentionally exits 1 because both acceptance assertions fail; its clean REQUESTED and visible later-COMMIT controls pass. The reviewed runtime diff and review artifact diff pass `git diff --check`. The final `run_validation.py --changed --json` passes both selected artifact checks (`review_pairing_contract`, `visual_review_handoff`) with complete coverage; the direct review-pairing check also passes (50 correctly paired packets).

Known Godot exit resource/ObjectDB warnings and procedural compound placement warnings appear in registered results; they do not fail those checks. Moment Forge: not run — the findings and correction contract concern machine-checkable state/visibility identities; no rendered capture or subjective baseline is required. The previously recorded WAIVE-TO-PLAYTEST visual disposition is reused.

## Durable executable reproduction

Save this block to `/tmp/frontier-correction-review-probe.gd` and run `godot --headless --path custodian --script /tmp/frontier-correction-review-probe.gd` from a freshly imported review checkout. It extends the landed AR4 smoke and modifies no reviewed file.

```gdscript
extends "res://tools/validation/procgen_archive_resolve_frontier_restraint_smoke.gd"

func _run() -> void:
	_test_ingress_pocket_occlusion()
	if not _errors.is_empty():
		for e in _errors:
			push_error(e)
		quit(1)
		return
	print("[CorrectionReviewProbe] existing and COMMIT-time regressions PASS")
	var target := OP + Vector2i(2, 1)
	var chunk := Vector2i(int(floor(float(target.x) / CHUNK)), int(floor(float(target.y) / CHUNK)))
	var o := _make()
	_walls.clear()
	o.begin_ingress_resolve(OP, [], CHUNK)
	_commit(o, [target])
	o.note_chunk_unloaded(chunk, CHUNK)
	o.note_tiles_requested(chunk, [target], true)
	print("[CorrectionReviewProbe] reacquired requested before advance: state=%d veil=%s" % [o.get_tile_state(target), o.has_veil(target)])
	o.advance(0.016, OP, CHUNK)
	print("[CorrectionReviewProbe] reacquired requested after advance: state=%d veil=%s" % [o.get_tile_state(target), o.has_veil(target)])
	_check(o.has_veil(target), "R1-02 pending pocket COMMIT exposed reacquired REQUESTED tile before COMMIT")
	o.queue_free()
	var control := _make()
	_walls.clear()
	control.begin_ingress_resolve(OP, [], CHUNK)
	control.note_tiles_requested(chunk, [target], false)
	control.advance(0.016, OP, CHUNK)
	_check(control.has_veil(target), "negative control exposed REQUESTED tile without pending COMMIT")
	print("[CorrectionReviewProbe] clean REQUESTED negative control: state=%d veil=%s" % [control.get_tile_state(target), control.has_veil(target)])
	control.queue_free()
	var visible := _make()
	_walls.clear()
	visible.begin_ingress_resolve(OP, [], CHUNK)
	_commit(visible, [target])
	visible.advance(0.016, OP, CHUNK)
	_check(not visible.has_veil(target), "visible later pocket COMMIT did not settle on next update")
	print("[CorrectionReviewProbe] visible later COMMIT: state=%d veil=%s" % [visible.get_tile_state(target), visible.has_veil(target)])
	visible.queue_free()
	var unknown := _make()
	_walls.clear()
	_walls[OP + Vector2i(1, 1)] = true
	unknown.begin_ingress_resolve(OP, [], CHUNK)
	_commit(unknown, [target])
	_run_for(unknown, 0.6, 0.016, NO_OPERATOR)
	print("[CorrectionReviewProbe] hidden pocket with unknown visibility: state=%d veil=%s center=%s" % [unknown.get_tile_state(target), unknown.has_veil(target), unknown.get_frontier().has_center()])
	_check(unknown.has_veil(target), "R1-03 hidden pocket COMMIT settled while visibility center was unknown")
	unknown.queue_free()
	for e in _errors:
		push_error(e)
	quit(0 if _errors.is_empty() else 1)
```

Observed trace (the two errors are expected defect proofs):

```text
Godot Engine v4.7.2.stable.arch_linux.ed1daf0bf (2026-08-17 01:18:38 UTC) - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[CorrectionReviewProbe] existing and COMMIT-time regressions PASS
[CorrectionReviewProbe] reacquired requested before advance: state=1 veil=true
[CorrectionReviewProbe] reacquired requested after advance: state=0 veil=false
[CorrectionReviewProbe] clean REQUESTED negative control: state=1 veil=true
[CorrectionReviewProbe] visible later COMMIT: state=0 veil=false
[CorrectionReviewProbe] hidden pocket with unknown visibility: state=0 veil=false center=false
ERROR: R1-02 pending pocket COMMIT exposed reacquired REQUESTED tile before COMMIT
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _run (/tmp/frontier-correction-review-probe.gd:50)
ERROR: R1-03 hidden pocket COMMIT settled while visibility center was unknown
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _run (/tmp/frontier-correction-review-probe.gd:50)
```

## Review Closeout

The archived correction 1 packet has an Independent Review receipt with two blocking defects and zero material evidence gaps. This review packet is complete and archived with findings. Correction `procgen-archive-resolve-frontier-restraint-review-corrections-2` and its paired fresh-context review are ready/auto with dependency ordering. This is the final permitted automatic correction cycle; its review must return to user/ChatGPT if blocking findings remain rather than creating correction 3.

## Recovery State

- Finish outcome: `blocked before push/landing`; reviewed runtime and target identity remain untouched.
- Workstream: `review-procgen-archive-resolve-frontier-restraint-review-corrections-1`
- Recovery branch: `agent/review-procgen-archive-resolve-frontier-restraint-review-corrections-1`
- Worktree: `/home/braydenchaffee/Projects/.custodian-worktrees/review-procgen-archive-resolve-frontier-restraint-review-corrections-1-20261007T105637Z-eff7df9071ba`
- Green artifact validation report: `/tmp/frontier-correction-review-closeout.json`
- Finish/checkpoint run: `20261007T105637Z-eff7df9071ba`
- Trace ref: `refs/heads/agent-diagnostics/review-procgen-archive-resolve-frontier-restraint-review-corrections-1/20261007T105637Z-eff7df9071ba`
- Next correction: canonical `procgen-archive-resolve-frontier-restraint-review-corrections-2`, locally ready/auto and dependency-gated until this review lands. Preserve the branch/worktree for recovery; do not change packet target identity or substitute misleading nested filenames.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: The registered smoke omits pending-commit identity reuse and unavailable-center ingress admission; both fresh owner probes fail. One attempted multi-test command selected only its final --test argument. workstream.py paired-review artifact gate permits correction names derived from the reviewed correction-1 target, while the authoritative review packet requires the canonical original-lineage correction-2 name. Finish rejects PROCGEN_ARCHIVE_RESOLVE_FRONTIER_RESTRAINT_REVIEW_CORRECTIONS_2.md as unauthorized before push/landing. Fix the lifecycle naming rule in a separately authorized pipeline workstream; preserve this review branch/worktree for recovery.
- Root cause / contributing factors: Pending entries are not invalidated by release and accept REQUESTED records; the ordinary ungated fallback defeats ingress's absent-center guard. The runner accepts one --test filter rather than an accumulating list. The finish artifact whitelist uses the current reviewed correction ID as its prefix instead of the canonical parent lineage, contradicting the packet's explicit second-cycle successor.
- Prevention / pipeline improvement: Add the two bounded lifecycle/unknown-center regressions with negative controls in correction 2; run one explicit --test command per required test and inspect each selected list.
- Tooling / docs drift discovered: The ephemeral worktree's graph is empty, so graph-first discovery required targeted source fallback. This review packet inherited the original AR4 main SHA instead of the correction target; its own Reviewed main metadata is now the actual claimed main. `check_ai_context.py --json` reports the same 15 out-of-scope grammar/index findings recorded by correction 1; no new finding points to this review or its successor packets. No unrelated metadata was changed.
- Follow-up: `procgen-archive-resolve-frontier-restraint-review-corrections-2`
- Pipeline follow-up: `manual-follow-up` — correction-lineage normalization in paired_review_artifact_scope_error; the bounded review override does not authorize editing lifecycle tooling.
- What worked: The fresh owner probe separated valid R1-01 behavior from missing edge coverage without modifying reviewed implementation.

## Next Handoff

- Next workstream: `procgen-archive-resolve-frontier-restraint-review-corrections-2`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73
- Refresh reason: `none`
- Next action: Resolve the mechanical finish artifact-gate mismatch in a separately authorized pipeline workstream, resume/finish this preserved review branch, then claim canonical correction 2 and its paired fresh-context review. Cycle 2 is the final allowed automatic correction cycle.
- Blockers or open questions: workstream.py paired-review artifact gate permits correction names derived from the reviewed correction-1 target, while the authoritative review packet requires the canonical original-lineage correction-2 name. Finish rejects PROCGEN_ARCHIVE_RESOLVE_FRONTIER_RESTRAINT_REVIEW_CORRECTIONS_2.md as unauthorized before push/landing. Fix the lifecycle naming rule in a separately authorized pipeline workstream; preserve this review branch/worktree for recovery. R1-02 and R1-03 remain the implementation acceptance blockers; no design/art decision is missing.
