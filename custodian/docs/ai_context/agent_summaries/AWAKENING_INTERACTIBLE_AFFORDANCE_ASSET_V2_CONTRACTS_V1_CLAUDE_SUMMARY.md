# Awakening Interactible Affordance Asset V2 Contracts V1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## Outcome

Registered the seven current affordance Asset V2 contracts from the locked state manifest. The registry now tracks all 27 required live states individually as open demand. Fourteen recommended states remain optional, and all 36 future states stay out of current required demand. Existing Crèche, Locker, Lift, Gate, and activation FX source families were not modified or replaced. No art was generated, uploaded, or represented as available.

## Change and evidence

- Added `awakening_interact_support`, `terminal`, `locker`, `lift`, `port`, `wayfinding`, and `shared_fx` family contracts with the manifest's state dimensions, frame counts, layouts, layers, variants, and requirement tiers.
- Added a machine-readable gate row for each of the 43 states in those seven contracts. Each row explicitly tracks Dropbox batch identity, source and normalized PNG checksums, alpha validation, pipeline status, Asset V2 state, and human approval. Missing evidence remains null/pending.
- Added 27 exact state targets to `required_assets.registry.json` and regenerated `REQUIRED_ASSETS.md`.
- Extended the manifest and current-state docs with the contract and gate status. Corrected the Awakening asset manifest's Crèche console description; it had incorrectly assigned Dust Lung lift motion authority to the console sprite.
- Contract/ledger/registry parity check passed: 27 required, 14 recommended, 43 ledger rows. All seven family `plan` and `status` commands parsed; all required states remain absent.
- `asset needs --check`: passed.
- `run_validation.py --changed --base origin/main --json`: passed, 3 tests with complete coverage of all changed files that have validation owners.
- `awakening_art_registration_smoke.gd`: passed after completing the full headless Godot import (`ordinary_zones=7`, `composition_exception=04_05`). The initial run before import failed on missing generated Godot import cache only.
- `git diff --check`: passed.
- `asset doctor --json` reports four existing `awakening_designation_locker` catalog hash mismatches (`authorize_open`, `closed`, `empty`, `open_loaded`). The same diagnostics were present before edits; no Locker catalog or artwork was changed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: A fresh worktree required a full headless import before the focused Awakening smoke could pass. The global Asset V2 doctor also reports four pre-existing Locker catalog hash mismatches.
- Root cause / contributing factors: Godot imported textures are worktree-local generated data; the Asset V2 doctor checks the repository-wide catalog, including unrelated existing Locker state hashes.
- Prevention / pipeline improvement: Complete one headless Godot import before renderer-backed smoke validation in a fresh worktree, and keep the pre-existing Locker catalog drift visible in review evidence.
- Tooling / docs drift discovered: The four Locker catalog hash mismatches remain unresolved and predate this task.
- Follow-up: review-awakening-interactible-affordance-asset-v2-contracts-v1
- What worked: Generating contracts from the locked state ledger kept dimensions, frame metadata, and requirement tiers aligned.

## Next Handoff

- Next workstream: review-awakening-interactible-affordance-asset-v2-contracts-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
- Refresh reason: none
- Next action: Run the paired fresh-context review after implementation lands.
- Blockers or open questions: none
