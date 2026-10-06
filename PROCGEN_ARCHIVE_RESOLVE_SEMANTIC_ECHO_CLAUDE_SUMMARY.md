# PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO (AR3) — interim summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4

**Status: implemented and objectively validated; waiting on human visual/game-feel approval. Packet NOT archived, NOT landed.**

## What changed
- `ProcGenPresentationClass` (new): five bounded classes (natural/road/constructed/wall_cliff/major_landmark), echo leads 0–130 ms.
- `ProcGenRevealPresentation`: lazy class query + one-shot echo write only for *committed* first-resolve cells (uncommitted cover carries no class data); reacquisition skips echo, settles in 0.12 s, shader scales registration/misregistration by 0.35; one-time ingress wave (`begin_ingress_resolve`) with settled pocket, outward over ~1.0 s (+0.18 resolve); settle loop no longer assumes FIFO.
- `archive_resolve.gdshader`: class-styled faint echo, reacquisition scaling.
- `ProcGenTilemap`: `get_archive_resolve_presentation_class()` (read-only), one-time `begin_archive_resolve_ingress()`, `main_playable_component_query_count` (observability).
- `ContractWorldLoader`: ingress trigger after late placement (Gothic connection), immediately before camera refresh; install trace validation seam.

## Evidence
- New: `procgen_archive_resolve_semantic_echo`, `contract_world_archive_resolve_ingress` (real loader, real registered ingress + Gothic gate; ordering, exact final tile, canonical validity/main component, zero added component queries). Negative control: removing the trigger fails the integration smoke.
- Green: procgen_archive_resolve_shader, procgen_reveal_presentation, pause_aware_streaming, chunk_lifecycle, payload_cache, distant_chunk_unload, runtime_health, region_frame, world_ingress_spawner, spawn_validity, ingress_spawn_clearance, camera_presentation_subject_constraint, S1 quick (fingerprint 1773840677).
- Moment Forge `procgen/archive_resolve_semantic_echo_review`: ingress settles ≈1.2 s, reacquisition settle 0.133 s vs first resolve ≤0.33 s, pocket never veiled.
- Dropbox: `/CUSTODIAN/visual_review/procgen-archive-resolve-semantic-echo/20261006T092059Z/REVIEW_MANIFEST.json`. **Human decision: pending.**

## Awkward parts
- First class mapping was wrong on real maps: `authored_landmark` material covers the spawn hardstand and `fortress_exclusion_cells` is a large ellipse, so 569/574 echoes read as landmark. Found only via the renderer probe; unit smoke missed it. Now landmark = Sundered Keep `terminal_apron_cells` claim only; `authored_landmark` material counts as constructed. Packet text should be updated accordingly.
- Moment Forge fixture commands need registration in `moment_action_driver.gd`.
- Install-time spawn selection makes 2 component queries, not 1 (pre-existing; AR3 adds 0).
- Constructed ground (~40% of floor) dominates the echo; review it for "too much".

## Reminder
Root checkout `CUSTODIAN` (main) still has an uncommitted `BRANCH_ARCHIVE.md` change from the branch-retirement run — return there to commit it.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: landmark class over-broad until renderer probe; fixture command registration missed first.
- Root cause / contributing factors: assumed material/claim names matched hero semantics without probing a real map.
- Prevention / pipeline improvement: probe class distribution on a real generated map before wiring.
- Tooling / docs drift discovered: packet's "authored-landmark material" wording is too broad.
- Follow-up: none
- What worked: lazy per-tile class query; integration trace seam.

## Next Handoff
- Next workstream: procgen-archive-resolve-semantic-echo
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4
- Refresh reason: none
- Next action: record visual decision on the Dropbox manifest; then resume, fill packet Completion Truth, archive, finish, run Dropbox cleanup command.
- Blockers or open questions: human visual approval
