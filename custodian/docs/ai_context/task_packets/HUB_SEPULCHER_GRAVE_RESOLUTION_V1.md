# SEPULCHER GRAVE ATTESTATION + PALE GROWTH

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-sepulcher-grave-resolution-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-hub-sepulcher-grave-evidence-v1`
- Locks: `hub-event-persistence, hub-sepulcher`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-hub-sepulcher-grave-resolution-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Sepulcher grave attestation + pale growth; deliver one playable, bounded event slice.
- Completion boundary: After 3 distinct readings display exactly two explicit findings: ATTEST: PROVENANCE CONFLICT or LEAVE UNRESOLVED. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Assume G1 landed: grave controller, three persisted evidence stages and authored_event_records are validated. No resolution choice or post-resolution cue exists until this packet.
- Evidence: G1 archived packet/review and landed grave smoke; custodian/game/state/persistent/hub_state.gd
- Task-specific authority: G1 reviewed contract; event spec §1; Custodian attestation jurisdiction.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Existing G1 grave controller and HubState event record; focused resolution smoke.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: After 3 distinct readings display exactly two explicit findings: ATTEST: PROVENANCE CONFLICT or LEAVE UNRESOLVED. On one choice persist resolution atomically, suppress repeated choice, keep all readings inspectable; on later arrival display a restrained pale-growth local presentation cue (existing art or primitives). Keep unknown grave identity unresolved, no lore claim that observation changes physical past.
- Preserve: G1 evidence progression, HubState snapshot/restore, normal optional route traversal.
- Non-goals: No NPC/dialogue framework, doctrine reward, combat, required raster art or forced story progression.
- Acceptance: Both choices test separately, exactly-once on button spam and snapshot restore; flower/growth appears after resolution only and never blocks collision; post-resolution reread works; no Contract side effects.
- Validation: New grave-resolution smoke + G1 smoke + HubState persistence + Hub first-set traversal; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Assume predecessor `review-hub-sepulcher-grave-evidence-v1` passed its post-land review and is archived complete. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-hub-sepulcher-grave-resolution-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
