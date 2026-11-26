"""Build three stylized Swedish emergency vehicles in Blender and export GLB assets."""
import bpy
import math
import os
from mathutils import Vector

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT_DIR, "vehicles")
SOURCE_DIR = os.path.join(ROOT_DIR, "source_blender")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(SOURCE_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)

def material(name, color, metallic=0.0, roughness=0.48, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf is None:
        nodes.clear()
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        output = nodes.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat

PAINT_WHITE = material("Warm ceramic white", (0.89, 0.91, 0.87), 0.28, 0.27)
PAINT_RED = material("Rescue red enamel", (0.72, 0.035, 0.028), 0.22, 0.3)
PAINT_NAVY = material("Police midnight blue", (0.035, 0.105, 0.17), 0.3, 0.28)
PAINT_YELLOW = material("High visibility yellow", (0.91, 0.71, 0.035), 0.12, 0.38)
PAINT_LIME = material("Ambulance fluorescent yellow", (0.78, 0.91, 0.025), 0.08, 0.35)
PAINT_GREEN = material("Ambulance reflective green", (0.012, 0.18, 0.10), 0.06, 0.34)
POLICE_BLUE = material("Police reflective blue", (0.025, 0.19, 0.55), 0.12, 0.32)
GLASS = material("Blue grey safety glass", (0.10, 0.23, 0.29), 0.18, 0.19)
GLASS_HI = material("Glass reflection", (0.42, 0.63, 0.66), 0.12, 0.23)
RUBBER = material("Tire rubber", (0.025, 0.032, 0.034), 0.02, 0.87)
TREAD = material("Tire sidewall", (0.08, 0.095, 0.094), 0.02, 0.72)
METAL = material("Brushed equipment metal", (0.55, 0.61, 0.6), 0.75, 0.27)
DARK = material("Graphite trim", (0.075, 0.095, 0.09), 0.34, 0.35)
BLUE_LAMP = material("Emergency blue lens", (0.015, 0.22, 0.95), 0.05, 0.2, 1.2)
RED_LAMP = material("Emergency red lens", (0.92, 0.025, 0.018), 0.02, 0.2, 1.1)
HEADLAMP = material("LED headlamp", (0.95, 0.84, 0.56), 0.05, 0.15, 0.45)
TAIL_LAMP = material("Tail lamp", (0.75, 0.025, 0.015), 0.05, 0.2, 0.2)
BLACK = material("Lettering black", (0.025, 0.045, 0.05), 0.1, 0.35)
HOSE = material("Fire hose", (0.82, 0.72, 0.45), 0.0, 0.62)
PAINT_BLACK = material("BMW gloss black", (0.012, 0.017, 0.022), 0.48, 0.2)
PAINT_SILVER = material("Traffic car silver", (0.53, 0.59, 0.61), 0.68, 0.24)
PAINT_BLUE_CAR = material("Traffic car deep blue", (0.025, 0.11, 0.32), 0.56, 0.24)

def attach(obj, root):
    obj.parent = root
    obj.matrix_parent_inverse = root.matrix_world.inverted()
    return obj

def cube(name, loc, dims, mat, bevel=0.06, root=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Soft manufactured edges", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
        normal = obj.modifiers.new("Weighted highlights", "WEIGHTED_NORMAL")
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.ops.object.modifier_apply(modifier=normal.name)
    if root:
        attach(obj, root)
    return obj

def cylinder(name, loc, radius, depth, mat, axis_x=True, vertices=32, root=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    if axis_x:
        obj.rotation_euler[1] = math.pi / 2
    if mat:
        obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    bevel = obj.modifiers.new("Machined edge", "BEVEL")
    bevel.width = min(depth * 0.12, radius * 0.08)
    bevel.segments = 2
    obj.modifiers.new("Weighted highlights", "WEIGHTED_NORMAL")
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.ops.object.modifier_apply(modifier="Weighted highlights")
    if root:
        attach(obj, root)
    return obj

def mesh_from_rings(name, rings, mat, root=None, bevel=0.035, section=None):
    """Build a smooth longitudinal body from measured cross sections (Y is length)."""
    vertices = []
    for y, half_width, bottom, shoulder, crown in rings:
        if section:
            vertices.extend(section(y, half_width, bottom, shoulder, crown))
            continue
        # Rounded shoulders and roof create a real car-like cross section instead of a box.
        vertices.extend([
            (-half_width * 0.88, y, bottom), (-half_width, y, bottom + 0.12),
            (-half_width, y, shoulder - 0.16), (-half_width * 0.93, y, shoulder),
            (-half_width * 0.72, y, crown), (0, y, crown + 0.035),
            (half_width * 0.72, y, crown), (half_width * 0.93, y, shoulder),
            (half_width, y, shoulder - 0.16), (half_width, y, bottom + 0.12),
            (half_width * 0.88, y, bottom),
        ])
    faces = []
    n = len(vertices) // len(rings)
    faces.append(tuple(range(n)))
    for row in range(len(rings) - 1):
        for col in range(n):
            a = row * n + col
            b = row * n + (col + 1) % n
            faces.append((a, a + n, b + n, b))
    faces.append(tuple((len(rings) - 1) * n + i for i in reversed(range(n))))
    mesh = bpy.data.meshes.new(name + " precision surface")
    mesh.from_pydata(vertices, [], faces)
    import bmesh
    # Recalculate the surface normals as a single closed shell before smoothing.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    if bevel:
        mod = obj.modifiers.new("Controlled body edge highlights", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
        obj.modifiers.new("Body highlight normals", "WEIGHTED_NORMAL")
    if root:
        attach(obj, root)
    return obj

def text_obj(name, body, loc, size, mat, side=0, root=None, *, flat=False):
    curve = bpy.data.curves.new(name, "FONT")
    curve.body = body
    curve.size = size
    if flat:
        curve.resolution_u = 5
        curve.fill_mode = 'FRONT'
    else:
        curve.extrude = 0.002
        curve.bevel_depth = 0.001
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    # Text baseline runs along the vehicle, with the glyphs upright on its sides.
    obj.rotation_euler = (math.pi / 2, 0, math.pi / 2 if side < 0 else -math.pi / 2)
    if mat:
        obj.data.materials.append(mat)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    if root:
        attach(obj, root)
    return obj

def pumper_running_gear(root,chassis):
    wheel_finish = material("Silver grey wheel enamel", (.43,.45,.46), .33, .48)
    stud_finish = material("Zinc plated fasteners", (.32,.33,.32), .72, .38)
    for y in (-2.05,1.65):
        bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=.562,depth=3.0,
            location=(0,y,.51),rotation=(0,math.pi/2,0))
        cutter=bpy.context.object
        cut=chassis.modifiers.new("Wheel well","BOOLEAN")
        cut.object=cutter
        cut.operation="DIFFERENCE"
        bpy.context.view_layer.objects.active=chassis
        bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
        recess = .105 if y > 0 else 0.0
        for side in (-1,1):
            def rings(profile):
                return [[(side*d,y+r*math.cos(i*math.tau/64),.51+r*math.sin(i*math.tau/64))
                         for i in range(64)] for d,r in profile]
            tire=[(.985,.30),(.970,.393),(.984,.466),(1.012,.502),
                  (1.041,.51),(1.078,.51),(1.084,.499),(1.091,.51),
                  (1.174,.51),(1.181,.499),(1.188,.51),(1.225,.51),
                  (1.25,.495),(1.278,.451),(1.291,.389),(1.283,.303)]
            profile_loft("All terrain tire",rings(tire+[tire[0]]),RUBBER,root,close_ends=False)
            lip = [(1.232,.308),(1.287,.309),(1.296,.298)]
            if recess:
                lip.extend([(1.275,.293),(1.229,.291),(1.189,.287)])
            lip.append((1.278-recess,.277))
            profile_loft("Alloy wheel rim",rings(lip),wheel_finish,root,close_ends=False)
            # Stamp each vent into a sector of the dished steel centre.
            vertices,faces=[],[]
            for i in range(8):
                center_angle=math.tau*(i+.5)/8
                base=len(vertices)
                for layer in range(3):
                    for j in range(32):
                        a=math.tau*j/32
                        u,v=math.cos(a),math.sin(a)
                        if layer==0:
                            edge=max(abs(u),abs(v))
                            angle=center_angle+(math.pi/8)*u/edge
                            r=.214+.063*v/edge
                            depth=1.278-.026*math.sin(math.pi*(r-.151)/.126)
                        else:
                            angle=center_angle+(.192 if layer==1 else .169)*u
                            r=.220+(.036 if layer==1 else .032)*v
                            depth=1.255 if layer==1 else 1.237
                        vertices.append((side*(depth-recess),y+r*math.cos(angle),.51+r*math.sin(angle)))
                for row in [base,base+32]:
                    for j in range(32):
                        k=(j+1)%32
                        face=(row+j,row+k,row+32+k,row+32+j)
                        faces.append(face if side<0 else face[::-1])
            mesh=bpy.data.meshes.new("Pierced steel centre")
            mesh.from_pydata(vertices,[],faces)
            mesh.materials.append(wheel_finish)
            for face in mesh.polygons: face.use_smooth=True
            dish=bpy.data.objects.new("Alloy wheel ventilated dish",mesh)
            bpy.context.collection.objects.link(dish)
            dish.parent=root
            cylinder("Brake disc",(side*(1.205-recess),y,.51),.268,.028,DARK,root=root)
            profile_loft("Alloy wheel bolt flange",rings([(1.278-recess,.151),(1.285-recess,.095)]),wheel_finish,root)
            if y < 0:
                profile_loft("Front axle hub cover",rings([(1.283,.105),(1.309,.106),
                    (1.337,.092),(1.345,.066),(1.346,.025)]),wheel_finish,root)
            else:
                cylinder("Center cap",(side*(1.296-recess),y,.51),.105,.082,DARK,root=root)
            for i in range(10):
                angle=math.tau*i/10
                cylinder("Wheel bolt",(side*(1.292-recess),y+.139*math.cos(angle),.51+.139*math.sin(angle)),
                         .018,.034,stud_finish,vertices=6,root=root)
            arch=[]
            for i in range(41):
                angle=.075+(math.pi-.15)*i/40
                arch.append([(side*d,y+r*math.cos(angle),.51+r*math.sin(angle))
                             for d,r in ((1.02,.549),(1.268,.549),(1.291,.556),
                                         (1.295,.573),(1.28,.588),(1.15,.600),(1.02,.583))])
            profile_loft("Wheel arch moulding",arch,DARK,root)
            cube("Mud flap",(side*1.14,y+.564,.421),(.259,.026,.25),RUBBER,.011,root)

def lights(root, center_y=-0.85, z=2.68, length=1.15):
    cube("Roof light bar housing", (0, center_y, z), (length, 0.16, 0.19), DARK, 0.055, root)
    for x, name, mat in ((-length * 0.31, "FlashBlue_Left", BLUE_LAMP), (length * 0.31, "FlashRed_Right", BLUE_LAMP)):
        cube(name, (x, center_y - 0.01, z + 0.035), (length * 0.29, 0.19, 0.15), mat, 0.055, root)
    for x in (-0.47, 0.47):
        cube("Forward scene light", (x, center_y - 0.025, z + 0.09), (0.12, 0.06, 0.17), HEADLAMP, 0.035, root)

def markings(root, text, color=BLACK, z=1.4, y=0.1, side_offset=1.1, size=0.27):
    for side in (-1, 1):
        text_obj("Side identity", text, (side * side_offset, y, z), size, color, side, root)

def make_ambulance():
    root = bpy.data.objects.new("Ambulans | Pickup 9310", None)
    bpy.context.collection.objects.link(root)
    yellow = material("Ambulans citrongul", (0.47, 0.55, 0.068), 0.06, 0.34)
    glass = material("Röktonat glas", (0.018, 0.042, 0.056), 0.36, 0.13)
    mirror_glass = material("Ambulance mirror glass",(.42,.51,.56),.88,.14)

    def box(name, loc, dims, mat, radius=0.025):
        return cube(name, loc, dims, mat, radius, root)

    def wheel_cut(shell, y):
        bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.54, depth=3,
            location=(0, y, 0.47), rotation=(0, math.pi / 2, 0))
        cutter = bpy.context.object
        modifier = shell.modifiers.new("Hjulhus", "BOOLEAN")
        modifier.object = cutter
        modifier.operation = "DIFFERENCE"
        bpy.context.view_layer.objects.active = shell
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.data.objects.remove(cutter, do_unlink=True)

    box("Ram", (0,0,0.6), (1.45,5.9,0.19), BLACK)
    nose = mesh_from_rings("Huv och dörrplåt", [
        (-3.18,.84,.59,1.15,1.25), (-3.07,.98,.53,1.30,1.36),
        (-2.65,1.01,.50,1.35,1.40), (-1.97,1.02,.50,1.37,1.42),
        (-.28,1.01,.50,1.40,1.44)], yellow, root)
    wheel_cut(nose,-2.05)
    # The sloped windscreen and the front door glass share a narrow painted
    # A-pillar. Each belt follows the same aperture around both cab corners.
    vertices,faces,slots=[],[],[]
    for t in (0,.065,.12,.85,.92,1):
        front=-2.02+.73*t
        rear=-.29-.12*t
        half=.973-.112*t
        perimeter=[(0,front-.052),(.84*half,front),(.95*half,front+.038),
                   (half,front+.115),(half,rear-.13),(half*.98,rear),
                   (-half*.98,rear),(-half,rear-.13),(-half,front+.115),
                   (-.95*half,front+.038),(-.84*half,front)]
        base=len(vertices)
        for x,y in perimeter:
            z=1.405+.711*t+.033*(1-(x/half)**2)*t
            vertices.append((x,y,z))
        n=len(perimeter)
        if base:
            for k in range(n):
                q=(k+1)%n
                faces.append((base-n+k,base-n+q,base+q,base+k))
                slots.append(int(.12<t<=.92 and k in (0,1,3,7,9,10)))
    faces.append(tuple(range(len(vertices)-n,len(vertices))))
    slots.append(0)
    mesh=bpy.data.meshes.new("Hyttens glas och stolpar")
    mesh.from_pydata(vertices,[],faces)
    for finish in (yellow,glass):
        mesh.materials.append(finish)
    mesh.polygons.foreach_set("material_index",slots)
    cabin=bpy.data.objects.new("Förarhytt",mesh)
    bpy.context.collection.objects.link(cabin)
    cabin.parent=root
    # Raised modules are visible above the box body from the chase camera.
    for y in (.06, 2.77):
        for side in (-1, 1):
            x = .75*side
            box("Beacon mounting foot", (x,y,2.624), (.40,.21,.075), RUBBER, .024)
            box("Cobalt polycarbonate casing", (x,y,2.712), (.46,.24,.145), POLICE_BLUE,.045)
            phase = "FlashBlue" if side < 0 else "FlashRed"
            box(phase+"_RoofBeacon", (x,y,2.735), (.47,.25,.124), BLUE_LAMP,.040)
    # The module fairing projects over the roof at the front of the box.
    fairing=[]
    for y,w,base,top in ((-1.27,.76,2.164,2.183),(-1.18,.88,2.148,2.29),
                         (-.98,.95,2.14,2.445),(-.68,1.018,2.136,2.547),
                         (-.37,1.06,2.132,2.587),(-.212,1.077,2.13,2.598)):
        fairing.append([(x*w,y,base+(top-base)*h) for x,h in
                        ((-.90,0),(-1,.18),(-.99,.68),(-.91,.94),
                         (-.66,1),(.66,1),(.91,.94),(.99,.68),(1,.18),(.90,0))])
    profile_loft("Vårdmodulens taköverhäng",fairing,yellow,root)
    def rear_outline(x,y,z,width,height,radius):
        outline = []
        for sx,sz,start in ((1,1,0),(-1,1,90),(-1,-1,180),(1,-1,270)):
            for k in range(7):
                ang = math.radians(start+15*k)
                outline.append((x+sx*(width/2-radius)+radius*math.cos(ang),y,
                                z+sz*(height/2-radius)+radius*math.sin(ang)))
        return outline

    cell = box("Vårdmodul", (0,1.42,1.56), (2.21,3.35,2.1), yellow,.075)
    wheel_cut(cell,1.77)
    for side in (-1,1):
        for row in range(2):
            for col in range(4):
                if (row+col)%2: continue
                y = .20 + col*.81
                panel = box("Reflexfält", (side*1.106,y,.77+row*.35), (.008,.80,.35), PAINT_GREEN,.002)
                if abs(y-1.77)<.95: wheel_cut(panel,1.77)
            # Cast the decal onto the stamped door. The top course is forward
            # and the lower course aft, as on unit 3 26-9310.
            vertices,faces=[],[]
            for j in range(13):
                z=.615+row*.366+j*.362/12
                for k in range(9):
                    y=-.963-row*.542+k*.535/8
                    hit,point,normal,_=nose.ray_cast((side*2,y,z),(-side,0,0))
                    if not hit:
                        raise ValueError("Door marking outside pickup body")
                    vertices.append(point+normal*.003)
                    if j and k:
                        i=j*9+k
                        face=(i-10,i-9,i,i-1)
                        faces.append(face if side>0 else face[::-1])
            mesh=bpy.data.meshes.new("Formskuren dörrreflex")
            mesh.from_pydata(vertices,[],faces)
            mesh.materials.append(PAINT_GREEN)
            decal=bpy.data.objects.new("Dörrreflex",mesh)
            bpy.context.collection.objects.link(decal)
            decal.parent=root
        def side_outline(y,z,w,h,r,depth):
            return [(side*depth,u,v) for u,_,v in rear_outline(y,0,z,w,h,r)]
        window=[side_outline(1.62,2.02,w,h,r,d) for w,h,r,d in
                ((.87,.458,.077,1.104),(.866,.455,.076,1.117),
                 (.850,.438,.067,1.124),(.814,.404,.057,1.124),
                 (.803,.395,.054,1.116))]
        profile_loft("Vårdfönstrets gummilist",window,RUBBER,root,close_ends=False)
        profile_loft("Vårdfönstrets välvda glas",[window[-1],
            side_outline(1.62,2.02,.74,.345,.051,1.121),
            side_outline(1.62,2.02,.56,.23,.047,1.124)],glass,root)
        for left,right,latch in ((.03,.79,.64),(2.36,3.00,2.83)):
            mid=(left+right)*.5
            width=right-left
            frame=[side_outline(mid,1.445,width-dw,1.08-dw,r,d) for dw,r,d in
                   ((0,.024,1.112),(.005,.022,1.117),(.016,.017,1.117))]
            profile_loft("Luckans kantfog",frame,DARK,root,close_ends=False)
            lock=[side_outline(latch,1.45,w,h,r,d) for w,h,r,d in
                  ((.121,.093,.017,1.107),(.121,.093,.017,1.122),
                   (.100,.072,.011,1.125),(.093,.064,.010,1.116))]
            profile_loft("Lucklåsets infattning",lock,BLACK,root)
            box("Luckans dragspak",(side*1.126,latch,1.455),(.010,.065,.018),DARK,.005)
        for i in range(14):
            if i in (4,5,6):
                continue
            box("Övre reflex",(side*1.109,-.10+i*.23,2.49),(.009,.18,.075),PAINT_GREEN,.003)
        # Flat printed artwork on the module: six broad arms with a white
        # keyline and the staff and serpent centred above the service hatch.
        def side_decal(name,points,depth,finish):
            mesh=bpy.data.meshes.new(name)
            mesh.from_pydata([(side*depth,.36+side*u,2.19+v) for u,v in points],
                             [],[tuple(range(len(points)))])
            if mesh.polygons[0].normal.x*side<0:
                mesh.flip_normals()
            mesh.materials.append(finish)
            obj=bpy.data.objects.new(name,mesh)
            bpy.context.collection.objects.link(obj)
            obj.parent=root
        for scale,depth,finish in ((1,1.112,PAINT_WHITE),(.91,1.114,POLICE_BLUE)):
            star=[]
            for arm in range(6):
                angle=arm*math.tau/6
                for u,v in ((.049,.174),(-.049,.174),(-.049,.085)):
                    star.append((scale*(u*math.cos(angle)-v*math.sin(angle)),
                                 scale*(u*math.sin(angle)+v*math.cos(angle))))
            side_decal("Sjukvårdsstjärna",star,depth,finish)
        side_decal("Vårdsymbolens stav",[(-.005,-.107),(.005,-.107),
                   (.006,.108),(-.006,.108)],1.116,PAINT_WHITE)
        serpent=[]
        for i in range(25):
            t=i/24
            serpent.append((.025*(.55+.45*t)*math.sin(2.8*math.pi*t),-.085+.173*t))
        side_decal("Vårdsymbolens orm",[(u-.005,v) for u,v in serpent]+
                   [(u+.005,v) for u,v in reversed(serpent)],1.118,PAINT_WHITE)
        number=text_obj("Enhetsnummer på vårdmodul","3 26-9310",
                        (side*1.116,1.05,2.449),.121,PAINT_GREEN,-side,root)
        extents=[v.co.x for v in number.data.vertices]
        number.location.y-=side*(min(extents)+max(extents))*.5
        label = text_obj("Ambulansdekal","AMBULANS",(side*1.123,1.54,1.58),.185,POLICE_BLUE,-side,root)
        label.data.transform(__import__("mathutils").Matrix.Translation((-sum(v.co.x for v in label.data.vertices)/len(label.data.vertices),0,0)))
        box("Spegelfästets packning",(side*.948,-1.68,1.477),(.035,.128,.105),RUBBER,.014)
        box("Spegelarm",(side*1.059,-1.68,1.494),(.245,.068,.061),BLACK,.020)
        box("Spegelarmens led",(side*1.171,-1.68,1.526),(.088,.081,.096),BLACK,.022)
        box("Backspegelns hus",(side*1.177,-1.679,1.669),(.180,.150,.301),BLACK,.041)
        box("Spegelglasens gummilist",(side*1.177,-1.604,1.669),(.157,.019,.268),RUBBER,.024)
        box("Huvudspegelns glas",(side*1.177,-1.591,1.709),(.133,.012,.165),mirror_glass,.017)
        box("Vidvinkelspegelns glas",(side*1.177,-1.591,1.583),(.133,.012,.065),mirror_glass,.013)
        _, handle_contact, _, _ = nose.ray_cast((side*2,-.57,1.32),(-side,0,0))
        handle_x = handle_contact.x
        box("Dörrhandtagets packning",(handle_x+side*.006,-.57,1.32),
            (.025,.226,.073),RUBBER,.012)
        for handle_y in (-.653,-.485):
            box("Dörrhandtagets stöd",(handle_x+side*.022,handle_y,1.323),
                (.031,.033,.048),BLACK,.008)
        box("Dörrhandtagets grepp",(handle_x+side*.037,-.57,1.326),
            (.024,.173,.026),BLACK,.008)
        cylinder("Dörrens låscylinder",(handle_x+side*.020,-.466,1.296),
                 .011,.020,METAL,vertices=16,root=root)
        box("Fotstegets bärprofil",(side*.992,-.99,.466),(.275,1.31,.066),METAL,.022)
        box("Fotstegets halkskydd",(side*1.024,-.99,.505),(.195,1.22,.019),RUBBER,.009)
        for rib in range(13):
            box("Fotstegets greppkant",(side*1.023,-1.53+rib*.09,.518),
                (.149,.015,.009),DARK,.004)
        for support_y in (-1.425,-.565):
            box("Fotstegets konsol",(side*.864,support_y,.428),(.29,.079,.069),DARK,.012)
        for end_y in (-1.62,-.36):
            box("Fotstegets ändstycke",(side*.994,end_y,.464),(.274,.071,.072),BLACK,.018)
        # The module arch has a moulded lip that returns inside the wheel
        # opening. The deeper rear splash flap sits inboard of the trim.
        arch=[]
        liner=[]
        for i in range(49):
            theta=.065+(math.pi-.130)*i/48
            ring=[]
            for radius,depth in ((.537,1.025),(.530,1.094),(.532,1.119),
                                 (.541,1.131),(.566,1.133),(.588,1.118),
                                 (.592,1.102),(.573,1.099)):
                y=1.77+radius*math.cos(theta)
                z=.47+radius*math.sin(theta)
                ring.append((side*depth,y,z))
            arch.append(ring)
            liner.append([(side*depth,1.77+r*math.cos(theta),.47+r*math.sin(theta))
                          for depth,r in ((.752,.525),(1.09,.525),(1.09,.536),(.752,.536))])
        profile_loft("Innerskärm bak",liner,RUBBER,root)
        profile_loft("Vårdmodulens skärmkant",arch,RUBBER,root)
        flap=[]
        for z,y,width in ((.253,2.361,.095),(.263,2.361,.129),
                          (.362,2.343,.133),(.515,2.324,.137),(.550,2.321,.129)):
            flap.append([(side*(.957+dx*width),y+dy,z)
                         for dx,dy in ((-1,-.011),(1,-.011),(1,.011),(-1,.011))])
        profile_loft("Stänkskydd bak",flap,RUBBER,root)
        for y in (-2.05,1.77):
            def axle_rings(profile):
                return [[(side*depth,y+radius*math.cos(i*math.tau/64),
                          .47+radius*math.sin(i*math.tau/64)) for i in range(64)]
                        for depth,radius in profile]
            tire=[(.80,.292),(.787,.346),(.796,.409),(.817,.452),
                  (.838,.470),(.874,.470),(.880,.460),(.887,.470),
                  (.974,.470),(.981,.460),(.988,.470),(1.044,.470),
                  (1.065,.451),(1.087,.403),(1.094,.346),(1.082,.292)]
            profile_loft("Däck",axle_rings(tire+[tire[0]]),RUBBER,root,close_ends=False)
            rim=profile_loft("Aluminiumfälg",axle_rings([(.998,.274),(1.065,.293),
                (1.084,.300),(1.094,.292),(1.091,.279),(1.073,.261),
                (1.059,.228),(1.065,.183),(1.091,.148),(1.095,.103)]),METAL,root)
            for i in range(8):
                angle=i*math.tau/8
                hole_y=y+.219*math.cos(angle)
                hole_z=.47+.219*math.sin(angle)
                bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.044,depth=.18,
                    location=(side*1.055,hole_y,hole_z),rotation=(0,math.pi/2,0))
                punch=bpy.context.object
                cut=rim.modifiers.new("Ventilationshål","BOOLEAN")
                cut.object=punch
                cut.operation="DIFFERENCE"
                bpy.context.view_layer.objects.active=rim
                bpy.ops.object.modifier_apply(modifier=cut.name)
                bpy.data.objects.remove(punch,do_unlink=True)
                cylinder("Wheel bolt",(side*1.100,y+.122*math.cos(angle),
                    .47+.122*math.sin(angle)),.018,.029,DARK,vertices=6,root=root)
            cylinder("Wheel hub",(side*1.106,y,.47),.082,.066,METAL,root=root)
        # Wrap the stacked optical units around the front wing. Each
        # reflector opens toward the road with its bulb behind the rim.
        def lamp_loop(cx,cz,width,height,stand):
            ring=[]
            for i in range(32):
                a=math.tau*i/32
                c,sn=math.cos(a),math.sin(a)
                x=cx+width*.5*math.copysign(abs(c)**.43,c)
                z=cz+height*.5*math.copysign(abs(sn)**.43,sn)
                y=-3.185+.135*max(0,(x-.70)/.28)**2
                ring.append((side*x,y-stand,z))
            return ring
        profile_loft("Strålkastarhus",[
            lamp_loop(.737,1.065,w,h,d) for w,h,d in
            ((.407,.298,-.045),(.405,.298,.010),(.389,.285,.019))],BLACK,root)
        for height in (.996,1.132):
            profile_loft("Skiktad reflektor",[
                lamp_loop(.708,height,w,h,d) for w,h,d in
                ((.308,.126,.019),(.307,.124,.039),(.284,.102,.043),
                 (.192,.073,.025),(.078,.045,.023))],METAL,root)
            profile_loft("Strålkastarlins",[
                lamp_loop(.708,height,w,h,d) for w,h,d in
                ((.120,.064,.025),(.109,.060,.036),(.056,.037,.045))],HEADLAMP,root)
        turn_signal=material("Bärnstensfärgat blinkersglas",(.91,.255,.012),.12,.23)
        profile_loft("Front amber indicator",[
            lamp_loop(.905,1.067,w,h,d) for w,h,d in
            ((.049,.256,.017),(.048,.250,.030),(.033,.234,.036))],turn_signal,root)
        bezel=box("Främre blåljusinfattning",(side*.64,-1.093,2.377),
                  (.285,.044,.106),BLACK,.018)
        bezel.rotation_euler.x=-.84
        lens=box("FlashBlue_Module",(side*.64,-1.114,2.396),
                 (.241,.018,.070),BLUE_LAMP,.009)
        lens.rotation_euler.x=-.84
    def rear_panel(name,x,y,z,width,height,radius,finish):
        outline=rear_outline(x,y,z,width,height,radius)
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata(outline,[],[tuple(reversed(range(len(outline))))])
        mesh.materials.append(finish)
        obj=bpy.data.objects.new(name,mesh)
        bpy.context.collection.objects.link(obj)
        obj.parent=root
        return obj

    def rear_text(name,body,x,y,z,size,finish):
        obj=text_obj(name,body,(0,y,z),size,finish,root=root)
        xs=[v.co.x for v in obj.data.vertices]
        obj.scale.z=.08
        obj.location.x=x+(min(xs)+max(xs))/2
        obj.rotation_euler=(math.pi/2,0,math.pi)

    seal = material("EPDM door seals",(.014,.020,.022),.04,.62)
    amber = material("Amber signal optic",(.88,.32,.024),.18,.23)
    for side in (-1,1):
        x=side*.412
        rear_panel("Bakdörrens tätning",x,3.099,1.51,.818,1.68,.068,seal)
        rings=[rear_outline(x,y,1.51,w,h,r) for y,w,h,r in
               ((3.100,.795,1.654,.059),(3.104,.789,1.647,.054),
                (3.109,.776,1.635,.053),(3.110,.755,1.614,.052))]
        profile_loft("Pressad dörrplåt",rings,yellow,root)
        rear_panel("Infattning vårdfönster",x,3.111,1.999,.603,.445,.079,seal)
        rear_panel("Tonat bakglas",x,3.115,1.999,.564,.406,.065,glass)
        for row in range(2):
            for col in range(2):
                if (row+col+int(side>0))%2==0:
                    rear_panel("Grön bakreflex",x+(col-.5)*.381,3.116,.885+row*.276,.378,.269,.009,PAINT_GREEN)
        for z in (.91,1.98):
            box("Gångjärnsblad",(side*.793,3.121,z),(.102,.023,.086),METAL,.012)
            for i in (-1,0,1):
                cylinder("Gångjärnstapp",(side*.827,3.146,z+i*.044),.021,.040,
                         DARK if i==0 else METAL,axis_x=False,vertices=16,root=root)
            for dz in (-.022,.022):
                screw=cylinder("Gångjärnsskruv",(side*.765,3.136,z+dz),
                               .008,.006,DARK,axis_x=False,vertices=8,root=root)
                screw.rotation_euler.x=math.pi/2
        lamp_x=side*.951
        profile_loft("Baklykta hållare",[
            rear_outline(lamp_x,y,1.09,w,h,r) for y,w,h,r in
            ((3.096,.191,.492,.048),(3.110,.195,.495,.050),
             (3.126,.183,.482,.045),(3.130,.173,.473,.040))],seal,root)
        for z,finish in ((1.225,amber),(1.084,TAIL_LAMP),(.952,GLASS_HI)):
            # Cross sections curve around the outer corners. Microprisms on
            # the face catch glancing light across each sealed optical unit.
            rings=[]
            for j in range(37):
                u=j/18-1
                h=.0525*(1-.34*max(0,(abs(u)-.70)/.30)**2)
                bulge=.013*(1-u*u)
                prism=.0025*(j%3==1)
                rings.append([(lamp_x+u*.075,depth,z+v*h) for v,depth in
                    ((-1,3.129),(-.94,3.138+bulge),(-.73,3.141+bulge+prism),
                     (0,3.144+bulge+prism),(.73,3.141+bulge+prism),
                     (.94,3.138+bulge),(1,3.129))])
            name = "Rear indicator lens" if finish == amber else "Kombinationslykta"
            profile_loft(name,rings,finish,root)
        rear_panel("Blåljuskassett",side*.884,3.101,2.45,.345,.131,.037,seal)
        rear_panel("Blå optik",side*.884,3.105,2.45,.295,.087,.023,glass)
        for i in range(4):
            rear_panel("FlashBlue_Rear",side*.884+(i-1.5)*.063,3.113,2.45,.045,.056,.010,BLUE_LAMP)
    rear_text("Bakre ambulansmärkning","AMBULANS",0,3.115,1.52,.255,POLICE_BLUE)
    rear_text("Enhetsnummer bak","3 26-9310",0,3.106,2.405,.128,PAINT_GREEN)
    rear_panel("Infällt dörrgrepp",-.117,3.124,1.355,.142,.085,.024,seal)
    for x in (-.155,-.069):
        box("Låsspakens infästning",(x,3.134,1.359),(.024,.027,.034),seal,.006)
    box("Låsspak",(-.112,3.141,1.359),(.090,.029,.024),METAL,.009)
    lock=cylinder("Låscylinder bak",(-.116,3.132,1.327),.010,.012,METAL,False,16,root)
    lock.rotation_euler.x=math.pi/2
    box("Nyckelspår bak",(-.116,3.139,1.327),(.010,.003,.0025),BLACK,.001)
    # Mount the plate on one leaf so the centre seam stays clear.
    rear_panel("Skylthållare",.413,3.124,.795,.47,.117,.012,seal)
    rear_panel("Registreringsskylt bak",.413,3.128,.795,.453,.103,.009,PAINT_WHITE)
    rear_panel("Blått landsfält",.614,3.132,.795,.042,.099,.004,POLICE_BLUE)
    rear_text("Registreringsnummer ambulans","AXL 310",.392,3.129,.768,.081,BLACK)
    for x in (.283,.543):
        box("Skyltbelysningens hus",(x,3.134,.884),(.080,.048,.025),DARK,.006)
        box("Skyltbelysningens diffusor",(x,3.141,.870),(.058,.028,.007),GLASS_HI,.003)
    box("Laststeg",(0,3.147,.502),(2.14,.244,.105),DARK,.034)
    for i in range(3):
        box("Halkskydd",(0,3.08+i*.069,.558),(1.99,.025,.009),RUBBER,.003)
    reflector = material("Röd prismareflex",(.64,.018,.011),.16,.27)
    for side in (-1,1):
        x=side*.871
        box("Stötfångarreflexens ram",(x,3.265,.504),(.236,.023,.055),BLACK,.009)
        box("Röd stötfångarreflex",(x,3.278,.504),(.205,.009,.034),reflector,.006)
        for prism in range(-4,5):
            box("Reflexprisma",(x+prism*.020,3.283,.504),(.004,.003,.022),reflector,.001)
    # A pressed chrome surround narrows below the stacked headlamps.
    def grille_loop(width,height,depth):
        ring=[]
        for x,_,z in rear_outline(0,0,1.059,width,height,.046):
            ring.append((x*(1+.09*(z-1.059)/height),depth+.050*x*x,z))
        return ring
    profile_loft("Kylarmaskering",[
        grille_loop(w,h,d) for w,h,d in ((1.115,.365,-3.17),(1.110,.360,-3.210),
            (1.092,.345,-3.225),(1.045,.303,-3.225),(1.025,.289,-3.200))],
        METAL,root,close_ends=False)
    box("Kylarnätets skugga",(0,-3.184,1.059),(1.044,.019,.313),RUBBER,.024)
    for i in range(-10,11):
        x=i*.047
        box("Kylarlamell",(x,-3.203+.039*x*x,1.060),(.009,.016,.274),DARK,.003)
    for z in (.990,1.128):
        rings=[]
        for x in (-.522,-.45,-.27,0,.27,.45,.522):
            rings.append([(x,-3.218+.048*x*x+dy,z+dz) for dy,dz in
                         ((.012,-.018),(-.002,-.016),(-.013,-.008),
                          (-.014,.007),(-.006,.020),(.011,.016))])
        profile_loft("Välvd kromribba",rings,METAL,root)
    rings=[]
    for x in (-.990,-.976,-.933,-.85,-.71,-.49,-.27,0,.27,.49,.71,.85,.933,.976,.990):
        u=abs(x)
        sweep=.025*u*u+.240*u**9
        top=.842+.025*u
        low=.628+.074*u**7
        rings.append([(x,-3.261+sweep+dy,z) for dy,z in
                     ((.197,low+.025),(.068,low),(.013,low+.012),
                      (-.007,low+.047),(-.013,top-.045),(.002,top-.011),
                      (.036,top),(.165,top-.006))])
    profile_loft("Pressad kromstötfångare",rings,METAL,root)
    box("Nedre luftintag",(0,-3.277,.692),(.72,.021,.060),RUBBER,.018)
    box("Främre skylthållare",(0,-3.281,.769),(.47,.028,.102),seal,.010)
    box("Registreringsskylt fram",(0,-3.301,.769),(.453,.013,.090),PAINT_WHITE,.006)
    box("Blått landsfält fram",(-.201,-3.309,.769),(.042,.004,.083),POLICE_BLUE,.003)
    plate = text_obj("Registreringsnummer fram","AXL 310",(0,-3.312,.743),.075,BLACK,
                     root=root,flat=True)
    plate.rotation_euler = (math.pi/2,0,0)
    extent = [vertex.co.x for vertex in plate.data.vertices]
    plate.location.x = .018-(min(extent)+max(extent))*.5
    return root

def make_taxi():
    root=make_bmw(PAINT_BLACK,"Sjöstad kombitaxi")
    # Rework the donor wheelbase into a low estate with a long, upright tail.
    for obj in list(root.children):
        if any(key in obj.name.lower() for key in ("kidney","radiator","grille surround","roundel",
                "enamel badge","ruby light","smoked rear lamp","registration axl")):
            bpy.data.objects.remove(obj,do_unlink=True)
            continue
        frame=obj.matrix_local.copy()
        inverse=frame.inverted()
        for v in obj.data.vertices:
            p=frame@v.co
            p.y*=1.06
            if p.z>.79:
                p.z=.79+(p.z-.79)*.81
                p.y+=.23*min(1,max(0,(p.y-.55)/1.4))*min(1,(p.z-.79)/.63)
            v.co=inverse@p
    cube("Taxi grille",(0,-2.584,.916),(.89,.055,.239),DARK,.033,root)
    for i in range(-8,9):
        cube("Taxi grille bar",(i*.047,-2.619,.916),(.012,.009,.189),METAL,.003,root)
    for side in (-1,1):
        rings=[]
        for z,x,y,w in ((.81,.806,2.62,.077),(.89,.822,2.644,.113),
                          (1.00,.826,2.625,.107),(1.068,.810,2.58,.065),
                          (1.32,.758,2.39,.045),(1.50,.700,2.18,.037)):
            rings.append([(side*(x+w*math.cos(i*math.tau/20)),y+.08*math.sin(i*math.tau/20),z)
                          for i in range(20)])
        profile_loft("Estate pillar tail lamp",rings,TAIL_LAMP,root)
        for label,z,size in (("TAXI",.87,.16),("SJÖSTAD",.78,.078)):
            letters=text_obj("Taxi door lettering",label,(side*.947,-.49,z),size,PAINT_WHITE,-side,root)
            xs=[v.co.x for v in letters.data.vertices]
            letters.location.y-=side*(min(xs)+max(xs))*.5
        for index in range(2):
            sweep=[]
            for i in range(17):
                t=i/16
                y=.01+1.13*t
                z=.93-.33*math.sin(math.pi*t)+index*.07*math.sin(math.pi*t)
                sweep.append([(side*(.947+dx),y,z+dz) for dx,dz in
                              ((0,0),(.003,.011),(.004,.025),(0,.024))])
            profile_loft("Green leaf livery",sweep,PAINT_GREEN,root)
    cube("Taxi roof plinth",(0,.05,1.605),(.54,.32,.044),BLACK,.015,root)
    roof=next(obj for obj in root.children if obj.name.startswith("Roof and cabin"))
    for x in (-.164,.164):
        for y in (-.133,.233):
            hit, point, _, _ = roof.ray_cast((x,y,2.5),(0,0,-1))
            if not hit:
                raise ValueError("Taxi roof sign mounting tab outside roof")
            cube("Taxi sign rubber pad",(x,y,point.z+.006),(.092,.074,.018),RUBBER,.008,root)
            cube("Taxi sign mounting tab",(x,y,point.z+.020),(.082,.070,.016),DARK,.005,root)
            cylinder("Taxi sign fixing bolt",(x,y,point.z+.032),.010,.010,METAL,False,6,root)
    cube("Taxi roof sign",(0,.05,1.686),(.52,.25,.145),PAINT_WHITE,.032,root)
    for x in (-.254,.254):
        cube("Taxi sign end cap",(x,.05,1.686),(.030,.226,.120),DARK,.012,root)
    for side in (-1,1):
        sign=text_obj("Taxi roof lettering","TAXI",(0,.05+side*.128,1.653),.105,BLACK,root=root)
        sign.rotation_euler=(math.pi/2,0,math.pi if side>0 else 0)
        xs=[v.co.x for v in sign.data.vertices]
        sign.location.x=side*(min(xs)+max(xs))*.5
    return root

def make_police():
    root = make_bmw(PAINT_WHITE, "Polis | patrullbil", patrol=True)
    skin = next(obj for obj in root.children if obj.name.startswith("X5 M60i continuous"))
    bpy.context.view_layer.update()
    surface = skin.evaluated_get(bpy.context.evaluated_depsgraph_get())
    foil_blue=material("Patrol cobalt reflective film",(.009,.058,.39),.08,.30)
    foil_yellow=material("Patrol fluorescent lemon film",(.86,.98,.016),.03,.35)
    for side in (-1,1):
        for row in range(2):
            for col in range(8):
                points=[]
                faces=[]
                previous={}
                # Sample the vertical shoulder crease too. A tall flat quad cuts into the door.
                for j in range(13):
                    y=-1.90+.48*(col+j/12)
                    column={}
                    for h in range(9):
                        z=.854+row*.16+.158*h/8
                        hit,pt,normal,_=surface.ray_cast((side*2,y,z),(-side,0,0))
                        if not hit or normal.x*side<.30:
                            continue
                        column[h]=len(points)
                        points.append(tuple(pt+normal*.004))
                        if h-1 in column and h in previous and h-1 in previous:
                            face=(previous[h-1],column[h-1],column[h],previous[h])
                            faces.append(face if side>0 else face[::-1])
                    previous=column
                if not faces: continue
                mesh=bpy.data.meshes.new("Reflexfolie")
                mesh.from_pydata(points,[],faces)
                mesh.materials.append(foil_blue if (row+col)%2 else foil_yellow)
                patch=bpy.data.objects.new("Blågul reflex",mesh)
                bpy.context.collection.objects.link(patch)
                patch.parent=root
    # Conform the lettering to the bonnet crown so every glyph sits on the paint.
    lettering=text_obj("Bonnet police lettering","POLIS",(0,0,0),.29,foil_blue,root=root,flat=True)
    lettering.rotation_euler=(0,0,0)
    xs=[v.co.x for v in lettering.data.vertices]
    midpoint=(min(xs)+max(xs))*.5
    for v in lettering.data.vertices:
        x=v.co.x-midpoint
        y=-1.91+v.co.y
        hit,point,_,_=surface.ray_cast((x,y,3),(0,0,-1))
        if not hit: raise ValueError("Patrol lettering outside bonnet")
        v.co=(x,y,point.z+.008)
    for side in (-1,1):
        label=text_obj("Door police lettering","POLIS",(0,0,0),.235,foil_blue,root=root,flat=True)
        xs=[v.co.x for v in label.data.vertices]
        mid=(min(xs)+max(xs))*.5
        label.rotation_euler=(0,0,0)
        for v in label.data.vertices:
            y=-.30+side*(v.co.x-mid)
            z=.653+v.co.y
            hit,point,_,_=surface.ray_cast((side*2,y,z),(-side,0,0))
            if not hit: raise ValueError(f"Patrol lettering outside door {y} {z}")
            v.co=(point.x+.009*side,y,z)
    roof=next(obj for obj in root.children if obj.name.startswith("Roof and cabin"))
    def roof_z(x,y):
        hit,point,_,_=roof.ray_cast((x,y,3),(0,0,-1))
        if not hit: raise ValueError("Patrol equipment outside roof")
        return point.z
    antenna_z=roof_z(0,1.50)
    cylinder("Dispatch antenna foot",(0,1.50,antenna_z+.016),.040,.035,DARK,False,24,root)
    cylinder("Dispatch antenna seal",(0,1.50,antenna_z+.007),.044,.015,RUBBER,False,24,root)
    cylinder("Dispatch antenna collar",(0,1.50,antenna_z+.035),.018,.018,METAL,False,12,root)
    cylinder("Radio whip",(0,1.50,antenna_z+.221),.006,.38,DARK,False,12,root)
    for x in [-.19,.19]:
        cube("Front warning light bracket",(x,-2.484,.845),(.112,.038,.060),BLACK,.009,root)
        cube("FlashBlue_Grille" if x<0 else "FlashRed_Grille",(x,-2.509,.845),(.088,.016,.033),BLUE_LAMP,.006,root)
    y=-.08
    base=roof_z(0,y)+.042
    for x in [-.43,.43]:
        foot=roof_z(x,y)
        cube("Patrol lightbar foot",(x,y,(foot+base)*.5),(.11,.16,base-foot+.01),RUBBER,.009,root)
        for offset in [-.092,.092]:
            underlay=roof_z(x,y+offset)
            cube("Lightbar mounting tab",(x,y+offset,underlay+.007),
                 (.082,.046,.020),DARK,.006,root)
            cylinder("Lightbar foot fastener",(x,y+offset,underlay+.021),
                     .012,.012,METAL,False,6,root)
    shell=[]
    for elevation,w,d in [(0,.60,.099),(.012,.633,.126),(.069,.627,.124),(.085,.602,.104)]:
        ring=[]
        for i in range(48):
            a=math.tau*i/48
            c,sn=math.cos(a),math.sin(a)
            ring.append((w*math.copysign(abs(c)**.45,c),y+d*math.copysign(abs(sn)**.45,sn),base+elevation))
        shell.append(ring)
    profile_loft("Patrol lightbar extrusion",shell,DARK,root)
    for side in [-1,1]:
        for i in range(5):
            x=side*(.10+.104*i)
            for face in [-1,1]:
                depth=y+face*(.124-.010*(abs(x)/.59)**4)
                cube("Blue lens surround",(x,depth,base+.042),(.100,.018,.055),foil_blue,.008,root)
                cube("FlashBlue_Left" if side<0 else "FlashRed_Right",
                     (x,depth+face*.011,base+.043),(.083,.009,.038),BLUE_LAMP,.004,root)
    rear=text_obj("Bakluckans märkning","POLIS",(.28,2.49,1.03),.18,POLICE_BLUE,root=root)
    rear.rotation_euler=(math.pi/2,0,math.pi)
    return root

def make_volvo_xc60_police():
    from xc60_body import build
    return build()


def rear_prismatic_lens(name, x, z, height, finish, root):
    """Moulded lens with a shallow convex face and individual reflector facets."""
    vertices, faces = [], []
    columns, rows = 14, round(height / .007)
    for row in range(rows + 1):
        v = 2 * row / rows - 1
        for column in range(columns + 1):
            u = 2 * column / columns - 1
            # Soften the outline where the lens meets the rubber gasket.
            width = .0635 - .004 * abs(v) ** 8
            vertices.append((x + width*u, 3.127 + .009*(1-u*u) + .003*(1-v*v),
                             z + height*v/2))
    for row in range(rows):
        for column in range(columns):
            a = row*(columns+1) + column
            corners = (a, a+columns+1, a+columns+2, a+1)
            center = [sum(vertices[i][axis] for i in corners)/4 for axis in range(3)]
            center[1] += .00038
            tip = len(vertices)
            vertices.append(center)
            faces.extend((i, corners[(k+1)%4], tip) for k,i in enumerate(corners))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    lens = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(lens)
    lens.parent = root
    mesh.materials.append(finish)


def fit_fire_speedometer(root):
    x, y, z = .57, -2.823, 2.125
    # Keep the dial above the steering rim from the seated driving position.
    binnacle = next(part for part in root.children if part.name.startswith("Driver instrument binnacle"))
    binnacle.location.z += .12
    # Preserve dial clearance at the steering wheel while lowering the hood toward the glass.
    corners = [vertex.co.copy() for vertex in binnacle.data.vertices]
    front = min(v.y for v in corners)
    rear = max(v.y for v in corners)
    bottom = min(v.z for v in corners)
    top = max(v.z for v in corners)
    for vertex in binnacle.data.vertices:
        forward = (rear - vertex.co.y) / (rear - front)
        upper = (vertex.co.z - bottom) / (top - bottom)
        vertex.co.z -= .105 * forward * upper
    for name, depth, radius, finish in (
            ("Speedometer bezel", 0, .110, METAL),
            ("Speedometer dial", .006, .102, BLACK)):
        dial = cylinder(name, (x, y+depth, z), radius, .009, finish, False, 48, root)
        dial.rotation_euler.x = math.pi / 2
    for index in range(25):
        angle = math.radians(-135 + index*270/24)
        major = index % 4 == 0
        radius = .084 if major else .089
        mark = cube("Speed graduation", (x-radius*math.sin(angle), y+.014,
                    z+radius*math.cos(angle)), (.003, .003, .019 if major else .009),
                    HEADLAMP, .001, root)
        mark.rotation_euler.y = -angle
    for speed in range(0, 121, 20):
        angle = math.radians(-135 + speed*270/120)
        label = text_obj("Speed dial numeral", str(speed),
                         (x-.059*math.sin(angle), y+.014, z+.059*math.cos(angle)-.005),
                         .018, HEADLAMP, root=root, flat=True)
        label.rotation_euler = (math.pi/2, 0, math.pi)
        label.location.x += max(v.co.x for v in label.data.vertices)*.5
    needle = cube("Fire speed needle", (x, y+.020, z), (.005, .004, .075),
                  PAINT_RED, .001, root)
    for vertex in needle.data.vertices:
        vertex.co.z += .033
    needle.rotation_euler.y = math.radians(135)
    hub = cylinder("Speedometer spindle", (x, y+.024, z), .010, .007, DARK, False, 16, root)
    hub.rotation_euler.x = math.pi / 2


def fit_fire_cab_headliner(root):
    liner = material("Crew cab headliner fabric", (.48, .46, .42), 0, .92)
    cube("Moulded headliner", (0, -2.10, 3.028), (1.93, 2.16, .065), liner, .032, root)
    cube("Overhead console", (0, -2.94, 2.981), (1.78, .34, .095), liner, .043, root)
    for x in (-.55, .55):
        cube("Cab reading light bezel", (x, -2.93, 2.933), (.157, .091, .015), DARK, .007, root)
        cube("Cab reading light diffuser", (x, -2.93, 2.922), (.134, .069, .012), HEADLAMP, .006, root)
    for x in (-.24, .24):
        cube("Overhead vent recess", (x, -2.95, 2.932), (.20, .084, .013), BLACK, .006, root)
        for row in range(4):
            cube("Overhead vent slat", (x, -2.98 + row*.018, 2.924),
                 (.185, .008, .008), DARK, .003, root)


def shape_fire_cab_roof(root):
    # Raise the stamped upper shell above the windscreen seal. The rear
    # tapers beneath the ladder; the beacon stays level on the front crown.
    beacon_parts = ("Beacon mounting", "Blue beacon lens", "Blue optic bezel",
                    "LED reflector", "FlashBlue_", "FlashRed_", "Forward scene lamp")
    for part in root.children:
        if part.name.startswith(beacon_parts):
            part.location.z += .14
        elif part.name == "Fire crew cab":
            frame = part.matrix_local.copy()
            inverse = frame.inverted()
            for vertex in part.data.vertices:
                point = frame @ vertex.co
                height = max(0, min(1, (point.z - 2.93) / .13))
                front = max(0, min(1, (-point.y - .85) / 1.3))
                crown = 1 - .18 * min(1, abs(point.x) ** 4)
                point.z += height * (.075 + .065 * front) * crown
                vertex.co = inverse @ point


def make_fire_engine():
    cab_red = material("Fire appliance vermilion enamel", (.62, .027, .021), .025, .44)
    root = bpy.data.objects.new("Fire engine | Swedish Rescue Pumper", None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type = "CUBE"
    # Heavy chassis, tall cab, side equipment lockers and deck-mounted hose reels.
    chassis=cube("Ladder chassis", (0, 0.12, 1.11), (2.32, 5.95, 0.91), cab_red, 0.18, root)
    # Rolled shoulders and raised parapets enclose the equipment deck.
    deck=[]
    for y,w in ((-.70,1.065),(-.65,1.103),(-.56,1.114),(2.74,1.114),(2.91,1.10),(2.98,1.065)):
        deck.append([(x*w,y,z) for x,z in ((-.98,1.32),(-1,1.40),(-1,2.53),
                   (-.985,2.61),(-.93,2.64),(-.89,2.63),(-.87,2.55),
                   (.87,2.55),(.89,2.63),(.93,2.64),(.985,2.61),(1,2.53),(1,1.40),(.98,1.32))])
    profile_loft("Rescue body with raised roof edges",deck,cab_red,root)
    # Share edges between the glass and the cab skin. The windshield bends
    # around the front pillars and rakes back under the roof header.
    vertices,faces,finishes=[],[],[]
    for z,w,front,rear in ((1.12,1.025,-2.89,-.74),(1.17,1.086,-2.945,-.71),
            (1.62,1.105,-2.958,-.71),(1.73,1.104,-2.948,-.71),
            (1.78,1.099,-2.937,-.71),(2.04,1.09,-2.873,-.715),
            (2.425,1.06,-2.765,-.731),(2.469,1.054,-2.746,-.737),
            (2.51,1.051,-2.736,-.740),(2.55,1.044,-2.721,-.748),
            (2.576,1.031,-2.704,-.759),(2.598,1.007,-2.680,-.775),
            (2.610,.973,-2.650,-.796),(2.617,.930,-2.615,-.822)):
        half=[(0,front-.039),(.53*w,front-.031),(.84*w,front),
              (.92*w,front+.036),(.973*w,front+.103),(w,front+.188),
              (w,-1.615),(w,-1.542),(w,-.858),(.985*w,rear)]
        outline=half+[(-x,y) for x,y in reversed(half[1:])]
        n=len(outline)
        base=len(vertices)
        # The front door sill climbs towards the B pillar. The rear door
        # starts a separate sweep and rises again towards the crew compartment.
        sill_lift = (0,0,0,0,0,0,.13,.075,.185,.185)
        for k,(x,y) in enumerate(outline):
            station = min(k,n-k)
            lift = sill_lift[station] if z in (1.73,1.78) else 0
            vertices.append((x,y,z+lift))
        if base:
            for k in range(n):
                q=(k+1)%n
                faces.append((base-n+k,base-n+q,base+q,base+k))
                counterpart=min(k,n-1-k)
                glazed=counterpart in (0,1,2,5,7)
                finishes.append(1 if glazed and 1.78<z<=2.425 else
                                2 if glazed and z in (1.78,2.469) else 0)
    faces.extend((tuple(reversed(range(n))),tuple(range(len(vertices)-n,len(vertices)))))
    finishes.extend((0,0))
    mesh=bpy.data.meshes.new("Crew cab glazing and steelwork")
    mesh.from_pydata(vertices,[],faces)
    truck_glass=material("Laminated panoramic truck glass",(.015,.034,.048),.045,.095)
    shader=next(node for node in truck_glass.node_tree.nodes if node.type=="BSDF_PRINCIPLED")
    shader.inputs["Alpha"].default_value=.60
    for finish in (cab_red,truck_glass,RUBBER):
        mesh.materials.append(finish)
    mesh.polygons.foreach_set("material_index",finishes)
    for face in mesh.polygons:
        face.use_smooth = face.material_index == 1 or face.center.z > 2.47
    cabin=bpy.data.objects.new("Fire crew cab",mesh)
    bpy.context.collection.objects.link(cabin)
    cabin.parent=root
    upholstery=material("Fire crew woven graphite",(.065,.080,.084),.02,.8)
    cube("Crew cab floor",(0,-1.78,1.45),(2.03,1.91,.09),DARK,.035,root)
    for x in [-.57,.57]:
        for y in [-2.12,-1.13]:
            cube("Crew seat cushion",(x,y,1.63),(.49,.46,.12),upholstery,.049,root)
            back=cube("Crew seat back",(x,y+.177,1.87),(.485,.124,.47),upholstery,.045,root)
            back.rotation_euler.x=-.10
            cube("Crew head restraint",(x,y+.203,2.16),(.30,.12,.16),upholstery,.044,root)
    cube("Crew dashboard top",(0,-2.628,1.80),(1.96,.376,.135),DARK,.054,root)
    cube("Driver instrument binnacle",(.57,-2.535,1.90),(.47,.23,.17),BLACK,.046,root)
    bpy.ops.mesh.primitive_torus_add(location=(.57,-2.37,1.902),rotation=(math.radians(49),0,0),
                                    major_radius=.168,minor_radius=.015,major_segments=36,minor_segments=10)
    steering=bpy.context.object
    steering.name="Crew cab steering rim"
    steering.data.materials.append(RUBBER)
    steering.parent=root
    cube("Crew steering crossbar",(.57,-2.37,1.902),(.32,.035,.045),DARK,.012,root)
    cube("Dispatch terminal casing",(-.072,-2.53,1.911),(.27,.067,.157),BLACK,.016,root)
    cube("Dispatch terminal display",(-.072,-2.491,1.915),(.242,.012,.129),GLASS_HI,.006,root)
    shutter_finish = material("Satin silver shutter slats", (.76,.79,.80), .24, .42)
    def shutter_hardware(center, outward, width, height):
        # Local coordinates run along the slats, out from the face and upwards.
        nx,ny=outward
        def fitting(name, along, depth, up, span, thickness, rise, finish, bevel):
            x,y,z=center
            loc=(x+nx*depth-ny*along,y+ny*depth+nx*along,z+up)
            dims=(thickness,span,rise) if nx else (span,thickness,rise)
            return cube(name,loc,dims,finish,bevel,root)
        for end in (-1,1):
            fitting("Shutter guide rail",end*(width/2-.013),.007,height/2,
                    .026,.026,height,METAL,.005)
            fitting("Lift handle bracket",end*width*.36,.035,.086,
                    .032,.077,.068,METAL,.009)
        fitting("Shutter lift handle",0,.067,.088,width*.75,.028,.032,METAL,.010)
        fitting("Shutter lock bezel",0,.012,.153,.074,.025,.064,DARK,.010)
        fitting("Shutter lock barrel",0,.027,.153,.043,.009,.036,METAL,.004)
        fitting("Shutter keyway",0,.032,.153,.007,.003,.020,BLACK,.001)
    for side in (-1,1):
        for y in (-.10,1.08,2.26):
            low = 1.19 if y > 0 else .91
            high = 2.47
            cube("Locker gasket",(side*1.119,y,(high+low)/2),(.045,1.16,high-low),BLACK,.018,root)
            cube("Roller shutter",(side*1.147,y,(high+low)/2),(.041,1.11,high-low-.045),shutter_finish,.015,root)
            for row in range(2):
                for col in range(4):
                    finish = PAINT_YELLOW if (row+col)%2 else cab_red
                    cube("Locker reflective check",(side*1.171,y+(col-1.5)*.274,1.63+row*.155),
                         (.007,.274,.155),finish,.001,root)
            for rib in range(1,int((high-low)/.081)):
                cube("Shutter seam",(side*1.176,y,low+rib*.081),(.006,1.10,.006),DARK,0,root)
            shutter_hardware((side*1.168,y,low+.023),(side,0),1.11,high-low-.046)
        for row in range(2):
            for col in range(8):
                y = -2.63+col*.246
                finish = PAINT_YELLOW if (row+col)%2 else cab_red
                for front,rear in ((-2.735,-1.623),(-1.597,-.755)):
                    start=max(front+.009,y-.119)
                    end=min(rear-.009,y+.119)
                    if end>start:
                        cube("Crew door reflective check",(side*1.176,(start+end)/2,1.31+row*.14),
                             (.008,end-start,.137),finish,.003,root)
        for start,end in ((-.75,.71),(1.57,1.92)):
            cube("High visibility lower trim",(side*1.164,(start+end)/2,.95),
                 (.018,end-start,.075),PAINT_YELLOW,.006,root)
        # The two pressed door skins bridge the wider lower apron and the
        # narrower window sill. Leave a visible shut line between the doors.
        for front,rear in ((-2.735,-1.623),(-1.597,-.755)):
            courses=[]
            for z,d,inset in ((1.153,1.159,.034),(1.177,1.167,.015),
                              (1.246,1.168,.006),(1.347,1.160,.004),
                              (1.446,1.164,.004),(1.495,1.171,.005),
                              (1.523,1.172,.005),(1.572,1.128,.006),
                              (1.626,1.121,.007),(1.699,1.122,.010),
                              (1.724,1.107,.016)):
                courses.append([(side*x,y,z) for x,y in
                    ((1.093,front+inset),(d-.005,front+inset),(d,front+inset+.022),
                     (d,rear-inset-.022),(d-.005,rear-inset),(1.093,rear-inset))])
            panel=profile_loft("Pressed crew door panel",courses,cab_red,root)
            handle_y=rear-.147
            pocket=cube("Handle pocket former",(side*1.134,handle_y,1.656),
                        (.050,.202,.095),None,.021)
            cut=panel.modifiers.new("Stamped handle recess","BOOLEAN")
            cut.operation="DIFFERENCE"
            cut.object=pocket
            bpy.context.view_layer.objects.active=panel
            bpy.ops.object.modifier_apply(modifier=cut.name)
            bpy.data.objects.remove(pocket,do_unlink=True)
            cube("Door handle cup",(side*1.109,handle_y,1.656),(.005,.181,.078),BLACK,.002,root)
            for end in (-1,1):
                cube("Latch pivot",(side*1.117,handle_y+end*.069,1.67),(.017,.022,.023),DARK,.004,root)
            cube("Recessed latch grip",(side*1.123,handle_y,1.67),(.013,.150,.023),DARK,.006,root)
        # Recess the entry behind the front wheel and expose the step treads.
        recess=cube("Entry recess tool",(side*1.175,-1.088,.792),(.337,.650,.600),None,.044)
        cut=chassis.modifiers.new("Crew entry recess","BOOLEAN")
        cut.object=recess
        cut.operation="DIFFERENCE"
        bpy.context.view_layer.objects.active=chassis
        bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(recess,do_unlink=True)
        cube("Entry kick panel",(side*1.016,-1.088,.856),(.021,.571,.417),RUBBER,.012,root)
        for z,d in ((.548,1.129),(.828,1.091)):
            cube("Crew entry tread",(side*d,-1.088,z),(.201,.600,.042),METAL,.012,root)
            for i in range(6):
                cube("Tread grip",(side*d,-1.32+i*.093,z+.022),(.163,.028,.009),DARK,.004,root)
        for label, text, center_y, size in (
                ("Cab unit number","711",-2.37,.170),
                ("Cab identity","RÄDDNINGSTJÄNST",-1.29,.059)):
            marking=text_obj(label,text,(side*1.137,center_y,1.583),
                             size,PAINT_WHITE,-side,root,flat=True)
            xs=[vertex.co.x for vertex in marking.data.vertices]
            marking.location.y-=side*(min(xs)+max(xs))*.5
            # Seat the decal against the pressed skin along the window sill.
            for vertex in marking.data.vertices:
                z = marking.location.z + vertex.co.y
                span = min(1,max(0,(z-1.572)/.054))
                panel_x = 1.128 + span*(1.121-1.128)
                vertex.co.z = panel_x + .0015 - abs(marking.location.x)
        for z in (1.93,2.36):
            cube("Mirror bracket foot",(side*1.09,-2.56,z),(.085,.135,.084),RUBBER,.023,root)
            bracket=cube("Swept mirror bracket",(side*1.22,-2.60,z),(.29,.048,.042),BLACK,.014,root)
            bracket.rotation_euler.z=-side*.25
        cube("Mirror carrier",(side*1.34,-2.64,2.15),(.046,.052,.49),BLACK,.016,root)
        for label,z,w,h,tilt,bulge in (("Main",2.245,.213,.305,.035,.006),
                                       ("Wide angle",1.987,.203,.145,.29,.017)):
            # Convex glass and its lip share an outline, tilted towards the driver.
            def mirror_ring(scale, depth):
                ring=[]
                for i in range(40):
                    c=math.cos(math.tau*i/40)
                    sn=math.sin(math.tau*i/40)
                    x=w*.5*scale*math.copysign(abs(c)**.51,c)
                    v=h*.5*scale*math.copysign(abs(sn)**.51,sn)
                    y=depth+.17*x
                    ring.append((side*(1.345+x),-2.635+y*math.cos(tilt)+v*math.sin(tilt),
                                 z+v*math.cos(tilt)-y*math.sin(tilt)))
                return ring
            profile_loft(label+" mirror shell",[mirror_ring(k,d) for k,d in
                         ((.60,-.084),(.90,-.074),(1,-.043),(1,.035),(.95,.048))],BLACK,root)
            profile_loft(label+" mirror glass",[mirror_ring(k,d) for k,d in
                         ((.88,.049),(.70,.050+bulge*.5),(.38,.050+bulge*.9),(.04,.050+bulge))],METAL,root)
        # Wiper blades parked along the lower sweep of the panoramic screen.
        blade=[]
        for i in range(9):
            t=i/8
            x=side*(.063+.82*t)
            z=1.815+.066*t
            y=-2.983+.024*t*t+.26*(z-1.78)
            blade.append([(x,y+dy,z+dz) for dy,dz in ((-.010,0),(0,.009),(.009,0),(0,-.009))])
        profile_loft("Crew cab wiper blade",blade,RUBBER,root)
        arm=[]
        for distance,height,depth,radius in (
                (.23,1.781,-3.000,.014),(.27,1.790,-3.004,.012),
                (.36,1.816,-2.993,.009),(.47,1.847,-2.973,.008)):
            arm.append([(side*distance,depth+dy*radius,height+dz*radius)
                        for dy,dz in ((-1,-.5),(1,-.5),(1,.5),(-1,.5))])
        profile_loft("Cab wiper linkage",arm,DARK,root)
        cube("Cab wiper spindle cap",(side*.23,-3.000,1.779),
             (.050,.030,.026),RUBBER,.009,root)
    # The pumper carries one front axle and one rear axle.
    pumper_running_gear(root,chassis)
    cube("Rear pump compartment",(0,2.75,1.81),(2.15,.46,1.22),cab_red,.065,root)
    for side in (-1,1):
        x = side*.51
        cube("Rear shutter surround",(x,3.065,1.80),(.998,.08,1.57),BLACK,.025,root)
        cube("Rear roller blind",(x,3.115,1.80),(.952,.03,1.51),shutter_finish,.014,root)
        for row in range(2):
            for col in range(4):
                finish = PAINT_YELLOW if (row+col)%2 else cab_red
                cube("Rear reflective check",(x+(col-1.5)*.23,3.135,1.72+row*.145),
                     (.23,.008,.145),finish,.001,root)
        # A shallow folded lip catches light along each aluminium slat.
        # Run the profile through both reflective rows as on the full-size shutter.
        verts, faces = [], []
        for rib in range(1, 35):
            z = 1.045 + rib * 1.51 / 35
            face = len(verts)
            for depth, height in ((3.140, z-.002), (3.143, z), (3.140, z+.002)):
                verts.extend(((x-.474, depth, height), (x+.474, depth, height)))
            faces.extend(((face, face+2, face+3, face+1),
                          (face+2, face+4, face+5, face+3)))
        mesh = bpy.data.meshes.new("Rolled shutter lips")
        mesh.from_pydata(verts, [], faces)
        mesh.update()
        lips = bpy.data.objects.new("Rear shutter slat lips", mesh)
        bpy.context.collection.objects.link(lips)
        lips.parent = root
        lips.data.materials.append(shutter_finish)
        shutter_hardware((x,3.130,1.045),(0,1),.952,1.51)
    # Rear-facing work lights above the pump lockers, clear of the shutter tracks.
    for side in (-1,1):
        x = side*.99
        cube("Rear work light bracket",(x,3.07,2.59),(.14,.13,.055),METAL,.012,root)
        cube("Rear floodlight casing",(x,3.13,2.69),(.21,.12,.18),BLACK,.024,root)
        cube("Rear floodlight glazing",(x,3.193,2.69),(.175,.012,.146),GLASS_HI,.015,root)
        for row in (-1,0,1):
            for column in (-1,0,1):
                cube("Floodlight reflector",(x+column*.05,3.201,2.69+row*.04),
                     (.033,.008,.023),PAINT_WHITE,.006,root)
    # Each strip is cast across the face, turning back towards the two front corners.
    def fascia(name, half_width, height, thickness, depth, corner_rise, finish):
        rings = []
        for i in range(33):
            t = i / 16 - 1
            u = abs(t)
            x = t * half_width
            y = depth + .055*u*u + .14*u**6
            z = height + corner_rise * u**3
            rings.append([(x,y+dy,z+dz*thickness) for dy,dz in
                          ((.11,-.45),(.024,-.50),(0,-.38),(-.009,.12),
                           (.003,.38),(.026,.50),(.11,.42))])
        return profile_loft(name,rings,finish,root)

    # Raised shoulders sweep from the windscreen corners into the lamp aprons.
    for side in (-1,1):
        cheek = []
        for z,inner,outer,depth in (
            (.78,.65,1.065,-3.098),(.85,.62,1.095,-3.122),
            (1.08,.66,1.105,-3.115),(1.18,.72,1.102,-3.093),
            (1.39,.80,1.103,-3.070),(1.54,.85,1.10,-3.048),
            (1.67,.92,1.09,-3.014),(1.74,1.00,1.075,-2.964)):
            cheek.append([(side*x,depth+dy,z) for x,dy in (
                (inner,.12),(inner,.022),(inner+.016,.003),
                (inner+(outer-inner)*.65,.018),(outer-.016,.056),
                (outer,.094),(outer,.24),(inner,.24))])
        profile_loft("Sculpted cab corner apron",cheek,cab_red,root)
        seal = []
        for z,w,y in ((1.78,1.099,-2.937),(2.04,1.09,-2.873),(2.425,1.06,-2.765)):
            seal.append([(side*w*x,y+dy,z) for x,dy in
                         ((.91,.014),(.94,.033),(.978,.079),(.994,.128),
                          (.985,.145),(.95,.075),(.91,.045))])
        profile_loft("Wraparound windshield perimeter",seal,RUBBER,root)
    fascia("Windshield scuttle",1.075,1.769,.044,-2.997,.022,RUBBER)
    fascia("Cab brow over windshield",1.05,2.465,.08,-2.84,.012,BLACK)
    fascia("Reflective eyebrow",1.035,2.512,.030,-2.828,.012,PAINT_YELLOW)
    fascia("Upper cab pressing",1.09,1.64,.25,-3.065,.085,cab_red)
    radiator_finish = material("Shadowed radiator core",(.012,.014,.016),.03,.87)
    for z,width,depth in ((1.37,.80,-3.086),(1.124,.73,-3.115)):
        # A rolled trapezoidal mouth surrounds a perforated, recessed insert.
        outline = [(-.89,-.088),(-.82,-.108),(.82,-.108),(.89,-.088),
                   (.995,.060),(1,.085),(.965,.100),(-.965,.100),
                   (-1,.085),(-.995,.060)]
        rings = []
        for scale_x,scale_z,setback in ((1,1,.010),(.985,.95,-.008),
                                        (.960,.80,-.010),(.925,.72,.033)):
            rings.append([(x*width*scale_x,depth+setback+.052*x*x,
                           z+dz*scale_z+.015*x*x) for x,dz in outline])
        profile_loft("Rolled intake surround",rings,RUBBER,root,close_ends=False)
        back = [[(x*width*.94,depth+dy+.052*x*x,z+dz*.76+.015*x*x)
                 for x,dz in outline] for dy in (.045,.055)]
        radiator = profile_loft("Radiator shadow behind screen",back,radiator_finish,root)
        for face in radiator.data.polygons:
            face.use_smooth = False
        stripe = []
        for station in range(25):
            x = width*.81*(station/12-1)
            curve = (x/width)**2
            y = depth-.014+.052*curve
            h = z-.098+.015*curve
            stripe.append([(x,y+dy,h+dz) for dy,dz in
                           ((0,-.008),(0,.008),(.003,.008),(.003,-.008))])
        profile_loft("Reflective lower intake rim",stripe,PAINT_YELLOW,root)
        vertices,faces=[],[]
        pitch=.032
        for row in range(4):
            h=z-.045+row*.029
            for col in range(-26,27):
                center=(col+.5*(row%2))*pitch
                if abs(center)+pitch/2 > width*(.85+.026*row): continue
                base=len(vertices)
                for radius in (.018,.014):
                    for j in range(6):
                        angle=math.tau*j/6+math.pi/2
                        x=center+radius*math.cos(angle)
                        vertices.append((x,depth+.027+.052*(x/width)**2,
                                         h+radius*math.sin(angle)+.015*(x/width)**2))
                for j in range(6):
                    k=(j+1)%6
                    faces.append((base+j,base+k,base+6+k,base+6+j))
        mesh=bpy.data.meshes.new("Stamped intake screen")
        mesh.from_pydata(vertices,[],faces)
        mesh.materials.append(DARK)
        insert=bpy.data.objects.new("Honeycomb intake insert",mesh)
        bpy.context.collection.objects.link(insert)
        insert.parent=root
    for side in (-1,1):
        # The marker follows the sloping cheek below the windscreen.
        for name, finish, lens in (("Upper corner marker housing", BLACK, False),
                                   ("Upper corner running lamp", HEADLAMP, True)):
            sections = []
            for u, z, height in ((.755,1.632,.012),(.79,1.652,.057),
                                 (.875,1.680,.084),(.995,1.692,.108),(1.05,1.684,.080)):
                depth = -3.079 + .105*((u-.755)/.295)**2
                if lens:
                    z += height*.18
                    height *= .32
                    depth -= .009
                sections.append([(side*u,depth+dy,z+height*dz) for dy,dz in
                                 ((0,-.45),(-.004,.29),(.004,.5),(.027,.45),(.027,-.5))])
            profile_loft(name, sections, finish, root)
    badge = text_obj("Raised Skania grille lettering","SKANIA",(0,-3.082,1.585),.19,METAL,root=root)
    badge.location.x = -(min(v.co.x for v in badge.data.vertices) + max(v.co.x for v in badge.data.vertices)) * .5
    badge.rotation_euler = (math.pi/2,0,0)
    for x in [-.56,.56]:
        cube("Beacon mounting foot",(x,-2.32,2.634),(.119,.191,.077),RUBBER,.018,root)
    layers=[]
    for z,w,d in [(2.665,.807,.115),(2.677,.847,.144),(2.709,.852,.147),
                  (2.786,.832,.137),(2.803,.799,.109)]:
        ring=[]
        for i in range(48):
            angle=i*math.tau/48
            c,sn=math.cos(angle),math.sin(angle)
            ring.append((w*math.copysign(abs(c)**.40,c),
                         -2.32+d*math.copysign(abs(sn)**.40,sn),z))
        layers.append(ring)
    profile_loft("Beacon mounting tray",layers[:3],DARK,root)
    lens=material("Blue polycarbonate beacon cover",(.12,.35,.82),.08,.14)
    next(node for node in lens.node_tree.nodes if node.type=="BSDF_PRINCIPLED").inputs["Alpha"].default_value=.25
    lens.surface_render_method="BLENDED"
    shell=[[(x*1.025,-2.32+(y+2.32)*1.19,z+.009) for x,y,z in ring]
           for ring in layers[2:]]
    profile_loft("Blue beacon lens",shell,lens,root)
    smoked_blue=material("Unlit blue LED optics",(.012,.063,.31),.18,.20)
    for side in [-1,1]:
        lit_dies=[]
        for i in range(5):
            x=side*(.224+.125*i)
            for face in [-1,1]:
                y=-2.32+face*(.119-.010*(abs(x)/.8)**4)
                cube("Blue optic bezel",(x,y,2.749),(.118,.025,.065),smoked_blue,.010,root)
                for offset in (-.036,0,.036):
                    loc=(x+offset,y+face*.014,2.750)
                    cube("LED reflector",loc,(.027,.008,.036),METAL,.004,root)
                    lit_dies.append(cube("LED emitter",(loc[0],loc[1]+face*.005,loc[2]),
                                         (.021,.004,.028),BLUE_LAMP,.002,root))
        # Switch all thirty dies on this half together in the game.
        bpy.ops.object.select_all(action="DESELECT")
        for die in lit_dies:
            die.select_set(True)
        bpy.context.view_layer.objects.active=lit_dies[0]
        bpy.ops.object.join()
        lit_dies[0].name="FlashBlue_Left" if side<0 else "FlashRed_Right"
    cube("Forward scene lamp surround",(0,-2.462,2.747),(.300,.025,.080),BLACK,.009,root)
    cube("Forward scene lamp diffuser",(0,-2.479,2.747),(.276,.014,.048),HEADLAMP,.006,root)
    for x in (-.82,.82):
        cube("Deck rail",(x,1.06,2.728),(.046,3.52,.049),METAL,.014,root)
        for y in (-.62,.50,1.66,2.78):
            cube("Deck stanchion",(x,y,2.645),(.041,.04,.164),DARK,.008,root)
    for y in (-.58,2.56):
        cube("Ladder carrier",(0,y,2.64),(1.37,.106,.152),DARK,.018,root)
    for level in range(2):
        w=.33-.052*level
        z=2.747+.088*level
        for side in (-1,1):
            cube("Extension ladder stile",(side*w,.77,z),(.042,4.14,.070),METAL,.009,root)
        for i in range(14):
            cube("Extension ladder rung",(0,-1.17+i*.297+.09*level,z),
                 (2*w,.042,.030),METAL,.008,root)
    cover=material("Clear fire engine lamp cover",(.70,.83,.87),.03,.09)
    shader=next(node for node in cover.node_tree.nodes if node.type=="BSDF_PRINCIPLED")
    shader.inputs["Alpha"].default_value=.19
    projector_glass = material("Clear graphite projector lens",(.27,.34,.37),.38,.12)
    headlamp_pockets = []
    for x in (-0.82, 0.82):
        side=1 if x>0 else -1
        # The lens cluster wraps back towards the cab corner. Set each
        # reflector behind a rolled chrome edge in a common rubber housing.
        def light_ring(cx,cz,w,h,depth,corner=.24):
            ring=[]
            for i in range(32):
                angle=i*math.tau/32
                c,sn=math.cos(angle),math.sin(angle)
                u=cx+.5*w*math.copysign(abs(c)**corner,c)
                sweep=(u-.86)/.24
                z=cz-.445+.035*sweep+.5*h*(1-.25*sweep)*math.copysign(abs(sn)**corner,sn)
                ring.append((side*u,depth-.060+.080*((u-.63)/.48)**2,z))
            return ring
        pocket = [light_ring(.866,1.424,.499,.302,d) for d in (-3.24,-2.94)]
        headlamp_pockets.append(profile_loft("Lamp pocket cutter",pocket,RUBBER,root))
        shell=[light_ring(.866,1.424,w,h,d) for w,h,d in
               ((.490,.296,-2.93),(.494,.297,-3.030),(.482,.280,-3.052),(.455,.246,-3.044))]
        profile_loft("Cab headlamp seal",shell,RUBBER,root)
        for cx,w in ((.763,.179),(.945,.156)):
            optic=[light_ring(cx,1.448,w*f,.155*f,d,corner=.58) for f,d in
                   ((1,-3.050),(.94,-3.061),(.81,-3.047),(.63,-3.027))]
            profile_loft("Cab reflector",optic,METAL,root,close_ends=False)
            profile_loft("Cab projector",[
                light_ring(cx,1.448,w*f,.155*f,d,corner=.58) for f,d in
                ((.64,-3.036),(.52,-3.052),(.26,-3.061))],projector_glass,root)
        cover_rings=[light_ring(.861,1.447,w,h,d) for w,h,d in
                     ((.469,.252,-3.060),(.465,.248,-3.067),(.452,.239,-3.073))]
        profile_loft("Swept transparent headlamp cover",cover_rings,cover,root)
        amber=material("Amber cab signal",(.88,.235,.012),.12,.23)
        profile_loft("Cab amber signal",[
            light_ring(.865,1.335,w,h,d) for w,h,d in
            ((.369,.030,-3.052),(.365,.028,-3.055),(.352,.023,-3.058))],amber,root)
        x = side*1.075
        cube("Rear combination lamp seal",(x,3.071,1.47),(.148,.088,.435),RUBBER,.019,root)
        for label,z,height,finish in (
                ("Rear indicator lens",1.610,.105,amber),
                ("Tail lamp",1.468,.167,TAIL_LAMP),
                ("Reversing lens",1.319,.097,GLASS_HI)):
            rear_prismatic_lens(label, x, z, height, finish, root)
    bumper=[]
    for x in (-1.13,-1.11,-1.04,-.88,-.69,-.54,0,.54,.69,.88,1.04,1.11,1.13):
        u=abs(x)/1.13
        setback=.031*u*u+.235*u**7
        low=.355+.115*u**5
        fold=max(0,min(1,(abs(x)-.54)/.22))
        belt=.676+.075*u**3
        bumper.append([(x,-3.115+setback+dy,z) for dy,z in
                       ((.265,low+.029),(.064,low),(.015,low+.025),(-.012,low+.078),
                        (-.014,belt-.052),(.037*fold-.014,belt-.012),
                        (.038*fold-.014,belt+.010),(-.015,belt+.032),
                        (-.018,.934),(-.007,1.013),(.021,1.052),(.060,1.062),(.264,1.030))])
    bumper_shell = profile_loft("Wraparound crew cab bumper",bumper,cab_red,root)
    aprons = [part for part in root.children if part.name.startswith("Sculpted cab corner apron")]
    for pocket in headlamp_pockets:
        for panel in [bumper_shell, *aprons]:
            cut = panel.modifiers.new("Recess for lamp housing", "BOOLEAN")
            cut.object = pocket
            cut.operation = "DIFFERENCE"
            bpy.context.view_layer.objects.active = panel
            bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(pocket, do_unlink=True)
    # Lower cooling mouth flares towards the number plate.
    for name, finish, levels in (
            ("Lower intake surround", RUBBER, ((.565,.746),(.588,.765),(.804,.630),(.817,.610))),
            ("Lower intake grille", DARK, ((.641,.695),(.657,.684))),
            ("Lower intake grille", DARK, ((.719,.651),(.735,.640))),
            ("Lower intake reflective lip", PAINT_YELLOW, ((.818,.613),(.840,.598)))):
        sections = []
        for z, half_width in levels:
            depth = -3.149 if finish == RUBBER else -3.163
            sections.append([(u*half_width,depth+.027*u*u+offset,z)
                             for u,offset in ((-1,.021),(-1,.005),(-.85,0),(0,0),
                                              (.85,0),(1,.005),(1,.021),(0,.024))])
        profile_loft(name,sections,finish,root)
    for side in (-1,1):
        # A recessed foothold below each lamp gives the crew access to the windscreen.
        x = side*.84
        cube("Cab bumper foothold recess",(x,-3.063,1.127),(.35,.105,.131),RUBBER,.032,root)
        cube("Cab bumper step lip",(x,-3.105,1.073),(.365,.116,.027),METAL,.011,root)
        for rib in range(5):
            cube("Step tread ridge",(x+(rib-2)*.061,-3.114,1.088),
                 (.018,.071,.009),DARK,.003,root)
        cube("Fog light seal",(side*.862,-3.076,.606),(.210,.042,.128),BLACK,.023,root)
        cube("Fog lens",(side*.862,-3.101,.606),(.164,.016,.077),GLASS_HI,.018,root)
    cube("Number plate plinth",(0,-3.147,.49),(.49,.035,.13),BLACK,.014,root)
    cube("Reflective registration plate",(0,-3.170,.49),(.46,.010,.104),PAINT_WHITE,.007,root)
    cube("Rear registration plinth",(-.63,3.15,.89),(.51,.026,.137),BLACK,.009,root)
    cube("Rear registration plate",(-.63,3.168,.89),(.484,.012,.114),PAINT_WHITE,.005,root)
    plate_blue = material("Registration blue", (.015,.07,.43), .12, .35)
    for center_x, face_y, center_z, facing in ((0,-3.175,.49,1),(-.63,3.174,.89,-1)):
        heading = 0 if facing == 1 else math.pi
        strip_x = center_x - facing*.204
        cube("Blue country band",(strip_x,face_y-facing*.001,center_z),
             (.039,.003,.096),plate_blue,.002,root)
        for label, value, x, z, size, ink in (
                ("Fleet registration","SJT 711",center_x-facing*.161,center_z-.030,.078,BLACK),
                ("Country code","S",strip_x-facing*.008,center_z-.035,.023,PAINT_WHITE)):
            letters = text_obj(label,value,(x,face_y-facing*.006,z),size,ink,root=root)
            letters.rotation_euler = (math.pi/2,0,heading)
        for star in range(12):
            angle = star*math.tau/12
            cube("European plate emblem",
                 (strip_x+.011*math.cos(angle),face_y-facing*.004,center_z+.018+.011*math.sin(angle)),
                 (.003,.002,.003),PAINT_YELLOW,0,root)
    cube("Rear step crossmember",(0,3.05,.81),(2.19,.16,.14),DARK,.022,root)
    for side in (-1,1):
        x=side*.65
        for offset in (-.31,.31):
            bracket=cube("Footboard support",(x+offset,3.18,.718),
                         (.042,.37,.050),METAL,.006,root)
            bracket.rotation_euler.x=-.40
        # Open galvanized grating lets the ground show through the steps.
        bars=[]
        for edge in (-1,1):
            bars.append(cube("Step channel",(x,3.30+edge*.148,.681),(.92,.020,.045),METAL,.007,root))
        for i in range(23):
            bars.append(cube("Step bearing bar",(x+(i-11)*.041,3.30,.683),
                 (.012,.286,.038),METAL,.003,root))
        for i in range(4):
            bars.append(cube("Step cross rod",(x,3.20+i*.066,.693),(.91,.009,.012),METAL,.003,root))
        bpy.ops.object.select_all(action="DESELECT")
        for bar in bars:
            bar.select_set(True)
        bpy.context.view_layer.objects.active=bars[0]
        bpy.ops.object.join()
        bars[0].name="Galvanized rear footboard"
    cube("Tow hitch flange",(0,3.143,.79),(.23,.065,.194),cab_red,.014,root)
    for x in [-.076,.076]:
        for z in [.729,.851]:
            bolt = cylinder("Tow flange bolt",(x,3.183,z),.018,.020,METAL,False,6,root)
            bolt.rotation_euler.x = math.pi/2
    cube("Trailer socket bracket",(.191,3.152,.79),(.116,.052,.121),DARK,.009,root)
    for y, radius, finish, name in [
            (3.189,.047,METAL,"Trailer socket rim"),
            (3.207,.040,BLACK,"Trailer socket weather cap")]:
        socket = cylinder(name,(.191,y,.79),radius,.018,finish,False,32,root)
        socket.rotation_euler.x = math.pi/2
    cube("Trailer socket cap hinge",(.191,3.206,.833),(.043,.023,.017),DARK,.004,root)
    cube("Tow hitch drawbar",(0,3.255,.743),(.12,.246,.065),cab_red,.015,root)
    cylinder("Tow ball neck",(0,3.344,.800),.024,.099,METAL,False,24,root)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=.043,
                                         location=(0,3.344,.856))
    ball=bpy.context.object
    ball.name="Tow ball"
    ball.data.materials.append(METAL)
    for polygon in ball.data.polygons:
        polygon.use_smooth=True
    attach(ball,root)
    # Lengthen the equipment bay between axles without distorting the wheels.
    bpy.context.view_layer.update()
    for part in root.children:
        frame=part.matrix_local.copy()
        inverse=frame.inverted()
        for vertex in part.data.vertices:
            point=frame@vertex.co
            point.z += .46 * max(0,min(1,(point.z-1.75)/.75))
            point.y+=.82*max(0,min(1,(point.y+1.44)/1.98))-.41
            vertex.co=inverse@point
    shape_fire_cab_roof(root)
    fit_fire_cab_headliner(root)
    fit_fire_speedometer(root)
    return root

def profile_loft(name, rings, finish, parent, close_ends=True):
    """Join a sequence of equal-sized cross sections into a smooth surface."""
    import bmesh
    width = len(rings[0])
    vertices = [point for ring in rings for point in ring]
    faces = []
    for row in range(len(rings)-1):
        for i in range(width):
            k=row*width
            j=(i+1)%width
            faces.append((k+i,k+j,k+width+j,k+width+i))
    if close_ends:
        faces.extend([tuple(reversed(range(width))),tuple(range(len(vertices)-width,len(vertices)))])
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],faces)
    bm=bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(finish)
    for poly in mesh.polygons:
        poly.use_smooth=True
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent=parent
    return obj

def make_bmw(color, name="BMV X5i", *, patrol=False):
    detailed_cabin = patrol or color == PAINT_BLACK
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type = "CUBE"
    # Front is -Y. The main shell uses a series of cross-sections for a tapered nose,
    # broad shoulder, rounded roof corners and a subtly pinched rear.
    def panel_section(y, width, bottom, shoulder, crown):
        arch = max(math.exp(-((y-axle)/.55)**2) for axle in (-1.52,1.55))
        hip = shoulder - .21 + .10*arch + .035*y
        approach = max(0,min(1,(-y-1.76)/.64))
        sill = bottom-.23 + .242*approach**2*(3-2*approach)
        # Curve inward below the belt and return to the sill. The hood ridge
        # narrows towards the nose and disappears under the windshield.
        ridge = .43+.28*max(0,min(1,(y+2.5)/1.36))
        hood = max(0,min(1,(-y-.98)/.35))
        nose_blend = max(0,min(1,(y+2.50)/.34))
        relief = hood*(.016+.075*nose_blend*(3-2*nose_blend)*nose_blend**2)
        door = math.exp(-((y-.08)/1.0)**4)
        scallop = .048*door
        flank = [(.84,sill),(.945,sill+.035),(.98,sill+.10),
                 (.967-.45*scallop,sill+.17+.095*door),
                 (.951-scallop+.017*arch,hip-.29+.047*door),
                 (.983-.21*scallop,hip-.10),(1,hip-.023),
                 (1,hip),(.994,hip+.035),(.974,shoulder-.025),
                 (.926,shoulder+.025),(.83,crown-.005),
                 (ridge+.062,crown+.009),(ridge+.024,crown+.014+.72*relief),
                 (ridge,crown+.014+relief),(ridge-.05,crown+.016+.91*relief),
                 (ridge*.56,crown+.024+.70*relief)]
        return ([(-x*width,y,z) for x,z in flank] + [(0,y,crown+.035+.64*relief)] +
                [(x*width,y,z) for x,z in reversed(flank)])

    body = mesh_from_rings("X5 M60i continuous sculpted body", [
        (-2.50, .86, .66, 1.37, 1.485), (-2.48, .94, .65, 1.38, 1.49),
        (-2.43, 1.005, .635, 1.42, 1.515), (-2.31, 1.06, 0.61, 1.48, 1.55),
        (-1.88, 1.09, 0.62, 1.49, 1.56), (-1.52, 1.13, 0.61, 1.51, 1.59), (-1.20, 1.12, 0.61, 1.52, 1.60),
        (-0.28, 1.12, 0.61, 1.53, 1.57), (0.82, 1.11, 0.62, 1.51, 1.55),
        (1.75, 1.07, 0.64, 1.45, 1.48), (2.28, 1.04, 0.62, 1.56, 1.61),
        (2.455, .985, .665, 1.53, 1.585), (2.48, 0.97, 0.67, 1.52, 1.58),
    ], color, root, 0, section=panel_section)
    # Smooth the longitudinal control cage before cutting the four wheel wells.
    curvature = body.modifiers.new("Formed body panels", "SUBSURF")
    curvature.levels = 2
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=curvature.name)
    # The glasshouse has a high roof, sharply raked windshield, and descending rear screen.
    # Loft a continuous glazed cabin; the aperture frames share its vertices.
    privacy = material("Graphite solar glass", (.018,.030,.036), .43,.13)
    vertices, faces, slots = [], [], []
    levels = [0,.045,.10,.19,.31,.80,.90,.96,1]
    def roof_height(x,y):
        return 2.32-.069*(x/.82)**2-.030*((y-.62)/1.24)**2

    for t in levels:
        width = 1.00 - .105*t - .075*t*t
        front = -1.20 + .75*t + .12*t**9
        rear = 2.38 - .42*t - .16*t**5
        corners = [(front+.13,-width),(front+.055,-width*.95),(front,-width*.80),
                   (front-.055,0),(front,width*.80),(front+.055,width*.95),(front+.13,width)]
        # The quarter-light narrows into the D-pillar at both ends. Pull its
        # lower corner forward to form the return visible in the side photo.
        quarter_end = .875 - .065*max(0,1-t/.30)**2 - .036*t**6
        side_stations = [.31,.34,.64,.665,quarter_end]
        corners += [(front+(rear-front)*u,width) for u in side_stations]
        corners += [(rear-.17,width),(rear-.07,width*.96),(rear,width*.81),
                    (rear+.035,0),(rear,-width*.81),(rear-.07,-width*.96),(rear-.17,-width)]
        corners += [(front+(rear-front)*u,-width) for u in reversed(side_stations)]
        for y,x in corners:
            # The D-pillars tuck in above the haunch. Lift the sill
            # towards the rear quarter window and crown the roof across its width.
            quarter = max(0,min(1,(y-.85)/1.45))
            x *= 1-.065*quarter**2
            crown = .068*t*(1-(x/width)**2)
            vertices.append((x,y,1.52+.73*t+.095*quarter**2*(1-t)+crown-.030*t**3*((y-.62)/1.24)**2))
    n=len(corners)
    for row in range(len(levels)-1):
        for k in range(n):
            q=(k+1)%n
            faces.append((row*n+k,row*n+q,(row+1)*n+q,(row+1)*n+k))
            glazed = .10 <= levels[row] < .90 and k in (2,3,6,8,10,14,15,19,21,23)
            rear_glass = k in (8,10,14,15,19,21)
            slots.append((2 if rear_glass and detailed_cabin else 1) if glazed else 0)
    # Fill the roof with crowned courses, keeping the perimeter welded to the pillars.
    top_start=(len(levels)-1)*n
    previous=top_start
    for scale in (.76,.48,.19):
        current=len(vertices)
        for x,y,_ in vertices[top_start:top_start+n]:
            x*=scale
            y=.62+(y-.62)*scale
            vertices.append((x,y,roof_height(x,y)))
        for k in range(n):
            q=(k+1)%n
            faces.append((previous+k,previous+q,current+q,current+k))
            slots.append(0)
        previous=current
    faces.append(tuple(range(previous,previous+n)))
    slots.append(0)
    mesh=bpy.data.meshes.new("Continuous glazing and pillars")
    mesh.from_pydata(vertices,[],faces)
    mesh.materials.append(color)
    mesh.materials.append(privacy)
    if detailed_cabin:
        rear_tint=privacy.copy()
        rear_tint.name="Rear privacy glazing"
        rear_tint.surface_render_method="BLENDED"
        rear_shader = next(node for node in rear_tint.node_tree.nodes if node.type=="BSDF_PRINCIPLED")
        rear_shader.inputs["Base Color"].default_value = (.009,.017,.021,1)
        rear_shader.inputs["Alpha"].default_value = .85
        mesh.materials.append(rear_tint)
    mesh.polygons.foreach_set("material_index",slots)
    for face in mesh.polygons: face.use_smooth=True
    shell=bpy.data.objects.new("Roof and cabin",mesh)
    bpy.context.collection.objects.link(shell)
    shell.parent=root
    bpy.context.view_layer.update()
    windshield = shell.evaluated_get(bpy.context.evaluated_depsgraph_get())
    def windshield_point(x,z):
        hit,point,_,_=windshield.ray_cast((x,-3,z),(0,1,0))
        if not hit:
            raise ValueError("Wiper outside windshield")
        return point
    for start,end,rise in ((-.78,-.04,.029),(-.03,.77,.057)):
        rings=[]
        for i in range(13):
            t=i/12
            point=windshield_point(start+(end-start)*t,1.608+rise*t+.009*math.sin(math.pi*t))
            width=.009+.005*math.sin(math.pi*t)
            rings.append([(point.x,point.y-.014+dy,point.z+dz) for dy,dz in
                          ((-.009,0),(0,-width),(.006,0),(0,width))])
        profile_loft("Windscreen wiper blade",rings,RUBBER,root)
        arm=[]
        for t in (0,.35,.70,1):
            point=windshield_point(start+(end-start)*(.29+.28*t),1.573+(.048+rise*.57)*t)
            arm.append([(point.x,point.y-.020+dy,point.z+dz) for dy,dz in
                        ((-.007,-.008),(.007,-.008),(.007,.008),(-.007,.008))])
        profile_loft("Wiper arm",arm,DARK,root)
    if detailed_cabin:
        privacy.surface_render_method = "BLENDED"
        next(node for node in privacy.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .39
        leather = (material("Patrol seat fabric",(.068,.082,.091),.01,.79) if patrol else
                   material("Mocha leather",(.135,.069,.043),.02,.54))
        trim = material("Cabin charcoal", (.024,.025,.026), .02,.68)
        # Open the body between the bulkhead and rear shelf so the
        # footwells and cushions are visible below the window line.
        cavity=cube("Cabin opening tool",(0,.43,1.93),(1.80,2.94,1.62),trim,.115,root)
        cut=body.modifiers.new("Cabin tub","BOOLEAN")
        cut.object=cavity
        cut.operation="DIFFERENCE"
        cut.material_mode="TRANSFER"
        bpy.context.view_layer.objects.active=body
        bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(cavity,do_unlink=True)
        cube("Carpeted floor",(0,.43,1.144),(1.61,2.71,.042),trim,.02,root)
        cube("Centre tunnel",(0,-.27,1.335),(.30,.98,.35),trim,.065,root)
        cube("Leather armrest",(0,-.035,1.53),(.32,.48,.105),leather,.048,root)
        cube("Rear load cover",(0,1.78,1.51),(1.75,.70,.08),trim,.035,root)
        for side in (-1,1):
            cube("Interior door armrest",(side*.825,.28,1.43),(.13,2.22,.10),trim,.045,root)
        dash_sections=[]
        for x in (-.87,-.79,-.53,-.21,.09,.36,.60,.79,.87):
            taper=abs(x/.87)**3
            dash_sections.append([(x,y+.06*taper,z-.034*taper) for y,z in
                ((-.97,1.63),(-.88,1.703),(-.68,1.707),(-.54,1.674),
                 (-.544,1.615),(-.58,1.574),(-.71,1.535),(-.94,1.55))])
        profile_loft("Padded dashboard",dash_sections,trim,root)
        display_glass=material("Instrument display glass",(.012,.024,.032),.27,.19)
        display_sections=[]
        for i in range(17):
            x=-.26+i*.98/16
            y=-.716+.077*((x-.38)/.65)**2
            display_sections.append([(x,y+dy,z) for dy,z in
                    ((-.022,1.704),(-.034,1.843),(-.013,1.855),(.003,1.846),
                     (.016,1.719),(.010,1.704))])
        profile_loft("Curved instrument screen",display_sections,display_glass,root)
        for side in (-1,1):
            vent=cube("Dashboard vent",(side*.697,-.532,1.641),(.195,.018,.041),BLACK,.008,root)
            for z in (1.635,1.646):
                cube("Vent blade",(side*.697,-.517,z),(.165,.017,.004),DARK,.001,root)
        for y in (.05,1.15):
            for x in (-.48,.48):
                cube("Seat cushion",(x,y-.185,1.36),(.52,.51,.16),leather,.073,root)
                rings=[]
                for z,w,depth,lean in ((1.33,.235,.083,-.045),(1.45,.272,.10,-.020),(1.57,.24,.09,0),(1.65,.27,.095,.005),
                        (1.82,.25,.073,.039),(1.92,.205,.061,.057),(1.95,.15,.047,.065)):
                    rings.append([(x+w*math.cos(i*math.tau/24),
                        y+lean+depth*math.sin(i*math.tau/24)-.056*abs(math.cos(i*math.tau/24))**3,z)
                        for i in range(24)])
                profile_loft("Contoured seat back",rings,leather,root)
                cube("Padded head restraint",(x,y+.043,2.015),(.32,.17,.19),leather,.062,root)
        bpy.ops.mesh.primitive_torus_add(major_radius=.157,minor_radius=.021,
            major_segments=36,minor_segments=10,location=(.48,-.37,1.77),
            rotation=(math.radians(110),0,0))
        wheel = bpy.context.object
        wheel.name = "Steering wheel rim"
        wheel.parent = root
        wheel.data.materials.append(trim)
        for face in wheel.data.polygons:
            face.use_smooth=True
        # Work in the tilted plane of the rim so the thumb controls stay
        # flush with the spokes and face the seated driver.
        def steering_point(x,h,depth):
            return (.48+x,-.37-.342*h+.940*depth,1.77+.940*h+.342*depth)
        hub=[]
        for depth,radius in ((-.027,.056),(-.017,.072),(.010,.073),(.027,.065),(.033,.052)):
            hub.append([steering_point(radius*math.cos(i*math.tau/32),
                radius*.89*math.sin(i*math.tau/32),depth) for i in range(32)])
        profile_loft("Steering wheel airbag pad",hub,trim,root)
        for side in (-1,1):
            arm=[]
            for x,h,thickness in ((.047,-.009,.025),(.081,-.006,.028),
                                   (.113,-.002,.022),(.153,.008,.015)):
                arm.append([steering_point(side*x,h+thickness*math.sin(i*math.tau/12),
                           .006+.014*math.cos(i*math.tau/12)) for i in range(12)])
            profile_loft("Steering wheel thumb control pod",arm,BLACK,root)
            for x in (.084,.109):
                for h in (-.012,.004):
                    key=cube("Steering wheel thumb key",steering_point(side*x,h,.021),
                             (.020,.005,.011),trim,.002,root)
                    key.rotation_euler.x=math.radians(20)
        if patrol:
            cube("Dispatch screen mount",(.14,-.68,1.54),(.075,.10,.17),trim,.015,root)
            cube("Dispatch screen bezel",(.14,-.68,1.65),(.34,.046,.20),BLACK,.019,root)
            cube("Dispatch map display",(.14,-.654,1.65),(.304,.009,.162),GLASS_HI,.004,root)
        for side in (-1,1):
            lower=[]
            for h,x,w in ((-.045,.034,.012),(-.073,.029,.010),(-.116,.017,.009),(-.150,.012,.012)):
                lower.append([steering_point(side*x+w*math.cos(i*math.tau/12),h,
                             .009*math.sin(i*math.tau/12)) for i in range(12)])
            profile_loft("Steering wheel lower fork",lower,DARK,root)
    spoiler_sections=[]
    for x in (-.83,-.77,-.52,0,.52,.77,.83):
        end=(abs(x)/.83)**3
        spoiler_sections.append([(x,y-.085*end,z-.028*end) for y,z in
                                 ((1.72,2.224),(1.76,2.281),(1.91,2.294),
                                  (2.056,2.264),(2.044,2.222),(1.94,2.215))])
    profile_loft("Tailgate roof spoiler",spoiler_sections,color,root)
    cube("Centre brake lamp",(0,2.04,2.25),(.62,.015,.022),TAIL_LAMP,.007,root)
    rear_screen = shell.evaluated_get(bpy.context.evaluated_depsgraph_get())
    def rear_screen_depth(x, z):
        hit, point, _, _ = rear_screen.ray_cast((x,3,z),(0,-1,0))
        if not hit:
            raise ValueError("Rear wiper outside glazing")
        return point.y

    # A tapered pivot cover carries the arm above the spring-curved blade.
    for name, finish, stations in [
        ("Tailgate wiper blade",RUBBER,[
            (-.22,1.669,.007,.012),(-.10,1.675,.012,.014),
            (.17,1.692,.014,.015),(.40,1.699,.011,.014),(.48,1.70,.006,.011)]),
        ("Tailgate wiper arm",material("Graphite wiper moulding",(.012,.014,.016),.0,.62),[
            (-.034,1.652,.018,.021),(-.009,1.657,.035,.047),
            (.05,1.663,.033,.051),(.10,1.678,.022,.041),
            (.18,1.692,.015,.033),(.24,1.695,.010,.025)])]:
        rings=[]
        for x,z,width,stand in stations:
            ring=[]
            for k in range(12):
                angle=math.tau*k/12
                height=z+width*math.sin(angle)
                depth=rear_screen_depth(x,height)+stand*(1+.45*math.cos(angle))
                ring.append((x,depth,height))
            rings.append(ring)
        profile_loft(name,rings,finish,root)

    # The tailgate skin sweeps out beneath the glass, folds above the
    # plate pocket, then returns to the bumper with a shallow lower crease.
    vertices, faces = [], []
    columns = [-1,-.94,-.72,-.51,-.43,-.39,0,.39,.43,.51,.72,.94,1]
    for z, width, bulge, pocket in [
            (.79,.73,.008,0),(.84,.78,.024,0),(.94,.81,.051,0),
            (1.03,.83,.056,0),(1.08,.84,.063,.018),(1.12,.85,.066,.050),
            (1.29,.86,.065,.050),(1.33,.86,.077,.016),
            (1.35,.86,.081,0),(1.39,.85,.063,0),(1.43,.84,.035,0),
            (1.51,.84,.025,0),(1.55,.82,.005,0)]:
        start = len(vertices)
        for i,u in enumerate(columns):
            shoulder = max(0,min(1,(.51-abs(u))/.12))
            y = 2.483 + bulge*(1-u*u) - pocket*shoulder
            vertices.append((width*u,y,z+.014*u*u))
            if start and i:
                n = start+i
                count = len(columns)
                faces.append((n-count-1,n-1,n,n-count))
    mesh = bpy.data.meshes.new("Pressed tailgate outer skin")
    mesh.from_pydata(vertices,[],faces)
    mesh.materials.append(color)
    for face in mesh.polygons:
        face.use_smooth=True
    hatch = bpy.data.objects.new("Split tailgate",mesh)
    bpy.context.collection.objects.link(hatch)
    hatch.parent=root
    bpy.context.view_layer.update()
    hatch_skin = hatch.evaluated_get(bpy.context.evaluated_depsgraph_get())
    cube("Plate frame",(0,2.509,1.204),(.59,.012,.154),BLACK,.005,root)
    cube("Registration plate",(0,2.517,1.204),(.56,.007,.132),PAINT_WHITE,.003,root)
    # Project the gaps onto the pressed door skin at each height.
    bpy.context.view_layer.update()
    surface = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    def skin_point(side, y, z):
        hit, point, _, _ = surface.ray_cast((side*2,y,z),(-side,0,0))
        if not hit:
            raise ValueError(f"Door outline missed body at {y}, {z}")
        return (point.x+side*.003,y,z)

    handle_cutters=[]
    for side in (-1, 1):
        # Follow the curved outer hood edge from the lamp to the cowl.
        edge_points, quads = [], []
        for station in range(33):
            t = station/32
            y = -2.43 + 1.36*t
            x = .665+.265*math.sin(t*math.pi/2)
            for offset in (-.004,.004):
                hit, point, normal, _ = surface.ray_cast((side*(x+offset),y,2.5),(0,0,-1))
                if not hit:
                    raise ValueError("Bonnet seam outside front wing")
                edge_points.append(point + normal*.002)
            if station:
                k = 2*station
                face = (k-2,k-1,k+1,k)
                quads.append(face if side>0 else face[::-1])
        seam_mesh = bpy.data.meshes.new("Bonnet edge")
        seam_mesh.from_pydata(edge_points,[],quads)
        seam_mesh.materials.append(RUBBER)
        seam = bpy.data.objects.new("Bonnet shut line",seam_mesh)
        bpy.context.collection.objects.link(seam)
        seam.parent=root
        # Form the wheel opening flange from the skin before the bore is cut.
        for axle in (-1.52,1.55):
            vertices, faces = [], []
            for station in range(49):
                angle = .15+(math.pi-.30)*station/48
                for radius, proud in ((.542,.001),(.548,.012),(.568,.019),
                                      (.594,.012),(.618,.001)):
                    y = axle+radius*math.cos(angle)
                    z = .48+radius*math.sin(angle)
                    x,_,_=skin_point(side,y,z)
                    vertices.append((x+side*proud,y,z))
                if station:
                    for j in range(4):
                        k=(station-1)*5+j
                        face=(k,k+1,k+6,k+5)
                        faces.append(face if side>0 else face[::-1])
            mesh=bpy.data.meshes.new("Pressed wheel arch flange")
            mesh.from_pydata(vertices,[],faces)
            mesh.materials.append(color)
            for poly in mesh.polygons:
                poly.use_smooth=True
            flange=bpy.data.objects.new("Painted wheel arch return",mesh)
            bpy.context.collection.objects.link(flange)
            flange.parent=root
        seams = [
            [(-1.03,1.47),(-1.05,1.31),(-1.00,1.12),(-.94,.88),(-.92,.57)],
            [(.12,1.50),(.11,1.30),(.10,1.10),(.09,.84),(.08,.57)],
            [(1.29,1.49),(1.32,1.32),(1.30,1.17),(1.17,1.03),(1.03,.89),(.97,.57)],
        ]
        vertices, faces = [], []
        for path in seams:
            start = len(vertices)
            for y,z in path:
                vertices.extend(skin_point(side,y+offset,z) for offset in (-.006,.006))
            for i in range(start,len(vertices)-2,2):
                quad = (i,i+1,i+3,i+2)
                faces.append(quad if side<0 else quad[::-1])
        mesh = bpy.data.meshes.new("Door shut lines")
        mesh.from_pydata(vertices,[],faces)
        mesh.materials.append(RUBBER)
        gaps = bpy.data.objects.new("Front and rear door gaps",mesh)
        bpy.context.collection.objects.link(gaps)
        gaps.parent=root
        for center_y in (-.035,1.12):
            x,_,z = skin_point(side,center_y,1.39)
            # Cut a shallow oval finger cup into the painted door panel.
            bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,
                location=(x+side*.014,center_y,z))
            tool=bpy.context.object
            tool.scale=(.049,.108,.053)
            bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
            for face in tool.data.polygons:
                face.use_smooth=True
            handle_cutters.append(tool)
            rings=[]
            for along,relief,width in ((-.131,.003,.010),(-.118,.012,.018),
                    (-.091,.029,.023),(-.051,.041,.021),(.026,.045,.018),
                    (.078,.039,.019),(.105,.022,.022),(.117,.003,.015)):
                y=center_y+along
                skin_x,_,_=skin_point(side,y,z)
                rings.append([(skin_x+side*(relief+.012*math.cos(i*math.tau/12)),y,
                    z+.013+width*math.sin(i*math.tau/12)) for i in range(12)])
            profile_loft("Painted bridge door pull",rings,color,root)
        sill_rings=[]
        for y,width,height in ((-1.04,.045,.04),(-.84,.085,.09),
                (-.38,.091,.082),(.50,.094,.075),(.94,.085,.09),(1.10,.047,.044)):
            sill_rings.append([(side*(1.025+dx*width),y,.56+dz*height)
                               for dx,dz in ((0,0),(.9,.1),(1,.46),(.66,1),(0,.94))])
        profile_loft("Formed sill extension",sill_rings,DARK,root)
        def mirror_ring(y,w,h):
            ring=[]
            for i in range(40):
                angle=math.tau*i/40
                c,sn=math.cos(angle),math.sin(angle)
                dx=w*math.copysign(abs(c)**.70,c)
                dz=h*math.copysign(abs(sn)**.69,sn)
                ring.append((side*(1.105+dx),y+.17*dx,1.68+dz+.09*dx))
            return ring
        cap=[mirror_ring(y,w,h) for y,w,h in ((-1.025,.040,.029),
             (-1.005,.092,.053),(-.965,.135,.072),(-.916,.155,.082),
             (-.855,.157,.081),(-.821,.151,.076))]
        profile_loft("Mirror painted housing",cap,color,root)
        lip=[cap[-1],mirror_ring(-.814,.151,.076),mirror_ring(-.806,.146,.073),
             mirror_ring(-.806,.138,.065),mirror_ring(-.814,.137,.064)]
        profile_loft("Mirror glass seal",lip,RUBBER,root,close_ends=False)
        glass=[lip[-1],mirror_ring(-.813,.110,.050),mirror_ring(-.812,.057,.028),
               mirror_ring(-.811,.0001,.0001)]
        profile_loft("Convex mirror glass",glass,
            material("Silvered mirror",(.62,.70,.74),.96,.085),root,close_ends=False)
        stalk=[]
        for x,y,z,w,h in ((.956,-.932,1.592,.057,.037),(.992,-.919,1.603,.051,.031),
                          (1.041,-.893,1.620,.039,.026),(1.075,-.882,1.641,.043,.033)):
            stalk.append([(side*x,y+w*math.cos(i*math.tau/16),z+h*math.sin(i*math.tau/16))
                          for i in range(16)])
        profile_loft("Swept mirror mount",stalk,BLACK,root)
        rail=[]
        for y,width,height in ((-.34,.018,.009),(-.29,.028,.033),(-.16,.034,.053),
                (.18,.035,.064),(.72,.034,.067),(1.32,.033,.055),
                (1.61,.030,.036),(1.72,.017,.009)):
            x=side*(.71-.027*((y-.65)/1.06)**2)
            z=roof_height(x,y)
            rail.append([(x+width*math.cos(i*math.tau/12),y,
                          z+height*.48+height*.52*math.sin(i*math.tau/12)) for i in range(12)])
        profile_loft("Integrated roof rail",rail,DARK,root)
        cube("M sport fender trim", (side * 1.08, -1.37, 1.03), (0.05, 0.18, 0.05), DARK, 0.045, root)
    def fascia(name, side, profile, y, mat, thickness=.11):
        # Return each outer corner towards the wheel arch in plan view.
        vertices = [(side*x, y+.085*x**3+depth, z)
                    for depth in (0,thickness) for x,z in profile]
        n = len(profile)
        faces = [tuple(range(n)), tuple(reversed(range(n,2*n)))]
        faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices,[],faces)
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(name,mesh)
        bpy.context.collection.objects.link(obj)
        obj.parent = root
        mesh.materials.append(mat)

    for side in (-1,1):
        kidney = [(.018,1.48),(.055,1.53),(.36,1.55),(.50,1.52),(.54,1.46),
                  (.52,1.24),(.47,1.16),(.38,1.12),(.07,1.12),(.034,1.16)]
        # Round the kidney perimeter and sweep a satin lip with a recessed
        # inner wall. Keep the rear edge tucked under the bonnet.
        outline = kidney
        for _ in range(2):
            rounded = []
            for i,(x,z) in enumerate(outline):
                nx,nz = outline[(i+1)%len(outline)]
                rounded.extend(((.75*x+.25*nx,.75*z+.25*nz),
                                (.25*x+.75*nx,.25*z+.75*nz)))
            outline = rounded
        vertices,faces = [],[]
        count = len(outline)
        for scale,y in ((1,-2.493),(.996,-2.516),(.978,-2.529),
                        (.942,-2.529),(.924,-2.519),(.912,-2.503)):
            for x,z in outline:
                vertices.append((side*(.275+(x-.275)*scale),
                                 y+.075*x**3,1.306+(z-1.33)*scale))
        for row in range(5):
            for i in range(count):
                q=(i+1)%count
                face=(row*count+i,row*count+q,(row+1)*count+q,(row+1)*count+i)
                faces.append(face if side<0 else face[::-1])
        mesh=bpy.data.meshes.new("Rolled kidney grille rim")
        mesh.from_pydata(vertices,[],faces)
        mesh.materials.append(DARK)
        for poly in mesh.polygons:
            poly.use_smooth=True
        rim=bpy.data.objects.new("Satin grille surround",mesh)
        bpy.context.collection.objects.link(rim)
        rim.parent=root
        inner=[(.275+(x-.275)*.925,1.306+(z-1.33)*.925) for x,z in outline]
        # Sample both edges of the aperture so each vane terminates at the rim.
        def aperture_limits(x):
            hits = []
            for (a,h),(b,k) in zip(inner,inner[1:]+inner[:1]):
                if min(a,b) <= x < max(a,b):
                    hits.append(h+(k-h)*(x-a)/(b-a))
            return min(hits),max(hits)

        vertices,faces = [],[]
        left,right = min(x for x,_ in inner),max(x for x,_ in inner)
        for j in range(33):
            x = left+.0001+(right-left-.0002)*j/32
            for z in aperture_limits(x):
                vertices.append((side*x,-2.505+.075*x**3,z))
            if j:
                k=2*j
                face=(k-2,k,k+1,k-1)
                faces.append(face if side>0 else face[::-1])
        mesh=bpy.data.meshes.new("Radiator recess")
        mesh.from_pydata(vertices,[],faces)
        mesh.materials.append(RUBBER)
        grille=bpy.data.objects.new("Radiator shadow",mesh)
        bpy.context.collection.objects.link(grille)
        grille.parent=root
        # Thin cooling ribs sit behind the paired blades, clipped to the aperture.
        rib_vertices, rib_faces = [], []
        for z in (1.18,1.215,1.25,1.285,1.32,1.355,1.39,1.425,1.46):
            edges = [a+(z-h)*(b-a)/(k-h)
                     for (a,h),(b,k) in zip(inner,inner[1:]+inner[:1])
                     if min(h,k) <= z < max(h,k)]
            if len(edges) != 2:
                continue
            lo, hi = sorted(edges)
            base = len(rib_vertices)
            for j in range(9):
                x = lo+(hi-lo)*j/8
                depth = -2.507+.075*x**3
                rib_vertices.extend([(side*x,depth,z-.003),(side*x,depth-.002,z+.003)])
                if j:
                    i = base+2*j
                    face = (i-2,i,i+1,i-1)
                    rib_faces.append(face if side>0 else face[::-1])
        mesh = bpy.data.meshes.new("Radiator cooling ribs")
        mesh.from_pydata(rib_vertices,[],rib_faces)
        mesh.materials.append(DARK)
        ribs = bpy.data.objects.new("Radiator cooling ribs",mesh)
        bpy.context.collection.objects.link(ribs)
        ribs.parent = root
        vertices,faces=[],[]
        for i in range(10):
            # Five paired M blades follow the bowed face of each kidney.
            x=.082+(i//2)*.092+(i%2)*.026
            low,high=aperture_limits(x)
            base=len(vertices)
            for j in range(9):
                t=j/8
                bow=math.sin(math.pi*t)
                for k in range(8):
                    angle=k*math.tau/8
                    vertices.append((side*(x+.012*bow+.007*math.cos(angle)),
                        -2.513+.075*x**3-.012*bow+.005*math.sin(angle),low+(high-low)*t))
            for j in range(8):
                for k in range(8):
                    p=base+8*j
                    face=(p+k,p+(k+1)%8,p+8+(k+1)%8,p+8+k)
                    faces.append(face if side>0 else face[::-1])
        mesh=bpy.data.meshes.new("Cambered grille vanes")
        mesh.from_pydata(vertices,[],faces)
        mesh.materials.append(DARK)
        for poly in mesh.polygons:
            poly.use_smooth=True
        slats=bpy.data.objects.new("Kidney grille vanes",mesh)
        bpy.context.collection.objects.link(slats)
        slats.parent=root
        # Cast onto the curved corner from a front-quarter angle. The outer
        # end wraps onto the wing where a front-facing projection would miss.
        direction = Vector((-side*.65,1,0)).normalized()
        def lamp_point(u,v,clearance):
            height = 1.295+.054*u+v*.147
            origin = Vector((side*(.55+.60*u+.65),-3.5,height))
            hit,point,_,_ = surface.ray_cast(origin,direction)
            if not hit:
                raise ValueError(f"Headlamp projection missed at {u}, {v}")
            return point-direction*clearance

        def lamp_patch(label, outline, clearance, finish, dome=0):
            vertices = [lamp_point(u,v,clearance) for u,v in outline]
            mesh = bpy.data.meshes.new(label)
            count = len(vertices)
            faces = [tuple(range(count))]
            if dome:
                perimeter = vertices.copy()
                centre = sum(perimeter,Vector()) / count
                faces.clear()
                for row,(radius,depth) in enumerate(((.78,.58),(.45,.88),(.12,.99))):
                    vertices.extend(centre+(p-centre)*radius-direction*dome*depth for p in perimeter)
                    for i in range(count):
                        j=(i+1)%count
                        faces.append((row*count+i,row*count+j,(row+1)*count+j,(row+1)*count+i))
                faces.append(tuple(range(3*count,4*count)))
            mesh.from_pydata(vertices,[],faces)
            if dome:
                for polygon in mesh.polygons:
                    polygon.use_smooth = True
            mesh.update()
            if mesh.polygons[0].normal.dot(direction)>0:
                mesh.flip_normals()
            mesh.materials.append(finish)
            element = bpy.data.objects.new(label,mesh)
            bpy.context.collection.objects.link(element)
            element.parent=root

        vertices, faces = [], []
        for station in range(33):
            u = station/32
            taper = max(0,1-u/.17,(u-.78)/.22)**2
            low, high = .46*taper, 1-.36*taper
            for row in range(5):
                t = row/4
                vertices.append(lamp_point(u,low+(high-low)*t,.009+.006*math.sin(t*math.pi)))
                if station and row:
                    k = len(vertices)-1
                    faces.append((k-6,k-1,k,k-5))
        mesh = bpy.data.meshes.new("Continuous lamp housing")
        mesh.from_pydata(vertices,[],faces)
        mesh.update()
        if mesh.polygons[0].normal.dot(direction)>0:
            mesh.flip_normals()
        for poly in mesh.polygons:
            poly.use_smooth=True
        mesh.materials.append(BLACK)
        housing=bpy.data.objects.new("Smoked headlamp housing",mesh)
        bpy.context.collection.objects.link(housing)
        housing.parent=root
        for start,end in ((.10,.33),(.34,.60),(.61,.84)):
            lamp_patch("Upper optical trim",[(start,.915),(end,.915),(end,.948),(start,.948)],
                       .019,METAL)
        for u in (.14,.52):
            lamp_patch("Daytime LED chevron",[(u,.11),(u+.045,.11),(u+.12,.49),
                       (u+.055,.91),(u+.01,.91),(u+.067,.49)],.027,HEADLAMP)
            lamp_patch("Projector bezel",[(u+.13,.29),(u+.24,.29),(u+.26,.54),
                       (u+.23,.68),(u+.14,.68),(u+.12,.52)],.020,METAL)
            lamp_patch("Projector lens",[(u+.15,.34),(u+.225,.34),(u+.238,.53),
                       (u+.22,.62),(u+.15,.62),(u+.138,.52)],.026,GLASS,dome=.026)
        duct = [(.015,1.005),(.49,1.014),(.68,1.09),(.80,1.145),(.85,1.115),
                (.845,.755),(.75,.695),(.045,.695)]
        # Blend each corner over a fixed distance so the long lower edge
        # keeps its straight run while the small upper corners remain round.
        rounded=[]
        for i,corner in enumerate(duct):
            v=Vector(corner)
            prev=Vector(duct[i-1])-v
            nxt=Vector(duct[(i+1)%len(duct)])-v
            span=min(.034,prev.length*.34,nxt.length*.34)
            start=v+prev.normalized()*span
            end=v+nxt.normalized()*span
            for step in range(6):
                t=step/5
                rounded.append(start*(1-t)**2+2*t*(1-t)*v+t*t*end)
        vertices, faces, finishes = [], [], []
        profiles=[(1,.009),(.994,.003),(.982,0),(.971,.003),
                  (.96,.011),(.92,.036),(.88,.057)]
        for scale,setback in profiles:
            for x,z in rounded:
                x=.44+(x-.44)*scale
                z=.91+(z-.91)*scale
                vertices.append((side*x,-2.592+.085*x**3+setback,z))
        n=len(rounded)
        for row in range(len(profiles)-1):
            for i in range(n):
                q=(i+1)%n
                face=(row*n+i,row*n+q,(row+1)*n+q,(row+1)*n+i)
                faces.append(face if side<0 else face[::-1])
                finishes.append(int(row>=4))
        backing=tuple(range(len(vertices)-n,len(vertices)))
        faces.append(backing if side<0 else backing[::-1])
        finishes.append(2)
        mesh=bpy.data.meshes.new("Recessed air inlet")
        mesh.from_pydata(vertices,[],faces)
        for mat in (color,DARK,RUBBER):
            mesh.materials.append(mat)
        mesh.polygons.foreach_set("material_index",finishes)
        for polygon in mesh.polygons:
            polygon.use_smooth=polygon.material_index!=2
        inlet = bpy.data.objects.new("Bumper air inlet",mesh)
        bpy.context.collection.objects.link(inlet)
        inlet.parent=root
        # The centre sensor cover interrupts the fins under the plate.
        fascia("Radar cover surround",side,[(0,.716),(.124,.716),(.168,.904),
               (.143,.946),(0,.946)],-2.567,DARK,.022)
        fascia("Radar cover face",side,[(0,.729),(.115,.729),(.153,.900),
               (.134,.931),(0,.931)],-2.570,BLACK,.012)
        for x in (.226,.338,.453):
            fascia("Lower grille fin",side,[(x,.731),(x+.009,.731),
                   (x+.067,.984),(x+.054,.984)],-2.549,BLACK,.024)
        fascia("Outer duct partition",side,[(.546,.715),(.575,.715),
               (.695,1.083),(.661,1.073)],-2.579,DARK,.035)
        # The outer air curtain turns inward at its foot. Project each rim
        # vertex onto the cheek so its visible depth follows the bodywork.
        def cheek_vertex(x,z,depth):
            hit,point,normal,_ = surface.ray_cast((side*x,-3.4,z),(0,1,0))
            if not hit:
                raise ValueError("Air curtain outside bumper cheek")
            return point+normal*depth
        # Shape the painted cheek between the headlamp and duct. The ridge
        # sweeps outward and up, then rolls back into the original wing.
        courses=[]
        for column in range(25):
            u=column/24
            x=.535+.45*u
            fold=1.108+.125*u+.043*math.sin(math.pi*u)
            edge=math.sin(math.pi*u)**1.4
            course=[]
            for dz,relief in ((-.059,0),(-.042,.007),(-.018,.031),(0,.046),
                              (.018,.043),(.047,.028),(.078,.012),(.100,0)):
                course.append(cheek_vertex(x,fold+dz,edge*relief-.001))
            courses.append(course)
        width=len(courses[0])
        vertices=[point for course in courses for point in course]
        faces=[]
        for column in range(len(courses)-1):
            for row in range(width-1):
                i=column*width+row
                face=(i,i+width,i+width+1,i+1)
                faces.append(face if side>0 else face[::-1])
        mesh=bpy.data.meshes.new("Swept headlamp shoulder")
        mesh.from_pydata(vertices,[],faces)
        mesh.materials.append(color)
        for polygon in mesh.polygons:
            polygon.use_smooth=True
        shoulder=bpy.data.objects.new("Painted bumper cheek",mesh)
        bpy.context.collection.objects.link(shoulder)
        shoulder.parent=root
        # Build the slot in horizontal courses so the recessed face follows
        # the wing all the way around the bumper corner.
        courses=[(.658,.819,.879),(.667,.828,.936),(.683,.850,.949),
                 (.710,.875,.954),(.747,.887,.958),(.825,.890,.960),
                 (.930,.893,.961),(1.035,.895,.962),(1.125,.896,.964),
                 (1.145,.898,.962),(1.154,.902,.955),(1.160,.923,.947)]
        vertices,faces,slots=[],[],[]
        samples=((0,.002),(.045,.008),(.10,.012),(.16,.008),(.21,.004),
                 (.50,.004),(.79,.004),(.84,.008),(.90,.012),(.955,.008),(1,.002))
        stride=len(samples)
        for row,(z,left,right) in enumerate(courses):
            for u,depth in samples:
                vertices.append(cheek_vertex(left+(right-left)*u,z,depth))
            if row:
                for k in range(stride-1):
                    i=(row-1)*stride+k
                    quad=(i,i+1,i+1+stride,i+stride)
                    faces.append(quad if side>0 else quad[::-1])
                    slots.append(0 if k in (0,9) else 1 if k in (1,2,7,8) else 2)
        mesh=bpy.data.meshes.new("Air curtain return")
        mesh.from_pydata(vertices,[],faces)
        for finish in (color,DARK,RUBBER):
            mesh.materials.append(finish)
        mesh.polygons.foreach_set("material_index",slots)
        for polygon in mesh.polygons:
            polygon.use_smooth=True
        curtain=bpy.data.objects.new("Outer bumper air curtain",mesh)
        bpy.context.collection.objects.link(curtain)
        curtain.parent=root
        for z in (.790,.895,1.000,1.105):
            blade=[]
            for x in (.902,.925,.953):
                blade.append([cheek_vertex(x,z+dz,relief) for dz,relief in
                              ((-.005,.007),(0,.014),(.005,.012),(.004,.006))])
            profile_loft("Air curtain louvre",blade,DARK,root)
        # Sweep each lens along the tailgate and around the quarter panel.
        stations = [(.34,2.493,.038),(.43,2.496,.078),(.64,2.499,.089),
                    (.70,2.499,.094),(.755,2.498,.118),(.83,2.497,.14),(.92,2.492,.145),(.978,2.464,.135),
                    (1.005,2.393,.105),(1.027,2.29,.065),(1.032,2.23,.012)]
        for label, finish, band, thickness, outset in (
                ("Smoked rear lamp carrier",BLACK,0,1,0),
                ("Upper ruby light guide",TAIL_LAMP,.25,.27,.006),
                ("Lower ruby light guide",TAIL_LAMP,-.24,.23,.006)):
            vertices, faces = [], []
            for x,y,h in stations:
                # The two light guides exchange levels at the tailgate shoulder.
                crossing = max(-1.0,min(1.0,(.755-x)/.085))
                z = 1.395 + .055*x + h*band*crossing
                for edge in (-.5,.5):
                    height = z+h*edge*thickness
                    hit, point, _, _ = hatch_skin.ray_cast((side*x,3,height),(0,-1,0))
                    depth = max(y,point.y+.009) if hit else y
                    vertices.append((side*(x+outset*x),depth+outset,height))
            for i in range(0,len(vertices)-2,2):
                face = (i,i+1,i+3,i+2)
                faces.append(face if side>0 else face[::-1])
            mesh = bpy.data.meshes.new(label)
            mesh.from_pydata(vertices,[],faces)
            mesh.materials.append(finish)
            lamp = bpy.data.objects.new(label,mesh)
            bpy.context.collection.objects.link(lamp)
            lamp.parent=root
        # Sloping trim surrounds the paired outlets in each bumper corner.
        soot = material("Carbon inside exhaust", (.004,.004,.005), .03,.84)
        perimeter = [(-.20,-.062),(-.157,.079),(-.118,.095),(.154,.095),
                     (.190,.071),(.155,-.064),(.121,-.086),(-.173,-.086)]
        vertices, faces = [], []
        for scale,depth in ((1,2.534),(.95,2.550),(.86,2.550),(.80,2.531)):
            for x,z in perimeter:
                vertices.append((side*(.735+scale*x),depth,.607+scale*z))
        for row in range(3):
            for i in range(8):
                j=(i+1)%8
                face=(row*8+i,row*8+j,row*8+j+8,row*8+i+8)
                faces.append(face if side<0 else face[::-1])
        faces.append(tuple(range(24,32)))
        mesh=bpy.data.meshes.new("Recessed exhaust bezel")
        mesh.from_pydata(vertices,[],faces)
        mesh.materials.append(DARK)
        mesh.materials.append(soot)
        for face in mesh.polygons:
            face.use_smooth = face.index < 24
            face.material_index = int(face.index >= 16)
        bezel=bpy.data.objects.new("Exhaust surround",mesh)
        bpy.context.collection.objects.link(bezel)
        bezel.parent=root
        for offset in (-.066,.066):
            pipe = cylinder("Rolled exhaust tip",(side*.735+offset,2.538,.61),.053,.012,DARK,
                            axis_x=False,vertices=32,root=root)
            pipe.rotation_euler.x=math.pi/2
            bore = cylinder("Exhaust bore",(side*.735+offset,2.546,.61),.046,.003,soot,
                            axis_x=False,vertices=32,root=root)
            bore.rotation_euler.x=math.pi/2
        # Fit the air breather to the curved wing, just aft of the wheel opening.
        def vent_vertex(y,z,relief):
            hit,location,_,_ = body.ray_cast((side*2,y,z),(-side,0,0))
            if not hit:
                raise ValueError("Air breather outside wing")
            return (location.x+side*relief,y,z)
        outline = [(-.978,.775),(-.948,.747),(-.892,.756),(-.826,1.074),
                   (-.835,1.101),(-.890,1.075),(-.944,1.031)]
        rings=[]
        for scale,relief in [(1,.004),(.98,.014),(.84,.019),(.78,.007)]:
            rings.append([vent_vertex(-.90+(y+.90)*scale,.925+(z-.925)*scale,relief)
                          for y,z in outline])
        profile_loft("Fender breather bezel",rings,DARK,root,close_ends=False)
        pocket=material("Breather recess",(.006,.007,.008),.05,.63)
        profile_loft("Fender breather recess",[rings[-1],
            [vent_vertex(y,z,.004) for _,y,z in rings[-1]]],pocket,root)
        for z in (.845,.905,.965,1.025):
            y=-.927+(z-.845)*.23
            blade=[]
            for delta in (-.025,.025):
                blade.append([vent_vertex(y+delta,z+dz,depth) for dz,depth in
                              ((-.006,.009),(.003,.016),(.007,.014),(.003,.008))])
            profile_loft("Fender breather louvre",blade,DARK,root)

    for tool in handle_cutters:
        cut=body.modifiers.new("Stamped finger cup","BOOLEAN")
        cut.object=tool
        cut.operation="DIFFERENCE"
        bpy.context.view_layer.objects.active=body
        bpy.ops.object.modifier_apply(modifier=cut.name)
        bpy.data.objects.remove(tool,do_unlink=True)

    # Sweep the bumper moulding across the tail. Its painted shoulder curls
    # around the quarter panels while the lower insert rises under the boot.
    def bumper_section(x, *_):
        u = abs(x)/1.045
        wrap = .039*u*u + .255*u**10
        rise = .034*u**5
        profile = [(2.19,.51),(2.38,.49),(2.49,.50),(2.513,.535),
                   (2.517,.635),(2.523,.691),(2.546,.726),(2.554,.766),
                   (2.543,.798),(2.511,.812),(2.423,.817),(2.19,.796)]
        return [(x, y-wrap, z+rise) for y,z in profile]

    # Seat each surround and its pipes on the swept bumper face.
    bpy.context.view_layer.update()
    for part in root.children:
        if part.name.startswith(("Exhaust surround","Rolled exhaust tip","Exhaust bore")):
            frame = part.matrix_local.copy()
            inverse = frame.inverted()
            for vertex in part.data.vertices:
                point = frame @ vertex.co
                u = abs(point.x)/1.045
                point.y -= .039*u*u + .255*u**10
                point.z += .034*u**5
                vertex.co = inverse @ point

    sections = [(1.045*i/28,0,0,0,0) for i in range(-28,29)]
    bumper = mesh_from_rings("Wraparound rear bumper",sections,
        material("Rear bumper anthracite", (.014,.016,.019),.18,.44),
        root,.008,section=bumper_section)
    bumper.data.materials.append(color)
    for face in bumper.data.polygons:
        # The upper rub strip catches a continuous body-coloured highlight.
        face.material_index = int(face.center.z > .728)
    # A swept lower edge follows the bumper corners back to the wings.
    vertices, faces = [], []
    for i in range(33):
        x = (i-16)/16
        y = -2.55+.17*abs(x)**2
        z = .65+.056*abs(x)**3
        vertices.extend([(x,y,z),(x,y+.15,z+.018),(x,y+.15,z-.018),(x,y,z-.029)])
        if i:
            for j in range(4):
                k = 4*i
                faces.append((k-4+j,k-4+(j+1)%4,k+(j+1)%4,k+j))
    mesh=bpy.data.meshes.new("Swept front spoiler")
    mesh.from_pydata(vertices,[],faces)
    mesh.materials.append(DARK)
    spoiler=bpy.data.objects.new("Front lower splitter",mesh)
    bpy.context.collection.objects.link(spoiler)
    spoiler.parent=root
    badge_teal = material("BMV turquoise enamel", (.015, .37, .32), .20, .26)

    def roundel(name, center, vertical, outward, radius):
        vertices, faces, finishes = [], [], []
        segments = 48
        # Profile of the chrome lip, black border and domed enamel face.
        for fraction, relief in [(1,0),(1,.002),(.95,.004),(.89,.004),
                                 (.87,.003),(.67,.003),(.65,.004),(0,.006)]:
            for i in range(segments):
                angle = math.tau*i/segments
                radial = Vector((math.cos(angle),0,0)) + vertical*math.sin(angle)
                vertices.append(center + radius*fraction*radial + outward*relief)
        for band, finish in enumerate([0,0,0,1,1,0,2]):
            for i in range(segments):
                j = (i+1)%segments
                lo = band*segments
                face = (lo+i,lo+j,lo+j+segments,lo+i+segments)
                faces.append(face[:3] if band==6 else face)
                # A diagonal split makes the two-tone enamel a single motif.
                finishes.append(3 if finish == 2 and (i - 6) % segments < segments // 2 else finish)
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices,[],faces)
        for mat in (METAL, BLACK, badge_teal, PAINT_WHITE):
            mesh.materials.append(mat)
        for polygon, finish in zip(mesh.polygons,finishes):
            polygon.material_index = finish
        obj = bpy.data.objects.new(name,mesh)
        bpy.context.collection.objects.link(obj)
        obj.parent=root

    hit, center, normal, _ = body.ray_cast((0,-2.20,2.50),(0,0,-1))
    if not hit:
        raise ValueError("Bonnet badge outside body")
    if normal.z < 0:
        normal.negate()
    roundel("Bonnet enamel badge",center+normal*.002,
            normal.cross(Vector((1,0,0))).normalized(),normal,.055)
    hit, center, normal, _ = hatch.ray_cast((0,3,1.454),(0,-1,0))
    if hit:
        if normal.y < 0:
            normal.negate()
        vertical = normal.cross(Vector((1,0,0))).normalized()
        roundel("Tailgate enamel badge",center+normal*.003,vertical,normal,.053)

    for y in (-1.52, 1.55):
        for side in (-1, 1):
            bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=.54, depth=.62,
                location=(side*1.04,y,.48), rotation=(0,math.pi/2,0))
            cutter = bpy.context.object
            cut = body.modifiers.new("Wheel housing", "BOOLEAN")
            cut.object = cutter
            cut.operation = "DIFFERENCE"
            bpy.context.view_layer.objects.active = body
            bpy.ops.object.modifier_apply(modifier=cut.name)
            bpy.data.objects.remove(cutter, do_unlink=True)
            tire_rings=[]
            for offset,radius in ((-.132,.364),(-.144,.412),(-.132,.448),
                    (-.107,.472),(-.085,.480),(-.059,.480),(-.055,.472),
                    (-.051,.480),(.048,.480),(.052,.472),(.056,.480),
                    (.085,.480),(.108,.473),(.130,.452),(.144,.414),(.134,.364)):
                tire_rings.append([(side*(.93+offset),y+radius*math.sin(i*math.tau/64),
                                    .48+radius*math.cos(i*math.tau/64)) for i in range(64)])
            profile_loft("Performance tire",tire_rings+[tire_rings[0]],RUBBER,root,close_ends=False)
            def wheel_shell(name, profile, finish):
                rings = [[(side*depth,y+radius*math.sin(i*math.tau/64),
                           .48+radius*math.cos(i*math.tau/64)) for i in range(64)]
                         for depth,radius in profile]
                return profile_loft(name,rings,finish,root,close_ends=False)

            wheel_shell("Diamond cut rim",[(1.058,.381),(1.079,.382),
                (1.086,.375),(1.083,.364),(1.066,.359)],METAL)
            wheel_shell("Anthracite wheel barrel",[(1.077,.363),(1.042,.353),
                (.935,.348),(.856,.354)],BLACK)
            wheel_shell("Brake disc friction ring",[(.978,.178),(.978,.275),
                (.982,.282),(1.002,.282),(1.006,.275),(1.006,.178),(.978,.178)],
                material("Rotor swept steel",(.23,.22,.21),.82,.43))
            cylinder("Brake disc hat",(side*1.003,y,.48),.181,.041,DARK,vertices=48,root=root)
            cube("Red brake caliper",(side*1.034,y+.225,.51),(.062,.094,.212),PAINT_RED,.029,root)
            for lug in range(5):
                angle = math.tau*lug/5
                cylinder("Wheel bolt",(side*1.133,y+.085*math.sin(angle),
                    .48+.085*math.cos(angle)),.014,.016,DARK,vertices=6,root=root)
            vertices, faces, finishes = [], [], []
            for spoke in range(5):
                angle = spoke*math.tau/5
                for branch in (-1,1):
                    # A broad heel at the hub tapers into two swept, polished fingers.
                    base = len(vertices)
                    sections = ((.052,.012,.025,1.121),(.096,.018,.026,1.122),
                                (.15,.022,.022,1.131),(.20,.032,.019,1.137),
                                (.242,.048,.016,1.133),(.31,.074,.014,1.114),
                                (.357,.089,.012,1.088))
                    contour = ((-1,-.023),(-1,-.009),(-.76,-.003),
                               (.27,.004),(.83,.005),(1,.001),(1,-.020))
                    count = len(contour)
                    for radius,spread,width,offset in sections:
                        for edge, depth in contour:
                            tangent = branch*(spread + edge*width)
                            vertices.append((side*(offset+depth),
                                y+radius*math.sin(angle)+tangent*math.cos(angle),
                                .48+radius*math.cos(angle)-tangent*math.sin(angle)))
                    for row in range(len(sections)-1):
                        for k in range(count):
                            i = base+count*row
                            j = (k+1)%count
                            faces.append((i+k,i+j,i+count+j,i+count+k))
                            finishes.append(int(k in (3,4)))
                    for row in (0,len(sections)-1):
                        faces.append(tuple(base+row*count+i for i in range(count)))
                        finishes.append(0)
            mesh = bpy.data.meshes.new("Split spoke forging")
            mesh.from_pydata(vertices,[],faces)
            import bmesh
            bm = bmesh.new()
            bm.from_mesh(mesh)
            bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
            bm.to_mesh(mesh)
            bm.free()
            mesh.materials.append(material("Graphite wheel forging",(.024,.026,.029),.65,.26))
            mesh.materials.append(METAL)
            mesh.polygons.foreach_set("material_index",finishes)
            wheel = bpy.data.objects.new("Five double spokes",mesh)
            bpy.context.collection.objects.link(wheel)
            wheel.parent=root
            cylinder("Centre cap",(side*1.139,y,.48),.071,.018,BLACK,root=root)
            cylinder("Blue hub enamel",(side*1.152,y,.48),.036,.008,POLICE_BLUE,root=root)
    glass_rings=[]
    for y,w in ((-.12,.49),(-.08,.545),(.02,.563),(.62,.566),(1.17,.555),(1.24,.535),(1.27,.48)):
        top=[(x*w,y,roof_height(x*w,y)+.006) for x in (-1,-.75,-.5,-.25,0,.25,.5,.75,1)]
        glass_rings.append(top+[(x,y,z-.013) for x,y,z in reversed(top)])
    profile_loft("Panoramic sunroof",glass_rings,privacy,root)
    cube("Front plate", (0, -2.596, 1.035), (0.72, 0.035, 0.18), PAINT_WHITE, 0.025, root)
    registration = {PAINT_BLUE_CAR: "AXL 061", PAINT_SILVER: "AXL 062"}.get(color, "AXL 060")
    for rear, depth, height, width in [(True,2.523,1.204,.56),(False,-2.615,1.035,.72)]:
        facing = -1 if rear else 1
        cube("Blue registration band",(-facing*width*.445,depth,height),
             (width*.09,.002,.12),POLICE_BLUE,.001,root)
        glyphs = bpy.data.curves.new("Registration glyphs","FONT")
        glyphs.body = registration
        glyphs.size = .12
        glyphs.align_x = "CENTER"
        glyphs.align_y = "CENTER"
        lettering = bpy.data.objects.new("Registration " + registration,glyphs)
        bpy.context.collection.objects.link(lettering)
        lettering.parent = root
        lettering.location = (facing*.025,depth,height)
        lettering.rotation_euler = (math.pi/2,0,math.pi if rear else 0)
        glyphs.materials.append(BLACK)
        bpy.ops.object.select_all(action="DESELECT")
        lettering.select_set(True)
        bpy.context.view_layer.objects.active = lettering
        bpy.ops.object.convert(target="MESH")
    # Map the styling mesh to metres. Within each arch, use the same
    # longitudinal and vertical scale so wheels and cutouts stay circular.
    height_scale = 1.765 / 2.3175
    front_axle, rear_axle = -1.52, 1.55
    stations = [(-2.59, -2.38)]
    for old, new in ((front_axle,-1.4875), (rear_axle,1.4875)):
        stations.extend((old+d,new+d*height_scale) for d in (-.56,.56))
    stations.append((2.57,2.555))
    def longitudinal(y):
        for (a,b),(c,d) in zip(stations,stations[1:]):
            if y <= c:
                return b+(y-a)*(d-b)/(c-a)
        return stations[-1][1]
    bpy.context.view_layer.update()
    for part in root.children:
        frame = part.matrix_local.copy()
        inverse = frame.inverted()
        rigid_plate = part.name.startswith(("Front plate","Blue registration band","Registration AXL"))
        for vertex in part.data.vertices:
            point = frame @ vertex.co
            # Carry the bonnet, kidney rims and lamps together over the nose.
            # The centre projects ahead of the swept-back outer cheeks.
            nose = max(0,min(1,(-point.y-1.78)/.63))
            nose = nose*nose*(3-2*nose)
            across = 0 if rigid_plate else min(1,abs(point.x)/1.05)
            point.y += nose*(.23*across**2-.055)
            bonnet = max(0,min(1,(point.z-1.02)/.50))
            point.z += nose*bonnet*(.068*(1-across**2)+.032*across**5)
            point.x *= 2.004 / 2.296
            point.y = longitudinal(point.y)
            point.z *= height_scale
            vertex.co = inverse @ point

    return root

def polish_scene(vehicles, traffic_variants):
    # A clean showroom layout in the editable .blend file.
    for index, root in enumerate(vehicles):
        root.location.x = (index - 1.5) * 8.0
    for index, root in enumerate(traffic_variants):
        root.location = (60, index * 8, 0)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 1200
    bpy.context.scene.render.resolution_y = 720
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.image_settings.file_format = "PNG"
    floor = material("Studio floor", (0.105, 0.145, 0.155), 0.12, 0.7)
    cube("Studio floor", (0, 0, -0.18), (80, 80, 0.28), floor, 0.04)
    bay = material("Parking bay lines", (0.68, 0.73, 0.68), 0.05, 0.6)
    for x in (-16, -8, 0, 8, 16):
        cube("Display bay line", (x, 0, -0.032), (0.045, 9.8, 0.018), bay, 0.008)
    for y in (-4.9, 4.9):
        cube("Display bay line", (0, y, -0.032), (27, 0.045, 0.018), bay, 0.008)
    bpy.ops.object.camera_add(location=(17, -27, 17))
    camera = bpy.context.object
    camera.name = "Vehicle collection camera"
    target = Vector((0, 0.15, 1.05))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 34
    bpy.context.scene.camera = camera
    for name, loc, energy, size, color in (
        ("Large softbox", (0, -8, 16), 5200, 11, (0.79, 0.87, 1.0)),
        ("Warm fill", (-11, 3, 10), 3100, 9, (1.0, 0.79, 0.59)),
        ("Rim light", (10, 5, 12), 3900, 8, (0.62, 0.79, 1.0)),
    ):
        bpy.ops.object.light_add(type="AREA", location=loc)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        light.rotation_euler = (Vector((0, 0, 1.2)) - light.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.world.color = (0.12, 0.16, 0.17)
    bpy.context.scene.view_settings.view_transform = "AgX"
    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "vehicle_preview.png")
    bpy.context.scene.camera.data.lens = 42
    bpy.context.scene.render.film_transparent = False
    bpy.ops.render.render(write_still=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE_DIR, "Axels_Utryckningsfordon.blend"))

def render_bmw_detail(root):
    """Create a high resolution close-up render from the same front three-quarter view as the reference."""
    clear_scene()
    hero = make_bmw(PAINT_BLACK)
    hero.name = "BMW X5 M60i | reference study"
    floor_mat = material("Warm grey photographic cyclorama", (0.18, 0.19, 0.19), 0.08, 0.74)
    cube("Seamless studio floor", (0, 0, -0.19), (40, 40, 0.32), floor_mat, 0.08)
    bpy.ops.object.camera_add(location=(9.6, -12.8, 6.1))
    camera = bpy.context.object
    target = Vector((0, 0.0, 1.22))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 7.4
    bpy.context.scene.camera = camera
    for name, loc, energy, size, color in (
        ("Front softbox", (2, -7, 7), 1800, 5.0, (0.83, 0.89, 1.0)),
        ("Warm side strip", (6, 2, 5), 1500, 4.0, (1.0, 0.82, 0.64)),
        ("Roof rim", (-4, 4, 6), 2100, 3.5, (0.69, 0.81, 1.0)),
        ("Grille fill", (-1, -5, 2.8), 500, 2.4, (1.0, 0.94, 0.84)),
    ):
        bpy.ops.object.light_add(type="AREA", location=loc)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        light.rotation_euler = (Vector((0, 0, 1.15)) - light.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 1600
    bpy.context.scene.render.resolution_y = 1000
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.view_settings.view_transform = "AgX"
    bpy.context.scene.world.color = (0.12, 0.13, 0.14)
    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "bmw_x5_reference_study.png")
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE_DIR, "BMW_X5_M60i_ReferenceStudy.blend"))

def export_vehicle(root, filename):
    bpy.ops.object.select_all(action="DESELECT")
    root.location = (0, 0, 0)
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT_DIR, filename), export_format="GLB", use_selection=True, export_apply=True, export_yup=True, export_texcoords=True, export_normals=True, export_materials="EXPORT")

def main():
    clear_scene()
    ambulance = make_ambulance()
    police = make_police()
    fire = make_fire_engine()
    bmw_black = make_bmw(PAINT_BLACK)
    bmw_silver = make_bmw(PAINT_SILVER, "BMV X5i / Arctic silver")
    bmw_blue = make_bmw(PAINT_BLUE_CAR, "BMV X5i / Deep blue")
    export_vehicle(make_taxi(), "taxi.glb")
    export_vehicle(ambulance, "ambulance.glb")
    export_vehicle(police, "polisbil.glb")
    export_vehicle(fire, "brandbil.glb")
    export_vehicle(bmw_black, "bmw_x5_m60i.glb")
    export_vehicle(bmw_silver, "traffic_bmw_silver.glb")
    export_vehicle(bmw_blue, "traffic_bmw_blue.glb")
    polish_scene([ambulance, police, fire, bmw_black], [bmw_silver, bmw_blue])
    render_bmw_detail(bmw_black)
    print("Built Blender source, three emergency vehicles, and a BMW X5 M60i with traffic variants in", OUT_DIR)

if __name__ == "__main__":
    main()
