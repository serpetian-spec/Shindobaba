extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Game.profile["flags"]["rogue"] = true
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	Kage.succeed("kiri")
	print("KAGE reign=%s clan=%s" % [str(Kage.reign("kiri")).left(90), Kage.kage_clan("kiri")])
	Orgs._raid = {"vid": "kiri", "wave": 3, "t": 0.0, "out_t": 0.0, "nodes": [], "kage": false}
	Orgs._raid_kage("kiri")
	var k = Orgs._raid["nodes"][0]
	print("KAGE enemy name=%s lv=%d hp=%.0f jutsu=%s" % [k.display_name, k.level, k.max_hp, str(k.arch.get("jutsu", []))])
	var counts = {}
	for i in 400:
		var pk = k._pick_jutsu(k.arch.get("jutsu", []))
		counts[pk] = int(counts.get(pk, 0)) + 1
	print("KAGE pick dist=%s" % str(counts))
	k.take_hit({"dmg": 1e9, "attacker": pl, "kind": "heavy"})
	await _w(1.0)
	print("KAGE after kill reign=%s" % str(Kage.reign("kiri").get("name", "")))
	get_tree().quit()
