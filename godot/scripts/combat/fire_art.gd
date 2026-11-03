class_name FireArt
extends RefCounted
## Katon şekilleri (ref katon.png): cel ateş malzemesi (VFX.mat_fire "fire": uzun alev dilleri + katman konturu) ile
## - sheet: ağızdan çıkıp ileri aktıkça devasa dalgaya genişleyen kesintisiz alev kütlesi (Gōka Mekkyaku)
## - spiral: kullanıcının etrafında dönerek açılan kalın alev bandı (Bakufu Ranbu)
## Koni / kabuk yok: silüet malzemedeki gürültüyle aşınır (organik kenar).


## Alev dalgası kesiti: z = 0..reach boyunca (yerel +Z ileri), genişlik/yükseklik ağızdan uca açılır, uç yuvarlak.
## mouth_h: ağız yüksekliği (yerel y), kütle uzaklaştıkça yere iner ve devleşir.
static func sheet_mesh(reach: float, width: float, height: float, mouth_h: float, twist := 0.0) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings = 22
	var seg = 18
	var prev: Array = []
	for i in rings + 1:
		var u = float(i) / rings
		var z = u * reach
		var grow = pow(smoothstep(0.0, 1.0, u), 0.7)
		var nose = 1.0 - smoothstep(0.82, 1.0, u)   # uç yuvarlanır
		var hw = lerpf(0.35, width * 0.5, grow) * (0.25 + 0.75 * nose)
		var hh = lerpf(0.35, height * 0.5, grow) * (0.25 + 0.75 * nose)
		var cy = lerpf(mouth_h, hh * 0.92, smoothstep(0.0, 0.6, u))   # ağızdan yere doğru iner, dalga yere oturur
		var ring: Array = []
		for k in seg:
			var a = TAU * k / seg + twist * u
			var wav = 1.0 + 0.12 * sin(a * 3.0 + u * 9.0)   # kesit dalgalı (düz tüp olmasın)
			var p = Vector3(cos(a) * hw * wav, cy + sin(a) * hh * wav, z)
			p.y = maxf(p.y, -0.2)
			var n = Vector3(cos(a) / maxf(0.1, hw), sin(a) / maxf(0.1, hh), 0.0).normalized()
			ring.append([p, n])
		if not prev.is_empty():
			for k in seg:
				var k2 = (k + 1) % seg
				for q in [prev[k], ring[k2], ring[k], prev[k], prev[k2], ring[k2]]:   # dışa bakan sarım (cull_back)
					st.set_normal(q[1])
					st.add_vertex(q[0])
		prev = ring
	return st.commit()


## Spiral alev bandı: düzlem yerel XY (yerel +Z ileri bakar); turns tur, iç yarıçap r0 -> dış r1, bant kalınlığı ince-kalın-ince
static func spiral_mesh(turns: float, r0: float, r1: float, band: float, thick: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps = int(turns * 40.0)
	var seg = 10
	var prev: Array = []
	for i in steps + 1:
		var u = float(i) / steps
		var a = u * turns * TAU
		var r = lerpf(r0, r1, u)
		var c = Vector3(cos(a) * r, sin(a) * r, -u * 1.5)   # hafif ileri burgu
		var radial = Vector3(cos(a), sin(a), 0.0)
		var fz = Vector3(0, 0, 1)
		var w = band * sin(PI * clampf(u * 1.15, 0.0, 1.0)) * (0.5 + 0.5 * u) + 0.15
		var tk = thick * (0.4 + 0.6 * sin(PI * u))
		var ring: Array = []
		for k in seg:
			var b = TAU * k / seg
			var off = radial * cos(b) * w * 0.5 + fz * sin(b) * tk * 0.5
			var n = (radial * cos(b) / maxf(0.05, w) + fz * sin(b) / maxf(0.05, tk)).normalized()
			ring.append([c + off, n])
		if not prev.is_empty():
			for k in seg:
				var k2 = (k + 1) % seg
				for q in [prev[k], ring[k2], ring[k], prev[k], prev[k2], ring[k2]]:   # dışa bakan sarım (cull_back)
					st.set_normal(q[1])
					st.add_vertex(q[0])
		prev = ring
	return st.commit()
