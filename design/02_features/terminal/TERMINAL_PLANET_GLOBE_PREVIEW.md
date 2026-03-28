# Terminal Planet Globe Preview

## Goal

Replace the terminal's flat contracted-planet card preview with a terminal-only 3D globe preview that:

- renders into the existing terminal `PlanetPreview` panel
- is driven by the active contract `planet.key` and `planet_seed`
- can be rotated around its own axis by mouse drag
- behaves more like a globe viewer than a spinning 2D sprite

## Constraints

- Do not try to convert the existing PixelPlanets 2D scenes into real geometry at runtime.
- Keep the active world contract generation unchanged.
- Keep the 3D globe strictly as a terminal presentation layer.
- Preserve deterministic appearance from `planet_seed`.

## Runtime Approach

### Data Source

Use existing contract data from `CustodianContractMap`:

- `planet.key`
- `planet.planet_seed`

### Rendering Path

- Create a dedicated `SubViewport` for terminal planet rendering.
- Use a small 3D scene graph inside that viewport:
  - `Node3D` pivot
  - `MeshInstance3D` sphere
  - `Camera3D`
  - `DirectionalLight3D`
  - optional ambient environment
- Feed the viewport texture into the terminal `PlanetPreview` `TextureRect`.

### Globe Material

- Generate a seeded equirectangular texture procedurally at runtime.
- Map that texture onto the sphere mesh.
- Use palette families by `planet.key`:
  - `terran_wet`
  - `terran_dry`
  - `islands`
  - `ice_world`
  - `lava_world`
  - `gas_giant`

This does not need to visually match the old 2D PixelPlanets scenes one-to-one. It only needs to preserve contract identity and feel.

## Interaction

- Left-drag over the terminal planet preview rotates the globe.
- Horizontal drag controls yaw.
- Vertical drag controls pitch with clamping.
- Release leaves a small inertial carry, then settles.
- Rotation must occur around the globe's own center, not around an offset scene root.

## UX Expectations

- Terminal command input remains focus-sticky while terminal is open.
- Clicking or dragging the globe must not break terminal typing.
- The globe should be visually dominant over the smaller map preview.

## Terminal Shell Direction

The globe preview should sit inside a sleeker terminal shell rather than a debug-style panel.

### Layout Hierarchy

- Header:
  - short system eyebrow
  - terminal title
  - link / target status at the far right
- Left column:
  - command log
  - active command input row
  - concise link / operator status
- Right column:
  - large hero globe preview
  - compact map strip
  - short tactical summary block

### Text Direction

- Prefer short structured lines over prose paragraphs.
- Prioritize:
  - phase
  - threat
  - assault lane/objective
  - materials / defense
  - hostiles
  - contract seed / planet key / map seed
- Avoid repeating section labels in every line.

### Styling Direction

- Keep the shell dark, glassy, and low-noise.
- Use compact uppercase labels and larger title text.
- Give the command input stronger visual priority than the log body.
- Keep the planet panel dominant and the map panel secondary.

## Non-Goals

- No runtime replacement of in-world procgen contract planet scenes.
- No world-space camera orbit.
- No terrain picking, markers, or zoom-to-location behavior yet.
