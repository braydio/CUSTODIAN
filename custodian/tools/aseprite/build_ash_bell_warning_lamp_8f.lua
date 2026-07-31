-- build_ash_bell_warning_lamp_8f.lua
-- CUSTODIAN: convert the 2x2 / 4-frame warning-lamp sheet into an
-- 8-frame, 64x64-per-frame runtime animation with a controlled amber flicker.
--
-- Expected input:
--   - Active sprite is a 2-column x 2-row sheet.
--   - The sheet can be any even pixel dimensions; each cell is reduced
--     to TARGET_SIZE with nearest-neighbor sampling.
--   - RGB/RGBA input with transparency.
--
-- GUI:
--   1. Open the 4-frame PNG in Aseprite.
--   2. File > Scripts > Open Script, then run this file.
--
-- Headless from repository root:
--   aseprite -b path/to/the_4f_sheet.png \
--     --script custodian/tools/aseprite/build_ash_bell_warning_lamp_8f.lua \
--     --script-param repo="$PWD"
--
-- Optional script params:
--   frame_size=64
--   strength=1.0
--   output_png=/absolute/path/output.png
--   output_ase=/absolute/path/output.aseprite

local pc = app.pixelColor
local TRANSPARENT = pc.rgba(0, 0, 0, 0)

local SOURCE_COLUMNS = 2
local SOURCE_ROWS = 2
local SOURCE_FRAME_COUNT = 4
local OUTPUT_FRAME_COUNT = 8

local TARGET_SIZE = tonumber(app.params["frame_size"] or "64") or 64
local STRENGTH = tonumber(app.params["strength"] or "1.0") or 1.0

local OUTPUT_BASENAME =
  "ash_bell__underground_ingress_fx__warning_lamp__loop__omni__8f__64"

-- Deliberately irregular but restrained. Frame 8 ends near frame 1 so
-- the loop does not visibly pop.
local FLICKER = {
  { brightness =  0, warmth =  3, saturation =  1, glow_alpha =  0, duration = 0.120 },
  { brightness =  8, warmth =  7, saturation =  5, glow_alpha =  4, duration = 0.100 },
  { brightness = -9, warmth =  0, saturation = -4, glow_alpha = -6, duration = 0.140 },
  { brightness = 14, warmth = 11, saturation =  9, glow_alpha =  8, duration = 0.090 },
  { brightness =  5, warmth =  6, saturation =  4, glow_alpha =  3, duration = 0.110 },
  { brightness = -6, warmth =  1, saturation = -2, glow_alpha = -4, duration = 0.130 },
  { brightness = 10, warmth =  9, saturation =  7, glow_alpha =  6, duration = 0.100 },
  { brightness =  2, warmth =  4, saturation =  2, glow_alpha =  1, duration = 0.120 },
}

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function shell_quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function mkdir_p(path)
  if path and path ~= "" then
    os.execute("mkdir -p " .. shell_quote(path))
  end
end

local function dirname(path)
  if not path or path == "" then return "." end
  return path:match("^(.*)/[^/]+$") or "."
end

local function infer_repo_root(source_filename)
  local explicit = app.params["repo"]
  if explicit and explicit ~= "" then
    return explicit
  end

  if source_filename and source_filename ~= "" then
    local marker = "/custodian/"
    local i = string.find(source_filename, marker, 1, true)
    if i then
      return string.sub(source_filename, 1, i - 1)
    end
  end

  return nil
end

local function copy_active_cel_to_canvas(sprite)
  local cel = app.activeCel
  if not cel then
    cel = sprite.cels[1]
  end
  if not cel then
    error("The active sprite has no cel to process.")
  end

  local canvas = Image(sprite.width, sprite.height, ColorMode.RGB)
  canvas:drawImage(cel.image, cel.position)
  return canvas
end

local function crop_image(src, x0, y0, width, height)
  local out = Image(width, height, ColorMode.RGB)

  for y = 0, height - 1 do
    for x = 0, width - 1 do
      out:putPixel(x, y, src:getPixel(x0 + x, y0 + y))
    end
  end

  return out
end

local function resize_nearest(src, width, height)
  local out = Image(width, height, ColorMode.RGB)

  for y = 0, height - 1 do
    local sy = math.floor(y * src.height / height)
    sy = clamp(sy, 0, src.height - 1)

    for x = 0, width - 1 do
      local sx = math.floor(x * src.width / width)
      sx = clamp(sx, 0, src.width - 1)
      out:putPixel(x, y, src:getPixel(sx, sy))
    end
  end

  return out
end

local function rgb_to_hsv(r, g, b)
  local rf = r / 255.0
  local gf = g / 255.0
  local bf = b / 255.0

  local maxc = math.max(rf, gf, bf)
  local minc = math.min(rf, gf, bf)
  local delta = maxc - minc

  local hue = 0.0
  if delta > 0.00001 then
    if maxc == rf then
      hue = 60.0 * (((gf - bf) / delta) % 6.0)
    elseif maxc == gf then
      hue = 60.0 * (((bf - rf) / delta) + 2.0)
    else
      hue = 60.0 * (((rf - gf) / delta) + 4.0)
    end
  end

  if hue < 0.0 then hue = hue + 360.0 end

  local saturation = 0.0
  if maxc > 0.00001 then
    saturation = delta / maxc
  end

  return hue, saturation, maxc
end

-- Returns an influence from 0..1. This intentionally targets emissive
-- amber/yellow pixels and largely ignores the dark bracket and metal shell.
local function warm_emissive_weight(r, g, b, a)
  if a == 0 then return 0.0 end

  local hue, saturation, value = rgb_to_hsv(r, g, b)

  if hue < 14.0 or hue > 72.0 then return 0.0 end
  if saturation < 0.18 then return 0.0 end
  if value < 0.20 then return 0.0 end
  if r <= b or g <= b then return 0.0 end

  local hue_weight = 1.0 - math.abs(hue - 40.0) / 32.0
  hue_weight = clamp(hue_weight, 0.0, 1.0)

  local saturation_weight = clamp((saturation - 0.18) / 0.58, 0.0, 1.0)
  local value_weight = clamp((value - 0.20) / 0.70, 0.0, 1.0)
  local amber_bias = clamp(((r - b) / 255.0) * 1.6, 0.0, 1.0)

  return clamp(
    hue_weight *
    (0.35 * saturation_weight + 0.40 * value_weight + 0.25 * amber_bias),
    0.0,
    1.0
  )
end

local function apply_flicker(src, settings)
  local out = Image(src.width, src.height, ColorMode.RGB)

  local brightness = settings.brightness * STRENGTH
  local warmth = settings.warmth * STRENGTH
  local saturation_delta = settings.saturation * STRENGTH
  local glow_alpha = settings.glow_alpha * STRENGTH

  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local px = src:getPixel(x, y)
      local r = pc.rgbaR(px)
      local g = pc.rgbaG(px)
      local b = pc.rgbaB(px)
      local a = pc.rgbaA(px)

      if a == 0 then
        out:putPixel(x, y, TRANSPARENT)
      else
        local weight = warm_emissive_weight(r, g, b, a)

        if weight <= 0.0 then
          out:putPixel(x, y, px)
        else
          local gain = 1.0 + (brightness / 100.0) * weight

          local nr = r * gain
          local ng = g * gain
          local nb = b * gain

          -- Push the selected pixels toward a warmer amber without tinting
          -- the iron housing or bracket.
          nr = nr + 255.0 * (warmth / 100.0) * 0.11 * weight
          ng = ng + 255.0 * (warmth / 100.0) * 0.045 * weight
          nb = nb - 255.0 * (warmth / 100.0) * 0.13 * weight

          -- Controlled saturation adjustment around perceptual luminance.
          local lum = 0.2126 * nr + 0.7152 * ng + 0.0722 * nb
          local sat_gain = 1.0 + (saturation_delta / 100.0) * weight

          nr = lum + (nr - lum) * sat_gain
          ng = lum + (ng - lum) * sat_gain
          nb = lum + (nb - lum) * sat_gain

          local na = a
          if a < 250 then
            na = a * (1.0 + (glow_alpha / 100.0) * weight)
          end

          out:putPixel(
            x,
            y,
            pc.rgba(
              math.floor(clamp(nr, 0.0, 255.0) + 0.5),
              math.floor(clamp(ng, 0.0, 255.0) + 0.5),
              math.floor(clamp(nb, 0.0, 255.0) + 0.5),
              math.floor(clamp(na, 0.0, 255.0) + 0.5)
            )
          )
        end
      end
    end
  end

  return out
end

local function build_animation(processed_frames)
  local sprite = Sprite(TARGET_SIZE, TARGET_SIZE, ColorMode.RGB)
  sprite.layers[1].name = "warning_lamp"

  sprite.cels[1].image:drawImage(processed_frames[1], Point(0, 0))
  sprite.frames[1].duration = FLICKER[1].duration

  for i = 2, OUTPUT_FRAME_COUNT do
    local frame = sprite:newEmptyFrame()
    sprite:newCel(sprite.layers[1], frame, processed_frames[i], Point(0, 0))
    sprite.frames[i].duration = FLICKER[i].duration
  end

  local tag = sprite:newTag(1, OUTPUT_FRAME_COUNT)
  tag.name = "flicker"
  tag.aniDir = AniDir.FORWARD

  return sprite
end

local function build_horizontal_sheet(processed_frames)
  local sheet = Sprite(TARGET_SIZE * OUTPUT_FRAME_COUNT, TARGET_SIZE, ColorMode.RGB)
  sheet.layers[1].name = "warning_lamp_sheet"

  local sheet_image = sheet.cels[1].image
  for i = 1, OUTPUT_FRAME_COUNT do
    sheet_image:drawImage(
      processed_frames[i],
      Point((i - 1) * TARGET_SIZE, 0)
    )
  end

  return sheet
end

local source_sprite = app.activeSprite
if not source_sprite then
  error("Open the four-frame warning-lamp sheet before running this script.")
end

if source_sprite.colorMode ~= ColorMode.RGB then
  error("Convert the source sprite to RGB Color Mode before running this script.")
end

if source_sprite.width % SOURCE_COLUMNS ~= 0 or
   source_sprite.height % SOURCE_ROWS ~= 0 then
  error("Source dimensions must divide evenly into a 2x2 frame grid.")
end

local source_cell_w = source_sprite.width / SOURCE_COLUMNS
local source_cell_h = source_sprite.height / SOURCE_ROWS

local source_canvas = copy_active_cel_to_canvas(source_sprite)
local source_frames = {}

for row = 0, SOURCE_ROWS - 1 do
  for col = 0, SOURCE_COLUMNS - 1 do
    local source_index = row * SOURCE_COLUMNS + col + 1
    local cropped = crop_image(
      source_canvas,
      col * source_cell_w,
      row * source_cell_h,
      source_cell_w,
      source_cell_h
    )

    source_frames[source_index] =
      resize_nearest(cropped, TARGET_SIZE, TARGET_SIZE)
  end
end

-- Frames 1..4 use the source cells in reading order.
-- Frames 5..8 duplicate source cells 1..4, then receive a different
-- brightness/color treatment so the resulting loop has eight unique beats.
local processed_frames = {}
for i = 1, OUTPUT_FRAME_COUNT do
  local source_index = ((i - 1) % SOURCE_FRAME_COUNT) + 1
  processed_frames[i] = apply_flicker(source_frames[source_index], FLICKER[i])
end

local source_filename = source_sprite.filename or ""
local source_dir = dirname(source_filename)
local repo_root = infer_repo_root(source_filename)

local default_output_dir
local default_source_dir

if repo_root then
  default_output_dir =
    repo_root .. "/custodian/content/sprites/world/ingress/ash_bell"
  default_source_dir =
    default_output_dir .. "/source"
else
  default_output_dir = source_dir
  default_source_dir = source_dir
end

local output_png =
  app.params["output_png"] or
  (default_output_dir .. "/" .. OUTPUT_BASENAME .. ".png")

local output_ase =
  app.params["output_ase"] or
  (default_source_dir .. "/" .. OUTPUT_BASENAME .. ".aseprite")

mkdir_p(dirname(output_png))
mkdir_p(dirname(output_ase))

local animation = build_animation(processed_frames)
animation:saveAs(output_ase)

local sheet = build_horizontal_sheet(processed_frames)
sheet:saveAs(output_png)
sheet:close()

app.activeSprite = animation
app.refresh()

print("Built Ash-Bell warning lamp flicker:")
print("  Animation source: " .. output_ase)
print("  Runtime sheet:    " .. output_png)
print("  Layout:           8 horizontal frames")
print("  Frame size:       " .. TARGET_SIZE .. "x" .. TARGET_SIZE)
