extends Node
## Köy zemini rengi / ot yoğunluğu: Konoha içinde oyuncu arkası çekim (birkaç nokta)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.15, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("konoha")
	Hud.show_game_hud(false)
	var i = 0
	for off in [Vector2(20, -300), Vector2(-260, 120), Vector2(300, 250)]:
		pl.respawn(Game.from_map(Vector2(v["x"] + off.x, v["y"] + off.y)))
		await get_tree().create_timer(3.0).timeout
		await main.shot("vg_%d" % i)
		i += 1
	get_tree().quit()
