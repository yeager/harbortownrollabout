"""Volva HT-6 patrol SUV, measured longitudinal sections in metres (-Y nose)."""
from math import cos, exp, pi, sin, sqrt, tau

import bpy

from build_track_coupe import grid, oval, profile, tube
from build_vehicles import BLUE_LAMP, RUBBER, cube, cylinder, material


# station, maximum half-width, shoulder height, bonnet/deck centre height
BODY = [(-2.24,.836,1.12,1.14),(-2.12,.902,1.18,1.21),(-1.92,.977,1.26,1.31),
        (-1.61,1.025,1.34,1.39),(-1.27,1.034,1.38,1.42),(-.90,1.019,1.39,1.42),
        (-.26,1.011,1.38,1.41),(.48,1.015,1.385,1.41),(.95,1.024,1.405,1.43),
        (1.43,1.039,1.435,1.47),(1.84,1.026,1.47,1.49),(2.09,.987,1.465,1.47),
        (2.265,.902,1.40,1.435)]
AXLES = (-1.435,1.425)
AXLE_Z = .438
TYRE = .426


def wrap(y,u):
    # Viewed from above, both bumpers roll around the corners of the body.
    nose=max(0,1-(y+2.24)/.42)
    tail=max(0,1-(2.265-y)/.43)
    return y+(.16*tail*tail-.19*nose*nose)*(1-u*u)


def arch(y):
    for axle in AXLES:
        d=abs(y-axle)
        if d<=.481:
            return AXLE_Z+sqrt(max(0,.481**2-d*d))
        if d<.515:
            t=(d-.481)/.034
            return (1-t)*AXLE_Z+t*.332
    return .332


def side_point(side,y,z,offset=0):
    # Body section: pulled-in sill, shallow swage, crisp top shoulder.
    w=profile(BODY,y,1)
    top=profile(BODY,y,2)
    d=(.040*exp(-((z-.40)/.17)**2)+.026*exp(-((z-.84)/.22)**2)
       +.067*exp(-((z-top)/.065)**2))
    return (side*(w-d+offset),y,z)


def face_y(y,x,z=1.0):
    side=side_point(1,y,z)[0]
    return wrap(y,x/side)


def face_patch(name,y,outline,depth,finish):
    # Cross-sections follow the curvature across the full width; a large flat
    # polygon here would disappear into the centre of the rolled bumper.
    direction=-1 if y<0 else 1
    levels=sorted(set(z for x,z in outline))
    rows=[]
    for index,z0 in enumerate(levels):
        z=z0
        if index==0: z+=.0001
        if index==len(levels)-1: z-=.0001
        intersections=[]
        for (x1,z1),(x2,z2) in zip(outline,outline[1:]+outline[:1]):
            if min(z1,z2)<=z<max(z1,z2):
                intersections.append(x1+(x2-x1)*(z-z1)/(z2-z1))
        if len(intersections)<2:
            continue
        left,right=min(intersections),max(intersections)
        row=[]
        for i in range(31):
            x=left+(right-left)*i/30
            row.append((x,face_y(y,x,z)+direction*depth,z))
        rows.append(row)
    return grid(name,rows,finish)


def face_line(name,y,points,depth,radius,finish):
    sign=-1 if y<0 else 1
    line=[]
    for (ax,az),(bx,bz) in zip(points,points[1:]):
        segments=max(1,int(abs(bx-ax)/.035))
        for i in range(segments):
            t=i/segments
            x,z=ax+(bx-ax)*t,az+(bz-az)*t
            line.append((x,face_y(y,x,z)+sign*depth,z))
    x,z=points[-1]
    line.append((x,face_y(y,x,z)+sign*depth,z))
    return tube(name,line,radius,finish)


def panel_word(name,word,center,size,angle,finish):
    data=bpy.data.curves.new(name,"FONT")
    data.body=word
    data.size=size
    data.align_x="CENTER"
    data.align_y="CENTER"
    data.materials.append(finish)
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.location=center
    obj.rotation_euler=(pi/2,0,angle)
    return obj


def build():
    root=bpy.data.objects.new("Volva HT-6 patrol",None)
    bpy.context.collection.objects.link(root)
    white=material("XC60 ceramic white",(.89,.91,.89),.26,.25)
    glass=material("XC60 solar glass",(.028,.057,.074),.31,.15)
    black=material("XC60 grille basalt",(.018,.022,.025),.23,.32)
    trim=material("Grained lower cladding",(.032,.038,.043),.09,.55)
    chrome=material("Satin silver mouldings",(.50,.57,.59),.80,.24)
    alloy=material("XC60 machined wheel faces",(.38,.41,.43),.76,.25)
    blue=material("Polis ultramarine",(.014,.092,.455),.11,.31)
    yellow=material("Polis fluorescent lime",(.80,.94,.015),.09,.35,.065)
    ruby=material("Tail lamp XC60 red blade",(.61,.006,.012),.09,.20,.36)
    reflector=material("Bumper reflector red acrylic",(.45,.009,.014),.24,.19)
    reverse=material("Reverse lamp XC60",(.79,.85,.83),.14,.20)
    led=material("XC60 crystalline DRL",(.85,.94,1),.14,.17,.43)
    amber=material("XC60 amber side repeater",(.96,.39,.03),.14,.19)
    body_ys=sorted({-2.24+(2.265+2.24)*i/155 for i in range(156)}|
                   {axle+s*r for axle in AXLES for s in [-1,1] for r in [.481,.515]})
    for side in [-1,1]:
        rows=[]
        for y in body_ys:
            lower,upper=arch(y),profile(BODY,y,2)
            rows.append([side_point(side,y,lower+(upper-lower)*i/16) for i in range(17)])
        skin=grid("Pressed door skin and quarter panels",rows,white)
        if side>0:
            skin.data.flip_normals()
        for axle in AXLES:
            rows=[]
            for i in range(61):
                a=-.19+(pi+.38)*i/60
                row=[]
                for r,dx in [(.449,-.023),(.454,.009),(.470,.022),(.488,.013),(.497,-.002)]:
                    y=axle+r*cos(a)
                    row.append(side_point(side,y,AXLE_Z+r*sin(a),dx))
                rows.append(row)
            grid("Wheel arch protection",rows,trim)
        # Long scalloped side sill below the actual door cut lines.
        grid("Satin rocker blade",[[side_point(side,y,z,dx) for z,dx in [
            (.340,.002),(.371,.016),(.43,.019),(.443,.002)]]
            for y in [-.915,-.82,-.4,0,.44,.82,.905]],trim)
        for path in [[(-.90,1.32),(-.97,1.19),(-.985,.86),(-.896,.55),
                      (-.81,.468),(-.15,.45),(.145,.466),(.168,.62),(.158,1.065),(.15,1.335)],
                     [(.168,.466),(.63,.473),(.795,.518),(.905,.68),(1.019,.939),
                      (1.115,1.09),(1.137,1.26),(1.164,1.353)]]:
            tube("Door reveal",[side_point(side,y,z,.004) for y,z in path],.0065,trim)
        for y in [.011,.971]:
            at=side_point(side,y,1.240,.009)
            oval("Door handle recess",at,(.010,.111,.034),trim)
            oval("Flush painted handle",(at[0]+side*.013,y-.005,1.25),(.018,.091,.019),white)
        # Apply transfers to the compound side shape, not to flat boards.
        for column in range(6):
            begin=-1.007+.337*column
            for row in range(2):
                z=.75+.153*row
                points=[[side_point(side,begin+.334*k/4,z+h,.007)
                         for h in [0,.150]] for k in range(5)]
                grid("Retroreflective Battenburg panel",points,blue if (row+column)%2==0 else yellow)
        at=side_point(side,-.41,1.154,.022)
        panel_word("Patrol door lettering","POLIS",at,.230,side*pi/2,blue)
        at=side_point(side,.68,1.168,.018)
        panel_word("Unit fleet identifier","31-5130",at,.065,side*pi/2,blue)

    # Two end caps share the stamped sides and rolled edges of the hood and rear deck.
    def deck(y,u):
        w=side_point(1,y,profile(BODY,y,2))[0]
        shoulder=profile(BODY,y,2)
        center=profile(BODY,y,3)
        value=shoulder+(center-shoulder)*(1-u**4)
        if y<-.97:
            value+=.031*exp(-((abs(u)-.75)/.12)**2)*sin(pi*(y+2.24)/1.27)
        return (w*u,wrap(y,u),value)

    for start,end,label in [(-2.24,-.885,"Twin-ridge clamshell bonnet"),(1.875,2.265,"Tailgate shoulder")]:
        grid(label,[[deck(start+(end-start)*i/34,j/20) for j in range(-20,21)]
                    for i in range(35)],white)
    for y in [BODY[0][0],BODY[-1][0]]:
        rows=[]
        for j in range(-24,25):
            u=j/24
            row=[]
            for i in range(15):
                t=i/14
                z=.332+t*(profile(BODY,y,2)-.332)
                p=side_point(1,y,z)
                row.append((u*p[0],wrap(y,u),z+t**5*(deck(y,u)[2]-profile(BODY,y,2))))
            rows.append(row)
        cap=grid("Wrapped bumper stamping",rows,white)
        if y<0:
            cap.data.flip_normals()
    for side in [-1,1]:
        points=[]
        for i in range(31):
            t=i/30
            x,y,z=deck(-2.21+1.23*t,side*(.64+.15*t))
            points.append((x,y,z+.003))
        tube("Bonnet shutline",points,.0048,trim)

    # A continuous cabin skin follows the narrowing roof, swept screen and rear spoiler.
    # Each row carries a curved windscreen, a different rear rake, and flush side glass.
    cabin_rows=[(1.32,.950,-1.14,2.115),(1.395,.932,-1.105,2.105),
                (1.448,.908,-1.050,2.08),(1.605,.866,-.927,2.017),
                (1.800,.811,-.731,1.924),(1.897,.765,-.622,1.835),
                (1.933,.741,-.573,1.792),(1.960,.687,-.495,1.70)]
    def outline(row):
        z,w,yf,yr=row
        return [(w*u,y,z+h) for u,y,h in [(-1,yf+.145,0),(-.92,yf+.025,.01),
              (-.60,yf-.05,.019),(0,yf-.087,.030),(.60,yf-.05,.019),(.92,yf+.025,.01),
              (1,yf+.145,0),(1,yr-.17,0),(.88,yr-.028,.01),(0,yr+.028,.02),
              (-.88,yr-.028,.01),(-1,yr-.17,0)]]
    from build_vehicles import profile_loft
    canopy=profile_loft("Curved glazing and pressed roof",[outline(row) for row in cabin_rows],white,None)
    canopy.data.materials.append(glass)
    for poly in canopy.data.polygons:
        row,col=divmod(poly.index,12)
        if 2<=row<=4 and col in (0,1,2,3,4,6,8,9,11):
            poly.material_index=1
    def cabin_point(side,u,i,dx=0):
        z,w,f,a=cabin_rows[i]
        return (side*(w+dx),f+.145+u*(a-.17-f-.145),z)
    # Tuck the shoulder up to the sill underneath the windows.
    for side in [-1,1]:
        rows=[]
        for i in range(61):
            y=-1.10+3.09*i/60
            z=profile(BODY,y,2)
            rows.append([side_point(side,y,z), (side*.936,y,z+.008),
                         (side*.895,y,1.46)])
        grid("Shoulder ledge below daylight opening",rows,white)
        for title,u,half_width,finish in [("B pillar",.431,.025,black),
                            ("Rear door divider",.762,.012,black),("Rear pillar",.952,.049,white)]:
            grid(title,[[cabin_point(side,u-half_width,i,.007),cabin_point(side,u+half_width,i,.007)]
                        for i in range(2,6)],finish)
        for level in [2,5]:
            tube("Daylight opening bright edge",[cabin_point(side,u/28,level,.006)
                                                 for u in range(29)],.009,chrome)
        tube("Mirror pedestal",[(side*.922,-.759,1.39),(side*.987,-.770,1.443),
                                (side*1.045,-.761,1.471)],.029,black)
        oval("Mirror shell",(side*1.081,-.780,1.507),(.110,.128,.081),white)
        oval("Mirror glass",(side*1.081,-.680,1.504),(.088,.017,.058),glass)
        tube("Mirror turn repeater",[(side*1.174,-.817,1.493),(side*1.185,-.765,1.492),
                                      (side*1.168,-.724,1.488)],.006,amber)
    for side in [-1,1]:
        tube("Roof luggage rail",[(side*.651,-.487,1.979),(side*.66,-.368,2.014),
                                  (side*.663,1.489,2.018),(side*.65,1.633,1.969)],.019,chrome)
    grid("Tailgate roof spoiler",[[ (u*w,y,z+.015*(1-u*u)) for u in [-1,-.7,0,.7,1]]
                                  for w,y,z in [(.686,1.63,1.96),(.731,1.79,1.949),
                                                (.752,1.937,1.924),(.72,1.945,1.891)]],white)

    # Cabin furnishings and floor give the windshield a plausible interior reflection.
    cabin_glass=material("Laminated blue grey windshield",(.092,.18,.21),.11,.14)
    cabin_glass.diffuse_color=(.092,.18,.21,.62)
    next(node for node in cabin_glass.node_tree.nodes if node.type=="BSDF_PRINCIPLED").inputs["Alpha"].default_value=.62
    cabin_glass.surface_render_method="DITHERED"
    canopy.data.materials.append(cabin_glass)
    for poly in canopy.data.polygons:
        row,col=divmod(poly.index,12)
        if 2<=row<=4 and col in (0,1,2,3,4,8,9):
            poly.material_index=2
    cube("Cabin floor",(0,.38,.595),(1.65,2.81,.115),trim,.054)
    cube("Dashboard cowl",(0,-.906,1.386),(1.70,.37,.14),trim,.067)
    for x in [-.430,.430]:
        for y in [-.03,1.06]:
            seatback=cube("Upholstered backrest",(x,y,1.213),(.61,.163,.52),trim,.073)
            seatback.rotation_euler.x=-.12
            cube("Cabin head restraint",(x,y+.040,1.546),(.284,.129,.185),trim,.062)
    unlit_blue=material("Emergency bar blue polycarbonate",(.017,.087,.25),.13,.24)
    front=BODY[0][0]
    # Sixteen sided rounded trapezoid, gently bowed back to meet the side intakes.
    grille=[(-.460,1.126),(-.410,1.151),(.410,1.151),(.460,1.126),(.468,1.08),
            (.421,.826),(.38,.789),(-.38,.789),(-.421,.826),(-.468,1.08)]
    face_patch("Grille intake cavity",front,grille,.021,black)
    face_line("Grille satin edge",front,grille+[grille[0]],.032,.012,chrome)
    for k in range(-7,8):
        x=k*.053
        face_line("Concave vertical grille blade",front,[(x*.96,.823),(x,1.005),(x*1.04,1.125)],.032,.0068,chrome)
    cube("Volva grille badge",(0,front-.19-.052,.978),(.19,.036,.14),black,.012,root)
    face_line("Volva grille chevron",front,[(-.060,1.014),(0,.940),(.060,1.014)],
              .080,.010,chrome)
    face_patch("Lower bumper intake",front,[(-.706,.532),(-.641,.694),(-.549,.723),
              (.549,.723),(.641,.694),(.706,.532),(.657,.498),(-.657,.498)],.023,trim)
    for z in [.553,.604,.654]:
        face_line("Air intake slat",front,[(-.598,z),(-.28,z),(.28,z),(.598,z)],.035,.007,black)
    face_line("Skid plate satin edge",front,[(-.558,.461),(-.378,.437),(.378,.437),(.558,.461)],.017,.015,chrome)
    for side in [-1,1]:
        def mirror(points):
            return [(side*x,z) for x,z in points]
        # The outboard air pockets turn up toward the lamps at the bumper corners.
        pocket = mirror([(.665,.704),(.716,.855),(.786,.887),(.822,.861),
                         (.804,.698),(.754,.627),(.692,.631)])
        face_patch("Corner intake recess",front,pocket,.024,trim)
        face_line("Intake return lip",front,pocket[1:6],.036,.009,white)
        for z in (.716,.766,.816):
            face_line("Corner intake vane",front,mirror([(.717,z),(.757,z+.007),(.789,z+.016)]),
                      .038,.006,black)
        outline_pts=mirror([(.479,1.115),(.53,1.155),(.71,1.16),(.773,1.143),(.795,1.119),
                            (.773,1.041),(.676,1.022),(.524,1.045),(.476,1.073)])
        face_patch("Headlight swept recess",front,outline_pts,.035,glass)
        face_line("Headlamp weather seal",front,outline_pts+[outline_pts[0]],.04,.0055,black)
        face_line("Thor horizontal light guide",front,mirror([(.487,1.091),(.61,1.099),(.73,1.110),(.782,1.118)]),.046,.009,led)
        face_line("Thor light upper prong",front,mirror([(.587,1.096),(.610,1.114),(.623,1.141)]),.046,.009,led)
        face_line("Thor light lower prong",front,mirror([(.589,1.097),(.604,1.078),(.607,1.057)]),.046,.009,led)
        # The dark outer lens and amber repeater wrap onto the front wing.
        corner=[(side*.765,face_y(front,.765,1.105)-.032,1.105)]
        for k in range(9):
            y=front+.255*k/8
            z=1.107+.045*k/8
            corner.append(side_point(side,y,z,.007))
        grid("Headlamp outer wing lens",[[ (x,y,z-.040*(1-k/10)),(x,y,z+.030*(1-k/10))]
            for k,(x,y,z) in enumerate(corner)],glass)
        tube("Headlamp outer guide",corner[:7],.005,led)
        tube("Amber wing reflector",corner[6:],.006,amber)
        oval("Projector optic",(side*.741,face_y(front,.741)-.045,1.075),(.043,.015,.026),chrome)
        face_patch("Lower corner intake",front,mirror([(.704,.697),(.761,.773),(.814,.772),
                  (.825,.741),(.803,.525),(.718,.505)]),.021,black)
        face_line("Corner intake bright return",front,mirror([(.718,.517),(.79,.536),(.802,.643)]),.031,.006,chrome)
    cube("Front registration plate",(0,front-.19-.045,.719),(.469,.018,.098),white,.005)
    panel_word("Front registration","AXL 060",(0,front-.19-.056,.719),.062,0,black)

    rear=BODY[-1][0]
    for side in [-1,1]:
        # One continuous L-shaped blade across the D pillar, shoulder and the tailgate.
        spine=[]
        for i in range(6,1,-1):
            z,w,f,a=cabin_rows[i]
            spine.append((side*w*.971,a-.068,z))
        spine += [(side*.913,2.134,1.435),(side*.929,2.211,1.381),
                  (side*.891,2.270,1.350)]
        for x in [.854,.79,.72,.623,.496]:
            spine.append((side*x,face_y(rear,x)+.018,1.347+.014*(x-.5)/.35))
        sections=[[(x+side*dx,y+dy,z+dz) for dx,dy,dz in [
            (-.026,-.013,-.024),(.020,-.014,-.032),(.023,.018,-.009),
            (.012,.023,.029),(-.025,.010,.032)]] for x,y,z in spine]
        profile_loft("Tail lamp shoulder and pillar",sections,ruby,None)
        face_patch("Tailgate combination lens",rear,[(side*x,z) for x,z in [
            (.51,1.315),(.81,1.326),(.858,1.295),(.811,1.229),(.660,1.244),(.52,1.265)]],.020,trim)
        face_line("Tail lamp lower light guide",rear,[(side*.53,1.288),(side*.70,1.282),
                  (side*.807,1.269)],.034,.010,ruby)
        face_line("Reversing light",rear,[(side*.70,1.257),(side*.785,1.251)],.037,.009,reverse)
        face_line("Liftgate shut line",rear,[(side*.573,1.405),(side*.585,1.366),(side*.504,1.312),
                  (side*.505,1.25),(side*.708,1.194),(side*.716,.882),(side*.64,.785),
                  (side*.48,.763)],.008,.005,trim)
        face_line("Rear bumper reflector",rear,[(side*.698,.674),(side*.802,.682)],.025,.010,reflector)
    tube("Rear window wiper",[(-.40,2.108,1.477),(-.10,2.155,1.485),(.27,2.129,1.50)],.011,trim)
    cube("Centre brake lamp",(0,1.944,1.906),(.54,.025,.025),ruby,.008)
    panel_word("Volva tailgate lettering","VOLVA HT–6",(0,rear+.171,1.325),.075,pi,chrome)
    panel_word("Police rear legend","POLIS",(0,rear+.176,1.186),.119,pi,blue)
    face_patch("Plate recess",rear,[(-.315,1.059),(.315,1.059),(.29,.889),(-.29,.889)],.013,trim)
    cube("Rear registration plate",(0,rear+.189,.977),(.510,.020,.107),white,.009)
    panel_word("Rear registration","AXL 060",(0,rear+.201,.977),.069,pi,black)
    face_patch("Rear diffuser",rear,[(-.85,.49),(-.75,.586),(-.43,.57),(.43,.57),(.75,.586),
              (.85,.49),(.75,.374),(-.75,.374)],.026,trim)
    face_line("Rear satin sill protector",rear,[(-.73,.557),(-.46,.526),(.46,.526),(.73,.557)],.039,.008,chrome)
    for side in [-1,1]:
        for i in range(2):
            lo=.36+i*.209
            face_patch("Hatch reflective flashes",rear,[(side*lo,.821),(side*(lo+.112),.821),
                      (side*(lo+.202),.710),(side*(lo+.093),.710)],.012,yellow if i==0 else blue)

    for side in [-1,1]:
        for y in AXLES:
            before=set(bpy.context.scene.objects)
            def ring(profile_points,finish,label):
                rings=[[(side*x,y+r*cos(tau*i/56),AXLE_Z+r*sin(tau*i/56))
                       for i in range(56)] for x,r in profile_points]
                profile_loft(label,rings+[rings[0]],finish,None,close_ends=False)
            ring([(.851,.29),(.84,.346),(.854,.392),(.879,.418),(.908,TYRE),(.993,TYRE),
                  (1.024,.413),(1.049,.378),(1.051,.337),(1.035,.287)],RUBBER,"Touring sidewall")
            ring([(1.035,.276),(1.050,.285),(1.058,.290),(1.060,.272),(1.039,.255)],alloy,"Rolled rim")
            cylinder("Brake rotor",(side*1.001,y,AXLE_Z),.238,.022,chrome,vertices=36)
            for k in range(5):
                a=tau*k/5
                for branch in [-1,1]:
                    outline2=[(.059,.011),(.091,.012+branch*.002),(.244,.041+branch*.044),
                              (.279,.042+branch*.050),(.273,.019+branch*.053),(.106,-.013)]
                    points=[]
                    for x in [1.045,1.065]:
                        points.append([(side*x,y+r*cos(a)-d*sin(a),AXLE_Z+r*sin(a)+d*cos(a))
                                       for r,d in outline2])
                    profile_loft("Bifurcated wheel spoke",points,alloy,None)
            cylinder("Centre cap",(side*1.064,y,AXLE_Z),.061,.032,black,vertices=24)
            for part in set(bpy.context.scene.objects)-before:
                part["xc_batch"]="Performance tire XC60 "+("front" if y<0 else "rear")+(" left" if side<0 else " right")

    cylinder("Dispatch aerial base",(0,-.23,2.16),.043,.040,black,axis_x=False)
    cylinder("Dispatch aerial",(0,-.23,2.32),.007,.30,black,axis_x=False)
    for x in [-.39,.39]:
        cube("Lightbar mounting foot",(x,-.23,2.010),(.121,.188,.071),black,.022)
    cube("Roof lightbar mounting rail",(0,-.23,2.059),(1.20,.24,.040),chrome,.018)
    cube("Permanent blue lightbar casing",(0,-.23,2.102),(1.177,.202,.052),unlit_blue,.023)
    for side in [-1,1]:
        cube("Aluminium lightbar end cap",(side*.613,-.23,2.106),(.031,.209,.06),chrome,.012)
    for i in range(12):
        x=(i-5.5)*.099
        cube("FlashBlue_Left" if x<0 else "FlashRed_Right",(x,-.23,2.109),
             (.094,.216,.068),BLUE_LAMP,.022)
    for side in [-1,1]:
        cube("FlashBlue_Grille" if side<0 else "FlashRed_Grille",
             (side*.259,face_y(front,.259)-.043,.865),(.081,.019,.035),BLUE_LAMP,.009)
    for obj in list(bpy.context.scene.objects):
        if obj!=root:
            obj.parent=root
    return root
