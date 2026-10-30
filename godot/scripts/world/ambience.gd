extends Node3D
## Doğa atmosferi: ormanda süzülen yapraklar, gece ateş böcekleri, gökyüzünde kuş sürüleri, çölde kum savrulması.

var leaves: GPUParticles3D
var fall_pool: Array[GPUParticles3D] = []   # en yakın ağaçların taçlarından dökülen yapraklar (her biri bir ağaçta, ağacın kendi renginde)
var _fall_t := 0.0
var _fall_at := Vector3(1e9, 0, 0)
var fireflies: GPUParticles3D
var sand: GPUParticles3D
var birds: Array[Node3D] = []
var t := 0.0


func _ready() -> void:
	leaves = _emitter(55, 7.0, Vector3(30, 12, 30), Vector3(0.6, -1.2, 0.3), 0.4, 1.0, FX.tex_leaf, false,
		[Color(0.55, 0.75, 0.3, 0), Color(0.5, 0.72, 0.28, 1), Color(0.75, 0.6, 0.25, 1), Color(0.7, 0.55, 0.2, 0)], 0.18, true)
	fireflies = _emitter(90, 5.0, Vector3(25, 3, 25), Vector3(0, 0.15, 0), 0.3, 0.8, FX.tex_soft, true,
		[Color(0.7, 1.0, 0.4, 0), Color(0.8, 1.0, 0.45, 1), Color(0.8, 1.0, 0.45, 0)], 0.35, false)
	sand = _emitter(220, 3.0, Vector3(30, 4, 30), Vector3(8, 0.5, 2), 4.0, 8.0, FX.tex_smoke, false,
		[Color(0.9, 0.78, 0.55, 0), Color(0.88, 0.75, 0.52, 0.35), Color(0.88, 0.75, 0.52, 0)], 3.0, false)
	for i in 4:
		birds.append(_flock())
	for k in 10:
		var e = _emitter(44, 7.0, Vector3(2, 0.6, 2), Vector3(0.3, -1.0, 0.2), 0.2, 0.6, FX.tex_leaf, false,
			[Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], 0.5, true)
		var fm: ParticleProcessMaterial = e.process_material
		fm.gravity = Vector3(0, -0.8, 0)   # süzülerek ama gerçekten düşsün (havada asılı nokta gibi durmasın)
		fm.spread = 60.0
		fm.turbulence_noise_strength = 2.0
		fm.turbulence_influence_max = 0.3
		e.preprocess = 4.0   # yeni ağaca geçince yapraklar zaten havada olsun
		fall_pool.append(e)


## Oyuncunun 45 m çevresindeki yapraklı ağaçların taç noktaları -> yaprak yayıcı noktaları (renk = ağacın yaprak rengi)
func _refresh_fall(p: Vector3) -> void:
	var spots: Array = []
	for s in Builder.leaf_spots:
		var q: Vector3 = s[0]
		if absf(q.x - p.x) < 45.0 and absf(q.z - p.z) < 45.0:
			spots.append(s)
	var veg = Game.world.vegetation if Game.world else null
	if veg:
		var ck = Vector2i(floori(p.x / veg.CH), floori(p.z / veg.CH))
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var ch = veg.chunks.get(ck + Vector2i(dx, dz))
				if ch == null:
					continue
				for tr in ch["trees"]:
					if not int(tr[5]) in [0, 9] or absf(tr[0] - p.x) > 45.0 or absf(tr[2] - p.z) > 45.0:
						continue
					var top = 6.8 if int(tr[5]) == 0 else minf(15.0, 13.0 * float(tr[3]))
					spots.append([Vector3(tr[0], tr[1] + top * (float(tr[3]) if int(tr[5]) == 0 else 1.0), tr[2]), Props.VILLAGE_TREE_LEAF[0], 3.0 * float(tr[3])])
	spots.sort_custom(func(a, b): return (a[0] as Vector3).distance_squared_to(p) < (b[0] as Vector3).distance_squared_to(p))
	# en yakın ağaçlar (aynı ağaç iki kez sayılmasın); yayıcı ağaca bağlı kalır, sadece listeden çıkan ağacınki boşa çıkar
	var want := {}
	for sp in spots:
		if want.size() >= fall_pool.size():
			break
		var q: Vector3 = sp[0]
		want["%d_%d" % [roundi(q.x), roundi(q.z)]] = sp
	var free: Array = []
	for e in fall_pool:
		var k = String(e.get_meta("tree", ""))
		if k != "" and want.has(k):
			want.erase(k)   # zaten bu ağaçta dökülüyor: dokunma
		else:
			e.emitting = false
			e.set_meta("tree", "")
			free.append(e)
	for k in want:
		if free.is_empty():
			break
		var e: GPUParticles3D = free.pop_back()
		var sp = want[k]
		var r: float = sp[2]
		var fm: ParticleProcessMaterial = e.process_material
		fm.emission_box_extents = Vector3(r * 0.9, r * 0.2, r * 0.9)
		fm.color = sp[1]
		e.global_position = (sp[0] as Vector3) - Vector3(0, r * 0.75, 0)   # tacın alt kenarı: hemen görünür
		e.set_meta("tree", k)
		e.emitting = true
		e.restart()


func _emitter(n: int, life: float, box: Vector3, dir: Vector3, vmin: float, vmax: float, tex: Texture2D, add: bool, cols: Array, size: float, spin: bool) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.amount = n
	p.lifetime = life
	p.preprocess = life
	p.visibility_aabb = AABB(Vector3(-60, -30, -60), Vector3(120, 60, 120))
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = dir.normalized()
	pm.spread = 35.0
	pm.initial_velocity_min = vmin
	pm.initial_velocity_max = vmax
	pm.gravity = Vector3(0, -0.15, 0) if spin else Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.5
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.2
	if spin:
		pm.angular_velocity_min = -180
		pm.angular_velocity_max = 180
		pm.angle_max = 360
	pm.color_ramp = FX._gradient(cols)
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(size, size * (0.6 if spin else 1.0))
	q.material = FX._draw_mat(tex, add)
	p.draw_pass_1 = q
	p.emitting = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p


func _flock() -> Node3D:
	## Basit kuş sürüsü: kanat çırpan V şekilleri, oyuncunun üstünde geniş daireler çizer
	var root = Node3D.new()
	add_child(root)
	var b = MB.new()
	b.add("box", Vector3(-0.35, 0, 0), Vector3(0.7, 0.03, 0.22), Color(0.15, 0.15, 0.18), Vector3(0, 0, 15))
	b.add("box", Vector3(0.35, 0, 0), Vector3(0.7, 0.03, 0.22), Color(0.15, 0.15, 0.18), Vector3(0, 0, -15))
	b.add("box", Vector3(0, 0, 0.05), Vector3(0.12, 0.08, 0.4), Color(0.2, 0.2, 0.22))
	var mesh = b.build(Props.toon())
	for i in randi_range(5, 9):
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3(randf_range(-4, 4), randf_range(-1.5, 1.5), randf_range(-4, 4))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	root.set_meta("phase", randf() * TAU)
	root.set_meta("r", randf_range(60, 140))
	root.set_meta("h", randf_range(45, 80))
	root.set_meta("spd", randf_range(0.08, 0.14))
	return root


func _process(dt: float) -> void:
	t += dt
	var pl = Game.player
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var p = cam.global_position if pl == null else pl.global_position
	var biome = Game.biome_at(p.x, p.z)
	var tod: float = Game.world.env.time_of_day if Game.world else 0.4
	var night = tod < 0.23 or tod > 0.79
	# 2 orman, 4 yağmur, 7 çimen, 10 bataklık, 11 köy
	# süzülen yapraklar yalnızca ormanda (köyde/çayırda havada asılı nokta gibi duruyordu)
	# rüzgârla uçuşan yapraklar: yeşil her bölgede (köy dahil) genel, ormanda yoğun
	var leafy = biome in [2, 4, 6, 7, 10, 11]
	leaves.emitting = leafy and not night
	leaves.amount_ratio = 1.0 if biome == 2 else 0.4
	fireflies.emitting = night and biome in [2, 4, 6, 7, 10]
	sand.emitting = biome == 3 or biome == 13
	_fall_t -= dt
	if _fall_t <= 0.0 or p.distance_to(_fall_at) > 18.0:
		_fall_t = 2.0
		_fall_at = p
		_refresh_fall(p)
	if night:
		for e in fall_pool:
			e.emitting = false
	for e in [leaves, fireflies, sand]:
		e.global_position = p + Vector3(0, 6 if e == leaves else 1.5, 0)
	for f in birds:
		var ph: float = f.get_meta("phase") + t * float(f.get_meta("spd"))
		var r: float = f.get_meta("r")
		var center = Vector3(round(p.x / 200.0) * 200.0, 0, round(p.z / 200.0) * 200.0)
		var pos = center + Vector3(cos(ph) * r, Game.ground_height(center.x, center.z) + float(f.get_meta("h")), sin(ph) * r)
		f.look_at_from_position(pos, pos + Vector3(-sin(ph), 0, cos(ph)), Vector3.UP)
		f.visible = not night
		for i in f.get_child_count():
			var w = f.get_child(i)
			w.rotation.z = sin(t * 9.0 + i) * 0.5
