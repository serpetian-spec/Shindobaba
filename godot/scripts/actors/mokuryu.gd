class_name Mokuryu
extends RefCounted
## Mokuton: Mokuryū no Jutsu başı (kanon, Hashirama; ref _tmp/mokuryuref): Çin ejderi gibi yılansı tahta ejder — uzun burun,
## tırtıklı dişlerle dolu iri açık çene, parlayan sarı gözler, geriye dökülen kabuk dikenli yele, başın arkasında küçük pençeli
## iki ön kol; yüzey tüylü kabuk çizgili gri-zeytin tahta. Ön -Z (ağız), birim: size (baş uzunluğu ~2.2*size).

const WOOD := Color(0.5, 0.49, 0.38)
const DARK := Color(0.32, 0.31, 0.24)
const EYE := Color(1.0, 0.88, 0.3)


static func head(size: float) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	# kafatası + uzun üst çene (burun)
	Loft.blob(b, Vector3(0, 0.1, 0.35), Vector3(0, -0.05, -1), 1.2, [Vector2(0.48, 0.42), Vector2(0.62, 0.52), Vector2(0.55, 0.45), Vector2(0.4, 0.32)], WOOD, 14)
	Loft.blob(b, Vector3(0, 0.12, -0.75), Vector3(0, -0.08, -1), 1.75, [Vector2(0.36, 0.26), Vector2(0.4, 0.27), Vector2(0.34, 0.22), Vector2(0.22, 0.14)], WOOD, 12)
	# kaş çıkıntıları (gözlerin üstünde kalın kabuk)
	for s in [-1.0, 1.0]:
		Loft.tube(b, [Vector3(s * 0.15, 0.48, -0.1), Vector3(s * 0.4, 0.55, 0.15), Vector3(s * 0.48, 0.5, 0.45)], [0.08, 0.11, 0.06], DARK, 6, 3)
	# üst dişler: üst çenenin altına dizili tırtıklı sivri dişler
	for k in 9:
		var z = lerpf(-1.5, -0.05, k / 8.0)
		for s in [-1.0, 1.0]:
			b.add("cone", Vector3(s * lerpf(0.18, 0.34, k / 8.0), -0.08, z), Vector3(0.07, 0.22 + (k % 2) * 0.08, 0.07), Color(0.88, 0.85, 0.72), Vector3(180, 0, 0), 5)
	# kabuk dikenli yele: kafanın tepesinden ve yanlarından geriye dökülür
	var rng = RandomNumberGenerator.new()
	rng.seed = 6061
	for k in 40:
		var a = rng.randf_range(-1.7, 1.7)
		var base = Vector3(sin(a) * 0.5, 0.35 + cos(a) * 0.15, 0.25 + rng.randf_range(0.0, 0.5))
		var dir = Vector3(sin(a) * 0.6, rng.randf_range(0.15, 0.55), 1.0).normalized()
		var L = rng.randf_range(0.9, 2.0)
		Loft.tube(b, [base, base + dir * L * 0.5, base + dir * L + Vector3(0, -0.15, 0)], [0.13, 0.07, 0.005], DARK.lightened(rng.randf_range(0.0, 0.2)), 5, 2)
	# kabuk çizgileri (tüylü yüzey)
	for k in 16:
		var z = rng.randf_range(-1.0, 0.8)
		var x = rng.randf_range(-0.35, 0.35)
		b.add("box", Vector3(x, 0.32 + (0.35 - absf(x)) * 0.2, z), Vector3(0.03, 0.02, 0.28), DARK, Vector3(0, rng.randf_range(-20, 20), 0))
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	root.add_child(mi)
	# alt çene: ayrı düğüm (açılıp kapanır) — dişli, açık
	var jaw = Node3D.new()
	jaw.name = "jaw"
	root.add_child(jaw)
	jaw.position = Vector3(0, -0.15, 0.2)
	jaw.rotation.x = deg_to_rad(40)
	var jb = MB.new()
	Loft.blob(jb, Vector3(0, -0.1, -0.7), Vector3(0, 0, -1), 1.85, [Vector2(0.32, 0.12), Vector2(0.36, 0.14), Vector2(0.3, 0.11), Vector2(0.16, 0.06)], WOOD.darkened(0.05), 10)
	for k in 8:
		var z = lerpf(-1.6, -0.2, k / 7.0)
		for s in [-1.0, 1.0]:
			jb.add("cone", Vector3(s * lerpf(0.16, 0.28, k / 7.0), 0.02, z), Vector3(0.06, 0.2 + (k % 2) * 0.07, 0.06), Color(0.88, 0.85, 0.72), Vector3.ZERO, 5)
	jb.add("box", Vector3(0, 0.0, -0.7), Vector3(0.42, 0.02, 1.1), Color(0.18, 0.08, 0.08))   # ağız içi
	var jm = MeshInstance3D.new()
	jm.mesh = jb.build(Props.toon())
	jaw.add_child(jm)
	# parlayan sarı gözler
	var em = StandardMaterial3D.new()
	em.albedo_color = EYE
	em.emission_enabled = true
	em.emission = EYE
	em.emission_energy_multiplier = 2.2
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var eb = MB.new()
	for s in [-1.0, 1.0]:
		eb.add("sphere", Vector3(s * 0.36, 0.38, -0.12), Vector3(0.2, 0.13, 0.16), EYE, Vector3(0, s * 20, -s * 15), 10)
	var emi = MeshInstance3D.new()
	emi.mesh = eb.build(em)
	root.add_child(emi)
	# başın arkasında küçük pençeli iki ön kol (Çin ejderi)
	var ab = MB.new()
	for s in [-1.0, 1.0]:
		Loft.tube(ab, [Vector3(s * 0.45, -0.25, 1.1), Vector3(s * 0.85, -0.7, 0.9), Vector3(s * 0.8, -1.15, 0.6)], [0.16, 0.13, 0.1], WOOD, 8, 3)
		for f in 3:
			var fa = (f - 1) * 0.35
			Loft.tube(ab, [Vector3(s * 0.8, -1.15, 0.6), Vector3(s * (0.8 + sin(fa) * 0.18), -1.35, 0.45 - cos(fa) * 0.1), Vector3(s * (0.82 + sin(fa) * 0.25), -1.45, 0.3 - cos(fa) * 0.15)], [0.06, 0.045, 0.01], DARK, 5, 2)
	var am = MeshInstance3D.new()
	am.mesh = ab.build(Props.toon())
	root.add_child(am)
	root.scale = Vector3.ONE * size
	return root
