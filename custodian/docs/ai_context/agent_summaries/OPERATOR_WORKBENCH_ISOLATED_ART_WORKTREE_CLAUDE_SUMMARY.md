# Operator Workbench Isolated Art Worktree — Claude Summary

## Delivered

- Normal `opui` now launches the Operator UI from the persistent `workbench/operator-art` checkout while reusing the coordination checkout's UI environment.
- OPUI shows checkout identity and disables tracked publish from coordination `main`. The reviewed `PUBLISH TO MAIN` action guards upstream source conflicts, calls the existing Workbench transaction once, validates the produced path set, stages only allowlisted outputs, commits deterministically, and delegates landing to `land_main.py`.
- A failed landing retains a clean local commit as `LAND PENDING`. Retry lands that commit without exporting pixels again. Best-effort coordination checkout sync is reported separately.
- `land_main.py`'s new finish-only direct-call guard initially blocked the approved UI flow after `origin/main` advanced. I added a separate, explicitly requested landing mode restricted to `workbench/operator-art` → `origin/main`; ordinary task branches remain blocked outside `workstream.py finish`.
- One-time ignored Workbench migration preserves Aseprite bytes, updates checkout-root paths in JSON manifests, reports tracked coordination edits without moving them, and refuses migration while Aseprite is running.

## Evidence

- `operator_art_worktree_smoke.py`: passed isolated launcher/worktree routing, identity, allowlisting, source conflict, unexpected path, migration, coordination-main refusal, and resumable landing cases.
- `operator_workbench_ui_smoke.py`: passed with the coordination UI venv, including the Textual pilot and retry-without-republish regression. The system-Python changed sweep skips only the optional Textual pilot; it passed separately with the venv.
- `operator_animation_workbench_smoke.py` and `operator_workbench_mirror_publish_smoke.py`: passed.
- `run_validation.py --changed --json`: passed, 14 selected and 14 passed, zero uncovered files. `py_compile` and `git diff --check` passed.

## Rough edges and limits

- Aseprite was open on the legacy ignored Workbench in the host coordination checkout. I did not migrate that live state; the helper correctly refused. Isolated fixtures covered both successful byte-preserving migration and the open-editor refusal.
- The task checkout had Git LFS pointer files at first. `git lfs checkout` hydrated the locally cached objects (17,036 objects, about 5.4 GB); no network fetch was needed. Runtime ensure now hydrates only needed Operator PNGs from the local cache and fails closed when cache content is unavailable.
- The synthetic landing race test intentionally makes `land_main.py` hit its three-retry block before a subsequent retry succeeds. This verifies recovery, though its expected blocked diagnostic appears in the smoke output.
- Post-sync validation first surfaced the finish-only guard described above. The scoped Operator publication path was added, and the lander tests now cover rejection from a normal task branch.
- The default root UI venv lacks Textual dependencies in system Python; the full pilot was run with the existing coordination UI venv.

## Deferred

- No art or animation contracts changed. Cross-machine synchronization of ignored Aseprite state and atomic visibility to arbitrary non-Workbench readers remain outside this task packet.
