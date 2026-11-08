extends Node
## Su köpekbalığı modeli: yandan / önden / üstten / 3-4 açı (SharkArt.shark), sabit kamera, düz zemin
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	var pl = main.player
	var base = pl.global_position + Vector3(0, 2.0, -6.0)
	var sk = SharkArt.shark(1.6)
	get_tree().current_scene.add_child(sk)
	sk.global_position = base
	sk.rotation.y = 0.0
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.current = true
	cc.fov = 40.0
	var views = {"yan": Vector3(5.5, 0.3, 0), "on": Vector3(0, 0.4, -5.5), "ust": Vector3(0.01, 6.0, 0), "ucdort": Vector3(3.8, 1.6, -3.8)}
	for k in views:
		cc.global_position = base + views[k]
		cc.look_at(base, Vector3.UP if k != "ust" else Vector3.FORWARD)
		await _w(0.3)
		await main.shot("shark_%s" % k)
	get_tree().quit()
