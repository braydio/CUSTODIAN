# CONVOY SCAN-TRIGGERED SECURITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-empty-convoy-security-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `review-campaign-empty-convoy-placement-v1`
- Locks: `procgen-authored-convoy, campaign-encounter`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-campaign-empty-convoy-security-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Convoy scan-triggered security; deliver one playable, bounded event slice.
- Completion boundary: Interaction SCAN CARGO CRADLE activates one bounded wave of up to three existing security units facing outward (use registered enemy/defense types and live safe-spawn rules). Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Assume C1 reviewed deterministic optional convoy footprint; no hostile engagement or one-shot activation in event.
- Evidence: C1 reviewed placement smoke and current combat spawn/turret APIs
- Task-specific authority: Existing enemy spawn/combat ownership, C1 collision/placement proof, event spec §4.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: C1 convoy controller plus existing security/encounter spawn seam; focused activation smoke.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Interaction SCAN CARGO CRADLE activates one bounded wave of up to three existing security units facing outward (use registered enemy/defense types and live safe-spawn rules). Record spawn/active/cleared local states in WorldEventMemory with run-seed-qualified event identity. No unbounded respawn on reload/revisit; player can retreat; if enemy registration absent fail closed into empty-defense evidence mode, not crash.
- Preserve: Existing enemy health/AI, world encounter Director authority, no new nav footprint, optional event can be skipped.
- Non-goals: No custom enemy class, turret combat rebalance, inventory, cargo provenance conclusion or vehicle operation.
- Acceptance: One scan activates at most one wave; no duplicate spawned identities; security clears when registered units defeated; unspawnable case is safe; fresh run seed resets independently.
- Validation: New convoy-security smoke incl reentry/unload/reload + relevant spawn/AI and C1 multi-seed placement regressions. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Assume predecessor `review-campaign-empty-convoy-placement-v1` passed its post-land review and is archived complete. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-campaign-empty-convoy-security-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
