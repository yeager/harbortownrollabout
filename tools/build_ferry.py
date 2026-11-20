"""Build the twin-ended Lotten passenger ferry for the Sjöstad canal."""
import os
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, cube, cylinder, mesh_from_rings, material,
                            text_obj, export_vehicle, SOURCE_DIR)

clear_scene()
root = bpy.data.objects.new("Lotten", None)
bpy.context.collection.objects.link(root)
white = material("Painted aluminium", (.89,.91,.87), .24,.32)
navy = material("Ship lettering", (.012,.045,.13))
deck = material("Non-slip deck", (.19,.22,.21))
glass = material("Wheelhouse glazing", (.13,.29,.33), .45,.16)
rubber = material("Fender rubber", (.027,.031,.035))
orange = material("Rescue orange", (.97,.16,.035))
steel = material("Galvanised fittings", (.49,.54,.56), .8,.27)

def box(name, point, size, finish, bevel=.025):
    return cube(name, point, size, finish, bevel, root)

def pole(name, point, radius, length, finish):
    return cylinder(name, point, radius, length, finish, False, 12, root)

stations = [(-6.4,1.18),(-5.8,1.68),(-4.7,1.94),(0,2),(4.7,1.94),(5.8,1.68),(6.4,1.18)]
def section(y,w,b,s,c):
    return [(-w*.65,y,b),(-w*.9,y,b+.18),(-w,y,s),(-w,y,c),
            (w,y,c),(w,y,s),(w*.9,y,b+.18),(w*.65,y,b)]
mesh_from_rings("Chined displacement hull", [(y,w,-.47,.24,.65) for y,w in stations],
                white,root,.045,section)
box("Main saloon", (0,0,1.05),(3.77,8.55,1.03),white,.12)
box("Continuous tinted glazing",(0,0,1.87),(3.72,8.39,.78),glass,.09)
box("Shelter roof",(0,0,2.31),(3.97,8.82,.14),navy,.065)
for side in [-1,1]:
    for i in range(11):
        box("Saloon mullion",(side*1.865,-4.10+.82*i,1.86),(.065,.073,.81),white,.01)
    text_obj("Vessel name","LOTTEN",(side*1.895,-side*.93,.89),.48,navy,-side,root)
    for end in [-1,1]:
        for i in range(6):
            y=end*(4.32+i*.36)
            x=side*(1.85-i*.11)
            pole("Guardrail stanchion",(x,y,.94),.023,.6,white)
        rail=box("Top rail",(side*1.575,end*5.22,1.24),(.046,1.93,.05),white)
        rail.rotation_euler.z=side*end*.296
    box("Rub rail",(side*1.975,0,.45),(.075,9.4,.11),rubber)
box("Upper wheelhouse sill",(0,-.4,2.57),(2.06,2.06,.40),white,.09)
box("Pilot glass",(0,-.4,3.06),(2.02,2.02,.68),glass,.09)
for x in [-.98,0,.98]:
    for y in [-1.39,.59]:
        box("Pilot window frame",(x,y,3.06),(.066,.066,.73),white)
box("White wheelhouse roof",(0,-.4,3.48),(2.28,2.22,.13),white,.06)
for side in [-1,1]:
    for y in [1.32,2.57]:
        box("Life raft capsule",(side*1.12,y,2.57),(.70,1.17,.36),orange,.14)
        for offset in [-.34,.34]:
            box("Raft strap",(side*1.12,y+offset,2.58),(.71,.045,.37),rubber)
pole("Signal mast",(0,-.8,3.94),.046,1.0,steel)
box("Radar scanner",(0,-.8,4.43),(.8,.12,.1),white)
pole("Ensign staff",(0,3.32,3.14),.032,1.62,steel)
box("Swedish ensign",(0,3.64,3.68),(.022,.62,.37),navy)
gold=material("Flag gold",(.96,.69,.04))
box("Flag cross bar",(0,3.64,3.68),(.025,.62,.076),gold)
box("Flag cross upright",(0,3.53,3.68),(.026,.078,.37),gold)
export_vehicle(root,"lotten.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE_DIR,"Lotten.blend"))
