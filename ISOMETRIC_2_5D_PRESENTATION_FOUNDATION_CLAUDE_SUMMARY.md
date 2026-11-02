# Isometric 2.5D Presentation Foundation — Claude Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff
Coordination chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4

## What changed

- Added `IsometricPresentationProfile` (Resource: `visual_elevation_px`, `depth_band`, `sort_anchor_offset`; bands -300/-200/-100/0/40/90/100) and `IsometricVisualAnchor2D` (ground/sort root; elevation offsets only the `VisualRoot` child; no physics, collision, or navigation) under `custodian/game/world/presentation/isometric_2_5d/`, with a README documenting reuse of `RoofOccluder2D` and `blob_shadow.gd`.
- Added a Y-sort fixture and focused smoke `isometric_2_5d_presentation_foundation` (manifest entry, tier `unit`, `needs_import`).
- Updated the roadmap, packet README, FILE_INDEX, and the packet's Completion Truth/Execution Feedback.
- Untouched: `roof_occluder_2d.gd`, `blob_shadow.gd`, production scenes, camera, movement, collision, navigation.

## Evidence

- `run_validation.py --test isometric_2_5d_presentation_foundation`: 1 passed.

## Awkward parts

- The first smoke run failed on my own wrong assertion (null profile does not reset `z_index`; that is intended, so the test now uses an explicit GROUND profile).
- The "rear visual overlaps front" check is weak: it asserts the elevated extent geometrically rather than rendering. No rendered capture was taken (not required by the packet).
- Setting `profile` to null leaves a previously applied band z-index in place.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: first smoke assertion was wrong, fixed
- Root cause / contributing factors: test assumed null profile resets band
- Prevention / pipeline improvement: none
- Tooling / docs drift discovered: none
- Follow-up: none

## Next Handoff
- Next workstream: review-isometric-2-5d-presentation-foundation
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4
- Refresh reason: none
- Next action: fresh-context paired review before the Forum/Sundered slices.
- Blockers or open questions: none
