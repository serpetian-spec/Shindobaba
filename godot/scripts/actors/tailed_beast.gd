class_name TailedBeast
extends Fighter
## Kuyruklu canavar boss'u: dev model (BeastRig), çok aşamalı saldırılar, zayıf noktalar, mühürleme.
## Öldürülemez: canı %8'e inince diz çöker → 30 sn içinde [F] ile mühürlenmeli, yoksa toparlanır.

const PHASE2 := 0.66
const PHASE3 := 0.33
const SUBDUE := 0.08

var id = ""
var info := {}
var rig: BeastRig
var display_name = ""
var phase = 1
var aggro = false
var home := Vector3.ZERO
var atk = ""
var atk_t = 0.0
var atk_dur = 1.0
var atk_hit = false
var atk_cd = 3.0
var subdued = false
var subdued_t = 0.0
var seal_item := {}
var ball: Node3D = null
var roam_t = 0.0
var roam_goal := Vector3.ZERO
var num = 1
var cam_set = false


func setup(beast_id: String) -> void:
	id = beast_id
	info = BeastModels.INFO.get(id, BeastModels.INFO["kurama"])
	num = int(info["num"])
	display_name = info["name"]
	team = "enemy"
	look = null
	element = info["element"]
	height = float(info["height"])
	radius = height * 0.24
	size = 1.0
	max_hp = 3000.0 + num * 1300.0 + (6000.0 if id == "kurama" else 0.0)
	hp = max_hp
	power = 2.5 + num * 0.35
	poise = 99.0


func _build_body() -> void:
	# dev gövde: kapsül yerine model + tırmanılabilir parça çarpıştırıcıları
	rig = BeastModels.build(id, height)
	add_child(rig)


func _ready() -> void:
	add_to_group("fighters")
	add_to_group("tailed_beasts")
	collision_layer = 0
	collision_mask = 0
	_build_body()
	home = global_position
	roam_goal = home
	global_position.y = Game.ground_height(global_position.x, global_position.z)


func take_hit(inf: Dictionary) -> void:
	if dead:
		return
	var dmg: float = inf.get("dmg", 5.0) * Combat.element_mult(inf.get("element", ""), element)
	# zayıf nokta: saldıran bir mühür noktasına yakınsa (tırmanıp vurmak) x3
	var atk_node = inf.get("attacker")
	if atk_node is Node3D and is_instance_valid(atk_node):
		for w in rig.weak_points:
			if is_instance_valid(w) and atk_node.global_position.distance_to(w.global_position) < maxf(6.0, height * 0.12):
				dmg *= 3.0
				Combat.popup_text(w.global_position + Vector3.UP * 2.0, "ZAYIF NOKTA!", Color(1, 0.85, 0.3))
				FX.impact(w.global_position, Color(1, 0.9, 0.4), 1.5)
				break
	if subdued:
		dmg = 0.0
	hp = maxf(max_hp * SUBDUE, hp - dmg)
	if not aggro:
		_start_fight()
	Combat.damage_number(global_position + Vector3.UP * height * 0.6, dmg, Color(1, 0.7, 0.3))
	Hud.boss_bar(self)
	if hp <= max_hp * SUBDUE + 0.01 and not subdued:
		_subdue()


func is_dead() -> bool:
	return dead


## İsabet testi: gövde kapsülü + tırmanma kutuları + zayıf noktalar (başa/sırta çıkıp vurmak da sayılır)
func hit_test(point: Vector3, extra: float) -> bool:
	var base = global_position
	var r = height * 0.2
	var y = clampf(point.y, base.y + r, base.y + height * 0.6)
	if point.distance_to(Vector3(base.x, y, base.z)) <= r + extra:
		return true
	for mk in rig.colliders:
		if not is_instance_valid(mk):
			continue
		var sz: Vector3 = (mk.get_meta("size") as Vector3) * rig.design_scale() * 0.5 + Vector3.ONE * (extra + 1.0)
		var lp = mk.global_transform.orthonormalized().affine_inverse() * point
		if absf(lp.x) <= sz.x and absf(lp.y) <= sz.y and absf(lp.z) <= sz.z:
			return true
	for w in rig.weak_points:
		if is_instance_valid(w) and point.distance_to(w.global_position) < extra + 4.0:
			return true
	return false


func _start_fight() -> void:
	aggro = true
	Hud.boss_bar(self)
	Hud.banner(display_name, "Kuyruklu Canavar uyandı! Zayıf noktalara (altın mühürler) tırman ve vur.", info["chakra"])
	Sfx.play("roar", global_position, 0.6)
	_begin("roar", 1.8)
	if Game.player and not cam_set:
		cam_set = true
		Game.player.set_meta("beast_cam", Game.player.cam_dist)
		Game.player.cam_dist = maxf(Game.player.cam_dist, clampf(height * 0.12, 8.0, 16.0))


func _end_fight() -> void:
	aggro = false
	Hud.boss_bar(null)
	if cam_set and Game.player and is_instance_valid(Game.player):
		Game.player.cam_dist = float(Game.player.get_meta("beast_cam", 5.5))
	cam_set = false


func _physics_process(dt: float) -> void:
	if dead or Game.paused:
		return
	var pl = Game.player
	if pl == null:
		return
	for k in statuses.keys():
		statuses[k] -= dt
		if statuses[k] <= 0.0:
			statuses.erase(k)
	var to = pl.global_position - global_position
	to.y = 0
	var dist = to.length()
	if subdued:
		subdued_t -= dt
		if not seal_item.is_empty():
			seal_item["pos"] = pl.global_position if dist < height * 0.7 else global_position
		if subdued_t <= 0.0:
			_recover()
		return
	if not aggro:
		# sakin dolaşma
		roam_t -= dt
		if roam_t <= 0.0:
			roam_t = randf_range(8.0, 16.0)
			roam_goal = home + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * height * 1.5
		_walk_to(roam_goal, dt, 0.35)
		if dist < maxf(220.0, height * 2.5) and Engine.get_process_frames() % 20 == 0:
			_start_fight()
		return
	if dist > maxf(900.0, height * 10.0):
		_end_fight()
		return
	# yöne dön
	var want = atan2(-to.x, -to.z)
	facing = lerp_angle(facing, want, minf(1.0, dt * (0.6 if atk == "" else 0.2)))
	rig.rotation.y = facing
	# fazlar
	var hpf = hp / max_hp
	if phase == 1 and hpf < PHASE2:
		phase = 2
		Hud.banner(display_name, "ÖFKELENDİ — Kuyruklu Canavar Topu!", Color(1, 0.35, 0.25))
		_begin("roar", 1.6)
	elif phase == 2 and hpf < PHASE3:
		phase = 3
		Hud.banner(display_name, "ÇILGINLIK — chakra taşıyor!", Color(1, 0.2, 0.2))
		_begin("roar", 1.6)
	# saldırı yürüt
	if atk != "":
		atk_t += dt
		_run_attack(dt)
		if atk_t >= atk_dur:
			atk = ""
			atk_cd = randf_range(1.6, 3.2) / (1.0 + (phase - 1) * 0.35)
		return
	atk_cd -= dt
	if dist > height * 0.75:
		_walk_to(pl.global_position, dt, 1.0)
	else:
		rig.move_speed = move_toward(rig.move_speed, 0.0, dt * 2.0)
	if atk_cd <= 0.0:
		_choose(dist)


func _walk_to(p: Vector3, dt: float, mul: float) -> void:
	var d = p - global_position
	d.y = 0
	if d.length() < 3.0:
		rig.move_speed = move_toward(rig.move_speed, 0.0, dt * 2.0)
		return
	var spd = clampf(height * 0.09, 4.0, 14.0) * mul
	global_position += d.normalized() * spd * dt
	global_position.y = Game.ground_height(global_position.x, global_position.z)
	if not aggro:
		facing = lerp_angle(facing, atan2(-d.x, -d.z), minf(1.0, dt * 0.8))
		rig.rotation.y = facing
	rig.move_speed = move_toward(rig.move_speed, mul, dt * 2.0)


func _choose(dist: float) -> void:
	var opts = []
	if dist < height * 0.8:
		opts += ["stomp", "swipe", "tail", "swipe", "elem"]
	else:
		opts += ["elem", "elem", "elem", "roar"]
	if phase >= 2:
		opts += ["ball", "elem"]
	if phase >= 3:
		opts += ["minions", "ball"]
	_begin(opts.pick_random(), 0.0)


func _begin(a: String, dur: float) -> void:
	atk = a
	atk_t = 0.0
	atk_hit = false
	var d = dur
	match a:
		"stomp":
			d = 1.5; rig.play_action("stomp", d)
		"swipe":
			d = 1.2; rig.play_action(["swipe_l", "swipe_r"].pick_random(), d)
		"tail":
			d = 2.0; rig.play_action("tail", d)
		"roar":
			d = maxf(d, 1.6); rig.play_action("roar", d)
		"elem":
			d = 1.6; rig.play_action("charge" if id in ["kokuo", "chomei", "isobu", "matatabi"] else "roar", d)
		"ball":
			d = 3.4; rig.play_action("ball", d)
			_ball_start()
		"minions":
			d = 1.6; rig.play_action("roar", d)
	atk_dur = d


func _dmg(base: float) -> float:
	return base * (1.0 + num * 0.12) * (1.0 + (phase - 1) * 0.25)


func _run_attack(_dt: float) -> void:
	var k = atk_t / atk_dur
	var fwd = face_dir()
	match atk:
		"stomp":
			if k > 0.55 and not atk_hit:
				atk_hit = true
				var c = global_position
				Combat.hit_sphere(self, c + Vector3.UP * 2.0, height * 0.45, {"dmg": _dmg(28.0), "knock": 26.0, "launch": 9.0, "kind": "heavy", "element": "doton"})
				_shockwave(c, height * 0.9)
		"swipe":
			if k > 0.42 and not atk_hit:
				atk_hit = true
				var pt = global_position + fwd * height * 0.45 + Vector3.UP * height * 0.15
				BijuuArts.melee(self, id, pt, height * 0.28, _dmg(34.0), fwd)   # canavara özgü pençe: kum, mavi alev, lav, asit...
				Sfx.play("whoosh", pt, 0.5)
		"tail":
			if k > 0.35 and not atk_hit:
				atk_hit = true
				Combat.hit_sphere(self, global_position + Vector3.UP * height * 0.2, height * 0.75, {"dmg": _dmg(30.0), "knock": 34.0, "launch": 8.0, "kind": "heavy"})
				FX.ring(global_position + Vector3.UP * height * 0.2, info["chakra"], height * 1.5, 0.6)
				Sfx.play("whoosh", global_position, 0.35)
				if Game.world:
					Game.world.env.add_shake(0.8)
		"roar":
			if k > 0.25 and not atk_hit:
				atk_hit = true
				Sfx.play("roar", global_position, 0.55)
				Combat.hit_sphere(self, global_position + Vector3.UP * height * 0.4, height * 0.9, {"dmg": _dmg(10.0), "knock": 40.0, "launch": 10.0, "kind": "heavy"})
				FX.ring(rig.mouth_pos(), info["chakra"], height * 1.2, 0.7, false, fwd)
				if Game.world:
					Game.world.env.add_shake(1.2)
		"elem":
			if k > 0.5 and not atk_hit:
				atk_hit = true
				_element_attack()
		"ball":
			_ball_tick(k)
		"minions":
			if k > 0.4 and not atk_hit:
				atk_hit = true
				_minions()


## Yere vuruş: halka şok dalgası + krater izi
func _shockwave(c: Vector3, r: float) -> void:
	FX.ring(c + Vector3.UP * 0.5, Color(0.85, 0.75, 0.55), r, 0.7)
	FX.burst(c + Vector3.UP * 2.0, {"amount": 60, "life": 1.4, "tex": FX.tex_smoke, "add": false, "size": height * 0.15, "vmin": 6, "vmax": 18, "gravity": Vector3(0, -2, 0),
		"colors": [Color(0.75, 0.65, 0.5, 0.9), Color(0.6, 0.55, 0.45, 0.0)]})
	_crater(c, r * 0.35)
	Sfx.play("boom", c, 0.5)
	if Game.world:
		Game.world.env.add_shake(1.5)


func _crater(c: Vector3, r: float) -> void:
	var dc = Decal.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d = Vector2(x - 32, y - 32).length() / 32.0
			var a = clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.18, 0.13, 0.08, a * 0.85 * (0.7 + 0.3 * sin(d * 18.0))))
	dc.texture_albedo = ImageTexture.create_from_image(img)
	dc.size = Vector3(r * 2.0, 20.0, r * 2.0)
	get_tree().current_scene.add_child(dc)
	dc.global_position = c
	var tw = dc.create_tween()
	tw.tween_interval(40.0)
	tw.tween_property(dc, "modulate:a", 0.0, 6.0)
	tw.tween_callback(dc.queue_free)


## Canavara özel teknik (BijuuArts): Renkūdan, mercan, lav fışkırması, asit baloncukları, mürekkep, chakra kolu...
func _element_attack() -> void:
	var pl = Game.player
	var dist = (pl.global_position - global_position).length()
	# teknik ölçeği: dev ama oyuncunun ekranını kaplamayacak kadar (alan teknikleri oyuncunun çevresine iner)
	var ts = clampf(height / 14.0, 2.0, 3.5)
	var key = BijuuArts.pick_key(id, dist, ts)
	if key != "":
		var td = BijuuArts.tech(id, key)
		BijuuArts.use(self, id, key, {"s": ts, "dmg": _dmg(30.0), "from": rig.mouth_pos(), "aim": pl.global_position + Vector3.UP, "tgt": pl, "col": info["chakra"]})
		Combat.popup_text(rig.mouth_pos() + Vector3.UP * 6.0, String(td.get("name", "")), info["chakra"].lightened(0.3))
		Sfx.play("roar", rig.mouth_pos(), 0.8, 0.5)
		return
	_element_attack_old()


func _element_attack_old() -> void:
	var pl = Game.player
	var from = rig.mouth_pos()
	var aim = (pl.global_position + Vector3.UP - from).normalized()
	var ch: Color = info["chakra"]
	match id:
		"shukaku":  # rüzgar: sıkıştırılmış hava mermisi + kum saçması
			for i in 3:
				_proj(from, (aim + Vector3(randf_range(-0.08, 0.08), 0, randf_range(-0.08, 0.08))).normalized(), 60.0, height * 0.06, "fuuton", Color(0.9, 0.8, 0.55), _dmg(26.0))
		"matatabi":  # mavi kedi alevi topları
			for i in 4:
				_proj(from, (aim + Vector3(randf_range(-0.12, 0.12), randf_range(-0.05, 0.05), 0)).normalized(), 48.0, height * 0.07, "katon", Color(0.3, 0.45, 1.0), _dmg(24.0))
		"isobu":  # su kütlesi mermisi + mercan tuzağı
			_proj(from, aim, 50.0, height * 0.1, "suiton", Color(0.4, 0.7, 1.0), _dmg(34.0))
			pl.apply_status("slow", 3.0)
		"son_goku":  # lav bombaları (yay çizerek)
			for i in 6:
				var tgt = pl.global_position + Vector3(randf_range(-12, 12), 0, randf_range(-12, 12))
				var pr = _proj(from, Vector3.ZERO, 0.0, height * 0.045, "yoton", Color(1.0, 0.4, 0.05), _dmg(22.0))
				var t = 1.6 + randf() * 0.6
				pr.gravity = 20.0
				pr.vel = (tgt - from) / t + Vector3.UP * 20.0 * t * 0.5
		"kokuo":  # buharla güçlenmiş boynuz hücumu
			var d = (pl.global_position - global_position)
			d.y = 0
			var dist = d.length()
			var tw = create_tween()
			var end = global_position + d.normalized() * minf(dist + 10.0, height * 2.0)
			end.y = Game.ground_height(end.x, end.z)
			tw.tween_property(self, "global_position", end, 0.6)
			tw.tween_callback(func():
				Combat.hit_sphere(self, global_position + face_dir() * height * 0.4 + Vector3.UP * height * 0.3, height * 0.35, {"dmg": _dmg(40.0), "knock": 40.0, "launch": 10.0, "kind": "heavy", "element": "futton"})
				FX.burst(global_position + Vector3.UP * height * 0.3, {"amount": 50, "life": 1.5, "tex": FX.tex_smoke, "add": false, "size": height * 0.12, "vmin": 4, "vmax": 12,
					"colors": [Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)]}))
		"saiken":  # aşındırıcı sümük alanı
			_field(pl.global_position, height * 0.25, Color(0.75, 0.95, 0.85), 7.0, _dmg(6.0), "suiton")
		"chomei":  # pul tozu: görüşü bulandırır + hücum
			_field(pl.global_position, height * 0.3, Color(0.9, 1.0, 0.6), 5.0, _dmg(5.0), "fuuton")
			if Game.world:
				Game.world.env.set_tint(Color(0.85, 1.0, 0.5, 0.25))
				get_tree().create_timer(3.0).timeout.connect(func():
					if Game.world: Game.world.env.set_tint(Color(0, 0, 0, 0)))
		"gyuki":  # mürekkep püskürtme (görüş kararır) + dokunaç
			_field(pl.global_position, height * 0.2, Color(0.05, 0.03, 0.08), 6.0, _dmg(8.0), "suiton")
			if Game.world:
				Game.world.env.set_tint(Color(0, 0, 0, 0.55))
				get_tree().create_timer(2.5).timeout.connect(func():
					if Game.world: Game.world.env.set_tint(Color(0, 0, 0, 0)))
			Combat.hit_sphere(self, global_position + face_dir() * height * 0.5, height * 0.3, {"dmg": _dmg(30.0), "knock": 20.0, "kind": "heavy"})
		_:  # kurama: art arda küçük canavar topları
			for i in 3:
				get_tree().create_timer(i * 0.3).timeout.connect(func():
					if dead or Game.player == null: return
					var a2 = (Game.player.global_position + Vector3.UP - rig.mouth_pos()).normalized()
					var b = TailedBeasts.fire_ball(self, rig.mouth_pos(), a2, height * 0.035, ch, _dmg(30.0), 70.0)
					b.homing = Game.player
					b.homing_turn = 0.4)
	Sfx.play("roar", from, 0.8, 0.5)


func _proj(from: Vector3, dir: Vector3, spd: float, r: float, el: String, col: Color, dmg: float) -> Projectile:
	var pr = Projectile.new()
	pr.shooter = self
	pr.vel = dir * spd
	pr.radius = maxf(1.0, r)
	pr.life = 4.0
	pr.info = {"dmg": dmg, "element": el, "knock": 18.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.06}
	pr.add_child(Projectile.energy_mesh(col.lightened(0.4), col, maxf(1.5, r * 2.0), 6.0, 0.0, 2.0))
	pr.on_hit = func(pos: Vector3, _t: Node3D) -> void:
		FX.explosion(pos, maxf(1.0, r * 0.6), col)
		Combat.hit_sphere(self, pos, maxf(4.0, r * 2.5), {"dmg": dmg * 0.5, "element": el, "knock": 14.0, "kind": "heavy"}, pr.hit_list)
	get_tree().current_scene.add_child(pr)
	pr.global_position = from
	return pr


## Hasar veren zemin alanı (sümük, toz, mürekkep)
func _field(c: Vector3, r: float, col: Color, dur: float, dps: float, el: String) -> void:
	var n = Node3D.new()
	get_tree().current_scene.add_child(n)
	n.global_position = c
	FX.ring(c + Vector3.UP * 0.3, col, r * 2.0, 0.6)
	var cloud = FX.burst(c + Vector3.UP * 2.0, {"amount": 50, "life": dur, "tex": FX.tex_smoke, "add": false, "size": r * 0.5, "vmin": 0.5, "vmax": 2.0, "gravity": Vector3.ZERO,
		"colors": [Color(col.r, col.g, col.b, 0.75), Color(col.r, col.g, col.b, 0.0)]})
	var t = {"v": 0.0}
	var tm = Timer.new()
	tm.wait_time = 0.5
	tm.autostart = true
	n.add_child(tm)
	tm.timeout.connect(func():
		t["v"] += 0.5
		if is_instance_valid(self):
			Combat.hit_sphere(self, c + Vector3.UP, r, {"dmg": dps * 0.5, "element": el, "knock": 0.0, "kind": "light"})
		if t["v"] >= dur:
			n.queue_free())


# ------------------------------------------------------------------ Kuyruklu Canavar Topu
func _ball_start() -> void:
	ball = Node3D.new()
	rig.mouth.add_child(ball)
	ball.add_child(Projectile.energy_mesh(Color(0.25, 0.1, 0.35), Color(0.02, 0.0, 0.05), 3.0, 14.0, 0.0, 1.6))
	ball.scale = Vector3.ONE * 0.05
	Sfx.play("rasengan", rig.mouth_pos(), 0.4)
	Combat.popup_text(rig.mouth_pos() + Vector3.UP * 4.0, "Kuyruklu Canavar Topu!", Color(0.8, 0.5, 1.0))
	FX.burst(rig.mouth_pos(), {"amount": 80, "life": 2.5, "tex": FX.tex_spark, "add": true, "size": height * 0.03, "vmin": -10, "vmax": -4, "gravity": Vector3.ZERO,
		"colors": [Color(0.7, 0.4, 1.0, 0.9), Color(0.2, 0.0, 0.4, 0.0)]})


func _ball_tick(k: float) -> void:
	if ball and is_instance_valid(ball):
		var s = minf(1.0, k / 0.8) * height * 0.04
		ball.scale = Vector3.ONE * maxf(0.05, s)
	if k > 0.8 and not atk_hit:
		atk_hit = true
		if ball and is_instance_valid(ball):
			ball.queue_free()
		var pl = Game.player
		var from = rig.mouth_pos()
		var aim = (pl.global_position + Vector3.UP - from).normalized()
		TailedBeasts.fire_ball(self, from, aim, height * 0.07, info["chakra"], _dmg(110.0), 75.0)


func _minions() -> void:
	for i in 2 + phase:
		var e = Enemy.new()
		var a = Enemy.archetype("rogue", i)
		a["name"] = "%s Chakra Klonu" % display_name.split(" — ")[0]
		a["hp"] = 160.0 + num * 30.0
		a["power"] = 2.0
		a["xp"] = 60
		a["ryo"] = 0
		a["respawn"] = false
		a["element"] = element
		e.setup(a)
		get_tree().current_scene.add_child(e)
		var p = global_position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * height * 0.6
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		FX.smoke_puff(p + Vector3.UP, 1.5, 14)


# ------------------------------------------------------------------ boyun eğme / mühürleme
func _subdue() -> void:
	subdued = true
	subdued_t = 30.0 * (1.0 + Stats.skill(Game.profile, "fuin"))
	atk = ""
	if ball and is_instance_valid(ball):
		ball.queue_free()
	rig.play_action("kneel", 999.0)
	rig.move_speed = 0.0
	Hud.banner("%s DİZ ÇÖKTÜ" % display_name.split(" — ")[0].to_upper(), "30 saniye içinde yanına git ve [F] ile mühürle!", Color(1, 0.85, 0.4))
	seal_item = {"pos": global_position, "radius": height * 0.75, "kind": "beast_seal", "label": "Mühürle: %s" % display_name.split(" — ")[0], "beast": self}
	Interact.add(seal_item)


func _recover() -> void:
	subdued = false
	Interact.items.erase(seal_item)
	seal_item = {}
	hp = max_hp * 0.35
	phase = 3
	rig.play_action("roar", 1.8)
	Hud.banner(display_name, "Mühürlenmeden toparlandı!", Color(1, 0.3, 0.2))
	Hud.boss_bar(self)


## Mühürleme tamamlandı (TailedBeasts çağırır): girdap efektiyle kaybolur
func sealed_away(into: Node3D) -> void:
	dead = true
	Interact.items.erase(seal_item)
	_end_fight()
	var tgt = into.global_position + Vector3.UP if into else global_position
	for i in 6:
		get_tree().create_timer(i * 0.25).timeout.connect(func():
			FX.ring(global_position + Vector3.UP * height * 0.5, info["chakra"], height * (1.2 - i * 0.18), 0.4, false, Vector3.UP))
	FX.burst(global_position + Vector3.UP * height * 0.5, {"amount": 160, "life": 1.6, "tex": FX.tex_spark, "add": true, "size": height * 0.04, "vmin": 2, "vmax": 8, "gravity": (tgt - global_position).normalized() * 30.0,
		"colors": [info["chakra"], Color(1, 1, 1, 0)]})
	var tw = create_tween()
	tw.tween_property(rig, "scale", Vector3.ONE * 0.01, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func die(_inf: Dictionary) -> void:
	pass


func _exit_tree() -> void:
	if not seal_item.is_empty():
		Interact.items.erase(seal_item)
	if aggro:
		_end_fight()
