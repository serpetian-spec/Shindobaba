extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.5).timeout
	Hud.visible = false
	main.player.visible = false
	main.player.set_physics_process(false)
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.current = true
	cam.fov = 40
	var base: Vector3 = main.player.global_position + Vector3(0, 0, -6)
	var i = 0
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var lk = CharacterModel.default_look()
		lk.merge({"gender": "m", "hair_style": "s2", "hair": Color(0.3, 0.2, 0.1), "band": Color(0.2, 0.2, 0.3), "band_style": "head", "village": vid, "age": "adult"}, true)
		Outfits.village_set(lk, vid, false)
		var m = CharacterModel.new()
		get_tree().current_scene.add_child(m)
		m.setup(lk)
		m.global_position = Vector3(base.x + (i - 2) * 1.3, Game.terrain_height(base.x, base.z), base.z)
		i += 1
	await get_tree().create_timer(1.0).timeout
	cam.global_position = Vector3(base.x, Game.terrain_height(base.x, base.z) + 1.2, base.z + 6.5)
	cam.look_at(Vector3(base.x, Game.terrain_height(base.x, base.z) + 1.0, base.z), Vector3.UP)
	await get_tree().create_timer(0.3).timeout
	await main.shot("vset_front")
	cam.global_position = Vector3(base.x, Game.terrain_height(base.x, base.z) + 1.2, base.z - 6.5)
	cam.look_at(Vector3(base.x, Game.terrain_height(base.x, base.z) + 1.0, base.z), Vector3.UP)
	await get_tree().create_timer(0.3).timeout
	await main.shot("vset_back")
	get_tree().quit()
