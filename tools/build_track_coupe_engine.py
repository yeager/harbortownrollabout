"""Synthesize a loopable six-cylinder sports exhaust for the GT3 RS."""
import math
import struct
import wave
from pathlib import Path

RATE = 24000
DURATION = 2
frames = bytearray()
# Three firing pulses per crank revolution, alternating between exhaust banks.
for i in range(RATE * DURATION):
    t = i / RATE
    crank = math.tau * 31 * t + .018 * math.sin(math.tau * 2 * t)
    firing = 3 * crank
    exhaust = sum(amplitude * math.sin(order * firing)
                  for order, amplitude in enumerate((0, .43, .22, .13, .072, .036)))
    banks = .12 * math.sin(1.5 * crank) + .046 * math.sin(4.5 * crank)
    induction = .045 * math.sin(8 * crank + .7 * math.sin(firing))
    frames.extend(struct.pack("<h", round(18000 * (exhaust + banks + induction))))

path = Path(__file__).resolve().parents[1] / "audio" / "track_coupe_engine.wav"
with wave.open(str(path), "wb") as out:
    out.setparams((1, 2, RATE, 0, "NONE", ""))
    out.writeframes(frames)
