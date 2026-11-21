"""Build the waterfront school in metres, with its entrance facing Blender +Y."""
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
materials = {}
vertices, faces, finishes = [], [], []


def finish(name, rgb, metal=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*rgb, 1)
    shader.inputs["Metallic"].default_value = metal
    materials[name] = mat


def loft(x, y, rings, material):
    start = len(vertices)
    for width, depth, z in rings:
        vertices.extend((x+a*width/2, y+b*depth/2, z)
                        for a,b in [(-1,-1),(1,-1),(1,1),(-1,1)])
    polygons = [(3,2,1,0)]
    for layer in range(len(rings)-1):
        for side in range(4):
            a = 4*layer + side
            b = 4*layer + (side+1)%4
            polygons.append((a,b,b+4,a+4))
    polygons.append(tuple(range(4*len(rings)-4,4*len(rings))))
    for polygon in polygons:
        faces.append(tuple(start+i for i in polygon))
        finishes.append(list(materials).index(material))


def box(x,y,z,w,d,h,material):
    loft(x,y,[(w,d,z),(w,d,z+h)],material)


finish("Apricot plaster",(.72,.46,.30))
finish("Limestone",(.57,.51,.42))
finish("Oxblood joinery",(.22,.055,.037))
finish("Blue window glass",(.10,.20,.25),.55)
finish("Verdigris copper",(.18,.47,.39),.45)
for x,w,d,h in [(0,14,7,6.6),(-9,4,6,5.0),(9,4,6,5.0),(-5,2.8,7.6,7),(5,2.8,7.6,7)]:
    box(x,0,0,w,d,.68,"Limestone")
    box(x,0,.68,w,d,h-.68,"Apricot plaster")
    box(x,0,h-.15,w+.16,d+.16,.18,"Limestone")
    loft(x,0,[(w+.42,d+.42,h),(w+.22,d+.22,h+.24),
              (w*.82,d*.76,h+.8),(max(.16,w-3),.32,h+1.8)],"Verdigris copper")
    for side in [-1,1]:
        for i in range(round(w/1.65)):
            wx=x+w*((i+.5)/round(w/1.65)-.5)
            for z in [1.18,3.57]:
                if z+1.3>h or (abs(wx)<.95 and z<2): continue
                wy=side*d/2
                box(wx,wy,z,.91,.12,1.45,"Oxblood joinery")
                box(wx,wy+side*.075,z+.09,.73,.045,1.27,"Blue window glass")
                box(wx,wy+side*.115,z+.1,.044,.035,1.25,"Oxblood joinery")
box(0,3.54,.14,1.65,.16,2.55,"Oxblood joinery")
for i in range(3):
    box(0,3.9+i*.3,0,2.45,.4,.3-i*.09,"Limestone")
mesh=bpy.data.meshes.new("School masonry and metalwork")
mesh.from_pydata(vertices,[],faces)
mesh.update()
obj=bpy.data.objects.new("Sjöstadsskolan",mesh)
bpy.context.collection.objects.link(obj)
for mat in materials.values(): mesh.materials.append(mat)
for poly,index in zip(mesh.polygons,finishes): poly.material_index=index
bpy.ops.wm.save_as_mainfile(filepath=str(root/"source_blender/Sjostadsskolan.blend"))
bpy.ops.export_scene.gltf(filepath=str(root/"environment/school.glb"),export_format="GLB")
