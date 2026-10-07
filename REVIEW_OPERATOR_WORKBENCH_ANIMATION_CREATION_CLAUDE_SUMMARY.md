# Review: Operator Workbench Animation Creation

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

## Findings

### R0-01 — New animation cannot publish through the shared UI/CLI service

- Class: `blocking_defect`
- Domain: `implementation`
- Priority: `P1`
- Affected acceptance: OPUI publication of a previously absent full-body animation; modular CREATE publication; UI and CLI share the guarded specialized publisher; guarded art-checkout commit/landing and post-publish browser refresh.
- Evidence: `custodian/tools/operator/ui/service.py:888` reads `identity` in the creation validation branch before assignment. Python treats it as a function-local variable because the later adopted-FX branch assigns it at line 914. Schema-valid bindings reach the generator expression and raise `NameError: cannot access free variable 'identity' where it is not associated with a value in enclosing scope`. `WorkbenchService.publish` invokes this guard at line 793 before readiness and `publish_to_main`; CLI real publication uses this same service at `operator_cli.py:105`.
- Fresh reproduction: Created both `full_body` and `modular_body` six-frame 96x96 disposable Aseprite sessions through the live creation backend, saved known RGBA pixels with Aseprite, then invoked real `WorkbenchService.publish(selection, prepare=True)`. Both raised the above NameError. Manifest/document SHA256 values and canonical source tree were unchanged. No production pixels or implementation files were changed.
- Disposition: `correction`
- Rationale: This prevents the central user-visible publication outcome for every valid new creation. Passing lower-level transaction fixtures cannot establish this path.
- Follow-up: `operator-workbench-animation-creation-review-corrections-1` and its paired cycle-1 review.

## Review Scope And Provenance

- Verdict: `findings`; one blocking defect, zero separately classified material evidence gaps, non-blocking issues, or optional improvements.
- Review cycle: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Implementation commit: `3e4a4df336ed963c096018319cc9208b33b39573`
- Reviewed checkout on main: `180bcec63`
- The original packet's `Reviewed main: 0a4bd5ec35` predates implementation. This review used the actual landed implementation diff and surviving live source, rather than treating that stale field as the target.
- Authority reconstructed from root/local AGENTS, archived implementation and active review packets, implementation summary, Workbench design, Art Agent creation contract, Asset Pipeline V2 delegation, current-state/index/validation guidance, review prompt, and lifecycle docs.
- Graph-first tools were attempted. The worktree graph has no indexed nodes (semantic query reports an empty graph); structural review therefore used targeted source/diff reads. The initial graph risk score cannot establish coverage.

## Evidence And Limits

Fresh focused validation passed:

- `operator_animation_workbench_smoke.py`: full-body known-pixel saved preview, lower-level successful CREATE source/runtime RGBA equality, timing sidecar, manifest normalization, collision refusal, injected post-CREATE rollback journal (`ROLLED_BACK`, primary failure retained, no recovery failure), document/resource preimage retention, modular synchronized saved exports, and existing migration compatibility.
- `operator_workbench_ui_smoke.py`: service projections and reachability discovery; Textual interactive pilot skipped because the optional package is absent.
- `operator_workbench_mirror_publish_smoke.py`: inherited FX CREATE/REPLACE, explicit mirror, collision, import metadata restoration and rollback fixtures.
- `operator_art_worktree_smoke.py`: isolated art-checkout lifecycle and fixture landing, including bounded remote-main race/retry behavior.
- Fresh real service publication falsification: R0-01 reproduced for both body templates. Tests above remain green despite this defect because the new creation smoke calls `animation_workbench.publish` directly and stubs the downstream pipeline; the UI fixture does not publish creation sessions through the real service.

Source inspection confirms schema-derived paths and blank/nonpublishing reference assembly, creation state labels, default-OFF mirror choice, saved Workbench preview support, a single lower-level transaction with exclusive CREATE, strict runtime sync/import/resource rebuild and rollback, source-backed normalization, post-PUBLISH browser reload, DORMANT fallback, and preservation of the external-art intake boundary. These mechanisms do not remedy the unreachable service publication path.

The implementation summary's import-preflight, SpriteFrames (588 imports), modular smoke, strict animation report (63 expected, 60 present, no required missing), and 22-check closeout results were reused as historical claims; they were not repeated or promoted into proof of new UI/CLI CREATE publication. Modular creation smoke proves authoring/export, not a real modular publication/landing. Correction validation must exercise both templates through the production service boundary and retain negative schema/collision checks. No renderer capture or aesthetic decision is needed for this confirmed tooling defect.

Review artifact checks: review-pairing contract passed (50 correctly paired packets); scoped packet/index lifecycle verified. The index generator also rewrote two unrelated Savage entries; those edits were deliberately reverted to preserve review scope.

Moment Forge: not run — review concerns authoring/publisher tooling and has no runtime timing or presentation change.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Creation publication acceptance was reported green while the shared UI/CLI service path always raises NameError; the packet's Reviewed main predates the implementation.
- Root cause / contributing factors: Creation fixtures exercise lower-level publication with downstream stages stubbed; UI smoke never exercises creation publication and its optional Textual pilot is skipped. The inherited Reviewed main field was not refreshed at implementation closeout.
- Prevention / pipeline improvement: The bounded correction requires real-model/real-workbench service publication fixtures for both templates, plus immutable live-target references in correction/re-review metadata.
- Tooling / docs drift discovered: Reviewed main 0a4bd5ec35 is an October 3 task-index change; actual implementation is 3e4a4df336ed963c096018319cc9208b33b39573 on the reviewed checkout 180bcec63.
- Follow-up: operator-workbench-animation-creation-review-corrections-1
- What worked: Fresh saved-Aseprite fixtures reproduced the defect for both templates and proved failure preserves document and manifest hashes.

## Next Handoff

- Next workstream: operator-workbench-animation-creation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Claim the bounded R0-01 correction, then its paired cycle-1 re-review. Resume downstream cockpit/UX planning only after correction review passes.
- Blockers or open questions: New-animation UI/CLI publication is blocked by R0-01; optional interactive Textual pilot remains unrun.
