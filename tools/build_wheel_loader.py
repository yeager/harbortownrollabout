"""Build a Volvo L90-style articulated loader. Run inside Blender from this repository."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v

v.clear_scene()
bpy.context.preferences.filepaths.save_version = 0
yellow = v.material("Volvo construction yellow", (.99, .56, .012), .22, .31)
charcoal = v.material("Cast charcoal steel", (.067, .08, .081), .6, .36)
rubber = v.material("Quarry tire rubber", (.024, .028, .029), 0, .92)
tread = v.material("Raised tire lugs", (.042, .047, .046), 0, .84)
steel = v.material("Bucket gunmetal", (.12, .14, .145), .67, .42)
edge = v.material("Polished cutting edge", (.43, .46, .45), .83, .32)
chrome = v.material("Hydraulic piston chrome", (.69, .75, .77), .94, .19)
amber = v.material("Amber beacon lens", (1, .28, .015), .16, .24, .5)
glass = v.material("Lightly tinted cab glazing", (.29, .49, .54), .15, .14)
next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .34
glass.diffuse_color = (.29, .49, .54, .34)
glass.surface_render_method = "DITHERED"


def pivot(name, point, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.location = point
    bpy.context.view_layer.update()
    if parent:
        v.attach(obj, parent)
    bpy.context.view_layer.update()
    return obj


root = pivot("VolvoWheelLoader", (0, 0, 0))
rear = pivot("RearFrame", (0, 0, 0), root)
front = pivot("Articulation", (0, -.18, 1.04), root)
lift = pivot("LiftArms", (0, -.85, 1.84), front)
bucket = pivot("Bucket", (0, -3.18, .53), lift)


def box(name, point, dimensions, finish, parent, bevel=.025):
    return v.cube(name, point, dimensions, finish, bevel, parent)


def pin(name, point, radius, depth, finish, parent, axis_x=True):
    return v.cylinder(name, point, radius, depth, finish, axis_x, 24, parent)


def rod(name, start, end, radius, finish, parent):
    a, b = Vector(start), Vector(end)
    obj = pin(name, (a+b)/2, radius, (b-a).length, finish, parent, False)
    obj.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    return obj


def profile(name, yz, x1, x2, finish, parent, bevel=.025):
    rings = [[(x, y, z) for y, z in yz] for x in (x1, x2)]
    obj = v.profile_loft(name, rings, finish, parent)
    obj.matrix_parent_inverse = parent.matrix_world.inverted()
    for face in obj.data.polygons:
        face.use_smooth = False
    mod = obj.modifiers.new("Rounded plate edges", "BEVEL")
    mod.width, mod.segments = bevel, 2
    obj.modifiers.new("Panel normals", "WEIGHTED_NORMAL")
    return obj


def pane(name, points, parent):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(points, [], [tuple(range(len(points)))])
    mesh.materials.append(glass)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    v.attach(obj, parent)


def tube(name, points, radius, finish, parent):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions, curve.resolution_u = '3D', 8
    curve.bevel_depth, curve.bevel_resolution = radius, 2
    spline = curve.splines.new('POLY')
    spline.points.add(len(points)-1)
    for point, coords in zip(spline.points, points):
        point.co = (*coords, 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    curve.materials.append(finish)
    v.attach(obj, parent)


# The waist remains open between two heavy independently steerable frames.
profile("Cast rear counterweight", [(.1,.83),(.7,.55),(2.60,.59),(2.99,.80),
        (3.02,1.46),(2.81,1.69),(.25,1.58)], -.9,.9,yellow,rear,.10)
profile("Sloped engine bonnet", [(.93,1.32),(2.94,1.32),(2.93,1.80),
        (2.73,2.04),(1.55,2.19),(1.12,2.18)], -.84,.84,yellow,rear,.08)
box("Rear radiator grille", (0,3.035,1.56),(1.50,.07,.50),charcoal,rear)
for i in range(8):
    box("Radiator transverse bar",(0,3.078,1.36+i*.061),
        (1.41,.026,.018),v.DARK,rear,.006)
rod("Diagonal grille brightwork",(.61,3.099,1.37),(-.61,3.099,1.76),.016,chrome,rear)
bpy.ops.mesh.primitive_torus_add(location=(0,3.121,1.565),rotation=(math.pi/2,0,0),
                                major_radius=.105,minor_radius=.013,major_segments=32,minor_segments=8)
emblem=bpy.context.object
emblem.name="Radiator emblem ring"
emblem.data.materials.append(chrome)
v.attach(emblem,rear)
box("Emblem centre bar",(0,3.136,1.565),(.216,.024,.045),chrome,rear,.008)
box("Rear bumper rub rail",(0,3.01,.90),(1.87,.13,.16),charcoal,rear)
for side in (-1,1):
    x=side*.857
    profile("Cooling louvre panel",[(1.42,1.84),(2.64,1.73),(2.69,1.90),(1.54,2.07)],
            x,x+side*.034,charcoal,rear,.012)
    for i in range(9):
        y=1.60+.112*i
        rod("Angled intake fin",(x+side*.041,y,1.88-.08*i/9),
            (x+side*.041,y+.049,2.01-.095*i/9),.014,v.DARK,rear)
    box("Rear combination lamp",(side*.72,2.956,1.79),(.22,.051,.10),v.TAIL_LAMP,rear)
    obj=v.text_obj("Model sign","L90", (side*.892,2.58 if side<0 else 2.19,1.53),
                   .15,charcoal,side=-side,root=rear)

box("Cab platform", (0,.46,1.53),(1.71,1.50,.23),charcoal,rear,.08)
profile("Central oscillating frame",[(-2.43,.75),(-1.94,.55),(-.41,.78),
        (-.12,1.00),(-.49,1.39),(-1.09,1.46),(-2.39,1.11)],-.47,.47,yellow,front,.06)
pin("Waist pivot",(0,-.18,1.06),.24,.51,charcoal,front,False)
for side in (-1,1):
    rod("Steering jack",(side*.63,.42,.87),(side*.65,-.57,.91),.09,charcoal,rear)
    rod("Steering piston",(side*.65,-.51,.91),(side*.66,-1.02,.92),.052,chrome,front)
    for step in range(3):
        box("Cab access tread",(side*(.85+.07*(2-step)),.25,.58+.27*step),
            (.30,.59,.075),charcoal,rear,.012)
    tube("Boarding handrail",[(side*.98,.63,1.16),(side*.99,.68,2.04),
         (side*.92,.72,2.16),(side*.69,.72,2.16)],.026,yellow,rear)


# Single tire carcass with a ring of opposing chevron bars. The lugs share one mesh per wheel.
def wheel(x,y,frame,label):
    z=.85
    center=pivot("Wheel_"+label,(x,y,z),frame)
    half_width=.275
    rings=[]
    for width,radius in [(-.26,.43),(-.295,.55),(-.29,.70),(-.25,.77),
                         (-.15,.80),(.15,.80),(.25,.77),(.29,.70),(.295,.55),(.26,.43)]:
        rings.append([(x+width,y+radius*math.cos(a*math.tau/48),z+radius*math.sin(a*math.tau/48)) for a in range(48)])
    obj=v.profile_loft("Rounded tire casing",rings+[rings[0]],rubber,center,False)
    obj.matrix_parent_inverse=center.matrix_world.inverted()
    vertices,faces=[],[]
    for i in range(23):
        for direction in (-1,1):
            angle=math.tau*(i+.18*(direction>0))/23
            offset=len(vertices)
            for r in (.765,.85):
                for width, shift in [( .008,-.057),(.265,.013),(.265,.10),(.008,.043)]:
                    a=angle+shift
                    radius=r-.041*(width/half_width)**2
                    vertices.append((x+direction*width,y+radius*math.cos(a),z+radius*math.sin(a)))
            faces.extend([tuple(offset+n for n in ids) for ids in [(0,1,2,3),(4,7,6,5),
                           (0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]])
    mesh=bpy.data.meshes.new("Chevron lugs")
    mesh.from_pydata(vertices,[],faces)
    import bmesh
    bm=bmesh.new(); bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bm.to_mesh(mesh); bm.free()
    obj=bpy.data.objects.new("Deep quarry tread",mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(tread)
    v.attach(obj,center)
    s=1 if x>0 else -1
    pin("Yellow wheel rim",(x,y,z),.463,.53,yellow,center)
    pin("Recessed hub dish",(x+s*.269,y,z),.362,.036,charcoal,center)
    pin("Planetary final drive",(x+s*.303,y,z),.282,.098,yellow,center)
    for i in range(8):
        a=i*math.tau/8
        v.cylinder("Lug nut",(x+s*.359,y+.202*math.cos(a),z+.202*math.sin(a)),
                   .028,.035,charcoal,True,6,center)


for y,frame,end in [(-1.66,front,"Front"),(1.64,rear,"Rear")]:
    for side in (-1,1):
        wheel(side*1.045,y,frame,end+("Left" if side<0 else "Right"))
        rings=[]
        for i in range(27):
            a=math.radians(24+i*132/26)
            rings.append([(side*x,y+r*math.cos(a),.85+r*math.sin(a))
                          for x,r in [(.76,.897),(1.375,.897),(1.375,.944),(.76,.944)]])
        obj=v.profile_loft("Curved wheel guard",rings,charcoal,frame)
        obj.matrix_parent_inverse=frame.matrix_world.inverted()

# Panoramic glass cab, with the ROPS pillars and working compartment modeled inside.
cab_yz=[(-.37,1.69),(-.59,3.12),(-.43,3.30),(.93,3.30),(1.12,3.09),(1.05,1.69)]
for side in (-1,1):
    x=side*.68
    pane("Glazed cab door",[(x,y,z) for y,z in cab_yz],rear)
    tube("ROPS door frame",[(x,y,z) for y,z in cab_yz+[cab_yz[0]]],.049,charcoal,rear)
    rod("Door window division",(x,.60,1.71),(x,.60,3.28),.028,charcoal,rear)
    box("Door handle",(x+side*.032,.56,2.23),(.04,.15,.033),v.BLACK,rear,.012)
    tube("Mirror mount",[(x,-.38,2.94),(side*.94,-.42,3.0),(side*1.04,-.43,2.92)],.028,charcoal,rear)
    box("Rearview mirror",(side*1.04,-.43,2.83),(.13,.085,.22),v.BLACK,rear)
for name,lower,upper in [("Windscreen",cab_yz[0],cab_yz[1]),("Rear glass",cab_yz[-1],cab_yz[-2])]:
    pane(name,[(-.67,*lower),(.67,*lower),(.67,*upper),(-.67,*upper)],rear)
    rod("Glazing lower seal",(-.68,*lower),(.68,*lower),.037,charcoal,rear)
box("Cab roof",(0,.22,3.31),(1.57,1.75,.13),charcoal,rear,.065)
box("Yellow roof crown",(0,.22,3.38),(1.48,1.60,.055),yellow,rear,.025)
box("Operator seat cushion",(0,.43,2.02),(.49,.48,.12),v.BLACK,rear,.055)
seat=box("Operator seat back",(0,.62,2.31),(.49,.12,.53),v.DARK,rear,.055)
seat.rotation_euler.x=-.12
rod("Steering column",(0,-.16,1.71),(0,-.13,2.19),.046,charcoal,rear)
bpy.ops.mesh.primitive_torus_add(major_radius=.18,minor_radius=.019,location=(0,-.13,2.19),rotation=(.45,0,0))
steering=bpy.context.object; steering.name="Steering wheel"; steering.data.materials.append(v.BLACK);v.attach(steering,rear)
for side in (-1,1):
    box("Roof work light housing",(side*.55,-.62,3.20),(.25,.13,.16),v.BLACK,rear)
    box("Roof work light lens",(side*.55,-.69,3.20),(.205,.029,.11),v.HEADLAMP,rear)
pin("Beacon plinth",(-.47,.72,3.43),.116,.09,charcoal,rear,False)
pin("Amber beacon",(-.47,.72,3.56),.096,.19,amber,rear,False)
pin("Exhaust heat shield",(.60,1.45,2.47),.102,.77,charcoal,rear,False)
rod("Turned exhaust outlet",(.60,1.45,2.79),(.60,1.49,3.03),.067,v.BLACK,rear)

# Twin dogleg boom plates, exposed polished rams and Z-bar tilt linkage.
arm_outline=[(-.78,1.68),(-.79,1.96),(-1.57,2.01),(-2.19,1.64),(-2.80,.99),
             (-3.32,.66),(-3.28,.43),(-3.09,.37),(-2.48,.86),(-1.89,1.43),(-1.43,1.65)]
for side in (-1,1):
    x=side*.55
    profile("Forged lift arm",arm_outline,x-.085,x+.085,charcoal,lift,.045)
    for y,z,r in [(-.85,1.84,.155),(-1.92,1.56,.115),(-3.18,.53,.122)]:
        pin("Boom bearing",(x,y,z),r,.23,steel,lift)
        pin("Pivot cap",(x+side*.129,y,z),r*.59,.044,yellow,lift)
    rod("Lift ram barrel",(side*.39,-.79,.99),(side*.46,-1.48,1.37),.105,charcoal,front)
    rod("Lift piston",(side*.46,-1.46,1.36),(side*.51,-1.92,1.56),.060,chrome,lift)
    tube("Hydraulic hose",[(x,-.76,1.76),(x,-1.01,2.03),(x,-1.48,2.06),(x,-1.92,1.84)],.022,v.BLACK,lift)
# Painted manufacturer lettering follows the shoulder of the boom on both sides.
from mathutils import Matrix
for side in (-1,1):
    label=v.text_obj("Volvo boom marking","VOLVO",
        (side*.64, -2.03 if side>0 else -1.62, 1.54 if side>0 else 1.78),
        .126,v.PAINT_WHITE,side=-side,root=lift)
    label.rotation_euler=(Matrix.Rotation(.48,3,'X') @ label.rotation_euler.to_matrix()).to_euler()
rod("Boom torque tube",(-.55,-2.15,1.53),(.55,-2.15,1.53),.12,charcoal,lift)
profile("Z-bar bell crank",[(-2.30,1.18),(-2.29,1.77),(-2.12,2.01),(-1.98,1.94),(-2.09,1.55),(-2.07,1.17)],
        -.094,.094,steel,lift)
rod("Tilt ram barrel",(0,-.77,1.94),(0,-1.62,1.94),.134,charcoal,lift)
rod("Tilt piston",(0,-1.61,1.94),(0,-2.07,1.94),.084,chrome,lift)
rod("Bucket tip link",(0,-2.20,1.23),(0,-3.28,1.04),.078,steel,lift)

# The rolled shell is a C-shaped extruded section; each cheek closes only the sides.
shell=[(-3.37,1.32),(-3.16,1.16),(-3.07,.88),(-3.08,.59),(-3.22,.35),
       (-3.47,.18),(-3.81,.113),(-4.44,.085),(-4.58,.13),(-4.40,.18),
       (-3.80,.22),(-3.53,.28),(-3.31,.43),(-3.19,.64),(-3.18,.87),(-3.26,1.11),(-3.44,1.24)]
profile("Rolled bucket shell",shell,-1.45,1.45,steel,bucket,.024)
cheek=[(-3.40,1.34),(-3.14,1.16),(-3.05,.89),(-3.07,.57),(-3.24,.31),(-3.65,.14),(-4.51,.09),
       (-4.46,.21),(-4.08,.53),(-3.85,.93)]
for side in (-1,1):
    profile("Bucket cheek",cheek,side*1.42,side*1.48,steel,bucket,.020)
profile("Hardened cutting edge",[(-4.58,.083),(-4.34,.093),(-4.29,.17),(-4.51,.16)],
        -1.49,1.49,edge,bucket,.009)
for i in range(7):
    x=(i-3)*.415
    profile("Replaceable digging tooth",[(-4.42,.085),(-4.69,.065),(-4.75,.086),(-4.53,.18),(-4.40,.19)],
            x-.075,x+.075,edge,bucket,.012)

v.export_vehicle(root,"volvo_wheel_loader.glb")
# Camera and lighting stay in the editable studio file and out of the game mesh.
scene=bpy.context.scene
target=Vector((0,-.72,1.45))
bpy.ops.object.camera_add(location=(8.5,-7.4,5.15))
camera=bpy.context.object
camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=9.6
scene.camera=camera
for position,power,size in [((3,-4,8),1300,6),((-4,-1,5),800,5),((1,5,7),1200,4)]:
    bpy.ops.object.light_add(type='AREA',location=position)
    lamp=bpy.context.object; lamp.data.energy=power; lamp.data.shape='DISK'; lamp.data.size=size
    lamp.rotation_euler=(target-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.015))
ground=bpy.context.object
ground.name="Studio ground (render only)"
ground.data.materials.append(v.material("Studio floor",(.16,.18,.19),0,.85))
ground.hide_set(True)
scene.world.color=(.25,.25,.25)
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_percentage=100
scene.render.resolution_x,scene.render.resolution_y=1000,670
scene.render.filepath="//../docs/volvo-wheel-loader.png"
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        view=area.spaces.active
        view.region_3d.view_rotation=camera.rotation_euler.to_quaternion()
        view.region_3d.view_location=target;view.region_3d.view_distance=10
        view.overlay.show_overlays=False;view.shading.color_type='MATERIAL'
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True);bpy.context.view_layer.objects.active=root
bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR)/"VolvoWheelLoader.blend"))
bpy.ops.render.render(write_still=True)
