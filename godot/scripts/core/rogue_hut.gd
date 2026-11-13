class_name RogueHut
extends RefCounted
## Kaçağın kendi barakası: sığınağın yakınında dülgerle birlikte kurulur (inşaat işi), çalınan sandık ve çuvallar içinde durur,
## içinde dinlenilir. Ses getiren işlerden sonra köyün av takımı barakayı bulup yakabilir; yanık baraka yeniden kurulur.
## Kayıt: Orgs.flags()["hut"] = {"at": [harita x, y], "state": "ok" / "burnt", "raid": bool}; ganimet: flags()["loot"] = {"chest", "sack"}

static var node: Node3D = null
static var shown := ""
static var item := {}
static var raiders := []   # barakayı basan av takımı (sen yetiştiysen sahnede)


static func d() -> Dictionary:
	var h = Orgs.flags().get("hut", {})
	return h if h is Dictionary else {}


static func state() -> String:
	return String(d().get("state", ""))


static func loot() -> Dictionary:
	var f = Orgs.flags()
	if not f.has("loot") or not f["loot"] is Dictionary:
		f["loot"] = {"chest": 0, "sack": 0}
	return f["loot"]


static func add_loot(kind: String, n: int) -> void:
	var l = loot()
	l[kind] = int(l.get(kind, 0)) + n


## Ses getiren iş: av takımı barakanın izini bulabilir (sen uzaktayken basar)
static func heat(p: float) -> void:
	if state() == "ok" and randf() < p:
		d()["raid"] = true


static func built(at: Array) -> void:
	Orgs.flags()["hut"] = {"at": at, "state": "ok", "raid": false}
	shown = ""


static func _free() -> void:
	if is_instance_valid(node):
		node.queue_free()
	node = null
	shown = ""
	if not item.is_empty():
		Interact.items.erase(item)
		item = {}


static func tick() -> void:
	var h = d()
	if h.is_empty() or not Orgs.is_rogue() or Game.player == null or Game.world == null:
		if is_instance_valid(node):
			_free()
		return
	if String(Missions.active().get("rjob", "")) == "hut":
		_free()   # yerinde inşaat alanı var
		return
	var pos = Missions._w(h["at"])
	var dist = Vector2(pos.x - Game.player.global_position.x, pos.z - Game.player.global_position.z).length()
	if h.get("raid", false) and String(h["state"]) == "ok":
		_raid_tick(h, pos, dist)
	if dist > 450.0:
		if is_instance_valid(node):
			_free()
		return
	var l = loot()
	var want = "%s:%d:%d" % [String(h["state"]), int(l.get("chest", 0)), int(l.get("sack", 0))]
	if is_instance_valid(node) and shown == want:
		return
	_free()
	pos.y = Game.ground_height(pos.x, pos.z)
	node = Node3D.new()
	Game.world.get_tree().current_scene.add_child(node)
	node.global_position = pos
	if String(h["state"]) == "burnt":
		_build_burnt(pos)
	else:
		_build_ok(pos, l)
	shown = want


## Baskın sessizce olmaz: av takımı yola çıkınca haberi gelir, barakanın yeri işaretlenir. Vaktinde yetişirsen takım
## barakanın başında karşına çıkar; yenersen baraka kurtulur. Yetişmezsen (ya da bırakıp kaçarsan) yakılır.
## Görev / antrenman sırasında baskın başlamaz: haber iş bitince gelir.
static func _raid_tick(h: Dictionary, pos: Vector3, dist: float) -> void:
	var now = Time.get_unix_time_from_system()
	if not h.has("raid_at"):
		if Missions.quiet():
			return
		h["raid_at"] = now + 200.0 + dist / 7.0
		raiders = []
		Game.profile["waypoint"] = [pos.x, pos.y, pos.z, "Barakan — av takımı yolda"]
		Game.profile["track"] = "waypoint"
		Hud.banner("BARAKAN TEHLİKEDE", "Av takımı barakanın izini buldu ve yola çıktı. %d sn içinde yetişirsen savunabilirsin." % int(float(h["raid_at"]) - now), Color(1, 0.5, 0.4))
		Sfx.play("alarm", null, 1.0, 0.6)
		return
	var live = raiders.filter(func(e): return is_instance_valid(e) and not e.is_dead())
	if not raiders.is_empty():
		if live.is_empty():
			# takım yenildi: baraka kurtuldu
			raiders = []
			h["raid"] = false
			h.erase("raid_at")
			RogueJobs.add_trail(-30.0)
			_clear_mark()
			Hud.banner("BARAKAN KURTULDU", "Av takımını barakanın başında durdurdun. İzin soğudu.", Color(0.6, 1.0, 0.7))
			Game.save_game()
		elif dist > 300.0:
			_burn(h)   # bırakıp gittin
		return
	if dist < 70.0:
		raiders = Orgs.hunters_at(pos, 16.0)
		Hud.banner("AV TAKIMI BARAKANDA", "Meşalelerle geldiler. Durdurursan baraka ayakta kalır.", Color(0.9, 0.3, 0.3))
	elif now > float(h["raid_at"]):
		_burn(h)


static func _clear_mark() -> void:
	var wp = Game.profile.get("waypoint")
	if wp is Array and wp.size() >= 4 and String(wp[3]).begins_with("Barakan"):
		Game.profile.erase("waypoint")


static func _burn(h: Dictionary) -> void:
	h["state"] = "burnt"
	h["raid"] = false
	h.erase("raid_at")
	for e in raiders:
		if is_instance_valid(e) and not e.is_dead() and e.global_position.distance_to(Game.player.global_position) > 200.0:
			e.queue_free()
	raiders = []
	_clear_mark()
	Hud.banner("BARAKAN YAKILDI", "Av takımı barakana senden önce vardı ve ateşe verdi.", Color(1, 0.5, 0.4))
	var l = loot()
	var lost = int(l.get("chest", 0)) - int(l.get("chest", 0)) / 2 + int(l.get("sack", 0)) - int(l.get("sack", 0)) / 2
	l["chest"] = int(l.get("chest", 0)) / 2
	l["sack"] = int(l.get("sack", 0)) / 2
	var vn = WorldPeople.vname(String(Orgs.flags().get("rogue_from", Progress.home())))
	WorldNews.headline("%s: av takımı kaçakların barakasını buldu ve ateşe verdi.%s" % [vn, (" İçindeki mallardan %d parça yandı." % lost) if lost > 0 else ""], Color(1, 0.5, 0.4))


static func _solid(body: StaticBody3D, p: Vector3, size: Vector3, yaw := 0.0) -> void:
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = p
	cs.rotation.y = yaw
	body.add_child(cs)


static func chest_mesh(b: MB, at: Vector3, yaw := 0.0) -> void:
	# sandık (kervandakiyle aynı)
	var q = Basis(Vector3.UP, deg_to_rad(yaw))
	b.add("box", at + Vector3(0, 0.2, 0), Vector3(0.7, 0.4, 0.46), Color(0.4, 0.26, 0.16), Vector3(0, yaw, 0))
	b.add("box", at + Vector3(0, 0.44, 0), Vector3(0.72, 0.1, 0.48), Color(0.34, 0.22, 0.14), Vector3(0, yaw, 0))
	for sx in [-0.26, 0.26]:
		b.add("box", at + q * Vector3(sx, 0.24, 0), Vector3(0.06, 0.52, 0.5), Color(0.3, 0.3, 0.33), Vector3(0, yaw, 0))
	b.add("box", at + q * Vector3(0, 0.3, 0.24), Vector3(0.1, 0.12, 0.03), Color(0.78, 0.64, 0.2), Vector3(0, yaw, 0))


static func _build_ok(pos: Vector3, l: Dictionary) -> void:
	var W = MissionWork.I()
	var b = MB.new()
	for sx in [-1.5, 1.5]:
		for sz in [-1.5, 1.5]:
			b.add("box", Vector3(sx, 0.1, sz), Vector3(0.5, 0.22, 0.5), Color(0.58, 0.56, 0.52))
	for s in 4:
		W.stage_mesh(b, s, 0.0)
	# yatak, yastık, yanında fener ve su testisi
	b.add("box", Vector3(-0.75, 0.57, 0.35), Vector3(0.85, 0.07, 1.9), Color(0.36, 0.4, 0.5))
	b.add("box", Vector3(-0.75, 0.62, 0.0), Vector3(0.87, 0.05, 1.1), Color(0.5, 0.3, 0.26))
	b.add("box", Vector3(-0.75, 0.66, 1.1), Vector3(0.5, 0.1, 0.3), Color(0.85, 0.82, 0.74))
	b.add("cyl", Vector3(0.3, 0.72, 1.15), Vector3(0.28, 0.4, 0.28), Color(0.6, 0.38, 0.26), Vector3.ZERO, 8)
	b.add("box", Vector3(1.2, 2.55, 0.0), Vector3(0.05, 0.5, 0.05), Color(0.2, 0.17, 0.14))
	b.add("box", Vector3(1.2, 2.2, 0.0), Vector3(0.2, 0.26, 0.2), Color(0.95, 0.85, 0.6))
	# ganimet: sandıklar ve çuvallar arka duvarın dibinde üst üste
	for i in mini(int(l.get("chest", 0)), 6):
		chest_mesh(b, Vector3(-0.9 + (i % 3) * 0.78, 0.54 + (i / 3) * 0.52, -1.1), (i % 3 - 1) * 7.0)
	for i in mini(int(l.get("sack", 0)), 6):
		b.add("sphere", Vector3(0.75 - (i / 3) * 0.1, 0.72 + (i / 3) * 0.32, -0.3 + (i % 3) * 0.5), Vector3(0.6, 0.36, 0.48), Color(0.75, 0.68, 0.5).darkened((i % 3) * 0.05), Vector3(0, i * 31.0, 0), 8)
	W._part(node, b)
	var lt = OmniLight3D.new()
	lt.light_color = Color(1.0, 0.75, 0.45)
	lt.light_energy = 1.2
	lt.omni_range = 6.0
	lt.position = Vector3(1.2, 2.1, 0)
	node.add_child(lt)
	var body = StaticBody3D.new()
	node.add_child(body)
	for sx in [-1.5, 1.5]:
		for sz in [-1.5, 1.5]:
			_solid(body, Vector3(sx, 1.5, sz), Vector3(0.3, 2.8, 0.3))
	for k in [1, 2, 3]:
		var a = k * PI * 0.5
		_solid(body, Vector3(cos(a) * 1.5, 1.6, sin(a) * 1.5), Vector3(0.12, 2.4, 3.0), -a)
	_solid(body, Vector3(0, 0.25, 0), Vector3(3.0, 0.5, 3.0))
	item = {"pos": pos + Vector3(2.3, 0, 0), "radius": 2.4, "kind": "rogue_hut", "label": "[F] Barakanda dinlen (can/chakra, kayıt)"}
	Interact.add(item)


static func _build_burnt(pos: Vector3) -> void:
	var W = MissionWork.I()
	var b = MB.new()
	var char_c = Color(0.1, 0.09, 0.08)
	for sx in [-1.5, 1.5]:
		for sz in [-1.5, 1.5]:
			b.add("box", Vector3(sx, 0.1, sz), Vector3(0.5, 0.22, 0.5), Color(0.3, 0.29, 0.28))
	# kömürleşmiş direkler: ikisi ayakta (biri yarım), ikisi devrik
	b.add("cyl", Vector3(-1.5, 1.4, -1.5), Vector3(0.24, 2.6, 0.24), char_c, Vector3(0, 0, 4), 7)
	b.add("cyl", Vector3(1.5, 0.8, -1.5), Vector3(0.24, 1.4, 0.24), char_c.lightened(0.04), Vector3(6, 0, -5), 7)
	b.add("cyl", Vector3(-0.6, 0.45, 1.2), Vector3(0.24, 2.6, 0.24), char_c, Vector3(84, 35, 0), 7)
	b.add("cyl", Vector3(0.9, 0.38, 0.4), Vector3(0.22, 2.4, 0.22), char_c.lightened(0.03), Vector3(88, -50, 0), 7)
	for k in 7:
		b.add("box", Vector3(-1.1 + k * 0.36, 0.3 + (k % 3) * 0.07, -0.6 + (k % 4) * 0.42), Vector3(0.5, 0.05, 1.5 - (k % 3) * 0.3), char_c.lightened((k % 3) * 0.03), Vector3(k * 7.0 - 20.0, k * 37.0, (k % 2) * 14.0))
	b.add("cyl", Vector3(0, 0.26, 0), Vector3(3.4, 0.06, 3.4), Color(0.2, 0.19, 0.18), Vector3.ZERO, 12)   # kül
	for k in 9:
		var a = TAU * k / 9.0
		b.add("sphere", Vector3(cos(a) * (0.5 + (k % 3) * 0.4), 0.33, sin(a) * (0.5 + (k % 2) * 0.5)), Vector3(0.5, 0.16, 0.44), Color(0.28, 0.27, 0.26).darkened((k % 3) * 0.1), Vector3.ZERO, 6)
	W._part(node, b)
	var body = StaticBody3D.new()
	node.add_child(body)
	_solid(body, Vector3(0, 0.2, 0), Vector3(3.2, 0.4, 3.2))
	_solid(body, Vector3(-1.5, 1.4, -1.5), Vector3(0.3, 2.6, 0.3))
	# hâlâ tüten enkaz
	var em = FX.burst(pos + Vector3(0.2, 0.5, 0.0), {"parent": node, "amount": 10, "life": 2.6, "tex": FX.tex_soft, "size": 0.9, "radius": 0.5,
		"vmin": 0.4, "vmax": 0.9, "dir": Vector3.UP, "spread": 12.0, "gravity": Vector3(0.15, 0.5, 0),
		"colors": [Color(0.3, 0.3, 0.3, 0.0), Color(0.32, 0.31, 0.3, 0.35), Color(0.4, 0.4, 0.4, 0.0)]})
	if em:
		em.one_shot = false
		em.emitting = true
	item = {"pos": pos + Vector3(2.3, 0, 0), "radius": 2.6, "kind": "rogue_hut", "label": "[F] Yanık barakan"}
	Interact.add(item)


## [F]: dinlen / yanıksa durum
static func use() -> void:
	if state() == "burnt":
		Hud.msg("Baraka yakılmış. Yeniden kurmak için dülgerin işi sığınaktaki panoda.", Color(1, 0.7, 0.5), 5.0)
		return
	if Game.player:
		Game.player.hp = Game.player.max_hp
		Game.player.chakra = Game.player.max_chakra
	Game.save_game()
	var l = loot()
	Hud.msg("Barakanda dinlendin. (Oyun kaydedildi)  •  İçerideki mal: %d sandık, %d çuval" % [int(l.get("chest", 0)), int(l.get("sack", 0))], Color(0.8, 0.9, 1), 5.0)
