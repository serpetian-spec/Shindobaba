extends Node
## Sharingan açılış sinematiği: göze dalan kamera karelerini çek
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.05, 0.05, 0.08), "top": Color(0.1, 0.12, 0.22), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.45, 0.95)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.show_game_hud(false)
	var pl = main.player
	pl.combat.modes.eyes.toggle()
	print("EYE active=%s" % pl.combat.modes.eyes.active)
	for t in [0.15, 0.4, 0.68, 0.85]:
		await get_tree().create_timer(0.0001 if t == 0.15 else 0.0).timeout
		await get_tree().create_timer(t - (0.0 if t == 0.15 else 0.0) - 0.0).timeout if t == 0.15 else await get_tree().create_timer(0.25 if t < 0.7 else 0.17).timeout
		await main.shot("eyecu_%d" % int(t * 100))
	await get_tree().create_timer(0.8).timeout
	await main.shot("eyecu_after")
	print("EYE cam_restored=%s" % (get_viewport().get_camera_3d() == pl.cam))
	get_tree().quit()
