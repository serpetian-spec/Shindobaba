extends Node
## Ölüm = yenilgi: baskın kaybedilir (baskıncılar çekilir), görev başarısız olur, doğulan yerde hedefleyen düşman peşini bırakır
var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _wait(1.5)
	Hud.close_dialog()
	var pl = main.player
	Kage.start_raid("kumo")
	await _wait(2.0)
	print("DTH baskın başladı: ", not Kage.raid.is_empty(), " düşman=", (Kage.raid.get("nodes", []) as Array).size())
	Game.profile["active_mission"] = {"title": "Test Görevi", "rank": "D", "village": "konoha", "type": "quest", "steps": []}
	print("DTH görev var: ", not Missions.active().is_empty())
	pl.hp = 0.0
	Progress.on_player_died()
	await _wait(0.5)
	print("DTH ölüm sonrası baskın=%s görev=%s" % [not Kage.raid.is_empty(), not Missions.active().is_empty()])
	await _wait(3.0)
	# doğulan yerde peşindeki düşman
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["respawn"] = false
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + Vector3(6, 0, 0)
	e.home = e.global_position
	e.target = pl
	e.state = "chase"
	Progress._calm_after_death(pl.global_position)
	await _wait(0.2)
	print("DTH peşindeki geçici düşman çekildi: ", not is_instance_valid(e) or e.is_queued_for_deletion())
	get_tree().quit()
