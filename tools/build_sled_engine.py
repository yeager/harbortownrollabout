"""Render a periodic two-cylinder exhaust note with a quieter track whirr."""
import math
import struct
import wave
from pathlib import Path

rate = 24000
frames = bytearray()
for i in range(rate * 2):
    t = i / rate
    phase = math.tau * 48 * t + .08 * math.sin(math.tau * 3 * t)
    exhaust = sum(weight * math.sin(h * phase) for h, weight in
                  enumerate((0, .23, .38, .16, .10, .05, .03)))
    whirr = .05 * math.sin(math.tau * 312 * t + .65 * math.sin(phase))
    frames.extend(struct.pack("<h", round(13500 * (exhaust + whirr))))
target = Path(__file__).resolve().parents[1] / "audio" / "sled_engine.wav"
with wave.open(str(target), "wb") as out:
    out.setparams((1, 2, rate, 0, "NONE", ""))
    out.writeframes(frames)
