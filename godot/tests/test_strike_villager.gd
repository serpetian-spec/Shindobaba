extends Node
## Köylüye doğrudan vuruş = suç (aranma puanı, kişi savaşçıya döner, muhafızlar)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(4.0).timeout
	Hud.close_dialog()
	var pl = main.player
	var best = null
	var bd = 1e9
	for v in get_tree().get_nodes_in_group("talkers"):
		if v is Node3D and v.visible and not v.interior and Crime.attack_option(v).size() > 0:
			var d = v.global_position.distance_to(pl.global_position)
			if d < bd:
				bd = d
				best = v
	print("VUR köylü bulundu: ", best != null, " mesafe=%.0f" % bd)
	if best:
		pl.global_position = best.global_position + Vector3(1.2, 0, 0)
		await get_tree().create_timer(0.3).timeout
		var h0 = Crime.heat()
		Combat.hit_sphere(pl, best.global_position + Vector3.UP * 1.0, 0.9, {"dmg": 10.0, "melee": true})
		await get_tree().create_timer(0.5).timeout
		print("VUR aranma %d -> %d, köylü dönüştü=%s" % [h0, Crime.heat(), not is_instance_valid(best) or best.is_queued_for_deletion()])
	get_tree().quit()
