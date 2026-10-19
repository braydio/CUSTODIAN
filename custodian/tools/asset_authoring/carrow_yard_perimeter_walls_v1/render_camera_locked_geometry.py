#!/usr/bin/env python3
"""Carrow Yard geometry-locked E-W, N-S and corner walls.

Renders fixed orthographic camera-facing PNGs and exports actual mesh construction proof.
The high-detail references are retained separately; rendered textures come from those user assets.
"""
from pathlib import Path
import os
import json, hashlib, math
from PIL import Image, ImageEnhance, ImageFilter
import numpy as np
import vtk
import trimesh

ROOT=Path(os.environ.get('CARROW_OUTPUT_DIR', str(Path(__file__).resolve().parent.parent / 'generated_geometry')))
ROOT.mkdir(parents=True, exist_ok=True)
TEX=ROOT/'textures'; TEX.mkdir(exist_ok=True)
REF=Image.open(os.environ.get('CARROW_SOURCE_PNG', str(Path(__file__).resolve().parent.parent / 'reference' / 'art_concept' / 'approved_detail_language_source.png'))).convert('RGBA')
# Seamless-ish material samples taken exclusively from the agreed Carrow source art.
SAMPLES={
 'stone_face':(185,430,730,643),
 'roof':(160,195,790,285),
 'stone':(1070,430,1300,580),
 'footing':(1030,660,1370,743),
 'parapet':(200,275,785,360),
 'pier':(815,300,912,670),
}
for n,box in SAMPLES.items():
 im=REF.crop(box).convert('RGB'); im.save(TEX/f'{n}.png')

TILE=32
WALK_CLEAR=4.0 # tiles
TOTAL_WIDTH=6.0 # 4 walking + 1 parapet thickness per side
HEIGHT=5.8 # tile units; includes footing and roof thickness
TOP=5.05
PARAPET_HEIGHT=1.05
PARAPET_T=.55
SEG_LENGTH=16.0
YAW_DEG=18.0; ELEV_DEG=60.0
# uniform orthographic output density, 45px/world tile.
PX_PER_TILE=45

vtk_tex={}
for name in SAMPLES:
 reader=vtk.vtkPNGReader();reader.SetFileName(str(TEX/f'{name}.png'));reader.Update()
 t=vtk.vtkTexture();t.SetInputConnection(reader.GetOutputPort());t.InterpolateOn(); t.RepeatOn()
 vtk_tex[name]=t

objects=[]
mesh_objects=[]


def color_actor(poly, rgb, spec=.08):
 mapper=vtk.vtkPolyDataMapper();mapper.SetInputConnection(poly.GetOutputPort())
 actor=vtk.vtkActor();actor.SetMapper(mapper)
 prop=actor.GetProperty();prop.SetColor(*rgb);prop.SetAmbient(.25);prop.SetDiffuse(.75);prop.SetSpecular(spec);prop.SetSpecularPower(10)
 objects.append(actor)
 return actor


def box(x0,y0,z0,x1,y1,z1, col=(.4,.39,.37), name='stone'):
 s=vtk.vtkCubeSource();s.SetBounds(x0,x1,y0,y1,z0,z1)
 a=color_actor(s,col)
 m=trimesh.creation.box(extents=(x1-x0,y1-y0,z1-z0));m.apply_translation(((x0+x1)/2,(y0+y1)/2,(z0+z1)/2))
 mesh_objects.append((name,m))
 return a


def quad(points, texture_name):
 # points [lowerleft,lower right,upper right,upper left] in texture coordinate ordering
 vertices=vtk.vtkPoints();
 for p in points:vertices.InsertNextPoint(*p)
 polys=vtk.vtkCellArray();quad=vtk.vtkQuad()
 for i in range(4):quad.GetPointIds().SetId(i,i)
 polys.InsertNextCell(quad)
 poly=vtk.vtkPolyData();poly.SetPoints(vertices);poly.SetPolys(polys)
 uvs=vtk.vtkFloatArray();uvs.SetNumberOfComponents(2);uvs.SetName('TextureCoordinates')
 for uv in [(0,0),(1,0),(1,1),(0,1)]:uvs.InsertNextTuple(uv)
 poly.GetPointData().SetTCoords(uvs)
 m=vtk.vtkPolyDataMapper();m.SetInputData(poly)
 actor=vtk.vtkActor();actor.SetMapper(m);actor.SetTexture(vtk_tex[texture_name]);actor.GetProperty().SetLighting(False)
 objects.append(actor)


def wall_rect(axis,a0,a1,side0,side1):
 # E-W axis x means runs east/west, offset transverse Y. N-S axis y means runs north/south, offset transverse X.
 # Geometry volumes connect flush at a0/a1; no duplicate end caps.
 if axis=='x':
  def xb(x,yn,yp,z0,z1,col,name):return box(x,yn,z0,x + (0 if False else 0),yp,z1,col,name) # not used
  box(a0,side0,0,a1,side1,TOP,(.40,.39,.37),'main_wall')
  box(a0,side0,TOP-.13,a1,side1,TOP,(.44,.43,.40),'top_slab')
  box(a0,side0-.03,0,a1,side0+.32,.5,(.42,.42,.4),'base_bevel')
  box(a0,side1-.32,0,a1,side1+.03,.5,(.42,.42,.4),'base_bevel')
  # each long side facade, deliberately use same reference-derived material for all 3 modules
  for side, eps in [(side0,-.006),(side1,.006)]:
   quad([(a0,side+eps,.55),(a1,side+eps,.55),(a1,side+eps,TOP-.1),(a0,side+eps,TOP-.1)],'stone_face')
  # visible top walkway: one clean single surface across full length
  quad([(a0,side0+.56,TOP+.011),(a1,side0+.56,TOP+.011),(a1,side1-.56,TOP+.011),(a0,side1-.56,TOP+.011)],'roof')
  # guard parapets along each long edge
  for v in [side0,side1-.55]:
   box(a0,v,TOP,a1,v+.55,TOP+PARAPET_HEIGHT,(.33,.34,.34),'parapet')
  # visual panel/railing top edge, leave joining ends flush
  for v in [side0,side1-.55]:
   box(a0,v-.04,TOP+PARAPET_HEIGHT-.13,a1,v+.59,TOP+PARAPET_HEIGHT+.025,(.55,.53,.49),'cap')
  # mounting ribs every 4 tiles but not at ends; pier shape protrudes sideward only
  for x in np.arange(a0+4,a1-.01,4):
   for v,sign in [(side0,-1),(side1,1)]:
    b0=v-.35 if sign<0 else v-.18;b1=v+.18 if sign<0 else v+.35
    box(x-.27,b0,.35,x+.27,b1,TOP+PARAPET_HEIGHT,(.50,.49,.45),'buttress')
  # group of characteristic windows simulated by darker patches 3d isolated shallow recesses
  for x in np.arange(a0+2,a1,3):
   for v,eps in [(side0,-.03),(side1,.03)]:
    sidev=v+eps
    quad([(x-.29,sidev,1.1),(x+.29,sidev,1.1),(x+.29,sidev,3.55),(x-.29,sidev,3.55)],'parapet')
 elif axis=='y':
  box(side0,a0,0,side1,a1,TOP,(.40,.39,.37),'main_wall')
  box(side0,a0,TOP-.13,side1,a1,TOP,(.44,.43,.40),'top_slab')
  box(side0-.03,a0,0,side0+.32,a1,.5,(.42,.42,.4),'base_bevel')
  box(side1-.32,a0,0,side1+.03,a1,.5,(.42,.42,.4),'base_bevel')
  for side,eps in [(side0,-.006),(side1,.006)]:
   quad([(side+eps,a0,.55),(side+eps,a1,.55),(side+eps,a1,TOP-.1),(side+eps,a0,TOP-.1)],'stone_face')
  quad([(side0+.56,a0,TOP+.011),(side1-.56,a0,TOP+.011),(side1-.56,a1,TOP+.011),(side0+.56,a1,TOP+.011)],'roof')
  for v in [side0,side1-.55]:
   box(v,a0,TOP,v+.55,a1,TOP+PARAPET_HEIGHT,(.33,.34,.34),'parapet')
   box(v-.04,a0,TOP+PARAPET_HEIGHT-.13,v+.59,a1,TOP+PARAPET_HEIGHT+.025,(.55,.53,.49),'cap')
  for y in np.arange(a0+4,a1-.01,4):
   for v,sign in [(side0,-1),(side1,1)]:
    b0=v-.35 if sign<0 else v-.18;b1=v+.18 if sign<0 else v+.35
    box(b0,y-.27,.35,b1,y+.27,TOP+PARAPET_HEIGHT,(.50,.49,.45),'buttress')
  for y in np.arange(a0+2,a1,3):
   for v,eps in [(side0,-.03),(side1,.03)]:
    sx=v+eps
    quad([(sx,y-.29,1.1),(sx,y+.29,1.1),(sx,y+.29,3.55),(sx,y-.29,3.55)],'parapet')


def corner():
 # Materially consistent L-shaped intersection from the same dimensions as straight runs.
 # Central 6x6 body + E-W arm x 6..16 and N-S arm y 6..16.
 box(0,0,0,6,6,TOP,(.40,.39,.37),'corner_core')
 box(0,0,TOP-.13,6,6,TOP,(.44,.43,.4),'corner_top')
 quad([(.55,.55,TOP+.011),(5.45,.55,TOP+.011),(5.45,5.45,TOP+.011),(.55,5.45,TOP+.011)],'roof')
 # perimeter parapets only at outer two faces of core, no cross-beam occluding walkable join
 for x0,y0,x1,y1 in [(0,0,6,.55),(0,0,.55,6)]:
  box(x0,y0,TOP,x1,y1,TOP+PARAPET_HEIGHT,(.36,.36,.34),'corner_parapet')
 box(0,0,TOP+PARAPET_HEIGHT-.1,6,.59,TOP+PARAPET_HEIGHT,(.53,.50,.46),'corner_cap')
 box(0,0,TOP+PARAPET_HEIGHT-.1,.59,6,TOP+PARAPET_HEIGHT,(.53,.50,.46),'corner_cap')
 # Textured corner faces at -Y and -X; external continuation is same as E-W/N-S geometry.
 quad([(0,-.006,.55),(6,-.006,.55),(6,-.006,TOP-.1),(0,-.006,TOP-.1)],'stone_face')
 quad([(-.006,0,.55),(-.006,6,.55),(-.006,6,TOP-.1),(-.006,0,TOP-.1)],'stone_face')
 wall_rect('x',6,16,0,6)
 wall_rect('y',6,16,0,6)
 # corner pier with raised observation node confined to no-walk inner corner area? visual only
 box(0,.0,TOP, .6,.6,TOP+1.35,(.53,.52,.48),'corner_pier')


def scene_for(kind):
 global objects,mesh_objects
 objects=[];mesh_objects=[]
 if kind=='wall_walkway_ew':wall_rect('x',0,SEG_LENGTH,0,TOTAL_WIDTH)
 elif kind=='wall_walkway_ns':wall_rect('y',0,SEG_LENGTH,0,TOTAL_WIDTH)
 else:corner()
 return objects,mesh_objects


def render(kind,width,height):
 objs, meshes=scene_for(kind)
 renderer=vtk.vtkRenderer();renderer.SetBackground(0,0,0);renderer.SetBackgroundAlpha(0.0)
 renderer.SetUseFXAA(False)
 renderer.AutomaticLightCreationOff()
 for obj in objs:renderer.AddActor(obj)
 light=vtk.vtkLight();light.SetLightTypeToSceneLight();light.SetPosition(10,-15,28);light.SetFocalPoint(3,3,3);light.SetIntensity(.85);renderer.AddLight(light)
 fill=vtk.vtkLight();fill.SetLightTypeToSceneLight();fill.SetPosition(-6,10,25);fill.SetIntensity(.4);renderer.AddLight(fill)
 w=vtk.vtkRenderWindow();w.SetOffScreenRendering(True);w.SetAlphaBitPlanes(1);w.SetMultiSamples(0)
 w.AddRenderer(renderer);w.SetSize(width*2,height*2)
 camera=vtk.vtkCamera()
 bbox={'wall_walkway_ew':(8,3,3),'wall_walkway_ns':(3,8,3),'wall_walkway_corner':(8,8,3)}[kind]
 yaw=math.radians(YAW_DEG);el=math.radians(ELEV_DEG)
 delta=np.array([math.sin(yaw)*math.cos(el), -math.cos(yaw)*math.cos(el), math.sin(el)])*60
 camera.SetPosition(*(np.array(bbox)+delta));camera.SetFocalPoint(*bbox);camera.SetViewUp(0,0,1)
 camera.ParallelProjectionOn()
 camera.SetParallelScale(height/(2.0*PX_PER_TILE)) # pixel-registered world scale
 renderer.SetActiveCamera(camera)
 renderer.ResetCameraClippingRange()
 w.Render()
 f=vtk.vtkWindowToImageFilter();f.SetInput(w);f.SetInputBufferTypeToRGBA();f.ReadFrontBufferOff();f.Update()
 writer=vtk.vtkPNGWriter();writer.SetInputConnection(f.GetOutputPort());writer.SetFileName(str(ROOT/f'{kind}_2x.png'));writer.Write()
 im=Image.open(ROOT/f'{kind}_2x.png').convert('RGBA').resize((width,height),Image.Resampling.LANCZOS)
 im.save(ROOT/f'{kind}.png')
 # export physical geometric construction proof as glb (not in-game runtime assets)
 scene=trimesh.Scene()
 for i,(name,mesh) in enumerate(meshes):
  if (mesh.extents>0).all():scene.add_geometry(mesh,node_name=f'{kind}_{name}_{i}')
 (ROOT/f'{kind}.glb').write_bytes(scene.export(file_type='glb'))
 (ROOT/f'{kind}_2x.png').unlink()
 print(kind,im.size,'faces',len(meshes),'alpha',im.getchannel('A').getextrema())

if __name__=='__main__':
 render('wall_walkway_ew',1024,768)
 render('wall_walkway_ns',768,1024)
 render('wall_walkway_corner',1024,1024)
 config={
  'schema':'custodian.carrow_wall_projection.v1',
  'camera':{'projection':'orthographic','yaw_deg':YAW_DEG,'elevation_deg':ELEV_DEG,'pixels_per_tile':PX_PER_TILE,'world_up':'Z','xy_to_game_grid':'X/Y 32px cells'},
  'geometry':{'tile_pixels':TILE,'wall_height_tiles':HEIGHT,'wall_top_height_tiles':TOP,'clear_walkway_tiles':WALK_CLEAR,'total_width_tiles':TOTAL_WIDTH,'parapet_height_tiles':PARAPET_HEIGHT,'segment_length_tiles':SEG_LENGTH,
    'endpoints':'straight open-section ends, flush; no terminating pillars; corner E-W and N-S arm interfaces are same cross-section'},
  'states':['wall_walkway_ew','wall_walkway_ns','wall_walkway_corner'],
  'notes':['Geometric projection proof, not final CUSTODIAN runtime acceptance','Self-shading permitted; detached ground shadows/background excluded','Textures sampled from prior accepted Carrow source art','Elevation traversal requires independent 2D semantic routing/occlusion implementation']
 }
 (ROOT/'projection_contract.json').write_text(json.dumps(config,indent=2))
