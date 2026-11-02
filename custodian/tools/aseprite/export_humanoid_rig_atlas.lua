-- Exports named 96x96 part layers to the fixed 5x4 rigid-cutout atlas.
local CELLS = {
  { "head", 0, 0, true },
  { "torso", 1, 0, true },
  { "pelvis", 2, 0, true },
  { "back_attachment", 3, 0, false },
  { "front_attachment", 4, 0, false },
  { "upper_arm_back", 0, 1, true },
  { "forearm_back", 1, 1, true },
  { "hand_back", 2, 1, true },
  { "upper_arm_front", 3, 1, true },
  { "forearm_front", 4, 1, true },
  { "hand_front", 0, 2, true },
  { "thigh_back", 1, 2, true },
  { "shin_back", 2, 2, true },
  { "foot_back", 3, 2, true },
  { "thigh_front", 4, 2, true },
  { "shin_front", 0, 3, true },
  { "foot_front", 1, 3, true },
  { "weapon", 2, 3, false },
  { "cape", 3, 3, false },
  { "reserved", 4, 3, false },
}

local source = app.activeSprite
if not source then
  return app.alert("Humanoid rig export requires an active 96x96 sprite.")
end
if source.width ~= 96 or source.height ~= 96 then
  return app.alert("Humanoid rig source must be exactly 96x96 pixels.")
end

local layers = {}
local function collect(layer_list)
  for _, layer in ipairs(layer_list) do
    if layer.isGroup then
      collect(layer.layers)
    else
      layers[layer.name] = layer
    end
  end
end
collect(source.layers)

local missing_core = {}
for _, spec in ipairs(CELLS) do
  if spec[4] and not layers[spec[1]] then
    table.insert(missing_core, spec[1])
  end
end
if #missing_core > 0 then
  return app.alert("Missing required rig layers:\n" .. table.concat(missing_core, ", "))
end

local default_name = source.filename ~= "" and
  source.filename:gsub("%.aseprite$", ""):gsub("__rig_source__", "__rig_atlas__"):gsub("__96$", "__5x4__96") .. ".png"
  or "enemy_id__rig_atlas__base__s__5x4__96.png"
local dialog = Dialog { title = "Export Humanoid Rig Atlas" }
dialog:file {
  id = "output",
  label = "Output PNG",
  filename = default_name,
  open = false,
  filetypes = { "png" },
}
dialog:button { id = "export", text = "Export", focus = true }
dialog:button { id = "cancel", text = "Cancel" }
dialog:show()
local data = dialog.data
if not data.export or not data.output or data.output == "" then return end

local atlas = Sprite(480, 384, ColorMode.RGB)
atlas.filename = data.output
atlas.layers[1].name = "__atlas_export"
local atlas_image = Image(480, 384, ColorMode.RGB)
atlas_image:clear()
local exported, missing_optional = {}, {}

for _, spec in ipairs(CELLS) do
  local name, column, row = spec[1], spec[2], spec[3]
  local layer = layers[name]
  local cel = layer and layer:cel(source.frames[1]) or nil
  if cel then
    -- Cel positions are part of the source's absolute 96x96 coordinate space.
    atlas_image:drawImage(cel.image, Point(column * 96 + cel.position.x, row * 96 + cel.position.y))
    table.insert(exported, name)
  elseif not spec[4] then
    table.insert(missing_optional, name)
  end
end

atlas:newCel(atlas.layers[1], 1, atlas_image, Point(0, 0))
atlas:saveCopyAs(data.output)
atlas:close()
app.activeSprite = source
app.refresh()
print(string.format(
  "[HumanoidRig] Exported %d parts to %s; optional blank: %s",
  #exported,
  data.output,
  #missing_optional > 0 and table.concat(missing_optional, ", ") or "none"
))
