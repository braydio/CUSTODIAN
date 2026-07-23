# Inventory Pause Menu Refinement

Status: implemented
Last updated: 2026-07-23

## Summary

The Black Reliquary inventory overlay is the Operator's field ledger and primary
pause-menu status surface. This refinement preserves its institutional
reliquary identity while removing nested-dashboard hierarchy, improving scan
speed, and making every control-looking element truthful and focusable.

The runtime remains presentation-only. `InventoryManager`, `ResourceLedger`,
equipment hooks, and item definitions retain gameplay authority.

## Information Architecture

The persistent header is:

```text
FIELD LEDGER     STATUS  EQUIPMENT  LEDGER  HISTORY     n RECORDS · n UNITS
```

The Ledger page presents three peers:

```text
CLASS | RECOVERED OBJECTS | INSPECTION
```

The old page-status label, `PAGES` label, `CARRIED REGISTER`, `INSPECTION
RECORD`, passive `VIEW: GRID` readout, and detached upper-right page hint are
removed. The category, recovered-object register, and inspection surfaces use
faint one-pixel framing. The register uses a lighter smoked surface than the
inspection panel so its cards remain connected to the Ledger rather than
floating over the paused world.

## Layout Contract

- Category rail: `170px`.
- Inspection panel: `380px`.
- Column gaps: `16px`.
- Item cards: `180x190px`.
- Item art viewport: fixed `118x118px`.
- Inspection art viewport: `144x144px`.
- Grid: four columns at widths of at least `1600px`, three from
  `1280-1599px`, and two below `1280px`, subject to the available register
  width.
- The inspection action is pinned below content. Only description/provenance
  scroll when necessary.

Cards use item art, a maximum two-line name, and an upper-right quantity badge.
Class stamps remain only where they add meaning for key objects, relics,
cognitive objects, or equipment; ordinary materials do not repeat `MAT`.

Cards lay out their icon and name through containers rather than absolute
positioning. Selection uses a persistent gold-black fill, full-intensity gold
edge, gold registration mark, brighter name, and a four-percent internal art
scale around the icon center. Keyboard or controller focus uses four
technical-cyan corner marks. Focus never replaces the selected record's gold
edge.

## Archive Glass

The full-screen backdrop samples the live viewport through Black Reliquary
Archive Glass. It uses moderate mip blur, reduced exposure and saturation,
soft highlight compression, a cold black-green tint, restrained vignette, and
extremely faint low-frequency grain. The world remains recognizable as a
paused in-world context, but its highlights cannot compete with active text or
selection borders. The inventory frame and page controls render after the
shader and remain sharp.

The backdrop intentionally excludes scanlines, RGB separation, barrel
distortion, animated waves, and conspicuous film grain.

The compact production-frame NinePatch is not stretched across the fullscreen
Ledger. The local `ReliquaryFrame` style retains the outer border without
creating a second overbright arch behind page content.

## Status, Footer, And Equipment

- The Status map uses a `480x300px` standard minimum. At `1280x720`, the left
  status panel contracts to about `280px`, the map minimum contracts to
  `400x250px`, and vertical spacing tightens so all six status rows remain
  above the footer.
- Status rows are configured through the reusable icon-label component before
  tree entry, preventing its `_ready()` lifecycle from clearing initially
  unset/default values or collapsing row height.
- Input prompts sit on a dedicated `38px`, near-opaque footer strip with a
  faint top border.
- Equipment uses two honest columns: `ACTIVE SLOTS` contains only implemented
  slots, while `AVAILABLE EQUIPMENT` lists unequipped Ledger records in the
  equipment category or displays `NO UNEQUIPPED EQUIPMENT`.

## Controls

- Category filtering and class/name sorting are real focusable buttons.
- `F` / controller `X` cycles filters.
- `R` / controller right-stick click toggles class-first and name-first sorting.
- `Q` / `LB` and `E` / `RB` cycle pages.
- Close and footer prompts switch between keyboard/mouse and controller
  language based on the latest input device.
- Reopening the menu preserves the last page for the current UI instance.

## Icon Normalization

Canonical card icons live at:

```text
custodian/content/ui/inventory/runtime/icons/icon_<item_id>.png
```

`custodian/tools/ui/normalize_inventory_icons.py` crops existing source alpha,
uses nearest-neighbor scaling, and centers the result on a transparent
`128x128px` canvas. The visible long edge is `96px`, inside the accepted
`88-104px` range. This is normalization of existing art, not illustration.
Dedicated portraits such as the P-9 may remain explicit catalog overrides.

## Validation

Run from `custodian/`:

```bash
godot --headless --path . --script tools/validation/inventory_ui_smoke.gd
godot --headless --path . --script tools/validation/inventory_ui_responsive_smoke.gd
godot --headless --path . --script tools/validation/black_reliquary_ui_smoke.gd
```

Run from the repository root:

```bash
python custodian/tools/ui/normalize_inventory_icons.py --check
```

The responsive smoke covers `2048x1152`, `1920x1080`, `1600x900`,
`1280x720`, and the existing `1152x648` two-column guard. It validates card
icon containment, register backing, Status/footer containment at supported
visual-check sizes, and keyboard/controller prompt modes. Graphical runs also
write Status, Ledger, and Equipment captures under `user://`; headless runs
skip capture because the dummy display has no viewport texture.

## Next Agent Slice

Goal: replace textual device prompts with production glyph textures once a
shared input-glyph asset/component contract exists.

Files: `inventory_ui.gd`, shared input-prompt components, and canonical UI
glyph assets.

Constraints: retain live text fallback, controller focus, page persistence,
and gameplay/input authority outside presentation.

Acceptance: glyph family switches correctly for keyboard, Xbox, PlayStation,
and other supported devices without changing page/filter/sort behavior.
