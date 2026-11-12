class_name Prey
extends Fighter
## Av hayvanı (av görevleri): Wildlife hayvanının vurulabilen hali.
## · Otlar, dolaşır; önünü görür (arkası kör), koşan ayak sesini duyar. Sessizce arkadan yaklaşılır ya da uzaktan vurulur.
## · Geyik / tavşan ürkünce kaçar, bir süre sonra yeniden otlar. Yaban domuzu döner, eşinir ve üstüne koşar (boynuz darbesi).
## · Ölünce yana devrilir ve yerde kalır: MissionWork avı omuza aldırır, askıya astırır.

const WL = preload("res://scripts/world/wildlife.gd")
const DEF := {
	"geyik": {"hp": 70.0, "r": 0.42, "h": 1.7, "see": 30.0, "hear": 16.0, "run": 11.5, "name": "Geyik"},
	"domuz": {"hp": 130.0, "r": 0.48, "h": 1.0, "see": 20.0, "hear": 12.0, "run": 9.5, "name": "Yaban Domuzu"},
	"tavşan": {"hp": 18.0, "r": 0.22, "h": 0.5, "see": 18.0, "hear": 12.0, "run": 9.0, "name": "Tavşan"}}

var kind := "domuz"
var display := "Yaban Domuzu"
var home := Vector3.ZERO
var an: Node3D            # Wildlife.Animal (yalnız görsel; kendi işlemesi kapalı)
var goal := Vector3.ZERO
var wait := 0.0
var spd := 0.0
var flee_t := 0.0
var charge_t := -1.0      # >= 0: saldırı (0..0.7 eşinme, sonra koşu)
var charge_dir := Vector3.ZERO
var charge_hit := false
var rest_t := 0.0         # saldırıdan sonra soluklanma (vurma fırsatı)
var phase := randf() * TAU
var on_dead := Callable()
var d: Dictionary


func _ready() -> void:
	look = null
	d = DEF.get(kind, DEF["domuz"])
	display = d["name"]
	radius = d["r"]
	height = d["h"]
	max_hp = d["hp"]
	hp = max_hp
	team = "enemy"
	add_to_group("fighters")
	add_to_group("prey")
	collision_layer = 4
	collision_mask = 1
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = radius
	cap.height = maxf(height, radius * 2.0 + 0.05)
	cs.shape = cap
	cs.position.y = cap.height * 0.5
	add_child(cs)
	an = WL.Animal.new()
	an.kind = kind
	add_child(an)
	an.set_process(false)
	home = global_position
	goal = home
	wait = randf_range(1.0, 4.0)
	facing = randf() * TAU
	rotation.y = facing


func is_dead() -> bool:
	return dead


func face_dir() -> Vector3:
	return Vector3(-sin(rotation.y), 0, -cos(rotation.y))


func _physics_process(dt: float) -> void:
	if dead or Game.paused or Game.player == null:
		return
	var pl = Game.player
	var p = global_position
	var to: Vector3 = pl.global_position - p
	to.y = 0
	var dist = to.length()
	if dist > 160.0:
		return
	var wish := Vector3.ZERO
	var speed_t := 0.0
	rest_t -= dt
	if charge_t >= 0.0:
		charge_t += dt
		if charge_t < 0.7:
			# eşinme: yüzünü döner, başını eğer, ön ayağıyla toprağı kazır
			charge_dir = to.normalized() if dist > 0.1 else face_dir()
			_turn(charge_dir, dt * 8.0)
			an.body.rotation.x = -0.22
			an.legs[0][0].rotation.x = sin(charge_t * 22.0) * 0.5
			if fmod(charge_t, 0.22) < dt:
				FX.burst(p - charge_dir * 0.3 + Vector3.UP * 0.05, {"amount": 5, "life": 0.4, "size": 0.07, "dir": -charge_dir + Vector3.UP * 0.6, "spread": 25.0, "vmin": 1.0, "vmax": 2.6, "gravity": Vector3(0, -8, 0), "colors": [Color(0.45, 0.36, 0.26, 1), Color(0.45, 0.36, 0.26, 0)]})
		else:
			wish = charge_dir
			speed_t = 13.0
			if not charge_hit and dist < radius + 1.0 and to.normalized().dot(charge_dir) > 0.3:
				charge_hit = true
				Combat.hit_sphere(self, p + charge_dir * 0.7 + Vector3.UP * 0.6, 0.9, {"dmg": 16.0, "knock": 9.0, "dir": charge_dir, "kind": "melee"})
			if charge_t > 2.1 or charge_hit and charge_t > 1.2:
				charge_t = -1.0
				rest_t = 2.6
	elif rest_t > 0.0:
		# soluklanır: yerinde durur, yanları inip kalkar
		an.body.scale.y = 1.0 + sin(rest_t * 9.0) * 0.03
	else:
		an.body.scale.y = 1.0
		if flee_t > 0.0:
			flee_t -= dt
		else:
			var fd = face_dir()
			var seen = dist < float(d["see"]) and fd.dot(to.normalized()) > -0.2
			var heard = dist < float(d["hear"]) and Vector2(pl.velocity.x, pl.velocity.z).length() > 4.6
			if seen or heard or dist < 1.6:
				_startle(to, dist)
		var v = goal - p
		v.y = 0
		if v.length() < 1.2:
			flee_t = minf(flee_t, 0.0)
			wait -= dt
			if wait <= 0.0:
				wait = randf_range(3.0, 8.0)
				goal = Missions.open_ground(home + Vector3(randf_range(-18, 18), 0, randf_range(-18, 18)), 8.0)
		else:
			wish = v.normalized()
			speed_t = float(d["run"]) if flee_t > 0.0 else 1.3
	spd = move_toward(spd, speed_t, dt * 14.0)
	if wish != Vector3.ZERO:
		_turn(wish, dt * 7.0)
		var veg = Game.world.vegetation if Game.world else null
		var np = p + wish * spd * dt
		if veg and veg.trunk_near(np.x, np.z, 0.45):
			var side = wish.rotated(Vector3.UP, PI * 0.5 * (1.0 if randf() < 0.5 else -1.0))
			if charge_t >= 0.0:
				charge_t = -1.0   # ağaca tosladı: sersemler
				rest_t = 3.2
				Sfx.play("hit", p, 0.7)
			else:
				goal = p + side * 14.0
			spd *= 0.4
	velocity = wish * spd + Vector3.DOWN * 12.0
	move_and_slide()
	var gh = Game.terrain_height(global_position.x, global_position.z)
	if global_position.y < gh:
		global_position.y = gh
	facing = rotation.y
	phase += dt * (2.0 + spd * 2.2)
	var swing = clampf(spd / 3.0, 0.0, 1.0) * 0.7
	if charge_t < 0.0 or charge_t >= 0.7:
		for lg in an.legs:
			lg[0].rotation.x = sin(phase + lg[1]) * swing
		an.body.rotation.x = -0.12 if spd < 0.2 and rest_t <= 0.0 and kind != "tavşan" else 0.0
	an.body.position.y = absf(sin(phase)) * 0.05 * swing


func _turn(dir: Vector3, k: float) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, k))


func _startle(to: Vector3, dist: float) -> void:
	if kind == "domuz" and dist < 16.0:
		_charge()
		return
	flee_t = 5.0
	var away = (-to).normalized() if dist > 0.1 else face_dir()
	var g = global_position + away.rotated(Vector3.UP, randf_range(-0.5, 0.5)) * 42.0
	# otlağından çok uzaklaşmaz: sınırı aştıysa yuvasının çevresinde döner
	if g.distance_to(home) > 75.0:
		g = home + (g - home).normalized() * 75.0
	goal = g
	wait = randf_range(4.0, 7.0)


func _charge() -> void:
	if charge_t >= 0.0:
		return
	charge_t = 0.0
	charge_hit = false
	flee_t = 0.0
	rest_t = 0.0


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	var dmg: float = info.get("dmg", 5.0)
	hp -= dmg
	Combat.damage_number(global_position + Vector3.UP * (height + 0.4), dmg, Color(1, 0.85, 0.6))
	FX.burst(global_position + Vector3.UP * height * 0.6, {"amount": 8, "life": 0.35, "size": 0.06, "vmin": 1.0, "vmax": 3.0, "gravity": Vector3(0, -9, 0), "colors": [Color(0.7, 0.08, 0.06, 1), Color(0.5, 0.05, 0.04, 0)]})
	var tw = an.create_tween()
	tw.tween_property(an, "position:y", 0.12, 0.05)
	tw.tween_property(an, "position:y", 0.0, 0.1)
	if hp <= 0.0:
		die(info)
		return
	var pl = Game.player
	var to: Vector3 = (pl.global_position - global_position) if pl else Vector3.FORWARD
	to.y = 0
	if kind == "domuz":
		if charge_t < 0.0:
			rest_t = 0.0
			_charge()
	else:
		flee_t = 0.0
		_startle(to, to.length())
		flee_t = 7.0


func stagger(_t: float) -> void:
	pass


func die(_info: Dictionary) -> void:
	if dead:
		return
	dead = true
	state = "dead"
	hp = 0.0
	collision_layer = 0
	collision_mask = 0
	remove_from_group("fighters")
	velocity = Vector3.ZERO
	an.body.scale.y = 1.0
	an.body.rotation.x = 0.0
	# yana devrilir, bacaklar gerilip kalır
	var side = 1.0 if randf() < 0.5 else -1.0
	var tw = an.create_tween().set_parallel(true)
	tw.tween_property(an, "rotation:z", deg_to_rad(84.0) * side, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(an, "position:y", radius * 0.75, 0.45)
	for lg in an.legs:
		tw.tween_property(lg[0], "rotation:x", 0.25 if lg[1] == 0.0 else -0.2, 0.5)
	Sfx.play("hit", global_position, 0.6)
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(self):
			FX.burst(global_position + Vector3.UP * 0.1, {"amount": 10, "life": 0.6, "size": 0.12, "vmin": 0.5, "vmax": 1.6, "gravity": Vector3(0, 0.5, 0), "colors": [Color(0.5, 0.42, 0.32, 0.7), Color(0.5, 0.42, 0.32, 0)]})
			if on_dead.is_valid():
				on_dead.call(self))
