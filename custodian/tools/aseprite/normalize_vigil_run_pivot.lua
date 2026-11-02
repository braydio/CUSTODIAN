-- Normalize the supplied 7-frame Vigil run strip to a common 48,48 grip.
-- Pixel data is translated only: no scaling, rotation, filtering, or resampling.
--
-- CLI:
-- aseprite -b raw_vigil_run.png \
--   --script-param output=normalized_7f_melee_vigil_dagger.png \
--   --script tools/aseprite/normalize_vigil_run_pivot.lua

local sprite = app.activeSprite
if not sprite then error("No active Vigil run sprite") end

local frame_size = 96
local frame_count = 7
local target_x = 48
local target_y = 48
local anchors = {
  {50, 48},
  {41, 55},
  {30, 48},
  {38, 44},
  {60, 48},
  {42, 51},
  {32, 47},
}

if sprite.width ~= frame_size * frame_count or sprite.height ~= frame_size then
  error(string.format(
    "Expected 672x96 Vigil run strip, got %dx%d",
    sprite.width,
    sprite.height
  ))
end

local source = Image(sprite.width, sprite.height, sprite.colorMode)
source:drawSprite(sprite, app.activeFrame.frameNumber)
local normalized = Image(sprite.width, sprite.height, sprite.colorMode)

for index, anchor in ipairs(anchors) do
  local source_x = (index - 1) * frame_size
  local frame = Image(frame_size, frame_size, sprite.colorMode)
  frame:drawImage(source, Point(-source_x, 0))
  local destination_x = source_x + target_x - anchor[1]
  local destination_y = target_y - anchor[2]
  normalized:drawImage(frame, Point(destination_x, destination_y))
end

local output = app.params.output
if not output or output == "" then
  error("Pass --script-param output=<path>")
end
normalized:saveAs(output)
print("Normalized Vigil run grip pivots to (48,48): " .. output)
