-- Read-only ownership diagnostics; compositing order is never changed here.
local function audit_pose_occlusion(parts,order,support)
  local owner={};local masks={near={},far={}}
  for _,entry in ipairs(order) do
    local img=parts[entry.name]
    if img then for y=0,127 do for x=0,127 do
      if opaque(img:getPixel(x,y)) then
        local k=y*128+x;owner[k]=entry.name
        if entry.limb then masks[entry.limb][k]=true end
      end
    end end end
  end
  local r={limb_overlap_pixels=0,visible={near=0,far=0},covered_by_costume={near=0,far=0},support_visible_sole_pixels=0,support_sole_occluders={}}
  for k,name in pairs(owner) do
    if masks.near[k] and masks.far[k] then r.limb_overlap_pixels=r.limb_overlap_pixels+1 end
    for _,s in ipairs({'near','far'}) do
      if masks[s][k] then
        if name:find('_'..s..'_') then r.visible[s]=r.visible[s]+1
        elseif not name:find('thigh') and not name:find('shin') and not name:find('foot') then r.covered_by_costume[s]=r.covered_by_costume[s]+1 end
      end
    end
  end
  local foot=combined_transformed_foot(parts,support);local sole=bottom_contact(foot)
  if sole then for x=0,127 do
    local y=math.floor(sole.y+.5);local name=owner[y*128+x] or 'none'
    if opaque(foot:getPixel(x,y)) then
      if name:find('foot_'..support..'_') then r.support_visible_sole_pixels=r.support_visible_sole_pixels+1
      else r.support_sole_occluders[name]=(r.support_sole_occluders[name] or 0)+1 end
    end
  end end
  return r
end
