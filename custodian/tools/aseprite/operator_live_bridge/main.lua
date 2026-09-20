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
local layer_visibility_listener = nil
local last_layer_visibility = {}
local pending_layer_visibility = nil
local send_layer_snapshot = nil
local emit_visibility_changes = nil

local function runtime_capabilities_available()
  local api_version = tonumber(app.apiVersion)
  return WebSocket ~= nil and Timer ~= nil and Uuid ~= nil and Image ~= nil and
    json ~= nil and app.events ~= nil and api_version ~= nil and api_version >= 34
end

local function layer_identity(layer)
  if layer == nil then
    return nil, nil
  end
  local layer_id = nil
  local ok, value = pcall(function() return tostring(layer.uuid) end)
  if ok and value ~= nil and value ~= "nil" then layer_id = value end
  return layer.name, layer_id
end

local function collect_layers(container, output)
  output = output or {}
  for _, layer in ipairs(container.layers or {}) do
    table.insert(output, layer)
    if layer.isGroup then collect_layers(layer, output) end
  end
  return output
end

local function layer_record(layer)
  local name, layer_id = layer_identity(layer)
  return {
    layer = name,
    layer_id = layer_id,
    visible = layer.isVisible,
    editable = layer.isEditable,
    reference = layer.isReference == true,
  }
end

local function layer_key(layer)
  local record = layer_record(layer)
  return record.layer_id or record.layer
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
    if layer_visibility_listener ~= nil then
      pcall(function() active_sprite.events:off(layer_visibility_listener) end)
    end
  end
  active_sprite = nil
  sprite_change_listener = nil
  filename_change_listener = nil
  layer_visibility_listener = nil
  last_layer_visibility = {}
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
  layer_visibility_listener = function() emit_visibility_changes() end
  sprite.events:on("layervisibility", layer_visibility_listener)
end

local function handle_site_change()
  bind_active_sprite()
  if connected then send_layer_snapshot() end
  local cause = nil
  if pending_site_change ~= nil then
    local frame = app.frame and app.frame.frameNumber or nil
    local _, layer_id = layer_identity(app.layer)
    local frame_matches = pending_site_change.frame == nil or frame == pending_site_change.frame
    local layer_matches = pending_site_change.layer_id == nil or layer_id == pending_site_change.layer_id
    if frame_matches and layer_matches then
      cause = pending_site_change.cause
    end
    pending_site_change = nil
  end
  send_site_state(cause)
end

local function send_layer_state(layer, cause)
  local state = layer_record(layer)
  state.document_path = app.sprite and app.sprite.filename or ""
  send("layer.state_changed", state, cause)
end

local function snapshot_layer_visibility(sprite)
  local result = {}
  if sprite == nil then return result end
  for _, layer in ipairs(collect_layers(sprite)) do
    result[layer_key(layer)] = layer.isVisible
  end
  return result
end

send_layer_snapshot = function()
  local sprite = app.sprite
  if sprite == nil then
    last_layer_visibility = {}
    return
  end
  last_layer_visibility = snapshot_layer_visibility(sprite)
  for _, layer in ipairs(collect_layers(sprite)) do send_layer_state(layer, nil) end
end

emit_visibility_changes = function()
  local sprite = app.sprite
  if sprite == nil then last_layer_visibility = {}; return end
  local current = snapshot_layer_visibility(sprite)
  for _, layer in ipairs(collect_layers(sprite)) do
    local key = layer_key(layer)
    local before, after = last_layer_visibility[key], current[key]
    if before ~= nil and before ~= after then
      local cause = nil
      if pending_layer_visibility ~= nil and pending_layer_visibility.key == key and
          pending_layer_visibility.visible == after then
        cause = pending_layer_visibility.cause
        pending_layer_visibility = nil
      end
      send_layer_state(layer, cause)
    end
  end
  last_layer_visibility = current
end

local function authorized_layer_names(sprite)
  local manifest_path = app.fs.joinPath(app.fs.filePath(sprite.filename), "workbench.json")
  if not app.fs.isFile(manifest_path) then error("workbench manifest missing") end
  local manifest = LivePreview.read_json(manifest_path)
  local names, entries = {}, { manifest.layers, manifest.references }
  for _, collection in ipairs(entries) do
    if collection ~= nil then
      for _, binding in ipairs(collection) do
        local name = binding.aseprite_layer_name
        if type(name) ~= "string" or name == "" then error("manifest layer name missing") end
        if names[name] ~= nil then error("duplicate authorized layer: " .. name) end
        names[name] = true
      end
    end
  end
  return names
end

local function resolve_authorized_layer(sprite, name, expected_id)
  if type(name) ~= "string" or name == "" then error("layer is required") end
  local allowed = authorized_layer_names(sprite)
  if not allowed[name] then error("layer is not authorized by workbench manifest") end
  local found = nil
  for _, layer in ipairs(collect_layers(sprite)) do
    if layer.name == name then
      if found ~= nil then error("ambiguous Aseprite layer name: " .. name) end
      found = layer
    end
  end
  if found == nil then error("authorized layer missing: " .. name) end
  local _, actual_id = layer_identity(found)
  if expected_id ~= nil and expected_id ~= actual_id then error("layer UUID does not match active document") end
  return found
end

local function active_layer_matches(layer)
  if app.layer == layer then return true end
  if app.layer == nil or layer == nil then return false end
  local active_name, active_id = layer_identity(app.layer)
  local target_name, target_id = layer_identity(layer)
  return active_name == target_name and (target_id == nil or active_id == target_id)
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

local function handle_select_layer(message)
  local payload, sprite = message.payload or {}, app.sprite
  if sprite == nil then send_command_result(message, false, "no active Aseprite document"); return end
  if sprite.filename ~= payload.document_path then send_command_result(message, false, "active document does not match requested workbench"); return end
  local ok, layer_or_error = pcall(resolve_authorized_layer, sprite, payload.layer, payload.layer_id)
  if not ok then send_command_result(message, false, tostring(layer_or_error)); return end
  local layer = layer_or_error
  local _, layer_id = layer_identity(layer)
  if active_layer_matches(layer) then send_site_state(message.sequence); send_command_result(message, true, nil); return end
  pending_site_change = { cause = message.sequence, layer_id = layer_id }
  app.range.layers = { layer }
  if pending_site_change ~= nil then
    if active_layer_matches(layer) then pending_site_change = nil; send_site_state(message.sequence)
    else pending_site_change = nil; send_command_result(message, false, "Aseprite did not activate requested layer"); return end
  end
  send_command_result(message, true, nil)
end

local function handle_set_layer_visibility(message)
  local payload, sprite = message.payload or {}, app.sprite
  if sprite == nil then send_command_result(message, false, "no active Aseprite document"); return end
  if sprite.filename ~= payload.document_path then send_command_result(message, false, "active document does not match requested workbench"); return end
  if type(payload.visible) ~= "boolean" then send_command_result(message, false, "visible must be boolean"); return end
  local ok, layer_or_error = pcall(resolve_authorized_layer, sprite, payload.layer, payload.layer_id)
  if not ok then send_command_result(message, false, tostring(layer_or_error)); return end
  local layer = layer_or_error
  if layer.isVisible == payload.visible then
    send_layer_state(layer, message.sequence); send_command_result(message, true, nil); return
  end
  pending_layer_visibility = { cause = message.sequence, key = layer_key(layer), visible = payload.visible }
  layer.isVisible = payload.visible
  if pending_layer_visibility ~= nil then
    if layer.isVisible == payload.visible then
      pending_layer_visibility = nil
      last_layer_visibility[layer_key(layer)] = payload.visible
      send_layer_state(layer, message.sequence)
    else
      pending_layer_visibility = nil
      send_command_result(message, false, "Aseprite did not change requested layer visibility"); return
    end
  end
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
  if message.type == "command.select_layer" then handle_select_layer(message); return end
  if message.type == "command.set_layer_visibility" then handle_set_layer_visibility(message); return end
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
    send_layer_snapshot()
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
