extends Node
## Kuchiyose: Ibuse Dokukami bağımsız jutsusu gerçek semender modelini getirir
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.5)
	pl.facing = 0.0
	Jutsu.execute(pl, "kuchiyose_ibuse_dokukami", null)
	await _w(1.6)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var fw: Vector3 = pl.cam_forward()
	fw.y = 0
	fw = fw.normalized()
	var rt = fw.cross(Vector3.UP)
	for v in [[rt * 34.0 + fw * 16.0 + Vector3.UP * 10.0, "ibuse_side"], [-fw * 9.0 + rt * 4.0 + Vector3.UP * 8.0, "ibuse_back"]]:
		cc.global_position = pl.global_position + v[0]
		cc.look_at(pl.global_position + fw * 18.0 + Vector3.UP * 3.0)
		cc.current = true
		await _w(0.1)
		await main.shot(v[1])
	get_tree().quit()
