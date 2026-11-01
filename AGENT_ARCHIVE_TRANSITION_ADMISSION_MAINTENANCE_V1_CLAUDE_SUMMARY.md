# Archive Transition Admission Maintenance Summary

## Scope

RC-119 authorizes a narrowly pinned lifecycle admission for the protected paired
review `review-agent-paired-review-runner-profile-summary-coverage-v1`. The
existing archive commit `704a1fbb3df6deae64e06291769eabd1d48f7eb2` and its one-line
metadata correction `81fb8ca935bb2d5f9f00f18d547c185035e7b8dd` remain intact.

## Implementation

`workstream.py` now admits only the exact archive/correction commit pair, with
the original parent, trees, packet blobs, path, and regular-file modes pinned.
It accepts the correction as the clean pre-sync tip and as the first-parent
correction immediately before the normal archive-first main sync. Further edits
to the protected archived review packet remain rejected.

Independent review of the first PR head found that the packet byte SHA-256
digests had been compared directly to Git SHA-1 blob IDs. The follow-up now
pins and checks both identifiers separately, and an unmocked local canary
authenticates the real preserved archive/correction commits and protected
worktree preflight.

`test_workstream.py` covers the pre-sync and verified sync paths plus extra
bytes, extra paths, changed review target, wrong parent, changed summary, and a
second post-sync edit. The existing unbound archive-follow-up rejection remains
covered.

## Validation

- `python3 -m py_compile workstream.py test_workstream.py` — passed.
- Focused RC-119 regression — passed.
- `python3 -m unittest -q test_workstream` — 81 tests passed.
- Unmocked RC-119 preserved-commit canary — passed.
- `git diff --check` — passed.

## Handoff

The change is in draft PR #103. Independent review of the corrected head and
the PR CI rerun are pending. The change does not accept the protected review,
alter original review evidence, release its claim/lock, launch a reviewer for
that run, or authorize merging this maintenance PR.
