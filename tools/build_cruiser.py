"""Build the low, sea-green 1960s hardtop used by cruising traffic."""
import math
import sys
from pathlib import Path
import bpy

sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_vehicles import (clear_scene, cube, cylinder, material, mesh_from_rings,
    export_vehicle, SOURCE_DIR, PAINT_WHITE, GLASS, DARK, RUBBER, METAL, HEADLAMP, RED_LAMP)

clear_scene()
root=bpy.data.objects.new("Sjöstad hardtop",None)
bpy.context.collection.objects.link(root)
paint=material("Seafoam enamel",(.258,.435,.412),.38,.39)
def box(name,xyz,size,finish,bevel=.022):
    return cube(name,xyz,size,finish,bevel,root)
def axle_part(name,x,y,r,d,finish):
    return cylinder(name,(x,y,.35),r,d,finish,True,48,root)
def round_lamp(name,x,y,z,r,finish):
    lamp=cylinder(name,(x,y,z),r,.05,finish,False,32,root)
    lamp.rotation_euler.x=math.pi/2

body=mesh_from_rings("Long-waisted body",[
    (-2.77,.92,.29,.78,.85),(-2.65,1.00,.24,.82,.89),
    (-1.83,1.025,.22,.87,.93),(-.81,1.015,.21,.87,.91),
    (.45,1.005,.21,.85,.90),(1.67,1.025,.22,.87,.96),
    (2.72,.99,.27,.89,.96),(2.79,.95,.30,.87,.92)],paint,root,.032)
for y in [-1.65,1.64]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=.385,depth=2.4,
        location=(0,y,.35),rotation=(0,math.pi/2,0))
    cutter=bpy.context.object
    mod=body.modifiers.new("Wheel arch","BOOLEAN")
    mod.object=cutter
    mod.operation="DIFFERENCE"
    bpy.context.view_layer.objects.active=body
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True)
    for side in [-1,1]:
        axle_part("Däck",side*.9,y,.35,.21,RUBBER)
        axle_part("Alloy wheel",side*1.007,y,.244,.025,METAL)
        axle_part("Wheel hub",side*1.021,y,.197,.029,DARK)
        for i in range(5):
            a=i*math.tau/5
            spoke=box("Alloy wheel spoke",(side*1.043,y+.11*math.sin(a),.35+.11*math.cos(a)),(.025,.065,.197),METAL)
            spoke.rotation_euler.x=-a
mesh_from_rings("Wraparound glazing",[(-1.08,.88,.88,.92,.95),(-.48,.78,.88,1.44,1.49),
    (.47,.78,.88,1.44,1.49),(1.28,.90,.88,.95,1.00)],GLASS,root,.025)
box("Ivory hardtop",(0,0,1.49),(1.62,1.14,.092),PAINT_WHITE,.045)
for side in [-1,1]:
    post=box("Sail panel",(side*.811,.79,1.23),(.10,.24,.68),paint)
    post.rotation_euler.x=.88
    post=box("Windscreen pillar",(side*.827,-.77,1.22),(.051,.057,.79),METAL)
    post.rotation_euler.x=-.83
    box("Stainless beltline",(side*1.013,0,.776),(.029,5.22,.047),METAL)
    box("Door handle",(side*1.014,.24,.827),(.035,.166,.035),METAL)
    for x in [.66,.87]:
        round_lamp("Lamp bezel",side*x,-2.755,.707,.115,METAL)
        round_lamp("Sealed beam",side*x,-2.787,.707,.091,HEADLAMP)
    for x in [.48,.68,.87]:
        round_lamp("Triple tail bezel",side*x,2.786,.72,.091,METAL)
        round_lamp("Ruby tail lens",side*x,2.819,.72,.069,RED_LAMP)
for y in [-2.79,2.82]:
    box("Chrome bumper",(0,y,.42),(2.04,.14,.115),METAL,.05)
box("Grille recess",(0,-2.77,.69),(1.06,.08,.26),DARK)
for i in range(5):
    box("Grille blade",(0,-2.82,.588+i*.046),(1.07,.025,.014),METAL,.004)
export_vehicle(root,"raggarbil.glb")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/"Raggarbil.blend"))
