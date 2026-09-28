# Two-Speed Validation CI — Closeout

Added changed-file CI to the existing repository validation workflow without changing runtime or validation semantics.

- Pushes to `main` and `agent/**`, pull requests to `main`, and manual dispatches now run manifest-routed validation.
- `Fast changed validation` runs only selected unit-tier owners and is bounded to 10 minutes.
- `Downstream changed validation` runs the full changed-file selection only after the fast job passes, and only for `main`, pull requests, or manual dispatches.
- Branch concurrency cancels stale runs so superseded validation does not pile up.
- Both jobs reuse `run_validation.py`, `validation_manifest.json`, Godot 4.7, and the existing tier/timeout/coverage behavior.
- The workflow is owned by `agent_workflow_contract`, while changes to the validation manifest remain owned by `validation_runner`.

The long downstream job is intentionally not wired into `land_main.py`; it is a post-land regression tripwire rather than a routine agent wait.
