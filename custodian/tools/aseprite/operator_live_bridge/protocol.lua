local Protocol = {}

Protocol.SCHEMA = "custodian.operator_live_bridge.message.v1"
Protocol.DEFAULT_URL = "ws://127.0.0.1:32147"
Protocol.REQUIRED_CAPABILITIES = {
  "websocket",
  "app_events_sitechange",
  "sprite_change_events",
  "sprite_is_modified",
  "timer",
  "frame_selection",
  "image_render_export",
  "layer_selection",
  "layer_visibility_control",
  "layer_visibility_events",
}

local server_types = {
  ["server.hello"] = true,
  ["heartbeat"] = true,
  ["command.open_workbench"] = true,
  ["command.select_frame"] = true,
  ["command.export_preview"] = true,
  ["command.select_layer"] = true,
  ["command.set_layer_visibility"] = true,
  ["command.save"] = true,
}

local unsupported_commands = {
  ["command.open_workbench"] = true,
  ["command.save"] = true,
}

local function encode_string(value)
  local wrapped = json.encode({ value })
  return wrapped:sub(2, -2)
end

function Protocol.new_client(session_id)
  assert(type(session_id) == "string" and session_id ~= "", "session_id is required")
  return {
    session_id = session_id,
    sequence = 0,
    bridge_session_id = nil,
    last_server_sequence = 0,
  }
end

function Protocol.next_message(client, message_type, payload, cause)
  client.sequence = client.sequence + 1
  return {
    schema = Protocol.SCHEMA,
    session_id = client.session_id,
    sequence = client.sequence,
    type = message_type,
    cause = cause,
    payload = payload or {},
  }
end

function Protocol.encode_message(client, message_type, payload, cause)
  local message = Protocol.next_message(client, message_type, payload, cause)
  local cause_json = "null"
  if cause ~= nil then cause_json = tostring(cause) end
  return table.concat({
    "{\"schema\":", encode_string(message.schema),
    ",\"session_id\":", encode_string(message.session_id),
    ",\"sequence\":", tostring(message.sequence),
    ",\"type\":", encode_string(message.type),
    ",\"cause\":", cause_json,
    ",\"payload\":", json.encode(message.payload), "}",
  })
end

function Protocol.decode_server_message(client, text)
  local ok, message = pcall(json.decode, text)
  if not ok or message == nil then
    return nil, "invalid JSON message"
  end
  if message.schema ~= Protocol.SCHEMA then
    return nil, "unsupported schema"
  end
  if type(message.session_id) ~= "string" or message.session_id == "" then
    return nil, "missing server session"
  end
  if type(message.sequence) ~= "number" or message.sequence < 1 or
      message.sequence % 1 ~= 0 then
    return nil, "invalid server sequence"
  end
  if not server_types[message.type] then
    return nil, "unsupported server message"
  end
  if message.type == "server.hello" then
    if client.bridge_session_id ~= nil and client.bridge_session_id ~= message.session_id then
      client.last_server_sequence = 0
    end
    client.bridge_session_id = message.session_id
  elseif client.bridge_session_id == nil or message.session_id ~= client.bridge_session_id then
    return nil, "server session mismatch"
  end
  if message.sequence <= client.last_server_sequence then
    return nil, "server sequence did not increase"
  end
  client.last_server_sequence = message.sequence
  return message, nil
end

function Protocol.passive_response(client, message)
  if unsupported_commands[message.type] then
    return Protocol.encode_message(client, "command.result", {
      ok = false,
      error = "unsupported in Packet 5",
      packet = "5",
    }, message.sequence)
  end
  if message.type == "heartbeat" then
    return Protocol.encode_message(client, "heartbeat", { ok = true }, message.sequence)
  end
  return nil
end

return Protocol
