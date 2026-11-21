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
    smooth = obj.modifiers.new("Tailored contours", 'SUBSURF')
    smooth.levels = 2
    bpy.ops.wm.obj_export(filepath=str(root / 'characters' / (name + '.obj')),
                          export_selected_objects=True, export_materials=False)

sculpt("Jacket", [(-.36,.167,.119,0),(-.35,.184,.128,0),(-.31,.189,.132,0),
                  (-.18,.167,.125,0),(.03,.19,.135,.008),(.19,.216,.138,0),
                  (.255,.226,.116,-.004),(.3,.157,.104,0),(.33,.085,.084,0)])
sculpt("Trouser", [(-.38,.066,.073,0),(-.35,.073,.078,.005),(-.26,.067,.075,-.013),
                   (-.16,.082,.09,-.018),(-.03,.072,.077,.008),(.025,.081,.09,.014),
                   (.16,.095,.11,0),(.29,.106,.113,0),(.37,.088,.093,0)])
sculpt("Sleeve", [(-.25,.044,.049,.025),(-.23,.054,.057,.024),(-.19,.053,.056,.023),
                  (-.08,.064,.064,.011),(.005,.061,.073,-.01),(.14,.077,.079,0),
                  (.215,.079,.084,0),(.265,.049,.058,0)])
sculpt("Trainer", [(-.054,.069,.129,.035),(-.049,.079,.141,.035),
                  (-.032,.080,.143,.035),(-.020,.078,.142,.036),
                  (.006,.074,.136,.035),(.018,.071,.123,.026),
                  (.042,.065,.095,.002),(.065,.056,.069,-.012)])
import runpy
runpy.run_path(str(root / 'tools' / 'build_portrait.py'))['build_portrait'](root)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'source_blender' / 'Characters.blend'))
