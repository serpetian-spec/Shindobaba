extends Node3D
## Vahşi hayvanlar: oyuncunun çevresinde biyoma göre sürüler (geyik, yaban domuzu, tilki, tavşan, turna).
## Otlar, dolaşır, yaklaşınca kaçar; uzaklaşınca silinir. Basit prosedürel modeller, bacaklar sinüsle yürür.

const MAX_HERDS := 5
const SPAWN_MIN := 140.0
const SPAWN_MAX := 420.0
const DESPAWN := 650.0
## biyom -> olası hayvanlar
const BY_BIOME := {2: ["geyik", "geyik", "domuz", "tilki"], 7: ["geyik", "tavşan", "tilki", "tavşan"], 6: ["turna", "tavşan"],
	4: ["domuz", "tilki"], 10: ["turna", "domuz"], 5: ["geyik", "tilki"], 9: ["geyik"], 8: ["tilki", "tavşan"], 3: ["tilki"]}

var _t := 0.0


func _process(dt: float) -> void:
	if Game.player == null:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = 2.0
	var p = Game.player.global_position
	for h in get_children():
		if h.global_position.distance_to(p) > DESPAWN:
			h.queue_free()
	if get_child_count() >= MAX_HERDS:
		return
	for tries in 6:
		var a = randf() * TAU
		var r = randf_range(SPAWN_MIN, SPAWN_MAX)
		var x = p.x + cos(a) * r
		var z = p.z + sin(a) * r
		var b = Game.biome_at(x, z)
		var kinds = BY_BIOME.get(b)
		if kinds == null or Game.road_at(x, z) > 0.0 or Game.terrain_height(x, z) < 0.5:
			continue
		var herd = Herd.new()
		herd.kind = kinds.pick_random()
		herd.position = Vector3(x, Game.terrain_height(x, z), z)
		add_child(herd)
		return


class Herd extends Node3D:
	var kind := "geyik"
	var animals: Array = []

	func _ready() -> void:
		var n = {"geyik": randi_range(3, 6), "domuz": randi_range(2, 4), "tilki": 1, "tavşan": randi_range(2, 4), "turna": randi_range(3, 5)}[kind]
		for i in n:
			var an = Animal.new()
			an.kind = kind
			an.home = global_position
			add_child(an)
			an.global_position = global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))


class Animal extends Node3D:
	var kind := "geyik"
	var home := Vector3.ZERO
	var goal := Vector3.ZERO
	var speed := 0.0
	var wait := 0.0
	var legs: Array = []
	var phase := randf() * TAU
	var body: Node3D
	var flee := 0.0
	var size := 1.0
	var run_speed := 9.0

	func _ready() -> void:
		body = Node3D.new()
		add_child(body)
		var b = MB.new()
		var c: Color
		var leg_h := 0.8
		var leg_r := 0.09
		var leg_x := 0.22
		var leg_z := 0.5
		match kind:
			"geyik":   # sika / Nara geyiği (ref Sika_deer.jpg + anime Nara ormanı): ince uzun bacak, yukarı boyun, dallı boynuz
				c = Color(0.62, 0.4, 0.22)
				var belly = Color(0.9, 0.82, 0.68)
				var dk = c.darkened(0.25)
				leg_h = 0.86; leg_z = 0.46; leg_x = 0.14; leg_r = 0.045
				b.add_grad("sphere", Vector3(0, 1.12, 0.02), Vector3(0.46, 0.5, 1.2), c, c.lerp(belly, 0.45), Vector3.ZERO, 12)   # gövde (karın biraz açık)
				b.add_grad("sphere", Vector3(0, 1.16, -0.38), Vector3(0.44, 0.58, 0.55), c, c.lerp(belly, 0.35), Vector3.ZERO, 10)   # göğüs
				b.add_grad("sphere", Vector3(0, 1.18, 0.4), Vector3(0.44, 0.54, 0.54), c, c.darkened(0.1), Vector3.ZERO, 10)   # sağrı
				b.add("cyl", Vector3(0, 1.5, -0.6), Vector3(0.2, 0.62, 0.24), c, Vector3(-38, 0, 0), 8)   # boyun
				b.add("sphere", Vector3(0, 1.38, -0.56), Vector3(0.2, 0.26, 0.22), c.lerp(belly, 0.5), Vector3.ZERO, 8)   # boğaz
				b.add("sphere", Vector3(0, 1.8, -0.8), Vector3(0.22, 0.24, 0.32), c, Vector3(-10, 0, 0), 10)   # kafa
				b.add("sphere", Vector3(0, 1.74, -0.98), Vector3(0.13, 0.13, 0.24), c.lightened(0.05), Vector3(-15, 0, 0), 8)   # burun
				b.add("sphere", Vector3(0, 1.72, -1.09), Vector3(0.07, 0.06, 0.05), Color(0.08, 0.07, 0.07), Vector3.ZERO, 6)
				for sx in [-1.0, 1.0]:
					b.add("sphere", Vector3(0.1 * sx, 1.85, -0.87), Vector3(0.045, 0.05, 0.04), Color(0.06, 0.05, 0.05), Vector3.ZERO, 6)   # göz
					b.add("sphere", Vector3(0.16 * sx, 1.93, -0.74), Vector3(0.07, 0.19, 0.1), c, Vector3(10, 0, 55 * sx), 6)   # kulak
					# boynuz: ana dal yukarı-geri-dışa, önde bir çatal, tepede ikiye ayrılır
					var ac = Color(0.72, 0.62, 0.48)
					b.add("cyl", Vector3(0.1 * sx, 2.16, -0.74), Vector3(0.04, 0.42, 0.04), ac, Vector3(14, 0, -16 * sx), 5)
					b.add("cyl", Vector3(0.12 * sx, 2.12, -0.83), Vector3(0.028, 0.22, 0.028), ac, Vector3(-45, 0, -8 * sx), 4)
					b.add("cyl", Vector3(0.18 * sx, 2.44, -0.66), Vector3(0.028, 0.24, 0.028), ac, Vector3(25, 0, -30 * sx), 4)
					b.add("cyl", Vector3(0.14 * sx, 2.46, -0.76), Vector3(0.026, 0.22, 0.026), ac, Vector3(-25, 0, -12 * sx), 4)
				b.add("sphere", Vector3(0, 1.22, 0.66), Vector3(0.24, 0.28, 0.1), Color(0.97, 0.95, 0.92), Vector3.ZERO, 8)   # beyaz kuyruk lekesi
				b.add("sphere", Vector3(0, 1.3, 0.7), Vector3(0.08, 0.16, 0.06), dk, Vector3(20, 0, 0), 6)   # kısa kuyruk
				run_speed = 12.0
			"domuz":   # yaban domuzu (ref Wild_boar.jpg): yüksek omuz kamburu, alçak sağrı, uzun kama kafa, yassı burun diski, sırt yelesi
				c = Color(0.3, 0.26, 0.22)
				var dk2 = Color(0.16, 0.14, 0.13)
				leg_h = 0.44; leg_z = 0.38; leg_x = 0.16; leg_r = 0.055
				b.add_grad("sphere", Vector3(0, 0.74, 0.05), Vector3(0.6, 0.66, 1.2), c, dk2, Vector3.ZERO, 12)   # gövde
				b.add_grad("sphere", Vector3(0, 0.84, -0.3), Vector3(0.62, 0.78, 0.62), c.lightened(0.04), dk2, Vector3.ZERO, 10)   # omuz kamburu
				b.add_grad("sphere", Vector3(0, 0.7, 0.45), Vector3(0.52, 0.56, 0.5), c, dk2, Vector3.ZERO, 10)   # sağrı
				b.add_grad("sphere", Vector3(0, 0.7, -0.68), Vector3(0.36, 0.42, 0.5), c, dk2, Vector3(12, 0, 0), 10)   # kafa (kama)
				b.add("cone", Vector3(0, 0.6, -0.98), Vector3(0.24, 0.42, 0.22), c.darkened(0.08), Vector3(-100, 0, 0), 8)   # uzun burun
				b.add("cyl", Vector3(0, 0.57, -1.18), Vector3(0.15, 0.05, 0.13), Color(0.42, 0.34, 0.32), Vector3(80, 0, 0), 10)   # burun diski
				for sx in [-1.0, 1.0]:
					b.add("sphere", Vector3(0.035 * sx, 0.57, -1.205), Vector3(0.03, 0.03, 0.02), Color(0.08, 0.06, 0.06), Vector3.ZERO, 5)   # burun deliği
					b.add("sphere", Vector3(0.13 * sx, 0.79, -0.82), Vector3(0.04, 0.035, 0.03), Color(0.05, 0.04, 0.04), Vector3.ZERO, 5)   # göz
					b.add("cone", Vector3(0.13 * sx, 0.98, -0.6), Vector3(0.09, 0.18, 0.05), dk2, Vector3(-10, 0, -15 * sx), 5)   # dik kulak
					b.add("cone", Vector3(0.09 * sx, 0.56, -1.04), Vector3(0.025, 0.12, 0.025), Color(0.95, 0.92, 0.84), Vector3(-25, 0, -25 * sx), 4)   # diş
				for k in 8:   # sırt yelesi: omuzdan sağrıya diken diken kıl
					var z = -0.6 + k * 0.14
					b.add("cone", Vector3(0, 1.17 - absf(z + 0.3) * 0.22, z), Vector3(0.1, 0.16, 0.1), dk2, Vector3(15, 0, 0), 4)
				b.add("cyl", Vector3(0, 0.66, 0.72), Vector3(0.03, 0.3, 0.03), dk2, Vector3(25, 0, 0), 4)   # ince kuyruk
				b.add("sphere", Vector3(0, 0.53, 0.78), Vector3(0.06, 0.1, 0.05), dk2, Vector3.ZERO, 5)
				run_speed = 8.0
			"tilki":
				c = Color(0.9, 0.45, 0.15)
				leg_h = 0.32; leg_z = 0.25; leg_x = 0.1; leg_r = 0.05
				b.add("sphere", Vector3(0, 0.45, 0), Vector3(0.3, 0.3, 0.7), c, Vector3.ZERO, 8)
				b.add("sphere", Vector3(0, 0.55, -0.4), Vector3(0.22, 0.2, 0.3), c, Vector3.ZERO, 8)
				b.add("cone", Vector3(0, 0.55, -0.6), Vector3(0.1, 0.18, 0.1), c, Vector3(-90, 0, 0), 5)
				for sx in [-1.0, 1.0]:
					b.add("cone", Vector3(0.08 * sx, 0.72, -0.38), Vector3(0.07, 0.14, 0.05), c.darkened(0.2), Vector3.ZERO, 4)
				b.add("sphere", Vector3(0, 0.5, 0.5), Vector3(0.16, 0.16, 0.5), c, Vector3(25, 0, 0), 6)
				b.add("sphere", Vector3(0, 0.45, 0.75), Vector3(0.1, 0.1, 0.14), Color(0.98, 0.96, 0.92), Vector3.ZERO, 5)
				run_speed = 10.0
			"tavşan":
				c = Color(0.75, 0.68, 0.58)
				leg_h = 0.12; leg_z = 0.1; leg_x = 0.07; leg_r = 0.04
				b.add("sphere", Vector3(0, 0.2, 0), Vector3(0.24, 0.22, 0.32), c, Vector3.ZERO, 8)
				b.add("sphere", Vector3(0, 0.3, -0.16), Vector3(0.15, 0.15, 0.16), c, Vector3.ZERO, 6)
				for sx in [-1.0, 1.0]:
					b.add("sphere", Vector3(0.04 * sx, 0.46, -0.14), Vector3(0.04, 0.18, 0.06), c, Vector3.ZERO, 5)
				run_speed = 9.0
			"turna":
				c = Color(0.95, 0.95, 0.95)
				leg_h = 0.8; leg_z = 0.0; leg_x = 0.08; leg_r = 0.025
				b.add("sphere", Vector3(0, 1.05, 0), Vector3(0.35, 0.35, 0.65), c, Vector3.ZERO, 8)
				b.add("cyl", Vector3(0, 1.45, -0.25), Vector3(0.06, 0.6, 0.06), c, Vector3(-20, 0, 0), 5)
				b.add("sphere", Vector3(0, 1.75, -0.32), Vector3(0.1, 0.1, 0.14), Color(0.85, 0.1, 0.1), Vector3.ZERO, 5)
				b.add("cone", Vector3(0, 1.73, -0.45), Vector3(0.03, 0.18, 0.03), Color(0.3, 0.3, 0.3), Vector3(-90, 0, 0), 4)
				b.add("sphere", Vector3(0, 1.0, 0.35), Vector3(0.25, 0.15, 0.3), Color(0.12, 0.12, 0.14), Vector3.ZERO, 6)
				run_speed = 7.0
		var mi = MeshInstance3D.new()
		mi.mesh = b.build(Props.toon())
		body.add_child(mi)
		for sx in [-1.0, 1.0]:
			for sz in ([-leg_z, leg_z] if leg_z > 0.0 else [0.0]):
				var pivot = Node3D.new()
				pivot.position = Vector3(leg_x * sx, leg_h, sz)
				body.add_child(pivot)
				var lb = MB.new()
				var lc = c.darkened(0.25) if kind != "turna" else Color(0.2, 0.2, 0.2)
				if kind in ["geyik", "domuz"]:
					# üst bacak (kas) + ince alt bacak + toynak; arka bacakta kalça kası
					lb.add("cyl", Vector3(0, -leg_h * 0.22, 0), Vector3(leg_r * 2.2, leg_h * 0.48, leg_r * 2.4), c.darkened(0.08), Vector3.ZERO, 6)
					lb.add("cyl", Vector3(0, -leg_h * 0.7, 0.0), Vector3(leg_r * 1.6, leg_h * 0.5, leg_r * 1.6), lc, Vector3(-4 if sz > 0 else 4, 0, 0), 5)
					lb.add("cyl", Vector3(0, -leg_h + 0.04, 0), Vector3(leg_r * 2.0, 0.08, leg_r * 2.4), Color(0.1, 0.08, 0.07), Vector3.ZERO, 6)
					if sz > 0:
						lb.add("sphere", Vector3(-signf(sx) * leg_r * 0.6, 0.02, 0.02), Vector3(leg_r * 2.8, leg_h * 0.36, leg_r * 3.4), c, Vector3.ZERO, 7)
				else:
					lb.add("cyl", Vector3(0, -leg_h * 0.5, 0), Vector3(leg_r * 2.0, leg_h, leg_r * 2.0), lc, Vector3.ZERO, 5)
				var lm = MeshInstance3D.new()
				lm.mesh = lb.build(Props.toon())
				pivot.add_child(lm)
				legs.append([pivot, 0.0 if (sx > 0) == (sz > 0) else PI])
		goal = global_position

	func _process(dt: float) -> void:
		if Game.paused:
			return
		var pl = Game.player
		var p = global_position
		if pl:
			var d = p.distance_to(pl.global_position)
			if d < 22.0 and flee <= 0.0:
				flee = 4.0
				var away = (p - pl.global_position)
				away.y = 0
				goal = p + away.normalized() * 60.0
			if d > 120.0:
				# uzaktayken sadece yere otur (ucuz)
				return
		flee -= dt
		var v = goal - p
		v.y = 0
		var spd = run_speed if flee > 0.0 else 1.3
		if v.length() < 1.0:
			if wait <= 0.0:
				wait = randf_range(2.0, 7.0)
			wait -= dt
			speed = move_toward(speed, 0.0, dt * 6.0)
			if wait <= 0.0:
				goal = home + Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))
		else:
			speed = move_toward(speed, spd, dt * 8.0)
			var dir = v.normalized()
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, dt * 6.0))
			p += dir * speed * dt
		p.y = Game.terrain_height(p.x, p.z)
		global_position = p
		phase += dt * (2.0 + speed * 2.2)
		var swing = clampf(speed / 3.0, 0.0, 1.0) * 0.7
		for lg in legs:
			lg[0].rotation.x = sin(phase + lg[1]) * swing
		body.position.y = absf(sin(phase)) * 0.05 * swing
		# otlama: dururken baş eğik
		body.rotation.x = -0.12 if speed < 0.2 and kind in ["geyik", "domuz"] else 0.0
