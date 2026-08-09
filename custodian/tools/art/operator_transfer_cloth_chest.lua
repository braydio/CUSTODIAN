-- operator_transfer_cloth_chest.lua
-- CUSTODIAN / Aseprite
--
-- Purpose:
--   Rebuild the cloth chest/collar + gold cord treatment from the RIGHT-hand
--   donor sprite in the supplied 192x96 reference PNG and overlay a
--   front-facing version on the LEFT-hand legacy armored sprite.
--
-- Important:
--   This intentionally DOES NOT rotate/resample the donor raster. Arbitrary
--   rotation would destroy the pixel clusters. Instead, it samples the exact
--   donor palette and redraws the garment as front-facing pixel clusters.
--
-- Expected source:
--   the exact supplied 192x96 composite image, opened as the active Aseprite cel.
--
-- Output:
--   a new non-destructive layer named:
--     chest_cloth_goldcord__front_overlay
--
-- Coordinates are 0-based Aseprite image coordinates.

local spr = app.activeSprite
if not spr then
  app.alert("Open the supplied 192x96 reference PNG first.")
  return
end

local srcCel = app.activeCel
if not srcCel then
  app.alert("The active layer/frame has no cel to sample.")
  return
end

-- The attached reference is exactly 192x96.
if spr.width < 186 or spr.height < 61 then
  app.alert{
    title="Wrong source image",
    text={
      "This script is calibrated to the supplied composite reference.",
      "Expected approximately 192x96 with the legacy sprite on the left",
      "and the cloth/gold-cord donor sprite on the right."
    }
  }
  return
end

if spr.colorMode ~= ColorMode.RGB then
  app.alert{
    title="RGB image required",
    text={
      "Convert the reference to RGB Color first:",
      "Sprite > Color Mode > RGB Color",
      "",
      "That keeps the donor colors exact."
    }
  }
  return
end

-- ---------------------------------------------------------------------------
-- Micro-adjustment.
-- Leave these at 0 for the exact supplied reference.
-- If you later paste the same legacy sprite somewhere else, change only these.
-- ---------------------------------------------------------------------------
local DX = 0
local DY = 0

local srcImage = srcCel.image
local srcPos = srcCel.position

local function sampleGlobal(x, y)
  local lx = x - srcPos.x
  local ly = y - srcPos.y
  if lx < 0 or ly < 0 or lx >= srcImage.width or ly >= srcImage.height then
    return app.pixelColor.rgba(0, 0, 0, 0)
  end
  return srcImage:getPixel(lx, ly)
end

-- ---------------------------------------------------------------------------
-- Exact donor palette samples.
-- These coordinates are all taken from the RIGHT-hand cloth/collar/chest
-- treatment in the supplied reference image.
-- ---------------------------------------------------------------------------
local C = {
  cloth_black       = sampleGlobal(136, 35), -- 10,11,11
  cloth_deep        = sampleGlobal(129, 40), -- 18,18,20
  cloth_warm_shadow = sampleGlobal(135, 40), -- 40,30,21
  cloth_mid         = sampleGlobal(143, 44), -- 50,53,50
  cloth_fold        = sampleGlobal(139, 46), -- 49,51,45
  cloth_soft_dark   = sampleGlobal(151, 41), -- 28,29,29

  cord_shadow       = sampleGlobal(137, 42), -- 181,108,21
  cord_mid          = sampleGlobal(136, 44), -- 232,158,26
  cord_bright       = sampleGlobal(146, 31), -- 255,197,27
  cord_spec         = sampleGlobal(146, 32), -- 253,242,59
}

local transparent = app.pixelColor.rgba(0, 0, 0, 0)
local out = Image(spr.width, spr.height, spr.colorMode)
out:clear(transparent)

local function px(x, y, color)
  out:drawPixel(x + DX, y + DY, color)
end

local function span(y, x1, x2, color)
  for x=x1,x2 do
    px(x, y, color)
  end
end

-- ===========================================================================
-- 1. CLOTH COLLAR / SHOULDER MANTLE
--
-- Front-facing reconstruction of the donor's wrapped cloth silhouette.
-- The center is intentionally left more open below the collar so the legacy
-- armored breastplate remains readable underneath.
-- ===========================================================================

-- Left collar/lapel.
span(31, 39, 43, C.cloth_black)
span(32, 38, 44, C.cloth_deep)
span(33, 37, 44, C.cloth_mid)
span(34, 37, 45, C.cloth_mid)
span(35, 37, 45, C.cloth_deep)
span(36, 38, 45, C.cloth_mid)
span(37, 38, 44, C.cloth_mid)
span(38, 39, 44, C.cloth_deep)
span(39, 40, 44, C.cloth_deep)
span(40, 40, 43, C.cloth_mid)
span(41, 41, 43, C.cloth_deep)
span(42, 42, 43, C.cloth_deep)

-- Right collar/lapel.
span(31, 53, 57, C.cloth_black)
span(32, 52, 58, C.cloth_deep)
span(33, 52, 59, C.cloth_deep)
span(34, 51, 59, C.cloth_mid)
span(35, 51, 59, C.cloth_deep)
span(36, 51, 58, C.cloth_deep)
span(37, 52, 58, C.cloth_mid)
span(38, 52, 57, C.cloth_mid)
span(39, 52, 56, C.cloth_deep)
span(40, 53, 56, C.cloth_mid)
span(41, 53, 55, C.cloth_deep)
span(42, 53, 54, C.cloth_deep)

-- Cloth bridge immediately beneath the hood / throat.
span(31, 44, 52, C.cloth_black)
span(32, 45, 51, C.cloth_deep)
span(33, 46, 50, C.cloth_warm_shadow)

-- Directional cloth folds.  These keep the material from reading as flat armor.
local folds = {
  {38,33,C.cloth_fold},
  {39,34,C.cloth_fold},
  {40,35,C.cloth_mid},
  {41,36,C.cloth_fold},

  {57,34,C.cloth_soft_dark},
  {56,35,C.cloth_mid},
  {55,36,C.cloth_mid},

  {42,38,C.cloth_fold},
  {43,39,C.cloth_mid},
  {54,38,C.cloth_black},
  {53,39,C.cloth_black},
}
for _,p in ipairs(folds) do
  px(p[1], p[2], p[3])
end

-- ===========================================================================
-- 2. GOLD CORD
--
-- Reoriented as a shallow front-facing V.  Shadow pixels sit under the cord,
-- then selected mid/bright pixels create the braided/glinting donor treatment.
-- ===========================================================================

local cordShadow = {
  -- left half
  {39,33},{40,34},{41,35},{42,36},{43,37},
  {44,38},{45,39},{46,40},{47,41},{48,42},

  -- right half
  {57,33},{56,34},{55,35},{54,36},{53,37},
  {52,38},{51,39},{50,40},{49,41},
}
for _,p in ipairs(cordShadow) do
  px(p[1], p[2], C.cord_shadow)
end

local cordMid = {
  {40,33},{42,35},{44,37},{46,39},{48,41},
  {56,33},{54,35},{52,37},{50,39},
}
for _,p in ipairs(cordMid) do
  px(p[1], p[2], C.cord_mid)
end

-- Sparse bright pixels only: preserves the donor's chunky pixel-art hierarchy.
px(44,37,C.cord_bright)
px(48,41,C.cord_spec)
px(52,37,C.cord_bright)

-- ===========================================================================
-- 3. COLLAR PIPING / GOLD TERMINALS
--
-- Small gold hits beside the hood connect the new cloth piece to the legacy
-- armor without replacing the helmet/hood silhouette.
-- ===========================================================================

px(40,31,C.cord_shadow)
px(41,31,C.cord_mid)
px(42,32,C.cord_bright)

px(54,32,C.cord_bright)
px(55,31,C.cord_mid)
px(56,31,C.cord_shadow)

-- ===========================================================================
-- Create non-destructive overlay layer.
-- ===========================================================================

app.transaction("Front-facing cloth chest + gold cord overlay", function()
  local layer = spr:newLayer()
  layer.name = "chest_cloth_goldcord__front_overlay"
  spr:newCel(layer, app.activeFrame.frameNumber, out, Point(0, 0))
end)

app.refresh()

app.alert{
  title="Overlay created",
  text={
    "Created: chest_cloth_goldcord__front_overlay",
    "",
    "The legacy armor is untouched underneath.",
    "The donor palette is sampled directly from the right-hand sprite.",
    "The garment geometry is manually reoriented for the front-facing left sprite.",
    "",
    "If you want a 1px placement adjustment, edit DX/DY at the top and rerun."
  }
}
