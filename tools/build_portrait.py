"""Portrait geometry in Blender coordinates. Positive Y faces the viewer."""
import bpy
from math import cos, exp, pi, sin, sqrt, tau

def build_portrait(root, alma=False):
    portrait = bpy.data.collections.new("Alma portrait" if alma else "Portrait details")
    bpy.context.scene.collection.children.link(portrait)

    def mesh(name, vertices, faces, material=None):
        data = bpy.data.meshes.new(name)
        data.from_pydata(vertices, [], faces)
        data.update()
        obj = bpy.data.objects.new(name, data)
        portrait.objects.link(obj)
        for poly in data.polygons:
            poly.use_smooth = True
        if material:
            data.materials.append(material)
        return obj

    def material(name, rgb):
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = (*rgb, 1)
        mat.use_nodes = True
        shader = mat.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Base Color'].default_value = (*rgb, 1)
        shader.inputs['Roughness'].default_value = .65
        return mat

    def obj_export(obj):
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.ops.wm.obj_export(filepath=str(root/'characters'/(obj.name+'.obj')),
                              export_selected_objects=True, export_materials=False)

    # Horizontal sections through chin, mandible, cheeks, temples and crown.
    rings = [(-.143,.016,.045,.056),(-.136,.043,.067,.036),(-.120,.063,.086,.018),
             (-.096,.081,.102,.002),(-.058,.092,.110,-.001),(-.022,.101,.116,-.001),
             (.018,.105,.122,-.004),(.057,.105,.125,-.008),(.094,.101,.120,-.010),
             (.120,.090,.109,-.013),(.141,.064,.084,-.015),(.155,.031,.042,-.016),(.159,.002,.003,-.016)]

    if alma:
        # Fuller cheeks and a shorter, softer jaw within the shared neck and hair fit.
        rings = [(z + .007 * max(0, -z/.143)**2,
                  w * (1 + .052 * exp(-((z+.045)/.035)**2)
                         - .065 * exp(-((z+.105)/.022)**2)), d, c)
                 for z, w, d, c in rings]

    def section(z):
        for lower, upper in zip(rings, rings[1:]):
            if z <= upper[0]:
                t = max(0, (z-lower[0])/(upper[0]-lower[0]))
                return tuple(a+(b-a)*t for a,b in zip(lower[1:],upper[1:]))
        return rings[-1][1:]

    def displacement(x,z):
        def bump(cx, cz, wx, wz):
            return exp(-((abs(x)-cx)/wx)**2 - ((z-cz)/wz)**2)
        return (.011*bump(.058,-.018,.025,.029) - .012*bump(.043,.014,.024,.014)
                +.009*bump(.043,.034,.030,.012) + .022*bump(0,.006,.012,.043)
                +(.027 if alma else .035)*bump(0,-.028,.015,.012) + .015*bump(.015,-.032,.009,.008)
                +.003*bump(.006,-.049,.0038,.009) - .002*bump(0,-.051,.003,.008)
                -.003*bump(0,-.083,.023,.006) + .008*bump(0,-.065,.036,.019) + .008*bump(0,-.108,.029,.016))

    def surface(x,z):
        w,d,c = section(z)
        f = sqrt(max(0,1-(x/w)**2))
        return c+d*f+displacement(x,z)*f**3

    def shell(name, rows, cols, vertex):
        verts=[vertex(j/rows,tau*i/cols) for j in range(rows+1) for i in range(cols)]
        faces=[]
        for j in range(rows):
            for i in range(cols):
                a=j*cols+i
                b=j*cols+(i+1)%cols
                faces.append((a,b,b+cols,a+cols))
        faces += [tuple(reversed(range(cols))),tuple(range(rows*cols,(rows+1)*cols))]
        return mesh(name,verts,faces)

    def face_point(t,a):
        z=rings[0][0]+t*(rings[-1][0]-rings[0][0])
        w,d,c=section(z)
        x=w*cos(a)
        return (x,c+d*sin(a)+displacement(x,z)*max(0,sin(a))**3,z)

    head=shell('AlmaFace' if alma else 'Face',80,96,face_point)
    obj_export(head)

    def hair_point(t,a, long_cut=False):
        # The side part sweeps across the forehead and the nape follows the skull.
        front=max(0,sin(a))
        part = cos(a) * front
        hairline = -.047 + .116*front**.9 + .014*part + .003*sin(7*a)
        if not long_cut:
            hairline += .007*sin(9*a+.7)*front + .003*sin(16*a)*front
        z=hairline+(.159-hairline)*t
        fall=(1-t)**2*(1-front**1.5) if long_cut else 0
        w,d,c=section(z)
        # Sweep locks around the side part and vary their width towards the crown.
        flow = a + .21*sin(pi*t) + .08*t*cos(a) + .022*sin(4*a)
        strand = (.008 + .003*cos(13*flow+1.2*t) + .0017*cos(31*flow)
                  + .001*cos(52*flow-2*t))*(1-.45*t)
        strand += .007*(1-t)*max(0, -part)
        return ((w+strand+.009*fall)*cos(a)-.003*t,c+(d+strand+.008*fall)*sin(a),z+.010*t-.094*fall)
    hair = bob = None
    if not alma:
        hair=shell('Hair',23,120,hair_point)
        obj_export(hair)
        bob=shell('Bob',23,120,lambda t,a: hair_point(t,a,True))
        obj_export(bob)

    sclera=material('Warm ivory',(.47,.43,.38))
    iris=material('Hazel',(.105,.085,.046))
    pupil=material('Pupil',(.015,.012,.011))
    brow=material('Brows',(.074,.043,.030))
    lip=material('Lips',(.40,.155,.116))
    crease=material('Lip seam',(.155,.056,.046))

    def patch(name,side,center,halfwidth,upper,lower,lift,mat,tilt=0):
        verts=[]
        n=26
        for k in range(n+1):
            u=-1+2*k/n
            x=side*(center[0]+halfwidth*u)
            arch=max(0,1-u*u)**.72
            for q in range(5):
                v=q/4
                z=center[1]+tilt*u+arch*(v*(upper+lower)-lower)
                verts.append((x,surface(x,z)+lift+.0018*arch*sin(pi*v),z))
        faces=[(i*5+j,(i+1)*5+j,(i+1)*5+j+1,i*5+j+1) for i in range(n) for j in range(4)]
        if side==1: faces=[f[::-1] for f in faces]
        return mesh(name,verts,faces,mat)

    lash=material('Lid rim',(.13,.075,.051))
    for s in (-1,1):
        # A tapered rim follows the upper boundary of the almond-shaped eye.
        verts=[]
        for i in range(27):
            u=-1+i/13
            arch=max(0,1-u*u)**.72
            x=s*(.042+.018*u)
            z=.013+.0056*arch+.0012*u
            for dz in (0,.0016*arch):
                verts.append((x,surface(x,z+dz)+.003,z+dz))
        quads=[(2*i,2*i+2,2*i+3,2*i+1) for i in range(26)]
        mesh('Lash line',verts,[q[::-1] for q in quads] if s==1 else quads,lash)

        patch('Eye',s,(.042,.013),.018,.0056,.0040,.0018,sclera,.0012)
        patch('Iris',s,(.042,.0136),.0071,.0044,.0039,.0042,iris)
        patch('Pupil',s,(.042,.0138),.0025,.0031,.0029,.0064,pupil)
        patch('Catchlight',s,(.0405,.016),.0010,.001,.001,.0083,sclera)
        patch('Eyebrow',s,(.045,.038),.023,.0038,.0026,.0027,brow,-.003)
        patch('Nostril',s,(.011,-.035),.0035,.0013,.0014,.0014,crease,.0008)
    # Two peaks of the cupid's bow above a softly curved mouth opening.
    for upper in (False, True):
        verts = []
        for i in range(33):
            u = (i-16)/16
            x = .026*u
            arch = max(0, 1-u*u)**.7
            seam = -.0655 + .0017*u*u
            height = (.0033 + .0029*exp(-((abs(u)-.25)/.18)**2)) if upper else -.0058
            for j in range(5):
                t = j/4
                z = seam + (.0007 if upper else -.0007) * arch + height*arch*t
                verts.append((x, surface(x,z) + arch*(.0024+.0026*sin(pi*t)), z))
        quads = [(i*5+j,i*5+j+1,(i+1)*5+j+1,(i+1)*5+j) for i in range(32) for j in range(4)]
        mesh('Upper lip' if upper else 'Lower lip', verts, quads if upper else [q[::-1] for q in quads], lip)
    patch('Mouth',1,(0,-.0655),.025,.0006,.00065,.0026,crease)
    if alma:
        from mathutils import Vector
        acetate = material("Dark plum acetate", (.064,.029,.035))

        def frame_tube(name, points, radius, closed=False):
            verts, faces = [], []
            path = [Vector(p) for p in points]
            for i, point in enumerate(path):
                before = path[i-1] if i or closed else point
                after = path[(i+1)%len(path)] if closed or i+1<len(path) else point
                tangent = (after-before).normalized()
                normal = tangent.cross(Vector((0,1,0))).normalized()
                if normal.length_squared<.01:
                    normal = Vector((1,0,0))
                across = tangent.cross(normal)
                for k in range(8):
                    angle = tau*k/8
                    verts.append(point + radius*(normal*cos(angle)+across*sin(angle)))
            for i in range(len(path) if closed else len(path)-1):
                for k in range(8):
                    j = (i+1)%len(path)
                    faces.append((i*8+k,i*8+(k+1)%8,j*8+(k+1)%8,j*8+k))
            return mesh(name,verts,faces,acetate)

        front_y = surface(.042,.013)+.017
        for side in (-1,1):
            ring = []
            for k in range(48):
                a = tau*k/48
                x = .044+.037*cos(a)
                ring.append((side*x,front_y-.012*(x/.081)**2,.012+.033*sin(a)))
            frame_tube("Rounded spectacle rim",ring,.0033,True)
            frame_tube("Temple",[(side*.079,front_y-.012,.021),
                                  (side*.099,.062,.025),(side*.11,.006,.023),
                                  (side*.109,-.025,.012)],.0033)
        frame_tube("Arched bridge",[(-.012,front_y,.022),(0,front_y+.003,.028),
                                     (.012,front_y,.022)],.0032)

        before_cap = set(portrait.objects)
        canvas = material("Raspberry cotton", (.69,.045,.22))
        stitching = material("Rose seam", (.40,.029,.105))
        def cap_point(t,a):
            lat = t*pi*.499
            return (.120*cos(lat)*cos(a), -.009+.145*cos(lat)*sin(a),
                    .060+.132*sin(lat)+.013*sin(a)*cos(lat))
        crown = shell("Six-panel cap",16,60,cap_point)
        crown.data.materials.append(canvas)
        for panel in range(6):
            a = tau*panel/6
            frame_points = [cap_point(j/18,a) for j in range(19)]
            seam = frame_tube("Panel stitching",frame_points,.0011)
            seam.data.materials[0] = stitching
        verts, faces = [], []
        for i in range(33):
            a = pi*i/32
            for edge in (0,1):
                verts.append((.117*cos(a),.004+(.135+.058*edge)*sin(a),
                              .059+.015*sin(a)-.015*edge*sin(a)))
        for i in range(32):
            faces.append((2*i,2*i+2,2*i+3,2*i+1))
        brim = mesh("Curved cap brim",verts,faces,canvas)
        brim.modifiers.new("Bound brim edge","SOLIDIFY").thickness=.003

        cap_parts = set(portrait.objects) - before_cap
        bpy.ops.object.select_all(action="DESELECT")
        for part in cap_parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = crown
        bpy.ops.object.join()
        crown.name = "SummerCap"

        hair_tones = [material("Chestnut lock", (.084,.040,.019)),
                      material("Brown lock", (.066,.032,.017)),
                      material("Sunlit lock", (.113,.058,.027))]
        for side in (-1,1):
            for strand, tone in enumerate(hair_tones):
                points = []
                for step in range(65):
                    t = step/64
                    phase = tau*(3.5*t+strand/3)
                    x = .085+.029*sin(pi*t)+.013*cos(phase)*(1-.40*t)
                    y = .014+.130*sin(t*pi/2)+.008*sin(2*phase)
                    points.append((side*x,y,-.052-.319*t))
                plait = frame_tube("Woven lock",points,.010)
                plait.data.materials[0] = tone
            tie = frame_tube("Hair elastic",[(side*.085,.144,-.368),
                                            (side*.084,.145,-.379)],.020)
            tie.data.materials[0] = stitching
            tail = frame_tube("Loose hair end",[(side*.084,.145,-.377),
                                               (side*.082,.145,-.396),
                                               (side*.077,.142,-.413)],.012)
            tail.data.materials[0] = hair_tones[0]
    bpy.ops.object.select_all(action='DESELECT')
    for obj in portrait.objects:
        obj.select_set(obj not in (head,hair,bob) and (not alma or obj != crown))
    bpy.context.view_layer.objects.active = next(obj for obj in portrait.objects if obj.select_get())
    bpy.ops.object.join()
    bpy.context.object.name = 'Facial features'
    if alma:
        crown.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(root/'characters'/('AlmaPortrait.glb' if alma else 'Portrait.glb')),
                              export_format='GLB',use_selection=True)

    if alma:
        return

    # A folded standing collar opens at the throat. The zip and pull follow the
    # front profile, so the player's recolourable jacket remains visible.
    trim=material('Collar lining',(.081,.092,.104))
    tape=material('Zipper tape',(.105,.119,.120))
    metal=material('Brushed zip',(.33,.35,.34))
    before=set(portrait.objects)
    verts=[]
    segments=60
    for i in range(segments+1):
        angle=pi*.5+.24+(tau-.48)*i/segments
        fold=sin(pi*i/segments)**.5
        for w,d,z in [(.105,.094,.310),(.086,.080,.350),(.078,.070,.348),(.080,.076,.312)]:
            verts.append((w*cos(angle),d*sin(angle),z+.022*fold))
    quads=[]
    for i in range(segments):
        for j in range(4):
            k=(j+1)%4
            quads.append((4*i+j,4*(i+1)+j,4*(i+1)+k,4*i+k))
    mesh('Collar',verts,quads,trim)
    path=[(-.335,.130),(-.30,.132),(-.18,.129),(.03,.142),(.16,.141),(.20,.135),(.25,.118),(.29,.107),(.319,.092)]
    for width,offset,mat in [(.006,.002,tape),(.0016,.003,metal)]:
        verts=[(x,y+offset,z) for z,y in path for x in (-width,width)]
        quads=[(2*i,2*i+2,2*i+3,2*i+1) for i in range(len(path)-1)]
        mesh('Front closure',verts,quads,mat)
    mesh('Pull tab',[(-.004,.111,.295),(.004,.111,.295),(.004,.121,.266),(-.004,.121,.266)],[(0,1,2,3)],metal)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in set(portrait.objects)-before:
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
    bpy.ops.object.join()
    bpy.context.object.name='Jacket trim'
    bpy.ops.export_scene.gltf(filepath=str(root/'characters'/'JacketTrim.glb'),
                              export_format='GLB',use_selection=True)
