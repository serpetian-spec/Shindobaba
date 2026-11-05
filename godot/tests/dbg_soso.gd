extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "sabaku", "element": "fuuton", "hair_style": "diken", "hair": Color(0.7, 0.2, 0.15), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	Hud.show_game_hud(false)
	await get_tree().create_timer(1.5).timeout
	var a = Enemy.archetype("rogue", 1)
	a["respawn"] = false
	var e = Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 7.0
	e.max_hp = 1e6
	e.hp = 1e6
	await get_tree().create_timer(0.5).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	Jutsu.execute(pl, "sabaku_soso", e)
	for t in [0.3, 0.55, 0.8, 1.2]:
		await get_tree().create_timer(0.25 if t > 0.3 else 0.3).timeout
		print("SOSO t=%.2f coat=%s hp=%d" % [t, e.has_meta("sand_coat"), int(e.hp)])
		cc.global_position = e.global_position + pl.face_dir() * -4.0 + pl.face_dir().cross(Vector3.UP) * 2.5 + Vector3.UP * 1.6
		cc.look_at(e.global_position + Vector3.UP * 1.0)
		cc.current = true
		await main.shot("soso_%d" % int(t * 100))
	get_tree().quit()
