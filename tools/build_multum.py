"""Build the Fait Multum family car."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Fait Multum", None)
bpy.context.collection.objects.link(root)
paint = v.material("Lagoon teal enamel", (.035, .37, .41), .48, .27)
glazing = v.material("Smoked blue glass", (.045, .102, .126), .28, .18)
amber = v.material("Amber signal glass", (.91, .29, .015))
reverse = v.material("Reverse lamp clear glass", (.72, .84, .89))
cream = v.material("Warm ivory plate", (.91, .90, .82))

def box(name, point, dimensions, finish, radius=.024):
    return v.cube(name, point, dimensions, finish, radius, root)

def rod(name, a, b, radius, finish):
    a, b = Vector(a), Vector(b)
    obj = v.cylinder(name, (a+b)/2, radius, (b-a).length, finish, False, 20, root)
    obj.rotation_euler = (b-a).to_track_quat("Z", "Y").to_euler()

def lamp(name, x, y, z, radius, finish):
    obj = v.cylinder(name, (x,y,z), radius, .034, finish, False, 32, root)
    obj.rotation_euler.x = math.pi/2

body = v.mesh_from_rings("Rounded body and short bonnet", [
    (-2.04,.75,.25,.54,.72),(-1.92,.88,.23,.62,.81),
    (-1.61,.92,.22,.69,.89),(-1.15,.925,.22,.77,.99),
    (-.67,.92,.22,.94,1.04),(.24,.92,.22,.94,1.04),
    (1.25,.91,.23,.95,1.05),(1.82,.88,.27,.94,1.04),
    (1.99,.79,.32,.91,1.00),
], paint, root, bevel=0)
for side in (-1,1):
    for y in (-1.28,1.30):
        cutter = v.cylinder("Wheel opening tool", (side*.94,y,.33), .383,.68,None)
        bpy.context.view_layer.objects.active = body
        cut = body.modifiers.new("Wheel arch", "BOOLEAN")
        cut.object = cutter
        cut.operation = "DIFFERENCE"
        bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(cutter, do_unlink=True)
edge = body.modifiers.new("Soft body highlights","BEVEL")
edge.width = .013
edge.segments = 3
body.modifiers.new("Body normals","WEIGHTED_NORMAL")

def cabin_section(y,w,base,shoulder,crown):
    return [(-w,y,base),(-w*.975,y,shoulder),(-w*.91,y,crown-.027),
            (0,y,crown),(w*.91,y,crown-.027),(w*.975,y,shoulder),(w,y,base)]

cabin = [
    (-1.285,.79,1.015,1.115,1.15),(-1.12,.85,1.035,1.26,1.30),
    (-.72,.871,1.055,1.59,1.65),(-.31,.87,1.065,1.707,1.77),
    (.40,.856,1.067,1.735,1.795),(1.17,.846,1.068,1.725,1.784),
    (1.65,.819,1.066,1.68,1.748),(1.83,.765,1.063,1.575,1.654),
    (1.87,.747,1.055,1.40,1.52),
]
v.mesh_from_rings("Panoramic glasshouse", cabin, glazing, root,.014,cabin_section)
v.mesh_from_rings("Rounded roof skin", [
    (y,w*.92,c-.037,c-.014,c+.012) for y,w,b,s,c in cabin[2:-1]
], paint, root,.015,cabin_section)
v.mesh_from_rings("Raised cowl under the windscreen", [
    (-1.41,.68,.901,.978,1.055),(-1.35,.785,.916,1.021,1.100),
    (-1.28,.849,.932,1.050,1.124),(-1.14,.863,.963,1.068,1.151),
    (-1.02,.854,.985,1.091,1.174),
], paint, root, bevel=0)

for side in (-1,1):
    for y,width,top in [(-.31,.87,1.741),(.57,.856,1.768),(1.42,.84,1.73)]:
        rod("Window pillar",(side*width,y,1.052),(side*width*.928,y,top),.024,v.DARK)
    for a,b in zip(cabin,cabin[1:]):
        rod("Window lower seal",(side*a[1],a[0],a[2]),(side*b[1],b[0],b[2]),.017,v.DARK)
    for y in (-.17,.91):
        box("Door rubbing strip",(side*.919,y,.645),(.038,.85,.057),v.DARK,.019)
        box("Oval door handle",(side*.924,y+.30,.918),(.043,.139,.056),v.DARK,.021)
    for y in (.23,1.35):
        rod("Door shut line",(side*.922,y,.44),(side*.924,y,.945),.005,v.DARK)
    box("Mirror mount",(side*.869,-.78,1.141),(.139,.114,.085),v.DARK)
    box("Rounded mirror housing",(side*.970,-.755,1.193),(.167,.146,.155),v.DARK,.042)
    box("Mirror glass",(side*.970,-.674,1.193),(.114,.014,.104),v.METAL,.007)
    lamp("Upper headlight surround",side*.694,-1.385,1.087,.078,v.DARK)
    lamp("Upper headlight",side*.694,-1.406,1.087,.062,v.HEADLAMP)
    lamp("Lower headlight surround",side*.655,-2.043,.672,.092,v.DARK)
    lamp("Lower headlight",side*.655,-2.065,.672,.079,v.HEADLAMP)
    lamp("Front amber indicator",side*.816,-1.987,.671,.052,amber)
    lamp("Bumper fog lamp",side*.658,-2.102,.374,.043,v.HEADLAMP)
    box("Rear lamp housing",(side*.754,1.938,.865),(.179,.115,.297),v.DARK,.036)
    lamp("Tail lamp",side*.748,2.000,.937,.065,v.TAIL_LAMP)
    lamp("Rear indicator lens",side*.776,2.006,.835,.052,amber)
    lamp("Reversing lens",side*.733,2.004,.762,.030,reverse)
    for y in (-1.28,1.30):
        v.cylinder("Däck",(side*.797,y,.318),.318,.197,v.RUBBER,True,48,root)
        v.cylinder("Wheel hub barrel",(side*.884,y,.318),.209,.045,v.DARK,True,40,root)
        v.cylinder("Wheel hub cap",(side*.913,y,.318),.077,.028,v.METAL,True,32,root)
        for i in range(8):
            angle = i*math.tau/8
            rod("Wheel hub spoke",(side*.915,y+.062*math.cos(angle),.318+.062*math.sin(angle)),
                (side*.908,y+.195*math.cos(angle+.10),.318+.195*math.sin(angle+.10)),.022,v.METAL)

box("Front bumper", (0,-1.983,.418),(1.68,.225,.315),v.DARK,.071)
box("Rear bumper", (0,1.929,.433),(1.69,.211,.271),v.DARK,.074)
box("Lower grille recess",(0,-2.100,.384),(.91,.031,.169),v.RUBBER,.013)
for z in (.338,.383,.428):
    box("Lower grille rail",(0,-2.118,z),(.833,.020,.014),v.DARK,.005)
box("Bonnet intake",(0,-2.039,.615),(.78,.028,.065),v.DARK,.012)
for y, sign in [(-2.116,-1),(2.049,1)]:
    box("Registration plate",(0,y,.525),(.465,.024,.106),cream,.010)
    text = v.text_obj("Registration","FA 608",(-.167 if sign<0 else .167,y+sign*.016,.497),
                      .077,v.DARK,root=root,flat=True)
    text.rotation_euler = (math.pi/2,0,0 if sign<0 else math.pi)
badge = v.text_obj("Multum hatch badge","MULTUM",(.208,2.008,.842),.086,
                   v.METAL,root=root,flat=True)
badge.rotation_euler = (math.pi/2,0,math.pi)
box("Fait enamel badge",(0,-1.414,1.049),(.109,.025,.074),v.DARK,.011)
logo = v.text_obj("Fait badge lettering","FAIT",(-.041,-1.433,1.032),.034,
                  cream,root=root,flat=True)
logo.rotation_euler = (math.pi/2,0,0)
rod("Roof antenna",(0,.14,1.805),(0,.31,2.078),.009,v.DARK)
for x in (-.48,.22):
    rod("Windscreen wiper arm",(x,-1.208,1.203),(x+.18,-1.055,1.345),.011,v.DARK)
    rod("Windscreen wiper blade",(x+.035,-1.104,1.305),(x+.33,-.997,1.393),.013,v.DARK)
rod("Rear window wiper",(-.30,1.873,1.31),(.20,1.894,1.24),.012,v.DARK)
v.export_vehicle(root,"multum.glb")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR)/"Multum.blend"))
