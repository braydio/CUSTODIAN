local LivePreview = {}

local function find_layer(sprite, name)
  for _, layer in ipairs(sprite.layers) do
    if layer.name == name then return layer end
  end
  return nil
end

function LivePreview.read_json(path)
  local file = assert(io.open(path, "rb"))
  local text = file:read("*a")
  file:close()
  return json.decode(text)
end

function LivePreview.render(sprite, manifest, output_path, composition)
  composition = composition or "body_fx"
  local document_frames = manifest.timeline and manifest.timeline.document_frames
  local canvas = manifest.canvas or {}
  if type(document_frames) ~= "number" or document_frames % 1 ~= 0 or document_frames < 1 then
    error("invalid live preview frame contract")
  end
  if sprite.width ~= canvas.width or sprite.height ~= canvas.height or
      #sprite.frames ~= document_frames then
    error("live preview document contract mismatch")
  end

  local bindings = manifest.layers
  if bindings == nil then
    error("live preview manifest has no presentation layers")
  end
  local seen = {}
  local render_layers = {}
  local layer_count = 0
  for _, binding in ipairs(bindings) do
    local semantic = binding.binding_id or binding.aseprite_layer_name
    local is_fx = binding.role == "fx" or semantic == "fx" or string.find(semantic, "fx", 1, true) ~= nil
    local is_body = not is_fx and not string.find(semantic, "REFERENCE", 1, true) and not string.find(semantic, "guide", 1, true)
    if (composition == "fx" and not is_fx) or (composition == "body" and not is_body) then
      goto continue_binding
    end
    layer_count = layer_count + 1
    local layer_name = binding.aseprite_layer_name
    if type(layer_name) ~= "string" or layer_name == "" then
      error("live preview manifest layer name missing")
    end
    if seen[layer_name] then
      error("duplicate live preview layer: " .. layer_name)
    end
    seen[layer_name] = true
    local layer = find_layer(sprite, layer_name)
    if layer == nil then
      error("required live preview layer missing: " .. layer_name)
    end
    if layer.isGroup or not layer.isImage then
      error("live preview layer is not an image layer: " .. layer_name)
    end
    table.insert(render_layers, layer)
    ::continue_binding::
  end
  if layer_count == 0 then
    error("live preview manifest has no presentation layers")
  end

  if layer_count == 0 then error("selected live composition has no authorized layers") end
  local strip = Image(sprite.width * document_frames, sprite.height, ColorMode.RGBA)
  for frame_number = 1, document_frames do
    local frame_x = (frame_number - 1) * sprite.width
    for _, layer in ipairs(render_layers) do
      local cel = layer:cel(frame_number)
      if cel ~= nil then
        local opacity = math.floor(((layer.opacity or 255) * (cel.opacity or 255) / 255) + 0.5)
        strip:drawImage(
          cel.image,
          Point(frame_x + cel.position.x, cel.position.y),
          opacity,
          layer.blendMode
        )
      end
    end
  end

  app.fs.makeAllDirectories(app.fs.filePath(output_path))
  strip:saveAs(output_path)
  return {
    frames = document_frames,
    frame_width = sprite.width,
    frame_height = sprite.height,
  }
end

return LivePreview
