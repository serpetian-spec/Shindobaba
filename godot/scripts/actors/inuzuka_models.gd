class_name InuzukaModels
extends RefCounted
## Inuzuka modelleri (referans: Narutopedia Akamaru Part II kareleri ve Double-Headed Wolf karesi).
## Dönen sözlük: {"root", "legs": [pivot], "tail": pivot, "heads": [pivot], "jaws": [pivot]}. Ön -Z, taban y=0.

const FUR := Color(0.96, 0.93, 0.87)
const WOLF := Color(0.97, 0.97, 0.98)


static func _mesh(parent: Node3D, b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	parent.add_child(mi)
	return mi


static func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var n = Node3D.new()
	n.position = at
	parent.add_child(n)
	return n


## Cel tüy tutamı: yüzeyden dışa çıkan birkaç sivri, yassı tutam (Akamaru/kurt kabarık kürkü)
static func _tufts(b: MB, at: Vector3, dir: Vector3, n: int, ln: float, w: float, col: Color, spread := 0.6, seed_v := 1) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in n:
		var d = (dir + Vector3(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))).normalized()
		var o = at + Vector3(rng.randf_range(-w, w), rng.randf_range(-w, w), rng.randf_range(-w, w)) * 1.5
		BeastRig.claw(b, o, d, ln * rng.randf_range(0.7, 1.2), w * rng.randf_range(0.8, 1.2), col)


## ------------------------------------------------------------------ Akamaru (Part II)
## Ölçek: h = omuz yüksekliği (Part II ~1.3 m, Kiba üstüne biner).
## Inuzuka ninken tüy renkleri [gövde, karın, kulak]: oyun başında rastgele seçilir, köpek büyüyünce de aynı kalır.
## 0 Akamaru (beyaz, kahve kulak) · 1 Kuromaru (siyah, beyaz karın) · 2 Haimaru kardeşler (gri, beyaz karın) · diğerleri aynı klanın köpek çeşitleri
const COATS := [
	[Color(0.96, 0.93, 0.87), Color(1.0, 0.98, 0.94), Color(0.45, 0.32, 0.27)],
	[Color(0.15, 0.14, 0.16), Color(0.92, 0.9, 0.88), Color(0.08, 0.07, 0.08)],
	[Color(0.56, 0.56, 0.6), Color(0.94, 0.93, 0.92), Color(0.36, 0.36, 0.4)],
	[Color(0.58, 0.4, 0.26), Color(0.9, 0.8, 0.64), Color(0.3, 0.2, 0.14)],
	[Color(0.86, 0.72, 0.5), Color(0.98, 0.93, 0.82), Color(0.2, 0.15, 0.12)],
	[Color(0.74, 0.4, 0.2), Color(0.97, 0.94, 0.9), Color(0.5, 0.24, 0.12)],
	[Color(0.3, 0.3, 0.34), Color(0.7, 0.68, 0.66), Color(0.14, 0.13, 0.15)],
	[Color(0.36, 0.24, 0.18), Color(0.82, 0.62, 0.42), Color(0.16, 0.1, 0.08)],
	[Color(0.9, 0.86, 0.8), Color(1.0, 0.98, 0.95), Color(0.14, 0.13, 0.14)],
	[Color(0.7, 0.72, 0.78), Color(0.97, 0.97, 0.98), Color(0.24, 0.26, 0.34)],
]


## Oyuncunun köpeğinin rengi: ilk kez sorulduğunda rastgele seçilip kayda yazılır
static func player_coat() -> int:
	if not Game.profile.has("ninken_coat"):
		Game.profile["ninken_coat"] = randi() % COATS.size()
	return int(Game.profile["ninken_coat"]) % COATS.size()


## ------------------------------------------------------------------ Anime köpeği (sıfırdan; refs/summons akamaru/kuromaru/shiba/hei/bisuke/guruko/akino)
## h = omuz yüksekliği. Ön -Z, taban y=0. İri baş, kalın boyun, derin göğüs, ince bel, tombul bacak + iri pati; tüy yalnız belirli yerlerde tutam.
## sp: c/under/earc renkler · ear "prick"|"flop"|"long" · snout (burun boyu, h oranı) · girth (gövde kalınlığı) · head (baş ölçeği) ·
##     fluff 0..1 (yanak + göğüs tutamları) · shag (kurt gibi dikenli sırt/yan tüyü) · tail "curl"|"plume"|"whip" · eyes "open"|"closed" ·
##     socks (bacak altı under rengi) · muzzle (burun-ağız under rengi) · crest (ibik rengi) · crest_len ·
##     vest, neck_band, head_band, glasses, bandage, kanji, eye_ring, whisker, eyepatch (aksesuarlar)
static func dog(h: float, sp: Dictionary) -> Dictionary:
	var out = {"root": Node3D.new(), "legs": [], "tail": null, "heads": [], "jaws": []}
	var root: Node3D = out["root"]
	var c: Color = sp.get("c", Color(0.8, 0.62, 0.4))
	var under: Color = sp.get("under", c.lightened(0.3))
	var earc: Color = sp.get("earc", c.darkened(0.3))
	var g := float(sp.get("girth", 1.0))
	var fluff := float(sp.get("fluff", 0.5))
	var LINE = Color(0.1, 0.08, 0.08)
	var blue = Color(0.16, 0.26, 0.55)
	var white = Color(0.96, 0.96, 0.94)
	var by = h * 0.66
	var L = h * 1.05
	var b = MB.new()
	var coat = func(_t: float, a: float, _d: Vector3) -> Color:
		return c.lerp(under, smoothstep(-0.35, -0.7, sin(a)))
	var tz = [L * 0.5, L * 0.2, -L * 0.2, -L * 0.46]
	var ty = [by, by + h * 0.01, by - h * 0.02, by + h * 0.05]
	var tr = [Vector2(0.19, 0.2) * h * g, Vector2(0.2, 0.21) * h * g, Vector2(0.25, 0.29) * h * g, Vector2(0.21, 0.25) * h * g]
	Loft.tube(b, [Vector3(0, ty[0], tz[0]), Vector3(0, ty[1], tz[1]), Vector3(0, ty[2], tz[2]), Vector3(0, ty[3], tz[3])], tr, c, 22, 6, true, true, coat)
	# boyun: kalın, öne-yukarı
	var P = Vector3(0, by + h * 0.47, -L * 0.5 - h * 0.15)
	Loft.tube(b, [Vector3(0, by + h * 0.08, -L * 0.36), Vector3(0, by + h * 0.3, -L * 0.47), P + Vector3(0, -h * 0.06, h * 0.08)], [Vector2(0.2, 0.22) * h * g, Vector2(0.17, 0.19) * h * g, Vector2(0.16, 0.17) * h], c, 16, 4, true, true,
		func(_t: float, _a: float, d: Vector3) -> Color: return under if (d.z < -0.35 and d.y < 0.3) else c)
	# göğüs tutamı (çenenin altından göğse)
	var rng = RandomNumberGenerator.new()
	rng.seed = 5
	for k in int(9 * fluff):
		var a = lerpf(-1.1, 1.1, k / maxf(1.0, 9.0 * fluff - 1.0))
		BeastRig.claw(b, Vector3(sin(a) * h * 0.16 * g, by + h * 0.12 - absf(a) * h * 0.04, -L * 0.47 - cos(a) * h * 0.06), Vector3(sin(a) * 0.5, -1, -0.45), h * rng.randf_range(0.16, 0.24), h * 0.06, under)
	if sp.get("shag", false):   # kurt tipi: sırtta ve yanlarda geriye bakan dikenli tüy
		for k in 46:
			var a2 = rng.randf_range(0.1, PI - 0.1)
			var z = rng.randf_range(-L * 0.45, L * 0.5)
			BeastRig.claw(b, Vector3(cos(a2) * h * 0.2 * g, by + sin(a2) * h * 0.22 * g, z), Vector3(cos(a2) * 0.7, sin(a2) * 0.6, 1.0), h * rng.randf_range(0.12, 0.2), h * 0.05, c.darkened(rng.randf_range(0.0, 0.1)))
	if sp.get("vest", false):   # mavi ninken yeleği + sırtta beyaz işaret
		Loft.tube(b, [Vector3(0, ty[1], L * 0.12), Vector3(0, ty[2], tz[2]), Vector3(0, ty[3] + h * 0.01, -L * 0.43)], [tr[1] * 1.07, tr[2] * 1.07, tr[3] * 1.1], blue, 22, 4, true, true)
		var top = Vector3(0, ty[2] + tr[2].y * 1.07 - h * 0.012, -L * 0.14)
		b.add("sphere", top, Vector3(0.22, 0.035, 0.22) * h, white, Vector3.ZERO, 14)
		for k in 8:   # işaretin içi (henohenomoheji yerine koyu sarmal çizgi)
			var sa = k * 0.9
			b.add("sphere", top + Vector3(cos(sa), 0.08, sin(sa)) * h * (0.02 + k * 0.008), Vector3(0.022, 0.012, 0.022) * h, LINE, Vector3.ZERO, 5)
	if sp.get("neck_band", false):   # boyunda alın koruyucu
		var nb = Vector3(0, by + h * 0.24, -L * 0.45)
		Loft.tube(b, [nb + Vector3(0, -h * 0.03, h * 0.03), nb + Vector3(0, h * 0.03, -h * 0.02)], [h * 0.2 * g, h * 0.19 * g], blue, 16, 2, false, false)
		b.add("box", nb + Vector3(0, -h * 0.08, -h * 0.17 * g), Vector3(0.16, 0.07, 0.025) * h, Color(0.78, 0.8, 0.84), Vector3(25, 0, 0))
	if sp.get("bandage", false):   # boyun sargısı
		for k in 3:
			var q0 = Vector3(0, by + h * (0.16 + k * 0.07), -L * 0.4 - k * h * 0.035)
			Loft.tube(b, [q0 + Vector3(0, -h * 0.025, h * 0.03), q0 + Vector3(0, h * 0.03, -h * 0.02)], [h * (0.215 - k * 0.012) * g, h * (0.205 - k * 0.012) * g], white, 16, 2, false, false)
	_mesh(root, b)
	# ---- baş (pivot): kafatası merkezi = pivot
	var head = _pivot(root, P)
	head.scale = Vector3.ONE * float(sp.get("head", 1.0))
	var hb = MB.new()
	var sn = float(sp.get("snout", 0.2)) * h
	var mz: Color = under if sp.get("muzzle", false) else c
	Loft.blob(hb, Vector3(0, 0, h * 0.02), Vector3(0, 0.15, -1), h * 0.46, [Vector2(0.15, 0.14) * h, Vector2(0.23, 0.21) * h, Vector2(0.22, 0.2) * h, Vector2(0.13, 0.11) * h], c, 18)
	Loft.tube(hb, [Vector3(0, -h * 0.04, -h * 0.13), Vector3(0, -h * 0.06, -h * 0.2 - sn * 0.5), Vector3(0, -h * 0.065, -h * 0.2 - sn)], [Vector2(0.15, 0.125) * h, Vector2(0.11, 0.092) * h, Vector2(0.07, 0.06) * h], mz, 16, 6)
	if sp.get("muzzle", false):   # alna doğru çıkan beyaz şerit
		hb.add("sphere", Vector3(0, h * 0.03, -h * 0.17), Vector3(0.11, 0.2, 0.1) * h, under, Vector3(-20, 0, 0), 10)
	var tip = Vector3(0, -h * 0.065, -h * 0.2 - sn)
	hb.add("sphere", tip + Vector3(0, h * 0.035, -h * 0.02), Vector3(0.08, 0.06, 0.065) * h, Color(0.06, 0.05, 0.05), Vector3.ZERO, 10)   # burun
	Loft.tube(hb, [tip + Vector3(0, h * 0.0, -h * 0.045), tip + Vector3(0, -h * 0.045, -h * 0.03)], [h * 0.008, h * 0.008], LINE, 5, 2)
	for sx in [-1.0, 1.0]:
		# ağız çizgisi: burundan yana, yanağa doğru hafif yukarı
		Loft.tube(hb, [tip + Vector3(0, -h * 0.045, -h * 0.03), tip + Vector3(sx * h * 0.06, -h * 0.06, h * 0.0), tip + Vector3(sx * h * 0.105, -h * 0.035, sn * 0.6 + h * 0.03)], [h * 0.008, h * 0.009, h * 0.006], LINE, 5, 3)
		var ep = Vector3(sx * h * 0.1, h * 0.055, -h * 0.185)
		if String(sp.get("eyes", "open")) == "closed":   # kapalı, gülen göz (aşağı açık kavis)
			Loft.tube(hb, [ep + Vector3(-sx * h * 0.045, -h * 0.005, -h * 0.005), ep + Vector3(0, h * 0.025, -h * 0.02), ep + Vector3(sx * h * 0.05, -h * 0.01, h * 0.01)], [h * 0.01, h * 0.016, h * 0.01], LINE, 6, 3)
		else:
			hb.add("sphere", ep, Vector3(0.1, 0.075, 0.05) * h, white, Vector3(0, sx * 18, 0), 10)
			hb.add("sphere", ep + Vector3(-sx * h * 0.008, -h * 0.004, -h * 0.02), Vector3(0.036, 0.045, 0.025) * h, LINE, Vector3.ZERO, 8)
			Loft.tube(hb, [ep + Vector3(-sx * h * 0.06, h * 0.03, -h * 0.02), ep + Vector3(0, h * 0.05, -h * 0.015), ep + Vector3(sx * h * 0.065, h * 0.055, h * 0.02)], [h * 0.012, h * 0.016, h * 0.008], LINE, 6, 3)   # sert kaş
		if sp.get("eye_ring", false):
			hb.add("sphere", ep + Vector3(0, 0, h * 0.012), Vector3(0.15, 0.12, 0.05) * h, earc, Vector3(0, sx * 18, 0), 10)
		if sp.get("glasses", false):
			hb.add("sphere", ep + Vector3(0, 0, -h * 0.03), Vector3(0.125, 0.11, 0.035) * h, Color(0.03, 0.03, 0.04), Vector3(0, sx * 14, 0), 12)
		if sp.get("whisker", false):
			for k in 3:
				Loft.tube(hb, [Vector3(sx * h * 0.13, -h * 0.03 - k * h * 0.03, -h * 0.17), Vector3(sx * h * 0.2, -h * 0.02 - k * h * 0.04, -h * 0.12)], [h * 0.007, h * 0.004], LINE, 4, 2)
		# kulak
		match String(sp.get("ear", "prick")):
			"prick":
				var e0 = Vector3(sx * h * 0.13, h * 0.13, h * 0.03)
				Loft.tube(hb, [e0, e0 + Vector3(sx * 0.05, 0.13, 0.0) * h, e0 + Vector3(sx * 0.09, 0.27, -0.01) * h], [Vector2(0.085, 0.035) * h, Vector2(0.065, 0.028) * h, Vector2(0.006, 0.006) * h], c, 10, 4, true, false)
				Loft.tube(hb, [e0 + Vector3(0, 0.02, -0.025) * h, e0 + Vector3(sx * 0.05, 0.12, -0.022) * h, e0 + Vector3(sx * 0.08, 0.22, -0.02) * h], [Vector2(0.05, 0.012) * h, Vector2(0.038, 0.01) * h, Vector2(0.004, 0.004) * h], earc, 8, 3, true, false)
			"flop", "long":
				var ln = 0.3 if sp["ear"] == "flop" else 0.46
				var k0 = Vector3(sx * h * 0.19, h * 0.12, h * 0.04)
				Loft.tube(hb, [k0, k0 + Vector3(sx * 0.08, -ln * 0.3, -0.01) * h, k0 + Vector3(sx * 0.1, -ln * 0.75, -0.02) * h, k0 + Vector3(sx * 0.07, -ln, -0.01) * h],
					[Vector2(0.03, 0.08) * h, Vector2(0.035, 0.105) * h, Vector2(0.035, 0.11) * h, Vector2(0.02, 0.06) * h], earc, 12, 4, true, true, Callable(), Vector3(0, 0, 1))
		# yanak tutamları
		for k in int(3 * fluff + 0.5):
			BeastRig.claw(hb, Vector3(sx * h * 0.19, -h * 0.02 - k * h * 0.045, h * 0.0), Vector3(sx, -0.25 - k * 0.3, 0.15), h * 0.15, h * 0.05, mz if k > 0 else c)
	if sp.has("crest"):   # ibik: alından enseye dik tutamlar
		var cl := float(sp.get("crest_len", 0.22))
		for k in 5:
			BeastRig.claw(hb, Vector3(0, h * 0.17, -h * 0.08 + k * h * 0.055), Vector3(0, 1, -0.15 + k * 0.2), h * cl * (1.0 - absf(k - 1.5) * 0.12), h * 0.05, sp["crest"])
	if sp.has("bangs"):
		for k in 7:
			BeastRig.claw(hb, Vector3((k - 3) * h * 0.05, h * 0.2, -h * 0.02), Vector3((k - 3) * 0.3, 0.15 - absf(k - 3) * 0.12, -1), h * 0.2, h * 0.055, sp["bangs"])
			BeastRig.claw(hb, Vector3((k - 3) * h * 0.05, h * 0.21, h * 0.05), Vector3((k - 3) * 0.4, 0.8, 0.5), h * 0.16, h * 0.05, sp["bangs"])
	if sp.get("head_band", false):   # alın bandı + metal plaka
		Loft.tube(hb, [Vector3(0, h * 0.06, h * 0.1), Vector3(0, h * 0.13, -h * 0.1)], [h * 0.215, h * 0.2], blue, 16, 2, false, false)
		hb.add("box", Vector3(0, h * 0.165, -h * 0.17), Vector3(0.17, 0.07, 0.03) * h, Color(0.78, 0.8, 0.84), Vector3(-35, 0, 0))
	if sp.get("bandage", false):   # baş sargısı: alın ve tepe (gözler açıkta)
		for k in 4:
			Loft.tube(hb, [Vector3(0, h * (0.07 + k * 0.03), h * (0.12 - k * 0.04)), Vector3(0, h * (0.13 + k * 0.02), -h * (0.06 + k * 0.02))], [h * (0.215 - k * 0.012), h * (0.2 - k * 0.014)], white, 16, 2, false, false)
	if sp.get("kanji", false):
		for q in [[Vector3(0, 0.165, -0.165), Vector3(0.07, 0.012, 0.012)], [Vector3(0, 0.14, -0.175), Vector3(0.012, 0.05, 0.012)], [Vector3(0, 0.12, -0.18), Vector3(0.06, 0.012, 0.012)]]:
			hb.add("box", q[0] * h, q[1] * h, LINE, Vector3(-30, 0, 0))
	if sp.get("eyepatch", false):   # Kuromaru: sağ gözde siyah bant
		hb.add("sphere", Vector3(-h * 0.1, h * 0.055, -h * 0.2), Vector3(0.12, 0.11, 0.04) * h, LINE, Vector3(0, -18, 0), 10)
		Loft.tube(hb, [Vector3(-h * 0.2, h * 0.1, -h * 0.02), Vector3(-h * 0.1, h * 0.1, -h * 0.2), Vector3(h * 0.12, h * 0.19, -h * 0.1)], [h * 0.012, h * 0.012, h * 0.012], LINE, 5, 3)
	_mesh(head, hb)
	out["heads"].append(head)
	# ---- bacaklar: omuz/kalça kası, incelen incik, iri pati
	var sock: Color = under if sp.get("socks", false) else c
	for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var front = q.z < 0
		var hip = Vector3(q.x * h * 0.15 * g, by - h * 0.04, (-L * 0.3 if front else L * 0.36))
		var pv = _pivot(root, hip)
		var lb = MB.new()
		var knee = Vector3(0, -hip.y * 0.48, (h * 0.03 if front else -h * 0.08))
		var paw = Vector3(0, -hip.y + h * 0.07, (0.0 if front else h * 0.02))
		Loft.tube(lb, [Vector3(0, h * 0.04, 0), knee, paw], [Vector2(0.105, 0.14 if front else 0.17) * h * g, Vector2(0.075, 0.08) * h, Vector2(0.065, 0.065) * h], [c, c.lerp(sock, 0.6), sock], 14, 4)
		lb.add("sphere", paw + Vector3(0, -h * 0.025, -h * 0.045), Vector3(0.15, 0.09, 0.2) * h, sock, Vector3.ZERO, 10)
		for f in 3:
			lb.add("sphere", paw + Vector3((f - 1) * h * 0.045, -h * 0.04, -h * 0.13), Vector3(0.05, 0.05, 0.06) * h, sock, Vector3.ZERO, 6)
		_mesh(pv, lb)
		out["legs"].append(pv)
	# ---- kuyruk
	var tail = _pivot(root, Vector3(0, by + h * 0.1, L * 0.5))
	var tb = MB.new()
	match String(sp.get("tail", "curl")):
		"curl":   # sırta doğru kıvrık kısa kuyruk
			Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.2, h * 0.12), Vector3(0, h * 0.36, h * 0.02), Vector3(0, h * 0.34, -h * 0.14)], [h * 0.06, h * 0.09, h * 0.085, h * 0.03], [c, c, under, under], 12, 4, true, true)
		"plume":   # gür, geriye-yukarı
			Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.12, h * 0.24), Vector3(0, h * 0.34, h * 0.42), Vector3(0, h * 0.56, h * 0.44)], [h * 0.07, h * 0.13, h * 0.12, h * 0.02], [c, c, c, under], 12, 4, true, true)
			for k in 8:
				BeastRig.claw(tb, Vector3(0, h * (0.1 + k * 0.05), h * (0.22 + k * 0.03)), Vector3(0, -0.4, 1), h * 0.14, h * 0.05, c)
		_:   # ince, uzun
			Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.02, h * 0.25), Vector3(0, h * 0.12, h * 0.45), Vector3(0, h * 0.26, h * 0.56)], [h * 0.045, h * 0.04, h * 0.03, h * 0.012], [c, c, c, under], 10, 4, true, true)
	_mesh(tail, tb)
	out["tail"] = tail
	return out


## Inuzuka ninken türleri: renk (COATS) + tür özellikleri. 0 Akamaru tipi (sarkık kulak, kapalı gülen göz, kıvrık kuyruk, tepe tutamı),
## 1 Kuromaru tipi (kurt: dik kulak, dikenli tüy, beyaz ağız, göz bandı), 2 Haimaru tipi (gri, dik kulak, beyaz ağız/çorap); diğerleri karışık.
static func akamaru(h := 1.3, coat := 0) -> Dictionary:
	var i = coat % COATS.size()
	var sp := {"c": COATS[i][0], "under": COATS[i][1], "earc": COATS[i][2], "ear": "flop", "snout": 0.17, "girth": 1.08, "head": 1.3, "fluff": 1.0,
		"tail": "curl", "eyes": "closed", "crest": COATS[i][0], "crest_len": 0.13}
	match i:
		1:
			sp.merge({"ear": "prick", "shag": true, "muzzle": true, "eyes": "open", "tail": "plume", "snout": 0.24, "eyepatch": true, "head": 1.15, "socks": true}, true)
			sp.erase("crest")
		2, 9:
			sp.merge({"ear": "prick", "muzzle": true, "socks": true, "eyes": "open", "tail": "plume", "snout": 0.22, "head": 1.15}, true)
			sp.erase("crest")
		3, 7:
			sp.merge({"ear": "long", "eyes": "open", "tail": "whip", "snout": 0.22, "muzzle": true}, true)
		6:
			sp.merge({"ear": "prick", "shag": true, "eyes": "open", "tail": "plume", "snout": 0.24, "head": 1.15}, true)
			sp.erase("crest")
	return dog(h, sp)


## ------------------------------------------------------------------ İki/üç başlı kurt (Sōtōrō / Santōrō) — sıfırdan
## refs/summons2/human_beast_*: bembeyaz, kabarık yeleli dev kurt; öne çökmüş saldırı duruşu, geniş göğüs ve omuz kamburu, uzun bacaklar, iri pati + siyah pençe,
## kalın boyunlar yana açılır; uzun burunlu kurt başları — açık çene, sivri dişler, salya, küçük kırmızı gözler, çatık siyah kaş, yanak yelesi; yukarı kıvrık gür kuyruk.
## h = omuz yüksekliği. Dönen: root, legs (4 pivot), tail, heads (pivotlar), jaws (alt çene pivotları).
static func twin_wolf(heads := 2, h := 4.4, coat := 0) -> Dictionary:
	var out = {"root": Node3D.new(), "legs": [], "tail": null, "heads": [], "jaws": []}
	var root: Node3D = out["root"]
	var c: Color = WOLF if coat == 0 else COATS[coat % COATS.size()][0]
	var sh: Color = c.darkened(0.13)
	var LINE = Color(0.08, 0.06, 0.07)
	var tooth = Color(0.98, 0.97, 0.92)
	var by = h * 0.6
	var L = h * 1.2
	var rng = RandomNumberGenerator.new()
	rng.seed = 21
	var b = MB.new()
	var fur = func(_t: float, a: float, _d: Vector3) -> Color:
		return c.lerp(sh, smoothstep(-0.3, -0.85, sin(a)))
	Loft.tube(b, [Vector3(0, by + h * 0.06, L * 0.5), Vector3(0, by + h * 0.02, L * 0.18), Vector3(0, by + h * 0.0, -L * 0.2), Vector3(0, by + h * 0.1, -L * 0.42)],
		[Vector2(0.2, 0.22) * h, Vector2(0.2, 0.22) * h, Vector2(0.32, 0.38) * h, Vector2(0.34, 0.36) * h], c, 24, 6, true, true, fur)
	# omuz yelesi: kamburun üstünden geriye ve yanlara dökülen uzun tutamlar
	for k in 44:
		var a = rng.randf_range(-0.5, PI + 0.5)
		var z = rng.randf_range(-L * 0.46, -L * 0.02)
		var o = Vector3(cos(a) * h * 0.32, by + h * 0.06 + sin(a) * h * 0.36, z)
		BeastRig.claw(b, o, Vector3(cos(a) * 0.6, sin(a) * 0.5 - 0.35, 1.0), h * rng.randf_range(0.2, 0.34), h * 0.07, c if k % 3 else sh)
	for k in 14:   # sırt hattı + karın saçağı
		var z2 = lerpf(-L * 0.1, L * 0.46, k / 13.0)
		BeastRig.claw(b, Vector3(0, by + h * 0.24, z2), Vector3(0, 0.6, 1), h * 0.16, h * 0.05, c)
		BeastRig.claw(b, Vector3(0, by - h * 0.2, z2), Vector3(0, -1, 0.5), h * 0.14, h * 0.05, sh)
	var hx: Array = [-0.3, 0.3] if heads == 2 else [-0.36, 0.0, 0.36]
	var S = h * 0.47
	for i in hx.size():
		var x: float = hx[i]
		var mid = heads == 3 and i == 1
		var n0 = Vector3(x * h * 0.5, by + h * 0.16, -L * 0.4)
		var hp = Vector3(x * h * 1.1, by + h * (0.62 if mid else 0.3), -L * 0.42 - h * (0.3 if mid else 0.52))
		Loft.tube(b, [n0, n0.lerp(hp, 0.5) + Vector3(0, h * 0.06, 0), hp + Vector3(0, 0, S * 0.3)], [h * 0.24, h * 0.2, h * 0.17], c, 16, 4, true, true, fur)
		for k in 14:   # boyun yelesi
			var a3 = lerpf(-2.7, 2.7, k / 13.0)
			var q = n0.lerp(hp, 0.6)
			BeastRig.claw(b, q + Vector3(sin(a3) * h * 0.2, cos(a3) * h * 0.2, 0), Vector3(sin(a3) * 0.7, cos(a3) * 0.4 - 0.5, 0.9), h * 0.3, h * 0.07, c if k % 2 else sh)
		var head = _pivot(root, hp)
		head.rotation = Vector3(0.12, -x * 0.5, 0)
		var hb = MB.new()
		Loft.blob(hb, Vector3(0, S * 0.05, S * 0.05), Vector3(0, 0.1, -1), S * 1.3, [Vector2(0.36, 0.34) * S, Vector2(0.56, 0.5) * S, Vector2(0.52, 0.46) * S, Vector2(0.34, 0.3) * S], c, 18)
		# üst çene: uzun, öne incelen burun; ucu hafif kalkık
		Loft.tube(hb, [Vector3(0, -S * 0.02, -S * 0.45), Vector3(0, -S * 0.04, -S * 0.95), Vector3(0, -S * 0.02, -S * 1.5)], [Vector2(0.34, 0.24) * S, Vector2(0.27, 0.19) * S, Vector2(0.2, 0.14) * S], c, 16, 4)
		hb.add("sphere", Vector3(0, S * 0.06, -S * 1.56), Vector3(0.22, 0.16, 0.16) * S, LINE, Vector3.ZERO, 10)   # burun
		hb.add("sphere", Vector3(0, -S * 0.14, -S * 0.95), Vector3(0.46, 0.08, 1.1) * S, Color(0.3, 0.1, 0.14), Vector3.ZERO, 10)   # damak (koyu)
		for sx in [-1.0, 1.0]:
			for k in 6:   # üst dişler: önde iki uzun köpek dişi
				var tz = -S * (1.42 - k * 0.17)
				BeastRig.claw(hb, Vector3(sx * S * (0.14 + k * 0.022), -S * 0.14, tz), Vector3(0, -1, 0.08), S * (0.26 if k == 0 else 0.12), S * 0.04, tooth)
			var ep = Vector3(sx * S * 0.27, S * 0.26, -S * 0.56)
			hb.add("sphere", ep, Vector3(0.25, 0.19, 0.2) * S, tooth, Vector3(0, sx * 20, -sx * 14), 10)
			hb.add("sphere", ep + Vector3(sx * S * 0.03, S * 0.005, -S * 0.065), Vector3(0.12, 0.13, 0.1) * S, Color(0.85, 0.1, 0.1), Vector3.ZERO, 8)
			hb.add("sphere", ep + Vector3(sx * S * 0.04, S * 0.005, -S * 0.105), Vector3(0.045, 0.05, 0.04) * S, LINE, Vector3.ZERO, 6)
			Loft.tube(hb, [ep + Vector3(-sx * S * 0.15, S * 0.07, -S * 0.1), ep + Vector3(0, S * 0.14, -S * 0.05), ep + Vector3(sx * S * 0.18, S * 0.2, S * 0.04)], [S * 0.025, S * 0.04, S * 0.02], LINE, 6, 3)   # çatık kaş
			# kulak: sivri, geriye yatık
			var e0 = Vector3(sx * S * 0.36, S * 0.36, S * 0.2)
			Loft.tube(hb, [e0, e0 + Vector3(sx * 0.1, 0.26, 0.14) * S, e0 + Vector3(sx * 0.16, 0.52, 0.34) * S], [Vector2(0.18, 0.07) * S, Vector2(0.13, 0.05) * S, Vector2(0.01, 0.01) * S], c, 10, 3, true, false)
			for k in 8:   # yanak yelesi: baştan aşağı sarkan uzun tutamlar
				BeastRig.claw(hb, Vector3(sx * S * (0.5 - k * 0.02), S * (0.25 - k * 0.07), S * (0.3 - k * 0.09)), Vector3(sx * 0.45, -1.0, 0.25), S * (0.75 + (k % 3) * 0.18), S * 0.15, c if k % 2 else sh)
		for k in 5:   # alın tutamı
			BeastRig.claw(hb, Vector3((k - 2) * S * 0.1, S * 0.46, -S * 0.05), Vector3((k - 2) * 0.15, 0.7, 1), S * 0.36, S * 0.1, c)
		_mesh(head, hb)
		# alt çene (pivot): açık, dişli, dil, çene sakalı, salya
		var jaw = _pivot(head, Vector3(0, -S * 0.2, -S * 0.3))
		jaw.rotation.x = -0.42
		var jb = MB.new()
		Loft.tube(jb, [Vector3(0, 0, S * 0.1), Vector3(0, -S * 0.02, -S * 0.55), Vector3(0, 0, -S * 1.1)], [Vector2(0.3, 0.14) * S, Vector2(0.23, 0.11) * S, Vector2(0.15, 0.08) * S], c, 14, 4)
		jb.add("sphere", Vector3(0, S * 0.08, -S * 0.5), Vector3(0.3, 0.07, 0.95) * S, Color(0.78, 0.3, 0.36), Vector3.ZERO, 10)   # dil
		for sx in [-1.0, 1.0]:
			for k in 5:
				BeastRig.claw(jb, Vector3(sx * S * (0.11 + k * 0.022), S * 0.08, -S * (1.02 - k * 0.17)), Vector3(0, 1, 0.05), S * (0.22 if k == 0 else 0.1), S * 0.035, tooth)
		for k in 5:
			BeastRig.claw(jb, Vector3((k - 2) * S * 0.07, -S * 0.1, -S * 0.3), Vector3((k - 2) * 0.15, -1, 0.3), S * 0.4, S * 0.1, c)
		for k in 2:   # salya
			Loft.tube(jb, [Vector3((k - 0.5) * S * 0.3, S * 0.02, -S * (0.7 + k * 0.2)), Vector3((k - 0.5) * S * 0.32, -S * (0.5 + k * 0.3), -S * (0.75 + k * 0.2))], [S * 0.03, S * 0.012], Color(0.82, 0.92, 1.0), 5, 2)
		_mesh(jaw, jb)
		out["heads"].append(head)
		out["jaws"].append(jaw)
	_mesh(root, b)
	# bacaklar: uzun, dirsekte tüy; iri pati, dört siyah pençe
	for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var front = q.z < 0
		var hip = Vector3(q.x * h * (0.26 if front else 0.17), by - h * 0.02, (-L * 0.34 if front else L * 0.38))
		var pv = _pivot(root, hip)
		var lb = MB.new()
		var knee = Vector3(q.x * h * 0.02, -hip.y * 0.46, (h * 0.07 if front else -h * 0.14))
		var paw = Vector3(q.x * h * 0.03, -hip.y + h * 0.08, (-h * 0.06 if front else h * 0.02))
		Loft.tube(lb, [Vector3(0, h * 0.06, 0), knee, paw], [Vector2(0.13, 0.17 if front else 0.22) * h, Vector2(0.09, 0.1) * h, Vector2(0.075, 0.075) * h], c, 14, 4)
		lb.add("sphere", paw + Vector3(0, -h * 0.03, -h * 0.07), Vector3(0.2, 0.1, 0.28) * h, c, Vector3.ZERO, 10)
		for f in 4:
			BeastRig.claw(lb, paw + Vector3((f - 1.5) * h * 0.045, -h * 0.03, -h * 0.19), Vector3(0, -0.55, -1), h * 0.11, h * 0.022, LINE)
		for k in 4:
			BeastRig.claw(lb, knee + Vector3(0, h * 0.08 - k * h * 0.07, h * 0.05), Vector3(0, -0.5, 1), h * 0.16, h * 0.05, sh)
		_mesh(pv, lb)
		out["legs"].append(pv)
	# kuyruk: yukarı kıvrık, gür
	var tail = _pivot(root, Vector3(0, by + h * 0.12, L * 0.5))
	var tb = MB.new()
	var tp = [Vector3.ZERO, Vector3(0, h * 0.16, h * 0.28), Vector3(0, h * 0.46, h * 0.44), Vector3(0, h * 0.76, h * 0.34), Vector3(0, h * 0.9, h * 0.12)]
	Loft.tube(tb, tp, [h * 0.08, h * 0.14, h * 0.15, h * 0.11, h * 0.02], c, 14, 5, true, true)
	for k in 14:
		var u = k / 13.0
		var at: Vector3 = tp[1].lerp(tp[3], u)
		BeastRig.claw(tb, at, Vector3((k % 3 - 1) * 0.4, -0.3, 1), h * 0.2, h * 0.06, c if k % 2 else sh)
	_mesh(tail, tb)
	out["tail"] = tail
	return out
