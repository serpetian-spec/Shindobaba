extends Node
## Tenseigan yeni yolu (Ay Mabedi) + Bakuha teknikleri Kil Yolu'nda + Ōtsutsuki oynanamaz
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hyuga", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var ey: Eyes = pl.combat.modes.eyes
	var pr = Game.profile
	pr["level"] = 45
	for s in ["sag_goz", "sol_goz"]:
		Gear.equipped(pr, s)["lvl"] = 3
	ey.toggle()
	Game.world.env.time_of_day = 0.05
	for i in 70:
		ey.evolve_tick(1.0)
	print("MOON auto kinds (7 olmamalı)=", ey._kind("sag"), ey._kind("sol"), " call=", pr["flags"].get("moon_call", false))
	var q = KgPaths.site_quest("moon", [0.0, 0.0])
	print("MOON quest=", q["title"], " steps=", q["steps"].size())
	KgPaths._moon_site({"pos": pl.global_position}, KgPaths.SITES["moon"])
	await get_tree().create_timer(0.3).timeout
	await main.shot("moon_dialog")
	Menus.clear()
	KgPaths.quest_done(q, true)
	await get_tree().create_timer(0.5).timeout
	print("MOON after quest kinds=", ey._kind("sag"), ey._kind("sol"))
	print("KIL order=", LegendPaths.PATHS["kil"]["order"].filter(func(j): return not Data.jutsu.has(j)), " bakuha learn=", Data.jutsu["bakuha_rensa"]["learn"], " clan exists=", Data.clans.has("bakuha"))
	print("UNPLAYABLE ok=", Progress.UNPLAYABLE_CLANS)
	get_tree().quit()
