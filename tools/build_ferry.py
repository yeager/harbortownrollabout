"""Build the twin-ended Lotten passenger ferry for the Sjöstad canal."""
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector

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
saloon_glass = material("Light sea-green saloon glass", (.57,.74,.72), .12,.15)
next(node for node in saloon_glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .32
seat = material("Blue-grey upholstered seating", (.13,.24,.28), .04,.76)
rubber = material("Fender rubber", (.027,.031,.035))
orange = material("Rescue orange", (.97,.16,.035))
steel = material("Galvanised fittings", (.49,.54,.56), .8,.27)

def box(name, point, size, finish, bevel=.025):
    return cube(name, point, size, finish, bevel, root)

def pole(name, point, radius, length, finish):
    return cylinder(name, point, radius, length, finish, False, 12, root)

def tube(name, a, b, radius, finish):
    a, b = Vector(a), Vector(b)
    rod = pole(name, (a+b)*.5, radius, (b-a).length, finish)
    rod.rotation_euler = (b-a).to_track_quat("Z","Y").to_euler()
    return rod

# The shuttle has two broad landing ends, a shallow keel, and a raised sheer.
stations = [(-6.4,1.18,.12,.65),(-6.05,1.52,-.13,.67),(-5.5,1.78,-.35,.69),
            (-4.65,1.94,-.46,.66),(-2.7,2,-.50,.65),(0,2,-.50,.65),
            (2.7,2,-.50,.65),(4.65,1.94,-.46,.66),(5.5,1.78,-.35,.69),
            (6.05,1.52,-.13,.67),(6.4,1.18,.12,.65)]
def section(y,w,b,s,c):
    return [(-w*.60,y,b),(-w*.89,y,b+(c-b)*.22),(-w,y,s),(-w,y,c),
            (w,y,c),(w,y,s),(w*.89,y,b+(c-b)*.22),(w*.60,y,b)]
mesh_from_rings("Chined displacement hull", [(y,w,b,.39,c) for y,w,b,c in stations],
                white,root,.035,section)
box("Main saloon", (0,0,1.05),(3.77,8.55,1.03),white,.075)
box("Continuous tinted glazing",(0,0,1.87),(3.72,8.39,.78),saloon_glass,.045)
for row in range(7):
    for side in [-1,1]:
        box("Window seat back",(side*1.26,-3.14+row*.99,1.67),(.80,.13,.49),seat,.05)
        box("Headrest",(side*1.26,-3.14+row*.99,1.90),(.66,.16,.13),seat,.045)
box("Saloon window header",(0,0,2.25),(3.81,8.61,.09),white)
box("Shelter roof",(0,0,2.33),(3.97,8.82,.11),navy,.04)
for side in [-1,1]:
    for i in range(11):
        box("Saloon mullion",(side*1.865,-4.10+.82*i,1.86),(.065,.073,.81),white,.01)
    text_obj("Vessel name","LOTTEN",(side*1.895,-side*1.13,.88),.63,navy,-side,root)
    text_obj("Home port","Stockholm",(side*1.895,side*3.08,1.04),.13,navy,-side,root)
    for end in [-1,1]:
        posts = [(side*w,end*y) for w,y in [(1.86,4.24),(1.85,4.64),(1.80,5.03),
                  (1.70,5.43),(1.52,5.83),(1.21,6.21)]]
        for x,y in posts:
            pole("Bulwark stanchion",(x,y,1.0),.029,.70,white)
        for (x,y),(xx,yy) in zip(posts,posts[1:]):
            for height in [.88,1.11,1.35]:
                tube("Boarding deck rail",(x,y,height),(xx,yy,height),.022,white)
        for i in range(1,len(stations)):
            y,w,_,_ = stations[i-1]
            yy,ww,_,_ = stations[i]
            if (y+yy)*end > 0:
                tube("Hull rubbing strake",(side*w,y,.43),(side*ww,yy,.43),.043,white)
# Pilot windows angle outward above an inset white console.
box("Wheelhouse coaming",(0,-.46,2.58),(2.07,2.36,.42),white,.055)
def pilot_section(y,w,b,s,c):
    return [(-w*.88,y*.89-.46,b),(-w,y-.46,c),(w,y-.46,c),(w*.88,y*.89-.46,b)]
mesh_from_rings("Pilot glass", [(-1.22,1.09,2.76,0,3.44),(1.22,1.09,2.76,0,3.44)],
                glass,root,.02,pilot_section)
for end in [-1,1]:
    for x in [-1.09,-.36,.36,1.09]:
        tube("Raked pilot frame",(x*.88,end*1.22*.89-.46,2.76),
             (x,end*1.22-.46,3.44),.03,white)
    for side in [-1,1]:
        tube("Wheelhouse side mullion",(side*.96,end*.36-.46,2.76),
             (side*1.09,end*.40-.46,3.44),.025,white)
    box("Lower landing ramp",(0,end*6.23,.70),(1.95,.46,.11),deck)
    box("Ramp nosing",(0,end*6.40,.74),(1.95,.10,.07),rubber)
    for side in [-1,1]:
        box("Landing fender",(side*1.11,end*6.33,.46),(.28,.17,.23),rubber,.065)
        box("Boarding door",(side*.98,end*4.29,1.41),(.84,.075,1.47),white,.04)
        box("Boarding door window",(side*.98,end*4.336,1.68),(.63,.027,.70),glass,.035)
        box("Door grab handle",(side*.67,end*4.36,1.25),(.035,.055,.18),steel,.01)
box("White wheelhouse roof",(0,-.46,3.49),(2.34,2.58,.12),white,.06)
for side in [-1,1]:
    for y in [1.32,2.57]:
        for tier in range(3):
            box("Stacked flotation platform",(side*1.12,y,2.45+tier*.09),(.76,1.19,.078),orange,.036)
        for offset in [-.34,.34]:
            box("Raft strap",(side*1.12,y+offset,2.58),(.78,.040,.29),rubber)
pole("Signal mast",(0,-.8,3.94),.046,1.0,steel)
for height, width in [(4.02,.74),(4.25,.45)]:
    tube("Signal yardarm",(-width,-.8,height),(width,-.8,height),.018,steel)
for x,y in [(-.8,-1.25),(.72,.16)]:
    tube("Whip antenna",(x,y,3.55),(x,y,4.62),.012,steel)
box("Radar scanner",(0,-.8,4.43),(.8,.12,.1),white)
pole("Ensign staff",(0,3.32,3.14),.032,1.62,steel)
box("Swedish ensign",(0,3.64,3.68),(.022,.62,.37),navy)
gold=material("Flag gold",(.96,.69,.04))
box("Flag cross bar",(0,3.64,3.68),(.025,.62,.076),gold)
box("Flag cross upright",(0,3.53,3.68),(.026,.078,.37),gold)
export_vehicle(root,"lotten.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE_DIR,"Lotten.blend"))
