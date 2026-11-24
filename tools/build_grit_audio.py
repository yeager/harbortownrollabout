"""Synthesize a short seamless loop of loose grit striking a hard surface."""
import math
from pathlib import Path
import random
import struct
import wave

rate = 24000
frames = [0.0] * (rate * 2)
rng = random.Random(41)
for _ in range(465):
    start = rng.randrange(len(frames))
    pitch = rng.uniform(700, 3400)
    tail = rng.uniform(.001, .009)
    level = rng.uniform(.055, .37)
    for offset in range(round(tail * rate * 5)):
        time = offset / rate
        tap = math.sin(math.tau * pitch * time) * .5 + rng.uniform(-.5, .5)
        frames[(start+offset) % len(frames)] += level * tap * math.exp(-time/tail)

path = Path(__file__).resolve().parents[1] / "audio" / "grit_spreader.wav"
with wave.open(str(path), "wb") as stream:
    stream.setparams((1, 2, rate, 0, "NONE", ""))
    stream.writeframes(b"".join(struct.pack("<h", round(23500 * math.tanh(value))) for value in frames))
