"""Generate the Sjöstaden freezer van, with service hatches and roof loudspeakers."""
import math
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
bpy.context.preferences.filepaths.save_version = 0
root = bpy.data.objects.new("Sjöstadsglass", None)
bpy.context.collection.objects.link(root)
blue = v.material("Glacier blue enamel", (.09, .57, .81), .25, .28)
ink = v.material("Marine blue signwriting", (.012, .058, .21))
pink = v.material("Strawberry ice", (.96, .2, .43))
mint = v.material("Pistachio ice", (.24, .79, .48))
cream = v.material("Vanilla ice", (.98, .83, .55))


def box(name, pos, size, mat, radius=.025):
    return v.cube(name, pos, size, mat, radius, root)


def disc(name, pos, radius, depth, mat):
    return v.cylinder(name, pos, radius, depth, mat, root=root)


def front_text(name, text, pos, size, mat, rear=False):
    obj = v.text_obj(name, text, pos, size, mat, root=root)
    obj.rotation_euler = (math.pi / 2, 0, math.pi if rear else 0)
    return obj


def window(name, vertices):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], [(0, 1, 2, 3), (3, 2, 1, 0)])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(v.GLASS)
    obj.parent = root


box("Chassis", (0, 0, .54), (1.45, 5.65, .26), v.DARK)
v.mesh_from_rings("Pressed steel bonnet and cab", [
    (-2.98,.85,.53,1.03,1.10), (-2.79,.98,.52,1.21,1.33),
    (-2.04,1.0,.57,1.37,1.49), (-1.25,1.0,.63,2.30,2.46),
    (-.46,1.0,.64,2.32,2.48)], blue, root)
window("Swept windscreen", [(-.84,-2.04,1.47),(.84,-2.04,1.47),
                            (.79,-1.28,2.43),(-.79,-1.28,2.43)])
box("Freezer body", (0,1.25,1.72), (2.14,3.43,1.76), blue,.075)
box("Front bumper", (0,-2.97,.69), (1.91,.17,.30), v.DARK,.08)
box("Radiator", (0,-2.95,.99), (1.16,.10,.28), v.BLACK)
for h in (.91,1,1.09):
    box("Grille louvre", (0,-3.007,h), (1.08,.025,.018), v.METAL)
for side in (-1,1):
    s = side
    window("Cab door window", [(s*1.012,-1.93,1.47),(s*1.012,-.55,1.47),
                               (s*.958,-.55,2.23),(s*.958,-1.25,2.23)])
    box("Mirror arm",(s*1.05,-1.77,1.59),(.26,.07,.07),v.DARK)
    box("Door mirror",(s*1.20,-1.75,1.71),(.16,.20,.33),v.DARK)
    box("Door handle",(s*1.012,-.65,1.34),(.05,.19,.055),v.DARK)
    box("Headlight lens",(s*.77,-2.926,1.09),(.32,.09,.14),v.HEADLAMP)
    for y in (-1.96,1.85):
        disc("Däck", (s*.91,y,.405), .405,.26,v.RUBBER)
        disc("Wheel hub steel", (s*1.05,y,.405), .255,.065,v.METAL)
        disc("Center cap", (s*1.088,y,.405), .115,.035,v.DARK)
        for n in range(8):
            a = n*math.tau/8
            disc("Fälghål", (s*1.087,y+.184*math.sin(a),.405+.184*math.cos(a)), .026,.01,v.DARK)
    box("Continuous side step",(s*1.07,1.13,.76),(.15,3.41,.065),v.METAL)
    for y in (.12,1.25,2.38):
        box("Hatch gasket",(s*1.07,y,1.56),(.018,1.07,1.15),ink)
        box("Freezer hatch",(s*1.088,y,1.56),(.025,1.055,1.13),blue)
        box("Flush latch",(s*1.111,y+.40,1.56),(.035,.055,.14),v.METAL)
        for off in (-.34,.34):
            box("Insulated hinge",(s*1.11,y+off,2.12),(.03,.13,.046),v.METAL)
    v.text_obj("Route lettering","SJÖSTADSGLASS",(s*1.076,1.25-s*.97,2.29),.26,ink,side=-s,root=root)
    speaker = disc("Roof loudspeaker", (s*.61,-.93,2.65),.145,.22,v.DARK)
    speaker.rotation_euler = (math.pi/2,0,0)
    cap = disc("Speaker grille", (s*.61,-1.047,2.65),.112,.018,v.BLACK)
    cap.rotation_euler = speaker.rotation_euler
    box("Tail lamp",(s*.80,2.99,.96),(.35,.06,.13),v.TAIL_LAMP)
box("Roof lightbox",(0,-.91,2.67),(1.03,.23,.28),v.PAINT_WHITE)
front_text("Illuminated roof board","GLASS",( -.32,-1.035,2.60),.21,ink)
box("Rear menu surround",(0,2.979,1.81),(1.78,.05,1.33),v.METAL)
box("Illustrated menu",(0,3.01,1.81),(1.69,.025,1.24),v.PAINT_WHITE)
front_text("Menu title","VÅRA GLASSAR",(.68,3.036,2.16),.18,ink,True)
for row in range(2):
    for col,flavour in enumerate((pink,mint,cream,pink,mint)):
        x = -.63+col*.315
        z = 1.55+row*.38
        box("Beech lolly stick",(x,3.032,z-.15),(.035,.025,.10),cream)
        box("Menu ice lolly",(x,3.053,z),(.12,.045,.21),flavour,.045)
box("Folding sales shelf",(0,3.05,1.09),(1.36,.22,.07),v.METAL)
v.export_vehicle(root, "ice_cream_van.glb")
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR) / "IceCreamVan.blend"))
