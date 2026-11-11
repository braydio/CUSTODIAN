# CUSTODIAN IMPLEMENTATION 024 — PixelPlanets legacy retirement

Workstream: `procgen-pixelplanets-legacy-retirement-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2

## Result

Removed the six obsolete PixelPlanets scene references, scene loader, unused `PlanetRoot`, exported planet offset, and tracked `custodian/Planets` symlink. The physical `PixelPlanets` directory was absent and was not searched for or changed. Contract payloads retain key, `planet_seed`, world profile, and map seed semantics without advertising obsolete scene or instance fields. The terminal's independent procedural 3D globe remains and is verified from the contract key and seed.

Updated current-tense design/status documentation and added `planet_contract_retirement_smoke.gd` plus its validation manifest entry. The smoke pins the pre-removal profile SHA-256 and fixed-seed key/planet-seed/map-seed outputs, checks normal and Edgar contract paths without legacy resources, and checks terminal globe material construction.

## Validation

- Focused `planet_contract_retirement`: PASS; source unchanged during validation. Godot emitted shutdown ObjectDB/resource leak warnings classified by the existing runner as known warnings.
- Canonical `run_validation.py --changed --base origin/main --json`: PASS, 16 selected / 16 passed / 0 failed / 0 timed out / 0 infrastructure errors; coverage complete with no uncovered files; source unchanged during validation.
- `git diff --check` and staged diff check: PASS.
- Runtime search for live `res://Planets/`, `PLANET_LIBRARY`, old loader functions, planet instance/scene fields and `PlanetRoot`: no production runtime references.
- Commit: `25a7f6d1c1d6e995d8cefed2a5b0865de481b217` (pushed to `origin/agent/procgen-pixelplanets-legacy-retirement-v1`).

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The first Edgar contract smoke reached a pre-existing invalid command_post.tmj and RoomLoader emitted a fatal no-templates warning.`
- Root cause / contributing factors: `The legacy-layout loader input is malformed in the current content tree and is unrelated to planet contract serialization.`
- Prevention / pipeline improvement: `Use a small EdgarContractHarness with deterministic valid layout output to isolate the contract serialization path from unrelated room-template assets.`
- Tooling / docs drift discovered: `none`
- Follow-up: `review-procgen-pixelplanets-legacy-retirement-v1`
- What worked: `The focused regression pins the pre-removal profile digest and fixed-seed RNG tuples while exercising seeded terminal globe construction without legacy art resources.`

## Next Handoff

- Next workstream: `review-procgen-pixelplanets-legacy-retirement-v1`
- Next packet state: dependency-gated until implementation archive and landing complete
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2
- Next action: After canonical finish archives and lands this implementation, launch the fresh-context paired review against the exact landed commit and preserved baseline tests.
- Blockers or open questions: none for implementation; independent review remains required.
