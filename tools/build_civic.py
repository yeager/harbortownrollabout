"""Build the neighbourhood police station and hospital exteriors."""
import sys
from pathlib import Path
import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_environment import (box, window, text, mat, clear, export, SOURCE, OUT,
                               WHITE, GLASS, METAL, BRICK, TEAL, MORTAR, TILE)

def create(hospital):
    clear()
    name = "Sjöstads sjukhus" if hospital else "Polisstation"
    root = bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(root)
    width = 20 if hospital else 13
    floors = 4 if hospital else 2
    depth = 9
    accent = TEAL if hospital else mat("Police blue",(.024,.095,.23))
    def part(label, loc, dims, finish, bevel=.03):
        return box(label,loc,dims,finish,bevel,root)
    height=3*floors
    part("Facade",(0,0,height/2),(width,depth,height),WHITE if hospital else BRICK)
    part("Granite plinth",(0,0,.22),(width+.12,depth+.12,.44),MORTAR)
    for level in range(floors):
        z=1.4+3*level
        for bay in range(-3 if hospital else -2,4 if hospital else 3):
            if level==0 and bay==0: continue
            window(root,bay*2.6,-4.54,z,1.92,1.55)
        for side in [-1,1]:
            for y in [-2.8,-.1,2.6]:
                part("Side glazing",(side*(width/2+.04),y,z),(.08,1.93,1.56),GLASS)
                part("Window surround",(side*(width/2+.08),y,z-.82),(.15,2.06,.09),METAL)
        part("Shadow line",(0,0,z+1.35),(width+.16,depth+.12,.13),MORTAR)
    part("Reception glazing",(0,-4.59,1.22),(2.55,.17,2.44),GLASS)
    for x in [-1.24,0,1.24]:
        part("Door frame",(x,-4.71,1.22),(.065,.06,2.44),METAL)
    part("Entrance canopy",(0,-5.52,2.77),(5.8,2.25,.23),accent)
    for x in [-2.69,2.69]:
        part("Portico column",(x,-6.48,1.35),(.12,.12,2.70),METAL)
    part("Sign band",(0,-4.59,height-.35),(width,.20,.82),accent)
    text("Station name","SJÖSTADS SJUKHUS" if hospital else "POLIS",(-3.45 if hospital else -1,-4.707,height-.55),.62,WHITE,root)
    if hospital:
        text("Emergency entrance","AKUT",(-.58,-6.67,2.67),.31,WHITE,root)
        for x in [-5.5,4.9]:
            part("Air handling plant",(x,.8,height+.57),(3,2.8,1.12),TILE,.12)
    else:
        for x in [-5,-3.7,3.7,5]:
            part("Vertical brick pier",(x,-4.56,3),(.16,.29,6),BRICK)
    part("Parapet",(0,0,height+.12),(width+.30,depth+.28,.22),TILE)
    filename="sjukhus" if hospital else "polisstation"
    export(root,str(Path(OUT)/(filename+".glb")))
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(SOURCE)/(filename+".blend")))
create(False)
create(True)
