extends Node
## Kaçak sığınağı tezgâhları + av-ninjası sıklığı
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pr = Game.profile
	pr["level"] = 20
	pr["rank"] = 1
	pr["ryo"] = 99999
	Orgs.defect()
	Hud.close_dialog()
	var hp = Orgs.hideout_pos()
	main.player.respawn(hp + Vector3(0, 0.5, 8))
	await get_tree().create_timer(4.0).timeout
	var kinds = []
	for it in Interact.items:
		if String(it.get("kind", "")).begins_with("rogue_"):
			kinds.append(it["kind"])
	print("ROGUE stalls: %s" % [kinds])
	for k in ["rogue_tailor", "rogue_weapons", "rogue_scrolls", "rogue_summoner"]:
		Orgs.rogue_shop(k)
		await get_tree().create_timer(0.4).timeout
		Hud.close_dialog()
	print("ROGUE hunter_next=%.0f" % Orgs._hunter_next)
	# kamera: sığınak
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	cam.global_position = hp + Vector3(0, 9, 22)
	cam.look_at(hp + Vector3(0, 1, 0))
	await get_tree().create_timer(1.0).timeout
	await main.shot("rogue_camp")
	get_tree().quit()
