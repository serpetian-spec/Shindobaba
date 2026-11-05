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
	var n = 0
	for o in [Vector3(120, 0, 80), Vector3(-140, 0, -60), Vector3(60, 0, -150)]:
		var p = c + o
		p.y = Game.ground_height(p.x, p.z)
		Game.player.respawn(p)
		await _wait(2.5)
		cc.global_position = p + Vector3(40, 45, 40)
		cc.look_at(p + Vector3(-30, 0, -30))
		cc.current = true
		Hud.close_dialog()
		await _wait(0.5)
		await main.shot("roof_%d" % n)
		n += 1
	get_tree().quit()
