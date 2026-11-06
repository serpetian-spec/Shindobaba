class_name TrainingDummy
extends Node3D
## Antrenman kuklası: hasar alır, sallanır, devrilir ve geri kalkar.

var team = "dummy"
var radius = 0.45
var height = 1.9
var hp = 120.0
var max_hp = 120.0
var dead = false
var vis: Node3D


func _ready() -> void:
	add_to_group("fighters")
	# arazi yüksekliği; yükseltilmiş zeminde (teras, avlu döşemesi) verilen yükseklik korunur
	var g = Game.ground_height(global_position.x, global_position.z)
	if not has_meta("exam_target") or global_position.y < g:
		global_position.y = g
	vis = Node3D.new()
	add_child(vis)
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.95, 0), Vector3(0.28, 1.9, 0.28), Color(0.45, 0.32, 0.2), Vector3.ZERO, 8)
	b.add("cyl", Vector3(0, 1.2, 0), Vector3(0.75, 0.8, 0.6), Color(0.85, 0.75, 0.5), Vector3.ZERO, 10)
	b.add("box", Vector3(0, 1.3, 0), Vector3(1.4, 0.14, 0.18), Color(0.45, 0.32, 0.2))
	b.add("sphere", Vector3(0, 1.85, 0), Vector3(0.45, 0.45, 0.45), Color(0.85, 0.75, 0.5), Vector3.ZERO, 10)
	b.add("box", Vector3(0, 1.25, 0.31), Vector3(0.3, 0.3, 0.02), Color(0.8, 0.15, 0.15))
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	vis.add_child(mi)
	var sb = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = 0.35
	sh.height = 1.9
	cs.shape = sh
	cs.position.y = 0.95
	sb.add_child(cs)
	add_child(sb)


func is_dead() -> bool:
	return dead


func face_dir() -> Vector3:
	return -global_transform.basis.z


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	if has_meta("drill_throw") and not info.has("tool"):
		Combat.popup_text(global_position + Vector3.UP * 1.2, "Yalnız atış! [R]", Color(1, 0.8, 0.4))
		return
	if has_meta("throw_only"):
		# atış hedefi: yalnız kunai/shuriken; tek isabet yeter
		if not info.has("tool"):
			Combat.popup_text(global_position + Vector3.UP * 2.2, "Yalnız atış! [R]", Color(1, 0.8, 0.4))
			return
		info = info.duplicate()
		info["dmg"] = hp + 1.0
	var dmg: float = info.get("dmg", 5.0)
	hp -= dmg
	Combat.damage_number(global_position + Vector3.UP * 2.3, dmg, Color(1, 0.9, 0.3) if info.get("kind", "") != "heavy" else Color(1, 0.55, 0.2))
	var d: Vector3 = info.get("dir", Vector3.FORWARD)
	var axis = Vector3.UP.cross(d).normalized()
	if axis.length() < 0.1:
		axis = Vector3.RIGHT
	vis.transform.basis = Basis(axis, 0.35 if info.get("kind", "") != "heavy" else 0.6)
	var tw = vis.create_tween()
	tw.tween_property(vis, "transform:basis", Basis.IDENTITY, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Progress.on_dummy_hit(self, dmg)
	if hp <= 0.0:
		dead = true
		var tw2 = vis.create_tween()
		tw2.tween_property(vis, "transform:basis", Basis(axis, PI * 0.47), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw2.tween_interval(4.0)
		tw2.tween_callback(func():
			hp = max_hp
			dead = false
			vis.transform.basis = Basis.IDENTITY
			FX.smoke_puff(global_position + Vector3.UP, 0.7, 8))
		Progress.on_dummy_broken(self)


func apply_status(_n: String, _d: float) -> void:
	pass
