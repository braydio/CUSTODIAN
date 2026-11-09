# Dispatcher V2 Stage 1 handoff

Workstream: `turn-scoped-dispatcher-v2`
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
Implementation branch: `agent/turn-scoped-dispatcher-v2`
Branch base: `900ce8b427d422eaa31597fda6f4b266b75f6f70`
Reviewed main: `841931733cd0103e5dbeb5587063d3b880e50db7`

Original goal: Build the first operational stage of the two-mode, turn-scoped CUSTODIAN dispatcher, correcting the approved plan's old-dispatcher selection gates.

Implemented: V2 readiness authenticates a unique task definition from fetched `origin/main`; ignores old status, dependency, claim and lock gates; holds only on explicit unresolved user-design metadata; creates non-forcing normal/recovery branches; supports fresh normal and historical starts; hydrates and verifies Git LFS; records durable task/source/base metadata in handoffs; checkpoints tracked and untracked work; classifies ignored caches versus unresolved ignored data; rejects secret-like material; pushes LFS and Git without force; verifies exact remote commit SHA; and safely retires the exact clean temporary checkout. Historical recovery falls back to current main when prior data is unavailable.

Remaining: Stage 2 must verify the private archive manifest/restore path and migrate legacy checkout data. Stage 3 must validate integration, publish the behavior-difference matrix, migrate repository entrypoints, obtain fresh-context independent review, and perform the production cutover. The old dispatcher remains the documented production authority until then.

Validation: `python3 -m unittest custodian/tools/agent/test_turn_dispatcher_v2.py -v` (16 tests passed); `python3 -m py_compile custodian/tools/agent/turn_dispatcher_v2.py custodian/tools/agent/test_turn_dispatcher_v2.py`; `git diff --check`; live `inspect` against `agent-blocker-capture-hooks-v1` on authenticated main.

Sources/evidence: PR #123 candidate at branch base above; isolated local bare-Git fixtures; real Git LFS upload, fresh-clone fetch/checkout and missing-object refusal tests; first-branch and checkpoint non-fast-forward race tests; remote SHA verification failure receipt test.

Resume: Fetch `agent/turn-scoped-dispatcher-v2`, inspect its latest commit and this handoff, rerun the focused suite, then continue with the Stage 2 archive verification contract. Do not switch production entrypoints or remove historical worktrees in this stage.
