-- remove_external_outline_batch.lua
-- Headless Aseprite batch version.
-- Removes only dark external outline pixels from all cels in the active sprite.
--
-- CLI params:
--   outlineWidth=1
--   darkThreshold=105
--   alphaThreshold=0
--   output=/path/to/output.png

local spr = app.activeSprite

if not spr then
  app.alert("No active sprite.")
  return
end

local params = app.params or {}

local function param_number(name, fallback)
  local v = tonumber(params[name])
  if v == nil then return fallback end
  return v
end

local outlineWidth = math.max(1, math.floor(param_number("outlineWidth", 1)))
local darkThreshold = math.max(0, math.min(255, param_number("darkThreshold", 105)))
local alphaThreshold = math.max(0, math.min(255, param_number("alphaThreshold", 0)))
local output = params["output"]

local function key(x, y, w)
  return y * w + x + 1
end

local function luminance(r, g, b)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

local function get_rgba(img, x, y, pal)
  local p = img:getPixel(x, y)

  if spr.colorMode == ColorMode.INDEXED then
    local c = pal:getColor(p)
    return app.pixelColor.rgbaR(c),
           app.pixelColor.rgbaG(c),
           app.pixelColor.rgbaB(c),
           app.pixelColor.rgbaA(c),
           p
  elseif spr.colorMode == ColorMode.GRAYSCALE then
    local v = app.pixelColor.grayaV(p)
    local a = app.pixelColor.grayaA(p)
    return v, v, v, a, p
  else
    return app.pixelColor.rgbaR(p),
           app.pixelColor.rgbaG(p),
           app.pixelColor.rgbaB(p),
           app.pixelColor.rgbaA(p),
           p
  end
end

local function make_transparent_pixel()
  if spr.colorMode == ColorMode.INDEXED then
    return spr.transparentColor
  elseif spr.colorMode == ColorMode.GRAYSCALE then
    return app.pixelColor.graya(0, 0)
  else
    return app.pixelColor.rgba(0, 0, 0, 0)
  end
end

local function is_solid(alphaMap, x, y, w, h)
  if x < 0 or y < 0 or x >= w or y >= h then
    return false
  end
  return alphaMap[key(x, y, w)] > alphaThreshold
end

local function touches_outside(alphaMap, x, y, w, h)
  for dy = -1, 1 do
    for dx = -1, 1 do
      if not (dx == 0 and dy == 0) then
        if not is_solid(alphaMap, x + dx, y + dy, w, h) then
          return true
        end
      end
    end
  end
  return false
end

local function remove_outline_from_cel(cel)
  local src = cel.image
  local img = Image(src)
  local w = img.width
  local h = img.height
  local pal = spr.palettes[1]

  local alphaMap = {}
  local darkMap = {}
  local removeMap = {}

  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local k = key(x, y, w)
      local r, g, b, a = get_rgba(img, x, y, pal)

      alphaMap[k] = a
      darkMap[k] = luminance(r, g, b) <= darkThreshold
      removeMap[k] = false
    end
  end

  for _pass = 1, outlineWidth do
    local passRemove = {}

    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local k = key(x, y, w)

        if alphaMap[k] > alphaThreshold and darkMap[k] then
          if touches_outside(alphaMap, x, y, w, h) then
            passRemove[k] = true
          end
        end
      end
    end

    for k, _ in pairs(passRemove) do
      alphaMap[k] = 0
      removeMap[k] = true
    end
  end

  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local k = key(x, y, w)
      if removeMap[k] then
        img:putPixel(x, y, make_transparent_pixel())
      end
    end
  end

  cel.image = img
end

app.transaction("Remove External Outline Batch", function()
  for _, cel in ipairs(spr.cels) do
    remove_outline_from_cel(cel)
  end
end)

if output ~= nil and output ~= "" then
  spr:saveAs(output)
else
  app.command.SaveFile()
end
