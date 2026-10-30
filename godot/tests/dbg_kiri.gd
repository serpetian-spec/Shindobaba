extends Node
## Kiri chūnin kıyafetleri (Kage cübbesi çıkmamalı)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var cam = get_viewport().get_camera_3d()
	var fw = -cam.global_transform.basis.z
	fw.y = 0
	fw = fw.normalized()
	var side = fw.cross(Vector3.UP)
	for k in 8:
		var a = Enemy.archetype("kiri", k + 3)
		a["respawn"] = false
		var e = Enemy.new()
		e.setup(a)
		e.team = "player"
		get_tree().current_scene.add_child(e)
		var q = pl.global_position + fw * 7.0 + side * (k - 3.5) * 1.5
		q.y = Game.ground_height(q.x, q.z)
		e.global_position = q
		e.home = q
		e.set_physics_process(false)
		e.look_at(pl.global_position, Vector3.UP, true)
	await get_tree().create_timer(1.5).timeout
	await main.shot("kiri_row")
	get_tree().quit()
