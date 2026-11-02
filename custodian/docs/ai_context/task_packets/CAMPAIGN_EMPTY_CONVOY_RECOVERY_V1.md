# CONVOY TRACE + BOUNDED SALVAGE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-empty-convoy-recovery-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `campaign-empty-convoy-security-v1`
- Locks: `procgen-authored-convoy, campaign-encounter`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-campaign-empty-convoy-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Convoy trace + bounded salvage; deliver one playable, bounded event slice.
- Completion boundary: After security cleared (or legitimate safe-empty fallback), reveal manifest IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED and one CUSTODY TRACE: SHIPMENT UNVERIFIED. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: C1 site and C2 one-shot defense have landed. C2 paired review was explicitly owner-waived before launch; that disposition is not a reviewer PASS or independent acceptance. Final trace and one-time salvage are not yet implemented.
- Evidence: C2 archived implementation packet, run-state/security smoke, and explicit owner-waived review disposition; WorldEventMemory and active inventory/ResourceLedger APIs
- Task-specific authority: WorldEventMemory, live inventory ledger, event spec §4, C1/C2 implementation evidence and review dispositions; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Convoy controller, registered item/ledger path when present, focused reward/evidence smoke.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: After security cleared (or legitimate safe-empty fallback), reveal manifest IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED and one CUSTODY TRACE: SHIPMENT UNVERIFIED. Grant one modest salvage transaction only if an existing valid item/resource type and ledger operation can be used, otherwise evidence-only completion. Mark WorldEventMemory complete atomically before repeat interaction can duplicate the reward; allow trace reread without second reward. Do not mutate HubState or campaign outcomes.
- Preserve: Seed-specific optional site, existing threat semantics and resource ledger authority.
- Non-goals: No new currency schema, Cross-run reward, restored Scout requirement, resolved cargo identity.
- Acceptance: No duplicate reward after spam, reload, reconnection/revisit; no negative/unknown item; evidence available without reward; non-convoy campaigns unaffected.
- Validation: New convoy-evidence/ledger exactly-once smoke + C1/C2; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Assume predecessor `review-campaign-empty-convoy-security-v1` passed its post-land review and is archived complete. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-campaign-empty-convoy-recovery-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.

## Dependency disposition
- C2 implementation: landed complete at `bde08b88caf38b8163f3c6dbbeff2597bd3935ab`.
- C2 paired review: `owner_waived_prelaunch`; no reviewer was launched, and this is not a PASS.
- C3 remains gated on the C2 implementation only; the waived review does not establish independent acceptance.
