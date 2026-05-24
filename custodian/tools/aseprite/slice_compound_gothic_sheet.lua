-- slice_compound_gothic_sheet.lua
-- CUSTODIAN gothic compound slicer
--
-- Run from repo root:
--   aseprite -b ./custodian/content/tiles/compound_gothic_sheet.png \
--     --script ./custodian/tools/aseprite/slice_compound_gothic_sheet.lua \
--     --script-param repo="$PWD"
--
-- Output:
--   ./custodian/content/tiles/...
--   ./custodian/content/props/...
--   ./custodian/content/sprites/...
--   ./custodian/content/procgen/special_rooms/gothic_compound/compound_gothic_sheet_manifest.json
--
-- Notes:
-- - This is tuned for the 1536x1024 labeled sheet shown in chat.
-- - Grid-like sections use fixed slicing.
-- - Prop/object sections use dark-background component detection.
-- - Review outputs before wiring procgen. The source sheet has labels/panel borders,
--   so this is a strong first pass, not a magic perfect semantic classifier.

local pc = app.pixelColor

local BASE_W = 1536
local BASE_H = 1024
local TILE_SIZE = 32

local PARAM_REPO = app.params["repo"] or os.getenv("PWD") or "."
local SOURCE_PATH = app.params["source"] or (PARAM_REPO .. "/custodian/content/tiles/compound_gothic_sheet.png")
local CUSTODIAN_ROOT = PARAM_REPO .. "/custodian"

local MANIFEST_PATH =
  CUSTODIAN_ROOT .. "/content/procgen/special_rooms/gothic_compound/compound_gothic_sheet_manifest.json"

local TRANSPARENT = pc.rgba(0, 0, 0, 0)

local manifest = {
  schema = "custodian.compound_sheet_slices.v1",
  source = SOURCE_PATH,
  tile_size = TILE_SIZE,
  generated_by = "slice_compound_gothic_sheet.lua",
  assets = {}
}

local function shell_quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function mkdir_p(path)
  os.execute("mkdir -p " .. shell_quote(path))
end

local function join_path(a, b)
  if string.sub(a, -1) == "/" then
    return a .. b
  end
  return a .. "/" .. b
end

local function rel_to_res(path)
  local marker = "/custodian/"
  local i = string.find(path, marker, 1, true)
  if i then
    return "res://" .. string.sub(path, i + string.len(marker))
  end
  return path
end

local function json_escape(s)
  s = tostring(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub('"', '\\"')
  s = s:gsub("\n", "\\n")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\t", "\\t")
  return '"' .. s .. '"'
end

local function is_array(t)
  if type(t) ~= "table" then return false end
  local n = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then return false end
    if k > n then n = k end
  end
  for i = 1, n do
    if t[i] == nil then return false end
  end
  return true
end

local function encode_json(v, indent)
  indent = indent or 0
  local tv = type(v)

  if tv == "nil" then
    return "null"
  elseif tv == "boolean" then
    return v and "true" or "false"
  elseif tv == "number" then
    return tostring(v)
  elseif tv == "string" then
    return json_escape(v)
  elseif tv == "table" then
    local pad = string.rep("  ", indent)
    local child = string.rep("  ", indent + 1)

    if is_array(v) then
      if #v == 0 then return "[]" end
      local parts = {}
      for i = 1, #v do
        table.insert(parts, child .. encode_json(v[i], indent + 1))
      end
      return "[\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "]"
    else
      local keys = {}
      for k, _ in pairs(v) do table.insert(keys, k) end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

      if #keys == 0 then return "{}" end

      local parts = {}
      for _, k in ipairs(keys) do
        table.insert(parts, child .. json_escape(k) .. ": " .. encode_json(v[k], indent + 1))
      end
      return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
    end
  end

  return "null"
end

local function write_text(path, text)
  mkdir_p(path:match("^(.*)/[^/]+$") or ".")
  local f = io.open(path, "w")
  if not f then
    error("Could not write: " .. path)
  end
  f:write(text)
  f:close()
end

local function rgba(px)
  return pc.rgbaR(px), pc.rgbaG(px), pc.rgbaB(px), pc.rgbaA(px)
end

local function color_dist2(px, bg)
  local r, g, b, a = rgba(px)
  local dr = r - bg.r
  local dg = g - bg.g
  local db = b - bg.b
  return dr * dr + dg * dg + db * db
end

local function sample_bg_colors(src_img, rect)
  local pts = {
    { rect.x + 1, rect.y + 1 },
    { rect.x + rect.w - 2, rect.y + 1 },
    { rect.x + 1, rect.y + rect.h - 2 },
    { rect.x + rect.w - 2, rect.y + rect.h - 2 },
    { rect.x + math.floor(rect.w / 2), rect.y + 1 },
  }

  local samples = {}

  for _, p in ipairs(pts) do
    local x = math.max(0, math.min(src_img.width - 1, p[1]))
    local y = math.max(0, math.min(src_img.height - 1, p[2]))
    local px = src_img:getPixel(x, y)
    local r, g, b, a = rgba(px)
    table.insert(samples, { r = r, g = g, b = b, a = a })
  end

  -- Common dark panel background fallbacks from this sheet.
  table.insert(samples, { r = 7, g = 12, b = 14, a = 255 })
  table.insert(samples, { r = 9, g = 16, b = 18, a = 255 })
  table.insert(samples, { r = 12, g = 18, b = 20, a = 255 })

  return samples
end

local function is_bg_pixel(px, bg_samples, threshold)
  local r, g, b, a = rgba(px)
  if a == 0 then return true end

  local limit = threshold * threshold
  for _, bg in ipairs(bg_samples) do
    if color_dist2(px, bg) <= limit then
      return true
    end
  end

  return false
end

local function scaled_rect(src, x, y, w, h)
  local sx = src.width / BASE_W
  local sy = src.height / BASE_H

  return {
    x = math.floor(x * sx + 0.5),
    y = math.floor(y * sy + 0.5),
    w = math.floor(w * sx + 0.5),
    h = math.floor(h * sy + 0.5)
  }
end

local function clamp_rect_to_sprite(src, rect)
  if rect.x < 0 then
    rect.w = rect.w + rect.x
    rect.x = 0
  end
  if rect.y < 0 then
    rect.h = rect.h + rect.y
    rect.y = 0
  end
  if rect.x + rect.w > src.width then
    rect.w = src.width - rect.x
  end
  if rect.y + rect.h > src.height then
    rect.h = src.height - rect.y
  end
  return rect
end

local function find_non_bg_bbox(src_img, rect, bg_samples, threshold)
  local minx, miny = rect.w, rect.h
  local maxx, maxy = -1, -1

  for yy = 0, rect.h - 1 do
    for xx = 0, rect.w - 1 do
      local px = src_img:getPixel(rect.x + xx, rect.y + yy)
      if not is_bg_pixel(px, bg_samples, threshold) then
        if xx < minx then minx = xx end
        if yy < miny then miny = yy end
        if xx > maxx then maxx = xx end
        if yy > maxy then maxy = yy end
      end
    end
  end

  if maxx < minx or maxy < miny then
    return nil
  end

  return {
    x = rect.x + minx,
    y = rect.y + miny,
    w = maxx - minx + 1,
    h = maxy - miny + 1
  }
end

local function expand_rect(rect, pad, src)
  local r = {
    x = rect.x - pad,
    y = rect.y - pad,
    w = rect.w + pad * 2,
    h = rect.h + pad * 2
  }
  return clamp_rect_to_sprite(src, r)
end

local function anchor_for(mode, w, h)
  if mode == "top_left" then
    return { mode = mode, x = 0, y = 0 }
  elseif mode == "bottom_cell" then
    return { mode = mode, x = math.floor(TILE_SIZE / 2), y = h }
  elseif mode == "bottom_center" then
    return { mode = mode, x = math.floor(w / 2), y = h }
  else
    return { mode = "center", x = math.floor(w / 2), y = math.floor(h / 2) }
  end
end

local function save_crop(src, src_img, opts)
  local rect = clamp_rect_to_sprite(src, opts.rect)
  local bg_samples = sample_bg_colors(src_img, rect)
  local threshold = opts.threshold or 10

  if opts.trim then
    local bbox = find_non_bg_bbox(src_img, rect, bg_samples, threshold)
    if not bbox then return nil end
    rect = expand_rect(bbox, opts.pad or 0, src)
    bg_samples = sample_bg_colors(src_img, rect)
  end

  mkdir_p(opts.dest)

  local out = Sprite(rect.w, rect.h, ColorMode.RGB)
  local out_img = out.cels[1].image

  for yy = 0, rect.h - 1 do
    for xx = 0, rect.w - 1 do
      local px = src_img:getPixel(rect.x + xx, rect.y + yy)
      if opts.transparentize and is_bg_pixel(px, bg_samples, threshold) then
        out_img:putPixel(xx, yy, TRANSPARENT)
      else
        out_img:putPixel(xx, yy, px)
      end
    end
  end

  local filename = opts.filename
  local path = join_path(opts.dest, filename)
  out:saveAs(path)
  out:close()

  local entry = {
    id = opts.id,
    file = rel_to_res(path),
    source_rect_px = { x = rect.x, y = rect.y, w = rect.w, h = rect.h },
    category = opts.category,
    kind = opts.kind,
    layer = opts.layer,
    collision = opts.collision,
    blocks_movement = opts.blocks_movement,
    runtime_class = opts.runtime_class,
    tags = opts.tags or {},
    size_px = { w = rect.w, h = rect.h },
    grid_size_tiles = {
      w = math.max(1, math.ceil(rect.w / TILE_SIZE)),
      h = math.max(1, math.ceil(rect.h / TILE_SIZE))
    },
    anchor = anchor_for(opts.anchor_mode or "bottom_center", rect.w, rect.h),
    review_required = opts.review_required == true
  }

  table.insert(manifest.assets, entry)
  return entry
end

local function grid_section(src, src_img, def)
  local count = 0

  for row = 0, def.rows - 1 do
    for col = 0, def.cols - 1 do
      count = count + 1

      local x = def.x + col * (def.step_x or def.cell_w)
      local y = def.y + row * (def.step_y or def.cell_h)
      local w = def.crop_w or def.cell_w
      local h = def.crop_h or def.cell_h

      local rect = scaled_rect(src, x, y, w, h)
      local id = string.format("%s_%03d", def.prefix, count)
      local filename = id .. ".png"

      save_crop(src, src_img, {
        rect = rect,
        id = id,
        filename = filename,
        dest = join_path(CUSTODIAN_ROOT, def.dest),
        category = def.category,
        kind = def.kind,
        layer = def.layer,
        runtime_class = def.runtime_class,
        collision = def.collision,
        blocks_movement = def.blocks_movement,
        tags = def.tags,
        transparentize = def.transparentize or false,
        trim = def.trim or false,
        pad = def.pad or 0,
        threshold = def.threshold or 10,
        anchor_mode = def.anchor_mode or "top_left",
        review_required = def.review_required or false
      })
    end
  end
end

local function rects_overlap(a, b, pad)
  pad = pad or 0
  return not (
    a.x + a.w + pad < b.x or
    b.x + b.w + pad < a.x or
    a.y + a.h + pad < b.y or
    b.y + b.h + pad < a.y
  )
end

local function merge_two(a, b)
  local x1 = math.min(a.x, b.x)
  local y1 = math.min(a.y, b.y)
  local x2 = math.max(a.x + a.w, b.x + b.w)
  local y2 = math.max(a.y + a.h, b.y + b.h)
  return { x = x1, y = y1, w = x2 - x1, h = y2 - y1, area = (a.area or 0) + (b.area or 0) }
end

local function merge_boxes(boxes, pad)
  local changed = true

  while changed do
    changed = false
    local out = {}
    local used = {}

    for i = 1, #boxes do
      if not used[i] then
        local current = boxes[i]
        used[i] = true

        for j = i + 1, #boxes do
          if not used[j] and rects_overlap(current, boxes[j], pad) then
            current = merge_two(current, boxes[j])
            used[j] = true
            changed = true
          end
        end

        table.insert(out, current)
      end
    end

    boxes = out
  end

  return boxes
end

local function auto_components(src, src_img, def)
  local rect = clamp_rect_to_sprite(src, scaled_rect(src, def.x, def.y, def.w, def.h))
  local bg_samples = sample_bg_colors(src_img, rect)
  local threshold = def.threshold or 10
  local rw, rh = rect.w, rect.h
  local visited = {}
  local boxes = {}

  local function idx(x, y)
    return y * rw + x + 1
  end

  local function is_fg_local(x, y)
    if x < 0 or y < 0 or x >= rw or y >= rh then return false end
    local px = src_img:getPixel(rect.x + x, rect.y + y)
    return not is_bg_pixel(px, bg_samples, threshold)
  end

  for y = 0, rh - 1 do
    for x = 0, rw - 1 do
      local start_i = idx(x, y)

      if not visited[start_i] and is_fg_local(x, y) then
        local qx = { x }
        local qy = { y }
        local qi = 1
        visited[start_i] = true

        local minx, miny = x, y
        local maxx, maxy = x, y
        local area = 0

        while qi <= #qx do
          local cx = qx[qi]
          local cy = qy[qi]
          qi = qi + 1
          area = area + 1

          if cx < minx then minx = cx end
          if cy < miny then miny = cy end
          if cx > maxx then maxx = cx end
          if cy > maxy then maxy = cy end

          local neigh = {
            { cx + 1, cy },
            { cx - 1, cy },
            { cx, cy + 1 },
            { cx, cy - 1 }
          }

          for _, p in ipairs(neigh) do
            local nx, ny = p[1], p[2]
            if nx >= 0 and ny >= 0 and nx < rw and ny < rh then
              local ni = idx(nx, ny)
              if not visited[ni] and is_fg_local(nx, ny) then
                visited[ni] = true
                table.insert(qx, nx)
                table.insert(qy, ny)
              end
            end
          end
        end

        local bw = maxx - minx + 1
        local bh = maxy - miny + 1

        local too_small = area < (def.min_area or 12) or bw < (def.min_w or 4) or bh < (def.min_h or 4)
        local likely_panel_line = (bw > rw * 0.90 and bh < 8) or (bh > rh * 0.90 and bw < 8)

        if not too_small and not likely_panel_line then
          table.insert(boxes, {
            x = rect.x + minx,
            y = rect.y + miny,
            w = bw,
            h = bh,
            area = area
          })
        end
      end
    end
  end

  boxes = merge_boxes(boxes, def.merge or 6)

  table.sort(boxes, function(a, b)
    if math.abs(a.y - b.y) > 12 then
      return a.y < b.y
    end
    return a.x < b.x
  end)

  local count = 0

  for _, b in ipairs(boxes) do
    local skip = false

    if b.w > (def.max_w or 9999) then skip = true end
    if b.h > (def.max_h or 9999) then skip = true end

    if not skip then
      count = count + 1
      local id = string.format("%s_%03d", def.prefix, count)
      save_crop(src, src_img, {
        rect = expand_rect(b, def.pad or 2, src),
        id = id,
        filename = id .. ".png",
        dest = join_path(CUSTODIAN_ROOT, def.dest),
        category = def.category,
        kind = def.kind,
        layer = def.layer,
        runtime_class = def.runtime_class,
        collision = def.collision,
        blocks_movement = def.blocks_movement,
        tags = def.tags,
        transparentize = true,
        trim = true,
        pad = 0,
        threshold = def.threshold or 10,
        anchor_mode = def.anchor_mode or "bottom_center",
        review_required = def.review_required ~= false
      })
    end
  end
end

local function manual_crop(src, src_img, def)
  local rect = scaled_rect(src, def.x, def.y, def.w, def.h)
  save_crop(src, src_img, {
    rect = rect,
    id = def.id,
    filename = def.id .. ".png",
    dest = join_path(CUSTODIAN_ROOT, def.dest),
    category = def.category,
    kind = def.kind,
    layer = def.layer,
    runtime_class = def.runtime_class,
    collision = def.collision,
    blocks_movement = def.blocks_movement,
    tags = def.tags,
    transparentize = def.transparentize or false,
    trim = def.trim or false,
    pad = def.pad or 0,
    threshold = def.threshold or 10,
    anchor_mode = def.anchor_mode or "top_left",
    review_required = def.review_required or false
  })
end

local function frame_row(src, src_img, def)
  for i = 1, def.count do
    local x = def.x + (i - 1) * def.step_x
    local id = string.format("%s_%03d", def.prefix, i)

    save_crop(src, src_img, {
      rect = scaled_rect(src, x, def.y, def.w, def.h),
      id = id,
      filename = id .. ".png",
      dest = join_path(CUSTODIAN_ROOT, def.dest),
      category = def.category,
      kind = def.kind,
      layer = def.layer,
      runtime_class = "animated_sprite_frame",
      collision = false,
      blocks_movement = false,
      tags = def.tags,
      transparentize = true,
      trim = true,
      pad = def.pad or 2,
      threshold = def.threshold or 10,
      anchor_mode = "bottom_center",
      review_required = false
    })
  end
end

local src = app.activeSprite
if not src then
  src = app.open(SOURCE_PATH)
end

if not src then
  error("Could not open source sheet: " .. SOURCE_PATH)
end

if not src.cels or #src.cels == 0 then
  error("Source sheet has no cels: " .. SOURCE_PATH)
end

local src_img = src.cels[1].image

-- -------------------------------------------------------------------------
-- TILEMAP / TILE-LIKE SECTIONS
-- -------------------------------------------------------------------------

grid_section(src, src_img, {
  prefix = "floor_tile",
  x = 16, y = 31,
  cols = 10, rows = 3,
  cell_w = 50, cell_h = 52,
  crop_w = 48, crop_h = 48,
  dest = "content/tiles/interiors/gothic/floors",
  category = "terrain_base",
  kind = "floor_tile",
  layer = "BaseGroundLayer",
  runtime_class = "tilemap_cell",
  collision = false,
  blocks_movement = false,
  anchor_mode = "top_left",
  tags = { "floor", "interior", "gothic" },
  review_required = false
})

grid_section(src, src_img, {
  prefix = "road_path",
  x = 17, y = 363,
  cols = 10, rows = 1,
  cell_w = 50, cell_h = 68,
  crop_w = 48, crop_h = 66,
  dest = "content/tiles/roads_paths/runtime/gothic_compound",
  category = "road_path",
  kind = "road_or_path_tile",
  layer = "RoadPathLayer",
  runtime_class = "tilemap_cell",
  collision = false,
  blocks_movement = false,
  anchor_mode = "top_left",
  tags = { "road", "path", "gothic" },
  review_required = true
})

grid_section(src, src_img, {
  prefix = "floor_detail",
  x = 17, y = 467,
  cols = 10, rows = 2,
  cell_w = 50, cell_h = 52,
  crop_w = 48, crop_h = 48,
  dest = "content/tiles/decals/gothic_compound/floor",
  category = "floor_decal",
  kind = "decorative_floor_detail",
  layer = "DecalLayer",
  runtime_class = "tilemap_decal",
  collision = false,
  blocks_movement = false,
  anchor_mode = "top_left",
  tags = { "decal", "floor", "gothic" },
  review_required = false
})

auto_components(src, src_img, {
  prefix = "ritual_floor_decal",
  x = 975, y = 310, w = 545, h = 68,
  dest = "content/tiles/decals/gothic_compound/ritual",
  category = "ritual_floor_decal",
  kind = "ritual_decal",
  layer = "DecalLayer",
  runtime_class = "tilemap_decal",
  collision = false,
  blocks_movement = false,
  anchor_mode = "center",
  tags = { "ritual", "decal", "floor", "objective_marker" },
  min_area = 80,
  min_w = 12,
  min_h = 12,
  merge = 8,
  pad = 3,
  threshold = 11,
  review_required = true
})

-- -------------------------------------------------------------------------
-- WALLS / GATES / COMPOUND ARCHITECTURE
-- -------------------------------------------------------------------------

auto_components(src, src_img, {
  prefix = "wall_tile",
  x = 15, y = 216, w = 500, h = 112,
  dest = "content/tiles/walls/gothic_compound/wall_tiles",
  category = "wall",
  kind = "modular_wall",
  layer = "WallLayer",
  runtime_class = "tilemap_or_wall_segment",
  collision = true,
  blocks_movement = true,
  anchor_mode = "bottom_cell",
  tags = { "wall", "gothic", "compound" },
  min_area = 40,
  min_w = 6,
  min_h = 8,
  merge = 7,
  pad = 2,
  threshold = 10,
  review_required = true
})

auto_components(src, src_img, {
  prefix = "wall_top_edge",
  x = 15, y = 616, w = 505, h = 112,
  dest = "content/tiles/walls/gothic_compound/tops_edges",
  category = "wall_top_edge",
  kind = "wall_top_or_edge",
  layer = "WallLayer",
  runtime_class = "tilemap_or_wall_segment",
  collision = true,
  blocks_movement = true,
  anchor_mode = "bottom_cell",
  tags = { "wall", "top", "edge", "gothic" },
  min_area = 30,
  min_w = 5,
  min_h = 5,
  merge = 6,
  pad = 2,
  threshold = 10,
  review_required = true
})

auto_components(src, src_img, {
  prefix = "door_gate_mechanism",
  x = 15, y = 765, w = 506, h = 236,
  dest = "content/props/gothic_compound/doors_gates",
  category = "door_gate_mechanism",
  kind = "door_gate_prop",
  layer = "GateLayer",
  runtime_class = "sprite_prop_or_scene",
  collision = "partial",
  blocks_movement = "review",
  anchor_mode = "bottom_center",
  tags = { "door", "gate", "mechanism", "gothic" },
  min_area = 80,
  min_w = 10,
  min_h = 12,
  merge = 8,
  pad = 3,
  threshold = 10,
  review_required = true
})

manual_crop(src, src_img, {
  id = "event_room_ritual_chamber",
  x = 973, y = 29, w = 548, h = 239,
  dest = "content/procgen/special_rooms/gothic_compound/rooms",
  category = "special_room_stamp",
  kind = "ritual_event_room",
  layer = "RoomLayer",
  runtime_class = "room_stamp_source",
  collision = "from_room_data",
  blocks_movement = "from_room_data",
  anchor_mode = "top_left",
  tags = { "special_room", "ritual_room", "gothic_compound" },
  transparentize = false,
  trim = false,
  review_required = true
})

-- -------------------------------------------------------------------------
-- PROPS / STATIC WORLD OBJECTS
-- -------------------------------------------------------------------------

auto_components(src, src_img, {
  prefix = "prop",
  x = 535, y = 31, w = 426, h = 707,
  dest = "content/props/gothic_compound/misc",
  category = "prop",
  kind = "static_prop",
  layer = "PropLayer",
  runtime_class = "sprite_prop",
  collision = "review",
  blocks_movement = "review",
  anchor_mode = "bottom_center",
  tags = { "prop", "gothic", "industrial" },
  min_area = 35,
  min_w = 5,
  min_h = 5,
  merge = 7,
  pad = 3,
  threshold = 10,
  review_required = true
})

auto_components(src, src_img, {
  prefix = "rock_rubble_cluster",
  x = 972, y = 419, w = 226, h = 164,
  dest = "content/props/gothic_compound/rubble",
  category = "rubble",
  kind = "rubble_cluster",
  layer = "PropLayer",
  runtime_class = "sprite_prop",
  collision = true,
  blocks_movement = true,
  anchor_mode = "bottom_center",
  tags = { "rubble", "cover", "blocker" },
  min_area = 45,
  min_w = 8,
  min_h = 7,
  merge = 7,
  pad = 3,
  threshold = 10,
  review_required = true
})

auto_components(src, src_img, {
  prefix = "dead_tree_vegetation",
  x = 972, y = 620, w = 226, h = 120,
  dest = "content/props/gothic_compound/vegetation",
  category = "dead_vegetation",
  kind = "dead_tree_or_shrub",
  layer = "PropLayer",
  runtime_class = "sprite_prop",
  collision = true,
  blocks_movement = true,
  anchor_mode = "bottom_center",
  tags = { "dead_tree", "vegetation", "gothic", "blocker" },
  min_area = 50,
  min_w = 8,
  min_h = 10,
  merge = 8,
  pad = 3,
  threshold = 10,
  review_required = true
})

auto_components(src, src_img, {
  prefix = "light_effect_object",
  x = 535, y = 765, w = 284, h = 235,
  dest = "content/props/gothic_compound/lights_effects",
  category = "light_or_effect_object",
  kind = "light_prop",
  layer = "LightLayer",
  runtime_class = "sprite_prop_or_light_marker",
  collision = "partial",
  blocks_movement = false,
  anchor_mode = "bottom_center",
  tags = { "light", "lamp", "effect", "gothic" },
  min_area = 35,
  min_w = 5,
  min_h = 8,
  merge = 7,
  pad = 3,
  threshold = 10,
  review_required = true
})

auto_components(src, src_img, {
  prefix = "spike_barricade_fence",
  x = 824, y = 765, w = 287, h = 235,
  dest = "content/props/gothic_compound/barriers",
  category = "barrier",
  kind = "spike_barricade_or_fence",
  layer = "PropLayer",
  runtime_class = "sprite_prop",
  collision = true,
  blocks_movement = true,
  anchor_mode = "bottom_center",
  tags = { "barrier", "spike", "fence", "barricade" },
  min_area = 40,
  min_w = 6,
  min_h = 7,
  merge = 7,
  pad = 3,
  threshold = 10,
  review_required = true
})

-- -------------------------------------------------------------------------
-- FORLORN RITUALANT SPRITES
-- -------------------------------------------------------------------------

frame_row(src, src_img, {
  prefix = "forlorn_ritualant_idle",
  x = 1216, y = 437,
  count = 6,
  step_x = 50,
  w = 47, h = 65,
  dest = "content/sprites/enemies/forlorn_ritualant/idle",
  category = "actor_frame",
  kind = "idle",
  layer = "ActorLayer",
  tags = { "enemy", "forlorn_ritualant", "idle" },
  pad = 3,
  threshold = 10
})

frame_row(src, src_img, {
  prefix = "forlorn_ritualant_activation",
  x = 1216, y = 526,
  count = 7,
  step_x = 43,
  w = 42, h = 75,
  dest = "content/sprites/enemies/forlorn_ritualant/activation",
  category = "actor_frame",
  kind = "activation",
  layer = "ActorLayer",
  tags = { "enemy", "forlorn_ritualant", "activation" },
  pad = 3,
  threshold = 10
})

frame_row(src, src_img, {
  prefix = "forlorn_ritualant_casting",
  x = 1210, y = 606,
  count = 4,
  step_x = 78,
  w = 75, h = 119,
  dest = "content/sprites/enemies/forlorn_ritualant/casting",
  category = "actor_frame",
  kind = "casting",
  layer = "ActorLayer",
  tags = { "enemy", "forlorn_ritualant", "casting", "ritual" },
  pad = 4,
  threshold = 10
})

frame_row(src, src_img, {
  prefix = "forlorn_ritualant_attack",
  x = 1212, y = 774,
  count = 5,
  step_x = 62,
  w = 62, h = 88,
  dest = "content/sprites/enemies/forlorn_ritualant/attack",
  category = "actor_frame",
  kind = "attack",
  layer = "ActorLayer",
  tags = { "enemy", "forlorn_ritualant", "attack" },
  pad = 4,
  threshold = 10
})

frame_row(src, src_img, {
  prefix = "forlorn_ritualant_death",
  x = 1210, y = 898,
  count = 4,
  step_x = 78,
  w = 78, h = 95,
  dest = "content/sprites/enemies/forlorn_ritualant/death",
  category = "actor_frame",
  kind = "death",
  layer = "ActorLayer",
  tags = { "enemy", "forlorn_ritualant", "death" },
  pad = 4,
  threshold = 10
})

auto_components(src, src_img, {
  prefix = "forlorn_ritualant_side_staff",
  x = 1120, y = 765, w = 78, h = 235,
  dest = "content/sprites/enemies/forlorn_ritualant/overlays/staff",
  category = "actor_overlay_frame",
  kind = "side_staff_overlay",
  layer = "ActorOverlayLayer",
  runtime_class = "animated_sprite_overlay_frame",
  collision = false,
  blocks_movement = false,
  anchor_mode = "bottom_center",
  tags = { "enemy", "forlorn_ritualant", "staff", "overlay" },
  min_area = 45,
  min_w = 8,
  min_h = 18,
  merge = 8,
  pad = 4,
  threshold = 10,
  review_required = false
})

-- -------------------------------------------------------------------------
-- WRITE MANIFEST
-- -------------------------------------------------------------------------

write_text(MANIFEST_PATH, encode_json(manifest, 0))

print("CUSTODIAN gothic compound slicing complete.")
print("Wrote " .. tostring(#manifest.assets) .. " assets.")
print("Manifest: " .. MANIFEST_PATH)
