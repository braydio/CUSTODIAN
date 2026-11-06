# Crèche canonical source staging and registration receipt (2026-11-06)

- Workstream: `awakening-interactible-clean-room-plates-v1`
- Scope: exact approved source_work replacement only; no inbox, family, runtime, scene, geometry, or gameplay mutation.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Current control chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aebed23-b464-83e9-93f8-d2560865c5da
- Rollback anchor: `origin/main` source masters at `fd706097f245274d5458bf920cef82f7dd2f3b83`; the original source files remain addressable by their Git LFS OIDs below.

## Source identity and preimage

| Role | Canonical path | Prior SHA-256 / LFS OID | Approved SHA-256 / LFS OID | Canvas | Alpha-zero pixels | Alpha ≥128 bbox (inclusive) |
|---|---|---|---|---|---:|---|
| floor / underlay | `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png` | `f4e6586bed8efa7e3b9c10c0a271d3caa3d09b4ccfd904601bd95f797d8b2ca9` | `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a` | 1464×1074 RGBA | 642939 | (47, 242, 1417, 980) |
| wall / foreground | `custodian/asset_drop/source_work/awakening/awakening_creche_environment/foreground_source.png` | `1b3944558d2879cd5b17f2e3eb7a172b6f653143e5e053acbe5802ae9d1340cf` | `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc` | 1464×1074 RGBA | 835509 | (11, 8, 1452, 1063) |

Both originals were copied byte-for-byte from the immutable preclaim publication paths. SHA-256 was verified before and after atomic replacement. No resize, crop, color conversion, or re-export occurred.

## Registration evidence

- Both authored layers have the exact same 1464×1074 canvas; this is pixel-grid registration proof only, with no inferred in-engine acceptance.
- Source anchor transform: identity pixel grid (no scale, rotation, crop, or offset). Their centered canvas origin is `(732, 537)`; the current scene's `Underlay` and `Foreground` remain centered at `(0, -32)` and were not edited in this workstream.
- Coordinate reference only: the existing console body node at world `(105, 118)` maps to canvas `(837, 655)` and its interaction at `(112, 144)` maps to `(844, 681)` under a 1-pixel-per-world-unit centered canvas. This receipt does not certify walkability, collision, navmesh, visual fit, or the future runtime scene transform.
- Floor alpha ≥128 extent: `(47, 242, 1417, 980)`. The approved foreground alpha ≥128 extent: `(11, 8, 1452, 1063)`. Both contain true alpha-zero pixels; alpha extrema are `(0, 255)` and `(0, 255)`.

## Rollback and deferred gates

- Prior source bytes are preserved in the parent commit `fd706097f245274d5458bf920cef82f7dd2f3b83` as Git LFS objects `sha256:f4e6586bed8efa7e3b9c10c0a271d3caa3d09b4ccfd904601bd95f797d8b2ca9` and `sha256:1b3944558d2879cd5b17f2e3eb7a172b6f653143e5e053acbe5802ae9d1340cf`. Roll back only these paths with `git restore --source=fd706097f245274d5458bf920cef82f7dd2f3b83 -- custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png custodian/asset_drop/source_work/awakening/awakening_creche_environment/foreground_source.png`; do not reset the workstream or alter unrelated files.
- The existing family remains 960×704 while these approved sources are 1464×1074. The two canonical inbox paths were absent before this task and remain absent. Do not set `RUNTIME_READY`, install inbox files, change the family schema, run an ingest, or claim an Asset V2 runtime cutover here.
- `awakening_creche_environment.asset.json`, runtime PNGs, `.import` sidecars, scene resources/transforms, spatial geometry and gameplay authority were not modified.
- The matching family update, inbox intake, reviewed Asset V2 plan/ingest, Godot import, measured walkability/collision/nav, console integration and gameplay-scale human review remain in `awakening-creche-console-sprite-reauthor-v1` under the authoring chat's explicit resolution.


## Asset V2 plan observation

- Command: `python3 custodian/tools/assets/asset.py plan awakening_creche_environment --json`.
- Result: `can_apply=true`, `source_count=0`, `output_count=0`, no errors, with warning `inbox does not exist: custodian/asset_drop/inbox/awakening_creche_environment`.
- This plan inspects the Asset V2 inbox, not the `source_work` masters. It is recorded as a non-mutating downstream intake check and does not validate source registration or mean runtime readiness. The absent inbox is intentional under the authoring chat's source-only boundary.
