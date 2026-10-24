extends Node
## Düşüşte "kollar açık" süzülme pozu takılı kalıyor mu: süper zıplama + havada darbe, normal düşüş
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	# 1) süper zıplama, havadayken darbe al
	pl.leap_charge = 1.0
	pl._leap(1.0)
	await get_tree().create_timer(0.4).timeout
	pl.take_hit({"dmg": 1.0, "knock": 6.0, "launch": 2.0, "kind": "heavy", "dir": Vector3(1, 0, 0)})
	await get_tree().create_timer(3.0).timeout
	print("FALL1 grounded=%s leaping=%s leap_w=%.2f" % [pl.grounded, pl.leaping, float(pl.model.overlay.weights.get("leap", 0.0))])
	# 2) normal düşüş (yüksekten bırak)
	pl.global_position += Vector3.UP * 25.0
	pl.velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	print("FALL2_AIR leaping=%s leap_w=%.2f" % [pl.leaping, float(pl.model.overlay.weights.get("leap", 0.0))])
	await get_tree().create_timer(3.0).timeout
	print("FALL2_LAND grounded=%s leap_w=%.2f" % [pl.grounded, float(pl.model.overlay.weights.get("leap", 0.0))])
	get_tree().quit()
