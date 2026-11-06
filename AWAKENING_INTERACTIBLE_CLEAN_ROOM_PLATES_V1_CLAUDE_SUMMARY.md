Workstream: awakening-interactible-clean-room-plates-v1

# Crèche canonical source staging closeout

## Scope completed

Replaced only the canonical Crèche Asset V2 `source_work` underlay and foreground masters with the exact user-approved 1464×1074 RGBA files. Preserved the prior source masters as Git LFS objects pinned at `origin/main` `fd706097f245274d5458bf920cef82f7dd2f3b83`, and recorded their OIDs and exact rollback command in the source-registration receipt.

The canonical inbox files remain absent. The family contract and live runtime remain 960×704. No family, inbox, runtime image, Godot scene, scene transform, collision/navigation geometry, or gameplay file changed. The downstream Crèche room/console cutover owns those changes and the required gameplay-scale user/ChatGPT review. No paired Codex review was run or represented as passing.

## Source proof

- Floor / underlay: SHA-256 `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`, 1464×1074 RGBA, alpha≥128 bounds `(47,242)–(1417,980)`.
- Wall / foreground: SHA-256 `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`, 1464×1074 RGBA, alpha≥128 bounds `(11,8)–(1452,1063)`.
- Both layers retain the exact authored pixel grid and shared 1464×1074 canvas; no resize, crop, offset, or re-export was applied.
- Durable registration and rollback evidence: `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md`.

## Validation and limits

The task-scoped packet/category, managed-index, review-pairing, AI-context, source hash/RGBA/alpha, rollback-object, and changed-file checks passed. The Asset V2 plan dry-run returned `can_apply=true`, zero sources/outputs/errors, and warned that the inbox directory is absent. That plan does not inspect source_work; it is recorded only as evidence that inbox/runtime intake remains deferred.

This source-only workstream does not validate the new floor geometry, collision/navigation, 01→02 route, console fit, Godot import, or gameplay-scale presentation. Those remain required for the downstream atomic cutover.

## Process Feedback

- Friction: medium. The earlier packet required inbox staging even though its active family contract still specifies 960×704 and the approved sources are 1464×1074.
- Cause: source_work preparation and runtime-ready Asset V2 inbox intake were conflated in the packet boundary.
- Prevention: keep source identity publication, canonical source_work replacement, inbox readiness, family migration, and runtime ingestion as separate gates; include active family dimensions in the dispatch-time source receipt.
- Tooling: the handoff installer correctly rejects `SOURCE_READY_NEEDS_TUNE` inbox promotion. `asset.py plan` inspects inbox only and reports no source work when inbox is absent.
- What worked: immutable LFS-published inputs, atomic byte replacement, exact hash checks, and the parent commit's LFS OIDs provide durable rollback without touching runtime state.

## Next Handoff

Refresh and dispatch `awakening-creche-console-sprite-reauthor-v1` after this source-only closeout. That workstream must update the family/inbox and runtime scene atomically, measure the walkable footprint, preserve the 01→02 route and console behavior, run the focused Awakening geometry/progression/collision/art-registration/console-animation validations, and present game-scale captures for direct user/ChatGPT review. Do not start an inbox or floor-only runtime intermediate.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
Current control chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aebed23-b464-83e9-93f8-d2560865c5da
