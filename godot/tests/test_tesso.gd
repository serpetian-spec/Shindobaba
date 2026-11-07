extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "none", "element": "fuuton", "hair_style": "uzun", "hair": Color(0.3, 0.2, 0.1), "top": Color(0.85, 0.82, 0.75), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
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
	await _w(0.5)
	cc.global_position = pl.global_position + rt * 7.0 + fw * 7.0 + Vector3.UP * 2.0
	cc.look_at(pl.global_position + fw * 7.0 + Vector3.UP * 1.6)
	cc.current = true
	await _w(0.05)
	await main.shot("kamatari2")
	get_tree().quit()
	pl.cam.current = true
	await _w(2.0)
	Jutsu.execute(pl, "tesso_kusari", null)
	await _w(0.5)
	var pj = _find(get_tree().root)
	var m = MeshInstance3D.new()
	m.mesh = pj._mcache["tesso_claw"]
	get_tree().current_scene.add_child(m)
	m.global_position = pl.global_position + fw * 3.0 + Vector3.UP * 1.5
	m.look_at(m.global_position + fw + rt * 0.0)
	m.scale = Vector3.ONE * 2.0
	cc.global_position = m.global_position + rt * 1.6 - fw * 0.8 + Vector3.UP * 0.6
	cc.look_at(m.global_position)
	cc.current = true
	await _w(0.1)
	await main.shot("tesso")
	cc.global_position = m.global_position + fw * 2.0 + Vector3.UP * 0.2
	cc.look_at(m.global_position)
	await _w(0.1)
	await main.shot("tesso_f")
	get_tree().quit()

func _find(n: Node) -> Node:
	if n.has_method("p_tesso_kusari"):
		return n
	for ch in n.get_children():
		var r = _find(ch)
		if r:
			return r
	return null
