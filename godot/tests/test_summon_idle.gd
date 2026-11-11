extends Node
## Çağrıların durma duruşu: düşman yokken çağrılır, 3 sn sonra iki açıdan çekilir. SI="şahin:2,köpek:1" (sözleşme:kademe)
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
	main.world.env.time_of_day = 0.5
	for it in OS.get_environment("SI").split(","):
		var id = it.split(":")[0]
		var tier = int(it.split(":")[1])
		var s = Summon.new()
		s.contract = id
		s.tier = tier
		s.def = Contracts.DEFS[id]["tiers"][tier]
		s.owner_f = pl
		s.team = pl.team
		main.add_child(s)
		var f = pl.face_dir()
		s.global_position = pl.global_position + f * 6.0
		var sz = maxf(2.0, float(s.def["h"]))
		await get_tree().create_timer(3.0).timeout
		for k in 2:
			var cam = Camera3D.new()
			main.add_child(cam)
			var side = f.cross(Vector3.UP) * (1.0 if k == 0 else -0.2)
			var c = s.global_position + Vector3.UP * sz * 0.6
			cam.global_position = c + (side - f * (0.6 if k == 0 else -1.0)).normalized() * (3.0 + sz * 1.8) + Vector3.UP * sz * 0.3
			cam.look_at(c)
			cam.current = true
			await get_tree().create_timer(0.25).timeout
			await main.shot("idle_%s_%d" % [s.def["model"], k])
			cam.queue_free()
		s.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
