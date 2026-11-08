extends Node
## Shichūka evi: kapı boşluğundan geçilir, duvar katıdır (ışın testi) + iyileşme alanı içeride
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "senju", "element": "doton", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.facing = 0.0
	var f = pl.face_dir()
	PathJutsu.cast_path(pl, "mokuton_shichuka", null)
	await _w(1.0)
	var at = pl.global_position + f * 6.0
	var g = Game.ground_height(at.x, at.z)
	var space = pl.get_world_3d().direct_space_state
	var side = f.cross(Vector3.UP).normalized()
	for test in [["door", Vector3.ZERO], ["wall", side * 2.2]]:
		var a = pl.global_position + test[1] + Vector3(0, g - pl.global_position.y + 1.2, 0)
		var b = at + test[1] + Vector3(0, g - at.y + 1.2, 0)
		var q = PhysicsRayQueryParameters3D.create(a, b)
		q.exclude = [pl.get_rid()]
		var r = space.intersect_ray(q)
		print("DOOR %s blocked=%s" % [test[0], not r.is_empty()])
	get_tree().quit()
