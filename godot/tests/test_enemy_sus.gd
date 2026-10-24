extends Node
## Düşman Susanoo çeşitliliği: dört düşman, her biri kendi renk/yapısında
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.set_process(false)
	var base = pl.global_position + Vector3(0, 0, -30)
	for i in 4:
		var a = Enemy.archetype("rogue", i)
		a["respawn"] = false
		a["name"] = ["Uchiha Raigen", "Uchiha Hisame", "Uchiha Kagerō", "Uchiha Tokiwa"][i]
		var e = Enemy.new()
		e.setup(a)
		main.add_child(e)
		var p = base + Vector3((i - 1.5) * 16.0, 0, 0)
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		e.set_process(false)
		e.set_physics_process(false)
		EnemyArts._susanoo(e)
	await get_tree().create_timer(1.5).timeout
	pl.cam.global_position = base + Vector3(0, 12, 42)
	pl.cam.look_at(base + Vector3(0, 8, 0))
	await main.shot("enemy_sus_variety")
	get_tree().quit()
