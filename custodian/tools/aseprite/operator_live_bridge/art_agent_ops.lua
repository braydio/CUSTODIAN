-- Shared read-only Art Agent execution seam. Transport adapters own document
-- lifecycle and persistence; this module never opens, saves, or closes sprites.
local Ops = {}
local READ_TYPES = {inspect=true,render=true,render_clean=true,render_editor=true,render_layer=true,render_silhouette=true}
local function fail(message) error(message, 0) end

local function authorized_output(path, capability)
  local root = capability.preview_root
  if type(path) ~= "string" then fail("render output outside authorized preview root") end
  if string.find(path, "\0", 1, true) then fail("render output path contains a NUL byte") end
  if string.find(path, "\\", 1, true) then fail("render output path contains a backslash") end
  if string.find(path, "..", 1, true) then fail("render output path contains a traversal segment") end
  if string.find(path, "/./", 1, true) then fail("render output path contains a redundant segment") end
  if string.sub(path, 1, 1) ~= "/" or string.sub(path, 1, #root + 1) ~= root .. "/" then fail("render output outside authorized preview root") end
end

local function find_layer(sprite, name)
  for _, layer in ipairs(sprite.layers) do if layer.name == name then return layer end end
  return nil
end

local function render(sprite, operation, capability)
  authorized_output(operation.output, capability)
  local visibility = {}
  local function internal(layer)
    return string.sub(layer.name, 1, 12) == "__REFERENCE_" or string.sub(layer.name, 1, 12) == "__ART_GUIDE_"
      or string.sub(layer.name, 1, 15) == "__ART_LANDMARK_" or layer.name == "__REVIEW_NOTES"
      or (operation.include_drafts == false and string.sub(layer.name, 1, 13) == "__ART_DRAFT__")
  end
  if operation.type == "render_layer" then
    if type(operation.layer) ~= "string" or find_layer(sprite, operation.layer) == nil then fail("render layer missing: " .. tostring(operation.layer)) end
    for _, layer in ipairs(sprite.layers) do visibility[layer] = layer.isVisible; layer.isVisible = layer.name == operation.layer end
  elseif operation.type == "render_clean" then
    for _, layer in ipairs(sprite.layers) do visibility[layer] = layer.isVisible; if internal(layer) then layer.isVisible = false end end
  end
  local strip = Image(sprite.width * #sprite.frames, sprite.height, ColorMode.RGB)
  for index = 1, #sprite.frames do strip:drawSprite(sprite, index, Point((index - 1) * sprite.width, 0)) end
  if operation.type == "render_silhouette" then
    for pixel in strip:pixels() do local value = pixel(); local alpha = app.pixelColor.rgbaA(value); if alpha > 0 then pixel(app.pixelColor.rgba(255, 255, 255, alpha)) end end
  end
  strip:saveAs(operation.output)
  for layer, value in pairs(visibility) do layer.isVisible = value end
  return {output=operation.output,frames=#sprite.frames,size={strip.width,strip.height}}
end

function Ops.execute(sprite, req, capability, manifest)
  if sprite == nil then fail("no active Aseprite document") end
  local operation = req.operation or {}
  if not READ_TYPES[operation.type] then fail("Packet 9A live Art Agent execution is read-only") end
  if sprite.width ~= manifest.canvas.width or sprite.height ~= manifest.canvas.height then fail("Operator workbench document contract changed") end
  local response = {schema="custodian.operator_art_agent.response.v2",request_id=req.request_id or "unknown",operation_key=req.operation_key or "unknown",ok=true,changed=false,operation=operation.type,warnings={}}
  if operation.type == "inspect" then
    response.canvas={width=sprite.width,height=sprite.height}; response.frames=#sprite.frames; response.layers={}; response.references={}
    for _, binding in ipairs(manifest.layers or {}) do local contract=binding.workspace_contract; table.insert(response.layers,{name=binding.aseprite_layer_name,editable=binding.editable,frames=contract.frames,legal_rect={contract.placement[1],contract.placement[2],contract.frame_size[1],contract.frame_size[2]}}) end
    for _, layer in ipairs(sprite.layers) do if string.sub(layer.name,1,12)=="__REFERENCE_" then table.insert(response.references,layer.name) end end
  else
    local result=render(sprite,operation,capability); response.output=result.output; response.frames=result.frames; response.size=result.size
  end
  return response
end

return Ops
