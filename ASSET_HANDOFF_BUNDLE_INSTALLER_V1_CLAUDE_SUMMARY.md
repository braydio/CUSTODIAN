# Asset Handoff Bundle Installer V1 — Closing Summary

Implemented a standalone, standard-library installer for reviewed Asset V2
handoff ZIPs. It accepts `custodian.asset_handoff.v1`, validates package
checksums/sizes and declared PNG dimensions before writing, requires explicit
state install flags, validates both repository markers and all paths, and only
writes below `custodian/asset_drop/source_work/` or
`custodian/asset_drop/inbox/`. Each new file is written through a same-directory
temporary file and exclusive atomic hard-link, so a concurrent destination is
never overwritten. Identical existing bytes are reported as unchanged;
different bytes fail closed. Dry-run performs the same preflight without making
directories or files.

The smoke copies the installer byte-for-byte into temporary bundles and runs it
in temporary CUSTODIAN fixtures. Positive cases cover default Git-root
discovery, source plus runtime-ready inbox installation, repeat idempotency,
zero-write dry-run, tune-needed source-only staging, and rejected-state skips.
Negative controls cover source hash/size tampering, mismatched and malformed
PNG dimensions, a different-byte collision, wrong repository markers,
absolute/traversal paths, runtime/content destinations, invalid review gates,
and symlink escapes from both the bundle and checkout. All failed preflight
cases leave the permitted intake roots without newly installed files.

Added `generate_asset_handoff_bundle.md` with the manifest contract, per-image
signoff, Game32/procgen metadata, counts, exact routing, and live-main/drift
inspection requirements. Extended the existing Asset V2 architecture and
updated current state and indexes. The installer does not edit family
contracts, call ingest, change generated catalogs, bind consumers, or publish
runtime assets; source ZIPs remain evidence.

## Validation

- `python3 custodian/tools/validation/run_validation.py --test asset_handoff_installer --json` — passed.
- `python3 custodian/tools/validation/run_validation.py --test review_pairing_contract --json` — failed on unrelated active packets' stale validation references; this packet's missing installer entrypoint no longer appears in the failures.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — installer, existing Asset Pipeline V2, Workbench, docs, and validation-runner tests passed; `agent_workflow_contract` failed because its referenced `.github/workflows/expire-lfs-degraded-mode.yml` is absent from `origin/main`.
- `python3 custodian/tools/agent/validate_prompt_contract.py --templates-only --strict` — passed, zero repeated defaults.
- `python3 custodian/tools/agent/check_ai_context.py --json` — failed on ten existing unrelated task-index entries; none reference this packet or its new prompt/index entries.
- The focused smoke uses no Godot process, image renderer, or external Python package.

The dispatcher claim's best-effort diagnostic push stalled for over five
minutes in the Git LFS pre-push hook. I terminated only the stalled SSH/LFS
push; the dispatcher then completed and returned its verified claim receipt.
This is recorded as a manual pipeline follow-up. No connector/runtime evidence
or unrelated root-checkout artifacts were changed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The claim waited over five minutes on a best-effort diagnostics push through the Git LFS pre-push hook. Broad changed-file validation failed in `agent_workflow_contract` because `.github/workflows/expire-lfs-degraded-mode.yml` is absent. The focused AI-context validator reported ten unrelated stale task-index entries, and `review_pairing_contract` still reports validation paths missing from seven other active workstreams.
- Root cause / contributing factors: The diagnostics publisher synchronously invokes the repository LFS pre-push hook without an effective remote timeout. Existing workflow tests and packet validation references are stale independently of this asset-handoff slice.
- Prevention / pipeline improvement: Preserve the focused acceptance gate for this slice; track diagnostics-push timeouts and the existing workflow/packet validation debt for their owners rather than broadening this asset tool.
- Tooling / docs drift discovered: `.github/workflows/expire-lfs-degraded-mode.yml` is referenced by `agent_workflow_smoke.py` but absent from `origin/main`; `check_ai_context.py` reports stale entries for `ASH_BELL_FORLORN_RITUALANT.md`, `BLACK_RELIQUARY_LIVE_MINIMAP.md`, and other unrelated packet-index rows. `review_pairing_contract` no longer reports this packet's installer entrypoint, but retains unrelated missing script references.
- Follow-up: manual-follow-up — diagnostics-push timeout and repository-global workflow/packet-index validation debt.
- What worked: The copied installer passed from a temporary checkout without repository Python imports.
