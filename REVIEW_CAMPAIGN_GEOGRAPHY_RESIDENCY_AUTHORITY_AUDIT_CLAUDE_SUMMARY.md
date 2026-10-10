# F15-A Geography and Residency Authority Paired Review

## Result

Review **passed** with no blocking defects or material evidence gaps. The review reconstructed the F15-A evidence report and acceptance contract from the archived implementation packet, report source, current runtime, and focused validation. The implementation is `18e7e88ac91d5c70445121038984a4e15830d820`; current `origin/main` reviewed was `1da9c970f27ff37298abb190ce8d3075d4837f0b`. Reviewer context was fresh; provenance is `different-agent`.

The report distinguishes confirmed runtime contracts, measured local-map evidence, inferred architecture, and unproved capabilities. It correctly states that there is no durable production Domain+Location address; route/level scene residency and M6 visual chunk eviction have separate owners; F14 anchors are synthetic; no continuous two-site route was demonstrated; and ambient duplication is a source-inspected race, not an in-game reproduction. The Ritualant ingress failure and its scope limitation are explicit. The provisional graph-backed locality recommendation does not lock world extent or authorize F15-B/C2 implementation.

## Independent validation

- Godot `4.7.2.stable.arch_linux.ed1daf0bf` editor import completed in the resumed current-main worktree.
- `procgen_distant_chunk_unload_smoke.gd`: exit 0, printed `PASS`. Two resource lifetime warnings remain at exit; no parse errors occurred after full import.
- `generated_region_route_lifecycle_smoke.gd`: first post-import attempt exited 0 before printing a result and was treated as incomplete. A retry exited 0 and printed `PASS`. Its `MissingSpawn` and invalid `ProcGen owner` errors are deliberate negative controls; both rollbacks completed and the test passed.
- `task_packet_index.py`: PASS.
- `validate_review_pairing.py`: PASS, 62 auto review packets correctly paired.
- `check_ai_context.py`: PASS.
- `git diff --check`: PASS.

The initial M6 inferred-type cascade reproduced before full Godot editor import, alongside missing imported resources/global script classes. After explicit editor initialization, the same current-main smoke passed. The separate two-snapshot recovery probe had exhausted `/tmp` during its second imported checkout; that partial attempt is not used as a product failure or pass. Its logs remain at `/tmp/custodian-f15a-validation.XvBZV0oY`; current-main M6 and route logs are `/tmp/f15a-current-m6.log` and `/tmp/f15a-current-route-retry.log`.

No implementation or evidence-report files were edited. No finding or correction packet is warranted. The ambient-spawn ingress issue remains with its existing procgen/level owner. Unrelated Awakening tooling remains outside this review.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: high
- What went wrong: The first focused M6 invocation ran before Godot had populated the worktree's global-class/import cache; a duplicate two-snapshot probe exhausted temporary storage; the first post-import route invocation ended before a verdict line.
- Root cause / contributing factors: Import preflight did not initialize all assets/global classes in this fresh checkout; two independent full Godot caches consumed about 12.6 GB under `/tmp`; one route fixture run did not complete its own PASS receipt.
- Prevention / pipeline improvement: Initialize the actual Godot editor import cache in the review worktree before diagnosing parser cascades; run one imported snapshot at a time when `/tmp` is constrained; require the smoke's PASS line as well as exit code.
- Tooling / docs drift discovered: `godot_import_preflight.py` PASS did not establish that all script classes and imported resources were ready for direct smoke execution in this fresh worktree.
- Follow-up: manual-follow-up
- What worked: Explicit editor import followed by serial focused smokes separated cache initialization from product behavior; current-main queue validators also passed.

## Next Handoff
- Next workstream: none
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: Decide the production geographic address/topology owner, finite or expandable extent, continuous scene seam, minimum locality proof, and actor/spawn residency boundaries before F15-B/C2.
- Next action: Return the accepted F15-A evidence and unresolved design decisions to the authoring conversation; do not start F15-B/C2 from this review.
- Blockers or open questions: No review blocker. Human-owned geography decisions remain open.
