class_name MissionWork
extends ScenePoser
## Görev işleri: görevdeki her iş gerçek bir nesne + gerçek bir hareket + dünyada kalan bir sonuçtur.
## · Nesne: make(tür, yer, yön, sıra, etiket) — toprakta yabani ot, kesilecek şifalı ot, boyanacak çit paneli...
## · Hareket: [F] ile run(it) — oyuncu yanına yürür, işi eliyle yapar (diz çöküp söker, fırçayla boyar, kunai ile keser).
## · Sonuç: sökülen otlar yığına atılır, tahta boyanır, kesilen otun kökü yerde kalır.
## · Görev veren de çalışır: busy(npc, tür) — çapalar, süpürür; konuşunca bırakır. Teslim: give(npc, eşya) elden ele.
## Missions adımları "work" anahtarıyla bunu kullanır (collect / points).

const RM = preload("res://scripts/world/road_map.gd")

static var inst: MissionWork

var busy_run := false
var piles := {}          # anahtar -> yığın düğümü
var busy_npcs := {}      # npc -> tür
var rider: Node3D        # omuzda taşınan (yakalanan kedi)
var paint_col := Color(0.86, 0.3, 0.24)
var kid_play := {}       # bakıcılık oyunu durumu
var field_d := {}        # kurulu tarla: {"key", "root", "spots", "pile_at", "farmer_at"}
var garden_d := {}       # kurulu bahçe: {"key", "root", "panels", "npc_at", "face"}


static func I() -> MissionWork:
	if not is_instance_valid(inst):
		inst = MissionWork.new()
		inst.name = "MissionWork"
		Game.player.get_tree().current_scene.add_child(inst)
	return inst


static func active() -> bool:
	return is_instance_valid(inst) and inst.busy_run


func _process(dt: float) -> void:
	_apply_poses(dt)
	if is_instance_valid(rider) and Game.player != null:
		var pl = Game.player
		var fd = _fd(pl)
		var right = fd.cross(Vector3.UP).normalized()
		var sc: float = pl.model.age_scale
		rider.global_position = pl.global_position + Vector3.UP * (1.38 * sc + pl.model_lift) + right * 0.19 * sc - fd * 0.03
		rider.rotation.y = pl.facing + PI * 0.5
	_kid_tick(dt)


func _own(n: Node, whole_mission := false) -> void:
	(Missions.pickups if whole_mission else Missions.step_nodes).append(n)


# ====================================================================== nesneler
## İş nesnesi kurar ve [F] kaydını açar
func make(kind: String, pos: Vector3, yaw: float, idx: int, label: String, extra := {}) -> Node3D:
	pos.y = Game.ground_height(pos.x, pos.z)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = pos
	root.rotation.y = yaw
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(pos) + idx * 977
	match kind:
		"weed":
			_build_weed(root, rng)
		"herb":
			_build_herb(root, rng)
	var it = {"pos": pos + Vector3.UP * 0.2, "radius": 2.4, "kind": "quest", "label": label, "qkey": Missions._key(), "qi": idx, "work": kind, "node": root}
	it.merge(extra)
	Interact.add(it)
	root.set_meta("it", it)
	root.tree_exiting.connect(func(): Interact.items.erase(it))
	_own(root)
	return root


## Yapı için boş, düzgün alan: c çevresinde dışa doğru arar; (2·hx × 2·hz) dikdörtgenin her yanı açık zemin, yoldan uzak, eğim az
func clear_spot(c: Vector3, hx: float, hz: float, max_r := 60.0) -> Vector3:
	var space = Game.world.get_world_3d().direct_space_state if Game.world and Game.world.is_inside_tree() else null
	var r := 0.0
	while r <= max_r:
		var n = 1 if r == 0.0 else 10
		var off = randf() * TAU
		for i in n:
			var a = off + TAU * i / n
			var q = c + Vector3(cos(a) * r, 0, sin(a) * r)
			var ok = true
			var lo := 1e9
			var hi := -1e9
			for sx in [-1.0, -0.5, 0.0, 0.5, 1.0]:
				for sz in [-1.0, 0.0, 1.0]:
					var w = q + Vector3(sx * (hx + 1.2), 0, sz * (hz + 1.2))
					var g = Game.ground_height(w.x, w.z)
					lo = minf(lo, g)
					hi = maxf(hi, g)
					if not Missions._og_ok(w, space) or Game.road_dist(w.x, w.z) < 2.5 or Game.wet_at(w.x, w.z) > 0.3:
						ok = false
						break
				if not ok:
					break
			if ok and hi - lo < 1.0:
				q.y = Game.ground_height(q.x, q.z)
				return q
		r += 4.0
	return Missions.open_ground(c, 30.0)


func _part(parent: Node3D, b: MB, at := Vector3.ZERO, m: Material = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(m if m != null else mat)
	if m != null:
		mi.material_override = m
	parent.add_child(mi)
	mi.position = at
	return mi


## Yabani ot: yere yayılmış tırtıklı yapraklar + uzun sap + sarı çiçek başı; kök toprağın altında
func _build_weed(root: Node3D, rng: RandomNumberGenerator) -> void:
	var b = MB.new()
	var g1 = Color(0.36, 0.52, 0.2)
	var g2 = Color(0.48, 0.62, 0.24)
	var n = rng.randi_range(7, 9)
	for k in n:
		var a = TAU * k / n + rng.randf_range(-0.2, 0.2)
		var L = rng.randf_range(0.26, 0.4)
		var tilt = rng.randf_range(18.0, 38.0)
		var dir = Vector3(cos(a), 0, sin(a))
		# yaprak: iki parça (dip dar, uç geniş ve sarkık)
		b.add("box", dir * L * 0.28 + Vector3.UP * (0.05 + L * 0.2), Vector3(L * 0.6, 0.012, 0.07), g1.lerp(g2, rng.randf()), Vector3(0, -rad_to_deg(a), tilt))
		b.add("box", dir * L * 0.72 + Vector3.UP * (0.07 + L * 0.3), Vector3(L * 0.55, 0.012, 0.1), g1.lerp(g2, rng.randf()), Vector3(0, -rad_to_deg(a), tilt * 0.3))
	for k in rng.randi_range(1, 3):
		var off = Vector3(rng.randf_range(-0.06, 0.06), 0, rng.randf_range(-0.06, 0.06))
		var h = rng.randf_range(0.36, 0.58)
		b.add("cyl", off + Vector3.UP * h * 0.5, Vector3(0.022, h, 0.022), Color(0.42, 0.56, 0.22), Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6)), 5)
		b.add("sphere", off + Vector3.UP * (h + 0.03), Vector3(0.1, 0.07, 0.1), Color(0.96, 0.82, 0.2), Vector3.ZERO, 7)
		b.add("sphere", off + Vector3.UP * (h + 0.045), Vector3(0.05, 0.04, 0.05), Color(0.85, 0.6, 0.12), Vector3.ZERO, 6)
	var top = _part(root, b)
	top.name = "top"
	var r = MB.new()
	r.add("cone", Vector3(0, -0.12, 0), Vector3(0.07, 0.24, 0.07), Color(0.62, 0.5, 0.34), Vector3(180, 0, 0), 6)
	for k in 4:
		var a2 = TAU * k / 4.0 + 0.4
		r.add("box", Vector3(cos(a2) * 0.05, -0.1 - k * 0.025, sin(a2) * 0.05), Vector3(0.12, 0.012, 0.012), Color(0.55, 0.44, 0.3), Vector3(0, -rad_to_deg(a2), -35))
	r.add("sphere", Vector3(0, -0.03, 0), Vector3(0.13, 0.08, 0.13), Color(0.32, 0.24, 0.16), Vector3.ZERO, 6)   # köke yapışık toprak
	var rt = _part(top, r)
	rt.name = "root"
	rt.visible = false
	# toprak kabarığı (yerde kalır)
	var s = MB.new()
	s.add("sphere", Vector3(0, 0.0, 0), Vector3(0.3, 0.07, 0.3), Color(0.36, 0.28, 0.19), Vector3.ZERO, 8)
	_part(root, s).name = "soil"


## Şifalı ot: geniş yapraklı demet + mor / beyaz çiçek salkımı; kesilince kökü kalır
func _build_herb(root: Node3D, rng: RandomNumberGenerator) -> void:
	var b = MB.new()
	var lf = [Color(0.2, 0.5, 0.3), Color(0.26, 0.58, 0.34), Color(0.18, 0.44, 0.3)]
	var fl = [Color(0.7, 0.5, 0.9), Color(0.96, 0.95, 0.9), Color(0.55, 0.7, 0.95)][rng.randi() % 3]
	var stems = rng.randi_range(4, 6)
	for k in stems:
		var a = TAU * k / stems + rng.randf_range(-0.3, 0.3)
		var lean = rng.randf_range(8.0, 22.0)
		var h = rng.randf_range(0.34, 0.5)
		var dir = Vector3(cos(a), 0, sin(a))
		var tip = dir * h * sin(deg_to_rad(lean)) + Vector3.UP * (0.08 + h * cos(deg_to_rad(lean)))
		var base = dir * 0.03 + Vector3.UP * 0.08
		b.add("cyl", (base + tip) * 0.5, Vector3(0.018, h, 0.018), Color(0.3, 0.5, 0.26), Vector3(sin(a) * lean, 0, -cos(a) * lean), 5)
		for j in 3:   # karşılıklı oval yapraklar
			var p = base.lerp(tip, 0.3 + j * 0.25)
			for sd in [-1.0, 1.0]:
				var la = a + sd * 1.3
				b.add("sphere", p + Vector3(cos(la), 0.15, sin(la)) * 0.07, Vector3(0.12, 0.016, 0.065), lf[(k + j) % 3], Vector3(0, -rad_to_deg(la), 24), 6)
		for j in 4:   # çiçek salkımı
			b.add("sphere", tip + Vector3(rng.randf_range(-0.03, 0.03), 0.02 + j * 0.028, rng.randf_range(-0.03, 0.03)), Vector3.ONE * (0.06 - j * 0.008), fl, Vector3.ZERO, 6)
	var top = _part(root, b)
	top.name = "top"
	var s = MB.new()
	for k in stems:
		var a = TAU * k / stems
		s.add("cyl", Vector3(cos(a) * 0.03, 0.04, sin(a) * 0.03), Vector3(0.02, 0.08, 0.02), Color(0.3, 0.46, 0.24), Vector3.ZERO, 5)
	for k in 3:
		var a = TAU * k / 3.0 + 0.5
		s.add("sphere", Vector3(cos(a) * 0.09, 0.025, sin(a) * 0.09), Vector3(0.13, 0.014, 0.07), lf[k], Vector3(0, -rad_to_deg(a), 6), 6)
	_part(root, s).name = "stub"


## Bahçe: çitle çevrili çiçek / sebze tarhı. Çit panelleri boyanacak iş nesneleridir (her panel 3 tahta).
## Döner: panel düğümleri. Boyasız paneller gri-kahve ham tahta.
func garden(c: Vector3, n: int) -> Dictionary:
	var key = String(Missions.active().get("id", ""))
	if garden_d.get("key", "") == key and is_instance_valid(garden_d.get("root")):
		return garden_d
	c = clear_spot(c, maxi(2, n - 2) * 0.75 + 0.6, 3.2)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = c
	_own(root, true)
	var body = StaticBody3D.new()
	root.add_child(body)
	var gy = func(x: float, z: float) -> float: return Game.ground_height(c.x + x, c.z + z) - c.y
	paint_col = [Color(0.86, 0.3, 0.24), Color(0.95, 0.94, 0.88), Color(0.3, 0.5, 0.72), Color(0.4, 0.62, 0.36)].pick_random()
	var raw = Color(0.52, 0.45, 0.38)
	var W := 1.5   # panel genişliği
	# U biçimi: ön kenarda n-2 panel, iki yanda birer panel boyanacak; arka kenar ve kalan yan paneller zaten boyalı
	var front = maxi(2, n - 2)
	var half = front * W * 0.5
	var depth = 4.5
	var slots = []   # [merkez, dışa bakan yön (radyan), boyanacak mı]
	for k in front:
		slots.append([Vector3(-half + W * (k + 0.5), 0, depth * 0.5), 0.0, true])
	slots.append([Vector3(-half, 0, depth * 0.5 - W * 0.5), -PI * 0.5, true])
	slots.append([Vector3(half, 0, depth * 0.5 - W * 0.5), PI * 0.5, true])
	for k in 2:
		slots.append([Vector3(-half, 0, depth * 0.5 - W * (k + 1.5)), -PI * 0.5, false])
		slots.append([Vector3(half, 0, depth * 0.5 - W * (k + 1.5)), PI * 0.5, false])
	for k in front:
		if k != front / 2:   # arkada küçük kapı boşluğu
			slots.append([Vector3(-half + W * (k + 0.5), 0, depth * 0.5 - W * 3.0), PI, false])
	var fixed = MB.new()
	var out = []
	var idx := 0
	for sl in slots:
		var p: Vector3 = sl[0]
		var yaw: float = sl[1]
		var g: float = gy.call(p.x, p.z)
		var nrm = Vector3(sin(yaw), 0, cos(yaw))
		var tan = Vector3(cos(yaw), 0, -sin(yaw))
		# direkler + iki kuşak (boyanmaz)
		for sd in [-1.0, 1.0]:
			var q = p + tan * W * 0.5 * sd
			fixed.add("box", q + Vector3(0, g + 0.6, 0), Vector3(0.11, 1.2, 0.11), Color(0.4, 0.3, 0.2))
			fixed.add("prism", q + Vector3(0, g + 1.25, 0), Vector3(0.15, 0.1, 0.15), Color(0.36, 0.27, 0.18))
		for hh in [0.35, 0.9]:
			fixed.add("box", p - nrm * 0.045 + Vector3(0, g + hh, 0), Vector3(W, 0.07, 0.04), Color(0.42, 0.32, 0.22), Vector3(0, rad_to_deg(yaw), 0))
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = Vector3(W, 1.15, 0.12)
		cs.shape = sh
		cs.position = p + Vector3(0, g + 0.58, 0)
		cs.rotation.y = yaw
		body.add_child(cs)
		var panel = Node3D.new()
		root.add_child(panel)
		panel.position = p + Vector3(0, g, 0)
		panel.rotation.y = yaw
		var boards = []
		for j in 3:
			var bb = MB.new()
			var bw = W / 3.0 - 0.05
			var bh = 1.05 + (0.04 if j == 1 else 0.0)
			bb.add("box", Vector3(0, bh * 0.5 + 0.06, 0), Vector3(bw, bh, 0.035), Color.WHITE)
			bb.add("prism", Vector3(0, bh + 0.06 + 0.06, 0), Vector3(bw, 0.12, 0.035), Color.WHITE)
			var done: bool = not sl[2]
			var mm = Props.toon_color(paint_col.darkened(0.04 * (j % 2)) if done else raw.darkened(0.06 * j), 0.15)
			var mi = _part(panel, bb, Vector3((j - 1) * W / 3.0, 0, 0), mm)
			boards.append(mi)
		if sl[2]:
			panel.set_meta("boards", boards)
			panel.set_meta("nrm", nrm)
			out.append(panel)
			idx += 1
	# tarhlar: toprak sırtlar + lahana / çiçek sıraları
	for row in 3:
		var z = depth * 0.5 - 1.1 - row * 1.15
		fixed.add("box", Vector3(0, gy.call(0, z) + 0.07, z), Vector3(half * 2.0 - 0.9, 0.14, 0.7), Color(0.36, 0.27, 0.18))
		for k in int(half * 2.0 / 0.62) - 1:
			var x = -half + 0.75 + k * 0.62
			if row == 1:
				fixed.add("sphere", Vector3(x, gy.call(x, z) + 0.22, z), Vector3(0.36, 0.26, 0.36), Color(0.5, 0.7, 0.36), Vector3.ZERO, 7)
				fixed.add("sphere", Vector3(x, gy.call(x, z) + 0.27, z), Vector3(0.22, 0.2, 0.22), Color(0.66, 0.8, 0.46), Vector3.ZERO, 6)
			else:
				fixed.add("cyl", Vector3(x, gy.call(x, z) + 0.28, z), Vector3(0.02, 0.3, 0.02), Color(0.3, 0.5, 0.25), Vector3.ZERO, 4)
				fixed.add("sphere", Vector3(x, gy.call(x, z) + 0.45, z), Vector3(0.16, 0.12, 0.16), [Color(0.95, 0.55, 0.6), Color(0.96, 0.85, 0.3), Color(0.9, 0.9, 0.95)][(k + row) % 3], Vector3.ZERO, 6)
	_part(root, fixed)
	# boya kovası (ön tarafta, çitin dışında durur)
	var bk = _bucket()
	root.add_child(bk)
	bk.top_level = false
	bk.position = Vector3(-half - 0.5, gy.call(-half - 0.5, depth * 0.5 + 0.9), depth * 0.5 + 0.9)
	root.set_meta("bucket", bk)
	set_meta("garden", root)
	# çimen bahçenin içinden kalksın
	var lane = [Vector2(c.x - half, c.z - 0.75), Vector2(c.x + half, c.z - 0.75), depth * 0.5 + 0.4, true]
	RM.lanes.append(lane)
	RM.lanes_dirty = true
	root.tree_exiting.connect(func():
		RM.lanes.erase(lane)
		RM.lanes_dirty = true)
	garden_d = {"key": key, "root": root, "panels": out, "npc_at": c + Vector3(half + 1.4, 0, depth * 0.5 + 1.6), "face": c + Vector3(half + 3.5, 0, depth * 0.5 + 1.6)}
	return garden_d


## Boyama adımı başladı: boyanmamış paneller [F] ile işlenebilir olur
func arm_garden(label: String) -> int:
	var n := 0
	for panel in garden_d.get("panels", []):
		if not is_instance_valid(panel) or panel.has_meta("done"):
			continue
		var nrm: Vector3 = panel.get_meta("nrm")
		var it = {"pos": panel.global_position + nrm * 0.6 + Vector3.UP * 0.5, "radius": 1.6, "kind": "quest", "label": label, "qkey": Missions._key(), "qi": n, "work": "paint", "node": panel, "nrm": nrm}
		Interact.add(it)
		panel.set_meta("it", it)
		panel.tree_exiting.connect(func(): Interact.items.erase(it))
		n += 1
	return n


## Görev vereni iş yerine koyar (çiftçi karıkta, teyze bahçe kapısında)
func place_worker(npc: Node3D, at: Vector3, face: Vector3) -> void:
	at.y = Game.ground_height(at.x, at.z)
	npc.global_position = at
	npc.home = at
	npc.goal = at
	var tf = face - at
	npc.facing = atan2(-tf.x, -tf.z)
	npc.model.rotation.y = npc.facing


## Tarla: sürülmüş toprak, sırtlarda sıra sıra ekin, aralarda yabani ot yerleri; korkuluk, sepet yeri.
## Görev boyunca durur (aynı görev için bir kez kurulur). Çimen tarlanın üstünden kalkar.
func field(c: Vector3) -> Dictionary:
	var key = String(Missions.active().get("id", ""))
	if field_d.get("key", "") == key and is_instance_valid(field_d.get("root")):
		return field_d
	c = clear_spot(c, 7.2, 5.2)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = c
	_own(root, true)
	var gy = func(x: float, z: float) -> float: return Game.ground_height(c.x + x, c.z + z) - c.y
	var HX := 6.5    # yarı uzunluk (sırt boyu x ekseninde)
	var ROWS := 6
	var GAP := 1.5
	var HZ = ROWS * GAP * 0.5
	# çimen kalksın
	var lane = [Vector2(c.x - HX - 0.5, c.z), Vector2(c.x + HX + 0.5, c.z), HZ + 0.8, true]
	RM.lanes.append(lane)
	RM.lanes_dirty = true
	root.tree_exiting.connect(func():
		RM.lanes.erase(lane)
		RM.lanes_dirty = true)
	var b = MB.new()
	var soil = Color(0.37, 0.27, 0.18)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(key) + 3
	var spots = []
	for r in ROWS:
		var z = -HZ + GAP * (r + 0.5)
		# sırt: parça parça (zemine otursun)
		for k in 13:
			var x = -HX + (k + 0.5) * (HX * 2.0 / 13.0)
			var g: float = gy.call(x, z)
			b.add("sphere", Vector3(x, g + 0.03, z), Vector3(1.15, 0.36, 0.78), soil.lightened(0.05 * ((k + r) % 2)), Vector3.ZERO, 6)
			# ekin: yapraklı fide (turp / lahana fidesi)
			if (k + r) % 2 == 0 or rng.randf() < 0.6:
				var px = x + rng.randf_range(-0.12, 0.12)
				for j in 5:
					var a = TAU * j / 5.0 + rng.randf() * 0.6
					b.add("sphere", Vector3(px + cos(a) * 0.1, g + 0.3, z + sin(a) * 0.1), Vector3(0.24, 0.03, 0.11), Color(0.3, 0.6, 0.26).lerp(Color(0.44, 0.7, 0.3), rng.randf()), Vector3(0, -rad_to_deg(a), 32), 6)
				b.add("sphere", Vector3(px, g + 0.24, z), Vector3(0.1, 0.09, 0.1), Color(0.93, 0.92, 0.86), Vector3.ZERO, 6)
		# karık (sırtların arası): ot yerleri
		if r < ROWS - 1:
			for k in 3:
				spots.append(c + Vector3(rng.randf_range(-HX + 0.8, HX - 0.8), 0, z + GAP * 0.5))
	# sınır: alçak tahta kazıklar + ip
	for k in 10:
		for sd in [-1.0, 1.0]:
			var x = -HX - 0.6 + k * ((HX * 2.0 + 1.2) / 9.0)
			var z = sd * (HZ + 0.6)
			b.add("cyl", Vector3(x, gy.call(x, z) + 0.3, z), Vector3(0.07, 0.6, 0.07), Color(0.45, 0.33, 0.2), Vector3.ZERO, 5)
			if k < 9:
				b.add("box", Vector3(x + (HX * 2.0 + 1.2) / 18.0, gy.call(x, z) + 0.5, z), Vector3((HX * 2.0 + 1.2) / 9.0, 0.015, 0.015), Color(0.78, 0.7, 0.5))
	# korkuluk
	var sp = Vector3(HX - 1.5, 0, -HZ + GAP)
	var sg: float = gy.call(sp.x, sp.z)
	b.add("cyl", sp + Vector3(0, sg + 1.0, 0), Vector3(0.07, 2.0, 0.07), Color(0.45, 0.33, 0.2), Vector3.ZERO, 5)
	b.add("box", sp + Vector3(0, sg + 1.5, 0), Vector3(1.5, 0.07, 0.07), Color(0.45, 0.33, 0.2))
	b.add("box", sp + Vector3(0, sg + 1.25, 0), Vector3(0.62, 0.7, 0.2), Color(0.56, 0.3, 0.24))
	for sd in [-1.0, 1.0]:
		b.add("box", sp + Vector3(sd * 0.55, sg + 1.47, 0), Vector3(0.55, 0.2, 0.16), Color(0.56, 0.3, 0.24))
		b.add("box", sp + Vector3(sd * 0.86, sg + 1.45, 0), Vector3(0.14, 0.05, 0.3), Color(0.85, 0.74, 0.4), Vector3(0, 0, sd * 20))
	b.add("sphere", sp + Vector3(0, sg + 1.85, 0), Vector3(0.38, 0.4, 0.38), Color(0.86, 0.78, 0.6), Vector3.ZERO, 8)
	b.add("cone", sp + Vector3(0, sg + 2.1, 0), Vector3(0.85, 0.3, 0.85), Color(0.8, 0.66, 0.34), Vector3.ZERO, 9)
	_part(root, b)
	var pile_at = c + Vector3(-HX - 1.3, 0, HZ - 0.8)
	field_d = {"key": key, "root": root, "spots": spots, "pile_at": pile_at, "farmer_at": c + Vector3(-HX + 1.6, 0, -HZ + GAP * 1.0), "face": c + Vector3(HX, 0, -HZ + GAP * 1.0)}
	return field_d


func _bucket() -> MeshInstance3D:
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.14, 0), Vector3(0.3, 0.28, 0.3), Color(0.5, 0.42, 0.32), Vector3.ZERO, 10)
	b.add("cyl", Vector3(0, 0.05, 0), Vector3(0.315, 0.03, 0.315), Color(0.3, 0.3, 0.32), Vector3.ZERO, 10)
	b.add("cyl", Vector3(0, 0.24, 0), Vector3(0.315, 0.03, 0.315), Color(0.3, 0.3, 0.32), Vector3.ZERO, 10)
	b.add("cyl", Vector3(0, 0.275, 0), Vector3(0.27, 0.012, 0.27), paint_col, Vector3.ZERO, 10)
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(mat)
	return mi


## Yığın: işten çıkanların atıldığı yer (sökülen otlar)
func pile(key: String, at: Vector3) -> Node3D:
	if piles.has(key) and is_instance_valid(piles[key]):
		return piles[key]
	at.y = Game.ground_height(at.x, at.z)
	var p = Node3D.new()
	get_tree().current_scene.add_child(p)
	p.global_position = at
	# hasır sepet: otlar buna atılır
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.16, 0), Vector3(0.62, 0.32, 0.62), Color(0.72, 0.58, 0.34), Vector3.ZERO, 10)
	b.add("cyl", Vector3(0, 0.33, 0), Vector3(0.66, 0.04, 0.66), Color(0.6, 0.47, 0.27), Vector3.ZERO, 10)
	b.add("cyl", Vector3(0, 0.31, 0), Vector3(0.54, 0.03, 0.54), Color(0.3, 0.24, 0.16), Vector3.ZERO, 10)
	for k in 3:
		b.add("cyl", Vector3(0, 0.08 + k * 0.08, 0), Vector3(0.635, 0.012, 0.635), Color(0.56, 0.44, 0.25), Vector3.ZERO, 10)
	_part(p, b)
	piles[key] = p
	_own(p, true)
	return p


# ====================================================================== [F]: işi yap
func run(it: Dictionary) -> void:
	if busy_run or not is_instance_valid(it.get("node")):
		return
	busy_run = true
	Interact.items.erase(it)
	var pl = Game.player
	_lock(30.0)
	match String(it["work"]):
		"weed":
			await _act_weed(it)
		"herb":
			await _act_herb(it)
		"paint":
			await _act_paint(it)
		"ball":
			await _act_ball(it)
		"comfort":
			await _act_comfort(it)
	if is_instance_valid(pl):
		_clear_pose(pl)
		pl.model.play("idle", 0.25)
	_release_player()
	busy_run = false
	if not it.get("silent", false):
		Missions.work_done(it)


func _stand_at(node: Node3D, dist: float, dir = null) -> void:
	var pl = Game.player
	var to: Vector3 = dir if dir is Vector3 else (pl.global_position - node.global_position)
	to.y = 0
	if to.length() < 0.05:
		to = Vector3(0, 0, 1)
	var sp = node.global_position + to.normalized() * dist
	sp.y = pl.global_position.y
	if pl.global_position.distance_to(sp) > 0.25:
		await _go_w(pl, sp, 2.4, false, 0.12)
	_look_at(pl, node.global_position)


## Yabani ot: diz çök, iki elle dibinden kavra, asıl, kökünden sök (toprak saçılır), sepete at
func _act_weed(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	var top: Node3D = w.get_node("top")
	await _stand_at(w, 0.62)
	var base = w.global_position
	_pose(pl, "pull", {"sit": "seiza", "anim": "idle", "at": base, "lift": 0.0})
	await _wait(0.5)
	# asılma: ot gerilir, titrer
	var t := 0.0
	while t < 0.7:
		var dt = get_process_delta_time()
		t += dt
		top.scale = Vector3(1.0 - 0.1 * t, 1.0 + 0.28 * t + sin(t * 46.0) * 0.03, 1.0 - 0.1 * t)
		top.rotation.z = sin(t * 40.0) * 0.05
		await get_tree().process_frame
	# koptu
	top.get_node("root").visible = true
	top.scale = Vector3.ONE
	top.rotation.z = 0.0
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", base, 0.9, 0.7)
	FX.burst(base + Vector3.UP * 0.1, {"amount": 16, "life": 0.55, "size": 0.09, "vmin": 1.2, "vmax": 3.2, "spread": 70.0, "gravity": Vector3(0, -9, 0),
		"colors": [Color(0.36, 0.27, 0.18, 1), Color(0.3, 0.22, 0.15, 0)]})
	var soil: Node3D = w.get_node("soil")
	soil.scale = Vector3(1.3, 0.5, 1.3)   # çukur kenarı
	t = 0.0
	while t < 0.55:
		t += get_process_delta_time()
		top.global_position = _held(pl) + Vector3.DOWN * 0.1
		await get_tree().process_frame
	# sepete at
	var pk: Node3D = pile(String(it.get("pile", "weeds")), it.get("pile_at", base + Vector3(2, 0, 0)))
	_pose(pl, "toss", {"sit": "seiza", "anim": "idle", "to": pk.global_position, "lift": 0.0})
	await _wait(0.22)
	var from = top.global_position
	var cnt = pk.get_child_count()
	var to = pk.global_position + Vector3(randf_range(-0.14, 0.14), 0.3 + cnt * 0.035, randf_range(-0.14, 0.14))
	var keep = top.global_transform
	w.remove_child(top)
	pk.add_child(top)
	top.global_transform = keep
	t = 0.0
	var dur = clampf(from.distance_to(to) * 0.11, 0.3, 0.9)
	while t < dur:
		t += get_process_delta_time()
		var k = minf(t / dur, 1.0)
		top.global_position = from.lerp(to, k) + Vector3.UP * sin(k * PI) * (0.5 + from.distance_to(to) * 0.12)
		top.rotation.x = k * 3.0
		await get_tree().process_frame
	top.global_position = to
	top.rotation = Vector3(randf_range(1.2, 1.9), randf() * TAU, 0)
	Sfx.play("pickup", to, 0.5, 1.3)
	await _wait(0.15)


## Şifalı ot: diz çök, sol elle demeti tut, sağ eldeki kunai ile dibinden kes; demet kesene girer, kök kalır
func _act_herb(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	var top: Node3D = w.get_node("top")
	await _stand_at(w, 0.6)
	var base = w.global_position
	_pose(pl, "cut", {"sit": "seiza", "anim": "idle", "at": base, "lift": 0.0})
	await _wait(0.62)
	var t := 0.0
	while t < 0.22:   # demeti kendine eğer
		t += get_process_delta_time()
		top.rotation.x = -0.3 * minf(t / 0.22, 1.0)
		await get_tree().process_frame
	await _wait(0.16)
	Sfx.play("slash", base, 0.6, 1.5)
	FX.burst(base + Vector3.UP * 0.1, {"amount": 8, "life": 0.4, "size": 0.07, "vmin": 0.6, "vmax": 1.8, "gravity": Vector3(0, -6, 0), "colors": [Color(0.3, 0.6, 0.32, 1), Color(0.3, 0.6, 0.32, 0)]})
	st[pl]["pop"] = st[pl]["t"]
	t = 0.0
	var from = top.global_position
	while t < 0.75:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.75, t)
		var hip = pl.global_position + Vector3.UP * (0.42 + pl.model_lift * 0.0) - _fd(pl).cross(Vector3.UP).normalized() * 0.2
		top.global_position = from.lerp(hip, k) + Vector3.UP * sin(k * PI) * 0.25
		top.scale = Vector3.ONE * lerpf(1.0, 0.25, smoothstep(0.5, 1.0, k))
		top.rotation.x = lerpf(-0.3, 1.2, k)
		await get_tree().process_frame
	top.queue_free()
	Sfx.play("pickup", base, 0.6, 1.2)
	var inv: Dictionary = Game.profile["inventory"]
	inv["herb"] = int(inv.get("herb", 0)) + 1
	await _wait(0.12)


## Çit paneli: fırçayı kovaya batır, üç tahtayı tek tek yukarıdan aşağı boya (tahta boyandıkça renk değiştirir)
func _act_paint(it: Dictionary) -> void:
	var pl = Game.player
	var panel: Node3D = it["node"]
	var nrm: Vector3 = it["nrm"]
	var boards: Array = panel.get_meta("boards")
	var pp = panel.global_position
	var tan = Vector3(nrm.z, 0, -nrm.x)
	await _stand_at(panel, 0.5, nrm)
	_look_at(pl, pp)
	# kova yanına gelir (elinde taşıdı)
	var bk = _bucket()
	add_child(bk)
	bk.top_level = true
	var bpos = pp + nrm * 0.75 + tan * 0.2
	bpos.y = Game.ground_height(bpos.x, bpos.z)
	bk.global_position = bpos
	Missions.step_nodes.append(bk)
	var gd = get_meta("garden") if has_meta("garden") else null
	if gd != null and is_instance_valid(gd) and gd.has_meta("bucket") and is_instance_valid(gd.get_meta("bucket")):
		(gd.get_meta("bucket") as Node3D).visible = false
	_pose(pl, "paint", {"anim": "idle", "tip": bpos + Vector3.UP * 0.3, "nrm": nrm})
	var s: Dictionary = st[pl]
	await _wait(0.45)
	var raw_cols = []
	for b in boards:
		raw_cols.append((b.material_override as ShaderMaterial).get_shader_parameter("tint"))
	for j in boards.size():
		var bx = pp + tan * ((j - 1) * 0.5)
		# batır
		s["tip"] = bpos + Vector3.UP * 0.3
		await _wait(0.4)
		# tahtanın önüne yan adım (kol yetişsin)
		var side_p = bx + nrm * 0.5 - tan * 0.12
		side_p.y = pl.global_position.y
		s["tip"] = bx + Vector3.UP * 1.05 + nrm * 0.03
		await _go_w(pl, side_p, 1.2, true, 0.05)
		_look_at(pl, bx - tan * 0.12)
		Sfx.play("pickup", bpos, 0.35, 1.6)
		# iki fırça darbesi: yukarıdan aşağı, sonra aşağıdan yukarı
		var m: ShaderMaterial = boards[j].material_override
		var t := 0.0
		var dur := 1.35
		while t < dur:
			var dt = get_process_delta_time()
			t += dt
			var k = t / dur
			var ph = k * 2.0
			var y = lerpf(1.08, 0.4, ph) if ph < 1.0 else lerpf(0.4, 1.08, ph - 1.0)
			var sx = -0.07 if ph < 1.0 else 0.07
			s["tip"] = bx + tan * sx + Vector3.UP * y + nrm * 0.03
			m.set_shader_parameter("tint", (raw_cols[j] as Color).lerp(paint_col.darkened(0.04 * (j % 2)), smoothstep(0.1, 0.95, k)))
			await get_tree().process_frame
		panel.set_meta("done", true)
		FX.burst(bx + Vector3.UP * 0.25 + nrm * 0.05, {"amount": 5, "life": 0.5, "size": 0.05, "vmin": 0.2, "vmax": 0.9, "gravity": Vector3(0, -7, 0), "colors": [paint_col, Color(paint_col.r, paint_col.g, paint_col.b, 0)]})
	s["tip"] = bpos + Vector3.UP * 0.5
	await _wait(0.25)
	bk.queue_free()
	if gd != null and is_instance_valid(gd) and gd.has_meta("bucket") and is_instance_valid(gd.get_meta("bucket")):
		var gb: Node3D = gd.get_meta("bucket")
		gb.visible = true
		gb.global_position = bpos


## Elde tutulan şeyin yeri (poz formülünden; oyuncunun kemik okuması bir kare geriden gelir)
func _held(n: Node3D) -> Vector3:
	return st[n].get("hold", n.global_position + Vector3.UP * 0.6) if st.has(n) else n.global_position + Vector3.UP * 0.6


# ====================================================================== pozlar
func _make(n: Node3D, s: Dictionary) -> Dictionary:
	var t: float = s["t"]
	var fd = _fd(n)
	var right = fd.cross(Vector3.UP).normalized()
	var sc: float = n.model.age_scale
	match String(s["k"]):
		"pull":
			# iki el otun dibinde; kopunca gövde geriye yaylanır, eller göğüs önüne kalkar
			var at: Vector3 = s["at"]
			var k = smoothstep(0.0, 0.42, t)
			var strain = smoothstep(0.45, 1.1, t)
			var pop = smoothstep(0.0, 0.3, t - float(s["pop"])) if s.has("pop") else 0.0
			var rest = n.global_position + fd * 0.2 + Vector3.UP * 0.5 * sc
			var grab = at + Vector3.UP * (0.14 + 0.05 * strain)
			var up = n.global_position + fd * 0.34 + Vector3.UP * 0.74 * sc
			var h = rest.lerp(grab, k).lerp(up, pop)
			s["hold"] = h
			var arms = _ik(n, "Left", h - right * 0.05, 34.0 * k * (1.0 - pop))
			arms.append_array(_ik(n, "Right", h + right * 0.05, 34.0 * k * (1.0 - pop)))
			return {"arms": arms, "fL": GRIP, "fR": GRIP, "spine": 40.0 * k - 12.0 * strain * (1.0 - pop) - 46.0 * pop, "neck": 14.0 * k - 20.0 * pop}
		"toss":
			var to: Vector3 = s["to"]
			var d = (to - n.global_position)
			d.y = 0
			d = d.normalized()
			var k2 = smoothstep(0.0, 0.3, t)
			var h2 = (n.global_position + fd * 0.34 + Vector3.UP * 0.74 * sc).lerp(n.global_position + d * 0.55 + Vector3.UP * 0.95 * sc, k2)
			s["hold"] = h2
			var arms2 = _ik(n, "Right", h2)
			arms2.append(["LeftUpperArm", Vector3(0.2, -0.9, 0.3)])
			return {"arms": arms2, "fL": HALF, "fR": OPEN if k2 > 0.6 else GRIP, "spine": -6.0, "neck": 0.0, "twist": 20.0 * k2 * signf(d.dot(right))}
		"cut":
			var at2: Vector3 = s["at"]
			var k3 = smoothstep(0.0, 0.45, t)
			var cutk = smoothstep(0.0, 0.14, t - 0.95) * (1.0 - smoothstep(0.2, 0.5, t - 0.95))
			var done = smoothstep(0.0, 0.4, t - float(s["pop"])) if s.has("pop") else 0.0
			var lh = (n.global_position + fd * 0.2 + Vector3.UP * 0.5 * sc).lerp(at2 + Vector3.UP * 0.34 - fd * 0.03, k3)
			lh = lh.lerp(n.global_position - right * 0.22 + Vector3.UP * 0.45 * sc + fd * 0.1, done)
			var rh0 = at2 + right * 0.22 + Vector3.UP * 0.2 - fd * 0.1
			var rh1 = at2 - right * 0.1 + Vector3.UP * 0.07 - fd * 0.02
			var rh = (n.global_position + fd * 0.22 + right * 0.2 + Vector3.UP * 0.5 * sc).lerp(rh0.lerp(rh1, cutk), k3)
			var arms3 = _ik(n, "Left", lh, 32.0 * k3 * (1.0 - done))
			arms3.append_array(_ik(n, "Right", rh, 32.0 * k3 * (1.0 - done)))
			var kn = _wprop(s, "kunai")
			_aim(kn, rh, rh + (-right + fd * 0.25 - Vector3.UP * 0.25).normalized())
			return {"arms": arms3, "fL": GRIP, "fR": GRIP, "spine": 38.0 * k3 * (1.0 - done * 0.7), "neck": 14.0 * k3}
		"paint":
			# sağ el fırçayı tutar: uç "tip" noktasında, sap tahtadan oyuncuya doğru
			var tip: Vector3 = s["tip"]
			var cur: Vector3 = s.get("tip_s", tip)
			cur = cur.lerp(tip, minf(1.0, get_process_delta_time() * 14.0))
			s["tip_s"] = cur
			var sh = _bone(n, "RightUpperArm")
			var back = (sh - cur)
			back.y *= 0.4
			back = back.normalized()
			var hand = cur + back * 0.24 + Vector3.UP * 0.03
			var br = _wprop(s, "brush")
			# fırça kol hedefinin formülünden (oyuncunun el kemiği okuması güvenilmez); kol yetişsin diye el omuzdan en çok 0.5 m
			var reach = hand - sh
			if reach.length() > 0.5:
				hand = sh + reach.normalized() * 0.5
			_aim(br, hand, hand + (cur - hand).normalized())
			var arms4 = _ik(n, "Right", hand, 12.0 if cur.y - n.global_position.y < 0.5 else 0.0)
			arms4.append(["LeftUpperArm", Vector3(0.22, -0.92, 0.12)])
			var low = clampf((0.75 - (cur.y - n.global_position.y)) / 0.6, 0.0, 1.0)
			return {"arms": arms4, "fL": HALF, "fR": GRIP, "spine": 6.0 + 26.0 * low, "neck": 6.0 + 10.0 * low}
		"hoe":
			# çapa: iki elle kaldır, toprağa vur, çek
			var ph = fmod(t, 2.1) / 2.1
			var up2 = smoothstep(0.0, 0.42, ph) * (1.0 - smoothstep(0.5, 0.62, ph))
			var drag = smoothstep(0.62, 0.95, ph)
			var head = n.global_position + fd * (0.95 - 0.3 * drag) + Vector3.UP * (0.04 + 1.15 * up2 * sc)
			var butt = n.global_position + Vector3.UP * (0.95 * sc + 0.25 * up2) - fd * (0.15 - 0.3 * up2) + right * 0.12
			var dir = (butt - head).normalized()
			var L = head.distance_to(butt)
			var arms5 = _ik(n, "Right", head + dir * L * 0.55, 14.0 * (1.0 - up2))
			arms5.append_array(_ik(n, "Left", head + dir * L * 0.9, 14.0 * (1.0 - up2)))
			var hoe = _wprop(s, "hoe")
			_aim(hoe, head, butt)
			if ph > 0.6 and not s.get("hit", false):
				s["hit"] = true
				FX.burst(head, {"amount": 6, "life": 0.4, "size": 0.07, "vmin": 0.6, "vmax": 1.8, "gravity": Vector3(0, -8, 0), "colors": [Color(0.36, 0.27, 0.18, 1), Color(0.36, 0.27, 0.18, 0)]})
			elif ph < 0.3:
				s["hit"] = false
			return {"arms": arms5, "fL": GRIP, "fR": GRIP, "spine": 26.0 - 22.0 * up2, "neck": 10.0}
		"give", "take":
			# iki elle göğüs önünde uzatır / alır
			var k6 = smoothstep(0.0, 0.4, t)
			var mid = n.global_position + Vector3.UP * (0.95 * sc) + fd * (0.16 + 0.17 * k6)
			s["hold"] = mid + Vector3.UP * 0.04
			var w6: float = float(s.get("w", 0.16))
			var arms6 = _ik(n, "Left", mid - right * w6 - Vector3.UP * 0.03)
			arms6.append_array(_ik(n, "Right", mid + right * w6 - Vector3.UP * 0.03))
			return {"arms": arms6, "fL": HALF, "fR": HALF, "spine": 6.0 * k6, "neck": 8.0}
		"hug_small":
			# küçük bir şeyi (kedi) göğsüne bastırır
			var mid2 = n.global_position + Vector3.UP * (1.05 * sc) + fd * 0.17
			s["hold"] = mid2 + fd * 0.06
			var arms7 = _ik(n, "Left", mid2 - right * 0.1 - Vector3.UP * 0.06)
			arms7.append_array(_ik(n, "Right", mid2 + right * 0.1 + Vector3.UP * 0.02))
			return {"arms": arms7, "fL": HALF, "fR": HALF, "spine": -4.0, "neck": 16.0}
		"grab_low":
			# yerdeki bir şeye iki elle uzanır, sonra göğsüne kaldırır
			var at3: Vector3 = s["at"]
			var k8 = smoothstep(0.0, 0.35, t)
			var lift2 = smoothstep(0.0, 0.5, t - float(s["pop"])) if s.has("pop") else 0.0
			var h8 = (n.global_position + fd * 0.2 + Vector3.UP * 0.5 * sc).lerp(at3 + Vector3.UP * 0.18, k8).lerp(n.global_position + fd * 0.3 + Vector3.UP * 0.62 * sc, lift2)
			s["hold"] = h8
			var arms8 = _ik(n, "Left", h8 - right * 0.1, 30.0 * k8 * (1.0 - lift2))
			arms8.append_array(_ik(n, "Right", h8 + right * 0.1, 30.0 * k8 * (1.0 - lift2)))
			return {"arms": arms8, "fL": HALF, "fR": HALF, "spine": 34.0 * k8 * (1.0 - lift2 * 0.8), "neck": 12.0}
		"pat_kid":
			var o: Node3D = s.get("with")
			var arms11 = []
			if is_instance_valid(o):
				var k11 = smoothstep(0.0, 0.5, t)
				var top11 = _bone(o, "Head") + Vector3.UP * 0.17 * o.model.age_scale + right * sin(t * 6.0) * 0.06
				arms11 = _ik(n, "Right", (n.global_position + fd * 0.2 + Vector3.UP * 0.5 * sc).lerp(top11, k11), 10.0)
			arms11.append(["LeftUpperArm", Vector3(0.2, -0.85, 0.4)])
			arms11.append(["LeftLowerArm", Vector3(-0.1, -0.5, 0.86)])
			return {"arms": arms11, "fL": HALF, "fR": OPEN, "spine": 12.0, "neck": 14.0}
		"kick":
			var k9 = smoothstep(0.0, 0.16, t) * (1.0 - smoothstep(0.28, 0.6, t))
			var back9 = smoothstep(0.0, 0.1, t) * (1.0 - smoothstep(0.1, 0.2, t))
			var leg = Vector3(-0.05, -0.75 + 0.55 * k9, 0.2 + 0.75 * k9 - 0.5 * back9).normalized()
			return {"arms": [["RightUpperLeg", leg], ["RightLowerLeg", (leg + Vector3(0, -0.4 * (1.0 - k9), -0.5 * back9)).normalized()],
				["LeftUpperArm", Vector3(0.5, -0.5, 0.5 * k9)], ["RightUpperArm", Vector3(-0.5, -0.6, -0.4 * k9)]], "fL": HALF, "fR": HALF, "spine": -8.0 * k9, "neck": 6.0}
		"cry":
			# yere oturmuş, yumrukları gözlerinde
			var sob = sin(t * 9.0) * 0.012
			var eye = _bone(n, "Head") + fd * 0.09 * sc + Vector3.UP * (0.03 + sob)
			var arms10 = _ik(n, "Left", eye - right * 0.045 * sc)
			arms10.append_array(_ik(n, "Right", eye + right * 0.045 * sc))
			return {"arms": arms10, "fL": GRIP, "fR": GRIP, "spine": 14.0 + sin(t * 9.0) * 3.0, "neck": 18.0}
	return super._make(n, s)


## İş aletleri (uçları +z yönünde)
func _wprop(s: Dictionary, name: String) -> MeshInstance3D:
	if not s.has("props"):
		s["props"] = {}
	if s["props"].has(name) and is_instance_valid(s["props"][name]):
		return s["props"][name]
	var b = MB.new()
	match name:
		"kunai":
			b.add("cyl", Vector3(0, 0, -0.02), Vector3(0.02, 0.09, 0.02), Color(0.86, 0.84, 0.78), Vector3(90, 0, 0), 6)
			b.add("cyl", Vector3(0, 0, -0.085), Vector3(0.045, 0.012, 0.045), Color(0.25, 0.25, 0.28), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.045), Vector3(0.05, 0.012, 0.05), Color(0.25, 0.25, 0.28), Vector3(0, 45, 0))
			b.add("cone", Vector3(0, 0, 0.13), Vector3(0.05, 0.14, 0.014), Color(0.3, 0.3, 0.33), Vector3(90, 0, 0), 4)
		"brush":
			b.add("cyl", Vector3(0, 0, 0.08), Vector3(0.022, 0.2, 0.022), Color(0.62, 0.45, 0.25), Vector3(90, 0, 0), 6)
			b.add("box", Vector3(0, 0, 0.19), Vector3(0.09, 0.02, 0.04), Color(0.7, 0.7, 0.72))
			b.add("box", Vector3(0, 0, 0.235), Vector3(0.085, 0.022, 0.07), paint_col)
		"hoe":
			b.add("cyl", Vector3(0, 0, 0.7), Vector3(0.03, 1.4, 0.03), Color(0.6, 0.45, 0.27), Vector3(90, 0, 0), 6)
			b.add("box", Vector3(0, -0.1, 0.02), Vector3(0.16, 0.22, 0.02), Color(0.35, 0.35, 0.38))
			b.add("box", Vector3(0, -0.005, 0.03), Vector3(0.05, 0.05, 0.06), Color(0.3, 0.3, 0.32))
	var m = _mesh(b)
	s["props"][name] = m
	return m


# ====================================================================== görev veren çalışıyor
## NPC bir işle meşgul (konuşana kadar): "hoe" çapa, "sweep" süpürge, "fold" kollar kavuşuk bekleyiş
func busy(npc: Node3D, kind: String) -> void:
	if not is_instance_valid(npc):
		return
	busy_npcs[npc] = kind
	_pose(npc, kind, {"anim": "idle"})


func stop_busy(npc: Node3D) -> void:
	if busy_npcs.has(npc):
		busy_npcs.erase(npc)
		_clear_pose(npc)


## Elden teslim: oyuncu eşyayı iki eliyle uzatır, NPC alır, eğilerek teşekkür eder
func give(npc: Node3D, kind: String) -> void:
	var pl = Game.player
	if not is_instance_valid(npc):
		return
	busy_run = true
	_lock(20.0)
	stop_busy(npc)
	if npc is QuestNPC:
		npc.set_physics_process(false)
	var to = npc.global_position - pl.global_position
	to.y = 0
	if to.length() > 0.9 or to.length() < 0.7:
		var sp = npc.global_position - to.normalized() * 0.8
		sp.y = pl.global_position.y
		await _go_w(pl, sp, 2.2, false, 0.1)
	_look_at(pl, npc.global_position)
	_look_at(npc, pl.global_position)
	var item: Node3D
	if kind == "cat" and is_instance_valid(rider):
		item = rider
		rider = null
	else:
		item = _item(kind)
	_pose(pl, "give", {"anim": "idle", "w": 0.17})
	var t := 0.0
	while t < 0.7:
		t += get_process_delta_time()
		item.global_position = item.global_position.lerp(_held(pl) + Vector3.UP * 0.02, 0.35) if kind == "cat" else _held(pl) + Vector3.UP * 0.02
		item.rotation.y = pl.facing + (PI * 0.5 if kind == "cat" else 0.0)
		await get_tree().process_frame
	_pose(npc, "take", {"anim": "idle", "w": 0.17})
	await _wait(0.45)
	var from = item.global_position
	t = 0.0
	while t < 0.4 and is_instance_valid(npc):
		t += get_process_delta_time()
		item.global_position = from.lerp(_held(npc) + Vector3.UP * 0.02, smoothstep(0.0, 0.4, t))
		await get_tree().process_frame
	Sfx.play("pickup", item.global_position, 0.6, 1.1)
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	if kind == "cat":
		_pose(npc, "hug_small", {"anim": "idle"})
		t = 0.0
		while t < 2.2 and is_instance_valid(npc):
			t += get_process_delta_time()
			item.global_position = item.global_position.lerp(_held(npc), 0.3)
			item.rotation.y = npc.facing + PI * 0.5
			await get_tree().process_frame
	else:
		# kenara koyar, eğilir
		var dn = npc.global_position + _fd(npc).cross(Vector3.UP).normalized() * 0.55
		dn.y = Game.ground_height(dn.x, dn.z)
		from = item.global_position
		t = 0.0
		_clear_pose(npc)
		npc.model.play("pickup", 0.15, 1.0, true)
		while t < 0.6:
			t += get_process_delta_time()
			item.global_position = from.lerp(dn, smoothstep(0.0, 0.6, t))
			await get_tree().process_frame
		await _wait(0.3)
		_look_at(npc, pl.global_position)
		_pose(npc, "bow", {"anim": "idle", "len": 1.6})
		await _wait(1.6)
		_clear_pose(npc)
	_own(item, true)
	if npc is QuestNPC:
		npc.set_physics_process(true)
	_release_player()
	busy_run = false


func _item(kind: String) -> Node3D:
	var b = MB.new()
	match kind:
		"herb_basket":
			b.add("cyl", Vector3(0, 0.07, 0), Vector3(0.3, 0.14, 0.3), Color(0.72, 0.58, 0.34), Vector3.ZERO, 10)
			b.add("cyl", Vector3(0, 0.145, 0), Vector3(0.32, 0.02, 0.32), Color(0.58, 0.45, 0.26), Vector3.ZERO, 10)
			for k in 7:
				var a = TAU * k / 7.0
				b.add("sphere", Vector3(cos(a) * 0.08, 0.17 + (k % 2) * 0.02, sin(a) * 0.08), Vector3(0.13, 0.03, 0.07), [Color(0.2, 0.5, 0.3), Color(0.26, 0.58, 0.34)][k % 2], Vector3(0, -rad_to_deg(a), 14), 6)
			for k in 4:
				b.add("sphere", Vector3(cos(k * 1.7) * 0.06, 0.2, sin(k * 1.7) * 0.06), Vector3.ONE * 0.045, Color(0.7, 0.5, 0.9), Vector3.ZERO, 6)
		_:
			b.add("box", Vector3(0, 0.08, 0), Vector3(0.3, 0.16, 0.22), Color(0.6, 0.45, 0.28))
	return _mesh(b)


# ====================================================================== kedi
## Kediyi yakala: çömel, iki elle kavra, kaldır; kedi omzuna tırmanır ve sahibine kadar orada kalır
func catch_cat(cat: Node3D) -> void:
	if busy_run:
		return
	busy_run = true
	var pl = Game.player
	_lock(20.0)
	cat.set_physics_process(false)
	cat.remove_from_group("catchables")
	_look_at(pl, cat.global_position)
	var at = cat.global_position
	_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": at, "lift": 0.0})
	await _wait(0.42)
	Sfx.play("pickup", at, 0.8, 1.4)
	Combat.popup_text(at + Vector3.UP * 0.9, "Miyaaav!!", Color(1.0, 0.9, 0.6))
	st[pl]["pop"] = st[pl]["t"]
	var t := 0.0
	while t < 1.3:   # çırpınır
		t += get_process_delta_time()
		cat.global_position = cat.global_position.lerp(_held(pl) - Vector3.UP * 0.12, 0.3)
		cat.vis.rotation.y = pl.facing + PI * 0.5 + sin(t * 22.0) * 0.5 * (1.0 - t / 1.3)
		cat.vis.rotation.z = sin(t * 27.0) * 0.35 * (1.0 - t / 1.3)
		await get_tree().process_frame
	# omza
	var vis: Node3D = cat.vis
	cat.remove_child(vis)
	add_child(vis)
	vis.top_level = true
	vis.global_position = cat.global_position
	vis.rotation = Vector3.ZERO
	vis.scale = Vector3.ONE * 0.8
	cat.queue_free()
	rider = null
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	var from = vis.global_position
	t = 0.0
	while t < 0.45:
		t += get_process_delta_time()
		var fd = _fd(pl)
		var tgt = pl.global_position + Vector3.UP * 1.38 * pl.model.age_scale + fd.cross(Vector3.UP).normalized() * 0.19
		vis.global_position = from.lerp(tgt, smoothstep(0.0, 0.45, t)) + Vector3.UP * sin(t / 0.45 * PI) * 0.2
		await get_tree().process_frame
	rider = vis
	Missions.pickups.append(vis)
	Hud.msg("Mikan omzuna tırmandı. Tırnakları yeleğinde... sahibine götür.", Color(1.0, 0.9, 0.7), 5.0)
	_release_player()
	busy_run = false
	Missions.on_cat_caught()


# ====================================================================== bakıcılık: çocukla top + düşüp ağlama
## Bakıcılık adımı başlarken: çocuğun oyunu kurulur (top). Olaylar: top sana gelir ([F] geri vur), çocuk düşer ([F] teselli et)
func kid_begin(kid: Node3D) -> void:
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3.ONE * 0.34, Color(0.92, 0.3, 0.26), Vector3.ZERO, 10)
	b.add("sphere", Vector3.ZERO, Vector3(0.345, 0.1, 0.345), Color(0.96, 0.92, 0.82), Vector3.ZERO, 10)
	var ball = _mesh(b)
	ball.global_position = kid.global_position + Vector3(1.2, 0.17, 0.6)
	_own(ball)
	kid_play = {"kid": kid, "ball": ball, "vel": Vector3.ZERO, "state": "chase", "t": 0.0, "n": 0, "it": {}}


func _ball_it(label: String, kind: String, at: Vector3, node: Node3D) -> void:
	var it = {"pos": at, "radius": 2.6, "kind": "quest", "label": label, "qkey": Missions._key(), "qi": 0, "work": kind, "node": node, "silent": true}
	Interact.add(it)
	kid_play["it"] = it


func _kid_tick(dt: float) -> void:
	if kid_play.is_empty():
		return
	var kid = kid_play["kid"]
	var ball = kid_play["ball"]
	if not is_instance_valid(kid) or not is_instance_valid(ball) or Missions._cur().get("kind", "") != "babysit":
		if kid_play.get("it", {}).size() > 0:
			Interact.items.erase(kid_play["it"])
		if is_instance_valid(kid):
			_clear_pose(kid)
			kid.mode = "idle"
		kid_play = {}
		return
	var pl = Game.player
	# top fiziği: yuvarlanır, yavaşlar
	var v: Vector3 = kid_play["vel"]
	if v.length() > 0.05:
		ball.global_position += v * dt
		var g = Game.ground_height(ball.global_position.x, ball.global_position.z) + 0.17
		if ball.global_position.y <= g:
			ball.global_position.y = g
			v.y = absf(v.y) * 0.45 if absf(v.y) > 1.5 else 0.0
			v.x *= 1.0 - 1.4 * dt
			v.z *= 1.0 - 1.4 * dt
		else:
			v.y -= 14.0 * dt
		ball.rotate(Vector3(v.z, 0, -v.x).normalized() if Vector2(v.x, v.z).length() > 0.1 else Vector3.RIGHT, Vector2(v.x, v.z).length() * dt / 0.17)
		kid_play["vel"] = v
		if kid_play.get("it", {}).size() > 0 and String(kid_play["it"].get("work", "")) == "ball":
			kid_play["it"]["pos"] = ball.global_position
	kid_play["t"] = float(kid_play["t"]) + dt
	match String(kid_play["state"]):
		"chase":   # çocuk topa koşar
			kid.mode = "scripted"
			var to = ball.global_position - kid.global_position
			to.y = 0
			if to.length() > 0.7:
				_turn(kid, atan2(-to.x, -to.z), dt * 10.0)
				kid.global_position += to.normalized() * minf(5.0 * dt, to.length())
				kid.global_position.y = Game.ground_height(kid.global_position.x, kid.global_position.z)
				kid.model.play("run", 0.2, 0.9)
			elif v.length() < 0.6:
				# vuruş: üçüncü vuruşta ayağı takılır, düşer
				if int(kid_play["n"]) >= 2 + int(kid_play.get("falls", 0)) * 3:   # ilk düşüş 3. vuruşta, sonrakiler seyrekleşir
					kid_play["falls"] = int(kid_play.get("falls", 0)) + 1
					kid_play["state"] = "fall"
					kid_play["t"] = 0.0
					kid.model.anim.play(CharacterModel.ANIM["getup"], 0.0, -2.2, true)   # yere kapaklanır
					kid.model.overlay.foot_ik = false
					Sfx.play("punch", kid.global_position, 0.4, 1.4)
					_say(kid, "Ayy!", 1.2)
				else:
					var tp = pl.global_position - kid.global_position
					tp.y = 0
					_look_at(kid, pl.global_position)
					_pose(kid, "kick", {"anim": "idle"})
					kid_play["vel"] = tp.normalized() * clampf(tp.length() * 1.15, 4.0, 11.0) + Vector3.UP * 2.6
					Sfx.play("punch", ball.global_position, 0.5, 1.5)
					_say(kid, ["Tut bakalım!", "Sana geliyor!", "Vur vur vur!"].pick_random(), 2.0)
					kid_play["state"] = "wait"
					kid_play["t"] = 0.0
					_ball_it("[F] Topa vur", "ball", ball.global_position, ball)
		"wait":   # top oyuncuda: çocuk zıplayarak bekler
			if float(kid_play["t"]) > 0.6 and st.has(kid) and String(st[kid]["k"]) == "kick":
				_pose(kid, "cheer", {"anim": "idle"})
			_look_at(kid, pl.global_position, dt * 6.0)
			if float(kid_play["t"]) > 9.0 and st.has(kid) and not kid_play.get("nag", false):
				kid_play["nag"] = true
				_say(kid, "Hadiii, vursana!", 2.4)
		"fall":
			if float(kid_play["t"]) > 1.0:
				kid_play["state"] = "cry"
				kid_play["t"] = 0.0
				kid.model.play("idle", 0.3)
				_pose(kid, "cry", {"anim": "idle", "sit": "agura"})
				_say(kid, "Uwaaaaah! Dizim!", 3.5)
				_ball_it("[F] Teselli et", "comfort", kid.global_position + Vector3.UP * 0.3, kid)
		"cry":
			if fmod(float(kid_play["t"]), 0.5) < dt and is_instance_valid(kid):
				for sd in [-1.0, 1.0]:
					FX.burst(_bone(kid, "Head") + _fd(kid) * 0.1 + _fd(kid).cross(Vector3.UP).normalized() * 0.05 * sd, {"amount": 2, "life": 0.5, "size": 0.035, "vmin": 0.4, "vmax": 1.0, "gravity": Vector3(0, -6, 0),
						"colors": [Color(0.6, 0.85, 1.0, 1), Color(0.6, 0.85, 1.0, 0)]})
			if fmod(float(kid_play["t"]), 4.0) < dt and float(kid_play["t"]) > 3.0:
				_say(kid, ["Anneeee!", "Çok acıyooor!", "Uwaaah!"].pick_random(), 2.4)
		"happy":
			if float(kid_play["t"]) > 2.2:
				_clear_pose(kid)
				kid_play["state"] = "chase"
				kid_play["n"] = 0
				kid_play["t"] = 0.0


## Oyuncu topa vurur: top çocuğa döner
func _act_ball(it: Dictionary) -> void:
	var pl = Game.player
	var ball: Node3D = kid_play.get("ball")
	var kid: Node3D = kid_play.get("kid")
	if not is_instance_valid(ball) or not is_instance_valid(kid):
		return
	kid_play["vel"] = Vector3.ZERO
	var to = kid.global_position - ball.global_position
	to.y = 0
	var sp = ball.global_position - to.normalized() * 0.55
	sp.y = pl.global_position.y
	await _go_w(pl, sp, 3.4, false, 0.15)
	_look_at(pl, kid.global_position)
	_pose(pl, "kick", {"anim": "idle"})
	await _wait(0.16)
	if not is_instance_valid(ball) or not is_instance_valid(kid):
		return
	to = kid.global_position - ball.global_position
	to.y = 0
	kid_play["vel"] = to.normalized() * clampf(to.length() * 1.1, 4.0, 11.0) + Vector3.UP * 3.0
	Sfx.play("punch", ball.global_position, 0.6, 1.3)
	await _wait(0.4)
	kid_play["n"] = int(kid_play["n"]) + 1
	kid_play["state"] = "chase"
	kid_play["t"] = 0.0
	kid_play["nag"] = false
	kid_play["it"] = {}
	_clear_pose(kid)
	_say(kid, ["Güzel vuruş!", "Vaay! Bir daha!", "Hahaha!"].pick_random(), 2.0)


## Düşüp ağlayan çocuğu teselli et: yanına çök, başını okşa; çocuk gözünü siler, ayağa kalkar
func _act_comfort(it: Dictionary) -> void:
	var pl = Game.player
	var kid: Node3D = kid_play.get("kid")
	if not is_instance_valid(kid):
		return
	await _stand_at(kid, 0.62)
	_look_at(kid, pl.global_position)
	_pose(pl, "pat_kid", {"sit": "seiza", "anim": "idle", "with": kid, "lift": 0.0})
	await _wait(0.7)
	Combat.popup_text(pl.global_position + Vector3.UP * 1.5, "Geçti, geçti. Ninjalar ağlamaz... çoğu zaman.", Color(0.8, 0.95, 1.0))
	await _wait(1.9)
	kid_play["state"] = "happy"
	kid_play["t"] = 0.0
	kid_play["it"] = {}
	_pose(kid, "cheer", {"anim": "idle"})
	_say(kid, "...Acımıyor artık! Sen iyi bir ninjasın!", 2.6)
	await _wait(0.5)


# ====================================================================== gidip gelen görev veren (pazara giden anne)
func walk_off(npc: Node3D, dist := 26.0) -> void:
	if not is_instance_valid(npc):
		return
	stop_busy(npc)
	npc.set_physics_process(false)
	npc.remove_from_group("talkers")
	var pl = Game.player
	var away = npc.global_position - pl.global_position
	away.y = 0
	var tgt = Missions.open_ground(npc.global_position + away.normalized() * dist, 8.0)
	npc.set_meta("came_from", npc.global_position)
	await _go_w(npc, tgt, 2.3, false, 0.6)
	if is_instance_valid(npc):
		npc.visible = false


func walk_back(npc: Node3D) -> void:
	if not is_instance_valid(npc) or npc.visible:
		return
	npc.visible = true
	var pl = Game.player
	var to = pl.global_position - npc.global_position
	to.y = 0
	var tgt = pl.global_position - to.normalized() * 2.2
	_say(npc, "Geldim, geldim! Bir şey olmadı ya?", 3.0)
	await _go_w(npc, tgt, 2.3, false, 0.3)
	if is_instance_valid(npc):
		npc.home = npc.global_position
		npc.goal = npc.global_position
		npc.add_to_group("talkers")
		npc.set_physics_process(true)
		_look_at(npc, pl.global_position)
