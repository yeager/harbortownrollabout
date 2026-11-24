"""Build the DAM double-cab pickup and its editable Blender source."""
import math
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import attach, clear_scene, cube, cylinder, export_vehicle, material, mesh_from_rings

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
    white = material("Headlight lens", (.81, .91, 1), .1, .21, .5)
    reverse = material("Reverse lamp clear", (.81, .91, 1), .1, .21)
    red = material("Tail lamp ruby", (.57, .018, .022), .06, .25, .22)
    amber = material("Amber markers", (.95, .31, .018), .02, .3, .45)

    def panel(name, position, dimensions, finish, bevel=.035, parent=root):
        return cube(name, position, dimensions, finish, bevel, parent)

    mesh_from_rings("Pickup body", [
        (-2.91, .94, .75, 1.32, 1.36), (-2.53, 1.03, .69, 1.40, 1.47),
        (-1.52, 1.05, .78, 1.39, 1.43), (-.86, 1.01, .63, 1.32, 1.36),
        (.95, 1.02, .63, 1.30, 1.35), (1.37, 1.02, .73, 1.27, 1.28),
    ], paint, root)
    panel("Frame rails", (0, .02, .63), (1.50, 5.45, .21), trim)
    mesh_from_rings("Cab glazing", [
        (-1.44, .97, 1.30, 1.44, 1.44), (-1.00, .91, 1.34, 1.98, 2.00),
        (-.77, .92, 1.34, 2.03, 2.05), (.83, .92, 1.34, 2.03, 2.05),
        (1.08, .95, 1.34, 1.91, 1.96), (1.23, .96, 1.34, 1.39, 1.42),
    ], glass, root, bevel=.018)
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
    panel("Tailgate handle", (0, 2.922, 1.22), (.28, .045, .074), trim)
    panel("Rear step bumper", (0, 2.89, .72), (2.03, .34, .23), trim, .085)
    for index in range(-6, 7):
        panel("Cargo floor rib", (index*.125, 2.04, .976), (.040, 1.48, .017), liner, .006)
    for side in [-1, 1]:
        panel("Bed side", (side*.963, 2.06, 1.12), (.21, 1.66, .46), paint, .072)
        panel("Bed rail cap", (side*.965, 2.06, 1.352), (.23, 1.68, .048), trim)
        panel("Cargo liner side", (side*.845, 2.06, 1.139), (.052, 1.53, .34), liner)
        for y in [1.51, 2.54]:
            panel("Cargo tie-down", (side*.812, y, 1.18), (.034, .079, .052), alloy, .012)
        panel("Tail lamp housing", (side*.965, 2.852, 1.13), (.194, .16, .40), trim)
        for z in [.99, 1.11, 1.24]:
            panel("Rear lamp lens", (side*.965, 2.941, z), (.137, .032, .073), reverse if z == 1.11 else red)
        panel("Running board", (side*1.07, -.09, .59), (.21, 2.26, .09), trim)
        panel("Cab window divider", (side*.894, -.03, 1.65), (.086, .082, .62), trim)
        for y in [-.56, .67]:
            panel("Door pull", (side*1.015, y, 1.213), (.046, .19, .055), trim)
        panel("Door seam", (side*1.023, -.035, .98), (.012, .014, .50), trim, .004)
        panel("Mirror stem", (side*1.02, -.99, 1.52), (.31, .107, .08), trim)
        panel("Mirror housing", (side*1.17, -.99, 1.57), (.234, .236, .131), trim)
        panel("Mirror glass", (side*1.17, -.862, 1.57), (.184, .022, .084), chrome)
        for y in [-1.78, 1.96]:
            # Segmented arches follow the tyre instead of filling the wheel opening.
            for angle_index in range(11):
                angle = math.radians(10 + 16*angle_index)
                arch = panel("Wheel arch molding", (side*1.051, y + .54*math.cos(angle), .45 + .54*math.sin(angle)), (.178, .174, .085), trim, .022)
                arch.rotation_euler.x = angle - math.pi/2
            wheel = cylinder("All terrain tire", (side*1.012, y, .433), .433, .326, rubber, root=root)
            cylinder("Alloy wheel hub", (side*1.179, y, .433), .253, .075, alloy, root=wheel)
            cylinder("Center cap", (side*1.226, y, .433), .082, .027, chrome, root=wheel)
            for index in range(8):
                angle = index * math.tau/8
                spoke = panel("Wheel spoke", (side*1.222, y+.15*math.cos(angle), .433+.15*math.sin(angle)), (.034, .18, .038), alloy, .014, wheel)
                spoke.rotation_euler.x = angle
            for index in range(28):
                angle = index*math.tau/28
                tread = panel("Raised tread block", (side*1.012, y+.429*math.cos(angle), .433+.429*math.sin(angle)), (.30, .053, .025), rubber, .007, wheel)
                tread.rotation_euler.x = angle-math.pi/2

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
