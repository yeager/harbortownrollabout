"""Create three distinct, gentle loopable siren tones for the game."""
import math
import struct
import wave
from pathlib import Path

RATE = 24000

def render(path: Path, duration: float, phase_model, amplitude_model):
    frames = bytearray()
    for i in range(int(RATE * duration)):
        t = i / RATE
        phase_cycles = phase_model(t)
        amplitude = amplitude_model(t)
        phase = math.tau * phase_cycles
        sample = amplitude * (math.sin(phase) + 0.18 * math.sin(phase * 2 + 0.2) + 0.12 * math.sin(phase * 3 + 0.6))
        frames.extend(struct.pack("<h", max(-32767, min(32767, int(sample * 32767)))))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(frames)

def ambulance_phase(t: float) -> float:
    cycle = math.floor(t)
    local = t - cycle
    if local < 0.5:
        return cycle * 550 + local * 480
    return cycle * 550 + 240 + (local - 0.5) * 620

def police_phase(t: float) -> float:
    period = 0.8
    return 650 * t + 260 * period / math.tau * (1 - math.cos(math.tau * t / period))

def fire_phase(t: float) -> float:
    interval = math.floor(t / 0.8)
    local = t - interval * 0.8
    completed_pairs = interval // 2
    if interval % 2 == 0:
        return completed_pairs * 744 + local * 390
    return completed_pairs * 744 + 312 + local * 540

def suv_engine_phase(t: float) -> float:
    # A low, smooth V8 idle loop with enough harmonics to read as an engine.
    return 105 * t + 12 * 1.4 / math.tau * (1 - math.cos(math.tau * t / 1.4))

def suv_engine_gain(t: float) -> float:
    return 0.19 + 0.05 * (0.5 + 0.5 * math.sin(math.tau * t / 1.4))

def steady_gain(_t: float) -> float:
    return 0.30

def police_gain(t: float) -> float:
    return 0.24 + 0.06 * (0.5 + 0.5 * math.sin(math.tau * t / 0.2))

render(Path("audio/siren_ambulance.wav"), 4.0, ambulance_phase, steady_gain)
render(Path("audio/siren_police.wav"), 4.0, police_phase, police_gain)
render(Path("audio/siren_fire.wav"), 4.8, fire_phase, steady_gain)
render(Path("audio/suv_engine.wav"), 4.2, suv_engine_phase, suv_engine_gain)
print("Generated ambulance, police, and fire sirens plus a BMW V8 idle loop.")
