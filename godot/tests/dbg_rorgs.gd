extends Node
## Rastgele örgütler: üretim, Bingo, üye çağırma; Akatsuki lideri tarzı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	for o in Orgs.random_orgs():
		print("RO %s goal=%s leader=%s style=%s" % [o["name"], o["goal"], o["members"][0]["name"], o["members"][0]["style"]])
	print("RO bingo=%d" % Orgs.ro_bingo_entries().size())
	var o = Orgs.random_orgs()[0]
	var e = Orgs.spawn_ro_member(o, o["members"][1], pl.global_position + Vector3(0, 0, -6))
	var lead = Orgs.spawn_member(Orgs.AKATSUKI[8], pl.global_position + Vector3(4, 0, -6))
	print("RO member=%s | akatsuki_leader=%s style=%s" % [e.display_name, lead.display_name, lead.arch.get("style")])
	Hud.show_game_hud(false)
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = pl.global_position + Vector3(2, 1.8, -1)
	cam.look_at(e.global_position + Vector3.UP)
	await get_tree().create_timer(1.0).timeout
	await main.shot("rorg")
	get_tree().quit()
