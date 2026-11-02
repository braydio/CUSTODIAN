-- Export named Aseprite slices into the Operator frame-aware weapon socket JSON.
-- CLI example:
-- aseprite -b source.aseprite --script-param output=out.json \
--   --script-param weapon_id=carbine_mk1 \
--   --script tools/aseprite/export_operator_weapon_sockets.lua

local sprite = app.activeSprite
if not sprite then error("No active Aseprite sprite") end

local required = {
  grip = "socket_weapon_grip",
  support_grip = "socket_support_grip",
  muzzle = "socket_muzzle",
  ejection = "socket_ejection",
}

local function find_slice(name)
  for _, slice in ipairs(sprite.slices) do
    if slice.name == name then return slice end
  end
  error("Missing required Aseprite slice: " .. name)
end

local function find_optional_slice(name)
  for _, slice in ipairs(sprite.slices) do
    if slice.name == name then return slice end
  end
  return nil
end

local slices = {}
for key, name in pairs(required) do slices[key] = find_slice(name) end
slices.operator_root = find_optional_slice("socket_operator_root")

local function point_for(slice, frame_number)
  local key = nil
  for _, candidate in ipairs(slice.keys) do
    if candidate.frameNumber <= frame_number and
       (not key or candidate.frameNumber > key.frameNumber) then
      key = candidate
    end
  end
  if not key then error("Missing " .. slice.name .. " key at frame " .. frame_number) end
  local bounds = key.bounds
  return {bounds.x + bounds.width / 2, bounds.y + bounds.height / 2}
end

local function operator_local_point(slice, frame_number)
  local point = point_for(slice, frame_number)
  local origin = {sprite.width / 2, sprite.height / 2}
  if slices.operator_root then origin = point_for(slices.operator_root, frame_number) end
  return {point[1] - origin[1], point[2] - origin[2]}
end

local function escape(value)
  return value:gsub("\\", "\\\\"):gsub('"', '\\"')
end

local function encode(value)
  local kind = type(value)
  if kind == "string" then return '"' .. escape(value) .. '"' end
  if kind == "number" or kind == "boolean" then return tostring(value) end
  if kind ~= "table" then return "null" end
  local is_array = #value > 0
  local parts = {}
  if is_array then
    for _, item in ipairs(value) do table.insert(parts, encode(item)) end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  local keys = {}
  for key, _ in pairs(value) do table.insert(keys, key) end
  table.sort(keys)
  for _, key in ipairs(keys) do
    table.insert(parts, encode(key) .. ":" .. encode(value[key]))
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

local tracks = {}
-- MIGRATION SEAM (C2a-R3). Socket tracks are keyed by the LIVE upper-body
-- animation name, and after the body-pair cutover that name is the canonical
-- semantic identity. The Carbine socket master still carries legacy tag names,
-- so they are canonicalized here, at generation time.
--
-- This is NOT a runtime alias: nothing translates names while the game runs.
-- EXIT CONDITION: retag `content/_aseprite/sprites/operator/source/
-- aiming_2h_carbine_source.aseprite` with the canonical identities and delete
-- this table. Tags already authored canonically pass through untouched.
local LEGACY_TAG_MIGRATION = {
  ranged_2h_stance_modular_right = "ranged_2h/posture/stance_01/e/upper_body",
  ranged_2h_stance_modular_left = "ranged_2h/posture/stance_01/w/upper_body",
  ranged_2h_stance_modular_down_right = "ranged_2h/posture/stance_01/se/upper_body",
  ranged_2h_stance_modular_down_left = "ranged_2h/posture/stance_01/sw/upper_body",
  ranged_2h_aim_modular_right = "ranged_2h/cosmetic/aim_01/e/upper_body",
  ranged_2h_aim_modular_left = "ranged_2h/cosmetic/aim_01/w/upper_body",
  ranged_2h_aim_modular_down_right = "ranged_2h/cosmetic/aim_01/se/upper_body",
  ranged_2h_aim_modular_down_left = "ranged_2h/cosmetic/aim_01/sw/upper_body",
  ranged_2h_fire_modular_right = "ranged_2h/cosmetic/fire_01/e/upper_body",
  ranged_2h_fire_modular_left = "ranged_2h/cosmetic/fire_01/w/upper_body",
  ranged_2h_fire_modular_down_right = "ranged_2h/cosmetic/fire_01/se/upper_body",
  ranged_2h_fire_modular_down_left = "ranged_2h/cosmetic/fire_01/sw/upper_body",
}

-- A socket key must be a canonical animation identity. Anything else would be
-- published as a track nothing can ever look up, because the live animation
-- name never takes that shape again.
local function canonical_track_key(tag_name)
  local migrated = LEGACY_TAG_MIGRATION[tag_name]
  if migrated then return migrated end
  if not string.find(tag_name, "/", 1, true) then
    error("Socket tag '" .. tag_name .. "' is not a canonical animation identity."
      .. " Retag it as profile/group/action/direction/layer, or add it to"
      .. " LEGACY_TAG_MIGRATION if it is known migration residue.")
  end
  return tag_name
end

for _, tag in ipairs(sprite.tags) do
  local frames = {}
  for frame_number = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
    table.insert(frames, {
      grip = operator_local_point(slices.grip, frame_number),
      support_grip = operator_local_point(slices.support_grip, frame_number),
      muzzle = operator_local_point(slices.muzzle, frame_number),
      ejection = operator_local_point(slices.ejection, frame_number),
      weapon_angle_deg = 0,
      weapon_z = 3,
    })
  end
  tracks[canonical_track_key(tag.name)] = frames
end

local output = app.params.output
if not output or output == "" then error("Pass --script-param output=<path>") end
local file = assert(io.open(output, "w"))
file:write(encode({
  schema_version = 1,
  owner = "operator",
  weapon_id = app.params.weapon_id or "unknown",
  cell_size = {sprite.width, sprite.height},
  coordinate_space = "operator_local",
  tracks = tracks,
}))
file:write("\n")
file:close()
print("Exported operator weapon sockets: " .. output)
