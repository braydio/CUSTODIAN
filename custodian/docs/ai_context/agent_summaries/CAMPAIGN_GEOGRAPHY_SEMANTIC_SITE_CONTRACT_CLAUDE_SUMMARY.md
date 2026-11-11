# F15-B2 · Campaign Geography Semantic Site Contract

Implemented and validated the bounded, read-only semantic projection over the accepted F15-B1 geography registry. `CampaignGeographySemanticRegistry` binds canonical B1 Domain/Location addresses and declared logical edges to typed F02 source references, deterministic site descriptors, intended ingress metadata, and optional Hall reference slots. It validates a whole Domain candidate before replacing registered state and returns defensive copies.

The source adapter consults the existing F02 `LevelRegistry` and `LevelDefinition` contracts. The implementation does not add a parallel F02 registry, alter B1 topology, instantiate Nodes, stage scenes, generate terrain, or mutate F14 population. F02 currently supplies no authentic physical ingress proof through the inspected source contract, so the registry leaves ingress `planned` and rejects unsupported `verified` claims. The generated-region and authored-override resolution branches are guarded by actual existing LevelRegistry entries; current production entries do not provide a positive generated-region fixture, so no positive physical/materialization behavior is claimed.

## Evidence

- Ran Godot editor import before focused testing to populate the fresh class/import cache.
- `campaign_geography_semantic_site_smoke.gd`: exit 0, `CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: PASS`.
- Deliberate `--negative-control`: expected nonzero exit, `CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: NEGATIVE CONTROL`.
- Existing `campaign_geography_identity_smoke.gd`: exit 0, `CAMPAIGN_GEOGRAPHY_IDENTITY_SMOKE: PASS`.
- `run_validation.py --changed --base HEAD --test campaign_geography_semantic_site --json`: passed 1/1, complete coverage, zero failures, zero infrastructure errors. Report captured at `/tmp/campaign-geography-semantic-site-validation.json` for lifecycle finish.
- `check_ai_context.py`: PASS.
- `validate_review_pairing.py`: PASS, 63 auto packets correctly paired.
- `git diff --check`: PASS.

The focused adversarial fixture covers stable normalization for reordered inputs and reconstructed B1 state, Domain/address separation, canonical edge and directed-transit behavior, unknown and mismatched F02 sources, stale provenance, authored override conflicts, false physical-proof claims, false truth-bearing encounter metadata, duplicate/reference errors, atomic rejection and retry, typed optional slots, and the no-Node/data-only boundary.

## Deferred

This slice does not prove a physical road, shore, ingress, scene transfer, continuous walk, travel scale, locality residency, F14 actor handoff, or F15-C gameplay traversal. F14-C2b, production streaming, numerical scale, and art remain separately gated.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial smoke iterations exposed Godot typed-array boundaries and a fixture that did not match declared B1 topology; corrected before final validation.
- Root cause / contributing factors: The semantic test needed to respect the live typed B1 API and directed edge declarations.
- Prevention / pipeline improvement: Keep focused fixtures constructed from live accepted B1 descriptors and retain explicit positive, negative-control, and regression runs.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: The focused validation manifest selected the single intended test with complete changed-file coverage.

## Next Handoff
- Next workstream: review-campaign-geography-semantic-site-contract
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none; the design is approved and the fresh paired review is the immediate successor.
- Next action: Land and archive implementation, then launch the independent review using paired_review_runner.py from the coordination checkout.
- Blockers or open questions: none for this implementation; physical ingress proof, F14-C2b locality residency, scale, and F15-C traversal remain separate gates.
