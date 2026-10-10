# F15-B1 · Campaign Geography Identity Foundation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-geography-identity-foundation`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-campaign-geography-residency-authority-audit`
- Locks: `campaign-geography`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture`
- Paired review workstream: `review-campaign-geography-identity-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new durable identity authority is a cross-system architecture boundary and requires an independent fresh-context review`
- Reviewed main: `fb2f634b`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Goal: Establish a deterministic, collision-safe, data-only identity contract for persistent Campaign Domains, geographic Locations, reciprocal adjacency edges, and per-visit references.
- Completion boundary: Add the smallest repository-native data authority and focused validation proving two fixed-seed Domain fixtures resolve stable addresses and reciprocal neighbor relationships across repeated visits and re-instantiation. No terrain generation or physical travel is part of this slice.
- Current measured state: F15-A is independently accepted. Existing route node IDs, generated scene IDs, `WorldIdentityContract` macro-sector IDs, and M6 chunk coordinates do not provide durable geographic `(domain_id, location_id)` identity. F14-C1 uses synthetic locality anchors; it is not a production geography registry. No F15-B1 packet or runtime authority existed at reviewed `main@fb2f634b`.
- Evidence: `design/04_architecture/F15_POST_AUDIT_GEOGRAPHY_AND_LIVING_WORLD_DECISION_RECORD.md` (approved D1–D7, B1 boundary); `design/04_architecture/codebase_systems_audit/F15_GEOGRAPHY_RESIDENCY_AUTHORITY_EVIDENCE.md`; `REVIEW_CAMPAIGN_GEOGRAPHY_RESIDENCY_AUTHORITY_AUDIT_CLAUDE_SUMMARY.md`; `design/04_architecture/CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md`; `custodian/game/state/world/world_identity_contract.gd`; `custodian/game/state/run/campaign_session.gd`; `custodian/game/state/world/abstract_activity_simulation_state.gd`; `custodian/game/systems/simulation/actor_reification_coordinator.gd`.
- Task-specific authority: Approved D1–D7 in the post-audit decision record; F15 owns durable Domain/Location/Edge identity and topology descriptors; F06 campaign/session owns visit lifecycle; F14 consumes immutable geographic actor addresses and remains sole strategic actor truth; F02 owns local terrain/scene generation; REMAP-3 owns disk persistence. Root `AGENTS.md` and `custodian/AGENTS.md` govern workflow.
- Work surface: Inspect current identity/session types and add a small data-only F15 geography authority in the existing active Godot state/world ownership area chosen from live code. Add focused machine-checkable tests or validation fixture(s) at the existing repository validation seam. Update only directly necessary design/API documentation and current-state index references if required by repository conventions.
- Change: Define a structured Domain identity with stable seed and generation version; stable Location identity scoped to its Domain; stable typed Edge identity and reciprocal adjacency semantics; and a CampaignVisit reference that points to the same persistent Domain and entry/active Locations. Make address/key encoding injective for valid dotted identities. Validate duplicate/colliding addresses, duplicate edges, missing neighbors, incompatible generation versions, invalid ingress provenance, and unsupported references by deterministic fail-closed results. Provide two named neighboring fixture Locations with reciprocal edges for fixed seeds; repeated construction and a second visit must resolve identical Domain/Location/Edge identities. Keep route-node identity distinct from LocationId. Implement the narrowest useful API and preserve existing F06/F14/F02 owners.
- Preserve: Existing schemas/readers, CampaignSession lifecycle and serialization contracts; F14 actor identity and fixed-step authority; F02 terrain generator output and route behavior; existing route/scene/chunk identities; deterministic behavior; no scene or gameplay-node ownership transfer.
- Non-goals: Tiles or terrain output, scenes or streaming, actor registration/reification, ambient spawning, population simulation, save/load or disk persistence, world-scale numeric dimensions, final visual grammar, landmark/encounter/mystery implementation, B2 semantic generation, C2 integration, F15-C travel proof, or any claim that continuous multi-site traversal exists.
- Acceptance: (1) Two fixed-seed Domain fixtures create stable, distinct, collision-safe identities, including valid dotted IDs. (2) Each fixture has two neighboring Locations whose typed Edge references are reciprocal and deterministic; duplicate edge, missing neighbor, or address collision fails closed. (3) Repeated construction and a second CampaignVisit to the same Domain resolve identical sites and generation provenance; incompatible generation version and invalid ingress provenance fail closed. (4) A RouteNode fixture is not accepted or returned as a LocationId. (5) The public contract contains no Node/scene handles and no gameplay node is created. (6) Existing F06/F14/F02 behavior, schemas, and procgen outputs remain unchanged. (7) Focused tests and changed-file validation pass; paired reviewer can reproduce the identity/negative-case claims from committed evidence.
- Validation: Read `custodian/docs/ai_context/VALIDATION_RECIPES.md` and exact owning code/tests first. Run the smallest focused tests for the new identity authority plus relevant existing campaign/session and F14 snapshot tests. Run `python3 custodian/tools/validation/run_validation.py --changed --json`, `python3 custodian/tools/agent/task_packet_index.py`, `python3 custodian/tools/agent/validate_review_pairing.py`, and `git diff --check`. Do not run a broad Godot sweep for this data-only slice. Do not assert cross-site runtime streaming.
- Task overrides: `none`
- Deferred: Numerical world scale, final visual presentation, exact streaming implementation, B2, C2a/b, F15-C, REMAP-3 disk persistence, and repair of the separately owned Ritualant ingress issue unless it prevents a required B1 provenance validator from being authored (in which case report the exact dependency instead of changing its owner).

## Refresh Planning Authority

- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh instruction: D1–D7 are approved. Do not reopen numeric scale, final visual presentation, or exact streaming implementation; stop and report if implementation evidence makes one of those decisions necessary to satisfy this B1 boundary.

## Context Pack

- Repomix: `none`

## Next Handoff

- Next workstream: `review-campaign-geography-identity-foundation`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: After implementation lands and archives complete, launch the paired fresh-context review through `paired_review_runner.py`.
- Blockers or open questions: User authorized packet preparation/publication and explicitly held implementation claim timing; do not claim until separately authorized.
