class_name Player
extends CharacterBody3D
## Oyuncu: Shinobi Striker tarzı parkur + Storm tarzı dövüş girişleri.
## Ctrl/Space: zıpla, havada çift zıplama, duvarda -> duvardan sek.  Shift: ninja koşusu / havada dash.
## Duvara doğru koşmak = duvarda koşmaya başlar (ek tuş yok, chakra harcamaz).

signal died

const RUN := 11.0
const WALK := 2.4   # Caps Lock: sakin köylü yürüyüşü
var walking := false
const DASH := 17.0   # anime: ninja koşusu hızlı ama araç hızında değil
const GRAV := 36.0
const JUMP := 16.0   # ~3.6 m: tek sıçrayışta çatı/dal
const WALL_SPEED := 12.0
const AIR_DASH := 28.0
const LEAP_FWD := 17.0   # Ctrl: Shinobi Striker uzun ninja sıçrayışı
const LEAP_UP := 15.5

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
# Striker: ipli kunai (havada Q, düşüş başına bir kez) ve duvar koşusu atılımı (duvarda Ctrl)
var rope_ok = true
var rope_t = -1.0
var rope_pt := Vector3.ZERO
var rope_line: MeshInstance3D
var wall_boost_t = -1.0
const ROPE_RANGE := 45.0
var sprint_t = 0.0
var was_turbo = false
var last_air_vy = 0.0
var cam_lift = 0.0   # dev dönüşümlerde kamera hedefini yükselt (kuyruklu canavar, Susanoo)
var cam_range := Vector2(2.2, 14.0)   # fare tekeri yakınlaştırma sınırı (dev dönüşümde büyür)
var model_lift := 0.0   # model görsel olarak bu kadar yukarıda (Susanoo içinde süzülme)
var cam_giant := false   # dev form: kamera küçük engellere (ağaç, ev) çarpıp canavarın içine sıçramasın
var leap_charge = -1.0     # Ctrl basılı: 0..1 şarj (Striker süper zıplaması), -1 = şarj yok
var flip_t = -1.0          # havada takla zamanlayıcısı
var leap_ui: Control
var leap_bar: ProgressBar
var leap_arc: MeshInstance3D
const LEAP_CHARGE_TIME := 0.75
var air_dash_ok = true
var air_dash_used = 0
var dash_t = 0.0
var wall_n = Vector3.ZERO  # 0 ise duvarda değil
var wall_cd = 0.0
var wall_stall = 0.0       # duvarda yukarı basılıyken ilerleyemeden geçen süre (saçak/balkon altı)
# kenara tutunup üstüne çıkma (duvar tepesi, saçak, balkon): 3 noktalı eğri boyunca kısa geçiş
var mantle_t = -1.0
var mantle_pts: Array = []
var mantle_dur = 0.35
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
var max_stamina = 100.0
var _stam_rest := 0.0   # son harcamadan beri (dinlenince hızlı dolar)
# uçuş kipi: kaynak ("light" Keijūgan, "sand" kum bulutu, "susanoo" kanatlar...) ve ayarları
var fly_src := ""
var fly_cfg := {}
var fly_vis: Node3D = null


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


func spend_stamina(n: float) -> void:
	stamina = maxf(0.0, stamina - n)
	_stam_rest = 0.0


func apply_profile_stats() -> void:
	if Game.profile.is_empty():
		return
	max_hp = Stats.max_hp(Game.profile)
	max_chakra = Stats.max_chakra(Game.profile)
	max_stamina = Stats.max_stamina(Game.profile)
	hp = minf(hp, max_hp)
	chakra = minf(chakra, max_chakra)
	stamina = minf(stamina, max_stamina)


# ------------------------------------------------------------------ girdi
func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("walk") and not e.is_echo():
		walking = not walking
		Hud.msg("Yürüyüş" if walking else "Koşu", Color(0.85, 0.9, 1.0), 1.0)
	if Game.paused or Game.ui_open:
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s = 0.18 * float(Game.settings["sens"])
		yaw -= e.relative.x * s
		pitch -= e.relative.y * s * (-1.0 if Game.settings["invert_y"] else 1.0)
		pitch = clampf(pitch, -70, 60)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = maxf(cam_range.x, cam_dist - cam_range.y * 0.04)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = minf(cam_range.y, cam_dist + cam_range.y * 0.04)
	# Kai: genjutsu/sersemletmeyi chakrayla boz
	if e.is_action_pressed("substitute") and (has_status("stun") or has_status("fear") or has_status("kokuangyo")) and Stats.has_unlock(Game.profile, "kai") and chakra >= 12.0:
		chakra -= 12.0
		statuses.erase("stun")
		statuses.erase("fear")
		statuses.erase("kokuangyo")
		input_locked = 0.0
		Combat.popup_text(global_position + Vector3.UP * 2.2, "KAI!", Color(0.8, 0.6, 1.0))
		FX.ring(global_position + Vector3.UP, Color(0.8, 0.6, 1.0), 3.0, 0.3, false)
		Sfx.play("seal", global_position, 1.2)
		get_viewport().set_input_as_handled()
		return
	if fly_src != "":
		# uçarken Space/Ctrl yükselip alçalır (_fly_move); havada zıplamada kanatlı Susanoo da burada değil
		return
	if e.is_action_pressed("jump") and not grounded and wall_n == Vector3.ZERO and has_meta("wing_flight"):
		start_flight("susanoo", get_meta("wing_flight"))
		return
	if e.is_action_pressed("leap") and wall_n != Vector3.ZERO:
		_wall_boost()
	elif e.is_action_pressed("leap"):
		if input_locked > 0.0:
			return
		if (grounded or swimming) and wall_n == Vector3.ZERO:
			leap_charge = 0.0   # basarken ses yok: ses bırakınca (sıçrayışta) çıkar
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
## Nişangâhın ekrandaki yeri (oran): karakterin başının üstünde, kamera merkezinde karakter durduğu için ortada değil
const AIM_SCREEN := Vector2(0.5, 0.36)


## Nişangâhtan çıkan kamera ışını: [başlangıç, yön]
func aim_ray() -> Array:
	var vp = get_viewport()
	if cam == null or vp == null:
		return [global_position + Vector3.UP * 1.5, face_dir()]
	var sp = vp.get_visible_rect().size * AIM_SCREEN
	return [cam.project_ray_origin(sp), cam.project_ray_normal(sp)]


func aim_point(max_d := 220.0) -> Vector3:
	var ar = aim_ray()
	var from: Vector3 = ar[0]
	var dir: Vector3 = ar[1]
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
		air_dash_used = 0
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
	elif jumps < 2 + int(Stats.skill(Game.profile, "jumps")):
		velocity.y = JUMP * 0.92
		jumps = 2
		var d = wish_dir()
		if d.length() > 0.1:
			var hs = maxf(Vector2(velocity.x, velocity.z).length(), RUN)
			velocity.x = d.x * hs; velocity.z = d.z * hs
		FX.smoke_puff(global_position + Vector3.UP * 0.3, 0.5, 6)
		Sfx.play("whoosh", global_position)
		# havada ikinci zıplama: tüm vücut top gibi toplanıp öne takla atar (eskiden yer yuvarlanması oynuyordu: süzülme pozu
		# bacakları tuttuğu için yalnız üst gövde dönüyordu)
		model.play("air", 0.05)
		model.overlay.set_pose("leap", 0.0)
		flip_t = 0.001


## Ctrl: ileri doğru uzun, yüksek ninja sıçrayışı (yerde ya da havada bir kez; duvarda duvardan sek)
func _leap(power := 1.0) -> void:
	_show_leap_ui(false)
	model.overlay.set_pose("charge", 0.0)
	if input_locked > 0.0 or has_status("stun") or has_status("bind") or has_status("frozen"):   # sersem/bağlıyken sıçranamaz
		return
	if input_locked > 0.0:
		return
	if wall_n != Vector3.ZERO:
		_jump()
		return
	if not (grounded or swimming or jumps < 2 + int(Stats.skill(Game.profile, "jumps"))):
		return
	var d = wish_dir()
	if d.length() < 0.1:
		d = cam_forward()
	d = d.normalized()
	var air = not (grounded or swimming)
	var k = clampf(power, 0.0, 1.0)
	var lm = 1.0 + Stats.skill(Game.profile, "leap")
	# 2x mesafe ve 2x yükseklik: aynı yerçekiminde yatay ve dikey hız √2 katı
	velocity = d * lerpf(24.0, 56.0, k) * 1.414 * lm + Vector3.UP * lerpf(12.0, 22.5, k) * 1.414 * sqrt(lm) * (0.8 if air else 1.0)
	flip_t = 0.0 if k > 0.45 else -1.0
	facing = atan2(-d.x, -d.z)
	grounded = false
	swimming = false
	leaping = true
	jumps = 2 if air else 1
	FX.dust(global_position, 0.9)
	FX.speed_lines(global_position + Vector3.UP, d)
	Sfx.play("leap", null, 1.0, 1.1)   # bırakınca (sıçrayışın kendisi), basılıyken değil; oyuncuya tam ses (2D)
	Sfx.play("whoosh", global_position, 0.8, 0.6)
	model.play("jump", 0.05, 1.5, true)
	model.overlay.set_pose("leap", 1.0)
	model.overlay.glide_land = 0.0
	model.overlay.snap("ninja_run", 0.0)
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
		model.overlay.set_pose("charge", 0.0)
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
	# Striker çıkışı: derin çömelme, şarj doldukça daha alçak ve gergin
	model.play("idle", 0.12)
	model.overlay.charge_k = maxf(leap_charge, 1.0 if has_meta("kneel") else 0.0)   # Mushimayu vb. diz çökme
	model.overlay.set_pose("charge", 1.0)
	model.overlay.snap("ninja_run", 0.0)
	# iniş yayı: balistik yörünge araziye çarpana kadar
	var lmul = 1.0 + Stats.skill(Game.profile, "leap")
	var v = d * lerpf(24.0, 56.0, leap_charge) * lmul + Vector3.UP * lerpf(14.0, 27.0, leap_charge) * sqrt(lmul)
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
	air_dash_used += 1
	air_dash_ok = air_dash_used < 1 + int(Stats.skill(Game.profile, "air_dash"))
	dash_t = 0.24
	var d = wish_dir()
	if d.length() < 0.1:
		d = cam_forward()
	velocity = d * AIR_DASH + Vector3.UP * 1.5
	facing = atan2(-d.x, -d.z)
	FX.speed_lines(global_position + Vector3.UP, d)
	Sfx.play("whoosh", global_position, 1.3)


# ------------------------------------------------------------------ fizik
func _notification(what: int) -> void:
	# pencere odağı giderken Shift bırakılmış sayılır (basılı kalmış görünüp kendi kendine depar atmasın)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.action_release("dash")
		sprint_t = 0.0


func _physics_process(dt: float) -> void:
	if Game.paused:
		return
	dt *= Combat.player_comp()   # Sharingan algısı: dünya yavaş, oyuncu normal hızda
	# depar sayacı her hareket kipinde sıfırlanır (duvar/ip/tutunmada Shift bırakılınca kalıyordu -> kısa basışta tam hız);
	# jutsu/saldırı sırasında birikmez
	if not Input.is_action_pressed("dash") or not Input.is_physical_key_pressed(KEY_SHIFT) or (combat != null and not combat.get("action") in [null, ""]):
		sprint_t = 0.0
	input_locked -= dt
	wall_cd -= dt
	_tick_status(dt)
	land_t -= dt
	var regen = 1.5 * (1.0 + Stats.skill(Game.profile, "regen_chakra")) * (1.0 + Mastery.get_v(Game.profile, "chakra") * 0.02)
	# anime yaşam gücü: Uzumaki dev chakra ve hızlı toparlanma, Senju güçlü beden (yaralar hızla kapanır)
	var clan = String(Game.profile.get("clan", ""))
	if clan == "uzumaki":
		regen *= 1.6
	chakra = minf(max_chakra, chakra + regen * dt)
	# stamina: nefeslenince dolar; harcadıktan 1.5 sn sonra hızlanır, dayanıklılık ustalığı hızlandırır
	_stam_rest += dt
	var sreg = (3.0 if _stam_rest < 2.0 else 7.0) * (1.0 + Mastery.get_v(Game.profile, "dayaniklilik") * 0.015)   # dolum 6/16 idi: taijutsu bedava kalıyordu (ölçüldü)
	stamina = minf(max_stamina, stamina + sreg * dt)
	if hp > 0.0 and not Buffs.has("rinne_bedel"):   # Rinne Tensei bedeli: iyileşme yok
		var hreg = 0.5 * (1.0 + Stats.skill(Game.profile, "regen_hp"))
		if clan == "senju":
			hreg *= 3.0
		elif clan == "uzumaki":
			hreg *= 2.0
		hp = minf(max_hp, hp + hreg * dt)
	if hp <= 0.0:
		model.play("death", 0.1)
		return
	_update_leap_charge(dt)
	if fly_src != "":
		_fly_move(dt)
	elif mantle_t >= 0.0:
		_mantle_move(dt)
	elif rope_t >= 0.0:
		_rope_move(dt)
	elif wall_n != Vector3.ZERO:
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
	# Shift takılı kalmasın (menü açıkken / pencere odağı giderken bırakma olayı kaçınca hep koşuyordu):
	# depar yalnız fiziksel Shift gerçekten basılıyken ve arayüz kapalıyken
	var shift_down = Input.is_action_pressed("dash") and Input.is_physical_key_pressed(KEY_SHIFT) and not Game.ui_open
	if Input.is_action_pressed("dash") and not shift_down:
		Input.action_release("dash")
	var sprint = shift_down and grounded and wish.length() > 0.1
	# Shift 5 sn basılı: ikinci depar kademesi (büyük harita için)
	if sprint:
		sprint_t += dt
	var turbo = sprint and sprint_t > 5.0
	if turbo and not was_turbo:
		FX.speed_lines(global_position + Vector3.UP, wish)
		Sfx.play("whoosh", global_position, 0.7)
		Hud.msg("Ninja koşusu: tam hız!", Color(0.7, 0.9, 1.0), 1.2)
	was_turbo = turbo
	if combat and combat.has_method("move_override") and combat.move_override(dt):
		pass
	elif dash_t > 0.0:
		dash_t -= dt
	else:
		var spd_mul = Buffs.mod("speed") * (1.0 + Stats.skill(Game.profile, "speed") + Mastery.get_v(Game.profile, "hiz") * 0.003) * (1.0 + Gear.stat(Game.profile, "speed") + Stats.clan_bonus(Game.profile, "speed")) * status_speed()
		if sprint and wish.length() > 0.1:
			Mastery.gain(Game.profile, "hiz", dt * 0.025)   # koştukça hız (0.005 idi: sürekli koşsan 1 puan ~20 dk)
		var target = wish * ((DASH * 1.35 if turbo else DASH) if sprint else (WALK if walking else RUN)) * spd_mul   # tam hız (5 sn Shift) 2x; Caps Lock: yürüyüş
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
	var pre_pos = global_position
	move_and_slide()
	# bir dövüşçünün (düşman/klon/çağrı) kapsülünün üstüne basıp havada asılı kalmasın: kenara kayıp düş
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var cb = col.get_collider()
		if cb is Fighter or cb is Summon:
			if col.get_normal().y > 0.5:
				var away = global_position - (cb as Node3D).global_position
				away.y = 0.0
				away = away.normalized() if away.length() > 0.05 else -face_dir()
				global_position += away * 0.25
				velocity.y = minf(velocity.y, -6.0)
				grounded = false
			break
	# dik arazi (uçurum) = duvar: üstüne ışınlanma yok; içine doğru koşuyorsan duvar koşusuna geç
	var steep_n = _steep_block(pre_pos)
	if steep_n != Vector3.ZERO and wall_cd <= 0.0 and not swimming and wish.dot(-steep_n) > 0.35:
		_enter_wall(steep_n, true)
		return
	# arazi + su yüzeyi
	var p = global_position
	var terr = Game.terrain_height(p.x, p.z)
	var wl = Game.water_level(p.x, p.z, terr)   # deniz 0, gölet/kanal/vadi kendi yüzeyi
	on_water = wl > terr + 0.1
	var ground = terr
	if on_water and not swimming:
		ground = wl
		chakra -= 1.5 * maxf(0.1, 1.0 + Stats.skill(Game.profile, "water_cost")) * dt  # su üstünde durmak chakra ister
		Mastery.gain(Game.profile, "chakra", dt * 0.03)   # su üstünde yürüme: chakra kontrolü antrenmanı (0.005 idi: 1 puan ~20 dk, neredeyse gelişmiyordu)
		if chakra <= 0.0 and wl - terr > 1.0:   # sığ suda (dere, gölet) yüzülmez: dibe basılır
			swimming = true
			leaping = false
			model.overlay.set_pose("leap", 0.0)
		elif chakra <= 0.0:
			chakra = 0.0
			ground = terr
	if swimming:
		ground = maxf(terr, wl - 1.3)
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
		air_dash_used = 0
		rope_ok = true
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
				_enter_wall(n, false)
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
	model.position = Vector3(0, model_lift - drop, 0)
	if combat == null or not combat.busy():
		_animate(sp, sprint)
	elif combat.action != "chakra_dash":
		# koşarken ani vuruş/jutsu: koşu kolları ve süzülme hemen bırakılır, saldırı animasyonu tam görünür
		model.overlay.snap("ninja_run", 0.0)
		model.overlay.set_pose("charge", 0.0)
		if grounded:
			model.overlay.snap("leap", 0.0)


# ------------------------------------------------------------------ uçuş kipi
## Herhangi bir kaynak uçuş başlatabilir: cfg = {speed, lift, drain (chakra/sn), vis (Node3D), name, land_stop, dur}
## Space yükselir, Ctrl alçalır, Shift hızlanır; chakra biterse ya da süre dolarsa iner.
func start_flight(src: String, cfg := {}) -> void:
	if fly_src != "":
		stop_flight()
	fly_src = src
	leaping = false
	flip_t = -1.0
	fly_cfg = cfg.duplicate()
	fly_cfg["t"] = 0.0
	if cfg.get("vis") is Node3D:
		fly_vis = cfg["vis"]
		fly_cfg.erase("vis")
		if fly_vis.get_parent():
			fly_vis.reparent(self)
		else:
			add_child(fly_vis)
		fly_vis.position = Vector3.ZERO
	leap_charge = -1.0
	_show_leap_ui(false)
	if wall_n != Vector3.ZERO:
		_leave_wall()
	if rope_t >= 0.0:
		_end_rope()
	grounded = false
	velocity.y = maxf(velocity.y, 6.0)
	FX.smoke_puff(global_position + Vector3.UP * 0.3, 0.8, 10)
	Hud.msg("%s: Space yüksel, Ctrl alçal, Shift hızlan" % String(cfg.get("name", "Uçuş")), Color(0.8, 0.9, 1.0), 2.5)


func stop_flight() -> void:
	if fly_src == "":
		return
	fly_src = ""
	if is_instance_valid(fly_vis):
		var v = fly_vis
		var tw = v.create_tween()
		tw.tween_property(v, "scale", Vector3.ONE * 0.05, 0.3)
		tw.tween_callback(v.queue_free)
	fly_vis = null
	model.overlay.set_pose("leap", 0.0)
	FX.smoke_puff(global_position + Vector3.UP * 0.3, 0.6, 8)


func flight_source() -> String:
	return fly_src


func is_flying() -> bool:
	return fly_src != ""


func _fly_move(dt: float) -> void:
	fly_cfg["t"] = float(fly_cfg.get("t", 0.0)) + dt
	var drain = float(fly_cfg.get("drain", 2.0))
	chakra -= drain * dt
	if chakra <= 0.0 or (fly_cfg.has("dur") and fly_cfg["t"] > float(fly_cfg["dur"])):
		chakra = maxf(chakra, 0.0)
		Hud.msg("Uçuş bitti" + (" (chakra tükendi)" if chakra <= 0.0 else ""), Color(0.9, 0.8, 0.6))
		stop_flight()
		return
	var wish = wish_dir()
	var fast = Input.is_action_pressed("dash")
	var spd = float(fly_cfg.get("speed", 14.0)) * (1.8 if fast else 1.0) * Buffs.mod("speed")
	var vy = 0.0
	var lift = float(fly_cfg.get("lift", 8.0))
	if input_locked <= 0.0:
		if Input.is_action_pressed("jump"):
			vy = lift
		elif Input.is_action_pressed("leap"):
			vy = -lift * 1.3
	var target = wish * spd + Vector3.UP * vy
	var k = minf(1.0, (3.5 if target.length() > velocity.length() else 2.5) * dt)
	velocity = velocity.lerp(target, k)
	if combat and combat.has_method("move_override") and combat.move_override(dt):
		pass
	move_and_slide()
	var g = Game.ground_height(global_position.x, global_position.z)
	if global_position.y < g + 0.25:
		global_position.y = g + 0.25
		velocity.y = maxf(velocity.y, 0.0)
		if fly_cfg.get("land_stop", false) and vy < 0.0:
			stop_flight()
			return
	grounded = false
	jumps = 1
	var hv = Vector3(velocity.x, 0, velocity.z)
	if hv.length() > 0.5 and (combat == null or not combat.busy()):
		facing = lerp_angle(facing, atan2(-hv.x, -hv.z), minf(1.0, dt * 5.0))
	model.rotation = Vector3(0, facing, -clampf(wish.dot(global_transform.basis.x) * 0.25, -0.3, 0.3))
	model.position = Vector3(0, model_lift, 0)
	if combat == null or not combat.busy():
		if model.current != "air":
			model.play("air", 0.25)
		model.overlay.set_pose("ninja_run", 0.0)
		model.overlay.set_pose("leap", clampf(hv.length() / maxf(spd, 1.0), 0.25, 1.0))
	if is_instance_valid(fly_vis):
		fly_vis.rotation.y = facing
		fly_vis.position.y = sin(fly_cfg["t"] * 2.5) * 0.06


## Süper zıplamanın tepesinde öne takla (kalça etrafında)
func _apply_flip(dt: float) -> void:
	if flip_t < 0.0 or wall_n != Vector3.ZERO:
		if mantle_t < 0.0 and model.overlay.tuck > 0.0:
			model.overlay.tuck = move_toward(model.overlay.tuck, 0.0, dt * 6.0)
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
	# takla boyunca top gibi toplan (bacaklar süzülme pozunda donuk kalmasın)
	model.overlay.tuck = clampf(sin(PI * k) * 1.6, 0.0, 1.0) if flip_t > 0.0 else 0.0
	if flip_t > 0.0:
		model.overlay.snap("leap", 0.0)
	if k >= 1.0:
		flip_t = -1.0
		model.overlay.tuck = 0.0
		model.overlay.set_pose("leap", 1.0)  # taklanın ardından süzülme


## Dik arazi engeli: yeni konumda arazi, oyuncunun bir adımda çıkabileceğinden yüksekse yatay hareketi geri alır.
## Dönüş: engel olduysa uçurumdan dışarı bakan yatay normal, yoksa ZERO.
const STEEP_RISE := 1.4   # ~55°: bundan dik yüzey yürünemez, tırmanılır
func _steep_block(pre: Vector3) -> Vector3:
	var p = global_position
	var horiz = Vector2(p.x - pre.x, p.z - pre.z).length()
	if horiz < 0.0005:
		return Vector3.ZERO
	var terr = Game.terrain_height(p.x, p.z)
	if terr < 0.0:
		return Vector3.ZERO
	var base_y = minf(pre.y, p.y)
	if terr - base_y <= maxf(0.45, horiz * STEEP_RISE):
		return Vector3.ZERO
	# hareketi geri al (sadece yatay), arazinin içine girme
	global_position = Vector3(pre.x, p.y, pre.z)
	velocity.x = 0.0; velocity.z = 0.0
	var tn = Game.terrain_normal(p.x, p.z)
	var hn = Vector3(tn.x, 0, tn.z)
	if hn.length() < 0.05:
		hn = Vector3(pre.x - p.x, 0, pre.z - p.z)
	return hn.normalized()


## Arazi uçurumunda duvar koşusu: yüzeye yapışık yukarı/yana hareket, düz zemine varınca tepeye fırla
var terrain_wall := false
func _terrain_wall_move(dt: float) -> void:
	var n = wall_n
	var side = Vector3(n.z, 0, -n.x)
	var wish = wish_dir()
	var up_amt = wish.dot(-n)
	var side_amt = wish.dot(side)
	var spd = WALL_SPEED * (1.4 if Input.is_action_pressed("dash") else 1.0) * (1.0 + Stats.skill(Game.profile, "wall_run"))
	Mastery.gain(Game.profile, "chakra", dt * 0.02)   # ağaç/duvar tırmanma: chakra kontrolü antrenmanı (0.004 idi)
	if wall_boost_t > 0.0:
		wall_boost_t -= dt
		spd *= 2.3
		if up_amt < 0.2 and absf(side_amt) < 0.2:
			up_amt = 1.0
	var p = global_position + (Vector3.UP * up_amt + side * side_amt) * spd * dt
	# yüzeye yapış: n yönünde (dışarı) arazinin p.y yüksekliğine indiği noktayı bul
	var found = false
	var s_hit = 0.0
	var s = -3.0
	while s <= 3.0:
		var q = Vector3(p.x, 0, p.z) - n * s
		if Game.terrain_height(q.x, q.z) >= p.y:
			s_hit = s
			found = true
			break
		s += 0.2
	if not found:
		# önünde artık yükselen arazi yok: tepeye vardın
		global_position = p
		velocity = -n * 6.0 + Vector3.UP * 8.0
		model.play("jump", 0.05, 1.4, true)
		terrain_wall = false
		_leave_wall()
		return
	p.x -= n.x * (s_hit - radius)
	p.z -= n.z * (s_hit - radius)
	var tn = Game.terrain_normal(p.x - n.x * radius, p.z - n.z * radius)
	if tn.y > 0.72 and up_amt > 0.2:
		# eğim yumuşadı: üst kenar, öne fırla
		global_position = p
		velocity = -n * 6.0 + Vector3.UP * 7.0
		model.play("jump", 0.05, 1.4, true)
		terrain_wall = false
		_leave_wall()
		return
	var hn = Vector3(tn.x, 0, tn.z)
	if hn.length() > 0.2:
		wall_n = wall_n.lerp(hn.normalized(), minf(1.0, dt * 6.0)).normalized()
	var below = Game.terrain_height(p.x + n.x * 1.2, p.z + n.z * 1.2)
	if up_amt < -0.2 and p.y <= below + 0.1:
		p.y = below
		global_position = p
		terrain_wall = false
		_leave_wall()
		grounded = true
		return
	global_position = p
	velocity = Vector3.ZERO
	var move = Vector3.UP * up_amt * spd + side * side_amt * spd
	var center = global_position + Vector3.UP * 0.9
	var fwd = move.normalized() if move.length() > 0.5 else Vector3.UP
	var up = wall_n
	var right = fwd.cross(up).normalized()
	if right.length() < 0.1:
		right = side
	fwd = up.cross(right).normalized()
	model.global_transform = Transform3D(Basis(right, up, -fwd), center - wall_n * (radius - 0.02))
	model.play("run" if move.length() > 0.5 else "idle", 0.12, clampf(move.length() / 10.0, 0.6, 1.5))
	model.overlay.set_pose("ninja_run", 1.0 if move.length() > 0.5 else 0.0)


func _wall_tall(n: Vector3) -> bool:
	var space = get_world_3d().direct_space_state
	# eğik / yuvarlak yüzeyler (kubbe, su kabağı ev, kule eteği) 2.2 m'de geriye yatar: ışın onları da yakalasın
	var q = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.2, global_position + Vector3.UP * 2.2 - n * 2.8, 1)
	return not space.intersect_ray(q).is_empty()


func _wall_move(dt: float) -> void:
	if terrain_wall:
		_terrain_wall_move(dt)
		return
	var n = wall_n
	var side = Vector3(n.z, 0, -n.x)
	var wish = wish_dir()
	var up_amt = wish.dot(-n)
	var side_amt = wish.dot(side)
	var spd = WALL_SPEED * (1.4 if Input.is_action_pressed("dash") else 1.0) * (1.0 + Stats.skill(Game.profile, "wall_run"))
	if wall_boost_t > 0.0:
		wall_boost_t -= dt
		spd *= 2.3
		if up_amt < 0.2 and absf(side_amt) < 0.2:
			up_amt = 1.0  # yön verilmezse yukarı fırla
		if Engine.get_process_frames() % 3 == 0:
			FX.burst(global_position + Vector3.UP * 0.9, {"amount": 3, "life": 0.35, "size": 0.35, "vmin": 1, "vmax": 3, "add": true,
				"colors": [Color(0.5, 0.85, 1.0, 0.9), Color(0.4, 0.7, 1.0, 0)]})
	var move = Vector3.UP * up_amt * spd + side * side_amt * spd
	velocity = move - n * 3.0  # duvara bastır
	var pre = global_position
	move_and_slide()
	# saçak/balkon/korkuluk altında yukarı ilerleyemiyorsan: üstüne tırman (ya da duvardan bırak, sonsuza dek yapışma)
	if up_amt > 0.2 and global_position.y - pre.y < spd * up_amt * dt * 0.3:
		wall_stall += dt
	else:
		wall_stall = 0.0
	if wall_stall > 0.12:
		var ledge = _find_ledge(n, true)
		if ledge != null:
			_start_mantle(ledge, n)
			return
		if wall_stall > 0.45:
			velocity = n * 5.0 + Vector3.UP * 2.0
			_leave_wall()
			return
	var space = get_world_3d().direct_space_state
	var center = global_position + Vector3.UP * 0.9
	# eğimli yüzeyde yüzey merkezden daha uzakta kalır (45° kubbede ~1.3 m): kısa ışın "duvar bitti" sanıp fırlatıyordu
	var q = PhysicsRayQueryParameters3D.create(center, center - n * 2.2, 1)
	var hit = space.intersect_ray(q)
	if not hit.is_empty() and float(hit["normal"].y) > 0.72 and up_amt > 0.2:
		# yüzey yürünebilir eğime döndü (kubbenin üst kısmı): duvardan bırak, üstünde yürü
		velocity = -n * 4.0 + Vector3.UP * 3.0
		_leave_wall()
		return
	if hit.is_empty():
		# duvar bitti: yukarı gidiyorsak kenara tutunup üstüne çık (çatı saçağı dahil); bulunamazsa tepeye fırla
		if up_amt > 0.2:
			var top = _find_ledge(n, false)
			if top != null:
				_start_mantle(top, n)
				return
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


## Duvarda Ctrl: chakra patlamasıyla duvar boyunca hızlı atılım (Striker)
func _wall_boost() -> void:
	if input_locked > 0.0 or has_status("stun") or has_status("bind"):
		return
	var cost = 6.0
	if chakra < cost or wall_boost_t > 0.0:
		return
	chakra -= cost
	wall_boost_t = 0.6
	FX.ring(global_position + Vector3.UP * 0.9, Color(0.5, 0.85, 1.0), 2.2, 0.3, false, wall_n)
	Sfx.play("whoosh", global_position, 1.2)


## Havada Q: ipli kunai — nişangâhtaki yüzeye/dala tutunup oraya çekil (düşüş başına bir kez)
func rope_kunai() -> bool:
	if grounded or wall_n != Vector3.ZERO or not rope_ok or input_locked > 0.0:
		return false
	var pt = aim_point(ROPE_RANGE)
	var from = global_position + Vector3.UP * 1.2
	if from.distance_to(pt) > ROPE_RANGE - 0.5 or from.distance_to(pt) < 3.0:
		Hud.msg("İpli kunai: tutunacak yer yok", Color(0.85, 0.85, 0.85), 1.0)
		return false
	rope_ok = false
	rope_pt = pt
	rope_t = 0.0
	velocity *= 0.3
	if rope_line == null:
		rope_line = MeshInstance3D.new()
		rope_line.mesh = ImmediateMesh.new()
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.85, 0.85, 0.9)
		rope_line.material_override = m
		rope_line.top_level = true
		rope_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rope_line)
	rope_line.visible = true
	model.play("throw", 0.05, 1.6, true)
	Sfx.play("kunai", global_position)
	FX.hit_spark(pt, Color(0.9, 0.9, 1.0), 0.5)
	return true


func _rope_move(dt: float) -> void:
	rope_t += dt
	var to = rope_pt - (global_position + Vector3.UP * 1.0)
	var d = to.length()
	var pull = to.normalized() * minf(34.0, 10.0 + rope_t * 60.0)
	velocity = velocity.lerp(pull, minf(1.0, dt * 8.0))
	move_and_slide()
	var g = Game.ground_height(global_position.x, global_position.z)
	if global_position.y < g:
		global_position.y = g
	facing = lerp_angle(facing, atan2(-to.x, -to.z), minf(1.0, dt * 10.0))
	model.rotation = Vector3(0, facing, 0)
	model.play("air", 0.15)
	model.overlay.set_pose("leap", 0.8)
	# ip çizgisi
	var im: ImmediateMesh = rope_line.mesh
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(global_position + Vector3.UP * 1.3 + face_dir() * 0.3)
	im.surface_add_vertex(rope_pt)
	im.surface_end()
	if d < 2.2 or rope_t > 1.6 or is_on_wall() or Input.is_action_just_pressed("jump"):
		_end_rope()


func _end_rope() -> void:
	rope_t = -1.0
	if rope_line:
		rope_line.visible = false
	velocity += Vector3.UP * 7.0  # tutunma noktasında hafif sıçrama: dala/çatıya çık
	model.overlay.set_pose("leap", 0.0)
	jumps = maxi(jumps, 1)


## Duvara yapış: süzülme/takla pozları hemen bırakılır, yoksa bacaklar süzülme pozunda donuk kalıyordu
func _enter_wall(n: Vector3, terrain: bool) -> void:
	wall_n = n
	terrain_wall = terrain
	wall_stall = 0.0
	velocity = Vector3.ZERO
	grounded = false
	air_dash_ok = true
	air_dash_used = 0
	leaping = false
	flip_t = -1.0
	model.overlay.snap("leap", 0.0)
	model.overlay.glide_land = 0.0
	model.overlay.tuck = 0.0
	Sfx.play("land", global_position, 1.3)


## Duvarın tepesinde ya da önündeki çıkıntıda (saçak, balkon, sundurma) basılabilir bir yüzey ara.
## overhang: yukarısı tıkalı (önce dışarı taşan çıkıntının üstüne bak); değilse önce çatının/duvarın üstüne.
func _find_ledge(n: Vector3, overhang: bool):
	var space = get_world_3d().direct_space_state
	var p = global_position
	var offs = [-0.6, -1.2, -1.8, 0.8, 1.6, 2.6] if overhang else [0.8, 1.6, 2.6, 3.6, -0.6, -1.2]
	for k in offs:
		var c = p - n * k   # k>0: duvarın içine (çatıya), k<0: duvardan dışarı (çıkıntı)
		var q = PhysicsRayQueryParameters3D.create(Vector3(c.x, p.y + 6.5, c.z), Vector3(c.x, p.y + 0.2, c.z), 1, [get_rid()])
		var h = space.intersect_ray(q)
		if h.is_empty() or (h["normal"] as Vector3).y < 0.5:
			continue
		var top: Vector3 = h["position"]
		# baş için boşluk: üstü açık olmalı
		var q2 = PhysicsRayQueryParameters3D.create(top + Vector3.UP * 0.15, top + Vector3.UP * 1.7, 1, [get_rid()])
		if not space.intersect_ray(q2).is_empty():
			continue
		return top + Vector3.UP * 0.05
	return null


func _start_mantle(target: Vector3, n: Vector3) -> void:
	var p = global_position
	var out = (target - p).dot(n) > 0.2   # dışarı taşan çıkıntı: önce dışarı çık, sonra üstüne
	var mid = (p + target) * 0.5
	if out:
		mid = Vector3(target.x, maxf(p.y, target.y) + 1.4, target.z) + n * 0.6
	mid.y = maxf(p.y, target.y) + 1.3
	mantle_pts = [p, mid, target]
	mantle_dur = clampf(p.distance_to(target) / 10.0, 0.28, 0.55)
	mantle_t = 0.0
	_leave_wall()
	var hd = target - p
	hd.y = 0
	if hd.length() > 0.2:
		facing = atan2(-hd.x, -hd.z)
	model.rotation = Vector3(0, facing, 0)
	model.play("jump", 0.05, 1.6, true)
	Sfx.play("whoosh", global_position, 1.3, 0.6)


func _mantle_move(dt: float) -> void:
	mantle_t += dt
	var k = clampf(mantle_t / mantle_dur, 0.0, 1.0)
	var a: Vector3 = mantle_pts[0]; var b: Vector3 = mantle_pts[1]; var c: Vector3 = mantle_pts[2]
	global_position = a.lerp(b, k).lerp(b.lerp(c, k), k)
	model.overlay.tuck = sin(PI * k) * 0.75
	velocity = Vector3.ZERO
	if k >= 1.0:
		mantle_t = -1.0
		model.overlay.tuck = 0.0
		var hd = c - a
		hd.y = 0
		velocity = hd.normalized() * 3.0 if hd.length() > 0.1 else Vector3.ZERO
		grounded = false
		wall_cd = 0.15
		land_t = 0.0


func _leave_wall() -> void:
	wall_stall = 0.0
	terrain_wall = false
	wall_n = Vector3.ZERO
	wall_cd = 0.25
	model.transform = Transform3D(Basis(Vector3.UP, facing), Vector3.ZERO)


var _step_ph := -1.0


## Ayak sesi: animasyonda ayağın yere bastığı anda (ölçülen temas fazları), zemine göre
func _footstep(_sp: float, sprint: bool) -> void:
	if not grounded or swimming:
		_step_ph = -1.0
		return
	if model.footstep_cross(_step_ph):
		Sfx.play(Game.step_sound(global_position), global_position, randf_range(0.92, 1.08), 0.32 if sprint else 0.26)
	_step_ph = model.anim_progress() if model.current in CharacterModel.FOOT_PHASES else -1.0


func _animate(sp: float, sprint: bool) -> void:
	_footstep(sp, sprint)
	var ov = model.overlay
	if model.current == "sit" and input_locked > 0.0:
		return   # tezgâhta/salıncakta otururken ayağa kalkmasın
	if swimming:
		model.play("swim" if sp > 0.5 else "swim_idle", 0.2)
		ov.set_pose("ninja_run", 0.0)
		return
	if not grounded:
		if model.current not in ["jump", "roll"] or model.anim_progress() > 0.95:
			model.play("air", 0.25)
		ov.set_pose("ninja_run", 0.0)
		# süper zıplama dışındaki düşüşlerde kollar açık süzülme pozu kalmasın (duvar/ip/vuruş/uçuş sonrası takılıyordu)
		if not leaping and flip_t < 0.0:
			ov.set_pose("leap", 0.0)
			ov.glide_land = move_toward(ov.glide_land, 0.0, get_physics_process_delta_time() * 4.0)
		if leaping and rope_t < 0.0:
			# süzülme; yere yaklaşırken inişe hazırlan (dizler öne)
			var h = global_position.y - Game.terrain_height(global_position.x, global_position.z)
			var want = clampf(1.0 - (h - 1.5) / 6.0, 0.0, 1.0) if velocity.y < 0.0 else 0.0
			ov.glide_land = move_toward(ov.glide_land, want, get_physics_process_delta_time() * 4.0)
		return
	# yerdeyken süzülme/takla pozları her durumda bırakılır
	if not leaping:
		ov.set_pose("leap", 0.0)
		ov.glide_land = 0.0
		if mantle_t < 0.0 and flip_t < 0.0:
			ov.tuck = 0.0
	if land_t > 0.0:
		return
	if sp > 0.6:
		var run_anim = "run" if sp > 8.0 else ("walk" if sp < 3.5 else "jog")
		model.play(run_anim, 0.15, clampf(sp / 2.4, 0.7, 1.3) if run_anim == "walk" else clampf(sp / (16.0 if sprint else 10.0), 0.7, 1.6))
		ov.set_pose("ninja_run", 1.0 if sprint else 0.0)
	else:
		model.play("idle", 0.2)
		ov.set_pose("ninja_run", 0.0)


func _update_camera(dt: float) -> void:
	var target = get_global_transform_interpolated().origin + Vector3.UP * (1.6 * (model.age_scale if model else 1.0) + cam_lift)
	cam_pivot.global_position = cam_pivot.global_position.lerp(target, minf(1.0, dt * 16.0))
	# dev formda kamera yukarıdan bakar (kuyruklar/gövde ekranı kapatmasın)
	cam_pivot.rotation = Vector3(deg_to_rad(pitch - (2.0 if cam_giant else 0.0)), deg_to_rad(yaw), 0)
	# kamera duvarlara ve araziye girmesin
	var back = cam_pivot.global_transform.basis.z
	var want = cam_dist
	var space = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(cam_pivot.global_position, cam_pivot.global_position + back * cam_dist, 1)
	var hit = {} if cam_giant else space.intersect_ray(q)
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
	# savunma azalan getirili: 20 puan %25, 40 puan %40, en fazla %45 (tam zırh ölümsüz yapmasın)
	var dfn = maxf(0.0, Gear.stat(Game.profile, "def"))
	var armor = Buffs.mod("armor") * (1.0 - minf(dfn / (dfn + 60.0), 0.45)) * (1.0 - clampf(Stats.skill(Game.profile, "def"), 0.0, 0.5))
	info = info.duplicate()
	info["dmg"] = info.get("dmg", 5.0) * armor
	if combat:
		combat.take_hit(info)


var statuses = {}  # element durumları: burn, wet, frozen, chilled, shocked, mud, stun, bind, slow


func apply_status(n: String, d: float) -> void:
	if n in ["stun", "bind", "fear", "kokuangyo"]:
		d /= 1.0 + Stats.skill(Game.profile, "gen_resist")  # genjutsu direnci
		if n != "bind" and Stats.has_unlock(Game.profile, "kai") and not statuses.has("_kai_tip"):
			statuses["_kai_tip"] = 30.0
			Hud.msg("Genjutsu! [Q] Kai ile çöz", Color(0.8, 0.6, 1.0), 2.0)
	d = Combat.cc_dur(self, n, d)
	if d <= 0.0:
		return
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
		hp -= 4.0 * clampf(1.0 - Stats.skill(Game.profile, "poison_resist"), 0.2, 1.0) * dt
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
	mantle_t = -1.0
	flip_t = -1.0
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
