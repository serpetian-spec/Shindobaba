"""Kuklalar, köylüler, gölge klonlar - hepsi boyutlarına göre kapsül hitbox kullanır."""
import math
import random
from ursina import Entity, Vec3, time, destroy, invoke, curve
from .util import C, mdl, poof, flat, lerp_angle
from .physics import Body, capsule_hit
from .ninja_model import NinjaModel
from . import state


class Damageable(Entity):
    def __init__(self, radius, height, hp, mass=1.0, **kw):
        super().__init__(**kw)
        self.body = Body(self, radius, height, mass)
        state.world.phys.bodies.append(self.body)
        self.max_hp = self.hp = hp
        self.dead = False
        state.targets.append(self)

    def hit_test(self, point, radius):
        return not self.dead and capsule_hit(point, self.body, radius)

    def take_damage(self, amount, knock=None):
        if self.dead:
            return
        self.hp -= amount
        if state.hud:
            state.hud.damage_number(self.world_position + Vec3(0, self.body.height + .3, 0), amount)
        self.on_hit(knock)
        if self.hp <= 0:
            self.dead = True
            self.on_death()

    def on_hit(self, knock):
        pass

    def on_death(self):
        pass

    def remove(self):
        if self in state.targets:
            state.targets.remove(self)
        if self.body in state.world.phys.bodies:
            state.world.phys.bodies.remove(self.body)
        destroy(self)


class TrainingDummy(Damageable):
    def __init__(self, position):
        super().__init__(radius=.45, height=1.9, hp=150, mass=0, position=position)
        self.spawn = Vec3(position)
        self.vis = Entity(parent=self)
        self.post = Entity(parent=self.vis, model=mdl('cyl8'), scale=(.25, 1.9, .25), color=C('#7a5532'))
        Entity(parent=self.vis, model='cube', y=1.2, scale=(.7, .7, .45), color=C('#d8c48a'))
        Entity(parent=self.vis, model='cube', y=1.2, scale=(1.3, .15, .2), color=C('#7a5532'))
        Entity(parent=self.vis, model='sphere', y=1.8, scale=.42, color=C('#d8c48a'))
        Entity(parent=self.vis, model='cube', position=(0, 1.2, .23), scale=(.3, .3, .02), color=C('#c0302a'))

    def on_hit(self, knock):
        self.vis.rotation_z = random.choice((-1, 1)) * 14
        self.vis.animate_rotation((0, 0, 0), duration=.35, curve=curve.out_elastic)

    def on_death(self):
        self.vis.animate_rotation((85, 0, 0), duration=.5, curve=curve.out_bounce)
        self.body.active = False
        invoke(self.respawn, delay=5)

    def respawn(self):
        self.hp, self.dead = self.max_hp, False
        self.body.active = True
        self.vis.rotation = (0, 0, 0)
        poof(self.world_position, .8)


class Walker(Entity):
    """Zemini takip eden, duvara girmeyen basit karakter."""

    def __init__(self, outfit, radius=.4, height=1.8, scale_k=1.0, **kw):
        super().__init__(**kw)
        self.model_ = NinjaModel(outfit, parent=self, scale=scale_k)
        self.body = Body(self, radius * scale_k, height * scale_k, 1.0)
        state.world.phys.bodies.append(self.body)
        self.vy = 0
        self.speed = 0

    def walk(self, wish, speed):
        dt = time.dt
        phys = state.world.phys
        p = self.position + wish * speed * dt
        self.vy -= 30 * dt
        p.y += self.vy * dt
        phys.resolve(p, self.body.radius, self.body.height)
        fl = phys.floor(p.x, p.z, self.body.radius, max(p.y, self.y))
        if p.y <= fl:
            p.y, self.vy = fl, 0
        self.position = p
        self.speed = speed if wish.length() > .1 else 0
        if self.speed:
            self.model_.rotation_y = lerp_angle(self.model_.rotation_y,
                                                math.degrees(math.atan2(wish.x, wish.z)), dt * 10)
        self.model_.animate(dt, self.speed, 'ground')

    def remove(self):
        if self.body in state.world.phys.bodies:
            state.world.phys.bodies.remove(self.body)
        destroy(self)


class Villager(Walker):
    OUTFITS = [dict(top=t, top2=t, pants=p, hair=h, band=None, shoes='#3a2f25')
               for t, p, h in [('#7a9e6a', '#5b4a3a', '#3a2a1a'), ('#b05a5a', '#3a3a4a', '#1a1a1a'),
                               ('#d8c890', '#6a5a4a', '#7a4a2a'), ('#6a7ab0', '#4a4a4a', '#c8a050'),
                               ('#c890b0', '#3a3a5a', '#2a1a1a'), ('#e0e0e0', '#2a2a2a', '#555555')]]

    def __init__(self, position):
        super().__init__(random.choice(Villager.OUTFITS), position=position, scale_k=random.uniform(.85, 1.05))
        self.goal = random.choice(state.world.road_points)
        self.wait = 0

    def update(self):
        if self.wait > 0:
            self.wait -= time.dt
            self.walk(Vec3(0, 0, 0), 0)
            return
        d = self.goal - self.position
        d.y = 0
        if d.length() < 1.5:
            self.goal = random.choice(state.world.road_points)
            self.wait = random.uniform(0, 4)
        self.walk(flat(d), 3.2)


class ShadowClone(Walker):
    """Kage Bunshin: oyuncunun kopyası, en yakın hedefe saldırır."""

    def __init__(self, position, life=14):
        super().__init__('player', position=position)
        self.life = life
        self.cd = 0
        poof(self.world_position, 1)

    def update(self):
        dt = time.dt
        self.life -= dt
        self.cd -= dt
        if self.life <= 0:
            self.vanish()
            return
        tgt, best = None, 30
        for t in state.targets:
            if not t.dead:
                d = (t.position - self.position).length()
                if d < best:
                    tgt, best = t, d
        if tgt:
            to = tgt.position - self.position
            reach = self.body.radius + tgt.body.radius + .5
            if best > reach:
                self.walk(flat(to), 11)
            else:
                self.walk(Vec3(0, 0, 0), 0)
                self.model_.rotation_y = math.degrees(math.atan2(to.x, to.z))
                if self.cd <= 0:
                    self.cd = .55
                    self.model_.arms[1].rotation_x = -90
                    tgt.take_damage(6, flat(to))
        else:
            to = state.player.position - self.position
            if to.length() > 4:
                self.walk(flat(to), 12)
            else:
                self.walk(Vec3(0, 0, 0), 0)

    def vanish(self):
        poof(self.world_position, 1)
        self.remove()


class Kunai(Entity):
    def __init__(self, pos, direction, owner=None):
        super().__init__(position=pos, model='cube', scale=(.06, .06, .5), color=C('#30343a'))
        self.dir = direction.normalized()
        self.look_at(self.position + self.dir)
        Entity(parent=self, model='cube', z=-.6, scale=(1.6, .6, .3), color=C('#c8c8c8'))
        self.speed = 70
        self.stuck = False
        self.t = 0

    def update(self):
        if self.stuck:
            return
        dt = time.dt
        self.t += dt
        step = self.speed * dt
        self.dir.y -= 2 * dt * .1
        o = self.position
        for t in state.targets:
            for k in range(4):
                if t.hit_test(o + self.dir * step * k / 3, .15):
                    t.take_damage(18, flat(self.dir))
                    destroy(self)
                    return
        hit = state.world.phys.raycast(o, self.dir, step)
        if hit:
            self.position = o + self.dir * (hit[0] - .1)
            self.stuck = True
            destroy(self, delay=6)
            return
        self.position = o + self.dir * step
        if self.t > 3:
            destroy(self)
