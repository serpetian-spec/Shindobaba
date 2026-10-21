"""Tüm sesler ve müzik koddan sentezlenir (harici dosya yok). İlk açılışta %APPDATA%/ShinobiYolu/ses klasörüne yazılır."""
import os
import wave
import numpy as np
from .profile import SAVE_DIR

SR = 22050
AUDIO_VER = 3
DIR = os.path.join(SAVE_DIR, f'ses_v{AUDIO_VER}')
rng = np.random.default_rng(5)


def _t(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, a=.005, r=None, curve=4.0):
    t = np.arange(n) / SR
    e = np.minimum(1, t / max(a, 1e-4))
    dur = n / SR
    e *= np.exp(-curve * t / dur) if r is None else np.clip(1 - (t - (dur - r)) / r, 0, 1)
    return e


def lowpass(x, k):
    if k <= 1:
        return x
    c = np.cumsum(np.insert(x, 0, 0))
    y = (c[k:] - c[:-k]) / k
    return np.concatenate([y, np.zeros(len(x) - len(y))])


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def sweep(f0, f1, dur, wave_='sin'):
    t = _t(dur)
    f = np.linspace(f0, f1, len(t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if wave_ == 'sq':
        return np.sign(np.sin(ph))
    if wave_ == 'saw':
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    return np.sin(ph)


def write(name, x):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1
    x = (x / m * .9 * 32767).astype(np.int16)
    with wave.open(os.path.join(DIR, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(x.tobytes())


# ---------------------------------------------------------------- efektler
def gen_sfx():
    n = lambda d: int(SR * d)
    write('punch', lowpass(noise(.12), 6) * env(n(.12), curve=9) + sweep(160, 60, .12) * env(n(.12), curve=7) * .8)
    write('hit_heavy', lowpass(noise(.25), 10) * env(n(.25), curve=7) + sweep(120, 40, .25) * env(n(.25), curve=5))
    write('whoosh', lowpass(noise(.25), 14) * np.sin(np.linspace(0, np.pi, n(.25))) * .8)
    write('jump', lowpass(noise(.15), 20) * env(n(.15), curve=6) * .6 + sweep(200, 340, .15) * env(n(.15)) * .15)
    write('land', lowpass(noise(.1), 30) * env(n(.1), curve=10))
    write('step', lowpass(noise(.05), 25) * env(n(.05), curve=12) * .5)
    write('poof', lowpass(noise(.45), 8) * env(n(.45), a=.02, curve=5))
    write('kunai', sweep(2400, 1200, .12) * env(n(.12), curve=8) * .3 + lowpass(noise(.12), 3) * env(n(.12), curve=10) * .4)
    write('clink', (np.sin(2 * np.pi * 3100 * _t(.18)) + .6 * np.sin(2 * np.pi * 4700 * _t(.18))) * env(n(.18), curve=14))
    write('boom', lowpass(noise(1.0), 40) * env(n(1.0), a=.005, curve=4) + sweep(80, 25, 1.0) * env(n(1.0), curve=3))
    write('fire', lowpass(noise(1.0), 12) * env(n(1.0), a=.1, curve=2) + lowpass(noise(1.0), 50) * .6)
    write('water', lowpass(noise(.8), 5) * (np.sin(_t(.8) * 40) * .5 + .5) * env(n(.8), a=.05, curve=2.5))
    write('wind', lowpass(noise(.8), 7) * np.sin(np.linspace(0, np.pi, n(.8))) * (1 + .5 * np.sin(_t(.8) * 30)))
    write('earth', lowpass(noise(.7), 60) * env(n(.7), a=.01, curve=3) + sweep(70, 40, .7) * env(n(.7), curve=4))
    chirp = sum(np.sin(2 * np.pi * (2500 + 700 * np.sin(_t(1.2) * (40 + i * 13))) * _t(1.2)) for i in range(4))
    write('chidori', (chirp * .4 + noise(1.2) * .5) * env(n(1.2), a=.05, curve=1.5))
    write('rasengan', (sweep(180, 260, 1.0) + .5 * sweep(360, 520, 1.0) + lowpass(noise(1.0), 4) * .4)
          * (1 + .3 * np.sin(_t(1.0) * 50)) * env(n(1.0), a=.2, curve=1))
    write('seal', sweep(900, 700, .05) * env(n(.05), curve=10) * .5 + lowpass(noise(.05), 2) * env(n(.05), curve=14) * .4)
    write('levelup', np.concatenate([np.sin(2 * np.pi * f * _t(.13)) * env(n(.13), curve=3) for f in (523, 659, 784, 1046)]))
    write('click', sweep(1200, 900, .04) * env(n(.04), curve=10))
    write('coin', np.concatenate([np.sin(2 * np.pi * f * _t(.08)) * env(n(.08), curve=4) for f in (988, 1318)]))
    write('hurt', sweep(400, 200, .2, 'saw') * env(n(.2), curve=6) * .4 + lowpass(noise(.2), 6) * env(n(.2), curve=8))
    write('block', np.sin(2 * np.pi * 1800 * _t(.15)) * env(n(.15), curve=12) + lowpass(noise(.15), 4) * env(n(.15), curve=14))
    write('roar', lowpass(sweep(90, 60, 1.6, 'saw') + noise(1.6) * .7, 20) * env(n(1.6), a=.2, curve=1.2))
    write('genjutsu', sum(np.sin(2 * np.pi * f * _t(1.2)) for f in (220, 233, 330)) * env(n(1.2), a=.3, curve=2))
    write('heal', np.concatenate([np.sin(2 * np.pi * f * _t(.25)) * env(n(.25), a=.05) for f in (660, 880, 990)]) * .6)
    write('thunder', lowpass(noise(2.0), 30) * env(n(2.0), a=.01, curve=2.5))


# ---------------------------------------------------------------- müzik
# Japon "In" ölçeği (D Eb G A Bb) ve yo ölçeği
IN = [0, 1, 5, 7, 8]
YO = [0, 2, 5, 7, 9]


def midi(m):
    return 440 * 2 ** ((m - 69) / 12)


def koto(f, dur, vol=1.0):
    t = _t(dur)
    x = sum((1 / (h ** 1.3)) * np.sin(2 * np.pi * f * h * t) * np.exp(-t * (2.5 + h * 1.6)) for h in range(1, 7))
    return x * np.minimum(1, t / .003) * vol


def flute(f, dur, vol=1.0):
    t = _t(dur)
    vib = 1 + .006 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t / .3)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    x = np.sin(ph) + .25 * np.sin(2 * ph) + .08 * lowpass(noise(dur), 3)
    e = np.minimum(1, t / .08) * np.clip((dur - t) / .15, 0, 1)
    return x * e * vol


def taiko(dur=.6, vol=1.0, pitch=70):
    t = _t(dur)
    return (np.sin(2 * np.pi * np.cumsum(np.linspace(pitch * 1.6, pitch, len(t))) / SR) * np.exp(-t * 7)
            + lowpass(noise(dur), 15) * np.exp(-t * 25) * .6) * vol


def shaker(vol=.3):
    return lowpass(noise(.06), 2) * env(int(SR * .06), curve=10) * vol


def mix_into(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:j] += x[:j - i]


def gen_track(name, bpm, scale, root, bars, drums, lead='koto', seed=0, density=.7):
    r = np.random.default_rng(seed)
    beat = 60 / bpm
    total = bars * 4 * beat
    buf = np.zeros(int(SR * (total + 2)))
    notes = [root + o + 12 * k for k in (0, 1) for o in scale]
    idx = 4
    for b in range(bars * 4 * 2):  # sekizlik notalar
        tt = b * beat / 2
        if r.random() < density:
            idx = max(0, min(len(notes) - 1, idx + r.choice([-2, -1, -1, 1, 1, 2, 0])))
            f = midi(notes[idx])
            if lead == 'koto':
                mix_into(buf, koto(f, 1.6, .55), tt)
            else:
                if b % 2 == 0:
                    mix_into(buf, flute(f, beat * r.choice([1, 2]), .4), tt)
        if b % 8 == 0:  # bas
            mix_into(buf, koto(midi(root - 12 + scale[(b // 8) % 3 * 2 % len(scale)]), 3.0, .7), tt)
    for b in range(bars * 4):
        tt = b * beat
        if drums >= 1 and b % 4 in (0, 2):
            mix_into(buf, taiko(.7, .9), tt)
        if drums >= 2:
            mix_into(buf, taiko(.4, .5, 140), tt + beat / 2)
            if b % 2:
                mix_into(buf, taiko(.3, .6, 110), tt + beat * .75)
            for k in range(4):
                mix_into(buf, shaker(.2), tt + k * beat / 4)
        elif drums >= 1:
            mix_into(buf, shaker(.15), tt + beat / 2)
    # döngü yumuşak geçsin
    n = int(SR * total)
    tail = buf[n:]
    buf = buf[:n]
    buf[:len(tail)] += tail
    write(name, buf)


def gen_music():
    gen_track('muz_koy', 84, YO, 62, 16, 1, 'koto', seed=1, density=.55)
    gen_track('muz_gece', 64, IN, 57, 12, 0, 'flute', seed=2, density=.8)
    gen_track('muz_savas', 150, IN, 62, 24, 2, 'koto', seed=3, density=.85)
    gen_track('muz_boss', 168, IN, 57, 24, 2, 'koto', seed=4, density=.95)
    gen_track('muz_menu', 72, YO, 60, 12, 0, 'koto', seed=7, density=.5)


def ensure_generated():
    marker = os.path.join(DIR, 'tamam')
    if os.path.exists(marker):
        return
    os.makedirs(DIR, exist_ok=True)
    gen_sfx()
    gen_music()
    open(marker, 'w').close()


# ---------------------------------------------------------------- çalma
class AudioManager:
    def __init__(self, settings):
        from ursina import application
        from panda3d.core import Filename
        ensure_generated()
        self.settings = settings
        self.loader = application.base.loader
        self.Filename = Filename
        self.cache = {}
        self.music = None
        self.music_name = None
        self.fade = []

    def _load(self, name):
        if name not in self.cache:
            p = os.path.join(DIR, name + '.wav')
            self.cache[name] = [self.loader.loadSfx(self.Filename.fromOsSpecific(p)) for _ in range(3)]
        return self.cache[name]

    def play(self, name, vol=1.0, pitch=1.0, pos=None):
        from . import state
        if pos is not None and state.player is not None:
            d = (pos - state.player.position).length()
            vol *= max(0, 1 - d / 60)
            if vol <= .02:
                return
        try:
            pool = self._load(name)
        except Exception:
            return
        s = min(pool, key=lambda x: x.status() == x.PLAYING)
        s.setVolume(vol * self.settings['sfx'])
        s.setPlayRate(pitch)
        s.play()

    def play_music(self, name):
        if name == self.music_name:
            return
        self.music_name = name
        old = self.music
        try:
            p = os.path.join(DIR, name + '.wav')
            self.music = self.loader.loadSfx(self.Filename.fromOsSpecific(p))
        except Exception:
            self.music = None
            return
        self.music.setLoop(True)
        self.music.setVolume(0)
        self.music.play()
        self.fade = [(self.music, 0, 1)]
        if old:
            self.fade.append((old, 1, -1))

    def update(self, dt):
        keep = []
        for snd, v, d in self.fade:
            v += d * dt * .7
            if d < 0 and v <= 0:
                snd.stop()
                continue
            if d > 0 and v >= 1:
                v = 1
                snd.setVolume(v * self.settings['music'] * .55)
                continue
            snd.setVolume(max(0, v) * self.settings['music'] * .55)
            keep.append((snd, v, d))
        self.fade = keep
        if self.music and not self.fade:
            self.music.setVolume(self.settings['music'] * .55)
