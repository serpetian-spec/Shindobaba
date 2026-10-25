extends Node
## Akademi sınavı uygulama → hedef parkuru tam akış (köy seçilebilir): oyuncu vuruşuyla kuklaları devir, sınav bitiyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	var vid = "konoha"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--village="):
			vid = a.substr(10)
	main.creator_state["village"] = vid
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Game.profile["level"] = 6
	var spot = null
	for it in Interact.items:
		if (it.get("kind", "") == "enter" and String(it.get("room", "")) == "academy") or it.get("kind", "") == "academy":
			var c = Game.from_map(Vector2(Game.village(vid)["x"], Game.village(vid)["y"]))
			if Vector2(it["pos"].x - c.x, it["pos"].z - c.z).length() < float(Game.village(vid)["r"]) * 1.2:
				spot = it
	print("FLOW village=%s home=%s spot=%s" % [vid, Progress.home(), spot.get("kind", "") if spot else null])
	pl.respawn(spot["pos"] + Vector3(0, 0.3, 0))
	await get_tree().create_timer(1.0).timeout
	if spot.get("kind", "") == "enter":
		Interiors.inst.enter(spot)
		await get_tree().create_timer(1.5).timeout
	Exams.data = {"written": 1.0, "practical": 0, "targets": 0}
	Exams.academy_practical()
	Exams.on_technique("bunshin_no_jutsu")
	Exams.on_technique("henge")
	await get_tree().create_timer(5.0).timeout   # kunai fırlatılır
	Exams.on_technique("kawarimi")
	print("FLOW after kawarimi cur=%s" % Exams.cur)
	await get_tree().create_timer(4.0).timeout
	print("FLOW cur=%s inside='%s'" % [Exams.cur, Interiors.inst.inside])
	var ds = Exams.nodes.filter(func(n): return n is TrainingDummy and is_instance_valid(n))
	print("FLOW dummies=%d" % ds.size())
	for d in ds:
		pl.global_position = d.global_position + Vector3(0, 0, 1.2)
		await get_tree().create_timer(0.1).timeout
		for k in 4:
			Combat.hit_sphere(pl, d.global_position + Vector3.UP, 1.0, {"dmg": 40.0, "kind": "light", "dir": Vector3.FORWARD})
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(1.0).timeout
	print("FLOW done cur='%s' passed=%s broken=%s" % [Exams.cur, Exams.flags().get("academy_passed", false), Exams.data.get("broken", "-")])
	get_tree().quit()
