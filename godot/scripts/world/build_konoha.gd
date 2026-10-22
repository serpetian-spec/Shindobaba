class_name BuildKonoha
extends RefCounted
## Konohagakure: Ateş Ülkesi'nin gizli yaprak köyü. Yerel (x=doğu, n=kuzey), merkez (0,0), yarıçap ~430 m.

const R := 410.0


static func build(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Konoha")
	var rng = RandomNumberGenerator.new()
	rng.seed = 1234
	var occupied: Array = []  # [x, n, r] binaların yerleşmeyeceği alanlar

	# ---- yollar (görsel, toprak)
	var road = Color(0.74, 0.62, 0.45)
	b.box(Vector3(0, 0.03, -170), Vector3(18, 0.1, 470), road, 0, false)   # ana cadde (güney kapı -> kule)
	for rn in [-260, -110, 40, 160]:
		b.box(Vector3(0, 0.04, rn), Vector3(760, 0.1, 12), road, 0, false)
	for rx in [-200, 200]:
		b.box(Vector3(rx, 0.045, -40), Vector3(10, 0.1, 620), road, 0, false)
	occupied.append([0, -170, 14, 240])  # dikdörtgen: [x, n, yarı genişlik, yarı uzunluk]

	# ---- surlar + A-Un kapısı (güney)
	var wall_c = Color(0.86, 0.76, 0.58)
	b.wall_ring(R, 22.0, 4.0, wall_c, [[0.0, 76.0], [180.0, 9.0]], 3.0)
	var gn = -R
	for sx in [-1.0, 1.0]:
		b.box(Vector3(17 * sx, 15, gn), Vector3(6, 30, 7), Color(0.22, 0.4, 0.24))
		b.box(Vector3(19 * sx, 11, gn + 9), Vector3(1.5, 22, 15), Color(0.24, 0.42, 0.26), -8 * sx)  # açık kapı kanatları
	b.box(Vector3(0, 31, gn), Vector3(42, 4, 8), Color(0.22, 0.4, 0.24))
	b.box(Vector3(0, 27, gn - 4.2), Vector3(14, 3.2, 0.4), Color(0.92, 0.88, 0.78), 0, false)
	b.box(Vector3(0, 27, gn - 4.45), Vector3(9, 1.2, 0.1), Color(0.15, 0.15, 0.18), 0, false)  # "あうん" yazısı yerine şerit
	for sx in [-1.0, 1.0]:  # nöbetçi kulübesi
		b.box(Vector3(30 * sx, 1.6, gn + 16), Vector3(9, 3.2, 5), Color(0.62, 0.46, 0.3))
		b.box(Vector3(30 * sx, 3.5, gn + 16), Vector3(10, 0.5, 6), Color(0.2, 0.36, 0.55), 0, false)
	b.interact(Vector3(30, 0, gn + 13), 5, "gate", "[F] Kapı nöbetçisiyle konuş")

	# ---- Hokage Kayası (kuzey)
	var rock = Color(0.6, 0.55, 0.48)
	b.box(Vector3(0, 36, 430), Vector3(620, 80, 120), rock)
	b.box(Vector3(0, 60, 520), Vector3(800, 130, 90), rock.darkened(0.15))
	for sx in [-1.0, 1.0]:
		b.box(Vector3(330 * sx, 30, 380), Vector3(80, 70, 160), rock.darkened(0.08))
	var faces = [-120.0, -60.0, 0.0, 60.0, 120.0]
	for i in faces.size():
		var fx: float = faces[i]
		var fz = 369.0
		var fc = rock.lightened(0.06)
		b.box(Vector3(fx, 46, fz + 3), Vector3(30, 34, 10), fc)
		b.box(Vector3(fx, 64, fz + 4), Vector3(32, 7, 12), fc.darkened(0.12))  # saç hattı
		b.box(Vector3(fx, 50, fz - 2.5), Vector3(27, 3, 2), fc.darkened(0.1), 0, false)  # alın bandı
		for ex in [-6.5, 6.5]:
			b.box(Vector3(fx + ex, 44, fz - 2.2), Vector3(6, 2.2, 1), Color(0.32, 0.29, 0.26), 0, false)
		b.box(Vector3(fx, 38, fz - 3.5), Vector3(3.2, 7, 3), fc, 0, false)
		b.box(Vector3(fx, 32, fz - 2.2), Vector3(10, 1.4, 1), Color(0.32, 0.29, 0.26), 0, false)
	# kayaya çıkan taş merdiven (doğu ucu) + tepede seyir yeri
	for k in 40:
		b.box(Vector3(200 + k * 0.0, k * 2.0 + 1.0, 300 + k * 1.6), Vector3(10, 2.0, 3), Color(0.66, 0.6, 0.52))
	b.box(Vector3(0, 76.5, 395), Vector3(60, 1, 20), Color(0.55, 0.45, 0.35), 0, false)
	b.interact(Vector3(0, 76, 395), 12, "lookout", "[F] Köyü seyret (kayıt)")
	occupied.append([0, 380, 330, 60])

	# ---- Hokage Kulesi
	var tn = 220.0
	b.cyl(Vector3(0, 16, tn), 46, 32, Color(0.92, 0.86, 0.72), true, 32)
	b.cyl(Vector3(0, 33, tn), 50, 3, Color(0.72, 0.18, 0.15), true, 32)
	b.cyl(Vector3(0, 40, tn), 34, 12, Color(0.92, 0.86, 0.72), true, 28)
	b.cone(Vector3(0, 52, tn), 44, 9, Color(0.72, 0.18, 0.15), 28, true)
	b.cyl(Vector3(0, 36.5, tn - 16.6), 9, 9, Color(0.72, 0.18, 0.15), false, 16)  # "火" plakası (daire)
	b.box(Vector3(0, 36.5, tn - 17.4), Vector3(4.5, 5.5, 0.4), Color(0.95, 0.92, 0.85), 0, false)
	b.box(Vector3(0, 3.5, tn - 23.2), Vector3(7, 7, 1), Color(0.35, 0.24, 0.16), 0, false)
	for k in 8:  # pencereler
		var a = deg_to_rad(k * 45.0 + 22.5)
		b.box(Vector3(23.2 * sin(a), 20, tn + 23.2 * cos(a)), Vector3(3, 3, 0.4), Color(0.42, 0.62, 0.78), k * 45.0 + 22.5, false)
	b.box(Vector3(46, 9, tn + 4), Vector3(40, 18, 28), Color(0.92, 0.86, 0.72))  # idari bina
	b.box(Vector3(46, 18.6, tn + 4), Vector3(42, 1.2, 30), Color(0.72, 0.18, 0.15))
	b.interact(Vector3(0, 0, tn - 26), 7, "mission_board", "[F] Görev Masası (Hokage Kulesi)")
	occupied.append([20, tn, 60, 30])

	# ---- Ninja Akademisi
	var ax = -120.0; var an = 175.0
	b.box(Vector3(ax, 9, an), Vector3(70, 18, 26), Color(0.88, 0.78, 0.58))
	b.box(Vector3(ax, 18.7, an), Vector3(72, 1.4, 28), Color(0.72, 0.18, 0.15))
	b.box(Vector3(ax, 22, an), Vector3(20, 6, 14), Color(0.88, 0.78, 0.58))
	b.box(Vector3(ax, 25.6, an), Vector3(22, 1.2, 16), Color(0.72, 0.18, 0.15))
	for i in 10:
		for fl in [5.0, 12.5]:
			b.box(Vector3(ax - 30 + i * 6.6, fl, an - 13.1), Vector3(3, 2.8, 0.3), Color(0.42, 0.62, 0.78), 0, false)
	b.box(Vector3(ax, 3, an - 13.4), Vector3(6, 6, 0.6), Color(0.35, 0.24, 0.16), 0, false)
	# salıncaklı ağaç
	var tx = ax + 30.0; var tz = an - 32.0
	b.tree(tx, tz, 1.4, rng)
	b.box(Vector3(tx + 4.5, 7.4, tz), Vector3(8, 0.5, 0.5), Color(0.42, 0.29, 0.18), 0, false)
	for dz in [-0.6, 0.6]:
		b.box(Vector3(tx + 7, 5.0, tz + dz), Vector3(0.05, 4.8, 0.05), Color(0.85, 0.82, 0.75), 0, false)
	b.box(Vector3(tx + 7, 2.6, tz), Vector3(0.8, 0.12, 1.5), Color(0.55, 0.38, 0.22), 0, false)
	b.interact(Vector3(tx + 7, 0, tz), 3, "swing", "[F] Salıncağa otur")
	b.interact(Vector3(ax, 0, an - 18), 8, "academy", "[F] Akademi hocasıyla konuş")
	# akademi avlusu: kuklalar
	for i in 5:
		Spawner.dummy(b.w(Vector3(ax - 20 + i * 10, 0, an - 45)))
	occupied.append([ax, an - 15, 50, 40])

	# ---- Ichiraku Ramen
	var ix = 22.0; var inn = -60.0
	b.box(Vector3(ix, 0.65, inn - 1.5), Vector3(9, 1.3, 1.2), Color(0.55, 0.35, 0.2))
	b.box(Vector3(ix, 1.35, inn - 1.5), Vector3(9.5, 0.12, 1.6), Color(0.8, 0.62, 0.4), 0, false)
	b.box(Vector3(ix, 1.8, inn + 2.2), Vector3(9, 3.6, 4.5), Color(0.92, 0.88, 0.8))
	for sx in [-4.4, 4.4]:
		b.box(Vector3(ix + sx, 1.9, inn - 2.4), Vector3(0.35, 3.8, 0.35), Color(0.35, 0.24, 0.16), 0, false)
	b.box(Vector3(ix, 3.9, inn), Vector3(10.5, 0.5, 7.5), Color(0.72, 0.18, 0.15))
	for i in 6:
		b.box(Vector3(ix - 3.7 + i * 1.48, 3.1, inn - 2.55), Vector3(1.3, 1.1, 0.06), Color(0.95, 0.95, 0.95) if i % 2 else Color(0.85, 0.28, 0.22), 0, false)
	for i in 4:
		b.cyl(Vector3(ix - 3 + i * 2, 0.4, inn - 3.4), 0.7, 0.8, Color(0.72, 0.18, 0.15), false, 10)
	b.interact(Vector3(ix, 0, inn - 4), 4, "ramen", "[F] Ramen ye (50 Ryō) — can + chakra")
	occupied.append([ix, inn, 10, 8])

	# ---- çarşı caddesi (n=-110): tezgahlar + silah dükkânı
	for i in 14:
		var sx = -150.0 + i * 22.0
		if absf(sx) < 16:
			continue
		var side = 1.0 if i % 2 == 0 else -1.0
		var cn = -110.0 + side * 10.0
		var aw = [Color(0.85, 0.3, 0.25), Color(0.25, 0.5, 0.75), Color(0.95, 0.75, 0.3), Color(0.35, 0.6, 0.35)][i % 4]
		b.box(Vector3(sx, 0.6, cn), Vector3(5, 1.2, 2), Color(0.55, 0.4, 0.25))
		b.box(Vector3(sx, 2.9, cn), Vector3(6, 0.15, 3.2), aw, 0, false, Vector3(-10 * side, 0, 0))
		for k in 3:
			b.box(Vector3(sx - 1.6 + k * 1.6, 1.45, cn), Vector3(0.9, 0.5, 0.9), [Color(0.9, 0.5, 0.2), Color(0.85, 0.2, 0.3), Color(0.4, 0.75, 0.3)][k], 0, false)
	var wsx = 60.0; var wsn = -128.0
	b.house(wsx, wsn, 14, 11, 2, 0, "konoha", rng)
	b.box(Vector3(wsx, 9.4, wsn - 5.8), Vector3(6, 1.6, 0.3), Color(0.15, 0.15, 0.18), 0, false)
	b.interact(Vector3(wsx, 0, wsn - 8), 5, "shop_weapons", "[F] Silah Dükkânı")
	var hx = -60.0; var hn = -128.0
	b.house(hx, hn, 14, 11, 2, 0, "konoha", rng)
	b.interact(Vector3(hx, 0, hn - 8), 5, "shop_items", "[F] Eczane (merhem, haplar)")
	occupied.append([0, -110, 170, 16])

	# ---- Konoha Hastanesi
	var hpx = 140.0; var hpn = 70.0
	b.box(Vector3(hpx, 12, hpn), Vector3(50, 24, 30), Color(0.96, 0.95, 0.92))
	b.box(Vector3(hpx, 24.6, hpn), Vector3(52, 1.2, 32), Color(0.75, 0.25, 0.22))
	b.box(Vector3(hpx + 30, 8, hpn), Vector3(14, 16, 22), Color(0.94, 0.93, 0.9))
	b.cyl(Vector3(hpx, 20, hpn - 15.2), 6, 6, Color(0.75, 0.25, 0.22), false, 16)
	b.box(Vector3(hpx, 20, hpn - 15.5), Vector3(1.2, 3.6, 0.3), Color(1, 1, 1), 0, false)
	b.box(Vector3(hpx, 20, hpn - 15.5), Vector3(3.6, 1.2, 0.3), Color(1, 1, 1), 0, false)
	b.interact(Vector3(hpx, 0, hpn - 18), 6, "hospital", "[F] Hastane: iyileş (ücretsiz)")
	occupied.append([hpx + 6, hpn, 34, 20])

	# ---- Chunin Sınavı stadyumu
	var sx0 = 260.0; var sn0 = -40.0
	for k in 48:
		var a = k * 7.5
		var rad = deg_to_rad(a)
		var o = Vector2(55 * sin(rad), 55 * cos(rad))
		b.box(Vector3(sx0 + o.x, 9, sn0 + o.y), Vector3(7.6, 18, 4), Color(0.85, 0.78, 0.62), a)
		for t in 4:  # tribün basamakları (iç)
			var ro = 51.0 - t * 2.5
			b.box(Vector3(sx0 + ro * sin(rad), 2 + t * 3.5, sn0 + ro * cos(rad)), Vector3(7, 1, 2.4), Color(0.7, 0.6, 0.48), a)
	b.box(Vector3(sx0, 0.05, sn0), Vector3(70, 0.1, 70), Color(0.62, 0.72, 0.42), 0, false)
	b.box(Vector3(sx0, 18.5, sn0 + 54), Vector3(16, 3, 8), Color(0.72, 0.18, 0.15))  # kage locası
	b.interact(Vector3(sx0, 0, sn0 - 56), 8, "chunin_exam", "[F] Chunin Sınavı başvurusu")
	occupied.append([sx0, sn0, 62, 62])

	# ---- Uchiha Bölgesi (güneybatı) + Naka Tapınağı
	var ux = -260.0; var un = -170.0
	b.wall_ring_at(ux, un, 70.0, 5.0, Color(0.9, 0.88, 0.84), [[45.0, 18.0]])
	for k in 14:
		var a = k * 360.0 / 14.0
		var rr = 50.0 if k % 2 == 0 else 32.0
		var hxp = ux + rr * sin(deg_to_rad(a)); var hnp = un + rr * cos(deg_to_rad(a))
		b.house(hxp, hnp, 11, 9, 1 + (k % 2), a + 180.0, "konoha", rng)
		var fo = Builder.rot(0, -4.6, a + 180.0)
		b.cyl(Vector3(hxp + fo.x, 5.2, hnp + fo.y), 1.8, 0.1, Color(0.8, 0.15, 0.15), false, 12)  # yelpaze arması
	b.box(Vector3(ux, 3.5, un), Vector3(12, 7, 9), Color(0.55, 0.32, 0.22))  # Naka tapınağı
	b.roof(Vector3(ux, 7, un), Vector3(15, 4, 12), Color(0.25, 0.25, 0.3))
	b.box(Vector3(ux, 5, un - 12), Vector3(9, 0.8, 0.8), Color(0.8, 0.2, 0.15), 0, false)  # torii
	for sx in [-3.8, 3.8]:
		b.box(Vector3(ux + sx, 2.6, un - 12), Vector3(0.7, 5.2, 0.7), Color(0.8, 0.2, 0.15), 0, false)
	b.interact(Vector3(ux, 0, un - 10), 5, "naka", "[F] Naka Tapınağı")
	occupied.append([ux, un, 72, 72])

	# ---- Hyuga Konağı (kuzeybatı)
	var yx = -250.0; var yn = 90.0
	b.wall_rect(yx, yn, 90, 70, 4.0, Color(0.9, 0.88, 0.82))
	b.box(Vector3(yx, 4, yn + 10), Vector3(50, 8, 22), Color(0.58, 0.42, 0.28))
	b.roof(Vector3(yx, 8, yn + 10), Vector3(56, 6, 28), Color(0.28, 0.28, 0.32))
	b.box(Vector3(yx + 30, 3, yn - 15), Vector3(18, 6, 14), Color(0.58, 0.42, 0.28))
	b.roof(Vector3(yx + 30, 6, yn - 15), Vector3(21, 4, 17), Color(0.28, 0.28, 0.32))
	b.box(Vector3(yx - 15, 0.05, yn - 18), Vector3(30, 0.1, 18), Color(0.8, 0.78, 0.7), 0, false)  # çakıl avlu
	b.interact(Vector3(yx, 0, yn - 34), 6, "hyuga", "[F] Hyuga Konağı")
	occupied.append([yx, yn, 48, 38])

	# ---- Akimichi barbekü restoranı
	b.house(-40, -35, 16, 12, 2, 0, "konoha", rng)
	b.box(Vector3(-40, 9.6, -41.2), Vector3(8, 1.8, 0.3), Color(0.85, 0.3, 0.2), 0, false)
	b.interact(Vector3(-40, 0, -43), 5, "bbq", "[F] Barbekü (Yakiniku) ye — 80 Ryō")
	occupied.append([-40, -35, 10, 8])

	# ---- ANBU karargâhı (kayanın dibinde, karanlık)
	b.box(Vector3(-200, 7, 330), Vector3(30, 14, 22), Color(0.25, 0.25, 0.28))
	b.box(Vector3(-200, 14.5, 330), Vector3(32, 1, 24), Color(0.15, 0.15, 0.17))
	b.interact(Vector3(-200, 0, 317), 6, "anbu", "[F] ANBU Karargâhı")
	occupied.append([-200, 330, 20, 16])

	# ---- Antrenman Alanı 3 + Anıt Taşı (doğu)
	var tgx = 300.0; var tgn = 170.0
	b.box(Vector3(tgx, 0.04, tgn), Vector3(90, 0.1, 70), Color(0.45, 0.62, 0.3), 0, false)
	for i in 3:
		b.cyl(Vector3(tgx - 6 + i * 6, 1.0, tgn + 12), 1.0, 2.0, Color(0.48, 0.34, 0.2), true, 10)
	b.box(Vector3(tgx - 25, 2.2, tgn + 20), Vector3(4, 4.4, 1.2), Color(0.45, 0.45, 0.48))
	b.interact(Vector3(tgx - 25, 0, tgn + 17), 4, "memorial", "[F] Anıt Taşı")
	b.interact(Vector3(tgx, 0, tgn + 8), 6, "training", "[F] Antrenman yap (chakra kontrolü)")
	for i in 4:
		Spawner.dummy(b.w(Vector3(tgx - 15 + i * 10, 0, tgn - 10)))
	occupied.append([tgx, tgn, 46, 36])

	# ---- evler: sık mahalleler, her ev en yakın sokağa bakar, aralarda dar ara sokaklar
	var count = 0
	var gx = -385.0
	while gx <= 385.0:
		var gn2 = -395.0
		while gn2 <= 345.0:
			var x = gx + rng.randf_range(-1.5, 1.5)
			var n = gn2 + rng.randf_range(-1.5, 1.5)
			gn2 += 15.0
			if Vector2(x, n).length() > R - 16:
				continue
			if not _free(x, n, occupied, 7.0):
				continue
			if rng.randf() < 0.07:
				b.tree(x, n, rng.randf_range(0.9, 1.3), rng)
				continue
			var fl = [1, 2, 2, 2, 3].pick_random()
			b.house(x, n, 10, 9, fl, _face_road(x, n), "konoha", rng)
			count += 1
		gx += 15.0
	# sokak fenerleri
	for n in range(-380, 200, 30):
		b.lantern(-11, n)
		b.lantern(11, n)
	b.finish()
	print("Konoha: ", count, " ev")


## Evin ön cephesini en yakın sokağa çeviren yaw (derece)
static func _face_road(x: float, n: float) -> float:
	var best = Vector2(0, -1)
	var bd = 1e9
	var cands = [Vector2(0, clampf(n, -400, 60))]
	for rn in [-260, -110, 40, 160]:
		cands.append(Vector2(clampf(x, -380, 380), rn))
	for rx in [-200, 200]:
		cands.append(Vector2(rx, clampf(n, -350, 270)))
	for c in cands:
		var d = Vector2(x, n).distance_to(c)
		if d < bd:
			bd = d
			best = (c - Vector2(x, n)).normalized()
	if bd > 60.0:
		return [0.0, 90.0, 180.0, 270.0][int(absf(x * 7.0 + n * 3.0)) % 4]
	var yaw = rad_to_deg(atan2(-best.x, -best.y))
	return round(yaw / 90.0) * 90.0


static func _free(x: float, n: float, occ: Array, pad: float) -> bool:
	for o in occ:
		if absf(x - o[0]) < o[2] + pad and absf(n - o[1]) < o[3] + pad:
			return false
	# yollar
	if absf(x) < 16:
		return false
	for rn in [-260, -110, 40, 160]:
		if absf(n - rn) < 11:
			return false
	for rx in [-200, 200]:
		if absf(x - rx) < 10:
			return false
	return true
