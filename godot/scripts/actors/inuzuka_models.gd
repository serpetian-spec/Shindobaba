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
static func akamaru(h := 1.3) -> Dictionary:
	var out = {"root": Node3D.new(), "legs": [], "tail": null, "heads": [], "jaws": []}
	var root: Node3D = out["root"]
	var c = FUR
	var belly = Color(1.0, 0.98, 0.94)
	var ear = Color(0.45, 0.32, 0.27)
	var leg = h * 0.55
	var by = h * 0.72   # gövde ekseni
	var L = h * 1.35
	var b = MB.new()
	# fıçı gövde: derin göğüs, kalın bel, yuvarlak kalça
	Loft.tube(b, [Vector3(0, by, L * 0.48), Vector3(0, by + h * 0.04, L * 0.2), Vector3(0, by + h * 0.02, -L * 0.15), Vector3(0, by + h * 0.04, -L * 0.42)],
		[Vector2(0.4, 0.4) * h, Vector2(0.43, 0.44) * h, Vector2(0.46, 0.5) * h, Vector2(0.42, 0.48) * h], c, 18, 4)
	# tüy kabuğu: bütün gövdeyi saran, aşağı dökülen kabarık cel tutamlar (referans: tüy yumağı)
	var rngf = RandomNumberGenerator.new()
	rngf.seed = 7
	for k in 70:
		var a = rngf.randf_range(-PI * 0.95, 0.15)   # yalnız yanlar ve alt kenar (sırt pürüzsüz)
		var z = rngf.randf_range(-L * 0.45, L * 0.48)
		var rr = h * 0.44
		var o = Vector3(cos(a) * rr, by + sin(a) * rr * 1.05, z)
		var dv = Vector3(cos(a) * 0.35, -1.0, 0.1).normalized()   # yüzeye yatık, aşağı dökülen
		BeastRig.claw(b, o, dv, h * rngf.randf_range(0.1, 0.17), h * 0.075, c.darkened(rngf.randf_range(0.0, 0.05)))
	# göğüs yelesi ve boyun kabarık tüyü (referans: çenenin altından göğse dökülen tüy)
	_tufts(b, Vector3(0, by - h * 0.05, -L * 0.52), Vector3(0, -0.6, -1), 40, h * 0.3, h * 0.07, c, 0.7, 11)
	_tufts(b, Vector3(0, by + h * 0.25, -L * 0.3), Vector3(0, 1, 0.2), 10, h * 0.14, h * 0.05, c.darkened(0.04), 0.6, 12)
	for sx in [-1.0, 1.0]:   # yanlarda dökük tüy
		_tufts(b, Vector3(sx * h * 0.32, by - h * 0.15, 0), Vector3(sx, -0.8, 0), 14, h * 0.18, h * 0.05, c, 0.5, 13 + int(sx))
	_mesh(root, b)
	# baş (pivot): büyük yuvarlak kafa, orta boy kalın burun, iri siyah burun, kısık kapalı gözler, sarkık dudak, sarkık kulaklar
	var head = _pivot(root, Vector3(0, by + h * 0.36, -L * 0.56))
	head.scale = Vector3.ONE * 1.45   # referans: baş gövdeye göre çok iri
	var hb = MB.new()
	Loft.blob(hb, Vector3(0, h * 0.04, h * 0.02), Vector3(0, 0.2, -1), h * 0.5, [Vector2(0.18, 0.16) * h, Vector2(0.27, 0.26) * h, Vector2(0.26, 0.25) * h, Vector2(0.14, 0.12) * h], c, 16)
	# geniş, kısa, sarkık yanaklı ağız-burun bölgesi
	Loft.tube(hb, [Vector3(0, -h * 0.04, -h * 0.14), Vector3(0, -h * 0.07, -h * 0.3), Vector3(0, -h * 0.08, -h * 0.42)], [Vector2(0.19, 0.15) * h, Vector2(0.16, 0.13) * h, Vector2(0.11, 0.09) * h], c, 14, 3)
	for sx2 in [-1.0, 1.0]:
		Loft.blob(hb, Vector3(sx2 * h * 0.1, -h * 0.13, -h * 0.25), Vector3(0, -1, 0), h * 0.16, [Vector2(0.06, 0.07) * h, Vector2(0.08, 0.09) * h, Vector2(0.05, 0.06) * h], c, 10)   # sarkık yanak
	hb.add("sphere", Vector3(0, -h * 0.03, -h * 0.46), Vector3(0.13, 0.09, 0.09) * h, Color(0.08, 0.06, 0.06), Vector3.ZERO, 10)   # iri siyah burun
	var LINE = Color(0.14, 0.1, 0.1)
	# ağız: burundan inen çizgi, iki yana sarkık yanaklara doğru kıvrılır ("w")
	Loft.tube(hb, [Vector3(0, -h * 0.08, -h * 0.47), Vector3(0, -h * 0.13, -h * 0.45)], [h * 0.012, h * 0.012], LINE, 5, 2)
	for sx in [-1.0, 1.0]:
		# sarkık dudak (jowl) ve ağız çizgisi
		Loft.tube(hb, [Vector3(0, -h * 0.13, -h * 0.45), Vector3(sx * h * 0.07, -h * 0.17, -h * 0.42), Vector3(sx * h * 0.13, -h * 0.15, -h * 0.36), Vector3(sx * h * 0.17, -h * 0.19, -h * 0.28)], [h * 0.012, h * 0.016, h * 0.014, h * 0.008], LINE, 5, 2)
		# kısık kapalı gözler: aşağı kıvrık koyu kavis
		var e0 = Vector3(sx * h * 0.05, h * 0.14, -h * 0.22)
		Loft.tube(hb, [e0, e0 + Vector3(sx * h * 0.05, h * 0.025, h * 0.01), e0 + Vector3(sx * h * 0.11, -h * 0.005, h * 0.035)], [h * 0.016, h * 0.022, h * 0.012], LINE, 5, 2)   # kısık kapalı göz
		Loft.tube(hb, [e0 + Vector3(0, h * 0.07, 0.0), e0 + Vector3(sx * h * 0.05, h * 0.1, h * 0.01), e0 + Vector3(sx * h * 0.1, h * 0.085, h * 0.03)], [h * 0.008, h * 0.012, h * 0.006], LINE, 5, 2)   # kaş
		# sarkık kulak: kafanın yanından aşağı uzanan yassı, uçta yuvarlanan kahverengi lob
		var k0 = Vector3(sx * h * 0.2, h * 0.16, h * 0.04)
		Loft.tube(hb, [k0, k0 + Vector3(sx * h * 0.08, -h * 0.12, -h * 0.02), k0 + Vector3(sx * h * 0.1, -h * 0.32, -h * 0.03), k0 + Vector3(sx * h * 0.08, -h * 0.44, -h * 0.02)],
			[Vector2(0.025, 0.07) * h, Vector2(0.03, 0.09) * h, Vector2(0.03, 0.09) * h, Vector2(0.02, 0.05) * h], ear, 10, 3, true, true, Callable(), Vector3(0, 0, 1))
		_tufts(hb, Vector3(sx * h * 0.2, -h * 0.12, -h * 0.08), Vector3(sx * 0.6, -1, 0), 10, h * 0.16, h * 0.04, c, 0.4, 20 + int(sx))   # yanak/sakal tüyü
	_tufts(hb, Vector3(0, h * 0.26, h * 0.04), Vector3(0, 1, 0.3), 7, h * 0.2, h * 0.04, c, 0.5, 30)   # tepe perçemi (dikenli)
	_mesh(head, hb)
	out["heads"].append(head)
	# bacaklar: kalın, tüylü, iri pati
	for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var front = q.z < 0
		var pv = _pivot(root, Vector3(q.x * h * 0.2, by - h * 0.05, q.z * L * (0.3 if front else 0.33)))
		var lb = MB.new()
		var knee = Vector3(q.x * h * 0.01, -leg * 0.45, (h * 0.03 if front else -h * 0.08))
		var paw = Vector3(0, -(by - h * 0.05) + h * 0.06, -h * 0.02)
		Loft.tube(lb, [Vector3.ZERO, knee, paw], [Vector2(0.2, 0.22) * h, Vector2(0.15, 0.15) * h, Vector2(0.12, 0.12) * h], c, 12, 3)
		for kk in 3:   # bacağı örten dökük tüy
			_tufts(lb, Vector3(0, -leg * (0.2 + kk * 0.25), 0), Vector3(0, -1, 0), 6, h * 0.14, h * 0.05, c, 0.5, 200 + kk + out["legs"].size() * 3)
		lb.add("sphere", paw + Vector3(0, -h * 0.02, -h * 0.05), Vector3(0.2, 0.1, 0.24) * h, c.darkened(0.03), Vector3.ZERO, 10)
		_tufts(lb, knee, Vector3(0, -0.3, 0.6 if front else -0.6), 5, h * 0.1, h * 0.03, c, 0.4, 40 + out["legs"].size())
		_mesh(pv, lb)
		out["legs"].append(pv)
	# kuyruk: yukarı kıvrık, tüylü
	var tail = _pivot(root, Vector3(0, by + h * 0.1, L * 0.5))
	var tb = MB.new()
	Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.2, h * 0.14), Vector3(0, h * 0.4, h * 0.08), Vector3(0, h * 0.48, -h * 0.1)], [h * 0.1, h * 0.15, h * 0.14, h * 0.05], c, 12, 3, true, false)
	_tufts(tb, Vector3(0, h * 0.34, h * 0.1), Vector3(0, 0.3, 1), 16, h * 0.18, h * 0.05, c, 0.7, 50)
	_mesh(tail, tb)
	out["tail"] = tail
	return out


## ------------------------------------------------------------------ İki/üç başlı kurt (Sōtōrō / Santōrō)
## Ölçek: h = omuz yüksekliği (~4.4 m). Referans: bembeyaz, uzun kırık bacaklı, kambur ve sinsi eğik duruş; omuz ve boyunlarda
## gür yele; iri kurt başları — açık çene, sivri dişler, kırmızı gözler, çatık kaş, siyah burun; çene altında tüy sakalı;
## uzun yukarı kıvrık kuyruk; kalın siyah pençeler.
static func twin_wolf(heads := 2, h := 4.4) -> Dictionary:
	var out = {"root": Node3D.new(), "legs": [], "tail": null, "heads": [], "jaws": []}
	var root: Node3D = out["root"]
	var c = WOLF
	var sh = Color(0.86, 0.87, 0.9)
	var L = h * 1.15
	var by = h * 0.5   # sinmiş, alçak duruş
	var b = MB.new()
	# gövde: önde yüksek omuz, arkaya düşen bel (kambur, sinsi duruş)
	Loft.tube(b, [Vector3(0, by - h * 0.05, L * 0.5), Vector3(0, by, L * 0.2), Vector3(0, by + h * 0.08, -L * 0.15), Vector3(0, by + h * 0.12, -L * 0.42)],
		[Vector2(0.25, 0.25) * h, Vector2(0.23, 0.26) * h, Vector2(0.3, 0.34) * h, Vector2(0.33, 0.37) * h], c, 18, 4)
	# omuz ve boyun yelesi: gür, dışa savrulan cel tutamlar
	_tufts(b, Vector3(0, by + h * 0.2, -L * 0.3), Vector3(0, 1, 0.3), 30, h * 0.22, h * 0.05, c, 0.9, 61)
	for sx in [-1.0, 1.0]:
		_tufts(b, Vector3(sx * h * 0.25, by + h * 0.05, -L * 0.32), Vector3(sx, 0.3, 0.2), 16, h * 0.2, h * 0.05, sh, 0.6, 62 + int(sx))
		_tufts(b, Vector3(sx * h * 0.2, by - h * 0.1, L * 0.1), Vector3(sx, -0.5, 0.3), 10, h * 0.14, h * 0.04, c, 0.5, 64 + int(sx))
	_tufts(b, Vector3(0, by + h * 0.15, L * 0.05), Vector3(0, 1, 0.6), 12, h * 0.12, h * 0.04, sh, 0.5, 66)
	_mesh(root, b)
	# başlar: iki (ya da üç) iri kurt başı, boyunlar omuzdan öne-yukarı
	var hx: Array = [-0.22, 0.22] if heads == 2 else [-0.3, 0.0, 0.3]
	for i in hx.size():
		var x = float(hx[i]) * h
		var neck0 = Vector3(x * 0.6, by + h * 0.12, -L * 0.42)
		var hp = Vector3(x * 1.3, by + h * 0.18 - absf(float(hx[i])) * h * 0.08, -L * 0.6)
		var nb = MB.new()
		Loft.tube(nb, [neck0, neck0.lerp(hp, 0.5) + Vector3(0, h * 0.04, 0), hp], [Vector2(0.16, 0.18) * h, Vector2(0.14, 0.16) * h, Vector2(0.12, 0.13) * h], c, 14, 3)
		_tufts(nb, neck0.lerp(hp, 0.5) + Vector3(0, h * 0.1, h * 0.02), Vector3(0, 1, 0.4), 18, h * 0.24, h * 0.05, c, 0.8, 70 + i)
		_tufts(nb, hp + Vector3(0, h * 0.02, h * 0.12), Vector3(0, 0.6, 1), 22, h * 0.26, h * 0.06, c, 0.9, 75 + i)   # başın arkasını saran yele
		for sx3 in [-1.0, 1.0]:
			_tufts(nb, hp + Vector3(sx3 * h * 0.14, -h * 0.05, h * 0.06), Vector3(sx3, -0.4, 0.4), 10, h * 0.2, h * 0.05, c, 0.6, 78 + i + int(sx3))
		_mesh(root, nb)
		var head = _pivot(root, hp)
		head.rotation.y = -float(hx[i]) * 0.5   # başlar biraz dışa bakar
		head.rotation.x = 0.1
		var S = h * 0.42   # baş birimi: referansta baş gövdeye göre iri
		var hb = MB.new()
		# kafatası: geniş, yuvarlak; yanaklarda kabarık tüy
		hb.add("sphere", Vector3(0, S * 0.1, S * 0.05), Vector3(1.0, 0.85, 0.95) * S, c, Vector3.ZERO, 16)
		# kısa, geniş burun (üst çene): kafatasından öne
		Loft.tube(hb, [Vector3(0, S * 0.05, -S * 0.3), Vector3(0, S * 0.02, -S * 0.6), Vector3(0, -S * 0.02, -S * 0.82)], [Vector2(0.3, 0.22) * S, Vector2(0.24, 0.18) * S, Vector2(0.17, 0.13) * S], c, 14, 3)
		hb.add("sphere", Vector3(0, S * 0.05, -S * 0.86), Vector3(0.2, 0.14, 0.13) * S, Color(0.1, 0.07, 0.07), Vector3.ZERO, 8)   # siyah burun
		# üst dudak kenarı (koyu çizgi) ve üst diş sırası: ağzın tavanından aşağı sivri dişler, önde iki iri köpek dişi
		for sx in [-1.0, 1.0]:
			Loft.tube(hb, [Vector3(sx * S * 0.05, -S * 0.1, -S * 0.82), Vector3(sx * S * 0.2, -S * 0.12, -S * 0.6), Vector3(sx * S * 0.3, -S * 0.1, -S * 0.3)], [S * 0.025, S * 0.03, S * 0.02], Color(0.2, 0.15, 0.15), 5, 2)
			for k in 4:
				var z = -S * (0.78 - k * 0.12)
				var tx = sx * S * (0.07 + k * 0.06)
				BeastRig.claw(hb, Vector3(tx, -S * 0.1, z), Vector3(0, -1, 0.05), S * (0.18 if k == 0 else 0.1), S * 0.035, Color(0.98, 0.96, 0.9))
			# kırmızı göz + koyu göz bebeği + çatık kaş
			var ep = Vector3(sx * S * 0.33, S * 0.28, -S * 0.62)
			hb.add("sphere", ep, Vector3(0.2, 0.12, 0.08) * S, Color(0.92, 0.9, 0.86), Vector3(0, sx * 25, -sx * 20), 8)
			hb.add("sphere", ep + Vector3(0, 0, -S * 0.04), Vector3(0.08, 0.1, 0.04) * S, Color(0.85, 0.12, 0.1), Vector3.ZERO, 8)
			Loft.tube(hb, [ep + Vector3(-sx * S * 0.12, S * 0.02, -S * 0.02), ep + Vector3(sx * S * 0.02, S * 0.13, -S * 0.01), ep + Vector3(sx * S * 0.16, S * 0.16, S * 0.02)], [S * 0.03, S * 0.04, S * 0.015], Color(0.55, 0.55, 0.6), 5, 2)
			# sivri kulak (yeleden çıkar)
			var e0 = Vector3(sx * S * 0.45, S * 0.6, S * 0.1)
			Loft.tube(hb, [e0, e0 + Vector3(sx * 0.06, 0.25, 0.05) * S, e0 + Vector3(sx * 0.1, 0.5, 0.12) * S], [Vector2(0.14, 0.06) * S, Vector2(0.09, 0.04) * S, Vector2(0.01, 0.01) * S], c, 8, 2, true, false)
			_tufts(hb, Vector3(sx * S * 0.6, -S * 0.15, -S * 0.05), Vector3(sx, -0.4, 0.3), 10, S * 0.35, S * 0.08, c, 0.5, 80 + i * 3 + int(sx))   # yanak tüyü
		_tufts(hb, Vector3(0, S * 0.75, S * 0.2), Vector3(0, 1, 0.5), 12, S * 0.4, S * 0.08, c, 0.6, 86 + i)   # tepe yelesi
		_mesh(head, hb)
		# alt çene: sonuna kadar açık, ağız içi kırmızı, alt dişler yukarı, çene altında tüy sakalı (salya sarkar)
		var jaw = _pivot(head, Vector3(0, -S * 0.15, -S * 0.25))
		jaw.rotation.x = 0.55
		var jb = MB.new()
		Loft.tube(jb, [Vector3(0, 0, 0), Vector3(0, -S * 0.04, -S * 0.3), Vector3(0, -S * 0.05, -S * 0.52)], [Vector2(0.26, 0.08) * S, Vector2(0.2, 0.07) * S, Vector2(0.13, 0.05) * S], c, 10, 3)
		jb.add("sphere", Vector3(0, S * 0.03, -S * 0.28), Vector3(0.36, 0.08, 0.5) * S, Color(0.6, 0.12, 0.16), Vector3.ZERO, 10)   # ağız içi / dil
		for sx in [-1.0, 1.0]:
			for k in 4:
				BeastRig.claw(jb, Vector3(sx * S * (0.06 + k * 0.05), S * 0.03, -S * (0.5 - k * 0.1)), Vector3(0, 1, 0), S * (0.14 if k == 0 else 0.08), S * 0.03, Color(0.98, 0.96, 0.9))
		_tufts(jb, Vector3(0, -S * 0.1, -S * 0.25), Vector3(0, -1, 0.2), 9, S * 0.35, S * 0.06, c, 0.4, 90 + i)   # çene altı sakal
		jb.add("cyl", Vector3(S * 0.05, -S * 0.35, -S * 0.42), Vector3(0.04, 0.6, 0.04) * S, Color(0.8, 0.9, 1.0), Vector3.ZERO, 6)   # salya
		_mesh(jaw, jb)
		out["heads"].append(head)
		out["jaws"].append(jaw)
	# bacaklar: uzun, ince, kırık açılı, kara pençeli; ön bacaklar yana açık (sinsi duruş)
	for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var front = q.z < 0
		var pv = _pivot(root, Vector3(q.x * h * 0.17, by - h * 0.02, q.z * L * (0.32 if front else 0.36)))
		var lb = MB.new()
		# ön bacaklar iki yana açık ve öne uzanmış (saldırı öncesi sinme), arka bacaklar kırık
		var spread = 0.32 if front else 0.12
		var knee = Vector3(q.x * h * spread * 0.6, -by * 0.35, (-h * 0.15 if front else h * 0.22))
		var ankle = Vector3(q.x * h * spread * 0.9, -by * 0.8, (-h * 0.22 if front else h * 0.05))
		var paw = Vector3(q.x * h * spread, -by + h * 0.04, (-h * 0.3 if front else -h * 0.04))
		Loft.tube(lb, [Vector3.ZERO, knee, ankle, paw], [Vector2(0.14, 0.16) * h, Vector2(0.085, 0.09) * h, Vector2(0.06, 0.06) * h, Vector2(0.065, 0.065) * h], c, 12, 3)
		lb.add("sphere", paw + Vector3(0, -h * 0.01, -h * 0.05), Vector3(0.13, 0.06, 0.15) * h, c, Vector3.ZERO, 10)
		for f in 4:
			BeastRig.claw(lb, paw + Vector3((f - 1.5) * h * 0.03, -h * 0.02, -h * 0.11), Vector3(0, -0.6, -1), h * 0.08, h * 0.014, Color(0.08, 0.07, 0.07))
		_tufts(lb, knee, Vector3(0, 0, 1 if front else -1), 5, h * 0.08, h * 0.02, c, 0.4, 100 + out["legs"].size())
		_mesh(pv, lb)
		out["legs"].append(pv)
	# kuyruk: uzun, yukarı kıvrık, gür
	var tail = _pivot(root, Vector3(0, by + h * 0.02, L * 0.5))
	var tb = MB.new()
	Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.15, h * 0.25), Vector3(0, h * 0.45, h * 0.4), Vector3(0, h * 0.72, h * 0.3), Vector3(0, h * 0.82, h * 0.1)], [h * 0.07, h * 0.1, h * 0.1, h * 0.07, h * 0.02], c, 12, 3, true, false)
	_tufts(tb, Vector3(0, h * 0.45, h * 0.4), Vector3(0, 0.3, 1), 10, h * 0.12, h * 0.03, c, 0.6, 120)
	_mesh(tail, tb)
	out["tail"] = tail
	return out
