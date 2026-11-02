-- Thin headless adapter for the shared Operator Art Agent engine.
local protocol = dofile(assert(app.params["lib"], "Art Agent library parameter required"))
local Ops = dofile(assert(app.params["ops"], "Art Agent operation library required"))

local function read_json(path)
  local file = assert(io.open(path, "rb"))
  local text = file:read("*a")
  file:close()
  return json.decode(text)
end

local function write_json(path, value)
  local file = assert(io.open(path, "wb"))
  file:write(json.encode(value))
  file:close()
end

local request_path = assert(app.params["request"], "request script parameter required")
local response_path = assert(app.params["response"], "response script parameter required")
local request_id = "unknown"
local operation_key = "unknown"
local sprite

local function execute()
  local request = read_json(request_path)
  request_id = request.request_id or request_id
  operation_key = request.operation_key or operation_key
  local capability = read_json(assert(request.capability, "capability required"))
  local manifest = read_json(assert(request.manifest, "manifest required"))
  sprite = assert(app.open(request.workbench), "failed to open Operator workbench")
  local response = Ops.execute(sprite, request, capability, manifest)
  if response.changed then
    sprite:saveAs(request.workbench)
  end
  sprite:close()
  sprite = nil
  return response
end

local ok, result = xpcall(execute, debug.traceback)
if sprite ~= nil then
  pcall(function() sprite:close() end)
end
if ok then
  write_json(response_path, result)
else
  write_json(response_path, {
    schema = protocol.RESPONSE_SCHEMA,
    request_id = request_id,
    operation_key = operation_key,
    ok = false,
    error = tostring(result),
    warnings = {},
  })
  error(result)
end
