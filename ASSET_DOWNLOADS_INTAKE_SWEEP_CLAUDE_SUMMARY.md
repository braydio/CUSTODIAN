# Asset Downloads Intake Sweep — Partial Checkpoint

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9

## Result

The intake remains at 11 of 21 required states: Ambulatory 6/6, Dust Lung structures 4/4, and Undergate machinery 6/6. Attestation is 0/7 and Reliquary 0/3. The refreshed A2 outer ZIP and all manifest, member, per-file hash, dimensions, mode, alpha, and target checks passed. The required `attestation_dais` pre-staging gate failed in both supplied source and normalized art, so no A2 files were extracted into the repository or staged. This is a partial checkpoint; resume this same workstream after corrected dais art or authoritative replacement input is available.

## Verified Handoffs and Asset V2 Jobs

- Consumed `/CUSTODIAN/implementation_inputs/awakening_service_basin_b_handoff_v1.zip`; expected and actual SHA-256 `749cba1851e5bae8e5c68cbb0293b1b0b58ac447204b024fadc911b7665e189c`; Asset V2 job `job_20261007T140317Z_c027e86a`.
- Consumed `/CUSTODIAN/implementation_inputs/awakening_dustlung_undergate_next10_handoff_v1.zip`; expected and actual SHA-256 `7bceeb24022613515ec65d05da5a6b6f2acee31c9920edb552c7a48936eda612`; Dust Lung job `job_20261007T140446Z_1d47c503`; Undergate job `job_20261007T140503Z_b6135b78`.
- Preflighted `/CUSTODIAN/implementation_inputs/awakening_next10_required_fixtures_handoff_v1.zip`, current Dropbox revision `65d22e7369f4c915cdd61`, SHA-256 `82012a4f2b0285b8833eb3daa2878e49e7798e123970ab17fd304c9af757c9a4`. Manifest identifies the intended handoff and exactly 7 Attestation + 3 Reliquary states. All 20 source/normalized files pass manifest SHA-256, dimensions, RGBA/alpha and canonical target checks; actual ZIP members exactly match declarations and allowed auxiliary files. No package file was extracted into the repository because the required dais art gate failed.

The prior tracked Basin B source was preserved before replacement at `custodian/asset_drop/source_work/awakening/awakening_ambulatory_fixtures/pre_handoff_service_basin_b_source.png` (SHA-256 `3f3879b1b2bac3d03171ae4586124c36c07f0594da550b00db03fc352cf523cd`). The supplied canonical source SHA is `506f36de93096f32b37991fc7a4a5b27d0bb476c00afe7d47d3b608f010efc15`.

All 22 supplied files from the two accepted ZIPs matched their manifest SHA-256, dimensions, RGBA mode, and declared alpha extrema. The 11 runtime PNGs below match their normalized input hashes and have Godot import sidecars:

| Family / state | Runtime path | SHA-256 |
|---|---|---|
| Ambulatory / `service_basin_b` | `custodian/content/sprites/environment/props/awakening/awakening_ambulatory_fixtures/runtime/body/awakening_ambulatory_fixtures__body__fixture__service_basin_b__omni__1f__128.png` | `b8e068ced61b6a7416b8b5be6ed2da881e5d7861e48faf7e4ea46a2e7cba6924` |
| Dust Lung / `broken_bridge_a` | `custodian/content/sprites/environment/props/awakening/awakening_dust_lung_structures/runtime/body/awakening_dust_lung_structures__body__fixture__broken_bridge_a__omni__1f__256x160.png` | `891244f7fd8df1a3d10c7ffb01a8342d7902d838295c3d19bf36a45b7e292c54` |
| Dust Lung / `broken_bridge_b` | `custodian/content/sprites/environment/props/awakening/awakening_dust_lung_structures/runtime/body/awakening_dust_lung_structures__body__fixture__broken_bridge_b__omni__1f__256x160.png` | `c18446e231ace1d91a26c531bc3fcb0f66412abd1165cca2b2d010fc7f58b2b5` |
| Dust Lung / `giant_duct` | `custodian/content/sprites/environment/props/awakening/awakening_dust_lung_structures/runtime/body/awakening_dust_lung_structures__body__fixture__giant_duct__omni__1f__256.png` | `97797f99f29ef5d29b0d0a721b971c8f2128c8f655e0890ec51a36e873423ade` |
| Dust Lung / `lift_lever` | `custodian/content/sprites/environment/props/awakening/awakening_dust_lung_structures/runtime/body/awakening_dust_lung_structures__body__fixture__lift_lever__omni__1f__128.png` | `7bb6721ecd740242b848f3bf6e3356bb7d47391940816c576c1c7df2b3f7b09e` |
| Undergate / `blind_route_housing` | `custodian/content/sprites/environment/props/awakening/awakening_undergate_machinery/runtime/body/awakening_undergate_machinery__body__fixture__blind_route_housing__omni__1f__160.png` | `2ef738370e2f38c44530bdd1f34e52f8d40fce118dbbfb4952bf3d686b280012` |
| Undergate / `mechanism_plinth` | `custodian/content/sprites/environment/props/awakening/awakening_undergate_machinery/runtime/body/awakening_undergate_machinery__body__fixture__mechanism_plinth__omni__1f__160.png` | `7ad22efe029c1384f1e3986dc9ec814e31d04595bc415f343fecfb052c094232` |
| Undergate / `register_route_map` | `custodian/content/sprites/environment/props/awakening/awakening_undergate_machinery/runtime/body/awakening_undergate_machinery__body__fixture__register_route_map__omni__1f__384x256.png` | `b8e13f0f63f3d044f09cf1d770e5b3f62b5bbf32bafaa8952f3103df62779247` |
| Undergate / `register_shelving` | `custodian/content/sprites/environment/props/awakening/awakening_undergate_machinery/runtime/body/awakening_undergate_machinery__body__fixture__register_shelving__omni__1f__256x192.png` | `34d47d370ce3f7d3aee76845d3281adaa4d75d47bb4bfe11b24f779329ca8750` |
| Undergate / `route_coil` | `custodian/content/sprites/environment/props/awakening/awakening_undergate_machinery/runtime/body/awakening_undergate_machinery__body__fixture__route_coil__omni__1f__192.png` | `721db2b219b51a788e9aff4ea4e88bc4f148031c8f656fead7fee85a191b87f8` |
| Undergate / `transit_drum` | `custodian/content/sprites/environment/props/awakening/awakening_undergate_machinery/runtime/body/awakening_undergate_machinery__body__fixture__transit_drum__omni__1f__256x192.png` | `298225462916a47bb3b73808a75f61d389fda9ba56a7c5606b6d7a02075aa995` |

## Consumption and Dropbox Audit

No scene bindings were added. `service_basin_b` is `BAKED_ONLY` under the packet's Ambulatory doctrine. The four Dust Lung and six Undergate states are `NOT_READY` as independent scene props. The ten A2 states remain unpublished and `NOT_READY`. The live Designation Locker reauthor ZIP is owned by `awakening-designation-locker-visual-reauthor-v1` and was left untouched. The recursive audit classified all 52 Dropbox entries with no unknown disposition in `custodian/docs/ai_context/reports/assets/dropbox_unstaged_asset_intake.json`; the existing partial Alpine cliff payload, already-landed Operator/Alpine payloads, superseded Alpine batch, donor bundle, and transport smokes were not consumed.

## Documentation and Validation

Updated the current required-assets registry/projection, Awakening runtime ingest status report, and Asset Manifest consumption audit. `asset.py status` reports Ambulatory 6/6, Attestation 0/7, Reliquary 0/3, Dust Lung 4/4, Undergate 6/6; `asset.py doctor --json` is healthy with no issues. `asset_pipeline_status_smoke.py`, `asset_requirements_smoke.py`, package/per-file checks, Godot imports, and `git diff --check` pass.

`run_validation.py --changed --json` selected three tests and all three passed, but returned `passed=false` because its coverage map does not cover the 11 newly generated runtime PNG files. Each runtime file was independently verified against the manifest hash and import sidecar. `attestation_dais` blocks A2 staging. Using 8-connected nontransparent-alpha components, the source is 566×282 with a 78,658-pixel principal island and an 848-pixel satellite (848/79,506 = 1.0666%). The normalized image is 256×192 with a 14,398-pixel principal island and two satellites totaling 204 pixels (204/14,602 = 1.3971%). Both exceed the packet’s strict <1% rule. Neither image was modified, and no A2 files were staged.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: The packet’s old A2 digest predated its sole Dropbox revision. After main refreshed the authority, the dais source and normalized alpha masks each exceeded the packet’s strict 1% satellite cap, so all A2 staging was withheld. Initial A1/A3 staging also assumed the zip root matched `handoff_id`; this caused no package-target writes and was corrected.
- Root cause / contributing factors: A2’s sole Dropbox revision postdated the packet’s author-time digest; dais art contains satellite alpha above the explicit threshold; handoff root naming differs from the manifest handoff ID.
- Prevention / pipeline improvement: Keep the pre-staging connected-component gate before any A2 write. Resume only with corrected dais art or authoritative replacement input. Resolve archive paths from the ZIP listing after verifying the outer hash.
- Tooling / docs drift discovered: Changed-file validation selects passing asset tests but reports incomplete coverage for generated runtime PNGs; current asset intake documentation had stale status notes and has now been refreshed.
- Follow-up: manual-follow-up
- What worked: Asset V2 plan/ingest/status/doctor and per-file manifest verification gave a precise boundary.

## Next Handoff

- Next workstream: awakening-designation-locker-visual-reauthor-v1
- Next packet state: dependency-gated
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9
- Refresh reason: the current Attestation/Reliquary ZIP does not match this packet's immutable hash, so the intake cannot complete yet.
- Next action: obtain the exact A2 archive or explicitly refresh its packet authority, then resume this same workstream.
- Blockers or open questions: current A2 SHA-256 is 82012a4f2b0285b8833eb3daa2878e49e7798e123970ab17fd304c9af757c9a4; expected 7192a7e2a2c291d5db11c70e5027fbeea9d5597e24d32a8033b428b6c3a9c4b3.
