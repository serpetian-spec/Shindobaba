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
		"clinic":
			return _clinic(b, pid, p, base)
		"paper":
			return _paper(b, pid, p, base)
		"toad":
			return _toad(b, pid, p, base)
		"clay":
			return _clay(b, pid, p, base)
		"thread":
			return _thread(b, pid, p, base)
		"thunder":
			return _thunder(b, pid, p, base)
		"chidori":
			return _chidori(b, pid, p, base)
		"jashin":
			return _jashin(b, pid, p, base)
		"octo":
			return _octo(b, pid, p, base)
		"ink":
			return _ink(b, pid, p, base)
		"puppet":
			return _puppet(b, pid, p, base)
		"_eski":
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
		b.crag(Vector3(cx, my + 7.5, mouth_n + 12.0 + absf(k - 2) * 3.0), 13.0, 26.0 - absf(k - 2) * 4.0, rock.darkened(0.1), k + 20, true)   # ağzın üstündeki kayalar: girişin üstünde, katı (tırmanılır)
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
	# girişi çerçeveleyen dev taş yılanlar: kaidede çöreklenmiş sarmal gövde yükselir, boyun kemerin üstüne eğilir;
	# açık ağız (üst/alt çene, dört diş, çatal dil), yarık göz bebekli sarı gözler, boyunca pul sırtı
	for sx in [-1.0, 1.0]:
		var cx = 11.5 * sx
		var cn = mouth_n - 2.0
		var gy = _g(p, base, cx, cn)
		var bw = b.w(Vector3(cx, gy, cn))
		var mb = b._mb(bw)
		var scol = Color(0.44, 0.4, 0.5)
		var belly = Color(0.62, 0.58, 0.5)
		var pts: Array = []
		var rads: Array = []
		for k in 26:   # sarmal: 2.2 tur, yukarı daralır
			var f = k / 25.0
			var a = f * TAU * 2.2 + (0.0 if sx > 0 else PI)
			var rr = lerpf(4.2, 1.6, f)
			pts.append(bw + Vector3(cos(a) * rr, 0.9 + f * 8.0, sin(a) * rr))
			rads.append(lerpf(1.25, 0.95, f))
		var inward = Vector3(-sx, 0, 0)
		var top: Vector3 = pts[-1]
		for k in 5:   # boyun: yukarı ve kemere doğru kıvrılır
			var f = (k + 1) / 5.0
			pts.append(top + Vector3(0, sin(f * 1.4) * 3.2, 0) + inward * f * 3.6 + Vector3(0, 0, -f * 1.2))
			rads.append(lerpf(0.95, 0.85, f))
		Loft.tube(mb, pts, rads, scol, 14, 3, true, false, func(t2: float, a2: float, d2: Vector3) -> Color: return belly if d2.y < -0.35 else (scol.darkened(0.12) if int(t2 * 60.0) % 2 == 0 else scol))
		var nk: Vector3 = pts[-1]
		var hd = (pts[-1] - pts[-2]).normalized()
		hd = (hd + Vector3(0, -0.55, -0.4)).normalized()   # baş aşağı-öne (girişe) bakar
		var hs = hd.cross(Vector3.UP).normalized()
		var hu = hs.cross(hd).normalized()
		var hc = nk + hd * 1.0
		Loft.blob(mb, hc, hd, 3.4, [0.9, 1.25, 1.1, 0.7], scol, 14)   # üst kafa
		Loft.blob(mb, hc - hu * 0.75 + hd * 0.2, (hd - hu * 0.55).normalized(), 2.8, [0.7, 0.95, 0.8, 0.4], belly, 12)   # açık alt çene
		for fx in [-1.0, 1.0]:
			mb.add("cone", hc + hd * 1.9 + hs * 0.45 * fx - hu * 0.35, Vector3(0.28, 1.0, 0.28), Color(0.93, 0.9, 0.82), Vector3(180, 0, 0), 5)   # üst diş
			mb.add("sphere", hc + hd * 0.9 + hs * 0.78 * fx + hu * 0.55, Vector3(0.55, 0.32, 0.42), Color(1.0, 0.82, 0.12), Vector3.ZERO, 8)   # göz
			mb.add("box", hc + hd * 1.02 + hs * 0.95 * fx + hu * 0.55, Vector3(0.06, 0.3, 0.06), Color(0.05, 0.04, 0.03), Vector3.ZERO)   # yarık bebek
		for fx in [-1.0, 1.0]:   # çatal dil
			mb.add("box", hc + hd * 2.6 - hu * 0.6 + hs * 0.12 * fx, Vector3(0.1, 0.06, 1.0), Color(0.75, 0.2, 0.25), Vector3(0, fx * 12.0, 0))
		b._collide(b.w(Vector3(cx, gy + 4.5, cn)), Vector3(8.0, 9.0, 8.0), 0.0)
	# dehlizin sonunda yer altı laboratuvarına inen kapı
	b.interact(Vector3(0, my + 0.4, mouth_n + tunnel_len - 1.5), 3.5, "enter", "[F] Aşağı in: Yılan Ustasının Laboratuvarı", {"room": "snake_lab", "path": pid, "out": b.w(Vector3(0, my + 0.4, mouth_n + tunnel_len - 3.0))})
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
	# usta yer altı laboratuvarında (Interiors "snake_lab"); antrenmanlar (zehir sisi, zehir keseleri) dışarıdaki meydanda
	LegendPaths.drill_spots[pid] = {"center": b.w(Vector3(0, y0, 0.0))}
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
	# avlu: talimle aşınmış toprak (otsuz; çimen yol haritasından okur)
	var RM = preload("res://scripts/world/road_map.gd")
	for k in 6:
		var zz = -15.0 + k * 4.0
		var wa = b.w(Vector3(-15.0, 0, zz))
		var wb = b.w(Vector3(15.0, 0, zz))
		RM.add_lane(Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), 2.4, true)
	# antrenman: dört hedef tahtası (atış talimi) + avlu merkezi (silah toplama, silah yağmuru çemberi)
	var posts: Array = []
	for k in 4:
		var tx2 = -7.5 + k * 5.0
		posts.append(b.w(Vector3(tx2, _g(p, base, tx2, -11.0), -11.0)))
	LegendPaths.drill_spots[pid] = {"posts": posts, "center": b.w(Vector3(0, _g(p, base, 0.0, -2.0), -2.0))}
	LegendPaths._mentor(b, pid, Vector3(-1.5, fy + 0.8, 8.4), PI)
	b.interact(Vector3(-1.5, fy, 6.0), 6.5, "path_mentor", "[F] Silah ustasıyla konuş", {"path": pid})
	return 5.0


## Yosunlu Kurbağa Tapınağı (Kurbağa Bilgesi Yolu, Şelale Ülkesi): arkada yosunlu kayalıktan dökülen şelale ve gölet (yürünebilir su,
## nilüfer yaprakları), iki yanda yosun tutmuş dev taş kurbağa heykelleri, kırmızı çatılı küçük tapınak (hokora), kurbağa yağı küpleri,
## ustanın roman yazdığı alçak yazı masası (parşömen yığını, mürekkep, fener), iğne talimi için saman kuklalar.
static func _toad(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var stone = Color(0.5, 0.52, 0.48)
	var moss = Color(0.3, 0.45, 0.25)
	var wood = Color(0.42, 0.28, 0.17)
	var red = Color(0.72, 0.18, 0.14)
	var toad_c = Color(0.55, 0.6, 0.42)
	var spots: Dictionary = {}
	var gy = _g(p, base, 0, 0)
	var RM = preload("res://scripts/world/road_map.gd")
	for k in 11:   # avlu + gölet zemini (gölet altında çimen suyun içinden çıkıyordu)
		var zz = -14.0 + k * 3.5
		var wa = b.w(Vector3(-14.0, 0, zz)); var wb = b.w(Vector3(14.0, 0, zz))
		RM.add_lane(Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), 2.0, true)
	# ---- gölet (arka): kaya halka + yürünebilir su + nilüfer yaprakları + şelale
	var PN = 14.0
	var py = _g(p, base, 0, PN)
	for k in 26:
		var a = TAU * k / 26.0
		var rx = cos(a) * 9.0; var rn = PN + sin(a) * 5.5
		if sin(a) < -0.55 and absf(cos(a)) < 0.5:
			continue   # ön tarafta giriş boşluğu (göletin kıyısına inilir)
		b.boulder(Vector3(rx, _g(p, base, rx, rn) + 0.35, rn), Vector3(1.6, 0.9, 1.4), stone.darkened(0.1 * (k % 3)), k, true)
		b.sphere(Vector3(rx, _g(p, base, rx, rn) + 0.8, rn), Vector3(1.2, 0.25, 1.0), moss, 6)
	AcademyGrounds._oval_water(b, Vector3(0, py + 0.3, PN), 17.0, 10.0)   # oval su: kaya halkasıyla aynı biçim (dikdörtgenin köşeleri taşıyordu)
	for k in 7:
		var lx = randf_range(-6.0, 6.0); var ln = PN + randf_range(-3.0, 3.0)
		b.cyl(Vector3(lx, py + 0.33, ln), randf_range(0.8, 1.3), 0.03, Color(0.3, 0.55, 0.28), false, 10)
		if k % 3 == 0:
			b.sphere(Vector3(lx + 0.2, py + 0.42, ln), Vector3(0.25, 0.18, 0.25), Color(0.95, 0.7, 0.8), 6)   # nilüfer çiçeği
	# şelale kayalığı (göletin arkasında) + dökülen su
	for k in 7:
		b.boulder(Vector3(-7.0 + k * 2.3, py + 3.0 + (k % 2) * 1.5, PN + 6.5), Vector3(3.2, 6.5 + (k % 3), 2.6), stone.darkened(0.15), k + 30, true)
		b.sphere(Vector3(-7.0 + k * 2.3, py + 6.6 + (k % 2) * 1.5, PN + 6.0), Vector3(2.6, 0.6, 2.0), moss.darkened(0.1), 6)
	Waterfalls.add(b.w(Vector3(0, py + 0.3, PN + 5.2)), 7.5, 3.4, 0.0)
	# ---- dev taş kurbağa heykelleri (gölet iki yanında): gövde + baş + yuvarlak gözler + yosun
	for sx in [-1.0, 1.0]:
		var tx = 11.0 * sx; var tn = 9.0
		var ty = _g(p, base, tx, tn)
		b.box(Vector3(tx, ty + 0.4, tn), Vector3(3.2, 0.8, 3.2), stone, 0.0, true)          # kaide
		b.sphere(Vector3(tx, ty + 2.0, tn), Vector3(3.0, 2.4, 3.2), toad_c, 10, true)        # gövde
		b.sphere(Vector3(tx, ty + 3.3, tn - 0.6), Vector3(2.4, 1.4, 2.0), toad_c.lightened(0.05), 10)   # baş
		for ex in [-1.0, 1.0]:
			b.sphere(Vector3(tx + ex * 0.75, ty + 4.0, tn - 0.9), Vector3(0.65, 0.65, 0.65), toad_c.lightened(0.1), 8)
			b.sphere(Vector3(tx + ex * 0.75, ty + 4.05, tn - 1.15), Vector3(0.3, 0.32, 0.2), Color(0.1, 0.08, 0.06), 6)   # göz bebeği
		b.box(Vector3(tx, ty + 3.05, tn - 1.55), Vector3(1.4, 0.06, 0.1), Color(0.2, 0.18, 0.15), 0.0, false)   # ağız çizgisi
		for k in 4:   # ön ayaklar + yosun lekeleri
			b.sphere(Vector3(tx + (k - 1.5) * 0.7, ty + 1.0, tn - 1.5), Vector3(0.5, 0.4, 0.7), toad_c.darkened(0.08), 6)
		b.sphere(Vector3(tx + 0.6, ty + 3.4, tn + 0.2), Vector3(1.2, 0.35, 1.0), moss, 6)
	# ---- küçük tapınak (hokora): taş kaide, ahşap gövde, kırmızı çatı, önünde sunu kabı + kurbağa yağı küpleri
	var hx = -6.0; var hn = 2.0
	var hy = _g(p, base, hx, hn)
	b.box(Vector3(hx, hy + 0.5, hn), Vector3(2.4, 1.0, 2.0), stone)
	b.box(Vector3(hx, hy + 1.6, hn), Vector3(1.8, 1.2, 1.5), wood)
	b.box(Vector3(hx, hy + 1.6, hn - 0.76), Vector3(0.9, 0.8, 0.04), Color(0.15, 0.1, 0.08), 0.0, false)
	b.roof(Vector3(hx, hy + 2.3, hn), Vector3(2.8, 1.0, 2.4), red)
	b.kanji(Vector3(hx, hy + 2.2, hn - 0.9), "蛙", 0.5, Color(0.95, 0.85, 0.5), 180.0)
	for k in 5:   # kurbağa yağı küpleri (kehribar sırlı)
		var jx = hx + 2.0 + (k % 3) * 0.75; var jn = hn - 0.6 + (k / 3) * 0.8
		var jy = _g(p, base, jx, jn)
		b.cyl(Vector3(jx, jy + 0.4, jn), 0.6, 0.8, Color(0.6, 0.38, 0.15), true, 10)
		b.cyl(Vector3(jx, jy + 0.82, jn), 0.36, 0.08, Color(0.25, 0.18, 0.1), false, 8)
	# ---- ustanın yazı masası (sağ önde): alçak masa, parşömen yığını, mürekkep taşı, fener, minder
	var dx = 6.0; var dn = 2.0
	var dy = _g(p, base, dx, dn)
	b.box(Vector3(dx, dy + 0.38, dn), Vector3(1.8, 0.08, 0.9), wood)
	for q in 4:
		b.box(Vector3(dx + (0.8 if q % 2 else -0.8), dy + 0.17, dn + (0.38 if q < 2 else -0.38)), Vector3(0.08, 0.34, 0.08), wood.darkened(0.2), 0.0, false)
	for k in 4:
		b.cyl(Vector3(dx - 0.55, dy + 0.48 + k * 0.08, dn), 0.08, 0.6, Color(0.9, 0.86, 0.72), false, 6)
	b.box(Vector3(dx + 0.2, dy + 0.43, dn), Vector3(0.6, 0.01, 0.5), Color(0.95, 0.93, 0.85), 0.0, false)   # yazılan sayfa
	b.box(Vector3(dx + 0.65, dy + 0.45, dn - 0.2), Vector3(0.18, 0.05, 0.12), Color(0.1, 0.1, 0.12), 0.0, false)   # mürekkep taşı
	b.box(Vector3(dx, dy + 0.04, dn + 0.9), Vector3(0.9, 0.08, 0.7), Color(0.5, 0.25, 0.2), 0.0, false)   # minder
	b.lantern(dx + 2.0, dn)
	b.lantern(hx - 2.0, hn)
	# ---- iğne talimi: saman kuklalar (önde)
	var posts: Array = []
	for k in 3:
		var kx = -3.0 + k * 3.0; var kn = -9.0
		var ky = _g(p, base, kx, kn)
		b.box(Vector3(kx, ky + 0.9, kn), Vector3(0.18, 1.8, 0.18), wood)
		b.cyl(Vector3(kx, ky + 1.5, kn), 0.6, 1.0, Color(0.85, 0.75, 0.45), false, 10)
		b.sphere(Vector3(kx, ky + 2.3, kn), Vector3(0.5, 0.5, 0.5), Color(0.88, 0.78, 0.48))
		posts.append(b.w(Vector3(kx, ky, kn)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -3), -3))
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(dx, dy + 0.05, dn + 0.9), PI)
	b.interact(Vector3(dx, dy, dn - 1.2), 5.0, "path_mentor", "[F] Kurbağa Bilgesi ile konuş", {"path": pid})
	return 5.0


## Kil Atölyesi (Patlayıcı Kil Yolu, Toprak Ülkesi kanyonu): kanyon duvarının dibinde açık hava atölyesi — tuğla kubbe fırın (ağzı kor),
## tente altında yoğurma tezgâhı ve kil figür rafları, yarım kalmış dev kil ejder (iskeleli), üç kil teknesi, tırmanılan kaya kulesi
## (tepesinde kalkışa hazır kil kuş), önde yanık kraterli atış alanı ve hedef tahtaları. Antrenman noktaları LegendPaths.drill_spots'a.
static func _clay_bird(b: Builder, at: Vector3, s: float, yaw: float, clay: Color) -> void:
	var f = Vector3(sin(yaw), 0, cos(yaw))
	var r = Vector3(f.z, 0, -f.x)
	b.sphere(at + Vector3(0, 0.5 * s, 0), Vector3(0.7, 0.6, 1.1) * s, clay, 8)                       # gövde
	b.sphere(at + f * 0.62 * s + Vector3(0, 0.82 * s, 0), Vector3(0.42, 0.4, 0.46) * s, clay.lightened(0.04), 8)   # baş
	b.cone(at + f * 0.98 * s + Vector3(0, 0.78 * s, 0), 0.16 * s, 0.34 * s, clay.darkened(0.12), 6)          # gaga
	for sx in [-1.0, 1.0]:
		b.box(at + r * sx * 0.62 * s + Vector3(0, 0.62 * s, -0.05 * s), Vector3(0.95, 0.07, 0.5) * s, clay.darkened(0.05), yaw, false, Vector3(0, 0, -18.0 * sx))   # kanat
		b.sphere(at + f * 0.76 * s + r * sx * 0.16 * s + Vector3(0, 0.9 * s, 0), Vector3.ONE * 0.07 * s, Color(0.1, 0.1, 0.12), 6)   # göz
	b.box(at - f * 0.7 * s + Vector3(0, 0.5 * s, 0), Vector3(0.36, 0.06, 0.6) * s, clay.darkened(0.08), yaw, false)   # kuyruk


static func _clay(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var rock = Color(0.6, 0.47, 0.36)
	var brick = Color(0.62, 0.33, 0.24)
	var wood = Color(0.42, 0.29, 0.18)
	var clay = Color(0.93, 0.91, 0.84)
	var wet = Color(0.74, 0.72, 0.66)
	var soot = Color(0.16, 0.14, 0.13)
	var spots: Dictionary = {}
	var RM = preload("res://scripts/world/road_map.gd")
	for k in 12:   # atölye ve atış alanı zemini: çıplak toprak
		var zz = -16.0 + k * 3.0
		var wa = b.w(Vector3(-15.0, 0, zz)); var wb = b.w(Vector3(15.0, 0, zz))
		RM.add_lane(Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), 1.8, true)
	# ---- kanyon duvarı (arka): katmanlı kaya blokları, ortada fırını örten saçak
	for k in 13:   # arka sıra: yüksek, geniş, birbirine geçen bloklar; ön sıra: alçak döküntü
		var x = -19.0 + k * 3.2 + sin(k * 2.3) * 0.8
		var n = 21.0 + cos(k * 1.7) * 1.2
		var h = 9.0 + fmod(k * 3.7, 5.0)
		b.boulder(Vector3(x, _g(p, base, x, n) + h * 0.32, n), Vector3(7.5 + fmod(k * 1.9, 3.0), h, 6.0), rock.darkened(0.05 * (k % 4)), k * 5 + 3, true, k * 1.3)
	for k in 9:
		var x = -17.0 + k * 4.3 + cos(k * 3.1)
		if absf(x + 5.0) < 4.0:
			continue   # fırının arkası açık kalsın
		var n = 17.6 + sin(k * 2.9) * 0.8
		var h = 2.6 + fmod(k * 2.3, 2.4)
		b.boulder(Vector3(x, _g(p, base, x, n) + h * 0.3, n), Vector3(4.2 + fmod(k * 1.3, 1.6), h, 3.4), rock.lightened(0.04 * (k % 3)), k * 7 + 1, true, k * 0.9)
	var fy = _g(p, base, 0, 12)
	# ---- tuğla kubbe fırın: kaide, kubbe, kor ağız, baca, odun yığını
	var kx = -5.0; var kn = 13.5
	var ky = _g(p, base, kx, kn)
	b.cyl(Vector3(kx, ky + 0.4, kn), 5.2, 0.8, brick.darkened(0.25), true, 16)
	b.sphere(Vector3(kx, ky + 0.8, kn), Vector3(4.6, 5.6, 4.6), brick, 14, true)
	for r in 4:   # tuğla sıraları
		b.cyl(Vector3(kx, ky + 1.2 + r * 0.62, kn), 4.66 - r * r * 0.22, 0.07, brick.darkened(0.3), false, 16)
	b.box(Vector3(kx, ky + 1.35, kn - 2.2), Vector3(1.5, 1.3, 0.5), soot, 0.0, false)                 # ağız
	b.box(Vector3(kx, ky + 1.0, kn - 2.25), Vector3(1.2, 0.5, 0.42), Color(1.0, 0.5, 0.12), 0.0, false)   # kor
	b.box(Vector3(kx, ky + 2.1, kn - 2.3), Vector3(1.9, 0.25, 0.5), brick.darkened(0.2), 0.0, false)    # lento
	b.cyl(Vector3(kx + 0.6, ky + 4.6, kn + 0.6), 0.9, 2.6, brick.darkened(0.15), true, 10)
	b.cyl(Vector3(kx + 0.6, ky + 5.95, kn + 0.6), 1.1, 0.2, soot, false, 10)
	light(b, b.w(Vector3(kx, ky + 1.2, kn - 3.0)), Color(1.0, 0.55, 0.2), 2.2, 9.0)
	for k in 9:   # odun yığını
		b.cyl(Vector3(kx - 3.6 + (k % 3) * 0.42, ky + 0.25 + (k / 3) * 0.4, kn - 1.0), 0.38, 1.6, wood.darkened(0.1 * (k % 2)), k < 3, 6, -1.0)
	b.kanji(Vector3(kx, ky + 3.3, kn - 2.05), "爆", 1.1, Color(0.12, 0.1, 0.1), 0.0)
	# ---- tente altında tezgâh + figür rafı (sağ arka)
	var tx = 6.0; var tn = 12.0
	var ty = _g(p, base, tx, tn)
	for q in 4:
		b.box(Vector3(tx + (3.4 if q % 2 else -3.4), ty + 1.7, tn + (2.0 if q < 2 else -2.0)), Vector3(0.2, 3.4 if q < 2 else 2.9, 0.2), wood)
	b.box(Vector3(tx, ty + 3.3, tn), Vector3(7.6, 0.08, 4.8), Color(0.82, 0.74, 0.58), 0.0, false, Vector3(-6.0, 0, 0))   # bez tente
	b.box(Vector3(tx, ty + 0.9, tn), Vector3(5.0, 0.12, 1.5), wood)                                     # tezgâh
	for q in 4:
		b.box(Vector3(tx + (2.3 if q % 2 else -2.3), ty + 0.45, tn + (0.6 if q < 2 else -0.6)), Vector3(0.14, 0.9, 0.14), wood.darkened(0.2), 0.0, false)
	for k in 5:   # tezgâhta: kil topakları ve yarım figürler
		var lx = tx - 2.0 + k * 1.0
		if k % 2 == 0:
			b.sphere(Vector3(lx, ty + 1.12, tn), Vector3(0.42, 0.3, 0.38), wet if k == 2 else clay, 8)
		else:
			_clay_bird(b, Vector3(lx, ty + 0.96, tn), 0.34, PI + (k - 2) * 0.4, clay)
	b.cyl(Vector3(tx + 2.1, ty + 1.02, tn - 0.3), 0.6, 0.1, wood.lightened(0.15), false, 12)             # çömlekçi çarkı
	# raf: üç katta kil kuşlar ve örümcekler
	b.box(Vector3(tx, ty + 1.5, tn + 1.9), Vector3(5.4, 3.0, 0.12), wood.darkened(0.15))
	for row in 3:
		b.box(Vector3(tx, ty + 0.7 + row * 0.9, tn + 1.6), Vector3(5.4, 0.08, 0.6), wood)
		for k in 6:
			var sxp = tx - 2.25 + k * 0.9
			if (k + row) % 2 == 0:
				_clay_bird(b, Vector3(sxp, ty + 0.74 + row * 0.9, tn + 1.6), 0.28, PI, clay)
			else:   # kil örümcek: gövde + sekiz bacak
				b.sphere(Vector3(sxp, ty + 0.9 + row * 0.9, tn + 1.6), Vector3(0.26, 0.2, 0.3), clay, 6)
				for j in 8:
					var la = (j + 0.5) * TAU / 8.0
					b.box(Vector3(sxp + cos(la) * 0.2, ty + 0.84 + row * 0.9, tn + 1.6 + sin(la) * 0.2), Vector3(0.04, 0.04, 0.22), clay.darkened(0.1), -la + PI * 0.5, false, Vector3(22.0, 0, 0))
	# ---- yarım kalmış dev kil ejder (sağda): boğum boğum gövde, baş, kanat taslakları, iskele
	var ex = 10.5; var en = 2.5
	var ey = _g(p, base, ex, en)
	var prev = Vector3.ZERO
	for k in 12:   # gövde: baştan kuyruğa incelen, kıvrılan boğumlar; sırtta diken sırası
		var u = k / 11.0
		var bx = ex + sin(u * 3.0) * 2.0; var bn = en + 4.2 - u * 10.0
		var sz = lerpf(2.3, 0.45, pow(u, 0.8))
		var by = _g(p, base, bx, bn) + sz * 0.46 + maxf(0.0, 1.0 - u * 3.0) * 2.4   # boyun yukarı kalkar
		b.sphere(Vector3(bx, by, bn), Vector3(sz, sz * 0.92, sz * 1.5), clay.darkened(0.025 * (k % 2)), 10, sz > 1.5)
		b.cone(Vector3(bx, by + sz * 0.5 + 0.12, bn), sz * 0.28, sz * 0.5, clay.darkened(0.1), 5)
		prev = Vector3(bx, by, bn)
	var hy = ey + 3.9
	b.sphere(Vector3(ex, hy, en + 5.6), Vector3(1.7, 1.35, 2.0), clay, 10, true)                          # kafa
	b.sphere(Vector3(ex, hy - 0.2, en + 6.9), Vector3(1.15, 0.8, 1.6), clay.lightened(0.03), 10)           # burun
	b.box(Vector3(ex, hy - 0.5, en + 6.9), Vector3(1.0, 0.07, 1.4), soot, 0.0, false)                       # ağız yarığı
	for sx in [-1.0, 1.0]:
		b.sphere(Vector3(ex + sx * 0.62, hy + 0.42, en + 6.1), Vector3(0.3, 0.3, 0.3), Color(0.1, 0.1, 0.12), 6)
		b.cone(Vector3(ex + sx * 0.6, hy + 1.0, en + 4.9), 0.36, 1.3, clay.darkened(0.08), 6)              # boynuz
		for j in 2:   # ön ve arka ayak
			var lx = ex + sx * 1.5; var ln = en + 2.6 - j * 3.4
			b.sphere(Vector3(lx, _g(p, base, lx, ln) + 0.55, ln), Vector3(0.9, 1.1, 1.1), clay.darkened(0.04), 8)
		for j in 2:   # iskele direkleri
			b.box(Vector3(ex + sx * 4.6, ey + 2.6, en + 0.4 + j * 4.6), Vector3(0.14, 5.2, 0.14), wood, 0.0, false)
	b.box(Vector3(ex, ey + 5.1, en + 5.0), Vector3(9.4, 0.1, 0.14), wood, 0.0, false)
	b.box(Vector3(ex, ey + 5.1, en + 0.4), Vector3(9.4, 0.1, 0.14), wood, 0.0, false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(ex + sx * 4.6, ey + 3.0, en + 2.7), Vector3(0.1, 0.1, 4.6), wood, 0.0, false)
	# ---- kil tekneleri (solda): ıslak kil dolu üç tekne (yoğurma antrenmanı)
	var vats: Array = []
	for k in 3:
		var vx = -10.0 + (k % 2) * 3.2; var vn = 4.0 + k * 2.6
		var vy = _g(p, base, vx, vn)
		b.cyl(Vector3(vx, vy + 0.35, vn), 2.2, 0.7, wood.darkened(0.1), true, 12)
		b.cyl(Vector3(vx, vy + 0.68, vn), 1.95, 0.08, wet, false, 12)
		b.sphere(Vector3(vx + 0.3, vy + 0.78, vn - 0.2), Vector3(0.7, 0.3, 0.6), clay, 8)
		vats.append(b.w(Vector3(vx, vy, vn - 1.75)))
	spots["vats"] = vats
	for k in 4:   # kil çuvalları
		b.sphere(Vector3(-13.0 + (k % 2) * 0.9, _g(p, base, -13, 9) + 0.3 + (k / 2) * 0.5, 9.0), Vector3(0.9, 0.55, 0.7), Color(0.72, 0.64, 0.5), 8, k < 2)
	# ---- kaya kulesi (sol önde): sarmal basamak kayalar, tepede kalkışa hazır kil kuş
	var sx0 = -12.0; var sn0 = -5.0
	var sy0 = _g(p, base, sx0, sn0)
	b.cyl(Vector3(sx0, sy0 + 4.6, sn0), 4.0, 9.2, rock, true, 9)
	b.cyl(Vector3(sx0, sy0 + 9.3, sn0), 4.6, 0.3, rock.lightened(0.08), true, 9)
	for k in 5:
		var a = PI * 0.5 + k * 1.15
		var hx = sx0 + cos(a) * 3.0; var hn = sn0 + sin(a) * 3.0
		var hh = 1.7 + k * 1.75
		b.cyl(Vector3(hx, sy0 + hh * 0.5, hn), 2.3, hh, rock.darkened(0.05 + 0.03 * (k % 2)), true, 7)
	_clay_bird(b, Vector3(sx0, sy0 + 9.45, sn0 + 0.6), 1.5, PI, clay)
	spots["top"] = [b.w(Vector3(sx0, sy0 + 9.5, sn0 - 1.2))]
	# ---- atış alanı (önde): yanık kraterler + hedef tahtaları
	var posts: Array = []
	for k in 4:
		var px = -4.5 + k * 3.0; var pn = -13.0
		var pyy = _g(p, base, px, pn)
		b.box(Vector3(px, pyy + 1.0, pn), Vector3(0.18, 2.0, 0.18), wood)
		b.sphere(Vector3(px, pyy + 1.9, pn + 0.12), Vector3(1.4, 1.4, 0.14), Color(0.9, 0.86, 0.75), 14)
		b.sphere(Vector3(px, pyy + 1.9, pn + 0.2), Vector3(0.8, 0.8, 0.1), Color(0.75, 0.2, 0.15), 12)
		b.sphere(Vector3(px, pyy + 1.9, pn + 0.26), Vector3(0.3, 0.3, 0.08), Color(0.9, 0.86, 0.75), 10)
		posts.append(b.w(Vector3(px, pyy, pn)))
	for k in 6:
		var cx = -6.0 + fmod(k * 5.3, 13.0); var cn = -6.0 - fmod(k * 3.1, 5.0)
		var cy = _g(p, base, cx, cn)
		b.sphere(Vector3(cx, cy + 0.03, cn), Vector3(2.6 + (k % 2), 0.08, 2.4 + (k % 3) * 0.4), soot, 10)
		for j in 5:
			var ra = j * 1.3 + k
			b.boulder(Vector3(cx + cos(ra) * 1.5, cy + 0.12, cn + sin(ra) * 1.4), Vector3(0.5, 0.3, 0.45), rock.darkened(0.3), j + k, false)
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -5), -5))
	b.lantern(tx - 4.2, tn - 2.4)
	b.lantern(-8.5, 10.0)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(tx - 1.0, ty + 0.05, tn - 1.6), PI)
	b.interact(Vector3(tx - 1.0, ty, tn - 3.2), 5.0, "path_mentor", "[F] Kil Sanatçısı ile konuş", {"path": pid})
	return 8.5


static func _dirt(b: Builder, hx: float, n0: float, n1: float) -> void:
	var RM = preload("res://scripts/world/road_map.gd")
	var n = n0
	while n <= n1:
		var wa = b.w(Vector3(-hx, 0, n)); var wb = b.w(Vector3(hx, 0, n))
		RM.add_lane(Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), 1.8, true)
		n += 3.0


## Saman kukla (vuruş talimi): direk + gövde + baş; döner: dünya konumu
static func _straw(b: Builder, p: Vector2, base: float, x: float, n: float, col := Color(0.85, 0.75, 0.45)) -> Vector3:
	var y = _g(p, base, x, n)
	b.box(Vector3(x, y + 0.9, n), Vector3(0.18, 1.8, 0.18), Color(0.4, 0.28, 0.17))
	b.cyl(Vector3(x, y + 1.5, n), 0.6, 1.0, col, false, 10)
	b.sphere(Vector3(x, y + 2.3, n), Vector3(0.5, 0.5, 0.5), col.lightened(0.05))
	return b.w(Vector3(x, y, n))


## Kara İplik Mezarlığı (Toprak Kini Yolu, Şelale Ülkesi): eğik mezar taşları, ölü ağaçlar; arkada taş ödül morgu (kefenli
## bedenlerin yattığı taş sedirler, defter masası, para sandıkları); meydanda dört kalbin maskesi direklerde, aralarında kara iplikler.
static func _thread(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var stone = Color(0.4, 0.4, 0.43)
	var dark = Color(0.07, 0.07, 0.09)
	var wood = Color(0.3, 0.22, 0.16)
	var spots: Dictionary = {}
	_dirt(b, 14.0, -15.0, 9.0)
	# ---- taş morg (arka): alçak, kalın duvarlı, kapısı açık; içeride üç sedir
	var my = maxf(_g(p, base, -6, 15), _g(p, base, 6, 15))
	b.box(Vector3(0, my + 0.25, 15), Vector3(17, 0.5, 9), stone.darkened(0.2))
	b.box(Vector3(0, my + 2.4, 19.3), Vector3(17, 4.3, 0.6), stone)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(8.2 * sx, my + 2.4, 15), Vector3(0.6, 4.3, 9), stone)
		b.box(Vector3(5.6 * sx, my + 2.4, 10.8), Vector3(5.6, 4.3, 0.6), stone.lightened(0.04))
	b.box(Vector3(0, my + 4.1, 10.8), Vector3(5.8, 0.9, 0.7), stone.darkened(0.1))
	b.box(Vector3(0, my + 4.8, 15), Vector3(18, 0.5, 10), stone.darkened(0.25))
	b.kanji(Vector3(0, my + 4.1, 10.4), "賞", 0.8, Color(0.75, 0.7, 0.55), 0.0)
	var slabs: Array = []
	for k in 3:
		var sx2 = -5.0 + k * 5.0
		b.box(Vector3(sx2, my + 0.95, 16.6), Vector3(1.3, 0.9, 2.6), stone.lightened(0.08))
		b.sphere(Vector3(sx2, my + 1.6, 16.6), Vector3(0.9, 0.5, 2.2), Color(0.82, 0.8, 0.74), 8)        # kefenli beden
		b.sphere(Vector3(sx2, my + 1.68, 17.5), Vector3(0.5, 0.42, 0.5), Color(0.82, 0.8, 0.74), 8)
		for j in 4:   # dikiş izleri
			b.box(Vector3(sx2, my + 1.86, 16.0 + j * 0.35), Vector3(0.5, 0.03, 0.05), dark, 0.5, false)
		slabs.append(b.w(Vector3(sx2, my + 0.5, 14.6)))
	spots["slabs"] = slabs
	light(b, b.w(Vector3(0, my + 3.4, 15)), Color(0.6, 0.85, 0.6), 1.2, 11.0)
	# defter masası + para sandıkları (kapının sağında, dışarıda)
	var dx = 5.5; var dn = 8.2
	var dy = _g(p, base, dx, dn)
	b.box(Vector3(dx, dy + 0.8, dn), Vector3(2.4, 0.1, 1.1), wood)
	for q in 4:
		b.box(Vector3(dx + (1.05 if q % 2 else -1.05), dy + 0.4, dn + (0.4 if q < 2 else -0.4)), Vector3(0.12, 0.8, 0.12), wood.darkened(0.2), 0.0, false)
	b.box(Vector3(dx - 0.4, dy + 0.9, dn), Vector3(0.7, 0.08, 0.5), Color(0.9, 0.86, 0.72), 0.2, false)     # ödül defteri
	for k in 3:
		b.box(Vector3(dx + 2.2 + k * 0.2, dy + 0.35 + k * 0.62, dn + 0.3), Vector3(1.1, 0.6, 0.75), Color(0.22, 0.2, 0.18), k * 0.15)
		b.box(Vector3(dx + 2.2 + k * 0.2, dy + 0.35 + k * 0.62, dn - 0.08), Vector3(0.2, 0.2, 0.04), Color(0.8, 0.65, 0.2), k * 0.15, false)
	# ---- dört maske direği (ateş, rüzgâr, şimşek, su) ve aralarındaki kara iplik ağı
	var masks = [Color(0.75, 0.2, 0.15), Color(0.5, 0.7, 0.55), Color(0.85, 0.75, 0.25), Color(0.3, 0.45, 0.75)]
	var tops: Array = []
	for k in 4:
		var a = PI * 0.25 + k * PI * 0.5
		var px = cos(a) * 8.5; var pn = 1.0 + sin(a) * 5.5
		var py = _g(p, base, px, pn)
		b.cyl(Vector3(px, py + 2.3, pn), 0.34, 4.6, wood, true, 7)
		b.sphere(Vector3(px, py + 4.5, pn - 0.2), Vector3(1.0, 1.25, 0.5), Color(0.9, 0.88, 0.82), 10)        # maske
		b.sphere(Vector3(px, py + 4.95, pn - 0.42), Vector3(0.7, 0.3, 0.12), masks[k], 8)                      # alın boyası
		for ex in [-1.0, 1.0]:
			b.sphere(Vector3(px + ex * 0.22, py + 4.55, pn - 0.44), Vector3(0.2, 0.1, 0.08), dark, 6)
		b.box(Vector3(px, py + 4.1, pn - 0.44), Vector3(0.42, 0.05, 0.05), dark, 0.0, false)
		tops.append(Vector3(px, py + 3.9, pn))
	for k in 4:
		var t0: Vector3 = tops[k]; var t1: Vector3 = tops[(k + 1) % 4]
		for j in 3:   # sarkan üç iplik
			var prev = t0 - Vector3(0, j * 0.5, 0)
			for q in range(1, 9):
				var u = q / 8.0
				var cur = t0.lerp(t1, u) - Vector3(0, j * 0.5 + sin(u * PI) * (0.5 + j * 0.25), 0)
				rod(b, prev, cur, 0.05, dark, 4)
				prev = cur
	for k in 5:   # yerde kara iplik yumakları
		var hx2 = -7.0 + k * 3.4; var hn2 = 1.0 + sin(k * 2.2) * 3.0
		b.sphere(Vector3(hx2, _g(p, base, hx2, hn2) + 0.22, hn2), Vector3(1.1, 0.42, 0.9), dark, 8)
	# ---- mezar taşları ve ölü ağaçlar (iki yanda)
	for k in 14:
		var gx = (-12.5 if k % 2 == 0 else 12.5) + sin(k * 1.9) * 1.4
		var gn = -11.0 + (k / 2) * 3.4
		var gyy = _g(p, base, gx, gn)
		b.box(Vector3(gx, gyy + 0.75, gn), Vector3(0.9, 1.5 + fmod(k * 0.37, 0.6), 0.28), stone.lightened(0.05 * (k % 3)), sin(k * 3.3) * 0.35, true, Vector3(sin(k * 2.1) * 7.0, 0, cos(k * 1.3) * 6.0))
		b.sphere(Vector3(gx, gyy + 0.1, gn + 0.9), Vector3(1.1, 0.3, 1.9), Color(0.3, 0.27, 0.24), 8)      # mezar tümseği
	for k in 4:
		var tx2 = [-15.0, 15.0, -14.0, 14.5][k]; var tn2 = [-6.0, -3.0, 9.0, 7.0][k]
		dead_tree(b, tx2, _g(p, base, tx2, tn2), tn2, 1.2, k * 1.7)
	fog(b, b.w(Vector3(0, _g(p, base, 0, -4) + 0.4, -4)), 12.0, Color(0.55, 0.6, 0.6), 12)
	# ---- talim: iplikle dikilmiş kuklalar (önde)
	var posts: Array = []
	for k in 3:
		posts.append(_straw(b, p, base, -3.0 + k * 3.0, -10.0, Color(0.6, 0.55, 0.45)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -3), -3))
	b.lantern(-3.6, 9.4)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(dx, dy + 0.05, dn - 1.1), PI)
	b.interact(Vector3(dx, dy, dn - 2.6), 5.0, "path_mentor", "[F] İplik Ustası ile konuş", {"path": pid})
	return 5.5


## Üç kollu işaret kunaisi (yere saplı): sap + mühür kâğıdı + üç ağız
static func _mark_kunai(b: Builder, at: Vector3, s: float) -> void:
	var steel = Color(0.74, 0.76, 0.8)
	b.cyl(at + Vector3(0, 0.55 * s, 0), 0.1 * s, 0.7 * s, Color(0.92, 0.88, 0.7), false, 6)       # mühürlü sap
	b.cyl(at + Vector3(0, 0.95 * s, 0), 0.22 * s, 0.06 * s, Color(0.3, 0.3, 0.33), false, 8)     # halka
	b.box(at + Vector3(0, 0.12 * s, 0), Vector3(0.1, 0.5, 0.03) * s, steel, 0.0, false)          # orta ağız (toprakta)
	for sx in [-1.0, 1.0]:
		b.box(at + Vector3(sx * 0.14 * s, 0.24 * s, 0), Vector3(0.07, 0.3, 0.03) * s, steel, 0.0, false, Vector3(0, 0, 28.0 * sx))


## Yıldırım Mührü Tapınağı (Uçan Yıldırım Yolu, Girdap harabeleri): yıkık Uzumaki tapınağı — kırık sütunlar, yarısı çökmüş torii,
## yerde girdap arması taş kürsü, ışınlanma formülü kazılı mühür taşı, avluya halka halka saplı üç kollu işaret kunaileri.
static func _thunder(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var stone = Color(0.62, 0.6, 0.55)
	var red = Color(0.7, 0.2, 0.15)
	var moss = Color(0.32, 0.46, 0.26)
	var spots: Dictionary = {}
	_dirt(b, 13.0, -15.0, 6.0)
	# ---- yıkık tapınak kürsüsü (arka): basamaklı taş zemin, ayakta kalan ve devrilmiş sütunlar, çatısız arka duvar
	var ty = maxf(_g(p, base, -7, 15), _g(p, base, 7, 15))
	b.box(Vector3(0, ty + 0.3, 15), Vector3(20, 0.6, 11), stone.darkened(0.12))
	b.box(Vector3(0, ty + 0.75, 15.5), Vector3(17, 0.3, 9), stone)
	b.box(Vector3(0, ty + 0.15, 8.9), Vector3(8, 0.3, 1.2), stone.darkened(0.05))
	for k in 6:
		var cx = -7.0 + (k % 3) * 7.0; var cn = 12.0 + (k / 3) * 6.5
		var h = [5.2, 2.2, 5.2, 3.4, 5.2, 1.4][k]
		b.cyl(Vector3(cx, ty + 0.9 + h * 0.5, cn), 1.0, h, stone.lightened(0.05), true, 10)
		b.cyl(Vector3(cx, ty + 1.0, cn), 1.4, 0.3, stone.darkened(0.1), false, 10)
		if h > 5.0:
			b.box(Vector3(cx, ty + 0.9 + h + 0.2, cn), Vector3(1.5, 0.4, 1.5), stone.darkened(0.08))
		else:
			b.sphere(Vector3(cx, ty + 0.95 + h, cn), Vector3(1.05, 0.3, 1.0), moss, 8)
	b.box(Vector3(-3.5, ty + 1.4, 13.5), Vector3(1.0, 1.0, 3.4), stone.lightened(0.03), 0.5, true, Vector3(0, 0, 8.0))   # devrik sütun parçası
	b.box(Vector3(3.0, ty + 3.2, 19.6), Vector3(11, 5.0, 0.7), stone.darkened(0.06))
	b.boulder(Vector3(-6.5, ty + 1.6, 19.4), Vector3(4.0, 2.6, 2.4), stone.darkened(0.15), 4, true)
	# mühür taşı: ışınlanma formülü
	b.box(Vector3(3.0, ty + 2.6, 19.1), Vector3(2.6, 3.4, 0.4), Color(0.25, 0.25, 0.28))
	for k in 4:
		b.kanji(Vector3(3.0, ty + 3.9 - k * 0.72, 18.85), ["飛", "雷", "神", "術"][k], 0.6, Color(0.98, 0.85, 0.3), 0.0)
	light(b, b.w(Vector3(3.0, ty + 2.6, 17.8)), Color(1.0, 0.85, 0.35), 1.6, 9.0)
	# girdap arması (kürsünün ortasında): iç içe halkalar + kıvrım
	for k in 4:
		b.cyl(Vector3(0, ty + 0.92 + k * 0.01, 14.5), 4.6 - k * 1.1, 0.04, red if k % 2 == 0 else stone.lightened(0.12), false, 24)
	# ---- yarısı çökmüş torii (girişte)
	var gy = _g(p, base, 0, -4)
	b.cyl(Vector3(-4.0, gy + 3.2, -4), 0.6, 6.4, red, true, 10)
	b.cyl(Vector3(4.0, gy + 1.4, -4), 0.6, 2.8, red.darkened(0.1), true, 10)
	b.box(Vector3(-1.2, gy + 6.3, -4), Vector3(7.4, 0.5, 0.8), red.darkened(0.2), 0.0, true, Vector3(0, 0, -9.0))
	b.box(Vector3(5.6, gy + 0.4, -3.2), Vector3(4.0, 0.5, 0.7), red.darkened(0.25), 0.7, true, Vector3(0, 0, 4.0))   # düşmüş kiriş
	shimenawa(b, Vector3(-4.0, gy + 5.2, -4.2), Vector3(3.6, gy + 2.6, -4.2), 0.9)
	# ---- işaret kunaileri: avluda sekiz işaret (ışınlanma talimi) + hedef direkleri
	var marks: Array = []
	for k in 8:
		var a = TAU * k / 8.0 + 0.3
		var mx = cos(a) * 10.0; var mn = 1.0 + sin(a) * 6.0
		var myy = _g(p, base, mx, mn)
		b.cyl(Vector3(mx, myy + 0.06, mn), 1.7, 0.12, stone.darkened(0.1), false, 10)
		_mark_kunai(b, Vector3(mx, myy + 0.1, mn), 1.5)
		marks.append(b.w(Vector3(mx, myy, mn)))
	spots["marks"] = marks
	var posts: Array = []
	for k in 4:
		var px = -4.5 + k * 3.0; var pn = -12.0
		var pyy = _g(p, base, px, pn)
		b.box(Vector3(px, pyy + 1.0, pn), Vector3(0.18, 2.0, 0.18), Color(0.4, 0.28, 0.17))
		b.sphere(Vector3(px, pyy + 1.9, pn + 0.12), Vector3(1.4, 1.4, 0.14), Color(0.9, 0.86, 0.75), 14)
		b.sphere(Vector3(px, pyy + 1.9, pn + 0.2), Vector3(0.7, 0.7, 0.1), Color(0.98, 0.8, 0.2), 12)
		posts.append(b.w(Vector3(px, pyy, pn)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, 1), 1))
	for k in 6:
		mossy_rock(b, [-13.0, 13.0, -12.0, 12.5, -14.0, 14.0][k], _g(p, base, [-13.0, 13.0, -12.0, 12.5, -14.0, 14.0][k], -9.0 + k * 3.6), -9.0 + k * 3.6, 1.2 + (k % 3) * 0.5, k)
	b.lantern(-5.0, 8.4)
	b.lantern(5.0, 8.4)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(0, ty + 0.95, 11.0), PI)
	b.interact(Vector3(0, ty + 0.3, 8.6), 5.5, "path_mentor", "[F] Sarı Şimşek ile konuş", {"path": pid})
	return 8.0


## Bin Kuş Uçurumu (Şimşek Kılıcı Yolu, Demir Ülkesi): yıldırımın düştüğü kayalık — bakır sargılı paratoner direkleri, ortadan
## yarılmış yanık kayalar (Chidori talimi), delinmiş kaya sırası, taş sığınak ve kılıç askısı, arkada sivri zirve.
static func _chidori(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var rock = Color(0.42, 0.44, 0.5)
	var metal = Color(0.3, 0.31, 0.35)
	var copper = Color(0.75, 0.45, 0.25)
	var burn = Color(0.12, 0.12, 0.14)
	var wood = Color(0.36, 0.26, 0.18)
	var spots: Dictionary = {}
	_dirt(b, 13.0, -15.0, 9.0)
	# ---- sivri zirve ve kayalık (arka)
	for k in 9:
		var x = -16.0 + k * 4.0 + sin(k * 2.1)
		var h = 7.0 + fmod(k * 4.3, 6.0) + (9.0 if k == 4 else 0.0)
		b.boulder(Vector3(x, _g(p, base, x, 20.0) + h * 0.33, 20.0 + cos(k * 1.9)), Vector3(5.6, h, 5.0), rock.darkened(0.05 * (k % 3)), k * 3 + 2, true, k * 1.1)
	# ---- paratoner direkleri: beş direk, bakır sargı, tepede top; diplerinde yanık halka
	for k in 5:
		var a = PI * 0.15 + k * PI * 0.175
		var lx = cos(a) * 11.5; var ln = 4.0 + sin(a) * 9.0
		var ly = _g(p, base, lx, ln)
		b.cyl(Vector3(lx, ly + 4.5, ln), 0.26, 9.0, metal, true, 7)
		for j in 5:
			b.cyl(Vector3(lx, ly + 2.0 + j * 0.42, ln), 0.42, 0.16, copper, false, 8)
		b.cone(Vector3(lx, ly + 9.5, ln), 0.3, 1.0, metal.lightened(0.2), 6)
		b.cyl(Vector3(lx, ly + 0.04, ln), 2.6, 0.06, burn, false, 12)
		if k % 2 == 0:
			light(b, b.w(Vector3(lx, ly + 9.0, ln)), Color(0.6, 0.8, 1.0), 1.4, 8.0)
	# ---- taş sığınak (sol arka): üç duvar, taş çatı, içinde kılıç askısı ve ocak
	var hx = -8.0; var hn = 13.0
	var hy = _g(p, base, hx, hn)
	b.box(Vector3(hx, hy + 1.4, hn + 2.2), Vector3(6.0, 2.8, 0.6), rock.lightened(0.06))
	for sx in [-1.0, 1.0]:
		b.box(Vector3(hx + sx * 2.7, hy + 1.4, hn), Vector3(0.6, 2.8, 4.4), rock.lightened(0.03))
	b.box(Vector3(hx, hy + 3.0, hn - 0.2), Vector3(7.0, 0.5, 5.4), rock.darkened(0.12), 0.0, true, Vector3(-5.0, 0, 0))
	b.box(Vector3(hx, hy + 1.5, hn + 1.8), Vector3(3.4, 0.1, 0.2), wood, 0.0, false)                       # kılıç askısı
	for k in 3:
		b.box(Vector3(hx - 1.1 + k * 1.1, hy + 1.0, hn + 1.7), Vector3(0.07, 1.5, 0.05), Color(0.78, 0.8, 0.86), 0.0, false, Vector3(0, 0, 6.0))
		b.box(Vector3(hx - 1.1 + k * 1.1, hy + 1.75, hn + 1.7), Vector3(0.24, 0.06, 0.1), burn, 0.0, false)
	b.cyl(Vector3(hx + 1.2, hy + 0.15, hn - 0.4), 1.0, 0.3, rock.darkened(0.2), false, 8)                 # ocak
	light(b, b.w(Vector3(hx + 1.2, hy + 0.6, hn - 0.4)), Color(1.0, 0.6, 0.25), 1.6, 7.0)
	# ---- yarılmış yanık kayalar (Chidori talimi): iki yarım + ortada yanık yarık
	var posts: Array = []
	for k in 3:
		var rx = -5.0 + k * 5.0; var rn = -9.0
		var ry = _g(p, base, rx, rn)
		for sx in [-1.0, 1.0]:
			b.boulder(Vector3(rx + sx * 0.95, ry + 1.2, rn), Vector3(1.7, 2.8, 2.4), rock.lightened(0.04 * k), k * 4 + int(sx) + 3, true, sx * 0.3)
			b.box(Vector3(rx + sx * 0.2, ry + 0.9, rn), Vector3(0.08, 1.5, 1.5), burn, 0.0, false)
		b.cyl(Vector3(rx, ry + 0.04, rn - 1.6), 2.2, 0.06, burn, false, 10)
		posts.append(b.w(Vector3(rx, ry, rn - 1.4)))
	spots["posts"] = posts
	# delinmiş kaya sırası (sağda): Chidori Eisō ile delinen levhalar
	for k in 4:
		var sx3 = 9.0; var sn3 = -6.0 + k * 2.6
		var sy3 = _g(p, base, sx3, sn3)
		b.box(Vector3(sx3, sy3 + 1.3, sn3), Vector3(2.4, 2.6, 0.5), rock.lightened(0.08), 0.1 * k)
		b.sphere(Vector3(sx3, sy3 + 1.5, sn3), Vector3(0.7, 0.7, 0.56), burn, 8)
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, 0), 0))
	b.lantern(-4.0, 10.0)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(hx + 0.2, hy + 0.05, hn - 3.6), PI)
	b.interact(Vector3(hx + 0.2, hy, hn - 5.0), 5.0, "path_mentor", "[F] Şimşek Kılıcı ile konuş", {"path": pid})
	return 8.0


## Kanlı Ayin Tapınağı (Jashin Yolu, Sıcak Su Ülkesi): kara taş basamaklı sunak, arkasında dik duran dev Jashin halkası (çember + ters
## üçgen), yerde kan çemberi, kazıklar, kor mangallar, kemik yığınları, kızıl flamalar, üç ağızlı tırpan anıtı.
static func _jashin(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var stone = Color(0.2, 0.19, 0.21)
	var blood = Color(0.55, 0.05, 0.06)
	var bone = Color(0.86, 0.83, 0.74)
	var iron = Color(0.3, 0.3, 0.33)
	var spots: Dictionary = {}
	_dirt(b, 13.0, -15.0, 8.0)
	# ---- basamaklı sunak + dik Jashin halkası
	var ay = maxf(_g(p, base, -6, 15), _g(p, base, 6, 15))
	for k in 3:
		b.box(Vector3(0, ay + 0.3 + k * 0.6, 15.0 + k * 0.9), Vector3(16.0 - k * 3.0, 0.6, 9.0 - k * 1.8), stone.lightened(0.03 * k))
	b.box(Vector3(0, ay + 2.3, 16.5), Vector3(3.4, 1.0, 1.6), stone.lightened(0.1))                     # sunak taşı
	b.box(Vector3(0, ay + 2.82, 16.5), Vector3(3.0, 0.05, 1.2), blood, 0.0, false)
	var rc = Vector3(0, ay + 6.6, 19.0)
	for k in 24:   # halka
		var a0 = TAU * k / 24.0; var a1 = TAU * (k + 1) / 24.0
		rod(b, rc + Vector3(cos(a0), sin(a0), 0) * 3.4, rc + Vector3(cos(a1), sin(a1), 0) * 3.4, 0.5, stone.lightened(0.12), 6)
	for k in 3:   # ters üçgen
		var a0 = -PI * 0.5 + k * TAU / 3.0; var a1 = -PI * 0.5 + (k + 1) * TAU / 3.0
		rod(b, rc + Vector3(cos(a0), sin(a0), 0) * 3.3, rc + Vector3(cos(a1), sin(a1), 0) * 3.3, 0.4, stone.lightened(0.12), 6)
	b.box(Vector3(0, ay + 2.6, 19.0), Vector3(1.2, 2.2, 1.0), stone)                                  # halkanın ayağı
	for sx in [-1.0, 1.0]:   # mangallar + flamalar
		b.cyl(Vector3(sx * 5.0, ay + 2.5, 14.2), 0.9, 1.4, iron, true, 8)
		b.sphere(Vector3(sx * 5.0, ay + 3.3, 14.2), Vector3(0.8, 0.5, 0.8), Color(1.0, 0.35, 0.1), 8)
		light(b, b.w(Vector3(sx * 5.0, ay + 3.8, 14.2)), Color(1.0, 0.3, 0.15), 2.0, 10.0)
		b.cyl(Vector3(sx * 7.6, ay + 3.6, 18.6), 0.2, 7.2, iron, true, 6)
		b.box(Vector3(sx * 7.6, ay + 5.0, 18.4), Vector3(1.3, 3.6, 0.05), blood.darkened(0.1), 0.0, false)
	# ---- yerde kan çemberi + üçgen (ayin alanı)
	var cy = _g(p, base, 0, 2) + 0.05
	for k in 36:   # çember: zemine oturan kan izi (eğimli arazide yarısı toprağa gömülmesin)
		var a0 = TAU * k / 36.0; var a1 = TAU * (k + 1) / 36.0
		var q0 = Vector3(cos(a0) * 6.0, 0, 2 + sin(a0) * 6.0); var q1 = Vector3(cos(a1) * 6.0, 0, 2 + sin(a1) * 6.0)
		q0.y = _g(p, base, q0.x, q0.z) + 0.07; q1.y = _g(p, base, q1.x, q1.z) + 0.07
		rod(b, q0, q1, 0.3, blood, 4)
	for k in 3:
		var a1 = -PI * 0.5 + k * TAU / 3.0
		var a2 = -PI * 0.5 + (k + 1) * TAU / 3.0
		var prev = Vector3.ZERO
		for q in 9:
			var u = q / 8.0
			var cur = Vector3(lerpf(cos(a1), cos(a2), u) * 5.8, 0, 2 + lerpf(sin(a1), sin(a2), u) * 5.8)
			cur.y = _g(p, base, cur.x, cur.z) + 0.07
			if q > 0:
				rod(b, prev, cur, 0.24, blood, 4)
			prev = cur
	# ---- kazıklar (çemberin çevresinde) ve kemik yığınları
	for k in 8:
		var a = TAU * k / 8.0 + 0.2
		var kx = cos(a) * 9.5; var kn = 2.0 + sin(a) * 8.0
		if kn < -4.5 or kn > 9.0:
			continue
		var kyy = _g(p, base, kx, kn)
		b.cyl(Vector3(kx, kyy + 1.4, kn), 0.14, 2.8, Color(0.25, 0.2, 0.18), false, 6)
		b.cone(Vector3(kx, kyy + 3.0, kn), 0.14, 0.5, iron.lightened(0.3), 6)
		if k % 2 == 0:
			bones(b, kx + 0.8, kyy, kn + 0.4, 1.0)
	# üç ağızlı tırpan anıtı (sağda)
	var sx2 = 11.0; var sn2 = 9.0
	var sy2 = _g(p, base, sx2, sn2)
	b.box(Vector3(sx2, sy2 + 0.4, sn2), Vector3(2.0, 0.8, 2.0), stone.lightened(0.06))
	rod(b, Vector3(sx2 - 1.2, sy2 + 0.8, sn2), Vector3(sx2 + 1.0, sy2 + 7.0, sn2), 0.22, iron, 6)
	for j in 3:
		b.box(Vector3(sx2 + 0.2 + j * 0.3, sy2 + 5.6 + j * 0.55 - 0.3, sn2 - 0.6 - j * 0.05), Vector3(0.1, 0.45, 2.2 - j * 0.3), blood.lightened(0.15), 0.0, false, Vector3(-18.0, 0, 0))
	# ---- talim kuklaları (önde) + atış için ikinci sıra
	var posts: Array = []
	for k in 4:
		posts.append(_straw(b, p, base, -4.5 + k * 3.0, -11.0, Color(0.7, 0.6, 0.42)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, cy, 2))
	fog(b, b.w(Vector3(0, cy + 0.3, 2)), 10.0, Color(0.5, 0.2, 0.2), 10)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(0, ay + 1.85, 14.4), PI)
	b.interact(Vector3(0, ay + 0.7, 11.6), 5.5, "path_mentor", "[F] Ayin Rahibi ile konuş", {"path": pid})
	return 10.0


## Hileler ve Gerçekler Şelalesi (Sekiz Kuyruk Yolu, Yıldırım Ülkesi): şelale kayalığı ve göleti, gölün ortasında shimenawa ile çevrili
## meditasyon adası, başsız taş bekçi heykelleri, yedi kılıçlı askı, ritim davulları ve kafiye defteri.
static func _octo(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var rock = Color(0.5, 0.48, 0.5)
	var moss = Color(0.3, 0.45, 0.28)
	var wood = Color(0.4, 0.27, 0.17)
	var spots: Dictionary = {}
	_dirt(b, 13.0, -15.0, 3.0)
	var PN = 13.0
	var py = _g(p, base, 0, PN)
	# ---- şelale kayalığı (arka) + dökülen su + gölet
	for k in 9:
		var x = -14.0 + k * 3.5
		var h = 10.0 + fmod(k * 3.3, 4.0)
		b.boulder(Vector3(x, py + h * 0.34, PN + 8.5 + cos(k * 1.7)), Vector3(5.4, h, 5.0), rock.darkened(0.06 * (k % 3)), k * 3 + 5, true, k * 0.8)
		b.sphere(Vector3(x, py + h * 0.82, PN + 7.6), Vector3(3.6, 0.6, 2.4), moss, 6)
	Waterfalls.add(b.w(Vector3(0, py + 0.3, PN + 6.0)), 9.0, 4.2, 0.0)
	AcademyGrounds._oval_water(b, Vector3(0, py + 0.3, PN), 24.0, 12.0)
	for k in 22:   # kıyı kayaları
		var a = TAU * k / 22.0
		if sin(a) < -0.6 and absf(cos(a)) < 0.45:
			continue
		var rx = cos(a) * 12.6; var rn = PN + sin(a) * 6.6
		b.boulder(Vector3(rx, _g(p, base, rx, rn) + 0.3, rn), Vector3(1.8, 0.9, 1.5), rock.darkened(0.08 * (k % 3)), k, true)
	# ---- meditasyon adası: yassı taş, dört direk ve shimenawa
	b.cyl(Vector3(0, py + 0.35, PN - 0.5), 4.6, 0.7, rock.lightened(0.08), true, 12)
	b.cyl(Vector3(0, py + 0.75, PN - 0.5), 1.6, 0.12, Color(0.82, 0.76, 0.6), false, 12)                 # hasır minder
	var corners = []
	for k in 4:
		var a = PI * 0.25 + k * PI * 0.5
		var q = Vector3(cos(a) * 1.9, py + 0.7, PN - 0.5 + sin(a) * 1.9)
		b.cyl(q + Vector3(0, 0.8, 0), 0.14, 1.6, wood, false, 6)
		corners.append(q + Vector3(0, 1.5, 0))
	for k in 4:
		shimenawa(b, corners[k], corners[(k + 1) % 4], 0.25)
	for k in 3:   # adaya basma taşları
		b.cyl(Vector3(0, py + 0.3, PN - 3.6 - k * 1.5), 1.2, 0.5, rock, true, 8)
	spots["island"] = [b.w(Vector3(0, py + 0.75, PN - 0.5))]
	# ---- başsız taş bekçiler (göletin iki yanında)
	for sx in [-1.0, 1.0]:
		var gx = sx * 10.0; var gn = 4.0
		var gy = _g(p, base, gx, gn)
		b.box(Vector3(gx, gy + 0.4, gn), Vector3(2.4, 0.8, 2.4), rock.darkened(0.1))
		b.sphere(Vector3(gx, gy + 2.3, gn), Vector3(2.0, 3.2, 1.6), rock.lightened(0.05), 10, true)       # gövde
		for ex in [-1.0, 1.0]:
			b.sphere(Vector3(gx + ex * 1.05, gy + 2.5, gn - 0.2), Vector3(0.7, 2.2, 0.8), rock, 8)        # kollar
		b.cyl(Vector3(gx, gy + 3.95, gn), 0.9, 0.2, rock.darkened(0.2), false, 8)                          # kırık boyun
		b.sphere(Vector3(gx + sx * 1.6, gy + 0.45, gn - 1.6), Vector3(1.0, 0.9, 1.0), rock.lightened(0.02), 8, true)   # düşmüş baş
		b.sphere(Vector3(gx, gy + 3.2, gn + 0.3), Vector3(1.6, 0.4, 1.2), moss, 6)
	# ---- yedi kılıçlı askı + ritim davulları + kafiye defteri (sol önde)
	var rx2 = -8.0; var rn2 = -3.0
	var ry2 = _g(p, base, rx2, rn2)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(rx2 + sx * 2.2, ry2 + 0.9, rn2), Vector3(0.16, 1.8, 0.16), wood)
	b.box(Vector3(rx2, ry2 + 1.7, rn2), Vector3(4.6, 0.12, 0.16), wood)
	for k in 7:
		b.box(Vector3(rx2 - 1.8 + k * 0.6, ry2 + 1.0, rn2), Vector3(0.07, 1.3, 0.03), Color(0.78, 0.8, 0.85), 0.0, false, Vector3(0, 0, 4.0))
		b.box(Vector3(rx2 - 1.8 + k * 0.6, ry2 + 1.72, rn2), Vector3(0.09, 0.3, 0.06), Color(0.15, 0.12, 0.12), 0.0, false)
	for k in 3:
		var dx = 6.5 + k * 1.9; var dn = -3.0
		var dy = _g(p, base, dx, dn)
		b.cyl(Vector3(dx, dy + 0.5, dn), 1.3, 1.0, Color(0.55, 0.2, 0.18), true, 12)
		b.cyl(Vector3(dx, dy + 1.02, dn), 1.25, 0.05, Color(0.9, 0.86, 0.75), false, 12)
	b.box(Vector3(5.0, _g(p, base, 5, -3) + 0.5, -3.0), Vector3(0.7, 1.0, 0.5), wood)                     # rahle
	b.box(Vector3(5.0, _g(p, base, 5, -3) + 1.04, -3.0), Vector3(0.6, 0.05, 0.42), Color(0.92, 0.9, 0.8), 0.0, false, Vector3(-14.0, 0, 0))
	var posts: Array = []
	for k in 3:
		posts.append(_straw(b, p, base, -3.0 + k * 3.0, -11.0))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -5), -5))
	b.lantern(-3.0, 3.6)
	b.lantern(3.0, 3.6)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(5.0, _g(p, base, 5, -1.6) + 0.05, -1.6), PI)
	b.interact(Vector3(5.0, _g(p, base, 5, -4.4), -4.4), 5.0, "path_mentor", "[F] Ritim Ustası ile konuş", {"path": pid})
	return -1.0


## Yıkık Kök Karakolu (Mürekkep Yolu, Ateş Ülkesi ormanı): yarısı çökmüş beton sığınak (kök armalı), çizim masaları ve açık parşömenler,
## iplere asılı mürekkep canavar resimleri, mürekkep küpleri, yere saplı dev fırça.
static func _ink(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var conc = Color(0.46, 0.46, 0.44)
	var ink = Color(0.05, 0.05, 0.07)
	var paper = Color(0.93, 0.91, 0.84)
	var wood = Color(0.33, 0.24, 0.17)
	var spots: Dictionary = {}
	_dirt(b, 12.0, -15.0, 8.0)
	# ---- yıkık sığınak (arka): kalın duvarlar, yarısı çökmüş çatı, moloz
	var by = maxf(_g(p, base, -6, 15), _g(p, base, 6, 15))
	b.box(Vector3(0, by + 0.2, 15), Vector3(18, 0.4, 9), conc.darkened(0.2))
	b.box(Vector3(0, by + 2.2, 19.2), Vector3(18, 4.0, 0.8), conc)
	b.box(Vector3(-8.6, by + 2.2, 15), Vector3(0.8, 4.0, 9), conc.darkened(0.05))
	b.box(Vector3(8.6, by + 1.2, 16.5), Vector3(0.8, 2.0, 6), conc.darkened(0.08))                    # yıkık yan duvar
	b.box(Vector3(-6.0, by + 2.2, 10.8), Vector3(5.0, 4.0, 0.8), conc.lightened(0.03))
	b.box(Vector3(-3.8, by + 4.4, 15), Vector3(10.4, 0.6, 9.4), conc.darkened(0.15))                  # ayakta kalan çatı
	b.box(Vector3(4.6, by + 2.1, 14.6), Vector3(7.4, 0.6, 6.0), conc.darkened(0.18), 0.15, true, Vector3(0, 0, -32.0))   # çökmüş çatı levhası
	for k in 7:
		b.boulder(Vector3(3.0 + fmod(k * 2.3, 6.0), by + 0.5, 10.0 + fmod(k * 1.7, 4.0)), Vector3(1.4, 0.9, 1.2), conc.darkened(0.05 * (k % 3)), k, false)
	b.kanji(Vector3(-6.0, by + 3.0, 10.35), "根", 1.5, ink, 0.0)
	light(b, b.w(Vector3(-4.0, by + 3.2, 15)), Color(0.75, 0.8, 0.95), 1.0, 9.0)
	# ---- çizim masaları (içeride, çatı altında): alçak masa, açık parşömen, mürekkep taşı, fırçalık
	var desks: Array = []
	for k in 3:
		var dx = -6.6 + k * 2.6; var dn = 15.8
		b.box(Vector3(dx, by + 0.75, dn), Vector3(1.8, 0.1, 1.0), wood)
		for q in 4:
			b.box(Vector3(dx + (0.8 if q % 2 else -0.8), by + 0.55, dn + (0.4 if q < 2 else -0.4)), Vector3(0.1, 0.35, 0.1), wood.darkened(0.2), 0.0, false)
		b.box(Vector3(dx, by + 0.81, dn), Vector3(1.3, 0.02, 0.7), paper, 0.0, false)
		b.box(Vector3(dx - 0.2 + k * 0.1, by + 0.83, dn), Vector3(0.6, 0.02, 0.36), ink, 0.3 * k, false)       # yarım çizim
		b.cyl(Vector3(dx + 0.7, by + 0.9, dn + 0.3), 0.14, 0.2, Color(0.5, 0.35, 0.2), false, 6)
		desks.append(b.w(Vector3(dx, by + 0.4, dn - 1.3)))
	spots["desks"] = desks
	# ---- iplere asılı canavar resimleri (avluda, iki direk arasında iki sıra)
	for row in 2:
		var hn = 6.0 - row * 4.5
		var hy = _g(p, base, 0, hn)
		for sx in [-1.0, 1.0]:
			b.cyl(Vector3(sx * 9.0, hy + 2.2, hn), 0.2, 4.4, wood, true, 6)
		rod(b, Vector3(-9.0, hy + 4.2, hn), Vector3(9.0, hy + 4.2, hn), 0.05, Color(0.2, 0.18, 0.15), 4)
		for k in 6:
			var sx3 = -7.5 + k * 3.0
			b.box(Vector3(sx3, hy + 3.0, hn), Vector3(1.6, 2.3, 0.04), paper, 0.0, false)
			b.kanji(Vector3(sx3, hy + 3.1, hn - 0.05), ["虎", "鳥", "龍", "獅", "蛇", "鼠"][(k + row * 3) % 6], 1.25, ink, 0.0)   # fırça yazısı: canavarın adı
			b.box(Vector3(sx3, hy + 4.18, hn), Vector3(1.7, 0.08, 0.08), wood, 0.0, false)
			b.box(Vector3(sx3, hy + 1.84, hn), Vector3(1.7, 0.08, 0.08), wood, 0.0, false)
	# ---- mürekkep küpleri ve dev fırça (sağda)
	for k in 4:
		var vx = 9.5 + (k % 2) * 1.8; var vn = -1.0 + (k / 2) * 2.0
		var vy = _g(p, base, vx, vn)
		b.cyl(Vector3(vx, vy + 0.6, vn), 1.4, 1.2, Color(0.28, 0.22, 0.18), true, 12)
		b.cyl(Vector3(vx, vy + 1.22, vn), 1.2, 0.05, ink, false, 12)
	var fx = -10.5; var fn = 1.0
	var fyy = _g(p, base, fx, fn)
	rod(b, Vector3(fx, fyy + 0.9, fn), Vector3(fx + 1.2, fyy + 5.2, fn + 0.3), 0.3, wood.lightened(0.2), 8)
	b.cone(Vector3(fx - 0.12, fyy + 0.5, fn - 0.03), 0.6, 1.2, ink, 8)
	b.sphere(Vector3(fx - 0.3, fyy + 0.04, fn), Vector3(2.4, 0.06, 1.8), ink, 10)                        # mürekkep lekesi
	var posts: Array = []
	for k in 3:
		posts.append(_straw(b, p, base, -3.0 + k * 3.0, -11.0, Color(0.8, 0.78, 0.7)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -5), -5))
	b.lantern(-2.4, 9.6)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(0.6, by + 0.45, 12.4), PI)
	b.interact(Vector3(0.6, by + 0.2, 10.4), 5.5, "path_mentor", "[F] Mürekkep Ustası ile konuş", {"path": pid})
	return 8.5


## Askıdaki kukla: gövde, baş, sarkan kollar ve bacaklar, chakra ipleri
static func _hung_puppet(b: Builder, at: Vector3, col: Color, cloak: Color) -> void:
	b.box(at + Vector3(0, -0.9, 0), Vector3(0.6, 0.9, 0.36), cloak, 0.0, false)
	b.sphere(at + Vector3(0, -0.2, 0), Vector3(0.42, 0.46, 0.4), col, 8)
	b.box(at + Vector3(0, -0.3, -0.2), Vector3(0.26, 0.05, 0.04), Color(0.2, 0.12, 0.1), 0.0, false)     # ağız yarığı
	for sx in [-1.0, 1.0]:
		b.box(at + Vector3(sx * 0.42, -1.0, 0), Vector3(0.12, 0.9, 0.12), col.darkened(0.1), 0.0, false, Vector3(0, 0, 10.0 * sx))
		b.box(at + Vector3(sx * 0.16, -1.85, 0), Vector3(0.14, 1.0, 0.14), col.darkened(0.15), 0.0, false)
		b.cyl(at + Vector3(sx * 0.14, 0.35, 0), 0.02, 0.7, Color(0.6, 0.8, 1.0), false, 4)


## Kızıl Kum Atölyesi (Akasuna Kukla Yolu, Rüzgâr Ülkesi): kumtaşı kubbeli atölye, tentenin altında askıda kuklalar, parça tezgâhları
## (kollar, başlar, zehir iğneleri), mor zehir kazanları, akrep kuyruğu parçası.
static func _puppet(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var sand = Color(0.82, 0.68, 0.48)
	var wood = Color(0.5, 0.36, 0.24)
	var pup = Color(0.62, 0.48, 0.34)
	var red = Color(0.55, 0.14, 0.12)
	var spots: Dictionary = {}
	# ---- kumtaşı kubbeli atölye (arka): silindir gövde, kubbe, kemerli kapı, yuvarlak pencereler
	var wy = maxf(_g(p, base, -5, 15), _g(p, base, 5, 15))
	b.cyl(Vector3(0, wy + 2.4, 16.0), 12.0, 4.8, sand, true, 16)
	b.sphere(Vector3(0, wy + 4.6, 16.0), Vector3(12.0, 6.4, 12.0), sand.lightened(0.05), 16)
	b.box(Vector3(0, wy + 1.5, 10.1), Vector3(2.4, 3.0, 0.5), Color(0.18, 0.13, 0.1), 0.0, false)        # kapı
	b.box(Vector3(0, wy + 3.15, 10.0), Vector3(3.0, 0.4, 0.6), sand.darkened(0.15), 0.0, false)
	for sx in [-1.0, 1.0]:
		b.sphere(Vector3(sx * 3.6, wy + 3.0, 10.95), Vector3(1.0, 1.0, 0.5), Color(0.15, 0.12, 0.1), 8)
	b.kanji(Vector3(0, wy + 4.3, 10.3), "傀", 1.0, red, 0.0)
	# ---- tente + askıdaki kuklalar (kapının iki yanında)
	for sx in [-1.0, 1.0]:
		var tx = sx * 7.5; var tn = 7.0
		var ty = _g(p, base, tx, tn)
		for q in 4:
			b.box(Vector3(tx + (2.6 if q % 2 else -2.6), ty + 1.9, tn + (1.6 if q < 2 else -1.6)), Vector3(0.2, 3.8, 0.2), wood)
		b.box(Vector3(tx, ty + 3.8, tn), Vector3(6.0, 0.08, 4.0), red, 0.0, false, Vector3(-5.0, 0, 0))
		b.box(Vector3(tx, ty + 3.5, tn), Vector3(5.2, 0.12, 0.12), wood, 0.0, false)
		for k in 3:
			_hung_puppet(b, Vector3(tx - 1.7 + k * 1.7, ty + 3.2, tn), pup.lightened(0.06 * k), [Color(0.2, 0.18, 0.2), red.darkened(0.2), Color(0.3, 0.26, 0.2)][k])
	# ---- parça tezgâhları (ortada üç tezgâh): kollar, başlar, iğne demetleri
	var benches: Array = []
	for k in 3:
		var bx = -5.0 + k * 5.0; var bn = 1.5
		var byy = _g(p, base, bx, bn)
		b.box(Vector3(bx, byy + 0.85, bn), Vector3(2.6, 0.12, 1.2), wood)
		for q in 4:
			b.box(Vector3(bx + (1.15 if q % 2 else -1.15), byy + 0.42, bn + (0.45 if q < 2 else -0.45)), Vector3(0.12, 0.85, 0.12), wood.darkened(0.2), 0.0, false)
		b.box(Vector3(bx - 0.6, byy + 0.98, bn), Vector3(0.9, 0.13, 0.13), pup, 0.3, false)                # kol
		b.sphere(Vector3(bx - 1.1, byy + 0.99, bn + 0.12), Vector3(0.18, 0.16, 0.2), pup.darkened(0.1), 6)
		b.sphere(Vector3(bx + 0.5, byy + 1.1, bn), Vector3(0.4, 0.42, 0.38), pup.lightened(0.05), 8)       # baş
		for j in 5:
			b.box(Vector3(bx + 0.95, byy + 0.94, bn - 0.3 + j * 0.08), Vector3(0.5, 0.015, 0.015), Color(0.75, 0.77, 0.8), 0.0, false)   # senbon
		benches.append(b.w(Vector3(bx, byy, bn - 1.5)))
	spots["benches"] = benches
	# ---- zehir kazanları (solda) + akrep kuyruğu (sağda)
	for k in 3:
		var cx = -11.5; var cn = -4.0 + k * 2.6
		var cy = _g(p, base, cx, cn)
		b.cyl(Vector3(cx, cy + 0.5, cn), 1.5, 1.0, Color(0.2, 0.2, 0.22), true, 12)
		b.cyl(Vector3(cx, cy + 1.02, cn), 1.3, 0.05, Color(0.55, 0.2, 0.7), false, 12)
	light(b, b.w(Vector3(-11.5, _g(p, base, -11.5, -1.4) + 1.6, -1.4)), Color(0.7, 0.3, 0.9), 1.2, 7.0)
	var sx4 = 11.0; var sn4 = -2.0
	var sy4 = _g(p, base, sx4, sn4)
	for k in 8:   # boğumlu kuyruk yukarı kıvrılır
		var u = k / 7.0
		b.sphere(Vector3(sx4, sy4 + 0.4 + sin(u * 2.4) * 2.6, sn4 - 2.0 + u * 3.4 - sin(u * 3.0) * 0.9), Vector3(1.25, 1.1, 1.3) * lerpf(1.0, 0.55, u), Color(0.3, 0.26, 0.24), 8, k == 0)
	b.cone(Vector3(sx4, sy4 + 2.3, sn4 + 0.3), 0.3, 0.9, Color(0.7, 0.72, 0.76), 6)
	var posts: Array = []
	for k in 4:
		var px = -4.5 + k * 3.0; var pn = -11.0
		var pyy = _g(p, base, px, pn)
		b.box(Vector3(px, pyy + 1.0, pn), Vector3(0.18, 2.0, 0.18), wood)
		b.sphere(Vector3(px, pyy + 1.9, pn + 0.12), Vector3(1.4, 1.4, 0.14), Color(0.9, 0.86, 0.75), 14)
		b.sphere(Vector3(px, pyy + 1.9, pn + 0.2), Vector3(0.7, 0.7, 0.1), red, 12)
		posts.append(b.w(Vector3(px, pyy, pn)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -5), -5))
	b.lantern(-3.0, 8.6)
	b.lantern(3.0, 8.6)
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(0, _g(p, base, 0, 8.4) + 0.05, 8.4), PI)
	b.interact(Vector3(0, _g(p, base, 0, 6.6), 6.6), 5.5, "path_mentor", "[F] Kukla Ustası ile konuş", {"path": pid})
	return 6.0


## Kâğıt Çiçek Kulesi (Kâğıt Yolu, Yağmur Ülkesi): Amegakure tarzı koyu metal 4 katlı kule (dış borular, 0.9 m kat çıkıntıları:
## çift zıplamayla kat kat tepeye çıkılır), tepede dev beyaz kâğıt çiçek; ıslak taş avlu, iplere asılı origami turnalar,
## kâğıt fenerler, katlama masaları (kâğıt yığınları), kâğıt mızrak kuklaları. Antrenman noktaları LegendPaths.drill_spots'a.
static func _paper(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var metal = Color(0.3, 0.31, 0.34)
	var metal_d = Color(0.2, 0.21, 0.24)
	var pipe = Color(0.4, 0.38, 0.36)
	var paper = Color(0.96, 0.95, 0.92)
	var wood = Color(0.38, 0.27, 0.18)
	var spots: Dictionary = {}
	var gy = _g(p, base, 0, 8)
	var RM = preload("res://scripts/world/road_map.gd")
	for k in 9:
		var zz = -16.0 + k * 4.0
		var wa = b.w(Vector3(-17.0, 0, zz)); var wb = b.w(Vector3(17.0, 0, zz))
		RM.add_lane(Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), 2.4, true)
	# ---- kule: 4 kat, her kat 0.9 m içeri çekilir (çıkıntı), her katın üstüne dış rampa
	var TX = 0.0; var TN = 10.0
	var w = 9.0
	var y = gy
	var tiers = [4.6, 4.4, 4.2, 4.0]
	for i in tiers.size():
		var h: float = tiers[i]
		b.box(Vector3(TX, y + h * 0.5, TN), Vector3(w, h, w), metal if i % 2 == 0 else metal.darkened(0.08))
		b.box(Vector3(TX, y + h + 0.1, TN), Vector3(w + 0.4, 0.2, w + 0.4), metal_d, 0.0, false)   # kat saçağı: görsel (çarpışmalı olunca tırmanırken kafa çarpıyordu)
		for sx in [-1.0, 1.0]:   # dış borular
			b.cyl(Vector3(TX + sx * (w * 0.5 + 0.12), y + h * 0.5, TN - w * 0.3), 0.22, h, pipe, false, 8)
			b.cyl(Vector3(TX + sx * (w * 0.5 + 0.12), y + h * 0.5, TN + w * 0.3), 0.22, h, pipe, false, 8)
		for k in 3:   # karanlık pencereler + yeşilimsi ışık
			b.box(Vector3(TX - w * 0.3 + k * w * 0.3, y + h * 0.6, TN - w * 0.5 - 0.02), Vector3(0.7, 0.9, 0.05), Color(0.55, 0.75, 0.6), 0.0, false)
		# katlar 4-4.6 m, çıkıntılar 0.9 m: çift zıplamayla (~6.5 m) kat kat tepeye çıkılır (ninja parkuru; rampa yok)
		y += h
		w -= 1.8
	# tepe platformu + korkuluk + dev kâğıt çiçek
	var top_y = y - 0.13   # platform üstü = en üst kat tavanı (+0.02): korkuluk/çiçek havada kalmasın
	b.box(Vector3(TX, top_y, TN), Vector3(w + 3.0, 0.3, w + 3.0), metal_d, 0.0, false)   # görsel; zemin en üst katın tavanı (saçak gibi kafa çarpmasın)
	for k in 16:
		var a = TAU * k / 16.0
		b.cyl(Vector3(TX + cos(a) * (w * 0.5 + 1.3), top_y + 0.6, TN + sin(a) * (w * 0.5 + 1.3)), 0.08, 1.0, metal, false, 5)
	for k in 8:   # taç yapraklar (iki halka), ortada sarı göbek
		var a2 = TAU * k / 8.0
		b.sphere(Vector3(TX + cos(a2) * 1.2, top_y + 1.4, TN + sin(a2) * 1.2), Vector3(1.6, 0.25, 0.9), paper, 8)
		var a3 = a2 + PI / 8.0
		b.sphere(Vector3(TX + cos(a3) * 0.8, top_y + 1.8, TN + sin(a3) * 0.8), Vector3(1.0, 0.3, 0.6), paper.darkened(0.04), 8)
	b.sphere(Vector3(TX, top_y + 1.9, TN), Vector3(0.6, 0.4, 0.6), Color(0.95, 0.85, 0.5), 8)
	b.cyl(Vector3(TX, top_y + 0.8, TN), 0.25, 1.2, Color(0.35, 0.55, 0.35), false, 6)   # sap
	spots["top"] = [b.w(Vector3(TX + w * 0.5 + 0.6, top_y + 0.15, TN))]
	spots["tower"] = b.w(Vector3(TX, gy, TN))
	# ---- avlu: ıslak taş levhalar (parlak su birikintileri), kâğıt fenerler
	for k in 14:
		var px = randf_range(-12, 12); var pn = randf_range(-14, 2)
		var py = _g(p, base, px, pn)
		b.box(Vector3(px, py + 0.02, pn), Vector3(randf_range(1.0, 2.4), 0.02, randf_range(0.8, 1.8)), Color(0.35, 0.42, 0.5), randf() * 90.0, false)
	for sx in [-1.0, 1.0]:
		for k in 3:
			b.lantern(sx * 6.0, -2.0 - k * 5.0)
	# iplere asılı origami turnalar (giriş yolu üstünde)
	for r in 2:
		var ry = _g(p, base, 0, -6.0 - r * 6.0) + 4.2
		var zz = -6.0 - r * 6.0
		b.box(Vector3(-5.0, ry - 2.1, zz), Vector3(0.15, 4.2, 0.15), metal_d)
		b.box(Vector3(5.0, ry - 2.1, zz), Vector3(0.15, 4.2, 0.15), metal_d)
		b.box(Vector3(0, ry, zz), Vector3(10.0, 0.04, 0.04), Color(0.2, 0.2, 0.2), 0.0, false)
		for k in 9:
			var cx = -4.0 + k * 1.0
			var cl = 0.6 + (k % 3) * 0.35
			b.box(Vector3(cx, ry - cl * 0.5, zz), Vector3(0.01, cl, 0.01), Color(0.9, 0.9, 0.9), 0.0, false)
			var ccol = [paper, Color(0.85, 0.3, 0.3), Color(0.55, 0.45, 0.8)][k % 3]
			b.box(Vector3(cx, ry - cl - 0.05, zz), Vector3(0.28, 0.04, 0.12), ccol, 35.0, false)   # kanatlar
			b.box(Vector3(cx, ry - cl, zz), Vector3(0.06, 0.12, 0.3), ccol, 0.0, false)        # gövde
	# ---- katlama masaları (Kami Bunshin): alçak masa + kâğıt yığını + yarım katlanmış figür, önünde minder
	var mats: Array = []
	for k in 3:
		var mx = -10.0 + k * 3.2; var mn = 2.0
		var my = _g(p, base, mx, mn)
		b.box(Vector3(mx, my + 0.35, mn), Vector3(1.6, 0.08, 0.9), wood)
		for q in 4:
			b.box(Vector3(mx + (0.7 if q % 2 else -0.7), my + 0.16, mn + (0.35 if q < 2 else -0.35)), Vector3(0.08, 0.32, 0.08), wood.darkened(0.2), 0.0, false)
		for h2 in 5:
			b.box(Vector3(mx - 0.4, my + 0.42 + h2 * 0.012, mn), Vector3(0.5, 0.01, 0.38), paper.darkened(0.02 * h2), 0.0, false)
		b.box(Vector3(mx + 0.35, my + 0.5, mn), Vector3(0.22, 0.25, 0.08), paper, 0.0, false)   # katlanan figür
		b.sphere(Vector3(mx + 0.35, my + 0.68, mn), Vector3(0.12, 0.12, 0.08), paper, 6)
		b.box(Vector3(mx, my + 0.04, mn - 1.0), Vector3(0.9, 0.08, 0.7), Color(0.3, 0.3, 0.45), 0.0, false)   # minder
		mats.append(b.w(Vector3(mx, my, mn - 1.0)))
	spots["mats"] = mats
	# ---- kâğıt mızrak kuklaları
	var posts: Array = []
	for k in 3:
		var dx = 9.0 + k * 3.0; var dn = -10.0
		var dy = _g(p, base, dx, dn)
		b.box(Vector3(dx, dy + 0.9, dn), Vector3(0.18, 1.8, 0.18), wood)
		b.cyl(Vector3(dx, dy + 1.5, dn), 0.6, 1.0, paper.darkened(0.15), false, 10)
		b.sphere(Vector3(dx, dy + 2.3, dn), Vector3(0.5, 0.5, 0.5), paper.darkened(0.1))
		posts.append(b.w(Vector3(dx, dy, dn)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -6), -6))
	LegendPaths.drill_spots[pid] = spots
	LegendPaths._mentor(b, pid, Vector3(0, gy + 0.05, TN - 6.0), PI)
	b.interact(Vector3(0, gy, TN - 7.5), 5.5, "path_mentor", "[F] Kâğıt Ustası ile konuş", {"path": pid})
	return 5.0


## Yuge Şifa Tapınağı (Şifacı Yolu): yeşil kiremitli açık cepheli tapınak (ilaç rafları, muayene sedi), iki yanda buharı tüten
## şifa havuzları (yürünebilir su), solda beyaz tenteli yaralı koğuşu (sedirlerde yatan hastalar), sağda balık leğenleri (kanon:
## Mistik Avuç ölmek üzere olan balıkla çalışılır), önde şifalı ot tarhları + kurutma askısı, yanda chakra neşteri kuklaları.
## Antrenman noktaları LegendPaths.drill_spots'a yazılır.
static func _clinic(b: Builder, pid: String, p: Vector2, base: float) -> float:
	var wood = Color(0.46, 0.32, 0.2)
	var dark = Color(0.26, 0.18, 0.11)
	var plaster = Color(0.95, 0.94, 0.9)
	var stone = Color(0.56, 0.55, 0.52)
	var green_t = Color(0.2, 0.45, 0.33)
	var cloth = Color(0.95, 0.95, 0.92)
	var skin = Color(0.93, 0.78, 0.64)
	var spots: Dictionary = {}
	var fy = maxf(_g(p, base, -8, 14), _g(p, base, 8, 14))
	# avlu: toprak (otsuz)
	var RM = preload("res://scripts/world/road_map.gd")
	for k in 8:
		var zz = -16.0 + k * 4.0
		var wa = b.w(Vector3(-17.0, 0, zz)); var wb = b.w(Vector3(17.0, 0, zz))
		RM.add_lane(Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), 2.4, true)
	# ---- tapınak (kuzey): taş kaide, ahşap zemin, açık ön cephe, yeşil çatı, "癒" levhası
	b.box(Vector3(0, fy + 0.4, 14), Vector3(16, 0.8, 10), stone)
	b.box(Vector3(0, fy + 0.84, 14), Vector3(15.4, 0.1, 9.4), Color(0.66, 0.5, 0.32))
	for k in 3:
		b.box(Vector3(0, fy + 0.62 - k * 0.2, 8.6 - k * 0.42), Vector3(5.0, 0.2, 0.45), wood)
	for x in [-7.4, -2.5, 2.5, 7.4]:
		b.box(Vector3(x, fy + 3.0, 9.4), Vector3(0.42, 4.2, 0.42), dark)
	b.box(Vector3(0, fy + 3.0, 18.8), Vector3(15.4, 4.2, 0.32), plaster)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(7.6 * sx, fy + 3.0, 14), Vector3(0.32, 4.2, 9.4), plaster)
	b.box(Vector3(0, fy + 5.1, 9.4), Vector3(15.8, 0.4, 0.45), dark)
	b.roof(Vector3(0, fy + 5.3, 14), Vector3(18.0, 3.0, 12.4), green_t)
	b.kanji(Vector3(0, fy + 4.4, 9.1), "癒", 1.4, Color(0.95, 0.9, 0.7), 180.0)
	# ilaç rafları (arka duvar): raflar + yeşil/amber kavanozlar
	for sx in [-1.0, 1.0]:
		var rx = 4.5 * sx
		b.box(Vector3(rx, fy + 2.0, 18.3), Vector3(4.6, 2.4, 0.5), wood)
		for r in 3:
			b.box(Vector3(rx, fy + 1.15 + r * 0.75, 18.0), Vector3(4.4, 0.06, 0.45), dark, 0.0, false)
			for q in 6:
				var jc = [Color(0.45, 0.8, 0.55), Color(0.85, 0.65, 0.3), Color(0.6, 0.75, 0.85)][(q + r) % 3]
				b.cyl(Vector3(rx - 1.8 + q * 0.72, fy + 1.4 + r * 0.75, 17.95), 0.32, 0.42, jc, false, 8)
	# muayene sedi + ot havanı
	b.box(Vector3(-2.0, fy + 1.3, 13.5), Vector3(2.2, 0.15, 1.0), cloth)
	for q in 4:
		b.box(Vector3(-2.0 + (0.95 if q % 2 else -0.95), fy + 1.08, 13.5 + (0.38 if q < 2 else -0.38)), Vector3(0.1, 0.42, 0.1), dark, 0.0, false)
	b.cyl(Vector3(2.5, fy + 1.1, 13.0), 0.5, 0.4, stone.darkened(0.2), false, 10)
	light(b, b.w(Vector3(0, fy + 4.0, 14.0)), Color(1.0, 0.9, 0.7), 1.4, 12.0)
	# içeride: iki yanda hasta sedirleri, tavandan sarkan fenerler, duvarda "医" parşömeni
	for sx in [-1.0, 1.0]:
		var ix = 5.6 * sx
		b.box(Vector3(ix, fy + 1.3, 12.5), Vector3(1.0, 0.1, 2.2), wood)
		for q in 4:
			b.box(Vector3(ix + (0.42 if q % 2 else -0.42), fy + 1.08, 12.5 + (0.95 if q < 2 else -0.95)), Vector3(0.08, 0.42, 0.08), dark, 0.0, false)
		b.box(Vector3(ix, fy + 1.4, 12.5), Vector3(0.9, 0.1, 2.05), cloth)
		b.sphere(Vector3(ix, fy + 1.56, 12.2), Vector3(0.62, 0.32, 1.3), Color(0.55, 0.62, 0.55), 8)
		b.sphere(Vector3(ix, fy + 1.58, 13.3), Vector3(0.3, 0.28, 0.32), skin, 8)
		b.box(Vector3(ix * 0.6, fy + 4.2, 13.0), Vector3(0.03, 0.6, 0.03), dark, 0.0, false)
		b.sphere(Vector3(ix * 0.6, fy + 3.75, 13.0), Vector3(0.5, 0.6, 0.5), Color(1.0, 0.92, 0.75), 8)
	b.box(Vector3(0, fy + 3.0, 18.6), Vector3(1.4, 2.2, 0.04), Color(0.96, 0.94, 0.86), 0.0, false)
	b.kanji(Vector3(0, fy + 3.0, 18.55), "医", 0.9, Color(0.12, 0.1, 0.1), 180.0)
	# ---- şifa havuzları (iki yanda): kaya halka + yürünebilir su + buhar
	for sx in [-1.0, 1.0]:
		var hx = 12.5 * sx; var hn = 9.0
		var hy = _g(p, base, hx, hn)
		for k in 14:
			var a = TAU * k / 14.0
			b.boulder(Vector3(hx + cos(a) * 3.4, hy + 0.3, hn + sin(a) * 2.8), Vector3(1.2, 0.8, 1.0), stone.darkened(0.08 * (k % 3)), k, true)
		VillageStyles.water(b, Vector3(hx, hy + 0.35, hn), Vector2(6.2, 5.0))
		Steam.add(b.w(Vector3(hx, hy + 0.6, hn)))
	# ---- yaralı koğuşu (sol önde): direkler + beyaz tente + 4 sedir, her sedirde yatan hasta
	var wx = -11.0; var wn = -6.0
	var wy = _g(p, base, wx, wn)
	for q in 6:
		b.box(Vector3(wx - 4.0 + (q % 3) * 4.0, wy + 1.6, wn + (2.6 if q < 3 else -2.6)), Vector3(0.16, 3.2, 0.16), dark)
	b.box(Vector3(wx, wy + 3.2, wn), Vector3(8.6, 0.06, 5.8), cloth, 0.0, false)
	b.box(Vector3(wx, wy + 3.0, wn + 2.9), Vector3(8.6, 0.4, 0.04), Color(0.3, 0.6, 0.4), 0.0, false)   # yeşil saçak
	var pats: Array = []
	for k in 4:
		var cx = wx - 3.0 + k * 2.0
		var cy = _g(p, base, cx, wn)
		b.box(Vector3(cx, cy + 0.45, wn), Vector3(1.0, 0.1, 2.2), wood)                 # sedir
		for q in 4:
			b.box(Vector3(cx + (0.42 if q % 2 else -0.42), cy + 0.2, wn + (0.95 if q < 2 else -0.95)), Vector3(0.08, 0.4, 0.08), dark, 0.0, false)
		b.box(Vector3(cx, cy + 0.56, wn), Vector3(0.9, 0.1, 2.05), cloth)                 # şilte
		b.sphere(Vector3(cx, cy + 0.72, wn - 0.3), Vector3(0.62, 0.32, 1.3), [Color(0.55, 0.6, 0.7), Color(0.6, 0.5, 0.45), Color(0.5, 0.58, 0.5)][k % 3], 8)   # battaniyeli beden
		b.sphere(Vector3(cx, cy + 0.74, wn + 0.78), Vector3(0.3, 0.28, 0.32), skin, 8)    # baş
		b.box(Vector3(cx, cy + 0.8, wn + 0.78), Vector3(0.32, 0.07, 0.34), cloth, 0.0, false)   # alın sargısı
		pats.append(b.w(Vector3(cx + 0.9, cy, wn)))
	spots["patients"] = pats
	# ---- balık leğenleri (sağ önde): ahşap leğen + su + yan yatmış balık
	var basins: Array = []
	for k in 3:
		var bxx = 8.0 + k * 3.0; var bnn = -6.0
		var by = _g(p, base, bxx, bnn)
		b.cyl(Vector3(bxx, by + 0.4, bnn), 1.4, 0.8, wood.darkened(0.1), true, 12)
		b.cyl(Vector3(bxx, by + 0.79, bnn), 1.2, 0.04, Color(0.25, 0.45, 0.6), false, 12)
		b.sphere(Vector3(bxx, by + 0.83, bnn), Vector3(0.55, 0.12, 0.2), Color(0.75, 0.75, 0.8), 6)   # balık
		b.cone(Vector3(bxx + 0.33, by + 0.83, bnn), 0.14, 0.2, Color(0.7, 0.7, 0.76))
		basins.append(b.w(Vector3(bxx, by, bnn - 1.3)))
	spots["basins"] = basins
	# ---- şifalı ot tarhları + kurutma askısı (önde ortada)
	for r in 3:
		for k in 8:
			var gx = -4.2 + k * 1.2; var gn = -12.0 - r * 1.6
			var gy = _g(p, base, gx, gn)
			b.sphere(Vector3(gx, gy + 0.3, gn), Vector3(0.7, 0.55, 0.7), [Color(0.3, 0.6, 0.3), Color(0.4, 0.62, 0.32), Color(0.35, 0.55, 0.4)][(k + r) % 3], 6)
	var rgy = _g(p, base, 0, -17.5)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(3.0 * sx, rgy + 1.2, -17.5), Vector3(0.12, 2.4, 0.12), dark)
	b.box(Vector3(0, rgy + 2.3, -17.5), Vector3(6.2, 0.08, 0.08), dark, 0.0, false)
	for k in 9:
		b.box(Vector3(-2.6 + k * 0.65, rgy + 1.95, -17.5), Vector3(0.18, 0.6, 0.06), Color(0.45, 0.55, 0.3).darkened((k % 3) * 0.1), 0.0, false)
	# ---- chakra neşteri kuklaları (sağ arka)
	var posts: Array = []
	for k in 3:
		var dx = 10.0 + k * 3.0; var dn = -14.0
		var dy = _g(p, base, dx, dn)
		b.box(Vector3(dx, dy + 0.9, dn), Vector3(0.18, 1.8, 0.18), wood)
		b.cyl(Vector3(dx, dy + 1.5, dn), 0.6, 1.0, Color(0.85, 0.78, 0.6), false, 10)
		b.sphere(Vector3(dx, dy + 2.3, dn), Vector3(0.5, 0.5, 0.5), Color(0.88, 0.8, 0.62))
		posts.append(b.w(Vector3(dx, dy, dn)))
	spots["posts"] = posts
	spots["center"] = b.w(Vector3(0, _g(p, base, 0, -4), -4))
	LegendPaths.drill_spots[pid] = spots
	b.lantern(-4.0, 6.0)
	b.lantern(4.0, 6.0)
	LegendPaths._mentor(b, pid, Vector3(0, fy + 0.9, 12.0), PI)
	b.interact(Vector3(0, fy, 9.0), 6.0, "path_mentor", "[F] Şifacı Usta ile konuş", {"path": pid})
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
