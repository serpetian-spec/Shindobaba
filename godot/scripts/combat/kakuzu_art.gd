class_name KakuzuArt
extends RefCounted
## Kakuzu'nun maske canavarları (anime referanslı): kara iplik (jiongu) yumağından kambur, iri gövde; yere değen uzun
## iplik demeti kollar, kısa bacaklar; göğsün üstünde elemente özgü beyaz seramik maske
## (katon: kırmızı dişli ağız, fūton: boynuzlu + turuncu gaga, suiton: açık mavi gözyaşı, raiton: koyu mavi gözyaşı).
## Kök düğümün orijini MASKENİN merkezidir (mermiler maskenin ağzından çıksın); gövde aşağıda. s=1: ~3 m boy

const INK := Color(0.07, 0.065, 0.08)
const INK2 := Color(0.16, 0.15, 0.17)
const MASK := Color(0.93, 0.93, 0.95)
const DARK := Color(0.08, 0.08, 0.1)


static func _m(b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(ClayArt.mat())
	mi.material_override = ClayArt.mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


static func beast(kind: String, s := 1.0) -> Node3D:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var root = Node3D.new()
	var body = Node3D.new()
	var mask_h = 2.35 if kind != "raiton" else 1.8
	body.position = Vector3(0, -mask_h, -1.2) * s   # maske gövdenin önünde (içine gömülmesin)
	root.add_child(body)
	var b = MB.new()
	# kambur iplik yumağı gövde
	var tall = 1.0 if kind != "raiton" else 0.78
	Loft.tube(b, ClayArt._sc([Vector3(0, 0.25, 0), Vector3(0, 0.9, 0.05), Vector3(0, 1.7, 0.1), Vector3(0, 2.4 * tall, 0.15), Vector3(0, 2.9 * tall, 0.0), Vector3(0, 3.05 * tall, -0.15)], s),
		ClayArt._sc([Vector2(0.75, 0.6), Vector2(0.95, 0.75), Vector2(1.05, 0.85), Vector2(0.95, 0.8), Vector2(0.65, 0.6), Vector2(0.2, 0.2)], s), INK, 18, 3)
	# yüzeyde kıvrık iplik demetleri (kıllı, lifli doku): gövde boyunca kıvrılan ince açık-koyu teller
	for k in 70:
		var a = rng.randf() * TAU
		var y0 = rng.randf_range(0.3, 2.6) * tall
		var rr = 0.95 * sin(clampf(y0 / (3.0 * tall), 0.05, 0.95) * PI) + 0.25
		var p0 = Vector3(cos(a) * rr * 1.05, y0, sin(a) * rr * 0.85 + 0.08)
		var tw = Vector3(-sin(a), rng.randf_range(-1.2, -0.4), cos(a)) * rng.randf_range(0.25, 0.5)
		var nrm = Vector3(cos(a), 0, sin(a)) * 0.06
		Loft.tube(b, ClayArt._sc([p0 + nrm, p0 + tw * 0.5 + nrm * 1.6, p0 + tw + nrm], s), ClayArt._sc([Vector2(0.025, 0.025), Vector2(0.02, 0.02), Vector2(0.006, 0.006)], s), INK2 if k % 3 else INK, 5, 2)
	# fūton canavarı: sırtta yelpaze gibi kabaran sivri iplik tepeliği
	if kind == "futon":
		for k in 9:
			var a2 = (k - 4) * 0.28
			var r0 = Vector3(sin(a2) * 0.4, 2.7, -0.3)
			Loft.tube(b, ClayArt._sc([r0, r0 + Vector3(sin(a2) * 1.2, 0.9 + cos(a2) * 0.4, -0.6), r0 + Vector3(sin(a2) * 2.1, 1.2, -1.0)], s), ClayArt._sc([Vector2(0.14, 0.1), Vector2(0.09, 0.06), Vector2(0.01, 0.01)], s), INK, 6, 3)
	# kısa kalın bacaklar
	for sx in [-1.0, 1.0]:
		var h0 = Vector3(sx * 0.45, 0.45, 0.0)
		Loft.tube(b, ClayArt._sc([h0, h0 + Vector3(sx * 0.1, -0.3, 0.05), h0 + Vector3(sx * 0.12, -0.45, 0.18)], s), ClayArt._sc([Vector2(0.32, 0.32), Vector2(0.3, 0.3), Vector2(0.28, 0.2)], s), INK, 10, 3)
	body.add_child(_m(b))
	# yere değen uzun kollar: omuzdan iniş, ayrı düğüm (salınır); her kol beş bükülmüş iplik demeti
	for sx in [-1.0, 1.0]:
		var arm = Node3D.new()
		arm.position = Vector3(sx * 0.95, 2.2 * tall, 0.05) * s
		var ab = MB.new()
		for q in 6:
			var o = Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
			var e = Vector3(sx * 0.35, -1.2 * tall, 0.35) + o * 1.5
			var hnd = Vector3(sx * 0.45, -2.05 * tall, 0.55) + o * 2.5
			Loft.tube(ab, ClayArt._sc([o, e + o.rotated(Vector3.UP, 1.2), hnd], s), ClayArt._sc([Vector2(0.16, 0.16), Vector2(0.12, 0.12), Vector2(0.1, 0.08)], s), INK if q % 2 else INK2, 7, 3)
		# yumruk/iplik pençe ucu
		for q in 4:
			var f0 = Vector3(sx * 0.45, -2.05 * tall, 0.55)
			Loft.tube(ab, ClayArt._sc([f0, f0 + Vector3((q - 1.5) * 0.12, -0.12, 0.28)], s), ClayArt._sc([Vector2(0.07, 0.07), Vector2(0.02, 0.02)], s), INK, 5, 2)
		arm.add_child(_m(ab))
		body.add_child(arm)
		var tw = arm.create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		arm.rotation.x = -0.06
		tw.tween_property(arm, "rotation:x", 0.1, 1.1 + sx * 0.1)
		tw.tween_property(arm, "rotation:x", -0.06, 1.1 + sx * 0.1)
	# nefes alır gibi kabarıp iner
	var br = body.create_tween().set_loops()
	br.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	br.tween_property(body, "scale", Vector3(1.03, 0.98, 1.03), 0.9)
	br.tween_property(body, "scale", Vector3.ONE, 0.9)
	root.add_child(mask(kind, s * 1.35))
	return root


## Elemente özgü maske (+Z önde); orijin maskenin merkezi
static func mask(kind: String, s := 1.0) -> MeshInstance3D:
	var b = MB.new()
	var S = func(v: Vector3) -> Vector3: return v * s
	b.add("sphere", S.call(Vector3(0, 0, 0)), S.call(Vector3(0.58, 0.68, 0.22)), MASK, Vector3.ZERO, 18)
	# dikiş izleri (maske kenarı boyunca kara iplik)
	for k in 12:
		var a = k * TAU / 12.0
		b.add("box", S.call(Vector3(cos(a) * 0.29, sin(a) * 0.34, -0.02)), S.call(Vector3(0.025, 0.09, 0.03)), DARK, Vector3(0, 0, rad_to_deg(a)))
	match kind:
		"katon":
			for sx in [-1.0, 1.0]:
				b.add("sphere", S.call(Vector3(sx * 0.14, 0.15, 0.09)), S.call(Vector3(0.1, 0.1, 0.04)), DARK, Vector3.ZERO, 10)
				b.add("sphere", S.call(Vector3(sx * 0.14, 0.15, 0.1)), S.call(Vector3(0.05, 0.05, 0.03)), MASK, Vector3.ZERO, 8)
			# iri kırmızı ağız, iki sıra beyaz diş
			b.add("sphere", S.call(Vector3(0, -0.1, 0.09)), S.call(Vector3(0.36, 0.2, 0.05)), Color(0.75, 0.08, 0.15), Vector3.ZERO, 14)
			for q in 6:
				b.add("box", S.call(Vector3(-0.12 + q * 0.048, -0.06, 0.115)), S.call(Vector3(0.036, 0.05, 0.02)), MASK)
				b.add("box", S.call(Vector3(-0.12 + q * 0.048, -0.14, 0.115)), S.call(Vector3(0.036, 0.05, 0.02)), MASK)
		"futon":
			for sx in [-1.0, 1.0]:
				b.add("sphere", S.call(Vector3(sx * 0.13, 0.12, 0.09)), S.call(Vector3(0.11, 0.12, 0.04)), DARK, Vector3.ZERO, 10)
				b.add("sphere", S.call(Vector3(sx * 0.13, 0.12, 0.1)), S.call(Vector3(0.06, 0.07, 0.03)), MASK, Vector3.ZERO, 8)
				# boynuzlar + yan kanatlar
				Loft.tube(b, [S.call(Vector3(sx * 0.2, 0.25, 0.0)), S.call(Vector3(sx * 0.34, 0.42, 0.0)), S.call(Vector3(sx * 0.3, 0.6, 0.02))], [Vector2(0.06, 0.06) * s, Vector2(0.045, 0.045) * s, Vector2(0.015, 0.015) * s], MASK, 8, 3)
				b.add("sphere", S.call(Vector3(sx * 0.33, -0.05, -0.02)), S.call(Vector3(0.12, 0.42, 0.05)), MASK, Vector3(0, sx * 25.0, 0), 10)
			b.add("cone", S.call(Vector3(0, -0.02, 0.13)), S.call(Vector3(0.12, 0.14, 0.05)), Color(0.98, 0.7, 0.2), Vector3(180, 0, 0), 3)
			b.add("box", S.call(Vector3(0, -0.2, 0.1)), S.call(Vector3(0.24, 0.08, 0.03)), DARK)
			for q in 5:
				b.add("cone", S.call(Vector3(-0.09 + q * 0.045, -0.175, 0.115)), S.call(Vector3(0.03, 0.05, 0.02)), MASK, Vector3(180, 0, 0), 3)
		"suiton", "raiton":
			var tear = Color(0.55, 0.78, 0.95) if kind == "suiton" else Color(0.12, 0.25, 0.6)
			for sx in [-1.0, 1.0]:
				b.add("sphere", S.call(Vector3(sx * 0.13, 0.14, 0.09)), S.call(Vector3(0.09, 0.09, 0.04)), DARK, Vector3.ZERO, 10)
				b.add("sphere", S.call(Vector3(sx * 0.13, 0.14, 0.1)), S.call(Vector3(0.045, 0.045, 0.03)), MASK, Vector3.ZERO, 8)
			b.add("sphere", S.call(Vector3(0.17, -0.05, 0.08)), S.call(Vector3(0.08, 0.2, 0.04)), tear, Vector3(0, 0, 15), 12)
			b.add("sphere", S.call(Vector3(-0.04, 0.0, 0.11)), S.call(Vector3(0.03, 0.03, 0.02)), DARK, Vector3.ZERO, 6)
			b.add("sphere", S.call(Vector3(0.04, 0.0, 0.11)), S.call(Vector3(0.03, 0.03, 0.02)), DARK, Vector3.ZERO, 6)
			# dalgalı ağız çizgisi
			var ml = []
			var mr = []
			for q in 7:
				ml.append(S.call(Vector3(-0.16 + q * 0.05, -0.16 + sin(q * 1.1) * 0.025, 0.1)))
				mr.append(Vector2(0.012, 0.012) * s)
			Loft.tube(b, ml, mr, DARK, 5, 2)
	return _m(b)
