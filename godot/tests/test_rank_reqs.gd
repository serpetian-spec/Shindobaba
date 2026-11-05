extends Node
## Rütbe görev şartları: görevsiz başvuru reddedilir, şart tutunca kabul
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	var pr = Game.profile
	pr["rank"] = 1
	pr["level"] = 30
	pr["story"] = Journal.FREE
	pr["missions_done"] = {"D": 0, "C": 0, "B": 0, "A": 0, "S": 0}
	ChuninExam.apply()
	print("CHUNIN no-missions: ", Hud.last_dialog.left(90))
	Hud.close_dialog()
	pr["missions_done"] = {"D": 8, "C": 4, "B": 0, "A": 0, "S": 0}
	ChuninExam.apply()
	print("CHUNIN ok-missions: ", Hud.last_dialog.left(90))
	Hud.close_dialog()
	pr["rank"] = 2
	pr["level"] = 50
	pr["elements"] = ["katon", "fuuton"]
	pr["missions_done"] = {"D": 8, "C": 4, "B": 0, "A": 3, "S": 0}
	Exams.jonin_offer()
	print("JONIN old-reqs: ", Hud.last_dialog.left(110))
	Hud.close_dialog()
	pr["missions_done"] = {"D": 8, "C": 4, "B": 6, "A": 4, "S": 0}
	Exams.jonin_offer()
	print("JONIN ok: ", Hud.last_dialog.left(90))
	get_tree().quit()
