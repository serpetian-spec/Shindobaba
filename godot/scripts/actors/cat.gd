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
	# detaylı model (TownAnimals): kedi tekir / calico / smokin / siyah..., köpek shiba / akita / kurt köpeği; bacaklar ve kuyruk salınır
	var rng = RandomNumberGenerator.new()
	rng.seed = get_instance_id() * 7919 + Time.get_ticks_usec()   # her hayvan farklı tüy rengi
	var d: Dictionary = TownAnimals.dog(rng) if is_dog else TownAnimals.cat(rng, not ambient)
	vis = d["root"]
	add_child(vis)
	legs = d["legs"]
	tail = d["tail"]


var legs: Array = []
var tail: Node3D = null


func _process(_dt: float) -> void:
	# yürüyüş: çapraz bacak salınımı hızla orantılı, kuyruk sallanır
	var spd = Vector2(velocity.x, velocity.z).length()
	var ph = t * (6.0 + spd * 1.6)
	for i in legs.size():
		var lg: Node3D = legs[i]
		lg.rotation.x = sin(ph + (PI if i in [1, 2] else 0.0)) * clampf(spd * 0.12, 0.0, 0.55)
	if tail:
		tail.rotation.z = sin(t * (3.0 if not is_dog else 9.0)) * (0.25 if not is_dog else 0.35)


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
		vis.rotation.y = atan2(-flee.x, -flee.z)   # yeni model önü -z: kafa gidilen yöne


func catch() -> void:
	if not Missions.active().is_empty() and Missions._cur().get("kind", "") == "cat":
		MissionWork.I().catch_cat(self)   # çömel, kavra, omza al
		return
	Hud.dialog("Mikan", "Miyaaav! (Kediyi yakaladın, çizik içindesin ama görev tamam.)", [])
	Missions.on_cat_caught()
	queue_free()
