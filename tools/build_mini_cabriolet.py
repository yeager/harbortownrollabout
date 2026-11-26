"""Build the four-seat Mino Kuper S in metres; Blender -Y is the nose."""
from math import cos, exp, pi, sin, sqrt, tau
from pathlib import Path
import sys

import bpy
from mathutils import Vector

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
from build_track_coupe import grid, oval, profile, tube
from build_vehicles import cube, cylinder, material, text_obj

PROJECT = TOOLS.parent
bpy.ops.wm.read_factory_settings(use_empty=True)
paint = material("Melting silver metallic", (.47,.49,.49), .65, .25)
trim = material("Grained graphite arch cladding", (.033,.038,.041), .04,.66)
rubber = material("Tyre rubber", (.017,.019,.021),.02,.82)
chrome = material("Polished brightwork", (.69,.72,.74),.82,.17)
alloy = material("Anthracite alloy", (.135,.145,.153),.72,.24)
shadow = material("Intake and panel shadow", (.012,.015,.018),.1,.55)
seat = material("Cream grey woven upholstery", (.61,.58,.51),.01,.78)
cloth = material("Woven hood textile", (.039,.043,.045),.0,.91)
stitch = material("Upholstery seams", (.36,.35,.32),.01,.79)
lamp = material("Headlamp light guide", (.82,.91,.95),.22,.17,.45)
red = material("Tail lamp ruby lens", (.62,.013,.016),.17,.20,.25)
pane = material("Tinted laminated windshield", (.40,.57,.61),.06,.14)
pane.diffuse_color=(.40,.57,.61,.24)
pane.node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value=.24
pane.surface_render_method="DITHERED"
# Longitudinal stations govern bumper wrap, the rising bonnet and rear haunches.
stations = [(-1.89,.54,.68),(-1.83,.69,.75),(-1.66,.80,.84),
            (-1.38,.845,.91),(-1.03,.855,.96),(-.75,.846,1.00),
            (-.52,.84,.985),(.05,.835,.955),(.56,.85,.965),
            (1.08,.853,1.005),(1.48,.835,1.005),(1.70,.795,.96),
            (1.82,.71,.92),(1.85,.63,.89)]
axles=(-1.235,1.23)


def shell_floor(y):
    for axle in axles:
        distance=abs(y-axle)
        if distance<.36:
            return .314+sqrt(max(0,.36**2-distance**2))
        if distance<.39:
            return .195+(.39-distance)/.03*(.314-.195)
    return .195


def width(y):
    return profile(stations,y,1)


def belt(y):
    return profile(stations,y,2)


def side_point(y, fraction, side):
    bottom=shell_floor(y)
    # Rolled outer sill and shoulder leave a highlight along the doors.
    inset=.038*(1-fraction)**5+.040*fraction**6
    return (side*(width(y)-inset+.016*sin(pi*fraction)),y,bottom+(belt(y)-bottom)*fraction)


def deck(start,end,name,rise):
    rows=[]
    for i in range(31):
        y=start+(end-start)*i/30
        rows.append([(u*(width(y)-.040),y,belt(y)+rise*(1-u**4))
                     for u in [j/14 for j in range(-14,15)]])
    grid(name,rows,paint)


for side in (-1,1):
    rows=[]
    ys=sorted({-1.89+i*3.74/180 for i in range(181)} |
              {axle+sign*r for axle in axles for sign in [-1,1] for r in [.36,.39]})
    for y in ys:
        rows.append([side_point(y,i/12,side) for i in range(13)])
    side_skin = grid("Pressed side with open wheel arches",rows,paint)
    if side > 0:
        side_skin.data.flip_normals()
    # Cabin rim folds inwards around the passenger compartment.
    rows=[]
    for i in range(43):
        y=-.72+2.12*i/42
        w=width(y)
        z=belt(y)
        rows.append([(side*(w-.04),y,z),(side*(w-.087),y,z+.009),
                     (side*(w-.118),y,z-.012),(side*(w-.13),y,z-.10)])
    grid("Door cap",rows,paint)
    tube("Waist chrome",[(side*(width(y)-.051),y,belt(y)+.012)
                         for y in [-.76+i*2.22/40 for i in range(41)]],.011,chrome)
    tube("Door weather seal",[(side*(width(y)-.112),y,belt(y))
                              for y in [-.71+i*2.10/40 for i in range(41)]],.012,trim)
    for axle in axles:
        rows=[]
        for i in range(57):
            a=-.23+(pi+.46)*i/56
            row=[]
            for radius,offset in [(.327,-.018),(.339,.011),(.348,.022),(.383,.012),(.392,-.013)]:
                y=axle+radius*cos(a)
                row.append((side*(width(y)+offset),y,.314+radius*sin(a)))
            rows.append(row)
        grid("Black wheel arch eyebrow",rows,trim)
    tube("Door shut line",[(side_point(y,(z-shell_floor(y))/(belt(y)-shell_floor(y)),side)[0]+side*.003,y,z) for y,z in
          [(-.69,.90),(-.74,.76),(-.71,.44),(-.62,.32),(-.48,.30),
           (.48,.30),(.59,.34),(.625,.44),(.63,.74),(.615,.94)]],.0065,shadow)
    cube("Sill cladding",(side*.815,0,.23),(.08,1.66,.12),trim,.035)
    oval("Handle pocket",(side*.844,.47,.844),(.014,.095,.036),shadow)
    oval("Chrome pull",(side*.861,.463,.853),(.020,.077,.018),chrome)
    tube("Mirror stalk",[(side*.785,-.64,.975),(side*.88,-.63,1.06)],.021,trim)
    oval("Painted mirror",(side*.928,-.645,1.074),(.09,.10,.058),paint)
    oval("Mirror backing",(side*.929,-.576,1.075),(.070,.018,.045),chrome)

deck(-1.89,-.72,"Clamshell bonnet",.047)
deck(1.40,1.85,"Boot lid",.027)
for y,deck_rise in [(-1.89,.047),(1.85,.027)]:
    rows=[]
    for i in range(29):
        u=(i-14)/14
        section=[]
        for j in range(13):
            fraction=j/12
            side_x,_,z=side_point(y,fraction,1)
            section.append((u*side_x,y,z+fraction**5*deck_rise*(1-u**4)))
        rows.append(section)
    fascia = grid("Bumper fascia",rows,paint)
    if y < 0:
        fascia.data.flip_normals()
cube("Cabin carpet",(0,.26,.34),(1.48,2.30,.14),shadow,.055)
for side in [-1,1]:
    cube("Inner door card",(side*.734,.27,.668),(.089,1.96,.53),seat,.042)
    cube("Padded door armrest",(side*.675,.03,.724),(.090,.63,.076),trim,.032)
cube("Dashboard",(0,-.645,.899),(1.46,.31,.175),trim,.076)
cube("Rear bulkhead",(0,1.28,.69),(1.48,.24,.57),seat,.07)


def upholstery(x,y,rear):
    w=.55 if rear else .59
    cube("Seat squab",(x,y,.515),(w,.43,.16),seat,.075)
    back=cube("Seat back",(x,y+.18,.764),(w,.14,.44),seat,.063)
    back.rotation_euler.x=-.12
    for offset in [-.23,.23]:
        oval("Raised side bolster",(x+offset,y+.126,.76),(.063,.075,.206),seat,-.12)
    for z in [.64,.70,.76,.82,.88]:
        tube("Stitched seat rib",[(x-.16,y+.099,z),(x,y+.089,z-.012),
                                 (x+.16,y+.099,z)],.003,stitch)
    for offset in [-.06,.06]:
        tube("Headrest post",[(x+offset,y+.19,.965),(x+offset,y+.20,1.032)],.010,chrome)
    cube("Padded headrest",(x,y+.204,1.087),(.264,.128,.168),seat,.058)


for x in [-.38,.38]:
    upholstery(x,-.19,False)
    upholstery(x,.705,True)
cube("Centre console",(0,-.12,.56),(.19,.72,.19),trim,.052)
oval("Gear lever",(0,-.36,.68),(.03,.032,.046),chrome)
tube("Raked steering column",[(-.38,-.59,.855),(-.38,-.426,.916)],.035,shadow)
center=Vector((-.38,-.423,.927))
steer_ring=[center+Vector((.162*cos(a),.058*sin(a),.15*sin(a))) for a in [tau*i/48 for i in range(49)]]
tube("Three spoke steering wheel",steer_ring,.016,trim)
oval("Airbag pad",center,(.06,.032,.05),trim)
for k in [0,16,32]:
    tube("Steering spoke",[center,steer_ring[k]],.013,chrome)
oval("Round centre instrument surround",(0,-.488,.942),(.135,.020,.132),chrome)
oval("Centre instrument face",(0,-.464,.945),(.120,.012,.116),shadow)
cube("Instrument screen",(0,-.449,.946),(.148,.009,.072),pane,.004)
# Slightly bowed windshield; the door glasses are lowered.
def screen(u,t):
    return (u*(.773-.074*t),-.708+.29*t+.080*u*u,1.012+.415*t-.021*u*u)

grid("Laminated curved windscreen",[[screen(i/12,j/8) for i in range(-12,13)] for j in range(9)],pane)
for side in [-1,1]:
    tube("Windscreen pillar",[screen(side,j/8) for j in range(9)],.032,trim)
for t in [0,1]:
    tube("Windscreen surround",[screen(i/20,t) for i in range(-20,21)],.030,trim)
for x in [-.34,.37]:
    tube("Wiper arm",[(x,-.699,1.026),(x-.12,-.643,1.08)],.007,shadow)
    tube("Wiper blade",[(x-.33,-.622,1.099),(x+.135,-.638,1.077)],.008,shadow)
for i in range(4):
    y=1.22+i*.086
    folded=cube("Folded canvas roof",(0,y,1.025+.042*sin(pi*i/3)),(1.50-.07*i,.135,.102),cloth,.048)
    tube("Folded hem",[(-.67,y+.026,folded.location.z+.050),(0,y+.048,folded.location.z+.050),
                      (.67,y+.026,folded.location.z+.050)],.006,seat)

# Subtle woven Union Jack bands follow each ridge of the stowed soft top.
weave=material("Graphite flag weave",(.099,.105,.111),.01,.82)
for row in range(4):
    y=1.22+row*.086
    z=1.025+.042*sin(pi*row/3)+.052
    for sign in [-1,1]:
        cx=sign*(row-1.5)*.385
        grid("Woven saltire", [[(max(-.63,min(.63,cx+sign*t*.385+dx)),y+t*.082,z+.001)
            for dx in [-.055,.055]] for t in [-.48,0,.48]],weave)
    cube("Woven vertical cross",(0,y,z+.002),(.10,.087,.004),weave,.001)
    if row==2:
        cube("Woven transverse cross",(0,y-.035,z+.002),(1.31,.035,.004),weave,.001)


def front_grille():
    # The grille follows the rounded bumper in plan and tapers below the waist.
    rows=[]
    for radius in [.07,.55,1.0]:
        row=[]
        for i in range(65):
            a=tau*i/64
            cx,sz=cos(a),sin(a)
            x=.47*radius*(1+.12*sz)*(abs(cx)**.68)*(1 if cx>=0 else -1)
            z=.554+.139*radius*(abs(sz)**.72)*(1 if sz>=0 else -1)
            row.append((x,-1.908+.028*(abs(x)/.47)**2,z))
        rows.append(row)
    grid("Rounded grille recess",rows,shadow)
    tube("Bright grille bezel",rows[-1],.016,chrome)
    for k in [-2,-1,0,1,2]:
        z=.554+.043*k
        span=.433-.026*abs(k)+.012*k
        tube("Horizontal grille blade",[(span*j/12,-1.911+.027*(span*j/12/.47)**2,z)
                                      for j in range(-12,13)],.009,chrome)


front_grille()
oval("Lower bumper inlet",(0,-1.883,.309),(.49,.039,.046),shadow)
for side in [-1,1]:
    # Round headlamp pods lean back into the clamshell bonnet shoulders.
    center=Vector((side*.664,-1.763,.791))
    normal=Vector((side*.33,-.72,.61)).normalized()
    center+=normal*.026
    ex=Vector((1,0,0)).project(normal)
    tangent=(Vector((1,0,0))-ex).normalized()
    up=normal.cross(tangent).normalized()
    if up.z<0:
        up=-up
    def lens_points(rx,rz,depth):
        return [center+tangent*(rx*cos(tau*i/48))+up*(rz*sin(tau*i/48))+normal*depth
                for i in range(49)]
    grid("Sculpted headlight pocket",[lens_points(.205,.229,-.151),lens_points(.184,.200,-.078),lens_points(.170,.185,-.027),lens_points(.151,.176,.018)],paint)
    tube("Chrome headlamp ring",lens_points(.145,.167,.026),.015,chrome)
    grid("Round graphite lamp bowl",[lens_points(.14,.164,.023),lens_points(.09,.104,.034),
                                     lens_points(.002,.002,.037)],trim)
    tube("Circular daytime running lamp",lens_points(.115,.134,.041),.010,lamp)
    grid("Projector lens",[lens_points(.052,.052,.045),lens_points(.003,.003,.058)],pane)
    oval("Rear lamp bright frame",(side*.652,1.795,.756),(.118,.048,.155),chrome)
    oval("Rear red lamp",(side*.652,1.828,.756),(.102,.029,.140),red)
    for z in [.714,.764,.813]:
        tube("Rear lamp bars",[(side*.652-.057,1.854,z),(side*.652+.053,1.854,z)],.006,red)
    for y in axles:
        existing = set(bpy.context.scene.objects)
        cylinder("Tyre",(side*.78,y,.306),.306,.173,rubber,vertices=48)
        cylinder("Wheel rim",(side*.854,y,.306),.208,.038,alloy,vertices=48)
        cylinder("Recessed wheel barrel",(side*.874,y,.306),.182,.010,shadow,vertices=40)
        for i in range(8):
            angle=tau*i/8
            for d in [-.025,.025]:
                a=angle+d
                tube("Forked spoke",[(side*.886,y+.063*cos(a),.306+.063*sin(a)),
                     (side*.878,y+.120*cos(a+.09),.306+.120*sin(a+.09)),
                     (side*.883,y+.188*cos(a+d*3),.306+.188*sin(a+d*3))],.011,alloy)
        cylinder("Hubcap",(side*.888,y,.306),.059,.019,alloy,vertices=28)
        axle_name = "front" if y < 0 else "rear"
        side_name = "left" if side < 0 else "right"
        for part in set(bpy.context.scene.objects) - existing:
            part["wheel_batch"] = f"Performance tire {axle_name} {side_name}"
plate_yellow=material("Rear registration yellow",(.94,.65,.052),.04,.30)
cube("Rear number plate",(0,1.864,.515),(.415,.018,.112),plate_yellow,.007)
number=text_obj("Registration","S174 MBA",(0,1.876,.487),.071,shadow)
number.rotation_euler=(pi/2,0,pi)
# Centre the converted text mesh without affecting its reading direction.
xs=[v.co.x for v in number.data.vertices]
number.location.x=(min(xs)+max(xs))/2
for side in [-1,1]:
    oval("Bumper corner air channel",(side*.55,-1.862,.36),(.066,.028,.085),trim)
    tube("Rear gate seam",[(side*.607,1.833,.849),(side*.602,1.848,.56),
                          (side*.52,1.855,.415),(side*.30,1.855,.405)],.005,shadow)
sport_red=material("Kuper S red lettering",(.72,.018,.012),.17,.29)
sport=text_obj("Kuper S lettering","S",(.34,1.855,.79),.062,sport_red)
sport.rotation_euler=(pi/2,0,pi)
cube("Boot handle",(0,1.879,.73),(.259,.034,.03),chrome,.014)
tube("Exhaust outlet",[(-.57,1.62,.233),(-.57,1.82,.218)],.047,trim)
# The Mino badge has a copper monogram inset into a dark oval.
badge_copper = material("Mino copper enamel", (.65, .25, .08), .42, .29)
for y,z,sign in [(-1.897,.743,-1),(1.858,.815,1)]:
    oval("Mino badge rim", (0,y,z), (.052,.011,.028), chrome)
    oval("Mino badge enamel", (0,y+sign*.009,z), (.046,.005,.022), trim)
    tube("Mino monogram", [(x,y+sign*.014,z+dz) for x,dz in
         [(-.026,-.012),(-.026,.012),(0,-.004),(.026,.012),(.026,-.012)]],
         .0026,badge_copper)
bpy.ops.object.select_all(action="SELECT")
bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
bpy.ops.object.convert(target="MESH")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(PROJECT/"source_blender/compact_convertible.blend"),compress=True)
# Ship a small set of material batches while keeping the editable source parts.
groups = {}
for obj in list(bpy.context.scene.objects):
    if obj.type == "MESH":
        groups.setdefault(obj.get("wheel_batch", obj.data.materials[0].name), []).append(obj)
for finish, parts in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    if len(parts) > 1:
        bpy.ops.object.join()
    parts[0].name = finish
bpy.ops.export_scene.gltf(filepath=str(PROJECT/"vehicles/compact_convertible.glb"),
                          export_format="GLB",export_yup=True,export_animations=False)
