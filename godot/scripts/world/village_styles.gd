class_name VillageStyles
extends RefCounted
## Köy mimarileri: her köyün kendine has ev tipleri (Builder ile, yerel uzay: x doğu, y yukarı, n kuzey; yaw 0 = ön güney).
## Builder.house() bu fonksiyonları stile göre çağırır; köyler (build_sites) ve mezralar (poi_builder/roadside) ortak kullanır.

const DARK := Color(0.12, 0.1, 0.09)
const WOOD := Color(0.42, 0.29, 0.18)


## ---------------------------------------------------------------- Suna (referans): kumtaşı rengi, şişkin "su kabağı" gövdeli evler; gövdeyi saran
## kalın bantlar ve bantlarda sıra sıra yuvarlak köşeli yarık pencereler; bir kısmı kat kat daralan bantlı kuleler; tepede küçük kubbe başlıklar.
static func suna_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.84, 0.68, 0.44).lerp(Color(0.78, 0.7, 0.5), rng.randf()).darkened(rng.randf_range(0.0, 0.1))
	var band = c.darkened(0.16)
	var d = minf(wdt, dep) * 0.95
	var gourd = rng.randf() < 0.55
	var top: float
	if gourd:
		# kısa taban + şişkin gövde (yassı küre) + gövdeyi saran bantlar ve yarık pencereler
		var hb = floors * 3.6 + 3.0
		b.cyl(Vector3(x, 1.2, n), d * 0.8, 2.4, c.darkened(0.06), true, 12)
		var cy = 2.2 + hb * 0.5
		b.sphere(Vector3(x, cy, n), Vector3(d, hb, d), c, 12, true)   # binlerce ev: düşük dilim (Suna 14M üçgendi)
		for k in 3:
			var t = -0.32 + k * 0.32
			var y = cy + t * hb
			var rr = d * 0.5 * sqrt(maxf(0.05, 1.0 - 4.0 * t * t)) + 0.15
			_band(b, x, n, y, rr, band, yaw, rng, k == 1)
		top = cy + hb * 0.5
		b.dome(Vector3(x, top - 0.6, n), d * 0.38, 1.4, c.lightened(0.05), 10)
	else:
		# kat kat daralan bantlı kule (her kademe silindir + bant + yarıklar)
		var tiers = clampi(floors, 2, 4)
		var y = 0.0
		var dd = d
		for t in tiers:
			var th = 4.2
			b.cyl(Vector3(x, y + th * 0.5, n), dd, th, c.lightened(0.02 * (t % 2)), true, 14)
			_band(b, x, n, y + th * 0.62, dd * 0.5 + 0.12, band, yaw, rng, true)
			b.cyl(Vector3(x, y + th, n), dd + 0.5, 0.35, band, false, 14)
			y += th
			dd *= 0.84
		top = y
		b.dome(Vector3(x, top, n), dd * 1.05, dd * 0.42, c.lightened(0.05), 12)
	# kapı (kemerli), kumaş tente, çatıda su deposu / anten
	# kapı tabanın yüzeyinde: su kabağı evde taban gövdeden dar (çap d*0.8), kule ilk kademesi tam çap
	var fo = Builder.rot(0, -(d * 0.4 if gourd else d * 0.5) + 0.02, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.0, yaw, "suna", rng)
	if rng.randf() < 0.45:
		var aw = [Color(0.75, 0.25, 0.2), Color(0.25, 0.45, 0.6), Color(0.85, 0.65, 0.25), Color(0.55, 0.35, 0.55)][rng.randi() % 4]
		var ao = Builder.rot(0, -d * 0.5 - 1.3, yaw)
		b.box(Vector3(x + ao.x, 3.4, n + ao.y), Vector3(4.2, 0.12, 2.4), aw, yaw, false, Vector3(-14, 0, 0))
	if rng.randf() < 0.4:
		b.cyl(Vector3(x, top + 1.0, n), 0.25, 2.0, DARK, false, 6)


## Suna bandı: gövdeyi saran kalın kuşak + üstünde yuvarlak köşeli yarık pencere sırası
static func _band(b: Builder, x: float, n: float, y: float, r: float, col: Color, yaw: float, rng: RandomNumberGenerator, windows: bool) -> void:
	b.cyl(Vector3(x, y, n), r * 2.0 + 0.3, 1.1, col, false, 14)
	if not windows:
		return
	var cnt = maxi(6, int(TAU * r / 2.2))
	for k in cnt:
		var a = yaw + 360.0 * k / cnt
		var o = Builder.rot(0, r + 0.18, a)
		b.box(Vector3(x + o.x, y, n + o.y), Vector3(0.95, 0.6, 0.2), DARK, a, false)


## ---------------------------------------------------------------- Kiri (referans): yüksek, pembe-gri tuğla tonlu silindir kuleler; dikey sıralı koyu yarık
## pencereler; üstte renkli (mavi / mor / pembe) geniş başlık bandı, çoğunun tepesinde yeşillik (çatı bahçesi); alçak geniş yuvarlak yapılar da var.
static func kiri_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.74, 0.64, 0.62).lerp(Color(0.68, 0.66, 0.68), rng.randf()).darkened(rng.randf_range(0.0, 0.12))
	var cap = [Color(0.32, 0.4, 0.66), Color(0.46, 0.36, 0.58), Color(0.74, 0.5, 0.58), Color(0.36, 0.5, 0.6)][rng.randi() % 4]
	var low = rng.randf() < 0.22
	var d = maxf(wdt, dep) * (1.05 if low else rng.randf_range(0.6, 0.8))
	var hgt = 5.0 if low else (floors + rng.randi_range(2, 5)) * 4.0
	b.cyl(Vector3(x, hgt * 0.5, n), d, hgt, c, true, 18)
	# tuğla dokusu izi: ince koyu yatay derzler
	var y = 1.6
	while y < hgt - 0.5:
		b.cyl(Vector3(x, y, n), d + 0.06, 0.06, c.darkened(0.14), false, 18)
		y += 1.6
	# dikey sıralı yarık pencereler
	if not low:
		var cols_n = maxi(3, int(d * 0.5))
		for k in cols_n:
			var a = yaw + 360.0 * k / cols_n + rng.randf_range(-6, 6)
			var o = Builder.rot(0, d * 0.5 + 0.05, a)
			var fy = 3.0
			while fy < hgt - 2.0:
				b.box(Vector3(x + o.x, fy, n + o.y), Vector3(1.3, 0.42, 0.2), Color(0.18, 0.16, 0.18), a, false)
				fy += 2.0
	# başlık: geniş renkli bant + üstünde yeşillik ya da kubbe
	b.cyl(Vector3(x, hgt + 0.7, n), d + 1.0, 1.4, cap, false, 18)
	b.cyl(Vector3(x, hgt + 1.45, n), d + 1.2, 0.2, cap.darkened(0.2), false, 18)
	if low:
		b.cyl(Vector3(x, hgt + 1.3, n), d * 0.9, 0.2, Color(0.82, 0.84, 0.86), false, 18)
	elif rng.randf() < 0.65:
		for k in 5:   # çatı bahçesi: çalı kümeleri
			var a = rng.randf() * TAU
			var rr = rng.randf_range(0.0, d * 0.3)
			b.sphere(Vector3(x + cos(a) * rr, hgt + 2.2 + rng.randf_range(0, 0.6), n + sin(a) * rr), Vector3(d * 0.45, d * 0.3, d * 0.45), Color(0.24, 0.44, 0.24).lightened(rng.randf_range(0, 0.1)), 8)
	else:
		b.dome(Vector3(x, hgt + 1.5, n), d + 0.4, d * 0.3, cap.lightened(0.08), 16)
	var fo = Builder.rot(0, -d * 0.5 - 0.05, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.0, yaw, "kiri", rng)


## ---------------------------------------------------------------- Iwa (referans): gri taştan kovan / basamaklı koni evler; silindir gövde, üstünde
## kademe kademe daralan halkalardan koni çatı, tepede küçük renkli başlık; bir kısmı yarık pencereli dar taş kule; evler arası teller.
static func iwa_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.56, 0.55, 0.52).lerp(Color(0.6, 0.55, 0.48), rng.randf()).darkened(rng.randf_range(0.0, 0.14))
	var capc = [Color(0.45, 0.32, 0.55), Color(0.6, 0.3, 0.22), Color(0.4, 0.42, 0.48)][rng.randi() % 3]
	var tower = rng.randf() < 0.3
	var d = maxf(wdt, dep) * (0.6 if tower else 0.95)
	var hgt = (floors + (3 if tower else 0)) * 3.8
	b.cyl(Vector3(x, hgt * 0.5, n), d, hgt, c, true, 16)
	for f in int(hgt / 3.8):
		b.cyl(Vector3(x, f * 3.8 + 3.8, n), d + 0.5, 0.3, c.darkened(0.18), false, 16)   # kat bandı
		var cnt = maxi(3, int(d * 0.45))
		for k in cnt:
			var a = yaw + 360.0 * k / cnt + f * 25.0
			var o = Builder.rot(0, d * 0.5 + 0.05, a)
			b.box(Vector3(x + o.x, f * 3.8 + 2.0, n + o.y), Vector3(0.9, 1.0, 0.2), DARK, a, false)
	# basamaklı koni çatı: daralan taş halkalar
	var rings = 5 if not tower else 3
	var y = hgt
	for k in rings:
		var rd = (d + 1.2) * (1.0 - float(k) / rings * 0.85)
		b.cyl(Vector3(x, y + 0.45, n), rd, 0.9, c.lightened(0.04 * (k % 2)) if k < rings - 1 else c, k == 0, 16)
		y += 0.9
	b.cone(Vector3(x, y + 0.7, n), d * 0.3, 1.4, capc, 10)
	var fo = Builder.rot(0, -d * 0.5 - 0.05, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.0, yaw, "iwa", rng)


## ---------------------------------------------------------------- Ame: koyu sanayi blokları, borular, ışıklı pencere ızgarası, anten
static func ame_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.36, 0.38, 0.41).darkened(rng.randf_range(0.0, 0.12))
	var fl = floors + rng.randi_range(1, 4)
	var hgt = fl * 4.0
	b.box(Vector3(x, hgt * 0.5, n), Vector3(wdt, hgt, dep), c, yaw)
	for f in fl:
		b.box(Vector3(x, f * 4.0 + 4.0, n), Vector3(wdt + 0.3, 0.25, dep + 0.3), c.darkened(0.2), yaw, false)
		var cnt = maxi(2, int(wdt / 2.4))
		for k in cnt:
			var lx = -wdt * 0.5 + (k + 0.5) * wdt / cnt
			var lit = rng.randf() < 0.3
			var o = Builder.rot(lx, -dep * 0.5 - 0.04, yaw)
			b.box(Vector3(x + o.x, f * 4.0 + 2.2, n + o.y), Vector3(0.9, 1.3, 0.15), Color(0.95, 0.8, 0.45) if lit else Color(0.14, 0.16, 0.2), yaw, false)
	for k in 2:
		var o = Builder.rot((wdt * 0.5 + 0.5) * (1 if k == 0 else -1), rng.randf_range(-dep * 0.3, dep * 0.3), yaw)
		b.cyl(Vector3(x + o.x, hgt * 0.5, n + o.y), 0.8, hgt + 2.0, Color(0.32, 0.33, 0.35), false, 8)
	b.cyl(Vector3(x, hgt + 3.0, n), 0.2, 6.0, Color(0.25, 0.25, 0.27), false, 6)
	b.box(Vector3(x, hgt + 0.6, n), Vector3(wdt * 0.5, 1.2, dep * 0.5), c.darkened(0.1), yaw, false)
	var fo = Builder.rot(0, -dep * 0.5 - 0.04, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.0, yaw, "ame", rng)


## ---------------------------------------------------------------- Kumo (referans): kaya sütunları arasında yukarı doğru genişleyen kase biçimli,
## yeşilimsi beyaz katlı yapılar (ters kesik koni kademeleri, kenarda korkuluk), bir kısmı mavi kubbeli yuvarlak kule.
static func kumo_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.66, 0.72, 0.62).lerp(Color(0.86, 0.87, 0.84), rng.randf()).darkened(rng.randf_range(0.0, 0.08))
	var blue = Color(0.22, 0.45, 0.72).lightened(rng.randf_range(-0.06, 0.08))
	var d = maxf(wdt, dep) * 0.9
	if rng.randf() < 0.55:
		# kase kademeleri: her kademe aşağıda dar, yukarıda geniş (ters kesik koni) + kenar bandı + korkuluk
		var tiers = clampi(floors, 2, 4)
		var y = 0.0
		var dd = d * 0.6
		b.cyl(Vector3(x, 1.5, n), dd, 3.0, c.darkened(0.1), true, 18)
		y = 3.0
		for t in tiers:
			var th = 3.6
			var wp = b.w(Vector3(x, y + th * 0.5, n))
			b._mb(wp).add("frustum", wp, Vector3(dd + t * 2.4 + 2.4, th, dd + t * 2.4 + 2.4), c.lightened(0.03 * (t % 2)), Vector3(180, 0, 0), 20)
			b.frustum_shape(wp, (dd + t * 2.4 + 2.4) * 0.36, (dd + t * 2.4 + 2.4) * 0.5, th)   # ters kesik koni: altta dar
			b.cyl(Vector3(x, y + th, n), dd + t * 2.4 + 2.8, 0.35, c.darkened(0.2), false, 20)
			for k in 10:
				var a = yaw + k * 36.0
				var o = Builder.rot(0, (dd + t * 2.4 + 2.6) * 0.5, a)
				b.box(Vector3(x + o.x, y + th + 0.6, n + o.y), Vector3(0.12, 1.0, 0.12), Color(0.4, 0.42, 0.4), 0, false)
			var cnt = maxi(4, int(dd * 0.6))
			for k in cnt:
				var a = yaw + 360.0 * k / cnt
				var o = Builder.rot(0, (dd + t * 2.4 + 1.6) * 0.5, a)
				b.box(Vector3(x + o.x, y + th * 0.45, n + o.y), Vector3(1.2, 0.8, 0.2), Color(0.16, 0.22, 0.28), a, false)
			y += th
	else:
		var hgt = floors * 4.0 + 1.0
		b.frustum(Vector3(x, hgt * 0.5, n), d, hgt, c, true, 16)
		b.cyl(Vector3(x, hgt * 0.62, n), d * 0.95, 0.5, blue, false, 16)
		b.cyl(Vector3(x, hgt + 0.25, n), d * 0.85, 0.5, blue.darkened(0.15), false, 16)
		b.dome(Vector3(x, hgt + 0.5, n), d * 0.8, d * 0.35, blue, 16)
		for f in floors:
			var cnt = maxi(3, int(d * 0.5))
			for k in cnt:
				var a = yaw + 360.0 * k / cnt
				var o = Builder.rot(0, d * 0.42 * (1.0 - 0.14 * (f * 4.0 + 2.2) / hgt) + 0.1, a)
				b.disc(Vector3(x + o.x, f * 4.0 + 2.2, n + o.y), 1.2, 0.2, Color(0.16, 0.24, 0.35), a + 180.0, 10)
	var fo = Builder.rot(0, -d * 0.3 - 0.05, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.0, yaw, "kumo", rng)


## ---------------------------------------------------------------- Kar: ahşap ev, kalın karlı çatı, saçak buzları, odun yığını
static func snow_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var wood = Color(0.48, 0.34, 0.22).darkened(rng.randf_range(0.0, 0.2))
	var snow = Color(0.95, 0.97, 1.0)
	floors = mini(floors, 2)
	var hgt = floors * 3.8
	b.box(Vector3(x, 0.4, n), Vector3(wdt + 0.4, 0.8, dep + 0.4), Color(0.5, 0.5, 0.52), yaw)
	b.box(Vector3(x, hgt * 0.5 + 0.8, n), Vector3(wdt, hgt, dep), wood, yaw)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var o = Builder.rot(sx * wdt * 0.5, sz * dep * 0.5, yaw)
			b.box(Vector3(x + o.x, hgt * 0.5 + 0.8, n + o.y), Vector3(0.4, hgt, 0.4), wood.darkened(0.3), yaw, false)
	var cnt = maxi(1, int(wdt / 3.0))
	for f in floors:
		for k in cnt:
			var lx = -wdt * 0.5 + (k + 0.5) * wdt / cnt
			var o = Builder.rot(lx, -dep * 0.5 - 0.05, yaw)
			b.box(Vector3(x + o.x, f * 3.8 + 2.6, n + o.y), Vector3(1.2, 1.2, 0.2), Color(0.95, 0.82, 0.5) if rng.randf() < 0.4 else Color(0.2, 0.25, 0.32), yaw, false)
	# dik çatı + üstünde kalın kar + saçak
	b.roof(Vector3(x, hgt + 0.8, n), Vector3(wdt + 2.2, 4.2, dep + 1.6), Color(0.3, 0.25, 0.22), yaw)
	b.roof(Vector3(x, hgt + 1.15, n), Vector3(wdt + 2.4, 4.0, dep + 1.8), snow, yaw)
	for k in 6:
		var lx = -wdt * 0.5 + k * wdt / 5.0
		var o = Builder.rot(lx, -dep * 0.5 - 0.9, yaw)
		var wi = b.w(Vector3(x + o.x, hgt + 0.45, n + o.y))
		b._mb(wi).add("cone", wi, Vector3(0.25, 0.8, 0.25), Color(0.85, 0.92, 1.0), Vector3(180, 0, 0), 5)
	var fo = Builder.rot(0, -dep * 0.5 - 0.05, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.8, yaw, "snow", rng)
	# yan duvara dayalı odun yığını + kar yığını
	var wo = Builder.rot(wdt * 0.5 + 0.8, 0, yaw)
	b.box(Vector3(x + wo.x, 0.8, n + wo.y), Vector3(1.2, 1.6, dep * 0.6), Color(0.45, 0.32, 0.2), yaw, false)
	b.dome(Vector3(x - wo.x * 1.2, 0, n - wo.y * 1.2), 3.0, 0.8, snow, 10)


## ---------------------------------------------------------------- uçuşan sis / bulut kartları (Kiri sisi, Kumo bulutları)
static var _mist_mat: StandardMaterial3D
static func mist(b: Builder, count: int, rmin: float, rmax: float, ymin: float, ymax: float, size: float, rng: RandomNumberGenerator, alpha := 0.32, col := Color(0.92, 0.95, 1.0)) -> void:
	if not is_instance_valid(b.root):
		return
	if _mist_mat == null:
		_mist_mat = StandardMaterial3D.new()
		_mist_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mist_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mist_mat.albedo_texture = FX.tex_soft
		_mist_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_mist_mat.billboard_keep_scale = true
		_mist_mat.vertex_color_use_as_albedo = true
		_mist_mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		_mist_mat.distance_fade_min_distance = 10.0
		_mist_mat.distance_fade_max_distance = 60.0
		_mist_mat.disable_receive_shadows = true
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q = QuadMesh.new()
	q.size = Vector2(1, 1)
	q.material = _mist_mat
	mm.mesh = q
	mm.instance_count = count
	for i in count:
		var a = rng.randf() * TAU
		var r = rng.randf_range(rmin, rmax)
		var s = size * rng.randf_range(0.6, 1.4)
		var p = b.w(Vector3(r * sin(a), rng.randf_range(ymin, ymax), r * cos(a))) - b.root.global_position
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s * 1.8, s, s)), p))
		mm.set_instance_color(i, Color(col.r, col.g, col.b, alpha * rng.randf_range(0.6, 1.0)))
	var mi = MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = b.view_dist
	b.root.add_child(mi)


## ---------------------------------------------------------------- basit su yüzeyi (göl/kanal), yarı saydam
static var _water_mat: StandardMaterial3D
static func water(b: Builder, p: Vector3, size: Vector2, yaw := 0.0) -> void:
	if not is_instance_valid(b.root):
		return
	if _water_mat == null:
		_water_mat = StandardMaterial3D.new()
		_water_mat.albedo_color = Color(0.22, 0.5, 0.62, 0.82)
		_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_water_mat.roughness = 0.08
		_water_mat.metallic_specular = 0.9
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = size
	pm.material = _water_mat
	mi.mesh = pm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = b.view_dist
	b.root.add_child(mi)
	mi.global_position = b.w(p)
	mi.rotation.y = deg_to_rad(-yaw)


## ---------------------------------------------------------------- asma köprü: tahta + iki ip korkuluk (a -> b, yerel)
static func rope_bridge(b: Builder, a: Vector3, c: Vector3, width := 3.0, sag := 3.0) -> void:
	var seg = maxi(4, int(a.distance_to(c) / 3.0))
	var dir = c - a
	var yaw = rad_to_deg(atan2(dir.x, dir.z))
	for i in seg:
		var t0 = float(i) / seg
		var t1 = float(i + 1) / seg
		var p0 = a.lerp(c, t0) - Vector3(0, sin(t0 * PI) * sag, 0)
		var p1 = a.lerp(c, t1) - Vector3(0, sin(t1 * PI) * sag, 0)
		var m = (p0 + p1) * 0.5
		var L = p0.distance_to(p1)
		var pitch = rad_to_deg(atan2(p1.y - p0.y, Vector2(p1.x - p0.x, p1.z - p0.z).length()))
		b.box(m, Vector3(width, 0.18, L * 0.92), WOOD.lightened(0.05 * (i % 2)), yaw, true, Vector3(pitch, 0, 0))
		for sx in [-1.0, 1.0]:
			var off = Builder.rot(width * 0.5 * sx, 0, yaw)
			b.box(m + Vector3(off.x, 1.0, off.y), Vector3(0.08, 0.08, L), Color(0.6, 0.5, 0.35), yaw, false, Vector3(pitch, 0, 0))
			if i % 2 == 0:
				b.box(p0 + Vector3(off.x, 0.5, off.y), Vector3(0.06, 1.0, 0.06), Color(0.6, 0.5, 0.35), yaw, false)
