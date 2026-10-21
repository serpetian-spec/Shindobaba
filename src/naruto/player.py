"""Oyuncu: Shinobi Striker tarzı parkur + temel jutsular.

Ctrl / Space : zıpla, havada tekrar -> çift zıplama, duvardayken -> duvardan sekme
Shift        : yerde koşu (ninja koşusu), havada -> hava dash'i
Duvara koşarak/zıplayarak çarp -> duvarda yürü (W yukarı, S aşağı, A/D yana)
"""
import math
from ursina import Entity, Vec3, camera, held_keys, mouse, time, destroy, invoke, application
from .util import C, mdl, poof, burst, flat, lerp_angle
from .physics import Body
from .ninja_model import NinjaModel
from .actors import ShadowClone, Kunai
from . import state

WALK, RUN = 7.0, 16.0
GRAV = 34.0
JUMP_V = 13.0
WALL_SPEED = 11.0


def jump_key():
    return held_keys['left control'] or held_keys['right control'] or held_keys['space']


class Player(Entity):
    def __init__(self, position):
        super().__init__(position=position)
        self.model_ = NinjaModel('player', parent=self)
        self.body = Body(self, .4, 1.8, 1.0)
        state.world.phys.bodies.append(self.body)
        state.player = self

        self.max_hp = self.hp = 100.0
        self.max_chakra = self.chakra = 100.0
        self.vel = Vec3(0, 0, 0)
        self.grounded = True
        self.jumps = 0
        self.air_dash = True
        self.dash_t = 0
        self.wall = None  # (nx, nz) duvar normali
        self.wall_cd = 0
        self.facing = 0.0
        self.busy = 0
        self.charging = False
        self.rasengan = None
        self.rasen_dash = 0
        self.combo = 0
        self.combo_t = 0
        self.punch_cd = 0
        self.on_swing = False
        self.mouse_look = True

        # kamera
        self.yaw, self.pitch, self.dist = 0.0, 12.0, 7.0
        self.pivot = Entity()
        camera.parent = self.pivot
        camera.position = (0, 0, -self.dist)
        camera.rotation = (0, 0, 0)
        camera.fov = 75

        self.aura = Entity(parent=self, model='sphere', y=.9, scale=(1.6, 2.4, 1.6), color=C('#5fc8ff', .25),
                           unlit=True, enabled=False)

    # ------------------------------------------------------------ yardımcı
    def cam_basis(self):
        a = math.radians(self.yaw)
        return Vec3(math.sin(a), 0, math.cos(a)), Vec3(math.cos(a), 0, -math.sin(a))

    def wish_dir(self):
        fwd, right = self.cam_basis()
        d = fwd * (held_keys['w'] - held_keys['s']) + right * (held_keys['d'] - held_keys['a'])
        return d.normalized() if d.length() > .01 else Vec3(0, 0, 0)

    def face_vec(self):
        a = math.radians(self.facing)
        return Vec3(math.sin(a), 0, math.cos(a))

    def spend(self, amount):
        if self.chakra < amount:
            if state.hud:
                state.hud.message('Yeterli chakra yok! (C basılı tut: chakra topla)', '#7fd0ff')
            return False
        self.chakra -= amount
        return True

    # ------------------------------------------------------------ girdi
    def input(self, key):
        if application.paused or not mouse.locked:
            return
        if key in ('left control', 'right control', 'space'):
            self.do_jump()
        elif key in ('left shift', 'right shift'):
            if not self.grounded and not self.wall and self.air_dash and self.spend(8):
                self.air_dash = False
                self.dash_t = .22
                d = self.wish_dir()
                if d.length() < .1:
                    d = self.cam_basis()[0]
                self.vel = d * 30
                self.vel.y = 1.5
                self.facing = math.degrees(math.atan2(d.x, d.z))
                poof(self.world_position + Vec3(0, .5, 0), .5, count=5)
        elif key == 'left mouse down':
            self.punch()
        elif key == '1':
            self.cast_rasengan()
        elif key == '2':
            self.cast_clones()
        elif key in ('3', 'r'):
            self.throw_kunai()
        elif key == 'f':
            self.interact()
        elif key == 'scroll up':
            self.dist = max(2.5, self.dist - .8)
        elif key == 'scroll down':
            self.dist = min(16, self.dist + .8)

    def do_jump(self):
        if self.on_swing:
            self.on_swing = False
        if self.wall:  # duvardan sekme
            nx, nz = self.wall
            d = self.wish_dir()
            side = d - Vec3(nx, 0, nz) * d.dot(Vec3(nx, 0, nz))
            self.vel = Vec3(nx, 0, nz) * 11 + side * 6
            self.vel.y = JUMP_V * .95
            self.wall = None
            self.wall_cd = .3
            self.jumps = 1
            self.air_dash = True
            self.facing = math.degrees(math.atan2(self.vel.x, self.vel.z))
            return
        if self.grounded:
            self.vel.y = JUMP_V
            self.grounded = False
            self.jumps = 1
        elif self.jumps < 2:
            self.vel.y = JUMP_V * .9
            self.jumps = 2
            poof(self.world_position, .45, count=5)
            d = self.wish_dir()
            if d.length() > .1:
                hs = max(Vec3(self.vel.x, 0, self.vel.z).length(), WALK)
                self.vel.x, self.vel.z = d.x * hs, d.z * hs

    # ------------------------------------------------------------ jutsu / dövüş
    def melee_point(self, reach=1.1):
        return self.position + Vec3(0, 1.1, 0) + self.face_vec() * (self.body.radius + reach * .6)

    def punch(self):
        if self.busy > 0 or self.punch_cd > 0 or self.wall:
            return
        self.combo = self.combo + 1 if self.combo_t > 0 else 1
        if self.combo > 3:
            self.combo = 1
        self.combo_t = .7
        self.punch_cd = .28
        fwd = self.cam_basis()[0]
        self.facing = math.degrees(math.atan2(fwd.x, fwd.z))
        arm = self.model_.arms[self.combo % 2]
        arm.rotation_x = -100
        dmg = (8, 10, 18)[self.combo - 1]
        p = self.melee_point()
        for t in list(state.targets):
            if t.hit_test(p, .8):
                t.take_damage(dmg, self.face_vec())
        if self.combo == 3:
            self.vel += self.face_vec() * 6

    def cast_rasengan(self):
        if self.busy > 0 or self.wall or not self.spend(30):
            return
        self.busy = .9
        fwd = self.cam_basis()[0]
        self.facing = math.degrees(math.atan2(fwd.x, fwd.z))
        self.rasengan = Entity(parent=self.model_, model='sphere', position=(.35, 1.25, .55), scale=.05,
                               color=C('#5fc8ff', .9), unlit=True)
        Entity(parent=self.rasengan, model='sphere', scale=1.3, color=C('#dff6ff', .35), unlit=True)
        self.rasengan.animate_scale(.55, duration=.45)
        invoke(self._rasengan_go, delay=.45)

    def _rasengan_go(self):
        self.rasen_dash = .35

    def _rasengan_end(self, hit_pos=None):
        if self.rasengan:
            if hit_pos is not None:
                burst(hit_pos, '#5fc8ff', 6, .5)
            destroy(self.rasengan)
            self.rasengan = None
        self.rasen_dash = 0

    def cast_clones(self):
        if self.busy > 0 or not self.spend(40):
            return
        self.busy = .4
        r = self.cam_basis()[1]
        for off in (-2.2, 2.2, 0):
            p = self.position + r * off + (self.face_vec() * -2 if off == 0 else Vec3(0, 0, 0))
            ShadowClone(p)
        state.hud.message('Kage Bunshin no Jutsu!', '#ffffff')

    def throw_kunai(self):
        if self.busy > 0 or self.punch_cd > 0:
            return
        self.punch_cd = .25
        d = camera.forward
        fwd = flat(d)
        if fwd.length() > .1:
            self.facing = math.degrees(math.atan2(fwd.x, fwd.z))
        start = self.position + Vec3(0, 1.4, 0) + fwd * .6
        # kameranın baktığı noktaya doğru at
        o = camera.world_position
        hit = state.world.phys.raycast(o, d, 200)
        target = o + d * (hit[0] if hit else 200)
        Kunai(start, target - start)
        self.model_.arms[1].rotation_x = -120

    def interact(self):
        it = self.nearest_interactable()
        if not it:
            return
        if it['kind'] == 'ramen':
            self.hp, self.chakra = self.max_hp, self.max_chakra
            state.hud.message('Sıcak bir kase miso ramen... Can ve chakra doldu!', '#ffd08a')
        elif it['kind'] == 'swing':
            self.on_swing = True
            self.position = it['pos'] + Vec3(0, .4, 0)
            self.vel = Vec3(0, 0, 0)
            state.hud.message('Salıncakta sallanıyorsun... (Ctrl ile kalk)', '#cccccc')

    def nearest_interactable(self):
        for it in state.interactables:
            if (it['pos'] - self.position).length() < it['radius']:
                return it
        return None

    # ------------------------------------------------------------ güncelleme
    def update(self):
        if application.paused:
            return
        dt = min(time.dt, 1 / 20)
        if mouse.locked and self.mouse_look:
            self.yaw += mouse.velocity[0] * 140
            self.pitch = max(-60, min(75, self.pitch - mouse.velocity[1] * 100))
        self.busy -= dt
        self.punch_cd -= dt
        self.combo_t -= dt
        self.wall_cd -= dt

        # chakra toplama
        self.charging = held_keys['c'] and self.grounded and not self.wall and mouse.locked
        self.aura.enabled = self.charging
        if self.charging:
            self.chakra = min(self.max_chakra, self.chakra + 35 * dt)
            s = 1 + math.sin(time.time() * 12) * .08
            self.aura.scale = Vec3(1.6, 2.4, 1.6) * s
        else:
            self.chakra = min(self.max_chakra, self.chakra + 3 * dt)

        if self.on_swing:
            self.model_.rotation_x = math.sin(time.time() * 2) * 25
            self.model_.animate(dt, 0, 'idle')
        elif self.wall:
            self.update_wall(dt)
        else:
            self.update_ground_air(dt)

        self.update_camera(dt)

    def update_ground_air(self, dt):
        phys = state.world.phys
        wish = self.wish_dir() if not self.charging else Vec3(0, 0, 0)
        running = (held_keys['left shift'] or held_keys['right shift']) and wish.length() > .1

        if self.rasen_dash > 0:
            self.rasen_dash -= dt
            self.vel = self.face_vec() * 28
            self.vel.y = 0
            p = self.position + Vec3(0, 1.2, 0) + self.face_vec() * .8
            for t in list(state.targets):
                if t.hit_test(p, .9):
                    t.take_damage(60, self.face_vec())
                    self._rasengan_end(p)
                    self.vel = self.face_vec() * -4
                    break
            if self.rasen_dash <= 0:
                self._rasengan_end(p)
        elif self.dash_t > 0:
            self.dash_t -= dt
        else:
            target_speed = RUN if running else WALK
            hv = Vec3(self.vel.x, 0, self.vel.z)
            want = wish * target_speed
            accel = 12 if self.grounded else 3.5
            if not self.grounded and wish.length() < .1:
                want = hv  # havada momentumu koru
            hv = hv + (want - hv) * min(1, accel * dt)
            self.vel.x, self.vel.z = hv.x, hv.z
            self.vel.y -= GRAV * dt

        p = self.position + self.vel * dt
        contacts = phys.resolve(p, self.body.radius, self.body.height)

        # tavan
        ceil = phys.ceiling(p.x, p.z, self.body.radius, p.y + self.body.height)
        if p.y + self.body.height > ceil and self.vel.y > 0:
            p.y = ceil - self.body.height
            self.vel.y = 0

        fl = phys.floor(p.x, p.z, self.body.radius, max(p.y, self.y))
        was_grounded = self.grounded
        if p.y <= fl + .02 and self.vel.y <= 0:
            if fl - p.y > .05 and was_grounded:
                p.y = self.y + (fl - self.y) * min(1, dt * 18)  # basamak çıkışı yumuşak
                if fl - p.y < .05:
                    p.y = fl
            else:
                p.y = fl
            self.vel.y = 0
            self.grounded = True
            self.jumps = 0
            self.air_dash = True
        else:
            self.grounded = False
        self.position = p

        # duvara yapışma (Shinobi Striker tarzı)
        if contacts and self.wall_cd <= 0 and self.rasen_dash <= 0:
            for nx, nz, col in contacts:
                n = Vec3(nx, 0, nz)
                tall = col.y1 - self.y > 1.6
                into = wish.dot(-n)
                if tall and into > .45 and (running or not self.grounded or self.dash_t > 0):
                    self.wall = (nx, nz)
                    self.vel = Vec3(0, 0, 0)
                    self.grounded = False
                    self.air_dash = True
                    break

        hv = Vec3(self.vel.x, 0, self.vel.z)
        sp = hv.length()
        if sp > .5 and self.rasen_dash <= 0 and self.dash_t <= 0:
            self.facing = lerp_angle(self.facing, math.degrees(math.atan2(hv.x, hv.z)), dt * 14)
        self.model_.rotation = (0, self.facing, 0)
        if self.charging:
            mode = 'charge'
        elif not self.grounded:
            mode = 'air'
        else:
            mode = 'run' if running else 'ground'
        self.model_.animate(dt, sp, mode)

    def update_wall(self, dt):
        phys = state.world.phys
        nx, nz = self.wall
        n = Vec3(nx, 0, nz)
        side = Vec3(nz, 0, -nx)
        wish = self.wish_dir()
        up_amt = wish.dot(-n)  # duvara doğru basmak = yukarı
        side_amt = wish.dot(side)
        run = held_keys['left shift'] or held_keys['right shift']
        spd = WALL_SPEED * (1.35 if run else 1)
        move = Vec3(0, up_amt, 0) * spd + side * side_amt * spd
        self.chakra = max(0, self.chakra - (7 if move.length() > .1 else 3) * dt)
        if self.chakra <= 0:
            self.leave_wall(push=2)
            state.hud.message('Chakra bitti, duvardan düştün!', '#7fd0ff')
            return

        p = self.position + move * dt
        # duvara bastır, temas devam ediyor mu?
        probe = p - n * .25
        contacts = phys.resolve(probe, self.body.radius, self.body.height)
        touching = None
        for cx, cz, col in contacts:
            if Vec3(cx, 0, cz).dot(n) > .3 or touching is None:
                touching = (cx, cz, col)
        if touching:
            p = probe
            cx, cz, col = touching
            self.wall = (cx, cz)  # köşeleri dönebilsin
            # duvarın tepesi: üstüne fırla
            if p.y + 1.0 > col.y1 and up_amt > .2:
                self.leave_wall()
                self.vel = -n * 6
                self.vel.y = 9
                self.position = Vec3(p.x, col.y1 - .9, p.z)
                return
        else:
            # duvar bitti (kenar). yukarı gidiyorsak üste tırman
            if up_amt > .2:
                self.vel = -n * 6
                self.vel.y = 8
            self.leave_wall()
            self.position = p
            return
        fl = phys.floor(p.x, p.z, self.body.radius, p.y)
        if p.y <= fl and up_amt < -.2:
            p.y = fl
            self.leave_wall()
            self.position = p
            self.grounded = True
            return
        p.y = max(p.y, fl)
        self.position = p

        # görsel: ayaklar duvarda, gövde duvara dik
        fwd = move.normalized() if move.length() > .1 else Vec3(0, 1, 0)
        base = -n * (self.body.radius - .05)
        self.model_.setPos(base)
        self.model_.lookAt(base + fwd, n)
        self.model_.animate(dt, move.length(), 'wall')

    def leave_wall(self, push=0):
        if self.wall:
            nx, nz = self.wall
            self.vel = Vec3(nx, 0, nz) * push
        self.wall = None
        self.wall_cd = .25
        self.model_.rotation = (0, self.facing, 0)
        self.model_.position = (0, 0, 0)

    def update_camera(self, dt):
        target = self.position + Vec3(0, 1.7, 0)
        self.pivot.position = self.pivot.position + (target - self.pivot.position) * min(1, dt * 15)
        self.pivot.rotation = (self.pitch, self.yaw, 0)
        # kamera duvarın içine girmesin
        back = -self.pivot.forward
        hit = state.world.phys.raycast(self.pivot.position, back, self.dist)
        d = self.dist if not hit else max(1.0, hit[0] - .35)
        cz = camera.z + (-d - camera.z) * min(1, dt * 12)
        camera.position = (0, 0, cz)
