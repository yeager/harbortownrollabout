"""Build the Vovlo 434 three-door hatchback for Harbor Town Rollabout."""
import math
import sys
from pathlib import Path

import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Vovlo 434", None)
bpy.context.collection.objects.link(root)
paint = v.material("Juniper green enamel", (.035, .255, .163), .22, .36)
glass = v.material("Blue gray window glass", (.055, .119, .143), 0, .27)
amber = v.material("Amber lens", (.91, .29, .015))
headlamp_glass = v.material("Pale fluted headlamp glass", (.66, .72, .69), .12, .29)
headlamp_flute = v.material("Headlamp glass flute", (.44, .53, .51), .20, .29)
headlamp_optic = v.material("Bright headlamp reflector", (.79, .81, .74), .46, .24)
amber_flute = v.material("Amber glass flute", (.68, .17, .012), .10, .31)
reverse = v.material("Reverse lamp clear", (.75, .81, .78))
ivory = v.material("Ivory plate", (.9, .87, .78))

def box(name, location, dimensions, material, bevel=.012):
    return v.cube(name, location, dimensions, material, bevel, root)

def text(name, value, position, size, facing_rear=False, material=v.METAL):
    label = v.text_obj(name, value, position, size, material, root=root, flat=True)
    label.rotation_euler = (math.pi / 2, 0, math.pi if facing_rear else 0)

def pane(name, outline):
    v.profile_loft(name, [outline, [(x * .997, y * .997, z - .006) for x, y, z in outline]], glass, root)
    v.pipe(name + " rubber seal", outline + outline[:1], .015, v.RUBBER, root)
    v.pipe(name + " bright trim", outline + outline[:1], .007, v.METAL, root)

shell = v.mesh_from_rings("Pressed steel body", [
    (-2.04, .705, .28, .65, .781), (-1.97, .787, .25, .714, .823),
    (-1.72, .815, .22, .769, .861), (-1.21, .829, .208, .800, .895),
    (-.73, .832, .203, .829, .914), (.22, .830, .204, .856, .925),
    (1.18, .821, .210, .875, .950), (1.76, .795, .234, .893, .978),
    (1.98, .738, .27, .843, .932), (2.019, .698, .302, .774, .906),
], paint, root, bevel=0)
for side in (-1, 1):
    for y in (-1.215, 1.215):
        cutter = v.cylinder("Arch tool", (side * .84, y, .286), .339, .55, v.RUBBER, vertices=64)
        bpy.context.view_layer.objects.active = shell
        cut = shell.modifiers.new("Wheel opening", "BOOLEAN")
        cut.object = cutter
        cut.operation = "DIFFERENCE"
        cut.material_mode = "TRANSFER"
        bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(cutter, do_unlink=True)
edge = shell.modifiers.new("Soft panel edges", "BEVEL")
edge.width = .015
edge.segments = 3
shell.modifiers.new("Panel normals", "WEIGHTED_NORMAL")

def cabin_section(y, width, sill, gutter, roof):
    return [(-width, y, sill), (-width * .88, y, gutter),
            (-width * .72, y, roof - .012), (0, y, roof),
            (width * .72, y, roof - .012), (width * .88, y, gutter), (width, y, sill)]

v.mesh_from_rings("Painted hatchback cabin", [
    (-.817, .753, .895, .911, .933), (-.35, .722, .907, 1.31, 1.379),
    (-.17, .715, .911, 1.405, 1.443), (.54, .700, .923, 1.421, 1.452),
    (.90, .696, .939, 1.384, 1.410), (1.46, .730, .958, 1.045, 1.082),
    (1.58, .714, .934, .976, 1.012),
], paint, root, .015, cabin_section)
pane("Windscreen", [(x, y - .056, z) for x, y, z in [(-.654, -.824, .939), (.654, -.824, .939),
                    (.601, -.285, 1.399), (.522, -.243, 1.425),
                    (-.522, -.243, 1.425), (-.601, -.285, 1.399)]])
pane("Hatch glass", [(-.626, 1.512, 1.054), (-.560, .961, 1.390),
                     (.560, .961, 1.390), (.626, 1.512, 1.054)])
heater = v.material("Copper heater trace", (.20, .11, .065), .24, .54)
heater_rows = []
for row in range(7):
    t = (row + 1) / 9
    y = 1.512 + (.961 - 1.512) * t + .004
    z = 1.054 + (1.390 - 1.054) * t + .004
    width = .626 + (.560 - .626) * t - .039
    heater_rows.append((width, y, z))
    v.pipe("Rear heater trace", [(-width, y, z), (width, y, z)], .0012, heater, root)
for side in (-1, 1):
    v.pipe("Rear heater bus bar", [(side * width, y, z) for width, y, z in heater_rows],
           .002, heater, root)

for side in (-1, 1):
    def side_pane(name, points):
        pane(name, [(side * x, y, z) for x, y, z in points])
    side_pane("Door window", [(.754, -.744, .957), (.720, .377, .969),
                             (.634, .359, 1.413), (.631, -.172, 1.410),
                             (.663, -.270, 1.356)])
    side_pane("Rear quarter window", [(.718, .448, .970), (.747, 1.334, .988),
                                     (.710, 1.370, 1.060), (.621, .857, 1.384),
                                     (.628, .435, 1.413)])
    v.pipe("Door shut line", [(side*x, y, z) for x, y, z in [
        (.778, -.731, .916), (.825, -.700, .769), (.834, -.698, .35),
        (.825, -.656, .303), (.822, .345, .303), (.83, .411, .375),
        (.832, .449, .742), (.771, .425, .929)
    ]], .004, v.RUBBER, root)
    for y, length in [(-1.67, .42), (-.12, 1.04), (.65, .40), (1.72, .26)]:
        box("Door rubbing strip", (side*.825, y, .60), (.028, length, .030), v.DARK, .007)
        box("Bright side molding", (side*.842, y, .608), (.008, length - .018, .009), v.METAL, .003)
    box("Door handle surround", (side*.824, .274, .805), (.031, .153, .060), v.DARK)
    box("Door release", (side*.844, .274, .808), (.016, .115, .019), v.METAL, .005)
    box("Mirror base", (side*.752, -.582, .994), (.055, .105, .072), v.RUBBER)
    box("Door mirror", (side*.835, -.579, 1.062), (.164, .116, .109), v.DARK, .026)
    box("Mirror reflector", (side*.84, -.515, 1.062), (.119, .009, .079), v.METAL)
    for slot in range(5):
        y = 1.390 - slot * .047
        z = 1.066 + slot * .032
        # Follow the taper of the painted quarter pillar.
        x = .693 - slot * .0085
        box("Quarter pillar vent", (side * x, y, z), (.009, .041, .012), v.RUBBER, .003)
    box("Front lamp gasket", (side*.584, -2.004, .702), (.345, .060, .187), v.RUBBER)
    box("Front lamp bright frame", (side*.581, -2.035, .707), (.329, .028, .173), v.METAL)
    box("Headlight lens", (side * .545, -2.055, .708), (.239, .035, .151),
        headlamp_glass, .011)
    optic_angles = [step * math.tau / 48 for step in range(48)]
    v.profile_loft("Circular headlamp optic rim", [
        [(side * .542 + radius * math.cos(angle), depth,
          .710 + radius * math.sin(angle)) for angle in optic_angles]
        for depth, radius in [(-2.073, .052), (-2.077, .049),
                              (-2.077, .044), (-2.073, .042)]
    ], headlamp_optic, root, close_ends=False)
    for flute in range(-9, 10):
        box("Vertical headlamp flute", (side * (.545 + flute * .0114), -2.075, .708),
            (.0018, .004, .135), headlamp_flute, .0008)
    box("Front amber indicator", (side * .709, -2.051, .702), (.074, .031, .144), amber)
    for flute in range(-3, 4):
        box("Amber lens rib", (side * (.709 + flute * .0085), -2.067, .702),
            (.0017, .0035, .123), amber_flute, .0007)
    box("Rear lamp carrier", (side * .548, 2.005, .627), (.436, .087, .158), v.RUBBER)
    for name, x, width, ribs, finish in [
        ("Tail lamp", .555, .231, 16, v.TAIL_LAMP),
        ("Rear indicator lens", .715, .069, 6, amber),
        ("Reversing lens", .400, .068, 6, reverse),
    ]:
        # Mold the flutes into the lens itself so they light with the lens.
        sections = [(-.5, 0, .83)]
        for rib in range(ribs):
            for offset, relief in [(.15, 0), (.5, .0027), (.85, 0)]:
                sections.append(((rib + offset) / ribs - .5, relief, 1))
        sections.append((.5, 0, .83))
        v.profile_loft(name, [
            [(side * (x + width * offset), y, .627 + z * height)
             for y, z in [
                 (2.043, -.060), (2.060 + relief, -.065),
                 (2.069 + relief, -.052), (2.069 + relief, .052),
                 (2.060 + relief, .065), (2.043, .060),
             ]]
            for offset, relief, height in sections
        ], finish, root)
    for y in (-1.215, 1.215):
        v.cylinder("Däck", (side*.699, y, .287), .287, .181, v.RUBBER, vertices=64, root=root)
        v.cylinder("Pressed steel wheel rim", (side*.786, y, .287), .183, .037, v.METAL, vertices=56, root=root)
        v.cylinder("Wheel hub cap", (side*.813, y, .287), .067, .026, v.DARK, vertices=40, root=root)
        for n in range(10):
            angle = math.tau * n / 10
            recess = box("Wheel hub vent", (side*.808, y+.133*math.cos(angle), .287+.133*math.sin(angle)),
                         (.009, .044, .027), v.RUBBER, .006)
            recess.rotation_euler.x = angle + math.pi / 2
        for n in range(4):
            angle = math.tau * n / 4
            v.cylinder("Wheel lug nut", (side*.828, y+.045*math.cos(angle), .287+.045*math.sin(angle)),
                       .008, .007, v.METAL, vertices=6, root=root)

box("Grille backing", (0, -2.041, .713), (.842, .065, .179), v.RUBBER)
for z in (.646, .670, .694, .718, .742, .766):
    box("Grille horizontal blade", (0, -2.081, z), (.790, .025, .010), v.DARK, .004)
box("Vovlo grille medallion", (0, -2.096, .709), (.101, .017, .081), v.METAL)
box("Vovlo grille enamel", (0, -2.107, .709), (.081, .010, .064), v.POLICE_BLUE)
text("Vovlo emblem", "V", (-.021, -2.115, .687), .052, material=ivory)
for y, sign, z in [(-2.058, -1, .430), (2.053, 1, .405)]:
    box("Wraparound bumper", (0, y + sign*.012, z), (1.61, .209, .191), v.DARK, .045)
    box("Bumper bright line", (0, y + sign*.120, z+.032), (1.47, .013, .012), v.METAL, .004)
    box("Plate mount", (0, y + sign*.126, z+.011), (.448, .025, .109), v.RUBBER)
    box("Registration plate", (0, y + sign*.142, z+.011), (.420, .015, .086), ivory, .007)
    text("Registration", "HVK 434", (sign*.150, y + sign*.153, z-.016), .067, sign > 0, v.RUBBER)
text("Vovlo hatch badge", "VOVLO", (.654, 2.027, .808), .057, True)
text("434 hatch badge", "434", (-.463, 2.027, .808), .057, True)
box("Hatch latch", (0, 2.024, .778), (.070, .027, .066), v.DARK)
for x in (-.49, .17):
    v.pipe("Parked wiper arm", [(x, -.869, .946), (x+.16, -.809, .991)], .009, v.RUBBER, root)
    v.pipe("Parked wiper blade", [(x+.045, -.828, .981), (x+.35, -.783, 1.013)], .009, v.DARK, root)
v.pipe("Roof aerial", [(0, -.13, 1.449), (0, .125, 1.755)], .006, v.DARK, root)

v.export_vehicle(root, "vovlo_434.glb")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR) / "Vovlo_434.blend"))
