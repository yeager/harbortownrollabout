"""Build the four passenger cars and the Sjöstad city bus from longitudinal profiles."""
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, cube, cylinder, material, mesh_from_rings,
    export_vehicle, profile_loft, text_obj, SOURCE_DIR, DARK, RUBBER, METAL, HEADLAMP, RED_LAMP)

CLASSIC_BADGES = {
    "sport_sedan": ("BWM M3 E33", .802),
    "classic_estate": ("VOLVA 241", .844),
    "classic_fastback": ("SAAV 97", .567),
}

def saav_tire(side, x, y, radius, root):
    # Section through the bead, rounded shoulders and three tread grooves.
    profile = [
        (-.105,.68),(-.105,.84),(-.099,.93),(-.085,.981),(-.069,1.0),
        (-.052,1.0),(-.049,.969),(-.035,.969),(-.032,1.0),
        (-.010,1.0),(-.007,.969),(.007,.969),(.010,1.0),
        (.032,1.0),(.035,.969),(.049,.969),(.052,1.0),
        (.069,1.0),(.085,.981),(.099,.93),(.105,.84),(.105,.68),
    ]
    segments = 64
    points = [(side*offset,radius*scale*math.cos(angle),radius*scale*math.sin(angle))
              for offset,scale in profile
              for angle in (math.tau*step/segments for step in range(segments))]
    faces = []
    for ring in range(len(profile)):
        start = ring*segments
        following = ((ring+1) % len(profile))*segments
        for step in range(segments):
            neighbor = (step+1) % segments
            face = (start+step,start+neighbor,following+neighbor,following+step)
            faces.append(face if side > 0 else face[::-1])
    mesh = bpy.data.meshes.new("Saav tire tread")
    mesh.from_pydata(points,[],faces)
    mesh.materials.append(RUBBER)
    mesh.update()
    for face in mesh.polygons:
        face.use_smooth = True
    tire = bpy.data.objects.new("Däck",mesh)
    bpy.context.collection.objects.link(tire)
    tire.parent = root
    tire.location = (side*x,y,radius)


def build(key, length, width, axles, color, belt, cabin):
    clear_scene()
    root=bpy.data.objects.new(key,None)
    bpy.context.collection.objects.link(root)
    paint=material(key+" enamel",color,.42,.26)
    glass=material("Smoked blue glazing",(.035,.062,.077),.47,.15)
    cabin_materials=[paint,glass]
    if key=="sport_sedan":
        windscreens=material("Laminated blue-green safety glass",(.065,.125,.135),.08,.13)
        shade=material("Blue-green upper sun strip",(.025,.063,.078),.07,.16)
        for finish,alpha in [(windscreens,.58),(shade,.72)]:
            shader=next(node for node in finish.node_tree.nodes if node.type=="BSDF_PRINCIPLED")
            shader.inputs["Alpha"].default_value=alpha
        cabin_materials.extend([windscreens,shade])
    white=material("Ivory",(.88,.86,.75),.13,.3)
    amber=material("Indicator",(.95,.29,.012),.15,.27)
    if key == "classic_fastback":
        reverse_glass = material("Reverse lamp Saav glass",(.73,.77,.74),.14,.24)
    def box(name,x,y,z,w,d,h,mat,bev=.018):
        return cube(name,(x,y,z),(w,d,h),mat,bev,root)
    def bar(name,a,b,thick,mat):
        v=Vector(b)-Vector(a)
        part=box(name,*((Vector(a)+Vector(b))*.5),thick,thick,v.length,mat,.008)
        part.rotation_euler=v.to_track_quat('Z','Y').to_euler()
    bus=key=="city_bus"
    end=length/2
    wheel=.46 if bus else .32
    shape=[(-1,.88,.8),(-.93,.97,.92),(-.63,1,1),(-.28,.98,1.03),(.22,.99,1.02),(.65,1,1),(.94,.97,.98),(1,.91,.92)]
    if key=="classic_fastback": shape=[(-1,.70,.77),(-.91,.90,.85),(-.67,1,.96),(-.29,.98,1.05),(.25,.98,1.06),(.68,1,.99),(.92,.88,.86),(1,.72,.73)]
    if bus: shape=[(-1,.94,.99),(-.97,1,1),(.97,1,1),(1,.96,.99)]
    body=mesh_from_rings("Painted bodyshell",[(u*end,w*width,.20,belt*h-.04,belt*h) for u,w,h in shape],paint,root,.035)
    for y in axles:
        bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=wheel+.045,depth=width*2.5,location=(0,y,wheel),rotation=(0,math.pi/2,0))
        cutter=bpy.context.object
        mod=body.modifiers.new("Wheel opening","BOOLEAN");mod.object=cutter;mod.operation="DIFFERENCE"
        bpy.context.view_layer.objects.active=body
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
        for side in [-1,1]:
            if key == "classic_fastback":
                saav_tire(side,width-.12,y,wheel,root)
            else:
                cylinder("Däck",(side*(width-.12),y,wheel),wheel,.21,RUBBER,True,48,root)
            for name,x,r,d,mat in [("Alloy wheel",width-.012,wheel*.74,.04,DARK if key=="classic_fastback" else METAL),("Wheel hub",width+.012,wheel*.43,.036,DARK)]:
                cylinder(name,(side*x,y,wheel),r,d,mat,True,48,root)
            if key=="sport_sedan":
                cylinder("Anthracite wheel barrel",(side*(width+.019),y,wheel),.208,.029,DARK,True,48,root)
                vertices,faces=[],[]
                for i in range(16):
                    base=math.tau*i/16
                    for sweep in [-1,1]:
                        start=len(vertices)
                        for r,twist,w,x in [(.060,0,.010,.048),(.125,.13,.008,.053),(.208,.32,.006,.040)]:
                            angle=base+sweep*twist
                            for depth,offset in [(0,-w),(.009,-w),(.009,w),(0,w)]:
                                vertices.append((side*(width+x+depth),y+r*math.sin(angle)+offset*math.cos(angle),
                                                 wheel+r*math.cos(angle)-offset*math.sin(angle)))
                        for ring in [start,start+4]:
                            for j in range(4):
                                k=(j+1)%4
                                faces.append((ring+j,ring+k,ring+4+k,ring+4+j))
                mesh=bpy.data.meshes.new("Cross spoke lattice")
                mesh.from_pydata(vertices,[],faces)
                mesh.materials.append(METAL)
                lattice=bpy.data.objects.new("Alloy wheel cross spokes",mesh)
                bpy.context.collection.objects.link(lattice)
                lattice.parent=root
                cylinder("Center cap",(side*(width+.055),y,wheel),.068,.022,METAL,True,32,root)
                for i in range(5):
                    angle=math.tau*i/5
                    cylinder("Wheel bolt",(side*(width+.07),y+.046*math.sin(angle),wheel+.046*math.cos(angle)),.011,.012,DARK,True,6,root)
                continue
            if key == "classic_fastback":
                wheel_x = side*(width+.038)
                dish = cylinder("Pressed steel wheel", (wheel_x,y,wheel), .211,
                                .022,METAL,True,64,root)
                for slot in range(8):
                    angle = math.tau*slot/8
                    bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=.020,depth=.055,
                        location=(wheel_x,y+.166*math.cos(angle),wheel+.166*math.sin(angle)),
                        rotation=(0,math.pi/2,0))
                    punch = bpy.context.object
                    opening = dish.modifiers.new("Ventilation opening","BOOLEAN")
                    opening.object = punch
                    opening.operation = "DIFFERENCE"
                    bpy.context.view_layer.objects.active = dish
                    bpy.ops.object.modifier_apply(modifier=opening.name)
                    bpy.data.objects.remove(punch,do_unlink=True)
                bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=12,
                    location=(side*(width+.021),y,wheel),rotation=(0,math.pi/2,0),
                    major_radius=.222,minor_radius=.011)
                lip = bpy.context.object
                lip.name = "Alloy wheel rolled edge"
                lip.data.materials.append(METAL)
                for face in lip.data.polygons:
                    face.use_smooth = True
                lip.parent = root
                cylinder("Wheel hub cap",(side*(width+.063),y,wheel),.079,.044,
                         METAL,True,48,root)
                continue
            count=8
            for i in range(count):
                angle=math.tau*i/count
                spoke=box("Alloy wheel spoke",side*(width+.04),y+.13*math.sin(angle),wheel+.13*math.cos(angle),.02,.033,.18,METAL,.006)
                spoke.rotation_euler.x=-angle+.21
    # Roof contours and matching individual side panes on each side.
    verts=[]; faces=[]; mats=[]
    def quad(points,mat):
        n=len(verts);verts.extend(points);faces.append(tuple(reversed(range(n,n+4))));mats.append(mat)
    sections=[]
    for y,top,wt in cabin:
        sections.append([(-width*.91,y,belt-.025),(-width*wt,y,top-.035),
                         (width*wt,y,top-.035),(width*.91,y,belt-.025)])
    def crowned_edge(section):
        left,right=Vector(section[1]),Vector(section[2])
        crown=.037*min(1.0,max(0.0,(left.z-belt)/.4))
        points=[]
        for j in range(11):
            t=j/10
            point=left.lerp(right,t)
            point.z+=4*t*(1-t)*crown
            points.append(point)
        return points
    for i,(a,b) in enumerate(zip(sections,sections[1:])):
        for j in range(3):
            if key=="sport_sedan" and j==1:
                near,far=crowned_edge(a),crowned_edge(b)
                for k in range(len(near)-1):
                    if i==0:
                        edge=near[k].lerp(far[k],.91)
                        next_edge=near[k+1].lerp(far[k+1],.91)
                        quad([near[k],edge,next_edge,near[k+1]],windscreens)
                        quad([edge,far[k],far[k+1],next_edge],shade)
                    else:
                        finish=windscreens if i==len(sections)-2 else paint
                        quad([near[k],far[k],far[k+1],near[k+1]],finish)
                continue
            quad([a[j],b[j],b[j+1],a[j+1]],glass if j!=1 or i in [0,len(sections)-2] or key=="electric_sedan" else paint)
        for side,j in [(-1,0),(1,3)]:
            k=1 if j==0 else 2
            bar("Roof rail",a[k],b[k],.036 if key=="sport_sedan" else .058,paint)
            if i>0:
                bar("Window pillar",a[j],a[k],.043 if key=="sport_sedan" else .065,paint if i==1 else DARK)
            if key=="sport_sedan":
                bar("Beltline window seal",a[j],b[j],.025,RUBBER)
    if key=="sport_sedan":
        lower,upper=[crowned_edge(section) for section in sections[:2]]
        def windshield(u,t):
            column=min(9,int(u*10))
            fraction=u*10-column
            foot=lower[column].lerp(lower[column+1],fraction)
            head=upper[column].lerp(upper[column+1],fraction)
            return foot.lerp(head,t)+Vector((0,-.007,.005))
        for t in [.014,.98]:
            for j in range(10):
                bar("Windscreen gasket",windshield(j/10,t),windshield((j+1)/10,t),.019,RUBBER)
        for u in [.36,.78]:
            bar("Wiper arm",windshield(u,.022),windshield(u-.117,.135),.012,DARK)
            bar("Wiper blade",windshield(u-.236,.149),windshield(u+.026,.117),.015,RUBBER)
    elif key == "classic_fastback":
        lower, upper = sections[:2]
        def glass_point(u, t):
            foot = Vector(lower[1]).lerp(Vector(lower[2]),u)
            head = Vector(upper[1]).lerp(Vector(upper[2]),u)
            return foot.lerp(head,t)+Vector((0,-.006,.006))

        for t in (.012,.982):
            bar("Saav windscreen seal",glass_point(.008,t),glass_point(.992,t),.014,RUBBER)
        for u in (.29,.73):
            hinge = glass_point(u,.029)
            arm_end = glass_point(u+.11,.174)
            spindle = cylinder("Saav wiper spindle",hinge,.014,.024,DARK,False,20,root)
            spindle.rotation_euler.x = -.74
            bar("Saav wiper arm",hinge,arm_end,.012,DARK)
            bar("Saav wiper blade",glass_point(u-.063,.194),
                glass_point(u+.253,.156),.015,RUBBER)
        upper, lower = sections[-2:]
        def rear_glass_point(u, t):
            top = Vector(upper[1]).lerp(Vector(upper[2]),u)
            bottom = Vector(lower[1]).lerp(Vector(lower[2]),u)
            return top.lerp(bottom,t)+Vector((0,.003,.005))

        for t in (.014,.980):
            bar("Saav rear window seal",rear_glass_point(.008,t),
                rear_glass_point(.992,t),.015,RUBBER)
        heater = material("Saav rear glass heater",(.34,.16,.069),.20,.54)
        for row in range(8):
            t = .161 + row*.095
            bar("Saav rear window heater line",rear_glass_point(.067,t),
                rear_glass_point(.933,t),.0035,heater)
        for u in (.067,.933):
            bar("Saav rear window heater busbar",rear_glass_point(u,.138),
                rear_glass_point(u,.85),.005,heater)
    mesh=bpy.data.meshes.new("Cabin panels");mesh.from_pydata(verts,[],faces);mesh.update()
    cabin_obj=bpy.data.objects.new("Cabin",mesh);bpy.context.collection.objects.link(cabin_obj);cabin_obj.parent=root
    for mat in cabin_materials: mesh.materials.append(mat)
    for p,m in zip(mesh.polygons,mats): p.material_index=cabin_materials.index(m)
    if key in ["sport_sedan","classic_estate"]:
        glass.diffuse_color=(.12,.17,.19,.40)
        shader=next(node for node in glass.node_tree.nodes if node.type=="BSDF_PRINCIPLED")
        shader.inputs["Alpha"].default_value=.40
        for x in [-.39,.39]:
            box("Front seat back",x,.10,belt+.085,.45,.16,.31,DARK,.065)
            box("Head restraint",x,.14,belt+.285,.26,.14,.13,RUBBER,.042)
        box("Rear bench backrest",0,.72,belt+.075,1.39,.18,.26,DARK,.07)
        for x in [-.42,.42]:
            box("Rear headrest",x,.73,belt+.237,.25,.13,.105,RUBBER,.045)
        for x in [-.465,-.327]:
            dial=cylinder("Recessed dashboard dial",(x,-.483,belt+.079),.056,.023,RUBBER,False,24,root)
            dial.rotation_euler.x=math.pi/2
            bar("Instrument pointer",(x,-.469,belt+.079),(x-.021,-.469,belt+.102),.005,white)
        box("Instrument panel",0,-.59,belt+.024,1.42,.23,.11,DARK,.040)
        bpy.ops.mesh.primitive_torus_add(location=(-.39,-.405,belt+.11),
            rotation=(math.radians(57),0,0),major_radius=.136,minor_radius=.015)
        rim=bpy.context.object
        rim.name="Steering rim"
        rim.parent=root
        rim.data.materials.append(RUBBER)
        box("Steering wheel hub",-.39,-.405,belt+.11,.244,.034,.037,DARK)
    if key=="classic_estate":
        reverse=material("Reverse lamp classic saloon",(.76,.79,.74),.09,.21)
        top,bottom=sections[-2:]
        for t in [.045,.2,.32,.44,.56,.68,.8,.95]:
            left=Vector(top[1]).lerp(Vector(bottom[1]),t)
            right=Vector(top[2]).lerp(Vector(bottom[2]),t)
            left.y+=.006
            right.y+=.006
            bar("Rear screen seal" if t in [.045,.95] else "Heated screen filament",
                left,right,.022 if t in [.045,.95] else .003,RUBBER)
    for side in [-1,1]:
        if key in ["sport_sedan","classic_estate"]:
            # Solid sail panel joins the roof to the rear deck behind the quarter glass.
            y1,z1,w1=cabin[-2]
            y2,z2,w2=cabin[-1]
            pillar_rings=[]
            for depth in [.0,.032]:
                pillar_rings.append([(side*(width*w1+depth),y1-.025,z1-.035),
                                     (side*(width*w1+depth),y1+.065,z1-.035),
                                     (side*(width*.91+depth),y2+.008,belt-.019),
                                     (side*(width*.91+depth),y2-.23,belt-.019)])
            profile_loft("Painted rear quarter pillar",pillar_rings,paint,root)
            for y in ([.35] if key=="sport_sedan" else [.12,.94]):
                bar("Door shut line",(side*width*.992,y,belt-.045),
                    (side*width*.994,y-.018,.55),.012,DARK)
        if key=="sport_sedan":
            mount_y=cabin[1][0]-.07
            bar("Mirror stalk",(side*(width-.06),mount_y,belt+.08),
                (side*(width+.055),mount_y+.009,belt+.14),.047,DARK)
            shell=[]
            for dy,w,h in [(-.078,.042,.037),(-.057,.085,.053),(.021,.104,.061),(.059,.095,.054)]:
                shell.append([(side*(width+.109+w*math.cos(t)),mount_y+dy,belt+.15+h*math.sin(t))
                              for t in [math.tau*i/20 for i in range(20)]])
            profile_loft("Aero mirror housing",shell,paint,root)
            box("Mirror glass",side*(width+.108),mount_y+.062,belt+.15,.159,.009,.077,METAL,.004)
        elif key == "classic_fastback":
            mount_y = cabin[1][0] - .07
            box("Mirror door gasket",side*.761,mount_y,.929,.048,.108,.089,RUBBER,.012)
            bar("Mirror angled stalk",(side*.780,mount_y,.937),
                (side*.862,mount_y-.009,.999),.036,DARK)
            box("Mirror shell",side*.884,mount_y-.024,1.014,.183,.113,.112,DARK,.032)
            box("Mirror glass seal",side*.884,mount_y+.034,1.014,.158,.014,.089,RUBBER,.016)
            box("Mirror glass",side*.884,mount_y+.044,1.014,.140,.011,.075,METAL,.012)
        else:
            box("Mirror",side*(width+.065),cabin[1][0]-.07,belt+.12,.17,.22,.13,paint)
        if key == "classic_fastback":
            # Project the shut line onto the curved outer panel.
            outline = [(-.657,.897),(.536,.897),(.625,.815),(.611,.360),
                       (.532,.281),(-.582,.281),(-.655,.347)]
            seam = bpy.data.curves.new("Saav door shut line", "CURVE")
            seam.dimensions = "3D"
            seam.bevel_depth = .003
            seam.bevel_resolution = 2
            trace = seam.splines.new("POLY")
            segments = 14
            trace.points.add(len(outline)*segments-1)
            trace.use_cyclic_u = True
            for edge, (start_y,start_z) in enumerate(outline):
                end_y,end_z = outline[(edge+1) % len(outline)]
                for step in range(segments):
                    t = step/segments
                    y = start_y+(end_y-start_y)*t
                    z = start_z+(end_z-start_z)*t
                    hit, surface, normal, _ = body.ray_cast((side*1.1,y,z),(-side,0,0))
                    point = surface + normal*.002 if hit else Vector((side*.737,y,z))
                    trace.points[edge*segments+step].co = (*point,1)
            seam.materials.append(DARK)
            trim = bpy.data.objects.new("Saav door shut line", seam)
            bpy.context.collection.objects.link(trim)
            trim.parent = root
            box("Saav handle gasket",side*.775,.384,.769,.024,.174,.058,RUBBER,.011)
            box("Saav door pull",side*.793,.375,.777,.025,.131,.030,METAL,.008)
            cylinder("Saav door lock",(side*.794,.450,.769),.012,.010,METAL,True,20,root)
        else:
            for y in ([.10,.94] if key in ["electric_sedan","classic_estate"] else [.22]):
                box("Door handle",side*width*.99,y,belt-.14,.032,.15,.04,DARK)
        if key=="classic_estate":
            box("Rectangular headlamp seal",side*.59,-end-.025,belt*.73,.39,.065,.245,DARK)
            box("Fluted rectangular headlamp",side*.59,-end-.064,belt*.73,.35,.034,.205,HEADLAMP)
            box("Corner indicator",side*.802,-end+.015,belt*.73,.065,.16,.20,amber)
            box("Rubber door protector",side*width,0,.54,.038,1.91,.075,RUBBER)
        elif key=="sport_sedan":
            box("Sculpted sill",side*(width-.012),0,.29,.115,1.87,.115,paint,.032)
            box("Front brake cooling duct",side*.51,-end-.077,.35,.27,.023,.064,DARK)
            for axle in axles:
                rings=[]
                # Sections run fore-aft. The opening stays round under a level shoulder,
                # while the ends taper into the door and bumper.
                arch=.363
                stations=[-.67,-.55,-.44]+[-arch*math.cos(math.pi*i/24) for i in range(25)]+[.44,.55,.67]
                for offset in stations:
                    taper=max(0.0,min(1.0,(.67-abs(offset))/.27))
                    opening=wheel+math.sqrt(max(0.0,arch**2-offset**2))
                    if abs(offset)>arch:
                        opening-=min(.08,(abs(offset)-arch)*.7)
                    shoulder=.763+.028*taper
                    outer=width-.033+.108*taper
                    section=[(width-.066,opening),(outer-.008,opening),
                             (outer,opening+.022),(outer-.005,shoulder-.035),
                             (outer-.018,shoulder),(width-.050,shoulder+.073)]
                    rings.append([(side*x,axle+offset,z) for x,z in section])
                profile_loft("Box flare shoulder",rings,paint,root)
            box("Twin lamp grille surround",side*.577,-end-.026,belt*.73,.515,.075,.267,DARK,.026)
            for x in [.461,.687]:
                lamp_x, lamp_z = side*x, belt*.73
                gasket = cylinder("Lamp rubber seat",(lamp_x,-end-.061,lamp_z),
                                  .115,.023,RUBBER,False,40,root)
                gasket.rotation_euler.x = math.pi/2
                bezel = cylinder("Headlight retaining ring",(lamp_x,-end-.074,lamp_z),
                                 .108,.018,METAL,False,40,root)
                bezel.rotation_euler.x = math.pi/2
                lens_profile = [(.080,.095),(.087,.096),(.092,.091),
                                (.096,.072),(.098,.039),(.099,.012)]
                profile_loft("Headlight",[
                    [(lamp_x+radius*math.cos(i*math.tau/40),-end-depth,
                      lamp_z+radius*math.sin(i*math.tau/40)) for i in range(40)]
                    for depth,radius in lens_profile
                ],HEADLAMP,root)
            box("Front indicator housing",side*.657,-end-.047,.483,
                .246,.077,.077,RUBBER,.012)
            box("Front amber indicator",side*.657,-end-.087,.483,
                .213,.022,.056,amber,.008)
        elif key == "classic_fastback":
            x = side*.501
            box("Headlamp pocket",x,-end-.029,.657,.359,.103,.237,RUBBER,.027)
            box("Headlamp bright surround",x,-end-.084,.657,.318,.032,.204,METAL,.020)
            box("Headlamp lens",x,-end-.105,.657,.281,.024,.169,HEADLAMP,.016)
            box("Front indicator housing",x,-end-.058,.492,.225,.092,.075,RUBBER,.012)
            box("Front indicator bezel",x,-end-.108,.492,.205,.024,.059,METAL,.007)
            box("Front amber indicator",x,-end-.125,.492,.184,.020,.045,amber,.006)
        else:
            box("Headlamp",side*width*.68,-end-.02,belt*.72,width*.40,.065,.10 if key=="electric_sedan" else .18,HEADLAMP)
        if key=="classic_estate":
            box("Six-cell lamp gasket",side*.605,end+.018,.725,.405,.075,.226,RUBBER,.017)
            for row,finishes in enumerate([(RED_LAMP,RED_LAMP,RED_LAMP),(RED_LAMP,reverse,amber)]):
                for column,finish in enumerate(finishes):
                    x=side*(.478+column*.127)
                    box("Rear lamp cell",x,end+.062,.674+row*.102,.122,.029,.094,finish,.008)
            box("Bumper quarter return",side*.819,end-.16,.435,.103,.42,.154,RUBBER,.024)
        elif key=="sport_sedan":
            box("Rear light cluster seal",side*.57,end+.018,.708,.468,.078,.203,RUBBER,.018)
            clear_lens=material("Reverse lamp coupe",(.77,.80,.74),.15,.18)
            for x,w,finish in [(.399,.105,clear_lens),(.544,.175,RED_LAMP),(.715,.151,amber)]:
                label = "Rear indicator lens" if finish == amber else "Rear lamp upper lens"
                box(label,side*x,end+.062,.755,w,.032,.075,finish,.007)
            box("Rear lamp stop lens",side*.57,end+.062,.661,.443,.032,.088,RED_LAMP,.009)
        elif key == "classic_fastback":
            x = side*.538
            box("Rear combination lamp housing",x,end+.027,.631,.284,.104,.215,RUBBER,.018)
            box("Rear lamp bezel",x,end+.083,.631,.260,.032,.191,METAL,.012)
            box("Ruby tail lens",x-side*.039,end+.105,.657,.146,.022,.112,RED_LAMP,.009)
            box("Rear indicator lens",x+side*.081,end+.105,.657,.079,.022,.112,amber,.008)
            box("Reversing lens",x,end+.105,.574,.225,.022,.041,reverse_glass,.006)
        else:
            box("Ruby tail lens",side*width*.66,end+.025,belt*.73,width*.44,.07,.12,RED_LAMP)
            box("Amber lens",side*width*.84,end+.03,belt*.75,.07,.07,.09,amber)
    for y in [-end,end]:
        if key=="classic_estate" and y>0:
            box("Rear impact bumper",0,y+.052,.435,1.72,.21,.158,RUBBER,.030)
            box("Bumper bright edge",0,y+.115,.512,1.62,.045,.019,METAL,.007)
            box("Boot trailing edge",0,y-.027,.907,1.46,.12,.034,paint,.012)
            box("Number plate gasket",0,y+.012,.692,.54,.028,.15,RUBBER,.009)
            box("Registration plate",0,y+.031,.692,.504,.013,.116,white,.006)
            plate=text_obj("Registration lettering","SJO 240",(.165,y+.042,.657),.09,DARK,root=root,flat=True)
            plate.rotation_euler=(math.pi/2,0,math.pi)
            box("Boot release",0,y+.03,.804,.098,.040,.028,METAL,.009)
        elif key=="sport_sedan" and y>0:
            bumper=[]
            for x in [-.85,-.83,-.78,-.67,0,.67,.78,.83,.85]:
                setback=.14*(abs(x)/.85)**12
                bumper.append([(x,y+dy-setback,z) for dy,z in
                               [(-.16,.27),(.050,.28),(.097,.342),(.123,.475),
                                (.104,.518),(.055,.534),(-.15,.519)]])
            profile_loft("Wraparound rear apron",bumper,paint,root)
            box("Rear rub strip",0,y+.124,.471,1.38,.024,.047,RUBBER,.009)
            box("Rear plate surround",0,y+.019,.694,.591,.041,.164,DARK,.014)
            box("Rear number plate",0,y+.047,.694,.504,.013,.113,white,.006)
            plate=text_obj("Coupe registration","SJO 030",(.151,y+.056,.665),.082,DARK,root=root,flat=True)
            plate.rotation_euler=(math.pi/2,0,math.pi)
            for x in [.515,.604]:
                pipe=cylinder("Tailpipe rolled rim",(x,y+.043,.238),.042,.134,METAL,False,24,root)
                pipe.rotation_euler.x=math.pi/2
                bore=cylinder("Exhaust opening",(x,y+.112,.238),.034,.006,DARK,False,24,root)
                bore.rotation_euler.x=math.pi/2
        elif key == "classic_fastback":
            outward = math.copysign(1,y)
            profile = [(-.078,.314),(.035,.304),(.063,.320),(.067,.341),
                       (.067,.392),(.051,.416),(.022,.424),(-.078,.412)]
            sections = []
            for x in (-.759,-.750,-.716,-.65,-.54,-.375,0,.375,.54,.65,.716,.750,.759):
                corner = (abs(x)/.759)**6
                section_height = 1.0 - .20*corner
                sections.append([(x, y+outward*(depth-.223*corner),
                                  .36+(z-.36)*section_height) for depth,z in profile])
            profile_loft("Saav wraparound bumper",sections,RUBBER,root)
        else:
            box("Bumper",0,y,.36,width*1.96,.13,.13,RUBBER if key!="sport_sedan" else paint)
    if key == "classic_fastback":
        outline = [(-.340,.748),(.340,.748),(.368,.699),(.357,.445),
                   (.310,.406),(-.310,.406),(-.357,.445),(-.368,.699)]
        seam = bpy.data.curves.new("Saav boot shut line","CURVE")
        seam.dimensions = "3D"
        seam.bevel_depth = .003
        seam.bevel_resolution = 2
        trace = seam.splines.new("POLY")
        segments = 16
        trace.points.add(len(outline)*segments-1)
        trace.use_cyclic_u = True
        for edge,(start_x,start_z) in enumerate(outline):
            end_x,end_z = outline[(edge+1) % len(outline)]
            for step in range(segments):
                t = step/segments
                x,z = start_x+(end_x-start_x)*t, start_z+(end_z-start_z)*t
                hit,surface,normal,_ = body.ray_cast((x,end+.3,z),(0,-1,0))
                point = surface + normal*.002 if hit else Vector((x,end,z))
                trace.points[edge*segments+step].co = (*point,1)
        seam.materials.append(DARK)
        trim = bpy.data.objects.new("Saav boot shut line",seam)
        bpy.context.collection.objects.link(trim)
        trim.parent = root
        box("Saav boot release gasket",0,end+.012,.635,.135,.027,.041,RUBBER,.009)
        box("Saav boot release handle",0,end+.029,.639,.105,.023,.019,METAL,.006)
        lock = cylinder("Saav boot lock",(0,end+.027,.622),.009,.012,METAL,False,16,root)
        lock.rotation_euler.x = math.pi/2
        box("Saav silencer",-.460,end-.238,.229,.245,.368,.112,DARK,.041)
        box("Saav silencer clamp",-.460,end-.163,.233,.252,.033,.119,METAL,.014)
        outlet_profile = [(-.144,.034),(.062,.034),(.125,.033),(.134,.028),
                          (.125,.022),(-.144,.022)]
        steps = 32
        vertices = []
        for y,radius in outlet_profile:
            for step in range(steps):
                angle = math.tau*step/steps
                vertices.append((-.460+radius*math.cos(angle), end+y,
                                 .220+radius*math.sin(angle)))
        faces = []
        for ring in range(len(outlet_profile)):
            following = (ring+1) % len(outlet_profile)
            for step in range(steps):
                neighbor = (step+1) % steps
                faces.append((ring*steps+step,following*steps+step,
                              following*steps+neighbor,ring*steps+neighbor))
        exhaust_mesh = bpy.data.meshes.new("Saav rolled exhaust pipe")
        exhaust_mesh.from_pydata(vertices,[],faces)
        exhaust_mesh.update()
        exhaust_mesh.materials.append(METAL)
        exhaust_mesh.materials.append(DARK)
        for face in exhaust_mesh.polygons:
            face.use_smooth = True
            if face.index >= 4*steps:
                face.material_index = 1
        exhaust = bpy.data.objects.new("Saav exhaust outlet",exhaust_mesh)
        bpy.context.collection.objects.link(exhaust)
        exhaust.parent = root
        blue = material("Saav registration country blue",(.025,.106,.43),.06,.40)
        for outward, height, offset in [(-1,.360,.079),(1,.464,.039)]:
            y = outward*(end+offset)
            box("Saav plate gasket",0,y,height,.510,.034,.120,RUBBER,.010)
            box("Saav number plate",0,y+outward*.021,height,.478,.012,.105,white,.006)
            box("Saav plate country band",outward*.211,y+outward*.029,height,
                .039,.004,.092,blue,.003)
            for text, x, z, size, finish in [
                ("SJO 097",.150,-.025,.073,DARK),("S",.216,-.030,.022,white),
            ]:
                glyph = text_obj("Saav plate "+text,text,(outward*x,y+outward*.033,height+z),
                                 size,finish,root=root,flat=True)
                glyph.rotation_euler = (math.pi/2,0,math.pi if outward > 0 else 0)
            for x in (-.161,.161):
                screw = cylinder("Saav plate screw",(x,y+outward*.032,height+.038),
                                 .006,.007,METAL,False,12,root)
                screw.rotation_euler.x = math.pi/2
    if key!="electric_sedan":
        box("Grille",0,-end-.033,belt*.74,width*.91,.05,.22,DARK)
        if key=="classic_estate":
            grille_y = -end - .083
            box("Volva grille badge",0,grille_y,.735,.19,.025,.14,DARK,.009)
            for side in [-1,1]:
                bar("Volva grille chevron",(side*.062,grille_y-.018,.775),
                    (0,grille_y-.018,.698),.017,METAL)
        elif key=="sport_sedan":
            for centre_x in (-.09,.09):
                box("Twin grille surround",centre_x,-end-.074,belt*.74,.15,.035,.20,METAL,.016)
                box("Twin grille recessed insert",centre_x,-end-.090,belt*.74,
                    .119,.009,.164,RUBBER,.010)
                for offset in (-.041,-.021,0,.021,.041):
                    box("Twin grille upright",centre_x+offset,-end-.099,belt*.74,
                        .008,.014,.142,DARK,.002)
        if key == "classic_fastback":
            box("Saav grille backing",0,-end-.063,.657,.669,.075,.225,DARK,.020)
            for z in (.554,.761):
                box("Grille bright trim",0,-end-.108,z,.656,.022,.016,METAL,.005)
            for i in range(5):
                box("Grille slat",0,-end-.107,.574+i*.037,.621,.019,.012,METAL,.003)
            box("Saav grille emblem backing",0,-end-.123,.677,.14,.025,.063,DARK,.006)
            emblem = text_obj("Saav grille emblem","SAAV",(-.049,-end-.138,.662),
                              .040,METAL,root=root,flat=True)
            emblem.rotation_euler = (math.pi/2,0,0)
        else:
            for i in range(4):
                box("Grille slat",0,-end-.065,belt*.65+i*.043,width*.83,.018,.011,METAL,.002)
    else:
        # A silver lightning stroke on a graphite mounting plate.
        for y in [-end-.003, end+.003]:
            z = .649 if y < 0 else .723
            box("Teslo emblem backing",0,y,z,.102,.016,.062,DARK,.011)
            face_y = y + math.copysign(.011,y)
            points = [(-.026,face_y,z+.017),(.011,face_y,z+.017),
                      (-.011,face_y,z-.016),(.026,face_y,z-.016)]
            if y > 0:
                points = [(-x,y,z) for x,y,z in points]
            for start, finish in zip(points, points[1:]):
                bar("Teslo Z emblem",start,finish,.007,METAL)
    if key in CLASSIC_BADGES:
        name, height = CLASSIC_BADGES[key]
        emblem = text_obj(name+" rear badge",name,(0,end+.012,height),.047,METAL,root=root)
        emblem.rotation_euler = (math.pi/2,0,math.pi)
        bounds = [vertex.co.x for vertex in emblem.data.vertices]
        emblem.location.x = (min(bounds)+max(bounds))*.5
    if key=="sport_sedan":
        for side in [-1,1]:
            feet=[]
            for z,y,d,w in [(belt-.063,end-.16,.168,.069),(belt-.042,end-.16,.139,.047),
                             (belt+.097,end-.13,.096,.035),(belt+.126,end-.13,.129,.050)]:
                feet.append([(side*.61+x*w,y+v*d,z) for x,v in [(-1,-.5),(1,-.5),(1,.5),(-1,.5)]])
            profile_loft("Swept spoiler pedestal",feet,paint,root)
        wing=[]
        for x in [-.78,-.755,-.61,0,.61,.755,.78]:
            section_scale=1.0-.30*(abs(x)/.78)**4
            wing.append([(x,end-.13+y*section_scale,belt+.125+z*section_scale+.009*(abs(x)/.78)**2)
                         for y,z in [(-.112,.011),(-.101,.026),(-.046,.034),(.032,.033),
                                     (.106,.045),(.111,.025),(.032,.009),(-.071,.0),(-.104,.002)]])
        profile_loft("Cambered boot spoiler",wing,paint,root)
    if bus:
        for side in [-1,1]:
            box("White waist stripe",side*width,0,.87,.03,length*.96,.15,white)
        for y in [-3.6,.3,3.5]:
            for off in [-.25,.25]: box("Passenger door",-width-.025,y+off,1.36,.035,.46,2.03,DARK)
        box("Destination board",0,-end-.03,2.68,1.75,.08,.34,DARK)
        box("Roof ventilation",0,0,3.10,1.5,3,.22,white)
    export_vehicle(root,key+".glb")
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/(key+".blend")))

build("sport_sedan",4.35,.86,[-1.28,1.28],(.57,.018,.023),.93,[(-1.02,.97,.89),(-.49,1.40,.77),(.20,1.42,.76),(.69,1.40,.76),(1.30,.97,.89)])
build("classic_estate",4.77,.86,[-1.32,1.32],(.89,.23,.035),.99,[(-.96,1.03,.89),(-.53,1.46,.81),(.20,1.48,.80),(.86,1.47,.81),(1.32,1.03,.89)])
build("classic_fastback",4.15,.79,[-1.23,1.23],(.12,.38,.30),.90,[(-.88,.95,.88),(-.49,1.38,.76),(-.23,1.47,.73),(.28,1.48,.73),(.69,1.41,.74),(1.09,1.22,.79),(1.57,.91,.82)])
build("electric_sedan",4.97,.97,[-1.48,1.48],(.82,.84,.86),.90,[(-1.31,.94,.89),(-.63,1.31,.75),(-.2,1.43,.71),(.39,1.44,.71),(.88,1.35,.74),(1.47,1.13,.78),(1.93,.93,.81)])
build("city_bus",10.4,1.24,[-3.12,2.94],(.65,.025,.038),1.45,[(-5.2,1.50,.90),(-4.99,2.96,.94),(-3.45,2.98,.94),(-1.9,2.98,.94),(-.4,2.98,.94),(1.1,2.98,.94),(2.6,2.98,.94),(4.97,2.98,.94),(5.2,1.50,.90)])
