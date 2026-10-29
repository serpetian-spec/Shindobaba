extends Node
## Kurbağalar (3 kademe) + karga + semender yandan
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
	var specs = [["kurbağa", 0, 0.0], ["kurbağa", 1, 4.0], ["kurbağa", 2, 18.0], ["semender", 2, 40.0]]
	for sp in specs:
		var s = Summon.new()
		s.contract = sp[0]; s.tier = sp[1]; s.def = Contracts.DEFS[sp[0]]["tiers"][sp[1]]
		s.owner_f = null; s.team = "neutral"
		get_tree().current_scene.add_child(s)
		s.global_position = pl.global_position + Vector3(sp[2], 0, -30)
		s.set_physics_process(false)
		s.facing = PI * 0.5
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = pl.global_position + Vector3(22, 10, 25)
	cam.look_at(pl.global_position + Vector3(22, 4, -30))
	await get_tree().create_timer(1.5).timeout
	await main.shot("summons")
	get_tree().quit()
