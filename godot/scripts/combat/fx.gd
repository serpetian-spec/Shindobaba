extends Node
## Görsel efektler (autoload "FX"): GPU parçacıkları, şok dalgaları, ışık çakmaları, iz efektleri.

var tex_soft: ImageTexture
var tex_spark: ImageTexture
var tex_smoke: ImageTexture
var tex_ring: ImageTexture
var tex_leaf: ImageTexture
var _mats = {}


func _ready() -> void:
	tex_soft = _radial(64, 2.2)
	tex_spark = _spark()
	tex_smoke = _smoke()
	tex_ring = _ring()
	tex_leaf = _leaf()


# ------------------------------------------------------------------ dokular
func _radial(s: int, p: float) -> ImageTexture:
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d = Vector2(x - s * 0.5 + 0.5, y - s * 0.5 + 0.5).length() / (s * 0.5)
			var a = pow(clampf(1.0 - d, 0, 1), p)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _spark() -> ImageTexture:
	var w = 16; var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u = absf(x - w * 0.5 + 0.5) / (w * 0.5); var v = absf(y - h * 0.5 + 0.5) / (h * 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, pow(clampf(1.0 - u, 0, 1), 2.0) * pow(clampf(1.0 - v, 0, 1), 0.8)))
	return ImageTexture.create_from_image(img)


func _smoke() -> ImageTexture:
	var s = 64
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var n = FastNoiseLite.new()
	n.frequency = 0.08
	for y in s:
		for x in s:
			var d = Vector2(x - s * 0.5, y - s * 0.5).length() / (s * 0.5)
			var a = clampf(1.0 - d, 0, 1)
			a = pow(a, 1.3) * (0.65 + 0.35 * n.get_noise_2d(x, y))
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a * 1.4, 0, 1)))
	return ImageTexture.create_from_image(img)


func _ring() -> ImageTexture:
	var s = 128
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d = Vector2(x - s * 0.5, y - s * 0.5).length() / (s * 0.5)
			var a = exp(-pow((d - 0.85) * 9.0, 2.0))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _leaf() -> ImageTexture:
	# yaprak silüeti: iki ucu sivri, yatay; ortada koyu damar, kenara doğru hafif koyulaşma, kısa sap
	var s = 64
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var u = (x - s * 0.5) / (s * 0.46); var v = (y - s * 0.5) / (s * 0.5)
			var half = pow(maxf(0.0, 1.0 - u * u), 0.75) * (0.62 + 0.12 * u)
			var a = 1.0 - smoothstep(half - 0.06, half, absf(v))
			if u < -1.0 and u > -1.22 and absf(v) < 0.05:
				a = 1.0   # sap
			var sh = 1.0 - 0.25 * smoothstep(0.2, 1.0, absf(v) / maxf(half, 0.01))
			if absf(v) < 0.035 and absf(u) < 0.9:
				sh *= 0.72   # orta damar
			elif absf(absf(v) - absf(u + 0.6) * 0.5 + 0.0) < 0.03 and u > -0.6 and u < 0.7 and absf(v) < half * 0.8:
				sh *= 0.85   # yan damarlar
			img.set_pixel(x, y, Color(sh, sh, sh, a))
	return ImageTexture.create_from_image(img)


func _draw_mat(tex: Texture2D, additive: bool, billboard := BaseMaterial3D.BILLBOARD_PARTICLES) -> StandardMaterial3D:
	var key = "%s_%s_%d" % [tex.get_instance_id(), additive, billboard]
	if _mats.has(key):
		return _mats[key]
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = billboard
	m.billboard_keep_scale = true
	m.disable_receive_shadows = true
	m.no_depth_test = false
	_mats[key] = m
	return m


func _gradient(cols: Array) -> GradientTexture1D:
	var g = Gradient.new()
	var offs = PackedFloat32Array()
	var cc = PackedColorArray()
	for i in cols.size():
		offs.append(float(i) / maxf(1.0, cols.size() - 1))
		cc.append(cols[i])
	g.offsets = offs
	g.colors = cc
	var t = GradientTexture1D.new()
	t.gradient = g
	return t


func _curve(points: Array) -> CurveTexture:
	var c = Curve.new()
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var t = CurveTexture.new()
	t.curve = c
	return t


## Renk rampasına göre cel topak parlaklığı: sıcak/doygun renkler (alev, enerji) parlar, gri duman parlamaz
func _auto_glow(cfg: Dictionary) -> float:
	var cols: Array = cfg.get("colors", [Color.WHITE])
	var c: Color = cols[mini(1, cols.size() - 1)]
	return 1.1 if c.s > 0.55 and c.v > 0.7 else 1.0


func _auto_outline(cfg: Dictionary) -> Color:
	var cols: Array = cfg.get("colors", [Color.WHITE])
	var c: Color = cols[mini(1, cols.size() - 1)]
	return Color.from_hsv(c.h, minf(1.0, c.s + 0.2), c.v * 0.28)


## Genel amaçlı tek seferlik parçacık patlaması
func burst(pos: Vector3, cfg: Dictionary) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = cfg.get("explosive", 0.95)
	p.amount = cfg.get("amount", 24)
	p.lifetime = cfg.get("life", 0.6)
	p.fixed_fps = 60
	p.local_coords = cfg.get("local", false)
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = cfg.get("radius", 0.2)
	pm.direction = cfg.get("dir", Vector3.UP)
	pm.spread = cfg.get("spread", 180.0)
	pm.initial_velocity_min = cfg.get("vmin", 2.0)
	pm.initial_velocity_max = cfg.get("vmax", 6.0)
	pm.gravity = cfg.get("gravity", Vector3.ZERO)
	pm.damping_min = cfg.get("damp", 2.0)
	pm.damping_max = cfg.get("damp", 2.0) * 1.5
	pm.scale_min = cfg.get("smin", 0.5)
	pm.scale_max = cfg.get("smax", 1.0)
	pm.angle_min = 0; pm.angle_max = 360
	pm.angular_velocity_min = cfg.get("spin", 0.0) * -1.0
	pm.angular_velocity_max = cfg.get("spin", 0.0)
	pm.color_ramp = _gradient(cfg.get("colors", [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	pm.scale_curve = _curve(cfg.get("scale_curve", [[0.0, 0.6], [0.3, 1.0], [1.0, 0.8]]))
	if cfg.has("orbit"):
		pm.orbit_velocity_min = cfg["orbit"]; pm.orbit_velocity_max = cfg["orbit"] * 1.4
	if cfg.has("tangent"):
		pm.tangential_accel_min = cfg["tangent"]; pm.tangential_accel_max = cfg["tangent"]
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2.ONE * cfg.get("size", 1.0)
	var tex: Texture2D = cfg.get("tex", tex_soft)
	var bb: int = cfg.get("billboard", BaseMaterial3D.BILLBOARD_PARTICLES)
	# sert kenarlı cel topak: açıkça istenirse ya da (duman dokusu + karışımlı) tüm eski duman/alev çağrıları
	var cel: bool = cfg.get("cel", (tex == tex_smoke or tex == tex_soft) and not cfg.get("add", true))
	if cel:
		q.material = VFX.mat_puff(cfg.get("glow", _auto_glow(cfg)), cfg.get("hot", 0.0), cfg.get("outline_col", _auto_outline(cfg)),
			cfg.get("rough", 0.32), cfg.get("shade", 0.3), cfg.get("stretch", 1.0), cfg.get("outline", 0.07))
		p.draw_pass_1 = q
	elif tex == tex_spark:
		q.size = Vector2(0.12, 0.6) * cfg.get("size", 1.0)
		pm.particle_flag_align_y = true
		bb = BaseMaterial3D.BILLBOARD_DISABLED
	if not cel:
		q.material = _draw_mat(tex, cfg.get("add", true), bb)
	p.draw_pass_1 = q
	var vr = 20.0 + float(cfg.get("radius", 0.2)) * 1.5   # geniş yayılımlı bulutlar (Kirin fırtınası) kenarda kırpılmasın
	p.visibility_aabb = AABB(Vector3(-vr, -vr, -vr), Vector3(vr, vr, vr) * 2.0)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var parent: Node = cfg.get("parent", get_tree().current_scene)
	parent.add_child(p)
	if p.local_coords and parent != get_tree().current_scene:
		p.position = pos
	else:
		p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Genişleyen halka (yere paralel ya da kameraya dönük) — sert kenarlı anime şok dalgası
func ring(pos: Vector3, col: Color, size := 4.0, dur := 0.35, flat := true, normal := Vector3.UP) -> void:
	VFX.shockwave(pos, col, size, dur, flat, normal)


## Anlık çarpma flaşı: yumuşak beyaz küre yerine sivri anime yıldız
func flash_sphere(pos: Vector3, col: Color, size := 2.0, dur := 0.25) -> void:
	VFX.star(pos, col, size * 1.1, maxf(0.14, dur * 0.8))


## Geçici nokta ışık (patlamalar, jutsu parıltısı)
func light(pos: Vector3, col: Color, energy := 4.0, rng := 10.0, dur := 0.3) -> void:
	var l = OmniLight3D.new()
	l.light_color = col
	# efekt ışıkları sahneyi beyaza boğmasın (özellikle gece): yumuşak, kısa menzil
	energy = minf(energy * 0.28, 1.6)
	rng *= 0.7
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	var tw = l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, dur)
	tw.tween_callback(l.queue_free)


# ------------------------------------------------------------------ hazır efektler
## Kan: vuruş yönünde sıçrayan koyu kırmızı damlalar (yerçekimli) + kısa sis; yere düşen leke bir süre kalır.
## amount 0..1 (darbenin şiddeti). Ayarlar > Kan kapalıysa hiçbir şey yapmaz.
func blood(pos: Vector3, dir: Vector3, amount := 0.5) -> void:
	if not bool(Game.settings.get("blood", true)):
		return
	amount = clampf(amount, 0.15, 1.0)
	var d = dir.normalized() if dir.length() > 0.05 else Vector3.UP
	d = (d + Vector3.UP * 0.35).normalized()
	# sıçrama: koyu kan damlaları, yerçekimiyle yay çizip düşer
	burst(pos, {"amount": int(14 + 26 * amount), "life": 0.7, "size": 0.15, "vmin": 2.0, "vmax": 5.0 + 3.0 * amount, "dir": d, "spread": 30.0,
		"gravity": Vector3(0, -16.0, 0), "damp": 0.3, "add": false, "cel": false, "tex": tex_soft, "smin": 0.5, "smax": 1.3,
		"colors": [Color(0.5, 0.0, 0.02, 1.0), Color(0.36, 0.0, 0.015, 1.0), Color(0.22, 0.0, 0.01, 0.0)], "explosive": 1.0})
	burst(pos, {"amount": int(4 + 5 * amount), "life": 0.35, "size": 0.38 * (0.6 + amount), "vmin": 0.6, "vmax": 1.6, "dir": d, "spread": 40.0,
		"damp": 3.0, "add": false, "cel": false, "tex": tex_soft,
		"colors": [Color(0.42, 0.0, 0.02, 0.7), Color(0.28, 0.0, 0.01, 0.0)]})
	var space = get_viewport().get_world_3d().direct_space_state
	var ground = func(gp: Vector2, top: float) -> float:
		var gy = Game.ground_height(gp.x, gp.y)
		var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(gp.x, top, gp.y), Vector3(gp.x, gy - 1.0, gp.y), 1))
		return maxf(gy, float(hit["position"].y)) if not hit.is_empty() else gy
	# damlalar yere iner: sıçrama yönünde birkaç küçük leke (düşüş süresi kadar gecikmeli) + ana gölcük
	var hd = Vector2(d.x, d.z).normalized() if Vector2(d.x, d.z).length() > 0.05 else Vector2.ZERO
	var drops = int(2 + 5 * amount)
	for i in drops:
		var dist = randf_range(0.3, 1.6) * (0.6 + amount)
		var gp = Vector2(pos.x, pos.z) + hd * dist + Vector2(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35))
		var gy = ground.call(gp, pos.y + 0.5)
		var delay = clampf(sqrt(maxf(0.0, pos.y - gy) / 8.0), 0.12, 0.5) + dist * 0.05
		get_tree().create_timer(delay).timeout.connect(_blood_decal.bind(Vector3(gp.x, gy + 0.025, gp.y), randf_range(0.12, 0.28) * (0.7 + amount)))
	var gp0 = Vector2(pos.x, pos.z) + hd * 0.5
	get_tree().create_timer(0.35).timeout.connect(_blood_decal.bind(Vector3(gp0.x, ground.call(gp0, pos.y + 0.5) + 0.02, gp0.y), 0.45 + amount * 0.6))
	# yaradan süzülen birkaç damla: düz aşağı, yavaş
	if amount > 0.35:
		burst(pos + Vector3(0, -0.1, 0), {"amount": 3, "life": 0.9, "size": 0.07, "vmin": 0.0, "vmax": 0.4, "dir": Vector3.DOWN, "spread": 10.0,
			"gravity": Vector3(0, -9.0, 0), "damp": 0.0, "add": false, "cel": false, "tex": tex_soft, "explosive": 0.3,
			"colors": [Color(0.45, 0.0, 0.02, 1.0), Color(0.3, 0.0, 0.01, 1.0)]})


## Kan gölcüğü dokusu: birkaç metaball'dan düzensiz, keskin kenarlı sıvı birikintisi; kenarı biraz koyu,
## üstte ıslak parlama lekesi (yumuşak bulanık leke kar tanesi gibi duruyordu). 4 çeşit önbellekte.
var _puddle_tex: Array = []
func _puddle(i: int) -> Texture2D:
	if _puddle_tex.is_empty():
		var rng = RandomNumberGenerator.new()
		rng.seed = 7731
		for v in 4:
			var N = 128
			var img = Image.create(N, N, false, Image.FORMAT_RGBA8)
			var balls = [[Vector2(0.5, 0.5), 0.13]]
			for k in 6 + v:
				var a = rng.randf() * TAU
				var d = rng.randf_range(0.06, 0.2)
				balls.append([Vector2(0.5, 0.5) + Vector2(cos(a), sin(a)) * d, rng.randf_range(0.04, 0.09)])
			for k in 4:   # ana gölden kopmuş küçük damlalar
				var a = rng.randf() * TAU
				balls.append([Vector2(0.5, 0.5) + Vector2(cos(a), sin(a)) * rng.randf_range(0.3, 0.38), rng.randf_range(0.015, 0.025)])
			var hl = Vector2(0.42, 0.4)
			for y in N:
				for x in N:
					var p = Vector2(x + 0.5, y + 0.5) / N
					var f = 0.0
					for bb in balls:
						f += bb[1] * bb[1] / maxf(0.0001, p.distance_squared_to(bb[0]))
					var al = clampf((f - 1.0) / 0.25, 0.0, 1.0) * clampf((0.5 - maxf(absf(p.x - 0.5), absf(p.y - 0.5))) / 0.04, 0.0, 1.0)
					if al <= 0.0:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
						continue
					var rim = clampf((f - 1.0) / 1.2, 0.0, 1.0)
					var c = lerpf(0.55, 1.0, rim)
					var shine = clampf(1.0 - p.distance_to(hl) / 0.09, 0.0, 1.0) * clampf((f - 2.0) / 2.0, 0.0, 1.0)
					img.set_pixel(x, y, Color(c + shine * 1.4, c + shine * 0.9, c + shine * 0.9, al))
			_puddle_tex.append(ImageTexture.create_from_image(img))
	return _puddle_tex[i % _puddle_tex.size()]


## Kan lekeleri: ceset kalkmadan silinmez (ceset en fazla 90 sn kalır → leke 100 sn), en eski leke üst sınırda söner
var _blood_list: Array = []
func _blood_decal(p: Vector3, r: float, life := 100.0) -> Node3D:
	if _blood_list.size() > 160:
		var old = _blood_list.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	# Decal: eğimli kumu/taşı sarar (düz quad zemine gömülüp yarım kalıyordu)
	var mi = Decal.new()
	mi.texture_albedo = _puddle(randi())
	mi.modulate = Color(0.4, 0.01, 0.025, 0.97)
	mi.size = Vector3(r * randf_range(1.1, 1.5) * 2.0, 1.2, r * 2.0)
	mi.cull_mask = 1
	mi.upper_fade = 0.3
	mi.lower_fade = 0.3
	get_tree().current_scene.add_child(mi)
	mi.global_position = p
	mi.rotation.y = randf() * TAU
	_blood_list.append(mi)
	# sıvı yayılır: küçük başlayıp yavaşça genişler
	mi.scale = Vector3.ONE * 0.35
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if life > 0.0:
		tw.tween_interval(life)
		tw.tween_property(mi, "modulate:a", 0.0, 3.0)
		tw.tween_callback(func():
			_blood_list.erase(mi)
			mi.queue_free())
	return mi


## Cesedin altında yavaşça yayılan büyük kan gölü; ceset kalkınca söner (sahibi: corpse)
func blood_pool(corpse: Node3D, r := 1.3) -> void:
	if not bool(Game.settings.get("blood", true)) or not is_instance_valid(corpse):
		return
	var p = corpse.global_position
	var mi = _blood_decal(Vector3(p.x, Game.ground_height(p.x, p.z) + 0.1, p.z), r, 0.0)
	mi.scale = Vector3.ONE * 0.15
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	corpse.tree_exiting.connect(func():
		if is_instance_valid(mi):
			var t2 = mi.create_tween()
			t2.tween_interval(8.0)
			t2.tween_property(mi, "modulate:a", 0.0, 3.0)
			t2.tween_callback(func():
				_blood_list.erase(mi)
				mi.queue_free()))


func dust(pos: Vector3, s := 1.0) -> void:
	# anime tozu: yumuşak kenarlı, açık ve ince konturlu, az (kalın kahverengi konturlu kaba topaklar fazla duruyordu)
	burst(pos + Vector3.UP * 0.15, {"cel": true, "amount": int(5 * s) + 3, "life": 0.7, "size": 0.95 * s, "radius": 0.45 * s,
		"vmin": 1.5, "vmax": 4.0 * s, "dir": Vector3.UP, "spread": 80.0, "damp": 4.5, "gravity": Vector3(0, -0.5, 0), "spin": 40.0,
		"glow": 1.0, "outline_col": Color(0.66, 0.58, 0.47), "rough": 0.15, "shade": 0.18, "outline": 0.03,
		"colors": [Color(0.9, 0.84, 0.72, 0.85), Color(0.84, 0.78, 0.66, 0.6), Color(0.78, 0.72, 0.62, 0.0)],
		"scale_curve": [[0.0, 0.45], [0.3, 1.0], [1.0, 1.15]]})


## Anime "puf" bulutu (Kawarimi, çağırma, gölge klon): beyaz kabarık cel topaklar + gri gölge + kontur
func smoke_puff(pos: Vector3, s := 1.0, n := 14) -> void:
	burst(pos, {"cel": true, "amount": n, "life": 0.85, "size": 1.9 * s, "radius": 0.55 * s, "vmin": 1.5, "vmax": 4.0 * s,
		"damp": 4.0, "gravity": Vector3(0, 1.5, 0), "spin": 80.0, "glow": 1.0, "shade": 0.22, "rough": 0.3,
		"outline_col": Color(0.35, 0.36, 0.42),
		"colors": [Color(1, 1, 1, 1), Color(0.96, 0.96, 0.98, 1), Color(0.9, 0.9, 0.93, 0.6), Color(0.88, 0.88, 0.92, 0.0)],
		"scale_curve": [[0.0, 0.35], [0.2, 1.0], [1.0, 1.2]]})
	VFX.star(pos, Color(1, 1, 1), 1.6 * s, 0.12)
	Sfx.play("poof", pos)


func speed_lines(pos: Vector3, dir: Vector3) -> void:
	burst(pos, {"amount": 14, "life": 0.25, "tex": tex_spark, "size": 2.2, "vmin": 10, "vmax": 18, "dir": -dir,
		"spread": 12.0, "radius": 0.8, "damp": 1.0, "colors": [Color(1, 1, 1, 0.8), Color(0.8, 0.9, 1, 0)]})


## Vuruş kıvılcımı: sivri yıldız + kıvılcım çizgileri + küçük halka
func hit_spark(pos: Vector3, col := Color(1.0, 0.85, 0.4), s := 1.0) -> void:
	burst(pos, {"amount": int(14 * s), "life": 0.28, "tex": tex_spark, "size": 1.5 * s, "vmin": 8, "vmax": 16 * s,
		"damp": 6.0, "colors": [Color(1, 1, 1, 1), col, Color(col.r, col.g, col.b, 0)]})
	VFX.star(pos, col, 1.5 * s, 0.14)
	VFX.shockwave(pos, col.lightened(0.3), 2.6 * s, 0.2, false)


func impact(pos: Vector3, col: Color, s := 1.0) -> void:
	hit_spark(pos, col, s * 1.3)
	var g = Vector3(pos.x, Game.jutsu_floor(pos.x, pos.z) + 0.1, pos.z)
	VFX.shockwave(g, col, 7.0 * s, 0.45)
	dust(g, 1.4 * s)
	if s >= 1.2:
		VFX.cracks(g, 2.5 * s)
		VFX.debris(g + Vector3.UP * 0.3, Color(0.5, 0.42, 0.32), int(6 * s), 9.0 * s, 0.35)
	light(pos, col, 6.0 * s, 10.0 * s, 0.25)


func explosion(pos: Vector3, s := 1.0, col := Color(1.0, 0.55, 0.15)) -> void:
	VFX.explosion(pos, s, col)


## Döngüsel emitter: chakra aurası, jutsu çekirdekleri vb.
## dur > 0: o kadar saniye sonra kendiliğinden söner (iyileşme/seviye atlama gibi tek seferlik parıltılar).
## dur <= 0: kalıcı; çağıran durdurmalı (emitting = false + queue_free).
func aura(parent: Node3D, col: Color, s := 1.0, offset := Vector3(0, 0.9, 0), dur := 1.6) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.amount = int(60 * s)
	p.lifetime = 0.8
	p.local_coords = false
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.7 * s
	pm.direction = Vector3.UP
	pm.spread = 20.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 4.0
	pm.gravity = Vector3(0, 2.0, 0)
	pm.scale_min = 0.4; pm.scale_max = 1.0
	pm.color_ramp = _gradient([Color(col.r, col.g, col.b, 0), Color(col.r, col.g, col.b, 0.85), Color(col.lightened(0.4).r, col.lightened(0.4).g, col.lightened(0.4).b, 0)])
	pm.scale_curve = _curve([[0.0, 0.3], [0.4, 1.0], [1.0, 0.2]])
	pm.particle_flag_align_y = true
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(0.16, 0.9) * s
	q.material = _draw_mat(tex_spark, true, BaseMaterial3D.BILLBOARD_DISABLED)
	p.draw_pass_1 = q
	parent.add_child(p)
	p.position = offset
	p.emitting = true
	if dur > 0.0:
		get_tree().create_timer(dur).timeout.connect(func():
			if is_instance_valid(p):
				p.emitting = false
				get_tree().create_timer(p.lifetime + 0.1).timeout.connect(func():
					if is_instance_valid(p):
						p.queue_free()))
	return p
