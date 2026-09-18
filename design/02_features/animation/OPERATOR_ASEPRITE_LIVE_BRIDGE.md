# Operator Aseprite Live Bridge

## Status

Foundation, persistent Aseprite reporting client, and Workbench bridge
lifecycle implemented; bidirectional frame navigation deferred.

Packet 1 established the versioned protocol, loopback WebSocket server, tooling
state model, capability gate, path confinement, and fake-client validation.
Packet 2 adds the persistent reporting-only Aseprite extension. Packet 3A makes
the Workbench UI own server startup, status projection, and shutdown. No
command can mutate Aseprite yet.

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

The server defaults to `127.0.0.1:32147`; callers may explicitly request
`port=0` for isolated tests. It admits one client at a time, treats
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
2. **Aseprite Extension (implemented):** persistent Lua client and document/editor reporting.
3A. **Workbench Bridge Lifecycle (implemented):** Textual-owned startup, status, transition logging, failure projection, and shutdown.
3B. **Bidirectional Frame Navigation (deferred):** document focus and causal frame sync.
4. **Live Unsaved Preview (deferred):** debounced in-memory render export.
5. **Layer Synchronization (deferred):** focus and visibility proof/control.
6. **Preview Examiner (deferred):** live/saved/canonical/runtime comparison.
7. **Transition Examiner (deferred):** seam metrics and ghost review.
8. **Timeline Completion (deferred):** trims, loops, FPS, and source-frame navigation.
9. **Art Agent Coexistence (deferred):** guarded live-document mutation without weakening current locks or transactions.
10. **Workspace Polish (deferred):** lifecycle, recovery, and optional window layout.

Later packets must preserve the canonical publication boundary and may add only
semantic commands, never general remote execution.

## Persistent Aseprite client

The repo-owned extension lives at
`custodian/tools/aseprite/operator_live_bridge/`. Its `init(plugin)` lifecycle
creates one client session, starts the native reconnecting WebSocket, binds
`app.events.sitechange` plus active-sprite `change` and `filenamechange`
listeners, and starts a one-second reconciliation timer for save/close/dirty
state that lacks a dedicated complete event path. `exit(plugin)` stops the
timer, unregisters listeners, and closes the socket.

The default `ws://127.0.0.1:32147` URL is persisted in
`plugin.preferences.bridge_url`. Run
`custodian/tools/aseprite/install_operator_live_bridge.sh` once to install a
deterministic symlink beneath the user's Aseprite extensions directory; repo
updates then apply without repeated copying. The helper refuses to replace any
existing file, directory, or differently targeted symlink. Restart Aseprite to
load or reload the plugin.

One client UUID and one monotonically increasing client sequence span the
plugin lifecycle, including reconnects. Each WebSocket open sends a fresh
`client.hello` with actual Aseprite/API versions, the required capability set,
and current editor state. `server.hello` establishes the separate bridge
session; later inbound messages must use it and increase the bridge sequence.

`editor.site_changed` reports active document path/sprite ID, frame, layer name
and UUID, dirty flag, and the current revision. An explicit `has_document=false`
clears active editor/document state when nothing is open. Active-sprite content
changes, including undo/redo, monotonically increment one client-session
revision and emit `document.changed`. Filename changes and human saves are
observed without saving or opening anything on the user's behalf.

Packet 2 accepts only `server.hello` and heartbeat behavior. All four semantic
commands return `command.result` with `ok=false` and `unsupported in Packet 2`;
they never mutate the editor. Unknown schemas, sessions, sequences, and message
types fail closed.

## Validation

`custodian/tools/validation/operator_live_bridge_smoke.py` uses an in-process
fake WebSocket client. It proves stable and ephemeral endpoint contracts,
loopback lifecycle, typed handshake, rejection
of bad schemas and missing capabilities, state/revision updates, command
tracking and causality, non-destructive disconnect/reconnect, confined paths,
and canonical-file immutability. It also runs the protocol under the installed
Aseprite Lua runtime, checks the extension structure/reporting/refusal seams,
and proves the safe idempotent symlink installer in an isolated config root.

Persistent-plugin GUI automation is not deterministic in the current headless
validation environment. A manual/optional pilot may start a `port=32147`
server, install the symlink, restart Aseprite, and observe frame/pixel/save and
reconnect state without publishing; headless one-shot scripting is not claimed
as proof of plugin lifecycle behavior.

## Workbench lifecycle and connection UX

`custodian/tools/operator/ui/live_bridge_controller.py` is the focused Textual
lifecycle adapter. `OperatorWorkbenchApp` owns exactly one controller, starts it
as a non-blocking Textual worker after mounting the main screen, and projects an
immutable snapshot every 0.5 seconds. Widgets never receive the WebSocket or a
command surface, and live state is not copied into `WorkbenchUIState`.

The UI lifecycle states are `STOPPED`, `STARTING`, `WAITING`, `CONNECTED`, and
`UNAVAILABLE`. The compact status bar renders them as `LIVE ○ STOPPED`,
`LIVE … STARTING`, `LIVE ○ WAITING`, `LIVE ● CONNECTED`, or
`LIVE × UNAVAILABLE`. Only meaningful transitions enter ActivityLog: listening,
client connected/disconnected, and one concise startup warning.

Production UI startup uses the stable `127.0.0.1:32147` endpoint. Missing
optional WebSocket support and address-in-use errors become `UNAVAILABLE`; the
Workbench browser, editing, review, and publication surfaces continue normally.
The controller never chooses another port or terminates the conflicting owner.

Textual's awaited async unmount hook stops the server and bounds WebSocket close
waiting to one second. It does not close Aseprite, save a sprite, or mutate any
document. Aseprite remains open and its Packet 2 client quietly retries until a
future Workbench owns the endpoint.

## Next Agent Slice

Packet 3B may add causal document/frame navigation between the Workbench and the
already-reporting client. It must preserve the Packet 3A lifecycle/status
adapter and must not add preview rendering, layer control, Art Agent routing,
or canonical publication behavior.
