extends Node
## Sınav akışı (gerçek oynanış): hedef okları, Zil Testi karşılaması, Chunin hedefi
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(4.0).timeout
	var pr = Game.profile
	for s in [0, 1, 2, 3]:
		pr["story"] = s
		await get_tree().create_timer(0.3).timeout
		print("ADIM ", s, " hedef=", Missions.target_name, " dist=", int(Missions.target_marker.distance_to(main.player.global_position)), " | ", Progress.objective_text())
	pr["flags"]["academy_passed"] = true
	pr["story"] = 3
	await get_tree().create_timer(0.3).timeout
	var tp = Exams.find_point(["training"])
	print("MEZUN hedef=", Missions.target_name, " eğitim noktasına uzaklık=", int(Missions.target_marker.distance_to(tp)), " | ", Progress.objective_text())
	main.player.respawn(tp + Vector3(5, 1, 5))
	await get_tree().create_timer(1.5).timeout
	print("KARŞILAMA dialog=", Hud.dialog_open(), " ui=", Game.ui_open)
	Exams.bell_start()
	await get_tree().create_timer(0.5).timeout
	print("ZİL cur=", Exams.cur)
	Exams._bell_result(true, "test")
	await get_tree().create_timer(0.5).timeout
	print("ZİL SONRASI rank=", pr["rank"], " story=", pr["story"], " | ", Progress.objective_text())
	for s in [4, 5, 6, 7, 9]:
		pr["story"] = s
		await get_tree().create_timer(0.3).timeout
		print("ADIM ", s, " hedef=", Missions.target_name, " dist=", int(Missions.target_marker.distance_to(main.player.global_position)), " marker=", Missions.has_marker)
	get_tree().quit()
