"""Blue trail snowmobile, with an articulated-looking front suspension."""
import sys
from pathlib import Path
from math import atan2, cos, sin, pi
import bpy
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene, cube, cylinder, material, mesh_from_rings, export_vehicle, SOURCE_DIR, DARK, RUBBER, METAL, HEADLAMP, RED_LAMP

clear_scene()
root = bpy.data.objects.new("Trail sled", None)
bpy.context.collection.objects.link(root)
blue = material("Cobalt enamel", (.018,.075,.62), .5,.25)

def shell(name, rows, finish):
    return mesh_from_rings(name, rows, finish, root, .019)

def beam(name, start, end, radius, finish):
    direction = Vector(end) - Vector(start)
    part = cylinder(name, (Vector(end)+Vector(start))/2, radius, direction.length, finish, False, 16, root)
    part.rotation_euler = direction.to_track_quat('Z','Y').to_euler()
    return part

def pivot(name, location):
    node = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(node)
    node.parent = root
    node.location = location
    return node

def attach(part, joint):
    part.parent = joint
    part.location -= joint.location

# Sweep the rubber belt around the two end wheels, leaving the bogie visible.
track = []
for center_y, start_angle in [(1.14,-pi/2),(-.10,pi/2)]:
    for i in range(17):
        angle = start_angle + pi*i/16
        track.append((center_y, angle))
vertices, faces = [], []
for center_y, angle in track:
    for x, radius in [(-.20,.20),(.20,.20),(.20,.17),(-.20,.17)]:
        vertices.append((x, center_y+radius*cos(angle), .23+radius*sin(angle)))
for i in range(len(track)):
    j = (i+1) % len(track)
    for k in range(4):
        n = (k+1) % 4
        faces.append((4*i+k,4*j+k,4*j+n,4*i+n))
belt_mesh = bpy.data.meshes.new("Track cross section")
belt_mesh.from_pydata(vertices, [], faces)
belt = bpy.data.objects.new("Endless rubber track", belt_mesh)
bpy.context.collection.objects.link(belt)
belt.parent = root
belt_mesh.materials.append(RUBBER)
for i in range(19):
    for z in [.026,.434]:
        cube("Track cleat",(0,-.10+i*1.24/18,z),(.45,.036,.045),DARK,.007,root)
for center_y,angle in track[::3]:
    cleat = cube("Return cleat",(0,center_y+.213*cos(angle),.23+.213*sin(angle)),(.45,.034,.045),DARK,.007,root)
    cleat.rotation_euler.x = angle-pi/2
for side in [-1,1]:
    beam("Slide rail",(side*.125,-.16,.17),(side*.125,1.16,.17),.035,METAL)
    for y in [-.10,.31,.73,1.14]:
        cylinder("Bogie tyre",(side*.146,y,.23),.163,.073,RUBBER,True,32,root)
        cylinder("Wheel face",(side*.187,y,.23),.112,.016,DARK,True,32,root)
        cylinder("Axle cap",(side*.199,y,.23),.037,.018,METAL,True,20,root)
shell("Tunnel and fairing",[(-1.2,.12,.43,.54,.60),(-.90,.35,.29,.64,.78),(-.45,.46,.30,.89,1.05),(-.12,.38,.32,.83,.93),(.32,.33,.42,.62,.68),(1.43,.27,.48,.56,.60)],blue)
shell("Graphite bonnet",[(-1.22,.10,.51,.58,.61),(-.88,.31,.58,.72,.80),(-.44,.37,.74,.94,1.07),(-.20,.29,.77,.96,1.08)], DARK)
shell("Saddle",[(-.17,.17,.66,.76,.82),(.04,.21,.61,.83,.88),(.60,.23,.57,.74,.82),(.92,.17,.56,.65,.72)],RUBBER)
bars = pivot("HandlebarPivot", (0,-.36,1.18))
for side in [-1,1]:
    cube("Footboard", (side*.37,.28,.32), (.20,.90,.045), DARK,.015,root)
    for step in range(7):
        cube("Foot grip", (side*.37,-.07+step*.11,.35), (.18,.019,.017), METAL,.004,root)
    x = side*.51
    ski = pivot("SkiPivotLeft" if side < 0 else "SkiPivotRight", (x,-.82,.08))
    for y,z,y2,z2 in [(-1.57,.20,-1.45,.085),(-1.45,.085,-1.28,.055),(-1.28,.055,-.51,.055),(-.51,.055,-.43,.09)]:
        part=cube("Upturned runner",(x,(y+y2)/2,(z+z2)/2),(.17,((y2-y)**2+(z2-z)**2)**.5+.02,.046),blue,.018,root)
        part.rotation_euler.x=atan2(z2-z,y2-y)
        attach(part, ski)
    # The grab loop arches back from the raised tip and turns with the runner.
    loop_points = [(-1.55,.18),(-1.48,.25),(-1.39,.28),(-1.31,.24),(-1.18,.08)]
    for (y,z),(next_y,next_z) in zip(loop_points,loop_points[1:]):
        attach(beam("Ski grab loop",(x,y,z),(x,next_y,next_z),.016,METAL), ski)
    beam("Steering spindle",(x,-.82,.08),(x,-.75,.46),.035,METAL)
    for y in [-.95,-.45]:
        beam("Wishbone",(side*.21,y,.38),(x,-.75,.23),.022,blue)
    beam("Shock",(side*.27,-.60,.67),(x,-.75,.24),.031,METAL)
    beam("Headlight strip",(side*.045,-.72,.92),(side*.27,-.64,.92),.035,HEADLAMP)
    attach(beam("Grip",(side*.23,-.36,1.18),(side*.36,-.33,1.18),.028,RUBBER), bars)
attach(beam("Handlebar",(-.3,-.36,1.18),(.3,-.36,1.18),.019,METAL), bars)
beam("Steering column",(0,-.29,.9),(0,-.36,1.18),.032,DARK)
cube("Tail lamp",(0,1.43,.57),(.20,.03,.055),RED_LAMP,.012,root)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"Snowmobile.blend"))
export_vehicle(root,"snowmobile.glb")
