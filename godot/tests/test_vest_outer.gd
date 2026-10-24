extends Node
## Yelek + dış giysi (haori, palto, pelerin, org pelerini): yelek dışarı taşmasın
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 300))
	base.y = Game.terrain_height(base.x, base.z)
	var outs = ["haori", "palto", "pelerin", "org_pelerin", "haori_uzun"]
	for i in outs.size():
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "m", "hair_style": "kısa", "top_style": "uzun", "vest": Color(0.3, 0.42, 0.25), "outer_style": outs[i], "outer": Color(0.9, 0.9, 0.88)})
		var p = base + Vector3((i - 2) * 0.9, 0, 0)
		p.y = Game.terrain_height(p.x, p.z)
		m.global_position = p
		m.rotation.y = PI
		m.play("idle")
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = base + Vector3(0, 1.3, 3.6)
	cam.look_at(base + Vector3(0, 1.0, 0))
	await get_tree().create_timer(1.5).timeout
	await main.shot("vo_on")
	cam.global_position = base + Vector3(2.4, 1.3, 2.6)
	cam.look_at(base + Vector3(0, 1.0, 0))
	await get_tree().create_timer(0.3).timeout
	await main.shot("vo_yan")
	get_tree().quit()
