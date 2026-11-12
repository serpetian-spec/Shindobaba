extends Node
## Dövüş hissi: (1) klonlar düşmanı kilitliyor mu (sersemletilmiş zaman oranı), (2) düşmanlar ne sıklıkla saldırıyor, (3) oyuncu sonsuz komboda kalıyor mu
var main: Node
func _mk(pl, a: Dictionary, off: Vector3) -> Enemy:
	var e = Enemy.new()
	e.setup(a)
	main.add_child(e)
	var p = pl.global_position + off
	p.y = Game.ground_height(p.x, p.z)
	e.global_position = p
	e.home = p
	e.target = pl
	e.state = "chase"
	return e

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.max_hp = 999999.0
	pl.hp = pl.max_hp
	# (1) klonlar
	var a = Enemy.archetype("rogue", 0)
	a["respawn"] = false; a["hp"] = 99999.0
	var e = _mk(pl, a, pl.face_dir() * 6.0)
	for k in 3:
		var c = ShadowClone.new()
		main.add_child(c)
		c.global_position = e.global_position + Vector3(cos(k * 2.1), 0, sin(k * 2.1)) * 1.5
	var stunned = 0
	var total = 0
	for i in 100:
		await get_tree().create_timer(0.05).timeout
		total += 1
		if e.state in ["hitstun", "knockdown"]:
			stunned += 1
	print("FEEL clones: enemy stunned %d%% of time, clones_left=%d" % [stunned * 100 / total, get_tree().get_nodes_in_group("fighters").filter(func(f): return f is ShadowClone).size()])
	for c in get_tree().get_nodes_in_group("fighters"):
		if c is ShadowClone:
			c.vanish()
	e.queue_free()
	await get_tree().create_timer(0.5).timeout
	# (2) saldırganlık: 3 düşman, 10 sn içinde oyuncuya isabet sayısı
	Enemy._tok.clear()
	var es = []
	for k in 3:
		var b = Enemy.archetype("rogue", k)
		b["respawn"] = false; b["hp"] = 99999.0
		es.append(_mk(pl, b, Vector3(cos(k * 2.1), 0, sin(k * 2.1)) * 9.0))
	var hp0 = pl.hp
	Enemy.swings = 0
	var hits = [0]
	var breaks = 0
	pl.set_process(false)
	for i in 200:
		await get_tree().create_timer(0.05).timeout
		pl.hp = pl.max_hp
		if pl.combat.invuln > 0.9:
			breaks += 1
	print("FEEL aggression: swings_in_10s=%d tokens=%d combo_breaks=%d" % [Enemy.swings, Enemy.attack_tokens, breaks])
	get_tree().quit()
