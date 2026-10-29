extends Node
## Toplu kontrol: Byakugan damarları, Akatsuki Bingo + davet, kaçak görevleri derleniyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hyuga", "element": "katon", "hair_style": "uzun", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.85, 0.82, 0.78), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.9, 0.9, 0.95)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	print("B6 visited=%s" % [Game.profile["visited"]])
	var aka = Missions.bingo_entries().filter(func(x): return x.get("org", false))
	print("B6 akatsuki_in_bingo=%d" % aka.size())
	Hud.show_game_hud(false)
	pl.model.set_dojutsu_eyes(2, 1, 2, 1, true)
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 18
	cam.current = true
	var hb = pl.model.skel.find_bone("Head")
	var head = pl.model.skel.global_transform * pl.model.skel.get_bone_global_pose(hb).origin + Vector3.UP * 0.07
	var fw = pl.face_dir()
	cam.global_position = head + fw * 0.9
	cam.look_at(head)
	await get_tree().create_timer(0.4).timeout
	await main.shot("byakugan_veins")
	Game.profile["level"] = 40
	Game.profile["rank"] = 3
	Orgs.defect()
	Orgs.add_infamy(2100)
	Orgs.flags()["akatsuki_member"] = true
	var j = Orgs._akatsuki_job()
	print("B6 aka_job=%s rank=%s" % [j["title"], Orgs.rogue_rank_name()])
	get_tree().quit()
