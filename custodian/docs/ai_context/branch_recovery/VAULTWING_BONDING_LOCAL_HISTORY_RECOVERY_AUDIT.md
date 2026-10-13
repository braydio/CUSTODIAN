# Vaultwing Bonding Local History Recovery Audit

## Scope and measured refs

- Audit date: 2026-10-13.
- Live main: `388bce9a9c448a739a09cae7ede1126b64c3523a` (`origin/main`).
- Donor archive: `archive/agent-vaultwing-bonding-art-final-ingest-20261007` -> `2eb4e7190a3bd5f50719e0c613782bac1cf21cc8`.
- Archive tag verification: fetched annotated tag object `a20501d4cd2b7bac41883e061ccf6ff5b4985a6b`; peeled remote tag resolves to the donor SHA above. The archive ref is unchanged.
- Historical checkpoint: `7aae81a85e77d8fec05df86bd2bac51cf73b94a2` is an ancestor of the donor. `7aae81a8..2eb4e719` contains 23 commits; the reverse range contains 0.
- Merge base: `309360a4d0cee36f6f36915dcb53c21718596f15`.
- `origin/main...donor` counts: 2562 main-only, 25 donor-only. The canonical donor-only set is the 25 commits listed below (`git rev-list --reverse origin/main..archive/...`).
- `git cherry -v origin/main <donor>` reports `+` for all 25 commits: there are no exact patch-id-equivalent commits. Where classified as rewritten-equivalent, that conclusion is based on current functional behavior, current Asset V2 contents, owner documentation, and tests rather than identical patch IDs.

## Current-state evidence and ownership

- `python3 custodian/tools/assets/asset.py status ambient_vaultwing_common --json` reports 11/11 required, 80 runtime outputs, and 20 states; the bonding subset has 24 runtime direction outputs.
- `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/` contains the accepted masters, including all six donor actions and four `bond_greet` directions. The final-ingest summary records the selective restore and rejects as excluded.
- `custodian/tools/assets/stage_vaultwing_bonding_source_work.py` and its focused test contain current source-map resolution, named batch preflight, immutable-source checks, and reject-without-copy behavior. Their evolved implementations own current staging behavior.
- Current Vaultwing art/source ownership is the `ambient_vaultwing_common` Asset V2 family and Asset Pipeline V2; current design/context ownership is `design/02_features/ambient/VAULTWING_SYSTEM.md`, `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md`, and `custodian/docs/ai_context/`.
- The superseding final-ingest record is `VAULTWING_BOND_GREET_FINAL_INGEST_CLAUDE_SUMMARY.md` and archived packet `custodian/docs/ai_context/task_packets/archived/VAULTWING_BOND_GREET_FINAL_INGEST.md`. It records 24/24 bonding directions, 80/80 family strips, corrected source masters, and the explicit decision to exclude rejected inputs.

## Per-commit dispositions

Each row classifies one donor-only commit exactly once. Salvage is `no` for every row.

| Commit | Classification | Touched paths | Current owner and evidence / decision |
|---|---|---|---|
| `a2924d51249c901c08277ef08f5454f0aef40091` | already present on main / rewritten-equivalent | old ingest summary and packet; `stage_vaultwing_bonding_source_work.py`; staging tests | Current stager resolves explicit source maps and tests path validation. The functional contract is present in the current owner; no port needed. |
| `7aae81a85e77d8fec05df86bd2bac51cf73b94a2` | already present on main / rewritten-equivalent | 8 accepted source masters, source-work README, 8 archive inputs/logs, 11 runtime strips/import sidecars, old packet/docs/context | The later final ingest selectively restored accepted sources/runtime through Asset V2. Current source-work has the masters; current status proves 24/24 bonding and 80/80 family output. Rejected files from this checkpoint were not accepted and remain excluded. |
| `955afd2669196ceb3229135e6f6cfbbc57d8b989` | already present on main / rewritten-equivalent | `stage_vaultwing_bonding_source_work.py` | Current stager leaves rejected sources at their supplied path and creates no source-work, inbox, runtime, or quarantine copy. |
| `199ed468063fadaf7232ac181c54e84ab544f294` | already present on main / rewritten-equivalent | staging tests | Current tests cover rejection staying local and clean replacement acceptance; current tests are the maintained test owner. |
| `818633ebe8c177dc99f7302635f47c94995b4389` | superseded | archived legacy ingest packet | Replaced by the selectively reconciled `VAULTWING_BOND_GREET_FINAL_INGEST` workstream and current 24/24, 80/80 closure. |
| `ca6f22d1da720f1adaad61661b277f7ff7059654` | obsolete/no-longer-applicable | `VAULTWING_BONDING_ART_FINAL_INGEST_CLAUDE_SUMMARY.md` | Historical execution note for the retired donor; current final-ingest summary and archive record own the outcome. |
| `a199e1c024587f84515e751a2dfbd161d280217c` | superseded | `custodian/docs/ai_context/CURRENT_STATE.md` | Current-state document has since advanced and reflects completed family coverage; old intermediate snapshot is not authoritative. |
| `87b7482b08344709fdb3e69f7f9a8a7a76a977a1` | superseded | `custodian/docs/ai_context/FILE_INDEX.md` | Current file index is maintained on main; donor rejection-era entries are not needed. |
| `4ab8044324058ce15cb8334337fbc303ad3eea6f` | superseded | `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md` | Current active design supersedes the donor's interim quarantine policy. |
| `1570f355f73fcb7be6996141bb8d2853edffe433` | superseded | `design/02_features/ambient/VAULTWING_SYSTEM.md` | Current active system design is authoritative; no unique requirement remains. |
| `83e6d3f4957ec110c65dc8f9bc97e95b2cbbf8f4` | superseded | source-work README | Current README and final-ingest record carry the maintained source/rejection workflow. |
| `a40e85ff948621a4b37e24e363a7b05791f51f75` | superseded | `required_assets.registry.json` | Current Asset V2 status is complete (11/11 required; 80 outputs), and generated requirement state is owned by current family/catalog tooling. |
| `c11e2c8b63fdbbf713f4dba70ec2315ac1203b66` | already present on main / rewritten-equivalent | rejected `bond_greet_e` unresolved input | The rejected input is absent from current production/source-work; later final-ingest explicitly excluded rejected candidates. |
| `c1aec8f62b13b4dad34a772ff690f52a71359f99` | already present on main / rewritten-equivalent | rejected `bond_greet_n` unresolved input | The rejected input is absent from current production/source-work; later final-ingest explicitly excluded rejected candidates. |
| `78f9a06e8b50fc29e73a02d367433f141f008906` | already present on main / rewritten-equivalent | rejected `bond_greet_s` unresolved input | The rejected input is absent from current production/source-work; later final-ingest explicitly excluded rejected candidates. |
| `5c90ed96eb04bf32a198af08f1979cac7bc45a4e` | already present on main / rewritten-equivalent | rejected `inspect_bait_s_vw2` unresolved input | Rejected candidate is not in current accepted source/runtime state; current staging does not promote rejected input. |
| `5da9e4bb2e6d0e1613a36c31c13f1dcd1d466b5f` | already present on main / rewritten-equivalent | rejected `inspect_bait_s_vw8` unresolved input | Final-ingest summary records removal of this old rejected artifact; it is absent from current family state. |
| `adbe03feacf867d0ac501e7394c38350cfda7af5` | superseded | `custodian/docs/ai_context/CURRENT_STATE.md` | Later current-state updates replace the donor's partial-pass snapshot. |
| `2fc75b62f3cf080038c5c4079aa97c84f823b39f` | already present on main / rewritten-equivalent | `stage_vaultwing_bonding_source_work.py` | Current stager retains the reject lifecycle: no canonical source promotion or generated copies for rejected inputs. |
| `2adf3e8f4ff1038e3f0f3a95573058ebafdd464d` | superseded | source-work README | Current source-work README and Asset V2 family contract supersede the old historical-retention wording. |
| `faf8eb532e784db7c88bda6e14b2540f731f3e65` | superseded | `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md` | Current design carries the accepted/rejected art boundary; donor wording adds no current authority. |
| `02c31ca2abeea0df80f51a0e2da828790c6ba44e` | obsolete/no-longer-applicable | archived legacy ingest packet | The packet is archived and superseded; removing its obsolete rejected-greeting remap is historical packet cleanup only. |
| `55ffb72f758bf1cd38c7e4ed06d0a9873eb90d40` | superseded | source-work README | Current README and stager own root-copy cleanup and preservation behavior. |
| `9b2b3d5b284a32fca50e5fe05688a9c9f1a6533a` | obsolete/no-longer-applicable | `VAULTWING_BONDING_ART_PASS_1_CLAUDE_SUMMARY.md` | Supersession annotation pertains only to historical closeout prose; current archive/final-ingest records own history. |
| `2eb4e7190a3bd5f50719e0c613782bac1cf21cc8` | obsolete/no-longer-applicable | `VAULTWING_BONDING_ART_PASS_2_CLAUDE_SUMMARY.md` | Supersession annotation pertains only to historical closeout prose; current archive/final-ingest records own history. |

## Outcome

- Donor-only commits audited: 25/25, each listed once.
- Classification counts: 10 already present / rewritten-equivalent; 11 superseded; 4 obsolete/no-longer-applicable; 0 genuinely unique and valuable.
- Salvage selected: **none**. Accepted art/source/staging behavior has current owners and is present in the completed family; remaining donor content is rejected history, superseded guidance, or historical notes. No production/source-work mutation, cherry-pick, branch recreation, or archive-tag mutation was performed.
- Archive tag and donor head remain untouched; the old checkpoint remains reachable.

## Validation evidence

- `git fetch --tags origin`; exact archive tag and peeled head verified from `git ls-remote`.
- `git merge-base --is-ancestor 7aae81a85e77d8fec05df86bd2bac51cf73b94a2 archive/agent-vaultwing-bonding-art-final-ingest-20261007` — passed.
- `git rev-list --left-right --count origin/main...archive/agent-vaultwing-bonding-art-final-ingest-20261007` — `2562 25`.
- `git rev-list --reverse origin/main..archive/agent-vaultwing-bonding-art-final-ingest-20261007` — the 25 listed donor commits.
- `git cherry -v origin/main archive/agent-vaultwing-bonding-art-final-ingest-20261007` — all 25 exact patch IDs differ; functional equivalence decisions are supported by current code/tests and family/source state above.
- Asset V2 family status — 11/11 required; 80 runtime outputs; 24 bonding runtime outputs.
