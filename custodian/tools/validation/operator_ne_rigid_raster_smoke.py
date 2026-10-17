#!/usr/bin/env python3
"""Real Aseprite regression for forward splat holes versus inverse nearest sampling."""
from pathlib import Path
import shutil
import subprocess
import tempfile
ROOT=Path(__file__).resolve().parents[3]

def main():
    binary=shutil.which('aseprite')
    if not binary:
        print('SKIP operator_ne_rigid_raster: Aseprite unavailable');return
    prelude='''local spr=Sprite(32,32,ColorMode.RGB)
local W,H=32,32
local function round(v)return math.floor(v+0.5)end
local function opaque(p)return app.pixelColor.rgbaA(p)>0 end
local place_rigid
'''
    check='''
local src=Image(spr.spec);src:clear()
local color=app.pixelColor.rgba(70,50,30,255)
for y=8,23 do for x=8,23 do src:putPixel(x,y,color) end end
local pivot={x=16,y=16}
local neutral=place_rigid(src,pivot,pivot,0)
for y=0,31 do for x=0,31 do assert(neutral:getPixel(x,y)==src:getPixel(x,y),'neutral changed') end end
for _,angle in ipairs({-37,-15,15,37}) do
 local image=place_rigid(src,pivot,pivot,angle)
 for y=0,31 do for x=0,31 do
  local p=image:getPixel(x,y);assert(p==0 or p==color,'palette or alpha invented')
  -- Strict interior disk must remain completely covered after rotation.
  if (x-16)^2+(y-16)^2<=25 then assert(p==color,'forward-splat interior hole') end
 end end
end
print('PASS inverse nearest rigid raster: neutral identity, filled interior, palette, binary alpha')
'''
    with tempfile.TemporaryDirectory() as td:
        path=Path(td)/'test.lua';path.write_text(prelude+(ROOT/'custodian/tools/operator/ne_walk_retarget/rigid_raster.lua').read_text()+check)
        r=subprocess.run([binary,'-b','--script',str(path)],capture_output=True,text=True,timeout=30)
        assert r.returncode==0 and 'PASS inverse nearest rigid raster' in r.stdout,r.stdout+r.stderr
        print(r.stdout.strip())
if __name__=='__main__':main()
