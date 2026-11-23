"""Build the high-clearance monster pickup and its editable Blender source."""
from math import cos, sin, tau
from pathlib import Path
import sys
import bpy
from mathutils import Vector
from mathutils.geometry import interpolate_bezier

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Monster truck", None)
bpy.context.collection.objects.link(root)
red = v.material("Candy apple red", (.72,.019,.012), .46,.22)
orange = v.material("Flame orange", (1,.28,.008), .12,.3)
gold = v.material("Flame gold", (1,.61,.025), .08,.32)
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

def pickup_section(y, width, bottom, shoulder, crown):
    # The front wings rise outboard of the hood, tapering into the door shoulders.
    wing = max(0, 1 - abs(y+1.9)/1.05) * .14
    contour = [(0,bottom),(.88,bottom),(.98,bottom+.055),(1,bottom+.13),
               (1,shoulder-.12),(.985,shoulder-.025),(.94,shoulder+.035+wing),
               (.85,crown+wing),(.76,crown+.015+wing*.55),(.65,crown-.025),
               (.38,crown+.018),(0,crown+.038)]
    if y >= 1.0:
        contour = contour[:7] + [(.89,crown),(.83,crown),(.80,2.47),(.76,2.44),(0,2.44)]
    return [(width*x,y,z) for x,z in contour] + [(-width*x,y,z) for x,z in reversed(contour[1:-1])]

v.mesh_from_rings("Pickup body", [
    (-2.72,.86,2.17,2.50,2.55),(-2.66,.95,2.14,2.57,2.63),
    (-2.48,1.035,2.12,2.66,2.72),(-2.20,1.075,2.11,2.71,2.76),
    (-1.90,1.09,2.10,2.74,2.79),(-1.55,1.09,2.09,2.75,2.81),
    (-1.05,1.09,2.09,2.75,2.83),(.85,1.09,2.08,2.76,2.82),
    (1.01,1.085,2.09,2.75,2.82),(2.38,1.035,2.14,2.68,2.73),(2.56,1.0,2.17,2.64,2.69)
],red,root,section=pickup_section)
# Nest the glass inside the roof at its upper edge and inside the body at the sill.
lower_front = [(-.98,-1.04,2.77),(.98,-1.04,2.77)]
upper_front = [(-.82,-.48,3.48),(.82,-.48,3.48)]
lower_rear = [(-.98,.94,2.77),(.98,.94,2.77)]
upper_rear = [(-.82,.52,3.48),(.82,.52,3.48)]
panes = bpy.data.meshes.new("Four flat cab panes")
panes.from_pydata(lower_front+upper_front+lower_rear+upper_rear,[],
                  [(0,1,3,2),(5,4,6,7),(4,0,2,6),(1,5,7,3)])
windows = bpy.data.objects.new("Cab glazing",panes)
bpy.context.collection.objects.link(windows)
windows.parent = root
next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .42
panes.materials.append(glass)
v.cube("Cab dashboard",(0,-.60,2.91),(1.46,.28,.16),steel,.045,root)
v.cube("Seat cushion",(0,.07,2.91),(.55,.49,.12),rubber,.05,root)
v.cube("Seat back",(0,.30,3.10),(.53,.13,.46),rubber,.06,root)
v.cube("Head restraint",(0,.31,3.36),(.29,.12,.15),rubber,.04,root)
for side in [-1,1]:
    tube("Harness shoulder strap",(.13*side,.22,3.28),(.18*side,.21,2.95),.022,orange)
    tube("Rear cage brace",(side*.68,.64,2.84),(-side*.67,.39,3.45),.032,steel)
tube("Steering column",(0,-.56,2.91),(0,-.30,3.05),.038,steel)
bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=(0,-.30,3.05),
                                rotation=(1.12,0,0),major_radius=.15,minor_radius=.018)
wheel = bpy.context.object
wheel.name = "Steering wheel"
wheel.parent = root
wheel.data.materials.append(rubber)
for spoke in range(3):
    angle = tau*spoke/3
    tube("Wheel spoke",wheel.location,wheel.location+Vector((.14*cos(angle),.061*sin(angle),.126*sin(angle))),.011,steel)
roof_rings = []
for y,width,edge in [(-.56,.81,3.41),(-.46,.86,3.48),(-.21,.88,3.52),
                     (.18,.88,3.53),(.49,.86,3.49),(.60,.81,3.40)]:
    roof_rings.append([(-width,y,edge),(-width,y,edge+.039),(-width*.83,y,edge+.083),
                       (0,y,edge+.12),(width*.83,y,edge+.083),(width,y,edge+.039),
                       (width,y,edge),(0,y,edge-.012)])
v.profile_loft("Cab roof",roof_rings,red,root)
liner = v.material("Textured bed liner",(.047,.051,.055),.05,.82)
v.cube("Recessed bed floor",(0,1.73,2.45),(1.55,1.46,.034),liner,.012,root)
for rib in range(-4,5):
    v.cube("Pressed bed rib",(rib*.16,1.72,2.476),(.069,1.32,.025),liner,.011,root)
v.cube("Tailgate",(0,2.51,2.55),(1.83,.105,.30),red,.032,root)
v.cube("Tailgate handle",(0,2.568,2.59),(.34,.025,.065),steel,.014,root)
v.cube("Front grille",(0,-2.72,2.4),(1.23,.10,.23),steel,.055,root)
for i in range(9):
    x = (i-4)*.126
    mesh = bpy.data.meshes.new("Grille fang")
    tip = 2.31 if i in (0,8) else 2.37
    mesh.from_pydata([(x-.055,-2.774,2.49),(x+.055,-2.774,2.49),(x,-2.785,tip)],[],[(0,2,1)])
    tooth = bpy.data.objects.new("Grille fang",mesh)
    bpy.context.collection.objects.link(tooth)
    mesh.materials.append(v.PAINT_WHITE)
    tooth.parent = root
for side in [-1,1]:
    x=side*.87
    for y in [-1.69,1.68]:
        tube("Shock absorber",(x,y,1.02),(x*.83,y*.69,2.18),.10,v.METAL)
        tube("Suspension link",(x,y,1.03),(x,.22*y,1.75),.07,steel)
        lower = Vector((x,y,1.02))
        upper = Vector((x*.83,y*.69,2.18))
        axis = (upper-lower).normalized()
        radial = axis.cross(Vector((0,1,0))).normalized()
        tangent = axis.cross(radial)
        coil = bpy.data.curves.new("Coil spring", "CURVE")
        coil.dimensions = "3D"
        coil.bevel_depth = .024
        coil.bevel_resolution = 2
        coil.use_fill_caps = True
        spline = coil.splines.new("POLY")
        spline.points.add(84)
        for i, point in enumerate(spline.points):
            t = i / 84
            phase = tau * 7 * t
            center = lower.lerp(upper, .30 + .55*t)
            point.co = (center + .13*(radial*cos(phase) + tangent*sin(phase))).to_4d()
        spring = bpy.data.objects.new("Suspension spring", coil)
        bpy.context.collection.objects.link(spring)
        spring.parent = root
        coil.materials.append(red)
    tube("Frame rail",(x,-2.23,1.98),(x,2.30,1.98),.10,steel)
    tube("Cab pillar",(side*1.0,-1,2.75),(side*.82,-.46,3.5),.056,red)
    tube("Cab pillar",(side*.98,.9,2.8),(side*.83,.55,3.49),.065,red)
    horn_rings = []
    for t in range(13):
        u = t/12
        center = Vector((side*(.63+.10*u),.34+.57*u*u,3.56+.52*u))
        axis = Vector((side*.10,1.14*u,.52)).normalized()
        across = axis.cross(Vector((0,1,0))).normalized()
        around = axis.cross(across)
        radius = .115*(1-u)**.8 + .004
        horn_rings.append([center + radius*(across*cos(tau*i/16)+around*sin(tau*i/16)) for i in range(16)])
    v.profile_loft("Swept roof horn",horn_rings,red,root)
    v.cube("Headlight",(side*.75,-2.69,2.49),(.30,.08,.15),v.HEADLAMP,.03,root)
    lamp_x = side*.78
    v.cube("Tail lamp surround",(lamp_x,2.566,2.49),(.335,.068,.207),steel,.027,root)
    v.cube("Stop lamp lens",(lamp_x,2.606,2.526),(.29,.024,.078),v.TAIL_LAMP,.014,root)
    v.cube("Turn signal lens",(lamp_x+side*.067,2.606,2.446),(.153,.024,.051),orange,.011,root)
    v.cube("Reversing lens",(lamp_x-side*.087,2.606,2.446),(.107,.024,.051),v.HEADLAMP,.011,root)
    # Cubic segments share endpoints but retain sharp tips between tongues.
    start = Vector((-1.97,2.31))
    segments = [
        ((-1.82,2.35),(-1.72,2.58),(-1.38,2.65)),
        ((-1.65,2.40),(-1.25,2.48),(-.84,2.73)),
        ((-1.04,2.57),(-1.20,2.43),(-.94,2.48)),
        ((-.73,2.53),(-.48,2.67),(-.17,2.66)),
        ((-.56,2.58),(-.69,2.32),(-1.04,2.33)),
        ((-1.19,2.34),(-1.22,2.40),(-1.39,2.37)),
        ((-1.58,2.34),(-1.78,2.22),tuple(start)),
    ]
    outline = []
    cursor = start
    for handle1, handle2, tip in segments:
        end = Vector(tip)
        outline.extend(interpolate_bezier(cursor,Vector(handle1),Vector(handle2),end,10)[:-1])
        cursor = end
    for label, scale, depth, finish in [("Flame silhouette",1.0,1.094,orange),("Flame core",.71,1.098,gold)]:
        mesh = bpy.data.meshes.new(label)
        points = [start + (point-start)*scale for point in outline]
        mesh.from_pydata([(side*depth,y,z) for y,z in points],[],[tuple(range(len(points)))])
        decal = bpy.data.objects.new(label,mesh)
        bpy.context.collection.objects.link(decal)
        mesh.materials.append(finish)
        decal.parent = root
    letters = v.text_obj("Door lettering","MONSTER",(side*1.105,0,2.36),.32,gold,side=-side,root=root)
    # Centre the word over the flame tips on both flanks.
    letters.location.y = -.02 - side*max(vertex.co.x for vertex in letters.data.vertices)/2

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
                sections = []
                for width, radius, sweep in [(.012,1.0,0),(.19,1.0,.09),(.28,.995,.15),(.39,.93,.21),(.455,.81,.24)]:
                    ring = []
                    for offset, height in [(-.070,-.014),(-.060,.034),(-.043,.050),(.043,.050),(.060,.034),(.070,-.014)]:
                        angle = tau*i/22 + sweep + offset
                        ring.append((x+half*width,y+(radius+height)*cos(angle),1.04+(radius+height)*sin(angle)))
                    sections.append(ring)
                parts.append(v.profile_loft("Chevron shoulder lug",sections,lug,root))
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
