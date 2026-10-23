extends Node
## Sabit Naruto hikâyesi yok: Akademi başlangıcı -> mezuniyet -> serbest oyun (Yolun), hedef seçme/takip, kronik, eski kayıt dönüşümü.
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	print("ST start story=", Progress.story(), " seed=", Game.profile.has("seed"), " obj=", Progress.objective_text())
	# Akademi adımları
	for i in [1, 2, 3]:
		Progress.set_story(i)
		print("ST step ", i, ": ", Progress.objective_text())
	# Zil testi geçildi -> mezuniyet (exams.gd bell_result yolu: promote(1) + set_story(4))
	Progress.promote(1)
	Progress.set_story(4)
	Progress.set_story(11)   # eski kod numarası: serbest oyunun ötesine geçmemeli
	print("ST free=", Journal.is_free(), " story=", Progress.story(), " obj=", Progress.objective_text())
	Journal.pick("chunin")
	Journal.pick("explore")
	Journal.pick("legend")
	Game.profile["track"] = "goal:explore"
	await get_tree().create_timer(0.5).timeout
	print("ST marker ", Missions.has_marker, " -> ", Missions.target_name)
	Game.profile["level"] = 15
	print("ST obj=", Progress.objective_text())
	Journal.add("Kumo yolunda bir tüccarı haydutlardan kurtardın.", "event")
	Game.profile["rival"] = {"name": "Kaçak Ninja", "kind": "rogue", "element": "suiton", "level": 9, "wins": 2, "t": 0.0}
	await get_tree().create_timer(2.5).timeout
	main._pause()
	Menus.ninja_menu(main, "missions")
	await get_tree().create_timer(0.8).timeout
	await main.shot("story_tab")
	main.resume()
	# eski kayıt: Naruto hikâyesinin 9. adımı + yarım Yasak Parşömen görevi
	var old = {"story": 9, "level": 20, "rank": 1, "flags": {}, "active_mission": {"title": "Yasak Parşömen"}}
	Journal.migrate(old)
	print("ST migrate story=", old["story"], " mission=", old["active_mission"], " journal=", old["journal"].size(), " seed=", old.has("seed"))
	var mid = {"story": 2, "level": 3, "rank": 0, "flags": {}}
	Journal.migrate(mid)
	print("ST migrate academy story=", mid["story"])
	get_tree().quit()
