# Common Vaultwing source art

## Current bonding-art state (2026-09-29)

The six Slice-B bonding actions are complete in Asset V2: 24/24 runtime
directions and 80/80 total Vaultwing runtime strips. `bond_greet` has authored
E/N/S/W directions; W for the other five states is mirrored from E under the
family contract. The four raw greeting sheets were copied byte-for-byte to
`bond_greet_{e,n,s,w}_source.png` from these named inputs:

| Input | Direction | SHA-256 |
| --- | --- | --- |
| `vw_east_facing.png` | E | `4d2da93b93c46bc84ddfe71d745582bfd4d1db3da8d467c96c79666318e5dd94` |
| `vw_north_facing.png` | N | `fd696c31037654a6de556f8ba850ebe42cb8a1e3b6e258a5bf8a0c52a0b06ffd` |
| `vw_south_facing.png` | S | `087a1624f762805c17c66796658fe98b34a08cdd67435786d5c622621203a061` |
| `vw_west_facing.png` | W | `19ac395ca8c0ffc95306217ab1a3089bfb79139938e7acf6c4635c4f4acaddac` |

Use the named profile to validate and stage the 8×1 sheets:

```bash
python3 custodian/tools/assets/stage_vaultwing_bonding_source_work.py --downloads-batch [DIRECTORY]
```
Omitting the directory uses `~/Downloads`.
The pass-history sections below describe their state on 2026-09-26 and are
retained as historical records; their missing-art counts and rejection notes
are not current production status. The `vaultwing-bonding-animation-suite`
requirement is fulfilled and retained in the machine registry; the generated
root `REQUIRED_ASSETS.md` omits it.

Rejected bonding candidates stay at their user-provided local path for
correction. The stager does not copy them into source_work, inbox, runtime, or
repository quarantine, and does not delete them automatically. The old Pass-1
`inspect_bait_s_vw8__2e75b561e102.png` quarantine artifact was removed from the
repository as part of this finalization.

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

Historical Pass-1 lifecycle: accepted source masters belong in this directory.
Rejected generated candidates must never occupy a canonical source-master
filename. The rejected Pass-1 `vw8` source was initially retained in a
hash-named quarantine; that repository artifact has since been deleted under
the deletion-only rejection policy described above.

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
| 8 | `vw8.png` | — | 1983×793 | rejected for generated matte; the temporary quarantine copy was later deleted under the user's deletion-only policy |
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
