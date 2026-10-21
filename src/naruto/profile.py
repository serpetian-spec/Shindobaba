"""Oyuncu profili + kayıt/yükleme + ayarlar. Kayıtlar: %APPDATA%/ShinobiYolu"""
import os
import json
import time
from . import data

SAVE_DIR = os.path.join(os.environ.get('APPDATA', os.path.expanduser('~')), 'ShinobiYolu')
os.makedirs(SAVE_DIR, exist_ok=True)
SETTINGS_PATH = os.path.join(SAVE_DIR, 'ayarlar.json')

DEFAULT_SETTINGS = dict(sens=1.0, fov=75, music=.5, sfx=.8, view=1.0, fullscreen=False, fps=False, invert_y=False,
                        shadows=False)


def load_settings():
    s = dict(DEFAULT_SETTINGS)
    try:
        with open(SETTINGS_PATH, encoding='utf8') as f:
            s.update(json.load(f))
    except Exception:
        pass
    return s


def save_settings(s):
    try:
        with open(SETTINGS_PATH, 'w', encoding='utf8') as f:
            json.dump(s, f, indent=1)
    except Exception:
        pass


class Profile:
    def __init__(self):
        self.slot = 1
        self.name = 'İsimsiz'
        self.clan = 'none'
        self.elements = ['katon']
        self.hair_style = 'diken'
        self.hair_color = data.HAIR_COLORS[0]
        self.outfit_color = data.OUTFIT_COLORS[0]
        self.level = 1
        self.xp = 0
        self.rank = 0
        self.ryo = 300
        self.skill_points = 1
        self.skills = []
        self.learned = []  # öğrenilen jutsular
        self.slots = [None] * 6
        self.inventory = dict(kunai=20, shuriken=10, salve=2, smoke=1)
        self.throw_sel = 'kunai'
        self.summon = 'kurbağa'
        self.missions_done = dict(D=0, C=0, B=0, A=0, S=0)
        self.flags = {}  # hikaye bayrakları
        self.play_time = 0.0
        self.pos = None
        self.day_time = .35

    # ------------------------------------------------------------ hesaplar
    @property
    def rank_name(self):
        return data.RANKS[self.rank]

    def max_hp(self):
        return 100 + (self.level - 1) * 12 + (30 if 'vit1' in self.skills else 0) + \
            data.CLANS[self.clan].get('hp_bonus', 0)

    def max_chakra(self):
        return 100 + (self.level - 1) * 10 + (40 if 'nin2' in self.skills else 0)

    def can_use(self, jid):
        j = data.J[jid]
        if self.level < j['level'] or self.rank < j['rank']:
            return False
        if j['clan'] and j['clan'] != self.clan:
            return False
        if j['skill'] and j['skill'] not in self.skills:
            return False
        el = j['element']
        if el in data.ELEMENTS and el not in self.elements:
            return False
        if el in data.COMBINED:
            needs = data.COMBINED[el]['needs']
            native = (el == 'mokuton' and self.clan == 'senju') or (el == 'hyoton' and self.clan == 'yuki')
            if not native and not ('kekkei' in self.skills and all(n in self.elements for n in needs)):
                return False
        return True

    def available_jutsu(self):
        return [j for j in data.J if self.can_use(j) and j not in ('sharingan', 'byakugan')]

    def add_xp(self, amount):
        """Seviye atlama sayısını döndürür."""
        self.xp += int(amount)
        ups = 0
        while self.xp >= data.xp_for_level(self.level):
            self.xp -= data.xp_for_level(self.level)
            self.level += 1
            self.skill_points += 1
            ups += 1
        return ups

    def auto_learn(self):
        """Şartları karşılanan jutsular otomatik öğrenilir, boş slotlara yerleşir. Yeni öğrenilenleri döndürür."""
        new = []
        for jid in self.available_jutsu():
            if jid not in self.learned:
                self.learned.append(jid)
                new.append(jid)
                if jid not in data.DOJUTSU_IDS and None in self.slots and jid not in self.slots:
                    self.slots[self.slots.index(None)] = jid
        return new

    # ------------------------------------------------------------ kayıt
    def path(self, slot=None):
        return os.path.join(SAVE_DIR, f'kayit_{slot or self.slot}.json')

    def save(self, player=None, world_time=None):
        if player is not None:
            self.pos = [player.x, player.y + .2, player.z]
        if world_time is not None:
            self.day_time = world_time
        d = {k: v for k, v in self.__dict__.items()}
        d['saved_at'] = time.strftime('%Y-%m-%d %H:%M')
        with open(self.path(), 'w', encoding='utf8') as f:
            json.dump(d, f, ensure_ascii=False, indent=1)

    @staticmethod
    def load(slot):
        p = Profile()
        with open(p.path(slot), encoding='utf8') as f:
            d = json.load(f)
        for k, v in d.items():
            if k in p.__dict__:
                setattr(p, k, v)
        p.slot = slot
        if len(p.slots) < 6:
            p.slots += [None] * (6 - len(p.slots))
        return p

    @staticmethod
    def slot_info(slot):
        try:
            with open(Profile().path(slot), encoding='utf8') as f:
                d = json.load(f)
            return f"{d['name']} - {data.RANKS[d['rank']]} Sv.{d['level']} ({d.get('saved_at', '')})"
        except Exception:
            return None
