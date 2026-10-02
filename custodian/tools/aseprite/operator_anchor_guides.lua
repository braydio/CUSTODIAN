-- Render the approved Operator registration profile into a non-export guide group.
local sprite = assert(app.activeSprite, "Open an Aseprite document first")
local profile_path = app.params["profile"]
if not profile_path or profile_path == "" then
  local root = app.params["repo"] or os.getenv("PWD") or "."
  profile_path = app.fs.joinPath(root, "custodian/content/data/operator/authoring/operator_art_profile.json")
end
local file = assert(io.open(profile_path, "r"), "Cannot read Operator profile: " .. profile_path)
local profile = json.decode(file:read("*a")); file:close()
local registration = assert(profile.registration, "Profile has no registration block")
assert(registration.status == "accepted", "Registration geometry is not accepted")
assert(registration.frame_size[1] == 96 and registration.frame_size[2] == 96, "Expected 96x96 profile")
assert(sprite.width % 96 == 0 and sprite.height % 96 == 0, "Canvas must be an exact grid of 96px cells")

local group_name = "__ART_GUIDE_OPERATOR_REGISTRATION"
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
for cy=0,sprite.height-1,96 do
  for cx=0,sprite.width-1,96 do
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
app.activeLayer = layer
app.refresh()
print("[OperatorRegistration] Profile guide rendered: " .. profile_path)
