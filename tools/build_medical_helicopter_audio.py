"""Synthesize a two-second, phase-aligned rotor loop for the medical helicopter."""

import math
from pathlib import Path
import struct
import wave


RATE = 24000
DURATION = 2
path = Path(__file__).resolve().parents[1] / "audio" / "medical_helicopter_rotor.wav"

frames = bytearray()
for frame in range(RATE * DURATION):
    angle = math.tau * frame / RATE
    blade = math.cos(22 * angle)
    pulse = ((1 + blade) / 2) ** 9
    flutter = .83 + .17 * math.cos(2.5 * angle)
    rotor = flutter * (.24 * blade + pulse * (.22 + .16 * math.sin(66 * angle)))
    turbine = (.08 + .08 * pulse) * math.sin(264 * angle) + .042 * math.sin(499.5 * angle)
    frames.extend(struct.pack("<h", round(29000 * (rotor + turbine))))

with wave.open(str(path), "wb") as output:
    output.setparams((1, 2, RATE, 0, "NONE", ""))
    output.writeframes(frames)
