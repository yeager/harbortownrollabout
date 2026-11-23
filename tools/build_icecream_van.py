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
    speaker = disc("Roof loudspeaker", (s*.61,-.93,2.65),.145,.22,v.DARK)
    speaker.rotation_euler = (math.pi/2,0,0)
    cap = disc("Speaker grille", (s*.61,-1.047,2.65),.112,.018,v.BLACK)
    cap.rotation_euler = speaker.rotation_euler
    box("Tail lamp",(s*.80,2.99,.96),(.35,.06,.13),v.TAIL_LAMP)
box("Roof lightbox",(0,-.91,2.67),(1.03,.23,.28),v.PAINT_WHITE)
box("Rear menu surround",(0,2.979,1.81),(1.78,.05,1.33),v.METAL)
box("Illustrated menu",(0,3.01,1.81),(1.69,.025,1.24),v.PAINT_WHITE)
berry = v.material("Blueberry violet", (.34,.09,.80))
lemon = v.material("Lemon yellow", (1,.73,.035))
melon = v.material("Watermelon coral", (1,.13,.18))
for index, finish in enumerate((pink,mint,berry,lemon,melon,blue)):
    x = .55 - index%3*.55
    z = 1.94 - (index//3)*.47
    box("Menu card",(x,3.035,z-.04),(.52,.016,.445),cream,.015)
    def sweet(name, dx, dz, width, height, material, y=3.09):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, location=(x+dx,y,z+dz))
        part = bpy.context.object
        part.name = name
        part.scale = (width,.025,height)
        part.parent = root
        part.data.materials.append(material)

    if index == 0:
        bpy.ops.mesh.primitive_cone_add(vertices=18,radius1=.008,radius2=.084,depth=.15,location=(x,3.07,z))
        cone = bpy.context.object
        cone.parent = root
        cone.data.materials.append(lemon)
        sweet("Berry scoop",0,.095,.105,.072,pink)
        sweet("Cherry",.043,.157,.027,.026,melon)
        continue
    box("Wooden stick",(x,3.052,z-.047),(.032,.018,.098),v.material("Beech",(.74,.47,.23)),.009)
    if index == 2:
        for dx,dz in ((-.052,.045),(.053,.045),(0,.119)):
            sweet("Hiccup bubble",dx,dz,.064,.06,berry)
    elif index == 4:
        for row in range(9):
            width = .22-.022*row
            box("Melon slice",(x,3.075,z+.017*row),(width,.05,.022),melon if row else mint,.006)
        for dx,dz in ((-.05,.04),(.034,.052),(0,.092)):
            sweet("Melon seed",dx,dz,.008,.013,ink,3.10)
    else:
        box("Fruit ice",(x,3.066,z+.068),(.16,.055,.195),finish,.035)
        if index == 1:
            for sign in (-1,1):
                sweet("Mint ear",sign*.081,.143,.036,.025,mint)
                sweet("Eye",sign*.037,.095,.009,.01,ink,3.102)
            sweet("Muzzle",0,.043,.048,.025,pink,3.104)
        elif index == 3:
            for sign in (-1,1):
                fin=box("Rocket fin",(x+sign*.077,3.067,z+.008),(.04,.045,.085),melon,.009)
                fin.rotation_euler.y=sign*.38
            sweet("Porthole",0,.098,.034,.034,blue,3.101)
        else:
            for angle in (0,math.pi/3,-math.pi/3):
                ray=box("Snow crystal",(x,3.101,z+.071),(.015,.012,.13),v.PAINT_WHITE,.004)
                ray.rotation_euler.y=angle
box("Folding sales shelf",(0,3.05,1.09),(1.36,.22,.07),v.METAL)
v.export_vehicle(root, "ice_cream_van.glb")
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR) / "IceCreamVan.blend"))
