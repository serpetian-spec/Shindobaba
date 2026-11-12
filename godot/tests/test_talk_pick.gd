extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(2.5).timeout
	Hud.close_dialog()
	var pl = main.player
	var out = pl.global_position + Vector3(600, 0, -2400)
	out.y = Game.terrain_height(out.x, out.z) + 0.5
	pl.respawn(out)
	await get_tree().create_timer(1.0).timeout
	var mk = func(off: Vector3, nm: String) -> Node:
		var v = Villager.new()
		v.role = "walker"
		v.stay = true
		v.display_override = nm
		get_tree().current_scene.add_child(v)
		v.global_position = pl.global_position + off
		return v
	var a = mk.call(Vector3(0, 0, -3.0), "ON")
	var b = mk.call(Vector3(0, 0, 1.0), "ARKA")
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	for dirs in [[Vector3(0, 0, -1), "öne bak"], [Vector3(0, 0, 1), "arkaya bak"], [Vector3(1, 0, 0), "yana bak"]]:
		cam.global_position = pl.global_position - dirs[0] * 4.0 + Vector3(0, 2, 0)
		cam.look_at(pl.global_position + dirs[0] * 4.0 + Vector3(0, 1, 0))
		cam.current = true
		await get_tree().process_frame
		var t = Hud._near_talker(pl)
		print("TP ", dirs[1], " -> ", t.display if t else "-")
	get_tree().quit()
