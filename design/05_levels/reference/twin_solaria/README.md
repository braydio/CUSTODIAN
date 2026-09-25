# Twin Solaria Canonical Visual Reference

**Status:** persistent documentation reference  
**Purpose:** preserve the current Twin Solaria master composite beside its canonical level/lore design authority  
**Runtime authority:** none  
**Asset Pipeline V2 status:** not an intake family and not a runtime binding

## Canonical reference

![Twin Solaria Crown Route Court reference](twin_solaria_crown_route_court_reference.png)


- Persistent documentation copy:
  `design/05_levels/reference/twin_solaria/twin_solaria_crown_route_court_reference.png`
- Dimensions: **3500 x 3000**
- Git LFS object: `sha256:20d42bce2ced38d2cd3cd2a162ce2f4706e91d95015b28193b112c82bb975759`
- LFS payload size: **16,402,002 bytes**
- Source copied from:
  `custodian/content/levels/hub/twin_solaria/development/twin_solaria_rebuilt_upscaled.png`
- Existing development consumer:
  `custodian/scenes/twin_solaria_backdrop_test.tscn`

The development copy remains in place because the existing fidelity-preview scene still
references it. This documentation copy is the persistent visual record used by
`design/05_levels/TWIN_SOLARIA.md`.

## Preservation rule

This file is a canonical **visual reference**, not a production runtime texture contract.

Do not:

- route runtime code to this path;
- treat the raster as authored collision or navigation;
- overwrite it in place when later art changes the level;
- send it directly through Asset Pipeline V2 as a monolithic gameplay asset;
- infer exact collision from painted architectural edges.

If the composition is materially revised, preserve this reference and add a new
versioned documentation image beside it, then update the level spec to identify
which version is canonical.

Any new runtime art derived from this reference must enter through Asset Pipeline V2
using a registered family and normalized inbox contract.
