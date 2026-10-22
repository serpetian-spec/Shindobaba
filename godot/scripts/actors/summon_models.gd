class_name SummonModels
extends RefCounted
## Çağırma hayvanlarının prosedürel modelleri. Modeller -Z'ye bakar, gerçek boyutta (metre) kurulur.
## Dönen sözlük: {"root": Node3D, "anim": tür ("hop", "slither", "crawl", "fly", "walk", "flock", "biped", "spider"),
##   "legs": [Node3D], "wings": [Node3D], "segments": [Node3D], "head": Node3D, "tail": Node3D, "mouth": Vector3 (yerel)}


static func build(model: String, h: float, length: float) -> Dictionary:
	var out = {"root": Node3D.new(), "anim": "walk", "legs": [], "wings": [], "segments": [], "head": null, "tail": null, "mouth": Vector3(0, h * 0.5, -h * 0.5)}
	match model:
		"toad_small", "toad_mid", "toad_boss":
			_toad(out, model, h)
		"snake_swarm":
			_snake_swarm(out, h)
		"snake_giant", "snake_boss":
			_snake(out, model, h, length)
		"slug_frag", "slug_acid", "slug_queen":
			_slug(out, model, h, length)
		"hawk_small", "hawk_mount", "hawk_giant":
			_hawk(out, model, h)
		"dog_small", "dog_pack", "wolf_giant":
			_dog(out, model, h)
		"monkey_small", "monkey_king":
			_monkey(out, model, h)
		"crow_flock":
			_crows(out, h)
		"salamander":
			_salamander(out, h, length)
		"turtle_small", "turtle_giant":
			_turtle(out, model, h, length)
		"weasel_trio":
			_weasel(out, h)
		"cat_small", "cat_giant":
			_cat(out, model, h, length)
		"spider":
			_spider(out, h)
		_:
			var b = MB.new()
			b.add("sphere", Vector3(0, h * 0.5, 0), Vector3.ONE * h, Color(0.6, 0.5, 0.4), Vector3.ZERO, 10)
			_mesh(out["root"], b)
	return out


static func _mesh(parent: Node3D, b: MB, at := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	mi.position = at
	parent.add_child(mi)
	return mi


static func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var n = Node3D.new()
	n.position = at
	parent.add_child(n)
	return n


# ------------------------------------------------------------------ kurbağalar
static func _toad(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "hop"
	var base = {"toad_small": Color(0.35, 0.7, 0.3), "toad_mid": Color(0.85, 0.5, 0.2), "toad_boss": Color(0.85, 0.32, 0.2)}[model]
	var spot = base.darkened(0.3)
	var belly = Color(0.97, 0.88, 0.65)
	var s = h  # gövde yüksekliği birimi
	var b = MB.new()
	b.add("sphere", Vector3(0, s * 0.42, 0.05 * s), Vector3(1.1, 0.78, 1.15) * s, base, Vector3.ZERO, 18)
	b.add("sphere", Vector3(0, s * 0.33, -0.22 * s), Vector3(0.88, 0.52, 0.66) * s, belly, Vector3.ZERO, 16)
	# ağız çizgisi + gözler (yatay kurbağa göz bebeği)
	b.add("box", Vector3(0, s * 0.43, -0.56 * s), Vector3(0.78, 0.025, 0.06) * s, Color(0.2, 0.08, 0.06), Vector3(0, 0, 0))
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(0.36 * sx, s * 0.74, -0.32 * s), Vector3(0.23, 0.23, 0.23) * s, Color(0.98, 0.85, 0.3), Vector3.ZERO, 12)
		b.add("box", Vector3(0.36 * sx, s * 0.745, -0.435 * s), Vector3(0.14, 0.04, 0.02) * s, Color(0.05, 0.03, 0.03))
		b.add("sphere", Vector3(0.36 * sx, s * 0.8, -0.28 * s), Vector3(0.26, 0.1, 0.24) * s, base.darkened(0.12), Vector3.ZERO, 10)  # göz kapağı
		# arka bacak kalçaları
		b.add("sphere", Vector3(0.5 * sx, s * 0.26, 0.28 * s), Vector3(0.42, 0.38, 0.58) * s, base.darkened(0.08), Vector3.ZERO, 12)
		b.add("sphere", Vector3(0.6 * sx, s * 0.05, 0.05 * s), Vector3(0.3, 0.08, 0.42) * s, base.darkened(0.15), Vector3.ZERO, 10)  # perdeli ayak
	# siğiller
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(model)
	for i in 18:
		var a = rng.randf() * TAU
		var y = rng.randf_range(0.35, 0.75)
		b.add("sphere", Vector3(cos(a) * 0.5 * s, y * s, sin(a) * 0.52 * s + 0.05 * s), Vector3.ONE * s * rng.randf_range(0.05, 0.09), spot, Vector3.ZERO, 6)
	match model:
		"toad_small":
			b.add("cyl", Vector3(0, s * 0.82, 0.25 * s), Vector3(0.12, 0.5, 0.12) * s, Color(0.85, 0.8, 0.65), Vector3(0, 0, 90), 8)  # sırtta parşömen
		"toad_mid":
			b.add("torus", Vector3(0, s * 0.55, -0.05 * s), Vector3(1.0, 0.5, 1.0) * s, Color(0.75, 0.15, 0.15), Vector3(10, 0, 0), 14)  # atkı
		"toad_boss":
			# yelek (kanji yaması), sırtta dev kılıç, pipo
			b.add("sphere", Vector3(0, s * 0.5, 0.12 * s), Vector3(1.16, 0.62, 1.05) * s, Color(0.2, 0.25, 0.4), Vector3.ZERO, 16)
			b.add("cyl", Vector3(0, s * 0.62, 0.62 * s), Vector3(0.2, 0.02, 0.2) * s, Color(0.95, 0.92, 0.85), Vector3(80, 0, 0), 14)
			b.add("box", Vector3(0, s * 0.62, 0.64 * s), Vector3(0.025, 0.12, 0.01) * s, Color(0.1, 0.1, 0.1))
			b.add("box", Vector3(0, s * 0.64, 0.64 * s), Vector3(0.09, 0.02, 0.01) * s, Color(0.1, 0.1, 0.1))
			b.add("box", Vector3(0.1 * s, s * 0.95, 0.45 * s), Vector3(0.06, 1.0, 0.12) * s, Color(0.75, 0.78, 0.82), Vector3(-20, 0, 25))
			b.add("cyl", Vector3(0.25 * s, s * 0.45, -0.62 * s), Vector3(0.04, 0.35, 0.04) * s, Color(0.35, 0.25, 0.15), Vector3(75, 0, 0), 8)
			for sx in [-1.0, 1.0]:  # yara izi ve kaş
				b.add("box", Vector3(0.36 * sx, s * 0.88, -0.33 * s), Vector3(0.2, 0.03, 0.05) * s, Color(0.15, 0.08, 0.06), Vector3(0, 0, -12 * sx))
	_mesh(out["root"], b)
	# ön kollar (zıplamada kıpırdar)
	for sx in [-1.0, 1.0]:
		var pv = _pivot(out["root"], Vector3(0.36 * sx, s * 0.35, -0.38 * s))
		var lb = MB.new()
		lb.add("cyl", Vector3(0.02 * sx, -0.17 * s, -0.02 * s), Vector3(0.13, 0.34, 0.13) * s, base.darkened(0.05), Vector3(-10, 0, 8 * sx), 8)
		lb.add("sphere", Vector3(0.05 * sx, -0.34 * s, -0.08 * s), Vector3(0.2, 0.06, 0.22) * s, base.darkened(0.15), Vector3.ZERO, 8)
		if model == "toad_mid":
			lb.add("box", Vector3(0.05 * sx, -0.3 * s, -0.35 * s), Vector3(0.04, 0.05, 0.5) * s, Color(0.78, 0.8, 0.84))
		if model == "toad_boss" and sx < 0:
			lb.add("cyl", Vector3(-0.04 * s, -0.3 * s, -0.12 * s), Vector3(0.05, 0.25, 0.05) * s, Color(0.2, 0.15, 0.12), Vector3(-30, 0, 0), 6)
			lb.add("box", Vector3(-0.04 * s, -0.08 * s, -0.5 * s), Vector3(0.04, 0.09, 0.85) * s, Color(0.78, 0.8, 0.84), Vector3(-30, 0, 0))
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, s * 0.43, -0.6 * s)


# ------------------------------------------------------------------ yılanlar
static func _snake(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "slither"
	var boss = model == "snake_boss"
	var c1 = Color(0.45, 0.32, 0.62) if boss else Color(0.25, 0.42, 0.3)
	var c2 = Color(0.85, 0.75, 0.45) if boss else Color(0.75, 0.78, 0.55)
	var n = 22
	var r0 = h * 0.5
	for i in n:
		var t = float(i) / (n - 1)
		var rr = r0 * (1.0 - t * 0.82) * (0.95 if i == 0 else 1.0)
		var seg = Node3D.new()
		seg.position = Vector3(0, rr, t * length)
		out["root"].add_child(seg)
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(rr * 2.0, rr * 1.8, length / n * 1.6), c1.darkened(0.15 if i % 2 else 0.0), Vector3.ZERO, 12)
		b.add("sphere", Vector3(0, -rr * 0.35, 0), Vector3(rr * 1.6, rr * 1.0, length / n * 1.5), c2, Vector3.ZERO, 10)  # karın
		if i % 3 == 0:
			for sx in [-1.0, 1.0]:
				b.add("sphere", Vector3(rr * 0.6 * sx, rr * 0.55, 0), Vector3(rr * 0.5, rr * 0.25, rr * 0.5), c1.lightened(0.2), Vector3.ZERO, 6)
		_mesh(seg, b)
		out["segments"].append(seg)
	# baş
	var head = Node3D.new()
	head.position = Vector3(0, r0 * 1.1, -r0 * 0.6)
	out["root"].add_child(head)
	var hb = MB.new()
	var hs = r0 * 1.45
	hb.add("sphere", Vector3(0, 0, -hs * 0.4), Vector3(hs * 1.7, hs * 1.1, hs * 2.2), c1, Vector3.ZERO, 14)
	hb.add("box", Vector3(0, -hs * 0.18, -hs * 1.2), Vector3(hs * 1.2, hs * 0.06, hs * 0.9), Color(0.25, 0.05, 0.08))  # ağız
	for sx in [-1.0, 1.0]:
		hb.add("sphere", Vector3(hs * 0.48 * sx, hs * 0.3, -hs * 0.9), Vector3(hs * 0.32, hs * 0.26, hs * 0.26), Color(0.98, 0.82, 0.15), Vector3.ZERO, 10)
		hb.add("box", Vector3(hs * 0.48 * sx, hs * 0.3, -hs * 1.02), Vector3(hs * 0.05, hs * 0.22, hs * 0.02), Color(0.05, 0.03, 0.03))  # dikey göz bebeği
		hb.add("cone", Vector3(hs * 0.25 * sx, -hs * 0.3, -hs * 1.45), Vector3(hs * 0.08, hs * 0.3, hs * 0.08), Color(0.97, 0.95, 0.9), Vector3(180, 0, 0), 5)  # dişler
		if boss:
			hb.add("cone", Vector3(hs * 0.45 * sx, hs * 0.75, -hs * 0.2), Vector3(hs * 0.16, hs * 0.9, hs * 0.16), Color(0.25, 0.2, 0.3), Vector3(-30, 0, -20 * sx), 6)
	hb.add("cone", Vector3(0, -hs * 0.12, -hs * 1.85), Vector3(hs * 0.06, hs * 0.7, hs * 0.02), Color(0.85, 0.15, 0.25), Vector3(-90, 0, 0), 4)  # çatal dil
	_mesh(head, hb)
	out["head"] = head
	out["mouth"] = head.position + Vector3(0, -hs * 0.1, -hs * 1.6)


static func _snake_swarm(out: Dictionary, h: float) -> void:
	out["anim"] = "flock"
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for k in 6:
		var n = Node3D.new()
		n.position = Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
		out["root"].add_child(n)
		var b = MB.new()
		var col = [Color(0.3, 0.5, 0.3), Color(0.45, 0.35, 0.6), Color(0.6, 0.55, 0.3)][k % 3]
		for i in 8:
			b.add("sphere", Vector3(sin(i * 0.9) * 0.12, h * 0.15, i * 0.16), Vector3(0.16, 0.13, 0.22) * (1.0 - i * 0.07), col, Vector3.ZERO, 6)
		b.add("sphere", Vector3(0, h * 0.18, -0.12), Vector3(0.2, 0.14, 0.24), col.darkened(0.1), Vector3.ZERO, 8)
		_mesh(n, b)
		out["segments"].append(n)


# ------------------------------------------------------------------ sümüklüböcekler
static func _slug(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "crawl"
	if model == "slug_frag":
		length = h * 2.2
	var white = Color(0.94, 0.96, 0.98)
	var stripe = {"slug_frag": Color(0.4, 0.6, 0.95), "slug_acid": Color(0.45, 0.8, 0.25), "slug_queen": Color(0.35, 0.5, 0.9)}[model]
	var body = Node3D.new()
	out["root"].add_child(body)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.45, 0), Vector3(h * 1.05, h * 0.9, length), white, Vector3.ZERO, 18)
	b.add("sphere", Vector3(0, h * 0.18, 0.05 * length), Vector3(h * 1.25, h * 0.35, length * 1.08), white.darkened(0.08), Vector3.ZERO, 14)  # taban
	b.add("sphere", Vector3(0, h * 0.5, 0), Vector3(h * 0.25, h * 0.86, length * 0.86), stripe, Vector3.ZERO, 12)  # sırt şeridi
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.33 * sx, h * 0.45, 0), Vector3(h * 0.4, h * 0.6, length * 0.8), stripe.lightened(0.25), Vector3(0, 0, 0), 12)
	b.add("sphere", Vector3(0, h * 0.45, 0), Vector3(h * 1.0, h * 0.84, length * 0.97), white, Vector3.ZERO, 18)  # şeritleri çerçeveleyen gövde
	if model == "slug_queen":
		for i in 5:  # kraliçe sırt benekleri
			b.add("sphere", Vector3(0, h * 0.88, -length * 0.3 + i * length * 0.15), Vector3(h * 0.16, h * 0.08, h * 0.2), stripe.darkened(0.2), Vector3.ZERO, 8)
	_mesh(body, b)
	out["segments"].append(body)
	# göz sapları
	var head = _pivot(out["root"], Vector3(0, h * 0.7, -length * 0.42))
	var eb = MB.new()
	for sx in [-1.0, 1.0]:
		eb.add("cyl", Vector3(h * 0.16 * sx, h * 0.25, -h * 0.05), Vector3(h * 0.07, h * 0.55, h * 0.07), white, Vector3(-20, 0, 12 * sx), 8)
		eb.add("sphere", Vector3(h * 0.22 * sx, h * 0.52, -h * 0.14), Vector3(h * 0.14, h * 0.14, h * 0.14), Color(0.1, 0.1, 0.15), Vector3.ZERO, 8)
	_mesh(head, eb)
	out["head"] = head
	out["mouth"] = Vector3(0, h * 0.4, -length * 0.5)


# ------------------------------------------------------------------ şahinler
static func _hawk(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "fly"
	var c = {"hawk_small": Color(0.55, 0.42, 0.3), "hawk_mount": Color(0.62, 0.5, 0.36), "hawk_giant": Color(0.3, 0.28, 0.32)}[model]
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.5, 0), Vector3(h * 0.6, h * 0.55, h * 1.5), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, h * 0.48, -h * 0.3), Vector3(h * 0.55, h * 0.55, h * 0.6), Color(0.92, 0.88, 0.8), Vector3.ZERO, 12)  # göğüs
	b.add("sphere", Vector3(0, h * 0.78, -h * 0.68), Vector3(h * 0.3, h * 0.3, h * 0.36), c.lightened(0.15), Vector3.ZERO, 12)
	b.add("cone", Vector3(0, h * 0.74, -h * 0.9), Vector3(h * 0.08, h * 0.18, h * 0.08), Color(0.95, 0.75, 0.2), Vector3(-110, 0, 0), 6)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.11 * sx, h * 0.83, -h * 0.8), Vector3(h * 0.06, h * 0.05, h * 0.04), Color(0.1, 0.08, 0.05), Vector3.ZERO, 6)
		b.add("box", Vector3(h * 0.11 * sx, h * 0.87, -h * 0.79), Vector3(h * 0.1, h * 0.02, h * 0.05), c.darkened(0.3), Vector3(0, 0, -15 * sx))
		b.add("cyl", Vector3(h * 0.15 * sx, h * 0.12, 0.0), Vector3(h * 0.05, h * 0.25, h * 0.05), Color(0.95, 0.75, 0.2), Vector3.ZERO, 6)
	for k in 5:  # kuyruk yelpazesi
		b.add("box", Vector3((k - 2) * h * 0.07, h * 0.45, h * 0.85), Vector3(h * 0.08, h * 0.03, h * 0.5), c.darkened(0.15), Vector3(0, (k - 2) * 12.0, 0))
	if model != "hawk_small":
		b.add("box", Vector3(0, h * 0.86, h * 0.05), Vector3(h * 0.4, h * 0.05, h * 0.45), Color(0.6, 0.15, 0.15))  # eyer
	_mesh(out["root"], b)
	for sx in [-1.0, 1.0]:
		var pv = _pivot(out["root"], Vector3(h * 0.3 * sx, h * 0.62, -h * 0.05))
		var wb = MB.new()
		for k in 6:
			wb.add("box", Vector3((0.3 + k * 0.32) * h * sx, -k * 0.02 * h, k * 0.07 * h), Vector3(h * 0.36, h * 0.04, h * (0.8 - k * 0.08)), c.darkened(0.05 * (k % 2)), Vector3(0, -8 * k * sx, 0))
			wb.add("box", Vector3((0.3 + k * 0.32) * h * sx, -k * 0.02 * h - h * 0.01, k * 0.07 * h + h * (0.4 - k * 0.04)), Vector3(h * 0.3, h * 0.03, h * 0.12), Color(0.95, 0.93, 0.88), Vector3(0, -8 * k * sx, 0))
		_mesh(pv, wb)
		out["wings"].append(pv)
	out["mouth"] = Vector3(0, h * 0.8, -h * 1.0)


# ------------------------------------------------------------------ köpekler
static func _dog(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "walk"
	var giant = model == "wolf_giant"
	var c = Color(0.62, 0.48, 0.34) if not giant else Color(0.55, 0.57, 0.62)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.55, 0), Vector3(h * 0.5, h * 0.5, h * 1.15), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, h * 0.6, -h * 0.45), Vector3(h * 0.52, h * 0.55, h * 0.55), c.lightened(0.1), Vector3.ZERO, 12)  # göğüs yelesi
	var heads = [0.0] if not giant else [-0.22, 0.22]
	for hx in heads:
		b.add("sphere", Vector3(hx * h, h * 0.85, -h * 0.68), Vector3(h * 0.36, h * 0.34, h * 0.38), c, Vector3.ZERO, 12)
		b.add("sphere", Vector3(hx * h, h * 0.78, -h * 0.9), Vector3(h * 0.2, h * 0.17, h * 0.3), c.lightened(0.2), Vector3(10, 0, 0), 10)  # burun
		b.add("sphere", Vector3(hx * h, h * 0.82, -h * 1.05), Vector3(h * 0.07, h * 0.06, h * 0.05), Color(0.08, 0.06, 0.06), Vector3.ZERO, 6)
		for sx in [-1.0, 1.0]:
			b.add("cone", Vector3((hx + 0.11 * sx) * h, h * 1.05, -h * 0.64), Vector3(h * 0.09, h * 0.2, h * 0.07), c.darkened(0.1), Vector3(0, 0, -12 * sx), 5)
			b.add("sphere", Vector3((hx + 0.09 * sx) * h, h * 0.9, -h * 0.84), Vector3(h * 0.05, h * 0.05, h * 0.03), Color(0.15, 0.1, 0.05) if not giant else Color(0.95, 0.75, 0.1), Vector3.ZERO, 6)
	if not giant:
		b.add("cyl", Vector3(0, h * 0.75, -h * 0.4), Vector3(h * 0.42, h * 0.08, h * 0.42), Color(0.2, 0.3, 0.5), Vector3(70, 0, 0), 10)  # boyun bandı
		b.add("box", Vector3(0, h * 0.68, 0.05 * h), Vector3(h * 0.46, h * 0.3, h * 0.6), Color(0.2, 0.3, 0.5))  # yelek
	_mesh(out["root"], b)
	var tail = _pivot(out["root"], Vector3(0, h * 0.65, h * 0.55))
	var tb = MB.new()
	tb.add("cone", Vector3(0, h * 0.1, h * 0.2), Vector3(h * 0.12, h * 0.45, h * 0.12), c, Vector3(60, 0, 0), 6)
	_mesh(tail, tb)
	out["tail"] = tail
	for p in [Vector3(-0.17, 0, -0.38), Vector3(0.17, 0, -0.38), Vector3(-0.17, 0, 0.38), Vector3(0.17, 0, 0.38)]:
		var pv = _pivot(out["root"], Vector3(p.x * h, h * 0.45, p.z * h))
		var lb = MB.new()
		lb.add("cyl", Vector3(0, -h * 0.22, 0), Vector3(h * 0.11, h * 0.45, h * 0.11), c.darkened(0.08), Vector3.ZERO, 6)
		lb.add("sphere", Vector3(0, -h * 0.44, -h * 0.03), Vector3(h * 0.13, h * 0.06, h * 0.16), c.darkened(0.15), Vector3.ZERO, 6)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.8, -h * 1.0)


# ------------------------------------------------------------------ maymunlar
static func _monkey(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "biped"
	var king = model == "monkey_king"
	var fur = Color(0.62, 0.45, 0.3)
	var face = Color(0.9, 0.72, 0.6)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.48, 0), Vector3(h * 0.45, h * 0.5, h * 0.38), fur, Vector3.ZERO, 12)
	b.add("sphere", Vector3(0, h * 0.82, -h * 0.02), Vector3(h * 0.3, h * 0.3, h * 0.3), fur, Vector3.ZERO, 12)
	b.add("sphere", Vector3(0, h * 0.8, -h * 0.13), Vector3(h * 0.22, h * 0.2, h * 0.1), face, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.06 * sx, h * 0.84, -h * 0.18), Vector3(h * 0.04, h * 0.04, h * 0.02), Color(0.1, 0.08, 0.05), Vector3.ZERO, 6)
		b.add("sphere", Vector3(h * 0.16 * sx, h * 0.84, 0), Vector3(h * 0.09, h * 0.1, h * 0.04), face, Vector3.ZERO, 6)
		b.add("cyl", Vector3(h * 0.12 * sx, h * 0.15, 0), Vector3(h * 0.1, h * 0.32, h * 0.1), fur, Vector3.ZERO, 6)
	if king:
		b.add("sphere", Vector3(0, h * 0.5, 0), Vector3(h * 0.52, h * 0.42, h * 0.44), Color(0.25, 0.25, 0.3), Vector3.ZERO, 12)  # zırh
		b.add("cyl", Vector3(0, h * 0.99, 0), Vector3(h * 0.22, h * 0.06, h * 0.22), Color(0.9, 0.75, 0.25), Vector3.ZERO, 10)  # taç
		b.add("sphere", Vector3(0, h * 0.68, 0), Vector3(h * 0.5, h * 0.12, h * 0.4), Color(0.95, 0.92, 0.88), Vector3.ZERO, 10)  # beyaz yele
	_mesh(out["root"], b)
	for sx in [-1.0, 1.0]:
		var pv = _pivot(out["root"], Vector3(h * 0.22 * sx, h * 0.65, 0))
		var ab = MB.new()
		ab.add("cyl", Vector3(h * 0.05 * sx, -h * 0.25, 0), Vector3(h * 0.08, h * 0.55, h * 0.08), fur, Vector3(0, 0, 8 * sx), 6)
		_mesh(pv, ab)
		out["legs"].append(pv)
	var tail = _pivot(out["root"], Vector3(0, h * 0.35, h * 0.18))
	var tb = MB.new()
	tb.add("cyl", Vector3(0, h * 0.15, h * 0.2), Vector3(h * 0.05, h * 0.55, h * 0.05), fur, Vector3(50, 0, 0), 6)
	_mesh(tail, tb)
	out["tail"] = tail


static func _crows(out: Dictionary, h: float) -> void:
	out["anim"] = "flock"
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	for k in 9:
		var n = Node3D.new()
		n.position = Vector3(rng.randf_range(-2, 2), rng.randf_range(1.0, 3.0), rng.randf_range(-2, 2))
		out["root"].add_child(n)
		var b = MB.new()
		var c = Color(0.08, 0.08, 0.1)
		b.add("sphere", Vector3.ZERO, Vector3(0.22, 0.2, 0.42), c, Vector3.ZERO, 8)
		b.add("sphere", Vector3(0, 0.08, -0.22), Vector3(0.16, 0.15, 0.17), c, Vector3.ZERO, 8)
		b.add("cone", Vector3(0, 0.07, -0.34), Vector3(0.04, 0.1, 0.04), Color(0.2, 0.2, 0.22), Vector3(-90, 0, 0), 5)
		b.add("sphere", Vector3(0.05, 0.11, -0.28), Vector3(0.035, 0.035, 0.02), Color(0.85, 0.1, 0.1), Vector3.ZERO, 5)
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(0.25 * sx, 0.02, 0.02), Vector3(0.36, 0.02, 0.18), c, Vector3(0, 0, 10 * sx))
		_mesh(n, b)
		out["segments"].append(n)


# ------------------------------------------------------------------ semender
static func _salamander(out: Dictionary, h: float, length: float) -> void:
	out["anim"] = "walk"
	var c = Color(0.22, 0.2, 0.3)
	var spots = Color(0.95, 0.78, 0.2)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.45, 0), Vector3(h * 1.4, h * 0.75, length * 0.45), c, Vector3.ZERO, 16)
	b.add("sphere", Vector3(0, h * 0.5, -length * 0.3), Vector3(h * 1.3, h * 0.6, h * 1.3), c.lightened(0.05), Vector3.ZERO, 14)  # baş
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.45 * sx, h * 0.75, -length * 0.33), Vector3(h * 0.22, h * 0.22, h * 0.18), Color(0.95, 0.85, 0.3), Vector3.ZERO, 8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 5
	for i in 22:
		b.add("sphere", Vector3(rng.randf_range(-0.55, 0.55) * h, h * 0.8, rng.randf_range(-0.2, 0.2) * length), Vector3.ONE * h * 0.12, spots, Vector3.ZERO, 6)
	b.add("cyl", Vector3(0, h * 0.85, 0), Vector3(h * 0.2, h * 0.3, h * 0.2), Color(0.5, 0.3, 0.55), Vector3.ZERO, 8)  # sis bezi
	_mesh(out["root"], b)
	var tail = _pivot(out["root"], Vector3(0, h * 0.4, length * 0.2))
	var tb = MB.new()
	tb.add("cone", Vector3(0, 0, length * 0.25), Vector3(h * 0.5, length * 0.55, h * 0.35), c, Vector3(90, 0, 0), 10)
	_mesh(tail, tb)
	out["tail"] = tail
	for p in [Vector3(-0.75, 0, -0.18), Vector3(0.75, 0, -0.18), Vector3(-0.75, 0, 0.14), Vector3(0.75, 0, 0.14)]:
		var pv = _pivot(out["root"], Vector3(p.x * h, h * 0.35, p.z * length))
		var lb = MB.new()
		lb.add("cyl", Vector3(p.x * h * 0.2, -h * 0.15, 0), Vector3(h * 0.25, h * 0.45, h * 0.25), c.darkened(0.1), Vector3(0, 0, 40 * signf(p.x)), 6)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.45, -length * 0.38)


# ------------------------------------------------------------------ kaplumbağa
static func _turtle(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "walk"
	if length <= 0.0:
		length = h * 1.6
	var shell = Color(0.3, 0.45, 0.32)
	var skin = Color(0.55, 0.62, 0.45)
	var b = MB.new()
	b.add("hemi", Vector3(0, h * 0.3, 0), Vector3(length * 0.9, h * 1.4, length), shell, Vector3.ZERO, 16)
	b.add("cyl", Vector3(0, h * 0.3, 0), Vector3(length * 0.95, h * 0.12, length * 1.05), shell.lightened(0.15), Vector3.ZERO, 16)
	for i in 7:  # altıgen plakalar
		var a = i * TAU / 6.0
		var pp = Vector3(cos(a), 0, sin(a)) * (length * 0.22 if i < 6 else 0.0)
		b.add("cyl", pp + Vector3(0, h * (0.92 if i == 6 else 0.82), 0), Vector3(length * 0.2, h * 0.08, length * 0.2), shell.darkened(0.15), Vector3.ZERO, 6)
	b.add("sphere", Vector3(0, h * 0.4, -length * 0.55), Vector3(h * 0.45, h * 0.4, h * 0.55), skin, Vector3.ZERO, 12)
	b.add("box", Vector3(0, h * 0.45, -length * 0.5), Vector3(h * 0.48, h * 0.1, h * 0.3), Color(0.65, 0.15, 0.15))  # alın bandı
	if model == "turtle_giant":
		for i in 4:  # sırtta küçük ağaçlar
			b.add("cone", Vector3((i - 1.5) * length * 0.15, h * 1.3, (i % 2 - 0.5) * length * 0.2), Vector3(length * 0.08, h * 0.35, length * 0.08), Color(0.2, 0.5, 0.25), Vector3.ZERO, 6)
	_mesh(out["root"], b)
	for p in [Vector3(-0.42, 0, -0.32), Vector3(0.42, 0, -0.32), Vector3(-0.42, 0, 0.32), Vector3(0.42, 0, 0.32)]:
		var pv = _pivot(out["root"], Vector3(p.x * length, h * 0.25, p.z * length))
		var lb = MB.new()
		lb.add("sphere", Vector3(0, -h * 0.1, 0), Vector3(h * 0.35, h * 0.35, h * 0.35), skin, Vector3.ZERO, 8)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.4, -length * 0.7)


static func _weasel(out: Dictionary, h: float) -> void:
	out["anim"] = "walk"
	var c = Color(0.9, 0.85, 0.72)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.4, 0), Vector3(h * 0.35, h * 0.35, h * 1.0), c, Vector3.ZERO, 10)
	b.add("sphere", Vector3(0, h * 0.55, -h * 0.5), Vector3(h * 0.32, h * 0.3, h * 0.36), c, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.08 * sx, h * 0.6, -h * 0.66), Vector3(h * 0.05, h * 0.05, h * 0.03), Color(0.1, 0.05, 0.05), Vector3.ZERO, 6)
		b.add("cone", Vector3(h * 0.1 * sx, h * 0.75, -h * 0.48), Vector3(h * 0.06, h * 0.12, h * 0.05), c, Vector3.ZERO, 5)
	# orak (sırtta) + kuyruk
	b.add("box", Vector3(h * 0.25, h * 0.75, h * 0.1), Vector3(h * 0.05, h * 0.5, h * 0.12), Color(0.8, 0.82, 0.86), Vector3(0, 0, -30))
	b.add("cone", Vector3(0, h * 0.45, h * 0.6), Vector3(h * 0.14, h * 0.6, h * 0.14), c, Vector3(70, 0, 0), 8)
	b.add("box", Vector3(0, h * 0.58, -h * 0.1), Vector3(h * 0.36, h * 0.08, h * 0.3), Color(0.2, 0.35, 0.6))  # bandana
	_mesh(out["root"], b)
	for p in [Vector3(-0.14, 0, -0.3), Vector3(0.14, 0, -0.3), Vector3(-0.14, 0, 0.3), Vector3(0.14, 0, 0.3)]:
		var pv = _pivot(out["root"], Vector3(p.x * h, h * 0.3, p.z * h))
		var lb = MB.new()
		lb.add("cyl", Vector3(0, -h * 0.14, 0), Vector3(h * 0.07, h * 0.28, h * 0.07), c.darkened(0.1), Vector3.ZERO, 5)
		_mesh(pv, lb)
		out["legs"].append(pv)


static func _cat(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "walk"
	var giant = model == "cat_giant"
	var c = Color(0.3, 0.35, 0.55) if giant else Color(0.85, 0.6, 0.3)
	if length <= 0.0:
		length = h * 1.6
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.55, 0), Vector3(h * 0.55, h * 0.5, length * 0.75), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, h * 0.85, -length * 0.42), Vector3(h * 0.48, h * 0.42, h * 0.42), c, Vector3.ZERO, 12)
	for sx in [-1.0, 1.0]:
		b.add("cone", Vector3(h * 0.15 * sx, h * 1.1, -length * 0.4), Vector3(h * 0.12, h * 0.2, h * 0.08), c, Vector3(0, 0, -10 * sx), 4)
		b.add("sphere", Vector3(h * 0.11 * sx, h * 0.9, -length * 0.42 - h * 0.2), Vector3(h * 0.1, h * 0.09, h * 0.04), Color(0.4, 0.9, 1.0) if giant else Color(0.9, 0.85, 0.2), Vector3.ZERO, 8)
	if not giant:
		b.add("box", Vector3(0, h * 0.62, 0), Vector3(h * 0.5, h * 0.3, length * 0.4), Color(0.25, 0.3, 0.2))  # ninja yeleği
	_mesh(out["root"], b)
	var tail = _pivot(out["root"], Vector3(0, h * 0.7, length * 0.35))
	var tb = MB.new()
	for sx in ([-1.0, 1.0] if giant else [0.0]):
		tb.add("cone", Vector3(h * 0.15 * sx, h * 0.3, h * 0.1), Vector3(h * 0.12, h * 0.9, h * 0.12), c, Vector3(25, 0, 15 * sx), 6)
		if giant:
			tb.add("sphere", Vector3(h * 0.25 * sx, h * 0.75, h * 0.25), Vector3(h * 0.25, h * 0.35, h * 0.25), Color(0.3, 0.6, 1.0), Vector3.ZERO, 8)  # mavi alev
	_mesh(tail, tb)
	out["tail"] = tail
	for p in [Vector3(-0.2, 0, -0.3), Vector3(0.2, 0, -0.3), Vector3(-0.2, 0, 0.3), Vector3(0.2, 0, 0.3)]:
		var pv = _pivot(out["root"], Vector3(p.x * h, h * 0.45, p.z * length))
		var lb = MB.new()
		lb.add("cyl", Vector3(0, -h * 0.22, 0), Vector3(h * 0.11, h * 0.45, h * 0.11), c.darkened(0.1), Vector3.ZERO, 6)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.8, -length * 0.62)


static func _spider(out: Dictionary, h: float) -> void:
	out["anim"] = "spider"
	var c = Color(0.25, 0.2, 0.18)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.5, h * 0.45), Vector3(h * 1.0, h * 0.8, h * 1.1), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, h * 0.45, -h * 0.2), Vector3(h * 0.6, h * 0.45, h * 0.6), c.lightened(0.1), Vector3.ZERO, 12)
	b.add("box", Vector3(0, h * 0.86, h * 0.45), Vector3(h * 0.12, h * 0.04, h * 0.6), Color(0.85, 0.65, 0.15))
	for i in 6:
		b.add("sphere", Vector3((i % 3 - 1) * h * 0.1, h * 0.55 + (i / 3) * h * 0.07, -h * 0.48), Vector3.ONE * h * 0.06, Color(0.85, 0.1, 0.1), Vector3.ZERO, 6)
	_mesh(out["root"], b)
	for i in 8:
		var sx = -1.0 if i < 4 else 1.0
		var k = i % 4
		var pv = _pivot(out["root"], Vector3(h * 0.25 * sx, h * 0.5, -h * 0.35 + k * h * 0.15))
		var lb = MB.new()
		lb.add("cyl", Vector3(h * 0.35 * sx, h * 0.12, 0), Vector3(h * 0.06, h * 0.75, h * 0.06), c, Vector3(0, 0, -70 * sx), 5)
		lb.add("cyl", Vector3(h * 0.72 * sx, -h * 0.22, 0), Vector3(h * 0.05, h * 0.65, h * 0.05), c, Vector3(0, 0, 25 * sx), 5)
		_mesh(pv, lb)
		out["legs"].append(pv)
