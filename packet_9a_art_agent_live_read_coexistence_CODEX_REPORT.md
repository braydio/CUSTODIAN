# Packet 9A — Art Agent Live Read Coexistence Foundation

## Commit

`24a69b0e8` — pushed to `origin/main`

## Files changed

- Shared Lua Art Agent read executor and headless adapter wiring
- Live Art Agent relay and command-result waiters
- Read-only live-bridge protocol/capability support
- Relay lifecycle in the Workbench controller
- UI and relay validation fixtures
- Packet 9A documentation updates

## Shared Lua executor extraction

The shared executor now owns the live-safe `inspect` and render operations.
Transport adapters retain document lifecycle and persistence responsibilities.
Legacy mutation behavior remains headless-only and is not exposed to the live
bridge in Packet 9A.

## Headless Art Agent parity

Passed:

- `operator_art_agent_service_smoke.py`
- `operator_art_agent_aseprite_smoke.py`

## Relay endpoint and lifecycle

Implemented the loopback relay at `127.0.0.1:32148`, with strict authorized-root
confinement, one-request-per-connection framing, non-fatal startup failure, and
orderly shutdown. The bridge server now supports awaited command-result waiters.

## Live-read and collision behavior

- Matching live document: read requests execute against in-memory Aseprite data.
- Wrong document: relay returns `unavailable`; Python uses the legacy headless path.
- Matching mutation: relay returns `mutation_refused`; no Aseprite command or
  headless fallback is attempted.
- Live and headless responses use the same response validator.

## Presentation-state restoration

Live reads preserve and restore active frame, active layer, layer visibility,
filename, dirty state, and revision. Internal visibility changes are suppressed
from user-facing bridge events.

## Real Aseprite result

The real headless Aseprite inspect/render regression passed. Persistent GUI
transport was not available in this environment, so that lifecycle remains
covered by protocol/relay fixtures rather than a live desktop capture.

## Production immutability

Existing production immutability checks passed; no canonical or runtime Operator
assets were changed by the Packet 9A implementation.

## Validation

Passed in the project UI environment:

- Art Agent service and Aseprite smokes
- live relay smoke
- live bridge smoke
- Workbench UI smoke
- Timeline smoke
- Transition smoke
- Motion smoke

System-Python changed validation was not clean because the system environment
lacks `websockets` and the changed-file selector also included unrelated dirty
files. The project UI environment includes `websockets`; its focused live-bridge
validation passed.

## Documentation drift

Updated the live-bridge roadmap, `CURRENT_STATE.md`, `FILE_INDEX.md`, the Art
Agent system specification, and the Operator tooling README. Packet 9A is
documented as implemented; Packet 9B remains deferred.

## Packet 9B follow-up

Packet 9B still needs the full live mutation operation port, revision-locked
transactions, and in-memory undo/rollback semantics. No live mutation authority
was enabled by Packet 9A.
