extends Node
## Vuruş testi: usta (skill yüksek) düşmana art arda vurulabiliyor mu; Mangekyō düşman Amaterasu/Susanoo kullanıyor mu;
## Susanoo savuruşu ayak dibindeki küçük düşmana değiyor mu
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
	# 1) usta düşman: 20 hafif darbe
	var a = Enemy.archetype("rogue", 0)
	a["respawn"] = false; a["hp"] = 5000.0; a["level"] = 50; a["power"] = 3.0; a["skill"] = 0.95; a["guard"] = 0.55; a["sub"] = 0.25
	var e = _mk(pl, a, pl.face_dir() * 2.0)
	var landed = 0
	for i in 20:
		var hp0 = e.hp
		var d = e.global_position - pl.global_position
		Combat.hit_sphere(pl, e.global_position + Vector3.UP, 1.0, {"dmg": 20.0, "knock": 1.0, "kind": "light" if i % 4 != 3 else "heavy", "dir": d.normalized()})
		if hp0 - e.hp > 10.0:
			landed += 1
		await get_tree().create_timer(0.3).timeout
	print("HITS skill=%.2f landed=%d/20" % [e.skill, landed])
	e.queue_free()
	# 2) Mangekyō düşman
	var b = Enemy.archetype("rogue", 1)
	b["respawn"] = false; b["hp"] = 3000.0; b["level"] = 45
	var m = _mk(pl, b, pl.face_dir() * 12.0)
	m.set_meta("eyes", {"kind": 4, "lvl": 3})
	m.set_meta("ea_cd", 0.5)
	await get_tree().create_timer(2.0).timeout
	print("ARTS burn=%s stun=%s" % [pl.has_status("burn"), pl.has_status("stun")])
	m.hp = m.max_hp * 0.4
	await get_tree().create_timer(1.5).timeout
	print("ARTS susanoo=%s" % (m.has_meta("ea_susanoo") and is_instance_valid(m.get_meta("ea_susanoo"))))
	pl.set_process(false)
	pl.cam.global_position = m.global_position + Vector3(14, 8, 18)
	pl.cam.look_at(m.global_position + Vector3.UP * 4)
	await main.shot("enemy_susanoo")
	m.queue_free()
	# 3) oyuncu Susanoo savuruşu, ayak dibinde küçük düşman
	var c = Enemy.archetype("bandit", 0)
	c["respawn"] = false; c["hp"] = 5000.0
	var small = _mk(pl, c, pl.face_dir() * 6.0)
	small.skill = 0.0
	var sn = Susanoo.new()
	pl.add_child(sn)
	sn.build({"susanoo": {"mastery": 999.0}}, 5, pl.model)
	var h0 = small.hp
	sn.swipe(pl, pl.face_dir())
	await get_tree().create_timer(0.6).timeout
	print("ZONE tier=%d small_dmg=%d" % [sn.tier, int(h0 - small.hp)])
	get_tree().quit()
