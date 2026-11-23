"""Build the parked burger van and agricultural tractor for the west district."""
from math import cos, sin, pi, radians, tau
from pathlib import Path
import sys
import bpy
from mathutils import Vector, Matrix
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
                  and not part.name.startswith((separate_glass, "All terrain tire", "Projector lens"))]
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
v.mesh_from_rings("Delivery cab", [(-3.18,.84,.54,1.06,1.13),(-2.91,.99,.55,1.24,1.31),
    (-2.25,1,.56,1.43,1.53),(-1.54,1,.59,2.29,2.43),(-.77,1,.60,2.31,2.45)],charcoal,root)
# Cross-sections follow the crown of the scuttle and narrow toward the roof.
windshield = []
for y, width, crown in [(-2.225,.851,1.61),(-2.17,.86,1.68),(-1.61,.79,2.39),(-1.58,.75,2.42)]:
    row = [(-width,y+.052,crown-.033),(-width*.62,y+.009,crown),
           (0,y,crown+.013),(width*.62,y+.009,crown),(width,y+.052,crown-.033)]
    windshield.append(row + [(x,sy+.015,z-.012) for x,sy,z in reversed(row)])
v.profile_loft("Swept laminated windscreen",windshield,v.GLASS,root)
for x in [-.39,.36]:
    rod("Wiper blade",(x-.28,-2.206,1.646),(x+.26,-2.169,1.69),.013,v.BLACK)
    rod("Wiper arm",(x+.17,-2.242,1.595),(x,-2.184,1.67),.012,v.DARK)
for s in [-1,1]:
    box("Cab side glass",(s*.987,-1.26,1.88),(.035,.88,.71),v.GLASS,.09)
    box("Mirror stalk",(s*1.08,-1.6,1.67),(.27,.055,.05),v.DARK)
    box("Mirror",(s*1.22,-1.60,1.75),(.13,.19,.28),charcoal)
    lamp_rows = []
    for x,y,z,h in [(.53,-3.184,1.036,.041),(.71,-3.173,1.065,.068),
                    (.84,-3.100,1.105,.071),(.92,-2.985,1.133,.037)]:
        lamp_rows.append([(s*x,y,z-h),(s*x,y,z+h),(s*x,y+.038,z+h),(s*x,y+.038,z-h)])
    v.profile_loft("Swept headlamp reflector",lamp_rows,v.METAL,root)
    rod("Daylight strip",(s*.55,-3.195,1.063),(s*.73,-3.183,1.107),.014,v.HEADLAMP)
    rod("Daylight return",(s*.73,-3.183,1.107),(s*.90,-3.012,1.153),.014,v.HEADLAMP)
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
box("Front bumper",(0,-3.18,.68),(1.86,.12,.22),v.DARK)
box("Grille",(0,-3.17,.94),(1.02,.06,.22),v.BLACK)
for z in [.875,.93,.985]:
    box("Radiator grille slat",(0,-3.211,z),(.92,.018,.014),v.METAL,.005)
box("Chassis rails",(0,.02,.55),(1.58,5.95,.27),v.DARK)
for side in [-1,1]:
    for front,rear in [(-.78,1.40),(2.36,3.16)]:
        box("Lower skirt",(side*1.06,(front+rear)/2,.66),(.105,rear-front,.36),charcoal)
    box("Wheel arch header",(side*1.06,1.88,.87),(.105,.97,.13),charcoal)
box("Kitchen plinth",(0,1.19,.99),(2.21,3.94,.38),charcoal)
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
for y,finish in [(.22,red),(.34,mustard)]:
    v.cylinder("Squeeze bottle",(1.17,y,1.397),.046,.23,finish,False,20,root)
    bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=.034,radius2=.009,depth=.086,location=(1.17,y,1.555))
    nozzle=bpy.context.object
    nozzle.name="Tapered sauce spout"
    nozzle.parent=root
    nozzle.data.materials.append(v.PAINT_WHITE)
for i in range(5):
    box("Takeaway carton",(1.16,2.14,1.305+i*.038),(.23,.29,.048),kraft,.015)
for y in [.56,.88,1.20]:
    box("Ingredient pan",(.89,y,1.45),(.24,.26,.085),v.METAL,.02)
    box("Pan contents",(.89,y,1.492),(.20,.22,.012),
        mustard if y==.56 else red if y==.88 else v.material("Leaf lettuce",(.13,.33,.06)))
for y in [.86,1.13,1.40,1.67]:
    patty=v.cylinder("Burger on grill",(-.54,y,1.69),.105,.056,v.material("Grilled beef",(.15,.058,.026)),False,18,root)
for y in [-.35,2.70]:
    box("Menu frame",(1.09,y,2.02),(.07,.61,1.32),v.METAL)
    box("Chalkboard",(1.14,y,2.02),(.04,.55,1.25),v.DARK)
    items = ["MENY","BURGARE","POMMES","LÄSK"] if y<0 else ["DAGENS","DUBBEL","MED OST","89 KR"]
    for n,word in enumerate(items):
        v.text_obj("Chalk lettering",word,(1.168,y-.23,2.42-.21*n),.09,v.PAINT_WHITE,side=-1,root=root,flat=True)
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
dusty_tread = v.material("Field-worn tread crowns", (.057,.055,.048), 0,.95)
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
    rod("Bright V badge",(0,-2.302,1.31),(side*.066,-2.302,1.394),.012,v.METAL)
    # The blade climbs across the nose, then turns back along the bonnet shoulder.
    lamp_path = [(.12,-2.286,1.277,1.301),(.21,-2.292,1.306,1.391),
                 (.32,-2.291,1.324,1.437),(.456,-2.274,1.369,1.461),
                 (.510,-2.228,1.402,1.480),(.554,-2.158,1.452,1.495)]
    reflector, light_guide = [], []
    for x,y,low,high in lamp_path:
        reflector.append([(side*x,y,low),(side*x,y,high),
                          (side*x,y+.026,high),(side*x,y+.026,low)])
        light_guide.append([(side*(x+.004),y-.006,high-.019),
                            (side*(x+.004),y-.006,high),
                            (side*x,y+.003,high),(side*x,y+.003,high-.019)])
    v.profile_loft("Wraparound headlamp housing",reflector,v.DARK,root)
    v.profile_loft("Upper running light",light_guide,v.HEADLAMP,root)
    rod("Projector bezel",(side*.32,-2.29,1.374),(side*.32,-2.309,1.374),.048,v.METAL)
    rod("Projector lens",(side*.32,-2.309,1.374),(side*.32,-2.322,1.374),.036,v.HEADLAMP)
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
box("Seat back",(0,1.01,2.23),(.55,.14,.54),cloth,.07).rotation_euler.x=-.10
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
            outline.append((x, .55+y, height+crown))
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
        rod("Cab pillar",(s*.73,y,1.54),(s*.75,y,3.18),.046,v.BLACK)
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
        for name, profile, material in [("Agricultural tyre",tyre_profile,v.RUBBER),
                                         ("Ivory wheel dish",rim_profile,v.PAINT_WHITE)]:
            rings = [[(x+s*w*offset,y+r*radius*sin(tau*j/48),r+r*radius*cos(tau*j/48))
                      for j in range(48)] for offset,radius in profile]
            if material == v.RUBBER:
                rings.append(rings[0])
            v.profile_loft(name,rings,material,root,close_ends=False)
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
                    (.015,.958,0), (.20,.95,.055), (.37,.94,.12),
                    (.49,.875,.185), (.53,.815,.202)
                ]:
                    for radius, half_angle in [(base_radius,-.052),(base_radius,.052),
                                               (base_radius+.064,.041),(base_radius+.064,-.041)]:
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
        tread_mesh.materials.append(v.RUBBER)
        tread_mesh.materials.append(dusty_tread)
        for face_index in contact_faces:
            tread_mesh.polygons[face_index].material_index = 1
        tread = bpy.data.objects.new("Chevron tread", tread_mesh)
        bpy.context.collection.objects.link(tread)
        tread.parent = root
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
        verts=[]
        faces=[]
        for i in range(33):
            angle=radians(-66+i*4)
            for j,(offset,rise) in enumerate(section):
                # The front lip sweeps back at its corners, exposing the tyre shoulder.
                lip = max(0,1-i/6) if y<0 else 0
                arc = angle + radians(lip*(9+8*abs(offset)))
                radius = r+rise-lip*.023
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
            face.material_index=int(face.index % (len(section)-1) >= 3)
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
    box("Fender lamp pedestal",(side*1.03,1.70,1.72),(.39,.18,.16),v.BLACK,.05)
    box("Rear stop lens",(side*.98,1.80,1.74),(.23,.04,.085),v.TAIL_LAMP)
    box("Rear indicator",(side*1.14,1.80,1.74),(.07,.04,.085),amber)
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
