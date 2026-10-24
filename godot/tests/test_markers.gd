extends Node
## Etkileşim/kapı işaretleri: yerden ne kadar yukarıda? (tepede görünen giriş hatası)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var space = main.player.get_world_3d().direct_space_state
	var n = 0
	for it in Interact.items:
		var p: Vector3 = it["pos"]
		var gh = Game.ground_height(p.x, p.z)
		var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, p.y + 80.0, p.z), Vector3(p.x, gh - 2.0, p.z), 1))
		var top = float(hit["position"].y) if not hit.is_empty() else gh
		# zeminden çok yukarıda ya da üstünde çatı/blok varken çok aşağıda olanlar
		if p.y - gh > 4.0 or (top - p.y > 4.0 and String(it.get("kind", "")) == "enter"):
			n += 1
			print("MARK %s '%s' y-ground=%.1f roof_above=%.1f pos=%s" % [it.get("kind", ""), it.get("label", ""), p.y - gh, top - p.y, p])
	print("MARK total=%d" % n)
	get_tree().quit()
