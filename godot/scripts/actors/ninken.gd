class_name Ninken
extends CharacterBody3D
## Inuzuka ninken'i: sahibini takip eder, en yakın düşmana saldırır. Küçük kapsül hitbox.

var team = "player"
var radius = 0.45
var height = 1.0
var max_hp = 140.0
var hp = 140.0
var dead = false
var owner_f: Node3D = null
var tgt: Node3D = null
var cd = 0.0
var facing = 0.0
var vis: Node3D
var parts := {}
var gait := 0.0
var drill_t = 0.0


func _ready() -> void:
	add_to_group("fighters")
	add_to_group("ninken")
	collision_layer = 4
	collision_mask = 1
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = radius
	cap.height = 1.0
	cs.shape = cap
	cs.position.y = 0.5
	add_child(cs)
	vis = Node3D.new()
	add_child(vis)
	# referans (Akamaru, Part II): kabarık krem-beyaz dev köpek, sarkık kahve kulaklar, kısık gözler (InuzukaModels)
	parts = InuzukaModels.akamaru(1.3)   # Part II: omzu Kiba'nın göğsüne gelir
	vis.add_child(parts["root"])


func is_dead() -> bool:
	return dead


func face_dir() -> Vector3:
	return Vector3(-sin(facing), 0, -cos(facing))


func apply_status(_n: String, _d: float) -> void:
	pass


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	var dmg: float = info.get("dmg", 5.0)
	hp -= dmg
	Combat.damage_number(global_position + Vector3.UP * 1.4, dmg, Color(1, 0.6, 0.5))
	if hp <= 0.0:
		dead = true
		FX.smoke_puff(global_position + Vector3.UP * 0.5, 0.7, 10)
		Hud.msg("Ninken yaralandı ve çekildi. (Jutsu ile tekrar çağır)", Color(0.9, 0.7, 0.6))
		queue_free()


func gatsuga(t: Node3D) -> void:
	tgt = t
	drill_t = 0.9


func _physics_process(dt: float) -> void:
	if Game.paused or dead:
		return
	cd -= dt
	velocity.y -= 30.0 * dt
	if owner_f == null or not is_instance_valid(owner_f):
		queue_free()
		return
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead():
		tgt = Combat.nearest_enemy(self, 25.0)
		if tgt and tgt.global_position.distance_to(owner_f.global_position) > 30.0:
			tgt = null
	var wish = Vector3.ZERO
	if drill_t > 0.0 and tgt:
		drill_t -= dt
		var v = tgt.global_position - global_position
		v.y = 0
		wish = v.normalized() * 24.0
		vis.rotation.z += dt * 30.0
		if Combat.hit_sphere(self, global_position + Vector3.UP * 0.6 + v.normalized() * 0.8, 1.2, {"dmg": 10.0 * Stats.melee_mult(Game.profile), "knock": 10.0, "launch": 4.0, "kind": "heavy"}).size() > 0:
			drill_t = 0.0
	else:
		vis.rotation.z = 0.0
		if tgt:
			var v = tgt.global_position - global_position
			v.y = 0
			var d = v.length() - tgt.radius - radius
			facing = atan2(-v.x, -v.z)
			if d > 0.9:
				wish = v.normalized() * 14.0
			elif cd <= 0.0:
				cd = 0.6
				var pt = global_position + Vector3.UP * 0.7 + v.normalized() * 0.9
				if not Combat.hit_sphere(self, pt, 0.8, {"dmg": 6.0 * Stats.melee_mult(Game.profile), "knock": 2.0, "kind": "light"}).is_empty():
					FX.hit_spark(pt, Color(1, 0.9, 0.7), 0.5)
					Sfx.play("punch", pt, 1.4, 0.6)
		else:
			var v = owner_f.global_position + owner_f.global_transform.basis.x * 1.8 - global_position
			v.y = 0
			if v.length() > 2.5:
				wish = v.normalized() * minf(16.0, v.length() * 3.0)
				facing = atan2(-v.x, -v.z)
			if v.length() > 60.0:
				global_position = owner_f.global_position + Vector3(2, 0, 0)
	velocity.x = wish.x; velocity.z = wish.z
	move_and_slide()
	# yürüyüş: hızla orantılı çapraz bacak salınımı, kuyruk sallanır
	var spd = Vector2(velocity.x, velocity.z).length()
	gait += dt * (3.0 + spd * 1.2)
	var mv = clampf(spd / 6.0, 0.0, 1.0)
	if parts.has("legs"):
		for i in parts["legs"].size():
			(parts["legs"][i] as Node3D).rotation.x = sin(gait) * 0.6 * mv * (1.0 if i % 2 == 0 else -1.0) * (1.0 if i < 2 else -1.0)
	if parts.get("tail"):
		(parts["tail"] as Node3D).rotation.z = sin(gait * 1.7) * 0.35
	var g = Game.ground_height(global_position.x, global_position.z)
	if global_position.y < g:
		global_position.y = g
		velocity.y = 0
	vis.rotation.y = facing
	if wish.length() > 1.0:
		vis.position.y = absf(sin(Time.get_ticks_msec() * 0.02)) * 0.12
