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
Recovery Ambulatory fixture family now has all six required states published
in the Asset V2 catalog; `service_basin_b` was ingested by the
`awakening-detail-assets-batch-01` handoff (2026-10-02) but is not yet bound
to a scene consumer, since its two candidate layout obstacle slots already
carry matching baked basin dressing in the live plate with no documented a/b
disambiguation. The same batch ingested the Late Service relay-lamp `idle`
state, all six required `awakening_authority_inlay` route-tile states, and
`awakening_ruin_decal` states `floor_crack_a`/`rubble_small`; none of these
are yet wired to a scene or tile consumer — no authority-inlay or ruin-decal
placement system exists in the live runtime, and the Late Service altar slot
already shows baked lamp art with the same binding ambiguity as the
Ambulatory basins. `awakening_ruin_decal` still requires `floor_crack_b`,
`floor_crack_c`, and `rubble_medium`.

## Partial / missing

`awakening_creche_fixtures` required coverage is complete: `alcove_closed`,
`alcove_broken`, `alcove_fused`, `alcove_empty`, `wall_of_seals`, `relic_table`,
and `authority_inscription` are present. Recommended dressing remains open.

`awakening_ambulatory_fixtures` required art is now fully published:
`service_basin_a`, `inspection_niche_medica`, `inspection_niche_vestment`,
`broken_mirror_panel`, and `hidden_reliquary_panel` are baked into the live
plate; `service_basin_b` is Asset V2-ready but unbound (see above).

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
