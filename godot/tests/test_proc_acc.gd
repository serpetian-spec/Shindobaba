extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 300))
	base.y = Game.terrain_height(base.x, base.z)
	var looks = [{"face_style": "kitsune"}, {"face_style": "tengu"}, {"face_style": "oni"}, {"back_item": "kabak"}, {"back_item": "sake"}, {"head_style": "kage"}, {"head_style": "kasa"}, {"face_style": "anbu_kedi"}]
	for i in looks.size():
		var lk = {"gender": "m", "hair_style": "kısa", "top_style": "uzun", "band": null}
		lk.merge(looks[i], true)
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(lk)
		var p = base + Vector3((i - 3.5) * 0.85, 0, 0)
		p.y = Game.terrain_height(p.x, p.z)
		m.global_position = p
		m.rotation.y = PI if i != 3 else PI * 0.25
		m.play("idle")
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = base + Vector3(0, 1.5, 3.4)
	cam.look_at(base + Vector3(0, 1.25, 0))
	await get_tree().create_timer(1.5).timeout
	await main.shot("acc_on")
	get_tree().quit()
