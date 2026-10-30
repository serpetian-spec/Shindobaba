extends Node
## Baskında köy ninjaları savaşa katılıyor mu
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(6.0).timeout
	Progress.set_story(Journal.FREE)
	Kage.start_raid("kumo")
	Kage.raid["at"] = Game.player.global_position
	await get_tree().create_timer(4.0).timeout
	print("RALLY rallied=", Kage.raid.get("rallied", []).size(), " allies=", Kage.raid["allies"].size())
	await main.shot("raid_rally")
	get_tree().quit()
