extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var holder = Node3D.new()
	get_tree().current_scene.add_child(holder)
	holder.position = Vector3(0, -500, 0)
	var arches = ["genin", "chunin", "jonin", "rogue", "bandit", "samurai", "traveler", "merchant", "farmer", "monk", "elder", "medic", "noble", "worker", "sennin", "kid", "student", "anbu"]
	var t0 = Time.get_ticks_usec()
	var n = 0
	for rep in 3:
		var tr = Time.get_ticks_usec()
		for a in arches:
			for gd in ["m", "f"]:
				var lk = CharacterModel.default_look()
				lk["gender"] = gd
				lk.merge(Outfits.roll(a, ["konoha", "suna", "kiri", "kumo", "iwa"][n % 5]), true)
				lk["gender"] = gd
				var cm = CharacterModel.new()
				holder.add_child(cm)
				cm.setup(lk)
				cm.free()
				n += 1
		print("PREWARM rep %d: %.0fms" % [rep, (Time.get_ticks_usec() - tr) / 1000.0])
	print("PREWARM total %d models %.0fms" % [n, (Time.get_ticks_usec() - t0) / 1000.0])
	get_tree().quit()
