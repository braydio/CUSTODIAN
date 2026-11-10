# REVIEW: WEATHER V2 REVIEW SOURCE-PROVENANCE BRIDGE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-weather-v2-review-source-provenance-bridge-v1`
- Category: `agent-ops`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `weather-v2-review-source-provenance-bridge-v1`
- Locks: `paired-review-source-provenance`
- Review: `none`
- Review target workstream: `weather-v2-review-source-provenance-bridge-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/WEATHER_V2_REVIEW_SOURCE_PROVENANCE_BRIDGE_V1.md`
- Reviewed main: `8e23d8b5418d7298dccc438c430652fe66d96333`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af2865a-62e0-83ea-b08d-d591648b381e
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the Weather V2 source-provenance bridge admits only the authentic historical source and archive sequence while preserving all normal paired-review validation behavior.
- Reviewed implementation acceptance: Verify every acceptance item in the archived `WEATHER_V2_REVIEW_SOURCE_PROVENANCE_BRIDGE_V1.md`, especially private receipt digest and semantic validation, the exact source span and archive transitions, fail-closed negative controls, and preservation of the held Weather run.
- Review evidence: Reuse the durable evidence manifest `custodian/docs/ai_context/provenance/weather_v2_presentation_contract_v1.json`, focused test results and implementation summary. On the authenticated host, inspect the original private receipts read-only and verify the exact held-run recovery plan without applying it. Do not treat the implementation summary alone as proof.
- Correction threshold: Create correction work only for a confirmed bridge defect or a material evidence gap preventing confidence in an acceptance claim. Record stable review finding IDs and route any correction through the normal correction/re-review lifecycle. Do not manufacture a PASS to unblock Weather work.
- Focused validation: Run the focused provenance-verifier tests, `python3 custodian/tools/agent/test_paired_review_runner.py`, changed-file validation, and the exact held-run host-validation recovery `--plan` after the bridge is landed. Confirm the PR #126 owner-exception tests remain passing and legacy trace-backed source spans are unchanged.
- Review focus: Confirm the manifest is complete and contains no private receipt bytes or absolute host paths; verifier reads the exact seven records without modifying them; acquisition definition hash follows the V2 dispatcher's canonical packet hashing; only the pinned Weather workstream and held run are eligible; source paths, modes, blobs, commit parents/trees, validation-manifest union, checkpoint, and archive transition are exact; malformed, altered, missing, duplicate, replayed, or cross-workstream evidence fails closed; existing owner-exception and ordinary trace validation stay independent; and the original Weather reviewer is not launched or marked accepted by the bridge.
- Acceptance: Produce a findings-first independent review of the landed bridge. Record a `passed` receipt or concrete findings with stable cycle-scoped IDs, evidence, affected acceptance, disposition, and rationale. A successful bridge review establishes only the bridge; the preserved Weather review remains unresolved until its own authentic reviewer outcome is recorded.
- Non-goals: Do not modify the bridge implementation, original Weather runtime implementation, original Weather review run, or unrelated owner-exception behavior. Do not apply held-run recovery, launch its reviewer, or accept the Weather V2 presentation review in this workstream.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Publication inputs: `custodian/docs/ai_context/provenance/weather_v2_presentation_contract_v1.json`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/turn_dispatcher_v2.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/task_packets/archived/WEATHER_V2_PRESENTATION_CONTRACT_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_WEATHER_V2_PRESENTATION_CONTRACT_V1.md`; `custodian/docs/ai_context/turn_handoffs/weather-v2-presentation-contract-v1.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`

## Authoring handoff

Do not claim from this temporary `draft/manual` publication state. The pair is explicitly opted into the atomic authoring handoff; after both packets and the evidence manifest land on `origin/main`, the handoff must validate and promote both packets to `ready/auto`. Claim only after the promoted pair is verified on `origin/main` and a fresh dispatcher audit confirms eligibility. No human design decision is pending.

## Procedure

1. Claim only after the bridge implementation is complete and archived on `origin/main` and the dispatcher confirms eligibility.
2. Start a fresh reviewer context. Reconstruct the contract from the archived implementation packet, evidence manifest, live code, tests, and actual host-private receipt identities.
3. Do not edit the implementation under review. Preserve the original held Weather review and its evidence.
4. Run the smallest focused tests that establish each acceptance claim. Inspect exact source and Git object identities rather than trusting commit messages or summaries.
5. Record findings first. If the bridge is valid, report only bridge acceptance; do not infer that the original Weather review has passed.
6. Complete and archive this review through the supported workstream lifecycle.

## Handoff

After the bridge review, the immediate successor remains the preserved `review-weather-v2-presentation-contract-v1` run. It may recover only through its exact authenticated same-run host-validation procedure after bridge acceptance. The successor must produce a genuine independent Weather review outcome; this bridge review cannot satisfy or replace it.
