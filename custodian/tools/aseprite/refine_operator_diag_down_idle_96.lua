-- refine_operator_diag_down_idle_96.lua
-- Tailored to the supplied CUSTODIAN operator idle:
--   * 5 frames
--   * 96x96 pixels per frame
--   * down-right diagonal facing
--
-- Accepted source layouts:
--   1) one horizontal 480x96 cel containing five 96x96 cells, or
--   2) a 96x96 sprite with at least five timeline frames on the active layer.
--
-- The script is non-destructive: it writes the result to a new layer named
-- "operator_diag_down_refined" (or a numbered variant).

local spr = app.activeSprite
if not spr then
  app.alert("Open the operator sprite before running this script.")
  return
end

if spr.colorMode ~= ColorMode.RGB then
  app.alert("This tailored script expects an RGB/RGBA sprite. Convert the sprite to RGB first.")
  return
end

local sourceLayer = app.activeLayer
if not sourceLayer or sourceLayer.isGroup or sourceLayer.isTilemap then
  app.alert("Select the pixel layer containing the operator frames.")
  return
end

local pc = app.pixelColor
local CLEAR = pc.rgba(0, 0, 0, 0)
local CELL_W = 96
local CELL_H = 96
local FRAME_COUNT = 5
local OUTPUT_LAYER_BASE = "operator_diag_down_refined"

local function alphaAt(img, x, y)
  if x < 0 or y < 0 or x >= img.width or y >= img.height then
    return 0
  end
  return pc.rgbaA(img:getPixel(x, y))
end

local function isEdgePixel(img, x, y)
  if alphaAt(img, x, y) == 0 then
    return false
  end
  return alphaAt(img, x - 1, y) == 0
      or alphaAt(img, x + 1, y) == 0
      or alphaAt(img, x, y - 1) == 0
      or alphaAt(img, x, y + 1) == 0
end

local function isGold(pixel)
  local a = pc.rgbaA(pixel)
  if a == 0 then return false end

  local r = pc.rgbaR(pixel)
  local g = pc.rgbaG(pixel)
  local b = pc.rgbaB(pixel)

  return r >= 45
     and r >= g
     and r > b * 1.35
     and g > b * 1.15
end

local function scaleRgb(pixel, factor)
  local a = pc.rgbaA(pixel)
  if a == 0 then return pixel end

  local function clampByte(v)
    return math.max(0, math.min(255, math.floor(v + 0.5)))
  end

  return pc.rgba(
    clampByte(pc.rgbaR(pixel) * factor),
    clampByte(pc.rgbaG(pixel) * factor),
    clampByte(pc.rgbaB(pixel) * factor),
    a)
end

local function moveGoldLandmarks(src, out, x0, y0, x1, y1, dx, dy, minRgbSum)
  local moves = {}

  for y = y0, y1 do
    for x = x0, x1 do
      local pixel = src:getPixel(x, y)
      local rgbSum = pc.rgbaR(pixel) + pc.rgbaG(pixel) + pc.rgbaB(pixel)
      if isGold(pixel) and rgbSum >= minRgbSum then
        moves[#moves + 1] = { x = x, y = y, pixel = pixel }
      end
    end
  end

  -- Cut first, then paste, so adjacent highlight pixels move as one cluster.
  for _, move in ipairs(moves) do
    out:putPixel(move.x, move.y, CLEAR)
  end

  for _, move in ipairs(moves) do
    local nx = move.x + dx
    local ny = move.y + dy
    if nx >= 0 and ny >= 0 and nx < CELL_W and ny < CELL_H then
      out:putPixel(nx, ny, move.pixel)
    end
  end
end

local function refineFrame(sourceImage, frameIndex)
  local src = Image(sourceImage)
  local out = Image(sourceImage)

  -- -----------------------------------------------------------------------
  -- A. Commit the down-right facing direction.
  -- -----------------------------------------------------------------------

  -- Shift the visible amber face/visor information one pixel toward screen-right
  -- while leaving the outer hood mass anchored.
  moveGoldLandmarks(src, out, 38, 19, 50, 28, 1, 0, 120)

  -- Shift chest and belt landmarks one pixel right so the armor centerline no
  -- longer reinforces a straight-on pose.
  moveGoldLandmarks(src, out, 40, 30, 48, 57, 1, 0, 0)

  -- Compress the far/left silhouette by removing only its outermost edge.
  -- This affects the far shoulder, arm, and upper coat without hollowing the body.
  for y = 28, 61 do
    for x = 29, 40 do
      if isEdgePixel(src, x, y) and alphaAt(src, x - 1, y) == 0 then
        out:putPixel(x, y, CLEAR)
      end
    end
  end

  -- Broaden and lower the near/right shoulder and arm by one pixel. Copying only
  -- the exposed edge preserves the interior armor detail and avoids tearing.
  for y = 28, 60 do
    for x = 46, 62 do
      if isEdgePixel(src, x, y) and alphaAt(src, x + 1, y) == 0 then
        local dy = 0
        if y >= 31 and y <= 58 then dy = 1 end
        local nx = x + 1
        local ny = y + dy
        if nx < CELL_W and ny < CELL_H then
          out:putPixel(nx, ny, src:getPixel(x, y))
        end
      end
    end
  end

  -- -----------------------------------------------------------------------
  -- B. Five-frame breathing arc.
  -- Frame 1 neutral
  -- Frame 2 inhale
  -- Frame 3 peak
  -- Frame 4 exhale / cloth lag
  -- Frame 5 cloth recovery
  -- -----------------------------------------------------------------------

  if frameIndex == 2 or frameIndex == 3 then
    -- Lift only the upper silhouette by one pixel. The hood and boots remain
    -- anchored, so this reads as chest/shoulder breathing rather than bobbing.
    for y = 28, 39 do
      for x = 31, 61 do
        if alphaAt(src, x, y) > 0 and alphaAt(src, x, y - 1) == 0 then
          out:putPixel(x, y - 1, src:getPixel(x, y))
        end
      end
    end

    -- Remove the exposed lower lip of the upper torso where it borders empty
    -- space, completing the one-pixel upward settle without moving the feet.
    for y = 49, 57 do
      for x = 36, 56 do
        if isEdgePixel(src, x, y) and alphaAt(src, x, y + 1) == 0 then
          out:putPixel(x, y, CLEAR)
        end
      end
    end
  end

  if frameIndex == 3 then
    -- Peak inhale: near shoulder reaches its widest point. This is intentionally
    -- one extra edge pixel beyond frame 2, not a second full-body shift.
    for y = 29, 42 do
      for x = 46, 62 do
        if alphaAt(src, x, y) > 0 and alphaAt(src, x + 1, y) == 0 then
          local nx = x + 2
          local ny = y + 1
          if nx < CELL_W and ny < CELL_H then
            out:putPixel(nx, ny, src:getPixel(x, y))
          end
        end
      end
    end
  end

  -- Secondary cloth motion trails the torso by one frame.
  local clothSwing = ({ 0, 0, 1, 2, 1 })[frameIndex]
  if clothSwing > 0 then
    local edgePixels = {}

    -- Move only the lowest 11 pixels of the near/right panel. This keeps the
    -- waist stable while allowing the hem to lag and recover.
    for y = 68, 78 do
      for x = 45, 59 do
        if alphaAt(src, x, y) > 0 and alphaAt(src, x + 1, y) == 0 then
          edgePixels[#edgePixels + 1] = {
            x = x,
            y = y,
            pixel = src:getPixel(x, y)
          }
        end
      end
    end

    for _, edgePixel in ipairs(edgePixels) do
      local nx = math.min(CELL_W - 1, edgePixel.x + clothSwing)
      out:putPixel(nx, edgePixel.y, edgePixel.pixel)

      -- On frame 4, remove the old outer edge so the two-pixel lag reads as a
      -- displaced hem rather than a thicker coat.
      if clothSwing == 2 then
        out:putPixel(edgePixel.x, edgePixel.y, CLEAR)
      end
    end
  end

  -- Keep the far/left coat panel narrow and partially occluded.
  for y = 53, 76 do
    for x = 30, 40 do
      if isEdgePixel(src, x, y) and alphaAt(src, x - 1, y) == 0 then
        out:putPixel(x, y, CLEAR)
      end
    end
  end

  -- -----------------------------------------------------------------------
  -- C. Foot placement: near boot lower/outward, far boot tucked behind.
  -- -----------------------------------------------------------------------

  -- Extend the near/right boot one pixel right and down while preserving its
  -- contact mass. This establishes depth without making the whole sprite bob.
  for y = 67, 83 do
    for x = 45, 62 do
      if alphaAt(src, x, y) > 0
         and (alphaAt(src, x + 1, y) == 0 or alphaAt(src, x, y + 1) == 0) then
        local nx = math.min(CELL_W - 1, x + 1)
        local ny = math.min(CELL_H - 1, y + 1)
        out:putPixel(nx, ny, src:getPixel(x, y))
      end
    end
  end

  -- Pull the far/left boot edge one pixel inward so it sits behind the near boot.
  local farBootMoves = {}
  for y = 67, 83 do
    for x = 29, 43 do
      if isEdgePixel(src, x, y) and alphaAt(src, x - 1, y) == 0 then
        farBootMoves[#farBootMoves + 1] = {
          x = x,
          y = y,
          pixel = src:getPixel(x, y)
        }
      end
    end
  end

  for _, move in ipairs(farBootMoves) do
    out:putPixel(move.x, move.y, CLEAR)
    if move.x + 1 < CELL_W then
      out:putPixel(move.x + 1, move.y, move.pixel)
    end
  end

  -- -----------------------------------------------------------------------
  -- D. Directional value hierarchy.
  -- -----------------------------------------------------------------------

  -- Dim far-side gold and strengthen near-side gold. Neutral center highlights
  -- remain untouched so the face/chest still carry the focal hierarchy.
  for y = 26, 83 do
    for x = 29, 63 do
      local pixel = out:getPixel(x, y)
      if isGold(pixel) then
        if x < 44 then
          out:putPixel(x, y, scaleRgb(pixel, 0.78))
        elseif x > 46 then
          out:putPixel(x, y, scaleRgb(pixel, 1.08))
        end
      end
    end
  end

  return out
end

local function uniqueLayerName(sprite, baseName)
  local used = {}
  for _, layer in ipairs(sprite.layers) do
    used[layer.name] = true
  end

  if not used[baseName] then return baseName end

  local suffix = 2
  while used[baseName .. "_" .. suffix] do
    suffix = suffix + 1
  end
  return baseName .. "_" .. suffix
end

local activeCel = app.activeCel
local isFlatSheet = activeCel
  and activeCel.image.width == CELL_W * FRAME_COUNT
  and activeCel.image.height == CELL_H

local isTimeline = spr.width == CELL_W
  and spr.height == CELL_H
  and #spr.frames >= FRAME_COUNT

if not isFlatSheet and not isTimeline then
  app.alert(
    "Unsupported layout. Select either:\n" ..
    "• a 480x96 cel containing five horizontal 96x96 frames, or\n" ..
    "• a 96x96 sprite with at least five timeline frames."
  )
  return
end

local outputLayer
local outputLayerName = uniqueLayerName(spr, OUTPUT_LAYER_BASE)

app.transaction("Refine diagonal-down operator idle", function()
  outputLayer = spr:newLayer()
  outputLayer.name = outputLayerName
  outputLayer.opacity = sourceLayer.opacity
  outputLayer.blendMode = sourceLayer.blendMode

  if isFlatSheet then
    local sourceCel = activeCel
    local sourceSheet = sourceCel.image
    local outputSheet = Image(sourceSheet)

    for frameIndex = 1, FRAME_COUNT do
      local sourceRect = Rectangle(
        (frameIndex - 1) * CELL_W,
        0,
        CELL_W,
        CELL_H)

      local sourceFrame = Image(sourceSheet, sourceRect)
      local refinedFrame = refineFrame(sourceFrame, frameIndex)

      for y = 0, CELL_H - 1 do
        for x = 0, CELL_W - 1 do
          outputSheet:putPixel(
            (frameIndex - 1) * CELL_W + x,
            y,
            refinedFrame:getPixel(x, y))
        end
      end
    end

    spr:newCel(outputLayer, sourceCel.frame, outputSheet, sourceCel.position)
  else
    -- Timeline mode: read each active-layer cel into a full 96x96 canvas, so
    -- trimmed cel bounds and cel positions are handled correctly.
    for frameIndex = 1, FRAME_COUNT do
      local frame = spr.frames[frameIndex]
      local sourceCel = sourceLayer:cel(frame)
      local sourceFrame = Image(CELL_W, CELL_H, ColorMode.RGB)
      sourceFrame:clear()

      if sourceCel then
        sourceFrame:drawImage(sourceCel.image, sourceCel.position)
      end

      local refinedFrame = refineFrame(sourceFrame, frameIndex)
      spr:newCel(outputLayer, frame, refinedFrame, Point(0, 0))
    end
  end
end)

app.activeLayer = outputLayer
app.refresh()

app.alert(
  "Created layer: " .. outputLayerName .. "\n\n" ..
  "The original layer was left unchanged. Review at 100% zoom, especially " ..
  "the face rim, near shoulder, coat hem, and boot contacts."
)
