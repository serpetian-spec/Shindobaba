extends Node
## Güce takmış kişiler: dünya turlarında gelişim (kayıt dökümü) + dövüşte kullandıkları (tam gövde Susanoo, canavar çağırma,
## jinchūriki dönüşümü + Susanoo zırhı). TURNS = dünya turu sayısı, FIGHT=0 dövüş sahnelerini atlar.
var main: Node
var cam: Camera3D


func _camw(p: Vector3, t: Vector3) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 55.0
		cam.far = 6000.0
	cam.global_position = p
	cam.look_at(t)
	cam.current = true


func _dump(tag: String) -> void:
	var ps = WorldAmbition.people()
	ps.sort_custom(func(a, b): return int(a["level"]) > int(b["level"]))
	print("AMB %s: %d kisi" % [tag, ps.size()])
	var ec = {}
	for q in WorldPeople.all().values():
		if WorldPeople.alive(q):
			var kk = "%d/%d" % [int(q["eye"][0]), int(q["eye"][1])]
			ec[kk] = int(ec.get(kk, 0)) + 1
	print("AMB   dunyadaki gozler (tur/seviye: kisi): %s" % str(ec))
	for p in ps:
		print("AMB   %s | %s %s | Guc %d | goz %s | muhurlu=%s emrinde=%s | istek=%s" % [String(p["name"]), String(p["village"]), ("kacak" if WorldPeople.is_rogue(p) else "koy"),
			int(p["level"]), str(p["eye"]), WorldAmbition.beast_of(p), str(WorldAmbition.ctrl_of(p)), String(p["amb"].get("want", ""))])
		var lg: Array = p.get("log", [])
		for l in lg.slice(maxi(0, lg.size() - 3)):
			print("AMB       - %s" % str(l))


func _fight(tag: String, p: Dictionary, wait: float) -> void:
	var pl = main.player
	var e: Enemy = WorldAmbition.come(p)
	await get_tree().create_timer(1.5).timeout
	print("AMB dovus %s: %s Guc %d goz %s can %.0f kademe=%s emrinde=%s canavar=%s" % [tag, e.display_name, int(p["level"]), str(p["eye"]), e.max_hp, str(e.get_meta("sus_tier", 0)), str(e.get_meta("amb_ctrl", [])), String(e.arch.get("beast", ""))])
	e.hp = e.max_hp * 0.55
	var t := 0.0
	var shot := 0
	while t < wait:
		await get_tree().create_timer(2.0).timeout
		t += 2.0
		if not is_instance_valid(e):
			break
		var form = e.get_meta("jin_form") if e.has_meta("jin_form") else null
		var tgt: Node3D = form if form != null and is_instance_valid(form) else e
		var sn = e.get_meta("ea_susanoo") if e.has_meta("ea_susanoo") else null
		var h = 3.0
		if sn != null and is_instance_valid(sn):
			h = Susanoo.TIER_HEIGHT[sn.tier]
		if tgt is TailedBeast:
			h = tgt.height
		var beasts = get_tree().get_nodes_in_group("fighters").filter(func(n): return n is TailedBeast and not n.dead)
		print("AMB   t=%.0f susanoo=%s (kademe %s) donusum=%s zirh=%s sahadaki canavar=%d" % [t, sn != null and is_instance_valid(sn), (str(sn.tier) if sn != null and is_instance_valid(sn) else "-"),
			form != null and is_instance_valid(form), (form.rig.get_node_or_null("BeastSus") != null if form != null and is_instance_valid(form) else false), beasts.size()])
		if int(t) % 6 == 0 and shot < 3:
			shot += 1
			var c = tgt.global_position + Vector3.UP * h * 0.5
			_camw(c + Vector3(h * 1.6 + 8.0, h * 0.3 + 3.0, h * 1.6 + 8.0), c)
			await get_tree().create_timer(0.2).timeout
			await main.shot("amb_%s_%d" % [tag, shot])
			pl.cam.make_current()
	for n in get_tree().get_nodes_in_group("fighters"):
		if n is TailedBeast or n == e:
			n.queue_free()
	if is_instance_valid(e):
		e.queue_free()
	await get_tree().create_timer(1.0).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12),
		"bottom": Color(0.9, 0.45, 0.12), "skin": Color(1.0, 0.86, 0.72), "eye": Color(0.2, 0.4, 0.9)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.5
	Game.profile["kd_wait"] = 99999.0
	WorldDay.auto = false
	WorldAmbition.ensure()
	_dump("baslangic")
	var turns = int(OS.get_environment("TURNS")) if OS.get_environment("TURNS") != "" else 80
	for i in turns:
		WorldAmbition.world_tick()
	_dump("%d tur sonra" % turns)
	var bs = TailedBeasts.beasts()
	for id in bs:
		var b: Dictionary = bs[id]
		print("AMB canavar %s: %s %s emrinde=%s" % [id, String(b.get("state", "")), String((b.get("host", {}) as Dictionary).get("name", "")), String(b.get("ctrl_by", ""))])
	if OS.get_environment("FIGHT") == "0":
		get_tree().quit()
		return
	# dövüş: açık araziye çık
	var at = pl.global_position + Vector3(0, 0, 900.0)
	at = Missions.open_ground(at, 60.0)
	at.y = Game.ground_height(at.x, at.z) + 0.3
	pl.global_position = at
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()
	Game.profile["god"] = true
	pl.set_meta("test_invuln", true)
	await get_tree().create_timer(2.0).timeout
	var ps = WorldAmbition.people()
	ps.sort_custom(func(a, b): return int(a["level"]) > int(b["level"]))
	# 1) emrinde canavar olan Ebedi Mangekyō (kayıtta yoksa en güçlü kişi o hâle getirilir: yalnız görüntü denemesi)
	var a1: Dictionary = ps[0]
	a1["eye"] = [5, 3]
	a1["level"] = maxi(int(a1["level"]), 200)
	if WorldAmbition.ctrl_of(a1).is_empty():
		for id in ["kokuo", "matatabi", "saiken", "chomei"]:
			if String(bs[id].get("state", "wild")) in ["wild", "free"] and String(bs[id].get("ctrl_by", "")) == "":
				bs[id]["ctrl_by"] = String(a1["id"])
				(a1["amb"]["ctrl"] as Array).append(id)
				break
	await _fight("cagiran", a1, 24.0)
	# 2) bedenine canavar mühürlü Mangekyō sahibi: dönüşüm + Susanoo zırhı
	var a2: Dictionary = ps[1]
	a2["eye"] = [5, 3]
	a2["level"] = maxi(int(a2["level"]), 180)
	if WorldAmbition.beast_of(a2) == "":
		for id in ["shukaku", "isobu", "son_goku", "gyuki"]:
			if String(bs[id].get("state", "wild")) in ["wild", "free"]:
				bs[id]["state"] = "host"
				bs[id]["host"] = {"name": String(a2["name"]), "village": String(a2["village"]), "rogue": true, "level": int(a2["level"]), "gender": "m", "wp": String(a2["id"])}
				a2["beast"] = id
				break
	await _fight("jin", a2, 30.0)
	get_tree().quit()
