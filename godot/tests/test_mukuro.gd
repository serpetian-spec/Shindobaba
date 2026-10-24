extends Node
## Kuklacı Mukuro görevi: boss köy dışında açık zeminde doğuyor mu, yerde mi, çekim
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	var m = {"title": "Kuklacı Mukuro", "giver": "Kazekage", "brief": "test", "rank": "S", "village": "suna", "type": "quest",
		"steps": [{"kind": "boss", "boss": "puppeteer", "near": "suna", "text": "Rüzgar Ülkesi'ne git ve kuklacıyı yen."}]}
	Missions.accept(m)
	await get_tree().create_timer(1.0).timeout
	var boss = null
	for n in Missions.step_nodes:
		if n is Boss:
			boss = n
	if boss == null:
		print("MUKURO boss yok")
		get_tree().quit()
		return
	var bp = boss.global_position
	var v = Game.village("suna")
	print("MUKURO at=%s map_d=%.0f r=%.0f ground=%.1f" % [bp, Game.to_map(bp).distance_to(Vector2(v["x"], v["y"])), float(v["r"]), bp.y - Game.ground_height(bp.x, bp.z)])
	pl.respawn(bp + Vector3(0, 0, 25))
	await get_tree().create_timer(4.0).timeout
	print("MUKURO after near: aggro=%s hp=%d pos=%s" % [boss.get("aggro"), int(boss.hp), boss.global_position])
	pl.set_process(false)
	pl.cam.global_position = pl.global_position + Vector3(0, 6, 10)
	pl.cam.look_at(boss.global_position + Vector3.UP * 1.5)
	await get_tree().create_timer(0.2).timeout
	await main.shot("mukuro")
	get_tree().quit()
