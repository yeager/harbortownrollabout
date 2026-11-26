"""Build the three-axle rear loader and its vehicle-selection portrait."""
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector

project = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(project / "tools"))
import build_vehicles as v

v.clear_scene()
root = bpy.data.objects.new("Harbor sanitation", None)
bpy.context.collection.objects.link(root)
green = v.material("Leaf green enamel", (.035, .38, .105), .35, .29)
amber = v.material("Amber lens", (1, .35, .015), .12, .25, .3)

def box(name, pos, dims, finish, radius=.035):
    return v.cube(name, pos, dims, finish, radius, root)

def ram(name, start, end, radius, finish):
    axis = Vector(end) - Vector(start)
    rod = v.cylinder(name, (Vector(end) + Vector(start))/2, radius, axis.length, finish, False, 16, root)
    rod.rotation_euler = axis.to_track_quat('Z', 'Y').to_euler()

def wheel_surface(name, side, y, profile, finish):
    segments = 64
    vertices = []
    for offset, radius in profile:
        for step in range(segments):
            angle = math.tau * step / segments
            vertices.append((side * offset, radius * math.cos(angle), radius * math.sin(angle)))
    faces = []
    for ring in range(len(profile)):
        following = (ring + 1) % len(profile)
        for step in range(segments):
            neighbor = (step + 1) % segments
            face = (ring * segments + step, ring * segments + neighbor,
                    following * segments + neighbor, following * segments + step)
            faces.append(face if side > 0 else face[::-1])
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    mesh.materials.append(finish)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    wheel = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(wheel)
    wheel.parent = root
    wheel.location = (side, y, .55)


def rear_mudguard(side, axle_y):
    sections = 24
    profile = [(.77,.608),(.79,.632),(1.219,.632),(1.249,.611),
               (1.249,.586),(1.221,.603),(.79,.603),(.77,.588)]
    vertices = []
    for step in range(sections + 1):
        angle = math.radians(-78 + 156 * step / sections)
        for x, radius in profile:
            vertices.append((side*x, axle_y + radius*math.sin(angle),
                             .55 + radius*math.cos(angle)))
    width = len(profile)
    faces = [tuple(reversed(range(width)))]
    for section in range(sections):
        for corner in range(width):
            neighbor = (corner + 1) % width
            first = section * width
            faces.append((first + corner, first + neighbor,
                          first + width + neighbor, first + width + corner))
    faces.append(tuple(range(sections * width, len(vertices))))
    if side < 0:
        faces = [face[::-1] for face in faces]
    mesh = bpy.data.meshes.new("Rear mudguard")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    mesh.materials.append(v.DARK)
    for face in mesh.polygons[1:-1]:
        face.use_smooth = True
    guard = bpy.data.objects.new("Rear mudguard", mesh)
    bpy.context.collection.objects.link(guard)
    guard.parent = root
    for end in (-1, 1):
        ram("Mudguard support",(side*.77,axle_y+end*.39,.98),
            (side*1.18,axle_y+end*.39,1.018),.022,v.DARK)
    box("Mud flap carrier",(side*1.004,axle_y+.621,.654),(.471,.082,.076),v.DARK,.012)
    box("Rear rubber mud flap",(side*1.004,axle_y+.632,.483),(.446,.039,.339),v.RUBBER,.014)
    box("Mud flap retaining strip",(side*1.004,axle_y+.656,.625),(.436,.017,.045),v.METAL,.007)
    for x in (.83,1.004,1.178):
        rivet = v.cylinder("Mud flap fastener",(side*x,axle_y+.669,.625),
                           .009,.010,v.DARK,False,12,root)
        rivet.rotation_euler.x = math.pi/2


tire_profile = [
    (-.195,.350),(-.195,.454),(-.182,.503),(-.162,.537),(-.132,.550),
    (-.087,.550),(-.084,.537),(-.069,.537),(-.066,.550),
    (-.012,.550),(-.009,.537),(.009,.537),(.012,.550),
    (.066,.550),(.069,.537),(.084,.537),(.087,.550),
    (.132,.550),(.162,.537),(.182,.503),(.195,.454),(.195,.350),
]
rim_profile = [
    (.161,.348),(.175,.361),(.200,.361),(.212,.349),(.210,.331),
    (.175,.300),(.170,.249),(.204,.196),(.212,.138),(.161,.138),
]

box("Ladder chassis", (0,0,.82), (1.60,7.4,.32), v.DARK)
box("Cab shell", (0,-2.90,2.04), (2.34,1.98,2.20), green,.17)
gasket = box("Windshield gasket",(0,-3.862,2.57),(2.116,.123,.946),v.RUBBER,.088)
gasket.rotation_euler.x = -.09
glass = box("Panoramic windshield",(0,-3.87,2.57),(2.05,.12,.88),v.GLASS,.08)
glass.rotation_euler.x = -.09
for pivot_x in (-.82,.14):
    pivot = v.cylinder("Windshield wiper spindle",(pivot_x,-3.961,2.141),
                       .036,.055,v.DARK,False,20,root)
    pivot.rotation_euler.x = math.pi/2
    elbow = (pivot_x+.30,-4.005,2.205)
    blade_center = (pivot_x+.415,-4.004,2.257)
    ram("Windshield wiper arm",(pivot_x,-3.995,2.141),elbow,.015,v.DARK)
    ram("Windshield wiper arm tip",elbow,blade_center,.009,v.DARK)
    ram("Windshield wiper blade",(pivot_x+.072,-3.986,2.225),
        (pivot_x+.758,-3.981,2.289),.014,v.RUBBER)
    ram("Windshield blade spine",(pivot_x+.108,-4.002,2.228),
        (pivot_x+.722,-3.997,2.286),.007,v.DARK)
box("Sun visor",(0,-3.92,3.06),(2.29,.24,.12),v.DARK)
box("Front bumper",(0,-3.90,.82),(2.34,.28,.37),v.DARK,.08)
box("Grille recess",(0,-3.908,1.39),(1.42,.045,.43),v.BLACK,.034)
for z in (1.165,1.615):
    box("Grille horizontal surround",(0,-3.939,z),(1.46,.101,.044),v.DARK,.012)
for side in (-1,1):
    box("Grille end surround",(side*.711,-3.939,1.39),(.045,.101,.438),v.DARK,.012)
    box("Grille louvre support",(side*.39,-3.943,1.39),(.038,.041,.392),v.DARK,.006)
for row in range(6):
    z = 1.224 + row*.066
    louvre = box("Radiator louvre",(0,-3.958,z),(1.37,.071,.029),v.DARK,.006)
    louvre.rotation_euler.x = math.radians(-19)
v.mesh_from_rings("Compactor body", [
    (-1.78,1.20,1.22,3.25,3.5),(-1.59,1.24,1.18,3.37,3.58),
    (2.37,1.24,1.18,3.37,3.58),(2.65,1.18,1.23,3.26,3.46)],green,root)
box("Rear hopper floor",(0,2.97,1.12),(2.26,.96,.16),v.DARK)
box("Loading comb carrier",(0,3.54,1.177),(1.84,.16,.125),v.DARK,.017)
box("Loading comb mounting rail",(0,3.623,1.163),(1.74,.053,.091),v.METAL,.012)
for tooth in range(16):
    x = (tooth - 7.5) * .105
    tine = box("Loading comb tooth",(x,3.657,1.226),(.065,.115,.091),v.METAL,.012)
    tine.rotation_euler.x = math.radians(17)
for side in (-1,1):
    box("Loading comb end bracket",(side*.913,3.548,1.168),(.092,.206,.172),green,.017)
    v.cylinder("Loading comb bracket pin",(side*.968,3.561,1.16),
                     .041,.025,v.METAL,True,20,root)
for side in (-1,1):
    box("Door window gasket",(side*1.173,-2.94,2.58),(.030,1.588,.880),v.RUBBER,.040)
    box("Door window",(side*1.155,-2.94,2.58),(.085,1.55,.84),v.GLASS,.075)
    door_outline = [(-3.71,2.77),(-3.64,3.047),(-2.22,3.047),
                    (-2.10,2.94),(-2.10,1.145),(-2.19,1.072),
                    (-3.58,1.072),(-3.71,1.215),(-3.71,2.77)]
    for start, end in zip(door_outline,door_outline[1:]):
        ram("Cab door shut line",(side*1.171,*start),(side*1.171,*end),.006,v.DARK)
    box("Mirror mounting foot",(side*1.17,-3.49,2.66),(.075,.145,.116),v.RUBBER,.016)
    ram("Mirror arm",(side*1.18,-3.49,2.66),(side*1.43,-3.53,2.62),.034,v.DARK)
    ram("Mirror carrier",(side*1.43,-3.53,2.66),(side*1.43,-3.53,2.31),.022,v.DARK)
    for label, height, depth, size in (
            ("Main",2.60,-3.50,.258),("Wide angle",2.382,-3.483,.136)):
        box(label+" mirror shell",(side*1.43,depth,height),(.175,.114,size),v.BLACK,.025)
        box(label+" mirror glass",(side*1.43,depth+.057,height),
            (.144,.014,size-.032),v.METAL,.014)
    for height, step_x, width in ((.64,1.04,.38),(.91,1.10,.29)):
        box("Cab step",(side*step_x,-2.17,height),(width,.40,.087),v.METAL,.016)
        for stripe in (-.135,-.045,.045,.135):
            box("Step grip rib",(side*step_x,-2.17+stripe,height+.048),
                (width-.06,.029,.015),v.DARK,.005)
    for y in (-2.33,-2.01):
        box("Step support",(side*.96,y,.775),(.20,.052,.25),v.DARK,.008)
    for z in (1.26,1.78):
        ram("Cab grab rail mount",(side*1.16,-2.51,z),(side*1.208,-2.51,z),.018,v.DARK)
    ram("Cab grab rail",(side*1.208,-2.51,1.26),(side*1.208,-2.51,1.78),.019,v.METAL)
    box("Door handle recess",(side*1.176,-2.25,1.88),(.018,.203,.082),v.DARK,.012)
    box("Door pull",(side*1.196,-2.25,1.888),(.036,.153,.030),v.METAL,.009)
    box("Front lamp carrier",(side*.89,-3.958,1.052),(.468,.156,.202),green,.030)
    box("Front lamp bezel",(side*.89,-4.034,1.052),(.444,.038,.175),v.BLACK,.016)
    box("Headlight lens",(side*.815,-4.055,1.052),(.255,.024,.126),v.HEADLAMP,.012)
    box("Front amber indicator",(side*1.023,-4.055,1.052),(.110,.024,.126),amber,.009)
    box("Roof beacon",(side*.82,-2.74,3.20),(.19,.23,.17),amber)
    box("Reflective tape",(side*1.244,.33,1.43),(.018,4.22,.075),v.PAINT_YELLOW)
    v.text_obj("Fleet marking","ECO  24",(side*1.25,.24,2.41),.42,v.PAINT_WHITE,side=-side,root=root,flat=True)
    cheek=box("Hopper cheek",(side*1.06,2.95,2.19),(.23,1.04,2.24),green,.10)
    cheek.rotation_euler.x=.20
    ram("Lift cylinder",(side*1.20,2.47,3.13),(side*1.20,3.01,2.03),.074,v.DARK)
    ram("Chrome piston",(side*1.20,3.01,2.03),(side*1.20,3.36,1.31),.042,v.METAL)
    box("Crew footboard",(side*.87,3.59,.67),(.53,.44,.105),v.METAL,.018)
    for offset in (-.145,-.052,.052,.145):
        box("Footboard grip rib",(side*.87,3.59+offset,.726),(.44,.028,.019),v.DARK,.005)
    for x in (.69,1.05):
        ram("Footboard brace",(side*x,3.25,.78),(side*x,3.71,.625),.027,v.DARK)
    for z in (1.79,2.29):
        ram("Rear grab handle mount",(side*1.163,3.32,z),(side*1.30,3.38,z),.026,v.DARK)
    ram("Rear grab handle",(side*1.30,3.38,1.79),(side*1.30,3.38,2.29),.024,v.METAL)
    light_x = side*1.12
    box("Rear lamp mounting plate",(light_x,3.531,1.46),(.183,.213,.367),green,.018)
    box("Rear lamp gasket",(light_x,3.650,1.46),(.168,.052,.337),v.RUBBER,.015)
    box("Rear indicator lens",(light_x,3.680,1.545),(.120,.026,.104),amber,.009)
    box("Tail lamp",(light_x,3.680,1.418),(.120,.026,.135),v.TAIL_LAMP,.009)
    for z in (1.310,1.612):
        screw = v.cylinder("Rear lamp retaining screw",(light_x,3.679,z),
                           .008,.012,v.METAL,False,12,root)
        screw.rotation_euler.x = math.pi/2
    for axle_y in (.90,2.28):
        rear_mudguard(side, axle_y)
    for y in (-2.94,.90,2.28):
        wheel_surface("Performance tire",side,y,tire_profile,v.RUBBER)
        wheel_surface("Alloy wheel dish",side,y,rim_profile,v.METAL)
        v.cylinder("Wheel hub",(side*1.206,y,.55),.151,.081,v.DARK,True,32,root)
        v.cylinder("Wheel hub cover",(side*1.249,y,.55),.103,.020,v.METAL,True,32,root)
        for j in range(8):
            a = j * math.tau / 8
            bolt_y, bolt_z = y + .222*math.cos(a), .55 + .222*math.sin(a)
            v.cylinder("Wheel bolt washer",(side*1.193,bolt_y,bolt_z),.040,.026,v.DARK,True,16,root)
            v.cylinder("Wheel bolt",(side*1.214,bolt_y,bolt_z),.027,.033,v.METAL,True,6,root)
v.export_vehicle(root,"refuse_truck.glb")
if os.getenv("TRUCK_PORTRAIT"):
    scene=bpy.context.scene
    scene.render.engine='BLENDER_WORKBENCH'
    scene.display.shading.color_type='MATERIAL'
    scene.display.shading.show_shadows=True
    scene.display.shading.show_cavity=True
    scene.render.film_transparent=True
    bpy.ops.object.camera_add(location=(8,-10,5.8))
    camera=bpy.context.object
    camera.rotation_euler=(Vector((0,0,1.65))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'
    camera.data.ortho_scale=11
    scene.camera=camera
    scene.render.resolution_x=768
    scene.render.resolution_y=384
    scene.render.resolution_percentage=100
    scene.render.filepath=os.environ['TRUCK_PORTRAIT']
    bpy.ops.render.render(write_still=True)
