class_name VfxSerpent
extends Node3D
## Baş düğümünü takip eden ejderha/yılan gövdesi. Gövde başın geçmiş konumlarına dizilir, kıvrılarak dalgalanır.
## style ile her ejder kendi gövdesini alır (hepsi aynı küre zinciri saçma duruyordu):
##   "water"  : ince, kesintisiz su tüpü + yol boyu serpinti/damla
##   "fire"   : ince alev tüpü + gövdeden kopan alev dilleri ve kor
##   "lightning": soluk parıltı tüpü + gövde boyunca çatırdayan şimşek arkları
##   "dark"   : kara alev tüpü + koyu duman
##   "earth"  : kaba kaya/çamur parçaları (parçalı), aradan dökülen çamur
##   "wood"   : boğumlu tahta parçalar (parçalı, kalın — animede Mokuryū kalın)
##   ""       : eski parçalı gövde (yılanlar vb.)
## seed (jutsu kimliği) ile uzunluk/kalınlık/kıvrım her jutsuda farklı.

var head: Node3D
var count = 12
var spacing = 1.1
var radius = 1.0
var mat: Material
var fin_mat: Material
var ring_mat: Material   # varsa her parçaya koyu boğum halkası (tahta/kabuk gövde)
var style := ""
var thin := -1.0          # gövde kalınlık çarpanı (-1: stile göre)
var col := Color(0.4, 0.7, 1.0)
var seed_id := ""
var segs: Array[Node3D] = []
var hist: Array[Vector3] = []
var dying = false
var ep := VFX.epic   # yaratıldığı yayının destan ölçeği
var phase = randf() * TAU
var sway := 1.0
var _tube: MeshInstance3D
var _tim := ImmediateMesh.new()
var _arcs: Array = []
var _fx_t := 0.0
var _alpha := 1.0
const THIN := 0.42
const HEAD_K := 0.65
const TUBE := ["water", "fire", "lightning", "dark", "smoke"]
const RING := 10


func _ready() -> void:
	top_level = true
	spacing *= ep
	radius *= ep
	if thin < 0.0:
		thin = {"water": 0.36, "fire": 0.34, "lightning": 0.28, "dark": 0.36, "smoke": 0.42, "earth": 0.5, "wood": 0.72}.get(style, THIN)
	# jutsuya özgü oranlar: aynı elementteki ejderler bile birbirinin kopyası olmasın
	if seed_id != "":
		var h = absi(hash(seed_id))
		thin *= 0.85 + float(h % 31) / 100.0
		sway = 0.7 + float((h / 31) % 70) / 100.0
		count = int(count * (1.25 + float((h / 2170) % 40) / 100.0))
	else:
		count = int(count * 1.4)
	radius *= thin
	spacing *= 0.85
	if style in TUBE:
		_tube = MeshInstance3D.new()
		_tube.mesh = _tim
		# tüp gövdeye boyuna (kuyruk tarafından / çıkış noktasından) bakınca kenar aşınması tüm gövdeyi siliyordu
		if mat is ShaderMaterial and mat.shader and mat.shader.resource_path.ends_with("vfx_fire.gdshader"):
			mat = mat.duplicate()
			mat.set_shader_parameter("fres_k", 0.5)
			# "alev dili" köşe kaydırması dünya yüksekliğine göre çalışır: tüp gövdeyi ezip görünmez yapıyordu (Kokuryū)
			mat.set_shader_parameter("tongue", 0.0)
			mat.set_shader_parameter("erode", minf(0.42, float(mat.get_shader_parameter("erode"))))
		_tube.material_override = mat
		_tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_tube.extra_cull_margin = 400.0
		add_child(_tube)
		if style == "lightning":
			for i in 6:
				var a = Arcs.new()
				a.color = col
				a.count = 1
				a.width = 0.09 * maxf(1.0, radius)
				a.top_level = true
				add_child(a)
				_arcs.append(a)
		return
	for i in count:
		var k = float(i) / count
		var seg = Node3D.new()
		var mi = MeshInstance3D.new()
		mi.mesh = VFX._sphere(0.5, 18, 9) if style != "earth" else VFX.asset("rock_chunk") if VFX.asset("rock_chunk") else VFX._sphere(0.5, 7, 5)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var r = radius * (1.0 - k * 0.8)
		if style == "earth":   # kaba, düzensiz kaya topakları
			mi.scale = Vector3(r * randf_range(1.8, 2.4), r * randf_range(1.5, 2.1), spacing * randf_range(1.6, 2.2))
			mi.rotation = Vector3(randf() * 0.6, randf() * TAU, randf() * 0.6)
		else:
			mi.scale = Vector3(r * 2.0, r * 1.8, spacing * 2.2)
		seg.add_child(mi)
		if ring_mat:
			var ring = MeshInstance3D.new()
			if not VFX._cache.has("seg_ring"):
				var tm = TorusMesh.new()
				tm.inner_radius = 0.42; tm.outer_radius = 0.56; tm.rings = 16; tm.ring_segments = 6
				VFX._cache["seg_ring"] = tm
			ring.mesh = VFX._cache["seg_ring"]
			ring.material_override = ring_mat
			ring.rotation_degrees = Vector3(90, 0, 0)
			ring.scale = Vector3(r * 2.05, r * 1.6, r * 1.9)
			ring.position = Vector3(0, 0, spacing * 0.5)
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			seg.add_child(ring)
		if fin_mat and i % 2 == 0 and i < count - 2:
			var fin = MeshInstance3D.new()
			if not VFX._cache.has("seg_fin"):
				var cm = CylinderMesh.new()
				cm.top_radius = 0.0; cm.bottom_radius = 0.5; cm.height = 1.0; cm.radial_segments = 4
				VFX._cache["seg_fin"] = cm
			fin.mesh = VFX._cache["seg_fin"]
			fin.material_override = fin_mat
			fin.scale = Vector3(r * 0.35, r * 1.2, r * 0.8)
			fin.position = Vector3(0, r * 0.95, 0.1)
			fin.rotation_degrees = Vector3(-35, 0, 0)
			fin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			seg.add_child(fin)
		add_child(seg)
		segs.append(seg)
		seg.visible = false


func _process(dt: float) -> void:
	if not dying and head != null and is_instance_valid(head) and head.is_inside_tree():
		var p = head.global_position
		if hist.is_empty() or hist[0].distance_to(p) > 0.12:
			hist.push_front(p)
			if hist.size() > 400:
				hist.pop_back()
	elif not dying:
		dying = true
		var tw = create_tween().set_parallel(true)
		for s in segs:
			tw.tween_property(s, "scale", Vector3.ONE * 0.02, 0.35).set_ease(Tween.EASE_IN)
		tw.tween_property(self, "_alpha", 0.0, 0.4)
		tw.chain().tween_callback(queue_free)
	if hist.size() < 2:
		return
	phase += dt * 7.0
	# geçmiş boyunca mesafeye göre yerleştir
	var pts: Array = []
	var acc = 0.0
	var hi = 0
	var amp = radius / thin * sway
	for i in count:
		var want = (i + 1) * spacing
		while hi < hist.size() - 1 and acc + hist[hi].distance_to(hist[hi + 1]) < want:
			acc += hist[hi].distance_to(hist[hi + 1])
			hi += 1
		if hi >= hist.size() - 1:
			break
		var a: Vector3 = hist[hi]; var b: Vector3 = hist[hi + 1]
		var seglen = maxf(0.001, a.distance_to(b))
		var pos = a.lerp(b, clampf((want - acc) / seglen, 0.0, 1.0))
		var fwd = (a - b).normalized()
		var side = fwd.cross(Vector3.UP).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		pos += side * sin(phase - i * 0.6) * amp * 0.25 + Vector3.UP * cos(phase * 0.8 - i * 0.5) * amp * 0.15
		pts.append([pos, fwd])
	if _tube:
		_build_tube(pts)
		_style_fx(pts, dt)
		return
	for i in segs.size():
		if i >= pts.size():
			segs[i].visible = false
			continue
		var fwd: Vector3 = pts[i][1]
		segs[i].visible = true
		segs[i].global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP if absf(fwd.y) < 0.98 else Vector3.RIGHT), pts[i][0])
	if style == "earth":
		_style_fx(pts, dt)


## Kesintisiz, kuyruğa doğru sivrilen tüp (baştan kuyruğa halka halka)
func _build_tube(pts: Array) -> void:
	_tim.clear_surfaces()
	var n = pts.size()
	if n < 2:
		return
	var rings: Array = []
	for i in n:
		var k = float(i) / maxf(1.0, count - 1)
		var r = radius * (1.0 - k * 0.72) * _alpha
		# baş tarafı boyna doğru incelir, kafaya oturur
		if i < 2:
			r *= 0.75 + i * 0.12
		# kuyruk ucu açık kalmasın (içinden öbür taraf görünüyordu): son halkalar sivri bir uca kapanır
		if i == n - 1:
			r = 0.0
		elif i == n - 2:
			r *= 0.45
		var f: Vector3 = pts[i][1]
		var s = f.cross(Vector3.UP)
		if s.length() < 0.1:
			s = f.cross(Vector3.RIGHT)
		s = s.normalized()
		var u = s.cross(f).normalized()
		var ring = []
		for j in RING + 1:
			var a = TAU * j / RING
			ring.append([pts[i][0] + (s * cos(a) + u * sin(a)) * r, (s * cos(a) + u * sin(a)), float(j) / RING])
		rings.append([ring, k])
	_tim.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n - 1:
		var r0: Array = rings[i][0]; var r1: Array = rings[i + 1][0]
		var v0 = rings[i][1]; var v1 = rings[i + 1][1]
		for j in RING:
			for q in [[r0[j], v0], [r1[j], v1], [r1[j + 1], v1], [r0[j], v0], [r1[j + 1], v1], [r0[j + 1], v0]]:
				_tim.surface_set_normal(q[0][1])
				_tim.surface_set_color(Color(1, 1, 1, _alpha))
				_tim.surface_set_uv(Vector2(q[0][2], q[1] * 4.0))
				_tim.surface_add_vertex(q[0][0])
	# baş ucu kapağı (boyun halkası açık kalmasın)
	var r0: Array = rings[0][0]
	var c0: Vector3 = pts[0][0] + pts[0][1] * radius * 0.3
	for j in RING:
		for q in [[c0, pts[0][1]], [r0[j + 1][0], r0[j + 1][1]], [r0[j][0], r0[j][1]]]:
			_tim.surface_set_normal(q[1])
			_tim.surface_set_color(Color(1, 1, 1, _alpha))
			_tim.surface_set_uv(Vector2(0.5, 0.0))
			_tim.surface_add_vertex(q[0])
	_tim.surface_end()


## Stile özgü süs: serpinti, alev dilleri, şimşek arkları, kara duman, dökülen çamur
func _style_fx(pts: Array, dt: float) -> void:
	if style == "lightning":
		for ai in _arcs.size():
			var a: Arcs = _arcs[ai]
			var i0 = int(float(ai) / _arcs.size() * (pts.size() - 1))
			var i1 = mini(pts.size() - 1, i0 + maxi(1, pts.size() / _arcs.size()))
			if i1 <= i0:
				a.visible = false
				continue
			a.visible = true
			a.global_position = pts[i0][0]
			a.to_point = pts[i1][0] - pts[i0][0] + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * radius
	_fx_t -= dt
	if _fx_t > 0.0 or pts.size() < 3 or VFX.busy():
		return
	_fx_t = 0.045 if style in ["fire", "dark", "smoke"] else 0.07
	var p: Vector3 = pts[randi_range(1, pts.size() - 1)][0]
	match style:
		"water":
			# akıntının kendi renginde damla: su mavi, kurbağa yağı amber, lav kızıl (+ kor) — lavdan/yağdan mavi su fışkırmasın
			var wc = Color(0.55, 0.8, 1.0)
			if mat is ShaderMaterial and mat.get_shader_parameter("c_mid") != null:
				wc = mat.get_shader_parameter("c_mid")
			var nonwater = wc.r > wc.b + 0.2
			FX.burst(p, {"amount": 6, "life": 0.6, "tex": FX.tex_soft, "size": 0.35 * maxf(1.0, radius), "radius": radius, "vmin": 1.5, "vmax": 4.0,
				"dir": Vector3.UP, "spread": 120.0, "gravity": Vector3(0, -9.0, 0), "add": false,
				"colors": [wc.lightened(0.35) if nonwater else Color(0.9, 0.97, 1.0, 0.9), wc if nonwater else Color(0.55, 0.8, 1.0, 0.7), Color(wc.r, wc.g, wc.b, 0.0)]})
			if nonwater and wc.g < 0.45:
				VFX.embers(p, Color(1.0, 0.5, 0.1), 3, 3.0, 0.6)
		"fire":
			FX.burst(p, {"amount": 5, "life": 0.45, "tex": FX.tex_smoke, "add": false, "cel": true, "size": 0.9 * maxf(1.0, radius), "radius": radius * 0.6,
				"vmin": 1.0, "vmax": 3.0, "dir": Vector3.UP, "spread": 60.0, "gravity": Vector3(0, 3.0, 0), "hot": 0.6, "outline": 0.03,
				"colors": [Color(1, 0.9, 0.4, 1), Color(1, 0.45, 0.05, 0.9), Color(0.5, 0.1, 0.02, 0.0)]})
			VFX.embers(p, Color(1.0, 0.6, 0.15), 4, 4.0, 0.6)
		"dark":
			# kara alev dilleri (cel, mor kenarlı) + koyu duman
			FX.burst(p, {"amount": 5, "life": 0.5, "tex": FX.tex_smoke, "add": false, "cel": true, "size": 1.0 * maxf(1.0, radius), "radius": radius * 0.6,
				"vmin": 1.0, "vmax": 3.0, "dir": Vector3.UP, "spread": 60.0, "gravity": Vector3(0, 3.0, 0), "outline": 0.035, "outline_col": Color(0.45, 0.1, 0.6),
				"colors": [Color(0.12, 0.04, 0.16, 1.0), Color(0.06, 0.02, 0.09, 0.95), Color(0.2, 0.05, 0.3, 0.0)]})
			FX.burst(p, {"amount": 3, "life": 0.8, "tex": FX.tex_smoke, "add": false, "cel": false, "size": 1.2 * maxf(1.0, radius), "radius": radius * 0.6,
				"vmin": 0.5, "vmax": 1.5, "dir": Vector3.UP, "spread": 80.0, "gravity": Vector3(0, 1.5, 0),
				"colors": [Color(0.05, 0.02, 0.08, 0.7), Color(0.15, 0.05, 0.22, 0.4), Color(0.1, 0.02, 0.15, 0.0)]})
			VFX.embers(p, Color(0.6, 0.15, 0.8), 3, 3.0, 0.6)
		"smoke":   # duman ejderi: gövdeden kabaran gri cel duman topakları + kızıl kor
			VFX.puffs(p, {"amount": 3, "life": 0.9, "size": 1.2 * maxf(1.0, radius), "radius": radius * 0.7, "vmin": 0.4, "vmax": 1.4, "dir": Vector3.UP, "spread": 70.0,
				"gravity": Vector3(0, 0.8, 0), "rough": 0.24, "outline": 0.035, "outline_col": Color(0.18, 0.17, 0.19), "shade": 0.35,
				"colors": [Color(0.55, 0.53, 0.56, 0.0), Color(0.5, 0.48, 0.51, 1), Color(0.38, 0.36, 0.39, 0.9), Color(0.3, 0.28, 0.3, 0.0)]})
			VFX.embers(p, Color(1.0, 0.4, 0.1), 3, 3.0, 0.6)
		"lightning":
			FX.burst(p, {"amount": 6, "life": 0.2, "tex": FX.tex_spark, "size": 0.8, "vmin": 4.0, "vmax": 9.0, "spread": 180.0,
				"colors": [Color(1, 1, 1, 1), col.lightened(0.4), Color(col.r, col.g, col.b, 0)]})
		"earth":
			FX.burst(p, {"amount": 4, "life": 0.8, "tex": FX.tex_soft, "size": 0.4 * maxf(1.0, radius), "radius": radius * 0.5, "vmin": 0.5, "vmax": 2.0,
				"dir": Vector3.DOWN, "spread": 40.0, "gravity": Vector3(0, -9.0, 0), "add": false,
				"colors": [Color(0.45, 0.35, 0.25, 1), Color(0.4, 0.3, 0.2, 0.9), Color(0.35, 0.28, 0.2, 0.0)]})


## Ejderha başı: açık çene, boynuzlar, parlayan gözler (ileri = -Z)
static func dragon_head(mat: Material, size: float, eye := Color(1, 1, 0.75)) -> Node3D:
	var root = Node3D.new()
	var parts = [
		["sphere", Vector3(0, 0, 0), Vector3(1.0, 0.85, 1.3), Vector3.ZERO],          # kafatası
		["box", Vector3(0, 0.05, -0.85), Vector3(0.62, 0.32, 0.9), Vector3(-6, 0, 0)],   # üst çene
		["box", Vector3(0, -0.32, -0.75), Vector3(0.55, 0.16, 0.85), Vector3(18, 0, 0)],  # alt çene (açık)
		["cone", Vector3(0.28, 0.42, 0.45), Vector3(0.14, 1.0, 0.14), Vector3(-55, 0, -18)],
		["cone", Vector3(-0.28, 0.42, 0.45), Vector3(0.14, 1.0, 0.14), Vector3(-55, 0, 18)],
		["cone", Vector3(0.45, 0.0, 0.2), Vector3(0.1, 0.6, 0.1), Vector3(-70, 0, -60)],  # yanak dikenleri
		["cone", Vector3(-0.45, 0.0, 0.2), Vector3(0.1, 0.6, 0.1), Vector3(-70, 0, 60)],
	]
	# kafa ve diş meshleri önbellekte: her yayında MB ile yeniden üretmek kare takılması yapıyordu
	var hk = "dhead"
	if not VFX._cache.has(hk):
		var b = MB.new()
		for p in parts:
			b.add(p[0], p[1], p[2], Color.WHITE, p[3], 8)
		VFX._cache[hk] = b.build(null)
	var mi = MeshInstance3D.new()
	mi.mesh = VFX._cache[hk]
	var bm = VFX.asset("dragon_head")   # Blender'da modellenmiş kafa: uzun burun, açık çene, kıvrık boynuz, yele, bıyık, dişler
	if bm:
		mi.mesh = bm
		mi.scale = Vector3.ONE * 0.85
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	# dişler + gözler
	var tk = "dteeth_%s_%s" % [eye, bm != null]
	if not VFX._cache.has(tk):
		var t = MB.new()
		for k in (0 if bm else 5):   # Blender kafasının kendi dişleri var
			var x = -0.22 + k * 0.11
			t.add("cone", Vector3(x, -0.1, -1.15 + absf(x) * 0.6), Vector3(0.06, 0.18, 0.06), Color(1, 1, 1), Vector3(180, 0, 0), 4)
			t.add("cone", Vector3(x, -0.2, -1.05 + absf(x) * 0.6), Vector3(0.05, 0.14, 0.05), Color(1, 1, 1), Vector3.ZERO, 4)
		for sx in [-1.0, 1.0]:
			if bm:
				t.add("sphere", Vector3(0.24 * sx, 0.24, -0.3), Vector3(0.16, 0.08, 0.12), eye, Vector3(0, 0, 14 * sx), 6)   # Blender kafası göz yuvası
			else:
				t.add("sphere", Vector3(0.3 * sx, 0.22, -0.45), Vector3(0.2, 0.1, 0.14), eye, Vector3(0, 0, 12 * sx), 6)
		var um = StandardMaterial3D.new()
		um.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		um.vertex_color_use_as_albedo = true
		VFX._cache[tk] = t.build(um)
	var ti = MeshInstance3D.new()
	ti.mesh = VFX._cache[tk]
	ti.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ti)
	root.scale = Vector3.ONE * size * VFX.epic * HEAD_K   # anime oranı: kafa ince gövdeye göre büyük ama dev değil
	return root
