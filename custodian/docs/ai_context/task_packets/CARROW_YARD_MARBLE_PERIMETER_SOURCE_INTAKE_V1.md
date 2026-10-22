# CARROW YARD MARBLE PERIMETER SOURCE INTAKE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `carrow-yard-marble-perimeter-source-intake-v1`
- Authoring handoff: `auto`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `carrow-yard-art, asset-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, visual, runtime`
- Paired review workstream: `review-carrow-yard-marble-perimeter-source-intake-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new immutable source imagery plus exact crop, provenance and scene preview checks`
- Reviewed main: `29b0dc57bf54`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f`
- Visual review: `required`
- Goal: Stage and verify the selected real ruined-marble Carrow source slices and provide six reproducible native-scale Godot assembly examples for human seam, camera, gate and perimeter-layout review, without claiming runtime approval.
- Completion boundary: Verify the exact SHA-256-identified Dropbox package and internal files, preserve three masters, install three source-ready-needs-tune RGBA crop states into existing `carrow_yard_perimeter_walls_v1` source-work, reproduce the original clean L pixel-exactly, measure native-scale seam/repetition/underlap behavior, reconcile active Carrow art docs and provisional existing family, and deliver the SIX actual-source assembly gallery views, schema-backed placements, seam failures and 32px-Operator screenshots specified in `ASSEMBLY_GALLERY_SPEC_V1.md`, plus an evidence-led human approval gate. NO normalized inbox, ingestion, or gameplay runtime binding absent a separate human visual approval.
- Current measured state: Existing blocked `agent/carrow-yard-volumetric-perimeter@d033eef4f` is historical preserved donor evidence only, not to be claimed, reset, archived or fast-forwarded by this packet. Main has no marble sources or family contract at packet authoring; Carrow V2 doc retains superseded six-piece and mapper-next language. Three new cropped pieces have lossless clean-master assembly, but repeated seam pitch, N-S underlap offset/z-order, game-world anchors and native visual approval remain unresolved.
- Evidence: Published Dropbox package and original references documented below; manifest SHA-256s; exact source crop rectangles; source L proof; historical failed prior-art seam records; tracked `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/ASSEMBLY_GALLERY_SPEC_V1.md` defines six required real-source examples.
- Task-specific authority: `design/04_architecture/ASSET_PIPELINE_V2.md`; `custodian/tools/assets/asset_handoff_installer.py`; `custodian/tools/assets/asset.py`; `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; `design/05_levels/CARROW_YARD_INTERIOR_SCALE_AND_LAYOUT_V2.md`; `design/03_world/locations/CARROW_YARD.md`; root/custodian `AGENTS.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/`; `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/`; `custodian/scenes/debug/carrow_marble_perimeter_assembly_gallery.tscn`; `custodian/tools/validation/carrow_marble_assembly_gallery_smoke.gd`; bounded gallery preview/testing surface; `custodian/content/metadata/assets/families/carrow_yard_perimeter_walls_v1.asset.json` only if needed to capture unverified source states; active Carrow art docs.
- Publication inputs: `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/source_batch.md`, `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/verify_marble_slices.py`, `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/ASSEMBLY_GALLERY_SPEC_V1.md` (published with this packet); package's immutable Dropbox path and SHA-256 are durable external art transport; existing `custodian/tools/assets/asset_handoff_installer.py` is the safe source installer.
- Change: Use durable batch lookup (rclone `git-dropbox-sync:/CUSTODIAN/asset_batches/` or connected Dropbox), verify whole archive SHA and extracted manifest/file hashes BEFORE mutation, run installer dry-run then copy only approved SOURCE_READY_NEEDS_TUNE sources, preserve original existing sources, validate exact L reconstruction, construct six distinct gallery examples from the original PNGs without resampling (three E-W, three N-S underlap, corner L, 160px gate gap, labeled incomplete full ring, actual Operator), write `assemblies.json` with per-piece crop/position/z and per-join PASS/FAIL/UNVERIFIED, capture actual Godot screenshots, retain honest 0/3 runtime readiness until human acceptance.
- Preserve: User's earlier E-W and two-layer N-S visual tests; all seven earlier Carrow source states; historical blocked branch and local worktree; Camera2D 32px XY ownership; route/gameplay/collision/upper walkway semantics; unrelated locker doctor issues; active source records.
- Non-goals: No 3D runtime migration, automatic art regeneration, re-ingestion of older seven assets, claim or recovery of historical blocked workstream, elevated navigation, migration of Carrow routes, false ready status, or alpha-derived collision.
- Acceptance: (A1) Exact archive + internal source SHA checks pass; (A2) exactly three expected states and untouched masters preserved; (A3) cropped pixels reconstruct clean 1312x1199 master exactly under alpha<=3 cleanup, without scaling; (A4) six separate interactive Godot preview views and complete deterministic screenshots/`assemblies.json` are produced exactly as `ASSEMBLY_GALLERY_SPEC_V1.md` requires: E-W triple-repeat, N-S triple-repeat with two-layer underlap, original L with both connector checks, 160px world-grid gate gap, four-sided proposal explicitly marking missing corners, and actual Operator native-scale comparison; seam offsets/z-order/crop/draw order recorded even on FAIL; (A5) source-intake state truthful, no inbox/ingest or implied approval; (A6) active Carrow docs reconciled without erasing legacy plans or touching historical donor claims; (A7) human visual gate explicitly remains pending until a later approval.
- Validation: `sha256sum` the ZIP and three source candidates against this packet; `python3 custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/verify_marble_slices.py <extracted-package-root>`; `python3 custodian/tools/assets/asset_handoff_installer.py --repo <repo> --dry-run` from extracted package; focused Godot gallery smoke and six actual-render screenshot checks at actual Operator zoom; independent verify no false seam PASS, fixed 160px gate clearance and true source SHA;  `python3 custodian/tools/assets/asset.py status carrow_yard_perimeter_walls_v1`; changed-file validator; `git diff --check`; independent review.
- Task overrides: `none`
- Deferred: Full module tileability acceptance, final normalized dimensions, corner collision anchors, actual elevated walkability, and asset intake are separate human-gated work.

## Durable source batch on Dropbox

- Root: `/CUSTODIAN/asset_batches/`
- Archive: `custodian_carrow_yard_marble_corner_slices_handoff_v1.zip`
- Full path: `/CUSTODIAN/asset_batches/custodian_carrow_yard_marble_corner_slices_handoff_v1.zip`
- SHA-256: `9079d308412f3c1cef3840d730bb9234da074ad8f09232e8db6be20509b92392`
- Unpacked package root: `custodian_carrow_yard_marble_corner_slices_handoff_v1/`
- Package includes `MANIFEST.json`, original source masters, three PNG slices, `CODEX_IMPLEMENTATION.md`, `QA_REPORT.md`, deterministic slicer and review images.
- Individually uploaded reference masters in same Dropbox root: `carrow_marble_clean_ne_master.png`, `carrow_marble_double_ns_reference.png`, `carrow_marble_damaged_right_end_reference.png`. These are reference conveniences only; the SHA-identified archive is authoritative. The damaged-right-end master must not be used for crop output.
- Existing older 7-source batch: `custodian_carrow_yard_exterior_source_set_asset_handoff_v1.zip`, preserve and reconcile; do not substitute it for this marble revision.

| State | Dimensions | SHA-256 | Source crop x0,y0,x1,y1 | Placement x,y |
| --- | --- | --- | --- | --- |
| `wall_marble_ew_straight_01` | 805x684 | `af152f20218ee342c15ce8e51e28a95e936900d31271a82c7f4a31c565613368` | 0,505,805,1189 | 0,505 |
| `wall_marble_ns_straight_01` | 492x505 | `68e8d14f24baf0e46496df6fd2ea9e0ccb06b1d56d1551c66512c18db42d65c2` | 820,0,1312,505 | 820,0 |
| `wall_marble_corner_ne_01` | 507x684 | `f9074c4b64baa5301c3d74261e1dafa078a55ba3ac78e1176200e8dd4c487032` | 805,505,1312,1189 | 805,505 |

All three are RGBA, one frame, `SOURCE_READY_NEEDS_TUNE`. The source workstream must produce six Godot-rendered examples, not an AI-generated replacement concept sheet. Gallery specification: `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/ASSEMBLY_GALLERY_SPEC_V1.md`. ZIP manifest is `custodian.asset_handoff.v1`, not a semantic family contract; do not treat its `install_source` approval as runtime readiness. Expected source destination prefix: `custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/`.

### Zero-search retrieval

```bash
set -euo pipefail
STAGE="$(mktemp -d)"
rclone copyto 'git-dropbox-sync:/CUSTODIAN/asset_batches/custodian_carrow_yard_marble_corner_slices_handoff_v1.zip' "$STAGE/carrow.zip"
echo '9079d308412f3c1cef3840d730bb9234da074ad8f09232e8db6be20509b92392  '"$STAGE/carrow.zip" | sha256sum -c -
unzip -q "$STAGE/carrow.zip" -d "$STAGE"
PKG="$STAGE/custodian_carrow_yard_marble_corner_slices_handoff_v1"
python3 custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/verify_marble_slices.py "$PKG"
python3 "$PKG/INSTALL_INTO_REPO.py" --repo "$(git rev-parse --show-toplevel)" --dry-run
```

The ZIP does **not** contain `INSTALL_INTO_REPO.py` at authoring time; copy the current repository's audited `custodian/tools/assets/asset_handoff_installer.py` into the unpacked package root as `INSTALL_INTO_REPO.py` before running the last dry-run command, or invoke the maintained installer with equivalent checked semantics. Never run a stale installer from another package.

## Historical workstream fencing

- `agent/carrow-yard-volumetric-perimeter@d033eef4f` contains the previous (rejected) wall-art pass and an already blocked protected packet. Preserve as historical donor. No claim, force push, reset, branch recreation, archive or merge.
- Before touching shared Carrow art paths, run `python3 custodian/tools/agent/dispatch.py audit --json`, inspect `carrow-yard-volumetric-perimeter` for a live protected run, and stop if an actual competing owner is modifying the same paths; do not infer ownership from a stale branch alone.
- Separate source-work publication is deliberately independent of the old volumetric geometry/runtime scope. If there is any real concurrent claim collision, defer and report instead of stealing a lock.

## Handoff

- Next workstream: `carrow-yard-volumetric-perimeter` (existing blocked donor; human-led refresh only, never automatically claimed)
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f`
- Refresh reason: Only after source-intake review may the remaining camera/footprint/normalization/runtime presentation work be refreshed using the new marble candidates.
- Next action: Return six native-scale real-asset Godot examples, quantitative seam/underlap coordinates, gate geometry and missing module list for human review.
- Blockers or open questions: Exact repeat pitch and N-S underlap offsets/draw order are not independently verified; human runtime art approval pending.
