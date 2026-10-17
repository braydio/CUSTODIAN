-- Five sparse source-phase poses only. Uses pinned core and inverse rigid raster.
local function run_calibration()
local cfg=json.decode(app.params.config)
local function save_json(name,value)
  local f=assert(io.open(cfg.output..'/'..name,'w'));f:write(json.encode(value));f:close()
end
local function cp(p) return {x=p.x,y=p.y} end
validate_rig()
local metrics={near=source_leg_metrics('near'),far=source_leg_metrics('far')}
local feet={near=foot_metrics('near'),far=foot_metrics('far')}
require_support_foot(feet.near);require_support_foot(feet.far)
local colors={};local seen={}
for _,entry in ipairs(DRAW_ORDER) do
  local layer=source_for_part(entry.name,entry.hidden)
  if layer then for p in full_canvas_image(layer):pixels() do
    local c=p()
    if opaque(c) and not seen[c] then
      seen[c]=true;table.insert(colors,{app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c),app.pixelColor.rgbaA(c)})
    end
  end end
end
local function solve(i,adjust)
  local planned=cfg.motion_plan.frames[i];local support=cfg.annotations.frames[i].support
  local preset={body_dx=0,body_dy=0,pelvis_rot=0,support=support,robe={near=0,far=0,center=0}}
  local solved={pelvis=cp(planned.pelvis),raw_pelvis=cp(planned.pelvis),pelvis_rot=0,derived_preset=preset}
  for _,s in ipairs({'near','far'}) do
    local l=planned.legs[s];local m=metrics[s];local ankle=cp(l.ankle)
    if s==support and adjust then ankle=add(ankle,adjust) end
    local knee,ankle,clamped=solve_two_bone_retarget(l.hip,ankle,m.thigh_len,m.shin_len,l.preferred_knee)
    solved[s]={hip=cp(l.hip),knee=knee,ankle=ankle,toe=add(ankle,rotate_vec(sub(m.toe,m.ankle),l.foot_delta)),
      thigh_delta=deg(angle_of(sub(knee,l.hip))-m.source_thigh_angle),
      shin_delta=deg(angle_of(sub(ankle,knee))-m.source_shin_angle),foot_delta=l.foot_delta,
      raw_foot_delta=l.raw_foot_delta,pitch_clamp_deviation_deg=l.pitch_clamp_deviation_deg,
      mapped_knee=cp(l.preferred_knee),mapped_ankle=cp(l.ankle),raw_ankle=cp(planned.raw_targets[s]),
      target_clamped=clamped,knee_fit_error=distance(knee,l.preferred_knee),
      desired_sole=s==support and add(l.ankle,rendered_rotated_foot_offset(feet[s],l.foot_delta)) or nil}
  end
  return solved
end
local report={schema='custodian.ne_crossover_poses.v1',frames={},accepted=false,timing_fps=false,source_colors=colors,
  secondary_motion='neutral for isolated leg calibration',
  occlusion_policy='Retain donor anatomical near foreground where contours overlap; screen lead reversal does not justify swapping whole limbs.'}
for _,i in ipairs(cfg.selected_frames) do
  local f=cfg.annotations.frames[i];local row={frame=i,support=f.support,failures={}}
  local solved=solve(i);local parts,missing=rasterize_reference_parts(solved)
  local check=verify_support_contact(solved.derived_preset,solved,parts)
  if not check.pass then
    local candidates={}
    for iy=-12,12 do for ix=-12,12 do table.insert(candidates,{x=ix*.25,y=iy*.25}) end end
    table.sort(candidates,function(a,b)
      local aa=a.x*a.x+a.y*a.y;local bb=b.x*b.x+b.y*b.y
      if aa==bb then if a.x==b.x then return a.y<b.y end return a.x<b.x end return aa<bb
    end)
    for _,adjust in ipairs(candidates) do
      local c=solve(i,adjust);local l=c[f.support]
      local n=c.near.ankle.x-c.far.ankle.x;local donor=f.landmarks.ankle_near.xy[1]-f.landmarks.ankle_far.xy[1]
      local planned=cfg.motion_plan.frames[i].legs[f.support]
      local k=sub(l.knee,l.hip);local a=sub(l.ankle,l.hip)
      local pk=sub(planned.knee,planned.hip);local pa=sub(planned.ankle,planned.hip)
      if not l.target_clamped and l.knee_fit_error<=cfg.annotations.controls.max_knee_fit_error_px and n*donor>0
        and (k.x*a.y-k.y*a.x)*(pk.x*pa.y-pk.y*pa.x)>0 then
        local ps,ms=rasterize_reference_parts(c);local cc=verify_support_contact(c.derived_preset,c,ps)
        if cc.pass then solved,parts,missing,check=c,ps,ms,cc;row.raster_correction=adjust;break end
      end
    end
  end
  row.contact=check;row.legs={near=solved.near,far=solved.far};row.missing_hidden=missing
  if not check.pass then table.insert(row.failures,'rendered_support_contact') end
  for _,s in ipairs({'near','far'}) do
    if solved[s].target_clamped then table.insert(row.failures,s..'_unreachable') end
    if solved[s].knee_fit_error>cfg.annotations.controls.max_knee_fit_error_px then table.insert(row.failures,s..'_knee_fit') end
  end
  local result=Image(128,128,ColorMode.RGB);result:clear()
  local owner={};local side_masks={near={},far={}};local distal_masks={near={},far={}}
  for _,entry in ipairs(DRAW_ORDER) do
    local img=parts[entry.name]
    if img then
      result:drawImage(img)
      for y=0,127 do for x=0,127 do
        if opaque(img:getPixel(x,y)) then
          local index=y*128+x;owner[index]=entry.name
          if entry.limb then side_masks[entry.limb][index]=true
            if entry.segment=='shin' or entry.segment=='foot' then distal_masks[entry.limb][index]=true end
          end
        end
      end end
    end
  end
  local audit={limb_overlap_pixels=0,distal_overlap_pixels=0,visible={near=0,far=0},covered_by_costume={near=0,far=0},coverage={}}
  local mask=Image(128,128,ColorMode.RGB);mask:clear()
  for index,name in pairs(owner) do
    local near=side_masks.near[index];local far=side_masks.far[index]
    if near and far then audit.limb_overlap_pixels=audit.limb_overlap_pixels+1 end
    if distal_masks.near[index] and distal_masks.far[index] then audit.distal_overlap_pixels=audit.distal_overlap_pixels+1 end
    for _,s in ipairs({'near','far'}) do
      if side_masks[s][index] then
        if name:find('_'..s..'_') or name:find('_'..s..'_completion') then audit.visible[s]=audit.visible[s]+1
        elseif not name:find('thigh') and not name:find('shin') and not name:find('foot') then
          audit.covered_by_costume[s]=audit.covered_by_costume[s]+1
          audit.coverage[name]=(audit.coverage[name] or 0)+1
        end
      end
    end
    local color=nil
    if near and far then color=app.pixelColor.rgba(255,255,255,255)
    elseif near then color=app.pixelColor.rgba(0,210,255,255)
    elseif far then color=app.pixelColor.rgba(255,0,190,255) end
    if color then mask:putPixel(index%128,math.floor(index/128),color) end
  end
  local foot=combined_transformed_foot(parts,f.support)
  local sole=bottom_contact(foot);local visible_sole=0;local sole_occluders={}
  if sole then
    for x=0,127 do
      local y=math.floor(sole.y+.5)
      local name=owner[y*128+x] or ''
      if opaque(foot:getPixel(x,y)) then
        if name:find('foot_'..f.support..'_') then visible_sole=visible_sole+1
        else sole_occluders[name]=(sole_occluders[name] or 0)+1 end
      end
    end
  end
  audit.support_visible_sole_pixels=visible_sole
  audit.support_sole_occluders=sole_occluders
  -- Contact may legitimately be hidden at a crossing. This is a visibility
  -- diagnostic, not permission to reverse anatomical depth just to expose it.
  row.occlusion=audit
  row.donor_ankle_dx=f.landmarks.ankle_near.xy[1]-f.landmarks.ankle_far.xy[1]
  row.operator_ankle_dx=solved.near.ankle.x-solved.far.ankle.x
  result:saveAs(cfg.output..'/pose_f'..string.format('%02d',i)..'.png')
  mask:saveAs(cfg.output..'/ownership_f'..string.format('%02d',i)..'.png')
  table.insert(report.frames,row)
end
save_json('calibration_report.json',report)
end
local ok,err=xpcall(run_calibration,debug.traceback);if not ok then error(err) end
