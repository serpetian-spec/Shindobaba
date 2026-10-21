class_name CatNPC
extends CharacterBody3D
## Kayıp kedi Mikan: yaklaşınca kaçar, duvarlara tırmanır. [F] ile yakala.

var vis: Node3D
var t = 0.0
var flee = Vector3.ZERO


func _ready() -> void:
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
	b.add("sphere", Vector3(0, 0.3, 0), Vector3(0.3, 0.28, 0.55), c, Vector3.ZERO, 10)
	b.add("sphere", Vector3(0, 0.45, -0.3), Vector3(0.25, 0.23, 0.23), c, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		b.add("cone", Vector3(0.07 * sx, 0.6, -0.3), Vector3(0.08, 0.1, 0.06), c, Vector3.ZERO, 4)
	b.add("cyl", Vector3(0, 0.45, 0.35), Vector3(0.05, 0.4, 0.05), c, Vector3(-40, 0, 0), 5)
	b.add("box", Vector3(0, 0.42, -0.13), Vector3(0.22, 0.04, 0.04), Color(0.8, 0.15, 0.2))  # kurdele
	vis.mesh = b.build(Props.toon())
	add_child(vis)


func _physics_process(dt: float) -> void:
	t += dt
	velocity.y -= 30.0 * dt
	var pl = Game.player
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
