"""Synthesize a seamless small single-cylinder two-stroke exhaust loop."""
import math
from pathlib import Path
import struct
import wave

rate = 24000
audio = bytearray()
for sample in range(rate * 2):
    t = sample / rate
    cycle = 45 * t + .014 * math.sin(math.tau * 2 * t)
    phase = math.tau * cycle
    # A short exhaust pulse once per revolution, softened by the silencer.
    pulse = sum(math.sin(h * phase + .08 * h) * math.exp(-h * .19)
                for h in range(1, 19)) * .16
    rasp = .042 * math.sin(phase * 6) * math.cos(math.tau * t * 2)
    audio.extend(struct.pack('<h', round(16000 * (pulse + rasp))))
with wave.open(str(Path(__file__).resolve().parents[1] / "audio/moped_engine.wav"), 'wb') as output:
    output.setparams((1, 2, rate, 0, "NONE", ""))
    output.writeframes(audio)
