"""Build a Swedish police helicopter with independently animated rotor hubs."""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene, cube, cylinder, material, pipe, export_vehicle, text_obj, SOURCE_DIR

clear_scene()
def pivot(name, parent=None, position=(0,0,0)):
    node=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(node)
    node.parent=parent
    node.location=position
    return node

root=pivot("Polishelikopter")
blue=material("Polis blue lacquer",(.025,.17,.46),.36,.27)
white=material("White enamel",(.86,.90,.92),.25,.32)
red=material("Signal red",(.78,.022,.018),.20,.31)
glass=material("Smoked canopy",(.021,.068,.102),.48,.14)
graphite=material("Graphite composite",(.036,.043,.049),.18,.38)
metal=material("Rotor hardware",(.32,.37,.4),.76,.28)

def shell(name, stations, paint):
    verts=[]
    faces=[]
    indices=[]
    sides=40
    for y,w,z,h in stations:
        for i in range(sides):
            a=math.tau*i/sides
            verts.append((w*math.cos(a),y,z+h*math.sin(a)))
    for j in range(len(stations)-1):
        for i in range(sides):
            k=(i+1)%sides
            faces.append((j*sides+i,(j+1)*sides+i,(j+1)*sides+k,j*sides+k))
            indices.append(paint(j,i,math.sin(math.tau*(i+.5)/sides)))
    faces.extend([tuple(range(sides)),tuple(reversed(range(len(verts)-sides,len(verts))))])
    indices.extend([0,0])
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    for m in [blue,white,glass,red]: mesh.materials.append(m)
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent=root
    for face,idx in zip(mesh.polygons,indices):
        face.material_index=idx
        face.use_smooth=True
    return obj

def cabin_paint(j,i,s):
    if j < 3 and s > .09:
        return 2
    if j<9 and .09<s<.91 and j not in (3,6) and i not in (9,10):
        return 2
    return 1 if -.53<s<.14 else 0

cabin = shell("Glazed passenger fuselage",[(-3.45,.07,1.39,.10),(-3.22,.59,1.39,.52),
      (-2.75,.95,1.48,.84),(-2.05,1.09,1.54,1.01),(-1.98,1.10,1.55,1.02),
      (-1.25,1.13,1.56,1.08),(-.79,1.14,1.56,1.09),(-.71,1.14,1.56,1.09),
      (.03,1.13,1.55,1.07),(.80,1.05,1.55,.97),(1.57,.81,1.57,.75),(2.3,.40,1.64,.38)],cabin_paint)
shell("Tapered tail boom",[(1.6,.55,1.69,.49),(2.7,.38,1.74,.36),
      (4.3,.22,1.9,.23),(4.80,.14,2.05,.15)],lambda j,i,s:0)


def cabin_surface(side, y, z, offset):
    hit, contact, _, _ = cabin.ray_cast((side * 2, y, z), (-side, 0, 0))
    if not hit:
        raise ValueError(f"Door detail misses fuselage at {(side, y, z)}")
    return (contact.x + side * offset, y, z)


def windscreen_surface(x, z, offset):
    hit, contact, _, _ = cabin.ray_cast((x, -4, z), (0, 1, 0))
    if not hit:
        raise ValueError(f"Detail misses windscreen at {(x, z)}")
    return (x, contact.y - offset, z)


pipe("Windscreen center mullion", [
    windscreen_surface(0, 1.49 + 1.02 * step / 40, .010)
    for step in range(41)
], .023, graphite, root)

landing_glass = material("Landing lamp glass", (.86, .93, 1.0), .12, .20, .65)
for side in [-1,1]:
    light_x = side * .39
    for name, offset, radius, depth, finish in (
        ("Landing lamp housing", .012, .122, .116, graphite),
        ("Landing lamp reflector", .069, .095, .037, metal),
        ("Landing lamp lens", .089, .075, .018, landing_glass),
    ):
        lamp = cylinder(name, windscreen_surface(light_x, .99, offset),
                        radius, depth, finish, False, 24, root)
        lamp.rotation_euler.x = 1.30
    pivot_point = windscreen_surface(side * .34, 1.49, .015)
    mount = cylinder("Windscreen wiper pivot", pivot_point, .043, .046, graphite, False, 20, root)
    mount.rotation_euler.x = math.pi / 2
    pipe("Windscreen wiper arm", [
        windscreen_surface(side * (.34 + .16 * step / 12), 1.49 + .40 * step / 12, .033)
        for step in range(13)
    ], .013, metal, root)
    pipe("Windscreen wiper blade", [
        windscreen_surface(side * (.45 + .12 * step / 12), 1.73 + .37 * step / 12, .018)
        for step in range(13)
    ], .020, graphite, root)
    text_obj("Police fuselage lettering","POLIS",(side*1.15,-side*.68,1.14),.40,blue,-side,root)
    for outline in (
        ((-2.01, 2.33), (-.78, 2.34), (-.78, .94), (-1.89, .94), (-2.01, 1.10)),
        ((-.68, 2.34), (.67, 2.25), (.75, 1.07), (.60, .94), (-.68, .94)),
    ):
        seam = [
            cabin_surface(side, y0 + (y1 - y0) * step / 16, z0 + (z1 - z0) * step / 16, .003)
            for (y0, z0), (y1, z1) in zip(outline, outline[1:] + outline[:1])
            for step in range(16)
        ]
        pipe("Cabin door seam", seam + seam[:1], .007, graphite, root)
    for handle_y in (-1.02, .48):
        cube("Recessed cabin handle surround", cabin_surface(side, handle_y, 1.55, .002),
             (.027, .235, .066), graphite, .013, root)
        cube("Cabin door pull", cabin_surface(side, handle_y, 1.55, .020),
             (.024, .164, .028), metal, .008, root)
    pipe("Tubular landing skid", [
        (side * 1.08, -2.46, .35), (side * 1.08, -2.30, .23),
        (side * 1.08, -2.13, .16), (side * 1.08, -1.94, .13),
        (side * 1.08, 1.45, .13), (side * 1.08, 1.64, .18),
    ], .057, graphite, root)
    for y in (-1.55, .78):
        pipe("Landing skid cross brace", [
            (side * .47, y, .81), (side * .71, y, .61),
            (side * .92, y, .38), (side * 1.08, y, .17),
        ], .054, blue, root)
        cube("Landing skid saddle", (side * 1.08, y, .173),
             (.147, .167, .075), metal, .023, root)
    cube("Cabin access step", (side * 1.08, -1.05, .195),
         (.237, .49, .044), metal, .018, root)
    cube("Cabin step grip", (side * 1.08, -1.05, .221),
         (.195, .43, .014), graphite, .006, root)
for z,y,dy,dz,finish in [(2.85,5.525,.82,.38,white),(3.09,5.57,.80,.16,red)]:
    fin=cube("Tail fin",(0,y,z),(.11,dy,dz),finish,.055,root)
    fin.rotation_euler.x=-.22
cube("Tailplane",(0,4.57,1.92),(2.22,.44,.072),white,.035,root)
for side, position, color in [
    (1, "Port", (.94, .018, .024)),
    (-1, "Starboard", (.025, .82, .20)),
]:
    lens = material(f"{position} navigation glass", color, .08, .28, 2.6)
    cube(f"{position} navigation lamp housing", (side * 1.09, 4.53, 1.92),
         (.14, .20, .092), graphite, .032, root)
    cube(f"{position} navigation lamp lens", (side * 1.165, 4.53, 1.92),
         (.046, .143, .066), lens, .021, root)
aft_lens = material("Aft navigation glass", (.92, .95, 1.0), .06, .26, 1.7)
cube("Aft navigation lamp housing", (0, 5.955, 3.035), (.134, .112, .082), graphite, .025, root)
cube("Aft navigation lamp lens", (0, 6.012, 3.035), (.094, .032, .055), aft_lens, .012, root)
cube("Turbine housing", (0, .09, 2.52), (1.25, 2.26, .53), blue, .24, root)
for side in (-1, 1):
    cube("Turbine intake recess", (side * .624, -.38, 2.54),
         (.045, .54, .20), graphite, .021, root)
    for index in range(6):
        louver = cube("Turbine intake louver", (side * .650, -.59 + index * .084, 2.54),
                      (.034, .033, .163), metal, .008, root)
        louver.rotation_euler.z = side * .32

    outlet_center = (side * .357, 1.208, 2.54)
    exhaust = cylinder("Turbine exhaust recess", outlet_center, .122, .089, graphite, False, 28, root)
    exhaust.rotation_euler.x = math.pi / 2
    bpy.ops.mesh.primitive_torus_add(
        location=(outlet_center[0], 1.255, outlet_center[2]), rotation=(math.pi / 2, 0, 0),
        major_radius=.117, minor_radius=.021, major_segments=32, minor_segments=10,
    )
    lip = bpy.context.object
    lip.name = "Turbine exhaust lip"
    lip.parent = root
    lip.data.materials.append(metal)
    for polygon in lip.data.polygons:
        polygon.use_smooth = True
cylinder("Mast",(0,-.27,2.99),.095,.47,metal,False,20,root)
main=pivot("MainRotor",root,(0,-.27,3.21))
tail=pivot("TailRotor",root,(0,5.35,2.05))
for name, height, radius, depth, finish in [
    ("Main rotor hub", 0, .29, .13, metal),
    ("Main rotor cap", .093, .19, .074, blue),
]:
    component = cylinder(name, (0, 0, height), radius, depth, finish, False, 32, main)
    component.matrix_parent_inverse.identity()
tail_hub = cylinder("Tail rotor hub", (0, 0, 0), .112, .15, metal, True, 24, tail)
tail_hub.matrix_parent_inverse.identity()
for hub,count,length in [(main,4,4.09),(tail,7,.50)]:
    for i in range(count):
        angle=math.tau*i/count
        if hub==main:
            blade=cube("Main blade",(0,0,0),(.19,length,.047),graphite,.02,hub)
            radial = Vector((-math.sin(angle), math.cos(angle), 0))
            blade.location = radial * (.35 + length / 2)
            blade.rotation_euler.z=angle
            cuff = cube("Main blade root cuff", (0, 0, 0), (.235, .39, .085), metal, .025, hub)
            cuff.location = radial * .365
            cuff.rotation_euler.z = angle
            cuff.matrix_parent_inverse.identity()
        else:
            blade=cube("Tail blade",(0,0,0),(.038,.08,length),graphite,.012,hub)
            blade.location=(0,-math.sin(angle)*length/2,math.cos(angle)*length/2)
            blade.rotation_euler.x=angle
        blade.matrix_parent_inverse.identity()
bpy.ops.mesh.primitive_torus_add(location=(0,5.35,2.05),rotation=(0,math.pi/2,0),
                                major_radius=.60,minor_radius=.085)
ring=bpy.context.object
ring.name="Shrouded tail rotor"
ring.parent=root
ring.scale.z = 1.8
ring.data.materials.append(blue)
for polygon in ring.data.polygons:
    polygon.use_smooth = True
cube("Tail gearbox support", (.124, 5.35, 2.05), (.067, 1.15, .077), blue, .025, root)
cylinder("Tail gearbox cover", (.16, 5.35, 2.05), .085, .041, blue, True, 24, root)
export_vehicle(root,"polishelikopter.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"Polishelikopter.blend"))
