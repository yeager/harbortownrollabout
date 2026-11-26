"""Synthesize a seamless five-cylinder road-car exhaust loop."""
import math
from pathlib import Path
import struct
import wave

RATE = 24000
SECONDS = 2
CRANK_HZ = 18
# Firing follows a four-stroke cycle: five pulses in two revolutions.
PULSE_LEVELS = (1.00, .88, 1.08, .94, .97)
FRAMES = bytearray()

for sample in range(RATE * SECONDS):
    time = sample / RATE
    cycle = time * CRANK_HZ / 2
    phase = cycle % 1
    exhaust = 0.0
    for cylinder, level in enumerate(PULSE_LEVELS):
        elapsed = (phase - cylinder / 5) % 1
        exhaust += level * (math.exp(-elapsed * 90) - .30 * math.exp(-elapsed * 23))
    firing = math.tau * cycle * 5
    resonance = .20 * math.sin(firing) + .11 * math.sin(2 * firing - .7)
    undertone = .075 * math.sin(math.tau * cycle)
    FRAMES.extend(struct.pack("<h", round(15000 * (exhaust + resonance + undertone))))

path = Path(__file__).resolve().parents[1] / "audio" / "rally_coupe_engine.wav"
with wave.open(str(path), "wb") as stream:
    stream.setparams((1, 2, RATE, 0, "NONE", ""))
    stream.writeframes(FRAMES)
