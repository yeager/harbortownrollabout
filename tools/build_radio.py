"""Render original instrumental in-car music and a quiet electric motor loop."""
import math
from pathlib import Path
import wave
from array import array

audio = Path(__file__).resolve().parents[1] / "audio"
rate = 24000
def render(name, seconds, sample):
    with wave.open(str(audio / (name+".wav")), "wb") as stream:
        stream.setparams((1,2,rate,0,"NONE",""))
        stream.writeframes(array("h",(round(sample(i/rate)*32767) for i in range(round(seconds*rate)))).tobytes())

def track(t):
    beat=t/.48
    bar=int(beat//4)%8
    chord=[(50,57,62,66),(47,54,59,62),(43,50,55,59),(45,52,57,61)][bar%4]
    note=chord[[0,2,1,3,1,2,3,2][int(beat*2)%8]]+(12 if bar>=4 else 0)
    def tone(n,phase):
        return math.sin(math.tau*440*2**((n-69)/12)*phase)
    step=t%.24
    bass=t%.96
    return .18*tone(note,step)*min(1,step/.014)*math.exp(-step*14)*min(1,(.24-step)/.04)+.12*tone(chord[0]-12,bass)*min(1,bass/.025)*math.exp(-bass*4)*min(1,(.96-bass)/.07)
render("sjostad_radio",15.36,track)
render("electric_drive",1,lambda t:.015*math.sin(math.tau*145*t)+.006*math.sin(math.tau*290*t))
