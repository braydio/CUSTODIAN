local Protocol = nil
local LivePreview = nil

local socket = nil
local client = nil
local connected = false
local exiting = false
local active_sprite = nil
local revision = 0
local site_listener = nil
local sprite_change_listener = nil
local filename_change_listener = nil
local reconcile_timer = nil
local last_snapshot_signature = nil
local pending_site_change = nil

local function runtime_capabilities_available()
  return WebSocket ~= nil and Timer ~= nil and Uuid ~= nil and Image ~= nil and
    json ~= nil and app.events ~= nil and app.apiVersion ~= nil
end

local function layer_identity(layer)
  if layer == nil then
    return nil, nil
  end
  local layer_id = nil
  local ok, value = pcall(function() return tostring(layer.uuid) end)
  if ok then layer_id = value end
  return layer.name, layer_id
end

local function editor_state()
  local sprite = app.sprite
  if sprite == nil then
    return { has_document = false, revision = revision }
  end
  local layer_name, layer_id = layer_identity(app.layer)
  local state = {
    has_document = true,
    document_path = sprite.filename,
    sprite_id = sprite.id,
    modified = sprite.isModified,
    revision = revision,
  }
  if app.frame ~= nil then state.frame = app.frame.frameNumber end
  if layer_name ~= nil then state.layer = layer_name end
  if layer_id ~= nil then state.layer_id = layer_id end
  return state
end

local function snapshot_signature(state)
  return table.concat({
    tostring(state.has_document), tostring(state.document_path),
    tostring(state.sprite_id), tostring(state.frame), tostring(state.layer),
    tostring(state.layer_id), tostring(state.modified), tostring(state.revision),
  }, "|")
end

local function send(message_type, payload, cause)
  if connected and socket ~= nil and not exiting then
    socket:sendText(Protocol.encode_message(client, message_type, payload, cause))
  end
end

local function unbind_sprite()
  if active_sprite ~= nil then
    if sprite_change_listener ~= nil then
      pcall(function() active_sprite.events:off(sprite_change_listener) end)
    end
    if filename_change_listener ~= nil then
      pcall(function() active_sprite.events:off(filename_change_listener) end)
    end
  end
  active_sprite = nil
  sprite_change_listener = nil
  filename_change_listener = nil
end

local function send_site_state(cause)
  local state = editor_state()
  last_snapshot_signature = snapshot_signature(state)
  send("editor.site_changed", state, cause)
end

local function bind_active_sprite()
  local sprite = app.sprite
  if sprite == active_sprite then return end
  unbind_sprite()
  active_sprite = sprite
  if sprite == nil then return end

  sprite_change_listener = function()
    revision = revision + 1
    local state = editor_state()
    last_snapshot_signature = snapshot_signature(state)
    send("document.changed", {
      revision = revision,
      modified = sprite.isModified,
      document_path = sprite.filename,
      sprite_id = sprite.id,
    }, nil)
  end
  filename_change_listener = function()
    send_site_state(nil)
  end
  sprite.events:on("change", sprite_change_listener)
  sprite.events:on("filenamechange", filename_change_listener)
end

local function handle_site_change()
  bind_active_sprite()
  local cause = nil
  if pending_site_change ~= nil then
    local frame = app.frame and app.frame.frameNumber or nil
    if frame == pending_site_change.frame then
      cause = pending_site_change.cause
    end
    pending_site_change = nil
  end
  send_site_state(cause)
end

local function send_command_result(message, ok, error_message)
  send("command.result", { ok = ok, error = error_message }, message.sequence)
end

local function handle_select_frame(message)
  local payload = message.payload or {}
  local frame = payload.frame
  local expected_path = payload.document_path
  local sprite = app.sprite
  if sprite == nil then
    send_command_result(message, false, "no active Aseprite document")
    return
  end
  if type(expected_path) ~= "string" or expected_path == "" then
    send_command_result(message, false, "document_path is required")
    return
  end
  if sprite.filename ~= expected_path then
    send_command_result(message, false, "active document does not match requested workbench")
    return
  end
  if type(frame) ~= "number" or frame % 1 ~= 0 or frame < 1 or frame > #sprite.frames then
    send_command_result(message, false, "frame is outside active document")
    return
  end
  if app.frame ~= nil and app.frame.frameNumber == frame then
    send_site_state(message.sequence)
    send_command_result(message, true, nil)
    return
  end
  pending_site_change = { cause = message.sequence, frame = frame }
  app.frame = frame
  send_command_result(message, true, nil)
end

local function export_result(message, payload)
  payload.operation = "export_preview"
  send("command.result", payload, message.sequence)
end

local function handle_export_preview(message)
  local payload = message.payload or {}
  local expected_path = payload.document_path
  local output_path = payload.output_path
  local expected_revision = payload.revision
  local sprite = app.sprite
  if sprite == nil then
    export_result(message, { ok = false, error = "no active Aseprite document" })
    return
  end
  if type(expected_path) ~= "string" or expected_path == "" then
    export_result(message, { ok = false, error = "document_path is required" })
    return
  end
  if sprite.filename ~= expected_path then
    export_result(message, {
      ok = false,
      error = "active document does not match requested workbench",
      document_path = sprite.filename,
      revision = revision,
    })
    return
  end
  if type(output_path) ~= "string" or output_path == "" then
    export_result(message, { ok = false, error = "output_path is required" })
    return
  end
  if type(expected_revision) ~= "number" or expected_revision % 1 ~= 0 or expected_revision < 0 then
    export_result(message, { ok = false, error = "invalid expected revision" })
    return
  end
  if expected_revision ~= revision then
    export_result(message, {
      ok = false,
      error = "stale live preview revision",
      document_path = sprite.filename,
      revision = revision,
    })
    return
  end

  local manifest_path = app.fs.joinPath(app.fs.filePath(sprite.filename), "workbench.json")
  if not app.fs.isFile(manifest_path) then
    export_result(message, {
      ok = false,
      error = "workbench manifest missing",
      document_path = sprite.filename,
      revision = revision,
    })
    return
  end

  local modified_before = sprite.isModified
  local ok, result = pcall(function()
    local manifest = LivePreview.read_json(manifest_path)
    return LivePreview.render(sprite, manifest, output_path)
  end)
  if not ok then
    export_result(message, {
      ok = false,
      error = tostring(result),
      document_path = sprite.filename,
      revision = revision,
    })
    return
  end
  if sprite.isModified ~= modified_before then
    export_result(message, {
      ok = false,
      error = "live preview render changed document dirty state",
      document_path = sprite.filename,
      revision = revision,
    })
    return
  end
  export_result(message, {
    ok = true,
    document_path = sprite.filename,
    output_path = output_path,
    revision = revision,
    modified = sprite.isModified,
    frames = result.frames,
    frame_width = result.frame_width,
    frame_height = result.frame_height,
  })
end

local function handle_server_text(text)
  local message = Protocol.decode_server_message(client, text)
  if message == nil then return end
  if message.type == "command.select_frame" then
    handle_select_frame(message)
    return
  end
  if message.type == "command.export_preview" then
    handle_export_preview(message)
    return
  end
  local response = Protocol.passive_response(client, message)
  if response ~= nil and connected and socket ~= nil then
    socket:sendText(response)
  end
end

local function handle_socket(message_type, data, _error)
  if exiting then return end
  if message_type == WebSocketMessageType.OPEN then
    connected = true
    bind_active_sprite()
    local state = editor_state()
    last_snapshot_signature = snapshot_signature(state)
    send("client.hello", {
      aseprite_version = tostring(app.version),
      api_version = tostring(app.apiVersion),
      capabilities = Protocol.REQUIRED_CAPABILITIES,
      editor_state = state,
    }, nil)
  elseif message_type == WebSocketMessageType.TEXT then
    handle_server_text(data)
  elseif message_type == WebSocketMessageType.CLOSE then
    connected = false
  end
end

function init(plugin)
  Protocol = dofile(app.fs.joinPath(plugin.path, "protocol.lua"))
  LivePreview = dofile(app.fs.joinPath(plugin.path, "live_preview.lua"))
  exiting = false
  revision = 0
  if plugin.preferences.bridge_url == nil or plugin.preferences.bridge_url == "" then
    plugin.preferences.bridge_url = Protocol.DEFAULT_URL
  end
  if not runtime_capabilities_available() then return end
  client = Protocol.new_client(tostring(Uuid()))

  site_listener = function() handle_site_change() end
  app.events:on("sitechange", site_listener)
  bind_active_sprite()
  last_snapshot_signature = snapshot_signature(editor_state())

  reconcile_timer = Timer{
    interval = 1.0,
    ontick = function()
      bind_active_sprite()
      local state = editor_state()
      local signature = snapshot_signature(state)
      if signature ~= last_snapshot_signature then
        last_snapshot_signature = signature
      send_site_state(nil)
      end
    end,
  }
  reconcile_timer:start()

  socket = WebSocket{
    url = plugin.preferences.bridge_url,
    onreceive = handle_socket,
    deflate = false,
    minreconnectwait = 1.0,
    maxreconnectwait = 5.0,
  }
  socket:connect()
end

function exit(_plugin)
  exiting = true
  connected = false
  if reconcile_timer ~= nil then
    reconcile_timer:stop()
    reconcile_timer = nil
  end
  if site_listener ~= nil then
    pcall(function() app.events:off(site_listener) end)
    site_listener = nil
  end
  unbind_sprite()
  if socket ~= nil then
    socket:close()
    socket = nil
  end
  client = nil
end
