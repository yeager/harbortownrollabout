"""Build the red and yellow flatbed recovery truck from a commercial truck cab."""
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, make_fire_engine, cube, cylinder, text_obj,
    DARK, METAL, PAINT_RED, PAINT_YELLOW, RED_LAMP, export_vehicle, SOURCE_DIR)
clear_scene()
root=make_fire_engine()
root.name="Sjöstad roadside recovery"
bpy.context.view_layer.update()
for part in list(root.children):
    if part.type!="MESH": continue
    center=part.matrix_world @ (sum((Vector(c) for c in part.bound_box),Vector())/8)
    if center.y<-.71 and not any(word in part.name.lower() for word in ("letter","identity","flash","light bar","scene light","crest","badge")):
        continue
    if center.z<.85 and .6<center.y<1.7:
        part.location.y+=.82
        continue
    bpy.data.objects.remove(part,do_unlink=True)
def box(name,xyz,size,finish,r=.025):
    return cube(name,xyz,size,finish,r,root)
box("Chassis",(0,.32,.72),(1.64,6.94,.34),DARK)
box("Flatbed",(0,1.59,1.14),(2.49,4.57,.16),PAINT_RED,.06)
box("Deck grip",(0,1.59,1.227),(2.35,4.44,.026),DARK)
for side in [-1,1]:
    box("Locker",(side*1.01,.15,.76),(.38,1.52,.66),PAINT_RED)
    box("Yellow livery",(side*1.208,.15,.83),(.03,1.5,.30),PAINT_YELLOW)
    box("Cab stripe",(side*1.109,-1.76,1.52),(.032,1.91,.20),PAINT_YELLOW)
    box("Headboard upright",(side*1.11,-.62,1.71),(.13,.17,1.06),PAINT_RED)
    for j in range(8):
        box("Lashing eye",(side*1.22,-.35+j*.54,1.245),(.048,.12,.035),METAL)
    box("Tail lamp",(side*.98,3.89,1.09),(.34,.09,.10),RED_LAMP)
    box("Amber marker",(side*.69,-1.63,2.73),(.41,.22,.15),PAINT_YELLOW,.055)
box("Headboard crossbeam",(0,-.62,2.18),(2.34,.16,.18),PAINT_RED)
cylinder("Winch drum",(0,-.46,1.49),.19,.70,METAL,True,32,root)
for i in range(12):
    cylinder("Wound cable",(i*.048-.27,-.46,1.49),.20,.025,DARK,True,24,root)
box("Wheel lift",(0,3.68,.58),(.32,1.05,.18),DARK)
box("Wheel lift crossbar",(0,4.08,.51),(1.71,.17,.15),METAL)
for side in [-1, 1]:
    # Folded tyre cradle and its pinned hinge at either end of the rear yoke.
    box("Cradle pivot bracket", (side*.72,4.06,.53), (.21,.27,.22), DARK)
    cylinder("Cradle hinge pin", (side*.72,4.09,.53), .075,.25,METAL,True,24,root)
    box("Wheel cradle arm", (side*.72,4.30,.48), (.12,.52,.10), DARK)
    box("Tyre retaining toe", (side*.57,4.52,.50), (.40,.10,.13), METAL)
    for j in range(4):
        box("Locker reflector", (side*1.229,-.40+j*.34,.66), (.012,.18,.065), PAINT_YELLOW,.008)
export_vehicle(root,"bargare.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"Bargare.blend"))
