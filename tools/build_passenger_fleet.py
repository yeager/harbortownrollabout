"""Build the four passenger cars and the Sjöstad city bus from longitudinal profiles."""
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, cube, cylinder, material, mesh_from_rings,
    export_vehicle, SOURCE_DIR, DARK, RUBBER, METAL, HEADLAMP, RED_LAMP)

def build(key, length, width, axles, color, belt, cabin):
    clear_scene()
    root=bpy.data.objects.new(key,None)
    bpy.context.collection.objects.link(root)
    paint=material(key+" enamel",color,.42,.26)
    glass=material("Smoked blue glazing",(.035,.062,.077),.47,.15)
    white=material("Ivory",(.88,.86,.75),.13,.3)
    amber=material("Indicator",(.95,.29,.012),.15,.27)
    def box(name,x,y,z,w,d,h,mat,bev=.018):
        return cube(name,(x,y,z),(w,d,h),mat,bev,root)
    def bar(name,a,b,thick,mat):
        v=Vector(b)-Vector(a)
        part=box(name,*((Vector(a)+Vector(b))*.5),thick,thick,v.length,mat,.008)
        part.rotation_euler=v.to_track_quat('Z','Y').to_euler()
    bus=key=="city_bus"
    end=length/2
    wheel=.46 if bus else .32
    shape=[(-1,.88,.8),(-.93,.97,.92),(-.63,1,1),(-.28,.98,1.03),(.22,.99,1.02),(.65,1,1),(.94,.97,.98),(1,.91,.92)]
    if key=="saab96": shape=[(-1,.70,.77),(-.91,.90,.85),(-.67,1,.96),(-.29,.98,1.05),(.25,.98,1.06),(.68,1,.99),(.92,.88,.86),(1,.72,.73)]
    if bus: shape=[(-1,.94,.99),(-.97,1,1),(.97,1,1),(1,.96,.99)]
    body=mesh_from_rings("Painted bodyshell",[(u*end,w*width,.20,belt*h-.04,belt*h) for u,w,h in shape],paint,root,.035)
    for y in axles:
        bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=wheel+.045,depth=width*2.5,location=(0,y,wheel),rotation=(0,math.pi/2,0))
        cutter=bpy.context.object
        mod=body.modifiers.new("Wheel opening","BOOLEAN");mod.object=cutter;mod.operation="DIFFERENCE"
        bpy.context.view_layer.objects.active=body
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
        for side in [-1,1]:
            for name,x,r,d,mat in [("Däck",width-.12,wheel,.21,RUBBER),("Alloy wheel",width-.012,wheel*.74,.04,METAL),("Wheel hub",width+.012,wheel*.43,.036,DARK)]:
                cylinder(name,(side*x,y,wheel),r,d,mat,True,48,root)
            count=14 if key=="m3_e30" else 8
            for i in range(count):
                angle=math.tau*i/count
                spoke=box("Alloy wheel spoke",side*(width+.04),y+.13*math.sin(angle),wheel+.13*math.cos(angle),.02,.033,.18,METAL,.006)
                spoke.rotation_euler.x=-angle+.21
    # Roof contours and matching individual side panes on each side.
    verts=[]; faces=[]; mats=[]
    def quad(points,mat):
        n=len(verts);verts.extend(points);faces.append(tuple(reversed(range(n,n+4))));mats.append(mat)
    sections=[]
    for y,top,wt in cabin:
        sections.append([(-width*.91,y,belt-.025),(-width*wt,y,top-.035),
                         (width*wt,y,top-.035),(width*.91,y,belt-.025)])
    for i,(a,b) in enumerate(zip(sections,sections[1:])):
        for j in range(3):
            quad([a[j],b[j],b[j+1],a[j+1]],glass if j!=1 or i in [0,len(sections)-2] or key=="model_s" else paint)
        for side,j in [(-1,0),(1,3)]:
            k=1 if j==0 else 2
            bar("Roof rail",a[k],b[k],.058,paint)
            if i>0: bar("Window pillar",a[j],a[k],.065,paint if i==1 else DARK)
    mesh=bpy.data.meshes.new("Cabin panels");mesh.from_pydata(verts,[],faces);mesh.update()
    cabin_obj=bpy.data.objects.new("Cabin",mesh);bpy.context.collection.objects.link(cabin_obj);cabin_obj.parent=root
    for mat in [paint,glass]: mesh.materials.append(mat)
    for p,m in zip(mesh.polygons,mats): p.material_index=int(m==glass)
    for side in [-1,1]:
        box("Mirror",side*(width+.065),cabin[1][0]-.07,belt+.12,.17,.22,.13,paint)
        for y in ([.10,.94] if key in ["model_s","volvo240"] else [.22]):
            box("Door handle",side*width*.99,y,belt-.14,.032,.15,.04,DARK)
        if key in ["m3_e30","volvo240"]:
            for x in ([.48,.72] if key=="m3_e30" else [.65]):
                lens=cylinder("Headlight",(side*x,-end-.012,belt*.73),.116,.055,HEADLAMP,False,32,root)
                lens.rotation_euler.x=math.pi/2
        else:
            box("Headlamp",side*width*.68,-end-.02,belt*.72,width*.40,.065,.10 if key=="model_s" else .18,HEADLAMP)
        box("Ruby tail lens",side*width*.66,end+.025,belt*.73,width*.44,.07,.12,RED_LAMP)
        box("Amber lens",side*width*.84,end+.03,belt*.75,.07,.07,.09,amber)
    for y in [-end,end]:
        box("Bumper",0,y,.36,width*1.96,.13,.13,RUBBER if key!="m3_e30" else paint)
    if key!="model_s":
        box("Grille",0,-end-.033,belt*.74,width*.91,.05,.22,DARK)
        if key=="volvo240":
            bar("Diagonal grille slash",(-.38,-end-.072,belt*.64),(.38,-end-.072,belt*.84),.027,METAL)
        elif key=="m3_e30":
            for x in [-.09,.09]: box("Kidney surround",x,-end-.074,belt*.74,.15,.035,.20,METAL)
            for x in [-.09,.09]: box("Kidney opening",x,-end-.097,belt*.74,.115,.025,.17,DARK)
        for i in range(4): box("Grille slat",0,-end-.065,belt*.65+i*.043,width*.83,.018,.011,METAL,.002)
    if key=="m3_e30":
        for side in [-1,1]: box("Spoiler foot",side*.63,end-.17,belt+.04,.08,.19,.18,paint)
        box("Rear wing",0,end-.17,belt+.15,1.55,.24,.07,paint)
    if bus:
        for side in [-1,1]:
            box("White waist stripe",side*width,0,.87,.03,length*.96,.15,white)
        for y in [-3.6,.3,3.5]:
            for off in [-.25,.25]: box("Passenger door",-width-.025,y+off,1.36,.035,.46,2.03,DARK)
        box("Destination board",0,-end-.03,2.68,1.75,.08,.34,DARK)
        box("Roof ventilation",0,0,3.10,1.5,3,.22,white)
    export_vehicle(root,key+".glb")
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/(key+".blend")))

build("m3_e30",4.35,.86,[-1.28,1.28],(.57,.018,.023),.93,[(-1.02,.97,.89),(-.49,1.40,.77),(.20,1.42,.76),(.69,1.40,.76),(1.30,.97,.89)])
build("volvo240",4.77,.86,[-1.32,1.32],(.89,.23,.035),.99,[(-.96,1.03,.89),(-.53,1.46,.81),(.20,1.48,.80),(.86,1.47,.81),(1.32,1.03,.89)])
build("saab96",4.15,.79,[-1.23,1.23],(.12,.38,.30),.90,[(-.88,.95,.88),(-.49,1.38,.76),(-.23,1.47,.73),(.28,1.48,.73),(.69,1.41,.74),(1.09,1.22,.79),(1.57,.91,.82)])
build("model_s",4.97,.97,[-1.48,1.48],(.82,.84,.86),.90,[(-1.31,.94,.89),(-.63,1.31,.75),(-.2,1.43,.71),(.39,1.44,.71),(.88,1.35,.74),(1.47,1.13,.78),(1.93,.93,.81)])
build("city_bus",10.4,1.24,[-3.12,2.94],(.65,.025,.038),1.45,[(-5.2,1.50,.90),(-4.99,2.96,.94),(-3.45,2.98,.94),(-1.9,2.98,.94),(-.4,2.98,.94),(1.1,2.98,.94),(2.6,2.98,.94),(4.97,2.98,.94),(5.2,1.50,.90)])
