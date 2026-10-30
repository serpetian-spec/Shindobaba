extends Node
## Stun azalan getirisi + jutsu bloğu
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var a = Enemy.archetype("rogue", 0)
	a["respawn"] = false
	var e = Enemy.new()
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 3.0
	await get_tree().process_frame
	for k in 5:
		e.statuses.erase("stun")
		e.apply_status("stun", 2.0)
		print("CC stun#", k, " dur=", snappedf(e.statuses.get("stun", 0.0), 0.01))
	# kesintisiz bağlama: 3 sn sonra kurtulur
	await get_tree().create_timer(4.5).timeout
	e.statuses.clear()
	e.remove_meta("cc_imm")
	e.set_meta("cc_n", 0)
	var held = 0.0
	for k in 50:
		e.apply_status("bind", 0.3)
		await get_tree().create_timer(0.1).timeout
		if e.has_status("bind"):
			held += 0.1
	print("CC continuous bind held=", snappedf(held, 0.1))
	# blok: oyuncu blokta, önden küçük ve büyük jutsu
	pl.combat.action = "guard"
	pl.combat.guard_t = 1.0
	pl.chakra = 200.0
	for t in [0, 2, 4, 5]:
		pl.hp = pl.max_hp
		pl.combat.action = "guard"
		var hp0 = pl.hp
		pl.combat.take_hit({"dmg": 50.0, "attacker": e, "tier": t, "kind": "heavy" if t >= 3 else "light", "dir": Vector3.FORWARD})
		print("BLOCK tier ", t, " taken=", snappedf(hp0 - pl.hp, 0.1), " action=", pl.combat.action)
	pl.hp = pl.max_hp
	pl.combat.action = "guard"
	var h1 = pl.hp
	pl.combat.take_hit({"dmg": 50.0, "attacker": e, "kind": "light", "dir": Vector3.FORWARD, "melee": true})
	print("BLOCK melee taken=", snappedf(h1 - pl.hp, 0.1))
	print("CD tiers: ", [0, 1, 2, 3, 4, 5].map(func(t): return Combat.jutsu_cd({"tier": t, "cd": Combat.CD_AVG[t]})), " goukakyuu=", Combat.jutsu_cd(Data.jutsu["katon_goukakyuu"]))
	get_tree().quit()
