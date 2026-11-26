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
mirror_glass = v.material("Silvered mirror glass", (.53,.61,.65),.85,.15)
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
    (-.66,.46,.20,.50,.57)],red,root,.018,panel_section)
v.mesh_from_rings("Seat pedestal and rear deck",[(.005,.42,.21,.50,.55),(.42,.425,.22,.52,.56),(.78,.385,.23,.51,.54),
    (1.02,.345,.24,.50,.525),(1.16,.315,.25,.48,.51)],red,root,.018,panel_section)
# The central lamp sits on a flat panel. Close-set sections roll its outer
# corners back into the sloping cheeks without narrowing the footwell.
bonnet = v.mesh_from_rings("Tilting wedge front",[(-1.18,.303,.428,.54,.65),
    (-1.174,.337,.422,.54,.654),(-1.157,.365,.421,.545,.661),
    (-1.127,.388,.427,.554,.671),(-1.06,.427,.44,.57,.69),
    (-.46,.47,.51,.80,.92),(-.25,.43,.54,.85,.95)],red,root,.015,panel_section)
# Hollow the underside from the driver side, keeping the outer cheeks and bonnet skin.
cutter = box("Footwell cavity",(0,-.35,.41),(.76,.60,.70),v.BLACK,.025)
bpy.context.view_layer.objects.active = bonnet
cut = bonnet.modifiers.new("Recess for knees and boots", 'BOOLEAN')
cut.operation = 'DIFFERENCE'
cut.object = cutter
bpy.ops.object.modifier_apply(modifier=cut.name)
bpy.data.objects.remove(cutter,do_unlink=True)
box("Pressed footwell floor",(0,-.315,.211),(.82,.73,.044),red,.018)
box("Rubber foot mat",(0,-.315,.238),(.765,.64,.010),v.RUBBER,.005)
fixed_parts = set(root.children) - {bonnet}
# The rubber seat follows the bonnet; the spun bezel wraps around the glass edge.
for name, finish, section in [
    ("Headlight rubber gasket", v.RUBBER,
     [(.095,-1.179),(.108,-1.179),(.107,-1.189),(.103,-1.194),(.095,-1.194)]),
    ("Chrome headlight bezel", v.METAL,
     [(.094,-1.188),(.102,-1.188),(.102,-1.199),(.099,-1.207),
      (.093,-1.211),(.085,-1.211),(.084,-1.207),(.087,-1.202),(.090,-1.194)]),
]:
    angles = [math.tau*i/64 for i in range(64)]
    rings = [[(radius*math.cos(angle), y, .58+radius*math.sin(angle))
              for angle in angles] for radius,y in section+[section[0]]]
    v.profile_loft(name,rings,finish,root,close_ends=False)
# Flutes are part of one lens mesh so the driving light still has one emitter.
lens_radius = .085
vertices = [(-lens_radius,-1.208,.58)]
faces = []
columns, rows = 64, 12
for column in range(1, columns):
    u = 2*column/columns-1
    half_height = math.sqrt(1-u*u)
    for row in range(rows+1):
        h = half_height*(2*row/rows-1)
        dome = max(0,1-u*u-h*h)
        flute = .002*(1-math.cos(math.tau*column/4))*math.sqrt(dome)
        vertices.append((lens_radius*u,-1.208-.012*dome-flute,.58+lens_radius*h))
        index = len(vertices)-1
        if row:
            if column == 1:
                faces.append((0,index-1,index))
            else:
                faces.append((index-rows-2,index-1,index,index-rows-1))
tip = len(vertices)
vertices.append((lens_radius,-1.208,.58))
for row in range(rows):
    faces.append((tip-rows-1+row,tip,tip-rows+row))
mesh = bpy.data.meshes.new("Fluted glass reflector lens")
mesh.from_pydata(vertices, [], faces)
mesh.materials.append(v.material("Fluted headlamp glass",(.46,.53,.52),.38,.20))
# Alternating reflector highlights remain readable when the flutes are subpixel.
reflection = mesh.color_attributes.new(name="Reflector",type="FLOAT_COLOR",domain="POINT")
for vertex, sample in zip(mesh.vertices, reflection.data):
    u = vertex.co.x / lens_radius
    height = (vertex.co.z-.58) / lens_radius
    ridge = .5 + .5*math.cos(math.pi*8*u)
    centre = max(0.0,1-u*u-height*height)
    tone = .25 + .30*ridge + .15*centre
    sample.color = (tone,tone,tone,1)
shader = mesh.materials[0].node_tree
color = shader.nodes.new("ShaderNodeVertexColor")
color.layer_name = reflection.name
shader.links.new(color.outputs["Color"],next(n for n in shader.nodes if n.type=="BSDF_PRINCIPLED").inputs["Base Color"])
lens = bpy.data.objects.new("Headlight lens",mesh)
bpy.context.collection.objects.link(lens)
lens.parent = root
nose_lamp("Horn grille rim",-1.153,.33,.059,.025,v.METAL)
nose_lamp("Horn grille recess",-1.168,.33,.051,.006,v.BLACK)
for index in range(-2,3):
    offset = index*.017
    half_height = math.sqrt(.048**2-offset**2)
    tube("Horn grille rib",(offset,-1.173,.33-half_height),
         (offset,-1.173,.33+half_height),.003,v.METAL)

# The screen bows toward the nose at its centre and narrows under the roof.
def screen_point(u,t):
    return (u*(.418-.026*t),-.43+.33*t+.09*u*u,.916+.603*t-.018*u*u)
screen_columns, screen_rows = 41, 13
verts = [screen_point(2*i/(screen_columns-1)-1,j/(screen_rows-1))
         for j in range(screen_rows) for i in range(screen_columns)]
faces = [(a,a+1,a+1+screen_columns,a+screen_columns)
         for j in range(screen_rows-1) for i in range(screen_columns-1)
         for a in [j*screen_columns+i]]
mesh=bpy.data.meshes.new("Windscreen sheet")
mesh.from_pydata(verts,[],faces)
mesh.materials.append(glass)
screen=bpy.data.objects.new("Wraparound windscreen",mesh)
bpy.context.collection.objects.link(screen)
screen.parent=root
for f in mesh.polygons: f.use_smooth=True
# A continuous rubber channel follows all four edges of the curved acrylic.
edges = ([screen_point(i/20,0) for i in range(-20,20)] +
         [screen_point(1,j/12) for j in range(12)] +
         [screen_point(i/20,1) for i in range(20,-20,-1)] +
         [screen_point(-1,j/12) for j in range(12,0,-1)])
seal_path = [Vector(point) for point in edges]
seal_rings = []
for i, point in enumerate(seal_path):
    tangent = (seal_path[(i+1)%len(seal_path)]-seal_path[i-1]).normalized()
    across = tangent.cross(Vector((0,1,0))).normalized()
    depth = across.cross(tangent).normalized()
    seal_rings.append([point + across*(.013*math.cos(math.tau*j/12)) +
                       depth*(.010*math.sin(math.tau*j/12)) for j in range(12)])
v.profile_loft("Continuous windscreen seal",seal_rings+[seal_rings[0]],v.RUBBER,root,close_ends=False)
roof_sections = [
    (-.138,.365,1.490,1.510,1.540),(-.130,.386,1.489,1.513,1.548),
    (-.110,.404,1.493,1.522,1.554),(.02,.425,1.50,1.55,1.57),
    (.29,.428,1.54,1.57,1.59),(.45,.416,1.568,1.588,1.603),
    (.49,.400,1.577,1.590,1.604),(.502,.383,1.580,1.590,1.601),
]
v.mesh_from_rings("Overhanging canopy",roof_sections,red,root,.006,panel_section)
# An inset finishing strip closes the underside between the molded edges.
roof_trim = [(y,width-.009,bottom-.009,bottom,bottom+.007)
             for y,width,bottom,_,_ in roof_sections]
v.mesh_from_rings("Canopy lower finishing strip",roof_trim,v.DARK,root,.003,panel_section)
for side in (-1,1):
    # Front edge follows the screen. The trailing edge flares into the roof.
    pillar_rings = []
    for t, depth in ((0,.10),(.25,.092),(.58,.087),(.78,.10),(.90,.15),(.97,.24),(1,.31)):
        x,y,z = screen_point(side,t)
        pillar_rings.append([(x+side*dx,y+dy,z+dz) for dx,dy,dz in
                             ((-.012,0,0),(.018,0,0),(.018,depth,.026*t),(-.012,depth,.026*t))])
    faces = [(0,3,2,1)]
    for row in range(len(pillar_rings)-1):
        for corner in range(4):
            a = row*4+corner
            b = row*4+(corner+1)%4
            faces.append((a,b,b+4,a+4))
    faces.append((24,25,26,27))
    pillar_mesh = bpy.data.meshes.new("Moulded screen surround")
    pillar_mesh.from_pydata([point for ring in pillar_rings for point in ring], [],
                            [face if side > 0 else face[::-1] for face in faces])
    pillar_mesh.materials.append(red)
    pillar = bpy.data.objects.new("Swept canopy pillar",pillar_mesh)
    bpy.context.collection.objects.link(pillar)
    pillar.parent = root
    edge = pillar.modifiers.new("Rounded moulding", 'BEVEL')
    edge.width = .007
    edge.segments = 3
    box("Mirror mounting pad",(side*.409,-.421,.919),(.046,.053,.025),v.RUBBER,.008)
    tube("Mirror stem",(side*.415,-.421,.923),(side*.507,-.445,1.057),.008,v.METAL)
    tube("Mirror adjustment joint",(side*.507,-.445,1.048),(side*.507,-.445,1.064),.014,v.DARK)
    # Rounded shells taper toward the front, with the silvered pane inside the rear lip.
    for name, finish, sections in [
        ("Wing mirror shell", v.DARK,
         [(-.478,.036,.024),(-.469,.055,.035),(-.446,.061,.038),
          (-.430,.059,.037),(-.427,.054,.032),(-.432,.049,.028),(-.437,.048,.027)]),
        ("Wing mirror glass", mirror_glass,
         [(-.438,.048,.027),(-.432,.050,.029),(-.430,.046,.026)]),
    ]:
        rings = []
        for y,width,height in sections:
            ring = []
            for i in range(48):
                angle = math.tau*i/48
                x, z = math.cos(angle), math.sin(angle)
                ring.append((side*.513+width*math.copysign(abs(x)**.65,x),
                             y,1.084+height*math.copysign(abs(z)**.65,z)))
            rings.append(ring)
        v.profile_loft(name,rings,finish,root)
    mount = box("Front indicator mounting arm",(side*.343,-1.151,.544),
                (.096,.046,.021),v.DARK,.006)
    mount.rotation_euler.z = side*.23
    box("Front indicator housing",(side*.380,-1.163,.544),(.103,.053,.060),v.DARK,.012)
    box("Front amber indicator",(side*.380,-1.193,.544),(.092,.025,.049),amber,.009)
# Both the arm and rubber blade sit on the outside of the bowed screen.
def wiper_point(u, t):
    return Vector(screen_point(u, t)) + Vector((0, -.018, 0))

pivot = wiper_point(-.58, 1.0)
blade_joint = wiper_point(-.09, .65)
tube("Wiper spindle", screen_point(-.58, 1.0), pivot, .018, v.METAL)
tube("Wiper arm", pivot, blade_joint, .008, v.DARK)
tube("Wiper blade lower", wiper_point(.15, .45), blade_joint, .011, v.BLACK)
tube("Wiper blade upper", blade_joint, wiper_point(-.33, .85), .011, v.BLACK)
# The bonnet, windscreen and roof lift as one shell about the nose.
moving_parts = set(root.children) - fixed_parts
hinge = bpy.data.objects.new("EntryHinge",None)
bpy.context.collection.objects.link(hinge)
hinge.parent = root
hinge.location = (0,-1.13,.44)
for part in moving_parts:
    part.parent = hinge
    part.location -= hinge.location
box("Seat cushion",(0,.18,.595),(.61,.42,.093),vinyl,.044)
# Upholstery sections run from the padded face to the shallow rear shell.
outline = []
for cx, cz, start in ((.235,.19,0),(-.235,.19,90),(-.235,-.19,180),(.235,-.19,270)):
    for step in range(7):
        angle = math.radians(start + step*15)
        x = cx + .065*math.cos(angle)
        z = cz + .065*math.sin(angle)
        outline.append((x*(1-.09*(z+.255)/.51), z))
vertices, faces = [], []
sections = [(.68,-.066),(.90,-.054),(.98,-.034),(1,0),(.96,.033),(.84,.049)]
count = len(outline)
for ring, (scale, depth) in enumerate(sections):
    for i, (x,z) in enumerate(outline):
        vertices.append((x*scale, depth-.012*(x/.30)**2, z*scale))
        if ring:
            prev = (ring-1)*count
            j = (i+1)%count
            faces.append((prev+i,ring*count+i,ring*count+j,prev+j))
faces.extend([tuple(range(count)),tuple(reversed(range(len(vertices)-count,len(vertices))))])
mesh = bpy.data.meshes.new("Padded backrest")
mesh.from_pydata(vertices, [], faces)
mesh.materials.append(vinyl)
back = bpy.data.objects.new("Upright seat back",mesh)
bpy.context.collection.objects.link(back)
back.parent = root
back.location = (0,.407,.85)
back.rotation_euler.x = -.19
for face in mesh.polygons:
    face.use_smooth = True
welt = v.material("Ivory seat piping", (.72,.62,.44), 0,.52)
seam = [Vector((x,-.012*(x/.30)**2,z)) for x,z in outline]
for i, point in enumerate(seam):
    tube("Backrest welt", back.location+back.rotation_euler.to_matrix()@point,
         back.location+back.rotation_euler.to_matrix()@seam[(i+1)%count], .005, welt)
tube("Steering column",(0,-.42,.245),(0,-.13,.85),.022,v.DARK)
tube("Handlebar",(-.25,-.13,.85),(.25,-.13,.85),.017,v.METAL)
for side in (-1,1):
    tube("Handle grip",(side*.18,-.13,.85),(side*.255,-.13,.85),.024,v.BLACK)
# Fixed fibreglass arches leave clearance for the tyres at full steering lock.
for side in (-1, 1):
    vertices = []
    faces = []
    arch_profile = ((.29,.285),(.31,.290),(.47,.291),(.500,.288),
                    (.524,.282),(.539,.272),(.544,.261),(.541,.252),
                    (.534,.249),(.525,.251))
    strips = len(arch_profile)
    for step in range(49):
        angle = math.radians(-12 + step * 204 / 48)
        for x, radius in arch_profile:
            vertices.append((side*x, -.72-radius*math.cos(angle), .227+radius*math.sin(angle)))
        if step:
            for strip in range(strips-1):
                i = (step-1)*strips+strip
                face = (i,i+1,i+strips+1,i+strips)
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
    shell.thickness = .004
    edge = arch.modifiers.new("Rounded cut ends", 'BEVEL')
    edge.width = .002
    edge.segments = 3

def wheel_surface(name, center, profile, material, side=1, *, tread=False):
    segments = 192 if tread else 48
    vertices = []
    faces = []
    for ring, (radius, depth) in enumerate(profile):
        for index in range(segments):
            angle = math.tau*index/segments
            surface_radius = radius
            if tread:
                # Stagger the diagonal shoulder cuts on opposite sides of the tread.
                phase = (index + round(depth*150) + (4 if depth < 0 else 0)) % 8
                if phase == 0 and .027 <= abs(depth) <= .053:
                    surface_radius -= .003 if abs(depth) < .053 else .001
            vertices.append((side*depth,surface_radius*math.cos(angle),
                             surface_radius*math.sin(angle)))
            if ring:
                a = (ring-1)*segments+index
                b = (ring-1)*segments+(index+1)%segments
                face = (a,b,b+segments,a+segments)
                faces.append(face if side > 0 else face[::-1])
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    wheel_part = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(wheel_part)
    wheel_part.parent = root
    wheel_part.location = center
    for polygon in mesh.polygons:
        polygon.use_smooth = True

# Section from the centre of the tread to the bead at the steel rim.
shoulder = [(.227,.005),(.223,.006),(.223,.008),(.227,.009),
            (.226,.021),(.221,.023),(.221,.025),(.225,.027),
            (.223,.039),(.218,.041),(.218,.043),(.222,.045),
            (.218,.053),(.209,.060),(.195,.065),(.177,.069),
            (.153,.068),(.135,.064),(.131,.059)]
rubber_profile = [(r,-d) for r,d in reversed(shoulder)] + shoulder
rim_profile = [(.138,.064),(.138,.075),(.133,.079),(.128,.076),(.124,.070),
               (.115,.068),(.110,.071),(.104,.072),(.086,.070),(.062,.065),
               (.048,.066),(.038,.076),(.030,.079)]
for x,y in ((-.429,-.72),(.429,-.72),(0,.89)):
    wheel_surface("Performance tire",(x,y,.227),rubber_profile,v.RUBBER,tread=True)
    for side in (-1,1):
        wheel_surface("Wheel hub",(x,y,.227),rim_profile,v.METAL,side)
        v.cylinder("Center cap",(x+side*.080,y,.227),.031,.017,v.DARK,True,32,root)
        for i in range(8):
            angle = math.tau*(i+.5)/8
            hub_y, hub_z = y+.094*math.cos(angle), .227+.094*math.sin(angle)
            v.cylinder("Wheel hub vent collar",(x+side*.071,hub_y,hub_z),
                       .013,.005,v.METAL,True,16,root)
            v.cylinder("Wheel hub vent inset",(x+side*.074,hub_y,hub_z),
                       .010,.002,v.DARK,True,16,root)
        for i in range(4):
            angle = math.tau*i/4
            v.cylinder("Wheel bolt",(x+side*.069,y+.049*math.cos(angle),
                       .227+.049*math.sin(angle)),.007,.012,v.METAL,True,6,root)
        tube("Wheel hub valve stem",(x+side*.075,y,.350),
             (x+side*.087,y,.344),.004,v.RUBBER)
        tube("Wheel hub valve cap",(x+side*.085,y,.345),
             (x+side*.092,y,.342),.0045,v.DARK)
# Tapered wire basket on the rear deck.
for z,w,front,rear in ((.55,.30,.53,1.05),(.72,.345,.49,1.12)):
    rear_width = w-.055
    corners=[(-w,front,z),(w,front,z),(rear_width,rear,z),(-rear_width,rear,z)]
    corners = [Vector(point) for point in corners]
    path = []
    for i, corner in enumerate(corners):
        start = corner + (corners[i-1] - corner).normalized() * .075
        end = corner + (corners[(i+1)%4] - corner).normalized() * .075
        for step in range(7):
            t = step / 6
            path.append(start.lerp(corner,t).lerp(corner.lerp(end,t),t))
    curve = bpy.data.curves.new("Bent steel rail", "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = .009
    curve.bevel_resolution = 2
    rim = curve.splines.new("POLY")
    rim.points.add(len(path)-1)
    rim.use_cyclic_u = True
    for point, position in zip(rim.points, path):
        point.co = (*position,1)
    obj = bpy.data.objects.new("Basket rim",curve)
    bpy.context.collection.objects.link(obj)
    obj.parent = root
    curve.materials.append(v.METAL)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target="MESH")
for side in (-1,1):
    for i in range(7):
        t=.14+.72*i/6
        tube("Basket wire",(side*(.30-.055*t),.53+.52*t,.55),(side*(.345-.055*t),.49+.63*t,.72),.005,v.METAL)
# The filler cap sits beside the forward air intake, inside the luggage rail.
v.cylinder("Filler gasket",(.19,.56,.559),.040,.009,v.RUBBER,False,32,root)
v.cylinder("Filler cap",(.19,.56,.577),.035,.030,v.METAL,False,32,root)
for rib in range(12):
    angle = math.tau * rib / 12
    x = .19 + .035*math.cos(angle)
    y = .56 + .035*math.sin(angle)
    tube("Cap grip",(x,y,.568),(x,y,.585),.0025,v.METAL)
# The deck itself forms the basket floor, leaving the two air intakes visible.
for y, z in ((.53,.559),(.78,.549)):
    v.cylinder("Deck vent bezel",(0,y,z),.094,.012,v.METAL,False,40,root)
    v.cylinder("Deck vent recess",(0,y,z+.008),.085,.009,v.BLACK,False,40,root)
    for row in range(-5,6):
        offset = row*.015
        chord = math.sqrt(.084**2-offset**2)
        tube("Deck grille wire",(offset,y-chord,z+.014),(offset,y+chord,z+.014),.002,v.METAL)
        tube("Deck grille wire",(-chord,y+offset,z+.016),(chord,y+offset,z+.016),.002,v.METAL)
for side in (-1,1):
    tube("Grab handle mount",(side*.14,1.115,.52),(side*.13,1.155,.595),.014,v.BLACK)
tube("Rear grab handle",(-.13,1.155,.595),(.13,1.155,.595),.016,v.BLACK)
# The rear side panels taper inward. Seat the engine vents flush on that slope.
for side in (-1, 1):
    vent_y = .65
    slope = (.425 - .385) / (.78 - .42)
    for name, offset, size, finish in (
        ("Service vent surround", .004, (.018,.35,.145), v.METAL),
        ("Recess behind cooling slots", .013, (.014,.326,.124), v.BLACK),
    ):
        panel = box(name, (side*(.40+offset), vent_y, .387), size, finish, .007)
        panel.rotation_euler.z = side*math.atan(slope)
    # All wires share one mesh per panel to keep the grille cheap to draw.
    wires = bpy.data.curves.new("Square wire grille", 'CURVE')
    wires.dimensions = '3D'
    wires.bevel_depth = .0013
    wires.bevel_resolution = 0
    wires.materials.append(v.METAL)
    for vertical, count in ((True,13),(False,5)):
        for index in range(-count,count+1):
            offset = index*.012
            spline = wires.splines.new('POLY')
            spline.points.add(1)
            for point, end in zip(spline.points,(-1,1)):
                u,h = (offset,end*.060) if vertical else (end*.158,offset)
                point.co = (side*(.422-u*slope),vent_y+u,.387+h,1)
    grille = bpy.data.objects.new("Engine intake wire mesh",wires)
    bpy.context.collection.objects.link(grille)
    grille.parent = root
    bpy.context.view_layer.objects.active = grille
    bpy.ops.object.select_all(action='DESELECT')
    grille.select_set(True)
    bpy.ops.object.convert(target='MESH')
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
box("Tail lamp gasket",(0,1.158,.43),(.161,.020,.077),v.RUBBER,.013)
box("Tail lamp housing",(0,1.173,.43),(.153,.024,.069),v.DARK,.012)
# Mold the vertical prisms into the red lens so they light with the whole optic.
tail_lens_sections = []
for i in range(49):
    u = i/24-1
    half_height = .028 - .009*max(0,(abs(u)-.78)/.22)**2
    ridge = .0015*(1-math.cos(math.tau*i/4))*(1-u*u)
    tail_lens_sections.append([(u*.070,y,.43+h*half_height) for y,h in (
        (1.182,-.87),(1.186,-1),(1.195,-.84),(1.198+ridge,-.66),
        (1.201+ridge,0),(1.198+ridge,.66),(1.195,.84),(1.186,1),(1.182,.87),
    )])
v.profile_loft("Tail lamp fluted lens",tail_lens_sections,v.TAIL_LAMP,root)
for side in (-1,1):
    box("Rear indicator housing",(side*.237,1.157,.423),(.099,.037,.057),v.DARK,.009)
    box("Rear indicator lens",(side*.237,1.18,.423),(.088,.018,.047),amber,.008)
badge = v.text_obj("Norrsjö Shoppa rear badge", "NORRSJÖ SHOPPA",
                   (0,1.163,.476), .026, v.METAL, root=root)
badge.rotation_euler = (math.pi/2,0,math.pi)
badge.location.x = (min(vertex.co.x for vertex in badge.data.vertices) +
                    max(vertex.co.x for vertex in badge.data.vertices)) / 2
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
