local function run_v6()
-- Appended in the same scope as the pinned V5.5 math/raster core.
-- Never calls V5.5's embedded Knight template or one-frame retarget function.
local cfg=json.decode(app.params.config)
local function save_json(path,value)
  local f=assert(io.open(path,'w')); f:write(json.encode(value)); f:close()
end
validate_rig()
local rig_state={}
for _,l in ipairs(spr.layers) do
  local c=l:cel(1)
  if c then rig_state[l.name]={image=c.image:clone(),position=Point(c.position.x,c.position.y)} end
end
local feet={near=foot_metrics('near'),far=foot_metrics('far')}
require_support_foot(feet.near); require_support_foot(feet.far)
local metrics={near=source_leg_metrics('near'),far=source_leg_metrics('far')}
local source_palette=Image(128,128,ColorMode.RGB);source_palette:clear()
local palette_colors={};local palette_index=0
for name,state in pairs(rig_state) do
  if name:find('^__RIG_PART_') or name:find('^__RIG_HIDDEN_') then
    for pixel in state.image:pixels() do
      local color=pixel()
      if opaque(color) and not palette_colors[color] then
        palette_colors[color]=true
        source_palette:putPixel(palette_index%128,math.floor(palette_index/128),color)
        palette_index=palette_index+1
      end
    end
  end
end
source_palette:saveAs(cfg.output..'/source_palette.png')
local mean={pelvis={x=0,y=0},ankle_near={x=0,y=0},ankle_far={x=0,y=0}}
local refs={}
for i,f in ipairs(cfg.annotations.frames) do
  refs[i]={}
  for n,v in pairs(f.landmarks) do refs[i][n]={x=v.xy[1],y=v.xy[2]} end
  for n,p in pairs(mean) do p.x=p.x+refs[i][n].x/15; p.y=p.y+refs[i][n].y/15 end
end
local scale_sum=0
for _,r in ipairs(refs) do scale_sum=scale_sum+reference_scale_to_custodian(r)/15 end
local function copy_point(p) return {x=p.x,y=p.y} end
local function solve_frame(i,adjust)
  local planned=cfg.motion_plan.frames[i]
  local preset={pelvis_rot=0,body_dx=planned.pelvis.x-point('pelvis').x,
    body_dy=planned.pelvis.y-point('pelvis').y,support=cfg.annotations.frames[i].support,
    robe={near=0,far=0,center=0}}
  local solved={pelvis=copy_point(planned.pelvis),raw_pelvis=copy_point(planned.raw_pelvis),pelvis_rot=0,
    reference_scale=cfg.motion_plan.reference_scale,pelvis_clamped=false,reference_frame=i}
  for _,side in ipairs({'near','far'}) do
    local m=metrics[side];local l=planned.legs[side]
    local target=copy_point(l.ankle)
    if side==preset.support then target=add(target,adjust or {x=0,y=0}) end
    local knee,ankle,clamped=solve_two_bone_retarget(l.hip,target,m.thigh_len,m.shin_len,l.knee)
    local offset=rendered_rotated_foot_offset(feet[side],l.foot_delta)
    solved[side]={hip=copy_point(l.hip),knee=knee,ankle=ankle,
      toe=add(ankle,rotate_vec(sub(m.toe,m.ankle),l.foot_delta)),
      mapped_knee=copy_point(l.preferred_knee),mapped_ankle=copy_point(target),raw_ankle=copy_point(planned.raw_targets[side]),
      thigh_delta=deg(angle_of(sub(knee,l.hip))-m.source_thigh_angle),
      shin_delta=deg(angle_of(sub(ankle,knee))-m.source_shin_angle),foot_delta=l.foot_delta,
      target_clamped=clamped,knee_fit_error=distance(knee,l.preferred_knee),
      ankle_fit_error=distance(ankle,target),swing_reduction_px=0,
      reference_filter_deviation_px=distance(planned.raw_targets[side],l.ankle),
      desired_sole=side==preset.support and add(l.ankle,offset) or nil}
    preset.robe[side]=20*cfg.annotations.controls.robe_response_gain*math.sin((i-1)*2*math.pi/15+(side=='far' and -math.pi/3 or math.pi/6))
  end
  preset.robe.center=10*cfg.annotations.controls.robe_response_gain*math.sin((i-1)*2*math.pi/15)
  solved.derived_preset=preset
  return solved
end
local original_transform_special=transform_special
transform_special=function(src,special,preset,solved)
  -- Independent upper-body control: zero by default until separately authored.
  local amount=cfg.annotations.controls.upper_body_counter_motion_degrees
  if amount~=0 and (special=='torso' or special=='hood' or special:find('arm')) then
    local a=amount*math.sin((solved.reference_frame-1)*2*math.pi/15)
    return place_rigid(src,point('pelvis'),solved.pelvis,a)
  end
  return original_transform_special(src,special,preset,solved)
end
local output=Sprite(128,128,ColorMode.RGB)
output.layers[1].name='OPERATOR_PREVIEW_ONLY_TIMING_UNKNOWN'
for i=2,15 do output:newEmptyFrame() end
local clean_layer=output.layers[1]
local qa_layer=output:newLayer();qa_layer.name='QA_TOGGLE_FOR_DEFICIENCIES';qa_layer.isVisible=false
local ref_layer=output:newLayer();ref_layer.name='DONOR_REFERENCE_ONLY';ref_layer.isVisible=false
local marker_layer=output:newLayer();marker_layer.name='EDITABLE_REFERENCE_MARKERS';marker_layer.isVisible=false
local report={rig_metrics=metrics,rig_feet={near={sole=feet.near.sole,ankle=feet.near.ankle},far={sole=feet.far.sole,ankle=feet.far.ankle}},schema='custodian.ne_walk_preview.v1',timing_fps=false,accepted=false,
  root={x=64,y=106},ground_y=107,reference_scale=scale_sum,frames={},
  controls=cfg.annotations.controls,provisional_support=true}
local strip=Image(1920,128,ColorMode.RGB);strip:clear()
local qa_strip=Image(1920,128,ColorMode.RGB);qa_strip:clear()
for i,f in ipairs(cfg.annotations.frames) do
  app.activeSprite=spr; app.activeFrame=spr.frames[1]
  local row={frame=i,support=f.support,failures={},warnings={}}
  local ok,err=pcall(function()
    local solved=solve_frame(i)
    local parts,missing=rasterize_reference_parts(solved)
    local check=verify_support_contact(solved.derived_preset,solved,parts)
    local best=math.abs(check.dx or 999)+math.abs(check.dy or 999)
    -- Keep V5.5's bounded correction: re-solve IK and rasterize, never slide art.
    if not check.pass then
      local candidates={}
      -- Quarter-pixel changes alter raster phase; integer shifts alone cannot
      -- change which pitched boot pixels own the lowest sole row.
      for iy=-12,12 do for ix=-12,12 do
        if ix~=0 or iy~=0 then table.insert(candidates,{x=ix*.25,y=iy*.25}) end
      end end
      table.sort(candidates,function(a,b)
        local aa=a.x*a.x+a.y*a.y;local bb=b.x*b.x+b.y*b.y
        if aa==bb then if a.x==b.x then return a.y<b.y end return a.x<b.x end
        return aa<bb
      end)
      for _,adjust in ipairs(candidates) do
        local candidate=solve_frame(i,adjust)
        local leg=candidate[f.support]
        local k=sub(leg.knee,leg.hip);local a=sub(leg.ankle,leg.hip)
        local donor_dx=refs[i].ankle_near.x-refs[i].ankle_far.x
        local candidate_dx=candidate.near.ankle.x-candidate.far.ankle.x
        local compatible=candidate_dx*donor_dx>0 and not leg.target_clamped and leg.knee_fit_error<=cfg.annotations.controls.max_knee_fit_error_px
          and (k.x*a.y-k.y*a.x)*cfg.motion_plan.branches[f.support]>0
        for _,neighbor in ipairs({((i-2)%15)+1,(i%15)+1}) do
          local planned=cfg.motion_plan.frames[neighbor].legs[f.support]
          for _,joint in ipairs({'hip','knee','ankle','toe'}) do
            if distance(leg[joint],planned[joint])>cfg.annotations.controls.max_joint_step_px then compatible=false end
          end
          for _,part in ipairs({'thigh','shin','foot'}) do
            if math.abs(normalize_deg(leg[part..'_delta']-planned[part..'_delta']))>cfg.annotations.controls.max_rotation_step_degrees then compatible=false end
          end
        end
        if compatible then
          local cp,cm=rasterize_reference_parts(candidate)
          local cc=verify_support_contact(candidate.derived_preset,candidate,cp)
          if cc.pass then
            solved,parts,missing,check=candidate,cp,cm,cc
            row.raster_correction=adjust
            break
          end
        end
      end
    end
    row.contact=check; row.pelvis=solved.pelvis;row.raw_pelvis=solved.raw_pelvis
    row.secondary={upper_body=cfg.annotations.controls.upper_body_counter_motion_degrees*math.sin((i-1)*2*math.pi/15),
      robe_far=solved.derived_preset.robe.far,robe_near=solved.derived_preset.robe.near,robe_center=solved.derived_preset.robe.center}
    if not check.pass then table.insert(row.failures,'rendered_support_contact') end
    if solved.pelvis_clamped then table.insert(row.failures,'pelvis_clamped') end
    row.legs={};row.missing_hidden=missing
    for _,side in ipairs({'near','far'}) do
      local leg=solved[side];row.legs[side]=leg
      leg.continuity_ankle_correction_px=cfg.motion_plan.frames[i].legs[side].continuity_ankle_correction_px
      leg.continuity_knee_correction_px=cfg.motion_plan.frames[i].legs[side].continuity_knee_correction_px
      if leg.target_clamped then table.insert(row.failures,side..'_unreachable') end
      if leg.knee_fit_error>cfg.annotations.controls.max_knee_fit_error_px then table.insert(row.failures,side..'_knee_fit') end
      if leg.reference_filter_deviation_px>3 then table.insert(row.warnings,side..'_reference_trajectory_filter_deviation') end
      local contact=bottom_contact(combined_transformed_foot(parts,side))
      leg.rendered_boot_contact=contact
      leg.knee_branch=(leg.knee.x-leg.hip.x)*(leg.ankle.y-leg.hip.y)-(leg.knee.y-leg.hip.y)*(leg.ankle.x-leg.hip.x)
    end
    local result=Image(128,128,ColorMode.RGB);result:clear()
    for _,entry in ipairs(DRAW_ORDER) do if parts[entry.name] then result:drawImage(parts[entry.name]) end end
    row.occlusion=audit_pose_occlusion(parts,DRAW_ORDER,f.support)
    local qa=make_reference_qa(refs[i],solved,solved.derived_preset,feet,check)
    app.activeSprite=output
    output:newCel(clean_layer,i,result,Point(0,0))
    output:newCel(qa_layer,i,qa,Point(0,0))
    strip:drawImage(result,Point((i-1)*128,0));qa_strip:drawImage(qa,Point((i-1)*128,0))
    result:saveAs(cfg.output..'/frame_'..string.format('%02d',i)..'.png')
  end)
  if not ok then row.error=tostring(err);table.insert(row.failures,'solve_or_raster_error') end
  app.activeSprite=output
  local donor=Image{fromFile=cfg.bundle..'/reference/frames/knight_ne_walk_f'..string.format('%02d',i)..'.png'}
  output:newCel(ref_layer,i,donor,Point(0,0))
  local markers=Image(128,128,ColorMode.RGB);markers:clear()
  for n,l in pairs(f.landmarks) do markers:putPixel(l.xy[1],l.xy[2],reference_marker_color(n)) end
  output:newCel(marker_layer,i,markers,Point(0,0))
  row.pass=#row.failures==0;report.frames[i]=row
end
-- Preserve source rig layers/pivots as hidden locked editable-document context.
for name,state in pairs(rig_state) do
  local layer=output:newLayer();layer.name=name;layer.isVisible=false;layer.isEditable=false
  output:newCel(layer,1,state.image,state.position)
end
app.activeSprite=output
-- Aseprite requires positive frame durations. Inherited 100ms is editor-only,
-- explicitly excluded from timing authority; no GIF is exported.
output:saveAs(cfg.output..'/operator_ne_walk_v6_PREVIEW_ONLY.aseprite')
strip:saveAs(cfg.output..'/operator_ne_walk_v6_15f.png')
qa_strip:saveAs(cfg.output..'/operator_ne_walk_v6_qa_15f.png')
save_json(cfg.output..'/aseprite_report.json',report)
print('V6_BATCH_REPORT '..cfg.output..'/aseprite_report.json')

end
local ok,err=xpcall(run_v6,debug.traceback);if not ok then error(err) end
