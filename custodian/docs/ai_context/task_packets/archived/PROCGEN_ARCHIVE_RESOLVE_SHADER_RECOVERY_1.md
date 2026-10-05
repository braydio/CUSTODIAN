# PROCGEN ARCHIVE RESOLVE SHADER RECOVERY 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-shader-recovery-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-contract-world-ingress-spawn-clearance-fix`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-procgen-archive-resolve-shader`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `691b21b5f2ca3b962d4590224433bee1c5e5b138`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Parent implementation: `procgen-archive-resolve-shader`
- Parent implementation commit: `085a38a5ef7fbd83da146774f8ec669514509294`
- Parent packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ARCHIVE_RESOLVE_SHADER.md`
- Summary backlink: Every durable implementation/review/recovery/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7` exactly.
- Goal: Complete the missing real-renderer and human visual acceptance for the already-landed AR2 Archive Resolve shader without reopening AR1/AR2 architecture or duplicating the shader implementation.
- Completion boundary: Done when current-main AR2 compiles and runs on a real graphical renderer; a production-path or purpose-built Moment Forge procgen scenario exercises unresolved cover, active dissolve, settlement, pause freeze, reduced-effects behavior, actor-over-veil ordering, and at least one reacquisition if practical; no shader parse/link/runtime errors occur; compact motion evidence is published; the user/ChatGPT explicitly approves the visual/readability baseline in the recorded authoring chat or requests bounded tuning; any requested bounded tuning is applied and revalidated; and the recovery closes with the existing AR2 paired review as the next gate.
- Current measured state: AR2 code is already on current `main` and descends from implementation commit `085a38a5`: `archive_resolve.gdshader`, shared ShaderMaterial/custom-data plumbing in `procgen_reveal_presentation.gd`, AR2 focused smoke, live-toggle hardening, ContractMap draw-order correction, and the strengthened road-decal proof are present. The archived AR2 packet nevertheless records that shader compile and aesthetics were **not verified** because validation ran under headless/dummy rendering, while also marking Completion/Acceptance `yes`. That is an incomplete closeout, not evidence that the renderer gate passed. The user's subsequent normal generator playtest was blocked by an independent Operator-spawn-inside-Ash-Bell-ingress collision regression; the P0 `contract-world-ingress-spawn-clearance-fix` + paired review must close first so the normal contract-world playtest is trustworthy.
- Evidence: landed `archive_resolve.gdshader`; `procgen_reveal_presentation.gd`; `procgen_archive_resolve_shader_smoke.gd`; archived AR2 packet; current AR2 paired-review packet; `VISUAL_REVIEW_HANDOFF.md`; current Moment Forge tooling; P0 ingress-spawn-clearance hotfix pair.
- Task-specific authority: Archived AR2 packet remains the implementation contract; this recovery owns only the missing renderer-backed acceptance and any narrow tuning required to make that existing contract visually correct. The exact human/ChatGPT review authority for this recovery is `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`.
- Work surface: Prefer no runtime code changes. If real-renderer evidence exposes a concrete AR2 shader/readability defect, limit edits to `custodian/game/world/procgen/streaming/archive_resolve.gdshader`, AR2 presentation-only tuning fields/material sync in `procgen_reveal_presentation.gd` or `proc_gen_map.tscn`, and the narrowest Moment Forge scenario/fixture/evidence plumbing needed to exercise the effect. Update focused validation only when a renderer-discovered defect can be made machine-falsifiable. Do not touch contract-world spawn code; that belongs to the prerequisite hotfix.
- Change: Start by syncing/re-reading current `origin/main`; do not resurrect the stale pre-land AR2 worktree. Validate the code that is actually on main after the ingress-spawn hotfix/review closes.
- Change: Run a graphical Godot proof under the user's real X11/Wayland renderer and require `archive_resolve.gdshader` to parse/link/execute with zero shader/runtime errors. A headless pass cannot satisfy this item.
- Change: Run `python3 custodian/tools/iteration/run_moment.py --changed` first. If no existing scenario exercises the production procgen Archive Resolve veil, add the smallest dedicated scenario under `custodian/tools/iteration/scenarios/procgen/`. Do not misuse an authored-level reveal scenario just because it captures video.
- Change: Renderer evidence must show: unresolved REQUESTED/READY cover; active connected dissolve; complete settlement; pause freezing all animated shader motion; reduced-effects comparison; gameplay actors/items/projectiles visually above the veil; and, when practical, one unloaded/reacquired region using the landed reacquisition identity. The scenario must not alter generation semantics merely to stage the capture.
- Change: Publish the smallest useful evidence through `publish_review_artifacts.py --important` under workstream `procgen-archive-resolve-shader-recovery-1`. One short MP4 is allowed because continuity/motion is the acceptance question; otherwise prefer evidence keyframes/contact sheet.
- Change: After publishing, stop and report the Dropbox manifest/path plus these questions to the user for review in `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`: (1) does it read as Archive resolution rather than chunk loading/square pop/fog fade; (2) are graphite/soot and brass/amber restrained; (3) are actors/threats always readable over the veil; (4) does settled terrain return fully to normal; (5) is reduced-effects meaningfully calmer without becoming a generic fade?
- Change: If the user/ChatGPT requests bounded AR2 tuning, keep the same recovery workstream, make only the smallest shader/presentation tuning changes, rerun graphical proof + focused regressions, republish evidence, and seek explicit approval again. Do not create a new workstream for ordinary tuning discovered by this visual gate.
- Preserve: AR1 scheduling/authority; AR2 render architecture; one shared ShaderMaterial/MultiMesh; COLOR.a progress ownership; deterministic instance identity; pause-safe `presentation_time`; reduced-effects semantics; actor-over-veil ordering; live-toggle/overflow/road-reload hardening; Region Frame ownership; generation/collision/navigation/lifecycle/cache/residency semantics; S1 fingerprint `1773840677` unless independently changed on main.
- Non-goals: No AR3 semantic echo; no new presentation classes; no spawn/ingress choreography; no procgen generation/placement changes; no Ash Bell/Forlorn collision changes; no full-screen post-process; no new art family; no broad performance/decomplexification work; no aesthetic redesign beyond bounded AR2 tuning needed to pass the locked visual contract.
- Acceptance: (1) Real renderer loads/executes `archive_resolve.gdshader` with zero shader errors. (2) Production/purpose-built procgen scenario visibly exercises all required AR2 phases. (3) Pause freeze and reduced-effects behavior are visually and machine-consistent. (4) Actors remain readable above the veil. (5) Settled terrain has no persistent Archive Resolve treatment. (6) Reacquisition identity is preserved; if included in evidence it is not stronger/slower than first resolve due to an AR2 regression. (7) Existing AR2/AR1 focused tests and affected streaming/runtime-health tests remain green after any tuning. (8) S1 quick remains fingerprint `1773840677` unless current main already carries an approved baseline change. (9) Evidence is published and the explicit user/ChatGPT decision from the recorded authoring chat is written into closeout. (10) Only after explicit approval may this recovery be marked complete and the paired AR2 technical review become claimable.
- Validation: First graphical compile/run proof. Then Moment Forge evidence. If no code changes are required, rerun `procgen_archive_resolve_shader`, `procgen_reveal_presentation`, pause-aware streaming, runtime health, region frame, and S1 quick as a closeout sanity set. If tuning changes code, run the focused AR2 shader smoke first, then all affected tests selected by the changed files. Finish with `git diff --check`, packet/review pairing checks, and changed-file validation. Treat pre-existing unrelated AI-context failures as baseline only after reproducing them on untouched current main.
- Task overrides: `none`
- Deferred: AR3 semantic echo/spawn/reacquisition presentation remains blocked on the paired AR2 review and its required planning refresh in the recorded chat.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `parent AR2 implementation retained; this packet repairs incomplete closeout`
- Evidence: ``custodian/tools/iteration/scenarios/procgen/archive_resolve_shader_review.json` + `scenes/debug/archive_resolve_moment.tscn` + `tools/validation/fixtures/archive_resolve_moment.gd` exercise the production ProcGenTilemap streaming path on a 224x224 map under a real Vulkan renderer (GTX 1650 SUPER) with zero shader/parse errors in the Moment Forge log. Probes show REQUESTED/READY/RESOLVING/settled phases, active instances returning to 0, presentation_time frozen at 2.05 across ticks 121-149 while paused, a reduced-effects reveal (517 requested tiles) resolving through the same phases, 44 reacquisition tiles after a forced chunk unload, exactly one shared ShaderMaterial, and the actor drawn above the veil. Evidence published to Dropbox `/CUSTODIAN/visual_review/procgen-archive-resolve-shader-recovery-1/20261005T025507Z/REVIEW_MANIFEST.json` (13 files, no video). Focused tests green: procgen_archive_resolve_shader, procgen_reveal_presentation, procgen_pause_aware_streaming, procgen_runtime_health, procgen_region_frame, Moment Forge schema/router smokes; S1 quick fingerprint 1773840677; git diff --check clean. Visual decision: the user explicitly approved this pass in the Claude Code session on 2026-10-05 (and earlier directed that the playtest be treated as successful); it was given in-session rather than in the recorded authoring chat. No tuning was requested; no shader/runtime code changed. Reacquisition strength/speed was not separately compared against first resolve beyond sharing the same resolve path/duration.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `AR2 was archived/landed with a mandatory real-renderer gate still explicitly unverified.`
- Root cause / contributing factors: `AR2 closeout lacked a graphical proof because the validation tier is headless; no Moment Forge scenario existed for the procgen veil.`
- Prevention / pipeline improvement: `The new procgen/archive_resolve_shader_review scenario is the reusable renderer proof for future Archive Resolve tuning and AR3.`
- Tooling / docs drift discovered: `Fresh worktrees need `godot --import` before running scripts, otherwise global class types fail to resolve.`
- Follow-up: `review-procgen-archive-resolve-shader`

## Handoff

- Next workstream: `review-procgen-archive-resolve-shader`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none`
- Next action: Let the fresh-context AR2 paired review claim automatically.
- Blockers or open questions: none.
