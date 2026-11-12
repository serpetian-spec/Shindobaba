extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var id = Kin.id_of("baba")
	print("DJ baba id=", id)
	if id != "":
		var f = Friends.all()[id]
		f["job"] = "antrenman"
		for tod in [0.5, 0.9]:
			Game.world.env.time_of_day = tod
			print("DJ tod=", tod, " night=", HomeLife.night(), " job=", Friends.job_of(f), " where=", Friends.where_text(id), " home=", HomeLife._kin_home(id))
	get_tree().quit()
