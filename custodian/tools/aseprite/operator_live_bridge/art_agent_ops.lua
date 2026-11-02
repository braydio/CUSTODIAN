-- Shared read-only Art Agent execution seam. Transport adapters own document
-- lifecycle and persistence; this module never opens, saves, or closes sprites.
local Ops = {}
Ops.REQUEST_SCHEMA = "custodian.operator_art_agent.request.v2"
Ops.RESPONSE_SCHEMA = "custodian.operator_art_agent.response.v2"
Ops.CAPABILITY_SCHEMA = "custodian.operator_art_agent.capability.v1"
Ops.WORKBENCH_SCHEMA = "custodian.operator_animation_workbench.v2"
Ops.READ_TYPES = {inspect=true,render=true,render_clean=true,render_editor=true,render_layer=true,render_silhouette=true}
Ops.MUTATION_TYPES = {paint_pixels=true,erase_pixels=true,stroke=true,copy_region=true,move_region=true,draft_shift_part=true,draft_copy_part=true,draft_replace_part=true,draft_mirror_part=true,discard_draft=true,bake_draft=true,clear_masked_region=true,recolor_plan=true}
local function fail(message) error(message, 0) end

local function authorized_output(path, capability)
  local root = capability.preview_root
  if type(path) ~= "string" then fail("render output outside authorized preview root") end
  if string.find(path, "\0", 1, true) then fail("render output path contains a NUL byte") end
  if string.find(path, "\\", 1, true) then fail("render output path contains a backslash") end
  if string.find(path, "..", 1, true) then fail("render output path contains a traversal segment") end
  if string.find(path, "/./", 1, true) then fail("render output path contains a redundant segment") end
  if string.sub(path, 1, 1) ~= "/" or string.sub(path, 1, #root + 1) ~= root .. "/" then fail("render output outside authorized preview root") end
end

local function find_layer(sprite, name)
  for _, layer in ipairs(sprite.layers) do if layer.name == name then return layer end end
  return nil
end

function Ops.validate(sprite, req, capability, manifest)
  if req.schema ~= Ops.REQUEST_SCHEMA then fail("unsupported Art Agent request schema") end
  if capability.schema ~= Ops.CAPABILITY_SCHEMA then fail("unsupported Art Agent capability schema") end
  if req.capability ~= capability.capability_path then fail("Art Agent capability self-reference mismatch") end
  if req.session_id ~= capability.session_id or req.nonce ~= capability.nonce then fail("Art Agent capability mismatch") end
  if req.manifest ~= capability.workbench_manifest or req.workbench ~= capability.workbench then fail("Art Agent capability path mismatch") end
  if manifest.schema ~= Ops.WORKBENCH_SCHEMA then fail("unsupported Workbench manifest schema") end
  if not manifest.context or manifest.context.fingerprint ~= capability.context_fingerprint then fail("WORKBENCH CONTEXT MISMATCH") end
  if sprite.filename ~= req.workbench then fail("active document does not match Art Agent workbench") end
  if sprite.width ~= manifest.canvas.width or sprite.height ~= manifest.canvas.height or #sprite.frames ~= manifest.timeline.document_frames then fail("Operator workbench document contract changed") end
end

local function integer(value, label)
  if type(value) ~= "number" or value ~= math.floor(value) then fail(label .. " must be an integer") end
  return value
end

local function channel(value, label)
  integer(value, label); if value < 0 or value > 255 then fail(label .. " must be in 0..255") end; return value
end

local function transparent() return app.pixelColor.rgba(0, 0, 0, 0) end
local function rgba_value(value)
  if type(value) ~= "table" and type(value) ~= "userdata" then fail("RGBA must contain four channels") end
  return app.pixelColor.rgba(channel(value[1], "red"), channel(value[2], "green"), channel(value[3], "blue"), channel(value[4] or 255, "alpha"))
end

local function binding_for_layer(manifest, sprite, name)
  if type(name) ~= "string" or string.sub(name, 1, 12) == "__REFERENCE_" then fail("reference layers cannot be mutated") end
  for _, binding in ipairs(manifest.layers or {}) do
    if binding.aseprite_layer_name == name then
      if binding.editable ~= true then fail("target layer is not editable") end
      return binding
    end
  end
  fail("target layer is not a Workbench editable binding: " .. tostring(name))
end

local function resolve_cel(sprite, binding, frame)
  frame = integer(frame, "frame")
  local contract = binding.workspace_contract
  local valid = false
  for _, slot in ipairs(contract.timeline_slots or {}) do if slot == frame then valid = true; break end end
  if not valid then fail("frame is outside binding timeline") end
  local layer = find_layer(sprite, binding.aseprite_layer_name)
  if not layer then fail("workbench layer missing: " .. binding.aseprite_layer_name) end
  local cel = layer:cel(frame)
  if not cel then fail("target cel missing") end
  if cel.position.x ~= contract.placement[1] or cel.position.y ~= contract.placement[2] then fail("ART AGENT V1 DOES NOT SUPPORT MANUALLY MOVED CELS") end
  if cel.image.width ~= contract.frame_size[1] or cel.image.height ~= contract.frame_size[2] then fail("cel image dimensions differ from binding contract") end
  return cel, {x=contract.placement[1], y=contract.placement[2], w=contract.frame_size[1], h=contract.frame_size[2]}
end

local function contains(rect, x, y) return x >= rect.x and y >= rect.y and x < rect.x + rect.w and y < rect.y + rect.h end
local function changed_bounds(points)
  if #points == 0 then return nil end
  local minx,maxx,miny,maxy=points[1][1],points[1][1],points[1][2],points[1][2]
  for _, point in ipairs(points) do minx=math.min(minx,point[1]);maxx=math.max(maxx,point[1]);miny=math.min(miny,point[2]);maxy=math.max(maxy,point[2]) end
  return {minx,miny,maxx-minx+1,maxy-miny+1}
end

local function mutate_pixels(sprite, manifest, operation, label, on_commit)
  local binding=binding_for_layer(manifest,sprite,operation.layer); local cel,rect=resolve_cel(sprite,binding,operation.frame); local image=cel.image:clone(); local changed={}; local seen={}
  for _, pixel in ipairs(operation.pixels or {}) do
    local x,y=integer(pixel.x,label .. " x"),integer(pixel.y,label .. " y")
    if not contains(rect,x,y) then fail(label .. " pixel outside legal binding rectangle") end
    local value=operation.type == "erase_pixels" and transparent() or rgba_value(pixel.rgba); local lx,ly=x-rect.x,y-rect.y; local key=tostring(x) .. ":" .. tostring(y)
    if image:getPixel(lx,ly) ~= value then image:drawPixel(lx,ly,value); if not seen[key] then table.insert(changed,{x,y});seen[key]=true end end
  end
  if #changed > 0 then app.transaction("Operator Art Agent: " .. label,function() cel.image=image end); if on_commit then on_commit() end end
  return {changed=#changed > 0,changed_pixels=#changed,changed_bbox=changed_bounds(changed)}
end

local function spans_pixels(spans)
  local result={}
  for _, span in ipairs(spans or {}) do
    local y,x0,x1=integer(span.y,"mask y"),integer(span.x0,"mask x0"),integer(span.x1,"mask x1")
    if x1 < x0 then fail("mask span is reversed") end
    for x=x0,x1 do table.insert(result,{x,y}) end
  end
  if #result == 0 then fail("semantic mask is empty") end
  return result
end

local function line_points(x0,y0,x1,y1)
  local points={}; local dx=math.abs(x1-x0); local sx=x0<x1 and 1 or -1; local dy=-math.abs(y1-y0); local sy=y0<y1 and 1 or -1; local err=dx+dy
  while true do table.insert(points,{x0,y0}); if x0==x1 and y0==y1 then break end; local e2=2*err; if e2>=dy then err=err+dy;x0=x0+sx end; if e2<=dx then err=err+dx;y0=y0+sy end end
  return points
end

local function copy_or_move(sprite, manifest, operation, moving, on_commit)
  local binding=binding_for_layer(manifest,sprite,operation.layer); local source_rect=operation.source_rect or operation.rect or {}; local destination=operation.destination or {source_rect[1]+(operation.dx or 0),source_rect[2]+(operation.dy or 0)}; local source_cel,rect=resolve_cel(sprite,binding,operation.source_frame or operation.frame); local destination_cel=resolve_cel(sprite,binding,operation.destination_frame or operation.frame); destination_cel=destination_cel
  local w,h=integer(source_rect[3],"source width"),integer(source_rect[4],"source height"); if not contains(rect,source_rect[1],source_rect[2]) or not contains(rect,source_rect[1]+w-1,source_rect[2]+h-1) or not contains(rect,destination[1],destination[2]) or not contains(rect,destination[1]+w-1,destination[2]+h-1) then fail("copy/move rectangle outside legal binding rectangle") end
  local image=destination_cel.image:clone(); local values={}; local changed={}; for y=0,h-1 do values[y+1]={}; for x=0,w-1 do values[y+1][x+1]=source_cel.image:getPixel(source_rect[1]-rect.x+x,source_rect[2]-rect.y+y) end end
  local clear=transparent()
  if moving then for y=0,h-1 do for x=0,w-1 do local lx,ly=source_rect[1]-rect.x+x,source_rect[2]-rect.y+y; if image:getPixel(lx,ly)~=clear then image:drawPixel(lx,ly,clear);table.insert(changed,{source_rect[1]+x,source_rect[2]+y}) end end end end
  for y=0,h-1 do for x=0,w-1 do local lx,ly=destination[1]-rect.x+x,destination[2]-rect.y+y; local value=values[y+1][x+1]; if image:getPixel(lx,ly)~=value then image:drawPixel(lx,ly,value);table.insert(changed,{destination[1]+x,destination[2]+y}) end end end
  if #changed>0 then app.transaction("Operator Art Agent: "..operation.type,function() destination_cel.image=image end);if on_commit then on_commit() end end
  return {changed=#changed>0,changed_pixels=#changed,changed_bbox=changed_bounds(changed)}
end

local function find_draft(sprite, name)
  if type(name) ~= "string" or string.sub(name,1,13) ~= "__ART_DRAFT__" then fail("invalid Art Agent draft id") end
  local layer=find_layer(sprite,name); if not layer then fail("Art Agent draft missing: " .. name) end; return layer
end

local function render(sprite, operation, capability)
  authorized_output(operation.output, capability)
  local visibility = {}
  local function internal(layer)
    return string.sub(layer.name, 1, 12) == "__REFERENCE_" or string.sub(layer.name, 1, 12) == "__ART_GUIDE_"
      or string.sub(layer.name, 1, 15) == "__ART_LANDMARK_" or layer.name == "__REVIEW_NOTES"
      or (operation.include_drafts == false and string.sub(layer.name, 1, 13) == "__ART_DRAFT__")
  end
  if operation.type == "render_layer" then
    if type(operation.layer) ~= "string" or find_layer(sprite, operation.layer) == nil then fail("render layer missing: " .. tostring(operation.layer)) end
    for _, layer in ipairs(sprite.layers) do visibility[layer] = layer.isVisible; layer.isVisible = layer.name == operation.layer end
  elseif operation.type == "render_clean" then
    for _, layer in ipairs(sprite.layers) do visibility[layer] = layer.isVisible; if internal(layer) then layer.isVisible = false end end
  end
  local strip = Image(sprite.width * #sprite.frames, sprite.height, ColorMode.RGB)
  for index = 1, #sprite.frames do strip:drawSprite(sprite, index, Point((index - 1) * sprite.width, 0)) end
  if operation.type == "render_silhouette" then
    for pixel in strip:pixels() do local value = pixel(); local alpha = app.pixelColor.rgbaA(value); if alpha > 0 then pixel(app.pixelColor.rgba(255, 255, 255, alpha)) end end
  end
  strip:saveAs(operation.output)
  for layer, value in pairs(visibility) do layer.isVisible = value end
  return {output=operation.output,frames=#sprite.frames,size={strip.width,strip.height}}
end

function Ops.execute(sprite, req, capability, manifest, options)
  if sprite == nil then fail("no active Aseprite document") end
  options = options or {}
  Ops.validate(sprite, req, capability, manifest)
  local operation = req.operation or {}
  if not Ops.READ_TYPES[operation.type] and not Ops.MUTATION_TYPES[operation.type] then fail("unsupported Art Agent operation: " .. tostring(operation.type)) end
  if sprite.width ~= manifest.canvas.width or sprite.height ~= manifest.canvas.height then fail("Operator workbench document contract changed") end
  local response = {schema="custodian.operator_art_agent.response.v2",request_id=req.request_id or "unknown",operation_key=req.operation_key or "unknown",ok=true,changed=false,operation=operation.type,warnings={}}
  if operation.type == "inspect" then
    response.canvas={width=sprite.width,height=sprite.height}; response.frames=#sprite.frames; response.layers={}; response.references={}
    for _, binding in ipairs(manifest.layers or {}) do local contract=binding.workspace_contract; table.insert(response.layers,{name=binding.aseprite_layer_name,editable=binding.editable,frames=contract.frames,legal_rect={contract.placement[1],contract.placement[2],contract.frame_size[1],contract.frame_size[2]}}) end
    for _, layer in ipairs(sprite.layers) do if string.sub(layer.name,1,12)=="__REFERENCE_" then table.insert(response.references,layer.name) end end
  else
    if Ops.MUTATION_TYPES[operation.type] then
      if operation.type == "paint_pixels" or operation.type == "erase_pixels" then
        local result=mutate_pixels(sprite,manifest,operation,operation.type,options.on_commit); response.frame=operation.frame; response.layer=operation.layer; response.changed=result.changed; response.changed_pixels=result.changed_pixels; response.changed_bbox=result.changed_bbox
      elseif operation.type == "stroke" then
        local points=operation.points or {}; if #points < 1 then fail("stroke requires points") end; local pixels={}; local brush=operation.brush or {}; local size=brush.size or 1; if brush.shape ~= "square" or (size ~= 1 and size ~= 2 and size ~= 3) then fail("V1 stroke brush must be square size 1, 2, or 3") end
        local start=-math.floor((size-1)/2); local function stamp(x,y) for oy=start,start+size-1 do for ox=start,start+size-1 do table.insert(pixels,{x=x+ox,y=y+oy,rgba=operation.rgba}) end end end
        if #points == 1 then stamp(points[1][1],points[1][2]) else for index=1,#points-1 do for _,point in ipairs(line_points(points[index][1],points[index][2],points[index+1][1],points[index+1][2])) do stamp(point[1],point[2]) end end end
        local result=mutate_pixels(sprite,manifest,{type="paint_pixels",layer=operation.layer,frame=operation.frame,pixels=pixels},"stroke",options.on_commit); response.frame=operation.frame; response.layer=operation.layer; response.changed=result.changed; response.changed_pixels=result.changed_pixels; response.changed_bbox=result.changed_bbox
      elseif operation.type == "copy_region" or operation.type == "move_region" then
        local result=copy_or_move(sprite,manifest,operation,operation.type=="move_region",options.on_commit); response.frame=operation.frame; response.layer=operation.layer; response.changed=result.changed; response.changed_pixels=result.changed_pixels; response.changed_bbox=result.changed_bbox
      elseif operation.type == "clear_masked_region" then
        local pixels={}; for _,point in ipairs(spans_pixels(operation.spans)) do table.insert(pixels,{x=point[1],y=point[2],rgba={0,0,0,0}}) end
        local result=mutate_pixels(sprite,manifest,{type="erase_pixels",layer=operation.layer,frame=operation.frame,pixels=pixels},"clear_masked_region",options.on_commit); response.frame=operation.frame; response.layer=operation.layer; response.changed=result.changed; response.changed_pixels=result.changed_pixels; response.changed_bbox=result.changed_bbox
      elseif operation.type == "recolor_plan" then
        local total=0; local all_changed={}; local prepared={}
        for _, target in ipairs(operation.targets or {}) do
          local binding=binding_for_layer(manifest,sprite,target.layer); local cel,rect=resolve_cel(sprite,binding,target.frame); local image=cel.image:clone(); local mapping={}
          for _, item in ipairs(target.mappings or {}) do if #item.source_rgb ~= 3 or #item.destination_rgb ~= 3 then fail("recolor mappings contain RGB only") end; mapping[string.format("%d:%d:%d",item.source_rgb[1],item.source_rgb[2],item.source_rgb[3])]=item.destination_rgb end
          local target_points=nil
          if target.spans ~= nil then
            target_points={}
            for _, span in ipairs(target.spans) do
              local y,x0,x1=integer(span.y,"target span y"),integer(span.x0,"target span x0"),integer(span.x1,"target span x1")
              if x1 < x0 then fail("target span is reversed") end
              for x=x0,x1 do table.insert(target_points,{x,y}) end
            end
            if #target_points == 0 then fail("semantic target mask is empty") end
            for _, point in ipairs(target_points) do
              if not contains(rect,point[1],point[2]) then fail("target span outside legal binding rectangle") end
            end
          end
          for y=0,rect.h-1 do for x=0,rect.w-1 do
            if target_points ~= nil then
              local found=false
              for _, tp in ipairs(target_points) do if tp[1]==x and tp[2]==y then found=true; break end end
              if not found then goto skip_pixel end
            end
            local value=image:getPixel(x,y); local alpha=app.pixelColor.rgbaA(value); local key=string.format("%d:%d:%d",app.pixelColor.rgbaR(value),app.pixelColor.rgbaG(value),app.pixelColor.rgbaB(value)); local replacement=mapping[key]
            if alpha>0 and replacement then local next_value=app.pixelColor.rgba(replacement[1],replacement[2],replacement[3],alpha); if next_value~=value then image:drawPixel(x,y,next_value); total=total+1; table.insert(all_changed,{rect.x+x,rect.y+y}) end end
            ::skip_pixel::
          end end
          table.insert(prepared,{cel=cel,image=image})
        end
        if total>0 then app.transaction("Operator Art Agent: recolor plan",function() for _, p in ipairs(prepared) do p.cel.image=p.image end end); if options.on_commit then options.on_commit() end; response.changed=total>0; response.changed_pixels=total; response.changed_bbox=changed_bounds(all_changed); response.plan_id=operation.plan_id end
      elseif operation.type == "draft_shift_part" or operation.type == "draft_copy_part" or operation.type == "draft_replace_part" or operation.type == "draft_mirror_part" then
        local binding=binding_for_layer(manifest,sprite,operation.layer); local source_cel,rect=resolve_cel(sprite,binding,operation.source_frame or operation.frame); local pixels=spans_pixels(operation.spans); local draft_id=operation.draft_id; if find_layer(sprite,draft_id) then fail("invalid or duplicate draft id") end
        local image=Image(sprite.width,sprite.height,ColorMode.RGB); local changed={}; local dx,dy=operation.dx or 0,operation.dy or 0
        for _, point in ipairs(pixels) do if not contains(rect,point[1],point[2]) then fail("mask outside legal binding rectangle") end; local tx=point[1]+dx; if operation.type=="draft_mirror_part" then tx=integer(operation.axis_x,"mirror axis")-(point[1]-integer(operation.axis_x,"mirror axis")) end; local ty=point[2]+dy; local value=source_cel.image:getPixel(point[1]-rect.x,point[2]-rect.y); if app.pixelColor.rgbaA(value)>0 then image:drawPixel(tx,ty,value);table.insert(changed,{tx,ty}) end end
        if #changed>0 then app.transaction("Operator Art Agent: semantic draft",function() local layer=sprite:newLayer();layer.name=draft_id;sprite:newCel(layer,operation.destination_frame or operation.frame,image,Point(0,0)) end);if options.on_commit then options.on_commit() end end
        response.changed=#changed>0;response.changed_pixels=#changed;response.changed_bbox=changed_bounds(changed);response.draft_id=draft_id
      elseif operation.type == "discard_draft" then
        local draft=find_draft(sprite,operation.draft_id); app.transaction("Operator Art Agent: discard draft",function() sprite:deleteLayer(draft) end);if options.on_commit then options.on_commit() end;response.changed=true;response.draft_id=operation.draft_id
      elseif operation.type == "bake_draft" then
        local draft=find_draft(sprite,operation.draft_id); local binding=binding_for_layer(manifest,sprite,operation.layer); local target,rect=resolve_cel(sprite,binding,operation.frame); local draft_cel=draft:cel(operation.frame); if not draft_cel then fail("draft has no cel for target frame") end; local image=target.image:clone(); local changed={}
        if operation.clear_spans ~= nil then
          local clear_points=spans_pixels(operation.clear_spans); for _, point in ipairs(clear_points) do local x,y=point[1],point[2]; if not contains(rect,x,y) then fail("clear span outside legal binding rectangle") end; local lx,ly=x-rect.x,y-rect.y; if image:getPixel(lx,ly)~=transparent() then image:drawPixel(lx,ly,transparent());table.insert(changed,{x,y}) end end
        end
        for y=rect.y,rect.y+rect.h-1 do for x=rect.x,rect.x+rect.w-1 do local value=draft_cel.image:getPixel(x-draft_cel.position.x,y-draft_cel.position.y); if app.pixelColor.rgbaA(value)>0 then if image:getPixel(x-rect.x,y-rect.y)~=value then image:drawPixel(x-rect.x,y-rect.y,value);table.insert(changed,{x,y}) end end end end
        app.transaction("Operator Art Agent: bake draft",function() target.image=image;sprite:deleteLayer(draft) end);if options.on_commit then options.on_commit() end;response.changed=true;response.changed_pixels=#changed;response.changed_bbox=changed_bounds(changed);response.draft_id=operation.draft_id;response.needs_gap_repair=operation.clear_spans ~= nil
      else
        fail("live Art Agent mutation is not yet implemented for " .. operation.type)
      end
    else
      local result=render(sprite,operation,capability); response.output=result.output; response.frames=result.frames; response.size=result.size
    end
  end
  return response
end

return Ops
