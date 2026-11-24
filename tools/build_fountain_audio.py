"""Synthesize a seamless loop of water droplets landing on wet stone."""
import math
from pathlib import Path
import random
import struct
import wave

rate = 24000
samples = [0.0] * (rate * 4)
rng = random.Random(183)

for _ in range(1300):
    start = rng.randrange(len(samples))
    duration = rng.uniform(.004, .022)
    pitch = rng.uniform(260, 2500)
    level = rng.uniform(.025, .18)
    filtered_noise = 0.0
    for offset in range(round(duration * rate * 4)):
        time = offset / rate
        filtered_noise = .69 * filtered_noise + .31 * rng.uniform(-1, 1)
        phase = math.tau * pitch * (time + 6 * time**2)
        attack = min(1.0, time / .001)
        splash = .82 * filtered_noise + .18 * math.sin(phase)
        samples[(start + offset) % len(samples)] += splash * level * attack * math.exp(-time / duration)

path = Path(__file__).resolve().parents[1] / "audio" / "fountain_water.wav"
with wave.open(str(path), "wb") as stream:
    stream.setparams((1, 2, rate, 0, "NONE", ""))
    stream.writeframes(b"".join(struct.pack("<h", round(26500 * math.tanh(sample))) for sample in samples))
