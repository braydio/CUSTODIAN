# Sepulcher Memorial Court Existing Art V1

Workstream: `sepulcher-memorial-court-existing-art-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac

## Result

Added one visual-only Memorial Court presentation to the production Hub map lifecycle at the approved grave center `Vector2(-1984.0, -3200.0)`. It binds the reused, source-derived floor and witness-ring outputs and a separate native-scale wall-module preview. It does not own or change navigation, collisions, grave-event positions, save state, or the Memorial Slab.

### Per-asset outcome

- **Floor:** Reused the verified `paving_base` source (SHA-256 `414b017edbcc1ba53e4d277e32b4dfb42752552a4be2a1a2ad764a3706eeb960`). Installed target is 512×512 RGB, SHA-256 `ea3cd7805a43eb72a0227a38fdf17e80bdc6ade78bd1d9969d7a22cab03f6c0b`. Asset V2 job: `job_20261107T105354Z_c800b281`. Imported and bound in the production scene. The measured 3×3 join differences were mean 10.437, median 8.667, p95 26.333, max 47.667 across 6144 adjacent-pixel channel-average samples; internal mean was 11.223. The result supports this bounded court placement, not a general seamless-repeat claim. Asset catalog `runtime_verified` remains false.
- **Witness ring:** Reused verified `witness_ring_inlay` (source SHA-256 `800de773be5ef49333b4d2568a2c1d7160f36320c9ed251462bbb9d20ed10797`). Installed target is true RGBA 512×512, SHA-256 `ecad5b82071921d0b6d3dfda39a3b531744e154f29520f490264b8c0959ebf77`; alpha is preserved. Asset V2 job: `job_20261107T105354Z_dcc9eba8`. Imported and bound; broken ring is centered around the unchanged slab. Asset catalog `runtime_verified` remains false.
- **Low side wall:** Reused verified wall master source SHA-256 `94b172344d5d4e73329ba86135af6554563833eb7c21eb998e6e253af34e7a4c` as a distinct 256×128 RGBA native-scale module preview, target preview SHA-256 `ad8f830cd4c4edef87c1c78408f9fca2fdb11f6d2f488f9585b1084dd7887d6d`, included in Asset V2 job `job_20261107T105354Z_dcc9eba8`. The presentation places one module at the authorized north margin with bottom contact at the court edge. The planned 512×192 production target remains pending; no stretching or false target completion was done. The full-strip source was excluded because its supplied hash conflicts with the handoff's internal checksum.
- **Damage overlay:** Intentionally deferred. The full-tile flaked-wear patches were visually too broad and risked competing with the ring.
- **Marker footing:** Still requires a newly generated and approved source; state remains pending.

No source images were regenerated or painted. Original archive SHA-256: `bb7e2677ed46366ade16e0234a378fadc2785898afa865ade6093de2513ee694`. Runtime-source archive SHA-256: `f7fa7f7adef078ab2bce8386a8e69b9c979b56bba9ea521a9e7c95d6ac8d5d18`. All four original source hashes and handoff internal checksums were verified after safe ZIP path inspection.

## Runtime and captures

The focused presentation smoke passed: exactly one helper, expected floor/ring/wall-preview texture bindings, unchanged slab/event anchors and three inspection/two resolution points, unchanged collision/navigation, and no duplicate art through reload/state transitions. Existing pilot presentation modes were run and preserved.

Production Vulkan captures from the actual Hub map, production event, and gameplay camera are in `/tmp/sepulcher_memorial_court_capture/` pending the paired review's compact Dropbox handoff. Each is 1280×720 RGB:

| Capture | SHA-256 |
|---|---|
| `court_approach_east.png` | `db32f8a833f2ec294fe4a827ff02164218e350dc92216a560756fea4eeb82f20` |
| `court_before.png` | `566b52c1864f70b3595f6c2973ebcfe657b7357871cc34a5a03929c4ae1a4fc6` |
| `court_after.png` | `16bd5ed075e081396a38f74b9e304048286579df37f0145426b14567b9ab8f5a` |
| `court_full_contact.png` | `d151e1f028243d66b648458f9d5d31a05e31b464b4a773606352882ef050fbb3` |
| `court_interaction_clearance.png` | `37929e01d4e5a6b149b693ab1f92788cc5453b76ce76c22be307cbd99be912b7` |

The matched before/after views use the same camera and Operator world positions. The interaction diagnostic shows the three grave inspection locations, two resolution locations, Operator approach, and preserved clearances. Exact captures and the subjective composition questions will be handed off by the paired review, with the authoring chat URL above.

## Validation

- Memorial Court presentation smoke: PASS.
- `hub_sepulcher_grave_evidence_smoke.gd`: PASS.
- `hub_sepulcher_grave_resolution_smoke.gd`: PASS.
- `hub_first_set_blockout_smoke.gd`: PASS (15,471 walkable cells, 438 boundary segments, 14 markers).
- Asset V2 plan/status: floor 1/1 required ready; landmark family ring present, wall target and footing absent, preview present. `asset.py needs --check`: PASS.
- Asset V2 ingests applied through supported CLI for only approved/valid floor and ring states and separately identified wall preview. `asset.py doctor` reports four unrelated pre-existing awakening-locker hash mismatches (`authorize_open`, `closed`, `empty`, `open_loaded`); no Memorial Court state errors were reported. The catalog `runtime_verified` flags remain false.
- Hub art manifest validation: PASS.
- Changed validation report: `/tmp/memorial-court-validation.json`, PASS, 16 selected / 16 passed, zero failures/timeouts/infrastructure errors, stable source identity, no uncovered files. This report will be refreshed after packet closeout edits before lifecycle finish.
- `git diff --check`: PASS before packet closeout edits.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: One manifest update command ran from the persistent root checkout instead of the dispatcher worktree; the unrelated existing root Markdown edit was preserved and the accidentally changed, previously clean root JSON was restored from HEAD. The first changed validation detected Godot-generated script UID files and the next run detected the capture script was missing from the validation ownership map.
- Root cause / contributing factors: An omitted explicit workdir and a new capture script not yet listed as a validation owner.
- Prevention / pipeline improvement: Use an explicit workdir for every repo command and check `git rev-parse --show-toplevel` before metadata writes; list every changed support script in its focused validation owner map.
- Tooling / docs drift discovered: none
- Follow-up: paired fresh-context review
- What worked: Exact source/runtime handoff bytes and the published Asset V2 install path were reused without image edits.

## Next Handoff

- Next workstream: `review-sepulcher-memorial-court-existing-art-v1`
- Next packet state: dependency-gated until this implementation lands and archives complete
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac
- Refresh reason: none
- Next action: fresh-context paired review, followed by the scoped visual handoff if the reviewer confirms a material subjective composition question remains.
- Blockers or open questions: 512×192 wall target, marker footing source, and subjective approval of the square court edge/single wall module remain explicitly pending as described above.
