extends Node
## Kikaichū kukla iplerini yer: kuklaya isabet -> kukla çöker; kuklacıya isabet -> bütün kuklaları çöker; Aburame jutsu bilgisi kikai taşır
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "aburame", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var a = Enemy.archetype("rogue", 3)
	a["respawn"] = false
	var e := Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 8.0
	await _w(0.3)
	var ps = ClanConstruct.spawn(e, "puppet", 2, {"tier": 2})
	await _w(0.5)
	print("KS0 puppets=%d" % ps.size())
	var inf = JutsuEngine.info(pl, Data.jutsu["hijutsu_mushidama"])
	print("KS1 aburame jutsu kikai=%s ; katon kikai=%s" % [str(inf.get("kikai", false)), str(JutsuEngine.info(pl, Data.jutsu["katon_gokakyu"] if Data.jutsu.has("katon_gokakyu") else {"id": "x"}).get("kikai", false))])
	ps[0].take_hit({"attacker": pl, "dmg": 1.0, "kind": "light", "element": "", "kikai": true})
	print("KS2 hit puppet0 -> limp0=%.1f limp1=%.1f" % [ps[0].limp_t, ps[1].limp_t])
	await _w(4.5)
	print("KS3 after 4.5s limp0=%.1f" % ps[0].limp_t)
	e.take_hit({"attacker": pl, "dmg": 1.0, "kind": "light", "element": "", "kikai": true})
	print("KS4 hit owner -> limp0=%.1f limp1=%.1f" % [ps[0].limp_t, ps[1].limp_t])
	get_tree().quit()
