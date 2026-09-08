#!/usr/bin/env python3
"""Generate short UI sound effects for Daily Fit into assets/audio/ (WAV 44.1k mono).

- tap.wav    : 12ms crisp UI tick
- pop.wav    : 110ms soft confirm pop
- swish.wav  : 200ms filtered noise swish (tab drag / style swipe)
- whoosh.wav : 280ms rising-then-falling lift whoosh (capsule pickup)
- pluck.wav  : 140ms bright pluck (ratings, chip selection, saves)
"""
import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
ASSET_DIR = os.path.join(os.path.dirname(__file__), "assets", "audio")


def write_wav(name, samples):
    os.makedirs(ASSET_DIR, exist_ok=True)
    path = os.path.join(ASSET_DIR, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)
    print("wrote", path)


def tick():
    n = int(SAMPLE_RATE * 0.012)
    rnd = random.Random(7)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 650)
        s = math.sin(2 * math.pi * 2200 * t) * 0.8 + (rnd.random() * 2 - 1) * 0.12
        out.append(s * env * 0.42)
    return out


def pop():
    n = int(SAMPLE_RATE * 0.110)
    rnd = random.Random(3)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 420 - 260 * (t / 0.110)
        env = math.exp(-t * 34)
        s = math.sin(2 * math.pi * freq * t) * 0.85
        if t < 0.003:
            s += (rnd.random() * 2 - 1) * 0.5
        out.append(s * env * 0.5)
    return out


def swish():
    n = int(SAMPLE_RATE * 0.200)
    rnd = random.Random(11)
    noise = [rnd.random() * 2 - 1 for _ in range(n)]
    # Cheap low-pass (moving average) to soften the hiss.
    lp = noise[:]
    win = 6
    for i in range(win, n):
        lp[i] = sum(noise[i - win + 1 : i + 1]) / win
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * t / 0.200) ** 1.6
        out.append(lp[i] * env * 0.32)
    return out


def whoosh():
    n = int(SAMPLE_RATE * 0.280)
    rnd = random.Random(5)
    noise = [rnd.random() * 2 - 1 for _ in range(n)]
    lp = noise[:]
    win = 5
    for i in range(win, n):
        lp[i] = sum(noise[i - win + 1 : i + 1]) / win
    out = []
    for i in range(n):
        t = i / n
        # Rise quickly, decay gently.
        env = math.pow(t, 0.55) * math.pow(1 - t, 0.9) * 4.0
        out.append(lp[i] * env * 0.4)
    return out


def pluck():
    n = int(SAMPLE_RATE * 0.140)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 26)
        s = (
            math.sin(2 * math.pi * 660 * t) * 0.8
            + math.sin(2 * math.pi * 990 * t) * 0.25
            + math.sin(2 * math.pi * 1318 * t) * 0.1
        )
        out.append(s * env * 0.5)
    return out


for name, fn in (
    ("tap.wav", tick),
    ("pop.wav", pop),
    ("swish.wav", swish),
    ("whoosh.wav", whoosh),
    ("pluck.wav", pluck),
):
    write_wav(name, fn())