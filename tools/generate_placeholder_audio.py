"""Generate placeholder SFX + percussion loops for Warrior's Art.

Dev tool only — real recordings replace these WAVs with the same names.
Pure stdlib (wave/math/random), 44.1 kHz 16-bit mono. Deterministic (seeded)
so regenerating produces identical files.

Run from the repo root:  python tools/generate_placeholder_audio.py
"""

import math
import random
import struct
import wave
from pathlib import Path

SR = 44100
rng = random.Random(20260706)


def _env_exp(t: float, dur: float, sharpness: float = 6.0) -> float:
    return math.exp(-sharpness * t / dur)


def membrane(freq_start: float, freq_end: float, dur: float, *, noise: float = 0.15,
             sharpness: float = 6.0, gain: float = 0.9) -> list[float]:
    """A drum-ish hit: pitch-sweeping sine + a little noise, exponential decay."""
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = freq_start + (freq_end - freq_start) * (t / dur)
        phase += math.tau * f / SR
        s = math.sin(phase)
        s += noise * (rng.random() * 2 - 1)
        out.append(gain * s * _env_exp(t, dur, sharpness))
    return out


def swoosh(dur: float, *, gain: float = 0.5) -> list[float]:
    """Filtered-noise swish (attack whiff)."""
    n = int(SR * dur)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / SR
        # One-pole lowpass whose cutoff sweeps up then down.
        sweep = math.sin(math.pi * t / dur)  # 0..1..0
        alpha = 0.05 + 0.4 * sweep
        lp += alpha * ((rng.random() * 2 - 1) - lp)
        out.append(gain * lp * (0.4 + 0.6 * sweep))
    return out


def mix(*layers: list[float]) -> list[float]:
    n = max(len(v) for v in layers)
    out = [0.0] * n
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    peak = max(1.0, max(abs(s) for s in out))
    return [s / peak * 0.92 for s in out]


def place(pattern: list[tuple[float, list[float], float]], total: float) -> list[float]:
    """Lay hits onto a timeline: (time_sec, samples, gain)."""
    out = [0.0] * int(SR * total)
    for at, samples, gain in pattern:
        start = int(at * SR)
        for i, s in enumerate(samples):
            j = start + i
            if j < len(out):
                out[j] += s * gain
    peak = max(1.0, max(abs(s) for s in out))
    return [s / peak * 0.9 for s in out]


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        ))
    print(f"wrote {path}")


def percussion_loop(base: float, bpm: int, accents: list[float], bars: int = 2) -> list[float]:
    """A 16-step drum loop. `accents` is 16 gains (0 = rest)."""
    step = 60.0 / bpm / 4.0
    total = step * 16 * bars
    hits = []
    for bar in range(bars):
        for i, gain in enumerate(accents):
            if gain <= 0:
                continue
            hi = i % 4 == 2  # off-beat strokes ring higher (rim-ish)
            f0 = base * (2.2 if hi else 1.0)
            hits.append((
                (bar * 16 + i) * step,
                membrane(f0 * 2.0, f0, 0.11 if hi else 0.16, noise=0.25, sharpness=8),
                gain,
            ))
    return place(hits, total)


def main() -> None:
    sfx = Path("assets/audio/sfx")
    write_wav(sfx / "hit_light.wav", membrane(190, 70, 0.09, noise=0.35, gain=0.8))
    write_wav(sfx / "hit_heavy.wav", mix(
        membrane(150, 45, 0.18, noise=0.3, sharpness=5),
        membrane(600, 200, 0.04, noise=0.6, gain=0.4),
    ))
    write_wav(sfx / "block.wav", membrane(340, 180, 0.06, noise=0.45, sharpness=9, gain=0.6))
    write_wav(sfx / "whiff.wav", swoosh(0.14))
    write_wav(sfx / "throw.wav", mix(
        membrane(120, 55, 0.14, noise=0.2, sharpness=5),
        swoosh(0.1),
    ))
    write_wav(sfx / "ko.wav", mix(
        membrane(90, 32, 0.5, noise=0.25, sharpness=3),
        membrane(500, 120, 0.08, noise=0.7, gain=0.5),
    ))

    perc = Path("assets/audio/percussion")
    # Bengal dhak: bright, driving, festival tempo.
    write_wav(perc / "dhak_loop.wav", percussion_loop(
        170, 152, [1, 0, 0.6, 0.8, 1, 0, 0.6, 0, 1, 0.5, 0.6, 0.8, 1, 0, 0.7, 0.5]))
    # Varanasi pakhawaj: deeper, statelier gait.
    write_wav(perc / "pakhawaj_loop.wav", percussion_loop(
        95, 96, [1, 0, 0, 0.5, 0.8, 0, 0.4, 0, 1, 0, 0.5, 0, 0.8, 0, 0.4, 0.6]))
    # Tamil Nadu thavil: crisp, syncopated, temple-procession drive.
    write_wav(perc / "thavil_loop.wav", percussion_loop(
        150, 132, [1, 0, 0.7, 0, 0.9, 0.5, 0, 0.7, 1, 0, 0.6, 0.8, 0, 0.9, 0.5, 0]))
    # Punjab dhol: driving bhangra pulse.
    write_wav(perc / "dhol_loop.wav", percussion_loop(
        120, 144, [1, 0, 0.5, 0.7, 1, 0, 0.7, 0, 1, 0.5, 0, 0.7, 1, 0, 0.7, 0.5]))


if __name__ == "__main__":
    main()
