extends Node
## Konoha havadan + sokaktan: yol ağı, evlere bağlantı, düzen. KA=1 yalnız hava
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.45
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	var r = float(v["r"])
	print("KA r=", r, " c=", c)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.far = 6000.0
	var spots = [["air_c", Vector3(0, 420, 60), Vector3(0, 0, 0)], ["air_n", Vector3(0, 300, -r * 0.35 + 40), Vector3(0, 0, -r * 0.4)], ["air_s", Vector3(0, 300, r * 0.45 + 40), Vector3(0, 0, r * 0.4)],
		["air_e", Vector3(r * 0.45, 300, 40), Vector3(r * 0.45, 0, 0)], ["air_w", Vector3(-r * 0.45, 300, 40), Vector3(-r * 0.45, 0, 0)],
		["low_c", Vector3(30, 26, 90), Vector3(0, 2, 0)], ["low_e", Vector3(r * 0.35, 22, 70), Vector3(r * 0.35 + 20, 2, 0)], ["low_w", Vector3(-r * 0.35, 22, 70), Vector3(-r * 0.35 - 20, 2, 0)]]
	for s in spots:
		var at: Vector3 = c + s[1]
		var gy = Game.terrain_height(at.x, at.z)
		main.player.respawn(Vector3(at.x, gy + 2, at.z))
		await get_tree().create_timer(2.5).timeout
		cc.global_position = Vector3(at.x, gy + s[1].y, at.z)
		var tg: Vector3 = c + s[2]
		cc.look_at(Vector3(tg.x, Game.terrain_height(tg.x, tg.z) + s[2].y, tg.z))
		cc.current = true
		await get_tree().create_timer(0.5).timeout
		await main.shot("ka_" + s[0])
	get_tree().quit()
