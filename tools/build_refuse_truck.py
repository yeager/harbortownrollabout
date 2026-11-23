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

box("Ladder chassis", (0,0,.82), (1.60,7.4,.32), v.DARK)
box("Cab shell", (0,-2.90,2.04), (2.34,1.98,2.20), green,.17)
glass = box("Panoramic windshield",(0,-3.87,2.57),(2.05,.12,.88),v.GLASS,.08)
glass.rotation_euler.x = -.09
box("Sun visor",(0,-3.92,3.06),(2.29,.24,.12),v.DARK)
box("Front bumper",(0,-3.90,.82),(2.34,.28,.37),v.DARK,.08)
for i in range(4):
    box("Radiator louvre",(0,-3.91,1.20+i*.09),(1.28,.055,.045),v.BLACK)
v.mesh_from_rings("Compactor body", [
    (-1.78,1.20,1.22,3.25,3.5),(-1.59,1.24,1.18,3.37,3.58),
    (2.37,1.24,1.18,3.37,3.58),(2.65,1.18,1.23,3.26,3.46)],green,root)
box("Rear hopper floor",(0,2.97,1.12),(2.26,.96,.16),v.DARK)
box("Loading comb",(0,3.55,1.18),(1.84,.14,.16),v.METAL)
for side in (-1,1):
    box("Door window",(side*1.155,-2.94,2.58),(.085,1.55,.84),v.GLASS,.075)
    box("Mirror arm",(side*1.27,-3.49,2.66),(.32,.075,.073),v.DARK)
    box("Twin mirror",(side*1.43,-3.48,2.51),(.16,.19,.43),v.BLACK)
    box("Cab step",(side*1.04,-2.77,.64),(.38,.85,.11),v.METAL)
    box("Headlight lens",(side*.90,-3.99,1.02),(.35,.08,.17),v.HEADLAMP)
    box("Roof beacon",(side*.82,-2.74,3.20),(.19,.23,.17),amber)
    box("Reflective tape",(side*1.244,.33,1.43),(.018,4.22,.075),v.PAINT_YELLOW)
    v.text_obj("Fleet marking","ECO  24",(side*1.25,.24,2.41),.42,v.PAINT_WHITE,side=-side,root=root,flat=True)
    cheek=box("Hopper cheek",(side*1.06,2.95,2.19),(.23,1.04,2.24),green,.10)
    cheek.rotation_euler.x=.20
    ram("Lift cylinder",(side*1.20,2.47,3.13),(side*1.20,3.01,2.03),.074,v.DARK)
    ram("Chrome piston",(side*1.20,3.01,2.03),(side*1.20,3.36,1.31),.042,v.METAL)
    box("Crew footboard",(side*.87,3.59,.67),(.53,.44,.12),v.METAL)
    box("Rear light",(side*1.12,3.46,1.46),(.14,.09,.31),v.TAIL_LAMP)
    for y in (-2.94,.90,2.28):
        for name,x,r,d,mat in [('Performance tire',1.00,.55,.39,v.RUBBER),('Wheel rim',1.18,.353,.10,v.METAL),('Wheel hub',1.237,.158,.08,v.DARK)]:
            v.cylinder(name,(side*x,y,.55),r,d,mat,True,32,root)
        for j in range(8):
            a=j*math.tau/8
            v.cylinder("Wheel bolt",(side*1.24,y+.25*math.cos(a),.55+.25*math.sin(a)),.031,.04,v.DARK,True,6,root)
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
