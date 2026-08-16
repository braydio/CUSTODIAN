-- operator_pair_reference.lua
--
-- CUSTODIAN modular operator alignment-repair helper.
--
-- Run this from File > Scripts while the alignment-repair conveyor
-- (modular_alignment_repair.py) has a canonical editable source open in
-- Aseprite, e.g. the lower_body sheet being edited for draw_01/e.
--
-- The script derives the paired sheet from the open file's own filename:
--   operator__lower_body__... <-> operator__upper_body__...
--   /source/animations/ mapped to /runtime/animations/
-- opens that partner, and pastes it into a NEW layer named "pair_reference".
--
-- The pasted layer is a REFERENCE LAYER: it stays visible on canvas while you
-- line up the seam, but Aseprite never exports it into the PNG you save, so
-- the partner can never be baked into the editable source. Hide or delete the
-- layer if you want a clean view while editing.

local OPPOSITE_LAYER = {
  ["__lower_body__"] = "__upper_body__",
  ["__upper_body__"] = "__lower_body__",
}

local function file_exists(path)
  if not path then return false end
  local f = io.open(path, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

local function derive_partner(source_file)
  local swapped = nil
  for from, to in pairs(OPPOSITE_LAYER) do
    if string.find(source_file, from, 1, true) then
      swapped = string.gsub(source_file, from, to, 1)
      break
    end
  end
  if not swapped then return nil end
  local runtime = string.gsub(swapped, "/source/animations/", "/runtime/animations/")
  if file_exists(runtime) then return runtime end
  if file_exists(swapped) then return swapped end
  return nil
end

local function main()
  local target = app.activeSprite
  if not target then
    return app.alert("No sprite open. Open the editable source first.")
  end

  local source_file = target.filename
  if source_file == nil or source_file == "" then
    return app.alert("Active sprite has no file path. Save it first.")
  end

  for _, layer in ipairs(target.layers) do
    if layer.name == "pair_reference" then
      return app.alert("Reference layer already present on this sheet.")
    end
  end

  local partner_file = derive_partner(source_file)
  if not partner_file then
    return app.alert(
      "Could not derive a paired sheet from:\n" .. source_file
    )
  end

  local partner = app.open(partner_file)
  if not partner then
    return app.alert("Could not open paired sheet:\n" .. partner_file)
  end

  local src_layers = partner.layers
  if src_layers == nil or #src_layers == 0 then
    return app.alert("Paired sheet has no layers:\n" .. partner_file)
  end

  local layer = target:newLayer()
  layer.name = "pair_reference"
  layer.isReference = true

  local src_layer = src_layers[1]
  local n = math.min(#target.frames, #partner.frames)
  local pasted = 0
  for i = 1, n do
    local cel = src_layer:cel(i)
    if cel and cel.image then
      local img = Image(cel.image.spec)
      img:drawImage(cel.image, 0, 0)
      local pos = cel.position or Point(0, 0)
      target:newCel(layer, i, img, Point(pos.x, pos.y))
      pasted = pasted + 1
    end
  end

  app.activeSprite = target

  if pasted == 0 then
    return app.alert("Paired sheet frames could not be copied.")
  end

  app.alert(
    "Pasted " .. pasted .. " frame(s) into reference layer \"pair_reference\".\n\n"
      .. "The partner layer is visible for alignment but will NOT be saved "
      .. "into the PNG. Hide it (or undo) before saving if you need a clean view."
  )
end

main()
