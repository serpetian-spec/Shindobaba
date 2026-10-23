class_name VillageStyles
extends RefCounted
## Köy mimarileri: her köyün kendine has ev tipleri (Builder ile, yerel uzay: x doğu, y yukarı, n kuzey; yaw 0 = ön güney).
## Builder.house() bu fonksiyonları stile göre çağırır; köyler (build_sites) ve mezralar (poi_builder/roadside) ortak kullanır.

const DARK := Color(0.12, 0.1, 0.09)
const WOOD := Color(0.42, 0.29, 0.18)


## ---------------------------------------------------------------- Suna: kerpiç, yuvarlak köşeli, yuvarlak pencereli kubbe evler
static func suna_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.87, 0.74, 0.54).darkened(rng.randf_range(0.0, 0.12))
	var trim = c.darkened(0.12)
	var hgt = floors * 4.0 + 0.6
	var round_type = rng.randf() < 0.55
	var d = maxf(wdt, dep)
	if round_type:
		# silindir gövde + yassı kubbe + çatı korkuluğu
		b.cyl(Vector3(x, hgt * 0.5, n), d, hgt, c, true, 18)
		b.cyl(Vector3(x, hgt + 0.35, n), d + 0.5, 0.7, trim, false, 18)
		b.dome(Vector3(x, hgt + 0.7, n), d * 0.86, d * 0.28, c.lightened(0.06), 18)
		# yuvarlak pencereler (katlar boyunca)
		for f in floors:
			var cnt = maxi(4, int(d * 0.5))
			for k in cnt:
				var a = yaw + 360.0 * k / cnt + f * 22.0
				var o = Builder.rot(0, d * 0.5 + 0.05, a)
				b.disc(Vector3(x + o.x, f * 4.0 + 2.4, n + o.y), 1.3, 0.25, DARK, a + 180.0, 10)
				b.disc(Vector3(x + o.x * 1.01, f * 4.0 + 2.4, n + o.y * 1.01), 1.6, 0.12, trim, a + 180.0, 10)
	else:
		# yuvarlak köşeli kutu (köşelerde silindirler) + düz çatı + parapet
		b.box(Vector3(x, hgt * 0.5, n), Vector3(wdt - 1.6, hgt, dep), c, yaw)
		b.box(Vector3(x, hgt * 0.5, n), Vector3(wdt, hgt, dep - 1.6), c, yaw)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var o = Builder.rot((wdt * 0.5 - 0.8) * sx, (dep * 0.5 - 0.8) * sz, yaw)
				b.cyl(Vector3(x + o.x, hgt * 0.5, n + o.y), 1.6, hgt, c, false, 10)
		b.box(Vector3(x, hgt + 0.45, n), Vector3(wdt + 0.3, 0.9, dep + 0.3), trim, yaw, false)
		for f in floors:
			var cnt = maxi(1, int(wdt / 3.5))
			for k in cnt:
				var lx = -wdt * 0.5 + (k + 0.5) * wdt / cnt
				for side in [-1.0, 1.0]:
					var o = Builder.rot(lx, dep * 0.5 * side + 0.06 * side, yaw)
					b.disc(Vector3(x + o.x, f * 4.0 + 2.4, n + o.y), 1.25, 0.2, DARK, yaw + (180.0 if side > 0 else 0.0), 10)
	# kapı (kemerli), kumaş tente, su deposu, merdiven/kenar
	var fo = Builder.rot(0, -(d * 0.5 if round_type else dep * 0.5) - 0.05, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.0, yaw, "suna", rng)
	if rng.randf() < 0.6:
		var aw = [Color(0.75, 0.25, 0.2), Color(0.25, 0.45, 0.6), Color(0.85, 0.65, 0.25), Color(0.55, 0.35, 0.55)][rng.randi() % 4]
		var ao = Builder.rot(0, -(d * 0.5 if round_type else dep * 0.5) - 1.3, yaw)
		b.box(Vector3(x + ao.x, 3.6, n + ao.y), Vector3(4.6, 0.12, 2.6), aw, yaw, false, Vector3(-14, 0, 0))
		for sx in [-1.0, 1.0]:
			var po = Builder.rot(2.1 * sx, -(d * 0.5 if round_type else dep * 0.5) - 2.4, yaw)
			b.box(Vector3(x + po.x, 1.6, n + po.y), Vector3(0.14, 3.2, 0.14), WOOD, yaw, false)
	if rng.randf() < 0.5:
		var to = Builder.rot(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.0, 1.0), yaw)
		var ty = hgt + (d * 0.28 if round_type else 0.9)
		b.cyl(Vector3(x + to.x, ty + 1.2, n + to.y), 2.2, 2.4, Color(0.62, 0.64, 0.66), false, 10)
		b.cone(Vector3(x + to.x, ty + 2.7, n + to.y), 2.4, 0.6, Color(0.5, 0.52, 0.55), 10)


## ---------------------------------------------------------------- Kiri: mavi çatılı silindir kuleler, borular, balkon halkaları
static func kiri_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.66, 0.72, 0.74).darkened(rng.randf_range(0.0, 0.14))
	var blue = Color(0.26, 0.42, 0.58).lightened(rng.randf_range(-0.05, 0.08))
	var d = maxf(wdt, dep) * 0.9
	var fl = floors + 1
	var hgt = fl * 4.0
	b.cyl(Vector3(x, hgt * 0.5, n), d, hgt, c, true, 16)
	for f in fl:
		var y = f * 4.0 + 4.0
		b.cyl(Vector3(x, y - 0.15, n), d + 0.6, 0.3, c.darkened(0.15), false, 16)  # kat bandı
		var cnt = maxi(3, int(d * 0.45))
		for k in cnt:
			var a = yaw + 360.0 * k / cnt + f * 30.0
			var o = Builder.rot(0, d * 0.5 + 0.04, a)
			b.box(Vector3(x + o.x, y - 2.0, n + o.y), Vector3(1.0, 1.6, 0.2), Color(0.18, 0.25, 0.32), a, false)
	# konik/kubbe mavi çatı + baca
	if rng.randf() < 0.5:
		b.cone(Vector3(x, hgt + 1.6, n), d + 1.4, 3.2, blue, 16)
	else:
		b.cyl(Vector3(x, hgt + 0.3, n), d + 1.2, 0.6, blue.darkened(0.15), false, 16)
		b.dome(Vector3(x, hgt + 0.6, n), d + 0.8, d * 0.32, blue, 16)
	b.cyl(Vector3(x + d * 0.2, hgt + 2.4, n), 0.7, 2.4, Color(0.45, 0.48, 0.5), false, 8)
	# dış borular (dikey + dirsek)
	for k in 2:
		var a = yaw + 90.0 + k * 150.0
		var o = Builder.rot(0, d * 0.5 + 0.45, a)
		b.cyl(Vector3(x + o.x, hgt * 0.5, n + o.y), 0.55, hgt, Color(0.5, 0.52, 0.55), false, 8)
		var o2 = Builder.rot(0, d * 0.5 + 0.9, a)
		b.box(Vector3(x + o2.x, hgt * rng.randf_range(0.3, 0.8), n + o2.y), Vector3(0.5, 0.5, 1.4), Color(0.5, 0.52, 0.55), a, false)
	# ahşap balkon halkası
	if fl >= 2 and rng.randf() < 0.6:
		var by = 4.0 * rng.randi_range(1, fl - 1)
		b.cyl(Vector3(x, by, n), d + 2.4, 0.25, WOOD, false, 16)
		for k in 12:
			var o = Builder.rot(0, d * 0.5 + 1.1, yaw + k * 30.0)
			b.box(Vector3(x + o.x, by + 0.6, n + o.y), Vector3(0.15, 1.2, 0.15), WOOD, 0, false)
		var wpr = b.w(Vector3(x, by + 1.2, n))
		b._mb(wpr).add("torus", wpr, Vector3(d + 2.3, 0.6, d + 2.3), WOOD, Vector3.ZERO, 16)
	var fo = Builder.rot(0, -d * 0.5 - 0.05, yaw)
	DoorKit.door(b, x + fo.x, n + fo.y, 0.0, yaw, "kiri", rng)


## ---------------------------------------------------------------- Iwa: kayaya oyulmuş taş evler, kırmızı-kahve basamaklı çatılar
static func iwa_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var c = Color(0.56, 0.46, 0.36).darkened(rng.randf_range(0.0, 0.15))
	var roof = Color(0.55, 0.22, 0.16).lerp(Color(0.42, 0.3, 0.22), rng.randf())
	var hgt = floors * 4.0
	# katlar hafif kademeli (taş blok yığını)
	for f in floors:
		var s = 1.0 - f * 0.08
		b.box(Vector3(x, f * 4.0 + 2.0, n), Vector3(wdt * s, 4.0, dep * s), c.lightened(0.03 * (f % 2)), yaw)
		b.box(Vector3(x, f * 4.0 + 4.0, n), Vector3(wdt * s + 0.6, 0.35, dep * s + 0.6), c.darkened(0.18), yaw, false)
		# oyma pencereler
		var cnt = maxi(1, int(wdt * s / 3.2))
		for k in cnt:
			var lx = -wdt * s * 0.5 + (k + 0.5) * wdt * s / cnt
			var o = Builder.rot(lx, -dep * s * 0.5 - 0.05, yaw)
			b.box(Vector3(x + o.x, f * 4.0 + 2.2, n + o.y), Vector3(1.1, 1.5, 0.2), DARK, yaw, false)
			b.box(Vector3(x + o.x, f * 4.0 + 3.1, n + o.y), Vector3(1.5, 0.25, 0.4), c.darkened(0.2), yaw, false)
	# kademeli düz çatı levhaları + baca
	var s2 = 1.0 - (floors - 1) * 0.08
	b.box(Vector3(x, hgt + 0.4, n), Vector3(wdt * s2 + 1.4, 0.8, dep * s2 + 1.4), roof, yaw)
	b.box(Vector3(x, hgt + 1.0, n), Vector3(wdt * s2 * 0.6, 0.6, dep * s2 * 0.6), roof.darkened(0.12), yaw, false)
	var co = Builder.rot(wdt * 0.25, dep * 0.2, yaw)
	b.box(Vector3(x + co.x, hgt + 1.8, n + co.y), Vector3(1.0, 2.2, 1.0), c.darkened(0.1), yaw, false)
	var fo = Builder.rot(0, -dep * 0.5 - 0.05, yaw)
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


## ---------------------------------------------------------------- Kumo: beyaz yuvarlak kuleler, mavi kubbe, kemer bantları
static func kumo_house(b: Builder, x: float, n: float, wdt: float, dep: float, floors: int, yaw: float, rng: RandomNumberGenerator) -> void:
	var white = Color(0.9, 0.9, 0.87).darkened(rng.randf_range(0.0, 0.08))
	var blue = Color(0.22, 0.45, 0.72).lightened(rng.randf_range(-0.06, 0.08))
	var d = maxf(wdt, dep) * 0.85
	var hgt = floors * 4.0 + 1.0
	b.frustum(Vector3(x, hgt * 0.5, n), d, hgt, white, true, 16)
	b.cyl(Vector3(x, hgt * 0.62, n), d * 0.95, 0.5, blue, false, 16)
	b.cyl(Vector3(x, hgt + 0.25, n), d * 0.85, 0.5, blue.darkened(0.15), false, 16)
	b.dome(Vector3(x, hgt + 0.5, n), d * 0.8, d * 0.35, blue, 16)
	for f in floors:
		var cnt = maxi(3, int(d * 0.5))
		for k in cnt:
			var a = yaw + 360.0 * k / cnt
			var o = Builder.rot(0, d * 0.42 * (1.0 - 0.14 * (f * 4.0 + 2.2) / hgt) + 0.1, a)
			b.disc(Vector3(x + o.x, f * 4.0 + 2.2, n + o.y), 1.2, 0.2, Color(0.16, 0.24, 0.35), a + 180.0, 10)
	var fo = Builder.rot(0, -d * 0.43 - 0.05, yaw)  # gövde (frustum) tabanda ~0.43d yarıçaplı
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
