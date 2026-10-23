class_name VfxSerpent
extends Node3D
## Baş düğümünü takip eden parçalı ejderha/yılan gövdesi (Suiryūdan, Karyū, toprak ejderhası).
## Gövde parçaları başın geçmiş konumlarına dizilir; sırtta yüzgeç/diken, kıvrılarak dalgalanır.

var head: Node3D
var count = 12
var spacing = 1.1
var radius = 1.0
var mat: Material
var fin_mat: Material
var ring_mat: Material   # varsa her parçaya koyu boğum halkası (tahta/kabuk gövde)
var segs: Array[Node3D] = []
var hist: Array[Vector3] = []
var dying = false
var ep := VFX.epic   # yaratıldığı yayının destan ölçeği
var phase = randf() * TAU


func _ready() -> void:
	top_level = true
	spacing *= ep
	radius *= ep
	for i in count:
		var k = float(i) / count
		var seg = Node3D.new()
		var mi = MeshInstance3D.new()
		mi.mesh = VFX._sphere(0.5, 18, 9)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var r = radius * (1.0 - k * 0.7)
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
		tw.chain().tween_callback(queue_free)
	if hist.size() < 2:
		return
	phase += dt * 7.0
	# geçmiş boyunca mesafeye göre yerleştir
	var acc = 0.0
	var hi = 0
	for i in segs.size():
		var want = (i + 1) * spacing
		while hi < hist.size() - 1 and acc + hist[hi].distance_to(hist[hi + 1]) < want:
			acc += hist[hi].distance_to(hist[hi + 1])
			hi += 1
		if hi >= hist.size() - 1:
			segs[i].visible = false
			continue
		var a: Vector3 = hist[hi]; var b: Vector3 = hist[hi + 1]
		var seglen = maxf(0.001, a.distance_to(b))
		var pos = a.lerp(b, clampf((want - acc) / seglen, 0.0, 1.0))
		var fwd = (a - b).normalized()
		var side = fwd.cross(Vector3.UP).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		pos += side * sin(phase - i * 0.6) * radius * 0.25 + Vector3.UP * cos(phase * 0.8 - i * 0.5) * radius * 0.15
		segs[i].visible = true
		segs[i].global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP if absf(fwd.y) < 0.98 else Vector3.RIGHT), pos)


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
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	# dişler + gözler
	var tk = "dteeth_%s" % eye
	if not VFX._cache.has(tk):
		var t = MB.new()
		for k in 5:
			var x = -0.22 + k * 0.11
			t.add("cone", Vector3(x, -0.1, -1.15 + absf(x) * 0.6), Vector3(0.06, 0.18, 0.06), Color(1, 1, 1), Vector3(180, 0, 0), 4)
			t.add("cone", Vector3(x, -0.2, -1.05 + absf(x) * 0.6), Vector3(0.05, 0.14, 0.05), Color(1, 1, 1), Vector3.ZERO, 4)
		for sx in [-1.0, 1.0]:
			t.add("sphere", Vector3(0.3 * sx, 0.22, -0.45), Vector3(0.2, 0.1, 0.14), eye, Vector3(0, 0, 12 * sx), 6)
		var um = StandardMaterial3D.new()
		um.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		um.vertex_color_use_as_albedo = true
		VFX._cache[tk] = t.build(um)
	var ti = MeshInstance3D.new()
	ti.mesh = VFX._cache[tk]
	ti.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ti)
	root.scale = Vector3.ONE * size * VFX.epic
	return root
