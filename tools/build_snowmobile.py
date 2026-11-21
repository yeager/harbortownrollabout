"""Blue trail snowmobile, with an articulated-looking front suspension."""
import sys
from pathlib import Path
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

shell("Rubber drive belt", [(-.35,.19,.16,.32,.36),(-.12,.20,.035,.39,.43),(1.12,.20,.035,.39,.43),(1.4,.19,.15,.35,.39)], RUBBER)
for i in range(20):
    cube("Track lug", (0,-.1+i*.065,.044), (.45,.026,.065), DARK,.007,root)
for y in [0,.37,.76,1.13]:
    cylinder("Bogie hub",(0,y,.23),.12,.42,METAL,True,24,root)
shell("Tunnel and fairing",[(-1.2,.12,.43,.54,.60),(-.90,.35,.29,.64,.78),(-.45,.46,.30,.89,1.05),(-.12,.38,.32,.83,.93),(.32,.33,.42,.62,.68),(1.43,.27,.48,.56,.60)],blue)
shell("Graphite bonnet",[(-1.22,.10,.51,.58,.61),(-.88,.31,.58,.72,.80),(-.44,.37,.74,.94,1.07),(-.20,.29,.77,.96,1.08)], DARK)
shell("Saddle",[(-.17,.17,.66,.76,.82),(.04,.21,.61,.83,.88),(.60,.23,.57,.74,.82),(.92,.17,.56,.65,.72)],RUBBER)
for side in [-1,1]:
    x = side*.51
    for y,z,y2,z2 in [(-1.57,.20,-1.45,.085),(-1.45,.085,-1.28,.055),(-1.28,.055,-.51,.055),(-.51,.055,-.43,.09)]:
        part=cube("Upturned runner",(x,(y+y2)/2,(z+z2)/2),(.17,((y2-y)**2+(z2-z)**2)**.5+.02,.046),blue,.018,root)
        from math import atan2
        part.rotation_euler.x=atan2(z2-z,y2-y)
    beam("Steering spindle",(x,-.82,.08),(x,-.75,.46),.035,METAL)
    for y in [-.95,-.45]:
        beam("Wishbone",(side*.21,y,.38),(x,-.75,.23),.022,blue)
    beam("Shock",(side*.27,-.60,.67),(x,-.75,.24),.031,METAL)
    beam("Headlight strip",(side*.045,-.72,.92),(side*.27,-.64,.92),.035,HEADLAMP)
    beam("Grip",(side*.23,-.36,1.18),(side*.36,-.33,1.18),.028,RUBBER)
beam("Handlebar",(-.3,-.36,1.18),(.3,-.36,1.18),.019,METAL)
beam("Steering column",(0,-.29,.9),(0,-.36,1.18),.032,DARK)
cube("Tail lamp",(0,1.43,.57),(.20,.03,.055),RED_LAMP,.012,root)
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"Snowmobile.blend"))
export_vehicle(root,"snowmobile.glb")
