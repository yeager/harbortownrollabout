"""Build the ride-on mower and detachable tractor blade in metres."""
import math
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)

def finish(name, rgb, metallic=0, roughness=.55):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    shader = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    for key, value in [('Base Color', mat.diffuse_color), ('Metallic', metallic), ('Roughness', roughness)]:
        shader.inputs[key].default_value = value
    return mat

paint = finish("Tangerine enamel", (.92,.135,.009), .32,.29)
rubber = finish("Tyre rubber", (.019,.022,.024), 0,.92)
steel = finish("Galvanised steel", (.42,.45,.46), .73,.32)
frame = finish("Graphite steel", (.068,.078,.085), .52,.47)
seat = finish("Seat vinyl", (.038,.044,.048), 0,.63)

def part(name, mat, size=None, bevel=0):
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    if size:
        obj.dimensions = size
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Rolled edges", 'BEVEL')
        mod.width, mod.segments = bevel, 4
        obj.modifiers.new("Face normals", 'WEIGHTED_NORMAL')
    return obj

def box(name, loc, size, mat, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    return part(name,mat,size,bevel)

def disc(name,loc,radius,depth,mat,axis=(0,0,1)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=40,radius=radius,depth=depth,location=loc)
    obj = part(name,mat,bevel=min(.012,depth*.15))
    obj.rotation_euler = Vector(axis).to_track_quat('Z','Y').to_euler()
    return obj

def rod(name,a,b,r,mat):
    a,b = Vector(a),Vector(b)
    return disc(name,(a+b)/2,r,(a-b).length,mat,b-a)

def export(name):
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'vehicles'/(name+'.glb')), export_format='GLB')

box("Ladder frame",(0,.02,.36),(.61,1.52,.18),frame)
box("Engine bonnet",(0,.64,.64),(.83,.64,.44),paint,.14)
box("Bonnet lid",(0,.67,.855),(.61,.42,.035),frame)
for n in range(7):
    box("Cooling louvre",(0,.964,.53+n*.032),(.53,.018,.013),rubber,.004)
for side in (-1,1):
    box("Wheel arch",(side*.37,.1,.57),(.30,.92,.17),paint,.08)
    box("Footboard",(side*.28,-.39,.36),(.30,.58,.07),frame)
    for y in (-.43,.58):
        x=side*.43
        disc("All terrain tire",(x,y,.24),.24,.16,rubber,(1,0,0))
        disc("Alloy wheel",(x+side*.08,y,.24),.142,.036,steel,(1,0,0))
        disc("Wheel hub",(x+side*.106,y,.24),.065,.026,frame,(1,0,0))
        for n in range(20):
            a=n*math.tau/20
            tread=box("Mower tread",(x,y+.239*math.sin(a),.24+.239*math.cos(a)),(.14,.034,.019),rubber,.006)
            tread.rotation_euler.x=-a
box("Seat cushion",(0,.18,.74),(.52,.48,.105),seat,.05)
box("Seat back",(0,.395,.92),(.49,.10,.37),seat,.047).rotation_euler.x=-.15
box("Column cover",(0,-.54,.54),(.24,.24,.38),paint,.065).rotation_euler.x=-.16
rod("Column",(0,-.56,.55),(0,-.39,.94),.029,frame)
bpy.ops.mesh.primitive_torus_add(location=(0,-.39,.94),major_radius=.156,minor_radius=.015)
part("Steering wheel",rubber).rotation_euler.x=-.36
for x in (-.14,.14):
    rod("Wheel spoke",(0,-.39,.94),(x,-.39,.94),.009,steel)
for x in (-.29,.29):
    disc("Cutting deck",(x,-1.04,.164),.36,.145,frame)
    rod("Lift arm",(x,-.56,.32),(x,-1.05,.21),.028,steel)
    disc("Gauge wheel",(x*1.8,-1.31,.095),.095,.08,rubber,(1,0,0))
box("Belt guard",(0,-1.04,.252),(.74,.42,.115),paint,.05)
export("ride_on_mower")

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()
# Cross-section from the replaceable cutting edge up to the rolled lip.
profile=[(-.23,.14),(-.10,.27),(.018,.47),(.06,.65),(.035,.80),(-.035,.89)]
verts=[(x,y,z) for y,z in profile for x in (-1.53,1.53)]
mesh=bpy.data.meshes.new("Rolled mouldboard")
mesh.from_pydata(verts,[],[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(profile)-1)])
blade=bpy.data.objects.new("Orange mouldboard",mesh)
bpy.context.collection.objects.link(blade)
mesh.materials.append(paint)
blade.modifiers.new("Plate gauge",'SOLIDIFY').thickness=.035
for f in mesh.polygons: f.use_smooth=True
box("Rubber cutting edge",(0,-.233,.106),(3.07,.073,.16),rubber,.015)
box("Lip",(0,-.035,.89),(3.08,.078,.057),paint)
for i in range(13):
    disc("Cutting edge bolt",(-1.44+i*.24,-.279,.16),.017,.017,steel,(0,1,0))
for x in (-.37,.37):
    rod("Mounting arm",(x,.02,.35),(x,.72,.64),.066,frame)
    rod("Hydraulic ram",(x,.05,.64),(x,.64,.52),.043,steel)
export("tractor_snow_blade")
