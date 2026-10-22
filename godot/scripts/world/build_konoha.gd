class_name BuildKonoha
extends RefCounted
## Konohagakure: Ateş Ülkesi'nin gizli yaprak köyü. Yerel (x=doğu, n=kuzey), merkez (0,0), yarıçap ~1500 m (plato).
## Sokak ağı dünya verisinden (roads.json, kind "street") gelir; evler sokak boylarına dizilir (merkez sık, dış mahalleler seyrek).
## Kuzeyde arazi uçurumu (Hokage Kayası, n≈1170) — yüzler uçuruma oyulur. Girilebilir binalar ("enter" -> Interiors),
## canlı şehir mekânları (VillageLife.sites), süsler (CityDecor).

const VL = preload("res://scripts/world/village_life.gd")
const WALL_H := 28.0

static var R := 1460.0


## Kapı etkileşimi: araziye oturan nokta; alias = hikâye hedefi için iç mekândaki asıl tür
static func _door(b: Builder, x: float, n: float, radius: float, room: String, label: String, alias := "", seed := 0) -> void:
	var wp = b.w(Vector3(x, 0, n))
	wp.y = Game.terrain_height(wp.x, wp.z) + 0.4
	Interact.add({"pos": wp, "radius": radius, "kind": "enter", "label": label, "room": room, "alias": alias, "seed": seed, "out": wp})


## Araziye oturan etkileşim (Builder.interact taban yüksekliğini kullanır; burada gerçek zemin)
static func _act(b: Builder, x: float, n: float, radius: float, kind: String, label: String, data := {}) -> void:
	var wp = _gp(b, x, n) + Vector3(0, 0.4, 0)
	var d = {"pos": wp, "radius": radius, "kind": kind, "label": label}
	d.merge(data)
	Interact.add(d)


static func _site(b: Builder, type: String, x: float, n: float, extra := {}) -> void:
	var d = {"type": type, "pos": _gp(b, x, n)}
	d.merge(extra)
	if not VL.sites.has("konoha"):
		VL.sites["konoha"] = []
	VL.sites["konoha"].append(d)


## Yerel (x, n) noktasını araziye oturan Godot konumuna çevirir
static func _gp(b: Builder, x: float, n: float) -> Vector3:
	var wp = b.w(Vector3(x, 0, n))
	wp.y = Game.terrain_height(wp.x, wp.z)
	return wp


## Yerel zemin yüksekliği (köy tabanına göre)
static func _gy(b: Builder, x: float, n: float) -> float:
	var wp = b.w(Vector3(x, 0, n))
	return Game.terrain_height(wp.x, wp.z) - b.origin.y


## Yerel bakış yönü (dx doğu, dn kuzey) -> Villager.facing (radyan)
static func _face(dx: float, dn: float) -> float:
	return atan2(-dx, dn)


static func _on_road(b: Builder, x: float, n: float, clear: float) -> bool:
	var wp = b.w(Vector3(x, 0, n))
	return Game.road_dist(wp.x, wp.z) < clear


static func build(parent: Node3D, v: Dictionary) -> void:
	R = float(v.get("r", 1500.0)) - 40.0
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Konoha")
	var rng = RandomNumberGenerator.new()
	rng.seed = 1234
	var occupied: Array = []  # [x, n, yarı genişlik, yarı derinlik]
	VL.sites["konoha"] = []
	VL.doors["konoha"] = []
	var decor = Node3D.new()
	decor.name = "SehirSusleri"
	b.root.add_child(decor)
	var rock: Dictionary = v.get("hokage_rock", {})
	var cliff_n = float(rock.get("y", float(v["y"]) + 1170.0)) - float(v["y"])

	# ---- sur + kapılar (güney A-Un ana kapısı; diğerleri yolların girdiği açılarda)
	var wall_c = Color(0.86, 0.76, 0.58)
	var gate_angles: Array = v.get("gates", [180.0, 260.0, 100.0])
	var gaps = []
	for ga in gate_angles:
		gaps.append([float(ga), 2.4 if absf(float(ga) - 180.0) < 1.0 else 1.6])
	# kuzey: uçurum duvarın yerini alır
	var cliff_ang = rad_to_deg(acos(clampf(cliff_n / R, -1.0, 1.0)))
	gaps.append([0.0, cliff_ang * 2.0 + 6.0])
	b.wall_ring(R, WALL_H, 5.0, wall_c, gaps, 1.2)
	for ga in gate_angles:
		if absf(float(ga) - 180.0) < 1.0:
			_aun_gate(b, decor)
		else:
			b.village_gate(float(ga), R, 16.0, 24.0, Color(0.22, 0.42, 0.26), Color(0.16, 0.3, 0.2), "konoha", 1.6)
			var ga_r = deg_to_rad(float(ga))
			_site(b, "guard", (R - 14) * sin(ga_r) + 8 * cos(ga_r), (R - 14) * cos(ga_r) - 8 * sin(ga_r), {"face": _face(sin(ga_r), cos(ga_r))})

	# ---- Hokage Kayası: uçurum yüzüne oyulmuş beş yüz + tepede seyir yeri
	_hokage_faces(b, rock, cliff_n, v)

	# ---- merkez: Hokage Kulesi meydanı
	var tn = 600.0
	b.yoff = _gy(b, 0, tn)
	b.box(Vector3(0, 0.15, tn), Vector3(150, 0.3, 120), Color(0.78, 0.72, 0.62), 0, false)  # taş meydan
	b.cyl(Vector3(0, 24, tn), 70, 48, Color(0.92, 0.86, 0.72), true, 40)
	b.cyl(Vector3(0, 49.5, tn), 76, 3, Color(0.72, 0.18, 0.15), true, 40)
	b.cyl(Vector3(0, 59, tn), 52, 18, Color(0.92, 0.86, 0.72), true, 32)
	b.cone(Vector3(0, 74, tn), 66, 13, Color(0.72, 0.18, 0.15), 32, true)
	b.disc(Vector3(0, 55, tn - 26.0), 13, 0.8, Color(0.72, 0.18, 0.15))  # "火" plakası
	b.box(Vector3(0, 55, tn - 26.6), Vector3(6.5, 8, 0.5), Color(0.95, 0.92, 0.85), 0, false)
	b.box(Vector3(0, 4, tn - 35.2), Vector3(8, 8, 1), Color(0.35, 0.24, 0.16), 0, false)
	for k in 12:
		var a = deg_to_rad(k * 30.0 + 15.0)
		for fl in [14.0, 30.0]:
			b.box(Vector3(35.2 * sin(a), fl, tn + 35.2 * cos(a)), Vector3(4, 4, 0.5), Color(0.42, 0.62, 0.78), k * 30.0 + 15.0, false)
	b.box(Vector3(72, 13, tn + 6), Vector3(60, 26, 40), Color(0.92, 0.86, 0.72))  # idari bina
	b.box(Vector3(72, 26.8, tn + 6), Vector3(63, 1.6, 43), Color(0.72, 0.18, 0.15))
	b.box(Vector3(-72, 9, tn + 6), Vector3(44, 18, 32), Color(0.92, 0.86, 0.72))  # arşiv
	b.box(Vector3(-72, 18.8, tn + 6), Vector3(47, 1.6, 35), Color(0.72, 0.18, 0.15))
	b.yoff = 0.0
	_door(b, 0, tn - 37, 5.0, "hokage", "[F] Gir: Hokage Kulesi (Görev Masası)", "mission_board")
	for sx in [-1.0, 1.0]:
		CityDecor.banner(decor, _gp(b, 14 * sx, tn - 46), 0.0, Color(0.72, 0.18, 0.15), Color(0.98, 0.95, 0.9))
	_site(b, "pigeons", 30, tn - 52)
	occupied.append([0, tn, 110, 70])

	# ---- Ninja Akademisi (kulenin batısı) + avlu
	var ax = -540.0; var an = 610.0
	b.yoff = _gy(b, ax, an)
	b.box(Vector3(ax, 10, an), Vector3(100, 20, 34), Color(0.88, 0.78, 0.58))
	b.box(Vector3(ax, 20.8, an), Vector3(103, 1.6, 37), Color(0.72, 0.18, 0.15))
	b.box(Vector3(ax, 24.5, an), Vector3(28, 7, 18), Color(0.88, 0.78, 0.58))
	b.box(Vector3(ax, 28.6, an), Vector3(31, 1.4, 21), Color(0.72, 0.18, 0.15))
	for i in 14:
		for fl in [5.5, 14.0]:
			b.box(Vector3(ax - 45 + i * 6.9, fl, an - 17.1), Vector3(3.2, 3, 0.3), Color(0.42, 0.62, 0.78), 0, false)
	b.box(Vector3(ax, 3.2, an - 17.4), Vector3(7, 6.4, 0.6), Color(0.35, 0.24, 0.16), 0, false)
	b.box(Vector3(ax, 0.1, an - 60), Vector3(110, 0.2, 70), Color(0.74, 0.66, 0.52), 0, false)  # toprak avlu
	b.yoff = 0.0
	var tx = ax + 48.0; var tz = an - 36.0
	b.tree(tx, tz, 1.4, rng, _gy(b, tx, tz))
	var ty = _gy(b, tx, tz)
	b.box(Vector3(tx + 4.5, ty + 7.4, tz), Vector3(8, 0.5, 0.5), Color(0.42, 0.29, 0.18), 0, false)
	for dz in [-0.6, 0.6]:
		b.box(Vector3(tx + 7, ty + 5.0, tz + dz), Vector3(0.05, 4.8, 0.05), Color(0.85, 0.82, 0.75), 0, false)
	b.box(Vector3(tx + 7, ty + 2.6, tz), Vector3(0.8, 0.12, 1.5), Color(0.55, 0.38, 0.22), 0, false)
	_act(b, tx + 7, tz, 3, "swing", "[F] Salıncağa otur")
	_door(b, ax, an - 19, 5.0, "academy", "[F] Gir: Ninja Akademisi", "academy")
	for i in 5:
		Spawner.dummy(_gp(b, ax - 30 + i * 15, an - 70))
	_site(b, "academy_yard", ax, an - 60)
	_site(b, "ball", ax + 30, an - 80)
	_site(b, "pigeons", ax - 35, an - 75)
	occupied.append([ax, an - 25, 65, 70])

	# ---- çarşı: ana doğu-batı caddesi (n=0) boyunca tezgâhlar, arkada dükkânlar
	for i in 26:
		var sx = -310.0 + i * 25.0
		if absf(sx) < 22:
			continue
		var side = 1.0 if i % 2 == 0 else -1.0
		var cn = side * 12.0
		var aw = [Color(0.85, 0.3, 0.25), Color(0.25, 0.5, 0.75), Color(0.95, 0.75, 0.3), Color(0.35, 0.6, 0.35)][i % 4]
		b.yoff = _gy(b, sx, cn)
		b.box(Vector3(sx, 0.6, cn), Vector3(5, 1.2, 2), Color(0.55, 0.4, 0.25))
		b.box(Vector3(sx, 2.9, cn), Vector3(6, 0.15, 3.2), aw, 0, false, Vector3(-10 * side, 0, 0))
		for sp in [-2.8, 2.8]:
			b.box(Vector3(sx + sp, 1.5, cn + side * 1.2), Vector3(0.12, 3.0, 0.12), Color(0.35, 0.24, 0.16), 0, false)
		for k in 3:
			b.box(Vector3(sx - 1.6 + k * 1.6, 1.45, cn), Vector3(0.9, 0.5, 0.9), [Color(0.9, 0.5, 0.2), Color(0.85, 0.2, 0.3), Color(0.4, 0.75, 0.3)][k], 0, false)
		b.yoff = 0.0
		_site(b, "stall", sx, cn, {"back": _gp(b, sx, cn + side * 1.7), "front": _gp(b, sx, cn - side * 1.9), "face": _face(0, side)})
		if i % 3 == 0:
			CityDecor.banner(decor, _gp(b, sx + 3.2, cn - side * 1.4), 0.0, aw, Color(0.98, 0.95, 0.88))
	_site(b, "crowd", 0, 0)
	_site(b, "pigeons", 40, 14)
	for k in 13:
		var lx = -300.0 + k * 50.0
		if absf(lx) < 20:
			continue
		CityDecor.lantern_string(decor, _gp(b, lx, -14.5), _gp(b, lx, 14.5), 7, [Color(0.95, 0.3, 0.25), Color(1.0, 0.95, 0.85)])
	occupied.append([0, 0, 320, 22])
	# dükkânlar: [x, n, oda, etiket, levha rengi, alias, genişlik]
	var shops = [[-170.0, -36.0, "pharmacy", "[F] Gir: Eczane", Color(0.3, 0.6, 0.4), "shop_items", 14.0],
		[170.0, -36.0, "weapon_shop", "[F] Gir: Silah Dükkânı", Color(0.15, 0.15, 0.18), "shop_weapons", 14.0],
		[-250.0, -36.0, "tailor", "[F] Gir: Terzi (kıyafet, zırh)", Color(0.35, 0.25, 0.45), "tailor", 14.0],
		[250.0, -36.0, "teahouse", "[F] Gir: Dango ve Çay Evi", Color(0.85, 0.45, 0.55), "teahouse", 14.0],
		[-110.0, 36.0, "bbq", "[F] Gir: Yakiniku Restoranı", Color(0.85, 0.3, 0.2), "bbq", 16.0],
		[230.0, 38.0, "inn", "[F] Gir: Han (konaklama)", Color(0.25, 0.4, 0.6), "inn", 18.0]]
	for sh in shops:
		var face_south = sh[1] > 0.0  # caddenin kuzeyindekiler güneye (caddeye) bakar
		var yaw = 0.0 if face_south else 180.0
		b.house(sh[0], sh[1], sh[6], 11, 2, yaw, "konoha", rng)
		var dn = -1.0 if face_south else 1.0
		var hd = float(b.last_house.get("d", 11.0))
		b.box(Vector3(sh[0], _gy(b, sh[0], sh[1]) + 9.4, sh[1] + dn * (hd * 0.5 + 0.2)), Vector3(6, 1.6, 0.3), sh[4], 0, false)
		_door(b, sh[0], sh[1] + dn * (hd * 0.5 + 1.2), 3.0, sh[2], sh[3], sh[5])
		CityDecor.banner(decor, _gp(b, sh[0] + 5.0, sh[1] + dn * (hd * 0.5 + 2.4)), 0.0, sh[4], Color(0.98, 0.95, 0.9))
		occupied.append([sh[0], sh[1], sh[6] * 0.5 + 3, 9])
	_site(b, "bar", -95, 22)

	# ---- Ichiraku tarzı ramen tezgâhı (caddeye açık)
	var ix = 70.0; var inn = -30.0
	b.yoff = _gy(b, ix, inn)
	b.box(Vector3(ix, 0.65, inn + 1.5), Vector3(9, 1.3, 1.2), Color(0.55, 0.35, 0.2))
	b.box(Vector3(ix, 1.35, inn + 1.5), Vector3(9.5, 0.12, 1.6), Color(0.8, 0.62, 0.4), 0, false)
	b.box(Vector3(ix, 1.8, inn - 2.2), Vector3(9, 3.6, 4.5), Color(0.92, 0.88, 0.8))
	for sx in [-4.4, 4.4]:
		b.box(Vector3(ix + sx, 1.9, inn + 2.4), Vector3(0.35, 3.8, 0.35), Color(0.35, 0.24, 0.16), 0, false)
	b.box(Vector3(ix, 3.9, inn), Vector3(10.5, 0.5, 7.5), Color(0.72, 0.18, 0.15))
	for i in 6:
		b.box(Vector3(ix - 3.7 + i * 1.48, 3.1, inn + 2.55), Vector3(1.3, 1.1, 0.06), Color(0.95, 0.95, 0.95) if i % 2 else Color(0.85, 0.28, 0.22), 0, false)
	for i in 4:
		b.cyl(Vector3(ix - 3 + i * 2, 0.4, inn + 3.4), 0.7, 0.8, Color(0.72, 0.18, 0.15), false, 10)
	b.yoff = 0.0
	var seats = []
	for i in 4:
		seats.append(_gp(b, ix - 3 + i * 2, inn + 3.0))
	_act(b, ix, inn + 4, 4, "ramen", "[F] Tezgâha otur, ramen ye (50 Ryō)", {"seats": seats})
	_site(b, "ramen", ix, inn + 3.0, {"back": _gp(b, ix, inn - 0.3), "seats": seats, "face": _face(0, -1)})
	CityDecor.banner(decor, _gp(b, ix + 5.6, inn + 3.2), 0.0, Color(0.85, 0.25, 0.2), Color(0.98, 0.95, 0.9))
	occupied.append([ix, inn, 8, 6])

	# ---- Konoha Hastanesi (doğu)
	var hpx = 545.0; var hpn = 230.0
	b.yoff = _gy(b, hpx, hpn)
	b.box(Vector3(hpx, 15, hpn), Vector3(76, 30, 42), Color(0.96, 0.95, 0.92))
	b.box(Vector3(hpx, 30.6, hpn), Vector3(79, 1.4, 45), Color(0.75, 0.25, 0.22))
	b.box(Vector3(hpx + 46, 10, hpn), Vector3(20, 20, 30), Color(0.94, 0.93, 0.9))
	b.disc(Vector3(hpx, 24, hpn - 21.2), 8, 0.4, Color(0.75, 0.25, 0.22))
	b.box(Vector3(hpx, 24, hpn - 21.5), Vector3(1.6, 5, 0.3), Color(1, 1, 1), 0, false)
	b.box(Vector3(hpx, 24, hpn - 21.5), Vector3(5, 1.6, 0.3), Color(1, 1, 1), 0, false)
	for i in 12:
		for fl in [6.0, 14.0, 22.0]:
			b.box(Vector3(hpx - 33 + i * 6, fl, hpn - 21.1), Vector3(3, 2.6, 0.3), Color(0.5, 0.68, 0.82), 0, false)
	b.yoff = 0.0
	_door(b, hpx, hpn - 23, 5.0, "hospital", "[F] Gir: Konoha Hastanesi", "hospital")
	occupied.append([hpx + 10, hpn, 55, 28])

	# ---- Chunin Sınavı stadyumu (güneydoğu)
	var sx0 = 1050.0; var sn0 = -700.0
	for k in 72:
		var a = k * 5.0
		var rad = deg_to_rad(a)
		var o = Vector2(78 * sin(rad), 78 * cos(rad))
		var gy = _gy(b, sx0 + o.x, sn0 + o.y)
		b.box(Vector3(sx0 + o.x, gy + 11, sn0 + o.y), Vector3(7.4, 24, 4), Color(0.85, 0.78, 0.62), a)
		for t in 5:
			var ro = 74.0 - t * 2.6
			b.box(Vector3(sx0 + ro * sin(rad), gy + 2 + t * 3.8, sn0 + ro * cos(rad)), Vector3(7, 1, 2.6), Color(0.7, 0.6, 0.48), a)
	b.box(Vector3(sx0, _gy(b, sx0, sn0) + 0.05, sn0), Vector3(100, 0.1, 100), Color(0.62, 0.72, 0.42), 0, false)
	b.box(Vector3(sx0, _gy(b, sx0, sn0 + 76) + 24, sn0 + 76), Vector3(20, 4, 10), Color(0.72, 0.18, 0.15))
	_act(b, sx0, sn0 - 84, 8, "chunin_exam", "[F] Chunin Sınavı başvurusu")
	occupied.append([sx0, sn0, 86, 86])

	# ---- Uchiha Bölgesi (güneybatı) + Naka Tapınağı
	var ux = -1020.0; var un = -640.0
	b.wall_ring_at(ux, un, 125.0, 5.0, Color(0.9, 0.88, 0.84), [[45.0, 10.0]])
	for ring in [[95.0, 22], [62.0, 14]]:
		for k in ring[1]:
			var a = k * 360.0 / ring[1]
			var rr: float = ring[0]
			var hxp = ux + rr * sin(deg_to_rad(a)); var hnp = un + rr * cos(deg_to_rad(a))
			b.house(hxp, hnp, 11, 9, 1 + (k % 2), a + 180.0, "konoha", rng)
			var fo = Builder.rot(2.4, -float(b.last_house.get("d", 9.0)) * 0.5 - 0.1, a + 180.0)
			b.disc(Vector3(hxp + fo.x, _gy(b, hxp, hnp) + 2.6, hnp + fo.y), 1.4, 0.12, Color(0.8, 0.15, 0.15), a + 180.0, 12)
	b.yoff = _gy(b, ux, un)
	b.box(Vector3(ux, 4.5, un), Vector3(16, 9, 12), Color(0.55, 0.32, 0.22))
	b.roof(Vector3(ux, 9, un), Vector3(20, 5, 16), Color(0.25, 0.25, 0.3))
	b.box(Vector3(ux, 6, un - 16), Vector3(11, 1.0, 1.0), Color(0.8, 0.2, 0.15), 0, false)
	for sx in [-4.6, 4.6]:
		b.box(Vector3(ux + sx, 3.2, un - 16), Vector3(0.8, 6.4, 0.8), Color(0.8, 0.2, 0.15), 0, false)
	b.yoff = 0.0
	_act(b, ux, un - 13, 5, "naka", "[F] Naka Tapınağı")
	_act(b, ux + 8, un - 13, 3, "shrine", "[F] Tapınakta dua et (kısa kutsama)")
	occupied.append([ux, un, 128, 128])

	# ---- Hyuga Konağı (batı)
	var yx = -1050.0; var yn = 250.0
	b.yoff = _gy(b, yx, yn)
	b.wall_rect(yx, yn, 150, 110, 5.0, Color(0.9, 0.88, 0.82), 14.0)
	b.box(Vector3(yx, 5, yn + 15), Vector3(80, 10, 32), Color(0.58, 0.42, 0.28))
	b.roof(Vector3(yx, 10, yn + 15), Vector3(88, 7, 40), Color(0.28, 0.28, 0.32))
	b.box(Vector3(yx + 48, 3.5, yn - 22), Vector3(28, 7, 20), Color(0.58, 0.42, 0.28))
	b.roof(Vector3(yx + 48, 7, yn - 22), Vector3(32, 5, 24), Color(0.28, 0.28, 0.32))
	b.box(Vector3(yx - 25, 0.05, yn - 28), Vector3(50, 0.1, 30), Color(0.8, 0.78, 0.7), 0, false)
	b.yoff = 0.0
	_act(b, yx, yn - 56, 6, "hyuga", "[F] Hyuga Konağı")
	occupied.append([yx, yn, 80, 60])

	# ---- ANBU karargâhı (uçurumun dibinde, karanlık)
	var anx = -480.0; var ann = cliff_n - 110.0
	b.yoff = _gy(b, anx, ann)
	b.box(Vector3(anx, 9, ann), Vector3(40, 18, 30), Color(0.25, 0.25, 0.28))
	b.box(Vector3(anx, 18.5, ann), Vector3(42, 1, 32), Color(0.15, 0.15, 0.17))
	b.yoff = 0.0
	_act(b, anx, ann - 18, 6, "anbu", "[F] ANBU Karargâhı")
	occupied.append([anx, ann, 26, 20])

	# ---- Antrenman Alanı 3 + Anıt Taşı (doğu) + eğitmen
	var tgx = 1050.0; var tgn = 560.0
	b.box(Vector3(tgx, _gy(b, tgx, tgn) + 0.04, tgn), Vector3(140, 0.1, 110), Color(0.45, 0.62, 0.3), 0, false)
	for i in 3:
		b.cyl(Vector3(tgx - 6 + i * 6, _gy(b, tgx, tgn + 18) + 1.0, tgn + 18), 1.0, 2.0, Color(0.48, 0.34, 0.2), true, 10)
	b.box(Vector3(tgx - 35, _gy(b, tgx - 35, tgn + 30) + 2.2, tgn + 30), Vector3(4, 4.4, 1.2), Color(0.45, 0.45, 0.48))
	_act(b, tgx - 35, tgn + 27, 4, "memorial", "[F] Anıt Taşı")
	_act(b, tgx, tgn + 12, 6, "training", "[F] Antrenman yap (chakra kontrolü)")
	_act(b, tgx + 14, tgn + 12, 3.5, "trainer", "[F] Jonin eğitmen: jutsu öğren", {"village": "konoha"})
	_site(b, "trainer", tgx + 14, tgn + 14, {"face": _face(0, -1)})
	for i in 4:
		Spawner.dummy(_gp(b, tgx - 20 + i * 13, tgn - 15))
	_site(b, "spar", tgx - 30, tgn + 4)
	_site(b, "spar", tgx + 35, tgn - 2)
	occupied.append([tgx, tgn, 72, 58])
	for k in 30:  # alan çevresi ağaçlık
		var a = randf() * TAU
		var tr = rng.randf_range(80.0, 120.0)
		var tpx = tgx + cos(a) * tr; var tpn = tgn + sin(a) * tr * 0.8
		if not _on_road(b, tpx, tpn, 12.0):
			b.tree(tpx, tpn, rng.randf_range(1.2, 1.8), rng, _gy(b, tpx, tpn))

	# ---- oyuncunun evi (başlangıç noktasının yakınında) + inşaat alanı + park
	b.house(-150, 110, 10, 9, 2, 0, "konoha", rng)
	var phd = float(b.last_house.get("d", 9.0))
	b.box(Vector3(-150, _gy(b, -150, 110) + 2.6, 110 - phd * 0.5 - 0.1), Vector3(1.6, 0.5, 0.1), Color(0.9, 0.85, 0.7), 0, false)
	_door(b, -150, 110 - phd * 0.5 - 1.0, 2.6, "home_player", "[F] Evine gir (uyu, kaydet)")
	occupied.append([-150, 110, 8, 7])
	var cx0 = 520.0; var cn0 = -620.0
	var cg = _gy(b, cx0, cn0)
	for px in [-4.0, 0.0, 4.0]:
		for pn in [-3.0, 3.0]:
			b.box(Vector3(cx0 + px, cg + 3.0, cn0 + pn), Vector3(0.25, 6.0, 0.25), Color(0.62, 0.48, 0.3))
	for py in [2.0, 4.2]:
		b.box(Vector3(cx0, cg + py, cn0 - 3), Vector3(8.5, 0.15, 0.6), Color(0.55, 0.42, 0.26), 0, false)
	b.box(Vector3(cx0 - 2, cg + 1.2, cn0 + 3), Vector3(4.0, 2.4, 0.3), Color(0.9, 0.86, 0.76))
	b.box(Vector3(cx0 + 3, cg + 0.6, cn0 + 3), Vector3(2.0, 1.2, 0.3), Color(0.9, 0.86, 0.76))
	for k in 6:
		b.box(Vector3(cx0 + 7, cg + 0.15 + k * 0.22, cn0 - 2 + (k % 2) * 0.2), Vector3(0.3, 0.2, 4.0), Color(0.68, 0.52, 0.32), 0, false)
	_site(b, "work", cx0, cn0 - 5)
	occupied.append([cx0, cn0, 12, 10])
	var pkx = -520.0; var pkn = -250.0  # park: ağaçlar, banklar, top oynayan çocuklar
	for k in 24:
		var a = rng.randf() * TAU; var pr = rng.randf_range(15.0, 70.0)
		b.tree(pkx + cos(a) * pr, pkn + sin(a) * pr, rng.randf_range(1.0, 1.6), rng, _gy(b, pkx + cos(a) * pr, pkn + sin(a) * pr))
	_site(b, "ball", pkx, pkn)
	_site(b, "pigeons", pkx + 10, pkn - 8)
	for k in 4:
		var bx2 = pkx - 20 + k * 13.0
		b.box(Vector3(bx2, _gy(b, bx2, pkn - 30) + 0.45, pkn - 30), Vector3(2.2, 0.08, 0.45), Color(0.5, 0.34, 0.2), 0, false)
		_site(b, "bench", bx2, pkn - 30.4, {"face": _face(0, 1)})
	occupied.append([pkx, pkn, 75, 75])

	# ---- ana cadde (kuzey-güney, x=0): banklar, fener dizileri, sokak lambaları
	for nb in range(-1400, -40, 70):
		for sx in [-1.0, 1.0]:
			var bxp = 14.0 * sx
			var gyb = _gy(b, bxp, nb + 7)
			b.box(Vector3(bxp, gyb + 0.45, nb + 7), Vector3(0.45, 0.08, 2.2), Color(0.5, 0.34, 0.2), 0, false)
			for e in [-0.9, 0.9]:
				b.box(Vector3(bxp, gyb + 0.22, nb + 7 + e), Vector3(0.38, 0.44, 0.1), Color(0.42, 0.28, 0.16), 0, false)
			if rng.randf() < 0.4:
				_site(b, "bench", bxp, nb + 6.6, {"face": _face(-sx, 0)})
	for k in 18:
		var ln = -1380.0 + k * 75.0
		if ln > -40.0:
			break
		CityDecor.lantern_string(decor, _gp(b, -12.5, ln), _gp(b, 12.5, ln), 7, [Color(0.95, 0.3, 0.25), Color(1.0, 0.95, 0.85), Color(0.95, 0.3, 0.25)])
	for n in range(-1420, 560, 45):
		for sx in [-11.0, 11.0]:
			if not _on_road(b, sx * 3.0, n, 0.0):
				b.lantern(sx, n, 3.2 + _gy(b, sx, n))

	# ---- evler: sokak boylarına dizili (merkezde 3 sıra, dışarıda 1-2 sıra), her biri sokağa bakar
	b.view_dist = 1500.0
	var count = _street_houses(b, v, rng, occupied, decor, cliff_n)
	count += _fill_blocks(b, rng, occupied, cliff_n)
	# dış mahalleler: sokaklardan uzak boşluklara ağaç kümeleri (orman köyü hissi)
	var trees = 0
	for k in 1400:
		var a = rng.randf() * TAU
		var rr = sqrt(rng.randf()) * (R - 30.0)
		var tx2 = sin(a) * rr; var tn2 = cos(a) * rr
		if tn2 > cliff_n - 30.0 or rr < 250.0:
			continue
		if _on_road(b, tx2, tn2, 26.0) or not _free(tx2, tn2, occupied, 6.0):
			continue
		b.tree(tx2, tn2, rng.randf_range(1.1, 2.0), rng, _gy(b, tx2, tn2))
		trees += 1
	b.finish()
	_merge_house_cells(b.root)
	print("Konoha: ", count, " ev, ", trees, " ağaç")


## Sokak boyunca ev dizileri. Çakışma: dolu alanlar, başka sokaklar, önceki evler.
static func _street_houses(b: Builder, v: Dictionary, rng: RandomNumberGenerator, occupied: Array, decor: Node3D, cliff_n: float) -> int:
	var c = Vector2(float(v["x"]), float(v["y"]))
	var placed := {}  # 20 m ızgara -> [Vector2]
	var lantern_xf: Array = []
	var count = 0
	var segs: Array = []
	for rd in Game.roads:
		if rd["kind"] != "street":
			continue
		var pts: PackedVector2Array = rd["pts"]
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i] - c
			var e: Vector2 = pts[i + 1] - c
			if a.length() > R + 50.0 and e.length() > R + 50.0:
				continue
			segs.append([a, e])
	for sg in segs:
		var a: Vector2 = sg[0]
		var e: Vector2 = sg[1]
		var L = a.distance_to(e)
		var dir = (e - a) / L
		var nrm = Vector2(-dir.y, dir.x)
		var t = 22.0
		while t < L - 10.0:
			var p = a + dir * t
			t += rng.randf_range(15.0, 19.0)
			var dc = p.length()
			var rows = 1 if dc > 900.0 else (2 if dc > 450.0 else 3)
			for sd in [-1.0, 1.0]:
				for row in rows:
					var off = 15.5 + row * 16.5
					var q = p + nrm * sd * off + dir * rng.randf_range(-1.5, 1.5)
					if q.length() > R - 35.0 or q.y > cliff_n - 45.0:
						continue
					if not _free(q.x, q.y, occupied, 6.0):
						continue
					if _on_road(b, q.x, q.y, 12.5):
						continue
					var key = Vector2i(floori(q.x / 20.0), floori(q.y / 20.0))
					var clash = false
					for dx in [-1, 0, 1]:
						for dy in [-1, 0, 1]:
							for o in placed.get(key + Vector2i(dx, dy), []):
								if o.distance_to(q) < 12.5:
									clash = true
					if clash:
						continue
					if not placed.has(key):
						placed[key] = []
					placed[key].append(q)
					# yüz: sokağa doğru (-nrm*sd); Builder yaw: 0 = ön güneye bakar
					var fd = -nrm * sd
					var yaw = rad_to_deg(atan2(-fd.x, -fd.y))
					var fl = [1, 2, 2, 2, 3].pick_random() if dc < 700.0 else [1, 1, 2].pick_random()
					b.house(q.x, q.y, 10, 9, fl, yaw, "konoha", rng)
					var hd = float(b.last_house.get("d", 9.0))
					var fo = Builder.rot(0, -hd * 0.5 - 1.0, yaw)
					if row == 0:
						VL.doors["konoha"].append(_gp(b, q.x + fo.x, q.y + fo.y))
					if count % 11 == 4 and row == 0:
						_door(b, q.x + fo.x, q.y + fo.y, 2.0, "home", "[F] Kapıyı çal (misafir ol)", "", count)
					if count % 3 == 0:
						var lo = Builder.rot(1.1, -hd * 0.5 - 0.2, yaw)
						var gy = b._ground_off(q.x, q.y, 6.0).y
						var lp = b.w(Vector3(q.x + lo.x, gy + 2.55, q.y + lo.y))
						lantern_xf.append(Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)), lp))
					count += 1
	CityDecor.door_lanterns(decor, lantern_xf)
	return count


## Sokak araları (bloklar): merkezde sık, dışa doğru seyrek ev kümeleri; her 4. sıra ara sokak olarak boş kalır.
## Ev en yakın sokağa bakar (yol uzaklığının azaldığı eksen yönü).
static func _fill_blocks(b: Builder, rng: RandomNumberGenerator, occupied: Array, cliff_n: float) -> int:
	var count = 0
	var step = 17.0
	var gx = -R
	var ix = 0
	while gx < R:
		ix += 1
		var gn = -R
		var iz = 0
		while gn < cliff_n - 50.0:
			iz += 1
			var x = gx + rng.randf_range(-1.2, 1.2)
			var n = gn + rng.randf_range(-1.2, 1.2)
			gn += step
			if ix % 4 == 0 or iz % 4 == 0:
				continue  # ara sokak
			var d = Vector2(x, n).length()
			var prob = 0.62 if d < 600.0 else (0.32 if d < 1000.0 else 0.0)
			if rng.randf() > prob or d > R - 40.0:
				continue
			if not _free(x, n, occupied, 6.0) or _on_road(b, x, n, 40.0):
				continue
			# en yakın sokağa bak
			var best = Vector2(0, -1)
			var bd = 1e9
			for dv in [Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]:
				var wp = b.w(Vector3(x + dv.x * 30.0, 0, n + dv.y * 30.0))
				var rd = Game.road_dist(wp.x, wp.z)
				if rd < bd:
					bd = rd
					best = dv
			var yaw = rad_to_deg(atan2(-best.x, -best.y))
			var fl = [1, 2, 2, 3].pick_random() if d < 600.0 else [1, 1, 2].pick_random()
			b.house(x, n, 10, 9, fl, yaw, "konoha", rng)
			count += 1
		gx += step
	return count


## HouseKit 160 m hücrelerini 480 m hücrelerde birleştir (çizim çağrısı sayısı ~9 kat azalır)
static func _merge_house_cells(root: Node3D) -> void:
	var groups := {}
	var olds: Array = []
	for ch in root.get_children():
		if not ch is MultiMeshInstance3D or ch.layers != 2:
			continue
		var mm: MultiMesh = ch.multimesh
		if mm == null or not mm.use_colors:
			continue
		olds.append(ch)
		for i in mm.instance_count:
			var xf = mm.get_instance_transform(i)
			var k = [mm.mesh, Vector2i(floori(xf.origin.x / 480.0), floori(xf.origin.z / 480.0))]
			var ks = "%d|%d|%d" % [mm.mesh.get_instance_id(), k[1].x, k[1].y]
			if not groups.has(ks):
				groups[ks] = {"mesh": mm.mesh, "xf": [], "col": [], "vis": ch.visibility_range_end}
			groups[ks]["xf"].append(xf)
			groups[ks]["col"].append(mm.get_instance_color(i))
	for o in olds:
		o.queue_free()
	for ks in groups:
		var g: Dictionary = groups[ks]
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = g["mesh"]
		mm.instance_count = g["xf"].size()
		for i in g["xf"].size():
			mm.set_instance_transform(i, g["xf"][i])
			mm.set_instance_color(i, g["col"][i])
		var mmi = MultiMeshInstance3D.new()
		mmi.layers = 2
		mmi.multimesh = mm
		mmi.material_override = Props.toon()
		mmi.visibility_range_end = g["vis"] + 300.0
		mmi.visibility_range_end_margin = 80.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		root.add_child(mmi)


## Hokage Kayası: uçurum yüzünü tarayıp beş yüzü yüzeye oyar; tepede seyir yeri
static func _hokage_faces(b: Builder, rock: Dictionary, cliff_n: float, v: Dictionary) -> void:
	var top_abs = float(rock.get("top", float(v["base"]) + 165.0))
	var top = top_abs - b.origin.y
	var x0 = float(rock.get("x0", float(v["x"]) - 825.0)) - float(v["x"])
	var x1 = float(rock.get("x1", float(v["x"]) + 825.0)) - float(v["x"])
	var rc = Color(0.66, 0.6, 0.52)
	var cx = (x0 + x1) * 0.5
	var span = (x1 - x0) * 0.62
	for i in 5:
		var fx = cx - span * 0.5 + span * float(i) / 4.0
		var fy = top * 0.62
		# yüz yüksekliğinde uçurumun ön yüzünü bul
		var fn = cliff_n
		var nn = cliff_n - 140.0
		while nn < cliff_n + 200.0:
			if _gy(b, fx, nn) > fy:
				fn = nn
				break
			nn += 2.0
		var fc = rc.lightened(0.04 + 0.02 * (i % 2))
		var s = top / 165.0 * 1.45
		_stone_head(b, i, Vector3(fx, fy - 8 * s, fn), 92.0 * s, fc.darkened(0.12))
	# tepe seyir yeri (uçurumun hemen arkası)
	var ln = cliff_n + 35.0
	b.box(Vector3(cx, _gy(b, cx, ln) + 0.5, ln), Vector3(70, 1, 24), Color(0.55, 0.45, 0.35), 0, false)
	for k in 8:
		b.box(Vector3(cx - 34 + k * 9.7, _gy(b, cx, ln) + 1.6, ln - 12), Vector3(0.3, 1.2, 0.3), Color(0.42, 0.3, 0.2), 0, false)
	_act(b, cx, ln, 14, "lookout", "[F] Köyü seyret (kayıt)")
	_act(b, cx + 30, ln, 4, "shrine", "[F] Kayadaki küçük sunakta dua et")


## Gerçek karakter kafasından oyulmuş dev taş yüz: her Hokage farklı saç, yüz ve bant
const HOKAGE_LOOKS := [
	{"hair_style": "uzun", "face": "köşeli", "band": null, "beard": false},
	{"hair_style": "dağınık", "face": "keskin", "band": Color.WHITE, "band_style": "head"},
	{"hair_style": "kase", "face": "yuvarlak", "band": Color.WHITE, "band_style": "head", "beard": true},
	{"hair_style": "diken", "face": "normal", "band": Color.WHITE, "band_style": "head"},
	{"hair_style": "atkuyruğu", "face": "ince", "band": Color.WHITE, "band_style": "head", "gender": "f"},
]
static func _stone_head(b: Builder, i: int, at: Vector3, height: float, col: Color) -> void:
	var look = {"gender": "m", "age": "adult", "top_style": "uzun", "vest": null}
	look.merge(HOKAGE_LOOKS[i % HOKAGE_LOOKS.size()], true)
	var hm = CharacterModel.new()
	b.root.add_child(hm)
	hm.setup(look)
	hm.anim.stop()
	hm.set_process(false)
	var sk = hm.skel
	var head_y = sk.get_bone_global_rest(sk.find_bone("Head")).origin.y
	var neck_y = sk.get_bone_global_rest(sk.find_bone("Neck")).origin.y
	var sc = height / 0.3   # kafa ~0.3 m -> hedef yükseklik
	hm.scale = Vector3.ONE * sc
	hm.rotation.y = PI      # yüz güneye (köye) bakar
	# kafa merkezi uçurum yüzüne yarı gömülü
	var wp = b.w(at + Vector3(0, 0, height * 0.18))
	hm.global_position = wp - Vector3(0, (head_y + 0.08) * sc, 0)
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/stone_head.gdshader")
	m.set_shader_parameter("stone", col)
	m.set_shader_parameter("cut_world_y", hm.global_position.y + (neck_y - 0.02) * sc)
	for mi in hm.find_children("*", "MeshInstance3D", true, false):
		var nm = String(mi.name).to_lower()
		if nm.contains("eye") and not nm.contains("brow"):
			mi.visible = false
			continue
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _free(x: float, n: float, occ: Array, pad: float) -> bool:
	for o in occ:
		if absf(x - o[0]) < o[2] + pad and absf(n - o[1]) < o[3] + pad:
			return false
	return true


## Konoha'nın simge A-Un kapısı (güney): iki dev yeşil kanat, çatılı kemer, levha, nöbetçi kulübesi
static func _aun_gate(b: Builder, decor: Node3D) -> void:
	var gn = -R
	var g = b._ground_off(0, gn, 26)
	var y0 = g.x - 1.0
	var green = Color(0.2, 0.44, 0.27)
	var dark = Color(0.13, 0.28, 0.18)
	var s = 1.3
	for sx in [-1.0, 1.0]:
		b.box(Vector3(20 * s * sx, y0 + 17 * s, gn), Vector3(5 * s, 34 * s, 6 * s), dark)
		b.box(Vector3(20 * s * sx, y0 + 1.2, gn), Vector3(7 * s, 2.4, 8 * s), Color(0.55, 0.52, 0.48))
		b.box(Vector3(30 * s * sx, y0 + 14 * s, gn), Vector3(14 * s, 28 * s, 5), Color(0.86, 0.76, 0.58))
		b.box(Vector3(17.2 * s * sx, y0 + 13.5 * s, gn + 8.5 * s), Vector3(1.2 * s, 26 * s, 15 * s), green)
		b.disc(Vector3(16.4 * s * sx, y0 + 16 * s, gn + 8.5 * s), 7.0 * s, 0.3, Color(0.95, 0.92, 0.85), 90.0)
		b.disc(Vector3(16.2 * s * sx, y0 + 16 * s, gn + 8.5 * s), 4.2 * s, 0.3, Color(0.75, 0.15, 0.12), 90.0)
	b.box(Vector3(0, y0 + 32.5 * s, gn), Vector3(46 * s, 3.2 * s, 7 * s), dark)
	b.box(Vector3(0, y0 + 35.0 * s, gn), Vector3(52 * s, 1.4 * s, 11 * s), Color(0.16, 0.33, 0.22), 0, false)
	b.box(Vector3(0, y0 + 36.3 * s, gn), Vector3(46 * s, 1.2 * s, 7 * s), Color(0.12, 0.25, 0.17), 0, false)
	b.box(Vector3(0, y0 + 28.5 * s, gn - 4.0 * s), Vector3(16 * s, 3.6 * s, 0.5), Color(0.95, 0.92, 0.85), 0, false)
	b.box(Vector3(-3.2 * s, y0 + 28.5 * s, gn - 4.0 * s - 0.3), Vector3(2.4 * s, 2.4 * s, 0.1), Color(0.75, 0.15, 0.12), 0, false)
	b.box(Vector3(3.2 * s, y0 + 28.5 * s, gn - 4.0 * s - 0.3), Vector3(2.4 * s, 2.4 * s, 0.1), Color(0.75, 0.15, 0.12), 0, false)
	# nöbetçi kulübesi (içeride sağda)
	var kg = _gy(b, 40, gn + 22)
	b.box(Vector3(40, kg + 1.6, gn + 22), Vector3(10, 3.2, 5), Color(0.62, 0.46, 0.3))
	b.box(Vector3(40, kg + 3.9, gn + 22), Vector3(11.5, 0.5, 6.5), Color(0.2, 0.36, 0.55), 0, false)
	b.box(Vector3(40, kg + 2.4, gn + 19.4), Vector3(8, 0.15, 0.6), Color(0.85, 0.78, 0.6), 0, false)
	_act(b, 40, gn + 17, 5, "gate", "[F] Kapı nöbetçisiyle konuş")
	for sx in [-1.0, 1.0]:
		b.lantern(13 * sx, gn + 16, 4.0 + _gy(b, 13 * sx, gn + 16))
		_site(b, "guard", 15 * sx, gn + 9, {"face": _face(0, -1)})
		CityDecor.banner(decor, _gp(b, 32 * sx, gn + 12), 0.0, Color(0.2, 0.44, 0.27), Color(0.95, 0.92, 0.85))
