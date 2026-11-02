# REVIEW Existing Commanded Droid Hardening

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-showcase-existing-drone-hardening`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-showcase-existing-drone-hardening`
- Locks: `drone-runtime`
- Review: `none`
- Review target workstream: `npa-showcase-existing-drone-hardening`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_SHOWCASE_EXISTING_DRONE_HARDENING.md`
- Reviewed main: `44d49b7dd91fc8dc603be1b2a63be91a3246b028`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the landed existing commanded drone/droid showcase hardening against actual real-scene command paths, registered validation ownership and the accepted NPA-7 policy without reimplementing either.
- Reviewed implementation acceptance: Check all eight numbered acceptance items in the archived NPA_SHOWCASE_EXISTING_DRONE_HARDENING.md, especially genuine manager→production AlliedInfantryDroid command/guard/recall, nav, cap/replacement state, scene/status and manifest-owned smoke; confirm NPA-7 projectile/relationship proof remains canonical.
- Review evidence: Exact landed implementation commit, archived packet and summary, real-scene command smoke and data, changed validation_manifest.json test IDs/owners, original direct smoke outcomes, NPA-7 archived implementation and review, real projectile regression, Godot resource/import logs and based validation JSON.
- Correction threshold: Missing live manager/droid integration or command/guard/recall behavior, fake helper-only tests, changed/duplicate targeting or player-input owner, false projectile-safety result, cap/replacement/stale target regression, wrong manifest ownership, false scene/status/art claim, or a material validation-proof gap.
- Focused validation: Re-run actual registered production droid/manager smoke, commanded_ally_targeting_contract, allied_drone_navigation_walkability, actor_relationship_contract, existing direct smoke coverage as registered/needed, complete changed-file validation --base origin/main, pairing/index/AI-context. Respect import preflight, Godot fatal logs and writable-coordinator boundary for Git checks.
- Review focus: Insist on authentic main-scene AlliedInfantryDroid and DroneManager evidence, existing droid stability and no NPA-7 duplicate; verify all meaningful smoke source ownership, negative controls, observed nav and command transitions, hardening when runtime already correct.
- Acceptance: Findings-first independent receipt with zero blocking findings and zero material evidence gaps for pass. Use stable cycle R<cycle>-NN IDs and bounded correction/re-review where needed; do not patch the reviewed implementation.
- Non-goals: Do not create M-7, assets, gameplay policy, a new squad system, or edit reviewed implementation; no unrelated actor changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff
- Next workstream: `npa-showcase-existing-vaultwing-proof`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Vaultwing proof has an independent review/runtime gate; this drone review does not automatically release it.
- Next action: Check actual archived review proof before promoting any successor; retain human gates explicitly.
- Blockers or open questions: Vaultwing proof still depends on separately reviewed hardening and world-spawn integrity; no duplicate review claim is authorized.
