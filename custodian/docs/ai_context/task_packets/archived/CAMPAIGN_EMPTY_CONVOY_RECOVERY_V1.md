# CONVOY TRACE + BOUNDED SALVAGE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-empty-convoy-recovery-v1`
- Status: `complete`
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
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0`
- Visual review: `none`
- Goal: Convoy trace + bounded salvage; deliver one playable, bounded event slice.
- Completion boundary: After security cleared (or legitimate safe-empty fallback), reveal manifest IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED and one CUSTODY TRACE: SHIPMENT UNVERIFIED. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: C1 site and C2 one-shot defense have landed. C2 paired review was explicitly owner-waived before launch; that disposition is not a reviewer PASS or independent acceptance. Final trace and one-time salvage are not yet implemented.
- Evidence: C2 archived implementation packet, run-state/security smoke, and explicit owner-waived review disposition; WorldEventMemory and active inventory/ResourceLedger APIs
- Task-specific authority: WorldEventMemory, live inventory ledger, event spec §4, C1/C2 implementation evidence and review dispositions; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: `custodian/game/world/events/campaign/empty_convoy_site.gd`; `custodian/tools/validation/campaign_empty_convoy_recovery_smoke.gd`; `custodian/tools/validation/campaign_empty_convoy_recovery_smoke.gd.uid`; and `custodian/tools/validation/validation_manifest.json`.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: After security cleared (or legitimate safe-empty fallback), reveal manifest IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED and one CUSTODY TRACE: SHIPMENT UNVERIFIED. Grant one modest salvage transaction only if an existing valid item/resource type and ledger operation can be used, otherwise evidence-only completion. Mark WorldEventMemory complete atomically before repeat interaction can duplicate the reward; allow trace reread without second reward. Do not mutate HubState or campaign outcomes.
- Preserve: Seed-specific optional site, existing threat semantics and resource ledger authority.
- Non-goals: No new currency schema, Cross-run reward, restored Scout requirement, resolved cargo identity.
- Acceptance: No duplicate reward after spam, reload, reconnection/revisit; no negative/unknown item; evidence available without reward; non-convoy campaigns unaffected.
- Validation: `campaign_empty_convoy_recovery` proves exactly-once trace/salvage, same-run reentry, safe-empty evidence, and unknown-resource fallback; also run C1 placement and C2 security regressions plus changed-file validation. Run changed-file validation and `git diff --check` only after the focused smoke passes.
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
- Next action: After canonical implementation landing and teardown, run `review-campaign-empty-convoy-recovery-v1` in a fresh reviewer context.
- Blockers or open questions: C2 paired review was owner-waived, not passed. C3 independent paired review remains required after implementation landing.

## Dependency disposition
- C2 implementation: landed complete at `bde08b88caf38b8163f3c6dbbeff2597bd3935ab`.
- C2 paired review: `owner_waived_prelaunch`; no reviewer was launched, and this is not a PASS.
- C3 remains gated on the C2 implementation only; the waived review does not establish independent acceptance.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: n/a
- Evidence: After security clears or the safe-empty fallback is recorded, the site persists `CONVOY CUSTODY TRACE: SHIPMENT UNVERIFIED` and grants one canonical `ruin_scrap` through `ResourceLedger` only when its definition and completion memory are available. The completion receipt is written before the grant; spam and same-run reentry do not duplicate salvage. Missing ledger definition retains evidence-only completion. Focused recovery, C1 placement, C2 security, and final changed-source validation passed. Independent paired review is pending; no review PASS is claimed.
