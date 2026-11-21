"""Synthesize the ice cream truck signal, from the score in BrandNews 10/2003, p.9.

https://www.brandeye.se/form/artiklar/hart_bn1004.pdf
Pitch and rhythm follow the notation. The speaker tone is synthesized here.
"""
from array import array
from math import exp, sin, tau
from pathlib import Path
import sys
import wave

rate = 22050
eighth = .205
phrase = [(71, 1), (74, 1), (71, 1), (67, 2), (62, 1)]
score = [(62, 1)] + phrase * 2 + [(72, 2), (72, 1), (69, 2), (69, 1), (67, 3)]
samples = array("h")
for key, length in score:
    frequency = 440 * 2 ** ((key - 69) / 12)
    duration = eighth * length
    for i in range(round(rate * duration)):
        t = i / rate
        angle = tau * frequency * t
        envelope = min(t / .011, 1) * exp(-2.2 * t) * min(1, (duration - t) / .055)
        samples.append(round(18000 * envelope * (sin(angle) + .28*sin(2*angle) + .11*sin(3*angle))))
if sys.byteorder != "little":
    samples.byteswap()
with wave.open(str(Path(__file__).resolve().parents[1] / "audio/horn_icecream.wav"), "wb") as wav:
    wav.setparams((1, 2, rate, 0, "NONE", "not compressed"))
    wav.writeframes(samples.tobytes())
