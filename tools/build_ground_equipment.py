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
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'vehicles'/(name+'.glb')), export_format='GLB', export_apply=True)

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
# Stamp both blade chambers into one shell with a continuous rolled skirt.
outline = []
for centre, start in ((.29, -math.pi/2), (-.29, math.pi/2)):
    for i in range(21):
        angle = start + math.pi*i/20
        outline.append((centre + .36*math.cos(angle), .36*math.sin(angle)))
rings = [(1.0, .092), (1.0, .112), (.976, .128), (.961, .209), (.925, .237)]
vertices = [(x*scale, -1.04+y*scale, z) for scale,z in rings for x,y in outline]
count = len(outline)
faces = [tuple(reversed(range(count)))]
for level in range(len(rings)-1):
    for i in range(count):
        j = (i+1) % count
        a = level*count
        faces.append((a+i, a+j, a+count+j, a+count+i))
faces.append(tuple(range(len(vertices)-count, len(vertices))))
deck_mesh = bpy.data.meshes.new("Stamped deck shell")
deck_mesh.from_pydata(vertices, [], faces)
deck_mesh.update()
deck_mesh.materials.append(frame)
deck = bpy.data.objects.new("Cutting deck", deck_mesh)
bpy.context.collection.objects.link(deck)
for x in (-.29,.29):
    rod("Lift arm",(x,-.56,.32),(x,-1.05,.21),.028,steel)
    wheel_x = x*1.8
    disc("Gauge wheel",(wheel_x,-1.31,.095),.095,.08,rubber,(1,0,0))
    disc("Gauge wheel axle",(wheel_x,-1.31,.095),.023,.123,steel,(1,0,0))
    for cheek in (-.051,.051):
        rod("Caster fork",(wheel_x+cheek,-1.31,.095),(wheel_x+cheek,-1.26,.215),.014,frame)
    box("Caster yoke",(wheel_x,-1.26,.215),(.13,.061,.032),frame,.009)
    disc("Swivel bearing",(wheel_x,-1.26,.241),.031,.039,steel)
    rod("Caster mount",(wheel_x,-1.26,.256),(x,-1.12,.225),.021,frame)

# The front guard wraps around the blade housing and returns to its side mounts.
guard = bpy.data.curves.new("Tubular deck bumper", 'CURVE')
guard.dimensions = '3D'
guard.bevel_depth = .018
guard.bevel_resolution = 3
guard.use_fill_caps = True
rail = guard.splines.new('BEZIER')
path = [(-.60,-1.07,.20),(-.59,-1.30,.18),(-.48,-1.40,.145),
        (0,-1.42,.145),(.48,-1.40,.145),(.59,-1.30,.18),(.60,-1.07,.20)]
rail.bezier_points.add(len(path)-1)
for point, position in zip(rail.bezier_points,path):
    point.co = position
    point.handle_left_type = point.handle_right_type = 'AUTO'
guard.materials.append(frame)
bpy.context.collection.objects.link(bpy.data.objects.new("Front deck guard",guard))
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
    disc("Cutting edge washer",(-1.44+i*.24,-.287,.16),.023,.008,frame,(0,1,0))
    disc("Cutting edge bolt",(-1.44+i*.24,-.296,.16),.016,.016,steel,(0,1,0))
for x in (-1.02,0,1.02):
    box("Cutting edge clamp strip",(x,-.272,.16),(1.013,.025,.058),steel,.007)
for x in (-.37,.37):
    rod("Mounting arm",(x,.02,.35),(x,.72,.64),.066,frame)
    rod("Hydraulic ram",(x,.05,.64),(x,.64,.52),.043,steel)
# Rear trip springs sit between brackets welded to the mouldboard.
for x in (-.99,-.78,.78,.99):
    for z in (.29,.65):
        box("Spring anchor",(x,.10,z),(.115,.22,.035),frame,.009)
    coil = bpy.data.curves.new("Trip spring wire", 'CURVE')
    coil.dimensions = '3D'
    coil.bevel_depth = .009
    coil.bevel_resolution = 2
    helix = coil.splines.new('POLY')
    helix.points.add(96)
    for i, point in enumerate(helix.points):
        t = i/96
        angle = 8*math.tau*t
        point.co = (x+.034*math.cos(angle),.16+.034*math.sin(angle),.30+.34*t,1)
    coil.materials.append(steel)
    bpy.context.collection.objects.link(bpy.data.objects.new("Trip spring",coil))

lens = finish("Work lamp lens",(.92,.96,1),0,.24)
shader = lens.node_tree.nodes.get("Principled BSDF")
shader.inputs["Emission Color"].default_value = (.86,.94,1,1)
shader.inputs["Emission Strength"].default_value = 1.6
for x in (-1.28,1.28):
    box("Work lamp mounting saddle",(x,.024,.851),(.145,.090,.070),frame,.010)
    for offset in (-.048,.048):
        disc("Work lamp saddle bolt",(x+offset,.074,.851),.011,.012,steel,(0,1,0))
    rod("Lamp stalk",(x,.02,.84),(x,.055,.98),.019,frame)
    box("Work lamp housing",(x,.046,1.0),(.148,.086,.097),rubber,.018)
    box("Work lamp lens bezel",(x,.004,1.0),(.131,.020,.081),frame,.009)
    box("Work lamp cable gland",(x,.085,.972),(.041,.035,.032),rubber,.009)
    box("Work lamp diffuser",(x,-.001,1.0),(.118,.013,.072),lens,.006)
export("tractor_snow_blade")
