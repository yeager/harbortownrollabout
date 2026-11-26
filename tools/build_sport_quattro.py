"""Build the 1984 Sport quattro road car in metres for Godot."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import attach, clear_scene, cube, cylinder, export_vehicle, material, mesh_from_rings, profile_loft, text_obj

PROJECT = Path(__file__).resolve().parents[1]
AXLES = (-1.112, 1.112)
ARCH_HALF_LENGTH = .351
ARCH_RISE = .423


def build():
    clear_scene()
    root = bpy.data.objects.new("Audi Sport quattro", None)
    bpy.context.collection.objects.link(root)
    red = material("Tornado red enamel", (.67, .021, .031), .26, .23)
    next(node for node in red.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Coat Weight"].default_value = .45
    trim = material("Satin black ABS", (.022, .024, .028), .08, .42)
    recess = material("Dark grille recess", (.008, .010, .012), .05, .73)
    rubber = material("Carbon black tyre rubber", (.012, .014, .017), .0, .82)
    alloy = material("Warm silver painted alloy", (.62, .60, .54), .47, .26)
    chrome = material("Polished metal", (.64, .69, .74), .86, .19)
    lamp = material("Headlamp reflector glass", (.67, .72, .69), .32, .20, .13)
    lens = material("Clear pressed headlamp glass", (.83, .91, .92), .05, .18)
    next(node for node in lens.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .31
    amber = material("Amber indicator lens", (.92, .33, .025), .08, .25, .13)
    ruby = material("Tail lamp red smoked lens", (.32, .018, .021), .13, .25, .1)
    clear = material("Reverse lamp prism", (.20, .24, .25), .12, .22)
    smoked_amber = material("Smoked amber tail lens", (.15, .070, .021), .13, .26)
    smoked_ruby = material("Smoked red reflector", (.17, .021, .024), .12, .30)
    glass = material("Blue-green laminated glazing", (.17, .33, .39), .13, .13)
    glass.diffuse_color = (.17, .33, .39, .35)
    next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .35
    cloth = material("Charcoal seat cloth", (.069, .074, .076), 0, .91)
    leather = material("Graphite leather bolsters", (.104, .109, .114), 0, .63)
    carpet = material("Dark woven floor", (.027, .030, .031), 0, .94)
    marking = material("Cream gauge markings", (.72, .75, .66), 0, .56, .10)

    def box(name, at, size, mat=trim, bevel=.012, parent=root):
        return cube(name, at, size, mat, bevel, parent)

    def bar(name, a, b, width, depth, mat, parent=root):
        a, b = Vector(a), Vector(b)
        item = box(name, (a+b)/2, (width, (b-a).length, depth), mat, min(width, depth)*.24, parent)
        item.rotation_euler = (b-a).to_track_quat('Y', 'Z').to_euler()
        return item

    def polygon(name, points, mat, thickness=.008):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(points, [], [tuple(range(len(points)))])
        mesh.update()
        node = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(node)
        mesh.materials.append(mat)
        solid = node.modifiers.new("Panel thickness", 'SOLIDIFY')
        solid.thickness = thickness
        solid.offset = 0
        return attach(node, root)

    def glazed_opening(name, corners, outward, seal_width):
        outer = [Vector(p) for p in corners]
        normal = Vector(outward).normalized()
        center = sum(outer, Vector()) / len(outer)
        inner = []
        for i, p in enumerate(outer):
            before = (p-outer[i-1]).normalized()
            after = (outer[(i+1) % len(outer)]-p).normalized()
            n1 = normal.cross(before).normalized()
            n2 = normal.cross(after).normalized()
            if n1.dot(center-p) < 0:
                n1, n2 = -n1, -n2
            inner.append(p + (n1+n2) * seal_width / (1+n1.dot(n2)))
        polygon(name+" glass", inner, glass, .006)
        raised_outer = [p+normal*.007 for p in outer]
        raised_inner = [p+normal*.004 for p in inner]
        mesh = bpy.data.meshes.new(name+" continuous gasket")
        size = len(outer)
        mesh.from_pydata(raised_outer+raised_inner, [], [
            (i,(i+1)%size,(i+1)%size+size,i+size) for i in range(size)
        ])
        mesh.update()
        seal = bpy.data.objects.new(name+" rubber gasket",mesh)
        bpy.context.collection.objects.link(seal)
        mesh.materials.append(rubber)
        solid = seal.modifiers.new("Gasket depth","SOLIDIFY")
        solid.thickness = .012
        edge = seal.modifiers.new("Rounded gasket shoulders","BEVEL")
        edge.width = .0025
        edge.segments = 3
        attach(seal,root)

    stations = [
        (-2.032,.789,.195,.739,.779), (-1.89,.85,.198,.771,.806),
        (-1.48,.886,.220,.788,.841), (-1.11,.895,.222,.801,.86),
        (-.70,.854,.213,.810,.897), (-.35,.831,.206,.819,.913),
        (.40,.833,.209,.831,.899), (.72,.871,.220,.837,.893),
        (1.12,.895,.223,.840,.887), (1.45,.885,.224,.834,.881),
        (1.82,.859,.243,.825,.867), (2.023,.812,.264,.797,.839),
    ]
    cuts = {row[0] for row in stations} | {-.66, -.52, 1.13, 1.30}
    for axle in AXLES:
        cuts.update(axle + ARCH_HALF_LENGTH*math.cos(math.pi*i/28) for i in range(29))

    def sample(y):
        for a, b in zip(stations, stations[1:]):
            if a[0] <= y <= b[0]:
                ratio = (y-a[0])/(b[0]-a[0])
                return [v+(w-v)*ratio for v,w in zip(a,b)]
        return stations[-1]

    def lower_section(y, width, bottom, shoulder, crown):
        distance = min(abs(y-axle) for axle in AXLES)
        arch = math.sqrt(max(0.0, 1-(distance/ARCH_HALF_LENGTH)**2))
        lip = bottom + arch*ARCH_RISE
        belt = shoulder - .085
        # The outer edge rolls inward at the tyres and follows the sill as
        # the arch tapers into the door. Keep the upper crease continuous.
        flare = arch*.024
        lip_width = width*.957 + flare
        ramp = min(lip+.062, belt-.035)
        left = [
            (-lip_width+.044,y,lip+.014), (-lip_width+.011,y,lip),
            (-lip_width,y,lip+.014), (-lip_width+.002,y,lip+.027),
            (-width*.975-flare*.33,y,ramp),
            (-width*.986,y,belt-.012), (-width,y,belt),
            (-width*.984,y,belt+.030), (-width*.965,y,shoulder-.012),
            (-width*.925,y,shoulder), (-width*.71,y,crown-.007),
        ]
        # Drop the inner surface behind the cowl to form the passenger tub.
        cabin = min(1.0, max(0.0, (y+.66)/.14), max(0.0, (1.30-y)/.17))
        cabin_floor = crown + (.312-crown)*cabin
        left.append((-width*.68,y,cabin_floor))
        return left+[(0,y,cabin_floor)]+[(-x,y,z) for x,y,z in reversed(left)]

    body = mesh_from_rings("Sculpted body and open wheel arches", [sample(y) for y in sorted(cuts)], red, root, bevel=.012, section=lower_section)
    body_surface = body.evaluated_get(bpy.context.evaluated_depsgraph_get())

    def door_seam(name, side, top, bottom):
        vertices = []
        samples = 160
        clearance = Vector((side * .0012, 0, 0))
        for step in range(samples + 1):
            y, z = Vector(top).lerp(Vector(bottom), step / samples)
            for offset in [-.0018, .0018]:
                hit, point, _, _ = body_surface.ray_cast(
                    (side * 1.2, y + offset, z), (-side, 0, 0))
                if not hit:
                    raise ValueError(f"{name} lost the body surface at {y:.3f}, {z:.3f}")
                # Keep the projected strip outside the metal through the crease.
                vertices.append(point + clearance)
        faces = [(i, i + 1, i + 3, i + 2) for i in range(0, len(vertices) - 2, 2)]
        if side == 1:
            faces = [face[::-1] for face in faces]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        mesh.materials.append(recess)
        node = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(node)
        attach(node, root)

    box("Recessed underbody", (0,0,.187), (1.22,3.75,.13), recess, .035)
    bottom_front = (.759,-.65,.886)
    top_front = (.632,-.155,1.311)
    top_rear = (.628,.650,1.317)
    bottom_rear = (.770,1.49,.875)

    def mirrored(p):
        return (-p[0],p[1],p[2])

    glazed_opening("Raked windshield", [mirrored(bottom_front),bottom_front,top_front,mirrored(top_front)], (0,-.425,.495), .023)
    glazed_opening("Hatch", [bottom_rear,mirrored(bottom_rear),mirrored(top_rear),top_rear], (0,.442,.84), .024)
    for i in range(1,9):
        point = Vector(bottom_rear).lerp(Vector(top_rear),i/10)
        bar("Rear window heating trace",(-point.x+.035,point.y-.004,point.z-.008),(point.x-.035,point.y-.004,point.z-.008),.0015,.0018,trim)
    hatch_normal = Vector((0, .442, .84)).normalized()
    lower_glass = Vector((0, bottom_rear[1], bottom_rear[2]))
    upper_glass = Vector((0, top_rear[1], top_rear[2]))
    pivot = lower_glass.lerp(upper_glass, .03) + Vector((.12, 0, 0))
    spindle = cylinder("Rear wiper spindle cap", pivot + hatch_normal * .010,
                       .024, .022, trim, axis_x=False, vertices=24, root=root)
    spindle.rotation_euler = hatch_normal.to_track_quat('Z', 'Y').to_euler()
    blade_mount = lower_glass.lerp(upper_glass, .22) + Vector((-.19, 0, 0))
    bar("Rear wiper arm", pivot + hatch_normal * .024,
        blade_mount + hatch_normal * .019, .018, .013, trim)
    blade_start = blade_mount + Vector((-.18, 0, 0))
    blade_end = blade_mount + Vector((.18, 0, 0))
    bar("Rear wiper blade carrier", blade_start + hatch_normal * .013,
        blade_end + hatch_normal * .013, .014, .011, trim)
    bar("Rear wiper rubber edge", blade_start + hatch_normal * .006,
        blade_end + hatch_normal * .006, .007, .006, rubber)
    mesh_from_rings("Painted roof skin", [
        (-.174,.65,1.299,1.311,1.326),(-.07,.661,1.305,1.317,1.343),
        (.58,.658,1.306,1.319,1.345),(.688,.647,1.296,1.31,1.328),
    ], red, root, bevel=.009, section=lambda y,w,b,s,c: [(-w,y,b),(-w,y,s),(-w*.76,y,c-.007),(0,y,c),(w*.76,y,c-.007),(w,y,s),(w,y,b)])
    for side in [-1,1]:
        def on_side(point):
            x,y,z = point
            return (side*x,y,z)

        a,b,c,d = map(on_side, (bottom_front,top_front,top_rear,bottom_rear))
        quarter_tail = on_side((.751,1.202,.882))
        quarter_top = on_side((.642,.488,1.302))
        divider_top = Vector(b).lerp(Vector(quarter_top),.605)
        divider_bottom = Vector(a).lerp(Vector(quarter_tail),.545)
        outward = (side,0,.31)
        glazed_opening("Door window",[a,b,divider_top,divider_bottom],outward,.016)
        glazed_opening("Fixed quarter window",[divider_bottom,divider_top,quarter_top,quarter_tail],outward,.017)
        polygon("Painted C pillar", [quarter_tail,quarter_top,c,d], red,.027)
        bar("Painted A pillar",a,b,.046,.025,red)
        bar("Roof drip rail",b,c,.019,.022,trim)
        bar("Beltline weatherstrip",a,quarter_tail,.015,.021,trim)
        bar("B pillar",divider_top,divider_bottom,.022,.023,trim)
        door_seam("Door front shut line", side, (-.656,.796), (-.525,.253))
        door_seam("Door rear shut line", side, (.361,.810), (.414,.253))
        box("Door handle gasket", (side*.840,.246,.749), (.026,.146,.042), rubber,.009)
        box("Door handle inset", (side*.852,.238,.750), (.008,.121,.030), recess,.006)
        box("Door handle pull", (side*.858,.226,.754), (.015,.091,.019), trim,.005)
        lock = cylinder("Door lock barrel", (side*.853,.299,.748), .009,.013,
                        chrome, axis_x=True, vertices=20, root=root)
        box("Door lock key slot", (lock.location.x + side*.007,.299,.748),
            (.002,.008,.0025), recess,.001)
        box("Painted rocker trim", (side*.805,-.051,.239), (.069,.99,.059), red)
        box("Door mirror mounting gasket", (side*.763,-.562,.917),
            (.023,.117,.076), rubber,.010)
        bar("Door mirror support", (side*.760,-.568,.919),
            (side*.827,-.568,.946), .042,.050,trim)
        box("Door mirror housing", (side*.854,-.587,.951),
            (.167,.129,.098),trim,.021)
        box("Door mirror inset glass", (side*.854,-.518,.951),
            (.132,.006,.067),chrome,.007)
        for edge in [-1, 1]:
            box("Door mirror horizontal bezel", (side*.854,-.516,.951 + edge*.039),
                (.149,.018,.012),trim,.004)
            box("Door mirror vertical bezel", (side*.854 + edge*.073,-.516,.951),
                (.012,.018,.071),trim,.004)
        box("Quarter intake dark well", (side*.860,.685,.420),
            (.024,.155,.173), recess,.008)
        for edge in [-1, 1]:
            box("Quarter intake end frame", (side*.875,.685 + edge*.073,.420),
                (.013,.010,.165),trim,.003)
            box("Quarter intake top and bottom frame", (side*.875,.685,.420 + edge*.080),
                (.013,.146,.010),trim,.003)
        for i in range(5):
            fin = box("Quarter intake angled fin", (side*.872,.633 + i*.026,.420),
                      (.015,.009,.151),trim,.002)
            fin.rotation_euler.z = side * math.radians(24)
        for i in range(3):
            box("Rear pillar vent", (side*.851,1.571,.826+i*.019), (.014,.24,.008),trim,.002)
        for i, axle in enumerate(AXLES):
            x = side*(.758 if i == 0 else .746)
            shoulder = [(0, .293), (.023, .293), (.026, .287), (.031, .287),
                        (.034, .293), (.064, .293), (.067, .287), (.073, .287),
                        (.076, .292), (.089, .289), (.098, .281), (.103, .266),
                        (.104, .245), (.098, .205)]
            profile = [(-offset, radius) for offset, radius in reversed(shoulder[1:])] + shoulder
            rings = [
                [(x + offset, axle + radius * math.sin(angle * math.tau / 64),
                  .293 + radius * math.cos(angle * math.tau / 64)) for angle in range(64)]
                for offset, radius in profile
            ]
            wheel = profile_loft("Performance tire", rings, rubber, root)
            for radius, depth in [(.269, .102), (.279, .099)]:
                bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=6,major_radius=radius,minor_radius=.0018,location=(x+side*depth,axle,.293),rotation=(0,math.pi/2,0))
                bead = bpy.context.object
                bead.name = "Moulded sidewall line"
                bead.data.materials.append(rubber)
                attach(bead,wheel)
            cylinder("Wheel hub dark barrel", (x+side*.107,axle,.293), .220,.031,recess,vertices=64,root=wheel)
            cylinder("Wheel hub outer alloy", (x+side*.116,axle,.293), .214,.026,alloy,vertices=64,root=wheel)
            cylinder("Wheel hub recessed bowl", (x+side*.132,axle,.293), .181,.012,recess,vertices=64,root=wheel)
            cylinder("Wheel hub center", (x+side*.147,axle,.293), .076,.030,alloy,root=wheel)
            for j in range(15):
                theta = j*math.tau/15
                spoke = box("Wheel spoke",(x+side*.143,axle+.126*math.cos(theta),.293+.126*math.sin(theta)),(.026,.119,.025),alloy,.007,wheel)
                spoke.rotation_euler.x = theta
            valve_angle = math.pi / 15
            valve_direction = Vector((0, math.cos(valve_angle), math.sin(valve_angle)))
            valve_base = Vector((x + side*.135, axle, .293)) + valve_direction * .198
            valve_tip = valve_base - valve_direction * .019 + Vector((side*.009, 0, 0))
            valve_axis = (valve_tip - valve_base).normalized()
            valve = cylinder("Tyre valve stem", (valve_base + valve_tip) / 2,
                             .0045, (valve_tip - valve_base).length, rubber,
                             axis_x=False, vertices=12, root=wheel)
            valve.rotation_euler = valve_axis.to_track_quat('Z', 'Y').to_euler()
            valve_cap = cylinder("Tyre valve cap", valve_tip, .0055,.008, trim,
                                 axis_x=False, vertices=12, root=wheel)
            valve_cap.rotation_euler = valve.rotation_euler
            for j in range(5):
                theta = j*math.tau/5
                cylinder("Wheel bolt", (x+side*.163, axle+.043*math.cos(theta),.293+.043*math.sin(theta)), .009,.011,chrome,vertices=12,root=wheel)
            cylinder("Center cap", (x+side*.163, axle,.293), .026,.012,trim,root=wheel)
        x = side*.344
        box("Leather seat base", (x,.09,.464), (.446,.469,.107),leather,.045)
        box("Cloth cushion insert", (x,.082,.510), (.28,.394,.032),cloth,.013)
        for dx in [-.164,.164]:
            box("Raised cushion bolster", (x+dx,.091,.521), (.103,.419,.078),leather,.037)
            bar("Backrest side bolster", (x+dx,.203,.542),(x+dx,.283,.908),.106,.082,leather)
        back = box("Leather sport seat back", (x,.267,.733), (.421,.123,.440),leather,.052)
        back.rotation_euler.x = -.16
        insert = box("Cloth backrest insert", (x,.200,.734), (.269,.035,.343),cloth,.019)
        insert.rotation_euler.x = -.16
        for height in [.644,.702,.760,.818]:
            box("Seat insert seam", (x,.174+(height-.644)*.16,height), (.240,.005,.003),trim,.001)
        for dx in [-.085,.085]:
            box("Headrest side frame",(x+dx,.316,.993),(.047,.086,.149),leather,.018)
        for height in [.932,1.053]:
            box("Headrest crossbar",(x,.316,height),(.198,.085,.039),leather,.016)
        box("Interior door card",(side*.600,-.072,.667),(.071,.88,.244),leather,.029)
        box("Door armrest",(side*.548,.030,.668),(.082,.349,.060),trim,.022)
        box("Interior door cloth insert", (side*.560,-.010,.728),
            (.022,.54,.077),cloth,.012)
        box("Interior release surround", (side*.542,-.235,.735),
            (.025,.105,.042),recess,.010)
        box("Interior door release", (side*.526,-.243,.737),
            (.015,.062,.017),chrome,.004)
        cylinder("Window crank base", (side*.543,-.347,.659), .021,.031,
                 trim, vertices=24, root=root)
        crank_pivot = (side*.520,-.347,.659)
        crank_end = (side*.514,-.301,.618)
        bar("Window crank arm", crank_pivot, crank_end, .013,.015,trim)
        cylinder("Window crank knob", crank_end, .012,.023,trim,
                 vertices=20, root=root)
        box("Door pocket bottom", (side*.544,.062,.558),
            (.068,.436,.026),trim,.007)
        box("Door pocket lip", (side*.510,.062,.580),
            (.017,.436,.052),leather,.009)
        for pocket_y in [-.15, .274]:
            box("Door pocket end", (side*.543,pocket_y,.578),
                (.074,.018,.048),leather,.005)

    for index, x in enumerate([-.563,.082]):
        spindle = (x,-.621,.925)
        pivot = bpy.data.objects.new(f"QuattroWiperPivot_{index}",None)
        bpy.context.collection.objects.link(pivot)
        pivot.location = spindle
        attach(pivot,root)
        box("Wiper spindle shroud",spindle,(.048,.030,.036),trim,.010)
        bar("Wiper linkage",spindle,(x+.277,-.601,.943),.014,.014,trim,pivot)
        bar("Spring blade carrier",(x+.146,-.597,.949),(x+.415,-.586,.959),.017,.009,trim,pivot)
        bar("Wiper rubber edge",(x+.140,-.597,.944),(x+.426,-.586,.954),.009,.006,rubber,pivot)
    box("Carpeted floor", (0,.32,.334), (1.23,1.95,.034),carpet,.013)
    for side in [-1,1]:
        box("Lower kick trim",(side*.549,-.256,.448),(.041,.54,.175),carpet,.018)
    for side in [-1, 1]:
        outline = [(side*x, y, .354) for x, y in [
            (.174,-.486), (.215,-.565), (.485,-.565), (.520,-.506),
            (.520,-.137), (.482,-.109), (.199,-.109), (.174,-.142),
        ]]
        polygon("Shaped rubber floor mat", outline, rubber, .006)
        for start, end in zip(outline, outline[1:] + outline[:1]):
            bar("Floor mat perimeter bead", Vector(start) + Vector((0,0,.004)),
                Vector(end) + Vector((0,0,.004)), .008,.005,rubber)
        for row in range(10):
            box("Floor mat grip rib", (side*.348,-.455 + row*.032,.358),
                (.270,.007,.004),rubber,.001)
    box("Pedal bracket crossmember", (.35,-.583,.580), (.236,.045,.041),trim,.006)
    # Driver left, from the seated viewpoint looking along Blender -Y.
    for name, x, width, height, ribs in [
        ("Clutch", .44, .046, .052, 4),
        ("Brake", .35, .050, .052, 4),
        ("Accelerator", .26, .032, .077, 6),
    ]:
        pad_center = Vector((x, -.524, .432))
        cylinder(name + " pedal pivot", (x,-.567,.575), .012,.024,
                 alloy, vertices=16, root=root)
        bar(name + " pedal lever", (x,-.567,.575), (x,-.533,.434),
            .013,.016,trim)
        box(name + " pedal backing plate", pad_center + Vector((0,-.009,0)),
            (width,.012,height),alloy,.005)
        box(name + " pedal rubber pad", pad_center,
            (width-.004,.013,height-.004),rubber,.005)
        for row in range(ribs):
            row_height = (row - (ribs - 1) / 2) * (height - .018) / (ribs - 1)
            box(name + " pedal grip rib", pad_center + Vector((0,.007,row_height)),
                (width-.011,.004,.004),rubber,.001)
    box("Dashboard", (0,-.465,.785), (1.42,.363,.108),trim,.043)
    wheel_center = Vector((.346, -.150, .858))
    # The top of the rim leans toward the dashboard (Blender -Y).
    wheel_tilt = math.radians(107)
    bpy.ops.mesh.primitive_torus_add(
        major_segments=64, minor_segments=12, major_radius=.146, minor_radius=.015,
        location=wheel_center, rotation=(wheel_tilt, 0, 0))
    steering = bpy.context.object
    steering.name = "Steering wheel rim"
    steering.data.materials.append(trim)
    for face in steering.data.polygons:
        face.use_smooth = True
    attach(steering, root)
    hub = box("Steering wheel hub", wheel_center, (.115,.064,.042),trim,.013)
    hub.rotation_euler.x = wheel_tilt
    for offset in [-.100, .100]:
        spoke = box("Steering wheel spoke", wheel_center + Vector((offset, 0, 0)),
                    (.109,.024,.027),trim,.004)
        spoke.rotation_euler.x = wheel_tilt
    box("Instrument binnacle",(.346,-.478,.856),(.312,.122,.079),trim,.022)
    def dial(name, x, y, z, radius, speedometer=False):
        bezel = cylinder(name+" rim",(x,y,z),radius,.011,trim,axis_x=False,vertices=32,root=root)
        bezel.rotation_euler.x = math.pi/2
        disk = cylinder(name+" face",(x,y+.006,z),radius*.86,.004,recess,axis_x=False,vertices=32,root=root)
        disk.rotation_euler.x = math.pi/2
        for tick in range(13):
            angle = math.radians(-126+tick*21)
            dx, dz = math.sin(angle), math.cos(angle)
            bar("Gauge tick",(x+dx*radius*.67,y+.009,z+dz*radius*.67),(x+dx*radius*.82,y+.009,z+dz*radius*.82),.0017,.0018,marking)
        spindle = (x,y+.012,z)
        pointer_root = root
        if speedometer:
            pointer_root = bpy.data.objects.new("QuattroSpeedNeedle",None)
            bpy.context.collection.objects.link(pointer_root)
            pointer_root.location = spindle
            attach(pointer_root,root)
            for speed, angle in [(0,-126),(80,-42),(160,42),(240,126)]:
                theta = math.radians(angle)
                dx, dz = math.sin(theta), math.cos(theta)
                number = text_obj("Speed scale numeral",str(speed),(x+dx*radius*.50+.003,y+.011,z+dz*radius*.50-.002),.006,marking,root=root,flat=True)
                number.rotation_euler.z = math.pi
        bar("Gauge needle",spindle,(x-radius*.63,y+.012,z-radius*.458),.003,.002,red,pointer_root)

    column_axis = Vector((0, -math.sin(wheel_tilt), math.cos(wheel_tilt)))
    for name, start, end, radius, finish in [
        ("Steering column shroud", .058, .278, .032, trim),
        ("Steering column collar", .047, .063, .034, rubber),
        ("Steering shaft at hub", .014, .060, .019, trim),
    ]:
        piece = cylinder(name, wheel_center + column_axis * ((start + end) / 2),
                         radius, end - start, finish, axis_x=False, vertices=32, root=root)
        piece.rotation_euler.x = wheel_tilt
    dial("Speedometer",.412,-.412,.861,.040,speedometer=True)
    dial("Main instrument",.287,-.412,.861,.040)
    box("Centre stack",(.003,-.332,.640),(.294,.238,.299),trim,.027)
    for x in [-.059,.063]:
        box("Centre air vent",(x,-.208,.748),(.103,.012,.047),recess,.005)
        for j in range(4):
            box("Vent louvre",(x,-.201,.733+j*.010),(.091,.004,.003),leather,.001)
    box("Cassette radio",(.003,-.206,.683),(.227,.017,.038),recess,.004)
    box("Cassette slot",(.002,-.195,.688),(.113,.004,.007),trim,.001)
    for x in [-.073,0,.073]:
        dial("Auxiliary gauge",x,-.205,.617,.026)
    box("Transmission tunnel",(0,.068,.422),(.251,.866,.162),trim,.038)
    box("Gear shift gaiter",(0,-.039,.512),(.147,.138,.077),leather,.033)
    bar("Gear lever",(0,-.039,.535),(.006,-.006,.655),.012,.013,chrome)
    box("Gear knob",(.006,-.006,.655),(.055,.052,.052),trim,.021)
    bar("Handbrake",(.081,.265,.495),(.081,.107,.576),.030,.030,trim)
    box("Rear bench", (0,.728,.533), (1.24,.492,.155),cloth,.045)
    box("Front black grille frame",(0,-2.006,.650),(1.675,.103,.246),trim,.036)
    box("Deep grille opening",(0,-2.063,.655),(1.112,.016,.191),recess,.004)
    for i in range(8):
        box("Horizontal grille slat",(0,-2.074,.574+i*.023),(1.084,.016,.009),trim,.002)
    for i in range(5):
        box("Grille upright",(i*.181-.362,-2.070,.657),(.008,.014,.187),trim,.002)
    for i in range(5):
        bpy.ops.mesh.primitive_torus_add(major_segments=28,minor_segments=8,major_radius=.033,minor_radius=.0035,location=((i-2)*.049,-2.086,.656),rotation=(math.pi/2,0,0))
        ring = bpy.context.object
        ring.name = "Polished grille ring"
        ring.data.materials.append(chrome)
        attach(ring,root)
    box("Front painted bumper", (0,-2.001,.431), (1.702,.154,.197), red,.034)
    box("Deep front valance", (0,-1.968,.282), (1.626,.172,.132), red,.028)
    for side in [-1,1]:
        x = side*.686
        box("Headlamp pocket", (x,-2.063,.650), (.271,.025,.192), recess,.017)
        # The glass sits behind its surrounding gasket, over a separate
        # stepped reflector with a warm central bulb.
        for z in [.563,.737]:
            box("Horizontal headlamp gasket", (x,-2.085,z), (.253,.020,.019),trim,.006)
        for dx in [-.118,.118]:
            box("Vertical headlamp gasket", (x+dx,-2.085,.650), (.019,.020,.171),trim,.006)
        box("Headlamp reflector", (x,-2.074,.650), (.212,.012,.143),lamp,.017)
        box("Upper reflector facet", (x,-2.080,.706), (.183,.006,.016),chrome,.005)
        box("Lower reflector facet", (x,-2.080,.594), (.183,.006,.016),chrome,.005)
        box("Halogen bulb", (x,-2.082,.650), (.039,.007,.035),lamp,.015)
        box("Headlight lens", (x,-2.088,.650), (.221,.008,.153),lens,.014)
        for i in range(15):
            box("Refraction ridge", (x-.097+i*.0139,-2.090,.650), (.0018,.003,.126),lens,.0004)
        box("Front amber indicator", (side*.740,-2.083,.440), (.164,.025,.095),amber,.012)
        for i in range(8):
            box("Indicator lens flute", (side*.740-.061+i*.0174,-2.098,.440), (.002,.003,.069),amber,.0006)
        x = side*.674
        box("Wraparound rear lamp housing",(x,2.030,.662),(.303,.074,.207),trim,.026)
        for z, finish in [(.713,ruby),(.662,smoked_amber),(.611,clear)]:
            box("Inset tail lens",(x,2.066,z),(.245,.012,.038),finish,.006)
            for i in range(3):
                box("Pressed tail lens rib",(x,2.072,z-.010+i*.010),(.227,.004,.0025),finish,.001)
        box("Return lens around quarter",(side*.808,1.991,.671),(.027,.109,.131),smoked_ruby,.010)
        box("Rear bumper reflector",(side*.671,2.089,.423),(.106,.009,.025),smoked_ruby,.004)
        bar("Spoiler pedestal",(side*.588,1.532,.877),(side*.588,1.876,.973),.108,.078,trim)
        box("Rear bumper corner",(side*.786,2.010,.389),(.097,.150,.167),red,.026)

    mesh_from_rings("Trailing edge spoiler", [
        (1.615,.742,.944,.963,.972),(1.736,.787,.944,.988,.996),
        (1.900,.789,.943,1.004,1.011),(1.974,.764,.949,.988,.994),
    ], trim, root, bevel=.010, section=lambda y,w,b,s,c: [(-w*.95,y,b),(-w,y,s),(-w*.86,y,c),(0,y,c+.002),(w*.86,y,c),(w,y,s),(w*.95,y,b)])
    box("Dark rear cross panel",(0,2.029,.662),(1.205,.082,.203),recess,.016)
    for side in [-1,1]:
        for i in range(12):
            box("Rear panel ribs",(side*.355,2.072,.578+i*.014),(.374,.006,.005),trim,.001)
    box("Rear painted bumper",(0,2.017,.368),(1.625,.143,.204),red,.034)
    box("Rear impact strip",(0,2.058,.423),(1.634,.058,.078),trim,.014)
    for x in [-.578, -.485]:
        # The profile curls over the lip and continues down the inside wall.
        profile = [(2.000, .033), (2.010, .038), (2.108, .038),
                   (2.116, .035), (2.115, .031), (2.108, .028), (2.010, .027)]
        segments = 32
        vertices = []
        for y, radius in profile:
            for index in range(segments):
                angle = math.tau * index / segments
                vertices.append((x + radius * math.cos(angle), y, .249 + radius * math.sin(angle)))
        faces = []
        for ring in range(len(profile) - 1):
            for index in range(segments):
                first = ring * segments
                next_index = (index + 1) % segments
                faces.append((first + index, first + segments + index,
                              first + segments + next_index, first + next_index))
        mesh = bpy.data.meshes.new("Rolled exhaust tubing")
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        mesh.materials.append(chrome)
        mesh.materials.append(recess)
        for face in mesh.polygons:
            face.use_smooth = True
            face.material_index = int(face.index >= 5 * segments)
        outlet = bpy.data.objects.new("Hollow exhaust tip", mesh)
        bpy.context.collection.objects.link(outlet)
        attach(outlet, root)
        throat = cylinder("Shadow at exhaust throat", (x,2.014,.249), .027,.006,
                          recess, axis_x=False, vertices=segments, root=root)
        throat.rotation_euler.x = math.pi / 2

    for i in [-1,0,1]:
        x = i*.413
        box("Bumper intake",(x,-2.084,.435),(.374,.014,.105),recess,.008)
        box("Lower valance vent",(x,-2.053,.290),(.365,.017,.064),recess,.006)
        for vane in range(4):
            box("Bumper intake horizontal mesh", (x,-2.094,.401+vane*.022), (.351,.007,.003),trim,.001)
        for rib in range(12):
            box("Bumper intake vertical mesh", (x-.167+rib*.0304,-2.094,.435), (.003,.007,.090),trim,.001)
        for vane in range(2):
            box("Lower vent vane", (x,-2.063,.279+vane*.022), (.344,.006,.004),trim,.001)
    vent_y = -1.749
    vent_angle = math.atan2(.841 - .806, -1.48 - (-1.89))
    hood_height = sample(vent_y)[4]
    for x, width in [(-.443, .233), (0, .547), (.443, .233)]:
        vent = box("Bonnet vent recess", (x, vent_y, hood_height + .002),
                   (width, .133, .016), recess, .008)
        vent.rotation_euler.x = vent_angle

        def vent_detail(name, dx, dy, lift, size, finish, bevel):
            height = hood_height + dy * math.tan(vent_angle) + lift
            detail = box(name, (x + dx, vent_y + dy, height), size, finish, bevel)
            detail.rotation_euler.x = vent_angle
            return detail

        for side in [-1, 1]:
            vent_detail("Bonnet vent side rim", side * (width / 2 - .005), 0, .011,
                        (.010, .121, .009), trim, .002)
            vent_detail("Bonnet vent end rim", 0, side * .061, .011,
                        (width - .010, .010, .009), trim, .002)
        for dy in [-.038, 0, .038]:
            louvre = vent_detail("Bonnet vent louvre", 0, dy, .012,
                                 (width - .026, .016, .006), trim, .002)
            louvre.rotation_euler.x += math.radians(22)
    plate_white = material("Registration plate enamel", (.87,.87,.82), .03, .47)
    plate_blue = material("Registration country field", (.025,.12,.42), .03, .47)
    for y, z, outward in [(-2.084,.284,-1), (2.078,.657,1)]:
        box("Number plate frame",(0,y,z),(.308,.015,.099),trim,.008)
        box("Number plate insert",(0,y+outward*.010,z),(.280,.007,.077),plate_white,.006)
        box("Number plate country field",(outward*.121,y+outward*.014,z),(.028,.002,.069),plate_blue,.002)
        plate = text_obj("Number plate characters","SQ  084",(outward*.088,y+outward*.016,z-.017),.062,recess,root=root,flat=True)
        plate.rotation_euler.z = math.pi if outward == 1 else 0
        country = text_obj("Number plate country letter","S",(outward*.127,y+outward*.016,z-.020),.021,plate_white,root=root,flat=True)
        country.rotation_euler.z = plate.rotation_euler.z
    badge = text_obj("Quattro script","quattro",(-.335,2.029,.774),.055,trim,root=root)
    badge.rotation_euler.z = math.pi
    export_vehicle(root,"sport_quattro.glb")
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(PROJECT/"source_blender"/"sport_quattro.blend"),compress=True)


if __name__ == "__main__":
    build()
