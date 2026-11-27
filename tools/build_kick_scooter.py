"""Compact city kick scooter. Blender +Y is the direction of travel."""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import attach, clear_scene, cube, cylinder, material, export_vehicle, profile_loft, SOURCE_DIR

clear_scene()
root = bpy.data.objects.new("ElectricKickScooter", None)
bpy.context.collection.objects.link(root)
charcoal = material("Graphite frame", (.065,.075,.085), .55,.30)
rubber = material("Rubber", (.018,.021,.025), .04,.75)
steel = material("Brushed axle", (.38,.42,.44), .82,.30)
orange = material("Amber reflector", (.95,.25,.018), .16,.22,.18)
red = material("Brake cable", (.62,.024,.022), .12,.43)
tail = material("Tail marker", (.82,.035,.025), .20,.18,.35)
white = material("Headlamp lens", (.85,.90,.92), .15,.15,.90)

def tube(name, start, end, radius, mat):
    a, b = Vector(start), Vector(end)
    part = cylinder(name,(a+b)*.5,radius,(b-a).length,mat,False,16,root)
    part.rotation_euler = (b-a).to_track_quat("Z","Y").to_euler()

def curved(name, points, radius, mat):
    shape = bpy.data.curves.new(name, "CURVE")
    shape.dimensions = "3D"
    shape.bevel_depth = radius
    shape.bevel_resolution = 2
    shape.resolution_u = 10
    spline = shape.splines.new("BEZIER")
    spline.bezier_points.add(len(points)-1)
    for knot, point in zip(spline.bezier_points,points):
        knot.co = point
        knot.handle_left_type = "AUTO"
        knot.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name,shape)
    bpy.context.collection.objects.link(obj)
    obj.parent = root
    shape.materials.append(mat)

# Origin at ground level; the rider stands on the top surface at 0.17 m.
cube("Die cast battery deck",(0,-.04,.121),(.31,.82,.087),charcoal,.042,root)
cube("Textured standing pad",(0,-.052,.166),(.282,.744,.016),rubber,.008,root)
for side in (-1,1):
    for lane in (1,2,3):
        cube("Grip rib",(side*.036*lane,-.068,.175),(.008,.62,.005),charcoal,.002,root)
    cube("Deck side reflector",(side*.157,-.30,.126),(.006,.069,.025),orange,.003,root)
tyre_section = [
    (-.031, .066), (-.032, .087), (-.031, .103), (-.028, .111),
    (-.023, .116), (-.017, .118), (-.013, .118), (-.011, .115),
    (-.008, .115), (-.006, .118), (.006, .118), (.008, .115),
    (.011, .115), (.013, .118), (.017, .118), (.023, .116),
    (.028, .111), (.031, .103), (.032, .087), (.031, .066),
]
for i, y in enumerate((.48,-.48)):
    axle = bpy.data.objects.new(("FrontWheel","RearWheel")[i],None)
    bpy.context.collection.objects.link(axle)
    axle.parent = root
    axle.location = (0,y,.118)
    bpy.context.view_layer.update()
    tyre_sections = []
    for index in range(65):
        angle = index*math.tau/64
        tyre_sections.append([
            (x, y+radius*math.cos(angle), .118+radius*math.sin(angle))
            for x, radius in tyre_section
        ])
    tyre = profile_loft("Road tyre", tyre_sections, rubber, None, close_ends=False)
    attach(tyre, axle)
    cylinder("Hub motor case",(0,y,.118),.079,.073,charcoal,True,36,axle)
    cylinder("Axle cover",(0,y,.118),.027,.087,steel,True,24,axle)
    for side in (-1,1):
        for slot in range(6):
            angle = slot*math.tau/6
            cube("Hub spoke",(side*.038,y+.049*math.sin(angle),.118+.049*math.cos(angle)),
                 (.007,.012,.028),steel,.003,axle).rotation_euler.x = -angle
        tube("Fork blade",(side*.049,y,.123),(side*.049,y-.032 if i==0 else -.33,.26 if i==0 else .132),.018,charcoal)
        cube("Axle reflector",(side*.062,y,.145),(.015,.071,.034),orange,.007,root)
# The rear rotor spins with the hub and the caliper sits on the trailing arm.
rotor_sections = []
for index in range(73):
    angle = index*math.tau/72
    outside = .092 + .003*math.cos(6*angle)
    rotor_sections.append([
        (x, -.48 + radius*math.cos(angle), .118 + radius*math.sin(angle))
        for x, radius in [(.044, .070), (.044, outside), (.049, outside), (.049, .070)]
    ])
rotor = profile_loft("Rear brake rotor", rotor_sections, steel, None, close_ends=False)
attach(rotor, axle)
caliper = cube("Rear brake caliper", (.056,-.425,.189), (.032,.045,.035),
               charcoal,.008,root)
caliper.rotation_euler.x = -.62
tube("Rear caliper stay",(.055,-.404,.181),(.049,-.365,.135),.009,charcoal)
cylinder("Rear caliper mounting bolt",(.074,-.425,.191),
         .006,.005,steel,True,6,root)

# Form one curved guard over each wheel from a strip of quads.
for y, first, last in ((-.48,-1.22,1.29),(.48,-.91,.86)):
    verts, faces = [], []
    for step in range(17):
        angle = first+(last-first)*step/16
        for width,height in ((-.05,0),(-.038,.008),(.038,.008),(.05,0)):
            verts.append((width,y+.14*math.sin(angle),.118+(.14+height)*math.cos(angle)))
        if step:
            for edge in range(3):
                a = 4*(step-1)+edge
                faces.append((a,a+1,a+5,a+4))
    mesh = bpy.data.meshes.new("Pressed mudguard")
    mesh.from_pydata(verts,[],faces)
    mesh.materials.append(charcoal)
    obj = bpy.data.objects.new("Wheel guard",mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = root
    for poly in mesh.polygons:
        poly.use_smooth = True
    shell = obj.modifiers.new("Moulded guard thickness", "SOLIDIFY")
    shell.thickness = .004
    shell.offset = 0
    angle = .60 if y > 0 else -.79
    attachment_y = y + .14*math.sin(angle)
    attachment_z = .118 + .141*math.cos(angle)
    for side in (-1, 1):
        support_x = side*.046
        tube("Mudguard support stay", (side*.053, y, .149),
             (support_x, attachment_y, attachment_z), .006, charcoal)
        fastener = cylinder("Mudguard stay fastener",
                            (support_x, attachment_y, attachment_z+.004),
                            .006, .005, steel, False, 12, root)
        fastener.rotation_euler.x = -angle
cube("Rear red marker",(0,-.606,.179),(.064,.018,.025),tail,.005,root)
tube("Deck neck",(0,.28,.13),(0,.448,.34),.047,charcoal)
tube("Handlebar tube",(0,.46,.25),(0,.387,1.275),.025,charcoal)
tube("Folding collar",(0,.454,.31),(0,.447,.38),.037,charcoal)
for side in (-1,1):
    cheek = cube("Folding hinge cheek",(side*.030,.447,.331),
                 (.015,.079,.081),charcoal,.012,root)
    cheek.rotation_euler.x = -.12
    cylinder("Hinge pivot washer",(side*.039,.446,.335),
             .017,.005,steel,True,24,root)
    cylinder("Hinge pivot head",(side*.043,.446,.335),
             .010,.006,steel,True,6,root)
tube("Folding latch catch",(0,.414,.372),(0,.384,.349),.011,steel)
cube("Folding latch lever",(0,.377,.328),(.036,.030,.069),steel,.009,root)
cube("Folding latch safety tab",(0,.359,.315),(.031,.011,.022),red,.004,root)
tube("Handlebar",( -.287,.387,1.275),(.287,.387,1.275),.016,charcoal)
for side in (-1,1):
    tube("Handle grip",(side*.158,.387,1.275),(side*.294,.387,1.275),.022,rubber)
    for ring in range(5):
        x = side*(.178+ring*.022)
        tube("Grip groove",(x-.002,.387,1.275),(x+.002,.387,1.275),.0229,charcoal)
cube("Display housing",(0,.385,1.286),(.072,.093,.033),rubber,.014,root)
cube("Lamp lens",(0,.435,1.27),(.044,.016,.026),white,.006,root)
tube("Brake lever",(-.159,.394,1.265),(-.266,.444,1.245),.008,steel)
curved("Red brake cable",[(-.15,.397,1.26),(-.08,.494,1.17),(.032,.50,.91),
                         (.032,.453,.54),(.038,.433,.35)],.0065,red)
export_vehicle(root,"electric_kick_scooter.glb")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"ElectricKickScooter.blend"))
