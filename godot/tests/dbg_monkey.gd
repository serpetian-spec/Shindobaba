extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var base = Vector3(0, 3000, 0)
	var parts = SummonModels.build("monkey_king", 2.1, 1.0)
	var mk: Node3D = parts["root"]
	main.add_child(mk)
	mk.global_position = base
	var ab = AABB()
	for mi in mk.find_children("*", "VisualInstance3D", true, false):
		var a = mi.global_transform * mi.get_aabb()
		ab = a if ab.size == Vector3.ZERO else ab.merge(a)
	print("MONKEY keys=", parts.keys(), " aabb=", ab, " anim=", parts.get("anim"))
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = base + Vector3(0, 1.2, 5)
	cam.look_at(base + Vector3(0, 1.0, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	await main.shot("mk")
	get_tree().quit()
