import math
from ursina import Entity, Text, camera, window, Vec3, destroy, time, curve, mouse, application
from .util import C
from . import state
from . import build_info

L = -.5 * (16 / 9)


class Bar(Entity):
    def __init__(self, pos, col, label, **kw):
        super().__init__(parent=camera.ui, position=pos, **kw)
        Entity(parent=self, model='quad', origin=(-.5, 0), scale=(.42, .028), color=C('#101418', .75))
        self.fill = Entity(parent=self, model='quad', origin=(-.5, 0), x=.004, scale=(.412, .02), color=C(col))
        self.txt = Text(label, parent=self, position=(.43, .012), scale=.8, color=C('#ffffff'))

    def set(self, v, m):
        self.fill.scale_x = .412 * max(0, v) / m
        self.txt.text = f'{int(v)}/{int(m)}'


class HUD(Entity):
    def __init__(self):
        super().__init__(parent=camera.ui)
        state.hud = self
        self.hp = Bar((L + .04, .45), '#e04848', 'Can')
        self.ck = Bar((L + .04, .41), '#3aa0ff', 'Chakra')
        Text('Konoha Genin', parent=camera.ui, position=(L + .04, .49), scale=.9, color=C('#ffd08a'))

        # jutsu slotları
        self.slots = []
        for i, (key, name, cost, col) in enumerate([('LMB', 'Taijutsu', '-', '#d0a070'),
                                                    ('1', 'Rasengan', '30', '#5fc8ff'),
                                                    ('2', 'Kage Bunshin', '40', '#f0f0f0'),
                                                    ('3', 'Kunai', '-', '#9aa0a8'),
                                                    ('C', 'Chakra Topla', '+', '#3aa0ff')]):
            x = -.32 + i * .16
            Entity(parent=camera.ui, model='quad', position=(x, -.43), scale=(.14, .08), color=C('#101418', .7))
            Entity(parent=camera.ui, model='quad', position=(x, -.395), scale=(.14, .006), color=C(col))
            Text(f'[{key}]', parent=camera.ui, position=(x, -.41), origin=(0, 0), scale=.75, color=C(col))
            Text(name, parent=camera.ui, position=(x, -.437), origin=(0, 0), scale=.7)
            Text(f'chakra {cost}', parent=camera.ui, position=(x, -.458), origin=(0, 0), scale=.55,
                 color=C('#9ab'))

        Text('+', parent=camera.ui, origin=(0, 0), scale=1.2, color=C('#ffffff', .8))
        self.zone = Text('', parent=camera.ui, origin=(0, 0), y=.36, scale=2, color=C('#fff2d0'))
        self.zone_name = None
        self.msg = Text('', parent=camera.ui, origin=(0, 0), y=-.32, scale=1.1)
        self.msg_t = 0
        self.prompt = Text('', parent=camera.ui, origin=(0, 0), y=-.25, scale=1, color=C('#ffe08a'))
        self.state_txt = Text('', parent=camera.ui, origin=(.5, 0), position=(-L - .03, .1), scale=.8,
                              color=C('#cfe'))
        tag = 'TEST SÜRÜMÜ' if build_info.BUILD == 'test' else 'Sürüm'
        Text(f'{tag} v{build_info.VERSION}', parent=camera.ui, origin=(.5, -.5), position=(-L - .01, -.5),
             scale=.7, color=C('#ff9a6a' if build_info.BUILD == 'test' else '#bbbbbb'))

        # mini harita
        self.mm_size = .26
        self.mm = Entity(parent=camera.ui, position=(-L - .16, .34))
        Entity(parent=self.mm, model='circle', scale=self.mm_size + .012, color=C('#101418', .8))
        Entity(parent=self.mm, model='circle', scale=self.mm_size, color=C('#4f7f3c', .9))
        Entity(parent=self.mm, model='circle', scale=self.mm_size * 150 / 300 * 1.0, color=C('#88b45c', .9))
        self.mm_dots = Entity(parent=self.mm)
        self.mm_player = Entity(parent=self.mm, model='quad', scale=(.012, .02), color=C('#ff4a3a'))
        self.mm_marks = []
        for name, x, z, col in [('Kule', 0, 80, '#b8332a'), ('Ramen', 16, -40, '#ffd08a'),
                                ('Akademi', -55, 60, '#d9c39a'), ('Antr.', 95, -20, '#7fdc6a'),
                                ('Göl', 195, -120, '#3d8fd1'), ('Ölüm O.', -215, -140, '#24451f'),
                                ('Kapı', 0, -150, '#3f6b3a'), ('Kaya', 0, 170, '#8d8273')]:
            m = Entity(parent=self.mm_dots, model='circle', scale=.012, color=C(col))
            m.world_xz = (x, z)
            self.mm_marks.append(m)

        # duraklat menüsü
        self.pause = Entity(parent=camera.ui, enabled=False)
        Entity(parent=self.pause, model='quad', scale=(3, 1), color=C('#000000', .6))
        Text('DURAKLATILDI', parent=self.pause, origin=(0, 0), y=.2, scale=3)
        Text(CONTROLS, parent=self.pause, origin=(0, 0), y=-.05, scale=1)
        Text('[ESC] Devam   |   [Q] Oyundan çık', parent=self.pause, origin=(0, 0), y=-.33, scale=1.2,
             color=C('#ffd08a'))

    def toggle_pause(self):
        self.pause.enabled = not self.pause.enabled
        mouse.locked = not self.pause.enabled
        application.paused = self.pause.enabled

    def message(self, text, col='#ffffff', dur=3):
        self.msg.text = text
        self.msg.color = C(col)
        self.msg_t = dur

    def damage_number(self, world_pos, amount):
        sp = world_pos_to_ui(world_pos)
        if sp is None:
            return
        t = Text(str(int(amount)), parent=camera.ui, position=sp, origin=(0, 0), scale=1.6,
                 color=C('#ffdf4a' if amount < 30 else '#ff6a3a'))
        t.animate_position(t.position + Vec3(0, .06, 0), duration=.7, curve=curve.out_expo)
        t.fade_out(duration=.4, delay=.4)
        destroy(t, delay=.85)

    def update(self):
        p = state.player
        if not p:
            return
        self.hp.set(p.hp, p.max_hp)
        self.ck.set(p.chakra, p.max_chakra)
        if self.msg_t > 0:
            self.msg_t -= time.dt
            if self.msg_t <= 0:
                self.msg.text = ''
        it = p.nearest_interactable()
        self.prompt.text = it['label'] if it else ''
        st = 'DUVARDA' if p.wall else ('HAVADA' if not p.grounded else '')
        self.state_txt.text = st

        z = state.world.zone_at(p.position)
        if z != self.zone_name:
            self.zone_name = z
            self.zone.text = z
            self.zone.alpha = 1
            self.zone.fade_out(duration=1.5, delay=2.5)

        # mini harita: oyuncu merkezde değil, sabit harita (300m yarıçap)
        k = self.mm_size / 2 / 300
        for m in self.mm_marks:
            m.position = (m.world_xz[0] * k, m.world_xz[1] * k)
        self.mm_player.position = (p.x * k, p.z * k, -.01)
        self.mm_player.rotation_z = p.facing


def world_pos_to_ui(wp):
    rel = camera.getRelativePoint(camera.parent.getParent() if False else state.world.static, wp) \
        if False else None
    lens = camera.lens
    from panda3d.core import Point3, Point2
    p3 = camera.getRelativePoint(state.world.static.getParent(), Point3(*wp))
    p2 = Point2()
    if not lens.project(p3, p2):
        return None
    return Vec3(p2[0] * camera.aspect_ratio / 2, p2[1] / 2, 0)


CONTROLS = """WASD: hareket     Fare: kamera     Tekerlek: yakınlaştır
Ctrl / Space: zıpla (havada tekrar = çift zıplama)
Shift: ninja koşusu  |  havada Shift: hava dash'i
Duvara koşarak/zıplayarak git: DUVARDA YÜRÜ (W yukarı, S aşağı, A/D yana)
Duvardayken Ctrl: duvardan sek
Sol tık: yumruk kombosu  |  1: Rasengan  |  2: Gölge Klon  |  3 / R: Kunai
C (basılı): chakra topla  |  F: etkileşim"""
