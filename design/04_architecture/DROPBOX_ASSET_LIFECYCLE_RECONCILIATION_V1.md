# Dropbox source artwork → CUSTODIAN Asset V2: lifecycle reconciliation design

**Status:** implemented tooling on main; live Dropbox/rclone smoke and fresh-context review pending (2026-10-13)
**Workstream:** `dropbox-asset-lifecycle-reconciler-v1`
**Audit date:** 2026-10-13
**Reviewed Git main:** `76c86f4fd52eac4546139925d4c70a50725ed2a0`
**Chat backlink:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
**Audit seed:** `custodian/docs/ai_context/asset_audits/DROPBOX_ASSET_FAMILY_BASELINE_20261013.json`
**Inherits:** `custodian/AGENTS.md`, `custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md`, `custodian/tools/iteration/dropbox_transport.py`, `custodian/tools/iteration/implementation_handoff.py`, `custodian/tools/assets/asset.py`, `custodian/tools/assets/asset_status.py`, `custodian/content/metadata/assets/required_assets.registry.json`

## 1. Audit conclusion and precise evidence level

Dropbox's existing `/CUSTODIAN/asset_batches/_registry/` has `custodian.dropbox_asset_upload_index.v1` and immutable per-batch receipts. Its JSON/Markdown index was last updated **2026-10-07** and lists four Alpine batches only, while current Dropbox listings show newer Ash-Bell/lift ZIPs. Other durable source handoffs sit in `/CUSTODIAN/implementation_inputs/` and `/CUSTODIAN/generated_asset_batches/`. Do not delete, rename, or bulk-move them during a metadata audit.

Known, actionable outstanding intake:
- **AP2 Alpine Cliff:** 12 reviewed source-master states, Dropbox archive 33,847,263 bytes; packet `PROCGEN_ALPINE_CLIFF_PRESENTATION_V1.md` says ready/auto with dependency on completed underlay task; `procgen_alpine_cliff_fascia.asset.json` was not found at reviewed main. Source approval does NOT establish that runtime wiring exists.
- **AP3 Rocky Upland:** 10 reviewed source states, Dropbox archive 31,691,394 bytes, existing `procgen_surface_rocky_upland` family; packet says blocked/auto until AP2. Existing older states in a family do not prove these **new** states are ingested.
- **AP3 Meridian Hardstand:** 6 reviewed source states, Dropbox archive 19,124,392 bytes, existing `procgen_surface_meridian_hardstand` family; same dependency and state caveat. Together AP3 source masters cover **16 incoming states**.
- **Ritual props/chamber dressing:** six plus six already-reviewed source states, both Ash-Bell handoff archives present (6,824,679 and 3,924,735 bytes); static intake and paired review packets are ready/auto, but `ash_bell_ritual_props.asset.json` and `ash_bell_chamber_dressing.asset.json` were not found at reviewed main. The second archive may be a later closeout/alternative, not automatically 12 new images; compare manifests before double-counting.
- **Ash-Bell unarrived + Bridged Falls:** 21,991,270-byte October 13 ZIP; review source/manifest and family identities before marking accepted. Existing required-assets registry still names procession as needed, Saint apparition partial.
- **Lift V2 source:** new 7,801,299-byte ZIP in asset_batches root, no batch folder or registry receipt. Direct local ZIP validation found **seven archive entries, five individual RGBA PNGs, valid ZIP CRC**, archive SHA-256 `fb283369cf3546c7615d1ea51a28c6f6fd95591d36d8c1ccafd5e4c2338bcdbc`. Two static entries (`lift_deck`, `field_projector`) and three field animation entries (`field_idle`, `field_arming`, `field_engaged`); normalized runtime not present. User approval of visual direction does not equal final image/frame validation.
- **Other source lanes:** Awakening interactibles, C relieve tease, Operator movement, Field Scout Buggy, archived/duplicate generations and prior implementation inputs also exist in Dropbox. Baseline JSON records a bounded first-pass inventory, not a false claim that each ZIP has been opened or every runtime state traced.

Some assets may have landed **after** this source inspection; repeat at execution time against fresh `origin/main`. Findings are never promoted from unknown to missing solely due to a Dropbox file being absent. Historical archive and `visual_review/` are not source-master authority.

## 2. One source of truth per question

| Question | Authority | Derived view |
| --- | --- | --- |
| Which source packages exist and their bytes/checksums? | Dropbox immutable files + per-batch receipt | Remote source inventory |
| Which are approved/rejected/superseded? | Explicit review receipt with signer, chat/backlink, reviewed source hash and decision | Review-status projection |
| Which source state belongs to which V2 family? | Reviewed handoff manifest + actual Asset V2 family metadata | State mapping |
| Has normalization produced a valid inbox asset? | Local deterministic conversion output + verified canvas/frame/alpha receipt | Normalization readiness |
| Is an asset ingested, bound and verified? | **Existing Asset V2 catalog, `asset.py status`, requirements, and Godot tests** | Runtime-status projection |
| Can Codex claim intake? | Existing task packet DAG/locks + review approvals | `actionable` flag |

**Never create a second handwritten runtime-installed boolean.** A review receipt reports human source acceptance; a runtime stage is always a computed observation of live Asset V2 catalog and consumers.

## 3. Dropbox is source-master storage, not runtime mirror

Preserve canonical pre-existing lanes:

```text
/CUSTODIAN/asset_batches/_registry/
  README.md
  CUSTODIAN_ASSET_UPLOAD_INDEX.json  # existing discoverability index
  CUSTODIAN_ASSET_UPLOAD_INDEX.md
  <batch-id>.json                     # existing immutable upload receipt
  lifecycle/
    INDEX.json                       # NEW derived snapshot, never standalone authority
    INDEX.md                         # NEW human report
    audit-runs/<run-id>.json         # immutable scan receipts

/CUSTODIAN/asset_batches/<workstream>/<batch-id>/
  <approved high-resolution source ZIP>
  MANIFEST.json or HANDOFF_MANIFEST.json
  CHECKSUMS.sha256
  README.md
```

Existing direct-root or legacy `generated_asset_batches` and `implementation_inputs` objects remain where they are. First scan them read-only; propose moves only in a separately authorized cleanup because immutable packet paths/hashes may depend on those exact entries. New uploads must be one named immutable folder/one batch and registered atomically after upload completion.

No normalized PNG or runtime texture is required in Dropbox. Never copy runtime Godot resources there by default. Once approved, Codex fetches full-res source to verified scratch staging outside checkout, then preserves exact source masters under `custodian/asset_drop/source_work/<area>/<family-id>/<state-id>_source.png`; normalization occurs **locally after verified download**, with final generated state in `custodian/asset_drop/inbox/<family-id>/<state-id>.png`. Allow existing specialized Operator import rules to supersede generic V2 path. Ingest only with normal `asset.py plan/ingest/status/doctor/needs` contract, runtime consumers, and focused tests.

## 4. Manifest design (additive to existing registry)

The existing `custodian.dropbox_asset_upload_index.v1` is backward-compatible. New `custodian.dropbox_asset_lifecycle.v1` is a **generated snapshot**, not a competing authoring registry:

```json
{
  "schema": "custodian.dropbox_asset_lifecycle.v1",
  "scan_id": "20261013T....Z",
  "repo_commit": "<sha>",
  "remote_checked_at": "<utc>",
  "coverage": {"roots": ["asset_batches", "implementation_inputs", "generated_asset_batches"], "complete": true},
  "batches": [{
    "batch_id": "ash-bell-surface-lift-v2-full-resolution-source-20261013",
    "remote_path": "/CUSTODIAN/asset_batches/ash-bell-ritualant/...",
    "file": {"id": "id:...", "bytes": 7801299, "dropbox_content_hash": "...", "sha256": "...", "mtime": "..."},
    "source_manifest": {"validated": true, "schema": "custodian.asset_source_handoff.v1"},
    "source_review": {"status": "awaiting_review", "review_receipt": null},
    "families": [{
      "family_id": "ash_bell_surface_lift_safety_field_v1",
      "states": [{
        "state_id": "field_idle", "source_path": "...", "source_dimensions": [2172,724],
        "frames": 6, "fps": 6, "normalized_dimensions": [3072,192],
        "alpha_validated": "pending", "frame_registration_validated": "pending",
        "local_source_sha256": null, "normalization_receipt": null,
        "asset_v2_status": "not_registered", "runtime_consumer": null
      }]
    }],
    "actionable": false,
    "blockers": ["source_review", "family_contract", "normalization", "runtime_binding"],
    "supersedes": []
  }]
}
```

Real `asset_v2_status` values must be derived from live `asset_status.py`: source_pending, art_present, imported, bound, runtime_verified with exact resource/catalog evidence. Unknown must remain unknown. Do not falsely equate `partial` or existing family runtime completeness with each new source state. Preserve supported source-review lifecycle independently: `awaiting_review` → `approved` / `rejected` / `needs_regeneration` / `superseded`; technical validation may be `not_checked`, `passed` or `failed`. A source batch is not claimable until acceptance is evidenced.

Review receipts (manual approvals) are immutable and Git-tracked under **proposed** `custodian/content/metadata/assets/source_review_receipts.v1.json` with schema-valid references to ZIP SHA-256, family/states, reviewer authority, authoring chat, and date. Do **not** let Dropbox metadata or this generated projection silently approve art. Its values are the sole proposed new authored source-review authority; `asset.py` remains implementation truth.

## 5. CLI and roles

Three focused commands are now implemented on `main`. They reuse the pre-existing `dropbox_transport.py` remote resolution and Asset V2 ownership. **Read-only scan is the default; staging and remote publication require explicit `--apply`.**

```bash
# 1. Read-only reconciliation. Scans all three source lanes using rclone.
python3 custodian/tools/assets/dropbox_asset_audit.py scan --json
python3 custodian/tools/assets/dropbox_asset_audit.py report --format markdown

# 2. Approved source ZIP: safe download to temporary staging,
#    compare immutable package + every PNG hash to Git review receipt.
python3 custodian/tools/assets/dropbox_asset_stage.py <batch-id> \
  --dropbox-path /CUSTODIAN/asset_batches/<workstream>/<batch-id>/<package>.zip
# Write to source_work, and optionally derive normalized inbox with converter.
python3 custodian/tools/assets/dropbox_asset_stage.py <batch-id> \
  --dropbox-path /CUSTODIAN/asset_batches/<workstream>/<batch-id>/<package>.zip \
  --apply --normalize

# 3. Publish an immutable audit-run receipt plus a derived current index
#    in /CUSTODIAN/asset_batches/_registry/lifecycle/.
python3 custodian/tools/assets/dropbox_asset_publish.py
python3 custodian/tools/assets/dropbox_asset_publish.py --apply

# 4. Asset Pipeline V2 retains the exclusive runtime publication authority.
python3 custodian/tools/assets/asset.py plan <family-id>
python3 custodian/tools/assets/asset.py ingest <family-id> --yes --godot-import
python3 custodian/tools/assets/asset.py status <family-id>
python3 custodian/tools/assets/asset.py doctor
python3 custodian/tools/assets/asset.py needs --check
```

`--normalize` is **optional**: only use it when the exact state and frame count are registered in an Asset V2 family contract and an explicit review receipt includes `target_frame_size`. Otherwise stage **source_work only** and first resolve the unregistered family/dimensions. The existing `custodian/tools/art/custodian_pixelart_converter.py` is invoked to derive normalized image(s). Conversion will never invent the extra two missing frames in a 6-frame source intended to become an 8-frame animation; that mismatch is rejected.

The repository review registry is `custodian/content/metadata/assets/source_review_receipts.v1.json`. It starts empty deliberately; current Dropbox `active` flags and historical packet prose are **not** new approval receipts. To approve a batch, record an exact SHA-256-pinned review decision, human reviewer, timestamp, chat backlink, and per-image source state IDs, `entry`, family, SHA-256, source dimensions, frame count, and (where applicable) per-frame target geometry. The stage tool verifies all entries and refuses overwrites. No task/CI tool should silently approve a batch.

`asset_stage` accepts either `--dropbox-path` (direct temporary rclone download) or `--zip` (already fetched approved source). It does not ingest. The scanner reads metadata and index without downloading ZIPs; staging deliberately downloads bytes only for explicit approval-gated operations. The publisher writes an immutable run first and then a **replaceable derived current index**; it does not rewrite historical `_registry` receipts or uploaded source packages. The current-index update is not a cross-agent compare-and-swap operation, so avoid concurrent publishers and use the immutable run as the recovery/audit record.

**Unverified external steps:** the present ChatGPT environment does not have a configured CUSTODIAN rclone remote. The first full live remote scan, source-staging run, and Dropbox index publication remain operational acceptance tasks for Codex in its connected checkout. Passing local/GitHub unit tests is not proof those operations have run against this Dropbox account.

## 6. Operating procedure and validation gates

1. **Discover** all three relevant Dropbox lanes recursively and page through every result. Create an exact list of ZIPs, PNG source files, manifests and metadata; exclude `visual_review` by default as evidence only.
2. **Reconcile** Dropbox `_registry` against actual objects. Emit missing receipt, orphaned object, conflicting batch ID, duplicated hash, superseded artifact, stale index and unknown family warnings.
3. **Match** batch manifests/bytes against current `origin/main` family metadata, `required_assets.registry.json`, Asset V2 catalog, active/archived packet identity and dependency DAG. Report exact known blocking reason, not merely "pending".
4. **Review** source artwork by human/ChatGPT at appropriate scale and set immutable review verdict. Technical ZIP/PNG validity is necessary but insufficient for visual approval.
5. **Stage** approved source to local source_work, derive normalized inbox with existing pixel-art scripts where suitable (no stretching to fake poses/geometry), and write conversion receipt (input SHA-256, output SHA-256, actual dims, frame count/pivots, tool/version, command).
6. **Ingest** via current Asset V2 tools or specialized Operator owner, with explicit replacement approval.
7. **Verify** consumers, Godot smoke/visual ROI and every family/status/required-assets row; classify truly `runtime_verified` only after validation.
8. **Publish** new derived Dropbox index plus checked-in small human report, never automatic ingest or auto-claim-on-upload. Recommended manual weekly or pre-art-workstream execution; no daemon until operational need proven.

**Validation:** unit tests mock rclone output and ZIPs; golden-input tests for corrupted ZIP, path traversal, duplicate state, missing receipt, stale package, hash mismatch, invalid alpha, irregular frame cells, unreviewed source gate, existing runtime state not from source SHA, remote offline, replaced batch and concurrent publish; integration test on fake local remote; one real Dropbox read-only smoke; source staging and `asset.py` negative controls. Source V2 `source_work` and `inbox` destinations remain inside repository conventions, no runtime mutations from audit alone.

## 7. Minimal AGENTS instruction after the CLI lands

Add a short link rather than a new, independent `AGENTS.md`:

> Before any asset intake or upload closeout, run the Dropbox asset lifecycle audit against fresh `main`. Dropbox stores source masters, not normalized runtime. Treat any new upload as `awaiting_review` until an explicit review receipt approves exact SHA-256 and family states. Only Asset Pipeline V2 and runtime validation establish `ingested/bound/verified`. See `design/04_architecture/DROPBOX_ASSET_LIFECYCLE_RECONCILIATION_V1.md`. Do not create parallel status ledgers or ingest from `visual_review`.

The AGENTS routing note and focused CI suites are now present. Maintain the instructions when the CLI changes.

## 8. Dependency-aware implementation division

- **Slice A (this packet):** invent no new art; implement read-only remote scanner, legacy registry adapter, three-lane classification, source review receipt schema/projection and targeted tests. Produce current report; no auto-approve or mutate external input.
- **Slice B (follow-up, separate packet only if needed):** verify/stage exact approved source batches, compute normalization receipts via real pixel-art pipeline, block collisions, leave ingestion explicit.
- **Slice C (optional):** publish derived index to Dropbox and schedule audit as manual recurring Codex task; no silent cloud mutation by default.

The three CLI slices have now landed as implementation code. The existing draft/manual packet pair remains the place for Codex to perform fresh-context review, live Dropbox smoke, remediation and lifecycle closeout rather than re-implement the tools.
