extends Node
## Akademi sınavı son bölüm (hedef parkuru) akademi odasının içinden başlatılınca: dışarı çıkılıyor mu, kuklalar görünür/yerde mi, sınav bitiyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	var door = null
	for it in Interact.items:
		if it.get("kind", "") == "enter" and String(it.get("room", "")) == "academy":
			door = it
			break
	pl.respawn(door["pos"] + Vector3(0, 0.3, 0))
	await get_tree().create_timer(0.8).timeout
	Interiors.inst.enter(door)
	await get_tree().create_timer(1.5).timeout
	print("ACAD inside=%s y=%.0f" % [Interiors.inst.inside, pl.global_position.y])
	Exams.data = {"written": 1.0, "practical": 3, "targets": 0}
	Exams.academy_targets()
	await get_tree().create_timer(3.5).timeout
	print("ACAD after inside='%s' y=%.1f ground=%.1f cur=%s" % [Interiors.inst.inside, pl.global_position.y, Game.ground_height(pl.global_position.x, pl.global_position.z), Exams.cur])
	var ds = Exams.nodes.filter(func(n): return n is TrainingDummy)
	for d in ds:
		print("  dummy d=%.1f dy=%.1f" % [d.global_position.distance_to(pl.global_position), d.global_position.y - pl.global_position.y])
	pl.set_process(false)
	pl.cam.global_position = pl.global_position + Vector3(0, 9, 14)
	pl.cam.look_at(pl.global_position)
	await get_tree().create_timer(0.3).timeout
	await main.shot("academy_targets")
	for d in ds:
		d.take_hit({"dmg": 500.0, "kind": "heavy", "dir": Vector3.FORWARD})
	await get_tree().create_timer(1.0).timeout
	print("ACAD passed=%s cur='%s'" % [Exams.flags().get("academy_passed", false), Exams.cur])
	get_tree().quit()
