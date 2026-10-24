extends Node
## Yüz maskeleri yakın çekim (önden ve yandan)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.show_game_hud(false)
	var styles = ["anbu_tilki", "kitsune"]
	for i in styles.size():
		var lk = Game.profile["look"].duplicate()
		lk["face_style"] = styles[i]
		var m = CharacterModel.new()
		get_tree().current_scene.add_child(m)
		m.setup(lk)
		m.global_position = main.player.global_position + Vector3(i * 6.0, 0, -4)
		m.rotation.y = PI
	main.player.visible = false
	await get_tree().create_timer(0.5).timeout
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.fov = 30
	for i in styles.size():
		var c = main.player.global_position + Vector3(i * 6.0, 1.5, -4)
		for v in [["on", Vector3(0, 0.05, 1.3)], ["yan", Vector3(1.2, 0.05, 0.4)]]:
			cam.global_position = c + v[1]
			cam.look_at(c)
			cam.current = true
			await get_tree().create_timer(0.3).timeout
			await main.shot("m_%s_%s" % [styles[i], v[0]])
	get_tree().quit()
