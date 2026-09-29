# Vaultwing bond greet final ingest

## Outcome

The workstream is blocked at input provenance and preflight. I treated the
worktree's root `vw*.png` paths as the user's clarified local originals without
verifying their provenance. That was incorrect: the paths are Git-LFS pointers
present in `origin/main`, introduced by commit `302fef5b7` (`vaultwing source`).
The task worktree inherited those pointers from main. `git lfs checkout` hydrated
the payloads from the shared local LFS cache; no LFS fetch was run, but the
cache's original source is unknown. I cannot claim these were the user's local
Firefox saves or that their payloads were obtained independently from main.

The repo-tracked `vw1`–`vw4` payloads have 4, 5, 6, and 6 alpha-X frame clusters
instead of the required eight, with visual direction mismatches in the assigned
N/S/W slots. This describes only the repo-tracked payloads, not the user's
separate originals. The older checkpoint also records `vw9`, `vw10`, and `vw12`
as clipped greeting candidates. No alternate mapping was guessed.

No source_work, inbox, runtime, catalog, quarantine, or production art was
written. The workstream remains blocked until the user's actual local inputs can
be found and provenance plus frame/orientation preflight are verified.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: high
- What went wrong: repo-tracked LFS payloads were mistaken for the user's local source files.
- Root cause / contributing factors: the task worktree inherited root pointers from main, and the shared LFS cache does not record where or when its objects were obtained.
- Prevention / pipeline improvement: verify user-provided files from an independent local path or compare hashes supplied by the user before treating them as local originals; do not write assets until both provenance and contract checks pass.
- Tooling / docs drift discovered: the packet's Downloads path was superseded by the user's project-root instruction, but those tracked paths are not independently verified local copies.
- Follow-up: manual-follow-up — locate/receive the user's actual local `bond_greet` E/N/S/W sheets, verify provenance, and resume this workstream.
- What worked: no LFS fetch was run and production destinations remain untouched.
