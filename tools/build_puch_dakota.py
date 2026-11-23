"""Build the blue Puch Dakota moped. Blender -Y is the riding direction."""
from math import cos, pi, sin, sqrt, tau
from pathlib import Path
import sys

import bpy
from mathutils import Vector

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
from build_porsche import grid, oval, tube
from build_vehicles import cube, cylinder, material, profile_loft

PROJECT = TOOLS.parent
bpy.ops.wm.read_factory_settings(use_empty=True)
blue = material("Dakota ultramarine enamel", (.019,.102,.406), .39,.25)
chrome = material("Chrome plated steel", (.68,.73,.78), .88,.20)
aluminium = material("Cast engine aluminium", (.29,.31,.32), .65,.37)
dark = material("Chain and dark hardware", (.050,.055,.059), .55,.41)
rubber = material("Road tyre charcoal", (.021,.023,.024), .03,.79)
leather = material("Black vinyl seat", (.012,.014,.018), .01,.70)
seam = material("Saddle piping", (.030,.031,.035), .01,.65)
lamp = material("Headlamp ribbed glass", (.80,.78,.61), .18,.18,.30)
red = material("Tail lamp ruby Dakota", (.57,.012,.007), .08,.23,.23)
cream = material("Warm ivory transfers", (.92,.85,.60), .10,.44)
badge_green = material("Puch crest green", (.014,.25,.073), .18,.32)
wheel_y = (-.565,.575)
radius = .285


def loft(name, stations, finish, count=28):
    """Elliptical cross-sections in XZ at each longitudinal station."""
    rings = []
    for y,half_width,center_z,half_height in stations:
        rings.append([(half_width*cos(tau*i/count),y,center_z+half_height*sin(tau*i/count))
                      for i in range(count)])
    return profile_loft(name,rings,finish,None)


def transverse_ring(name,y,z,profile,finish):
    rings = [[(x,y+r*cos(tau*i/64),z+r*sin(tau*i/64)) for i in range(64)] for x,r in profile]
    return profile_loft(name,rings+[rings[0]],finish,None,close_ends=False)


def mudguard(name,y,start,end,finish):
    rows = []
    for i in range(53):
        a=start+(end-start)*i/52
        row=[]
        for x,r in [(-.061,.312),(-.056,.319),(-.039,.328),(0,.332),
                    (.039,.328),(.056,.319),(.061,.312)]:
            row.append((x,y+r*cos(a),radius+r*sin(a)))
        rows.append(row)
    grid(name,rows,finish)
    for side in [-1,1]:
        edge=[(side*.061,y+.312*cos(start+(end-start)*i/52),
              radius+.312*sin(start+(end-start)*i/52)) for i in range(53)]
        tube("Rolled guard edge",edge,.003,chrome)


def decal(name,body,center,size,side,finish):
    font=bpy.data.curves.new(name,"FONT")
    font.body=body
    font.align_x="CENTER"
    font.align_y="CENTER"
    font.size=size
    obj=bpy.data.objects.new(name,font)
    bpy.context.collection.objects.link(obj)
    obj.location=center
    obj.rotation_euler=(pi/2,0,side*pi/2)
    font.materials.append(finish)


for y in wheel_y:
    before=set(bpy.context.scene.objects)
    transverse_ring("Rounded tread tyre",y,radius,
        [(-.029,.218),(-.038,.238),(-.039,.256),(-.030,.274),(-.015,.283),
         (0,radius),(.015,.283),(.030,.274),(.039,.256),(.038,.238),(.029,.218)],rubber)
    # Stagger the shallow shoulder ribs on either side of the smooth crown.
    vertices, faces = [], []
    for side in (-1, 1):
        for index in range(48):
            angle = tau * (index + .5 * (side > 0)) / 48
            base = len(vertices)
            for x, r, sweep in [(.006, .285, 0), (.018, .282, .019),
                                (.030, .276, .045), (.036, .266, .053)]:
                for offset, rise in [(-.018, -.001), (-.011, .0018),
                                     (.011, .0018), (.018, -.001)]:
                    a = angle + sweep + offset
                    vertices.append((side*x, y+(r+rise)*cos(a), radius+(r+rise)*sin(a)))
            for row in range(3):
                for col in range(3):
                    k = base + row*4 + col
                    quad = (k, k+1, k+5, k+4)
                    faces.append(quad if side > 0 else quad[::-1])
    tread_mesh = bpy.data.meshes.new("Road tread")
    tread_mesh.from_pydata(vertices, [], faces)
    tread_mesh.materials.append(rubber)
    tread = bpy.data.objects.new("Moulded shoulder tread", tread_mesh)
    bpy.context.collection.objects.link(tread)
    transverse_ring("Rolled chrome rim",y,radius,
        [(-.028,.221),(-.029,.232),(-.019,.235),(-.013,.226),(.013,.226),
         (.019,.235),(.029,.232),(.028,.221),(.012,.216),(-.012,.216)],chrome)
    cylinder("Drum hub",(0,y,radius),.057,.115,aluminium,vertices=32)
    for side in [-1,1]:
        cylinder("Spoke flange",(side*.051,y,radius),.067,.009,aluminium,vertices=32)
        for i in range(18):
            a=tau*(i+(.5 if side<0 else 0))/18
            b=a+(.40 if i%2==0 else -.40)
            anchor=Vector((side*.056,y+.061*cos(a),radius+.061*sin(a)))
            seat=Vector((side*.012,y+.221*cos(b),radius+.221*sin(b)))
            tube("Laced stainless spoke",[anchor,seat],.0028,chrome)
            tube("Spoke nipple",[seat.lerp(anchor,.055),seat],.0043,aluminium)
        cylinder("Axle nut",(side*.063,y,radius),.019,.015,chrome,vertices=6)
    batch="Performance tire Dakota "+("front" if y<0 else "rear")
    for obj in set(bpy.context.scene.objects)-before:
        obj["wheel_batch"]=batch

mudguard("Front bright mudguard",wheel_y[0],-.16,2.69,chrome)
# Deep pressed rear shell. The skirt flares around the tyre and rises under the saddle.
rear_rows=[]
for i in range(65):
    angle=-.12+3.08*i/64
    crown=max(0,sin(angle))
    shoulder=.342+.052*crown
    lip=.302+.015*crown
    half_width=.066+.019*crown
    profile=[(-1,lip),(-1.01,lip+.005),(-.99,shoulder-.015),(-.91,shoulder),
             (-.64,shoulder+.009),(0,shoulder+.013),(.64,shoulder+.009),
             (.91,shoulder),(.99,shoulder-.015),(1.01,lip+.005),(1,lip)]
    rear_rows.append([(w*half_width,wheel_y[1]+r*cos(angle),radius+r*sin(angle)) for w,r in profile])
grid("Deep valanced rear mudguard",rear_rows,blue)
for edge in [0,-1]:
    tube("Folded blue rear skirt edge",[row[edge] for row in rear_rows],.0035,blue)
# Pressed step-through backbone with the tank above its downward slope.
loft("Pressed blue frame",[
    (-.388,.038,.717,.061),(-.315,.049,.651,.077),(-.16,.062,.528,.076),
    (.00,.076,.444,.082),(.16,.088,.481,.109),(.292,.096,.597,.114),
    (.375,.071,.673,.052)],blue)
# Both finishes share a pressed waist. The dome rises toward the steering head.
tank_stations = [
    # longitudinal position, half width, waist height, crown rise, belly depth
    (-.392,.004,.747,.012,.014),(-.377,.064,.746,.066,.057),
    (-.341,.112,.745,.098,.085),(-.25,.136,.744,.134,.108),
    (-.15,.139,.743,.122,.109),(-.065,.132,.742,.095,.101),
    (.023,.111,.738,.061,.084),(.075,.083,.731,.036,.061),
    (.106,.047,.722,.021,.040),(.115,.004,.715,.009,.012)]
for name,finish,upper in [("Chrome tank crown",chrome,True),("Painted tank belly",blue,False)]:
    rows = []
    for y,w,z,rise,depth in tank_stations:
        row = []
        for j in range(33):
            angle = pi*(j/32 + (0 if upper else 1))
            row.append((w*cos(angle),y,z+(rise if upper else depth)*sin(angle)))
        rows.append(row[::-1])
    grid(name,rows,finish)
for side in (-1,1):
    tube("Rolled tank waist",[(side*w,y,z) for y,w,z,_,_ in tank_stations],.0028,chrome)
cylinder("Fuel cap",(0,-.237,.883),.036,.014,chrome,axis_x=False)
for side in [-1,1]:
    oval("Polished tank lettering panel",(side*.134,-.151,.777),(.005,.120,.033),chrome)
    decal("Classic tank transfer","CLASSIC",(side*.140,-.151,.777),.043,side,dark)
    oval("Puch medallion rim",(side*.128,-.297,.786),(.006,.029,.031),chrome)
    oval("Puch medallion enamel",(side*.134,-.297,.786),(.003,.025,.027),badge_green)
    decal("Harbour medallion lettering","SJÖ",(side*.138,-.297,.788),.012,side,cream)
    apron_outline=[(-.346,.692),(-.253,.697),(-.085,.683),(.037,.699),
                   (.118,.739),(.334,.741),(.401,.695),(.362,.626),
                   (.271,.559),(.106,.459),(.031,.446),(-.039,.467),(-.192,.564)]
    rings=[]
    for x,scale in [(.035,.97),(.063,1),(.080,.98)]:
        rings.append([(side*x,.042+(y-.042)*scale,.618+(z-.618)*scale) for y,z in apron_outline])
    profile_loft("Pressed frame apron",rings,blue,None)
    cover_outline=[(-.003,.625),(.036,.665),(.112,.713),(.258,.722),
                   (.316,.702),(.299,.630),(.278,.576),(.219,.553),
                   (.099,.527),(.045,.533),(.021,.550)]
    rings=[]
    for x,scale in [(.077,.95),(.085,1),(.095,.985),(.103,.925)]:
        rings.append([(side*x,.154+(y-.154)*scale,.626+(z-.626)*scale) for y,z in cover_outline])
    profile_loft("Stamped removable side cover",rings,blue,None)
    for z in [.567,.587]:
        tube("Embossed cover rib",[(side*.103,.094,z),(side*.106,.109,z+.002),
                                   (side*.106,.237,z+.036),(side*.103,.251,z+.039)],.003,blue)
    cylinder("Cover fastener",(side*.106,.252,.682),.008,.006,chrome,vertices=20)
    tube("Swing arm",[(side*.063,.091,.359),(side*.072,.324,.318),
                       (side*.065,.575,.285)],.023,blue)
    tube("Rear subframe",[(side*.059,.133,.465),(side*.071,.367,.715),
                          (side*.076,.553,.676)],.022,blue)
    tube("Rear suspension damper",[(side*.084,.559,.32),(side*.095,.420,.653)],.019,chrome)
    coils=[]
    for i in range(112):
        t=i/111
        a=tau*8*t
        coils.append((side*.09+.024*cos(a),.541-.102*t+.022*sin(a),
                     .36+.238*t+.008*sin(a)))
    tube("Rear shock spring",coils,.0048,dark)
    for y,z in [(.541,.36),(.439,.598)]:
        tube("Shock spring seat",[(side*.09,y+.002,z-.005),(side*.09,y-.002,z+.005)],.031,chrome)
    # Rubber gaiters bridge the moving stanchions and the painted fork shrouds.
    lower=Vector((side*.066,-.501,.523))
    upper=Vector((side*.068,-.440,.695))
    axis=(upper-lower).normalized()
    radial=axis.cross(Vector((1,0,0))).normalized()
    across=radial.cross(axis).normalized()
    folds=[]
    for step in range(19):
        center=lower.lerp(upper,step/18)
        lip=.024 if step%2==0 else .030
        folds.append([center+lip*(across*cos(tau*j/20)+radial*sin(tau*j/20)) for j in range(20)])
    profile_loft("Accordion fork gaiter",folds,rubber,None)
    tube("Polished fork stanchion",[(side*.066,-.51,.493),(side*.069,-.411,.760)],.018,chrome)
    tube("Painted fork slider",[(side*.065,-.565,.285),(side*.066,-.502,.526)],.024,blue)
    tube("Blue fork shroud",[(side*.068,-.445,.689),(side*.067,-.395,.816)],.026,blue)
    tube("Front stay",[(side*.064,-.565,.285),(side*.060,-.306,.445)],.005,chrome)
    tube("Rear carrier stay",[(side*.069,.575,.30),(side*.088,.763,.644)],.010,chrome)
    tube("Footrest stem",[(side*.085,.064,.333),(side*.202,.064,.333)],.012,chrome)
    cylinder("Footrest grip",(side*.169,.064,.333),.020,.072,rubber,vertices=16)

oval("Cast gearbox",(0,-.021,.368),(.117,.139,.089),aluminium)
# Draw the cast perimeter around the clutch drum and narrower gearbox nose.
cover_outline=[(-.133,.384),(-.121,.410),(-.082,.435),(-.030,.444),
               (.027,.439),(.071,.422),(.102,.390),(.105,.361),
               (.091,.336),(.055,.319),(-.008,.311),(-.078,.322),(-.122,.346)]
for side in [-1,1]:
    rings=[]
    for x,scale in [(.088,.93),(.100,1.0),(.108,1.0),(.124,.96),(.132,.86)]:
        rings.append([(side*x,-.01+(y+.01)*scale,.376+(z-.376)*scale) for y,z in cover_outline])
    profile_loft("Cast transmission cover",rings,aluminium,None)
    flange=[(side*.106,y,z) for y,z in cover_outline]
    tube("Transmission gasket",flange+[flange[0]],.0018,dark)
    for radius in (.049,.056):
        arc=[]
        for i in range(30):
            angle=-.85*pi+i*(1.54*pi/29)
            arc.append((side*.132,-.049+radius*cos(angle),.378+radius*sin(angle)))
        tube("Cast clutch surround",arc,.002,aluminium)
    cylinder("Oil inspection plug",(side*.134,.040,.389),.013,.009,aluminium,vertices=6)
    cylinder("Inspection plug face",(side*.140,.040,.389),.008,.003,chrome,vertices=24)
    for y,z in [(-.104,.392),(.059,.405),(.069,.349),(-.075,.341)]:
        cylinder("Cover screw",(side*.132,y,z),.0048,.006,chrome,vertices=12)
    cylinder("Machined clutch boss",(side*.132,-.049,.378),.044,.008,chrome,vertices=40)
    cylinder("Clutch boss recess",(side*.137,-.049,.378),.035,.004,aluminium,vertices=40)
# Finned angled cylinder and plug lead remain visible through the open frame triangle.
barrel=cube("Cylinder barrel",(0,-.145,.471),(.138,.085,.12),dark,.012)
barrel.rotation_euler.x=.30
axis=Vector((0,-.48,.877)).normalized()
across=Vector((0,axis.z,-axis.y))
for i in range(9):
    center=Vector((0,-.122,.426))+axis*(i*.013)
    width=.080+.011*sin(pi*i/8)
    rings=[]
    for thickness,scale in [(-.0033,.94),(-.0022,1),(.0022,1),(.0033,.94)]:
        rim=[]
        for j in range(28):
            u,v=cos(tau*j/28),sin(tau*j/28)
            rim.append(center+axis*thickness+Vector(((1 if u>=0 else -1)*abs(u)**.62*width*scale,0,0))
                       +across*((1 if v>=0 else -1)*abs(v)**.62*.053*scale))
        rings.append(rim)
    profile_loft("Cast barrel cooling fin",rings,aluminium,None)
cylinder("Spark plug ceramic",(0,-.179,.544),.011,.033,cream,axis_x=False)
tube("Ignition lead",[(0,-.179,.560),(.026,-.190,.582),(.046,-.123,.607),
                      (.032,-.06,.562)],.006,rubber)
tube("Exhaust header",[(.044,-.173,.431),(.103,-.201,.399),(.132,-.219,.334),
                        (.132,-.166,.266),(.117,-.066,.233),(.113,.267,.229)],.018,chrome)
loft("Cigar silencer",[(.10,.021,.230,.021),(.22,.032,.232,.032),(.56,.034,.25,.034),
                       (.675,.024,.261,.024),(.71,.017,.26,.017)],chrome).location.x=.118
oval("Silencer outlet",(.118,.708,.261),(.012,.009,.012),dark)
tube("Enclosed chain upper run",[(-.082,.009,.388),(-.085,.54,.366),
                                (-.084,.597,.348)],.027,blue)
tube("Chain return",[(-.078,.039,.327),(-.079,.333,.247),(-.078,.570,.234)],.006,dark)
# Long rounded vinyl bench with narrower nose and a slim chrome base.
saddle_profile=[(.006,.068,.776,.035),(.050,.102,.779,.049),(.21,.122,.785,.048),
                (.435,.129,.786,.050),(.52,.117,.788,.052),(.555,.065,.792,.040)]
# The upholstery has a broad crown and turns sharply down to the piped edge.
bench_sections = []
for y,width,z,height in saddle_profile:
    ring = []
    for j in range(40):
        u, v = cos(tau*j/40), sin(tau*j/40)
        ring.append((width*(1 if u>=0 else -1)*abs(u)**.72,y,
                     z+height*(1 if v>=0 else -1)*abs(v)**.72))
    bench_sections.append(ring)
profile_loft("Ribbed bench saddle",bench_sections,leather,None)
for i in range(13):
    y=.058+i*.036
    for first,last in zip(saddle_profile,saddle_profile[1:]):
        if first[0] <= y <= last[0]:
            t=(y-first[0])/(last[0]-first[0])
            width,z,h=[first[k]*(1-t)+last[k]*t for k in (1,2,3)]
            break
    points=[]
    for j in range(-8,9):
        u=.89*j/8
        points.append((u*width,y,z+h*(1-abs(u)**(2/.72))**(.72/2)+.0006))
    tube("Seat embossed rib",points,.0024,leather)
for side in [-1,1]:
    for first,last in zip(saddle_profile[1:-2],saddle_profile[2:-1]):
        for t in (.25,.75):
            y,width,z,h = [a+(b-a)*t for a,b in zip(first,last)]
            depth = .48
            flank = width*(1-depth**(2/.72))**(.72/2)
            oval("Black saddle stud",(side*flank,y,z-h*depth),(.003,.006,.006),dark)
    tube("Seat edge bead",[(side*w,y,z-.008) for y,w,z,h in saddle_profile],.0055,seam)
cube("Seat mounting rail",(0,.288,.731),(.184,.45,.022),chrome,.010)
for side in [-1,1]:
    tube("Luggage rack rail",[(side*.090,.497,.675),(side*.099,.688,.662),
                              (side*.096,.815,.656),(side*.080,.842,.656)],.008,chrome)
for y in [.57,.633,.696,.76,.818]:
    tube("Carrier cross tube",[(-.092,y,.662),(.092,y,.662)],.0068,chrome)
oval("Rear lamp base",(0,.920,.378),(.045,.031,.047),rubber)
oval("Rear lamp lens",(0,.943,.384),(.041,.019,.038),red)
# Tapered pressed headlamp nacelle, front bezel and fluted glass.
loft("Blue headlamp shell",[(-.551,.061,.793,.061),(-.532,.074,.794,.074),
                           (-.475,.071,.799,.067),(-.423,.044,.802,.045)],blue)
oval("Chrome headlamp bezel",(0,-.552,.793),(.074,.012,.074),chrome)
oval("Headlamp lens",(0,-.562,.793),(.066,.014,.064),lamp)
for i in range(-3,4):
    h=.053*(1-(i/4)**2)**.5
    tube("Lens flute",[(i*.014,-.572,.793-h),(i*.014,-.576,.793+h)],.0011,chrome)
cylinder("Speedometer bezel",(0,-.49,.863),.033,.012,chrome,axis_x=False)
cylinder("Speedometer dial",(0,-.49,.870),.029,.003,dark,axis_x=False)
for i in range(9):
    a=pi*(.20-i*.175)
    tube("Dial graduation",[(r*cos(a),-.49+r*sin(a),.872) for r in [.0145,.018]],.00075,cream)
    if i % 2 == 0:
        font = bpy.data.curves.new("Dial numeral", "FONT")
        font.body = str(i*5)
        font.align_x = font.align_y = "CENTER"
        font.size = .0065
        numeral = bpy.data.objects.new("Dial numeral " + font.body, font)
        bpy.context.collection.objects.link(numeral)
        numeral.location = (.023*cos(a),-.49+.023*sin(a),.872)
        numeral.rotation_euler.z = pi
        font.materials.append(cream)
needle = tube("SpeedNeedle",[(0,0,0),(.016*cos(.20*pi),.016*sin(.20*pi),0)],.0011,red)
needle.location = (0,-.49,.874)
cylinder("Steering clamp",(0,-.391,.843),.036,.053,chrome,axis_x=False)
for side in [-1,1]:
    tube("Swept chrome handlebar",[(0,-.395,.868),(side*.108,-.394,.875),
         (side*.179,-.383,.954),(side*.233,-.363,.984),(side*.302,-.323,.985)],.012,chrome)
    tube("Handlebar grip",[(side*.237,-.361,.985),(side*.309,-.318,.986)],.018,rubber)
    for rib in range(8):
        along=rib/8
        start=Vector((side*(.242+.064*along),-.358+.039*along,.985))
        tube("Grip moulding",[start,start+Vector((side*.002,.001,0))],.0195,rubber)
    tube("Brake lever",[(side*.214,-.373,.978),(side*.247,-.405,.965),
                        (side*.31,-.366,.964)],.0056,chrome)
    tube("Brake cable",[(side*.213,-.382,.973),(side*.143,-.506,.880),
                        (side*.053,-.482,.810),(side*.063,-.461,.670)],.0036,rubber)
# A single period-style round mirror on the left lever perch.
cylinder("Mirror stem locknut", (.219,-.373,.986), .011,.014,chrome,axis_x=False,vertices=6)
tube("Bent mirror stem",[(.219,-.373,.987),(.224,-.389,1.043),
                         (.268,-.412,1.104),(.285,-.418,1.118)],.005,chrome)
oval("Mirror swivel",(.285,-.418,1.118),(.010,.010,.010),dark)
mirror_center = Vector((.285,-.416,1.151))
mirror_normal = Vector((-.28,.94,.19)).normalized()
for name,offset,dimensions,finish in [
    ("Pressed mirror shell",0,(.049,.013,.049),chrome),
    ("Mirror edge seal",.009,(.046,.006,.046),rubber),
    ("Silvered mirror glass",.013,(.043,.003,.043),chrome),
]:
    shell = oval(name,mirror_center + mirror_normal*offset,dimensions,finish)
    shell.rotation_euler = Vector((0,1,0)).rotation_difference(mirror_normal).to_euler()
tube("Front brake cable",[(.063,-.461,.670),(.078,-.472,.535),(.078,-.54,.324)],.0035,rubber)
tube("Kickstart lever",[(.127,.015,.373),(.149,.083,.392),(.16,.122,.485)],.008,chrome)
cylinder("Kickstart tread",(.180,.122,.484),.011,.048,rubber,vertices=16)
tube("Gear selector",[(-.128,-.035,.35),(-.143,-.112,.343)],.006,chrome)
cylinder("Selector toe pad",(-.155,-.118,.343),.012,.04,rubber,vertices=12)
# Keep all parts editable in the Blender source. Batch the exported mesh by wheel and finish.
bpy.ops.object.select_all(action="SELECT")
bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
bpy.ops.object.convert(target="MESH")
for name,position in {
    "RiderSeat": (0,.16,.83),
    "GripLeft": (.27,-.34,.985), "GripRight": (-.27,-.34,.985),
    "PegLeft": (.17,.064,.333), "PegRight": (-.17,.064,.333)
}.items():
    anchor=bpy.data.objects.new(name,None)
    anchor.empty_display_type="PLAIN_AXES"
    anchor.empty_display_size=.025
    anchor.location=position
    bpy.context.collection.objects.link(anchor)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(PROJECT/"source_blender/PuchDakota.blend"),compress=True)
groups={}
for obj in list(bpy.context.scene.objects):
    if obj.type=="MESH" and obj.name != "SpeedNeedle":
        groups.setdefault(obj.get("wheel_batch",obj.data.materials[0].name),[]).append(obj)
for name,parts in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    if len(parts)>1:
        bpy.ops.object.join()
    parts[0].name=name
bpy.ops.export_scene.gltf(filepath=str(PROJECT/"vehicles/puch_dakota.glb"),
                          export_format="GLB",export_yup=True,export_animations=False)
