# Vaultwing bond greet final ingest

## Outcome

The workstream is blocked at the required local-art preflight. The user directed
this run to use the 12 `vw*.png` files in the project-root CUSTODIAN directory
and explicitly prohibited downloading them from `main`. The checkout held LFS
pointers; all 12 payloads were already in the local LFS cache and were
materialized with `git lfs checkout` only. No fetch or network transfer occurred.

The packet's assigned first-four mapping (`vw1=e`, `vw2=n`, `vw3=s`, `vw4=w`)
does not satisfy the eight-frame contract. The existing stager found 4, 5, 6,
and 6 alpha-X frame clusters, respectively. Each file decodes as RGBA with
transparency, but visual review also found direction mismatches in the assigned
N/S/W slots. The older checkpoint already records `vw9`, `vw10`, and `vw12` as
greeting sheets with clipped wings. No alternative mapping was guessed.

No source_work, inbox, runtime, catalog, quarantine, or production art was
written. The required staging-workflow implementation and checkpoint
convergence were not started because the packet's explicit override requires
this workstream to stop and checkpoint when the local input preflight fails.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: medium
- What went wrong: packet inputs described as four new local greeting sheets were not the intended eight-frame E/N/S/W batch; the user-provided root batch contains previously tracked material with mismatched frame counts and orientations.
- Root cause / contributing factors: the packet's Downloads path and four-file mapping did not match the user's clarified local source location and available batch.
- Prevention / pipeline improvement: retain the fail-closed preflight; update the packet to accept the user's local source location and require corrected eight-frame directional inputs before any file writes.
- Tooling / docs drift discovered: packet input-location prose was superseded by the user's instruction; packet handoff now records the local-batch preflight evidence.
- Follow-up: manual-follow-up
- What worked: local LFS cache allowed inspection without any fetch; staging destinations remained untouched.
