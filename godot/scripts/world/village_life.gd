extends Node3D
## Köy hayatı yöneticisi: oyuncu bir köydeyken çevresinde kalabalık tutar (yakında doğar, uzaklaşınca kaybolur).
## Günün saatine göre program: sabah işe/akademiye gidenler, öğlen pazar kalabalığı, akşam eve dönenler, gece nöbetçiler.
## Sabit mekânlar (tezgâhlar, antrenman, inşaat, banklar, top oynayan çocuklar, kapı nöbetçileri, meyhane önü)
## Builder kayıtlarından (sites) gelir; oyuncu yaklaşınca canlanır.

## köy id -> [{type, pos, face(rad), ...}]
static var sites := {}
static var doors := {}  # köy id -> [kapı önü noktaları] (akşam eve girenler)

const PHASE_ROLES := {
	"sabah": [["walker", 40], ["kid", 26], ["chat", 8], ["patrol", 8], ["roof", 6], ["animal", 8]],
	"oglen": [["walker", 36], ["kid", 14], ["chat", 16], ["shopper", 18], ["patrol", 6], ["roof", 6], ["animal", 8]],
	"aksam": [["walker", 50], ["kid", 8], ["chat", 16], ["patrol", 8], ["roof", 4], ["animal", 8]],
	"gece": [["walker", 14], ["patrol", 16], ["roof", 4], ["animal", 6]],
}

var npcs: Array = []
var current := ""
var t := 0.0
var street_cache := {}
var queue: Array = []  # bekleyen doğumlar: her karede en fazla bir karakter modeli yaratılır (takılma olmasın)
var active_sites := {}  # site index -> [nodes]
var phase := "oglen"
var interiors: Interiors
var crowd: AudioStreamPlayer3D
var glow_t := 0.0


func _ready() -> void:
	interiors = Interiors.new()
	interiors.name = "Interiors"
	add_child(interiors)
	_add_village_trainers()


func _village_at(p: Vector3) -> Dictionary:
	if interiors and interiors.inside != "":
		return {}
	var m = Game.to_map(p)
	for v in Game.world_info["villages"]:
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 1.05:
			return v
	return {}


## Köyün sokak noktaları: yol ağındaki "street" parçalarından örneklenir (yanlara hafif sapma)
func _streets(v: Dictionary) -> Array:
	if street_cache.has(v["id"]):
		VillageSpots.top_up(street_cache[v["id"]], v)   # ara sokak / avlu / park noktaları (parklar sonradan kurulur)
		return street_cache[v["id"]]
	var pts: Array = []
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r: float = v["r"]
	var segs: Array = Game.road_segments_near(c, r)
	for e in segs:
		var rd: Dictionary = Game.roads[e.x]
		if rd["kind"] != "street" and rd["kind"] != "road":
			continue
		var pa: Vector2 = rd["pts"][e.y]
		var pb: Vector2 = rd["pts"][e.y + 1]
		var L = pa.distance_to(pb)
		var n = int(L / 18.0)
		for i in n:
			var q = pa.lerp(pb, (float(i) + randf()) / maxf(1.0, n))
			if q.distance_to(c) > r * 0.97:
				continue
			var side = (pb - pa).normalized().orthogonal() * randf_range(-4.0, 4.0)
			pts.append(Game.from_map(q + side))
	if pts.is_empty():
		for i in 120:
			var a2 = randf() * TAU
			pts.append(Game.from_map(c + Vector2(cos(a2), sin(a2)) * sqrt(randf()) * r * 0.9))
	VillageSpots.top_up(pts, v)
	street_cache[v["id"]] = pts
	return pts


## Büyük köylerin antrenman alanına eğitmen (etkileşim + NPC). Konoha kendi kurulumunda ekler.
func _add_village_trainers() -> void:
	for vid in ["suna", "kiri", "kumo", "iwa", "ame", "kusa", "taki", "oto", "yu", "shimo", "tani", "nami", "uzushio", "tetsu"]:
		var v = Game.village(vid)
		if v.is_empty():
			continue
		var has = false
		for it in Interact.items:
			if it["kind"] == "trainer" and it.get("village", "") == vid:
				has = true
		if has:
			continue
		var c = Vector2(float(v["x"]), float(v["y"]))
		var r = float(v["r"])
		var best = c + Vector2(r * 0.3, 0)
		var bd = 1e9
		for e in Game.road_segments_near(c, r * 0.6):
			var rd: Dictionary = Game.roads[e.x]
			var q: Vector2 = (rd["pts"][e.y] + rd["pts"][e.y + 1]) * 0.5
			var d = absf(q.distance_to(c) - r * 0.3)
			if d < bd:
				bd = d
				var dirv: Vector2 = (rd["pts"][e.y + 1] - rd["pts"][e.y]).normalized()
				best = q + dirv.orthogonal() * 10.0
		var wp = Game.from_map(best)
		var title = "%s Eğitmeni" % String(v.get("name", vid)).replace("gakure", "")
		Interact.add({"pos": wp + Vector3(0, 0.4, 0), "radius": 3.5, "kind": "trainer", "village": vid, "title": title,
			"label": "[F] %s: jutsu öğren" % title})
		if not sites.has(vid):
			sites[vid] = []
		sites[vid].append({"type": "trainer", "pos": wp + Vector3(0, 0, -1.2), "face": 0.0, "title": title})


static func _phase_of(tod: float) -> String:
	if tod < 0.24 or tod > 0.8:
		return "gece"
	if tod < 0.42:
		return "sabah"
	if tod < 0.62:
		return "oglen"
	return "aksam"


func _process(dt: float) -> void:
	# gece parıltısı (fenerler) — saniyede bir
	glow_t -= dt
	if glow_t <= 0.0 and Game.world:
		glow_t = 1.0
		var tod: float = Game.world.env.time_of_day
		var nk = 1.0 - smoothstep(0.22, 0.3, tod) + smoothstep(0.72, 0.8, tod)
		CityDecor.set_night(clampf(nk, 0.0, 1.0))
	if Game.player == null or Game.paused:
		return
	if not queue.is_empty():
		_spawn(queue.pop_front())
	t -= dt
	if t > 0.0:
		return
	t = 0.8
	var p = Game.player.global_position
	var v = _village_at(p)
	var tod2: float = Game.world.env.time_of_day if Game.world else 0.5
	var new_phase = _phase_of(tod2)
	if new_phase != phase:
		phase = new_phase
		if phase == "aksam" or phase == "gece":
			_send_home(v)
	# uzaklaşanları temizle (karede birkaç tane)
	var freed = 0
	for n in npcs.duplicate():
		if not is_instance_valid(n):
			npcs.erase(n)
		elif (n.global_position.distance_to(p) > 150.0 or v.is_empty()) and freed < 6:
			freed += 1
			n.queue_free()
			npcs.erase(n)
	_relocate(v)
	_update_sites(v, p)
	_update_crowd(v, p)
	if v.is_empty():
		current = ""
		queue = queue.filter(func(r): return r[0] == "__never")
		return
	# büyük gizli köyler Konoha kadar kalabalık; küçük kasabalar daha sakin (eskiden 22 kişi koca köye dağılıp boş görünüyordu)
	var big = v["id"] in ["konoha", "suna", "kiri", "kumo", "iwa"]
	var base = int((36 if big else 18) * maxf(0.7, Game.npc_scale))
	var target = base if phase != "gece" else int(base * 0.4)
	var streets = _streets(v)
	var roofs: Array = Builder.roof_points.get(v["id"], [])
	var planned = npcs.size() + queue.size()
	var groups = 0
	while planned < target and groups < 3:
		groups += 1
		var role = _pick_role()
		var near: Array = streets.filter(func(q): return q.distance_to(p) < 100.0 and q.distance_to(p) > (22.0 if current == v["id"] else 4.0))
		if near.is_empty():
			# yakında sokak noktası yok (Kiri'nin geniş meydanları, köprüler): uzaktaki sokaklar, o da yoksa çevredeki açık zemin
			near = streets.filter(func(q): return q.distance_to(p) < 220.0)
		if near.is_empty():
			for k in 6:
				var a = randf() * TAU
				var q = Missions.open_ground(p + Vector3(cos(a), 0, sin(a)) * randf_range(25.0, 70.0), 12.0)
				if Game.terrain_height(q.x, q.z) > 0.3:   # suya değil
					near.append(q)
		if near.is_empty():
			break
		var at: Vector3 = near.pick_random()
		match role:
			"chat":
				queue.append(["chat2", at, streets])
				planned += 2
			"kid":
				for k in randi_range(2, 4):
					queue.append(["kid", at + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), streets])
					planned += 1
			"roof":
				var near_roofs: Array = roofs.filter(func(q): return q.distance_to(p) < 110.0)
				if near_roofs.size() > 3:
					queue.append(["roof", near_roofs.pick_random(), near_roofs])
					planned += 1
			"shopper":
				var stalls = _stalls(v)
				if not stalls.is_empty():
					queue.append(["shopper", at, stalls])
					planned += 1
			_:
				queue.append([role, at, streets])
				planned += 1
	current = v["id"]


## Kurulumda (fizik yokken) konan tezgâhlar: oyuncu köydeyken bir kez açık zemine taşınır
var _relocated := {}


func _relocate(v: Dictionary) -> void:
	if v.is_empty() or _relocated.get(v["id"], 0.0) < 0.0:
		return
	# köye girdikten ~3 sn sonra (binaların çarpışma gövdeleri yüklenmiş olsun)
	_relocated[v["id"]] = float(_relocated.get(v["id"], 0.0)) + 0.8
	if float(_relocated[v["id"]]) < 3.0:
		return
	_relocated[v["id"]] = -1.0
	for it in Interact.items:
		if not it.get("relocate", false) or String(it.get("village", "")) != String(v["id"]):
			continue
		var off: Vector3 = it.get("node_off", Vector3.ZERO)
		var base: Vector3 = it["pos"] + off
		var q = Missions.open_ground(base, 40.0)
		it["pos"] = q - off
		var n = it.get("node")
		if n and is_instance_valid(n):
			n.global_position = q


func _stalls(v: Dictionary) -> Array:
	var out = []
	for s in sites.get(v["id"], []):
		if s["type"] == "stall":
			out.append({"front": s["front"], "face": s["face"]})
	return out


## Akşam: sokaktaki yürüyenlerin bir kısmı en yakın kapıya yürüyüp "eve girer"
func _send_home(v: Dictionary) -> void:
	if v.is_empty():
		return
	var ds: Array = doors.get(v["id"], [])
	if ds.is_empty():
		return
	for n in npcs:
		if is_instance_valid(n) and n is Villager and n.role in ["walker", "kid", "chat"] and randf() < (0.5 if phase == "aksam" else 0.85):
			var best = ds[0]
			var bd = 1e9
			for k in 12:
				var q: Vector3 = ds.pick_random()
				var d = q.distance_to(n.global_position)
				if d < bd:
					bd = d; best = q
			n.role = "walker"
			n.going_home = true
			n.goal = best
			n.wait = 0.0


func _pick_role() -> String:
	var roles: Array = PHASE_ROLES[phase]
	var total = 0
	for r in roles:
		total += r[1]
	var k = randi() % total
	for r in roles:
		k -= r[1]
		if k < 0:
			return r[0]
	return "walker"


func _spawn(req: Array) -> void:
	match req[0]:
		"animal":
			var c = CatNPC.new()
			c.ambient = true
			c.is_dog = randf() < 0.5
			add_child(c)
			c.global_position = req[1]
			npcs.append(c)
		"chat2":
			# sohbet çifti: ikinci kişi bir sonraki karede gelir
			var a = _villager("chat", req[1], req[2])
			queue.push_front(["chat_b", req[1] + Vector3(1.4, 0, 0.3), req[2], a])
		"chat_b":
			var b = _villager("chat", req[1], req[2])
			var a = req[3]
			if is_instance_valid(a):
				a.buddy = b
				b.buddy = a
		"site":
			_spawn_site_actor(req[1], req[2], req[3])
		_:
			var vg = _villager(req[0], req[1], req[2])
			if req[0] == "shopper":
				vg._pick_stall()
			elif req[0] == "kid" and phase == "sabah":
				# sabah çocuklar akademiye koşar
				var ac = _site_pos(current, "academy_yard")
				if ac != Vector3.INF:
					vg.home = ac + Vector3(randf_range(-10, 10), 0, randf_range(-6, 6))
					vg.goal = vg.home


func _site_pos(vid: String, type: String) -> Vector3:
	for s in sites.get(vid, []):
		if s["type"] == type:
			return s["pos"]
	return Vector3.INF


func _villager(role: String, at: Vector3, pts: Array, extra := {}) -> Villager:
	var vg = Villager.new()
	vg.role = role
	vg.points = pts
	vg.night = phase == "gece"
	for k in extra:
		vg.set(k, extra[k])
	add_child(vg)
	at.y = Game.ground_height(at.x, at.z) if role != "roof" else at.y
	vg.global_position = at
	vg.home = at
	npcs.append(vg)
	return vg


# ------------------------------------------------------------------ sabit mekânlar
func _site_ok(s: Dictionary) -> bool:
	match s["type"]:
		"stall", "work", "bench", "spar", "ball":
			return phase != "gece"
		"bar":
			return phase == "gece" or phase == "aksam"
		"academy_yard", "crowd", "pigeons":
			return s["type"] == "pigeons" and phase != "gece"
	return true


func _update_sites(v: Dictionary, p: Vector3) -> void:
	# uzaklaşan / saati geçen mekânları kapat
	for key in active_sites.keys():
		var info: Dictionary = active_sites[key]
		var s: Dictionary = info["site"]
		if v.is_empty() or s["pos"].distance_to(p) > 150.0 or not _site_ok(s):
			for n in info["nodes"]:
				if is_instance_valid(n):
					n.queue_free()
			active_sites.erase(key)
	if v.is_empty():
		return
	var list: Array = sites.get(v["id"], [])
	for i in list.size():
		var s: Dictionary = list[i]
		var key = "%s_%d" % [v["id"], i]
		if active_sites.has(key) or not _site_ok(s):
			continue
		if s["pos"].distance_to(p) < 110.0:
			active_sites[key] = {"site": s, "nodes": []}
			_open_site(key, s)


func _open_site(key: String, s: Dictionary) -> void:
	var pos: Vector3 = s["pos"]
	var f: float = s.get("face", 0.0)
	match s["type"]:
		"stall":
			queue.append(["site", key, "vendor", {"pos": s["back"], "face": f + PI, "fixed_face": true}])
		"spar":
			queue.append(["site", key, "spar", {"pos": pos + Vector3(1.1, 0, 0), "pair": "a"}])
			queue.append(["site", key, "spar", {"pos": pos - Vector3(1.1, 0, 0), "pair": "b"}])
		"work":
			for k in 2:
				var o = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
				queue.append(["site", key, "worker", {"pos": pos + o, "face": randf() * TAU, "work_anims": [["b/TreeChopping", "a/Fixing_Kneeling"], ["a/Push", "a/Fixing_Kneeling", "b/TreeChopping"]][k]}])
			queue.append(["site", key, "worker", {"pos": pos + Vector3(4, 0, 0), "work_points": [pos + Vector3(6, 0, 3), pos + Vector3(-5, 0, -2)]}])
		"bench":
			queue.append(["site", key, "sitter", {"pos": pos, "face": f, "fixed_face": true}])
			if randf() < 0.5:
				queue.append(["site", key, "sitter", {"pos": pos + Vector3(cos(f), 0, -sin(f)) * 0.7, "face": f, "fixed_face": true}])
		"ball":
			var bg = BallGame.new()
			add_child(bg)
			bg.global_position = pos
			active_sites[key]["nodes"].append(bg)
			for k in 3:
				queue.append(["site", key, "ball", {"pos": pos + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)), "game": bg}])
		"guard":
			queue.append(["site", key, "guard", {"pos": pos, "face": f, "fixed_face": true}])
		"bar":
			queue.append(["site", key, "drunk", {"pos": pos}])
		"trainer":
			queue.append(["site", key, "teacher", {"pos": pos, "face": f, "fixed_face": true, "display_override": s.get("title", "Jonin Eğitmen"),
				"lines_override": ["Antrenmana hazır mısın?", "Önce temel, sonra ileri teknikler.", "Chakra kontrolün gelişiyor!"], "wander_r": 1.2}])
		"pigeons":
			var fl = PigeonFlock.new()
			add_child(fl)
			fl.global_position = pos
			active_sites[key]["nodes"].append(fl)
		"ramen":
			queue.append(["site", key, "keeper", {"pos": s["back"], "face": f + PI, "fixed_face": true, "display_override": "Ramen Ustası", "lines_override": ["Miso chashu mu, shio mu?", "Ekstra naruto dilimi koydum!", "Bir kase daha?"]}])
			for k in 2:
				var sp: Vector3 = s["seats"][k * 2 + 1]
				queue.append(["site", key, "customer", {"pos": sp, "face": f, "fixed_face": true, "eat_mode": true}])


func _spawn_site_actor(key: String, role: String, d: Dictionary) -> void:
	if not active_sites.has(key):
		return
	var extra = {}
	for k in ["fixed_face", "work_anims", "work_points", "display_override", "lines_override", "eat_mode", "wander_r"]:
		if d.has(k):
			extra[k] = d[k]
	var vg = _villager(role, d["pos"], [], extra)
	npcs.erase(vg)  # mekân aktörleri sokak sayısına dahil değil
	if d.has("face"):
		vg.facing = d["face"]
		vg.stand_face = d["face"]
		vg.model.rotation.y = vg.facing
	active_sites[key]["nodes"].append(vg)
	if role == "spar":
		for n in active_sites[key]["nodes"]:
			if n != vg and n is Villager and n.role == "spar":
				n.buddy = vg
				vg.buddy = n
	if role == "ball" and d.has("game") and is_instance_valid(d["game"]):
		d["game"].kids.append(vg)


func _update_crowd(v: Dictionary, p: Vector3) -> void:
	var cpos = _site_pos(v.get("id", ""), "crowd") if not v.is_empty() else Vector3.INF
	if cpos == Vector3.INF:
		if crowd:
			crowd.stop()
		return
	if crowd == null:
		crowd = AudioStreamPlayer3D.new()
		var s = load("res://assets/sfx/crowd.wav")
		if s == null:
			return
		s = s.duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
		crowd.stream = s
		crowd.unit_size = 30.0
		crowd.max_distance = 140.0
		add_child(crowd)
	crowd.global_position = cpos
	var vol = {"sabah": 0.45, "oglen": 1.0, "aksam": 0.6, "gece": 0.0}[phase] * float(Game.settings["sfx"]) * 0.7
	if vol <= 0.01:
		crowd.stop()
		return
	crowd.volume_db = linear_to_db(vol)
	if not crowd.playing:
		crowd.play()


# ------------------------------------------------------------------ top oynayan çocuklar
class BallGame extends Node3D:
	var kids: Array = []
	var ball: MeshInstance3D
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var k := 1.0
	var holder: Node3D = null
	var hold_t := 0.0

	func _ready() -> void:
		ball = MeshInstance3D.new()
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(0.32, 0.32, 0.32), Color(0.9, 0.25, 0.2), Vector3.ZERO, 10)
		b.add("box", Vector3.ZERO, Vector3(0.33, 0.05, 0.05), Color(1, 1, 1))
		ball.mesh = b.build(Props.toon())
		add_child(ball)
		from = global_position
		to = global_position

	func _process(dt: float) -> void:
		kids = kids.filter(func(x): return is_instance_valid(x))
		if kids.size() < 2 or Game.paused:
			return
		if k < 1.0:
			k = minf(1.0, k + dt / maxf(0.5, from.distance_to(to) / 7.0))
			var p = from.lerp(to, k)
			p.y = Game.terrain_height(p.x, p.z) + 0.16 + sin(k * PI) * minf(2.5, from.distance_to(to) * 0.25)
			ball.global_position = p
			ball.rotation.x += dt * 10.0
			if holder:
				holder.goal = to
			return
		# top yere düştü: en yakın çocuk gelir ve vurur
		if holder == null or not is_instance_valid(holder):
			var best = kids[0]
			for c in kids:
				if c.global_position.distance_to(ball.global_position) < best.global_position.distance_to(ball.global_position):
					best = c
			holder = best
			hold_t = 0.0
		holder.goal = ball.global_position
		for c in kids:
			if c != holder and c.goal.distance_to(global_position) > 9.0:
				c.goal = global_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
		hold_t += dt
		if holder.global_position.distance_to(ball.global_position) < 0.9 or hold_t > 4.0:
			holder.kick_ball()
			var others = kids.filter(func(x): return x != holder)
			var target = others.pick_random()
			from = ball.global_position
			to = target.global_position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
			to = global_position + (to - global_position).limit_length(9.0)
			k = 0.0
			holder = target
			if randf() < 0.4:
				Sfx.play("punch", from, 1.6, 0.25)


# ------------------------------------------------------------------ güvercinler: yerde gagalar, yaklaşınca havalanır
class PigeonFlock extends Node3D:
	var birds: Array = []
	var flying := -1.0
	var reset_t := 0.0
	static var _mesh: ArrayMesh

	func _ready() -> void:
		if _mesh == null:
			var b = MB.new()
			b.add("sphere", Vector3(0, 0.12, 0), Vector3(0.16, 0.14, 0.26), Color(0.55, 0.57, 0.62), Vector3.ZERO, 6)
			b.add("sphere", Vector3(0, 0.22, -0.12), Vector3(0.1, 0.1, 0.1), Color(0.45, 0.5, 0.58), Vector3.ZERO, 6)
			b.add("cone", Vector3(0, 0.21, -0.19), Vector3(0.03, 0.06, 0.03), Color(0.85, 0.6, 0.3), Vector3(-90, 0, 0), 4)
			b.add("box", Vector3(0, 0.13, 0.15), Vector3(0.1, 0.02, 0.12), Color(0.4, 0.42, 0.48))
			_mesh = b.build(Props.toon())
		for i in 12:
			var m = MeshInstance3D.new()
			m.mesh = _mesh
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(m)
			birds.append({"n": m, "o": Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)), "ph": randf() * TAU, "v": Vector3.ZERO})
		_land()

	func _land() -> void:
		flying = -1.0
		for b in birds:
			var p = global_position + b["o"]
			p.y = Game.terrain_height(p.x, p.z)
			b["n"].global_position = p
			b["n"].rotation.y = randf() * TAU
			b["n"].visible = true

	func _process(dt: float) -> void:
		if Game.player == null or Game.paused:
			return
		var pd = Game.player.global_position.distance_to(global_position)
		if flying < 0.0:
			if pd < 5.0:
				flying = 0.0
				Sfx.play("whoosh", global_position, 1.8, 0.4)
				for b in birds:
					b["v"] = Vector3(randf_range(-3, 3), randf_range(5, 8), randf_range(-3, 3))
				return
			var tt = Time.get_ticks_msec() * 0.001
			for b in birds:
				var peck = maxf(0.0, sin(tt * 3.0 + b["ph"]))
				b["n"].rotation.x = -peck * 0.6
				if randf() < dt * 0.3:
					b["n"].rotation.y += randf_range(-1.0, 1.0)
			return
		flying += dt
		for b in birds:
			b["n"].global_position += b["v"] * dt
			b["v"] += Vector3(0, -1.0, 0) * dt
			b["n"].rotation.x = sin(flying * 30.0 + b["ph"]) * 0.4
		if flying > 3.0:
			for b in birds:
				b["n"].visible = false
			reset_t += dt
			if reset_t > 20.0 and pd > 25.0:
				reset_t = 0.0
				_land()
