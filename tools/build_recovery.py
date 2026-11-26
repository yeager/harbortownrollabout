"""Build the red and yellow flatbed recovery truck from a commercial truck cab."""
from math import pi
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, make_fire_engine, cube, cylinder, text_obj,
    DARK, METAL, PAINT_RED, PAINT_YELLOW, RED_LAMP, export_vehicle, SOURCE_DIR)


def add_lashing_eye(root, x, y):
    cube("Lashing eye base",(x,y,1.232),(.082,.162,.028),DARK,.008,root)
    for end in (-.065,.065):
        cylinder("Lashing base bolt",(x,y+end,1.249),.009,.010,METAL,False,6,root)
    for end in (-.044,.044):
        cube("Lashing eye support",(x,y+end,1.256),(.025,.019,.024),METAL,.004,root)
    bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=8,
                                     major_radius=.038,minor_radius=.007,
                                     location=(x,y,1.269))
    eye=bpy.context.object
    eye.name="Lashing eye"
    for vertex in eye.data.vertices:
        vertex.co.x *= .70
        vertex.co.y *= 1.20
    for face in eye.data.polygons:
        face.use_smooth=True
    eye.data.materials.append(METAL)
    eye.parent=root


def add_tail_lamp_housing(root, side):
    x = side*.98
    cube("Rear lamp housing",(x,3.88,1.09),(.415,.107,.156),DARK,.017,root)
    cube("Rear lamp carrier",(x,3.825,1.09),(.375,.060,.177),PAINT_RED,.011,root)
    cube("Tail lamp",(x-side*.059,3.931,1.09),(.200,.030,.100),RED_LAMP,.010,root)
    cube("Rear indicator lens",(x+side*.110,3.931,1.09),(.112,.030,.100),
         PAINT_YELLOW,.010,root)
    for offset in (-.187,.187):
        screw = cylinder("Rear lamp housing screw",(x+offset,3.938,1.09),
                         .009,.010,METAL,False,12,root)
        screw.rotation_euler.x = pi/2


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
        add_lashing_eye(root,side*1.20,-.35+j*.54)
    add_tail_lamp_housing(root,side)
    box("Amber marker",(side*.69,-1.63,2.73),(.41,.22,.15),PAINT_YELLOW,.055)
box("Headboard crossbeam",(0,-.62,2.18),(2.34,.16,.18),PAINT_RED)
cylinder("Winch drum",(0,-.46,1.49),.19,.70,METAL,True,32,root)
for i in range(12):
    cylinder("Wound cable",(i*.048-.27,-.46,1.49),.20,.025,DARK,True,24,root)
for side in (-1,1):
    x = side*.393
    box("Winch pedestal foot",(x,-.46,1.262),(.236,.34,.054),PAINT_RED)
    box("Winch bearing pedestal",(x,-.46,1.393),(.094,.26,.24),PAINT_RED)
    cylinder("Winch bearing cap",(side*.449,-.46,1.49),.093,.043,METAL,True,24,root)
    cylinder("Winch axle end",(side*.477,-.46,1.49),.044,.024,DARK,True,16,root)
    for y in (-.575,-.345):
        cylinder("Winch foot bolt",(side*.465,y,1.299),.019,.019,METAL,False,6,root)
box("Cable guide saddle",(0,-.205,1.289),(.324,.15,.095),PAINT_RED)
for z in (1.335,1.429):
    cylinder("Cable guide roller",(0,-.185,z),.026,.25,METAL,True,24,root)
for x in (-.143,.143):
    box("Cable guide cheek",(x,-.185,1.384),(.038,.092,.145),DARK)
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
