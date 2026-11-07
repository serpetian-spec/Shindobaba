extends Node
## Kirikiri Mai (gerçek Kamatari modeli) + Tetsuzan (koyu dikenli dev top)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "none", "element": "fuuton", "hair_style": "uzun", "hair": Color(0.85, 0.7, 0.3), "top": Color(0.85, 0.82, 0.75), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	var fw: Vector3 = pl.cam_forward()
	fw.y = 0
	fw = fw.normalized()
	var rt = fw.cross(Vector3.UP)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	Jutsu.execute(pl, "kuchiyose_kirikiri_mai", null)
	await _w(0.32)
	cc.global_position = pl.global_position + rt * 2.0 + fw * 6.0 + Vector3.UP * 2.6
	cc.look_at(pl.global_position + rt * 2.0 + Vector3.UP * 2.0)
	cc.current = true
	await _w(0.05)
	await main.shot("kamatari")
	pl.cam.current = true
	await _w(2.0)
	Jutsu.execute(pl, "kuchiyose_tetsuzan", null)
	await _w(0.45)
	cc.global_position = pl.global_position + rt * 20.0 + fw * 10.0 + Vector3.UP * 12.0
	cc.look_at(pl.global_position + fw * 22.0 + Vector3.UP * 14.0)
	cc.current = true
	await _w(0.05)
	await main.shot("tetsuzan")
	get_tree().quit()
