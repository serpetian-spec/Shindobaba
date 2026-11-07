extends Node
## Düşman Kamizuru oyuncuyla tarzıyla dövüşür: menzilde durur (6.5 m), arı vuruşları oyuncuya hasar verir
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.25, 0.2, 0.15), "top": Color(0.85, 0.85, 0.8), "pants": Color(0.2, 0.2, 0.25), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await get_tree().create_timer(1.0).timeout
	pl.max_hp = 1e6; pl.hp = 1e6
	var e := Enemy.new()
	var a = Enemy.archetype("rogue", 2)
	a["clan"] = "kamizuru"
	a["jutsu"] = []
	e.setup(a)
	e.look["weapon_r"] = null
	e.arch["clan"] = "kamizuru"
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -15)
	e.home = e.global_position
	e.target = pl
	var hp0 = pl.hp
	var dmin = 99.0; var dsum = 0.0; var n = 0
	for k in 40:
		await get_tree().create_timer(0.25).timeout
		var d = e.global_position.distance_to(pl.global_position)
		dmin = minf(dmin, d); dsum += d; n += 1
		if k % 4 == 0:
			print("KS t=%d d=%.1f state=%s tgt=%s hostile=%s pl_y=%.1f" % [k, d, str(e.get("state")), str(e.target), str(Combat.hostile(e, pl)), pl.global_position.y])
	print("KF keyed=%s dmg_to_player=%.1f dist_min=%.1f dist_avg=%.1f" % [e._keyed_id(), hp0 - pl.hp, dmin, dsum / n])
	get_tree().quit()
