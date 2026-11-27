"""Build the twin-ended Lotten passenger ferry for the Sjöstad canal."""
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, cube, cylinder, mesh_from_rings, material,
                            text_obj, export_vehicle, profile_loft, SOURCE_DIR)

clear_scene()
root = bpy.data.objects.new("Lotten", None)
bpy.context.collection.objects.link(root)
white = material("Painted aluminium", (.94,.924,.845), .24,.32)
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
box("Shelter roof",(0,0,2.33),(3.97,8.82,.11),rubber,.04)
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
    for row_y in (6.13,6.21,6.29):
        box("Ramp anti-slip strip",(0,end*row_y,.760),(1.77,.031,.016),rubber,.004)
    for side in (-1,1):
        box("Ramp edge strip",(side*.927,end*6.20,.761),(.048,.32,.017),steel,.004)
    for side in [-1,1]:
        bitt_x, bitt_y = side*1.39, end*5.43
        box("Mooring bitt base",(bitt_x,bitt_y,.684),(.22,.47,.034),steel,.010)
        for offset in (-.124,.124):
            pole("Mooring bitt post",(bitt_x,bitt_y+offset,.811),.049,.238,steel)
            pole("Mooring bitt head",(bitt_x,bitt_y+offset,.935),.073,.034,steel)
        for offset in (-.19,.19):
            pole("Mooring base fastener",(bitt_x,bitt_y+offset,.706),.018,.014,steel)
        box("Landing fender backing plate",(side*1.11,end*6.377,.466),
            (.467,.062,.354),steel,.018)
        box("Fender upper retaining flange",(side*1.11,end*6.384,.627),
            (.29,.075,.031),steel,.008)
        for offset in (-.085,.085):
            pole("Fender retaining bolt",(side*1.11+offset,end*6.408,.645),
                 .017,.017,steel)
        box("Landing fender",(side*1.11,end*6.33,.46),(.43,.25,.32),rubber,.095)
        box("Boarding door",(side*.98,end*4.29,1.41),(.84,.075,1.47),white,.04)
        box("Boarding window gasket",(side*.98,end*4.333,1.68),(.674,.026,.744),rubber,.041)
        box("Boarding door window",(side*.98,end*4.336,1.68),(.63,.027,.70),glass,.035)
        handle_x = side*.67
        for z in (1.098,1.272):
            box("Door handle mounting pad",(handle_x,end*4.340,z),
                (.078,.028,.049),steel,.008)
            tube("Door handle return",(handle_x,end*4.349,z),
                 (handle_x,end*4.398,z),.017,steel)
        tube("Door grab handle",(handle_x,end*4.398,1.098),
             (handle_x,end*4.398,1.272),.017,steel)
box("White wheelhouse roof",(0,-.46,3.49),(2.34,2.58,.12),white,.06)
for side in [-1,1]:
    for y in [1.32,2.57]:
        for tier in range(3):
            box("Stacked flotation platform",(side*1.12,y,2.45+tier*.09),(.76,1.19,.078),orange,.036)
        for offset in [-.34,.34]:
            strap_y = y+offset
            box("Raft cradle rail",(side*1.12,strap_y,2.399),(.84,.079,.031),steel,.006)
            box("Raft strap",(side*1.12,strap_y,2.55),(.78,.040,.277),rubber,.009)
            box("Raft buckle frame",(side*1.30,strap_y,2.697),(.103,.073,.022),steel,.006)
            box("Raft buckle webbing",(side*1.30,strap_y,2.710),(.075,.039,.010),rubber,.003)
            box("Raft buckle crossbar",(side*1.30,strap_y,2.718),(.018,.066,.012),steel,.003)
pole("Signal mast",(0,-.8,3.94),.046,1.0,steel)
for height, width in [(4.02,.74),(4.25,.45)]:
    tube("Signal yardarm",(-width,-.8,height),(width,-.8,height),.018,steel)
for x,y in [(-.8,-1.25),(.72,.16)]:
    tube("Whip antenna",(x,y,3.55),(x,y,4.62),.012,steel)
box("Radar scanner",(0,-.8,4.43),(.8,.12,.1),white)
gold = material("Signal yellow", (.99,.66,.035))
red = material("Lifebuoy vermilion", (.82,.045,.022), .04,.46)
oxide = material("Waterline oxide red", (.39,.065,.043), .13,.50)
brass = material("Funnel bronze", (.34,.13,.068), .45,.43)

# Follow the chines down to their intersection with the waterline.
for side in [-1,1]:
    vertices = []
    for y,w,b,c in stations:
        shoulder = b+(c-b)*.22
        for z in [.016,.090]:
            z = max(z,b+.002)
            if z < shoulder:
                fraction = .60+.29*(z-b)/(shoulder-b)
            else:
                fraction = .89+.11*(z-shoulder)/(.39-shoulder)
            vertices.append((side*w*fraction+side*.006,y,z))
    mesh = bpy.data.meshes.new("Waterline ribbon")
    mesh.from_pydata(vertices,[],[(i,i+1,i+3,i+2) for i in range(0,len(vertices)-2,2)])
    band = bpy.data.objects.new("Antifouling stripe",mesh)
    bpy.context.collection.objects.link(band)
    band.parent = root
    mesh.materials.append(oxide)

# The upper promenade wraps the wheelhouse and life-saving equipment.
corners = [(-1.74,-2.18),(1.74,-2.18),(1.74,3.46),(-1.74,3.46)]
for a,b in zip(corners,corners[1:]+corners[:1]):
    length = math.dist(a,b)
    count = math.ceil(length/1.1)
    for i in range(count):
        x,y = [a[k]+(b[k]-a[k])*i/count for k in (0,1)]
        pole("Promenade baluster",(x,y,2.66),.018,.58,white)
    for z in (2.64,2.95):
        tube("Promenade rail",(*a,z),(*b,z),.022,white)

for side in [-1,1]:
    x = side*1.976
    box("Rescue ring mounting spine",(side*1.904,3.28,1.75),
        (.045,.082,.50),steel,.010)
    for z in (1.504,1.968):
        tube("Rescue ring cradle arm",(side*1.91,3.28,z),
             (side*2.026,3.28,z),.014,steel)
    pole("Rescue ring cradle lip",(side*2.026,3.28,1.523),.014,.068,steel)
    bpy.ops.mesh.primitive_torus_add(major_radius=.227, minor_radius=.062,
            major_segments=48, minor_segments=10, location=(x,3.22,1.75),
            rotation=(0,math.pi/2,0))
    ring = bpy.context.object
    ring.name = "Rescue ring"
    ring.parent = root
    ring.data.materials.append(red)
    ring.data.materials.append(white)
    for face in ring.data.polygons:
        angle = math.atan2(face.center.y,face.center.x)
        face.material_index = int(abs(math.sin(2*angle)) < .24)
        face.use_smooth = True
    for end in [-1,1]:
        # Heavy oblique cushions absorb impacts as the ferry meets the landing.
        tube("Docking buffer",(side*1.30,end*6.18,.40),(side*1.51,end*5.97,.66),.105,rubber)
for end in [-1,1]:
    for x in [-.84,.84]:
        pole("Gate upright",(x,end*6.06,.997),.028,.574,gold)
        box("Gate deck plate",(x,end*6.048,.752),(.105,.115,.021),steel,.006)
        for offset in (-.032,.032):
            pole("Gate base bolt",(x+offset,end*6.019,.768),.009,.014,steel)
    for z in (.877,1.135):
        pole("Gate hinge collar",(-.84,end*6.06,z),.039,.061,steel)
        pole("Gate hinge pin head",(-.84,end*6.06,z+.035),.022,.013,steel)
    box("Gate latch housing",(.84,end*6.06,1.195),(.085,.082,.067),steel,.010)
    tube("Gate latch pull",(.802,end*6.031,1.198),(.735,end*6.031,1.198),.014,steel)
    for height in (.91,1.27):
        tube("Landing gate",(-.84,end*6.06,height),(.84,end*6.06,height),.026,gold)
    for x in [-.54,-.27,0,.27,.54]:
        pole("Gate spindle",(x,end*6.06,1.08),.014,.36,gold)

pole("Funnel deck flange",(1.36,.51,2.40),.151,.033,steel)
for index in range(4):
    angle = (index+.5)*math.tau/4
    pole("Funnel flange bolt",(1.36+.119*math.cos(angle),.51+.119*math.sin(angle),2.421),
         .016,.015,steel)
pole("Funnel",(1.36,.51,3.101),.091,1.463,brass)
rim_profile = [(3.805,.089),(3.819,.109),(3.917,.109),(3.950,.105),
               (3.953,.078),(3.938,.070),(3.844,.070),(3.826,.065)]
angles = [index*math.tau/32 for index in range(32)]
profile_loft("Recessed exhaust outlet",[
    [(1.36+radius*math.cos(angle),.51+radius*math.sin(angle),z) for angle in angles]
    for z,radius in rim_profile
],rubber,root)
blue = material("Ensign blue", (.012,.15,.43))
def flag(name,y,swedish):
    pole(name+" staff",(0,y,3.91),.032,3.08,steel)
    # Shared vertices give the fly and hem a gentle twist in the same wind.
    width,height = .88,.51
    us = sorted(set([i/12 for i in range(13)]+[.32,.46]))
    vs = [0,.38,.50,.62,1]
    coords,faces,indices = [],[],[]
    for u in us:
        for v in vs:
            coords.append((u*.16*math.sin(8*u+v*.8),y+width*u,
                           5.34-height*v-.085*u+.035*u*math.sin(7*u+v)))
    for i in range(len(us)-1):
        for j in range(len(vs)-1):
            n = i*len(vs)+j
            faces.append((n,n+len(vs),n+len(vs)+1,n+1))
            u,v = (us[i]+us[i+1])/2,(vs[j]+vs[j+1])/2
            mark = (.32<u<.46 or .38<v<.62) if swedish else abs(u-.48)*1.55+abs(v-.5)<.30
            indices.append(int(mark))
    mesh = bpy.data.meshes.new(name+" cloth")
    mesh.from_pydata(coords,[],faces)
    obj = bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = root
    mesh.materials.append(blue)
    mesh.materials.append(gold)
    for face,index in zip(mesh.polygons,indices):
        face.material_index = index
        face.use_smooth = True
flag("Swedish ensign",-2.60,True)
flag("House burgee",3.62,False)
export_vehicle(root,"lotten.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE_DIR,"Lotten.blend"))
