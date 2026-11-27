"""Generate the Sjöstaden freezer van, with service hatches and roof loudspeakers."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

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
# The windscreen follows both halves of the crowned steel cab surface.
for side in (-1,1):
    window("Swept windscreen", [
        (0,-2.017,1.568),(side*.708,-2.017,1.534),
        (side*.688,-1.286,2.431),(0,-1.286,2.464),
    ])
for pivot_x in (-.52,.10):
    pivot = Vector((pivot_x,-2.079,1.501))
    blade_start = Vector((pivot_x+.102,-1.958,1.658))
    blade_end = Vector((pivot_x+.412,-1.903,1.738))
    blade_midpoint = (blade_start+blade_end)/2
    v.cylinder("Wiper spindle cap",pivot,.024,.028,v.DARK,False,20,root)
    arm = box("Wiper arm",(pivot+blade_midpoint)/2,
              ((blade_midpoint-pivot).length,.017,.016),v.DARK,.004)
    arm.rotation_euler = (blade_midpoint-pivot).to_track_quat("X","Z").to_euler()
    blade = box("Wiper blade",blade_midpoint,
                ((blade_end-blade_start).length,.021,.018),v.RUBBER,.004)
    blade.rotation_euler = (blade_end-blade_start).to_track_quat("X","Z").to_euler()
box("Freezer body", (0,1.25,1.72), (2.14,3.43,1.76), blue,.075)
box("Front bumper", (0,-2.97,.69), (1.91,.17,.30), v.DARK,.08)
box("Recessed radiator core",(0,-2.983,.997),(1.11,.035,.281),v.BLACK,.018)
for x in (-.566,.566):
    box("Grille side frame",(x,-3.036,.997),(.053,.116,.308),v.DARK,.016)
for z in (.857,1.137):
    box("Grille horizontal frame",(0,-3.036,z),(1.10,.116,.041),v.DARK,.011)
for index in range(23):
    x = (index-11)*.046
    box("Radiator cooling fin",(x,-3.006,.997),(.015,.018,.235),v.DARK,.003)
for z in (.921,.997,1.073):
    box("Grille louvre",(0,-3.054,z),(1.083,.062,.025),v.METAL,.006)
reverse_glass = v.material("Reverse lamp ice van lens", (.79,.87,.93), .12,.23)
signal_glass = v.material("Amber indicator glass", (.96,.34,.018), .12,.26)
mirror_glass = v.material("Door mirror glass", (.45,.55,.62), .88,.13)
for side in (-1,1):
    s = side
    window("Cab door window", [(s*1.012,-1.93,1.47),(s*1.012,-.55,1.47),
                               (s*.958,-.55,2.23),(s*.958,-1.25,2.23)])
    box("Mirror mounting plate",(s*1.008,-1.77,1.566),(.047,.157,.145),v.DARK,.017)
    box("Mirror arm",(s*1.113,-1.77,1.581),(.224,.071,.070),v.DARK,.016)
    v.cylinder("Mirror folding pivot",(s*1.205,-1.77,1.619),.051,.102,
               v.DARK,False,24,root)
    box("Door mirror housing",(s*1.221,-1.766,1.754),(.190,.164,.300),v.DARK,.038)
    box("Mirror glass gasket",(s*1.221,-1.683,1.754),(.164,.020,.267),v.RUBBER,.009)
    box("Door mirror glass",(s*1.221,-1.670,1.754),(.146,.010,.247),mirror_glass,.004)
    box("Door handle",(s*1.012,-.65,1.34),(.05,.19,.055),v.DARK)
    box("Headlight housing",(s*.776,-2.969,1.092),(.365,.18,.177),v.DARK,.027)
    box("Headlight reflector rim",(s*.776,-3.062,1.092),(.331,.022,.149),v.METAL,.015)
    box("Headlight lens",(s*.776,-3.076,1.092),(.301,.024,.122),v.HEADLAMP,.015)
    box("Front indicator bezel",(s*.80,-3.038,.928),(.29,.075,.103),v.DARK,.017)
    box("Front amber indicator",(s*.80,-3.079,.928),(.248,.022,.073),signal_glass,.011)
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
        latch_y = y+.37
        box("Freezer latch surround",(s*1.107,latch_y,1.56),(.019,.123,.181),v.METAL,.010)
        box("Freezer latch recess",(s*1.118,latch_y,1.577),(.010,.083,.112),v.DARK,.008)
        box("Freezer latch handle",(s*1.127,latch_y,1.59),(.016,.067,.027),v.METAL,.006)
        disc("Freezer latch lock",(s*1.120,latch_y,1.500),.016,.012,v.METAL)
        box("Freezer latch keyway",(s*1.127,latch_y,1.500),(.002,.004,.014),v.BLACK,.001)
        for offset in (-.34,.34):
            hinge_y = y+offset
            box("Freezer hinge body leaf",(s*1.077,hinge_y,2.158),
                (.019,.127,.050),v.METAL,.005)
            box("Freezer hinge hatch leaf",(s*1.108,hinge_y,2.108),
                (.017,.127,.052),v.METAL,.005)
            for name, shift, radius, length in (
                ("Pin",0,.007,.133),("Centre knuckle",0,.017,.044),
                ("End knuckle",-.044,.017,.034),("End knuckle",.044,.017,.034),
            ):
                hinge = v.cylinder("Freezer hinge "+name,(s*1.106,hinge_y+shift,2.134),
                                   radius,length,v.METAL,False,16,root)
                hinge.rotation_euler.x = math.pi/2
    speaker_x = s*.665
    box("Speaker roof mounting plate",(speaker_x,-.91,2.465),(.204,.226,.029),v.DARK,.009)
    for offset in (-.08,.08):
        box("Speaker bracket upright",(speaker_x+offset,-.91,2.547),
            (.025,.080,.158),v.METAL,.006)
        v.cylinder("Speaker bracket bolt",(speaker_x+offset*1.17,-.91,2.608),
                   .018,.021,v.METAL,True,8,root)
    # Follow the outside of the horn and return along the inside of the flare.
    horn_rings = [
        (-.802,.065),(-.824,.083),(-.905,.088),(-.988,.117),
        (-1.071,.149),(-1.086,.149),(-1.092,.135),
        (-1.076,.129),(-.996,.097),(-.929,.062),(-.910,.036),
    ]
    v.profile_loft("Flared roof loudspeaker",[
        [(speaker_x+radius*math.cos(angle),y,2.65+radius*math.sin(angle))
         for angle in (step*math.tau/32 for step in range(32))]
        for y,radius in horn_rings
    ],v.DARK,root)
    driver = v.cylinder("Speaker throat driver",(speaker_x,-.951,2.65),.037,.080,
                        v.BLACK,False,20,root)
    driver.rotation_euler.x = math.pi/2
    box("Rear combination lamp housing",(s*.75,2.973,.96),(.50,.074,.167),v.DARK,.018)
    box("Rear indicator bezel",(s*.865,2.973,1.090),(.24,.074,.098),v.DARK,.014)
    box("Rear indicator lens",(s*.865,3.012,1.090),(.203,.032,.071),signal_glass,.009)
    box("Tail lamp",(s*.806,3.012,.96),(.343,.032,.124),v.TAIL_LAMP,.012)
    box("Reversing lens",(s*.562,3.012,.96),(.118,.032,.124),reverse_glass,.010)
    for offset in (-.034,0,.034):
        box("Backlight lens rib",(s*.562+offset,3.029,.96),(.009,.006,.092),
            reverse_glass,.002)
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
