"""Create the open centre-console launch and its editable Blender source."""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene, cube, cylinder, material, mesh_from_rings, export_vehicle, SOURCE_DIR

clear_scene()
root = bpy.data.objects.new("Centre console launch", None)
bpy.context.collection.objects.link(root)
white = material("Ivory gelcoat", (.86,.87,.83), .15,.23)
deck = material("Non-slip moulded deck", (.65,.68,.65))
rubber = material("Rubber rubbing strake", (.019,.023,.024))
steel = material("Polished marine stainless", (.66,.72,.73), .92,.18)
glass = material("Tinted windscreen", (.37,.62,.67), .10,.13)
bsdf = next(node for node in glass.node_tree.nodes if node.type=="BSDF_PRINCIPLED")
bsdf.inputs["Alpha"].default_value = .44
seat = material("Blue marine vinyl", (.028,.077,.13), .05,.44)

def box(name, xyz, size, finish, bevel=.035):
    return cube(name, xyz, size, finish, bevel, root)

def tube(name, a, b, radius, finish):
    a,b = Vector(a),Vector(b)
    obj = cylinder(name,(a+b)/2,radius,(b-a).length,finish,False,12,root)
    obj.rotation_euler = (b-a).to_track_quat("Z","Y").to_euler()
    return obj

stations = [(-2.50,.07,.78),(-2.26,.42,.73),(-1.82,.77,.66),(-1.12,.96,.61),
            (0,1,.58),(1.45,.94,.54),(2.12,.87,.52)]
def section(y,w,b,s,h):
    return [(0,y,b),(-w*.83,y,b+.24),(-w,y,h),(-w*.89,y,h),
            (-w*.73,y,.14),(w*.73,y,.14),(w*.89,y,h),(w,y,h),(w*.83,y,b+.24)]
mesh_from_rings("Open V hull",[(y,w,-.32+.17*max(0,-y-1),0,h) for y,w,h in stations],white,root,.024,section)
for side in [-1,1]:
    for i in range(1,len(stations)):
        y,w,h=stations[i]
        py,pw,ph=stations[i-1]
        tube("Gunwale fender",(side*pw,py,ph-.046),(side*w,y,h-.046),.031,rubber)
        if i<=3:
            tube("Bow pulpit",(side*pw,py,ph+.36),(side*w,y,h+.36),.019,steel)
            tube("Pulpit leg",(side*w,y,h),(side*w,y,h+.36),.016,steel)
box("Forward casting deck",(0,-1.57,.42),(1.19,.79,.17),deck,.12)
box("Centre console",(0,-.26,.57),(.91,.61,.74),white,.11)
screen=box("Spray screen",(0,-.51,1.18),(.99,.047,.65),glass,.055)
screen.rotation_euler.x=-.22
for side in [-1,1]:
    tube("Windscreen frame",(side*.49,-.58,.87),(side*.49,-.44,1.49),.018,steel)
tube("Top bow",(-.49,-.44,1.49),(.49,-.44,1.49),.018,steel)
box("Helm wheel hub",(.21,.077,.89),(.13,.12,.13),rubber)
bpy.ops.mesh.primitive_torus_add(location=(.21,.11,.93),major_radius=.145,minor_radius=.018,rotation=(1.16,0,0))
wheel=bpy.context.object
wheel.name="Helm wheel"
wheel.parent=root
wheel.data.materials.append(rubber)
for y in [.61,1.68]:
    box("Bench cushion",(0,y,.54),(1.4,.49,.15),seat,.07)
    box("Backrest",(0,y+.23,.74),(1.42,.13,.43),white,.07)
    box("Bench locker",(0,y,.34),(1.29,.40,.28),white)
box("Outboard cowling",(0,2.28,.59),(.49,.58,.61),white,.14)
box("Gearcase",(0,2.31,.02),(.14,.23,.68),steel)
tube("Propeller hub",(0,2.31,-.24),(0,2.52,-.24),.068,rubber)
export_vehicle(root,"motorboat.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"Motorboat.blend"))
