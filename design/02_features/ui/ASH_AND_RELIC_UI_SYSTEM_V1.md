# Ash & Relic UI Design Authority V1

**Status:** Owner adopted 2026-11-11. This is the approved visual direction; it is not an assertion of implementation.

**Optional editable concept board:** https://www.tldraw.com/f/mZpfs1EDfrpCBhvxj3ef4

## Core rule

CUSTODIAN's interface is an ancient instrument of observation and judgment. It should be precise, sparse, legible, mineral and civic, leaving the game world unobstructed. Visual art, textures and ornament can be replaced freely. Gameplay, input, saves, terminal commands and interaction semantics remain controlled by their existing owners.

**Three separate palettes:** physical material identity is consistent, environments freely change color and lighting, and the UI keeps the same semantic colors regardless of location. The UI may adopt one nonessential district accent for a thin reveal line but must never recolor health, ammunition or warnings based on biome.

## Approved base palette

| Name | Hex | Intended role |
| --- | --- | --- |
| Void Ink | `#11191D` | backdrop/shadows |
| Charcoal | `#30383D` | structural darkness |
| Mineral Slate | `#59646A` | midtone structure, NOT ordinary small text |
| Weathered Stone | `#94938A` | architectural midlight |
| Bone Ivory | `#D9D2C1` | primary text/stone highlight |
| Old Bronze | `#B49A71` | active selection/civic detail |
| Oxidized Teal | `#668F88` | interaction/status |
| Dusty Wine | `#A56766` | health/sacrifice bar |
| Archive Blue | `#839EBD` | cognition |

**Readable UI role tier:** panel `#171E22`; primary `#D9D2C1`; secondary `#ADB5B2`; active `#D8C196`; interaction `#98C1B8`; critical text `#E0AAA7`; cognition text `#A7B9D7`. Opaque or near-opaque (~92–96%) field plaques work on bright snow and dark ruins. Verify real text/background contrast; add glyph/word redundancy rather than communicating danger by hue alone. Electric cyan/green in older Black Reliquary are reserved for exceptional diagnostic signals, not everyday HUD chrome.

**Existing theme authority:** `custodian/game/ui/theme/black_reliquary_palette.gd` and `black_reliquary_styles.gd`. Add semantic tokens with backward compatibility. Do not create rival theme libraries.

## Typography

Use **existing** IBM Plex resources; no new font asset required:
- `res://content/ui/fonts/terminal_display_regular.ttf` — condensed location/section title, 20–24 px at 1280×720.
- `res://content/ui/fonts/terminal_mono_regular.ttf` — ordinary label 15–16 px, secondary 13–14 px.
- `res://content/ui/fonts/terminal_mono_bold.ttf` — numeric readout 16–18 px.

Never use per-node `scale = Vector2(0.5, 0.5)` to shrink essential field UI. Use real sizes, anchors and containers, clipped-by-design only for secondary information.

## Field HUD v1

1280×720 baseline with ~20 px outer safe margin. Top-left: compact health/integrity and stamina bars/numbers. Top-center: 2.5-second location reveal, thin accent divider and short fades. Top-right: optional minimap only where established gameplay rules permit; **campaign field HUD must not gain a mandatory always-on minimap/compass**. Bottom-left: one provider-backed context prompt honoring one-shot/proximity/latched leases. Bottom-right: weapon, magazine/reserve, reload/overheat/heat when active. Keep center clear of persistent panels.

Modes: *explore* = quiet; *combat* = emphasize vitals/weapon; *interact* = show one authoritative prompt; *pause/ledger* = existing full-screen owner. Presentation animation cannot affect simulation. No invented combat signals. Notifications should be brief and nonblocking.

Responsive reference sizes: **1024×648, 1280×720, 1920×1080**. No overlapping vital, prompt, weapon or minimap groups; reticle and Operator remain unobstructed.

## Runtime boundaries

The global `custodian/scenes/game.tscn` uses `res://game/ui/hud/ui.gd` CanvasLayer, which still owns substantial terminal, HUD, inventory coordination and command compatibility. For Field HUD v1, KEEP this integration authority. Add ONE passive field presenter receiving existing truthful state, and hide **only** duplicated legacy normal-play visual widgets after the new view is ready. Do not hide entire UI hierarchy. Keep input and command routing, inventory, pause, construction, minimap integrations and save schemas intact.

A separate `custodian_hud.tscn`/`.gd` serves local Black Reliquary contexts including Sundered Keep. Preserve those API consumers during Field HUD v1; prevent simultaneous duplicated field HUDs within one context. Replacing every existing UI scene is a later explicit task, not part of the first landing.

## Chromatic progression

Preserve `design/04_architecture/HUB_CHROMA_PROGRESSION.md`: Sacrifice red/wine, Authority amber/gold, Cognition blue/violet, Persistence green, Synthesis white/iridescent. Environmental saturation changes with campaign evidence; interface meaning remains fixed. Do not globally desaturate all original art.

## Five-slice roadmap, not an automatic dependency DAG

1. **Field HUD v1:** one true main-game implementation and responsive state/input proof. This is the only currently authorized ready task packet.
2. Inventory & Ledger.
3. Terminal & Fabrication.
4. Map & Wayfinding.
5. Global UI cutover, asset retirement and consistency polish.

Later slices receive a **fresh user/ChatGPT packet on request**, after review of the prior result. No future task is queued, claimed or required for Field HUD v1 completion.

## Future artwork, not needed for current implementation

Possible new Asset V2 family `custodian_ui_ash_relic_icons_v1`: **64×64 RGBA, one frame per icon**, shared silhouette registration; states integrity/stamina/interact/ammo/warning/navigation. Proposed paths:
- `custodian/asset_drop/source_work/ui/custodian_ui_ash_relic_icons_v1/`
- `custodian/asset_drop/inbox/custodian_ui_ash_relic_icons_v1/`
- `custodian/content/metadata/assets/families/custodian_ui_ash_relic_icons_v1.asset.json`

These do not yet exist. Confirm pipeline schema and obtain individual human source approvals before future Asset V2 ingestion. **Current Field HUD must work with shipped fonts and Godot-native controls, without new binary assets.**

## Documentation state

Older Black Reliquary UI documents describe current production implementation, not this new design. Update them only after corresponding code surfaces are actually migrated. The existing F03 HUD/terminal architecture audit correctly notes remaining command-routing authority in `ui.gd`; this visual redesign does not resolve that debt.

**Authoring chat:** not-recorded until the originating conversation URL is supplied.