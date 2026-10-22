extends Node3D
## Köy hayatı yöneticisi: oyuncu bir köydeyken çevresinde kalabalık tutar (yakında doğar, uzaklaşınca kaybolur).
## Sokak noktaları biyom haritasındaki yol pikselleri, çatılar ve tezgahlar Builder kayıtlarından gelir.

const ROLES := [["walker", 40], ["kid", 18], ["chat", 10], ["patrol", 8], ["roof", 6], ["sitter", 6], ["animal", 8]]

var npcs: Array = []
var current := ""
var t := 0.0
var street_cache := {}


func _village_at(p: Vector3) -> Dictionary:
	var m = Game.to_map(p)
	for v in Game.world_info["villages"]:
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 1.05:
			return v
	return {}


func _streets(v: Dictionary) -> Array:
	if street_cache.has(v["id"]):
		return street_cache[v["id"]]
	var pts: Array = []
	var r: float = v["r"]
	var tries = 0
	while pts.size() < 260 and tries < 6000:
		tries += 1
		var a = randf() * TAU
		var d = sqrt(randf()) * r * 0.95
		var x = float(v["x"]) + cos(a) * d
		var y = float(v["y"]) + sin(a) * d
		var px = clampi(int((x - Game.x0) / Game.res), 0, Game.hw - 1)
		var py = clampi(int((Game.y1 - y) / Game.res), 0, Game.hh - 1)
		var road = Game.biome_img.get_pixel(px, py).g
		if road > 0.4 or tries > 4000:
			pts.append(Game.from_map(Vector2(x, y)))
	street_cache[v["id"]] = pts
	return pts


func _process(dt: float) -> void:
	t -= dt
	if t > 0.0 or Game.player == null or Game.paused:
		return
	t = 0.8
	var p = Game.player.global_position
	var v = _village_at(p)
	# uzaklaşanları temizle
	for n in npcs.duplicate():
		if not is_instance_valid(n):
			npcs.erase(n)
		elif n.global_position.distance_to(p) > 150.0 or v.is_empty():
			n.queue_free()
			npcs.erase(n)
	if v.is_empty():
		current = ""
		return
	var target = 55 if v["id"] == "konoha" else 26
	var streets = _streets(v)
	var roofs: Array = Builder.roof_points.get(v["id"], [])
	var spawned = 0
	while npcs.size() < target and spawned < 4:
		spawned += 1
		var role = _pick_role()
		var near: Array = streets.filter(func(q): return q.distance_to(p) < 120.0 and q.distance_to(p) > (35.0 if current == v["id"] else 4.0))
		if near.is_empty():
			break
		var at: Vector3 = near.pick_random()
		match role:
			"animal":
				var c = CatNPC.new()
				c.ambient = true
				c.is_dog = randf() < 0.5
				add_child(c)
				c.global_position = at
				npcs.append(c)
			"chat":
				var a = _villager("chat", at, streets)
				var b = _villager("chat", at + Vector3(1.4, 0, 0.3), streets)
				a.buddy = b
				b.buddy = a
			"kid":
				for k in randi_range(2, 4):
					_villager("kid", at + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), streets)
			"roof":
				var near_roofs: Array = roofs.filter(func(q): return q.distance_to(p) < 110.0)
				if near_roofs.size() > 3:
					_villager("roof", near_roofs.pick_random(), near_roofs)
			_:
				_villager(role, at, streets)
	current = v["id"]


func _pick_role() -> String:
	var total = 0
	for r in ROLES:
		total += r[1]
	var k = randi() % total
	for r in ROLES:
		k -= r[1]
		if k < 0:
			return r[0]
	return "walker"


func _villager(role: String, at: Vector3, pts: Array) -> Villager:
	var vg = Villager.new()
	vg.role = role
	vg.points = pts
	add_child(vg)
	at.y = Game.ground_height(at.x, at.z) if role != "roof" else at.y
	vg.global_position = at
	vg.home = at
	npcs.append(vg)
	return vg
