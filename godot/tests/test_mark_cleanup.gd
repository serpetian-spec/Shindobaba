extends Node
## Yamanaka işaret oku: çağıran ölse de 15 sn sonra oyuncunun başından kalkar
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.9, 0.9, 0.9), "top": Color(0.7, 0.2, 0.2), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	var n0 = pl.get_child_count()
	var a = Enemy.archetype("rogue", 2)
	a["clan"] = "yamanaka"
	var e := Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -8)
	await _w(0.3)
	Jutsu.execute(e, "shindenshin_no_jutsu", pl)
	await _w(0.3)
	var n1 = pl.get_child_count()
	e.queue_free()   # Yamanaka ölür
	await _w(16.0)
	print("MC children before=%d marked=%d after16s=%d (temiz=%s)" % [n0, n1, pl.get_child_count(), str(pl.get_child_count() <= n0)])
	get_tree().quit()
