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


def line(name, points, radius, mat, handle_type="AUTO"):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.bevel_depth, curve.bevel_resolution = radius, 2
    spline = curve.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for knot, pos in zip(spline.bezier_points, points):
        knot.co = pos
        knot.handle_left_type = knot.handle_right_type = handle_type
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


worn_edge = v.material("Polished grouser edge", (.42,.43,.40), .74,.45)
for side in [-1,1]:
    x = side*1.48
    box("Track frame", (x,0,.69), (.66,4.28,.72), graphite,.12)
    for y in [-2.13,-1.52,-.92,-.31,.31,.92,1.52,2.13]:
        outer = abs(y)>2
        z, r = (.68,.49) if outer else (.46,.26)
        disc("Final drive" if outer else "Lower roller", (x,y,z), r,.66,graphite)
        disc("Bearing cover", (x+side*.34,y,z),r*.52,.055,shoe)
        if y == 2.13:
            disc("Final drive flange",(x+side*.37,y,z),.355,.045,shoe)
            disc("Final drive hub",(x+side*.41,y,z),.205,.065,graphite)
            for bolt in range(10):
                angle = tau*bolt/10
                v.cylinder("Final drive bolt",(x+side*.404,y+.30*cos(angle),z+.30*sin(angle)),
                           .032,.026,chrome,vertices=6,root=root)
        elif not outer:
            disc("Bearing dust cap",(x+side*.379,y,z),.083,.035,graphite)
    profile("Track roller guard",[(-1.77,.67),(-1.59,.87),(1.55,.87),(1.77,.68),
            (1.62,.54),(-1.57,.54)],x+side*.36,.065,graphite,.035)
    length = 8.52 + tau*.57
    parts = []
    for i in range(52):
        y,z,ang = track_frame(i*length/52)
        for name,depth,height,lift,mat in [("Track shoe",.224,.116,0,shoe),("Grouser",.052,.05,.07,v.METAL),("Wear edge",.036,.009,.096,worn_edge)]:
            obj=box(name,(x,y-lift*sin(ang),z+lift*cos(ang)),(.88,depth,height),mat,0)
            obj.rotation_euler.x=ang
            parts.append(obj)
        pin_y, pin_z, _ = track_frame((i+.5)*length/52)
        parts.append(v.cylinder("Track hinge pin",(x,pin_y,pin_z),.044,.91,shoe,vertices=12,root=root))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    parts[0].name = "Continuous crawler shoes "+str(side)

box("Cross carriage",(0,0,.96),(2.85,3.46,.64),graphite,.12)
v.cylinder("Swing bearing",(0,0,1.37),1.37,.32,shoe,axis_x=False,root=root)
box("Upper deck",(0,.18,1.64),(3.72,4.62,.34),graphite,.13)
# Yellow service doors meet a cast rear weight that wraps around both corners.
box("Engine service body",(0,.88,2.43),(3.67,1.52,1.42),gold,.095)
for x in [-.83,.83]:
    box("Service hatch gasket",(x,.87,3.15),(1.51,1.19,.036),v.RUBBER,.018)
    box("Service hatch lid",(x,.87,3.18),(1.47,1.15,.052),graphite,.025)
    for offset in [-.52,.52]:
        box("Hatch hinge",(x+offset,.30,3.21),(.17,.085,.06),shoe,.018)
    line("Hatch pull",[(x-.11,1.34,3.205),(x-.10,1.34,3.26),
         (x+.10,1.34,3.26),(x+.11,1.34,3.205)],.014,chrome)
box("Cooling intake recess",(-.83,.84,3.212),(1.16,.76,.022),v.BLACK,.01)
for row in range(9):
    box("Angled intake slat",(-.83,.50+.084*row,3.238),
        (1.12,.063,.024),shoe,.008).rotation_euler.x=.32
# The stack has an open bore and a rolled rim that catch the light from above.
stack = []
for z,r in [(3.204,.116),(3.27,.116),(3.28,.087),(3.63,.087),(3.64,.074),(3.42,.074)]:
    stack.append([(.90+r*cos(i*tau/24),.66+r*sin(i*tau/24),z) for i in range(24)])
v.profile_loft("Exhaust stack",stack,graphite,root)
outline = [(-1.84,1.52),(1.84,1.52),(1.84,1.83)]
for i in range(25):
    angle = i*pi/24
    outline.append((1.84*cos(angle),1.84+.84*sin(angle)))
rings = []
for z, scale in [(1.71,.94),(1.76,.985),(1.85,1),(2.78,1),(2.99,.986),(3.08,.95)]:
    rings.append([(x*scale,1.52+(y-1.52)*scale,z) for x,y in outline])
v.profile_loft("Rounded cast counterweight",rings,graphite,root)
reflector = v.material("Ruby reflector", (.66,.022,.012), .18,.28)
for side in [-1,1]:
    for z in [2.14,2.70]:
        line("Rear reflector",[(side*x,y,z+dz) for x,y,dz in
              [(1.26,2.458,0),(1.18,2.492,.04),(.94,2.573,.05)]],.031,reflector)
box("Engine access enclosure",(-.97,-.52,2.41),(1.6,1.84,1.32),graphite,.12)
for y in [-1.12,-.88,-.64,-.40,-.16]:
    box("Cooling grille",(-1.786,y,2.46),(.036,.095,.66),v.BLACK,.018)
for side in [-1,1]:
    for center_y in [.53,1.18]:
        box("Service door seal",(side*1.838,center_y,2.40),(.016,.626,1.12),v.RUBBER,.008)
        box("Enamel side hatch",(side*1.848,center_y,2.40),(.02,.604,1.09),gold,.009)
        latch_y = center_y + .20
        box("Flush latch pocket",(side*1.863,latch_y,2.47),(.014,.085,.11),graphite,.006)
        box("Quarter turn latch",(side*1.872,latch_y,2.47),(.013,.047,.018),chrome,.005)
    for row in range(6):
        z = 2.59 + row*.052
        box("Louvre opening",(side*1.862,1.18,z),(.012,.40,.029),v.BLACK,.005)
        box("Louvre lip",(side*1.87,1.18,z+.015),(.022,.40,.012),gold,.005)
    v.text_obj("Machine designation","HT-16",(side*1.865,.55-side*.22,2.22),.16,graphite,side=-side,root=root)
# A low sill and individual pillars leave a clear view through the cab.
next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .24
glass.diffuse_color = (.12,.29,.32,.24)
profile("Cab floor",[(-2.12,1.78),(-2.13,2.04),(-.30,2.04),(-.30,1.80)],1.08,1.35,graphite,.035)
box("Front kick panel",(1.08,-2.09,2.22),(1.34,.07,.46),graphite)
box("Rear seat plinth",(1.08,-.72,2.26),(1.32,.79,.47),graphite)
for side in [-1,1]:
    px=1.08+side*.683
    profile("Lower sight glass",[(-2.04,2.09),(-2.00,2.48),(-1.18,2.48),(-1.26,2.27),(-1.55,2.09)],px,.018,glass,.012)
    profile("Lower door skin",[(-1.55,2.04),(-1.21,2.25),(-1.13,2.50),(-.32,2.50),(-.32,2.04)],px,.045,graphite,.018)
    tube("Door waist rail",(px,-2.04,2.50),(px,-.36,2.50),.034,graphite)
door_x=1.79
line("Door perimeter seal",[(door_x,y,z) for y,z in
     [(-2.065,2.06),(-2.075,2.47),(-1.925,3.79),(-1.67,3.94),
      (-1.155,3.94),(-1.155,2.24),(-1.49,2.06),(-2.065,2.06)]],.017,v.RUBBER,handle_type="VECTOR")
box("Latch recess",(door_x,-1.28,2.58),(.05,.17,.08),v.RUBBER,.02)
tube("Door pull lever",(1.832,-1.35,2.59),(1.832,-1.22,2.59),.017,chrome)
for z in [2.38,3.30]:
    tube("Door hinge",(door_x,-2.06+(z-2.38)*.10,z),(door_x,-2.05+(z-2.38)*.10,z+.10),.024,graphite)
box("Rear window",(1.08,-.34,3.22),(1.23,.025,1.43),glass,.02)
fabric = v.material("Woven slate upholstery", (.17,.21,.23), 0,.93)
box("Suspension pedestal",(1.08,-1.04,2.58),(.40,.40,.20),graphite)
box("Seat cushion",(1.08,-1.11,2.73),(.53,.54,.15),fabric,.065)
box("Seat back",(1.08,-.88,3.01),(.52,.14,.57),fabric,.06).rotation_euler.x=-.12
box("Head restraint",(1.08,-.83,3.36),(.34,.14,.18),fabric,.05)
for side in [-1,1]:
    px=1.08+side*.683
    tube("Windshield pillar",(px,-2.08,2.42),(px,-1.92,3.97),.053,graphite)
    tube("Rear pillar",(px,-.34,2.43),(px,-.39,3.97),.054,graphite)
    tube("Door mullion",(px,-1.154,2.48),(px,-1.154,3.97),.033,graphite)
    x=1.08+side*.36
    box("Armrest console",(x,-1.14,2.78),(.14,.56,.17),graphite,.045)
    tube("Joystick shaft",(x,-1.36,2.84),(x,-1.41,3.00),.018,chrome)
    box("Joystick grip",(x,-1.42,3.04),(.070,.085,.11),v.RUBBER,.025)
    profile("Door glass",[(-2.02,2.51),(-1.88,3.77),(-1.65,3.88),(-1.19,3.88),(-1.19,2.51)],px,.022,glass,.025)
    profile("Quarter glass",[(-1.12,2.51),(-1.12,3.88),(-.51,3.88),(-.42,3.72),(-.42,2.51)],px,.022,glass,.025)
box("Windshield",(1.08,-2.075,3.06),(1.18,.055,1.55),glass,.035).rotation_euler.x=-.105
box("Roof seal",(1.08,-1.18,3.995),(1.45,1.66,.075),graphite,.035)
box("Cab roof",(1.08,-1.18,4.07),(1.48,1.7,.14),gold,.065)
amber = v.material("Amber warning lens", (1.0,.26,.015), .12,.22)
v.cylinder("Beacon rubber foot",(1.48,-.74,4.155),.10,.04,v.RUBBER,axis_x=False,root=root)
v.cylinder("Amber beacon",(1.48,-.74,4.24),.081,.14,amber,axis_x=False,root=root)
# One parked wiper follows the slope of the front glass.
tube("Wiper arm",(.60,-2.175,2.48),(1.21,-2.105,3.18),.012,graphite)
tube("Wiper blade",(.93,-2.135,2.93),(1.49,-2.081,3.43),.017,v.RUBBER)
for pos in [(1.65,-1.99,3.94),(.52,-1.99,3.94)]:
    box("Work light",pos,(.23,.12,.14),v.HEADLAMP)
box("Entry platform",(1.57,-2.27,1.67),(.58,.69,.14),graphite,.045)
for y in [-2.50,-2.40,-2.30,-2.20]:
    box("Step tread",(1.57,y,1.75),(.48,.027,.023),shoe,.008)
line("Entry grab rail",[(1.80,-2.54,1.73),(1.80,-2.54,2.52),
     (1.80,-2.51,2.60),(1.80,-2.45,2.63),(1.80,-2.22,2.63),
     (1.80,-2.16,2.59),(1.80,-2.15,2.52),(1.80,-2.15,1.73)],.028,gold)
tube("Mirror arm",(1.79,-2.40,2.29),(1.98,-2.48,2.33),.021,graphite)
tube("Mirror stalk",(1.98,-2.48,2.33),(1.98,-2.53,2.65),.019,graphite)
box("Mirror casing",(1.98,-2.53,2.70),(.17,.066,.30),v.RUBBER,.030)
mirror = v.material("Cool mirror glass", (.57,.66,.68), .88,.12)
box("Mirror face",(1.98,-2.493,2.70),(.14,.014,.26),mirror,.006)
for y in [.16,.98]:
    tube("Handrail upright",(1.77,y,2.92),(1.77,y,3.78),.033,graphite)
tube("Handrail",(1.77,.16,3.78),(1.77,.98,3.78),.034,graphite)

bx=-.12
boom_outline = [
    (-.54,1.97),(-1.12,2.00),(-2.58,4.13),(-2.82,4.45),(-3.04,4.69),
    (-3.26,4.86),(-3.48,4.96),(-3.76,5.02),(-5.92,5.19),
    (-6.10,5.28),(-6.19,5.44),(-6.13,5.62),(-5.98,5.72),
    (-3.58,5.82),(-3.31,5.81),(-3.10,5.75),(-2.90,5.64),
    (-2.71,5.46),(-2.50,5.19)
]
profile("Boom",boom_outline,bx,.64,graphite,.065)
profile("Dipper", [(-5.78,5.21),(-6.01,6.20),(-6.40,6.40),(-6.57,6.17),(-6.32,4.85),(-6.99,1.15),(-6.73,.98),(-6.48,1.28)],bx,.46,graphite,.065)
for x in [bx-.46,bx+.46]:
    hydraulic("Boom lift",x,(-1.8,1.99),(-3.02,4.88),.144)
hydraulic("Stick cylinder",bx,(-3.15,5.87),(-6.23,6.23),.135)
hydraulic("Bucket cylinder",bx,(-6.43,5.06),(-7.04,2.11),.12)
profile("Bucket bell crank",[(-6.99,2.25),(-7.16,2.11),(-7.05,1.24),(-6.69,1.03),(-6.62,1.20),(-6.89,1.45)],bx,.57,shoe)
wear_finish = v.material("Machined pivot steel", (.31,.32,.29),.72,.43)
for y,z,r in [(-.9,2.16,.25),(-6.01,5.43,.20),(-6.83,1.18,.17)]:
    disc("Hardened hinge pin",(bx,y,z),r,.79,shoe)
    for side in [-1,1]:
        disc("Hardened bearing collar",(bx+side*.362,y,z),r*1.18,.073,graphite)
        disc("Hardened thrust washer",(bx+side*.401,y,z),r*.90,.022,wear_finish)
        box("Hardened keeper plate",(bx+side*.424,y+.08*r,z),(.032,r*1.27,r*.38),shoe,.012)
        for offset in [-.34,.49]:
            v.cylinder("Hardened keeper bolt",(bx+side*.448,y+offset*r,z),
                       r*.133,.024,chrome,vertices=6,root=root)
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
# Tapered scuffs follow the floor and back wall where material slides out.
# A single mesh keeps the marks attached to the shell in the game rig.
def bucket_scuffs():
    from random import Random
    rng = Random(48)
    vertices, faces = [], []
    for _ in range(52):
        x = bx + rng.uniform(-.76,.76)
        start = rng.uniform(.13,2.65)
        end = min(start + rng.uniform(.22,1.65),4.6)
        stops = [start] + [k for k in range(1,5) if start < k < end] + [end]
        stops.insert(1,(stops[0]+stops[1])*.5)
        width = rng.uniform(.002,.012)
        first = len(vertices)
        for index,t in enumerate(stops):
            segment = int(t)
            y,z = inner[segment]
            dy,dz = inner[segment+1]
            fraction = t-segment
            y += (dy-y)*fraction + .004
            z += (dz-z)*fraction + .004
            spread = width*(.12 if index in [0,len(stops)-1] else 1)
            drift = .009*sin(t*2+x*13)
            vertices.extend([(x+drift-spread,y,z),(x+drift+spread,y,z)])
            if index:
                k = first+2*index
                faces.append((k-2,k,k+1,k-1))
    mesh = bpy.data.meshes.new("Bucket abrasion ribbons")
    mesh.from_pydata(vertices,[],faces)
    mesh.materials.append(v.material("Scraped shell steel", (.24,.23,.21), .64,.56))
    marks = bpy.data.objects.new("Digging bucket scuffs",mesh)
    bpy.context.collection.objects.link(marks)
    marks.parent = root

bucket_scuffs()
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
polished = v.material("Ground cutting steel", (.36,.34,.29), .78,.36)
profile("Digging edge bevel",[(-6.38,.22),(-6.17,.20),(-6.10,.22),
        (-6.20,.30),(-6.38,.32)],bx,1.68,polished,.009)
for i in range(5):
    x = bx+(i-2)*.34
    profile("Replaceable tooth socket",[(-6.44,.23),(-6.20,.19),(-6.08,.23),
            (-6.19,.34),(-6.42,.36)],x,.22,wear_steel,.018)
    rings = []
    for y,half_width,low,high in [(-6.22,.084,.19,.31),(-6.05,.08,.16,.25),
                                  (-5.97,.069,.145,.209),(-5.88,.050,.132,.15)]:
        rings.append([(x-half_width,y,low),(x+half_width,y,low),
                      (x+half_width,y,high),(x-half_width,y,high)])
    tooth = v.profile_loft("Replaceable tapered tooth", rings, shoe, root)
    tooth.data.materials.append(polished)
    for face in tooth.data.polygons:
        face.use_smooth = False
        if face.center.y > -5.97:
            face.material_index = 1
for side in [-1,1]:
    v.text_obj("Boom lettering","HT-16",(bx+side*.327,-4.46-side*.59,5.34),.32,v.PAINT_WHITE,side=-side,root=root)

bpy.context.preferences.filepaths.save_version=0
v.export_vehicle(root, "volvo_ec950f.glb")
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR)/"VolvoEC950F.blend"))
