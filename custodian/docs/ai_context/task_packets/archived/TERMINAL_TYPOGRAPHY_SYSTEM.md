# TERMINAL TYPOGRAPHY SYSTEM

- Status: `complete`
- Authority: `design/02_features/terminal/BLACK_RELIQUARY_UI.md`, `custodian/docs/design/TERMINAL_UI_ASSETS.md`
- Goal: Replace ad hoc default terminal text with a licensed two-font hierarchy and disciplined overflow behavior, especially on Fabrication.
- Files: `game/ui/hud/ui.gd`, `content/ui/fonts/`, focused validation, terminal asset documentation, and AI context indexes.
- Constraints: Do not change gameplay; fonts must ship in-repo, remain licensed, load defensively, and never introduce horizontal scrolling as an overflow fix.
- Acceptance: Display/mono roles and approved sizes apply in both terminal theme passes; input is 16px; Fabrication rows/detail/filter use 12/12/11px; work rows ellipsize; relevant horizontal scrolling stays disabled; typography and existing Fabrication smokes pass.
- Completed: IBM Plex font binaries and OFL provenance are vendored; guarded loading, semantic helpers, hierarchy, sizes, clipping, no-wrap filters, and typography smoke are implemented. Typography, StyleBox, Fabrication layout/readability/command/clickable regressions, font import, and normal boot pass.
- Deferred: Manual visual review at supported desktop resolutions after automated validation.
