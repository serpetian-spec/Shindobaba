from ursina import Entity, Vec3
from .util import C, mdl

SKIN = '#f3c9a0'

OUTFITS = {
    # özgün oyuncu karakteri (kanon karakter değil): koyu mavi genin kıyafeti
    'player': dict(top='#24324f', top2='#3d5a80', pants='#4a4f5a', hair='#5a3a22', band='#2a3f9e', shoes='#1f2530', spiky=True),
    'chunin': dict(top='#2f3a4a', top2='#5f7a3a', pants='#2f3a4a', hair='#222222', band='#2a3f9e', shoes='#1f2530'),
    'villager': dict(top='#7a9e6a', top2='#7a9e6a', pants='#5b4a3a', hair='#3a2a1a', band=None, shoes='#3a2f25'),
}


class NinjaModel(Entity):
    """Kutulardan yapılmış basit ninja. root'un altında; ayak tabanı y=0."""

    def __init__(self, outfit='player', **kw):
        super().__init__(**kw)
        o = OUTFITS[outfit] if isinstance(outfit, str) else outfit
        self.o = o
        # bacaklar
        self.legs = []
        for sx in (-1, 1):
            piv = Entity(parent=self, position=(.13 * sx, .85, 0))
            Entity(parent=piv, model='cube', y=-.38, scale=(.19, .76, .21), color=C(o['pants']))
            Entity(parent=piv, model='cube', y=-.8, z=.04, scale=(.2, .1, .3), color=C(o['shoes']))
            self.legs.append(piv)
        # gövde
        self.torso = Entity(parent=self, y=.85)
        Entity(parent=self.torso, model='cube', y=.33, scale=(.5, .66, .28), color=C(o['top']))
        Entity(parent=self.torso, model='cube', y=.52, scale=(.52, .26, .3), color=C(o['top2']))
        # kollar
        self.arms = []
        for sx in (-1, 1):
            piv = Entity(parent=self.torso, position=(.33 * sx, .6, 0))
            Entity(parent=piv, model='cube', y=-.28, scale=(.15, .56, .16), color=C(o['top']))
            Entity(parent=piv, model='cube', y=-.62, scale=(.13, .13, .13), color=C(SKIN))
            self.arms.append(piv)
        # kafa
        self.head = Entity(parent=self.torso, y=.92)
        Entity(parent=self.head, model='cube', scale=(.36, .38, .34), color=C(SKIN))
        for ex in (-.08, .08):
            Entity(parent=self.head, model='cube', position=(ex, .02, .175), scale=(.06, .06, .01), color=C('#2a6fd6'))
        # saç (dikenli)
        Entity(parent=self.head, model='cube', y=.17, scale=(.4, .14, .38), color=C(o['hair']))
        Entity(parent=self.head, model='cube', position=(0, .04, -.17), scale=(.4, .3, .06), color=C(o['hair']))
        if o.get('spiky'):
            for (x, z, rx, rz) in [(-.12, .06, 20, 30), (.12, .06, 20, -30), (0, -.12, -35, 0), (0, .02, 10, 0)]:
                Entity(parent=self.head, model=mdl('cone8'), position=(x, .2, z), rotation=(rx, 0, rz),
                       scale=(.13, .22, .13), color=C(o['hair']))
        if o.get('band'):
            Entity(parent=self.head, model='cube', y=.1, scale=(.38, .07, .36), color=C(o['band']))
            Entity(parent=self.head, model='cube', position=(0, .1, .18), scale=(.17, .07, .02), color=C('#c9ccd4'))
        self.phase = 0

    def animate(self, dt, speed, mode='ground'):
        """mode: ground | run | air | wall | charge | idle"""
        import math
        self.phase += dt * (4 + speed * .9)
        s = math.sin(self.phase)
        if mode == 'air':
            self.legs[0].rotation_x, self.legs[1].rotation_x = -40, 20
            self.arms[0].rotation_x = self.arms[1].rotation_x = -20
            self.arms[0].rotation_z, self.arms[1].rotation_z = 40, -40
            self.torso.rotation_x = 10
        elif mode == 'charge':
            self.legs[0].rotation_x = self.legs[1].rotation_x = 0
            self.arms[0].rotation_x = self.arms[1].rotation_x = -80
            self.arms[0].rotation_z, self.arms[1].rotation_z = -25, 25
            self.torso.rotation_x = 0
        elif mode in ('run', 'wall') and speed > .5:
            # Naruto koşusu: öne eğik, kollar geride
            self.legs[0].rotation_x, self.legs[1].rotation_x = s * 55, -s * 55
            self.arms[0].rotation_x = self.arms[1].rotation_x = 70
            self.arms[0].rotation_z = self.arms[1].rotation_z = 0
            self.torso.rotation_x = 30
        elif speed > .5:
            self.legs[0].rotation_x, self.legs[1].rotation_x = s * 35, -s * 35
            self.arms[0].rotation_x, self.arms[1].rotation_x = -s * 30, s * 30
            self.arms[0].rotation_z = self.arms[1].rotation_z = 0
            self.torso.rotation_x = 5
        else:
            for l in self.legs:
                l.rotation_x *= .8
            for a in self.arms:
                a.rotation_x *= .8
                a.rotation_z *= .8
            self.torso.rotation_x *= .8
