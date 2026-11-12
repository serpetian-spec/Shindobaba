class_name KageHall
extends RefCounted
## Kage binaları ve önlerindeki tören meydanları. Yerel koordinat (Builder): x doğu, n kuzey, bina önü güneye (-n) bakar.
## plaza(): taş döşeli meydan (derz çizgileri, sınır bandı, orta yol + kakma), amblemli çeşme, teras + rampalı merdiven,
## köy kapısı (iki direk + kanji plakası), fener sıraları, banklar, çit gibi budanmış çalılı taş saksılar + iklime göre ağaçlar,
## sancaklar, kapı ve merdiven nöbetçileri. konoha_tower(): Hokage Kulesi (katlı gövde, saçak, balkon korkuluğu, 火 plakası,
## giriş revakı, kanatlar, çatı su depoları).

const VL = preload("res://scripts/world/village_life.gd")


## Yerel zemin yüksekliği (köy tabanına göre)
static func _g(b: Builder, x: float, n: float) -> float:
	return Game.terrain_height(b.origin.x + x, b.origin.z - n) - b.origin.y


static func _gp(b: Builder, x: float, n: float) -> Vector3:
	var wp = b.origin + Vector3(x, 0, -n)
	wp.y = Game.terrain_height(wp.x, wp.z)
	return wp


## Görünmez eğimli çarpışma (merdiven rampası): n0'dan (y0) n1'e (y1) yükselir
static func _ramp(b: Builder, x: float, n0: float, y0: float, n1: float, y1: float, wd: float) -> void:
	if not is_instance_valid(b.body):
		return
	var run = absf(n1 - n0)
	var rise = y1 - y0
	var L = sqrt(run * run + rise * rise)
	var th = atan2(rise, run)
	var mid = b.w(Vector3(x, (y0 + y1) * 0.5, (n0 + n1) * 0.5))
	var basis = Basis(Vector3.RIGHT, th if n1 > n0 else -th)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(wd, 0.4, L)
	cs.shape = sh
	cs.transform = Transform3D(basis, mid - basis.y * 0.2)
	b.add_shape(cs)


static func _site(vid: String, d: Dictionary) -> void:
	if not VL.sites.has(vid):
		VL.sites[vid] = []
	VL.sites[vid].append(d)


## Ağaç: iklime göre (yeşil: geniş yapraklı, çöl: palmiye, sis/kaya/bulut: çam)
static func tree(b: Builder, x: float, n: float, y: float, climate: String, rng: RandomNumberGenerator, s := 1.0) -> void:
	if b._underwater(x, n, y):
		return
	match climate:
		"desert":   # anime hurma palmiyesi (AnimeTree)
			b.pack_mesh(AnimeTree.mesh("palm", "palm", rng.randi() % 3), Vector3(x, y, n), rng.randf() * 360.0, s * rng.randf_range(0.9, 1.1), 1.0)
			b._collide_cyl(b.w(Vector3(x, y + 3.0 * s, n)), 0.3 * s, 6.0 * s)
		"mist", "rock", "cloud":   # anime köknar / kara çam
			var pine = rng.randf() < 0.4
			b.pack_mesh(AnimeTree.mesh("pine" if pine else "fir", "pine" if pine else "fir", rng.randi() % 3), Vector3(x, y, n), rng.randf() * 360.0, s * rng.randf_range(0.7, 0.85), 1.0)
			b._collide_cyl(b.w(Vector3(x, y + 3.0 * s, n)), 0.35 * s, 6.0 * s)
		_:
			b.tree(x, n, s * rng.randf_range(0.95, 1.2), rng, y)


## Taş saksı: kenarlar + toprak + kenarda budanmış çalılar (+ ağaçlar)
static func planter(b: Builder, x: float, n: float, wd: float, dp: float, rim: Color, climate: String, rng: RandomNumberGenerator, trees := 2) -> void:
	var y = 0.0
	b.box(Vector3(x, y + 0.35, n - dp * 0.5), Vector3(wd, 0.7, 0.5), rim)
	b.box(Vector3(x, y + 0.35, n + dp * 0.5), Vector3(wd, 0.7, 0.5), rim)
	b.box(Vector3(x - wd * 0.5, y + 0.35, n), Vector3(0.5, 0.7, dp), rim)
	b.box(Vector3(x + wd * 0.5, y + 0.35, n), Vector3(0.5, 0.7, dp), rim)
	b.box(Vector3(x, y + 0.72, n - dp * 0.5), Vector3(wd + 0.15, 0.08, 0.65), rim.lightened(0.12), 0, false)
	b.box(Vector3(x, y + 0.72, n + dp * 0.5), Vector3(wd + 0.15, 0.08, 0.65), rim.lightened(0.12), 0, false)
	var soil = Color(0.36, 0.26, 0.18) if climate != "desert" else Color(0.62, 0.48, 0.3)
	b.box(Vector3(x, y + 0.5, n), Vector3(wd - 0.4, 0.3, dp - 0.4), soil, 0, false)
	var hedge = Color(0.24, 0.5, 0.24) if climate != "desert" else Color(0.42, 0.55, 0.3)
	if climate in ["rock", "cloud"]:
		hedge = Color(0.26, 0.48, 0.3)
	# kenar boyunca top budanmış çalılar
	var k = 0.0
	while k <= wd - 1.6:
		for sz in [-1.0, 1.0]:
			b.sphere(Vector3(x - wd * 0.5 + 0.8 + k, y + 1.0, n + sz * (dp * 0.5 - 0.75)), Vector3(1.3, 1.0, 1.1), hedge.lightened(rng.randf_range(-0.04, 0.05)), 8)
		k += 1.25
	if climate == "desert":
		for j in int(wd / 3.0):
			b.boulder(Vector3(x - wd * 0.5 + 1.5 + j * 3.0, y + 0.75, n + rng.randf_range(-0.6, 0.6)), Vector3(0.9, 0.5, 0.8), Color(0.7, 0.58, 0.42), j, false)
	for t in trees:
		var tx = x - wd * 0.5 + wd * (t + 0.5) / trees
		tree(b, tx, n, y + 0.6, climate, rng, 1.0)


## Tören meydanı. o: {vid, cx, front, hw, depth, climate, stone, trim, acc, gate, kanji, terrace_h, terrace_w, terrace_d, decor}
## Çeşme suyu: akan su malzemeli yassı disk
static func _water_disc(b: Builder, p: Vector3, d: float) -> void:
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = d * 0.5
	cm.bottom_radius = d * 0.5
	cm.height = 0.06
	cm.radial_segments = 28
	mi.mesh = cm
	mi.material_override = Canal._water()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.root.add_child(mi)
	mi.position = b.w(p)


## Fışkıran su: ortadan yukarı ince su sütunu + yay çizip düşen damlalar, üst çanağın kenarından havuza dökülen su perdesi
static func _fountain_spray(b: Builder, decor, p: Vector3) -> void:
	var parent: Node3D = decor if decor is Node3D else b.root
	var top = b.w(p)
	var jet = GPUParticles3D.new()
	jet.amount = 140
	jet.lifetime = 1.3
	jet.preprocess = 1.3
	jet.visibility_aabb = AABB(Vector3(-6, -5, -6), Vector3(12, 12, 12))
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 14.0
	pm.initial_velocity_min = 5.5
	pm.initial_velocity_max = 6.5
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	pm.color_ramp = FX._gradient([Color(0.85, 0.95, 1.0, 0.0), Color(0.85, 0.95, 1.0, 0.85), Color(0.75, 0.9, 1.0, 0.7), Color(0.75, 0.9, 1.0, 0.0)])
	jet.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(0.22, 0.22)
	q.material = FX._draw_mat(FX.tex_soft, false)
	jet.draw_pass_1 = q
	jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(jet)
	jet.position = top + Vector3(0, 0.3, 0)   # köy kökü dünya merkezinde
	# üst çanaktan halka halinde dökülen su: kenardan aşağı akan damlalar
	var fall = GPUParticles3D.new()
	fall.amount = 220
	fall.lifetime = 0.8
	fall.preprocess = 0.8
	fall.visibility_aabb = AABB(Vector3(-6, -5, -6), Vector3(12, 8, 12))
	var fm = ParticleProcessMaterial.new()
	fm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	fm.emission_ring_axis = Vector3.UP
	fm.emission_ring_radius = 1.8
	fm.emission_ring_inner_radius = 1.75
	fm.emission_ring_height = 0.05
	fm.direction = Vector3.DOWN
	fm.spread = 5.0
	fm.initial_velocity_min = 0.6
	fm.initial_velocity_max = 1.0
	fm.gravity = Vector3(0, -9.8, 0)
	fm.color_ramp = FX._gradient([Color(0.8, 0.92, 1.0, 0.7), Color(0.8, 0.92, 1.0, 0.6), Color(0.8, 0.92, 1.0, 0.0)])
	fall.process_material = fm
	var q2 = QuadMesh.new()
	q2.size = Vector2(0.12, 0.45)
	q2.material = FX._draw_mat(FX.tex_soft, false)
	fall.draw_pass_1 = q2
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(fall)
	fall.position = top
	for e in [jet, fall]:
		e.emitting = true


static func plaza(b: Builder, o: Dictionary) -> void:
	var vid: String = o["vid"]
	var cx: float = o.get("cx", 0.0)
	var front: float = o["front"]
	var hw: float = o.get("hw", 50.0)
	var depth: float = o.get("depth", 60.0)
	var climate: String = o.get("climate", "green")
	var stone: Color = o.get("stone", Color(0.8, 0.75, 0.66))
	var trim: Color = o.get("trim", stone.darkened(0.25))
	var acc: Color = o.get("acc", Color(0.72, 0.18, 0.15))
	var gate_c: Color = o.get("gate", acc)
	var kj: String = o.get("kanji", "火")
	var th: float = o.get("terrace_h", 0.6)
	var tw: float = o.get("terrace_w", 30.0)
	var td: float = o.get("terrace_d", 5.0)
	var decor: Node3D = o.get("decor", null)
	if decor == null:
		decor = Node3D.new()
		decor.name = "KageMeydani"
		b.root.add_child(decor)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(vid + "_meydan")
	var yo = b.yoff
	b.yoff = _g(b, cx, front - depth * 0.5)
	var n0 = front - depth   # meydan girişi
	var nm = front - depth * 0.5
	# --- döşeme: kalın plaka (eğimde boşluk kalmasın), sınır bandı, derzler, orta yol
	b.box(Vector3(cx, -0.55, nm), Vector3(hw * 2.0, 1.2, depth), stone, 0, false)
	# yürüme katmanı: döşemenin (derz/yol/mozaik dahil) üstüne basılır, ayak araziye gömülmez
	b._collide(b.w(Vector3(cx, -0.48, nm)), Vector3(hw * 2.0, 1.2, depth), 0.0)
	grass_mask(b, cx, n0, front, hw)   # çimen döşemeden çıkmasın
	for sz in [-1.0, 1.0]:
		b.box(Vector3(cx, 0.07, nm + sz * (depth * 0.5 - 0.7)), Vector3(hw * 2.0, 0.04, 1.4), trim, 0, false)
		b.box(Vector3(cx + sz * (hw - 0.7), 0.07, nm), Vector3(1.4, 0.04, depth), trim, 0, false)
	var jc = stone.darkened(0.12)
	var gx = -hw + 5.0
	while gx < hw - 1.0:
		b.box(Vector3(cx + gx, 0.065, nm), Vector3(0.1, 0.03, depth - 2.8), jc, 0, false)
		gx += 5.0
	var gn = n0 + 5.0
	while gn < front - 1.0:
		b.box(Vector3(cx, 0.065, gn), Vector3(hw * 2.0 - 2.8, 0.03, 0.1), jc, 0, false)
		gn += 5.0
	var path_c = stone.lightened(0.14)
	b.box(Vector3(cx, 0.08, nm - td * 0.5), Vector3(8.0, 0.05, depth - td), path_c, 0, false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(cx + sx * 4.1, 0.09, nm - td * 0.5), Vector3(0.3, 0.05, depth - td), trim, 0, false)
	var kn = n0 + 4.0
	while kn < front - td - 4.0:
		if absf(kn - nm) > 9.0:
			b.box(Vector3(cx, 0.1, kn), Vector3(1.6, 0.05, 1.6), acc.darkened(0.1), 45.0, false)
		kn += 6.0
	# --- orta: mozaik halkalar + amblemli çeşme
	b.cyl(Vector3(cx, 0.09, nm), 19.0, 0.06, trim, false, 32)
	b.cyl(Vector3(cx, 0.11, nm), 17.4, 0.06, path_c, false, 32)
	b.cyl(Vector3(cx, 0.13, nm), 13.0, 0.06, acc.darkened(0.15), false, 32)
	b.cyl(Vector3(cx, 0.45, nm), 10.6, 0.9, stone.darkened(0.08), true, 28)
	b.cyl(Vector3(cx, 0.93, nm), 11.0, 0.12, stone.lightened(0.1), false, 28)
	_water_disc(b, Vector3(cx, 0.86, nm), 9.6)   # havuz suyu (akan, ışıltılı)
	b.cyl(Vector3(cx, 2.0, nm), 1.4, 2.6, stone.lightened(0.05), true, 12)
	b.cyl(Vector3(cx, 3.35, nm), 4.0, 0.35, stone.lightened(0.1), false, 20)
	_water_disc(b, Vector3(cx, 3.52, nm), 3.5)
	b.cyl(Vector3(cx, 4.4, nm), 0.6, 1.8, stone.lightened(0.05), false, 10)
	b.disc(Vector3(cx, 6.0, nm), 2.4, 0.3, acc, 0.0, 20)
	b.disc(Vector3(cx, 6.0, nm), 2.7, 0.2, Color(0.85, 0.68, 0.3), 0.0, 20)
	b.kanji(Vector3(cx, 6.0, nm - 0.2), kj, 1.7, Color(0.98, 0.96, 0.9), 0.0)
	b.kanji(Vector3(cx, 6.0, nm + 0.2), kj, 1.7, Color(0.98, 0.96, 0.9), 180.0)
	_fountain_spray(b, o.get("decor"), Vector3(cx, 3.6, nm))   # üst çanaktan taşıp havuza dökülen su + tepeden fışkırma
	# --- teras + rampalı merdiven (görsel basamaklar)
	if th > 0.05:
		b.box(Vector3(cx, th * 0.5 - 0.3, front - td * 0.5), Vector3(tw, th + 0.6, td), stone.darkened(0.04))
		b.box(Vector3(cx, th + 0.03, front - td * 0.5), Vector3(tw + 0.3, 0.08, td + 0.3), stone.lightened(0.1), 0, false)
		var steps = maxi(2, int(ceil(th / 0.3)))
		var sh = th / steps
		var sd = 0.9
		var sw = minf(tw - 6.0, 16.0)
		for i in steps:
			var top = th - sh * (i + 1)
			var sn = front - td - sd * (i + 0.5)
			b.box(Vector3(cx, (top - 0.3) * 0.5, sn), Vector3(sw, top + 0.3, sd), stone.lightened(0.04 if i % 2 else 0.0), 0, false)
		_ramp(b, cx, front - td - sd * steps, 0.0, front - td, th, sw)
		for sx in [-1.0, 1.0]:  # basamaklı yan yanaklar + dipte taş fener
			var yx = cx + sx * (sw * 0.5 + 0.6)
			for i in steps:
				var top = th - sh * i + 0.25
				b.box(Vector3(yx, (top - 0.3) * 0.5, front - td - sd * (i + 0.5)), Vector3(1.2, top + 0.3, sd + 0.02), trim)
			b.lantern(yx + sx * 1.6, front - td - sd * steps - 0.6, 3.2)
	# --- giriş kapısı: iki direk, iki kiriş, kanji plakası
	var gw = 7.5
	for sx in [-1.0, 1.0]:
		b.box(Vector3(cx + sx * gw, 0.6, n0 + 1.5), Vector3(2.2, 1.2, 2.2), stone.darkened(0.15))
		b.cyl(Vector3(cx + sx * gw, 5.6, n0 + 1.5), 1.3, 9.6, gate_c, true, 12)
	b.box(Vector3(cx, 10.6, n0 + 1.5), Vector3(gw * 2.0 + 5.0, 1.0, 1.6), gate_c.darkened(0.25), 0, false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(cx + sx * (gw + 2.6), 10.95, n0 + 1.5), Vector3(2.0, 0.6, 1.6), gate_c.darkened(0.25), 0, false, Vector3(0, 0, -12 * sx))
	b.box(Vector3(cx, 8.6, n0 + 1.5), Vector3(gw * 2.0 + 1.4, 0.7, 1.0), gate_c, 0, false)
	b.box(Vector3(cx, 9.6, n0 + 1.5), Vector3(3.2, 2.0, 0.4), Color(0.12, 0.1, 0.09), 0, false)
	b.box(Vector3(cx, 9.6, n0 + 1.28), Vector3(2.8, 1.6, 0.06), Color(0.96, 0.94, 0.88), 0, false)
	b.kanji(Vector3(cx, 9.6, n0 + 1.2), kj, 1.4, acc.darkened(0.2), 0.0)
	# --- fener sıraları + banklar (yol kenarı)
	var ln = n0 + 6.0
	var i_l = 0
	while ln < front - td - 6.0:
		if absf(ln - nm) > 11.0:
			for sx in [-1.0, 1.0]:
				b.lantern(cx + sx * 6.2, ln, 3.2)
				if i_l % 2 == 1:
					b.prop("bench", Vector3(cx + sx * 9.0, 0.0, ln), 90.0 * sx, 0.0, 0.0)
		ln += 8.0
		i_l += 1
	# --- iki yanda saksılar (dış kenarda, aralıklı): budanmış çalılar + ağaç; arada açık taş meydan
	var pw = minf(hw - 18.0, 20.0)
	if pw > 6.0:
		for sx in [-1.0, 1.0]:
			var px = cx + sx * (hw - 3.0 - pw * 0.5)
			var pn = n0 + 8.0
			while pn + 8.0 < front - 4.0:
				planter(b, px, pn + 4.0, pw, 7.0, trim, climate, rng, 1 if pw < 14.0 else 2)
				pn += 18.0
	# meydan zemini: peyzaj ağaçları buraya dikilmesin
	if b.has_method("add_solid"):
		b.add_solid(b.w(Vector3(cx, 0, nm)), hw, depth * 0.5, 0.0)
	# --- sancaklar: teras önü + kapı yanları
	for sx in [-1.0, 1.0]:
		CityDecor.banner(decor, _gp(b, cx + sx * (tw * 0.5 + 2.5), front - td - 1.0), 0.0, acc, Color(0.98, 0.96, 0.9))
		CityDecor.banner(decor, _gp(b, cx + sx * (gw + 3.5), n0 + 3.0), 0.0, acc, Color(0.98, 0.96, 0.9))
	# --- nöbetçiler: merdiven başı + kapı
	for sx in [-1.0, 1.0]:
		_site(vid, {"type": "guard", "pos": _gp(b, cx + sx * (minf(tw - 6.0, 16.0) * 0.5 + 1.0), front - td - 4.5), "face": PI})   # fenerin önünde, meydan tarafında (arkasında kalıyordu)
		_site(vid, {"type": "guard", "pos": _gp(b, cx + sx * (gw - 2.0), n0 + 0.5), "face": PI})
	_site(vid, {"type": "pigeons", "pos": _gp(b, cx + 12, nm - 8)})
	b.yoff = yo


## Dikdörtgen alanı çimen maskesine yaz (yol dokusu G kanalı): yerel x [cx-hw, cx+hw], n [n0, n1].
## RoadMap şeridi dikdörtgendir, uçları half*0.5 uzar: uzun eksen boyunca 4 şerit, taşma yok.
static func grass_mask(b: Builder, cx: float, n0: float, n1: float, hw: float) -> void:
	var RM = preload("res://scripts/world/road_map.gd")
	var along_x = hw * 2.0 >= n1 - n0
	var short = (n1 - n0) if along_x else hw * 2.0
	var rows = 4
	var half = short / rows * 0.5 * 1.1   # komşu şeritler hafif örtüşür
	for r in rows:
		var t = (r + 0.5) / rows
		var a: Vector3; var e: Vector3
		if along_x:
			var nn = lerpf(n0, n1, t)
			a = b.w(Vector3(cx - hw + half * 0.5, 0, nn)); e = b.w(Vector3(cx + hw - half * 0.5, 0, nn))
		else:
			var xx = lerpf(cx - hw, cx + hw, t)
			a = b.w(Vector3(xx, 0, n0 + half * 0.5)); e = b.w(Vector3(xx, 0, n1 - half * 0.5))
		RM.add_lane(Vector2(a.x, a.z), Vector2(e.x, e.z), half)

## Kage ofisi kapısı (iç mekân: Interiors "kage" odası)
static func door(b: Builder, x: float, n: float, y: float, vid: String, label: String, radius := 5.0) -> void:
	var wp = b.w(Vector3(x, 0, n))
	wp.y = maxf(Game.terrain_height(wp.x, wp.z), b.origin.y + y) + 0.4
	Interact.add({"pos": wp, "radius": radius, "kind": "enter", "label": label, "room": "kage", "vid": vid, "alias": "mission_board", "out": wp})


## Hokage Kulesi: taş kaide, katlı krem gövde, kat bantları + pencereler, kırmızı saçak etek, balkon + korkuluk,
## üst gövde + 火 plakası, iki kademeli kırmızı çatı, giriş revakı, doğu idari kanat, batı arşiv (書), su depoları.
static func konoha_tower(b: Builder, decor: Node3D, tn: float) -> float:
	var yo = b.yoff
	b.yoff = _g(b, 0, tn)
	var cream = Color(0.94, 0.88, 0.74)
	var red = Color(0.75, 0.17, 0.13)
	var dark = Color(0.3, 0.2, 0.14)
	var glass = Color(0.55, 0.72, 0.85)   # pencere işareti: gece bazıları yanar (toon)
	var stone = Color(0.66, 0.62, 0.56)
	# anime (refs/konoha/Hokage_Residence.png): kırmızı silindir gövde, kiremit etek çatılar (krem gövde kanon değildi)
	var wall = Color(0.74, 0.22, 0.17)
	var tile = Color(0.86, 0.52, 0.24)
	# kaide
	b.cyl(Vector3(0, 0.3, tn), 82, 1.2, stone, true, 40)
	b.cyl(Vector3(0, 0.93, tn), 83, 0.08, stone.lightened(0.12), false, 40)
	# ana gövde + kat bantları
	b.cyl(Vector3(0, 24.9, tn), 70, 48, wall, true, 40)
	for fl in 4:
		b.cyl(Vector3(0, 11.0 + fl * 10.0, tn), 70.8, 0.6, dark.lightened(0.15), false, 40)
	b.cyl(Vector3(0, 1.9, tn), 71.2, 2.0, wall.darkened(0.2), false, 40)
	# pencereler: çerçeve + cam + küçük saçak
	for k in 16:
		var a = k * 22.5 + 11.25
		if absf(wrapf(a - 180.0, -180.0, 180.0)) < 14.0:
			continue  # giriş cephesi
		for fl in 4:
			var y = 6.2 + fl * 10.0
			var q = Builder.rot(0, 35.15, a)
			b.box(Vector3(q.x, y, tn + q.y), Vector3(4.2, 4.4, 0.4), dark, a, false)
			var q2 = Builder.rot(0, 35.3, a)
			b.box(Vector3(q2.x, y, tn + q2.y), Vector3(3.6, 3.8, 0.3), glass, a, false)
			b.box(Vector3(q2.x, y, tn + q2.y), Vector3(0.18, 3.8, 0.34), dark, a, false)
			var q3 = Builder.rot(0, 35.9, a)
			b.box(Vector3(q3.x, y + 2.55, tn + q3.y), Vector3(4.8, 0.25, 1.4), tile, a, false, Vector3(-14, 0, 0))
	# kırmızı saçak etek + alt kiriş
	b.cone(Vector3(0, 53.0, tn), 86, 9.0, tile, 40)
	b.cyl(Vector3(0, 48.6, tn), 85.5, 0.5, dark, false, 40)
	# balkon zemini + korkuluk (yürünebilir)
	b.cyl(Vector3(0, 56.8, tn), 66, 0.6, stone.lightened(0.05), true, 40)
	for k in 48:
		var a = k * 7.5
		var q = Builder.rot(0, 32.6, a)
		b.box(Vector3(q.x, 57.8, tn + q.y), Vector3(0.22, 1.4, 0.22), red.darkened(0.2), a, false)
		var q2 = Builder.rot(0, 32.6, a + 3.75)
		b.box(Vector3(q2.x, 58.55, tn + q2.y), Vector3(4.35, 0.16, 0.26), red.darkened(0.2), a + 3.75, false)
	# üst gövde
	b.cyl(Vector3(0, 62.0, tn), 52, 11, wall, true, 32)
	for k in 12:
		var a = k * 30.0 + 15.0
		var q = Builder.rot(0, 26.1, a)
		b.disc(Vector3(q.x, 61.5, tn + q.y), 2.6, 0.3, dark, a, 14)
		b.disc(Vector3(q.x * 1.004, 61.5, tn + q.y * 1.004), 2.1, 0.3, glass.lightened(0.1), a, 14)
	# 火 plakası (üst gövdenin önünde, balkonun üstünde)
	b.disc(Vector3(0, 63.0, tn - 26.4), 9.6, 0.5, Color(0.97, 0.95, 0.9), 0.0, 28)
	b.disc(Vector3(0, 63.0, tn - 26.2), 10.4, 0.4, red, 0.0, 28)
	b.kanji(Vector3(0, 63.0, tn - 26.75), "火", 7.6, red.darkened(0.05), 0.0)
	# çatı: kiriş bandı, büyük kırmızı koni, ikinci kademe, tepe süsü
	b.cyl(Vector3(0, 67.7, tn), 54, 0.8, dark, false, 32)
	b.cone(Vector3(0, 73.5, tn), 68, 12.0, tile, 32, true)
	b.cyl(Vector3(0, 79.0, tn), 18, 2.2, wall, false, 20)
	b.cone(Vector3(0, 82.6, tn), 24, 5.6, tile.darkened(0.05), 20)
	b.cyl(Vector3(0, 86.6, tn), 0.6, 3.0, dark, false, 8)
	b.sphere(Vector3(0, 88.3, tn), Vector3(1.1, 1.1, 1.1), Color(0.85, 0.68, 0.3), 10)
	# giriş revakı: iki kırmızı sütun, kırmızı çatı, çift kapı, noren, kanji pano
	var en = tn - 35.0
	for sx in [-1.0, 1.0]:
		b.cyl(Vector3(sx * 5.6, 4.0, en - 6.0), 1.1, 7.0, red, true, 10)
		b.box(Vector3(sx * 5.6, 0.8, en - 6.0), Vector3(1.8, 0.4, 1.8), stone.darkened(0.1), 0, false)
	b.box(Vector3(0, 7.7, en - 3.2), Vector3(14.0, 0.8, 7.2), dark, 0, false)
	b.roof(Vector3(0, 8.1, en - 3.2), Vector3(16.0, 2.6, 8.4), red)
	b.box(Vector3(0, 4.1, en + 0.15), Vector3(7.4, 6.4, 0.6), dark, 0, false)   # kapı terasın üstünde (alt yarısı terasa gömülüyordu)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(sx * 1.75, 3.75, en - 0.2), Vector3(3.3, 5.5, 0.2), Color(0.45, 0.28, 0.16), 0, false)
		b.box(Vector3(sx * 0.4, 3.75, en - 0.32), Vector3(0.12, 0.8, 0.08), Color(0.85, 0.68, 0.3), 0, false)
	for k in 4:
		b.box(Vector3(-2.7 + k * 1.8, 5.6, en - 0.5), Vector3(1.7, 1.6, 0.06), red, 0, false)
	b.box(Vector3(0, 9.6, en - 6.85), Vector3(4.2, 1.6, 0.2), Color(0.96, 0.94, 0.88), 0, false)
	b.kanji(Vector3(0, 9.6, en - 7.0), "火影", 1.3, red.darkened(0.2), 0.0)
	# doğu: idari kanat (pencere sıraları, kat saçakları, çatıda su depoları)
	var ex = 72.0; var enn = tn + 6.0
	b.box(Vector3(ex, 13, enn), Vector3(60, 26, 40), cream)
	b.box(Vector3(ex, 26.8, enn), Vector3(63, 1.6, 43), red)
	for fl in 3:
		var y = 4.5 + fl * 8.0
		b.box(Vector3(ex, y + 3.8, enn - 20.4), Vector3(60.4, 0.35, 1.2), red.darkened(0.15), 0, false)
		for i in 9:
			var wx = ex - 25.0 + i * 6.25
			b.box(Vector3(wx, y, enn - 20.15), Vector3(3.6, 3.2, 0.3), dark, 0, false)
			b.box(Vector3(wx, y, enn - 20.3), Vector3(3.1, 2.7, 0.2), glass, 0, false)
	for t in 3:
		var tx = ex - 18.0 + t * 16.0
		b.cyl(Vector3(tx, 30.0, enn + 6.0), 5.0, 4.6, Color(0.82, 0.84, 0.86), true, 14)
		b.cone(Vector3(tx, 33.0, enn + 6.0), 5.6, 1.4, Color(0.6, 0.62, 0.66), 14)
		for sx in [-1.0, 1.0]:
			b.box(Vector3(tx + sx * 1.8, 28.2, enn + 6.0), Vector3(0.25, 1.6, 0.25), dark, 0, false)
	b.box(Vector3(ex - 18.0, 30.6, enn - 14.0), Vector3(0.2, 6.0, 0.2), dark, 0, false)  # anten
	for k in 3:
		b.box(Vector3(ex - 18.0, 31.0 + k * 0.9, enn - 14.0), Vector3(2.4 - k * 0.5, 0.08, 0.08), dark, 0, false)
	# batı: arşiv / kütüphane (書)
	var wx0 = -72.0
	b.box(Vector3(wx0, 9, enn), Vector3(44, 18, 32), cream)
	b.box(Vector3(wx0, 18.8, enn), Vector3(47, 1.6, 35), red)
	b.roof(Vector3(wx0, 19.6, enn), Vector3(40, 5.0, 28), red.darkened(0.1))
	for fl in 2:
		for i in 6:
			var px = wx0 - 17.5 + i * 7.0
			b.box(Vector3(px, 5.0 + fl * 7.5, enn - 16.15), Vector3(3.2, 3.4, 0.3), dark, 0, false)
			b.box(Vector3(px, 5.0 + fl * 7.5, enn - 16.3), Vector3(2.7, 2.9, 0.2), Color(0.95, 0.92, 0.8), 0, false)
	b.disc(Vector3(wx0, 14.0, enn - 16.3), 5.0, 0.3, red, 0.0, 20)
	b.kanji(Vector3(wx0, 14.0, enn - 16.55), "書", 3.6, Color(0.98, 0.95, 0.9), 0.0)
	# gövdelerle kule arasında kapalı köprüler
	for sx in [-1.0, 1.0]:
		var bx0 = sx * 38.0
		var bw = 6.0 if sx > 0 else 14.0
		b.box(Vector3(bx0 + sx * bw * 0.5, 16.0, tn + 6.0), Vector3(bw + 2.0, 4.0, 6.0), cream.darkened(0.04))
		b.box(Vector3(bx0 + sx * bw * 0.5, 18.2, tn + 6.0), Vector3(bw + 2.6, 0.5, 6.8), red, 0, false)
	b.yoff = yo
	return tn - 41.0  # kaide önü
