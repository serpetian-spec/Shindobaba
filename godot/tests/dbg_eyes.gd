extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var i = 0
	for g in ["m", "f"]:
		for ec in [Color(0.25, 0.45, 0.8), Color(0.2, 0.2, 0.2)]:
			var m = CharacterModel.new()
			get_tree().current_scene.add_child(m)
			m.global_position = Vector3(i * 3.0, 2000, 0)
			m.setup({"gender": g, "hair_style": "uzun" if g == "f" else "diken", "hair": Color(0.8, 0.8, 0.85), "eye": ec, "skin": Color(0.96, 0.8, 0.66), "age": "teen"})
			m.play("idle")
			await get_tree().create_timer(0.8).timeout
			var hp = m.eye_center_model if m.get("eye_center_model") != null else Vector3(0, 1.45, 0)
			var c = m.global_transform * hp
			cc.global_position = c + Vector3(0, 0.06, -0.45)
			cc.look_at(c + Vector3(0, 0.05, 0))
			cc.fov = 30
			cc.current = true
			await get_tree().create_timer(0.2).timeout
			await main.shot("eye_%s_%d" % [g, i])
			m.queue_free()
			i += 1
	get_tree().quit()
