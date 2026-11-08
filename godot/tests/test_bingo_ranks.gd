extends Node
## Bingo kaçakları: gerçek doğma yolu (_bb_new + _bb_spawn) — rütbe başına Güç, can, vuruş, jutsu, elit
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	for rk in ["C", "B", "A", "S"]:
		for n in 2:
			var e = Missions._bb_new(rk)
			Missions._bingo()["list"].append(e)
			Missions._bb_spawn(e, pl.global_position + Vector3(20, 0, 0))
			var b = Missions._bb_spawned[int(e["id"])][0]
			print("BBR %s %s Güç=%d can=%.0f vuruş=%.2f elit=%s jutsu=%s" % [rk, b.display_name.left(38), b.level, b.max_hp, b.power, str(b.get_meta("elite_boss", "-")), str((b.arch["jutsu"] as Array).slice(0, 4))])
			b.queue_free()
	print("BBR Kage karşılaştırma: Güç 200 can ~15000 vuruş ~13")
	get_tree().quit()
