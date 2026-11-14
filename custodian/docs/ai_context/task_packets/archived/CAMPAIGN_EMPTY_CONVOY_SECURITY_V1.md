# CONVOY SCAN-TRIGGERED SECURITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-empty-convoy-security-v1`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `campaign-empty-convoy-placement-v1`
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
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0`
- Visual review: `none`
- Goal: Convoy scan-triggered security; deliver one playable, bounded event slice.
- Completion boundary: Interaction SCAN CARGO CRADLE activates one bounded wave of up to three existing security units facing outward (use registered enemy/defense types and live safe-spawn rules). Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Assume C1 reviewed deterministic optional convoy footprint; no hostile engagement or one-shot activation in event.
- Evidence: C1 reviewed placement smoke and current combat spawn/turret APIs
- Task-specific authority: Existing enemy spawn/combat ownership, C1 collision/placement proof, event spec §4.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: `custodian/game/world/events/campaign/empty_convoy_site.gd`; `custodian/game/world/procgen/special_rooms/special_room_runtime_inserter.gd`; `custodian/game/systems/spawning/ambient_enemy_spawner.gd`; `custodian/tools/validation/campaign_empty_convoy_security_smoke.gd`; `custodian/tools/validation/campaign_empty_convoy_security_smoke.gd.uid`; and `custodian/tools/validation/validation_manifest.json`.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Interaction SCAN CARGO CRADLE activates one bounded wave of up to three existing security units facing outward (use registered enemy/defense types and live safe-spawn rules). Record spawn/active/cleared local states in WorldEventMemory with run-seed-qualified event identity. No unbounded respawn on reload/revisit; player can retreat; if enemy registration absent fail closed into empty-defense evidence mode, not crash.
- Preserve: Existing enemy health/AI, world encounter Director authority, no new nav footprint, optional event can be skipped.
- Non-goals: No custom enemy class, turret combat rebalance, inventory, cargo provenance conclusion or vehicle operation.
- Acceptance: One scan activates at most one wave; no duplicate spawned identities; security clears when registered units defeated; unspawnable case is safe; fresh run seed resets independently.
- Validation: Convoy-security smoke covers bounded registered queue, shared active cap, facing, completion, run identity, reentry, queue-time and preflight safe-spawn failure; ambient actor spawn and real-world ambient spawn regressions; C1 multi-seed placement; reciprocal canon and validation-runner self-checks. Changed-file validation and `git diff --check` must pass before finish.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Predecessor implementation `campaign-empty-convoy-placement-v1` landed at `47fd0755203dc22fb7149889253154741c78689b` and passed implementation validation (5/5, complete changed-source coverage). Its paired review was explicitly owner-waived prelaunch because the exact read-only host gate rejected the changed validation manifest as lacking an accepted exact source attestation. That disposition is not reviewer PASS or independent acceptance. This packet depends on the landed implementation only. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: After canonical implementation landing and teardown, run `review-campaign-empty-convoy-security-v1` in a fresh reviewer context.
- Blockers or open questions: Paired review remains pending and must not be treated as PASS; ordinary dispatcher dependencies and live claim locks apply.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: n/a
- Evidence: Runtime-integrated scan interaction queues at most three registered security actors through `AmbientEnemySpawner`, accounts for them in the shared active cap, persists run-seed-qualified event state, and fails safely when queue-time walkability changes. Focused security, ambient spawn, real-world ambient spawn, C1 placement, and changed-source validation passed. Independent paired review is still pending and no review PASS is claimed.
