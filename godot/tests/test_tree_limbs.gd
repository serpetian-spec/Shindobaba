extends Node
## Ağaç dalları çarpışır: vahşi ağaç havuzunda dal kapsülleri, köyde Builder.tree_limbs; yukarıdan ışın dala çarpar
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	var pl = main.player
	var v = Game.village("konoha")
	var pos = Game.from_map(Vector2(v["x"] + float(v["r"]) + 300, v["y"] + 200))
	pl.respawn(pos)
	await get_tree().create_timer(5.0).timeout
	var veg = get_tree().current_scene.find_child("Vegetation", true, false)
	if veg == null:
		for n in get_tree().current_scene.get_children():
			if n.get("bodies") != null and n.get("body_tree") != null:
				veg = n
	print("LIMB bitki düğümü: ", veg != null)
	var on = 0
	var hit_ok = 0
	var tried = 0
	var space = pl.get_world_3d().direct_space_state
	for sb in veg.bodies:
		if sb.position.y < -1000.0:
			continue
		for ch in sb.get_children():
			if ch.has_meta("limb") and not ch.disabled:
				on += 1
				if tried < 12:
					tried += 1
					var c: Vector3 = ch.global_position
					var q = PhysicsRayQueryParameters3D.create(c + Vector3.UP * 3.0, c + Vector3.DOWN * 0.5)
					var h = space.intersect_ray(q)
					if not h.is_empty() and h["collider"] == sb:
						hit_ok += 1
	print("LIMB açık dal kapsülü=%d  ışın dala çarptı %d/%d" % [on, hit_ok, tried])
	get_tree().quit()
