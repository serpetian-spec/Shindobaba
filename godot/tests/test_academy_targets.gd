extends Node
## Akademi atış hedefleri: 3 hedef, 90 sn; hepsi kırılınca sonuç ekranına geçiliyor mu
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	Exams.data = {"written": 0.8, "practical": 3, "targets": 0}
	Exams.academy_targets()
	await get_tree().create_timer(2.0).timeout
	var ds = Exams.nodes.filter(func(n): return is_instance_valid(n) and n is TrainingDummy)
	print("TARGETS hedef=%d süre=%.0f cur=%s" % [ds.size(), float(Exams.data["t"]), Exams.cur])
	for d in ds:
		Exams.on_dummy_broken(d)
	await get_tree().create_timer(1.0).timeout
	print("TARGETS kırıldı=%d cur_after=%s" % [int(Exams.data.get("broken", -1)), Exams.cur])
	get_tree().quit()
