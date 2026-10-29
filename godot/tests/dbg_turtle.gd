extends Node
## Dev kaplumbağa yandan: boyun boyu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	pl.visible = false
	var s = Summon.new()
	s.contract = "kaplumbağa"; s.tier = 0; s.def = Contracts.DEFS["kaplumbağa"]["tiers"][0]
	s.owner_f = null; s.team = "neutral"
	get_tree().current_scene.add_child(s)
	var p = pl.global_position + Vector3(0, 0, -8)
	s.global_position = p
	s.set_physics_process(false)
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	await get_tree().create_timer(1.0).timeout
	cam.global_position = p + Vector3(3.2, 1.0, -0.6)
	cam.look_at(p + Vector3(0, 0.45, -0.3))
	await get_tree().create_timer(0.3).timeout
	await main.shot("turtle_side")
	get_tree().quit()
