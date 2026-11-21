"""Stockholm-inspired articulated tram saloon. Blender +Y faces the leading cab."""
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector

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
seat = material("Royal blue moquette", (.024,.055,.23), .01,.87)
cream = material("Warm ivory interior lining", (.88,.81,.65), .08,.53)
floor_mat = material("Slate nonslip lino", (.16,.18,.19), .03,.78)
shell = material("Seat shell", (.235,.265,.29), .12,.52)
teal = material("Aqua moquette yarn", (.13,.51,.55), .0,.88)
violet = material("Lilac moquette yarn", (.31,.32,.51), .0,.88)
rose = material("Red moquette yarn", (.55,.12,.13), .0,.88)
gold = material("Gold moquette yarn", (.72,.47,.10), .0,.88)
light = material("Warm ceiling diffuser", (.97,.87,.68), .0,.45,1.5)
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

def tube(name, a, b, radius, finish):
    delta = Vector(b)-Vector(a)
    obj = cylinder(name,(Vector(a)+Vector(b))*.5,radius,delta.length,finish,False,12,root)
    obj.rotation_euler = delta.to_track_quat("Z","Y").to_euler()

# The woven pattern is small geometry batched with the rest of the upholstery.
# Its scale stays constant across differently shaped cushions and backrests.
pattern_patches = {teal: [], violet: [], rose: [], gold: []}

def seat_at(x, y, facing):
    cube("Seat pedestal",(x,y,.68),(.13,.17,.38),steel,.025,root)
    cube("Moulded seat base",(x,y,.885),(.40,.46,.10),shell,.042,root)
    cube("Moquette cushion",(x,y,.945),(.37,.42,.09),seat,.040,root)
    back_y = y-facing*.205
    tilt = facing*math.radians(7)
    for name, shift, width, height, finish in [
        ("Curved seat shell", -.045, .414,.60,shell),
        ("Upholstered back", .014, .37,.53,seat)
    ]:
        back = cube(name,(x,back_y+facing*shift,1.19),(width,.08,height),finish,.037,root)
        back.rotation_euler.x = tilt
    for edge in (-1,1):
        # Small foam bolsters follow the contour of the reclining seat back.
        bolster = cube("Side bolster",(x+edge*.157,back_y+facing*.041,1.18),
                       (.059,.061,.45),seat,.027,root)
        bolster.rotation_euler.x = tilt
    grip_y = back_y-facing*.086
    for edge in (-1,1):
        tube("Seat grab support",(x+edge*.125,grip_y,1.43),
             (x+edge*.12,grip_y,1.525),.013,shell)
    tube("Rounded seat-top grip",(x-.12,grip_y,1.525),(x+.12,grip_y,1.525),.016,yellow)
    rng = random.Random(round(x*1000)+round(y*1000))
    for row in range(8):
        for col in range(5):
            u = -.13+col*.064+rng.uniform(-.016,.016)
            v = -.21+row*.057+rng.uniform(-.015,.015)
            # Four-point lozenge on the gently reclining fabric surface.
            dx,dy = rng.choice([(.009,.007),(-.006,.009),(.008,-.002)])
            offsets = [(u-dx,v-dy),(u+dx,v+dy),(u+dx+.004,v+dy-.004),(u-dx+.004,v-dy-.004)]
            patch = []
            for px,pz in offsets:
                py = facing*.043
                patch.append((x+px, back_y+facing*.014 + py*math.cos(tilt)-pz*math.sin(tilt),
                              1.19 + py*math.sin(tilt)+pz*math.cos(tilt)))
            yarn = rng.choice((teal,violet,teal,violet,rose,gold))
            pattern_patches[yarn].append(patch)
            if row < 7:
                pattern_patches[yarn].append([(x+px,y+pz,.991) for px,pz in offsets])

def add_yarn(finish, patches):
    verts = [vertex for patch in patches for vertex in patch]
    faces = [tuple(range(i,i+4)) for i in range(0,len(verts),4)]
    mesh = bpy.data.meshes.new(finish.name)
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(finish)
    mesh.update()
    obj = bpy.data.objects.new(finish.name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = root

# The middle gap is the real sliding doorway. The floor continues through it.
cube("Vestibule floor", (0,0,.43), (2.33,4.42,.12), black,.03,root)
cube("Continuous non-slip aisle",(0,0,.49),(2.30,4.42,.038),floor_mat,.015,root)
for y in (-1.71,-.76,.40,1.49):
    cube("Lino panel seam",(0,y,.509),(2.23,.012,.002),shell,.0,root)
for end in (-1,1):
    # A recessed frame separates the sections while leaving a full-height central passage.
    for side in (-1,1):
        cube("Ivory gangway cheek",(side*.985,end*2.145,1.36),(.31,.09,1.72),cream,.036,root)
        cube("Gangway side seal",(side*.828,end*2.18,1.34),(.068,.08,1.69),black,.022,root)
    cube("Gangway lintel",(0,end*2.15,2.195),(1.86,.10,.085),black,.024,root)
    cube("Gangway threshold",(0,end*2.27,.48),(.93,.31,.043),floor_mat,.014,root)
band("Shoulder fascia", -2.20,2.20,2.27,2.55,1.18,1.13,silver)
band("Rounded roof shoulders", -2.20,2.20,2.55,2.67,1.13,.98,silver)
for start,end in [(-2.20,-.65),(.39,2.20)]:
    band("Inset skirt",start,end,.28,.48,1.08,1.17,black)
    mid = (start+end)*.5
    for side in [-1,1]:
        outer = sorted([side*1.20,side*1.12])
        section("Side panel",start,end,[(outer[0],.65),(outer[1],.65),(outer[1],1.19),(outer[0],1.19)],silver)
        section("Waist stripe",start,end,[(outer[0],.48),(outer[1],.48),(outer[1],.65),(outer[0],.65)],blue)
        cube("Seat plinth and wheel cover",(side*.855,mid,.536),(.53,end-start-.04,.10),floor_mat,.028,root)
        cube("Ivory window ledge",(side*1.09,mid,1.18),(.10,end-start,.066),cream,.024,root)
        cube("Ivory lower wall",(side*1.105,mid,.85),(.037,end-start,.67),cream,.015,root)
        for post in (start+.036,mid,end-.036):
            cube("Glazing pillar",(side*1.155,post,1.73),(.07,.073,1.09),frame,.012,root)
        for a,b in [(start,mid),(mid,end)]:
            cube("Passenger window",(side*1.16,(a+b)*.5,1.73),(.031,b-a-.05,1.01),glass,.014,root)
        for z in (1.205,2.245):
            cube("Bonded window seal",(side*1.158,mid,z),(.07,end-start,.065),frame,.013,root)
        for row in (-1,1):
            for x in ([.88,.462] if side==1 else [-.86]):
                seat_at(x, mid+row*.36, 1 if mid>0 else -1)

for finish, patches in pattern_patches.items():
    add_yarn(finish, patches)

cube("Interior destination board",(0,2.13,2.145),(.90,.073,.16),black,.020,root)
cube("LED matrix surround",(0,2.09,2.145),(.84,.008,.126),frame,.004,root)
cube("Headliner",(0,0,2.256),(2.26,4.41,.036),cream,.014,root)
for side in (-1,1):
    x = side*.51
    cube("Ceiling lamp surround",(side*.74,0,2.22),(.22,4.31,.062),shell,.025,root)
    cube("Ceiling strip diffuser",(side*.74,0,2.186),(.14,4.19,.027),light,.013,root)
    tube("Overhead grab rail",(x,-2.08,2.07),(x,2.08,2.07),.023,yellow)
    for y in (-1.84,-.70,.48,1.82):
        tube("Ceiling bracket",(x,y,2.07),(x,y,2.25),.016,steel)
    for y in (-1.60,-1.12,.79,1.36):
        tube("Hanger strap",(x,y,2.07),(x,y,1.98),.012,black)
        a,b,c = (x,y,1.99),(x,y-.073,1.87),(x,y+.073,1.87)
        for start,end in [(a,b),(b,c),(c,a)]:
            tube("Triangular hand grip",start,end,.013,yellow)
    for y in (-.69,.44):
        tube("Entrance stanchion",(side*.84,y,.51),(side*.84,y,2.19),.023,yellow)
        tube("Stanchion bend",(side*.84,y,2.19),(side*.70,y,2.24),.023,yellow)

cube("Bogie frame",(0,0,.32),(1.67,2.45,.26),black,.065,root)
for y in (-.91,.91):
    for side in [-1,1]:
        cylinder("Steel wheel",(side*.72,y,.29),.27,.13,steel,True,24,root)
        cylinder("Axle bearing",(side*.86,y,.29),.13,.12,black,True,16,root)
cube("Roof equipment housing",(0,1.28,2.72),(1.37,1.14,.18),steel,.065,root)
for y in (.89,1.04,1.19,1.34,1.49,1.64):
    cube("Roof louvre",(0,y,2.815),(1.05,.049,.024),black,.008,root)
# Batch opaque geometry by material to keep the three-car consist inexpensive.
for mat in (blue,silver,steel,black,frame,seat,yellow,cream,floor_mat,shell,light):
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
