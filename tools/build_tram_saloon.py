"""Stockholm-inspired articulated tram saloon. Blender +Y faces the leading cab."""
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene, cube, cylinder, export_vehicle, material, SOURCE_DIR

clear_scene()
root = bpy.data.objects.new("Low-floor tram saloon", None)
bpy.context.collection.objects.link(root)
blue = material("Baltic blue enamel", (.015,.24,.49), .30,.28)
silver = material("Pearl grey enamel", (.63,.69,.72), .38,.31)
steel = material("Cast steel", (.115,.15,.16), .55,.43)
black = material("Rubber and underfloor panels", (.024,.032,.033), .12,.46)
frame = material("Window frit", (.010,.018,.022), .16,.25)
glass = material("Cool saloon glazing", (.072,.19,.23), .24,.16)
glass_bsdf = next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
glass_bsdf.inputs["Alpha"].default_value = .54
glass.diffuse_color = (.072,.19,.23,.54)
seat = material("Woven blue seats", (.043,.17,.26), .03,.79)
yellow = material("Grab rails", (.92,.58,.08), .25,.35)

def section(name, start, end, levels, mat):
    # Each height has its own width. Aligning seams keeps the flanks flush.
    verts = []
    for y in (start,end):
        for x,z in levels:
            verts.append((x,y,z))
    count = len(levels)
    faces = [tuple(range(count)), tuple(reversed(range(count,2*count)))]
    faces.extend((i,count+i,count+(i+1)%count,(i+1)%count) for i in range(count))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = root

def band(name, start, end, bottom, top, bottom_width, top_width, mat):
    section(name,start,end,[(-bottom_width,bottom),(bottom_width,bottom),(top_width,top),(-top_width,top)],mat)

# The middle gap is the real sliding doorway. The floor continues through it.
cube("Vestibule floor", (0,0,.43), (2.33,4.42,.12), black,.03,root)
band("Shoulder fascia", -2.20,2.20,2.27,2.55,1.18,1.13,silver)
band("Rounded roof shoulders", -2.20,2.20,2.55,2.67,1.13,.98,silver)
for start,end in [(-2.20,-.65),(.39,2.20)]:
    band("Inset skirt",start,end,.28,.48,1.08,1.17,black)
    band("Blue waist stripe",start,end,.48,.65,1.17,1.20,blue)
    band("Painted side panel",start,end,.65,1.19,1.20,1.18,silver)
    mid = (start+end)*.5
    for side in [-1,1]:
        for post in (start+.036,mid,end-.036):
            cube("Glazing pillar",(side*1.155,post,1.73),(.07,.073,1.09),frame,.012,root)
        for a,b in [(start,mid),(mid,end)]:
            cube("Passenger window",(side*1.16,(a+b)*.5,1.73),(.031,b-a-.05,1.01),glass,.014,root)
        for z in (1.205,2.245):
            cube("Bonded window seal",(side*1.158,mid,z),(.07,end-start,.065),frame,.013,root)
        cube("Seat cushion",(side*.69,mid,.91),(.53,.48,.12),seat,.05,root)
        cube("Seat back",(side*.69,mid-.22,1.15),(.53,.11,.56),seat,.05,root)
        cylinder("Vestibule grab pole",(side*.89,mid,1.64),.024,1.20,yellow,False,12,root)

cube("Bogie frame",(0,0,.32),(1.67,2.45,.26),black,.065,root)
for y in (-.91,.91):
    for side in [-1,1]:
        cylinder("Steel wheel",(side*.72,y,.29),.27,.13,steel,True,24,root)
        cylinder("Axle bearing",(side*.86,y,.29),.13,.12,black,True,16,root)
cube("Roof equipment housing",(0,1.28,2.72),(1.37,1.14,.18),steel,.065,root)
for y in (.89,1.04,1.19,1.34,1.49,1.64):
    cube("Roof louvre",(0,y,2.815),(1.05,.049,.024),black,.008,root)
# Batch opaque geometry by material to keep the three-car consist inexpensive.
for mat in (blue,silver,steel,black,frame,seat,yellow):
    bpy.ops.object.select_all(action="DESELECT")
    objects = [obj for obj in root.children if obj.type == "MESH" and obj.data.materials[0] == mat]
    for obj in objects:
        obj.select_set(True)
    if objects:
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
export_vehicle(root,"tram_saloon.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"TramSaloon.blend"))
