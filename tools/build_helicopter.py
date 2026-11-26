"""Build a Swedish police helicopter with independently animated rotor hubs."""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene, cube, cylinder, material, export_vehicle, text_obj, SOURCE_DIR

clear_scene()
def pivot(name, parent=None, position=(0,0,0)):
    node=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(node)
    node.parent=parent
    node.location=position
    return node

root=pivot("Polishelikopter")
blue=material("Polis blue lacquer",(.025,.17,.46),.36,.27)
white=material("White enamel",(.86,.90,.92),.25,.32)
red=material("Signal red",(.78,.022,.018),.20,.31)
glass=material("Smoked canopy",(.021,.068,.102),.48,.14)
graphite=material("Graphite composite",(.036,.043,.049),.18,.38)
metal=material("Rotor hardware",(.32,.37,.4),.76,.28)

def shell(name, stations, paint):
    verts=[]
    faces=[]
    indices=[]
    sides=40
    for y,w,z,h in stations:
        for i in range(sides):
            a=math.tau*i/sides
            verts.append((w*math.cos(a),y,z+h*math.sin(a)))
    for j in range(len(stations)-1):
        for i in range(sides):
            k=(i+1)%sides
            faces.append((j*sides+i,(j+1)*sides+i,(j+1)*sides+k,j*sides+k))
            indices.append(paint(j,i,math.sin(math.tau*(i+.5)/sides)))
    faces.extend([tuple(range(sides)),tuple(reversed(range(len(verts)-sides,len(verts))))])
    indices.extend([0,0])
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    for m in [blue,white,glass,red]: mesh.materials.append(m)
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent=root
    for face,idx in zip(mesh.polygons,indices):
        face.material_index=idx
        face.use_smooth=True
    return obj

def cabin_paint(j,i,s):
    if j<9 and .09<s<.91 and j not in (3,6) and i not in (9,10):
        return 2
    return 1 if -.53<s<.14 else 0

shell("Glazed passenger fuselage",[(-3.45,.07,1.39,.10),(-3.22,.59,1.39,.52),
      (-2.75,.95,1.48,.84),(-2.05,1.09,1.54,1.01),(-1.98,1.10,1.55,1.02),
      (-1.25,1.13,1.56,1.08),(-.79,1.14,1.56,1.09),(-.71,1.14,1.56,1.09),
      (.03,1.13,1.55,1.07),(.80,1.05,1.55,.97),(1.57,.81,1.57,.75),(2.3,.40,1.64,.38)],cabin_paint)
shell("Tapered tail boom",[(1.6,.55,1.69,.49),(2.7,.38,1.74,.36),
      (4.3,.22,1.9,.23),(5.47,.16,2.01,.16)],lambda j,i,s:0)
for side in [-1,1]:
    text_obj("Police fuselage lettering","POLIS",(side*1.15,-side*.68,1.14),.40,blue,-side,root)
    skid=cube("Landing runner",(side*1.08,-.39,.16),(.09,3.83,.10),blue,.045,root)
    for y in [-1.55,.78]:
        support=cube("Skid strut",(side*.92,y,.44),(.08,.1,.65),blue,.035,root)
        support.rotation_euler.y=-side*.52
for z,y,dy,dz,finish in [(2.47,5.44,.82,1.16,white),(3.09,5.57,.80,.16,red)]:
    fin=cube("Tail fin",(0,y,z),(.11,dy,dz),finish,.055,root)
    fin.rotation_euler.x=-.22
cube("Tailplane",(0,4.57,1.92),(2.22,.44,.072),white,.035,root)
engine=cube("Turbine housing",(0,.09,2.52),(1.25,2.26,.53),blue,.24,root)
cylinder("Mast",(0,-.27,2.99),.095,.47,metal,False,20,root)
main=pivot("MainRotor",root,(0,-.27,3.21))
tail=pivot("TailRotor",root,(.25,5.35,2.05))
for name, height, radius, depth, finish in [
    ("Main rotor hub", 0, .29, .13, metal),
    ("Main rotor cap", .093, .19, .074, blue),
]:
    component = cylinder(name, (0, 0, height), radius, depth, finish, False, 32, main)
    component.matrix_parent_inverse.identity()
for hub,count,length in [(main,4,4.09),(tail,7,.56)]:
    for i in range(count):
        angle=math.tau*i/count
        if hub==main:
            blade=cube("Main blade",(0,0,0),(.19,length,.047),graphite,.02,hub)
            radial = Vector((-math.sin(angle), math.cos(angle), 0))
            blade.location = radial * (.35 + length / 2)
            blade.rotation_euler.z=angle
            cuff = cube("Main blade root cuff", (0, 0, 0), (.235, .39, .085), metal, .025, hub)
            cuff.location = radial * .365
            cuff.rotation_euler.z = angle
            cuff.matrix_parent_inverse.identity()
        else:
            blade=cube("Tail blade",(0,0,0),(.038,.08,length),graphite,.012,hub)
            blade.location=(0,-math.sin(angle)*length/2,math.cos(angle)*length/2)
            blade.rotation_euler.x=angle
        blade.matrix_parent_inverse.identity()
bpy.ops.mesh.primitive_torus_add(location=(.18,5.35,2.05),rotation=(0,math.pi/2,0),
                                major_radius=.60,minor_radius=.085)
ring=bpy.context.object
ring.name="Shrouded tail rotor"
ring.parent=root
ring.data.materials.append(blue)
export_vehicle(root,"polishelikopter.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"Polishelikopter.blend"))
