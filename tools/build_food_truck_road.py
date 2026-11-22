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
road_red = bpy.data.materials["Cherry lacquer"]
for part in list(root.children):
    if part.name.startswith(("Raised red hatch","Hatch end trim","Hatch drip edge","Gas spring",
                             "Chrome piston","Upper strut bracket","Strut bracket","Service sill")):
        bpy.data.objects.remove(part,do_unlink=True)
box("Latched service shutter",(1.20,1.19,2.02),(.055,3.94,1.59),road_red,.025)
for y in [-.64,3.02]:
    box("Recessed shutter catch",(1.233,y,1.30),(.016,.115,.055),v.DARK,.008)
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
v.export_vehicle(root,"food_truck_road.glb")

