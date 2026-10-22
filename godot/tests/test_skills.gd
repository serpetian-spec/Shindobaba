extends Node
## Yetenek ağacı: düğüm öğrenme, etkiler, ekran görüntüleri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	var pr = Game.profile
	var pl = main.player
	print("DÜĞÜM SAYISI: ", Data.skills.get("nodes", {}).size(), " dal: ", Data.skills.get("branches", []).size())
	pr["level"] = 60
	pr["rank"] = 3
	pr["sp"] = 80
	var hp0 = Stats.max_hp(pr)
	var mel0 = Stats.melee_mult(pr)
	print("ENGEL (seviye 1 olsaydı tai4): ", Stats.skill_block({"level": 1, "sp": 5, "skills": [], "clan": "none"}, "tai4"))
	for sid in ["tai1", "tai2", "tai_govde", "strong_fist", "tai4", "shi_parkur1", "shi_leap1", "shi_dash", "shi_leap2", "shi_jump3", "nin1", "nin3", "sur_can1", "sur_tuccar", "gates1"]:
		var ok = Stats.learn_skill(pr, sid)
		print("öğren ", sid, " -> ", ok, "  ", Stats.skill_block(pr, sid) if not ok else "")
	pl.apply_profile_stats()
	print("can: ", hp0, " -> ", Stats.max_hp(pr), "   yakın dövüş: ", snappedf(mel0, 0.01), " -> ", snappedf(Stats.melee_mult(pr), 0.01))
	print("hız +", Stats.skill(pr, "speed"), "  sıçrayış +", Stats.skill(pr, "leap"), "  hava atılma +", Stats.skill(pr, "air_dash"), "  zıplama +", Stats.skill(pr, "jumps"))
	print("mühür hızı +", Stats.skill(pr, "seal_speed"), "  maliyet ", Stats.skill(pr, "jutsu_cost"), "  fiyat 100 -> ", Stats.price(100), "  yumuşak yumruk engeli: ", Stats.skill_block(pr, "gentle_fist"))
	var sp_before = int(pr["sp"])
	var back = Stats.respec(pr)
	print("sıfırlama: ", back, " puan geri, sp ", sp_before, " -> ", pr["sp"], "  kalan: ", pr["skills"])
	for sid in ["tai1", "tai2", "tai_kombo1", "tai_govde", "tai_guard", "shi_parkur1", "shi_leap1", "shi_gizli1", "shi_dash", "nin1", "nin2", "nin3", "nin_el1"]:
		Stats.learn_skill(pr, sid)
	main._pause()
	for br in ["taijutsu", "shinobi", "ninjutsu"]:
		SkillTree.branch = br
		SkillTree.sel = {"taijutsu": "strong_fist", "shinobi": "shi_jump3", "ninjutsu": "nin4"}[br]
		Menus.ninja_menu(main, "skills")
		await get_tree().create_timer(0.6).timeout
		await main.shot("sk_" + br)
	SkillTree.confirm = "nin4"
	Menus.ninja_menu(main, "skills")
	await get_tree().create_timer(0.4).timeout
	await main.shot("sk_onay")
	SkillTree.learn(main, "nin4")
	print("nin4 öğrenildi: ", "nin4" in pr["skills"])
	get_tree().quit()
