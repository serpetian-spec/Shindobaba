extends Node
## Öldürme süresi: oyuncu Sv.X yakın dövüş/jutsu hasarı vs tekleşen görev düşmanı canı
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	for lv in [10, 25, 45]:
		Game.profile["level"] = lv
		var combo = 0.0
		for i in 5:
			combo += float(main.player.combat._combo(i)["dmg"]) * Stats.melee_mult(Game.profile)
		var jd = Data.jutsu["katon_goukakyuu"]
		var jut = JutsuEngine.base_dmg(main.player, jd) * float(Combat._bal.get("katon_goukakyuu", 1.0) if not Combat._bal.is_empty() else 1.0)
		var bm = Missions._spawn_boss({"name": "Jakotsu", "hp": 5200.0, "level": lv + 8, "power": 3.2}, "rogue", main.player.global_position + Vector3(50, 0, 50))
		var s5 = JutsuEngine.base_dmg(main.player, {"tier": 5}) 
		print("TTK lv%d BOSS hp=%d power=%.2f  S-jutsu(oyuncu)=%.0f -> %.1f jutsu  combo=%.0f -> %.1f kombo  boss S-jutsu=%.0f vs oyuncu can %d" % [lv, bm.max_hp, bm.power, s5, bm.max_hp / s5, combo, bm.max_hp / combo, 100.0 * bm.power, Stats.max_hp(Game.profile)])
		bm.queue_free()
		for spec in [["rogue", 4, "B"], ["bandit", 4, "C"], ["rogue", 1, "B"]]:
			var a = Enemy.archetype(spec[0], 0)
			a["level"] = lv
			Enemy.toughen(a, spec[1], spec[2])
			var e = Enemy.new()
			e.setup(a)
			var hit = (4.5 + 8.0) * 0.5 * e.power
			print("TTK lv%d %s x%d: hp=%d  combo=%.0f (%.1f kombo)  goukakyuu=%.0f  enemy hit=%.0f vs player hp=%d (%.0f darbe)" % [lv, spec[0], spec[1], e.max_hp, combo, e.max_hp / combo, jut, hit, Stats.max_hp(Game.profile), Stats.max_hp(Game.profile) / hit])
			e.free()
	get_tree().quit()
