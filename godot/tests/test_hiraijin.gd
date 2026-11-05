extends Node
## Hiraijin no Jutsu: tek başına / bir müttefikle çalışmaz; iki müttefikle üçü birden Kage Kulesi önüne ışınlanır; Shiranui Güç 40'ta öğrenir
var main: Node

func _ally(pl) -> Enemy:
	var a = Enemy.archetype("genin_rival", 0)
	a["respawn"] = false
	var e = Enemy.new()
	e.setup(a)
	e.team = "player"
	e.set_meta("teammate", true)
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	return e

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "shiranui", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["mastery"] = {"chakra": 50.0, "dayaniklilik": 40.0, "hiz": 30.0, "kenjutsu": 30.0, "ninjutsu": 60.0, "taijutsu": 40.0}
	Mastery.refresh_level(pr)
	pr["rank"] = 2
	Progress.clan_unlocks(false)
	print("HJ Güç=%d öğrenildi=%s" % [int(pr["level"]), "hiraijin_no_jutsu" in pr["learned"]])
	var v = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"])) + Vector3(250, 1, 250))
	await get_tree().create_timer(2.0).timeout
	var door = Exams.find_point(["mission_board"], "konoha")
	var allies = []
	for n in [0, 1, 2]:
		while allies.size() < n:
			allies.append(_ally(pl))
		await get_tree().create_timer(0.3).timeout
		var p0 = pl.global_position
		Jutsu.execute(pl, "hiraijin_no_jutsu", null)
		await get_tree().create_timer(1.2).timeout
		var moved = pl.global_position.distance_to(p0) > 20.0
		print("HJ müttefik=%d ışınlandı=%s kapıya=%.1f m müttefik_kapıya=%s" % [n, moved, pl.global_position.distance_to(door), allies.map(func(a): return snappedf(a.global_position.distance_to(door), 0.1))])
	get_tree().quit()
