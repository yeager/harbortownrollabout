"""Build the editable EC950F crawler excavator and its game mesh. Nose faces -Y."""
from math import atan2, cos, pi, sin, tau
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Volvo EC950F", None)
bpy.context.collection.objects.link(root)
gold = v.material("Construction yellow", (.95, .49, .025), .23, .32)
graphite = v.material("Graphite machine enamel", (.07, .085, .09), .32, .34)
shoe = v.material("Iron track plates", (.17, .18, .17), .76, .57)
chrome = v.material("Hydraulic chrome", (.66, .73, .78), .84, .18)
glass = v.material("Cab glass", (.08, .22, .28), .4, .19)


def box(name, pos, dims, mat, bevel=.025):
    return v.cube(name, pos, dims, mat, bevel, root)


def disc(name, pos, r, w, mat):
    return v.cylinder(name, pos, r, w, mat, vertices=24, root=root)


def tube(name, a, b, r, mat):
    a, b = Vector(a), Vector(b)
    obj = v.cylinder(name, (a+b)/2, r, (a-b).length, mat, axis_x=False, vertices=12, root=root)
    obj.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()
    return obj


def profile(name, points, x, width, mat, bevel=.045):
    rings = [[(side, y, z) for y,z in points] for side in (x-width/2, x+width/2)]
    obj = v.profile_loft(name, rings, mat, root)
    for poly in obj.data.polygons:
        poly.use_smooth = False
    mod = obj.modifiers.new("Forged corners", "BEVEL")
    mod.width, mod.segments = bevel, 3
    obj.modifiers.new("Face normals", "WEIGHTED_NORMAL")
    return obj


def hydraulic(name, x, base, end, radius):
    a, b = Vector((x,*base)), Vector((x,*end))
    collar = a.lerp(b, .53)
    tube(name+" barrel", a, collar, radius, graphite)
    tube(name+" gland", collar, a.lerp(b,.57), radius*1.09, shoe)
    tube(name+" piston", a.lerp(b,.55), b, radius*.60, chrome)
    for p in [a,b]:
        disc(name+" pivot", p, radius*1.22, radius*2.4, shoe)


def line(name, points, radius, mat):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.bevel_depth, curve.bevel_resolution = radius, 2
    spline = curve.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for knot, pos in zip(spline.bezier_points, points):
        knot.co = pos
        knot.handle_left_type = knot.handle_right_type = 'AUTO'
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.parent = root
    curve.materials.append(mat)


def track_frame(t):
    # Equidistant shoes around a stadium, including both sprockets.
    half, r = 2.13, .57
    straight = 2*half
    if t < straight:
        return -half+t, .68+r, 0
    t -= straight
    if t < pi*r:
        a = t/r
        return half+r*sin(a), .68+r*cos(a), -a
    t -= pi*r
    if t < straight:
        return half-t, .68-r, pi
    a = (t-straight)/r
    return -half-r*sin(a), .68-r*cos(a), pi-a


for side in [-1,1]:
    x = side*1.48
    box("Track frame", (x,0,.69), (.66,4.28,.72), graphite,.12)
    for y in [-2.13,-1.52,-.92,-.31,.31,.92,1.52,2.13]:
        outer = abs(y)>2
        z, r = (.68,.49) if outer else (.46,.26)
        disc("Final drive" if outer else "Lower roller", (x,y,z), r,.66,graphite)
        disc("Bearing cover", (x+side*.34,y,z),r*.52,.055,shoe)
    length = 8.52 + tau*.57
    parts = []
    for i in range(52):
        y,z,ang = track_frame(i*length/52)
        for name,depth,height,lift,mat in [("Track shoe",.224,.116,0,shoe),("Grouser",.052,.05,.07,v.METAL)]:
            obj=box(name,(x,y-lift*sin(ang),z+lift*cos(ang)),(.88,depth,height),mat,0)
            obj.rotation_euler.x=ang
            parts.append(obj)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    parts[0].name = "Continuous crawler shoes "+str(side)

box("Cross carriage",(0,0,.96),(2.85,3.46,.64),graphite,.12)
v.cylinder("Swing bearing",(0,0,1.37),1.37,.32,shoe,axis_x=False,root=root)
box("Upper deck",(0,.18,1.64),(3.72,4.62,.34),graphite,.13)
v.mesh_from_rings("Cast counterweight",[(.25,1.82,1.69,2.97,3.05),(1.72,1.84,1.70,3.05,3.18),(2.37,1.73,1.75,3.00,3.10),(2.64,1.44,1.80,2.88,2.99)],gold,root)
box("Engine access enclosure",(-.97,-.52,2.41),(1.6,1.84,1.32),graphite,.12)
for y in [-1.12,-.88,-.64,-.40,-.16]:
    box("Cooling grille",(-1.786,y,2.46),(.036,.095,.66),v.BLACK,.018)
for side in [-1,1]:
    v.text_obj("Machine designation","EC950F",(side*1.846,1.10-side*.34,2.28),.20,graphite,side=-side,root=root)
# Glazing has an angled windshield and an inset door, with solid frame around it.
cab=[(-2.12,1.78),(-2.14,2.30),(-1.97,3.85),(-1.68,4.02),(-.43,4.02),(-.30,3.81),(-.30,1.80)]
profile("Cab frame",cab,1.08,1.35,graphite,.065)
for side in [-1,1]:
    px=1.08+side*.683
    profile("Door glass",[(-2.02,2.51),(-1.88,3.77),(-1.65,3.88),(-1.19,3.88),(-1.19,2.51)],px,.022,glass,.025)
    profile("Quarter glass",[(-1.12,2.51),(-1.12,3.88),(-.51,3.88),(-.42,3.72),(-.42,2.51)],px,.022,glass,.025)
box("Windshield",(1.08,-2.075,3.06),(1.18,.055,1.55),glass,.035).rotation_euler.x=-.105
box("Roof",(1.08,-1.18,4.03),(1.44,1.65,.13),graphite,.065)
for pos in [(1.65,-1.99,3.94),(.52,-1.99,3.94)]:
    box("Work light",pos,(.23,.12,.14),v.HEADLAMP)
for y in [.16,.98]:
    tube("Handrail upright",(1.77,y,2.92),(1.77,y,3.78),.033,graphite)
tube("Handrail",(1.77,.16,3.78),(1.77,.98,3.78),.034,graphite)

bx=-.12
profile("Boom", [(-.54,1.97),(-1.12,2.00),(-3.32,4.95),(-5.93,5.07),(-6.15,5.46),(-5.99,5.73),(-3.22,5.80),(-2.78,5.56)],bx,.64,graphite,.10)
profile("Dipper", [(-5.78,5.21),(-6.01,6.20),(-6.40,6.40),(-6.57,6.17),(-6.32,4.85),(-6.99,1.15),(-6.73,.98),(-6.48,1.28)],bx,.46,graphite,.065)
for x in [bx-.46,bx+.46]:
    hydraulic("Boom lift",x,(-1.8,1.99),(-3.02,4.88),.144)
hydraulic("Stick cylinder",bx,(-3.15,5.87),(-6.23,6.23),.135)
hydraulic("Bucket cylinder",bx,(-6.43,5.06),(-7.04,2.11),.12)
profile("Bucket bell crank",[(-6.99,2.25),(-7.16,2.11),(-7.05,1.24),(-6.69,1.03),(-6.62,1.20),(-6.89,1.45)],bx,.57,shoe)
for y,z,r in [(-.9,2.16,.25),(-6.01,5.43,.20),(-6.83,1.18,.17)]:
    disc("Hardened hinge pin",(bx,y,z),r,.79,shoe)
for x in [bx-.19,bx+.19]:
    line("High pressure hose",[(x,-.47,2.67),(x,-1.55,3.78),(x,-3.28,5.93),(x,-5.3,5.87),(x,-5.88,6.02),(x,-6.28,5.60),(x,-6.35,4.94)],.04,v.RUBBER)
# External bucket-cylinder feed and return run down the visible dipper cheek.
for side in [-1,1]:
    x = bx + side*.27
    line("Bucket circuit jumper",[(bx+side*.19,-5.85,6.00),(x,-6.06,6.10),
         (x,-6.30,5.91),(x,-6.22,5.59),(x,-6.23,5.30)],.027,v.RUBBER)
    tube("Swaged connector",(x,-6.23,5.32),(x,-6.25,5.22),.045,chrome)
    tube("Bucket feed pipe",(x,-6.25,5.23),(x,-6.43,4.30),.024,chrome)
    line("Cylinder port hose",[(x,-6.43,4.30),(x,-6.55,4.21),
         (bx+side*.14,-6.62,4.22),(bx+side*.09,-6.60,4.28)],.027,v.RUBBER)
    for y,z in [(-6.31,4.92),(-6.39,4.49)]:
        tube("Dipper pipe clip",(bx+side*.21,y,z),(x+side*.029,y,z),.043,shoe)
# Concave shell, closed cheeks and separate forged teeth. Mouth faces the machine.
outer=[(-7.05,1.34),(-7.34,1.15),(-7.49,.83),(-7.42,.49),(-7.15,.27),(-6.18,.22)]
inner=[(-6.18,.34),(-7.10,.38),(-7.31,.55),(-7.37,.82),(-7.25,1.04),(-6.99,1.22)]
profile("Digging bucket shell",outer+inner,bx,1.66,shoe,.025)
for side in [-1,1]:
    profile("Bucket cheek",outer+[(-6.47,.55),(-6.91,1.22)],bx+side*.83,.08,graphite,.028)
wear_steel = v.material("Abraded bucket steel", (.23,.22,.20), .69,.62)
for offset in [-.63,-.21,.21,.63]:
    profile("Heel wear runner",[(-7.51,.81),(-7.46,.47),(-7.17,.22),(-6.50,.193),
            (-6.46,.24),(-7.14,.28),(-7.41,.50),(-7.48,.84)],bx+offset,.16,wear_steel,.012)
for side in [-1,1]:
    for y,z in [(-7.25,.57),(-6.96,.45),(-6.65,.39)]:
        profile("Cheek wear plate",[(y-.09,z+.17),(y+.10,z+.18),(y+.145,z+.02),
                (y+.07,z-.10),(y-.13,z-.09),(y-.045,z+.02)],
                bx+side*.884,.04,wear_steel,.012)
for i in range(5):
    profile("Replaceable tooth",[(-6.35,.21),(-6.11,.17),(-5.88,.13),(-5.96,.23),(-6.20,.33)],bx+(i-2)*.34,.15,shoe,.015)
for side in [-1,1]:
    v.text_obj("Boom lettering","VOLVO",(bx+side*.327,-4.46-side*.59,5.34),.32,v.PAINT_WHITE,side=-side,root=root)

bpy.context.preferences.filepaths.save_version=0
v.export_vehicle(root, "volvo_ec950f.glb")
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR)/"VolvoEC950F.blend"))
