class_name Summon
extends Fighter
## Kuchiyose: dev hayvan. Büyük kapsül hitbox (boyuta göre) - duvarlara/karakterlere girmez.

var kind = "kurbağa"
var life = 30.0
var cd = 1.0
var tgt: Node3D = null
var body_mesh: MeshInstance3D


func _ready() -> void:
	look = {}
	match kind:
		"kurbağa":
			radius = 3.2; height = 7.0; max_hp = 400.0
		"yılan":
			radius = 2.4; height = 4.5; max_hp = 300.0
		"sümüklü":
			radius = 2.8; height = 5.0; max_hp = 350.0
		_:
			radius = 1.2; height = 2.2; max_hp = 200.0
	hp = max_hp
	add_to_group("fighters")
	collision_layer = 4
	collision_mask = 1 | 4
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = radius
	cap.height = maxf(height, radius * 2.0 + 0.1)
	cs.shape = cap
	cs.position.y = height * 0.5
	add_child(cs)
	body_mesh = MeshInstance3D.new()
	body_mesh.mesh = _make_mesh()
	add_child(body_mesh)


func _make_mesh() -> ArrayMesh:
	var b = MB.new()
	match kind:
		"kurbağa":
			var c = Color(0.85, 0.42, 0.25)
			b.add("sphere", Vector3(0, 3.6, 0), Vector3(7.5, 5.6, 8.0), c, Vector3.ZERO, 16)
			b.add("sphere", Vector3(0, 2.2, -2.6), Vector3(6.0, 3.0, 3.6), Color(0.95, 0.85, 0.6), Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				b.add("sphere", Vector3(2.0 * sx, 6.4, -2.8), Vector3(1.8, 1.8, 1.8), Color(0.95, 0.9, 0.5), Vector3.ZERO, 12)
				b.add("box", Vector3(2.0 * sx, 6.4, -3.65), Vector3(1.2, 0.35, 0.1), Color(0.1, 0.08, 0.08))
				b.add("sphere", Vector3(3.2 * sx, 1.0, -2.0), Vector3(2.2, 2.0, 3.0), c.darkened(0.1), Vector3.ZERO, 10)
				b.add("sphere", Vector3(3.4 * sx, 1.2, 2.2), Vector3(2.6, 2.4, 3.6), c.darkened(0.1), Vector3.ZERO, 10)
			b.add("box", Vector3(0, 6.2, 1.5), Vector3(6.5, 0.6, 4.0), Color(0.25, 0.3, 0.45), Vector3(-15, 0, 0))  # pelerin
			b.add("cyl", Vector3(1.5, 4.0, -3.8), Vector3(0.4, 2.5, 0.4), Color(0.35, 0.25, 0.18), Vector3(70, 0, 0), 8)  # pipo
		"yılan":
			var c = Color(0.5, 0.38, 0.65)
			for i in 10:
				b.add("sphere", Vector3(sin(i * 0.7) * 2.0, 1.4 + (2.6 if i == 0 else 0.0), i * 2.2), Vector3(3.0, 2.8, 3.0) * (1.0 - i * 0.05), c.darkened((i % 2) * 0.1), Vector3.ZERO, 12)
			b.add("box", Vector3(0, 4.2, -1.6), Vector3(2.6, 0.4, 1.2), Color(0.9, 0.85, 0.3))
		"sümüklü":
			var c = Color(0.9, 0.93, 0.97)
			b.add("sphere", Vector3(0, 2.5, 0), Vector3(5.6, 5.0, 9.0), c, Vector3.ZERO, 16)
			b.add("box", Vector3(0, 3.0, 0), Vector3(5.7, 0.6, 7.0), Color(0.4, 0.55, 0.85))
			for sx in [-1.0, 1.0]:
				b.add("cyl", Vector3(1.0 * sx, 5.8, -3.6), Vector3(0.4, 2.0, 0.4), c, Vector3(-20, 0, 0), 8)
		_:
			var c = Color(0.55, 0.42, 0.3)
			b.add("sphere", Vector3(0, 1.2, 0), Vector3(1.4, 1.4, 2.6), c, Vector3.ZERO, 10)
			b.add("sphere", Vector3(0, 1.8, -1.5), Vector3(1.0, 1.0, 1.2), c, Vector3.ZERO, 10)
	return b.build(Props.toon())


func is_dead() -> bool:
	return dead


func take_hit(info: Dictionary) -> void:
	hp -= info.get("dmg", 5.0)
	Combat.damage_number(global_position + Vector3.UP * (height + 0.5), info.get("dmg", 5.0), Color(1, 0.8, 0.5))
	if hp <= 0.0:
		_end()


func _end() -> void:
	if dead:
		return
	dead = true
	FX.smoke_puff(global_position + Vector3.UP * 3.0, 4.0, 40)
	queue_free()


func _physics_process(dt: float) -> void:
	if Game.paused or dead:
		return
	life -= dt
	cd -= dt
	if life <= 0.0:
		_end()
		return
	velocity.y -= 32.0 * dt
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead():
		tgt = Combat.nearest_enemy(self, 45.0)
	var wish = Vector3.ZERO
	if tgt:
		var v = tgt.global_position - global_position
		v.y = 0
		facing = atan2(-v.x, -v.z)
		if v.length() > radius + tgt.radius + 4.0:
			wish = v.normalized() * 9.0
		elif cd <= 0.0:
			cd = 2.2
			_attack()
	elif Game.player:
		var v = Game.player.global_position - global_position
		v.y = 0
		if v.length() > 12.0:
			wish = v.normalized() * 9.0
	velocity.x = wish.x; velocity.z = wish.z
	move_and_slide()
	var g = Game.ground_height(global_position.x, global_position.z)
	if global_position.y < g:
		global_position.y = g
		velocity.y = 0
	body_mesh.rotation.y = facing + PI


func _attack() -> void:
	var front = global_position + Vector3(-sin(facing), 0, -cos(facing)) * (radius + 2.0)
	match kind:
		"kurbağa":
			# zıplayıp ezme
			var tw = create_tween()
			tw.tween_property(body_mesh, "position:y", 4.0, 0.3).set_ease(Tween.EASE_OUT)
			tw.tween_property(body_mesh, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
			tw.tween_callback(func():
				FX.impact(front, Color(1, 0.8, 0.5), 2.0)
				Combat.hit_sphere(self, front + Vector3.UP, 5.5, {"dmg": 35.0, "knock": 18.0, "launch": 8.0, "kind": "heavy", "hitstop": 0.08})
				Sfx.play("boom", front, 0.7))
		"yılan":
			FX.hit_spark(front + Vector3.UP * 2, Color(0.8, 0.5, 1), 1.5)
			Combat.hit_sphere(self, front + Vector3.UP * 1.5, 3.5, {"dmg": 28.0, "knock": 8.0, "kind": "heavy", "stun": 1.5})
		"sümüklü":
			if Game.player:
				Game.player.hp = minf(Game.player.max_hp, Game.player.hp + 25.0)
				FX.aura(Game.player, Color(0.5, 1, 0.6), 1.0)
				Sfx.play("heal", Game.player.global_position)
		_:
			Combat.hit_sphere(self, front + Vector3.UP, 2.0, {"dmg": 14.0, "knock": 4.0, "kind": "light"})
