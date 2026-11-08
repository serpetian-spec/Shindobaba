extends Node
## Kage'nin vuruşu: Güç 75 oyuncuya en ağır jutsusu ve düz vuruşu (gerçek take_hit, oyuncu zırhı dahil)
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var PG = float(OS.get_environment("PG")) if OS.get_environment("PG") != "" else 200.0
	var m = Game.profile.get("mastery", {})
	for kk in ["taijutsu", "ninjutsu"]:
		m[kk] = PG
	Game.profile["mastery"] = m
	var hp75 = Stats.ninja_hp(PG)
	print("KHIT start")
	for vid in (OS.get_environment("VIDS").split(",", false) if OS.get_environment("VIDS") != "" else ["konoha", "kumo", "kiri"]):
		print("KHIT spawn %s" % vid)
		Orgs._raid = {"vid": vid, "wave": 3, "t": 0.0, "out_t": 0.0, "nodes": [], "kage": false}
		Orgs._raid_kage(vid)
		var k: Enemy = Orgs._raid["nodes"][0]
		Orgs._raid = {}
		k.set_physics_process(false)
		k.add_buff("kage_mode", 9999.0, {"jutsu": 1.35, "melee": 1.35})
		var best = ""
		for id in k.arch["jutsu"]:
			if best == "" or int(Data.jutsu.get(id, {}).get("tier", 0)) > int(Data.jutsu.get(best, {}).get("tier", 0)):
				best = id
		var jd = Data.jutsu.get(best, {})
		var dmg = float(JutsuEngine.info(k, jd).get("dmg", 0.0))
		pl.max_hp = 1e7; pl.hp = 1e7
		pl.take_hit({"dmg": dmg, "attacker": k, "kind": "heavy", "element": String(jd.get("element", ""))})
		var jh = 1e7 - pl.hp
		pl.hp = 1e7
		pl.take_hit({"dmg": 12.0 * k.power * k.buff_mod("melee"), "attacker": k, "kind": "light", "melee": true})
		var mh = 1e7 - pl.hp
		k.add_buff("kage_resolve", 9999.0, {"armor": 0.9})
		var tot = 0.0
		var hits = []
		for i in 6:
			var h0 = k.hp
			k.take_hit({"dmg": 122.0 * Stats.jutsu_mult(Game.profile), "attacker": pl, "kind": "heavy", "element": ["katon", "fuuton", "suiton"][i % 3], "tier": 5})
			hits.append(int(h0 - k.hp))
			tot += h0 - k.hp
		var ps = tot / 6.0
		print("KHIT %s clan=%s buffs=%s metas=%s hits=%s" % [vid, k.arch.get("clan"), str(k.buffs.keys()), str(k.get_meta_list()), str(hits)])
		print("KHIT %s Güç%d oyuncu can=%.0f | Kage power=%.2f can=%.0f | Kage S-jutsu=%.0f -> oyuncu %.1f vuruşta ölür | oyuncu S-jutsu=%.0f -> Kage %.1f vuruşta ölür | Kage düz vuruş=%.0f" % [vid, PG, hp75, k.power, k.max_hp, jh, hp75 / maxf(jh, 1.0), ps, k.max_hp / maxf(ps, 1.0), mh])
		k.queue_free()
	get_tree().quit()
