-- Render the approved Operator registration profile into a non-export guide group.
local sprite = assert(app.activeSprite, "Open an Aseprite document first")
local profile_path = app.params["profile"]
if not profile_path or profile_path == "" then
  local root = app.params["repo"] or os.getenv("PWD") or "."
  profile_path = app.fs.joinPath(root, "custodian/content/data/operator/authoring/operator_art_profile.json")
end
local file = assert(io.open(profile_path, "r"), "Cannot read Operator profile: " .. profile_path)
local profile = json.decode(file:read("*a")); file:close()
local profile_id = app.params["profile_id"]
local selected
if profile.schema == "custodian.operator_art_profile.v3" then
  profile_id = profile_id or profile.active_authoring_profile
  selected = assert(profile.profiles[profile_id], "Unknown Operator profile: " .. tostring(profile_id))
  local candidate_size = selected.registration.frame_size
  if sprite.width % candidate_size[1] ~= 0 or sprite.height % candidate_size[2] ~= 0 then
    local legacy = profile.profiles.legacy_96
    local legacy_size = legacy.registration.frame_size
    if sprite.width % legacy_size[1] == 0 and sprite.height % legacy_size[2] == 0 then
      profile_id = "legacy_96"; selected = legacy
    else
      error("Canvas does not match selected or legacy Operator profile grid")
    end
  end
else
  selected = profile
  profile_id = profile_id or "legacy_96"
end
local registration = assert(selected.registration, "Profile has no registration block")
assert(registration.status == "accepted" or registration.status == "provisional", "Registration profile has invalid state")
local cell_width, cell_height = registration.frame_size[1], registration.frame_size[2]
assert(sprite.width % cell_width == 0 and sprite.height % cell_height == 0, "Canvas must be an exact grid of profile cells")

local suffix = string.upper(string.gsub(profile_id, "[^%w]", "_"))
local group_name = "__ART_GUIDE_OPERATOR_REGISTRATION_" .. suffix
for i = #sprite.layers, 1, -1 do
  local layer = sprite.layers[i]
  if layer.name == group_name then sprite:deleteLayer(layer) end
end
local group = sprite:newGroup(); group.name = group_name; group.isVisible = true; group.isEditable = false
local layer = sprite:newLayer(); layer.name = "__ART_GUIDE_OPERATOR_REGISTRATION_RULER"; layer.parent = group
layer.isVisible = true; layer.isEditable = false
local image = Image(sprite.width, sprite.height, ColorMode.RGB)
image:clear()
local cyan = Color { r = 70, g = 220, b = 255, a = 190 }
local amber = Color { r = 255, g = 205, b = 70, a = 220 }
local function put(x,y,color)
  if x >= 0 and x < sprite.width and y >= 0 and y < sprite.height then image:putPixel(x,y,color) end
end
local function dashed_h(y,color)
  for x=0,sprite.width-1 do if x % 8 < 4 then put(x,y,color) end end
end
local function dashed_v(x,color)
  for y=0,sprite.height-1 do if y % 8 < 4 then put(x,y,color) end end
end
for cy=0,sprite.height-1,cell_height do
  for cx=0,sprite.width-1,cell_width do
    for _,y in pairs(registration.guide.horizontal) do dashed_h(cy+y,cyan) end
    for _,x in pairs(registration.guide.vertical) do dashed_v(cx+x,cyan) end
    for _,point in pairs(registration.guide.points) do
      local x,y=cx+point[1],cy+point[2]
      for d=-2,2 do put(x+d,y,amber); put(x,y+d,amber) end
    end
  end
end
for frame_index=1,#sprite.frames do
  sprite:newCel(layer, frame_index, image:clone(), Point(0,0))
end
local canonical = selected.canonical_reference
if canonical and canonical.path then
  local direction = string.lower(app.params["direction"] or "n")
  local direction_order = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}
  local direction_index = nil
  for i, name in ipairs(direction_order) do if name == direction then direction_index = i - 1 end end
  assert(direction_index ~= nil, "Direction must be n, ne, e, se, s, sw, w, or nw")
  local reference_path = app.fs.joinPath(app.params["repo"] or os.getenv("PWD") or ".", canonical.path)
  local reference_sprite = assert(app.open(reference_path), "Cannot open canonical Operator reference: " .. reference_path)
  local reference_cel = assert(reference_sprite.layers[1]:cel(1), "Canonical reference has no first cel")
  app.activeSprite = sprite
  app.activeLayer = group
  app.command.NewLayer{reference=true}
  local ghost = app.activeLayer
  ghost.name = "__ART_GUIDE_OPERATOR_CANONICAL_REFERENCE"
  ghost.isVisible = true; ghost.isEditable = false; ghost.opacity = 96
  local columns, rows = sprite.width / cell_width, sprite.height / cell_height
  assert(rows == 1 or rows == 8, "Canonical reference guides need a single row or eight direction rows")
  local ghost_image = Image(sprite.width, sprite.height, ColorMode.RGB)
  ghost_image:clear()
  for row=0,rows-1 do
    for col=0,columns-1 do
      local index
      if rows == 8 then index = row
      elseif columns == 8 then index = col
      else index = direction_index end
      local ref_cell = Image(cell_width, cell_height, ColorMode.RGB)
      ref_cell:clear()
      ref_cell:drawImage(reference_cel.image, -index * cell_width, 0)
      ghost_image:drawImage(ref_cell, col * cell_width, row * cell_height)
    end
  end
  for frame_index=1,#sprite.frames do
    sprite:newCel(ghost, frame_index, ghost_image:clone(), Point(0,0))
  end
end
app.activeLayer = layer
app.refresh()
print("[OperatorRegistration] Profile guide rendered: " .. profile_id .. " (" .. registration.status .. "): " .. profile_path)
