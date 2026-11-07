extends Node3D
## Yol trafiği: oyuncunun çevresindeki yollarda yürüyen yolcular, tüccar kervanları (öküz arabası), hacılar, devriyeler.
## Gruplar yol çoklu çizgisini izler; uzaklaşınca silinir. [F] ile konuşulur.

const MAX_GROUPS := 7
const SPAWN_MIN := 260.0
const SPAWN_MAX := 750.0
const DESPAWN := 1100.0

var _t := 0.0


func _process(dt: float) -> void:
	if Game.player == null:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = 1.2
	var p = Game.player.global_position
	for g in get_children():
		if g.global_position.distance_to(p) > DESPAWN or g.done:
			g.queue_free()
	if get_child_count() >= MAX_GROUPS:
		return
	var m = Vector2(p.x, -p.z)
	var segs = Game.road_segments_near(m, SPAWN_MAX)
	segs.shuffle()
	for e in segs:
		var rl: Dictionary = Game.roads[e.x]
		if rl["kind"] != "road":
			continue
		var pts: PackedVector2Array = rl["pts"]
		var a: Vector2 = pts[e.y]
		var b: Vector2 = pts[e.y + 1]
		var t = randf()
		var q = a.lerp(b, t)
		var d = q.distance_to(m)
		if d < SPAWN_MIN or d > SPAWN_MAX:
			continue
		# köy içinde doğma
		var inside = false
		for v in Game.world_info["villages"]:
			if q.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) + 120.0:
				inside = true
		if inside:
			continue
		var g = TravelGroup.new()
		g.road = e.x
		g.seg = e.y
		g.t = t
		g.dir = 1 if randf() < 0.5 else -1
		g.kind = ["yolcu", "yolcu", "kervan", "hacı", "kervan", "ninja"][randi() % 6]
		add_child(g)
		return


class TravelGroup extends Node3D:
	const LINES := {
		"yolcu": ["Bir sonraki köye daha çok var mı? Ayaklarım şişti.", "Yolda haydut görürsen hemen kaç, kahramanlık yapma.", "Bu yolda eski bir han vardı, yemekleri efsaneydi."],
		"kervan": ["İpek ve baharat taşıyoruz. Sınır karakolları yine vergi istedi...", "Ninja koruması tutmak pahalı ama haydutlar daha pahalı.", "Kum Ülkesi'ne kadar gideceğiz, su matarası unutma!"],
		"hacı": ["Tepe tapınağına adak götürüyorum. Yol uzun ama kalp hafif.", "Atalar yolu gösterir evlat."],
		"ninja": ["Görevdeyim, oyalanamam.", "Sınırda tuhaf hareketler var, dikkatli ol."],
	}
	var road := 0
	var seg := 0
	var t := 0.0
	var dir := 1
	var kind := "yolcu"
	var speed := 1.5
	var members: Array = []   # [node, geri mesafe, yanal ofset, insan mı]
	var done := false
	var display := "Yolcu"

	func _ready() -> void:
		add_to_group("talkers")
		var n = 1
		match kind:
			"yolcu":
				n = randi_range(1, 2)
				display = "Yolcu"
			"kervan":
				n = 2
				display = "Tüccar"
				speed = 1.2
				_add_ox_cart()
			"hacı":
				n = randi_range(2, 4)
				display = "Hacı"
				speed = 1.1
			"ninja":
				n = randi_range(2, 3)
				display = "Gezgin Ninja"
				speed = 4.2
		for i in n:
			await CharacterModel.build_turn(self)   # kafile üyeleri ayrı karelerde kurulur (donma olmasın)
			if not is_inside_tree():
				return
			var cm = CharacterModel.new()
			add_child(cm)
			cm.setup(_look(i))
			cm.play("run" if kind == "ninja" else "walk", 0.0)
			members.append([cm, 2.0 + i * 1.8 + (6.0 if kind == "kervan" else 0.0), randf_range(-1.2, 1.2), true])
		_place()

	func _look(i: int) -> Dictionary:
		var tops = [Color(0.5, 0.6, 0.45), Color(0.6, 0.35, 0.3), Color(0.8, 0.75, 0.55), Color(0.4, 0.45, 0.6), Color(0.55, 0.42, 0.3)]
		var lk = {"gender": ["m", "f"].pick_random(), "top": tops.pick_random(), "pants": Color(0.35, 0.3, 0.28), "band": null,
			"hair_style": ["kısa", "uzun", "atkuyruğu", "kase"].pick_random(), "hair": Color(0.15, 0.1, 0.08), "pants_style": "sivil",
			"sandal": Color(0.35, 0.25, 0.15), "age": "adult", "beard": randf() < 0.3}
		match kind:
			"hacı":
				lk.merge({"top": Color(0.92, 0.9, 0.85), "pants": Color(0.92, 0.9, 0.85), "hair": Color(0.7, 0.7, 0.72)}, true)
			"ninja":
				lk.merge({"vest": Color(0.38, 0.48, 0.28), "top": Color(0.18, 0.22, 0.3), "pants": Color(0.18, 0.22, 0.3), "pants_style": "ninja",
					"band": Color(0.15, 0.22, 0.55), "top_style": "uzun", "weapon_r": "kunai"}, true)
		lk["top2"] = Color(lk["top"]).darkened(0.2)
		# yol kalabalığı: hacılar keşiş, ninja kafilesi köy üniforması, kervan tüccar/gezgin/çiftçi kıyafeti
		var oa: String = {"hacı": "monk", "ninja": "chunin"}.get(kind, ["traveler", "merchant", "farmer", "traveler"][i % 4])
		lk.merge(Outfits.roll(oa, Outfits.village_near()), true)
		lk["npc"] = true   # saç tutamı donması önlemi (köylülerle aynı)
		lk["npc_strict"] = true
		return lk

	func _add_ox_cart() -> void:
		var od: Dictionary = TownAnimals.ox()   # detaylı yük öküzü (boynuz, hörgüç, boyunduruk, sırt örtüsü)
		var ox: Node3D = od["root"]
		ox.set_meta("legs", od["legs"])
		add_child(ox)
		members.append([ox, 0.0, 0.0, false])
		var cart = MeshInstance3D.new()
		var cb = MB.new()
		var wood = Color(0.52, 0.38, 0.24)
		cb.add("box", Vector3(0, 1.1, 0), Vector3(2.0, 0.25, 3.2), wood)
		cb.add("box", Vector3(0, 1.7, 0.2), Vector3(1.8, 1.0, 2.4), Color(0.78, 0.7, 0.52))
		cb.add("sphere", Vector3(0, 2.3, 0.2), Vector3(1.6, 0.6, 2.2), Color(0.85, 0.82, 0.72), Vector3.ZERO, 8)
		for sx in [-1.0, 1.0]:
			cb.add("cyl", Vector3(1.05 * sx, 0.7, 0), Vector3(1.4, 0.15, 1.4), wood.darkened(0.3), Vector3(0, 0, 90), 10)
		cb.add("box", Vector3(0, 0.95, -2.3), Vector3(0.12, 0.12, 1.8), wood)
		cart.mesh = cb.build(Props.toon())
		add_child(cart)
		members.append([cart, 3.6, 0.0, false])

	func talk() -> void:
		var pool: Array = LINES.get(kind, LINES["yolcu"])
		Hud.dialog(display, pool.pick_random(), [])

	## yol üzerinde s mesafe geri -> dünya konumu ve yön
	func _at(back: float) -> Array:
		var pts: PackedVector2Array = Game.roads[road]["pts"]
		var si = seg
		var tt = t
		var rem = back
		while rem > 0.0:
			var a: Vector2 = pts[si]
			var b: Vector2 = pts[si + 1]
			var L = maxf(a.distance_to(b), 0.01)
			var avail = (tt * L) if dir > 0 else ((1.0 - tt) * L)
			if rem <= avail:
				tt -= rem / L * dir
				rem = 0.0
			else:
				rem -= avail
				if dir > 0:
					si -= 1
					tt = 1.0
				else:
					si += 1
					tt = 0.0
				if si < 0 or si >= pts.size() - 1:
					si = clampi(si, 0, pts.size() - 2)
					break
		var a2: Vector2 = pts[si]
		var b2: Vector2 = pts[si + 1]
		var q = a2.lerp(b2, clampf(tt, 0.0, 1.0))
		var fwd = (b2 - a2).normalized() * dir
		return [q, fwd]

	## Deniz/göl köprüsündeyse güverteye çık (su altından yürümesin)
	func _onto_deck(m: Vector2, w: Vector3) -> Vector3:
		var dy = Roadside.deck_y(m)
		if dy > w.y:
			w.y = dy
		return w

	func _place() -> void:
		var head = _at(0.0)
		global_position = _onto_deck(head[0], Game.from_map(head[0]))
		for mem in members:
			var r = _at(mem[1])
			var q: Vector2 = r[0]
			var f: Vector2 = r[1]
			var side = Vector2(f.y, -f.x) * mem[2]
			var w = _onto_deck(q + side, Game.from_map(q + side))
			mem[0].global_position = w
			mem[0].rotation.y = atan2(-f.x, f.y)
			if mem[0].has_meta("legs"):   # öküz: adımlar (model yönü kediyle aynı: ek 180° dönüş arabaya bakmasına yol açıyordu)
				var ph = Time.get_ticks_msec() * 0.006
				var lg: Array = mem[0].get_meta("legs")
				for i in lg.size():
					(lg[i] as Node3D).rotation.x = sin(ph + (PI if i in [1, 2] else 0.0)) * 0.35

	func _process(dt: float) -> void:
		if Game.paused:
			return
		if Game.player and global_position.distance_to(Game.player.global_position) < 4.0:
			for mem in members:
				if mem[3]:
					mem[0].play("idle", 0.3)
			return
		for mem in members:
			if mem[3]:
				mem[0].play("run" if kind == "ninja" else "walk", 0.3)
		var pts: PackedVector2Array = Game.roads[road]["pts"]
		var L = maxf(pts[seg].distance_to(pts[seg + 1]), 0.01)
		t += speed * dt / L * dir
		if t > 1.0:
			if seg + 1 >= pts.size() - 1:
				done = true
				return
			seg += 1
			t = 0.0
		elif t < 0.0:
			if seg - 1 < 0:
				done = true
				return
			seg -= 1
			t = 1.0
		_place()
