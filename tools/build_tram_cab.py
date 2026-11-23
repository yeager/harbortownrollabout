"""Build the blue tram cab with a raked, wraparound windscreen."""
import math
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mathutils import Vector
from build_vehicles import clear_scene, material, cube, export_vehicle, SOURCE_DIR

clear_scene()
root = bpy.data.objects.new("Tram cab", None)
bpy.context.collection.objects.link(root)
blue = material("Transit blue enamel", (.014,.25,.51), .32,.26)
glass = material("Cab safety glass", (.026,.067,.083), .42,.16)
seal = material("Screen surround", (.014,.021,.026), .18,.3)
silver = material("Roof fairing", (.66,.71,.74), .42,.3)
lamp = material("Dipped headlight", (.91,.86,.68), .1,.2,1.25)
# Profile measurements at the nose tip. The side returns meet the saloon
# 20 mm inside its end frame, including the crown above the windscreen.
rings = [
    (.29,1.065,2.55), (.32,1.095,2.60), (.38,1.125,2.66),
    (.43,1.15,2.69), (.46,1.16,2.70), (.52,1.17,2.72),
    (.67,1.197,2.757), (.84,1.202,2.771), (.96,1.20,2.768),
    (1.04,1.195,2.758), (1.10,1.19,2.747), (1.15,1.182,2.736),
    (1.20,1.176,2.725), (1.31,1.168,2.705), (1.58,1.155,2.650),
    (1.93,1.142,2.562), (2.20,1.13,2.491), (2.26,1.124,2.473),
    (2.45,1.112,2.421), (2.49,1.11,2.406), (2.54,1.105,2.388),
    (2.58,1.095,2.37), (2.615,1.076,2.351), (2.647,1.035,2.324),
    (2.67,.966,2.29), (2.682,.84,2.264), (2.687,.66,2.24)]
# Project the prow farthest at the beltline, then recede into the brow.
rings = [(z,width,tip+.20*max(0,1-abs(z-.96)/1.65)) for z,width,tip in rings]
seam_y = 2.18

def cab_dimensions(z):
    for (lo,w0,y0),(hi,w1,y1) in zip(rings,rings[1:]):
        if lo <= z <= hi:
            mix = (z-lo)/(hi-lo)
            return w0+(w1-w0)*mix, y0+(y1-y0)*mix
    return rings[-1][1:]

def surface_y(x,z):
    width,tip=cab_dimensions(z)
    # Superellipse keeps the destination display readable straight across the
    # centre, with progressively stronger curvature toward the end pillars.
    return seam_y + (tip-seam_y)*max(0,1-abs(x/width)**3.0)**(1/3)

verts, faces, slots = [], [], []
columns=64
for k,(z,width,tip) in enumerate(rings):
    for j in range(columns+1):
        a = math.pi*j/columns
        x=width*math.copysign(abs(math.cos(a))**(2/3),math.cos(a))
        verts.append((x,seam_y+(tip-seam_y)*max(0,math.sin(a))**(2/3),z))
        if not k or not j:
            continue
        row=k*(columns+1)
        faces.append((row+j-columns-2,row+j-columns-1,row+j,row+j-1))
        mid=(z+rings[k-1][0])/2
        if mid<.43: slot=2
        elif mid<1.10: slot=0
        elif mid<2.49:
            slot=2 if mid<1.20 or mid>2.20 or min(j,columns-j+1)<3 else 1
        else: slot=3
        slots.append(slot)
# Cover the rounded brow, leaving the rear aperture open to the saloon.
faces.append(tuple(range((len(rings)-1)*(columns+1),len(verts))))
slots.append(3)
mesh = bpy.data.meshes.new("Wraparound driver compartment")
mesh.from_pydata(verts, [], faces)
mesh.update()
obj = bpy.data.objects.new("Swept cab shell",mesh)
bpy.context.collection.objects.link(obj)
obj.parent=root
for mat in [blue,glass,seal,silver]: mesh.materials.append(mat)
for face,slot in zip(mesh.polygons,slots):
    face.material_index=slot
    face.use_smooth=True

def fascia_patch(name,x0,x1,z0,z1,radius,offset,mat):
    # A rounded patch projected onto the actual compound-curved nose.
    outline=[]
    for cx,cz,a0 in [(x1-radius,z1-radius,0),(x0+radius,z1-radius,90),
                     (x0+radius,z0+radius,180),(x1-radius,z0+radius,270)]:
        for step in range(9):
            a=math.radians(a0+90*step/8)
            outline.append((cx+radius*math.cos(a),cz+radius*math.sin(a)))
    # Multiple intermediate rings conform broad faceplates to the screen.
    cx,cz=(x0+x1)/2,(z0+z1)/2
    points=[(cx,surface_y(cx,cz)+offset,cz)]
    patches=[]
    for ring in range(1,7):
        start=len(points)
        for i,(x,z) in enumerate(outline):
            x,z=cx+(x-cx)*ring/6,cz+(z-cz)*ring/6
            points.append((x,surface_y(x,z)+offset,z))
            j=(i+1)%len(outline)
            if ring==1: patches.append((0,start+j,start+i))
            else: patches.append((start+i-len(outline),start+j-len(outline),start+j,start+i))
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(points,[],patches)
    mesh.materials.append(mat)
    mesh.update()
    for face in mesh.polygons: face.use_smooth=True
    patch=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(patch)
    patch.parent=root

for side in [-1,1]:
    x=side*.86
    fascia_patch("Recessed lamp cluster",x-.17,x+.17,.85,1.025,.075,.010,seal)
    fascia_patch("Dipped LED lens",x-.122,x+.122,.933,.979,.021,.019,lamp)
    fascia_patch("Marker light",x-.058,x+.058,.881,.909,.013,.019,lamp)
fascia_patch("Route indicator surround",-.76,.76,2.235,2.446,.078,.010,seal)
fascia_patch("Amber matrix panel",-.694,.694,2.256,2.424,.050,.017,glass)
# Follow the rounded skirt with a replaceable rubbing strip and a flush access door.
fascia_patch("Skirt rubbing strip",-.99,.99,.419,.471,.022,.009,seal)
fascia_patch("Access door gasket",-.488,.488,.518,.708,.042,.007,seal)
fascia_patch("Lower service hatch",-.48,.48,.525,.70,.035,.012,blue)
for x in (-.39,.39):
    fascia_patch("Recessed quarter-turn latch",x-.017,x+.017,.643,.677,.016,.016,silver)
    fascia_patch("Latch slot",x-.009,x+.009,.658,.662,.0015,.019,seal)
def screen_point(x,z):
    return Vector((x,surface_y(x,z)+.018,z))

def wiper_bar(label, start, end, width):
    offset = end-start
    bar = cube(label,(start+end)*.5,(width,.020,offset.length),seal,.006,root)
    bar.rotation_euler = offset.to_track_quat("Z","Y").to_euler()

for side in (-1,1):
    hinge = screen_point(side*.76,1.20)
    joint = screen_point(side*.36,1.54)
    wiper_bar("Wiper arm",hinge,joint,.022)
    wiper_bar("Wiper blade",screen_point(side*.63,1.39),screen_point(side*.10,1.70),.036)

# The nose colour tapers into the saloon waist; its upper edge follows the
# lower windscreen rather than breaking abruptly at the cab/saloon seam.
for side in [-1,1]:
    rows = [(.52,.657),(.68,.667),(.97,.727),(1.28,.841),(1.58,.962),(1.88,1.052),(2.19,1.099)]
    verts=[]
    for y,top in rows:
        for z in (.651,(.651+top)*.5,top):
            # Follow the outward camber on the saloon side pressing.
            width=1.209-.009*(z-.90)**2/.09
            verts.append((side*width,y,z))
    faces=[]
    for j in range(len(rows)-1):
        for k in range(2):
            idx=3*j+k
            face=(idx,idx+3,idx+4,idx+1)
            faces.append(face if side>0 else tuple(reversed(face)))
    mesh=bpy.data.meshes.new("Cab livery transition")
    mesh.from_pydata(verts,[],faces)
    mesh.materials.append(blue)
    mesh.update()
    panel=bpy.data.objects.new("Swept blue flank",mesh)
    bpy.context.collection.objects.link(panel)
    panel.parent=root

export_vehicle(root,"tram_cab.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"TramCab.blend"))
