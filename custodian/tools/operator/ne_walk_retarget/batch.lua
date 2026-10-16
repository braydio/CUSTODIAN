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
local function solve_frame(i,adjust)
  local r=refs[i]; local f=cfg.annotations.frames[i]; local controls=cfg.annotations.controls
  local src_p=point('pelvis')
  local raw=add(src_p,{x=(r.pelvis.x-mean.pelvis.x)*scale_sum,y=(r.pelvis.y-mean.pelvis.y)*scale_sum})
  local pelvis={x=src_p.x+clamp(raw.x-src_p.x,-7,7),y=src_p.y+clamp(raw.y-src_p.y,-6,6)}
  local support=f.support
  local m=metrics[support]
  local support_delta={x=(r['ankle_'..support].x-mean['ankle_'..support].x)*scale_sum,
    y=(r['ankle_'..support].y-mean['ankle_'..support].y)*scale_sum}
  local target=add(add(m.ankle,support_delta),adjust or {x=0,y=0})
  local corrected,reach_corrected=support_reach_corrected_pelvis(pelvis,0,support,target)
  if math.abs(corrected.x-src_p.x)<=7 and math.abs(corrected.y-src_p.y)<=6 then pelvis=corrected end
  local solved={pelvis=pelvis,raw_pelvis=raw,pelvis_rot=0,reference_scale=scale_sum,
    pelvis_reach_corrected=reach_corrected,
    pelvis_clamped=math.abs(raw.x-src_p.x)>7 or math.abs(raw.y-src_p.y)>6,reference_frame=i}
  local preset={pelvis_rot=0,body_dx=pelvis.x-src_p.x,body_dy=pelvis.y-src_p.y,
    support=f.support,robe={near=0,far=0,center=0}}
  for _,side in ipairs({'near','far'}) do
    local m=metrics[side];local geo=feet[side]
    local hip=add(m.hip,sub(pelvis,src_p))
    local ref_ankle=r['ankle_'..side]; local ref_mean=mean['ankle_'..side]
    local donor_delta={x=(ref_ankle.x-ref_mean.x)*scale_sum,y=(ref_ankle.y-ref_mean.y)*scale_sum}
    local raw_ankle=add(m.ankle,donor_delta)
    local max_span=m.thigh_len+m.shin_len
    local desired=raw_ankle
    local swing_reduction=0
    if side~=f.support then
      desired=add(m.ankle,{x=donor_delta.x*controls.swing_reference_blend,y=donor_delta.y*controls.swing_reference_blend})
      swing_reduction=distance(raw_ankle,desired)
    end
    local foot_rot=reference_foot_rotation(r,side)
    local offset=rendered_rotated_foot_offset(geo,foot_rot)
    -- Targets travel along the donor's in-place phase path. Root/floor stay fixed.
    local sole=add(desired,offset)
    if side==f.support then desired=add(desired,adjust or {x=0,y=0}) end
    local v=sub(r['knee_'..side],r['hip_'..side]);local norm=length(v)
    assert(norm>1.5,'collapsed reference thigh')
    local preferred=add(hip,{x=v.x/norm*m.thigh_len,y=v.y/norm*m.thigh_len})
    local knee,ankle,was_clamped=solve_two_bone_retarget(hip,desired,m.thigh_len,m.shin_len,preferred)
    local leg={hip=hip,knee=knee,ankle=ankle,toe=add(ankle,rotate_vec(sub(m.toe,m.ankle),foot_rot)),
      mapped_ankle=desired,mapped_knee=preferred,raw_ankle=raw_ankle,
      thigh_delta=deg(angle_of(sub(knee,hip))-m.source_thigh_angle),
      shin_delta=deg(angle_of(sub(ankle,knee))-m.source_shin_angle),foot_delta=foot_rot,
      target_clamped=was_clamped,knee_fit_error=distance(knee,preferred),
      ankle_fit_error=distance(ankle,desired),swing_reduction_px=swing_reduction,
      desired_sole=side==f.support and sole or nil}
    solved[side]=leg
    preset.robe[side]=clamp(-leg.thigh_delta*controls.robe_response_gain,-12,12)
  end
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
      for dy=-3,3 do for dx=-3,3 do
        local candidate=solve_frame(i,{x=dx,y=dy})
        local cp,cm=rasterize_reference_parts(candidate)
        local cc=verify_support_contact(candidate.derived_preset,candidate,cp)
        local score=math.abs(cc.dx or 999)+math.abs(cc.dy or 999)
        if cc.pass and score<best and not candidate[f.support].target_clamped then
          solved,parts,missing,check,best=candidate,cp,cm,cc,score
          row.raster_correction={x=dx,y=dy}
        end
      end end
    end
    row.contact=check; row.pelvis=solved.pelvis;row.raw_pelvis=solved.raw_pelvis
    if not check.pass then table.insert(row.failures,'rendered_support_contact') end
    if solved.pelvis_clamped then table.insert(row.failures,'pelvis_clamped') end
    row.legs={};row.missing_hidden=missing
    for _,side in ipairs({'near','far'}) do
      local leg=solved[side];row.legs[side]=leg
      if leg.target_clamped then table.insert(row.failures,side..'_unreachable') end
      if leg.knee_fit_error>cfg.annotations.controls.max_knee_fit_error_px then table.insert(row.failures,side..'_knee_fit') end
      if leg.swing_reduction_px>3 then table.insert(row.warnings,side..'_swing_reduction') end
      local contact=bottom_contact(combined_transformed_foot(parts,side))
      leg.rendered_boot_contact=contact
      leg.knee_branch=(leg.knee.x-leg.hip.x)*(leg.ankle.y-leg.hip.y)-(leg.knee.y-leg.hip.y)*(leg.ankle.x-leg.hip.x)
    end
    local result=Image(128,128,ColorMode.RGB);result:clear()
    for _,entry in ipairs(DRAW_ORDER) do if parts[entry.name] then result:drawImage(parts[entry.name]) end end
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
