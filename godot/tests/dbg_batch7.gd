extends Node
## Toplu kontrol: dükkân stoku + benzersiz eşya, Rinnegan teknikleri açılıyor mu, efsane Bingo, düşman üstünde kalma
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var st = Gear.shop_stock("w", "konoha")
	var uq = st.filter(func(x): return String(x).begins_with("u_"))
	print("B7 stock=%d unique=%s" % [st.size(), uq.map(func(x): return Gear.item(x)["name"] + " r" + str(UI.rarity_of_gear(x)))])
	Gear.grant(Game.profile, uq[0])
	Game.save_game()
	Game.profile["level"] = 50
	Gear.grant(Game.profile, "goz_rinnegan", "sag_goz", null, null, {"lvl": 3, "origin": "uyanis"})
	Progress.clan_unlocks(false)
	var rl = Game.profile["learned"].filter(func(x): return String(Data.jutsu.get(x, {}).get("learn", "")) == "eye:rinnegan")
	print("B7 rinnegan_learned=%d" % rl.size())
	ClanWorld._seed_legends()
	var leg = Missions._bingo()["list"].filter(func(e): return e.has("legend")).map(func(e): return e["alias"])
	print("B7 legends=%s" % [leg])
	var e = Enemy.new()
	e.setup(Enemy.archetype("bandit", 0))
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -3)
	e.set_physics_process(false)
	await get_tree().create_timer(0.3).timeout
	pl.global_position = e.global_position + Vector3(0, 2.2, 0)
	pl.velocity = Vector3.ZERO
	await get_tree().create_timer(1.5).timeout
	print("B7 on_enemy_height=%.2f (ground ~0)" % (pl.global_position.y - Game.ground_height(pl.global_position.x, pl.global_position.z)))
	get_tree().quit()
