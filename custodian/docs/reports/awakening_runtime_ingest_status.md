# Awakening Runtime Ingest Status

Status: first-pass production art is runtime-bound and imported for the listed
states. This is not a claim that Awakening art is complete, and publication does
not imply a separate scene binding.

## Completed

Crèche console, console activation FX, recovery alcove idle/wake, Custodian
Approach, Designation Locker, Dust Lung lift, Gate Plaza, Undergate, Gate of
Dust components, and Late Service underlay/foreground are present in the Asset
V2 catalog and load through the Awakening runtime route. Late Service uses the
canonical 704×768 pair under `content/levels/awakening/09_late_service/` with
one shared resize transform and production foreground occlusion.

The Crèche fixture family has all seven required states published. The
`awakening_ambulatory_fixtures` family now has all six required states,
including `service_basin_b` (Asset V2 job
`job_20261007T140317Z_c027e86a`). `awakening_dust_lung_structures` is 4/4
(job `job_20261007T140446Z_1d47c503`) and
`awakening_undergate_machinery` is 6/6 (job
`job_20261007T140503Z_b6135b78`). All eleven new runtime PNGs were imported by
Godot. No new scene bindings were introduced.

## Partial / blocked

`awakening_attestation_fixtures` remains 0/7 and
`awakening_reliquary_fixtures` remains 0/3. The current Dropbox
`awakening_next10_required_fixtures_handoff_v1.zip` hashes to
`82012a4f2b0285b8833eb3daa2878e49e7798e123970ab17fd304c9af757c9a4`, while
the active intake packet requires
`7192a7e2a2c291d5db11c70e5027fbeea9d5597e24d32a8033b428b6c3a9c4b3`. It was
not extracted or consumed. `attestation_dais` received no preflight or
correction because its containing archive failed the immutable ZIP gate.

The current required-asset projection reflects completed Ambulatory, Dust Lung,
and Undergate families while keeping Attestation and Reliquary open.

## Tooling and housekeeping

Canonical normalization, staging, and review entrypoints live under
`custodian/tools/art/`. Normalization does not mutate source masters, staging
checks live family dimensions, and review inventory only treats explicit frame
markers or resolved animation contracts as strips. Before replacing the Basin B
source master, the tracked prior source was preserved at
`custodian/asset_drop/source_work/awakening/awakening_ambulatory_fixtures/pre_handoff_service_basin_b_source.png`.

## Runtime verification

Asset V2 status reports Ambulatory 6/6, Dust Lung 4/4, and Undergate 6/6;
Attestation and Reliquary remain 0/7 and 0/3. Asset V2 doctor reports healthy
with no issues. All eleven newly published runtime PNGs have Godot import
sidecars. No room geometry, interaction, collision, or scene binding changed.
