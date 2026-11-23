"""Build smooth garment and face profiles in metres with Blender."""
import bpy
import math
from pathlib import Path

root = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)

def sculpt(name, sections):
    vertices, faces = [], []
    sides = 32
    for height, width, depth, forward in sections:
        for i in range(sides):
            angle = math.tau * i / sides
            vertices.append((width * math.cos(angle), forward + depth * math.sin(angle), height))
    for j in range(len(sections) - 1):
        for i in range(sides):
            a = j * sides + i
            b = j * sides + (i + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    faces.extend([tuple(reversed(range(sides))), tuple(range(len(vertices)-sides, len(vertices)))])
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    for face in mesh.polygons:
        face.use_smooth = True
    if name == "Trainer":
        for label in ("Outsole", "Canvas"):
            mesh.materials.append(bpy.data.materials.new(label))
        for face in mesh.polygons:
            face.material_index = int(face.center.z > -.032)
    smooth = obj.modifiers.new("Tailored contours", 'SUBSURF')
    smooth.levels = 2
    bpy.ops.wm.obj_export(filepath=str(root / 'characters' / (name + '.obj')),
                          export_selected_objects=True, export_materials=(name == "Trainer"))

sculpt("Jacket", [(-.36,.167,.119,0),(-.35,.184,.128,0),(-.31,.189,.132,0),
                  (-.18,.167,.125,0),(.03,.19,.135,.008),(.19,.216,.138,0),
                  (.248,.220,.116,-.004),(.277,.204,.112,0),(.300,.163,.105,0),(.329,.090,.085,0)])
# Cuff, Achilles, calf, knee and thigh. The calf sits behind the shin;
# the kneecap breaks the forward silhouette at the gait rig's knee pivot.
sculpt("Trouser", [(-.38,.060,.066,0),(-.354,.067,.072,.002),
                   (-.30,.056,.063,-.008),(-.23,.064,.075,-.017),
                   (-.158,.083,.095,-.024),(-.095,.079,.084,-.016),
                   (-.054,.066,.069,-.003),(-.018,.072,.077,.013),
                   (.014,.076,.084,.019),(.060,.080,.086,.011),
                   (.16,.094,.105,.008),(.264,.105,.116,.002),
                   (.334,.105,.114,-.006),(.37,.090,.099,-.006)])
sculpt("Sleeve", [(-0.3546875,.044,.049,.025),(-0.3263125,.054,.057,.024),(-0.2695625,.053,.056,.023),
                  (-0.1135,.064,.064,.011),(0.0070938,.061,.073,-.01),(.199,.072,.078,0),
                  (.280,.073,.082,0),(.315,.065,.076,0),(.339,.044,.060,0),(.350,.022,.038,0)])
sculpt("Trainer", [(-.054,.069,.129,.035),(-.049,.079,.141,.035),
                  (-.032,.080,.143,.035),(-.020,.078,.142,.036),
                  (.006,.072,.115,.017),(.018,.069,.100,.004),
                  (.042,.064,.083,-.010),(.065,.056,.069,-.012)])
import runpy
build_portrait = runpy.run_path(str(root / 'tools' / 'build_portrait.py'))['build_portrait']
build_portrait(root)
build_portrait(root, alma=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'source_blender' / 'Characters.blend'))
