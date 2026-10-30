extends Node
## Akademi döngüsü: mezuniyet, büyüyen çocuklar, öğretmenlik, jōnin hocalığı, görevde yaralanma/ölüm
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 3
	Game.profile["level"] = 30
	var now = Time.get_unix_time_from_system()
	Game.profile["children"] = [{"name": "Test Hana", "gender": "f", "clans": ["hyuga"], "born": now - 6000}]
	var fid = Friends._make_friend("Nara Shun", "nara", ClanWorld.clan_look("nara", "chunin", "konoha", false), 60, "Nara klanı")
	Friends.all()[fid]["family"] = [{"rel": "Oğlu", "name": "Nara Kei", "alive": true}]
	print("ACAD teacher opts=", Friends._teacher_opts().map(func(o): return o["label"]))
	Friends._teacher_opts()[0]["cb"].call()
	Menus.clear()
	print("ACAD teacher opts2=", Friends._teacher_opts().map(func(o): return o["label"]))
	Friends._teacher_opts()[0]["cb"].call()
	Menus.clear()
	print("ACAD lessons=", Game.profile.get("lessons"))
	var ff = Friends.inst()
	ff.graduation()
	print("ACAD grads=", Friends.grads().map(func(g): return [g["name"], g["parent"], g["student"]]))
	print("ACAD friends=", Friends.all().values().map(func(f): return [f["name"], f["title"]]))
	await get_tree().create_timer(0.5).timeout
	Menus.clear()
	var ac = Exams.find_point(["academy"])
	var cam = get_viewport().get_camera_3d()
	var cf = -cam.global_transform.basis.z
	cf.y = 0
	cf = cf.normalized()
	pl.global_position = ac - cf * 15.0 + Vector3.UP * 2.0
	await get_tree().create_timer(3.0).timeout
	print("ACAD spawned=", ff._grad_nodes.size())
	# kameraya mezunları göster
	await get_tree().create_timer(1.0).timeout
	await main.shot("acad_grads")
	var n = ff._grad_nodes.values()[0]
	var o = Friends.options_for(n)
	print("ACAD grad opts=", o.map(func(x): return x["label"]))
	o[0]["cb"].call()
	Menus.clear()
	print("ACAD met=", Friends.all()[String(n.get_meta("friend_id"))]["name"], " title=", Friends.all()[String(n.get_meta("friend_id"))]["title"])
	# Kage'den: öğretmenlik + genin takımı
	print("ACAD kage opts=", Friends._kage_teach_opts().map(func(o): return o["label"]))
	for o2 in Friends._kage_teach_opts():
		if String(o2["label"]).begins_with("Bir genin"):
			o2["cb"].call()
	Menus.clear()
	print("ACAD students=", Friends.all().values().filter(func(f): return f.get("student", false)).map(func(f): return f["name"]))
	print("ACAD party max=", Friends.party_max())
	# görev riski
	var ids = Friends.all().keys()
	var stats = {"ok": 0, "inj": 0, "dead": 0}
	for k in 60:
		var id = ids[k % ids.size()]
		var f: Dictionary = Friends.all()[id]
		f["status"] = ""
		f["away"] = 0.0
		f["party"] = true
		Friends.on_mission_done("S")
		if f["status"] == "öldü":
			stats["dead"] += 1
		elif float(f.get("away", 0.0)) > Time.get_unix_time_from_system():
			stats["inj"] += 1
		else:
			stats["ok"] += 1
		for j in Friends.all():
			Friends.all()[j]["party"] = false
		Menus.clear()
	print("ACAD S-rank risk over 60: ", stats)
	var f0: Dictionary = Friends.all()[ids[0]]
	f0["status"] = ""
	Friends.injure(ids[0], "test")
	Menus._friend_i = 0
	Menus.ninja_menu(main, "relations")
	await get_tree().create_timer(1.0).timeout
	await main.shot("acad_card")
	print("ACAD done")
	get_tree().quit()
