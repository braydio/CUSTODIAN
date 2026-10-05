# HUB FORUM ADJUDICATION + CONTRACT PREWARM — H3

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-forum-adjudication-contract-prewarm`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-hub-awakening-context-handoff`
- Locks: `hub-runtime, contract-bootstrap`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-forum-adjudication-contract-prewarm`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `786f73125094`

- Goal: Make the Adjudication Dais the first embodied Contract decision: surface one provisional first Contract, accept it exactly once, persist that accepted scenario/seed across Hub exploration, and start exactly one `WorldContractBootstrap` prewarm while the player remains physically in Hub.
- Completion boundary: Add one persistent Hub campaign-selection authority and one Dais interaction sufficient for the first playable. Acceptance stores one typed `CampaignScenario` with one nonzero seed and calls the persistent bootstrap once. Selected state survives Hub/Twin traversal and exposes generation state for H5. No deployment.
- Current measured state: `CampaignScenario`, `HubState`, `DefaultCampaignScenarioFactory`, and `WorldContractBootstrap` exist, but no live persistent Hub owner surfaces/stores an accepted scenario. Bootstrap owns IDLE/GENERATING/READY/FAILED/CLAIMED and one-shot generation. H2's production Hub host/lifecycle does not yet exist.
- Evidence: `HUB_SYSTEM_META_PROGRESSION.md`; `CAMPAIGN_FLOW_AND_GAME_LOOP.md`; `HUB_FIRST_SET_BLOCKOUT.md`; `hub_state.gd`; `campaign_scenario.gd`; `default_campaign_scenario_factory.gd`; `world_contract_bootstrap.gd`; `world_contract_prewarm_smoke.gd`.
- Task-specific authority: reviewed H2 runtime host/lifecycle; Hub meta-progression authority; H1 `AdjudicationDais`; persistent bootstrap API.
- Work surface: Reuse any H2 persistent Hub coordinator; otherwise create the narrowest selection owner. Add Dais interaction/presentation under the Hub host, HubState ownership, accepted CampaignScenario/seed state, bootstrap integration, and focused adjudication smoke. Geometry does not own campaign state.
- Change: V1 may surface one first scenario through `DefaultCampaignScenarioFactory` rather than inventing the full future offer generator. Explicit Dais acceptance stores that typed scenario and explicit nonzero procgen seed in persistent Hub authority, then calls `WorldContractBootstrap.ensure_started(seed)` exactly once. Repeated interaction reads accepted/prewarm state and cannot reroll/duplicate. State must survive authored Hub/Twin activation cycles. Expose READY/GENERATING/FAILED for H5 without making Field Terminal the destination.
- Preserve: physical Hub control during generation; bootstrap stale-map guards; contract-sandbox compatibility; deterministic accepted seed; no Node refs in persistent HubState; H1/Twin geometry; CampaignScenario schema.
- Non-goals: No multi-offer/recon system; no final Contract art/prose; no `game.tscn` load; no Campaign simulation; no Twin wiring; no outcome application.
- Acceptance: explicit Dais acceptance stores exactly one typed scenario + nonzero seed; generation_count changes 0→1 once; repeated use during GENERATING/READY/FAILED cannot silently reroll or increment generation_count; bootstrap seed equals accepted seed; Hub remains active while generation runs/fails/completes; selection survives Hub-host deactivate/reactivate used by authored traversal; H3 never loads `game.tscn`; direct bootstrap/debug sandbox remains green.
- Validation: Add focused Dais/adjudication smoke using fake bootstrap generation where practical; prove accepted identity, one-shot generation, persistence, failure visibility, and no scene transition. Re-run `world_contract_prewarm_smoke.gd`, H2/H1 focused smokes, HubState/CampaignScenario regressions, changed-file closeout, `git diff --check`.
- Task overrides: `none`
- Deferred: full offer generation/recon; H5 retry/deploy; H6 outcome/return; production Forum art/audio.

## Claim-Time Dependency Refresh

This packet is intentionally `ready/auto` while its declared dependencies may still be incomplete. The dispatcher must keep it non-claimable until every `Depends on` workstream is archived `complete`. Once claimed, the execution agent must reconstruct the landed predecessor seams from current `main`, archived implementation/review summaries, and live public APIs before mutation. Reconcile private helper names and bounded implementation drift while preserving this packet's Goal, Completion boundary, Preserve, Non-goals, and Acceptance. Update directly stale packet/docs facts inside the workstream when needed. Do not stop for a ChatGPT/user refresh unless current evidence exposes a genuine unresolved design choice that existing authority cannot answer.
## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: After HR2 archives complete, H3 and H4 become auto-claimable in parallel and each self-refreshes from current main before mutation.
- Best starting files: reviewed H2 owner/Hub host; HubState/CampaignScenario/default factory; WorldContractBootstrap; H1 Dais marker.
- Blockers or open questions: persistent host/coordinator seam is an H2 output.