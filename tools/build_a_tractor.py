"""Model the white, pickup-converted Swedish A-traktor in the reference."""
import math
import sys
from pathlib import Path
import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, cube, cylinder, material, mesh_from_rings,
                            export_vehicle, SOURCE_DIR, PAINT_WHITE, GLASS, DARK,
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
cab=mesh_from_rings("Glazed cab",[(-1.01,.82,.92,.96,1.00),(-.45,.75,.93,1.49,1.58),
    (.64,.75,.93,1.49,1.58),(.92,.80,.93,1.38,1.48)],GLASS,root,.02)
box("Enamel roof",(.0,.09,1.565),(1.45,1.17,.084),PAINT_WHITE,.052)
for side in [-1,1]:
    box("Door window pillar",(side*.754,.52,1.25),(.058,.19,.57),PAINT_WHITE)
    box("Door handle",(side*.886,.25,.92),(.052,.15,.031),DARK)
    box("Bodyside moulding",(side*.889,-.10,.55),(.032,1.85,.055),RUBBER)
    box("Mirror",(side*.94,-.75,1.045),(.16,.14,.15),DARK)
    box("Cargo rail",(side*.79,1.55,.99),(.13,1.23,.14),PAINT_WHITE)
    box("Rear lamp",(side*.78,2.182,.70),(.135,.047,.34),RED_LAMP)
    box("Reversing lens",(side*.78,2.208,.70),(.131,.012,.087),PAINT_WHITE)
    box("Headlight",(side*.58,-2.323,.72),(.31,.054,.17),HEADLAMP)
box("Load bed liner",(0,1.55,.97),(1.46,1.21,.045),DARK)
for i in range(-5,6): box("Bed rib",(i*.117,1.55,1.004),(.034,1.15,.025),RUBBER,.008)
for y in [-2.30,2.20]: box("Black bumper",(0,y,.43),(1.77,.16,.16),RUBBER)
box("Radiator grille",(0,-2.33,.73),(.73,.055,.21),DARK)
for i in range(-6,7):box("Grille rib",(i*.052,-2.36,.73),(.016,.015,.185),METAL,.004)
def triangle(name,y,scale,finish):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata([(x*scale-.23,y,1.23+z*scale) for x,z in [(0,.22),(.22,-.15),(-.22,-.15)]],[],[(0,1,2)])
    mesh.materials.append(finish)
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent=root
triangle("LGF reflector border",.933,1,RED_LAMP)
triangle("Fluorescent centre",.935,.76,material("LGF orange",(1,.12,.012),0,.36))
export_vehicle(root,"a_traktor.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"A-traktor.blend"))
