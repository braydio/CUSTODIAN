# Common Vaultwing source art

The regenerated South and North replacements are complete at 14/14. The wild
Slice A runtime closeout is implemented with production marker/spawner wiring,
spatial attacks, perching, retreat, and focused validation. All source
files retain their semantic names and 256px contracts.
Future corrected art can replace any state through the same normal Asset V2
workflow:

1. preserve the replacement candidate under this source-work directory;
2. stage matching `state__direction.png` files in
   `custodian/asset_drop/inbox/ambient_vaultwing_common/`;
3. run `asset.py plan ambient_vaultwing_common` and inspect the dry-run;
4. apply the targeted family ingest with replacement enabled where required;
5. run Vaultwing and changed-file validation.

The original matte-bearing inputs remain preserved under
`custodian/asset_drop/unresolved/ambient_vaultwing_south_north_20260922/` as
rollback and comparison evidence. Do not delete that quarantine when replacing
these temporary strips. The rejected `vw_3`/`vw_7` masters are preserved under
`custodian/asset_drop/unresolved/vaultwing_south_partial_20260923/`.

## Bonding art pass 1 (2026-09-26)

Ordinal mapping is fixed by the pass contract. The matching root inputs were
copied byte-for-byte here and removed from the root only after hash checks:

| Ordinal | Input | Semantic source master | Raw size | Result |
|---:|---|---|---:|---|
| 1 | missing | `notice_bait_e_source.png` | — | not staged |
| 2 | `vw_2.png` | `notice_bait_s_source.png` | 2172×724 | accepted |
| 3 | `vw3.png` | `notice_bait_n_source.png` | 2172×724 | accepted |
| 4 | `vw4.png` | `guarded_approach_e_source.png` | 2172×724 | accepted |
| 5 | `vw5.png` | `guarded_approach_s_source.png` | 2172×724 | accepted |
| 6 | `vw6.png` | `guarded_approach_n_source.png` | 2172×724 | accepted |
| 7 | `vw7.png` | `inspect_bait_e_source.png` | 1983×793 | accepted |
| 8 | `vw8.png` | `inspect_bait_s_source.png` | 1983×793 | rejected: generated matte; quarantined at `custodian/asset_drop/unresolved/vaultwing_bonding_pass_1_matte/inspect_bait_s_vw8.png` |
| 9 | `vw9.png` | `inspect_bait_n_source.png` | 1983×793 | accepted |
| 10 | missing | `feed_accept_e_source.png` | — | not staged |

The reusable normalizer `custodian/tools/assets/stage_vaultwing_bonding_source_work.py`
extracts alpha-separated frame groups, checks expected frame counts and
background cleanliness, and uses a shared per-strip scale with the approved
directional ground art as reference. It premultiplies alpha for Lanczos
downsampling and registers each frame to the ground-support anchor in the
256×256 cell. It does not repair or synthesize frames. Accepted inbox strips
are 1024×256 (notice, 4f), 1536×256 (approach, 6f), and 1280×256 (inspect,
5f). `feed_accept` has no input in this batch. Ordinals 1, 8, and 10 remain
unresolved for recovery. The next authored batch is ordinals 11–18.
