class_name BuildKonoha
extends RefCounted
## Konohagakure: Ateş Ülkesi'nin gizli yaprak köyü. Yerel (x=doğu, n=kuzey), merkez (0,0), yarıçap ~1500 m (plato).
## Sokak ağı dünya verisinden (roads.json, kind "street") gelir; evler sokak boylarına dizilir (merkez sık, dış mahalleler seyrek).
## Kuzeyde arazi uçurumu (Hokage Kayası, n≈1170) — yüzler uçuruma oyulur. Girilebilir binalar ("enter" -> Interiors),
## canlı şehir mekânları (VillageLife.sites), süsler (CityDecor).

const VL = preload("res://scripts/world/village_life.gd")
const WALL_H := 28.0

static var R := 1460.0
static var hospital_door := Vector3.ZERO   # ölünce doğma noktası (hastane kapısının önü)
static var _veg_cache := {}


## Kapı etkileşimi: araziye oturan nokta; alias = hikâye hedefi için iç mekândaki asıl tür
const TG = preload("res://scripts/world/training_ground.gd")   # 3. Antrenman Alanı


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
	var _t0 = Time.get_ticks_msec()
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

	# ---- merkez: Hokage Kulesi + tören meydanı (KageHall)
	var tn = 600.0
	var tfront = KageHall.konoha_tower(b, decor, tn)
	_door(b, 0, tn - 37, 5.0, "hokage", "[F] Gir: Hokage Kulesi (Hokage ile görüş, görevler)", "mission_board")
	Interact.items[Interact.items.size() - 1]["vid"] = "konoha"
	KageHall.plaza(b, {"vid": "konoha", "front": tfront, "hw": 58.0, "depth": 74.0, "climate": "green", "stone": Color(0.8, 0.74, 0.64),
		"trim": Color(0.6, 0.52, 0.44), "acc": Color(0.72, 0.18, 0.15), "gate": Color(0.72, 0.18, 0.15), "kanji": "火", "terrace_h": 0.9, "terrace_w": 34.0, "decor": decor})
	occupied.append([0, tn - 18, 116, 98, 25.0])

	# ---- Ninja Akademisi (kulenin batısı) + avlu
	var ax = -540.0; var an = 610.0
	b.yoff = _gy(b, ax, an)
	# anime (refs/konoha/Academy.png): turuncu kiremitli alçak ön kanatlar, ortada kırmızı silindir ana bina (iki kat kiremit etek,
	# tepede üç beyaz boynuz), solunda mavi etekli beyaz sivri kule, çatıda yuvarlak 火 levhası. Düz bej kutu değil.
	var a_tan = Color(0.84, 0.66, 0.42)
	var a_tile = Color(0.92, 0.56, 0.2)
	var a_red = Color(0.74, 0.2, 0.16)
	var a_white = Color(0.93, 0.93, 0.9)
	var a_wood = Color(0.38, 0.26, 0.16)
	# ön kanat (tek kat, sokağa bakan) + arka kanat (iki kat): ikisi de kiremit beşik çatı
	b.box(Vector3(ax, 4.5, an - 8.5), Vector3(100, 9, 17), a_tan)
	b.roof(Vector3(ax, 9.0, an - 8.5), Vector3(104, 4.2, 20.5), a_tile)
	b.box(Vector3(ax, 7.0, an + 8.5), Vector3(100, 14, 17), a_tan.darkened(0.06))
	b.roof(Vector3(ax, 14.0, an + 8.5), Vector3(104, 5.0, 20.5), a_tile.darkened(0.05))
	b.box(Vector3(ax, 9.15, an - 17.2), Vector3(104, 0.5, 0.5), a_wood, 0, false)   # saçak kirişi
	for i in 15:   # ön kanat pencereleri (ahşap çerçeveli) — ortada kapıya yer
		var wx = ax - 46.0 + i * 6.55
		if absf(wx - ax) < 7.0:
			continue
		b.box(Vector3(wx, 5.0, an - 17.08), Vector3(2.6, 2.2, 0.2), a_wood, 0, false)
		b.box(Vector3(wx, 5.0, an - 17.16), Vector3(2.1, 1.7, 0.2), Color(0.5, 0.68, 0.82), 0, false)
		b.box(Vector3(wx, 5.0, an - 17.22), Vector3(0.14, 1.7, 0.2), a_wood, 0, false)
	for i in 9:   # arka kanat üst kat pencereleri (ön çatının üstünden görünür)
		b.box(Vector3(ax - 44.0 + i * 11.0, 11.6, an - 0.08), Vector3(2.4, 1.6, 0.2), Color(0.5, 0.68, 0.82), 0, false)
	# giriş: ahşap kapı, üstünde küçük kiremit saçak ve tabela
	b.box(Vector3(ax, 3.2, an - 17.4), Vector3(7, 6.4, 0.6), a_wood, 0, false)
	b.roof(Vector3(ax, 6.9, an - 18.6), Vector3(11, 1.6, 4.0), a_tile)
	for sx in [-4.8, 4.8]:
		b.box(Vector3(ax + sx, 3.45, an - 20.2), Vector3(0.5, 6.9, 0.5), a_red, 0, false)
	b.box(Vector3(ax, 8.1, an - 20.3), Vector3(9.0, 1.9, 0.25), a_white, 0, false)
	b.kanji(Vector3(ax, 8.1, an - 20.46), "忍者学校", 1.4, Color(0.12, 0.1, 0.1), 0.0)
	# ana bina: kırmızı silindir, ortasında ve üstünde kiremit etek, tepe tamburu
	var mcx = ax + 14.0; var mcn = an + 2.0
	b.cyl(Vector3(mcx, 13.0, mcn), 34.0, 26.0, a_red, true, 24)
	b.cone(Vector3(mcx, 15.5, mcn), 52.0, 9.0, a_tile, 24)
	b.cone(Vector3(mcx, 28.6, mcn), 39.0, 7.2, a_tile, 24)
	b.cyl(Vector3(mcx, 25.1, mcn), 39.4, 0.45, Color(0.6, 0.62, 0.64), false, 24)   # saçak kenar bandı
	b.cyl(Vector3(mcx, 11.1, mcn), 52.4, 0.45, Color(0.6, 0.62, 0.64), false, 24)
	b.cyl(Vector3(mcx, 29.5, mcn), 25.0, 7.0, a_red, false, 24)
	b.cyl(Vector3(mcx, 33.3, mcn), 27.0, 0.8, a_tile.darkened(0.12), false, 24)
	for k in 8:   # silindirin çevresinde beyaz çerçeveli pencereler (üst kat)
		var wa = deg_to_rad(-70.0 + k * 20.0)
		var wpn = Vector3(mcx + sin(wa) * 17.05, 21.5, mcn - cos(wa) * 17.05)
		b.box(wpn, Vector3(2.4, 2.8, 0.5), a_white, rad_to_deg(wa), false)
		b.box(wpn + Vector3(sin(wa), 0, -cos(wa)) * 0.12, Vector3(1.8, 2.2, 0.5), Color(0.22, 0.26, 0.34), rad_to_deg(wa), false)
	# tepe kenarında gri-mavi boynuzlar (anime: çatı çemberinden yükselen dişler; öndeki en uzun)
	var a_horn = Color(0.66, 0.74, 0.8)
	for k in 5:
		var ha = deg_to_rad(-80.0 + k * 40.0)
		var hh = [9.0, 14.0, 17.0, 14.0, 9.0][k]
		b.cone(Vector3(mcx + sin(ha) * 10.6, 33.6 + hh * 0.5, mcn - cos(ha) * 10.6), 2.6, hh, a_horn, 10)
	# çatıdaki yuvarlak 火 levhası (silindirin sol önünde, direk üstünde)
	var plx = mcx - 15.0; var pln = mcn - 12.5
	b.box(Vector3(plx, 14.0, pln + 0.6), Vector3(0.6, 9.0, 0.6), a_wood, 0, false)
	b.disc(Vector3(plx, 20.5, pln + 0.3), 9.4, 0.5, a_red, 0.0, 20)
	b.disc(Vector3(plx, 20.5, pln), 8.2, 0.5, a_white, 0.0, 20)
	b.kanji(Vector3(plx, 20.5, pln - 0.32), "火", 5.2, a_red, 0.0)
	# beyaz sivri kule (solda): mavi-gri etek çatı, koyu bantlar, soğan başlık
	var tx = ax - 22.0; var ttn = an + 3.0
	b.cyl(Vector3(tx, 10.0, ttn), 13.0, 20.0, a_white, true, 16)
	b.cone(Vector3(tx, 18.0, ttn), 23.0, 8.0, Color(0.42, 0.6, 0.7), 16)
	b.cyl(Vector3(tx, 25.5, ttn), 8.0, 11.0, a_white, false, 16)
	for k in 3:
		b.cyl(Vector3(tx, 23.0 + k * 3.0, ttn), 8.5, 0.7, Color(0.62, 0.3, 0.24), false, 16)
	b.cone(Vector3(tx, 34.0, ttn), 8.0, 6.0, a_white, 16)
	b.cyl(Vector3(tx, 35.4, ttn), 3.4, 0.5, Color(0.62, 0.3, 0.24), false, 12)
	b.sphere(Vector3(tx, 38.2, ttn), Vector3(5.4, 5.4, 5.4), Color(0.78, 0.8, 0.84))
	for k in 5:   # sol ön köşede havalandırma boruları
		b.cyl(Vector3(ax - 48.0 + k * 1.9, 9.8 + (k % 2) * 0.7, an - 12.0), 1.3, 2.4 + (k % 2) * 1.4, a_white, false, 10)
	b.yoff = 0.0
	# avlu: duvar + kapı, taş yol, fenerler, antrenman alanı, gölet, salıncak ağacı, oyun parkı, sundurma
	var arng = RandomNumberGenerator.new()
	arng.seed = 4321  # ayrı tohum: köyün geri kalan yerleşimi değişmesin
	AcademyGrounds.dress(b, ax, an - 17.0, 62.0, 78.0, arng, {"vid": "konoha", "climate": "green", "flag": Color(0.2, 0.42, 0.26),
		"kanji": "忍", "flag_kanji": "木", "roof": Color(0.72, 0.18, 0.15), "bw": 100.0, "decor": decor})
	_door(b, ax, an - 19, 5.0, "academy", "[F] Gir: Ninja Akademisi", "academy")
	_site(b, "pigeons", ax + 8, an - 40)
	occupied.append([ax, an - 25, 65, 70, 25.0])

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
	var shops = [[-170.0, -23.0, "pharmacy", "[F] Gir: Eczane", Color(0.3, 0.6, 0.4), "shop_items", 14.0],
		[170.0, -23.0, "weapon_shop", "[F] Gir: Silah Dükkânı", Color(0.15, 0.15, 0.18), "shop_weapons", 14.0],
		[-250.0, -23.0, "tailor", "[F] Gir: Terzi (kıyafet, zırh)", Color(0.35, 0.25, 0.45), "tailor", 14.0],
		[250.0, -23.0, "teahouse", "[F] Gir: Dango ve Çay Evi", Color(0.85, 0.45, 0.55), "teahouse", 14.0],
		[-110.0, 23.0, "bbq", "[F] Gir: Yakiniku Restoranı", Color(0.85, 0.3, 0.2), "bbq", 16.0],
		[230.0, 24.0, "inn", "[F] Gir: Han (konaklama)", Color(0.25, 0.4, 0.6), "inn", 18.0],
		[-30.0, -23.0, "scrolls", "[F] Gir: Parşömenci", Color(0.72, 0.56, 0.22), "shop_scrolls", 14.0]]
	for sh in shops:
		var face_south = sh[1] > 0.0  # caddenin kuzeyindekiler güneye (caddeye) bakar
		var yaw = 0.0 if face_south else 180.0
		b.house_ti = HouseKit.rect_template(rng, sh[6] + 4.0, 14.0)   # köşeli dükkân binası (yuvarlak kule / kubbe değil)
		b.shift_off_road = true
		b.house(sh[0], sh[1], sh[6] + 4.0, 14.0, 2, yaw, "konoha", rng)
		b.shift_off_road = false
		sh = sh.duplicate()
		sh[0] = b.placed_xn.x   # bina caddeden kaydırıldıysa vitrin/kapı/afiş onunla gelir
		sh[1] = b.placed_xn.y
		var dn = -1.0 if face_south else 1.0
		var hd = float(b.last_house.get("d", 11.0))
		SpecialBuildings.shop_front(b, decor, sh[0], sh[1] + dn * hd * 0.5, dn, sh[2], sh[4], sh[6])
		_door(b, sh[0], sh[1] + dn * (hd * 0.5 + 1.2), 3.0, sh[2], sh[3], sh[5])
		CityDecor.banner(decor, _gp(b, sh[0] + 5.0, sh[1] + dn * (hd * 0.5 + 2.4)), 0.0, sh[4], Color(0.98, 0.95, 0.9))
		occupied.append([sh[0], sh[1], sh[6] * 0.5 + 3, 9])
	_site(b, "bar", -95, 22)

	# ---- Ichiraku tarzı ramen tezgâhı (caddeye açık)
	var ix = 70.0; var inn = -30.0
	b.yoff = _gy(b, ix, inn)
	var ich = null  # hayran modeli havada duruyordu/uyumsuzdu: kendi tezgâhımız kullanılıyor
	if ich:
		decor.add_child(ich)
		ich.global_position = _gp(b, ix, inn - 0.6)
		ich.rotation.y = PI
		b._collide(b.w(Vector3(ix, 0.65, inn + 1.5)), Vector3(9, 1.3, 1.2), 0.0)  # tezgâh ve arka duvar çarpışması
		b._collide(b.w(Vector3(ix, 1.8, inn - 2.2)), Vector3(9, 3.6, 4.5), 0.0)
	else:
		_ichiraku_boxes(b, ix, inn)
	b.yoff = 0.0
	var seats = []
	for i in 4:
		seats.append(_gp(b, ix - 3 + i * 2, inn + RAMEN_SEAT_N))
	_act(b, ix, inn + 4, 4, "ramen", "[F] Tezgâha otur, ramen ye (50 Ryō)", {"seats": seats, "seat_face": _face(0, -1)})
	_site(b, "ramen", ix, inn + 3.0, {"back": _gp(b, ix, inn - 0.3), "seats": seats, "face": _face(0, -1)})
	CityDecor.banner(decor, _gp(b, ix + 5.6, inn + 3.2), 0.0, Color(0.85, 0.25, 0.2), Color(0.98, 0.95, 0.9))
	occupied.append([ix, inn, 8, 6])

	# ---- Konoha Hastanesi (doğu): giriş kulesi, kanopi, çatı, yan kanat, ön bahçe
	var hpx = 545.0; var hpn = 230.0
	SpecialBuildings.hospital(b, decor, hpx, hpn, rng)
	_door(b, hpx, hpn - 27.5, 5.0, "hospital", "[F] Gir: Konoha Hastanesi", "hospital")
	hospital_door = _gp(b, hpx, hpn - 33.0)
	occupied.append([hpx + 12, hpn - 26, 64, 58, 25.0])

	# ---- Chunin Sınavı stadyumu (güneydoğu)
	var sx0 = 1050.0; var sn0 = -700.0
	# referans (Konoha stadyumu): nervürlü eğimli dış duvar, tribünler, ağaçlı saha, katlı çatılı ana bina + Kage locası (kuzeyde)
	var srng = RandomNumberGenerator.new()
	srng.seed = 7123
	Stadium.build(b, sx0, sn0, _gy(b, sx0, sn0), Stadium.style_for("konoha"), srng, 0.0)
	_act(b, sx0, sn0 - 84, 8, "chunin_exam", "[F] Chunin Sınavı başvurusu")
	occupied.append([sx0, sn0, 86, 86, 25.0])

	# ---- Uchiha Bölgesi (güneybatı) + Naka Tapınağı
	var ux = -1020.0; var un = -640.0
	var _tu = Time.get_ticks_msec()
	HouseKit.ensure()
	print("SURE sablon ", Time.get_ticks_msec() - _tu, " ms")
	b.wall_ring_at(ux, un, 125.0, 5.0, Color(0.9, 0.88, 0.84), [[45.0, 10.0]])
	for ring in [[95.0, 22], [62.0, 14]]:
		for k in ring[1]:
			var a = k * 360.0 / ring[1]
			var rr: float = ring[0]
			var hxp = ux + rr * sin(deg_to_rad(a)); var hnp = un + rr * cos(deg_to_rad(a))
			b.house(hxp, hnp, 11, 9, 1 + (k % 2), a + 180.0, "konoha", rng)
			if not b.house_ok:
				continue   # ev kurulmadıysa Uchiha arması havada kalmasın
			var fo = Builder.rot(2.4, -float(b.last_house.get("d", 9.0)) * 0.5 - 0.1, a + 180.0)
			b.disc(Vector3(hxp + fo.x, _gy(b, hxp, hnp) + 2.6, hnp + fo.y), 1.4, 0.12, Color(0.8, 0.15, 0.15), a + 180.0, 12)
	b.yoff = _gy(b, ux, un)
	var _tt = Time.get_ticks_msec()
	var tm = null   # hazır tapınak modeli (jp_temple) pakete girmiyor: oyunda görünmez tapınak + çarpışma kalıyordu -> kendi modelimiz
	print("SURE tapinak ", Time.get_ticks_msec() - _tt, " ms")
	if tm != null:
		b.pack_mesh(tm, Vector3(ux, 0, un + 4), 180.0, 1.0, 1.5)
		b._collide(b.w(Vector3(ux, 4.0, un + 4)), Vector3(14, 8, 14), 0.0)
		for sx2 in [-7.0, 7.0]:
			b.prop("stone_lamp", Vector3(ux + sx2, 0, un - 20), 0.0, 2.4, 0.4)
	else:
		# anime (refs/konoha/Naka_Shrine.png): taş kaide, krem panolu koyu kırmızı ahşap çatkılı ana salon, gri-yeşil geniş
		# saçaklı çatı + önde üçgen alınlıklı giriş saçağı, mahya üstünde kütükler, iki yanda alçak kafesli kanatlar,
		# önde gri kaideli büyük kırmızı torii (çift kiriş, ortasında Uchiha yelpazeli levha), taş fenerler.
		var n_wood = Color(0.55, 0.24, 0.22)
		var n_cream = Color(0.86, 0.82, 0.68)
		var n_roof = Color(0.5, 0.52, 0.42)
		var n_stone = Color(0.62, 0.63, 0.6)
		var n_lat = Color(0.4, 0.26, 0.22)
		b.box(Vector3(ux, 0.5, un - 1.0), Vector3(58, 1.0, 22), n_stone)                 # kaide
		b.box(Vector3(ux, 0.25, un - 13.0), Vector3(12, 0.5, 2.4), n_stone.darkened(0.08))   # basamak
		# ana salon
		b.box(Vector3(ux, 5.0, un), Vector3(18, 8, 12), n_cream)
		for i in 5:
			b.box(Vector3(ux - 9.0 + i * 4.5, 5.0, un - 6.05), Vector3(0.5, 8.0, 0.3), n_wood, 0, false)
		for yy in [1.3, 5.2, 8.8]:
			b.box(Vector3(ux, yy, un - 6.05), Vector3(18.2, 0.45, 0.3), n_wood, 0, false)
		for sxk in [-1.0, 1.0]:   # salonun ön yüzünde kafesli pencereler
			b.box(Vector3(ux + sxk * 6.7, 3.3, un - 6.1), Vector3(3.6, 3.2, 0.2), n_lat, 0, false)
		b.roof(Vector3(ux, 9.0, un), Vector3(27, 6.5, 19), n_roof)
		b.box(Vector3(ux, 9.05, un - 9.4), Vector3(27.2, 0.4, 0.5), n_roof.darkened(0.25), 0, false)
		b.box(Vector3(ux, 15.6, un), Vector3(20, 0.9, 1.4), n_wood.darkened(0.25), 0, false)   # mahya kirişi
		for i in 5:   # mahya kütükleri
			b.box(Vector3(ux - 7.0 + i * 3.5, 16.4, un), Vector3(0.8, 0.8, 3.4), Color(0.72, 0.62, 0.48), 0, false)
		# giriş saçağı: iki direk, üçgen alınlık, yelpazeli levha, kafesli çift kapı, çan ipi
		for sxk in [-1.0, 1.0]:
			b.box(Vector3(ux + sxk * 3.6, 3.6, un - 10.0), Vector3(0.6, 5.2, 0.6), n_wood)
		b.box(Vector3(ux, 6.4, un - 8.2), Vector3(8.6, 0.5, 4.6), n_wood, 0, false)
		b.roof(Vector3(ux, 6.6, un - 8.4), Vector3(4.4, 3.4, 10.4), n_roof.darkened(0.06), 90.0)
		b.box(Vector3(ux, 7.9, un - 10.75), Vector3(2.6, 1.2, 0.2), n_cream, 0, false)
		b.disc(Vector3(ux, 8.05, un - 10.9), 0.8, 0.12, Color(0.8, 0.16, 0.14), 0.0, 12)
		b.box(Vector3(ux, 7.72, un - 10.92), Vector3(0.84, 0.36, 0.12), Color(0.95, 0.93, 0.88), 0, false)
		b.box(Vector3(ux, 3.2, un - 6.2), Vector3(4.6, 4.4, 0.3), n_lat, 0, false)
		for k in 6:
			b.box(Vector3(ux - 2.0 + k * 0.8, 3.2, un - 6.4), Vector3(0.1, 4.2, 0.1), n_wood.lightened(0.15), 0, false)
		b.box(Vector3(ux, 3.2, un - 6.42), Vector3(0.18, 4.4, 0.12), n_wood, 0, false)
		b.box(Vector3(ux, 4.6, un - 9.9), Vector3(0.12, 3.0, 0.12), Color(0.8, 0.74, 0.5), 0, false)   # çan ipi
		# yan kanatlar: alçak, kafesli üst bant + krem alt pano, kendi çatısı
		for sxk in [-1.0, 1.0]:
			var wxk = ux + sxk * 19.0
			b.box(Vector3(wxk, 3.2, un + 1.0), Vector3(20, 4.4, 9), n_cream)
			b.box(Vector3(wxk, 3.9, un - 3.56), Vector3(20, 2.2, 0.2), n_lat, 0, false)
			for i in 5:
				b.box(Vector3(wxk - 10.0 + i * 5.0, 3.2, un - 3.6), Vector3(0.4, 4.4, 0.3), n_wood, 0, false)
			for yy in [1.3, 2.7, 5.2]:
				b.box(Vector3(wxk, yy, un - 3.6), Vector3(20.2, 0.3, 0.3), n_wood, 0, false)
			b.roof(Vector3(wxk, 5.4, un + 1.0), Vector3(23, 3.0, 13), n_roof.darkened(0.04))
			b.prop("stone_lamp", Vector3(ux + sxk * 6.2, 1.0, un - 10.5), 0.0, 2.0, 0.4)
		# torii
		var tn0 = un - 19.0
		for sxk in [-1.0, 1.0]:
			b.cyl(Vector3(ux + sxk * 6.4, 1.8, tn0), 1.5, 3.6, n_stone.lightened(0.12), true, 12)
			b.cyl(Vector3(ux + sxk * 6.4, 8.2, tn0), 1.15, 9.4, n_wood.lightened(0.12), true, 12)
		b.box(Vector3(ux, 13.3, tn0), Vector3(19.5, 1.0, 1.3), n_wood.lightened(0.12), 0, false)
		b.box(Vector3(ux, 10.4, tn0), Vector3(16.0, 0.8, 0.9), n_wood.lightened(0.12), 0, false)
		b.box(Vector3(ux, 11.85, tn0 - 0.1), Vector3(2.6, 2.0, 0.5), Color(0.8, 0.72, 0.52), 0, false)
		b.disc(Vector3(ux, 12.05, tn0 - 0.4), 1.2, 0.12, Color(0.8, 0.16, 0.14), 0.0, 12)
		b.box(Vector3(ux, 11.55, tn0 - 0.42), Vector3(1.24, 0.5, 0.12), Color(0.95, 0.93, 0.88), 0, false)
		b.box(Vector3(ux, 11.2, tn0 - 0.42), Vector3(0.16, 0.5, 0.12), Color(0.95, 0.93, 0.88), 0, false)
	b.yoff = 0.0
	print("SURE uchiha ", Time.get_ticks_msec() - _tu, " ms")
	_act(b, ux, un - 13, 5, "enter", "[F] Gir: Naka Tapınağı", {"room": "naka_shrine", "vid": "konoha", "out": _gp(b, ux, un - 13)})
	_act(b, ux + 8, un - 13, 3, "shrine", "[F] Tapınakta dua et (kısa kutsama)")
	occupied.append([ux, un, 128, 128])

	# ---- Hyuga Konağı (batı)
	var yx = -1050.0; var yn = 250.0
	b.yoff = _gy(b, yx, yn)
	b.wall_rect(yx, yn, 150, 110, 5.0, Color(0.9, 0.88, 0.82), 14.0)
	# geleneksel konak (animede Hyūga evi: beyaz sıvalı, koyu ahşap çatkılı, gri kiremitli, geniş verandalı, ahşap dōjō zeminli avlu)
	var h_wall = Color(0.93, 0.91, 0.85)
	var h_wood = Color(0.34, 0.24, 0.17)
	var h_roof = Color(0.3, 0.31, 0.36)
	var h_floor = Color(0.62, 0.46, 0.3)
	# ana ev: yükseltilmiş ahşap zemin + veranda, çatkılı duvar, iki kademeli çatı
	b.box(Vector3(yx, 0.6, yn + 13), Vector3(88, 1.2, 40), h_floor)
	b.box(Vector3(yx, 5.2, yn + 15), Vector3(78, 8, 30), h_wall)
	for i in 14:
		b.box(Vector3(yx - 39.0 + i * 6.0, 5.2, yn - 0.05), Vector3(0.45, 8.0, 0.3), h_wood, 0, false)
		if i < 13 and i != 6:   # shōji kayar kapılar (kâğıt panolar)
			b.box(Vector3(yx - 36.0 + i * 6.0, 3.6, yn - 0.1), Vector3(4.6, 4.4, 0.16), Color(0.97, 0.95, 0.86), 0, false)
			b.box(Vector3(yx - 36.0 + i * 6.0, 3.6, yn - 0.2), Vector3(0.1, 4.4, 0.1), h_wood, 0, false)
			b.box(Vector3(yx - 36.0 + i * 6.0, 3.6, yn - 0.2), Vector3(4.6, 0.1, 0.1), h_wood, 0, false)
	for yy in [1.3, 6.0, 9.1]:
		b.box(Vector3(yx, yy, yn - 0.05), Vector3(78.2, 0.4, 0.3), h_wood, 0, false)
	b.box(Vector3(yx, 3.8, yn - 0.15), Vector3(5.0, 5.0, 0.3), h_wood.lightened(0.1), 0, false)   # ana kapı
	for i in 9:   # veranda direkleri
		b.box(Vector3(yx - 42.0 + i * 10.5, 3.7, yn - 6.2), Vector3(0.5, 5.0, 0.5), h_wood)
	b.box(Vector3(yx, 6.3, yn - 3.5), Vector3(90, 0.4, 7.5), h_roof.darkened(0.1), 0, false, Vector3(-8.0, 0, 0))   # veranda saçağı
	b.roof(Vector3(yx, 9.2, yn + 15), Vector3(90, 5.0, 40), h_roof)
	b.box(Vector3(yx, 14.3, yn + 15), Vector3(40, 3.0, 14), h_wall)
	b.roof(Vector3(yx, 15.8, yn + 15), Vector3(48, 5.5, 22), h_roof.darkened(0.05))
	b.box(Vector3(yx, 21.4, yn + 15), Vector3(44, 0.7, 1.2), h_roof.darkened(0.3), 0, false)
	b.box(Vector3(yx, 0.3, yn - 8.5), Vector3(8.0, 0.6, 2.0), Color(0.66, 0.66, 0.64))   # veranda basamağı
	# yan ev (misafir / yan kol): aynı dil
	b.box(Vector3(yx + 48, 4.0, yn - 22), Vector3(28, 7, 20), h_wall)
	for i in 6:
		b.box(Vector3(yx + 34.0 + i * 5.6, 4.0, yn - 32.05), Vector3(0.4, 7.0, 0.3), h_wood, 0, false)
	for yy in [1.0, 4.6, 7.3]:
		b.box(Vector3(yx + 48, yy, yn - 32.05), Vector3(28.2, 0.35, 0.3), h_wood, 0, false)
	b.roof(Vector3(yx + 48, 7.5, yn - 22), Vector3(33, 5, 25), h_roof)
	# dōjō avlusu: ahşap antrenman zemini + kenarında vuruş kütükleri, sancakta klan arması
	b.box(Vector3(yx - 25, 0.2, yn - 28), Vector3(50, 0.4, 30), h_floor.lightened(0.08))
	for k in 9:
		b.box(Vector3(yx - 47.0 + k * 5.5, 0.42, yn - 28), Vector3(0.12, 0.04, 30.0), h_floor.darkened(0.2), 0, false)
	for k in 4:
		b.cyl(Vector3(yx - 46.0 + k * 4.0, 1.5, yn - 45.5), 0.6, 2.4, h_wood.lightened(0.2), true, 8)
		b.cyl(Vector3(yx - 46.0 + k * 4.0, 2.0, yn - 45.5), 0.72, 0.5, Color(0.86, 0.8, 0.62), false, 8)
	# arma: beyaz diskte alev kıvrımı (sade: disk + koyu halka + orta nokta), ana kapının üstünde
	b.disc(Vector3(yx, 7.6, yn - 0.3), 2.4, 0.2, h_wood, 0.0, 16)
	b.disc(Vector3(yx, 7.6, yn - 0.4), 2.0, 0.2, Color(0.97, 0.96, 0.92), 0.0, 16)
	b.disc(Vector3(yx, 7.6, yn - 0.5), 0.8, 0.2, Color(0.75, 0.2, 0.16), 0.0, 12)
	# dış kapı: iki kalın direk, kiremit çatı, kiriş
	for sxk in [-1.0, 1.0]:
		b.box(Vector3(yx + sxk * 7.2, 3.6, yn - 55.0), Vector3(1.2, 7.2, 1.6), h_wood)
	b.box(Vector3(yx, 6.6, yn - 55.0), Vector3(16.5, 0.7, 1.2), h_wood, 0, false)
	b.roof(Vector3(yx, 7.2, yn - 55.0), Vector3(20.0, 2.6, 6.0), h_roof)
	# bahçe: taş yol (dış kapıdan verandaya), taş fenerler, gölet + kayalar, çam / akçaağaç
	b.box(Vector3(yx, 0.06, yn - 31.0), Vector3(4.0, 0.12, 44.0), Color(0.7, 0.69, 0.66), 0, false)
	for k in 4:
		for sxk in [-1.0, 1.0]:
			b.prop("stone_lamp", Vector3(yx + sxk * 4.0, 0.0, yn - 14.0 - k * 10.0), 0.0, 2.0, 0.4)
	KageHall._water_disc(b, Vector3(yx + 22.0, 0.12, yn - 40.0), 16.0)
	for k in 7:
		var ra = k * 51.0
		var rq = Builder.rot(0, 8.6, ra)
		b.sphere(Vector3(yx + 22.0 + rq.x, 0.5, yn - 40.0 + rq.y), Vector3(2.2 + (k % 3) * 0.7, 1.4 + (k % 2) * 0.5, 2.0), Color(0.5, 0.5, 0.48), 8, true)
	KageHall.tree(b, yx + 32.0, yn - 44.0, 0.0, "green", rng, 1.2)
	KageHall.tree(b, yx - 60.0, yn - 5.0, 0.0, "green", rng, 1.4)
	KageHall.tree(b, yx + 62.0, yn + 30.0, 0.0, "green", rng, 1.3)
	KageHall.tree(b, yx - 58.0, yn + 38.0, 0.0, "green", rng, 1.1)
	b.yoff = 0.0
	_act(b, yx, yn - 56, 6, "hyuga", "[F] Hyuga Konağı")
	occupied.append([yx, yn, 80, 60, 25.0])

	# ---- ANBU karargâhı (uçurumun dibinde, karanlık)
	var anx = -480.0; var ann = cliff_n - 110.0
	SpecialBuildings.anbu(b, decor, anx, ann)
	b.interact(Vector3(anx, _gy(b, anx, ann - 22), ann - 22), 4.0, "enter", "[F] Gir: Anbu Karargâhı", {"room": "secret_hq", "vid": "konoha", "alias": "anbu", "out": _gp(b, anx, ann - 22)})
	occupied.append([anx, ann + 2, 40, 30, 25.0])

	# ---- Antrenman Alanı 3 (TrainingGround: çan kütükleri, Anıt Taşı, şelaleli gölet, dere + köprü, hedefler, parkur, sakura...)
	var tgx = 1050.0; var tgn = 560.0
	TG.road_check = func(x: float, n: float) -> bool: return _on_road(b, x, n, 12.0)
	TG.build(b, decor, tgx, tgn, rng, func(x: float, n: float) -> float: return _gy(b, x, n), _act, _site)
	occupied.append([tgx, tgn, 72, 58, 25.0])

	# ---- oyuncunun evi (başlangıç noktasının yakınında) + inşaat alanı + park
	b.house(-150, 110, 10, 9, 2, 0, "konoha", rng)
	var phd = float(b.last_house.get("d", 9.0))
	b.box(Vector3(-150, _gy(b, -150, 110) + 2.6, 110 - phd * 0.5 - 0.1), Vector3(1.6, 0.5, 0.1), Color(0.9, 0.85, 0.7), 0, false)
	_door(b, -150, 110 - phd * 0.5 - 1.0, 2.6, "home_player", "[F] Evine gir (uyu, kaydet)")
	Interact.items[-1]["home_of"] = "konoha"
	Interact.items[-1]["vid"] = "konoha"
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

	# ---- Naka Nehri: Hokage Kayası'nın batısındaki şelaleden doğar, Akademi'nin batısından, Hyūga ile park arasından,
	# Uchiha Bölgesi'nin kıyısından geçip güneybatıda surdan çıkar (evlerden önce: evler kanalın üstüne konmaz)
	var naka: Array = []
	var ctrl = [Vector2(-640, cliff_n - 14.0), Vector2(-690, 960), Vector2(-760, 720), Vector2(-805, 470), Vector2(-830, 200),
		Vector2(-845, -60), Vector2(-865, -330), Vector2(-875, -540), Vector2(-930, -820), Vector2(-1010, -1000), Vector2(-1060, R * -0.74 - 20.0)]
	for i in ctrl.size() - 1:   # Catmull-Rom: yumuşak kıvrım
		var p0: Vector2 = ctrl[maxi(0, i - 1)]
		var p1: Vector2 = ctrl[i]
		var p2: Vector2 = ctrl[i + 1]
		var p3: Vector2 = ctrl[mini(ctrl.size() - 1, i + 2)]
		for k in 8:
			var t = k / 8.0
			naka.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	naka.append(ctrl[ctrl.size() - 1])
	var crng = RandomNumberGenerator.new()
	crng.seed = 777
	Canal.build(b, naka, 9.0, func(x, n): return _on_road(b, x, n, 0.5), crng)
	_naka_falls(b, decor, ctrl[0], cliff_n)

	# ---- evler: sokak boylarına dizili (merkezde 3 sıra, dışarıda 1-2 sıra), her biri sokağa bakar
	b.view_dist = 1500.0
	_path_doors.clear()
	var count = _street_houses(b, v, rng, occupied, decor, cliff_n)
	count += _fill_blocks(b, rng, occupied, cliff_n)
	_house_paths(b, c0_paths(v))
	# dış mahalleler: sokaklardan uzak boşluklara ağaç kümeleri (orman köyü hissi)
	var trees = 0
	for k in 4800:   # orman köyü: dış mahallelerde bol, uzun ağaç (eskiden seyrek ve kısaydı)
		var a = rng.randf() * TAU
		var rr = sqrt(rng.randf()) * (R - 50.0)   # sura yaslanmasın
		var tx2 = sin(a) * rr; var tn2 = cos(a) * rr
		if tn2 > cliff_n - 30.0 or rr < 250.0:
			continue
		if _on_road(b, tx2, tn2, 26.0) or not _free(tx2, tn2, occupied, 6.0):
			continue
		b.tree(tx2, tn2, rng.randf_range(1.6, 2.9), rng, _gy(b, tx2, tn2))
		occupied.append([tx2, tn2, 4.0, 4.0])
		trees += 1
		# ağaç dibi: çalı, çiçek öbeği, kaya (çevre detayı)
		for q in rng.randi_range(1, 3):
			var bx2 = tx2 + rng.randf_range(-6.0, 6.0)
			var bn2 = tn2 + rng.randf_range(-6.0, 6.0)
			if _on_road(b, bx2, bn2, 5.0):
				continue
			var vt = [18, 18, 12, 4][rng.randi() % 4]
			if not _veg_cache.has(vt):
				_veg_cache[vt] = Props.vegetation_mesh(vt)
			b.pack_mesh(_veg_cache[vt], Vector3(bx2, _gy(b, bx2, bn2), bn2), rng.randf() * 360.0, rng.randf_range(0.7, 1.3) * (0.5 if vt == 4 else 1.0), 0.5)
	b.finish()
	_merge_house_cells(b.root)
	print("Konoha: ", count, " ev, ", trees, " ağaç  toplam ", Time.get_ticks_msec() - _t0, " ms")


## Sokak boyunca ev dizileri. Çakışma: dolu alanlar, başka sokaklar, önceki evler.
static func _street_houses(b: Builder, v: Dictionary, rng: RandomNumberGenerator, occupied: Array, decor: Node3D, cliff_n: float) -> int:
	# Bitişik nizam: her caddenin iki yanında evler gerçek genişlikleriyle yan yana (0.3-1 m ara), 4-6 evde bir dar ara sokak;
	# arka sıralar sırt sırta (15.5 m bant). Animedeki gibi dip dibe şehir dokusu.
	HouseKit.ensure()
	var c = Vector2(float(v["x"]), float(v["y"]))
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
		if L < 8.0:
			continue
		var dir = (e - a) / L
		var nrm = Vector2(-dir.y, dir.x)
		var dc0 = ((a + e) * 0.5).length()
		# cadde üstü fener dizileri (her ~32 m'de karşıdan karşıya) + gerçek ışık noktası
		var lt = 16.0
		while lt < L - 8.0 and dc0 < 1150.0:
			var lp = a + dir * lt
			lt += 32.0
			if lp.length() > R - 40.0 or lp.y > cliff_n - 45.0:
				continue
			CityDecor.lantern_string(decor, _gp(b, lp.x + nrm.x * 8.5, lp.y + nrm.y * 8.5), _gp(b, lp.x - nrm.x * 8.5, lp.y - nrm.y * 8.5), 6,
				[Color(0.95, 0.3, 0.25), Color(1.0, 0.92, 0.75), Color(0.95, 0.3, 0.25)])
			Lights.add(_gp(b, lp.x, lp.y) + Vector3.UP * 5.6)
		var rows = 2 if dc0 > 1100.0 else (3 if dc0 > 650.0 else 4)
		for sd in [-1.0, 1.0]:
			for row in rows:
				var t = 9.0 + rng.randf_range(0.0, 4.0) * row
				var run = 0
				var alley_at = rng.randi_range(4, 6)
				while t < L - 8.0:
					var ti = _pick_template(rng, row == 0)
					var tw = float(HouseKit.templates[ti]["w"])
					var td = float(HouseKit.templates[ti]["d"])
					if t + tw > L - 4.0:
						break
					var off = 7.5 + row * 15.5 + td * 0.5
					var q = a + dir * (t + tw * 0.5) + nrm * sd * off
					var placed = false
					if q.length() < R - 35.0 and q.y < cliff_n - 45.0 and _free(q.x, q.y, occupied, 2.0) and not _on_road(b, q.x, q.y, td * 0.5 + 1.0) \
							and _lot_free(b, q, dir, tw, td):
						var fd = -nrm * sd
						var yaw = rad_to_deg(atan2(-fd.x, -fd.y))
						b.house_ti = ti
						b.house(q.x, q.y, tw + 0.1, td + 0.1, 3, yaw, "konoha", rng)
						placed = b.house_ok   # yol yüzünden atlandıysa kapı/fener eklenmez (sokak ortasında binasız kapı kalıyordu)
						if placed:
							q = b.placed_xn   # komşuyla çakışmamak için kaydırıldıysa kapı/fener onunla gelir
						var fo = Builder.rot(0, -td * 0.5 - 1.0, yaw)
						if placed:
							_path_doors.append(_gp(b, q.x + fo.x, q.y + fo.y))
						if row == 0 and placed:
							VL.doors["konoha"].append(_gp(b, q.x + fo.x, q.y + fo.y))
							if count % 11 == 4:
								_door(b, q.x + fo.x, q.y + fo.y, 2.0, "home", "[F] Kapıyı çal (misafir ol)", "", count)
							if count % 3 == 0:
								var lo = Builder.rot(1.1, -td * 0.5 - 0.2, yaw)
								var gy = b._ground_off(q.x, q.y, 6.0).y
								lantern_xf.append(Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)), b.w(Vector3(q.x + lo.x, gy + 2.55, q.y + lo.y))))
						count += 1
					t += tw + rng.randf_range(1.8, 3.0) if placed else 4.0   # evler arası dar geçit (dip dibe değil)
					run += 1
					if run >= alley_at:   # dar ara sokak
						t += rng.randf_range(2.8, 4.0)
						run = 0
						alley_at = rng.randi_range(4, 6)
	CityDecor.door_lanterns(decor, lantern_xf)
	return count


static var _path_doors: Array = []   # her evin kapı önü (dünya)


static func c0_paths(v: Dictionary) -> Vector2:
	return Vector2(float(v["x"]), float(v["y"]))


## Her evin kapısı sokağa bağlanır: evlerin arasından dolanan toprak patikalar (çimin ortasında yolsuz ev kalmasın).
## 3 m'lik ızgarada caddelerden dışarı doğru tek bir yayılım (engel: bütün yapıların tabanı); her kapı kendi izini
## caddeye kadar geri izler, izler birleşince ortak ara sokak olur.
static func _house_paths(b: Builder, vc: Vector2) -> void:
	var t0 = Time.get_ticks_msec()
	var CELL = 3.0
	var N = int(ceil(2.0 * (R + 30.0) / CELL))
	var ox = b.origin.x - N * CELL * 0.5
	var oz = b.origin.z - N * CELL * 0.5
	var blocked = PackedByteArray()
	blocked.resize(N * N)
	# yapı tabanları (yönlü dikdörtgen + 0.7 m pay)
	for key in b.solids:
		for rec in b.solids[key]:
			var hw: float = float(rec[2]) - 0.1
			var hd: float = float(rec[3]) - 0.1
			var a: float = rec[4]
			var ca = cos(a); var sa = sin(a)
			var ext = absf(ca) * hw + absf(sa) * hd
			var ezt = absf(sa) * hw + absf(ca) * hd
			var i0 = clampi(int((float(rec[0]) - ext - ox) / CELL), 0, N - 1)
			var i1 = clampi(int((float(rec[0]) + ext - ox) / CELL), 0, N - 1)
			var j0 = clampi(int((float(rec[1]) - ezt - oz) / CELL), 0, N - 1)
			var j1 = clampi(int((float(rec[1]) + ezt - oz) / CELL), 0, N - 1)
			for j in range(j0, j1 + 1):
				for i in range(i0, i1 + 1):
					var dx = ox + (i + 0.5) * CELL - float(rec[0])
					var dz = oz + (j + 0.5) * CELL - float(rec[1])
					var lx = absf(ca * dx - sa * dz)
					var lz = absf(sa * dx + ca * dz)
					if lx < hw and lz < hd:
						# 2 = yapının içi (geçilmez), 1 = duvar dibi (yalnız başka yol yoksa: evlerin arasındaki dar geçit)
						blocked[j * N + i] = 2 if (lx < hw - 1.6 and lz < hd - 1.6) else maxi(blocked[j * N + i], 1)
	# kaynak: cadde orta çizgileri
	var parent = PackedInt32Array()
	parent.resize(N * N)
	parent.fill(-2)   # -2 görülmedi, -1 kaynak
	var depth = PackedInt32Array()
	depth.resize(N * N)
	var q = PackedInt32Array()
	for rd in Game.roads:
		if rd["kind"] != "street":
			continue
		var pts: PackedVector2Array = rd["pts"]
		for k in range(pts.size() - 1):
			if (pts[k] - vc).length() > R + 60.0 and (pts[k + 1] - vc).length() > R + 60.0:
				continue
			var L = pts[k].distance_to(pts[k + 1])
			var steps = int(L / 2.0) + 1
			for sI in steps + 1:
				var m = pts[k].lerp(pts[k + 1], float(sI) / steps)
				var i = int((m.x - ox) / CELL)
				var j = int((-m.y - oz) / CELL)
				if i < 0 or j < 0 or i >= N or j >= N:
					continue
				var id = j * N + i
				if parent[id] == -2:
					parent[id] = -1
					blocked[id] = 0
					q.append(id)
	# yayılım (8 komşu, en çok 55 hücre ≈ 165 m)
	var head = 0
	var offs = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]]
	var tight = PackedInt32Array()   # [hücre, geldiği] çiftleri: açık yoldan ulaşılamayınca dar geçitler açılır
	while head < q.size() or not tight.is_empty():
		if head >= q.size():
			var tk = 0
			while tk < tight.size():
				if parent[tight[tk]] == -2:
					parent[tight[tk]] = tight[tk + 1]
					depth[tight[tk]] = depth[tight[tk + 1]] + 1
					q.append(tight[tk])
				tk += 2
			tight = PackedInt32Array()
			continue
		var id = q[head]
		head += 1
		var dd = depth[id]
		if dd >= 75:
			continue
		var i = id % N
		var j = id / N
		for o in offs:
			var ni = i + o[0]
			var nj = j + o[1]
			if ni < 0 or nj < 0 or ni >= N or nj >= N:
				continue
			var nid = nj * N + ni
			if parent[nid] != -2 or blocked[nid] == 2:
				continue
			if o[0] != 0 and o[1] != 0 and (blocked[j * N + ni] == 2 or blocked[nj * N + i] == 2):
				continue   # köşeden sıkışarak geçme
			if blocked[nid] == 1:
				if o[0] == 0 or o[1] == 0:
					tight.append(nid)
					tight.append(id)
				continue
			parent[nid] = id
			depth[nid] = dd + 1
			q.append(nid)
	# her kapıdan caddeye geri iz
	var painted = PackedByteArray()
	painted.resize(N * N)
	var RMc = preload("res://scripts/world/road_map.gd")
	var lanes = 0
	var linked = 0
	var orphan = 0
	for dpos in _path_doors:
		var dp: Vector3 = dpos
		if Game.road_dist(dp.x, dp.z) < 11.0:
			linked += 1
			continue   # kapı zaten caddede
		var ci = int((dp.x - ox) / CELL)
		var cj = int((dp.z - oz) / CELL)
		var start = -1
		var bd = 1e9
		for dj in range(-2, 3):
			for di in range(-2, 3):
				var ni = ci + di
				var nj = cj + dj
				if ni < 0 or nj < 0 or ni >= N or nj >= N:
					continue
				var nid = nj * N + ni
				if parent[nid] == -2:
					continue
				var d2 = Vector2(ox + (ni + 0.5) * CELL - dp.x, oz + (nj + 0.5) * CELL - dp.z).length() + depth[nid] * 0.01
				if d2 < bd:
					bd = d2
					start = nid
		if start < 0:
			orphan += 1
			continue
		linked += 1
		var prev = Vector2(dp.x, dp.z)
		var cur = start
		var run_a = prev
		var run_dir = Vector2.ZERO
		var guard = 0
		while cur >= 0 and guard < 80:
			guard += 1
			var pt = Vector2(ox + (cur % N + 0.5) * CELL, oz + (cur / N + 0.5) * CELL)
			var dir = (pt - prev).normalized()
			if run_dir != Vector2.ZERO and dir.dot(run_dir) < 0.999:
				RMc.add_lane(run_a, prev, 1.25, true)
				lanes += 1
				run_a = prev
			run_dir = dir
			prev = pt
			if painted[cur] == 1:
				break   # başka bir evin patikasına bağlandı
			painted[cur] = 1
			cur = parent[cur]
		if prev != run_a:
			RMc.add_lane(run_a, prev, 1.25, true)
			lanes += 1
	print("Konoha patika: ", _path_doors.size(), " kapı, ", linked, " bağlı, ", orphan, " ulaşılamadı, ", lanes, " parça, ", Time.get_ticks_msec() - t0, " ms")


## Bitişik dizilim için şablon: cadde önünde dükkân / kasaba evi ağırlıklı, arkada apartman ağırlıklı
static func _pick_template(rng: RandomNumberGenerator, front: bool) -> int:
	var n = HouseKit.templates.size()
	for k in 6:
		var ti = rng.randi() % n
		var t: Dictionary = HouseKit.templates[ti]
		if float(t["d"]) > 15.2:
			continue
		if int(t.get("arch", 0)) >= 5 and rng.randf() < 0.55:
			continue   # yuvarlak kuleler simge gibi seyrek kalsın
		var h = float(t["h"])
		if front and h > 19.0 and rng.randf() < 0.5:
			continue   # cadde önü biraz daha alçak
		if not front and h < 9.0 and rng.randf() < 0.5:
			continue
		return ti
	return rng.randi() % n


## Arsa boş mu: dikdörtgenin merkezi + dört köşesi çevresinde (diğer evler, meydanlar, kanal setleri)
static func _lot_free(b: Builder, q: Vector2, dir: Vector2, tw: float, td: float) -> bool:
	var nr = Vector2(-dir.y, dir.x)
	# 4x3 örnek ızgarası (köşe + kenar ortaları + iç): aradaki ağaç / kanal / yapı kaçmasın
	var pts: Array = []
	for i in 4:
		for j in 3:
			pts.append(dir * lerpf(-tw * 0.5 + 0.9, tw * 0.5 - 0.9, i / 3.0) + nr * lerpf(-td * 0.5 + 0.9, td * 0.5 - 0.9, j / 2.0))
	for o in pts:
		var p = q + o
		var wq = b.w(Vector3(p.x, 0, p.y))
		if not b.area_free(Vector2(wq.x, wq.z), 0.7):
			return false
	return true


## Sokak araları (bloklar): cadde sıralarının arkasında kalan iç alan, 16 m ızgarada sırt sırta evlerle dolar;
## her 4. sıra ara sokak olarak boş kalır. Ev en yakın sokağa bakar.
static func _fill_blocks(b: Builder, rng: RandomNumberGenerator, occupied: Array, cliff_n: float) -> int:
	var count = 0
	var step = 16.0
	var gx = -R
	var ix = 0
	while gx < R:
		ix += 1
		var gn = -R
		var iz = 0
		while gn < cliff_n - 50.0:
			iz += 1
			var x = gx
			var n = gn
			gn += step
			if ix % 4 == 0 or iz % 5 == 0:
				continue  # ara sokak
			var d = Vector2(x, n).length()
			var prob = 0.8 if d < 700.0 else (0.72 if d < 1100.0 else 0.55)
			if d > R - 40.0:
				continue
			if rng.randf() > prob:
				# boş kalan blok hücresi: avlu ağaç kümesi (bloklar arası yeşillik; ızgara gibi çıplak durmasın)
				if _free(x, n, occupied, 2.0) and not _on_road(b, x, n, 9.0):
					var wq0 = b.w(Vector3(x, 0, n))
					if b.area_free(Vector2(wq0.x, wq0.z), 6.0):
						for k in rng.randi_range(2, 4):
							var tx = x + rng.randf_range(-5.0, 5.0)
							var tn = n + rng.randf_range(-5.0, 5.0)
							b.tree(tx, tn, rng.randf_range(0.9, 1.4), rng, _gy(b, tx, tn))
						for k in rng.randi_range(1, 3):   # ağaç diplerinde çiçek öbekleri
							var fx = x + rng.randf_range(-6.0, 6.0)
							var fn = n + rng.randf_range(-6.0, 6.0)
							b.pack_mesh(CityLandscape._flower(rng.randi() % Props.FLOWER_KINDS), Vector3(fx, _gy(b, fx, fn), fn), rng.randf() * 360.0, rng.randf_range(0.8, 1.2), 0.4)
				continue
			if not _free(x, n, occupied, 3.0) or _on_road(b, x, n, 10.0):
				continue
			var ti = -1
			for k in 8:
				var tk = rng.randi() % HouseKit.templates.size()
				if int(HouseKit.templates[tk].get("arch", 0)) >= 5 and rng.randf() < 0.7:
					continue   # yuvarlak kule / kubbe blok içinde seyrek (her yer kule olunca karmaşık duruyordu)
				if float(HouseKit.templates[tk]["w"]) <= step - 0.6 and float(HouseKit.templates[tk]["d"]) <= step - 0.6:
					ti = tk
					break
			if ti < 0:
				continue
			var tw = float(HouseKit.templates[ti]["w"])
			var td = float(HouseKit.templates[ti]["d"])
			# en yakın sokağa bak
			var best = Vector2(0, -1)
			var bd = 1e9
			for dv in [Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]:
				var wp = b.w(Vector3(x + dv.x * 30.0, 0, n + dv.y * 30.0))
				var rd = Game.road_dist(wp.x, wp.z)
				if rd < bd:
					bd = rd
					best = dv
			var side = Vector2(-best.y, best.x)
			if not _lot_free(b, Vector2(x, n), side, tw, td):
				continue
			var yaw = rad_to_deg(atan2(-best.x, -best.y))
			b.house_ti = ti
			b.house(x, n, tw + 0.1, td + 0.1, 3, yaw, "konoha", rng)
			if b.house_ok:
				var fo2 = Builder.rot(0, -td * 0.5 - 1.0, yaw)
				_path_doors.append(_gp(b, b.placed_xn.x + fo2.x, b.placed_xn.y + fo2.y))
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
		if mm == null or not mm.use_colors or ch.material_override == null:
			continue  # hazır modeller (kendi malzemesi + LOD aralıkları) birleştirilmez
		if ch.visibility_range_end < 1000.0:
			continue  # HouseKit yakın kademeleri (detay / yakın kabuk): hücre ve mesafeleri eşleşik, birleştirme bozar
		olds.append(ch)
		for i in mm.instance_count:
			var xf = mm.get_instance_transform(i)
			var k = [mm.mesh, Vector2i(floori(xf.origin.x / 480.0), floori(xf.origin.z / 480.0))]
			var ks = "%d|%d|%d" % [mm.mesh.get_instance_id(), k[1].x, k[1].y]
			if not groups.has(ks):
				groups[ks] = {"mesh": mm.mesh, "xf": [], "col": [], "vis": ch.visibility_range_end, "mat": ch.material_override}
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
		mmi.material_override = g["mat"]  # hazır modeller kendi malzemelerini kullanır (override yok)
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
	var rc = Color(0.74, 0.58, 0.36)   # kayanın altın-toprak tonu (yüzler kayadan oyulmuş)
	var cx = (x0 + x1) * 0.5
	# yüzler köyün tam karşısında, birbirine yakın dizili (animedeki gibi): x = 0 civarı
	var gap = 92.0
	var H = clampf(top * 0.42, 40.0, 78.0)   # kafa (çene-tepe) yüksekliği
	var fy = top * 0.56
	for i in 5:
		var fx = (float(i) - 2.0) * gap
		var fc = rc.lightened(0.03 * float(i % 2))
		# kafanın orta yüksekliğinde uçurum yüzeyi (kuzeye doğru arazi bu yüksekliği geçtiği ilk nokta)
		# kayaya OYULMUŞ kabartma (anime): uçurum yüzeyine yapışık ızgara — kenarları kayanın içine gömülür, havada kafa/kaya yığını yok
		_relief_head(b, fx, fy, cliff_n, H, fc.darkened(0.06), i)
	# halk için uçuruma çıkan zikzak taş merdiven (yüzlerin batısında, seyir yerine çıkar)
	_cliff_stairs(b, -2.0 * gap - gap * 1.1, cliff_n, top, rc.darkened(0.2))
	# tepe seyir yeri (uçurumun hemen arkası)
	var ln = cliff_n + 35.0
	b.box(Vector3(cx, _gy(b, cx, ln) + 0.5, ln), Vector3(70, 1, 24), Color(0.55, 0.45, 0.35), 0, false)
	for k in 8:
		b.box(Vector3(cx - 34 + k * 9.7, _gy(b, cx, ln) + 1.6, ln - 12), Vector3(0.3, 1.2, 0.3), Color(0.42, 0.3, 0.2), 0, false)
	_act(b, cx, ln, 14, "lookout", "[F] Köyü seyret (kayıt)")
	_act(b, cx + 30, ln, 4, "shrine", "[F] Kayadaki küçük sunakta dua et")


## Hokage Kayası kabartması (anime ref refs/hokage_rock): baş, uçurumun kendisine oyulmuş — ızgaranın her noktası uçurum
## yüzeyinden içeri/dışarı itilir, kenarlar kayanın içinde kalır (tam duvara yapışık). Yüz oval kubbe; saç kütlesi stile göre
## (0 uzun saç, 1 geriye dikenli, 2 kâse kesim, 3 kısa dikenli, 4 kâküllü uzun — kadın); 1-3'te alın koruyucusu bandı;
## göz çukurları, kaş çıkıntısı, burun, elmacık, ağız çizgisi, çene; altta boyun ve omuzlar kayaya karışır.
## Oyunun kendi Hokage'leri (kanon yüz kopyası değil). Renk: oyuk yerler koyu, dikey akıntı izleri.
static func _relief_head(b: Builder, fx: float, fy: float, cliff_n: float, H: float, col: Color, style: int) -> void:
	var W = H * 1.4
	var TOP = H * 0.8
	var BOT = -H * 1.1
	# uçurum yüzeyi: kaba ızgarada ölçülür, aradaki noktalar çift doğrusal (her noktada ikili arama çok pahalı)
	var CX = 9; var CY = 10
	var surf: Array = []
	for jy in CY:
		var row: Array = []
		for ix in CX:
			var sx = fx - W * 0.5 + W * ix / float(CX - 1)
			var sy = fy + BOT + (TOP - BOT) * jy / float(CY - 1)
			row.append(_cliff_surface(b, sx, cliff_n, sy))
		surf.append(row)
	var surf_at = func(x: float, y: float) -> float:
		var fu = clampf((x - (fx - W * 0.5)) / W * (CX - 1), 0.0, CX - 1.001)
		var fv = clampf((y - (fy + BOT)) / (TOP - BOT) * (CY - 1), 0.0, CY - 1.001)
		var i0 = int(fu); var j0 = int(fv)
		var a = fu - i0; var c = fv - j0
		return lerpf(lerpf(surf[j0][i0], surf[j0][i0 + 1], a), lerpf(surf[j0 + 1][i0], surf[j0 + 1][i0 + 1], a), c)
	var g2 = func(dx: float, dy: float, sx: float, sy: float) -> float:
		return exp(-(dx * dx) / (2.0 * sx * sx) - (dy * dy) / (2.0 * sy * sy))
	var dome = func(u: float, v: float, cx: float, cy: float, rx: float, ry: float, d: float) -> float:
		var q = pow((u - cx) / rx, 2.0) + pow((v - cy) / ry, 2.0)
		return d * sqrt(maxf(0.0, 1.0 - q))
	var banded = style in [1, 2, 3]
	# önü düz, kenarı dik kubbe (pw küçük = daha düz ön yüz): top gibi yuvarlak kafa maymun suratı yapıyordu
	var sdome = func(u: float, v: float, cx: float, cy: float, rx: float, ry: float, d: float, pw: float) -> float:
		var q = pow((u - cx) / rx, 2.0) + pow((v - cy) / ry, 2.0)
		return d * pow(maxf(0.0, 1.0 - q), pw)
	# üçgen saç dikeni: merkezden ang yönünde r0'dan r1'e incelerek uzanır
	var spike = func(rel: Vector2, ang: float, r0: float, r1: float, w0: float, d0: float) -> float:
		var dirv = Vector2(sin(ang), cos(ang))
		var al = rel.dot(dirv)
		if al < r0 * 0.4 or al > r1:
			return 0.0
		var k = clampf((al - r0) / (r1 - r0), 0.0, 1.0)
		var w = w0 * (1.0 - k) + 0.004
		var pr = absf(rel.x * dirv.y - rel.y * dirv.x)
		return d0 * (1.0 - 0.75 * k) * pow(clampf(1.0 - pr / w, 0.0, 1.0), 0.6)
	# derinlik (H biriminde, uçurum yüzeyinden dışarı)
	var depth = func(u: float, v: float) -> float:
		# yüz (anime taş yüzleri): alın geniş, çeneye doğru daralan uzun oval; ön yüz düz
		var tj = clampf((0.02 - v) / 0.5, 0.0, 1.0)
		var rx = 0.275 * (1.0 - 0.42 * pow(tj, 1.7))
		var qf = pow(u / rx, 2.0) + pow((v + 0.03) / 0.47, 2.0)
		var face = 0.3 * pow(1.0 - qf, 0.38) if qf < 1.0 else 0.0
		var hair = 0.0
		match style:
			0, 4:   # uzun düz saç: tepeden omuza inen kesintisiz perde (yüzü çerçeveler), uçları kırık
				var topq = pow(u / 0.41, 2.0) + pow(maxf(0.0, v - 0.05) / 0.47, 2.0)
				var hw = 0.41 - 0.05 * clampf((-0.1 - v) / 0.6, 0.0, 1.0)
				var vb = -0.74 - 0.05 * sin(u * 43.0) - 0.03 * sin(u * 17.0 + 1.0)
				if topq < 1.0 and absf(u) < hw and v > vb:
					hair = 0.22 * pow(1.0 - topq, 0.3) * clampf((hw - absf(u)) / 0.05, 0.0, 1.0) * clampf((v - vb) / 0.07, 0.0, 1.0)
			1:   # geriye taranmış: kafa kütlesi + tepeden yukarı-geri açılan iri dikenler
				hair = sdome.call(u, v, 0.0, 0.1, 0.345, 0.46, 0.25, 0.4)
				for k in 7:
					hair = maxf(hair, float(spike.call(Vector2(u, v - 0.16), deg_to_rad(-66.0 + k * 22.0), 0.3, 0.62 - 0.05 * absf(k - 3.0), 0.085, 0.22)))
			2:   # kâse kesim: yuvarlak kütle, kâküller alnın üstünde düz biter
				hair = sdome.call(u, v, 0.0, 0.12, 0.4, 0.42, 0.27, 0.4)
			3:   # kısa dikenli: kafanın çevresinde her yöne sivri tutamlar
				hair = sdome.call(u, v, 0.0, 0.08, 0.345, 0.45, 0.24, 0.4)
				for k in 13:
					hair = maxf(hair, float(spike.call(Vector2(u, v - 0.1), deg_to_rad(-126.0 + k * 21.0), 0.3, 0.5 + 0.05 * float(k % 2), 0.07, 0.2)))
		if hair > 0.0:
			hair += 0.011 * sin(u * 78.0 + v * 6.0) * clampf(hair / 0.1, 0.0, 1.0)   # saç telleri: dikey oluklar
		var t = maxf(face, hair)
		# kâse kâkülü: alnın üstünde düz biter. Kadın: ortadan ayrık, yanlara inen kâkül
		if style == 2 and v > 0.17 and face > 0.0:
			t = maxf(t, face + 0.014 + 0.005 * sin(u * 70.0))
		if style == 4 and face > 0.0 and v > 0.13 + maxf(0.0, 0.2 - absf(u)) * 1.3:
			t = maxf(t, face + 0.014 + 0.005 * sin(u * 70.0))
		# alın koruyucusu: alnı saran ince bant + ortada plaka (yüzün eğrisini izler)
		if banded and v > 0.2 and v < 0.295 and absf(u) < 0.36:
			t = maxf(t, maxf(face, hair) + 0.012)
			if absf(u) < 0.125 and v > 0.212 and v < 0.283:
				t += 0.01
		# yüz ayrıntıları (yalnız yüzün önde olduğu yerde)
		if face > 0.0 and face >= hair - 0.004 and v < 0.2:
			for sx in [-1.0, 1.0]:
				var ex = u - sx * 0.115
				var ey = v - 0.05 - ex * sx * 0.1
				# derin göz çukuru + içinde kabarık, bebeksiz iri badem göz (taş yüzlerin boş bakışı)
				var sock = clampf(1.0 - pow(ex / 0.098, 2.0) - pow(ey / 0.056, 2.0), 0.0, 1.0)
				t -= 0.038 * pow(sock, 0.6)
				var ball = clampf(1.0 - pow(ex / 0.074, 2.0) - pow(ey / 0.03, 2.0), 0.0, 1.0)
				t += 0.024 * pow(ball, 0.5)
				t += 0.024 * g2.call(ex, ey - 0.066, 0.1, 0.014)                 # ağır kaş çıkıntısı
				t += 0.012 * g2.call(u - sx * 0.175, v + 0.03, 0.05, 0.04)       # elmacık kemiği
				t -= 0.012 * g2.call(u - sx * 0.14, v + 0.2, 0.05, 0.09)         # yanak çukuru (çeneye inen düzlem)
				t += 0.016 * g2.call(u - sx * 0.036, v + 0.128, 0.017, 0.017)    # burun kanadı
			# uzun düz burun: kaş arasından başlar, aşağı doğru genişleyip yükselir, ucu keskin biter
			if v > -0.145 and v < 0.11:
				var nk = clampf((0.11 - v) / 0.25, 0.0, 1.0)
				t += (0.014 + 0.058 * nk) * pow(clampf(1.0 - absf(u) / (0.02 + 0.03 * nk), 0.0, 1.0), 0.7)
			t -= 0.032 * g2.call(u, v + 0.245, 0.075, 0.011)                    # ağız çizgisi
			t += 0.009 * g2.call(u, v + 0.222, 0.055, 0.012)                    # üst dudak
			t += 0.013 * g2.call(u, v + 0.277, 0.048, 0.014)                    # alt dudak
			t += 0.022 * g2.call(u, v + 0.395, 0.07, 0.05)                      # çene
		# kısa boyun: çenenin altından kayaya karışarak söner (omuz / kaide yok — baş kayadan çıkar)
		var neck = 0.0
		if v < -0.34 and absf(u) < 0.15:
			neck = 0.15 * pow(1.0 - pow(u / 0.15, 2.0), 0.5) * clampf((v + 0.68) / 0.24, 0.0, 1.0)
		return maxf(t, neck)
	var NX = 150; var NY = 204
	var pos: Array = []
	var dep: Array = []
	for jy in NY:
		var drow: Array = []
		for ix in NX:
			var x = fx - W * 0.5 + W * ix / float(NX - 1)
			var y = fy + BOT + (TOP - BOT) * jy / float(NY - 1)
			drow.append(float(depth.call((x - fx) / H, (y - fy) / H)))
		dep.append(drow)
	for _pass in 1:
		var nd: Array = []
		for jy in NY:
			var r2: Array = []
			for ix in NX:
				var acc = 0.0
				for oy in [-1, 0, 1]:
					for ox in [-1, 0, 1]:
						acc += float(dep[clampi(jy + oy, 0, NY - 1)][clampi(ix + ox, 0, NX - 1)])
				r2.append(acc / 9.0)
			nd.append(r2)
		dep = nd
	for jy in NY:
		var prow: Array = []
		for ix in NX:
			var x = fx - W * 0.5 + W * ix / float(NX - 1)
			var y = fy + BOT + (TOP - BOT) * jy / float(NY - 1)
			# kenarlar kayanın 0.6 m içinde: yüzeyle birleşim yerinde boşluk/yarık kalmaz
			var n = float(surf_at.call(x, y)) - float(dep[jy][ix]) * H + 0.6
			prow.append(b.w(Vector3(x, y, n)))
		pos.append(prow)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng = RandomNumberGenerator.new()
	rng.seed = 4100 + style
	var streak: Array = []
	for ix in NX:
		streak.append(rng.randf())
	var cfn = func(ix: int, jy: int) -> Color:
		var d0: float = dep[jy][ix]
		var avg = (float(dep[jy][maxi(ix - 1, 0)]) + float(dep[jy][mini(ix + 1, NX - 1)]) + float(dep[maxi(jy - 1, 0)][ix]) + float(dep[mini(jy + 1, NY - 1)][ix])) * 0.25
		var concave = clampf((avg - d0) * 160.0, 0.0, 0.45)   # oyuk/yarık: koyu (göz, ağız, saç araları)
		var c = col.darkened(concave + float(streak[ix]) * 0.07 + (0.06 if d0 < 0.01 else 0.0))
		return c
	for jy in NY - 1:
		for ix in NX - 1:
			var q = [[ix, jy], [ix + 1, jy + 1], [ix + 1, jy], [ix, jy], [ix, jy + 1], [ix + 1, jy + 1]]   # ön yüz köye bakar
			for e in q:
				st.set_color(cfn.call(e[0], e[1]))
				st.add_vertex(pos[e[1]][e[0]])
	st.generate_normals()
	var mesh = st.commit()
	var mat = Props.toon()
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	b.root.add_child(mi)
	mi.global_transform = Transform3D.IDENTITY
	# çarpışma: kabartmanın kendisi (üstüne basılır, tırmanılır)
	if is_instance_valid(b.body):
		var cs = CollisionShape3D.new()
		# çarpışma ızgarası görselin üçte biri sıklıkta (aynı şekil, dokuzda bir üçgen)
		var faces := PackedVector3Array()
		var STEP = 3
		var jy2 = 0
		while jy2 + STEP < NY:
			var ix2 = 0
			while ix2 + STEP < NX:
				for e in [[ix2, jy2], [ix2 + STEP, jy2 + STEP], [ix2 + STEP, jy2], [ix2, jy2], [ix2, jy2 + STEP], [ix2 + STEP, jy2 + STEP]]:
					faces.append(pos[e[1]][e[0]])
				ix2 += STEP
			jy2 += STEP
		var tri = ConcavePolygonShape3D.new()
		tri.set_faces(faces)
		cs.shape = tri
		b.add_shape(cs)
		cs.global_transform = Transform3D.IDENTITY if cs.is_inside_tree() else Transform3D.IDENTITY


## Gerçek karakter kafasından oyulmuş dev taş yüz: her Hokage farklı saç, yüz ve bant
const HOKAGE_LOOKS := [
	{"hair_style": "uzun", "face_id": 0, "band": null},
	{"hair_style": "geriye", "face_id": 1, "band": Color.WHITE, "band_style": "head"},
	{"hair_style": "kase", "face_id": 2, "band": Color.WHITE, "band_style": "head"},
	{"hair_style": "kısa", "face_id": 3, "band": Color.WHITE, "band_style": "head"},
	{"hair_style": "kisa_kakul", "face_id": 1, "band": Color.WHITE, "band_style": "head", "gender": "f"},
]
## look_extra: başka büstler (Sonun Vadisi heykelleri) için görünüm; yaw: yüzün baktığı yön (PI = güney/köy)
static func _stone_head(b: Builder, i: int, at: Vector3, height: float, col: Color, look_extra := {}, yaw := PI) -> void:
	var look = {"gender": "m", "age": "adult", "top_style": "uzun", "vest": null}
	look.merge(HOKAGE_LOOKS[i % HOKAGE_LOOKS.size()] if look_extra.is_empty() else look_extra, true)
	var hm = CharacterModel.new()
	b.root.add_child(hm)
	hm.setup(look)
	hm.anim.stop()
	hm.set_process(false)
	var sk = hm.skel
	# T-pozundaki kollar boyun kesiminin üstüne taşıyor, kayadan dev bir kol uzanıyordu: kolları omuza büzüp gizle
	for bn in ["LeftUpperArm", "RightUpperArm"]:
		var bi = sk.find_bone(bn)
		if bi >= 0:
			sk.set_bone_pose_scale(bi, Vector3.ONE * 0.001)
	var head_y = sk.get_bone_global_rest(sk.find_bone("Head")).origin.y
	var neck_y = sk.get_bone_global_rest(sk.find_bone("Neck")).origin.y
	var sc = height / 0.3   # kafa ~0.3 m -> hedef yükseklik
	hm.scale = Vector3.ONE * sc
	hm.rotation = Vector3(deg_to_rad(-8.0), yaw, 0)  # yüz güneye (köye) bakar, hafif yukarı
	# kafa uçurumdan dışarı taşar: merkezi yüzeyin biraz önünde (köy tarafı), arkası kayaya gömülü
	var fwd = Vector3(-sin(yaw), 0, cos(yaw)) * height * 0.02   # yüz yönüne çok az öne: arkası kayaya gömülü (havada durmasın)
	var wp = b.w(at + fwd)
	hm.global_position = wp - Vector3(0, (head_y + 0.05) * sc, 0)
	# çarpışma: kafatası küresi + yüz/çene kutusu + boyun bloğu (üstünde durulabilir, içinden geçilmez)
	var hc = b.w(at + Vector3(0, height * 0.08, 0) + fwd)
	var body = StaticBody3D.new()
	body.collision_layer = 1
	b.root.add_child(body)
	var add_shape = func(sh: Shape3D, xf: Transform3D) -> void:
		var cs = CollisionShape3D.new()
		cs.shape = sh
		cs.transform = xf
		body.add_child(cs)
	var sp = SphereShape3D.new()
	sp.radius = height * 0.46
	add_shape.call(sp, Transform3D(Basis.IDENTITY, hc))
	var bx = BoxShape3D.new()
	bx.size = Vector3(height * 0.62, height * 0.55, height * 0.6)
	add_shape.call(bx, Transform3D(Basis.IDENTITY, hc + Vector3(0, -height * 0.3, height * 0.05)))
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/stone_head.gdshader")
	m.set_shader_parameter("stone", col)
	m.set_shader_parameter("cut_world_y", hm.global_position.y + (neck_y + 0.015) * sc)
	for mi in hm.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mi.mesh == null:
			continue
		# her yüzey kendi dokusuyla taşa oyulur: göz, kaş, ağız ve saç telleri çizgi olarak okunur
		for si in mi.mesh.get_surface_count():
			var src = mi.get_surface_override_material(si)
			if src == null:
				src = mi.mesh.surface_get_material(si)
			if src == null and mi.material_override != null:
				src = mi.material_override
			var t: Texture2D = null
			if src is ShaderMaterial:
				t = src.get_shader_parameter("tex")
			elif src is BaseMaterial3D:
				if src.albedo_color.a < 0.05:
					continue  # görünmez yüz parçası
				t = src.albedo_texture
			var sm = m.duplicate()
			if t != null:
				sm.set_shader_parameter("tex", t)
				sm.set_shader_parameter("use_tex", true)
			mi.set_surface_override_material(si, sm)
		mi.material_override = null


## Prosedürel Ichiraku tarzı tezgâh (referans: Ichiraku Ramen, Teuchi sahneleri): caddeye açık tezgâh, kırmızı tezgâh üstü,
## önde "ラーメン一楽" yazılı lacivert noren perdeleri, yanda kırmızı fener, tezgâh önünde kırmızı minderli yuvarlak tabureler,
## tezgâhın arkasında usta için mutfak boşluğu: kaynayan kazanlar (buhar), kase rafı, çubuk kutuları. Müşteri tarafı = büyük n.
const RAMEN_SEAT_N := 2.2   # tabure merkezi (inn + bu)
const RAMEN_STOOL_H := 0.48
static func _ichiraku_boxes(b: Builder, ix: float, inn: float) -> void:
	var wood = Color(0.62, 0.44, 0.28)
	var dark = Color(0.36, 0.25, 0.16)
	b.box(Vector3(ix, 0.03, inn + 1.0), Vector3(10.6, 0.06, 9.0), Color(0.56, 0.5, 0.42))   # sıkıştırılmış toprak/taş zemin (çimeni temizler)
	# arka bina (mutfak duvarı + depo): ön yüzü inn-1.2'de; usta inn-0.3'te durur
	b.box(Vector3(ix, 1.9, inn - 3.3), Vector3(9.4, 3.8, 4.2), Color(0.86, 0.78, 0.62))
	for k in 7:   # ahşap tahta derzleri
		b.box(Vector3(ix - 4.2 + k * 1.4, 1.9, inn - 1.19), Vector3(0.08, 3.8, 0.04), wood.darkened(0.2), 0, false)
	# arka tezgâh: kazanlar, raf
	b.box(Vector3(ix, 0.5, inn - 0.85), Vector3(8.6, 1.0, 0.7), wood.darkened(0.1))
	b.box(Vector3(ix, 1.02, inn - 0.85), Vector3(8.8, 0.06, 0.8), Color(0.7, 0.7, 0.68), 0, false)   # paslanmaz çelik
	for k in 3:
		var px = ix - 3.0 + k * 1.3
		b.cyl(Vector3(px, 1.3, inn - 0.85), 0.62, 0.55, Color(0.62, 0.62, 0.64), false, 14)   # kazan
		b.cyl(Vector3(px, 1.58, inn - 0.85), 0.56, 0.02, Color(0.78, 0.6, 0.35), false, 14)   # et suyu
	for r in 2:   # kase rafı
		b.box(Vector3(ix + 2.2, 1.75 + r * 0.45, inn - 1.05), Vector3(3.0, 0.05, 0.3), wood, 0, false)
		for k in 7:
			b.cyl(Vector3(ix + 1.0 + k * 0.4, 1.83 + r * 0.45, inn - 1.05), 0.2, 0.1, Color(0.75, 0.18, 0.14) if (k + r) % 2 == 0 else Color(0.93, 0.92, 0.88), false, 10)
	# ana tezgâh: gövde, kırmızı üst, müşteri tarafında ayak dayama çıtası
	b.box(Vector3(ix, 0.4, inn + 1.35), Vector3(9.0, 0.8, 0.95), wood)   # gövde geride: üst levha öne taşar (diz boşluğu)
	b.box(Vector3(ix, 0.84, inn + 1.55), Vector3(9.4, 0.08, 1.35), Color(0.72, 0.16, 0.12), 0, false)
	b.box(Vector3(ix, 0.22, inn + 1.86), Vector3(9.0, 0.06, 0.1), dark, 0, false)
	for k in 6:   # tezgâh gövdesinde dikey çıtalar
		b.box(Vector3(ix - 3.75 + k * 1.5, 0.4, inn + 1.84), Vector3(0.1, 0.8, 0.04), dark, 0, false)
	# tezgâh üstü: çubuk kutuları, baharat, peçete
	for k in 4:
		var cx = ix - 3.0 + k * 2.0 + 1.0
		b.cyl(Vector3(cx, 0.96, inn + 1.2), 0.14, 0.16, Color(0.75, 0.75, 0.72), false, 8)
		for q in 5:
			b.box(Vector3(cx - 0.03 + q * 0.015, 1.1, inn + 1.2), Vector3(0.012, 0.22, 0.012), Color(0.86, 0.72, 0.5), 0, false)
		b.cyl(Vector3(cx + 0.18, 0.93, inn + 1.2), 0.07, 0.1, Color(0.85, 0.35, 0.15), false, 8)
	# direkler, çatı
	for sx in [-4.55, 4.55]:
		b.box(Vector3(ix + sx, 1.9, inn + 2.3), Vector3(0.3, 3.8, 0.3), dark, 0, false)
		b.box(Vector3(ix + sx, 1.9, inn - 0.9), Vector3(0.3, 3.8, 0.3), dark, 0, false)
	b.box(Vector3(ix, 3.72, inn + 0.5), Vector3(9.8, 0.25, 4.6), wood.darkened(0.15), 0, false)   # tavan
	b.roof(Vector3(ix, 3.85, inn - 0.4), Vector3(10.6, 1.2, 8.0), Color(0.48, 0.36, 0.26), 0.0)
	b.box(Vector3(ix, 3.55, inn + 2.42), Vector3(9.6, 0.3, 0.12), dark, 0, false)   # noren çıtası
	# noren: 6 lacivert perde, her birinde bir harf (ラーメン一楽), sarı-beyaz
	var txt = ["ラ", "ー", "メ", "ン", "一", "楽"]
	for i in 6:
		var px = ix + 3.75 - i * 1.5   # müşteri tarafından (büyük n) bakınca soldan sağa okunur
		b.box(Vector3(px, 3.0, inn + 2.45), Vector3(1.42, 1.0, 0.03), Color(0.14, 0.2, 0.32), 0, false)
		b.kanji(Vector3(px, 3.0, inn + 2.47), txt[i], 0.62, Color(0.98, 0.9, 0.45), 180.0)
	# kırmızı kâğıt fener (chōchin) sol direkte
	b.cyl(Vector3(ix - 4.95, 2.6, inn + 2.4), 0.5, 0.7, Color(0.85, 0.15, 0.1), false, 12)
	b.cyl(Vector3(ix - 4.95, 2.96, inn + 2.4), 0.36, 0.06, Color(0.15, 0.12, 0.1), false, 12)
	b.cyl(Vector3(ix - 4.95, 2.24, inn + 2.4), 0.36, 0.06, Color(0.15, 0.12, 0.1), false, 12)
	b.kanji(Vector3(ix - 4.95, 2.6, inn + 2.66), "一楽", 0.22, Color(0.1, 0.08, 0.06), 180.0)
	# tabureler: ahşap ayak, kırmızı yuvarlak minder (oturma yüksekliği RAMEN_STOOL_H); geçilebilir (oturan karakter içine girmesin)
	for i in 4:
		var sxp = ix - 3 + i * 2
		b.cyl(Vector3(sxp, RAMEN_STOOL_H * 0.5 - 0.04, inn + RAMEN_SEAT_N), 0.14, RAMEN_STOOL_H - 0.08, Color(0.3, 0.3, 0.32), false, 8)
		b.cyl(Vector3(sxp, 0.03, inn + RAMEN_SEAT_N), 0.5, 0.06, Color(0.3, 0.3, 0.32), false, 10)
		b.cyl(Vector3(sxp, RAMEN_STOOL_H - 0.04, inn + RAMEN_SEAT_N), 0.52, 0.08, Color(0.78, 0.16, 0.12), false, 14)


## Uçurum yüzeyi: verilen yükseklikte kuzeye doğru arazinin bu yüksekliği geçtiği ilk n
## Uçurum yüzüne yaslı zikzak merdiven: 0.6 m basamak, 20 basamakta bir sahanlık, yön değiştirir
static func _cliff_stairs(b: Builder, xs: float, cliff_n: float, top: float, col: Color) -> void:
	var y = _gy(b, xs, cliff_n - 150.0)
	var x = xs - 14.0
	var dir = 1.0
	var rise = 0.6
	var run = 1.4
	var guard = 0
	while y < top + 1.0 and guard < 600:
		guard += 1
		# gidiş kolu uçuruma yaslı (iç şerit), dönüş kolu dış şeritte: kollar üst üste binip aşağı inişi kapatmasın
		var lane = 0.0 if dir > 0.0 else 5.8
		for k in 20:
			if y >= top + 1.0:
				break
			y += rise
			x += run * dir
			var sn = _cliff_surface(b, x, cliff_n, y + 1.0)
			b.box(Vector3(x, y - 0.5, sn - 3.2 - lane), Vector3(run + 0.1, 1.0, 5.6), col, 0, true)
			if lane > 0.0:
				b.box(Vector3(x, y + 0.45, sn - 6.1 - lane), Vector3(run + 0.1, 0.9, 0.3), col.darkened(0.2), 0, true)   # korkuluk (dış kenar)
			else:
				b.box(Vector3(x, y - 3.0, sn - 6.0), Vector3(run + 0.1, 5.0, 0.3), col.darkened(0.12), 0, true)   # iç kolu alttaki dış koldan ayıran duvar
		# sahanlık: iki şeridi de kaplar
		var ln = _cliff_surface(b, x + dir * 2.5, cliff_n, y + 1.0)
		b.box(Vector3(x + dir * 2.5, y - 0.5, ln - 6.1), Vector3(5.0, 1.0, 11.4), col.lightened(0.05), 0, true)
		b.box(Vector3(x + dir * 4.9, y + 0.45, ln - 6.1), Vector3(0.3, 0.9, 11.4), col.darkened(0.2), 0, true)   # sahanlık ucu korkuluğu
		x += dir * 2.5
		dir = -dir
		x += dir * 2.5


static func _cliff_surface(b: Builder, x: float, cliff_n: float, y: float) -> float:
	# kaba adım (8 m) + ikili arama: metre metre taramak taş başına ~360 arazi sorgusuydu (yükleme 17 sn uzuyordu)
	var nn = cliff_n - 140.0
	while nn < cliff_n + 220.0:
		if _gy(b, x, nn + 8.0) > y:
			var lo = nn
			var hi = nn + 8.0
			for k in 4:
				var mid = (lo + hi) * 0.5
				if _gy(b, x, mid) > y:
					hi = mid
				else:
					lo = mid
			return hi
		nn += 8.0
	return cliff_n


## Naka Nehri'nin kaynağı: kayalıktan dökülen şelale (katmanlı su perdesi + dipte köpük ve sis)
static func _naka_falls(b: Builder, decor: Node3D, at: Vector2, cliff_n: float) -> void:
	var top = 46.0
	var g = _gy(b, at.x, at.y)
	for k in 10:
		var y = g + top * (1.0 - (k + 0.5) / 10.0)
		var n = _cliff_surface(b, at.x, cliff_n, y) - 1.2
		var mi = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2(8.0 + k * 0.25, top / 10.0 + 0.6)
		mi.mesh = q
		mi.material_override = Canal._water()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		decor.add_child(mi)
		mi.global_position = b.w(Vector3(at.x, y, minf(n, cliff_n - 2.0)))
	b.boulder(Vector3(at.x - 6.0, g, at.y + 1.0), Vector3(4.0, 3.0, 3.5), Color(0.5, 0.48, 0.45))
	b.boulder(Vector3(at.x + 6.5, g, at.y + 2.0), Vector3(5.0, 3.6, 4.0), Color(0.46, 0.44, 0.42))


static func _free(x: float, n: float, occ: Array, pad: float) -> bool:
	for o in occ:
		var extra = float(o[4]) if o.size() > 4 else 0.0   # önemli bina: çevresinde ek boşluk (evler dibine dayanmaz)
		if absf(x - o[0]) < o[2] + pad + extra and absf(n - o[1]) < o[3] + pad + extra:
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
