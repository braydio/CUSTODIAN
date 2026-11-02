# Field Fabricator Mk1 — Production Runtime Integration

**Status:** production runtime integrated
**Authority:** `custodian/design/02_art_direction/CUSTODIAN_STRUCTURE_DESIGN_CONTRACT.md`
**Runtime target:** `custodian/game/infrastructure/structures/field_fabricator_mk1.tscn`

## Locked Contracts

The Field Fabricator retains its `4×3` logical footprint, `92×64` solid
collision, `320` maximum integrity, and `10/25/40 P` minimum/standard/overdrive
power contract at priority `30`. ResourceLedger, BuildInventory, FabPipeline,
InfrastructureRegistry, and WorldSimulationRuntime retain their existing
authority boundaries.

The physical Mk1 is the local `FABRICATION` service provider. FabPipeline is a
single-lane FIFO adapter: only queue slot zero progresses, zero service pauses
its elapsed time, and missing or destroyed providers cannot fabricate or accept
new orders. An intact unpowered provider may accept queued work for later
resumption.

## Production Art Contract

All lifecycle sheets use eight horizontal `156×156` frames (`1248×156`).

| Layer | State | FPS | Playback |
|---|---|---:|---|
| body | `idle` | 6 | loop |
| body | `startup` | 9 | one-shot |
| body | `fabricate` | 8 | loop |
| body | `fabricate_complete` | 9 | one-shot |
| body | `offline` | 6 | loop |
| FX | `idle` | 6 | loop |
| FX | `startup` | 9 | one-shot |
| FX | `fabricate` | 8 | loop |
| FX | `fabricate_complete` | 9 | one-shot |

Canonical runtime sheets live below
`content/sprites/environment/props/field_fabricator_mk1/runtime/{body,fx}/interaction/`
and end in `__8f__156.png`. Body presentation may fall back to idle for an
optional future state. FX never falls back: a missing exact overlay hides the
FX node. There is intentionally no `offline_fx`; the offline machine is dark.

## Presentation State Machine

Power loss wins over all other presentation and selects `offline`. A transition
from zero to positive service plays `startup`, then selects `fabricate` when a
job exists or `idle` otherwise. The active FIFO job selects `fabricate`; its
completion plays `fabricate_complete`, then returns to `fabricate` for the next
queued job or `idle` for an empty queue. Destroyed state selects `offline`.
Damage reduces throughput through the existing integrity-scaled service output
rather than introducing random stoppage.

## Physical Interaction and Terminal Truth

The `Interaction` child sits at local `Vector2(0, 48)`, implements the shared
`interactable` contract, and calls
`/root/GameRoot/UI.open_fabricator_terminal()`. This opens the same FABRICATION
page available through the Command Terminal; it does not introduce another
recipe, payment, queue, or inventory authority.

The terminal view model projects the registered structure, its PowerConsumer,
and FabPipeline queue as read-only state: `OFFLINE`, `DEGRADED`, `ONLINE`,
`OVERDRIVE`, or `DESTROYED`; allocated/standard power; effective throughput;
integrity; active recipe/progress; and waiting count. Terminal commands enter
FabPipeline only and never mutate power or integrity.

## Validation

Focused authority lives in:

- `tools/validation/field_fabricator_visual_smoke.gd`
- `tools/validation/powered_fabricator_slice_smoke.gd`
- `tools/validation/fabrication_terminal_command_smoke.gd`
- `tools/validation/fabrication_terminal_clickable_smoke.gd`

Manual review still owns silhouette, ramp readability, restrained teal light,
collision feel, and animation timing quality at gameplay zoom.
