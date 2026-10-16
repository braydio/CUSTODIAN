-- Runs after the pinned V5.5 core; read-only export and optional disposable copy.
local cfg=json.decode(app.params.audit_config)
local function run_audit()
  assert(#spr.frames==1,'audit requires a single-frame saved rig')
  validate_rig()
  local report={layers={},pivots={},metrics={},feet={},source_file=spr.filename}
  for name,_ in pairs(PIVOT_SPEC) do report.pivots[name]=point(name) end
  for _,side in ipairs({'near','far'}) do
    report.metrics[side]=source_leg_metrics(side)
    local geo=foot_metrics(side)
    geo.image=nil
    report.feet[side]=geo
  end
  for _,layer in ipairs(spr.layers) do
    if layer.name:find('^__RIG_') then
      assert(not report.layers[layer.name],'duplicate layer '..layer.name)
      local image=full_canvas_image(layer)
      local filename=layer.name..'.png'
      image:saveAs(cfg.output..'/'..filename)
      report.layers[layer.name]={file=filename,count=count_opaque(image)}
    end
  end
  if cfg.candidate then
    -- Source authority stays provisional. Retain original version as a whole;
    -- never combine semantic layers or pivots from the incompatible newer rig.
    local remove={}
    for _,layer in ipairs(spr.layers) do
      if not layer.name:find('^__RIG_') then table.insert(remove,layer) end
    end
    for _,layer in ipairs(remove) do spr:deleteLayer(layer) end
    for _,layer in ipairs(spr.layers) do
      layer.isVisible=layer.name:find('^__RIG_PART_')~=nil
      layer.isEditable=false
    end
    local guide=spr:newLayer();guide.name='RECOVERY_QA_FAR_BOOT_AUTHORING_REQUIRED';guide.isVisible=false
    local image=Image(spr.spec);image:clear()
    draw_leg_skeleton(image,{hip=point('hip_far'),knee=point('knee_far'),ankle=point('ankle_far'),toe=point('toe_far')},C.far)
    draw_cross(image,point('ankle_far'),C.desired_sole,3)
    spr:newCel(guide,1,image,Point(0,0))
    spr:saveAs(cfg.candidate)
  end
  local f=assert(io.open(cfg.output..'/export.json','w'));f:write(json.encode(report));f:close()
end
local ok,err=xpcall(run_audit,debug.traceback);if not ok then error(err) end
