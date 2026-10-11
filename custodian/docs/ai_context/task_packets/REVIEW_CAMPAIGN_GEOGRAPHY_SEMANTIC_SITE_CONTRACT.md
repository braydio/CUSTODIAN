# REVIEW: F15-B2 Canonical Geographic Semantic Site and Edge Binding Contract

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-campaign-geography-semantic-site-contract`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `campaign-geography-semantic-site-contract`
- Locks: `campaign-geography-semantic-contract`
- Review: `none`
- Review target workstream: `campaign-geography-semantic-site-contract`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_CONTRACT.md`
- Reviewed main: `84c7eb1f8a2ee8c2e4936b9df9afa8ea7e1672d1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify B2's address-keyed semantic/F02 source mapping without crediting it for unimplemented multi-site physical traversal, geography scaling or world streaming.
- Reviewed implementation acceptance: Exact implementation packet's **B2-01 through B2-08**: deterministic plan by immutable Domain+Location; reciprocal/directed edge consistency; atomic invalid provenance/unknown F02 source/truth-cue rejection; physical ingress unverified by default; optional Hall data metadata only; no Godot game nodes, F02 terrain or route mutation; focused smoke/negative mode and changed-file coverage; current-state truth.
- Review evidence: Newly archived B2 packet + required implementation closing summary and actual landing commit, live data-only B1 registry/visit code, F02 `LevelLoader` and `GeneratedRegionLevel` source/level/route definitions, new B2 sidecar, new smoke and validation manifest, B1 independent review evidence. Fresh implementation trace is a **claim**, not proof.
- Correction threshold: Only confirmed B2-01 through B2-08 defect or **material acceptance evidence gap** yields a bounded review-correction pair. F15-C physical traversal, F02 scene materialization, semantic art placement, F14-C2 population and subjective scenic preferences are **deferred** and cannot be invented as B2 blockers.
- Focused validation: In fresh reviewer worktree run Godot editor import before headless fixture. Check exit 0 plus literal new B2 PASS and expected nonzero negative control, not just a printed log line. Independently mutate two sources: (1) reciprocal B1 edge with inconsistent paired site-ingress declarations and (2) valid address plus unsupported F02 reference or forged `verified` physical ingress. Both must fail without partial registration. Recreate registry in different order and confirm identical canonical plan and B1 key/seed. Run B1 smoke, explicit changed-file selection via `custodian/tools/validation/run_validation.py --changed --base <landed-commit-parent> --test <new-owner-id> --json`, `git diff --check`; verify manifest covers all new files. Avoid unnecessary expensive two-site generation runs.
- Review focus: `CampaignGeographyRegistry` remains sole topological owner; F02 remains physical/generator authority; avoid `geo-v1` schema shadow authority, changing locality provenance, accepting a map label as permanent location address, assuming geographic adjacency implies a live route, or claiming true Encounter Language cues without referenced state. Dotted-ID canonical encoding and duplicate/partial-plan handling are high priority.
- Acceptance: Fresh-context, findings-first post-land review receipt with implementation main SHA and evidence matrix B2-01..08. Each issue gets stable `R0-NN`, one severity class, domain, affected acceptance, source evidence, action/disposition and rationale. `passed` only when zero blocking defects/material proof gaps; for blocking cases author the standard **delta correction + fresh re-review pair** within max 2 cycles. Do not patch implementation code in review. Archive review with source-backed summary and exact authoring-chat backlink.
- Non-goals: Do not build B2, add geography gameplay, repair all procgen issues, modify actor management, approve art/visuals, or create B2 successor/C2b packets. Do not require C2a to be complete to review B2.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Reviewer independence and exit

1. Claim only when B2 archived `complete` on main, and start from **new, fresh** agent context. Read root/local AGENTS, the archived packet, live code, accepted geography doctrine and `custodian/docs/ai_context/prompts/review_runtime_change.md`.
2. Reconstruct actual A/B locality edges, source declarations and semantic plans from repository evidence. Challenge referential validity, ordering and `verified` labels with mutations, not only author's happy-path tests.
3. Record findings-first receipt in archived target; assign correction-worthy issues to a separate workstream, never this reviewer. Close/archive with feedback and exact chat URL.

## Next Handoff

- Next workstream: `none`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: `Actual B2 F02 binding proof and accepted semantic fields must inform C2b's physical ingress/residency plan and F15-C later visible traversal; neither is approved now.`
- Next action: Return independent B2 receipt and validated site/edge/ingress semantics to the planning conversation for scoped C2b/F15-C gate evaluation after C2a.
- Blockers or open questions: `No human art review for metadata-only B2; physical streaming, world scale and valid multi-site ingress remain deferred outside review.`
