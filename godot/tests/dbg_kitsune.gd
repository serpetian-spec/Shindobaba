extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var n = SFProps.accessory_node("kitsune")
	var ab = SFProps._bounds(n)
	print("KIT aabb=", ab)
	var pts = SFProps._points(n)
	var zs = []
	for p in pts:
		if absf(p.x) < 0.02 and absf(p.y) < 0.03:
			zs.append(snappedf(p.z, 0.002))
	zs.sort()
	print("KIT center z samples=", zs.slice(0, 6), " ... ", zs.slice(maxi(0, zs.size() - 6)))
	var edge = []
	for p in pts:
		if absf(p.x) > ab.size.x * 0.42:
			edge.append(snappedf(p.z, 0.002))
	edge.sort()
	print("KIT edge z=", edge.slice(0, 4), " ... ", edge.slice(maxi(0, edge.size() - 4)))
	var nose = -1.0
	var nz = 0.0
	for p in pts:
		if absf(p.x) < 0.015 and p.y < 0.0 and p.y > -0.08:
			if p.z > nz:
				nz = p.z; nose = p.y
	print("KIT max z near center-low=", nz, " at y=", nose)
	var front_n = 0; var back_n = 0
	for p in pts:
		if p.z > 0.02: front_n += 1
		if p.z < -0.03: back_n += 1
	print("KIT z>0.02 count=", front_n, " z<-0.03 count=", back_n)
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup({"gender": "m", "hair_style": "diken", "face_style": "kitsune"})
	print("KIT eye=", m.eye_center_model, " hc=", m._head_center())
	var hb = m.skel.get_bone_global_rest(m.skel.find_bone("Head"))
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "VFace":
			print("KIT vface global aabb center (model)=", (m.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()).get_center())
	get_tree().quit()
