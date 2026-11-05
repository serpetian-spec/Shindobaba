extends Node
## İç mekânda güçlü itme/savrulma: oyuncu ve rakip duvardan geçip odadan atılmamalı (dalga jutsusu oyuncuyu dışarı atıyordu)
var main: Node

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	pr["level"] = 36
	var pl: Player = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	await _wait(1.0)
	ChuninExam.host = "konoha"
	ChuninExam.st = {"written": 5, "forest_days": 0.0, "prelim_wins": 0, "final_wins": 0, "jutsu": {}, "kawarimi": 0, "hp_lost": 0.0, "invasion": false, "mates_alive": 2}
	ChuninExam._forest()
	await _wait(1.5)
	pr["inventory"]["scroll_heaven"] = 1
	pr["inventory"]["scroll_earth"] = 1
	var tw: Vector3 = ChuninExam.st["tower"]
	tw.y = Game.ground_height(tw.x, tw.z)
	pl.respawn(tw + Vector3(10, 1.0, 0))
	await _wait(3.0)
	Hud.close_dialog()
	ExamUI._resume()
	ChuninExam._next_prelim()
	await _wait(3.0)
	var e = ChuninExam.st.get("duel")
	var y0 = pl.global_position.y
	var ok = 0
	var tot = 0
	for k in 8:
		var dir = Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0))
		pl.take_hit({"dmg": 1.0, "knock": 90.0, "launch": 6.0, "dir": dir, "kind": "heavy", "attacker": e})
		await _wait(1.2)
		var inside = Interiors.inst.inside
		var good = inside != "" and absf(pl.global_position.y - y0) < 4.0
		tot += 1
		ok += 1 if good else 0
		print("KNOCK oyuncu yön=%d inside=%s dy=%.2f merkezden=%.1f %s" % [k, inside, pl.global_position.y - y0, Vector2(pl.global_position.x - Interiors.inst.origin.x, pl.global_position.z - Interiors.inst.origin.z).length(), "OK" if good else "HATA"])
	if e and is_instance_valid(e):
		for k in 4:
			var dir = Vector3(cos(k * TAU / 4.0), 0, sin(k * TAU / 4.0))
			e.take_hit({"dmg": 1.0, "knock": 90.0, "launch": 6.0, "dir": dir, "kind": "heavy", "attacker": pl})
			await _wait(1.2)
			if not is_instance_valid(e):
				print("KNOCK rakip silindi (düello bitti)")
				break
			var good2 = absf(e.global_position.y - y0) < 4.0 and Vector2(e.global_position.x - Interiors.inst.origin.x, e.global_position.z - Interiors.inst.origin.z).length() < 45.0
			tot += 1
			ok += 1 if good2 else 0
			print("KNOCK rakip yön=%d dy=%.2f %s" % [k, e.global_position.y - y0, "OK" if good2 else "HATA"])
	ChuninExam._fail("test")
	await _wait(2.0)
	Hud.close_dialog()
	if Interiors.inst.inside != "":
		Interiors.inst.exit()
		await _wait(1.5)
	var p0 = pl.global_position
	Interiors.inst.enter({"pos": p0, "out": p0, "room": "lair_cave", "seed": 3})
	await _wait(2.5)
	y0 = pl.global_position.y
	print("KNOCK mağara inside=%s" % Interiors.inst.inside)
	# sert durumlar: duvara doğru 150 m/s hız ve konumu doğrudan duvarın ötesine taşıma (jutsu itişi gibi)
	for k in 4:
		var dir = Vector3(cos(k * TAU / 4.0 + 0.3), 0, sin(k * TAU / 4.0 + 0.3))
		pl.velocity = dir * 150.0
		await _wait(0.6)
		var g1 = Interiors.inst.inside != "" and absf(pl.global_position.y - y0) < 4.0 and Vector2(pl.global_position.x - Interiors.inst.origin.x, pl.global_position.z - Interiors.inst.origin.z).length() < 45.0
		tot += 1
		ok += 1 if g1 else 0
		print("KNOCK hız150 yön=%d merkezden=%.1f %s" % [k, Vector2(pl.global_position.x - Interiors.inst.origin.x, pl.global_position.z - Interiors.inst.origin.z).length(), "OK" if g1 else "HATA"])
		pl.global_position = pl.global_position + dir * 30.0
		await _wait(1.5)
		var g2 = Interiors.inst.inside != "" and absf(pl.global_position.y - y0) < 4.0 and Vector2(pl.global_position.x - Interiors.inst.origin.x, pl.global_position.z - Interiors.inst.origin.z).length() < 45.0
		tot += 1
		ok += 1 if g2 else 0
		print("KNOCK ışınla30 yön=%d inside=%s dy=%.2f merkezden=%.1f %s" % [k, Interiors.inst.inside, pl.global_position.y - y0, Vector2(pl.global_position.x - Interiors.inst.origin.x, pl.global_position.z - Interiors.inst.origin.z).length(), "OK" if g2 else "HATA"])
	print("KNOCK SONUÇ %d / %d" % [ok, tot])
	get_tree().quit()
