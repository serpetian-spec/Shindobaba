extends Node
## Kalıcı siviller: kayda geçme, yakın bağı, yeniden aynı kişi olarak gelme, sözler, yaşlanma. WV=köy
var main: Node
var cam: Camera3D


func _folk() -> Array:
	return get_tree().get_nodes_in_group("talkers").filter(func(n): return is_instance_valid(n) and n.has_meta("folk") and not n.is_queued_for_deletion())


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("WV") if OS.get_environment("WV") != "" else "konoha"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var t0 = Time.get_ticks_msec()
	await get_tree().create_timer(22.0).timeout
	var ns = _folk()
	var reg: Dictionary = WorldFolk.of(vid)
	var kin = reg.values().filter(func(f): return String(f.get("kin", "")) != "")
	var cats = {}
	for f in reg.values():
		cats[WorldFolk._cat_of(f)] = int(cats.get(WorldFolk._cat_of(f), 0)) + 1
	var allv = get_tree().get_nodes_in_group("talkers").filter(func(n): return n is Villager)
	print("WF ", vid, " street=", allv.size(), " folk_nodes=", ns.size(), " ninja_nodes=", allv.filter(func(n): return n.has_meta("world_person")).size(), " registry=", reg.size(), " kin=", kin.size(), " cats=", cats, " fps=", Engine.get_frames_per_second())
	for f in kin.slice(0, 5):
		var p = WorldPeople.get_p(String(f["kin"]))
		print("WF   ", f["name"], " ", int(Aging.years(f)), "y ", "F" if f["f"] else "M", " rel=", f["rel"], " -> ", p["name"], " ", int(Aging.person_years(p)), "y | ", WorldFolk.line(f, null, "(sıradan söz)"))
	# konuşma: tanışma sayısı + ad etiketi
	var kn = ns.filter(func(n): return String(WorldFolk.of_node(n).get("kin", "")) != "")
	var pick: Node = kn[0] if not kn.is_empty() else (ns[0] if not ns.is_empty() else null)
	if pick != null:
		var f = WorldFolk.of_node(pick)
		pl.global_position = pick.global_position + Vector3(0, 0.3, 2.0)
		await get_tree().create_timer(0.4).timeout
		for i in 3:
			print("WF   talk", i, " [", pick.display, "] ", WorldFolk.line(f, pick, "(sıradan söz)"))
			WorldFolk.talked(f, pick)
		pick.talk()
		await get_tree().create_timer(0.6).timeout
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 45.0
		cam.global_position = pick.global_position + Vector3(1.2, 1.7, 3.2)
		cam.look_at(pick.global_position + Vector3(0, 1.3, 0))
		cam.current = true
		await get_tree().create_timer(0.3).timeout
		await main.shot("wf_talk")
		Hud.close_dialog() if Hud.has_method("close_dialog") else null
		# yakını ölürse / oyuncu öldürürse
		var p = WorldPeople.get_p(String(f.get("kin", "")))
		if not p.is_empty():
			p["hurt_t"] = Aging.clock() + 500.0
			print("WF   hurt: ", WorldFolk.line(f, pick, "-"))
			p.erase("hurt_t")
			p["slain_by_player"] = true
			WorldPeople._die(p, "test")
			print("WF   slain: ", WorldFolk.line(f, pick, "-"), " regard=", WorldFolk.regard(f).get("act", ""))
	# yeniden doğuş: herkesi sil, aynı kişiler geri gelsin
	var before = reg.size()
	var names0 = ns.map(func(n): return n.display)
	var vl = WorldDay.vl
	for n in vl.npcs.duplicate():
		if is_instance_valid(n):
			n.queue_free()
	vl.npcs.clear()
	await get_tree().create_timer(16.0).timeout
	var ns2 = _folk()
	var again = ns2.filter(func(n): return n.display in names0).size()
	var ids = {}
	var dup = 0
	for n in ns2:
		if ids.has(n.get_meta("folk")):
			dup += 1
		ids[n.get_meta("folk")] = true
	print("WF respawn folk_nodes=", ns2.size(), " same_people=", again, " registry ", before, "->", WorldFolk.of(vid).size(), " duplicates=", dup)
	# yaşlanma: 30 yıl ileri
	var kid = WorldFolk.of(vid).values().filter(func(f): return WorldFolk._cat_of(f) == "child")
	if not kid.is_empty():
		var k = kid[0]
		var y0 = Aging.years(k)
		Game.profile["clock"] = Aging.clock() + Aging.YEAR * 30.0
		var d = WorldFolk.dress(k)
		print("WF age ", k["name"], " ", int(y0), "y -> ", int(Aging.years(k)), "y stage=", d["look_extra"]["age"], " cat=", WorldFolk._cat_of(k))
		Game.profile["clock"] = Aging.clock() + Aging.YEAR * 60.0
		var n0 = WorldFolk.of(vid).size()
		WorldFolk._stage.clear()
		WorldFolk.cast(vid, "walker")
		print("WF old age deaths: registry ", n0, " -> ", WorldFolk.of(vid).size())
	print("WF done ", Time.get_ticks_msec() - t0)
	get_tree().quit()
