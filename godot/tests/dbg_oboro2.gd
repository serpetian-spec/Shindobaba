extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "gekko", "element": "fuuton", "hair_style": "uzun", "hair": Color(0.45, 0.3, 0.55), "top": Color(0.3, 0.35, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	var wm = CharacterModel.weapon_mesh("katana")
	Jutsu.execute(pl, "oborozukiyo", null)
	for i in 8:
		await get_tree().create_timer(0.06).timeout
		var n = 0
		var info = ""
		for c in get_tree().current_scene.get_children():
			if c is MeshInstance3D and c.has_meta("oboro_sword"):
				n += 1
				if info == "":
					info = "pos_dy=%.2f tr=%.2f sc=%.2f" % [c.global_position.y - pl.global_position.y, c.transparency, c.global_transform.basis.get_scale().x]
		print("OB t=%.2f swords=%d %s pl_y=%.2f" % [i * 0.06, n, info, pl.global_position.y])
	get_tree().quit()
