class_name Player
extends CharacterBody3D
## Oyuncu: Shinobi Striker tarzı parkur + Storm tarzı dövüş girişleri.
## Ctrl/Space: zıpla, havada çift zıplama, duvarda -> duvardan sek.  Shift: ninja koşusu / havada dash.
## Duvara doğru koşmak = duvarda koşmaya başlar (ek tuş yok, chakra harcamaz).

signal died

const RUN := 11.0
const DASH := 19.0
const GRAV := 32.0
const JUMP := 13.5
const WALL_SPEED := 12.0
const AIR_DASH := 28.0

var model: CharacterModel
var cam_pivot: Node3D
var cam: Camera3D
var yaw = 0.0
var pitch = -12.0
var cam_dist = 5.5
var cam_cur_dist = 5.5
var radius = 0.38
var height = 1.8

var grounded = true
var jumps = 0
var air_dash_ok = true
var dash_t = 0.0
var wall_n = Vector3.ZERO  # 0 ise duvarda değil
var wall_cd = 0.0
var facing = 0.0
var on_water = false
var swimming = false
var land_t = 0.0
var input_locked = 0.0
var combat: Node = null  # Combat bileşeni (dövüş)

var team = "player"
var max_hp = 100.0
var hp = 100.0
var max_chakra = 100.0
var chakra = 100.0
var stamina = 100.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50)
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = radius
	cap.height = height
	cs.shape = cap
	cs.position.y = height * 0.5
	add_child(cs)
	model = CharacterModel.new()
	add_child(model)
	model.setup(Game.profile.get("look", {}) if not Game.profile.is_empty() else {})
	cam_pivot = Node3D.new()
	cam_pivot.top_level = true
	add_child(cam_pivot)
	cam = Camera3D.new()
	cam.fov = float(Game.settings["fov"])
	cam.far = 4000.0
	cam.near = 0.1
	cam_pivot.add_child(cam)
	cam.current = true
	Game.player = self
	add_to_group("fighters")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	yaw = 180.0


func apply_profile_stats() -> void:
	if Game.profile.is_empty():
		return
	max_hp = Stats.max_hp(Game.profile)
	max_chakra = Stats.max_chakra(Game.profile)
	hp = minf(hp, max_hp)
	chakra = minf(chakra, max_chakra)


# ------------------------------------------------------------------ girdi
func _unhandled_input(e: InputEvent) -> void:
	if Game.paused or Game.ui_open:
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s = 0.18 * float(Game.settings["sens"])
		yaw -= e.relative.x * s
		pitch -= e.relative.y * s * (-1.0 if Game.settings["invert_y"] else 1.0)
		pitch = clampf(pitch, -70, 60)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = maxf(2.2, cam_dist - 0.5)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = minf(14.0, cam_dist + 0.5)
	if e.is_action_pressed("jump"):
		_jump()
	elif e.is_action_pressed("dash"):
		if not grounded and not wall_n and air_dash_ok and input_locked <= 0.0:
			_air_dash()


func wish_dir() -> Vector3:
	if input_locked > 0.0:
		return Vector3.ZERO
	var v = Input.get_vector("left", "right", "back", "forward")
	if v.length() < 0.1:
		return Vector3.ZERO
	var b = Basis(Vector3.UP, deg_to_rad(yaw))
	var d = b * Vector3(v.x, 0, -v.y)
	return d.normalized() * minf(1.0, v.length())


func cam_forward() -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3.FORWARD


func face_dir() -> Vector3:
	return Vector3(-sin(facing), 0, -cos(facing))


func _jump() -> void:
	if input_locked > 0.0:
		return
	if wall_n != Vector3.ZERO:
		var d = wish_dir()
		var side = d - wall_n * d.dot(wall_n)
		velocity = wall_n * 11.0 + side * 6.0 + Vector3.UP * JUMP * 0.95
		_leave_wall()
		wall_cd = 0.3
		jumps = 1
		air_dash_ok = true
		Sfx.play("jump", global_position)
		model.play("jump", 0.05, 1.4, true)
		return
	if grounded or swimming:
		velocity.y = JUMP
		grounded = false
		swimming = false
		jumps = 1
		Sfx.play("jump", global_position)
		model.play("jump", 0.05, 1.3, true)
		FX.dust(global_position, 0.6)
	elif jumps < 2:
		velocity.y = JUMP * 0.92
		jumps = 2
		var d = wish_dir()
		if d.length() > 0.1:
			var hs = maxf(Vector2(velocity.x, velocity.z).length(), RUN)
			velocity.x = d.x * hs; velocity.z = d.z * hs
		FX.smoke_puff(global_position + Vector3.UP * 0.3, 0.5, 6)
		Sfx.play("whoosh", global_position)
		model.play("roll", 0.05, 1.8, true)


func _air_dash() -> void:
	if chakra < 6.0:
		return
	chakra -= 6.0
	air_dash_ok = false
	dash_t = 0.24
	var d = wish_dir()
	if d.length() < 0.1:
		d = cam_forward()
	velocity = d * AIR_DASH + Vector3.UP * 1.5
	facing = atan2(-d.x, -d.z)
	FX.speed_lines(global_position + Vector3.UP, d)
	Sfx.play("whoosh", global_position, 1.3)


# ------------------------------------------------------------------ fizik
func _physics_process(dt: float) -> void:
	if Game.paused:
		return
	input_locked -= dt
	wall_cd -= dt
	land_t -= dt
	var regen = 2.0 * (2.0 if "vit2" in Game.profile.get("skills", []) else 1.0)
	chakra = minf(max_chakra, chakra + regen * dt)
	if hp > 0.0:
		hp = minf(max_hp, hp + 0.5 * dt)
	if hp <= 0.0:
		model.play("death", 0.1)
		return
	if wall_n != Vector3.ZERO:
		_wall_move(dt)
	else:
		_ground_air_move(dt)
	_update_camera(dt)


func _ground_air_move(dt: float) -> void:
	var wish = wish_dir()
	var sprint = Input.is_action_pressed("dash") and grounded and wish.length() > 0.1
	if combat and combat.has_method("move_override") and combat.move_override(dt):
		pass
	elif dash_t > 0.0:
		dash_t -= dt
	else:
		var spd_mul = Buffs.mod("speed") * (1.12 if "tai2" in Game.profile.get("skills", []) else 1.0)
		var target = wish * (DASH if sprint else RUN) * spd_mul
		if swimming:
			target *= 0.35
		var hv = Vector3(velocity.x, 0, velocity.z)
		var accel = 14.0 if grounded else 3.5
		if not grounded and wish.length() < 0.1:
			target = hv
		hv = hv.lerp(target, minf(1.0, accel * dt))
		velocity.x = hv.x; velocity.z = hv.z
		if not swimming:
			velocity.y -= GRAV * dt
	var was_grounded = grounded
	move_and_slide()
	# arazi + su yüzeyi
	var p = global_position
	var terr = Game.terrain_height(p.x, p.z)
	on_water = terr < -0.3
	var ground = terr
	if on_water and not swimming:
		ground = 0.0
		chakra -= 1.5 * dt  # su üstünde durmak chakra ister
		if chakra <= 0.0:
			swimming = true
	if swimming:
		ground = -1.3
		if not on_water or chakra > 25.0 and Input.is_action_just_pressed("jump"):
			swimming = false
	if p.y <= ground + 0.02 and velocity.y <= 0.0:
		p.y = ground
		velocity.y = 0.0
		global_position = p
		grounded = true
	else:
		grounded = is_on_floor()
	if grounded:
		if not was_grounded and land_t < -0.3:
			land_t = 0.25
			model.play("land", 0.05, 1.6, true)
			FX.dust(global_position, 0.5)
			Sfx.play("land", global_position)
		jumps = 0
		air_dash_ok = true
	# duvar koşusuna geç
	if is_on_wall() and wall_cd <= 0.0 and not swimming:
		var n = get_wall_normal()
		n.y = 0.0
		if n.length() > 0.5:
			n = n.normalized()
			if wish.dot(-n) > 0.35 and _wall_tall(n):
				wall_n = n
				velocity = Vector3.ZERO
				grounded = false
				air_dash_ok = true
				Sfx.play("land", global_position, 1.3)
	# yön + animasyon
	var hv = Vector3(velocity.x, 0, velocity.z)
	var sp = hv.length()
	if sp > 0.5 and (combat == null or not combat.busy()):
		facing = lerp_angle(facing, atan2(-hv.x, -hv.z), minf(1.0, dt * 14.0))
	model.rotation = Vector3(0, facing, 0)
	model.position = Vector3.ZERO
	if combat == null or not combat.busy():
		_animate(sp, sprint)


func _wall_tall(n: Vector3) -> bool:
	var space = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.2, global_position + Vector3.UP * 2.2 - n * 1.2, 1)
	return not space.intersect_ray(q).is_empty()


func _wall_move(dt: float) -> void:
	var n = wall_n
	var side = Vector3(n.z, 0, -n.x)
	var wish = wish_dir()
	var up_amt = wish.dot(-n)
	var side_amt = wish.dot(side)
	var spd = WALL_SPEED * (1.4 if Input.is_action_pressed("dash") else 1.0)
	var move = Vector3.UP * up_amt * spd + side * side_amt * spd
	velocity = move - n * 3.0  # duvara bastır
	move_and_slide()
	var space = get_world_3d().direct_space_state
	var center = global_position + Vector3.UP * 0.9
	var q = PhysicsRayQueryParameters3D.create(center, center - n * 1.0, 1)
	var hit = space.intersect_ray(q)
	if hit.is_empty():
		# duvar bitti: yukarı gidiyorsak tepeye fırla
		if up_amt > 0.2:
			velocity = -n * 6.0 + Vector3.UP * 9.0
			model.play("jump", 0.05, 1.4, true)
		_leave_wall()
		return
	var hn: Vector3 = hit["normal"]
	hn.y = 0
	if hn.length() > 0.5:
		wall_n = hn.normalized()  # köşeleri dön
	if global_position.y <= Game.terrain_height(global_position.x, global_position.z) + 0.05 and up_amt < -0.2:
		_leave_wall()
		grounded = true
		return
	# görsel: ayaklar duvarda, gövde duvara dik
	var fwd = move.normalized() if move.length() > 0.5 else Vector3.UP
	var up = wall_n
	var right = fwd.cross(up).normalized()
	if right.length() < 0.1:
		right = side
	fwd = up.cross(right).normalized()
	var basis = Basis(right, up, -fwd)
	model.global_transform = Transform3D(basis, center - wall_n * (radius - 0.02))
	model.play("run" if move.length() > 0.5 else "idle", 0.12, clampf(move.length() / 10.0, 0.6, 1.5))
	model.overlay.set_pose("ninja_run", 1.0 if move.length() > 0.5 else 0.0)


func _leave_wall() -> void:
	wall_n = Vector3.ZERO
	wall_cd = 0.25
	model.transform = Transform3D(Basis(Vector3.UP, facing), Vector3.ZERO)


func _animate(sp: float, sprint: bool) -> void:
	var ov = model.overlay
	if swimming:
		model.play("swim" if sp > 0.5 else "swim_idle", 0.2)
		ov.set_pose("ninja_run", 0.0)
		return
	if not grounded:
		if model.current not in ["jump", "roll"] or model.anim_progress() > 0.95:
			model.play("air", 0.25)
		ov.set_pose("ninja_run", 0.0)
		return
	if land_t > 0.0:
		return
	if sp > 0.6:
		var run_anim = "run" if sp > 8.0 else "jog"
		model.play(run_anim, 0.15, clampf(sp / (16.0 if sprint else 10.0), 0.7, 1.6))
		ov.set_pose("ninja_run", 1.0 if sprint else 0.0)
	else:
		model.play("idle", 0.2)
		ov.set_pose("ninja_run", 0.0)


func _update_camera(dt: float) -> void:
	var target = global_position + Vector3.UP * 1.6
	cam_pivot.global_position = cam_pivot.global_position.lerp(target, minf(1.0, dt * 16.0))
	cam_pivot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
	# kamera duvarlara ve araziye girmesin
	var back = cam_pivot.global_transform.basis.z
	var want = cam_dist
	var space = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(cam_pivot.global_position, cam_pivot.global_position + back * cam_dist, 1)
	var hit = space.intersect_ray(q)
	if not hit.is_empty():
		want = maxf(0.8, cam_pivot.global_position.distance_to(hit["position"]) - 0.3)
	for i in 8:
		var t = want * (i + 1) / 8.0
		var cp = cam_pivot.global_position + back * t
		if cp.y < Game.terrain_height(cp.x, cp.z) + 0.4:
			want = maxf(0.8, t - want / 8.0)
			break
	cam_cur_dist = lerpf(cam_cur_dist, want, minf(1.0, dt * (20.0 if want < cam_cur_dist else 6.0)))
	var shake = Vector3.ZERO
	if Game.world and Game.world.env.shake > 0.0:
		var s: float = Game.world.env.shake
		shake = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * s * 0.15
		Game.world.env.shake = maxf(0.0, s - dt * 4.0)
	cam.position = Vector3(0.0, 0.0, cam_cur_dist) + shake


# ------------------------------------------------------------------ dövüş arayüzü
func is_dead() -> bool:
	return hp <= 0.0


func take_hit(info: Dictionary) -> void:
	if Buffs.has("henge"):
		Jutsu.end_henge(self)
	var armor = Buffs.mod("armor")
	info = info.duplicate()
	info["dmg"] = info.get("dmg", 5.0) * armor
	if combat:
		combat.take_hit(info)


func apply_status(_n: String, _d: float) -> void:
	pass


func respawn(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	hp = max_hp
	chakra = max_chakra
	wall_n = Vector3.ZERO
	if combat:
		combat.action = ""
	model.transform = Transform3D.IDENTITY
	model.play("idle", 0.0)
	cam_pivot.global_position = global_position + Vector3.UP * 1.6


func sit(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	model.play("sit", 0.2)
	input_locked = 2.0
	Hud.msg("Salıncakta sallanıyorsun... Akademinin bahçesi çok huzurlu.", Color(0.9, 0.9, 0.8))


func rebuild_model() -> void:
	var old = model
	model = CharacterModel.new()
	add_child(model)
	var look: Dictionary = Game.profile.get("look", {})
	model.setup(look)
	model.rotation.y = facing
	old.queue_free()
	FX.smoke_puff(global_position + Vector3.UP, 0.8, 10)
