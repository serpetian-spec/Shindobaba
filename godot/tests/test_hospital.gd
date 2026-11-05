extends Node
## Konoha çatı su depoları yoğunluğu: köyün üstünden iki geniş kare

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "senju", "element": "doton", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	await _wait(3.0)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.far = 3000.0
	var hd = Progress._hospital_pos()
	print("HOSPDOOR ", hd)
	Game.player.respawn(hd)
	await _wait(3.0)
	cc.global_position = hd + Vector3(0, 140, 0.01)
	cc.look_at(hd)
	cc.current = true
	Hud.close_dialog()
	await _wait(0.5)
	await main.shot("hosp_top")
	cc.global_position = hd + Vector3(-60, 35, -60)
	cc.look_at(hd + Vector3(0, 5, 0))
	await _wait(0.3)
	await main.shot("hosp_side")
	get_tree().quit()
