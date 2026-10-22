class_name CatNPC
extends CharacterBody3D
## Kayıp kedi Mikan: yaklaşınca kaçar, duvarlara tırmanır. [F] ile yakala.

var vis: Node3D
var t = 0.0
var flee = Vector3.ZERO
var ambient = false   # köydeki gezgin kedi/köpek (yakalanmaz)
var is_dog = false


func _ready() -> void:
	if not ambient:
		add_to_group("catchables")
	collision_layer = 0
	collision_mask = 1
	var cs = CollisionShape3D.new()
	var sh = SphereShape3D.new()
	sh.radius = 0.25
	cs.shape = sh
	cs.position.y = 0.25
	add_child(cs)
	vis = MeshInstance3D.new()
	var b = MB.new()
	var c = Color(0.95, 0.6, 0.25)
	if ambient:
		c = [Color(0.95, 0.6, 0.25), Color(0.2, 0.2, 0.22), Color(0.9, 0.9, 0.9), Color(0.6, 0.55, 0.5)].pick_random()
	if is_dog:
		c = [Color(0.85, 0.75, 0.55), Color(0.3, 0.25, 0.2), Color(0.95, 0.95, 0.92)].pick_random()
		b.add("sphere", Vector3(0, 0.45, 0), Vector3(0.38, 0.36, 0.75), c, Vector3.ZERO, 10)
		b.add("sphere", Vector3(0, 0.65, -0.42), Vector3(0.3, 0.28, 0.32), c, Vector3.ZERO, 10)
		b.add("box", Vector3(0, 0.6, -0.6), Vector3(0.14, 0.12, 0.16), c.darkened(0.2))
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(0.12 * sx, 0.78, -0.4), Vector3(0.08, 0.14, 0.04), c.darkened(0.25))
			for sz in [-0.22, 0.22]:
				b.add("cyl", Vector3(0.12 * sx, 0.18, sz), Vector3(0.09, 0.36, 0.09), c, Vector3.ZERO, 6)
		b.add("cyl", Vector3(0, 0.58, 0.45), Vector3(0.06, 0.35, 0.06), c, Vector3(-50, 0, 0), 5)
		vis.mesh = b.build(Props.toon())
		add_child(vis)
		return
	b.add("sphere", Vector3(0, 0.3, 0), Vector3(0.3, 0.28, 0.55), c, Vector3.ZERO, 10)
	b.add("sphere", Vector3(0, 0.45, -0.3), Vector3(0.25, 0.23, 0.23), c, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		b.add("cone", Vector3(0.07 * sx, 0.6, -0.3), Vector3(0.08, 0.1, 0.06), c, Vector3.ZERO, 4)
	b.add("cyl", Vector3(0, 0.45, 0.35), Vector3(0.05, 0.4, 0.05), c, Vector3(-40, 0, 0), 5)
	if not ambient:
		b.add("box", Vector3(0, 0.42, -0.13), Vector3(0.22, 0.04, 0.04), Color(0.8, 0.15, 0.2))  # kurdele
	vis.mesh = b.build(Props.toon())
	add_child(vis)


func _physics_process(dt: float) -> void:
	t += dt
	velocity.y -= 30.0 * dt
	var pl = Game.player
	if ambient:
		pl = null
	if pl and pl.global_position.distance_to(global_position) < 9.0:
		flee = (global_position - pl.global_position)
		flee.y = 0
		flee = flee.normalized() * 9.0
	elif fmod(t, 3.0) < dt:
		flee = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 2.0
	velocity.x = flee.x; velocity.z = flee.z
	move_and_slide()
	if is_on_wall():
		velocity.y = 6.0
	var g = Game.ground_height(global_position.x, global_position.z)
	if global_position.y < g:
		global_position.y = g; velocity.y = 0
	if flee.length() > 0.1:
		vis.rotation.y = atan2(-flee.x, -flee.z) + PI


func catch() -> void:
	Hud.dialog("Mikan", "Miyaaav! (Kediyi yakaladın, çizik içindesin ama görev tamam.)", [])
	Missions.on_cat_caught()
	queue_free()
