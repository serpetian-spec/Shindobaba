extends Node
## Çatı çarpışması: oyuncu birkaç şablon evin üstüne bırakılır, durduğu yükseklik çatı tepesiyle karşılaştırılır
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	await get_tree().create_timer(4.0).timeout
	var pl = main.player
	WorldDamage._drain()
	var near = WorldDamage._houses_near(pl.global_position, 250.0)
	print("ROOF near=", near.size())
	near.shuffle()
	var n = 0
	for r in near:
		if n >= 6:
			break
		var t: Dictionary = HouseKit.templates[r["ti"]]
		pl.global_position = r["pos"] + Vector3(0, float(t["roof_top"]) + 6.0, 0)
		pl.velocity = Vector3.ZERO
		await get_tree().create_timer(2.5).timeout
		var y = pl.global_position.y - r["pos"].y
		print("ROOF ti=", r["ti"], " round=", t.has("body_shape"), " h=", snappedf(t["h"], 0.1), " top=", snappedf(t["roof_top"], 0.1), " stood=", snappedf(y, 0.1), " floor=", pl.is_on_floor())
		await main.shot("roof_%d" % n)
		n += 1
	var v = Game.village("konoha")
	for sp in [["hokage", 0.0, 600.0], ["hokage_e", 25.0, 600.0], ["hospital", 557.0, 230.0], ["academy", -540.0, 610.0], ["academy_top", -540.0, 615.0]]:
		var q = Game.from_map(Vector2(v["x"] + sp[1], v["y"] + sp[2]))
		var g = Game.ground_height(q.x, q.z)
		pl.global_position = Vector3(q.x, g + 80.0, q.z)
		pl.velocity = Vector3.ZERO
		await get_tree().create_timer(4.0).timeout
		print("SPECIAL ", sp[0], " stood=", snappedf(pl.global_position.y - g, 0.1), " floor=", pl.is_on_floor())
	get_tree().quit()
