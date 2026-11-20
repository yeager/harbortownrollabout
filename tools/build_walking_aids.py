"""Editable pushchair and rollator props, oriented for the pedestrian rig."""
import sys
from pathlib import Path
import bpy
from mathutils import Vector

sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_vehicles import clear_scene,cube,cylinder,material,RUBBER,METAL,DARK,SOURCE_DIR
from build_environment import export,OUT

def build(pram):
    clear_scene()
    name="Barnvagn" if pram else "Rullator"
    root=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(root)
    finish=material("Forest upholstery" if pram else "Berry enamel",
                    (.045,.18,.14) if pram else (.41,.047,.083),.18,.43)
    def bar(a,b,r,mat):
        a,b=Vector(a),Vector(b)
        tube=cylinder("Frame tube",(a+b)/2,r,(b-a).length,mat,False,12,root)
        tube.rotation_euler=(b-a).to_track_quat("Z","Y").to_euler()
    def pad(label,loc,size,mat,bevel):
        return cube(label,loc,size,mat,bevel,root)
    for side in [-1,1]:
        x=side*.26
        for y,radius in [(.35,.14 if pram else .10),(.99,.105 if pram else .09)]:
            cylinder("Tyre",(x,y,radius),radius,.052,RUBBER,True,28,root)
            cylinder("Wheel dish",(x+side*.019,y,radius),radius*.74,.034,METAL,True,24,root)
            cylinder("Hub",(x+side*.041,y,radius),radius*.27,.023,DARK,True,16,root)
        bar((x,.99,.12),(x,.34,.94),.019,finish)
        bar((x,.35,.14),(x,.85,.66),.019,METAL)
        bar((x,.41,.84),(x,.31,.92),.027,RUBBER)
    bar((-.26,.79,.55),(.26,.79,.55),.017,METAL)
    if pram:
        bar((-.26,.32,.93),(.26,.32,.93),.027,RUBBER)
        pad("Carrycot base",(0,.74,.56),(.51,.77,.15),DARK,.066)
        for side in [-1,1]:
            pad("Cot side",(side*.238,.74,.68),(.055,.76,.22),finish,.024)
        for y in [.39,1.09]:
            pad("Cot end",(0,y,.68),(.46,.06,.22),finish,.024)
        pad("Blanket",(0,.7,.68),(.40,.43,.09),material("Ochre cotton",(.77,.53,.29)),.04)
        pad("Canopy back",(0,1.03,.84),(.51,.14,.31),finish,.065)
        pad("Canopy visor",(0,.91,.97),(.52,.33,.09),finish,.04)
    else:
        pad("Folding seat",(0,.65,.56),(.47,.30,.056),DARK,.027)
        pad("Shopping pouch",(0,.82,.41),(.39,.15,.27),finish,.035)
        for side in [-1,1]:
            bar((side*.26,.35,.86),(side*.26,.28,.84),.015,METAL)
        bar((-.25,.79,.74),(.25,.79,.74),.032,RUBBER)
    export(root,str(Path(OUT)/(name.lower()+".glb")))
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE_DIR)/(name+".blend")))

build(True)
build(False)
