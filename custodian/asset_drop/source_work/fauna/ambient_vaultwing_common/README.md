# Common Vaultwing source art

The regenerated wild South and North replacements are complete at 14/14
states per facing; this count describes the Slice-A wild baseline only. The wild
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

Lifecycle: accepted source masters belong in this directory. Rejected generated
candidates belong under
`custodian/asset_drop/unresolved/vaultwing_bonding_rejected/` and must never
occupy a canonical source-master filename. The rejected Pass-1 `vw8` source was
removed from source_work after byte comparison and retained as
`inspect_bait_s_vw8__2e75b561e102.png` in durable quarantine.

Ordinal mapping is fixed by the pass contract. Accepted root inputs were copied
byte-for-byte here and removed from the root only after hash checks; the
rejected vw8 input was quarantined instead:

| Ordinal | Input | Semantic source master | Raw size | Result |
|---:|---|---|---:|---|
| 1 | missing | `notice_bait_e_source.png` | — | not staged |
| 2 | `vw_2.png` | `notice_bait_s_source.png` | 2172×724 | accepted |
| 3 | `vw3.png` | `notice_bait_n_source.png` | 2172×724 | accepted |
| 4 | `vw4.png` | `guarded_approach_e_source.png` | 2172×724 | accepted |
| 5 | `vw5.png` | `guarded_approach_s_source.png` | 2172×724 | accepted |
| 6 | `vw6.png` | `guarded_approach_n_source.png` | 2172×724 | accepted |
| 7 | `vw7.png` | `inspect_bait_e_source.png` | 1983×793 | accepted |
| 8 | `vw8.png` | — | 1983×793 | rejected: generated matte; preserved at `custodian/asset_drop/unresolved/vaultwing_bonding_rejected/inspect_bait_s_vw8__2e75b561e102.png` |
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

## Bonding art pass 2 source recovery

Pass 2 corrected the staging order so background validation precedes canonical
source_work assignment. Rejected art is hash-named in the durable quarantine;
it creates no canonical master or inbox strip. Distinct accepted source masters
remain immutable, while an accepted replacement can populate a slot that has
only rejected history. The first-batch ordinal map remains fixed: 1
`notice_bait_e`, 8 `inspect_bait_s`, 10–12 `feed_accept_e/s/n`, 13–15
`watch_player_e/s/n`, and 16–18 `bond_greet_e/s/n`. No Pass-2 root masters were
present during this run; all eleven remain missing.

## Bonding art pass 3 (2026-09-28)

The task-local inputs `vw1.png`–`vw12.png` were mapped by semantic name and
verified by SHA-256; the project-root originals remain with the user. Eight
approved inputs are retained byte-for-byte here and produced eleven runtime
strips through the existing Asset V2 family. Seven sheets passed the shared
family-aware normalizer before balanced pixel-art conversion. `vw6` was
processed as a fixed-cell six-frame sheet because adjacent source poses join at
their alpha edges; its 256px output was visually checked and stays inside each
cell's eight-pixel edge guard.

The three eight-frame greeting sheets `vw9.png`, `vw10.png`, and `vw12.png`
produce visibly clipped wings when divided into uniform cells. They are not
accepted source masters and remain hash-verified in
`custodian/asset_drop/unresolved/vaultwing_bonding_rejected/`. The superseded
wrong-facing `vw2.png` is quarantined there as well. These inputs need corrected
sheets or a reviewed segmentation before they can be ingested. Current totals
are 15/18 authored bonding masters, 20/24 bonding runtime strips, and 76/80
Vaultwing runtime strips overall.
