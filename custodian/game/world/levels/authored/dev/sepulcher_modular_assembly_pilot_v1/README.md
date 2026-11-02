# Sepulcher Four-Asset Assembly Pilot V1

Dev-only gameplay comparison reusing the real V2 Operator, controller, canonical
idle presenter, HUD, Camera2D and bootstrap. The four normalized pilot images and
full 768px wall strip under `preview/generated/` are review-only inputs; they
are not Asset Pipeline V2 inbox/runtime assets.

## Source provenance

The review bundle was retrieved from Dropbox path
`/CUSTODIAN/implementation_inputs/CUSTODIAN_sep_mats_four_asset_pilot_v1_20261101.zip`,
file ID `id:8NXqdXuW6GUAAAAAAAAGXg`, revision `65f3fc55fd636915cdd61`,
archive SHA-256 `bb7e2677ed46366ade16e0234a378fadc2785898afa865ade6093de2513ee694`.
The package verifier and normalization check passed before staging. Its installer
staged only the four unmodified source masters under `custodian/asset_drop/source_work/`;
all inbox installs were skipped and neither family is registered in Asset V2.

| State | Source SHA-256 | Dev normalized SHA-256 |
| --- | --- | --- |
| `paving_base` | `414b017edbcc1ba53e4d277e32b4dfb42752552a4be2a1a2ad764a3706eeb960` | `ea3cd7805a43eb72a0227a38fdf17e80bdc6ade78bd1d9969d7a22cab03f6c0b` |
| `paving_damage_overlay` | `5c90a66eb5c436d74f78e3771ba843bf096c810af8946c81870772b7df51ad92` | `c04f98158ab4aaba9b96cc4150e454b3fff138a34f9909865ee3829acd553f9f` |
| `witness_ring_inlay` | `800de773be5ef49333b4d2568a2c1d7160f36320c9ed251462bbb9d20ed10797` | `ecad5b82071921d0b6d3dfda39a3b531744e154f29520f490264b8c0959ebf77` |
| `retaining_wall_segment` | `94b172344d5d4e73329ba86135af6554563833eb7c21eb998e6e253af34e7a4c` | `ad8f830cd4c4edef87c1c78408f9fca2fdb11f6d2f488f9585b1084dd7887d6d` |

The complete 768×239 transparent wall strip is kept at
`preview/generated/retaining_wall_full_strip_768.png` (SHA-256
`d2f36bca4b4beb304b47d19e22bf3ba22297e3afd7bdec63928286493e597dea`).
The canonical Operator remains the existing V2 idle-only source with SHA-256
`d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`.

Launch with:

```bash
godot --path custodian res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/sepulcher_modular_assembly_pilot_v1.tscn
```

Controls: `1` neutral, `2` original courtyard, `3` NW repeat diagnostic, `4`
quiet modular, `5` four-asset assembly; `Tab` toggles modes 2/4, `M` toggles
4/5, `U` toggles rotated/unrotated paving, `D` damage, `R` ring, `W` wall art,
`J` wall module join diagnostic, `B` existing quiet-floor bronze routes, and
`V` canonical idle/legacy Operator visuals. Move with the ordinary gameplay
controls. The canonical 128px artwork is idle-only; motion/combat artwork has
not been authored or approved.
