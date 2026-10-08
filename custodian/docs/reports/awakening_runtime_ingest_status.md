# Awakening Runtime Ingest Status

Status: first-pass production art is runtime-bound and imported for the listed
states. This is not a claim that Awakening art is complete, and publication does
not imply a separate scene binding.

## Completed

Crèche console and console activation FX both have verified Asset V2 runtime
outputs. Awakening now builds the existing 8-frame activation sheet into one
non-looping runtime presentation at the Layout-owned Crèche console marker; the
first acknowledgement plays it once, then stops and hides it. The progression
smoke verifies the frame strip, playback, one-shot behavior, and reset state.
Asset V2 status still reports the runtime PNG as imported while its static
consumer binding remains unverified because the sprite is assembled from code.
Recovery alcove idle/wake, Custodian Approach, Designation Locker, Dust Lung lift, Gate
Plaza, Undergate, Gate of Dust components, and Late Service
underlay/foreground remain present in the Asset V2 catalog/runtime path. Late
Service uses the canonical 704×768 pair under
`content/levels/awakening/09_late_service/` with one shared resize transform
and production foreground occlusion.

The Crèche fixture family has all seven required states published. The
`awakening_ambulatory_fixtures` family now has all six required states,
including `service_basin_b` (Asset V2 job
`job_20261007T140317Z_c027e86a`). `awakening_dust_lung_structures` is 4/4
(job `job_20261007T140446Z_1d47c503`) and
`awakening_undergate_machinery` is 6/6 (job
`job_20261007T140503Z_b6135b78`). All eleven new runtime PNGs were imported by
Godot. No new scene bindings were introduced.

## Completed required fixture intake

The currently actionable 21-state Dropbox intake is published and imported:
Ambulatory 6/6 (`job_20261007T140317Z_c027e86a`), Attestation 7/7
(`job_20261007T193241Z_c557cbae`), Reliquary 3/3
(`job_20261007T193254Z_0f45bf23`), Dust Lung structures 4/4
(`job_20261007T140446Z_1d47c503`), and Undergate machinery 6/6
(`job_20261007T140503Z_b6135b78`). All 21 runtime PNGs have Godot import
sidecars. No new scene bindings were introduced; the fixtures retain their
`BAKED_ONLY` or `NOT_READY` consumption classifications under existing layout
and placement authority.

A2 was consumed from Dropbox revision `65d22e7369f4c915cdd61`, outer SHA-256
`82012a4f2b0285b8833eb3daa2878e49e7798e123970ab17fd304c9af757c9a4`. Its
manifest and all ten source/normalized contracts passed. `attestation_dais`
received the packet-authorized exact one-revision alpha-island cleanup; only
848 source and 204 normalized satellite alpha pixels were cleared. The
revision-specific provenance originals and full before/after/topology/principal
byte-identity receipt are retained at
`custodian/docs/ai_context/reports/assets/attestation_dais_a2_correction_receipt.json`.

The current required-asset projection reports all five families complete for
these required states. No room geometry, interaction, collision, or scene
binding changed.

## Tooling and housekeeping

Canonical normalization, staging, and review entrypoints live under
`custodian/tools/art/`. Normalization does not mutate source masters, staging
checks live family dimensions, and review inventory only treats explicit frame
markers or resolved animation contracts as strips. Before replacing the Basin B
source master, the tracked prior source was preserved at
`custodian/asset_drop/source_work/awakening/awakening_ambulatory_fixtures/pre_handoff_service_basin_b_source.png`.

## Runtime verification

Asset V2 status reports Ambulatory 6/6, Attestation 7/7, Reliquary 3/3,
Dust Lung 4/4, Undergate 6/6, and Crèche console activation 1/1. Asset V2 doctor
reports healthy with no issues. All 21 newly published runtime PNGs have Godot
import sidecars. The console activation runtime presentation is consumed in
code; no room geometry or collision changed.
