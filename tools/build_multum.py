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
reflector = v.material("Passive ruby reflector", (.43, .013, .021), .12, .32)

def box(name, point, dimensions, finish, radius=.024):
    return v.cube(name, point, dimensions, finish, radius, root)

def rod(name, a, b, radius, finish):
    a, b = Vector(a), Vector(b)
    obj = v.cylinder(name, (a+b)/2, radius, (b-a).length, finish, False, 20, root)
    obj.rotation_euler = (b-a).to_track_quat("Z", "Y").to_euler()

def lamp(name, x, y, z, radius, finish):
    obj = v.cylinder(name, (x,y,z), radius, .034, finish, False, 32, root)
    obj.rotation_euler.x = math.pi/2

def headlight(label, x, y, z, radius):
    lamp(label+" gasket",x,y+.014,z,radius*1.20,v.RUBBER)
    lamp(label+" reflector rim",x,y-.002,z,radius*1.08,v.METAL)
    angles = [step*math.tau/40 for step in range(40)]
    section = [(.010,1),(.018,1),(.023,.91),(.027,.66),(.029,.24)]
    v.profile_loft(label+" lens",[
        [(x+radius*scale*math.cos(angle),y-depth,z+radius*scale*math.sin(angle))
         for angle in angles]
        for depth,scale in section
    ],v.HEADLAMP,root)

def tire(side, y):
    profile = [
        (-.098,.211),(-.098,.270),(-.092,.292),(-.080,.309),
        (-.062,.318),(-.046,.318),(-.043,.309),(-.033,.309),(-.030,.318),
        (-.007,.318),(-.004,.309),(.004,.309),(.007,.318),
        (.030,.318),(.033,.309),(.043,.309),(.046,.318),(.062,.318),
        (.080,.309),(.092,.292),(.098,.270),(.098,.211),
    ]
    angles = [step*math.tau/64 for step in range(64)]
    v.profile_loft("Däck", [
        [(side*.797+offset,y+radius*math.sin(angle),.318+radius*math.cos(angle))
         for angle in angles]
        for offset,radius in profile
    ],v.RUBBER,root)

def alloy_face(side, y):
    rim_profile = [
        (.879, .210), (.896, .214), (.912, .213), (.919, .207),
        (.919, .199), (.914, .194), (.899, .192), (.879, .195),
    ]
    angles = [step * math.tau / 64 for step in range(64)]
    v.profile_loft("Alloy rim lip", [
        [(side * depth, y + radius * math.cos(angle), .318 + radius * math.sin(angle))
         for angle in angles]
        for depth, radius in rim_profile
    ], v.METAL, root, close_ends=False)
    for spoke in range(7):
        angle = spoke * math.tau / 7
        v.profile_loft("Swept alloy spoke", [
            [(side * (depth + .011 * math.cos(section)),
              y + radius * math.cos(angle + sweep) - width * math.sin(section) * math.sin(angle + sweep),
              .318 + radius * math.sin(angle + sweep) + width * math.sin(section) * math.cos(angle + sweep))
             for section in angles[::4]]
            for radius, depth, width, sweep in [
                (.063, .907, .028, 0), (.085, .912, .028, .02),
                (.145, .906, .018, .08), (.183, .904, .016, .13),
                (.202, .902, .022, .15),
            ]
        ], v.METAL, root)

def body_section(y, width, bottom, shoulder, crown):
    half_section = [
        (width * .88, bottom), (width, bottom + .12),
        (width, shoulder - .16), (width * .981, shoulder - .065),
        (width * .93, shoulder), (width * .855, shoulder + .61 * (crown - shoulder)),
        (width * .72, crown), (width * .46, crown + .022),
        (width * .23, crown + .032),
    ]
    return ([(-x, y, z) for x, z in half_section]
            + [(0, y, crown + .035)]
            + [(x, y, z) for x, z in reversed(half_section)])


body = v.mesh_from_rings("Rounded body and short bonnet", [
    (-2.04,.75,.25,.54,.72),(-2.00,.81,.24,.575,.755),
    (-1.92,.88,.23,.62,.81),(-1.79,.906,.224,.658,.848),
    (-1.61,.92,.22,.69,.89),(-1.39,.924,.22,.725,.939),
    (-1.15,.925,.22,.77,.99),
    (-.67,.92,.22,.94,1.04),(.24,.92,.22,.94,1.04),
    (1.25,.91,.23,.95,1.05),(1.82,.88,.27,.94,1.04),
    (1.99,.79,.32,.91,1.00),
], paint, root, bevel=0, section=body_section)
for side in (-1,1):
    for y in (-1.28,1.30):
        cutter = v.cylinder("Wheel opening tool", (side*.94,y,.33), .383, .68, None, vertices=96)
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
    for y in (-.31,.23,1.35):
        # Interpolate the same cross sections used by the glasshouse shell.
        a,b = next((a,b) for a,b in zip(cabin,cabin[1:]) if a[0] <= y <= b[0])
        t = (y-a[0])/(b[0]-a[0])
        width,base,shoulder,crown = [a[i]+(b[i]-a[i])*t for i in range(1,5)]
        outline = [(width+.008,base),(.975*width+.008,shoulder),
                   (.91*width+.008,crown-.024)]
        v.profile_loft("Flush window pillar",[
            [(side*x,y+offset,z) for x,z in outline]
            for offset in (-.031,.031)
        ],v.DARK,root,close_ends=False)
    for a,b in zip(cabin,cabin[1:]):
        rod("Window lower seal",(side*a[1],a[0],a[2]),(side*b[1],b[0],b[2]),.017,v.DARK)
    for a,b in zip(cabin[2:],cabin[3:]):
        rod("Window roof seal",(side*a[1]*.91,a[0],a[4]-.022),
            (side*b[1]*.91,b[0],b[4]-.022),.015,v.DARK)
    for start, end, end_depth in [(-.704, .198, .918), (.259, 1.037, .910)]:
        sections = [
            (start, .918, .18), (start + .026, .918, .72),
            (start + .067, .918, 1), (end - .067, end_depth, 1),
            (end - .026, end_depth, .70), (end, end_depth, .18),
        ]
        v.profile_loft("Tapered door rubbing strip", [
            [(side * (depth + .020 * scale * math.cos(angle)), y,
              .645 + .029 * scale * math.sin(angle))
             for angle in (step * math.tau / 24 for step in range(24))]
            for y, depth, scale in sections
        ], v.DARK, root)
    for y in (-.17,.91):
        handle_y = y+.30
        box("Door handle gasket",(side*.919,handle_y,.918),(.026,.163,.068),v.RUBBER,.021)
        box("Recessed door handle pocket",(side*.933,handle_y,.918),
            (.018,.143,.053),v.DARK,.015)
        for offset in (-.042,.042):
            box("Door pull support",(side*.949,handle_y+offset,.918),
                (.032,.025,.031),v.DARK,.008)
        box("Oval door pull",(side*.966,handle_y,.918),(.026,.117,.026),v.DARK,.010)
        if y < 0:
            v.cylinder("Front door lock",(side*.931,handle_y,.852),
                       .012,.013,v.METAL,True,20,root)
            box("Door lock keyway",(side*.938,handle_y,.852),
                (.003,.004,.012),v.RUBBER,.001)
    for y, bottom in ((.23, .44), (1.35, .715)):
        rod("Door shut line",(side*.922,y,bottom),(side*.924,y,.945),.005,v.DARK)
    box("Mirror mounting pad",(side*.873,-.78,1.141),(.047,.130,.108),v.RUBBER,.016)
    rod("Mirror support arm",(side*.885,-.78,1.125),(side*.952,-.77,1.154),
        .032,v.DARK)
    v.cylinder("Mirror folding joint",(side*.950,-.77,1.159),
               .039,.055,v.DARK,False,24,root)
    box("Rounded mirror housing",(side*.970,-.755,1.193),(.167,.146,.155),v.DARK,.042)
    box("Mirror glass gasket",(side*.970,-.679,1.193),(.140,.024,.127),v.RUBBER,.011)
    box("Mirror glass",(side*.970,-.665,1.193),(.117,.012,.104),v.METAL,.007)
    headlight("Upper headlight",side*.694,-1.385,1.087,.062)
    headlight("Lower headlight",side*.655,-2.043,.672,.079)
    lamp("Front amber indicator",side*.816,-1.987,.671,.052,amber)
    cluster = [(.706,.716),(.786,.727),(.840,.768),(.842,.828),
               (.802,.894),(.784,.983),(.743,1.006),(.699,.975),
               (.680,.910),(.675,.782)]
    v.profile_loft("Rounded rear lamp housing", [
        [(side*(.752+(x-.752)*scale),y,.86+(z-.86)*scale) for x,z in cluster]
        for y,scale in [(1.912,.91),(1.975,1.06),(1.998,1.0)]
    ],v.RUBBER,root)
    lamp("Tail lamp",side*.735,2.001,.937,.052,v.TAIL_LAMP)
    lamp("Rear indicator lens",side*.777,2.011,.835,.054,amber)
    lamp("Reversing lens",side*.733,2.009,.761,.032,reverse)
    for y in (-1.28,1.30):
        tire(side,y)
        v.cylinder("Wheel hub barrel",(side*.884,y,.318),.209,.045,v.DARK,True,40,root)
        v.cylinder("Wheel hub cap",(side*.913,y,.318),.077,.028,v.METAL,True,32,root)
        alloy_face(side, y)
        for i in range(4):
            angle = (i+.5)*math.tau/4
            bolt_y = y+.049*math.cos(angle)
            bolt_z = .318+.049*math.sin(angle)
            v.cylinder("Wheel bolt recess",(side*.927,bolt_y,bolt_z),
                       .016,.008,v.DARK,True,16,root)
            v.cylinder("Wheel lug nut",(side*.933,bolt_y,bolt_z),
                       .010,.010,v.METAL,True,6,root)
        valve_base = (side*.903,y+.190,.378)
        valve_end = (side*.930,y+.211,.383)
        rod("Tire valve stem",valve_base,valve_end,.008,v.DARK)
        rod("Tire valve cap",valve_end,(side*.938,y+.217,.385),.009,v.METAL)

# Follow the taper of the rear quarter panel above and behind the wheel.
fuel_door_angles = [step * math.tau / 48 for step in range(48)]
for name, finish, profile in [
    ("Fuel door perimeter", v.DARK, [(.896, .071), (.903, .071), (.905, .068)]),
    ("Painted fuel door", paint, [(.903, .065), (.908, .065), (.911, .060)]),
]:
    v.profile_loft(name, [
        [(depth - .053 * radius * math.cos(angle) - .22 * radius * math.sin(angle),
          1.53 + radius * math.cos(angle), .855 + radius * math.sin(angle))
         for angle in fuel_door_angles]
        for depth, radius in profile
    ], finish, root)

box("Front bumper", (0,-1.983,.418),(1.68,.225,.315),v.DARK,.071)
box("Rear bumper", (0,1.929,.433),(1.69,.211,.271),v.DARK,.074)
for side in (-1, 1):
    headlight("Bumper fog lamp", side * .656, -2.095, .366, .041)
    box("Front bumper corner rub strip", (side * .656, -2.093, .478),
        (.249, .027, .035), v.RUBBER, .014)
    box("Rear bumper corner rub strip", (side * .658, 2.035, .487),
        (.245, .027, .040), v.RUBBER, .016)
    reflector_angles = [step * math.tau / 32 for step in range(32)]
    v.profile_loft("Rear bumper reflector", [
        [(side * .729 + radius * math.cos(angle), depth, .394 + radius * math.sin(angle))
         for angle in reflector_angles]
        for depth, radius in [(2.029, .040), (2.038, .040), (2.043, .035)]
    ], reflector, root)
box("Rear bumper central rub strip", (0, 2.034, .408),
    (.965, .022, .035), v.RUBBER, .013)
box("Lower grille recess",(0,-2.100,.384),(.91,.031,.169),v.RUBBER,.013)
for x in (-.33, -.22, -.11, 0, .11, .22, .33):
    box("Lower grille upright", (x, -2.115, .384), (.015, .011, .134), v.DARK, .004)
for z in (.329, .373, .417, .449):
    box("Lower grille rail", (0, -2.124, z), (.833, .023, .015), v.DARK, .005)
box("Bonnet intake",(0,-2.039,.615),(.78,.028,.065),v.DARK,.012)
for y, sign in [(-2.116, -1), (2.049, 1)]:
    rotation = (math.pi / 2, 0, 0 if sign < 0 else math.pi)
    box("Registration plate holder", (0, y - sign * .007, .525),
        (.508, .023, .122), v.RUBBER, .009)
    box("Registration plate", (0, y, .525), (.488, .024, .108), cream, .007)
    box("Registration country band", (sign * .219, y + sign * .012, .525),
        (.043, .005, .101), v.POLICE_BLUE, .003)
    for label, lettering, x, z, size, finish in [
        ("Registration", "FA 608", .147, .497, .077, v.DARK),
        ("Country code", "S", .229, .492, .028, cream),
    ]:
        text = v.text_obj(label, lettering, (sign * x, y + sign * .016, z),
                          size, finish, root=root, flat=True)
        text.rotation_euler = rotation
    for x in (-.178, .198):
        fastener = v.cylinder("Registration plate fastener",
                              (-sign * x, y + sign * .013, .563),
                              .004, .003, v.METAL, False, 12, root)
        fastener.rotation_euler.x = math.pi / 2
badge = v.text_obj("Multum hatch badge","MULTUM",(.208,2.008,.842),.086,
                   v.METAL,root=root,flat=True)
badge.rotation_euler = (math.pi/2,0,math.pi)
box("Fait enamel badge",(0,-1.414,1.049),(.109,.025,.074),v.DARK,.011)
logo = v.text_obj("Fait badge lettering","FAIT",(-.041,-1.433,1.032),.034,
                  cream,root=root,flat=True)
logo.rotation_euler = (math.pi/2,0,0)
rod("Roof antenna",(0,.14,1.805),(0,.31,2.078),.009,v.DARK)
for x, length in [(-.625, .535), (.055, .540)]:
    spindle = v.cylinder("Windscreen wiper spindle", (x, -1.270, 1.156),
                         .022, .024, v.RUBBER, False, 24, root)
    spindle.rotation_euler.x = .62
    blade_start = (x + .045, -1.216, 1.193)
    blade_end = (x + length, -1.185, 1.227)
    blade_center = Vector(blade_start).lerp(Vector(blade_end), .47)
    rod("Windscreen wiper arm", (x, -1.283, 1.164), blade_center,
        .009, v.DARK)
    rod("Windscreen wiper blade rail", blade_start, blade_end, .010, v.DARK)
    rod("Windscreen wiper rubber edge",
        Vector(blade_start) + Vector((0, .010, -.007)),
        Vector(blade_end) + Vector((0, .010, -.007)), .007, v.RUBBER)
# The lower hatch panel ends at the bumper and is narrower than the rear glass.
for side in (-1, 1):
    rod("Hatch side seam", (side * .627, 1.993, .943),
        (side * .604, 1.993, .655), .004, v.DARK)
    rod("Hatch corner seam", (side * .604, 1.993, .655),
        (side * .564, 1.993, .620), .004, v.DARK)
rod("Hatch sill seam", (-.564, 1.993, .620), (.564, 1.993, .620), .004, v.DARK)
box("Hatch release recess", (0, 2.003, .722), (.237, .029, .054), v.RUBBER, .013)
box("Hatch release grip", (0, 2.020, .731), (.190, .015, .025), paint, .007)

pivot = v.cylinder("Rear wiper spindle", (.253, 1.881, 1.140),
                   .031, .029, v.RUBBER, False, 24, root)
pivot.rotation_euler.x = math.pi / 2
rod("Rear wiper arm", (.253, 1.903, 1.140), (-.041, 1.905, 1.235), .013, v.DARK)
rod("Rear wiper blade rail", (-.322, 1.899, 1.255), (.176, 1.899, 1.220), .012, v.DARK)
rod("Rear wiper rubber edge", (-.322, 1.885, 1.249), (.176, 1.885, 1.214), .009, v.RUBBER)
v.export_vehicle(root,"multum.glb")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR)/"Multum.blend"))
