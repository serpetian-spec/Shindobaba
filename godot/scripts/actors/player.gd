class_name Player
extends CharacterBody3D
## Oyuncu: Shinobi Striker tarzı parkur + Storm tarzı dövüş girişleri.
## Ctrl/Space: zıpla, havada çift zıplama, duvarda -> duvardan sek.  Shift: ninja koşusu / havada dash.
## Duvara doğru koşmak = duvarda koşmaya başlar (ek tuş yok, chakra harcamaz).

signal died

const RUN := 11.0
const DASH := 19.0
const GRAV := 36.0
const JUMP := 14.2
const WALL_SPEED := 12.0
const AIR_DASH := 28.0
const LEAP_FWD := 23.0   # Ctrl: Shinobi Striker uzun ninja sıçrayışı
const LEAP_UP := 14.5

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
var leaping = false
var last_air_vy = 0.0
var leap_charge = -1.0     # Ctrl basılı: 0..1 şarj (Striker süper zıplaması), -1 = şarj yok
var flip_t = -1.0          # havada takla zamanlayıcısı
var leap_ui: Control
var leap_bar: ProgressBar
var leap_arc: MeshInstance3D
const LEAP_CHARGE_TIME := 0.75
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
	model.setup(_look_with_age())
	_fit_capsule()
	# fizik 60 Hz, ekran daha hızlı olabilir: sadece oyuncu gövdesi kareler arası yumuşatılır (dünyanın geri kalanı _process'te
	# hareket ettiği için kökte kapalı), kamera her karede yumuşatılmış konumu izler -> takılma/titreme olmaz
	get_tree().root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	cam_pivot = Node3D.new()
	cam_pivot.top_level = true
	cam_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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
	if e.is_action_pressed("leap"):
		if (grounded or swimming) and wall_n == Vector3.ZERO:
			leap_charge = 0.0
			Sfx.play("whoosh", global_position, 0.6, 0.35)
		else:
			_leap(0.55)
	elif e.is_action_released("leap") and leap_charge >= 0.0:
		var p = leap_charge
		leap_charge = -1.0
		_leap(p)
	elif e.is_action_pressed("jump"):
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


## Nişangâhın (ekran ortası) dünyada değdiği nokta: jutsu ve atışlar buraya gider
func aim_point(max_d := 220.0) -> Vector3:
	var from = cam.global_position
	var dir = -cam.global_transform.basis.z
	var q = PhysicsRayQueryParameters3D.create(from, from + dir * max_d, 0xFFFFFFFF, [get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(q)
	var pt: Vector3 = hit["position"] if not hit.is_empty() else from + dir * max_d
	# arazi (fiziksiz yükseklik haritası) ile kesişim
	var step = 2.0
	var t = 0.0
	while t < from.distance_to(pt):
		var x = from + dir * t
		if x.y < Game.terrain_height(x.x, x.z):
			return x
		t += step
	return pt


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


## Ctrl: ileri doğru uzun, yüksek ninja sıçrayışı (yerde ya da havada bir kez; duvarda duvardan sek)
func _leap(power := 1.0) -> void:
	_show_leap_ui(false)
	if input_locked > 0.0:
		return
	if wall_n != Vector3.ZERO:
		_jump()
		return
	if not (grounded or swimming or jumps < 2):
		return
	var d = wish_dir()
	if d.length() < 0.1:
		d = cam_forward()
	d = d.normalized()
	var air = not (grounded or swimming)
	var k = clampf(power, 0.0, 1.0)
	velocity = d * lerpf(13.0, 30.0, k) + Vector3.UP * lerpf(9.5, 18.0, k) * (0.8 if air else 1.0)
	flip_t = 0.0 if k > 0.45 else -1.0
	facing = atan2(-d.x, -d.z)
	grounded = false
	swimming = false
	leaping = true
	jumps = 2 if air else 1
	FX.dust(global_position, 0.9)
	FX.speed_lines(global_position + Vector3.UP, d)
	Sfx.play("jump", global_position, 0.9)
	Sfx.play("whoosh", global_position, 0.8)
	model.play("jump", 0.05, 1.5, true)
	model.overlay.set_pose("leap", 1.0)
	model.overlay.set_pose("ninja_run", 0.0)
	if k > 0.8:
		FX.impact(global_position, Color(0.85, 0.8, 0.65), 0.5)
		Sfx.play("land", global_position, 0.7)


## Şarj çubuğu + iniş yayı (Shinobi Striker süper zıplama önizlemesi)
func _show_leap_ui(on: bool) -> void:
	if leap_ui == null:
		var cl = CanvasLayer.new()
		add_child(cl)
		leap_ui = Control.new()
		leap_ui.set_anchors_preset(Control.PRESET_CENTER)
		leap_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(leap_ui)
		leap_bar = UI.bar(Color(0.3, 0.85, 1.0), 180, 10)
		leap_bar.max_value = 1.0
		leap_bar.position = Vector2(-90, 60)
		leap_ui.add_child(leap_bar)
		var l = UI.label("SÜPER ZIPLAMA", 13, Color(0.75, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(-90, 40)
		l.size = Vector2(180, 18)
		leap_ui.add_child(l)
		leap_arc = MeshInstance3D.new()
		leap_arc.mesh = ImmediateMesh.new()
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.4, 0.9, 1.0, 0.85)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		leap_arc.material_override = m
		leap_arc.top_level = true
		leap_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(leap_arc)
	leap_ui.visible = on
	leap_arc.visible = on


func _update_leap_charge(dt: float) -> void:
	if leap_charge < 0.0:
		return
	if not (grounded or swimming) or input_locked > 0.0:
		leap_charge = -1.0
		_show_leap_ui(false)
		return
	leap_charge = minf(1.0, leap_charge + dt / LEAP_CHARGE_TIME)
	_show_leap_ui(true)
	leap_bar.value = leap_charge
	# çömel, yönü kameraya çevir
	velocity.x *= 0.8; velocity.z *= 0.8
	var d = wish_dir()
	if d.length() < 0.1:
		d = cam_forward()
	d = d.normalized()
	facing = lerp_angle(facing, atan2(-d.x, -d.z), minf(1.0, dt * 12.0))
	model.play("crouch", 0.12)
	# iniş yayı: balistik yörünge araziye çarpana kadar
	var v = d * lerpf(13.0, 30.0, leap_charge) + Vector3.UP * lerpf(9.5, 18.0, leap_charge)
	var p = global_position + Vector3.UP * 0.3
	var im: ImmediateMesh = leap_arc.mesh
	im.clear_surfaces()
	var pts = [p]
	for i in 70:
		var t = 0.03
		v.y -= GRAV * t
		p += v * t
		pts.append(p)
		if p.y < Game.terrain_height(p.x, p.z) and i > 4:
			break
	var eye = cam.global_position
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, pts.size() - 1):
		if i % 3 == 2:
			continue  # kesikli şerit
		var a: Vector3 = pts[i]; var b: Vector3 = pts[i + 1]
		var side = (b - a).cross(eye - a).normalized() * 0.09
		for q in [a - side, a + side, b + side, a - side, b + side, b - side]:
			im.surface_add_vertex(q)
	# iniş halkası
	var land: Vector3 = pts[-1]
	land.y = Game.terrain_height(land.x, land.z) + 0.08
	for k in 24:
		var a0 = TAU * k / 24.0; var a1 = TAU * (k + 1) / 24.0
		var r0 = 0.9; var r1 = 1.15
		var p0 = land + Vector3(cos(a0), 0, sin(a0)) * r0; var p1 = land + Vector3(cos(a1), 0, sin(a1)) * r0
		var q0 = land + Vector3(cos(a0), 0, sin(a0)) * r1; var q1 = land + Vector3(cos(a1), 0, sin(a1)) * r1
		for q in [p0, q0, q1, p0, q1, p1]:
			im.surface_add_vertex(q)
	im.surface_end()


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
	_tick_status(dt)
	land_t -= dt
	var regen = 2.0 * (2.0 if "vit2" in Game.profile.get("skills", []) else 1.0)
	chakra = minf(max_chakra, chakra + regen * dt)
	if hp > 0.0:
		hp = minf(max_hp, hp + 0.5 * dt)
	if hp <= 0.0:
		model.play("death", 0.1)
		return
	_update_leap_charge(dt)
	if wall_n != Vector3.ZERO:
		_wall_move(dt)
	else:
		_ground_air_move(dt)
	_apply_flip(dt)


func _process(dt: float) -> void:
	if Game.paused:
		return
	_update_camera(dt)


func _ground_air_move(dt: float) -> void:
	var wish = wish_dir()
	var sprint = Input.is_action_pressed("dash") and grounded and wish.length() > 0.1
	if combat and combat.has_method("move_override") and combat.move_override(dt):
		pass
	elif dash_t > 0.0:
		dash_t -= dt
	else:
		var spd_mul = Buffs.mod("speed") * (1.12 if "tai2" in Game.profile.get("skills", []) else 1.0) * (1.0 + Gear.stat(Game.profile, "speed")) * status_speed()
		var target = wish * (DASH if sprint else RUN) * spd_mul
		if swimming:
			target *= 0.35
		var hv = Vector3(velocity.x, 0, velocity.z)
		# ağırlık hissi: kalkışta yavaş ivmelen, durunca çabuk ama kaymalı dur
		var accel = (6.5 if target.length() > hv.length() else 9.0) if grounded else 2.8
		if not grounded and wish.length() < 0.1:
			target = hv
		elif leaping and not grounded:
			target = wish.normalized() * maxf(hv.length(), RUN)  # sıçrayışta yön verilir, hız korunur
		hv = hv.lerp(target, minf(1.0, accel * dt))
		velocity.x = hv.x; velocity.z = hv.z
		if not swimming:
			velocity.y -= GRAV * dt
	var was_grounded = grounded
	if not grounded:
		last_air_vy = velocity.y
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
	# yokuş aşağı: yerdeyken arazi hızla alçalıyorsa havaya kalkma, zemine yapış
	var snap = maxf(0.3, Vector2(velocity.x, velocity.z).length() * dt * 1.6)
	if was_grounded and velocity.y <= 0.0 and p.y > ground and p.y - ground < snap and not swimming:
		p.y = ground
	if p.y <= ground + 0.02 and velocity.y <= 0.0:
		p.y = ground
		velocity.y = 0.0
		global_position = p
		grounded = true
	else:
		grounded = is_on_floor()
	if grounded:
		if not was_grounded and land_t < -0.3:
			# yüksekten düşüşte ağır iniş: kısa toparlanma, hız kesilir
			var hard = last_air_vy < -20.0
			land_t = 0.38 if hard else 0.22
			if hard:
				velocity.x *= 0.35; velocity.z *= 0.35
				input_locked = maxf(input_locked, 0.18)
				FX.impact(global_position, Color(0.8, 0.75, 0.6), 0.7)
			model.play("land", 0.05, 1.3 if hard else 1.6, true)
			FX.dust(global_position, 0.5)
			Sfx.play("land", global_position)
		jumps = 0
		air_dash_ok = true
		if leaping:
			model.overlay.set_pose("leap", 0.0)
			flip_t = -1.0
		leaping = false
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
		facing = lerp_angle(facing, atan2(-hv.x, -hv.z), minf(1.0, dt * (8.0 if grounded else 4.0)))
	model.rotation = Vector3(0, facing, 0)
	# eğimde aşağıdaki ayak yere değsin: modeli eğime göre biraz alçalt
	var drop = 0.0
	if grounded:
		var tn = Game.terrain_normal(global_position.x, global_position.z)
		drop = clampf(0.16 * tan(acos(clampf(tn.y, 0.5, 1.0))), 0.0, 0.28)
	model.position = Vector3(0, -drop, 0)
	if combat == null or not combat.busy():
		_animate(sp, sprint)


## Süper zıplamanın tepesinde öne takla (kalça etrafında)
func _apply_flip(dt: float) -> void:
	if flip_t < 0.0 or wall_n != Vector3.ZERO:
		return
	if velocity.y < 4.0 or flip_t > 0.0:
		flip_t += dt
	var dur = 0.5
	var k = clampf(flip_t / dur, 0.0, 1.0)
	var ang = -TAU * (k * k * (3.0 - 2.0 * k))
	var c = Vector3(0, 0.95 * model.age_scale, 0)
	var b = Basis(Vector3.UP, facing) * Basis(Vector3.RIGHT, ang)
	model.transform = Transform3D(b, model.position + c - b * c + Basis(Vector3.UP, facing) * Vector3.ZERO)
	model.scale = Vector3.ONE * model.age_scale
	if k >= 1.0:
		flip_t = -1.0
		model.overlay.set_pose("leap", 0.35)


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
	var target = get_global_transform_interpolated().origin + Vector3.UP * (1.6 * (model.age_scale if model else 1.0))
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
	# ekipman savunması: her puan ~%1.2 azaltır (en fazla %50)
	var armor = Buffs.mod("armor") * (1.0 - clampf(Gear.stat(Game.profile, "def") * 0.012, 0.0, 0.5))
	info = info.duplicate()
	info["dmg"] = info.get("dmg", 5.0) * armor
	if combat:
		combat.take_hit(info)


var statuses = {}  # element durumları: burn, wet, frozen, chilled, shocked, mud, stun, bind, slow


func apply_status(n: String, d: float) -> void:
	statuses[n] = maxf(statuses.get(n, 0.0), d)
	if n in ["stun", "bind", "frozen"]:
		input_locked = maxf(input_locked, d)


func has_status(n: String) -> bool:
	return statuses.get(n, 0.0) > 0.0


func _tick_status(dt: float) -> void:
	for k in statuses.keys():
		statuses[k] -= dt
		if statuses[k] <= 0.0:
			statuses.erase(k)
	if has_status("burn"):
		hp -= 4.0 * dt
		if randf() < dt * 8.0:
			FX.burst(global_position + Vector3.UP * randf_range(0.3, 1.6), {"amount": 3, "life": 0.5, "size": 0.6, "vmin": 1, "vmax": 2, "gravity": Vector3(0, 3, 0),
				"colors": [Color(1, 0.8, 0.3, 1), Color(1, 0.3, 0.05, 0)]})
	if has_status("wet") and randf() < dt * 4.0:
		FX.burst(global_position + Vector3.UP * randf_range(0.5, 1.6), {"amount": 2, "life": 0.4, "add": false, "size": 0.15, "vmin": 0.1, "vmax": 0.3, "gravity": Vector3(0, -9, 0),
			"colors": [Color(0.6, 0.8, 1, 0.9), Color(0.6, 0.8, 1, 0)]})


func status_speed() -> float:
	if has_status("slow") or has_status("mud") or has_status("chilled"):
		return 0.55
	return 1.0


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
	reset_physics_interpolation()
	cam_pivot.global_position = global_position + Vector3.UP * 1.6


func sit(at: Vector3) -> void:
	global_position = at
	reset_physics_interpolation()
	velocity = Vector3.ZERO
	model.play("sit", 0.2)
	input_locked = 2.0
	Hud.msg("Salıncakta sallanıyorsun... Akademinin bahçesi çok huzurlu.", Color(0.9, 0.9, 0.8))


## Rütbeye göre yaş: Akademi=çocuk, Genin=genç, Chunin=delikanlı, Jonin+=yetişkin
static func age_for_rank(rank: int) -> String:
	return ["child", "teen", "young", "adult", "adult"][clampi(rank, 0, 4)]


func _look_with_age() -> Dictionary:
	var look: Dictionary = (Game.profile.get("look", {}) if not Game.profile.is_empty() else {}).duplicate()
	look["age"] = age_for_rank(int(Game.profile.get("rank", 0)))
	return look


## Boy değişince kapsül hitbox da değişir
func _fit_capsule() -> void:
	var k = model.age_scale
	radius = 0.38 * k
	height = 1.8 * k
	for c in get_children():
		if c is CollisionShape3D and c.shape is CapsuleShape3D:
			c.shape.radius = radius
			c.shape.height = height
			c.position.y = height * 0.5


func rebuild_model() -> void:
	var old = model
	model = CharacterModel.new()
	add_child(model)
	model.setup(_look_with_age())
	_fit_capsule()
	model.rotation.y = facing
	old.queue_free()
	FX.smoke_puff(global_position + Vector3.UP, 0.8, 10)
	if combat and combat.modes and combat.modes.eyes:
		combat.modes.eyes.refresh_visual.call_deferred()
