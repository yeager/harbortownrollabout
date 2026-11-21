"""Build just the Volvo XC60 Swedish police patrol model."""
import os, sys
import bpy
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_vehicles import clear_scene, make_volvo_xc60_police, export_vehicle, SOURCE_DIR
clear_scene()
vehicle = make_volvo_xc60_police()
export_vehicle(vehicle, "volvo_xc60_polis.glb")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE_DIR, "volvo_xc60_polis.blend"))
print("Built Volvo XC60 Swedish police model")
