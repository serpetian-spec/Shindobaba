class_name PathLairs
extends RefCounted
## Efsane Yolları ustalarının inleri (LegendPaths.build_all çağırır). Her in araziye gömülü, kendi atmosferiyle:
## titreyen ışıklı meşaleler, yerde sürünen sis, ayrıntılı dekor; düz zemin diskleri yok.
## build(...) ustanın önünün yerel kuzey ofsetini döndürür (görev hedefi / yol gösterme noktası).

static var _dead_tree: Mesh


static func build(kind: String, b: Builder, pid: String, p: Vector2, base: float) -> float:
	match kind:
		"snake":
			return _snake(b, pid, p, base)
		"forge":
			return _forge(b, pid, p, base)
		"dojo":
			return _dojo(b, pid, p, base)
		"clinic", "paper", "toad", "clay", "thread", "thunder", "chidori", "jashin", "octo", "ink", "puppet":
			return _hall(b, pid, p, base, kind)
	return 0.0


# ------------------------------------------------------------------ ortak yardımcılar
static func _g(p: Vector2, base: float, x: float, n: float) -> float:
	return Game.terrain_height(p.x + x, -(p.y + n)) - base


## Titreyen ışık (meşale, ocak)
static func light(b: Builder, wp: Vector3, col: Color, energy: float, rng_: float) -> void:
	var l = OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_
	b.root.add_child(l)
	l.global_position = wp
	var tw = l.create_tween().set_loops()
	tw.tween_property(l, "light_energy", energy * 1.35, 0.11 + randf() * 0.05)
	tw.tween_property(l, "light_energy", energy * 0.7, 0.16 + randf() * 0.06)
	tw.tween_property(l, "light_energy", energy, 0.09)


## Yerde sürünen sis bulutları (sürekli)
static func fog(b: Builder, wp: Vector3, r: float, col: Color, amount := 16) -> void:
	var e = GPUParticles3D.new()
	e.amount = amount
	e.lifetime = 8.0
	e.preprocess = 8.0
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(r, 0.4, r)
	pm.direction = Vector3(1, 0, 0.4)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = 5.0
	pm.scale_max = 9.0
	pm.color_ramp = FX._gradient([Color(col, 0.0), Color(col, col.a), Color(col, col.a * 0.8), Color(col, 0.0)])
	e.process_material = pm
	var q = QuadMesh.new()
	q.material = FX._draw_mat(FX.tex_smoke, false)
	e.draw_pass_1 = q
	e.visibility_aabb = AABB(Vector3(-r - 10, -4, -r - 10), Vector3(r * 2 + 20, 12, r * 2 + 20))
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.root.add_child(e)
	e.global_position = wp
	e.emitting = true


## İki nokta arası (yerel) silindir parçası: halat, kemik, kütük
static func rod(b: Builder, a: Vector3, c: Vector3, d: float, col: Color, seg := 6) -> void:
	var wa = b.w(a)
	var wc = b.w(c)
	var dir = (wc - wa)
	var L = dir.length()
	if L < 0.01:
		return
	var e = Basis(Quaternion(Vector3.UP, dir / L)).get_euler()
	b._mb(wa).add("cyl", (wa + wc) * 0.5, Vector3(d, L, d), col, Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z)), seg)


static func dead_tree(b: Builder, x: float, y: float, n: float, s: float, yaw: float) -> void:
	if _dead_tree == null:
		_dead_tree = Props.vegetation_mesh(2)
	b.pack_mesh(_dead_tree, Vector3(x, y, n), yaw, s, 1.5)


static func mossy_rock(b: Builder, x: float, y: float, n: float, s: float, v: int) -> void:
	b.boulder(Vector3(x, y + s * 0.35, n), Vector3(s * 1.3, s, s * 1.1), Color(0.36, 0.34, 0.38), v, s > 2.0, v * 37.0)
	var wp = b.w(Vector3(x, y + s * 0.82, n))
	b._mb(wp).add("sphere", wp, Vector3(s * 1.05, s * 0.28, s * 0.9), Color(0.32, 0.5, 0.24), Vector3(0, v * 37.0, 0), 8)


## Kemik yığını: dağınık kemikler + kafatası
static func bones(b: Builder, x: float, y: float, n: float, s: float) -> void:
	var bone = Color(0.88, 0.85, 0.74)
	for k in 6:
		var a = k * 1.05
		var r = 0.4 + (k % 3) * 0.35
		var c = Vector3(x + cos(a) * r, y + 0.12, n + sin(a) * r)
		rod(b, c - Vector3(cos(a + 1.3), 0, sin(a + 1.3)) * 0.55 * s, c + Vector3(cos(a + 1.3), 0.15, sin(a + 1.3)) * 0.55 * s, 0.12 * s, bone, 5)
	var wp = b.w(Vector3(x, y + 0.32 * s, n))
	b._mb(wp).add("sphere", wp, Vector3(0.6, 0.5, 0.7) * s, bone, Vector3.ZERO, 8)
	for sx in [-1.0, 1.0]:
		b._mb(wp).add("sphere", wp + Vector3(0.14 * sx, 0.06, -0.3) * s, Vector3(0.16, 0.14, 0.1) * s, Color(0.08, 0.06, 0.06), Vector3.ZERO, 5)


## Asılı dökülmüş yılan derisi: tepeden sarkan, dalgalı soluk şerit
static func hanging_skin(b: Builder, x: float, top: float, n: float, L: float) -> void:
	for k in 7:
		var t = k / 6.0
		var wp = b.w(Vector3(x + sin(t * 5.0) * 0.25, top - t * L, n))
		b._mb(wp).add("box", wp, Vector3(0.55 - t * 0.25, L / 6.5, 0.05), Color(0.9, 0.87, 0.74).darkened(t * 0.15), Vector3(sin(t * 4.0) * 12.0, 0, sin(t * 6.0) * 10.0))


## Shimenawa: iki direk arasında sarkan kalın halat + zikzak kâğıt tılsımlar (shide)
static func shimenawa(b: Builder, a: Vector3, c: Vector3, sag: float) -> void:
	var prev = a
	for k in range(1, 13):
		var t = k / 12.0
		var q = a.lerp(c, t) - Vector3.UP * sin(t * PI) * sag
		rod(b, prev, q, 0.42, Color(0.78, 0.68, 0.45), 6)
		prev = q
		if k % 3 == 0 and k < 12:
			for z in 3:
				var wp = b.w(q - Vector3.UP * (0.35 + z * 0.32) + Vector3(0.12 * (1 if z % 2 == 0 else -1), 0, 0))
				b._mb(wp).add("box", wp, Vector3(0.22, 0.3, 0.02), Color(0.97, 0.96, 0.92), Vector3(0, 0, 20.0 * (1 if z % 2 == 0 else -1)))


## Taş kemer: yarım daire düzensiz kaya bloklarıyla oyulmuş giriş
static func rock_arch(b: Builder, cx: float, y: float, n: float, w: float, h: float, col: Color) -> void:
	for k in 15:
		var a = PI * k / 14.0
		var jit = 0.6 * sin(k * 2.7)
		var x = cx + cos(a) * (w * 0.5 + jit)
		var yy = y + sin(a) * h + 0.4
		var s = 2.6 + 1.6 * absf(sin(k * 1.9))
		b.boulder(Vector3(x, yy, n + jit * 0.5), Vector3(s, s * 0.9, s * 1.2), col.darkened(0.05 * (k % 3)), k + 2, k in [0, 14], k * 23.0)


# ------------------------------------------------------------------ Ryūchi İni (Yılan Yolu)
## Sarp kaya duvarına oyulmuş derin mağara: düzensiz taş kemer, 18 m içeri yürünen kararan tünel,
## girişi çerçeveleyen iki dev sarmal yılan oyması, mor titreyen meşaleler, sürünen mor sis,
## kemik yığınları, sarkan yılan derileri, eğri kurumuş ağaçlar ve tılsımlı shimenawa.
static func _snake(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var rock = Color(0.33, 0.3, 0.37)
	var y0 = _g(p, base, 0, 0)
	var mouth_n = 18.0
	var my = _g(p, base, 0, mouth_n)
	# kaya duvarı: yay biçimli sarp kayalar (tünelin üstü dahil, tünel hattında çarpışma yok)
	for k in 13:
		var a = deg_to_rad(198.0 + k * 12.0)
		var r = 30.0 + (k % 3) * 4.0
		var x = cos(a) * r
		var n = -sin(a) * r + 12.0
		b.crag(Vector3(x, _g(p, base, x, n) - 1.5, n), 14.0 + (k % 4) * 3.0, 24.0 + (k % 5) * 5.0, rock.lerp(Color(0.24, 0.21, 0.3), (k % 3) * 0.3), k + 3, absf(x) > 9.0)
	for k in 5:
		var cx = (k - 2) * 7.0
		b.crag(Vector3(cx, my + 7.5, mouth_n + 12.0 + absf(k - 2) * 3.0), 13.0, 26.0 - absf(k - 2) * 4.0, rock.darkened(0.1), k + 20, false)
	# tünel: zemin, yan duvarlar (kaya blokları, içeri doğru kararır), tavan ve karanlık katmanları
	var tunnel_len = 18.0
	b.box(Vector3(0, my + 0.02, mouth_n + tunnel_len * 0.5), Vector3(9.5, 0.12, tunnel_len), Color(0.16, 0.14, 0.17), 0.0, false)
	for k in 9:
		var tn = mouth_n + 1.0 + k * 2.1
		var dk = float(k) / 8.0
		for sx in [-1.0, 1.0]:
			b.boulder(Vector3(5.2 * sx + sin(k * 1.7) * 0.4, my + 2.2, tn), Vector3(2.6, 4.6, 2.6), rock.darkened(0.25 + dk * 0.5), k + 5, true, k * 31.0)
		b.box(Vector3(0, my + 7.6 - dk * 0.6, tn), Vector3(10.5, 2.4, 2.3), rock.darkened(0.35 + dk * 0.5), 0.0, false)
	b.box(Vector3(0, my + 4.0, mouth_n + tunnel_len + 0.6), Vector3(11.0, 9.0, 0.6), Color(0.02, 0.015, 0.03), 0.0, true)
	for k in 4:   # içeri yürüdükçe artan karanlık
		var q = MeshInstance3D.new()
		var qm = QuadMesh.new()
		qm.size = Vector2(10.0, 8.5)
		q.mesh = qm
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.0, 0.0, 0.02, 0.32)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		q.material_override = m
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.root.add_child(q)
		q.global_position = b.w(Vector3(0, my + 4.1, mouth_n + 5.0 + k * 3.5))
	light(b, b.w(Vector3(0, my + 3.0, mouth_n + 8.0)), Color(0.55, 0.25, 0.85), 1.2, 9.0)   # derinlerde mor parıltı
	var eyes = b.w(Vector3(0, my + 2.6, mouth_n + tunnel_len - 0.2))
	for sx in [-1.0, 1.0]:   # karanlıkta parlayan sarı yılan gözleri
		b._mb(eyes).add("sphere", eyes + Vector3(0.7 * sx, 0, 0), Vector3(0.5, 0.22, 0.1), Color(1.0, 0.85, 0.1), Vector3(0, 0, 10 * sx), 8)
	rock_arch(b, 0.0, my - 0.5, mouth_n, 11.0, 8.0, rock.lightened(0.04))
	for k in 4:
		hanging_skin(b, -3.6 + k * 2.4, my + 7.4 - absf(k - 1.5) * 0.6, mouth_n - 0.4, 2.6 + (k % 2) * 1.2)
	# girişi çerçeveleyen dev sarmal yılan oymaları (başları kemerin üstüne eğilir)
	for sx in [-1.0, 1.0]:
		var cx = 11.5 * sx
		var cn = mouth_n - 2.0
		var gy = _g(p, base, cx, cn)
		for k in 6:
			var wp = b.w(Vector3(cx, gy + 0.9 + k * 1.45, cn))
			b._mb(wp).add("torus", wp, Vector3.ONE * (5.6 - k * 0.62), Color(0.42, 0.38, 0.47).lerp(Color(0.5, 0.46, 0.4), k * 0.12), Vector3(0, k * 47, 0), 18)
		var neck = b.w(Vector3(cx - 1.2 * sx, gy + 10.5, cn + 0.4))
		b._mb(neck).add("cyl", neck, Vector3(1.6, 4.0, 1.6), Color(0.45, 0.41, 0.49), Vector3(0, 0, 28 * sx), 10)
		var hp = b.w(Vector3(cx - 2.8 * sx, gy + 12.8, cn - 0.6))
		b._mb(hp).add("sphere", hp, Vector3(2.6, 1.9, 3.8), Color(0.46, 0.42, 0.5), Vector3(18, 25 * sx, 0), 12)
		b._mb(hp).add("sphere", hp + Vector3(0, -0.75, -1.2), Vector3(2.0, 0.5, 2.6), Color(0.62, 0.58, 0.48), Vector3(28, 25 * sx, 0), 10)
		for fx in [-1.0, 1.0]:
			b._mb(hp).add("cone", hp + Vector3(0.6 * fx, -0.9, -1.9), Vector3(0.3, 1.2, 0.3), Color(0.92, 0.9, 0.82), Vector3(195, 0, 0), 5)
			b._mb(hp).add("sphere", hp + Vector3(0.85 * fx, 0.55, -1.5), Vector3(0.55, 0.32, 0.4), Color(1.0, 0.82, 0.12), Vector3.ZERO, 8)
		b._collide(b.w(Vector3(cx, gy + 4.5, cn)), Vector3(9.0, 9.0, 9.0), 0.0)
	# mor meşaleler: direk + demir sepet + alev + titreyen ışık
	for q in [Vector2(-6.5, 12.5), Vector2(6.5, 12.5), Vector2(-7.5, 2.0), Vector2(7.5, 2.0), Vector2(-6.0, -9.0), Vector2(6.0, -9.0)]:
		var gy = _g(p, base, q.x, q.y)
		b.box(Vector3(q.x, gy + 1.4, q.y), Vector3(0.25, 2.8, 0.25), Color(0.18, 0.12, 0.1))
		b.cyl(Vector3(q.x, gy + 2.95, q.y), 0.75, 0.45, Color(0.15, 0.14, 0.16), false, 10)
		b.cone(Vector3(q.x, gy + 3.7, q.y), 0.65, 1.3, Color(0.78, 0.35, 1.0), 8)
		b.cone(Vector3(q.x, gy + 3.55, q.y), 0.38, 0.8, Color(0.97, 0.85, 1.0), 6)
		light(b, b.w(Vector3(q.x, gy + 3.9, q.y)), Color(0.72, 0.35, 1.0), 2.0, 11.0)
	# basamak taşlarıyla yol (güneyden mağaraya)
	for k in 16:
		var n = -28.0 + k * 2.7
		var x = sin(k * 0.55) * 2.2
		var gy = _g(p, base, x, n)
		b.boulder(Vector3(x, gy + 0.05, n), Vector3(1.8, 0.25, 1.4), Color(0.48, 0.46, 0.5), k, false, k * 41.0)
	# yosunlu kayalar, kemik yığınları, kurumuş eğri ağaçlar
	for k in 10:
		var a = k * 0.63 + 0.4
		var r = 13.0 + (k % 4) * 3.5
		var x = cos(a + PI) * r
		var n = sin(a + PI) * r * 0.8 + 2.0
		if absf(x) < 4.0:
			x += 6.0 * signf(x + 0.01)
		mossy_rock(b, x, _g(p, base, x, n), n, 1.4 + (k % 3) * 0.9, k)
	for q in [Vector3(-8.5, 0, 8.0), Vector3(9.0, 0, 5.5), Vector3(-4.0, 0, 15.5), Vector3(13.0, 0, -4.0)]:
		bones(b, q.x, _g(p, base, q.x, q.z), q.z, 1.0 + (int(q.x) % 2) * 0.3)
	for q in [Vector3(-9.0, 0, -12.0), Vector3(9.0, 0, -12.0), Vector3(-17.0, 0, 6.0), Vector3(16.0, 0, 9.0), Vector3(-14.0, 0, -18.0)]:
		dead_tree(b, q.x, _g(p, base, q.x, q.z), q.z, 1.5 + absf(q.x) * 0.02, q.x * 13.0)
	# kurumuş iki ağaç arasında shimenawa
	var ly = _g(p, base, -9.0, -12.0)
	var ry = _g(p, base, 9.0, -12.0)
	shimenawa(b, Vector3(-8.6, ly + 5.2, -12.0), Vector3(8.6, ry + 5.2, -12.0), 1.6)
	b.kanji(Vector3(0, y0 + 9.6, mouth_n - 3.5), "龍地", 2.2, Color(0.82, 0.62, 1.0), 180.0)
	# yerde sürünen mor sis + mağaradan taşan sis
	fog(b, b.w(Vector3(0, my + 0.6, mouth_n + 2.0)), 6.0, Color(0.55, 0.45, 0.7, 0.4), 14)
	fog(b, b.w(Vector3(-8.0, y0 + 0.5, 0.0)), 9.0, Color(0.6, 0.52, 0.72, 0.3), 14)
	fog(b, b.w(Vector3(8.0, y0 + 0.5, -4.0)), 9.0, Color(0.6, 0.52, 0.72, 0.3), 14)
	LegendPaths._mentor(b, pid, Vector3(0, my + 0.05, mouth_n - 3.0), PI)
	b.interact(Vector3(0, my, mouth_n - 6.0), 6.5, "path_mentor", "[F] Yılan Ustası ile konuş", {"path": pid})
	return mouth_n - 7.0


# ------------------------------------------------------------------ Tetsuyama Demirhanesi (Silah Ustası Yolu)
## Açık tepede ahşap çatkılı atölye: taş temel, sıvalı paneller, iki katlı kiremit çatı, taş baca (duman + kıvılcım),
## kor parlayan ocak, örs, su fıçısı, körük, bileği taşı, kömür ve odun yığını; çitli antrenman avlusu,
## hedefler ve saman kuklalar, silah rafları, nobori sancakları, demircinin evi.
static func _forge(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var wood = Color(0.38, 0.24, 0.14)
	var dark = Color(0.24, 0.16, 0.1)
	var plaster = Color(0.9, 0.86, 0.76)
	var stone = Color(0.5, 0.48, 0.46)
	var pj = PathJutsu.get_pinst()
	var fy = maxf(_g(p, base, -7, 12), _g(p, base, 7, 12))
	# atölye: taş temel + çatkı direkleri + sıvalı arka/yan duvarlar (ön açık)
	b.box(Vector3(0, fy + 0.4, 12), Vector3(17, 0.8, 11), stone)
	for x in [-8.0, -2.7, 2.7, 8.0]:
		for n in [7.0, 17.0]:
			b.box(Vector3(x, fy + 3.3, n), Vector3(0.45, 5.0, 0.45), dark)
	b.box(Vector3(0, fy + 3.3, 17.2), Vector3(16.5, 5.0, 0.35), plaster)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(8.2 * sx, fy + 3.3, 12), Vector3(0.35, 5.0, 10.0), plaster)
		b.box(Vector3(8.25 * sx, fy + 3.3, 12), Vector3(0.12, 0.3, 10.2), dark, 0.0, false)
	for n in [7.0, 17.0]:
		b.box(Vector3(0, fy + 5.8, n), Vector3(17, 0.4, 0.4), dark, 0.0, false)
	b.roof(Vector3(0, fy + 7.4, 12), Vector3(19.5, 3.0, 13.5), Color(0.26, 0.28, 0.34))
	b.roof(Vector3(0, fy + 9.6, 12), Vector3(9.0, 1.6, 6.0), Color(0.3, 0.32, 0.38))
	b.kanji(Vector3(0, fy + 6.5, 6.6), "鉄山", 1.6, Color(0.95, 0.78, 0.35), 180.0)
	# taş baca: duman + kıvılcım
	b.frustum(Vector3(5.0, fy + 7.0, 15.0), 2.6, 9.0, stone.darkened(0.15))
	b.box(Vector3(5.0, fy + 11.8, 15.0), Vector3(2.2, 0.5, 2.2), stone.darkened(0.3))
	Steam.add(b.w(Vector3(5.0, fy + 13.5, 15.0)))
	# ocak + kor + körük
	b.box(Vector3(5.0, fy + 1.6, 14.6), Vector3(4.0, 1.6, 3.0), stone.darkened(0.3))
	b.box(Vector3(5.0, fy + 2.5, 14.3), Vector3(3.0, 0.3, 2.0), Color(1.0, 0.42, 0.08), 0.0, false)
	b.box(Vector3(5.0, fy + 2.62, 14.3), Vector3(2.0, 0.12, 1.2), Color(1.0, 0.85, 0.35), 0.0, false)
	light(b, b.w(Vector3(5.0, fy + 3.4, 13.6)), Color(1.0, 0.5, 0.15), 3.2, 13.0)
	b.box(Vector3(2.0, fy + 1.4, 15.5), Vector3(1.4, 0.9, 1.0), Color(0.45, 0.3, 0.2))
	b.sphere(Vector3(2.0, fy + 1.9, 15.5), Vector3(1.2, 0.5, 0.8), Color(0.35, 0.22, 0.14))
	# örs (kütük üstünde, boynuzlu), su fıçısı, bileği taşı, kömür ve odun yığını
	b.cyl(Vector3(-1.5, fy + 1.3, 10.0), 1.1, 1.0, Color(0.42, 0.28, 0.18))
	b.box(Vector3(-1.5, fy + 2.05, 10.0), Vector3(1.5, 0.5, 0.6), Color(0.2, 0.2, 0.22))
	b.cone(Vector3(-0.45, fy + 2.1, 10.0), 0.45, 0.8, Color(0.22, 0.22, 0.24))
	b.cyl(Vector3(1.2, fy + 1.3, 9.0), 1.3, 1.1, wood)
	b.cyl(Vector3(1.2, fy + 1.86, 9.0), 1.1, 0.06, Color(0.1, 0.2, 0.32), false)
	var gw = b.w(Vector3(-5.0, fy + 1.7, 14.0))
	b._mb(gw).add("cyl", gw, Vector3(1.6, 0.3, 1.6), Color(0.55, 0.52, 0.48), Vector3(0, 0, 90), 16)
	b.box(Vector3(-5.0, fy + 1.0, 14.0), Vector3(0.3, 1.2, 1.4), wood)
	for k in 5:
		b.boulder(Vector3(-6.5 + (k % 3) * 0.6, fy + 0.9 + (k / 3) * 0.4, 16.0 - (k % 2) * 0.5), Vector3(0.9, 0.6, 0.8), Color(0.12, 0.11, 0.12), k)
	for k in 9:
		rod(b, Vector3(10.0, fy + 0.35 + (k / 3) * 0.42, 9.0 + (k % 3) * 0.42), Vector3(10.0, fy + 0.35 + (k / 3) * 0.42, 9.0 + (k % 3) * 0.42) + Vector3(0, 0.0, 0.001) + Vector3(2.4, 0, 0), 0.4, wood.lightened(0.15), 8)
	# silah rafları (avlunun iki yanında)
	for r in 2:
		var rx = -11.5 if r == 0 else 11.5
		var ry = _g(p, base, rx, 2.0)
		b.box(Vector3(rx, ry + 1.6, 2.0), Vector3(0.3, 3.2, 6.0), wood)
		b.box(Vector3(rx, ry + 3.1, 2.0), Vector3(0.6, 0.2, 6.4), dark)
		b.box(Vector3(rx, ry + 0.3, 2.0), Vector3(0.6, 0.2, 6.4), dark)
		b.box(Vector3(rx, ry + 3.55, 2.0), Vector3(1.0, 0.25, 6.8), Color(0.3, 0.32, 0.38), 0.0, false)
		for k in 7:
			var kind: String = PathJutsu.WEAPON_KINDS[(k + r * 5) % PathJutsu.WEAPON_KINDS.size()]
			var mi = pj.mi_of(pj.weapon_mesh(kind))
			b.root.add_child(mi)
			mi.global_position = b.w(Vector3(rx + (0.25 if r == 0 else -0.25), ry + 1.7, -0.6 + k * 0.85))
			mi.rotation_degrees = Vector3(-90, 90 if r == 0 else -90, 0)
			mi.scale = Vector3.ONE * 1.6
	# çitli antrenman avlusu: hedef tahtaları, saman kuklalar, saplanmış kunailer
	for k in 14:
		var a = PI + PI * k / 13.0
		var x = cos(a) * 15.0
		var n = sin(a) * 11.0 - 4.0
		var gy = _g(p, base, x, n)
		b.box(Vector3(x, gy + 0.6, n), Vector3(0.22, 1.2, 0.22), wood)
		if k < 13:
			var a2 = PI + PI * (k + 1) / 13.0
			var x2 = cos(a2) * 15.0
			var n2 = sin(a2) * 11.0 - 4.0
			rod(b, Vector3(x, gy + 0.95, n), Vector3(x2, _g(p, base, x2, n2) + 0.95, n2), 0.12, wood.lightened(0.1), 5)
	for k in 4:
		var tx = -7.5 + k * 5.0
		var tn = -11.0
		var ty = _g(p, base, tx, tn)
		b.box(Vector3(tx, ty + 1.0, tn), Vector3(0.25, 2.0, 0.25), wood)
		var wp = b.w(Vector3(tx, ty + 2.2, tn))
		b._mb(wp).add("cyl", wp, Vector3(1.4, 0.18, 1.4), Color(0.85, 0.75, 0.55), Vector3(90, 0, 0), 16)
		b._mb(wp).add("cyl", wp + Vector3(0, 0, -0.01), Vector3(0.9, 0.2, 0.9), Color(0.8, 0.2, 0.18), Vector3(90, 0, 0), 16)
		b._mb(wp).add("cyl", wp + Vector3(0, 0, -0.02), Vector3(0.35, 0.22, 0.35), Color(0.95, 0.92, 0.85), Vector3(90, 0, 0), 12)
		for q in 2:
			var km = pj.mi_of(pj.weapon_mesh("kunai"))
			b.root.add_child(km)
			km.global_position = wp + Vector3(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4), 0.35)
			km.rotation_degrees = Vector3(0, 180, 0)
	for k in 3:
		var dx = -5.0 + k * 5.0
		var dn = -4.5
		var dy = _g(p, base, dx, dn)
		b.box(Vector3(dx, dy + 0.9, dn), Vector3(0.18, 1.8, 0.18), wood)
		b.cyl(Vector3(dx, dy + 1.5, dn), 0.6, 1.0, Color(0.85, 0.75, 0.42), false, 10)
		b.sphere(Vector3(dx, dy + 2.3, dn), Vector3(0.5, 0.5, 0.5), Color(0.88, 0.78, 0.45))
		b.box(Vector3(dx, dy + 1.75, dn), Vector3(1.4, 0.16, 0.16), wood, 0.0, false)
	# nobori sancakları ve asılı dev parşömenler
	for sx in [-1.0, 1.0]:
		for k in 2:
			var nx = (9.5 + k * 3.0) * sx
			var nn = -15.0 + k * 1.5
			var ny = _g(p, base, nx, nn)
			b.box(Vector3(nx, ny + 3.5, nn), Vector3(0.18, 7.0, 0.18), dark)
			b.box(Vector3(nx + 0.55 * sx, ny + 4.6, nn), Vector3(1.0, 4.0, 0.05), Color(0.82, 0.16, 0.14) if k == 0 else Color(0.95, 0.93, 0.86), 0.0, false)
			b.kanji(Vector3(nx + 0.55 * sx, ny + 4.6, nn - 0.06), "武" if k == 0 else "刃", 0.8, Color(0.98, 0.96, 0.9) if k == 0 else Color(0.1, 0.08, 0.08), 180.0)
		var sxp = 7.0 * sx
		var sy = _g(p, base, sxp, 5.0)
		b.box(Vector3(sxp, sy + 3.5, 5.0), Vector3(0.35, 7.0, 0.35), wood)
		b.box(Vector3(sxp, sy + 6.8, 5.0), Vector3(3.2, 0.3, 0.3), wood, 0.0, false)
		b.box(Vector3(sxp, sy + 4.6, 5.0), Vector3(2.4, 4.0, 0.06), Color(0.96, 0.94, 0.86), 0.0, false)
		b.box(Vector3(sxp, sy + 6.5, 4.95), Vector3(2.4, 0.25, 0.06), Color(0.75, 0.12, 0.12), 0.0, false)
		b.box(Vector3(sxp, sy + 2.7, 4.95), Vector3(2.4, 0.25, 0.06), Color(0.75, 0.12, 0.12), 0.0, false)
		b.kanji(Vector3(sxp, sy + 4.6, 4.9), "龍" if sx < 0 else "虎", 1.8, Color(0.1, 0.08, 0.08), 180.0)
	# demircinin evi (doğuda) ve fenerler
	var hy = _g(p, base, 20.0, 14.0)
	b.box(Vector3(20.0, hy + 0.4, 14.0), Vector3(8.0, 0.8, 7.0), stone)
	b.box(Vector3(20.0, hy + 2.3, 14.0), Vector3(7.4, 3.0, 6.4), plaster)
	for x in [16.4, 23.6]:
		b.box(Vector3(x, hy + 2.3, 14.0), Vector3(0.3, 3.0, 6.6), dark)
	b.roof(Vector3(20.0, hy + 4.6, 14.0), Vector3(9.0, 2.0, 8.0), Color(0.26, 0.28, 0.34))
	b.box(Vector3(16.25, hy + 1.9, 14.0), Vector3(0.1, 2.2, 1.6), Color(0.55, 0.4, 0.25), 0.0, false)
	b.lantern(-4.0, 4.0)
	b.lantern(4.0, 4.0)
	fog(b, b.w(Vector3(5.0, fy + 1.0, 12.0)), 4.0, Color(0.7, 0.68, 0.66, 0.18), 6)   # ocak dumanı tavanda
	LegendPaths._mentor(b, pid, Vector3(-1.5, fy + 0.8, 8.4), PI)
	b.interact(Vector3(-1.5, fy, 6.0), 6.5, "path_mentor", "[F] Silah ustasıyla konuş", {"path": pid})
	return 5.0


## Seishun Dojosu (Sekiz Kapı Yolu): açık cepheli ahşap dojo + toprak antrenman avlusu. Kanon taijutsu antrenmanının izleri:
## iple sarılı, tekme izli vuruş kütükleri; ip kulplu taş ağırlıklar; iple çekilen dev kaya; avluyu dolanan aşınmış koşu izi;
## amuda/şınav kalasları; yeşil-kırmızı nobori sancakları; kanji levhalı ahşap kapı; bambu çit. Dojonun içinde parlak ahşap zemin,
## arka duvarda "根性" (azim) parşömeni, silah rafı (bō, nunçaku), duvarda asılı bacak ağırlıkları.
## Antrenman noktaları LegendPaths.drill_spots'a yazılır (teknik öğrenme antrenmanı orada yapılır).
static func _dojo(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var wood = Color(0.46, 0.31, 0.18)
	var dark = Color(0.24, 0.16, 0.1)
	var floor_c = Color(0.62, 0.46, 0.28)
	var plaster = Color(0.93, 0.9, 0.82)
	var earth = Color(0.58, 0.46, 0.32)
	var stone = Color(0.55, 0.53, 0.5)
	var green = Color(0.22, 0.52, 0.26)
	var red = Color(0.72, 0.16, 0.13)
	var fy = maxf(maxf(_g(p, base, -9, 16), _g(p, base, 9, 16)), _g(p, base, 0, 22))
	var spots: Dictionary = {}
	# ---- dojo binası (kuzeyde): taş kaide, yükseltilmiş ahşap zemin, güneyi açık (verandalı), kiremit çatı
	b.box(Vector3(0, fy + 0.45, 17), Vector3(20, 0.9, 12), stone)
	b.box(Vector3(0, fy + 0.95, 17), Vector3(19.2, 0.12, 11.4), floor_c)
	for k in 12:   # zemin tahtaları
		b.box(Vector3(-9.0 + k * 1.64, fy + 1.02, 17), Vector3(1.55, 0.02, 11.2), floor_c.darkened(0.06 if k % 2 else -0.04), 0.0, false)
	for k in 4:   # veranda basamakları
		b.box(Vector3(0, fy + 0.8 - k * 0.22, 10.9 - k * 0.45), Vector3(6.0, 0.22, 0.5), wood)
	for x in [-9.6, -4.8, 0.0, 4.8, 9.6]:   # ön sütunlar
		b.box(Vector3(x, fy + 3.2, 11.3), Vector3(0.45, 4.4, 0.45), dark)
	b.box(Vector3(0, fy + 5.25, 11.3), Vector3(20.2, 0.45, 0.5), dark)   # ön kiriş
	b.box(Vector3(0, fy + 3.2, 22.8), Vector3(19.6, 4.4, 0.35), plaster)   # arka duvar
	for sx in [-1.0, 1.0]:
		b.box(Vector3(9.8 * sx, fy + 3.2, 17), Vector3(0.35, 4.4, 11.5), plaster)
		for k in 3:   # yan duvarda ahşap çerçeve
			b.box(Vector3(9.75 * sx, fy + 3.2, 12.5 + k * 4.5), Vector3(0.4, 4.4, 0.25), dark, 0.0, false)
	b.roof(Vector3(0, fy + 5.5, 17), Vector3(22.5, 3.4, 14.5), Color(0.55, 0.18, 0.15))
	b.box(Vector3(0, fy + 7.1, 17), Vector3(22.8, 0.35, 0.5), dark, 0.0, false)   # mahya
	# arka duvar: 根性 parşömeni, iki yanda 青春 ve 努力
	b.box(Vector3(0, fy + 3.4, 22.55), Vector3(2.4, 3.6, 0.05), Color(0.95, 0.92, 0.84), 0.0, false)
	b.kanji(Vector3(0, fy + 3.6, 22.5), "根性", 1.1, Color(0.1, 0.08, 0.08), 0.0)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(5.5 * sx, fy + 3.4, 22.55), Vector3(1.6, 3.0, 0.05), Color(0.95, 0.92, 0.84), 0.0, false)
		b.kanji(Vector3(5.5 * sx, fy + 3.5, 22.5), "青春" if sx < 0 else "努力", 0.75, Color(0.1, 0.08, 0.08), 0.0)
	# silah rafı (bō ve nunçaku) + duvarda asılı bacak ağırlıkları
	b.box(Vector3(-8.0, fy + 2.2, 21.8), Vector3(2.6, 0.12, 0.5), wood, 0.0, false)
	b.box(Vector3(-8.0, fy + 1.2, 21.8), Vector3(2.6, 0.12, 0.5), wood, 0.0, false)
	for k in 5:
		b.box(Vector3(-9.1 + k * 0.55, fy + 2.4, 21.9), Vector3(0.07, 2.9, 0.07), Color(0.55, 0.4, 0.24), 0.0, false, Vector3(8, 0, 0))
	for k in 4:
		b.box(Vector3(6.6 + k * 0.8, fy + 2.6, 22.45), Vector3(0.35, 0.6, 0.18), Color(0.2, 0.34, 0.2), 0.0, false)   # bacak ağırlıkları
		b.box(Vector3(6.6 + k * 0.8, fy + 3.0, 22.5), Vector3(0.05, 0.3, 0.05), dark, 0.0, false)
	for sx in [-1.0, 1.0]:   # içeride iki fener
		b.box(Vector3(7.5 * sx, fy + 4.6, 18.5), Vector3(0.05, 0.6, 0.05), dark, 0.0, false)
		b.sphere(Vector3(7.5 * sx, fy + 4.1, 18.5), Vector3(0.6, 0.75, 0.6), Color(1.0, 0.86, 0.6), 8)
		light(b, b.w(Vector3(7.5 * sx, fy + 4.0, 18.5)), Color(1.0, 0.8, 0.55), 1.1, 9.0)
	# ---- antrenman avlusu (güneyde): aşınmış toprak meydan + koşu izi halkası
	var cy = _g(p, base, 0, -2)
	# avlu toprak: otsuz (çimen yol haritasından okur — şeritlerle avlu çemberini kapla)
	var RM = preload("res://scripts/world/road_map.gd")
	for k in 9:
		var zz = -2.0 - 16.0 + k * 4.0
		var half = sqrt(maxf(0.0, 17.0 * 17.0 - pow(zz + 2.0, 2.0)))
		var wa = b.w(Vector3(-half, 0, zz))
		var wb = b.w(Vector3(half, 0, zz))
		RM.add_lane(Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), 2.4, true)   # arazi de toprak boyanır (eğim diskin üstüne çıkınca yeşil kalıyordu)
	for k in 36:   # koşu izi: avluyu dolanan koyu, ayak izi gibi aşınmış halka
		var a = TAU * k / 36.0
		var q = Vector3(cos(a) * 15.5, 0, -2 + sin(a) * 15.5)
		b.box(Vector3(q.x, _g(p, base, q.x, q.z) + 0.06, q.z), Vector3(2.9, 0.04, 1.4), earth.darkened(0.16), rad_to_deg(-a) + 90.0, false)
	# vuruş kütükleri: iple sarılı tepe, tekme/yumruk izleri (çentikler), bazısı eğik
	var posts: Array = []
	for k in 6:
		var x = -11.0 + k * 4.4
		var n = 3.5 - absf(k - 2.5) * 0.8
		var gy = _g(p, base, x, n)
		var tilt = [0.0, 6.0, -3.0, 0.0, 8.0, -5.0][k]
		b.cyl(Vector3(x, gy + 1.0, n), 0.55, 2.0, wood.darkened(0.05 * (k % 2)), true, 9)
		for r in 3:
			b.cyl(Vector3(x, gy + 1.35 + r * 0.16, n), 0.6, 0.1, Color(0.82, 0.76, 0.6), false, 9)   # ip sargısı
		for c in 4:
			b.box(Vector3(x + 0.27, gy + 0.6 + c * 0.25, n - 0.05), Vector3(0.04, 0.08, 0.2), dark, tilt, false)   # darbe çentikleri
		posts.append(b.w(Vector3(x, gy, n - 1.0)))
	spots["posts"] = posts
	# ip kulplu taş ağırlıklar (boy boy) + kütük kaldırma barı
	var wts: Array = []
	for k in 4:
		var x = 11.0 + (k % 2) * 1.8
		var n = -6.0 - (k / 2) * 2.0
		var gy = _g(p, base, x, n)
		var r = 0.6 + k * 0.18
		b.sphere(Vector3(x, gy + r * 0.8, n), Vector3(r * 2.0, r * 1.6, r * 2.0), stone.darkened(0.05 * k), 9, true)
		b.cyl(Vector3(x, gy + r * 1.75, n), r * 0.9, 0.12, Color(0.75, 0.68, 0.5), false, 10)   # ip kulp
		wts.append(b.w(Vector3(x - 1.4, gy, n)))
	spots["weights"] = wts
	var bx = -12.0; var bn = -7.0
	var bgy = _g(p, base, bx, bn)
	b.boulder(Vector3(bx, bgy + 1.6, bn), Vector3(4.2, 3.2, 3.8), stone.darkened(0.08), 2, true, 20.0)   # çekilecek dev kaya
	for k in 6:   # kayaya bağlı halat (yerde uzanır)
		b.box(Vector3(bx + 2.4 + k * 0.9, _g(p, base, bx + 2.4 + k * 0.9, bn + 0.5) + 0.1, bn + 0.5), Vector3(0.95, 0.12, 0.12), Color(0.78, 0.7, 0.5), 0.0, false)
	spots["boulder"] = b.w(Vector3(bx + 8.0, _g(p, base, bx + 8.0, bn + 0.5), bn + 0.5))
	# amut / şınav kalasları
	for k in 3:
		var x = -2.0 + k * 2.0
		var gy = _g(p, base, x, -10)
		b.box(Vector3(x, gy + 0.25, -10), Vector3(1.6, 0.12, 0.5), wood, 0.0, false)
		for sx in [-1.0, 1.0]:
			b.box(Vector3(x + 0.7 * sx, gy + 0.12, -10), Vector3(0.12, 0.24, 0.4), dark, 0.0, false)
	spots["pushup"] = b.w(Vector3(0, _g(p, base, 0, -10), -10))
	# su fıçısı + kova
	b.cyl(Vector3(8.5, _g(p, base, 8.5, 9.5) + 0.55, 9.5), 1.1, 1.1, wood.darkened(0.1), true, 12)
	b.cyl(Vector3(8.5, _g(p, base, 8.5, 9.5) + 1.12, 9.5), 1.0, 0.05, Color(0.3, 0.45, 0.6), false, 12)
	# nobori sancakları (yeşil / kırmızı)
	for k in 6:
		var x = -16.0 + (k % 3) * 1.2 if k < 3 else 13.6 + (k % 3) * 1.2
		var n = -14.0
		var gy = _g(p, base, x, n)
		b.box(Vector3(x, gy + 2.6, n), Vector3(0.1, 5.2, 0.1), dark, 0.0, false)
		b.box(Vector3(x + 0.35, gy + 3.4, n), Vector3(0.6, 3.0, 0.04), green if k % 2 == 0 else red, 0.0, false)
		b.kanji(Vector3(x + 0.35, gy + 3.6, n - 0.04), "青" if k % 2 == 0 else "火", 0.42, Color(0.97, 0.95, 0.9), 0.0)
	# dojo kapısı (güney): iki direk + çatılı kiriş + 道場 levhası
	var gy0 = _g(p, base, 0, -19)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(3.2 * sx, gy0 + 2.4, -19), Vector3(0.55, 4.8, 0.55), dark)
	b.box(Vector3(0, gy0 + 4.95, -19), Vector3(8.4, 0.45, 0.8), dark, 0.0, false)
	b.roof(Vector3(0, gy0 + 5.2, -19), Vector3(9.4, 1.0, 2.2), Color(0.55, 0.18, 0.15))
	b.box(Vector3(0, gy0 + 4.2, -19.3), Vector3(2.6, 0.9, 0.08), Color(0.9, 0.86, 0.74), 0.0, false)
	b.kanji(Vector3(0, gy0 + 4.2, -19.36), "道場", 0.7, Color(0.1, 0.08, 0.08), 0.0)
	# bambu çit (kapı açıklığı hariç)
	for k in 40:
		var a = TAU * k / 40.0
		var q = Vector3(cos(a) * 19.0, 0, 1.5 + sin(a) * 21.0)
		if q.z < -17.0 and absf(q.x) < 4.0:
			continue
		if q.z > 11.0 and absf(q.x) < 10.5:
			continue   # dojo binası
		var gy = _g(p, base, q.x, q.z)
		b.box(Vector3(q.x, gy + 0.65, q.z), Vector3(0.12, 1.3, 0.12), Color(0.62, 0.58, 0.34), 0.0, false)
		b.box(Vector3(q.x, gy + 0.9, q.z), Vector3(2.9, 0.07, 0.07), Color(0.6, 0.55, 0.32), rad_to_deg(-a) + 90.0, false)
		b.box(Vector3(q.x, gy + 0.45, q.z), Vector3(2.9, 0.07, 0.07), Color(0.6, 0.55, 0.32), rad_to_deg(-a) + 90.0, false)
	b.lantern(-4.5, -17.5)
	b.lantern(4.5, -17.5)
	LegendPaths.drill_spots[pid] = spots
	# usta avluda, dojonun önünde (amut duruşu değil: konuşulur)
	LegendPaths._mentor(b, pid, Vector3(0, _g(p, base, 0, 7.5) + 0.05, 7.5), PI)
	b.interact(Vector3(0, _g(p, base, 0, 5.5), 5.5), 5.5, "path_mentor", "[F] Taijutsu Ustası ile konuş", {"path": pid})
	return 5.5


## Şifa tapınağı / dövüş dojosu: taş temelli ahşap salon, verandada usta; tapınakta buhar havuzu, dojoda kütükler ve ağırlıklar
static func _hall(b: Builder, pid: String, p: Vector2, base: float, kind: String) -> float:
	var wood = Color(0.42, 0.28, 0.16)
	var dark = Color(0.22, 0.15, 0.1)
	var roof = {"clinic": Color(0.3, 0.45, 0.35), "dojo": Color(0.55, 0.18, 0.15), "paper": Color(0.4, 0.4, 0.46), "toad": Color(0.85, 0.45, 0.2),
		"clay": Color(0.75, 0.62, 0.42), "thread": Color(0.22, 0.22, 0.24), "thunder": Color(0.85, 0.7, 0.2), "chidori": Color(0.3, 0.35, 0.55), "jashin": Color(0.45, 0.08, 0.1), "octo": Color(0.6, 0.3, 0.55), "ink": Color(0.18, 0.18, 0.2), "puppet": Color(0.55, 0.2, 0.18)}[kind]
	var wall = Color(0.92, 0.9, 0.84)
	var fy = maxf(_g(p, base, -8, 14), _g(p, base, 8, 14))
	b.box(Vector3(0, fy + 0.5, 14), Vector3(18, 1.0, 12), Color(0.55, 0.52, 0.48))
	for x in [-8.5, -3.0, 3.0, 8.5]:
		b.box(Vector3(x, fy + 3.2, 8.4), Vector3(0.4, 4.4, 0.4), dark)
	b.box(Vector3(0, fy + 3.2, 19.6), Vector3(17.5, 4.4, 0.3), wall)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(8.8 * sx, fy + 3.2, 14), Vector3(0.3, 4.4, 11), wall)
	b.roof(Vector3(0, fy + 5.4, 14), Vector3(20, 3.2, 14), roof)
	b.kanji(Vector3(0, fy + 4.8, 19.4), {"clinic": "癒", "dojo": "道", "paper": "紙", "toad": "蝦", "clay": "爆", "thread": "糸", "thunder": "雷", "chidori": "千", "jashin": "邪", "octo": "八", "ink": "墨", "puppet": "傀"}[kind], 2.2, Color(0.15, 0.12, 0.1), 0)
	if kind == "clinic":
		b.cyl(Vector3(-9, _g(p, base, -9, 2) + 0.1, 2), 7.0, 0.4, Color(0.55, 0.52, 0.48), true, 16)
		VillageStyles.water(b, Vector3(-9, _g(p, base, -9, 2) + 0.35, 2), Vector2(6, 6))
		for k in 6:
			b.box(Vector3(4 + k * 1.3, fy + 1.3, 12), Vector3(1.0, 0.4, 2.0), Color(0.85, 0.85, 0.82))   # yaralı yatakları
	elif kind == "paper":
		# kâğıt çiçekler: beyaz yapraklı küreler + uçuşan turnalar
		for k in 9:
			var a = TAU * k / 9.0
			var q = Vector3(cos(a) * 10.0, 0, 10.0 + sin(a) * 6.0)
			for j in 5:
				b.sphere(Vector3(q.x + cos(j * 1.25) * 0.4, _g(p, base, q.x, q.z) + 1.0 + sin(j * 1.25) * 0.4, q.z), Vector3(0.5, 0.18, 0.5), Color(0.96, 0.95, 0.98), 6)
		b.cyl(Vector3(-11, fy + 6.0, 16), 3.0, 12.0, Color(0.9, 0.9, 0.94), true, 10)   # kâğıt kule
		b.cone(Vector3(-11, fy + 13.5, 16), 4.0, 3.0, Color(0.45, 0.4, 0.6), 10)
	elif kind == "toad":
		# taş kurbağa heykelleri ve yosunlu kayalar
		for k in 4:
			var x = -8.0 + k * 5.3
			var gy = _g(p, base, x, 3)
			b.sphere(Vector3(x, gy + 0.9, 3), Vector3(1.8, 1.4, 1.6), Color(0.5, 0.55, 0.45), 10)
			for sx in [-1.0, 1.0]:
				b.sphere(Vector3(x + 0.5 * sx, gy + 1.6, 2.4), Vector3(0.45, 0.45, 0.45), Color(0.55, 0.6, 0.5), 8)
		b.box(Vector3(10, fy + 2.0, 6), Vector3(1.2, 4.0, 1.2), Color(0.35, 0.3, 0.25))   # kurbağa kâğıt fenerleri direği
	elif kind == "clay":
		# kil kuş ve örümcek heykelleri, kil çanakları, yanık izleri
		for k in 5:
			var x = -9.0 + k * 4.5
			var gy = _g(p, base, x, 3)
			b.sphere(Vector3(x, gy + 1.0, 3), Vector3(1.4, 0.8, 2.0), Color(0.93, 0.9, 0.82), 10)
			for sx in [-1.0, 1.0]:
				b.box(Vector3(x + 1.2 * sx, gy + 1.1, 3), Vector3(1.6, 0.12, 0.8), Color(0.9, 0.87, 0.78), 0.0, false)
			b.sphere(Vector3(x, gy + 0.05, 3), Vector3(2.4, 0.1, 2.4), Color(0.18, 0.15, 0.12), 8)
		for k in 4:
			b.cyl(Vector3(9, _g(p, base, 9, -2 + k * 2) + 0.5, -2 + k * 2), 1.2, 1.0, Color(0.6, 0.48, 0.34), true, 10)
	elif kind == "thread":
		# mezar taşları ve kara iplik yığınları
		for k in 8:
			var x = -10.0 + (k % 4) * 6.5
			var n = 1.0 + (k / 4) * 4.0
			var gy = _g(p, base, x, n)
			b.box(Vector3(x, gy + 0.9, n), Vector3(0.9, 1.8, 0.3), Color(0.42, 0.42, 0.44), randf() * 0.4 - 0.2)
		for k in 4:
			b.sphere(Vector3(-6 + k * 4, _g(p, base, -6 + k * 4, 7) + 0.3, 7), Vector3(1.2, 0.5, 1.0), Color(0.08, 0.08, 0.1), 8)
	elif kind == "thunder":
		# yere saplı üç kollu kunailer + mühür kâğıtları
		for k in 8:
			var a = TAU * k / 8.0
			var q = Vector3(cos(a) * 9.0, 0, 6.0 + sin(a) * 5.0)
			var gy = _g(p, base, q.x, q.z)
			b.cyl(Vector3(q.x, gy + 0.6, q.z), 0.12, 1.2, Color(0.3, 0.3, 0.32), false, 6)
			for j in 3:
				b.box(Vector3(q.x + cos(j * 2.1) * 0.25, gy + 1.25, q.z + sin(j * 2.1) * 0.25), Vector3(0.12, 0.5, 0.04), Color(0.7, 0.72, 0.76), j * 2.1, false)
			b.box(Vector3(q.x, gy + 0.9, q.z + 0.08), Vector3(0.2, 0.45, 0.02), Color(0.93, 0.9, 0.8), 0.0, false)
	elif kind == "chidori":
		# şimşek çubukları ve karlı kayalar
		for k in 5:
			var x = -10.0 + k * 5.0
			var gy = _g(p, base, x, 2)
			b.cyl(Vector3(x, gy + 3.0, 2), 0.25, 6.0, Color(0.35, 0.35, 0.4), true, 6)
			b.sphere(Vector3(x, gy + 6.2, 2), Vector3(0.5, 0.5, 0.5), Color(0.6, 0.8, 1.0), 8)
		for k in 6:
			var x2 = -9.0 + k * 3.6
			b.sphere(Vector3(x2, _g(p, base, x2, 0) + 0.5, 0), Vector3(1.6, 0.9, 1.4), Color(0.92, 0.94, 0.98), 8)
	elif kind == "jashin":
		# kan çemberi + üçgen, dev tırpan heykeli
		var cy = _g(p, base, 0, 3) + 0.05
		b.cyl(Vector3(0, cy, 3), 8.0, 0.06, Color(0.55, 0.05, 0.06), false, 32)
		b.cyl(Vector3(0, cy + 0.02, 3), 7.4, 0.06, Color(0.55, 0.5, 0.45), false, 32)
		for k in 3:
			var a1 = k * TAU / 3.0 + PI * 0.5
			var a2 = (k + 1) * TAU / 3.0 + PI * 0.5
			var p1 = Vector3(cos(a1) * 3.6, cy + 0.04, 3 + sin(a1) * 3.6)
			var p2 = Vector3(cos(a2) * 3.6, cy + 0.04, 3 + sin(a2) * 3.6)
			b.box((p1 + p2) * 0.5, Vector3(0.15, 0.04, p1.distance_to(p2)), Color(0.55, 0.05, 0.06), atan2((p2 - p1).x, (p2 - p1).z), false)
		b.cyl(Vector3(10, _g(p, base, 10, 6) + 3.0, 6), 0.2, 6.0, Color(0.2, 0.2, 0.22), true, 6)
		for j in 3:
			b.box(Vector3(10.6, _g(p, base, 10, 6) + 5.6 - j * 0.6, 6), Vector3(1.4, 0.15, 0.08), Color(0.7, 0.1, 0.12), 0.3, false)
	elif kind == "puppet":
		# atölye: tezgâhta yarım kuklalar, tavandan sarkan kollar
		for k in 5:
			var x = -6.0 + k * 3.0
			b.box(Vector3(x, fy + 1.2, 16.5), Vector3(0.5, 1.4, 0.35), Color(0.52, 0.38, 0.26))
			b.sphere(Vector3(x, fy + 2.15, 16.5), Vector3(0.38, 0.42, 0.38), Color(0.6, 0.45, 0.32), 8)
			b.cyl(Vector3(x, fy + 4.2, 13.0), 0.12, 1.4, Color(0.5, 0.36, 0.24), false, 6)
		b.box(Vector3(0, fy + 0.9, 12.0), Vector3(6.0, 0.8, 1.6), Color(0.35, 0.25, 0.18))
	elif kind == "ink":
		# asılı mürekkep resimleri, devrik Kök tabelası, mürekkep kazanları
		for k in 6:
			b.box(Vector3(-7.5 + k * 3.0, fy + 3.4, 19.3), Vector3(1.4, 2.4, 0.05), Color(0.93, 0.91, 0.85))
			b.box(Vector3(-7.5 + k * 3.0, fy + 3.4, 19.25), Vector3(0.9, 1.4, 0.04), Color(0.08, 0.08, 0.1))
		for k in 3:
			var x = -4.0 + k * 4.0
			b.cyl(Vector3(x, _g(p, base, x, 4) + 0.45, 4), 1.2, 0.9, Color(0.25, 0.2, 0.16), true, 12)
			b.cyl(Vector3(x, _g(p, base, x, 4) + 0.92, 4), 1.0, 0.05, Color(0.05, 0.05, 0.07), false, 12)
		b.box(Vector3(7.0, _g(p, base, 7, 3) + 0.3, 3.0), Vector3(3.2, 0.25, 1.2), Color(0.35, 0.25, 0.18))   # devrik tabela
	elif kind == "octo":
		# ahtapot heykeli (kafa + kıvrık kollar) ve ritim taşları
		var oy = _g(p, base, -9, 6)
		b.sphere(Vector3(-9, oy + 2.5, 6), Vector3(3.0, 3.6, 3.0), Color(0.6, 0.35, 0.55), 12)
		for k in 8:
			var a = TAU * k / 8.0
			b.sphere(Vector3(-9 + cos(a) * 2.2, oy + 0.5, 6 + sin(a) * 2.2), Vector3(1.0, 0.6, 2.4), Color(0.55, 0.32, 0.5), 8)
		for k in 5:
			var x = 2.0 + k * 2.5
			b.cyl(Vector3(x, _g(p, base, x, 3) + 0.4, 3), 1.0, 0.8, Color(0.4, 0.4, 0.44), true, 10)
	else:
		for k in 5:
			var x = -7.0 + k * 3.5
			b.cyl(Vector3(x, _g(p, base, x, 3) + 1.0, 3), 0.6, 2.0, wood, true, 8)   # vuruş kütükleri
		b.cyl(Vector3(8, _g(p, base, 8, 4) + 0.4, 4), 1.4, 0.8, Color(0.3, 0.3, 0.32), true, 10)   # taş ağırlık
	LegendPaths._mentor(b, pid, Vector3(0, fy + 1.05, 8.6), PI)
	b.interact(Vector3(0, fy + 1.0, 6.0), 6.5, "path_mentor", "[F] %s ile konuş" % {"clinic": "Şifacı Usta", "dojo": "Taijutsu Ustası", "paper": "Kâğıt Ustası", "toad": "Kurbağa Bilgesi", "clay": "Kil Sanatçısı", "thread": "İplik Ustası", "thunder": "Sarı Şimşek", "chidori": "Şimşek Kılıcı", "jashin": "Ayin Rahibi", "octo": "Ritim Ustası", "ink": "Mürekkep Ustası", "puppet": "Kukla Ustası"}[kind], {"path": pid})
	return 6.0
