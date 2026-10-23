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
var overlay: PoseOverlay
var cloth_shell_mat: ShaderMaterial
var head_ab := AABB()
var current = ""
var materials: Array[ShaderMaterial] = []
var eye_mats: Array[StandardMaterial3D] = []
var hit_flash = 0.0


## VRoid: iskelet uzayında yüz -Z; tüm prosedürel kod +Z ön kabul ediyor -> 180° çevrilmiş "model uzayı"
const VROID_SCALE := 1.1
const TOE_PITCH := 0.0
const FOOT_PITCH_F := 0.0
## VRoid glb'lerinin kök kemiği 180° çevrildi (model +Z ön); ek dönüşüm gerekmiyor
static var FLIP := Transform3D.IDENTITY
const FACE_DONORS_M := ["masc_vroid", "AvatarSample_C", "HairSample_Male", "Sakurada_Fumiriya"]
const FACE_DONORS_F := ["fem_vroid", "AvatarSample_A", "AvatarSample_B", "Sendagaya_Shibu", "Darkness_Shibu", "HairSample_Female"]
## saç stili -> [VRoid modeli, mesh adı] (saç kafaya sabitlenir, renk oyuncunun saç rengi)
const HAIR_DONORS := {
	"kısa": ["Sakurada_Fumiriya", "Hair001", ""], "diken": ["masc_vroid", "Body", "diken"], "dağınık": ["HairSample_Male", "Hair001", "dağınık"],
	"kase": ["Sendagaya_Shibu", "Hair001", ""], "uzun": ["AvatarSample_B", "Hair001", ""], "atkuyruğu": ["fem_vroid", "Body", "atkuyruğu"],
	"kisa_kakul": ["AvatarSample_A", "Hair001", ""], "kakul": ["Darkness_Shibu", "Hair001", "kakul"], "geriye": ["masc_vroid", "Body", "geriye"],
	"ananas": ["masc_vroid", "Body", "ananas"], "topuz": ["fem_vroid", "Body", "topuz"], "ikiz_topuz": ["fem_vroid", "Body", "ikiz_topuz"],
	"yele": ["AvatarSample_C", "Hair001", "yele"], "orgu": ["AvatarSample_A", "Hair001", "orgu"], "mohikan": ["masc_vroid", "Body", "mohikan"],
	"kirpik": ["masc_vroid", "Body", "kirpik"], "kel": ["", "", ""],
}
const VROID_SKIN := Color(0.99, 0.89, 0.82)  # VRoid doku ten rengi (oyuncu teni bununla oranlanır)
static var _scenes := {}
static var _donor_cache := {}
var face_mi: MeshInstance3D
var head_fix := Transform3D.IDENTITY
var eye_center_model := Vector3(0, 1.62, 0.08)


static var _inv_mat: StandardMaterial3D
static func _invisible_mat() -> StandardMaterial3D:
	if _inv_mat == null:
		_inv_mat = StandardMaterial3D.new()
		_inv_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_inv_mat.albedo_color = Color(0, 0, 0, 0)
	return _inv_mat


static var _part_mats := {}
## Yüz parçası malzemesi (göz beyazı/ağız: alfa kesme; kirpik/vurgu: saydam), ışıksız anime
static func _face_part_mat(src: BaseMaterial3D, mname: String) -> StandardMaterial3D:
	var key = src.get_instance_id()
	if _part_mats.has(key):
		return (_part_mats[key] as StandardMaterial3D).duplicate()
	var m = StandardMaterial3D.new()
	m.albedo_texture = src.albedo_texture
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_BACK
	if mname.contains("EyeHighlight") or mname.contains("Eyelash") or mname.contains("Eyeline") or mname.contains("FaceBrow"):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.render_priority = 2 if mname.contains("EyeHighlight") else 1
	else:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	_part_mats[key] = m
	return m.duplicate()


static func _scene(n: String) -> PackedScene:
	if not _scenes.has(n):
		_scenes[n] = load("res://assets/vrm/%s.glb" % n)
	return _scenes[n]


## Kemiğin dinlenme dönüşümü, +Z-ön model uzayında
func _grest(bi: int) -> Transform3D:
	return FLIP * skel.get_bone_global_rest(bi)


func _skin_ratio() -> Color:
	var sk: Color = look["skin"]
	return Color(clampf(sk.r / VROID_SKIN.r, 0.2, 1.3), clampf(sk.g / VROID_SKIN.g, 0.2, 1.3), clampf(sk.b / VROID_SKIN.b, 0.2, 1.3))


## Bir VRoid modelinin bir mesh'ini kafa kemiği uzayına sabitleyip malzemeye göre birleştirir
var skull_c := Vector3(0, 1.63, 0)
var skull_r := Vector3(0.1, 0.105, 0.105)
static var _skull_cache := {}
var band_ring: Array = []   # alın yüksekliğinde kafa çevresi [açı -> yarıçap]


## Kafa derisinden kafatası elipsoidi ve alın bandı halkası
func _measure_skull(m: ArrayMesh, xf: Transform3D) -> void:
	var pts = PackedVector3Array()
	for si in m.get_surface_count():
		var vv: PackedVector3Array = m.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
		for q in vv:
			pts.append(xf * q)
	if pts.size() < 50:
		return
	var ey = eye_center_model.y
	var top = -1e9; var back = 1e9; var front = -1e9; var half_w = 0.0
	for q in pts:
		top = maxf(top, q.y)
		if q.y > ey - 0.02:
			back = minf(back, q.z); front = maxf(front, q.z)
			half_w = maxf(half_w, absf(q.x))
	skull_c = Vector3(0, (top + ey) * 0.5 - 0.01, (back + front) * 0.5)
	skull_r = Vector3(half_w * 0.98, (top - ey) * 0.5 + 0.04, (front - back) * 0.5)
	# bant halkası: alın yüksekliğinde 24 yönde en dış deri
	var by = ey + 0.052
	var bins = 24
	var rad = PackedFloat32Array()
	rad.resize(bins)
	for q in pts:
		if absf(q.y - by) > 0.014:
			continue
		var d = Vector2(q.x - skull_c.x, q.z - skull_c.z)
		var k = int(floor((atan2(d.y, d.x) + PI) / TAU * bins)) % bins
		rad[k] = maxf(rad[k], d.length())
	for it in 4:
		for k in bins:
			if rad[k] <= 0.0:
				rad[k] = maxf(rad[(k + 1) % bins], rad[(k + bins - 1) % bins])
	band_ring = [by, rad]


## Alın bandı: kafayı saran ince şerit (önü hafif aşağı eğik) + alında metal plaka
func _band_mesh(col: Color) -> Array:
	var by: float = band_ring[0]
	var rad: PackedFloat32Array = band_ring[1]
	var bins = rad.size()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h = 0.034
	var ring = []
	for k in bins + 1:
		var kk = k % bins
		var a = (float(kk) + 0.5) / bins * TAU - PI
		var dir = Vector3(cos(a), 0, sin(a))
		var r = rad[kk] + 0.007
		var tilt = -0.012 * maxf(0.0, dir.z)  # önde hafif aşağı
		var p = Vector3(skull_c.x, by + tilt, skull_c.z) + dir * r
		ring.append([p, dir])
	for k in bins:
		var A = ring[k]; var B = ring[k + 1]
		var a0: Vector3 = A[0]; var b0: Vector3 = B[0]
		var quad = [a0 - Vector3(0, h * 0.5, 0), b0 - Vector3(0, h * 0.5, 0), b0 + Vector3(0, h * 0.5, 0), a0 - Vector3(0, h * 0.5, 0), b0 + Vector3(0, h * 0.5, 0), a0 + Vector3(0, h * 0.5, 0)]
		var ns = [A[1], B[1], B[1], A[1], B[1], A[1]]
		for i in 6:
			st.set_color(col)
			st.set_normal(ns[i])
			st.add_vertex(quad[i])
	st.generate_tangents()
	var mesh = st.commit()
	# ön: +Z yönündeki yarıçap
	var kf = int(floor((atan2(1.0, 0.0) + PI) / TAU * bins)) % bins
	var fz = skull_c.z + rad[kf] + 0.011
	return [mesh, Vector3(skull_c.x, by - 0.012, fz)]


static func _donor_part(donor: String, mesh_name: String, mat_filter := "") -> Dictionary:
	var key = "%s|%s|%s" % [donor, mesh_name, mat_filter]
	if _donor_cache.has(key):
		return _donor_cache[key]
	var out = {}
	var inst: Node = _scene(donor).instantiate()
	var sk: Skeleton3D = inst.find_child("GeneralSkeleton", true, false)
	var mi: MeshInstance3D = sk.get_node_or_null(mesh_name) if sk else null
	if mi == null or mi.skin == null:
		inst.free()
		_donor_cache[key] = out
		return out
	# bağışçının özgün kafa kemiği uzayı (bind): tüm VRoid modellerinde aynı çerçeve
	var skin: Skin = mi.skin
	var hb := Transform3D.IDENTITY
	for i in skin.get_bind_count():
		var nm = String(skin.get_bind_name(i))
		if nm == "":
			nm = String(sk.get_bone_name(skin.get_bind_bone(i)))
		if nm == "Head":
			hb = skin.get_bind_pose(i)
			break
	var groups = {}
	var mesh: Mesh = mi.mesh
	for si in mesh.get_surface_count():
		var mat: Material = mesh.surface_get_material(si)
		var mname = mat.resource_name if mat else ""
		if mat_filter != "" and not mname.contains(mat_filter):
			continue
		var arr = mesh.surface_get_arrays(si)
		if not groups.has(mname):
			groups[mname] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(), "i": PackedInt32Array(), "mat": mat}
		var gr = groups[mname]
		var base = gr["v"].size()
		var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var uu = arr[Mesh.ARRAY_TEX_UV]
		for k in vv.size():
			gr["v"].append(hb * vv[k])
			gr["n"].append((hb.basis * nn[k]).normalized())
			gr["uv"].append(uu[k] if uu != null else Vector2.ZERO)
		var ii = arr[Mesh.ARRAY_INDEX]
		if ii == null:
			for k in vv.size():
				gr["i"].append(base + k)
		else:
			for k in ii:
				gr["i"].append(base + k)
	var am = ArrayMesh.new()
	var mats = []
	var aabb := AABB()
	var first = true
	var iris := AABB()
	for mname in groups:
		var gr = groups[mname]
		var a = []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = gr["v"]
		a[Mesh.ARRAY_NORMAL] = gr["n"]
		a[Mesh.ARRAY_TEX_UV] = gr["uv"]
		a[Mesh.ARRAY_INDEX] = gr["i"]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		mats.append(gr["mat"])
		for q in gr["v"]:
			if first:
				aabb = AABB(q, Vector3.ZERO); first = false
			else:
				aabb = aabb.expand(q)
		if String(mname).contains("EyeIris"):
			iris = AABB(gr["v"][0], Vector3.ZERO)
			for q in gr["v"]:
				iris = iris.expand(q)
	inst.free()
	out = {"mesh": am, "mats": mats, "aabb": aabb, "iris": iris}
	_donor_cache[key] = out
	return out


## Yüz (VRoid) + saç (VRoid) kafaya; göz malzemesi dōjutsu desteğiyle
func _face_and_hair() -> void:
	var female = look["gender"] == "f"
	var donors: Array = FACE_DONORS_F if female else FACE_DONORS_M
	var fi = int(look.get("face_id", -1))
	if fi < 0:
		var f = look.get("face")
		var h = hash(str(f)) if f != null else randi()
		fi = absi(h) % donors.size()
		look["face_id"] = fi
	var donor = donors[fi % donors.size()]
	if not female and look.get("age", "adult") in ["child", "teen"]:
		donor = ["HairSample_Male", "Sakurada_Fumiriya"][fi % 2]
	var fd = _donor_part(donor, "Face")
	var head_bi = skel.find_bone("Head")
	var head_rest = _grest(head_bi)
	# bağışçı kafa-yerel -> bizim gövdenin özgün kafa konumu (gövde bağları düzeltilmiş dinlenmeye göre)
	var r180 = Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3.ZERO)
	var g0 = Transform3D.IDENTITY
	var bskin: Skin = body_mesh.skin if body_mesh else null
	if bskin:
		for i in bskin.get_bind_count():
			if String(bskin.get_bind_name(i)) == "Head":
				g0 = bskin.get_bind_pose(i).affine_inverse()
				break
	head_fix = head_rest.affine_inverse() * r180 * g0
	var place = head_rest * head_fix
	if not fd.is_empty():
		var holder = _attach("Head", head_rest).get_child(0)
		face_mi = MeshInstance3D.new()
		face_mi.name = "VFace"
		face_mi.mesh = fd["mesh"]
		face_mi.transform = head_fix
		holder.add_child(face_mi)
		eyes_mesh = face_mi
		var ratio = _skin_ratio()
		for si in fd["mats"].size():
			var mat: Material = fd["mats"][si]
			var mname = mat.resource_name if mat else ""
			var tex = mat.albedo_texture if mat is BaseMaterial3D else null
			if mname.contains("EyeIris"):
				eye_mat = ShaderMaterial.new()
				eye_mat.shader = load("res://shaders/vroid_eye.gdshader")
				eye_mat.set_shader_parameter("tex", tex)
				eye_mat.set_shader_parameter("eye_color", look["eye"])
				face_mi.set_surface_override_material(si, eye_mat)
				materials.append(eye_mat)
			elif mname.contains("SKIN"):
				var sm = ShaderMaterial.new()
				sm.shader = load("res://shaders/vroid_toon.gdshader")
				sm.set_shader_parameter("tex", tex)
				sm.set_shader_parameter("tint", ratio)
				face_mi.set_surface_override_material(si, sm)
				materials.append(sm)
			elif mname.contains("EyeExtra"):
				face_mi.set_surface_override_material(si, _invisible_mat())
			elif mat is BaseMaterial3D:
				# VRoid MToon kesme/saydamlık: göz beyazı, ağız, kirpik vb. alfa ile kesilmeli
				var cm = _face_part_mat(mat, mname)
				if mname.contains("FaceBrow"):
					cm.albedo_color = Color(look["hair"]).lerp(Color(0.1, 0.08, 0.08), 0.4)
				face_mi.set_surface_override_material(si, cm)
		var ir: AABB = fd["iris"]
		var ic = ir.get_center() if ir.size != Vector3.ZERO else fd["aabb"].get_center()
		eye_center_model = place * ic
		var fa: AABB = fd["aabb"]
		head_ab = AABB(place * fa.position, Vector3.ZERO).expand(place * fa.end)
		head_ab = head_ab.abs()
		var sk_key = "%s|%s|%s" % [look["gender"], donor, look.get("age", "adult")]
		if _skull_cache.has(sk_key):
			var sc = _skull_cache[sk_key]
			skull_c = sc[0]; skull_r = sc[1]; band_ring = sc[2]
		else:
			_measure_skull(fd["mesh"], place)
			_skull_cache[sk_key] = [skull_c, skull_r, band_ring]
	# saç: VRoid saç mesh'i + gerekirse prosedürel tutam eklentisi (diken, topuz, at kuyruğu...)
	var hd: Array = HAIR_DONORS.get(look.get("hair_style", "diken"), HAIR_DONORS["diken"])
	if hd.size() > 2 and hd[2] != "" and head_ab.size.x > 0.05:
		var hk = "vroid|%s" % hd[2]
		if not _hair_cache.has(hk):
			_hair_cache[hk] = _hair_clumps(hd[2], skull_c, skull_r)
		var cm = ShaderMaterial.new()
		cm.shader = load("res://shaders/toon.gdshader")
		cm.set_shader_parameter("tint", look["hair"])
		cm.set_shader_parameter("rim_amount", 0.45)
		materials.append(cm)
		var cl = _mesh_on("Head", _hair_cache[hk], Transform3D.IDENTITY)
		cl.material_override = cm
	if hd[0] != "":
		var hp = _donor_part(hd[0], hd[1], "HAIR")
		if not hp.is_empty():
			var holder2 = _attach("Head", head_rest).get_child(0)
			var hair_mi = MeshInstance3D.new()
			hair_mi.name = "VHair"
			hair_mi.mesh = hp["mesh"]
			hair_mi.transform = head_fix
			holder2.add_child(hair_mi)
			for si in hp["mats"].size():
				var mat: Material = hp["mats"][si]
				var hm = ShaderMaterial.new()
				hm.shader = load("res://shaders/vroid_toon.gdshader")
				hm.set_shader_parameter("tex", mat.albedo_texture if mat is BaseMaterial3D else null)
				hm.set_shader_parameter("mode", 1)
				hm.set_shader_parameter("use_alpha", true)
				hm.set_shader_parameter("tint", look["hair"])
				hm.set_shader_parameter("rim_amount", 0.5)
				hair_mi.set_surface_override_material(si, hm)
				materials.append(hm)


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
	if look.get("face_style") == null and look.get("mask") != null:
		look["face_style"] = {"anbu": "anbu_kedi", "cloth": "cloth"}.get(look["mask"], null)
	if look.get("outer_style") == null and look.get("cloak") != null:
		look["outer_style"] = "pelerin"
		look["outer"] = look["cloak"]
	# anime taban gövde (VRoid): yüz ve saç başka VRoid modellerinden kafaya takılır
	var src: PackedScene = _scene("fem_vroid" if look["gender"] == "f" else "masc_vroid")
	var inst = src.instantiate()
	add_child(inst)
	var old_ap = inst.find_child("AnimationPlayer", true, false)
	if old_ap:
		old_ap.queue_free()
	skel = inst.find_child("GeneralSkeleton", true, false)
	body_mesh = skel.get_node_or_null("Body")
	var base_face = skel.get_node_or_null("Face")
	if base_face:
		base_face.queue_free()
	var sec = inst.get_node_or_null("secondary")
	if sec:
		sec.queue_free()
	inst.scale = Vector3.ONE * VROID_SCALE  # VRoid ~1.6 m -> ~1.78 m
	inst.rotation.y = PI  # VRoid kökü +Z'ye çevrildi (glb); biz -Z ileri kullanıyoruz
	_face_and_hair()
	_paint_body()
	_cloth_details()
	_attachments()
	_accessories()
	anim = AnimationPlayer.new()
	anim.name = "Anim"
	inst.add_child(anim)
	anim.root_node = NodePath("..")
	_add_libs()
	overlay = PoseOverlay.new()
	skel.add_child(overlay)
	apply_age(look.get("age", "adult"))
	stance = _stance_for_look()
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
		for k2 in _libs:
			var lib2: AnimationLibrary = _libs[k2]
			for an in lib2.get_animation_list():
				var A: Animation = lib2.get_animation(an)
				for ti in range(A.get_track_count() - 1, -1, -1):
					var tp = String(A.track_get_path(ti))
					if tp.ends_with(":LeftToes") or tp.ends_with(":RightToes"):
						A.remove_track(ti)
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


## [boy, kafa, göğüs genişliği, uzuv kalınlığı, bacak boyu]
const AGES := {"child": [0.78, 1.2, 0.84, 0.82, 1.0], "teen": [0.87, 1.09, 0.91, 0.9, 1.0], "young": [0.94, 1.03, 0.97, 0.96, 1.0], "adult": [1.0, 1.0, 1.0, 1.0, 1.0]}
var age_scale = 1.0


## Yaşa göre boy, kafa oranı ve omuz genişliği
func apply_age(age: String) -> void:
	var a: Array = AGES.get(age, AGES["adult"])
	age_scale = a[0]
	scale = Vector3.ONE * age_scale
	overlay.head_scale = a[1]
	overlay.chest_scale = a[2]
	overlay.limb_scale = a[3]
	overlay.leg_len = a[4]
	overlay.toe_pitch = TOE_PITCH
	overlay.foot_pitch = FOOT_PITCH_F if look["gender"] == "f" else 0.0



func anim_length(key: String) -> float:
	var full: String = ANIM.get(key, key)
	return anim.get_animation(full).length if anim.has_animation(full) else 0.5


func anim_progress() -> float:
	if anim.current_animation == "":
		return 1.0
	return anim.current_animation_position / maxf(0.01, anim.current_animation_length)


# ------------------------------------------------------------------ kıyafet (vücuttan türetilen kumaş katmanları)
## Bölge kodları: 0 ten, 10 omuz/üst kol, 11 göğüs, 12 bel, 13 ön kol, 14 bilek,
## 20 kalça, 21 uyluk, 22 baldır, 23 baldır altı, 30 ayak, 40 boyun
## Renk yuvaları (vertex COLOR.r = yuva * 0.1, toon shader palette_mode): 0 ten, 1 üst, 2 üst-vurgu, 3 alt, 4 sargı, 5 yelek
const TOP_STYLES := {"tisort": "Kısa Kollu Tişört", "uzun": "Uzun Kollu Ninja Gömleği", "ceket": "Fermuarlı Ceket", "yakali": "Yüksek Yakalı Gömlek", "kolsuz": "Kolsuz Yakalı", "kimono": "Kimono Üstü"}
const PANTS_STYLES := {"ninja": "Ninja Pantolonu", "sort": "Diz Altı Şort", "sivil": "Uzun Pantolon", "sargi": "Sargılı Pantolon"}

## Yüz tipi: [çene genişliği, çene ucu, elmacık, burun, kaş çıkıntısı, işaret]
const FACES := {
	"normal": [0.0, 0.0, 0.0, 0.0, 0.0], "keskin": [-0.008, 0.01, -0.004, 0.004, 0.004], "yuvarlak": [0.01, -0.006, 0.008, -0.003, 0.0],
	"köşeli": [0.012, 0.004, 0.0, 0.002, 0.004], "ince": [-0.01, -0.004, -0.006, 0.0, -0.002], "iri burun": [0.004, 0.0, 0.002, 0.009, 0.003],
}
const FACE_MARKS := {"yok": 0, "burun yarası": 1, "yanak çizgisi": 2, "çil": 3, "kırışık": 4}


static func random_face() -> Array:
	return [randf_range(-0.01, 0.012), randf_range(-0.007, 0.01), randf_range(-0.006, 0.008), randf_range(-0.003, 0.008), randf_range(-0.003, 0.004)]


static var _geo := {}       # cinsiyet -> {arrays, regions, weld, wadj, wnrm, per, tex}
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
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	# VRoid: köşeleri 180° çevir (model uzayı +Z ön); deri bağları buna göre (bind * FLIP^-1)
	# VRoid: mesh uzayı -Z önde, iskelet (kök 180° çevrildi) +Z önde -> köşeleri iskelet uzayına çevir, bağları uyarla
	var r180 = Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3.ZERO)
	for i in v.size():
		v[i] = Vector3(-v[i].x, v[i].y, -v[i].z)
		nrm[i] = Vector3(-nrm[i].x, nrm[i].y, -nrm[i].z)
	arr[Mesh.ARRAY_NORMAL] = nrm
	var tg = arr[Mesh.ARRAY_TANGENT]
	if tg != null:
		for i in range(0, tg.size(), 4):
			tg[i] = -tg[i]; tg[i + 2] = -tg[i + 2]
		arr[Mesh.ARRAY_TANGENT] = tg
	# bağ pozları düzeltilmiş dinlenme pozundan (içe aktarıcının rest fixer'ı ayak/göğüs/boyun dinlenmesini döndürüyor;
	# eski bağlarla ayaklar yukarı kalkık, göğüs eğik deforme oluyordu)
	var skin2: Skin = skin.duplicate()
	for i in skin2.get_bind_count():
		var nm = String(skin2.get_bind_name(i))
		var bi = skel.find_bone(nm) if nm != "" else skin2.get_bind_bone(i)
		if bi >= 0:
			skin2.set_bind_pose(i, skel.get_bone_global_rest(bi).affine_inverse())
		else:
			skin2.set_bind_pose(i, skin2.get_bind_pose(i) * r180)
	# bölge eşikleri bu gövdeye göre
	_rc_wrist = absf(_grest(skel.find_bone("LeftHand")).origin.x) - 0.06
	_rc_hip = _grest(skel.find_bone("Hips")).origin.y + 0.01
	_rc_shin = _grest(skel.find_bone("LeftFoot")).origin.y + 0.2
	arr[Mesh.ARRAY_VERTEX] = v
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
	# UV dikişlerinde çoğaltılmış köşeleri birleştir (yumuşatmada çatlak olmasın)
	var weld = PackedInt32Array()
	weld.resize(v.size())
	var uniq = {}
	var wpos = PackedVector3Array()
	var wnrm = PackedVector3Array()
	for i in v.size():
		var key = v[i].snapped(Vector3.ONE * 0.0001)
		if not uniq.has(key):
			uniq[key] = wpos.size()
			wpos.append(v[i])
			wnrm.append(Vector3.ZERO)
		weld[i] = uniq[key]
		wnrm[weld[i]] += nrm[i]
	for i in wnrm.size():
		wnrm[i] = wnrm[i].normalized()
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var sets: Array = []
	sets.resize(wpos.size())
	for i in wpos.size():
		sets[i] = {}
	for t in range(0, idx.size(), 3):
		var a = weld[idx[t]]; var b = weld[idx[t + 1]]; var c = weld[idx[t + 2]]
		sets[a][b] = 1; sets[a][c] = 1
		sets[b][a] = 1; sets[b][c] = 1
		sets[c][a] = 1; sets[c][b] = 1
	var wadj: Array = []
	wadj.resize(wpos.size())
	for i in wpos.size():
		wadj[i] = PackedInt32Array(sets[i].keys())
	var src_tex = null
	var src_mat = mesh.surface_get_material(0)
	if src_mat is BaseMaterial3D:
		src_tex = src_mat.albedo_texture
	var rest = PackedFloat32Array()
	rest.resize(v.size() * 4)
	for i in v.size():
		rest[i * 4] = v[i].x; rest[i * 4 + 1] = v[i].y; rest[i * 4 + 2] = v[i].z
	arr[Mesh.ARRAY_CUSTOM0] = rest
	var g = {"arrays": arr, "regions": regions, "weld": weld, "wpos": wpos, "wadj": wadj, "wnrm": wnrm, "per": per, "tex": src_tex, "skin": skin2}
	_geo[gender] = g
	return g


static var _rc_wrist := 0.55
static var _rc_hip := 1.0
static var _rc_shin := 0.3
static func _region_code(bn: String, p: Vector3) -> int:
	if bn.contains("Head") or bn == "":
		return 0
	if bn.contains("Neck"):
		return 40
	if bn.contains("Hand") or bn.contains("Thumb") or bn.contains("Index") or bn.contains("Middle") or bn.contains("Ring") or bn.contains("Little") or bn.contains("leaf"):
		return 0
	if bn.contains("LowerArm"):
		return 14 if absf(p.x) > _rc_wrist else 13
	if bn.contains("UpperArm") or bn.contains("Shoulder"):
		return 10
	if bn.contains("Chest"):
		return 11
	if bn == "Spine":
		return 12
	if bn.contains("Hips"):
		return 12 if p.y > _rc_hip else 20
	if bn.contains("UpperLeg"):
		return 21
	if bn.contains("LowerLeg"):
		return 23 if p.y < _rc_shin else 22
	if bn.contains("Toes"):
		return 0
	if bn.contains("Foot"):
		return 30
	return 12


func top_style() -> String:
	var s = look.get("top_style", "")
	if TOP_STYLES.has(s):
		return s
	return "uzun" if look.get("sleeves", true) else "tisort"


func pants_style() -> String:
	var s = look.get("pants_style", "")
	return s if PANTS_STYLES.has(s) else "ninja"


## Kumaş kabuğu kalınlığı (0 = kabuk yok). Hangi kısmın görüneceğine shader karar verir.
static func _shell_offset(code: int) -> float:
	return {10: 0.014, 11: 0.02, 12: 0.022, 13: 0.014, 14: 0.01, 20: 0.012, 21: 0.022, 22: 0.018, 23: 0.01}.get(code, 0.0)


func _palette() -> PackedColorArray:
	var L = look
	var vest = L["vest"] if L["vest"] != null else L["top"]
	var gc = func(k: String, d: Color) -> Color: return Color(L[k]) if L.get(k) != null else d
	return PackedColorArray([Color(L["skin"]), Color(L["top"]), Color(L["top2"]), Color(L["pants"]), Color(L["wraps"]), Color(vest), Color(L["sandal"]), Color(0.12, 0.1, 0.1),
		gc.call("outer", Color(0.4, 0.32, 0.24)), gc.call("acc", Color(0.55, 0.58, 0.62)), gc.call("headgear", Color(0.22, 0.2, 0.24)), gc.call("facegear", Color(0.15, 0.15, 0.2))])


func _surface_flags(g: Dictionary) -> int:
	var f = Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	return f | (Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if g["per"] == 8 else 0)


func _cloth_mat(layer: int) -> ShaderMaterial:
	var g = _geo_for(look["gender"])
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.45)
	mat.set_shader_parameter("spec_amount", 0.1 if layer == 0 else 0.0)
	mat.set_shader_parameter("palette_mode", true)
	mat.set_shader_parameter("pal", _palette())
	mat.set_shader_parameter("layer", layer)
	mat.set_shader_parameter("top_style", TOP_STYLES.keys().find(top_style()))
	mat.set_shader_parameter("pants_style", PANTS_STYLES.keys().find(pants_style()))
	mat.set_shader_parameter("top_pattern", int(look.get("top_pattern", 0)))
	mat.set_shader_parameter("vest_style", int(look.get("vest_style", 0)))
	mat.set_shader_parameter("gloves", bool(look.get("gloves", false)))
	mat.set_shader_parameter("arm_wraps", bool(look.get("arm_wraps", false)))
	mat.set_shader_parameter("outer_sleeves", 1 if look.get("outer_style") in ["palto", "haori"] else 0)
	mat.set_shader_parameter("foot_cover", look.get("foot_style", "sandal") == "tabi")
	var bp = func(n: String) -> Vector3: return _grest(skel.find_bone(n)).origin
	mat.set_shader_parameter("rig_a", Vector4(bp.call("LeftUpperArm").x, bp.call("LeftLowerArm").x, bp.call("LeftHand").x, bp.call("Neck").y))
	mat.set_shader_parameter("rig_b", Vector4(bp.call("Hips").y, bp.call("LeftLowerLeg").y, bp.call("LeftFoot").y, bp.call("UpperChest").y))
	if g["tex"]:
		mat.set_shader_parameter("tex", g["tex"])
	mat.set_shader_parameter("tint", _skin_ratio())
	var f = look.get("face")
	if f is String:
		f = FACES.get(f, FACES["normal"])
	if not f is Array or f.size() < 5:
		f = random_face()
		look["face"] = f
	var young = {"child": 1.0, "teen": 0.5}.get(look.get("age", "adult"), 0.0)
	# çocuk yüzü: dar çene, küçük burun, dolgun yanak
	mat.set_shader_parameter("face_a", Vector4.ZERO)
	mat.set_shader_parameter("face_b", Vector4(f[4], FACE_MARKS.get(look.get("face_mark", "yok"), 0), 0, 0))
	mat.set_shader_parameter("face_ref", Vector4(0, eye_center_model.y, eye_center_model.z, 0))
	materials.append(mat)
	return mat


func _paint_body() -> void:
	var g = _geo_for(look["gender"])
	var key = look["gender"]
	if not _body_cache.has(key):
		var m = ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, g["arrays"], [], {}, _surface_flags(g))
		_body_cache[key] = m
		_shell_cache[key] = _build_shell(g, func(c): return _shell_offset(c), 22)
		_shell_cache[key + "|vest"] = _build_shell(g, func(c): return {10: 0.035, 11: 0.055, 12: 0.058, 20: 0.05}.get(c, 0.0), 14)
	body_mesh.mesh = _body_cache[key]
	body_mesh.skin = g["skin"]
	body_mesh.set_surface_override_material(0, _cloth_mat(0))
	var shell_mat = _cloth_mat(1)
	cloth_shell_mat = shell_mat
	_add_shell(_shell_cache[key], shell_mat)
	var vest_mat = null
	if look["vest"] != null:
		vest_mat = _cloth_mat(2)
		_add_shell(_shell_cache[key + "|vest"], vest_mat)
	_cloth_rings(g, shell_mat, vest_mat)
	_garments(g)


## Kollarda manşet, belde gömlek eteği, paçada büzgü: kıyafete gerçek kalınlık/katman verir
static var _ring_cache := {}
func _cloth_rings(g: Dictionary, mat: ShaderMaterial, vest_mat) -> void:
	var bp = func(n: String) -> Vector3: return _grest(skel.find_bone(n)).origin
	var ua = bp.call("LeftUpperArm").x; var el = bp.call("LeftLowerArm").x; var ha = bp.call("LeftHand").x
	var neck = bp.call("Neck").y; var hips = bp.call("Hips").y; var knee = bp.call("LeftLowerLeg").y; var ank = bp.call("LeftFoot").y
	var ts = top_style(); var ps = pants_style()
	var short_sleeve = ts in ["tisort", "yakali"]
	var sleeve = lerpf(ua, el, 0.5) if short_sleeve else ha - 0.035
	var cut = {"ninja": knee - 0.17, "sort": knee - 0.05}.get(ps, ank + 0.04)
	var rings = []
	for sx in [-1.0, 1.0]:
		var side = "Left" if sx > 0 else "Right"
		rings.append([0, sleeve * sx, sx, side + ("UpperArm" if short_sleeve else "LowerArm"), 0.016, 0.011, Vector3(-0.012 * sx, 0, 0), mat, neck])
		rings.append([1, cut, sx, side + "LowerLeg", 0.02 if ps == "ninja" else 0.014, 0.013, Vector3(0, 0.012, 0), mat, neck])
	rings.append([1, hips + 0.03, 0.0, "Hips", 0.03, 0.012, Vector3(0, 0.015, 0), mat, neck])
	if vest_mat != null:
		rings.append([1, hips + 0.04, 0.0, "Hips", 0.058, 0.01, Vector3(0, 0.03, 0), vest_mat, neck])
	for r in rings:
		var key = "%s|%d|%.3f|%.1f|%.3f|%.3f" % [look["gender"], r[0], r[1], r[2], r[4], r[5]]
		if not _ring_cache.has(key):
			_ring_cache[key] = _ring_mesh(g, r[0], r[1], r[2], r[4], r[5], r[6], r[8])
		if _ring_cache[key] == null:
			continue
		var mi = _mesh_on(r[3], _ring_cache[key], Transform3D.IDENTITY)
		mi.material_override = r[7]


## Gövde kesitinin (düzlemde) dış çizgisini izleyen tüp halka
static func _ring_mesh(g: Dictionary, axis: int, value: float, side: float, extra: float, thick: float, shift: Vector3, neck_y: float, ymax := 99.0) -> ArrayMesh:
	var wpos: PackedVector3Array = g["wpos"]
	var pts = []
	for p in wpos:
		if absf(p[axis] - value) > 0.012 or p.y > ymax:
			continue
		if axis == 0:
			if p.y < neck_y - 0.32:
				continue
		elif side != 0.0:
			if signf(p.x) != side or absf(p.x) > 0.35:
				continue
		elif absf(p.x) > 0.3:
			continue
		pts.append(p)
	if pts.size() < 8:
		return null
	var c = Vector3.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	c[axis] = value
	var ua = Vector3.UP if axis == 0 else Vector3.RIGHT
	var ub = Vector3.UP if axis == 2 else Vector3.BACK
	var bins = 20
	var rad = PackedFloat32Array()
	rad.resize(bins)
	for p in pts:
		var d = p - c
		var a = atan2(d.dot(ub), d.dot(ua))
		var k = int(floor((a + PI) / TAU * bins)) % bins
		rad[k] = maxf(rad[k], Vector2(d.dot(ua), d.dot(ub)).length())
	for it in 3:  # boş bölmeleri komşulardan doldur
		for k in bins:
			if rad[k] <= 0.0:
				rad[k] = maxf(rad[(k + 1) % bins], rad[(k + bins - 1) % bins])
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var sides = 6
	var ring_pts = []
	for k in bins:
		var a = (float(k) + 0.5) / bins * TAU - PI
		var dir = (ua * cos(a) + ub * sin(a)).normalized()
		var r = rad[k] + extra
		ring_pts.append([c + dir * r, dir])
	var normal_axis = [Vector3.RIGHT, Vector3.UP, Vector3.BACK][axis]
	for k in bins:
		var A = ring_pts[k]; var B = ring_pts[(k + 1) % bins]
		for q in sides:
			var t0 = float(q) / sides * TAU; var t1 = float(q + 1) / sides * TAU
			var quad = [[A, t0], [B, t0], [B, t1], [A, t0], [B, t1], [A, t1]]
			for e in quad:
				var o = e[0][1] * cos(e[1]) + normal_axis * sin(e[1])
				var pos: Vector3 = e[0][0] + o * thick
				st.set_normal(o)
				var cp = e[0][0] + shift
				st.set_custom(0, Color(cp.x, cp.y, cp.z, 0))
				st.add_vertex(pos)
	return st.commit(null, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)


func _add_shell(m: ArrayMesh, mat: ShaderMaterial) -> void:
	if m == null:
		return
	var shell = MeshInstance3D.new()
	shell.name = "Cloth"
	shell.mesh = m
	skel.add_child(shell)
	shell.skin = body_mesh.skin
	shell.skeleton = shell.get_path_to(skel)
	shell.material_override = mat


## Seçili bölgeleri kaslardan arındırıp (Taubin yumuşatma) normal yönünde şişirerek kumaş kabuğu üretir
func _build_shell(g: Dictionary, offset_of: Callable, iters: int) -> ArrayMesh:
	var arr: Array = (g["arrays"] as Array).duplicate(true)
	var regions: PackedInt32Array = g["regions"]
	var weld: PackedInt32Array = g["weld"]
	var wadj: Array = g["wadj"]
	var wnrm: PackedVector3Array = g["wnrm"]
	var pos: PackedVector3Array = (g["wpos"] as PackedVector3Array).duplicate()
	var n = pos.size()
	var off = PackedFloat32Array()
	off.resize(n)
	var code_w = PackedInt32Array()
	code_w.resize(n)
	for i in regions.size():
		var o: float = offset_of.call(regions[i])
		off[weld[i]] = maxf(off[weld[i]], o)
		code_w[weld[i]] = regions[i]
	# sınır köşeleri (kumaşın bittiği yer) sabit kalır, iç kısım yumuşar
	var movable = PackedByteArray()
	movable.resize(n)
	for i in n:
		if off[i] <= 0.0:
			continue
		var inner = 1
		for j in wadj[i]:
			if off[j] <= 0.0:
				inner = 0
				break
		movable[i] = inner
	# kalınlık alanını yay: kabuk kenarlarda vücuda yumuşakça otursun (çizgi/kırık kenar olmasın)
	for it in 6:
		var o2 = off.duplicate()
		for i in n:
			if off[i] <= 0.0:
				continue
			var nb: PackedInt32Array = wadj[i]
			var s = off[i]
			for j in nb:
				s += off[j]
			o2[i] = maxf(0.001, s / (nb.size() + 1))
		off = o2
	for it in iters * 2:
		var lam = 0.55 if it % 2 == 0 else -0.58
		var nxt = pos.duplicate()
		for i in n:
			if movable[i] == 0:
				continue
			var nb: PackedInt32Array = wadj[i]
			var s = Vector3.ZERO
			for j in nb:
				s += pos[j]
			nxt[i] = pos[i] + (s / nb.size() - pos[i]) * lam
		pos = nxt
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var keep_v = PackedByteArray()
	keep_v.resize(v.size())
	for i in v.size():
		var w = weld[i]
		if off[w] <= 0.0:
			continue
		keep_v[i] = 1
		v[i] = pos[w] + wnrm[w] * off[w]
	arr[Mesh.ARRAY_VERTEX] = v
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var keep = PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if keep_v[idx[t]] == 1 and keep_v[idx[t + 1]] == 1 and keep_v[idx[t + 2]] == 1:
			keep.append(idx[t]); keep.append(idx[t + 1]); keep.append(idx[t + 2])
	if keep.is_empty():
		return null
	arr[Mesh.ARRAY_INDEX] = keep
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, _surface_flags(g))
	return m


## Ninja sandaleti: ayak izine göre biçimli taban + parmak kayışı, ayak üstü kayışı, bilek kayışı, topuk
static var _sole_cache := {}
func _sandals() -> void:
	var g = _geo_for(look["gender"])
	var wpos: PackedVector3Array = g["wpos"]
	var neck = _grest(skel.find_bone("Neck")).origin.y
	for side in ["Left", "Right"]:
		var sx = 1.0 if side == "Left" else -1.0
		var fb = skel.find_bone(side + "Foot")
		if fb < 0:
			continue
		var fp = _grest(fb).origin
		var key = "%s|%s" % [look["gender"], side]
		if not _sole_cache.has(key):
			_sole_cache[key] = _sole_mesh(wpos, sx)
		var parts = [_sole_cache[key]]
		var ring_defs = [[2, fp.z + 0.13, 0.004, 0.007, 0.075], [2, fp.z + 0.06, 0.004, 0.008, 0.11], [1, fp.y + 0.02, 0.006, 0.008, 99.0]]
		match look.get("foot_style", "sandal"):
			"tabi":
				ring_defs = [[1, fp.y + 0.02, 0.004, 0.006, 99.0]]  # ayak shader'da kapalı, sadece bilek bağı
			"zori":
				ring_defs = [[2, fp.z + 0.11, 0.004, 0.006, 0.07]]
		for rd in ring_defs:
			var rk = "%s|%d|%.3f" % [key, rd[0], rd[1]]
			if not _ring_cache.has(rk):
				_ring_cache[rk] = _ring_mesh(g, rd[0], rd[1], sx, rd[2], rd[3], Vector3(0, -10, 0), neck, rd[4])
			parts.append(_ring_cache[rk])
		for m in parts:
			if m == null:
				continue
			var mi = _mesh_on(side + "Foot", m, Transform3D.IDENTITY)
			mi.material_override = cloth_shell_mat


## Taban: ayağın yere yakın köşelerinden çıkarılan dış hat, 1.6 cm kalınlık
static func _sole_mesh(wpos: PackedVector3Array, sx: float) -> ArrayMesh:
	var bins = 12
	var zmin = 1e9; var zmax = -1e9
	var pts = []
	for p in wpos:
		if p.y < 0.05 and signf(p.x) == sx and absf(p.x) < 0.35:
			pts.append(p)
			zmin = minf(zmin, p.z); zmax = maxf(zmax, p.z)
	if pts.size() < 10:
		return null
	zmin -= 0.012; zmax += 0.015
	var lo = PackedFloat32Array(); var hi = PackedFloat32Array()
	lo.resize(bins); hi.resize(bins)
	for k in bins:
		lo[k] = 1e9; hi[k] = -1e9
	for p in pts:
		var k = clampi(int((p.z - zmin) / (zmax - zmin) * bins), 0, bins - 1)
		lo[k] = minf(lo[k], p.x); hi[k] = maxf(hi[k], p.x)
	var cx = 0.0
	for p in pts:
		cx += p.x
	cx /= pts.size()
	for it in 3:
		for k in bins:
			if lo[k] > 1e8:
				var nb = k - 1 if k > 0 and lo[k - 1] < 1e8 else mini(k + 1, bins - 1)
				lo[k] = lo[nb]; hi[k] = hi[nb]
	var outline = []
	for k in bins:
		var z = zmin + (float(k) + 0.5) / bins * (zmax - zmin)
		var round_k = sin(PI * (float(k) + 0.5) / bins)
		var hw = maxf(0.02, (hi[k] - lo[k]) * 0.5 + 0.01) * lerpf(0.75, 1.0, round_k)
		var mx = (hi[k] + lo[k]) * 0.5
		outline.append(Vector2(mx + hw, z))
	for k in range(bins - 1, -1, -1):
		var z = zmin + (float(k) + 0.5) / bins * (zmax - zmin)
		var round_k = sin(PI * (float(k) + 0.5) / bins)
		var hw = maxf(0.02, (hi[k] - lo[k]) * 0.5 + 0.01) * lerpf(0.75, 1.0, round_k)
		var mx = (hi[k] + lo[k]) * 0.5
		outline.append(Vector2(mx - hw, z))
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var y0 = -0.004; var y1 = 0.014
	var c3 = Vector2(cx, (zmin + zmax) * 0.5)
	var n = outline.size()
	var dark = Color(0, -20, 0, 0)  # shader: çok negatif y = koyu taban rengi
	for i in n:
		var a: Vector2 = outline[i]; var b: Vector2 = outline[(i + 1) % n]
		for tri in [[c3, a, b, y1, Vector3.UP], [c3, b, a, y0, Vector3.DOWN]]:
			for q in [tri[0], tri[1], tri[2]]:
				st.set_normal(tri[4])
				st.set_custom(0, dark)
				st.add_vertex(Vector3(q.x, tri[3], q.y))
		var sn = Vector3(b.y - a.y, 0, -(b.x - a.x)).normalized()
		for q in [[a, y0], [b, y0], [b, y1], [a, y0], [b, y1], [a, y1]]:
			st.set_normal(sn)
			st.set_custom(0, dark)
			st.add_vertex(Vector3(q[0].x, q[1], q[0].y))
	return st.commit(null, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)


# ------------------------------------------------------------------ giysi katmanları (palto, pelerin, hakama, kapüşon, maske, koruyucular)
## Gövde/uzuv kesitlerinden "loft" yüzeyi örülür; her köşe en yakın vücut köşesinin kemik ağırlıklarını alır (iskeletle birlikte bükülür)
static var _garment_cache := {}


func _bp(n: String) -> Vector3:
	return _grest(skel.find_bone(n)).origin


## Vücut köşeleri için ızgara (en yakın köşe araması) + eksene göre kovalar
static func _skin_index(g: Dictionary) -> void:
	if g.has("grid"):
		return
	var v: PackedVector3Array = g["arrays"][Mesh.ARRAY_VERTEX]
	var grid = {}
	for i in v.size():
		var k = Vector3i(floor(v[i].x / 0.04), floor(v[i].y / 0.04), floor(v[i].z / 0.04))
		if not grid.has(k):
			grid[k] = PackedInt32Array()
		grid[k].append(i)
	g["grid"] = grid
	var wpos: PackedVector3Array = g["wpos"]
	for axis in [0, 1, 2]:
		var buck = {}
		for p in wpos:
			var b = int(floor(p[axis] / 0.01))
			if not buck.has(b):
				buck[b] = []
			buck[b].append(p)
		g["buck%d" % axis] = buck


static func _nearest(g: Dictionary, p: Vector3) -> int:
	var v: PackedVector3Array = g["arrays"][Mesh.ARRAY_VERTEX]
	var grid: Dictionary = g["grid"]
	var c = Vector3i(floor(p.x / 0.04), floor(p.y / 0.04), floor(p.z / 0.04))
	var best = -1
	var bd = 1e9
	for r in [1, 2, 4]:
		for x in range(-r, r + 1):
			for y in range(-r, r + 1):
				for z in range(-r, r + 1):
					var k = c + Vector3i(x, y, z)
					if not grid.has(k):
						continue
					for i in grid[k]:
						var d = v[i].distance_squared_to(p)
						if d < bd:
							bd = d; best = i
		if best >= 0:
			return best
	return 0


func _bind_index(bone: String) -> int:
	var skin: Skin = body_mesh.skin
	var bi = skel.find_bone(bone)
	for i in skin.get_bind_count():
		if skin.get_bind_name(i) == StringName(bone) or skin.get_bind_bone(i) == bi:
			return i
	return 0


## Kesit katmanlarından çift yüzlü, iskelete bağlı giysi örer.
## axis: 0 = x (kol), 1 = y (gövde/bacak); filt(p) kesite giren vücut köşeleri; off(t, açı) kalınlık; skip(t, açı) boş bırakılan kısımlar (ön açıklık vb.)
func _loft(g: Dictionary, axis: int, v0: float, v1: float, rows: int, filt: Callable, off: Callable, slot: int, skip = null, skirt_y := -99.0, bins := 24) -> ArrayMesh:
	_skin_index(g)
	var buck: Dictionary = g["buck%d" % axis]
	var ua = Vector3.UP if axis == 0 else Vector3.RIGHT
	var ub = Vector3.BACK
	var centers = []
	var radii = []
	for r in rows:
		var val = lerpf(v0, v1, float(r) / (rows - 1))
		var pts = []
		for b in range(int(floor((val - 0.015) / 0.01)), int(floor((val + 0.015) / 0.01)) + 1):
			if buck.has(b):
				for p in buck[b]:
					if absf(p[axis] - val) <= 0.015 and filt.call(p):
						pts.append(p)
		if pts.size() < 6:
			centers.append(null)
			radii.append(null)
			continue
		var c = Vector3.ZERO
		for p in pts:
			c += p
		c /= pts.size()
		c[axis] = val
		var rad = PackedFloat32Array()
		rad.resize(bins)
		for p in pts:
			var d = p - c
			var a = atan2(d.dot(ub), d.dot(ua))
			var k = int(floor((a + PI) / TAU * bins)) % bins
			rad[k] = maxf(rad[k], Vector2(d.dot(ua), d.dot(ub)).length())
		for it in 4:
			for k in bins:
				if rad[k] <= 0.0:
					rad[k] = maxf(rad[(k + 1) % bins], rad[(k + bins - 1) % bins])
		centers.append(c)
		radii.append(rad)
	# boş katmanları komşudan doldur (kesit bulunamayan uçlar)
	for it in rows:
		for r in rows:
			if centers[r] == null:
				var nb = r - 1 if r > 0 and centers[r - 1] != null else (r + 1 if r < rows - 1 and centers[r + 1] != null else -1)
				if nb >= 0:
					var c: Vector3 = centers[nb]
					c[axis] = lerpf(v0, v1, float(r) / (rows - 1))
					centers[r] = c
					radii[r] = (radii[nb] as PackedFloat32Array).duplicate()
	if centers[0] == null:
		return null
	# yarıçapları yumuşat (açıda + katmanlar arasında)
	for it in 2:
		for r in rows:
			var rr: PackedFloat32Array = radii[r]
			var nn = rr.duplicate()
			for k in bins:
				nn[k] = (rr[(k + bins - 1) % bins] + rr[k] * 2.0 + rr[(k + 1) % bins]) * 0.25
			radii[r] = nn
		for r in range(1, rows - 1):
			var a: PackedFloat32Array = radii[r - 1]; var b: PackedFloat32Array = radii[r]; var c2: PackedFloat32Array = radii[r + 1]
			var nn = b.duplicate()
			for k in bins:
				nn[k] = (a[k] + b[k] * 2.0 + c2[k]) * 0.25
			radii[r] = nn
	var verts = PackedVector3Array()
	var custom = PackedFloat32Array()
	for r in rows:
		var t = float(r) / (rows - 1)
		for k in bins:
			var ang = (float(k) + 0.5) / bins * TAU - PI
			var dir = ua * cos(ang) + ub * sin(ang)
			var p: Vector3 = centers[r] + dir * ((radii[r] as PackedFloat32Array)[k] + float(off.call(t, ang)))
			verts.append(p)
			custom.append_array([p.x, p.y, p.z, float(slot)])
	var idx = PackedInt32Array()
	for r in rows - 1:
		var t = (float(r) + 0.5) / (rows - 1)
		for k in bins:
			var ang = (float(k) + 1.0) / bins * TAU - PI
			if skip != null and skip.call(t, ang):
				continue
			var a = r * bins + k; var b = r * bins + (k + 1) % bins
			var c = (r + 1) * bins + k; var d = (r + 1) * bins + (k + 1) % bins
			if axis == 1:
				idx.append_array([a, c, b, b, c, d])
			else:
				idx.append_array([a, b, c, b, d, c])
	if idx.is_empty():
		return null
	return _skinned_mesh(g, verts, custom, idx, skirt_y)


## Normaller + ağırlık aktarımı + iç yüz (çift taraflı) → iskelete bağlanacak mesh
func _skinned_mesh(g: Dictionary, verts: PackedVector3Array, custom: PackedFloat32Array, idx: PackedInt32Array, skirt_y: float) -> ArrayMesh:
	var n = verts.size()
	var nrm = PackedVector3Array()
	nrm.resize(n)
	for t in range(0, idx.size(), 3):
		var fnm = (verts[idx[t + 2]] - verts[idx[t]]).cross(verts[idx[t + 1]] - verts[idx[t]])
		for j in 3:
			nrm[idx[t + j]] += fnm
	for i in n:
		nrm[i] = nrm[i].normalized() if nrm[i].length() > 0.0 else Vector3.UP
	var per: int = g["per"]
	var sb = g["arrays"][Mesh.ARRAY_BONES]
	var sw = g["arrays"][Mesh.ARRAY_WEIGHTS]
	var hips_bi = _bind_index("Hips")
	var bones = PackedInt32Array(); var weights = PackedFloat32Array()
	bones.resize(n * per); weights.resize(n * per)
	for i in n:
		var src = _nearest(g, verts[i])
		var wb = []
		for k in per:
			wb.append([sb[src * per + k], sw[src * per + k]])
		if verts[i].y < skirt_y:
			# etek/palto alt kısmı: bacaklarla gerilmesin, çoğunlukla kalçayı izlesin
			var blend = clampf((skirt_y - verts[i].y) / 0.25, 0.0, 0.7)
			for e in wb:
				e[1] = e[1] * (1.0 - blend)
			var put = false
			for e in wb:
				if e[0] == hips_bi:
					e[1] += blend
					put = true
			if not put:
				wb.sort_custom(func(x, y): return x[1] < y[1])
				wb[0] = [hips_bi, blend + wb[0][1]]
		var tot = 0.0
		for e in wb:
			tot += e[1]
		for k in per:
			bones[i * per + k] = wb[k][0]
			weights[i * per + k] = wb[k][1] / maxf(tot, 0.0001)
	# iç yüz: aynı köşeler hafif içeride, ters normal, ters sarım
	var all_v = verts.duplicate(); var all_n = nrm.duplicate(); var all_c = custom.duplicate()
	var all_b = bones.duplicate(); var all_w = weights.duplicate()
	for i in n:
		all_v.append(verts[i] - nrm[i] * 0.003)
		all_n.append(-nrm[i])
	all_c.append_array(custom)
	all_b.append_array(bones)
	all_w.append_array(weights)
	var all_i = idx.duplicate()
	for t in range(0, idx.size(), 3):
		all_i.append_array([idx[t] + n, idx[t + 2] + n, idx[t + 1] + n])
	var uv = PackedVector2Array()
	uv.resize(all_v.size())
	for i in all_v.size():
		uv[i] = Vector2(all_v[i].x + all_v[i].z, all_v[i].y) * 2.0
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = all_v
	arr[Mesh.ARRAY_NORMAL] = all_n
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_CUSTOM0] = all_c
	arr[Mesh.ARRAY_BONES] = all_b
	arr[Mesh.ARRAY_WEIGHTS] = all_w
	arr[Mesh.ARRAY_INDEX] = all_i
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, _surface_flags(g))
	return m


func _garment(key: String, build: Callable) -> void:
	var k = "%s|%s" % [look["gender"], key]
	if not _garment_cache.has(k):
		_garment_cache[k] = build.call()
	if _garment_cache[k] != null:
		_add_shell(_garment_cache[k], cloth_shell_mat)


## Görünümdeki giysi katmanlarını kur
func _garments(g: Dictionary) -> void:
	var neck = _bp("Neck").y; var hips = _bp("Hips").y; var knee = _bp("LeftLowerLeg").y; var ank = _bp("LeftFoot").y
	var chest = _bp("UpperChest").y; var ua = _bp("LeftUpperArm").x; var ha = _bp("LeftHand").x
	var ey = neck + 0.17
	if eyes_mesh:
		ey = eyes_mesh.get_aabb().get_center().y
	var torso = func(p: Vector3) -> bool: return absf(p.x) < (ua * 0.95 if p.y > neck - 0.33 else 0.45) and p.y < neck + 0.06
	var front_gap = func(w: float, from_t: float) -> Callable:
		return func(t: float, ang: float) -> bool: return t > from_t and absf(wrapf(ang - PI * 0.5, -PI, PI)) < w
	var flat = func(o: float) -> Callable:
		return func(_t: float, _a: float) -> float: return o
	match look.get("outer_style"):
		"palto":
			_garment("palto", func(): return _loft(g, 1, neck - 0.01, knee + 0.02, 22, torso, func(t, _a): return 0.045 + t * t * 0.11, 8, front_gap.call(0.2, 0.12), hips - 0.06))
		"pelerin":
			_garment("pelerin", func(): return _loft(g, 1, neck + 0.02, knee - 0.06, 22, torso, func(t, _a): return 0.06 + t * 0.1, 8, null, hips - 0.06))
		"haori":
			_garment("haori", func(): return _loft(g, 1, neck - 0.01, hips - 0.16, 14, torso, func(t, _a): return 0.045 + t * 0.05, 8, front_gap.call(0.26, 0.05), hips - 0.06))
		"kisa":
			_garment("kisa", func(): return _loft(g, 1, neck - 0.03, chest - 0.3, 12, torso, func(t, _a): return 0.05 + t * 0.07, 8, func(_t, ang): return absf(wrapf(ang - PI * 0.5, -PI, PI)) < 1.7))
			_garment("atki", func(): return _loft(g, 1, neck - 0.06, neck + 0.04, 5, func(p): return absf(p.x) < 0.16, flat.call(0.03), 8))
		"atki":
			_garment("atki", func(): return _loft(g, 1, neck - 0.06, neck + 0.04, 5, func(p): return absf(p.x) < 0.16, flat.call(0.03), 8))
	if top_style() == "kimono":
		_garment("obi", func(): return _loft(g, 1, hips + 0.03, hips + 0.15, 5, torso, flat.call(0.03), 2))
	if look.get("hakama", false):
		# hakama: belden bileğe geniş, pilili etek-pantolon (bacakların ortak kesitinden)
		_garment("hakama", func(): return _loft(g, 1, hips + 0.06, ank + 0.06, 22, torso, func(t, _a): return 0.03 + t * 0.06, 3, null, hips - 0.12, 28))
	var hs = look.get("head_style")
	if hs == "kapuson":
		_garment("kapuson", func(): return _loft(g, 1, ey + 0.17, neck - 0.04, 14, func(p): return p.y > neck - 0.1 and absf(p.x) < 0.15,
			func(t, _a): return 0.055 + t * 0.02, 10, func(t, ang): return t > 0.32 and t < 0.9 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 1.05))
	var fs = look.get("face_style")
	if fs in ["cloth", "gas"]:
		_garment("maske", func(): return _loft(g, 1, ey - 0.038, neck - 0.03, 10, func(p): return p.y > neck - 0.08 and absf(p.x) < 0.13, flat.call(0.009), 11))
	var gd = look.get("guards")
	if gd in ["kol", "ikisi"]:
		for sx in [-1.0, 1.0]:
			_garment("kolluk%d" % int(sx), func(): return _loft(g, 0, (ha - 0.17) * sx, (ha - 0.05) * sx, 6, func(p): return signf(p.x) == sx and p.y > neck - 0.32, flat.call(0.018), 9, null, -99.0, 16))
	if gd in ["bacak", "ikisi"]:
		for sx in [-1.0, 1.0]:
			_garment("kaval%d" % int(sx), func(): return _loft(g, 1, knee - 0.05, ank + 0.08, 8, func(p): return signf(p.x) == sx and absf(p.x) < 0.35,
				func(_t, ang): return 0.03 if absf(wrapf(ang - PI * 0.5, -PI, PI)) < 1.3 else 0.02, 9, null, -99.0, 16))


## Hayran modeli aksesuar: SFProps.ACCESSORIES[id] kemiğe, ref noktasına göre "off" ofsetle takılır
func _sf_acc(id: String, ref: Vector3) -> bool:
	if id == "" or not SFProps.has_accessory(id):
		return false
	var d: Dictionary = SFProps.ACCESSORIES[id]
	var n = SFProps.accessory_node(id)
	if n == null:
		return false
	var a = _attach(String(d["bone"]), Transform3D(Basis.IDENTITY, ref + Vector3(d.get("off", Vector3.ZERO))))
	a.get_child(0).add_child(n)
	return true


## Sert (kemiğe sabit) aksesuarlar: şapka, maske detayları, sırt eşyaları, yelek kayışları, eldiven plakaları, kemer
func _accessories() -> void:
	var hc = _head_center()
	var ab = head_ab
	var hw = clampf(ab.size.x, 0.16, 0.26) if ab.size.x > 0.05 else 0.2
	var hd = clampf(ab.size.z, 0.17, 0.28) if ab.size.z > 0.05 else 0.22
	var hh = clampf(ab.size.y, 0.12, 0.26) if ab.size.y > 0.05 else 0.2
	# konum hep kafa merkezinden (saç modelinin sınırları güvenilmez)
	var htop = hc.y + hh * 0.42
	var hcen = hc
	var ch = _bp("UpperChest")
	var hip = _bp("Hips")
	var steel = Color(0.62, 0.65, 0.7)
	var dark = Color(0.12, 0.12, 0.14)
	var hg: Color = look.get("headgear", Color(0.5, 0.4, 0.3)) if look.get("headgear") != null else Color(0.5, 0.4, 0.3)
	# hayran modelleri (varsa): şapka / maske / sırt eşyası; yoksa aşağıdaki prosedürel modeller
	var sf_head = _sf_acc(SFProps.HEAD_MAP.get(look.get("head_style"), ""), hc)
	var sf_face = _sf_acc(SFProps.FACE_MAP.get(look.get("face_style"), ""), hc)
	var sf_back = _sf_acc(SFProps.BACK_MAP.get(look.get("back_item"), ""), ch)
	match (null if sf_head else look.get("head_style")):
		"kasa":
			var m = MB.new()
			m.add("cone", Vector3(0, 0.0, 0), Vector3(hw * 3.2, 0.17, hw * 3.2), hg, Vector3.ZERO, 18)
			m.add("cyl", Vector3(0, -0.075, 0), Vector3(hw * 3.1, 0.014, hw * 3.1), hg.darkened(0.15), Vector3.ZERO, 18)
			m.add("cyl", Vector3(0, -0.05, 0), Vector3(hw * 1.05, 0.04, hw * 1.12), hg.darkened(0.35), Vector3.ZERO, 14)
			_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hcen.x, htop + 0.02, hcen.z)))
		"bandana":
			var m = MB.new()
			m.add("hemi", Vector3.ZERO, Vector3(hw * 1.16, hh * 0.8, hd * 1.12), hg, Vector3.ZERO, 16)
			m.add("box", Vector3(0, -0.012, hd * 0.56), Vector3(0.07, 0.03, 0.006), Color(0.8, 0.82, 0.86))
			m.add("box", Vector3(0.0, -0.03, -hd * 0.56), Vector3(0.03, 0.06, 0.02), hg, Vector3(-30, 0, 0))
			_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hcen.x, hc.y - 0.005, hcen.z)))
		"bandaj":
			var m = MB.new()
			m.add("cyl", Vector3.ZERO, Vector3(hw * 1.14, 0.05, hd * 1.08), hg, Vector3(6, 0, 0), 20)
			m.add("box", Vector3(0.03, -0.04, -hd * 0.55), Vector3(0.03, 0.09, 0.006), hg, Vector3(-15, 0, 12))
			_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hcen.x, hc.y + 0.02, hcen.z)))
	var fg: Color = look.get("facegear", Color.WHITE) if look.get("facegear") != null else Color.WHITE
	var fs = null if sf_face else look.get("face_style")
	if fs != null and String(fs).begins_with("anbu"):
		var m = MB.new()
		var red = Color(0.75, 0.1, 0.12)
		m.add("sphere", Vector3.ZERO, Vector3(0.17, 0.22, 0.09), fg, Vector3.ZERO, 12)
		for sx in [-1.0, 1.0]:
			m.add("box", Vector3(0.035 * sx, 0.02, 0.043), Vector3(0.035, 0.012, 0.006), dark, Vector3(0, 0, -12 * sx))
		match fs:
			"anbu_kedi":
				for sx in [-1.0, 1.0]:
					m.add("cone", Vector3(0.06 * sx, 0.11, 0.0), Vector3(0.05, 0.06, 0.03), fg, Vector3(0, 0, -20 * sx), 4)
					for k in 2:
						m.add("box", Vector3(0.06 * sx, -0.03 - k * 0.018, 0.04), Vector3(0.05, 0.006, 0.004), red, Vector3(0, 0, 8 * sx * (k * 2 - 1)))
			"anbu_kurt":
				m.add("box", Vector3(0, -0.04, 0.06), Vector3(0.06, 0.05, 0.06), fg)
				for sx in [-1.0, 1.0]:
					m.add("cone", Vector3(0.065 * sx, 0.11, -0.01), Vector3(0.045, 0.07, 0.03), fg, Vector3(0, 0, -15 * sx), 4)
					m.add("box", Vector3(0.045 * sx, 0.055, 0.04), Vector3(0.006, 0.05, 0.004), Color(0.25, 0.3, 0.55), Vector3(0, 0, 20 * sx))
			"anbu_kus":
				m.add("cone", Vector3(0, -0.02, 0.09), Vector3(0.05, 0.1, 0.04), Color(0.9, 0.7, 0.25), Vector3(80, 0, 0), 6)
				m.add("box", Vector3(0, 0.07, 0.04), Vector3(0.1, 0.008, 0.004), red)
			"anbu_ayi":
				for sx in [-1.0, 1.0]:
					m.add("sphere", Vector3(0.075 * sx, 0.1, -0.005), Vector3(0.05, 0.05, 0.025), fg, Vector3.ZERO, 8)
				m.add("sphere", Vector3(0, -0.04, 0.045), Vector3(0.05, 0.035, 0.03), Color(0.3, 0.25, 0.25), Vector3.ZERO, 8)
		_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, -0.03, 0.085)))
	elif fs == "gas":
		var m = MB.new()
		for sx in [-1.0, 1.0]:
			m.add("cyl", Vector3(0.05 * sx, -0.02, 0.0), Vector3(0.045, 0.06, 0.045), Color(0.35, 0.38, 0.35), Vector3(80, 0, 25 * sx), 10)
			m.add("cyl", Vector3(0.055 * sx, -0.025, 0.03), Vector3(0.05, 0.012, 0.05), dark, Vector3(80, 0, 25 * sx), 10)
		m.add("box", Vector3(0, 0.005, 0.0), Vector3(0.05, 0.04, 0.03), fg)
		_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, -0.085, 0.11)))
	elif fs == "goggles":
		var m = MB.new()
		m.add("cyl", Vector3(0, 0, 0), Vector3(hw * 1.14, 0.022, hd * 1.08), dark, Vector3.ZERO, 20)
		for sx in [-1.0, 1.0]:
			m.add("cyl", Vector3(0.036 * sx, 0, hd * 0.54 + 0.005), Vector3(0.05, 0.022, 0.05), steel, Vector3(90, 0, 0), 12)
			m.add("cyl", Vector3(0.036 * sx, 0, hd * 0.54 + 0.017), Vector3(0.04, 0.004, 0.04), fg, Vector3(90, 0, 0), 12)
		var gy = (eyes_mesh.get_aabb().get_center().y + 0.055) if eyes_mesh else hc.y + 0.05
		_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hcen.x, gy, hcen.z)))
	# --- sırt / bel
	var bc: Color = look.get("backc", Color(0.4, 0.33, 0.22)) if look.get("backc") != null else Color(0.4, 0.33, 0.22)
	match (null if sf_back else look.get("back_item")):
		"parsomen":
			var m = MB.new()
			m.add("cyl", Vector3.ZERO, Vector3(0.13, 0.62, 0.13), bc, Vector3(0, 0, 90), 12)
			for sx in [-1.0, 1.0]:
				m.add("cyl", Vector3(0.32 * sx, 0, 0), Vector3(0.15, 0.03, 0.15), Color(0.55, 0.12, 0.12), Vector3(0, 0, 90), 12)
			m.add("box", Vector3(0, 0.0, 0.05), Vector3(0.04, 0.5, 0.01), dark, Vector3(0, 0, 40))
			_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis(Vector3.BACK, deg_to_rad(-12)), ch + Vector3(0, -0.12, -0.2)))
		"shuriken":
			var m = MB.new()
			for k in 4:
				m.add("box", Vector3(0, 0, 0), Vector3(0.09, 0.62, 0.012), bc, Vector3(0, 0, 45 * k), 4)
			m.add("cyl", Vector3.ZERO, Vector3(0.1, 0.03, 0.1), dark, Vector3(90, 0, 0), 10)
			_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis.IDENTITY, ch + Vector3(0, -0.08, -0.19)))
		"kin":
			var m = MB.new()
			m.add("box", Vector3(0, -0.15, 0), Vector3(0.05, 0.75, 0.03), bc)
			m.add("cyl", Vector3(0, 0.3, 0), Vector3(0.035, 0.2, 0.035), dark, Vector3.ZERO, 8)
			m.add("cyl", Vector3(0, 0.2, 0), Vector3(0.08, 0.012, 0.08), Color(0.55, 0.45, 0.25), Vector3.ZERO, 10)
			m.add("box", Vector3(0, -0.02, 0.03), Vector3(0.6, 0.03, 0.008), Color(0.3, 0.22, 0.15), Vector3(0, 0, 50))
			_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis(Vector3.BACK, deg_to_rad(35)), ch + Vector3(0, -0.12, -0.17)))
		"canta":
			var m = MB.new()
			m.add("box", Vector3(0, 0, 0), Vector3(0.28, 0.32, 0.12), bc)
			m.add("box", Vector3(0, -0.06, 0.065), Vector3(0.2, 0.12, 0.03), bc.darkened(0.2))
			m.add("cyl", Vector3(0, 0.2, 0), Vector3(0.09, 0.34, 0.09), Color(0.55, 0.15, 0.15), Vector3(0, 0, 90), 10)
			_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis.IDENTITY, ch + Vector3(0, -0.15, -0.2)))
		"kemer":
			var m = MB.new()
			for k in 4:
				var a = deg_to_rad(-60 + k * 40)
				m.add("box", Vector3(sin(a) * 0.17, 0, cos(a) * 0.13), Vector3(0.06, 0.07, 0.045), bc, Vector3(0, rad_to_deg(a), 0))
			m.add("cyl", Vector3(0.16, -0.02, -0.05), Vector3(0.05, 0.16, 0.05), Color(0.85, 0.8, 0.65), Vector3(0, 0, 10), 8)
			_mesh_on("Hips", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hip + Vector3(0, 0.07, 0)))
	# --- yelek detayları (köy tarzı)
	if look["vest"] != null:
		var vc: Color = look["vest"]
		var vs = int(look.get("vest_style", 0))
		var m = MB.new()
		match vs:
			1:  # Suna: omuzdan çapraz kayış
				m.add("box", Vector3(0, -0.12, 0.165), Vector3(0.05, 0.62, 0.015), vc.darkened(0.3), Vector3(0, 0, -38))
				m.add("box", Vector3(0, -0.12, -0.165), Vector3(0.05, 0.62, 0.015), vc.darkened(0.3), Vector3(0, 0, 38))
			3:  # Kumo: tek askı
				m.add("box", Vector3(0.1, 0.12, 0.0), Vector3(0.07, 0.025, 0.3), vc.darkened(0.15))
			5, 6:  # ANBU / samuray: omuzluklar
				for sx in [-1.0, 1.0]:
					m.add("hemi", Vector3(0.2 * sx, 0.1, 0.0), Vector3(0.15, 0.08, 0.16), vc.darkened(0.1), Vector3(0, 0, -25 * sx), 10)
					if vs == 6:
						m.add("box", Vector3(0.22 * sx, 0.03, 0.0), Vector3(0.12, 0.05, 0.16), vc.darkened(0.25), Vector3(0, 0, -30 * sx))
		if not m.is_empty():
			_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis.IDENTITY, ch))
	# --- eldiven plakası
	if look.get("gloves", false):
		var ac: Color = look.get("acc", dark) if look.get("acc") != null else dark
		for side in ["Left", "Right"]:
			var sx = 1.0 if side == "Left" else -1.0
			var hp = _bp(side + "Hand")
			var m = MB.new()
			m.add("box", Vector3(0.04 * sx, 0.028, 0.0), Vector3(0.07, 0.008, 0.06), steel)
			_mesh_on(side + "Hand", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hp))


## Yaka, fermuar, bel bağı
func _cloth_details() -> void:
	var ts = top_style()
	_sandals()
	var neck = skel.find_bone("Neck")
	if neck >= 0 and ts in ["yakali", "ceket"] and look["vest"] == null:
		var np = _grest(neck).origin
		var c = MB.new()
		var cc: Color = look["top"] if ts == "yakali" else look["top2"]
		c.add("cyl", Vector3(0, 0.035, 0.0), Vector3(0.15, 0.12, 0.15), cc, Vector3.ZERO, 16)
		if ts == "ceket":
			c.add("box", Vector3(0, 0.03, 0.074), Vector3(0.012, 0.09, 0.006), Color(0.85, 0.85, 0.85))
		_mesh_on("Neck", c.build(Props.toon()), Transform3D(Basis.IDENTITY, np))
	if ts == "ceket" and look["vest"] == null:
		var cb = skel.find_bone("UpperChest")
		if cb >= 0:
			var cp = _grest(cb).origin
			var z = MB.new()
			z.add("box", Vector3(0, -0.12, 0.13), Vector3(0.012, 0.42, 0.01), Color(0.85, 0.85, 0.85), Vector3(-6, 0, 0))
			_mesh_on("UpperChest", z.build(Props.toon()), Transform3D(Basis.IDENTITY, cp))
	# bel bağı (pantolon kemeri)
	var hb = skel.find_bone("Hips")
	if hb >= 0:
		var hp = _grest(hb).origin
		var w = MB.new()
		w.add("cyl", Vector3(0, 0.07, 0.0), Vector3(0.33, 0.07, 0.24), Color(look["pants"]).darkened(0.3), Vector3.ZERO, 16)
		_mesh_on("Hips", w.build(Props.toon()), Transform3D(Basis.IDENTITY, hp))


# ------------------------------------------------------------------ eklentiler (saç, bant, göz, çanta)
func _attach(bone: String, model_xf: Transform3D) -> BoneAttachment3D:
	var ba = BoneAttachment3D.new()
	ba.bone_name = bone
	skel.add_child(ba)
	var holder = Node3D.new()
	ba.add_child(holder)
	var bi = skel.find_bone(bone)
	var rest = _grest(bi)
	holder.transform = rest.affine_inverse() * model_xf
	return ba


func _mesh_on(bone: String, mesh: Mesh, model_xf: Transform3D) -> MeshInstance3D:
	var ba = _attach(bone, model_xf)
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	ba.get_child(0).add_child(mi)
	return mi


func _head_center() -> Vector3:
	if face_mi:
		return eye_center_model + Vector3(0, 0.03, -0.07)
	return _grest(skel.find_bone("Head")).origin + Vector3(0, 0.1, 0)


const HAIR_FILES := {
	"diken": "Hair_Buzzed", "kısa": "Hair_SimpleParted", "uzun": "Hair_Long",
	"atkuyruğu": "Hair_Buzzed", "kase": "Hair_Buzzed", "dağınık": "Hair_Buzzed",
	"ananas": "Hair_Buzzed", "topuz": "Hair_Buns", "ikiz_topuz": "Hair_Buzzed", "yele": "Hair_Buzzed", "kakul": "Hair_Buzzed",
	"geriye": "Hair_Buzzed", "orgu": "Hair_Buzzed", "mohikan": "Hair_Buzzed", "kel": "", "kirpik": "Hair_Buzzed", "kisa_kakul": "Hair_Buzzed",
}
## Saç stilleri (arayüzde gösterilen adlar)
const HAIR_STYLES := {"diken": "Dikenli", "dağınık": "Dağınık", "kase": "Kâse", "kısa": "Kısa", "uzun": "Uzun", "atkuyruğu": "At Kuyruğu",
	"ananas": "Ananas Topuz", "topuz": "Topuz", "ikiz_topuz": "İkiz Topuz", "yele": "Uzun Yele", "kakul": "Tek Göz Kâkül", "geriye": "Geriye Taranmış",
	"orgu": "Örgü", "mohikan": "Mohikan", "kirpik": "Kısa Kirpi", "kisa_kakul": "Kâküllü Kısa", "kel": "Kel"}
static var _scalp_cache := {}
static var _hair_cache := {}


## Saç tabanı modelinin sınırlarından kafa elipsoidini çıkarır (model uzayı)
func _scalp(file: String, hn: Node) -> AABB:
	if _scalp_cache.has(file):
		return _scalp_cache[file]
	var ab := AABB()
	var first = true
	for mi in hn.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.get_aabb()
		ab = b if first else ab.merge(b)
		first = false
	_scalp_cache[file] = ab
	return ab


## Anime saç tutamı: kökten uca incelen, kavisli, yassı baklava kesitli tüp
static func _clump(st: SurfaceTool, root: Vector3, d: Vector3, grav: Vector3, length: float, width: float, flat := 0.45) -> void:
	var segs = 5
	var side = d.cross(Vector3.UP)
	if side.length() < 0.1:
		side = d.cross(Vector3.FORWARD)
	side = side.normalized()
	var rings = []
	for k in segs + 1:
		var t = float(k) / segs
		var p = root + d * length * t + grav * length * t * t
		var tan = (d + grav * 2.0 * t).normalized()
		var sd = (side - tan * side.dot(tan)).normalized()
		var up = tan.cross(sd).normalized()
		var w = width * pow(1.0 - t, 0.85)
		rings.append([p, sd * w, up * w * flat])
	for k in segs:
		var a = rings[k]; var b = rings[k + 1]
		var ca = [a[0] + a[1], a[0] + a[2], a[0] - a[1], a[0] - a[2]]
		var cb = [b[0] + b[1], b[0] + b[2], b[0] - b[1], b[0] - b[2]]
		var shade_a = 0.55 + 0.45 * float(k) / segs
		var shade_b = 0.55 + 0.45 * float(k + 1) / segs
		for q in 4:
			var q2 = (q + 1) % 4
			for vv in [[ca[q], shade_a], [cb[q], shade_b], [cb[q2], shade_b], [ca[q], shade_a], [cb[q2], shade_b], [ca[q2], shade_a]]:
				st.set_color(Color(vv[1], vv[1], vv[1]))
				st.add_vertex(vv[0])


## Saç stili tutamları (kafa elipsoidi: merkez c, yarıçap r; +Z yüz)
static func _hair_clumps(style: String, c: Vector3, r: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(style)
	var at = func(yaw_deg: float, pitch_deg: float) -> Array:
		var yw = deg_to_rad(yaw_deg); var pt = deg_to_rad(pitch_deg)
		var n = Vector3(sin(yw) * sin(pt), cos(pt), cos(yw) * sin(pt))
		return [c + n * r * 0.92, n]
	var bangs = func(count: int, spread: float, length: float, width: float) -> void:
		for i in count:
			var yw = lerpf(-spread, spread, (float(i) + 0.5) / count) + rng.randf_range(-5, 5)
			var a = at.call(yw, 52.0 + rng.randf_range(-6, 6))
			var d = (a[1] * 0.45 + Vector3(0, -0.7, 0.35)).normalized()
			_clump(st, a[0], d, Vector3(0, -0.15, 0.1), length * rng.randf_range(0.85, 1.15), width)
	# saç örtüsü: kafa derisini yatık tutamlarla kapla (kel görünmesin)
	if style in ["diken", "dağınık", "kase", "atkuyruğu", "ananas", "ikiz_topuz", "yele", "kakul", "geriye", "orgu", "kirpik", "kisa_kakul"]:
		for row in [[8.0, 5], [30.0, 9], [55.0, 12], [80.0, 14], [98.0, 10]]:
			for i in row[1]:
				var yw = 360.0 * (float(i) + 0.5) / row[1] + row[0]
				var wy = wrapf(yw, -180.0, 180.0)
				if row[0] > 70.0 and absf(wy) < 60.0:
					continue  # alın/yüz açık
				var front_short = row[0] > 40.0 and absf(wy) < 70.0  # alın üstü: gözlere inmesin
				var a = at.call(yw, row[0])
				var n: Vector3 = a[1]
				var flow = (Vector3(0, -1.0, -0.4) - n * n.dot(Vector3(0, -1.0, -0.4)))
				if flow.length() < 0.05:
					flow = Vector3(0, -1, 0) - n * n.y
				var root = c + n * r * 0.86
				var ln = rng.randf_range(0.09, 0.12) * (0.7 if row[0] > 90.0 else 1.0)
				if front_short:
					ln = 0.045
				_clump(st, root, (flow.normalized() + n * 0.15).normalized(), -n * 0.2, ln, 0.08, 0.32)
	match style:
		"diken":
			for ring in [[15.0, 4], [45.0, 8], [78.0, 10], [108.0, 8]]:
				for i in ring[1]:
					var yw = 360.0 * (float(i) + 0.5) / ring[1] + ring[0] * 1.7 + rng.randf_range(-8, 8)
					var wy = wrapf(yw, -180.0, 180.0)
					if ring[0] > 70.0 and absf(wy) < 55.0:
						continue  # yüzün önü açık kalır
					var a = at.call(yw, ring[0])
					var d = (a[1] + Vector3(0, 0.05, -0.3)).normalized()
					_clump(st, a[0], d, Vector3(0, -0.12, -0.08), rng.randf_range(0.11, 0.16), rng.randf_range(0.065, 0.08))
			bangs.call(5, 50.0, 0.11, 0.045)
		"dağınık":
			for i in 14:
				var yw = rng.randf_range(100, 260); var pt = rng.randf_range(20, 105)
				var a = at.call(yw, pt)
				var d = (a[1] + Vector3(0, 0.45, -0.5)).normalized()
				_clump(st, a[0], d, Vector3(0, 0.1, -0.15), rng.randf_range(0.12, 0.18), 0.06)
			for i in 9:  # ön tepe: yukarı/geriye kalkık (yüzü kapatmaz)
				var a = at.call(rng.randf_range(-70, 70), rng.randf_range(8, 38))
				_clump(st, a[0], (a[1] + Vector3(0, 0.5, -0.35)).normalized(), Vector3(0, -0.1, -0.05), 0.11, 0.06)
			for sx in [-1.0, 1.0]:  # yüzü çerçeveleyen perçemler (yüzü kapatmaz, şakaktan iner)
				var a = at.call(80.0 * sx, 70.0)
				_clump(st, a[0], Vector3(0.25 * sx, -1, 0.1).normalized(), Vector3(0.03 * sx, -0.1, 0.0), 0.15, 0.04)
			bangs.call(3, 30.0, 0.075, 0.04)
		"kase":
			for ring in [[25.0, 10], [55.0, 16], [85.0, 20]]:
				for i in ring[1]:
					var yw = 360.0 * (float(i) + 0.5) / ring[1]
					var a = at.call(yw, ring[0])
					var front = absf(wrapf(yw, -180.0, 180.0)) < 70.0
					if front and ring[0] > 70.0:
						continue
					var d = (a[1] * 0.35 + Vector3(0, -1, 0)).normalized()
					var ln = 0.07 if front else 0.13
					if ring[0] < 50.0:
						ln = 0.14
					_clump(st, a[0], d, a[1] * 0.08, ln, 0.07, 0.35)
		"atkuyruğu":
			var tie = c + Vector3(0, r.y * 0.55, -r.z * 0.95)
			for i in 14:
				var a = at.call(rng.randf_range(-150, 150), rng.randf_range(15, 95))
				var to = (tie - a[0])
				_clump(st, a[0], to.normalized(), Vector3.ZERO, to.length() * 1.05, 0.06, 0.3)
			for i in 7:
				var d = Vector3(rng.randf_range(-0.25, 0.25), -0.35, -1).normalized()
				_clump(st, tie, d, Vector3(0, -0.9, 0.05), rng.randf_range(0.26, 0.36), 0.06)
			bangs.call(4, 45.0, 0.1, 0.045)
		"ananas":  # tepede toplanmış dik, sivri at kuyruğu
			var tie = c + Vector3(0, r.y * 0.85, -r.z * 0.75)
			for i in 12:
				var a = at.call(rng.randf_range(-160, 160), rng.randf_range(25, 100))
				var to = tie - a[0]
				_clump(st, a[0], to.normalized(), Vector3.ZERO, to.length() * 1.05, 0.06, 0.3)
			for i in 9:
				var ang = TAU * i / 9.0
				var d = Vector3(cos(ang) * 0.45, 0.85, sin(ang) * 0.35 - 0.3).normalized()
				_clump(st, tie, d, Vector3(0, -0.15, -0.1), rng.randf_range(0.13, 0.18), 0.05)
			bangs.call(2, 30.0, 0.07, 0.04)
		"ikiz_topuz":
			for sx in [-1.0, 1.0]:
				var bun = c + Vector3(r.x * 0.75 * sx, r.y * 0.85, -r.z * 0.1)
				for i in 10:
					var ang = TAU * i / 10.0
					var d = Vector3(cos(ang), sin(ang) * 0.6 + 0.3, sin(ang) * 0.8).normalized()
					_clump(st, bun - d * 0.03, d.cross(Vector3.UP).normalized(), Vector3.ZERO, 0.08, 0.06, 0.6)
			bangs.call(5, 50.0, 0.08, 0.045)
		"yele":  # omuzlara inen dağınık uzun yele
			for i in 22:
				var a = at.call(rng.randf_range(70, 290), rng.randf_range(40, 110))
				var d = (a[1] * 0.4 + Vector3(0, -1, -0.2)).normalized()
				_clump(st, a[0], d, Vector3(rng.randf_range(-0.1, 0.1), -0.2, -0.1), rng.randf_range(0.25, 0.4), 0.07)
			for i in 8:
				var a = at.call(rng.randf_range(-60, 60), rng.randf_range(10, 50))
				_clump(st, a[0], (a[1] + Vector3(0, 0.3, -0.2)).normalized(), Vector3(0, -0.2, 0), 0.12, 0.06)
			bangs.call(5, 55.0, 0.11, 0.045)
		"kakul":  # tek gözü kapatan uzun kâkül
			var a = at.call(-25.0, 58.0)
			_clump(st, a[0], Vector3(-0.35, -0.9, 0.25).normalized(), Vector3(-0.05, -0.1, 0.05), 0.2, 0.09, 0.25)
			bangs.call(2, 15.0, 0.07, 0.045)
		"geriye":  # geriye taranmış, alın açık
			for i in 10:
				var a = at.call(rng.randf_range(-40, 40), rng.randf_range(20, 45))
				_clump(st, a[0], Vector3(0, 0.15, -1).normalized(), Vector3(0, -0.3, 0), 0.16, 0.08, 0.25)
		"topuz":  # tepe arkasında tek topuz
			var bun = c + Vector3(0, r.y * 0.75, -r.z * 0.55)
			for i in 14:
				var ang = TAU * i / 14.0
				var d = Vector3(cos(ang), sin(ang) * 0.7 + 0.25, sin(ang) * 0.7).normalized()
				_clump(st, bun - d * 0.035, d.cross(Vector3.UP).normalized(), Vector3.ZERO, 0.1, 0.075, 0.6)
			for i in 10:
				var a = at.call(rng.randf_range(-150, 150), rng.randf_range(20, 90))
				var to = bun - a[0]
				_clump(st, a[0], to.normalized(), Vector3.ZERO, to.length(), 0.06, 0.3)
		"orgu":  # ense arkasından inen tek örgü
			var top = c + Vector3(0, -r.y * 0.2, -r.z * 0.95)
			for k in 7:
				var pt = top + Vector3(0.012 * (1 if k % 2 == 0 else -1), -k * 0.06, -0.01 * k)
				_clump(st, pt, Vector3(0.3 * (1 if k % 2 == 0 else -1), -1, -0.1).normalized(), Vector3.ZERO, 0.08, 0.055, 0.7)
			bangs.call(4, 45.0, 0.09, 0.045)
		"mohikan":
			for i in 9:
				var a = at.call(180.0, -40.0 + i * 15.0) if i < 3 else at.call(0.0, 80.0 - (i - 3) * 16.0)
				_clump(st, a[0], (a[1] + Vector3(0, 0.4, 0)).normalized(), Vector3(0, 0, -0.05), 0.15, 0.06, 0.4)
		"kirpik":  # kısa sivri kirpi saç
			for i in 30:
				var a = at.call(rng.randf_range(-180, 180), rng.randf_range(0, 95))
				_clump(st, a[0], a[1], Vector3.ZERO, rng.randf_range(0.04, 0.06), 0.035)
		"kisa_kakul":  # kısa saç, düz kesik kâkül
			bangs.call(9, 65.0, 0.085, 0.045)
		"uzun":
			bangs.call(5, 50.0, 0.12, 0.045)
		"kısa":
			bangs.call(3, 30.0, 0.07, 0.04)
	st.generate_normals()
	return st.commit()


func _attachments() -> void:
	var hc = _head_center()
	var female: bool = look["gender"] == "f"
	var hair_col: Color = look["hair"]
	# gözler ve saç: _face_and_hair (VRoid)
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
	# --- alın koruyucu
	if look["band"] != null and look["band_style"] != "none":
		var band = MB.new()
		var bc: Color = look["band"]
		if look["band_style"] == "neck":
			band.add("torus", Vector3.ZERO, Vector3(0.24, 0.24, 0.24), bc, Vector3.ZERO, 16)
			_mesh_on("Neck", band.build(Props.toon()), Transform3D(Basis.IDENTITY, _grest(skel.find_bone("Neck")).origin + Vector3(0, 0.03, 0)))
		else:
			if band_ring.is_empty():
				band.add("cyl", Vector3.ZERO, Vector3(0.2, 0.034, 0.21), bc, Vector3.ZERO, 22)
				_mesh_on("Head", band.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, 0.025, 0)))
			else:
				var bm = _band_mesh(bc)
				var bmi = _mesh_on("Head", bm[0], Transform3D.IDENTITY)
				bmi.material_override = Props.toon()
				var plate: Vector3 = bm[1]
				var pl = MB.new()
				pl.add("box", plate, Vector3(0.07, 0.03, 0.006), Color(0.8, 0.82, 0.86))
				# arkada sarkan bağ uçları
				var bz = skull_c.z - (plate.z - skull_c.z) - 0.005
				pl.add("box", Vector3(-0.01, plate.y - 0.03, bz), Vector3(0.016, 0.07, 0.005), bc, Vector3(20, 0, 8))
				pl.add("box", Vector3(0.01, plate.y - 0.03, bz), Vector3(0.016, 0.07, 0.005), bc, Vector3(20, 0, -10))
				_mesh_on("Head", pl.build(Props.toon()), Transform3D.IDENTITY)
				var q = QuadMesh.new()
				q.size = Vector2(0.058, 0.023)
				var sm = StandardMaterial3D.new()
				sm.albedo_texture = symbol_texture(look["village"], look["band_style"] == "slashed")
				sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				q.material = sm
				_mesh_on("Head", q, Transform3D(Basis.IDENTITY, plate + Vector3(0, 0, 0.0035)))
	# --- yelek: kumaş katmanına boyanır; üstüne sadece yaka + parşömen cepleri
	if look["vest"] != null:
		var v = MB.new()
		var vc: Color = look["vest"]
		var ch = _grest(skel.find_bone("UpperChest")).origin
		v.add("torus", Vector3(0, 0.15, -0.005), Vector3(0.3, 0.3, 0.28), vc.darkened(0.1), Vector3.ZERO, 14)
		for sx in [-1.0, 1.0]:
			for k in 2:
				v.add("box", Vector3(0.075 * sx, -0.08 - k * 0.09, 0.17), Vector3(0.075, 0.085, 0.04), vc.darkened(0.15))
		_mesh_on("UpperChest", v.build(Props.toon()), Transform3D(Basis.IDENTITY, ch))
	# --- eldeki silahlar (ekipman: sağ el / sol el)
	for pair in [["weapon_r", "Right"], ["weapon_l", "Left"]]:
		var wid = look.get(pair[0])
		if wid == null or wid == "":
			continue
		var hb = skel.find_bone(pair[1] + "Hand")
		if hb < 0:
			continue
		var hp = _grest(hb).origin
		var sx = 1.0 if pair[1] == "Left" else -1.0
		var wxf = Transform3D(Basis.IDENTITY, hp + Vector3(0.075 * sx, -0.015, 0.01))
		var wn = SFProps.weapon_node(String(wid))  # hayran modeli varsa (yoksa prosedürel)
		if wn:
			_attach(pair[1] + "Hand", wxf).get_child(0).add_child(wn)
		else:
			_mesh_on(pair[1] + "Hand", weapon_mesh(String(wid)), wxf)
	# --- çanta + kunai kılıfı
	var hip = _grest(skel.find_bone("Hips")).origin
	var pouch = MB.new()
	pouch.add("box", Vector3.ZERO, Vector3(0.14, 0.09, 0.07), Color(0.42, 0.33, 0.22))
	_mesh_on("Hips", pouch.build(Props.toon()), Transform3D(Basis.IDENTITY, hip + Vector3(0.0, 0.02, -0.14)))
	var th = _grest(skel.find_bone("RightUpperLeg")).origin
	var holster = MB.new()
	holster.add("box", Vector3.ZERO, Vector3(0.05, 0.12, 0.1), Color(0.12, 0.12, 0.14))
	holster.add("box", Vector3(0, 0.07, 0), Vector3(0.06, 0.02, 0.11), Color(0.85, 0.85, 0.85))
	_mesh_on("RightUpperLeg", holster.build(Props.toon()), Transform3D(Basis.IDENTITY, th + Vector3(-0.11, -0.16, 0.0)))


## Silah modeli: kabza başlangıçta, namlu +Z yönünde
static var _weapon_cache := {}
static func weapon_mesh(id: String) -> ArrayMesh:
	if _weapon_cache.has(id):
		return _weapon_cache[id]
	var b = MB.new()
	var steel = Color(0.72, 0.75, 0.8)
	var dark = Color(0.12, 0.12, 0.14)
	var wrap = Color(0.85, 0.82, 0.75)
	match id:
		"kunai":
			b.add("cyl", Vector3(0, 0, -0.02), Vector3(0.022, 0.1, 0.022), wrap, Vector3(90, 0, 0), 6)
			b.add("torus", Vector3(0, 0, -0.085), Vector3(0.05, 0.05, 0.05), dark, Vector3(90, 0, 0), 8)
			b.add("sphere", Vector3(0, 0, 0.1), Vector3(0.05, 0.012, 0.17), steel, Vector3.ZERO, 6)
		"tanto":
			b.add("cyl", Vector3(0, 0, -0.03), Vector3(0.03, 0.13, 0.03), dark, Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.04), Vector3(0.07, 0.05, 0.012), Color(0.6, 0.5, 0.3))
			b.add("box", Vector3(0, 0, 0.2), Vector3(0.012, 0.035, 0.3), steel)
			b.add("cone", Vector3(0, 0, 0.36), Vector3(0.012, 0.03, 0.035), steel, Vector3(90, 0, 0), 4)
		"katana":
			b.add("cyl", Vector3(0, 0, -0.06), Vector3(0.032, 0.24, 0.032), dark, Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.065), Vector3(0.09, 0.012, 0.09), Color(0.55, 0.45, 0.25), Vector3(90, 0, 0), 12)
			b.add("box", Vector3(0, 0.005, 0.42), Vector3(0.01, 0.034, 0.7), steel, Vector3(-3, 0, 0))
			b.add("cone", Vector3(0, 0.025, 0.79), Vector3(0.01, 0.06, 0.034), steel, Vector3(87, 0, 0), 4)
		"musta":
			b.add("box", Vector3(0.0, 0.0, 0.0), Vector3(0.03, 0.1, 0.12), dark)
			b.add("box", Vector3(0, 0, 0.16), Vector3(0.01, 0.03, 0.2), steel)
		"tonfa":
			b.add("cyl", Vector3(0, 0, 0), Vector3(0.03, 0.1, 0.03), Color(0.35, 0.25, 0.15), Vector3(90, 0, 0), 6)
			b.add("cyl", Vector3(0, -0.04, -0.05), Vector3(0.035, 0.45, 0.035), Color(0.3, 0.22, 0.14), Vector3(90, 0, 0), 8)
		"yelpaze":
			b.add("cyl", Vector3(0, 0, 0), Vector3(0.03, 0.18, 0.03), dark, Vector3(90, 0, 0), 6)
			b.add("box", Vector3(0, 0, 0.42), Vector3(0.02, 0.16, 0.66), Color(0.85, 0.82, 0.75))
			b.add("box", Vector3(0, 0, 0.42), Vector3(0.026, 0.03, 0.66), Color(0.6, 0.15, 0.15))
		"altin_kunai", "patlayici_kunai", "zincirli_kunai":
			var bl = Color(0.85, 0.7, 0.3) if id == "altin_kunai" else steel
			b.add("cyl", Vector3(0, 0, -0.02), Vector3(0.022, 0.1, 0.022), wrap if id != "altin_kunai" else dark, Vector3(90, 0, 0), 6)
			b.add("torus", Vector3(0, 0, -0.085), Vector3(0.05, 0.05, 0.05), dark, Vector3(90, 0, 0), 8)
			b.add("sphere", Vector3(0, 0, 0.1), Vector3(0.05, 0.012, 0.17), bl, Vector3.ZERO, 6)
			if id == "patlayici_kunai":
				b.add("box", Vector3(0, 0.0, -0.02), Vector3(0.04, 0.03, 0.1), Color(0.95, 0.92, 0.82))
				b.add("box", Vector3(0, 0.016, -0.02), Vector3(0.012, 0.002, 0.07), Color(0.75, 0.1, 0.1))
			if id == "zincirli_kunai":
				for k in 6:
					b.add("torus", Vector3(0, -0.02 - k * 0.035, -0.11 - k * 0.012), Vector3(0.03, 0.03, 0.03), dark, Vector3(90 * (k % 2), 0, 0), 6)
		"senbon":
			for k in 3:
				b.add("cyl", Vector3((k - 1) * 0.018, 0, 0.06), Vector3(0.004, 0.2, 0.004), steel, Vector3(90, (k - 1) * 8.0, 0), 4)
		"ikiz_hancer":
			b.add("cyl", Vector3(0, 0, -0.03), Vector3(0.028, 0.11, 0.028), Color(0.35, 0.22, 0.15), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.03), Vector3(0.08, 0.02, 0.015), steel)
			b.add("box", Vector3(0, 0, 0.14), Vector3(0.01, 0.04, 0.2), steel)
			b.add("cone", Vector3(0, 0, 0.26), Vector3(0.01, 0.045, 0.04), steel, Vector3(90, 0, 0), 4)
		"kama":
			b.add("cyl", Vector3(0, 0, 0.02), Vector3(0.03, 0.26, 0.03), Color(0.45, 0.32, 0.2), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0.07, 0.14), Vector3(0.01, 0.15, 0.03), steel, Vector3(-20, 0, 0))
			b.add("box", Vector3(0, 0.13, 0.09), Vector3(0.01, 0.025, 0.1), steel, Vector3(30, 0, 0))
		"pence":
			b.add("box", Vector3(0, 0.0, 0.0), Vector3(0.09, 0.03, 0.08), dark)
			for k in 3:
				b.add("cone", Vector3((k - 1) * 0.03, 0.0, 0.12), Vector3(0.012, 0.18, 0.006), steel, Vector3(90, 0, 0), 4)
		"chakra_bicak":
			var glow = Color(0.55, 0.8, 1.0)
			b.add("box", Vector3(0.0, 0.0, 0.0), Vector3(0.03, 0.1, 0.11), dark)
			b.add("box", Vector3(0, 0.0, 0.17), Vector3(0.012, 0.04, 0.24), glow)
			b.add("box", Vector3(0, 0.0, 0.17), Vector3(0.02, 0.06, 0.2), glow.lightened(0.45))
		"wakizashi":
			b.add("cyl", Vector3(0, 0, -0.05), Vector3(0.03, 0.16, 0.03), dark, Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.04), Vector3(0.075, 0.012, 0.075), Color(0.55, 0.45, 0.25), Vector3(90, 0, 0), 12)
			b.add("box", Vector3(0, 0.004, 0.3), Vector3(0.01, 0.032, 0.5), steel, Vector3(-3, 0, 0))
			b.add("cone", Vector3(0, 0.018, 0.57), Vector3(0.01, 0.05, 0.032), steel, Vector3(87, 0, 0), 4)
		"nodachi":
			b.add("cyl", Vector3(0, 0, -0.12), Vector3(0.036, 0.36, 0.036), dark, Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.08), Vector3(0.12, 0.06, 0.02), Color(0.55, 0.45, 0.25))
			b.add("box", Vector3(0, 0.006, 0.7), Vector3(0.014, 0.06, 1.2), steel, Vector3(-2, 0, 0))
			b.add("cone", Vector3(0, 0.03, 1.33), Vector3(0.014, 0.1, 0.06), steel, Vector3(88, 0, 0), 4)
		"savas_cekici":
			b.add("cyl", Vector3(0, 0, 0.25), Vector3(0.035, 0.95, 0.035), Color(0.35, 0.25, 0.15), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.72), Vector3(0.14, 0.24, 0.16), Color(0.4, 0.4, 0.42))
			b.add("box", Vector3(0, 0, 0.72), Vector3(0.16, 0.06, 0.18), dark)
		"bo":
			b.add("cyl", Vector3(0, 0, 0.1), Vector3(0.036, 1.7, 0.036), Color(0.45, 0.32, 0.2), Vector3(90, 0, 0), 8)
			for z in [-0.72, 0.92]:
				b.add("cyl", Vector3(0, 0, z), Vector3(0.042, 0.08, 0.042), dark, Vector3(90, 0, 0), 8)
		"mizrak":
			b.add("cyl", Vector3(0, 0, 0.2), Vector3(0.032, 1.8, 0.032), Color(0.35, 0.22, 0.15), Vector3(90, 0, 0), 8)
			b.add("cone", Vector3(0, 0, 1.2), Vector3(0.05, 0.24, 0.012), steel, Vector3(90, 0, 0), 4)
			b.add("cyl", Vector3(0, 0, 1.07), Vector3(0.045, 0.04, 0.045), Color(0.6, 0.15, 0.15), Vector3(90, 0, 0), 8)
		"kusarigama":
			b.add("cyl", Vector3(0, 0, 0.02), Vector3(0.03, 0.3, 0.03), Color(0.45, 0.32, 0.2), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0.09, 0.16), Vector3(0.01, 0.2, 0.035), steel, Vector3(-25, 0, 0))
			for k in 9:
				b.add("torus", Vector3(0.0, -0.02 - k * 0.04, -0.12 - k * 0.01), Vector3(0.03, 0.03, 0.03), dark, Vector3(90 * (k % 2), 0, 0), 6)
			b.add("sphere", Vector3(0, -0.4, -0.22), Vector3(0.06, 0.06, 0.06), dark, Vector3.ZERO, 8)
		"el_shuriken":
			b.add("cyl", Vector3(0, 0, 0), Vector3(0.03, 0.12, 0.03), dark, Vector3(90, 0, 0), 6)
			for k in 4:
				b.add_xf("box", Transform3D(Basis(Vector3.BACK, deg_to_rad(45.0 + 90.0 * k)) * Basis.from_scale(Vector3(0.09, 0.62, 0.012)), Vector3(0, 0, 0.3)), Color(0.5, 0.52, 0.56))
			b.add("cyl", Vector3(0, 0, 0.3), Vector3(0.11, 0.03, 0.11), dark, Vector3(90, 0, 0), 10)
		"kubikiribocho":
			b.add("cyl", Vector3(0, 0, -0.1), Vector3(0.04, 0.34, 0.04), Color(0.35, 0.25, 0.18), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, -0.05, 0.12), Vector3(0.03, 0.12, 0.08), dark)
			# geniş satır ağzı, uçta yuvarlak delik (çerçeve parçalarıyla), sırtta boyun çentiği
			b.add("box", Vector3(0, -0.12, 0.62), Vector3(0.02, 0.36, 0.9), steel)
			b.add("box", Vector3(0, -0.02, 1.2), Vector3(0.02, 0.16, 0.26), steel)
			b.add("box", Vector3(0, -0.27, 1.2), Vector3(0.02, 0.06, 0.26), steel)
			b.add("box", Vector3(0, -0.12, 1.36), Vector3(0.02, 0.36, 0.06), steel)
			b.add("torus", Vector3(0, -0.15, 1.2), Vector3(0.2, 0.2, 0.2), steel.darkened(0.15), Vector3(0, 0, 90), 14)
			b.add("cyl", Vector3(0, -0.3, 0.45), Vector3(0.1, 0.024, 0.1), dark, Vector3(0, 0, 90), 12)
		"samehada":
			b.add("cyl", Vector3(0, 0, -0.1), Vector3(0.045, 0.34, 0.045), Color(0.85, 0.82, 0.75), Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.62), Vector3(0.2, 1.05, 0.13), Color(0.25, 0.32, 0.5), Vector3(90, 0, 0), 10)
			for k in 14:
				var a = k * 2.4
				b.add("cone", Vector3(cos(a) * 0.09, sin(a) * 0.06, 0.2 + k * 0.065), Vector3(0.035, 0.06, 0.035), Color(0.2, 0.26, 0.42), Vector3(rad_to_deg(a), 0, 90), 4)
			for z in [0.25, 0.55, 0.85]:
				b.add("cyl", Vector3(0, 0, z), Vector3(0.215, 0.05, 0.145), Color(0.92, 0.9, 0.85), Vector3(90, 0, 0), 10)
		"kiba":
			b.add("cyl", Vector3(0, 0, -0.05), Vector3(0.03, 0.16, 0.03), dark, Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0.0, 0.42), Vector3(0.014, 0.07, 0.72), Color(0.6, 0.65, 0.72))
			for k in 7:
				b.add("cone", Vector3(0, 0.045, 0.12 + k * 0.1), Vector3(0.012, 0.05, 0.04), Color(0.95, 0.88, 0.4), Vector3(0, 0, 0), 4)
			b.add("box", Vector3(0, 0.0, 0.42), Vector3(0.022, 0.025, 0.74), Color(1.0, 0.95, 0.5))
		"hiramekarei":
			for sx in [-1.0, 1.0]:
				b.add("cyl", Vector3(0.045 * sx, 0, -0.08), Vector3(0.03, 0.3, 0.03), Color(0.85, 0.82, 0.75), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.08), Vector3(0.14, 0.05, 0.04), dark)
			b.add("box", Vector3(0, 0, 0.62), Vector3(0.24, 0.025, 1.0), Color(0.3, 0.45, 0.75))
			b.add("cone", Vector3(0, 0, 1.17), Vector3(0.24, 0.12, 0.025), Color(0.3, 0.45, 0.75), Vector3(90, 0, 0), 4)
			for z in [0.3, 0.55, 0.8]:
				b.add("box", Vector3(0, 0, z), Vector3(0.25, 0.035, 0.05), Color(0.92, 0.9, 0.85))
		"shibuki":
			b.add("cyl", Vector3(0, 0, -0.08), Vector3(0.035, 0.28, 0.035), dark, Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.55), Vector3(0.025, 0.2, 0.85), steel)
			b.add("cyl", Vector3(0, 0.0, 0.55), Vector3(0.09, 0.82, 0.09), Color(0.85, 0.8, 0.65), Vector3(90, 0, 0), 10)
			for k in 6:
				b.add("box", Vector3(0, 0.05, 0.22 + k * 0.13), Vector3(0.1, 0.012, 0.06), Color(0.95, 0.92, 0.85))
				b.add("box", Vector3(0, 0.057, 0.22 + k * 0.13), Vector3(0.03, 0.004, 0.04), Color(0.8, 0.1, 0.1))
		"nuibari":
			b.add("cyl", Vector3(0, 0, -0.06), Vector3(0.035, 0.22, 0.035), Color(0.35, 0.22, 0.15), Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.7), Vector3(0.018, 1.4, 0.018), Color(0.8, 0.82, 0.86), Vector3(90, 0, 0), 6)
			b.add("cone", Vector3(0, 0, 1.45), Vector3(0.02, 0.1, 0.02), Color(0.8, 0.82, 0.86), Vector3(90, 0, 0), 6)
			b.add("torus", Vector3(0, -0.06, -0.15), Vector3(0.14, 0.14, 0.14), Color(0.75, 0.75, 0.8), Vector3(90, 0, 0), 12)
		"kabutowari":
			b.add("cyl", Vector3(0, 0, 0.15), Vector3(0.035, 0.6, 0.035), Color(0.35, 0.25, 0.15), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0.12, 0.42), Vector3(0.025, 0.26, 0.2), Color(0.45, 0.45, 0.48))
			b.add("cyl", Vector3(0, 0.25, 0.42), Vector3(0.21, 0.025, 0.21), Color(0.55, 0.55, 0.58), Vector3(0, 0, 90), 12)
			for k in 6:
				b.add("torus", Vector3(0, -0.04 - k * 0.04, -0.15 - k * 0.015), Vector3(0.03, 0.03, 0.03), dark, Vector3(90 * (k % 2), 0, 0), 6)
			b.add("cyl", Vector3(0, -0.3, -0.26), Vector3(0.11, 0.18, 0.11), Color(0.4, 0.4, 0.42), Vector3(0, 0, 90), 10)
		"chokuto":
			b.add("cyl", Vector3(0, 0, -0.08), Vector3(0.032, 0.22, 0.032), Color(0.85, 0.85, 0.85), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.04), Vector3(0.05, 0.05, 0.02), dark)
			b.add("box", Vector3(0, 0, 0.5), Vector3(0.012, 0.03, 0.88), Color(0.85, 0.87, 0.9))
			b.add("cone", Vector3(0, 0, 0.97), Vector3(0.012, 0.06, 0.03), Color(0.85, 0.87, 0.9), Vector3(90, 0, 0), 4)
		"raijin":
			b.add("cyl", Vector3(0, 0, -0.06), Vector3(0.035, 0.2, 0.035), Color(0.8, 0.65, 0.25), Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.05), Vector3(0.1, 0.02, 0.1), Color(0.85, 0.7, 0.3), Vector3(90, 0, 0), 10)
			b.add("box", Vector3(0, 0, 0.6), Vector3(0.02, 0.05, 1.05), Color(1.0, 0.95, 0.55))
			for k in 6:
				b.add("box", Vector3(0, (0.035 if k % 2 == 0 else -0.035), 0.2 + k * 0.17), Vector3(0.012, 0.05, 0.08), Color(1.0, 0.85, 0.2), Vector3(0, 0, 25 if k % 2 == 0 else -25))
		"ruzgar_bicak":
			b.add("box", Vector3(0.0, 0.0, 0.0), Vector3(0.03, 0.1, 0.11), dark)
			b.add("box", Vector3(0, 0.0, 0.17), Vector3(0.012, 0.04, 0.24), Color(0.6, 0.62, 0.66))
			b.add("cone", Vector3(0, 0.0, 0.42), Vector3(0.02, 0.32, 0.07), Color(0.6, 1.0, 0.8), Vector3(90, 0, 0), 4)
		"fuma_shuriken":
			b.add("cyl", Vector3(0, 0, 0), Vector3(0.03, 0.14, 0.03), dark, Vector3(90, 0, 0), 6)
			for k in 4:
				var bs = Basis(Vector3.BACK, deg_to_rad(90.0 * k))
				b.add_xf("box", Transform3D(bs * Basis.from_scale(Vector3(0.12, 0.48, 0.012)), Vector3(0, 0, 0.5) + bs * Vector3(0, 0.26, 0)), Color(0.55, 0.57, 0.62))
				b.add_xf("cone", Transform3D(bs * Basis(Vector3.BACK, deg_to_rad(-30)) * Basis.from_scale(Vector3(0.12, 0.2, 0.012)), Vector3(0, 0, 0.5) + bs * Vector3(0.05, 0.55, 0)), Color(0.55, 0.57, 0.62), 4)
			b.add("cyl", Vector3(0, 0, 0.5), Vector3(0.16, 0.04, 0.16), dark, Vector3(90, 0, 0), 12)
		"gunbai":
			b.add("cyl", Vector3(0, 0, 0.12), Vector3(0.035, 0.4, 0.035), dark, Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.62), Vector3(0.62, 0.025, 0.72), Color(0.75, 0.15, 0.15), Vector3(0, 0, 90), 20)
			b.add("cyl", Vector3(0.016, 0, 0.62), Vector3(0.3, 0.012, 0.34), Color(0.95, 0.95, 0.95), Vector3(0, 0, 90), 16)
			b.add("torus", Vector3(0, 0, 0.62), Vector3(0.64, 0.64, 0.74), dark, Vector3(0, 0, 90), 20)
		_:
			b.add("box", Vector3(0, 0, 0.1), Vector3(0.02, 0.03, 0.2), steel)
	var m = b.build(Props.toon())
	_weapon_cache[id] = m
	return m


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


## Sağ/sol göz ayrı desen (sağ göz = karakterin sağı = model -X)
## Sennin modu görünümü: 0 yok, 1 kurbağa, 2 yılan, 3 sümüklüböcek (göz bebeği + yüz izleri)
func set_sage(kind: int) -> void:
	if eye_mat:
		eye_mat.set_shader_parameter("sage_eyes", kind)
	if body_mesh:
		var m = body_mesh.get_surface_override_material(0)
		if m is ShaderMaterial:
			m.set_shader_parameter("sage_marks", kind)


func set_dojutsu_eyes(kind_r: int, lvl_r: int, kind_l: int, lvl_l: int, veins := false) -> void:
	if eye_mat:
		eye_mat.set_shader_parameter("dojutsu", kind_r)
		eye_mat.set_shader_parameter("tomoe", lvl_r)
		eye_mat.set_shader_parameter("dojutsu_l", kind_l)
		eye_mat.set_shader_parameter("tomoe_l", lvl_l)
	if body_mesh:
		var m = body_mesh.get_surface_override_material(0)
		if m is ShaderMaterial:
			m.set_shader_parameter("byakugan_veins", 1.0 if veins else 0.0)


## Özel Mangekyō desenleri (Eyes.design_vecs ile)
func set_ms_designs(right: Dictionary, left: Dictionary) -> void:
	if eye_mat == null:
		return
	for pair in [[right, "r"], [left, "l"]]:
		if pair[0].is_empty():
			continue
		var v = Eyes.design_vecs(pair[0])
		eye_mat.set_shader_parameter("ms_%s_a" % pair[1], v[0])
		eye_mat.set_shader_parameter("ms_%s_b" % pair[1], v[1])
		eye_mat.set_shader_parameter("ms_col_%s" % pair[1], v[2])


## Göz tekniği görünümü: 0 yok, 1 sharingan, 2 byakugan, 3 ketsuryugan, 4 mangekyō
func set_dojutsu(kind: int, tomoe := 3) -> void:
	if eye_mat:
		eye_mat.set_shader_parameter("dojutsu", kind)
		eye_mat.set_shader_parameter("tomoe", tomoe)
	if body_mesh:
		var m = body_mesh.get_surface_override_material(0)
		if m is ShaderMaterial:
			m.set_shader_parameter("byakugan_veins", 1.0 if kind == 2 else 0.0)


func flash(amount: float) -> void:
	hit_flash = maxf(hit_flash, amount)


const STANCE_OF := {"blade": "w_blade", "dual": "w_dual", "sickle": "w_dual", "claw": "w_dual", "sword": "w_sword", "heavy": "w_shoulder", "staff": "w_shoulder", "chain": "w_shoulder", "fan": "w_fan"}
var stance := ""


func _stance_for_look() -> String:
	for k in ["weapon_r", "weapon_l"]:
		var wid = look.get(k)
		if wid != null and wid != "":
			var w: Dictionary = Gear.ITEMS.get(String(wid), {}).get("weapon", {})
			if not w.is_empty():
				return STANCE_OF.get(w.get("style", ""), "")
	return ""


func _process(dt: float) -> void:
	# silah duruşu: beklerken/yürürken silaha göre kollar; saldırı, mühür ve ninja koşusunda kapanır
	if stance != "" and overlay:
		var on = current in ["idle", "walk", "jog", "run", "air", "fall", "sword_idle"] and overlay.weights.get("ninja_run", 0.0) < 0.5 and overlay.weights.get("leap", 0.0) < 0.3
		overlay.set_pose(stance, 1.0 if on else 0.0)
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - dt * 5.0)
		for m in materials:
			m.set_shader_parameter("hit_flash", hit_flash)
