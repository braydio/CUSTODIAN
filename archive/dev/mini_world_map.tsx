<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.12.0" name="mini_world_map" tilewidth="16" tileheight="16" tilecount="5396" columns="71">
 <grid orientation="orthogonal" width="8" height="16"/>
 <image source="../sprites/additional-charsets/MiniWorldSprites/AllAssetsPreview.png" width="1136" height="304"/>
 <tile id="1076" type="ground"/>
 <wangsets>
  <wangset name="water" type="mixed" tile="-1">
   <wangcolor name="" color="#ff0000" tile="-1" probability="1"/>
   <wangcolor name="water_source" color="#00ff00" tile="-1" probability="1"/>
  </wangset>
  <wangset name="grass" type="corner" tile="1076">
   <wangcolor name="grass_main" color="#ff0000" tile="1076" probability="1"/>
   <wangtile tileid="1076" wangid="0,1,0,1,0,1,0,1"/>
  </wangset>
 </wangsets>
</tileset>
