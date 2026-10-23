class_name SFModels
extends RefCounted
## Sketchfab'dan indirilen hayran yapımı modeller (assets/sketchfab, git'e girmez).
## Varsa kullanılır, yoksa prosedürel model devreye girer. Malzemeler oyunun sert cel gölgesine çevrilir (doku korunur).
## yaw: modelin ön yüzünü -Z'ye çeviren dönüş (derece); fit: "h" yüksekliğe, "len" uzunluğa göre ölçek
## hide: gizlenecek düğüm adı parçaları (zemin plakası, alakasız aksesuar)

const DEFS := {
	"kurama": {"file": "kurama_calfan", "yaw": 180.0, "fit": "h", "surface": 0, "mul": 1.7},
	"shukaku": {"file": "shukaku", "yaw": 180.0, "fit": "h", "surface": 1, "mul": 1.3},
	"toad_boss": {"file": "battle_toad", "yaw": 180.0, "fit": "h", "surface": 1, "drop_flat": true},
	"toad_mid": {"file": "naruto_frog", "yaw": 180.0, "fit": "h", "surface": 1, "tint": Color(0.92, 0.55, 0.2)},
	"snake_boss": {"file": "aoda", "yaw": 180.0, "fit": "len", "surface": 1, "tint": Color(0.5, 0.36, 0.68)},
	"slug_queen": {"file": "slug_arion", "yaw": 180.0, "fit": "len", "surface": 3, "tint": Color(0.86, 0.92, 1.0), "luma": true},
	"monkey_king": {"file": "monkey_king", "yaw": 180.0, "fit": "h", "surface": 1},
	"snake_giant": {"file": "cobra_anim", "yaw": 180.0, "fit": "len", "surface": 1, "mul": 1.0},
	"weasel_trio": {"file": "mink_lowpoly_anim", "yaw": 180.0, "fit": "len", "surface": 0},
	"crow_flock": {"file": "crow", "yaw": 180.0, "fit": "len", "surface": 0},
}


static func path_for(key: String) -> String:
	if not DEFS.has(key):
		return ""
	var f = DEFS[key]["file"]
	var p = "res://assets/sketchfab/%s/%s.glb" % [f, f]
	return p if ResourceLoader.exists(p) else ""


static func _aabb(n: Node3D, xf_root: Transform3D) -> AABB:
	var ab = AABB(); var first = true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible:
			continue
		var xf = xf_root
		var chain = []
		var c: Node = mi
		while c != n and c != null:
			chain.push_front(c)
			c = c.get_parent()
		for k in chain:
			xf = xf * (k as Node3D).transform
		var a = xf * mi.get_aabb()
		ab = a if first else ab.merge(a)
		first = false
	return ab


## Modeli kurar: dönen düğüm yerel uzayda tabanı y=0'da, ortası x/z=0'da, ön yüzü -Z'de, hedef boyutta.
## Dönüş: {"node": Node3D, "player": AnimationPlayer|null, "anims": [ad...]} ya da boş sözlük
static func build(key: String, size: float) -> Dictionary:
	var p = path_for(key)
	if p == "":
		return {}
	var d: Dictionary = DEFS[key]
	var inst: Node3D = (load(p) as PackedScene).instantiate()
	var holder = Node3D.new()
	holder.name = "SF_" + key
	holder.add_child(inst)
	for h in d.get("hide", []):
		for c in inst.find_children("*" + h + "*", "Node3D", true, false):
			c.visible = false
	if d.get("drop_flat", false):  # zemin plakasını at
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = mi.get_aabb()
			if a.size.y < maxf(a.size.x, a.size.z) * 0.15:
				mi.visible = false
	inst.rotation.y = deg_to_rad(float(d.get("yaw", 0.0)))
	var ab = _aabb(inst, inst.transform)
	var ref = ab.size.y if d.get("fit", "h") == "h" else maxf(ab.size.x, ab.size.z)
	var k = size / maxf(ref, 0.0001) * float(d.get("mul", 1.0))
	inst.scale = Vector3.ONE * k
	ab = _aabb(inst, inst.transform)
	inst.position = Vector3(-ab.get_center().x, -ab.position.y, -ab.get_center().z)
	_convert_materials(inst, int(d.get("surface", 0)), d.get("tint", null), d.get("luma", false))
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var names = []
	if ap:
		names = Array(ap.get_animation_list())
		for nm in names:
			ap.get_animation(nm).loop_mode = Animation.LOOP_LINEAR
		if not names.is_empty():
			ap.play(names[0])
	return {"node": holder, "player": ap, "anims": names, "size": ab.size}


## StandardMaterial -> sert cel canavar malzemesi (doku + renk korunur)
static func _convert_materials(n: Node, surface: int, tint, luma := false) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for si in mi.mesh.get_surface_count():
			var sm = mi.get_active_material(si)
			var m = ShaderMaterial.new()
			m.shader = load("res://shaders/beast.gdshader")
			m.set_shader_parameter("surface", surface)
			m.set_shader_parameter("stroke", 0.2)
			m.set_shader_parameter("shadow_tint", Color(0.32, 0.26, 0.42))
			m.set_shader_parameter("use_tint", true)
			var col = Color.WHITE
			if sm is BaseMaterial3D:
				col = sm.albedo_color
				if sm.albedo_texture:
					m.set_shader_parameter("use_tex", true)
					m.set_shader_parameter("tex", sm.albedo_texture)
					col = sm.albedo_color
			if tint != null:
				col = tint if (luma or not (sm is BaseMaterial3D and sm.albedo_texture)) else Color(tint).lerp(Color.WHITE, 0.4)
			m.set_shader_parameter("tex_luma", luma)
			m.set_shader_parameter("tint", col)
			mi.set_surface_override_material(si, m)
