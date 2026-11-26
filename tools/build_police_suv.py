"""Build the editable Volvo patrol SUV and its game-ready batches."""
from pathlib import Path
import sys

import bpy

sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene, export_vehicle, make_police_suv, SOURCE_DIR

clear_scene()
vehicle=make_police_suv()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"police_suv.blend"),compress=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in vehicle.children:
    obj.select_set(True)
bpy.context.view_layer.objects.active=vehicle.children[0]
bpy.ops.object.convert(target="MESH")
groups={}
for obj in vehicle.children:
    if obj.type!="MESH":
        continue
    if obj.name.startswith(("FlashBlue","FlashRed","Centre brake lamp")):
        continue
    # The canopy uses white paint and glass; Blender preserves its material slots on join.
    key=obj.get("xc_batch",obj.data.materials[0].name)
    groups.setdefault(key,[]).append(obj)
for name,parts in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    if len(parts)>1:
        bpy.ops.object.join()
    parts[0].name=name
export_vehicle(vehicle,"police_suv.glb")
