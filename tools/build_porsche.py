"""Build the wide-body 911 GT3 RS in metres. Blender -Y is the front."""
from math import cos, exp, pi, sin, sqrt, tau
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector
from mathutils.geometry import delaunay_2d_cdt

TOOLS = Path(__file__).resolve().parent
PROJECT = TOOLS.parent
sys.path.insert(0, str(TOOLS))
from build_vehicles import cube, material
from porsche_wheels import build_wheels


def mesh(name, vertices, faces, finish, smooth=True):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(finish)
    for face in data.polygons:
        face.use_smooth = smooth
    return obj


def grid(name, rows, finish, closed=False):
    width = len(rows[0])
    faces = []
    for i in range(len(rows)-1):
        for j in range(width if closed else width-1):
            a = i*width+j
            b = i*width+(j+1)%width
            faces.append((a, b, b+width, a+width))
    if closed:
        faces.extend([tuple(reversed(range(width))), tuple(range((len(rows)-1)*width,len(rows)*width))])
    obj = mesh(name,[v for row in rows for v in row],faces,finish)
    if closed:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
        bm.to_mesh(obj.data)
        bm.free()
    return obj


def tube(name, points, radius, finish):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    path = curve.splines.new("POLY")
    path.points.add(len(points)-1)
    for point, value in zip(path.points,points):
        point.co = (*value,1)
    curve.materials.append(finish)
    obj = bpy.data.objects.new(name,curve)
    bpy.context.collection.objects.link(obj)
    return obj


def oval(name, center, scale, finish, tilt=0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=40,ring_count=20,location=center)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler.x = tilt
    obj.data.materials.append(finish)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def profile(stations,y,col):
    # Cubic Hermite interpolation preserves the tangent at each body station.
    for i,(p,q) in enumerate(zip(stations,stations[1:])):
        if y <= q[0]:
            before, after = stations[max(0,i-1)], stations[min(len(stations)-1,i+2)]
            length = q[0]-p[0]
            t = max(0,(y-p[0])/length)
            a = length*(q[col]-before[col])/(q[0]-before[0])
            b = length*(after[col]-p[col])/(after[0]-p[0])
            return (1+2*t)*(1-t)**2*p[col]+t*(1-t)**2*a+t*t*(3-2*t)*q[col]+t*t*(t-1)*b
    return stations[-1][col]


# y, half width at belt, centreline height, outer shoulder height
BODY = [(-2.28,.884,.508,.557),(-2.19,.899,.521,.583),(-1.98,.92,.557,.68),
        (-1.69,.95,.595,.767),(-1.23,.967,.671,.829),(-.82,.945,.72,.79),
        (-.54,.928,.76,.754),(-.12,.918,.775,.752),(.42,.929,.77,.768),
        (.88,.985,.765,.832),(1.29,1.006,.778,.862),(1.67,.993,.782,.846),
        (2.01,.953,.754,.788),(2.22,.899,.708,.724),(2.27,.855,.665,.677)]


def upper(y,u):
    width = profile(BODY,y,1)
    crown = profile(BODY,y,2)
    shoulder = profile(BODY,y,3)
    v = abs(u)
    return (width*u,y,crown+(shoulder-crown)*exp(-((v-.78)/.24)**2)-.055*v**9)


def arch_edge(y):
    base = .216
    for axle,r,h in [(-1.18,.385,.35),(1.27,.399,.365)]:
        offset = abs(y-axle)
        if offset < r:
            return h+sqrt(max(0,r*r-offset*offset))
        if offset < r+.042:
            return h+(base-h)*(offset-r)/.042
    return base


def side_surface(y,z,side):
    width=profile(BODY,y,1)
    lower=arch_edge(y)+.012
    upper_edge=upper(y,1)[2]
    t=max(0,min(1,(upper_edge-z)/max(.01,upper_edge-lower)))
    waist=.035*sin(pi*t)**2*exp(-((y-.15)/.75)**4)
    # A broad pressed channel in the door feeds the intake ahead of the hip.
    shoulder=.099*exp(-((y-.58)/.39)**2-((t-.48)/.30)**2)
    x=width*(1.0+.008*sin(t*pi)-.004*t*t)-waist-shoulder
    return (side*x,y,z)


def body_shell():
    rows=[]
    samples = sorted(set([-2.28+i*4.55/156 for i in range(157)] +
                         [axle+s*r for axle,r in [(-1.18,.385),(1.27,.399)] for s in [-1,1]]))
    for y in samples:
        width = profile(BODY,y,1)
        edge = arch_edge(y)
        top = upper(y,1)[2]
        # The cut arches curl in around the tyre. The underside retreats
        # behind the wheel wells, leaving a true opening in the side profile.
        row = [upper(y,i/20) for i in range(-20,21)]
        for s in [1,-1]:
            side=[side_surface(y,top+(edge+.012-top)*k/9,s) for k in range(1,10)]
            side.extend([(s*(width-.037),y,edge-.006),(s*.63,y,edge-.022),(s*.59,y,.20)])
            row.extend(side if s==1 else reversed(side))
        # The nose sweeps rearward around the fenders. Keep its end open:
        # the separate moulded fascia contains three real through-openings.
        blend=max(0.0,1-(y+2.28)/.69)**2
        row=[(x,y+blend*(front_depth(x)+2.28),z) for x,_,z in row]
        rows.append(row)
    obj=grid("Wide body with raised front wings and open arches",rows,paint,True)
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    cap=max((f for f in bm.faces if len(f.verts)>10),key=lambda f:-f.calc_center_median().y)
    bmesh.ops.delete(bm,geom=[cap],context="FACES_ONLY")
    bm.to_mesh(obj.data)
    bm.free()
    return [(x,z) for x,_,z in rows[0]]


# y, roof height, half-width at sill, half-width at roof edge
CAB = [(-.88,.755,.76,.64),(-.76,.863,.79,.68),(-.48,1.071,.797,.666),
       (-.22,1.205,.797,.646),(.02,1.259,.799,.63),(.27,1.276,.788,.615),
       (.50,1.258,.782,.611),(.74,1.203,.772,.60),(1.01,1.111,.755,.571),
       (1.34,.963,.728,.526),(1.63,.805,.679,.463)]


def canopy(y,u):
    if abs(u)>.76:
        fraction=min(1,(abs(u)-.76)/.217)
        y+=(fraction-.5)*.30*exp(-((y-.99)/.255)**2)
    z=profile(CAB,y,1)
    width=profile(CAB,y,2)
    roof=profile(CAB,y,3)
    floor=.733+.05*max(0,y)
    v=abs(u)
    if v<=.72:
        x=roof*v/.72
        h=z-.036*(v/.72)**2
    else:
        k=(v-.72)/.28
        x=roof+(width-roof)*k
        h=(z-.036)*(1-k)+floor*k
    return ((-1 if u<0 else 1)*x,y,h)


def build_canopy():
    stations=sorted(set([-.88+2.51*i/96 for i in range(97)]+[-.818,-.29,.49,.57,.72,1.42]))
    sections=[-1,-.977,-.76,-.735,-.72,-.69,-.655,-.49,-.25,0,.25,.49,.655,.69,.72,.735,.76,.977,1]
    roof=grid("Coupé roof and individually framed glazing",[[canopy(y,u) for u in sections] for y in stations],paint)
    for mat in [glass,carbon,rubber]:
        roof.data.materials.append(mat)
    for polygon in roof.data.polygons:
        row,col=divmod(polygon.index,len(sections)-1)
        y=(stations[row]+stations[row+1])*.5
        u=abs((sections[col]+sections[col+1])*.5)
        if u < .69:
            if -.818<y<-.29 or .72<y<1.42:
                polygon.material_index=1
            elif -.29<=y<=.72 and u<.655:
                polygon.material_index=2
        elif .76<u<.977 and -.70<y<1.0:
            polygon.material_index=3 if .49<y<.57 else 1
    for s in [-1,1]:
        tube("Glazing lower reveal",[canopy(y,s*.979) for y in stations if -.70<y<1.0],.008,rubber)
        oval("Bucket seat back",(s*.356,.33,.637),(.246,.118,.287),leather,-.16)
        oval("Seat head restraint",(s*.356,.37,.87),(.122,.094,.135),leather)
        oval("Seat cushion",(s*.356,.10,.44),(.227,.31,.085),leather)
    for s in [-1,1]:
        # Short wiper arms rest on the black frit at the windscreen base.
        x=s*.32
        tube("Wiper arm",[(x,-.79,.839),(x+.09,-.755,.866)],.010,rubber)
        tube("Wiper blade",[(x-.12,-.756,.864),(x+.20,-.752,.871)],.009,rubber)
    oval("Dashboard binnacle",(0,-.52,.791),(.651,.17,.085),leather)
    ring=[(.347+.14*cos(tau*i/48),-.40+.022*sin(tau*i/48),.853+.135*sin(tau*i/48)) for i in range(49)]
    tube("Steering wheel rim", ring,.015,leather)
    for angle in [0,pi,1.5*pi]:
        tube("Steering wheel spoke",[(.347,-.4,.853),(.347+.13*cos(angle),-.4,.853+.13*sin(angle))],.012,alloy)


def hood_patch(name, outline, finish, height=.006):
    coords=[]
    for x,y in outline:
        w=profile(BODY,y,1)
        coords.append((x,y,upper(y,x/w)[2]+height))
    obj=mesh(name,coords,[tuple(range(len(coords)))],finish,False)
    return obj


def rear_aero():
    # Two curved airfoils supported from above by the characteristic swan necks.
    for y,z,chord in [(1.88,1.13,.33),(2.064,1.255,.245)]:
        rows=[]
        for i in range(31):
            x=(i/15-1)*.995
            sweep=.075*abs(x)**2
            rows.append([(x,y+sweep+chord*a,z+b+.025*x*x) for a,b in
                         [(-.48,.012),(-.32,.03),(.08,.025),(.54,.053),(.50,.027),(0,-.013),(-.39,-.016)]])
        grid("Carbon rear wing blade",rows,carbon,True)
    for s in [-1,1]:
        for name,points,half in [
            ("Wing endplate",[(1.69,1.15),(1.79,1.32),(2.22,1.36),(2.26,1.19),(2.11,1.11)],.993),
            ("Swan neck wing upright",[(1.63,.79),(1.76,1.12),(1.85,1.29),(2.00,1.28),
                                       (2.02,1.24),(1.89,1.24),(1.87,1.10),(1.84,.80)],.49)]:
            grid(name,[[(s*(half+dx),y,z) for y,z in points] for dx in [-.016,.016]],carbon,True)
    for i in range(-4,5):
        x=i*.087
        cube("Engine cover cooling blade",(x,1.74,.80),(.033,.245,.031),rubber,.01)
    reversing = material("Reverse lamp clear lens",(.65,.70,.71),.2,.22)
    reflector_finish = material("Red passive reflector",(.42,.008,.006),.22,.23)
    shell = bpy.data.objects["Wide body with raised front wings and open arches"]
    for vert in shell.data.vertices:
        x,y,z = vert.co
        if y > 2.0:
            blend = min(1,(y-2.0)/.27)
            vert.co.y -= .205*(abs(x)/.94)**4*blend**2
    # Sweep the valance around the rear quarters. The light band follows the
    # deck edge; the dark diffuser rises outside the central exhaust tunnel.
    rows = []
    lenses = []
    sockets = []
    valance = []
    ducktail = []
    for i in range(81):
        u = (i - 40) / 40
        x = .939 * u
        v = abs(u)
        aft = 2.375 - .115*v**2 - .179*v**8
        top = .700 + .018*v**2 - .045*v**8
        pocket = .046*exp(-(v/.57)**6)
        rows.append([(x,aft+dy,top+dz) for dy,dz in
                     [(-.19,-.008),(-.035,.008),(-.012,.003),(.003,-.019),(.008,-.052),
                      (.016,-.102),(.020,-.151),(.021-pocket,-.222),
                      (.019-pocket,-.276),(.012,-.298),(-.14,-.34)]])
        # A closed cross-section gives the fascia its rolled lower edge.
        z = top-.082
        sockets.append([(x,aft+dy,z+dz) for dy,dz in
                        [(-.022,.027),(.019,.025),(.027,.012),(.024,-.032),(-.025,-.036)]])
        lenses.append([(x*.997,aft+dy,z+dz) for dy,dz in
                       [(.022,.009),(.031,.009),(.032,-.004),(.023,-.007)]])
        bottom = .158 + .067*v**3 + .069*exp(-(v/.29)**4)
        lip = top-.298
        valance.append([(x,aft+dy,h) for dy,h in
                       [(-.09,lip+.045),(.010,lip+.003),(.022,lip-.015),(.018,lip-.044),
                        (-.008,bottom+.046),(-.03,bottom+.016),(-.08,bottom),(-.31,bottom+.026)]])
        ducktail.append([(x*.93,aft+dy,top+dz) for dy,dz in
                        [(-.27,.012),(-.20,.041),(-.115,.069),(-.075,.075),(-.061,.061),(-.086,.042),(-.17,.008)]])
    grid("Rolled rear bumper with inset registration recess",rows,paint,True)
    grid("Wraparound smoked tail light housing",sockets,rubber,True)
    grid("Tail lamp continuous curved LED ribbon",lenses,red,True)
    grid("Rear carbon diffuser and raised exhaust tunnel",valance,carbon,True)
    grid("Swept ducktail engine lid lip",ducktail,paint,True)
    for s in [-1,1]:
        for j in range(3):
            x = s*(.32+.177*j)
            y = 2.31-.12*abs(x)
            fin = [(y-.30,.24),(y+.021,.252),(y+.002,.136),(y-.12,.154)]
            grid("Diffuser channel fin", [[(x+dx,yy,zz) for yy,zz in fin] for dx in [-.011,.011]],carbon,True)
        # Rolled metal tubing with an actual hollow bore and a dark back wall.
        rows = []
        for y,r in [(2.27,.064),(2.39,.073),(2.409,.073),(2.414,.068),(2.407,.061),(2.313,.058)]:
            rows.append([(s*.087+r*cos(tau*j/48), y, .236+r*sin(tau*j/48)) for j in range(48)])
        exhaust = grid("Centre exhaust rolled titanium tip",rows,alloy,True)
        exhaust.data.materials.append(rubber)
        for face in exhaust.data.polygons:
            if face.index >= 4*48:
                face.material_index=1
        reflector = []
        for j in range(14):
            x = .56+j*.021
            u = x/.939
            y = 2.375-.115*u**2-.179*u**8
            reflector.append((s*x,y+.023,.381+.013*u*u))
        tube("Rear corner reflector",reflector,.011,reflector_finish)
        reverse_strip = []
        for j in range(10):
            x = .66+.012*j
            u = x/.939
            aft = 2.375-.115*u**2-.179*u**8
            top = .700+.018*u**2-.045*u**8
            reverse_strip.append((s*x,aft+.030,top-.104))
        tube("Reverse lamp strip",reverse_strip,.007,reversing)
        # Extraction blades behind the rear tyre follow the flared quarter.
        for j in range(2):
            y0 = 1.79+j*.13
            perimeter = [(y0+.025,.61),(y0+.055,.59),(y0+.108,.25),
                         (y0+.080,.225),(y0-.010,.270),(y0-.015,.405)]
            grid("Rear wheel wake guide",
                 [[(s*(profile(BODY,y,1)+dx),y,z) for y,z in perimeter]
                  for dx in [-.007,.014]],carbon,True)
    cube("Registration plate",(0,2.353,.463),(.415,.018,.106),plate,.008)
    badge("S GT 525",(0,2.364,.464),(pi/2,0,pi),.068,rubber)
    badge("P O R S C H E",(0,2.398,.565),(pi/2,0,pi),.045,alloy)


def badge(value,location,rotation,size,mat):
    c=bpy.data.curves.new(value,"FONT")
    c.body=value
    c.align_x="CENTER"
    c.align_y="CENTER"
    c.size=size
    c.materials.append(mat)
    o=bpy.data.objects.new(value,c)
    bpy.context.collection.objects.link(o)
    o.location=location
    o.rotation_euler=rotation


def front_depth(x):
    return -2.302+.240*(abs(x)/.9)**2.4


def front_intakes(boundary):
    holes=[]
    for side,outline in [(0,[(-.53,.237),(.53,.237),(.478,.426),(-.478,.426)]),
                         (-1,[(.551,.232),(.830,.242),(.846,.445),(.624,.469)]),
                         (1,[(.551,.232),(.830,.242),(.846,.445),(.624,.469)])]:
        if side == -1:
            outline=[(-x,z) for x,z in reversed(outline)]
        cx=sum(x for x,z in outline)/4
        cz=sum(z for x,z in outline)/4
        rounded=[]
        for i,corner in enumerate(outline):
            c=Vector(corner)
            a=c.lerp(Vector(outline[i-1]),.12)
            b=c.lerp(Vector(outline[(i+1)%4]),.12)
            for k in range(7):
                t=k/6
                rounded.append(tuple((1-t)**2*a+2*t*(1-t)*c+t*t*b))
        holes.append(rounded)
        def ring(depth,scale):
            result=[]
            for x,z in rounded:
                x=cx+(x-cx)*scale
                z=cz+(z-cz)*scale
                result.append((x,front_depth(x)+depth,z))
            return result
        grid("Recessed intake duct",[ring(0,1),ring(.008,.973),ring(.055,.88),ring(.105,.86)],carbon)
        core=ring(.107,.87)
        mesh("Recessed heat exchanger",core,[tuple(range(len(core)))],rubber,False)
        count=35 if side==0 else 11
        for i in range(count):
            x=min(v[0] for v in core)+.03+i*(max(v[0] for v in core)-min(v[0] for v in core)-.06)/(count-1)
            cube("Radiator vertical fin",(x,front_depth(x)+.1,cz),(.005,.009,.107),glass_dark,.002)
    # Triangulate the paint surrounding the three openings in elevation,
    # then sweep it back in 3D so the ducts meet the fenders seamlessly.
    verts=[]
    loops=[]
    for outline in [boundary]+holes:
        loops.append(list(range(len(verts),len(verts)+len(outline))))
        verts.extend(Vector(v) for v in outline)
    edges=[(loop[i-1],loop[i]) for loop in loops for i in range(len(loop))]
    vs,_,faces,*_=delaunay_2d_cdt(verts,edges,[],0,1e-6)
    def contains(point,loop):
        inside=False
        x,z=point
        for i,(ax,az) in enumerate(loop):
            bx,bz=loop[i-1]
            if (az>z)!=(bz>z) and x < ax+(bx-ax)*(z-az)/(bz-az):
                inside=not inside
        return inside
    visible=[]
    for face in faces:
        center=sum((vs[i] for i in face),Vector((0,0)))/len(face)
        if contains(center,boundary) and not any(contains(center,hole) for hole in holes):
            visible.append(tuple(face))
    assert len(visible)>100, "The front fascia must surround the duct openings"
    mesh("Moulded front apron with three open ducts",[(x,front_depth(x),z) for x,z in vs],visible,paint,False)


def details(front_boundary):
    for s in [-1,1]:
        # Each optical layer follows the actual compound curve of the fender.
        cx,cy = s*.717,-1.795
        def lens_point(a,radius,lift):
            x = cx + s*.156*radius*cos(a)
            y = cy + .240*radius*sin(a) + .032*radius*cos(a)
            return x,y,upper(y,x/profile(BODY,y,1))[2]+lift
        for name,radii,heights,finish in [
                ("Oval headlamp seal",[.005,.85,1.04],[.008,.012,.006],rubber),
                ("Headlamp chrome bezel",[.90,.958,1],[.021,.021,.012],alloy),
                ("Smoked oval lamp cover",[.005,.42,.77,.914],[.041,.039,.029,.019],glass_dark)]:
            rows=[[lens_point(tau*i/64,r,lift) for i in range(65)] for r,lift in zip(radii,heights)]
            grid(name,rows,finish)
        for offset_x,offset_y,radius,name,finish in [
                (0,-.044,.061,"Projector reflector",alloy),
                (0,-.044,.043,"Headlight lens projector",lamp),
                (-.064,.085,.015,"Daytime running light",lamp),
                (.064,.085,.015,"Daytime running light",lamp),
                (-.059,-.105,.013,"Daytime running light",lamp),
                (.059,-.105,.013,"Daytime running light",lamp)]:
            x=cx+offset_x
            y=cy+offset_y
            h=upper(y,x/profile(BODY,y,1))[2]
            oval(name,(x,y,h+.045), (radius,radius*1.14,.009),finish,.35)
        for j in range(4):
            y=-1.20+j*.074
            hood_patch("Front wing louvre",[(s*.783,y),(s*.918,y+.018),(s*.917,y+.051),(s*.788,y+.042)],carbon,.012)
        for name,y0,y1,z,h in [("Side sill",-.74,.82,.218,.08),("RS rocker stripe",-.76,.805,.315,.043)]:
            cube(name,(s*.92,(y0+y1)/2,z),(.052,y1-y0,h),carbon if name=="Side sill" else red_paint,.017)
        cube("Flush door handle",(s*.931,.327,.714),(.034,.134,.029),alloy,.013)
        seam=[(-.58,.729),(-.60,.678),(-.61,.577),(-.61,.422),(-.58,.344),(-.50,.287),
              (-.26,.281),(.05,.281),(.27,.285),(.395,.303),(.482,.362),(.509,.452),(.515,.62),(.503,.742)]
        tube("Stamped coupé door shut line",[(x+s*.003,y,z) for x,y,z in
              (side_surface(y,z,s) for y,z in seam)],.0048,rubber)
        # A flush dark throat sits in the pressed scallop. Its aft wall rises
        # out of the door skin and into the broad rear wheel arch.
        inlet=[(.535,.651),(.536,.621),(.589,.533),(.720,.403),(.747,.401),
               (.758,.426),(.731,.556),(.699,.644),(.650,.679),(.581,.682),(.545,.671)]
        cy,cz=.651,.531
        rows=[]
        for scale,height in [(1.12,.005),(1.0,.020),(.91,.009),(.77,.007)]:
            ring=[]
            for py,pz in inlet:
                y,z=cy+(py-cy)*scale,cz+(pz-cz)*scale
                x,_,_=side_surface(y,z,s)
                ring.append((x+s*height,y,z))
            rows.append(ring+[ring[0]])
        grid("Sculpted quarter air scoop rolled lip",rows,carbon)
        inner=rows[-1][:-1]
        hub=side_surface(cy,cz,s)
        center=(hub[0]+s*.006,cy,cz)
        mesh("Quarter scoop inner throat",inner+[center],[(i,(i+1)%len(inner),len(inner))
              for i in range(len(inner))],rubber)
        tube("Mirror stalk",[(s*.799,-.55,.777),(s*.934,-.54,.848)],.024,rubber)
        oval("Mirror housing",(s*.967,-.548,.855),(.111,.13,.058),carbon)
        oval("Mirror glass",(s*.973,-.451,.859),(.089,.027,.043),alloy)
        for axle,r,h in [(-1.18,.385,.35),(1.27,.399,.365)]:
            arc=[]
            for i in range(49):
                a=pi*i/48
                y=axle+r*cos(a)
                arc.append((s*(profile(BODY,y,1)*.996),y,h+r*sin(a)+.008))
            tube("Wheel arch edge",arc,.012,paint)
        badge("GT3 RS",(s*.932,.065,.345),(pi/2,0,s*pi/2),.1,red_paint)
    # Cambered carbon shelf with a rolled leading edge. At the corners it
    # sweeps aft and curls upwards into the return ahead of the wheel arch.
    splitter = []
    for i in range(81):
        u = (i-40)/40
        x = .951*u
        edge = abs(u)
        nose = front_depth(x) - .064 + .082*edge**12
        rise = .036*edge**8
        chord = .35-.19*edge**4
        splitter.append([(x,nose+chord*f,z+rise) for f,z in
                         [(0,.171),(.020,.179),(.10,.184),(.52,.196),
                          (.85,.209),(1,.222),(1,.183),(.50,.167),(.07,.163),(.012,.165)]])
    grid("Swept carbon splitter with rolled leading edge",splitter,carbon,True)
    front_intakes(front_boundary)
    hood_patch("Bonnet crest",[(-.023,-2.05),(0,-2.083),(.023,-2.05),(.024,-2.019),(-.024,-2.019)],gold,.008)
    for s in [-1,1]:
        # Raised outlet guide with a rolled crown, tapering into the bonnet
        # near the nose. The rear opening exposes the recessed vanes below.
        rows = []
        for j in range(25):
            t = j/24
            y = -1.78 + .64*t
            inner = .16 + .037*t
            outer = .276 + .144*t
            lip = .006 + .068*t*t
            row = []
            for fraction,height in [(0,.004),(.035,.009),(.17,lip*.95),
                                    (.27,lip),(.29,lip-.008),(.22,.007),(.84,.006),
                                    (.86,lip*.72),(.93,lip*.78),(1,.004)]:
                x = s*(inner + fraction*(outer-inner))
                row.append((x,y,upper(y,x/profile(BODY,y,1))[2]+height))
            rows.append(row)
        guide = grid("Sculpted bonnet air extractor",rows,carbon)
        guide.data.materials.append(rubber)
        for face in guide.data.polygons:
            if face.index % 9 == 5:
                face.material_index = 1
        for j in range(3):
            y = -1.40 + j*.073
            fin = []
            for py,h in [(y,.008),(y+.004,.032),(y+.014,.032),(y+.015,.006)]:
                fin.append([(s*x,py,upper(py,s*x/profile(BODY,py,1))[2]+h)
                            for x in [.248,.352]])
            grid("Bonnet outlet turning vane",fin,rubber)
    # Panel reveal delineates the lower hood from the two fender crowns.
    hood_edge = [(-.53,-.87),(-.552,-1.18),(-.547,-1.56),(-.525,-1.83),
                 (-.471,-2.017),(-.387,-2.09),(-.22,-2.12),(0,-2.13)]
    edge = hood_edge + [(-x,y) for x,y in reversed(hood_edge[:-1])]
    tube("Bonnet shut line",[(x,y,upper(y,x/profile(BODY,y,1))[2]+.004)
                             for x,y in edge],.004,glass_dark)
    rear_aero()


def run():
    global paint,carbon,glass,rubber,glass_dark,alloy,lamp,red,plate,leather,red_paint,gold
    bpy.ops.wm.read_factory_settings(use_empty=True)
    paint=material("GT silver pearl",(.74,.76,.78),.49,.22)
    carbon=material("Graphite aero composite",(.022,.026,.029),.33,.30)
    glass=material("Solar green laminated glazing",(.028,.041,.047),.19,.16)
    glass.diffuse_color=(.028,.041,.047,.55)
    glass.node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value=.55
    glass.surface_render_method="DITHERED"
    glass_dark=material("Lamp smoked chrome",(.073,.09,.10),.60,.16)
    rubber=material("Deep intake shadow",(.008,.010,.012),.03,.57)
    alloy=material("Machined aluminium trim",(.53,.55,.56),.83,.22)
    lamp=material("Headlamp pearl LED",(.88,.954,1.0),.35,.15,.64)
    red=material("Tail lamp ruby",(.61,.006,.009),.18,.23,.38)
    red_paint=material("Guards red graphic",(.64,.026,.012),.20,.34)
    leather=material("Graphite bucket upholstery",(.032,.034,.037),.02,.68)
    plate=material("Ivory registration plate",(.86,.88,.86),.03,.29)
    gold=material("Bonnet shield",(.56,.32,.051),.56,.28)
    front_boundary=body_shell()
    build_canopy()
    details(front_boundary)
    build_wheels(-1.18,1.27,1.61,1.67,.35,.365,.275,.315)
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    # Convert lettering, pipework and bevels to portable GLB geometry.
    bpy.ops.object.convert(target="MESH")
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(PROJECT/"source_blender/porsche_gt3_rs.blend"),compress=True)
    bpy.ops.export_scene.gltf(filepath=str(PROJECT/"vehicles/porsche_gt3_rs.glb"),
                              export_format="GLB",export_yup=True,export_animations=False)


if __name__ == "__main__":
    run()
