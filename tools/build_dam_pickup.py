"""Build the DAM double-cab pickup and its editable Blender source."""
import math
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import attach, clear_scene, cube, cylinder, export_vehicle, material, mesh_from_rings, profile_loft, text_obj

PROJECT = Path(__file__).resolve().parents[1]


def build_pickup():
    clear_scene()
    root = bpy.data.objects.new("DAM Pickup", None)
    bpy.context.collection.objects.link(root)
    paint = material("Silver metallic body", (.39, .43, .46), .64, .24)
    trim = material("Textured graphite polymer", (.030, .038, .043), .04, .61)
    liner = material("Rubber cargo liner", (.018, .023, .027), .0, .86)
    glass = material("Smoked safety glass", (.043, .072, .085), .35, .18)
    rubber = material("Off-road black rubber", (.012, .015, .017), .01, .89)
    alloy = material("Gunmetal alloy", (.105, .128, .14), .73, .31)
    chrome = material("Brushed silver", (.64, .67, .69), .74, .25)
    brake_enamel = material("Cast brake caliper enamel", (.27, .045, .030), .32, .48)
    white = material("Headlight lens", (.81, .91, 1), .1, .21, .5)
    reverse = material("Reverse lamp clear", (.81, .91, 1), .1, .21)
    red = material("Tail lamp ruby", (.57, .018, .022), .06, .25, .22)
    amber = material("Amber markers", (.95, .31, .018), .02, .3, .45)

    tread_vertices, tread_faces = [], []
    for lateral, width, phase, sweep in [
        (-.112, .076, .0, -.011), (0, .098, .5, .014), (.112, .076, .0, -.011),
    ]:
        for index in range(28):
            angle = (index+phase)*math.tau/28
            cosine, sine = math.cos(angle), math.sin(angle)
            base = len(tread_vertices)
            for radius in [.417, .4415]:
                for across, along in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
                    tangent = along*.022 + across*sweep
                    tread_vertices.append((
                        lateral + across*width*.5,
                        radius*cosine - tangent*sine,
                        radius*sine + tangent*cosine,
                    ))
            for face in [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1),
                         (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]:
                tread_faces.append(tuple(base+vertex for vertex in face))
    tread_mesh = bpy.data.meshes.new("Staggered pickup tread blocks")
    tread_mesh.from_pydata(tread_vertices, [], tread_faces)
    tread_mesh.materials.append(rubber)

    def panel(name, position, dimensions, finish, bevel=.035, parent=root):
        return cube(name, position, dimensions, finish, bevel, parent)

    body = mesh_from_rings("Pickup body", [
        (-2.91, .94, .75, 1.32, 1.36), (-2.53, 1.03, .69, 1.40, 1.47),
        (-1.52, 1.05, .78, 1.39, 1.43), (-.86, 1.01, .63, 1.32, 1.36),
        (.95, 1.02, .63, 1.30, 1.35), (1.37, 1.02, .73, 1.27, 1.28),
    ], paint, root)
    bpy.context.view_layer.update()
    body_surface = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    panel("Frame rails", (0, .02, .63), (1.50, 5.45, .21), trim)
    glazing = mesh_from_rings("Cab glazing", [
        (-1.44, .97, 1.30, 1.44, 1.44), (-1.00, .91, 1.34, 1.98, 2.00),
        (-.77, .92, 1.34, 2.03, 2.05), (.83, .92, 1.34, 2.03, 2.05),
        (1.08, .95, 1.34, 1.91, 1.96), (1.23, .96, 1.34, 1.39, 1.42),
    ], glass, root, bevel=.018)
    # Follow the glass surface from the waist to the roof at each outer pillar.
    for side in [-1, 1]:
        for label, stations in [
            ("Front", [(-1.391, 1.475), (-1.306, 1.57), (-1.195, 1.71),
                       (-1.097, 1.84), (-.990, 1.963)]),
            ("Rear", [(1.194, 1.475), (1.164, 1.60), (1.127, 1.73),
                      (1.080, 1.85), (1.008, 1.943)]),
        ]:
            pillar = []
            for y, z in stations:
                section = []
                for dy, relief in [(-.024, -.006), (-.022, .006), (.022, .006), (.024, -.006)]:
                    hit, surface, _, _ = glazing.ray_cast((side*1.4, y+dy, z), (-side, 0, 0))
                    if not hit:
                        raise ValueError(f"{label} cab pillar outside glazing")
                    section.append((surface.x+side*relief, y+dy, z))
                pillar.append(section)
            profile_loft(f"{label} cab window pillar seal", pillar, trim, root)

    def roof_section(y, width, underside, shoulder, crown):
        # The shallow roof skin has its own cross section. The deeper body
        # profile would fold its lower vertices through the outer surface.
        return [
            (-width*.96, y, underside),
            (-width, y, shoulder),
            (-width*.86, y, crown-.020),
            (-width*.55, y, crown-.006),
            (0, y, crown),
            (width*.55, y, crown-.006),
            (width*.86, y, crown-.020),
            (width, y, shoulder),
            (width*.96, y, underside),
            (0, y, underside-.003),
        ]

    mesh_from_rings("Cab roof", [
        (-1.04, .876, 1.984, 2.003, 2.042),
        (-.88, .908, 1.990, 2.038, 2.103),
        (-.57, .916, 1.996, 2.047, 2.127),
        (.66, .916, 1.996, 2.047, 2.126),
        (.91, .907, 1.968, 2.018, 2.090),
        (1.035, .886, 1.929, 1.964, 2.030),
    ], paint, root, bevel=.012, section=roof_section)
    for index, x in enumerate([-.60, .16]):
        spindle = (x, -1.427, 1.501)
        pivot = bpy.data.objects.new(f"PickupWiperPivot_{index}", None)
        bpy.context.collection.objects.link(pivot)
        pivot.location = spindle
        attach(pivot, root)
        panel("Wiper spindle cap", spindle, (.066, .041, .056), trim, .018)
        panel("Wiper arm", (x+.155, -1.408, 1.518), (.32, .024, .026), trim, .008, pivot)
        panel("Wiper blade", (x+.272, -1.396, 1.529), (.34, .026, .028), rubber, .010, pivot)

    panel("Centre brake lamp", (0, 1.048, 1.984), (.31, .048, .047), red, .011)
    panel("Cargo bed floor", (0, 2.02, .91), (1.91, 1.69, .12), liner)
    panel("Bed front bulkhead", (0, 1.26, 1.09), (1.86, .13, .40), liner)
    panel("Tailgate", (0, 2.84, 1.10), (1.93, .14, .49), paint)
    panel("Tailgate handle bezel", (0, 2.919, 1.22), (.295, .028, .089), trim, .019)
    panel("Tailgate finger pocket", (0, 2.935, 1.21), (.243, .012, .043), liner, .011)
    for x in [-.104, .104]:
        panel("Tailgate handle pivot", (x, 2.946, 1.235), (.027, .029, .030), trim, .008)
    panel("Tailgate bridge grip", (0, 2.961, 1.235), (.229, .025, .026), alloy, .009)
    panel("Rear step bumper", (0, 2.89, .72), (2.03, .34, .23), trim, .085)
    for side in [-1, 1]:
        panel("Rear bumper step insert", (side*.59, 2.923, .835),
              (.54, .205, .023), liner, .018)
        for row in range(4):
            panel("Rear bumper step tread", (side*.59, 2.855+row*.044, .847),
                  (.464, .014, .012), trim, .005)
    for index in range(-6, 7):
        panel("Cargo floor rib", (index*.125, 2.04, .976), (.040, 1.48, .017), liner, .006)
    for side in [-1, 1]:
        panel("Bed side", (side*.963, 2.06, 1.12), (.21, 1.66, .46), paint, .072)
        panel("Bed rail cap", (side*.965, 2.06, 1.352), (.23, 1.68, .048), trim)
        panel("Cargo liner side", (side*.845, 2.06, 1.139), (.052, 1.53, .34), liner)
        for y in [1.51, 2.54]:
            panel("Cargo tie-down", (side*.812, y, 1.18), (.034, .079, .052), alloy, .012)
        panel("Tail lamp housing", (side*.965, 2.852, 1.13), (.194, .16, .40), trim)
        for label, z, finish in [
            ("Rear tail lamp lens", .981, red),
            ("Rear reversing lens", 1.074, reverse),
            ("Rear brake lamp lens", 1.172, red),
            ("Rear indicator lens", 1.263, amber),
        ]:
            panel(label, (side*.965, 2.937, z), (.137, .032, .062), finish, .012)
        panel("Running board beam", (side*1.07, -.09, .59), (.21, 2.26, .09), trim)
        for y in [-.667, .475]:
            panel("Running board bracket", (side*.937, y, .562),
                  (.28, .104, .050), alloy, .012)
            panel("Running board grip pad", (side*1.079, y, .635),
                  (.167, 1.02, .021), liner, .010)
            for index in range(8):
                panel("Running board tread", (side*1.079, y + (index-3.5)*.112, .648),
                      (.137, .032, .013), trim, .004)
        panel("Running board outer trim", (side*1.174, -.09, .609),
              (.019, 2.15, .026), alloy, .007)
        panel("Cab window divider", (side*.894, -.03, 1.65), (.086, .082, .62), trim)
        for y in [-.56, .67]:
            z = 1.213
            hit, surface, _, _ = body_surface.ray_cast((side*1.4, y, z), (-side, 0, 0))
            if not hit:
                raise ValueError("Door handle outside pickup body")
            x = surface.x
            panel("Door pull bezel", (x+side*.004, y, z), (.022, .231, .082), trim, .011)
            panel("Door pull finger pocket", (x+side*.013, y, z-.006),
                  (.011, .175, .042), liner, .005)
            for end in [-1, 1]:
                panel("Door pull end mount", (x+side*.022, y+end*.079, z+.009),
                      (.029, .036, .034), trim, .009)
            panel("Door pull bridge", (x+side*.039, y, z+.011),
                  (.028, .179, .025), alloy, .008)
            if y < 0:
                cylinder("Front door lock cylinder", (x+side*.017, y+.095, z-.018),
                         .008, .006, chrome, vertices=16, root=root)
                panel("Front door key slot", (x+side*.021, y+.095, z-.018),
                      (.002, .008, .002), liner, .0008)
        # The outer shut line follows the sills and rises around both doors.
        for label, path in [
            ("Door perimeter", [(-1.32, 1.302), (-1.30, 1.17), (-1.226, .877),
                                (-1.184, .818), (-1.098, .792), (-.74, .767),
                                (-.035, .767), (.69, .767), (.895, .791),
                                (.992, .860), (1.078, 1.04), (1.114, 1.293)]),
            ("Door centre", [(-.035, .771), (-.035, 1.014), (-.035, 1.19), (-.035, 1.309)]),
        ]:
            samples = []
            for start, end in zip(path, path[1:]):
                count = math.ceil(math.dist(start, end) / .025)
                samples.extend(
                    (start[0] + (end[0]-start[0])*i/count,
                     start[1] + (end[1]-start[1])*i/count)
                    for i in range(count)
                )
            samples.append(path[-1])
            sections = []
            for index, (y, z) in enumerate(samples):
                before = samples[max(0, index-1)]
                after = samples[min(len(samples)-1, index+1)]
                dy, dz = after[0]-before[0], after[1]-before[1]
                length = math.hypot(dy, dz)
                section = []
                for width, relief in [(-.004, -.002), (-.0035, .003),
                                      (.0035, .003), (.004, -.002)]:
                    yy, zz = y - width*dz/length, z + width*dy/length
                    hit, surface, _, _ = body_surface.ray_cast((side*1.4, yy, zz), (-side, 0, 0))
                    if not hit:
                        raise ValueError(f"{label} outside pickup body")
                    section.append((surface.x+side*relief, yy, zz))
                sections.append(section)
            profile_loft(f"{label} shut line", sections, trim, root)
        panel("Mirror door mount", (side*.925, -.991, 1.516), (.102, .174, .115), trim, .024)
        stem = panel("Mirror stem", (side*1.033, -1.004, 1.519), (.239, .086, .063), trim, .021)
        stem.rotation_euler.z = -side*.12
        cylinder("Mirror folding pivot", (side*1.124, -1.016, 1.544),
                 .042, .067, trim, False, 20, root)
        outline = [(-.96, -.55), (-.74, -.91), (.55, -.98), (.92, -.69),
                   (1, .48), (.76, .89), (-.58, 1), (-.90, .74)]
        for label, finish, sections in [
            ("Mirror housing", trim, [(-1.112, .064, .043), (-1.09, .092, .064),
                                      (-1.035, .123, .085), (-.903, .123, .085),
                                      (-.875, .112, .076)]),
            ("Mirror glass gasket", rubber, [(-.878, .105, .070), (-.867, .105, .070)]),
            ("Mirror glass", chrome, [(-.870, .094, .061), (-.863, .094, .061)]),
        ]:
            rings = [
                [(side*(1.169+x*width), y, 1.577+z*height) for x, z in outline]
                for y, width, height in sections
            ]
            part = profile_loft(label, rings, finish, root)
            if label == "Mirror glass":
                for face in part.data.polygons:
                    face.use_smooth = False
        for y in [-1.78, 1.96]:
            # Sweep a rounded lip around the tyre, tapering the ends into the body.
            arch_sections = []
            for index in range(33):
                angle = math.radians(7 + 166 * index / 32)
                flare = min(1.0, min(index, 32-index) / 4)
                outer = 1.093 + .049 * flare
                profile = [
                    (.965, .503), (outer-.018, .503), (outer-.004, .514),
                    (outer, .537), (outer-.009, .563), (outer-.033, .581),
                    (1.052, .589), (.965, .577),
                ]
                arch_sections.append([
                    (side*x, y + radius*math.cos(angle), .433 + radius*math.sin(angle))
                    for x, radius in profile
                ])
            profile_loft("Continuous wheel arch molding", arch_sections, trim, root)
            wheel = cylinder("All terrain tire", (side*1.012, y, .433), .433, .326, rubber, root=root)
            barrel_profile = [(1.152, .229), (1.218, .229), (1.234, .234),
                              (1.237, .246), (1.230, .254), (1.152, .254)]
            barrel_sections = []
            for index in range(49):
                angle = index*math.tau/48
                barrel_sections.append([
                    (side*x, y+radius*math.cos(angle), .433+radius*math.sin(angle))
                    for x, radius in barrel_profile
                ])
            barrel = profile_loft("Alloy wheel barrel", barrel_sections, alloy, None, close_ends=False)
            attach(barrel, wheel)
            cylinder("Brake rotor behind spokes", (side*1.179, y, .433),
                     .183, .016, trim, root=wheel)
            caliper = panel("Red brake caliper", (side*1.188, y+.148, .562),
                            (.039, .083, .095), brake_enamel, .014)
            caliper.rotation_euler.x = -.66
            valve_angle = math.pi/8
            valve_y = y + .244*math.cos(valve_angle)
            valve_z = .433 + .244*math.sin(valve_angle)
            cylinder("Tire valve stem", (side*1.244, valve_y, valve_z),
                     .0047, .028, chrome, vertices=12, root=wheel)
            cylinder("Tire valve cap", (side*1.259, valve_y, valve_z),
                     .006, .010, trim, vertices=10, root=wheel)
            cylinder("Wheel hub mounting face", (side*1.212, y, .433),
                     .096, .032, alloy, root=wheel)
            cylinder("Center cap", (side*1.233, y, .433), .053, .022, chrome, root=wheel)
            for index in range(6):
                angle = index*math.tau/6
                cylinder("Wheel lug fastener",
                         (side*1.233, y+.071*math.cos(angle), .433+.071*math.sin(angle)),
                         .010, .012, chrome, vertices=6, root=wheel)
            for index in range(8):
                angle = index * math.tau/8
                spoke = panel("Wheel spoke", (side*1.222, y+.15*math.cos(angle), .433+.15*math.sin(angle)), (.034, .18, .038), alloy, .014, wheel)
                spoke.rotation_euler.x = angle
            tread = bpy.data.objects.new("Staggered tire tread", tread_mesh)
            bpy.context.collection.objects.link(tread)
            tread.location = (side*1.012, y, .433)
            attach(tread, wheel)
            bevel = tread.modifiers.new("Rounded tread edges", "BEVEL")
            bevel.width = .003
            bevel.segments = 1

    panel("Front bumper", (0, -2.85, .76), (2.10, .39, .32), trim, .11)
    panel("Lower intake", (0, -3.044, .80), (1.26, .052, .127), liner)
    panel("Skid plate", (0, -3.006, .647), (.84, .14, .12), alloy)
    panel("Grille surround", (0, -2.916, 1.155), (1.46, .17, .44), trim, .10)
    panel("Recessed grille", (0, -3.011, 1.158), (1.28, .025, .31), liner)
    for row in range(6):
        panel("Grille slat", (0, -3.03, 1.029+row*.051), (1.23, .019, .012), alloy, .003)
    for side in [-1, 1]:
        panel("Headlight housing", (side*.849, -2.935, 1.241), (.335, .16, .221), trim)
        panel("LED light signature", (side*.839, -3.023, 1.273), (.261, .038, .049), white)
        panel("Projector lens", (side*.841, -3.022, 1.205), (.185, .027, .053), white)
        panel("Front amber marker", (side*.972, -3.012, 1.227), (.025, .029, .115), amber)
        panel("Fog light", (side*.811, -3.041, .777), (.131, .022, .047), white)
    panel("Raised hood scoop", (0, -1.957, 1.468), (.69, .65, .111), paint, .053)
    panel("Scoop opening", (0, -2.234, 1.497), (.55, .147, .055), liner, .025)
    for x in [-.16, 0, .16]:
        panel("Scoop marker", (x, -2.304, 1.499), (.042, .018, .015), amber, .005)

    plate_white = material("Reflective plate enamel", (.84, .86, .82), .02, .44)
    plate_blue = material("Blue registration band", (.023, .089, .39), .02, .48)
    for end, y, z in [("Front", -3.076, .779), ("Rear", 3.054, .723)]:
        direction = math.copysign(1, y)
        panel(f"{end} plate holder", (0, y, z), (.487, .036, .119), trim, .014)
        panel("Front number plate" if end == "Front" else "Registration plate", (0, y+direction*.022, z),
              (.455, .014, .094), plate_white, .004)
        panel(f"{end} plate blue band", (direction*.201, y+direction*.030, z),
              (.043, .004, .083), plate_blue, .002)
        number = text_obj(f"{end} registration", "HBR 264", (0, y+direction*.032, z),
                          .067, liner, root=root, flat=True)
        number.rotation_euler = (math.pi/2, 0, math.pi if direction > 0 else 0)
        xs = [vertex.co.x for vertex in number.data.vertices]
        ys = [vertex.co.y for vertex in number.data.vertices]
        number.location.x = direction*((min(xs)+max(xs))*.5-.012)
        number.location.z -= (min(ys)+max(ys))*.5

    for x in [-.154, .154]:
        panel("Rear plate lamp housing", (x, 3.074, .785), (.078, .046, .027), trim, .008)
        panel("Rear plate lamp diffuser", (x, 3.085, .773), (.060, .026, .009), white, .003)

    curve = bpy.data.curves.new("DAM grille lettering", 'FONT')
    curve.body = "DAM"
    curve.align_x = 'CENTER'
    curve.align_y = 'CENTER'
    curve.size = .275
    curve.extrude = .009
    curve.bevel_depth = .002
    lettering = bpy.data.objects.new("DAM grille badge", curve)
    bpy.context.collection.objects.link(lettering)
    lettering.location = (0, -3.052, 1.172)
    lettering.rotation_euler.x = math.pi/2
    curve.materials.append(chrome)
    attach(lettering, root)
    bpy.ops.object.select_all(action="DESELECT")
    lettering.select_set(True)
    bpy.context.view_layer.objects.active = lettering
    bpy.ops.object.convert(target='MESH')
    export_vehicle(root, "dam_pickup.glb")
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(PROJECT / "source_blender" / "dam_pickup.blend"), compress=True)


if __name__ == "__main__":
    build_pickup()
