extends Node
## Birlikte etkinlik (ramen) + görev yerlerinin metne uyması
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 2
	Game.profile["level"] = 20
	Game.profile["ryo"] = 5000
	# görev yerleri
	for t in [["Pirinç Hasadı", "Köylülerin pirinç tarlasında hasada yardım et.", "pirinç demeti"], ["Balık Ağları", "Fırtına balıkçı ağlarını kıyıya savurdu.", "balık ağı"],
			["Şifalı Otlar", "Ormandan şifalı ot getir.", "şifalı ot"], ["Tapınak Bahçesi", "Tapınak için taş lazım", "taş"]]:
		var k = Missions._place_kind("%s %s %s" % t)
		var at = Missions._place(k, "konoha")
		var poi = ""
		if at != null:
			for p in Game.pois:
				if Vector2(float(p["x"]), float(p["y"])).distance_to(Vector2(at[0], at[1])) < 30:
					poi = String(p["t"]) + " " + String(p.get("name", ""))
		print("PLACE ", t[0], " -> ", k, " ", at, " poi=", poi)
	for kind in ["hamlet", "dock", "shrine"]:
		var at2 = Missions._spot("konoha", 200, 400) if kind != "dock" else Missions._place("dock", "konoha")
		var c2 = Missions._w(at2)
		var node = Missions._build_site(kind, c2)
		var cam = get_viewport().get_camera_3d()
		var cf = -cam.global_transform.basis.z
		cf.y = 0
		var pp = c2 - cf.normalized() * 22.0
		pp.y = Game.ground_height(pp.x, pp.z) + 0.3
		pl.global_position = pp
		await get_tree().create_timer(3.0).timeout
		await main.shot("site_" + kind)
		node.queue_free()
	# dost + ramen
	var v = ClanResident.new()
	v.clan = "nara"
	v.vid = "konoha"
	v.given = "Nara Emi"
	v.display_override = v.given
	v.role = "nurse"
	v.look_extra = ClanWorld.clan_look("nara", "chunin", "konoha", true, "adult")
	main.actors.add_child(v)
	var ramen = {}
	for it in Interact.items:
		if it["kind"] == "ramen":
			ramen = it
	print("ACT ramen at ", ramen.get("pos"))
	pl.global_position = ramen["pos"] + Vector3(0, 0.5, 30)
	v.global_position = pl.global_position + Vector3(2, 0, 0)
	await get_tree().create_timer(1.0).timeout
	Friends._meet(v)
	Menus.clear()
	var id = String(v.get_meta("friend_id"))
	Friends.all()[id]["bond"] = 40
	Friends.begin_activity(id, "meal")
	var ff = Friends.inst()
	print("ACT started ", ff.act.get("kind"), " dest=", ff.act.get("dest", {}).get("name"))
	await get_tree().create_timer(2.0).timeout
	await main.shot("act_walk")
	# oyuncuyu yürüt (ışınla) tezgâha
	pl.global_position = ramen["pos"] + Vector3(0, 0.3, 3)
	await get_tree().create_timer(1.5).timeout
	print("ACT stage ", ff.act.get("stage"))
	await get_tree().create_timer(4.0).timeout
	await main.shot("act_eat")
	await get_tree().create_timer(9.0).timeout
	print("ACT done ", ff.act.is_empty(), " bond=", Friends.all()[id]["bond"], " ryo=", Game.profile["ryo"], " log=", Friends.all()[id]["log"])
	# antrenman
	Friends.begin_activity(id, "train")
	await get_tree().create_timer(1.0).timeout
	pl.global_position = ff.act["dest"]["pos"] + Vector3(0, 0.5, 2)
	await get_tree().create_timer(5.0).timeout
	print("ACT spar stage ", ff.act.get("stage"))
	await main.shot("act_spar")
	if ff.act.has("e") and is_instance_valid(ff.act["e"]):
		ff.act["e"].hp = ff.act["e"].max_hp * 0.2
	await get_tree().create_timer(6.0).timeout
	print("ACT spar done ", ff.act.is_empty(), " log=", Friends.all()[id]["log"].slice(-1))
	get_tree().quit()
