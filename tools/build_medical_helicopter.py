"""Create Harbor Town's yellow and teal ambulance helicopter and articulated rotors."""

import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import SOURCE_DIR, clear_scene, cube, cylinder, export_vehicle, material, text_obj


def pivot(name, parent=None, position=(0, 0, 0)):
    node = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    node.location = position
    return node


def shell(name, stations, finishes, paint, parent):
    sides = 48
    points = []
    for y, width, center, height in stations:
        for index in range(sides):
            angle = math.tau * index / sides
            points.append((width * math.cos(angle), y, center + height * math.sin(angle)))
    faces = []
    colors = []
    for row in range(len(stations) - 1):
        for index in range(sides):
            following = (index + 1) % sides
            faces.append((row * sides + index, (row + 1) * sides + index,
                          (row + 1) * sides + following, row * sides + following))
            colors.append(paint(row, index, math.sin(math.tau * (index + .5) / sides)))
    faces.extend((tuple(range(sides)), tuple(reversed(range(len(points) - sides, len(points))))))
    colors.extend((0, 0))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(points, [], faces)
    mesh.update()
    for finish in finishes:
        mesh.materials.append(finish)
    for polygon, color in zip(mesh.polygons, colors):
        polygon.material_index = color
        polygon.use_smooth = True
    node = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    return node


def pipe(name, points, radius, finish, parent):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = radius
    curve.bevel_resolution = 3
    curve.use_fill_caps = True
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, vertex in zip(spline.points, points):
        point.co = (*vertex, 1)
    node = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    curve.materials.append(finish)


clear_scene()
root = pivot("Ambulance Helicopter")
yellow = material("Rescue yellow", (.88, .89, .035), .12, .31)
teal = material("Medical teal", (.013, .23, .19), .27, .3)
dark = material("Composite and rubber", (.019, .024, .030), .26, .36)
glass = material("Blue-black cockpit glazing", (.024, .067, .098), .55, .14)
white = material("White blade markings", (.8, .83, .79), .1, .45)
metal = material("Rotor metal", (.29, .34, .36), .73, .3)
blue = material("Medical emblem blue", (.024, .13, .39), .24, .25)
red_lamp = material("Port navigation red", (.94, .02, .025), .08, .28, 3.0)
green_lamp = material("Starboard navigation green", (.025, .82, .20), .08, .28, 3.0)
white_lamp = material("Landing lamp", (.94, .95, .89), .12, .24, 2.0)

fuselage = [
    (-3.47, .08, 1.20, .08), (-3.28, .48, 1.29, .38), (-3.03, .73, 1.39, .65),
    (-2.73, .92, 1.45, .84), (-2.42, 1.03, 1.51, .99), (-2.11, 1.10, 1.56, 1.06),
    (-1.83, 1.145, 1.57, 1.09), (-1.76, 1.15, 1.57, 1.09), (-1.43, 1.17, 1.57, 1.10),
    (-1.08, 1.18, 1.57, 1.1), (-.75, 1.18, 1.58, 1.1), (-.67, 1.18, 1.58, 1.1),
    (-.34, 1.18, 1.58, 1.10), (0, 1.16, 1.58, 1.10), (.33, 1.14, 1.58, 1.09),
    (.40, 1.14, 1.58, 1.09), (.72, 1.10, 1.59, 1.06), (1.04, 1.05, 1.60, 1.01),
    (1.35, .96, 1.62, .90), (1.65, .83, 1.65, .76), (1.92, .65, 1.70, .58),
    (2.28, .43, 1.79, .39), (2.54, .33, 1.86, .29),
]


def cabin_paint(row, index, height):
    if row < 6 and .02 < height < .9 and index not in (11, 12):
        return 2
    if 7 <= row <= 17 and .09 < height < .61:
        return 3 if row in (10, 14) else 2
    if 4 <= row <= 19 and -.86 < height < -.38:
        lower_band = height < -.64
        return 1 if (row % 2 == int(lower_band)) else 0
    if 17 <= row <= 20 and height > -.24:
        return 1
    return 0


cabin = shell("Glazed ambulance fuselage", fuselage, [yellow, teal, glass, dark], cabin_paint, root)
shell("Tail boom", [(1.92, .52, 1.78, .40), (2.62, .38, 1.88, .30),
                    (4.05, .24, 2.02, .20), (5.16, .17, 2.10, .15)],
      [yellow, teal], lambda row, index, height: int(height > .51), root)
shell("Turbine fairing", [(-1.6, .11, 2.48, .11), (-1.17, .49, 2.64, .22),
                          (-.35, .65, 2.76, .27), (.82, .64, 2.75, .25),
                          (1.48, .52, 2.59, .23), (1.84, .25, 2.35, .14)],
      [teal, yellow], lambda row, index, height: int(row >= 3), root)
for side in (-1, 1):
    text_obj("Ambulance lettering", "AMBULANS", (side * 1.17, -1.64 if side > 0 else .03, 1.14),
             .226, teal, -side, root, flat=True)
    for angle in (0, math.tau / 3, 2 * math.tau / 3):
        arm = cube("Star of Life arm", (side * 1.145, .65, 1.40), (.018, .098, .39), blue, .007, root)
        arm.rotation_euler.x = angle
    pipe("Black tubular skid", [(side * 1.06, -2.56, .23), (side * 1.07, -2.28, .095),
                                (side * 1.08, -2.06, .064), (side * 1.08, 1.53, .064),
                                (side * 1.08, 1.77, .10)], .064, dark, root)
    for y in (-1.63, 1.07):
        pipe("Skid cross braces", [(side * .53, y, .63), (side * .79, y, .47),
                                  (side * 1.08, y, .115)], .048, dark, root)
        cube("Skid saddle clamp", (side * 1.08, y, .112), (.156, .153, .084), metal, .016, root)
        for bolt_y in (y - .048, y + .048):
            cylinder("Skid clamp bolt", (side * 1.125, bolt_y, .161),
                     .013, .017, dark, False, 6, root)
    for step_y in (-1.04, .52):
        cube("Skid step plate", (side * 1.087, step_y, .139), (.235, .495, .045), metal, .014, root)
        cube("Skid step rubber insert", (side * 1.087, step_y, .166),
             (.193, .425, .012), dark, .007, root)
        for rib in range(-3, 4):
            cube("Skid step grip rib", (side * 1.087, step_y + rib * .052, .175),
                 (.164, .013, .009), dark, .003, root)
    for outline in (
        ((-1.78, 2.25), (-.73, 2.30), (-.70, 1.23), (-.78, 1.14), (-1.53, 1.14), (-1.78, 1.45), (-1.78, 2.25)),
        ((-.64, 2.30), (.48, 2.28), (.54, 1.21), (.43, 1.12), (-.55, 1.12), (-.64, 1.23), (-.64, 2.30)),
    ):
        seam = []
        for (y0, z0), (y1, z1) in zip(outline, outline[1:]):
            for step in range(12):
                t = step / 12
                y, z = y0 + (y1 - y0) * t, z0 + (z1 - z0) * t
                hit, contact, _, _ = cabin.ray_cast((side * 2, y, z), (-side, 0, 0))
                if not hit:
                    raise ValueError("Cabin door seam must meet the fuselage")
                seam.append((contact.x + side * .003, y, z))
        pipe("Cabin door seam", seam + [seam[0]], .006, dark, root)
    handle_y, handle_z = -.26, 1.65
    hit, contact, _, _ = cabin.ray_cast((side * 2, handle_y, handle_z), (-side, 0, 0))
    if not hit:
        raise ValueError("Cabin door handle must meet the fuselage")
    cube("Door pull gasket", (contact.x + side * .003, handle_y, handle_z),
         (.026, .284, .066), dark, .015, root)
    for support in (-.102, .102):
        cube("Door pull support", (contact.x + side * .019, handle_y + support, handle_z),
             (.034, .042, .041), metal, .008, root)
    cube("Door pull grip", (contact.x + side * .037, handle_y, handle_z),
         (.025, .214, .027), metal, .008, root)
    cylinder("Door lock bezel", (contact.x + side * .018, handle_y + .129, handle_z - .045),
             .014, .018, metal, True, 16, root)
    cube("Door lock slot", (contact.x + side * .028, handle_y + .129, handle_z - .045),
         (.006, .012, .004), dark, .001, root)
    lamp_y, lamp_z = 1.0, 1.74
    hit, contact, _, _ = cabin.ray_cast((side * 2, lamp_y, lamp_z), (-side, 0, 0))
    if not hit:
        raise ValueError("Navigation lamp must meet the fuselage")
    cube("Navigation lamp gasket", (contact.x + side * .006, lamp_y, lamp_z),
         (.034, .139, .077), dark, .020, root)
    cube("Navigation lamp bezel", (contact.x + side * .026, lamp_y, lamp_z),
         (.035, .120, .063), metal, .017, root)
    # The nose points toward -Y, so port is the positive X side.
    cube("Port navigation lens" if side > 0 else "Starboard navigation lens",
         (contact.x + side * .048, lamp_y, lamp_z), (.022, .092, .045),
         red_lamp if side > 0 else green_lamp, .013, root)
    cube("Landing lamp mounting plate", (side * .44, -2.49, .725),
         (.244, .236, .073), dark, .027, root)
    for name, y, z, radius, depth, finish in (
        ("Landing lamp housing", -2.52, .666, .119, .116, dark),
        ("Landing lamp reflector rim", -2.553, .620, .110, .029, metal),
        ("Landing lamp lens", -2.568, .600, .090, .021, white_lamp),
    ):
        lamp = cylinder(name, (side * .44, y, z), radius, depth, finish, False, 24, root)
        lamp.rotation_euler.x = -.63

cube("Horizontal stabilizer", (0, 4.31, 2.03), (2.54, .50, .083), teal, .038, root)
fin = cube("Swept yellow tail fin", (0, 5.48, 2.95), (.22, .72, 1.20), yellow, .09, root)
fin.rotation_euler.x = -.30
tip = cube("Teal tail cap", (0, 5.64, 3.53), (.235, .68, .095), teal, .03, root)
tip.rotation_euler.x = -.04
tail_white = material("Aft navigation white", (.92, .95, 1.0), .06, .26, 1.55)
cube("Aft navigation lamp housing", (0, 5.962, 3.518), (.148, .104, .081), dark, .023, root)
cube("Aft navigation lamp rim", (0, 6.014, 3.518), (.115, .023, .061), metal, .014, root)
cube("Aft navigation lamp lens", (0, 6.029, 3.518), (.087, .014, .044), tail_white, .010, root)
bpy.ops.mesh.primitive_torus_add(location=(0, 5.40, 2.11), rotation=(0, math.pi / 2, 0),
                                major_radius=.63, minor_radius=.119, major_segments=48, minor_segments=14)
duct = bpy.context.object
duct.name = "Molded fenestron shroud"
duct.parent = root
duct.data.materials.append(yellow)
for polygon in duct.data.polygons:
    polygon.use_smooth = True
# The gearbox support spans the duct behind the spinning fan.
cube("Fenestron gearbox support", (.165, 5.40, 2.11), (.092, 1.16, .085), yellow, .032, root)
cylinder("Fenestron gearbox cover", (.211, 5.40, 2.11), .105, .052, yellow, True, 24, root)
tail_rotor = pivot("TailRotor", root, (0, 5.40, 2.11))
cylinder("Fan hub", (0, 0, 0), .138, .19, yellow, True, 24, tail_rotor)
for index in range(9):
    angle = math.tau * index / 9
    vane = cube("Fenestron blade", (0, -.305 * math.sin(angle), .305 * math.cos(angle)),
                (.038, .095, .42), dark, .014, tail_rotor)
    vane.rotation_euler.x = angle

cylinder("Rotor mast", (0, -.38, 3.08), .090, .34, metal, False, 24, root)
main_rotor = pivot("MainRotor", root, (0, -.38, 3.27))
cylinder("Rotor hub", (0, 0, 0), .247, .12, metal, False, 28, main_rotor)
cylinder("Main hub cap", (0, 0, .079), .22, .081, yellow, False, 28, main_rotor)
for index in range(5):
    angle = math.tau * index / 5
    blade = pivot("Composite rotor assembly", main_rotor)
    blade.rotation_euler.z = angle
    cube("Main rotor blade", (0, 2.62, 0), (.22, 4.67, .047), dark, .02, blade)
    cube("Blade tip stripe", (0, 4.81, .024), (.185, .165, .003), white, .001, blade)

# Imported rotor children need local transforms at their rotating hubs.
for rotor in (main_rotor, tail_rotor):
    for component in rotor.children_recursive:
        component.matrix_parent_inverse.identity()

export_vehicle(root, "ambulance_helicopter.glb")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR) / "AmbulanceHelicopter.blend"))
