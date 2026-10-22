class_name Fighter
extends CharacterBody3D
## NPC savaşçılarının tabanı (düşmanlar, klonlar, çağrılar): kapsül hitbox (boyuta göre), arazi takibi,
## hasar/sersemleme/savrulma, durum etkileri, animasyon.

var team = "enemy"
var radius = 0.38
var height = 1.8
var size = 1.0
var max_hp = 100.0
var hp = 100.0
var element = ""
var power = 1.0
var model: CharacterModel
var look = {}
var facing = 0.0
var grounded = true
var state = "idle"
var state_t = 0.0
var statuses = {}  # ad -> kalan süre
var dead = false
var poise = 0.0  # süper zırh (boss)


func _ready() -> void:
	add_to_group("fighters")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	_build_body()


func _build_body() -> void:
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = radius * size
	cap.height = maxf(height * size, cap.radius * 2.0 + 0.01)
	cs.shape = cap
	cs.position.y = height * size * 0.5
	add_child(cs)
	radius *= size
	height *= size
	if model == null and look != null:
		model = CharacterModel.new()
		add_child(model)
		model.setup(look)
		model.scale = Vector3.ONE * size


func is_dead() -> bool:
	return dead


func face_dir() -> Vector3:
	return Vector3(-sin(facing), 0, -cos(facing))


func apply_status(name: String, dur: float) -> void:
	statuses[name] = maxf(statuses.get(name, 0.0), dur)


func has_status(name: String) -> bool:
	return statuses.get(name, 0.0) > 0.0


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	var dmg: float = info.get("dmg", 5.0) * Combat.element_mult(info.get("element", ""), element)
	hp -= dmg
	model.flash(0.9)
	var col = Color(1, 0.9, 0.3) if info.get("kind", "light") == "light" else Color(1, 0.55, 0.2)
	Combat.damage_number(global_position + Vector3.UP * (height + 0.3), dmg, col, info.get("kind", "") == "heavy")
	if info.get("burn", 0.0) > 0.0:
		apply_status("burn", info["burn"])
	if info.get("stun", 0.0) > 0.0:
		apply_status("stun", info["stun"])
	on_damaged(info)
	if hp <= 0.0:
		hp = 0.0
		die(info)
		return
	var dir: Vector3 = info.get("dir", Vector3.ZERO)
	var heavy: bool = info.get("kind", "light") == "heavy" or info.get("launch", 0.0) > 0.0
	if poise > 0.0 and not heavy:
		return
	state_t = 0.0
	if heavy and size < 2.5:
		state = "knockdown"
		velocity = dir * info.get("knock", 8.0) / size + Vector3.UP * (info.get("launch", 0.0) + 3.0)
		model.play("knock", 0.05, 1.2, true)
	else:
		state = "hitstun"
		velocity = dir * info.get("knock", 2.0) / size
		model.play("hit" if randf() < 0.5 else "hit_head", 0.04, 1.4, true)


func on_damaged(_info: Dictionary) -> void:
	pass


func die(_info: Dictionary) -> void:
	dead = true
	state = "dead"
	model.play("death", 0.1)
	collision_layer = 0
	remove_from_group("fighters")
	var tw = create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func(): FX.smoke_puff(global_position + Vector3.UP * 0.5, 0.8, 10))
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(queue_free)


func stagger(t: float) -> void:
	state = "hitstun"
	state_t = -t
	model.play("hit", 0.05, 0.8, true)


## Hareket + arazi; wish: istenen yatay hız
func step_move(wish: Vector3, dt: float, turn := true) -> void:
	var slow = 0.45 if has_status("slow") else 1.0
	var hv = Vector3(velocity.x, 0, velocity.z)
	if state in ["hitstun", "knockdown", "dead"]:
		hv = hv.move_toward(Vector3.ZERO, dt * (8.0 if state == "knockdown" else 25.0))
	else:
		hv = hv.lerp(wish * slow, minf(1.0, dt * 10.0))
	velocity.x = hv.x; velocity.z = hv.z
	velocity.y -= 32.0 * dt
	move_and_slide()
	var g = Game.ground_height(global_position.x, global_position.z)
	var snap = maxf(0.3, hv.length() * dt * 1.6)
	if grounded and velocity.y <= 0 and global_position.y > g and global_position.y - g < snap:
		global_position.y = g
	if global_position.y <= g and velocity.y <= 0:
		global_position.y = g
		velocity.y = 0
		grounded = true
	else:
		grounded = is_on_floor()
	if turn and hv.length() > 0.5 and state not in ["hitstun", "knockdown", "dead"]:
		facing = lerp_angle(facing, atan2(-hv.x, -hv.z), minf(1.0, dt * 10.0))
	model.rotation.y = facing


func tick_status(dt: float) -> void:
	for k in statuses.keys():
		statuses[k] -= dt
		if statuses[k] <= 0.0:
			statuses.erase(k)
	if has_status("burn"):
		hp -= 4.0 * dt
		if randf() < dt * 8.0:
			FX.burst(global_position + Vector3.UP * randf_range(0.3, height), {"amount": 3, "life": 0.5, "size": 0.6, "vmin": 1, "vmax": 2, "gravity": Vector3(0, 3, 0),
				"colors": [Color(1, 0.8, 0.3, 1), Color(1, 0.3, 0.05, 0)]})
		if hp <= 0.0 and not dead:
			die({})
