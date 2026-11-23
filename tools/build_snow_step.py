"""Synthesize a boot compressing snow, followed by a short granular scrape."""
import math
import random
import struct
import wave
from pathlib import Path

rate = 24000
rng = random.Random(918)
samples = []
grain = 0.0
smooth = 0.0
for i in range(int(rate * 0.32)):
    t = i / rate
    pressure = (1 - math.exp(-90*t)) * math.exp(-14*t)
    scrape = math.exp(-((t - 0.14) / 0.047)**2)
    if rng.random() < 0.07:
        grain = rng.uniform(0.12, 0.85)
    grain *= 0.93
    noise = rng.uniform(-1, 1)
    smooth += 0.18 * (noise - smooth)
    crunch = (3 * smooth + 0.42 * (noise - smooth)) * (0.22 + grain)
    thud = 0.28 * math.sin(math.tau * (112*t - 72*t*t)) * math.exp(-28*t)
    samples.append((pressure + 0.36 * scrape) * crunch + thud)
peak = max(map(abs, samples))
with wave.open(str(Path(__file__).resolve().parents[1] / "audio/snow_step.wav"), "wb") as output:
    output.setparams((1, 2, rate, 0, "NONE", ""))
    output.writeframes(b"".join(struct.pack("<h", round(23000 * x / peak)) for x in samples))
