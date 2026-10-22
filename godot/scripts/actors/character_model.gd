class_name CharacterModel
extends Node3D
## İskeletli, animasyonlu ninja modeli. Görünüm sözlükle tanımlanır (look):
## gender, skin, hair, hair_style, eye, top, top2, pants, vest, band (renk), band_style, village, wraps, sandal, cloak, mask

const ANIM := {
	"idle": "a/Idle", "walk": "a/Walk", "jog": "a/Jog_Fwd", "run": "a/Sprint", "jump": "b/NinjaJump_Start",
	"air": "b/NinjaJump_Idle", "land": "b/NinjaJump_Land", "roll": "a/Roll", "jab": "a/Punch_Jab",
	"cross": "a/Punch_Cross", "hook": "b/Melee_Hook", "slash_a": "b/Sword_Regular_A", "slash_b": "b/Sword_Regular_B",
	"slash_c": "b/Sword_Regular_C", "throw": "b/OverhandThrow", "cast_in": "a/Spell_Simple_Enter",
	"cast": "a/Spell_Simple_Idle", "cast_out": "a/Spell_Simple_Shoot", "hit": "a/Hit_Chest", "hit_head": "a/Hit_Head",
	"knock": "b/Hit_Knockback", "death": "a/Death01", "getup": "b/LayToIdle", "slide": "b/Slide",
	"block": "b/Sword_Block", "crouch": "a/Crouch_Idle", "sit": "a/Sitting_Idle", "swim": "a/Swim_Fwd",
	"swim_idle": "a/Swim_Idle", "talk": "a/Idle_Talking", "push": "a/Push", "fold": "b/Idle_FoldArms",
	"eat": "b/Consume", "interact": "a/Interact", "dance": "a/Dance", "yes": "b/Yes", "no": "b/Idle_No",
	"pickup": "a/PickUp_Table", "fall": "b/NinjaJump_Idle", "sword_idle": "a/Sword_Idle", "dash": "b/Slide_Start",
}
const LOOPS := ["idle", "walk", "jog", "run", "air", "cast", "crouch", "sit", "swim", "swim_idle", "talk", "fold", "dance", "block", "sword_idle", "fall"]

static var _libs = {}

var look = {}
var skel: Skeleton3D
var anim: AnimationPlayer
var body_mesh: MeshInstance3D
var eyes_mesh: MeshInstance3D
var brows_mesh: MeshInstance3D
var eye_mat: ShaderMaterial
var outfit := {}
var overlay: PoseOverlay
var current = ""
var materials: Array[ShaderMaterial] = []
var eye_mats: Array[StandardMaterial3D] = []
var hit_flash = 0.0


static func default_look() -> Dictionary:
	return {
		"gender": "m", "skin": Color(0.96, 0.8, 0.66), "hair": Color(0.3, 0.2, 0.12), "hair_style": "diken",
		"eye": Color(0.25, 0.45, 0.8), "top": Color(0.15, 0.2, 0.33), "top2": Color(0.25, 0.35, 0.5),
		"pants": Color(0.18, 0.2, 0.25), "vest": null, "band": Color(0.15, 0.22, 0.55), "band_style": "head",
		"village": "konoha", "wraps": Color(0.92, 0.92, 0.9), "sandal": Color(0.15, 0.2, 0.32), "cloak": null,
		"mask": null, "sleeves": true, "age": "adult",
	}


func setup(l: Dictionary) -> void:
	look = default_look()
	look.merge(l, true)
	var src: PackedScene = load("res://assets/chars/Superhero_Female_FullBody.gltf" if look["gender"] == "f" else "res://assets/chars/Superhero_Male_FullBody.gltf")
	var inst = src.instantiate()
	add_child(inst)
	var old_ap = inst.find_child("AnimationPlayer", true, false)
	if old_ap:
		old_ap.queue_free()
	skel = inst.find_child("GeneralSkeleton", true, false)
	for c in skel.get_children():
		if c is MeshInstance3D:
			if String(c.name).to_lower().begins_with("superhero"):
				body_mesh = c
			elif c.name == "Eyes":
				eyes_mesh = c
			elif c.name == "Eyebrows":
				brows_mesh = c
	inst.rotation.y = PI  # model +Z'ye bakıyor, biz -Z ileri kullanıyoruz
	outfit = _outfit_for_look()
	_paint_body()
	_equip_outfit()
	_attachments()
	anim = AnimationPlayer.new()
	anim.name = "Anim"
	inst.add_child(anim)
	anim.root_node = NodePath("..")
	_add_libs()
	overlay = PoseOverlay.new()
	skel.add_child(overlay)
	apply_age(look.get("age", "adult"))
	play("idle", 0.0)


func _add_libs() -> void:
	if _libs.is_empty():
		for pair in [["a", "res://assets/anim/ual1.glb"], ["b", "res://assets/anim/ual2.glb"]]:
			var s: Node = (load(pair[1]) as PackedScene).instantiate()
			var ap: AnimationPlayer = s.find_child("AnimationPlayer", true, false)
			var lib: AnimationLibrary = ap.get_animation_library("")
			_libs[pair[0]] = lib
			s.free()
		for key in LOOPS:
			var full: String = ANIM[key]
			var lib: AnimationLibrary = _libs[full.substr(0, 1)]
			var nm = full.substr(2)
			if lib.has_animation(nm):
				lib.get_animation(nm).loop_mode = Animation.LOOP_LINEAR
	for k in _libs:
		anim.add_animation_library(k, _libs[k])


## Animasyon oynat (aynı animasyon tekrar istenirse yeniden başlatmaz, restart=true hariç)
func play(key: String, blend := 0.15, speed := 1.0, restart := false) -> void:
	var full: String = ANIM.get(key, key)
	if not anim.has_animation(full):
		return
	if current == key and not restart and anim.is_playing():
		anim.speed_scale = speed
		return
	current = key
	anim.play(full, blend, 1.0)
	anim.speed_scale = speed
	if restart:
		anim.seek(0.0, true)


const AGES := {"child": [0.76, 1.1, 0.9], "teen": [0.84, 1.05, 0.94], "young": [0.92, 1.02, 0.97], "adult": [1.0, 1.0, 1.0]}
var age_scale = 1.0


## Yaşa göre boy, kafa oranı ve omuz genişliği
func apply_age(age: String) -> void:
	var a: Array = AGES.get(age, AGES["adult"])
	age_scale = a[0]
	scale = Vector3.ONE * age_scale
	overlay.head_scale = a[1]
	overlay.chest_scale = a[2]


func anim_length(key: String) -> float:
	var full: String = ANIM.get(key, key)
	return anim.get_animation(full).length if anim.has_animation(full) else 0.5


func anim_progress() -> float:
	if anim.current_animation == "":
		return 1.0
	return anim.current_animation_position / maxf(0.01, anim.current_animation_length)


# ------------------------------------------------------------------ boyama + kumaş katmanı
## Bölge kodları: 0 ten, 10 omuz/üst kol, 11 göğüs, 12 bel, 13 ön kol, 14 bilek sargısı,
## 20 kalça, 21 uyluk, 22 baldır, 23 baldır sargısı, 30 sandalet, 40 boyun
static var _geo := {}      # cinsiyet -> {arrays, regions, adj, per, tex}
static var _body_cache := {}
static var _shell_cache := {}


func _geo_for(gender: String) -> Dictionary:
	if _geo.has(gender):
		return _geo[gender]
	var mesh: ArrayMesh = body_mesh.mesh
	var skin: Skin = body_mesh.skin
	var bind_names = {}
	if skin:
		for i in skin.get_bind_count():
			var nm = skin.get_bind_name(i)
			if nm == &"":
				nm = skel.get_bone_name(skin.get_bind_bone(i))
			bind_names[i] = String(nm)
	var arr = mesh.surface_get_arrays(0)
	for k in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_TEX_UV2]:
		arr[k] = null
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bones = arr[Mesh.ARRAY_BONES]
	var weights = arr[Mesh.ARRAY_WEIGHTS]
	var per = 4
	if bones != null and v.size() > 0:
		per = bones.size() / v.size()
	var regions = PackedInt32Array()
	regions.resize(v.size())
	for i in v.size():
		var bn = ""
		if bones != null:
			var best = -1.0
			for k in per:
				var w: float = weights[i * per + k]
				if w > best:
					best = w
					bn = bind_names.get(bones[i * per + k], "")
		regions[i] = _region_code(bn, v[i])
	# komşuluk (pürüzsüzleştirme için)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var adj: Array = []
	adj.resize(v.size())
	for i in v.size():
		adj[i] = PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var a = idx[t]; var b = idx[t + 1]; var c = idx[t + 2]
		adj[a].append(b); adj[a].append(c)
		adj[b].append(a); adj[b].append(c)
		adj[c].append(a); adj[c].append(b)
	var src_tex = null
	var src_mat = mesh.surface_get_material(0)
	if src_mat is BaseMaterial3D:
		src_tex = src_mat.albedo_texture
	var g = {"arrays": arr, "regions": regions, "adj": adj, "per": per, "tex": src_tex}
	_geo[gender] = g
	return g


static func _region_code(bn: String, p: Vector3) -> int:
	if bn.contains("Head") or bn == "":
		return 0
	if bn.contains("Neck"):
		return 40
	if bn.contains("Hand") or bn.contains("Thumb") or bn.contains("Index") or bn.contains("Middle") or bn.contains("Ring") or bn.contains("Little") or bn.contains("leaf"):
		return 0
	if bn.contains("LowerArm"):
		return 14 if absf(p.x) > 0.55 else 13
	if bn.contains("UpperArm") or bn.contains("Shoulder"):
		return 10
	if bn.contains("Chest"):
		return 11
	if bn == "Spine":
		return 12
	if bn.contains("Hips"):
		return 12 if p.y > 1.0 else 20
	if bn.contains("UpperLeg"):
		return 21
	if bn.contains("LowerLeg"):
		return 23 if p.y < 0.3 else 22
	if bn.contains("Toes"):
		return 0
	if bn.contains("Foot"):
		return 30
	return 12


## Giyilen parçaların altında kalan vücut bölgeleri (görünmez yapılır, içinden vücut sızmasın)
func _hidden_codes() -> Array:
	var h = []
	if outfit.get("body", "") != "":
		h.append_array([10, 11, 12, 20])
	if outfit.get("arms", "") != "":
		h.append_array([10, 13, 14])
	if outfit.get("legs", "") != "":
		h.append_array([20, 21, 22])
	if outfit.get("feet", "") != "":
		h.append_array([22, 23, 30])
	return h


func _outfit_for_look() -> Dictionary:
	var L = look
	if L.has("outfit") and L["outfit"] is Dictionary:
		return L["outfit"]
	var o = {"body": "Peasant", "arms": "Peasant" if L["sleeves"] else "", "legs": "Peasant", "feet": "Peasant", "hood": false, "pauldron": false}
	if L["vest"] != null:
		o["body"] = "Ranger"
		o["arms"] = "Peasant"  # yelek altı uzun kollu ninja tişörtü
	if L.get("band_style", "") == "slashed" and L.get("mask", null) == null:
		o["hood"] = randf() < 0.5
	return o


func _paint_body() -> void:
	var g = _geo_for(look["gender"])
	var hidden = _hidden_codes()
	var key = "%s|%s" % [look["gender"], str(hidden)]
	if not _body_cache.has(key):
		var arr: Array = (g["arrays"] as Array).duplicate()
		var regions: PackedInt32Array = g["regions"]
		var cols = PackedColorArray()
		cols.resize(regions.size())
		for i in regions.size():
			cols[i] = Color(1, 1, 1, 1.0 if regions[i] in hidden else 0.0)
		arr[Mesh.ARRAY_COLOR] = cols
		var m = ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if g["per"] == 8 else 0)
		_body_cache[key] = m
	body_mesh.mesh = _body_cache[key]
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.5)
	mat.set_shader_parameter("spec_amount", 0.12)
	mat.set_shader_parameter("cloth_mode", true)
	mat.set_shader_parameter("hide_masked", true)
	if g["tex"]:
		mat.set_shader_parameter("tex", g["tex"])
	mat.set_shader_parameter("tint", Color(look["skin"]))
	body_mesh.set_surface_override_material(0, mat)
	materials.append(mat)


## Quaternius modüler kıyafet parçalarını bizim iskelete giydirir, her parçayı kendi rengine boyar
func _equip_outfit() -> void:
	var gp = "Female" if look["gender"] == "f" else "Male"
	var L = look
	var parts = []
	if outfit.get("body", "") != "":
		parts.append(["%s_%s_Body" % [gp, outfit["body"]], L["vest"] if outfit["body"] == "Ranger" and L["vest"] != null else L["top"]])
	if outfit.get("arms", "") != "":
		parts.append(["%s_%s_Arms" % [gp, outfit["arms"]], L["top"]])
	if outfit.get("legs", "") != "":
		parts.append(["%s_%s_Legs" % [gp, outfit["legs"]], L["pants"]])
	if outfit.get("feet", "") != "":
		var fname = "%s_%s_Feet" % [gp, outfit["feet"]]
		if gp == "Male" and outfit["feet"] == "Ranger":
			fname = "Male_Ranger_Feet_Boots"
		parts.append([fname, L["sandal"]])
	if outfit.get("hood", false):
		parts.append(["%s_Ranger_Head_Hood" % gp, Color(L["top"]).darkened(0.35)])
	if outfit.get("pauldron", false):
		parts.append(["Female_Ranger_Acc_Pauldrons" if gp == "Female" else "Male_Ranger_Acc_Pauldron", Color(0.45, 0.47, 0.5)])
	for p in parts:
		var path = "res://assets/outfits/%s.gltf" % p[0]
		if not ResourceLoader.exists(path):
			continue
		var inst = (load(path) as PackedScene).instantiate()
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var src_mat = mi.mesh.surface_get_material(0)
			mi.get_parent().remove_child(mi)
			mi.owner = null
			skel.add_child(mi)
			mi.skeleton = mi.get_path_to(skel)
			var m = ShaderMaterial.new()
			m.shader = load("res://shaders/toon.gdshader")
			m.set_shader_parameter("use_vertex_color", false)
			m.set_shader_parameter("luma_tint", true)
			var tint: Color = p[1]
			if String(mi.name).contains("Belt"):
				tint = Color(0.3, 0.22, 0.15)
			m.set_shader_parameter("tint", tint)
			m.set_shader_parameter("rim_amount", 0.4)
			if src_mat is BaseMaterial3D and src_mat.albedo_texture:
				m.set_shader_parameter("tex", src_mat.albedo_texture)
			mi.material_override = m
			materials.append(m)
		inst.free()


# ------------------------------------------------------------------ eklentiler (saç, bant, göz, çanta)
func _attach(bone: String, model_xf: Transform3D) -> BoneAttachment3D:
	var ba = BoneAttachment3D.new()
	ba.bone_name = bone
	skel.add_child(ba)
	var holder = Node3D.new()
	ba.add_child(holder)
	var bi = skel.find_bone(bone)
	var rest = skel.get_bone_global_rest(bi)
	holder.transform = rest.affine_inverse() * model_xf
	return ba


func _mesh_on(bone: String, mesh: Mesh, model_xf: Transform3D) -> MeshInstance3D:
	var ba = _attach(bone, model_xf)
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	ba.get_child(0).add_child(mi)
	return mi


func _head_center() -> Vector3:
	if eyes_mesh:
		var ab: AABB = eyes_mesh.get_aabb()
		return ab.get_center() + Vector3(0, 0.05, -0.075)
	return skel.get_bone_global_rest(skel.find_bone("Head")).origin + Vector3(0, 0.1, 0)


const HAIR_FILES := {
	"diken": ["Hair_SimpleParted", true], "kısa": ["Hair_Buzzed", false], "uzun": ["Hair_Long", false],
	"atkuyruğu": ["Hair_Buns", false], "kase": ["Hair_SimpleParted", false], "dağınık": ["Hair_SimpleParted", true],
}


func _attachments() -> void:
	var hc = _head_center()
	var female: bool = look["gender"] == "f"
	var hair_col: Color = look["hair"]
	# --- gözler (klan rengi) ve kaşlar
	if eyes_mesh:
		eye_mat = ShaderMaterial.new()
		eye_mat.shader = load("res://shaders/toon.gdshader")
		eye_mat.set_shader_parameter("eye_mode", true)
		eye_mat.set_shader_parameter("use_vertex_color", false)
		eye_mat.set_shader_parameter("rim_amount", 0.0)
		var em = eyes_mesh.mesh.surface_get_material(0)
		if em is BaseMaterial3D:
			eye_mat.set_shader_parameter("tex", em.albedo_texture)
		eye_mat.set_shader_parameter("eye_color", look["eye"])
		eyes_mesh.material_override = eye_mat
	var hair_mat = ShaderMaterial.new()
	hair_mat.shader = load("res://shaders/toon.gdshader")
	hair_mat.set_shader_parameter("luma_tint", true)
	hair_mat.set_shader_parameter("use_vertex_color", false)
	hair_mat.set_shader_parameter("tint", hair_col)
	hair_mat.set_shader_parameter("rim_amount", 0.6)
	hair_mat.set_shader_parameter("spec_amount", 0.35)
	hair_mat.set_shader_parameter("tex", load("res://assets/chars/T_Hair_1_BaseColor.png"))
	materials.append(hair_mat)
	if brows_mesh:
		brows_mesh.material_override = hair_mat
	# --- saç modeli (model uzayında kafada konumlu) + anime dikenleri
	var hf: Array = HAIR_FILES.get(look["hair_style"], HAIR_FILES["kase"])
	var file: String = hf[0]
	if female and file == "Hair_Buzzed":
		file = "Hair_BuzzedFemale"
	var hs: PackedScene = load("res://assets/chars/hair/%s.gltf" % file)
	if hs:
		var hn = hs.instantiate()
		var ba = _attach("Head", Transform3D.IDENTITY)
		ba.get_child(0).add_child(hn)
		for mi in hn.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = hair_mat
	if hf[1]:
		var b = MB.new()
		_hair_mesh(b, look["hair_style"], 1.0)
		var sp = _mesh_on("Head", b.build(hair_mat), Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.82), hc + Vector3(0, -0.005, 0)))
		sp.material_override = hair_mat
	# --- alın koruyucu
	if look["band"] != null and look["band_style"] != "none":
		var band = MB.new()
		var bc: Color = look["band"]
		if look["band_style"] == "neck":
			band.add("torus", Vector3.ZERO, Vector3(0.24, 0.24, 0.24), bc, Vector3.ZERO, 16)
			_mesh_on("Neck", band.build(Props.toon()), Transform3D(Basis.IDENTITY, skel.get_bone_global_rest(skel.find_bone("Neck")).origin + Vector3(0, 0.03, 0)))
		else:
			band.add("cyl", Vector3.ZERO, Vector3(0.205, 0.04, 0.228), bc, Vector3.ZERO, 18)
			band.add("box", Vector3(0, 0, 0.111), Vector3(0.088, 0.04, 0.01), Color(0.8, 0.82, 0.86))
			band.add("box", Vector3(-0.012, -0.03, -0.12), Vector3(0.026, 0.11, 0.008), bc, Vector3(-25, 0, 8))
			band.add("box", Vector3(0.012, -0.03, -0.12), Vector3(0.026, 0.11, 0.008), bc, Vector3(-25, 0, -10))
			_mesh_on("Head", band.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, 0.025, 0)))
			var q = QuadMesh.new()
			q.size = Vector2(0.08, 0.034)
			var sm = StandardMaterial3D.new()
			sm.albedo_texture = symbol_texture(look["village"], look["band_style"] == "slashed")
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			q.material = sm
			_mesh_on("Head", q, Transform3D(Basis.IDENTITY, hc + Vector3(0, 0.025, 0.117)))
	# --- yelek: kumaş katmanına boyanır; üstüne sadece yaka + parşömen cepleri
	if look["vest"] != null:
		var v = MB.new()
		var vc: Color = look["vest"]
		var ch = skel.get_bone_global_rest(skel.find_bone("UpperChest")).origin
		v.add("torus", Vector3(0, 0.15, -0.005), Vector3(0.3, 0.3, 0.28), vc.darkened(0.1), Vector3.ZERO, 14)
		for sx in [-1.0, 1.0]:
			for k in 2:
				v.add("box", Vector3(0.075 * sx, -0.06 - k * 0.09, 0.135), Vector3(0.07, 0.08, 0.035), vc.darkened(0.15))
		_mesh_on("UpperChest", v.build(Props.toon()), Transform3D(Basis.IDENTITY, ch))
	# --- çanta + kunai kılıfı
	var hip = skel.get_bone_global_rest(skel.find_bone("Hips")).origin
	var pouch = MB.new()
	pouch.add("box", Vector3.ZERO, Vector3(0.14, 0.09, 0.07), Color(0.42, 0.33, 0.22))
	_mesh_on("Hips", pouch.build(Props.toon()), Transform3D(Basis.IDENTITY, hip + Vector3(0.0, 0.02, -0.14)))
	var th = skel.get_bone_global_rest(skel.find_bone("RightUpperLeg")).origin
	var holster = MB.new()
	holster.add("box", Vector3.ZERO, Vector3(0.05, 0.12, 0.1), Color(0.12, 0.12, 0.14))
	holster.add("box", Vector3(0, 0.07, 0), Vector3(0.06, 0.02, 0.11), Color(0.85, 0.85, 0.85))
	_mesh_on("RightUpperLeg", holster.build(Props.toon()), Transform3D(Basis.IDENTITY, th + Vector3(-0.11, -0.16, 0.0)))
	# --- pelerin (Akatsuki tarzı)
	if look["cloak"] != null:
		var c = MB.new()
		var cc: Color = look["cloak"]
		var ch = skel.get_bone_global_rest(skel.find_bone("UpperChest")).origin
		c.add("cyl", Vector3(0, -0.45, 0), Vector3(0.5, 1.05, 0.38), cc, Vector3.ZERO, 12)
		c.add("cyl", Vector3(0, 0.1, 0), Vector3(0.34, 0.2, 0.32), cc, Vector3.ZERO, 10)
		for pp in [Vector3(-0.12, -0.2, 0.18), Vector3(0.14, -0.6, 0.18), Vector3(0.05, -0.1, -0.19), Vector3(-0.1, -0.7, -0.18)]:
			c.add("sphere", pp, Vector3(0.12, 0.07, 0.02), Color(0.75, 0.1, 0.12), Vector3.ZERO, 6)
		_mesh_on("UpperChest", c.build(Props.toon()), Transform3D(Basis.IDENTITY, ch))
	if look["mask"] == "anbu":
		var m = MB.new()
		m.add("sphere", Vector3.ZERO, Vector3(0.19, 0.24, 0.1), Color(0.95, 0.95, 0.95), Vector3.ZERO, 10)
		m.add("box", Vector3(0.04, 0.0, 0.05), Vector3(0.012, 0.09, 0.005), Color(0.75, 0.1, 0.1), Vector3(0, 0, 30))
		_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, -0.03, 0.08)))
	elif look["mask"] == "cloth":
		var m = MB.new()
		m.add("box", Vector3.ZERO, Vector3(0.2, 0.09, 0.2), Color(0.15, 0.15, 0.2))
		_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, -0.075, 0.02)))


func _hair_mesh(b: MB, style: String, _hs: float) -> void:
	var c = Color.WHITE  # renk materyalden gelir
	# taban: kafatasını saran kapak
	b.add("hemi", Vector3(0, 0.03, -0.01), Vector3(0.235, 0.28, 0.255), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, -0.02, -0.04), Vector3(0.23, 0.2, 0.22), c, Vector3.ZERO, 12)
	match style:
		"diken":
			var spikes = [[0, 25, 0.14], [30, 40, 0.13], [-30, 40, 0.13], [70, 55, 0.12], [-70, 55, 0.12], [120, 60, 0.13],
				[-120, 60, 0.13], [180, 55, 0.15], [150, 35, 0.12], [-150, 35, 0.12], [0, 70, 0.12], [90, 20, 0.1], [-90, 20, 0.1]]
			for s in spikes:
				var yaw = deg_to_rad(s[0]); var pitch = deg_to_rad(s[1])
				var dir = Vector3(sin(yaw) * sin(pitch), cos(pitch), cos(yaw) * sin(pitch))
				var basis = Basis(Quaternion(Vector3.UP, dir))
				b.add_xf("cone", Transform3D(basis.scaled(Vector3(0.07, s[2], 0.07)), Vector3(0, 0.05, -0.01) + dir * 0.13), c, 6)
			for sx in [-1.0, 1.0]:  # favoriler / perçem
				b.add_xf("cone", Transform3D(Basis(Vector3.RIGHT, PI * 0.95).rotated(Vector3.FORWARD, 0.25 * sx).scaled(Vector3(0.05, 0.1, 0.04)), Vector3(0.1 * sx, -0.04, 0.07)), c, 5)
			b.add_xf("cone", Transform3D(Basis(Vector3.RIGHT, PI * 0.8).scaled(Vector3(0.06, 0.09, 0.04)), Vector3(0.03, 0.08, 0.11)), c, 5)
		"kısa":
			b.add("sphere", Vector3(0, 0.07, 0.0), Vector3(0.25, 0.18, 0.27), c, Vector3.ZERO, 12)
		"uzun":
			b.add("box", Vector3(0, -0.2, -0.1), Vector3(0.24, 0.42, 0.08), c, Vector3(8, 0, 0))
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(0.11 * sx, -0.12, 0.02), Vector3(0.04, 0.3, 0.12), c)
		"atkuyruğu":
			b.add("sphere", Vector3(0, 0.1, -0.15), Vector3(0.08, 0.08, 0.08), c, Vector3.ZERO, 6)
			b.add("cone", Vector3(0, 0.0, -0.22), Vector3(0.09, 0.28, 0.09), c, Vector3(-150, 0, 0), 6)
		"kase":
			b.add("cyl", Vector3(0, 0.02, 0.0), Vector3(0.265, 0.17, 0.275), c, Vector3.ZERO, 16)
		"dağınık":
			for i in 14:
				var yaw = randf() * TAU; var pitch = randf_range(0.2, 1.3)
				var dir = Vector3(sin(yaw) * sin(pitch), cos(pitch), cos(yaw) * sin(pitch))
				b.add_xf("cone", Transform3D(Basis(Quaternion(Vector3.UP, dir)).scaled(Vector3(0.06, 0.09, 0.06)), Vector3(0, 0.05, -0.01) + dir * 0.12), c, 5)


func _eye_texture(iris: Color, right: bool) -> ImageTexture:
	var w = 48; var h = 32
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var u = (x - w * 0.5) / (w * 0.5); var v = (y - h * 0.5) / (h * 0.5)
			var e = u * u + v * v * 1.25
			if e < 1.0:
				var col = Color(0.98, 0.98, 1.0)
				var ix = u * 1.6 - (0.1 if right else -0.1); var iy = v * 1.2 + 0.05
				var ir = ix * ix + iy * iy
				if ir < 0.55:
					col = iris.darkened(0.25 + (0.2 if iy < -0.2 else 0.0)).lerp(iris.lightened(0.25), clampf(iy + 0.5, 0, 1) * 0.6)
				if ir < 0.13:
					col = Color(0.05, 0.03, 0.05)
				if (ix + 0.25) * (ix + 0.25) + (iy + 0.3) * (iy + 0.3) < 0.03:
					col = Color(1, 1, 1)
				if v < -0.55:
					col = Color(0.08, 0.05, 0.06)  # üst kirpik
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func symbol_texture(village: String, slashed := false) -> ImageTexture:
	var w = 64; var h = 28
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink = Color(0.15, 0.15, 0.18)
	for y in h:
		for x in w:
			var u = (x - w * 0.5) / (h * 0.5); var v = (y - h * 0.5) / (h * 0.5)
			var on = false
			match village:
				"konoha":  # sarmal + üçgen yaprak
					var r = sqrt(u * u + v * v); var a = atan2(v, u)
					var sp = fmod(r * 6.0 - a / TAU * 2.0 + 10.0, 2.0)
					on = (r < 0.7 and sp < 0.55) or (u > 0.45 and u < 1.1 and absf(v + (u - 0.45) * 0.9 - 0.1) < 0.12)
				"suna":  # kum saati
					on = absf(absf(v) * 0.8 - absf(u)) < 0.12 and absf(v) < 0.75 or absf(absf(v) - 0.75) < 0.1 and absf(u) < 0.6
				"kiri":  # dört dalga çizgisi
					for i in 4:
						if absf(u - (-0.75 + i * 0.5) - sin(v * 2.0) * 0.12) < 0.08 and absf(v) < 0.75:
							on = true
				"kumo":  # bulut
					on = Vector2(u + 0.35, v).length() < 0.35 or Vector2(u - 0.35, v).length() < 0.35 or Vector2(u, v + 0.25).length() < 0.4
					on = on and not (Vector2(u + 0.35, v).length() < 0.22 or Vector2(u - 0.35, v).length() < 0.22)
				"iwa":  # iki kaya
					on = (absf(u + 0.3) + absf(v) * 0.6 < 0.4) or (absf(u - 0.35) + absf(v - 0.1) * 0.6 < 0.35)
				"oto":  # nota
					on = (Vector2(u + 0.2, v - 0.4).length() < 0.25) or (absf(u - 0.03) < 0.07 and v < 0.4 and v > -0.8)
				_:  # yağmur: dört dikey çizgi
					for i in 4:
						if absf(u - (-0.6 + i * 0.4)) < 0.06 and absf(v) < 0.7:
							on = true
			if slashed and absf(v + u * 0.45) < 0.09:
				on = true
			if on:
				img.set_pixel(x, y, ink)
	return ImageTexture.create_from_image(img)


func set_eye_color(c: Color) -> void:
	if eye_mat:
		eye_mat.set_shader_parameter("eye_color", c)


func flash(amount: float) -> void:
	hit_flash = maxf(hit_flash, amount)


func _process(dt: float) -> void:
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - dt * 5.0)
		for m in materials:
			m.set_shader_parameter("hit_flash", hit_flash)
