"""Build a vintage open-sided shopping tricycle (Blender coordinates, nose at -Y)."""
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector

project = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(project / 'tools'))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Shopping tricycle", None)
bpy.context.collection.objects.link(root)
red = v.material("Cherry red moulded shell", (.64,.026,.034),.22,.26)
vinyl = v.material("Saddle vinyl", (.032,.028,.027),0,.6)
glass = v.material("Clear curved acrylic", (.65,.81,.86),.06,.15)
next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value=.26
amber = v.material("Amber indicator", (.95,.24,.015),.05,.25)
def box(name,pos,size,material,bevel=.018):
    return v.cube(name,pos,size,material,bevel,root)

def tube(name,a,b,radius,material):
    axis=Vector(b)-Vector(a)
    rod=v.cylinder(name,(Vector(a)+Vector(b))/2,radius,axis.length,material,False,16,root)
    rod.rotation_euler=axis.to_track_quat('Z','Y').to_euler()
    return rod

def nose_lamp(name,y,z,radius,depth,material):
    lamp=v.cylinder(name,(0,y,z),radius,depth,material,False,48,root)
    lamp.rotation_euler.x=math.pi/2

def panel_section(y, width, bottom, shoulder, crown):
    height = crown - bottom
    return [(x*width,y,bottom+h*height) for x,h in [
        (-.93,0),(-1,.14),(-1,.77),(-.94,.92),(-.72,.99),(0,1),
        (.72,.99),(.94,.92),(1,.77),(1,.14),(.93,0)]]

v.mesh_from_rings("Pressed chassis",[(-1.15,.37,.19,.46,.52),(-.94,.47,.17,.53,.59),
    (-.42,.46,.21,.53,.58),(.63,.40,.23,.52,.55),(1.16,.37,.24,.48,.51)],red,root,.018,panel_section)
v.mesh_from_rings("Tilting wedge front",[(-1.18,.37,.42,.54,.65),(-1.06,.44,.44,.57,.69),
    (-.46,.47,.51,.80,.92),(-.25,.43,.54,.85,.95)],red,root,.015,panel_section)
nose_lamp("Chrome headlight bezel",-1.185,.58,.101,.045,v.METAL)
nose_lamp("Headlight lens",-1.211,.58,.085,.015,v.HEADLAMP)
nose_lamp("Horn grille",-1.153,.33,.057,.025,v.BLACK)

# The screen bows toward the nose at its centre and narrows under the roof.
def screen_point(u,t):
    return (u*(.418-.026*t),-.43+.33*t+.09*u*u,.916+.603*t-.018*u*u)
verts=[screen_point(i/10,j/4) for j in range(5) for i in range(-10,11)]
faces=[(j*21+i,j*21+i+1,(j+1)*21+i+1,(j+1)*21+i) for j in range(4) for i in range(20)]
mesh=bpy.data.meshes.new("Windscreen sheet")
mesh.from_pydata(verts,[],faces)
mesh.materials.append(glass)
screen=bpy.data.objects.new("Wraparound windscreen",mesh)
bpy.context.collection.objects.link(screen)
screen.parent=root
for f in mesh.polygons: f.use_smooth=True
for t in (0,1):
    for i in range(-10,10):
        tube("Window seal",screen_point(i/10,t),screen_point((i+1)/10,t),.012,v.BLACK)
v.mesh_from_rings("Overhanging canopy",[(-.12,.39,1.495,1.52,1.55),(.02,.425,1.50,1.55,1.57),
    (.38,.435,1.53,1.56,1.59)],red,root,.012,panel_section)
for side in (-1,1):
    tube("Swept canopy pillar",screen_point(side,0),screen_point(side,1),.037,red)
    tube("Mirror stem",(side*.40,-.42,.91),(side*.51,-.43,1.05),.009,v.METAL)
    box("Wing mirror",(side*.51,-.43,1.07),(.094,.034,.07),v.METAL)
    box("Turn signal",(side*.46,-.46,.80),(.024,.085,.046),amber,.008)
# Both the arm and rubber blade sit on the outside of the bowed screen.
def wiper_point(u, t):
    return Vector(screen_point(u, t)) + Vector((0, -.018, 0))

pivot = wiper_point(.25, .08)
blade_joint = wiper_point(-.12, .51)
tube("Wiper spindle", screen_point(.25, .08), pivot, .018, v.METAL)
tube("Wiper arm", pivot, blade_joint, .008, v.DARK)
tube("Wiper blade lower", wiper_point(.06, .32), blade_joint, .011, v.BLACK)
tube("Wiper blade upper", blade_joint, wiper_point(-.30, .70), .011, v.BLACK)
box("Seat cushion",(0,.18,.595),(.61,.42,.093),vinyl,.044)
back=box("Upright seat back",(0,.395,.82),(.60,.074,.48),vinyl,.034)
back.rotation_euler.x=-.12
tube("Steering column",(0,-.27,.58),(0,-.13,.85),.022,v.DARK)
tube("Handlebar",(-.25,-.13,.85),(.25,-.13,.85),.017,v.METAL)
for side in (-1,1):
    tube("Handle grip",(side*.18,-.13,.85),(side*.255,-.13,.85),.024,v.BLACK)
# Fixed fibreglass arches leave clearance for the tyres at full steering lock.
for side in (-1, 1):
    vertices = []
    faces = []
    for step in range(25):
        angle = math.radians(-12 + step * 204 / 24)
        for x, radius in ((.29,.29), (.49,.29), (.54,.274), (.54,.249)):
            vertices.append((side*x, -.72-radius*math.cos(angle), .227+radius*math.sin(angle)))
        if step:
            for strip in range(3):
                i = (step-1)*4+strip
                face = (i,i+1,i+5,i+4)
                faces.append(face if side > 0 else face[::-1])
    mesh = bpy.data.meshes.new("Rolled wheel arch")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(red)
    arch = bpy.data.objects.new("Front mudguard", mesh)
    bpy.context.collection.objects.link(arch)
    arch.parent = root
    for face in mesh.polygons:
        face.use_smooth = True
    shell = arch.modifiers.new("Pressed lip", 'SOLIDIFY')
    shell.thickness = .006
for x,y in ((-.429,-.72),(.429,-.72),(0,.89)):
    v.cylinder("Performance tire",(x,y,.227),.227,.13,v.RUBBER,True,40,root)
    for side in (-1,1):
        v.cylinder("Wheel hub",(x+side*.066,y,.227),.133,.014,v.METAL,True,32,root)
        v.cylinder("Center cap",(x+side*.080,y,.227),.053,.025,v.METAL,True,32,root)
# Tapered wire basket on the rear deck.
for z,w,front,rear in ((.55,.30,.53,1.05),(.72,.36,.49,1.12)):
    corners=[(-w,front,z),(w,front,z),(w,rear,z),(-w,rear,z)]
    for i in range(4): tube("Basket rim",corners[i],corners[(i+1)%4],.010,v.METAL)
for side in (-1,1):
    for i in range(7):
        t=i/6
        tube("Basket wire",(side*.30,.53+.52*t,.55),(side*.36,.49+.63*t,.72),.005,v.METAL)
for i in range(-3,4):
    tube("Basket floor",(i*.095,.53,.55),(i*.095,1.05,.55),.006,v.METAL)
# The rear side panels taper inward. Seat the engine vents flush on that slope.
for side in (-1, 1):
    vent_y = .65
    slope = (.40 - .37) / (1.16 - .63)
    for name, offset, size, finish in (
        ("Service vent surround", .004, (.018,.35,.145), v.METAL),
        ("Recess behind cooling slots", .013, (.014,.326,.124), v.BLACK),
    ):
        panel = box(name, (side*(.40+offset), vent_y, .387), size, finish, .007)
        panel.rotation_euler.z = side*math.atan(slope)
    for row in range(5):
        slat = box("Engine cooling louvre", (side*.421, vent_y, .34+row*.023),
                   (.014,.31,.012), v.DARK, .004)
        slat.rotation_euler.z = side*math.atan(slope)
tube("Exhaust downpipe",(.34,.24,.32),(.426,.34,.213),.020,v.METAL)
tube("Exhaust inlet",(.426,.34,.213),(.426,.52,.198),.020,v.METAL)
tube("Silencer",(.426,.51,.198),(.426,1.01,.202),.042,v.METAL)
for y in (.59,.93):
    tube("Silencer strap",(.426,y-.007,.20),(.426,y+.007,.20),.044,v.DARK)
    box("Exhaust hanger",(.414,y,.256),(.023,.027,.086),v.DARK,.004)
tube("Exhaust outlet",(.426,1.01,.202),(.426,1.12,.194),.022,v.METAL)
tube("Dark outlet bore",(.426,1.12,.194),(.426,1.121,.194),.016,v.BLACK)
# A trailing rubber flap hangs from the deck behind the single rear tyre.
flap = box("Rear mud flap", (0,1.147,.203), (.216,.018,.211), v.RUBBER, .008)
flap.rotation_euler.x = math.radians(13)
box("Mud flap retaining strip", (0,1.132,.293), (.215,.025,.028), v.METAL, .004)
box("Tail lamp",(0,1.16,.43),(.14,.035,.06),v.TAIL_LAMP)
v.export_vehicle(root,"shopping_trike.glb")
if os.getenv("SHOPPER_PORTRAIT"):
    scene=bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    for position, power, size in [((2,-4,5),420,4),((-3,-1,3),260,3),((1,3,4),350,3)]:
        bpy.ops.object.light_add(type='AREA', location=position)
        lamp = bpy.context.object
        lamp.rotation_euler = (Vector((0,0,.7))-lamp.location).to_track_quat('-Z','Y').to_euler()
        lamp.data.energy = power
        lamp.data.size = size
    scene.render.film_transparent=True
    bpy.ops.object.camera_add(location=(4,-3.9,2.3))
    camera=bpy.context.object
    camera.rotation_euler=(Vector((0,0,.79))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'
    camera.data.ortho_scale=4.55
    scene.camera=camera
    scene.render.resolution_x=768
    scene.render.resolution_y=384
    scene.render.resolution_percentage=100
    scene.render.filepath=os.environ['SHOPPER_PORTRAIT']
    bpy.ops.render.render(write_still=True)
