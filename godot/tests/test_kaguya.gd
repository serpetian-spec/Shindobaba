extends Node
## Klan jutsuları testi: ClanJutsu'nun uyguladığı her jutsu sırayla atılır (hata/çökme yok mu),
## seçilmiş olanların etki anında ekran görüntüsü alınır, uçuş kipi (Keijūgan, kum bulutu) denenir.

var main: Node
var IDS = []


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _enemy(pos: Vector3) -> Enemy:
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pos
	e.home = pos
	e.lose_target(999)
	e.state = "idle"
	e.max_hp = 1e9
	e.hp = 1e9
	return e


func _clear() -> void:
	for n in get_tree().current_scene.get_children():
		if n is Projectile:
			n.queue_free()
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is ShadowClone or f is Summon or f is ClanConstruct:
			f.queue_free()


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "kaguya", "element": "katon", "hair_style": "diken",
		"hair": Color(0.9, 0.9, 0.92), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var v := Game.village("konoha")
	var al = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base := Game.from_map(Vector2(al["x"], al["y"]))
	var vs = Game.village("suna")
	base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	pl.max_hp = 1e9
	pl.hp = 1e9
	pl.max_chakra = 1e9
	pl.chakra = 1e9
	pl.yaw = 0.0
	pl.pitch = -12.0
	pl.cam_dist = 10.0
	var pr = Game.profile
	pr["level"] = 60
	pr["rank"] = 4
	await _wait(1.5)
	var fwd: Vector3 = pl.cam_forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var side = fwd.cross(Vector3.UP)
	var foes = [_enemy(base + fwd * 8.0), _enemy(base + fwd * 12.0 + side * 3.0), _enemy(base + fwd * 10.0 - side * 3.5)]
	await _wait(0.5)

	var f0 = foes[0]
	# 1) Shikotsumyaku: fiziksel darbe x0.8 (element darbesine göre)
	pl.max_hp = 1e9; pl.hp = 1e9
	await _wait(1.3)
	pl.take_hit({"dmg": 1.0, "kind": "light", "knock": 0.0, "attacker": f0, "element": "doton", "dir": Vector3.FORWARD})   # can kırpma artefaktını yut
	pl.combat.invuln = 0.0
	var a = pl.hp
	pl.take_hit({"dmg": 50.0, "kind": "light", "knock": 0.0, "attacker": f0, "dir": Vector3.FORWARD})
	var phys = a - pl.hp
	pl.combat.invuln = 0.0
	a = pl.hp
	pl.take_hit({"dmg": 50.0, "kind": "light", "knock": 0.0, "attacker": f0, "element": "doton", "dir": Vector3.FORWARD})
	print("KG phys=", phys, " doton=", a - pl.hp)
	# 2) oyuncu Karamatsu: yakın dövüşle vuran düşman yaralanır
	Jutsu.execute(pl, "karamatsu_no_mai", null)
	await _wait(0.3)
	var fh = f0.hp
	a = pl.hp
	pl.combat.invuln = 0.0
	pl.take_hit({"dmg": 40.0, "kind": "heavy", "knock": 0.0, "attacker": f0, "melee": true, "dir": Vector3.FORWARD})
	print("KG larch player_dmg=", a - pl.hp, " attacker_dmg=", fh - f0.hp, " buff=", Buffs.has("karamatsu"))
	# 3) düşman Karamatsu: oyuncu vurursa oyuncu yaralanır
	Buffs.remove("karamatsu")
	f0.add_buff("karamatsu", 5.0, {})
	pl.combat.invuln = 0.0
	a = pl.hp
	fh = f0.hp
	f0.take_hit({"dmg": 40.0, "kind": "heavy", "knock": 0.0, "attacker": pl, "melee": true, "dir": Vector3.FORWARD})
	print("KG enemy larch enemy_dmg=", fh - f0.hp, " player_dmg=", a - pl.hp)
	f0.buffs.erase("karamatsu")
	# 4) Sawarabi + mühür II: hedefin arkasından çıkar
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for id in ["karamatsu_no_mai", "sawarabi_no_mai", "tessenka_no_mai_tsuru"]:
		pl.global_position = base
		f0.global_position = base + fwd * 8.0
		f0.statuses.clear()
		var tv = pl.global_position - f0.global_position
		f0.facing = atan2(-tv.x, -tv.z)
		if id == "sawarabi_no_mai":
			Buffs.add("juin2", 6.0, {})
		Jutsu.execute(pl, id, f0)
		await _wait(0.6 if id != "sawarabi_no_mai" else 1.0)
		var fd = pl.face_dir()
		var sd = fd.cross(Vector3.UP)
		cc.global_position = base + Vector3.UP * (3.0 if id != "sawarabi_no_mai" else 9.0) + sd * (7.0 if id != "sawarabi_no_mai" else 22.0) + fd * 3.0
		cc.look_at(base + Vector3.UP * 1.2 + fd * 4.0)
		cc.current = true
		await _wait(0.03)
		await main.shot("kg_%s" % id)
		pl.cam.current = true
		if id == "sawarabi_no_mai":
			await _wait(0.6)
			var behind = (pl.global_position - f0.global_position).dot(f0.face_dir())
			print("KG sawarabi dist=", pl.global_position.distance_to(f0.global_position), " behind(<0)=", behind)
			Buffs.remove("juin2")
		await _wait(1.0)
		_clear()
	get_tree().quit()
