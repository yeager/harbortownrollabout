"""Build the Vovlo 434 three-door hatchback for Harbor Town Rollabout."""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Vovlo 434", None)
bpy.context.collection.objects.link(root)
paint = v.material("Burnt orange enamel", (.54, .125, .030), .22, .36)
glass = v.material("Blue gray window glass", (.055, .119, .143), 0, .27)
amber = v.material("Amber lens", (.91, .29, .015))
headlamp_glass = v.material("Pale fluted headlamp glass", (.66, .72, .69), .12, .29)
headlamp_flute = v.material("Headlamp glass flute", (.44, .53, .51), .20, .29)
headlamp_optic = v.material("Bright headlamp reflector", (.79, .81, .74), .46, .24)
reverse = v.material("Reverse lamp clear", (.75, .81, .78))
ivory = v.material("Ivory plate", (.9, .87, .78))
mirror_glass = v.material("Mirror glass", (.48, .56, .59), .9, .12)

def box(name, location, dimensions, material, bevel=.012):
    return v.cube(name, location, dimensions, material, bevel, root)

def text(name, value, position, size, facing_rear=False, material=v.METAL):
    label = v.text_obj(name, value, position, size, material, root=root, flat=True)
    label.rotation_euler = (math.pi / 2, 0, math.pi if facing_rear else 0)

def pane(name, outline, seating_offset):
    v.profile_loft(name, [outline, [(x * .997, y * .997, z - .006) for x, y, z in outline]], glass, root)
    v.pipe(name + " rubber seal", outline + outline[:1], .015, v.RUBBER, root)
    # Return the gasket to the painted frame behind the glass.
    outer = [Vector(point) for point in outline]
    v.profile_loft(name + " gasket return", [outer, [
        point + Vector(seating_offset) for point in outer
    ]], v.RUBBER, root, close_ends=False)

# Axial section from the inner sidewall to the outer sidewall.
tire_section = [
    (-.0905, .188), (-.0905, .236), (-.086, .260), (-.077, .276),
    (-.060, .284), (-.039, .287), (-.036, .282), (-.032, .282),
    (-.029, .287), (-.005, .287), (-.002, .281), (.002, .281),
    (.005, .287), (.029, .287), (.032, .282), (.036, .282),
    (.039, .287), (.060, .284), (.077, .276), (.086, .260),
    (.0905, .236), (.0905, .188),
]
tire_rings = []
for x, radius in tire_section:
    ring = []
    for segment in range(144):
        angle = math.tau * segment / 144
        groove_offset = .003 * math.sin(24 * angle) if abs(x) < .045 else 0
        ring.append((x + groove_offset, radius * math.cos(angle), radius * math.sin(angle)))
    tire_rings.append(ring)
tire_template = v.profile_loft("Däck med slitbanespår", tire_rings, v.RUBBER, root)

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

# The raised lip follows the painted sheet immediately above each wheel opening.
body_surface = shell.evaluated_get(bpy.context.evaluated_depsgraph_get())
for side in (-1, 1):
    for axle in (-1.215, 1.215):
        lip = []
        for step in range(45):
            angle = math.pi * step / 44
            y = axle + .345 * math.cos(angle)
            z = .286 + .345 * math.sin(angle)
            hit, point, _, _ = body_surface.ray_cast(
                Vector((side * 1.1, y, z)), Vector((-side, 0, 0))
            )
            if not hit:
                raise RuntimeError(f"Wheel arch lip misses the panel at {y:.3f}, {z:.3f}")
            lip.append(point + Vector((side * .001, 0, 0)))
        v.pipe("Rolled wheel arch lip", lip, .004, paint, root)

# Rolled inner liners follow the arch behind the rotating tires.
liner_finish = v.material("Textured wheelhouse liner", (.027, .030, .031), 0, .86)
for side in (-1, 1):
    for axle in (-1.215, 1.215):
        v.profile_loft("Fixed wheelhouse liner", [
            [(side * x, axle + radius * math.cos(angle), .286 + radius * math.sin(angle))
             for x, radius in [(.559, .342), (.563, .331), (.606, .327),
                               (.765, .329), (.794, .335), (.794, .341)]]
            for angle in (math.pi * step / 48 for step in range(49))
        ], liner_finish, root)

# Sample the finished body so the shut line follows the crown without gaps.
hood_outline = [
    (-.53, -1.985), (.53, -1.985), (.58, -1.95),
    (.628, -.898), (-.628, -.898), (-.58, -1.95),
]
hood_seam = []
for start, end in zip(hood_outline, hood_outline[1:] + hood_outline[:1]):
    steps = max(1, math.ceil(math.dist(start, end) / .035))
    for index in range(steps):
        x, y = Vector(start).lerp(Vector(end), index / steps)
        hit, point, _, _ = body_surface.ray_cast(Vector((x, y, 1.2)), Vector((0, 0, -1)))
        if not hit:
            raise RuntimeError(f"Bonnet outline misses the body at {x:.3f}, {y:.3f}")
        hood_seam.append((x, y, point.z + .0008))
v.pipe("Bonnet shut line", hood_seam + hood_seam[:1], .0032, v.DARK, root)

# Seat the cowl slots on the bonnet's slope below the parked wipers.
for slot in range(-12, 13):
    x = slot * .023
    hit, point, normal, _ = body_surface.ray_cast(
        Vector((x, -.977, 1.2)), Vector((0, 0, -1))
    )
    if not hit:
        raise RuntimeError("Cowl vent misses the bonnet")
    vent = box("Cowl air slot", point + normal * .0006,
               (.010, .051, .003), v.RUBBER, .001)
    vent.rotation_euler = normal.to_track_quat('Z', 'Y').to_euler()

# Project the lower hatch perimeter onto the tail panel and the sloped deck.
hatch_outline = [
    (-.622, .728), (.622, .728), (.650, .752), (.650, .816),
    (.610, .881), (.530, .925), (0, .959), (-.530, .925),
    (-.610, .881), (-.650, .816), (-.650, .752),
]
hatch_seam = []
for start, end in zip(hatch_outline, hatch_outline[1:] + hatch_outline[:1]):
    steps = max(1, math.ceil(math.dist(start, end) / .020))
    for index in range(steps):
        x, z = Vector(start).lerp(Vector(end), index / steps)
        hit, point, normal, _ = body_surface.ray_cast(Vector((x, 2.3, z)), Vector((0, -1, 0)))
        if not hit:
            raise RuntimeError(f"Hatch edge misses the body at {x:.3f}, {z:.3f}")
        hatch_seam.append(point + normal * .001)
v.pipe("Lower hatch shut line", hatch_seam + hatch_seam[:1], .0032, v.DARK, root)

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
                    (-.522, -.243, 1.425), (-.601, -.285, 1.399)]], (0, .078, 0))
pane("Hatch glass", [(-.626, 1.512, 1.054), (-.560, .961, 1.390),
                     (.560, .961, 1.390), (.626, 1.512, 1.054)], (0, -.086, 0))
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

# Seat the fuel filler on the right rear quarter at the local panel angle.
hit, filler_surface, filler_normal, _ = body_surface.ray_cast(
    Vector((1.1, 1.69, .762)), Vector((-1, 0, 0))
)
if not hit:
    raise RuntimeError("Fuel filler misses the rear quarter panel")
for name, radius, depth, offset, finish in [
    ("Fuel filler surround", .055, .030, -.008, v.RUBBER),
    ("Fuel cap", .044, .015, .009, v.DARK),
]:
    filler = v.cylinder(name, filler_surface + filler_normal * offset, radius, depth,
                        finish, axis_x=False, vertices=40, root=root)
    filler.rotation_euler = filler_normal.to_track_quat('Z', 'Y').to_euler()
lock = box("Fuel cap grip", filler_surface + filler_normal * .018,
           (.055, .013, .009), v.RUBBER, .003)
lock.rotation_euler = filler.rotation_euler

def tail_corner_recess(x):
    # Keep the inner lenses square to the back and sweep the outer lens toward the side.
    return .55 * max(0, x - .65) + .45 * max(0, x - .72)

for side in (-1, 1):
    def side_pane(name, points):
        pane(name, [(side * x, y, z) for x, y, z in points], (-side * .075, 0, 0))
    side_pane("Door window", [(.754, -.744, .957), (.720, .377, .969),
                             (.634, .359, 1.413), (.631, -.172, 1.410),
                             (.663, -.270, 1.356)])
    side_pane("Rear quarter window", [(.718, .448, .970), (.747, 1.334, .988),
                                     (.710, 1.370, 1.060), (.621, .857, 1.384),
                                     (.628, .435, 1.413)])
    door_outline = [
        (-.731, .896), (-.700, .769), (-.698, .35), (-.656, .303),
        (.345, .303), (.411, .375), (.449, .742), (.425, .914),
    ]
    door_seam = []
    for segment, (start, end) in enumerate(zip(door_outline, door_outline[1:])):
        steps = math.ceil(math.dist(start, end) / .005)
        for index in range(1 if segment else 0, steps + 1):
            y, z = Vector(start).lerp(Vector(end), index / steps)
            hit, point, _, _ = body_surface.ray_cast(
                Vector((side * 1.1, y, z)), Vector((-side, 0, 0))
            )
            if not hit:
                raise RuntimeError(f"Door edge misses the body at {y:.3f}, {z:.3f}")
            door_seam.append(point + Vector((side * .0017, 0, 0)))
    v.pipe("Door shut line", door_seam, .003, v.RUBBER, root)
    for center, length in [(-1.67, .42), (-.12, 1.04), (.65, .40), (1.72, .26)]:
        molding_rings = []
        bright_edge = []
        steps = math.ceil(length / .035)
        for index in range(steps + 1):
            y = center + length * (index / steps - .5)
            hit, point, _, _ = body_surface.ray_cast(
                Vector((side * 1.1, y, .600)), Vector((-side, 0, 0))
            )
            if not hit:
                raise RuntimeError(f"Side molding misses the body at {y:.3f}")
            projection = .008 if index in (0, steps) else .016
            molding_rings.append([
                (point.x + side * depth, y, .600 + height)
                for depth, height in [(-.012, -.014), (projection - .004, -.014),
                                      (projection, -.008), (projection, .008),
                                      (projection - .004, .014), (-.012, .014)]
            ])
            if 0 < index < steps:
                bright_edge.append((point.x + side * (projection + .001), y, .608))
        v.profile_loft("Side rubbing strip", molding_rings, v.DARK, root)
        v.pipe("Bright side molding", bright_edge, .0035, v.METAL, root)
    hit, handle_seat, panel_normal, _ = body_surface.ray_cast(
        Vector((side * 1.1, .274, .805)), Vector((-side, 0, 0))
    )
    if not hit:
        raise RuntimeError("Door handle misses the side panel")
    handle_rotation = Vector((side, 0, 0)).rotation_difference(panel_normal)
    for name, offset, size, finish, bevel in [
        ("Door handle gasket", (.004, 0, 0), (.024, .151, .060), v.RUBBER, .008),
        ("Door handle bezel", (.016, 0, 0), (.010, .135, .048), v.METAL, .004),
        ("Door handle recess", (.021, 0, 0), (.006, .118, .035), v.RUBBER, .003),
        ("Door release lever", (.027, -.014, .004), (.009, .078, .015), v.METAL, .003),
        ("Door key slot", (.031, .039, 0), (.003, .003, .009), v.RUBBER, .001),
    ]:
        position = handle_seat + handle_rotation @ Vector((side * offset[0], offset[1], offset[2]))
        handle_part = box(name, position, size, finish, bevel)
        handle_part.rotation_euler = handle_rotation.to_euler()
    cylinder_position = handle_seat + handle_rotation @ Vector((side * .026, .039, 0))
    key_cylinder = v.cylinder("Door lock cylinder", cylinder_position, .008, .008,
                              v.METAL, axis_x=False, vertices=24, root=root)
    key_cylinder.rotation_euler = panel_normal.to_track_quat('Z', 'Y').to_euler()
    box("Mirror mounting gasket", (side * .743, -.593, .982), (.029, .091, .053), v.RUBBER)
    v.pipe("Mirror pedestal", [(side * .747, -.596, .985), (side * .806, -.586, 1.021)],
           .022, v.DARK, root)
    mirror_outline = [(-.82, -1), (.76, -1), (1, -.68), (1, .64),
                      (.74, 1), (-.76, 1), (-1, .66), (-1, -.70)]
    v.profile_loft("Door mirror shell", [
        [(side * (.843 + x * width), y, 1.062 + z * height) for x, z in mirror_outline]
        for y, width, height in [
            (-.644, .056, .035), (-.618, .080, .049), (-.546, .087, .052),
            (-.518, .083, .049), (-.517, .071, .039), (-.531, .070, .038),
        ]
    ], v.DARK, root)
    v.profile_loft("Mirror glass insert", [
        [(side * (.843 + x * .070), y, 1.062 + z * .038) for x, z in mirror_outline]
        for y in (-.534, -.527)
    ], mirror_glass, root)
    for slot in range(5):
        y = 1.390 - slot * .047
        z = 1.066 + slot * .032
        # Follow the taper of the painted quarter pillar.
        x = .693 - slot * .0085
        box("Quarter pillar vent", (side * x, y, z), (.009, .041, .012), v.RUBBER, .003)
    box("Front lamp gasket", (side*.545, -2.004, .702), (.270, .060, .187), v.RUBBER)
    box("Front lamp bright frame", (side*.545, -2.035, .707), (.254, .028, .173), v.METAL)
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
    # The amber lens starts alongside the headlamp and tapers into the fender.
    indicator_stations = [(.674, -2.060, .061)]
    for rib in range(9):
        for phase, relief in [(.15, 0), (.52, .0024), (.84, 0)]:
            t = (rib + phase) / 9
            indicator_stations.append((.674 + .104 * t, -2.077 + .156 * t**2 - relief,
                                       .069 - .013 * t))
    indicator_stations.append((.778, -1.917, .041))
    v.profile_loft("Front amber indicator", [
        [(side * x, y + inset, .703 + half_height * level)
         for inset, level in [(0, -.82), (0, .82), (.008, 1),
                              (.038, 1), (.038, -1), (.008, -1)]]
        for x, y, half_height in indicator_stations
    ], amber, root)
    v.profile_loft("Rear lamp carrier", [
        [(side * x, y - tail_corner_recess(x), z)
         for y, z in [(1.976, .552), (2.037, .552), (2.053, .567),
                      (2.053, .687), (2.037, .702), (1.976, .702)]]
        for x in (.337, .355, .65, .72, .756)
    ], v.RUBBER, root)
    for name, x, width, ribs, finish in [
        ("Tail lamp position lens", .491, .102, 7, v.TAIL_LAMP),
        ("Tail lamp brake lens", .607, .124, 9, v.TAIL_LAMP),
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
            [(side * (x + width * offset), y - tail_corner_recess(x + width * offset),
              .627 + z * height)
             for y, z in [
                 (2.043, -.060), (2.060 + relief, -.065),
                 (2.069 + relief, -.052), (2.069 + relief, .052),
                 (2.060 + relief, .065), (2.043, .060),
             ]]
            for offset, relief, height in sections
        ], finish, root)
    for y in (-1.215, 1.215):
        tire = tire_template.copy()
        bpy.context.collection.objects.link(tire)
        tire.location = (side * .699, y, .287)
        rim = v.cylinder("Pressed steel wheel rim", (side * .790, y, .287),
                         .183, .040, v.METAL, vertices=64, root=root)
        for n in range(10):
            angle = math.tau * n / 10
            cutter = v.cube("Rim ventilation tool",
                            (side * .790, y + .133 * math.cos(angle), .287 + .133 * math.sin(angle)),
                            (.065, .028, .042), None, .008)
            cutter.rotation_euler.x = angle
            bpy.context.view_layer.objects.active = rim
            opening = rim.modifiers.new("Pressed ventilation opening", "BOOLEAN")
            opening.operation = "DIFFERENCE"
            opening.object = cutter
            bpy.ops.object.modifier_apply(modifier=opening.name)
            bpy.data.objects.remove(cutter, do_unlink=True)
        rim_edge = rim.modifiers.new("Rounded ventilation edges", "BEVEL")
        rim_edge.width = .0013
        rim_edge.segments = 2
        rim.modifiers.new("Rim face normals", "WEIGHTED_NORMAL")
        v.cylinder("Wheel hub cap", (side * .814, y, .287),
                   .067, .026, v.DARK, vertices=40, root=root)
        for n in range(4):
            angle = math.tau * n / 4
            v.cylinder("Wheel lug nut", (side*.828, y+.045*math.cos(angle), .287+.045*math.sin(angle)),
                       .008, .007, v.METAL, vertices=6, root=root)

        # Place the valve between two vents on the outer rim shoulder.
        valve_angle = math.tau / 20
        valve_base = Vector((side * .807, y + .161 * math.cos(valve_angle),
                             .287 + .161 * math.sin(valve_angle)))
        valve_axis = Vector((side, -.26 * math.cos(valve_angle),
                             -.26 * math.sin(valve_angle))).normalized()
        for name, offset, radius, depth, finish in [
            ("Tire valve stem", .011, .005, .022, v.RUBBER),
            ("Tire valve cap", .025, .0055, .010, v.DARK),
        ]:
            valve = v.cylinder(name, valve_base + valve_axis * offset, radius, depth,
                               finish, axis_x=False, vertices=16, root=root)
            valve.rotation_euler = valve_axis.to_track_quat('Z', 'Y').to_euler()

for side in (-1, 1):
    v.profile_loft("Rear rubber mud flap", [
        [(side * x, y + depth, z) for x, depth in [
            (inner, -.007), (outer, -.007), (outer, .007), (inner, .007)
        ]]
        for z, y, inner, outer in [
            (.112, 1.598, .614, .772), (.125, 1.593, .597, .789),
            (.235, 1.571, .588, .795), (.364, 1.552, .582, .785),
        ]
    ], v.RUBBER, root)
    box("Rear mud flap bracket", (side * .682, 1.564, .347),
        (.190, .026, .033), v.DARK, .003)

bpy.data.objects.remove(tire_template, do_unlink=True)

# Layer the molded frame, floating slats and a recessed radiator face.
grille_outline = [(-.96, -1), (.96, -1), (1, -.72), (1, .72),
                  (.96, 1), (-.96, 1), (-1, .72), (-1, -.72)]
v.profile_loft("Grille surround", [
    [(x * width, y, .710 + z * height) for x, z in grille_outline]
    for y, width, height in [
        (-2.025, .419, .095), (-2.082, .419, .095), (-2.093, .411, .087),
        (-2.093, .396, .072), (-2.054, .391, .069),
    ]
], v.DARK, root, close_ends=False)
box("Grille recessed radiator", (0, -2.041, .710), (.792, .026, .143), v.RUBBER, .005)
for x in (-.30, -.20, -.10, 0, .10, .20, .30):
    box("Grille vertical support", (x, -2.061, .710), (.006, .018, .143), v.DARK, .001)
for z in (.650, .674, .698, .722, .746, .770):
    slat = box("Grille horizontal blade", (0, -2.075, z), (.795, .031, .008), v.DARK, .002)
    slat.rotation_euler.x = .13
box("Vovlo grille medallion", (0, -2.096, .709), (.101, .017, .081), v.METAL)
box("Vovlo grille enamel", (0, -2.107, .709), (.081, .010, .064), v.POLICE_BLUE)
text("Vovlo emblem", "V", (-.021, -2.115, .687), .052, material=ivory)
for y, sign, z in [(-2.058, -1, .430), (2.053, 1, .405)]:
    # The centre projects beyond the body, while the ends follow the fenders.
    bumper_stations = [(-.810, -.150), (-.808, -.058), (-.792, .030),
                       (-.757, .083), (-.692, .112), (-.530, .119),
                       (.530, .119), (.692, .112), (.757, .083),
                       (.792, .030), (.808, -.058), (.810, -.150)]
    v.profile_loft("Wraparound bumper", [
        [(x, y + sign * (reach - inset), z + height)
         for inset, height in [(0, -.059), (0, .051), (.020, .083),
                               (.055, .094), (.174, .082), (.174, -.071),
                               (.059, -.092), (.021, -.082)]]
        for x, reach in bumper_stations
    ], v.DARK, root)
    v.pipe("Bumper bright line",
           [(x, y + sign * (reach + .004), z + .031)
            for x, reach in bumper_stations], .005, v.METAL, root)
    box("Plate mount", (0, y + sign*.126, z+.011), (.448, .025, .109), v.RUBBER)
    box("Rear registration plate" if sign > 0 else "Registration plate", (0, y + sign*.142, z+.011), (.420, .015, .086), ivory, .007)
    text("Registration", "HVK 434", (sign*.150, y + sign*.153, z-.016), .067, sign > 0, v.RUBBER)
# A shallow lower apron wraps back toward the front wheel openings.
v.profile_loft("Front lower apron", [
    [(x, y + setback, z) for y, z in [
        (-2.074, .366), (-2.092, .286), (-2.103, .258),
        (-2.073, .233), (-1.957, .246), (-1.952, .374),
    ]]
    for x, setback in [
        (-.746, .110), (-.709, .056), (-.633, .012), (-.520, 0),
        (.520, 0), (.633, .012), (.709, .056), (.746, .110),
    ]
], v.DARK, root)
tow_eye = [(-.32, -2.071, .248), (-.32, -2.136, .244),
           (-.32, -2.152, .219), (-.32, -2.127, .200),
           (-.32, -2.067, .213)]
v.pipe("Front tow eye", tow_eye + tow_eye[:1], .007, v.METAL, root)
for x in (-.145, .145):
    box("Rear plate lamp housing", (x, 2.180, .481), (.092, .031, .026), v.DARK, .004)
    box("Rear plate lamp diffuser", (x, 2.193, .471), (.074, .014, .010), ivory, .002)
# Turn the rolled end back into the tube so the outlet remains open.
exhaust_stations = [
    (1.79, -.46, .282, .025), (1.98, -.46, .253, .025),
    (2.202, -.48, .248, .027), (2.213, -.48, .248, .025),
    (2.213, -.48, .248, .021),
]
v.profile_loft("Rolled exhaust outlet", [
    [(x + radius * math.cos(angle), y, z + radius * math.sin(angle))
     for angle in (math.tau * step / 32 for step in range(32))]
    for y, x, z, radius in exhaust_stations
], v.METAL, root, close_ends=False)
v.profile_loft("Dark exhaust bore", [
    [(-.48 + radius * math.cos(angle), y, .248 + radius * math.sin(angle))
     for angle in (math.tau * step / 32 for step in range(32))]
    for y, radius in [(2.213, .021), (2.201, .020), (2.102, .020)]
], v.RUBBER, root, close_ends=False)
v.cylinder("Exhaust bore shadow", (-.48, 2.103, .248), .020, .005,
           v.RUBBER, axis_x=False, vertices=32, root=root).rotation_euler.x = math.pi / 2
badge_finish = v.material("Satin hatch lettering", (.64, .66, .65), .35, .38)
text("Vovlo hatch badge", "VOVLO", (.575, 2.025, .805), .051, True, badge_finish)
text("434 hatch badge", "434", (-.421, 2.025, .805), .051, True, badge_finish)
box("Hatch latch gasket", (0, 2.018, .782), (.072, .015, .078), v.RUBBER, .006)
box("Hatch latch surround", (0, 2.029, .782), (.058, .013, .067), badge_finish, .004)
box("Hatch latch insert", (0, 2.036, .782), (.045, .009, .055), v.DARK, .003)
latch_cylinder = v.cylinder("Hatch lock cylinder", (0, 2.042, .793), .011, .009,
                            badge_finish, axis_x=False, vertices=24, root=root)
latch_cylinder.rotation_euler.x = math.pi / 2
box("Hatch lock key slot", (0, 2.047, .793), (.011, .003, .003), v.RUBBER, .001)
box("Hatch release paddle", (0, 2.043, .766), (.031, .010, .014), v.RUBBER, .002)
for x in (-.49, .17):
    mount = Vector((x, -.913, .932))
    v.cylinder("Wiper pivot", mount, .023, .020, v.RUBBER,
               axis_x=False, vertices=20, root=root)
    # Use the windscreen rake for the rubber edge and its supporting frame.
    blade_points = []
    for offset, height in [(.015, .978), (.105, .988), (.215, 1.002), (.340, 1.018)]:
        glass_y = -.880 + (.539 / .460) * (height - .939)
        blade_points.append(Vector((x + offset, glass_y - .008, height)))
    v.pipe("Parked wiper blade", blade_points, .005, v.RUBBER, root)
    frame_points = [
        blade_points[0], blade_points[1] + Vector((0, -.011, 0)),
        blade_points[2] + Vector((0, -.011, 0)), blade_points[3],
    ]
    v.pipe("Wiper blade frame", frame_points, .0045, v.DARK, root)
    v.pipe("Parked wiper arm", [mount, mount + Vector((.037, .022, .035)),
                              frame_points[1].lerp(frame_points[2], .5)],
           .007, v.DARK, root)
rear_wiper_base = Vector((.126, 1.514, 1.060))
rear_wiper_axis = Vector((0, .336, .551)).normalized()
rear_spindle = v.cylinder("Rear wiper spindle", rear_wiper_base, .018, .018, v.RUBBER,
                          axis_x=False, vertices=24, root=root)
rear_spindle.rotation_euler = rear_wiper_axis.to_track_quat('Z', 'Y').to_euler()
rear_blade = [
    Vector((x, 1.512 - .551 * (z - 1.054) / .336 + .009, z))
    for x, z in [(-.379, 1.101), (-.265, 1.102), (-.105, 1.107), (.005, 1.112)]
]
v.pipe("Rear wiper rubber edge", rear_blade, .004, v.RUBBER, root)
rear_frame = [rear_blade[0], rear_blade[1] + rear_wiper_axis * .008,
              rear_blade[2] + rear_wiper_axis * .008, rear_blade[3]]
v.pipe("Rear wiper blade frame", rear_frame, .004, v.DARK, root)
v.pipe("Rear wiper arm", [rear_wiper_base + rear_wiper_axis * .009,
                         (.057, 1.495, 1.085), rear_frame[1].lerp(rear_frame[2], .5)],
       .006, v.DARK, root)
v.pipe("Roof aerial", [(0, -.13, 1.449), (0, .125, 1.755)], .006, v.DARK, root)

v.export_vehicle(root, "vovlo_434.glb")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR) / "Vovlo_434.blend"))
