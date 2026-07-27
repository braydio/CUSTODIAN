-- Creates a non-destructive 96x96 humanoid cutout source document.
local PARTS_BACK_TO_FRONT = {
  "cape",
  "back_attachment",
  "upper_arm_back",
  "forearm_back",
  "hand_back",
  "thigh_back",
  "shin_back",
  "foot_back",
  "pelvis",
  "torso",
  "head",
  "thigh_front",
  "shin_front",
  "foot_front",
  "upper_arm_front",
  "forearm_front",
  "hand_front",
  "weapon",
  "front_attachment",
  "reserved",
}

local sprite = Sprite(96, 96, ColorMode.RGB)
sprite.filename = "enemy_id__rig_source__base__s__96.aseprite"
sprite.frames[1].duration = 1.0

-- Reuse the initial layer, then add the remaining semantic part layers.
sprite.layers[1].name = PARTS_BACK_TO_FRONT[1]
for i = 2, #PARTS_BACK_TO_FRONT do
  local layer = sprite:newLayer()
  layer.name = PARTS_BACK_TO_FRONT[i]
end

local guide_group = sprite:newGroup()
guide_group.name = "__GUIDES_DO_NOT_EXPORT"
guide_group.isVisible = true
local guide_layer = sprite:newLayer()
guide_layer.name = "__rig_guides"
guide_layer.parent = guide_group
guide_layer.opacity = 150

local image = Image(96, 96, ColorMode.RGB)
image:clear()
local cyan = Color { r = 32, g = 220, b = 255, a = 190 }
local amber = Color { r = 255, g = 182, b = 48, a = 190 }

local function put(x, y, color)
  if x >= 0 and x < 96 and y >= 0 and y < 96 then
    image:putPixel(x, y, color)
  end
end

for y = 0, 95 do put(48, y, cyan) end
for x = 0, 95 do
  put(x, 43, cyan) -- shoulder line
  put(x, 59, cyan) -- hip line
  put(x, 82, amber) -- baseline
end

local joints = {
  {48, 31}, {42, 43}, {54, 43}, {38, 54}, {59, 54},
  {39, 64}, {58, 64}, {44, 59}, {52, 59}, {42, 69},
  {54, 69}, {42, 79}, {54, 79},
}
for _, joint in ipairs(joints) do
  local x, y = joint[1], joint[2]
  put(x, y, amber)
  put(x - 1, y, amber)
  put(x + 1, y, amber)
  put(x, y - 1, amber)
  put(x, y + 1, amber)
end

sprite:newCel(guide_layer, 1, image, Point(0, 0))
app.activeSprite = sprite
app.activeLayer = sprite.layers[#sprite.layers - 1]
app.refresh()
print("[HumanoidRig] Created 96x96 source with 20 part layers and non-export guides.")
