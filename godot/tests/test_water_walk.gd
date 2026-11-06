extends Node
## Su üstü yürüme: deniz, kayıtlı göletler/kanal ve Sonun Vadisi nehrinde oyuncu y = su yüzeyi mi
var main: Node

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _probe(pl, at: Vector3, tag: String) -> void:
	pl.global_position = at + Vector3(0, 1.5, 0)
	pl.velocity = Vector3.ZERO
	pl.swimming = false
	await _wait(1.5)
	var p = pl.global_position
	print("WTR %s terr=%.2f water=%.2f y=%.2f on_water=%s swim=%s grounded=%s chakra=%.0f" % [tag, Game.terrain_height(p.x, p.z), Game.water_level(p.x, p.z), p.y, pl.on_water, pl.swimming, pl.grounded, pl.chakra])

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _wait(2.0)
	Hud.close_dialog()
	var pl = main.player
	# kayıtlı yüzeyler (Konoha)
	var seen := {}
	var n := 0
	for k in Game._water_grid:
		for e in Game._water_grid[k]:
			if seen.has(e) or not is_instance_valid(e[0]):
				continue
			seen[e] = true
			var c: Vector2 = e[1]
			if Game.terrain_height(c.x, c.y) < e[4] - 0.25 and n < 4:
				n += 1
				await _probe(pl, Vector3(c.x, e[4], c.y), "kayit%d(%s)" % [n, e[0].get_parent().name])
	print("WTR kayit sayisi=", seen.size())
	await _probe(pl, Vector3(-2720, 0, 630), "deniz")
	# Sonun Vadisi
	var ve = Game.from_map(Vector2(120, 600))
	print("WTR ve=", ve, " terr=", Game.terrain_height(ve.x, ve.z))
	pl.global_position = ve + Vector3(0, 5, 0)
	await _wait(1.0)
	var best = null
	var seen2 = {}
	for k in Game._water_grid:
		for e in Game._water_grid[k]:
			if is_instance_valid(e[0]) and not seen2.has(e) and e[4] < -1.0:
				seen2[e] = true
				print("WTR vadi-aday c=%s y=%.1f terr=%.1f size=%s" % [e[1], e[4], Game.terrain_height(e[1].x, e[1].y), e[2]])
	for k in Game._water_grid:
		for e in Game._water_grid[k]:
			if is_instance_valid(e[0]) and e[4] < -1.0 and (best == null or (e[1] as Vector2).distance_to(Vector2(ve.x, ve.z)) < (best[1] as Vector2).distance_to(Vector2(ve.x, ve.z))):
				best = e
	if best:
		await _probe(pl, Vector3(best[1].x, best[4], best[1].y), "vadi")
		await _wait(3.0)
		var p = pl.global_position
		print("WTR vadi+3sn y=%.2f water=%.2f swim=%s" % [p.y, Game.water_level(p.x, p.z), pl.swimming])
		pl.set_process(false)
		pl.cam.global_position = p + Vector3(0, 4, 9)
		pl.cam.look_at(p + Vector3(0, 1, 0))
		await _wait(0.3)
		await main.shot("water_vadi")
	get_tree().quit()
