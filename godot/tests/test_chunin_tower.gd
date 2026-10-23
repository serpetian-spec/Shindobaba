extends Node
## Konoha Ölüm Ormanı kulesine varınca ön elemelere geçiş (kule 40 m yarıçaplı; eskiden merkeze 30 m şartı yüzünden girilemiyordu)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Game.profile["level"] = 16
	ChuninExam.host = "konoha"
	ChuninExam.st = {"written": 5, "forest_days": 0.0, "prelim_wins": 0, "final_wins": 0, "jutsu": {}, "kawarimi": 0, "hp_lost": 0.0, "invasion": false, "mates_alive": 2}
	ChuninExam._forest()
	await get_tree().create_timer(3.0).timeout
	var inv: Dictionary = Game.profile["inventory"]
	inv["scroll_heaven"] = 1
	inv["scroll_earth"] = 1
	var tw: Vector3 = ChuninExam.st["tower"]
	var door = tw + Vector3(0, 0, 46)
	for it in Interact.items:
		if it.get("kind", "") == "fod_tower":
			door = it["pos"]
	print("TOWER center ", tw, " door ", door, " dist ", Vector2(door.x - tw.x, door.z - tw.z).length())
	main.player.respawn(door)
	await get_tree().create_timer(1.5).timeout
	print("TOWER stage after walking to door: ", ChuninExam.stage)
	await main.shot("tower_prelim")
	get_tree().quit()
