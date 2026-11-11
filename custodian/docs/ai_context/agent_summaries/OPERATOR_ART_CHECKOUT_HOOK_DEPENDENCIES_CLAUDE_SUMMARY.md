# operator art checkout hook dependencies

Fixed the persistent Operator sparse profile omission that blocked Git commits after successful Workbench publication. The real pre-commit hook runs tools/validate_filenames.py in the art checkout, but that helper was omitted. The sparse profile now includes .githooks and tools/validate_filenames.py. The filename check remains mandatory; no production hooks were disabled to recover the publication.

Added a fixture-only regression using a local Git remote and the real pre-commit hook/helper. It proves sparse materialization, successful valid-art commit, continued omission of unrelated reports, and rejection of a Windows-reserved CON.png without advancing HEAD. Full operator_art_worktree_smoke and git diff --check passed. The first positive-hook assertion looked only at stdout; corrected it to inspect combined stdout/stderr because Git forwards hook output on stderr.

Recovered the actual failed fast_02 east/west publication. Its last transaction was COMMITTED and all mandatory validations had passed; exactly 12 source/runtime PNG paths were staged. Verified the staged set against the transaction paths and source target hashes, backed up the staged binary patch and recovery receipt under .ai/operator_animation_workbench/recovery/fast_two_commit_hook_20261004, and materialized the existing helper from art HEAD without changing its contents or the index. The real pre-commit filename check then passed. Created the normal LAND PENDING receipt and retried through WorkbenchService.publish; an assertion stub guaranteed the exporter was never called during retry. Published to origin/main at 6f93fce19a2c1dd36242faf5c5dc656744133a75. Saved Aseprite bytes and export stamp were unchanged; coordination sync succeeded.

After landing the profile fix, normal ensure must reconcile the now-clean art checkout to the updated sparse profile. No discarded frames, artwork re-export, or validator bypass was used. Update the active checkout before closing the slice; the user's fast_02 publication is already landed and needs no repeated publish.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: a required pre-commit helper was absent from the sparse checkout; completed art publication remained staged after commit failure
- Root cause / contributing factors: prior fixture commits did not exercise the real repository hook and sparse helper dependency
- Prevention / pipeline improvement: include hooks and filename helper in profile; fixture commits execute the real hook with positive and negative filename controls
- Tooling / docs drift discovered: checkout contract omitted an active commit-time dependency
- Follow-up: fixed-in-scope
- What worked: exact staged-path/hash recovery and pending-land retry avoided re-exporting already validated pixels
