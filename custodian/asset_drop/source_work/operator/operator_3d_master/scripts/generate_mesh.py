#!/usr/bin/env python3
"""Deterministic editable volumetric Operator *blockout* (not approved canonical art).

Standalone host Python requires numpy, trimesh, Pillow. Generated GLB contains
named independent manifold parts for Blender rig parenting and art editing.
"""
import argparse, hashlib, json, math, pathlib, sys
import numpy as np
import trimesh

P=pathlib.Path

def color_mesh(mesh, rgba):
    mesh.visual.vertex_colors = np.repeat(np.asarray([rgba], dtype=np.uint8), len(mesh.vertices), axis=0)
    return mesh

def ellipsoid(center, radii, detail=2):
    m=trimesh.creation.icosphere(subdivisions=detail, radius=1)
    m.apply_scale(radii)
    m.apply_translation(center)
    return m

def link(a,b,r1,r2=None,sections=12):
    a=np.asarray(a,dtype=float);b=np.asarray(b,dtype=float)
    v=b-a;length=float(np.linalg.norm(v));r2=r1 if r2 is None else r2
    mesh=trimesh.creation.cone(radius=r1,height=length,sections=sections) if r2==0 else None
    if mesh is None:
        # Cylinder with independently controllable ends for tapered armor segments
        mesh=loft_circle(a,b,r1,r2,sections)
        return mesh
    T=trimesh.geometry.align_vectors([0,0,1],v)
    mesh.apply_transform(T);mesh.apply_translation(a)
    return mesh

def loft_circle(a,b,r1,r2,n=12):
    a=np.asarray(a,dtype=float);b=np.asarray(b,dtype=float);v=b-a;v/=np.linalg.norm(v)
    u=np.cross(v,[0,1,0]);u=u/np.linalg.norm(u) if np.linalg.norm(u)>1e-6 else np.array([1.,0,0])
    w=np.cross(v,u)
    vs=[a+rr*(math.cos(t*2*math.pi/n)*u+math.sin(t*2*math.pi/n)*w) for z,rr in [(a,r1),(b,r2)] for t in range(n)]
    vs.extend([a,b]);faces=[]
    for i in range(n):
        j=(i+1)%n;faces.extend([(i,j,n+j),(i,n+j,n+i),(2*n,j,i),(2*n+1,n+i,n+j)])
    return trimesh.Trimesh(vertices=vs,faces=faces,process=True)

def loft_rings(rings, sides=20, center_offset=0):
    """Ring (z, width_x, depth_y, center_y): closed tapered solid."""
    vs=[];n=sides
    for z,wx,dy,cy in rings:
        for i in range(n):
            t=i*2*math.pi/n
            vs.append([wx*math.cos(t),cy+dy*math.sin(t),z])
    faces=[]
    for k in range(len(rings)-1):
        for i in range(n):
            a=k*n+i;b=k*n+(i+1)%n;c=(k+1)*n+(i+1)%n;d=(k+1)*n+i
            faces += [(a,b,c),(a,c,d)]
    a0=len(vs);vs.append([0,rings[0][3],rings[0][0]]);a1=len(vs);vs.append([0,rings[-1][3],rings[-1][0]])
    for i in range(n):faces.extend([(a0,(i+1)%n,i),(a1,(len(rings)-1)*n+i,(len(rings)-1)*n+(i+1)%n)])
    return trimesh.Trimesh(vertices=vs,faces=faces,process=True)

def slab_polygon(points, thickness=.04):
    # 3D ribbon shell over a plane with front & rear + closed side walls
    points=np.asarray(points,dtype=float)
    q=len(points);vs=np.vstack([points+np.array([0,thickness/2,0]),points-np.array([0,thickness/2,0])]);faces=[]
    # convex-ish fan works for our armor panel path
    for i in range(1,q-1): faces.extend([(0,i,i+1),(q,q+i+1,q+i)])
    for i in range(q):j=(i+1)%q;faces.extend([(i,j,q+j),(i,q+j,q+i)])
    return trimesh.Trimesh(vertices=vs,faces=faces,process=True)

def cape_mesh(p):
    """A single continuous bent 3D cape sheet with physically continuous folds."""
    hem=float(p['cape_hem_z']);span=float(p['cloak_spread']);verts=[];faces=[]
    width_segments=36;vertical_segments=12
    for j in range(vertical_segments+1):
        frac=j/vertical_segments
        z=1.56*(1-frac)+hem*frac
        width=.345*(1-frac)+span*frac
        for i in range(width_segments+1):
            th=i/width_segments*math.pi
            ridge=(math.sin(6*th+frac*.9)**2-.50)*.073*(frac**1.25)
            xx=width*math.cos(th)
            yy=.14+(0.21+frac*.16)*math.sin(th)+frac*.055+ridge
            zz=z+.02*math.sin(7*th)*frac
            verts.append([xx,yy,zz])
    for j in range(vertical_segments):
        for i in range(width_segments):
            a=j*(width_segments+1)+i;b=a+1;c=a+width_segments+1;d=c+1
            faces.extend([(a,c,d),(a,d,b)])
    return trimesh.Trimesh(vertices=verts,faces=faces,process=False)

def hood_shell():
    """Actual fabric shell behind and beside the mask, with an open face aperture."""
    vertices=[];faces=[];num=40
    # The forward 105-degree wedge is left open for the approved visor region.
    # Angle 0 points side-right; pi/2 points toward the back.
    angles=np.linspace(-.18, math.pi+.18,num+1)
    rings=[(1.57,.240,.203,.038),(1.68,.247,.215,.030),(1.79,.224,.216,.055),
           (1.90,.201,.209,.088),(1.983,.136,.152,.114),(2.002,.045,.055,.133)]
    for z,w,d,cy in rings:
        for t in angles:
            vertices.append([w*math.cos(t),cy+d*math.sin(t),z])
    for j in range(len(rings)-1):
        for i in range(num):
            a=j*(num+1)+i;b=a+1;c=a+num+1;d=c+1
            faces += [(a,b,d),(a,d,c)]
    return trimesh.Trimesh(vertices=vertices,faces=faces,process=False)

def main():
    ar=argparse.ArgumentParser();ar.add_argument('--config',required=True);ar.add_argument('--out',required=True);a=ar.parse_args()
    config_path=P(a.config);p=json.loads(config_path.read_text());dst=P(a.out);dst.parent.mkdir(parents=True,exist_ok=True)
    scene=trimesh.Scene(); items=[];palette=p['palette']
    def add(name,mesh,mat,group):
        assert name not in {x['name'] for x in items},name
        hs=float(p.get('head_group_scale',1.0))
        if group=='Head' and hs!=1.0:
            c=np.array([0,-.008,1.70]);mesh.apply_translation(-c);mesh.apply_scale(hs);mesh.apply_translation(c)
        mesh=color_mesh(mesh,palette[mat]);mesh.metadata.update({'rig_group':group,'material_class':mat})
        scene.add_geometry(mesh,geom_name=name,node_name=name)
        items.append({'name':name,'rig_group':group,'material_class':mat,'vertices':len(mesh.vertices),'faces':len(mesh.faces)})
    def legacy():
        # Stable root: feet on Z=0; forward (character front) points towards -Y.
        add('Pelvis__underplate',loft_rings([(0.92,.22,.16,0.01),(1.03,.26,.17,0.01),(1.13,.24,.18,0.01)]),'armor_dark','Hips')
        add('Torso__core',loft_rings([(1.00,.235,.15,.012),(1.22,.29,.22,0.0),(1.47,.32,.225,0.0),(1.59,.275,.19,.012)]),'armor','Spine')
        add('Torso__inner_gorget',loft_rings([(1.50,.20,.155,0),(1.65,.19,.16,0)]),'undercloth','Spine')
        add('Torso__breastplate_left',slab_polygon([[.008,-.222,1.19],[.265,-.11,1.20],[.29,-.10,1.47],[.052,-.245,1.52],[.01,-.263,1.38]],.045),'armor_light','Spine')
        add('Torso__breastplate_right',slab_polygon([[-.008,-.222,1.19],[-.265,-.11,1.20],[-.29,-.10,1.47],[-.052,-.245,1.52],[-.01,-.263,1.38]],.045),'armor','Spine')
        for j in range(3):
            z=1.10+j*.068
            add(f'Torso__abdomen_lamella_{j}',loft_rings([(z,.255-j*.008,.173,0),(z+.028,.264-j*.009,.177,-.008)]),'armor_dark' if j%2 else 'armor','Hips')
        add('Torso__center_bronze',slab_polygon([[-.024,-.253,1.17],[.024,-.253,1.17],[.033,-.267,1.53],[-.033,-.267,1.53]],.016),'bronze_dim','Spine')
        # Leather belt with segmented bronze clasp and suspended tabard
        add('Hips__belt',loft_rings([(1.02,.279,.183,-.004),(1.09,.283,.185,-.006)]),'undercloth','Hips')
        add('Hips__buckle',trimesh.creation.box(extents=[.13,.053,.12],transform=trimesh.transformations.translation_matrix([0,-.210,1.062])),'bronze','Hips')
        for k in [-1,1]:
            side='L' if k>0 else 'R';sgn=k
            # Legs are distinct, complete volumes, joined anatomically at knees.
            x=sgn*.165
            add(f'Thigh_{side}__fabric',link([x,0,1.02],[sgn*.195,-.012,.61],.136,.107,14),'undercloth',f'Thigh.{side}')
            add(f'Thigh_{side}__outer_plate',ellipsoid([sgn*.201,-.028,.81],[.137,.135,.238],2),'armor',f'Thigh.{side}')
            add(f'Thigh_{side}__ridge',link([sgn*.22,-.16,.94],[sgn*.213,-.14,.70],.028,.024,8),'bronze_dim',f'Thigh.{side}')
            add(f'Knee_{side}__cup',ellipsoid([sgn*.19,-.058,.58],[.137,.153,.124],2),'armor_light',f'Shin.{side}')
            add(f'Shin_{side}__core',link([sgn*.19,0,.58],[sgn*.19,-.008,.20],.106,.08,12),'undercloth',f'Shin.{side}')
            add(f'Shin_{side}__greave',ellipsoid([sgn*.196,-.053,.40],[.119,.116,.217],2),'armor',f'Shin.{side}')
            add(f'Shin_{side}__vertical_flute',link([sgn*.192,-.172,.52],[sgn*.193,-.149,.30],.017,.024,8),'bronze_dim',f'Shin.{side}')
            add(f'Boot_{side}__ankle',ellipsoid([sgn*.19,0,.185],[.112,.125,.125],2),'armor_dark',f'Foot.{side}')
            add(f'Boot_{side}__sole',trimesh.creation.box(extents=[.255,.37,.072],transform=trimesh.transformations.translation_matrix([sgn*.19,-.090,.058])),'armor_dark',f'Foot.{side}')
            add(f'Boot_{side}__toe',ellipsoid([sgn*.19,-.20,.115],[.128,.193,.087],2),'armor',f'Foot.{side}')
            add(f'Boot_{side}__toe_cap',ellipsoid([sgn*.19,-.287,.122],[.115,.08,.064],1),'armor_light',f'Foot.{side}')
            # Shoulder, bicep, elbow, forearm, fingers are continuous 3D volumes.
            add(f'Shoulder_{side}__joint',ellipsoid([sgn*.36,0,1.51],[.17,.15,.156],2),'undercloth',f'UpperArm.{side}')
            add(f'Shoulder_{side}__pauldron',ellipsoid([sgn*.425,-.015,1.558],[.209,.216,.157],2),'armor_light',f'UpperArm.{side}')
            add(f'Shoulder_{side}__raised_rim',ellipsoid([sgn*.425,-.003,1.618],[.210,.218,.073],2),'armor',f'UpperArm.{side}')
            add(f'UpperArm_{side}__mail',link([sgn*.39,0,1.49],[sgn*.47,-.01,1.19],.124,.093,14),'undercloth',f'UpperArm.{side}')
            add(f'UpperArm_{side}__plate',ellipsoid([sgn*.43,-.05,1.37],[.13,.13,.19],2),'armor',f'UpperArm.{side}')
            add(f'Elbow_{side}__pivot',ellipsoid([sgn*.475,-.011,1.20],[.115,.117,.10],2),'armor_dark',f'Forearm.{side}')
            add(f'Forearm_{side}__sleeve',link([sgn*.475,-.02,1.19],[sgn*.48,-.06,.94],.10,.084,12),'undercloth',f'Forearm.{side}')
            add(f'Forearm_{side}__vambrace',ellipsoid([sgn*.49,-.083,1.09],[.116,.112,.157],2),'armor_light',f'Forearm.{side}')
            add(f'Hand_{side}__gauntlet',ellipsoid([sgn*.48,-.075,.90],[.096,.097,.13],2),'armor',f'Forearm.{side}')
            for finger in range(3):
                add(f'Hand_{side}__finger_{finger}',ellipsoid([sgn*.48+(.045-finger*.045),-.122,.824],[.028,.043,.075],1),'armor_dark',f'Forearm.{side}')
        # Helmet and intact hood physically wrap around a closed head volume.
        head_scale=float(p['helmet_scale'])
        add('Head__skull_helmet',ellipsoid([0,-.008,1.775],[.178*head_scale,.173*head_scale,.203*head_scale],3),'armor','Head')
        add('Head__hood_outer',hood_shell(),'cloak','Head')
        add('Head__cowl_lower',loft_rings([(1.575,.245,.195,.043),(1.68,.24,.21,.026),(1.765,.195,.18,.055)]),'cloak','Head')
        add('Head__cheek_guard',slab_polygon([[-.153,-.166,1.70],[.153,-.166,1.70],[.165,-.132,1.81],[.105,-.20,1.87],[-.105,-.20,1.87],[-.165,-.132,1.81]],.066),'armor_dark','Head')
        add('Head__brow',slab_polygon([[-.155,-.19,1.825],[.155,-.19,1.825],[.18,-.165,1.889],[-.18,-.165,1.889]],.04),'armor','Head')
        if p.get('visor_chevron',False):
            add('Head__visor_amber',slab_polygon([[-.115,-.215,1.855],[.115,-.215,1.855],[.0,-.222,1.745]],.012),'visor','Head')
        else:
            add('Head__visor_amber',slab_polygon([[-.108,-.213,1.823],[.108,-.213,1.823],[.115,-.212,1.848],[-.115,-.212,1.848]],.009),'visor','Head')
        add('Head__nose_crest',slab_polygon([[-.020,-.235,1.785],[.020,-.235,1.785],[.021,-.235,1.86],[-.021,-.235,1.86]],.01),'bronze_dim','Head')
        add('Head__chin_plate',slab_polygon([[-.09,-.209,1.707],[.09,-.209,1.707],[.135,-.178,1.766],[-.135,-.178,1.766]],.025),'armor','Head')
        if p.get('gold_trim',False):
            def ring(name,c,rx,ry,r,group,rot=False):
                m=trimesh.creation.torus(1.0,r/max(rx,ry),48,8);m.apply_scale([rx,ry,max(rx,ry)])
                if rot:m.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[1,0,0]))
                m.apply_translation(c);add(name,m,'bronze',group)
            ring('Trim__belt_top',[0,0.0,1.10],.285,.19,.011,'Hips');ring('Trim__belt_bottom',[0,0.0,1.015],.28,.185,.011,'Hips')
            ring('Trim__gorget',[0,0.0,1.60],.20,.165,.010,'Spine')
            for k in (-1,1):
                sd='L' if k>0 else 'R'
                ring(f'Trim__pauldron_{sd}',[k*.425,-.015,1.50],.195,.20,.011,f'UpperArm.{sd}')
                ring(f'Trim__arm_cuff_{sd}',[k*.45,-.012,1.28],.125,.12,.009,f'UpperArm.{sd}')
                ring(f'Trim__wrist_{sd}',[k*.485,-.07,.99],.105,.10,.009,f'Forearm.{sd}')
                ring(f'Trim__thigh_{sd}',[k*.20,-.02,.62],.145,.14,.009,f'Thigh.{sd}')
                ring(f'Trim__shin_top_{sd}',[k*.19,-.03,.47],.125,.125,.009,f'Shin.{sd}')
                ring(f'Trim__boot_cuff_{sd}',[k*.19,-.01,.275],.115,.12,.009,f'Foot.{sd}')
        if p.get('hood_trim',False):
            m=trimesh.creation.torus(1.0,.014/.16,48,8);m.apply_scale([.135,.16,.16])
            m.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[1,0,0]));m.apply_translation([0,-.17,1.80]);add('Trim__hood_opening',m,'bronze','Head')
        # Solid cloth surfaces, not articulated shreds cut out of a static sprite.
        add('Cloak__one_piece_folded_fabric',cape_mesh(p),'cloak','Cloak')
        add('Cloak__upper_mantle',loft_rings([(1.42,.41,.19,.076),(1.55,.43,.26,.105),(1.65,.27,.21,.042)]),'cloak_fold','Cloak')
        add('Tabard__front',slab_polygon([[-.185,-.205,1.045],[.185,-.205,1.045],[.235,-.24,.38],[.098,-.27,.31],[-.10,-.27,.32],[-.24,-.24,.39]],.027),'cloak','Hips')
        for x in [-.166,.166]:
            add(f'Tabard__edge_ornament_{"L" if x>0 else "R"}',link([x,-.24,.95],[x*1.25,-.284,.39],.016,.013,8),'bronze_dim','Hips')
        # Side waist straps and clasps
        for s in [-1,1]:
            add(f'Hips__side_fauld_{"L" if s>0 else "R"}',slab_polygon([[s*.255,-.05,1.015],[s*.33,-.015,1.0],[s*.4,-.002,.78],[s*.29,-.07,.75]],.035),'armor','Hips')
    if int(p.get('model_version',1))>=6:
        import generate_mesh_v6;generate_mesh_v6.build(add,p)
    else:
        legacy()
    bs=p.get('body_scale',[1,1,1])
    if bs!=[1,1,1]:scene.apply_transform(np.diag([bs[0],bs[1],bs[2],1.0]))
    if p.get('export_y_up',False):
        # glTF is Y-up/-Z-forward; authoring space here is Z-up/-Y-forward. (x,y,z)->(x,z,-y)
        # so Blender's importer returns the character upright with the front still on -Y.
        scene.apply_transform(np.array([[1,0,0,0],[0,0,1,0],[0,-1,0,0],[0,0,0,1]],dtype=float))
    glb=scene.export(file_type='glb')
    dst.write_bytes(glb)
    h=hashlib.sha256(glb).hexdigest()
    manifest={'schema':'custodian.operator_3d_master.blockout.v1','status':p['status'],'source_config_sha256':hashlib.sha256(config_path.read_bytes()).hexdigest(),'asset_sha256':h,'source_reference_sha256':p['source_contract']['design_sha256'],'approved_as_canonical':False,'mesh_parts':items,'size_bytes':len(glb),'rig_group_count':len({x['rig_group'] for x in items}), 'geometry_count':len(items)}
    dst.with_suffix('.manifest.json').write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n')
    print(json.dumps({'asset':str(dst),'sha256':h,'parts':len(items),'vertices':sum(q['vertices'] for q in items)},indent=2))
if __name__=='__main__':main()
