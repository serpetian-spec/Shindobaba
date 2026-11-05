extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "aburame", "element": "doton", "hair_style": "diken", "hair": Color(0.15, 0.12, 0.1), "top": Color(0.35, 0.45, 0.38), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	Hud.show_game_hud(false)
	await get_tree().create_timer(1.5).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var f = pl.face_dir()
	Jutsu.execute(pl, "hijutsu_mushimayu", null)
	var ts = [0.6, 1.4, 3.0]
	var acc = 0.0
	for t in ts:
		await get_tree().create_timer(t - acc).timeout
		acc = t
		cc.global_position = pl.global_position + f * 2.4 + f.cross(Vector3.UP) * 0.8 + Vector3.UP * 1.0
		cc.look_at(pl.global_position + Vector3.UP * 0.8)
		cc.current = true
		await main.shot("mm_%d" % int(t * 10))
	get_tree().quit()
