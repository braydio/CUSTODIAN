# SEPULCHER GRAVE ATTESTATION + PALE GROWTH

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-sepulcher-grave-resolution-v1`
- Status: `complete`
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
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
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

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: The production `SepulcherGraveEvidence` controller exposes exactly two physical choices after the three readings, persists either exact finding once in the existing HubState event record, suppresses both choices after resolution, and keeps all three readings inspectable without changing evidence. On restored later visits, either finding shows the restrained pale growth; the controller and choice presentation add no collision owner. The focused production-host smoke, predecessor grave evidence/persistence smoke, Hub first-set traversal smoke, 9/9 changed-file validation, JSON manifest parse, and `git diff --check` passed. Contract prewarm count remained unchanged.
- Deferred work: Production raster growth art remains deferred; no new art family or generalized event framework was added.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The predecessor G1 smoke expected completed readings to become unavailable, conflicting with G2's accepted reread requirement. Its assertion was updated to verify all three readings remain inspectable and that rereading leaves the record unchanged.
- Root cause / contributing factors: G1's original no-replay assertion predated the G2 contract to retain access to the physical evidence.
- Prevention / pipeline improvement: Keep predecessor regression assertions aligned when a declared successor extends behavior while preserving the underlying evidence state.
- Tooling / docs drift discovered: none.
- Follow-up: `fixed-in-scope`.
- What worked: Existing physical interaction and HubState snapshot/restore seams supported both findings and the later-visit cue without adding a state manager or collision authority.

## Handoff
- Next workstream: `review-hub-sepulcher-grave-resolution-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `n/a`
- Refresh reason: `none`
- Next action: Run the paired review from a fresh context after this implementation lands and archives.
- Blockers or open questions: `none`
