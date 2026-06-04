#!/usr/bin/env python3
# Generate small placeholder WAV assets for the minimum BGM/SFX pass.

import math
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RATE = 22050
AMP = 32767


def _write_mono(path: Path, samples) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        frames = bytearray()
        for sample in samples:
            value = max(-1.0, min(1.0, sample))
            frames += int(value * AMP).to_bytes(2, byteorder="little", signed=True)
        wav.writeframes(frames)


def _sine(freq: float, t: float) -> float:
    return math.sin(2.0 * math.pi * freq * t)


def _env(index: int, total: int, attack: float = 0.01, release: float = 0.08) -> float:
    t = index / RATE
    duration = total / RATE
    if t < attack:
        return t / max(attack, 0.001)
    tail = duration - t
    if tail < release:
        return max(0.0, tail / max(release, 0.001))
    return 1.0


def _tone(duration: float, freq: float, volume: float = 0.35, overtones=()):
    total = int(RATE * duration)
    for i in range(total):
        t = i / RATE
        value = _sine(freq, t)
        for mul, gain in overtones:
            value += _sine(freq * mul, t) * gain
        yield value * volume * _env(i, total)


def _battle_theme():
    duration = 8.0
    total = int(RATE * duration)
    bass = [110.0, 130.81, 146.83, 164.81]
    lead = [220.0, 246.94, 261.63, 293.66, 329.63, 293.66, 261.63, 246.94]
    for i in range(total):
        t = i / RATE
        beat = int(t * 2.0)
        step = int(t * 4.0)
        bass_freq = bass[beat % len(bass)]
        lead_freq = lead[step % len(lead)]
        pulse = 0.72 + 0.28 * max(0.0, _sine(2.0, t))
        value = _sine(bass_freq, t) * 0.18
        value += _sine(lead_freq, t) * 0.08 * pulse
        value += _sine(lead_freq * 2.0, t) * 0.025
        yield value


def _coin():
    yield from _tone(0.09, 880.0, 0.26, [(2.0, 0.25)])
    yield from _tone(0.13, 1320.0, 0.22, [(2.0, 0.18)])


def _victory():
    for freq in [392.0, 523.25, 659.25, 783.99]:
        yield from _tone(0.16, freq, 0.24, [(2.0, 0.18)])


def _defeat():
    for freq in [246.94, 220.0, 196.0]:
        yield from _tone(0.18, freq, 0.25, [(0.5, 0.20)])


def main() -> int:
    targets = {
        "assets/audio/music/battle_theme.wav": _battle_theme(),
        "assets/audio/sfx/ui_click.wav": _tone(0.07, 660.0, 0.24, [(3.0, 0.12)]),
        "assets/audio/sfx/coin.wav": _coin(),
        "assets/audio/sfx/battle_start.wav": _tone(0.35, 196.0, 0.27, [(1.5, 0.20), (2.0, 0.12)]),
        "assets/audio/sfx/victory.wav": _victory(),
        "assets/audio/sfx/defeat.wav": _defeat(),
    }
    for rel, samples in targets.items():
        path = ROOT / rel
        _write_mono(path, samples)
        print(f"audio: {rel}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
