# Review: Awakening Handoff Readiness + Art Convergence V1

## Outcome

Completed fresh paired review `review-awakening-handoff-readiness-art-convergence-v1` against landed implementation `3374efec219d`. The prior human lock explicitly approves the 04/05 1502×2048 shared composition, root placement, and Dust→Connector→Locker ordering; the user's current direction accepts that lock and requires no second subjective sequence. No image vision pass or UI sequence was performed.

## Finding

- **R0-01 — material proof gap; correction required.** The review packet requires a derived exact-grow64 registration proof and underlay/foreground parity for all nine zone plates. The new `awakening_art_registration_smoke.gd` covers the seven standalone zones (01–03, 06–09) and the shared 04/05 composition, but its expected dimensions and centers are hard-coded rather than derived from `AwakeningLayout.ZONES`. Existing broad smoke asserts hidden 04/05 legacy texture dimensions and an intentionally deferred Zone04 foreground. The committed `awakening_04_05_registered_composition_v1.json` proves the approved composition's source hashes, alpha bounds/overlaps, root transform, and 1,025 floor samples; it does not form one complete Layout-derived registration contract or prove grow64 parity for the seven ordinary plates.
- The accepted shared 04/05 composition is an explicit exception to individual room-plate parity, supported by the archived prior human lock and registration report. That accepted presentation remains unchanged. The required correction is limited to machine validation and contract clarity; it must not edit presentation, source/runtime assets, transforms, or gameplay.

## Verification

After initializing this fresh worktree's Godot editor/import cache, these focused checks passed: art registration, Awakening boot, Awakening geometry, Awakening progression, registered composition traversal, connector Asset V2 contract, Road of Witnesses production, and HUD interaction prompt lease. The initial cold-cache registration run failed before meaningful assertions because imported `.ctex` files and global-class cache were absent. Editor import resolved it; only generated untracked Operator reference `.import` sidecars were produced and are excluded from the review commit.

Committed seam evidence was reused: ordered five-ROI manifest from run `20261009T112518-0400`, metrics, contact sheet, and all five 400×200 crops are present. Each ROI reports zero void ratio and no matte color. Discontinuity metrics remain diagnostic only. No changed-file sweep was rerun because the review made no implementation changes and the stated gap is in coverage, not a failing runtime behavior.

The progression smoke proves console/P-9 gating, one production event and one compatibility emission from the same once-only decision, plus data-only snapshot behavior. HUD lease coverage proves four-second readout dwell and overlay suppression; Crèche activation is exactly eight frames at 8 FPS and once-only. Geometry/Road checks preserve the 240×496 pylon blockers, open central route, Road's existing offset/anchor/gap, and continuous South Reach route. The live Awakening source adds no scene transition or Contract prewarm. Current ledger and later 2026-10-09 documentation identify the Road modular art as live and describe the shared connector's current registration; obsolete transforms remain only in explicitly historical records. I also removed the obsolete manual README section that still presented the earlier fade repair as active and indexed completed packets.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: The first focused Godot check used a cold worktree and emitted cache/import failures before validation assertions could run.
- Root cause / contributing factors: Godot's editor import and global-class scan had not run in the fresh worktree.
- Prevention / pipeline improvement: Initialize the headless editor cache once before focused scripts and remove only known generated untracked `.import` sidecars.
- Tooling / docs drift discovered: R0-01 captures the missing consolidated, Layout-derived registration proof. Repository-wide `check_ai_context.py` also reports 10 pre-existing findings in unrelated `ASH_BELL_RITUALANT_STATIC_ASSET_INTAKE.md`; those packet fields were left untouched.
- Follow-up: awakening-handoff-readiness-art-registration-proof-corrections-1
- What worked: Existing structured traversal, registration, and progression evidence kept the review objective and avoided subjective visual review.

## Next Handoff

- Next workstream: awakening-handoff-readiness-art-registration-proof-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Refresh reason: none
- Next action: After this review lands and archives, claim the bounded validation/contract correction and its paired fresh review before implementing Awakening→Hub transition work.
- Blockers or open questions: R0-01 must be resolved while preserving the approved 04/05 composition; no new art decision is required.
