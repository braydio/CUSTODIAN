-- Inverse nearest-neighbor rigid sampling. Source pixels remain immutable;
-- sampling destination centers avoids holes from forward-rounded splats.
place_rigid=function(src,src_pivot,dst_pivot,rotation_deg)
  local out=Image(spr.spec);out:clear()
  local r=math.rad(rotation_deg);local c=math.cos(r);local s=math.sin(r)
  for y=0,H-1 do for x=0,W-1 do
    local dx=x-dst_pivot.x;local dy=y-dst_pivot.y
    local sx=round(src_pivot.x+dx*c+dy*s)
    local sy=round(src_pivot.y-dx*s+dy*c)
    if sx>=0 and sx<W and sy>=0 and sy<H then
      local p=src:getPixel(sx,sy)
      if opaque(p) then out:putPixel(x,y,p) end
    end
  end end
  return out
end
