-- Builds a bounded editable master from reviewed modular 96px horizontal strips.
local lower_path = assert(app.params["lower"], "lower is required")
local upper_path = assert(app.params["upper"], "upper is required")
local fx_path = app.params["fx"]
local output_path = assert(app.params["output"], "output is required")
local action = assert(app.params["action"], "action is required")
local frame_count_value = assert(app.params["frames"], "frames is required")
local frame_count = tonumber(frame_count_value)

local function open_strip(path)
  local source = app.open(path)
  if source.width ~= frame_count * 96 or source.height ~= 96 then
    error("invalid modular strip geometry: " .. path)
  end
  return source
end

local function copy_strip(sprite, layer, source)
  local source_image = source.layers[1]:cel(1).image
  for index = 1, frame_count do
    local image = Image(96, 96, ColorMode.RGB)
    image:drawImage(source_image, Point(-(index - 1) * 96, 0))
    sprite:newCel(layer, index, image, Point(0, 0))
  end
end

local lower_source = open_strip(lower_path)
local upper_source = open_strip(upper_path)
local fx_source = nil
if fx_path and fx_path ~= "" then fx_source = open_strip(fx_path) end

local sprite = Sprite(96, 96, ColorMode.RGB)
while #sprite.frames < frame_count do sprite:newEmptyFrame() end
for _, frame in ipairs(sprite.frames) do frame.duration = 1 / 12 end

local lower = sprite.layers[1]
lower.name = "lower_body"
copy_strip(sprite, lower, lower_source)
local upper = sprite:newLayer()
upper.name = "upper_body"
copy_strip(sprite, upper, upper_source)
if fx_source then
  local fx = sprite:newLayer()
  fx.name = "fx"
  copy_strip(sprite, fx, fx_source)
end
local tag = sprite:newTag(1, frame_count)
tag.name = "unarmed/attack/" .. action .. "/e"
tag.aniDir = AniDir.FORWARD
sprite:saveAs(output_path)

lower_source:close()
upper_source:close()
if fx_source then fx_source:close() end
sprite:close()
