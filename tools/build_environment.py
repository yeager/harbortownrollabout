"""Build reusable Swedish town buildings and vegetation for Axels Utryckning."""
import bpy
import math
import os
import random
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "environment")
SOURCE = os.path.join(ROOT, "source_blender")
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)

def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

def mat(name, color, metallic=0, rough=0.65):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = next(node for node in m.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = rough
    return m

RED_WOOD = mat("Falun red painted timber", (0.43, 0.065, 0.038))
RED_DARK = mat("Deep red timber detail", (0.29, 0.035, 0.025))
CREAM = mat("Warm Swedish plaster", (0.82, 0.76, 0.62))
WHITE = mat("Warm white trim", (0.91, 0.89, 0.80))
BRICK = mat("Rust red brick", (0.42, 0.18, 0.12))
TILE = mat("Dark graphite roof tile", (0.11, 0.15, 0.17), 0.1)
COPPER = mat("Aged copper roof", (0.13, 0.29, 0.26), 0.6, 0.36)
GLASS = mat("Reflective blue window glass", (0.12, 0.28, 0.34), 0.23, 0.2)
GLASS_HI = mat("Window reflection", (0.48, 0.66, 0.68), 0.1, 0.24)
TEAL = mat("Clinic teal sign band", (0.03, 0.34, 0.38), 0.1)
MORTAR = mat("Stone foundation", (0.22, 0.25, 0.24))
WOOD = mat("Oiled oak", (0.36, 0.23, 0.12))
METAL = mat("Galvanized steel", (0.45, 0.52, 0.5), 0.68, 0.32)
GREEN = mat("Leaf green", (0.065, 0.17, 0.040), 0, 0.86)
GREEN_LIGHT = mat("Sunlit leaves", (0.16, 0.31, 0.062), 0, 0.84)
GREEN_DARK = mat("Deep leaves", (0.034, 0.095, 0.030), 0, 0.9)
BARK = mat("Natural bark", (0.24, 0.14, 0.075), 0, 0.88)
PINE = mat("Spruce needles", (0.030, 0.092, 0.053), 0, 0.9)
PINE_LIGHT = mat("Spruce tips", (0.056, 0.153, 0.079), 0, 0.9)
YELLOW = mat("Fire station warning yellow", (0.95, 0.63, 0.045), 0.08, 0.4)
RED = mat("Fire station rescue red", (0.68, 0.035, 0.025), 0.12, 0.34)
BIKE_FRAME = mat("Bicycle frame teal", (0.025, 0.28, 0.33), 0.28, 0.3)
BIKE_TIRE = mat("Bicycle tire rubber", (0.025, 0.03, 0.032), 0, 0.85)
RIDER_JACKET = mat("Cyclist high visibility jacket", (0.91, 0.36, 0.025), 0, 0.42)
RIDER_PANTS = mat("Cyclist dark trousers", (0.075, 0.12, 0.16), 0, 0.7)
HELMET = mat("Cyclist helmet", (0.88, 0.89, 0.86), 0.04, 0.36)
DARK = mat("Bicycle component graphite", (0.06, 0.08, 0.08), 0.1, 0.55)

def parent(obj, root):
    obj.parent = root
    obj.matrix_parent_inverse = root.matrix_world.inverted()
    return obj

def box(name, loc, dims, material, bevel=0.04, root=None, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    obj.rotation_euler = rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material:
        obj.data.materials.append(material)
    if bevel:
        b = obj.modifiers.new("Weather softened edges", "BEVEL")
        b.width = bevel
        b.segments = 3
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=b.name)
        n = obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
        bpy.ops.object.modifier_apply(modifier=n.name)
    if root:
        parent(obj, root)
    return obj

def cylinder(name, loc, radius, depth, material, root, vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    bevel = obj.modifiers.new("Rounded edge", "BEVEL")
    bevel.width = 0.035
    bevel.segments = 2
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    if root:
        parent(obj, root)
    return obj

def text(name, words, loc, size, material, root, side_front=True):
    curve = bpy.data.curves.new(name, "FONT")
    curve.body = words
    curve.size = size
    curve.extrude = 0.003
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = (math.pi / 2, 0, 0 if side_front else math.pi)
    obj.data.materials.append(material)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    parent(obj, root)
    return obj

def window(root, x, y, z, width=1.35, height=1.55):
    box("Window reveal", (x, y, z), (width + 0.18, 0.13, height + 0.18), WHITE, 0.035, root)
    box("Insulated glazing", (x, y - 0.075, z), (width, 0.055, height), GLASS, 0.035, root)
    box("Window mullion", (x, y - 0.12, z), (0.055, 0.035, height), WHITE, 0.014, root)
    box("Window transom", (x, y - 0.12, z), (width, 0.035, 0.055), WHITE, 0.014, root)
    box("Stone sill", (x, y - 0.11, z - height * 0.5 - 0.13), (width + 0.24, 0.17, 0.12), MORTAR, 0.025, root)
    box("Glass reflection", (x - width * 0.24, y - 0.15, z + height * 0.16), (0.045, 0.018, height * 0.58), GLASS_HI, 0.01, root)

def pitched_roof(root, width, depth, eaves, rise, roofmat):
    span = width * 0.5
    slope_len = math.sqrt(span * span + rise * rise)
    angle = math.atan2(rise, span)
    box("Left pitched roof", (-width * 0.25, 0, eaves + rise * 0.5), (slope_len + 0.25, depth + 0.55, 0.22), roofmat, 0.07, root, (0, -angle, 0))
    box("Right pitched roof", (width * 0.25, 0, eaves + rise * 0.5), (slope_len + 0.25, depth + 0.55, 0.22), roofmat, 0.07, root, (0, angle, 0))
    cylinder("Ridge cap", (0, 0, eaves + rise + 0.08), 0.12, depth + 0.63, roofmat, root, 12)

def build_bakery():
    root = bpy.data.objects.new("Town house | Bageriet", None)
    bpy.context.collection.objects.link(root)
    box("Stone foundation", (0, 0, 0.34), (13.0, 11.6, 0.68), MORTAR, 0.07, root)
    box("Timber house shell", (0, 0, 3.15), (12.7, 11.3, 5.7), RED_WOOD, 0.10, root)
    # Lower clapboard courses create readable siding in the sun.
    for z in [0.9 + i * 0.42 for i in range(11)]:
        box("Horizontal timber siding", (0, -5.7, z), (12.35, 0.045, 0.035), RED_DARK, 0.012, root)
    for x in (-6.18, 6.18):
        box("White corner board", (x, -5.73, 3.12), (0.19, 0.12, 5.4), WHITE, 0.025, root)
    for x in (-4.1, 0, 4.1):
        window(root, x, -5.79, 2.35, 1.65, 1.65)
        window(root, x, -5.79, 4.65, 1.45, 1.55)
    box("Bakery glazed door", (0, -5.9, 1.55), (1.3, 0.18, 2.5), WOOD, 0.06, root)
    box("Door glass", (0, -6.02, 1.85), (0.84, 0.05, 1.45), GLASS, 0.04, root)
    box("Bakery awning", (0, -6.25, 3.15), (4.0, 1.1, 0.22), RED_DARK, 0.05, root, (0.12, 0, 0))
    for x in (-1.6, -0.8, 0, 0.8, 1.6):
        box("Awning stripe", (x, -6.27, 3.29), (0.38, 0.97, 0.035), WHITE, 0.025, root)
    text("Bakery sign", "BAGERI  •  KAFFE", (-3.1, -6.0, 5.66), 0.52, WHITE, root)
    pitched_roof(root, 13.1, 11.9, 6.15, 2.15, TILE)
    box("Chimney stack", (4.2, 2.6, 8.1), (0.9, 1.0, 2.5), RED_WOOD, 0.07, root)
    box("Chimney cap", (4.2, 2.6, 9.4), (1.1, 1.2, 0.22), TILE, 0.04, root)
    return root

def build_clinic():
    root = bpy.data.objects.new("Civic building | Vårdcentralen", None)
    bpy.context.collection.objects.link(root)
    box("Foundation", (0, 0, 0.35), (13.8, 13.0, 0.7), MORTAR, 0.06, root)
    box("Clinic facade", (0, 0, 4.8), (13.5, 12.7, 8.9), CREAM, 0.12, root)
    for z in (1.25, 3.35, 5.75, 7.85):
        for x in (-4.7, -1.6, 1.6, 4.7):
            window(root, x, -6.42, z, 1.72, 1.35)
    box("Clinic teal band", (0, -6.47, 2.18), (13.0, 0.11, 0.36), TEAL, 0.025, root)
    box("Entrance canopy", (0, -7.05, 3.1), (4.8, 1.5, 0.25), TEAL, 0.06, root, (0.08, 0, 0))
    for x in (-1.6, 1.6):
        box("Canopy support", (x, -6.98, 1.65), (0.12, 0.12, 2.7), METAL, 0.025, root)
    text("Clinic sign", "VÅRDCENTRAL", (-3.5, -6.52, 8.4), 0.7, TEAL, root)
    box("Flat roof parapet", (0, 0, 9.45), (14.1, 13.3, 0.48), WHITE, 0.06, root)
    return root

def build_fire_station():
    root = bpy.data.objects.new("Fire station | Brandstationen", None)
    bpy.context.collection.objects.link(root)
    box("Station foundation", (0, 0, 0.36), (16.4, 14.0, 0.72), MORTAR, 0.06, root)
    box("Red brick fire station", (0, 0, 3.85), (16.0, 13.7, 6.4), RED, 0.09, root)
    for x in (-4.65, 0, 4.65):
        box("Garage door inset", (x, -6.92, 2.35), (4.05, 0.19, 3.65), MORTAR, 0.08, root)
        box("Roller door", (x, -7.06, 2.35), (3.62, 0.09, 3.22), WHITE, 0.045, root)
        for z in [0.9 + i * 0.28 for i in range(11)]:
            box("Roller door rib", (x, -7.12, z), (3.48, 0.035, 0.045), MORTAR, 0.012, root)
        for side_x in (x - 1.88, x + 1.88):
            box("Garage warning stripe", (side_x, -7.13, 2.35), (0.12, 0.04, 3.25), YELLOW, 0.02, root)
    text("Fire house sign", "RÄDDNINGSTJÄNSTEN", (-6.15, -7.04, 6.25), 0.58, WHITE, root)
    # Hose tower with louvered ventilation and a short aerial on the roof.
    box("Drying tower", (6.05, 2.7, 7.6), (3.8, 4.1, 8.2), RED_WOOD, 0.08, root)
    for z in (5.0, 6.7, 8.4, 10.1):
        box("Tower louver glass", (6.05, 0.58, z), (2.8, 0.09, 0.8), GLASS, 0.035, root)
        for x in [4.9 + i * 0.38 for i in range(7)]:
            box("Tower ventilation slat", (x, 0.51, z), (0.045, 0.05, 0.72), WHITE, 0.01, root)
    for x in (-6.3, -2.3, 2.3, 6.3):
        window(root, x, -6.97, 6.15, 1.35, 1.0)
    box("Station roof", (0, 0, 7.2), (16.4, 14.1, 0.45), TILE, 0.08, root)
    return root

def build_library():
    root = bpy.data.objects.new("Civic building | Stadsbiblioteket", None)
    bpy.context.collection.objects.link(root)
    box("Stone base", (0, 0, 0.34), (13.6, 13.0, 0.68), MORTAR, 0.06, root)
    box("Brick library", (0, 0, 3.15), (13.2, 12.7, 5.5), BRICK, 0.08, root)
    for x in (-4.9, -1.65, 1.65, 4.9):
        window(root, x, -6.43, 3.65, 2.2, 3.25)
    box("Library entry", (0, -6.52, 1.5), (1.65, 0.18, 2.45), WOOD, 0.06, root)
    box("Library entry glass", (0, -6.63, 1.75), (1.1, 0.05, 1.45), GLASS, 0.035, root)
    box("Reading room canopy", (0, -6.98, 3.05), (5.7, 1.25, 0.24), WOOD, 0.055, root)
    text("Library sign", "BIBLIOTEK", (-2.0, -6.55, 5.15), 0.58, WHITE, root)
    pitched_roof(root, 13.6, 13.0, 5.9, 1.6, COPPER)
    return root

def build_deciduous_tree(seed=9310, spread=1.0):
    root = bpy.data.objects.new("Tree | Deciduous", None)
    bpy.context.collection.objects.link(root)
    rng = random.Random(seed)
    vertices, faces, palette = [], [], []

    def branch(start, end, base, tip):
        axis = (end - start).normalized()
        u = axis.orthogonal().normalized()
        v = axis.cross(u)
        first = len(vertices)
        for centre, radius in [(start, base), (end, tip)]:
            for n in range(8):
                angle = n * math.tau / 8
                vertices.append(centre + radius * (u * math.cos(angle) + v * math.sin(angle)))
        for n in range(8):
            k = (n + 1) % 8
            faces.append((first+n, first+k, first+k+8, first+n+8))
            palette.append(0)

    branch(Vector((0,0,0)),Vector((0,0,5.4)),.19,.028)
    for i in range(26):
        angle = i * 2.39996 + rng.uniform(-.18,.18)
        direction = Vector((math.cos(angle), math.sin(angle), 0))
        origin = Vector((0,0,1.85 + .13*i))
        length = spread * (1.0-i/34) * rng.uniform(1.65,2.25)
        joint = origin + direction*length*.55 + Vector((0,0,.65))
        branch(origin, joint, .093*(1-i/35), .045)
        for fork in [-.6,0,.6]:
            radial = Vector((math.cos(angle+fork),math.sin(angle+fork),0))
            end = joint + radial*length*.59 + Vector((0,0,rng.uniform(.56,1.1)))
            branch(joint,end,.046,.009)
            for leaf in range(76):
                offset = Vector((rng.gauss(0,.32),rng.gauss(0,.32),rng.gauss(0,.30)))
                centre = joint.lerp(end,rng.uniform(.48,1.13)) + offset
                yaw = rng.uniform(0,math.tau)
                blade = Vector((math.cos(yaw),math.sin(yaw),rng.uniform(-.8,.8)))*rng.uniform(.09,.17)
                width = Vector((-blade.y,blade.x,.025))*.48
                first = len(vertices)
                vertices.extend((centre-blade,centre-blade*.32+width,centre+blade*.42+width*.85,
                                 centre+blade,centre+blade*.38-width*.78,centre-blade*.42-width,
                                 centre+Vector((0,0,.018))))
                tint = rng.choice((1,1,2,3)) if offset.z > 0 else rng.choice((1,2,2))
                for edge in range(6):
                    faces.append((first+6,first+(edge+1)%6,first+edge))
                    palette.append(tint)
    mesh = bpy.data.meshes.new("Förgrenad krona och blad")
    mesh.from_pydata(vertices,[],faces)
    for surface in [BARK,GREEN,GREEN_DARK,GREEN_LIGHT]:
        mesh.materials.append(surface)
    mesh.polygons.foreach_set("material_index",palette)
    tree = bpy.data.objects.new("Kajträd",mesh)
    bpy.context.collection.objects.link(tree)
    tree.parent = root
    return root

def build_pine():
    root = bpy.data.objects.new("Tree | Scandinavian spruce", None)
    bpy.context.collection.objects.link(root)
    rng = random.Random(654)
    cylinder("Avsmalnande granstam", (0,0,2.8), .115, 5.6, BARK, root, 12)
    vertices,faces,shades = [],[],[]
    up = Vector((0,0,1))
    def spray(a,b,span,shade):
        axis = b-a
        across = axis.cross(up).normalized()
        first = len(vertices)
        # Drooping, toothed sides give each shoot an irregular silhouette.
        for j in range(8):
            t = j/7
            mid = a+axis*t + up*(.07*math.sin(t*math.pi))
            spread = span*(.15+.85*math.sin(t*math.pi)**.7)
            edge = across*spread*(1.0 if j%2 else .68)
            vertices.extend((mid-edge-up*spread*.8, mid, mid+edge-up*spread*.9))
        for j in range(7):
            k = first+j*3
            faces.extend(((k,k+3,k+4,k+1),(k+1,k+4,k+5,k+2)))
            shades.extend((shade,shade))
    for level in range(19):
        h = .78+level*.30
        for n in range(8):
            angle = math.tau*n/8+level*2.4+rng.uniform(-.18,.18)
            along = Vector((math.cos(angle),math.sin(angle),0))
            side = along.cross(up)
            reach = (1.95*(1-level/20)**.80)*rng.uniform(.76,1.11)
            start = up*(h+rng.uniform(-.12,.12))
            def spine(t):
                return start+along*reach*t+up*reach*(.19*t-.34*math.sin(t*math.pi))
            spray(start,spine(.66),.12,0)
            spray(spine(.4),spine(1),.17,1)
            for j in range(1,9):
                t = j/10
                for sign in (-1,1):
                    width = reach*(.31*(1-t)+.07)*rng.uniform(.8,1.25)
                    tip = spine(t)+side*sign*width+along*(width*.68)-up*(width*.58)
                    spray(spine(t),tip,.055+.07*(1-t),int(rng.random()>.72))
    mesh=bpy.data.meshes.new("Granens hängande barrskott")
    mesh.from_pydata(vertices,[],faces)
    for finish in (PINE,PINE_LIGHT):
        mesh.materials.append(finish)
    mesh.polygons.foreach_set("material_index",shades)
    crown=bpy.data.objects.new("Oregelbundna grengrenar",mesh)
    bpy.context.collection.objects.link(crown)
    crown.parent=root
    return root

def tube_between(root, name, start, end, radius, material):
    a, b = Vector(start), Vector(end)
    direction = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=direction.length, location=(a + b) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("Tube edge", "BEVEL")
    bevel.width = radius * 0.3
    bevel.segments = 2
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return parent(obj, root)

def sphere(name, loc, scale, material, root):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    for face in obj.data.polygons: face.use_smooth = True
    return parent(obj, root)

def build_cyclist():
    root = bpy.data.objects.new("Cyclist | city commuter", None)
    bpy.context.collection.objects.link(root)
    rear = (0, 0.58, 0.48)
    front = (0, -0.58, 0.48)
    crank = (0, 0.02, 0.46)
    seat = (0, 0.25, 0.98)
    stem = (0, -0.34, 1.06)
    for y in (0.58, -0.58):
        bpy.ops.mesh.primitive_torus_add(major_segments=32, minor_segments=8, major_radius=0.45, minor_radius=0.045, location=(0, y, 0.48))
        wheel = bpy.context.object
        wheel.name = "Bicycle wheel"
        wheel.rotation_euler[1] = math.pi * 0.5
        wheel.data.materials.append(BIKE_TIRE)
        parent(wheel, root)
        cylinder("Wheel hub", (0, y, 0.48), 0.075, 0.12, METAL, root, 16)
        for angle in range(12):
            a = angle * math.tau / 12
            tube_between(root, "Bicycle spoke", (0, y, 0.48), (0, y + math.cos(a) * 0.405, 0.48 + math.sin(a) * 0.405), 0.008, METAL)
    tube_between(root, "Lower bicycle frame", rear, crank, 0.035, BIKE_FRAME)
    tube_between(root, "Seat stay", rear, seat, 0.03, BIKE_FRAME)
    tube_between(root, "Seat tube", seat, crank, 0.035, BIKE_FRAME)
    tube_between(root, "Top tube", seat, stem, 0.035, BIKE_FRAME)
    tube_between(root, "Down tube", crank, stem, 0.038, BIKE_FRAME)
    tube_between(root, "Front fork", front, stem, 0.03, METAL)
    tube_between(root, "Handlebar", (0, -0.38, 1.08), (0, -0.67, 1.08), 0.035, DARK)
    tube_between(root, "Seat post", seat, (0, 0.25, 1.12), 0.04, METAL)
    tube_between(root, "Saddle", (0, 0.13, 1.13), (0, 0.42, 1.13), 0.07, DARK)
    tube_between(root, "Pedal crank", (0, -0.08, 0.46), (0, 0.12, 0.46), 0.026, METAL)
    tube_between(root, "Pedal", (0, -0.17, 0.46), (0, -0.01, 0.46), 0.045, DARK)
    sphere("Cyclist torso", (0, 0.0, 1.37), (0.25, 0.34, 0.43), RIDER_JACKET, root)
    sphere("Cyclist head", (0, -0.31, 1.76), (0.2, 0.2, 0.22), CREAM, root)
    sphere("Cyclist helmet", (0, -0.3, 1.91), (0.24, 0.25, 0.13), HELMET, root)
    for side in (-1, 1):
        tube_between(root, "Cyclist upper arm", (side * 0.18, -0.14, 1.51), (side * 0.16, -0.33, 1.12), 0.09, RIDER_JACKET)
        tube_between(root, "Cyclist forearm", (side * 0.16, -0.33, 1.12), (side * 0.10, -0.57, 1.08), 0.065, RIDER_JACKET)
        sphere("Cyclist glove", (side * 0.1, -0.59, 1.08), (0.075, 0.07, 0.07), RIDER_PANTS, root)
        tube_between(root, "Cyclist thigh", (side * 0.12, 0.13, 1.13), (side * 0.12, -0.1, 0.67), 0.12, RIDER_PANTS)
        tube_between(root, "Cyclist lower leg", (side * 0.12, -0.1, 0.67), (side * 0.12, 0.05, 0.46), 0.08, RIDER_PANTS)
    return root

def export(root, path):
    bpy.ops.object.select_all(action="DESELECT")
    root.location = (0, 0, 0)
    root.select_set(True)
    for child in root.children_recursive: child.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True, export_materials="EXPORT")

def main():
    clear()
    assets = [
        (build_bakery(), "bageri.glb"),
        (build_clinic(), "vardcentral.glb"),
        (build_fire_station(), "brandstation.glb"),
        (build_library(), "bibliotek.glb"),
        (build_deciduous_tree(), "lovtrad.glb"),
        (build_deciduous_tree(158, 1.32), "bredkronigt_lovtrad.glb"),
        (build_pine(), "gran.glb"),
        (build_cyclist(), "cyklist.glb"),
    ]
    for root, filename in assets:
        export(root, os.path.join(OUT, filename))
    # Separate, clean overview layout for the editable source file.
    for i, (root, _filename) in enumerate(assets):
        root.location = ((i % 3) * 20, (i // 3) * 23, 0)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE, "Axels_Miljo.blend"))
    print("Created four detailed town buildings, two tree models and a cyclist.")

if __name__ == "__main__":
    main()
