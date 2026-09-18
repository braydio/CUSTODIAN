# Operator Aseprite Live Bridge

## Status

Foundation implemented; Aseprite client deferred.

Packet 1 establishes the versioned protocol, loopback WebSocket server, tooling
state model, capability gate, path confinement, and fake-client validation. It
does not start from the Workbench UI and no Aseprite extension exists yet.

## Authority

The Operator Workbench is semantic selection, control, review, and publication
authority. Aseprite is the human pixel editor. An `.aseprite` document beneath
`.ai/operator_animation_workbench/` is disposable authoring state; it is not a
production source.

Canonical Operator PNGs remain production authority. Publication continues to
run exclusively through `animation_workbench.py` and its guarded transaction,
validation, and runtime projection. The live bridge is presentation/tooling
state only and may never influence deterministic gameplay or bypass publish.
The existing Art Agent one-shot Aseprite transport is unchanged.

## Architecture

`custodian/tools/operator/live_bridge/` owns a narrow local control channel:

```text
Operator Workbench (semantic/control authority)
             |
       loopback WebSocket
             |
Aseprite extension (future pixel editor client)
             |
 disposable .aseprite document
```

The server binds only to `127.0.0.1`, admits one client at a time, treats
disconnect/reconnect as ordinary state, and shuts down cleanly. The optional
`websockets` dependency stays in the Operator UI requirements so ordinary
`operator anim` commands remain independent of it.

## Protocol

Every message uses the exact fields `schema`, `session_id`, `sequence`, `type`,
`cause`, and `payload`. The schema is
`custodian.operator_live_bridge.message.v1`.

Packet 1 defines `client.hello`, `server.hello`, `editor.state`,
`editor.site_changed`, `document.changed`, `command.open_workbench`,
`command.select_frame`, `command.export_preview`, `command.save`,
`command.result`, and `heartbeat`.

Sequences identify commands and order each peer's messages. A consequence or
acknowledgement carries the originating command sequence in `cause`. A causal
site change is confirmation of a Workbench request; a site change without that
cause is a user-originated editor action. Reconnect establishes a fresh client
session without deleting last-known document/editor presentation state.

## Capability and filesystem boundary

`client.hello` supplies the Aseprite and API versions. The pure capability gate
requires equivalents for WebSocket, app `sitechange`, sprite change events,
`Sprite.isModified`, timers, frame selection, and image/render export. Tests do
not infer or require a locally installed Aseprite version.

Open commands are confined to `.aseprite` documents beneath
`.ai/operator_animation_workbench/`. Future preview exports are confined to
`.ai/operator_animation_workbench/live/` PNGs. These are ignored review
artifacts. Paths are resolved before containment checks, preventing traversal.
The protocol has no generic Lua, shell, or arbitrary-file command.

Pixels never cross the WebSocket. A later preview flow will carry revision and
export coordination only; Aseprite will render the in-memory sprite to the
confined ignored review location.

## Packet roadmap

1. **Live Bridge Core (implemented):** Python protocol/server/state and fake-client validation.
2. **Aseprite Extension (deferred):** persistent Lua client and document/editor reporting.
3. **Live Navigation (deferred):** document focus and causal frame sync.
4. **Live Unsaved Preview (deferred):** debounced in-memory render export.
5. **Layer Synchronization (deferred):** focus and visibility proof/control.
6. **Preview Examiner (deferred):** live/saved/canonical/runtime comparison.
7. **Transition Examiner (deferred):** seam metrics and ghost review.
8. **Timeline Completion (deferred):** trims, loops, FPS, and source-frame navigation.
9. **Art Agent Coexistence (deferred):** guarded live-document mutation without weakening current locks or transactions.
10. **Workspace Polish (deferred):** lifecycle, recovery, and optional window layout.

Later packets must preserve the canonical publication boundary and may add only
semantic commands, never general remote execution.

## Packet 1 validation

`custodian/tools/validation/operator_live_bridge_smoke.py` uses an in-process
fake WebSocket client. It proves loopback lifecycle, typed handshake, rejection
of bad schemas and missing capabilities, state/revision updates, command
tracking and causality, non-destructive disconnect/reconnect, confined paths,
and canonical-file immutability.

## Next Agent Slice

Packet 2 may add only the persistent Aseprite extension and its connection/state
reporting. It must consume this protocol, reconnect quietly when the Workbench
is absent, and must not add frame commands, preview export, layer control, UI
wiring, Art Agent routing, or canonical publication behavior.
