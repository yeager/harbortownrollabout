"""Render short, softly gated vehicle horns and a bicycle bell."""
import math
import struct
import wave
from pathlib import Path

RATE = 24000
AUDIO = Path(__file__).resolve().parents[1] / "audio"
# Each voice has its own tuning, overtone balance, attack and sustain.
VOICES = {
    "ambulance": ((392, 494), (.68,.23,.09), .025,.56),
    "police": ((523, 659), (.56,.31,.13), .017,.36),
    "fire": ((146, 185, 220), (.41,.29,.18,.09,.03), .085,.75),
    "bmw": ((330, 415), (.70,.19,.08,.03), .033,.48),
    "raggarbil": ((311, 370), (.43,.31,.18,.08), .06,.64),
    "a_traktor": ((405,), (.52,.28,.14,.06), .022,.32),
    "taxi": ((466,), (.47,.30,.17,.06), .023,.38),
    "recovery": ((233,294), (.56,.29,.15), .055,.58),
    "motorboat": ((255, 510), (.77,.18,.05), .045,.64),
    "tram": ((694, 1731, 2818), (.95,.05), .008,1.05),
    "bicycle": ((990, 2534), (.88,.12), .005,.80),
}
for name,(tones,weights,attack,duration) in VOICES.items():
    frames = bytearray()
    for i in range(round(RATE*duration)):
        t = i/RATE
        envelope = min(1,t/attack,max(0,(duration-t)/.073))
        if name=="bicycle":
            envelope *= math.exp(-4.8*t)
        if name=="tram":
            strike = t if t < .24 else t-.24
            envelope *= min(1,strike/attack)*math.exp(-5.5*strike)
        value = sum(weight*math.sin(math.tau*hz*(h+1)*t)
                    for hz in tones for h,weight in enumerate(weights))
        frames.extend(struct.pack("<h",round(19000*envelope*value/len(tones))))
    with wave.open(str(AUDIO/f"horn_{name}.wav"),"wb") as out:
        out.setparams((1,2,RATE,0,"NONE",""))
        out.writeframes(frames)
