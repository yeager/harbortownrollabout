"""Model the white, pickup-converted Swedish A-traktor in the reference."""
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, cube, cylinder, material, mesh_from_rings,
                            export_vehicle, profile_loft, SOURCE_DIR, PAINT_WHITE, GLASS, DARK,
                            RUBBER, METAL, HEADLAMP, RED_LAMP)

clear_scene()
root=bpy.data.objects.new("White A-traktor",None)
bpy.context.collection.objects.link(root)
def box(name,loc,size,finish,bevel=.025):
    return cube(name,loc,size,finish,bevel,root)
def wheel_part(name,x,y,r,d,finish):
    return cylinder(name,(x,y,.322),r,d,finish,True,32,root)

shell=mesh_from_rings("Pressed steel body",[
    (-2.32,.78,.33,.80,.85),(-2.19,.86,.31,.84,.91),(-1.67,.89,.29,.89,.95),
    (-.85,.89,.29,.91,.98),(.65,.89,.29,.92,.97),(2.18,.86,.34,.91,.95)],
    PAINT_WHITE,root,.025)
for y in [-1.45,1.39]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.354,depth=2.4,
        location=(0,y,.322),rotation=(0,math.pi/2,0))
    cutter=bpy.context.object
    cut=shell.modifiers.new("Wheel well","BOOLEAN")
    cut.object=cutter
    cut.operation="DIFFERENCE"
    bpy.context.view_layer.objects.active=shell
    bpy.ops.object.modifier_apply(modifier=cut.name)
    bpy.data.objects.remove(cutter,do_unlink=True)
    for side in [-1,1]:
        wheel_part("Däck",side*.80,y,.322,.18,RUBBER)
        wheel_part("Alloy wheel",side*.89,y,.238,.021,METAL)
        wheel_part("Wheel hub recess",side*.903,y,.213,.019,DARK)
        for spoke in range(10):
            angle=spoke*math.tau/10
            bar=box("Alloy wheel spoke",(side*.917,y+.11*math.sin(angle),.322+.11*math.cos(angle)),
                    (.018,.031,.215),METAL,.008)
            bar.rotation_euler.x=-angle
def panel(name, vertices, finish):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], [tuple(range(len(vertices)))])
    mesh.materials.append(finish)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = root
    return obj

def rod(name, a, b, radius, finish):
    a, b = Vector(a), Vector(b)
    obj = cylinder(name, (a+b)/2, radius, (b-a).length, finish, False, 12, root)
    obj.rotation_euler = (b-a).to_track_quat("Z","Y").to_euler()
    return obj

# Glazing sits inside a continuous painted roof perimeter and pressed pillars.
glass = material("Neutral smoked laminated glass", (.062,.11,.135), .46, .17)
cab=mesh_from_rings("Painted cab", [(-1.01,.82,.92,.97,1.0),
    (-.44,.715,.92,1.56,1.62),(.49,.715,.92,1.56,1.61),(.86,.78,.92,1.39,1.47)],
    PAINT_WHITE,root,.026,
    section=lambda y,w,b,h,t: [(-w-.042,y,b),(-w,y,h),(-w*.85,y,t),(w*.85,y,t),(w,y,h),(w+.042,y,b)])
panel("Raked wraparound windscreen", [(-.795,-1.025,1.038),(.795,-1.025,1.038),
    (.674,-.548,1.565),(-.674,-.548,1.565)], glass)
panel("Cab backlight", [(-.65,.866,1.062),(.65,.866,1.062),(.65,.866,1.374),(-.65,.866,1.374)],glass)
for side in (-1,1):
    panel("Driver side glass",[(side*x,y,z) for x,y,z in
        ((.839,-.889,1.015),(.725,-.400,1.536),(.725,.312,1.536),(.757,.315,1.015))],glass)
    panel("Rear quarter glass",[(side*x,y,z) for x,y,z in
        ((.758,.376,1.015),(.725,.375,1.526),(.745,.529,1.515),(.794,.766,1.392),(.819,.766,1.015))],glass)
    rod("Wiper blade",(side*.13,-.985,1.089),(side*.57,-.975,1.104),.009,RUBBER)
    rod("Door sill brightwork",(side*.884,-.88,.407),(side*.884,.51,.407),.015,METAL)
    box("Door pull escutcheon",(side*.876,.235,.855),(.034,.187,.052),RUBBER,.012)
    for axle_y in (-1.45,1.39):
        wheel_part("Center cap",side*.93,axle_y,.054,.024,METAL)
amber = material("A-tractor amber optic",(.92,.33,.032),.08,.28)
for side in [-1,1]:
    box("Door handle",(side*.886,.25,.92),(.052,.15,.031),DARK)
    box("Bodyside moulding",(side*.889,-.10,.55),(.032,1.85,.055),RUBBER)
    box("Mirror",(side*.94,-.75,1.045),(.16,.14,.15),DARK)
    box("Cargo rail",(side*.79,1.55,.99),(.13,1.23,.14),PAINT_WHITE)
    box("Tail light gasket",(side*.78,2.186,.70),(.156,.033,.348),RUBBER,.014)
    box("Tail light housing",(side*.78,2.207,.70),(.144,.026,.336),DARK,.011)
    for label,z,height,finish in (
        ("Rear lamp brake lens",.802,.114,RED_LAMP),
        ("Reversing lens",.706,.058,PAINT_WHITE),
        ("Rear indicator lens",.638,.068,amber),
        ("Rear lamp lower lens",.566,.056,RED_LAMP),
    ):
        box(label,(side*.78,2.225,z),(.126,.020,height),finish,.008)
    box("Headlight",(side*.58,-2.323,.72),(.31,.054,.17),HEADLAMP)
# Cut an actual recessed bed within the rear quarters.
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,1.515,1.127))
cutter=bpy.context.object
cutter.dimensions=(1.43,1.12,.83)
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
cut=shell.modifiers.new("Recessed pickup bed","BOOLEAN")
cut.object=cutter
cut.operation="DIFFERENCE"
bpy.context.view_layer.objects.active=shell
bpy.ops.object.modifier_apply(modifier=cut.name)
bpy.data.objects.remove(cutter,do_unlink=True)
box("Load bed liner",(0,1.515,.724),(1.43,1.12,.030),DARK)
for side in (-1,1):
    box("Inner bed liner",(side*.712,1.515,.845),(.022,1.12,.214),DARK,.009)
    box("Wheel housing in bed",(side*.686,1.39,.770),(.14,.55,.093),RUBBER,.040)
    box("Front indicator gasket",(side*.767,-2.327,.71),(.111,.035,.167),RUBBER,.012)
    box("Front indicator housing",(side*.767,-2.347,.71),(.098,.023,.151),DARK,.010)
    box("Front amber indicator",(side*.767,-2.364,.71),(.085,.020,.137),amber,.010)
    box("Bumper bright strip",(side*.54,-2.374,.465),(.63,.017,.024),METAL,.004)
    box("Tailgate hinge",(side*.47,2.195,.631),(.112,.027,.040),METAL,.006)
box("Tailgate recessed pull",(0,2.197,.874),(.178,.021,.046),DARK,.010)
box("Rear registration",(0,2.199,.73),(.43,.021,.10),PAINT_WHITE,.008)
rod("Rolled exhaust pipe",(-.65,1.91,.331),(-.65,2.28,.285),.047,METAL)
rod("Exhaust bore",(-.65,2.277,.285),(-.65,2.286,.284),.035,RUBBER)
for i in range(-5,6): box("Bed rib",(i*.117,1.515,.747),(.034,1.085,.019),RUBBER,.008)
for y in [-2.30,2.20]: box("Black bumper",(0,y,.43),(1.77,.16,.16),RUBBER)
box("Radiator grille",(0,-2.33,.73),(.73,.055,.21),DARK)
for i in range(-6,7):box("Grille rib",(i*.052,-2.36,.73),(.016,.015,.185),METAL,.004)
# Stand the sign off the cab glass on two rubber-backed brackets.
for x in (-.34,-.12):
    box("LGF rubber mounting pad",(x,.882,1.13),(.043,.038,.066),RUBBER,.007)
    box("LGF mounting bracket",(x,.910,1.13),(.026,.054,.043),METAL,.004)

triangle_outline = [(0,.22),(.22,-.15),(-.22,-.15)]
def triangle_sections(sections):
    return [[(-.23+x*scale,y,1.23+z*scale) for x,z in triangle_outline]
            for y,scale in sections]

profile_loft("LGF sign backing",triangle_sections([(.930,.975),(.938,1.012),(.947,1.012)]),DARK,root)
reflector = material("LGF red reflector",(.64,.012,.008),.12,.29)
profile_loft("LGF reflector border",triangle_sections([(.947,1),(.953,.987),(.955,.963)]),reflector,root)
fluorescent = material("LGF orange", (1,.15,.012),0,.42)
profile_loft("Fluorescent centre",triangle_sections([(.955,.74),(.958,.735)]),fluorescent,root)
export_vehicle(root,"a_traktor.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"A-traktor.blend"))
