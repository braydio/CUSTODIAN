<!-- V2 turn metadata -->
Task identity: turn-scoped-dispatcher-v2
Task definition: owner-authorized:https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0#sha256=b5d66450ca5bf05f6618ee0831066494d078846aa9fd1456f794972149664e6c at origin/main de9fb72d8f4f2c239c551d87797351c9093e21b8
Remote branch: agent/turn-scoped-dispatcher-v2
Acquisition mode: owner-authorized
Acquisition source: agent/turn-scoped-dispatcher-v2
Acquisition source commit: 7ba2ac64dafa90b5897cd6f83555665745ed49f7
Checkpoint base: 7ba2ac64dafa90b5897cd6f83555665745ed49f7
<!-- /V2 turn metadata -->

# Dispatcher V2 Stage 3A handoff

Workstream: `turn-scoped-dispatcher-v2`
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
Implementation branch: `agent/turn-scoped-dispatcher-v2`
Stage 3A starting SHA: `7ba2ac64dafa90b5897cd6f83555665745ed49f7`
Reviewed main used for the normal pilot: `52e09813cd0993fe0c8c03065938e21115f782f3`
D2-004 instruction SHA-256: `b5d66450ca5bf05f6618ee0831066494d078846aa9fd1456f794972149664e6c`

Original goal: Build an opt-in, turn-scoped task lifecycle with authenticated task definitions, safe normal and historical acquisition, durable checkpoint handoffs, and conservative checkout retirement; prepare integration without prematurely replacing production authority.

Implemented: Stage 1 and Stage 2 remain intact. Stage 3A adds three explicit definition cases: published packets authenticated from fetched `origin/main`; owner-authorized new identities carrying an exact ChatGPT conversation URL and instruction digest in a private receipt (explicitly not identity-verified); and historical work that reuses a verified branch while recording ancestry in both directions against current main. A packet published after owner-authorized acquisition forces re-acquisition before checkpoint. Retirement receipts make a successfully verified exact checkout retirement idempotent, provided the advertised remote SHA still matches. Added behavior-difference and production-consumer migration maps. No production entrypoint, task queue, service, sync timer, or private archive was changed.

Remaining: Stage 3A does not perform cutover. The host-private historical archive snapshot still could not be verified after a path disappeared during inventory follow-up; its external evidence coverage remains unenumerated. Do not restore from, modify, or retire data based on that archive. Before any archive-backed retirement, obtain a stable complete snapshot and verify a representative restore. Before production cutover, complete the separately reviewed consumer migration, review/correct the exact cutover diff in a fresh context, verify rollback, and complete all required operational validation. The old dispatcher remains the documented production authority.

Validation: `python3 -m unittest custodian.tools.agent.test_turn_dispatcher_v2 custodian.tools.agent.test_turn_archive_v1 -v` (35 tests passed). The tests cover authenticated packet selection independent of legacy status/locks/dependencies, ambiguous identities, design holds, owner authorization provenance and packet publication race, historical branch reuse/divergence/fallback, LFS failures, remote race preservation, ignored unique data, archive verification/restore failures, and retirement retry after an injected crash immediately following exact checkout removal. Python compilation, Windows-compatible filename validation, and `git diff --check` passed. Normal-mode isolated pilot seeded packet bytes from `origin/main@52e09813cd0993fe0c8c03065938e21115f782f3`, synthetic main `fde811594a3a7cf1e0c14c2d9820fa37d66d887f`, and verified checkpoint/resume SHA `5f601c6f419e54362b70a33dd370972c8168e9e2`; idempotent retirement also passed. No real feature branch was touched.

Sources/evidence: `design/04_architecture/TURN_SCOPED_DISPATCHER_V2_STAGE3A.md`; focused Git/LFS and archive fixtures; isolated synthetic packet pilot; exact D2-004 instruction SHA above. Prior Stage 2 private archive manifest digest `a7d8bdcd2807321af2a00cf27114ed0e3161f32f6e59a9a41a46692f65be5f54` remains unverified and is not used as a restore source. The root coordination checkout has unrelated dirty files and remains unsynchronized; no root files were changed.

Resume: Fetch `agent/turn-scoped-dispatcher-v2`, verify the latest advertised SHA, read this handoff and the Stage 3A readiness map, then continue only with the next orchestration-chat instruction. Do not activate any production entrypoint or alter the private archive without a separately authorized, reviewed scope.
