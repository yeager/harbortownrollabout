"""Build the blue tram cab with a raked, wraparound windscreen."""
import math
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene, material, cube, export_vehicle, SOURCE_DIR

clear_scene()
root = bpy.data.objects.new("Tram cab", None)
bpy.context.collection.objects.link(root)
blue = material("Transit blue enamel", (.014,.25,.51), .32,.26)
glass = material("Cab safety glass", (.026,.067,.083), .42,.16)
seal = material("Screen surround", (.014,.021,.026), .18,.3)
silver = material("Roof fairing", (.66,.71,.74), .42,.3)
lamp = material("Dipped headlight", (.91,.86,.68), .1,.2,1.25)
# Horizontal sections narrow towards the brow and curve around both corners.
rings = [(.34,1.12,2.65),(.48,1.18,2.74),(.99,1.18,2.77),
         (1.09,1.16,2.74),(1.20,1.15,2.72),(2.22,1.09,2.46),
         (2.44,1.08,2.42),(2.6,1.10,2.39),(2.68,1.06,2.35)]
verts, faces, slots = [], [], []
for level,(z,width,tip) in enumerate(rings):
    row = len(verts)
    for j in range(25):
        a = math.pi*j/24
        verts.append((width*math.cos(a),2.29+(tip-2.29)*math.sin(a),z))
        if level and j:
            faces.append((row+j-26,row+j-25,row+j,row+j-1))
            slots.append(0 if level<=3 or j<3 or j>22 else 2 if level in (4,6) else 1 if level==5 else 3)
mesh = bpy.data.meshes.new("Cab fascia sections")
mesh.from_pydata(verts, [], faces)
mesh.update()
obj = bpy.data.objects.new("Formed cab shell",mesh)
bpy.context.collection.objects.link(obj)
obj.parent=root
for mat in [blue,glass,seal,silver]: mesh.materials.append(mat)
for face,slot in zip(mesh.polygons,slots):
    face.material_index=slot
    face.use_smooth=True
for side in [-1,1]:
    cube("Lamp bezel",(side*.78,2.63,1.04),(.28,.09,.14),seal,.045,root)
    cube("Headlight lens",(side*.78,2.69,1.04),(.19,.055,.072),lamp,.026,root)
cube("Destination display",(0,2.48,2.32),(1.40,.08,.21),seal,.04,root)
export_vehicle(root,"tram_cab.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"TramCab.blend"))
