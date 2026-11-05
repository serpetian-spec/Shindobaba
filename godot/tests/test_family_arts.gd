extends Node
## Aile öğretisi: klan üyesi Güç şartında kanon teknikleri kendiliğinden öğrenir (yatkınlıklar durur); NPC de kullanır
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for clan in ["gekko", "momochi", "kurosuki", "fuma", "mitarashi", "namikaze"]:
		var el = {"momochi": "suiton", "kurosuki": "raiton"}.get(clan, "katon")
		main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": clan, "element": el, "hair_style": "diken", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
		main._start_new_game()
		await get_tree().create_timer(0.5).timeout
		var pr = Game.profile
		pr["mastery"] = {"chakra": 70.0, "dayaniklilik": 60.0, "hiz": 40.0, "kenjutsu": 50.0, "ninjutsu": 80.0, "taijutsu": 60.0}
		Mastery.refresh_level(pr)
		Progress.clan_unlocks(false)
		var fam: Array = Data.clans[clan].get("family_arts", [])
		var got = fam.filter(func(j): return j in pr["learned"])
		var npc = ClanWorld.clan_jutsu(clan, 40, 8)
		print("FAM %s Güç=%d öğrendi=%s / %s  NPC havuzu=%s  yatkınlık=%s" % [clan, int(pr["level"]), got, fam, npc.filter(func(j): return j in fam), LegendPaths.BLOOD.values().has(clan)])
	get_tree().quit()
