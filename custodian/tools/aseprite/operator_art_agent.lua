-- Deterministic pixel-authoring bridge for disposable Operator workbenches.
local function read_json(path)
  local file=assert(io.open(path,"rb")); local text=file:read("*a"); file:close()
  if not json or not json.decode then error("Aseprite native JSON support required") end
  return json.decode(text)
end

local function write_json(path,value)
  local file=assert(io.open(path,"wb"))
  if not json or not json.encode then error("Aseprite native JSON support required") end
  file:write(json.encode(value)); file:close()
end

local request_path=assert(app.params["request"],"request script parameter required")
local response_path=assert(app.params["response"],"response script parameter required")
local request_id="unknown"

local function execute()
  local req=read_json(request_path); request_id=req.request_id or request_id
  if req.schema~="custodian.operator_art_agent.request.v1" then error("unsupported Art Agent request schema") end
  local manifest=read_json(req.manifest)
  local operation=assert(req.operation,"operation required")
  local sprite=assert(app.open(req.workbench),"failed to open Operator workbench")

  local function close_and_error(message)
    sprite:close(); error(message)
  end

  if sprite.width~=manifest.canvas.width or sprite.height~=manifest.canvas.height or #sprite.frames~=manifest.timeline.document_frames then
    close_and_error("Operator workbench document contract changed")
  end

  local function find_layer(name)
    for _,layer in ipairs(sprite.layers) do if layer.name==name then return layer end end
    return nil
  end

  local function binding_for_layer(name)
    if type(name)~="string" or string.sub(name,1,12)=="__REFERENCE_" then
      close_and_error("reference layers cannot be mutated")
    end
    for _,binding in ipairs(manifest.layers) do
      if binding.aseprite_layer_name==name then
        if binding.editable~=true then close_and_error("target layer is not editable") end
        return binding
      end
    end
    close_and_error("target layer is not a Workbench editable binding: "..tostring(name))
  end

  local function legal_rect(binding)
    local contract=binding.workspace_contract
    return {x=contract.placement[1],y=contract.placement[2],w=contract.frame_size[1],h=contract.frame_size[2]}
  end

  local function contains(rect,x,y)
    return x>=rect.x and y>=rect.y and x<rect.x+rect.w and y<rect.y+rect.h
  end

  local function validate_rect(rect,x,y,w,h,label)
    if type(x)~="number" or type(y)~="number" or type(w)~="number" or type(h)~="number" or w<1 or h<1 then
      close_and_error(label.." is invalid")
    end
    if not contains(rect,x,y) or not contains(rect,x+w-1,y+h-1) then
      close_and_error(label.." outside legal binding rectangle")
    end
  end

  local function resolve_cel(binding,frame_number)
    if type(frame_number)~="number" then close_and_error("frame must be an integer") end
    local contract=binding.workspace_contract; local valid=false
    for _,slot in ipairs(contract.timeline_slots) do if slot==frame_number then valid=true; break end end
    if not valid then close_and_error("frame is outside binding timeline") end
    local layer=find_layer(binding.aseprite_layer_name)
    if not layer then close_and_error("workbench layer missing: "..binding.aseprite_layer_name) end
    local cel=layer:cel(frame_number)
    if not cel then close_and_error("target cel missing") end
    if cel.position.x~=contract.placement[1] or cel.position.y~=contract.placement[2] then
      close_and_error("ART AGENT V1 DOES NOT SUPPORT MANUALLY MOVED CELS")
    end
    return layer,cel
  end

  local function transparent()
    return app.pixelColor.rgba(0,0,0,0)
  end

  local function rgba_value(value)
    if value==nil or #value<3 then close_and_error("RGBA must contain at least RGB") end
    return app.pixelColor.rgba(value[1],value[2],value[3],value[4] or 255)
  end

  local function changed_bounds(points)
    if #points==0 then return nil end
    local min_x,max_x,min_y,max_y=points[1][1],points[1][1],points[1][2],points[1][2]
    for _,point in ipairs(points) do
      min_x=math.min(min_x,point[1]); max_x=math.max(max_x,point[1])
      min_y=math.min(min_y,point[2]); max_y=math.max(max_y,point[2])
    end
    return {min_x,min_y,max_x-min_x+1,max_y-min_y+1}
  end

  local function mutate_pixels(binding,frame,pixels,label)
    local _,cel=resolve_cel(binding,frame); local rect=legal_rect(binding); local image=cel.image:clone()
    local changed={}; local seen={}
    for _,pixel in ipairs(pixels) do
      local x,y=pixel.x,pixel.y
      if type(x)~="number" or type(y)~="number" or not contains(rect,x,y) then
        close_and_error(label.." pixel outside legal binding rectangle")
      end
      local value=pixel.value
      local local_x,local_y=x-rect.x,y-rect.y; local key=tostring(x)..":"..tostring(y)
      if image:getPixel(local_x,local_y)~=value then
        image:drawPixel(local_x,local_y,value)
        if not seen[key] then table.insert(changed,{x,y}); seen[key]=true end
      end
    end
    app.transaction("Operator Art Agent: "..label,function() cel.image=image end)
    return {changed_pixels=#changed,changed_bbox=changed_bounds(changed)}
  end

  local function line_points(x0,y0,x1,y1)
    local points={}; local dx=math.abs(x1-x0); local sx=x0<x1 and 1 or -1
    local dy=-math.abs(y1-y0); local sy=y0<y1 and 1 or -1; local err=dx+dy
    while true do
      table.insert(points,{x0,y0}); if x0==x1 and y0==y1 then break end
      local e2=2*err
      if e2>=dy then err=err+dy; x0=x0+sx end
      if e2<=dx then err=err+dx; y0=y0+sy end
    end
    return points
  end

  local response={schema="custodian.operator_art_agent.response.v1",request_id=request_id,ok=true,operation=operation.type,warnings={}}
  if operation.type=="inspect" then
    response.canvas={width=sprite.width,height=sprite.height}; response.frames=#sprite.frames; response.layers={}; response.references={}
    for _,binding in ipairs(manifest.layers) do
      local contract=binding.workspace_contract
      table.insert(response.layers,{name=binding.aseprite_layer_name,editable=binding.editable,frames=contract.frames,legal_rect={contract.placement[1],contract.placement[2],contract.frame_size[1],contract.frame_size[2]}})
    end
    for _,layer in ipairs(sprite.layers) do if string.sub(layer.name,1,12)=="__REFERENCE_" then table.insert(response.references,layer.name) end end
  elseif operation.type=="render" then
    local output=assert(operation.output,"render output required")
    local strip=Image(sprite.width*#sprite.frames,sprite.height,ColorMode.RGB)
    for index=1,#sprite.frames do strip:drawSprite(sprite,index,Point((index-1)*sprite.width,0)) end
    strip:saveAs(output); response.output=output; response.frames=#sprite.frames; response.size={strip.width,strip.height}
  elseif operation.type=="paint_pixels" or operation.type=="erase_pixels" then
    local binding=binding_for_layer(operation.layer); local pixels={}
    for _,pixel in ipairs(operation.pixels or {}) do
      table.insert(pixels,{x=pixel.x,y=pixel.y,value=operation.type=="erase_pixels" and transparent() or rgba_value(pixel.rgba)})
    end
    local result=mutate_pixels(binding,operation.frame,pixels,operation.type)
    response.frame=operation.frame; response.layer=operation.layer; response.changed_pixels=result.changed_pixels; response.changed_bbox=result.changed_bbox
  elseif operation.type=="stroke" then
    local binding=binding_for_layer(operation.layer); local brush=operation.brush or {}; local size=brush.size or 1
    if brush.shape~="square" or (size~=1 and size~=2 and size~=3) then close_and_error("V1 stroke brush must be square size 1, 2, or 3") end
    local input=operation.points or {}; if #input<1 then close_and_error("stroke requires points") end
    local color=rgba_value(operation.rgba); local pixels={}; local start=-math.floor((size-1)/2)
    local function stamp(x,y)
      for oy=start,start+size-1 do for ox=start,start+size-1 do table.insert(pixels,{x=x+ox,y=y+oy,value=color}) end end
    end
    if #input==1 then stamp(input[1][1],input[1][2]) else
      for i=1,#input-1 do for _,point in ipairs(line_points(input[i][1],input[i][2],input[i+1][1],input[i+1][2])) do stamp(point[1],point[2]) end end
    end
    local result=mutate_pixels(binding,operation.frame,pixels,"stroke")
    response.frame=operation.frame; response.layer=operation.layer; response.changed_pixels=result.changed_pixels; response.changed_bbox=result.changed_bbox
  elseif operation.type=="copy_region" then
    local binding=binding_for_layer(operation.layer); local rect=legal_rect(binding); local source_rect=operation.source_rect or {}; local destination=operation.destination or {}
    validate_rect(rect,source_rect[1],source_rect[2],source_rect[3],source_rect[4],"copy source rectangle")
    validate_rect(rect,destination[1],destination[2],source_rect[3],source_rect[4],"copy destination rectangle")
    local _,source_cel=resolve_cel(binding,operation.source_frame); local _,destination_cel=resolve_cel(binding,operation.destination_frame)
    local source_image=source_cel.image; local image=destination_cel.image:clone(); local values={}; local changed={}
    for y=0,source_rect[4]-1 do values[y+1]={}; for x=0,source_rect[3]-1 do values[y+1][x+1]=source_image:getPixel(source_rect[1]-rect.x+x,source_rect[2]-rect.y+y) end end
    for y=0,source_rect[4]-1 do for x=0,source_rect[3]-1 do local lx,ly=destination[1]-rect.x+x,destination[2]-rect.y+y; local value=values[y+1][x+1]; if image:getPixel(lx,ly)~=value then image:drawPixel(lx,ly,value); table.insert(changed,{destination[1]+x,destination[2]+y}) end end end
    app.transaction("Operator Art Agent: copy region",function() destination_cel.image=image end)
    response.layer=operation.layer; response.changed_pixels=#changed; response.changed_bbox=changed_bounds(changed)
  elseif operation.type=="move_region" then
    local binding=binding_for_layer(operation.layer); local rect=legal_rect(binding); local source_rect=operation.rect or {}; local dx,dy=operation.dx,operation.dy
    validate_rect(rect,source_rect[1],source_rect[2],source_rect[3],source_rect[4],"move source rectangle")
    validate_rect(rect,source_rect[1]+dx,source_rect[2]+dy,source_rect[3],source_rect[4],"move destination rectangle")
    local _,cel=resolve_cel(binding,operation.frame); local original=cel.image; local image=original:clone(); local values={}; local changed={}; local changed_keys={}
    local function mark(x,y) local key=tostring(x)..":"..tostring(y); if not changed_keys[key] then table.insert(changed,{x,y}); changed_keys[key]=true end end
    for y=0,source_rect[4]-1 do values[y+1]={}; for x=0,source_rect[3]-1 do values[y+1][x+1]=original:getPixel(source_rect[1]-rect.x+x,source_rect[2]-rect.y+y) end end
    local clear=transparent()
    for y=0,source_rect[4]-1 do for x=0,source_rect[3]-1 do local lx,ly=source_rect[1]-rect.x+x,source_rect[2]-rect.y+y; if image:getPixel(lx,ly)~=clear then image:drawPixel(lx,ly,clear); mark(source_rect[1]+x,source_rect[2]+y) end end end
    for y=0,source_rect[4]-1 do for x=0,source_rect[3]-1 do local doc_x,doc_y=source_rect[1]+dx+x,source_rect[2]+dy+y; local lx,ly=doc_x-rect.x,doc_y-rect.y; local value=values[y+1][x+1]; if image:getPixel(lx,ly)~=value then image:drawPixel(lx,ly,value); mark(doc_x,doc_y) end end end
    app.transaction("Operator Art Agent: move region",function() cel.image=image end)
    response.frame=operation.frame; response.layer=operation.layer; response.changed_pixels=#changed; response.changed_bbox=changed_bounds(changed)
  else close_and_error("unsupported Art Agent V1 operation: "..tostring(operation.type)) end

  if operation.type~="inspect" and operation.type~="render" then sprite:saveAs(req.workbench) end
  sprite:close(); return response
end

local ok,result=xpcall(execute,debug.traceback)
if ok then write_json(response_path,result) else
  write_json(response_path,{schema="custodian.operator_art_agent.response.v1",request_id=request_id,ok=false,error=tostring(result),warnings={}})
  error(result)
end
