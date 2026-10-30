extends Node
## Yelek + dış giysi: önü açık giysilerde yelek açıklıktan görünür, taşmaz
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	pl.set_process(false)
	var cam = get_viewport().get_camera_3d()
	var base = pl.global_position + Vector3(40, 0, 40)
	var styles = ["haori", "palto", "jinbaori", "pelerin"]
	var vs = []
	for k in styles.size():
		var v = Villager.new()
		v.role = "guard"
		v.look_extra = {"vest": Color(0.3, 0.42, 0.28), "vest_style": 1, "outer_style": styles[k], "outer": Color(0.85, 0.82, 0.75), "top": Color(0.15, 0.18, 0.3), "top_style": "uzun"}
		main.actors.add_child(v)
		var p = base + Vector3(k * 1.4, 0, 0)
		p.y = Game.ground_height(p.x, p.z)
		v.global_position = p
		v.set_physics_process(false)
		v.set_process(false)
		vs.append(v)
	await get_tree().create_timer(0.6).timeout
	for v in vs:
		v.model.play("idle", 0.0)
		v.model.rotation.y = 0.0
	await get_tree().create_timer(0.4).timeout
	var mid = base + Vector3(2.1, 1.25, 0)
	mid.y = Game.ground_height(mid.x, mid.z) + 1.25
	for ang in [0.0, 35.0]:
		var dir = Vector3(sin(deg_to_rad(ang)), 0.05, -cos(deg_to_rad(ang))).normalized()
		cam.global_position = mid + dir * 4.2
		cam.look_at(mid, Vector3.UP)
		await get_tree().process_frame
		await get_tree().process_frame
		await main.shot("vest_%d" % int(ang))
	get_tree().quit()
