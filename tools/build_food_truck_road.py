"""Export the travelling version of the food truck from its Blender source."""
from pathlib import Path
import sys
import bpy
from mathutils import Vector
project = Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(project / "source_blender/FoodTruck.blend"))
sys.path.insert(0,str(project / "tools"))
import build_vehicles as v

def box(name,pos,dims,mat,bevel):
    return v.cube(name,pos,dims,mat,bevel,root)

root = bpy.data.objects["Kajens burgare"]
shutter_finish = bpy.data.materials["Charcoal enamel"]
for part in list(root.children):
    if part.name.startswith(("Raised red hatch","Hatch exterior skin","Hatch end trim","Hatch drip edge","Gas spring",
                             "Chrome piston","Upper strut mounting plate","Lower strut mounting plate","Strut ",
                             "Hatch hinge","Fixed hatch hinge","Raised hatch hinge","Service sill",
                             "Drink can","Rolled can lid","Can pull tab","Can label stripe",
                             "Counter award","Hatch spotlight","Takeaway carton","Squeeze bottle","Tapered sauce spout")):
        bpy.data.objects.remove(part,do_unlink=True)
box("Latched service shutter",(1.20,1.19,2.02),(.055,3.94,1.59),shutter_finish,.025)
for z in (1.24, 2.80):
    box("Shutter edge rail",(1.229,1.19,z),(.019,3.94,.035),v.METAL,.006)
for y in (-.76,3.14):
    box("Shutter end rail",(1.229,y,2.02),(.019,.035,1.53),v.METAL,.006)
# Three flat silhouettes form the burger printed on the closed hatch.
bun = [(0,-.02),(.03,.10),(.10,.21),(.23,.29),(.40,.32),
       (.57,.29),(.70,.21),(.77,.10),(.80,-.02)]
filling = [(0,-.12),(.11,-.08),(.21,-.13),(.34,-.08),(.50,-.14),
           (.63,-.09),(.80,-.12),(.78,-.19),(.02,-.19)]
base = [(.02,-.23),(.78,-.23),(.73,-.31),(.64,-.34),(.16,-.34),(.07,-.31)]
for name, outline in [("Crown",bun),("Filling",filling),("Heel",base)]:
    mesh = bpy.data.meshes.new("Burger print " + name)
    mesh.from_pydata([(1.229,.79+y,2.11+z) for y,z in outline], [],
                     [list(reversed(range(len(outline))))])
    decal = bpy.data.objects.new(mesh.name,mesh)
    bpy.context.collection.objects.link(decal)
    decal.parent = root
    mesh.materials.append(v.PAINT_WHITE)
# A single warm-white print spans the hatch, with the burger as its centrepiece.
for word, start_y in [("KAJENS", -.59), ("BURGARE", 1.72)]:
    bpy.ops.object.select_all(action="DESELECT")
    v.text_obj("Shutter lettering " + word, word, (1.232,start_y,1.96),
               .29,v.PAINT_WHITE,side=-1,root=root,flat=True)
for z in (1.69,2.37):
    for y in (.00,2.38):
        box("Printed pinstripe",(1.231,y,z),(.002,1.04,.012),v.PAINT_WHITE,0)
for y in [-.64,3.02]:
    box("Shutter latch backing plate",(1.233,y,1.30),(.016,.172,.086),v.METAL,.009)
    box("Recessed shutter catch",(1.242,y-.015,1.30),(.010,.093,.048),v.DARK,.008)
    box("Catch lever",(1.252,y-.015,1.30),(.015,.066,.017),v.METAL,.004)
    lock = v.cylinder("Shutter lock cylinder",(1.25,y+.053,1.30),.016,.014,
                      v.METAL,False,16,root)
    lock.rotation_euler.y = 1.5707963
    box("Shutter lock keyway",(1.258,y+.053,1.30),(.002,.005,.016),v.DARK,.001)
for y in (-.43,.38,1.19,2.0,2.81):
    box("Shutter hinge leaf",(1.234,y,2.771),(.012,.14,.043),v.METAL,.004)
    barrel = v.cylinder("Shutter hinge barrel",(1.25,y,2.803),.018,.15,v.METAL,False,16,root)
    barrel.rotation_euler.x = 1.5707963
wheel_parts = [part for part in root.children if part.name.startswith(
    ("Tyre","Pressed steel rim","Hub cap","Rim vent","Hex wheel bolt"))]
bpy.context.view_layer.update()
for tyre in [part for part in wheel_parts if part.name.startswith("Tyre")]:
    bpy.ops.object.select_all(action="DESELECT")
    for part in wheel_parts:
        centre = part.matrix_world @ (sum((Vector(p) for p in part.bound_box),Vector())/8)
        if (centre-tyre.location).length < .46:
            part.select_set(True)
    wheel_parts = [part for part in wheel_parts if not part.select_get()]
    bpy.context.view_layer.objects.active = tyre
    bpy.ops.object.join()
    tyre.name = "All terrain tire"
# Keep the rotating wheel assembly separate from the fixed steering column.
pivot = bpy.data.objects.new("SteeringPivot", None)
bpy.context.collection.objects.link(pivot)
pivot.parent = root
pivot.location = bpy.data.objects["Steering rim"].location
bpy.context.view_layer.update()
for part in list(root.children):
    if part.name.startswith(("Steering rim", "Steering spoke", "Horn pad")):
        world = part.matrix_world.copy()
        part.parent = pivot
        part.matrix_world = world
reverse_glass = v.material("Reverse lamp clear lens",(.80,.86,.89),.12,.2)
for side in (-1,1):
    housing_x = side*.91
    box("Backlight bezel",(housing_x-side*.17,3.185,.94),(.12,.068,.12),v.DARK,.014)
    box("Reversing lens",(housing_x-side*.17,3.225,.94),(.093,.024,.09),reverse_glass,.012)
v.export_vehicle(root,"food_truck_road.glb")

