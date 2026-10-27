#!/usr/bin/env python3
"""No-Blender mesh inspection. Renders eight views via VTK/EGL, as *geometry proof*.
These are not Blender skin/animation proof and are not canonical 128px art.
"""
import argparse, pathlib, json, math
import numpy as np
from PIL import Image,ImageDraw
import trimesh
import vtk
from vtk.util.numpy_support import numpy_to_vtk, vtk_to_numpy

def vtk_poly(m):
    pts=vtk.vtkPoints();pts.SetData(numpy_to_vtk(np.ascontiguousarray(m.vertices,dtype=np.float32),deep=True))
    cell=vtk.vtkCellArray();idx=np.column_stack([np.full(len(m.faces),3,dtype=np.int64),np.asarray(m.faces,dtype=np.int64)]).ravel()
    cell.SetCells(len(m.faces),numpy_to_vtk(idx,deep=True,array_type=vtk.VTK_ID_TYPE))
    pd=vtk.vtkPolyData();pd.SetPoints(pts);pd.SetPolys(cell);return pd

def proof(glb,out):
    src=trimesh.load(glb,force='scene');out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
    meshes=src.dump(concatenate=False)
    print('loaded meshes',len(meshes))
    scene=vtk.vtkRenderer();scene.SetBackground(.07,.085,.11)
    for m in meshes:
        if not len(m.faces):continue
        mesh=vtk_poly(m)
        normals=vtk.vtkPolyDataNormals();normals.SetInputData(mesh);normals.ComputeCellNormalsOn();normals.ComputePointNormalsOn();normals.AutoOrientNormalsOff();normals.Update()
        mapr=vtk.vtkPolyDataMapper();mapr.SetInputConnection(normals.GetOutputPort())
        actor=vtk.vtkActor();actor.SetMapper(mapr)
        color=m.visual.vertex_colors[:,:3].mean(axis=0)/255 if hasattr(m.visual,'vertex_colors') else [0.3]*3
        actor.GetProperty().SetColor(*[float(c) for c in color]);actor.GetProperty().SetAmbient(.23);actor.GetProperty().SetDiffuse(.68);actor.GetProperty().SetSpecular(.18);actor.GetProperty().SetSpecularPower(20)
        scene.AddActor(actor)
    lights=[((-4,-4,6),1.0),((3,1,3),.50),((2,5,6),.7)]
    for pos,power in lights:
        li=vtk.vtkLight();li.SetPosition(*pos);li.SetFocalPoint(0,0,1);li.SetIntensity(power);scene.AddLight(li)
    cam=vtk.vtkCamera();cam.ParallelProjectionOn();cam.SetParallelScale(1.45)
    cam.SetFocalPoint(0,0,1.05);scene.SetActiveCamera(cam)
    rw=vtk.vtkRenderWindow();rw.SetOffScreenRendering(1);rw.AddRenderer(scene);rw.SetSize(450,450)
    rw.SetAlphaBitPlanes(1);rw.SetMultiSamples(4)
    frames=[];angles={'N':180,'NE':135,'E':90,'SE':45,'S':0,'SW':-45,'W':-90,'NW':-135}
    for name,deg in angles.items():
        a=math.radians(deg);e=math.radians(30)
        cam.SetPosition(5*math.sin(a)*math.cos(e),-5*math.cos(a)*math.cos(e),1.05+5*math.sin(e))
        cam.SetViewUp(0,0,1);cam.SetClippingRange(.01,30)
        rw.Render()
        w2i=vtk.vtkWindowToImageFilter();w2i.SetInput(rw);w2i.SetInputBufferTypeToRGB();w2i.ReadFrontBufferOff();w2i.Update()
        data=w2i.GetOutput();dims=data.GetDimensions()
        arr=vtk_to_numpy(data.GetPointData().GetScalars()).reshape(dims[1],dims[0],-1)[::-1,:,:3]
        im=Image.fromarray(arr,'RGB');im.save(out/f'{name}.png');frames.append((name,im))
    sheet=Image.new('RGB',(450*4,478*2),(18,23,29));draw=ImageDraw.Draw(sheet)
    for i,(name,im) in enumerate(frames):
        x=i%4*450;y=i//4*478
        sheet.paste(im,(x,y+28));draw.text((x+12,y+6),name,fill=(238,206,162))
    sheet.save(out/'eight_direction_geometry_sheet.png');print(str(out/'eight_direction_geometry_sheet.png'))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('glb');p.add_argument('out');a=p.parse_args();proof(a.glb,a.out)
