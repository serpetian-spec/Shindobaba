class_name EdoWarrior
extends Fighter
## Edo Tensei ile diriltilmiş ninja: çatlak gri ten, siyah göz akı. Sahibinin yanında savaşır;
## yok edilemez — ağır hasarda kâğıt külüne dağılır, 3 sn sonra yeniden birleşir. Süre bitince toprağa döner.

var owner_f: Node3D = null
var life := 30.0
var tgt: Node3D = null
var cd := 0.0
var crumbled := 0.0
var jutsu_cd := 3.0


static func edo_look(i: int) -> Dictionary:
	var lk = CharacterModel.default_look()
	lk.merge({"skin": Color(0.62, 0.6, 0.58), "eye": Color(0.12, 0.1, 0.1), "gender": ["m", "f"][i % 2],
		"hair_style": ["uzun", "dağınık", "atkuyruğu", "kısa"][i % 4], "hair": [Color(0.12, 0.1, 0.1), Color(0.75, 0.75, 0.78)][i % 2],
		"top": Color(0.2, 0.2, 0.24), "top2": Color(0.3, 0.28, 0.3), "pants": Color(0.18, 0.18, 0.2), "band": Color(0.3, 0.3, 0.32),
		"band_style": "slashed", "vest": null}, true)
	return lk


func _ready() -> void:
	max_hp = 260.0
	hp = max_hp
	super._ready()
	if team == "":
		team = "player"
	FX.burst(global_position + Vector3.UP, {"amount": 24, "life": 0.7, "size": 0.5, "vmin": 2, "vmax": 6,
		"colors": [Color(0.9, 0.88, 0.8), Color(0.5, 0.45, 0.4, 0)]})


func is_dead() -> bool:
	return dead or crumbled > 0.0


func take_hit(info: Dictionary) -> void:
	if dead or crumbled > 0.0:
		return
	var dmg = float(info.get("dmg", 5.0))
	hp -= dmg
	model.flash(0.6)
	Combat.damage_number(global_position + Vector3.UP * (height + 0.3), dmg, Color(0.8, 0.78, 0.7), false)
	# kâğıt kırıntısı: yaralar hemen kapanır gibi
	FX.burst(global_position + Vector3.UP * 1.1, {"amount": 6, "life": 0.4, "size": 0.25, "vmin": 1, "vmax": 4,
		"colors": [Color(0.95, 0.93, 0.85), Color(0.6, 0.55, 0.5, 0)]})
	if hp <= 0.0:
		_crumble()


func _crumble() -> void:
	crumbled = 3.0
	model.visible = false
	collision_layer = 0
	FX.burst(global_position + Vector3.UP, {"amount": 40, "life": 0.9, "size": 0.45, "vmin": 2, "vmax": 8,
		"colors": [Color(0.95, 0.93, 0.85), Color(0.4, 0.38, 0.35, 0)]})
	Combat.popup_text(global_position + Vector3.UP * 2.4, "Kül oldu... yeniden birleşiyor", Color(0.85, 0.82, 0.75))


func _reform() -> void:
	hp = max_hp
	model.visible = true
	collision_layer = 4
	FX.burst(global_position + Vector3.UP, {"amount": 30, "life": 0.6, "size": 0.4, "vmin": -6, "vmax": -2,
		"colors": [Color(0.95, 0.93, 0.85), Color(0.5, 0.45, 0.4, 0)]})


func vanish() -> void:
	if dead:
		return
	dead = true
	FX.smoke_puff(global_position + Vector3.UP, 1.0, 14)
	FX.dust(global_position, 1.0)
	queue_free()


func _physics_process(dt: float) -> void:
	if Game.paused:
		return
	life -= dt
	cd -= dt
	jutsu_cd -= dt
	if life <= 0.0:
		vanish()
		return
	if crumbled > 0.0:
		crumbled -= dt
		if crumbled <= 0.0:
			_reform()
		return
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead():
		tgt = Combat.nearest_enemy(self, 32.0)
	if tgt:
		var v = tgt.global_position - global_position
		v.y = 0
		var d = v.length() - tgt.radius - radius
		facing = atan2(-v.x, -v.z)
		# diriltilmiş ninja jutsu da kullanır: kara ateş topu
		if d > 6.0 and d < 20.0 and jutsu_cd <= 0.0:
			jutsu_cd = randf_range(4.0, 6.0)
			model.play("throw", 0.05, 1.4, true)
			var s = global_position + Vector3.UP * 1.4
			var pr = Projectile.new()
			pr.shooter = self
			pr.vel = (tgt.global_position + Vector3.UP - s).normalized() * 34.0
			pr.radius = 0.9
			pr.life = 1.4
			pr.info = {"dmg": 18.0 * power, "knock": 8.0, "kind": "heavy", "burn": 3.0, "hitstop": 0.05}
			pr.add_child(VFX.fireball(1.2, "black"))
			get_tree().current_scene.add_child(pr)
			pr.global_position = s
			return
		if d > 1.3:
			step_move(v.normalized() * 12.0, dt, false)
			model.play("run", 0.1, 1.2)
		else:
			step_move(Vector3.ZERO, dt, false)
			if cd <= 0.0:
				cd = 0.55
				model.play(["jab", "cross", "hook", "slash_a"].pick_random(), 0.05, 1.4, true)
				var pt = global_position + Vector3.UP * 1.1 + face_dir() * (radius + 0.8)
				if not Combat.hit_sphere(self, pt, 0.9, {"dmg": 11.0 * power, "knock": 3.0, "kind": "light"}).is_empty():
					FX.hit_spark(pt, Color(0.85, 0.8, 0.7), 0.7)
					Sfx.play("punch", pt)
					if tgt is Enemy:
						tgt.target = self
	elif owner_f and is_instance_valid(owner_f):
		var v = owner_f.global_position - global_position
		v.y = 0
		if v.length() > 4.5:
			step_move(v.normalized() * 11.0, dt)
			model.play("run", 0.15)
		else:
			step_move(Vector3.ZERO, dt)
			model.play("idle", 0.2)
