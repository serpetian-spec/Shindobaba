extends Node
## Köy yelekleri (Konoha, Suna, Kiri, Kumo, Iwa) önden
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
	pl.visible = false
	pl.set_process(false)
	Hud.show_game_hud(false)
	var i = 0
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var L = CharacterModel.default_look()
		L.merge(Outfits.roll("chunin", vid), true)
		L["face_style"] = null
		L["head_style"] = null
		L["outer_style"] = null
		L["back_item"] = null
		L["guards"] = null
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(L)
		var p = pl.global_position + Vector3(-3.2 + i * 1.6, 0, -6)
		p.y = Game.ground_height(p.x, p.z)
		m.global_position = p
		m.rotation.y = PI
		m.play("idle", 0.0)
		i += 1
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 34
	cam.global_position = pl.global_position + Vector3(0, 1.4, 1.2)
	cam.look_at(pl.global_position + Vector3(0, 1.15, -6))
	cam.current = true
	await get_tree().create_timer(1.0).timeout
	await main.shot("vests")
	get_tree().quit()
