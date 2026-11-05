extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var cj = ClanJutsu.new()
	add_child(cj)
	var mi = MeshInstance3D.new()
	mi.mesh = cj._kidaichu_mesh(0).build(Props.toon())
	get_tree().current_scene.add_child(mi)
	mi.global_position = Vector3(0, 2000, 0)
	var sun = DirectionalLight3D.new()
	get_tree().current_scene.add_child(sun)
	sun.rotation_degrees = Vector3(-50, 30, 0)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 35
	for k in 2:
		cc.global_position = mi.global_position + (Vector3(1.4, 0.7, -1.2) if k == 0 else Vector3(-1.6, 0.4, 0.3))
		cc.look_at(mi.global_position)
		cc.current = true
		await get_tree().create_timer(0.3).timeout
		await main.shot("bug_%d" % k)
	get_tree().quit()
