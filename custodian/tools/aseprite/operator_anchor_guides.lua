-- Render the approved Operator registration profile into a locked, non-export guide group.
--
-- Params (all optional):
--   repo=<repo root>            used to discover the profile and canonical reference images
--   profile=<profile json path> explicit profile file (headless/tests)
--   profile_id=legacy_96|operator_2_5d_128
--                               default: the active authoring profile if the canvas is an exact grid of
--                               its frame size, otherwise the profile whose frame size tiles the canvas
--   direction=n|ne|e|se|s|sw|w|nw|grid
--                               canonical-128 only; `grid` maps cell columns to the canonical order
--
-- Legacy 96 renders one ruler layer. Canonical 128 renders four locked guide layers:
--   __ART_GUIDE_OPERATOR_FLOOR, _CENTER, _BODY, _CANONICAL_REFERENCE
-- Every layer name starts with __ART_GUIDE_, which Art Agent clean renders and publishing exclude.
local sprite = assert(app.activeSprite, "Open an Aseprite document first")
local profile_path = app.params["profile"]
local root = app.params["repo"] or os.getenv("PWD") or "."
if not profile_path or profile_path == "" then
  profile_path = app.fs.joinPath(root, "custodian/content/data/operator/authoring/operator_art_profile.json")
end
local function read_json(path)
  local handle = assert(io.open(path, "r"), "Cannot read: " .. path)
  local value = json.decode(handle:read("*a")); handle:close()
  return value
end
local profile = read_json(profile_path)

local registry = {}
if profile.profiles then
  for id, block in pairs(profile.profiles) do registry[id] = block.registration end
else
  registry["legacy_96"] = profile.registration
end
local function tiles(registration)
  return registration and sprite.width % registration.frame_size[1] == 0 and sprite.height % registration.frame_size[2] == 0
end
local profile_id = app.params["profile_id"]
if not profile_id or profile_id == "" then
  profile_id = profile.active_authoring_profile or "legacy_96"
  if not tiles(registry[profile_id]) then
    for id, registration in pairs(registry) do
      if tiles(registration) then profile_id = id break end
    end
  end
end
local registration = assert(registry[profile_id], "Profile has no registration block: " .. tostring(profile_id))
assert(registration.status == "accepted" or registration.status == "provisional", "Registration geometry status must be accepted or provisional")
local cell_w, cell_h = registration.frame_size[1], registration.frame_size[2]
assert((cell_w == 96 or cell_w == 128) and cell_w == cell_h, "Expected a 96x96 or 128x128 profile")
assert(tiles(registration), "Canvas must be an exact grid of " .. cell_w .. "px cells")
local canonical = profile_id ~= "legacy_96"

local DIRECTIONS = { "n", "ne", "e", "se", "s", "sw", "w", "nw" }
local direction = app.params["direction"]
if not direction or direction == "" then direction = "s" end

local group_name = "__ART_GUIDE_OPERATOR_REGISTRATION"
for i = #sprite.layers, 1, -1 do
  local layer = sprite.layers[i]
  if layer.name == group_name then sprite:deleteLayer(layer) end
end
local group = sprite:newGroup(); group.name = group_name; group.isVisible = true; group.isEditable = false

local cyan = Color { r = 70, g = 220, b = 255, a = 190 }
local green = Color { r = 72, g = 235, b = 190, a = 200 }
local amber = Color { r = 255, g = 205, b = 70, a = 220 }
local red = Color { r = 255, g = 90, b = 100, a = 220 }

local function new_guide_layer(name, opacity)
  local layer = sprite:newLayer(); layer.name = name; layer.parent = group
  layer.isVisible = true; layer.isEditable = false
  if opacity then layer.opacity = opacity end
  return layer
end
local function new_image() local image = Image(sprite.width, sprite.height, ColorMode.RGB); image:clear(); return image end
local function put(image, x, y, color)
  if x >= 0 and x < sprite.width and y >= 0 and y < sprite.height then image:putPixel(x, y, color) end
end
local function dashed_h(image, y, color)
  for x = 0, sprite.width - 1 do if x % 8 < 4 then put(image, x, y, color) end end
end
local function dashed_v(image, x, color)
  for y = 0, sprite.height - 1 do if y % 8 < 4 then put(image, x, y, color) end end
end
local function cross(image, x, y, color)
  for d = -2, 2 do put(image, x + d, y, color); put(image, x, y + d, color) end
end
local function publish(layer, image)
  for frame_index = 1, #sprite.frames do
    sprite:newCel(layer, frame_index, image:clone(), Point(0, 0))
  end
end
local function each_cell(callback)
  for cy = 0, sprite.height - 1, cell_h do
    local column = 0
    for cx = 0, sprite.width - 1, cell_w do
      callback(cx, cy, column)
      column = column + 1
    end
  end
end

local last_layer
if not canonical then
  local layer = new_guide_layer("__ART_GUIDE_OPERATOR_REGISTRATION_RULER")
  local image = new_image()
  each_cell(function(cx, cy)
    for _, y in pairs(registration.guide.horizontal) do dashed_h(image, cy + y, cyan) end
    for _, x in pairs(registration.guide.vertical) do dashed_v(image, cx + x, cyan) end
    for _, point in pairs(registration.guide.points) do cross(image, cx + point[1], cy + point[2], amber) end
  end)
  publish(layer, image); last_layer = layer
else
  local floor = new_guide_layer("__ART_GUIDE_OPERATOR_FLOOR")
  local center = new_guide_layer("__ART_GUIDE_OPERATOR_CENTER")
  local body = new_guide_layer("__ART_GUIDE_OPERATOR_BODY")
  local reference = new_guide_layer("__ART_GUIDE_OPERATOR_CANONICAL_REFERENCE", 90)
  local ref = assert(profile.canonical_visual_reference, "v3 profile has no canonical_visual_reference")
  local measurements = read_json(app.fs.joinPath(root, ref.measurements_path))
  local floor_image, center_image, body_image, ref_image = new_image(), new_image(), new_image(), new_image()
  local cache = {}
  each_cell(function(cx, cy, column)
    local code = direction
    if direction == "grid" then code = DIRECTIONS[(column % #DIRECTIONS) + 1] end
    local entry = assert(measurements.directions[code], "Unknown canonical direction: " .. tostring(code))
    dashed_h(floor_image, cy + registration.ground_y, green)
    dashed_h(floor_image, cy + registration.anchor[2], green)
    dashed_v(center_image, cx + registration.anchor[1], cyan)
    for _, point in pairs(entry.landmarks.normalized_128) do
      cross(body_image, cx + math.floor(point.x + 0.5), cy + math.floor(point.y + 0.5), point.confidence >= 0.6 and amber or red)
    end
    if not cache[code] then
      cache[code] = Image { fromFile = app.fs.joinPath(root, entry.reference_png) }
    end
    ref_image:drawImage(cache[code], Point(cx, cy))
  end)
  publish(floor, floor_image); publish(center, center_image)
  publish(body, body_image); publish(reference, ref_image)
  last_layer = reference
end
app.activeLayer = last_layer
app.refresh()
print("[OperatorRegistration] " .. profile_id .. " (" .. registration.status .. ") guide rendered: " .. profile_path)
