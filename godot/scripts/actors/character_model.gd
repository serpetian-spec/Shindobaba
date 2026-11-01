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
	# taban her zaman gerçek bir VRoid saçı (eski düz "buzz" başlık kel gibi görünüyordu); tutam eklentisi üstüne gelir
	"kısa": ["Sakurada_Fumiriya", "Hair001", ""], "diken": ["HairSample_Male", "Hair001", "diken"], "dağınık": ["HairSample_Male", "Hair001", "dağınık"],
	"kase": ["Sendagaya_Shibu", "Hair001", ""], "uzun": ["AvatarSample_B", "Hair001", ""], "atkuyruğu": ["AvatarSample_A", "Hair001", "atkuyruğu"],
	"kisa_kakul": ["AvatarSample_A", "Hair001", ""], "kakul": ["Darkness_Shibu", "Hair001", "kakul"], "geriye": ["Sakurada_Fumiriya", "Hair001", "geriye"],
	"ananas": ["HairSample_Male", "Hair001", "ananas"], "topuz": ["AvatarSample_A", "Hair001", "topuz"], "ikiz_topuz": ["AvatarSample_A", "Hair001", "ikiz_topuz"],
	"yele": ["AvatarSample_C", "Hair001", "yele"], "orgu": ["AvatarSample_A", "Hair001", "orgu"], "mohikan": ["masc_vroid", "Body", "mohikan"],
	"kirpik": ["Sakurada_Fumiriya", "Hair001", "kirpik"], "kel": ["", "", ""],
	# yeni stiller (karakter yaratma): taban saç + tutam eklentisi
	"dalgali": ["Darkness_Shibu", "Hair001", "dalgali"], "savas_yelesi": ["AvatarSample_C", "Hair001", "savas_yelesi"], "bilge_yelesi": ["HairSample_Male", "Hair001", "bilge_yelesi"], "yuksek_kuyruk": ["Sakurada_Fumiriya", "Hair001", "yuksek_kuyruk"],
	"yan_kuyruk": ["Sakurada_Fumiriya", "Hair001", "yan_kuyruk"], "ikiz_kuyruk": ["AvatarSample_A", "Hair001", "ikiz_kuyruk"],
	"ikiz_orgu": ["AvatarSample_A", "Hair001", "ikiz_orgu"], "samuray": ["masc_vroid", "Body", "samuray"],
	"savasci_kuyruk": ["masc_vroid", "Body", "savasci_kuyruk"], "alev": ["HairSample_Male", "Hair001", "alev"],
	"geriye_diken": ["HairSample_Male", "Hair001", "geriye_diken"], "yan_tarama": ["Sakurada_Fumiriya", "Hair001", "yan_tarama"],
	"perde": ["Sendagaya_Shibu", "Hair001", "perde"], "kabarik": ["HairSample_Male", "Hair001", "kabarik"],
	"ruzgar": ["AvatarSample_C", "Hair001", "ruzgar"], "yabani": ["HairSample_Male", "Hair001", "yabani"],
	"ense_kuyruk": ["Sakurada_Fumiriya", "Hair001", "ense_kuyruk"], "alcak_topuz": ["AvatarSample_A", "Hair001", "alcak_topuz"],
	"kazinmis": ["masc_vroid", "Body", ""], "yan_kazinmis": ["masc_vroid", "Body", "yan_kazinmis"],
	"golge": ["Darkness_Shibu", "Hair001", ""], "cerceve": ["AvatarSample_B", "Hair001", "cerceve"],
	"yan_orgu": ["Sendagaya_Shibu", "Hair001", "yan_orgu"], "bagli_uzun": ["AvatarSample_B", "Hair001", "bagli_uzun"],
	"tepe_diken": ["Sakurada_Fumiriya", "Hair001", "tepe_diken"], "yan_topuz": ["Sendagaya_Shibu", "Hair001", "yan_topuz"],
}
const VROID_SKIN := Color(0.99, 0.89, 0.82)  # VRoid doku ten rengi (oyuncu teni bununla oranlanır)
static var _scenes := {}
static var _donor_cache := {}
var face_mi: MeshInstance3D
var head_fix := Transform3D.IDENTITY
var eye_center_model := Vector3(0, 1.62, 0.08)
var eye_half := 0.032
var sclera_mat: ShaderMaterial = null
var face_skin_mat: ShaderMaterial = null   # yüz derisi (Byakugan damarları)   # göz akı (Rinnegan tüm gözü kaplar)
var _eye_trails: Array = []
var _outer_pad := 0.0   # dış giysi kabuğuna eklenen pay (yeleğin üstüne)
var _gdata: Dictionary = {}


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
const HAIR_SCALE := 1.0   # taban saç küçültülürse kafa derisi görünüyor (kel); sadece kafa oranına uydurulur
const CLUMP_SCALE := 1.0
const CLUMP_LEN := 0.82    # tutam uzunluğu: kökler kafada kalır, uçlar kısalır
const CLUMP_WID := 0.9
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
	var iris_c := [Vector3.ZERO, Vector3.ZERO, 0.02]   # model uzayında iki iris merkezi (x<0, x>0) + iris yarıçapı
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
			var cx = iris.get_center().x
			var sides = [[Vector3.ZERO, 0, 1e9, -1e9, 1e9, -1e9], [Vector3.ZERO, 0, 1e9, -1e9, 1e9, -1e9]]
			var uvb = [Rect2(), Rect2()]   # her gözün doku (UV) sınırları: desen irisle birlikte kayar (göz bakınca)
			var uvf = [true, true]
			for vi in gr["v"].size():
				var q: Vector3 = gr["v"][vi]
				var si = 0 if q.x < cx else 1
				var sd = sides[si]
				sd[0] += q; sd[1] += 1
				sd[2] = minf(sd[2], q.x); sd[3] = maxf(sd[3], q.x)
				sd[4] = minf(sd[4], q.y); sd[5] = maxf(sd[5], q.y)
				var uv: Vector2 = gr["uv"][vi]
				if uvf[si]:
					uvb[si] = Rect2(uv, Vector2.ZERO); uvf[si] = false
				else:
					uvb[si] = uvb[si].expand(uv)
			if sides[0][1] > 0 and sides[1][1] > 0:
				# merkez = sınır kutusunun ortası (köşe ortalaması kalabalık tarafa kayıyordu); yarıçap en/boy ayrı
				var c0 = Vector3((sides[0][2] + sides[0][3]) * 0.5, (sides[0][4] + sides[0][5]) * 0.5, (sides[0][0] / sides[0][1]).z)
				var c1 = Vector3((sides[1][2] + sides[1][3]) * 0.5, (sides[1][4] + sides[1][5]) * 0.5, (sides[1][0] / sides[1][1]).z)
				iris_c = [c0, c1, (sides[0][3] - sides[0][2]) * 0.5, (sides[0][5] - sides[0][4]) * 0.5, uvb[0], uvb[1]]
	inst.free()
	out = {"mesh": am, "mats": mats, "aabb": aabb, "iris": iris, "iris_c": iris_c}
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
				var ic2: Array = fd.get("iris_c", [])
				if ic2.size() >= 3:
					eye_mat.set_shader_parameter("eye_c_r", ic2[0])
					eye_mat.set_shader_parameter("eye_c_l", ic2[1])
					eye_mat.set_shader_parameter("iris_r3", ic2[2])
					eye_mat.set_shader_parameter("iris_r2", Vector2(ic2[2], ic2[3] if ic2.size() > 3 else ic2[2]))
				face_mi.set_surface_override_material(si, eye_mat)
				materials.append(eye_mat)
			elif mname.contains("SKIN"):
				var sm = ShaderMaterial.new()
				sm.shader = load("res://shaders/vroid_toon.gdshader")
				sm.set_shader_parameter("tex", tex)
				face_skin_mat = sm
				var ic4: Array = fd.get("iris_c", [])
				if ic4.size() >= 3:
					sm.set_shader_parameter("eye_c_r", ic4[0])
					sm.set_shader_parameter("eye_c_l", ic4[1])
					sm.set_shader_parameter("iris_r3", ic4[2])
				sm.set_shader_parameter("tint", ratio)
				face_mi.set_surface_override_material(si, sm)
				materials.append(sm)
			elif mname.contains("EyeWhite") and tex != null:
				sclera_mat = ShaderMaterial.new()
				sclera_mat.shader = load("res://shaders/vroid_sclera.gdshader")
				sclera_mat.set_shader_parameter("tex", tex)
				var ic3: Array = fd.get("iris_c", [])
				if ic3.size() >= 3:
					sclera_mat.set_shader_parameter("eye_c_r", ic3[0])
					sclera_mat.set_shader_parameter("eye_c_l", ic3[1])
					sclera_mat.set_shader_parameter("iris_r3", ic3[2])
				face_mi.set_surface_override_material(si, sclera_mat)
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
		if body_mesh and body_mesh.get_surface_override_material(0) is ShaderMaterial:
			body_mesh.get_surface_override_material(0).set_shader_parameter("scalp_cut", _scalp_cut())
		eye_half = clampf((place.basis * ir.size).abs().x * 0.3, 0.02, 0.045) if ir.size != Vector3.ZERO else 0.032
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
		# önbellek anahtarı kafa ölçüsüne bağlı (yaş/cinsiyet/yüz değişince saç kafada kalsın)
		var hk = "vroid|%s|%s|%s|%s" % [hd[2], look["gender"], donor, look.get("age", "adult")]
		if not _hair_cache.has(hk):
			_hair_cache[hk] = _hair_clumps(hd[2], skull_c, skull_r)
		var cm = ShaderMaterial.new()
		cm.shader = load("res://shaders/toon.gdshader")
		cm.set_shader_parameter("tint", look["hair"])
		cm.set_shader_parameter("rim_amount", 0.45)
		materials.append(cm)
		# tutamlar kafaya göre biraz küçültülür (kafa merkezi etrafında)
		var cs = Transform3D(Basis.IDENTITY, skull_c) * Transform3D(Basis.from_scale(Vector3.ONE * CLUMP_SCALE), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -skull_c)
		var cl = _mesh_on("Head", _hair_cache[hk], cs)
		cl.material_override = cm
	if hd[0] != "":
		var hp = _donor_part(hd[0], hd[1], "HAIR")
		if not hp.is_empty():
			var holder2 = _attach("Head", head_rest).get_child(0)
			var hair_mi = MeshInstance3D.new()
			hair_mi.name = "VHair"
			hair_mi.mesh = hp["mesh"]
			# saç bağışçısının kafası bizim yüz bağışçısından büyük/küçük olabilir: yüz genişliğine göre ölçekle + hafif küçült
			var hs = HAIR_SCALE
			var hc = Vector3.ZERO
			if hd[0] != donor:
				var hf = _donor_part(hd[0], "Face")
				if not hf.is_empty() and not fd.is_empty() and hf["aabb"].size.x > 0.01:
					hs *= clampf(fd["aabb"].size.x / hf["aabb"].size.x, 0.97, 1.2)
					hc = hf["aabb"].get_center()
			elif not fd.is_empty():
				hc = fd["aabb"].get_center()
			hair_mi.transform = head_fix * Transform3D(Basis.IDENTITY, hc) * Transform3D(Basis.from_scale(Vector3.ONE * hs), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -hc)
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
	overlay.key_weapon_cb = _key_blade_sk
	skel.add_child(overlay)
	rig = WeaponRig.new()   # overlay'den sonra: silahlı el yumruk, kın hareketi
	skel.add_child(rig)
	drawn = look.get("drawn", true)
	_place_weapons()
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
const AGES := {"child": [0.78, 1.1, 0.84, 0.82, 1.0], "teen": [0.87, 1.05, 0.91, 0.9, 1.0], "young": [0.94, 1.03, 0.97, 0.96, 1.0], "adult": [1.0, 1.0, 1.0, 1.0, 1.0]}
var age_scale = 1.0


## Yaşa göre boy, kafa oranı ve omuz genişliği
func apply_age(age: String) -> void:
	var a: Array = AGES.get(age, AGES["adult"])
	age_scale = a[0]
	look["age"] = age   # klonlar (bunshin) aynı yaşta çıksın
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


## Yürüme/koşu döngüsünde ayakların yere bastığı ilerleme oranları (tests/dbg_footphase.gd ile ölçüldü)
const FOOT_PHASES := {"walk": [0.05, 0.55], "jog": [0.0, 0.53], "run": [0.0, 0.5]}


## Önceki karedeki ilerlemeden bu kareye bir ayak teması geçildi mi
func footstep_cross(prev: float) -> bool:
	if prev < 0.0 or not FOOT_PHASES.has(current):
		return false
	var now = anim_progress()
	for ph in FOOT_PHASES[current]:
		if (now >= prev and prev < ph and now >= ph) or (now < prev and (prev < ph or now >= ph)):
			return true
	return false


func anim_progress() -> float:
	if anim.current_animation == "":
		return 1.0
	return anim.current_animation_position / maxf(0.01, anim.current_animation_length)


# ------------------------------------------------------------------ kıyafet (vücuttan türetilen kumaş katmanları)
## Bölge kodları: 0 ten, 10 omuz/üst kol, 11 göğüs, 12 bel, 13 ön kol, 14 bilek,
## 20 kalça, 21 uyluk, 22 baldır, 23 baldır altı, 30 ayak, 40 boyun
## Renk yuvaları (vertex COLOR.r = yuva * 0.1, toon shader palette_mode): 0 ten, 1 üst, 2 üst-vurgu, 3 alt, 4 sargı, 5 yelek
## Sıra shader'daki top_style / pants_style numaralarıyla aynı (sona ekle)
const TOP_STYLES := {"tisort": "Kısa Kollu Tişört", "uzun": "Uzun Kollu Ninja Gömleği", "ceket": "Fermuarlı Ceket", "yakali": "Yüksek Yakalı Gömlek", "kolsuz": "Kolsuz Yakalı", "kimono": "Kimono Üstü",
	"gi": "Dövüş Gi'si", "yakali_uzun": "Uzun Kollu Yüksek Yaka", "atlet": "Atlet", "tek_kol": "Tek Kollu Üst"}
const PANTS_STYLES := {"ninja": "Ninja Pantolonu", "sort": "Diz Altı Şort", "sivil": "Uzun Pantolon", "sargi": "Sargılı Pantolon", "bol": "Bol Paçalı Pantolon", "kapri": "Kapri", "kisa_sort": "Kısa Şort"}

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


## Ten rengini geçici boyar (Sekiz Kapı kızarması, lanet mührü...): k=0 normal, 1 = tamamen col
func set_skin_tint(col: Color, k: float) -> void:
	if body_mesh == null:
		return
	var pal = _palette()
	if k > 0.0:
		pal[0] = Color(pal[0]).lerp(col, clampf(k, 0.0, 1.0))
	var m = body_mesh.get_surface_override_material(0)
	if m is ShaderMaterial:
		m.set_shader_parameter("pal", pal)
	# yüz derisi ayrı malzeme (vroid): kendi tint'i aynı oranda boyanır, yoksa yüz normal kalıp göze batıyordu
	if face_skin_mat:
		if not face_skin_mat.has_meta("base_tint"):
			face_skin_mat.set_meta("base_tint", face_skin_mat.get_shader_parameter("tint"))
		var bt: Color = face_skin_mat.get_meta("base_tint")
		var target = Color(bt.r * col.r / maxf(0.01, Color(look["skin"]).r), bt.g * col.g / maxf(0.01, Color(look["skin"]).g), bt.b * col.b / maxf(0.01, Color(look["skin"]).b))
		face_skin_mat.set_shader_parameter("tint", bt.lerp(target, clampf(k, 0.0, 1.0)))


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
	mat.set_shader_parameter("pants_pattern", int(look.get("pants_pattern", 0)))
	mat.set_shader_parameter("pants_accent", look.get("pants2", Color(look.get("pants", Color(0.2, 0.2, 0.22))).darkened(0.45)))
	mat.set_shader_parameter("vest_style", int(look.get("vest_style", 0)))
	mat.set_shader_parameter("gloves", bool(look.get("gloves", false)))
	mat.set_shader_parameter("arm_wraps", bool(look.get("arm_wraps", false)))
	var os_ = String(look.get("outer_style", "")) if look.get("outer_style") != null else ""
	# yelek dış giysinin altında: önü açık giysilerde (haori, palto, jinbaori) yalnız açıklık kadarı görünür, kapalı pelerinde gizli
	const OPEN_GAP := {"haori": 0.031, "haori_uzun": 0.029, "jinbaori": 0.038, "palto": 0.025}
	mat.set_shader_parameter("outer_cover", 0 if os_ in ["", "atki", "kisa", "kesa"] else (1 if OPEN_GAP.has(os_) else 2))
	mat.set_shader_parameter("outer_gap", float(OPEN_GAP.get(os_, 0.075)))
	mat.set_shader_parameter("outer_sleeves", 1 if look.get("outer_style") in ["palto", "haori"] else 0)
	mat.set_shader_parameter("foot_cover", look.get("foot_style", "sandal") == "tabi")
	OutfitParts.mat_params(self, mat)
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
	# gövde mesh'inin kafa derisi saçın arasından taşıyordu: göz hizasının biraz üstünden yukarısı gizlenir (ön yüz VFace, tepe/arka saç)
	mat.set_shader_parameter("scalp_cut", _scalp_cut())
	# kesim bölgesi atılmaz, saç rengine boyanır: ense delik görünmez (arkası görünüyordu), saç arasından kel deri de görünmez
	if not look.get("hair_style", "") in ["kel", "mohikan"] and look.get("hair") is Color:
		mat.set_shader_parameter("scalp_col", look["hair"])
	materials.append(mat)
	return mat


## Gövde mesh'inin kafa derisi saçın altından taşmasın ("arkadan kel"): tepe göz hizasının üstü, arka kafa ense hizasının üstü gizlenir
func _scalp_cut() -> Vector4:
	if look.get("hair_style", "") in ["kel", "mohikan", "samuray", "savasci_kuyruk", "kazinmis", "yan_kazinmis"]:
		return Vector4(99, -99, 99, 0)
	return Vector4(eye_center_model.y + 0.02, eye_center_model.z - 0.065, eye_center_model.y - 0.055, 0)


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
	var short_sleeve = ts in ["tisort", "yakali", "gi"]
	var sleeve = (el + 0.05 if ts == "gi" else lerpf(ua, el, 0.5)) if short_sleeve else ha - 0.035
	var cut = {"ninja": knee - 0.17, "sort": knee - 0.05, "kapri": lerpf(knee, ank, 0.45), "kisa_sort": knee + 0.12}.get(ps, ank + 0.04)
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


func _add_shell(m: ArrayMesh, mat: ShaderMaterial) -> MeshInstance3D:
	if m == null:
		return null
	var shell = MeshInstance3D.new()
	shell.name = "Cloth"
	shell.mesh = m
	skel.add_child(shell)
	shell.skin = body_mesh.skin
	shell.skeleton = shell.get_path_to(skel)
	shell.material_override = mat
	return shell


var _strap_nodes: Array = []   # sırt kayışları (silah eldeyken gizlenir)


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
			"cizme", "yuksek_sandal", "bilek_bot", "diz_cizme", "sargili_bot", "zirhli_tozluk":
				ring_defs = OutfitParts.foot_rings(look["foot_style"], fp)
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
	# ızgarada komşu yok (kafanın üstü / uzak giysi köşesi): tüm köşelerde ara — yoksa 0. köşenin (bacak) ağırlığını alıp yere sarkar
	for i in v.size():
		var d = v[i].distance_squared_to(p)
		if d < bd:
			bd = d; best = i
	return maxi(best, 0)


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
			var p: Vector3 = centers[r] + dir * ((radii[r] as PackedFloat32Array)[k] + float(off.call(t, ang)) + _outer_pad)
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
	var k = "%s|%s|%.3f" % [look["gender"], key, _outer_pad]
	if not _garment_cache.has(k):
		_garment_cache[k] = build.call()
	if _garment_cache[k] != null:
		_add_shell(_garment_cache[k], cloth_shell_mat)


## Görünümdeki giysi katmanlarını kur
func _garments(g: Dictionary) -> void:
	var neck = _bp("Neck").y; var hips = _bp("Hips").y; var knee = _bp("LeftLowerLeg").y; var ank = _bp("LeftFoot").y
	var chest = _bp("UpperChest").y; var ua = _bp("LeftUpperArm").x; var ha = _bp("LeftHand").x
	# göz yüksekliği model uzayında (VRoid yüz parçasının iris merkezi); göz mesh'inin AABB'si yerel uzayda, kullanma
	var ey = eye_center_model.y if face_mi else neck + 0.17
	var torso = func(p: Vector3) -> bool: return absf(p.x) < (ua * 0.95 if p.y > neck - 0.33 else 0.45) and p.y < neck + 0.06
	var front_gap = func(w: float, from_t: float) -> Callable:
		return func(t: float, ang: float) -> bool: return t > from_t and absf(wrapf(ang - PI * 0.5, -PI, PI)) < w
	var flat = func(o: float) -> Callable:
		return func(_t: float, _a: float) -> float: return o
	# yelek giyiliyse dış giysi (palto, pelerin, haori...) yeleğin kabuğunun dışına alınır: yelek dışarı taşmasın
	_outer_pad = 0.02 if look.get("vest") != null and look.get("outer_style") != null else 0.0
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
	_outer_pad = 0.0
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
				func(_t, ang): return 0.046 if absf(wrapf(ang - PI * 0.5, -PI, PI)) < 1.3 else 0.036, 9, null, -99.0, 16))   # paça kıvrımı taşmasın
	OutfitParts.garments(self, g)
	_outer_pad = 0.0
	_gdata = g   # sırt silahı kayışı silahlar kurulurken loft edilir


## Sırt silahı kayışı: omuzdan karşı kalçaya çapraz inen deri kayış + beli saran kemer (beden kabuğu, koyu renk slotu).
## Silahın çaprazıyla aynı yönde iner; kelepçeler silahı bu kayışa bağlar (havada durmaz).
func _back_strap(sx: float) -> void:
	if _gdata.is_empty():
		return
	var g = _gdata
	var neck = _bp("Neck").y; var hips = _bp("Hips").y
	var ua = _bp("LeftUpperArm").x
	var torso = func(p: Vector3) -> bool: return absf(p.x) < (ua * 0.95 if p.y > neck - 0.33 else 0.45) and p.y < neck + 0.06
	# kendi deri rengi: kabuk malzemesinin kopyası, tüm kabuk aksesuar slotunda (9), o slot kahverengi deri
	var mat: ShaderMaterial = cloth_shell_mat.duplicate()
	var pal: Array = Array(mat.get_shader_parameter("pal")).duplicate()
	if pal.size() > 9:
		pal[9] = Color(0.3, 0.19, 0.11)
		mat.set_shader_parameter("pal", pal)
	# çapraz göğüs kayışı: gerçek 3B deri şerit (kumaş kabuğuyla aynı yüzeyde z-savaşı yapıp lekeli görünüyordu)
	var sm = _strap_mesh(sx)
	if sm:
		var smi = _mesh_on("UpperChest", sm, Transform3D.IDENTITY)
		_strap_nodes.append(smi)
	# bel kemeri yok (animede Samehada/gunbai kayışı yalnız omuzdan karşı kalçaya çapraz)


## Çapraz kayış: bir omzun üstünden karşı kalçaya inen eğik düzlemin gövdeyi kestiği halka; her açıda gövde yüzeyi
## (köşe taraması) bulunur, yüzeyin 1.4 cm dışından kalın deri şerit (kenar dikişli) + göğüste metal toka
func _strap_mesh(sx: float, belt := false) -> Mesh:
	if body_mesh == null or body_mesh.mesh == null:
		return null
	var vs: PackedVector3Array = body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var ua = absf(_bp("LeftUpperArm").x)
	var yc = (neck - 0.02 + hips + 0.04) * 0.5
	var k = (neck - 0.02 - (hips + 0.04)) / maxf(0.1, ua * 1.6)   # sx tarafındaki omuz yukarıda
	if belt:
		yc = hips + 0.05
		k = 0.0
	var N = 44
	# kumaş kabuğu + yelek + dış giysi kalınlığı (eskiden çıplak gövdeye göre ölçülüp kıyafetin içine giriyordu)
	var pad = 0.03 + (0.032 if look.get("vest") != null else 0.0) + (0.04 if look.get("outer_style") != null else 0.0)
	var pts: Array = []
	var outs: Array = []
	for i in N:
		var a = TAU * i / N
		var d = Vector3(sin(a), 0, cos(a))
		var y = yc - sx * k * sin(a) * ua * 0.8
		var best = 0.0
		var lim = ua * (0.92 if y > neck - 0.3 else 1.5)
		for v in vs:
			if absf(v.y - y) > 0.035 or absf(v.x) > lim:
				continue
			var hz = Vector2(v.x, v.z)
			var r = hz.length()
			if r < 0.02:
				continue
			if Vector2(d.x, d.z).dot(hz / r) > 0.985 and r > best:
				best = r
		if best <= 0.0:
			best = 0.14
		pts.append(Vector3(d.x * (best + pad), y, d.z * (best + pad)))
		outs.append(d)
	var leather = Color(0.24, 0.17, 0.12)
	var b = MB.new()
	for i in N:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[(i + 1) % N]
		var t = p1 - p0
		var ln = t.length()
		if ln < 0.001:
			continue
		t /= ln
		var nrm: Vector3 = ((outs[i] as Vector3) + (outs[(i + 1) % N] as Vector3)).normalized()
		var w = nrm.cross(t).normalized()
		nrm = t.cross(w).normalized()
		var c = (p0 + p1) * 0.5
		b.add_xf("box", Transform3D(Basis(w * 0.066, nrm * 0.014, t * ln * 1.08), c), leather)   # anime: düz, kalın koyu deri kayış
	# toka: kayışın/kemerin ön noktası (açı ~0)
	var fp: Vector3 = pts[0]
	b.add("torus", fp + Vector3(0, 0, 0.012), Vector3(0.075, 0.03, 0.075), Color(0.62, 0.6, 0.56), Vector3(90, 0, 0), 14)   # göğüste metal halka
	return b.build(Props.toon())


## Kunai kılıfı (set1.png): sağ uyluğun dış-önünde siyah kılıf + uyluğu saran iki beyaz bant; uyluk yüzeyi köşe taramasıyla bulunur
## (eskiden sabit konumdaydı: pantolon kabuğunun içinde kalıp görünmüyordu)
func _thigh_holster() -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	var vs: PackedVector3Array = body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var hipb = _bp("RightUpperLeg")
	var kn = _bp("RightLowerLeg")
	var pad = 0.026   # pantolon kabuğu
	var ring = func(y: float) -> Array:
		# o yükseklikte uyluk kesiti: merkez + açı başına yarıçap
		var cx = 0.0; var cz = 0.0; var cn = 0
		for v in vs:
			if absf(v.y - y) < 0.02 and v.x < -0.02 and absf(v.x - hipb.x) < 0.13:
				cx += v.x; cz += v.z; cn += 1
		if cn == 0:
			return []
		var c = Vector3(cx / cn, y, cz / cn)
		var out = []
		for i in 24:
			var a = TAU * i / 24.0
			var d = Vector3(sin(a), 0, cos(a))
			var best = 0.05
			for v in vs:
				if absf(v.y - y) < 0.02 and v.x < -0.02 and absf(v.x - hipb.x) < 0.13:
					var h = Vector2(v.x - c.x, v.z - c.z)
					var r = h.length()
					if r > 0.01 and Vector2(d.x, d.z).dot(h / r) > 0.96 and r > best:
						best = r
			out.append(c + d * (best + pad))
		return out
	var m = MB.new()
	var white = Color(0.92, 0.92, 0.9)
	var yb = [hipb.y - (hipb.y - kn.y) * 0.3, hipb.y - (hipb.y - kn.y) * 0.45]
	var outer_pt = Vector3.ZERO
	for y in yb:
		var pts: Array = ring.call(y)
		if pts.is_empty():
			continue
		for i in pts.size():
			var p0: Vector3 = pts[i]
			var p1: Vector3 = pts[(i + 1) % pts.size()]
			var t = p1 - p0
			var nrm = Vector3(t.z, 0, -t.x).normalized()
			if nrm.dot(p0 - Vector3(hipb.x, y, p0.z)) < 0.0 and false:
				nrm = -nrm
			m.add_xf("box", Transform3D(Basis(t * 1.1, Vector3.UP * 0.024, nrm * 0.008), (p0 + p1) * 0.5), white)
		outer_pt = outer_pt + pts[int(pts.size() * 0.79) % pts.size()]   # dış-ön (sağ bacakta -x ile ön arası)
	if outer_pt != Vector3.ZERO:
		outer_pt /= 2.0
		var od = Vector3(outer_pt.x - hipb.x, 0, outer_pt.z - hipb.z).normalized()
		var bas = Basis(Vector3.UP.cross(od).normalized(), Vector3.UP, od)
		var black = Color(0.1, 0.1, 0.12)
		m.add_xf("box", Transform3D(bas.scaled(Vector3(0.075, 0.12, 0.035)), outer_pt + od * 0.022 + Vector3(0, -0.01, 0)), black)
		m.add_xf("box", Transform3D(bas.scaled(Vector3(0.08, 0.03, 0.04)), outer_pt + od * 0.026 + Vector3(0, 0.055, 0)), black.lightened(0.08))   # kapak
	_mesh_on("RightUpperLeg", m.build(Props.toon()), Transform3D.IDENTITY)


## Set kıyafet ayrıntıları (kaynak: köy set görselleri) — 3B parçalar, kemiğe bağlı:
## guard_stripes: koruyucuların üstünde boyuna çizgiler (Kumo kırmızı, Kiri açık mavi), knee_wraps: dizde çapraz beyaz sargı (Kumo),
## pants_flap: pantolonun sağ yanından dize kadar sarkan koyu kanat (Iwa)
func _outfit_extras() -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	var vs: PackedVector3Array = body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var gd = look.get("guards")
	var stripe = look.get("guard_stripes")
	for side in [["Left", 1.0], ["Right", -1.0]]:
		var pre: String = side[0]
		var sx: float = side[1]
		var knee = _bp(pre + "LowerLeg")
		var ank = _bp(pre + "Foot")
		# kaval önü: bacağın ön yüzeyi (köşe taraması)
		var front = func(y: float) -> float:
			var best = knee.z + 0.04
			for v in vs:
				if absf(v.x - knee.x) < 0.07 and absf(v.y - y) < 0.025 and v.z > best:
					best = v.z
			return best
		if stripe != null and gd in ["bacak", "ikisi"]:
			var m = MB.new()
			var y0 = knee.y - 0.06
			var y1 = ank.y + 0.1
			var ym = (y0 + y1) * 0.5
			var fz = float(front.call(ym)) + 0.056
			var cx = knee.x
			var bz = -1.0
			for v in vs:
				if absf(v.y - ym) < 0.03 and absf(v.x - knee.x) < 0.08 and v.z > bz:
					bz = v.z
					cx = v.x   # kavalın en ön noktası
			for k in 3:
				var x = cx + (k - 1) * 0.022
				m.add("box", Vector3(x, ym, fz), Vector3(0.008, y0 - y1, 0.006), stripe)
			_mesh_on(pre + "LowerLeg", m.build(Props.toon()), Transform3D.IDENTITY)
		if look.get("knee_wraps", false):
			var m2 = MB.new()
			var white = Color(0.92, 0.92, 0.9)
			var kz = float(front.call(knee.y + 0.02)) + 0.016
			for a in [-28.0, 28.0]:
				m2.add("box", Vector3(knee.x, knee.y + 0.04, kz), Vector3(0.022, 0.16, 0.008), white, Vector3(0, 0, a))
			m2.add("box", Vector3(knee.x, knee.y + 0.11, kz - 0.004), Vector3(0.13, 0.022, 0.008), white)
			m2.add("box", Vector3(knee.x, knee.y - 0.03, kz - 0.004), Vector3(0.12, 0.022, 0.008), white)
			_mesh_on(pre + "UpperLeg", m2.build(Props.toon()), Transform3D.IDENTITY)
		# ön kol çizgileri (Kiri kol koruyucusu)
		if stripe != null and gd in ["kol", "ikisi"]:
			var la = _bp(pre + "LowerArm")
			var hd = _bp(pre + "Hand")
			var ax = (hd - la).normalized()
			var r = 0.0
			var mid = la.lerp(hd, 0.6)
			for v in vs:
				var d = v - la
				var tt = d.dot(ax)
				if tt < 0.0 or tt > la.distance_to(hd):
					continue
				var perp = (d - ax * tt).length()
				if perp < 0.09 and absf(tt - la.distance_to(hd) * 0.6) < 0.03:
					r = maxf(r, perp)
			r += 0.026
			var up = Vector3.UP - ax * ax.dot(Vector3.UP)
			up = up.normalized()
			var side_v = ax.cross(up).normalized()
			var m3 = MB.new()
			var seg_len = la.distance_to(hd) * 0.42
			for k in 4:
				var ang = PI * 0.25 + k * PI * 0.5
				var off = (up * cos(ang) + side_v * sin(ang)) * r
				var c = mid + off
				m3.add_xf("box", Transform3D(Basis(side_v * 0.008, up * 0.006, ax * seg_len).rotated(ax, ang), c), stripe)
			_mesh_on(pre + "LowerArm", m3.build(Props.toon()), Transform3D.IDENTITY)
	# Iwa: sağ uyluğun dışından dize kadar sarkan koyu kanat
	var flap = look.get("pants_flap")
	if flap != null:
		var hip = _bp("RightUpperLeg")
		var kn = _bp("RightLowerLeg")
		var ymid = (hip.y + kn.y) * 0.5
		var fz = hip.z
		for v in vs:
			if absf(v.y - ymid) < 0.03 and absf(v.x - hip.x) < 0.08 and v.z > fz:
				fz = v.z
		var m4 = MB.new()
		var top = hip.y + 0.1
		var bot = kn.y - 0.02
		# referans: sağ uyluğun önünü ve dışını kaplayan, dize kadar inen koyu kanat (önden görünür)
		var pts = PackedVector2Array([Vector2(-0.1, 0.0), Vector2(0.11, 0.0), Vector2(0.13, bot - top), Vector2(-0.09, bot - top + 0.03)])
		m4.add_slab(pts, 0.012, flap, Transform3D(Basis(Vector3(-0.35, 0, 1).normalized(), Vector3(1, 0, 0.35).normalized(), Vector3.UP), Vector3(hip.x - 0.02, top, fz + 0.035)))
		_mesh_on("RightUpperLeg", m4.build(Props.toon()), Transform3D.IDENTITY)


## Gövdenin sırt yüzeyi (model uzayı z, arkası negatif): omurga hizasında, y yüksekliğinde
func _back_z(y: float) -> float:
	if body_mesh == null or body_mesh.mesh == null:
		return 0.0
	var vs: PackedVector3Array = body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bz = 0.0
	for v in vs:
		if absf(v.x) < 0.09 and absf(v.y - y) < 0.06 and v.z < bz:
			bz = v.z
	return bz


## Silahın z=zc kesitindeki genişliği (silah uzayı): ince yer (sap, gövde) kelepçe için seçilir
static func _xsec(node: Node3D, zc: float, band := 0.03) -> AABB:
	var out := AABB()
	var first := true
	var mis: Array = [node] if node is MeshInstance3D else node.find_children("*", "MeshInstance3D", true, false)
	for mi in mis:
		var xf := Transform3D.IDENTITY
		var c: Node = mi
		while c != node and c != null:
			xf = (c as Node3D).transform * xf
			c = c.get_parent()
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for si in mesh.get_surface_count():
			var vs: PackedVector3Array = mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
			for v in vs:
				var w = xf * v
				if absf(w.z - zc) < band:
					if first:
						out = AABB(w, Vector3.ZERO); first = false
					else:
						out = out.expand(w)
	return out


## Hayran modeli aksesuar: SFProps.ACCESSORIES[id] kemiğe, ref noktasına göre "off" ofsetle takılır
func _sf_acc(id: String, ref: Vector3) -> bool:
	if id == "" or not SFProps.has_accessory(id):
		return false
	var d: Dictionary = SFProps.ACCESSORIES[id]
	var n = SFProps.accessory_node(id)
	if n == null:
		return false
	var bone = String(d["bone"])
	if bone == "Hips":
		ref = _bp("Hips")
	var a = _attach(bone, Transform3D(Basis.IDENTITY, ref + Vector3(d.get("off", Vector3.ZERO))))
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
	if not sf_head and look.get("head_style") == "kage":
		KageAttire.hat(self, String(look.get("village", "konoha")))
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
	elif fs in ["kitsune", "tengu", "oni"]:
		# festival maskeleri (yüzü saran kabuk + desen); model önü +Z
		var m = MB.new()
		var red = Color(0.82, 0.1, 0.12)
		match fs:
			"kitsune":
				var wt = Color(0.97, 0.96, 0.94)
				m.add("sphere", Vector3(0, 0.0, 0.0), Vector3(0.17, 0.23, 0.1), wt, Vector3.ZERO, 14)
				m.add("cone", Vector3(0, -0.05, 0.065), Vector3(0.07, 0.1, 0.05), wt, Vector3(-80, 0, 0), 10)   # sivri tilki burnu
				m.add("sphere", Vector3(0, -0.055, 0.115), Vector3(0.018, 0.014, 0.014), Color(0.08, 0.06, 0.06), Vector3.ZERO, 6)
				for sx in [-1.0, 1.0]:
					m.add("cone", Vector3(0.06 * sx, 0.13, -0.005), Vector3(0.055, 0.08, 0.025), wt, Vector3(0, 0, -16 * sx), 4)   # kulak
					m.add("cone", Vector3(0.06 * sx, 0.128, 0.005), Vector3(0.032, 0.05, 0.01), red, Vector3(0, 0, -16 * sx), 4)   # kulak içi
					m.add("box", Vector3(0.042 * sx, 0.025, 0.045), Vector3(0.038, 0.008, 0.004), Color(0.06, 0.05, 0.06), Vector3(0, 0, 22 * sx))   # kısık göz
					m.add("box", Vector3(0.045 * sx, 0.06, 0.04), Vector3(0.03, 0.006, 0.004), red, Vector3(0, 0, -28 * sx))   # kaş
					for k in 2:
						m.add("box", Vector3(0.06 * sx, -0.035 - k * 0.016, 0.04), Vector3(0.04, 0.005, 0.004), Color(0.25, 0.35, 0.65), Vector3(0, 0, (6 - k * 14) * sx))   # bıyık
				m.add("box", Vector3(0, -0.095, 0.04), Vector3(0.05, 0.006, 0.004), red)   # ağız
			"tengu":
				m.add("sphere", Vector3.ZERO, Vector3(0.17, 0.23, 0.1), red, Vector3.ZERO, 14)
				m.add("cone", Vector3(0, -0.01, 0.12), Vector3(0.05, 0.2, 0.05), red.darkened(0.08), Vector3(-90, 0, 0), 10)   # uzun burun
				for sx in [-1.0, 1.0]:
					m.add("box", Vector3(0.045 * sx, 0.04, 0.045), Vector3(0.035, 0.012, 0.006), Color(0.08, 0.05, 0.05), Vector3(0, 0, -20 * sx))
					m.add("sphere", Vector3(0.055 * sx, 0.075, 0.04), Vector3(0.045, 0.02, 0.02), Color(0.95, 0.95, 0.92), Vector3(0, 0, -20 * sx), 6)   # beyaz kaş
				m.add("sphere", Vector3(0, -0.12, 0.03), Vector3(0.1, 0.06, 0.04), Color(0.95, 0.95, 0.92), Vector3.ZERO, 8)   # sakal
			"oni":
				m.add("sphere", Vector3.ZERO, Vector3(0.18, 0.23, 0.1), Color(0.75, 0.12, 0.1), Vector3.ZERO, 14)
				for sx in [-1.0, 1.0]:
					m.add("cone", Vector3(0.06 * sx, 0.13, 0.0), Vector3(0.03, 0.09, 0.03), Color(0.95, 0.9, 0.75), Vector3(0, 0, -18 * sx), 6)   # boynuz
					m.add("sphere", Vector3(0.045 * sx, 0.035, 0.045), Vector3(0.04, 0.025, 0.012), Color(1.0, 0.85, 0.2), Vector3.ZERO, 8)
					m.add("cone", Vector3(0.035 * sx, -0.08, 0.05), Vector3(0.014, 0.035, 0.01), Color(0.97, 0.95, 0.9), Vector3(180, 0, 0), 4)   # diş
				m.add("box", Vector3(0, -0.07, 0.045), Vector3(0.1, 0.02, 0.006), Color(0.1, 0.03, 0.03))
				m.add("box", Vector3(0, 0.06, 0.05), Vector3(0.11, 0.015, 0.006), Color(0.1, 0.03, 0.03), Vector3(0, 0, 0))
		_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, -0.035, 0.1)))
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
		var gy = (eye_center_model.y + 0.055) if face_mi else hc.y + 0.05
		_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hcen.x, gy, hcen.z)))
	# --- sırt / bel
	var bc: Color = look.get("backc", Color(0.4, 0.33, 0.22)) if look.get("backc") != null else Color(0.4, 0.33, 0.22)
	match (null if sf_back else look.get("back_item")):
		"kabak", "sake":
			# su kabağı (sırtta dev, iki boğumlu) / sake kabağı (belde küçük)
			var big = look.get("back_item") == "kabak"
			var gc = Color(0.78, 0.6, 0.4) if big else Color(0.82, 0.62, 0.32)
			var k = 1.0 if big else 0.32
			var m = MB.new()
			m.add("sphere", Vector3(0, -0.14 * k, 0), Vector3(0.36, 0.38, 0.34) * k, gc, Vector3.ZERO, 16)
			m.add("sphere", Vector3(0, 0.2 * k, 0), Vector3(0.24, 0.26, 0.23) * k, gc.lightened(0.04), Vector3.ZERO, 14)
			m.add("cyl", Vector3(0, 0.04 * k, 0), Vector3(0.13, 0.03, 0.13) * k, Color(0.55, 0.14, 0.12), Vector3.ZERO, 12)   # boğum ipi
			m.add("cyl", Vector3(0, 0.36 * k, 0), Vector3(0.08, 0.08, 0.08) * k, Color(0.45, 0.3, 0.18), Vector3.ZERO, 10)   # tıpa
			if big:
				m.add("box", Vector3(0, 0.0, 0.17), Vector3(0.05, 0.6, 0.01), Color(0.3, 0.22, 0.14), Vector3(0, 0, 38))   # kayış
				m.add("box", Vector3(0, -0.12, -0.18), Vector3(0.12, 0.12, 0.006), Color(0.6, 0.12, 0.1), Vector3(0, 0, 45))   # mühür kâğıdı
				_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis(Vector3.BACK, deg_to_rad(-8)), ch + Vector3(0, -0.12, -0.33)))
			else:
				var hp = _grest(skel.find_bone("Hips")).origin
				_mesh_on("Hips", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hp + Vector3(0.18, -0.05, 0.02)))
		"parsomen":
			var m = MB.new()
			m.add("cyl", Vector3.ZERO, Vector3(0.13, 0.62, 0.13), bc, Vector3(0, 0, 90), 12)
			for sx in [-1.0, 1.0]:
				m.add("cyl", Vector3(0.32 * sx, 0, 0), Vector3(0.15, 0.03, 0.15), Color(0.55, 0.12, 0.12), Vector3(0, 0, 90), 12)
			m.add("box", Vector3(0, 0.0, 0.05), Vector3(0.04, 0.5, 0.01), dark, Vector3(0, 0, 40))
			_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis(Vector3.BACK, deg_to_rad(-12)), ch + Vector3(0, -0.12, -0.2)))
		"shuriken":
			# dev fūma shuriken sırtta: 4 uçlu yıldız, sırt düzleminde, hafif çapraz
			var m = MB.new()
			_w_star(m, Vector3.ZERO, 0.36, 0.11, 4, bc, dark)
			m.add("box", Vector3(0, 0, 0.03), Vector3(0.05, 0.5, 0.012), Color(0.3, 0.22, 0.15), Vector3(0, 0, -35))   # taşıma kayışı
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
			# el sırtı (dinlenme T pozunda üst yüz bileğin 1.2 cm üstünde, el 0..7.8 cm dışarı, z -6.8..1.2 cm): plaka yüzeye oturur
			m.add("box", Vector3(0.038 * sx, 0.0165, -0.022), Vector3(0.058, 0.009, 0.05), steel)
			_mesh_on(side + "Hand", m.build(Props.toon()), Transform3D(Basis.IDENTITY, hp))
	OutfitParts.accessories(self)


## Yaka, fermuar, bel bağı
func _cloth_details() -> void:
	var ts = top_style()
	_sandals()
	var neck = skel.find_bone("Neck")
	if neck >= 0 and ts in ["yakali", "ceket", "yakali_uzun"] and look["vest"] == null:
		var np = _grest(neck).origin
		var c = MB.new()
		var cc: Color = look["top2"] if ts == "ceket" else look["top"]
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


var _mouth: MeshInstance3D = null
## Konuşma ağzı: yüzün önünde küçük koyu ağız şekli; open 0 kapalı (görünmez çizgi) .. 1 açık
func set_mouth(open: float) -> void:
	if _mouth == null:
		if skel == null or skel.find_bone("Head") < 0:
			return
		var b = MB.new()
		b.add("sphere", Vector3.ZERO, Vector3(0.034, 0.02, 0.008), Color(0.32, 0.1, 0.1), Vector3.ZERO, 10)
		b.add("box", Vector3(0, 0.006, 0.001), Vector3(0.026, 0.004, 0.004), Color(0.95, 0.94, 0.9))   # üst diş çizgisi
		var hc = eye_center_model if face_mi else _head_center()
		# yüz yüzeyinin hemen önünde, gözlerin ~7 cm altında (çene üstü)
		_mouth = _mesh_on("Head", b.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(0, hc.y - 0.072, hc.z + 0.012)))
		_mouth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mouth.set_meta("base", _mouth.transform)
	_mouth.visible = open > 0.08
	var bt: Transform3D = _mouth.get_meta("base")
	_mouth.transform = Transform3D(bt.basis * Basis.from_scale(Vector3(1.0, maxf(0.2, open), 1.0)), bt.origin)


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
	"orgu": "Örgü", "mohikan": "Mohikan", "kirpik": "Kısa Kirpi", "kisa_kakul": "Kâküllü Kısa",
	"dalgali": "Dalgalı Uzun", "savas_yelesi": "Savaş Yelesi", "bilge_yelesi": "Bilge Yelesi", "yuksek_kuyruk": "Yüksek At Kuyruğu", "yan_kuyruk": "Yan At Kuyruğu", "ikiz_kuyruk": "İkiz Kuyruk",
	"ikiz_orgu": "İkiz Örgü", "samuray": "Samuray Tepesi", "savasci_kuyruk": "Savaşçı Kuyruğu", "alev": "Alev Dikeni",
	"geriye_diken": "Geriye Dikenli", "yan_tarama": "Yana Taranmış", "perde": "Ortadan Ayrık", "kabarik": "Kabarık",
	"ruzgar": "Rüzgâr Savruğu", "yabani": "Yabani Yele", "ense_kuyruk": "Ense Kuyruğu", "alcak_topuz": "Alçak Topuz",
	"kazinmis": "Kazınmış", "yan_kazinmis": "Yanları Kazınmış", "golge": "Gölge Kâkül", "cerceve": "Yüz Çerçeveli",
	"yan_orgu": "Yan Örgü", "bagli_uzun": "Bağlı Uzun", "tepe_diken": "Tepe Dikeni", "yan_topuz": "Yan Topuz",
	"kel": "Kel"}
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


## Kafatasını arkadan ve tepeden saran, yüzü ve enseyi açık bırakan ince saç kabuğu (model uzayında)
static func _scalp_cap(c: Vector3, r: Vector3, front: float, eye_y: float, hab: AABB) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var la = 14; var lo = 24
	# ölçülen kafatası yarıçapı (özellikle derinlik) yüz mesh'inden küçük çıkıyor: kabuk kafanın içinde kalıp görünmüyordu.
	# Arka/yan/tepe için gerçek kafa kutusunun dış sınırını kullan
	var back = maxf(r.z, (c.z - hab.position.z) if front > 0.0 else (hab.end.z - c.z))
	var rr = Vector3(maxf(r.x, hab.size.x * 0.5) * 1.1, maxf(r.y, hab.end.y - c.y) * 1.06, back * 1.45)   # arka kafa gövdeden gelir, yüz kutusundan daha geride
	var grid = []
	for i in la + 1:
		var row = []
		var th = PI * float(i) / la   # 0 tepe, PI alt
		for j in lo + 1:
			var ph = TAU * float(j) / lo
			var d = Vector3(sin(th) * sin(ph), cos(th), sin(th) * cos(ph))
			var p = c + d * rr
			var fwd = d.z * front
			# yüz: önde ve kaş hizasının altında açık; ense/boyun açık
			var keep = not (fwd > 0.2 and p.y < eye_y + r.y * 0.42) and p.y > c.y - r.y * (1.05 if fwd < -0.1 else 0.7) and not (fwd > 0.55 and p.y < eye_y + r.y * 0.7)
			row.append([p, d, keep])
		grid.append(row)
	for i in la:
		for j in lo:
			var a = grid[i][j]; var b = grid[i + 1][j]; var cc = grid[i + 1][j + 1]; var dd = grid[i][j + 1]
			for tri in [[a, cc, b], [a, dd, cc]]:   # dışa bakan sarım (toon shader cull_back)
				if tri[0][2] and tri[1][2] and tri[2][2]:
					for v in tri:
						st.set_color(Color(0.8, 0.8, 0.8))
						st.set_normal(v[1])
						st.set_uv(Vector2.ZERO)
						st.add_vertex(v[0])
	return st.commit()


## Anime saç tutamı: kökten uca incelen, kavisli, yassı baklava kesitli tüp
static func _clump(st: SurfaceTool, root: Vector3, d: Vector3, grav: Vector3, length: float, width: float, flat := 0.45) -> void:
	length *= CLUMP_LEN
	width *= CLUMP_WID
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
	# kafadan bir bağlama noktasına toplanan tutamlar (at kuyruğu / topuz kökü)
	var gather = func(tie: Vector3, n: int, y0: float, y1: float, p0: float, p1: float) -> void:
		for i in n:
			var a = at.call(rng.randf_range(y0, y1), rng.randf_range(p0, p1))
			var to = tie - a[0]
			_clump(st, a[0], to.normalized(), Vector3.ZERO, to.length() * 1.05, 0.06, 0.3)
	# bağlama noktasından sarkan kuyruk
	var tail = func(tie: Vector3, dir: Vector3, n: int, length: float, width: float, spread: float, grav: Vector3) -> void:
		for i in n:
			var d = (dir.normalized() + Vector3(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread) * 0.5, rng.randf_range(-spread, spread))).normalized()
			_clump(st, tie, d, grav, length * rng.randf_range(0.85, 1.1), width)
	# yuvarlak topuz
	var bun_at = func(bun: Vector3, n: int, size: float) -> void:
		for i in n:
			var ang = TAU * i / float(n)
			var d = Vector3(cos(ang), sin(ang) * 0.7 + 0.25, sin(ang) * 0.7).normalized()
			_clump(st, bun - d * 0.035 * size, d.cross(Vector3.UP).normalized(), Vector3.ZERO, 0.1 * size, 0.075 * size, 0.6)
	# örgü: yön boyunca sağa-sola dönüşümlü kısa tutamlar
	var braid = func(top: Vector3, dir: Vector3, segs: int, step: float, width: float) -> void:
		var dn = dir.normalized()
		var sd = dn.cross(Vector3.FORWARD if absf(dn.z) < 0.9 else Vector3.RIGHT).normalized()
		for k in segs:
			var s = 1.0 if k % 2 == 0 else -1.0
			var w = width * (1.0 - 0.35 * float(k) / segs)
			_clump(st, top + dn * step * k + sd * 0.008 * s, (dn + sd * 0.22 * s).normalized(), Vector3.ZERO, step * 2.0, w * 1.15, 0.9)
	if style in ["diken", "dağınık", "kase", "atkuyruğu", "ananas", "ikiz_topuz", "yele", "kakul", "geriye", "orgu", "kirpik", "kisa_kakul", "alev", "geriye_diken", "kabarik", "yabani", "savas_yelesi", "bilge_yelesi"]:
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
		"dalgali":  # sırta inen dalgalı uzun tutamlar (iki parçalı: dışa sonra içe kıvrılır)
			for i in 16:
				var a = at.call(rng.randf_range(95, 265), rng.randf_range(55, 105))
				var d1 = (a[1] * 0.45 + Vector3(0, -1, -0.15)).normalized()
				var ln = rng.randf_range(0.24, 0.3)
				var mid = a[0] + d1 * ln * CLUMP_LEN * 0.9
				_clump(st, a[0], d1, a[1] * 0.12, ln, 0.075)
				_clump(st, mid, (Vector3(0, -1, 0) - a[1] * 0.35).normalized(), a[1] * 0.18, ln * 0.95, 0.06)
			bangs.call(4, 45.0, 0.1, 0.045)
		"savas_yelesi":  # bele kadar inen çok hacimli, sivri uçlu kabarık yele + tek gözü örten uzun perçem
			for i in 34:
				var a = at.call(rng.randf_range(75, 285), rng.randf_range(25, 115))
				var d = (a[1] * 0.75 + Vector3(0, -1, -0.25)).normalized()
				_clump(st, a[0], d, Vector3(rng.randf_range(-0.12, 0.12), -0.45, -0.12), rng.randf_range(0.42, 0.62), rng.randf_range(0.09, 0.12), 0.4)
			for i in 12:  # tepe hacmi: geriye kalkık kalın dikenler
				var a = at.call(rng.randf_range(-170, 170), rng.randf_range(5, 55))
				_clump(st, a[0], (a[1] + Vector3(0, 0.2, -0.6)).normalized(), Vector3(0, -0.2, -0.1), rng.randf_range(0.16, 0.22), 0.09)
			for sx in [-1.0, 1.0]:  # şakaklardan göğse inen kalın perçemler
				var a = at.call(70.0 * sx, 68.0)
				_clump(st, a[0], Vector3(0.3 * sx, -1, 0.2).normalized(), Vector3(0.04 * sx, -0.15, 0.04), 0.3, 0.07)
			var bang = at.call(-22.0, 52.0)
			_clump(st, bang[0], Vector3(-0.3, -0.95, 0.3).normalized(), Vector3(-0.04, -0.12, 0.06), 0.2, 0.08, 0.3)
			bangs.call(3, 35.0, 0.09, 0.045)
		"bilge_yelesi":  # sırtın ortasına inen, dışa sivri taşan dev diken yele + yüzü çevreleyen iki uzun perçem
			for i in 28:
				var a = at.call(rng.randf_range(95, 265), rng.randf_range(20, 105))
				var d = (a[1] * 0.9 + Vector3(0, -0.55, -0.6)).normalized()
				_clump(st, a[0], d, Vector3(0, -0.5, -0.05), rng.randf_range(0.34, 0.5), rng.randf_range(0.1, 0.13), 0.45)
			for i in 10:  # tepe: yukarı-geriye kalkık iri dikenler
				var a = at.call(rng.randf_range(-160, 160), rng.randf_range(5, 50))
				_clump(st, a[0], (a[1] + Vector3(0, 0.35, -0.5)).normalized(), Vector3(0, -0.1, -0.1), rng.randf_range(0.17, 0.23), 0.09)
			for sx in [-1.0, 1.0]:
				var a = at.call(48.0 * sx, 60.0)
				_clump(st, a[0], Vector3(0.35 * sx, -1, 0.3).normalized(), Vector3(0.05 * sx, -0.1, 0.03), 0.28, 0.07)
		"yuksek_kuyruk":  # tepede bağlanıp sırta inen uzun kuyruk
			var tie = c + Vector3(0, r.y * 0.8, -r.z * 0.8)
			gather.call(tie, 14, -150.0, 150.0, 15.0, 95.0)
			tail.call(tie, Vector3(0, -0.25, -1), 9, 0.42, 0.065, 0.2, Vector3(0, -1.7, 0.55))
			bangs.call(4, 45.0, 0.09, 0.045)
		"yan_kuyruk":
			var tie = c + Vector3(r.x * 0.85, r.y * 0.15, -r.z * 0.35)
			gather.call(tie, 12, -150.0, 150.0, 15.0, 95.0)
			tail.call(tie, Vector3(0.45, -1, -0.15), 7, 0.32, 0.06, 0.2, Vector3(0.05, -0.6, 0))
			bangs.call(5, 50.0, 0.1, 0.045)
		"ikiz_kuyruk":
			for sx in [-1.0, 1.0]:
				var tie = c + Vector3(r.x * 0.8 * sx, r.y * 0.45, -r.z * 0.35)
				bun_at.call(tie, 6, 0.45)
				tail.call(tie, Vector3(0.35 * sx, -0.6, -0.4), 6, 0.36, 0.06, 0.2, Vector3(0.1 * sx, -1.0, 0))
			bangs.call(5, 50.0, 0.09, 0.045)
		"ikiz_orgu":
			for sx in [-1.0, 1.0]:
				braid.call(c + Vector3(r.x * 0.72 * sx, -r.y * 0.35, -r.z * 0.4), Vector3(0.12 * sx, -1, 0.1), 8, 0.055, 0.05)
			bangs.call(5, 50.0, 0.09, 0.045)
		"samuray":  # kazınmış başta tepe topuzu, öne katlanmış kısa kuyruk
			var base = c + Vector3(0, r.y * 1.0, -r.z * 0.1)
			gather.call(base, 8, -180.0, 180.0, 15.0, 55.0)
			bun_at.call(base, 8, 0.7)
			tail.call(base + Vector3(0, 0.02, 0), Vector3(0, 0.3, 1), 5, 0.16, 0.06, 0.08, Vector3(0, -0.5, 0))
		"savasci_kuyruk":  # kazınmış başta tepe arkasından bele inen tek uzun kuyruk
			var tie = c + Vector3(0, r.y * 0.75, -r.z * 0.8)
			gather.call(tie, 10, -120.0, 120.0, 10.0, 70.0)
			bun_at.call(tie, 6, 0.4)
			tail.call(tie, Vector3(0, -0.2, -1), 9, 0.52, 0.07, 0.15, Vector3(0, -1.8, 0.6))
		"alev":  # yukarı ve geriye savrulan alev biçimli dikenler
			for ring in [[10.0, 5], [35.0, 9], [65.0, 12]]:
				for i in ring[1]:
					var yw = 360.0 * (float(i) + 0.5) / ring[1] + rng.randf_range(-10, 10)
					var a = at.call(yw, ring[0])
					var d = (a[1] * 0.5 + Vector3(0, 1, -0.25)).normalized()
					_clump(st, a[0], d, Vector3(0, 0.05, -0.12), rng.randf_range(0.17, 0.24), 0.075)
			bangs.call(4, 45.0, 0.08, 0.045)
		"geriye_diken":  # geriye yatık sivri dikenler, alın açık
			for ring in [[20.0, 6], [50.0, 10], [85.0, 10]]:
				for i in ring[1]:
					var yw = 360.0 * (float(i) + 0.5) / ring[1] + rng.randf_range(-8, 8)
					if ring[0] > 70.0 and absf(wrapf(yw, -180.0, 180.0)) < 60.0:
						continue
					var a = at.call(yw, ring[0])
					_clump(st, a[0], (a[1] * 0.3 + Vector3(0, 0.15, -1)).normalized(), Vector3(0, -0.05, -0.05), rng.randf_range(0.16, 0.22), 0.07)
		"yan_tarama":  # alnı bir yandan öbür yana kaplayan yatık perçem
			for i in 7:
				var a = at.call(rng.randf_range(-50, 40), rng.randf_range(38, 58))
				_clump(st, a[0], Vector3(1, -0.5, 0.35).normalized(), Vector3(0, -0.25, 0), rng.randf_range(0.11, 0.15), 0.06, 0.3)
		"perde":  # ortadan ayrılıp yüzü iki yandan çerçeveleyen perçemler
			for sx in [-1.0, 1.0]:
				for i in 4:
					var a = at.call(sx * (12.0 + i * 13.0), 45.0 + i * 4.0)
					_clump(st, a[0], Vector3(0.45 * sx, -1, 0.3).normalized(), Vector3(0.05 * sx, -0.2, 0.05), 0.19 + i * 0.015, 0.06)
		"kabarik":  # kabarık, hacimli kısa bukleler
			for i in 42:
				var yw = rng.randf_range(-180, 180); var pt = rng.randf_range(0, 100)
				if absf(yw) < 60.0 and pt > 60.0:
					continue
				var a = at.call(yw, pt)
				_clump(st, a[0], a[1], -a[1] * 0.3, rng.randf_range(0.07, 0.1), 0.09, 0.8)
			bangs.call(3, 35.0, 0.06, 0.04)
		"ruzgar":  # bir yana ve geriye savrulmuş uzun saç
			for i in 18:
				var a = at.call(rng.randf_range(60, 300), rng.randf_range(30, 100))
				_clump(st, a[0], (a[1] * 0.3 + Vector3(0.6, 0.1, -1)).normalized(), Vector3(0.2, -0.2, -0.1), rng.randf_range(0.25, 0.35), 0.07)
			bangs.call(4, 40.0, 0.1, 0.045)
		"yabani":  # sırta inen, uçları sivri dağınık uzun yele + tepe dikenleri
			for i in 20:
				var a = at.call(rng.randf_range(100, 260), rng.randf_range(40, 110))
				_clump(st, a[0], (a[1] * 0.5 + Vector3(0, -1, -0.4)).normalized(), Vector3(rng.randf_range(-0.1, 0.1), -0.25, -0.1), rng.randf_range(0.3, 0.45), 0.085)
			for i in 8:
				var a = at.call(rng.randf_range(-170, 170), rng.randf_range(10, 45))
				_clump(st, a[0], (a[1] + Vector3(0, 0.1, -0.35)).normalized(), Vector3(0, -0.12, -0.08), rng.randf_range(0.12, 0.16), 0.075)
			bangs.call(5, 50.0, 0.11, 0.045)
		"ense_kuyruk":  # kısa saç, enseden sarkan ince kuyruk
			tail.call(c + Vector3(0, -r.y * 0.35, -r.z * 0.95), Vector3(0, -1, -0.2), 3, 0.22, 0.04, 0.08, Vector3(0, -0.2, 0))
			bangs.call(3, 30.0, 0.07, 0.04)
		"alcak_topuz":  # ensede alçak topuz
			var bun = c + Vector3(0, -r.y * 0.15, -r.z * 1.3)
			gather.call(bun, 10, 100.0, 260.0, 30.0, 100.0)
			bun_at.call(bun, 14, 1.25)
			bangs.call(4, 45.0, 0.09, 0.045)
		"yan_kazinmis":  # yanlar kazınmış, tepede geriye yatık hacim
			for i in 14:
				var a = at.call(rng.randf_range(-70, 70) + (180.0 if i % 3 == 0 else 0.0), rng.randf_range(0, 40))
				_clump(st, a[0], (a[1] * 0.3 + Vector3(0, 0.3, -1)).normalized(), Vector3(0, -0.15, 0), rng.randf_range(0.13, 0.17), 0.08, 0.35)
		"cerceve":  # uzun saç, yüzü iki yandan saran uzun perçemler
			for sx in [-1.0, 1.0]:
				for i in 2:
					var a = at.call(sx * (55.0 + i * 12.0), 62.0)
					_clump(st, a[0], Vector3(0.2 * sx, -1, 0.15).normalized(), Vector3(0.02 * sx, -0.1, 0), 0.24, 0.05)
			bangs.call(5, 45.0, 0.1, 0.045)
		"yan_orgu":  # omuzdan öne düşen tek yan örgü
			braid.call(c + Vector3(r.x * 0.7, -r.y * 0.4, r.z * 0.05), Vector3(0.12, -1, 0.35), 8, 0.055, 0.055)
		"bagli_uzun":  # ensede bağlanmış uzun saç
			var tie = c + Vector3(0, -r.y * 0.5, -r.z * 0.95)
			bun_at.call(tie, 6, 0.35)
			tail.call(tie, Vector3(0, -1, -0.15), 5, 0.3, 0.06, 0.12, Vector3(0, -0.3, 0))
		"tepe_diken":  # kısa saç, yalnız tepede kısa dikenler
			for i in 10:
				var a = at.call(rng.randf_range(-180, 180), rng.randf_range(0, 35))
				_clump(st, a[0], (a[1] + Vector3(0, 0.3, -0.1)).normalized(), Vector3.ZERO, rng.randf_range(0.09, 0.12), 0.06)
		"yan_topuz":  # tek yanda topuz
			var bun = c + Vector3(r.x * 0.7, r.y * 0.6, -r.z * 0.35)
			gather.call(bun, 8, -60.0, 160.0, 15.0, 80.0)
			bun_at.call(bun, 12, 0.9)
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
	# --- yelek: kumaş katmanına boyanır; üstüne sadece yaka + parşömen cepleri (dış giysi altındayken yok: taşıyordu)
	if look["vest"] != null and (look.get("outer_style") == null or String(look.get("outer_style")) in ["atki", "kisa", "kesa"]):
		var v = MB.new()
		var vc: Color = look["vest"]
		var ch = _grest(skel.find_bone("UpperChest")).origin
		var vs = int(look.get("vest_style", 0))
		var dk = vc.darkened(0.22)
		var lt = vc.lightened(0.18)
		# yaka (Konoha/Kumo yüksek, diğerleri alçak)
		var collar_h = 0.34 if vs in [0, 3] else 0.24
		# fermuar: göğsün ön yüzeyine oturan parçalar (sabit derinlikteyken havada kalıyordu); boyun halkası yaka yok (gövdeye oturmuyordu)
		if body_mesh and body_mesh.mesh:
			var bvs: PackedVector3Array = body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var zp = []
			for k in 9:
				var yy = ch.y + 0.1 - k * 0.055
				var fz = -1.0
				for q in bvs:
					if absf(q.x) < 0.03 and absf(q.y - yy) < 0.02 and q.z > fz:
						fz = q.z
				zp.append(Vector3(0, yy - ch.y, fz - ch.z) if fz > -1.0 else null)
			# göğüs çıkıntısında yelek kabuğu daha dışarıda: komşu satırların en önü + yelek kalınlığı
			var zs = []
			for k in 9:
				var mz = -9.0
				for j in [k - 1, k, k + 1]:
					if j >= 0 and j < 9 and zp[j] != null:
						mz = maxf(mz, zp[j].z)
				zs.append(mz)
			var zmax = -9.0
			for k in 9:
				if zp[k] != null:
					zmax = maxf(zmax, zp[k].z)
			for k in 9:
				if zp[k] != null:
					# yelek önü düz panel: üstte göğüs çıkıntısının hizasında kalır (içine gömülüp kayboluyordu)
					zp[k] = Vector3(0, zp[k].y, maxf(zs[k] + 0.07, zmax + 0.035 - 0.02 * maxf(0.0, k - 5.0)))
			for k in 8:
				if zp[k] != null and zp[k + 1] != null:
					var a0: Vector3 = zp[k]
					var a1: Vector3 = zp[k + 1]
					var dd = a1 - a0
					v.add_xf("box", Transform3D(Basis(Vector3.RIGHT * 0.011, Vector3(0, -dd.z, dd.y).normalized() * 0.005, dd * 1.05), (a0 + a1) * 0.5), Color(0.82, 0.82, 0.8))
		# parşömen cebi takımı: taban + dikey cepler + kapak çizgileri (referans: Konoha/Suna yelekleri)
		var vlo = MB.new()   # bel hizası (göğsün altı): bel kemiğine bağlı; göğüs kemiğine bağlıyken koşarken gövdeden kopup havada kalıyordu
		var pack = func(cx: float, cy: float, n: int):
			var v0: MB = vlo if cy < -0.12 else v
			v0.add("box", Vector3(cx, cy, 0.175 + maxf(0.0, -cy - 0.12) * 0.15), Vector3(0.026 * n + 0.012, 0.1, 0.03), dk)
			for k in n:
				var x = cx - 0.013 * (n - 1) + k * 0.026
				v0.add("box", Vector3(x, cy - 0.005, 0.192), Vector3(0.022, 0.085, 0.012), vc.darkened(0.08))
				v0.add("box", Vector3(x, cy + 0.03, 0.2), Vector3(0.024, 0.006, 0.006), dk.darkened(0.2))   # kapak dikişi
		match vs:
			0:   # Konoha: göğüste iki takım (2x2 cep) + omuzda düğmeli yassı omuzluk (set1.png)
				for sx in [-1.0, 1.0]:
					pack.call(0.085 * sx, -0.06, 3)
					pack.call(0.085 * sx, -0.17, 3)

			1:   # Suna: kanat gibi açılan dev omuzluklar + açık renk omuz kayışı + karında cepler
				for sx in [-1.0, 1.0]:
					v.add("hemi", Vector3(0.21 * sx, 0.1, 0.0), Vector3(0.24, 0.07, 0.19), vc.darkened(0.05), Vector3(0, 0, -30 * sx), 12)   # kanat gibi açılan omuzluk
					v.add("box", Vector3(0.11 * sx, 0.1, 0.165), Vector3(0.045, 0.025, 0.01), Color(0.82, 0.84, 0.86))
					pack.call(0.08 * sx, -0.2, 3)
			2:   # Kiri: yatay zırh plakaları + kutu omuzluk + plakaların altından sarkan önlük (mistset.png)
				for k in 3:
					v.add("box", Vector3(0, -0.04 - k * 0.095, 0.168), Vector3(0.26, 0.07, 0.016), vc.darkened(0.04 * k))
				for sx in [-1.0, 1.0]:
					v.add("box", Vector3(0.19 * sx, 0.12, 0.0), Vector3(0.16, 0.035, 0.18), dk, Vector3(0, 0, -16 * sx))
					v.add("box", Vector3(0.155 * sx, -0.2, 0.17), Vector3(0.05, 0.03, 0.02), dk)   # yan tokalar
				var hp2 = _grest(skel.find_bone("Hips")).origin
				var apr = MB.new()
				var flap = PackedVector2Array([Vector2(-0.13, 0.0), Vector2(0.13, 0.0), Vector2(0.11, -0.2), Vector2(0.0, -0.24), Vector2(-0.11, -0.2)])
				apr.add_slab(PackedVector2Array(Array(flap).map(func(q): return Vector2(q.x, q.y))), 0.012, vc.darkened(0.06), Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3(0, 0.06, 0.17)))   # profil (genişlik, boy) -> (x, y), yüz öne
				_mesh_on("Hips", apr.build(Props.toon()), Transform3D(Basis.IDENTITY, hp2))
			3:   # Kumo: yan cepler (tek askı zaten var)
				for sx in [-1.0, 1.0]:
					pack.call(0.095 * sx, -0.12, 2)
			4:   # Iwa: omuzluk + karında kalın kemer plakası
				for sx in [-1.0, 1.0]:
					v.add("hemi", Vector3(0.19 * sx, 0.1, 0.0), Vector3(0.15, 0.08, 0.16), dk, Vector3(0, 0, -24 * sx), 10)
				vlo.add("box", Vector3(0, -0.27, 0.15), Vector3(0.34, 0.09, 0.06), lt.darkened(0.15))
				vlo.add("box", Vector3(0, -0.27, 0.185), Vector3(0.36, 0.012, 0.01), dk)
			_:
				for sx in [-1.0, 1.0]:
					pack.call(0.08 * sx, -0.1, 2)
		_mesh_on("UpperChest", v.build(Props.toon()), Transform3D(Basis.IDENTITY, ch))
		if not vlo.verts.is_empty():
			_mesh_on("Chest", vlo.build(Props.toon()), Transform3D(Basis.IDENTITY, ch))
	_outfit_extras()
	# --- eldeki silahlar (ekipman: sağ el / sol el) ve kınları
	_weapons()
	# --- çanta + kunai kılıfı
	var hip = _grest(skel.find_bone("Hips")).origin
	var pouch = MB.new()
	pouch.add("box", Vector3.ZERO, Vector3(0.14, 0.09, 0.07), Color(0.42, 0.33, 0.22))
	_mesh_on("Hips", pouch.build(Props.toon()), Transform3D(Basis.IDENTITY, hip + Vector3(0.0, 0.02, -0.14)))
	_thigh_holster()


# ------------------------------------------------------------------ silahlar: tutuş, kın, çekme/sokma
## Silah kını yeri: pouch = kunai çantası/kılıfı (görünmez), hip = sol kalçada kınlı kılıç (çapraz çekiş),
## back = sırtta çapraz (dev kılıçlar, sopalar), low_back = belin arkasında yatay, belt = yan kalçada asılı
const SHEATH_OF := {"blade": "pouch", "dual": "pouch", "claw": "pouch", "sickle": "belt", "sword": "hip", "heavy": "back", "staff": "back", "chain": "belt", "fan": "back"}
const SHEATH_ID := {"tanto": "low_back", "ikiz_hancer": "low_back", "tonfa": "belt", "sai": "belt", "kiba": "back", "nodachi": "back"}
## Kınlı kılıçlar: [kın başı z, kın ucu z, kalınlık, genişlik] (silah uzayında, kabza 0, namlu +Z)
const SAYA := {"katana": [0.075, 0.84, 0.042, 0.06], "wakizashi": [0.05, 0.6, 0.04, 0.055], "nodachi": [0.1, 1.38, 0.05, 0.11],
	"tanto": [0.06, 0.4, 0.045, 0.045], "chokuto": [0.13, 0.9, 0.05, 0.05], "raijin": [0.08, 0.86, 0.045, 0.06]}
const SHEATH_DUR := 0.42
const KATANA_TIP_DOWN := -75.0
const BACK_TIP_UP := ["savas_cekici", "uc_tirpan", "mizrak"]

var weapons: Array = []     # [{id, side, kind, node, hand, sheath}]
var drawn := true           # silah elde mi (oyuncu: kınında başlar, saldırınca çekilir)
var _stowed := false        # mühür/jutsu sırasında eller boşalır, silah geçici olarak kına girer
var _sheath_t := -1.0
var _swapped := false
var rig: WeaponRig


const HAND_FRAME := ["tonfa", "pence", "kama", "kusarigama"]


static func sheath_kind(id: String) -> String:
	if SHEATH_ID.has(id):
		return SHEATH_ID[id]
	var st = String(Gear.ITEMS.get(id, {}).get("weapon", {}).get("style", "blade"))
	return SHEATH_OF.get(st, "pouch")


## Jutsu sırasında ele geçici eşya (Uchihagaeshi yelpazesi vb.): o eldeki silah gizlenir, el yumruk olur; dur sonra kaybolur
func hold_temp(id: String, dur: float, side := "Right", scl := 1.0, roll := 0.0, flip := false, procedural := false) -> Node3D:
	if skel == null or skel.find_bone(side + "Hand") < 0:
		return null
	var node: Node3D = null if procedural else SFProps.weapon_node(id)
	if node == null:
		var mi = MeshInstance3D.new()
		mi.mesh = weapon_mesh(id)
		node = mi
	node.transform.basis = (Basis(Vector3.UP, PI) * Basis(Vector3.BACK, roll) if flip else Basis(Vector3.BACK, roll)).scaled(Vector3.ONE * scl)   # roll: uzun eksen etrafında (yelpaze yüzü öne)
	var hand: Node3D = _attach(side + "Hand", _grip_xf(side)).get_child(0)
	hand.add_child(node)
	var hidden = []
	for w in weapons:
		if w["side"] == side and (w["node"] as Node3D).visible:
			(w["node"] as Node3D).visible = false
			hidden.append(w["node"])
	if rig:
		rig.hold[side] = 1.0
	get_tree().create_timer(dur).timeout.connect(func():
		if is_instance_valid(hand):
			hand.get_parent().queue_free()
		for h in hidden:
			if is_instance_valid(h):
				h.visible = true
		_place_weapons())
	return node


func has_weapon() -> bool:
	return not weapons.is_empty()


func _weapons() -> void:
	for pair in [["weapon_r", "Right"], ["weapon_l", "Left"]]:
		var wid = look.get(pair[0])
		if wid == null or wid == "":
			continue
		var side: String = pair[1]
		var id = String(wid)
		if skel.find_bone(side + "Hand") < 0:
			continue
		var node: Node3D = SFProps.weapon_node(id)  # hayran modeli varsa (yoksa prosedürel)
		if node == null:
			var mi = MeshInstance3D.new()
			mi.mesh = weapon_mesh(id)
			node = mi
		if id in HAND_FRAME and side == "Right":
			# tutuş çerçevesi sağ elde z etrafında 180° dönük: yönü ele göre olan silahlar (tonfa gövdesi dirseğe,
			# pençe el sırtına, kama bıçağı parmak eklemlerine) iki elde de aynı tarafa baksın
			var wrap = Node3D.new()
			wrap.add_child(node)
			node.transform.basis = Basis(Vector3.BACK, PI)
			node = wrap
		var hand: Node3D = _attach(side + "Hand", _grip_xf(side)).get_child(0)
		hand.add_child(node)
		if SAYA.has(id):
			node.transform.basis = Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.RIGHT, deg_to_rad(KATANA_TIP_DOWN))
		var kind = sheath_kind(id)
		weapons.append({"id": id, "side": side, "kind": kind, "node": node, "hand": hand, "sheath": _sheath_holder(kind, side, id, node)})


## Avuç içindeki tutma noktası: parmak kökü hizasında, avucun altında; kabza parmaklara dik, namlu başparmak tarafında (+Z ön)
func _grip_xf(side: String) -> Transform3D:
	var hp = _grest(skel.find_bone(side + "Hand")).origin
	var sx = 1.0 if side == "Left" else -1.0
	var mb = skel.find_bone(side + "MiddleProximal")
	var f = (_grest(mb).origin - hp) if mb >= 0 else Vector3(0.085 * sx, 0, 0)
	var x = (f * sx).normalized()
	var z = (Vector3.BACK - x * x.dot(Vector3.BACK)).normalized()
	var y = z.cross(x)
	return Transform3D(Basis(x, y, z), hp + f * 0.8 - y * 0.022)


## z = namlu yönü, xh = silahın kalınlık ekseni (yassı yüzün normali) için ipucu
static func _frame(z: Vector3, xh: Vector3) -> Basis:
	z = z.normalized()
	var x = (xh - z * z.dot(xh)).normalized()
	return Basis(x, z.cross(x), z)


## Silahın kabza->uç uzunluk aralığı (silah uzayında z)
static func _z_span(n: Node3D) -> Vector2:
	var ab: AABB
	if n is MeshInstance3D:
		ab = (n as MeshInstance3D).mesh.get_aabb()
	else:
		ab = SFProps._bounds(n)
	return Vector2(ab.position.z, ab.end.z)


func _sheath_holder(kind: String, side: String, id: String, node: Node3D) -> Node3D:
	if kind == "pouch":
		return null
	var sx = 1.0 if side == "Left" else -1.0
	var span = _z_span(node)
	var mid = (span.x + span.y) * 0.5
	var xf: Transform3D
	match kind:
		"hip":
			# sağ el kılıcı sol kalçada: kabza önde-yukarıda, uç geride-aşağıda
			var hp = _grest(skel.find_bone("Hips")).origin
			var b = _frame(Vector3(-sx * 0.07, -0.62, -1.0), Vector3(-sx, 0, 0))
			xf = Transform3D(b, hp + Vector3(-sx * 0.16, 0.12, 0.15))
		"back":
			# sırtta çapraz: kabza sağ omzun üstünde, uç sol kalçaya doğru; yassı yüz sırta yaslı
			var ch = _grest(skel.find_bone("UpperChest")).origin
			var L = span.y - span.x
			var steep = 1.35 if L > 1.9 else (0.7 if L > 1.2 else 0.55)  # uzun sopalar sırtı daha yatık çaprazlar
			if id == "samehada":
				steep = 0.72   # kaynak (Storm): sırtta ~55° dik çapraz, sap sağ omuzun üstünde
			var dir = Vector3(-sx * steep, -1.0, 0.0)
			if id in BACK_TIP_UP:
				dir = -dir   # ağır başlı silahlar: baş yukarıda (çekiç, tırpan, mızrak)
			var b = _frame(dir, Vector3(0, 0, -1))
			var center = ch + Vector3(0, -0.06, -0.2 - 0.02 * L)
			# sırta yasla: silahın gövdeye bakan yüzü (silah uzayında en küçük x; holder +x sırttan dışarı) sırt yüzeyi + kayış kalınlığında
			var bz = _back_z(ch.y - 0.06)
			if bz < 0.0:
				var wab: AABB = (node as MeshInstance3D).mesh.get_aabb() if node is MeshInstance3D else SFProps._bounds(node)
				var pad = 0.028 + (0.025 if look.get("vest") != null else 0.0) + (0.04 if look.get("outer_style") != null else 0.0)
				var near_x = wab.position.x
				if id == "samehada":
					near_x = -0.12   # yassı gövde yarı kalınlığı (uçtaki pul dikenleri AABB'yi büyütüp silahı sırttan uzaklaştırıyordu)
				center.z = bz - pad + near_x + 0.02
			var mid2 = mid if L > 1.2 else mid * 0.8
			xf = Transform3D(b, center - b.z * mid2)
		"low_back":
			var hp = _grest(skel.find_bone("Hips")).origin
			var b = _frame(Vector3(-sx, 0.12, 0.0), Vector3(0, 0, -1))
			xf = Transform3D(b, hp + Vector3(0, 0.12, -0.17) - b.z * mid)
		_ when id == "tonfa":
			# tonfa: uzun gövde silah uzayında -x boyunca -> gövde uyluk boyunca aşağı sarkar, yan kabza öne bakar
			var hp = _grest(skel.find_bone("Hips")).origin
			var b = _frame(Vector3(sx * 0.15, 0.0, 1.0), Vector3(0, 1, 0))
			xf = Transform3D(b, hp + Vector3(sx * 0.21, 0.05, 0.02))
		_:
			# belt: yan kalçada aşağı sarkar
			var hp = _grest(skel.find_bone("Hips")).origin
			var b = _frame(Vector3(sx * 0.12, -1.0, 0.18), Vector3(sx, 0, 0))
			xf = Transform3D(b, hp + Vector3(sx * 0.2, 0.1, 0.03))
	var holder: Node3D = _attach("UpperChest" if kind == "back" else "Hips", xf).get_child(0)
	if kind == "back" and id in ["bashosen", "samehada", "gunbai"]:
		# Bashōsen / Samehada / Gunbai: havada duran deri kelepçe yok; Samehada ve Gunbai'de göğüs kayışı var (animedeki gibi)
		if id in ["samehada", "gunbai"]:
			_back_strap(sx)
	elif kind == "back":
		_back_strap(sx)
		# iki deri kelepçe: silahı sırttaki kayışa bağlar (holder +x sırttan dışarı, y sırt düzleminde silaha dik)
		var leather = Color(0.3, 0.19, 0.11)
		var cm = MB.new()
		var L = span.y - span.x
		# üst ve alt yarıda kesiti en ince yeri bul (sap, gövde, kın): kelepçe oraya sarılır
		for half in [-1.0, 1.0]:
			var zc = mid + half * L * 0.16
			var ab: AABB = _xsec(node, zc)
			var best = ab.size.y + ab.size.x * 0.5 if ab.size != Vector3.ZERO else 99.0
			for k in 7:
				var z2 = mid + half * L * (0.06 + k * 0.05)
				var a2: AABB = _xsec(node, z2)
				var w2 = a2.size.y + a2.size.x * 0.5
				if a2.size != Vector3.ZERO and w2 < best - 0.01:
					best = w2; ab = a2; zc = z2
			if best > 50.0:
				continue
			var y0 = ab.position.y - 0.012; var y1 = ab.end.y + 0.012
			var x0 = ab.position.x - 0.035; var x1 = ab.end.x + 0.008
			cm.add("box", Vector3(x1, (y0 + y1) * 0.5, zc), Vector3(0.012, y1 - y0 + 0.012, 0.045), leather)
			for yy in [y0, y1]:
				cm.add("box", Vector3((x0 + x1) * 0.5, yy, zc), Vector3(x1 - x0, 0.012, 0.045), leather)
			cm.add("box", Vector3(x1 + 0.006, (y0 + y1) * 0.5, zc), Vector3(0.008, 0.03, 0.03), Color(0.72, 0.66, 0.5))   # toka
		var cmi = MeshInstance3D.new()
		cmi.name = "SirtKelepce"
		cmi.mesh = cm.build(Props.toon())
		holder.add_child(cmi)
	if SAYA.has(id):
		var s: Array = SAYA[id]
		var m = MB.new()
		var lacq = Color(0.09, 0.08, 0.1)
		var gold = Color(0.72, 0.58, 0.3)
		var ln: float = s[1] - s[0]
		m.add("cyl", Vector3(0, 0, s[0] + ln * 0.5), Vector3(s[2], ln, s[3]), lacq, Vector3(90, 0, 0), 10)
		m.add("cyl", Vector3(0, 0, s[0] + 0.012), Vector3(s[2] * 1.15, 0.024, s[3] * 1.12), gold, Vector3(90, 0, 0), 10)
		m.add("cyl", Vector3(0, 0, s[1] - 0.02), Vector3(s[2] * 1.12, 0.04, s[3] * 1.08), gold, Vector3(90, 0, 0), 10)
		# sageo bağı (kına sarılı ip)
		m.add("cyl", Vector3(0, 0, s[0] + ln * 0.14), Vector3(s[2] * 1.18, 0.03, s[3] * 1.16), Color(0.55, 0.1, 0.12), Vector3(90, 0, 0), 10)
		var smi = MeshInstance3D.new()
		smi.mesh = m.build(Props.toon())
		holder.add_child(smi)
	if id == "kusarigama":
		# kınlı hali: zincir kalçada halka halka sarılı, orak sapı aşağı sarkar, ağırlık halkanın altında (sert zincir gövdeden fırlamasın)
		var m2 = MB.new()
		var steel = Color(0.7, 0.72, 0.76)
		var dark = Color(0.22, 0.22, 0.25)
		# uyluk dış yüzü ~0.15 m (pantolonla ~0.17): tutucu 0.2 m + dışa eğik -> parçalar biraz içeri alınır, uyluğa değer
		# tutucu ekseni: +x kalçadan dışarı, +z aşağı, y ileri/geri (bk: geri yönü, tarafa göre işaret değişir)
		var bk = -sx
		for k in 4:
			m2.add("torus", Vector3(-0.035 + 0.005 * k, 0.0, 0.03 + k * 0.022), Vector3(0.13 - k * 0.006, 0.13 - k * 0.006, 0.022), dark, Vector3(0, 90, 0), 12)
		m2.add("sphere", Vector3(-0.01, bk * 0.06, 0.12), Vector3(0.055, 0.055, 0.055), dark, Vector3.ZERO, 8)   # ağırlık
		m2.add("cyl", Vector3(-0.045, 0.0, 0.24), Vector3(0.03, 0.3, 0.03), Color(0.45, 0.32, 0.2), Vector3(90, 0, 0), 8)   # orak sapı uyluğun dış yanında
		# bıçak sapın ucundan geriye-yukarı katlı: sapa paralel uzanır, bacağa girmez
		m2.add("box", Vector3(-0.045, bk * 0.035, 0.31), Vector3(0.01, 0.035, 0.17), steel, Vector3(bk * -12.0, 0, 0))
		var coil = MeshInstance3D.new()
		coil.name = "KusariStow"
		coil.mesh = m2.build(Props.toon())
		coil.visible = false
		holder.add_child(coil)
	return holder


## Silahları duruma göre ele ya da kına yerleştir
func _place_weapons() -> void:
	var in_hand = drawn and not _stowed
	if rig:
		rig.hold = {"Left": 0.0, "Right": 0.0}
	for w in weapons:
		var n: Node3D = w["node"]
		var tgt: Node3D = w["hand"] if (in_hand or w["sheath"] == null) else w["sheath"]
		if n.get_parent() != tgt:
			n.get_parent().remove_child(n)
			tgt.add_child(n)
			n.transform = Transform3D.IDENTITY
		# kılıçlar elde: yassı yatmasın — kendi ekseninde 90° (ağız aşağı), uç biraz aşağı
		if SAYA.has(w["id"]):
			n.transform.basis = Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.RIGHT, deg_to_rad(KATANA_TIP_DOWN)) if n.get_parent() == w["hand"] else Basis.IDENTITY
		n.visible = in_hand or w["sheath"] != null
		if w["id"] == "kusarigama" and w["sheath"] != null:
			var coil = (w["sheath"] as Node3D).get_node_or_null("KusariStow")
			if coil:
				coil.visible = not in_hand
				n.visible = in_hand
		if rig and in_hand:
			rig.hold[w["side"]] = 1.0
		if w["sheath"] != null and w["kind"] == "back":
			for ch in (w["sheath"] as Node3D).get_children():
				if ch != n and ch is MeshInstance3D:
					ch.visible = not in_hand
	for sn in _strap_nodes:
		if is_instance_valid(sn):
			sn.visible = not in_hand


## Silahı çek / kınına sok (animate: kol kına uzanır, silah yer değiştirir, kol geri döner)
func set_drawn(on: bool, animate := true) -> void:
	look["drawn"] = on   # klonlar (bunshin) aynı durumda çıksın
	if weapons.is_empty() or rig == null:
		drawn = on
		return
	if on == drawn and _sheath_t < 0.0:
		return
	drawn = on
	if not animate or _stowed:
		_sheath_t = -1.0
		rig.reach_w = 0.0
		_place_weapons()
		return
	var w0: Dictionary = weapons[0]
	rig.reach_side = w0["side"]
	rig.reach_arms = _reach_pose(w0["kind"], w0["side"])
	_sheath_t = 0.0
	_swapped = false


## Kına uzanan kol pozu (model uzayı yönleri, +Z ön, +X karakterin solu)
static func _reach_pose(kind: String, side: String) -> Array:
	var sx = 1.0 if side == "Left" else -1.0
	var ua = side + "UpperArm"
	var la = side + "LowerArm"
	match kind:
		"back":
			return [[ua, Vector3(sx * 0.3, 0.92, -0.2)], [la, Vector3(-sx * 0.55, 0.35, -0.75)]]
		"hip":
			return [[ua, Vector3(-sx * 0.3, -0.8, 0.5)], [la, Vector3(-sx * 0.92, -0.3, 0.25)]]
		"low_back":
			return [[ua, Vector3(sx * 0.3, -0.75, -0.6)], [la, Vector3(-sx * 0.8, -0.2, -0.55)]]
		"belt":
			return [[ua, Vector3(sx * 0.3, -0.94, -0.1)], [la, Vector3(sx * 0.05, -0.95, 0.3)]]
	return [[ua, Vector3(sx * 0.25, -0.96, -0.05)], [la, Vector3(sx * 0.1, -0.97, 0.2)]]


func _weapon_process(dt: float) -> void:
	if weapons.is_empty() or rig == null:
		return
	if _sheath_t >= 0.0:
		_sheath_t += dt / SHEATH_DUR
		var k = _sheath_t
		var r = k / 0.4 if k < 0.4 else (1.0 - k) / 0.6
		rig.reach_w = smoothstep(0.0, 1.0, clampf(r, 0.0, 1.0))
		if k >= 0.4 and not _swapped:
			_swapped = true
			_place_weapons()
			Sfx.play("whoosh", global_position, 1.6 if drawn else 1.25, 0.35)
		if k >= 1.0:
			_sheath_t = -1.0
			rig.reach_w = 0.0
	# mühür ve jutsu pozunda eller boşalır
	var busy = overlay.weights.get("seal", 0.0) > 0.3 or overlay.weights.get("cast", 0.0) > 0.3
	if busy != _stowed:
		_stowed = busy
		if _sheath_t < 0.0 or _swapped:
			_place_weapons()


## Silah modeli: kabza başlangıçta, namlu +Z yönünde
static var _weapon_cache := {}
## Japon kılıcı ağzı: hafif kavisli (sırt yukarı, +y), uca doğru incelen; kesik kissaki ucu, habaki ve keskin kenarda hamon çizgisi
static func _w_blade(b: MB, z0: float, L: float, w: float, curve: float, steel: Color) -> void:
	# elde tutuşta silah yerel +y aşağı bakıyor: kesit aynalanır -> keskin ağız alta, sırt üste, uç yukarı kalkar (sori)
	var m := -1.0
	var back := PackedVector2Array()
	var edge := PackedVector2Array()
	var n := 14
	for k in n + 1:
		var t := float(k) / n
		var z := z0 + t * L
		var bow := curve * t * t
		var ww := w * (1.0 - t * 0.28)
		if t > 0.9:
			ww *= lerpf(1.0, 0.0, (t - 0.9) / 0.1)   # kissaki
		back.append(Vector2((bow + ww * 0.5) * m, z))
		edge.append(Vector2((bow - ww * 0.5) * m, z))
	var o := PackedVector2Array()
	for p in back:
		o.append(p)
	for k in range(edge.size() - 1, -1, -1):
		o.append(edge[k])
	b.add_slab(o, 0.009, steel, Transform3D.IDENTITY, func(p: Vector2) -> float: return 0.009 if p.y < z0 + L * 0.95 else 0.004, steel.darkened(0.15))
	# hamon: keskin kenar boyunca dalgalı açık şerit (iki yüzde de görünür)
	var hm := PackedVector2Array()
	for k in n:
		var t := float(k) / n
		var z := z0 + 0.02 + t * L * 0.9
		var bow := curve * t * t
		var ww := w * (1.0 - t * 0.28)
		hm.append(Vector2((bow - ww * 0.5 + 0.002) * m, z))
	for k in range(n - 1, -1, -1):
		var t := float(k) / n
		var z := z0 + 0.02 + t * L * 0.9
		var bow := curve * t * t
		var ww := w * (1.0 - t * 0.28)
		hm.append(Vector2((bow - ww * 0.5 + ww * (0.32 + 0.08 * sin(t * 40.0))) * m, z))
	b.add_slab(hm, 0.0105, steel.lightened(0.35))
	b.add("box", Vector3(0, 0, z0 + 0.012), Vector3(0.014, w * 1.05, 0.03), Color(0.8, 0.65, 0.3))   # habaki


## Kılıç sapı (tsuka): koyu öz + çapraz (elmas) sargı + kashira başlığı
static func _w_tsuka(b: MB, z0: float, z1: float, r: float, core: Color) -> void:
	b.add("cyl", Vector3(0, 0, (z0 + z1) * 0.5), Vector3(r * 2.0, z1 - z0, r * 2.0), Color(0.92, 0.9, 0.84), Vector3(90, 0, 0), 10)
	var nb := int((z1 - z0) / 0.035)
	for k in nb:
		var z := z0 + 0.02 + k * 0.035
		for sgn in [1.0, -1.0]:
			b.add("box", Vector3(0, 0, z), Vector3(r * 2.25, r * 2.25, 0.012), core, Vector3(sgn * 35.0, 0, 0))
	b.add("cyl", Vector3(0, 0, z0 - 0.01), Vector3(r * 2.3, 0.025, r * 2.3), core.darkened(0.2), Vector3(90, 0, 0), 10)


## Tsuba (el koruması): oval disk + kenar halkası
static func _w_tsuba(b: MB, z: float, r: float, col: Color) -> void:
	b.add("cyl", Vector3(0, 0, z), Vector3(r * 2.0, 0.008, r * 1.6), col, Vector3(90, 0, 0), 16)
	b.add("torus", Vector3(0, 0, z), Vector3(r * 2.05, 0.01, r * 1.65), col.darkened(0.3), Vector3(90, 0, 0), 16)


## Dev shuriken: göbek + n kavisli, sivri uçlu kol (kesici kenar bir yana kıvrık); göbek z düzleminde (kollar x-y düzleminde)
## Shuriken yıldızı (XY düzleminde, kalınlık Z): n sivri uç, uçlar arası içbükey kenar (düz kesici ağız), ortada delik;
## her ucun ortasında açık renkli bileylenmiş ağız şeridi. Eski kavisli bıçaklar yelpaze gibi duruyordu.
static func _w_star(b: MB, c: Vector3, R: float, w: float, n: int, steel: Color, hub: Color) -> void:
	var to_xy := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))   # profil (u,v) -> dünya (x=-v, y=u)
	var r_in := R * clampf(w / R, 0.26, 0.36)   # uçlar arası iç köşe
	var o := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		var a2 := TAU * (k + 0.5) / n
		o.append(Vector2(sin(a), cos(a)) * R)
		# uçtan iç köşeye hafif içbükey kenar (3 ara nokta)
		for j in [1, 2, 3]:
			var t: float = j / 4.0
			var p: Vector2 = Vector2(sin(a), cos(a)) * R * (1.0 - t) + Vector2(sin(a2), cos(a2)) * r_in * t
			o.append(p * (1.0 - 0.07 * sin(t * PI)))
		o.append(Vector2(sin(a2), cos(a2)) * r_in)
		for j in [1, 2, 3]:
			var t: float = j / 4.0
			var a3 := TAU * (k + 1) / n
			var p: Vector2 = Vector2(sin(a2), cos(a2)) * r_in * (1.0 - t) + Vector2(sin(a3), cos(a3)) * R * t
			o.append(p * (1.0 - 0.07 * sin(t * PI)))
	b.add_slab(o, maxf(0.012, R * 0.03), steel, Transform3D(to_xy, c), func(p: Vector2) -> float: return maxf(0.004, R * 0.03 * (1.0 - 0.75 * p.length() / R)), steel.darkened(0.3))
	# bileylenmiş ağız: her ucun ekseninde ince açık şerit (iki yüzde)
	for k in n:
		var a := TAU * k / n
		for sz in [-1.0, 1.0]:
			var mid := Vector3(-cos(a), sin(a), 0.0) * R * 0.62   # profil ekseni dünyada (x=-v, y=u)
			b.add("box", c + mid + Vector3(0, 0, sz * R * 0.017), Vector3(R * 0.035, R * 0.62, 0.003), steel.lightened(0.35), Vector3(0, 0, 90.0 - rad_to_deg(a)))
	b.add("torus", c, Vector3(r_in * 0.42, r_in * 0.42, r_in * 0.42), hub, Vector3(90, 0, 0), 12)


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
			_w_tsuka(b, -0.2, 0.05, 0.017, dark)
			_w_tsuba(b, 0.065, 0.045, Color(0.2, 0.18, 0.16))
			_w_blade(b, 0.075, 0.72, 0.032, 0.035, steel)
		"musta":
			b.add("box", Vector3(0.0, 0.0, 0.0), Vector3(0.03, 0.1, 0.12), dark)
			b.add("box", Vector3(0, 0, 0.16), Vector3(0.01, 0.03, 0.2), steel)
		"tonfa":
			# yan kabza yumrukta (z ekseni), gövde serçe parmak altında ön kol boyunca (-x: dirseğe doğru) uzanır
			b.add("cyl", Vector3(0, 0, -0.01), Vector3(0.03, 0.12, 0.03), Color(0.35, 0.25, 0.15), Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(-0.14, 0, -0.085), Vector3(0.038, 0.56, 0.038), Color(0.3, 0.22, 0.14), Vector3(0, 0, 90), 10)
			for xx in [-0.41, 0.13]:
				b.add("cyl", Vector3(xx, 0, -0.085), Vector3(0.042, 0.03, 0.042), Color(0.18, 0.13, 0.09), Vector3(0, 0, 90), 10)
		"yelpaze":
			# açık demir savaş yelpazesi (tessen): sap + menteşe, 110° açılmış kâğıt yaprak, demir kaburgalar, kırmızı kenar bandı
			b.add("cyl", Vector3(0, 0, -0.06), Vector3(0.03, 0.2, 0.03), dark, Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.05), Vector3(0.05, 0.03, 0.05), Color(0.6, 0.55, 0.4), Vector3(0, 0, 90), 10)
			var fan = PackedVector2Array([Vector2(0, 0.05)])
			var fan_r = PackedVector2Array()
			for k in 12:
				var a = deg_to_rad(lerpf(-55.0, 55.0, k / 11.0))
				fan.append(Vector2(sin(a) * 0.62, 0.05 + cos(a) * 0.62))
			for k in 12:
				var a = deg_to_rad(lerpf(-55.0, 55.0, k / 11.0))
				fan_r.append(Vector2(sin(a) * 0.62, 0.05 + cos(a) * 0.62))
			for k in range(11, -1, -1):
				var a = deg_to_rad(lerpf(-55.0, 55.0, k / 11.0))
				fan_r.append(Vector2(sin(a) * 0.5, 0.05 + cos(a) * 0.5))
			b.add_slab(fan, 0.008, Color(0.93, 0.9, 0.8))
			b.add_slab(fan_r, 0.012, Color(0.7, 0.12, 0.12))
			for k in 9:
				var a = deg_to_rad(lerpf(-55.0, 55.0, k / 8.0))
				b.add_xf("box", Transform3D(Basis(Vector3.RIGHT, -a) * Basis.from_scale(Vector3(0.016, 0.012, 0.6)), Vector3(0, sin(a) * 0.32, 0.05 + cos(a) * 0.32)), Color(0.22, 0.22, 0.25))
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
			# el sırtı plakası (+y), pençeler parmak eklemlerinin üstünden ileri (+x) uzanır, yumruk boyunca (z) dizilir
			b.add("box", Vector3(-0.02, 0.045, 0.0), Vector3(0.1, 0.02, 0.09), dark)
			b.add("box", Vector3(0.035, 0.035, 0.0), Vector3(0.03, 0.035, 0.085), dark)
			for k in 3:
				b.add("cone", Vector3(0.15, 0.04, (k - 1) * 0.028), Vector3(0.012, 0.22, 0.006), steel, Vector3(0, 0, -90), 4)
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
			_w_tsuka(b, -0.32, 0.06, 0.019, dark)
			_w_tsuba(b, 0.075, 0.055, Color(0.45, 0.36, 0.2))
			_w_blade(b, 0.085, 1.22, 0.042, 0.055, steel)
		"savas_cekici":
			b.add("cyl", Vector3(0, 0, 0.25), Vector3(0.035, 0.95, 0.035), Color(0.35, 0.25, 0.15), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.72), Vector3(0.14, 0.24, 0.16), Color(0.4, 0.4, 0.42))
			b.add("box", Vector3(0, 0, 0.72), Vector3(0.16, 0.06, 0.18), dark)
		"kongo_asa":
			# elmas asa (referans: Maymun Kral'ın dönüştüğü asa): düz siyah gövde, iki uçta kemik beyazı başlık
			b.add("cyl", Vector3(0, 0, 0.15), Vector3(0.05, 2.1, 0.05), Color(0.08, 0.08, 0.09), Vector3(90, 0, 0), 12)
			for z in [-0.86, 1.16]:
				b.add("cyl", Vector3(0, 0, z), Vector3(0.056, 0.18, 0.056), Color(0.88, 0.86, 0.78), Vector3(90, 0, 0), 12)
		"bo":
			b.add("cyl", Vector3(0, 0, 0.1), Vector3(0.036, 1.7, 0.036), Color(0.45, 0.32, 0.2), Vector3(90, 0, 0), 8)
			for z in [-0.72, 0.92]:
				b.add("cyl", Vector3(0, 0, z), Vector3(0.042, 0.08, 0.042), dark, Vector3(90, 0, 0), 8)
		"mizrak":
			b.add("cyl", Vector3(0, 0, 0.2), Vector3(0.032, 1.8, 0.032), Color(0.35, 0.22, 0.15), Vector3(90, 0, 0), 8)
			b.add("cone", Vector3(0, 0, 1.2), Vector3(0.05, 0.24, 0.012), steel, Vector3(90, 0, 0), 4)
			b.add("cyl", Vector3(0, 0, 1.07), Vector3(0.045, 0.04, 0.045), Color(0.6, 0.15, 0.15), Vector3(90, 0, 0), 8)
		"kusarigama":
			b.add("cyl", Vector3(0, 0, 0.02), Vector3(0.032, 0.32, 0.032), Color(0.45, 0.32, 0.2), Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.17), Vector3(0.042, 0.04, 0.042), dark, Vector3(90, 0, 0), 8)   # bilezik
			# orak: sapın ucundan dik çıkar, öne kıvrılan hilal (iç kenar keskin)
			var sick = PackedVector2Array()
			for k in 9:
				var t = k / 8.0
				sick.append(Vector2(-0.01 + t * 0.26, 0.15 + t * t * 0.12))
			for k in range(8, -1, -1):
				var t = k / 8.0
				sick.append(Vector2(-0.01 + t * 0.24, 0.19 + t * t * 0.1 + (1.0 - t) * 0.0))
			b.add_slab(sick, 0.01, steel, Transform3D.IDENTITY, Callable(), steel.darkened(0.2))
			for k in 9:
				b.add("torus", Vector3(0.0, -0.02 - k * 0.04, -0.12 - k * 0.01), Vector3(0.03, 0.03, 0.03), dark, Vector3(90 * (k % 2), 0, 0), 6)
			b.add("sphere", Vector3(0, -0.4, -0.22), Vector3(0.06, 0.06, 0.06), dark, Vector3.ZERO, 8)
		"el_shuriken":
			b.add("cyl", Vector3(0, 0, 0.1), Vector3(0.03, 0.4, 0.03), dark, Vector3(90, 0, 0), 8)   # sap göbeğe kadar
			_w_star(b, Vector3(0, 0, 0.3), 0.34, 0.17, 4, Color(0.5, 0.52, 0.56), dark)
		"kubikiribocho", "samehada", "kiba", "hiramekarei", "shibuki", "nuibari", "kabutowari":
			MistSwords.build(id, b)   # Sis'in Yedi Kılıcı: referansla modellendi
		"chokuto":
			b.add("cyl", Vector3(0, 0, -0.08), Vector3(0.032, 0.22, 0.032), Color(0.85, 0.85, 0.85), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.04), Vector3(0.05, 0.05, 0.02), dark)
			b.add("box", Vector3(0, 0, 0.5), Vector3(0.012, 0.03, 0.88), Color(0.85, 0.87, 0.9))
			b.add("cone", Vector3(0, 0, 0.97), Vector3(0.012, 0.06, 0.03), Color(0.85, 0.87, 0.9), Vector3(90, 0, 0), 4)
		"raijin":
			# yıldırım kılıcı: altın sap ve tsuba, ağız zikzak şimşek biçiminde (sarı-beyaz, ortası daha parlak)
			_w_tsuka(b, -0.2, 0.04, 0.018, Color(0.75, 0.6, 0.2))
			_w_tsuba(b, 0.055, 0.05, Color(0.85, 0.7, 0.3))
			var zz = PackedVector2Array()
			var zl = []
			var zr = []
			for k in 9:
				var z = 0.07 + k * 0.095
				var o = (0.03 if k % 2 == 0 else -0.03) * (1.0 - k / 10.0)
				var w = 0.045 * (1.0 - k / 10.0) + 0.01
				zl.append(Vector2(o - w, z))
				zr.append(Vector2(o + w, z))
			for p in zl:
				zz.append(p)
			zz.append(Vector2(0.0, 0.92))
			for k in range(zr.size() - 1, -1, -1):
				zz.append(zr[k])
			b.add_slab(zz, 0.022, Color(1.0, 0.92, 0.45), Transform3D.IDENTITY, Callable(), Color(1.0, 0.75, 0.2))
			var core = PackedVector2Array()
			for p in zl:
				core.append(Vector2(lerpf(p.x, 0.0, 0.6), p.y))
			core.append(Vector2(0.0, 0.87))
			for k in range(zr.size() - 1, -1, -1):
				core.append(Vector2(lerpf(zr[k].x, 0.0, 0.6), zr[k].y))
			b.add_slab(core, 0.03, Color(1.0, 1.0, 0.92))
		"ruzgar_bicak":
			b.add("box", Vector3(0.0, 0.0, 0.0), Vector3(0.03, 0.1, 0.11), dark)
			b.add("box", Vector3(0, 0.0, 0.17), Vector3(0.012, 0.04, 0.24), Color(0.6, 0.62, 0.66))
			b.add("cone", Vector3(0, 0.0, 0.42), Vector3(0.02, 0.32, 0.07), Color(0.6, 1.0, 0.8), Vector3(90, 0, 0), 4)
		"fuma_shuriken":
			b.add("cyl", Vector3(0, 0, 0.2), Vector3(0.032, 0.6, 0.032), dark, Vector3(90, 0, 0), 8)   # sap göbeğe kadar
			_w_star(b, Vector3(0, 0, 0.5), 0.62, 0.3, 4, Color(0.55, 0.57, 0.62), dark)
		"sai":
			b.add("cyl", Vector3(0, 0, 0.0), Vector3(0.03, 0.12, 0.03), Color(0.2, 0.12, 0.1), Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 0.31), Vector3(0.018, 0.5, 0.018), steel, Vector3(90, 0, 0), 6)
			b.add("cone", Vector3(0, 0, 0.58), Vector3(0.02, 0.05, 0.02), steel, Vector3(90, 0, 0), 6)
			for sx in [-1.0, 1.0]:
				b.add("cyl", Vector3(0.04 * sx, 0, 0.1), Vector3(0.013, 0.1, 0.013), steel, Vector3(0, 0, -60 * sx), 6)
				b.add("cyl", Vector3(0.065 * sx, 0, 0.15), Vector3(0.012, 0.09, 0.012), steel, Vector3(90, 0, 0), 6)
		"uc_tirpan":
			# üç bıçaklı kızıl tırpan: uzun sap, ucunda yelpaze gibi açılmış üç kavisli bıçak
			b.add("cyl", Vector3(0, 0, 0.55), Vector3(0.035, 1.3, 0.035), Color(0.15, 0.12, 0.12), Vector3(90, 0, 0), 8)
			b.add("cyl", Vector3(0, 0, 1.2), Vector3(0.06, 0.08, 0.06), Color(0.3, 0.3, 0.32), Vector3(90, 0, 0), 8)   # bıçak yuvası
			# üç kavisli kızıl bıçak: sapın ucundan aynı yöne (+y) kıvrılır, öndeki en büyük; aralarında boşluk
			for k in 3:
				var sz = 1.0 - k * 0.18
				var z0 = 1.2 - k * 0.11
				var cr = PackedVector2Array()
				# alt (keskin) kenar ve üst kenar aynı x adımında: üst = alt + incelen genişlik (kenarlar kesişmesin)
				for j in 10:
					var t = j / 9.0
					cr.append(Vector2(0.02 + t * 0.55 * sz, z0 + 0.05 - t * t * 0.32 * sz))
				for j in range(9, -1, -1):
					var t = j / 9.0
					cr.append(Vector2(0.02 + t * 0.55 * sz, z0 + 0.05 - t * t * 0.32 * sz + 0.11 * sz * pow(1.0 - t, 0.8) + 0.004))
				b.add_slab(cr, 0.016, Color(0.82, 0.12, 0.1), Transform3D.IDENTITY, Callable(), Color(0.55, 0.06, 0.05))
		"bashosen":
			# Bashōsen (anime): yelpaze düzlemi YZ; sap +Z boyunca, göbek sapın ucunda, tüyler göbekten yelpaze gibi açılır
			var white = Color(0.95, 0.95, 0.93)
			var crimson = Color(0.72, 0.1, 0.2)
			b.add("cyl", Vector3(0, 0, 0.25), Vector3(0.05, 0.5, 0.05), white, Vector3(90, 0, 0), 10)
			for q in 6:
				b.add("cyl", Vector3(0, 0, 0.04 + q * 0.075), Vector3(0.062, 0.022, 0.062), Color(0.82, 0.82, 0.84), Vector3(90, 0, 0), 10)
			var H = Vector3(0, 0, 0.55)
			var L = 0.9
			var n = 17
			for k in n:
				var a = deg_to_rad(lerpf(-80.0, 80.0, float(k) / (n - 1)))
				var w = 0.075
				var xo = 0.004 * (k % 2)
				var xf = Transform3D(Basis(Vector3.RIGHT, a), H + Vector3(xo, 0, 0))
				# beyaz kök kısmı: üst kenarı tırtıklı (anime: beyazla kırmızının sınırı yırtık gibi)
				var wo = PackedVector2Array([Vector2(-w * 0.55, 0.0), Vector2(-w, L * 0.3)])
				var zz = []
				for j in 7:
					var y = lerpf(-w, w, j / 6.0)
					zz.append(Vector2(y, L * (0.74 if j % 2 == 0 else 0.66)))
				for p in zz:
					wo.append(p)
				wo.append(Vector2(w, L * 0.3))
				wo.append(Vector2(w * 0.55, 0.0))
				b.add_slab(wo, 0.012, white, xf)
				# kırmızı uç: aynı tırtıklı sınırdan sivri uca
				var co = PackedVector2Array()
				for j in range(6, -1, -1):
					co.append(zz[j])
				co.append(Vector2(-w * 0.8, L * 0.88))
				co.append(Vector2(0, L))
				co.append(Vector2(w * 0.8, L * 0.88))
				var co2 = PackedVector2Array()
				for j in range(co.size() - 1, -1, -1):
					co2.append(co[j])
				b.add_slab(co2, 0.012, crimson, xf)
			# dipte kırmızı kısa tüy tacı (iki yüzde)
			for sxo in [-0.016, 0.016]:
				for k in 11:
					var a = deg_to_rad(lerpf(-82.0, 82.0, k / 10.0))
					var w2 = 0.045
					var L2 = 0.3 + 0.05 * (1.0 - absf(k - 5) / 5.0)
					var o = PackedVector2Array([Vector2(-w2 * 0.5, 0.0), Vector2(-w2, L2 * 0.5), Vector2(0, L2), Vector2(w2, L2 * 0.5), Vector2(w2 * 0.5, 0.0)])
					b.add_slab(o, 0.01, crimson, Transform3D(Basis(Vector3.RIGHT, a), H + Vector3(sxo, 0, 0)))
			# göbek: beyaz halka + mavi göz (iki yüz)
			b.add("cyl", H, Vector3(0.15, 0.06, 0.15), white, Vector3(0, 0, 90), 16)
			b.add("cyl", H, Vector3(0.09, 0.07, 0.09), Color(0.35, 0.55, 0.85), Vector3(0, 0, 90), 14)
		"gunbai":
			# Madara gunbai'si (kaynak gunbaielde.png / gunbaisirt.png): su kabağı (8) biçimli yelpaze — sapa yakın küçük, uçta büyük
			# yuvarlak lob, belde boğum; kalın koyu gri çerçeve, krem-beyaz yüz, iki lobda 3'er kırmızı tomoe; yüzün ortasından
			# boydan boya geçen ince krem sap (uçta topuz), dipte zincir halkaları. Yüz normali +X (sırta yassı yaslanır).
			var rimc = Color(0.3, 0.3, 0.33)
			var facec = Color(0.93, 0.92, 0.87)
			var polec = Color(0.9, 0.87, 0.78)
			var tomo = Color(0.78, 0.08, 0.08)
			var c1 = 1.16; var r1 = 0.36   # sapa yakın küçük lob
			var c2 = 1.84; var r2 = 0.48   # uçtaki büyük lob (belde boğum)
			var wfn = func(z: float, inset: float) -> float:
				var w1 = sqrt(maxf(0.0, (r1 - inset) * (r1 - inset) - (z - c1) * (z - c1)))
				var w2 = sqrt(maxf(0.0, (r2 - inset) * (r2 - inset) - (z - c2) * (z - c2)))
				return maxf(w1, w2)
			var outline = func(inset: float) -> PackedVector2Array:
				var z0 = c1 - r1 + inset
				var z1 = c2 + r2 - inset
				var right = []
				for k in 49:
					var u = 0.5 - 0.5 * cos(PI * k / 48.0)   # uçlarda sık örnek: yuvarlak biter
					var z = lerpf(z0, z1, u)
					right.append(Vector2(wfn.call(z, inset), z))
				var o = PackedVector2Array()
				for p in right:
					o.append(p)
				for i in range(right.size() - 2, 0, -1):
					o.append(Vector2(-right[i].x, right[i].y))
				return o
			b.add_slab(outline.call(0.0), 0.06, rimc)
			b.add_slab(outline.call(0.075), 0.072, facec)
			# sap: yüzün ortasından boydan boya, uçta topuz; dipte halka ve zincir
			var p0 = -0.16
			var p1 = c2 + r2 + 0.06
			b.add("cyl", Vector3(0, 0, (p0 + p1) * 0.5), Vector3(0.042, p1 - p0, 0.042), polec, Vector3(90, 0, 0), 10)
			b.add("sphere", Vector3(0, 0, p1), Vector3(0.07, 0.07, 0.07), polec, Vector3.ZERO, 10)
			b.add("cyl", Vector3(0, 0, p0 + 0.02), Vector3(0.06, 0.04, 0.06), polec.darkened(0.25), Vector3(90, 0, 0), 10)
			b.add("sphere", Vector3(0, 0, p0), Vector3(0.055, 0.055, 0.055), polec.darkened(0.25), Vector3.ZERO, 10)
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
	_set_eye_trails(kind_r, kind_l)
	if sclera_mat:
		var rc = Color(0.74, 0.66, 0.92)
		var kc = Color(0.78, 0.1, 0.1)   # Ketsuryūgan: göz akı da kan kırmızısı
		sclera_mat.set_shader_parameter("tint_r", rc if kind_r == 6 else (kc if kind_r == 3 else Color.WHITE))
		sclera_mat.set_shader_parameter("tint_l", rc if kind_l == 6 else (kc if kind_l == 3 else Color.WHITE))
		sclera_mat.set_shader_parameter("rings_r", 1.0 if kind_r == 6 else 0.0)
		sclera_mat.set_shader_parameter("rings_l", 1.0 if kind_l == 6 else 0.0)
	if eye_mat:
		eye_mat.set_shader_parameter("dojutsu", kind_r)
		eye_mat.set_shader_parameter("tomoe", lvl_r)
		eye_mat.set_shader_parameter("dojutsu_l", kind_l)
		eye_mat.set_shader_parameter("tomoe_l", lvl_l)
	if body_mesh:
		var m = body_mesh.get_surface_override_material(0)
		if m is ShaderMaterial:
			m.set_shader_parameter("byakugan_veins", 1.0 if veins else 0.0)
	if face_skin_mat:
		face_skin_mat.set_shader_parameter("byakugan_veins", 1.0 if veins else 0.0)


## Kırmızı dōjutsu (Sharingan, Mangekyō, Ketsuryūgan) açıkken gözlerden ince ışık izi (Shinobi Striker tarzı)
func _set_eye_trails(kind_r: int, kind_l: int) -> void:
	for t in _eye_trails:
		if is_instance_valid(t):
			t.queue_free()
	_eye_trails.clear()
	if skel == null or skel.find_bone("Head") < 0:
		return
	var red = [1, 3, 4, 5]
	for pair in [[kind_r, -1.0], [kind_l, 1.0]]:
		if not int(pair[0]) in red:
			continue
		# model önü -Z ise göz yönü; yüz modeli eye_center_model'i model uzayında verir
		# iz gözün dış köşesinden çıkar: göz bebeğinin üstünde parlayıp Sharingan desenini kapatmasın
		var at = eye_center_model + Vector3(-eye_half * 1.55 * float(pair[1]), 0.003, 0.0)
		var ba = _attach("Head", Transform3D(Basis.IDENTITY, at))
		var tr = EyeTrail.new()
		tr.anchor = ba.get_child(0)
		tr.set_meta("side", float(pair[1]))
		if int(pair[0]) == 3:
			tr.col = Color(0.9, 0.05, 0.12)
		add_child(tr)
		_eye_trails.append(tr)
		_eye_trails.append(ba)


## Özel Mangekyō desenleri (Eyes.design_vecs ile)
func set_ms_designs(right: Dictionary, left: Dictionary) -> void:
	# göz ışık izi deseninin rengini alır (sağ göz -1, sol göz +1)
	for t in _eye_trails:
		if t is EyeTrail and is_instance_valid(t):
			var dd: Dictionary = right if float(t.get_meta("side", -1.0)) < 0.0 else left
			if dd.has("col"):
				var cc: Array = dd["col"]
				t.set_color(Color(cc[0], cc[1], cc[2]))
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


## Uzun ağızlı silahlar (Samehada, Kubikiribōchō, Kiba...) beklerken elin ekseninde kalınca başın önünden geçip yüzü kapatıyordu:
## duruştayken ağız omzun üstünden başın arkasına yatırılır; saldırıda kolla aynı hizaya döner
static var REST_TILT_OF := {"samehada": Vector3(-140, 40, 0), "gunbai": Vector3(-40, -100, 30)}   # gunbai: sağ yanda yukarı-dışa (kafaya ve yere girmez)   # silaha özel bekleme eğimi (kafanın içinden geçmesin)
const REST_TILT := Vector3(-25.0, -55.0, 0.0)


func _rest_tilt(on: bool, dt: float) -> void:
	for w in weapons:
		var n: Node3D = w["node"]
		if n.get_parent() != w["hand"] or SAYA.has(w["id"]):
			continue   # katana/wakizashi: ince namlu yüzü kapatmaz; yana yatırma kılıcı yan gösteriyordu
		if not w.has("long"):
			var sp = _z_span(n)
			w["long"] = sp.y - sp.x > 0.85
		if not w["long"]:
			continue
		var sx = 1.0 if w["side"] == "Right" else -1.0
		var rt: Vector3 = REST_TILT_OF.get(w["id"], REST_TILT)
		var tgt = Basis.from_euler(Vector3(deg_to_rad(rt.x), deg_to_rad(rt.y * sx), deg_to_rad(rt.z * sx))) if on else Basis.IDENTITY
		var cur_q = n.transform.basis.get_rotation_quaternion()
		var q = cur_q.slerp(tgt.get_rotation_quaternion(), minf(1.0, dt * (6.0 if on else 14.0)))
		n.transform.basis = Basis(q).scaled(n.transform.basis.get_scale())


## anahtar animasyonlu silahlar: [tutuş kaydırma (yumruk sap boyunca ileri), iz başı z, iz ucu z, elden uca boy]
const KEY_WEAPON := {"samehada": [0.58, 0.45, 1.9, 1.95], "gunbai": [0.0, 0.85, 2.3, 2.4]}


## Anahtar animasyon bitince silahın kaydırılmış konumunu geri al
func _key_blade() -> void:
	if overlay != null and overlay.key_t >= 0.0:
		return
	for w in weapons:
		if w.has("key_pos0") and is_instance_valid(w["node"]):
			(w["node"] as Node3D).position = w["key_pos0"]
			w.erase("key_pos0")
		if w.has("trail"):
			if is_instance_valid(w["trail"]):
				w["trail"].active = false
			w.erase("trail")


## Anahtar kare animasyonunda (Samehada kombosu) sağ eldeki silah pozdaki "blade" yönüne çevrilir.
## İSKELET GÜNCELLEMESİNİN İÇİNDE çağrılır (kol pozu uygulandıktan hemen sonra): bir kare gecikmeyle elden kopmaz.
## Yumruk sapın en ucunda (silah sap boyunca kaydırılır); kılıç ucu yere girecekse yerin hemen üstüne kaldırılır.
func _key_blade_sk(sk: Skeleton3D, blade: Vector3) -> void:
	var hb = sk.find_bone("RightHand")
	if hb < 0:
		return
	var hp: Transform3D = sk.get_bone_global_pose(hb)
	var skb = sk.global_transform.basis
	for w in weapons:
		var n: Node3D = w["node"]
		if w["side"] != "Right" or n.get_parent() != w["hand"] or not is_instance_valid(n):
			continue
		var holder: Node3D = w["hand"]
		var pb: Basis = (hp.basis * holder.transform.basis).orthonormalized()   # silahın ebeveyni, iskelet uzayında
		var sc: Vector3 = n.transform.basis.get_scale()
		if not w.has("key_pos0"):
			w["key_pos0"] = n.position
		if not w.has("trail") and is_inside_tree():
			var tr = SwordTrail.new()
			tr.node = n
			var kp0: Array = KEY_WEAPON.get(w["id"], [0.0, 0.5, 1.8, 2.0])
			tr.z0 = kp0[1]
			tr.z1 = kp0[2]
			get_tree().current_scene.add_child(tr)
			w["trail"] = tr
		var kp: Array = KEY_WEAPON.get(w["id"], [0.0, 0.5, 1.8, 2.0])   # [tutuş kaydırma, iz başı, iz ucu, boy]
		var grip = float(kp[0]) * sc.z
		# yer kontrolü (dünya): el + uç * boy yerin altına inmesin
		var z: Vector3 = blade.normalized()
		var gscale = (skb * pb).get_scale().z
		var hand_w: Vector3 = sk.global_transform * (hp * holder.transform * w["key_pos0"])
		var dir_w: Vector3 = (skb.orthonormalized() * z).normalized()
		var length = (float(kp[3]) + float(kp[0])) * sc.z * gscale
		var floor_y = global_position.y + 0.12
		var tip_y = hand_w.y + dir_w.y * length
		if tip_y < floor_y and length > 0.1:
			var need = clampf((floor_y - hand_w.y) / length, -1.0, 0.95)
			var hz = Vector3(dir_w.x, 0, dir_w.z)
			if hz.length() < 0.05:
				hz = skb.orthonormalized().z
			hz = hz.normalized() * sqrt(maxf(0.0, 1.0 - need * need))
			dir_w = Vector3(hz.x, need, hz.z)
			z = (skb.orthonormalized().inverse() * dir_w).normalized()
		var x = Vector3.UP.cross(z)
		if x.length() < 0.1:
			x = Vector3.RIGHT
		x = x.normalized()
		var want = Basis(x, z.cross(x).normalized(), z)
		if overlay.key_roll != 0.0:
			want = want * Basis(Vector3.BACK, deg_to_rad(overlay.key_roll))   # sap ekseni etrafında (gunbai yüzü rakibe)
		var q = (pb.inverse() * want).get_rotation_quaternion()
		n.transform.basis = Basis(q).scaled(sc)
		n.position = w["key_pos0"] + n.transform.basis.z.normalized() * grip


func flash(amount: float) -> void:
	hit_flash = maxf(hit_flash, amount)


## Darbe tepkisi (dünya yönünde itiş): poz katmanında gövde/kafa savrulur
func react(world_dir: Vector3, amp: float, head := false) -> void:
	if overlay == null:
		return
	var d = global_transform.basis.inverse() * world_dir
	overlay.hit_react(d, amp, head)


const STANCE_ID := {"samehada": "w_samehada"}   # silaha özel duruş
const STANCE_OF := {"blade": "w_blade", "dual": "w_dual", "sickle": "w_dual", "claw": "w_dual", "sword": "w_sword", "heavy": "w_shoulder", "staff": "w_shoulder", "chain": "w_dual", "fan": "w_fan"}   # kusarigama alçak tek el (omuzda bıçak kafaya değmesin)
var stance := ""


func _stance_for_look() -> String:
	for k in ["weapon_r", "weapon_l"]:
		var wid = look.get(k)
		if wid != null and wid != "":
			if STANCE_ID.has(String(wid)):
				return STANCE_ID[String(wid)]
			var w: Dictionary = Gear.ITEMS.get(String(wid), {}).get("weapon", {})
			if not w.is_empty():
				return STANCE_OF.get(w.get("style", ""), "")
	return ""


func _process(dt: float) -> void:
	# silah duruşu: beklerken/yürürken silaha göre kollar; saldırı, mühür ve ninja koşusunda kapanır
	_weapon_process(dt)
	if stance != "" and overlay:
		var on = drawn and not _stowed and overlay.key_t < 0.0 and current in ["idle", "walk", "jog", "run", "air", "fall", "sword_idle"] and overlay.weights.get("ninja_run", 0.0) < 0.5 and overlay.weights.get("leap", 0.0) < 0.3
		overlay.set_pose(stance, 1.0 if on else 0.0)
		if overlay.key_t < 0.0:
			_rest_tilt(on, dt)
	_key_blade()
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - dt * 5.0)
		for m in materials:
			m.set_shader_parameter("hit_flash", hit_flash)
