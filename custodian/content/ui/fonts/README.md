# CUSTODIAN UI Fonts

Runtime terminal typography uses IBM Plex from the official IBM Plex repository.

| Runtime file | Upstream face | Terminal role |
|---|---|---|
| `terminal_mono_regular.ttf` | IBM Plex Mono Regular | logs, values, status, input, and body copy |
| `terminal_mono_bold.ttf` | IBM Plex Mono Bold | work-order rows and compact command buttons |
| `terminal_display_regular.ttf` | IBM Plex Sans Condensed Regular | titles, section headers, and navigation |

Source revision: `IBM/plex@2f9ba1b25957d958db71a849e85d72e3ecfb845a`.

The fonts are licensed under the SIL Open Font License 1.1. The bundled license and provenance notes live under
`source/`. Godot should use normal dynamic-font import settings; these are not bitmap/pixel fonts and must not use
texture-nearest import rules.
