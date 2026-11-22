"""Build the high-clearance monster pickup and its editable Blender source."""
from math import cos, sin, tau
from pathlib import Path
import sys
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Monster truck", None)
bpy.context.collection.objects.link(root)
red = v.material("Candy apple red", (.72,.019,.012), .46,.22)
orange = v.material("Flame orange", (1,.28,.008), .12,.3)
steel = v.material("Graphite tube frame", (.09,.105,.12), .7,.32)
glass = v.material("Smoked blue glass", (.045,.12,.19), .48,.14)
rubber = v.material("Soft mud tire", (.024,.026,.034), 0,.85)
lug = v.material("Chevron tread", (.047,.049,.058), 0,.8)

def tube(name, a, b, r, mat):
    a,b = Vector(a),Vector(b)
    o=v.cylinder(name,(a+b)/2,r,(b-a).length,mat,False,16,root)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()

def shell(name, rings, mat):
    return v.mesh_from_rings(name,rings,mat,root)

shell("Pickup body", [(-2.72,.88,2.12,2.53,2.60),(-2.48,1.03,2.12,2.66,2.73),
      (-1.05,1.09,2.09,2.75,2.83),(.85,1.09,2.08,2.76,2.82),(2.56,1.0,2.17,2.64,2.69)],red)
shell("Cab glazing",[(-1.04,1.01,2.72,2.83,2.89),(-.46,.88,2.74,3.43,3.56),
      (.54,.89,2.74,3.45,3.57),(.92,1.01,2.72,2.83,2.93)],glass)
shell("Cab roof",[(-.5,.83,3.41,3.50,3.58),(.53,.85,3.42,3.52,3.61)],red)
v.cube("Bed liner",(0,1.72,2.77),(1.76,1.30,.08),steel,.04,root)
v.cube("Front grille",(0,-2.72,2.4),(1.23,.10,.23),steel,.055,root)
for side in [-1,1]:
    x=side*.87
    for y in [-1.69,1.68]:
        tube("Shock absorber",(x,y,1.02),(x*.83,y*.69,2.18),.10,v.METAL)
        tube("Suspension link",(x,y,1.03),(x,.22*y,1.75),.07,steel)
        for dz in range(7):
            t=.34+dz*.076
            pos=Vector((x,y,1.02)).lerp(Vector((x*.83,y*.69,2.18)),t)
            tube("Spring collar",pos,pos+Vector((0,0,.055)),.144,red)
    tube("Frame rail",(x,-2.23,1.98),(x,2.30,1.98),.10,steel)
    tube("Cab pillar",(side*1.0,-1,2.75),(side*.82,-.46,3.5),.056,red)
    tube("Cab pillar",(side*.98,.9,2.8),(side*.83,.55,3.49),.065,red)
    tube("Horn base",(side*.65,.40,3.54),(side*.74,.60,3.84),.095,red)
    tube("Horn tip",(side*.74,.60,3.84),(side*.74,.91,4.02),.047,red)
    v.cube("Headlight",(side*.75,-2.69,2.49),(.30,.08,.15),v.HEADLAMP,.03,root)
    v.cube("Tail lamp",(side*.78,2.56,2.48),(.28,.08,.16),v.TAIL_LAMP,.03,root)
    pts=[(-1.88,2.31),(-1.18,2.65),(-1.26,2.48),(-.65,2.76),(-.84,2.50),(-.16,2.68),(-.70,2.36),(-.66,2.47),(-1.32,2.29)]
    mesh=bpy.data.meshes.new("Flame graphic")
    mesh.from_pydata([(side*1.095,y,z) for y,z in pts],[],[tuple(range(len(pts)))])
    obj=bpy.data.objects.new("Flame",mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(orange)
    obj.parent=root
    v.text_obj("Door lettering","MONSTER",(side*1.10,.27,2.39),.24,v.PAINT_WHITE,side=-side,root=root)

for y in [-1.69,1.68]:
    tube("Solid axle",(-1.56,y,1.04),(1.56,y,1.04),.14,steel)
    for side in [-1,1]:
        x=side*1.48
        profile=[(-.48,.48),(-.48,.76),(-.39,.93),(-.27,1.0),(.27,1.0),(.39,.93),(.48,.76),(.48,.48)]
        rings=[[(x+w,y+r*cos(tau*i/48),1.04+r*sin(tau*i/48)) for i in range(48)] for w,r in profile]
        tire=v.profile_loft("All terrain tire",rings,rubber,root)
        parts=[tire]
        for i in range(22):
            for half in [-1,1]:
                a=tau*i/22+half*.034
                o=v.cube("Raised lug",(x+.20*half,y+.984*cos(a),1.04+.984*sin(a)),(.47,.105,.15),lug,0,root)
                o.rotation_euler=(a,0,half*.42)
                parts.append(o)
        bpy.ops.object.select_all(action='DESELECT')
        for o in parts: o.select_set(True)
        bpy.context.view_layer.objects.active=tire
        bpy.ops.object.join()
        v.cylinder("Wheel hub beadlock",(x+side*.44,y,1.04),.52,.115,red,root=root)
        v.cylinder("Wheel hub alloy",(x+side*.51,y,1.04),.40,.07,v.METAL,root=root)
        v.cylinder("Wheel hub cap",(x+side*.56,y,1.04),.18,.08,steel,root=root)
        for i in range(8):
            a=tau*i/8
            v.cylinder("Wheel bolt",(x+side*.56,y+.3*cos(a),1.04+.3*sin(a)),.034,.04,steel,vertices=6,root=root)

bpy.context.preferences.filepaths.save_version=0
v.export_vehicle(root,"monster_truck.glb")
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR)/"MonsterTruck.blend"))
