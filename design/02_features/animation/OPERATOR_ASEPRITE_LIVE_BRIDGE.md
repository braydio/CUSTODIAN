# Operator Aseprite Live Bridge

## Status

Foundation, persistent Aseprite reporting client, Workbench bridge lifecycle,
bidirectional frame navigation, and live unsaved Preview implemented; layer
synchronization deferred.

Packet 1 established the versioned protocol, loopback WebSocket server, tooling
state model, capability gate, path confinement, and fake-client validation.
Packet 2 adds the persistent Aseprite extension. Packet 3A makes the Workbench
UI own server startup, status projection, and shutdown. Packet 3B adds guarded,
causal frame navigation for the selected disposable authoring document only.
Packet 4 renders revision-guarded unsaved pixels into a disposable review strip
without saving the Aseprite document.

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
Aseprite extension (pixel editor client)
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

Open and preview commands are confined to `.aseprite` documents beneath
`.ai/operator_animation_workbench/`. Live preview exports are confined to
`.ai/operator_animation_workbench/live/` PNGs. These are ignored review
artifacts. Paths are resolved before containment checks, preventing traversal.
The protocol has no generic Lua, shell, or arbitrary-file command.

Pixels never cross the WebSocket. The bridge carries revision and export
coordination only; Aseprite renders the in-memory sprite to the confined ignored
review location.

## Packet roadmap

1. **Live Bridge Core (implemented):** Python protocol/server/state and fake-client validation.
2. **Aseprite Extension (implemented):** persistent Lua client and document/editor reporting.
3A. **Workbench Bridge Lifecycle (implemented):** Textual-owned startup, status, transition logging, failure projection, and shutdown.
3B. **Bidirectional Frame Navigation (implemented):** guarded causal frame sync between manual Preview navigation and the active authoring document.
4. **Live Unsaved Preview (implemented):** debounced, revision-guarded in-memory render export.
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

Packet 4 accepts `command.select_frame` and `command.export_preview`.
`command.open_workbench` and `command.save` return `command.result` with
`ok=false`. Unknown schemas, sessions, sequences, and message types fail closed.

## Bidirectional frame navigation

Workbench preview indexes are zero-based; Aseprite frame numbers are one-based.
`LiveBridgeController.select_frame()` owns that conversion and sends the exact
expected disposable `workbench.aseprite` path with every request. Python path
confinement rejects documents outside `.ai/operator_animation_workbench/`, and
the Lua client independently requires its active sprite filename to match
before assigning `app.frame`.

Validated hello/site messages are delivered immediately through a narrow
server-listener and controller-event queue while `BridgeState` remains the sole
transport state authority. A human Aseprite frame selection has no `cause` and
immediately updates the selected Workbench animation frame. A frame selected by
the Workbench carries the command sequence back on the resulting site event;
the UI records but does not reapply that causal confirmation, preventing a
feedback loop.

Only manual Preview scrub/Left/Right/Home/End navigation sends frame commands.
Automatic Preview playback, Timeline navigation/playback, and Motion
navigation/playback remain independent review clocks and never drive Aseprite.
Events for another document are ignored and never switch semantic animation
identity. Opening/focusing documents and cross-document semantic following are
still deferred.

## Live unsaved Preview

When PREVIEW is on its existing `workbench` source and the connected Aseprite
document exactly matches the selected workspace, `document.changed` starts a
150 ms exclusive debounce. Only the newest client-session revision is exported.
Entering PREVIEW also requests the current revision immediately. Failed, stale,
wrong-document, disconnected, and superseded requests are silent review-state
conditions rather than modal errors.

The controller chooses one stable SHA-keyed artifact per document beneath
`.ai/operator_animation_workbench/live/`. The Lua client validates the active
document and revision, reads adjacent `workbench.json`, and composites only the
manifest `layers` whitelist from bottom to top into one horizontal detached
`Image`. Reference, guide, landmark, and review-note layers are therefore not
eligible. Missing, non-image, or ambiguously duplicated manifest layer names
fail closed. The detached image is saved as PNG without changing visibility,
calling any sprite save API, clearing dirty state, or writing the `.aseprite`.

The successful causal result reports the artifact path, revision, frame count,
and dynamic frame dimensions. The Workbench verifies the result is still the
current revision and deterministic expected path, loads it as source `live`,
and redraws Preview without changing `WorkbenchUIState.preview_source` from
`workbench`. The source selector therefore remains exactly WORKBENCH / CANONICAL
/ RUNTIME. Timeline and Motion always retain persisted-source behavior. When
Aseprite is disconnected, existing saved Workbench preview export remains the
fallback.

Authority remains explicit:

```text
live PNG          = disposable review artifact
workbench.aseprite = disposable authoring document
canonical PNG     = production source authority
runtime assets    = generated execution authority
```

## Validation

`custodian/tools/validation/operator_live_bridge_smoke.py` uses an in-process
fake WebSocket client. It proves stable and ephemeral endpoint contracts,
loopback lifecycle, typed handshake, rejection
of bad schemas and missing capabilities, state/revision updates, command
tracking and causality, non-destructive disconnect/reconnect, confined paths,
and canonical-file immutability. It also runs the protocol and a real detached
manifest-filtered two-frame render under the installed Aseprite Lua runtime,
proving unsaved pixels are present, reference pixels are absent, dirty state is
preserved, and the `.aseprite` remains byte-identical. It checks refusal seams
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

Packet 5 may add layer focus/visibility synchronization. It must preserve the
manifest-whitelisted render boundary, keep reference/review layers outside
production-style composition, and must not add save/publication or Art Agent
mutation authority.
