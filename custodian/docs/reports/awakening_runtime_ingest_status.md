# Awakening Runtime Ingest Status

Status: first-pass production art is runtime-bound and verified for the listed
states. This is not a claim that Awakening art is complete.

## Completed

Crèche console, console activation FX, recovery alcove idle/wake, Custodian
Approach, Designation Locker, Dust Lung lift, Gate Plaza, Undergate, Gate of
Dust components, and Late Service underlay/foreground are present in the Asset
V2 catalog and load through the Awakening runtime route. Late Service uses the
canonical 704×768 pair under `content/levels/awakening/09_late_service/` with
one shared resize transform and production foreground occlusion.

The Crèche fixture family now has all seven required states published. The
Recovery Ambulatory fixture family has five of six required states published;
`service_basin_b` remains the only required gap.

## Partial / missing

`awakening_creche_fixtures` required coverage is complete: `alcove_closed`,
`alcove_broken`, `alcove_fused`, `alcove_empty`, `wall_of_seals`, `relic_table`,
and `authority_inscription` are present. Recommended dressing remains open.

`awakening_ambulatory_fixtures` is partial: `service_basin_a`,
`inspection_niche_medica`, `inspection_niche_vestment`, `broken_mirror_panel`,
and `hidden_reliquary_panel` are present; `service_basin_b` remains required.

## Tooling and housekeeping

Canonical normalization, staging, and review entrypoints now live under
`custodian/tools/art/`. Normalization never mutates source masters, staging
checks live family dimensions, and review inventory only treats explicit frame
markers or resolved animation contracts as strips. Recovery-alcove inbox files
were consumed duplicates of the already-bound idle/wake inputs and were removed
from the inbox; source masters remain preserved under `source_work/`.

## Runtime verification

Focused Asset V2 status, existing Awakening presentation smokes, and the
Awakening route resource parse were run. Late Service is wired into
`awakening_first_return.tscn` as an underlay plus foreground occlusion pair.
No room geometry or collision was changed. A dedicated visual capture harness
remains future work; the maintained Awakening route and presentation smokes
are the current verification path.
