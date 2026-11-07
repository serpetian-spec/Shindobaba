extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "gekko", "element": "fuuton", "hair_style": "uzun", "hair": Color(0.45, 0.3, 0.55), "top": Color(0.3, 0.35, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	Hud.show_game_hud(false)
	await get_tree().create_timer(2.0).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var f = pl.face_dir()
	Jutsu.execute(pl, "oborozukiyo", null)
	for t in [0.25, 0.4, 0.55]:
		await get_tree().create_timer(0.15 if t > 0.25 else 0.25).timeout
		cc.global_position = pl.global_position + f * 7.0 + Vector3.UP * 1.0
		cc.look_at(pl.global_position + Vector3.UP * 1.0)
		cc.current = true
		await main.shot("oboro_%d" % int(t * 100))
	get_tree().quit()
