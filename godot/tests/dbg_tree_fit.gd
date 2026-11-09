extends SceneTree
## Ağaç türü başına: çarpışma gövdesi (radii, yükseklik) vs görüntü mesh'inin gövde yarıçapı/yüksekliği
func _init() -> void:
	var V = load("res://scripts/world/vegetation.gd")
	var P = load("res://scripts/world/props.gd")
	for t in [0, 1, 2, 4, 5, 9, 11]:
		var m: ArrayMesh = P.vegetation_mesh(t, 0)
		var vs: PackedVector3Array = m.get_faces()
		var r2 = 0.0; var top = 0.0
		for q in vs:
			top = maxf(top, q.y)
			if q.y > 1.0 and q.y < 2.5:
				r2 = maxf(r2, Vector2(q.x, q.z).length())
		print("TREE t=", t, " visual_trunk_r@1-2.5m=", snappedf(r2, 0.01), " top=", snappedf(top, 0.1), " limbs=", m.has_meta("limbs"))
	quit()
