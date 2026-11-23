"""Generate a seamless four-stroke mower engine and cutting-deck loop."""
import math
from pathlib import Path
import struct
import wave

rate = 24000
samples = bytearray()
for i in range(2 * rate):
    t = i / rate
    # A four-stroke single fires every other turn of the crankshaft.
    crank = math.tau * 50 * t + 0.06 * math.sin(math.tau * 2 * t)
    exhaust = sum(math.sin(h * crank / 2) * math.exp(-0.28 * h)
                  for h in range(1, 16))
    fan = math.sin(3 * crank) + 0.3 * math.sin(6 * crank)
    signal = 0.21 * exhaust + 0.045 * fan + 0.075 * math.sin(crank)
    samples.extend(struct.pack("<h", round(32000 * signal)))

with wave.open(str(Path(__file__).resolve().parents[1] / "audio/mower_engine.wav"), "wb") as output:
    output.setparams((1, 2, rate, 0, "NONE", ""))
    output.writeframes(samples)
