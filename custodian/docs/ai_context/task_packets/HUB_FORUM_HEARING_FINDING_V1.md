# FORUM HEARING DETERMINATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-forum-hearing-finding-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `review-hub-forum-hearing-evidence-v1`
- Locks: `hub-forum-hearing, hub-event-persistence`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-forum-hearing-finding-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Forum hearing determination; deliver one playable, bounded event slice.
- Completion boundary: When all 3 sources read, offer ATTEST: PROVENANCE CONFLICT and MAINTAIN HOLD: RESTORATION NOT AUTHORIZED; persist one choice exactly once, expose both orders for reread, never actually open/close a Port. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Assume U1 reviewed 3-source hearing and scoped records exist; no decision or resolved readback implemented.
- Evidence: U1 archived packet/review and hearing smoke; hub_campaign_selection_authority.gd
- Task-specific authority: Custodian Mandate attestation/Hold, event spec §2; reviewed U1.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: U1 hearing controller + scoped HubState record and its readback UI.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: When all 3 sources read, offer ATTEST: PROVENANCE CONFLICT and MAINTAIN HOLD: RESTORATION NOT AUTHORIZED; persist one choice exactly once, expose both orders for reread, never actually open/close a Port. The player's determination is a continuity finding, not ruling on ownership or criminality.
- Preserve: U1 inspection state, Dais, Hub accepted scenario, WorldContractBootstrap generation count.
- Non-goals: No actual Port activation or Contract generation, authority rewiring or new reward economy.
- Acceptance: Both findings reachable/serializable; repeat/reload cannot duplicate completion; Dais acceptance and prewarm match baseline; no branch traps.
- Validation: New hearing-finding smoke + U1 + Forum adjudication regression + HubState snapshot; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Assume predecessor `review-hub-forum-hearing-evidence-v1` passed its post-land review and is archived complete. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-hub-forum-hearing-finding-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
