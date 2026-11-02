# EMPTY CONVOY INTEGRATED SECURITY CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-empty-convoy-security-integrated-correction-v1`
- Category: `gameplay-systems`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `campaign-empty-convoy-recovery-v1`
- Locks: `procgen-authored-convoy, campaign-encounter`
- Kind: `implementation`
- Review: `none`
- Review rationale: `The coordinator authorized one implementation packet and deferred the correction review disposition to a separate control. This packet claims neither review completion nor a waiver of the observed failure.`
- Reviewed main: `5876922872b8e08b6edc13f2a2a60c8947315e9e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0`
- Visual review: `none`
- Goal: Keep Empty Convoy security unresolved until registered defenders are verified defeated or an authoritative safe-empty outcome is established.
- Completion boundary: Correct the existing Empty Convoy security state transitions so temporary capacity, navigation, queue, or streaming failures cannot unlock custody trace or salvage. Close with focused state-transition and production-realistic validation; do not expand the event.
- Current measured state: Integrated gameplay retest on contract seed `2` generated map seed `3570245418` and inserted `campaign_empty_convoy_v1` at tile `(115,98)`. The player scanned the cargo cradle, observed no hostiles, and immediately received `RECORD CUSTODY TRACE`. Exact runtime trigger is unconfirmed. Source inspection shows capacity exhaustion, no resolved safe spawn, service unavailability, total queue failure, and missing active actors on reentry can all transition to `empty_defense`; the C3 trace path accepts that state as completion. The intended security encounter did not occur.
- Evidence: Original retry screenshot `/tmp/cqa-seed2-retry-final.png` (SHA-256 `29798452169388f4ed953e347bee4d47849d53aae157ff45dcc8ba2c232e61b9`); run log `/tmp/custodian-convoy-seed2-retry-gui.log` (SHA-256 captured after shutdown); the existing DevObservatory session record identifies the contract/map seeds. Host-local files are diagnostic provenance, not required implementation inputs.
- Task-specific authority: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`; completed C1/C2/C3 convoy packets and archived evidence; existing event-memory, ambient-spawn, and enemy death ownership. The C2/C3 implementation chain is complete; this is a bounded correction, not a reopened C1-C3 task.
- Work surface: `custodian/game/world/events/campaign/empty_convoy_site.gd`; existing `custodian/tools/validation/campaign_empty_convoy_security_smoke.gd`, `campaign_empty_convoy_recovery_smoke.gd`, and `campaign_empty_convoy_placement_smoke.gd`; only directly required event-memory/spawner/test owners if the correction proves necessary.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`; `custodian/game/world/events/campaign/empty_convoy_site.gd`; `custodian/tools/validation/campaign_empty_convoy_security_smoke.gd`; `custodian/tools/validation/campaign_empty_convoy_recovery_smoke.gd`; `custodian/tools/validation/campaign_empty_convoy_placement_smoke.gd`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Change: Distinguish permanent registered-defender absence from temporary inability to spawn or observe defenders. On full ambient capacity, record a retryable deferred state and retry within a bounded, event-owned mechanism when capacity becomes available. On failed walkability resolution or queue-time rejection, retain a retryable unresolved state with sanitized reason/count diagnostics. Failed or partial queue slots must not count as defeated or permit duplicate identities. On reentry, missing active actors remain unresolved unless WorldEventMemory or authoritative enemy-death ownership proves their defeat. Preserve safe-empty completion only when registered defender absence is authoritative. Permit custody trace and the existing exactly-once salvage only after verified clearance or that legitimate safe-empty outcome. Record the first relevant transition and its event identity, generated seed, prior/new state, reason, active/pending/cap counts, candidate positions, and queued/accepted/rejected counts through existing DevObservatory facilities; diagnostics must not control gameplay.
- Preserve: Existing C1 placement, C2 bounded defender wave, C3 custody trace and exactly-once ledger transaction; WorldEventMemory and AmbientEnemySpawner ownership; run-seed event identity; deterministic simulation; existing enemy health, AI, death signals, and combat rules.
- Non-goals: No new encounter manager or enemy class; no combat rebalance; no Asset V2 or environment-art work; no unrelated Operator presentation fixes; no reopening or rewriting archived C1-C3 implementation packets.
- Acceptance: (1) A full ambient cap does not produce `empty_defense`, trace, or salvage; freeing capacity permits one bounded retry. (2) A production-realistic walkability rejection leaves security unresolved and trace/salvage unavailable, with a recorded reason. (3) Queue-time failure and partial spawn never count failed slots as defeats, never duplicate accepted enemy identities, and remain safely recoverable. (4) Reentry with missing active actors remains unresolved unless verified defeat receipts exist. (5) Each actual defender must be defeated before clearance; all verified defeats permit the trace. (6) Legitimate registered-defender absence may use the existing safe-empty outcome. (7) Contract seed `2` records its generated map seed and the first scan either spawns registered defenders or leaves an explicitly unresolved state that cannot grant salvage. (8) Exactly one salvage award occurs after valid trace and no duplicate award occurs on revisit.
- Validation: Extend the existing security and recovery smoke tests for cap exhaustion/retry, no safe spawn, queue rejection, partial spawn, interrupted encounter/reentry, verified deaths, trace eligibility, and exactly-once salvage. Use the actual generated map/walkability owner for a production-realistic case; do not use an always-accepting probe as its substitute. Run the focused convoy security and recovery smokes plus placement regression. Record the contract seed and generated map seed. Follow committed-source validation in `custodian/docs/ai_context/VALIDATION_RECIPES.md`; do not run a broad sweep unless the changed-file recipe requires it.
- Task overrides: `none`
- Deferred: Review disposition for this correction requires a separate coordinator control. The implementation may not report this packet as independently reviewed or accepted.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0`
- Refresh instruction: Re-read the exact baseline and completed C3 owners in the claimed worktree. Keep the runtime trigger unknown unless the captured original run proves it; reproduce unsafe transitions deterministically.

## Handoff
- Next action: Claim this exact packet only if the current dispatcher audit marks it eligible and its lock remains available; implement and validate the bounded correction through the canonical workstream lifecycle.
- Blockers or open questions: Exact production trigger for the skipped defense is unknown. Review disposition is intentionally deferred to a separate coordinator control.
