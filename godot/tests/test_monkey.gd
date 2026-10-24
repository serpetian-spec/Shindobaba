extends Node
## Maymun Kral: önce görünür ve konuşur, sonra elmas asaya dönüşür; süre bitince eski silah geri gelir (kare kare çekim)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	Game.profile["level"] = 30
	Game.profile["rank"] = 2
	Contracts.sign("maymun")
	Game.profile["contracts"]["maymun"]["mastery"] = 999.0
	Game.profile["summon"] = "maymun"
	pl.chakra = 9999.0
	var f = pl.face_dir()
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.global_position = pl.global_position + f * 6.0 + f.cross(Vector3.UP) * 2.5 + Vector3.UP * 2.2
	cam.look_at(pl.global_position + f * 2.5 + Vector3.UP * 1.0)
	cam.current = true
	Contracts.summon(pl, {"id": "kuchiyose", "cost": 0})
	var sm = null
	await get_tree().create_timer(1.2).timeout
	for s in get_tree().get_nodes_in_group("summons"):
		sm = s
	print("MONKEY visible=%s tier=%s model=%s" % [sm.visible if sm else null, sm.tier if sm else null, sm.def.get("model", "") if sm else ""])
	await main.shot("monkey_appear")
	await get_tree().create_timer(1.6).timeout
	print("MONKEY after: visible=%s weapon=%s" % [sm.visible if is_instance_valid(sm) else "-", pl.model.look.get("weapon_r", "")])
	cam.global_position = pl.global_position + f * 3.0 + f.cross(Vector3.UP) * 1.5 + Vector3.UP * 1.6
	cam.look_at(pl.global_position + Vector3.UP * 1.1)
	await get_tree().create_timer(0.3).timeout
	await main.shot("monkey_staff")
	get_tree().quit()
