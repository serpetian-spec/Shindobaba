class_name ClanTrait
extends Node
## Klan ninjasının (Enemy çocuğu) klana özgü savaş davranışı — jutsu listesinin üstüne gerçek klan yetenekleri:
## Uchiha: Sharingan bakışı genjutsusu (sersemletir)  •  Hyūga: Hakke Kūshō + Kaiten + Jūken (chakra keser)
## Kaguya: yerden kemik mızraklar  •  Chinoike: kan genjutsusu (sersemletme + kanama)  •  Nara: gölge bağı
## Akimichi: büyüyüp gövde çarpması  •  Aburame: chakra emen böcek sürüsü  •  Hōzuki: vuruşta suya dönüşme
## duel: dostça düelloda %25 canda teslim olur.

var clan := ""
var eye_kind := 0
var duel := false
var on_yield: Callable
var f: Enemy
var cd := 3.0
var last_hp := -1.0
var _yielded := false


func _ready() -> void:
	f = get_parent()
	cd = randf_range(2.0, 4.0)


func _physics_process(dt: float) -> void:
	if f == null or Game.paused:
		return
	if f.dead:
		if duel and not _yielded and on_yield.is_valid():
			_yielded = true
			on_yield.call(true)
		return
	# Hōzuki: gelen hasarın bir kısmını su bedeniyle boşa çıkar
	if clan == "hozuki" and last_hp > 0.0 and f.hp < last_hp and randf() < 0.4:
		var lost: float = last_hp - f.hp
		f.hp = minf(f.max_hp, f.hp + lost * 0.85)
		VFX.splash(f.global_position + Vector3.UP * 1.0, 1.6)
		Combat.popup_text(f.global_position + Vector3.UP * 2.2, "Suika!", Color(0.6, 0.85, 1.0))
	last_hp = f.hp
	if duel and f.hp < f.max_hp * 0.25:
		_yield()
		return
	cd -= dt
	var t: Node3D = f.target
	if cd > 0.0 or t == null or not is_instance_valid(t) or t.is_dead() or f.state in ["hitstun", "knockdown", "cast"]:
		return
	var d := f.global_position.distance_to(t.global_position)
	match clan:
		"uchiha":
			if d < 16.0 and _sees(t):
				_sharingan(t)
				cd = randf_range(9.0, 13.0)
		"hyuga", "otsutsuki":
			if d < 3.4:
				_kaiten()
				cd = randf_range(7.0, 9.0)
			elif d < 13.0:
				_kusho(t)
				cd = randf_range(4.5, 6.5)
		"kaguya":
			if d < 9.0:
				_bone_spikes(t)
				cd = randf_range(5.0, 7.0)
		"chinoike":
			if d < 14.0 and _sees(t):
				_blood_gaze(t)
				cd = randf_range(10.0, 13.0)
		"nara":
			if d < 15.0:
				_shadow_bind(t)
				cd = randf_range(11.0, 14.0)
		"akimichi":
			if d < 9.0:
				_body_slam(t)
				cd = randf_range(10.0, 12.0)
		"aburame":
			if d < 14.0:
				_swarm(t)
				cd = randf_range(9.0, 12.0)
		_:
			cd = 99.0


func _sees(t: Node3D) -> bool:
	if not t.has_method("face_dir"):
		return true
	var to := (f.global_position - t.global_position)
	to.y = 0
	return t.face_dir().dot(to.normalized()) > 0.3


func _cast_pose(txt: String, col: Color) -> void:
	f.state = "recover"
	f.state_t = -0.4
	f.model.play("cast_out", 0.05, 1.2, true)
	Combat.popup_text(f.global_position + Vector3.UP * (f.height + 1.0), txt, col)


func _stun(t: Node3D, dur: float) -> void:
	if t.has_method("apply_status"):
		t.apply_status("stun", dur)


# ------------------------------------------------------------------ Uchiha
func _sharingan(t: Node3D) -> void:
	_cast_pose("Genjutsu: Sharingan", Color(1, 0.25, 0.25))
	var eye: Vector3 = f.global_position + Vector3.UP * (f.height * 0.92)
	# dönen üç tomoe halkası göz hizasında, hedefe doğru
	var ring := Node3D.new()
	f.add_child(ring)
	ring.global_position = eye + f.face_dir() * 0.6
	for i in 3:
		var tm := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18
		tm.mesh = sm
		tm.material_override = _unshaded(Color(0.05, 0.0, 0.0))
		tm.position = Vector3(cos(i * TAU / 3.0), sin(i * TAU / 3.0), 0) * 0.35
		ring.add_child(tm)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.55
	cm.bottom_radius = 0.55
	cm.height = 0.02
	disc.mesh = cm
	disc.rotation.x = PI * 0.5
	disc.material_override = _unshaded(Color(0.85, 0.05, 0.05, 0.75))
	ring.add_child(disc)
	ring.look_at(t.global_position + Vector3.UP * 1.5)
	var tw := ring.create_tween().set_parallel()
	tw.tween_property(ring, "rotation:z", ring.rotation.z + TAU * 2.0, 0.9)
	tw.tween_property(ring, "scale", Vector3.ONE * 2.2, 0.9)
	tw.chain().tween_callback(ring.queue_free)
	if t == Game.player:
		Game.world.env.screen_flash(0.45)
		Game.world.env.flash_tint(Color(0.9, 0.1, 0.1, 0.22), 1.6)   # eskiden opak renk + düşman ölünce sıfırlanmayan zamanlayıcı: ekran kırmızı kalıyordu
	_stun(t, 1.4)
	Sfx.play("seal", f.global_position, 0.7)


# ------------------------------------------------------------------ Hyūga
func _kusho(t: Node3D) -> void:
	_cast_pose("Hakke Kūshō", Color(0.85, 0.9, 1.0))
	var from := f.global_position + Vector3.UP * 1.2 + f.face_dir() * 0.6
	var dir := (t.global_position + Vector3.UP - from).normalized()
	for i in 4:
		VFX.shockwave(from + dir * (1.5 + i * 2.6), Color(0.85, 0.92, 1.0, 0.8), 1.6 + i * 0.5, 0.35, false, dir)
	Combat.hit_sphere(f, t.global_position + Vector3.UP, 1.4, {"dmg": 10.0 * f.power, "knock": 14.0, "launch": 2.0, "kind": "heavy", "hitstop": 0.06})
	_juken(t, 10.0)


func _kaiten() -> void:
	_cast_pose("Hakkeshō Kaiten", Color(0.85, 0.92, 1.0))
	f.model.play("spin", 0.05, 1.4, true)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 1.2
	sm.is_hemisphere = true
	dome.mesh = sm
	dome.material_override = VFX.mat_wind(Color(0.82, 0.92, 1.0), 9.0, 7.0, Vector3.UP, 0.75)
	get_tree().current_scene.add_child(dome)
	dome.global_position = f.global_position
	var tw := dome.create_tween().set_parallel()
	tw.tween_property(dome, "scale", Vector3(4.0, 3.2, 4.0), 0.25)
	tw.tween_property(dome, "rotation:y", TAU * 3.0, 0.9)
	tw.chain().tween_property(dome, "scale", Vector3(4.6, 0.2, 4.6), 0.25)
	tw.chain().tween_callback(dome.queue_free)
	FX.dust(f.global_position, 2.0)
	VFX.cracks(f.global_position, 4.0)
	Combat.hit_sphere(f, f.global_position + Vector3.UP, 3.8, {"dmg": 14.0 * f.power, "knock": 18.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.08})


## Jūken: chakra noktalarına vuruş — oyuncunun chakrası kesilir
func _juken(t: Node3D, amount: float) -> void:
	if t == Game.player:
		Game.player.chakra = maxf(0.0, Game.player.chakra - amount)
		Combat.popup_text(t.global_position + Vector3.UP * 2.0, "Chakra noktası kapandı -%d" % int(amount), Color(0.7, 0.8, 1.0))


# ------------------------------------------------------------------ Kaguya
func _bone_spikes(t: Node3D) -> void:
	_cast_pose("Sawarabi no Mai", Color(0.95, 0.95, 0.9))
	var c := t.global_position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.93, 0.86)
	mat.roughness = 0.6
	for i in 9:
		var a := randf() * TAU
		var r := randf_range(0.0, 2.6) if i > 0 else 0.0
		var p := c + Vector3(cos(a) * r, 0, sin(a) * r)
		p.y = Game.ground_height(p.x, p.z) - 0.2
		var sp := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = randf_range(0.18, 0.32)
		cm.height = randf_range(2.0, 3.6)
		cm.radial_segments = 6
		sp.mesh = cm
		sp.material_override = mat
		get_tree().current_scene.add_child(sp)
		sp.global_position = p + Vector3.UP * cm.height * 0.5
		sp.rotation = Vector3(randf_range(-0.35, 0.35), randf() * TAU, randf_range(-0.35, 0.35))
		sp.scale = Vector3(1, 0.01, 1)
		var tw := sp.create_tween()
		tw.tween_interval(0.05 * i)
		tw.tween_property(sp, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(2.2)
		tw.tween_property(sp, "scale", Vector3(1, 0.01, 1), 0.4)
		tw.tween_callback(sp.queue_free)
	FX.dust(c, 1.4)
	VFX.debris(c, Color(0.5, 0.42, 0.32), 10, 8.0, 0.35)
	Combat.hit_sphere(f, c + Vector3.UP * 0.8, 2.2, {"dmg": 16.0 * f.power, "knock": 4.0, "launch": 7.0, "kind": "heavy", "hitstop": 0.07})


# ------------------------------------------------------------------ Chinoike
func _blood_gaze(t: Node3D) -> void:
	_cast_pose("Ketsuryūgan: Kan Genjutsusu", Color(0.95, 0.15, 0.2))
	FX.burst(f.global_position + Vector3.UP * 1.6, {"amount": 40, "life": 1.2, "add": false, "size": 0.9, "vmin": 2, "vmax": 6,
		"colors": [Color(0.6, 0.02, 0.05, 0.9), Color(0.3, 0.0, 0.02, 0)]})
	if t == Game.player:
		Game.world.env.flash_tint(Color(0.7, 0.0, 0.05, 0.28), 2.0)
	_stun(t, 1.8)
	if t.has_method("apply_status"):
		t.apply_status("burn", 3.0)   # iç kanama: zamanla can kaybı


# ------------------------------------------------------------------ Nara
func _shadow_bind(t: Node3D) -> void:
	_cast_pose("Kagemane no Jutsu", Color(0.5, 0.5, 0.6))
	var a := f.global_position
	var b := t.global_position
	var mid := (a + b) * 0.5
	var L := Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
	var strip := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.45, 0.02, 1.0)
	strip.mesh = bm
	strip.material_override = _unshaded(Color(0.02, 0.02, 0.03, 0.92))
	get_tree().current_scene.add_child(strip)
	strip.global_position = Vector3(a.x, Game.ground_height(a.x, a.z) + 0.05, a.z)
	strip.look_at(Vector3(b.x, strip.global_position.y, b.z))
	var tw := strip.create_tween()
	tw.tween_method(func(k: float):
		strip.scale = Vector3(1, 1, maxf(0.01, L * k))
		strip.global_position = Vector3(a.x, Game.ground_height(mid.x, mid.z) + 0.05, a.z).lerp(Vector3(mid.x, Game.ground_height(mid.x, mid.z) + 0.05, mid.z), k), 0.0, 1.0, 0.5)
	tw.tween_callback(func():
		if is_instance_valid(t) and t.global_position.distance_to(b) < 4.0 and t.has_method("apply_status"):
			t.apply_status("bind", 2.2)
			Combat.popup_text(t.global_position + Vector3.UP * 2.0, "Gölgen bağlandı!", Color(0.6, 0.6, 0.7)))
	tw.tween_interval(2.2)
	tw.tween_callback(strip.queue_free)


# ------------------------------------------------------------------ Akimichi
func _body_slam(t: Node3D) -> void:
	_cast_pose("Baika no Jutsu!", Color(1, 0.6, 0.3))
	FX.smoke_puff(f.global_position + Vector3.UP, 1.4, 16)
	var m: Node3D = f.model
	var base: Vector3 = m.scale
	var tw := m.create_tween()
	tw.tween_property(m, "scale", base * 2.6, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func():
		if not is_instance_valid(t):
			return
		var land := t.global_position
		FX.dust(land, 2.6)
		VFX.shockwave(land + Vector3.UP * 0.2, Color(0.9, 0.75, 0.5, 0.8), 7.0, 0.45)
		VFX.cracks(land, 5.0)
		if Game.world:
			Game.world.env.add_shake(0.6)
		Combat.hit_sphere(f, land + Vector3.UP, 3.2, {"dmg": 22.0 * f.power, "knock": 16.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.1}))
	tw.tween_interval(1.4)
	tw.tween_property(m, "scale", base, 0.3)


# ------------------------------------------------------------------ Aburame
func _swarm(t: Node3D) -> void:
	_cast_pose("Kikaichū Sürüsü", Color(0.5, 0.55, 0.4))
	var from := f.global_position + Vector3.UP * 1.2
	var cloud := FX.burst(from, {"amount": 60, "life": 1.6, "add": false, "size": 0.12, "vmin": 1, "vmax": 3, "gravity": Vector3.ZERO,
		"colors": [Color(0.05, 0.05, 0.04, 1), Color(0.1, 0.1, 0.08, 0)]})
	var tw := create_tween()
	tw.tween_method(func(k: float):
		if is_instance_valid(cloud) and is_instance_valid(t):
			cloud.global_position = from.lerp(t.global_position + Vector3.UP, k), 0.0, 1.0, 0.7)
	tw.tween_callback(func():
		if is_instance_valid(t):
			Combat.hit_sphere(f, t.global_position + Vector3.UP, 1.6, {"dmg": 6.0 * f.power, "knock": 0.0, "kind": "light"})
			_juken(t, 18.0)
			if t.has_method("apply_status"):
				t.apply_status("slow", 3.0))


# ------------------------------------------------------------------ düello
func _yield() -> void:
	_yielded = true
	f.dead = true
	f.team = "neutral"
	f.target = null
	f.remove_from_group("fighters")
	f.model.play("idle", 0.2)
	Combat.popup_text(f.global_position + Vector3.UP * (f.height + 1.0), "Tamam, tamam! Pes ediyorum!", Color(1, 0.9, 0.6))
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(func():
		FX.smoke_puff(f.global_position + Vector3.UP, 1.0, 14)
		if on_yield.is_valid():
			on_yield.call(true)
		f.queue_free())


func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
