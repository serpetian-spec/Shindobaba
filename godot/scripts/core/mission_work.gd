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
var sites := {}          # "görev id:tür" -> {"root", "npc_at", "face", ...}
var cart_d := {}         # eskort arabası: {"npc", "ox", "cart", "legs", "trail"}
var dog_d := {}          # iz süren ninken: {"dog", "legs", "i", "t"}
var rider_kind := ""
var rider_yaw := PI * 0.5
var load_n := 0          # sırt küfesindeki parça sayısı
var tagged: Array = []   # mühür yapıştırılmış sandık yığınları (sabotaj)
var bound_d := {}        # bağlı rehine -> {"post", "rope"}
var rider_off := Vector3(0.19, 1.38, -0.03)
var job_d := {}          # aktif iş yeri (iskele / onarım / inşaat / ders): {"kind", "root", ...}
var hunt_d := {}         # av: {"root", "rack", "rack_front", "prey", "hung"}


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
		rider.global_position = pl.global_position + Vector3.UP * (rider_off.y * sc + pl.model_lift) + right * rider_off.x * sc + fd * rider_off.z * sc
		rider.rotation.y = pl.facing + rider_yaw
	_kid_tick(dt)
	_cart_tick(dt)
	_dog_tick(dt)
	_caravan_tick(dt)
	_decoy_tick(dt)


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
		"clue":
			_build_clue(root, int(extra.get("clue", idx)), rng, String(extra.get("ck", "")))
		"sack":
			_build_loot(root)
		"book":
			_build_book(root)
		"scroll":
			_build_scroll(root)
		"crate":
			_build_crates(root, rng)
		"item":
			_build_item(root, String(extra.get("item", "")), rng)
		"spot":
			_build_spot(root, String(extra.get("style", "stone")), rng)
		"lamp":
			_build_lamp(root)
		"trace":
			_build_clue(root, idx, rng, String(extra.get("ck", "prints")))
	if kind == "book" and extra.has("look"):
		_restyle_doc(root, String(extra["look"]))
	if kind in ["clue", "sack", "scroll", "item", "trace"]:
		# çimen izin üstünü örtmesin
		var lane = [Vector2(pos.x - 0.6, pos.z), Vector2(pos.x + 0.6, pos.z), 1.5, true]
		RM.lanes.append(lane)
		RM.lanes_dirty = true
		root.tree_exiting.connect(func():
			RM.lanes.erase(lane)
			RM.lanes_dirty = true)
	var it = {"pos": pos + Vector3.UP * 0.2, "radius": 2.4, "kind": "quest", "label": label, "qkey": Missions._key(), "qi": idx, "work": kind, "node": root}
	it.merge(extra)
	Interact.add(it)
	root.set_meta("it", it)
	root.tree_exiting.connect(func(): Interact.items.erase(it))
	_own(root, bool(extra.get("keep", false)))
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
		"clue":
			await _act_examine(it)
		"sack":
			await _act_sack(it)
		"book", "scroll":
			await _act_take(it)
		"crate":
			await _act_tag(it)
		"item":
			match String(it.get("act", "take")):
				"cut":
					await _act_herb(it)
				"back":
					await _act_back(it)
				_:
					await _act_take(it)
			Hud.float_text("+1 %s" % String(it.get("item", "")), Color(0.6, 1, 0.6))
		"spot":
			await _act_spot(it)
		"flame":
			await _act_douse(it)
		"carcass":
			await _act_carcass(it)
		"rack":
			await _act_rack(it)
		"lamp":
			await _act_lamp(it)
		"fish":
			await _act_fish(it)
		"plank":
			await _act_plank(it)
		"build":
			await _act_build(it)
		"teach":
			await _act_teach(it)
		"block":
			await _act_block(it)
		"loot":
			await _act_loot(it)
		"stash":
			await _act_stash(it)
		"cage":
			await _act_cage(it)
		"pack":
			await _act_pack(it)
		"decoy":
			await _act_decoy(it)
		"trace":
			await _act_wipe(it)
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
		"stand", "fold":
			return {"arms": [], "fL": HALF, "fR": HALF, "spine": 0.0, "neck": 0.0}
		"meditate":
			# eller dizlerde, baş hafif önde, yavaş nefes
			var br = sin(t * 1.6)
			var hp7 = _bone(n, "Hips")
			var arms20 = _ik(n, "Left", hp7 - right * 0.24 + fd * 0.26 + Vector3.UP * 0.08)
			arms20.append_array(_ik(n, "Right", hp7 + right * 0.24 + fd * 0.26 + Vector3.UP * 0.08))
			return {"arms": arms20, "fL": HALF, "fR": HALF, "spine": 2.0 + br * 1.5, "neck": 8.0}
		"slap":
			# kolu geri çeker, avucunu sandığa yapıştırır, bir an bastırır
			var at5: Vector3 = s["at"]
			var back5 = smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(0.25, 0.4, t))
			var k16 = smoothstep(0.28, 0.42, t) * (1.0 - smoothstep(0.95, 1.25, t))
			var rest16 = n.global_position + fd * 0.15 + right * 0.2 + Vector3.UP * 1.0 * sc
			var h16 = rest16.lerp(rest16 - fd * 0.25 + Vector3.UP * 0.15, back5).lerp(at5, k16)
			return {"arms": _ik(n, "Right", h16, 0.0), "fL": HALF, "fR": OPEN, "spine": 10.0 * k16 - 6.0 * back5, "neck": 4.0, "twist": -18.0 * k16 + 14.0 * back5}
		"bound":
			# eller arkada bağlı, baş önde; ara sıra kurtulmaya çalışır
			var hp5 = _bone(n, "Hips")
			var wr = sin(t * 2.2) * maxf(0.0, sin(t * 0.5))
			var arms17 = _ik(n, "Left", hp5 - fd * 0.2 - right * 0.06 + Vector3.UP * 0.12)
			arms17.append_array(_ik(n, "Right", hp5 - fd * 0.2 + right * 0.06 + Vector3.UP * 0.12))
			return {"arms": arms17, "fL": GRIP, "fR": GRIP, "spine": 10.0, "neck": 22.0 - 10.0 * absf(wr), "twist": wr * 9.0}
		"cheer":
			# iki kol havada, zıplar gibi sallanır
			var hd6 = _bone(n, "Head")
			var bb6 = sin(t * 8.0 + float(s.get("ph", 0.0)))
			var arms18 = _ik(n, "Left", hd6 - right * 0.32 + Vector3.UP * (0.34 + 0.07 * bb6))
			arms18.append_array(_ik(n, "Right", hd6 + right * 0.32 + Vector3.UP * (0.34 - 0.07 * bb6)))
			return {"arms": arms18, "fL": OPEN, "fR": OPEN, "spine": -6.0, "neck": -8.0}
		"embrace":
			# karşısındakine sarılır
			var o2: Node3D = s.get("with")
			if not is_instance_valid(o2):
				return {"arms": [], "fL": HALF, "fR": HALF}
			var k19 = smoothstep(0.0, 0.5, t)
			var osc: float = o2.model.age_scale
			var bk19 = o2.global_position + Vector3.UP * 1.12 * minf(sc, osc) + fd * 0.06
			var rest19 = n.global_position + fd * 0.15 + Vector3.UP * 0.9 * sc
			var arms19 = _ik(n, "Left", (rest19 - right * 0.2).lerp(bk19 - right * 0.17 + Vector3.UP * 0.08, k19))
			arms19.append_array(_ik(n, "Right", (rest19 + right * 0.2).lerp(bk19 + right * 0.17 - Vector3.UP * 0.06, k19)))
			return {"arms": arms19, "fL": OPEN, "fR": OPEN, "spine": 9.0 * k19, "neck": 12.0 * k19}
		"fret":
			# bir el alında, öbürü belde; sağa sola sallanır
			var sw = sin(t * 1.6)
			var fh = _bone(n, "Head") + fd * 0.1 * sc + Vector3.UP * 0.07 * sc
			var arms12 = _ik(n, "Right", fh + right * 0.03)
			arms12.append(["LeftUpperArm", Vector3(0.55, -0.7, -0.1)])
			arms12.append(["LeftLowerArm", Vector3(-0.7, -0.35, 0.4)])
			return {"arms": arms12, "fL": HALF, "fR": OPEN, "spine": 6.0, "neck": 14.0, "twist": sw * 10.0}
		"knead":
			# tezgâhtaki hamuru iki avuçla bastırıp iter
			var ph2 = sin(t * 3.4)
			var tb = n.global_position + fd * (0.42 + 0.07 * ph2) + Vector3.UP * (0.92 * sc - 0.02 * ph2)
			var arms13 = _ik(n, "Left", tb - right * 0.09, 10.0)
			arms13.append_array(_ik(n, "Right", tb + right * 0.09, 10.0))
			return {"arms": arms13, "fL": OPEN, "fR": OPEN, "spine": 14.0 + 5.0 * ph2, "neck": 12.0}
		"cower":
			# eller başın üstünde
			var hd = _bone(n, "Head") + Vector3.UP * 0.14 * sc
			var arms14 = _ik(n, "Left", hd - right * 0.08 + fd * 0.03)
			arms14.append_array(_ik(n, "Right", hd + right * 0.08 + fd * 0.03))
			return {"arms": arms14, "fL": HALF, "fR": HALF, "spine": 22.0 + sin(t * 14.0) * 1.5, "neck": 20.0}
		"examine":
			# çöker: önce eliyle yoklar, sonra eli çenesinde düşünür
			var at4: Vector3 = s["at"]
			var k15 = smoothstep(0.0, 0.4, t) * (1.0 - smoothstep(1.3, 1.7, t))
			var th = smoothstep(1.4, 1.9, t)
			var rest15 = n.global_position + fd * 0.2 + Vector3.UP * 0.5 * sc
			var chin = _bone(n, "Head") + fd * 0.1 * sc - Vector3.UP * 0.07 * sc
			var h15 = rest15.lerp(at4 + Vector3.UP * 0.1 + right * sin(t * 5.0) * 0.07, k15).lerp(chin, th)
			var arms15 = _ik(n, "Right", h15, 30.0 * k15)
			arms15.append(["LeftUpperArm", Vector3(0.18, -0.85, 0.45)])
			arms15.append(["LeftLowerArm", Vector3(-0.1, -0.5, 0.86)])
			return {"arms": arms15, "fL": HALF, "fR": OPEN if th < 0.5 else HALF, "spine": 32.0 * k15 + 6.0 * th, "neck": 16.0 * k15 - 4.0 * th}
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
		"blow":
			# göğüs önünde mühür, sonra baş geriye: el ağzın önünde halka, göğe üfler
			var k20 = smoothstep(0.55, 0.85, t)
			var chest = n.global_position + fd * 0.26 * sc + Vector3.UP * 1.12 * sc
			var mouth = _bone(n, "Head") + fd * 0.13 * sc + Vector3.UP * 0.02 * sc
			var arms20 = _ik(n, "Right", chest.lerp(mouth, k20) + right * 0.02)
			arms20.append_array(_ik(n, "Left", chest.lerp(chest - Vector3.UP * 0.12 * sc, k20) - right * 0.02))
			return {"arms": arms20, "fL": HALF, "fR": HALF, "spine": 4.0 - 9.0 * k20, "neck": -24.0 * k20}
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
	if npc is QuestNPC:
		npc.set_physics_process(false)   # bekleme animasyonu pozu ezmesin
	_pose(npc, kind, {"anim": "fold" if kind == "fold" else "idle"})


func stop_busy(npc: Node3D) -> void:
	if busy_npcs.has(npc):
		busy_npcs.erase(npc)
		_clear_pose(npc)
		if npc is QuestNPC:
			npc.set_physics_process(true)


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
	var carried = is_instance_valid(rider) and rider_kind == kind
	if carried:
		item = rider
		rider = null
	else:
		item = _item(kind)
	_pose(pl, "give", {"anim": "idle", "w": 0.17})
	var t := 0.0
	while t < 0.7:
		t += get_process_delta_time()
		item.global_position = item.global_position.lerp(_held(pl) + Vector3.UP * 0.02, 0.35) if carried else _held(pl) + Vector3.UP * 0.02
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
		"book":
			_book_parts(b, Vector3(0, 0.03, 0))
		"scroll":
			_scroll_parts(b, Vector3(0, 0.07, 0))
		"letter":
			b.add("cyl", Vector3(0, 0.03, 0), Vector3(0.06, 0.3, 0.06), Color(0.93, 0.89, 0.78), Vector3(0, 0, 90), 8)
			for sd in [-1.0, 1.0]:
				b.add("cyl", Vector3(sd * 0.15, 0.03, 0), Vector3(0.075, 0.025, 0.075), Color(0.3, 0.2, 0.14), Vector3(0, 0, 90), 8)
			b.add("cyl", Vector3(0, 0.03, 0), Vector3(0.068, 0.05, 0.068), Color(0.75, 0.15, 0.13), Vector3(0, 0, 90), 8)
			b.add("cyl", Vector3(0, 0.03, 0.036), Vector3(0.05, 0.012, 0.05), Color(0.85, 0.7, 0.25), Vector3(90, 0, 0), 8)
		"band":
			_band_parts(b, Vector3(0, 0.02, 0))
		"pouch":
			b.add("sphere", Vector3(0, 0.06, 0), Vector3(0.18, 0.14, 0.16), Color(0.55, 0.42, 0.22), Vector3.ZERO, 10)
			b.add("cyl", Vector3(0, 0.135, 0), Vector3(0.065, 0.05, 0.065), Color(0.5, 0.38, 0.2), Vector3.ZERO, 8)
			b.add("cyl", Vector3(0, 0.125, 0), Vector3(0.085, 0.014, 0.085), Color(0.75, 0.2, 0.18), Vector3.ZERO, 8)
		"dango":
			b.add("cyl", Vector3(0, 0.1, 0), Vector3(0.012, 0.3, 0.012), Color(0.75, 0.62, 0.4), Vector3.ZERO, 5)
			for k in 3:
				b.add("sphere", Vector3(0, 0.08 + k * 0.07, 0), Vector3.ONE * 0.075, [Color(0.95, 0.7, 0.75), Color(0.96, 0.95, 0.9), Color(0.62, 0.8, 0.5)][k], Vector3.ZERO, 8)
		_:
			b.add("box", Vector3(0, 0.08, 0), Vector3(0.3, 0.16, 0.22), Color(0.6, 0.45, 0.28))
	return _mesh(b)


## Ödül / teşekkür: NPC eşyayı uzatır, oyuncu alır (kese cebe girer)
func receive(npc: Node3D, kind: String) -> void:
	var pl = Game.player
	if not is_instance_valid(npc):
		return
	busy_run = true
	_lock(15.0)
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
	var item = _item(kind)
	_pose(npc, "give", {"anim": "idle", "w": 0.08})
	var t := 0.0
	while t < 0.6 and is_instance_valid(npc):
		t += get_process_delta_time()
		item.global_position = _held(npc) + Vector3.UP * 0.02
		await get_tree().process_frame
	_pose(pl, "take", {"anim": "idle", "w": 0.08})
	await _wait(0.4)
	var from = item.global_position
	t = 0.0
	while t < 0.35:
		t += get_process_delta_time()
		item.global_position = from.lerp(_held(pl) + Vector3.UP * 0.02, smoothstep(0.0, 0.35, t))
		await get_tree().process_frame
	Sfx.play("coin" if kind == "pouch" else "pickup", item.global_position, 0.8)
	if is_instance_valid(npc):
		_clear_pose(npc)
		_pose(npc, "bow", {"anim": "idle", "len": 1.4})
	# cebe / keseye
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	from = item.global_position
	var hip = pl.global_position + Vector3.UP * 0.9 * pl.model.age_scale - _fd(pl).cross(Vector3.UP).normalized() * 0.2
	t = 0.0
	while t < 0.4:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.4, t)
		item.global_position = from.lerp(hip, k)
		item.scale = Vector3.ONE * (1.0 - 0.7 * k)
		await get_tree().process_frame
	item.queue_free()
	await _wait(0.9)
	if is_instance_valid(npc):
		_clear_pose(npc)
		if npc is QuestNPC:
			npc.set_physics_process(true)
	_release_player()
	busy_run = false


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
	rider_kind = "cat"
	rider_yaw = PI * 0.5
	rider_off = Vector3(0.19, 1.38, -0.03)
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


# ====================================================================== görev mekânları (görev başından sonuna durur)
## tür: "stall_wrecked" soyulmuş tezgâh, "bakery" fırın tezgâhı, "checkpoint" sınır karakolu
func site(kind: String, c: Vector3) -> Dictionary:
	var key = "%s:%s" % [String(Missions.active().get("id", "")), kind]
	if sites.has(key) and is_instance_valid(sites[key].get("root")):
		return sites[key]
	var hx = {"checkpoint": 6.0, "hunt_camp": 4.6, "guard_post": 3.0, "repair_house": 5.8, "build_lot": 6.2, "class_yard": 6.2, "jail": 4.6, "depot": 4.6}.get(kind, 2.4)
	var hz = {"checkpoint": 5.0, "hunt_camp": 3.4, "guard_post": 2.6, "repair_house": 3.8, "build_lot": 3.6, "class_yard": 5.6, "jail": 4.2, "depot": 4.4}.get(kind, 2.2)
	if kind.begins_with("beacon") and Game.world and Game.world.vegetation:
		# işaret ateşi ağaçların altında yanmaz: çevresi açık bir yer ara
		var veg = Game.world.vegetation
		var found := false
		for ring in 9:
			for k in (1 if ring == 0 else 10):
				var aa = TAU * k / 10.0 + ring * 0.7
				var q = c + Vector3(cos(aa), 0, sin(aa)) * ring * 14.0
				if not veg.trunk_near(q.x, q.z, 11.0) and Game.terrain_height(q.x, q.z) > 0.5:
					c = q
					found = true
					break
			if found:
				break
	if not kind in ["fish_dock", "ambush"] and not Missions.active().get("fixed_site", false):   # iskele kıyıda, pusu yolun üstünde kalır; yeniden kurulan yapı eski yerinde
		c = clear_spot(c, hx, hz) if kind != "checkpoint" else Missions.open_ground(c, 40.0)
	c.y = Game.ground_height(c.x, c.z)
	if kind == "build_lot" and String(Missions.active().get("rjob", "")) == "hut":
		Missions.active()["hut_at"] = [Game.to_map(c).x, Game.to_map(c).y]
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = c
	_own(root, true)
	var body = StaticBody3D.new()
	root.add_child(body)
	var gy = func(x: float, z: float) -> float: return Game.ground_height(c.x + x, c.z + z) - c.y
	var solid = func(p: Vector3, size: Vector3) -> void:
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		cs.position = p
		body.add_child(cs)
	var b = MB.new()
	var wood = Color(0.48, 0.35, 0.22)
	var d = {"root": root, "npc_at": c + Vector3(0, 0, 1.6), "face": c + Vector3(0, 0, 5.0)}
	match kind:
		"stall_wrecked", "bakery":
			var g0: float = gy.call(0, 0)
			# tezgâh + dört direk + tente
			b.add("box", Vector3(0, g0 + 0.82, 0), Vector3(2.6, 0.1, 1.0), wood.lightened(0.08))
			b.add("box", Vector3(0, g0 + 0.4, 0.45), Vector3(2.6, 0.8, 0.06), wood)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.27, g0 + 0.4, 0), Vector3(0.06, 0.8, 1.0), wood)
				for sz in [-1.0, 1.0]:
					b.add("box", Vector3(sx * 1.25, g0 + 1.15, sz * 0.48), Vector3(0.09, 2.3, 0.09), wood.darkened(0.15))
			solid.call(Vector3(0, g0 + 0.45, 0), Vector3(2.6, 0.9, 1.0))
			if kind == "bakery":
				b.add("box", Vector3(0, g0 + 2.35, 0.1), Vector3(2.9, 0.06, 1.5), Color(0.85, 0.75, 0.5), Vector3(-10, 0, 0))
				b.add("box", Vector3(0, g0 + 2.25, 0.85), Vector3(2.9, 0.3, 0.03), Color(0.8, 0.45, 0.25))
				# hamur, un, somunlar
				b.add("sphere", Vector3(0, g0 + 0.92, -0.05), Vector3(0.5, 0.14, 0.38), Color(0.95, 0.9, 0.78), Vector3.ZERO, 10)
				b.add("cyl", Vector3(0, g0 + 0.875, -0.05), Vector3(0.8, 0.01, 0.6), Color(0.97, 0.96, 0.93), Vector3.ZERO, 10)
				for k in 4:
					b.add("sphere", Vector3(-0.95 + k * 0.24, g0 + 0.93, 0.25), Vector3(0.22, 0.13, 0.14), Color(0.78, 0.55, 0.3), Vector3(0, 20, 0), 8)
				b.add("cyl", Vector3(0.95, g0 + 0.98, -0.2), Vector3(0.24, 0.22, 0.24), Color(0.82, 0.75, 0.6), Vector3.ZERO, 8)
				# taş fırın (arkada)
				b.add("box", Vector3(0, g0 + 0.6, -1.6), Vector3(1.6, 1.2, 1.2), Color(0.6, 0.56, 0.5))
				b.add("hemi", Vector3(0, g0 + 1.2, -1.6), Vector3(1.6, 0.8, 1.2), Color(0.56, 0.52, 0.46), Vector3.ZERO, 10)
				b.add("box", Vector3(0, g0 + 0.75, -0.99), Vector3(0.6, 0.45, 0.04), Color(0.1, 0.08, 0.07))
				b.add("box", Vector3(0, g0 + 0.6, -0.985), Vector3(0.45, 0.14, 0.04), Color(0.95, 0.5, 0.15))
				b.add("box", Vector3(0.5, g0 + 2.0, -1.8), Vector3(0.3, 1.0, 0.3), Color(0.5, 0.47, 0.42))
				solid.call(Vector3(0, g0 + 0.8, -1.6), Vector3(1.6, 1.6, 1.2))
				d["npc_at"] = c + Vector3(0, 0, -0.78)   # tezgâhın arkasında, hamurun başında
				d["face"] = c + Vector3(0, 0, 3.0)
			else:
				# tente yırtık, bir yanı sarkmış
				b.add("box", Vector3(-0.55, g0 + 2.3, 0.1), Vector3(1.7, 0.05, 1.5), Color(0.3, 0.45, 0.62), Vector3(-10, 0, 6))
				b.add("box", Vector3(0.95, g0 + 1.75, 0.2), Vector3(1.0, 0.05, 1.3), Color(0.3, 0.45, 0.62), Vector3(-6, 0, -62))
				# devrilmiş sandıklar, kırık testi, saçılmış mallar, açık boş kasa
				b.add("box", Vector3(1.9, gy.call(1.9, 0.9) + 0.25, 0.9), Vector3(0.6, 0.5, 0.6), wood.lightened(0.05), Vector3(0, 25, 90))
				b.add("box", Vector3(-1.7, gy.call(-1.7, 1.2) + 0.2, 1.2), Vector3(0.55, 0.4, 0.55), wood, Vector3(18, -30, 0))
				for k in 7:
					var a = k * 0.9
					var q = Vector3(cos(a) * (0.7 + k * 0.16), 0, 1.1 + sin(a) * 0.5)
					b.add("sphere", q + Vector3(0, gy.call(q.x, q.z) + 0.07, 0), Vector3.ONE * 0.14, [Color(0.9, 0.35, 0.2), Color(0.95, 0.75, 0.25), Color(0.5, 0.7, 0.3)][k % 3], Vector3.ZERO, 7)
				b.add("hemi", Vector3(-0.6, gy.call(-0.6, 1.5) + 0.02, 1.5), Vector3(0.36, 0.3, 0.36), Color(0.62, 0.42, 0.3), Vector3(120, 30, 0), 8)
				b.add("box", Vector3(0.3, g0 + 0.93, 0.05), Vector3(0.42, 0.12, 0.3), Color(0.25, 0.2, 0.16))
				b.add("box", Vector3(0.3, g0 + 1.08, -0.1), Vector3(0.42, 0.3, 0.03), Color(0.3, 0.24, 0.18), Vector3(-25, 0, 0))
				b.add("box", Vector3(0.3, g0 + 0.975, 0.05), Vector3(0.36, 0.01, 0.24), Color(0.08, 0.07, 0.06))
				b.add("box", Vector3(-0.7, g0 + 0.89, 0.1), Vector3(0.5, 0.02, 0.3), Color(0.9, 0.88, 0.8), Vector3(0, 20, 0))
				d["npc_at"] = c + Vector3(-0.2, 0, 1.9)
				d["face"] = c + Vector3(0.3, 0, 0)
		"well_poisoned":
			# zehirlenen kuyu: taş bilezik, çatı, mor su, çapraz çakılmış tahtalar, devrik kova
			var g2: float = gy.call(0, 0)
			var stone = Color(0.58, 0.56, 0.52)
			for k in 12:
				var a7 = TAU * k / 12.0
				b.add("box", Vector3(cos(a7) * 0.9, g2 + 0.4, sin(a7) * 0.9), Vector3(0.5, 0.8, 0.3), stone.darkened((k % 3) * 0.06), Vector3(0, -rad_to_deg(a7) + 90.0, 0))
			b.add("cyl", Vector3(0, g2 + 0.5, 0), Vector3(1.6, 0.04, 1.6), Color(0.45, 0.22, 0.55), Vector3.ZERO, 12)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.05, g2 + 1.3, 0), Vector3(0.12, 2.6, 0.12), wood.darkened(0.15))
			b.add("prism", Vector3(0, g2 + 2.85, 0), Vector3(2.6, 0.6, 1.6), Color(0.35, 0.26, 0.2))
			b.add("cyl", Vector3(0, g2 + 2.2, 0), Vector3(0.12, 2.0, 0.12), wood, Vector3(0, 0, 90), 6)
			b.add("box", Vector3(0, g2 + 0.86, 0), Vector3(2.3, 0.05, 0.2), wood.lightened(0.1), Vector3(0, 35, 0))
			b.add("box", Vector3(0, g2 + 0.9, 0), Vector3(2.3, 0.05, 0.2), wood.lightened(0.05), Vector3(0, -35, 0))
			b.add("cyl", Vector3(1.7, gy.call(1.7, 0.8) + 0.16, 0.8), Vector3(0.34, 0.36, 0.34), wood, Vector3(0, 0, 85), 8)
			b.add("sphere", Vector3(2.1, gy.call(2.1, 0.8) + 0.01, 0.8), Vector3(0.9, 0.03, 0.6), Color(0.45, 0.22, 0.55), Vector3.ZERO, 9)
			solid.call(Vector3(0, g2 + 0.45, 0), Vector3(2.0, 0.9, 2.0))
			d["npc_at"] = c + Vector3(-1.2, 0, 1.9)
			d["face"] = c
		"barn_robbed":
			# soyulan ambar: direkler üstünde küçük kiler, kapısı açık, kilidi kırık, içi boş; yerde dökülmüş pirinç
			var g3: float = gy.call(0, 0)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					b.add("cyl", Vector3(sx * 1.3, g3 + 0.3, sz * 1.0 - 0.6), Vector3(0.22, 0.6, 0.22), stone_c(), Vector3.ZERO, 6)
			b.add("box", Vector3(0, g3 + 0.66, -0.6), Vector3(3.2, 0.14, 2.6), wood.darkened(0.1))
			b.add("box", Vector3(0, g3 + 1.7, -1.75), Vector3(3.0, 2.0, 0.12), Color(0.86, 0.82, 0.72))
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.45, g3 + 1.7, -0.6), Vector3(0.12, 2.0, 2.4), Color(0.86, 0.82, 0.72))
				b.add("box", Vector3(sx * 1.05, g3 + 1.7, 0.55), Vector3(0.9, 2.0, 0.12), Color(0.86, 0.82, 0.72))
			b.add("box", Vector3(0, g3 + 1.7, -0.5), Vector3(2.7, 1.9, 2.1), Color(0.07, 0.06, 0.05))   # karanlık iç
			b.add("box", Vector3(0, g3 + 2.5, 0.56), Vector3(1.3, 0.4, 0.12), Color(0.86, 0.82, 0.72))
			b.add("prism", Vector3(0, g3 + 3.15, -0.6), Vector3(3.8, 0.9, 3.2), Color(0.3, 0.26, 0.24))
			b.add("box", Vector3(0.95, g3 + 1.55, 1.0), Vector3(0.08, 1.6, 0.9), wood, Vector3(0, -25, 0))   # açık kapı kanadı
			b.add("box", Vector3(0.3, gy.call(0.3, 1.5) + 0.04, 1.5), Vector3(0.14, 0.08, 0.1), Color(0.3, 0.3, 0.33), Vector3(0, 30, 20))   # kırık kilit
			b.add("box", Vector3(0, g3 + 0.36, 1.0), Vector3(1.2, 0.12, 0.5), wood.darkened(0.15))   # basamak
			b.add("sphere", Vector3(-0.3, g3 + 0.95, 0.1), Vector3(0.6, 0.4, 0.5), Color(0.72, 0.62, 0.42), Vector3(0, 0, 20), 8)   # kalan tek çuval
			for k in 16:
				b.add("sphere", Vector3(-0.5 + k * 0.1 + sin(k * 2.1) * 0.1, gy.call(0, 1.6) + 0.02, 1.4 + k * 0.08), Vector3(0.07, 0.02, 0.05), Color(0.97, 0.96, 0.9), Vector3.ZERO, 5)
			solid.call(Vector3(0, g3 + 1.4, -0.6), Vector3(3.2, 2.8, 2.6))
			d["npc_at"] = c + Vector3(-1.3, 0, 2.0)
			d["face"] = c + Vector3(0, 0, 0.5)
		"stable_burnt":
			# kundaklanan ahır: kömürleşmiş direkler, çökmüş kirişler, kül, yarı yanmış saman, su kovaları
			var g4: float = gy.call(0, 0)
			var burnt = Color(0.11, 0.1, 0.09)
			b.add("cyl", Vector3(0, g4 + 0.015, -0.4), Vector3(4.2, 0.03, 3.6), Color(0.26, 0.25, 0.24), Vector3.ZERO, 12)
			var hs = [2.4, 1.5, 2.0, 0.9]
			for q in 4:
				var px = (q % 2 - 0.5) * 3.4
				var pz = (q / 2 - 0.5) * 2.6 - 0.4
				b.add("box", Vector3(px, gy.call(px, pz) + hs[q] * 0.5, pz), Vector3(0.2, hs[q], 0.2), burnt, Vector3(0, 0, (q - 1.5) * 3.0))
				solid.call(Vector3(px, gy.call(px, pz) + hs[q] * 0.5, pz), Vector3(0.2, hs[q], 0.2))
			b.add("box", Vector3(-0.4, g4 + 1.2, -1.7), Vector3(3.6, 0.18, 0.18), burnt, Vector3(0, 0, -15))
			b.add("box", Vector3(0.6, g4 + 0.5, -0.2), Vector3(0.18, 0.18, 3.0), burnt.lightened(0.04), Vector3(22, 14, 0))
			b.add("box", Vector3(-0.9, g4 + 0.12, 0.3), Vector3(2.2, 0.16, 0.18), burnt, Vector3(0, 40, 0))
			for k in 5:
				b.add("box", Vector3(-1.2 + k * 0.6, g4 + 0.03, -0.6 + sin(k * 1.7) * 0.6), Vector3(0.5, 0.04, 0.14), Color(0.85, 0.4, 0.12).darkened(0.3 + (k % 2) * 0.2), Vector3(0, k * 40.0, 0))
			b.add("sphere", Vector3(1.3, g4 + 0.3, -1.2), Vector3(1.1, 0.6, 0.9), Color(0.78, 0.66, 0.3), Vector3.ZERO, 8)
			b.add("sphere", Vector3(1.0, g4 + 0.34, -1.0), Vector3(0.8, 0.5, 0.7), Color(0.16, 0.14, 0.1), Vector3.ZERO, 7)
			for k in 2:
				b.add("cyl", Vector3(-2.2 + k * 0.45, gy.call(-2.2, 1.6) + 0.18, 1.6 + k * 0.2), Vector3(0.34, 0.36, 0.34), wood, Vector3.ZERO, 8)
			d["npc_at"] = c + Vector3(0.6, 0, 2.2)
			d["face"] = c + Vector3(0, 0, -0.4)
		"workbench":
			# soyulan atölye: sundurma altında tezgâh, arkada alet panosu (boş askılar), açık boş parça sandığı, talaş
			var g5: float = gy.call(0, 0)
			b.add("box", Vector3(0, g5 + 0.84, 0), Vector3(2.6, 0.1, 0.9), wood.lightened(0.08))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					b.add("box", Vector3(sx * 1.2, g5 + 0.4, sz * 0.38), Vector3(0.1, 0.8, 0.1), wood.darkened(0.1))
			b.add("box", Vector3(0, g5 + 1.5, -0.75), Vector3(2.8, 1.6, 0.08), wood.darkened(0.2))
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.4, g5 + 1.3, -0.75), Vector3(0.12, 2.6, 0.12), wood.darkened(0.25))
				b.add("box", Vector3(sx * 1.4, g5 + 1.2, 0.9), Vector3(0.1, 2.4, 0.1), wood.darkened(0.25))
			b.add("box", Vector3(0, g5 + 2.6, 0.1), Vector3(3.2, 0.06, 2.0), Color(0.4, 0.3, 0.24), Vector3(-8, 0, 0))
			for k in 8:
				b.add("cyl", Vector3(-1.05 + k * 0.3, g5 + 1.9, -0.68), Vector3(0.03, 0.1, 0.03), Color(0.3, 0.3, 0.33), Vector3(90, 0, 0), 4)
			b.add("box", Vector3(-1.05, g5 + 1.62, -0.69), Vector3(0.06, 0.5, 0.03), Color(0.3, 0.3, 0.33))   # kalan tek alet
			b.add("box", Vector3(-1.05, g5 + 1.4, -0.69), Vector3(0.16, 0.12, 0.05), Color(0.3, 0.3, 0.33))
			for k in 3:   # çalınan aletlerin panodaki soluk izi
				b.add("box", Vector3(-0.45 + k * 0.6, g5 + 1.6, -0.705), Vector3(0.1, 0.5, 0.01), wood.lightened(0.12))
			b.add("box", Vector3(1.8, gy.call(1.8, 0.3) + 0.25, 0.3), Vector3(0.8, 0.5, 0.6), wood)
			b.add("box", Vector3(1.8, gy.call(1.8, 0.3) + 0.46, 0.3), Vector3(0.7, 0.1, 0.5), Color(0.07, 0.06, 0.05))
			b.add("box", Vector3(1.8, gy.call(1.8, 0.3) + 0.4, -0.2), Vector3(0.8, 0.06, 0.6), wood.lightened(0.05), Vector3(-70, 0, 0))
			b.add("box", Vector3(0.4, g5 + 0.9, 0.0), Vector3(0.5, 0.02, 0.36), Color(0.9, 0.87, 0.78), Vector3(0, 12, 0))   # çizim kâğıdı
			for k in 10:
				b.add("box", Vector3(sin(k * 2.3) * 1.2, gy.call(0, 0.9) + 0.012, 0.8 + cos(k * 1.9) * 0.4), Vector3(0.1, 0.01, 0.03), wood.lightened(0.25), Vector3(0, k * 37.0, 0))
			solid.call(Vector3(0, g5 + 0.45, 0), Vector3(2.6, 0.9, 0.9))
			solid.call(Vector3(0, g5 + 1.3, -0.75), Vector3(2.8, 2.6, 0.12))
			d["npc_at"] = c + Vector3(-0.3, 0, 1.4)
			d["face"] = c + Vector3(0.3, 0, 0)
		"notice":
			# kayıp ilanı panosu: saçaklı tahta pano, üstünde yüz çizimli ilanlar, altında adak mumu
			var g6: float = gy.call(0, 0)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.1, g6 + 1.2, 0), Vector3(0.12, 2.4, 0.12), wood.darkened(0.2))
				solid.call(Vector3(sx * 1.1, g6 + 1.2, 0), Vector3(0.12, 2.4, 0.12))
			b.add("box", Vector3(0, g6 + 1.5, 0), Vector3(2.1, 1.3, 0.06), wood)
			b.add("prism", Vector3(0, g6 + 2.5, 0), Vector3(2.7, 0.4, 0.7), Color(0.3, 0.25, 0.22))
			for k in 5:
				var q6 = Vector3(-0.72 + (k % 3) * 0.72 + (0.36 if k >= 3 else 0.0), g6 + (1.78 if k < 3 else 1.24), 0.04)
				b.add("box", q6, Vector3(0.44, 0.52, 0.01), Color(0.92, 0.89, 0.78), Vector3(0, 0, sin(k * 3.1) * 5.0))
				b.add("sphere", q6 + Vector3(0, 0.08, 0.008), Vector3(0.2, 0.22, 0.01), Color(0.3, 0.27, 0.25), Vector3.ZERO, 8)
				b.add("box", q6 + Vector3(0, -0.17, 0.008), Vector3(0.3, 0.03, 0.005), Color(0.6, 0.15, 0.12))
			b.add("cyl", Vector3(0.5, g6 + 0.1, 0.5), Vector3(0.1, 0.2, 0.1), Color(0.95, 0.93, 0.85), Vector3.ZERO, 6)
			b.add("cone", Vector3(0.5, g6 + 0.26, 0.5), Vector3(0.05, 0.1, 0.05), Color(1.0, 0.7, 0.25), Vector3.ZERO, 5)
			b.add("hemi", Vector3(0.2, g6 + 0.0, 0.55), Vector3(0.22, 0.1, 0.22), Color(0.3, 0.2, 0.15), Vector3(180, 0, 0), 8)
			solid.call(Vector3(0, g6 + 1.5, 0), Vector3(2.1, 1.3, 0.1))
			d["npc_at"] = c + Vector3(-0.4, 0, 1.4)
			d["face"] = c + Vector3(-0.4, 0, 0)
		"checkpoint":
			# yolu kesen bariyer + nöbetçi kulübesi + gözetleme kulesi + bayrak
			var g1: float = gy.call(0, 0)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 3.2, gy.call(sx * 3.2, 0) + 0.6, 0), Vector3(0.22, 1.2, 0.22), wood.darkened(0.2))
				solid.call(Vector3(sx * 3.2, gy.call(sx * 3.2, 0) + 0.6, 0), Vector3(0.22, 1.2, 0.22))
			var bar = Node3D.new()
			root.add_child(bar)
			bar.position = Vector3(-3.2, g1 + 1.1, 0)
			var bb = MB.new()
			bb.add("box", Vector3(3.2, 0, 0), Vector3(6.6, 0.14, 0.14), Color(0.85, 0.82, 0.75))
			for k in 4:
				bb.add("box", Vector3(0.9 + k * 1.6, 0, 0), Vector3(0.7, 0.15, 0.15), Color(0.75, 0.2, 0.16))
			bb.add("box", Vector3(-0.5, 0, 0), Vector3(0.6, 0.3, 0.3), Color(0.35, 0.33, 0.32))
			_part(bar, bb)
			var bcs = CollisionShape3D.new()
			var bsh = BoxShape3D.new()
			bsh.size = Vector3(6.4, 1.2, 0.3)
			bcs.shape = bsh
			bcs.position = Vector3(0, g1 + 0.7, 0)
			body.add_child(bcs)
			d["bar"] = bar
			d["bar_cs"] = bcs
			# kulübe
			var hp = Vector3(5.2, gy.call(5.2, -1.5), -1.5)
			b.add("box", hp + Vector3(0, 1.1, 0), Vector3(2.2, 2.2, 2.2), Color(0.8, 0.74, 0.6))
			b.add("prism", hp + Vector3(0, 2.6, 0), Vector3(2.8, 0.9, 2.8), Color(0.3, 0.25, 0.22))
			b.add("box", hp + Vector3(-1.11, 1.3, 0), Vector3(0.04, 0.8, 1.0), Color(0.15, 0.13, 0.12))
			solid.call(hp + Vector3(0, 1.1, 0), Vector3(2.2, 2.2, 2.2))
			# kule
			var tp = Vector3(-5.6, gy.call(-5.6, -2.0), -2.0)
			for q in 4:
				b.add("cyl", tp + Vector3((q % 2 - 0.5) * 2.0, 2.8, (q / 2 - 0.5) * 2.0), Vector3(0.22, 5.6, 0.22), wood, Vector3.ZERO, 6)
			b.add("box", tp + Vector3(0, 5.6, 0), Vector3(2.8, 0.2, 2.8), wood)
			for q in 4:
				var a2 = q * PI * 0.5
				b.add("box", tp + Vector3(cos(a2) * 1.35, 6.1, sin(a2) * 1.35), Vector3(0.08, 0.8, 2.7), wood.darkened(0.1), Vector3(0, -rad_to_deg(a2), 0))
			b.add("prism", tp + Vector3(0, 7.4, 0), Vector3(3.4, 1.0, 3.4), Color(0.3, 0.22, 0.16))
			solid.call(tp + Vector3(0, 2.8, 0), Vector3(2.2, 5.6, 2.2))
			# bayrak
			b.add("cyl", Vector3(4.0, gy.call(4.0, 1.2) + 2.2, 1.2), Vector3(0.08, 4.4, 0.08), wood.darkened(0.2), Vector3.ZERO, 6)
			b.add("box", Vector3(4.7, gy.call(4.0, 1.2) + 3.9, 1.2), Vector3(1.3, 0.8, 0.03), Color(0.2, 0.35, 0.6))
			d["npc_at"] = c + Vector3(1.4, 0, 1.4)
			d["face"] = c + Vector3(1.4, 0, 8.0)
	_site_more(kind, root, b, d, c, gy, solid)
	_site_jobs(kind, root, b, d, c, gy, solid)
	_site_rogue(kind, root, b, d, c, gy, solid)
	if kind == "depot":
		_site_depot(root, b, d, c, gy, solid)
	_part(root, b)
	sites[key] = d
	return d


## Doğru parola: bariyer kalkar, yol açılır
func open_barrier() -> void:
	for key in sites:
		var d: Dictionary = sites[key]
		if d.has("bar") and is_instance_valid(d["bar"]) and not d.get("open", false):
			d["open"] = true
			var bar: Node3D = d["bar"]
			Sfx.play("pickup", bar.global_position, 0.8, 0.6)
			var tw = bar.create_tween()
			tw.tween_property(bar, "rotation:z", deg_to_rad(74.0), 1.6).set_trans(Tween.TRANS_SINE)
			if is_instance_valid(d.get("bar_cs")):
				(d["bar_cs"] as CollisionShape3D).set_deferred("disabled", true)


# ====================================================================== ipuçları (soruşturma)
func _build_clue(root: Node3D, idx: int, rng: RandomNumberGenerator, ck := "") -> void:
	var b = MB.new()
	if ck == "":
		ck = ["prints", "ash", "bandana"][idx % 3]
	if not ck in ["prints", "ash", "bandana"]:
		_build_clue2(root, b, ck, rng)
		_part(root, b)
		return
	match ["prints", "ash", "bandana"].find(ck):
		0:   # çamurlu sandal izleri: ıslak toprağa basılmış bir sıra iz
			for k in 6:
				var z = -0.9 + k * 0.36
				var x = 0.12 if k % 2 == 0 else -0.12
				b.add("sphere", Vector3(x, 0.045, z), Vector3(0.15, 0.03, 0.32), Color(0.17, 0.12, 0.08), Vector3(0, rng.randf_range(-8, 8), 0), 8)
				b.add("sphere", Vector3(x, 0.05, z - 0.11), Vector3(0.11, 0.03, 0.11), Color(0.12, 0.085, 0.06), Vector3.ZERO, 6)
			for k in 5:
				b.add("sphere", Vector3(rng.randf_range(-0.15, 0.15), 0.0, -0.8 + k * 0.4), Vector3(rng.randf_range(0.8, 1.1), 0.07, rng.randf_range(0.7, 0.9)), Color(0.36, 0.27, 0.17).darkened(rng.randf() * 0.1), Vector3.ZERO, 9)
		1:   # sönmüş ateş: kül halkası, kömürleşmiş odunlar, kemirilmiş kemik
			b.add("cyl", Vector3(0, 0.015, 0), Vector3(1.0, 0.03, 1.0), Color(0.3, 0.29, 0.28), Vector3.ZERO, 10)
			for k in 7:
				var a = TAU * k / 7.0
				b.add("sphere", Vector3(cos(a) * 0.56, 0.07, sin(a) * 0.56), Vector3(0.24, 0.16, 0.22), Color(0.45, 0.43, 0.4), Vector3.ZERO, 6)
			for k in 4:
				b.add("cyl", Vector3(cos(k * 1.6) * 0.14, 0.09, sin(k * 1.6) * 0.14), Vector3(0.09, 0.6, 0.09), Color(0.1, 0.09, 0.08), Vector3(80, k * 47, 0), 6)
			b.add("cyl", Vector3(0.75, 0.03, 0.3), Vector3(0.035, 0.26, 0.035), Color(0.92, 0.9, 0.82), Vector3(90, 40, 0), 6)
			for sd in [-1.0, 1.0]:
				b.add("sphere", Vector3(0.75 + sd * 0.085, 0.03, 0.3 - sd * 0.1), Vector3.ONE * 0.06, Color(0.92, 0.9, 0.82), Vector3.ZERO, 6)
		2:   # kırık dala takılmış yırtık bandana
			b.add("cyl", Vector3(0, 0.35, 0), Vector3(0.05, 0.7, 0.05), Color(0.36, 0.26, 0.16), Vector3(0, 0, 8), 5)
			b.add("cyl", Vector3(0.12, 0.6, 0), Vector3(0.03, 0.34, 0.03), Color(0.36, 0.26, 0.16), Vector3(0, 0, -55), 5)
			b.add("box", Vector3(0.24, 0.6, 0.0), Vector3(0.26, 0.2, 0.012), Color(0.62, 0.14, 0.12), Vector3(0, 0, -20))
			b.add("box", Vector3(0.36, 0.47, 0.01), Vector3(0.1, 0.24, 0.012), Color(0.58, 0.12, 0.1), Vector3(0, 0, 12))
			b.add("box", Vector3(0.2, 0.45, -0.01), Vector3(0.07, 0.16, 0.012), Color(0.6, 0.13, 0.11), Vector3(0, 0, -8))
	_part(root, b)


## Soruşturmaya özgü ipuçları (olayın kendi eşyası) ve S görevlerinin izleri
func _build_clue2(root: Node3D, b: MB, ck: String, rng: RandomNumberGenerator) -> void:
	var mud = Color(0.36, 0.27, 0.17)
	match ck:
		"rice":   # yırtık çuval köşesi + dökülmüş pirinç izi
			b.add("sphere", Vector3(-0.5, 0.1, 0), Vector3(0.5, 0.2, 0.36), Color(0.72, 0.62, 0.42), Vector3(0, 20, 0), 8)
			b.add("box", Vector3(-0.3, 0.06, 0.1), Vector3(0.26, 0.02, 0.2), Color(0.66, 0.56, 0.38), Vector3(0, 35, 12))
			for k in 26:
				var z = -0.1 + k * 0.07
				b.add("sphere", Vector3(-0.25 + k * 0.05 + rng.randf_range(-0.06, 0.06), 0.02, z * 0.4 + rng.randf_range(-0.07, 0.07)), Vector3(0.05, 0.02, 0.03), Color(0.97, 0.96, 0.9), Vector3(0, rng.randf() * 180.0, 0), 5)
			b.add("sphere", Vector3(-0.15, 0.03, 0.02), Vector3(0.3, 0.05, 0.22), Color(0.97, 0.96, 0.9), Vector3.ZERO, 8)
		"vial":   # devrik boş şişe, mantarı, mor tortu, kurumuş otlar
			b.add("sphere", Vector3(0.1, 0.012, 0.05), Vector3(0.7, 0.02, 0.5), Color(0.42, 0.2, 0.5), Vector3.ZERO, 10)
			b.add("cyl", Vector3(0, 0.07, 0), Vector3(0.13, 0.24, 0.13), Color(0.55, 0.75, 0.6), Vector3(90, 25, 0), 8)
			b.add("cyl", Vector3(0.07, 0.07, -0.15), Vector3(0.06, 0.1, 0.06), Color(0.55, 0.75, 0.6), Vector3(90, 25, 0), 6)
			b.add("cyl", Vector3(0.3, 0.03, -0.28), Vector3(0.06, 0.06, 0.06), Color(0.6, 0.45, 0.28), Vector3(70, 0, 0), 6)
			for k in 7:
				var a = TAU * k / 7.0
				b.add("box", Vector3(cos(a) * 0.38, 0.08, sin(a) * 0.3), Vector3(0.02, 0.2, 0.012), Color(0.5, 0.42, 0.2), Vector3(rng.randf_range(30, 60), rad_to_deg(a), 0))
		"rag":   # yağlı yanık bezler + devrik yağ testisi
			b.add("sphere", Vector3(0.25, 0.012, 0.1), Vector3(0.8, 0.02, 0.6), Color(0.12, 0.1, 0.08), Vector3.ZERO, 10)
			for k in 3:
				var q = Vector3(-0.3 + k * 0.28, 0.05, rng.randf_range(-0.2, 0.2))
				b.add("sphere", q, Vector3(0.3, 0.08, 0.24), Color(0.16, 0.13, 0.11), Vector3(0, rng.randf() * 90.0, 0), 7)
				b.add("box", q + Vector3(0.1, 0.03, 0.06), Vector3(0.16, 0.015, 0.1), Color(0.75, 0.68, 0.5), Vector3(8, rng.randf() * 90.0, 10))
				b.add("box", q + Vector3(0.02, 0.045, 0.0), Vector3(0.12, 0.012, 0.03), Color(0.85, 0.4, 0.12), Vector3(0, rng.randf() * 90.0, 0))
			b.add("sphere", Vector3(0.55, 0.14, -0.2), Vector3(0.3, 0.28, 0.28), Color(0.55, 0.36, 0.24), Vector3(0, 0, 80), 8)
			b.add("cyl", Vector3(0.38, 0.14, -0.2), Vector3(0.14, 0.1, 0.14), Color(0.5, 0.32, 0.22), Vector3(0, 0, 80), 7)
		"bag":   # yırtık yolcu çantası, saçılmış eşyalar
			b.add("sphere", Vector3(0, 0.13, 0), Vector3(0.55, 0.26, 0.4), Color(0.58, 0.48, 0.32), Vector3(0, 15, 0), 8)
			b.add("box", Vector3(0.05, 0.2, 0.0), Vector3(0.3, 0.015, 0.04), Color(0.1, 0.08, 0.07), Vector3(0, 40, 0))   # yırtık
			b.add("box", Vector3(-0.35, 0.03, 0.2), Vector3(0.6, 0.02, 0.05), Color(0.4, 0.3, 0.2), Vector3(0, -30, 0))   # kopuk askı
			b.add("hemi", Vector3(0.5, 0.0, 0.25), Vector3(0.2, 0.1, 0.2), Color(0.3, 0.2, 0.15), Vector3(180, 0, 0), 8)   # çanak
			b.add("box", Vector3(0.42, 0.02, -0.25), Vector3(0.2, 0.02, 0.06), Color(0.75, 0.62, 0.4), Vector3(0, 55, 0))   # tarak
			b.add("box", Vector3(-0.1, 0.02, 0.45), Vector3(0.24, 0.025, 0.11), Color(0.7, 0.6, 0.4), Vector3(0, -20, 0))   # hasır sandal
			b.add("box", Vector3(-0.1, 0.045, 0.45), Vector3(0.02, 0.02, 0.11), Color(0.3, 0.3, 0.6), Vector3(0, -20, 0))
			b.add("box", Vector3(0.2, 0.02, 0.5), Vector3(0.22, 0.01, 0.16), Color(0.92, 0.9, 0.8), Vector3(0, 25, 0))   # yol izni kâğıdı
		"puppet":   # kopmuş kukla kolu: eklem zorlanmış, chakra ipi kesik
			var pw = Color(0.72, 0.6, 0.42)
			b.add("cyl", Vector3(-0.2, 0.06, 0), Vector3(0.1, 0.42, 0.1), pw, Vector3(90, 70, 0), 7)
			b.add("sphere", Vector3(0.02, 0.06, 0.08), Vector3.ONE * 0.12, pw.darkened(0.2), Vector3.ZERO, 7)
			b.add("box", Vector3(0.16, 0.05, 0.13), Vector3(0.14, 0.05, 0.11), pw, Vector3(0, -20, 0))
			for k in 4:
				b.add("cyl", Vector3(0.27 + k * 0.004, 0.05, 0.12 + (k - 1.5) * 0.03), Vector3(0.022, 0.12, 0.022), pw.lightened(0.05), Vector3(90, 70 - k * 8, 0), 5)
			b.add("cyl", Vector3(-0.42, 0.06, -0.08), Vector3(0.05, 0.05, 0.05), Color(0.35, 0.33, 0.33), Vector3(90, 70, 0), 6)   # kırık mil
			for k in 5:
				b.add("box", Vector3(-0.1 + k * 0.16, 0.012, -0.3 + sin(k * 1.3) * 0.08), Vector3(0.17, 0.006, 0.012), Color(0.6, 0.85, 1.0), Vector3(0, k * 22.0 - 40.0, 0))
			for k in 6:
				b.add("box", Vector3(rng.randf_range(-0.5, 0.5), 0.01, rng.randf_range(-0.4, 0.4)), Vector3(0.06, 0.008, 0.02), pw.lightened(0.1), Vector3(0, rng.randf() * 180.0, 0))
		"clay":   # kil topakları, biri parmak izli; kumdan sararmış eldiven
			for k in 5:
				var q2 = Vector3(rng.randf_range(-0.4, 0.4), 0.06, rng.randf_range(-0.3, 0.3))
				b.add("sphere", q2, Vector3(rng.randf_range(0.14, 0.24), 0.12, rng.randf_range(0.14, 0.22)), Color(0.86, 0.84, 0.8).darkened(rng.randf() * 0.08), Vector3.ZERO, 7)
			b.add("sphere", Vector3(0, 0.1, 0), Vector3(0.3, 0.16, 0.26), Color(0.86, 0.84, 0.8), Vector3.ZERO, 8)
			for k in 4:
				b.add("sphere", Vector3(-0.06 + k * 0.04, 0.175, 0.02), Vector3(0.03, 0.02, 0.07), Color(0.6, 0.58, 0.55), Vector3.ZERO, 5)
			b.add("box", Vector3(0.5, 0.025, 0.25), Vector3(0.16, 0.04, 0.22), Color(0.8, 0.68, 0.3), Vector3(0, 30, 0))
			for k in 4:
				b.add("box", Vector3(0.44 + k * 0.035, 0.025, 0.4 + k * 0.012), Vector3(0.03, 0.035, 0.12), Color(0.8, 0.68, 0.3), Vector3(0, 30 - k * 6, 0))
		"receipt":   # taşın altına sıkışmış ıslak makbuzlar, su birikintisi
			b.add("sphere", Vector3(0.1, 0.01, 0.0), Vector3(0.9, 0.018, 0.7), Color(0.4, 0.5, 0.58), Vector3.ZERO, 10)
			for k in 4:
				var yw = rng.randf_range(-40, 40)
				var q3 = Vector3(-0.2 + k * 0.14, 0.022 + k * 0.004, rng.randf_range(-0.1, 0.1))
				b.add("box", q3, Vector3(0.2, 0.004, 0.3), Color(0.88, 0.85, 0.74).darkened(k * 0.04), Vector3(0, yw, 0))
				for j in 3:
					b.add("box", q3 + Vector3(0, 0.004, -0.08 + j * 0.07).rotated(Vector3.UP, deg_to_rad(yw)), Vector3(0.14, 0.003, 0.012), Color(0.2, 0.2, 0.3), Vector3(0, yw, 0))
				b.add("cyl", q3 + Vector3(0.05, 0.005, 0.1).rotated(Vector3.UP, deg_to_rad(yw)), Vector3(0.05, 0.003, 0.05), Color(0.7, 0.15, 0.12), Vector3.ZERO, 7)
			b.add("sphere", Vector3(-0.25, 0.08, -0.05), Vector3(0.26, 0.16, 0.22), Color(0.5, 0.5, 0.48), Vector3.ZERO, 7)
		"sandal":   # küçük çocuk sandaleti + sürüklenme izi + düşmüş fırıldak
			for sx in [-0.1, 0.1]:
				b.add("box", Vector3(sx, 0.012, 0.6), Vector3(0.05, 0.012, 2.2), mud.darkened(0.25), Vector3(0, sx * 12.0, 0))
			b.add("box", Vector3(0.2, 0.03, -0.5), Vector3(0.11, 0.03, 0.2), Color(0.8, 0.7, 0.45), Vector3(0, 35, 0))
			b.add("box", Vector3(0.2, 0.05, -0.53), Vector3(0.11, 0.025, 0.03), Color(0.8, 0.2, 0.2), Vector3(0, 35, 0))
			b.add("cyl", Vector3(-0.3, 0.02, -0.3), Vector3(0.02, 0.4, 0.02), Color(0.5, 0.38, 0.25), Vector3(90, 60, 0), 5)
			for k in 4:
				b.add("box", Vector3(-0.47, 0.03, -0.4) + Vector3(cos(k * PI * 0.5), 0, sin(k * PI * 0.5)) * 0.06, Vector3(0.1, 0.01, 0.06), [Color(0.9, 0.3, 0.3), Color(0.95, 0.85, 0.3)][k % 2], Vector3(0, -k * 90.0, 20))
		"skin":   # dev yılanın attığı gömlek: S çizen, yer yer çökmüş soluk tüp; pul halkaları, ağız kısmı yırtık
			var sc2 = Color(1.0, 0.95, 0.74)
			for k in 30:
				var t = k / 29.0
				var q4 = Vector3(sin(t * TAU) * 0.6, 0.0, -1.7 + t * 3.4)
				var yw4 = rad_to_deg(atan2(cos(t * TAU) * 0.6 * TAU / 3.4, 1.0))
				var r = 0.3 * (0.45 + 0.55 * sin(clampf(t * 1.15, 0.0, 1.0) * PI)) * (0.8 + 0.2 * sin(k * 2.3))
				b.add("sphere", q4 + Vector3(0, r * 0.45, 0), Vector3(r * 2.0, r * 1.1, 0.26), sc2.darkened(0.05 * (k % 2)), Vector3(0, yw4, 0), 8)
				if k % 2 == 0:
					b.add("box", q4 + Vector3(0, r * 0.98, 0), Vector3(r * 1.5, 0.02, 0.04), Color(0.7, 0.58, 0.36), Vector3(0, yw4, 0))
			for sx in [-1.0, 1.0]:   # yırtık ağız: iki yana açılmış ince zar
				b.add("box", Vector3(sx * 0.22, 0.03, 1.85), Vector3(0.3, 0.012, 0.5), sc2.lightened(0.06), Vector3(0, sx * 28.0, sx * -10.0))
		"needle":   # parçalanmış kapı tahtasına saplı zehirli senbonlar
			b.add("box", Vector3(0, 0.04, 0), Vector3(0.9, 0.06, 0.4), Color(0.45, 0.33, 0.2), Vector3(0, 12, 4))
			b.add("box", Vector3(0.5, 0.03, 0.3), Vector3(0.4, 0.05, 0.14), Color(0.42, 0.3, 0.18), Vector3(0, -30, 0))
			for k in 6:
				var q5 = Vector3(-0.32 + k * 0.13, 0.2, rng.randf_range(-0.1, 0.1))
				var tilt = Vector3(rng.randf_range(-28, 28), 0, rng.randf_range(-28, 28))
				b.add("cyl", q5, Vector3(0.014, 0.34, 0.014), Color(0.78, 0.8, 0.84), tilt, 4)
				b.add("sphere", q5 - Vector3(0, 0.13, 0), Vector3(0.05, 0.03, 0.05), Color(0.5, 0.25, 0.6), Vector3.ZERO, 5)
	if not ck in ["sandal", "skin"]:
		b.add("sphere", Vector3(0, -0.02, 0), Vector3(1.2, 0.05, 1.0), mud.lightened(0.05), Vector3.ZERO, 9)


## Soruşturmada aranan eşyanın ipucu türü
static func clue_kind(item: String) -> String:
	var n = item.to_lower()
	for pair in [["pirinç", "rice"], ["şişe", "vial"], ["zehir", "vial"], ["bez", "rag"], ["çanta", "bag"], ["kukla", "puppet"], ["kil", "clay"], ["makbuz", "receipt"]]:
		if String(pair[0]) in n:
			return String(pair[1])
	return "bandana"


## İncelenince oyuncunun çıkardığı sonuç
static func clue_find(ck: String, n := 3) -> String:
	return String({
		"prints": "Ayak izleri... %d kişi, yükleri ağır. Köyden uzaklaşıyorlar." % n,
		"ash": "Sönmüş ateş, kül daha ılık. Kampları uzakta değil.",
		"bandana": "Dala takılmış yırtık bir bandana. Bir çetenin işareti.",
		"rice": "Yırtık çuvaldan dökülen pirinç... iz buradan dağa doğru uzanıyor.",
		"vial": "Boş şişe, dibinde mor tortu. Çevresindeki ot bile kurumuş: zehir bu.",
		"rag": "Yağa bulanmış yanık bezler, devrik bir yağ testisi. Bu yangın kaza değil.",
		"bag": "Yırtık bir yolcu çantası; eşyalar saçılmış, para kesesi yok. Sahibi kendi isteğiyle gitmemiş.",
		"puppet": "Kopmuş bir kukla kolu... eklemi zorlanmış, chakra ipi kesilmiş.",
		"clay": "Kil topakları ve kumdan sararmış bir eldiven. Fıçıları kurcalayan buradan geçmiş.",
		"receipt": "Yağmurda ıslanmış makbuzlar: çalıntı malın kime satıldığı yazıyor.",
		"sandal": "Küçük bir sandalet ve sürüklenme izi... Çocuk bayıltılıp taşınmış.",
		"skin": "Yılan gömleği. Ama bu boyda bir yılan... sıradan bir hayvan değil, çağrılmış bir canavar.",
		"needle": "Senbonlar, uçları mor. Kukla mekanizmasından fırlatılmış zehirli iğneler.",
	}.get(ck, "Bir iz..."))


static func stone_c() -> Color:
	return Color(0.58, 0.56, 0.52)


## İpucunu incele: çök, eliyle yokla, düşün; bulduğunu söyler
func _act_examine(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	await _stand_at(w, 0.75)
	_pose(pl, "examine", {"sit": "seiza", "anim": "idle", "at": w.global_position + Vector3.UP * (0.45 if String(it.get("ck", ["prints", "ash", "bandana"][int(it.get("clue", 0)) % 3])) == "bandana" else 0.0), "lift": 0.0})
	await _wait(1.3)
	Combat.popup_text(pl.global_position + Vector3.UP * 1.6, String(it.get("find", "Bir iz...")), Color(0.85, 0.95, 1.0))
	Sfx.play("pickup", w.global_position, 0.5, 1.5)
	await _wait(1.5)


# ====================================================================== ganimet (çalınan mallar)
func _build_loot(root: Node3D) -> void:
	var b = MB.new()
	b.add("sphere", Vector3(0, 0.22, 0), Vector3(0.6, 0.48, 0.52), Color(0.72, 0.62, 0.42), Vector3.ZERO, 10)
	b.add("sphere", Vector3(0, 0.5, 0), Vector3(0.2, 0.16, 0.2), Color(0.68, 0.58, 0.4), Vector3.ZERO, 8)
	b.add("cyl", Vector3(0, 0.44, 0), Vector3(0.21, 0.03, 0.21), Color(0.4, 0.3, 0.2), Vector3.ZERO, 8)
	var top = _part(root, b)
	top.name = "top"
	var c2 = MB.new()
	c2.add("box", Vector3(0.55, 0.14, 0.1), Vector3(0.42, 0.28, 0.3), Color(0.25, 0.2, 0.16))
	c2.add("box", Vector3(0.55, 0.29, 0.1), Vector3(0.44, 0.03, 0.32), Color(0.5, 0.42, 0.2))
	_part(root, c2)


## Çuvalı omuzla: çök, kavra, sırtına at (teslim edene kadar sırtında)
func _act_sack(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	var top: Node3D = w.get_node("top")
	await _stand_at(w, 0.6)
	_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": w.global_position + Vector3.UP * 0.2, "lift": 0.0})
	await _wait(0.5)
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", w.global_position, 0.8, 0.7)
	var keep = top.global_transform
	w.remove_child(top)
	add_child(top)
	top.top_level = true
	top.global_transform = keep
	var t := 0.0
	while t < 0.5:
		t += get_process_delta_time()
		top.global_position = top.global_position.lerp(_held(pl) - Vector3.UP * 0.2, 0.3)
		await get_tree().process_frame
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	var from = top.global_position
	rider_off = Vector3(0.0, 1.05, -0.3)
	t = 0.0
	while t < 0.4:
		t += get_process_delta_time()
		var sc: float = pl.model.age_scale
		var tgt = pl.global_position + Vector3.UP * rider_off.y * sc + _fd(pl) * rider_off.z * sc
		top.global_position = from.lerp(tgt, smoothstep(0.0, 0.4, t)) + Vector3.UP * sin(t / 0.4 * PI) * 0.25
		await get_tree().process_frame
	top.scale = Vector3.ONE * 0.8
	rider = top
	rider_kind = "sack"
	Missions.pickups.append(top)


# ====================================================================== eskort: öküz arabası
## Tüccarın arabası: öküz tüccarın ardından yürür, araba öküzün ardından (tüccarın geçtiği izi izler)
func cart_begin(npc: Node3D) -> void:
	if cart_d.get("npc") == npc and is_instance_valid(cart_d.get("ox")):
		return
	if is_instance_valid(cart_d.get("ox")) and is_instance_valid(cart_d.get("cart")):
		# tüccar yeniden yerleştirildi: aynı araba yeni yerine gelir
		var bk = -_fd(npc)
		cart_d["npc"] = npc
		cart_d["trail"] = [npc.global_position + bk * 8.0, npc.global_position + bk * 4.0, npc.global_position]
		_cart_place(0.0, true)
		return
	var od: Dictionary = TownAnimals.ox()
	var ox: Node3D = od["root"]
	get_tree().current_scene.add_child(ox)
	var cart = MeshInstance3D.new()
	var cb = MB.new()
	var wood = Color(0.52, 0.38, 0.24)
	cb.add("box", Vector3(0, 1.1, 0), Vector3(2.0, 0.25, 3.2), wood)
	for sx in [-1.0, 1.0]:
		cb.add("box", Vector3(sx * 0.97, 1.45, 0), Vector3(0.07, 0.5, 3.2), wood.darkened(0.12))
		cb.add("cyl", Vector3(1.05 * sx, 0.7, 0), Vector3(1.4, 0.15, 1.4), wood.darkened(0.3), Vector3(0, 0, 90), 10)
		cb.add("cyl", Vector3(1.14 * sx, 0.7, 0), Vector3(0.3, 0.06, 0.3), Color(0.3, 0.3, 0.32), Vector3(0, 0, 90), 8)
	cb.add("box", Vector3(0, 1.45, 1.57), Vector3(2.0, 0.5, 0.07), wood.darkened(0.12))
	cb.add("box", Vector3(0, 0.95, -2.3), Vector3(0.12, 0.12, 1.8), wood)
	# yük: sandıklar, çuvallar, testi, üstü yarı örtülü
	cb.add("box", Vector3(-0.42, 1.52, 0.9), Vector3(0.8, 0.6, 0.8), Color(0.6, 0.45, 0.28))
	cb.add("box", Vector3(0.45, 1.47, 0.95), Vector3(0.75, 0.5, 0.75), Color(0.56, 0.42, 0.26), Vector3(0, 12, 0))
	cb.add("box", Vector3(-0.1, 2.02, 0.92), Vector3(0.7, 0.42, 0.7), Color(0.63, 0.48, 0.3), Vector3(0, -15, 0))
	for k in 3:
		cb.add("sphere", Vector3(-0.5 + k * 0.5, 1.5, -0.2), Vector3(0.56, 0.44, 0.5), Color(0.75, 0.68, 0.5).darkened(0.05 * k), Vector3.ZERO, 8)
	cb.add("sphere", Vector3(0.0, 1.85, -0.25), Vector3(0.5, 0.4, 0.46), Color(0.72, 0.64, 0.46), Vector3.ZERO, 8)
	cb.add("cyl", Vector3(0.6, 1.5, -1.1), Vector3(0.4, 0.55, 0.4), Color(0.6, 0.38, 0.26), Vector3.ZERO, 9)
	cb.add("box", Vector3(0, 2.3, 0.9), Vector3(1.9, 0.04, 1.2), Color(0.3, 0.42, 0.55), Vector3(4, 0, 3))
	cart.mesh = cb.build(mat)
	get_tree().current_scene.add_child(cart)
	_own(ox, true)
	_own(cart, true)
	var back = -_fd(npc)
	ox.global_position = npc.global_position + back * 2.4
	cart.global_position = npc.global_position + back * 6.0
	cart_d = {"npc": npc, "ox": ox, "cart": cart, "legs": od["legs"], "trail": [npc.global_position + back * 8.0, npc.global_position + back * 4.0, npc.global_position], "ph": 0.0}
	_cart_place(0.0, true)


func _trail_at(trail: Array, back: float) -> Array:
	# izin sonundan (tüccar) geriye doğru "back" metre: [konum, yön]
	var left = back
	for i in range(trail.size() - 1, 0, -1):
		var a: Vector3 = trail[i]
		var b: Vector3 = trail[i - 1]
		var d = a.distance_to(b)
		if left <= d:
			var p = a.lerp(b, left / maxf(d, 0.001))
			return [p, (a - b).normalized()]
		left -= d
	var a0: Vector3 = trail[0]
	var dir = ((trail[1] as Vector3) - a0).normalized() if trail.size() > 1 else Vector3.FORWARD
	return [a0 - dir * left, dir]


func _cart_place(moved: float, snap := false) -> void:
	var ox: Node3D = cart_d["ox"]
	var cart: Node3D = cart_d["cart"]
	var tr: Array = cart_d["trail"]
	var o = _trail_at(tr, 2.4)
	var cpt = _trail_at(tr, 6.0)
	for pair in [[ox, o], [cart, cpt]]:
		var n: Node3D = pair[0]
		var p: Vector3 = pair[1][0]
		var dir: Vector3 = pair[1][1]
		p.y = Game.ground_height(p.x, p.z)
		n.global_position = p if snap else n.global_position.lerp(p, 0.5)
		if Vector2(dir.x, dir.z).length() > 0.01:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-dir.x, -dir.z), 1.0 if snap else 0.15)
	cart_d["ph"] = float(cart_d["ph"]) + moved * 2.6
	var legs: Array = cart_d["legs"]
	for i in legs.size():
		(legs[i] as Node3D).rotation.x = sin(float(cart_d["ph"]) + (PI if i in [1, 2] else 0.0)) * (0.4 if moved > 0.0005 else 0.0)


func _cart_tick(_dt: float) -> void:
	if cart_d.is_empty():
		return
	var npc = cart_d["npc"]
	if not is_instance_valid(cart_d["ox"]) or not is_instance_valid(cart_d["cart"]):
		cart_d = {}
		return
	if not is_instance_valid(npc):
		return   # tüccar yeniden yerleştiriliyor; araba bekler
	var tr: Array = cart_d["trail"]
	var last: Vector3 = tr[tr.size() - 1]
	var d = Vector2(npc.global_position.x - last.x, npc.global_position.z - last.z).length()
	var moved := 0.0
	if d > 0.35:
		tr.append(npc.global_position)
		moved = d
		if tr.size() > 60:
			tr.pop_front()
	_cart_place(moved)


## Pusuda tüccar siner (eller başında, çömelir)
func cower(npc: Node3D, on: bool) -> void:
	if not is_instance_valid(npc):
		return
	var has = st.has(npc) and String(st[npc]["k"]) == "cower"
	if on and not has:
		npc.hold_anim = "crouch"
		_pose(npc, "cower", {})
		_say(npc, ["Hiii! Haydutlar!", "Malıma dokunmayın!", "Ninja! Bir şey yap!"].pick_random(), 2.6)
	elif not on and has:
		npc.hold_anim = ""
		_clear_pose(npc)


# ====================================================================== iz süren ninken
func dog_begin(prints: Array) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var od: Dictionary = TownAnimals.dog(rng)
	var dog: Node3D = od["root"]
	get_tree().current_scene.add_child(dog)
	_own(dog)
	var p0: Vector3 = prints[0]
	dog.global_position = p0
	dog_d = {"dog": dog, "legs": od["legs"], "tail": od.get("tail"), "i": 0, "t": 0.0, "ph": 0.0, "bark": 3.0, "prints": prints}


func _dog_tick(dt: float) -> void:
	if dog_d.is_empty():
		return
	var dog = dog_d["dog"]
	if not is_instance_valid(dog) or Missions._cur().get("kind", "") != "track":
		dog_d = {}
		return
	var prints: Array = dog_d["prints"]
	var pl = Game.player
	var idx = int(Missions.st.get("idx", 0))
	var want = mini(idx + 3, prints.size() - 1)   # oyuncunun ~20 m önünde
	var i = int(dog_d["i"])
	var moving = false
	if i < want:
		var tgt: Vector3 = prints[i + 1]
		var to = tgt - dog.global_position
		to.y = 0
		var spd = 8.5 if want - i > 2 else 5.0
		if to.length() < 0.5:
			dog_d["i"] = i + 1
		else:
			dog.global_position += to.normalized() * minf(spd * dt, to.length())
			dog.rotation.y = lerp_angle(dog.rotation.y, atan2(-to.x, -to.z), minf(1.0, dt * 9.0))
			dog.rotation.x = lerpf(dog.rotation.x, 0.0, minf(1.0, dt * 8.0))
			moving = true
			dog_d["ph"] = float(dog_d["ph"]) + spd * dt * 2.4
	dog.global_position.y = Game.ground_height(dog.global_position.x, dog.global_position.z)
	var legs: Array = dog_d["legs"]
	for k in legs.size():
		(legs[k] as Node3D).rotation.x = sin(float(dog_d["ph"]) + (PI if k in [1, 2] else 0.0)) * (0.6 if moving else 0.0)
	if is_instance_valid(dog_d.get("tail")):
		(dog_d["tail"] as Node3D).rotation.z = sin(Time.get_ticks_msec() * 0.012) * 0.4
	if not moving:
		# bekliyor: burnu yerde koklar; oyuncu geride kalırsa dönüp havlar
		dog_d["t"] = float(dog_d["t"]) + dt
		dog_d["bark"] = float(dog_d["bark"]) - dt
		var far = dog.global_position.distance_to(pl.global_position) > 16.0
		if far and float(dog_d["bark"]) <= 0.0:
			dog_d["bark"] = 4.5
			var tp = pl.global_position - dog.global_position
			dog.rotation.y = atan2(-tp.x, -tp.z)
			dog.rotation.x = -0.15
			Combat.popup_text(dog.global_position + Vector3.UP * 1.2, "Hav! Hav!", Color(1.0, 0.95, 0.8))
			Sfx.play("punch", dog.global_position, 0.3, 1.8)
		elif float(dog_d["bark"]) < 3.6:
			dog.rotation.x = lerpf(dog.rotation.x, 0.3, minf(1.0, dt * 5.0))   # burun yere
			dog.rotation.y += sin(float(dog_d["t"]) * 2.4) * dt * 0.8
	else:
		dog_d["t"] = 0.0


# ====================================================================== alınacak eşya (şifre kitabı, parşömen)
func _book_parts(b: MB, at: Vector3) -> void:
	b.add("box", at, Vector3(0.24, 0.06, 0.32), Color(0.16, 0.2, 0.36))
	b.add("box", at + Vector3(0.012, 0, 0), Vector3(0.23, 0.045, 0.3), Color(0.93, 0.9, 0.8))
	b.add("box", at + Vector3(0, 0.032, 0), Vector3(0.24, 0.006, 0.32), Color(0.16, 0.2, 0.36))
	b.add("box", at + Vector3(0, 0.037, 0), Vector3(0.1, 0.004, 0.16), Color(0.85, 0.75, 0.4))
	b.add("box", at + Vector3(0, 0.0, 0.0), Vector3(0.245, 0.062, 0.04), Color(0.7, 0.16, 0.14))


func _scroll_parts(b: MB, at: Vector3) -> void:
	b.add("cyl", at, Vector3(0.15, 0.5, 0.15), Color(0.3, 0.5, 0.36), Vector3(0, 0, 90), 10)
	b.add("cyl", at, Vector3(0.155, 0.12, 0.155), Color(0.9, 0.86, 0.72), Vector3(0, 0, 90), 10)
	b.add("cyl", at, Vector3(0.16, 0.035, 0.16), Color(0.75, 0.16, 0.14), Vector3(0, 0, 90), 10)
	for sd in [-1.0, 1.0]:
		b.add("cyl", at + Vector3(sd * 0.27, 0, 0), Vector3(0.18, 0.045, 0.18), Color(0.82, 0.68, 0.3), Vector3(0, 0, 90), 10)
		b.add("cyl", at + Vector3(sd * 0.31, 0, 0), Vector3(0.07, 0.05, 0.07), Color(0.3, 0.2, 0.14), Vector3(0, 0, 90), 8)


## Kaçakçıların masası: sandık masa, fener, üstünde şifre kitabı
func _build_book(root: Node3D) -> void:
	var b = MB.new()
	var wood = Color(0.46, 0.34, 0.22)
	b.add("box", Vector3(0, 0.26, 0), Vector3(0.9, 0.52, 0.62), wood)
	for sx in [-1.0, 1.0]:
		b.add("box", Vector3(sx * 0.42, 0.26, 0), Vector3(0.07, 0.54, 0.64), wood.darkened(0.2))
	b.add("box", Vector3(0, 0.53, 0), Vector3(0.94, 0.03, 0.66), wood.lightened(0.08))
	# fener + açık harita + mürekkep
	b.add("cyl", Vector3(0.3, 0.63, -0.15), Vector3(0.13, 0.18, 0.13), Color(0.95, 0.8, 0.4), Vector3.ZERO, 6)
	b.add("cyl", Vector3(0.3, 0.74, -0.15), Vector3(0.15, 0.03, 0.15), Color(0.2, 0.18, 0.17), Vector3.ZERO, 6)
	b.add("cyl", Vector3(0.3, 0.55, -0.15), Vector3(0.15, 0.03, 0.15), Color(0.2, 0.18, 0.17), Vector3.ZERO, 6)
	b.add("box", Vector3(-0.2, 0.548, -0.12), Vector3(0.4, 0.004, 0.3), Color(0.88, 0.82, 0.66), Vector3(0, 14, 0))
	b.add("cyl", Vector3(0.05, 0.57, 0.2), Vector3(0.05, 0.06, 0.05), Color(0.1, 0.1, 0.12), Vector3.ZERO, 6)
	_part(root, b)
	var tb = MB.new()
	_book_parts(tb, Vector3.ZERO)
	var top = _part(root, tb, Vector3(-0.18, 0.575, 0.12))
	top.name = "top"
	top.rotation.y = 0.3
	var body = StaticBody3D.new()
	root.add_child(body)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(0.9, 0.55, 0.62)
	cs.shape = sh
	cs.position = Vector3(0, 0.27, 0)
	body.add_child(cs)


func _build_scroll(root: Node3D) -> void:
	var tb = MB.new()
	_scroll_parts(tb, Vector3.ZERO)
	var top = _part(root, tb, Vector3(0, 0.08, 0))
	top.name = "top"


## Eşyayı al: sin, uzan, kavra, yeleğinin içine sok
func _act_take(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	var top: Node3D = w.get_node("top")
	var tp = top.global_position
	await _stand_at(w, 0.72 if String(it["work"]) == "book" else float(it.get("reach", 0.6)))
	_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": tp, "lift": 0.0})
	await _wait(0.45)
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", tp, 0.7, 1.1)
	var keep = top.global_transform
	w.remove_child(top)
	add_child(top)
	top.top_level = true
	top.global_transform = keep
	var t := 0.0
	while t < 0.5:
		t += get_process_delta_time()
		top.global_position = top.global_position.lerp(_held(pl), 0.3)
		await get_tree().process_frame
	# yeleğin içine
	var from = top.global_position
	t = 0.0
	while t < 0.4:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.4, t)
		top.global_position = from.lerp(pl.global_position + Vector3.UP * 0.75 * pl.model.age_scale + _fd(pl) * 0.08, k)
		top.scale = Vector3.ONE * (1.0 - 0.75 * k)
		await get_tree().process_frame
	top.queue_free()
	await _wait(0.15)


# ====================================================================== sabotaj: ikmal sandıkları + patlayıcı mühür
func _build_crates(root: Node3D, rng: RandomNumberGenerator) -> void:
	var b = MB.new()
	var wood = Color(0.5, 0.38, 0.24)
	var crate = func(at: Vector3, sz: float, yaw: float, col: Color) -> void:
		b.add("box", at, Vector3(sz, sz, sz), col, Vector3(0, yaw, 0))
		for e in [-1.0, 1.0]:
			b.add("box", at + Vector3(0, e * sz * 0.44, 0), Vector3(sz * 1.04, sz * 0.1, sz * 1.04), col.darkened(0.22), Vector3(0, yaw, 0))
	crate.call(Vector3(0, 0.45, 0), 0.9, 0.0, wood)
	crate.call(Vector3(0.95, 0.4, -0.1), 0.8, 12.0, wood.lightened(0.06))
	crate.call(Vector3(0.4, 1.22, -0.05), 0.7, -9.0, wood.darkened(0.05))
	b.add("cyl", Vector3(-0.85, 0.5, 0.05), Vector3(0.7, 1.0, 0.7), Color(0.44, 0.3, 0.2), Vector3.ZERO, 10)
	for h in [0.2, 0.8]:
		b.add("cyl", Vector3(-0.85, h, 0.05), Vector3(0.73, 0.06, 0.73), Color(0.25, 0.25, 0.27), Vector3.ZERO, 10)
	# çuval + üstü yarım örtü
	b.add("sphere", Vector3(1.0, 0.98, -0.1), Vector3(0.6, 0.4, 0.5), Color(0.74, 0.66, 0.48), Vector3.ZERO, 8)
	b.add("box", Vector3(0.4, 1.6, -0.25), Vector3(1.0, 0.03, 0.6), Color(0.32, 0.36, 0.28), Vector3(-12, 0, 4))
	var body = _part(root, b)
	body.name = "body"
	var sb = StaticBody3D.new()
	sb.name = "col"
	root.add_child(sb)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(2.5, 1.5, 0.9)
	cs.shape = sh
	cs.position = Vector3(0.05, 0.75, 0)
	sb.add_child(cs)


func _tag_mesh() -> MeshInstance3D:
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(0.16, 0.34, 0.008), Color(0.93, 0.88, 0.72))
	b.add("box", Vector3(0, 0.0, 0.005), Vector3(0.12, 0.3, 0.004), Color(0.93, 0.88, 0.72).darkened(0.08))
	# mühür yazısı: ortada daire + üst alt çizgiler
	b.add("cyl", Vector3(0, 0.0, 0.008), Vector3(0.09, 0.004, 0.09), Color(0.8, 0.14, 0.1), Vector3(90, 0, 0), 8)
	b.add("cyl", Vector3(0, 0.0, 0.01), Vector3(0.05, 0.004, 0.05), Color(0.93, 0.88, 0.72), Vector3(90, 0, 0), 8)
	for y in [-0.12, -0.09, 0.09, 0.12]:
		b.add("box", Vector3(0, y, 0.008), Vector3(0.09, 0.012, 0.004), Color(0.8, 0.14, 0.1))
	var m = MeshInstance3D.new()
	m.mesh = b.build(mat)
	return m


## Patlayıcı mührü sandığa yapıştır: kese → avuç → sandığın yüzü
func _act_tag(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	var front = w.global_transform.basis.z.normalized()
	var at = w.global_position + front * 0.46 + Vector3.UP * 0.62
	await _stand_at(w, 0.9, front)
	_look_at(pl, w.global_position)
	_pose(pl, "slap", {"anim": "idle", "at": at})
	var tag = _tag_mesh()
	add_child(tag)
	tag.top_level = true
	var t := 0.0
	while t < 0.42:   # mühür avuçta, kolla birlikte gelir
		t += get_process_delta_time()
		var k = smoothstep(0.28, 0.42, t)
		var rest = pl.global_position + _fd(pl) * 0.15 + _fd(pl).cross(Vector3.UP).normalized() * 0.2 + Vector3.UP * 1.0 * pl.model.age_scale
		tag.global_position = rest.lerp(at, k)
		tag.global_transform.basis = w.global_transform.basis
		await get_tree().process_frame
	remove_child(tag)
	w.add_child(tag)
	tag.top_level = false
	tag.position = Vector3(0, 0.62, 0.46)
	tag.rotation = Vector3.ZERO
	Sfx.play("seal", at, 1.0)
	FX.burst(at, {"amount": 8, "life": 0.35, "size": 0.06, "vmin": 0.5, "vmax": 1.6, "gravity": Vector3.ZERO, "colors": [Color(1.0, 0.5, 0.2, 1), Color(1.0, 0.3, 0.1, 0)]})
	await _wait(0.75)
	tagged.append(w)


## Mühürler ateşlendi: yığınlar sırayla patlar, yerlerinde yanık enkaz kalır
func blow() -> void:
	var list = tagged.filter(func(x): return is_instance_valid(x))
	tagged = []
	for w in list:
		if not is_instance_valid(w):
			continue
		var p: Vector3 = w.global_position
		FX.explosion(p + Vector3.UP * 0.7, 2.2)
		Sfx.play("boom", p, 0.9)
		FX.burst(p + Vector3.UP * 0.8, {"amount": 14, "life": 1.1, "size": 0.22, "vmin": 4.0, "vmax": 9.0, "gravity": Vector3(0, -14, 0), "colors": [Color(0.4, 0.28, 0.16, 1), Color(0.15, 0.1, 0.07, 1)]})
		for ch in w.get_children():
			ch.queue_free()
		var b = MB.new()
		var rng = RandomNumberGenerator.new()
		rng.seed = hash(p)
		b.add("cyl", Vector3(0, 0.02, 0), Vector3(4.2, 0.03, 3.6), Color(0.09, 0.08, 0.07), Vector3.ZERO, 12)
		for k in 11:
			var a = rng.randf() * TAU
			var r = rng.randf_range(0.2, 1.7)
			b.add("box", Vector3(cos(a) * r, rng.randf_range(0.06, 0.3), sin(a) * r), Vector3(rng.randf_range(0.5, 1.0), 0.07, 0.16), Color(0.14, 0.11, 0.09).lerp(Color(0.34, 0.24, 0.15), rng.randf() * 0.5), Vector3(rng.randf_range(-30, 30), rng.randf() * 360.0, rng.randf_range(-25, 25)))
		b.add("cyl", Vector3(-0.6, 0.18, 0.2), Vector3(0.66, 0.36, 0.66), Color(0.13, 0.1, 0.09), Vector3(14, 0, 8), 9)
		_part(w, b)
		await _wait(0.28)


# ====================================================================== rehine: kazığa bağlı
func bind(npc: Node3D, flat := false) -> void:
	if not is_instance_valid(npc) or bound_d.has(npc):
		return
	var fd = _fd(npc)
	var post = Node3D.new()
	get_tree().current_scene.add_child(post)
	_own(post, true)
	var pp = npc.global_position - fd * 0.3
	pp.y = npc.global_position.y if flat else Game.ground_height(pp.x, pp.z)   # iç mekânda zemin = odanın tabanı
	post.global_position = pp
	post.rotation.y = npc.facing
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.85, 0), Vector3(0.17, 1.7, 0.17), Color(0.4, 0.3, 0.2), Vector3.ZERO, 7)
	b.add("cone", Vector3(0, 1.78, 0), Vector3(0.17, 0.16, 0.17), Color(0.5, 0.4, 0.28), Vector3.ZERO, 7)
	_part(post, b)
	# ip: gövdeyi ve kazığı saran üç kat
	var rb = MB.new()
	var rc = Color(0.72, 0.62, 0.42)
	for y in [0.5, 0.58, 0.66]:
		rb.add("box", Vector3(0, y, -0.52), Vector3(0.44, 0.035, 0.035), rc)
		rb.add("box", Vector3(0, y, 0.1), Vector3(0.24, 0.035, 0.035), rc)
		for sx in [-1.0, 1.0]:
			rb.add("box", Vector3(sx * 0.17, y, -0.21), Vector3(0.035, 0.035, 0.66), rc, Vector3(0, sx * 9.0, 0))
	var rope = _part(post, rb)
	if npc.get("model") != null and npc.model.age_scale < 0.9:
		rope.scale = Vector3.ONE * npc.model.age_scale   # çocuk: ip gövdesine göre
	bound_d[npc] = {"post": post, "rope": rope}
	if npc is QuestNPC:
		npc.set_physics_process(false)
	_pose(npc, "bound", {"sit": "seiza", "anim": "idle", "lift": 0.0})


## İpleri kes: yanına çök, kunai ile ipi kes; rehine ayağa kalkar
func untie(npc: Node3D) -> void:
	if not is_instance_valid(npc) or not bound_d.has(npc):
		return
	var pl = Game.player
	var d: Dictionary = bound_d[npc]
	bound_d.erase(npc)
	busy_run = true
	_lock(15.0)
	var side = _fd(npc).cross(Vector3.UP).normalized()
	if (pl.global_position - npc.global_position).dot(side) < 0.0:
		side = -side
	var sp = npc.global_position + side * 0.75 - _fd(npc) * 0.15
	sp.y = pl.global_position.y
	await _go_w(pl, sp, 2.4, false, 0.12)
	var cut_at = npc.global_position - _fd(npc) * 0.2 + Vector3.UP * 0.3
	_look_at(pl, cut_at)
	_pose(pl, "cut", {"sit": "seiza", "anim": "idle", "at": cut_at, "lift": 0.0})
	await _wait(1.05)
	Sfx.play("slash", cut_at, 0.7, 1.4)
	if is_instance_valid(d.get("rope")):
		var rope: Node3D = d["rope"]
		var tw = rope.create_tween()
		tw.tween_property(rope, "position:y", -0.5, 0.3)
		tw.tween_callback(rope.queue_free)
	FX.burst(cut_at, {"amount": 6, "life": 0.4, "size": 0.05, "vmin": 0.5, "vmax": 1.5, "gravity": Vector3(0, -6, 0), "colors": [Color(0.72, 0.62, 0.42, 1), Color(0.72, 0.62, 0.42, 0)]})
	await _wait(0.5)
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	if is_instance_valid(npc):
		_clear_pose(npc)
		if npc is QuestNPC:
			npc.mode = "idle"
			npc.set_physics_process(true)
		_look_at(npc, pl.global_position)
	await _wait(0.5)
	_release_player()
	busy_run = false


## Kavuşma: kurtarılan kişi yakınına koşar, sarılırlar
func reunite(kid: Node3D, parent: Node3D, lines: Array = []) -> void:
	if not is_instance_valid(kid) or not is_instance_valid(parent):
		return
	busy_run = true
	_lock(15.0)
	stop_busy(parent)
	for n in [kid, parent]:
		if n is QuestNPC:
			n.mode = "idle"
			n.set_physics_process(false)
	var dir = kid.global_position - parent.global_position
	dir.y = 0
	if dir.length() < 0.1:
		dir = _fd(parent)
	_look_at(parent, kid.global_position)
	_say(kid, String(lines[0]) if lines.size() > 0 else "Baba!", 1.6)
	await _go_w(kid, parent.global_position + dir.normalized() * 0.42, 5.0, true, 0.08)
	_look_at(kid, parent.global_position)
	_look_at(parent, kid.global_position)
	_pose(kid, "embrace", {"anim": "idle", "with": parent})
	if kid.model.age_scale < parent.model.age_scale * 0.85:
		_pose(parent, "embrace", {"anim": "idle", "with": kid, "sit": "seiza", "lift": 0.0})   # çocuğa diz çöküp sarılır
	else:
		_pose(parent, "embrace", {"anim": "idle", "with": kid})
	await _wait(1.0)
	_say(parent, String(lines[1]) if lines.size() > 1 else "Kızım! Sağsın, şükürler olsun...", 2.4)
	await _wait(2.2)
	if is_instance_valid(kid) and is_instance_valid(parent):
		# kız babasının yanına geçer (ödeme sahnesine yer açılır)
		_clear_pose(kid)
		var sd = dir.normalized().cross(Vector3.UP)
		await _go_w(kid, parent.global_position + sd * 0.9 - dir.normalized() * 0.1, 2.2, true, 0.1)
		_look_at(kid, parent.global_position + dir.normalized() * 2.0)
	for n in [kid, parent]:
		if is_instance_valid(n):
			_clear_pose(n)
			n.home = n.global_position
			if n is QuestNPC:
				n.set_physics_process(true)
	_release_player()
	busy_run = false


# ====================================================================== savunma: barikat + saklanan köylüler
func barricade(c: Vector3) -> Dictionary:
	var key = "%s:barricade" % String(Missions.active().get("id", ""))
	if sites.has(key) and is_instance_valid(sites[key].get("root")):
		return sites[key]
	c.y = Game.ground_height(c.x, c.z)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = c
	_own(root, true)
	var space = Game.world.get_world_3d().direct_space_state if Game.world and Game.world.is_inside_tree() else null
	var wood = Color(0.44, 0.32, 0.2)
	var a0 = randf() * TAU
	for i in 5:
		var a = a0 + TAU * i / 5.0
		var q = c + Vector3(cos(a), 0, sin(a)) * 7.5
		if not Missions._og_ok(q, space):
			continue
		q.y = Game.ground_height(q.x, q.z)
		var piece = StaticBody3D.new()
		root.add_child(piece)
		piece.global_position = q
		piece.rotation.y = -a + PI * 0.5   # kütük çembere teğet
		var b = MB.new()
		b.add("cyl", Vector3(0, 0.62, 0), Vector3(0.2, 3.0, 0.2), wood, Vector3(0, 0, 90), 7)
		for k in 6:
			var x = -1.25 + k * 0.5
			for sd in [-1.0, 1.0]:
				b.add("cyl", Vector3(x + sd * 0.06, 0.62, 0), Vector3(0.1, 1.9, 0.1), wood.lightened(0.07), Vector3(sd * 42.0, 0, 0), 6)
				b.add("cone", Vector3(x + sd * 0.06, 0.62 + 0.74, sd * 0.67), Vector3(0.1, 0.22, 0.1), Color(0.8, 0.72, 0.55), Vector3(sd * 42.0, 0, 0), 6)
		_part(piece, b)
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = Vector3(3.0, 1.3, 0.9)
		cs.shape = sh
		cs.position = Vector3(0, 0.65, 0)
		piece.add_child(cs)
	# ortada: saman balyaları + devrilmiş el arabası (köylüler arkasına siner)
	var hb = MB.new()
	for k in 3:
		var hx = -1.1 + k * 1.1
		hb.add("box", Vector3(hx, Game.ground_height(c.x + hx, c.z - 1.4) - c.y + 0.4, -1.4), Vector3(1.0, 0.8, 0.7), Color(0.85, 0.72, 0.38).darkened(0.06 * k), Vector3(0, k * 7.0 - 6.0, 0))
	hb.add("box", Vector3(-0.5, Game.ground_height(c.x - 0.5, c.z - 1.4) - c.y + 1.15, -1.4), Vector3(1.0, 0.7, 0.7), Color(0.82, 0.69, 0.36), Vector3(0, 12, 0))
	hb.add("box", Vector3(2.4, 0.55, -0.6), Vector3(1.4, 0.12, 1.0), wood.lightened(0.1), Vector3(0, 20, 62))
	hb.add("cyl", Vector3(2.75, 0.95, -0.5), Vector3(0.8, 0.1, 0.8), wood.darkened(0.2), Vector3(0, 20, 62), 9)
	_part(root, hb)
	var hide = []
	for k in 3:
		hide.append(c + Vector3(-1.0 + k * 1.0, 0, -0.5))
	var d = {"root": root, "hide": hide}
	sites[key] = d
	return d


## Son dalga püskürtüldü: saklananlar ayağa fırlar, sevinir
func cheer(list: Array) -> void:
	var i := 0
	for n in list:
		if not is_instance_valid(n):
			continue
		if n is QuestNPC:
			n.mode = "idle"
			n.set_physics_process(false)
		_look_at(n, Game.player.global_position)
		n.model.play("idle", 0.2)
		_pose(n, "cheer", {"anim": "idle", "ph": i * 1.7})
		if i == 0:
			_say(n, "Kaçtılar! Köy kurtuldu!", 3.0)
		i += 1


# ====================================================================== toplanan eşyalar (rastgele görev havuzu)
## Eşya adından sınıf: "" ise modeli yok (eski usul toplanır)
static func item_class(name: String) -> String:
	var n = name.to_lower()
	for pair in [["alın bandı", "band"], ["balık ağı", "net"], ["yağ kabağı", ""], ["mantar", "mushroom"], ["pete", "honey"], ["nehir taşı", "stone"], ["yumurta", "eggs"], ["yuva", "nest"],
			["oyuncak", "toy"], ["kunai", "kunai"], ["kristal", "crystal"], ["kahraman suyu", "bottle"], ["şişe", "vial"], ["parşömen", "scroll"], ["harita", "map"],
			["mühür kâğıdı", "tagpaper"], ["mektup", "letter"], ["makbuz", "letter"], ["kayd", "letter"], ["kayıt", "letter"], ["kil", "clay"], ["kukla", "puppet"], ["turna", "crane"],
			["kurbağa", "frog"], ["pul", "skin"], ["cevher", "ore"], ["sandı", "cargo"], ["odun", "wood"], ["fener", "lantern"], ["pirinç", "rice"], ["tavuk", "hen"],
			["çay yaprağı", "herb"], ["şifalı ot", "herb"], ["şifa otu", "herb"]]:
		if String(pair[0]) in n:
			return String(pair[1])
	return ""


const BACK_ITEMS := ["cargo", "wood", "net", "lantern", "rice", "hen", "ore"]


static func item_act(name: String) -> String:
	var k = item_class(name)
	return "cut" if k == "herb" else ("back" if k in BACK_ITEMS else "take")


static func item_label(name: String) -> String:
	return "[F] %s %s" % [name.capitalize(), {"cut": "kes", "back": "sırtla", "take": "al"}[item_act(name)]]


func _build_item(root: Node3D, name: String, rng: RandomNumberGenerator) -> void:
	var k = item_class(name)
	if k == "herb":
		_build_herb(root, rng)
		return
	var t = MB.new()    # alınan parça ("top")
	var r = MB.new()    # yerde kalan
	var top_at = Vector3.ZERO
	var wood = Color(0.5, 0.37, 0.23)
	match k:
		"mushroom":
			for i in 3:
				var a = TAU * i / 3.0 + rng.randf()
				var q = Vector3(cos(a), 0, sin(a)) * 0.07
				var h = 0.1 + 0.05 * i
				t.add("cyl", q + Vector3(0, h * 0.5, 0), Vector3(0.045, h, 0.045), Color(0.95, 0.92, 0.84), Vector3.ZERO, 6)
				t.add("hemi", q + Vector3(0, h, 0), Vector3(0.15 - i * 0.02, 0.08, 0.15 - i * 0.02), Color(0.66, 0.4, 0.24).lerp(Color(0.8, 0.55, 0.3), i * 0.3), Vector3.ZERO, 8)
			r.add("cyl", Vector3(0.25, 0.09, 0.05), Vector3(0.24, 0.5, 0.24), Color(0.36, 0.28, 0.2), Vector3(0, 30, 82), 7)
			r.add("sphere", Vector3(0.18, 0.2, 0.05), Vector3(0.2, 0.05, 0.16), Color(0.3, 0.5, 0.28), Vector3.ZERO, 6)
		"honey":
			t.add("box", Vector3(0, 0.07, 0), Vector3(0.26, 0.1, 0.2), Color(0.95, 0.72, 0.2))
			for i in 6:
				t.add("cyl", Vector3(-0.09 + (i % 3) * 0.09, 0.122, -0.045 + (i / 3) * 0.09), Vector3(0.07, 0.01, 0.07), Color(0.8, 0.52, 0.1), Vector3.ZERO, 6)
			t.add("sphere", Vector3(0.1, 0.03, 0.09), Vector3(0.14, 0.04, 0.1), Color(1.0, 0.8, 0.3), Vector3.ZERO, 6)
			# devrilmiş hasır kovan
			r.add("hemi", Vector3(-0.4, 0.0, -0.1), Vector3(0.5, 0.5, 0.5), Color(0.78, 0.66, 0.4), Vector3(0, 0, 70), 9)
			for i in 3:
				r.add("cyl", Vector3(-0.4 + i * 0.06, 0.13 + i * 0.05, -0.1), Vector3(0.52 - i * 0.1, 0.03, 0.52 - i * 0.1), Color(0.66, 0.54, 0.32), Vector3(0, 0, 70), 9)
		"stone":
			t.add("sphere", Vector3(0, 0.035, 0), Vector3(0.3, 0.07, 0.22), Color(0.58, 0.6, 0.62), Vector3(0, 20, 0), 8)
			for i in 3:
				r.add("sphere", Vector3(0.22 + i * 0.12, 0.03, -0.12 + i * 0.13), Vector3(0.2 + 0.05 * i, 0.06, 0.16), Color(0.5, 0.52, 0.55).darkened(0.08 * i), Vector3(0, i * 40.0, 0), 7)
			top_at = Vector3(0, 0.0, 0)
		"eggs", "nest":
			var nb = t if k == "nest" else r
			nb.add("torus", Vector3(0, 0.06, 0), Vector3(0.34, 0.12, 0.34), Color(0.5, 0.4, 0.26), Vector3.ZERO, 9)
			nb.add("cyl", Vector3(0, 0.03, 0), Vector3(0.26, 0.04, 0.26), Color(0.44, 0.35, 0.22), Vector3.ZERO, 9)
			for i in 6:
				nb.add("cyl", Vector3(cos(i * 1.05) * 0.15, 0.08, sin(i * 1.05) * 0.15), Vector3(0.012, 0.26, 0.012), Color(0.6, 0.5, 0.3), Vector3(70, i * 60.0, 0), 4)
			if k == "eggs":
				for i in 3:
					t.add("sphere", Vector3(cos(i * 2.1) * 0.05, 0.03, sin(i * 2.1) * 0.05), Vector3(0.075, 0.1, 0.075), Color(0.75, 0.88, 0.9), Vector3(20, 0, i * 15.0), 7)
				top_at = Vector3(0, 0.07, 0)
			else:
				t.add("sphere", Vector3(0.05, 0.1, 0.0), Vector3(0.1, 0.02, 0.05), Color(0.9, 0.9, 0.88), Vector3(0, 30, 10), 5)   # tüy
		"toy":
			# kokeshi bebek + topaç
			t.add("cyl", Vector3(0, 0.09, 0), Vector3(0.09, 0.18, 0.09), Color(0.85, 0.3, 0.25), Vector3.ZERO, 8)
			t.add("sphere", Vector3(0, 0.22, 0), Vector3.ONE * 0.12, Color(0.93, 0.8, 0.62), Vector3.ZERO, 8)
			t.add("hemi", Vector3(0, 0.23, 0), Vector3(0.125, 0.07, 0.125), Color(0.12, 0.1, 0.1), Vector3.ZERO, 8)
			t.add("cyl", Vector3(0, 0.09, 0), Vector3(0.094, 0.03, 0.094), Color(0.95, 0.85, 0.4), Vector3.ZERO, 8)
			r.add("cone", Vector3(0.22, 0.05, 0.1), Vector3(0.14, 0.1, 0.14), Color(0.3, 0.5, 0.75), Vector3(180, 0, 25), 8)
			r.add("cyl", Vector3(0.24, 0.12, 0.1), Vector3(0.02, 0.08, 0.02), wood, Vector3(0, 0, 25), 5)
			top_at = Vector3(0, 0.0, 0)
		"band":
			# düştüğü yerde: toprağa saplı kırık kunai, sapına dolanmış alın bandı; çevrede dövüş izleri
			_band_parts(t, Vector3(0, 0.0, 0))
			top_at = Vector3(0.12, 0.05, 0.05)
			r.add("cone", Vector3(0, 0.02, 0), Vector3(0.07, 0.2, 0.025), Color(0.3, 0.3, 0.33), Vector3(180, 0, 12), 4)
			r.add("cyl", Vector3(0.02, 0.17, 0), Vector3(0.026, 0.13, 0.026), Color(0.78, 0.74, 0.62), Vector3(0, 0, -12), 6)
			r.add("sphere", Vector3(0.1, 0.0, 0.1), Vector3(0.9, 0.03, 0.7), Color(0.3, 0.24, 0.17), Vector3.ZERO, 8)
			for i in 3:
				r.add("cyl", Vector3(-0.3 + i * 0.25, 0.012, 0.35 - i * 0.2), Vector3(0.012, 0.22, 0.012), Color(0.75, 0.76, 0.8), Vector3(90, 30 + i * 50, 0), 4)
			r.add("box", Vector3(0.45, 0.02, -0.25), Vector3(0.16, 0.012, 0.08), Color(0.15, 0.2, 0.4), Vector3(0, 40, 0))
		"kunai":
			# toprağa saplı, halkası yukarıda; yanında eskimiş hedef kütüğü
			t.add("cone", Vector3(0, 0.0, 0), Vector3(0.07, 0.18, 0.025), Color(0.3, 0.3, 0.33), Vector3(180, 0, 0), 4)
			t.add("cyl", Vector3(0, 0.15, 0), Vector3(0.026, 0.13, 0.026), Color(0.78, 0.74, 0.62), Vector3.ZERO, 6)
			t.add("torus", Vector3(0, 0.245, 0), Vector3(0.075, 0.02, 0.075), Color(0.3, 0.3, 0.33), Vector3(90, 0, 0), 8)
			top_at = Vector3(0, 0.07, 0)
			r.add("sphere", Vector3(0, 0.0, 0), Vector3(0.2, 0.04, 0.2), Color(0.34, 0.26, 0.17), Vector3.ZERO, 7)
		"crystal":
			for i in 4:
				var a = TAU * i / 4.0
				t.add("cone", Vector3(cos(a) * 0.05, 0.12 + 0.03 * i, sin(a) * 0.05), Vector3(0.07, 0.24 + 0.06 * i, 0.07), Color(0.55, 0.8, 1.0).lerp(Color(1.0, 0.95, 0.5), i * 0.25), Vector3(cos(a) * 16.0, 0, -sin(a) * 16.0), 5)
			r.add("sphere", Vector3(0, 0.02, 0), Vector3(0.6, 0.3, 0.5), Color(0.34, 0.33, 0.36), Vector3.ZERO, 7)
			r.add("sphere", Vector3(0.25, 0.02, 0.2), Vector3(0.3, 0.2, 0.3), Color(0.3, 0.29, 0.32), Vector3.ZERO, 6)
			r.add("box", Vector3(-0.05, 0.16, 0.1), Vector3(0.3, 0.004, 0.02), Color(0.1, 0.1, 0.12), Vector3(0, 35, 0))   # yıldırım yanığı
			top_at = Vector3(0, 0.14, 0)
		"bottle", "vial":
			var liq = Color(0.4, 0.8, 0.95) if k == "bottle" else Color(0.65, 0.08, 0.1)
			t.add("sphere", Vector3(0, 0.09, 0), Vector3(0.15, 0.17, 0.15), liq, Vector3.ZERO, 8)
			t.add("cyl", Vector3(0, 0.2, 0), Vector3(0.05, 0.08, 0.05), liq.lightened(0.3), Vector3.ZERO, 6)
			t.add("cyl", Vector3(0, 0.25, 0), Vector3(0.06, 0.035, 0.06), wood, Vector3.ZERO, 6)
			t.add("cyl", Vector3(0, 0.18, 0), Vector3(0.07, 0.012, 0.07), Color(0.85, 0.8, 0.6), Vector3.ZERO, 6)
			if k == "bottle":   # kutsal ağacın kökü
				r.add("cyl", Vector3(-0.3, 0.1, -0.1), Vector3(0.16, 0.9, 0.16), Color(0.4, 0.3, 0.2), Vector3(0, 20, 78), 6)
				r.add("cyl", Vector3(0.1, 0.06, -0.3), Vector3(0.1, 0.6, 0.1), Color(0.37, 0.28, 0.19), Vector3(0, -50, 82), 6)
		"scroll":
			_scroll_parts(t, Vector3(0, 0.08, 0))
		"map":
			t.add("cyl", Vector3(0, 0.05, 0), Vector3(0.09, 0.46, 0.09), Color(0.88, 0.8, 0.6), Vector3(0, 0, 90), 8)
			t.add("cyl", Vector3(0, 0.05, 0), Vector3(0.095, 0.03, 0.095), Color(0.3, 0.4, 0.65), Vector3(0, 0, 90), 8)
			t.add("box", Vector3(0.0, 0.012, 0.13), Vector3(0.44, 0.004, 0.2), Color(0.9, 0.84, 0.66))
			t.add("box", Vector3(-0.05, 0.016, 0.13), Vector3(0.2, 0.002, 0.012), Color(0.3, 0.4, 0.65), Vector3(0, 25, 0))
		"tagpaper":
			# kırık mızrağa takılı kalmış mühür kâğıdı
			r.add("cyl", Vector3(0.0, 0.3, -0.03), Vector3(0.035, 0.7, 0.035), wood, Vector3(0, 0, 14), 5)
			r.add("box", Vector3(0.25, 0.03, 0.2), Vector3(0.4, 0.03, 0.3), Color(0.35, 0.33, 0.32), Vector3(0, 30, 0))
			t.add("box", Vector3(0, 0.0, 0), Vector3(0.14, 0.3, 0.008), Color(0.93, 0.88, 0.72))
			t.add("cyl", Vector3(0, 0.0, 0.006), Vector3(0.08, 0.004, 0.08), Color(0.8, 0.14, 0.1), Vector3(90, 0, 0), 8)
			for y in [-0.11, 0.11]:
				t.add("box", Vector3(0, y, 0.006), Vector3(0.08, 0.012, 0.004), Color(0.8, 0.14, 0.1))
			top_at = Vector3(0.02, 0.42, 0.0)
		"letter":
			t.add("box", Vector3(0, 0.012, 0), Vector3(0.26, 0.012, 0.17), Color(0.95, 0.92, 0.84), Vector3(0, 12, 0))
			t.add("prism", Vector3(0, 0.02, 0), Vector3(0.26, 0.004, 0.1), Color(0.86, 0.82, 0.72), Vector3(0, 12, 0))
			t.add("cyl", Vector3(0, 0.022, 0), Vector3(0.04, 0.008, 0.04), Color(0.75, 0.15, 0.13), Vector3.ZERO, 7)
			r.add("box", Vector3(0.22, 0.006, 0.12), Vector3(0.2, 0.004, 0.27), Color(0.92, 0.9, 0.82), Vector3(0, -25, 0))
			r.add("box", Vector3(-0.2, 0.006, -0.14), Vector3(0.2, 0.004, 0.27), Color(0.9, 0.88, 0.8), Vector3(0, 40, 0))
		"clay":
			t.add("sphere", Vector3(0, 0.07, 0), Vector3(0.24, 0.15, 0.2), Color(0.9, 0.88, 0.84), Vector3.ZERO, 7)
			t.add("sphere", Vector3(0.08, 0.13, 0.03), Vector3(0.13, 0.1, 0.12), Color(0.85, 0.83, 0.8), Vector3.ZERO, 6)
			r.add("sphere", Vector3(-0.2, 0.01, 0.1), Vector3(0.14, 0.04, 0.12), Color(0.82, 0.8, 0.76), Vector3.ZERO, 6)
		"puppet":
			t.add("cyl", Vector3(-0.12, 0.04, 0), Vector3(0.07, 0.26, 0.07), Color(0.72, 0.56, 0.36), Vector3(0, 0, 90), 7)
			t.add("sphere", Vector3(0.02, 0.04, 0), Vector3.ONE * 0.085, Color(0.3, 0.26, 0.24), Vector3.ZERO, 7)
			t.add("cyl", Vector3(0.14, 0.04, 0.03), Vector3(0.06, 0.24, 0.06), Color(0.72, 0.56, 0.36), Vector3(0, 20, 90), 7)
			t.add("box", Vector3(0.28, 0.04, 0.08), Vector3(0.09, 0.03, 0.08), Color(0.66, 0.5, 0.32), Vector3(0, 20, 0))
			for i in 3:
				t.add("box", Vector3(0.34, 0.04, 0.07 + i * 0.03), Vector3(0.07, 0.02, 0.018), Color(0.66, 0.5, 0.32), Vector3(0, 20 + i * 8.0, 0))
			top_at = Vector3(0, 0.0, 0)
		"crane":
			t.add("prism", Vector3(0, 0.08, 0), Vector3(0.1, 0.1, 0.22), Color(0.97, 0.96, 0.94))
			for sd in [-1.0, 1.0]:
				t.add("prism", Vector3(sd * 0.13, 0.13, 0), Vector3(0.24, 0.012, 0.14), Color(0.94, 0.93, 0.9), Vector3(0, 0, sd * 28.0))
			t.add("cone", Vector3(0, 0.17, 0.13), Vector3(0.03, 0.16, 0.03), Color(0.97, 0.96, 0.94), Vector3(35, 0, 0), 4)
			t.add("cone", Vector3(0, 0.15, -0.14), Vector3(0.04, 0.16, 0.02), Color(0.97, 0.96, 0.94), Vector3(-50, 0, 0), 4)
		"frog":
			t.add("sphere", Vector3(0, 0.07, 0), Vector3(0.2, 0.13, 0.24), Color(0.4, 0.66, 0.3), Vector3(-12, 0, 0), 8)
			t.add("sphere", Vector3(0, 0.045, 0.02), Vector3(0.17, 0.08, 0.2), Color(0.9, 0.9, 0.7), Vector3.ZERO, 7)
			for sd in [-1.0, 1.0]:
				t.add("sphere", Vector3(sd * 0.06, 0.14, 0.08), Vector3.ONE * 0.06, Color(0.4, 0.66, 0.3), Vector3.ZERO, 6)
				t.add("sphere", Vector3(sd * 0.065, 0.15, 0.1), Vector3.ONE * 0.03, Color(0.1, 0.1, 0.1), Vector3.ZERO, 5)
				t.add("sphere", Vector3(sd * 0.11, 0.035, -0.07), Vector3(0.09, 0.07, 0.15), Color(0.34, 0.58, 0.26), Vector3(0, sd * 25.0, 0), 6)
				t.add("sphere", Vector3(sd * 0.09, 0.02, 0.1), Vector3(0.05, 0.04, 0.08), Color(0.34, 0.58, 0.26), Vector3.ZERO, 5)
			r.add("cyl", Vector3(0, 0.005, 0), Vector3(0.5, 0.01, 0.46), Color(0.25, 0.5, 0.26), Vector3.ZERO, 9)   # nilüfer yaprağı
		"skin":
			for i in 6:
				var a = i * 0.55
				t.add("cyl", Vector3(cos(a) * 0.12 + i * 0.03, 0.03 + i * 0.004, sin(a) * 0.12), Vector3(0.07 - i * 0.006, 0.13, 0.07 - i * 0.006), Color(0.9, 0.88, 0.74).lerp(Color(0.75, 0.78, 0.6), i * 0.12), Vector3(0, -rad_to_deg(a), 90), 6)
		"ore":
			t.add("sphere", Vector3(0, 0.12, 0), Vector3(0.36, 0.26, 0.32), Color(0.38, 0.36, 0.36), Vector3(10, 30, 0), 6)
			for i in 5:
				t.add("box", Vector3(cos(i * 1.3) * 0.13, 0.14 + sin(i * 2.0) * 0.07, sin(i * 1.3) * 0.12), Vector3(0.07, 0.05, 0.06), Color(0.72, 0.42, 0.25), Vector3(i * 30.0, i * 50.0, 0))
			r.add("sphere", Vector3(0.3, 0.03, 0.2), Vector3(0.24, 0.12, 0.2), Color(0.33, 0.32, 0.32), Vector3.ZERO, 6)
		"cargo":
			t.add("box", Vector3(0, 0.22, 0), Vector3(0.5, 0.44, 0.44), Color(0.6, 0.45, 0.28))
			for e in [-1.0, 1.0]:
				t.add("box", Vector3(0, 0.22 + e * 0.19, 0), Vector3(0.52, 0.05, 0.46), Color(0.46, 0.34, 0.2))
			t.add("box", Vector3(0, 0.22, 0.223), Vector3(0.2, 0.16, 0.004), Color(0.92, 0.88, 0.76))
			t.add("box", Vector3(0, 0.22, 0.226), Vector3(0.12, 0.02, 0.004), Color(0.7, 0.16, 0.14))
		"wood":
			for i in 4:
				t.add("cyl", Vector3(0, 0.07 + (i / 2) * 0.12, -0.065 + (i % 2) * 0.13), Vector3(0.13, 0.6, 0.13), Color(0.5, 0.36, 0.22).darkened(0.05 * i), Vector3(0, 0, 90), 6)
				t.add("cyl", Vector3(0.301, 0.07 + (i / 2) * 0.12, -0.065 + (i % 2) * 0.13), Vector3(0.11, 0.004, 0.11), Color(0.82, 0.7, 0.5), Vector3(0, 0, 90), 6)
			for x in [-0.16, 0.16]:
				t.add("box", Vector3(x, 0.13, 0), Vector3(0.025, 0.28, 0.3), Color(0.75, 0.66, 0.45))
			r.add("cyl", Vector3(-0.5, 0.03, 0.2), Vector3(0.05, 0.5, 0.05), Color(0.44, 0.33, 0.2), Vector3(0, 40, 88), 5)
		"net":
			t.add("sphere", Vector3(0, 0.1, 0), Vector3(0.6, 0.22, 0.5), Color(0.42, 0.5, 0.46), Vector3.ZERO, 7)
			for i in 5:
				t.add("box", Vector3(-0.22 + i * 0.11, 0.2, 0), Vector3(0.012, 0.03, 0.46), Color(0.25, 0.3, 0.28), Vector3(0, i * 7.0 - 14.0, 0))
				t.add("box", Vector3(0, 0.2, -0.2 + i * 0.1), Vector3(0.54, 0.03, 0.012), Color(0.25, 0.3, 0.28), Vector3(0, i * 5.0 - 10.0, 0))
			for i in 4:
				t.add("sphere", Vector3(cos(i * 1.6) * 0.27, 0.14, sin(i * 1.6) * 0.22), Vector3.ONE * 0.09, Color(0.85, 0.5, 0.2), Vector3.ZERO, 6)   # şamandıra
		"lantern":
			t.add("sphere", Vector3(0, 0.2, 0), Vector3(0.34, 0.36, 0.34), Color(0.9, 0.3, 0.22), Vector3.ZERO, 9)
			for e in [-1.0, 1.0]:
				t.add("cyl", Vector3(0, 0.2 + e * 0.17, 0), Vector3(0.18, 0.04, 0.18), Color(0.12, 0.1, 0.1), Vector3.ZERO, 8)
			for i in 3:
				t.add("cyl", Vector3(0, 0.11 + i * 0.09, 0), Vector3(0.345 - absf(i - 1.0) * 0.05, 0.008, 0.345 - absf(i - 1.0) * 0.05), Color(0.7, 0.2, 0.15), Vector3.ZERO, 9)
			t.add("cyl", Vector3(0, 0.42, 0), Vector3(0.012, 0.1, 0.012), Color(0.12, 0.1, 0.1), Vector3.ZERO, 4)
		"rice":
			for i in 7:
				var a = TAU * i / 7.0
				t.add("cyl", Vector3(cos(a) * 0.04, 0.3, sin(a) * 0.04), Vector3(0.025, 0.6, 0.025), Color(0.82, 0.72, 0.36), Vector3(cos(a) * 7.0, 0, -sin(a) * 7.0), 4)
				t.add("sphere", Vector3(cos(a) * 0.11, 0.6, sin(a) * 0.11), Vector3(0.07, 0.2, 0.07), Color(0.9, 0.8, 0.42), Vector3(cos(a) * 30.0, 0, -sin(a) * 30.0), 5)
			t.add("cyl", Vector3(0, 0.26, 0), Vector3(0.13, 0.03, 0.13), Color(0.6, 0.5, 0.3), Vector3.ZERO, 7)
			for i in 5:
				r.add("cyl", Vector3(cos(i * 1.3) * 0.3, 0.04, sin(i * 1.3) * 0.3), Vector3(0.03, 0.08, 0.03), Color(0.75, 0.66, 0.34), Vector3.ZERO, 4)
		"hen":
			t.add("sphere", Vector3(0, 0.2, 0), Vector3(0.26, 0.24, 0.34), Color(0.96, 0.95, 0.92), Vector3(-10, 0, 0), 8)
			t.add("sphere", Vector3(0, 0.36, 0.14), Vector3.ONE * 0.13, Color(0.96, 0.95, 0.92), Vector3.ZERO, 7)
			t.add("cone", Vector3(0, 0.35, 0.22), Vector3(0.05, 0.07, 0.05), Color(0.95, 0.7, 0.2), Vector3(90, 0, 0), 5)
			t.add("box", Vector3(0, 0.44, 0.13), Vector3(0.02, 0.06, 0.09), Color(0.85, 0.15, 0.12))
			t.add("sphere", Vector3(0, 0.3, 0.2), Vector3(0.03, 0.05, 0.03), Color(0.85, 0.15, 0.12), Vector3.ZERO, 5)
			t.add("cone", Vector3(0, 0.32, -0.2), Vector3(0.14, 0.2, 0.05), Color(0.9, 0.89, 0.86), Vector3(-40, 0, 0), 5)
			for sd in [-1.0, 1.0]:
				t.add("sphere", Vector3(sd * 0.05, 0.4, 0.2), Vector3.ONE * 0.022, Color(0.08, 0.08, 0.08), Vector3.ZERO, 4)
				t.add("cyl", Vector3(sd * 0.06, 0.05, 0), Vector3(0.02, 0.1, 0.02), Color(0.95, 0.7, 0.2), Vector3.ZERO, 4)
		_:
			t.add("box", Vector3(0, 0.08, 0), Vector3(0.3, 0.16, 0.22), Color(0.6, 0.45, 0.28))
	var top = _part(root, t, top_at)
	top.name = "top"
	_part(root, r)


## Alın bandı: lacivert kumaş şerit (uçları sarkık) + çelik levha
func _band_parts(b: MB, at: Vector3) -> void:
	var cloth = Color(0.14, 0.2, 0.42)
	b.add("box", at + Vector3(0, 0.02, 0), Vector3(0.34, 0.012, 0.07), cloth)
	b.add("box", at + Vector3(-0.23, 0.014, 0.04), Vector3(0.16, 0.01, 0.05), cloth.darkened(0.1), Vector3(0, 35, 0))
	b.add("box", at + Vector3(0.23, 0.014, -0.05), Vector3(0.18, 0.01, 0.05), cloth.darkened(0.1), Vector3(0, 25, 0))
	b.add("box", at + Vector3(0, 0.03, 0), Vector3(0.17, 0.012, 0.062), Color(0.74, 0.76, 0.8))
	for sx in [-1.0, 1.0]:
		b.add("cyl", at + Vector3(sx * 0.07, 0.037, 0), Vector3(0.012, 0.006, 0.012), Color(0.4, 0.4, 0.44), Vector3.ZERO, 5)
	b.add("cyl", at + Vector3(0, 0.037, 0), Vector3(0.04, 0.004, 0.04), Color(0.45, 0.46, 0.5), Vector3.ZERO, 8)


# ====================================================================== yangın: yanan ev + kuyu + su taşıma
var fire_d := {}


## Yanan ev: sıvalı küçük ev (çatısı ve cephesi alev almış), yanında kuyu. Alevler tek tek söndürülür.
func fire_site(c: Vector3, label: String) -> Dictionary:
	if not fire_d.is_empty() and is_instance_valid(fire_d.get("root")):
		return fire_d
	c = clear_spot(c, 6.5, 4.5)
	c.y = Game.ground_height(c.x, c.z)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = c
	_own(root, true)
	var body = StaticBody3D.new()
	root.add_child(body)
	var solid = func(p: Vector3, size: Vector3) -> void:
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		cs.position = p
		body.add_child(cs)
	var b = MB.new()
	var wall = Color(0.86, 0.82, 0.72)
	var beam = Color(0.36, 0.26, 0.18)
	var soot = Color(0.1, 0.09, 0.08)
	# gövde + ahşap çatkı + kapı + pencere + çatı
	b.add("box", Vector3(-1.0, 1.2, 0), Vector3(4.0, 2.4, 3.2), wall)
	for sx in [-3.0, -1.0, 1.0]:
		b.add("box", Vector3(sx, 1.2, 1.61), Vector3(0.14, 2.4, 0.06), beam)
	b.add("box", Vector3(-1.0, 2.36, 1.61), Vector3(4.1, 0.14, 0.06), beam)
	b.add("box", Vector3(-1.0, 0.07, 1.61), Vector3(4.1, 0.14, 0.06), beam)
	b.add("box", Vector3(0.0, 1.0, 1.62), Vector3(0.9, 1.9, 0.05), Color(0.2, 0.14, 0.1))
	b.add("box", Vector3(-2.0, 1.45, 1.62), Vector3(0.9, 0.75, 0.05), Color(0.08, 0.07, 0.06))
	b.add("box", Vector3(-2.0, 1.45, 1.64), Vector3(0.06, 0.75, 0.03), beam)
	b.add("prism", Vector3(-1.0, 3.05, 0), Vector3(4.8, 1.3, 4.0), Color(0.5, 0.26, 0.2))
	# is lekeleri (alevlerin yaladığı yerler)
	b.add("box", Vector3(-2.0, 2.05, 1.615), Vector3(1.1, 0.5, 0.05), soot)
	b.add("box", Vector3(0.6, 1.9, 1.615), Vector3(0.7, 0.9, 0.05), soot)
	b.add("box", Vector3(-1.9, 3.2, 0.9), Vector3(1.6, 0.06, 1.2), soot, Vector3(33, 0, 0))
	b.add("box", Vector3(0.1, 3.2, -0.9), Vector3(1.4, 0.06, 1.2), soot, Vector3(-33, 0, 0))
	solid.call(Vector3(-1.0, 1.2, 0), Vector3(4.0, 2.4, 3.2))
	# kuyu
	var wp = Vector3(4.6, 0.0, 2.2)
	wp.y = Game.ground_height(c.x + wp.x, c.z + wp.z) - c.y
	for k in 10:
		var a = TAU * k / 10.0
		b.add("box", wp + Vector3(cos(a) * 0.7, 0.35, sin(a) * 0.7), Vector3(0.46, 0.7, 0.26), Color(0.58, 0.56, 0.52).darkened((k % 3) * 0.06), Vector3(0, -rad_to_deg(a) + 90.0, 0))
	b.add("cyl", wp + Vector3(0, 0.5, 0), Vector3(1.2, 0.04, 1.2), Color(0.25, 0.45, 0.62), Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		b.add("box", wp + Vector3(sx * 0.85, 1.1, 0), Vector3(0.1, 2.2, 0.1), beam)
	b.add("prism", wp + Vector3(0, 2.4, 0), Vector3(2.1, 0.5, 1.3), Color(0.35, 0.26, 0.2))
	b.add("cyl", wp + Vector3(0, 1.9, 0), Vector3(0.1, 1.7, 0.1), beam.lightened(0.1), Vector3(0, 0, 90), 6)
	solid.call(wp + Vector3(0, 0.4, 0), Vector3(1.6, 0.8, 1.6))
	_part(root, b)
	# alevler
	var flames = []
	var spots = [Vector3(-1.9, 3.2, 1.0), Vector3(0.1, 3.3, -0.6), Vector3(-2.0, 1.6, 1.8), Vector3(0.7, 1.5, 1.8)]
	for i in spots.size():
		var f = Node3D.new()
		root.add_child(f)
		f.position = spots[i]
		# tek top değil: boyu ve yeri farklı birkaç alev dili (akış yukarı)
		var big = 1.0 if i < 2 else 0.75
		for k in 4:
			var fb = VFX.fireball(big * [0.75, 0.6, 0.5, 0.42][k])
			f.add_child(fb)
			fb.rotation.x = deg_to_rad(-90.0)
			fb.rotation.z = [0.0, 0.25, -0.3, 0.12][k]
			fb.scale = Vector3(1.0, 1.0, [2.0, 2.4, 1.8, 2.8][k])
			fb.position = Vector3([0.0, 0.45, -0.5, 0.15][k], [0.0, 0.1, -0.05, 0.5][k], [0.0, -0.15, 0.1, 0.05][k]) * big
		var l = OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.2)
		l.light_energy = 2.2
		l.omni_range = 7.0
		f.add_child(l)
		var ip = c + Vector3(spots[i].x, 0.3, 2.6)
		var it = {"pos": ip, "radius": 2.6, "kind": "quest", "label": label, "qkey": Missions._key(), "qi": i, "work": "flame", "node": f, "well": c + wp + Vector3(0, 0, 1.25), "well_c": c + wp}
		Interact.add(it)
		f.tree_exiting.connect(func(): Interact.items.erase(it))
		flames.append(f)
	fire_d = {"root": root, "flames": flames, "door": c + Vector3(0.0, 0, 2.5), "npc_at": c + Vector3(2.4, 0, 4.2), "face": c + Vector3(-1.0, 0, 0)}
	return fire_d


## Kuyuya koş, kovayı doldur, aleve koş, suyu savur; alev tıslayarak söner
func _act_douse(it: Dictionary) -> void:
	var pl = Game.player
	var f: Node3D = it["node"]
	var well: Vector3 = it["well"]
	well.y = pl.global_position.y
	await _go_w(pl, well, 5.5, false, 0.25)
	_look_at(pl, it["well_c"])
	_pose(pl, "grab_low", {"anim": "idle", "at": (it["well_c"] as Vector3) + Vector3.UP * 0.45, "lift": 0.0})
	await _wait(0.55)
	Sfx.play("water", well, 0.9, 1.2)
	paint_col = Color(0.35, 0.55, 0.75)   # kovadaki su
	var bucket = _bucket()
	pl.add_child(bucket)
	bucket.position = Vector3(0.28, 0.62, -0.25)
	FX.burst(it["well_c"] + Vector3.UP * 0.6, {"amount": 8, "life": 0.4, "size": 0.05, "vmin": 0.6, "vmax": 1.8, "gravity": Vector3(0, -6, 0), "colors": [Color(0.6, 0.8, 1.0, 1), Color(0.6, 0.8, 1.0, 0)]})
	await _wait(0.35)
	_clear_pose(pl)
	if not is_instance_valid(f):
		bucket.queue_free()
		return
	var tgt: Vector3 = it["pos"]
	tgt.y = pl.global_position.y
	await _go_w(pl, tgt, 5.5, false, 0.3)
	if not is_instance_valid(f):
		bucket.queue_free()
		return
	_look_at(pl, f.global_position)
	var hand = pl.global_position + Vector3.UP * 1.1 + _fd(pl) * 0.4
	_pose(pl, "slap", {"anim": "idle", "at": hand + _fd(pl) * 0.3 + Vector3.UP * 0.35})
	await _wait(0.3)
	bucket.queue_free()
	var dir = (f.global_position - hand).normalized()
	var dist = f.global_position.distance_to(hand)
	FX.burst(hand, {"amount": 46, "life": 0.55, "size": 0.09, "dir": dir, "spread": 9.0, "vmin": dist * 2.2, "vmax": dist * 3.0, "damp": 0.4, "gravity": Vector3(0, -5, 0), "colors": [Color(0.65, 0.85, 1.0, 1), Color(0.6, 0.8, 1.0, 0.6), Color(0.6, 0.8, 1.0, 0)]})
	Sfx.play("water", hand, 1.0, 0.9)
	await _wait(0.35)
	if is_instance_valid(f):
		Sfx.play("th_steam", f.global_position, 1.0)
		FX.burst(f.global_position, {"amount": 22, "life": 1.1, "size": 0.3, "dir": Vector3.UP, "spread": 35.0, "vmin": 1.0, "vmax": 3.0, "damp": 1.0, "gravity": Vector3(0, 1.5, 0), "colors": [Color(0.95, 0.95, 0.95, 0.8), Color(0.9, 0.9, 0.9, 0)]})
		var tw = f.create_tween()
		tw.tween_property(f, "scale", Vector3.ONE * 0.05, 0.5)
		tw.tween_callback(f.queue_free)
	await _wait(0.6)


## Çalınan belge: masadaki kitabın yerine harita / mektup destesi
func _restyle_doc(root: Node3D, look: String) -> void:
	var k = item_class(look)
	if not k in ["map", "letter", "scroll"]:
		return
	var old = root.get_node_or_null("top")
	if old == null:
		return
	var b = MB.new()
	match k:
		"map":
			b.add("cyl", Vector3(0, 0.05, 0), Vector3(0.09, 0.46, 0.09), Color(0.88, 0.8, 0.6), Vector3(0, 0, 90), 8)
			b.add("cyl", Vector3(0, 0.05, 0), Vector3(0.095, 0.03, 0.095), Color(0.3, 0.4, 0.65), Vector3(0, 0, 90), 8)
		"letter":
			for i in 3:
				b.add("box", Vector3(0, 0.008 + i * 0.012, 0), Vector3(0.26, 0.01, 0.17), Color(0.95, 0.92, 0.84).darkened(0.04 * i), Vector3(0, i * 9.0 - 6.0, 0))
			b.add("box", Vector3(0, 0.022, 0), Vector3(0.03, 0.045, 0.2), Color(0.75, 0.15, 0.13))
			b.add("box", Vector3(0, 0.022, 0), Vector3(0.28, 0.045, 0.03), Color(0.75, 0.15, 0.13))
		"scroll":
			_scroll_parts(b, Vector3(0, 0.08, 0))
	var at = old.position
	root.remove_child(old)
	old.queue_free()
	var top = _part(root, b, at)
	top.name = "top"


# ====================================================================== sırt küfesi (büyük yükler)
## Küfe: tahta çerçeveli sırt sepeti; toplanan büyük eşyalar içine dizilir
func load_begin() -> void:
	if rider_kind == "load" and is_instance_valid(rider):
		return
	if is_instance_valid(rider):
		rider.queue_free()
	var fr = Node3D.new()
	add_child(fr)
	fr.top_level = true
	var b = MB.new()
	var wood = Color(0.5, 0.37, 0.23)
	var cane = Color(0.78, 0.66, 0.42)
	# sepet gövdesi (arkası ve yanları örgü, üstü açık)
	b.add("box", Vector3(0, 0.02, -0.02), Vector3(0.46, 0.03, 0.3), wood)
	b.add("box", Vector3(0, 0.28, -0.17), Vector3(0.46, 0.5, 0.025), cane)
	for sx in [-1.0, 1.0]:
		b.add("box", Vector3(sx * 0.23, 0.28, -0.02), Vector3(0.025, 0.5, 0.3), cane.darkened(0.06))
		b.add("box", Vector3(sx * 0.21, 0.4, 0.13), Vector3(0.035, 0.9, 0.035), wood)
		b.add("box", Vector3(sx * 0.13, 0.45, 0.16), Vector3(0.05, 0.5, 0.015), Color(0.3, 0.26, 0.22))   # omuz askısı
	b.add("box", Vector3(0, 0.2, 0.13), Vector3(0.44, 0.03, 0.03), wood)
	b.add("box", Vector3(0, 0.82, 0.13), Vector3(0.46, 0.035, 0.035), wood)
	for i in 4:
		b.add("box", Vector3(0, 0.1 + i * 0.12, -0.185), Vector3(0.46, 0.012, 0.012), cane.darkened(0.2))
	var m = MeshInstance3D.new()
	m.mesh = b.build(mat)
	fr.add_child(m)
	fr.scale = Vector3.ONE * 0.92
	rider = fr
	rider_kind = "load"
	rider_yaw = PI   # sepetin ağzı arkaya
	rider_off = Vector3(0.0, 0.78, -0.2)
	load_n = 0
	Missions.pickups.append(fr)


## Büyük eşya: çök, kavra, kaldır, omzunun üstünden küfeye at
func _act_back(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	var top: Node3D = w.get_node("top")
	load_begin()
	await _stand_at(w, 0.62)
	_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": top.global_position + Vector3.UP * 0.12, "lift": 0.0})
	await _wait(0.5)
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", w.global_position, 0.8, 0.8)
	var keep = top.global_transform
	w.remove_child(top)
	add_child(top)
	top.top_level = true
	top.global_transform = keep
	var t := 0.0
	while t < 0.45:
		t += get_process_delta_time()
		top.global_position = top.global_position.lerp(_held(pl) - Vector3.UP * 0.1, 0.3)
		await get_tree().process_frame
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	var from = top.global_position
	var slot = Vector3((load_n % 2 - 0.5) * 0.2, 0.4 + (load_n / 2) * 0.15, -0.03)   # ağzından taşar, dışarıdan görünür
	var s0 = top.scale
	t = 0.0
	while t < 0.45 and is_instance_valid(rider):
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.45, t)
		top.global_position = from.lerp(rider.global_transform * slot, k) + Vector3.UP * sin(k * PI) * 0.45
		top.scale = s0.lerp(Vector3.ONE * 0.5, k)
		await get_tree().process_frame
	if is_instance_valid(rider):
		remove_child(top)
		top.top_level = false
		rider.add_child(top)
		top.position = slot
		top.rotation = Vector3(0, load_n * 1.3, 0)
		top.scale = Vector3.ONE * 0.5 / rider.scale.x
	load_n += 1
	Sfx.play("punch", pl.global_position, 0.25, 1.4)
	await _wait(0.15)


## Küfeyi görev verenin önüne indir
func unload(npc: Node3D) -> void:
	if rider_kind != "load" or not is_instance_valid(rider) or not is_instance_valid(npc):
		return
	var pl = Game.player
	busy_run = true
	_lock(10.0)
	stop_busy(npc)
	var fr = rider
	var to = npc.global_position - pl.global_position
	to.y = 0
	var spot = pl.global_position + to.normalized() * minf(0.75, to.length() * 0.5) + to.normalized().cross(Vector3.UP) * 0.45
	spot.y = Game.ground_height(spot.x, spot.z)
	_look_at(pl, npc.global_position)
	_pose(pl, "grab_low", {"anim": "idle", "at": spot + Vector3.UP * 0.5, "lift": 0.0})
	rider = null
	rider_kind = ""
	var from = fr.global_position
	var t := 0.0
	while t < 0.6 and is_instance_valid(fr):
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.6, t)
		fr.global_position = from.lerp(spot, k) + Vector3.UP * sin(k * PI) * 0.2
		await get_tree().process_frame
	Sfx.play("punch", spot, 0.3, 0.8)
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	if is_instance_valid(npc):
		_look_at(npc, spot)
		_pose(npc, "bow", {"anim": "idle", "len": 1.2})
	await _wait(1.1)
	if is_instance_valid(npc):
		_clear_pose(npc)
	_release_player()
	busy_run = false


# ====================================================================== iş noktaları (mühür taşı, sandık, mühürlü parşömen)
## [F] yazısından nokta türü: "" ise modeli yok (eski usul işaret)
static func spot_class(label: String) -> String:
	var l = label.to_lower()
	if "hücre kab" in l:
		return "pod"
	if "zirve" in l or "bulut" in l:
		return "peak"
	if "sandı" in l:
		return "chest"
	if "parşömen" in l:
		return "scrollstand"
	if "taş" in l or "mühür" in l:
		return "stone"
	return ""


func _glow_mat(col: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	return m


func _build_spot(root: Node3D, style: String, rng: RandomNumberGenerator) -> void:
	var b = MB.new()
	var body = StaticBody3D.new()
	root.add_child(body)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	cs.shape = sh
	body.add_child(cs)
	match style:
		"chest":
			var wood = Color(0.42, 0.3, 0.2)
			var iron = Color(0.3, 0.3, 0.33)
			b.add("box", Vector3(0, 0.2, 0), Vector3(0.8, 0.4, 0.5), wood)
			for x in [-0.3, 0.3]:
				b.add("box", Vector3(x, 0.2, 0), Vector3(0.07, 0.42, 0.52), iron)
			b.add("box", Vector3(0, 0.36, 0.255), Vector3(0.12, 0.14, 0.02), Color(0.8, 0.68, 0.3))
			# içi: sikke kesesi + tomar
			b.add("box", Vector3(0, 0.39, 0), Vector3(0.72, 0.02, 0.42), Color(0.12, 0.1, 0.09))
			for i in 7:
				b.add("cyl", Vector3(-0.2 + (i % 4) * 0.12, 0.41 + (i / 4) * 0.012, -0.05 + (i % 3) * 0.06), Vector3(0.08, 0.012, 0.08), Color(0.92, 0.78, 0.3), Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10)), 7)
			var lid = Node3D.new()
			lid.name = "lid"
			root.add_child(lid)
			lid.position = Vector3(0, 0.4, -0.25)
			var lb = MB.new()
			lb.add("box", Vector3(0, 0.06, 0.25), Vector3(0.82, 0.12, 0.52), wood.lightened(0.05))
			for x in [-0.3, 0.3]:
				lb.add("box", Vector3(x, 0.06, 0.25), Vector3(0.07, 0.13, 0.54), iron)
			_part(lid, lb)
			sh.size = Vector3(0.8, 0.5, 0.5)
			cs.position = Vector3(0, 0.25, 0)
		"scrollstand":
			# alçak taş kaide + üstünde mühür bandıyla bağlı parşömen
			b.add("box", Vector3(0, 0.2, 0), Vector3(0.6, 0.4, 0.45), Color(0.52, 0.5, 0.47))
			b.add("box", Vector3(0, 0.42, 0), Vector3(0.7, 0.05, 0.52), Color(0.46, 0.44, 0.42))
			b.add("box", Vector3(0, 0.45, 0), Vector3(0.5, 0.012, 0.3), Color(0.5, 0.12, 0.12))
			var sb = MB.new()
			_scroll_parts(sb, Vector3.ZERO)
			var top = _part(root, sb, Vector3(0, 0.54, 0))
			top.name = "top"
			var pb = MB.new()   # açılınca görünen kâğıt
			pb.add("box", Vector3(0, 0, 0.22), Vector3(0.44, 0.006, 0.44), Color(0.93, 0.89, 0.76))
			for i in 4:
				pb.add("box", Vector3(-0.12 + i * 0.08, 0.005, 0.22), Vector3(0.02, 0.004, 0.32), Color(0.15, 0.13, 0.12))
			pb.add("cyl", Vector3(0, 0.006, 0.22), Vector3(0.16, 0.004, 0.16), Color(0.75, 0.15, 0.13), Vector3.ZERO, 10)
			var paper = _part(root, pb, Vector3(0, 0.47, 0.02))
			paper.name = "paper"
			paper.scale = Vector3(1, 1, 0.02)
			sh.size = Vector3(0.7, 0.46, 0.52)
			cs.position = Vector3(0, 0.23, 0)
		"pod":
			# hücre kabı: demir kaide, cam tüp içinde yeşil sıvıda soluk doku, üstte vanalı kapak, yanda borular
			var iron2 = Color(0.3, 0.31, 0.34)
			b.add("cyl", Vector3(0, 0.15, 0), Vector3(1.1, 0.3, 1.1), iron2, Vector3.ZERO, 12)
			b.add("cyl", Vector3(0, 0.33, 0), Vector3(0.95, 0.06, 0.95), iron2.lightened(0.12), Vector3.ZERO, 12)
			for k in 4:
				var a3 = TAU * k / 4.0 + 0.78
				b.add("cyl", Vector3(cos(a3) * 0.44, 1.05, sin(a3) * 0.44), Vector3(0.05, 1.4, 0.05), iron2, Vector3.ZERO, 5)
			b.add("cyl", Vector3(-0.62, 0.7, -0.2), Vector3(0.09, 1.4, 0.09), iron2.darkened(0.1), Vector3.ZERO, 6)
			b.add("cyl", Vector3(-0.42, 1.42, -0.14), Vector3(0.09, 0.5, 0.09), iron2.darkened(0.1), Vector3(0, 0, 70), 6)
			b.add("box", Vector3(0, 0.2, 0.56), Vector3(0.34, 0.2, 0.03), Color(0.85, 0.8, 0.6))   # etiket
			b.add("box", Vector3(0, 0.2, 0.578), Vector3(0.26, 0.03, 0.005), Color(0.15, 0.13, 0.12))
			# doku: soluk yumru + kök gibi uzantılar
			var tb = MB.new()
			tb.add("sphere", Vector3(0, 0, 0), Vector3(0.3, 0.36, 0.28), Color(0.9, 0.86, 0.72), Vector3.ZERO, 9)
			for k in 6:
				var a4 = TAU * k / 6.0
				tb.add("cyl", Vector3(cos(a4) * 0.12, -0.24, sin(a4) * 0.12), Vector3(0.035, 0.36, 0.035), Color(0.62, 0.5, 0.34), Vector3(sin(a4) * 24.0, 0, -cos(a4) * 24.0), 4)
			tb.add("sphere", Vector3(0.08, 0.1, 0.1), Vector3(0.12, 0.1, 0.08), Color(0.8, 0.72, 0.56), Vector3.ZERO, 6)
			var tis = _part(root, tb, Vector3(0, 1.05, 0))
			tis.name = "tissue"
			var liq = MeshInstance3D.new()
			liq.name = "glow"
			var lm = CylinderMesh.new()
			lm.top_radius = 0.4
			lm.bottom_radius = 0.4
			lm.height = 1.36
			lm.radial_segments = 14
			liq.mesh = lm
			var gm2 = StandardMaterial3D.new()
			gm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			gm2.albedo_color = Color(0.3, 0.85, 0.45, 0.38)
			liq.material_override = gm2
			root.add_child(liq)
			liq.position = Vector3(0, 1.05, 0)
			var cap = Node3D.new()
			cap.name = "lid"
			root.add_child(cap)
			cap.position = Vector3(0, 1.76, 0)
			var cb = MB.new()
			cb.add("cyl", Vector3(0, 0.06, 0), Vector3(1.0, 0.14, 1.0), iron2.lightened(0.08), Vector3.ZERO, 12)
			cb.add("cyl", Vector3(0, 0.17, 0), Vector3(0.5, 0.1, 0.5), iron2, Vector3.ZERO, 10)
			_part(cap, cb)
			var valve = Node3D.new()
			valve.name = "valve"
			cap.add_child(valve)
			valve.position = Vector3(0, 0.3, 0)
			var vb = MB.new()
			vb.add("cyl", Vector3(0, -0.04, 0), Vector3(0.06, 0.14, 0.06), iron2.darkened(0.2), Vector3.ZERO, 6)
			for k in 3:
				vb.add("box", Vector3.ZERO, Vector3(0.5, 0.035, 0.05), Color(0.7, 0.2, 0.16), Vector3(0, k * 60.0, 0))
			for k in 12:
				var a5 = TAU * k / 12.0
				vb.add("box", Vector3(cos(a5) * 0.25, 0, sin(a5) * 0.25), Vector3(0.14, 0.04, 0.05), Color(0.7, 0.2, 0.16), Vector3(0, -rad_to_deg(a5) + 90.0, 0))
			_part(valve, vb)
			sh.size = Vector3(1.0, 1.9, 1.0)
			cs.position = Vector3(0, 0.95, 0)
		"peak":
			# zirve işareti: üst üste dizilmiş yassı taşlar, tepesinde rüzgârda yıpranmış bez şerit
			var rk = Color(0.52, 0.5, 0.47)
			var y0 = 0.0
			for k in 6:
				var w6 = 0.95 - k * 0.12
				var h6 = rng.randf_range(0.16, 0.24)
				b.add("sphere", Vector3(rng.randf_range(-0.04, 0.04), y0 + h6 * 0.5, rng.randf_range(-0.04, 0.04)), Vector3(w6, h6 * 1.25, w6 * rng.randf_range(0.8, 1.0)), rk.darkened(rng.randf() * 0.18), Vector3(0, rng.randf() * 90.0, 0), 7)
				y0 += h6 * 0.92
			b.add("cyl", Vector3(0, y0 + 0.35, 0), Vector3(0.035, 0.8, 0.035), Color(0.4, 0.3, 0.2), Vector3(0, 0, 4), 5)
			b.add("box", Vector3(0.17, y0 + 0.66, 0), Vector3(0.32, 0.1, 0.01), Color(0.8, 0.25, 0.18), Vector3(0, 0, -14))
			b.add("box", Vector3(0.14, y0 + 0.52, 0), Vector3(0.24, 0.08, 0.01), Color(0.92, 0.9, 0.84), Vector3(0, 0, -24))
			for k in 5:
				var a6 = TAU * k / 5.0 + rng.randf()
				b.add("sphere", Vector3(cos(a6) * 0.75, 0.08, sin(a6) * 0.75), Vector3(0.36, 0.2, 0.3), rk.darkened(0.12), Vector3(0, rng.randf() * 90.0, 0), 6)
			sh.size = Vector3(0.9, y0, 0.9)
			cs.position = Vector3(0, y0 * 0.5, 0)
		_:
			# dikili mühür taşı: yosunlu kaba kaya, beline kutsal ip, önünde oyulmuş mühür dairesi
			var rock = Color(0.5, 0.5, 0.48)
			b.add("box", Vector3(0, 0.55, 0), Vector3(0.62, 1.1, 0.42), rock, Vector3(0, 0, 2))
			b.add("box", Vector3(0.02, 1.16, 0), Vector3(0.5, 0.22, 0.36), rock.lightened(0.05), Vector3(0, 0, -4))
			b.add("sphere", Vector3(0, 0.03, 0), Vector3(0.95, 0.16, 0.75), rock.darkened(0.15), Vector3.ZERO, 8)
			for i in 5:
				b.add("sphere", Vector3(rng.randf_range(-0.28, 0.28), rng.randf_range(0.1, 0.5), rng.randf_range(-0.2, 0.0)), Vector3(0.22, 0.12, 0.1), Color(0.3, 0.48, 0.26), Vector3.ZERO, 6)
			# shimenawa: ip + kâğıt şeritler
			b.add("box", Vector3(0, 0.95, 0.0), Vector3(0.68, 0.06, 0.48), Color(0.8, 0.72, 0.5))
			for x in [-0.2, 0.0, 0.2]:
				b.add("box", Vector3(x, 0.84, 0.245), Vector3(0.06, 0.16, 0.008), Color(0.96, 0.95, 0.92), Vector3(0, 0, x * 40.0))
			# oyma mühür (sönük)
			b.add("cyl", Vector3(0, 0.55, 0.212), Vector3(0.34, 0.008, 0.34), Color(0.22, 0.22, 0.23), Vector3(90, 0, 0), 12)
			b.add("cyl", Vector3(0, 0.55, 0.215), Vector3(0.26, 0.008, 0.26), rock, Vector3(90, 0, 0), 12)
			for i in 4:
				b.add("box", Vector3(0, 0.55, 0.218), Vector3(0.22, 0.03, 0.006), Color(0.22, 0.22, 0.23), Vector3(0, 0, i * 45.0))
			# parlayan mühür (uyanınca)
			var gb = MB.new()
			gb.add("cyl", Vector3(0, 0, 0), Vector3(0.345, 0.006, 0.345), Color.WHITE, Vector3(90, 0, 0), 12)
			for i in 4:
				gb.add("box", Vector3(0, 0, 0.004), Vector3(0.24, 0.036, 0.006), Color.WHITE, Vector3(0, 0, i * 45.0))
			var glow = MeshInstance3D.new()
			glow.name = "glow"
			glow.mesh = gb.build(mat)
			glow.material_override = _glow_mat(Color(0.55, 0.95, 1.0))
			root.add_child(glow)
			glow.position = Vector3(0, 0.55, 0.222)
			glow.visible = false
			sh.size = Vector3(0.62, 1.2, 0.42)
			cs.position = Vector3(0, 0.6, 0)
	_part(root, b)


## Noktadaki iş: taşta avuç bas / vur / otur; sandığın kapağını aç; parşömeni çöz
func _act_spot(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	var front = w.global_transform.basis.z.normalized()
	var lab = String(it.get("label", "")).to_lower()
	match String(it.get("style", "stone")):
		"chest":
			await _stand_at(w, 0.85, front)
			var lid: Node3D = w.get_node("lid")
			_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": w.global_position + front * 0.2 + Vector3.UP * 0.45, "lift": 0.0})
			await _wait(0.5)
			Sfx.play("pickup", w.global_position, 0.8, 0.6)
			var tw = lid.create_tween()
			tw.tween_property(lid, "rotation:x", deg_to_rad(-105.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await _wait(0.55)
			FX.burst(w.global_position + Vector3.UP * 0.5, {"amount": 8, "life": 0.5, "size": 0.05, "vmin": 0.6, "vmax": 1.8, "gravity": Vector3(0, -3, 0), "colors": [Color(1.0, 0.9, 0.4, 1), Color(1.0, 0.8, 0.3, 0)]})
			Sfx.play("coin", w.global_position, 0.9)
			await _wait(0.7)
		"scrollstand":
			await _stand_at(w, 0.85, front)
			var top: Node3D = w.get_node("top")
			var paper: Node3D = w.get_node("paper")
			_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": top.global_position, "lift": 0.0})
			await _wait(0.5)
			Sfx.play("seal", w.global_position, 1.0)
			var tw2 = paper.create_tween()
			tw2.tween_property(paper, "scale:z", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
			await _wait(0.5)
			FX.burst(w.global_position + front * 0.24 + Vector3.UP * 0.5, {"amount": 10, "life": 0.5, "size": 0.06, "vmin": 0.4, "vmax": 1.4, "gravity": Vector3(0, 2, 0), "colors": [Color(1.0, 0.4, 0.3, 1), Color(1.0, 0.3, 0.2, 0)]})
			await _wait(0.8)
		"pod":
			# vanayı çevir, kapak kalkar, sıvı parlar; avucunu dokuya bastır
			await _stand_at(w, 0.95, front)
			_look_at(pl, w.global_position)
			var cap2: Node3D = w.get_node("lid")
			var valve2: Node3D = cap2.get_node("valve")
			_pose(pl, "slap", {"anim": "idle", "at": valve2.global_position + front * 0.1})
			await _wait(0.45)
			Sfx.play("pickup", w.global_position, 0.9, 0.5)
			var twv = valve2.create_tween()
			twv.tween_property(valve2, "rotation:y", TAU * 1.5, 1.0).set_trans(Tween.TRANS_SINE)
			await _wait(1.05)
			_clear_pose(pl)
			var twc = cap2.create_tween()
			twc.tween_property(cap2, "position:y", cap2.position.y + 0.55, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var liq2: MeshInstance3D = w.get_node("glow")
			var lmat: StandardMaterial3D = liq2.material_override
			var twl = liq2.create_tween()
			twl.tween_property(lmat, "albedo_color", Color(0.55, 1.0, 0.6, 0.62), 0.7)
			Sfx.play("seal", w.global_position, 1.0, 0.7)
			FX.burst(w.global_position + Vector3.UP * 1.8, {"amount": 14, "life": 0.7, "size": 0.05, "vmin": 0.5, "vmax": 1.6, "gravity": Vector3(0, -2.5, 0), "colors": [Color(0.5, 1.0, 0.6, 1), Color(0.4, 0.9, 0.5, 0)]})
			await _wait(0.8)
			var tis2: Node3D = w.get_node("tissue")
			_pose(pl, "slap", {"anim": "idle", "at": tis2.global_position + Vector3.UP * 0.55 + front * 0.2})
			await _wait(0.5)
			var twt = tis2.create_tween()
			twt.tween_property(tis2, "scale", Vector3.ONE * 1.25, 0.25)
			twt.tween_property(tis2, "scale", Vector3.ONE * 0.6, 0.5)
			FX.light(tis2.global_position, Color(0.5, 1.0, 0.6), 3.0, 6.0, 0.6)
			await _wait(0.9)
		"peak":
			# taş yığınının yanında mühür yap, başını göğe kaldır, ateş topunu bulutlara üfle
			await _stand_at(w, 1.5, front)
			_look_at(pl, w.global_position)
			_pose(pl, "blow", {"anim": "idle"})
			await _wait(0.5)
			Sfx.play("seal", pl.global_position, 1.0)
			await _wait(0.45)
			var mouth2 = pl.global_position + Vector3.UP * 1.75 * pl.model.age_scale + _fd(pl) * 0.3
			var ball = VFX.fireball(0.5)
			get_tree().current_scene.add_child(ball)
			ball.global_position = mouth2
			Sfx.play("fire", mouth2, 1.0)
			var sky = mouth2 + Vector3.UP * 46.0 + _fd(pl) * 5.0
			var twb = ball.create_tween()
			twb.set_parallel(true)
			twb.tween_property(ball, "global_position", sky, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			twb.tween_property(ball, "scale", Vector3.ONE * 7.0, 1.5)
			FX.light(mouth2, Color(1.0, 0.6, 0.25), 3.0, 8.0, 0.5)
			await _wait(1.5)
			if is_instance_valid(ball):
				ball.queue_free()
			FX.flash_sphere(sky, Color(1.0, 0.6, 0.2), 14.0, 0.6)
			FX.light(sky, Color(1.0, 0.6, 0.25), 6.0, 60.0, 1.2)
			FX.burst(sky, {"amount": 40, "life": 2.2, "size": 0.7, "vmin": 2.0, "vmax": 7.0, "gravity": Vector3(0, 1.0, 0), "colors": [Color(1.0, 0.75, 0.3, 1), Color(1.0, 0.35, 0.1, 0)]})
			await _wait(0.6)
		_:
			var glow: Node3D = w.get_node_or_null("glow")
			var at = w.global_position + front * 0.24 + Vector3.UP * 0.62
			if "meditasyon" in lab:
				# taşın önünde bağdaş kurup otur, nefes al
				await _stand_at(w, 1.1, front)
				_look_at(pl, w.global_position)
				_pose(pl, "meditate", {"sit": "agura", "anim": "idle", "lift": 0.0})
				await _wait(2.4)
			elif "çal" in lab:
				# ritim: taşa iki kez vur
				await _stand_at(w, 0.72, front)
				_look_at(pl, w.global_position)
				for i in 2:
					_pose(pl, "slap", {"anim": "idle", "at": at})
					await _wait(0.42)
					Sfx.play("punch", at, 0.7, 0.7 + i * 0.25)
					FX.burst(at, {"amount": 5, "life": 0.3, "size": 0.05, "vmin": 0.5, "vmax": 1.4, "gravity": Vector3.ZERO, "colors": [Color(0.8, 0.8, 0.75, 1), Color(0.8, 0.8, 0.75, 0)]})
					await _wait(0.3)
					_clear_pose(pl)
			else:
				# avucunu oyma mühüre bastır, chakra ver
				await _stand_at(w, 0.72, front)
				_look_at(pl, w.global_position)
				_pose(pl, "slap", {"anim": "idle", "at": at})
				await _wait(0.45)
				Sfx.play("seal", at, 1.0)
				await _wait(0.5)
			if glow:
				glow.visible = true
				var gm: StandardMaterial3D = glow.material_override
				var tw3 = glow.create_tween()
				gm.albedo_color = Color(1, 1, 1)
				tw3.tween_property(gm, "albedo_color", Color(0.45, 0.9, 1.0), 0.6)
			FX.burst(at, {"amount": 10, "life": 0.6, "size": 0.06, "vmin": 0.4, "vmax": 1.3, "gravity": Vector3(0, 1.5, 0), "colors": [Color(0.6, 0.95, 1.0, 1), Color(0.5, 0.9, 1.0, 0)]})
			await _wait(0.5)


# ====================================================================== 5. adım: av, nöbet, haber zinciri
## Yeni mekânlar: avcı kampı (askı, çardak, ateş), nöbet kulübesi, işaret ateşi kulesi
func _site_more(kind: String, root: Node3D, b: MB, d: Dictionary, c: Vector3, gy: Callable, solid: Callable) -> void:
	var wood = Color(0.46, 0.33, 0.21)
	var dark = wood.darkened(0.3)
	var stone = Color(0.56, 0.54, 0.5)
	if kind == "hunt_camp":
		# askı: iki çatal ayak + üstte yatay sırık
		var rc = Vector3(-1.9, 0, -0.5)
		var rg: float = gy.call(rc.x, rc.z)
		for sx in [-1.25, 1.25]:
			for sz in [-1.0, 1.0]:
				b.add("cyl", Vector3(rc.x + sx, rg + 1.05, rc.z + sz * 0.38), Vector3(0.09, 2.3, 0.09), wood, Vector3(sz * 20.0, 0, 0), 6)
			b.add("cyl", Vector3(rc.x + sx, rg + 2.02, rc.z), Vector3(0.13, 0.1, 0.13), Color(0.75, 0.68, 0.5), Vector3(0, 0, 90), 6)   # bağ ipi
			solid.call(Vector3(rc.x + sx, rg + 1.0, rc.z), Vector3(0.2, 2.0, 0.8))
		b.add("cyl", Vector3(rc.x, rg + 2.08, rc.z), Vector3(0.08, 3.0, 0.08), wood.lightened(0.08), Vector3(0, 0, 90), 6)
		for k in 3:
			b.add("cyl", Vector3(rc.x - 0.8 + k * 0.8, rg + 1.98, rc.z), Vector3(0.025, 0.2, 0.025), Color(0.3, 0.3, 0.32), Vector3.ZERO, 4)   # kanca
		# çardak: iki direk + eğik post örtü
		var lc = Vector3(2.4, 0, -1.3)
		var lg: float = gy.call(lc.x, lc.z)
		for sx in [-1.1, 1.1]:
			b.add("cyl", Vector3(lc.x + sx, lg + 0.85, lc.z + 0.8), Vector3(0.09, 1.7, 0.09), wood, Vector3.ZERO, 6)
		b.add("cyl", Vector3(lc.x, lg + 1.7, lc.z + 0.8), Vector3(0.07, 2.5, 0.07), wood, Vector3(0, 0, 90), 6)
		b.add("box", Vector3(lc.x, lg + 0.9, lc.z - 0.25), Vector3(2.4, 0.06, 2.7), Color(0.5, 0.4, 0.28), Vector3(-38, 0, 0))
		b.add("box", Vector3(lc.x - 0.5, lg + 0.93, lc.z - 0.2), Vector3(0.7, 0.07, 1.3), Color(0.42, 0.33, 0.24), Vector3(-38, 0, 0))   # yama
		b.add("box", Vector3(lc.x, lg + 0.1, lc.z - 0.1), Vector3(1.7, 0.12, 0.8), Color(0.55, 0.5, 0.42))   # yatak
		solid.call(Vector3(lc.x, lg + 0.5, lc.z - 0.6), Vector3(2.2, 1.0, 1.2))
		# ateş çukuru
		var fc = Vector3(1.0, gy.call(1.0, 1.2), 1.2)
		for k in 8:
			var a = TAU * k / 8.0
			b.add("sphere", fc + Vector3(cos(a) * 0.42, 0.06, sin(a) * 0.42), Vector3(0.24, 0.18, 0.2), stone.darkened((k % 3) * 0.07), Vector3(0, k * 40.0, 0), 6)
		for k in 3:
			b.add("cyl", fc + Vector3(0, 0.1, 0), Vector3(0.09, 0.6, 0.09), Color(0.2, 0.15, 0.12), Vector3(78, k * 60.0, 0), 5)
		var fb = VFX.fireball(0.42)
		root.add_child(fb)
		fb.position = fc + Vector3(0, 0.32, 0)
		fb.rotation.x = deg_to_rad(-90.0)
		fb.scale = Vector3(1, 1, 1.9)
		var fl = OmniLight3D.new()
		fl.light_color = Color(1.0, 0.6, 0.25)
		fl.light_energy = 1.4
		fl.omni_range = 6.0
		fl.position = fc + Vector3(0, 0.7, 0)
		root.add_child(fl)
		# kütük + saplı balta, yay ve ok kılıfı çardağa dayalı
		var sc2 = Vector3(-0.3, gy.call(-0.3, 1.9), 1.9)
		b.add("cyl", sc2 + Vector3(0, 0.22, 0), Vector3(0.5, 0.44, 0.5), wood.darkened(0.1), Vector3.ZERO, 9)
		b.add("cyl", sc2 + Vector3(0, 0.445, 0), Vector3(0.46, 0.01, 0.46), Color(0.74, 0.62, 0.42), Vector3.ZERO, 9)
		b.add("cyl", sc2 + Vector3(0.05, 0.7, 0.0), Vector3(0.04, 0.6, 0.04), wood.lightened(0.1), Vector3(0, 0, -24), 5)
		b.add("box", sc2 + Vector3(-0.07, 0.5, 0.0), Vector3(0.16, 0.12, 0.03), Color(0.5, 0.5, 0.54), Vector3(0, 0, -24))
		solid.call(sc2 + Vector3(0, 0.22, 0), Vector3(0.5, 0.44, 0.5))
		b.add("cyl", Vector3(lc.x + 1.3, lg + 0.7, lc.z + 0.9), Vector3(0.03, 1.4, 0.03), dark, Vector3(8, 0, 6), 5)   # yay
		b.add("cyl", Vector3(lc.x + 1.5, lg + 0.4, lc.z + 0.95), Vector3(0.14, 0.7, 0.14), Color(0.4, 0.26, 0.18), Vector3(0, 0, 10), 7)   # ok kılıfı
		for k in 4:
			b.add("cyl", Vector3(lc.x + 1.44 + k * 0.03, lg + 0.86, lc.z + 0.93 + (k % 2) * 0.04), Vector3(0.012, 0.3, 0.012), Color(0.85, 0.8, 0.7), Vector3(0, 0, 10), 4)
		d["rack"] = c + Vector3(rc.x, rg + 2.08, rc.z)
		d["rack_front"] = c + Vector3(rc.x, 0, rc.z + 1.0)
		d["npc_at"] = c + Vector3(0.1, 0, 0.6)
		d["face"] = c + Vector3(1.0, 0, 1.2)
		d["hung"] = 0
		hunt_d = d
	elif kind == "guard_post":
		# nöbet kulübesi: önü açık ahşap kabin, içinde tezgâh, yanında mızraklık ve tabela
		var g0: float = gy.call(0, 0)
		var wl = Color(0.6, 0.47, 0.32)
		b.add("box", Vector3(0, g0 + 1.1, -0.95), Vector3(2.4, 2.2, 0.1), wl)
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(sx * 1.15, g0 + 1.1, -0.2), Vector3(0.1, 2.2, 1.6), wl.darkened(0.06))
			b.add("box", Vector3(sx * 1.15, g0 + 1.1, 0.62), Vector3(0.14, 2.2, 0.14), dark)
		b.add("box", Vector3(0, g0 + 0.95, 0.5), Vector3(2.3, 0.1, 0.5), wood.lightened(0.1))   # tezgâh
		b.add("box", Vector3(0, g0 + 0.47, 0.7), Vector3(2.3, 0.94, 0.08), wl.darkened(0.1))
		b.add("prism", Vector3(0, g0 + 2.55, -0.1), Vector3(3.0, 0.75, 2.4), Color(0.28, 0.33, 0.3))
		b.add("box", Vector3(-0.5, g0 + 1.02, 0.5), Vector3(0.42, 0.04, 0.3), Color(0.92, 0.9, 0.82))   # kayıt defteri
		b.add("cyl", Vector3(0.6, g0 + 1.08, 0.45), Vector3(0.1, 0.16, 0.1), Color(0.75, 0.75, 0.7), Vector3.ZERO, 7)   # çay bardağı
		solid.call(Vector3(0, g0 + 1.1, -0.2), Vector3(2.4, 2.2, 1.9))
		var sp = Vector3(1.9, gy.call(1.9, -0.4), -0.4)
		b.add("box", sp + Vector3(0, 0.5, 0), Vector3(0.9, 0.08, 0.3), dark)
		b.add("box", sp + Vector3(0, 1.3, 0), Vector3(0.9, 0.08, 0.3), dark)
		for sx in [-0.4, 0.4]:
			b.add("box", sp + Vector3(sx, 0.7, 0), Vector3(0.08, 1.4, 0.28), dark)
		for k in 3:
			var mx = -0.25 + k * 0.25
			b.add("cyl", sp + Vector3(mx, 1.2, 0), Vector3(0.035, 2.4, 0.035), wood.lightened(0.15), Vector3.ZERO, 5)
			b.add("cone", sp + Vector3(mx, 2.52, 0), Vector3(0.09, 0.3, 0.03), Color(0.7, 0.72, 0.76), Vector3.ZERO, 4)
		solid.call(sp + Vector3(0, 0.7, 0), Vector3(0.9, 1.4, 0.3))
		var tp = Vector3(-2.0, gy.call(-2.0, 0.6), 0.6)
		b.add("cyl", tp + Vector3(0, 0.8, 0), Vector3(0.08, 1.6, 0.08), dark, Vector3.ZERO, 6)
		b.add("box", tp + Vector3(0, 1.45, 0.02), Vector3(0.9, 0.55, 0.05), Color(0.86, 0.8, 0.64))
		for k in 3:
			b.add("box", tp + Vector3(0, 1.58 - k * 0.14, 0.05), Vector3(0.62 - k * 0.12, 0.035, 0.01), Color(0.15, 0.13, 0.12))
		d["npc_at"] = c + Vector3(0.9, 0, 1.5)
		d["face"] = c + Vector3(0.9, 0, 8.0)
		d["stand"] = c + Vector3(-0.4, 0, 2.4)
	elif kind.begins_with("beacon"):
		# işaret ateşi: taş kaide + demir mangal + odun; yanında odun istifi, basamak
		var g1: float = gy.call(0, 0)
		for ring in 3:
			var rr = 1.25 - ring * 0.12
			for k in 10:
				var a = TAU * (k + ring * 0.5) / 10.0
				b.add("box", Vector3(cos(a) * rr, g1 + 0.22 + ring * 0.42, sin(a) * rr), Vector3(0.78 - ring * 0.06, 0.42, 0.34), stone.darkened(((k + ring) % 3) * 0.07), Vector3(0, -rad_to_deg(a) + 90.0, 0))
		b.add("cyl", Vector3(0, g1 + 0.65, 0), Vector3(2.2, 1.3, 2.2), stone.darkened(0.25), Vector3.ZERO, 10)
		b.add("cyl", Vector3(0, g1 + 1.5, 0), Vector3(1.5, 0.34, 1.5), Color(0.16, 0.15, 0.15), Vector3.ZERO, 10)   # mangal
		b.add("cyl", Vector3(0, g1 + 1.68, 0), Vector3(1.3, 0.04, 1.3), Color(0.08, 0.07, 0.07), Vector3.ZERO, 10)
		for k in 3:
			b.add("cyl", Vector3(cos(k * 2.1) * 0.55, g1 + 1.36, sin(k * 2.1) * 0.55), Vector3(0.06, 0.3, 0.06), Color(0.16, 0.15, 0.15), Vector3.ZERO, 5)
		for k in 6:
			b.add("cyl", Vector3(0, g1 + 1.82 + (k / 3) * 0.14, 0), Vector3(0.13, 1.05, 0.13), Color(0.4, 0.28, 0.18).darkened((k % 2) * 0.12), Vector3(84, k * 60.0 + (k / 3) * 30.0, 0), 6)
		solid.call(Vector3(0, g1 + 0.85, 0), Vector3(2.3, 1.7, 2.3))
		var wp = Vector3(-2.2, gy.call(-2.2, 0.4), 0.4)
		for k in 7:
			b.add("cyl", wp + Vector3(0, 0.12 + (k / 4) * 0.22, (k % 4) * 0.24 - 0.36 + (k / 4) * 0.12), Vector3(0.22, 1.1, 0.22), Color(0.42, 0.3, 0.2).darkened((k % 3) * 0.08), Vector3(0, 0, 90), 6)
		solid.call(wp + Vector3(0, 0.25, 0), Vector3(1.1, 0.5, 1.0))
		b.add("cyl", Vector3(2.2, gy.call(2.2, -1.6) + 2.4, -1.6), Vector3(0.08, 4.8, 0.08), dark, Vector3.ZERO, 6)
		var vc = Color(0.78, 0.2, 0.16)
		b.add("box", Vector3(2.85, gy.call(2.2, -1.6) + 4.3, -1.6), Vector3(1.2, 0.75, 0.03), vc)
		d["fire_at"] = c + Vector3(0, g1 + 1.9, 0)
		d["torch_at"] = c + Vector3(0.0, 0, 1.75)
		d["npc_at"] = c + Vector3(1.9, 0, 2.2)
		d["face"] = c + Vector3(1.9, 0, 9.0)


## Konuşma sonrası olaylar (adımın "on_ok" anahtarı)
func site_event(ev: String, npc: Node3D, s: Dictionary) -> void:
	if ev == "fence":
		await fence_deal(npc)
		return
	if ev == "beacon" and s.has("site"):
		var key = "%s:%s" % [String(Missions.active().get("id", "")), String(s["site"])]
		if sites.has(key):
			await light_beacon(sites[key], npc)


## Nöbetçi meşaleyi alır, mangala yürür, odunu tutuşturur: alev ve duman göğe yükselir (kalır)
func light_beacon(d: Dictionary, npc: Node3D) -> void:
	if d.get("lit", false) or not is_instance_valid(d.get("root")):
		return
	d["lit"] = true
	var root: Node3D = d["root"]
	var fire_at: Vector3 = d["fire_at"]
	busy_run = true
	_lock(14.0)
	var torch: Node3D
	if is_instance_valid(npc):
		stop_busy(npc)
		if npc is QuestNPC:
			npc.set_physics_process(false)
		var tb = MB.new()
		tb.add("cyl", Vector3(0, 0, 0), Vector3(0.045, 0.7, 0.045), Color(0.4, 0.28, 0.18), Vector3.ZERO, 5)
		tb.add("cyl", Vector3(0, 0.38, 0), Vector3(0.09, 0.14, 0.09), Color(0.2, 0.17, 0.14), Vector3.ZERO, 6)
		torch = Node3D.new()
		npc.model.add_child(torch)
		torch.position = Vector3(0.24, 1.2, -0.34)
		_part(torch, tb)
		var tf = VFX.fireball(0.2)
		torch.add_child(tf)
		tf.position.y = 0.52
		tf.rotation.x = deg_to_rad(-90.0)
		tf.scale = Vector3(1, 1, 1.7)
		var tp: Vector3 = d["torch_at"]
		tp.y = npc.global_position.y
		await _go_w(npc, tp, 2.6, false, 0.15)
		if is_instance_valid(npc):
			_look_at(npc, fire_at)
			_look_at(Game.player, fire_at)
			_pose(npc, "slap", {"anim": "idle", "at": fire_at + (npc.global_position - fire_at).normalized() * 0.7 - Vector3.UP * 0.1})
			await _wait(0.75)
	Sfx.play("fire", fire_at, 0.8)
	var f = Node3D.new()
	root.add_child(f)
	f.global_position = fire_at
	f.scale = Vector3.ONE * 0.1
	for k in 5:
		var fb = VFX.fireball([1.0, 0.8, 0.7, 0.6, 0.5][k])
		f.add_child(fb)
		fb.rotation.x = deg_to_rad(-90.0)
		fb.rotation.z = [0.0, 0.22, -0.25, 0.1, -0.12][k]
		fb.scale = Vector3(1.0, 1.0, [2.6, 3.0, 2.4, 3.6, 4.2][k])
		fb.position = Vector3([0.0, 0.35, -0.38, 0.12, -0.1][k], [0.3, 0.4, 0.35, 0.9, 1.3][k], [0.0, -0.2, 0.15, 0.25, -0.1][k])
	var l = OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = 3.0
	l.omni_range = 16.0
	l.position.y = 1.0
	f.add_child(l)
	f.create_tween().tween_property(f, "scale", Vector3.ONE, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# duman sütunu: işaret uzaktan görülsün
	# duman sütunu: koyu topaklar yükselir, büyür, dağılır (işaret uzaktan görülsün)
	var sm = SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 6
	var smoke = func():
		if not is_instance_valid(f):
			return
		var mm = StandardMaterial3D.new()
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.roughness = 1.0
		var g = randf_range(0.3, 0.46)
		mm.albedo_color = Color(g, g * 0.97, g * 0.95, 0.85)
		var puff = Node3D.new()
		root.add_child(puff)
		for k in 4:   # topak: iç içe geçmiş birkaç küre (tek top gibi durmasın)
			var ball = MeshInstance3D.new()
			ball.mesh = sm
			ball.material_override = mm
			ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ball.position = Vector3(randf_range(-0.38, 0.38), randf_range(-0.3, 0.3), randf_range(-0.38, 0.38)) if k > 0 else Vector3.ZERO
			ball.scale = Vector3.ONE * (1.0 if k == 0 else randf_range(0.55, 0.85))
			puff.add_child(ball)
		puff.global_position = f.global_position + Vector3(randf_range(-0.3, 0.3), 2.2, randf_range(-0.3, 0.3))
		puff.scale = Vector3.ONE * randf_range(0.7, 1.0)
		var top = puff.position + Vector3(randf_range(1.5, 3.5), randf_range(20.0, 26.0), randf_range(-1.0, 1.0))
		var tw = puff.create_tween().set_parallel(true)
		tw.tween_property(puff, "position", top, 9.0)
		tw.tween_property(puff, "scale", Vector3.ONE * randf_range(3.2, 4.4), 9.0)
		tw.tween_property(mm, "albedo_color:a", 0.0, 4.0).set_delay(5.0)
		tw.chain().tween_callback(puff.queue_free)
	var tm = Timer.new()
	tm.wait_time = 0.45
	tm.autostart = true
	f.add_child(tm)
	tm.timeout.connect(smoke)
	await _wait(1.3)
	if is_instance_valid(torch):
		torch.queue_free()
	if is_instance_valid(npc):
		_clear_pose(npc)
		_look_at(npc, Game.player.global_position)
		if npc is QuestNPC:
			npc.set_physics_process(true)
	_release_player()
	busy_run = false


# ---------------------------------------------------------------------- av
## Av alanına hayvanları salar. kinds boşsa oranın biyomundan seçilir (geyik / yaban domuzu / tavşan)
func hunt_begin(c: Vector3, n: int, label: String, want := "") -> void:
	var WL = preload("res://scripts/world/wildlife.gd")
	var kind = want
	if kind == "":
		var opts = (WL.BY_BIOME.get(Game.biome_at(c.x, c.z), []) as Array).filter(func(x): return Prey.DEF.has(x))
		kind = opts.pick_random() if not opts.is_empty() else "tavşan"
	hunt_d["kind"] = kind
	hunt_d["label"] = label
	hunt_d["prey"] = []
	hunt_d["hung"] = int(hunt_d.get("hung", 0))
	for i in n:
		var a = TAU * i / float(n) + randf_range(-0.4, 0.4)
		var q = Missions.open_ground(c + Vector3(cos(a), 0, sin(a)) * randf_range(6.0, 16.0), 12.0)
		q.y = Game.terrain_height(q.x, q.z)
		var p = Prey.new()
		p.kind = kind
		p.position = q
		p.on_dead = _prey_dead
		get_tree().current_scene.add_child(p)
		Missions.pickups.append(p)
		hunt_d["prey"].append(p)
	if hunt_d.has("rack") and not hunt_d.has("rack_it"):
		_rack_item()


func _rack_item() -> void:
	var it = {"pos": hunt_d["rack_front"] + Vector3.UP * 0.4, "radius": 2.6, "kind": "quest", "label": "[F] Avı askıya as", "qkey": Missions._key(), "qi": 90, "work": "rack", "node": hunt_d["root"]}
	hunt_d["rack_it"] = it
	Interact.add(it)


func _prey_dead(p: Prey) -> void:
	var it = {"pos": p.global_position + Vector3.UP * 0.3, "radius": 2.6, "kind": "quest", "label": "[F] Avı omuzla", "qkey": Missions._key(), "qi": 80, "work": "carcass", "node": p, "silent": true}
	Interact.add(it)
	p.tree_exiting.connect(func(): Interact.items.erase(it))
	Hud.msg("%s yere serildi. Omuzlayıp avcının askısına götür." % p.display, Color(0.8, 1, 0.8))


## Görev işareti: omuzda av varsa askı, yoksa en yakın yaşayan / yerdeki av
func hunt_marker(fallback: Vector3) -> Vector3:
	if hunt_d.is_empty():
		return fallback
	if rider_kind == "prey" and is_instance_valid(rider) and hunt_d.has("rack_front"):
		return hunt_d["rack_front"]
	var best = fallback
	var bd = 1e9
	for p in hunt_d.get("prey", []):
		if is_instance_valid(p) and not p.has_meta("hung"):
			var dd: float = p.global_position.distance_to(Game.player.global_position) * (0.3 if p.dead else 1.0)
			if dd < bd:
				bd = dd
				best = p.global_position
	return best


## Diz çök, avı bacaklarından kavra, omzuna at
func _act_carcass(it: Dictionary) -> void:
	var pl = Game.player
	var p: Prey = it["node"]
	if is_instance_valid(rider):
		Hud.msg("Omzun dolu: önce taşıdığını bırak.", Color(1, 0.8, 0.5))
		Interact.add(it)
		return
	await _stand_at(p, 0.75)
	_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": p.global_position + Vector3.UP * 0.25, "lift": 0.0})
	await _wait(0.6)
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", p.global_position, 0.7, 0.8)
	p.set_physics_process(false)
	var body_y: float = {"geyik": 1.12, "domuz": 0.62, "tavşan": 0.22}.get(p.kind, 0.6)
	var sc: float = pl.model.age_scale
	rider_off = Vector3(0.0, 1.36 if p.kind != "tavşan" else 1.05, -0.3 if p.kind != "tavşan" else 0.3)   # ense arkasında, omuzlara yatık
	rider_yaw = PI * 0.5
	var from = p.global_position
	var an_from: Vector3 = p.an.rotation
	var an_p0: Vector3 = p.an.position
	var t := 0.0
	while t < 0.7:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.7, t)
		var tgt = pl.global_position + Vector3.UP * rider_off.y * sc + _fd(pl) * rider_off.z * sc
		p.global_position = from.lerp(tgt, k) + Vector3.UP * sin(k * PI) * 0.3
		p.rotation.y = lerp_angle(p.rotation.y, pl.facing + rider_yaw, k)
		# sırtüstü değil: karnı omuzda, bacaklar öne sarkar
		p.an.rotation = an_from.lerp(Vector3(0, 0, 0), k)
		p.an.position = an_p0.lerp(Vector3(0, -body_y + 0.12, 0), k)
		await get_tree().process_frame
	for lg in p.an.legs:
		lg[0].rotation.x = 0.0
		lg[0].rotation.z = 0.0
	rider = p
	rider_kind = "prey"
	_clear_pose(pl)
	Hud.float_text("Av omuzda", Color(0.8, 1, 0.8))


## Avı askıya as: arka ayaklarından kancaya, baş aşağı
func _act_rack(it: Dictionary) -> void:
	var pl = Game.player
	it["silent"] = true
	if rider_kind != "prey" or not is_instance_valid(rider):
		Hud.msg("Askı boş. Önce avı vur ve omuzla.", Color(1, 0.85, 0.6))
		Interact.add(it)
		return
	var p: Prey = rider
	var slot_i = int(hunt_d.get("hung", 0))
	var bar: Vector3 = hunt_d["rack"] + Vector3((slot_i % 3 - 1) * 0.8, 0, 0)
	var front: Vector3 = hunt_d["rack_front"] + Vector3((slot_i % 3 - 1) * 0.8, 0, -0.25)
	front.y = pl.global_position.y
	await _go_w(pl, front, 2.2, false, 0.12)
	_look_at(pl, bar)
	rider = null
	rider_kind = ""
	var body_y: float = {"geyik": 1.12, "domuz": 0.62, "tavşan": 0.22}.get(p.kind, 0.6)
	var half: float = {"geyik": 0.75, "domuz": 0.6, "tavşan": 0.25}.get(p.kind, 0.5)
	_pose(pl, "slap", {"anim": "idle", "at": bar - Vector3.UP * 0.35 + Vector3(0, 0, 0.25)})
	var from = p.global_position
	var from_rot = p.an.rotation
	var from_p = p.an.position
	var yaw0 = p.rotation.y
	var tgt = bar - Vector3.UP * (half + 0.22)
	var t := 0.0
	while t < 0.8:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.8, t)
		p.global_position = from.lerp(tgt, k)
		p.rotation.y = lerp_angle(yaw0, 0.0, k)
		# baş aşağı: gövde ekseni dikleşir; gövde merkezi kancanın tam altına gelsin
		p.an.rotation = from_rot.lerp(Vector3(-PI * 0.5, 0, 0), k)
		p.an.position = from_p.lerp(Vector3(0, 0, body_y), k)
		await get_tree().process_frame
	for lg in p.an.legs:
		lg[0].rotation.x = 0.35 if lg[0].position.z > 0.0 else -0.5
	p.set_meta("hung", true)
	Sfx.play("pickup", bar, 0.6, 1.0)
	hunt_d["hung"] = slot_i + 1
	# hafifçe sallanır
	var tw = p.create_tween()
	tw.tween_property(p, "rotation:z", 0.09, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(p, "rotation:z", -0.06, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(p, "rotation:z", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	await _wait(0.5)
	it["silent"] = false
	var left = (hunt_d.get("prey", []) as Array).filter(func(x): return is_instance_valid(x) and not x.has_meta("hung")).size()
	if left > 0:
		_rack_item()
	else:
		hunt_d.erase("rack_it")


# ---------------------------------------------------------------------- nöbet: fenerler
## Yol feneri: direk + kol + kâğıt fener (sönük). Yakılınca ışır ve gece boyu yanar.
func _build_lamp(root: Node3D) -> void:
	var b = MB.new()
	var wood = Color(0.3, 0.22, 0.16)
	b.add("cyl", Vector3(0, 1.2, 0), Vector3(0.11, 2.4, 0.11), wood, Vector3.ZERO, 6)
	b.add("box", Vector3(0, 0.08, 0), Vector3(0.36, 0.16, 0.36), Color(0.5, 0.48, 0.45))
	b.add("box", Vector3(0.28, 2.3, 0), Vector3(0.7, 0.07, 0.07), wood)
	b.add("box", Vector3(0.16, 2.12, 0), Vector3(0.05, 0.4, 0.05), wood, Vector3(0, 0, 40))
	b.add("cyl", Vector3(0.55, 2.2, 0), Vector3(0.012, 0.16, 0.012), Color(0.15, 0.15, 0.15), Vector3.ZERO, 4)
	b.add("box", Vector3(0.55, 2.11, 0), Vector3(0.3, 0.04, 0.3), Color(0.12, 0.1, 0.09))
	b.add("box", Vector3(0.55, 1.67, 0), Vector3(0.26, 0.04, 0.26), Color(0.12, 0.1, 0.09))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.add("box", Vector3(0.55 + sx * 0.125, 1.89, sz * 0.125), Vector3(0.02, 0.42, 0.02), Color(0.12, 0.1, 0.09))
	_part(root, b)
	var pm = StandardMaterial3D.new()
	pm.albedo_color = Color(0.62, 0.58, 0.5)
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var paper = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.24, 0.4, 0.24)
	paper.mesh = bm
	paper.material_override = pm
	paper.position = Vector3(0.55, 1.89, 0)
	root.add_child(paper)
	root.set_meta("paper", paper)
	var body = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(0.24, 2.4, 0.24)
	cs.shape = sh
	cs.position.y = 1.2
	body.add_child(cs)
	root.add_child(body)


## Fenerin altına geç, çakmak taşını çak, fitili tutuştur
func _act_lamp(it: Dictionary) -> void:
	var pl = Game.player
	var root: Node3D = it["node"]
	var paper: MeshInstance3D = root.get_meta("paper")
	var lp = paper.global_position
	var under = Vector3(lp.x, pl.global_position.y, lp.z) + (pl.global_position - lp).slide(Vector3.UP).normalized() * 0.55
	await _go_w(pl, under, 2.4, false, 0.1)
	_look_at(pl, lp)
	_pose(pl, "slap", {"anim": "idle", "at": lp - Vector3.UP * 0.28})
	await _wait(0.45)
	for k in 2:
		Sfx.play("pickup", lp, 1.9, 0.5)
		FX.burst(lp - Vector3.UP * 0.25, {"amount": 7, "life": 0.25, "size": 0.035, "vmin": 0.8, "vmax": 2.4, "gravity": Vector3(0, -6, 0), "colors": [Color(1, 0.9, 0.5, 1), Color(1, 0.6, 0.2, 0)]})
		await _wait(0.22)
	var pm: StandardMaterial3D = paper.material_override
	pm.emission_enabled = true
	pm.emission = Color(1.0, 0.72, 0.36)
	pm.emission_energy_multiplier = 0.0
	pm.albedo_color = Color(1.0, 0.86, 0.6)
	var l = OmniLight3D.new()
	l.light_color = Color(1.0, 0.72, 0.4)
	l.light_energy = 0.0
	l.omni_range = 9.0
	paper.add_child(l)
	var tw = paper.create_tween().set_parallel(true)
	tw.tween_property(pm, "emission_energy_multiplier", 2.4, 0.5)
	tw.tween_property(l, "light_energy", 1.6, 0.5)
	await _wait(0.55)


# ---------------------------------------------------------------------- nöbet: yük arama
## Yolcu bohçasını yere indirir; oyuncu diz çöküp açar, içindeki ortaya çıkar (what: "rice" / "cloth" / "fish" / "tags")
func search_pack(npc: Node3D, what: String) -> void:
	var pl = Game.player
	if not is_instance_valid(npc):
		return
	busy_run = true
	_lock(16.0)
	if npc is QuestNPC:
		npc.set_physics_process(false)
	var to = (pl.global_position - npc.global_position).slide(Vector3.UP).normalized()
	var gp = npc.global_position + to * 0.75
	gp.y = Game.ground_height(gp.x, gp.z)
	_look_at(npc, pl.global_position)
	var pack = Node3D.new()
	get_tree().current_scene.add_child(pack)
	_own(pack, true)
	var cloth = Color(0.32, 0.42, 0.55) if what != "tags" else Color(0.3, 0.3, 0.34)
	var b = MB.new()
	b.add("sphere", Vector3(0, 0.2, 0), Vector3(0.62, 0.42, 0.56), cloth, Vector3.ZERO, 10)
	var knot = Node3D.new()
	pack.add_child(knot)
	var kb = MB.new()
	kb.add("sphere", Vector3(0, 0.44, 0), Vector3(0.16, 0.12, 0.16), cloth.lightened(0.12), Vector3.ZERO, 7)
	for sx in [-1.0, 1.0]:
		kb.add("cone", Vector3(sx * 0.12, 0.5, 0), Vector3(0.1, 0.2, 0.04), cloth.lightened(0.12), Vector3(0, 0, -50.0 * sx), 4)
	_part(knot, kb)
	_part(pack, b)
	# npc sırtından indirir
	pack.global_position = npc.global_position + Vector3.UP * 1.1 - _fd(npc) * 0.25
	npc.model.play("pickup", 0.15, 1.0, true)
	var from = pack.global_position
	var t := 0.0
	while t < 0.6:
		t += get_process_delta_time()
		pack.global_position = from.lerp(gp, smoothstep(0.0, 0.6, t))
		await get_tree().process_frame
	var sp = gp + to * 0.7
	sp.y = pl.global_position.y
	await _go_w(pl, sp, 2.0, false, 0.1)
	_look_at(pl, gp)
	_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": gp + Vector3.UP * 0.3, "lift": 0.0})
	await _wait(0.7)
	Sfx.play("pickup", gp, 0.8, 1.2)
	knot.create_tween().tween_property(knot, "scale", Vector3(1.6, 0.2, 1.6), 0.25)
	# içindekiler: bohça açılır, mallar görünür
	var inside = Node3D.new()
	pack.add_child(inside)
	var ib = MB.new()
	match what:
		"tags":
			pass
		"fish":
			for k in 3:
				ib.add("sphere", Vector3(-0.12 + k * 0.12, 0.42, 0.02 * k), Vector3(0.1, 0.07, 0.34), Color(0.62, 0.68, 0.74).darkened(k * 0.06), Vector3(0, 12.0 * k - 10.0, 0), 7)
				ib.add("cone", Vector3(-0.12 + k * 0.12, 0.42, 0.2 + 0.02 * k), Vector3(0.1, 0.1, 0.02), Color(0.5, 0.56, 0.62), Vector3(90, 0, 0), 4)
		"cloth":
			for k in 3:
				ib.add("cyl", Vector3(-0.14 + k * 0.14, 0.44, 0), Vector3(0.13, 0.4, 0.13), [Color(0.75, 0.25, 0.3), Color(0.9, 0.8, 0.5), Color(0.3, 0.5, 0.45)][k], Vector3(90, 0, 0), 8)
		_:
			for k in 2:
				ib.add("sphere", Vector3(-0.1 + k * 0.2, 0.44, 0), Vector3(0.24, 0.2, 0.3), Color(0.88, 0.84, 0.72), Vector3.ZERO, 8)
				ib.add("cyl", Vector3(-0.1 + k * 0.2, 0.55, 0), Vector3(0.07, 0.06, 0.07), Color(0.7, 0.6, 0.4), Vector3.ZERO, 6)
	_part(inside, ib)
	if what == "tags":
		for k in 5:
			var tg = _tag_mesh()
			inside.add_child(tg)
			tg.position = Vector3(-0.16 + k * 0.08, 0.46 + (k % 2) * 0.012, 0.03 * (k % 3))
			tg.rotation = Vector3(deg_to_rad(-80.0), deg_to_rad(k * 9.0 - 18.0), 0)
	inside.scale = Vector3(1, 0.05, 1)
	inside.create_tween().tween_property(inside, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(0.9)
	if what == "tags":
		Hud.float_text("Patlayıcı mühürler!", Color(1, 0.5, 0.4))
		Sfx.play("alarm", gp, 1.0, 0.6)
	else:
		Hud.float_text({"fish": "Kurutulmuş balık", "cloth": "Top top kumaş"}.get(what, "Pirinç keseleri"), Color(0.8, 1, 0.8))
	await _wait(0.6)
	_clear_pose(pl)
	pl.model.play("idle", 0.25)
	if npc is QuestNPC and is_instance_valid(npc):
		npc.set_physics_process(true)
	_release_player()
	busy_run = false


# ====================================================================== 5. adım (2): balık, onarım, inşaat, ders
static var test_auto := false   # testte olta kendiliğinden çekilir


func _site_jobs(kind: String, root: Node3D, b: MB, d: Dictionary, c: Vector3, gy: Callable, solid: Callable) -> void:
	var wood = Color(0.5, 0.37, 0.24)
	var dark = wood.darkened(0.3)
	if kind == "fish_dock":
		# iskele suya doğru uzanır (en alçak yön = su)
		var best_a := 0.0
		var low := 1e9
		for k in 16:
			var a = TAU * k / 16.0
			var h = Game.terrain_height(c.x + cos(a) * 9.0, c.z + sin(a) * 9.0)
			if h < low:
				low = h
				best_a = a
		var dir = Vector3(cos(best_a), 0, sin(best_a))
		var piv = Node3D.new()
		root.add_child(piv)
		piv.rotation.y = atan2(-dir.x, -dir.z)   # yerel -Z = su
		var wl = maxf(Game.water_level(c.x + dir.x * 7.0, c.z + dir.z * 7.0), 0.0)
		var dy = maxf(wl + 0.5 - c.y, 0.14)
		var pb = MB.new()
		for i in 10:
			pb.add("box", Vector3(0, dy, 1.4 - i * 1.0), Vector3(1.9, 0.08, 0.93), wood.darkened((i % 3) * 0.07))
		for sx in [-0.88, 0.88]:
			pb.add("box", Vector3(sx, dy - 0.1, -3.1), Vector3(0.12, 0.14, 10.0), dark)
			for z in [0.6, -1.8, -4.2, -6.6, -7.9]:
				pb.add("cyl", Vector3(sx, dy - 0.75, z), Vector3(0.16, 2.3, 0.16), dark, Vector3.ZERO, 6)
		pb.add("cyl", Vector3(0.75, dy + 0.4, -7.7), Vector3(0.2, 0.8, 0.2), dark.lightened(0.1), Vector3.ZERO, 7)   # bağlama babası
		pb.add("cyl", Vector3(0.75, dy + 0.3, -7.7), Vector3(0.34, 0.14, 0.34), Color(0.78, 0.7, 0.5), Vector3.ZERO, 8)   # halat
		# sepet (iskele ucunda) + kova + olta sehpası (kıyıda)
		var bk = Vector3(-0.6, dy + 0.04, -5.6)
		pb.add("cyl", bk + Vector3(0, 0.2, 0), Vector3(0.56, 0.4, 0.56), Color(0.72, 0.6, 0.38), Vector3.ZERO, 10)
		pb.add("cyl", bk + Vector3(0, 0.39, 0), Vector3(0.5, 0.03, 0.5), Color(0.3, 0.24, 0.16), Vector3.ZERO, 10)
		pb.add("cyl", bk + Vector3(0, 0.1, 0), Vector3(0.6, 0.05, 0.6), Color(0.5, 0.4, 0.25), Vector3.ZERO, 10)
		var ry = Game.ground_height(c.x, c.z) - c.y
		for sx in [-0.5, 0.5]:
			pb.add("cyl", Vector3(2.0 + sx, ry + 0.5, 2.2), Vector3(0.07, 1.0, 0.07), dark, Vector3(0, 0, sx * 30.0), 5)
		pb.add("cyl", Vector3(2.0, ry + 0.92, 2.2), Vector3(0.05, 1.3, 0.05), dark, Vector3(0, 0, 90), 5)
		for k in 2:
			pb.add("cyl", Vector3(1.8 + k * 0.4, ry + 1.5, 1.6), Vector3(0.03, 2.6, 0.03), Color(0.72, 0.62, 0.3), Vector3(28, 0, 0), 5)
		_part(piv, pb)
		var body = StaticBody3D.new()
		piv.add_child(body)
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = Vector3(1.9, 0.3, 10.0)
		cs.shape = sh
		cs.position = Vector3(0, dy - 0.11, -3.1)
		body.add_child(cs)
		d["piv"] = piv
		d["dy"] = dy
		d["dir"] = dir
		d["wl"] = wl
		d["start"] = piv.to_global(Vector3(0, dy + 0.04, 1.2))
		d["cast_at"] = piv.to_global(Vector3(0.15, dy + 0.04, -7.0))
		d["mid"] = piv.to_global(Vector3(0, dy + 0.04, -3.0))
		d["basket"] = piv.to_global(bk + Vector3(0, 0.42, 0))
		d["npc_at"] = piv.to_global(Vector3(-2.0, 0, 2.0))
		d["face"] = piv.to_global(Vector3(-2.0, 0, -8.0))
		d["kind"] = kind
		job_d = d
	elif kind == "repair_house":
		# fırtınanın hırpaladığı kulübe: ön duvarda kırık tahtalar, yanda kereste istifi
		var g0: float = gy.call(0, 0)
		var wall = Color(0.62, 0.5, 0.36)
		b.add("box", Vector3(0, g0 + 1.2, -1.6), Vector3(4.4, 2.4, 0.12), wall)
		for sx in [-2.2, 2.2]:
			b.add("box", Vector3(sx, g0 + 1.2, -0.1), Vector3(0.12, 2.4, 3.0), wall.darkened(0.06))
		b.add("box", Vector3(0, g0 + 0.06, -0.1), Vector3(4.4, 0.12, 3.0), dark)
		b.add("prism", Vector3(0, g0 + 2.95, -0.1), Vector3(5.2, 1.1, 3.8), Color(0.34, 0.3, 0.28))
		for sx in [-2.2, 2.2]:
			b.add("box", Vector3(sx, g0 + 1.2, 1.4), Vector3(0.18, 2.4, 0.18), dark)
		b.add("box", Vector3(0, g0 + 2.34, 1.4), Vector3(4.5, 0.16, 0.16), dark)
		b.add("box", Vector3(0, g0 + 0.1, 1.4), Vector3(4.5, 0.16, 0.16), dark)
		# ön duvar: 8 tahta, 4'ü kırık (kalan yarım parça + boşluk)
		var gaps = []
		for i in 8:
			var x = -1.925 + i * 0.55
			if i in [1, 3, 4, 6]:
				b.add("box", Vector3(x, g0 + 0.45 + (i % 2) * 0.2, 1.4), Vector3(0.5, 0.7 + (i % 2) * 0.4, 0.07), wall.darkened(0.12), Vector3(0, 0, (i % 3 - 1) * 5.0))
				gaps.append(c + Vector3(x, g0, 1.4))
			else:
				b.add("box", Vector3(x, g0 + 1.2, 1.4), Vector3(0.5, 2.2, 0.07), wall.darkened((i % 3) * 0.05))
		# yere saçılmış kırık parçalar
		for k in 5:
			b.add("box", Vector3(-1.6 + k * 0.8, gy.call(-1.6 + k * 0.8, 2.3) + 0.04, 2.1 + (k % 2) * 0.5), Vector3(0.45, 0.05, 0.14), wall.darkened(0.2), Vector3(0, k * 37.0, 0))
		solid.call(Vector3(0, g0 + 1.2, -0.1), Vector3(4.4, 2.4, 3.1))
		var lp = Vector3(4.2, gy.call(4.2, 2.6), 2.6)
		for k in 6:
			b.add("box", lp + Vector3((k / 3) * 0.06, 0.05 + (k / 3) * 0.09, (k % 3) * 0.56 - 0.56), Vector3(2.2, 0.07, 0.5), Color(0.8, 0.66, 0.44).darkened((k % 2) * 0.06))
		for sz in [-0.9, 0.9]:
			b.add("box", lp + Vector3(0, 0.0, sz * 0.5), Vector3(0.14, 0.1, 0.14), dark)
		solid.call(lp + Vector3(0, 0.12, 0), Vector3(2.2, 0.24, 1.7))
		d["gaps"] = gaps
		d["nrm"] = Vector3(0, 0, 1)
		d["pile"] = c + lp
		d["npc_at"] = c + Vector3(-3.4, 0, 2.6)
		d["face"] = c + Vector3(0, 0, 1.4)
		d["kind"] = kind
		job_d = d
	elif kind == "build_lot":
		# inşaat alanı: kazıklarla çevrili temel, köşe taşları, tomruk istifi, testere tezgâhı
		var g1: float = gy.call(0, 0)
		for sx in [-1.5, 1.5]:
			for sz in [-1.5, 1.5]:
				b.add("box", Vector3(sx, g1 + 0.1, sz), Vector3(0.5, 0.22, 0.5), Color(0.58, 0.56, 0.52))
				b.add("cyl", Vector3(sx * 1.5, gy.call(sx * 1.5, sz * 1.5) + 0.3, sz * 1.5), Vector3(0.05, 0.6, 0.05), dark, Vector3.ZERO, 4)
		for k in 4:
			var a = k * PI * 0.5
			b.add("box", Vector3(cos(a) * 2.25, g1 + 0.5, sin(a) * 2.25), Vector3(0.015, 0.015, 4.5), Color(0.85, 0.8, 0.6), Vector3(0, -rad_to_deg(a), 0))   # ip
		var lp2 = Vector3(4.6, gy.call(4.6, 0.5), 0.5)
		for k in 7:
			b.add("cyl", lp2 + Vector3(0, 0.14 + (k / 4) * 0.25, (k % 4) * 0.3 - 0.45 + (k / 4) * 0.15), Vector3(0.27, 3.0, 0.27), Color(0.55, 0.4, 0.26).darkened((k % 3) * 0.06), Vector3(0, 0, 90), 7)
		solid.call(lp2 + Vector3(0, 0.25, 0), Vector3(3.0, 0.5, 1.3))
		var sp = Vector3(-4.2, gy.call(-4.2, 1.5), 1.5)
		for sx in [-0.6, 0.6]:
			for sz in [-1.0, 1.0]:
				b.add("box", sp + Vector3(sx, 0.35, sz * 0.2), Vector3(0.07, 0.75, 0.07), dark, Vector3(sz * 16.0, 0, 0))
			b.add("box", sp + Vector3(sx, 0.7, 0), Vector3(0.1, 0.08, 0.7), dark)
		b.add("box", sp + Vector3(0, 0.78, 0), Vector3(1.9, 0.07, 0.3), Color(0.8, 0.66, 0.44))
		solid.call(sp + Vector3(0, 0.4, 0), Vector3(1.6, 0.8, 0.6))
		d["stage"] = 0
		d["g"] = g1
		d["pile"] = c + lp2 + Vector3(0, 0, 1.2)
		d["npc_at"] = c + Vector3(-2.6, 0, 2.8)
		d["face"] = c
		d["kind"] = kind
		job_d = d
	elif kind == "class_yard":
		# eğitim alanı: üç hedef kütüğü, önlerinde atış çizgisi, yanda kunai sehpası
		var tg = []
		for i in 3:
			var x = -3.0 + i * 3.0
			var g2: float = gy.call(x, -4.0)
			b.add("cyl", Vector3(x, g2 + 0.9, -4.0), Vector3(0.5, 1.8, 0.5), wood, Vector3.ZERO, 9)
			b.add("cyl", Vector3(x, g2 + 1.81, -4.0), Vector3(0.46, 0.02, 0.46), Color(0.78, 0.66, 0.46), Vector3.ZERO, 9)
			# hedef tahtası: iç içe halkalar
			b.add("cyl", Vector3(x, g2 + 1.25, -3.72), Vector3(0.62, 0.05, 0.62), Color(0.92, 0.9, 0.84), Vector3(90, 0, 0), 14)
			b.add("cyl", Vector3(x, g2 + 1.25, -3.69), Vector3(0.42, 0.05, 0.42), Color(0.15, 0.14, 0.14), Vector3(90, 0, 0), 12)
			b.add("cyl", Vector3(x, g2 + 1.25, -3.66), Vector3(0.24, 0.05, 0.24), Color(0.92, 0.9, 0.84), Vector3(90, 0, 0), 10)
			b.add("cyl", Vector3(x, g2 + 1.25, -3.63), Vector3(0.1, 0.05, 0.1), Color(0.8, 0.16, 0.12), Vector3(90, 0, 0), 8)
			solid.call(Vector3(x, g2 + 0.9, -4.0), Vector3(0.5, 1.8, 0.5))
			tg.append(c + Vector3(x, g2 + 1.25, -3.6))
		b.add("box", Vector3(0, gy.call(0, 1.5) + 0.02, 1.5), Vector3(8.4, 0.03, 0.14), Color(0.9, 0.88, 0.8))   # atış çizgisi
		var kp = Vector3(5.0, gy.call(5.0, 1.8), 1.8)
		b.add("box", kp + Vector3(0, 0.75, 0), Vector3(1.1, 0.07, 0.5), wood)
		for sx in [-0.45, 0.45]:
			b.add("box", kp + Vector3(sx, 0.37, 0), Vector3(0.08, 0.74, 0.44), dark)
		for k in 5:
			b.add("box", kp + Vector3(-0.36 + k * 0.18, 0.8, 0.02 * (k % 2)), Vector3(0.05, 0.015, 0.3), Color(0.25, 0.25, 0.28), Vector3(0, k * 7.0 - 14.0, 0))
		solid.call(kp + Vector3(0, 0.4, 0), Vector3(1.1, 0.8, 0.5))
		d["targets"] = tg
		var kids = []
		var knames = ["Öğrenci Mako", "Öğrenci Tsubame", "Öğrenci Kota", "Öğrenci Hibari", "Öğrenci Nobu"]
		knames.shuffle()
		for i in 3:
			var spec = Missions._npc("ogrenci%d" % i, knames[i], "kid")
			var kp0 = c + Vector3(-2.2 + i * 2.2, 0, 4.4)
			var kn = Missions._make_npc(spec, kp0)
			place_worker(kn, kp0, c + Vector3(-2.2 + i * 2.2, 0, -4.0))
			kids.append(kn)
		d["kids"] = kids
		d["line_z"] = 1.5
		d["c"] = c
		d["npc_at"] = c + Vector3(-5.2, 0, 2.6)
		d["face"] = c + Vector3(0, 0, 1.5)
		d["kind"] = kind
		job_d = d


## Nokta adımı başlar: iş yerindeki [F] noktalarını açar; yapılacak iş sayısını döndürür
func job_begin(work: String, n: int, label: String) -> int:
	if job_d.is_empty() or not is_instance_valid(job_d.get("root")):
		return n
	var root: Node3D = job_d["root"]
	var add = func(i: int, pos: Vector3, node: Node3D, extra: Dictionary, radius := 2.4) -> void:
		var it = {"pos": pos, "radius": radius, "kind": "quest", "label": label, "qkey": Missions._key(), "qi": i, "work": work, "node": node}
		it.merge(extra, true)
		Interact.add(it)
		node.tree_exiting.connect(func(): Interact.items.erase(it))
	if work == "block":
		var logs: Array = job_d.get("logs", [])
		n = logs.size()
		for i in n:
			add.call(i, logs[i].global_position, logs[i], {}, 3.0)
		return n
	if work == "stash":
		var chs: Array = (job_d.get("chests", []) as Array).filter(func(x): return is_instance_valid(x))
		job_d["chests"] = chs
		for i in chs.size():
			add.call(i, chs[i].global_position, chs[i], {"work": "loot"}, 3.0)
		add.call(9, job_d["stash"], job_d["stash_node"], {"label": "[F] Sandığı zulaya indir"}, 2.6)
		return maxi(1, chs.size())
	if work == "decoy":
		var bk = "%s:beacon0" % String(Missions.active().get("id", ""))
		if sites.has(bk):
			add.call(0, sites[bk]["torch_at"], sites[bk]["root"], {}, 3.2)
		return 1
	if work == "rob":
		make("sack", Missions.open_ground(job_d["sack_at"], 1.0), randf() * TAU, 0, label, {})
		return 1
	if work == "cage":
		add.call(0, job_d["front"], job_d["lock"], {}, 2.6)
		return 1
	if work == "pack":
		add.call(0, (job_d["goods"] as Node3D).global_position, job_d["goods"], {"mode": "load"})
		return 1
	match work:
		"fish":
			var dir: Vector3 = job_d["dir"]
			for i in n:
				var sp = Node3D.new()
				get_tree().current_scene.add_child(sp)
				Missions.step_nodes.append(sp)
				var q: Vector3 = job_d["cast_at"] + dir.rotated(Vector3.UP, [-0.55, 0.1, 0.6][i % 3]) * (4.4 + (i % 2) * 1.2)
				q.y = float(job_d["wl"]) + 0.03
				sp.global_position = q
				var ring = MeshInstance3D.new()
				var tm = TorusMesh.new()
				tm.inner_radius = 0.3
				tm.outer_radius = 0.36
				tm.rings = 20
				tm.ring_segments = 4
				ring.mesh = tm
				var rm = StandardMaterial3D.new()
				rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				rm.albedo_color = Color(1, 1, 1, 0.55)
				ring.material_override = rm
				ring.scale = Vector3(1, 0.1, 1)
				sp.add_child(ring)
				var tw = ring.create_tween().set_loops()
				tw.tween_property(ring, "scale", Vector3(2.0, 0.1, 2.0), 1.6).from(Vector3(0.5, 0.1, 0.5))
				var orb = Node3D.new()
				sp.add_child(orb)
				var fm = _fish_mesh(0.42, Color(0.08, 0.12, 0.16))
				orb.add_child(fm)
				fm.position = Vector3(0.55, -0.14, 0)
				var tw2 = orb.create_tween().set_loops()
				tw2.tween_property(orb, "rotation:y", -TAU, 3.4 + i * 0.5).from(0.0)
				add.call(i, job_d["mid"], sp, {}, 5.0)
		"plank":
			var gaps: Array = job_d["gaps"]
			n = mini(n, gaps.size())
			for i in n:
				var gp = Node3D.new()
				root.add_child(gp)
				gp.global_position = gaps[i]
				add.call(i, gaps[i] + Vector3(0, 0.4, 0.9), gp, {})
		"build":
			n = 4
			var st0 = Node3D.new()
			root.add_child(st0)
			job_d["label"] = label
			add.call(0, root.global_position + Vector3(0, 0.4, 2.6), st0, {}, 3.4)
		"teach":
			var kids: Array = job_d.get("kids", [])
			n = mini(n, kids.size())
			for i in n:
				add.call(i, kids[i].global_position + Vector3.UP * 0.4, kids[i], {"ti": i})
	return n


func _fish_mesh(len: float, col: Color) -> MeshInstance3D:
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(len * 0.24, len * 0.3, len), col, Vector3.ZERO, 8)
	b.add("sphere", Vector3(0, -len * 0.04, 0), Vector3(len * 0.2, len * 0.22, len * 0.9), col.lightened(0.35), Vector3.ZERO, 8)
	b.add("cone", Vector3(0, 0, len * 0.6), Vector3(len * 0.06, len * 0.34, len * 0.36), col.darkened(0.15), Vector3(-90, 0, 0), 4)
	b.add("cone", Vector3(0, len * 0.16, 0), Vector3(len * 0.03, len * 0.16, len * 0.3), col.darkened(0.15), Vector3(-20, 0, 0), 4)
	b.add("sphere", Vector3(len * 0.1, len * 0.04, -len * 0.36), Vector3(len * 0.05, len * 0.05, len * 0.05), Color(0.05, 0.05, 0.05), Vector3.ZERO, 5)
	b.add("sphere", Vector3(-len * 0.1, len * 0.04, -len * 0.36), Vector3(len * 0.05, len * 0.05, len * 0.05), Color(0.05, 0.05, 0.05), Vector3.ZERO, 5)
	var m = MeshInstance3D.new()
	m.mesh = b.build(mat)
	return m


func _stretch(mi: Node3D, a: Vector3, b2: Vector3) -> void:
	var dv = b2 - a
	var ln = dv.length()
	if ln < 0.01:
		return
	var up = Vector3.UP if absf(dv.normalized().y) < 0.98 else Vector3.RIGHT
	mi.global_transform = Transform3D(Basis.looking_at(dv / ln, up), (a + b2) * 0.5)
	mi.scale = Vector3(1, 1, ln)


func _splash(at: Vector3, big := false) -> void:
	FX.burst(at, {"amount": 22 if big else 10, "life": 0.5, "size": 0.07, "dir": Vector3.UP, "spread": 40.0, "vmin": 1.5, "vmax": 4.5 if big else 2.6, "gravity": Vector3(0, -9, 0), "colors": [Color(0.85, 0.95, 1.0, 1), Color(0.7, 0.85, 1.0, 0)]})
	Sfx.play("water", at, 1.3 if not big else 1.0, 0.7)


## Balık tutma: iskelenin ucuna yürü, oltayı savur, şamandırayı izle; şamandıra batınca [F] ile çek.
## Erken çekersen balık ürker, geç kalırsan yemi alıp kaçar (nokta yeniden açılır).
func _act_fish(it: Dictionary) -> void:
	var pl = Game.player
	var spot: Node3D = it["node"]
	var d = job_d
	var caught := false
	if pl.global_position.distance_to(d["cast_at"]) > 1.5:
		if pl.global_position.y < float(d["cast_at"].y) - 0.3 or pl.global_position.distance_to(d["start"]) < pl.global_position.distance_to(d["cast_at"]):
			var s0: Vector3 = d["start"]
			s0.y = pl.global_position.y
			await _go_w(pl, s0, 2.6, false, 0.2)
			pl.global_position.y = float(d["start"].y)
		await _go_w(pl, d["cast_at"], 2.4, false, 0.15)
	pl.global_position.y = float(d["cast_at"].y)
	var sp = spot.global_position
	_look_at(pl, sp)
	_pose(pl, "give", {"anim": "idle", "w": 0.07})
	# olta: kamış + misina + şamandıra
	var rod = Node3D.new()
	add_child(rod)
	rod.top_level = true
	var rb = MB.new()
	rb.add("cyl", Vector3(0, 0, -1.3), Vector3(0.035, 2.9, 0.035), Color(0.74, 0.64, 0.3), Vector3(90, 0, 0), 5)
	rb.add("cyl", Vector3(0, 0, 0.0), Vector3(0.05, 0.4, 0.05), Color(0.3, 0.22, 0.16), Vector3(90, 0, 0), 5)
	_part(rod, rb)
	var line = MeshInstance3D.new()
	var lm = BoxMesh.new()
	lm.size = Vector3(0.008, 0.008, 1.0)
	line.mesh = lm
	var lmat = StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.albedo_color = Color(0.92, 0.92, 0.9)
	line.material_override = lmat
	add_child(line)
	line.top_level = true
	var bob = Node3D.new()
	add_child(bob)
	bob.top_level = true
	var bb = MB.new()
	bb.add("sphere", Vector3(0, 0.03, 0), Vector3(0.1, 0.1, 0.1), Color(0.9, 0.16, 0.12), Vector3.ZERO, 7)
	bb.add("sphere", Vector3(0, -0.02, 0), Vector3(0.1, 0.08, 0.1), Color(0.95, 0.95, 0.92), Vector3.ZERO, 7)
	bb.add("cyl", Vector3(0, 0.12, 0), Vector3(0.012, 0.12, 0.012), Color(0.9, 0.16, 0.12), Vector3.ZERO, 4)
	_part(bob, bb)
	var rs = {"pitch": 0.6, "tip": Vector3.ZERO}
	var fd = _fd(pl)
	var place = func():
		var hand = _held(pl) if st.has(pl) and st[pl].has("hold") else pl.global_position + Vector3.UP * 1.05 + fd * 0.35
		var ax = (fd * cos(float(rs["pitch"])) + Vector3.UP * sin(float(rs["pitch"]))).normalized()
		rod.global_transform = Transform3D(Basis.looking_at(ax, Vector3.UP if absf(ax.y) < 0.98 else -fd), hand)
		rs["tip"] = hand + ax * 2.75
	place.call()
	bob.global_position = rs["tip"]
	# savurma: geri çek, öne fırlat
	var t := 0.0
	while t < 0.9:
		t += get_process_delta_time()
		rs["pitch"] = lerpf(0.6, 1.9, smoothstep(0.0, 0.4, t)) if t < 0.45 else lerpf(1.9, 0.45, smoothstep(0.45, 0.7, t))
		place.call()
		var k = smoothstep(0.5, 0.9, t)
		bob.global_position = rs["tip"].lerp(sp, k) + Vector3.UP * sin(k * PI) * 1.6
		_stretch(line, rs["tip"], bob.global_position + Vector3.UP * 0.1)
		await get_tree().process_frame
	_splash(sp)
	# bekleme: şamandıra hafifçe oynar; erken çekme = ürkütme
	var wait_t = randf_range(1.6, 3.4)
	var early := false
	t = 0.0
	await get_tree().process_frame
	while t < wait_t:
		t += get_process_delta_time()
		place.call()
		bob.global_position = sp + Vector3.UP * sin(t * 3.0) * 0.02
		_stretch(line, rs["tip"], bob.global_position + Vector3.UP * 0.1)
		if t > 0.3 and Input.is_action_just_pressed("interact") and not test_auto:
			early = true
			break
		await get_tree().process_frame
	if early:
		Hud.msg("Erken çektin: balık ürktü. Şamandıranın batmasını bekle.", Color(1, 0.85, 0.6))
	else:
		# vurdu: şamandıra batar
		_splash(sp, true)
		Hud.float_text("ÇEK!  [F]", Color(1, 0.9, 0.4))
		var win := 1.15
		t = 0.0
		while t < win:
			t += get_process_delta_time()
			place.call()
			bob.global_position = sp + Vector3.DOWN * (0.14 + sin(t * 26.0) * 0.04) + Vector3(sin(t * 17.0), 0, cos(t * 13.0)) * 0.06
			_stretch(line, rs["tip"], bob.global_position + Vector3.UP * 0.1)
			if Input.is_action_just_pressed("interact") or (test_auto and t > 0.35):
				caught = true
				break
			await get_tree().process_frame
		if not caught:
			Hud.msg("Geç kaldın: balık yemi alıp kaçtı.", Color(1, 0.85, 0.6))
	if caught:
		# asıl: kamış dikilir, balık sudan fırlar, sepete düşer
		var ln = randf_range(0.34, 0.56)
		var fish = _fish_mesh(ln, [Color(0.5, 0.58, 0.66), Color(0.62, 0.5, 0.3), Color(0.42, 0.56, 0.5)].pick_random())
		add_child(fish)
		fish.top_level = true
		fish.global_position = sp
		_splash(sp, true)
		var basket: Vector3 = d["basket"]
		t = 0.0
		while t < 1.5:
			t += get_process_delta_time()
			rs["pitch"] = lerpf(0.45, 1.35, smoothstep(0.0, 0.3, t))
			place.call()
			var k = smoothstep(0.0, 0.75, t)
			var hang: Vector3 = rs["tip"] + Vector3.DOWN * 0.9
			var fp = sp.lerp(hang, k) + Vector3.UP * sin(k * PI) * 0.8
			if t > 0.95:
				var k2 = smoothstep(0.95, 1.45, t)
				fp = hang.lerp(basket, k2) + Vector3.UP * sin(k2 * PI) * 0.3
			fish.global_position = fp
			fish.rotation = Vector3(-PI * 0.5 + sin(t * 30.0) * 0.25, pl.facing, sin(t * 24.0) * 0.4)
			bob.global_position = fp + Vector3.UP * 0.25
			_stretch(line, rs["tip"], bob.global_position)
			await get_tree().process_frame
		fish.rotation = Vector3(0, randf() * TAU, PI * 0.5)
		fish.global_position = basket + Vector3(randf_range(-0.1, 0.1), 0.02 * int(d.get("fish_n", 0)), randf_range(-0.1, 0.1))
		d["fish_n"] = int(d.get("fish_n", 0)) + 1
		_own(fish, true)
		Sfx.play("pickup", basket, 0.9, 0.9)
		Hud.float_text("+1 balık (%d cm)" % int(ln * 100.0), Color(0.6, 1, 0.6))
		spot.queue_free()
	rod.queue_free()
	line.queue_free()
	bob.queue_free()
	_clear_pose(pl)
	it["silent"] = not caught
	if not caught:
		await _wait(0.4)
		Interact.add(it)


## Onarım: istiften tahta al, boşluğa yerleştir, çekiçle üç kez çak
func _act_plank(it: Dictionary) -> void:
	var pl = Game.player
	var gap: Node3D = it["node"]
	var d = job_d
	var pile: Vector3 = d["pile"]
	var pp = pile + Vector3(0, 0, 1.3)
	pp.y = pl.global_position.y
	await _go_w(pl, pp, 3.0, false, 0.2)
	_look_at(pl, pile)
	_pose(pl, "grab_low", {"anim": "idle", "at": pile + Vector3.UP * 0.3, "lift": 0.0})
	await _wait(0.45)
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", pile, 0.7, 0.9)
	var plank = Node3D.new()
	add_child(plank)
	plank.top_level = true
	var pb = MB.new()
	pb.add("box", Vector3(0, 1.1, 0), Vector3(0.5, 2.2, 0.07), Color(0.82, 0.68, 0.45))
	pb.add("box", Vector3(0.1, 1.3, 0.036), Vector3(0.04, 0.5, 0.005), Color(0.7, 0.56, 0.36))
	_part(plank, pb)
	plank.global_position = pile + Vector3.UP * 0.3
	plank.rotation = Vector3(PI * 0.5, 0, 0)
	var t := 0.0
	while t < 0.5:
		t += get_process_delta_time()
		plank.global_position = plank.global_position.lerp(_held(pl) + Vector3.DOWN * 0.1, 0.3)
		plank.rotation.y = pl.facing
		await get_tree().process_frame
	# kucağında taşı
	var gp = gap.global_position
	var front = gp + Vector3(0, 0, 0.75)
	front.y = pl.global_position.y
	var carry = {"on": true}
	var follow = func():
		while carry["on"] and is_instance_valid(plank):
			plank.global_position = pl.global_position + Vector3.UP * 0.75 * pl.model.age_scale + _fd(pl) * 0.32 - _fd(pl).cross(Vector3.UP).normalized() * 0.9
			plank.rotation = Vector3(0, pl.facing + PI * 0.5, PI * 0.5)
			await get_tree().process_frame
	follow.call()
	_clear_pose(pl)
	await _go_w(pl, front, 2.6, false, 0.12)
	carry["on"] = false
	_look_at(pl, gp)
	# yerine kaldır
	var from = plank.global_position
	var from_b = plank.global_transform.basis
	t = 0.0
	_pose(pl, "give", {"anim": "idle", "w": 0.2})
	while t < 0.55:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.55, t)
		plank.global_transform = Transform3D(from_b.slerp(Basis.IDENTITY, k), from.lerp(gp + Vector3(0, 0.08, 0.04), k))
		await get_tree().process_frame
	# çekiç
	var ham = Node3D.new()
	pl.model.add_child(ham)
	var hb = MB.new()
	hb.add("cyl", Vector3(0, 0, 0), Vector3(0.035, 0.34, 0.035), Color(0.45, 0.32, 0.2), Vector3.ZERO, 5)
	hb.add("box", Vector3(0, 0.17, 0), Vector3(0.08, 0.08, 0.2), Color(0.35, 0.35, 0.38))
	_part(ham, hb)
	for k in 3:
		var nail = gp + Vector3([-0.12, 0.1, -0.05][k], [1.7, 1.2, 0.6][k], 0.1)
		_pose(pl, "slap", {"anim": "idle", "at": nail + Vector3(0, 0, 0.12)})
		t = 0.0
		while t < 0.46:
			t += get_process_delta_time()
			ham.global_position = _bone(pl, "RightHand")
			ham.global_rotation = Vector3(-0.9 + smoothstep(0.25, 0.42, t) * 1.3, pl.facing, 0)
			await get_tree().process_frame
		Sfx.play("hit", nail, 1.5, 0.6)
		FX.burst(nail, {"amount": 6, "life": 0.3, "size": 0.04, "vmin": 0.6, "vmax": 1.8, "gravity": Vector3(0, -6, 0), "colors": [Color(0.85, 0.75, 0.55, 1), Color(0.85, 0.75, 0.55, 0)]})
		var nb = MeshInstance3D.new()
		var nm = SphereMesh.new()
		nm.radius = 0.022
		nm.height = 0.03
		nb.mesh = nm
		plank.add_child(nb)
		nb.global_position = nail - Vector3(0, 0, 0.055)
		plank.global_position.z -= 0.012
		await _wait(0.16)
	ham.queue_free()
	plank.top_level = false
	var keep = plank.global_transform
	remove_child(plank)
	d["root"].add_child(plank)
	plank.global_transform = keep
	gap.queue_free()


## İnşaat: her [F] bir aşama — tomruğu omuzla, yerine dik / çat, usta çakarken tut. Yapı aşama aşama yükselir.
## İnşaat aşamasının parçaları (0 direk, 1 kiriş + döşeme, 2 duvar, 3 çatı)
func stage_mesh(b: MB, stage: int, g: float) -> void:
	var wood = Color(0.6, 0.45, 0.3)
	var dark = wood.darkened(0.25)
	match stage:
		0:
			for sx in [-1.5, 1.5]:
				for sz in [-1.5, 1.5]:
					b.add("cyl", Vector3(sx, g + 1.5, sz), Vector3(0.26, 2.8, 0.26), wood, Vector3.ZERO, 7)
		1:
			for k in 4:
				var a = k * PI * 0.5
				b.add("box", Vector3(cos(a) * 1.5, g + 2.85, sin(a) * 1.5), Vector3(0.2, 0.2, 3.4), dark, Vector3(0, -rad_to_deg(a), 0))
				b.add("box", Vector3(cos(a) * 1.5, g + 0.42, sin(a) * 1.5), Vector3(0.16, 0.16, 3.2), dark, Vector3(0, -rad_to_deg(a), 0))
			b.add("box", Vector3(0, g + 0.5, 0), Vector3(3.0, 0.08, 3.0), Color(0.78, 0.64, 0.44))
		2:
			for k in [1, 2, 3]:
				var a = k * PI * 0.5
				for j in 5:
					b.add("box", Vector3(cos(a) * 1.5 - sin(a) * (j - 2) * 0.58, g + 1.65, sin(a) * 1.5 + cos(a) * (j - 2) * 0.58), Vector3(0.06, 2.2, 0.54), Color(0.8, 0.67, 0.46).darkened((j % 2) * 0.06), Vector3(0, -rad_to_deg(a), 0))
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.05, g + 1.65, 1.5), Vector3(0.8, 2.2, 0.06), Color(0.8, 0.67, 0.46))
		_:
			b.add("prism", Vector3(0, g + 3.55, 0), Vector3(4.2, 1.3, 4.0), Color(0.36, 0.3, 0.26))
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.05, g + 3.25, 0), Vector3(1.9, 0.05, 4.1), Color(0.3, 0.25, 0.22), Vector3(0, 0, -sx * 31.0))
			b.add("box", Vector3(0, g + 4.22, 0), Vector3(0.2, 0.14, 4.2), dark)


func _act_build(it: Dictionary) -> void:
	var pl = Game.player
	var d = job_d
	var root: Node3D = d["root"]
	var stage = int(d.get("stage", 0))
	var g: float = d["g"]
	var c = root.global_position
	var pile: Vector3 = d["pile"]
	var pp = pile
	pp.y = pl.global_position.y
	await _go_w(pl, pp, 3.0, false, 0.25)
	_look_at(pl, pile - Vector3(0, 0, 1.2))
	_pose(pl, "grab_low", {"anim": "idle", "at": pile - Vector3(0, -0.3, 1.0), "lift": 0.0})
	await _wait(0.5)
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", pile, 0.6, 1.0)
	# omuzda tomruk / kalas
	var log = Node3D.new()
	add_child(log)
	log.top_level = true
	var lb = MB.new()
	lb.add("cyl", Vector3.ZERO, Vector3(0.24, 2.8, 0.24), Color(0.56, 0.41, 0.27), Vector3(90, 0, 0), 7)
	lb.add("cyl", Vector3(0, 0, 1.41), Vector3(0.22, 0.01, 0.22), Color(0.8, 0.68, 0.48), Vector3(90, 0, 0), 7)
	lb.add("cyl", Vector3(0, 0, -1.41), Vector3(0.22, 0.01, 0.22), Color(0.8, 0.68, 0.48), Vector3(90, 0, 0), 7)
	_part(log, lb)
	var carry = {"on": true}
	var follow = func():
		while carry["on"] and is_instance_valid(log):
			log.global_position = pl.global_position + Vector3.UP * 1.47 * pl.model.age_scale + _fd(pl).cross(Vector3.UP).normalized() * 0.2
			log.rotation = Vector3(0.08, pl.facing, 0)
			await get_tree().process_frame
	follow.call()
	_clear_pose(pl)
	var front = c + Vector3(0, 0, 2.5)
	front.y = pl.global_position.y
	await _go_w(pl, front, 2.3, false, 0.15)
	_look_at(pl, c)
	carry["on"] = false
	# usta yardıma gelir
	var boss = Missions.npcs.get("usta")
	if is_instance_valid(boss):
		stop_busy(boss)
		boss.set_physics_process(false)
		var bp = c + Vector3(-2.3, 0, 2.3)
		bp.y = boss.global_position.y
		_go_w(boss, bp, 2.6, false, 0.2)
	# aşamanın parçaları yerden yükselir
	var part = Node3D.new()
	root.add_child(part)
	var b = MB.new()
	stage_mesh(b, stage, g)
	_part(part, b)
	part.position.y = -3.2 if stage < 3 else 2.5
	if stage == 3:
		part.scale = Vector3.ONE * 0.6
	var from = log.global_position
	_pose(pl, "give", {"anim": "idle", "w": 0.25})
	var t := 0.0
	Sfx.play("pickup", c, 0.5, 1.0)
	while t < 1.3:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 1.3, t)
		part.position.y = lerpf(-3.2 if stage < 3 else 2.5, 0.0, k)
		if stage == 3:
			part.scale = Vector3.ONE * lerpf(0.6, 1.0, k)
		log.global_position = from.lerp(c + Vector3(0, g + 1.2, 1.5), k)
		log.scale = Vector3.ONE * (1.0 - k * 0.95)
		await get_tree().process_frame
	log.queue_free()
	FX.burst(c + Vector3(0, g + 0.2, 0), {"amount": 18, "life": 0.7, "size": 0.16, "dir": Vector3.UP, "spread": 80.0, "vmin": 0.8, "vmax": 2.4, "gravity": Vector3(0, -1.0, 0), "colors": [Color(0.6, 0.5, 0.38, 0.7), Color(0.6, 0.5, 0.38, 0)]})
	# usta çakar, oyuncu tutar
	if is_instance_valid(boss):
		_look_at(boss, c)
	for k in 3:
		var hp2 = c + Vector3(-1.5, g + 1.2, 1.5)
		if is_instance_valid(boss):
			_pose(boss, "slap", {"anim": "idle", "at": hp2})
		await _wait(0.42)
		Sfx.play("hit", hp2, 1.3, 0.7)
		FX.burst(hp2, {"amount": 5, "life": 0.3, "size": 0.04, "vmin": 0.6, "vmax": 1.6, "gravity": Vector3(0, -6, 0), "colors": [Color(0.85, 0.75, 0.55, 1), Color(0.85, 0.75, 0.55, 0)]})
		await _wait(0.2)
	if stage == 0:
		var body = StaticBody3D.new()
		root.add_child(body)
		for sx in [-1.5, 1.5]:
			for sz in [-1.5, 1.5]:
				var cs = CollisionShape3D.new()
				var sh = BoxShape3D.new()
				sh.size = Vector3(0.3, 2.8, 0.3)
				cs.shape = sh
				cs.position = Vector3(sx, g + 1.5, sz)
				body.add_child(cs)
	if stage == 2:
		var body2 = StaticBody3D.new()
		root.add_child(body2)
		for k in [1, 2, 3]:
			var a = k * PI * 0.5
			var cs2 = CollisionShape3D.new()
			var sh2 = BoxShape3D.new()
			sh2.size = Vector3(0.12, 2.4, 3.0)
			cs2.shape = sh2
			cs2.position = Vector3(cos(a) * 1.5, g + 1.6, sin(a) * 1.5)
			cs2.rotation.y = -a
			body2.add_child(cs2)
	_clear_pose(pl)
	if is_instance_valid(boss):
		_clear_pose(boss)
		_look_at(boss, pl.global_position)
		_say(boss, ["Direkler dimdik. Şimdi kirişler!", "Güzel, çatkı tamam. Duvar tahtalarını getir!", "Bir çatısı kaldı. Son tomruk!", ("İşte bu. Dört duvar, bir dam: kaçağa saray." if String(Missions.active().get("rjob", "")) == "hut" else "İşte bu! Köyün yeni ambarı hazır.")][stage], 3.0)
		boss.set_physics_process(true)
	d["stage"] = stage + 1
	if stage + 1 < 4:
		var nx = Node3D.new()
		root.add_child(nx)
		var it2 = {"pos": it["pos"], "radius": it["radius"], "kind": "quest", "label": it["label"], "qkey": it["qkey"], "qi": stage + 1, "work": "build", "node": nx}
		Interact.add(it2)
		nx.tree_exiting.connect(func(): Interact.items.erase(it2))
	(it["node"] as Node3D).queue_free()


## Kunai: düz uçar, hedefe saplanır (kalır)
func _throw_kunai(from: Vector3, to: Vector3, owner_root: Node3D) -> void:
	var k = Node3D.new()
	get_tree().current_scene.add_child(k)
	var kb = MB.new()
	kb.add("cone", Vector3(0, 0, -0.1), Vector3(0.05, 0.2, 0.014), Color(0.3, 0.3, 0.33), Vector3(-90, 0, 0), 4)
	kb.add("cyl", Vector3(0, 0, 0.06), Vector3(0.022, 0.12, 0.022), Color(0.85, 0.82, 0.7), Vector3(90, 0, 0), 5)
	kb.add("cyl", Vector3(0, 0, 0.15), Vector3(0.05, 0.012, 0.05), Color(0.3, 0.3, 0.33), Vector3.ZERO, 6)
	_part(k, kb)
	k.global_position = from
	k.look_at(to, Vector3.UP)
	Sfx.play("throw", from, 1.2, 0.6)
	var t := 0.0
	var dur = from.distance_to(to) / 26.0
	while t < dur:
		t += get_process_delta_time()
		k.global_position = from.lerp(to, minf(1.0, t / dur))
		await get_tree().process_frame
	k.global_position = to
	Sfx.play("hit", to, 1.7, 0.5)
	var keep = k.global_transform
	k.get_parent().remove_child(k)
	owner_root.add_child(k)
	k.global_transform = keep


## Ders: önce sen atarsın (hedefin tam ortası); öğrenci dener, ıskalar; duruşunu düzeltirsin; yeniden atar, tutturur
func _act_teach(it: Dictionary) -> void:
	var pl = Game.player
	var kid: Node3D = it["node"]
	var d = job_d
	var i = int(it.get("ti", 0))
	var tg: Vector3 = d["targets"][i % 3]
	var root: Node3D = d["root"]
	var c: Vector3 = d["c"]
	var line_p = Vector3(tg.x - 0.7, pl.global_position.y, c.z + float(d["line_z"]))
	await _go_w(pl, line_p, 2.6, false, 0.12)
	_look_at(pl, tg)
	_look_at(kid, pl.global_position)
	_say(pl, ["Önce izle: bilek gevşek, omuz hedefe dönük.", "Nefesini tut, bırakırken at.", "Gözün hedefte, elin gözünü izlesin."][i % 3], 2.4)
	await _wait(0.5)
	_pose(pl, "slap", {"anim": "idle", "at": pl.global_position + Vector3.UP * 1.35 + _fd(pl) * 0.75})
	await _wait(0.34)
	await _throw_kunai(pl.global_position + Vector3.UP * 1.35 + _fd(pl) * 0.6, tg, root)
	_clear_pose(pl)
	await _wait(0.3)
	# öğrenci çizgiye gelir, atar, ıskalar
	if kid is QuestNPC:
		kid.set_physics_process(false)
	var kp = Vector3(tg.x + 0.5, kid.global_position.y, c.z + float(d["line_z"]))
	await _go_w(kid, kp, 2.8, false, 0.12)
	_look_at(kid, tg)
	_look_at(pl, kid.global_position)
	var ksc: float = kid.model.age_scale
	var khand = func(): return kid.global_position + Vector3.UP * 1.3 * ksc + _fd(kid) * 0.5
	_pose(kid, "slap", {"anim": "idle", "at": khand.call() + _fd(kid) * 0.2})
	await _wait(0.34)
	var miss = tg + Vector3([0.42, -0.38, 0.3][i % 3], [0.34, 0.3, -0.42][i % 3], -0.35)
	await _throw_kunai(khand.call(), miss, root)
	_clear_pose(kid)
	_say(kid, ["Ah! Yine kenara gitti...", "Olmuyor işte!", "Neden hep sola kaçıyor?"][i % 3], 2.2)
	await _wait(0.9)
	# düzeltme: yanına geç, dirseğini ve omzunu düzelt
	var side = kid.global_position + _fd(kid).cross(Vector3.UP).normalized() * 0.55 - _fd(kid) * 0.25
	side.y = pl.global_position.y
	await _go_w(pl, side, 1.8, false, 0.08)
	_look_at(pl, kid.global_position)
	_pose(kid, "slap", {"anim": "idle", "at": khand.call() + Vector3.UP * 0.1})
	st[kid]["t"] = 0.5
	var arm = kid.global_position + Vector3.UP * 1.15 * ksc + _fd(kid) * 0.25
	_pose(pl, "grab_low", {"anim": "idle", "at": arm - Vector3.UP * 0.18, "lift": 0.0})
	_say(pl, ["Dirseğini içeri al. Böyle.", "Omzun düşmüş, kaldır.", "Ayağını hedefe çevir, sonra kolunu."][i % 3], 2.2)
	var t := 0.0
	while t < 1.5:
		t += get_process_delta_time()
		if st.has(kid):
			st[kid]["t"] = 0.5   # kol havada, atış anında donuk
		await get_tree().process_frame
	_clear_pose(pl)
	var back = side - _fd(kid) * 0.9
	await _go_w(pl, back, 1.6, false, 0.1)
	_look_at(pl, tg)
	_pose(kid, "slap", {"anim": "idle", "at": khand.call() + _fd(kid) * 0.2})
	await _wait(0.34)
	await _throw_kunai(khand.call(), tg + Vector3(0.05, 0.04, 0), root)
	_clear_pose(kid)
	FX.burst(tg, {"amount": 10, "life": 0.4, "size": 0.05, "vmin": 0.8, "vmax": 2.2, "gravity": Vector3(0, -5, 0), "colors": [Color(1, 0.9, 0.5, 1), Color(1, 0.9, 0.5, 0)]})
	_look_at(kid, pl.global_position)
	_pose(kid, "cheer", {"anim": "idle", "ph": 0.0})
	_say(kid, ["Tam ortasından! Gördün mü sensei?!", "Oldu! OLDU!", "Bir daha, bir daha atayım!"][i % 3], 2.6)
	await _wait(1.4)
	kid.set_meta("taught", true)
	var kd = kid
	get_tree().create_timer(2.6).timeout.connect(func():
		if is_instance_valid(kd):
			_clear_pose(kd)
			kd.model.play("idle", 0.3))


# ====================================================================== kaçak işleri: soygun, kafes, kaçak mal
var caravan := {}   # soygun kervanı: {"npc", "stop", "halted"}


## Yolun yönü (iki yana da yol süren doğrultu); bulunamazsa ZERO
static func road_dir(p: Vector3) -> Vector3:
	var best = Vector3.ZERO
	var bs = -1
	for k in 12:
		var a = PI * k / 12.0
		var dv = Vector3(cos(a), 0, sin(a))
		var sc = 0
		for r in [6.0, 12.0, 18.0]:
			if Game.road_at(p.x + dv.x * r, p.z + dv.z * r) > 0.0:
				sc += 1
			if Game.road_at(p.x - dv.x * r, p.z - dv.z * r) > 0.0:
				sc += 1
		if sc > bs:
			bs = sc
			best = dv
	return best if bs >= 4 else Vector3.ZERO


func _site_rogue(kind: String, root: Node3D, b: MB, d: Dictionary, c: Vector3, gy: Callable, solid: Callable) -> void:
	var wood = Color(0.48, 0.35, 0.22)
	var dark = wood.darkened(0.3)
	if kind == "ambush":
		# pusu yeri: yol kenarında devrik kütükler, karşıda saklanılacak çalılık, arkada zula (içi oyuk kütük)
		var dir = road_dir(c)
		if dir == Vector3.ZERO:
			dir = Vector3(0, 0, 1)
		var side = Vector3(dir.z, 0, -dir.x)
		var logs = []
		for i in 2:
			var lg = Node3D.new()
			root.add_child(lg)
			var lb = MB.new()
			lb.add("cyl", Vector3.ZERO, Vector3(0.46, 5.4, 0.46), Color(0.42, 0.3, 0.2).darkened(i * 0.08), Vector3(90, 0, 0), 8)
			for e in [-2.71, 2.71]:
				lb.add("cyl", Vector3(0, 0, e), Vector3(0.42, 0.02, 0.42), Color(0.76, 0.64, 0.44), Vector3(90, 0, 0), 8)
			lb.add("cyl", Vector3(0.12, 0.2, 0.8), Vector3(0.1, 0.5, 0.1), Color(0.36, 0.26, 0.18), Vector3(0, 0, -35), 5)   # kırık dal
			_part(lg, lb)
			var lp = c + side * (6.6 + i * 1.1) + dir * (i * 1.6 - 0.8)
			lp.y = Game.ground_height(lp.x, lp.z) + 0.23
			lg.global_position = lp
			lg.rotation.y = atan2(dir.x, dir.z) + (0.25 if i == 0 else -0.15)
			logs.append(lg)
		# çalılık
		var hp = c - side * 8.5 + dir * 3.0
		hp.y = Game.ground_height(hp.x, hp.z)
		var hb = MB.new()
		for k in 9:
			var a = TAU * k / 9.0
			hb.add("sphere", Vector3(cos(a) * 1.1, 0.7 + (k % 3) * 0.25, sin(a) * 0.7), Vector3(1.5, 1.4, 1.3), Color(0.2, 0.42, 0.18).darkened((k % 3) * 0.08), Vector3.ZERO, 7)
		hb.add("sphere", Vector3(0, 1.2, 0), Vector3(2.0, 1.6, 1.4), Color(0.24, 0.48, 0.2), Vector3.ZERO, 8)
		var hn = Node3D.new()
		root.add_child(hn)
		_part(hn, hb)
		hn.global_position = hp
		hn.rotation.y = atan2(dir.x, dir.z)
		# zula: içi oyuk koca kütük + üstünde kabuk kapak
		var sp = c - side * 15.0 - dir * 4.0
		sp = Missions.open_ground(sp, 10.0)
		sp.y = Game.ground_height(sp.x, sp.z)
		var sn = Node3D.new()
		root.add_child(sn)
		sn.global_position = sp
		var sb = MB.new()
		for k in 10:
			var a = TAU * k / 10.0
			sb.add("box", Vector3(cos(a) * 0.62, 0.42, sin(a) * 0.62), Vector3(0.44, 0.84 + (k % 3) * 0.1, 0.14), Color(0.36, 0.26, 0.18).darkened((k % 2) * 0.08), Vector3(0, -rad_to_deg(a) + 90.0, 0))
		sb.add("cyl", Vector3(0, 0.04, 0), Vector3(1.2, 0.06, 1.2), Color(0.12, 0.09, 0.07), Vector3.ZERO, 10)
		for k in 4:
			sb.add("cyl", Vector3(cos(k * 1.6) * 0.85, 0.12, sin(k * 1.6) * 0.85), Vector3(0.22, 0.9, 0.22), Color(0.34, 0.25, 0.17), Vector3(70, k * 92.0, 0), 5)   # kökler
		_part(sn, sb)
		var lid = Node3D.new()
		sn.add_child(lid)
		var lidb = MB.new()
		lidb.add("cyl", Vector3.ZERO, Vector3(1.5, 0.08, 1.5), Color(0.3, 0.22, 0.15), Vector3.ZERO, 9)
		lidb.add("sphere", Vector3(0.2, 0.06, 0.1), Vector3(0.7, 0.12, 0.5), Color(0.25, 0.4, 0.2), Vector3.ZERO, 6)   # yosun
		_part(lid, lidb)
		lid.position = Vector3(0, 0.95, 0)
		var sbody = StaticBody3D.new()
		sn.add_child(sbody)
		var scs = CollisionShape3D.new()
		var ssh = CylinderShape3D.new()
		ssh.radius = 0.72
		ssh.height = 0.9
		scs.shape = ssh
		scs.position.y = 0.45
		sbody.add_child(scs)
		d["dir"] = dir
		d["side"] = side
		d["logs"] = logs
		d["hide"] = hp - side * 1.6
		d["stash"] = sp
		d["stash_node"] = sn
		d["lid"] = lid
		d["block_at"] = c
		d["placed"] = 0
		d["kind"] = kind
		job_d = d
	elif kind == "jail":
		# karakol kafesi: kazık parmaklıklı hücre, kapısında asma kilit; yanında nöbet ateşi ve silahlık
		var g0: float = gy.call(0, 0)
		for k in 4:
			var a = k * PI * 0.5
			var nx = cos(a)
			var nz = sin(a)
			if k == 1:
				continue   # ön yüz (+Z) kapı
			for j in 9:
				var o = (j - 4) * 0.36
				b.add("cyl", Vector3(nx * 1.45 - nz * o, g0 + 1.15, nz * 1.45 + nx * o), Vector3(0.1, 2.3, 0.1), wood.darkened((j % 3) * 0.06), Vector3.ZERO, 5)
			b.add("box", Vector3(nx * 1.45, g0 + 2.2, nz * 1.45), Vector3(0.14, 0.14, 3.1), dark, Vector3(0, -rad_to_deg(a), 0))
			b.add("box", Vector3(nx * 1.45, g0 + 0.25, nz * 1.45), Vector3(0.14, 0.14, 3.1), dark, Vector3(0, -rad_to_deg(a), 0))
			var cs = CollisionShape3D.new()
			var sh = BoxShape3D.new()
			sh.size = Vector3(0.2, 2.4, 3.1)
			cs.shape = sh
			cs.position = Vector3(nx * 1.45, g0 + 1.2, nz * 1.45)
			cs.rotation.y = -a
			(root.get_child(0) as StaticBody3D).add_child(cs)
		for sx in [-1.45, 1.45]:
			b.add("cyl", Vector3(sx, g0 + 1.2, 1.45), Vector3(0.18, 2.4, 0.18), dark, Vector3.ZERO, 6)
		b.add("box", Vector3(0, g0 + 2.36, 0), Vector3(3.2, 0.1, 3.2), dark.lightened(0.05))
		for j in 5:
			b.add("box", Vector3((j - 2) * 0.66, g0 + 2.44, 0), Vector3(0.12, 0.08, 3.3), dark)
		b.add("box", Vector3(0, g0 + 0.03, 0), Vector3(2.8, 0.05, 2.8), Color(0.62, 0.55, 0.36))   # saman
		# kapı (menteşe solda)
		var door = Node3D.new()
		root.add_child(door)
		door.position = Vector3(-1.4, g0, 1.45)
		var db = MB.new()
		for j in 8:
			db.add("cyl", Vector3(0.2 + j * 0.36, 1.15, 0), Vector3(0.09, 2.2, 0.09), wood.lightened(0.05), Vector3.ZERO, 5)
		for y in [0.3, 1.2, 2.1]:
			db.add("box", Vector3(1.4, y, 0), Vector3(2.8, 0.12, 0.12), dark)
		_part(door, db)
		var lock = Node3D.new()
		door.add_child(lock)
		lock.position = Vector3(2.7, 1.2, 0.1)
		var kb = MB.new()
		kb.add("box", Vector3.ZERO, Vector3(0.22, 0.2, 0.09), Color(0.3, 0.3, 0.33))
		kb.add("cyl", Vector3(0, 0.14, 0), Vector3(0.16, 0.03, 0.16), Color(0.22, 0.22, 0.25), Vector3(90, 0, 0), 8)
		kb.add("cyl", Vector3(0, -0.02, 0.05), Vector3(0.04, 0.02, 0.04), Color(0.08, 0.08, 0.08), Vector3(90, 0, 0), 6)
		_part(lock, kb)
		var dcs = CollisionShape3D.new()
		var dsh = BoxShape3D.new()
		dsh.size = Vector3(2.9, 2.4, 0.2)
		dcs.shape = dsh
		dcs.position = Vector3(0, g0 + 1.2, 1.45)
		(root.get_child(0) as StaticBody3D).add_child(dcs)
		# nöbet ateşi + silahlık
		var fc = Vector3(4.2, gy.call(4.2, 2.6), 2.6)
		for k in 7:
			var a2 = TAU * k / 7.0
			b.add("sphere", fc + Vector3(cos(a2) * 0.4, 0.06, sin(a2) * 0.4), Vector3(0.24, 0.18, 0.2), Color(0.5, 0.48, 0.45), Vector3.ZERO, 6)
		var fb = VFX.fireball(0.4)
		root.add_child(fb)
		fb.position = fc + Vector3(0, 0.3, 0)
		fb.rotation.x = deg_to_rad(-90.0)
		fb.scale = Vector3(1, 1, 1.8)
		var rk = Vector3(-3.6, gy.call(-3.6, 2.2), 2.2)
		for sx in [-0.4, 0.4]:
			b.add("box", rk + Vector3(sx, 0.7, 0), Vector3(0.08, 1.4, 0.28), dark)
		b.add("box", rk + Vector3(0, 1.3, 0), Vector3(0.9, 0.08, 0.3), dark)
		for k in 3:
			b.add("cyl", rk + Vector3(-0.25 + k * 0.25, 1.2, 0), Vector3(0.035, 2.4, 0.035), wood.lightened(0.15), Vector3.ZERO, 5)
			b.add("cone", rk + Vector3(-0.25 + k * 0.25, 2.52, 0), Vector3(0.09, 0.3, 0.03), Color(0.7, 0.72, 0.76), Vector3.ZERO, 4)
		d["cell"] = c + Vector3(0, 0, -0.2)
		d["door"] = door
		d["door_cs"] = dcs
		d["lock"] = lock
		d["front"] = c + Vector3(1.1, 0, 2.5)
		d["npc_at"] = c + Vector3(0, 0, -0.2)
		d["face"] = c + Vector3(0, 0, 5)
		d["kind"] = kind
		job_d = d
	elif kind == "contraband":
		# sığınak ağzında hazırlanan yük: kaçak mal sandığı + pirinç çuvalları
		var g1: float = gy.call(0, 0)
		b.add("box", Vector3(0, g1 + 0.3, 0), Vector3(1.0, 0.6, 0.7), wood)
		for sx in [-0.5, 0.5]:
			b.add("box", Vector3(sx, g1 + 0.3, 0), Vector3(0.05, 0.64, 0.74), dark)
		b.add("box", Vector3(0.1, g1 + 0.66, -0.5), Vector3(1.0, 0.05, 0.7), wood.lightened(0.06), Vector3(-62, 0, 0))   # açık kapak
		solid.call(Vector3(0, g1 + 0.3, 0), Vector3(1.0, 0.6, 0.7))
		var goods = Node3D.new()
		root.add_child(goods)
		goods.position = Vector3(0, g1 + 0.62, 0)
		var top = Node3D.new()
		top.name = "top"
		goods.add_child(top)
		var tb = MB.new()
		tb.add("box", Vector3(0, 0.1, 0), Vector3(0.5, 0.2, 0.34), Color(0.2, 0.2, 0.23))   # siyah beze sarılı paket
		tb.add("box", Vector3(0, 0.1, 0), Vector3(0.52, 0.04, 0.36), Color(0.7, 0.6, 0.4))   # ip
		tb.add("box", Vector3(0, 0.1, 0), Vector3(0.05, 0.22, 0.36), Color(0.7, 0.6, 0.4))
		_part(top, tb)
		for k in 3:
			var tg = _tag_mesh()
			top.add_child(tg)
			tg.position = Vector3(-0.12 + k * 0.12, 0.215, 0.02)
			tg.rotation = Vector3(deg_to_rad(-90.0), k * 0.3, 0)
		var rice = Node3D.new()
		root.add_child(rice)
		rice.position = Vector3(1.5, gy.call(1.5, 0.2), 0.2)
		var rtop = Node3D.new()
		rtop.name = "top"
		rice.add_child(rtop)
		var rb = MB.new()
		rb.add("sphere", Vector3(0, 0.16, 0), Vector3(0.56, 0.34, 0.44), Color(0.88, 0.84, 0.72), Vector3.ZERO, 8)
		rb.add("cyl", Vector3(0.24, 0.24, 0), Vector3(0.1, 0.1, 0.1), Color(0.7, 0.6, 0.4), Vector3(0, 0, 70), 6)
		_part(rtop, rb)
		rtop.position.y = 0.34
		var rb2 = MB.new()
		for k in 2:
			rb2.add("sphere", Vector3(k * 0.5 - 0.25, 0.16, 0.1 - k * 0.2), Vector3(0.6, 0.34, 0.46), Color(0.88, 0.84, 0.72).darkened(k * 0.06), Vector3(0, k * 40.0, 0), 8)
		_part(rice, rb2)
		d["goods"] = goods
		d["rice"] = rice
		d["kind"] = kind
		job_d = d


## Adım başında özel kurulum (adımın "setup" anahtarı)
func step_setup(what: String, s: Dictionary) -> void:
	match what:
		"traces":
			traces_begin()
		"decoy":
			_decoy_setup()
		"caravan":
			_caravan_begin(s)
		"jail":
			if job_d.get("kind", "") == "jail" and not is_instance_valid(Missions.npcs.get("tutsak")):
				var spec: Dictionary = s.get("prisoner", Missions._npc("tutsak", "Tutsak Kaçak", "civ"))
				var h = Missions._make_npc(spec, job_d["cell"])
				h.global_position = Vector3(job_d["cell"].x, Game.ground_height(job_d["cell"].x, job_d["cell"].z), job_d["cell"].z)
				h.home = h.global_position
				h.mode = "cower"
				bind(h)
				var k := 0
				for e in Missions.step_nodes:
					if is_instance_valid(e) and e is Enemy:
						var q: Vector3 = job_d["front"] + Vector3(-2.0 + k * 2.4, 0, 3.5 + (k % 2) * 1.5)
						q.y = Game.ground_height(q.x, q.z)
						e.global_position = q
						e.home = q
						e.wander_to = q
						k += 1
				Missions.target_marker = job_d["front"]


## Kervan: tüccar + öküz arabası yoldan gelir, muhafızlar yanında yürür; barikata varınca durur
func _caravan_begin(s: Dictionary) -> void:
	if job_d.get("kind", "") != "ambush":
		return
	var from = Missions._w(s["at"])
	var m = Missions._make_npc(Missions._npc("tuccar", "Vergi Kâhyası", "merchant"), from)
	var stop: Vector3 = job_d["block_at"] + (from - job_d["block_at"]).normalized() * 8.0
	cart_begin(m)
	m.mode = "march"
	m.goal = stop
	m.speed = 2.4
	caravan = {"npc": m, "stop": stop, "halted": false, "t": 0.0}
	# sandıklar arabanın kasasında
	var cart: Node3D = cart_d.get("cart")
	var chests = []
	if is_instance_valid(cart):
		for i in 2:
			var ch = Node3D.new()
			cart.add_child(ch)
			ch.position = Vector3(-0.5 + i * 0.6, 1.23, -1.2 + i * 0.45)
			ch.rotation.y = i * 0.3
			var cb = MB.new()
			cb.add("box", Vector3(0, 0.2, 0), Vector3(0.7, 0.4, 0.46), Color(0.4, 0.26, 0.16))
			cb.add("box", Vector3(0, 0.44, 0), Vector3(0.72, 0.1, 0.48), Color(0.34, 0.22, 0.14))
			for sx in [-0.26, 0.26]:
				cb.add("box", Vector3(sx, 0.24, 0), Vector3(0.06, 0.52, 0.5), Color(0.3, 0.3, 0.33))
			cb.add("box", Vector3(0, 0.3, 0.24), Vector3(0.1, 0.12, 0.03), Color(0.78, 0.64, 0.2))
			_part(ch, cb)
			chests.append(ch)
	job_d["chests"] = chests
	Hud.msg("Kervan yolda göründü. Barikata varana kadar çalılıkta bekle.", Color(1, 0.9, 0.6), 5.0)


func _caravan_tick(dt: float) -> void:
	if caravan.is_empty():
		return
	var m = caravan.get("npc")
	if not is_instance_valid(m):
		caravan = {}
		return
	caravan["t"] = float(caravan["t"]) + dt
	var foes = Missions.step_nodes.filter(func(e): return is_instance_valid(e) and e is Enemy and not e.is_dead())
	var pl = Game.player
	var hidden = pl != null and pl.global_position.distance_to(job_d.get("hide", Vector3.INF)) < 3.2
	if not caravan["halted"]:
		if hidden:
			for e in foes:
				e.blind_t = maxf(e.blind_t, 0.4)   # çalılığın ardındaki görülmez
		# muhafızlar tüccarın iki yanında yürür
		var i := 0
		for e in foes:
			if e.get("target") == null or not is_instance_valid(e.get("target")):
				var off = Vector3(2.6 if i % 2 == 0 else -2.6, 0, -2.0 - (i / 2) * 2.5)
				e.home = m.global_position + off.rotated(Vector3.UP, m.facing)
				e.wander_to = e.home
			i += 1
		var fight = foes.any(func(e): return e.get("target") != null and is_instance_valid(e.get("target")))
		if m.global_position.distance_to(caravan["stop"]) < 2.2 or fight or foes.is_empty():
			caravan["halted"] = true
			m.mode = "idle"
			if int(job_d.get("placed", 0)) >= 2 and not fight:
				_say(m, "Yol kapalı! Muhafızlar, kütükleri kaldırın!", 3.0)
			cower(m, true)
			var j := 0
			for e in foes:
				e.home = (job_d["block_at"] as Vector3) + (m.global_position - job_d["block_at"]).normalized() * (2.0 + j * 1.5)
				e.wander_to = e.home
				j += 1
				if hidden and not fight:
					e.blind_t = 4.0
			if hidden and not fight:
				Hud.msg("Muhafızlar kütüklere eğildi, seni görmediler. Şimdi!", Color(1, 0.9, 0.6), 4.0)


## Kütüğü ucundan kavra, yola sürükle, enine bırak
func _act_block(it: Dictionary) -> void:
	var pl = Game.player
	var lg: Node3D = it["node"]
	var d = job_d
	var dir: Vector3 = d["dir"]
	var side: Vector3 = d["side"]
	var n = int(d.get("placed", 0))
	await _stand_at(lg, 0.7)
	_pose(pl, "grab_low", {"anim": "idle", "at": lg.global_position + Vector3.UP * 0.1, "lift": 0.0})
	await _wait(0.55)
	st[pl]["pop"] = st[pl]["t"]
	Sfx.play("pickup", lg.global_position, 0.5, 1.0)
	var carry = {"on": true}
	var follow = func():
		while carry["on"] and is_instance_valid(lg):
			var tgt = pl.global_position + Vector3.UP * 0.62 * pl.model.age_scale + _fd(pl) * 0.45
			lg.global_position = lg.global_position.lerp(tgt, 0.25)
			lg.rotation.y = lerp_angle(lg.rotation.y, pl.facing + PI * 0.5, 0.12)
			await get_tree().process_frame
	follow.call()
	var tgt2: Vector3 = d["block_at"] + dir * (n * 0.9 - 0.45)
	var stand = tgt2 + dir * 0.8
	stand.y = pl.global_position.y
	await _go_w(pl, stand, 1.7, true, 0.15)
	_look_at(pl, tgt2)
	carry["on"] = false
	var from = lg.global_position
	var fy = lg.rotation.y
	var ty = atan2(side.x, side.z) + (0.18 if n == 0 else -0.14)
	tgt2.y = Game.ground_height(tgt2.x, tgt2.z) + 0.23 + n * 0.12
	var t := 0.0
	while t < 0.5:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.5, t)
		lg.global_position = from.lerp(tgt2, k)
		lg.rotation.y = lerp_angle(fy, ty, k)
		await get_tree().process_frame
	Sfx.play("punch", tgt2, 0.5, 1.2)
	FX.burst(tgt2, {"amount": 14, "life": 0.6, "size": 0.14, "dir": Vector3.UP, "spread": 80.0, "vmin": 0.6, "vmax": 2.0, "gravity": Vector3(0, -1.5, 0), "colors": [Color(0.6, 0.5, 0.38, 0.7), Color(0.6, 0.5, 0.38, 0)]})
	_clear_pose(pl)
	d["placed"] = n + 1
	if n + 1 >= 2:
		var body = StaticBody3D.new()
		(d["root"] as Node3D).add_child(body)
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = Vector3(5.4, 0.7, 1.6)
		cs.shape = sh
		body.global_position = (d["block_at"] as Vector3) + Vector3.UP * 0.35
		body.rotation.y = atan2(side.x, side.z) + PI * 0.5
		body.add_child(cs)
		Hud.msg("Yol kapandı. Çalılığın ardına geç ve kervanı bekle.", Color(1, 0.9, 0.6), 5.0)


## Sandığı arabadan indir, omuzla
func _act_loot(it: Dictionary) -> void:
	var pl = Game.player
	var ch: Node3D = it["node"]
	it["silent"] = true
	if is_instance_valid(rider):
		Hud.msg("Omzun dolu: önce taşıdığını zulaya bırak.", Color(1, 0.85, 0.6))
		Interact.add(it)
		return
	await _stand_at(ch, 1.25)
	_pose(pl, "give", {"anim": "idle", "w": 0.3})
	await _wait(0.4)
	Sfx.play("pickup", ch.global_position, 0.6, 1.0)
	var keep = ch.global_transform
	ch.get_parent().remove_child(ch)
	add_child(ch)
	ch.top_level = true
	ch.global_transform = keep
	Missions.pickups.append(ch)
	var from = ch.global_position
	rider_off = Vector3(0.37, 1.36, 0.0)   # sağ omuzda, uzun kenarı ileri-geri (başı kapatmasın)
	rider_yaw = PI * 0.5
	var t := 0.0
	while t < 0.6:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.6, t)
		var sc: float = pl.model.age_scale
		var right = _fd(pl).cross(Vector3.UP).normalized()
		var tgt = pl.global_position + Vector3.UP * rider_off.y * sc + right * rider_off.x * sc
		ch.global_position = from.lerp(tgt, k) + Vector3.UP * sin(k * PI) * 0.25
		await get_tree().process_frame
	rider = ch
	rider_kind = "chest"
	_clear_pose(pl)
	it["silent"] = not it.get("count", false)
	Hud.float_text("Sandık omuzda" if it.get("count", false) else "Sandık omuzda: zulaya götür", Color(1, 0.9, 0.6))


## Zula: kapağı kaldır, sandığı içine indir, kapağı ört
func _act_stash(it: Dictionary) -> void:
	var pl = Game.player
	var d = job_d
	it["silent"] = true
	if rider_kind != "chest" or not is_instance_valid(rider):
		Hud.msg("Zula boş. Önce sandığı omuzla.", Color(1, 0.85, 0.6))
		Interact.add(it)
		return
	var sn: Node3D = d["stash_node"]
	var lid: Node3D = d["lid"]
	await _stand_at(sn, 1.15)
	var ch = rider
	rider = null
	rider_kind = ""
	var tw = lid.create_tween()
	tw.tween_property(lid, "position", Vector3(1.1, 0.5, 0.3), 0.4)
	tw.parallel().tween_property(lid, "rotation:z", deg_to_rad(-70.0), 0.4)
	_pose(pl, "grab_low", {"anim": "idle", "at": sn.global_position + Vector3.UP * 0.9, "lift": 0.0})
	var from = ch.global_position
	var n = int(d.get("stashed", 0))
	var tgt = sn.global_position + Vector3(0, 0.12 + n * 0.42, 0)
	var t := 0.0
	while t < 0.8:
		t += get_process_delta_time()
		var k = smoothstep(0.0, 0.8, t)
		ch.global_position = from.lerp(tgt, k) + Vector3.UP * sin(k * PI) * 0.3
		ch.scale = Vector3.ONE * lerpf(1.0, 0.85, k)
		await get_tree().process_frame
	Sfx.play("punch", tgt, 0.4, 1.3)
	d["stashed"] = n + 1
	var left = (d.get("chests", []) as Array).size() - (n + 1)
	if left <= 0:
		var tw2 = lid.create_tween()
		tw2.tween_property(lid, "position", Vector3(0, 0.95, 0), 0.5)
		tw2.parallel().tween_property(lid, "rotation:z", 0.0, 0.5)
	await _wait(0.45)
	_clear_pose(pl)
	it["silent"] = false
	if left > 0:
		Interact.add(it)


## Kafes: asma kilide kunai ile üç darbe; kilit düşer, kapı açılır
func _act_cage(it: Dictionary) -> void:
	var pl = Game.player
	var d = job_d
	var lock: Node3D = d["lock"]
	var door: Node3D = d["door"]
	var fp: Vector3 = d["front"]
	fp.y = pl.global_position.y
	await _go_w(pl, fp, 2.4, false, 0.12)
	var lp = lock.global_position
	_look_at(pl, lp)
	for k in 3:
		_pose(pl, "slap", {"anim": "idle", "at": lp + Vector3(0, 0, 0.12)})
		await _wait(0.4)
		Sfx.play("hit", lp, 1.6, 0.7)
		FX.burst(lp, {"amount": 9, "life": 0.25, "size": 0.035, "vmin": 1.0, "vmax": 3.2, "gravity": Vector3(0, -7, 0), "colors": [Color(1, 0.9, 0.55, 1), Color(1, 0.6, 0.2, 0)]})
		lock.rotation.z = [0.25, -0.3, 0.5][k]
		await _wait(0.18)
	_clear_pose(pl)
	var keep = lock.global_transform
	door.remove_child(lock)
	(d["root"] as Node3D).add_child(lock)
	lock.global_transform = keep
	var tw = lock.create_tween()
	tw.tween_property(lock, "global_position:y", Game.ground_height(lp.x, lp.z) + 0.06, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(lock, "rotation:x", 1.4, 0.3)
	Sfx.play("pickup", lp, 0.5, 0.8)
	var tw2 = door.create_tween()
	tw2.tween_property(door, "rotation:y", deg_to_rad(-112.0), 0.9).set_trans(Tween.TRANS_SINE)
	(d["door_cs"] as CollisionShape3D).set_deferred("disabled", true)
	await _wait(0.9)


## İş noktası kaydı (job_begin dışından eklenenler için)
func _jitem(work: String, label: String, pos: Vector3, node: Node3D, extra := {}, radius := 2.4) -> void:
	var it = {"pos": pos, "radius": radius, "kind": "quest", "label": label, "qkey": Missions._key(), "qi": 0, "work": work, "node": node}
	it.merge(extra)
	Interact.add(it)
	node.tree_exiting.connect(func(): Interact.items.erase(it))


## Kaçak malı küfeye yükle; sonra seçim: üstünü pirinç çuvalıyla ört ya da öylece yola çık
func _act_pack(it: Dictionary) -> void:
	var pl = Game.player
	var d = job_d
	match String(it.get("mode", "load")):
		"load":
			it["silent"] = true
			await _act_back(it)
			Hud.float_text("Kaçak mal küfede", Color(1, 0.9, 0.6))
			var rice: Node3D = d["rice"]
			_jitem("pack", "[F] Üstünü pirinç çuvalıyla ört", rice.global_position, rice, {"mode": "cover"})
			_jitem("pack", "[F] Örtmeden yola çık", (d["root"] as Node3D).global_position + Vector3(-1.8, 0, 0.6), d["root"], {"mode": "go"}, 1.6)
			Hud.msg("Karakolda küfeni açtıracaklar. Üstünü pirinçle örtebilirsin.", Color(1, 0.9, 0.6), 5.0)
		"cover":
			await _act_back(it)
			Missions.active()["flags"]["covered"] = true
			Hud.float_text("Mal pirinç çuvalının altında", Color(0.8, 1, 0.8))
		_:
			_pose(pl, "give", {"anim": "idle", "w": 0.2})
			await _wait(0.4)
			_clear_pose(pl)


## Karakol araması: nöbetçi arkana geçer, küfeyi karıştırır. true: temiz çıktı
func inspect_load(npc: Node3D) -> bool:
	var pl = Game.player
	if not is_instance_valid(npc) or rider_kind != "load" or not is_instance_valid(rider):
		return false
	busy_run = true
	_lock(14.0)
	stop_busy(npc)
	if npc is QuestNPC:
		npc.set_physics_process(false)
	var to = (npc.global_position - pl.global_position).slide(Vector3.UP).normalized()
	_look_at(pl, pl.global_position + to * 3.0)
	var behind = pl.global_position - to * 0.85
	await _go_w(npc, pl.global_position + to.cross(Vector3.UP).normalized() * 1.2, 1.8, false, 0.15)
	await _go_w(npc, behind, 1.8, false, 0.12)
	_look_at(npc, pl.global_position)
	var covered: bool = Missions.active().get("flags", {}).get("covered", false)
	for k in 2:
		_pose(npc, "slap", {"anim": "idle", "at": rider.global_position + Vector3.UP * 0.55})
		await _wait(0.45)
		Sfx.play("pickup", rider.global_position, 0.6, 1.1 + k * 0.2)
		await _wait(0.25)
	if covered:
		Hud.float_text("Pirinç çuvalı. Altına bakmadı.", Color(0.8, 1, 0.8))
		await _wait(0.7)
	else:
		# siyah paketi çekip çıkarır
		var pk: Node3D = null
		for ch in rider.get_children():
			if ch.name.begins_with("top"):
				pk = ch
		if is_instance_valid(pk):
			var keep = pk.global_transform
			rider.remove_child(pk)
			add_child(pk)
			pk.top_level = true
			pk.global_transform = keep
			Missions.pickups.append(pk)
			var from = pk.global_position
			var tgt = npc.global_position + Vector3.UP * 1.25 + _fd(npc) * 0.35
			var t := 0.0
			while t < 0.5:
				t += get_process_delta_time()
				pk.global_position = from.lerp(tgt, smoothstep(0.0, 0.5, t))
				await get_tree().process_frame
		Hud.float_text("Patlayıcı mühürler!", Color(1, 0.5, 0.4))
		Sfx.play("alarm", npc.global_position, 1.0, 0.6)
		await _wait(0.7)
	_clear_pose(npc)
	if npc is QuestNPC and is_instance_valid(npc):
		npc.set_physics_process(true)
	_release_player()
	busy_run = false
	return covered


# ====================================================================== kaçak işleri (2): sahte işaret ateşi + depo
var decoy := {}   # {"guards": [QuestNPC], "to": Vector3, "seen": bool, "run": bool}


func _site_depot(root: Node3D, b: MB, d: Dictionary, c: Vector3, gy: Callable, solid: Callable) -> void:
	# erzak deposu: önü açık tahta baraka, raflar, fıçılar, çuval yığını; önünde fener direği
	var wood = Color(0.48, 0.35, 0.22)
	var dark = wood.darkened(0.3)
	var g0: float = gy.call(0, 0)
	b.add("box", Vector3(0, g0 + 0.06, 0), Vector3(4.6, 0.12, 3.2), wood.darkened(0.15))
	for sx in [-2.2, 2.2]:
		for sz in [-1.5, 1.5]:
			b.add("box", Vector3(sx, g0 + 1.3, sz), Vector3(0.16, 2.6, 0.16), dark)
		for k in 7:
			b.add("box", Vector3(sx, g0 + 0.3 + k * 0.34, 0), Vector3(0.06, 0.3, 2.9), wood.darkened((k % 3) * 0.06))
		solid.call(Vector3(sx, g0 + 1.3, 0), Vector3(0.2, 2.6, 3.0))
	for k in 7:
		b.add("box", Vector3(0, g0 + 0.3 + k * 0.34, -1.5), Vector3(4.4, 0.3, 0.06), wood.darkened((k % 2) * 0.07))
	solid.call(Vector3(0, g0 + 1.3, -1.5), Vector3(4.4, 2.6, 0.2))
	b.add("box", Vector3(0, g0 + 2.75, 0.15), Vector3(5.0, 0.1, 3.9), dark.lightened(0.04), Vector3(8, 0, 0))   # eğik çatı
	for k in 6:
		b.add("box", Vector3(-2.2 + k * 0.88, g0 + 2.83, 0.15), Vector3(0.1, 0.06, 3.95), dark, Vector3(8, 0, 0))
	# raf: testiler ve kutular
	b.add("box", Vector3(0, g0 + 1.25, -1.25), Vector3(4.2, 0.06, 0.45), wood.lightened(0.05))
	b.add("box", Vector3(0, g0 + 1.95, -1.25), Vector3(4.2, 0.06, 0.45), wood.lightened(0.05))
	for k in 5:
		b.add("cyl", Vector3(-1.7 + k * 0.5, g0 + 1.48, -1.25), Vector3(0.28, 0.4, 0.28), Color(0.6, 0.38, 0.26).darkened((k % 2) * 0.1), Vector3.ZERO, 8)
		b.add("cyl", Vector3(-1.7 + k * 0.5, g0 + 1.72, -1.25), Vector3(0.14, 0.08, 0.14), Color(0.5, 0.3, 0.2), Vector3.ZERO, 6)
	for k in 3:
		b.add("box", Vector3(0.9 + k * 0.42, g0 + 2.14, -1.25), Vector3(0.36, 0.3, 0.34), Color(0.56, 0.42, 0.26).darkened(k * 0.06), Vector3(0, k * 9.0, 0))
	# fıçılar
	for k in 3:
		var bp = Vector3(-1.6 + (k % 2) * 0.7, g0 + 0.55 + (k / 2) * 0.0, -0.7 + (k / 2) * 0.75)
		b.add("cyl", bp, Vector3(0.62, 0.86, 0.62), Color(0.45, 0.3, 0.18), Vector3.ZERO, 10)
		for y in [-0.25, 0.25]:
			b.add("cyl", bp + Vector3(0, y, 0), Vector3(0.65, 0.05, 0.65), Color(0.25, 0.25, 0.28), Vector3.ZERO, 10)
	solid.call(Vector3(-1.3, g0 + 0.55, -0.4), Vector3(1.5, 0.9, 1.5))
	# çuval yığını (arkada); çalınacak çuval önde ayrı durur
	for k in 5:
		b.add("sphere", Vector3(1.0 + (k % 3) * 0.48, g0 + 0.3 + (k / 3) * 0.34, -0.9 + (k % 2) * 0.2), Vector3(0.62, 0.38, 0.5), Color(0.75, 0.68, 0.5).darkened((k % 3) * 0.05), Vector3(0, k * 25.0, 0), 8)
	solid.call(Vector3(1.5, g0 + 0.35, -0.9), Vector3(1.5, 0.6, 0.8))
	# fener direği
	var lp = Vector3(2.9, gy.call(2.9, 2.2), 2.2)
	b.add("box", lp + Vector3(0, 1.1, 0), Vector3(0.1, 2.2, 0.1), dark)
	b.add("box", lp + Vector3(-0.25, 2.15, 0), Vector3(0.6, 0.07, 0.07), dark)
	b.add("box", lp + Vector3(-0.5, 1.9, 0), Vector3(0.24, 0.32, 0.24), Color(0.95, 0.85, 0.6))
	var l = OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.45)
	l.light_energy = 1.6
	l.omni_range = 8.0
	l.position = lp + Vector3(-0.5, 1.9, 0)
	root.add_child(l)
	d["sack_at"] = c + Vector3(0.6, 0, 0.5)
	d["guards"] = [c + Vector3(-1.6, 0, 2.6), c + Vector3(1.7, 0, 2.8)]
	d["face"] = c + Vector3(0, 0, 9.0)
	d["npc_at"] = c + Vector3(-1.6, 0, 2.6)
	d["kind"] = "depot"
	job_d = d


func _decoy_setup() -> void:
	if job_d.get("kind", "") != "depot" or not decoy.is_empty():
		return
	var gs = []
	var names = ["Depo Nöbetçisi Heita", "Depo Nöbetçisi Mokichi"]
	for i in 2:
		var at: Vector3 = job_d["guards"][i]
		var g = Missions._make_npc(Missions._npc("depocu%d" % i, names[i], "ninja"), at)
		place_worker(g, at, job_d["face"])
		busy(g, "fold")
		gs.append(g)
	decoy = {"guards": gs, "to": Vector3.ZERO, "seen": false, "run": false}


## İşaret ateşini yak: depo nöbetçileri ateşe koşar
func _act_decoy(it: Dictionary) -> void:
	var key = "%s:beacon0" % String(Missions.active().get("id", ""))
	if not sites.has(key):
		return
	var bd: Dictionary = sites[key]
	await light_beacon(bd, Game.player)
	busy_run = true
	if decoy.is_empty():
		return
	decoy["to"] = bd["torch_at"]
	decoy["run"] = true
	var i := 0
	for g in decoy["guards"]:
		if not is_instance_valid(g):
			continue
		stop_busy(g)
		_clear_pose(g)
		_say(g, ["İşaret ateşi! Sınırda bir şey var!", "Koş! Depo bekler, sınır beklemez!"][i % 2], 3.5)
		g.mode = "march"
		g.goal = (bd["torch_at"] as Vector3) + Vector3(i * 1.6 - 0.8, 0, 1.5)
		g.speed = 5.2
		i += 1
	Hud.msg("Depo nöbetçileri ateşe koşuyor. Yollarına çıkma; depoya dolan.", Color(1, 0.9, 0.6), 6.0)


func _decoy_tick(_dt: float) -> void:
	if decoy.is_empty() or not decoy.get("run", false) or decoy.get("seen", false) or Game.player == null:
		return
	if Missions.active().is_empty():
		decoy = {}
		return
	var pl = Game.player
	for g in decoy["guards"]:
		if not is_instance_valid(g):
			continue
		if g.global_position.distance_to(decoy["to"]) < 4.0:
			continue   # ateşin başında: arkası dönük
		if g.global_position.distance_to(pl.global_position) < 9.0:
			decoy["seen"] = true
	if decoy["seen"]:
		Missions.active()["flags"]["detected"] = true
		Hud.banner("GÖRÜLDÜN!", "Nöbetçiler yolda seni fark etti.", Color(1, 0.4, 0.3))
		for g in decoy["guards"]:
			if not is_instance_valid(g):
				continue
			var at: Vector3 = g.global_position
			Missions.npcs.erase(g.quest_tag)
			g.queue_free()
			Missions._spawn("samurai", at, 1, 0.5, "Depo Nöbetçisi")


# ====================================================================== kaçak işleri (3): mal okutma + iz silme
## Barakanın önüne okutulacak malın örneğini çıkar (omuzlanır, takasçıya götürülür)
func haul_begin(label: String) -> void:
	var h = RogueHut.d()
	if h.is_empty():
		return
	var pos = Missions._w(h["at"]) + Vector3(2.7, 0, 0.9)
	pos.y = Game.ground_height(pos.x, pos.z)
	var ch = Node3D.new()
	get_tree().current_scene.add_child(ch)
	ch.global_position = pos
	ch.rotation.y = 0.5
	var b = MB.new()
	RogueHut.chest_mesh(b, Vector3.ZERO)
	_part(ch, b)
	_own(ch, true)
	_jitem("loot", label, pos, ch, {"count": true}, 2.8)


## Takasçı: omzundaki sandığı önüne indir, barakadaki malın tamamının parası ödenir
func fence_deal(npc: Node3D) -> void:
	var pl = Game.player
	if rider_kind == "chest" and is_instance_valid(rider) and is_instance_valid(npc):
		var ch = rider
		rider = null
		rider_kind = ""
		busy_run = true
		_lock(8.0)
		var to = (npc.global_position - pl.global_position).slide(Vector3.UP).normalized()
		var spot = pl.global_position + to * 0.8
		spot.y = Game.ground_height(spot.x, spot.z)
		_pose(pl, "grab_low", {"anim": "idle", "at": spot + Vector3.UP * 0.4, "lift": 0.0})
		var from = ch.global_position
		var t := 0.0
		while t < 0.6 and is_instance_valid(ch):
			t += get_process_delta_time()
			var k = smoothstep(0.0, 0.6, t)
			ch.global_position = from.lerp(spot, k) + Vector3.UP * sin(k * PI) * 0.2
			await get_tree().process_frame
		Sfx.play("punch", spot, 0.4, 1.3)
		_clear_pose(pl)
		# takasçı eğilip kapağı yoklar
		_look_at(npc, spot)
		_pose(npc, "grab_low", {"anim": "idle", "at": spot + Vector3.UP * 0.45, "lift": 0.0})
		await _wait(0.9)
		_clear_pose(npc)
		_release_player()
		busy_run = false
	var l = RogueHut.loot()
	var total = int(l.get("chest", 0)) * RogueJobs.CHEST_RYO + int(l.get("sack", 0)) * RogueJobs.SACK_RYO
	Hud.msg("Takasçı %d sandık ve %d çuval için %d Ryō saydı. Adamları gece malı barakadan alacak." % [int(l.get("chest", 0)), int(l.get("sack", 0)), total], Color(1, 0.9, 0.5), 7.0)
	l["chest"] = 0
	l["sack"] = 0
	Progress.add_ryo(total)


## İş bitti, dönüş yolu: olay yerinde kendi izlerin duruyor (silmek isteğe bağlı)
func traces_begin() -> void:
	var pl = Game.player
	if pl == null:
		return
	var c = pl.global_position
	var a0 = randf() * TAU
	for i in 2:
		var q = Missions.open_ground(c + Vector3(cos(a0 + i * 2.4), 0, sin(a0 + i * 2.4)) * (3.5 + i * 2.0), 4.0)
		make("trace", q, randf() * TAU, i, "[F] İzini sil", {"ck": ["prints", "bandana"][i], "silent": true})
	Hud.msg("Olay yerinde izlerin kaldı: ayak izleri ve düşürdüğün bez. Silersen iz sürücüler seni geç bulur; silmezsen yola çık.", Color(1, 0.9, 0.6), 7.0)


## İzi sil: çök, dalla süpür / bezi al
func _act_wipe(it: Dictionary) -> void:
	var pl = Game.player
	var w: Node3D = it["node"]
	it["silent"] = true
	await _stand_at(w, 0.7)
	_pose(pl, "grab_low", {"sit": "seiza", "anim": "idle", "at": w.global_position + Vector3.UP * 0.1, "lift": 0.0})
	for k in 3:
		await _wait(0.32)
		Sfx.play("pickup", w.global_position, 0.3, 0.7 + k * 0.1)
		FX.burst(w.global_position + Vector3.UP * 0.08, {"amount": 10, "life": 0.5, "size": 0.12, "dir": Vector3.UP, "spread": 85.0, "vmin": 0.4, "vmax": 1.4, "gravity": Vector3(0, -1.5, 0), "colors": [Color(0.6, 0.52, 0.4, 0.7), Color(0.6, 0.52, 0.4, 0)]})
		if is_instance_valid(w):
			w.scale = Vector3.ONE * (1.0 - (k + 1) * 0.3)
	if is_instance_valid(w):
		w.queue_free()
	var m = Missions.active()
	if not m.is_empty():
		m["flags"]["wiped"] = int(m["flags"].get("wiped", 0)) + 1
	Hud.float_text("İz silindi", Color(0.8, 1, 0.8))
	_clear_pose(pl)
