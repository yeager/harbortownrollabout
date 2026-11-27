"""Build the parked burger van and agricultural tractor for the west district."""
from math import cos, sin, pi, radians, tau
from pathlib import Path
import sys
import bpy
from mathutils import Vector, Matrix, noise
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_vehicles as v


def start(name):
    v.clear_scene()
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    return obj


def box(name, pos, dims, mat, bevel=.025):
    return v.cube(name, pos, dims, mat, bevel, root)


def rod(name, a, b, radius, mat, segments=12):
    a, b = Vector(a), Vector(b)
    obj = v.cylinder(name, (a+b)/2, radius, (b-a).length, mat, False, segments, root)
    obj.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()


def disc(name, pos, r, depth, mat):
    return v.cylinder(name,pos,r,depth,mat,root=root)


def save(stem, filename, body_name, separate_glass):
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(v.SOURCE_DIR) / (stem + '.blend')))
    bpy.ops.object.select_all(action="DESELECT")
    # Keep alpha-blended windows independently sortable in Godot.
    body_parts = [part for part in root.children if part.type == "MESH"
                  and not part.name.startswith((separate_glass, "Cab glass", "All terrain tire", "Projector lens", "Upper running light"))]
    for part in body_parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = body_parts[0]
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.join()
    bpy.context.object.name = body_name
    v.export_vehicle(root, filename)


root = start("Kajens burgare")
charcoal = v.material("Charcoal enamel", (.023,.026,.031),.36,.26)
red = v.material("Cherry lacquer",(.58,.016,.024),.34,.24)
def nose_setback(y, lateral_fraction):
    return .12 * min(1.0, max(0.0, (-2.25-y)/.93)) * lateral_fraction**2

def cab_section(y, width, bottom, shoulder, crown):
    # The bonnet has a shallow crown and rolls down into the lamp shoulders.
    half = [(0, crown+.035), (.30, crown+.031), (.55, crown+.021),
            (.69, crown+.007), (.77, crown-.007),
            (.84, crown*.62+shoulder*.38), (.90, crown*.27+shoulder*.73),
            (.94, shoulder), (.972, shoulder-.052), (.993, shoulder-.115),
            (1, shoulder-.16), (1, bottom+.12), (.88, bottom)]
    # The nose projects in the centre and sweeps back towards each headlamp.
    outline = list(reversed(half[1:])) + [(-x,z) for x,z in half]
    return [(width*x, y + nose_setback(y,x), z) for x,z in outline]


cab_stations = [(-3.18,.83,.54,1.02,1.105),
    (-3.15,.878,.54,1.087,1.159),(-3.09,.926,.543,1.146,1.217),
    (-3.01,.966,.548,1.197,1.269),(-2.91,.99,.55,1.24,1.31),
    (-2.62,1,.555,1.325,1.422),
    (-2.25,1,.56,1.43,1.53),(-1.54,1,.59,1.54,1.55),(-.77,1,.60,1.54,1.55)]
cab_body = v.mesh_from_rings("Delivery cab",cab_stations,charcoal,root,section=cab_section)
for side in (-1, 1):
    seam = [(side*.69*width,y+nose_setback(y,.69),crown+.008) for y,width,_,_,crown in cab_stations if y <= -2.25]
    for front, rear in zip(seam, seam[1:]):
        rod("Bonnet panel gap",front,rear,.004,v.BLACK)
# Recess the floor behind the scuttle while keeping both exterior door skins.
footwell = box("Cab floor recess",(0,-1.45,1.70),(1.74,1.25,1.36),None,0)
cut = cab_body.modifiers.new("Footwell", "BOOLEAN")
cut.operation = 'DIFFERENCE'
cut.object = footwell
bpy.context.view_layer.objects.active = cab_body
bpy.ops.object.modifier_apply(modifier=cut.name)
bpy.data.objects.remove(footwell,do_unlink=True)
for side in (-1, 1):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=.488, depth=.64,
        location=(side*1.02,-2.28,.42), rotation=(0,pi/2,0))
    arch_tool = bpy.context.object
    recess = cab_body.modifiers.new("Front wheel housing","BOOLEAN")
    recess.operation = 'DIFFERENCE'
    recess.object = arch_tool
    bpy.context.view_layer.objects.active = cab_body
    bpy.ops.object.modifier_apply(modifier=recess.name)
    bpy.data.objects.remove(arch_tool,do_unlink=True)
    # Rolled wing lip projects beyond the tyre, then returns into the wheel well.
    lip = []
    for step in range(41):
        angle = radians(20 + 140*step/40)
        lip.append([(side*x,-2.28+r*cos(angle),.42+r*sin(angle)) for x,r in
                    [(.986,.526),(1.019,.518),(1.052,.500),(1.054,.488),
                     (1.043,.478),(.970,.478),(.970,.506)]])
    v.profile_loft("Rolled front wing",lip,charcoal,root)
cab_glass = v.material("Tinted cab glazing",(.21,.36,.39),.10,.16)
cab_glass.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = .31
cab_glass.surface_render_method = 'BLENDED'
lamp_cover = v.material("Clear moulded polycarbonate",(.82,.90,.96),.04,.11)
lamp_cover.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = .16
lamp_cover.surface_render_method = 'BLENDED'
indicator = v.material("Amber indicator prism",(.94,.32,.025),.24,.24)
roof_rings = []
for y, width, shoulder, crown in [
    (-1.612,.850,2.396,2.429), (-1.587,.905,2.404,2.454),
    (-1.534,.950,2.414,2.489), (-1.444,.978,2.426,2.514),
    (-1.280,.991,2.434,2.528), (-.960,.995,2.437,2.531),
    (-.710,.988,2.435,2.522)]:
    half = [(0,crown),(.48,crown-.008),(.76,crown-.026),
            (.91,shoulder+.034),(.98,shoulder+.015),(1,shoulder),
            (.99,shoulder-.028),(.94,shoulder-.048)]
    outline = [(-x,z) for x,z in reversed(half[1:])] + half
    roof_rings.append([(x*width,y,z) for x,z in outline])
v.profile_loft("Crowned cab roof",roof_rings,charcoal,root)
box("Dashboard",(0,-2.03,1.58),(1.84,.36,.17),v.DARK,.065)
# A shallow binnacle shades two analogue instruments on the driver-facing fascia.
driver_x = .46  # The cab faces -Y in Blender.
box("Instrument binnacle",(driver_x,-2.008,1.712),(.44,.19,.19),v.BLACK,.046)
for x,needle_angle in [(driver_x-.095,220),(driver_x+.095,135)]:
    rod("Gauge bezel",(x,-1.933,1.731),(x,-1.906,1.731),.078,v.METAL,40)
    rod("Recessed dial",(x,-1.908,1.731),(x,-1.902,1.731),.072,v.BLACK,40)
    center = Vector((x,-1.898,1.731))
    for tick in range(11):
        a = radians(220 - 26*tick)
        radial = Vector((cos(a),0,sin(a)))
        rod("Instrument index",center+radial*.055,center+radial*.064,.0018,v.PAINT_WHITE,8)
    direction = Vector((cos(radians(needle_angle)),0,sin(radians(needle_angle))))
    rod("Gauge pointer",center,center+direction*.054,.0028,red,8)
for x in [-.055,.085]:
    box("Vent recess",(x,-1.849,1.611),(.12,.022,.066),v.BLACK,.009)
    for slat in range(3):
        box("Vent vane",(x,-1.834,1.59+slat*.020),(.103,.012,.006),v.DARK,.002)
for x in [-.46,.46]:
    box("Seat pedestal",(x,-1.35,1.20),(.37,.38,.36),v.BLACK)
    box("Seat cushion",(x,-1.35,1.44),(.54,.52,.13),v.DARK,.06)
    box("Seat back",(x,-1.10,1.67),(.52,.14,.50),v.DARK,.065).rotation_euler.x = -.09
    box("Head restraint",(x,-1.075,1.96),(.31,.135,.17),v.BLACK,.055)
rod("Steering column",(driver_x,-1.99,1.56),(driver_x,-1.84,1.73),.033,v.BLACK)
hub = Vector((driver_x,-1.84,1.73))
rim_tilt = Vector((0,-.09,.153)).normalized()
bpy.ops.mesh.primitive_torus_add(location=hub, major_radius=.18, minor_radius=.016,
                                major_segments=48, minor_segments=12)
wheel = bpy.context.object
wheel.name = "Steering rim"
wheel.parent = root
wheel.rotation_euler = Vector((1,0,0)).cross(rim_tilt).to_track_quat('Z','Y').to_euler()
wheel.data.materials.append(v.BLACK)
for face in wheel.data.polygons:
    face.use_smooth = True
for angle in [0,pi,1.5*pi]:
    tip = hub + .18*(Vector((cos(angle),0,0)) + rim_tilt*sin(angle))
    rod("Steering spoke", hub, tip, .014, v.DARK)
box("Horn pad",hub,(.127,.075,.081),v.BLACK,.03)
# Cross-sections follow the crown of the scuttle and narrow toward the roof.
windshield = []
for y, width, crown in [(-2.228,.86,1.607),(-2.215,.905,1.625),
                        (-2.17,.924,1.68),(-1.83,.90,2.105),
                        (-1.615,.87,2.386),(-1.59,.855,2.415),(-1.581,.817,2.428)]:
    row = []
    for col in range(-8,9):
        fraction = col/8
        row.append((width*fraction,y-.012+.022*fraction**2,crown+.018-.036*fraction**2))
    windshield.append(row + [(x,sy+.015,z-.012) for x,sy,z in reversed(row)])
v.profile_loft("Cab glass windscreen",windshield,cab_glass,root)
for x in [-.39,.36]:
    rod("Wiper blade",(x-.28,-2.206,1.646),(x+.26,-2.169,1.69),.013,v.BLACK)
    rod("Wiper arm",(x+.17,-2.242,1.595),(x,-2.184,1.67),.012,v.DARK)
for s in [-1,1]:
    # A raked front quarter and nearly vertical trailing edge follow the cab pillars.
    aperture = [(-2.12,1.55),(-2.10,1.62),(-1.58,2.25),(-1.52,2.28),
                (-.90,2.28),(-.86,2.24),(-.86,1.56),(-.90,1.52),(-2.06,1.52)]
    inner = [(-1.46+(y+1.46)*.936,1.9+(z-1.9)*.936) for y,z in aperture]
    rim_rows = [[(s*depth,y,z) for y,z in outline] for depth,outline in
                [(1.0,aperture),(1.013,aperture),(1.013,inner),(1.0,inner),(1.0,aperture)]]
    v.profile_loft("Door window seal",rim_rows,v.RUBBER,root,close_ends=False)
    v.profile_loft("Cab glass side", [[(s*x,y,z) for y,z in inner] for x in (1.002,1.006)],cab_glass,root)
    # Fold the painted pillar around the adjoining front and quarter glass.
    pillar = []
    for z,front_y,inner_x,depth in [
        (1.49,-2.30,.865,.208),(1.56,-2.268,.88,.188),
        (1.66,-2.194,.892,.161),(1.95,-1.965,.885,.149),
        (2.23,-1.737,.866,.151),(2.34,-1.662,.85,.168),
        (2.395,-1.616,.842,.182)]:
        section = [(inner_x,0),(inner_x+.025,-.002),(.945,.015),
                   (.974,.039),(.993,.078),(1.002,depth-.031),
                   (.997,depth-.006),(.985,depth),(.957,depth-.005),
                   (inner_x+.010,.033)]
        pillar.append([(s*x,front_y+offset,z) for x,offset in section])
    v.profile_loft("Windscreen pillar",pillar,charcoal,root)
    box("Roof side rail",(s*.965,-1.20,2.30),(.09,.85,.10),charcoal)
    box("Cab rear pillar",(s*.966,-.81,1.92),(.09,.13,.85),charcoal)
    door_edge = [(-2.09,1.47),(-2.015,1.22),(-1.85,.96),(-1.79,.66),
                 (-1.72,.62),(-.88,.62),(-.82,.69),(-.82,2.26)]
    for (y1,z1),(y2,z2) in zip(door_edge,door_edge[1:]):
        rod("Door shut line",(s*1.008,y1,z1),(s*1.008,y2,z2),.009,v.BLACK)
    box("Recessed door handle",(s*1.016,-1.00,1.42),(.034,.18,.062),v.BLACK,.013)
    box("Handle pull",(s*1.042,-1.00,1.43),(.042,.137,.027),v.DARK,.009)
    box("Mirror mounting foot",(s*1.014,-1.92,1.56),(.047,.15,.10),v.RUBBER,.020)
    rod("Folding mirror arm",(s*1.025,-1.92,1.56),(s*1.20,-1.98,1.57),.028,v.DARK)
    rod("Mirror elbow",(s*1.20,-1.98,1.57),(s*1.265,-1.99,1.64),.024,v.DARK)
    # Rounded rectangular rings taper forward. The glass faces aft and inboard.
    for label,finish,sections in [
        ("Mirror shell",v.BLACK,[(-.088,.054,.105),(-.055,.091,.158),(.018,.10,.171),(.039,.096,.167)]),
        ("Mirror silvered face",v.METAL,[(.040,.085,.154),(.044,.085,.154)])
    ]:
        rings = []
        for depth,width,height in sections:
            outline = []
            for j in range(32):
                a = tau*j/32
                dx = width * abs(cos(a))**.55 * (1 if cos(a)>=0 else -1)
                dz = height * abs(sin(a))**.55 * (1 if sin(a)>=0 else -1)
                outline.append((s*(1.265+dx),-1.99+depth+.24*dx,1.78+dz))
            rings.append(outline)
        v.profile_loft(label,rings,finish,root)
    # Across the nose the broad lens stands upright. Its outer tip sweeps up
    # and rearward onto the sloping shoulder of the front wing.
    lamp_sections = [(.49,-3.193,1.025,.025),(.55,-3.197,1.061,.079),
                     (.65,-3.194,1.082,.107),(.755,-3.183,1.105,.111),
                     (.835,-3.154,1.126,.103),(.887,-3.103,1.158,.090),
                     (.923,-3.032,1.195,.068),(.950,-2.957,1.225,.037),
                     (.958,-2.913,1.244,.009)]
    lamp_sections = [(x,y+nose_setback(y,x),z,h) for x,y,z,h in lamp_sections]
    lens_rings, gasket_rings = [], []
    for x,y,z,h in lamp_sections:
        for rings,thickness,offset in [(gasket_rings,h+.012,.010),(lens_rings,h,-.005)]:
            rings.append([(s*x,y+offset-.018*cos(tau*j/16),z+thickness*sin(tau*j/16))
                          for j in range(16)])
    v.profile_loft("Headlamp perimeter seal",gasket_rings,v.BLACK,root)
    v.profile_loft("Swept headlamp reflector",lens_rings,v.METAL,root)
    # Faceted reflector cups surround the small bulbs under a shared clear lens.
    for x,y,z,width,height in [(.604,-3.223,1.071,.061,.047),(.749,-3.217,1.104,.076,.060)]:
        y += nose_setback(y,x)
        cup = []
        for scale,depth in [(1.0,-.011),(.94,-.014),(.73,-.005),(.44,.003),(.17,.008)]:
            ring = []
            for i in range(20):
                angle = tau*i/20
                dx = width*scale*cos(angle)
                ring.append((s*(x+dx),y+depth+.07*dx+nose_setback(y,x+dx)-nose_setback(y,x),z+height*scale*sin(angle)+.18*dx))
            cup.append(ring)
        reflector = v.profile_loft("Faceted lamp reflector",cup,v.METAL,root,close_ends=False)
        for face in reflector.data.polygons:
            face.use_smooth = False
        rod("Headlight bulb",(s*x,y+.004,z),(s*x,y-.004,z),height*.23,v.HEADLAMP,16)
    cover_rings = []
    for x,y,z,h in lamp_sections:
        # The crown clears both optics and returns to the gasket at its edges.
        arc = [(s*x, y-.012-.048*cos(pi*j/16), z+h*sin(pi*j/16))
               for j in range(-8,9)]
        cover_rings.append(arc + [(px,py+.002,pz) for px,py,pz in reversed(arc)])
    v.profile_loft("Projector lens cover",cover_rings,lamp_cover,root)
    for x,y,z,h in lamp_sections[4:7]:
        rod("Turn signal prism",(s*x,y-.024,z-h*.44),
            (s*x,y-.024,z+h*.44),.008,indicator)
    for y in [-2.28,1.88]:
        disc("Tyre",(s*.95,y,.42),.42,.28,v.RUBBER)
        profile=[(1.088,.267),(1.110,.274),(1.119,.263),(1.119,.246),
                 (1.105,.231),(1.101,.205),(1.105,.155),(1.127,.117),(1.135,.075)]
        rim_rings=[[(s*x,y+radius*cos(tau*i/40),.42+radius*sin(tau*i/40))
                    for i in range(40)] for x,radius in profile]
        v.profile_loft("Pressed steel rim",rim_rings,v.METAL,root)
        disc("Hub cap",(s*1.139,y,.42),.066,.026,charcoal)
        for i in range(6):
            angle=tau*i/6
            disc("Rim vent",(s*1.107,y+.18*cos(angle),.42+.18*sin(angle)),.031,.012,charcoal)
        for i in range(5):
            angle=tau*i/5
            v.cylinder("Hex wheel bolt",(s*1.134,y+.095*cos(angle),.42+.095*sin(angle)),
                       .014,.018,v.METAL,True,6,root)
# Sweep the moulded bumper round the nose and tuck its ends into the wings.
bumper_half = [(0,-3.236,.516,.833),(.48,-3.232,.522,.848),
               (.74,-3.208,.530,.881),(.85,-3.172,.536,.898),
               (.935,-3.137,.541,.906),(.977,-3.077,.545,.908),
               (1.004,-3.008,.549,.904),(1.019,-2.930,.553,.895),
               (1.027,-2.826,.559,.880),(1.028,-2.720,.566,.864),
               (1.025,-2.683,.569,.858),(1.020,-2.666,.578,.848)]
bumper_path = [(-x,y,low,high) for x,y,low,high in reversed(bumper_half[1:])] + bumper_half
bumper_rings = []
for i,(x,y,low,high) in enumerate(bumper_path):
    before = Vector(bumper_path[max(i-1,0)][:2])
    after = Vector(bumper_path[min(i+1,len(bumper_path)-1)][:2])
    tangent = (after-before).normalized()
    outward = Vector((tangent.y,-tangent.x))
    bumper_rings.append([(x+outward.x*d,y+outward.y*d,z) for d,z in
                         [(-.066,low),(-.010,low),(.012,low+.034),(.023,high-.088),
                          (.018,high-.031),(-.003,high),(-.066,high)]])
v.profile_loft("Wraparound front bumper",bumper_rings,v.DARK,root)
box("Lower cooling aperture",(0,-3.260,.642),(.89,.022,.114),v.BLACK,.025)
for z in (.622,.660):
    box("Intake vane",(0,-3.274,z),(.82,.014,.010),charcoal,.003)
for side in (-1, 1):
    x = side * .72
    rod("Fog lamp surround",(x,-3.21,.68),(x,-3.248,.68),.079,v.BLACK,32)
    rod("Fog lamp reflector",(x,-3.248,.68),(x,-3.253,.68),.054,v.METAL,32)
    rod("Fog lamp lens",(x,-3.253,.68),(x,-3.258,.68),.042,v.HEADLAMP,32)
box("Front plate carrier",(0,-3.261,.769),(.54,.023,.127),v.BLACK,.009)
box("Registration plate",(0,-3.275,.769),(.518,.006,.108),v.PAINT_WHITE,.004)
plate_text = v.text_obj("Front registration","KAJ 065",(-.166,-3.280,.737),.092,v.BLACK,root=root,flat=True)
plate_text.rotation_euler = (pi/2,0,0)
# A shallow trapezoidal recess carries the perforated grille between the lamps.
outline = [(-.515,1.056),(-.502,1.069),(.502,1.069),(.515,1.056),
           (.432,.862),(.403,.845),(-.403,.845),(-.432,.862)]
grille_sections = []
for depth,scale in [(-3.172,1),(-3.207,1),(-3.216,.972),(-3.205,.918)]:
    grille_sections.append([(x*scale,depth,.956+(z-.956)*scale) for x,z in outline])
v.profile_loft("Grille recess surround",grille_sections,v.BLACK,root)
vertices, faces = [], []
for row in range(4):
    z = .884 + row*.044
    for column in range(-10,11):
        x = (column+.5*(row%2))*.051
        if abs(x)+.026 > .401+row*.018:
            continue
        base = len(vertices)
        for radius in (.0296,.023):
            for corner in range(6):
                angle = pi/2 + corner*tau/6
                vertices.append((x+radius*cos(angle),-3.218,z+radius*sin(angle)))
        for corner in range(6):
            nxt = (corner+1)%6
            faces.append((base+corner,base+nxt,base+6+nxt,base+6+corner))
mesh = bpy.data.meshes.new("Honeycomb grille insert")
mesh.from_pydata(vertices,[],faces)
insert = bpy.data.objects.new(mesh.name,mesh)
bpy.context.collection.objects.link(insert)
insert.parent = root
mesh.materials.append(v.DARK)
box("Chassis rails",(0,.02,.55),(1.58,5.95,.27),v.DARK)
# The kitchen floor sits above the tyres. The skirt drops to a bright
# horizontal sill, broken by a flattened arch as on the reference van.
for side in (-1, 1):
    arch = [(-.78,.48),(1.39,.48),(1.40,.57),(1.43,.68),(1.48,.77),
            (1.54,.839),(1.61,.875),(1.70,.889),(2.06,.889),(2.15,.875),
            (2.22,.839),(2.28,.77),(2.33,.68),(2.36,.57),(2.37,.48),(3.16,.48)]
    panel, edging = [], []
    for y,z in arch:
        panel.append([(side*x,y,h) for x,h in
                      [(1.016,z),(1.112,z),(1.112,.997),(1.016,.997)]])
        edging.append([(side*x,y,z+dz) for x,dz in
                       [(1.108,0),(1.118,0),(1.120,.006),(1.120,.023),
                        (1.116,.028),(1.108,.028)]])
    skirt = v.profile_loft("Wheel arch skirt",panel,charcoal,root)
    # The aluminium edging is rolled, but the skirt above it is flat sheet.
    for face in skirt.data.polygons:
        face.use_smooth = False
    v.profile_loft("Wheel arch edging",edging,v.METAL,root)
box("Kitchen plinth",(0,1.19,1.04),(2.21,3.94,.28),charcoal)
box("Kitchen rear",(0,3.11,1.91),(2.21,.10,1.84),charcoal)
box("Rear door seal",(0,3.169,1.92),(1.81,.028,1.72),v.RUBBER,.024)
for side in [-1,1]:
    box("Rear access door",(side*.448,3.189,1.92),(.876,.032,1.67),charcoal,.018)
    for hinge_z in [1.35,2.47]:
        box("Door hinge leaf",(side*.883,3.213,hinge_z),(.115,.027,.065),v.METAL,.008)
        rod("Door hinge pin",(side*.916,3.229,hinge_z-.049),(side*.916,3.229,hinge_z+.049),.017,v.METAL)
    box("Rear lamp housing",(side*.91,3.17,.94),(.27,.085,.13),v.BLACK,.025)
    box("Rear lamp lens",(side*.91,3.219,.94),(.23,.027,.092),v.TAIL_LAMP,.018)
box("Door latch plate",(.13,3.215,1.72),(.19,.026,.09),v.BLACK,.012)
box("Door latch handle",(.13,3.247,1.73),(.14,.048,.028),v.METAL,.009)
box("Rear access step",(0,3.22,.72),(1.52,.35,.07),v.DARK,.018)
box("Cab bulkhead",(0,-.73,1.91),(2.21,.10,1.84),charcoal)
box("Kitchen far wall",(-1.06,1.19,1.91),(.10,3.94,1.84),charcoal)
box("Roof edging",(0,1.19,2.87),(2.26,3.99,.13),v.METAL)
box("Service sill",(1.13,1.19,1.24),(.54,3.87,.08),v.METAL)
# The two small sliding panes park at either end, leaving the pass open.
service_glass = v.material("Clear service window",(.72,.86,.88),.03,.16)
service_glass.node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value=.14
service_glass.surface_render_method='BLENDED'
for track_z in [1.30,2.78]:
    box("Sliding window track",(1.065,1.19,track_z),(.065,3.83,.036),v.METAL,.008)
for pane_y in [-.18,2.56]:
    box("Parked service pane",(1.067,pane_y,2.04),(.012,.98,1.46),service_glass,.003)
    for stile_y in [pane_y-.49,pane_y+.49]:
        box("Aluminium window stile",(1.067,stile_y,2.04),(.046,.032,1.49),v.METAL,.006)
    grip_y = pane_y+(.42 if pane_y<0 else -.42)
    box("Sliding window pull",(1.089,grip_y,1.73),(.028,.026,.14),v.BLACK,.008)
box("Raised red hatch",(1.67,1.19,2.77),(1.15,3.95,.07),red).rotation_euler.y=.13
# Shallow pressed ribs stiffen the red underside between the hatch end rails.
for y in (-.37,.41,1.19,1.97,2.75):
    rib = box("Raised red hatch rib",(1.666,y,2.731),(1.07,.044,.022),red,.010)
    rib.rotation_euler.y = .13
box("Hatch exterior skin",(1.676,1.19,2.807),(1.12,3.90,.008),charcoal,.003).rotation_euler.y=.13
# Aluminium perimeter follows the slope of the raised service panel.
for end_y in [-.77,3.15]:
    box("Hatch end trim",(1.67,end_y,2.77),(1.16,.035,.082),v.METAL,.009).rotation_euler.y=.13
box("Hatch drip edge",(2.239,1.19,2.696),(.038,3.95,.087),v.METAL,.009)
rod("Hatch hinge",(1.105,-.74,2.84),(1.105,3.12,2.84),.038,v.METAL)
for y in [-.64,3.02]:
    box("Strut bracket",(1.103,y,2.07),(.055,.085,.10),v.METAL,.009)
    rod("Gas spring barrel",(1.12,y,2.07),(1.64,y,2.43),.032,v.BLACK)
    rod("Chrome piston",(1.64,y,2.43),(2.04,y,2.695),.014,v.METAL)
    box("Upper strut bracket",(2.04,y,2.703),(.083,.065,.048),v.METAL,.009)
box("Griddle cabinet",(-.60,1.26,1.26),(.77,2.66,.70),v.METAL)
box("Cast iron griddle",(-.59,1.25,1.63),(.80,1.53,.065),v.BLACK)
box("Extractor canopy",(-.62,1.25,2.50),(.87,2.42,.22),v.METAL)
box("Extractor duct",(-.62,1.25,2.76),(.42,.56,.35),v.METAL,.025)
box("Roof vent flashing",(-.62,1.25,2.948),(.71,.86,.035),v.METAL,.014)
box("Vent throat",(-.62,1.25,3.045),(.54,.69,.18),v.DARK,.018)
for level in [2.995,3.055,3.115]:
    box("Vent louvre",(-.62,1.25,level),(.63,.78,.024),v.METAL,.011)
box("Vent rain cap",(-.62,1.25,3.158),(.72,.87,.055),v.METAL,.023)
box("Brushed steel splashback",(-.991,1.24,2.01),(.035,2.58,.81),v.METAL)
box("Pass shelf",(.90,1.26,1.39),(.34,2.10,.045),v.METAL)
mustard = v.material("Mustard yellow",(.91,.49,.019),0,.46)
kraft = v.material("Unbleached carton",(.60,.38,.19),0,.83)
box("Spice shelf",(-.84,.90,2.12),(.28,.98,.032),v.METAL,.009)
for y in [.49,1.31]:
    rod("Shelf brace",(-.969,y,1.96),(-.72,y,2.105),.012,v.METAL)
for y,seasoning in [(.56,red),(.76,kraft),(.96,mustard),(1.16,kraft)]:
    v.cylinder("Seasoning tin",(-.82,y,2.222),.068,.17,seasoning,False,20,root)
    v.cylinder("Tin label",(-.82,y,2.205),.069,.047,v.PAINT_WHITE,False,20,root)
    v.cylinder("Tin lid",(-.82,y,2.317),.072,.022,v.DARK,False,20,root)
for y in [1.57,2.24]:
    rod("Utensil rail mount",(-.97,y,2.23),(-.84,y,2.23),.019,v.METAL)
rod("Utensil rail",(-.84,1.55,2.23),(-.84,2.26,2.23),.017,v.METAL)
for y in [1.72,2.03]:
    rod("Spatula hook",(-.84,y,2.24),(-.80,y,2.20),.011,v.METAL)
    box("Spatula grip",(-.8,y,2.14),(.028,.038,.14),v.DARK,.009)
    rod("Spatula shank",(-.8,y,2.08),(-.77,y,1.99),.012,v.METAL)
    box("Turner blade",(-.77,y,1.92),(.015,.105,.15),v.METAL,.007)
for y,finish in [(.22,red),(.34,mustard)]:
    v.cylinder("Squeeze bottle",(1.17,y,1.397),.046,.23,finish,False,20,root)
    bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=.034,radius2=.009,depth=.086,location=(1.17,y,1.555))
    nozzle=bpy.context.object
    nozzle.name="Tapered sauce spout"
    nozzle.parent=root
    nozzle.data.materials.append(v.PAINT_WHITE)
# Cans line the customer side of the counter, leaving the middle clear for service.
lime = v.material("Lime soda enamel",(.18,.54,.15),.22,.32)
for index,finish in enumerate((red,lime,mustard,red,lime)):
    y = 2.44+index*.109
    can_rings = [[(1.24+radius*cos(tau*j/20),y+radius*sin(tau*j/20),1.282+height)
                  for j in range(20)] for height,radius in
                 [(0,.035),(.009,.040),(.021,.043),(.145,.043),(.155,.038),(.161,.038)]]
    v.profile_loft("Drink can",can_rings,finish,root)
    v.cylinder("Rolled can lid",(1.24,y,1.446),.039,.006,v.METAL,False,20,root)
    box("Can pull tab",(1.24,y,1.451),(.019,.032,.004),v.DARK,.002)
    v.cylinder("Can label stripe",(1.24,y,1.337),.0435,.013,v.PAINT_WHITE,False,20,root)
for i in range(5):
    box("Takeaway carton",(1.16,2.14,1.305+i*.038),(.23,.29,.048),kraft,.015)
brass = v.material("Brushed brass frame",(.65,.36,.095),.68,.29)
parchment = v.material("Warm certificate paper",(.94,.86,.69),0,.82)
for y in [.63,.95,1.27]:
    box("Counter award frame",(1.20,y,1.455),(.042,.28,.348),brass,.014)
    box("Counter award paper",(1.223,y,1.455),(.005,.243,.310),parchment,.003)
    for z,length in [(1.51,.135),(1.47,.182),(1.45,.154)]:
        box("Counter award ink",(1.227,y,z),(.002,length,.005),charcoal,.001)
    rod("Counter award seal",(1.226,y,1.39),(1.232,y,1.39),.027,brass,20)
for y in [.04,1.20,2.36]:
    v.cylinder("Hatch spotlight housing",(1.54,y,2.695),.061,.108,charcoal,False,20,root)
    v.cylinder("Hatch spotlight bezel",(1.54,y,2.642),.065,.018,v.METAL,False,20,root)
    v.cylinder("Hatch spotlight lens",(1.54,y,2.629),.051,.010,v.HEADLAMP,False,20,root)
for y in [.56,.88,1.20]:
    box("Ingredient pan",(.89,y,1.45),(.24,.26,.085),v.METAL,.02)
    box("Pan contents",(.89,y,1.492),(.20,.22,.012),
        mustard if y==.56 else red if y==.88 else v.material("Leaf lettuce",(.13,.33,.06)))
beef = v.material("Browned smash patty",(.12,.048,.021),0,.77)
cheddar = v.material("Melting cheddar",(.95,.44,.025),0,.41)
for index,(x,y) in enumerate([(-.48,.83),(-.63,1.10),(-.47,1.42),(-.57,1.71)]):
    rings = []
    for radius,height in [(.085,0),(.116,.009),(.111,.032),(.087,.044),(.043,.048)]:
        ring = []
        for step in range(32):
            angle = tau*step/32
            edge = radius*(1+.052*sin(5*angle+index)+.045*cos(9*angle-index))
            ring.append((x+edge*cos(angle),y+edge*sin(angle),1.6625+height))
        rings.append(ring)
    v.profile_loft("Seared burger patty",rings,beef,root)
    if index in (1,3):
        # The middle rests on the patty while the four corners drape over its edge.
        cheese_rings = []
        for scale,drop in [(.99,.003),(1,0),(.65,0),(.15,0)]:
            ring = []
            for step in range(24):
                angle = tau*step/24 + index*.23
                divisor = max(abs(cos(angle)),abs(sin(angle)))
                radius = .099*scale/divisor
                z = 1.713 - max(0,radius-.086)*.64 - drop
                ring.append((x+radius*cos(angle),y+radius*sin(angle),z))
            cheese_rings.append(ring)
        v.profile_loft("Draped cheddar",cheese_rings,cheddar,root,close_ends=False)
        v.cylinder("Cheddar centre",(x,y,1.712),.025,.002,cheddar,False,20,root)
for y in [-.35,2.70]:
    box("Menu frame",(1.09,y,2.02),(.07,.61,1.32),v.METAL)
    box("Chalkboard",(1.14,y,2.02),(.04,.55,1.25),v.DARK)
    # Illustrated chalk menus stay legible to children across game languages.
    chalk = v.PAINT_WHITE
    if y < 0:
        arch = [(y+.17*cos(i*pi/12),2.22+.13*sin(i*pi/12)) for i in range(13)]
        arch += [(y+.17,2.22)]
        for a,b in zip(arch,arch[1:]):
            rod("Chalk bun",(1.166,*a),(1.166,*b),.009,chalk,8)
        for z in [2.17,2.12]:
            rod("Chalk burger filling",(1.166,y-.16,z),(1.166,y+.16,z),.010,chalk,8)
        price = "65 kr"
    else:
        outline = [(-.13,2.28),(.13,2.28),(.095,2.04),(-.095,2.04),(-.13,2.28)]
        for a,b in zip(outline,outline[1:]):
            rod("Chalk cup",(1.166,y+a[0],a[1]),(1.166,y+b[0],b[1]),.009,chalk,8)
        rod("Chalk straw",(1.166,y+.02,2.29),(1.166,y+.08,2.42),.010,chalk,8)
        price = "15 kr"
    v.text_obj("Chalk price",price,(1.17,y-.19,1.82),.15,chalk,side=-1,root=root,flat=True)
v.text_obj("Serving counter lettering","KAJENS BURGARE",(1.113,-.50,.92),.29,v.PAINT_WHITE,side=-1,root=root,flat=True)
# Road-facing sign reads in the opposite direction along the kitchen wall.
v.text_obj("Roadside name","KAJENS BURGARE",(-1.12,2.83,1.89),.39,v.PAINT_WHITE,side=1,root=root,flat=True)
v.text_obj("Roadside kitchen sign","STREET FOOD",(-1.12,1.99,1.60),.19,v.PAINT_WHITE,side=1,root=root,flat=True)
for trim_z in [1.52,2.27]:
    box("Sign pinstripe",(-1.12,1.19,trim_z),(.012,3.38,.018),red,.004)
save("FoodTruck","food_truck.glb","Food truck body","Parked service pane")

root = start("Lantbrukstraktor")
red=v.material("Vermilion tractor enamel",(.63,.018,.021),.34,.24)
box("Gearbox",(0,.1,.91),(.83,3.7,.62),v.DARK,.12)
# Axle housings connect the inner wheel plates across the chassis.
# Pack a seamless field-dust tile into the vehicle so parked and driven wheels match.
def tyre_finish(name, low, high):
    finish = v.material(name, low, 0, .94)
    size = 128
    image = bpy.data.images.new(name, size, size, alpha=False)
    pixels = []
    for row in range(size):
        for col in range(size):
            u, t = tau*col/size, tau*row/size
            point = Vector(((2+.55*cos(t))*cos(u),(2+.55*cos(t))*sin(u),.55*sin(t)))
            dust = max(0,min(1,.45 + .7*noise.noise(point*1.8) + .25*noise.noise(point*18)))
            linear = [a+(b-a)*dust for a,b in zip(low,high)]
            pixels.extend([1.055*channel**(1/2.4)-.055 for channel in linear] + [1])
    image.colorspace_settings.name = "sRGB"
    image.pixels.foreach_set(pixels)
    image.pack()
    tex = finish.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    shader = next(node for node in finish.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    finish.node_tree.links.new(tex.outputs["Color"],shader.inputs["Base Color"])
    return finish

def tyre_uv(mesh):
    mesh.update()
    uv = mesh.uv_layers.new(name="Tyre grain")
    for face in mesh.polygons:
        axis = max(range(3),key=lambda i: abs(face.normal[i]))
        for index in face.loop_indices:
            point = mesh.vertices[mesh.loops[index].vertex_index].co
            uv.data[index].uv = (point[(axis+1)%3]*2,point[(axis+2)%3]*2)

field_rubber = tyre_finish("Weathered sidewall",(.011,.012,.012),(.052,.049,.043))
dusty_tread = tyre_finish("Dust on tread crowns",(.019,.020,.019),(.078,.072,.061))
front_radius = .70
for axle_y,axle_z,outer_x in [(-1.58,front_radius,.86),(1.03,.93,.81)]:
    stations=[(-outer_x,.115),(-.71,.145),(-.35,.128),(-.21,.205),
              (0,.235),(.21,.205),(.35,.128),(.71,.145),(outer_x,.115)]
    axle_rings=[[(x,axle_y+radius*cos(tau*i/24),axle_z+radius*sin(tau*i/24))
                 for i in range(24)] for x,radius in stations]
    v.profile_loft("Cast axle housing",axle_rings,v.DARK,root)
rod("Front steering tie rod",(-.76,-1.42,front_radius-.03),(.76,-1.42,front_radius-.03),.032,v.METAL)
for side in [-1,1]:
    rod("Steering knuckle arm",(side*.76,-1.42,front_radius-.03),(side*.82,-1.58,front_radius),.047,v.BLACK)
v.mesh_from_rings("Sculpted bonnet",[(-2.26,.49,1.02,1.40,1.54),
    (-2.18,.55,1.02,1.52,1.634),(-2.04,.605,1.02,1.65,1.76),
    (-1.52,.64,1.05,1.84,2.0),(-.65,.66,1.08,1.93,2.06),(-.27,.60,1.10,1.93,2.03)],red,root)
# The graphite insert folds over the nose and broadens along the raised bonnet.
insert_sections = [
    (-2.291,.15,1.25), (-2.291,.23,1.48), (-2.282,.27,1.55),
    (-2.253,.29,1.601), (-2.18,.32,1.687),
    (-2.04,.36,1.802), (-1.52,.40,2.042), (-.87,.33,2.086)]
insert_rings = []
for y, width, crest in insert_sections:
    insert_rings.append([(-width,y,crest-.026),(0,y,crest+.008),(width,y,crest-.026),
                         (width,y+.014,crest-.046),(0,y+.014,crest-.013),(-width,y+.014,crest-.046)])
v.profile_loft("Graphite bonnet spine",insert_rings,v.BLACK,root)
for side in [-1,1]:
    # Follow the bonnet flare, sweeping the lower edge up toward the cab.
    vent_sections = [(-2.10,.588,1.25,1.28),(-2.04,.61,1.24,1.42),
                     (-1.76,.633,1.30,1.56),(-1.52,.645,1.39,1.66),
                     (-1.18,.654,1.56,1.71),(-.78,.662,1.69,1.75)]
    vent_rings = []
    for y,width,low,high in vent_sections:
        vent_rings.append([(side*width,y,low),(side*(width+.009),y,low+.007),
                           (side*(width+.009),y,high-.007),(side*width,y,high)])
    v.profile_loft("Swept bonnet side insert",vent_rings,v.BLACK,root)
    # The vent blades follow the taper of the dark insert on the hood.
    for first, last in zip(vent_sections[1:4], vent_sections[2:5]):
        for position in (.23, .67):
            y, width, low, high = [a+(b-a)*position for a,b in zip(first,last)]
            blade = box("Bonnet cooling louvre", (side*(width+.010), y, (low+high)*.5),
                        (.016,.024,(high-low)*.68), v.DARK,.005)
            blade.rotation_euler.x = -.27
    rod("Bright V badge",(0,-2.302,1.31),(side*.066,-2.302,1.394),.012,v.METAL)
    # The blade climbs across the nose, then turns back along the bonnet shoulder.
    lamp_path = [(.115,-2.296,1.239,1.263),(.19,-2.296,1.245,1.280),
                 (.29,-2.294,1.264,1.425),(.34,-2.291,1.287,1.464),
                 (.463,-2.274,1.322,1.497),(.515,-2.228,1.386,1.510),
                 (.563,-2.158,1.445,1.546),(.607,-2.045,1.506,1.592),
                 (.624,-1.935,1.566,1.625),(.636,-1.83,1.629,1.646)]
    reflector, light_guide, lower_trim = [], [], []
    for x,y,low,high in lamp_path:
        low -= .023
        y -= .027
        lower_trim.append([(side*x,y-.004,low),(side*x,y-.004,low+.009),
                           (side*x,y+.008,low+.009),(side*x,y+.008,low)])
        reflector.append([(side*x,y,low),(side*x,y,high),
                          (side*x,y+.026,high),(side*x,y+.026,low)])
        light_guide.append([(side*(x+.004),y-.006,high-.026),
                            (side*(x+.004),y-.006,high),
                            (side*x,y+.003,high),(side*x,y+.003,high-.026)])
    v.profile_loft("Wraparound headlamp housing",reflector,v.BLACK,root)
    v.profile_loft("Upper running light",light_guide,v.HEADLAMP,root)
    v.profile_loft("Lower reflector rim",lower_trim,v.METAL,root)
    rod("Recessed projector barrel",(side*.32,-2.316,1.374),(side*.32,-2.331,1.374),.058,v.DARK)
    rod("Projector bezel",(side*.32,-2.331,1.374),(side*.32,-2.339,1.374),.048,v.METAL)
    rod("Projector lens",(side*.32,-2.339,1.374),(side*.32,-2.345,1.374),.036,v.HEADLAMP)
for z in [1.08,1.12,1.16]:
    box("Lower intake slat",(0,-2.267,z),(.59,.03,.021),v.DARK,.008)
box("Front linkage carrier",(0,-1.96,.89),(.56,.63,.29),v.DARK,.06)
for side in [-1,1]:
    pivot=(side*.22,-2.15,.85)
    elbow=(side*.29,-2.37,.57)
    tip=(side*.32,-2.53,.59)
    rod("Front lift arm",pivot,elbow,.055,v.DARK)
    rod("Front lift hook",elbow,tip,.055,v.DARK)
    rod("Front hook tip",tip,(side*.32,-2.55,.65),.044,v.DARK)
    disc("Linkage pivot pin",(side*.244,-2.15,.85),.069,.075,v.METAL)
rod("Front linkage crossbar",(-.27,-2.34,.60),(.27,-2.34,.60),.038,v.BLACK)
glazing = v.material("Blue-green laminated cab glass", (.070,.19,.18), .08,.17)
next(node for node in glazing.node_tree.nodes if node.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = .43
glazing.surface_render_method = 'BLENDED'
v.mesh_from_rings("Glazed operator cab",[(-.43,.64,1.46,2.91,3.0),(-.21,.77,1.45,3.12,3.20),
    (1.32,.76,1.54,3.14,3.20),(1.48,.67,1.67,2.96,3.02)],glazing,root)
# The red sill follows the shallow U at the foot of the rear windscreen.
rear_sill, rear_seal = [], []
for section in range(25):
    fraction = (section-12)/12
    x = .67*fraction
    sill_top = 1.74 + .25*fraction**2
    rear_sill.append([(x,1.45,1.63),(x,1.52,1.63),(x,1.52,sill_top-.016),
                      (x,1.50,sill_top),(x,1.45,sill_top)])
    rear_seal.append([(x,1.478,sill_top-.014),(x,1.515,sill_top-.014),
                      (x,1.521,sill_top+.012),(x,1.494,sill_top+.031),
                      (x,1.478,sill_top+.023)])
v.profile_loft("Curved rear cab sill",rear_sill,red,root)
v.profile_loft("Rear glazing lower seal",rear_seal,v.RUBBER,root)
# Sweep one rubber extrusion up both sides and around the top corners.
seal_path = [(-.67,1.99),(-.67,2.22),(-.65,2.76)]
for side in (-1,1):
    for step in range(13):
        angle = pi - (step + (12 if side == 1 else 0))*pi/24
        seal_path.append((side*.51 + .13*cos(angle),2.88 + .13*sin(angle)))
seal_path.extend([(.65,2.76),(.67,2.22),(.67,1.99)])
seal_rings = []
for i,(x,z) in enumerate(seal_path):
    before = Vector(seal_path[max(0,i-1)])
    after = Vector(seal_path[min(len(seal_path)-1,i+1)])
    tangent = (after-before).normalized()
    seal_rings.append([(x+.028*tangent.y*cos(tau*j/12),1.502+.019*sin(tau*j/12),
                        z-.028*tangent.x*cos(tau*j/12)) for j in range(12)])
v.profile_loft("Rounded rear window surround",seal_rings,v.RUBBER,root)
# The round speed plate faces following drivers through the rear window.
plate_center = Vector((.46,1.493,2.79))
rod("Speed plate border",plate_center,plate_center+Vector((0,.009,0)),.121,v.BLACK)
rod("Speed plate face",plate_center+Vector((0,.010,0)),plate_center+Vector((0,.014,0)),.106,v.PAINT_WHITE)
speed_text = bpy.data.curves.new("Speed plate numerals", "FONT")
speed_text.body = "50"
speed_text.align_x = "CENTER"
speed_text.align_y = "CENTER"
speed_text.size = .144
speed_text.resolution_u = 4
plate_label = bpy.data.objects.new("Rear speed marking",speed_text)
bpy.context.collection.objects.link(plate_label)
plate_label.parent = root
plate_label.location = plate_center+Vector((0,.016,0))
plate_label.rotation_euler = (pi/2,0,pi)
speed_text.materials.append(v.BLACK)
bpy.ops.object.select_all(action="DESELECT")
plate_label.select_set(True)
bpy.context.view_layer.objects.active = plate_label
bpy.ops.object.convert(target="MESH")
box("Cab floor",(0,.54,1.48),(1.48,1.76,.13),v.DARK)
box("Suspension pedestal",(0,.79,1.72),(.34,.36,.38),v.BLACK)
cloth = v.material("Graphite woven upholstery",(.10,.12,.14),0,.87)
box("Seat cushion",(0,.76,1.97),(.57,.54,.15),cloth,.07)
# The back widens at the shoulders and tapers into the headrest supports.
seat_sections = [(1.965,.16,.055),(2.00,.245,.075),(2.10,.265,.09),
                 (2.27,.239,.09),(2.39,.268,.084),(2.46,.241,.072),(2.49,.162,.048)]
seat_rings = []
for height,width,depth in seat_sections:
    center_y = .98 + .12*(height-2)
    seat_rings.append([(width*cos(tau*j/32),center_y+depth*sin(tau*j/32),height)
                       for j in range(32)])
v.profile_loft("Contoured driver seat back",seat_rings,cloth,root)
for x in (-.095,.095):
    rod("Headrest post",(x,1.032,2.46),(x,1.04,2.55),.012,v.METAL)
# Clip both sets of elastic cords to the rectangular pocket opening.
for direction in (-1,1):
    for offset in range(-4,5):
        base = offset*.082
        low = max(-.105, -direction*base-.16)
        high = min(.105, -direction*base+.16)
        if high-low < .015:
            continue
        ends = [(base+direction*t,1.103+.12*t,2.23+t) for t in (low,high)]
        rod("Seat pocket elastic",*ends,.0055,v.BLACK)
for z in (2.125,2.335):
    y = 1.103+.12*(z-2.23)
    rod("Pocket binding",(-.16,y,z),(.16,y,z),.009,v.BLACK)
for x in (-.16,.16):
    rod("Pocket edging",(x,1.0904,2.125),(x,1.1156,2.335),.009,v.BLACK)
box("Headrest",(0,1.04,2.58),(.33,.13,.18),cloth,.05)
for side in [-1,1]:
    box("Armrest",(side*.34,.78,2.14),(.09,.34,.08),v.DARK)
box("Dashboard",(0,-.19,2.02),(1.15,.29,.23),v.DARK,.07)
# Recessed air outlets flank the dials on the face toward the seat.
for side in (-1, 1):
    vent_x = side * .445
    box("Dashboard vent surround",(vent_x,-.047,2.04),(.19,.021,.085),v.BLACK,.014)
    for slat in (-1,0,1):
        box("Vent vane",(vent_x,-.033,2.04+slat*.019),(.158,.012,.008),v.DARK,.003)
for switch_x in (.19,.24,.29):
    box("Rocker switch bezel",(switch_x,-.046,2.02),(.042,.018,.065),v.BLACK,.006)
    box("Rocker paddle",(switch_x,-.031,2.02),(.032,.018,.051),v.DARK,.005).rotation_euler.x=.13
    box("Switch marker",(switch_x,-.020,2.033),(.015,.004,.004),v.PAINT_WHITE,.001)
box("Instrument binnacle",(0,-.145,2.166),(.49,.19,.17),v.BLACK,.037)
for gauge_x in (-.112,.112):
    rod("Instrument bezel",(gauge_x,-.058,2.176),(gauge_x,-.043,2.176),.072,v.METAL,32)
    rod("Gauge dial",(gauge_x,-.042,2.176),(gauge_x,-.038,2.176),.064,v.BLACK,32)
    for tick in range(9):
        theta = radians(-118+tick*29.5)
        rod("Dial graduation",(gauge_x+.047*sin(theta),-.036,2.176+.047*cos(theta)),
            (gauge_x+.057*sin(theta),-.036,2.176+.057*cos(theta)),.0027,v.PAINT_WHITE)
    rod("Instrument pointer",(gauge_x,-.032,2.176),
        (gauge_x+.036,-.032,2.201),.004,v.PAINT_RED)
box("Hydraulic lever console",(.47,.58,1.99),(.19,.41,.16),v.DARK,.025)
rod("Hydraulic lever",(.47,.53,2.06),(.46,.48,2.21),.014,v.BLACK)
box("Hydraulic lever grip",(.46,.48,2.22),(.062,.065,.076),v.DARK,.022)
column_base = Vector((0,-.19,1.82))
wheel_center = Vector((0,.18,2.19))
column_axis = (wheel_center-column_base).normalized()
wheel_rotation = column_axis.to_track_quat('Z','Y')
rod("Steering column",column_base,wheel_center,.038,v.DARK)
bpy.ops.mesh.primitive_torus_add(location=wheel_center,rotation=wheel_rotation.to_euler(),
                                major_radius=.19,minor_radius=.022,major_segments=48,minor_segments=12)
rim=bpy.context.object
rim.name="Steering wheel"
rim.parent=root
rim.data.materials.append(v.RUBBER)
for face in rim.data.polygons:
    face.use_smooth = True
for angle in (pi/6,5*pi/6,3*pi/2):
    end = wheel_center + wheel_rotation @ Vector((.19*cos(angle),.19*sin(angle),0))
    rod("Steering spoke",wheel_center,end,.013,v.DARK)
rod("Steering wheel hub",wheel_center-column_axis*.018,wheel_center+column_axis*.021,.048,v.BLACK,32)
# Horizontal rounded rectangles taper from the eaves into the roof crown.
roof_sections = []
for width, length, corner, height in [
    (.78,.94,.16,3.135), (.84,.99,.18,3.16), (.86,1.01,.19,3.21),
    (.85,1.00,.19,3.255), (.78,.94,.18,3.30), (.58,.72,.17,3.335),
    (.31,.42,.13,3.345)
]:
    outline = []
    for sx, sy, quadrant in [(1,1,0),(-1,1,1),(-1,-1,2),(1,-1,3)]:
        for step in range(6):
            angle = (quadrant + step/5) * pi/2
            x = sx*(width-corner)+corner*cos(angle)
            y = sy*(length-corner)+corner*sin(angle)
            # Sweep the visor down at the corners and gently arch the center panel.
            crown = .067 * (1 - (x/.86)**2) * (1 - (y/1.01)**2)
            rear_corner_drop = .075 * max(0, y/1.01)**3 * (x/.86)**2
            outline.append((x, .55+y, height+crown-rear_corner_drop))
    roof_sections.append(outline)
v.profile_loft("Crowned cab roof", roof_sections, red, root)
# Bent roof rails stand clear of the roof skin and leave room for the beacon.
for side in (-1, 1):
    rail_x = side * .73
    mounts = [(rail_x, -.32, 3.29), (rail_x, -.23, 3.39),
              (rail_x, 1.30, 3.39), (rail_x, 1.40, 3.29)]
    for start_point, end_point in zip(mounts, mounts[1:]):
        rod("Roof protection rail", start_point, end_point, .032, v.DARK)
    for y in (-.32, 1.40):
        box("Roof rail foot", (rail_x, y, 3.294), (.12,.17,.035), v.RUBBER,.012)
# Recess the LED cells behind the front edge of the roof.
box("Roof light bar housing",(0,-.454,3.205),(.84,.10,.096),v.BLACK,.018)
for cell in range(12):
    box("Roof LED reflector",((cell-5.5)*.065,-.507,3.207),(.048,.012,.043),v.HEADLAMP,.006)
# A recessed rear work bar sits between the paired corner lights.
box("Rear work bar gasket",(0,1.547,3.162),(.89,.08,.155),v.RUBBER,.033)
box("Rear work bar recess",(0,1.585,3.167),(.81,.021,.113),v.DARK,.015)
for column in range(12):
    for row in (-1,1):
        box("Rear work bar optic",((column-5.5)*.064,1.598,3.167+row*.022),
            (.050,.008,.030),v.METAL,.004)
# Top-mounted wipers park across the upper glass.
for label, pane_y, outward in [("Windscreen", -.43, -1), ("Rear window", 1.48, 1)]:
    arm_y = pane_y + outward*.042
    rod(label+" spindle", (0,pane_y,2.90), (0,arm_y,2.90), .032, v.BLACK)
    rod(label+" wiper arm", (0,arm_y,2.90), (.35,arm_y,2.72), .014, v.DARK)
    rod(label+" blade", (.08,arm_y,2.69), (.59,arm_y,2.75), .018, v.BLACK)
for side in [-1,1]:
    x = side*.79
    for z in [1.66,2.32]:
        rod("Grab rail mount", (side*.73,-.23,z), (x,-.30,z), .023, v.BLACK)
    rod("Cab entry grab rail", (x,-.30,1.66), (x,-.30,2.32), .024, v.DARK)
for s in [-1,1]:
    for y in [-.28,1.34]:
        # A pressed pillar narrows at eye level and sweeps inward under the eave.
        rear = y > 0
        rail = []
        for z, x, offset, width, depth in [
            (1.54,.727,.045,.051,.064), (1.81,.744,.038,.047,.060),
            (2.20,.749,.018,.033,.049), (2.69,.733,-.012,.030,.045),
            (2.94,.710,-.046,.034,.051), (3.18,.678,-.087,.046,.063)
        ]:
            center_y = y + (offset if rear else -offset)
            rail.append([(s*x + width*cos(tau*j/16),center_y + depth*sin(tau*j/16),z)
                         for j in range(16)])
        v.profile_loft("Swept cab pillar",rail,v.BLACK,root)
        facing = -1 if y<0 else 1
        lamp_y = y+facing*.14
        box("Corner work light pod",(s*.65,lamp_y,3.12),(.29,.16,.16),v.BLACK,.046)
        for offset in (-.065,.065):
            lamp_x = s*(.65+offset)
            rod("Work lamp rim",(lamp_x,lamp_y+facing*.074,3.12),
                (lamp_x,lamp_y+facing*.089,3.12),.058,v.METAL)
            rod("Work lamp lens",(lamp_x,lamp_y+facing*.09,3.12),
                (lamp_x,lamp_y+facing*.096,3.12),.046,v.HEADLAMP)
    box("Mirror pivot mount",(s*.75,-.27,3.025),(.14,.12,.12),v.DARK,.022)
    rod("Mirror outrigger",(s*.76,-.27,3.04),(s*1.18,-.38,3.01),.025,v.BLACK)
    rod("Mirror drop arm",(s*1.18,-.38,3.01),(s*1.24,-.38,2.81),.023,v.BLACK)
    mirror = box("Mirror housing",(s*1.24,-.38,2.70),(.20,.11,.34),v.BLACK,.045)
    mirror.rotation_euler.z = s*.19
    glass = box("Mirror glass",(s*1.25,-.326,2.70),(.166,.017,.302),v.METAL,.026)
    glass.rotation_euler.z = mirror.rotation_euler.z
    # The lower rear corner of the door sweeps over the wheel arch.
    door_outline = [(-.18,1.59),(.28,1.62),(.45,1.86),(.77,2.04),
                    (.85,2.14),(.86,3.04),(.78,3.09),(-.16,3.08),(-.18,1.59)]
    for (y1,z1),(y2,z2) in zip(door_outline,door_outline[1:]):
        rod("Moulded door seal",(s*.767,y1,z1),(s*.767,y2,z2),.024,v.BLACK)
    for handle_y in (.55,.72):
        box("Latch stand-off",(s*.788,handle_y,2.17),(.044,.035,.050),v.DARK,.008)
    box("Cab door pull",(s*.813,.635,2.17),(.033,.207,.039),v.BLACK,.013)
    for rail_y in [-.39,.03]:
        rod("Entry ladder side rail",(s*.64,rail_y,1.48),(s*.91,rail_y,.75),.032,v.BLACK)
    for i in range(3):
        step_x = .77+i*.08
        step_z = 1.23-i*.22
        box("Access tread",(s*step_x,-.18,step_z),(.34,.49,.056),v.METAL)
        for offset in [-.09,0,.09]:
            box("Grip ridge",(s*(step_x+offset),-.18,step_z+.031),
                (.022,.44,.014),v.DARK,.004)
    rod("Lower hitch arm",(s*.34,1.47,.92),(s*.55,2.26,.52),.076,v.DARK)
    for y,r,w in [(-1.58,front_radius,.46),(1.03,.93,.58)]:
        x=s*1.02
        existing = set(root.children)
        # Revolve a crowned casing and a pressed steel rim around the axle.
        tyre_profile = [(-.44,.53),(-.51,.63),(-.54,.78),(-.49,.89),
                        (-.37,.95),(0,.97),(.37,.95),(.49,.89),
                        (.54,.78),(.51,.63),(.44,.53)]
        rim_profile = [(.42,.56),(.51,.574),(.535,.552),(.51,.525),
                       (.42,.50),(.365,.44),(.36,.35),(.40,.29),(.46,.23)]
        for name, profile, material in [("Agricultural tyre",tyre_profile,field_rubber),
                                         ("Ivory wheel dish",rim_profile,v.PAINT_WHITE)]:
            rings = [[(x+s*w*offset,y+r*radius*sin(tau*j/48),r+r*radius*cos(tau*j/48))
                      for j in range(48)] for offset,radius in profile]
            if material == field_rubber:
                rings.append(rings[0])
            surface = v.profile_loft(name,rings,material,root,close_ends=False)
            if material == field_rubber:
                tyre_uv(surface.data)
        flange_x = x+s*w*.46
        disc("Steel mounting flange",(flange_x,y,r),r*.284,.054,v.METAL)
        disc("Inner wheel plate",(x-s*w*.41,y,r),r*.55,.04,v.DARK)
        disc("Axle hub",(flange_x+s*.042,y,r),r*.157,.066,v.DARK)
        disc("Hub dust cap",(flange_x+s*.078,y,r),r*.111,.020,v.BLACK)
        for bolt in range(8):
            angle=tau*bolt/8
            bolt_y, bolt_z = y+r*.219*sin(angle), r+r*.219*cos(angle)
            disc("Lug washer",(flange_x+s*.032,bolt_y,bolt_z),r*.041,.014,v.DARK)
            v.cylinder("Wheel nut",(flange_x+s*.051,bolt_y,bolt_z),
                       r*.030,.033,v.METAL,True,6,root)
        # Each moulded bar follows the crown down onto the shoulder.
        tread_vertices, tread_faces = [], []
        contact_faces = []
        for lug_index in range(18):
            for hand in (-1, 1):
                phase = tau * (lug_index + (.20 if hand < 0 else 0)) / 18
                first = len(tread_vertices)
                for lateral, base_radius, sweep in [
                    (.015,.958,0), (.20,.95,.070), (.37,.94,.15),
                    (.49,.875,.215), (.55,.775,.254)
                ]:
                    # Shallower shoulder tips leave the sidewall exposed. Wear follows
                    # a fixed pattern so rebuilding the model preserves the same tyre.
                    wear = .005*sin(lug_index*2.39 + hand + lateral*3)
                    height = .087 - .031*(lateral/.55)**3 + wear
                    for radius, half_angle in [(base_radius,-.059),(base_radius,.059),
                                               (base_radius+height,.042),(base_radius+height,-.042)]:
                        angle = phase + sweep + half_angle
                        tread_vertices.append((x+hand*w*lateral,y+r*radius*sin(angle),
                                               r+r*radius*cos(angle)))
                faces = [(0,1,2,3), (19,18,17,16)]
                for station in range(4):
                    for edge in range(4):
                        j = station*4 + edge
                        k = station*4 + (edge+1)%4
                        if edge == 2 and station < 3:
                            contact_faces.append(len(tread_faces)+len(faces))
                        faces.append((j,j+4,k+4,k))
                tread_faces.extend(tuple(first+i for i in (face[::-1] if hand>0 else face))
                                   for face in faces)
        tread_mesh = bpy.data.meshes.new("Swept chevron bars")
        tread_mesh.from_pydata(tread_vertices, [], tread_faces)
        tyre_uv(tread_mesh)
        tread_mesh.materials.append(field_rubber)
        tread_mesh.materials.append(dusty_tread)
        for face_index in contact_faces:
            tread_mesh.polygons[face_index].material_index = 1
        tread = bpy.data.objects.new("Chevron tread", tread_mesh)
        bpy.context.collection.objects.link(tread)
        tread.parent = root
        bevel = tread.modifiers.new("Worn tread edges", "BEVEL")
        bevel.width = .009
        bevel.segments = 2
        bevel.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = tread
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        # Export each complete wheel as one rotating assembly.
        bpy.ops.object.select_all(action="DESELECT")
        wheel_parts = set(root.children) - existing
        for part in wheel_parts:
            part.select_set(True)
        casing = next(part for part in wheel_parts if part.name.startswith("Agricultural tyre"))
        bpy.context.view_layer.objects.active = casing
        bpy.ops.object.join()
        casing.name = "All terrain tire"
        # Curved pressed guard spanning the crown of each wheel.
        section = [(-.60,.080),(-.43,.102),(.10,.116),(.36,.107),(.57,.084),(.62,.060)]
        if y > 0:
            # The inner wing rises into the cab sill, then rolls down over the tyre.
            section = [(-.72,.09),(-.64,.155),(-.52,.174),(-.34,.152),
                       (-.08,.126),(.20,.114),(.36,.107),(.51,.096),
                       (.60,.071),(.635,.030),(.638,-.010)]
        verts=[]
        faces=[]
        for i in range(33):
            angle=radians(-66+i*4)
            for j,(offset,rise) in enumerate(section):
                # The front lip sweeps back at its corners, exposing the tyre shoulder.
                lip = max(0,1-i/6) if y<0 else 0
                arc = angle + radians(lip*(9+8*abs(offset)))
                radius = r+rise-lip*.023
                if y > 0 and offset < 0:
                    radius += .065*(-offset)*cos(arc)**2
                verts.append((x+s*w*offset*(1-.12*lip),y+radius*sin(arc),r+radius*cos(arc)))
                if i and j:
                    last=len(verts)-1
                    face=(last-len(section)-1,last-len(section),last,last-1)
                    faces.append(face if s>0 else face[::-1])
        mesh=bpy.data.meshes.new("Curved mudguard")
        mesh.from_pydata(verts,[],faces)
        guard=bpy.data.objects.new("Pressed mudguard",mesh)
        bpy.context.collection.objects.link(guard)
        guard.parent=root
        mesh.materials.append(red if y>0 else v.DARK)
        mesh.materials.append(v.BLACK)
        for face in mesh.polygons:
            face.use_smooth=True
            face.material_index=int(face.index % (len(section)-1) >= (6 if y>0 else 3))
        guard.modifiers.new("Rolled edge","SOLIDIFY").thickness=.012 if y<0 else .025
# Rear implement carrier and linkage, between the large rear wheels.
housing_sections = []
for depth, width, bottom, top in [(1.44,.36,.75,1.48),(1.54,.42,.70,1.53),
                                  (1.84,.42,.70,1.53),(1.94,.36,.73,1.44)]:
    housing_sections.append([(x,depth,z) for x,z in [
        (-width*.48,bottom),(-width*.73,bottom+.12),(-width,1.14),
        (-width,top-.08),(-width*.75,top),(width*.75,top),
        (width,top-.08),(width,1.14),(width*.73,bottom+.12),(width*.48,bottom)]])
v.profile_loft("Cast lift housing",housing_sections,v.DARK,root)
for side in (-1,1):
    box("Top link clevis cheek",(side*.086,1.98,1.37),(.041,.20,.22),v.BLACK,.021)
    for z in (.84,.99):
        rod("Housing cover bolt",(side*.20,1.931,z),(side*.20,1.956,z),.026,v.METAL)
rod("Top link pivot pin",(-.13,2.03,1.40),(.13,2.03,1.40),.038,v.METAL)
rod("Top link barrel",(0,2.03,1.40),(0,2.15,1.20),.058,v.DARK)
rod("Top link adjuster",(0,2.15,1.20),(0,2.22,1.04),.033,v.METAL)
rod("PTO guard",(0,1.89,.88),(0,2.07,.88),.138,v.BLACK)
rod("PTO shaft",(0,2.07,.88),(0,2.17,.88),.066,v.METAL)
amber = v.material("Turn indicator amber",(.96,.26,.015),.08,.23)
for side in [-1,1]:
    rod("Lift rocker",(side*.30,1.64,1.40),(side*.44,1.98,1.38),.072,v.DARK)
    rod("Lift rod sleeve",(side*.44,1.98,1.38),(side*.48,2.00,.97),.064,v.BLACK)
    rod("Lower lift rod",(side*.48,2.00,.97),(side*.49,2.02,.65),.035,v.METAL)
    # Sweep a forged U-section around the implement pin seat, open at the top.
    hook_sections = []
    for step in range(25):
        angle = radians(-118+step*236/24)
        outer_radius = .136-.034*(abs(step-12)/12)**3
        hook_sections.append([(side*.55+dx,2.36+radius*sin(angle),.60-radius*cos(angle))
                              for dx,radius in [(-.052,.070),(-.052,outer_radius),
                                                (.052,outer_radius),(.052,.070)]])
    v.profile_loft("Open lower link hook",hook_sections,v.DARK,root)
    for height,cap in [(1.28,red),(1.11,amber)]:
        rod("Hydraulic socket",(side*.29,1.89,height),(side*.29,1.99,height),.058,v.METAL)
        rod("Coupling dust cap",(side*.29,1.99,height),(side*.29,2.02,height),.043,cap)
    # Feed the lift cylinder from the valve block, leaving slack below the pivot.
    hose_points = [(side*.27,1.94,1.35),(side*.32,2.05,1.35),
                   (side*.36,2.10,1.20),(side*.37,2.11,1.03),
                   (side*.41,2.10,.98),(side*.46,2.04,1.01)]
    hose_curve = bpy.data.curves.new("Rear hydraulic feed", "CURVE")
    hose_curve.dimensions = "3D"
    hose_curve.resolution_u = 5
    hose_curve.bevel_depth = .018
    hose_curve.bevel_resolution = 2
    spline = hose_curve.splines.new("BEZIER")
    spline.bezier_points.add(len(hose_points)-1)
    for point, position in zip(spline.bezier_points,hose_points):
        point.co = position
        point.handle_left_type = point.handle_right_type = "AUTO"
    hose = bpy.data.objects.new("Lift cylinder hose",hose_curve)
    bpy.context.collection.objects.link(hose)
    hose.parent = root
    hose_curve.materials.append(v.RUBBER)
    for tip, neighbour in [(0,1),(-1,-2)]:
        end = Vector(hose_points[tip])
        rod("Crimped hose ferrule",end,end+(Vector(hose_points[neighbour])-end).normalized()*.042,.026,v.METAL)
    bpy.ops.object.select_all(action="DESELECT")
    hose.select_set(True)
    bpy.context.view_layer.objects.active = hose
    bpy.ops.object.convert(target="MESH")
    # Four flush lenses follow the transverse crown of the wing.
    angle = radians(49)
    normal = Vector((0,sin(angle),cos(angle)))
    for offset,rise,lens in [(-.16,.138,v.TAIL_LAMP),(-.05,.126,v.TAIL_LAMP),
                             (.06,.117,v.TAIL_LAMP),(.17,.110,amber)]:
        radius = .93 + rise
        center = Vector((side*(1.02+offset),1.03+radius*sin(angle),.93+radius*cos(angle)))
        rod("Inset rear lamp seal",center-normal*.016,center+normal*.012,.047,v.BLACK,24)
        rod("Fender signal optic",center+normal*.011,center+normal*.022,.034,lens,24)
# A narrow pipe passes through the heat shield and bends away from the cab.
exhaust_profile = [(1.34,-.51,.061),(1.55,-.51,.061),(1.58,-.51,.095),
                   (2.62,-.51,.095),(2.67,-.51,.064),(2.79,-.51,.064),
                   (2.88,-.55,.064),(2.95,-.60,.061)]
exhaust_rings = []
for height,center_y,radius in exhaust_profile:
    exhaust_rings.append([(.69+radius*cos(tau*i/24),center_y+radius*sin(tau*i/24),height)
                          for i in range(24)])
v.profile_loft("Exhaust pipe and heat shield",exhaust_rings,v.DARK,root,close_ends=False)
mouth = [[(.69+radius*cos(tau*i/24),center_y+radius*sin(tau*i/24),height)
          for i in range(24)] for height,center_y,radius in
         [(2.95,-.60,.061),(2.95,-.60,.051),(2.88,-.55,.051)]]
v.profile_loft("Exhaust outlet lip and bore",mouth,v.BLACK,root,close_ends=False)
v.cylinder("Beacon rubber foot",(.62,1.16,3.318),.103,.05,v.RUBBER,False,24,root)
v.cylinder("Beacon retaining collar",(.62,1.16,3.351),.093,.028,v.BLACK,False,24,root)
beacon_lens = v.material("Amber beacon lens",(.98,.145,.006),.06,.18)
lens_profile = [(3.362,.083),(3.374,.088),(3.390,.084),(3.465,.080),
                (3.482,.076),(3.494,.060),(3.499,.022)]
# Stacked prisms cast alternating highlights around the amber lens.
for rib in range(5):
    base = 3.393 + rib * .013
    radius = .084 - (base - 3.390) * .053
    lens_profile.extend([(base,radius), (base+.004,radius+.0035), (base+.007,radius)])
lens_profile.sort()
lens_rings = [[(.62+radius*cos(tau*i/32),1.16+radius*sin(tau*i/32),height)
               for i in range(32)] for height,radius in lens_profile]
v.profile_loft("Amber beacon dome",lens_rings,beacon_lens,root)
# Lower the roofline above the seat, keeping glazing, mirrors and pillars aligned.
bpy.context.view_layer.update()
for part in root.children:
    if part.type != "MESH":
        continue
    world = part.matrix_world
    inverse = world.inverted()
    for vertex in part.data.vertices:
        point = world @ vertex.co
        if point.z > 2.35:
            point.z -= min((point.z - 2.35) * .34, .27)
            vertex.co = inverse @ point
save("FarmTractor","farm_tractor.glb","Tractor body","Glazed operator cab")
