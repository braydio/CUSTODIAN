-- Semantic Operator animation workbench bridge. Canonical PNGs are never written here.
local function read_json(path)
  local f=assert(io.open(path,"rb")); local text=f:read("*a"); f:close()
  if not json or not json.decode then error("This Aseprite build lacks native JSON support") end
  return json.decode(text)
end
local function mkdir(path) app.fs.makeDirectory(path) end
local manifest_path=app.params["manifest"]
local mode=app.params["mode"]
if not manifest_path or not mode then error("mode and manifest script parameters are required") end
local p=read_json(manifest_path); local root=app.fs.filePath(manifest_path)
local wb=p.aseprite.path

local function copy_strip(sprite, layer, binding, strip_path)
  local source=app.open(strip_path); local source_layer=source.layers[1]
  local contract=binding.workspace_contract or binding
  local slots=contract.timeline_slots or binding.timeline_slots
  for i=1,contract.frames do
    local x=(i-1)*binding.frame_size[1]
    local img=Image(binding.frame_size[1],binding.frame_size[2],ColorMode.RGB)
    img:drawImage(source_layer:cel(1).image,Point(-x,0))
    local slot=slots and slots[i] or i
    sprite:newCel(layer,slot,img,Point(contract.placement[1],contract.placement[2]))
  end
  source:close()
end
if mode=="assemble" then
  local s=Sprite(p.canvas.width,p.canvas.height,ColorMode.RGB)
  while #s.frames<p.timeline.document_frames do s:newEmptyFrame() end
  for _,frame in ipairs(s.frames) do frame.duration=1/p.timeline.preview_fps end
  s.layers[1].name=p.layers[1].aseprite_layer_name
  copy_strip(s,s.layers[1],p.layers[1],p.layers[1].input_path)
  for i=2,#p.layers do local b=p.layers[i]; local layer=s:newLayer(); layer.name=b.aseprite_layer_name; copy_strip(s,layer,b,b.input_path) end
  for _,r in ipairs(p.references or {}) do local layer=s:newLayer(); layer.name=r.aseprite_layer_name; layer.isVisible=false; layer.isEditable=false; copy_strip(s,layer,r,r.input_path) end
  local baseline=s:newLayer(); baseline.name="__REFERENCE_SESSION_BASELINE"; baseline.isVisible=false; baseline.isEditable=false
  local ref={frames=p.timeline.document_frames,frame_size={p.canvas.width,p.canvas.height},placement={0,0},timeline_slots={}}
  for i=1,p.timeline.document_frames do ref.timeline_slots[i]=i end
  copy_strip(s,baseline,ref,app.fs.joinPath(root,"baseline","reference_composite.png"))
  local tag=s:newTag(1,p.timeline.document_frames); tag.name=p.identity.profile.."/"..p.identity.group.."/"..p.identity.action.."/"..p.identity.direction
  s:saveAs(wb); s:close()
elseif mode=="export" then
  local s=app.open(wb)
  if #s.frames~=p.timeline.document_frames or s.width~=p.canvas.width or s.height~=p.canvas.height then error("Operator animation contract changed outside the pending Workbench V2 migration") end
  local stamp=assert(p.export_stamp,"manifest export_stamp missing"); local raw=app.fs.joinPath(root,"exports",stamp,"raw"); mkdir(app.fs.joinPath(root,"exports")); mkdir(app.fs.joinPath(root,"exports",stamp)); mkdir(raw)
  for _,b in ipairs(p.layers) do
    local layer=nil; for _,candidate in ipairs(s.layers) do if candidate.name==b.aseprite_layer_name then layer=candidate end end
    if not layer then error("required editable layer missing: "..b.aseprite_layer_name) end
    local contract=b.workspace_contract; local strip=Image(p.canvas.width*contract.frames,p.canvas.height,ColorMode.RGB)
    for i=1,contract.frames do local slot=contract.timeline_slots[i]; local cel=layer:cel(slot); if cel then strip:drawImage(cel.image,Point((i-1)*p.canvas.width+cel.position.x,cel.position.y)) end end
    strip:saveAs(app.fs.joinPath(raw,b.binding_id..".png"))
  end
  s:close()
else error("unknown mode: "..mode) end
