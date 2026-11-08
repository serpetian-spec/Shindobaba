extends Node
## Kage düellosu: Güç 75 oyuncuya karşı baskın Kage'si — mod açıyor mu, yakında/uzakta kaç jutsu atıyor,
## 20 sn'de oyuncuya ne kadar vuruyor, oyuncunun S-rank jutsusu ve yumruğu Kage'yi kaç vuruşta indirir
var main: Node
var casts := 0
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Game.profile["flags"]["rogue"] = true
	Orgs.flags()["rogue"] = true
	var m = Game.profile.get("mastery", {})
	for k in ["taijutsu", "ninjutsu", "kenjutsu"]:
		m[k] = 75.0
	Game.profile["mastery"] = m
	var pl = main.player
	pl.max_hp = Stats.ninja_hp(75); pl.hp = pl.max_hp
	print("DUEL player hp=%.0f melee_mult=%.2f" % [pl.max_hp, Stats.melee_mult(Game.profile)])
	for vid in OS.get_environment("VIDS").split(",", false) if OS.get_environment("VIDS") != "" else ["kumo", "konoha"]:
		var vs = Game.village(vid)
		pl.respawn(Game.from_map(Vector2(float(vs["x"]), float(vs["y"]))))   # gerçek baskın gibi: Kage'nin köyünde
		await _w(1.5)
		Hud.close_dialog()
		Orgs._raid = {"vid": vid, "wave": 3, "t": 0.0, "out_t": 0.0, "nodes": [], "kage": false}
		Orgs._raid_kage(vid)
		var k: Enemy = Orgs._raid["nodes"][0]
		k.tree_exiting.connect(func(): print("DUEL exiting dead=%s hp=%.0f" % [k.dead, k.hp]); print_stack())
		print("DUEL %s %s lv=%d hp=%.0f power=%.2f jutsu=%s" % [vid, k.display_name, k.level, k.max_hp, k.power, str(k.arch["jutsu"])])
		for dist in [3.0, 12.0]:
			k.global_position = pl.global_position + Vector3(0, 0, -dist)
			k.target = pl
			var real_hp = pl.max_hp
			pl.max_hp = 1e7
			pl.hp = 1e7
			var j0 = k.jcd.duplicate()
			var used = 0
			var t0 = Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < 20000:
				await get_tree().process_frame
				if not is_instance_valid(k):
					print("DUEL %s kage freed!" % vid)
					break
				for id in k.jcd:
					if float(k.jcd[id]) != float(j0.get(id, -1.0)):
						used += 1
						j0[id] = k.jcd[id]
				if pl.global_position.distance_to(k.global_position) > dist + 6.0:
					k.global_position = pl.global_position + Vector3(0, 0, -dist)
			var dealt = 1e7 - pl.hp
			print("DUEL %s dist=%.0f mode=%s jutsu_casts=%d dmg_to_player_20s=%.0f (= %.1f x Güç75 canı) buffs=%s" % [vid, dist, k.get_meta("kage_mode", false), used, dealt, dealt / real_hp, str(k.buffs.keys())])
			pl.max_hp = real_hp
			pl.hp = real_hp
		# oyuncunun vuruşu: S-rank katon ve ağır yumruk
		k.set_physics_process(false)
		var h0 = k.hp
		k.take_hit({"dmg": 122.0 * Stats.jutsu_mult(Game.profile), "attacker": pl, "kind": "heavy", "element": "katon"})
		var sj = h0 - k.hp
		h0 = k.hp
		k.take_hit({"dmg": 12.0 * Stats.melee_mult(Game.profile), "attacker": pl, "kind": "light", "melee": true})
		var pm = h0 - k.hp
		print("DUEL %s player S-jutsu hit=%.0f -> %.1f hits to kill; punch=%.0f -> %.0f punches" % [vid, sj, k.max_hp / maxf(sj, 1.0), pm, k.max_hp / maxf(pm, 1.0)])
		k.queue_free()
		await _w(0.5)
	get_tree().quit()
