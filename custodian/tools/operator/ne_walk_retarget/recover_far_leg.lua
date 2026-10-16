-- Provisional anatomy/ownership correction on the selected SINGLE_FRAME version.
-- Run in a headless disposable document; original file is never saved over.
local cfg=json.decode(app.params.recovery_config)
local function recover()
  validate_rig()
  local before_source=full_canvas_image(find_layer(SOURCE_NAME))
  local thigh=full_canvas_image(find_layer(PART_PREFIX..'thigh_far_visible'))
  local shin=full_canvas_image(find_layer(PART_PREFIX..'shin_far_visible'))
  local foot=full_canvas_image(find_layer(PART_PREFIX..'foot_far_visible'))
  assert(count_opaque(thigh)==91 and count_opaque(shin)==29 and count_opaque(foot)==0,'source semantic baseline drift')
  local moved={thigh_to_shin=0,shin_to_foot=0}
  -- Source-space traced regions: cuff/sole cluster y89..91; distal lower leg
  -- y84..88; proximal visible leg y78..83. This does not copy the newer rig.
  for y=0,127 do for x=0,127 do
    local p=shin:getPixel(x,y)
    if opaque(p) and y>=89 then
      foot:putPixel(x,y,p);shin:putPixel(x,y,0);moved.shin_to_foot=moved.shin_to_foot+1
    end
    p=thigh:getPixel(x,y)
    if opaque(p) and y>=84 then
      shin:putPixel(x,y,p);thigh:putPixel(x,y,0);moved.thigh_to_shin=moved.thigh_to_shin+1
    end
  end end
  local function replace(layer_name,img)
    local layer=find_layer(layer_name);assert(layer)
    local cel=layer:cel(1)
    if cel then spr:deleteCel(cel) end
    spr:newCel(layer,1,img,Point(0,0))
  end
  replace(PART_PREFIX..'thigh_far_visible',thigh)
  replace(PART_PREFIX..'shin_far_visible',shin)
  replace(PART_PREFIX..'foot_far_visible',foot)
  -- Hip remains occluded at its original source-relative location. Knee is the
  -- proximal/distal leg transition, ankle the cuff hinge, toe the rear boot tip.
  local proposed={hip_far={x=53,y=75},knee_far={x=52,y=83},ankle_far={x=50,y=88},toe_far={x=48,y=91}}
  local markers=full_canvas_image(find_layer(PIVOT_LAYER_NAME))
  for name,target in pairs(proposed) do
    local old=point(name)
    markers:putPixel(old.x,old.y,0)
  end
  for name,target in pairs(proposed) do markers:putPixel(target.x,target.y,PIVOT_SPEC[name].color) end
  replace(PIVOT_LAYER_NAME,markers)
  -- Four minimum joint-cover pixels, sampled from the selected source palette.
  -- In neutral every completion pixel is covered by its original visible owner.
  local hidden_shin=Image(spr.spec);hidden_shin:clear()
  local hidden_foot=Image(spr.spec);hidden_foot:clear()
  for _,p in ipairs({{51,83},{52,83}}) do
    assert(opaque(thigh:getPixel(p[1],p[2])),'shin completion must hide under original thigh')
    hidden_shin:putPixel(p[1],p[2],before_source:getPixel(p[1],p[2]))
  end
  for _,p in ipairs({{50,88},{51,88}}) do
    assert(opaque(shin:getPixel(p[1],p[2])),'foot completion must hide under original shin')
    hidden_foot:putPixel(p[1],p[2],before_source:getPixel(p[1],p[2]))
  end
  replace(HIDDEN_PREFIX..'shin_far_completion',hidden_shin)
  replace(HIDDEN_PREFIX..'foot_far_completion',hidden_foot)
  validate_rig()
  local feet={near=foot_metrics('near'),far=foot_metrics('far')}
  require_support_foot(feet.near);require_support_foot(feet.far)
  local neutral=Image(spr.spec);neutral:clear()
  for _,entry in ipairs(DRAW_ORDER) do
    local layer=source_for_part(entry.name,entry.hidden)
    if layer then neutral:drawImage(full_canvas_image(layer)) end
  end
  local mismatches=0
  for y=0,127 do for x=0,127 do
    if neutral:getPixel(x,y)~=before_source:getPixel(x,y) then mismatches=mismatches+1 end
  end end
  assert(mismatches==0,'neutral composite changed')
  neutral:saveAs(cfg.output..'/neutral_reconstructed.png')
  -- Calibrate support contact at source and perturbed integer ankle targets,
  -- re-solving exact canonical segment lengths for each boot rotation.
  local probes={}
  for _,side in ipairs({'near','far'}) do
    local m=source_leg_metrics(side)
    for _,rotation in ipairs({-15,0,15}) do
      local offset=rendered_rotated_foot_offset(feet[side],rotation)
      local sole=feet[side].sole
      local ankle=sub(sole,offset)
      local pelvis=point('pelvis')
      pelvis=support_reach_corrected_pelvis(pelvis,0,side,ankle)
      local hip=add(m.hip,sub(pelvis,point('pelvis')))
      local knee,actual,clamped=solve_two_bone_retarget(hip,ankle,m.thigh_len,m.shin_len,m.knee)
      local leg={hip=hip,knee=knee,ankle=actual,foot_delta=rotation,
        thigh_delta=deg(angle_of(sub(knee,hip))-m.source_thigh_angle),
        shin_delta=deg(angle_of(sub(actual,knee))-m.source_shin_angle),desired_sole=sole}
      local solved={pelvis=pelvis,near=leg,far=leg}
      local parts={}
      for _,entry in ipairs(DRAW_ORDER) do
        if entry.limb==side then
          local layer=source_for_part(entry.name,entry.hidden)
          if layer then parts[entry.name]=transform_limb_part(full_canvas_image(layer),side,entry.segment,solved) end
        end
      end
      local check=verify_support_contact({support=side},solved,parts)
      table.insert(probes,{side=side,rotation=rotation,contact=check,target_clamped=clamped,
        thigh_length_error=math.abs(distance(hip,knee)-m.thigh_len),
        shin_length_error=math.abs(distance(knee,actual)-m.shin_len)})
      assert(not clamped and check.pass,'support probe failed '..side..' '..rotation)
    end
  end
  -- Remove obsolete single-frame references; part/pivot editing remains local.
  local remove={}
  for _,layer in ipairs(spr.layers) do if not layer.name:find('^__RIG_') then table.insert(remove,layer) end end
  for _,layer in ipairs(remove) do spr:deleteLayer(layer) end
  for _,layer in ipairs(spr.layers) do
    layer.isVisible=layer.name:find('^__RIG_PART_')~=nil
    layer.isEditable=layer.name~=SOURCE_NAME and not layer.name:find('^__RIG_BINDING_')
  end
  spr:saveAs(cfg.output..'/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite')
  local report={schema='custodian.ne_anatomy_recovery.v1',accepted=false,proposed_pivots=proposed,
    moved_pixels=moved,hidden_shin_pixels=count_opaque(hidden_shin),hidden_boot_pixels=count_opaque(hidden_foot),
    neutral_mismatches=mismatches,contact_probes=probes,
    metrics={near=source_leg_metrics('near'),far=source_leg_metrics('far')},
    feet={near={valid=feet.near.valid,sole=feet.near.sole},far={valid=feet.far.valid,sole=feet.far.sole}}}
  local f=assert(io.open(cfg.output..'/recovery_report.json','w'));f:write(json.encode(report));f:close()
end
local ok,err=xpcall(recover,debug.traceback);if not ok then error(err) end
