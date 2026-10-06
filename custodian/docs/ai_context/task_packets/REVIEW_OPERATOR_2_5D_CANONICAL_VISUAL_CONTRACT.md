# REVIEW OPERATOR 2.5D CANONICAL VISUAL CONTRACT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-2-5d-canonical-visual-contract`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-2-5d-canonical-visual-contract`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Kind: `review`
- Reviewed main: `ca5e7d2acc5282f304a8d969343db127462326f1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Goal: Independently verify exact preservation of the approved Operator turnaround, deterministic dual-profile migration, direction-specific measurement/landmark truth, and non-leaking anti-drift guides/QA.
- Review modes: `code, architecture, asset-pipeline, workflow, visual-contract`
- Non-goals: no art regeneration, no runtime animation replacement, no subjective redesign.
- Required evidence: source hash/dimensions/order; source-cell reconstruction; profile v1/v2 backward compatibility; legacy-96 + canonical-128 selection; reproducible landmarks/measurements; deterministic palette/brightness/silhouette reports; Aseprite guide exclusion; intentional drift fixtures caught; turnaround/overlay faithful to the approved source.
- Acceptance: zero blocking source-integrity/profile-migration/guide-leak defects. Subjective visual concerns return to the authoring chat rather than being silently corrected.
- Validation: focused canonical visual-contract + registration-profile tests + `git diff --check` only.
## Handoff

- Next workstream: `operator-2-5d-workbench-cockpit-foundation`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: `none; WB25-1 is already authored and additionally waits for the completed viability audit and reviewed New Animation backend`
- Next action: `allow WB25-1 to claim only when all declared dependencies are complete`
- Blockers or open questions: `none beyond declared dependencies`
