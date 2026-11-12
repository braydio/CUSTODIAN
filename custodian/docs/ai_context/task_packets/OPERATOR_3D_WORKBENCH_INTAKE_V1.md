# OPERATOR 3D WORKBENCH INTAKE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-3d-workbench-intake-v1`
- Category: `tools-ux`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-3d-workbench-intake, operator-art-3d-preview`
- Kind: `implementation`
- Review: `none`
- Paired review workstream: `none`
- Review rationale: Candidate-only authoring tooling and ignored staging, with no gameplay, production art, canonical or publication-authority edits. Source hashes, transactional rollback, UI behavior and existing Workbench regression tests provide direct acceptance evidence; the owner explicitly requests no separate review workstream.
- Reviewed main: `0268a56c8f578779199cbdc39c98c9a12574b19b`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeeaefc-af8c-83ea-925f-091a0130a3fb
- Visual review: `none`
- Goal: Make the existing Operator Workbench play verified eight-direction 3D-derived Walking and Running through a guarded, repeatable candidate-only intake.
- Completion boundary: In a dispatcher-owned isolated checkout, integrate and reconcile the existing committed intake implementation with live main, validate exact host assets and the real persistent-art-checkout `operator ui`, land via canonical lifecycle, record truthful completion and retire the temporary checkout. No review or recovery packet.
- Current measured state: Preserved remote `agent/operator-3d-workbench-intake-v1` at `fde2793850f463aad97184a513a53110ac5880dd` includes the implementation and corrections; it has not landed and diverges from reviewed main. Claude reported 16 directional sessions, 320 frames, 55 intake/stager tests and passing Textual/Workbench smokes. Real interactive `operator ui` from the persistent art checkout was not run. These are prior host claims, not newly independently verified results.
- Evidence: `2efb97a821b14c14646489888f6b45ae63850cb7`; `fde2793850f463aad97184a513a53110ac5880dd`; retained Dropbox review evidence `/CUSTODIAN/visual_review/operator-3d-workbench-intake-v1/20261111T175018Z/`; source master SHA-256 `3004e9b5014450708bab80897a83ae676d27704321d2bc4cacdaf9ef1881c127`.
- Task-specific authority: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; existing Operator render/presenter authority and specialized Asset V2 candidate rules.
- Work surface: Existing Workbench service, app, browser/state, animation preview, candidate reader and sparse checkout in `custodian/tools/operator/`; contract/validator/stager in `custodian/tools/character3d/`; focused tests under `custodian/tools/validation/`; narrow Workbench documentation and test-ownership index. No source game scenes or canonical sprites.
- Publication inputs: `custodian/tools/operator/ui/service.py`; `custodian/tools/operator/ui/app.py`; `custodian/tools/operator/animation_preview.py`; `custodian/tools/operator/operator_art_worktree.py`; `custodian/tools/validation/operator_workbench_ui_smoke.py`; `custodian/tools/validation/operator_art_worktree_smoke.py`; `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
- Change: Fetch main, authenticate this workstream via dispatcher/workstream, keep the coordination root on main, and inspect the remote preserved source span. Port only the specific intake/character3d code already developed into the canonical claimed checkout, reconcile its current-main conflicts narrowly (notably the validation manifest and FILE_INDEX), and preserve unrelated main changes; source remote branch is historical implementation evidence, not a claimed main dependency or authorization to merge stale whole history. If the canonical agent branch already exists or is attached to a manual worktree, follow supported continuation/ownership checks; never force-create, reset or overwrite it, or fabricate claims. No extra recovery task: resolve safe local Git integration within this packet. Preserve candidate generation `operator_3d_80` independent of the 96px and 128px target planners.
- Preserve: 25×8 Walking and 15×8 Running, 160×160 RGBA at 80 px/m; action pivots Walk (50,107), Run (62,108); all eight individually rendered directions; no mirroring/recentering or pixel modifications. Preserve explicit source/motion/action/frame SHA bindings while unrelated contract additions remain valid; full-contract/manifest SHA stays audit provenance. Maintain transactional stager/apply, zero-write repeat apply, failed-apply rollback, verification receipts and distinct VERIFIED/REGISTERED/INVALID/MISSING browser statuses. Candidate preview single-source only; reject edit, migration, compare, transition, FX adoption and publish at both UI and backend boundaries.
- Non-goals: No Relaxed Idle or new animations, no gameplay or Godot runtime selector changes, no production sprite migration, no self-approval of Asset V2 art, no alternate Workbench and no unrelated worktree cleanup.
- Acceptance: Authenticated isolated checkout integrates the preserved implementation on up-to-date main. Host verifies the real source/model hashes and stages 320 frames; `--plan`, `--apply`, repeated `--apply` (0 writes) and `--verify` all pass. Every one of 16 candidate directions plays genuine pixels in `operator ui` from the actual persistent art checkout, with stable action pivots, active playback, accurate labels and no legacy fallback. Negative tests reject malformed frames, path escape, altered hashes, dropped directions and interrupted promotion. Legacy and 128px paths continue to work, publication remains disabled, and no `custodian/game/` or production art diff appears. Host-private frames live outside tracked Git: revalidate the existing Operator probe and regenerate them before claiming full acceptance, rather than mislabeling fixture evidence as live.
- Validation: Existing `custodian/tools/validation/operator_workbench_ui_smoke.py` and `custodian/tools/validation/operator_art_worktree_smoke.py`; integrate the previously authored `test_operator_3d_candidate_intake.py` fixture suite, character3d source-contract tests, actual Textual examiner-key pilot, all 16 real-frame previews, exact frame/source hashes, failure injection, touched-file checks and validation-manifest owner registration. New test files are outputs, not current publication inputs. Produce a compact machine-readable acceptance receipt.
- Task overrides: `none`
- Deferred: Authoring Relaxed Idle, production 3D cutover, weapon animation and VFX binding are separate work. No prior independent review outcome is changed.

## Execution and handoff

Use `dispatch.py claim operator-3d-workbench-intake-v1 --agent <agent-id>` or the supported same-workstream resume after fetching main and checking current owner. Never change the coordination-root branch. The old remote branch and ignored proof stay preserved until a canonical checkout contains a verified implementation and the exact regeneration route. Follow the V2 completion-truth/summary/archive/retirement lifecycle, with an explicit `Authoring chat:` backlink in the closing summary. This packet requests no independent review, no paired review and no recovery packet.

- Next workstream: `character3d-vfx-pipeline-v1`
- Next packet state: dependency-gated until this packet is complete
- Next action: After landing, dispatch the dependent VFX workstream to correct the foot-registration failure.
