# Crèche 960×704 candidate cutover receipt (2026-11-07)

- Workstream: `awakening-creche-console-sprite-reauthor-v1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aebed23-b464-83e9-93f8-d2560865c5da
- Decision: explicitly replace both 1464×1074 plates with the supplied 960×704 RGBA pair. This is a candidate runtime composition; human gameplay-scale approval remains pending.

## Source identity and V2 intake

| Role | Source SHA-256 | Canvas / alpha | Source_work | Inbox | Runtime output |
|---|---|---|---|---|---|
| underlay | `2960b84744e8db82be62f4b284601ed70f0395102cc3f0311e62cbc8bc018874` | 960×704 RGBA, alpha 255 | `asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png` | `asset_drop/inbox/awakening_creche_environment/underlay.png` | `content/levels/awakening/01_creche/awakening_creche_underlay_960x704.png` |
| foreground | `5fae745632eab60f2fa3dd7b322cbdd0afaec45bb43690870a775c36557ac064` | 960×704 RGBA, alpha 0–255 | `asset_drop/source_work/awakening/awakening_creche_environment/foreground_source.png` | `asset_drop/inbox/awakening_creche_environment/foreground.png` | `content/levels/awakening/01_creche/awakening_creche_foreground_960x704.png` |

The incoming ZIP `custodian_creche_960px_source_pair_20261107.zip` declared these hashes and dimensions in `MANIFEST.json`; `SHA256SUMS` verified both bytes. The underlay is fully opaque; the foreground includes the southern alpha opening at x400–555, y640–703 (inclusive). Centered identity transform maps this to approximately world x−80..+75, y+288..+352.

The nonempty Asset V2 plan reported `can_apply=true`, `source_count=2`, `output_count=2`, two `replace` operations and no errors. Guarded command `asset.py ingest awakening_creche_environment --replace --yes` completed as job `job_20261107T092214Z_0e12dbae`; immutable ingest/archive evidence is in `asset_drop/archive/job_20261107T092214Z_0e12dbae/` and its log is in `asset_drop/logs/`.

## Rollback identities

The previous approved 1464×1074 source identities remain available from parent commit `fd706097f245274d5458bf920cef82f7dd2f3b83` / Git LFS:

- Underlay: `sha256:9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`.
- Foreground: `sha256:515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`.

Restore only those two source paths from that commit to roll the source version back. Do not reset the workstream or remove the new archive/receipts.

The ZIP handoff was removed from `~/Downloads` after its exact source bytes were staged in source_work and inbox, the replacement plan was verified, and guarded ingestion succeeded. No crop, scale, rotation, color conversion or resampling was applied.
