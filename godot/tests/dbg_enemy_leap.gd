extends Node
## Düşman ninja sıçrayışıyla kovalıyor mu (oyuncu uzaklaşınca)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	pl.max_hp = 99999.0
	pl.hp = 99999.0
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["jutsu"] = []
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + Vector3(8, 0, 0)
	e.home = e.global_position
	await get_tree().create_timer(1.5).timeout
	var leaps = 0
	for k in 3:
		pl.global_position += Vector3(-45, 0, 0)
		pl.global_position.y = Game.ground_height(pl.global_position.x, pl.global_position.z)
		var t = 0.0
		while t < 3.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			if e.state == "leap" and e.state_t < 0.05:
				leaps += 1
		print("LEAP round=%d dist=%.1f state=%s target=%s" % [k, e.global_position.distance_to(pl.global_position), e.state, e.target == pl])
	print("LEAP total_leaps=%d" % leaps)
	get_tree().quit()
