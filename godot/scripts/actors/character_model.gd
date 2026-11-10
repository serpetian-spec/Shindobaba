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
const AnimeHair = preload("res://scripts/actors/anime_hair.gd")   # sıfırdan anime saçı
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
	# sıfırdan anime saçları (AnimeHair): VRoid tabanı yok
	"s1": ["", "", "s1"],
	"s2": ["", "", "s2"],
	"s3": ["", "", "s3"],
	"s4": ["", "", "s4"],
	"s5": ["", "", "s5"],
	"s6": ["", "", "s6"],
	"s7": ["", "", "s7"],
	"s8": ["", "", "s8"],
	"s9": ["", "", "s9"],
	"s10": ["", "", "s10"],
	"s11": ["", "", "s11"],
	"s12": ["", "", "s12"],
	"s13": ["", "", "s13"],
	"s14": ["", "", "s14"],
	"s15": ["", "", "s15"],
	"s16": ["", "", "s16"],
	"s17": ["", "", "s17"],
	"s18": ["", "", "s18"],
	"s19": ["", "", "s19"],
	"s20": ["", "", "s20"],
	"s21": ["", "", "s21"],
	"s22": ["", "", "s22"],
	"s23": ["", "", "s23"],
	"s24": ["", "", "s24"],
	"f1": ["", "", "f1"],
	"f2": ["", "", "f2"],
	"f3": ["", "", "f3"],
	"f4": ["", "", "f4"],
	"f5": ["", "", "f5"],
	"f6": ["", "", "f6"],
	"f7": ["", "", "f7"],
	"f8": ["", "", "f8"],
	"f9": ["", "", "f9"],
	"f10": ["", "", "f10"],
	"f11": ["", "", "f11"],
	"f12": ["", "", "f12"],
	"f13": ["", "", "f13"],
	"f14": ["", "", "f14"],
	"f15": ["", "", "f15"],
	"f16": ["", "", "f16"],
	"f17": ["", "", "f17"],
	"f18": ["", "", "f18"],
	"f19": ["", "", "f19"],
	"f20": ["", "", "f20"],
	"f21": ["", "", "f21"],
	"f22": ["", "", "f22"],
	"f23": ["", "", "f23"],
	"f24": ["", "", "f24"],
	"d0": ["", "", "d0"],
	"d1": ["", "", "d1"],
	"d2": ["", "", "d2"],
	"d3": ["", "", "d3"],
	"d4": ["", "", "d4"],
	"d5": ["", "", "d5"],
	"d6": ["", "", "d6"],
	"d8": ["", "", "d8"],
	"d9": ["", "", "d9"],
	"d10": ["", "", "d10"],
	"d11": ["", "", "d11"],
	"d14": ["", "", "d14"],
	"d15": ["", "", "d15"],
	"d16": ["", "", "d16"],
	"d17": ["", "", "d17"],
	"d18": ["", "", "d18"],
	"d20": ["", "", "d20"],
	"d22": ["", "", "d22"],
	"d23": ["", "", "d23"],
	"d24": ["", "", "d24"],
	"d25": ["", "", "d25"],
	"d26": ["", "", "d26"],
	"d27": ["", "", "d27"],
	"d28": ["", "", "d28"],
	"d29": ["", "", "d29"],
	"d30": ["", "", "d30"],
	"d32": ["", "", "d32"],
	"d33": ["", "", "d33"],
	"d34": ["", "", "d34"],
	"d35": ["", "", "d35"],
	"d36": ["", "", "d36"],
	"d37": ["", "", "d37"],
	"d39": ["", "", "d39"],
	"d40": ["", "", "d40"],
	"d41": ["", "", "d41"],
	"d42": ["", "", "d42"],
	"d43": ["", "", "d43"],
	"d44": ["", "", "d44"],
	"d45": ["", "", "d45"],
	"e0": ["", "", "e0"],
	"e2": ["", "", "e2"],
	"e3": ["", "", "e3"],
	"e4": ["", "", "e4"],
	"e5": ["", "", "e5"],
	"e6": ["", "", "e6"],
	"e7": ["", "", "e7"],
	"e8": ["", "", "e8"],
	"e9": ["", "", "e9"],
	"e10": ["", "", "e10"],
	"e11": ["", "", "e11"],
	"e12": ["", "", "e12"],
	"e13": ["", "", "e13"],
	"e14": ["", "", "e14"],
	"e15": ["", "", "e15"],
	"e22": ["", "", "e22"],
	"e23": ["", "", "e23"],
	"e26": ["", "", "e26"],
	"e27": ["", "", "e27"],
	"e28": ["", "", "e28"],
	"e29": ["", "", "e29"],
	"e30": ["", "", "e30"],
	"e31": ["", "", "e31"],
	"e32": ["", "", "e32"],
	"e33": ["", "", "e33"],
	"e34": ["", "", "e34"],
	"e35": ["", "", "e35"],
	"e36": ["", "", "e36"],
}
const VROID_SKIN := Color(0.99, 0.89, 0.82)  # VRoid doku ten rengi (oyuncu teni bununla oranlanır)
static var _scenes := {}
static var _donor_cache := {}
var face_mi: MeshInstance3D
var _face_xf := Transform3D.IDENTITY   # yüz mesh'i yerel -> model uzayı
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
		var path = "res://assets/vrm/%s.glb" % n
		if _prewarm.has(path) and ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_scenes[n] = ResourceLoader.load_threaded_get(path)   # arka planda önceden yüklendi (bekler, ama çoğu zaman hazır)
		else:
			_scenes[n] = load(path)
	return _scenes[n]


static var _build_frame := -1


## Ortam NPC'leri (yolcu, gezgin takım) için model kurma sırası: karede en fazla bir model kurulur, gerisi sonraki karelere
## kayar (bir karede 3-4 model = 300-650 ms donma). Kullanım: await CharacterModel.build_turn(self); sonra is_instance_valid kontrol.
static func build_turn(n: Node) -> void:
	while Engine.get_process_frames() == _build_frame and is_instance_valid(n) and n.is_inside_tree():
		await n.get_tree().process_frame
	_build_frame = Engine.get_process_frames()


## Yükleme ekranında her kıyafet türü × cinsiyet için birer deneme modeli kurup siler: giysi/halka/saç/bant önbellekleri dolar.
## Önbellekte olmayan bir giysiyi giyen ilk NPC'nin kurulumu 100-250 ms sürüyordu (dövüşe katılan takımda donma);
## önceden ısınınca aynı kurulum ~15 ms.
const WARM_ARCHES := ["genin", "chunin", "jonin", "rogue", "bandit", "samurai", "traveler", "merchant", "farmer", "monk", "elder", "medic", "noble", "worker", "sennin", "kid", "student"]
static var warmed := false


static func prewarm_looks(parent: Node, progress: Callable = Callable()) -> void:
	if warmed:
		return
	warmed = true
	var holder = Node3D.new()
	parent.add_child(holder)
	holder.position = Vector3(0, -900, 0)
	holder.visible = false
	var vs = ["konoha", "suna", "kiri", "kumo", "iwa"]
	var i = 0
	var total = WARM_ARCHES.size() * 2
	for a in WARM_ARCHES:
		for gd in ["m", "f"]:
			var lk = default_look()
			lk.merge(Outfits.roll(a, vs[i % vs.size()]), true)
			lk["gender"] = gd
			var cm = CharacterModel.new()
			holder.add_child(cm)
			cm.setup(lk)
			cm.free()
			i += 1
			if i % 4 == 0:
				if progress.is_valid():
					progress.call(float(i) / total, "")
				await parent.get_tree().process_frame
	holder.queue_free()


static var _prewarm := {}
## Oyun açılınca tüm VRoid saç/yüz/gövde modellerini arka planda yükle: köylü ilk kez o saçla kurulurken
## ana iş parçacığında ~230 ms dosya yükleme donması olmasın
static func prewarm() -> void:
	if not _prewarm.is_empty():
		return
	for f in DirAccess.get_files_at("res://assets/vrm"):
		var f2 = f.trim_suffix(".import").trim_suffix(".remap")
		if not f2.ends_with(".glb"):
			continue
		var path = "res://assets/vrm/" + f2
		if _prewarm.has(path):
			continue
		_prewarm[path] = true
		ResourceLoader.load_threaded_request(path, "PackedScene", true)


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
		_face_xf = place
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
				eye_mat.set_shader_parameter("simple_hl", 1.0 if look.get("gender", "m") == "f" else 0.0)
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
				var fpid = String(look.get("face_paint", "yok")) if look.get("face_paint") != null else "yok"
				if fpid != "yok" and ResourceLoader.exists("res://assets/facepaint/%s.png" % fpid):
					sm.set_shader_parameter("paint_tex", load("res://assets/facepaint/%s.png" % fpid))
					var pc = face_paint_color(look)
					sm.set_shader_parameter("paint_col", Color(pc.r, pc.g, pc.b, 1.0))
					var natural = not (look.get("face_paint_col") is Color and (look["face_paint_col"] as Color).a > 0.0)
					sm.set_shader_parameter("paint_natural", fpid.begins_with("x") and natural)   # renkli desen (Gül, Kamuflaj...) kendi renkleriyle
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
				elif look.get("gender", "m") == "f" and (mname.contains("Eyelash") or mname.contains("Eyeline")):
					cm.albedo_color = Color(0.32, 0.2, 0.18)   # VRoid kadın yüzü: kirpik/göz çizgisi pembe-kırmızıydı -> koyu kahve (anime)
				elif look.get("gender", "m") == "f" and mname.contains("EyeHighlight"):
					face_mi.set_surface_override_material(si, _invisible_mat())   # irisin içindeki "+" yıldız parıltıları (kullanıcı: "bu gözler ne?")
					continue
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
		_face_src = [fd["mesh"], place]   # saç tutamları gerçek alın/yüz yüzeyini izlesin (_head_radial)
		var sk_key = "%s|%s|%s" % [look["gender"], donor, look.get("age", "adult")]
		_sk_key = sk_key
		if _skull_cache.has(sk_key):
			var sc = _skull_cache[sk_key]
			skull_c = sc[0]; skull_r = sc[1]; band_ring = sc[2]
		else:
			_measure_skull(fd["mesh"], place)
			_skull_cache[sk_key] = [skull_c, skull_r, band_ring]
	# saç: VRoid saç mesh'i + gerekirse prosedürel tutam eklentisi (diken, topuz, at kuyruğu...)
	var hd: Array = HAIR_DONORS.get(look.get("hair_style", "diken"), HAIR_DONORS["diken"])
	if hd.size() > 2 and hd[2] != "" and head_ab.size.x > 0.05 and look.get("npc", false) and not look.get("keep_hair", false):   # keep_hair: kimliği olan karakter (dost, Bingo kaçağı, takım) saçını asla değiştirmez
		# köylü: bu yüz için hesaplanmamış saç tutamı ~140 ms donma demek. Yakın zamanda yeni hesap yapıldıysa
		# bu yüzde hazır (önbellekte) ya da tutamsız bir saç stili seç; çeşitlilik zamanla artar, donma olmaz
		var hk0 = "vroid|%s|%s|%s|%s" % [hd[2], look["gender"], donor, look.get("age", "adult")]
		var now = Time.get_ticks_msec()
		# anime saçı ~35 ms (eski tutam 140 ms): pencere 1.2 sn; yerine yalnız bu cinsiyetin HAZIR anime saçlarından seçilir
		# (eski düz VRoid saçına düşmez); hiç hazır yoksa istenen saç yine kurulur
		if not _hair_cache.has(hk0) and (now - _hair_new_ms < 1200 or look.get("npc_strict", false)):
			var opts = []
			for st in hair_styles_for(String(look["gender"])):
				if AnimeHair.has(st) and _hair_cache.has("vroid|%s|%s|%s|%s" % [st, look["gender"], donor, look.get("age", "adult")]):
					opts.append(st)
			if not opts.is_empty():
				look["hair_style"] = opts.pick_random()
				hd = HAIR_DONORS[look["hair_style"]]
			else:
				_hair_new_ms = now
		elif not _hair_cache.has(hk0):
			_hair_new_ms = now
	if hd.size() > 2 and hd[2] != "" and head_ab.size.x > 0.05:
		# önbellek anahtarı kafa ölçüsüne bağlı (yaş/cinsiyet/yüz değişince saç kafada kalsın)
		var hk = "vroid|%s|%s|%s|%s" % [hd[2], look["gender"], donor, look.get("age", "adult")]
		var banded = look.get("band") != null and String(look.get("band_style", "none")) in ["head", "slashed"]
		if AnimeHair.has(hd[2]) and banded:
			hk += "|band"   # alın bandı takılı: kâkül bandın altında, bandın üstünden dik tutamlar (saçak gibi raf olmasın)
		if not _hair_cache.has(hk):
			if AnimeHair.has(hd[2]):   # sıfırdan anime saçı (VRoid tabanı yok)
				_hair_cache[hk] = AnimeHair.build(hd[2], skull_c, skull_r, banded, (band_ring[0] + 0.01) if (banded and not band_ring.is_empty()) else -INF, _head_radial(), BAND_DROP)
				_hair_dyn[hk] = _anime_dangle(_hair_cache[hk], AnimeHair.strands)   # kâkül/ense/favori salınır, dikenler hafif yaylanır
			else:
				_hair_cache[hk] = _hair_clumps(hd[2], skull_c, skull_r)
				_hair_dyn[hk] = _clump_dangle(_hair_cache[hk])
		var cm = ShaderMaterial.new()
		cm.shader = load("res://shaders/toon.gdshader")
		cm.set_shader_parameter("tint", look["hair"])
		cm.set_shader_parameter("rim_amount", 0.45)
		materials.append(cm)
		# tutamlar kafaya göre biraz küçültülür (kafa merkezi etrafında)
		var cs = Transform3D(Basis.IDENTITY, skull_c) * Transform3D(Basis.from_scale(Vector3.ONE * CLUMP_SCALE), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -skull_c)
		if AnimeHair.has(hd[2]):
			cs = Transform3D.IDENTITY
			_anime_hair_vs = (_hair_cache[hk] as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		# uzun tutamlar ikincil hareketli (kafa kemiğine takılı küçük iskelet); sallanacak tutam yoksa sabit mesh
		_hair_mats.append([cm, cs])
		var hdn = add_dangle("Head", _hair_dyn.get(hk, {}), cm, cs, "HairDangle") if not _hair_dyn.get(hk, {}).is_empty() else null
		if hdn == null:
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
			# uzun saç: kulak hizasının altında kalan kısım dilim zincirleriyle sallanır (sırta/omuza çarpar)
			var vxf = hair_mi.transform
			var vk = "%s|%s|%s|%s|%s" % [hd[0], hd[1], donor, look["gender"], look.get("age", "adult")]   # saç stili adı gereksizdi (aynı VRoid saçı tekrar hesaplanıyordu)
			var vnow = Time.get_ticks_msec()
			if not _vhair_dyn.has(vk) and look.get("npc", false) and (vnow - _hair_new_ms < 6000 or look.get("npc_strict", false)):
				pass   # köylü: art arda yeni saç sallanma hesabı (~200 ms) yapma; bu köylünün saçı sabit kalır
			elif not _vhair_dyn.has(vk):
				if look.get("npc", false):
					_hair_new_ms = vnow
				_vhair_dyn[vk] = Dangle.sectors(hp["mesh"], head_rest * hair_mi.transform, skull_c, skull_c.y + skull_r.y * 0.2, {"fade": 0.09})   # alın hizasından aşağısı (perçemler, yanlar, ense) oynar
			var vd = Dangle.make(_vhair_dyn[vk]) if _vhair_dyn.has(vk) else null
			if vd != null:
				vd.transform = hair_mi.transform
				holder2.add_child(vd)
				_dangles.append(vd)
				hair_mi.free()
				hair_mi = vd.mi
				hair_mi.name = "VHair"
			else:
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
				_hair_mats.append([hm, head_rest * vxf])


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
	look["hair_style"] = HAIR_ALIAS.get(look.get("hair_style", "diken"), look.get("hair_style", "diken"))
	if not look.get("own_hair", false) and not AnimeHair.has(String(look["hair_style"])) and String(look["hair_style"]) != "kel":
		look["hair_style"] = npc_hair(look)   # NPC'ler de anime saçlarını kullanır (kullanıcı 2026-11-10); eski saç adları eşlenir
	if String(HAIR_GENDER.get(look["hair_style"], "")) not in ["", String(look.get("gender", "m"))]:
		look["hair_style"] = "kısa" if look.get("own_hair", false) else npc_hair(look)   # karşı cinsin saçı: NPC kendi cinsinin anime saçına, oyuncu düz saça
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
	_apply_hair_mask()
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
	if skel.find_bone("LeftHand") >= 0:
		var lr = _grest(skel.find_bone("LeftHand"))
		rig.left_holder = (lr.basis.orthonormalized().inverse() * _grip_xf("Left").basis.orthonormalized())
		rig.left_grip_pos = lr.basis.orthonormalized().inverse() * (_grip_xf("Left").origin - lr.origin)
	drawn = look.get("drawn", true)
	_place_weapons()
	_register_forearm_lock()
	apply_age(look.get("age", "adult"))
	stance = _stance_for_look()
	play("idle", 0.0)
	_queue_shadow_trim()


## Performans: küçük parçalar (kıyafet ayrıntısı, aksesuar, küçük silah) gölge düşürmez. Güneş gölgesi 4 kademeli olduğundan
## her gölgeli parça 4 kata kadar yeniden çiziliyordu (düşman başına ~170 çizim; 3+ kişide FPS çöküyordu). Gövde, yüz, saç,
## kıyafet kabuğu ve büyük parçalar (pelerin, dev silah) gölgede kalır: gölge silueti aynı görünür.
const SHADOW_KEEP := ["Body", "VHair", "HairDangle", "Cloth"]
var _trim_queued := false


func _queue_shadow_trim() -> void:
	if not _trim_queued:
		_trim_queued = true
		call_deferred("_shadow_trim")


func _shadow_trim() -> void:
	_trim_queued = false
	var npc = not (get_parent() is Player)
	for mi in find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or String(mi.name) in SHADOW_KEEP:
			continue
		var sz: Vector3 = mi.get_aabb().size * mi.global_basis.get_scale()
		var big = maxf(sz.x, maxf(sz.y, sz.z))
		if big < 0.9:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if npc and big < 0.35 and String(mi.name) != "VFace" and mi.visibility_range_end <= 0.0:
			mi.visibility_range_end = 40.0   # uzak NPC'de minik ayrıntı (düğme, kemer tokası, küçük alet) çizilmez


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


var _anim_speed := 1.0


## Oyuncunun modeli mi: Sharingan algı yavaşlamasında animasyonlar telafi edilir (dünya yavaş, sen normal)
func _time_comp() -> float:
	var par = get_parent()
	return Combat.player_comp() if par is Player else 1.0


## Animasyon oynat (aynı animasyon tekrar istenirse yeniden başlatmaz, restart=true hariç)
func play(key: String, blend := 0.15, speed := 1.0, restart := false) -> void:
	var full: String = ANIM.get(key, key)
	if not anim.has_animation(full):
		return
	if current == key and not restart and anim.is_playing():
		_anim_speed = speed
		anim.speed_scale = speed * _time_comp()
		return
	current = key
	anim.play(full, blend, 1.0)
	_anim_speed = speed
	anim.speed_scale = speed * _time_comp()
	if restart:
		anim.seek(0.0, true)


## [boy, kafa, göğüs genişliği, uzuv kalınlığı, bacak boyu]
const AGES := {"child": [0.78, 1.1, 0.84, 0.82, 1.0], "teen": [0.82, 1.07, 0.88, 0.86, 1.0], "young": [0.94, 1.03, 0.97, 0.96, 1.0], "adult": [1.0, 1.0, 1.0, 1.0, 1.0]}
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
	"gi": "Dövüş Gi'si", "yakali_uzun": "Uzun Kollu Yüksek Yaka", "atlet": "Atlet", "tek_kol": "Tek Kollu Üst", "yok": "Üst Yok"}
const PANTS_STYLES := {"ninja": "Ninja Pantolonu", "sort": "Diz Altı Şort", "sivil": "Uzun Pantolon", "sargi": "Sargılı Pantolon", "bol": "Bol Paçalı Pantolon", "kapri": "Kapri", "kisa_sort": "Kısa Şort"}

## Yüz tipi: [çene genişliği, çene ucu, elmacık, burun, kaş çıkıntısı, işaret]
const FACES := {
	"normal": [0.0, 0.0, 0.0, 0.0, 0.0], "keskin": [-0.008, 0.01, -0.004, 0.004, 0.004], "yuvarlak": [0.01, -0.006, 0.008, -0.003, 0.0],
	"köşeli": [0.012, 0.004, 0.0, 0.002, 0.004], "ince": [-0.01, -0.004, -0.006, 0.0, -0.002], "iri burun": [0.004, 0.0, 0.002, 0.009, 0.003],
}
const FACE_MARKS := {"yok": 0, "burun yarası": 1, "yanak çizgisi": 2, "çil": 3, "kırışık": 4}
## Yüz boyası (Shinobi Striker Face Paint 1-35, refs/facepaint): desen maskesi Striker görsellerinden çıkarıldı (assets/facepaint),
## yüze göz arası mesafeye göre önden yansıtılır; renk Striker'daki gibi seçilebilir ("Doğal" = görseldeki renk)
const FACE_PAINTS := {"yok": "Yok", "fp1": "Akimichi Sarmalı (Chōji)", "fp2": "Inuzuka Dişleri (Kiba)", "fp3": "Mor Yanak Çizgileri (Rin)", "fp4": "Burun Yarası (Iruka)", "fp5": "Bıyık İzleri (Naruto)", "fp6": "Alın Damlası", "fp7": "Senju Çizgileri (Tobirama)", "fp8": "Kara Kaş ve Burun", "fp9": "Göz Altı Yarası (Yagura)", "fp10": "Kabuki Boyası (Kankurō)", "fp11": "Göz Çizgileri (Genç Jiraiya)", "fp12": "Ai Kanjisi (Gaara)", "fp13": "Kaguya Noktaları (Kimimaro)", "fp14": "Alın ve Çene Mührü", "fp15": "Sennin Kızılı (Jiraiya)", "fp16": "Yılan Göz Çizgisi (Orochimaru)", "fp17": "Bıyık İzleri (Boruto)", "fp19": "Göz Kalemi", "fp20": "Çift Yanak Çizgisi", "fp21": "Yanak Çizgisi (Kagura)", "fp22": "Yıldız Yara", "fp23": "Kesik Yara", "fp24": "Çapraz Kesik", "fp25": "Pençe İzleri", "fp26": "Dikişli Yara", "fp27": "Bıyık Boyası", "fp28": "Gölge Lekesi", "fp29": "Dikiş ve Damla", "fp30": "Yanak Noktaları (Konohamaru)", "fp31": "Göz Çizgileri (Itachi)", "fp32": "Göz Yarası (Kakashi)", "fp33": "Boynuz İzi (Killer Bee)", "fp34": "Yılan Pulları (Kabuto)", "fp35": "Kaplan Boyası", "x0": "Parlak Dudak İzi", "x1": "Mürekkep Damlası", "x2": "Kar Kristali", "x4": "Kara Tavşan", "x5": "Gülen Ağız", "x6": "Yarım Deste", "x7": "Ninja Dünyası Arması", "x8": "Pati İzleri", "x9": "Ninja Köpekleri", "x10": "İnce Ruj", "x11": "Pudra Rujı", "x12": "Kabuki Göz", "x13": "Gül", "x14": "Hilal Ay", "x17": "Anahtar Deliği", "x18": "Kesik Çizgi", "x19": "Papyon Maske", "x20": "İblis Yüzü", "x21": "Işık Kanjisi", "x22": "Kahraman Maskesi", "x23": "İki Yıldız", "x24": "Üç Yıldız", "x25": "Kirli Leke", "x26": "Ayçiçeği", "x29": "Pastel Allık", "x30": "Kagura Çizgisi", "x31": "Sukea Gölgesi", "x32": "Kırlangıçkuyruğu Kelebek", "x33": "Gözyaşı Damlası", "x34": "Dikişli Yama", "x37": "Ceset Burnu", "x38": "Kontun Yemeği", "x40": "Balkabağı Fener", "x41": "Naruto 20. Yıl", "x42": "Kamuflaj", "x43": "Erik Çiçeği", "x44": "Akçaağaç Yaprağı", "x45": "Shuriken", "x46": "Uçurtma", "x47": "Lanet İşareti", "x55": "Bulutlar", "x56": "Ruj", "x57": "Mavi Ruj", "x58": "Pembe Ruj", "x67": "Şeytani Ruj", "x68": "Sevgililer Çikolatası", "x70": "Lanet Mührü (İkinci Aşama)"}
const FACE_PAINT_NATURAL := {"fp1": Color(0.43, 0.41, 0.44), "fp2": Color(0.44, 0.14, 0.18), "fp3": Color(0.33, 0.25, 0.45), "fp4": Color(0.68, 0.55, 0.56), "fp5": Color(0.50, 0.45, 0.45), "fp6": Color(0.32, 0.29, 0.31), "fp7": Color(0.42, 0.17, 0.20), "fp8": Color(0.31, 0.28, 0.29), "fp9": Color(0.31, 0.35, 0.44), "fp10": Color(0.48, 0.11, 0.16), "fp11": Color(0.45, 0.23, 0.25), "fp12": Color(0.55, 0.44, 0.46), "fp13": Color(0.42, 0.22, 0.25), "fp14": Color(0.47, 0.22, 0.25), "fp15": Color(0.44, 0.20, 0.22), "fp16": Color(0.24, 0.22, 0.26), "fp17": Color(0.48, 0.44, 0.44), "fp19": Color(0.38, 0.49, 0.67), "fp20": Color(0.68, 0.65, 0.24), "fp21": Color(0.51, 0.49, 0.50), "fp22": Color(0.32, 0.24, 0.24), "fp23": Color(0.69, 0.50, 0.39), "fp24": Color(0.73, 0.49, 0.33), "fp25": Color(0.21, 0.19, 0.29), "fp26": Color(0.68, 0.54, 0.55), "fp27": Color(0.72, 0.50, 0.36), "fp28": Color(0.08, 0.09, 0.18), "fp29": Color(0.45, 0.39, 0.39), "fp30": Color(0.45, 0.13, 0.18), "fp31": Color(0.52, 0.50, 0.50), "fp32": Color(0.60, 0.49, 0.49), "fp33": Color(0.29, 0.28, 0.41), "fp34": Color(0.45, 0.41, 0.42), "fp35": Color(0.33, 0.31, 0.31)}
const FACE_PAINT_COLORS := {"Doğal": Color(0, 0, 0, 0), "Kırmızı": Color(0.72, 0.1, 0.12), "Siyah": Color(0.07, 0.07, 0.09), "Mor": Color(0.45, 0.2, 0.62),
	"Mavi": Color(0.18, 0.32, 0.75), "Pembe": Color(0.92, 0.45, 0.62), "Yeşil": Color(0.2, 0.55, 0.28), "Camgöbeği": Color(0.25, 0.75, 0.82), "Beyaz": Color(0.95, 0.95, 0.95), "Haki": Color(0.6, 0.55, 0.38)}
## Klanın kanon boyası (Inuzuka kırmızı dişler, Akimichi sarmal, Kaguya kırmızı noktalar, Karatachi yara)
const CLAN_FACE_PAINT := {"inuzuka": "fp2", "akimichi": "fp1", "kaguya": "fp13", "karatachi": "fp9"}


static func face_paint_color(look_d: Dictionary) -> Color:
	var id = String(look_d.get("face_paint", "yok")) if look_d.get("face_paint") != null else "yok"
	var c = look_d.get("face_paint_col")
	if c is Color and (c as Color).a > 0.0:
		return c
	return FACE_PAINT_NATURAL.get(id, Color(0.7, 0.1, 0.1) if not id.begins_with("x") else Color.WHITE)


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
		m.set_shader_parameter("skin_tint", Color(col.r, col.g, col.b, clampf(k, 0.0, 1.0)))   # gövde, kollar, eller, ayaklar (ten dokulu: pal[0] etkilemiyordu)
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
	mat.set_shader_parameter("leg_fishnet", bool(look.get("leg_fishnet", false)))
	mat.set_shader_parameter("guard_net", bool(look.get("net_pads", false)))
	mat.set_shader_parameter("vest_open", bool(look.get("vest_open", false)))
	var kgd = look.get("kg") if look.get("kg") is Dictionary else {}
	mat.set_shader_parameter("inner_col", kgd["inner"] if kgd.get("inner") is Color else Color(0, 0, 0, 0))   # gi V yakasında iç giysi
	mat.set_shader_parameter("pants_pipe", look.get("pants_pipe") if look.get("pants_pipe") is Color else Color(0, 0, 0, 0))
	mat.set_shader_parameter("vest_style", int(look.get("vest_style", 0)))
	mat.set_shader_parameter("gloves", bool(look.get("gloves", false)))
	mat.set_shader_parameter("arm_wraps", bool(look.get("arm_wraps", false)))
	mat.set_shader_parameter("no_wraps", look.get("no_wraps") == true)
	var os_ = String(look.get("outer_style", "")) if look.get("outer_style") != null else ""
	# yelek dış giysinin altında: önü açık giysilerde (haori, palto, jinbaori) yalnız açıklık kadarı görünür, kapalı pelerinde gizli
	const OPEN_GAP := {"haori": 0.031, "haori_uzun": 0.029, "jinbaori": 0.038, "palto": 0.025, "acik_ceket": 0.045, "sisme_yelek": 0.06, "uzun_ceket": 0.02, "hirka": 0.04, "esofman_ceket": 0.03, "kisa_haori": 0.05, "hinata_ceket": 0.0, "hinata_ceket_acik": 0.05, "kisa_bolero": 0.042, "kuyruklu_ceket": 0.03, "uzun_trench": 0.05, "yirtik_esofman": 0.035, "uzun_robe": 0.03}
	mat.set_shader_parameter("outer_cover", 0 if os_ in ["", "atki", "kisa", "kesa"] else (1 if OPEN_GAP.has(os_) else 2))
	mat.set_shader_parameter("outer_gap", float(OPEN_GAP.get(os_, 0.075)))
	mat.set_shader_parameter("sleeve_roll", bool(look.get("sleeve_roll", false)))
	mat.set_shader_parameter("outer_sleeves", 1 if look.get("outer_style") in ["palto", "haori", "org_pelerin", "acik_ceket", "omuz_kazak", "uzun_ceket", "hirka", "esofman_ceket", "kizil_palto", "hinata_ceket", "algi_ceket", "turuncu_ceket", "kisa_bolero", "uzun_trench", "yirtik_esofman", "seytan_kapuson", "buyuk_kapusonlu"] else 0)
	mat.set_shader_parameter("foot_cover", look.get("foot_style", "sandal") == "tabi")
	var fz = 0.12
	var fy = _grest(skel.find_bone("LeftFoot")).origin.y
	var bv: PackedVector3Array = g["wpos"]
	var mz = -1.0
	for q in bv:
		if q.y < fy - 0.03 and q.z > mz:
			mz = q.z
	if mz > 0.0:
		fz = mz - 0.05
	mat.set_shader_parameter("foot_toe_z", fz)
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
		_shell_cache[key + "|vest"] = _build_shell(g, func(c): return {10: 0.04, 11: 0.064, 12: 0.066, 20: 0.056}.get(c, 0.0), 14)   # sırtta gömlek yarıklardan görünmesin
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
		if int(look.get("vest_style", 0)) in [0, 1, 2, 3, 4, 12]:
			_vest_kit(_shell_cache[key + "|vest"], g)
		if int(look.get("vest_style", 0)) == 2 and _sk_begin(_shell_cache[key]):
			# Kiri önlüğü: kalça önünde, kumaş kabuğuna yaslı, aşağı doğru daralan plaka şerit
			var hy = _bp("Hips").y
			var vc2: Color = Color(look["vest"]).darkened(0.06)
			_sk_panel(0.0, hy + 0.06, 0.24, 0.27, 0.17, 0.014, vc2)
			_sk_end(g)
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
	if ts == "yok":
		return   # çıplak gövde: kol ağzı / etek halkası çizilmez
	var sleeve = (el + 0.05 if ts == "gi" else lerpf(ua, el, 0.5)) if short_sleeve else ha - 0.035
	var roll = bool(look.get("sleeve_roll", false)) and ts in ["uzun", "yakali_uzun"]
	if roll:
		sleeve = lerpf(el, ha, 0.42)   # kıvrık kol: ön kol ortasında kalın katlı manşet
	var cut = {"ninja": knee - 0.17, "sort": knee - 0.05, "kapri": lerpf(knee, ank, 0.45), "kisa_sort": knee + 0.12}.get(ps, ank + 0.04)
	if ps == "kisa_sort" and look.get("pleat_skirt", false):
		cut = hips - 0.15   # pilili etek altındaki iç şort (gölgelendiricideki kesimle aynı)
	var rings = []
	for sx in [-1.0, 1.0]:
		var side = "Left" if sx > 0 else "Right"
		rings.append([0, sleeve * sx, sx, side + ("UpperArm" if short_sleeve else "LowerArm"), 0.03 if roll else 0.016, 0.016 if roll else 0.011, Vector3(-0.012 * sx, 0, 0), mat, neck])
		if not look.get("guards") in ["bacak", "ikisi"]:
			rings.append([1, cut, sx, side + ("UpperLeg" if cut > knee else "LowerLeg"), 0.02 if ps == "ninja" else 0.014, 0.013, Vector3(0, 0.012, 0), mat, neck])
	# üst / yelek etek halkaları kaldırıldı: kalça kemiğine yapışık katı tüplerdi (kumaştan 3 / 5.8 cm dışarı), gövde eğilince
	# kumaşın içine giriyor, belde/karında kalın kap gibi duruyordu. Üstün etek kenarı artık gövde kabuğuna derili ince bant;
	# yelek etek bandı yelek ayrıntısında (_vest_kit) yüzeye derili.

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
			"tabi", "shinobi":
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


## KESİM KALIBI (fotoğraftan ölçülen siluet): kesit vücudu takip etmez; her satırda prof(t) -> Vector4(yarı genişlik, yarı derinlik,
## ön açılım yarı açısı, köşelilik üssü) ile süperelips. Vücut yalnız alt sınır (gap): kumaş vücudun içine girmez ama belde daralmaz,
## göğüste şişmez (düz panel, omuz hattı). Açılım kenarı köşe sırası olarak tam açıdan geçer (ızgara basamağı yok).
## axis 0 (kol) için genişlik = derinlik = yarıçap. Ağırlık/etek dinamiği _skinned_mesh ile (_loft ile aynı).
func _cut_loft(g: Dictionary, axis: int, v0: float, v1: float, rows: int, filt: Callable, prof: Callable, slot: int, skirt_y := -99.0, bins := 48, gap: Variant = 0.012, skip = null) -> ArrayMesh:
	_skin_index(g)
	var buck: Dictionary = g["buck%d" % axis]
	var ua = Vector3.UP if axis == 0 else Vector3.RIGHT
	var ub = Vector3.BACK
	const BB := 36
	var lay := PackedVector3Array()
	var shv := PackedVector3Array()   # kumaş kabuğu (gömlek/üst): vücut ızgarasında göğüs biçimi yok, kabukta var
	var shm = _shell_cache.get(look["gender"])
	if shm is ArrayMesh:
		shv = (shm as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if axis == 1:
		for lm in _layer_meshes:
			lay.append_array((lm as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
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
			centers.append(null); radii.append(null)
			continue
		var npts = pts.size()
		for p in shv:
			if absf(p[axis] - val) <= 0.015 and filt.call(p):
				pts.append(p)
		var c = Vector3.ZERO
		for pi in npts:
			c += pts[pi]
		c /= npts
		c[axis] = val
		var lpts = []
		for p in lay:   # iç katmanlar (hakama/etek/iç cübbe): ayrı ölçülür, onlara karşı daha geniş pay (salınımda taşmasın)
			if absf(p[axis] - val) <= 0.025 and filt.call(p):
				lpts.append(p)
		var rad = PackedFloat32Array(); rad.resize(BB)
		for p in pts:
			var d = p - c
			var a = atan2(d.dot(ub), d.dot(ua))
			var k = int(floor((a + PI) / TAU * BB)) % BB
			rad[k] = maxf(rad[k], Vector2(d.dot(ua), d.dot(ub)).length())
		for p in lpts:
			var d = p - c
			var a = atan2(d.dot(ub), d.dot(ua))
			var k = int(floor((a + PI) / TAU * BB)) % BB
			rad[k] = maxf(rad[k], Vector2(d.dot(ua), d.dot(ub)).length() + 0.035)
		for it in 4:
			for k in BB:
				if rad[k] <= 0.0:
					rad[k] = maxf(rad[(k + 1) % BB], rad[(k + BB - 1) % BB])
		centers.append(c); radii.append(rad)
	for it in rows:
		for r in rows:
			if centers[r] == null:
				var nb = r - 1 if r > 0 and centers[r - 1] != null else (r + 1 if r < rows - 1 and centers[r + 1] != null else -1)
				if nb >= 0:
					var cc: Vector3 = centers[nb]
					cc[axis] = lerpf(v0, v1, float(r) / (rows - 1))
					centers[r] = cc
					radii[r] = (radii[nb] as PackedFloat32Array).duplicate()
	if centers[0] == null:
		return null
	# merkezleri yumuşat: kesim düz panel, vücudun öne/arkaya kayan merkezini birebir izlemesin
	for it in 3:
		var nc = centers.duplicate()
		for r in range(1, rows - 1):
			nc[r] = (centers[r - 1] + (centers[r] as Vector3) * 2.0 + centers[r + 1]) * 0.25
		centers = nc
	var verts = PackedVector3Array()
	var custom = PackedFloat32Array()
	var RR := PackedFloat32Array()
	var LB := PackedFloat32Array()
	var AN := PackedFloat32Array()
	var profs = []
	var open_any = false
	for r in rows:
		var pr0: Vector4 = prof.call(float(r) / (rows - 1))
		profs.append(pr0)
		if pr0.z > 0.0:
			open_any = true
	for r in rows:
		var pr: Vector4 = profs[r]
		var opa = maxf(pr.z, 0.0005) if open_any else 0.0   # bir satır açıksa hepsi önde dikişli (kapalı satırda dikiş birleşik)
		var nexp = maxf(pr.w, 2.0)
		var gp: float = (gap as Callable).call(float(r) / (rows - 1)) if gap is Callable else float(gap)   # katman payı: alttaki giysi (hakama/etek/yaka) kalınlığı
		for k in bins:
			# açık kesitte köşeler açılım kenarından kenarına (önde boşluk); kapalıda tam tur
			var ang = (PI * 0.5 + opa + (TAU - 2.0 * opa) * float(k) / (bins - 1)) if opa > 0.0 else ((float(k) + 0.5) / bins * TAU - PI)
			var ca = absf(cos(ang)); var sa = absf(sin(ang))
			var rc = 1.0 / pow(pow(ca / maxf(pr.x, 0.01), nexp) + pow(sa / maxf(pr.y, 0.01), nexp), 1.0 / nexp)
			var aw = wrapf(ang, -PI, PI)
			var kb = int(floor((aw + PI) / TAU * BB)) % BB
			var rb = (radii[r] as PackedFloat32Array)[kb]
			RR.append(maxf(rc, rb + gp) + _outer_pad)
			LB.append(rb + gp + _outer_pad)
			AN.append(ang)
	# yumuşatma (yalnız dışa): vücut girinti-çıkıntısı kumaşta kırışık çizgi yapmasın; ortalamadan küçük değer yükseltilir
	for it in 3:
		var nr = RR.duplicate()
		for r in rows:
			for k in bins:
				var i = r * bins + k
				var kl = k - 1 if k > 0 else (k if open_any else bins - 1)
				var kr = k + 1 if k < bins - 1 else (k if open_any else 0)
				var s4 = RR[r * bins + kl] + RR[r * bins + kr] + (RR[(r - 1) * bins + k] if r > 0 else RR[i]) + (RR[(r + 1) * bins + k] if r < rows - 1 else RR[i])
				nr[i] = maxf(LB[i], (RR[i] * 2.0 + s4) / 6.0)   # gerçek ortalama, yalnız vücut/katman alt sınırına kırp (balonlaşmaz)
		RR = nr
	for r in rows:
		for k in bins:
			var ang2: float = AN[r * bins + k]
			var p: Vector3 = centers[r] + (ua * cos(ang2) + ub * sin(ang2)) * RR[r * bins + k]
			verts.append(p)
			custom.append_array([p.x, p.y, p.z, float(slot)])
	var idx = PackedInt32Array()
	for r in rows - 1:
		var segs = bins - 1 if open_any else bins
		for k in segs:
			var a = r * bins + k; var b = r * bins + (k + 1) % bins
			var c = (r + 1) * bins + k; var d = (r + 1) * bins + (k + 1) % bins
			if skip != null and (skip as Callable).call((float(r) + 0.5) / (rows - 1), wrapf((AN[a] + AN[b]) * 0.5 if absf(AN[a] - AN[b]) < PI else AN[a], -PI, PI)):
				continue
			if axis == 1:
				idx.append_array([a, c, b, b, c, d])
			else:
				idx.append_array([a, b, c, b, d, c])
	if idx.is_empty():
		return null
	return _skinned_mesh(g, verts, custom, idx, skirt_y, axis == 1)


## Kesim tablosu: fotoğraftan okunan ölçüler; sp = {"w": [[t, S katı], ...], "d": [[t, m], ...], "o": [[t, rad], ...], "n": üs}
## (t: 0 = v0 üst, 1 = v1 alt; aradaki değerler doğrusal). S = omuz yarı genişliği (LeftUpperArm.x).
func _cut_spec(g: Dictionary, v0: float, v1: float, rows: int, sp: Dictionary, slot: int, skirt_y := -99.0, gap: Variant = 0.03, skip = null) -> ArrayMesh:
	var S = absf(_bp("LeftUpperArm").x)
	var neck = _bp("Neck").y
	var ua = absf(_bp("LeftUpperArm").x)
	var torso = func(p: Vector3) -> bool: return absf(p.x) < (ua * 0.95 if p.y > neck - 0.33 else ua * 1.25) and p.y < neck + 0.06   # bel altında eller (dinlenme pozu) ölçüme girmesin
	var pl = func(arr: Array, t: float) -> float:
		if arr.is_empty():
			return 0.0
		if t <= arr[0][0]:
			return float(arr[0][1])
		for i in range(1, arr.size()):
			if t <= arr[i][0]:
				var a = arr[i - 1]; var b = arr[i]
				return lerpf(float(a[1]), float(b[1]), (t - a[0]) / maxf(b[0] - a[0], 0.0001))
		return float(arr[-1][1])
	var W: Array = sp.get("w", [[0.0, 0.85], [1.0, 1.0]])
	var D: Array = sp.get("d", [[0.0, 0.11], [1.0, 0.13]])
	var O: Array = sp.get("o", [])
	var nexp: float = sp.get("n", 2.6)
	if look.get("vest") != null and gap is float:
		gap = float(gap) + 0.04   # taktik yeleğin cepleri/yakası (ayrı kit örgüsü, katman listesinde yok) dış giysiden taşmasın
	return _cut_loft(g, 1, v0, v1, rows, torso, func(t): return Vector4(S * pl.call(W, t), pl.call(D, t), pl.call(O, t), nexp), slot, skirt_y, 56, gap, skip)


## Kesim kolu: omuz dikişinden (S*0.92) bileğe; r = [[t, yarıçap m], ...] (t 0 omuz, 1 kol ucu), uç = bilekten içeri pay
func _cut_sleeve(g: Dictionary, key: String, r: Array, end_off := 0.05, slot := 8, nexp := 2.0) -> void:
	var S = absf(_bp("LeftUpperArm").x)
	var neck = _bp("Neck").y
	var hx = absf(_bp("LeftHand").x)
	var pl = func(t: float) -> float:
		if t <= r[0][0]:
			return float(r[0][1])
		for i in range(1, r.size()):
			if t <= r[i][0]:
				return lerpf(float(r[i - 1][1]), float(r[i][1]), (t - r[i - 1][0]) / maxf(r[i][0] - r[i - 1][0], 0.0001))
		return float(r[-1][1])
	var x1 = hx - end_off
	for sx in [1.0, -1.0]:
		_garment("%s%d" % [key, int(sx)], func(): return _cut_loft(g, 0, (S * 0.92) * sx, x1 * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > S * 0.9 and absf(p.x) < x1 + 0.02, func(t): return Vector4(pl.call(t), pl.call(t) * 0.9, 0.0, nexp), slot, -99.0, 28, 0.012))


## Normaller + ağırlık aktarımı + iç yüz (çift taraflı) → iskelete bağlanacak mesh
func _skinned_mesh(g: Dictionary, verts: PackedVector3Array, custom: PackedFloat32Array, idx: PackedInt32Array, skirt_y: float, hips_full := false) -> ArrayMesh:
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
			# vücuttan uzak bol kumaş (geniş etek/cübbe ucu): bacağa bağlanırsa durunca bacakla içeri çekilip daralıyordu -> kalçaya
			var far = verts[i].distance_to((g["arrays"][Mesh.ARRAY_VERTEX] as PackedVector3Array)[src])
			blend = maxf(blend, clampf((far - 0.04) / 0.08, 0.0, 1.0) * clampf((skirt_y - verts[i].y) / 0.15, 0.0, 1.0))
			if hips_full:   # kesim kalıbı etek/cübbe: belin altı tamamen kalçada (düz asılır, bacak içinde oynar; bacakla yarılmaz)
				blend = maxf(blend, clampf((skirt_y - verts[i].y) / 0.12, 0.0, 1.0))
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
			if hips_full and blend > 0.5:
				# kalıp etek/cübbe: o yandaki uyluğu kısmen izlesin -> duruşta/yürürken öne çıkan bacak kumaşı da açar, içinden çıkmaz
				var leg_bi = _bind_index("LeftUpperLeg" if verts[i].x > 0.0 else "RightUpperLeg")
				var share = (0.8 if verts[i].z > 0.02 else 0.45) * clampf(absf(verts[i].x) / 0.06, 0.0, 1.0) * clampf((skirt_y - verts[i].y) / 0.2, 0.0, 1.0)
				if leg_bi >= 0 and share > 0.0:
					for e in wb:
						e[1] = e[1] * (1.0 - share)
					wb.sort_custom(func(x, y): return x[1] < y[1])
					var lput = false
					for e in wb:
						if e[0] == leg_bi:
							e[1] += share
							lput = true
					if not lput:
						wb[0] = [leg_bi, share + wb[0][1]]
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
	all_c.append_array(custom)   # iç yüz kopyası (astar shader'da normal yönünden ayırt edilir)
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


var _layer_meshes := []   # bu kurulumda eklenen giysi katmanları (kesim kalıbı bunların dışında durur)
func _garment(key: String, build: Callable) -> void:
	var k = "%s|%s|%.3f" % [look["gender"], key, _outer_pad]
	var lsig = 0   # iç katman imzası: kesim kalıbı aynı anahtarla farklı iç katmanların üstüne kurulabilir
	for lm in _layer_meshes:
		lsig += (lm as ArrayMesh).get_instance_id() % 100003
	if not _garment_cache.has(k) or (_garment_cache[k] != null and int(_garment_cache[k].get_meta("lsig", lsig)) != lsig):
		_garment_cache[k] = build.call()
		if _garment_cache[k] != null:
			_garment_cache[k].set_meta("lsig", lsig)
	if _garment_cache[k] != null:
		_layer_meshes.append(_garment_cache[k])
		_dyn_garment(_add_shell(_garment_cache[k], cloth_shell_mat), key)


## Kendi rengi olan giysi parçası: başlık yuvası (10) bu kabuğa özel paletle boyanır; aynı yuvayı kullanan diğer giysilerle
## (eldiven/aksesuar/başlık) renk çakışmaz. build -> ArrayMesh (slot 10 ile loft)
func _garment_tinted(key: String, col: Color, build: Callable) -> void:
	var k = "%s|%s|%.3f" % [look["gender"], key, 0.0]
	if not _garment_cache.has(k):
		_garment_cache[k] = build.call()
	if _garment_cache[k] == null:
		return
	var smat: ShaderMaterial = cloth_shell_mat.duplicate()
	var spl: Array = Array(_palette())
	spl[10] = col
	smat.set_shader_parameter("pal", PackedColorArray(spl))
	_add_shell(_garment_cache[k], smat)


## Etekli dış giysiler: kalçanın altındaki kumaş dilim zincirleriyle sallanır (koşuda arkaya açılır, dönüşte savrulur,
## bacak/diz küreleri kumaşı iter: bacak kumaşın içinden çıkmaz). Zincir kemikleri karakter iskeletine eklenir.
const DYN_GARMENTS := {"pelerin": 0.26, "org_pelerin": 0.24, "panco": 0.3, "yirtik": 0.2, "jinbaori": 0.3, "danzo_ortu": 0.3, "yaprak_etek_alt": 0.4, "pilili_etek": 0.3, "hakama_ust": 0.2, "flamingo_firfir": 0.4, "mino": 0.36, "hakama": 0.32, "etek_1": 0.4, "etek_2": 0.34, "etek_3": 0.3}   # anahtar -> şekil sertliği
static var _gdyn_cache := {}


func _dyn_garment(shell: MeshInstance3D, key: String) -> void:
	if shell == null or not DYN_GARMENTS.has(key) or body_mesh == null or body_mesh.skin == null:
		return
	if key.begins_with("etek_") and look.get("outer_style") != null and not String(look.get("outer_style")) in ["atki", "kisa", "kesa"]:
		return   # dış giysinin altındaki etek sallanmasın: salınınca paltonun içinden taşıyordu (Anko)
	var hb = skel.find_bone("Hips")
	if hb < 0:
		return
	var hips = _bp("Hips")
	var root_y = hips.y - 0.05
	var base_skin: Skin = body_mesh.skin
	var nb = base_skin.get_bind_count()
	var ck = "%s|%s|%.3f|%d|%d" % [look["gender"], key, _outer_pad, nb, shell.mesh.get_instance_id()]
	if not _gdyn_cache.has(ck):
		_gdyn_cache[ck] = _build_dyn_garment(shell.mesh, Vector3(hips.x, 0, hips.z), root_y, nb, float(DYN_GARMENTS[key]))
	var pk: Dictionary = _gdyn_cache[ck]
	if pk.is_empty():
		return
	var flip_i = FLIP.affine_inverse()
	var skin: Skin = base_skin.duplicate()
	var defs = []
	for ch in pk["defs"]:
		var pts_s = PackedVector3Array()
		var b0 = -1
		for q in ch["pts"]:
			var sp = flip_i * (q as Vector3)
			var bi = skel.get_bone_count()
			skel.add_bone("dyn%d" % bi)
			skel.set_bone_rest(bi, Transform3D(Basis.IDENTITY, sp))
			skel.set_bone_pose_position(bi, sp)
			skin.add_bind(bi, Transform3D(Basis.IDENTITY, -sp) * flip_i)
			if b0 < 0:
				b0 = bi
			pts_s.append(sp)
		var d = ch.duplicate()
		d["pts"] = pts_s
		d["b0"] = b0
		defs.append(d)
	shell.mesh = pk["mesh"]
	shell.skin = skin
	var dn = Dangle.make_ext(skel, hb, defs)
	add_child(dn)
	_dangles.append(dn)


static func _build_dyn_garment(mesh: ArrayMesh, center: Vector3, root_y: float, nb: int, stiff: float) -> Dictionary:
	var arr = mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var sc = Dangle.sector_chains([v], center, root_y, {"sectors": 8, "points": 4, "min_len": 0.12, "fade": 0.05,
		"def": {"stiff": stiff, "stiff_tip": stiff * 0.55, "damp": 0.8, "grav": 0.6, "drag": 0.8, "air": 0.22, "follow": 0.6, "col_r": 0.025, "col_from": 1}})
	if sc.is_empty():
		return {}
	var defs: Array = sc["defs"]
	var off = []
	var acc = nb
	for d in defs:
		off.append(acc)
		acc += (d["pts"] as PackedVector3Array).size()
	var asg: Callable = sc["assign"]
	var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var per = bones.size() / maxi(v.size(), 1)
	var nbones = bones.duplicate()
	var nweights = weights.duplicate()
	for i in v.size():
		var res: Array = asg.call(i, 0)
		if res.is_empty():
			continue
		var ent = {}
		var fw = 0.0
		for r in res:
			var n: int = (defs[r[0]]["pts"] as PackedVector3Array).size()
			var s = float(r[1])
			var k = mini(int(floor(s)), n - 2)
			var f = s - k
			var b = int(off[r[0]]) + k
			ent[b] = ent.get(b, 0.0) + float(r[2]) * (1.0 - f)
			ent[b + 1] = ent.get(b + 1, 0.0) + float(r[2]) * f
			fw += float(r[2])
		for k in per:
			var w = weights[i * per + k] * (1.0 - fw)
			if w > 0.0:
				var b = bones[i * per + k]
				ent[b] = ent.get(b, 0.0) + w
		var lst = []
		for b in ent:
			lst.append([b, ent[b]])
		lst.sort_custom(func(x, y): return x[1] > y[1])
		var tot = 0.0
		for k in mini(per, lst.size()):
			tot += lst[k][1]
		for k in per:
			nbones[i * per + k] = lst[k][0] if k < lst.size() else 0
			nweights[i * per + k] = (lst[k][1] / maxf(tot, 0.0001)) if k < lst.size() else 0.0
	arr[Mesh.ARRAY_BONES] = nbones
	arr[Mesh.ARRAY_WEIGHTS] = nweights
	var fmt = mesh.surface_get_format(0)
	var cmask = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	for c in 4:
		cmask |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << (Mesh.ARRAY_FORMAT_CUSTOM_BASE + c * Mesh.ARRAY_FORMAT_CUSTOM_BITS)
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, fmt & cmask)
	return {"mesh": m, "defs": defs}


## Kısa açık ceketin ayrıntıları (ref refs/outfits_ss/full/leaf_striker.jpg): dik yaka (önü açık), bilekte kıvrık manşet,
## sol üst kolda kırmızı yuvarlak arma, belde tokalı beyaz kemer + iç giysinin beyaz plakası — hepsi kabuğa derili
func _acik_ceket_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.7, 0.8, 0.75))
	var jk: Dictionary = look.get("jk") if look.get("jk") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var ank = _bp("LeftFoot").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "acik_ceket", 0.0])
	if jm != null and _sk_begin(jm):
		_sk_ring(1, neck - 0.025, 0.055, 0.01, oc.darkened(0.04), 0.45, TAU - 0.45, 40, 0.004, 0.0, 0.02, 0.12)   # dik yaka, ön açık
		_sk_ring(1, neck - 0.1, 0.005, 0.003, oc.darkened(0.22), -PI, PI, 48, 0.001)   # omuz/göğüs dikiş hattı (yoke)
		if jk.get("pockets", false):   # kot ceket: göğüste kapaklı iki cep + düğme, cepten ete inen dikiş
			for sx in [-1.0, 1.0]:
				_sk_plate(0.085 * sx, chest - 0.045, 0.07, 0.06, 0.004, oc.darkened(0.08), 0.001, true)
				_sk_plate(0.085 * sx, chest - 0.02, 0.074, 0.022, 0.005, oc.darkened(0.2), 0.004, true)
				_sk_plate(0.085 * sx, chest - 0.03, 0.01, 0.01, 0.004, Color(0.75, 0.6, 0.3), 0.009, true)
				_sk_strip(0.085 * sx, chest - 0.085, hips + 0.05, 0.004, 0.002, oc.darkened(0.25), 16)
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		_sk_ring(0, (ha - 0.075) * sx, 0.04, 0.009, oc.darkened(0.06), -PI, PI, 24, 0.006, sx)   # kıvrık manşet
		if jk.get("cuff_stripes") is Color:   # manşet üstünde üç ince şerit (Matador)
			for k in 3:
				_sk_ring(0, (ha - 0.115 - k * 0.014) * sx, 0.006, 0.003, jk["cuff_stripes"], -PI, PI, 24, 0.012, sx)
	# sol üst kol arması: kolun üst yüzü (T pozu +Y) kol inince dışa döner
	var ax = lerpf(absf(_bp("LeftUpperArm").x), absf(_bp("LeftLowerArm").x), 0.3)
	var V: PackedVector3Array = _sk["v"]
	var top = Vector3.ZERO; var by = -9.0
	for q in V:
		if q.x > 0.0 and absf(q.x - ax) < 0.015 and absf(q.z) < 0.03 and q.y > by:
			by = q.y; top = q
	if by > -8.0:
		var pc: Color = jk.get("patch", Color(0.72, 0.12, 0.12))
		for k in 10:   # yassı yuvarlak arma: dilimlerden disk
			var a0 = TAU * k / 10.0
			_sk_box(top + Vector3(cos(a0) * 0.012, 0.004, sin(a0) * 0.012), Vector3(0.012, 0, 0).rotated(Vector3.UP, -a0), Vector3(0, 0.002, 0), Vector3(0, 0, 0.012).rotated(Vector3.UP, -a0), pc)
	if jk.get("shirt") is Color:   # iç gömleğin yakası (yeleğin üstünden görünen ince halka)
		_sk_ring(1, neck - 0.005, 0.02, 0.003, jk["shirt"], -PI, PI, 36, 0.002, 0.0, 0.0, 0.1)
	# belde kemer + toka; kemerde plakalar (Matador); üstünde iç giysinin plakası
	var bc: Color = jk.get("belt", Color(0.94, 0.94, 0.92))
	_sk_ring(1, hips + 0.05, 0.03, 0.006, bc, -PI, PI, 40, 0.002, 0.0, 0.0, 0.2)
	_sk_plate(0.0, hips + 0.05, 0.05, 0.036, 0.008, jk.get("buckle", Color(0.22, 0.22, 0.26)), 0.007, true)
	if jk.get("belt_plates") is Color:
		for k in 6:
			var bx = -0.14 + k * 0.056
			if absf(bx) > 0.03:
				_sk_plate(bx, hips + 0.05, 0.022, 0.022, 0.004, jk["belt_plates"], 0.008, true)
	_sk_plate(0.0, hips + 0.11, 0.055, 0.04, 0.006, jk.get("plate", Color(0.92, 0.92, 0.9)), 0.002, true)
	# kuyruk sokumunda çanta (kumaşa derili, kapaklı)
	var bg: Color = jk.get("bag", Color(0.2, 0.32, 0.22))
	if _sk_plate(0.0, hips + 0.02, 0.11, 0.075, 0.022, bg, 0.002, false):
		_sk_plate(0.0, hips + 0.045, 0.114, 0.024, 0.008, bg.darkened(0.2), 0.024, false)
		if jk.get("bag_star") is Color:
			_sk_plate(-0.03, hips + 0.035, 0.016, 0.016, 0.003, jk["bag_star"], 0.031, false)
	# bot bandı / perçinler (Matador altın bant, Kovboy perçin)
	for sx in [1.0, -1.0]:
		var lx = _bp(("Left" if sx > 0 else "Right") + "LowerLeg").x
		if jk.get("boot_band") is Color:
			_sk_ring(1, ank + 0.13, 0.025, 0.006, jk["boot_band"], -PI, PI, 24, 0.004, sx, 0.0, 0.2)
		if jk.get("boot_studs") is Color:
			for k in 3:
				_sk_plate(lx, ank + 0.06 + k * 0.03, 0.012, 0.012, 0.004, jk["boot_studs"], 0.006, true)
	_sk_end(g)


## Kiri tuniği ayrıntıları (ref refs/outfits_ss/full/mist_striker_1..3.jpg): iki çıtçıtlı kalın atkı yaka, sağ omuzdan sol kalçaya
## çapraz kayış (tokalı), tokalı kemer, sol kalçada kapaklı çanta (damalı varyant), hepsi kabuklara derili
func _kiri_tunik_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.6, 0.55, 0.75))
	var kt: Dictionary = look.get("kt") if look.get("kt") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var tm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kiri_tunik", 0.0])
	if tm == null or not _sk_begin(tm):
		return
	_sk_end(g)
	var ym = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kiri_yaka", 0.0])
	if ym != null and _sk_begin(ym):
		for k in 2:   # yakanın önünde iki çıtçıt
			_sk_plate(0.0, neck - 0.03 + k * 0.05, 0.014, 0.014, 0.005, kt.get("snap", Color(0.85, 0.85, 0.82)), 0.002, true)
		_sk_end(g)
	if not _sk_begin(tm):
		return
	# çapraz kayış: sağ omuzdan (−x) sol kalçaya (+x), tuniğin ön yüzünde; iki toka
	var sc: Color = kt.get("strap", Color(0.45, 0.62, 0.2))
	var a = Vector2(-0.09, chest + 0.1)
	var b = Vector2(0.15, hips + 0.0)
	var pts = []; var outs = []
	for k in 17:
		var q = a.lerp(b, k / 16.0)
		var hit = _sk_hit(q.x, q.y, true, 0.025)
		if not hit.is_empty():
			pts.append(Vector3(q.x, q.y, hit[0].z + 0.003)); outs.append(hit[1])
	for it in 2:
		var sm = pts.duplicate()
		for i in range(1, pts.size() - 1):
			sm[i] = Vector3(pts[i].x, pts[i].y, maxf(pts[i].z, (pts[i - 1].z + pts[i + 1].z) * 0.5))
		pts = sm
	if pts.size() > 1:
		var dir = (Vector3(b.x, b.y, 0) - Vector3(a.x, a.y, 0)).normalized()
		_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.036, 0.006, sc)
		for t in [0.25, 0.4]:   # kayış tokaları
			var q2 = a.lerp(b, t)
			_sk_plate(q2.x, q2.y, 0.04, 0.012, 0.004, kt.get("buckle", sc.lightened(0.15)), 0.01, true)
	# kemer + toka
	var bc: Color = kt.get("belt", sc)
	# tuniğin köşe sıraları ~4 cm aralıklı: halka en yakın sıraya oturur (sıralar arasında kesit boş kalıp kemer yarım çıkıyordu)
	var by2 = hips + 0.02
	var bd2 = 9.0
	for q in (_sk["v"] as PackedVector3Array):
		if absf(q.y - (hips + 0.02)) < bd2:
			bd2 = absf(q.y - (hips + 0.02)); by2 = q.y
	_sk_ring(1, by2, 0.032, 0.006, bc, -PI, PI, 48, 0.003, 0.0, 0.0, 0.32)
	_sk_plate(0.0, by2, 0.05, 0.034, 0.008, kt.get("buckle", bc.lightened(0.15)), 0.009, true)
	# sol kalçada çanta (kapaklı); damalı varyant: kapakta 4x2 dama
	var pc: Color = kt.get("pouch", Color(0.25, 0.2, 0.35))
	if _sk_plate(0.15, hips - 0.03, 0.07, 0.08, 0.035, pc, 0.004, true):
		_sk_plate(0.15, hips + 0.0, 0.074, 0.03, 0.008, pc.darkened(0.15), 0.04, true)
		if kt.get("checker") is Color:
			for cx in 4:
				for cy in 2:
					if (cx + cy) % 2 == 0:
						_sk_plate(0.15 - 0.027 + cx * 0.018, hips + 0.008 - cy * 0.016, 0.017, 0.015, 0.002, kt["checker"], 0.049, true)
		else:
			_sk_plate(0.15, hips - 0.005, 0.012, 0.012, 0.003, kt.get("snap", Color(0.85, 0.85, 0.82)), 0.049, true)
	_sk_end(g)


## Bulut sargı eteği ayrıntıları (ref refs/outfits_ss/full/cloud_striker_1..3.jpg): boyna gevşek sarılı kalın atkı (iki kat + önde sarkan
## uç), eteğin üst kenarı biyesi, belde kuşak (desenli varyant), bilek sargısı süsleri, atkıda yıldız — kabuklara derili
func _bulut_etek_kit(g: Dictionary) -> void:
	var bk: Dictionary = look.get("bk") if look.get("bk") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "bulut_etek", 0.0])
	if em != null and _sk_begin(em):
		var V: PackedVector3Array = _sk["v"]
		var ytop = -9.0
		for q in V:
			ytop = maxf(ytop, q.y)
		var tc: Color = bk.get("trim", Color(0.95, 0.95, 0.93))
		if bk.get("top_trim", true):
			_sk_ring(1, ytop - 0.006, 0.012, 0.004, tc, -PI, PI, 40, 0.002, 0.0, 0.0, 0.3)   # yüksek bel kenarı biyesi
		# kuşak: en yakın köşe sırasına
		var by = hips + 0.06
		var bd = 9.0
		for q in V:
			if absf(q.y - (hips + 0.06)) < bd:
				bd = absf(q.y - (hips + 0.06)); by = q.y
		var bc: Color = bk.get("belt", Color(0.9, 0.9, 0.88))
		_sk_ring(1, by, 0.04, 0.007, bc, -PI, PI, 48, 0.003, 0.0, 0.0, 0.32)
		if bk.get("belt_pattern") is Color:   # desenli kuşak: önde sıra sıra baklava
			for k in 9:
				var bx = -0.16 + k * 0.04
				_sk_plate(bx, by, 0.022, 0.022, 0.003, bk["belt_pattern"] if k % 2 == 0 else bc.darkened(0.3), 0.011, true)
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	# kalın atkı: boyun dibinde iki kat halka + önde göğse sarkan uç
	var sc: Color = bk.get("scarf", Color(0.9, 0.9, 0.88))
	_sk_ring(1, neck - 0.035, 0.05, 0.03, sc, -PI, PI, 40, 0.008, 0.0, 0.0, 0.14)
	_sk_ring(1, neck + 0.008, 0.04, 0.026, sc.darkened(0.06), -PI, PI, 40, 0.006, 0.0, 0.0, 0.1)
	if bk.get("scarf_star") is Color:   # atkının önünde küçük yıldız
		_sk_plate(0.04, neck - 0.04, 0.02, 0.02, 0.003, bk["scarf_star"], 0.04, true)
	# bilek sargısı süsü (Earth: yeşil baklava)
	if bk.get("wrist_mark") is Color:
		var ha = absf(_bp("LeftHand").x)
		var V2: PackedVector3Array = _sk["v"]
		for sx in [1.0, -1.0]:
			var ax = (ha - 0.08) * sx
			var top = Vector3.ZERO; var by2 = -9.0
			for q in V2:
				if absf(q.x - ax) < 0.012 and absf(q.z) < 0.03 and q.y > by2:
					by2 = q.y; top = q
			if by2 > -8.0:
				_sk_box(top + Vector3(0, 0.012, 0), Vector3(0.008, 0, 0.008).rotated(Vector3.UP, 0.785), Vector3(0, 0.003, 0), Vector3(-0.008, 0, 0.008).rotated(Vector3.UP, 0.785), bk["wrist_mark"])
	_sk_end(g)


## Kaya gi ayrıntıları (ref refs/outfits_ss/full/rock_1..3.jpg): boyun-omuz şal yaka, geniş kuşak (+ beyaz şerit varyantı), kuşaktan
## sarkan iki kapaklı çanta (etiketli varyant), sol kolda kol bandı / ok şeritleri — kabuklara derili
func _kaya_gi_kit(g: Dictionary) -> void:
	var rg: Dictionary = look.get("rg") if look.get("rg") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var gm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kaya_gi", 0.0])
	if gm != null and _sk_begin(gm):
		var V: PackedVector3Array = _sk["v"]
		var by = hips + 0.05
		var bd = 9.0
		for q in V:
			if absf(q.y - (hips + 0.05)) < bd:
				bd = absf(q.y - (hips + 0.05)); by = q.y
		var oc: Color = rg.get("obi", Color(0.1, 0.1, 0.12))
		_sk_ring(1, by, 0.065, 0.008, oc, -PI, PI, 48, 0.003, 0.0, 0.0, 0.32)   # geniş kuşak
		if rg.get("obi_band") is Color:
			_sk_ring(1, by + 0.012, 0.022, 0.004, rg["obi_band"], -PI, PI, 48, 0.012, 0.0, 0.0, 0.34)
		var pc: Color = rg.get("pouch", Color(0.35, 0.26, 0.18))
		for sx in [-1.0, 1.0]:   # kuşaktan sarkan iki çanta (önde, ortanın iki yanında)
			var px = 0.045 * sx
			if _sk_plate(px, by - 0.075, 0.05, 0.085, 0.024, pc, 0.008, true):
				_sk_plate(px, by - 0.04, 0.054, 0.024, 0.008, pc.darkened(0.2), 0.03, true)
				_sk_plate(px, by - 0.02, 0.012, 0.03, 0.004, pc.darkened(0.3), 0.012, true)   # askı
				if rg.get("tags", false):   # etiket (beyaz kâğıt + koyu yazı çizgileri)
					_sk_plate(px, by - 0.1, 0.03, 0.045, 0.002, Color(0.95, 0.95, 0.92), 0.034, true)
					for k in 3:
						_sk_plate(px, by - 0.088 - k * 0.011, 0.016, 0.004, 0.001, Color(0.15, 0.15, 0.2), 0.036, true)
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var sc: Color = rg.get("shawl", Color(0.15, 0.12, 0.1))   # şal yaka: boynu saran kalın kat + omuzlara yayılan alt kat
	_sk_ring(1, neck - 0.06, 0.05, 0.03, sc.darkened(0.05), -PI, PI, 44, 0.012, 0.0, 0.0, 0.17)
	_sk_ring(1, neck - 0.01, 0.06, 0.026, sc, -PI, PI, 40, 0.008, 0.0, 0.0, 0.11)
	# sol üst kol: kol bandı (iki beyaz şerit) + ok şeritleri
	var ax0 = absf(_bp("LeftUpperArm").x)
	var ax1 = absf(_bp("LeftLowerArm").x)
	if rg.get("armband") is Color:
		for k in 2:
			_sk_ring(0, lerpf(ax0, ax1, 0.55 + k * 0.1), 0.012, 0.003, rg["armband"], -PI, PI, 24, 0.004, 1.0)
	if rg.get("chevron") is Color:
		var V2: PackedVector3Array = _sk["v"]
		for k in 2:
			var ax = lerpf(ax0, ax1, 0.2 + k * 0.12)
			var top = Vector3.ZERO; var by2 = -9.0
			for q in V2:
				if q.x > 0.0 and absf(q.x - ax) < 0.012 and absf(q.z) < 0.03 and q.y > by2:
					by2 = q.y; top = q
			if by2 > -8.0:
				for sz in [-1.0, 1.0]:   # V: kola çapraz iki kol
					_sk_box(top + Vector3(-0.008, 0.004, 0.012 * sz), Vector3(0.012, 0, -0.008 * sz).normalized() * 0.016, Vector3(0, 0.002, 0), Vector3(0.008 * sz, 0, 0.012).normalized() * 0.004, rg["chevron"])
	_sk_end(g)


## Suna tuniği ayrıntıları (ref refs/outfits_ss/full/sand_striker_1..3.jpg): kalın atkı (Tribal: sarı üçgen kenarlı), sol omuzdan sağ kalçaya
## kılıflık kayışı + omuzda fişeklik bölmeleri, geniş kemer (şeritli / baklavalı varyant) ve toka — kabuklara derili
func _suna_tunik_kit(g: Dictionary) -> void:
	var st: Dictionary = look.get("st") if look.get("st") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var tm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "suna_tunik", 0.0])
	if tm != null and _sk_begin(tm):
		var sc: Color = st.get("strap", Color(0.45, 0.42, 0.4))
		var a = Vector2(0.1, chest + 0.1)    # sol omuz (+x)
		var b = Vector2(-0.15, hips + 0.02)  # sağ kalça
		var pts = []; var outs = []
		for k in 17:
			var q = a.lerp(b, k / 16.0)
			var hit = _sk_hit(q.x, q.y, true, 0.025)
			if not hit.is_empty():
				pts.append(Vector3(q.x, q.y, hit[0].z + 0.003)); outs.append(hit[1])
		for it in 2:
			var sm = pts.duplicate()
			for i in range(1, pts.size() - 1):
				sm[i] = Vector3(pts[i].x, pts[i].y, maxf(pts[i].z, (pts[i - 1].z + pts[i + 1].z) * 0.5))
			pts = sm
		if pts.size() > 1:
			var dir = (Vector3(b.x, b.y, 0) - Vector3(a.x, a.y, 0)).normalized()
			_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.042, 0.007, sc)
			for k in 3:   # omuz tarafında fişeklik bölmeleri (kayışa dik kısa çubuklar)
				var q2 = a.lerp(b, 0.1 + k * 0.06)
				_sk_plate(q2.x, q2.y, 0.05, 0.01, 0.005, st.get("loops", sc.darkened(0.25)), 0.012, true)
			if st.get("strap_dots") is Color:   # kayışta noktalar (Balloons)
				for k in 8:
					var q3 = a.lerp(b, 0.3 + k * 0.08)
					_sk_plate(q3.x, q3.y, 0.012, 0.012, 0.003, st["strap_dots"], 0.012, true)
		var V: PackedVector3Array = _sk["v"]
		var by = hips + 0.06
		var bd = 9.0
		for q in V:
			if absf(q.y - (hips + 0.06)) < bd:
				bd = absf(q.y - (hips + 0.06)); by = q.y
		var bc: Color = st.get("belt", Color(0.5, 0.48, 0.46))
		_sk_ring(1, by, 0.05, 0.008, bc, -PI, PI, 48, 0.003, 0.0, 0.0, 0.32)
		if st.get("belt_stripe") is Color:
			_sk_ring(1, by, 0.014, 0.004, st["belt_stripe"], -PI, PI, 48, 0.011, 0.0, 0.0, 0.34)
		if st.get("belt_diamond") is Color:
			for k in 11:
				var bx = -0.2 + k * 0.04
				if absf(bx) > 0.03:
					_sk_plate(bx, by, 0.018, 0.026, 0.003, st["belt_diamond"], 0.012, true)
		_sk_plate(0.02, by, 0.03, 0.05, 0.006, st.get("buckle", bc.darkened(0.2)), 0.011, true)   # toka
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var sf: Color = st.get("scarf", Color(0.92, 0.92, 0.9))
	_sk_ring(1, neck - 0.04, 0.055, 0.032, sf, -PI, PI, 40, 0.01, 0.0, 0.0, 0.15)
	_sk_ring(1, neck + 0.005, 0.045, 0.026, sf.darkened(0.05), -PI, PI, 40, 0.006, 0.0, 0.0, 0.1)
	if st.get("scarf_trim") is Color:   # Tribal: atkının üst kenarında sarı üçgenler
		for k in 12:
			var an = TAU * k / 12.0
			var p = Vector3(sin(an) * 0.075, neck + 0.03, cos(an) * 0.075)
			_sk_box(p, Vector3(cos(an), 0, -sin(an)) * 0.01, Vector3(0, 0.012, 0), Vector3(sin(an), 0, cos(an)) * 0.003, st["scarf_trim"])
	_sk_end(g)


## Şişme yelek ayrıntıları (ref refs/outfits_ss/full/beach_1..3, sky_blue.jpg): dik yaka, dolgu dikişleri, Maritime: önde balıklı iki cep +
## sırtta çapa; Sky Blue: sırta düşen kapüşon — kabuğa derili. Şortun önünde bağcık (iki ip + düğüm).
func _sisme_yelek_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.95, 0.55, 0.2))
	var by: Dictionary = look.get("by") if look.get("by") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var vm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "sisme_yelek", 0.0])
	if vm != null and _sk_begin(vm):
		_sk_ring(1, neck - 0.02, 0.06, 0.016, by.get("collar", oc), 0.55, TAU - 0.55, 40, 0.006, 0.0, 0.02, 0.13)   # dik yaka (önü açık)
		if by.get("pockets") is Color:
			for sx in [-1.0, 1.0]:
				if _sk_plate(0.12 * sx, hips + 0.06, 0.08, 0.06, 0.02, by["pockets"], 0.004, true):
					_sk_plate(0.12 * sx, hips + 0.06, 0.03, 0.014, 0.003, Color(0.95, 0.95, 0.95), 0.025, true)   # balık
		if by.get("anchor") is Color:   # sırtta çapa: dikey gövde + üst halka + alt kavis
			_sk_plate(0.0, chest - 0.02, 0.012, 0.09, 0.004, by["anchor"], 0.004, false)
			_sk_plate(0.0, chest + 0.03, 0.04, 0.01, 0.004, by["anchor"], 0.004, false)
			_sk_plate(0.0, chest - 0.065, 0.07, 0.012, 0.004, by["anchor"], 0.004, false)
		if by.get("hood") is Color:   # sırta düşmüş kapüşon: ensede kalın kavis
			_sk_plate(0.0, neck - 0.04, 0.17, 0.12, 0.05, by["hood"], 0.004, false)
			_sk_plate(0.0, neck - 0.1, 0.12, 0.03, 0.02, by["hood"].darkened(0.12), 0.05, false)
		_sk_end(g)
	if by.get("drawstring") is Color and _sk_begin(_shell_cache.get(look["gender"])):
		var sc: Color = by["drawstring"]
		_sk_plate(0.0, hips + 0.04, 0.03, 0.01, 0.004, sc, 0.004, true)   # düğüm
		for sx in [-1.0, 1.0]:
			_sk_plate(0.012 * sx, hips - 0.0, 0.005, 0.07, 0.003, sc, 0.004, true)   # sarkan uçlar
		_sk_end(g)


## Flamingo elbisesi ayrıntıları (ref refs/outfits_ss/full/flamingo.jpg): omzu açık çizgili bant (kolların üstünden geçen iki renkli şerit)
func _flamingo_kit(g: Dictionary) -> void:
	var fe: Dictionary = look.get("fe") if look.get("fe") is Dictionary else {}
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var sh = _bp("UpperChest").y + 0.085
	var a: Color = fe.get("band_a", Color(0.85, 0.3, 0.4))
	var b: Color = fe.get("band_b", Color(0.97, 0.9, 0.92))
	for k in 4:   # göğüs çevresi (yalnız gövde: T pozunda omuz hizasındaki kollar halkaya girip kol boyunca şerit oluyordu)
		_sk_ring(1, sh - k * 0.014, 0.012, 0.006, a if k % 2 == 0 else b, -PI, PI, 56, 0.006, 0.0, 0.0, 0.17)
	_sk_end(g)


## Kapüşonlu ayrıntıları (ref refs/outfits_ss/full/youth_1..3, cat_breeder_m.jpg): ensede düşük kapüşon, önde iki bağcık + uç düğümleri,
## kanguru cep yarıkları (biyeli varyant), ribanalı etek bandı, sağ bilekte bileklik, sol omuzda yuvarlak arma — kabuklara derili
func _kapusonlu_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.12, 0.12, 0.14))
	var yh: Dictionary = look.get("yh") if look.get("yh") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var hm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kapusonlu", 0.0])
	if hm != null and _sk_begin(hm):
		var hc: Color = yh.get("hood", oc)
		_sk_ring(1, neck - 0.012, 0.055, 0.022, hc, -PI, PI, 40, 0.012, 0.0, 0.0, 0.14)   # kapüşonun boyun çevresi (önde boyun kapalı)
		_sk_plate(0.0, neck - 0.05, 0.16, 0.11, 0.045, hc, 0.006, false)                              # sırta düşmüş kapüşon
		_sk_plate(0.0, neck - 0.1, 0.1, 0.025, 0.02, hc.darkened(0.15), 0.045, false)
		var dc: Color = yh.get("cord", Color(0.85, 0.85, 0.85))
		for sx in [-1.0, 1.0]:   # bağcıklar
			_sk_plate(0.03 * sx, neck - 0.075, 0.005, 0.09, 0.003, dc, 0.004, true)
			_sk_plate(0.03 * sx, neck - 0.125, 0.012, 0.012, 0.004, dc.darkened(0.2), 0.005, true)
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_ring(1, ybot + 0.022, 0.04, 0.006, yh.get("rib", oc.darkened(0.12)), -PI, PI, 44, 0.002, 0.0, 0.0, 0.3)   # ribana etek bandı
		if yh.get("pocket_trim") is Color:   # kanguru cep yarıkları (iki eğik biye)
			for sx in [-1.0, 1.0]:
				_sk_plate(0.085 * sx, hips + 0.1, 0.008, 0.08, 0.003, yh["pocket_trim"], 0.003, true)
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	if yh.get("wristband") is Color:   # sağ bilekte bileklik
		_sk_ring(0, -(ha - 0.09), 0.05, 0.008, yh["wristband"], -PI, PI, 24, 0.004, -1.0)
	if yh.get("logo") is Color:   # sol omuzda yuvarlak arma
		var ax = lerpf(absf(_bp("LeftUpperArm").x), absf(_bp("LeftLowerArm").x), 0.15)
		var V2: PackedVector3Array = _sk["v"]
		var top = Vector3.ZERO; var by = -9.0
		for q in V2:
			if q.x > 0.0 and absf(q.x - ax) < 0.015 and absf(q.z) < 0.03 and q.y > by:
				by = q.y; top = q
		if by > -8.0:
			for k in 10:
				var a0 = TAU * k / 10.0
				_sk_box(top + Vector3(cos(a0) * 0.012, 0.012, sin(a0) * 0.012), Vector3(0.012, 0, 0).rotated(Vector3.UP, -a0), Vector3(0, 0.002, 0), Vector3(0, 0, 0.012).rotated(Vector3.UP, -a0), yh["logo"])
	_sk_end(g)


## Omzu açık kazak ayrıntıları (ref refs/outfits_ss/full/sweet_1..3.jpg): üst kenarda ribana bant (omuzlardan geçer), etek ribanası
func _omuz_kazak_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.95, 0.93, 0.9))
	var sw: Dictionary = look.get("sw") if look.get("sw") is Dictionary else {}
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "omuz_kazak", 0.0])
	if km == null or not _sk_begin(km):
		return
	var V: PackedVector3Array = _sk["v"]
	var ytop = -9.0; var ybot = 9.0
	for q in V:
		ytop = maxf(ytop, q.y); ybot = minf(ybot, q.y)
	var rc: Color = sw.get("rib", oc.darkened(0.06))
	_sk_ring(1, ytop - 0.012, 0.028, 0.006, rc, -PI, PI, 56, 0.002, 0.0, 0.0, 0.26)
	_sk_ring(1, ybot + 0.016, 0.03, 0.006, rc, -PI, PI, 48, 0.002, 0.0, 0.0, 0.26)
	_sk_end(g)


## Uzun ceket ayrıntıları (ref refs/outfits_ss/full/swanky_*.jpg): dik yaka, boyundan bele fermuar, bel bandı (Springtime)
func _uzun_ceket_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.1, 0.1, 0.12))
	var uc: Dictionary = look.get("uc") if look.get("uc") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var cm2 = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "uzun_ceket", 0.0])
	if cm2 == null or not _sk_begin(cm2):
		return
	_sk_ring(1, neck + 0.0, 0.07, 0.012, uc.get("collar", oc), -PI, PI, 40, 0.004, 0.0, 0.0, 0.12)   # dik yaka
	_sk_strip(0.0, neck - 0.03, hips + 0.02, 0.008, 0.004, uc.get("zip", Color(0.75, 0.72, 0.6)), 30)   # fermuar
	if uc.get("waist") is Color:
		var V: PackedVector3Array = _sk["v"]
		var by = hips + 0.06
		var bd = 9.0
		for q in V:
			if absf(q.y - (hips + 0.06)) < bd:
				bd = absf(q.y - (hips + 0.06)); by = q.y
		_sk_ring(1, by, 0.04, 0.005, uc["waist"], -PI, PI, 48, 0.002, 0.0, 0.0, 0.3)
	_sk_end(g)


## Hırka ayrıntıları (ref refs/outfits_ss/full/wonder_1.jpg, wonder_4.jpg): önde boydan boya geniş ribana pervaz (yatay örgü
## çizgili), etekte ribana bant, bilekte kalın ribana manşet; Star varyantında ribana yok (düz kenar)
func _hirka_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.9, 0.9, 0.92))
	var hk: Dictionary = look.get("hk") if look.get("hk") is Dictionary else {}
	if not hk.get("rib", true):
		return
	var rc: Color = hk.get("rib_col", oc.darkened(0.1))
	var lc: Color = rc.darkened(0.18)
	var neck = _bp("Neck").y
	var hm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "hirka", 0.0])
	if hm != null and _sk_begin(hm):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		# ön kenar: göğüs altında önde açıklığa en yakın köşe
		_sk_edge_band(0.04, 0.007, rc)   # ribana pervaz: açılım kenarını izler
		_sk_ring(1, ybot + 0.018, 0.034, 0.007, rc, 0.68, TAU - 0.68, 56, 0.003, 0.0, 0.0, 0.3)
		for k in 3:
			_sk_ring(1, ybot + 0.008 + k * 0.011, 0.002, 0.002, lc, 0.68, TAU - 0.68, 56, 0.0105, 0.0, 0.0, 0.3)
		_sk_end(g)
	var hx = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "hirka_kol%d" % int(sx), 0.0])
		if km == null or not _sk_begin(km):
			continue
		_sk_ring(0, (hx - 0.07) * sx, 0.05, 0.008, rc, -PI, PI, 28, 0.003, sx)
		for k in 5:
			_sk_ring(0, (hx - 0.09 + k * 0.01) * sx, 0.002, 0.002, lc, -PI, PI, 28, 0.011, sx)
		_sk_end(g)


## Hemşire önlüğü ayrıntıları (ref refs/outfits_ss/full/adorable_*.jpg): dik yaka (önde ince yarık), çift sıra 2x3 düğme,
## yanlardan arkaya dolanan kemer + arkada fiyonk, bilekte iki renkli manşet (Springtime: kalpli)
func _onluk_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.95, 0.95, 0.96))
	var nd: Dictionary = look.get("nd") if look.get("nd") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var om = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "onluk", 0.0])
	if om != null and _sk_begin(om):
		_sk_ring(1, neck + 0.005, 0.065, 0.01, oc.darkened(0.03), 0.12, TAU - 0.12, 40, 0.004, 0.0, 0.0, 0.12)   # dik yaka, önde yarık
		var bc: Color = nd.get("btn", Color(0.72, 0.73, 0.76))
		for r in 3:
			for sx in [-1.0, 1.0]:
				var h = _sk_hit(0.038 * sx, chest - 0.06 - r * 0.075, true, 0.02)
				if h.is_empty():
					continue
				var c0: Vector3 = h[0] + (h[1] as Vector3) * 0.004
				var n: Vector3 = h[1]
				var u = n.cross(Vector3.UP).normalized()
				var v = u.cross(n).normalized()
				for k in 8:   # yuvarlak düğme: dilimlerden disk + koyu kenar
					var a0 = TAU * k / 8.0
					var d = (u * cos(a0) + v * sin(a0))
					_sk_box(c0 + d * 0.006, u * 0.0045, v * 0.0045, n * 0.002, bc if k % 2 == 0 else bc.darkened(0.08))
					_sk_box(c0 + d * 0.0095, (d.cross(n)) * 0.003, d * 0.0018, n * 0.0025, bc.darkened(0.35))
		# kemer: önde panelin kenarından yanlara ve arkaya dolanır
		var V: PackedVector3Array = _sk["v"]
		var wy = hips + 0.1
		var bd = 9.0
		var by = wy
		for q in V:
			if absf(q.y - wy) < bd:
				bd = absf(q.y - wy); by = q.y
		var belt: Color = nd.get("belt", Color(0.75, 0.12, 0.14))
		_sk_ring(1, by, 0.03, 0.006, belt, 0.55, TAU - 0.55, 48, 0.003, 0.0, 0.0, 0.3)
		if nd.get("belt_edge") is Color:
			for e in [-1.0, 1.0]:
				_sk_ring(1, by + e * 0.015, 0.005, 0.004, nd["belt_edge"], 0.55, TAU - 0.55, 48, 0.0075, 0.0, 0.0, 0.3)
		var hb = _sk_hit(0.0, by, false, 0.03)
		if not hb.is_empty():   # arkada fiyonk: iki kanat + düğüm + iki sarkan uç
			var p0: Vector3 = hb[0] + Vector3(0, 0, -0.012)
			for sx in [-1.0, 1.0]:
				_sk_box(p0 + Vector3(0.03 * sx, 0.006, -0.004), Vector3(0.026, 0.012 * sx, 0), Vector3(-0.006 * sx, 0.02, 0), Vector3(0, 0, -0.006), belt)
				_sk_box(p0 + Vector3(0.012 * sx, -0.05, 0.0), Vector3(0.01, 0, 0), Vector3(0.008 * sx, 0.045, 0), Vector3(0, 0, -0.004), belt.darkened(0.06))
			_sk_box(p0 + Vector3(0, 0, -0.006), Vector3(0.01, 0, 0), Vector3(0, 0.013, 0), Vector3(0, 0, -0.009), belt.darkened(0.12))
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	var cw: Color = nd.get("cuff", Color(0.96, 0.96, 0.97))
	var cl: Color = nd.get("cuff_line", Color(0.75, 0.12, 0.14))
	for sx in [1.0, -1.0]:
		_sk_ring(0, (ha - 0.07) * sx, 0.05, 0.011, cw, -PI, PI, 28, 0.006, sx)   # geniş manşet
		_sk_ring(0, (ha - 0.094) * sx, 0.007, 0.004, cl, -PI, PI, 28, 0.016, sx)   # manşetin dirsek kenarında renk şeridi
		if nd.get("hearts", false):
			for k in 8:
				var a0 = TAU * k / 8.0
				_sk_ring(0, (ha - 0.066) * sx, 0.012, 0.003, cl, a0 - 0.18, a0 + 0.18, 6, 0.017, sx)
	_sk_end(g)


## Antrenman kıyafeti ayrıntıları (ref refs/outfits_ss/full/new_year_greeting.jpg, wtny.jpg):
## gi'nin V yakasında renkli iç yaka, omuzları saran ve sırtta çaprazlanan sarı tasuki, hakama bel bağları / etek fiyonku
func _keiko_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var kg: Dictionary = look.get("kg") if look.get("kg") is Dictionary else {}
	if _sk_begin(_shell_cache.get(look["gender"])):
		var tc: Color = kg.get("tasuki", Color(0.95, 0.75, 0.15))
		var V: PackedVector3Array = _sk["v"]
		var N: PackedVector3Array = _sk["n"]
		var cy = chest - 0.02
		for sx in [-1.0, 1.0]:
			# omuz halkası: x = ±0.12 kesitinde kabuğun dış konturu (önde koltuk altından omuz üstüne, sırtta aşağı)
			var x0 = 0.12 * sx
			var bins := {}
			for i in V.size():
				var q = V[i]
				if absf(q.x - x0) < 0.012 and q.y > chest - 0.2:
					var a = atan2(q.y - cy, q.z)   # 0 ön, PI/2 üst, PI arka
					var k = int(floor(a / 0.1))
					var r = Vector2(q.z, q.y - cy).length()
					if not bins.has(k) or r > bins[k][0]:
						bins[k] = [r, i]
			var ks = bins.keys()
			ks.sort()
			var pts = []; var outs = []
			for k in ks:
				var a = k * 0.1
				if a < -0.9 or a > PI + 0.9:
					continue
				var i = bins[k][1]
				pts.append(Vector3(x0, V[i].y, V[i].z) + N[i] * 0.004); outs.append(N[i])
			if pts.size() > 2:
				_sk_band(pts, outs, Vector3.RIGHT, 0.026, 0.006, tc)
			# sırtta çapraz: omuz arkasından karşı bel yanına
			var a2 = Vector2(0.12 * sx, chest - 0.08)
			var b2 = Vector2(-0.13 * sx, hips + 0.16)
			var p2 = []; var o2 = []
			for k in 15:
				var qq = a2.lerp(b2, k / 14.0)
				var hit = _sk_hit(qq.x, qq.y, false, 0.025)
				if not hit.is_empty():
					p2.append(Vector3(qq.x, qq.y, hit[0].z - 0.004 - 0.002 * sx)); o2.append(hit[1])
			if p2.size() > 1:
				var dir = (Vector3(b2.x, b2.y, 0) - Vector3(a2.x, a2.y, 0)).normalized()
				_sk_band(p2, o2, Vector3.BACK.cross(dir).normalized(), 0.026, 0.006, tc)
		_sk_end(g)
	var hm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "hakama_ust", 0.0])
	if look.get("hakama_cut") == "genis" and hm != null and _sk_begin(hm):
		var pc: Color = look.get("pants", Color(0.15, 0.25, 0.7))
		var V2: PackedVector3Array = _sk["v"]
		var ytop = -9.0
		for q in V2:
			ytop = maxf(ytop, q.y)
		_sk_ring(1, ytop - 0.03, 0.05, 0.008, pc.darkened(0.3), -PI, PI, 48, 0.003, 0.0, 0.0, 0.3)   # bel bağı (himo) sargısı
		for sx in [-1.0, 1.0]:   # önde çapraz bağlar
			var p3 = []; var o3 = []
			var a3 = Vector2(-0.12 * sx, ytop - 0.012)
			var b3 = Vector2(0.06 * sx, ytop - 0.055)
			for k in 9:
				var qq = a3.lerp(b3, k / 8.0)
				var hit = _sk_hit(qq.x, qq.y, true, 0.03)
				if not hit.is_empty():
					p3.append(Vector3(qq.x, qq.y, hit[0].z + 0.01)); o3.append(hit[1])
			if p3.size() > 1:
				var dir = (Vector3(b3.x, b3.y, 0) - Vector3(a3.x, a3.y, 0)).normalized()
				_sk_band(p3, o3, Vector3.BACK.cross(dir).normalized(), 0.02, 0.006, pc.darkened(0.45))
		_sk_plate(0.0, ytop - 0.034, 0.05, 0.03, 0.006, pc.darkened(0.25), 0.016, true)   # düğüm
		_sk_plate(0.0, ytop - 0.034, 0.03, 0.016, 0.004, pc.darkened(0.05), 0.024, true)
		_sk_plate(0.0, ytop - 0.03, 0.14, 0.07, 0.008, pc.darkened(0.08), 0.008, false)   # sırtta koshi-ita
		_sk_end(g)
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "pilili_etek", 0.0])
	if look.get("pleat_skirt", false) and em != null and _sk_begin(em):
		var pc2: Color = look.get("pants", Color(0.7, 0.1, 0.12))
		var V3: PackedVector3Array = _sk["v"]
		var yt = -9.0
		for q in V3:
			yt = maxf(yt, q.y)
		_sk_ring(1, yt - 0.02, 0.04, 0.006, pc2.darkened(0.1), -PI, PI, 48, 0.003, 0.0, 0.0, 0.3)   # bel bandı
		var hit = _sk_hit(0.0, yt - 0.03, true, 0.03)
		if not hit.is_empty():   # önde büyük fiyonk: iki kanat, düğüm, iki uzun sarkan uç
			var p0: Vector3 = hit[0] + Vector3(0, 0, 0.012)
			for sx in [-1.0, 1.0]:
				_sk_box(p0 + Vector3(0.04 * sx, 0.008, 0.0), Vector3(0.036, 0.016 * sx, 0), Vector3(-0.008 * sx, 0.028, 0), Vector3(0, 0, 0.008), pc2.darkened(0.05))
				_sk_box(p0 + Vector3(0.018 * sx, -0.075, 0.004), Vector3(0.014, 0, 0), Vector3(0.012 * sx, 0.07, 0), Vector3(0, 0, 0.005), pc2.darkened(0.15))
			_sk_box(p0 + Vector3(0, 0, 0.006), Vector3(0.013, 0, 0), Vector3(0, 0.018, 0), Vector3(0, 0, 0.011), pc2.darkened(0.2))
		_sk_end(g)


## Eşofman ceketi ayrıntıları (ref refs/outfits_ss/boruto_outfit.png): dik yaka (dışı ceket rengi, ağzında renkli kenar),
## açık fermuarın iki gümüş dişli kenarı, belde ribana bant, bilekte ribana manşet
func _esofman_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.1, 0.1, 0.12))
	var ac: Color = look.get("outer_accent", Color(0.85, 0.3, 0.42)) if look.get("outer_accent") is Color else Color(0.85, 0.3, 0.42)
	var neck = _bp("Neck").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "esofman_ceket", 0.0])
	if jm != null and _sk_begin(jm):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_ring(1, neck + 0.0, 0.06, 0.009, oc, 0.3, TAU - 0.3, 40, 0.004, 0.0, 0.0, 0.12)   # dik yaka
		_sk_ring(1, neck + 0.032, 0.012, 0.011, ac, 0.3, TAU - 0.3, 40, 0.005, 0.0, 0.0, 0.12)   # yaka ağzı renkli
		_sk_ring(1, ybot + 0.022, 0.04, 0.007, oc.darkened(0.15), 0.3, TAU - 0.3, 48, 0.003, 0.0, 0.0, 0.3)   # bel ribanası
		_sk_edge_band(0.009, 0.004, Color(0.72, 0.73, 0.76), neck - 0.01, ybot + 0.03)   # fermuar dişleri: açılım kenarı
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		_sk_ring(0, (ha - 0.065) * sx, 0.04, 0.009, oc.darkened(0.15), -PI, PI, 24, 0.006, sx)
	_sk_end(g)


## Kısa geniş kollu ceket ayrıntıları (ref refs/outfits_ss/choji_outfit.png): önde boydan boya yaka bandı, kol ağzında kat
func _kisa_haori_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.15, 0.42, 0.2))
	var neck = _bp("Neck").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kisa_haori", 0.0])
	if jm != null and _sk_begin(jm):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_edge_band(0.034, 0.006, oc.darkened(0.08))   # yaka bandı (eri): açılım kenarı
		_sk_end(g)
	var el = absf(_bp("LeftLowerArm").x)
	for sx in [1.0, -1.0]:
		var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "haori_kol%d" % int(sx), 0.0])
		if km != null and _sk_begin(km):
			_sk_ring(0, (el + 0.1) * sx, 0.02, 0.005, oc.darkened(0.1), -PI, PI, 24, 0.002, sx)
			_sk_end(g)


## Kemer + gümüş plaka (ref choji_outfit.png): gövde kabuğunda belde renkli kemer, önde yuvarlatılmış gümüş tokalı plaka
func _waist_belt_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var bc: Color = look["waist_belt"]
	_sk_ring(1, hips + 0.05, 0.04, 0.008, bc, -PI, PI, 48, 0.004, 0.0, 0.0, 0.3)
	_sk_plate(0.0, hips + 0.05, 0.1, 0.034, 0.006, Color(0.78, 0.8, 0.84), 0.012, true)
	_sk_plate(0.0, hips + 0.05, 0.082, 0.02, 0.004, Color(0.88, 0.9, 0.93), 0.018, true)
	_sk_end(g)


## Kızıl kruvaze palto ayrıntıları (ref refs/outfits_ss/gaara_outfit.png): dik yaka, çift sıra 2x4 siyah düğme + yakada çapraz
## iki düğme, kruvaze kapak çizgisi, belde iki kahve kemer (gümüş toka), bilekte siyah şerit
func _kizil_palto_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.55, 0.1, 0.16))
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var pm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kizil_palto", 0.0])
	if pm != null and _sk_begin(pm):
		_sk_ring(1, neck + 0.005, 0.06, 0.009, oc.darkened(0.05), -PI, PI, 40, 0.004, 0.0, 0.0, 0.12)   # dik yaka
		var btn := Color(0.06, 0.06, 0.07)
		var pts = [Vector2(-0.065, neck - 0.05), Vector2(-0.03, neck - 0.08)]
		for r in 4:
			for xx in [-0.035, 0.055]:
				pts.append(Vector2(xx, chest - 0.02 - r * 0.07))
		for q in pts:
			var h = _sk_hit(q.x, q.y, true, 0.02)
			if h.is_empty():
				continue
			var n: Vector3 = h[1]
			var u = n.cross(Vector3.UP).normalized()
			var v = u.cross(n).normalized()
			var c0: Vector3 = h[0] + n * 0.003
			for k in 6:
				var a0 = TAU * k / 6.0
				var d = u * cos(a0) + v * sin(a0)
				_sk_box(c0 + d * 0.005, u * 0.004, v * 0.004, n * 0.003, btn)
		_sk_strip(-0.075, neck - 0.04, hips - 0.02, 0.004, 0.003, oc.darkened(0.35), 24)   # kruvaze kapak kenarı
		var V: PackedVector3Array = _sk["v"]
		for b in [[hips + 0.08, 0.04], [hips - 0.01, -0.02]]:
			var by = b[0]
			var bd = 9.0
			for q in V:
				if absf(q.y - b[0]) < bd:
					bd = absf(q.y - b[0]); by = q.y
			_sk_ring(1, by, 0.034, 0.008, Color(0.5, 0.34, 0.2), -PI, PI, 48, 0.004, 0.0, 0.0, 0.32)
			_sk_plate(b[1], by, 0.042, 0.038, 0.004, Color(0.72, 0.74, 0.78), 0.016, true)   # gümüş toka
			_sk_plate(b[1], by, 0.026, 0.024, 0.004, Color(0.5, 0.34, 0.2), 0.02, true)
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		_sk_ring(0, (ha - 0.1) * sx, 0.02, 0.006, Color(0.07, 0.07, 0.09), -PI, PI, 24, 0.006, sx)   # bilekte siyah şerit
	_sk_end(g)


## Kapüşonlu ceket ayrıntıları (ref refs/outfits_ss/hinata_outfit.png): boyunda dolgun kapüşon yakası, ortada fermuar,
## bilekte iki renkli kat
func _hinata_ceket_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.62, 0.58, 0.85))
	var neck = _bp("Neck").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "hinata_ceket_acik" if look.get("hc_open", false) else "hinata_ceket", 0.0])
	if jm != null and _sk_begin(jm):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		if not look.get("hc_open", false):
			_sk_strip(0.0, neck - 0.12, ybot + 0.01, 0.007, 0.004, oc.darkened(0.3), 28)   # fermuar
		_sk_ring(1, ybot + 0.012, 0.022, 0.006, oc.darkened(0.1), -PI, PI, 48, 0.003, 0.0, 0.0, 0.32)   # etek kenarı
		_sk_end(g)


## Kısa kapüşonlu ayrıntıları (ref refs/outfits_ss/hinata_outfit_2.png): önde iki büzgü ipi + ponpon, kapüşon katı, belde
## alttaki lavanta iç giysinin bandı (gövde kabuğuna)
func _kirpik_kapusonlu_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.9, 0.78, 0.9))
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kirpik_kapusonlu", 0.0])
	if km != null and _sk_begin(km):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_ring(1, ybot + 0.014, 0.026, 0.007, oc.darkened(0.06), -PI, PI, 48, 0.003, 0.0, 0.0, 0.3)   # etek ribanası
		for sx in [-1.0, 1.0]:   # büzgü ipleri + ponpon
			var x0 = -0.03 + 0.022 * sx
			_sk_strip(x0, neck - 0.04, neck - 0.17, 0.005, 0.004, Color(0.25, 0.18, 0.28), 12)
			_sk_plate(x0, neck - 0.18, 0.02, 0.02, 0.012, Color(0.96, 0.94, 0.96), 0.01, true)
		_sk_end(g)
	if look.get("under_band") is Color and _sk_begin(_shell_cache.get(look["gender"])):
		_sk_ring(1, hips + 0.13, 0.045, 0.006, look["under_band"], -PI, PI, 48, 0.004, 0.0, 0.0, 0.3)
		_sk_end(g)


## Kapüşonlu uzun cübbe ayrıntıları (ref refs/outfits_ss/kabuto_robe.png): önde boydan boya beyaz şerit, çan kolların
## ağzında gri-yeşil astar katı
func _yilan_cubbe_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.4, 0.08, 0.12))
	var lc: Color = look.get("lining", Color(0.55, 0.6, 0.55)) if look.get("lining") is Color else Color(0.55, 0.6, 0.55)
	var neck = _bp("Neck").y
	var cm2 = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "yilan_cubbe", 0.0])
	if cm2 != null and _sk_begin(cm2):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_strip(0.0, neck - 0.06, ybot + 0.01, 0.008, 0.004, Color(0.9, 0.9, 0.88), 44)
		_sk_end(g)
	var hx = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "cubbe_kol%d" % int(sx), 0.0])
		if km != null and _sk_begin(km):
			_sk_ring(0, (hx - 0.07) * sx, 0.016, 0.004, lc, -PI, PI, 28, 0.001, sx)
			_sk_end(g)


## Uzun ceket ayrıntıları (ref refs/outfits_ss/karin_outfit.png): dik yaka, belde açılan fermuar, gri kemer + toka, sırtta
## kemere takılı gri çanta
func _algi_ceket_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.72, 0.62, 0.85))
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "algi_ceket", 0.0])
	if jm == null or not _sk_begin(jm):
		return
	var V: PackedVector3Array = _sk["v"]
	_sk_ring(1, neck + 0.0, 0.055, 0.008, oc.darkened(0.05), 0.15, TAU - 0.15, 40, 0.004, 0.0, 0.0, 0.12)   # dik yaka
	_sk_strip(0.0, neck - 0.02, hips + 0.14, 0.006, 0.004, oc.darkened(0.35), 26)   # fermuar
	var by = hips + 0.1
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.1)) < bd:
			bd = absf(q.y - (hips + 0.1)); by = q.y
	var gc := Color(0.62, 0.68, 0.66)
	_sk_ring(1, by, 0.03, 0.007, gc, -PI, PI, 48, 0.004, 0.0, 0.0, 0.3)
	_sk_plate(0.04, by, 0.03, 0.036, 0.004, gc.darkened(0.25), 0.014, true)   # toka
	_sk_plate(0.0, by - 0.035, 0.15, 0.07, 0.03, gc.darkened(0.1), 0.012, false)   # sırt çantası
	_sk_end(g)


## Boyun atkısı + kol bandı (ref refs/outfits_ss/konohamaru_outfit.png): boyunda sarılı mavi atkı, solda düğüm ve iki uç;
## sol üst kolda kırmızı bant
func _boyun_atki_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	if look.get("neck_scarf") is Color:
		var am = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "boyun_atki", 0.0])
		if am != null and _sk_begin(am):
			var sc: Color = look["neck_scarf"]
			var h = _sk_hit(0.06, neck - 0.0, true, 0.03)
			if not h.is_empty():
				var p0: Vector3 = h[0] + Vector3(0, 0, 0.008)
				_sk_box(p0, Vector3(0.02, 0, 0), Vector3(0, 0.02, 0), Vector3(0, 0, 0.012), sc.darkened(0.1))   # düğüm
				_sk_box(p0 + Vector3(0.035, -0.02, 0.0), Vector3(0.03, -0.012, 0), Vector3(0.01, 0.026, 0), Vector3(0, 0, 0.006), sc)   # uç 1
				_sk_box(p0 + Vector3(0.02, -0.045, 0.004), Vector3(0.016, -0.02, 0), Vector3(0.014, 0.02, 0), Vector3(0, 0, 0.006), sc.darkened(0.05))   # uç 2
			_sk_end(g)
	if look.get("armband") is Color and _sk_begin(_shell_cache.get(look["gender"])):
		var ax = lerpf(absf(_bp("LeftUpperArm").x), absf(_bp("LeftLowerArm").x), 0.4)
		var asd = float(look.get("armband_side", 1.0))
		_sk_ring(0, ax * asd, 0.05, 0.007, look["armband"], -PI, PI, 24, 0.008, asd)
		_sk_end(g)


## Sargı elbise ayrıntıları (ref refs/outfits_ss/kurenai_outfit.png): gövdeyi çapraz saran kalın sargı bantları (önde ve
## arkada zıt yönlerde), her bandın alt kenarında koyu dikenli şerit
func _sargi_elbise_kit(g: Dictionary) -> void:
	var wc: Color = look.get("outer", Color(0.95, 0.95, 0.94))
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "sargi_elbise", 0.0])
	if em == null or not _sk_begin(em):
		return
	var dark := Color(0.1, 0.08, 0.1)
	var bands = []
	for k in 5:
		var y0 = neck - 0.1 - k * 0.075
		bands.append([Vector2(-0.16, y0), Vector2(0.16, y0 - 0.16), true])
		bands.append([Vector2(0.16, y0 - 0.03), Vector2(-0.16, y0 - 0.19), false])
	for bnd in bands:
		var a: Vector2 = bnd[0]
		var b: Vector2 = bnd[1]
		var pts = []; var outs = []; var pd = []; var od = []
		for k in 13:
			var q = a.lerp(b, k / 12.0)
			if q.y < hips - 0.2:
				continue
			var hit = _sk_hit(q.x, q.y, bnd[2], 0.03)
			if hit.is_empty():
				continue
			var z = hit[0].z + (0.006 if bnd[2] else -0.006)
			pts.append(Vector3(q.x, q.y, z)); outs.append(hit[1])
			pd.append(Vector3(q.x, q.y - 0.024, z + (0.003 if bnd[2] else -0.003))); od.append(hit[1])
		if pts.size() > 1:
			var dir = (Vector3(b.x, b.y, 0) - Vector3(a.x, a.y, 0)).normalized()
			var wd = Vector3.BACK.cross(dir).normalized()
			_sk_band(pts, outs, wd, 0.05, 0.006, wc.darkened(0.03))
			_sk_band(pd, od, wd, 0.006, 0.007, dark)
	_sk_end(g)


## İki tonlu kimono ayrıntıları (ref refs/outfits_ss/mitsuki_outfit.png): geniş kahve kuşak + hilal plakası, sırtta çanta
func _iki_ton_kimono_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "iki_ton_kimono", 0.0])
	if km == null or not _sk_begin(km):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.1
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.1)) < bd:
			bd = absf(q.y - (hips + 0.1)); by = q.y
	var bc := Color(0.55, 0.45, 0.36)
	_sk_ring(1, by, 0.075, 0.01, bc, -PI, PI, 56, 0.004, 0.0, 0.0, 0.32)
	_sk_ring(1, by + 0.03, 0.006, 0.004, bc.darkened(0.3), -PI, PI, 56, 0.012, 0.0, 0.0, 0.32)
	_sk_ring(1, by - 0.03, 0.006, 0.004, bc.darkened(0.3), -PI, PI, 56, 0.012, 0.0, 0.0, 0.32)
	_sk_plate(0.07, by, 0.05, 0.06, 0.004, bc.darkened(0.2), 0.014, true)   # toka plakası
	_sk_plate(0.072, by, 0.016, 0.034, 0.004, Color(0.95, 0.95, 0.94), 0.018, true)   # hilal
	_sk_plate(0.0, by - 0.02, 0.16, 0.07, 0.03, bc.darkened(0.1), 0.012, false)   # sırt çantası
	_sk_end(g)


## Kapalı eşofman ceketi ayrıntıları (ref refs/outfits_ss/naruto_outfit.png): dik siyah yaka, ortada fermuar, sol omuzda arma
## yaması, bel ribanası
func _turuncu_ceket_kit(g: Dictionary) -> void:
	var c2: Color = look.get("outer_accent", Color(0.12, 0.12, 0.16)) if look.get("outer_accent") is Color else Color(0.12, 0.12, 0.16)
	var neck = _bp("Neck").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "turuncu_ceket", 0.0])
	if jm != null and _sk_begin(jm):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_ring(1, neck + 0.005, 0.07, 0.01, c2, -PI, PI, 40, 0.004, 0.0, 0.0, 0.12)   # dik yaka
		_sk_strip(0.0, neck + 0.06, ybot + 0.01, 0.007, 0.004, Color(0.78, 0.78, 0.8), 34)   # fermuar
		_sk_ring(1, ybot + 0.02, 0.04, 0.007, c2, -PI, PI, 48, 0.003, 0.0, 0.0, 0.32)   # bel ribanası
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		_sk_ring(0, (ha - 0.065) * sx, 0.04, 0.009, c2.darkened(0.1), -PI, PI, 24, 0.006, sx)
	# sol üst kolda arma yaması: kolun dış yüzü (T pozu +Y)
	var ax = lerpf(absf(_bp("LeftUpperArm").x), absf(_bp("LeftLowerArm").x), 0.3)
	var V2: PackedVector3Array = _sk["v"]
	var top = Vector3.ZERO; var by = -9.0
	for q in V2:
		if q.x > 0.0 and absf(q.x - ax) < 0.015 and absf(q.z) < 0.03 and q.y > by:
			by = q.y; top = q
	if by > -8.0:
		_sk_box(top + Vector3(0, 0.006, 0), Vector3(0.026, 0, 0), Vector3(0, 0.003, 0), Vector3(0, 0, 0.03), Color(0.28, 0.28, 0.32))
	_sk_end(g)


## Kısa bolero ayrıntıları (ref refs/outfits_ss/sai_outfit.png): önde omuzlarda iki kırmızı şerit, belde beyaz-kırmızı kemer +
## toka, kalçada asılı kırmızı-altın parşömen
func _kisa_bolero_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var bm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kisa_bolero", 0.0])
	if bm != null and _sk_begin(bm):
		for sx in [-1.0, 1.0]:
			_sk_strip(0.115 * sx, neck - 0.0, neck - 0.11, 0.022, 0.005, Color(0.72, 0.12, 0.14), 10)
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var red := Color(0.72, 0.12, 0.14)
	_sk_ring(1, hips + 0.07, 0.034, 0.008, Color(0.94, 0.94, 0.92), -PI, PI, 48, 0.006, 0.0, 0.0, 0.3)
	for e in [-1.0, 1.0]:
		_sk_ring(1, hips + 0.07 + e * 0.011, 0.005, 0.004, red, -PI, PI, 48, 0.013, 0.0, 0.0, 0.3)
	_sk_plate(0.0, hips + 0.07, 0.04, 0.04, 0.005, Color(0.82, 0.82, 0.86), 0.016, true)
	# parşömen: kalçanın arkasında yatay rulo (kırmızı gövde, altın uçlar), kemere asılı
	var h = _sk_hit(0.0, hips - 0.04, false, 0.04)
	if not h.is_empty():
		var c0: Vector3 = h[0] + Vector3(0, 0, -0.04)
		for k in 8:
			var a0 = TAU * k / 8.0
			var d = Vector3(0, cos(a0), sin(a0)) * 0.03
			_sk_box(c0 + d, Vector3(0.13, 0, 0), Vector3(0, -sin(a0), cos(a0)) * 0.012, d.normalized() * 0.006, red)
			for sx in [-1.0, 1.0]:
				_sk_box(c0 + Vector3(0.15 * sx, 0, 0) + d * 1.1, Vector3(0.022, 0, 0), Vector3(0, -sin(a0), cos(a0)) * 0.013, d.normalized() * 0.006, Color(0.88, 0.7, 0.25))
	_sk_end(g)


## Bilezik (ref kushina_outfit.png): sol bilekte siyah halka
func _bangle_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	_sk_ring(0, ha - 0.06, 0.012, 0.009, look["bangle"], -PI, PI, 24, 0.008, 1.0)
	_sk_end(g)


## Kalın burgu ip (shimenawa) parçası: noktalar boyunca kısa eğik dilimler (burgulu görünüm), etkin SurfaceKit kaynağına derili
func _sk_rope(pts: Array, r: float, col: Color) -> void:
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d = b - a
		var n = d.length()
		if n < 0.001:
			continue
		var f = d / n
		var side = f.cross(Vector3.BACK)
		if side.length() < 0.1:
			side = f.cross(Vector3.UP)
		side = side.normalized()
		var up = side.cross(f).normalized()
		var segs = maxi(1, int(n / (r * 1.6)))
		for k in segs:
			var c = a + d * ((k + 0.5) / segs)
			var tw = (side * cos(0.6) + up * sin(0.6)) * r
			_sk_box(c, f * (n / segs) * 0.62, tw, up.cross(f).normalized() * r if k % 2 == 0 else side * r, col if k % 2 == 0 else col.darkened(0.12))


## Bel örtüsü + ip kuşak ayrıntıları (ref refs/outfits_ss/sasuke_outfit.png): belde mor burgu ip halkası, önde solda sarkan
## iki uzun ip ilmeği; bilekte lacivert ter bandı (gövde kabuğu)
func _bel_ortusu_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var knee = _bp("LeftLowerLeg").y
	var bm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "bel_ortusu", 0.0])
	var rc: Color = look.get("rope", Color(0.55, 0.45, 0.82)) if look.get("rope") is Color else Color(0.55, 0.45, 0.82)
	if bm != null and _sk_begin(bm):
		var V: PackedVector3Array = _sk["v"]
		var ytop = -9.0
		for q in V:
			ytop = maxf(ytop, q.y)
		var yb = ytop - 0.03
		var ring = []
		for k in 33:
			var a = TAU * k / 32.0
			var best = Vector3.ZERO; var br = -1.0
			for q in V:
				if absf(q.y - yb) < 0.02:
					var aq = atan2(q.z, q.x)
					if absf(wrapf(aq - a, -PI, PI)) < 0.12:
						var rr = Vector2(q.x, q.z).length()
						if rr > br:
							br = rr; best = q
			if br > 0.0:
				ring.append(best + Vector3(best.x, 0, best.z).normalized() * 0.022)
		_sk_rope(ring, 0.02, rc)
		# önde solda sarkan iki ilmek
		var hit = _sk_hit(0.08, yb, true, 0.04)
		if not hit.is_empty():
			var p0: Vector3 = hit[0] + Vector3(0, 0, 0.03)
			for lo in [[0.0, 0.0], [0.035, 0.025]]:
				var lp = []
				var depth = (yb - (knee + 0.02)) * (1.0 if lo[0] == 0.0 else 0.82)
				for k in 13:
					var t = k / 12.0
					lp.append(p0 + Vector3(lo[0] + 0.04 * sin(t * PI), -depth * sin(t * PI * 0.5) * (1.0 if t < 0.5 else 1.0) * (1.0 - absf(t - 0.5) * 0.0), lo[1] + 0.01 * sin(t * TAU)) + (Vector3(0.05, 0, 0) * t))
				_sk_rope(lp, 0.017, rc.darkened(0.04))
		_sk_end(g)
	if look.get("wristband") is Color and _sk_begin(_shell_cache.get(look["gender"])):
		var ha = absf(_bp("LeftHand").x)
		for sx in [1.0, -1.0]:
			_sk_ring(0, (ha - 0.075) * sx, 0.05, 0.01, look["wristband"], -PI, PI, 24, 0.008, sx)
		_sk_end(g)


## Kolsuz palto ayrıntıları (ref refs/outfits_ss/sasuke_outfit_2.png): sol omuzdan sağ kalçaya inen ince koyu kayış
func _kolsuz_palto_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var pm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kolsuz_palto", 0.0])
	if pm == null or not _sk_begin(pm):
		return
	var a = Vector2(0.13, neck - 0.04)
	var b = Vector2(-0.14, hips + 0.04)
	var pts = []; var outs = []
	for k in 17:
		var q = a.lerp(b, k / 16.0)
		var hit = _sk_hit(q.x, q.y, true, 0.03)
		if not hit.is_empty():
			pts.append(Vector3(q.x, q.y, hit[0].z + 0.004)); outs.append(hit[1])
	if pts.size() > 1:
		var dir = (Vector3(b.x, b.y, 0) - Vector3(a.x, a.y, 0)).normalized()
		_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.012, 0.005, Color(0.2, 0.2, 0.26))
	_sk_end(g)


## Kuyruklu ceket ayrıntıları (ref refs/outfits_ss/shikamaru_outfit.png): önü açık dik yaka (kıvrık), kolye (gövde kabuğu)
func _kuyruklu_ceket_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.9, 0.82, 0.55))
	var neck = _bp("Neck").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kuyruklu_ceket", 0.0])
	if jm != null and _sk_begin(jm):
		_sk_ring(1, neck + 0.01, 0.075, 0.01, oc.darkened(0.04), 0.55, TAU - 0.55, 40, 0.008, 0.0, 0.0, 0.12)   # dik açık yaka
		_sk_end(g)


## Kolye (ref shikamaru_outfit.png): boynu saran ince zincir + göğüste halka
func _necklace_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var neck = _bp("Neck").y
	var nc: Color = look["necklace"]
	_sk_ring(1, neck + 0.02, 0.004, 0.003, nc, -PI, PI, 40, 0.006, 0.0, 0.0, 0.1)
	var h = _sk_hit(0.0, neck - 0.09, true, 0.03)
	if not h.is_empty():
		var c0: Vector3 = h[0] + Vector3(0, 0, 0.006)
		for k in 10:
			var a0 = TAU * k / 10.0
			var d = Vector3(cos(a0), sin(a0), 0)
			_sk_box(c0 + d * 0.014, d.cross(Vector3.BACK) * 0.0055, d * 0.0018, Vector3(0, 0, 0.002), nc)
		for k in 6:   # zincirden halkaya iki ince kol
			var t = k / 5.0
			for sx in [-1.0, 1.0]:
				var hh = _sk_hit(0.04 * sx * (1.0 - t), lerpf(neck + 0.0, neck - 0.075, t), true, 0.03)
				if not hh.is_empty():
					_sk_box(hh[0] + Vector3(0, 0, 0.004), Vector3(0.0015, 0, 0), Vector3(0.006 * sx, 0.009, 0), Vector3(0, 0, 0.0015), nc)
	_sk_end(g)


## Kısa kimono ayrıntıları (ref refs/outfits_ss/temari_outfit.png): geniş koyu obi + açık çizgiler, pembe ip
func _kisa_kimono_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kisa_kimono", 0.0])
	if km == null or not _sk_begin(km):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.13
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.13)) < bd:
			bd = absf(q.y - (hips + 0.13)); by = q.y
	var kk: Dictionary = look.get("kk") if look.get("kk") is Dictionary else {}
	var oc: Color = kk.get("obi", Color(0.1, 0.12, 0.3))
	_sk_ring(1, by, 0.095, 0.01, oc, -PI, PI, 56, 0.004, 0.0, 0.0, 0.32)
	if kk.is_empty():
		for e in [-1.0, 1.0]:
			_sk_ring(1, by + e * 0.006, 0.004, 0.003, Color(0.85, 0.82, 0.9), -PI, PI, 56, 0.012, 0.0, 0.0, 0.32)
		_sk_ring(1, by - 0.03, 0.006, 0.006, Color(0.95, 0.72, 0.8), -PI, PI, 56, 0.014, 0.0, 0.0, 0.32)   # pembe ip (obijime)
	if kk.get("collar") is Color:   # yakadan bele inen iki beyaz yaka bandı (kruvaze)
		var neck = _bp("Neck").y
		for sx in [-1.0, 1.0]:
			var a = Vector2(0.065 * sx, neck + 0.0)
			var b = Vector2(0.012 * sx, by + 0.04)
			var pts = []; var outs = []
			for k in 13:
				var q = a.lerp(b, k / 12.0)
				var hit = _sk_hit(q.x, q.y, true, 0.03)
				if not hit.is_empty():
					pts.append(Vector3(q.x, q.y, hit[0].z + 0.004 + (0.004 if sx < 0.0 else 0.0))); outs.append(hit[1])
			if pts.size() > 1:
				var dir = (Vector3(b.x, b.y, 0) - Vector3(a.x, a.y, 0)).normalized()
				_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.028, 0.005, kk["collar"])
	_sk_end(g)
	if (look.get("kk") if look.get("kk") is Dictionary else {}).get("sleeve") is Color:   # kol ağzında beyaz bant
		var tel = absf(_bp("LeftLowerArm").x)
		for sx in [1.0, -1.0]:
			var km2 = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kimono_kol%d" % int(sx), 0.0])
			if km2 != null and _sk_begin(km2):
				_sk_ring(0, (tel + 0.1) * sx, 0.03, 0.005, look["kk"]["sleeve"], -PI, PI, 28, 0.002, sx)
				_sk_end(g)


## Çin tarzı üst ayrıntıları (ref refs/outfits_ss/tenten_outfit.png): dik yaka, yakadan sağ koltuğa ve aşağı inen kırmızı biye,
## kırmızı düğüm düğmeler, kırmızı etek bandı ve kıvrık kırmızı manşetler, bilekte mavi bilezik (gövde kabuğu)
func _cin_ust_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var rc: Color = look["cin_ust"]
	_sk_ring(1, neck + 0.03, 0.05, 0.008, Color(0.96, 0.96, 0.95), -PI, PI, 40, 0.006, 0.0, 0.0, 0.1)   # dik yaka
	_sk_ring(1, neck + 0.055, 0.006, 0.006, rc, -PI, PI, 40, 0.011, 0.0, 0.0, 0.1)
	# biye: yakadan (x=0) sağa (−x) kıvrılıp koltuk altından bele
	var path = []
	for k in 9:
		var t = k / 8.0
		path.append(Vector2(-0.1 * sin(t * PI * 0.5), lerpf(neck + 0.0, chest - 0.08, t)))
	for k in 1:
		path.append(Vector2(-0.1, hips + 0.14))
	var pts = []; var outs = []
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		for k in 4:
			var q = a.lerp(b, k / 4.0)
			var hit = _sk_hit(q.x, q.y, true, 0.025)
			if not hit.is_empty():
				pts.append(Vector3(q.x, q.y, hit[0].z + 0.005)); outs.append(hit[1])
	if pts.size() > 1:
		_sk_band(pts, outs, Vector3.RIGHT, 0.012, 0.005, rc)
	for k in 3:   # düğüm düğmeler
		var q = path[2 + k * 2]
		_sk_plate(q.x - 0.018, q.y, 0.03, 0.008, 0.004, rc, 0.01, true)
	_sk_ring(1, hips + 0.12, 0.022, 0.007, rc, -PI, PI, 48, 0.008, 0.0, 0.0, 0.3)   # etek bandı
	var ha = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		_sk_ring(0, (ha - 0.11) * sx, 0.035, 0.011, rc, -PI, PI, 24, 0.008, sx)   # kıvrık manşet
		_sk_ring(0, (ha - 0.055) * sx, 0.012, 0.008, Color(0.2, 0.25, 0.6), -PI, PI, 24, 0.007, sx)   # bilezik
	_sk_end(g)


## Güneş kimonosu ayrıntıları (ref refs/outfits_ss/15_million_user_celebration_outfits.png): siyah kuşak, kuşaktan sarkan
## 9 parlak magatama, sol yanda sarkan renkli bez, sağ omuzda bez düğüm
func _gunes_kimono_kit(g: Dictionary) -> void:
	var gk: Dictionary = look.get("gk") if look.get("gk") is Dictionary else {}
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "gunes_kimono", 0.0])
	if km == null or not _sk_begin(km):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.08
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.08)) < bd:
			bd = absf(q.y - (hips + 0.08)); by = q.y
	_sk_ring(1, by, 0.05, 0.01, Color(0.12, 0.08, 0.08), -PI, PI, 56, 0.005, 0.0, 0.0, 0.34)   # kuşak
	var mc: Color = gk.get("magatama", Color(1.0, 0.86, 0.25))
	for k in 9:   # magatama dizisi: kuşağın önünde soldan sağa
		var x = -0.02 + k * 0.016
		var h = _sk_hit(x, by - 0.02, true, 0.03)
		if h.is_empty():
			continue
		var p0: Vector3 = h[0] + Vector3(0, -0.015, 0.012)
		_sk_box(p0, Vector3(0.007, 0, 0), Vector3(0.002, -0.016, 0), Vector3(0, 0, 0.006), mc)
		_sk_box(p0 + Vector3(0.0, -0.016, 0.0), Vector3(0.005, 0, 0), Vector3(0.004, -0.008, 0), Vector3(0, 0, 0.005), mc)
	var cc: Color = gk.get("cloth", Color(0.8, 0.12, 0.12))
	var hc = _sk_hit(0.15, by, true, 0.04)
	if not hc.is_empty():   # sol yanda sarkan bez (iki kat)
		var p1: Vector3 = hc[0] + Vector3(0, 0, 0.015)
		_sk_box(p1 + Vector3(0, -0.11, 0), Vector3(0.05, 0, 0.0), Vector3(0.012, 0.11, 0.0), Vector3(0, 0, 0.006), cc)
		_sk_box(p1 + Vector3(0.025, -0.08, 0.01), Vector3(0.035, 0, 0), Vector3(0.02, 0.08, 0), Vector3(0, 0, 0.005), cc.lightened(0.2))
	var hs = _sk_hit(-0.1, neck - 0.02, true, 0.04)
	if not hs.is_empty():   # sağ omuzda bez düğüm
		var p2: Vector3 = hs[0] + Vector3(0, 0.01, 0.012)
		var kc: Color = gk.get("knot", Color(0.96, 0.95, 0.9))
		_sk_box(p2, Vector3(0.018, 0, 0), Vector3(0, 0.018, 0), Vector3(0, 0, 0.014), kc)
		_sk_box(p2 + Vector3(-0.004, -0.035, 0.0), Vector3(0.012, 0, 0), Vector3(0.004, 0.03, 0), Vector3(0, 0, 0.008), kc.darkened(0.05))
	_sk_end(g)


## Bol gömlek ayrıntıları (ref refs/outfits_ss/amado_outfit.png): geniş açık yaka, ince altın zincir kolye (gövde kabuğu)
func _genis_gomlek_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.1, 0.1, 0.12))
	var neck = _bp("Neck").y
	var gm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "genis_gomlek", 0.0])
	if gm != null and _sk_begin(gm):
		_sk_ring(1, neck + 0.01, 0.06, 0.008, oc.darkened(0.05), 0.5, TAU - 0.5, 40, 0.01, 0.0, 0.0, 0.13)   # geniş açık yaka
		_sk_end(g)
	if _sk_begin(_shell_cache.get(look["gender"])):
		_sk_ring(1, neck + 0.015, 0.006, 0.005, Color(0.92, 0.75, 0.25), -PI, PI, 40, 0.008, 0.0, 0.0, 0.1)
		_sk_end(g)


## Uzun trençkot ayrıntıları (ref refs/outfits_ss/anko_outfit.png): açık dik yaka, kalçada iki büyük torba cep, bilekte geniş
## katlı manşet (gövde kabuğu)
func _uzun_trench_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.85, 0.75, 0.58))
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var tm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "uzun_trench", 0.0])
	if tm != null and _sk_begin(tm):
		_sk_ring(1, neck + 0.01, 0.06, 0.008, oc.darkened(0.04), 0.5, TAU - 0.5, 40, 0.008, 0.0, 0.0, 0.13)
		for sx in [-1.0, 1.0]:
			_sk_plate(0.13 * sx, hips - 0.1, 0.1, 0.11, 0.005, oc.darkened(0.05), 0.004, true)   # torba cep
			_sk_plate(0.13 * sx, hips - 0.05, 0.104, 0.02, 0.006, oc.darkened(0.12), 0.008, true)   # cep kapağı
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		_sk_ring(0, (ha - 0.09) * sx, 0.07, 0.016, oc.darkened(0.06), -PI, PI, 24, 0.012, sx)
	_sk_end(g)


## Jōnin aksesuarları (ref refs/outfits_ss/asuma_outfit.png): üst kolda iki beyaz sargı bandı + omuzda kırmızı girdap, belde
## önden sarkan üçgen açık mavi bez (ortada kırmızı 火 işareti), iki bilekte mavi bilezik — gövde kabuğuna derili
func _jonin_aks_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var ua = absf(_bp("LeftUpperArm").x)
	var el = absf(_bp("LeftLowerArm").x)
	var ha = absf(_bp("LeftHand").x)
	var wc: Color = look["jonin_aks"]
	for sx in [1.0, -1.0]:
		for k in 2:
			_sk_ring(0, lerpf(ua, el, 0.62 + k * 0.12) * sx, 0.016, 0.006, wc, -PI, PI, 24, 0.008, sx)
		_sk_ring(0, (ha - 0.07) * sx, 0.012, 0.009, Color(0.2, 0.3, 0.7), -PI, PI, 24, 0.008, sx)   # bilezik
		# omuzda kırmızı girdap: kolun dış (+Y) yüzünde disk
		var ax = lerpf(ua, el, 0.25)
		var V: PackedVector3Array = _sk["v"]
		var top = Vector3.ZERO; var by = -9.0
		for q in V:
			if signf(q.x) == sx and absf(absf(q.x) - ax) < 0.015 and absf(q.z) < 0.03 and q.y > by:
				by = q.y; top = q
		if by > -8.0:
			for k in 8:
				var a0 = TAU * k / 8.0
				_sk_box(top + Vector3(cos(a0) * 0.011, 0.004, sin(a0) * 0.011), Vector3(0.011, 0, 0).rotated(Vector3.UP, -a0), Vector3(0, 0.002, 0), Vector3(0, 0, 0.011).rotated(Vector3.UP, -a0), Color(0.75, 0.12, 0.14) if k % 2 == 0 else Color(0.55, 0.08, 0.1))
	var h = _sk_hit(0.0, hips - 0.01, true, 0.04)
	if not h.is_empty():   # üçgen bez (ref: kalça genişliğinde, uyluğa sivrilen; ortada kırmızı daire içinde beyaz 火)
		var p0: Vector3 = h[0] + Vector3(0, 0, 0.045)
		var sc: Color = look.get("fire_sash", Color(0.75, 0.85, 0.95)) if look.get("fire_sash") is Color else Color(0.75, 0.85, 0.95)
		for k in 9:
			var w = 0.11 * (1.0 - k / 9.0)
			_sk_box(p0 + Vector3(0, -k * 0.021, 0.002 - k * 0.002), Vector3(w, 0, 0), Vector3(0, 0.011, 0), Vector3(0, 0, 0.004), sc)
		var ec = p0 + Vector3(0, -0.055, 0.006)
		_sk_disc(ec, Vector3(0, 0, 1), 0.034, 0.003, Color(0.78, 0.12, 0.16))
		_sk_box(ec + Vector3(0, 0.0, 0.004), Vector3(0.003, 0, 0), Vector3(0, 0.02, 0), Vector3(0, 0, 0.001), Color(0.95, 0.95, 0.95))
		for sx in [1.0, -1.0]:
			_sk_box(ec + Vector3(0.012 * sx, -0.004, 0.004), Vector3(0.003, 0, 0), Vector3(0.004 * sx, 0.012, 0), Vector3(0, 0, 0.001), Color(0.95, 0.95, 0.95))
			_sk_box(ec + Vector3(0.006 * sx, 0.012, 0.004), Vector3(0.0025, 0, 0), Vector3(0, 0.005, 0), Vector3(0, 0, 0.001), Color(0.95, 0.95, 0.95))
	_sk_end(g)


## Rikudō cübbesi ayrıntıları (ref refs/outfits_ss/asura_outfit.png): uzun dik yaka (önde kruvaze), geniş lacivert obi
func _rikudo_cubbe_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.93, 0.93, 0.95))
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var rm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "rikudo_cubbe", 0.0])
	if rm == null or not _sk_begin(rm):
		return
	_sk_ring(1, neck + 0.02, 0.1, 0.01, oc.darkened(0.03), 0.25, TAU - 0.25, 40, 0.012, 0.0, 0.0, 0.13)   # uzun dik yaka
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.1
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.1)) < bd:
			bd = absf(q.y - (hips + 0.1)); by = q.y
	_sk_ring(1, by, 0.08, 0.01, Color(0.14, 0.16, 0.36), -PI, PI, 56, 0.004, 0.0, 0.0, 0.34)
	_sk_end(g)


## Kutlama kimonosu ayrıntıları (ref refs/outfits_ss/celebratory_outfits.png): siyah kuşak + bej ip kuşak ve ortada mavi
## boncuk, sol kalçada sarkan bej ip ilmeği, sol omuzda gümüş-bej katmanlı omuzluk, boyundan sarkan mavi boncuklu beyaz püsküller
func _kutlama_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var knee = _bp("LeftLowerLeg").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kutlama_kimono", 0.0])
	if km != null and _sk_begin(km):
		var V: PackedVector3Array = _sk["v"]
		var by = hips + 0.1
		var bd = 9.0
		for q in V:
			if absf(q.y - (hips + 0.1)) < bd:
				bd = absf(q.y - (hips + 0.1)); by = q.y
		_sk_ring(1, by, 0.05, 0.01, Color(0.1, 0.08, 0.08), -PI, PI, 56, 0.004, 0.0, 0.0, 0.34)
		_sk_ring(1, by + 0.0, 0.012, 0.01, Color(0.85, 0.72, 0.52), -PI, PI, 56, 0.014, 0.0, 0.0, 0.34)
		var hb = _sk_hit(0.0, by, true, 0.03)
		if not hb.is_empty():
			_sk_box(hb[0] + Vector3(0, 0, 0.024), Vector3(0.012, 0, 0), Vector3(0, 0.012, 0), Vector3(0, 0, 0.01), Color(0.2, 0.7, 0.85))
		var hr = _sk_hit(0.15, by - 0.02, true, 0.05)
		if not hr.is_empty():   # sol kalçada sarkan kalın ip ilmeği
			var p0: Vector3 = hr[0] + Vector3(0, 0, 0.02)
			var lp = []
			for k in 15:
				var t = k / 14.0
				lp.append(p0 + Vector3(0.03 * sin(t * TAU), -(by - knee) * 0.85 * sin(t * PI), 0.02 * cos(t * TAU)))
			_sk_rope(lp, 0.016, Color(0.85, 0.72, 0.52))
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	# sol omuzluk: üst kolun dış yüzünde aşağı doğru üst üste binen üç plaka
	var ua = absf(_bp("LeftUpperArm").x)
	var el = absf(_bp("LeftLowerArm").x)
	for k in 3:
		var ax = lerpf(ua * 0.9, el, 0.12 + k * 0.2)
		var V2: PackedVector3Array = _sk["v"]
		var top = Vector3.ZERO; var bytop = -9.0
		for q in V2:
			if q.x > 0.0 and absf(q.x - ax) < 0.02 and absf(q.z) < 0.04 and q.y > bytop:
				bytop = q.y; top = q
		if bytop > -8.0:
			var pc = Color(0.78, 0.78, 0.8) if k % 2 == 0 else Color(0.82, 0.74, 0.6)
			_sk_box(top + Vector3(0.0, 0.028, 0), Vector3(0.05, -0.01, 0), Vector3(0, 0.006, 0), Vector3(0, 0, 0.065), pc)
	# boyundan sarkan iki beyaz püskül + mavi boncuk
	for sx in [-1.0, 1.0]:
		var h = _sk_hit(0.08 * sx, neck - 0.1, true, 0.04)
		if h.is_empty():
			continue
		var c0: Vector3 = h[0] + Vector3(0, 0, 0.03)
		_sk_box(c0, Vector3(0.016, 0, 0), Vector3(0, 0.016, 0), Vector3(0, 0, 0.014), Color(0.2, 0.7, 0.85))
		_sk_box(c0 + Vector3(0, -0.06, 0), Vector3(0.012, 0, 0), Vector3(0.004, 0.045, 0), Vector3(0, 0, 0.008), Color(0.94, 0.94, 0.92))
	_sk_end(g)


## Kolsuz kimono üst ayrıntıları (ref refs/outfits_ss/cho_cho_outfit.png): geniş turuncu obi + önde büyük fiyonk düğüm, üstünde
## ince kahve kemer, sırtta sarı çanta
func _kolsuz_kimono_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kolsuz_kimono", 0.0])
	if km == null or not _sk_begin(km):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.13
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.13)) < bd:
			bd = absf(q.y - (hips + 0.13)); by = q.y
	var oc := Color(0.95, 0.62, 0.15)
	_sk_ring(1, by, 0.08, 0.012, oc, -PI, PI, 56, 0.004, 0.0, 0.0, 0.34)
	_sk_ring(1, by - 0.03, 0.014, 0.006, Color(0.42, 0.28, 0.16), -PI, PI, 56, 0.016, 0.0, 0.0, 0.34)
	var h = _sk_hit(0.0, by, true, 0.03)
	if not h.is_empty():
		var p0: Vector3 = h[0] + Vector3(0, 0, 0.02)
		for sx in [-1.0, 1.0]:
			_sk_box(p0 + Vector3(0.045 * sx, 0.008, 0.0), Vector3(0.042, 0.018 * sx, 0), Vector3(-0.01 * sx, 0.03, 0), Vector3(0, 0, 0.012), oc.darkened(0.05))
		_sk_box(p0 + Vector3(0, 0, 0.008), Vector3(0.02, 0, 0), Vector3(0, 0.026, 0), Vector3(0, 0, 0.016), oc.darkened(0.15))
	_sk_plate(0.0, by - 0.01, 0.13, 0.06, 0.03, Color(0.95, 0.85, 0.3), 0.016, false)   # sırtta sarı çanta
	_sk_end(g)


## Takım yeleği ayrıntıları (ref refs/outfits_ss/code_outfit.png): boyunda katlı beyaz kravat
func _takim_yelek_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var h = _sk_hit(0.0, neck - 0.02, true, 0.04)
	if not h.is_empty():
		var p0: Vector3 = h[0] + Vector3(0, 0, 0.03)
		var wc := Color(0.92, 0.9, 0.96)
		_sk_box(p0, Vector3(0.022, 0, 0), Vector3(0, 0.014, 0), Vector3(0, 0, 0.012), wc)
		for sx in [-1.0, 1.0]:
			_sk_box(p0 + Vector3(0.016 * sx, -0.045, 0.004), Vector3(0.02, 0, 0), Vector3(-0.012 * sx, 0.045, 0), Vector3(0, 0, 0.006), wc.darkened(0.04))
	_sk_end(g)


## Shimenawa fiyonku (ref refs/outfits_ss/custom_ninja_outfit_type_three.png): zırhın önünde kalın beyaz burgu ipten iki büyük
## ilmekli fiyonk + aşağı sarkan iki uç (gövde kabuğundan zırh kalınlığı kadar dışarıda)
func _shimenawa_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var wc: Color = look["shimenawa"]
	var h = _sk_hit(0.0, chest - 0.1, true, 0.04)
	if not h.is_empty():
		var c0: Vector3 = h[0] + Vector3(0, 0, 0.1)
		for sx in [-1.0, 1.0]:
			var lp = []
			for k in 17:
				var a = TAU * k / 16.0
				lp.append(c0 + Vector3(sx * (0.08 + 0.07 * cos(a + PI)), 0.045 * sin(a), 0.0))
			_sk_rope(lp, 0.016, wc)
			var tp = []
			for k in 9:
				var t = k / 8.0
				tp.append(c0 + Vector3(0.02 * sx + 0.015 * sx * t, -0.02 - t * 0.2, 0.004))
			_sk_rope(tp, 0.016, wc.darkened(0.04))
		_sk_box(c0, Vector3(0.022, 0, 0), Vector3(0, 0.026, 0), Vector3(0, 0, 0.02), wc.darkened(0.08))
	_sk_end(g)


## Çivili kısa kapüşonlu ayrıntıları (ref refs/outfits_ss/daemon_outfit.png): önde iki sıra gümüş çivi, fermuar + yıldız
## çekme ucu, belde gri kemer, sağ kalçadan sarkan zincir
func _seytan_kapuson_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "seytan_kapuson", 0.0])
	if km != null and _sk_begin(km):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		for sx in [-1.0, 1.0]:
			var y = neck - 0.04
			while y > ybot + 0.02:
				_sk_plate(0.12 * sx, y, 0.008, 0.008, 0.005, Color(0.82, 0.82, 0.86), 0.006, true)
				y -= 0.02
		_sk_strip(0.0, neck + 0.0, ybot + 0.01, 0.006, 0.004, Color(0.75, 0.75, 0.78), 24)
		var h = _sk_hit(0.0, neck - 0.04, true, 0.03)
		if not h.is_empty():   # yıldız çekme ucu
			var c0: Vector3 = h[0] + Vector3(0, 0, 0.008)
			for k in 5:
				var a0 = TAU * k / 5.0 + PI * 0.5
				var d = Vector3(cos(a0), sin(a0), 0)
				_sk_box(c0 + d * 0.008, d * 0.008, d.cross(Vector3.BACK) * 0.004, Vector3(0, 0, 0.003), Color(0.85, 0.85, 0.9))
		_sk_end(g)
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	_sk_ring(1, hips + 0.05, 0.035, 0.008, Color(0.55, 0.55, 0.6), -PI, PI, 48, 0.008, 0.0, 0.0, 0.3)
	for e in [-1.0, 1.0]:
		_sk_ring(1, hips + 0.05 + e * 0.009, 0.004, 0.004, Color(0.92, 0.92, 0.94), -PI, PI, 48, 0.014, 0.0, 0.0, 0.3)
	var hc = _sk_hit(-0.1, hips + 0.04, true, 0.04)
	if not hc.is_empty():   # sarkan zincir: sağ kalçadan öne doğru sarkan yay
		var p0: Vector3 = hc[0] + Vector3(0, 0, 0.02)
		var lp = []
		for k in 13:
			var t = k / 12.0
			lp.append(p0 + Vector3(0.14 * t, -0.09 * sin(t * PI), 0.01 * sin(t * PI)))
		_sk_rope(lp, 0.006, Color(0.7, 0.7, 0.74))
	_sk_end(g)


## Kök reisi ayrıntıları (ref refs/outfits_ss/danzo_outfit.png): sağ kol baştan sona sargılı (gövde kabuğu halkaları), bilekte
## altın halka, mor kuşağın önde sarkan iki ucu
func _kok_reisi_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var ua = absf(_bp("LeftUpperArm").x)
	var ha = absf(_bp("LeftHand").x)
	var wc := Color(0.92, 0.9, 0.86)
	var x = ua + 0.02
	var k = 0
	while x < ha - 0.02:
		_sk_ring(0, -x, 0.016, 0.006, wc if k % 2 == 0 else wc.darkened(0.08), -PI, PI, 24, 0.006 + 0.002 * (k % 2), -1.0)
		x += 0.014
		k += 1
	_sk_ring(0, -(ha - 0.05), 0.012, 0.01, Color(0.92, 0.75, 0.3), -PI, PI, 24, 0.012, -1.0)   # altın halka
	var pc: Color = look["kok_reisi"]
	var h = _sk_hit(-0.06, hips + 0.08, true, 0.04)
	if not h.is_empty():
		var p0: Vector3 = h[0] + Vector3(0, 0, 0.03)
		_sk_box(p0 + Vector3(0, -0.1, 0), Vector3(0.022, 0, 0), Vector3(0.005, 0.1, 0), Vector3(0, 0, 0.005), pc)
		_sk_box(p0 + Vector3(0.03, -0.12, 0.004), Vector3(0.022, 0, 0), Vector3(-0.004, 0.12, 0), Vector3(0, 0, 0.005), pc.darkened(0.06))
	_sk_end(g)


## Delta elbisesi ayrıntıları (ref refs/outfits_ss/delta_outfit.png): balon kolların ucunda geniş beyaz manşet, sırtta pembe
## üçgen implant
func _delta_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hx = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "delta_kol%d" % int(sx), 0.0])
		if km != null and _sk_begin(km):
			_sk_ring(0, (hx - 0.08) * sx, 0.07, 0.008, Color(0.95, 0.95, 0.96), -PI, PI, 28, 0.004, sx)
			_sk_end(g)
	var dm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "delta_elbise", 0.0])
	if dm != null and _sk_begin(dm):
		var h = _sk_hit(0.0, neck - 0.1, false, 0.04)
		if not h.is_empty():
			var c0: Vector3 = h[0] + Vector3(0, 0, -0.006)
			_sk_box(c0, Vector3(0.026, 0, 0), Vector3(0, 0.02, 0), Vector3(0, 0, -0.008), Color(0.95, 0.5, 0.65))
			_sk_box(c0 + Vector3(0, -0.025, 0), Vector3(0.012, 0, 0), Vector3(0, 0.012, 0), Vector3(0, 0, -0.008), Color(0.95, 0.5, 0.65))
		_sk_end(g)


## Göğüs cepleri (ref refs/outfits_ss/denki_outfit_genin_ver.png): gövde kabuğunda iki kapaklı göğüs cebi + düğme
func _chest_pockets_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var chest = _bp("UpperChest").y
	var tc: Color = look.get("top", Color(0.2, 0.35, 0.72))
	for sx in [-1.0, 1.0]:
		_sk_plate(0.075 * sx, chest - 0.06, 0.07, 0.065, 0.004, tc.darkened(0.06), 0.004, true)
		_sk_plate(0.075 * sx, chest - 0.03, 0.074, 0.022, 0.005, tc.darkened(0.16), 0.008, true)
		_sk_plate(0.075 * sx, chest - 0.038, 0.01, 0.01, 0.004, tc.darkened(0.35), 0.013, true)
	_sk_end(g)


## Kabarık bluz ayrıntıları (ref refs/outfits_ss/eida_outfit.png): bileklerde üçer ince mavi bilezik (gövde kabuğu)
func _kabarik_bluz_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ha = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		for k in 3:
			_sk_ring(0, (ha - 0.05 - k * 0.012) * sx, 0.006, 0.006, Color(0.15, 0.55, 0.65), -PI, PI, 24, 0.01 + k * 0.002, sx)
	_sk_end(g)


## Omuzdan sarkan uzun şal (ref refs/outfits_ss/gaara_outfit_young_ver.png): sağ omuzdan öne çapraz inip sol bele sarılan,
## önde dize kadar sarkan kırık beyaz şal — gövde kabuğuna derili kalın bant
func _drape_sash_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var knee = _bp("LeftLowerLeg").y
	var sc: Color = look["drape_sash"]
	var paths = [[Vector2(-0.12, neck - 0.02), Vector2(0.14, hips + 0.08)], [Vector2(0.02, hips + 0.12), Vector2(0.06, knee - 0.02)]]
	for pth in paths:
		var a: Vector2 = pth[0]
		var b: Vector2 = pth[1]
		var pts = []; var outs = []
		for k in 17:
			var q = a.lerp(b, k / 16.0)
			var hit = _sk_hit(q.x, q.y, true, 0.04)
			if not hit.is_empty():
				pts.append(Vector3(q.x, q.y, hit[0].z + 0.012 + 0.006 * sin(k * 1.3))); outs.append(hit[1])
		for it in 2:
			var sm = pts.duplicate()
			for i in range(1, pts.size() - 1):
				sm[i] = Vector3(pts[i].x, pts[i].y, maxf(pts[i].z, (pts[i - 1].z + pts[i + 1].z) * 0.5))
			pts = sm
		if pts.size() > 1:
			var dir = (Vector3(b.x, b.y, 0) - Vector3(a.x, a.y, 0)).normalized()
			_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.085, 0.008, sc)
			_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.012, 0.011, sc.darkened(0.12), false, 0.03)
	_sk_end(g)


## Gi yelek (ref refs/outfits_ss/han_outfit.png): kendi renkli kolsuz yeleğin önünde siyah kruvaze yaka bandı ve bel bağı
func _gi_yelek_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var gm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "gi_yelek", 0.0])
	if gm == null or not _sk_begin(gm):
		return
	var dark := Color(0.1, 0.1, 0.14)
	for sx in [-1.0, 1.0]:
		var a = Vector2(0.075 * sx, neck - 0.02)
		var b = Vector2(0.012 * sx, hips + 0.12)
		var pts = []; var outs = []
		for k in 13:
			var q = a.lerp(b, k / 12.0)
			var hit = _sk_hit(q.x, q.y, true, 0.03)
			if not hit.is_empty():
				pts.append(Vector3(q.x, q.y, hit[0].z + 0.004 + (0.004 if sx < 0.0 else 0.0))); outs.append(hit[1])
		if pts.size() > 1:
			var dir = (Vector3(b.x, b.y, 0) - Vector3(a.x, a.y, 0)).normalized()
			_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.03, 0.005, dark)
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.1
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.1)) < bd:
			bd = absf(q.y - (hips + 0.1)); by = q.y
	_sk_ring(1, by, 0.03, 0.006, dark, -PI, PI, 48, 0.004, 0.0, 0.0, 0.32)
	_sk_end(g)


## Ön fiyonk (ref refs/outfits_ss/hanabi_outfit.png): kuşağın önünde iki kanatlı fiyonk + iki sarkan uç (gövde kabuğu)
func _front_bow_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var bc: Color = look["front_bow"]
	var h = _sk_hit(0.0, hips + 0.14, true, 0.04)
	if not h.is_empty():
		var p0: Vector3 = h[0] + Vector3(0, 0, 0.03)
		for sx in [-1.0, 1.0]:
			_sk_box(p0 + Vector3(0.035 * sx, 0.006, 0), Vector3(0.032, 0.014 * sx, 0), Vector3(-0.008 * sx, 0.024, 0), Vector3(0, 0, 0.01), bc)
			_sk_box(p0 + Vector3(0.016 * sx, -0.045, 0.004), Vector3(0.012, 0, 0), Vector3(0.012 * sx, 0.04, 0), Vector3(0, 0, 0.005), bc.darkened(0.06))
		_sk_box(p0 + Vector3(0, 0, 0.006), Vector3(0.012, 0, 0), Vector3(0, 0.016, 0), Vector3(0, 0, 0.012), bc.darkened(0.12))
	_sk_ring(1, hips + 0.14, 0.03, 0.008, bc, -PI, PI, 48, 0.02, 0.0, 0.0, 0.32)   # kuşak bandı
	_sk_end(g)


## Sırtta büyük parşömen (ref refs/outfits_ss/hashirama_outfit.png): göğüs hizasında sırta yatay bağlı, iki yana taşan dev rulo
func _back_scroll_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var chest = _bp("UpperChest").y
	var h = _sk_hit(0.0, chest - 0.14, false, 0.05)
	if not h.is_empty():
		var c0: Vector3 = h[0] + Vector3(0, 0, -0.1)
		for k in 12:
			var a0 = TAU * k / 12.0
			var d = Vector3(0, cos(a0), sin(a0)) * 0.075
			var tg = Vector3(0, -sin(a0), cos(a0)) * 0.021
			_sk_box(c0 + d, Vector3(0.27, 0, 0), tg, d.normalized() * 0.006, Color(0.94, 0.94, 0.96) if k % 3 != 0 else Color(0.72, 0.68, 0.84))
			for sx in [-1.0, 1.0]:
				_sk_box(c0 + Vector3(0.29 * sx, 0, 0) + d * 1.08, Vector3(0.022, 0, 0), tg * 1.08, d.normalized() * 0.006, Color(0.85, 0.85, 0.88))
		for sx in [-1.0, 1.0]:   # uç kapakları
			_sk_box(c0 + Vector3(0.315 * sx, 0, 0), Vector3(0.006, 0, 0), Vector3(0, 0.05, 0), Vector3(0, 0, 0.05), Color(0.2, 0.2, 0.22))
	_sk_end(g)


## Zırh önlüğü + ip kuşak (ref refs/outfits_ss/hashirama_outfit_young_ver.png): belden dize inen bağcıklı zırh önlüğü, bej ip kuşak
func _armor_apron_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var knee = _bp("LeftLowerLeg").y
	var ac: Color = look["armor_apron"]
	var h = _sk_hit(0.0, hips + 0.04, true, 0.05)
	if not h.is_empty():
		var p0: Vector3 = h[0] + Vector3(0, 0, 0.05)
		var ln = hips + 0.04 - (knee - 0.02)
		_sk_box(p0 + Vector3(0, -ln * 0.5, 0.0), Vector3(0.12, 0, 0), Vector3(0, ln * 0.5, 0), Vector3(0, 0, 0.01), ac)
		for k in 3:   # bağcık çizgileri
			var y = -ln * (0.2 + k * 0.3)
			_sk_box(p0 + Vector3(0, y, 0.012), Vector3(0.07, 0, 0), Vector3(0, 0.003, 0), Vector3(0, 0, 0.002), ac.darkened(0.45))
	_sk_ring(1, hips + 0.06, 0.03, 0.014, Color(0.88, 0.8, 0.6), -PI, PI, 48, 0.07, 0.0, 0.0, 0.34)
	_sk_end(g)


## Uzun açık cübbe ayrıntıları (ref refs/outfits_ss/hiashi_outfit.png): ön kenarlarda koyu yaka bandı
func _uzun_robe_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.1, 0.16, 0.12))
	var rm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "uzun_robe", 0.0])
	if rm == null or not _sk_begin(rm):
		return
	_sk_edge_band(0.04, 0.006, oc.darkened(0.25))
	_sk_end(g)


## Açık önlü giysinin ön kenarı boyunca bant (yaka/pervaz): her yükseklikte o satırın gerçek açılım kenarını izler
## (kesim kalıbında açılım aşağı doğru genişler; sabit x şeridi havada kalıyordu)
func _sk_edge_band(w: float, d: float, col: Color, y_top := 99.0, y_bot := -99.0) -> void:
	var V: PackedVector3Array = _sk["v"]
	var N: PackedVector3Array = _sk["n"]
	var ys := {}
	for i in V.size():
		if V[i].z > 0.0 and V[i].y < y_top and V[i].y > y_bot:
			var ky = int(round(V[i].y / 0.02))
			for sx in [-1, 1]:
				if signf(V[i].x) == sx:
					var key = ky * 2 + (1 if sx > 0 else 0)
					if not ys.has(key) or absf(V[i].x) < absf(V[ys[key]].x):
						ys[key] = i
	for sx in [-1, 1]:
		var keys = []
		for key in ys.keys():
			if (key & 1) == (1 if sx > 0 else 0):
				keys.append(key)
		keys.sort()
		var pts = []; var outs = []
		for key in keys:
			var v = V[ys[key]]
			pts.append(v + N[ys[key]] * 0.003 + Vector3(sx * w * 0.5, 0, 0)); outs.append(N[ys[key]])
		if pts.size() > 1:
			_sk_band(pts, outs, Vector3.RIGHT, w, d, col)


## Bol kapüşonlu ayrıntıları (ref refs/outfits_ss/himawari_outfit.png): büzgü ipleri, önde kanguru cebi, bilekte ribana
func _buyuk_kapusonlu_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.96, 0.82, 0.4))
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "buyuk_kapusonlu", 0.0])
	if km != null and _sk_begin(km):
		for sx in [-1.0, 1.0]:
			_sk_strip(0.03 * sx, neck - 0.02, neck - 0.16, 0.005, 0.004, oc.darkened(0.35), 12)
		_sk_plate(0.0, hips + 0.0, 0.17, 0.09, 0.006, oc.darkened(0.06), 0.006, true)   # kanguru cebi
		_sk_plate(0.0, hips + 0.045, 0.17, 0.008, 0.004, oc.darkened(0.2), 0.012, true)
		_sk_end(g)
	if _sk_begin(_shell_cache.get(look["gender"])):
		var ha = absf(_bp("LeftHand").x)
		for sx in [1.0, -1.0]:
			_sk_ring(0, (ha - 0.065) * sx, 0.04, 0.012, oc.darkened(0.08), -PI, PI, 24, 0.016, sx)
		_sk_end(g)


## Kısa kollu kazak ayrıntıları (ref refs/outfits_ss/hinata_outfit_5.png): kol ağzında ve etekte beyaz şerit, geniş yaka
func _kisa_kollu_kazak_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kisa_kollu_kazak", 0.0])
	var wc := Color(0.97, 0.96, 0.96)
	if km != null and _sk_begin(km):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_ring(1, ybot + 0.02, 0.026, 0.006, wc, -PI, PI, 48, 0.003, 0.0, 0.0, 0.3)
		_sk_ring(1, neck + 0.0, 0.02, 0.008, look.get("outer", wc).darkened(0.1), -PI, PI, 40, 0.006, 0.0, 0.0, 0.14)
		_sk_end(g)
	var kel = absf(_bp("LeftLowerArm").x)
	for sx in [1.0, -1.0]:
		var sm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kazak_kisa_kol%d" % int(sx), 0.0])
		if sm != null and _sk_begin(sm):
			for k in 2:
				_sk_ring(0, (kel - 0.06 - k * 0.022) * sx, 0.007, 0.004, wc, -PI, PI, 24, 0.002, sx)
			_sk_end(g)


## Geniş obi kuşak (ref refs/outfits_ss/hinata_outfit_4.png): belde geniş koyu mor kuşak + yanda sarkan mürdüm bez
func _wide_obi_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var oc: Color = look["wide_obi"]
	_sk_ring(1, hips + 0.12, 0.09, 0.01, oc, -PI, PI, 56, 0.008, 0.0, 0.0, 0.32)
	var h = _sk_hit(0.12, hips + 0.1, true, 0.05)
	if not h.is_empty():
		_sk_box(h[0] + Vector3(0, -0.06, 0.02), Vector3(0.022, 0, 0), Vector3(0.004, 0.06, 0), Vector3(0, 0, 0.006), oc.lightened(0.15))
	_sk_end(g)


## Pembe çizgili uzun etek (ref hinata_outfit_5.png): kendi renkli etek parçasının üstünde ince pembe çizgiler
func _stripe_skirt_kit(g: Dictionary) -> void:
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "cizgili_uzun_etek", 0.0])
	if em == null or not _sk_begin(em):
		return
	var V: PackedVector3Array = _sk["v"]
	var ybot = 9.0; var ytop = -9.0
	for q in V:
		ybot = minf(ybot, q.y); ytop = maxf(ytop, q.y)
	for f in [0.06, 0.2, 0.55]:
		var y = lerpf(ybot, ytop, f)
		var by = y
		var bd = 9.0
		for q in V:
			if absf(q.y - y) < bd:
				bd = absf(q.y - y); by = q.y
		_sk_ring(1, by, 0.006, 0.003, Color(0.88, 0.5, 0.62), -PI, PI, 56, 0.002, 0.0, 0.0, 0.5)
	_sk_end(g)


## Gelinlik ayrıntıları (ref refs/outfits_ss/all/hinata_outfit_bridal_ver): belde fırfırlı bant, önde koyu pli şeritler
func _gelinlik_kit(g: Dictionary) -> void:
	var oc: Color = look.get("outer", Color(0.14, 0.1, 0.18))
	var hips = _bp("Hips").y
	var ank = _bp("LeftFoot").y
	var gm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "gelinlik", 0.0])
	if gm == null or not _sk_begin(gm):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.12
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.12)) < bd:
			bd = absf(q.y - (hips + 0.12)); by = q.y
	for k in 3:   # fırfır bant: üst üste üç kat kıvrımlı halka
		_sk_ring(1, by - k * 0.02, 0.022, 0.008 + k * 0.003, oc.darkened(0.08 * k), -PI, PI, 64, 0.006 + k * 0.006, 0.0, 0.0, 0.34)
	for k in 5:   # önde koyu pli şeritler
		var x = -0.04 + k * 0.02
		_sk_strip(x, by - 0.06, ank + 0.06, 0.012, 0.004 + 0.002 * (k % 2), oc.lightened(0.12) if k % 2 == 0 else oc.darkened(0.2), 40)
	_sk_end(g)


## Hiruzen aksesuarları (ref hiruzen_outfit): iki omuzda gri omuzluk, sağ ön kolda bağlı zırhlı kolluk
func _hiruzen_aks_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var ua = absf(_bp("LeftUpperArm").x)
	var el = absf(_bp("LeftLowerArm").x)
	var ha = absf(_bp("LeftHand").x)
	var pc: Color = look["hiruzen_aks"]
	var V: PackedVector3Array = _sk["v"]
	for sx in [1.0, -1.0]:
		var ax = ua * 1.02
		var top = Vector3.ZERO; var by = -9.0
		for q in V:
			if signf(q.x) == sx and absf(absf(q.x) - ax) < 0.02 and absf(q.z) < 0.05 and q.y > by:
				by = q.y; top = q
		if by > -8.0:
			_sk_box(top + Vector3(0, 0.012, 0), Vector3(0.05, 0, 0), Vector3(0, 0.008, 0), Vector3(0, 0, 0.07), pc)
	for k in 5:   # sağ (−x) ön kolda kolluk
		var x = -lerpf(el + 0.02, ha - 0.06, k / 4.0)
		_sk_ring(0, x, 0.03, 0.012, Color(0.5, 0.56, 0.52) if k % 2 == 0 else Color(0.38, 0.42, 0.4), -PI, PI, 24, 0.012, -1.0)
	_sk_end(g)


## Karın ve uyluk bandajları (ref ino_outfit_young_ver): gövdede ve iki uylukta beyaz sargı halkaları
func _belly_wraps_kit(g: Dictionary) -> void:
	if not _sk_begin(_shell_cache.get(look["gender"])):
		return
	var hips = _bp("Hips").y
	var chest = _bp("UpperChest").y
	var knee = _bp("LeftLowerLeg").y
	var wc: Color = look["belly_wraps"]
	var y = chest - 0.16
	var k = 0
	while y > hips + 0.08:
		_sk_ring(1, y, 0.012, 0.005, wc if k % 2 == 0 else wc.darkened(0.06), -PI, PI, 48, 0.004, 0.0, 0.0, 0.25)
		y -= 0.014
		k += 1
	_sk_end(g)


## Kısa ceket ayrıntıları (ref inojin_outfit): omuzlardan inen kırmızı kayış bantları, fermuar
func _inojin_ceket_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var jm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "inojin_ceket", 0.0])
	if jm == null or not _sk_begin(jm):
		return
	var V: PackedVector3Array = _sk["v"]
	var ybot = 9.0
	for q in V:
		ybot = minf(ybot, q.y)
	for sx in [-1.0, 1.0]:
		_sk_strip(0.075 * sx, neck - 0.0, neck - 0.14, 0.022, 0.006, Color(0.65, 0.16, 0.18), 12)
	_sk_strip(0.0, neck + 0.02, ybot + 0.01, 0.006, 0.004, Color(0.7, 0.7, 0.74), 16)
	_sk_ring(1, neck + 0.01, 0.05, 0.008, look.get("outer", Color(0.1, 0.1, 0.12)), 0.2, TAU - 0.2, 40, 0.006, 0.0, 0.0, 0.12)
	_sk_end(g)


## Isshiki paltosu ayrıntıları (ref all/isshiki_outfit): ön kenarlarda kırmızı biye, kol ağzında kırmızı manşet, çıplak göğüste
## boyundan inen siyah tomoe dizisi (gövde kabuğu)
func _isshiki_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var pm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "isshiki_palto", 0.0])
	var red := Color(0.62, 0.08, 0.14)
	if pm != null and _sk_begin(pm):
		_sk_edge_band(0.022, 0.006, red)
		_sk_end(g)
	var hx = absf(_bp("LeftHand").x)
	for sx in [1.0, -1.0]:
		var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "isshiki_kol%d" % int(sx), 0.0])
		if km != null and _sk_begin(km):
			_sk_ring(0, (hx - 0.07) * sx, 0.04, 0.006, red, -PI, PI, 28, 0.002, sx)
			_sk_end(g)
	if _sk_begin(_shell_cache.get(look["gender"])):
		for k in 6:
			var h = _sk_hit(0.0, neck - 0.06 - k * 0.05, true, 0.03)
			if h.is_empty():
				continue
			var c0: Vector3 = h[0] + Vector3(0, 0, 0.002)
			for j in 8:
				var a0 = TAU * j / 8.0
				_sk_box(c0 + Vector3(cos(a0), sin(a0), 0) * 0.008, Vector3(0.006, 0, 0), Vector3(0, 0.006, 0), Vector3(0, 0, 0.002), Color(0.05, 0.05, 0.06))
		_sk_end(g)


## Tunik kuşağı (ref all/itachi_outfit): tuniğin belinde beyaz kuşak
func _itachi_tunik_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var tm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "itachi_tunik", 0.0])
	if tm == null or not _sk_begin(tm):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.08
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.08)) < bd:
			bd = absf(q.y - (hips + 0.08)); by = q.y
	_sk_ring(1, by, 0.022, 0.006, look.get("tunic_belt", Color(0.92, 0.92, 0.94)), -PI, PI, 48, 0.003, 0.0, 0.0, 0.32)
	_sk_end(g)


## Edo cübbesi ayrıntıları (ref all/itachi_outfit_reanimation_ver): ortada fermuar
func _edo_cubbe_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var cm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "edo_cubbe", 0.0])
	if cm == null or not _sk_begin(cm):
		return
	var V: PackedVector3Array = _sk["v"]
	var ybot = 9.0
	for q in V:
		ybot = minf(ybot, q.y)
	_sk_strip(0.0, neck - 0.04, ybot + 0.12, 0.007, 0.004, Color(0.75, 0.72, 0.6), 44)
	_sk_end(g)


## Yuvarlak rozet: yüzeye yaslı, üç döndürülmüş kare (12 köşeli disk)
func _sk_disc(c: Vector3, n: Vector3, r: float, d: float, col: Color) -> void:
	var u0 = Vector3.UP.cross(n).normalized()
	var v0 = n.cross(u0).normalized()
	for j in 3:
		var a = j * PI / 6.0
		var u = u0 * cos(a) + v0 * sin(a)
		var v = -u0 * sin(a) + v0 * cos(a)
		_sk_box(c + n * d * 0.5, u * r * 0.82, v * r * 0.82, n * d * 0.5, col)


## Jigen cübbesi ayrıntıları (ref all/jigen_outfit): etek ucunda ve kol ağzında dikey siyah şeritler, belde kırmızı kuşak + halka + püskül
func _jigen_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var sc: Color = look.get("outer2", Color(0.08, 0.08, 0.1))
	var cm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "jigen_cubbe", 0.0])
	if cm != null and _sk_begin(cm):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		for k in 22:
			var a = -PI + (k + 0.5) * TAU / 22.0
			_sk_ring(1, ybot + 0.09, 0.15, 0.004, sc, a - 0.06, a + 0.06, 3, 0.003)
		var by = hips + 0.13
		var bd = 9.0
		for q in V:
			if absf(q.y - (hips + 0.13)) < bd:
				bd = absf(q.y - (hips + 0.13)); by = q.y
		_sk_ring(1, by, 0.06, 0.008, Color(0.62, 0.1, 0.12), -PI, PI, 56, 0.004)
		var h = _sk_hit(0.0, by, true, 0.04)
		if not h.is_empty():
			var c0: Vector3 = h[0] + Vector3(0, 0, 0.014)
			for j in 10:
				var a0 = TAU * j / 10.0
				_sk_box(c0 + Vector3(cos(a0), sin(a0), 0) * 0.024, Vector3(0.008, 0, 0), Vector3(0, 0.008, 0), Vector3(0, 0, 0.004), Color(0.92, 0.9, 0.86))
			_sk_box(c0 + Vector3(0, -0.13, 0.002), Vector3(0.02, 0, 0), Vector3(0, 0.1, 0), Vector3(0, 0, 0.005), Color(0.92, 0.9, 0.86))
		_sk_end(g)
	for sx in [1.0, -1.0]:
		var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "jigen_kol%d" % int(sx), 0.0])
		if km != null and _sk_begin(km):
			var V2: PackedVector3Array = _sk["v"]
			var xm = 0.0
			for q in V2:
				if signf(q.x) == sx:
					xm = maxf(xm, absf(q.x))
			for k in 10:
				var a = -PI + (k + 0.5) * TAU / 10.0
				_sk_ring(0, (xm - 0.035) * sx, 0.05, 0.004, sc, a - 0.12, a + 0.12, 3, 0.003, sx)
			_sk_end(g)


## Sennin yeleği (ref all/jiraiya_outfit): göğüste iki sarı yuvarlak
func _sennin_yelek_kit(g: Dictionary) -> void:
	var chest = _bp("UpperChest").y
	var vm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "sennin_yelek", 0.0])
	if vm == null or not _sk_begin(vm):
		return
	for sx in [1.0, -1.0]:
		var h = _sk_hit(0.1 * sx, _bp("Neck").y - 0.13, true, 0.03)
		if not h.is_empty():
			_sk_disc(h[0], (h[1] as Vector3).normalized(), 0.04, 0.005, look.get("outer2", Color(0.95, 0.8, 0.25)))
	_sk_end(g)


## Kaguya kimonosu (ref all/kaguya_outfit): etek ucunda sarı+mor biye, çapraz sarı-mor kuşak, önde siyah düğmeler, kol ağzında siyah-sarı-mor bant
func _kaguya_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var yel := Color(0.85, 0.7, 0.2)
	var pur := Color(0.3, 0.12, 0.45)
	var blk := Color(0.06, 0.06, 0.08)
	var km = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kaguya_kimono", 0.0])
	if km != null and _sk_begin(km):
		var V: PackedVector3Array = _sk["v"]
		var ybot = 9.0
		for q in V:
			ybot = minf(ybot, q.y)
		_sk_ring(1, ybot + 0.025, 0.04, 0.006, pur, -PI, PI, 72, 0.003)
		_sk_ring(1, ybot + 0.075, 0.05, 0.006, yel, -PI, PI, 72, 0.003)
		var p0 = Vector2(-0.06, neck - 0.02)
		var p1 = Vector2(0.15, hips + 0.1)
		var dir2 = (p1 - p0).normalized()
		var steps = 48
		for i in steps + 1:
			var p = p0.lerp(p1, float(i) / steps)
			var h = _sk_hit(p.x, p.y, true, 0.025)
			if h.is_empty():
				continue
			var n: Vector3 = (h[1] as Vector3).normalized()
			var dv = Vector3(dir2.x, dir2.y, 0)
			dv = (dv - n * dv.dot(n)).normalized()
			var w = n.cross(dv).normalized()
			var ln = (p1 - p0).length() / steps * 0.7
			var c3 = Vector3(p.x, p.y, (h[0] as Vector3).z)
			_sk_box(c3 + n * 0.006, dv * ln, w * 0.04, n * 0.004, pur)
			_sk_box(c3 + n * 0.011, dv * ln, w * 0.026, n * 0.003, yel)
		for k in 6:
			var hb = _sk_hit(0.0, neck - 0.2 - k * 0.075, true, 0.03)
			if not hb.is_empty():
				_sk_disc(hb[0], (hb[1] as Vector3).normalized(), 0.013, 0.008, blk)
		_sk_end(g)
	for sx in [1.0, -1.0]:
		var sm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kaguya_kol%d" % int(sx), 0.0])
		if sm != null and _sk_begin(sm):
			var V2: PackedVector3Array = _sk["v"]
			var xm = 0.0
			for q in V2:
				if signf(q.x) == sx:
					xm = maxf(xm, absf(q.x))
			_sk_ring(0, (xm - 0.012) * sx, 0.022, 0.006, pur, -PI, PI, 36, 0.003, sx)
			_sk_ring(0, (xm - 0.04) * sx, 0.03, 0.006, yel, -PI, PI, 36, 0.003, sx)
			_sk_ring(0, (xm - 0.085) * sx, 0.06, 0.005, blk, -PI, PI, 36, 0.002, sx)
			_sk_end(g)


## Kawaki kolsuz paltoları (ref all/kawaki_outfit*): açılım kenarında açık renk yaka/pervaz bandı
func _kawaki_kit(g: Dictionary, key: String) -> void:
	var hips = _bp("Hips").y
	var neck = _bp("Neck").y
	var pm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], key, 0.0])
	if pm == null or not _sk_begin(pm):
		return
	_sk_edge_band(0.045 if key != "kawaki_ruro" else 0.02, 0.006, look.get("outer2", Color(0.5, 0.65, 0.85)), neck + 0.1, hips - 0.02 if key == "kawaki_palto" else -99.0)
	_sk_end(g)


## Altıncı Hokage cübbesi (ref all/kakashi_outfit_sixth_hokage_vers): önde sağa kayık dikey pervaz çizgisi
func _rokudaime_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var cm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "rokudaime_cubbe", 0.0])
	if cm == null or not _sk_begin(cm):
		return
	var V: PackedVector3Array = _sk["v"]
	var ybot = 9.0
	for q in V:
		ybot = minf(ybot, q.y)
	_sk_strip(-0.07, neck - 0.12, ybot + 0.02, 0.006, 0.003, (look.get("outer", Color(0.9, 0.9, 0.9)) as Color).darkened(0.25), 44)
	_sk_end(g)


## Kukla ustası önlüğü (ref all/kankuro_outfit): belde kırmızı kuşak, göğüste sırt çantasının beyaz omuz kayışları
func _kukla_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var neck = _bp("Neck").y
	var om = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kukla_onluk", 0.0])
	if om != null and _sk_begin(om):
		var V: PackedVector3Array = _sk["v"]
		var ytop = -9.0
		for q in V:
			ytop = maxf(ytop, q.y)
		var by = ytop
		_sk_ring(1, by, 0.04, 0.008, look.get("outer2", Color(0.55, 0.1, 0.16)), -PI, PI, 56, 0.004)
		_sk_end(g)
	if _sk_begin(_shell_cache.get(look["gender"])):
		for sx in [1.0, -1.0]:
			_sk_strip(0.125 * sx, neck + 0.0, neck - 0.26, 0.04, 0.008, Color(0.92, 0.92, 0.9), 16)
		_sk_end(g)


## Kaguya beyaz cübbesi (ref all/kaguya_outfit_2): önde iki yanda yere inen ince siyah çizgiler
func _kaguya_cubbe_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var cm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "kaguya_cubbe", 0.0])
	if cm == null or not _sk_begin(cm):
		return
	var V: PackedVector3Array = _sk["v"]
	var ybot = 9.0
	for q in V:
		ybot = minf(ybot, q.y)
	for sx in [1.0, -1.0]:
		for k in 2:
			_sk_strip((0.1 + k * 0.05) * sx, neck - 0.08, ybot + 0.03, 0.005, 0.003, Color(0.08, 0.08, 0.1), 44)
	_sk_end(g)


## Haku yukatası (ref all/haku_outfit_first_encounter_vers): beyaz obi, önde çapraz kırmızı yaka şeridi, girdap benekleri
func _haku_yukata_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var ym = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "haku_yukata", 0.0])
	if ym == null or not _sk_begin(ym):
		return
	var V: PackedVector3Array = _sk["v"]
	var ybot = 9.0
	for q in V:
		ybot = minf(ybot, q.y)
	var by = hips + 0.12
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.12)) < bd:
			bd = absf(q.y - (hips + 0.12)); by = q.y
	var rc: Color = look.get("outer2", Color(0.85, 0.35, 0.35))
	var steps = 40
	for i in steps + 1:
		var t = float(i) / steps
		var y = lerpf(neck - 0.02, ybot + 0.02, t)
		var x = lerpf(0.05, -0.05, minf(1.0, t * 2.2)) if y > by else -0.05
		var h = _sk_hit(x, y, true, 0.03)
		if h.is_empty():
			continue
		var n: Vector3 = (h[1] as Vector3).normalized()
		_sk_box(Vector3(x, y, (h[0] as Vector3).z) + n * 0.005, Vector3(0.018, 0, 0), Vector3(0, (neck - ybot) / steps * 0.7, 0), n * 0.003, rc)
	_sk_ring(1, by, 0.1, 0.008, Color(0.9, 0.9, 0.86), -PI, PI, 56, 0.006)
	var dots = [[0.1, 0.5], [-0.12, 0.62], [0.06, 0.8], [-0.1, 0.9], [0.13, 0.95], [0.0, 0.7]]
	for d in dots:
		for fr in [true, false]:
			var y2 = lerpf(by, ybot, d[1])
			var h2 = _sk_hit(d[0], y2, fr, 0.03)
			if not h2.is_empty():
				_sk_disc(h2[0], (h2[1] as Vector3).normalized(), 0.018, 0.004, Color(0.12, 0.08, 0.1))
	_sk_end(g)


## Savaş cübbesi (ref all/madara_outfit*): istenirse belde geniş obi (robe_obi), yüksek dik yaka
func _savas_cubbe_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var cm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "savas_cubbe", 0.0])
	if cm == null or not _sk_begin(cm):
		return
	var V: PackedVector3Array = _sk["v"]
	if look.get("robe_obi") is Color:
		var by = hips + 0.12
		var bd = 9.0
		for q in V:
			if absf(q.y - (hips + 0.12)) < bd:
				bd = absf(q.y - (hips + 0.12)); by = q.y
		_sk_ring(1, by, 0.11, 0.008, look["robe_obi"], -PI, PI, 56, 0.006)
		_sk_ring(1, by, 0.025, 0.006, (look["robe_obi"] as Color).darkened(0.3), -PI, PI, 56, 0.014)
	if look.get("robe_stripe") is Color:
		var yb = 9.0
		for q in V:
			yb = minf(yb, q.y)
		_sk_strip(-0.035, _bp("Neck").y - 0.02, yb + 0.02, 0.008, 0.004, look["robe_stripe"], 44)
	_sk_end(g)


## Mei elbisesi (ref all/mei_outfit): belde açık sarı ince kemer
func _mei_elbise_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "mei_elbise", 0.0])
	if em == null or not _sk_begin(em):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.14
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.14)) < bd:
			bd = absf(q.y - (hips + 0.14)); by = q.y
	_sk_ring(1, by, 0.022, 0.006, Color(0.9, 0.85, 0.6), -PI, PI, 56, 0.004)
	_sk_end(g)


## Bele bağlı ceket (ref all/naruto_outfit_prankster_ver): önde düğümlenip sarkan iki kol
func _bel_ceket_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var bm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "bel_ceket", 0.0])
	if bm == null or not _sk_begin(bm):
		return
	var oc: Color = look.get("outer", Color(0.95, 0.5, 0.2))
	var zf = -9.0
	for q in (_sk["v"] as PackedVector3Array):
		if absf(q.y - (hips + 0.04)) < 0.04:
			zf = maxf(zf, q.z)
	if zf > -8.0:
		var c0 := Vector3(0.0, hips + 0.04, zf + 0.01)
		_sk_box(c0, Vector3(0.045, 0, 0), Vector3(0, 0.03, 0), Vector3(0, 0, 0.022), oc.darkened(0.1))
		for sx in [1.0, -1.0]:
			_sk_box(c0 + Vector3(0.03 * sx, -0.16, -0.005), Vector3(0.028, 0, 0), Vector3(0, 0.15, 0), Vector3(0, 0, 0.018), oc)
			_sk_box(c0 + Vector3(0.03 * sx, -0.31, -0.005), Vector3(0.03, 0, 0), Vector3(0, 0.02, 0), Vector3(0, 0, 0.02), Color(0.16, 0.24, 0.5))
	_sk_end(g)


## Çin elbisesi (ref all/sakura_outfit_young_ver): önde altta beyaz halka, etek ve yırtmaç kenarında beyaz biye
func _cin_elbise_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "cin_elbise", 0.0])
	if em == null or not _sk_begin(em):
		return
	var V: PackedVector3Array = _sk["v"]
	var ybot = 9.0
	for q in V:
		ybot = minf(ybot, q.y)
	_sk_ring(1, ybot + 0.012, 0.022, 0.005, Color(0.95, 0.95, 0.93), -PI, PI, 64, 0.003)
	var cy = lerpf(hips, ybot, 0.62)
	for k in 24:
		var a = TAU * k / 24.0
		var p = Vector2(0.075 * cos(a), cy + 0.075 * sin(a))
		var h = _sk_hit(p.x, p.y, true, 0.03)
		if h.is_empty():
			continue
		var n: Vector3 = (h[1] as Vector3).normalized()
		var tg = Vector3(-sin(a), cos(a), 0)
		tg = (tg - n * tg.dot(n)).normalized()
		_sk_box(Vector3(p.x, p.y, (h[0] as Vector3).z) + n * 0.005, tg * 0.012, n.cross(tg).normalized() * 0.009, n * 0.003, Color(0.96, 0.96, 0.94))
	_sk_end(g)


## Sarada mini elbisesi (ref all/sarada_outfit_2): belde sarkan beyaz kemer, V yakada sarı iç
func _sarada_elbise_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var neck = _bp("Neck").y
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "sarada_elbise", 0.0])
	if em == null or not _sk_begin(em):
		return
	var V: PackedVector3Array = _sk["v"]
	var by = hips + 0.02
	var bd = 9.0
	for q in V:
		if absf(q.y - (hips + 0.02)) < bd:
			bd = absf(q.y - (hips + 0.02)); by = q.y
	if look.get("robe_obi") is Color:
		var oy = hips + 0.12
		var od = 9.0
		for q in V:
			if absf(q.y - (hips + 0.12)) < od:
				od = absf(q.y - (hips + 0.12)); oy = q.y
		_sk_ring(1, oy, 0.1, 0.008, look["robe_obi"], -PI, PI, 56, 0.005)
		_sk_end(g)
		return
	_sk_ring(1, by, 0.022, 0.006, Color(0.92, 0.92, 0.94), -PI, PI, 56, 0.004)
	var h = _sk_hit(0.02, by - 0.05, true, 0.04)
	if not h.is_empty():
		_sk_box(Vector3(0.02, by - 0.06, (h[0] as Vector3).z + 0.008), Vector3(0.01, 0, 0), Vector3(0, 0.05, 0), Vector3(0, 0, 0.003), Color(0.92, 0.92, 0.94))
	_sk_end(g)


## Yagura takımı ayrıntıları (ref all/yagura_outfit): belde sarkan iki uçlu turkuaz kuşak; göğüste çapraz koyu kayış + fiyonk, ortada gri plaka
func _yagura_kit(g: Dictionary) -> void:
	var hips = _bp("Hips").y
	var neck = _bp("Neck").y
	var sash: Color = look.get("sash", Color(0.2, 0.5, 0.42))
	var em = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "yagura_etek", 0.0])
	if em != null and _sk_begin(em):
		var V: PackedVector3Array = _sk["v"]
		var ytop = -9.0
		for q in V:
			ytop = maxf(ytop, q.y)
		_sk_ring(1, ytop, 0.06, 0.009, sash, -PI, PI, 56, 0.006)
		var zf = -9.0
		for q in V:
			if absf(q.y - ytop) < 0.03 and q.x < 0.0:
				zf = maxf(zf, q.z)
		if zf > -8.0:
			var c0 := Vector3(-0.06, ytop - 0.01, zf + 0.012)
			_sk_box(c0, Vector3(0.03, 0, 0), Vector3(0, 0.025, 0), Vector3(0, 0, 0.012), sash.darkened(0.15))
			for k in 2:
				var x = -0.04 - k * 0.035
				var ln = 0.3 + k * 0.08
				_sk_box(Vector3(x, ytop - 0.03 - ln * 0.5, zf + 0.016), Vector3(0.016, 0, 0), Vector3(0, ln * 0.5, 0), Vector3(0, 0, 0.004), sash)
		_sk_end(g)
	if _sk_begin(_shell_cache.get(look["gender"])):
		var p0 = Vector2(0.12, neck - 0.03)
		var p1 = Vector2(-0.13, hips + 0.12)
		var steps = 30
		var dir2 = (p1 - p0).normalized()
		for i in steps + 1:
			var p = p0.lerp(p1, float(i) / steps)
			var h = _sk_hit(p.x, p.y, true, 0.025)
			if h.is_empty():
				continue
			var n: Vector3 = (h[1] as Vector3).normalized()
			var dv = Vector3(dir2.x, dir2.y, 0)
			dv = (dv - n * dv.dot(n)).normalized()
			_sk_box(Vector3(p.x, p.y, (h[0] as Vector3).z) + n * 0.004, dv * ((p1 - p0).length() / steps * 0.7), n.cross(dv).normalized() * 0.014, n * 0.003, Color(0.12, 0.12, 0.16))
		var hb = _sk_hit(0.06, neck - 0.13, true, 0.03)
		if not hb.is_empty():
			for sx in [1.0, -1.0]:
				_sk_box(Vector3(0.06 + 0.018 * sx, neck - 0.13, (hb[0] as Vector3).z + 0.007), Vector3(0.016, 0, 0), Vector3(0, 0.01, 0), Vector3(0, 0, 0.004), Color(0.85, 0.85, 0.88))
		var hp = _sk_hit(0.0, neck - 0.2, true, 0.03)
		if not hp.is_empty():
			_sk_box(Vector3(0.0, neck - 0.2, (hp[0] as Vector3).z + 0.006), Vector3(0.06, 0, 0), Vector3(0, 0.02, 0), Vector3(0, 0, 0.004), Color(0.62, 0.62, 0.66))
		var hx = absf(_bp("LeftHand").x)
		_sk_ring(0, hx - 0.08, 0.055, 0.012, Color(0.1, 0.1, 0.12), -PI, PI, 24, 0.01, 1.0)
		_sk_end(g)
	var cm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "yagura_basalti", 0.0])
	if cm != null and _sk_begin(cm):
		var V2: PackedVector3Array = _sk["v"]
		var ys = []
		for q in V2:
			var yy = snappedf(q.y, 0.001)
			if not ys.has(yy):
				ys.append(yy)
		ys.sort()
		var oc: Color = look.get("outer", Color(0.36, 0.42, 0.2))
		for k in [int(ys.size() * 0.35), int(ys.size() * 0.7)]:
			_sk_ring(1, ys[k], 0.018, 0.006, oc.darkened(0.1), -PI, PI, 48, 0.003)
		_sk_end(g)


## ANBU beyaz paltosu (ref all/anbu_outfit_coat_ver): önden boydan inen dikiş/fermuar çizgisi
func _anbu_palto_kit(g: Dictionary) -> void:
	var neck = _bp("Neck").y
	var pm = _garment_cache.get("%s|%s|%.3f" % [look["gender"], "anbu_palto", 0.0])
	if pm == null or not _sk_begin(pm):
		return
	var V: PackedVector3Array = _sk["v"]
	var yb = 9.0
	for q in V:
		yb = minf(yb, q.y)
	_sk_strip(0.0, neck - 0.05, yb + 0.01, 0.004, 0.003, (look.get("outer", Color(0.85, 0.82, 0.74)) as Color).darkened(0.3), 44)
	_sk_end(g)


## Görünümdeki giysi katmanlarını kur
func _garments(g: Dictionary) -> void:
	_layer_meshes = []
	OutfitParts.pants_layers(self, g)
	var neck = _bp("Neck").y; var hips = _bp("Hips").y; var knee = _bp("LeftLowerLeg").y; var ank = _bp("LeftFoot").y
	var chest = _bp("UpperChest").y; var ua = _bp("LeftUpperArm").x; var ha = _bp("LeftHand").x
	# göz yüksekliği model uzayında (VRoid yüz parçasının iris merkezi); göz mesh'inin AABB'si yerel uzayda, kullanma
	var ey = eye_center_model.y if face_mi else neck + 0.17
	var torso = func(p: Vector3) -> bool: return absf(p.x) < (ua * 0.95 if p.y > neck - 0.33 else absf(ua) * 1.25) and p.y < neck + 0.06   # bel altında eller (dinlenme pozu) giysiye girmesin
	var front_gap = func(w: float, from_t: float) -> Callable:
		return func(t: float, ang: float) -> bool: return t > from_t and absf(wrapf(ang - PI * 0.5, -PI, PI)) < w
	var flat = func(o: float) -> Callable:
		return func(_t: float, _a: float) -> float: return o
	# yelek giyiliyse dış giysi (palto, pelerin, haori...) yeleğin kabuğunun dışına alınır: yelek dışarı taşmasın
	# iç katmanlar (obi, etek, hakama, geniş kollar) dış giysiden ÖNCE: kesim kalıbı (_cut_loft) bunların dışında durur
	if top_style() == "kimono":
		_garment("obi", func(): return _loft(g, 1, hips + 0.03, hips + 0.15, 5, torso, flat.call(0.03), 2))
	var sk = int(look.get("skirt", 0))
	if sk > 0 and not look.get("hakama", false):
		# etek (Striker kunoichi kıyafetleri): belden 1 mini (uyluk ortası), 2 diz, 3 uzun (bilek); A kesim, bacakların ortak kesitinden
		var sy1 = [0.0, hips - (hips - knee) * 0.45, knee - 0.02, ank + 0.08][sk]
		var fl = [0.0, 0.045, 0.06, 0.08][sk]
		_garment("etek_%d" % sk, func(): return _loft(g, 1, hips + 0.05, sy1, 12 + sk * 4, torso, func(t, _a): return 0.022 + t * fl, 3, null, hips - 0.1, 26))
	if look.get("hakama", false) and look.get("hakama_cut") == "genis":
		# geniş paçalı antrenman hakaması (Striker Training Clothes): yüksek bel (obiyi örter), apış altında iki ayrı bol paça, baldır ortası
		_garment("hakama_ust", func(): return _loft(g, 1, hips + 0.17, hips - 0.1, 10, torso, func(t, _a): return 0.034 + t * 0.03, 3, null, -99.0, 32))
		for sx in [-1.0, 1.0]:
			var kx = _bp(("Left" if sx > 0.0 else "Right") + "LowerLeg").x
			_garment("hakama_paca%d" % int(sx), func(): return _loft(g, 1, hips - 0.06, ank + 0.15, 16, func(p): return signf(p.x) == sx and absf(p.x - kx) < 0.1,
				func(t, a): return (0.032 + t * 0.07) * (1.0 if cos(a) * sx > -0.4 else 0.3), 3, null, -99.0, 24))
	elif look.get("hakama", false):
		# hakama: belden bileğe geniş, pilili etek-pantolon (bacakların ortak kesitinden)
		_garment("hakama", func(): return _loft(g, 1, hips + 0.06, ank + 0.06, 22, torso, func(t, _a): return 0.03 + t * 0.06, 3, null, hips - 0.12, 28))
	if look.get("petal_skirt") is Dictionary:
		# iki katlı yaprak etek (Striker Himawari): üst kat açık mavi sivri dişli, alt kat pembe-kırmızı fırfır
		var pk: Dictionary = look["petal_skirt"]
		_garment_tinted("yaprak_etek_alt", pk.get("b", Color(0.95, 0.55, 0.62)), func(): return _loft(g, 1, hips + 0.02, hips - 0.21, 10, torso, func(t, a): return 0.03 + t * 0.07 + 0.01 * absf(sin(a * 6.0)) * t, 10, null, hips - 0.06, 48))
		_garment_tinted("yaprak_etek_ust", pk.get("a", Color(0.75, 0.88, 0.95)), func(): return _loft(g, 1, hips + 0.04, hips - 0.08, 6, torso, func(t, _a): return 0.04 + t * 0.06, 10, func(t, ang): return t > 0.5 and fposmod(ang * 4.0, 1.0) < (t - 0.5) * 1.6, hips - 0.06, 48))
	if look.get("long_skirt") is Color:
		# A kesim uzun etek (Striker Hinata 5): belden baldır ortasına; altındaki pantolon paçası görünür
		_garment_tinted("cizgili_uzun_etek", look["long_skirt"], func(): return _cut_spec(g, hips + 0.06, knee - 0.06, 18, {"w": [[0.0, 0.86], [1.0, 1.75]], "d": [[0.0, 0.12], [1.0, 0.27]], "n": 2.4}, 10, hips - 0.08, 0.035))   # KESİM: hinata_outfit_5 — çok geniş A etek
	if look.get("pleat_skirt", false):
		# yüksek belli pilili kısa etek (Striker WTNY): göğüs altından uyluk ortasına; kat kat pli (açıya göre zikzak kalınlık)
		_garment("pilili_etek", func(): return _loft(g, 1, hips + 0.15, hips - 0.21, 14, torso, func(t, a): return 0.03 + t * 0.09 + 0.012 * t * absf(sin(a * 12.0)), 3, null, hips - 0.08, 72))
	if look.get("wide_sleeve_long", false):
		# uzun geniş kimono kolu: omuzdan bileğe, ağzı çok geniş sarkan kol (üst renginde)
		for sx in [1.0, -1.0]:
			var whx = absf(_bp("LeftHand").x)
			_garment("genis_uzun_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) * 0.86) * sx, (whx - 0.05) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.84 and absf(p.x) < whx - 0.03, func(t, _a): return 0.026 + t * 0.075, 1, null, -99.0, 24))
	if look.get("wide_sleeve", false):
		# geniş kısa kimono kolu: omuzdan dirseğin biraz altına, ağzı açılan bol kol (gi kolunun dışında)
		for sx in [1.0, -1.0]:
			var el = absf(_bp("LeftLowerArm").x)
			_garment("genis_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) + 0.02) * sx, (el + 0.08) * sx, 9, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) and absf(p.x) < el + 0.1, func(t, _a): return 0.022 + t * 0.035, 1, null, -99.0, 24))
	_outer_pad = 0.02 if look.get("vest") != null and look.get("outer_style") != null else 0.0
	match look.get("outer_style"):
		"palto":
			_garment("palto", func(): return _cut_spec(g, neck - 0.01, knee + 0.02, 26, {"w": [[0.0, 0.84], [0.1, 1.0], [1.0, 1.16]], "d": [[0.0, 0.115], [1.0, 0.15]], "o": [[0.0, 0.0], [0.12, 0.0], [0.2, 0.2], [1.0, 0.28]], "n": 3.0}, 8, hips - 0.05, 0.035))   # KESİM: düz uzun palto, önde açık
		"pelerin":
			_garment("pelerin", func(): return _loft(g, 1, neck + 0.02, knee - 0.06, 22, torso, func(t, _a): return 0.06 + t * 0.1, 8, null, hips - 0.06))
		"haori":
			_garment("haori", func(): return _cut_spec(g, neck - 0.01, hips - 0.16, 18, {"w": [[0.0, 0.86], [0.1, 1.06], [1.0, 1.12]], "d": [[0.0, 0.12], [1.0, 0.14]], "o": [[0.0, 0.26], [1.0, 0.3]], "n": 3.4}, 8, hips - 0.05, 0.035))   # KESİM: kutu haori, önü açık
		"kisa":
			_garment("kisa", func(): return _loft(g, 1, neck - 0.03, chest - 0.3, 12, torso, func(t, _a): return 0.05 + t * 0.07, 8, func(_t, ang): return absf(wrapf(ang - PI * 0.5, -PI, PI)) < 1.7))
			_garment("atki", func(): return _loft(g, 1, neck - 0.06, neck + 0.04, 5, func(p): return absf(p.x) < 0.16, flat.call(0.03), 8))
		"atki":
			# yelek varsa atkı yeleğin yakasının dışında kalsın (Killer B: Kumo yeleği üstünde kalın beyaz atkı)
			var ak = 0.055 if look.get("vest") != null else 0.03
			_garment("atki", func(): return _loft(g, 1, neck - 0.06, neck + 0.04, 5, func(p): return absf(p.x) < 0.16, flat.call(ak), 8))
		"buyuk_kapusonlu":
			# bol kapüşonlu (Striker Himawari): boyundan uyluk üstüne bol; arkada katlı kapüşon
			_garment("buyuk_kapusonlu", func(): return _cut_spec(g, neck + 0.0, hips - 0.12, 18, {"w": [[0.0, 0.86], [0.1, 1.12], [1.0, 1.12]], "d": [[0.0, 0.13], [1.0, 0.15]], "n": 3.4}, 8, hips - 0.04, 0.04))   # KESİM: himawari_outfit — bol kapüşonlu
			_garment("buyuk_kapuson_kat", func(): return _loft(g, 1, neck - 0.08, neck + 0.06, 7, func(p): return absf(p.x) < 0.18, func(t, a): return (0.075 - t * 0.03) if sin(a) < 0.3 else 0.045 - t * 0.015, 8))
		"kisa_kollu_kazak":
			# kısa kollu kazak (Striker Hinata 5): geniş yakalı, bele kadar; dirseğin üstüne kısa geniş kollar
			_garment("kisa_kollu_kazak", func(): return _cut_spec(g, neck - 0.01, hips + 0.05, 15, {"w": [[0.0, 0.88], [0.1, 1.06], [1.0, 1.06]], "d": [[0.0, 0.12], [1.0, 0.13]], "n": 3.4}, 8, -99.0, 0.035))   # KESİM: hinata_outfit_5 — kutu kazak
			for sx in [1.0, -1.0]:
				var kzel = absf(_bp("LeftLowerArm").x)
				_garment("kazak_kisa_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) * 0.86) * sx, (kzel - 0.04) * sx, 8, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.84 and absf(p.x) < kzel - 0.02, func(t, _a): return 0.026 + t * 0.016, 8, null, -99.0, 24))
		"uzun_robe":
			# önü açık uzun cübbe (Striker Hiashi): boyundan bileğe, önü boydan boya açık; çok geniş uzun kollar
			_garment("uzun_robe", func(): return _cut_loft(g, 1, neck + 0.01, ank + 0.03, 32, torso, func(t): return Vector4(absf(ua) * (lerpf(0.8, 1.04, smoothstep(0.0, 0.1, t)) + 0.18 * t), lerpf(0.11, 0.15, t), 0.2 + 0.28 * smoothstep(0.1, 0.5, t), 3.2), 8, hips - 0.05, 56, 0.03))   # KESİM: 4 foto hiashi_outfit; iç beyaz cübbe+hakama payı
			for sx in [1.0, -1.0]:
				var rrhx = absf(_bp("LeftHand").x)
				_garment("robe_kol%d" % int(sx), func(): return _cut_loft(g, 0, (absf(ua) * 0.92) * sx, (rrhx - 0.05) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.9 and absf(p.x) < rrhx - 0.03, func(t): return Vector4(0.07 + 0.06 * t, 0.06 + 0.02 * t, 0.0, 4.0), 8, -99.0, 28, 0.01))
		"kabarik_bluz":
			# kabarık bluz (Striker Eida): uzun dik boğazlı, bele kadar bol; balon kollar bilekte toplanır
			_garment("kabarik_bluz", func(): return _cut_spec(g, neck + 0.0, hips + 0.05, 16, {"w": [[0.0, 0.86], [0.12, 1.12], [1.0, 1.08]], "d": [[0.0, 0.13], [1.0, 0.15]], "n": 3.0}, 8, -99.0, 0.04))   # KESİM: eida_outfit — bol bluz
			_garment("kabarik_yaka", func(): return _loft(g, 1, neck - 0.03, neck + 0.11, 7, func(p): return absf(p.x) < 0.14, func(t, _a): return 0.055 - t * 0.01, 8))
			_cut_sleeve(g, "bluz_kol", [[0.0, 0.06], [0.5, 0.1], [0.88, 0.09], [1.0, 0.05]], 0.05, 8, 2.2)   # KESİM: eida — balon kol
		"kurbaga_kigurumi":
			# kurbağa kostümü (Striker Frog): boğazdan bileğe tüm vücudu saran kabarık tulum; kollar ve bacaklar ayrı şişkin tüpler
			_garment("kurbaga_govde", func(): return _loft(g, 1, neck + 0.05, hips - 0.12, 15, torso, func(t, _a): return 0.04 + 0.025 * sin(t * PI), 8))
			for sx in [1.0, -1.0]:
				var fhx = absf(_bp("LeftHand").x)
				_garment("kurbaga_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) * 0.86) * sx, (fhx - 0.03) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.84 and absf(p.x) < fhx - 0.01, func(t, _a): return 0.024 + 0.014 * sin(t * PI), 8, null, -99.0, 24))
				var fkx = _bp(("Left" if sx > 0.0 else "Right") + "LowerLeg").x
				_garment("kurbaga_bacak%d" % int(sx), func(): return _loft(g, 1, hips - 0.06, ank + 0.01, 18, func(p): return signf(p.x) == sx and absf(p.x - fkx) < 0.12, func(t, a): return (0.028 + 0.012 * sin(t * PI)) * (1.0 if cos(a) * sx > -0.4 else 0.5), 8, null, -99.0, 24))
		"seytan_kapuson":
			# çivili kısa kapüşonlu (Striker Daemon): boyundan belin üstüne kısa, fermuarlı; arkada katlı kapüşon
			_garment("seytan_kapuson", func(): return _cut_spec(g, neck + 0.0, hips + 0.12, 14, {"w": [[0.0, 0.84], [0.12, 1.04], [1.0, 1.0]], "d": [[0.0, 0.12], [1.0, 0.13]], "n": 3.2}, 8, -99.0, 0.03))   # KESİM: daemon_outfit — kısa kutu kapüşonlu
			_garment("seytan_kapuson_kat", func(): return _loft(g, 1, neck - 0.08, neck + 0.05, 6, func(p): return absf(p.x) < 0.18, func(t, a): return (0.06 - t * 0.025) if sin(a) < 0.3 else 0.035 - t * 0.012, 8))
		"danzo_ortu":
			# bej örtü (Striker Danzō): belin önünde soldan sağa çapraz sarılı büyük bez; önde ve solda uyluğa sarkar
			_garment("danzo_ortu", func(): return _loft(g, 1, hips + 0.2, hips - 0.24, 14, torso, func(t, a): return 0.07 + t * 0.05 + 0.01 * sin(a * 4.0 + t * 3.0), 8,
				func(t, ang): return sin(ang) < -0.25 or (cos(ang) < -0.2 - t * 0.6) or (t < 0.4 and cos(ang) < 0.3 - t * 1.5), hips - 0.05, 40))
		"delta_elbise":
			# Delta mini elbisesi (Striker Delta): dik yakadan uyluk üstüne; göğüste anahtar deliği oyuğu, omuzlar açık (kollar ayrı balon)
			_garment("delta_elbise", func(): return _cut_spec(g, neck + 0.04, hips - 0.18, 20, {"w": [[0.0, 0.6], [0.12, 0.88], [0.55, 0.84], [1.0, 1.02]], "d": [[0.0, 0.08], [0.15, 0.11], [1.0, 0.13]], "n": 2.6}, 8, hips - 0.06, 0.045, func(t, ang): return t > 0.07 and t < 0.3 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.22 * sin((t - 0.07) / 0.23 * PI)))   # KESİM: delta_outfit — oturan hafif A elbise
			for sx in [1.0, -1.0]:
				var dhx = absf(_bp("LeftHand").x)
				_garment("delta_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) + 0.05) * sx, (dhx - 0.05) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) + 0.03 and absf(p.x) < dhx - 0.03, func(t, _a): return 0.02 + 0.045 * sin(clampf(t * 1.1, 0.0, 1.0) * PI), 8, null, -99.0, 24))
		"kutlama_kimono":
			# kutlama kimonosu (Striker Celebratory): boyundan baldır ortasına; belden aşağı önde açılır, çok geniş uzun kollar
			_garment("kutlama_kimono", func(): return _cut_loft(g, 1, neck + 0.0, ank + 0.2, 30, torso, func(t): return Vector4(absf(ua) * (lerpf(0.8, 1.0, smoothstep(0.0, 0.1, t)) + 0.3 * maxf(0.0, t - 0.35)), lerpf(0.11, 0.16, t), 0.0 if t < 0.4 else 0.1 + (t - 0.4) * 0.6, 3.0), 8, hips - 0.05, 56, 0.03))   # KESİM: celebratory_outfits fotoları; hakama payı
			for sx in [1.0, -1.0]:
				var khx2 = absf(_bp("LeftHand").x)
				_garment("kutlama_kol%d" % int(sx), func(): return _cut_loft(g, 0, (absf(ua) * 0.92) * sx, (khx2 - 0.06) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.9 and absf(p.x) < khx2 - 0.04, func(t): return Vector4(0.065 + 0.07 * t, 0.06 + 0.025 * t, 0.0, 3.5), 8, -99.0, 28, 0.01))
		"kolsuz_kimono":
			# kolsuz kimono üst (Striker Chōchō): boyundan belin altına kruvaze, kolsuz (omuzlar file iç)
			_garment("kolsuz_kimono", func(): return _cut_spec(g, neck - 0.02, hips + 0.1, 14, {"w": [[0.0, 0.8], [0.12, 0.92], [1.0, 0.92]], "d": [[0.0, 0.11], [1.0, 0.12]], "n": 2.6}, 8, -99.0, 0.045))   # KESİM: cho_cho_outfit — oturan kolsuz kimono üst
		"takim_yelek":
			# takım yeleği (Striker Code): boyundan belin altına kolsuz, önde küçük V
			_garment("takim_yelek", func(): return _cut_spec(g, neck - 0.02, hips - 0.05, 16, {"w": [[0.0, 0.8], [0.12, 0.9], [1.0, 0.9]], "d": [[0.0, 0.1], [1.0, 0.12]], "n": 2.6}, 8, -99.0, 0.035, func(t, ang): return t < 0.2 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.3 - t * 1.4))   # KESİM: code_outfit — oturan yelek
		"uzun_trench":
			# uzun trençkot (Striker Anko): boyundan dize, önü boydan boya açık, bol
			_garment("uzun_trench", func(): return _cut_loft(g, 1, neck + 0.0, knee - 0.02, 26, torso, func(t): return Vector4(absf(ua) * (lerpf(0.82, 1.02, smoothstep(0.0, 0.12, t)) + 0.1 * t), lerpf(0.11, 0.15, t), 0.36 + 0.16 * t, 3.0), 8, hips - 0.04, 56, 0.03))   # KESİM: 6 foto anko_outfit; mini etek payı
		"rikudo_cubbe":
			# Rikudō cübbesi (Striker Asura): yüksek yakalı, bileğe inen geniş beyaz cübbe; çok geniş uzun kollar
			_garment("rikudo_cubbe", func(): return _cut_loft(g, 1, neck + 0.02, ank + 0.05, 32, torso, func(t): return Vector4(absf(ua) * (lerpf(0.8, 1.0, smoothstep(0.0, 0.1, t)) + 0.75 * maxf(0.0, t - 0.32)), lerpf(0.11, 0.27, t), 0.0, 2.6), 8, hips - 0.05, 56, 0.03))   # KESİM: asura_outfit
			for sx in [1.0, -1.0]:
				var rhx = absf(_bp("LeftHand").x)
				_garment("rikudo_kol%d" % int(sx), func(): return _cut_loft(g, 0, (absf(ua) * 0.92) * sx, (rhx - 0.05) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.9 and absf(p.x) < rhx - 0.03, func(t): return Vector4(0.07 + 0.08 * t, 0.065 + 0.03 * t, 0.0, 4.0), 8, -99.0, 28, 0.01))
		"yirtik_esofman":
			# yırtık eşofman ceketi (Striker Boruto Prologue): önü açık, etek ucu dişli yırtık
			_garment("yirtik_esofman", func(): return _cut_spec(g, neck + 0.0, hips - 0.07, 18, {"w": [[0.0, 0.84], [0.12, 1.06], [1.0, 1.08]], "d": [[0.0, 0.12], [1.0, 0.14]], "o": [[0.0, 0.32], [1.0, 0.38]], "n": 3.2}, 8, hips - 0.02, 0.03, func(t, ang): return t > 0.82 and fposmod(ang * 3.3, 1.0) < (t - 0.82) * 3.5))   # KESİM: boruto prologue — bol açık ceket, dişli yırtık etek
			_cut_sleeve(g, "yirtik_kol", [[0.0, 0.056], [0.7, 0.058], [1.0, 0.05]], 0.06, 8, 2.6)   # düz geniş eşofman kolu
		"gunes_kimono":
			# güneş kimonosu (Striker 15 Milyon / 20. yıl): üstte sağ omuzdan sol bele çapraz sarılı (sol omuz ve kol açık),
			# belden aşağı dizin altına bol sarma; yalnız sağda kısa kıvrık geniş kol
			_garment("gunes_kimono", func(): return _cut_spec(g, neck + 0.0, knee - 0.1, 28, {"w": [[0.0, 0.86], [0.1, 1.0], [0.35, 1.0], [1.0, 1.35]], "d": [[0.0, 0.12], [0.35, 0.13], [1.0, 0.2]], "n": 3.0}, 8, hips - 0.06, 0.035, func(t, ang): return (t < 0.36 and cos(ang) > -0.25 + t * 3.4) or (t > 0.5 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < (t - 0.5) * 1.6)))   # KESİM: 15 milyon/20. yıl — tek omuz sarılı kimono
			var gel = absf(_bp("LeftLowerArm").x)
			_garment("gunes_kol", func(): return _loft(g, 0, -(absf(ua) * 0.86), -(gel + 0.0), 9, func(p): return p.x < 0.0 and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.84 and absf(p.x) < gel + 0.02, func(t, _a): return 0.03 + t * 0.03, 8, null, -99.0, 24))
		"genis_gomlek":
			# bol geniş yakalı gömlek (Striker Amado): boyundan kalçaya bol, önde V yaka; ön kol ortasına bol kollar
			_garment("genis_gomlek", func(): return _cut_spec(g, neck + 0.0, hips - 0.06, 18, {"w": [[0.0, 0.86], [0.12, 1.1], [1.0, 1.12]], "d": [[0.0, 0.12], [1.0, 0.145]], "n": 3.4}, 8, hips - 0.02, 0.035, func(t, ang): return t < 0.16 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.4 - t * 2.2))   # KESİM: amado_outfit — bol kutu gömlek, V yaka
			_cut_sleeve(g, "genis_kol", [[0.0, 0.062], [1.0, 0.07]], 0.11, 8, 2.6)   # KESİM: amado — bol düz 3/4 kol
		"kuyruklu_ceket":
			# kuyruklu ceket (Striker Shikamaru): önde bele kadar açık, arkada ve yanlarda dize inen etek; dirsek boyu kollar
			_garment("kuyruklu_ceket", func(): return _cut_spec(g, neck + 0.0, knee - 0.04, 30, {"w": [[0.0, 0.82], [0.1, 0.98], [1.0, 1.08]], "d": [[0.0, 0.11], [1.0, 0.14]], "o": [[0.0, 0.28], [0.35, 0.36], [0.55, 0.95], [1.0, 1.45]], "n": 3.0}, 8, hips - 0.04, 0.03))   # KESİM: shikamaru_outfit — düz yelek-ceket, belden geniş açılım, dize kuyruk
			for sx in [1.0, -1.0]:
				var qel = absf(_bp("LeftLowerArm").x)
				_garment("kuyruk_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) * 0.86) * sx, (qel + 0.03) * sx, 9, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.84 and absf(p.x) < qel + 0.05, func(t, _a): return 0.026 + t * 0.016, 8, null, -99.0, 24))
		"kisa_kimono":
			# kısa kimono (Striker Temari): boyundan uyluk ortasına; dirseğin altına geniş kimono kolları
			_garment("kisa_kimono", func(): return _cut_spec(g, neck + 0.0, hips - 0.22, 22, {"w": [[0.0, 0.84], [0.1, 1.02], [0.5, 1.0], [1.0, 1.1]], "d": [[0.0, 0.115], [1.0, 0.14]], "n": 3.2}, 8, hips - 0.05, 0.035))   # KESİM: temari/haku — kısa kutu kimono
			_cut_sleeve(g, "kimono_kol", [[0.0, 0.065], [1.0, 0.1]], 0.12, 8, 3.5)   # KESİM: temari/haku — dirsek altı geniş kimono kolu
		"panel_etek":
			# iki panelli kısa etek (Striker Sakura): belden uyluk ortasına; iki yanda yırtmaç (önde ve arkada ayrı panel)
			_garment("panel_etek", func(): return _cut_spec(g, hips + 0.06, hips - 0.19, 12, {"w": [[0.0, 0.86], [1.0, 1.06]], "d": [[0.0, 0.11], [1.0, 0.145]], "n": 3.2}, 8, hips - 0.05, 0.03, func(t, ang): return t > 0.12 and (absf(wrapf(ang, -PI, PI)) < 0.2 or absf(wrapf(ang - PI, -PI, PI)) < 0.2)))   # KESİM: sakura_outfit — yanları yırtmaçlı panel etek
		"uzun_panel_ust":
			# yırtmaçlı uzun üst (Striker Sarada): boyundan uyluk ortasına kolsuz; kalçadan aşağı iki yanda yırtmaç
			_garment("uzun_panel_ust", func(): return _cut_spec(g, neck + 0.0, hips - 0.21, 22, {"w": [[0.0, 0.78], [0.12, 0.9], [0.5, 0.86], [1.0, 0.98]], "d": [[0.0, 0.1], [1.0, 0.13]], "n": 2.6}, 8, hips - 0.05, 0.045, func(t, ang): return t > 0.55 and (absf(wrapf(ang, -PI, PI)) < 0.28 or absf(wrapf(ang - PI, -PI, PI)) < 0.28)))   # KESİM: sarada_outfit — oturan yırtmaçlı uzun üst
		"bel_ortusu":
			# bel örtüsü (Striker Sasuke): belden dizin üstüne sarılı lacivert kumaş; önü ve arkası kat kat
			_garment("bel_ortusu", func(): return _cut_spec(g, hips + 0.1, knee + 0.02, 18, {"w": [[0.0, 0.9], [1.0, 1.22]], "d": [[0.0, 0.12], [1.0, 0.17]], "n": 3.0}, 8, hips - 0.05, 0.035))   # KESİM: sasuke_outfit — dize sarılı bel örtüsü
		"kolsuz_palto":
			# kolsuz palto (Striker Sasuke 2): boyundan uyluğa, göğüs altından önde açılan yırtmaç
			_garment("kolsuz_palto", func(): return _cut_spec(g, neck - 0.01, hips - 0.16, 20, {"w": [[0.0, 0.84], [0.12, 1.0], [1.0, 1.04]], "d": [[0.0, 0.11], [1.0, 0.135]], "o": [[0.0, 0.0], [0.45, 0.0], [0.6, 0.16], [1.0, 0.3]], "n": 3.4}, 8, hips - 0.04, 0.03))   # KESİM: sasuke_outfit_2 — düz kolsuz palto, karından yırtmaç
		"onluk_elbise":
			# uzun önlük elbise (Striker Kushina): kolsuz; göğüste oval yaka oyuntusu, baldıra inen hafif çan etek
			_garment("onluk_elbise", func(): return _cut_loft(g, 1, neck - 0.07, ank + 0.17, 28, torso, func(t): return Vector4(absf(ua) * (0.78 + 0.55 * maxf(0.0, t - 0.28)), lerpf(0.1, 0.17, t), 0.0, 2.4), 8, hips - 0.05, 56, func(t): return 0.05))   # KESİM: 6 foto kushina_outfit; göğüs payı
		"iki_ton_kimono":
			# iki tonlu kimono üst (Striker Mitsuki): boyundan uyluğa; çok geniş kimono kolları bileğin üstüne
			_garment("iki_ton_kimono", func(): return _cut_spec(g, neck + 0.0, hips - 0.2, 22, {"w": [[0.0, 0.86], [0.1, 1.06], [1.0, 1.1]], "d": [[0.0, 0.12], [1.0, 0.14]], "n": 3.4}, 8, hips - 0.04, 0.035))   # KESİM: mitsuki_outfit — kutu kimono
			_cut_sleeve(g, "kimono_genis", [[0.0, 0.07], [0.4, 0.1], [1.0, 0.12]], 0.1, 8, 4.0)   # KESİM: mitsuki — kare geniş kimono kolu
		"turuncu_ceket":
			# kapalı eşofman ceketi (Striker Naruto): boyundan belin altına, fermuarı kapalı
			_garment("turuncu_ceket", func(): return _cut_spec(g, neck + 0.0, hips - 0.03, 16, {"w": [[0.0, 0.82], [0.12, 1.02], [0.85, 1.0], [1.0, 0.9]], "d": [[0.0, 0.11], [0.8, 0.13], [1.0, 0.12]], "n": 3.2}, 8, -99.0, 0.03))   # KESİM: naruto_outfit — kutu kapalı eşofman, bantlı bel
			_cut_sleeve(g, "turuncu_kol", [[0.0, 0.056], [0.7, 0.058], [1.0, 0.05]], 0.06, 8, 2.6)   # düz geniş eşofman kolu
		"kisa_bolero":
			# kısa bolero ceket (Striker Sai): boyundan göbek üstüne, önü açık
			_garment("kisa_bolero", func(): return _cut_spec(g, neck + 0.0, hips + 0.13, 13, {"w": [[0.0, 0.84], [0.12, 1.02], [1.0, 1.0]], "d": [[0.0, 0.11], [1.0, 0.12]], "o": [[0.0, 0.42], [1.0, 0.42]], "n": 3.2}, 8, -99.0, 0.03))   # KESİM: sai_outfit — kısa kutu bolero
		"yilan_cubbe":
			# kapüşonlu uzun cübbe (Striker Kabuto; 13 foto refs/outfits_ss/all/kabuto_robe): KESİM — omuzdan yere üçgen A siluet
			# (etek omuzun ~1.75 katı), düz ön, kapüşon boyunda toplu; kollar dirsekten sonra açılan çan
			var S = absf(ua)
			_garment("yilan_cubbe", func(): return _cut_loft(g, 1, neck + 0.0, ank + 0.02, 32, torso, func(t): return Vector4(S * (lerpf(0.66, 1.05, smoothstep(0.0, 0.1, t)) + 1.35 * maxf(0.0, t - 0.1)), lerpf(0.12, 0.24, t), 0.0, 2.3), 8, hips - 0.05, 56))
			_garment("yilan_kapuson", func(): return _loft(g, 1, neck - 0.07, neck + 0.07, 7, func(p): return absf(p.x) < 0.17, func(t, a): return (0.07 - t * 0.02) if sin(a) < 0.2 else (0.045 - t * 0.015), 8))
			for sx in [1.0, -1.0]:
				var chx = absf(_bp("LeftHand").x)
				var cel = absf(_bp("LeftLowerArm").x)
				var tel = (cel - S * 0.92) / maxf(chx - 0.06 - S * 0.92, 0.05)
				_garment("cubbe_kol%d" % int(sx), func(): return _cut_loft(g, 0, (S * 0.92) * sx, (chx - 0.06) * sx, 16, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > S * 0.9 and absf(p.x) < chx - 0.04, func(t): return Vector4(0.06 + 0.07 * smoothstep(tel - 0.2, 1.0, t), 0.06 + 0.07 * smoothstep(tel - 0.2, 1.0, t), 0.0, 2.0), 8, -99.0, 28, 0.01))
		"algi_ceket":
			# uzun dar ceket (Striker Karin): boyundan uyluk üstüne; kemerden aşağı önde ters V açılır
			_garment("algi_ceket", func(): return _cut_spec(g, neck + 0.0, hips - 0.13, 18, {"w": [[0.0, 0.78], [0.12, 0.92], [0.55, 0.84], [1.0, 0.98]], "d": [[0.0, 0.1], [0.55, 0.11], [1.0, 0.13]], "o": [[0.0, 0.0], [0.62, 0.0], [0.75, 0.25], [1.0, 0.55]], "n": 2.6}, 8, hips - 0.03, 0.03))   # KESİM: karin_outfit — belde oturan, alttan açılan ceket
		"sargi_elbise":
			# sargı elbise (Striker Kurenai): göğüs üstünden uyluk ortasına gövdeyi saran beyaz sargı kumaş (bantlar ayrıntıda)
			_garment("sargi_elbise", func(): return _cut_spec(g, chest + 0.06, hips - 0.2, 18, {"w": [[0.0, 0.88], [0.4, 0.86], [1.0, 1.0]], "d": [[0.0, 0.12], [1.0, 0.13]], "n": 2.6}, 8, hips - 0.06, 0.045))   # KESİM: kurenai_outfit — düz sargı elbise
		"hinata_ceket":
			# bol kapüşonlu ceket (Striker Hinata): boyundan kalçanın altına hafif çan; önde boyunda küçük V (iç file görünür),
			# geniş uzun kollar (bilekte açılır), boynu saran dolgun kapüşon yakası
			if look.get("hc_open", false):   # fermuarı açık (Striker Hinata 3): ön boydan boya açık
				_garment("hinata_ceket_acik", func(): return _cut_spec(g, neck + 0.0, hips - 0.08, 18, {"w": [[0.0, 0.86], [0.1, 1.04], [1.0, 1.16]], "d": [[0.0, 0.12], [1.0, 0.145]], "o": [[0.0, 0.5], [1.0, 0.56]], "n": 3.2}, 8, hips - 0.03, 0.035))   # KESİM: hinata_outfit_3 — açık çan kutu ceket
			else:
				_garment("hinata_ceket", func(): return _cut_spec(g, neck + 0.0, hips - 0.08, 18, {"w": [[0.0, 0.86], [0.1, 1.04], [1.0, 1.16]], "d": [[0.0, 0.12], [1.0, 0.145]], "n": 3.2}, 8, hips - 0.03, 0.035, func(t, ang): return t < 0.16 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.32 - t * 1.6))   # KESİM: hinata_outfit — hafif çan kutu ceket
			_garment("hinata_yaka", func(): return _loft(g, 1, neck - 0.045, neck + 0.05, 7, func(p): return absf(p.x) < 0.15, func(t, a): return 0.05 - t * 0.022 + (0.018 if sin(a) < -0.2 else 0.0), 8,
				func(_t, ang): return absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.3))
			for sx in [1.0, -1.0]:
				var hhx = absf(_bp("LeftHand").x)
				_garment("hinata_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) * 0.86) * sx, (hhx - 0.03) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.84 and absf(p.x) < hhx - 0.02, func(t, _a): return 0.022 + t * t * 0.045, 8, null, -99.0, 24))
		"kirpik_kapusonlu":
			# kısa kapüşonlu (Striker Hinata 2): boyundan belin üstüne kısa; kısa kollar dirseğe kadar; arkada katlı kapüşon
			_garment("kirpik_kapusonlu", func(): return _cut_spec(g, neck + 0.0, hips + 0.15, 14, {"w": [[0.0, 0.84], [0.12, 1.02], [1.0, 1.0]], "d": [[0.0, 0.11], [1.0, 0.12]], "n": 3.0}, 8, -99.0, 0.035))   # KESİM: hinata_outfit_2 — kısa kapüşonlu
			_garment("kirpik_kapuson", func(): return _loft(g, 1, neck - 0.08, neck + 0.04, 6, func(p): return absf(p.x) < 0.18, func(t, a): return (0.05 - t * 0.02) if sin(a) < 0.3 else 0.03 - t * 0.012, 8))
			for sx in [1.0, -1.0]:
				var kel = absf(_bp("LeftLowerArm").x)
				_garment("kirpik_kol%d" % int(sx), func(): return _loft(g, 0, (absf(ua) * 0.86) * sx, (kel + 0.01) * sx, 8, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > absf(ua) * 0.84 and absf(p.x) < kel + 0.03, func(t, _a): return 0.024 + t * 0.012, 8, null, -99.0, 24))
		"yirtmacli_etek":
			# yırtmaçlı diz üstü etek (Striker Ino): belden uyluk ortasına, önde ortada yırtmaç; içinde gri iç etek (pantolon rengi)
			_garment("ic_etek", func(): return _loft(g, 1, hips + 0.02, hips - 0.22, 10, torso, func(t, _a): return 0.01 + t * 0.016, 3, null, hips - 0.08))
			_garment("yirtmacli_etek", func(): return _cut_spec(g, hips + 0.07, hips - 0.27, 14, {"w": [[0.0, 0.86], [1.0, 1.08]], "d": [[0.0, 0.11], [1.0, 0.15]], "n": 3.0}, 8, hips - 0.06, 0.03, func(t, ang): return t > 0.08 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.12 + t * 0.06))   # KESİM: ino_outfit — düz hafif A, önde yırtmaç
		"sargi_etek_uzun":
			# uzun sargı etek (Striker Ino 2): belden baldır ortasına düz-hafif çan; önde kruvaze kat çizgisi (desen)
			_garment("sargi_etek_uzun", func(): return _cut_spec(g, hips + 0.07, ank + 0.16, 22, {"w": [[0.0, 0.86], [1.0, 1.38]], "d": [[0.0, 0.11], [1.0, 0.22]], "n": 2.8}, 8, hips - 0.06, 0.03))   # KESİM: ino_outfit_2 — baldıra A sargı etek
		"esofman_ceket":
			# önü açık eşofman ceketi (Striker Boruto): boyundan belin altına, gövdeye yakın; fermuar açık (dar ön açıklık)
			_garment("esofman_ceket", func(): return _cut_spec(g, neck + 0.0, hips - 0.04, 16, {"w": [[0.0, 0.82], [0.12, 1.02], [0.85, 1.0], [1.0, 0.92]], "d": [[0.0, 0.11], [0.8, 0.13], [1.0, 0.12]], "o": [[0.0, 0.14], [1.0, 0.1]], "n": 3.2}, 8, -99.0, 0.03))   # KESİM: boruto_outfit — kutu eşofman, bantlı bel
			_cut_sleeve(g, "esofman_kol", [[0.0, 0.056], [0.7, 0.058], [1.0, 0.05]], 0.06, 8, 2.6)   # düz geniş eşofman kolu
		"kisa_haori":
			# kısa geniş kollu ceket (Striker Choji): boyundan kalçanın altına, önü açık; kollar dirseğin altına geniş ağızlı
			_garment("kisa_haori", func(): return _cut_spec(g, neck + 0.01, hips - 0.1, 18, {"w": [[0.0, 0.86], [0.1, 1.08], [1.0, 1.12]], "d": [[0.0, 0.12], [1.0, 0.14]], "o": [[0.0, 0.5], [1.0, 0.58]], "n": 3.4}, 8, hips - 0.03, 0.035))   # KESİM: choji_outfit — bol açık haori
			_cut_sleeve(g, "haori_kol", [[0.0, 0.065], [1.0, 0.095]], 0.12, 8, 3.2)   # KESİM: choji — geniş 3/4 haori kolu
		"isshiki_palto":
			# açık uzun palto (Striker Isshiki; foto all/isshiki_outfit): dize inen kutu panel, önü açık; geniş düz kollar; yüksek kırmızı yaka
			_garment("isshiki_palto", func(): return _cut_spec(g, neck + 0.0, knee - 0.05, 26, {"w": [[0.0, 0.86], [0.1, 1.04], [1.0, 1.14]], "d": [[0.0, 0.12], [1.0, 0.15]], "o": [[0.0, 0.5], [1.0, 0.56]], "n": 3.0}, 8, hips - 0.05, 0.035))
			_cut_sleeve(g, "isshiki_kol", [[0.0, 0.064], [1.0, 0.085]], 0.05, 8, 3.0)
			_garment_tinted("isshiki_yaka", Color(0.62, 0.08, 0.14), func(): return _loft(g, 1, neck - 0.04, neck + 0.14, 8, func(p): return absf(p.x) < 0.17, func(t, _a): return 0.04 + t * 0.06, 10, func(_t, ang): return absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.6))
		"itachi_tunik":
			# kısa kollu tunik (Striker Itachi; foto all/itachi_outfit): uyluk ortasına kutu tunik, önde V yaka (file iç görünür)
			_garment("itachi_tunik", func(): return _cut_spec(g, neck + 0.0, hips - 0.18, 20, {"w": [[0.0, 0.86], [0.1, 1.04], [1.0, 1.08]], "d": [[0.0, 0.12], [1.0, 0.13]], "n": 3.2}, 8, hips - 0.04, 0.035, func(t, ang): return t < 0.14 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.38 - t * 2.6))
			_cut_sleeve(g, "itachi_kol", [[0.0, 0.062], [1.0, 0.066]], absf(_bp("LeftHand").x) - lerpf(absf(ua), absf(_bp("LeftLowerArm").x), 0.75), 8, 2.8)
		"edo_cubbe":
			# kapüşonlu cübbe (Striker Itachi Edo; foto all/itachi_outfit_reanimation_ver): baldıra inen hafif A, altta önde yırtmaç
			_garment("edo_cubbe", func(): return _cut_spec(g, neck + 0.0, ank + 0.12, 28, {"w": [[0.0, 0.86], [0.1, 1.02], [1.0, 1.26]], "d": [[0.0, 0.12], [1.0, 0.17]], "o": [[0.0, 0.0], [0.72, 0.0], [1.0, 0.14]], "n": 2.8}, 8, hips - 0.05, 0.035))
			_garment("edo_kapuson", func(): return _loft(g, 1, neck - 0.07, neck + 0.07, 7, func(p): return absf(p.x) < 0.17, func(t, a): return (0.075 - t * 0.02) if sin(a) < 0.2 else (0.05 - t * 0.015), 8))
			_cut_sleeve(g, "edo_kol", [[0.0, 0.066], [1.0, 0.1]], 0.06, 8, 2.8)
		"kolsuz_trench":
			# kolsuz uzun trençkot (Striker Iwabe; foto all/iwabe_outfit_ninja_school_version): baldıra inen, önü boydan boya açık
			_garment("kolsuz_trench", func(): return _cut_spec(g, neck + 0.01, knee - 0.12, 26, {"w": [[0.0, 0.86], [0.1, 1.04], [1.0, 1.12]], "d": [[0.0, 0.12], [1.0, 0.15]], "o": [[0.0, 0.3], [0.3, 0.42], [1.0, 0.56]], "n": 3.2}, 8, hips - 0.05, 0.035))
		"jigen_cubbe":
			# uzun cübbe (Striker Jigen; foto all/jigen_outfit): göğüste kapalı çapraz, belin altından açılan, bileğe inen hafif A; kollar dirsek altında biten geniş kimono kolu
			_garment("jigen_cubbe", func(): return _cut_spec(g, neck + 0.0, ank + 0.1, 30, {"w": [[0.0, 0.86], [0.1, 1.04], [0.35, 1.06], [1.0, 1.4]], "d": [[0.0, 0.12], [1.0, 0.18]], "o": [[0.0, 0.0], [0.33, 0.0], [0.42, 0.18], [1.0, 0.75]], "n": 2.8}, 8, hips - 0.05, 0.035))
			_cut_sleeve(g, "jigen_kol", [[0.0, 0.066], [0.6, 0.1], [1.0, 0.11]], absf(_bp("LeftHand").x) - lerpf(absf(_bp("LeftLowerArm").x), absf(_bp("LeftHand").x), 0.35), 8, 2.6)
		"sennin_yelek":
			# kolsuz uzun yelek (Striker Jiraiya; foto all/jiraiya_outfit): omuzdan dize düz kutu panel, önü boydan açık
			_garment("sennin_yelek", func(): return _cut_spec(g, neck + 0.0, knee + 0.1, 24, {"w": [[0.0, 0.9], [0.1, 1.08], [1.0, 1.18]], "d": [[0.0, 0.13], [1.0, 0.16]], "o": [[0.0, 0.42], [1.0, 0.5]], "n": 3.4}, 8, hips - 0.05, 0.035))
		"kaguya_kimono":
			# yere inen kimono (Striker Kaguya; foto all/kaguya_outfit): kapalı, belden aşağı geniş çan; kollar bilekte çan gibi açılır
			_garment("kaguya_kimono", func(): return _cut_spec(g, neck + 0.0, ank - 0.03, 32, {"w": [[0.0, 0.86], [0.1, 1.04], [0.35, 1.06], [1.0, 2.0]], "d": [[0.0, 0.12], [0.35, 0.13], [1.0, 0.24]], "n": 2.4}, 8, hips - 0.05, 0.035))
			_cut_sleeve(g, "kaguya_kol", [[0.0, 0.066], [0.5, 0.085], [1.0, 0.16]], 0.0, 8, 2.2)
		"rokudaime_cubbe":
			# kapalı uzun cübbe (Striker Kakashi Sixth Hokage; foto all/kakashi_outfit_sixth_hokage_vers): omuzdan bileğe hafif A, önü kapalı;
			# boyunda kalın sargı yaka; bileğe inen geniş kollar
			_garment("rokudaime_cubbe", func(): return _cut_spec(g, neck + 0.0, ank + 0.04, 30, {"w": [[0.0, 0.92], [0.1, 1.08], [0.4, 1.12], [1.0, 1.5]], "d": [[0.0, 0.13], [1.0, 0.2]], "n": 2.6}, 8, hips - 0.05, 0.035))
			_garment("rokudaime_yaka", func(): return _loft(g, 1, neck - 0.07, neck + 0.04, 7, func(p): return absf(p.x) < 0.17, func(t, _a): return 0.06 - t * 0.02, 8))
			_cut_sleeve(g, "rokudaime_kol", [[0.0, 0.07], [0.5, 0.1], [1.0, 0.13]], 0.02, 8, 2.4)
		"kawaki_palto":
			# kolsuz uzun palto (Striker Kawaki; foto all/kawaki_outfit): dize inen düz panel, önü boydan açık, açık mavi yaka/pervaz
			_garment("kawaki_palto", func(): return _cut_spec(g, neck + 0.02, knee + 0.02, 24, {"w": [[0.0, 0.9], [0.1, 1.06], [1.0, 1.16]], "d": [[0.0, 0.13], [1.0, 0.15]], "o": [[0.0, 0.32], [0.4, 0.36], [1.0, 0.46]], "n": 3.4}, 8, hips - 0.05, 0.035))
		"kawaki_okul":
			# kolsuz uzun palto (Striker Kawaki Ninja School; foto all/kawaki_outfit_ninja_school_version): kalçadan aşağı geniş A, dizin altına; yırtık kol oyuntusu
			_garment("kawaki_okul", func(): return _cut_spec(g, neck + 0.02, knee - 0.14, 26, {"w": [[0.0, 0.9], [0.1, 1.06], [0.35, 1.1], [1.0, 2.4]], "d": [[0.0, 0.13], [0.35, 0.15], [1.0, 0.3]], "o": [[0.0, 0.3], [0.4, 0.3], [1.0, 0.7]], "n": 3.0}, 8, hips - 0.05, 0.035))
		"kawaki_ruro":
			# kolsuz uzun yelek (Striker Kawaki Prologue; foto all/kawaki_outfit_prologue_ver): dize inen düz, önü açık; boyunda mor atkı
			_garment("kawaki_ruro", func(): return _cut_spec(g, neck + 0.0, knee - 0.02, 24, {"w": [[0.0, 0.88], [0.1, 1.04], [1.0, 1.14]], "d": [[0.0, 0.12], [1.0, 0.15]], "o": [[0.0, 0.42], [1.0, 0.5]], "n": 3.4}, 8, hips - 0.05, 0.035))
			_garment_tinted("kawaki_atki", look.get("outer2", Color(0.3, 0.22, 0.4)), func(): return _loft(g, 1, neck - 0.1, neck + 0.08, 9, func(p): return absf(p.x) < 0.17, func(t, _a): return 0.06 - absf(t - 0.4) * 0.04, 10))
		"kukla_onluk":
			# bel önlüğü (Striker Kankuro; foto all/kankuro_outfit): belden uyluk ortasına düz siyah önlük-etek
			_garment("kukla_onluk", func(): return _cut_spec(g, hips + 0.1, hips - 0.24, 10, {"w": [[0.0, 1.0], [1.0, 1.16]], "d": [[0.0, 0.12], [1.0, 0.14]], "n": 3.0}, 8, hips + 0.1, 0.02))
		"kaguya_cubbe":
			# yere inen önü açık beyaz cübbe (Striker Kaguya 2; foto all/kaguya_outfit_2): omuzdan yere geniş A, önü göğüsten aşağı giderek açılır; bileği örten geniş kollar
			_garment("kaguya_cubbe", func(): return _cut_spec(g, neck + 0.0, ank - 0.04, 32, {"w": [[0.0, 0.9], [0.1, 1.06], [0.3, 1.1], [1.0, 2.0]], "d": [[0.0, 0.13], [1.0, 0.24]], "o": [[0.0, 0.25], [0.3, 0.42], [1.0, 1.2]], "n": 2.6}, 8, hips - 0.05, 0.035))
			_cut_sleeve(g, "kaguya_ckol", [[0.0, 0.068], [0.5, 0.1], [1.0, 0.14]], 0.0, 8, 2.4)
		"haku_yukata":
			# diz altına inen yukata (Striker Haku First Encounter; foto all/haku_outfit_first_encounter_vers): kapalı çapraz yaka, belden aşağı hafif A, dirsek altı geniş kol
			_garment("haku_yukata", func(): return _cut_spec(g, neck + 0.0, knee - 0.08, 26, {"w": [[0.0, 0.88], [0.1, 1.04], [0.35, 1.06], [1.0, 1.42]], "d": [[0.0, 0.12], [1.0, 0.17]], "n": 2.8}, 8, hips - 0.05, 0.035))
			_cut_sleeve(g, "haku_kol", [[0.0, 0.065], [1.0, 0.09]], absf(_bp("LeftHand").x) - lerpf(absf(_bp("LeftLowerArm").x), absf(_bp("LeftHand").x), 0.3), 8, 2.8)
		"savas_cubbe":
			# savaş cübbesi (Striker Madara / Madara Battle / Madara Young; foto all/madara_outfit*): baldıra inen, kalçadan aşağı önden açılan hafif A;
			# yüksek dik yaka; dirsekten çan gibi açılan geniş kollar
			_garment("savas_cubbe", func(): return _cut_spec(g, neck + 0.0, ank + 0.14, 28, {"w": [[0.0, 0.9], [0.1, 1.06], [0.35, 1.08], [1.0, 1.5]], "d": [[0.0, 0.13], [1.0, 0.19]], "o": [[0.0, 0.0], [0.45, 0.0], [0.55, 0.2], [1.0, 0.5]], "n": 2.8}, 8, hips - 0.05, 0.035))
			_garment("savas_yaka", func(): return _loft(g, 1, neck - 0.05, neck + 0.1, 8, func(p): return absf(p.x) < 0.17, func(t, _a): return 0.05 - t * 0.012, 8))
			_cut_sleeve(g, "savas_kol", [[0.0, 0.068], [0.5, 0.085], [1.0, 0.13]], 0.03, 8, 2.6)
		"mei_elbise":
			# uzun elbise (Striker Mei; foto all/mei_outfit): omuzları açık, göğüsten bileğe hafif A; sağ bacakta uyluğa çıkan yırtmaç; çan kollar ayrı
			_garment("mei_elbise", func(): return _cut_spec(g, neck - 0.14, ank + 0.12, 28, {"w": [[0.0, 0.9], [0.3, 0.98], [1.0, 1.3]], "d": [[0.0, 0.12], [1.0, 0.16]], "n": 2.6}, 8, hips - 0.05, 0.03, func(t, ang): return t > 0.5 and absf(wrapf(ang - 0.35, -PI, PI)) < 0.22))
			_cut_sleeve(g, "mei_kol", [[0.0, 0.058], [0.6, 0.07], [1.0, 0.11]], 0.0, 8, 2.4)
		"hokage_haori":
			# dize inen önü açık haori (Striker Minato; foto all/minato_outfit): düz kutu panel, dirseğe inen kısa geniş kol, eteği alev desenli (outer_pattern)
			_garment("hokage_haori", func(): return _cut_spec(g, neck + 0.0, knee - 0.02, 26, {"w": [[0.0, 0.9], [0.1, 1.08], [1.0, 1.24]], "d": [[0.0, 0.13], [1.0, 0.16]], "o": [[0.0, 0.34], [0.4, 0.38], [1.0, 0.46]], "n": 3.2}, 8, hips - 0.05, 0.035))
			_cut_sleeve(g, "hokage_kol", [[0.0, 0.07], [1.0, 0.082]], absf(_bp("LeftHand").x) - absf(_bp("LeftLowerArm").x) + 0.02, 8, 2.8)
		"bel_ceket":
			# bele bağlanmış ceket (Striker Naruto Prankster; foto all/naruto_outfit_prankster_ver): kalçayı saran, önü açık kısa parça
			_garment("bel_ceket", func(): return _cut_spec(g, hips + 0.07, hips - 0.26, 12, {"w": [[0.0, 1.08], [1.0, 1.3]], "d": [[0.0, 0.13], [1.0, 0.16]], "o": [[0.0, 0.25], [1.0, 0.7]], "n": 2.6}, 8, hips + 0.07, 0.02))
		"cin_elbise":
			# dize inen çin elbisesi (Striker Sakura Young; foto all/sakura_outfit_young_ver): bedene oturan düz kesim, iki yanda uyluğa çıkan yırtmaç
			_garment("cin_elbise", func(): return _cut_spec(g, neck + 0.0, knee - 0.02, 24, {"w": [[0.0, 0.88], [0.1, 1.02], [0.4, 1.02], [1.0, 1.1]], "d": [[0.0, 0.11], [1.0, 0.13]], "n": 2.6}, 8, hips - 0.05, 0.025, func(t, ang): return t > 0.62 and absf(cos(ang)) < 0.22))
		"sarada_elbise":
			# kolsuz mini elbise (Striker Sarada 2; foto all/sarada_outfit_2): uyluk ortasına A, derin V yaka
			_garment("sarada_elbise", func(): return _cut_spec(g, neck - 0.02, hips - 0.2, 18, {"w": [[0.0, 0.84], [0.1, 0.96], [0.4, 1.0], [1.0, 1.25]], "d": [[0.0, 0.11], [1.0, 0.15]], "n": 2.6}, 8, hips - 0.03, 0.025, func(t, ang): return t < 0.3 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.34 - t * 1.1))
		"gezgin_palto":
			# dize inen kapalı palto (Striker Sasuke Back in Time; foto all/sasuke_outfit_back_in_time_ver): dik yaka, düz kesim, önde altta kısa yırtmaç; bileğe inen dar kollar
			_garment("gezgin_palto", func(): return _cut_spec(g, neck + 0.0, knee - 0.04, 26, {"w": [[0.0, 0.9], [0.1, 1.05], [0.4, 1.06], [1.0, 1.2]], "d": [[0.0, 0.12], [1.0, 0.15]], "o": [[0.0, 0.0], [0.78, 0.0], [1.0, 0.16]], "n": 2.8}, 8, hips - 0.05, 0.035))
			_garment("gezgin_yaka", func(): return _loft(g, 1, neck - 0.04, neck + 0.07, 6, func(p): return absf(p.x) < 0.17, func(t, _a): return 0.03 - t * 0.008, 8))
			_cut_sleeve(g, "gezgin_kol", [[0.0, 0.058], [1.0, 0.05]], 0.03, 8, 2.2)
		"yagura_ortu":
			# Yagura takımı (Striker Yagura; foto all/yagura_outfit): omuzlara dökülen kalın kat kat başlık (atkı-pelerin) + belden dize inen,
			# önde çapraz bindirmeli bol sargı örtü; ikisi aynı kumaş
			_garment("yagura_basalti", func(): return _cut_spec(g, neck - 0.13, neck + 0.05, 9, {"w": [[0.0, 1.58], [0.4, 1.2], [1.0, 0.66]], "d": [[0.0, 0.16], [0.4, 0.15], [1.0, 0.095]], "n": 2.0}, 8, -99.0, 0.03))
			_garment("yagura_etek", func(): return _cut_spec(g, hips + 0.13, knee + 0.0, 16, {"w": [[0.0, 1.15], [0.3, 1.45], [1.0, 1.75]], "d": [[0.0, 0.15], [0.3, 0.19], [1.0, 0.24]], "n": 2.2}, 8, hips + 0.13, 0.04, func(t, ang): return t > 0.18 and absf(wrapf(ang - PI * 0.5 - 0.35, -PI, PI)) < 0.06 + t * 0.45))
		"gelinlik":
			# gelinlik (Striker Hinata Bridal; foto all/hinata_outfit_bridal_ver): boyundan bağlı kolsuz oturan üst, belden yere geniş A
			_garment("gelinlik", func(): return _cut_spec(g, neck - 0.02, ank + 0.01, 30, {"w": [[0.0, 0.62], [0.1, 0.82], [0.35, 0.8], [1.0, 3.1]], "d": [[0.0, 0.09], [0.35, 0.11], [1.0, 0.27]], "n": 2.4}, 8, hips - 0.05, 0.045))
		"sarma_mini":
			# kısa sargı etek (Striker genç Ino; foto all/ino_outfit_young_ver): belden uyluk ortasına düz, önde bindirme kanadı
			_garment("sarma_mini", func(): return _cut_spec(g, hips + 0.06, hips - 0.23, 13, {"w": [[0.0, 0.88], [1.0, 1.02]], "d": [[0.0, 0.11], [1.0, 0.135]], "n": 3.0}, 8, hips - 0.05, 0.03))
		"inojin_ceket":
			# kısa ceket (Striker Inojin; foto all/inojin_outfit): dik yakadan göğüs altına kutu kesim, kısa kollu
			_garment("inojin_ceket", func(): return _cut_spec(g, neck + 0.0, chest - 0.2, 12, {"w": [[0.0, 0.84], [0.15, 1.02], [1.0, 1.0]], "d": [[0.0, 0.11], [1.0, 0.12]], "n": 3.2}, 8, -99.0, 0.03))
			_cut_sleeve(g, "inojin_kol", [[0.0, 0.058], [1.0, 0.062]], absf(_bp("LeftHand").x) - lerpf(absf(ua), absf(_bp("LeftLowerArm").x), 0.6), 8, 2.6)
		"kizil_palto":
			# kızıl kruvaze palto (Striker Gaara; 8 foto refs/outfits_ss/all/gaara_outfit): KESİM KALIBI — omuz genişliğinde düz
			# panel (belde daralmaz), kemerin altından önde astarı görünen yırtmaç açılır, etek baldır ortasında hafif çan;
			# kollar omuz dikişinden bileğe düz geniş tüp. Ölçüler fotoğraftan omuz yarı genişliği (S) cinsinden.
			var S = absf(ua)
			var pv1 = knee - 0.22
			var tb = (neck - (hips + 0.06)) / (neck - pv1)
			_garment("kizil_palto", func(): return _cut_loft(g, 1, neck + 0.0, pv1, 30, torso, func(t): return Vector4(S * lerpf(0.78, 1.0, smoothstep(0.0, 0.14, t)) * (1.0 - 0.1 * smoothstep(0.14, tb, t) + 0.16 * smoothstep(tb, 1.0, t)), lerpf(0.105, 0.15, t), 0.0 if t < tb else 0.2 + (t - tb) / (1.0 - tb) * 0.45, 2.8), 8, hips - 0.05, 56))
			for sx in [1.0, -1.0]:
				var phx = absf(_bp("LeftHand").x)
				_garment("palto_kol%d" % int(sx), func(): return _cut_loft(g, 0, (S * 0.92) * sx, (phx - 0.05) * sx, 14, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > S * 0.9 and absf(p.x) < phx - 0.03, func(t): return Vector4(0.058 + t * 0.008, 0.058 + t * 0.008, 0.0, 2.0), 8, -99.0, 24, 0.01))
		"onluk":
			# kolsuz hemşire önlüğü (Striker Adorable): boyundan uyluk ortasına; gövdede dar, belden sonra A kesim açılır
			_garment("onluk", func(): return _cut_spec(g, neck + 0.0, hips - 0.22, 22, {"w": [[0.0, 0.8], [0.12, 0.9], [0.5, 0.84], [1.0, 1.22]], "d": [[0.0, 0.11], [0.5, 0.11], [1.0, 0.16]], "n": 2.6}, 8, hips - 0.05, 0.045))   # KESİM: adorable_striker — oturan üst, belden A etek
		"hirka":
			# önü açık hırka (Striker Wonder): boyundan kalçanın altına bol düz gövde; ön açıklık boydan boya,
			# kollar omuzdan bileğe ayrı bol "piskopos" kol (dirsekten sonra şişer, bilekte manşete toplanır)
			_garment("hirka", func(): return _cut_spec(g, neck - 0.01, hips - 0.17, 20, {"w": [[0.0, 0.85], [0.1, 1.08], [1.0, 1.1]], "d": [[0.0, 0.12], [1.0, 0.14]], "o": [[0.0, 0.5], [1.0, 0.6]], "n": 3.4}, 8, hips - 0.03, 0.035))   # KESİM: wonder_striker — kutu kesim düşük omuz hırka
			_cut_sleeve(g, "hirka_kol", [[0.0, 0.06], [0.35, 0.07], [0.75, 0.085], [0.92, 0.06], [1.0, 0.045]], 0.045)   # KESİM: wonder — dirsekten sonra şişen, manşette toplanan bol kol
		"uzun_ceket":
			# uzun ceket (Striker Swanky): dik yakalı, dize inen; belden aşağı önde ters V açılır (sivri uçlu iki kanat)
			_garment("uzun_ceket", func(): return _cut_spec(g, neck + 0.0, knee - 0.06, 26, {"w": [[0.0, 0.8], [0.1, 0.98], [0.45, 0.94], [1.0, 1.08]], "d": [[0.0, 0.1], [1.0, 0.13]], "o": [[0.0, 0.0], [0.4, 0.0], [0.6, 0.55], [1.0, 1.35]], "n": 2.8}, 8, hips - 0.06, 0.025))   # KESİM: swanky_striker fotoları — dar düz palto, belden ters V
		"omuz_kazak":
			# omzu açık kısa kazak (Striker Sweet): göğüs üstünden (omuz hattı) belin üstüne; kollar dış giysi renginde, bilekte çan gibi açılır
			_garment("omuz_kazak", func(): return _cut_spec(g, chest + 0.07, hips + 0.08, 14, {"w": [[0.0, 1.06], [1.0, 1.1]], "d": [[0.0, 0.12], [1.0, 0.13]], "n": 3.4}, 8, -99.0, 0.04))   # KESİM: sweet_striker — omzu açık bol kısa kazak
			for sx in [1.0, -1.0]:
				var el = absf(_bp("LeftLowerArm").x)
				var hx = absf(_bp("LeftHand").x)
				_garment("kazak_kol%d" % int(sx), func(): return _loft(g, 0, el * sx, (hx - 0.03) * sx, 8, func(p): return signf(p.x) == sx and p.y > neck - 0.35 and absf(p.x) > el - 0.02 and absf(p.x) < hx - 0.02, func(t, _a): return 0.014 + t * t * 0.07, 8))
		"kapusonlu":
			# kapüşonlu (Striker Youth): boyundan kalçaya bol, kapalı gövde; kollar alttaki dirsek boyu kollu üstten (reglan renk ayrı)
			_garment("kapusonlu", func(): return _cut_spec(g, neck - 0.02, hips - 0.06, 18, {"w": [[0.0, 0.84], [0.1, 1.06], [1.0, 1.04]], "d": [[0.0, 0.12], [1.0, 0.14]], "n": 3.2}, 8, hips - 0.02, 0.035))   # KESİM: youth_striker — kutu kapüşonlu
		"flamingo_elbise":
			# omzu açık kısa elbise (Striker Beach Flamingo): göğüs üstünden uyluk ortasına; dar korse, kalçadan sonra açılan etek + fırfır katı
			_garment("flamingo_elbise", func(): return _loft(g, 1, chest + 0.06, hips - 0.2, 16, torso, func(t, _a): return 0.018 + pow(maxf(0.0, t - 0.55), 1.6) * 0.32, 8, null, hips - 0.08))
			_garment("flamingo_firfir", func(): return _loft(g, 1, hips - 0.17, hips - 0.27, 6, torso, func(t, _a): return 0.055 + t * 0.1, 8, null, hips - 0.08))
		"sisme_yelek":
			# şişme yelek (Striker Beach): boyundan belin hemen üstüne kolsuz, önü açık; yatay dolgu dilimleri (kalınlık y boyunca dalgalı)
			_garment("sisme_yelek", func(): return _loft(g, 1, neck - 0.02, hips + 0.02, 24, torso, func(t, _a): return 0.045 + 0.034 * pow(absf(sin(t * PI * 4.5)), 0.6), 8, front_gap.call(0.5, -1.0)))
		"suna_tunik":
			# Suna tuniği (Striker Sand Striker): boyundan kalçanın altına bol, kolsuz tunik
			_garment("suna_tunik", func(): return _cut_spec(g, neck - 0.03, hips - 0.12, 18, {"w": [[0.0, 0.84], [0.1, 1.02], [1.0, 1.06]], "d": [[0.0, 0.115], [1.0, 0.135]], "n": 3.2}, 8, hips - 0.04, 0.035))   # KESİM: sand_striker — düz tunik
		"kaya_gi":
			# Kaya gi (Striker Rock Striker): boyundan kalçanın altına kolsuz çapraz bağlı gi; kollar alttaki tek kollu üstten
			_garment("kaya_gi", func(): return _cut_spec(g, neck - 0.03, hips - 0.13, 18, {"w": [[0.0, 0.84], [0.1, 1.0], [1.0, 1.06]], "d": [[0.0, 0.11], [1.0, 0.135]], "n": 3.2}, 8, hips - 0.04, 0.035))   # KESİM: rock_striker — düz gi tuniği
		"bulut_etek":
			# Bulut sargı eteği (Striker Cloud Striker): göğüs altından dizin hemen altına yüksek belli A kesim sargı etek
			_garment("bulut_etek", func(): return _cut_spec(g, chest - 0.1, knee - 0.03, 22, {"w": [[0.0, 0.84], [0.25, 0.86], [1.0, 1.32]], "d": [[0.0, 0.11], [0.25, 0.115], [1.0, 0.19]], "n": 2.6}, 8, hips - 0.06, 0.035))   # KESİM: cloud_striker — yüksek bel geniş A sargı etek
		"kiri_tunik":
			# Kiri tuniği (Striker Mist Striker): boyundan kalçanın altına inen kapalı uzun tunik; kollar alttaki üstün (kısa kabarık kol)
			_garment("kiri_tunik", func(): return _cut_spec(g, neck - 0.02, hips - 0.15, 19, {"w": [[0.0, 0.84], [0.1, 1.0], [1.0, 1.04]], "d": [[0.0, 0.11], [1.0, 0.13]], "n": 3.2}, 8, hips - 0.04, 0.035))   # KESİM: mist_striker — düz uzun tunik
			# kalın atkı yaka: boynu saran kalın kumaş tüp (tuniğin dışında), rengi gölgelendiricide yaka bölgesi
			_garment("kiri_yaka", func(): return _loft(g, 1, neck - 0.08, neck + 0.06, 7, func(p): return absf(p.x) < 0.17, func(t, _a): return 0.05 - t * 0.012, 8))
		"acik_ceket":
			# önü açık kısa ceket (Striker Leaf Striker): boyundan belin hemen üstüne, gövdeye yakın; ön açıklık boydan boya (iç giysi görünür)
			_garment("acik_ceket", func(): return _cut_spec(g, neck - 0.01, hips + 0.035, 15, {"w": [[0.0, 0.84], [0.12, 1.02], [1.0, 0.98]], "d": [[0.0, 0.11], [1.0, 0.13]], "o": [[0.0, 0.36], [1.0, 0.4]], "n": 3.0}, 8, -99.0, 0.03))   # KESİM: leaf_striker — kutu kısa açık ceket
	_outer_pad = 0.0
	if look.get("outer_style") == "acik_ceket":
		_acik_ceket_kit(g)
	if look.get("outer_style") == "kiri_tunik":
		_kiri_tunik_kit(g)
	if look.get("outer_style") == "bulut_etek":
		_bulut_etek_kit(g)
	if look.get("outer_style") == "kaya_gi":
		_kaya_gi_kit(g)
	if look.get("outer_style") == "suna_tunik":
		_suna_tunik_kit(g)
	if look.get("outer_style") == "sisme_yelek":
		_sisme_yelek_kit(g)
	if look.get("outer_style") == "flamingo_elbise":
		_flamingo_kit(g)
	if look.get("outer_style") == "kapusonlu":
		_kapusonlu_kit(g)
	if look.get("outer_style") == "omuz_kazak":
		_omuz_kazak_kit(g)
	if look.get("outer_style") == "uzun_ceket":
		_uzun_ceket_kit(g)
	if look.get("outer_style") == "hirka":
		_hirka_kit(g)
	if look.get("outer_style") == "onluk":
		_onluk_kit(g)
	if look.get("outer_style") == "esofman_ceket":
		_esofman_kit(g)
	if look.get("outer_style") == "hinata_ceket":
		_hinata_ceket_kit(g)
	if look.get("outer_style") == "yilan_cubbe":
		_yilan_cubbe_kit(g)
	if look.get("outer_style") == "iki_ton_kimono":
		_iki_ton_kimono_kit(g)
	if look.get("outer_style") == "bel_ortusu":
		_bel_ortusu_kit(g)
	if look.get("outer_style") == "kuyruklu_ceket":
		_kuyruklu_ceket_kit(g)
	if look.get("outer_style") == "gunes_kimono":
		_gunes_kimono_kit(g)
	if look.get("outer_style") == "uzun_trench":
		_uzun_trench_kit(g)
	if look.get("outer_style") == "kutlama_kimono":
		_kutlama_kit(g)
	if look.get("outer_style") == "seytan_kapuson":
		_seytan_kapuson_kit(g)
	if look.get("outer_style") == "kabarik_bluz":
		_kabarik_bluz_kit(g)
	if look.get("outer_style") == "uzun_robe":
		_uzun_robe_kit(g)
	if look.get("outer_style") == "buyuk_kapusonlu":
		_buyuk_kapusonlu_kit(g)
	if look.get("outer_style") == "kisa_kollu_kazak":
		_kisa_kollu_kazak_kit(g)
	if look.get("wide_obi") is Color:
		_wide_obi_kit(g)
	if look.get("front_bow") is Color:
		_front_bow_kit(g)
	if look.get("back_scroll", false):
		_back_scroll_kit(g)
	if look.get("armor_apron") is Color:
		_armor_apron_kit(g)
	if look.get("chest_pockets", false):
		_chest_pockets_kit(g)
	if look.get("outer_style") == "delta_elbise":
		_delta_kit(g)
	if look.get("kok_reisi") is Color:
		_kok_reisi_kit(g)
	if look.get("outer_style") == "kolsuz_kimono":
		_kolsuz_kimono_kit(g)
	if look.get("outer_style") == "takim_yelek":
		_takim_yelek_kit(g)
	if look.get("shimenawa") is Color:
		_shimenawa_kit(g)
	if look.get("outer_style") == "rikudo_cubbe":
		_rikudo_cubbe_kit(g)
	if look.get("jonin_aks") is Color:
		_jonin_aks_kit(g)
	if look.get("outer_style") == "genis_gomlek":
		_genis_gomlek_kit(g)
	if look.get("outer_style") == "kisa_kimono":
		_kisa_kimono_kit(g)
	if look.get("necklace") is Color:
		_necklace_kit(g)
	if look.get("cin_ust") is Color:
		_cin_ust_kit(g)
	if look.get("outer_style") == "kolsuz_palto":
		_kolsuz_palto_kit(g)
	if look.get("outer_style") == "turuncu_ceket":
		_turuncu_ceket_kit(g)
	if look.get("outer_style") == "kisa_bolero":
		_kisa_bolero_kit(g)
	if look.get("bangle") is Color:
		_bangle_kit(g)
	if look.get("outer_style") == "algi_ceket":
		_algi_ceket_kit(g)
	if look.get("outer_style") == "sargi_elbise":
		_sargi_elbise_kit(g)
	if look.get("outer_style") == "kirpik_kapusonlu":
		_kirpik_kapusonlu_kit(g)
	if look.get("outer_style") == "kisa_haori":
		_kisa_haori_kit(g)
	if look.get("outer_style") == "kizil_palto":
		_kizil_palto_kit(g)
	if look.get("outer_style") == "gelinlik":
		_gelinlik_kit(g)
	if look.get("outer_style") == "anbu_palto":
		_anbu_palto_kit(g)
	if look.get("outer_style") == "yagura_ortu":
		_yagura_kit(g)
	if look.get("outer_style") == "cin_elbise":
		_cin_elbise_kit(g)
	if look.get("outer_style") == "sarada_elbise":
		_sarada_elbise_kit(g)
	if look.get("outer_style") == "bel_ceket":
		_bel_ceket_kit(g)
	if look.get("outer_style") == "savas_cubbe":
		_savas_cubbe_kit(g)
	if look.get("outer_style") == "mei_elbise":
		_mei_elbise_kit(g)
	if look.get("outer_style") == "haku_yukata":
		_haku_yukata_kit(g)
	if look.get("outer_style") == "kaguya_cubbe":
		_kaguya_cubbe_kit(g)
	if look.get("outer_style") == "kukla_onluk":
		_kukla_kit(g)
	if look.get("outer_style") == "rokudaime_cubbe":
		_rokudaime_kit(g)
	if look.get("outer_style") in ["kawaki_palto", "kawaki_okul", "kawaki_ruro"]:
		_kawaki_kit(g, look["outer_style"])
	if look.get("outer_style") == "jigen_cubbe":
		_jigen_kit(g)
	if look.get("outer_style") == "sennin_yelek":
		_sennin_yelek_kit(g)
	if look.get("outer_style") == "kaguya_kimono":
		_kaguya_kit(g)
	if look.get("outer_style") == "isshiki_palto":
		_isshiki_kit(g)
	if look.get("outer_style") == "itachi_tunik":
		_itachi_tunik_kit(g)
	if look.get("outer_style") == "edo_cubbe":
		_edo_cubbe_kit(g)
	if look.get("outer_style") == "inojin_ceket":
		_inojin_ceket_kit(g)
	if look.get("hiruzen_aks") is Color:
		_hiruzen_aks_kit(g)
	if look.get("belly_wraps") is Color:
		_belly_wraps_kit(g)
	if look.get("waist_belt") is Color:
		_waist_belt_kit(g)
	if look.get("outer_style") in ["atki", "kisa"] and look.get("outer") is Color:
		# atkı: ense arkasındaki düğümden sırta sarkan, rüzgârda uçuşan iki uç (ikincil hareket)
		var nk = _bp("Neck")
		var bz = _back_z(neck - 0.02)
		for sx in [-1.0, 1.0]:
			dangle_strip("UpperChest", Vector3(nk.x + 0.025 * sx, neck - 0.02, bz - 0.03), Vector3(0.12 * sx, -1.0, -0.25), 0.34, 0.07, look["outer"], 0.18, Vector3(1, 0, 0), 0.006)
		if look.get("scarf_front_tail", false):
			# önden göğse sarkan tek uç (Striker Zabuza): boynun sağ önünden karın üstüne düz iner
			var fz = 0.0
			for v in _body_vs():
				if absf(v.x + 0.07) < 0.03 and absf(v.y - (neck - 0.1)) < 0.04 and v.z > fz:
					fz = v.z
			dangle_strip("UpperChest", Vector3(-0.07, neck - 0.05, fz + 0.035), Vector3(0.0, -1.0, 0.05), 0.3, 0.06, look["outer"], 0.6, Vector3(1, 0, 0), 0.008)
	var hs = look.get("head_style")
	if hs == "kapuson":
		# kapüşonun omuz etek kısmı (gövdeye derili): boyundan omuz başına açılan kumaş; kafa kısmı hood()
		var hk = "kapuson_etek_" + String(look.get("hood", ""))
		_garment(hk, func(): return _loft(g, 1, neck + 0.05, neck - 0.1, 9, func(p): return p.y > neck - 0.17 and absf(p.x) < ua * 1.05,
			func(t, _a): return 0.03 + t * 0.045, 10, func(t, ang): return t < 0.35 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.5))
	var fs = look.get("face_style")
	if fs in []:   # bez/gaz maske artık yüz kabuğu (face_item)
		_garment("maske", func(): return _loft(g, 1, ey - 0.038, neck - 0.03, 10, func(p): return p.y > neck - 0.08 and absf(p.x) < 0.13, flat.call(0.009), 11))
	if look.get("neck_scarf") is Color:
		# boyun atkısı (Striker Konohamaru): yelek yakasının dışında boynu saran kalın bez; kendi rengi için başlık yuvası (10)
		# bu kabuğa özel paletle boyanır (başka giysiyle renk çakışmasın)
		_garment_tinted("boyun_atki", look["neck_scarf"], func(): return _loft(g, 1, neck - 0.05, neck + 0.07, 8, func(p): return absf(p.x) < 0.15, func(t, a): return 0.07 - t * 0.032 + (0.012 if sin(a) > 0.3 else 0.0), 10))
	if look.get("sweater_hem") is Color:
		# uzun kazağın eteği (Striker Han): belden uyluk ortasına yatay kaburgalı kalın örgü
		_garment_tinted("kazak_etek", look["sweater_hem"], func(): return _loft(g, 1, hips + 0.08, hips - 0.22, 16, torso, func(t, _a): return 0.036 + t * 0.03 + 0.006 * absf(sin(t * PI * 9.0)), 10, null, hips - 0.06))
	if look.get("gi_yelek") is Color:
		# kolsuz gi yelek (Striker Han): göğüsten belin altına, omuz ve etek kenarı yırtık dişli
		_garment_tinted("gi_yelek", look["gi_yelek"], func(): return _loft(g, 1, neck - 0.01, hips - 0.03, 14, torso, func(t, _a): return 0.062 + t * 0.012, 10, func(t, ang): return (t < 0.12 and fposmod(ang * 3.0, 1.0) < 0.3) or (t > 0.9 and fposmod(ang * 4.0, 1.0) < (t - 0.9) * 6.0), -99.0, 48))
	if look.get("fur_scarf") is Color:
		# kalın kürk atkı (Striker Celebratory): boynu ve omuzları saran kabarık beyaz kürk (açıya göre tüylü dalga)
		_garment_tinted("kurk_atki", look["fur_scarf"], func(): return _loft(g, 1, neck - 0.09, neck + 0.05, 9, func(p): return absf(p.x) < 0.2, func(t, a): return 0.075 - t * 0.03 + 0.012 * absf(sin(a * 9.0 + t * 7.0)), 10, func(t, ang): return t > 0.4 and absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.25))
	if look.get("bell_cuffs") is Color:
		# çan manşet ve paçalar (Striker Code): bilekte açılan geniş manşet, baldır altında açılan geniş paça
		var bhx = absf(_bp("LeftHand").x)
		for sx in [-1.0, 1.0]:
			_garment_tinted("can_manset%d" % int(sx), look["bell_cuffs"], func(): return _loft(g, 0, (bhx - 0.2) * sx, (bhx - 0.035) * sx, 9, func(p): return signf(p.x) == sx and p.y > neck - 0.32, func(t, _a): return 0.016 + t * t * 0.05, 10, null, -99.0, 20))
			var bkx = _bp(("Left" if sx > 0.0 else "Right") + "LowerLeg").x
			_garment_tinted("can_paca%d" % int(sx), look["bell_cuffs"], func(): return _loft(g, 1, knee - 0.16, ank + 0.02, 9, func(p): return signf(p.x) == sx and absf(p.x - bkx) < 0.095, func(t, a): return (0.03 + t * 0.03) * (1.0 if cos(a) * sx > -0.3 else 0.5), 10, null, -99.0, 20))
	if look.get("elbow_pads") is Color:
		var pel = absf(_bp("LeftLowerArm").x)
		for sx in [-1.0, 1.0]:
			_garment_tinted("dirseklik%d" % int(sx), look["elbow_pads"], func(): return _loft(g, 0, (pel - 0.09) * sx, (pel + 0.07) * sx, 8, func(p): return signf(p.x) == sx and p.y > neck - 0.32, flat.call(0.014), 10, null, -99.0, 20))
	if look.get("net_pads", false):
		var nel = absf(_bp("LeftLowerArm").x)
		for sx in [-1.0, 1.0]:
			_garment("file_dirsek%d" % int(sx), func(): return _loft(g, 0, (nel - 0.07) * sx, (nel + 0.06) * sx, 8, func(p): return signf(p.x) == sx and p.y > neck - 0.32, flat.call(0.008), 9, null, -99.0, 20))
			_garment("file_diz%d" % int(sx), func(): return _loft(g, 1, knee + 0.08, knee - 0.08, 8, func(p): return signf(p.x) == sx and absf(p.x) < 0.3, flat.call(0.009), 9, null, -99.0, 20))
	var gd = look.get("guards")
	if gd in ["kol", "ikisi"]:
		for sx in [-1.0, 1.0]:
			_garment("kolluk%d_%d%s" % [int(sx), int(look.get("guard_long", false)), "a" if look.get("guard_ankle", false) else ""], func(): return _loft(g, 0, ((absf(_bp("LeftLowerArm").x) + 0.03) if look.get("guard_long", false) else (ha - 0.17)) * sx, (ha + (0.01 if look.get("guard_ankle", false) else -0.05)) * sx, 10 if look.get("guard_long", false) else 6, func(p): return signf(p.x) == sx and p.y > neck - 0.32, flat.call(0.018), 9, null, -99.0, 16))
	if gd in ["bacak", "ikisi"]:
		for sx in [-1.0, 1.0]:
			if look.get("guard_ankle", false):
				# bilek tozluğu (Striker Zabuza): bileği ve baldırın altını saran kalın örgü ısıtıcı
				_garment("tozluk%d" % int(sx), func(): return _loft(g, 1, ank + 0.2, ank + 0.02, 7, func(p): return signf(p.x) == sx and absf(p.x) < 0.35, func(t, _a): return 0.03 + 0.006 * sin(t * PI), 9, null, -99.0, 16))
				continue
			_garment("kaval%d" % int(sx), func(): return _loft(g, 1, knee - 0.05, ank + 0.08, 8, func(p): return signf(p.x) == sx and absf(p.x) < 0.35,
				func(_t, ang): return 0.046 if absf(wrapf(ang - PI * 0.5, -PI, PI)) < 1.3 else 0.036, 9, null, -99.0, 16))   # paça kıvrımı taşmasın
	if look.get("long_skirt") is Color:
		_stripe_skirt_kit(g)
	if look.get("gi_yelek") is Color:
		_gi_yelek_kit(g)
	if look.get("drape_sash") is Color:
		_drape_sash_kit(g)
	if look.get("neck_scarf") is Color or look.get("armband") is Color:
		_boyun_atki_kit(g)
	if look.get("kg") is Dictionary or look.get("pleat_skirt", false):   # hakama/etek kurulduktan sonra (bağlar onların kabuğuna derilir)
		_keiko_kit(g)
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
	var vs: PackedVector3Array = _body_vs()
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


## ---- Yüzeye oturan derili 3B parçalar (SurfaceKit) -------------------------------------------------
## Kaynak kabuğun (yelek) gerçek köşelerinden konum + normal + kemik ağırlıkları alınır; her parça köşesi en yakın kabuk
## köşesinin ağırlıklarını taşır -> kabukla birlikte eğilir/bükülür, hiçbir açıdan havada kalmaz, kumaşın içine girmez.
var _sk := {}

func _sk_begin(src: ArrayMesh) -> bool:
	if src == null:
		return false
	var a = src.surface_get_arrays(0)
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var used := {}
	for i in idx:
		used[i] = true
	var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var N: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var B: PackedInt32Array = a[Mesh.ARRAY_BONES]
	var W: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
	var per = B.size() / maxi(1, V.size())
	var vv = PackedVector3Array(); var nn = PackedVector3Array(); var bb = []; var ww = []
	for i in used.keys():
		vv.append(V[i]); nn.append(N[i].normalized())
		bb.append(B.slice(i * per, i * per + per)); ww.append(W.slice(i * per, i * per + per))
	_sk = {"v": vv, "n": nn, "b": bb, "w": ww, "per": per, "ov": PackedVector3Array(), "on": PackedVector3Array(), "oc": PackedColorArray(),
		"ob": PackedInt32Array(), "ow": PackedFloat32Array(), "oi": PackedInt32Array(), "custom": a[Mesh.ARRAY_CUSTOM0] != null}
	return true


## Yüzey noktası: o ön/arka yönde, verilen (x, y) civarındaki en dış kabuk köşesi -> [konum, normal, köşe indeksi]
func _sk_hit(x: float, y: float, front := true, rad := 0.02) -> Array:
	var V: PackedVector3Array = _sk["v"]
	var best = -1
	var bz = -99.0
	for i in V.size():
		var q = V[i]
		if absf(q.x - x) < rad and absf(q.y - y) < rad:
			var z = q.z if front else -q.z
			if z > bz:
				bz = z
				best = i
	if best < 0:
		return []
	return [V[best], (_sk["n"] as PackedVector3Array)[best], best]


func _sk_nearest(p: Vector3) -> int:
	var V: PackedVector3Array = _sk["v"]
	var best = 0
	var bd = 1e9
	for i in V.size():
		var d = V[i].distance_squared_to(p)
		if d < bd:
			bd = d
			best = i
	return best


## Kutu: merkez c, eksenler (u, v, n) yarı boyutlarıyla ölçekli; her köşe en yakın kabuk köşesinin ağırlıklarını alır
func _sk_box(c: Vector3, u: Vector3, v: Vector3, n: Vector3, col: Color) -> void:
	var corners = []
	for sz in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sx in [-1.0, 1.0]:
				corners.append(c + u * sx + v * sy + n * sz)
	var faces = [[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4], [2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5]]
	var fn = [-n, n, -v, v, -u, u]
	for f in 6:
		var base = (_sk["ov"] as PackedVector3Array).size()
		for k in 4:
			var q: Vector3 = corners[faces[f][k]]
			_sk["ov"].append(q)
			_sk["on"].append(fn[f].normalized())
			_sk["oc"].append(col)
			var j = _sk_nearest(q)
			_sk["ob"].append_array(_sk["b"][j])
			_sk["ow"].append_array(_sk["w"][j])
		_sk["oi"].append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))


## Yüzeye yaslı kutu: (x, y) noktasındaki kabuk yüzeyinde, yüzey normaline dik; w genişlik, h boy, d kalınlık (yüzeyden dışarı)
func _sk_plate(x: float, y: float, w: float, h: float, d: float, col: Color, lift := 0.0, front := true) -> bool:
	var hit = _sk_hit(x, y, front)
	if hit.is_empty():
		return false
	var n: Vector3 = hit[1]
	var u = Vector3.UP.cross(n).normalized() * (1.0 if front else -1.0)
	var v = n.cross(u).normalized() * (1.0 if front else -1.0)
	var c: Vector3 = hit[0] + n * (lift + d * 0.5)
	_sk_box(c, u * w * 0.5, v * h * 0.5, n * d * 0.5, col)
	return true


func _sk_end(g: Dictionary) -> MeshInstance3D:
	if (_sk["oi"] as PackedInt32Array).is_empty():
		return null
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _sk["ov"]
	arr[Mesh.ARRAY_NORMAL] = _sk["on"]
	arr[Mesh.ARRAY_COLOR] = _sk["oc"]
	arr[Mesh.ARRAY_BONES] = _sk["ob"]
	arr[Mesh.ARRAY_WEIGHTS] = _sk["ow"]
	arr[Mesh.ARRAY_INDEX] = _sk["oi"]
	if _sk.has("ouv") and (_sk["ouv"] as PackedVector2Array).size() == (_sk["ov"] as PackedVector3Array).size():
		arr[Mesh.ARRAY_TEX_UV] = _sk["ouv"]
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if int(_sk["per"]) == 8 else 0)
	var mi = MeshInstance3D.new()
	mi.mesh = m
	skel.add_child(mi)
	mi.skin = body_mesh.skin
	mi.skeleton = mi.get_path_to(skel)
	mi.material_override = Props.toon()
	_sk = {}
	return mi




## Sürekli bant (iç dikiş yok): noktalar boyunca, her noktada dış yön (out) ve genişlik yönü (wd); kalınlık d, genişlik h.
## shift: bandın genişlik yönünde kayması (yaka yukarı taşar)
func _sk_band(pts: Array, outs: Array, wd: Vector3, h: float, d: float, col: Color, closed := false, shift := 0.0) -> void:
	var n = pts.size()
	if n < 2:
		return
	var base = (_sk["ov"] as PackedVector3Array).size()
	var add_v = func(q: Vector3, nrm: Vector3, anchor: Vector3):
		_sk["ov"].append(q); _sk["on"].append(nrm); _sk["oc"].append(col)
		var j = _sk_nearest(anchor)
		_sk["ob"].append_array(_sk["b"][j]); _sk["ow"].append_array(_sk["w"][j])
	# her nokta için 3 yüz x 2 köşe: dış(üst, alt), üst(iç, dış), alt(iç, dış)
	for i in n:
		var p0: Vector3 = pts[i]
		var o: Vector3 = outs[i]
		var hi = p0 + wd * (h * 0.5 + shift)
		var lo = p0 - wd * (h * 0.5 - shift)
		add_v.call(hi + o * d, o, p0); add_v.call(lo + o * d, o, p0)
		add_v.call(hi, wd, p0); add_v.call(hi + o * d, wd, p0)
		add_v.call(lo + o * d, -wd, p0); add_v.call(lo, -wd, p0)
	var segs = n if closed else n - 1
	for i in segs:
		var a = base + i * 6
		var b = base + ((i + 1) % n) * 6
		for f in 3:
			var a0 = a + f * 2; var a1 = a0 + 1; var b0 = b + f * 2; var b1 = b0 + 1
			_sk["oi"].append_array(PackedInt32Array([a0, b0, b1, a0, b1, a1]))
			_sk["oi"].append_array(PackedInt32Array([a0, b1, b0, a0, a1, b1]))   # çift yüz (sarım yönünden bağımsız görünür)

## Kabuk üzerinde halka/yay: eksen (axis: 0=x, 1=y) etrafında, o kesitteki en dış kabuk noktalarından geçen bant.
## at: kesitin eksen değeri, h: bant genişliği (eksen boyunca), d: kalınlık, a0..a1: açı aralığı (axis=1: 0 önde; axis=0: 0 yukarı)
func _sk_ring(axis: int, at: float, h: float, d: float, col: Color, a0 := -PI, a1 := PI, bins := 36, lift := 0.0, side_sel := 0.0, shift := 0.0, max_r := 9.0) -> void:
	var V: PackedVector3Array = _sk["v"]
	var pts = []
	var c = Vector3.ZERO
	var cn = 0
	for q in V:
		if absf(q[axis] - at) < 0.012 and (side_sel == 0.0 or signf(q.x) == side_sel) and (max_r > 8.0 or Vector2(q.x, q.z).length() < max_r + 0.05):
			c += q; cn += 1
	if cn < 6:
		return
	c /= cn
	c[axis] = at
	var ua = Vector3.BACK if axis == 1 else Vector3.UP
	var ub = Vector3.RIGHT if axis == 1 else Vector3.BACK
	var ax = Vector3.UP if axis == 1 else Vector3.RIGHT
	for i in bins + 1:
		var a = lerpf(a0, a1, float(i) / bins)
		var dir = ua * cos(a) + ub * sin(a)
		var best = -1.0
		for q in V:
			if absf(q[axis] - at) < 0.014 and (side_sel == 0.0 or signf(q.x) == side_sel):
				var dq = q - c
				dq[axis] = 0.0
				var r = dq.length()
				if r > 0.01 and r < max_r and dq.normalized().dot(dir) > 0.97 and r > best:
					best = r
		pts.append(null if best < 0.0 else c + dir * (best + lift))
	if max_r < 8.0:
		# yaka: boynun çevresinde eksik açılar (yeleğin önü açık) ortalama yarıçapla doldurulur -> kesintisiz halka
		var rs = 0.0; var rn = 0
		for q in pts:
			if q != null:
				var dq: Vector3 = q - c
				dq[axis] = 0.0
				rs += dq.length(); rn += 1
		if rn > 0:
			for i in pts.size():
				if pts[i] == null:
					var a = lerpf(a0, a1, float(i) / bins)
					pts[i] = c + (ua * cos(a) + ub * sin(a)) * (rs / rn)
	var run = []
	var routs = []
	var full = absf(a1 - a0) > TAU - 0.01
	for i in pts.size():
		if pts[i] == null:
			if run.size() > 1:
				_sk_band(run, routs, ax, h, d, col, false, shift)
			run = []; routs = []
			continue
		var out: Vector3 = pts[i] - c
		out[axis] = 0.0
		run.append(pts[i]); routs.append(out.normalized())
	if run.size() > 1:
		_sk_band(run, routs, ax, h, d, col, full and run.size() == pts.size(), shift)


## Kabuk üzerinde düz çizgi zinciri (fermuar): x sabit, y0'dan y1'e; yüzey derinliği komşu köşelerden yumuşatılır
func _sk_strip(x: float, y0: float, y1: float, w: float, d: float, col: Color, n := 28) -> void:
	var V: PackedVector3Array = _sk["v"]
	var zs = []
	for k in n + 1:
		var y = lerpf(y0, y1, float(k) / n)
		var zz = -9.0
		for q in V:
			if absf(q.x - x) < 0.04 and absf(q.y - y) < 0.025 and q.z > zz:
				zz = q.z
		zs.append(zz)
	for k in n + 1:   # boşlukları komşulardan doldur (fermuar kesilmesin)
		if zs[k] < -8.0:
			var a = k - 1
			while a >= 0 and zs[a] < -8.0:
				a -= 1
			var b = k + 1
			while b <= n and zs[b] < -8.0:
				b += 1
			if a >= 0 and b <= n:
				zs[k] = lerpf(zs[a], zs[b], float(k - a) / (b - a))
			elif a >= 0:
				zs[k] = zs[a]
			elif b <= n:
				zs[k] = zs[b]
	for k in n + 1:   # yumuşat: komşuların en önü (göğüs çukurunda gömülmesin)
		var m = zs[k]
		for j in [k - 1, k + 1]:
			if j >= 0 and j <= n:
				m = maxf(m, zs[j] - 0.006)
		zs[k] = m
	var run = []
	var outs = []
	for k in n + 1:
		if zs[k] < -8.0:
			continue
		var p0 = Vector3(x, lerpf(y0, y1, float(k) / n), zs[k])
		var kn = mini(k + 1, n) if k < n else k
		var kp = maxi(k - 1, 0)
		var t = Vector3(0, lerpf(y0, y1, float(kn) / n) - lerpf(y0, y1, float(kp) / n), zs[kn] - zs[kp])
		var nrm = Vector3(0, -t.z, t.y).normalized()
		if nrm.z < 0.0:
			nrm = -nrm
		run.append(p0); outs.append(nrm)
	_sk_band(run, outs, Vector3.RIGHT, w, d, col)


## Parşömen cep takımı: bölgedeki kabuk köşelerinin ortalama konumu/normali tek bir çerçeve; taban + 3 hücre + kapak bu çerçevede
func _sk_pocket(cx: float, cy: float, w: float, h: float, vc: Color, dk: Color) -> void:
	var V: PackedVector3Array = _sk["v"]
	var N: PackedVector3Array = _sk["n"]
	var c = Vector3.ZERO; var nn = Vector3.ZERO; var cnt = 0
	var zmax = -9.0
	for i in V.size():
		var q = V[i]
		if q.z > 0.0 and absf(q.x - cx) < w * 0.5 and absf(q.y - cy) < h * 0.5:
			c += q; nn += N[i]; cnt += 1
			zmax = maxf(zmax, q.z)
	if cnt < 3:
		return
	c /= cnt
	var n = nn.normalized()
	if n.z < 0.3:
		n = (n + Vector3.BACK).normalized()
	c = Vector3(cx, cy, zmax - 0.004)   # en dış noktaya yaslı (gömülmez, boşluk kalmaz)
	var u = Vector3.UP.cross(n).normalized()
	var v = n.cross(u).normalized()
	_sk_box(c + n * 0.007, u * w * 0.5, v * h * 0.5, n * 0.007, dk)
	for k in 3:
		var x = (k - 1) * w / 3.0
		_sk_box(c + u * x - v * 0.006 + n * 0.02, u * (w / 3.0 - 0.008) * 0.5, v * (h - 0.02) * 0.5, n * 0.011, vc.darkened(0.04))
	_sk_box(c + v * (h * 0.5 - 0.009) + n * 0.024, u * (w + 0.004) * 0.5, v * 0.009, n * 0.012, dk.darkened(0.12))

## Düz panel (önlük vb.): bölgenin en ön noktasına yaslı tek çerçevede yamuk; satır satır kutular aynı düzlemde (kırık görünmez)
func _sk_panel(cx: float, y_top: float, h: float, w_top: float, w_bot: float, d: float, col: Color) -> void:
	var V: PackedVector3Array = _sk["v"]
	var zmax = -9.0
	for q in V:
		if q.z > 0.0 and absf(q.x - cx) < w_top * 0.5 and q.y < y_top + 0.02 and q.y > y_top - h:
			zmax = maxf(zmax, q.z)
	if zmax < -8.0:
		return
	var rows = 6
	for k in rows:
		var t = (k + 0.5) / rows
		var w = lerpf(w_top, w_bot, t)
		var y = y_top - h * t
		_sk_box(Vector3(cx, y, zmax + d * 0.5 + 0.004), Vector3.RIGHT * w * 0.5, Vector3.UP * h / rows * 0.52, Vector3.BACK * d * 0.5, col)


## Konoha yeleği (set1.png): göğüste 2x2 parşömen cebi (üst sıra küçük, alt büyük), boydan boya fermuar,
## yeleğin üst kenarında dik yaka, omuzlarda yassı omuzluk — hepsi yelek kabuğunun yüzeyinden
## Yelek ayrıntısı cinsiyet + stil + renge göre hep aynı çıkar: bir kez üretilip paylaşılır
## (her ninja için baştan ~105 ms sürüyordu; köyde devriye/çatı ninjası doğarken takılma yapıyordu)
static var _vest_kit_cache := {}
func _vest_kit(src: ArrayMesh, g: Dictionary) -> void:
	var ck = "%s|%d|%s" % [look["gender"], int(look.get("vest_style", 0)), Color(look["vest"]).to_html()]
	if _vest_kit_cache.has(ck):
		var cm = _vest_kit_cache[ck]
		if cm != null:
			var cmi = MeshInstance3D.new()
			cmi.mesh = cm
			skel.add_child(cmi)
			cmi.skin = body_mesh.skin
			cmi.skeleton = cmi.get_path_to(skel)
			cmi.material_override = Props.toon()
		return
	if not _sk_begin(src):
		return
	var vs = int(look.get("vest_style", 0))
	var vc: Color = look["vest"]
	var dk = vc.darkened(0.18)
	var zipc = Color(0.85, 0.85, 0.83)
	var neck = _bp("Neck").y
	var hips = _bp("Hips").y
	var ch = _bp("UpperChest").y
	var top_y = neck - 0.045
	var bot_y = hips + 0.05
	var sh_x = _bp("LeftUpperArm").x * 0.82
	match vs:
		0:   # Konoha (set1.png): fermuar, 2x2 parşömen cebi, dik yaka, etek bandı, yassı omuzluk
			if look.get("vest_open", false):   # fermuarı açık: ortası boş, iki kenarda fermuar dişi
				for zsx in [-1.0, 1.0]:
					_sk_strip(0.05 * zsx, top_y + 0.02, bot_y + 0.01, 0.008, 0.006, zipc, 34)
			else:
				_sk_strip(0.0, top_y + 0.02, bot_y + 0.01, 0.012, 0.006, zipc, 34)
			for sx in [-1.0, 1.0]:
				for row in [[ch - 0.075, 0.1, 0.075], [ch - 0.18, 0.115, 0.095]]:
					_sk_pocket(0.09 * sx, row[0], row[1], row[2], vc, dk)
			_sk_ring(1, top_y + 0.003, 0.085, 0.02, vc.darkened(0.05), -PI, PI, 48, 0.004, 0.0, 0.04, 0.115)
			_sk_ring(1, bot_y + 0.02, 0.035, 0.008, dk, -PI, PI, 40, 0.0)
			for sx in [-1.0, 1.0]:
				_sk_ring(0, sh_x * sx, 0.075, 0.012, vc.darkened(0.03), -0.55, 1.0, 16, 0.0, sx)
		1:   # Suna (sunaset.png): geniş kanat omuzluk (üstünde açık şerit), fermuar, karında iki cep takımı, dik yaka
			_sk_strip(0.0, top_y + 0.02, bot_y + 0.01, 0.012, 0.006, zipc, 34)
			for sx in [-1.0, 1.0]:
				_sk_pocket(0.085 * sx, ch - 0.2, 0.11, 0.085, vc, dk)
				_sk_ring(0, sh_x * sx * 1.05, 0.16, 0.03, vc.darkened(0.06), -0.95, 1.2, 20, 0.01, sx)   # geniş kanat omuzluk
				_sk_plate(sh_x * sx * 0.95, top_y - 0.035, 0.05, 0.022, 0.05, Color(0.84, 0.86, 0.88))   # omuzluğun önünde açık şerit
			_sk_ring(1, top_y + 0.003, 0.075, 0.02, vc.darkened(0.04), -PI, PI, 48, 0.004, 0.0, 0.035, 0.115)
			_sk_ring(1, bot_y + 0.02, 0.035, 0.008, dk, -PI, PI, 40, 0.0)
		2:   # Kiri (mistset.png): kutu omuzluk, belde kalın bant + yan tokalar, yatay plaka çizgileri (kabartma bant), önde önlük
			for sx in [-1.0, 1.0]:
				_sk_ring(0, sh_x * sx * 1.02, 0.11, 0.02, dk, -0.8, 1.1, 10, 0.004, sx)
				_sk_plate(0.15 * sx, ch - 0.22, 0.05, 0.03, 0.016, dk.darkened(0.15))
			_sk_ring(1, ch - 0.22, 0.03, 0.01, dk, -PI, PI, 40, 0.0)
			_sk_ring(1, ch - 0.1, 0.012, 0.005, vc.darkened(0.1), -1.2, 1.2, 24, 0.0)
			_sk_ring(1, bot_y + 0.02, 0.03, 0.008, dk, -PI, PI, 40, 0.0)
		3:   # Kumo (cloudset.png): tek omuz askısı + toka, sağ omuzdan sol böğre çapraz kabartma dikişler, göğüste şerit cep
			_sk_ring(0, sh_x * 0.85, 0.065, 0.012, vc.darkened(0.08), -0.9, 1.0, 14, 0.004, 1.0)   # sol omuz askısı
			_sk_plate(sh_x * 0.8, ch + 0.02, 0.045, 0.06, 0.014, Color(0.7, 0.72, 0.75))   # askı tokası
			for off in [-0.02, 0.09]:
				var pts = []
				var outs = []
				for k in 20:
					var t = k / 19.0
					var y = lerpf(ch + 0.04, bot_y + 0.04, t)
					var x = (y - ch) * 0.75 + off
					var hit = _sk_hit(x, y, true, 0.03)
					if not hit.is_empty():
						pts.append(Vector3(x, y, hit[0].z)); outs.append(hit[1])
				for it in 3:   # yumuşat: basamaklı görünmesin
					var sm = pts.duplicate()
					for i in range(1, pts.size() - 1):
						sm[i] = Vector3(pts[i].x, pts[i].y, maxf(pts[i].z, (pts[i - 1].z + pts[i + 1].z) * 0.5))
					pts = sm
				if pts.size() > 1:
					_sk_band(pts, outs, Vector3(0.6, 0.8, 0).normalized(), 0.008, 0.005, vc.darkened(0.25))
			for k in 4:
				_sk_plate(0.035 + k * 0.014, ch - 0.04, 0.008, 0.04, 0.008, vc.darkened(0.3))
			_sk_ring(1, bot_y + 0.02, 0.03, 0.008, vc.darkened(0.12), -PI, PI, 40, 0.0)
		4:   # Iwa (rockset.png): düğmeli yassı omuzluk, fermuar, karında büyük dikdörtgen cep, dik yaka
			_sk_strip(0.0, top_y + 0.02, bot_y + 0.01, 0.012, 0.006, zipc, 34)
			for sx in [-1.0, 1.0]:
				_sk_ring(0, sh_x * sx, 0.08, 0.014, dk, -0.6, 1.0, 14, 0.004, sx)
				_sk_plate(sh_x * sx * 0.92, top_y - 0.005, 0.02, 0.02, 0.022, Color(0.75, 0.72, 0.66))   # omuz düğmesi
			_sk_plate(0.0, ch - 0.2, 0.2, 0.09, 0.026, dk)   # karın cebi
			_sk_plate(0.0, ch - 0.16, 0.21, 0.018, 0.03, dk.darkened(0.15))   # cep kapağı
			_sk_ring(1, top_y + 0.003, 0.07, 0.018, vc.darkened(0.05), -PI, PI, 48, 0.004, 0.0, 0.035, 0.115)
			_sk_ring(1, bot_y + 0.02, 0.035, 0.008, dk, -PI, PI, 40, 0.0)
		12:   # ANBU düz plaka (anbu.png): önde boydan dikiş, belde kalın kabarık etek bandı, omuzdan geçen iki askı + tokalar
			var pt = ch + 0.035   # plakanın üst kenarı (koltuk altı hizası; üstü shader ile kesik)
			_sk_strip(0.0, pt, bot_y + 0.06, 0.006, 0.004, vc.darkened(0.45), 30)
			_sk_ring(1, bot_y + 0.035, 0.05, 0.01, vc.darkened(0.04), -PI, PI, 48, 0.0)
			_sk_ring(1, pt + 0.004, 0.014, 0.008, vc.darkened(0.12), -PI, PI, 40, 0.0, 0.0, 0.0, absf(sh_x) * 0.95)   # kol köşeleri halkaya girmesin
			for sx in [-1.0, 1.0]:
				# askı: yelek kabuğunun omuz kesitinden, kabuğun gövdeden açıklığı kadar içeri çekilir (omuzda havada durmasın)
				_sk_ring(0, 0.1 * sx, 0.05, 0.014, vc.darkened(0.06), -1.75, 1.75, 24, -0.038, sx)
				_sk_plate(0.1 * sx, pt + 0.012, 0.05, 0.022, 0.016, vc.darkened(0.15))   # askı tokası (ön)
	var vmi = _sk_end(g)
	_vest_kit_cache[ck] = vmi.mesh if vmi else null


## Kunai kılıfı (set1.png): sağ uyluğun dış-önünde siyah kılıf + uyluğu saran iki beyaz bant; uyluk yüzeyi köşe taramasıyla bulunur
## (eskiden sabit konumdaydı: pantolon kabuğunun içinde kalıp görünmüyordu)
static var _holster_rings := {}   # cinsiyet|y -> uyluk kesiti (gövde tabanı aynı: her karakterde 48 tam tarama ~19 ms'ydi)


func _thigh_holster() -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	# her kıyafette/çocukta olmasın: kanonda kılıf alnında bandı olan ninjanın teçhizatı (Akademi öğrencisi, çocuk, sivil
	# takmaz); kıyafet seti "holster": false/true ile ezebilir
	var want = look.get("holster", null)
	if want == null:
		want = String(look.get("age", "adult")) != "child" and look.get("band") != null
	if not bool(want):
		return
	var vs: PackedVector3Array = _body_vs()
	var hipb = _bp("RightUpperLeg")
	var kn = _bp("RightLowerLeg")
	var pad = 0.026   # pantolon kabuğu (kumaş kabuğu yoksa)
	# kayış gerçek kumaşın üstüne otursun: bol pantolonda (çoğu set) kayış kumaşın içinde kalıp kesik kesik görünüyordu
	var gk = ""
	var cloth_vs := PackedVector3Array()
	for c in skel.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Cloth") and c.mesh is ArrayMesh and c.visible:
			gk += "|%d" % c.mesh.get_instance_id()
			for si in c.mesh.get_surface_count():
				cloth_vs.append_array(c.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX])
	if cloth_vs.size() > 0:
		vs = vs.duplicate()
		vs.append_array(cloth_vs)
		pad = 0.012   # bol kumaşın kıvrımlarında kayış içeride kalmasın
	var ring0 = func(y: float) -> Array:
		# o yükseklikte uyluk kesiti: merkez + açı başına yarıçap
		var cx = 0.0; var cz = 0.0; var cn = 0
		for v in vs:
			if absf(v.y - y) < 0.02 and v.x < -0.004 and absf(v.x - hipb.x) < 0.14:
				cx += v.x; cz += v.z; cn += 1
		if cn == 0:
			return []
		var c = Vector3(cx / cn, y, cz / cn)
		# açı başına en dış yarıçap; köşe düşmeyen açılar komşulardan doldurulur (eskiden 5 cm'de kalıp kumaşın içine
		# gömülüyor, kayış kesik kesik/ayrık bloklar gibi görünüyordu)
		var rad: Array = []
		for i in 24:
			var a = TAU * i / 24.0
			var d = Vector3(sin(a), 0, cos(a))
			var best = -1.0
			for v in vs:
				if absf(v.y - y) < 0.02 and v.x < -0.004 and absf(v.x - hipb.x) < 0.14:
					var h = Vector2(v.x - c.x, v.z - c.z)
					var r = h.length()
					if r > 0.01 and Vector2(d.x, d.z).dot(h / r) > 0.93 and r > best:
						best = r
			rad.append(best)
		var mx = 0.05
		for r in rad:
			mx = maxf(mx, r)
		for i in 24:
			if rad[i] < 0.0:
				var acc = 0.0; var cnt = 0
				for o in [-2, -1, 1, 2]:
					var q = rad[(i + o + 24) % 24]
					if q > 0.0:
						acc += q; cnt += 1
				rad[i] = acc / cnt if cnt > 0 else mx
		var out = []
		for i in 24:
			# hafif yumuşatma: tek köşe çıkıntısı kayışı kırmasın
			var r = maxf(rad[i], (rad[(i + 23) % 24] + rad[i] * 2.0 + rad[(i + 1) % 24]) * 0.25)
			var a = TAU * i / 24.0
			out.append(c + Vector3(sin(a), 0, cos(a)) * (r + pad))
		return out
	var gkey = String(look.get("gender", "m")) + gk
	var ring = func(y: float) -> Array:
		var k = "%s|%.4f" % [gkey, y]
		if not _holster_rings.has(k):
			_holster_rings[k] = ring0.call(y)
		return _holster_rings[k]
	var m = MB.new()
	var white = Color(0.92, 0.92, 0.9)
	var yb = [hipb.y - (hipb.y - kn.y) * 0.3, hipb.y - (hipb.y - kn.y) * 0.45]
	var outer_pt = Vector3.ZERO
	for y in yb:
		var pts: Array = ring.call(y)
		if pts.is_empty():
			continue
		var hi = 21   # kılıf dış-önde (a=315°); kayışlar onun ÜSTÜNDEN geçer (kılıf bacağa bağlı görünsün)
		var lift = func(q: int) -> Vector3:
			var pp: Vector3 = pts[q % pts.size()]
			var dd = absi(((q - hi) % 24 + 36) % 24 - 12)
			var dirv = Vector3(pp.x - hipb.x, 0, pp.z - hipb.z).normalized()
			return pp + dirv * (0.034 if dd <= 1 else (0.018 if dd == 2 else 0.0))
		for i in pts.size():
			var p0: Vector3 = lift.call(i)
			var p1: Vector3 = lift.call(i + 1)
			var t = p1 - p0
			var nrm = Vector3(t.z, 0, -t.x).normalized()
			if nrm.dot(p0 - Vector3(hipb.x, y, p0.z)) < 0.0 and false:
				nrm = -nrm
			var bb = Basis(t * 1.15, Vector3.UP * 0.014, nrm * 0.005)   # ince bez kayış (2.4 cm kalın beyaz blok gibiydi)
			if bb.determinant() < 0.0:   # ters (sol el) taban yüzleri içe çevirip kayışı saydam gösteriyordu
				bb.z = -bb.z
			m.add_xf("box", Transform3D(bb, (p0 + p1) * 0.5), white)
		outer_pt = outer_pt + pts[21 % pts.size()]   # dış-ön (kayış kaldırma noktasıyla aynı)
	if outer_pt != Vector3.ZERO:
		outer_pt /= 2.0
		var od = Vector3(outer_pt.x - hipb.x, 0, outer_pt.z - hipb.z).normalized()
		var bas = Basis(Vector3.UP.cross(od).normalized(), Vector3.UP, od)
		var black = Color(0.1, 0.1, 0.12)
		m.add_xf("box", Transform3D(bas.scaled(Vector3(0.07, 0.11, 0.03)), outer_pt + od * 0.016 + Vector3(0, -0.012, 0)), black)
		m.add_xf("box", Transform3D(bas.scaled(Vector3(0.074, 0.028, 0.034)), outer_pt + od * 0.018 + Vector3(0, 0.048, 0)), black.lightened(0.08))   # kapak
	_mesh_on("RightUpperLeg", m.build(Props.toon()), Transform3D.IDENTITY)


## Gövde + kumaş kabuğu köşeleri (üste giyilenler kumaşın üstüne otursun)
func _wear_vs() -> PackedVector3Array:
	var vs: PackedVector3Array = _body_vs().duplicate()
	for c in skel.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Cloth") and c.mesh is ArrayMesh and c.visible:
			for si in c.mesh.get_surface_count():
				vs.append_array(c.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX])
	return vs


## y yüksekliğinde sel(v) köşelerinin kesiti: n açıda en dış yarıçap (+pad), yumuşatılmış
func _wear_ring(vs: PackedVector3Array, y: float, sel: Callable, n: int, pad: float, cen = null) -> Array:
	var c: Vector3
	if cen != null:
		c = Vector3(cen.x, y, cen.z)
	else:
		var cx = 0.0; var cz = 0.0; var cn = 0
		for v in vs:
			if absf(v.y - y) < 0.02 and sel.call(v):
				cx += v.x; cz += v.z; cn += 1
		if cn == 0:
			return []
		c = Vector3(cx / cn, y, cz / cn)
	var rad = []
	for i in n:
		rad.append(-1.0)
	for v in vs:
		if absf(v.y - y) < 0.02 and sel.call(v):
			var h = Vector2(v.x - c.x, v.z - c.z)
			var r = h.length()
			if r < 0.005 or r > 0.2:
				continue
			var i = int(round(fposmod(atan2(h.x, h.y), TAU) / TAU * n)) % n
			rad[i] = maxf(rad[i], r)
	var avg = 0.0; var an = 0
	for r in rad:
		if r > 0.0:
			avg += r; an += 1
	if an == 0:
		return []
	avg /= an
	for i in n:
		if rad[i] <= 0.0:
			rad[i] = avg
	for k in 3:   # yumuşat (köşeli görünmesin)
		var r2 = rad.duplicate()
		for i in n:
			r2[i] = maxf(rad[i], (rad[(i + n - 1) % n] + rad[i] * 2.0 + rad[(i + 1) % n]) * 0.25)
		rad = r2
	var out = []
	for i in n:
		var a = TAU * i / n
		out.append(c + Vector3(sin(a), 0, cos(a)) * (rad[i] + pad))
	return out


## Halkalar arası tüp; her 'stripe' dilimde bir koyu dikiş sütunu
func _ring_tube(m: MB, rings: Array, col: Color, stripe: int, cen: Vector3) -> void:
	for r in range(rings.size() - 1):
		var A: Array = rings[r]
		var B: Array = rings[r + 1]
		if A.is_empty() or B.is_empty():
			continue
		var n = A.size()
		for i in n:
			var j = (i + 1) % n
			var cc = col.darkened(0.32) if stripe > 0 and i % stripe == 0 else col
			var mid = (A[i] + A[j]) * 0.5
			var nrm = Vector3(mid.x - cen.x, 0, mid.z - cen.z).normalized()
			var arr = []
			arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([A[i], B[i], B[j], A[i], B[j], A[j]])
			arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([nrm, nrm, nrm, nrm, nrm, nrm])
			arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 3, 4, 5])
			m.add_arrays(arr, Transform3D.IDENTITY, cc)


## Ağırlıklı tozluk (ref lee.png, Gōken): dizin altından bileğe turuncu, alta doğru hafif bol, dikey dikişli panelli tüp; üstte kalın kıvrık ağız.
## İncik tek kemik: kabuk yüzeyinden ölçülüp LowerLeg kemiğine bağlanır (bacakla birlikte döner, kumaşın içine girmez)
func _leg_warmers(col: Color) -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	var vs = _wear_vs()
	for side in ["Left", "Right"]:
		var kn = _bp(side + "LowerLeg")
		var an = _bp(side + "Foot")
		var sel = func(v: Vector3) -> bool: return Vector2(v.x - kn.x, v.z - kn.z).length() < 0.13 and signf(v.x) == signf(kn.x)
		var y0 = an.y + 0.03
		var y1 = kn.y - 0.04
		var rows = 9
		var rings = []
		for r in rows + 1:
			var t = float(r) / rows
			var y = lerpf(y0, y1, t)
			var cy = an.lerp(kn, clampf((y - an.y) / maxf(0.01, kn.y - an.y), 0.0, 1.0))
			rings.append(_wear_ring(vs, y, sel, 28, 0.012 + (1.0 - t) * 0.012, cy))
		var m = MB.new()
		_ring_tube(m, rings, col, 7, kn)
		var top: Array = rings[rings.size() - 1]
		if not top.is_empty():   # üst ağız: dışa kıvrık kalın kenar
			var l0 = []; var l1 = []; var l2 = []
			for p in top:
				var o2 = Vector3(p.x - kn.x, 0, p.z - kn.z).normalized()
				l0.append(p)
				l1.append(p + o2 * 0.012 + Vector3.UP * 0.012)
				l2.append(p + o2 * 0.004 + Vector3.UP * 0.028)
			_ring_tube(m, [l0, l1, l2], col.darkened(0.08), 0, kn)
		var bot: Array = rings[0]
		if not bot.is_empty():   # alt ağız
			var b1 = []
			for p in bot:
				b1.append(p + Vector3(p.x - an.x, 0, p.z - an.z).normalized() * 0.006 + Vector3.DOWN * 0.012)
			_ring_tube(m, [b1, bot], col.darkened(0.1), 0, an)
		_mesh_on(side + "LowerLeg", m.build(Props.toon()), Transform3D.IDENTITY)


## Turuncu boyunluk (ref lee.png): boynu saran kalın, dikey dilimli halka
func _neck_warmer(col: Color) -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	var vs = _wear_vs()
	var nk = _bp("Neck")
	var hd = _bp("Head")
	var sel = func(v: Vector3) -> bool: return Vector2(v.x - nk.x, v.z - nk.z).length() < 0.1
	var rings = []
	for r in 6:
		var t = r / 5.0
		var y = lerpf(nk.y - 0.04, lerpf(nk.y, hd.y, 0.55), t)
		rings.append(_wear_ring(vs, y, sel, 28, 0.016 + sin(t * PI) * 0.012, nk))
	var m = MB.new()
	_ring_tube(m, rings, col, 4, nk)
	_mesh_on("Neck", m.build(Props.toon()), Transform3D.IDENTITY)


## Set kıyafet ayrıntıları (kaynak: köy set görselleri) — 3B parçalar, kemiğe bağlı:
## guard_stripes: koruyucuların üstünde boyuna çizgiler (Kumo kırmızı, Kiri açık mavi), knee_wraps: dizde çapraz beyaz sargı (Kumo),
## pants_flap: pantolonun sağ yanından dize kadar sarkan koyu kanat (Iwa)
static var _body_vs_cache := {}
## Gövde köşeleri (cinsiyete göre aynı taban): surface_get_arrays her seferinde ekran kartından kopya çekiyordu
func _body_vs() -> PackedVector3Array:
	var k = "%s|%d" % [look.get("gender", "m"), body_mesh.mesh.get_instance_id()]
	if not _body_vs_cache.has(k):
		_body_vs_cache[k] = body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return _body_vs_cache[k]


func _outfit_extras() -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	var vs: PackedVector3Array = _body_vs()
	var gd = look.get("guards")
	var stripe = look.get("guard_stripes")
	var g = _geo_for(look["gender"])
	var gk = func(key: String): return _garment_cache.get("%s|%s|%.3f" % [look["gender"], key, _outer_pad])
	# koruyucu çizgileri: koruyucu kabuğunun kendisinden (derili, kabukla eğilir; havada kalmaz)
	if stripe != null:
		for sx in [1.0, -1.0]:
			var lk = "kolluk%d_%d%s" % [int(sx), int(look.get("guard_long", false)), "a" if look.get("guard_ankle", false) else ""]
			for part in [["tozluk" if look.get("guard_ankle", false) else "kaval", gd in ["bacak", "ikisi"]], ["kolluk", gd in ["kol", "ikisi"]]]:
				if not part[1]:
					continue
				var src = gk.call(lk) if part[0] == "kolluk" else gk.call("%s%d" % [part[0], int(sx)])
				if src == null or not _sk_begin(src):
					continue
				var V: PackedVector3Array = _sk["v"]
				var y0 = 99.0; var y1 = -99.0
				for q in V:
					y0 = minf(y0, q.y); y1 = maxf(y1, q.y)
				var ym = (y0 + y1) * 0.5
				var cx = 0.0; var bz = -9.0
				for q in V:   # koruyucunun orta yükseklikteki en ön noktası: çizgiler tam önde
					if absf(q.y - ym) < 0.03 and q.z > bz:
						bz = q.z; cx = q.x
				var spread = 0.02 if part[0] != "kolluk" else 0.014
				var cnt = (5 if look.get("guard_ankle", false) else 3) if part[0] != "kolluk" else (4 if look.get("guard_ankle", false) else 2)
				for k in cnt:
					var x = cx + (k - (cnt - 1) * 0.5) * spread
					_sk_strip(x, y1 - 0.025, y0 + 0.025, 0.007, 0.005, stripe, 18)
				_sk_end(g)
	# Kumo diz sargısı: dizin önünde çapraz iki bant + üst/alt yatay bant, pantolon kabuğunun yüzeyinden
	if look.get("knee_wraps", false) and _sk_begin(_shell_cache.get(look["gender"])):
		var white = Color(0.92, 0.92, 0.9)
		for side in ["Left", "Right"]:
			var kn = _bp(side + "LowerLeg")
			var lines = [[Vector2(-0.055, 0.075), Vector2(0.055, -0.03)], [Vector2(0.055, 0.075), Vector2(-0.055, -0.03)],
				[Vector2(-0.065, 0.085), Vector2(0.065, 0.085)], [Vector2(-0.06, -0.04), Vector2(0.06, -0.04)]]
			for ln in lines:
				var pts = []; var outs = []
				for k in 9:
					var q: Vector2 = ln[0].lerp(ln[1], k / 8.0)
					var hit = _sk_hit(kn.x + q.x, kn.y + q.y, true, 0.02)
					if not hit.is_empty():
						pts.append(Vector3(kn.x + q.x, kn.y + q.y, hit[0].z)); outs.append(hit[1])
				for it in 2:
					var sm = pts.duplicate()
					for i in range(1, pts.size() - 1):
						sm[i] = Vector3(pts[i].x, pts[i].y, maxf(pts[i].z, (pts[i - 1].z + pts[i + 1].z) * 0.5))
					pts = sm
				if pts.size() > 1:
					var dir = (Vector3(ln[1].x, ln[1].y, 0) - Vector3(ln[0].x, ln[0].y, 0)).normalized()
					_sk_band(pts, outs, Vector3.BACK.cross(dir).normalized(), 0.018, 0.006, white)
		_sk_end(g)
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
	var vs: PackedVector3Array = _body_vs()
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


## Pürüzsüz miğfer kabuğu: kafa derisinin her yönde en dış noktasına + pay ile oturan, ızgarası yumuşatılmış kubbe.
## Ön kenar front_edge_y'de, arkaya doğru back_drop kadar iner (ense korunur).
func _helmet_shell(col: Color, front_edge_y: float, back_drop: float, pad := 0.016, flat_top := 0.0, side_drop := 0.0) -> MeshInstance3D:
	# kafa derisinin gerçek yüzeyi (saçlarla aynı ölçüm: _head_radial ızgarası, AnimeHair._real_r)
	AnimeHair._c = skull_c; AnimeHair._r = skull_r; AnimeHair._grid = _head_radial(); AnimeHair._band_y = -INF
	var NA = 64; var NP = 22
	var edge_at = func(a: float) -> float:   # a: yaw (0 = ön +Z)
		var back = maxf(0.0, -cos(a))
		return front_edge_y - back_drop * back * back - side_drop * smoothstep(0.5, 0.92, absf(sin(a)))   # side_drop: kapüşon yüzü açık bırakıp yanaklardan iner
	# yarıçap ızgarası: ölç -> genişlet (max 3x3, çıkıntılar dışarıda kalsın) -> 6 tur yumuşat (buruşuk değil pürüzsüz kask)
	var pmaxs = []
	for k in NA:
		var yw = float(k) / NA * 360.0 - 180.0
		var pmax = 30.0
		while pmax < 140.0:
			var dd = AnimeHair._dir(yw, pmax)
			if (skull_c + dd * AnimeHair._real_r(dd)).y < edge_at.call(deg_to_rad(yw)):
				break
			pmax += 2.0
		pmaxs.append(pmax)
	for it in 3:   # kenar çizgisi de yumuşak
		var sm = pmaxs.duplicate()
		for k in NA:
			sm[k] = (pmaxs[(k + NA - 1) % NA] + pmaxs[k] * 2.0 + pmaxs[(k + 1) % NA]) * 0.25
		pmaxs = sm
	var RG = []
	for k in NA:
		var row = []
		for jj in NP + 1:
			var yw = float(k) / NA * 360.0 - 180.0
			var d = AnimeHair._dir(yw, lerpf(0.0, pmaxs[k], float(jj) / NP))
			row.append(AnimeHair._real_r(d))
		RG.append(row)
	var dil = []
	for k in NA:
		var row = []
		for jj in NP + 1:
			var m = 0.0
			for dk in [-1, 0, 1]:
				for dj in [-1, 0, 1]:
					m = maxf(m, RG[(k + dk + NA) % NA][clampi(jj + dj, 0, NP)])
			row.append(m)
		dil.append(row)
	RG = dil
	for it in 6:
		var sm = []
		for k in NA:
			var row = []
			for jj in NP + 1:
				var a = 0.0
				for dk in [-1, 0, 1]:
					for dj in [-1, 0, 1]:
						a += RG[(k + dk + NA) % NA][clampi(jj + dj, 0, NP)]
				row.append(a / 9.0)
			sm.append(row)
		RG = sm
	var top_r = 0.0
	for k in NA:
		top_r += RG[k][0]
	top_r /= NA
	var p_at = func(k: int, j: int, off: float) -> Vector3:
		var kk = k % NA
		var yw = float(kk) / NA * 360.0 - 180.0
		var d = AnimeHair._dir(yw, lerpf(0.0, pmaxs[kk], float(j) / NP))
		var r = top_r if j == 0 else RG[kk][j]
		var pnt = skull_c + d * (r + pad + off)
		if flat_top > 0.0:   # silindir kep: yan duvar dik, tepe düz
			var hzv = Vector2(pnt.x - skull_c.x, pnt.z - skull_c.z)
			var rmax = RG[kk][NP] + pad
			if float(j) / NP < 0.55:
				var fy = flat_top + off   # iç yüz düz tepede 3 mm aşağıda (z-çakışma lekesi olmasın)
				pnt = Vector3(skull_c.x + hzv.normalized().x * (rmax + off) * (float(j) / NP / 0.55), fy, skull_c.z + hzv.normalized().y * (rmax + off) * (float(j) / NP / 0.55)) if hzv.length() > 0.0001 else Vector3(skull_c.x, fy, skull_c.z)
			else:
				var ee = (float(j) / NP - 0.55) / 0.45
				var e2 = AnimeHair._dir(float(kk) / NA * 360.0 - 180.0, pmaxs[kk])
				var bot = skull_c + e2 * (RG[kk][NP] + pad)
				var hb = Vector2(bot.x - skull_c.x, bot.z - skull_c.z)
				var hbn = hb.normalized() * (hb.length() + off)
				pnt = Vector3(skull_c.x + hbn.x, lerpf(flat_top + off, bot.y, ee), skull_c.z + hbn.y)
		return pnt
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in NA:
		for j in NP:
			var q = [p_at.call(k, j, 0.0), p_at.call(k + 1, j, 0.0), p_at.call(k + 1, j + 1, 0.0), p_at.call(k, j + 1, 0.0)]
			var qi = [p_at.call(k, j, -0.003), p_at.call(k + 1, j, -0.003), p_at.call(k + 1, j + 1, -0.003), p_at.call(k, j + 1, -0.003)]
			for idx in [0, 2, 1, 0, 3, 2]:
				st.set_color(col)
				st.add_vertex(q[idx])
			for idx in [0, 1, 2, 0, 2, 3]:   # karşı yön (3 mm içte): sarım hangi bölgede ters olursa olsun kubbe dolu
				st.set_color(col)
				st.add_vertex(qi[idx])
		var e = [p_at.call(k, NP, 0.0), p_at.call(k + 1, NP, 0.0), p_at.call(k + 1, NP, -0.012), p_at.call(k, NP, -0.012)]
		for idx in [0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2]:
			st.set_color(col.darkened(0.1))
			st.add_vertex(e[idx])
	st.generate_normals()
	var mi = _mesh_on("Head", st.commit(), Transform3D.IDENTITY)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.2)
	mi.material_override = mat
	return mi


## Yönlü kutu (merkez, eksenler, tam boyut) — vertex renkli
static func _box_basis(st: SurfaceTool, c: Vector3, b: Basis, size: Vector3, col: Color) -> void:
	var h = size * 0.5
	var corners = []
	for z in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for x in [-1.0, 1.0]:
				corners.append(c + b.x * h.x * x + b.y * h.y * y + b.z * h.z * z)
	var faces = [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]
	for f in faces:
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.add_vertex(corners[f[idx]])


## Konik hasır şapka: düz renk + ışınsal çizgi şeritleri + koyu tepe (Akatsuki şapkası)
func _cone_hat(cen: Vector3, R: float, H: float, col: Color, line: Color, lines: int, tip: Color) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var NA = lines * 4
	for i in NA:
		var a0 = TAU * i / NA; var a1 = TAU * (i + 1) / NA
		for k in 8:
			var t0 = k / 8.0; var t1 = (k + 1) / 8.0
			var p = func(a: float, t: float) -> Vector3: return cen + Vector3(sin(a) * R * t, H * (1.0 - t), cos(a) * R * t)
			var cl = tip if t1 <= 0.13 else (line if i % 4 == 0 else col)
			var q = [p.call(a0, t0), p.call(a1, t0), p.call(a1, t1), p.call(a0, t1)]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(cl)
				st.add_vertex(q[idx])
		var e0 = cen + Vector3(sin(a0) * R, 0, cos(a0) * R); var e1 = cen + Vector3(sin(a1) * R, 0, cos(a1) * R)
		var q2 = [e0, e1, e1 + Vector3(0, -0.008, 0), e0 + Vector3(0, -0.008, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_color(col.darkened(0.2))
			st.add_vertex(q2[idx])
	st.generate_normals()
	var mi = _mesh_on("Head", st.commit(), Transform3D.IDENTITY)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.15)
	mi.material_override = mat
	return mi


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
	if sf_head and look.get("head_style") in ["kasa", "kage"]:
		hair_mask_plane(Vector3.UP, Vector3(0, htop - 0.06, 0))
	if not sf_head and look.get("head_style") == "kage":
		KageAttire.hat(self, String(look.get("kage_vid") if look.get("kage_vid") != null else look.get("village", "konoha")))
	match (null if sf_head else look.get("head_style")):
		"kasa":
			var m = MB.new()
			m.add("cone", Vector3(0, 0.0, 0), Vector3(hw * 3.2, 0.17, hw * 3.2), hg, Vector3.ZERO, 18)
			m.add("cyl", Vector3(0, -0.075, 0), Vector3(hw * 3.1, 0.014, hw * 3.1), hg.darkened(0.15), Vector3.ZERO, 18)
			m.add("cyl", Vector3(0, -0.05, 0), Vector3(hw * 1.05, 0.04, hw * 1.12), hg.darkened(0.35), Vector3.ZERO, 14)
			_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hcen.x, htop + 0.02, hcen.z)))
			hair_mask_plane(Vector3.UP, Vector3(0, htop + 0.02 - 0.08, 0))   # şapka kenarının üstündeki saç şapkanın içinde kalır
		"bandana":
			if band_ring.is_empty():
				var m = MB.new()
				m.add("hemi", Vector3.ZERO, Vector3(hw * 1.16, hh * 0.8, hd * 1.12), hg, Vector3.ZERO, 16)
				_mesh_on("Head", m.build(Props.toon()), Transform3D(Basis.IDENTITY, Vector3(hcen.x, hc.y - 0.005, hcen.z)))
			else:
				_hitai_bandana(hg)
		"akatsuki":   # Striker "Akatsuki Hat" + anime (refs/hats): hasır sivri koni, ışınsal çizgiler, koyu tepe; kenarın altından
			# yüzü ve başı çevreleyen SIK, bitişik beyaz kâğıt şeritler (önde ortada yüz için dar aralık) — kumaş gibi salınır
			_band_ring_full()
			var R = hw * 1.45
			var by0 = eye_center_model.y + 0.045   # kenar alın hizası (ref: yüz görünür)
			var top_need = 0.0
			for q in _body_vs():
				if absf(q.x - hcen.x) < 0.05 and q.y > hcen.y:
					top_need = maxf(top_need, q.y)
			var H = maxf(R * 0.62, (top_need + 0.02 - by0) / 0.62)
			_cone_hat(Vector3(hcen.x, by0, hcen.z - 0.01), R, H, Color(0.78, 0.63, 0.46), Color(0.55, 0.42, 0.3), 36, Color(0.12, 0.1, 0.1))
			hair_mask_plane(Vector3.UP, Vector3(0, by0 + 0.01, 0))
			var nst = 40
			for k in nst:
				var deg = lerpf(34.0, 326.0, (k + 0.5) / nst)   # önde yüz açıklığı (ref: yüz ortadan görünür)
				var a = deg_to_rad(deg)
				var out = Vector3(sin(a), 0, cos(a))
				var L = hh * (1.25 + 0.18 * float((k * 7) % 3) / 2.0)
				var w = TAU * R * 0.74 * (292.0 / 360.0) / nst * 1.25
				var rr = R * 0.74 + (0.003 if k % 2 == 0 else 0.0)
				dangle_strip("Head", Vector3(hcen.x, by0 - 0.006, hcen.z - 0.01) + out * rr, (Vector3.DOWN + out * 0.04).normalized(), L, w, Color(0.93, 0.94, 0.96).darkened(0.04 * (k % 2)), 0.4, out.cross(Vector3.UP).normalized(), 0.002, null, 0.0)
		"miğfer":   # Hiruzen savaş miğferi (Striker Hiruzen_Helmet + anime refs/hats): kafaya oturan pürüzsüz beyaz kask (ön kenar
			_hiruzen_helmet(hg)
		"bere":   # örgü bere (Striker Naruto Knitted Cap): kafayı kaşa kadar saran yumuşak pürüzsüz kep, altta kıvrık kenar (manşet)
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(hg, by - 0.006, 0.07, 0.024)
			hair_mask_plane(Vector3.UP, Vector3(0, by - 0.03, 0))
		"teuchi":   # Ichiraku kepi (Striker Teuchi): alnı örten, düz tepeli dik silindir siyah kep; önde kırmızı 一楽
			_band_ring_full()
			var by = band_ring[0]
			var top = by
			for q in _body_vs():
				if absf(q.x - skull_c.x) < 0.05 and q.y > top:
					top = q.y
			var tmi = _helmet_shell(hg, by - 0.004, 0.03, 0.016, top + 0.012)   # ref: tepe kafanın hemen üstünde, alçak silindir
			hair_mask_plane(Vector3.UP, Vector3(0, by - 0.02, 0))
			var fr = float((band_ring[1] as PackedFloat32Array)[int(floor((PI * 0.5 + PI) / TAU * (band_ring[1] as PackedFloat32Array).size())) % (band_ring[1] as PackedFloat32Array).size()])
			var l = Label3D.new()
			l.text = "一楽"
			l.font = KageAttire._font()
			l.font_size = 64
			l.pixel_size = 0.0011
			l.modulate = Color(0.8, 0.15, 0.12)
			l.shaded = false
			l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
			l.position = Vector3(skull_c.x, by + 0.035, skull_c.z + fr + 0.03)
			tmi.add_child(l)
		"basortusu":   # Ayame baş örtüsü (Striker Ayame): başın tepesini saran bez (ön kenar saç çizgisi), ensede düğüm, iki geniş sarkan uç
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(hg, by + 0.012, 0.11, 0.02)
			hair_mask_plane(Vector3.UP, Vector3(0, by - 0.005, 0))
			var bk = 0.0
			for q in _body_vs():
				if absf(q.y - (by - 0.07)) < 0.02 and absf(q.x - skull_c.x) < 0.04 and q.z < skull_c.z:
					bk = minf(bk, q.z - skull_c.z)
			var kp = Vector3(skull_c.x + 0.02, by - 0.075, skull_c.z + bk - 0.03)
			var mk = MB.new()
			mk.add("sphere", kp, Vector3(0.035, 0.03, 0.025), hg.darkened(0.08), Vector3.ZERO, 8)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
			for sx in [-1.0, 1.0]:
				dangle_strip("Head", kp + Vector3(0.012 * sx, -0.005, -0.005), Vector3(0.55 * sx + 0.25, -1.0, -0.35), 0.12, 0.06, hg, 0.25, Vector3(1, 0, 0), 0.004, null, 0.6)
		"iwabe":   # Iwabe kepi (Striker Iwabe's Cap): kafayı saran beyaz sargı kep, tepede bez düğümü, çapraz koyu bağ, yanda sarkan iki ip
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(hg, by - 0.012, 0.06, 0.03)
			hair_mask_plane(Vector3.UP, Vector3(0, by - 0.03, 0))
			var tp = by
			for q in _body_vs():
				if absf(q.x - skull_c.x) < 0.05 and q.y > tp:
					tp = q.y
			var mk = MB.new()
			mk.add("sphere", Vector3(skull_c.x + 0.01, tp + 0.04, skull_c.z - 0.01), Vector3(0.07, 0.04, 0.06), hg.lightened(0.05), Vector3(0, 0, 12), 10)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
			var dk = Color(0.1, 0.11, 0.16)
			_skull_band(dk, by + 0.035, 0.022, 0.05, 0.018)
			_skull_band(dk, by + 0.008, 0.02, 0.05, -0.014)
			for q in 2:
				dangle_strip("Head", Vector3(skull_c.x + hw * 0.6, by + 0.005, skull_c.z - 0.02), Vector3(0.2 + q * 0.15, -1.0, -0.2), 0.16 + q * 0.03, 0.007, dk, 0.2, Vector3(0, 0, 1), 0.004, null, 0.0)
		"uyku":   # Naruto'nun uyku kepi (Striker Naruto's Nightcap): koyu lacivert kep, beyaz kıvrık manşet, önde çizgi film gözleri + burun
			_band_ring_full()
			var by = band_ring[0]
			var cap = _helmet_shell(hg, by - 0.01, 0.06, 0.03)
			hair_mask_plane(Vector3.UP, Vector3(0, by - 0.03, 0))
			_skull_band(Color(0.93, 0.93, 0.92), by - 0.002, 0.04, 0.04)
			var fr = _ring_r_at(PI * 0.5)
			var mk = MB.new()
			for sx in [-1.0, 1.0]:
				var ep = Vector3(skull_c.x + sx * 0.042, by + 0.075, skull_c.z + fr + 0.02)
				mk.add("sphere", ep, Vector3(0.042, 0.03, 0.01), Color(0.95, 0.95, 0.95), Vector3(-20, 0, 0), 12)
				mk.add("sphere", ep + Vector3(0, 0, 0.004), Vector3(0.018, 0.016, 0.008), Color(0.06, 0.06, 0.08), Vector3(-20, 0, 0), 10)
			mk.add("sphere", Vector3(skull_c.x, by + 0.02, skull_c.z + fr + 0.034), Vector3(0.026, 0.022, 0.014), Color(0.05, 0.05, 0.07), Vector3.ZERO, 10)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
		"samuray_s":   # Sasuke alın koruyucusu (Striker Samurai Sasuke): kafatasına oturan siyah başlık, alında Uchiha arması,
			# şakaktan çeneye inen mor kordon (çene altında düğüm, iki püskül), yanlarda kısa sarkan kanatlar
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(hg, by + 0.004, 0.1, 0.012)
			hair_mask_plane(Vector3.UP, Vector3(0, by - 0.01, 0))
			var fr = _ring_r_at(PI * 0.5)
			var mk = MB.new()
			var cp = Vector3(skull_c.x, by + 0.045, skull_c.z + fr + 0.016)
			mk.add("cyl", cp, Vector3(0.036, 0.004, 0.026), Color(0.8, 0.1, 0.1), Vector3(76, 0, 0), 16)
			mk.add("box", cp + Vector3(0, -0.022, 0.004), Vector3(0.008, 0.022, 0.004), Color(0.93, 0.93, 0.92), Vector3(-14, 0, 0))
			var chin = Vector3(skull_c.x, eye_center_model.y - 0.11, skull_c.z + fr * 0.55)
			var lav = Color(0.62, 0.55, 0.78)
			for sx in [-1.0, 1.0]:
				var tmp = Vector3(skull_c.x + sx * (hw * 0.52), by - 0.02, skull_c.z + 0.01)
				for q in 6:
					var t0 = q / 6.0; var t1 = (q + 1) / 6.0
					var a = tmp.lerp(chin, t0) + Vector3(sx * 0.012 * sin(t0 * PI), 0, 0.01 * sin(t0 * PI))
					var b = tmp.lerp(chin, t1) + Vector3(sx * 0.012 * sin(t1 * PI), 0, 0.01 * sin(t1 * PI))
					mk.add("cyl", (a + b) * 0.5, Vector3(0.006, a.distance_to(b) + 0.002, 0.006), lav, Vector3(rad_to_deg(atan2((b - a).z, -(b - a).y)), 0, -rad_to_deg(atan2((b - a).x, -(b - a).y))), 6)
				dangle_strip("Head", Vector3(skull_c.x + sx * (hw * 0.56), by - 0.005, skull_c.z - 0.03), Vector3(sx * 0.6, -1.0, -0.4), 0.09, 0.05, hg, 0.3, Vector3(0, 0, 1), 0.004)
			mk.add("sphere", chin, Vector3(0.016, 0.014, 0.014), lav, Vector3.ZERO, 8)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
			for sx in [-1.0, 1.0]:
				dangle_strip("Head", chin + Vector3(sx * 0.008, -0.006, 0.004), Vector3(sx * 0.15, -1.0, 0.1), 0.1, 0.014, lav, 0.15, Vector3(1, 0, 0), 0.006, null, 0.0)
		"samuray_k":   # Sakura alın koruyucusu (Striker Samurai Sakura): alnı örten koyu lacivert geniş bant (metal kenarlı), ensede beyaz bez bağ
			_band_ring_full()
			_hitai("Head", Vector3(skull_c.x, band_ring[0] + 0.012, skull_c.z), band_ring[1], hg, 0.052, 0.0, 0.0, 0.004, Vector3(0.25, -1.0, -0.6), false, 0.0, 0.0, 0.009)
			hair_mask_band(band_ring[0] - 0.012, 0.06, 0.008)
			for k in 3:
				dangle_strip("Head", Vector3(skull_c.x + 0.02, band_ring[0] - 0.01, skull_c.z - _ring_r_at(-PI * 0.5) - 0.012), Vector3(0.3 + k * 0.15, -1.0, -0.5), 0.14 + k * 0.02, 0.05, Color(0.94, 0.94, 0.95), 0.25, Vector3(1, 0, 0), 0.004)
		"kurbaga":   # Kurbağa başlığı (Striker Frog Head): yüzü açık bırakan koca yuvarlak kurbağa kapüşonu, tepede iki göz, yanaklarda pembe daire
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(hg, by + 0.012, 0.24, 0.05)   # önde alın kenarı (yüz açık), yan/arkada çeneye iner
			hair_mask_plane(Vector3.UP, Vector3(0, by - 0.01, 0))
			var tp = by
			for q in _body_vs():
				if absf(q.x - skull_c.x) < 0.05 and q.y > tp:
					tp = q.y
			var mk = MB.new()
			for sx in [-1.0, 1.0]:
				var ep = Vector3(skull_c.x + sx * hw * 0.48, tp + 0.03, skull_c.z + 0.02)
				mk.add("sphere", ep, Vector3(0.075, 0.07, 0.07), hg, Vector3.ZERO, 12)
				mk.add("sphere", ep + Vector3(0, 0.005, 0.034), Vector3(0.03, 0.03, 0.012), Color(0.06, 0.06, 0.08), Vector3.ZERO, 10)
				mk.add("sphere", Vector3(skull_c.x + sx * (hw * 0.62 + 0.04), eye_center_model.y - 0.02, skull_c.z + 0.05), Vector3(0.012, 0.04, 0.06), Color(0.98, 0.62, 0.6), Vector3.ZERO, 12)
			mk.add("sphere", Vector3(skull_c.x, eye_center_model.y - 0.13, skull_c.z - 0.02), Vector3(hw * 1.5, 0.08, hw * 1.25), hg, Vector3.ZERO, 14)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
		"han":   # Han şapkası (Striker Han Hat): geniş gri hasır koni, alın bandı, kulakları ve çeneyi örten mor bez sarkıtlar
			_band_ring_full()
			var R = hw * 1.75
			var by0 = eye_center_model.y + 0.05
			var top_need = 0.0
			for q in _body_vs():
				if absf(q.x - hcen.x) < 0.05 and q.y > hcen.y:
					top_need = maxf(top_need, q.y)
			var H = maxf(R * 0.42, (top_need + 0.02 - by0) / 0.55)
			_cone_hat(Vector3(hcen.x, by0, hcen.z - 0.01), R, H, Color(0.74, 0.75, 0.78), Color(0.5, 0.52, 0.56), 40, Color(0.22, 0.16, 0.12))
			hair_mask_plane(Vector3.UP, Vector3(0, by0 + 0.01, 0))
			var pur = Color(0.48, 0.42, 0.66)
			for k in 9:
				var deg = lerpf(55.0, 305.0, (k + 0.5) / 9.0)
				var a = deg_to_rad(deg)
				var out = Vector3(sin(a), 0, cos(a))
				dangle_strip("Head", Vector3(hcen.x, by0 - 0.02, hcen.z - 0.01) + out * (hw * 0.62), (Vector3.DOWN + out * 0.15).normalized(), hh * 1.4, 0.075, pur.darkened(0.05 * (k % 2)), 0.35, out.cross(Vector3.UP).normalized(), 0.004, null, 0.0)
		"kardan":   # Kardan adam (Striker Snowman): başı tümüyle örten beyaz kar topu yüz, kömür gözler + gülüş, havuç burun, sarı kova
			_band_ring_full()
			var hcm = Vector3(skull_c.x, eye_center_model.y - 0.01, skull_c.z + 0.01)
			var rr = hh * 0.85 + 0.03
			var mk = MB.new()
			mk.add("sphere", hcm, Vector3(rr * 2.1, rr * 2.0, rr * 2.0), Color(0.97, 0.97, 0.98), Vector3.ZERO, 18)
			var fz = rr * 0.98
			for sx in [-1.0, 1.0]:
				mk.add("sphere", hcm + Vector3(sx * rr * 0.38, rr * 0.25, fz * 0.92), Vector3(0.045, 0.05, 0.02), Color(0.05, 0.05, 0.06), Vector3.ZERO, 10)
			mk.add("sphere", hcm + Vector3(0, 0, fz + 0.01), Vector3(0.05, 0.045, 0.05), Color(0.95, 0.35, 0.12), Vector3.ZERO, 10)
			for k in 7:
				var t = (k - 3) / 3.0
				mk.add("sphere", hcm + Vector3(t * rr * 0.5, -rr * 0.35 - 0.05 * (1.0 - t * t) * 0.6, fz * (0.86 + 0.06 * (1.0 - absf(t)))), Vector3(0.024, 0.024, 0.014), Color(0.05, 0.05, 0.06), Vector3.ZERO, 8)
			mk.add("cyl", hcm + Vector3(0.03, rr * 1.05, -0.02), Vector3(rr * 0.85, rr * 0.75, rr * 0.85), Color(0.92, 0.78, 0.25), Vector3(0, 0, -14), 14)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
			hair_mask_plane(Vector3.UP, Vector3(0, -10.0, 0))   # saç tümüyle top içinde
		"gelin":   # Gelin duvağı (Striker Wedding Veil): başa oturan yeşil örgü kep + başı ve sırtı örten, bele inen bej kapüşonlu duvak
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(Color(0.2, 0.3, 0.24), by + 0.02, 0.07, 0.026)
			hair_mask_plane(Vector3.UP, Vector3(0, by, 0))
			var tp = by
			for q in _body_vs():
				if absf(q.x - skull_c.x) < 0.05 and q.y > tp:
					tp = q.y
			var nst = 26
			for k in nst:
				var deg = lerpf(40.0, 320.0, (k + 0.5) / nst)
				var a = deg_to_rad(deg)
				var out = Vector3(sin(a), 0, cos(a))
				var back = maxf(0.0, -cos(a))
				var root = Vector3(skull_c.x, tp - 0.02 - (1.0 - back) * 0.05, skull_c.z - 0.01) + out * (hw * 0.62 + 0.035)
				dangle_strip("Head", root, (Vector3.DOWN + out * 0.07).normalized(), 0.42 + back * 0.2, TAU * hw * 0.7 / nst * 1.35, hg.darkened(0.04 * (k % 2)), 0.35, out.cross(Vector3.UP).normalized(), 0.003, null, 0.0)
		"bandaj":
			# alnı saran sargı: iki kat (biri hafif eğik), ensede kısa sarkan uç
			var ybj = cloth_band(hg, 0.004, 0.034, 0.1, 0.026, 0.004)
			cloth_band(hg.darkened(0.06), 0.02, 0.02, 0.0, 0.0, 0.018, 0.0165)
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
	elif fs == "gas" and face_mi == null:
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
			# tek parça dönel gövde (iki hazne bel ile kesintisiz bağlı; eskiden iki ayrı küre arasında boşluk vardı)
			var prof = [[-0.33, 0.0], [-0.31, 0.09], [-0.26, 0.15], [-0.18, 0.183], [-0.1, 0.18], [-0.02, 0.15], [0.04, 0.095], [0.075, 0.072],
				[0.11, 0.09], [0.16, 0.118], [0.22, 0.12], [0.28, 0.095], [0.32, 0.055], [0.345, 0.04], [0.37, 0.04]]
			var lt = SurfaceTool.new()
			lt.begin(Mesh.PRIMITIVE_TRIANGLES)
			var nseg = 20
			for i in prof.size() - 1:
				for j in nseg:
					var a0 = TAU * j / nseg; var a1 = TAU * (j + 1) / nseg
					var y0 = prof[i][0] * k; var r0 = prof[i][1] * k
					var y1 = prof[i + 1][0] * k; var r1 = prof[i + 1][1] * k
					var q = [Vector3(cos(a0) * r0, y0, sin(a0) * r0), Vector3(cos(a1) * r0, y0, sin(a1) * r0), Vector3(cos(a1) * r1, y1, sin(a1) * r1), Vector3(cos(a0) * r1, y1, sin(a0) * r1)]
					var sh = 0.92 + 0.08 * sin(a0 * 3.0)   # hafif boğum dokusu
					for t in [0, 2, 1, 0, 3, 2]:
						lt.set_color(gc * Color(sh, sh, sh)); lt.add_vertex(q[t])
			lt.index()
			lt.generate_normals()
			m.add_arrays(lt.commit_to_arrays(), Transform3D.IDENTITY, gc)
			m.add("torus", Vector3(0, 0.075 * k, 0), Vector3(0.16, 0.16, 0.16) * k, Color(0.55, 0.14, 0.12), Vector3.ZERO, 14)   # boğum ipi (belde)
			m.add("cyl", Vector3(0, 0.385 * k, 0), Vector3(0.075, 0.05, 0.075) * k, Color(0.45, 0.3, 0.18), Vector3.ZERO, 10)   # tıpa
			if big:
				m.add("box", Vector3(0, 0.0, 0.17), Vector3(0.05, 0.6, 0.01), Color(0.3, 0.22, 0.14), Vector3(0, 0, 38))   # kayış
				m.add("box", Vector3(0, -0.12, -0.18), Vector3(0.12, 0.12, 0.006), Color(0.6, 0.12, 0.1), Vector3(0, 0, 45))   # mühür kâğıdı
				_mesh_on("UpperChest", m.build(Props.toon()), Transform3D(Basis(Vector3.BACK, deg_to_rad(-8)), ch + Vector3(0, -0.12, -0.305)))
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
	# bel bağı (pantolon kemeri): kalça kemiğine yapışık 33x7 cm katı silindir belin/göbeğin çevresinde kalın halka gibi
	# duruyor, eğilince kıyafetlerin içinden çıkıyordu -> gövde kabuğuna derili ince bant (kumaşla eğilir, dış giysinin altında kalır)
	pass   # bel bağı kaldırıldı (gömlek/pantolon geçişi kumaşın kendisinde)


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
const HAIR_STYLES := {"kısa": "Kısa", "kase": "Kâse", "uzun": "Uzun", "s1": "Dağınık Diken", "s2": "Dikenli Taç", "s3": "Yatık Diken", "s4": "Alev Yelpaze", "s5": "Düz Kuyruk", "s6": "Örtük Kâkül", "s7": "Yan Alev", "s8": "Ananas Kuyruk", "s9": "Kâse Kesim", "s10": "Dikenli Yele", "s11": "Düz Kısa", "s12": "Sık Diken", "s13": "Kısa Kirpi", "s14": "Geri Diken", "s15": "Uzun Perde", "s16": "Ördek Kuyruğu", "s17": "Yan Tarama", "s18": "Dik Fırça", "s19": "Savruk Diken", "s20": "Katlı Uç", "s21": "Tepe Kuyruk", "s22": "Geri Tarama", "s23": "Kısa Geri", "s24": "Dağınık Kısa", "f1": "Yan Ayrık Kısa", "f2": "Uzun Düz", "f3": "Uzun Dağınık", "f4": "Prenses Kâkül", "f5": "Dalgalı Uzun", "f6": "Dikenli Kuyruk", "f7": "Yan Kâkül Kuyruk", "f8": "Çift Topuz", "f9": "Dörtlü Kuyruk", "f10": "Kabarık Bere", "f11": "Düz Kesik Kısa", "f12": "Kısa Prenses", "f13": "Bantlı Kısa", "f14": "Açık Alın Kısa", "f15": "Topuz Kâkül", "f16": "Uzun Ayrık", "f17": "Örtük Kısa", "f18": "Küçük Prenses", "f19": "Uzun Kuyruk", "f20": "Alçak Kuyruk", "f21": "Kâküllü Kısa", "f22": "Arka Topuz", "f23": "Yana Kısa", "f24": "Tepe Topuz", "d0": "Yele Diken", "d1": "Uzun Yılan", "d2": "Çift Alçak Kuyruk", "d3": "Dev Yele", "d4": "Dağınık Kirpi", "d5": "Uzun Orman", "d6": "Dik Geri", "d8": "Sarı Şimşek", "d9": "Sert Kısa", "d10": "Topuz Perde", "d11": "Uzun Açık", "d14": "Gezgin Kâkül", "d15": "Geri Uzun", "d16": "Örtük Kuyruk", "d17": "Parlak Kâse", "d18": "Topuz Örtük", "d20": "Kabarık Kısa", "d22": "Hokage Dikeni", "d23": "Uzun Ayrık Düz", "d24": "Açık Alın Uzun", "d25": "Kıvırcık Kısa", "d26": "Dik Kısa", "d27": "Sivri Kâkül", "d28": "Savaş Sonrası Bob", "d29": "Asimetrik Bob", "d30": "Omuz Düz", "d32": "Alçak Kuyruk Uzun", "d33": "Kadim Diken", "d34": "Altı Yol Yelesi", "d35": "Dört Tutam", "d36": "Genç Dik", "d37": "Çift Uzun Kuyruk", "d39": "Görev Uzun", "d40": "Yere Uzun", "d41": "Kıvrık Tepe", "d42": "Savruk Dağınık", "d43": "Kukla Bob", "d44": "Yan Geri", "d45": "Dağınık Örtük", "e0": "Ananas Topuz", "e2": "Akademi Düz", "e3": "ANBU Tutam", "e4": "Genç Diken", "e5": "Ördek Kuyruğu", "e6": "Geriye Taralı", "e7": "Topuz", "e8": "Uzun Ayrık Perde", "e9": "Kemik Ayrık", "e10": "Vahşi Diken", "e11": "Genin Düz", "e12": "Yan Kâkül Uzun", "e13": "Genç Yan Alev", "e14": "Genç Uzun", "e15": "Küçük Bob", "e22": "Geniş Alın Uzun", "e23": "Kabarık Örtük", "e26": "Kabarık Kısa Kâkül", "e27": "Kabarık Kâse", "e28": "Kâkül Kuyruk", "e29": "Yüksek Kuyruk", "e30": "Uzun Prenses", "e31": "Omuz Ayrık", "e32": "Kedi Kâse", "e33": "Patlayıcı Kuyruk", "e34": "Patlayıcı Tutam", "e35": "Köpük Örtük", "e36": "Dağınık Kısa"}
## Saç cinsiyeti: Striker görselindeki MODELİN cinsiyeti (saçın sahibi karakterin adı değil — "Tsunade/Kaguya" erkek modelde). (kullanıcı 2026-11-09: kadın saçı kadınlara, erkek saçı erkeklere; yazılmayan = unisex)
const HAIR_GENDER := {"s1": "m", "s2": "m", "s3": "m", "s4": "m", "s5": "m", "s6": "m", "s7": "m", "s8": "m", "s9": "m", "s10": "m", "s11": "m", "s12": "m", "s13": "m", "s14": "m", "s15": "m", "s16": "m", "s17": "m", "s18": "m", "s19": "m", "s20": "m", "s21": "m", "s22": "m", "s23": "m", "s24": "m", "f1": "f", "f2": "f", "f3": "f", "f4": "f", "f5": "f", "f6": "f", "f7": "f", "f8": "f", "f9": "f", "f10": "f", "f11": "f", "f12": "f", "f13": "f", "f14": "f", "f15": "f", "f16": "f", "f17": "f", "f18": "f", "f19": "f", "f20": "f", "f21": "f", "f22": "f", "f23": "f", "f24": "f", "d0": "m", "d1": "m", "d2": "m", "d3": "m", "d4": "m", "d5": "m", "d6": "m", "d8": "m", "d9": "m", "d14": "m", "d15": "m", "d16": "m", "d17": "m", "d18": "m", "d20": "m", "d22": "m", "d23": "m", "d24": "m", "d25": "m", "d26": "m", "d27": "m", "d28": "m", "d29": "m", "d30": "m", "d32": "m", "d33": "m", "d34": "m", "d35": "f", "d36": "m", "d37": "f", "d39": "m", "d40": "m", "d41": "m", "d42": "m", "d43": "m", "d44": "m", "d45": "m", "e0": "m", "e2": "f", "e3": "m", "e4": "m", "e5": "m", "e6": "m", "e7": "f", "e8": "m", "e9": "m", "e10": "m", "e11": "f", "e12": "f", "e13": "m", "e14": "m", "e15": "f", "e22": "f", "e23": "m", "e26": "m", "e27": "m", "e28": "m", "e29": "m", "e30": "m", "e31": "m", "e32": "m", "e33": "m", "e34": "m", "e35": "m", "e36": "m", "d10": "m", "d11": "m"}

## NPC saçı: cinsiyete uygun anime saçlarından, görünüşe göre SABİT seçim (aynı kişi her kurulumda aynı saç)
static func npc_hair(lk: Dictionary) -> String:
	var g = String(lk.get("gender", "m"))
	var opts = hair_styles_for(g).filter(func(h): return AnimeHair.has(h))
	if opts.is_empty():
		return "kısa"
	var key = "%s|%s|%s|%s" % [String(lk.get("hair_style", "")), str(lk.get("hair", "")), str(lk.get("top", "")), str(lk.get("skin", ""))]
	return String(opts[absi(hash(key)) % opts.size()])


static func hair_styles_for(g: String) -> Array:
	return HAIR_STYLES.keys().filter(func(h): return String(HAIR_GENDER.get(h, "")) in ["", g])

## Kaldırılan saç modelleri (kullanıcı: 14 ve 16–43) -> en yakın kalan model (eski kayıtlar, NPC'ler)
## VRoid tabanı + tutam eklentili saçlar kaldırıldı (kullanıcı 2026-11-09: "iki saç üst üste gibi"); sıfırdan saçlar gelene kadar kalan modele düşer
const HAIR_ALIAS := {"orgu": "uzun", "mohikan": "kısa", "kisa_kakul": "kısa", "dalgali": "uzun", "savas_yelesi": "uzun", "bilge_yelesi": "uzun", "yuksek_kuyruk": "uzun", "yan_kuyruk": "uzun", "ikiz_kuyruk": "uzun", "ikiz_orgu": "uzun", "samuray": "uzun", "savasci_kuyruk": "uzun", "alev": "kısa", "geriye_diken": "kısa", "yan_tarama": "kısa", "perde": "uzun", "kabarik": "kısa", "ruzgar": "kısa", "yabani": "uzun", "ense_kuyruk": "uzun", "alcak_topuz": "uzun", "kazinmis": "kısa", "yan_kazinmis": "kısa", "golge": "uzun", "cerceve": "uzun", "yan_orgu": "uzun", "bagli_uzun": "uzun", "tepe_diken": "kısa", "yan_topuz": "uzun", "kel": "kısa", "diken": "kısa", "dağınık": "kısa", "atkuyruğu": "uzun", "kakul": "uzun", "geriye": "kısa", "ananas": "kısa", "topuz": "uzun", "ikiz_topuz": "uzun", "yele": "uzun", "kirpik": "kısa"}
static var _scalp_cache := {}
static var _hair_cache := {}
static var _hair_new_ms := -100000   # köylü için son yeni saç tutamı hesabı (art arda donma olmasın)
static var _hair_dyn := {}      # saç anahtarı -> Dangle paketi
static var _vhair_dyn := {}


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
	var sid = _strands.size()
	var cen = PackedVector3Array()
	for rg in rings:
		cen.append(rg[0])
	_strands.append({"rings": cen, "len": length, "dir": d, "group": _sgroup})
	var uv2 = Vector2(sid + 0.5, 0.0)
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
				st.set_uv2(uv2)
				st.add_vertex(vv[0])


static var _strands: Array = []   # _clump kayıtları (ikincil hareket: tutam zincirleri)
static var _sgroup := -1          # >= 0: tutamlar tek zincirde (örgü)
static var _gcount := 0


## Saç stili tutamları (kafa elipsoidi: merkez c, yarıçap r; +Z yüz)
static func _hair_clumps(style: String, c: Vector3, r: Vector3) -> ArrayMesh:
	_strands = []
	_sgroup = -1
	_gcount = 0
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
		_sgroup = -2
		for i in n:
			var a = at.call(rng.randf_range(y0, y1), rng.randf_range(p0, p1))
			var to = tie - a[0]
			_clump(st, a[0], to.normalized(), Vector3.ZERO, to.length() * 1.05, 0.06, 0.3)
		_sgroup = -1
	# bağlama noktasından sarkan kuyruk
	var tail = func(tie: Vector3, dir: Vector3, n: int, length: float, width: float, spread: float, grav: Vector3) -> void:
		for i in n:
			var d = (dir.normalized() + Vector3(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread) * 0.5, rng.randf_range(-spread, spread))).normalized()
			_clump(st, tie, d, grav, length * rng.randf_range(0.85, 1.1), width)
	# yuvarlak topuz
	var bun_at = func(bun: Vector3, n: int, size: float) -> void:
		_sgroup = -2
		for i in n:
			var ang = TAU * i / float(n)
			var d = Vector3(cos(ang), sin(ang) * 0.7 + 0.25, sin(ang) * 0.7).normalized()
			_clump(st, bun - d * 0.035 * size, d.cross(Vector3.UP).normalized(), Vector3.ZERO, 0.1 * size, 0.075 * size, 0.6)
		_sgroup = -1
	# örgü: yön boyunca sağa-sola dönüşümlü kısa tutamlar
	var braid = func(top: Vector3, dir: Vector3, segs: int, step: float, width: float) -> void:
		_sgroup = _gcount
		_gcount += 1
		var dn = dir.normalized()
		var sd = dn.cross(Vector3.FORWARD if absf(dn.z) < 0.9 else Vector3.RIGHT).normalized()
		for k in segs:
			var s = 1.0 if k % 2 == 0 else -1.0
			var w = width * (1.0 - 0.35 * float(k) / segs)
			_clump(st, top + dn * step * k + sd * 0.008 * s, (dn + sd * 0.22 * s).normalized(), Vector3.ZERO, step * 2.0, w * 1.15, 0.9)
		_sgroup = -1   # örgü bitti: sonraki tutamlar serbest
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
				_sgroup = -2
				_clump(st, root, (flow.normalized() + n * 0.15).normalized(), -n * 0.2, ln, 0.08, 0.32)
				_sgroup = -1
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
			_sgroup = _gcount
			_gcount += 1
			for k in 7:
				var pt = top + Vector3(0.012 * (1 if k % 2 == 0 else -1), -k * 0.06, -0.01 * k)
				_clump(st, pt, Vector3(0.3 * (1 if k % 2 == 0 else -1), -1, -0.1).normalized(), Vector3.ZERO, 0.08, 0.055, 0.7)
			_sgroup = -1
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


## Tutam mesh'inden ikincil hareket paketi: uzun/sarkan tutamlar benzer kök+yönle zincirlerde toplanır,
## örgüler tek zincir; kısa dikenler sabit kalır (kafa kemiğinde). _hair_clumps'tan hemen sonra çağrılır (_strands).
static func _clump_dangle(mesh: ArrayMesh) -> Dictionary:
	var strands = _strands
	var groups = []   # [{ids, root, dir, len, group}]
	var of = {}       # tutam -> zincir
	var order = []
	for i in strands.size():
		order.append(i)
	order.sort_custom(func(a, b): return strands[a]["len"] > strands[b]["len"])
	for i in order:
		var sd: Dictionary = strands[i]
		var L: float = sd["len"]
		var gid: int = sd["group"]
		var rings: PackedVector3Array = sd["rings"]
		var dir = (rings[rings.size() - 1] - rings[0]).normalized()
		# sabit kalanlar: kafa derisine yatık/toplanan tutamlar, topuz, kısa ya da yukarı bakan dikenler
		if gid == -2 or (gid < 0 and L < 0.035):
			continue
		var best = -1
		var bs = 1e9
		for gi in groups.size():
			var gr = groups[gi]
			if gr["group"] != gid:
				continue
			if gid >= 0:
				best = gi
				break
			var dd = (gr["root"] as Vector3).distance_to(rings[0])
			var ok = dd < 0.05 and dir.dot(gr["dir"]) > 0.8 and L / gr["len"] > 0.65
			var score = dd + (1.0 - dir.dot(gr["dir"])) * 0.2
			if ok and score < bs:
				bs = score
				best = gi
		if best < 0 and groups.size() >= 24:
			continue   # zincir sınırı: kalan kısa tutam sabit (başka yöndeki zincire bağlanıp tuhaf dönmesin)
		if best < 0:
			groups.append({"ids": [i], "root": rings[0], "dir": dir, "len": L, "group": gid})
			best = groups.size() - 1
		else:
			groups[best]["ids"].append(i)
		of[i] = best
	if groups.is_empty():
		return {}
	var defs = []
	for gr in groups:
		var pts = PackedVector3Array()
		if gr["group"] >= 0:
			# örgü: tutam kökleri boyunca tek zincir (yukarıdan aşağı) + son tutamın ucu
			var roots = []
			for i in gr["ids"]:
				roots.append(strands[i]["rings"][0])
			roots.sort_custom(func(a, b): return a.y > b.y)
			for q in roots:
				pts.append(q)
			var last: PackedVector3Array = strands[gr["ids"][0]]["rings"]
			for i in gr["ids"]:
				if (strands[i]["rings"][0] as Vector3).is_equal_approx(roots[roots.size() - 1]):
					last = strands[i]["rings"]
			pts.append(last[last.size() - 1])
		else:
			var ks = [0, 1, 2, 3, 4, 5] if gr["len"] >= 0.12 else [0, 3, 5]   # kısa tutam: az nokta (performans)
			for k in ks:
				var acc = Vector3.ZERO
				for i in gr["ids"]:
					acc += (strands[i]["rings"] as PackedVector3Array)[k]
				pts.append(acc / gr["ids"].size())
		var L: float = gr["len"]
		var upward = (gr["dir"] as Vector3).y > 0.3
		# tutamlar zaten sarkık modellendi: yerçekimi yalnız sapma için hafif (yoksa dinlenirken gövdeye gömülür)
		var hp = hair_profile(L, upward)
		hp["pts"] = pts
		defs.append(hp)
	var uv2: PackedVector2Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
	var assign = func(i: int, v: Vector3, _si: int) -> Array:
		var sid = int(uv2[i].x)
		if not of.has(sid):
			return []
		var ci: int = of[sid]
		return [[ci, Dangle.project(defs[ci]["pts"], v)[0], 1.0]]
	return Dangle.build(mesh, defs, assign)


## Anime saçı ikincil hareketi (kural: secondary-motion, hair_profile): akan tutamlar (kâkül, ense, favori) kendi
## zinciri; dikenler kafa bölgelerine (8 yön x tepe/yan) toplanır, sert profille hafif yaylanır. Kütle sabit.
func _anime_dangle(mesh: ArrayMesh, st: Array) -> Dictionary:
	var defs = []
	var of = {}
	var sectors = {}
	for i in st.size():
		var pts: PackedVector3Array = st[i]["pts"]
		if pts.size() < 3:
			continue
		var L = 0.0
		for k in range(1, pts.size()):
			L += pts[k].distance_to(pts[k - 1])
		if st[i]["kind"] == "lie":
			continue   # kafaya taranmış tutam: sabit (salınırsa kafadan kalkar)
		if st[i]["kind"] == "flow":
			if defs.size() >= 30:
				continue
			var cp = PackedVector3Array()
			for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
				cp.append(pts[int(round(f * (pts.size() - 1)))])
			var hp = hair_profile(L)
			hp["pts"] = cp
			of[i] = defs.size()
			defs.append(hp)
		else:
			var d = pts[0] - skull_c
			var sec = int(floor((atan2(d.x, d.z) + PI) / TAU * 8.0)) % 8 + (8 if d.y > skull_r.y * 0.6 else 0)
			if not sectors.has(sec):
				sectors[sec] = []
			sectors[sec].append(i)
	for sec in sectors:
		var ids: Array = sectors[sec]
		var cp = PackedVector3Array()
		var L = 0.0
		for f in [0.0, 0.5, 1.0]:
			var acc = Vector3.ZERO
			for i in ids:
				var pts: PackedVector3Array = st[i]["pts"]
				acc += pts[int(round(f * (pts.size() - 1)))]
			cp.append(acc / ids.size())
		L = cp[0].distance_to(cp[2])
		var hp = hair_profile(L, true)   # diken: yukarı/dışa bakan, sert
		hp["pts"] = cp
		var ci = defs.size()
		defs.append(hp)
		for i in ids:
			of[i] = ci
	if defs.is_empty():
		return {}
	var uv2: PackedVector2Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
	var assign = func(vi: int, v: Vector3, _si: int) -> Array:
		var sid = int(round(uv2[vi].x))
		if sid < 0 or not of.has(sid):
			return []
		var ci: int = of[sid]
		return [[ci, Dangle.project(defs[ci]["pts"], v)[0], 1.0]]
	return Dangle.build(mesh, defs, assign)


## Saçın TEK hareket profili (tutam + VRoid saç aynı): fark yalnız boydan gelir — kısa parça az, uzun parça çok oynar,
## hiçbiri kazık gibi sabit ya da yay gibi zıplayan olmaz (güçlü sönüm, kök başı izler).
static func hair_profile(L: float, upward := false) -> Dictionary:
	var k = clampf((L - 0.05) / 0.45, 0.0, 1.0)   # 0 kısa ... 1 uzun
	return {"stiff": lerpf(0.5, 0.3, k), "stiff_tip": lerpf(0.32, 0.12, k), "damp": 0.7, "grav": lerpf(0.1, 0.45, k) * (0.5 if upward else 1.0),
		"drag": 1.6, "air": lerpf(0.04, 0.14, k), "follow": lerpf(0.82, 0.62, k), "col_r": 0.03, "col_from": 1}


## Sarkan kumaş şeridi (bant/başlık bağı, kuşak ucu...): kökten dir yönünde uzanan, ikincil hareketli yassı şerit.
## model_root/dir model uzayında; bone'a takılır. Uçta hafif sivrilir.
func dangle_strip(bone: String, model_root: Vector3, dir: Vector3, length: float, width: float, col: Color, stiff := 0.2, side := Vector3.ZERO, thick := 0.004, parent: Node3D = null, taper := 0.35) -> Dangle:
	if parent == null and (skel == null or skel.find_bone(bone) < 0):
		return null
	var dn = dir.normalized()
	var sd = side.normalized() if side != Vector3.ZERO else dn.cross(Vector3.BACK if absf(dn.z) < 0.9 else Vector3.RIGHT).normalized()
	var nrm = dn.cross(sd).normalized()
	var n = 6
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts = PackedVector3Array()
	var ring = []
	for k in n + 1:
		var t = float(k) / n
		var c = model_root + dn * length * t
		pts.append(c)
		var w = width * (1.0 - taper * t) * 0.5
		ring.append([c - sd * w - nrm * thick, c + sd * w - nrm * thick, c + sd * w + nrm * thick, c - sd * w + nrm * thick])
	for k in n:
		var a = ring[k]; var b = ring[k + 1]
		for q in 4:
			var q2 = (q + 1) % 4
			for vv in [a[q], b[q], b[q2], a[q], b[q2], a[q2]]:
				st.set_color(col)
				st.add_vertex(vv)
	st.generate_normals()
	var mesh = st.commit()
	var pack = Dangle.build(mesh, [{"pts": pts, "stiff": stiff + 0.06, "stiff_tip": stiff * 0.4, "damp": 0.82, "grav": 0.7, "drag": 1.2, "air": 0.3, "follow": 0.5, "col_r": 0.012, "col_from": 1}],
		func(_i, v, _si): return [[0, Dangle.project(pts, v)[0], 1.0]])
	var d = Dangle.make(pack, Props.toon())
	if d == null:
		return null
	if parent != null:
		parent.add_child(d)   # silahın kendi parçası (çekiç kurdelesi): silahla birlikte gelir
	else:
		_attach(bone, Transform3D.IDENTITY).get_child(0).add_child(d)
	_dangles.append(d)
	return d


## Alın koruyucu (kafa) — referans: _tmp/ref_band (Kotetsu/Izumo): kumaş bant saçın ÜSTÜNDEN kafayı sarar
## (saç maskesi bandın içinde kalan saçı keser, bant saçı bastırmış görünür), alında kafaya uyan kavisli metal plaka
## (pahlı kenar, dört köşe perçini, kazınmış köy arması), arkada düğüm + iki kısa sarkan uç (ikincil hareket).
var _face_src: Array = []   # [yüz mesh, model yerleşimi]
var _anime_hair_vs := PackedVector3Array()   # sıfırdan saçın köşeleri (model uzayı): bant saç kütlesinin üstüne oturur


## Sıfırdan saç varsa bant halkası saç KÜTLESİNİN dış yüzeyine genişler (bant saçı sarar; deriye göre kurulunca
## saç bant hizasında yatay dilimle kesiliyordu). Uzun dikenler (kütleden 4.5 cm dışarı) sayılmaz: onlar bandın altından geçer.
## Kafa yüzeyi yön ızgarası (yaw 10° x pitch 10°): skull_c'den o yöndeki en dış deri (gövde mesh'inin kafası + yüz).
## Elipsoit yalnız yüzün derinliğini ölçer; kafatasının arkası çok daha geride -> saç oraya göre oturur (arka dikenler gömülmez)
func _head_radial() -> PackedFloat32Array:
	var NY = 36; var NPT = 19
	var g = PackedFloat32Array()
	g.resize(NY * NPT)
	var src = []
	var geo = _geo_for(look["gender"])   # çizilen gövde (ham VRoid mesh'i değil): kafatası arkası buradan
	src.append(geo["arrays"][Mesh.ARRAY_VERTEX])
	if not _face_src.is_empty():
		var fm: ArrayMesh = _face_src[0]
		var fx: Transform3D = _face_src[1]
		var fv = PackedVector3Array()
		for si in fm.get_surface_count():
			for q in (fm.surface_get_arrays(si)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				fv.append(fx * q)
		src.append(fv)
	var ny = _bp("Neck").y
	for vv in src:
		for q in vv:
			if q.y < ny:   # boyun dahil: ense tutamları boyun derisini izler (havada kalmaz)
				continue
			var d: Vector3 = q - skull_c
			var l = d.length()
			if l > 0.3 or l < 0.01:
				continue
			var dn = d / l
			var yw = rad_to_deg(atan2(dn.x, dn.z)); var pt = rad_to_deg(acos(clampf(dn.y, -1.0, 1.0)))
			var iy = int(floor((yw + 180.0) / 10.0)) % NY
			var ip = mini(int(floor(pt / 10.0)), NPT - 1)
			g[ip * NY + iy] = maxf(g[ip * NY + iy], l)
	# ince çıkıntılar (kulak, burun) yüzey sayılmasın: hücre, 3x3 komşularının medyanından 1 cm'den fazla dışarıdaysa medyana çekilir
	# (yoksa kulağın üstünden geçen tutam dışa fırlıyordu — "örümcek bacağı")
	var g2 = g.duplicate()
	for ip in NPT:
		for iy in NY:
			var v = g[ip * NY + iy]
			var yaw_c = (iy + 0.5) * 10.0 - 180.0
			if v <= 0.0 or absf(yaw_c) < 50.0 or absf(yaw_c) > 130.0:
				continue   # yalnız kulak bölgesi (alın tümseği kırpılırsa ince saç derinin altında kalıp alın görünüyordu)
			var nb = []
			for dp in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					var q = g[clampi(ip + dp, 0, NPT - 1) * NY + posmod(iy + dy, NY)]
					if q > 0.0:
						nb.append(q)
			nb.sort()
			var med = nb[nb.size() / 2]
			if v > med + 0.01:
				g2[ip * NY + iy] = med + 0.01
	g = g2
	return g


func _hair_wrapped_ring(by: float) -> PackedFloat32Array:
	var rad: PackedFloat32Array = (band_ring[1] as PackedFloat32Array).duplicate()
	if _anime_hair_vs.is_empty():
		return rad
	var bins = rad.size()
	var hr = PackedFloat32Array()
	hr.resize(bins)
	for q in _anime_hair_vs:
		if absf(q.y - by) > 0.016:
			continue
		var d = Vector2(q.x - skull_c.x, q.z - skull_c.z)
		var k = int(floor((atan2(d.y, d.x) + PI) / TAU * bins)) % bins
		var r = d.length()
		if r < rad[k] + 0.045:
			hr[k] = maxf(hr[k], r)
	for k in bins:
		rad[k] = maxf(rad[k], hr[k] + 0.004)
	for it in 2:   # yumuşat (bant pürüzsüz dönsün)
		var sm = rad.duplicate()
		for k in bins:
			sm[k] = maxf(rad[k], (rad[(k + bins - 1) % bins] + rad[k] * 2.0 + rad[(k + 1) % bins]) * 0.25)
		rad = sm
	return rad


const BAND_DROP := 0.045   # alın bandı: önden arkaya iniş (m)


## Eğik bant halkası: her yönde bandın o yöndeki yüksekliğinde (by - drop*(1-sin)/2) en dış deri (yüz + gövde kafası)
func _tilted_ring(by: float, drop: float) -> PackedFloat32Array:
	var base: PackedFloat32Array = band_ring[1]
	var bins = base.size()
	var rad = PackedFloat32Array()
	rad.resize(bins)
	var ny = _bp("Neck").y + 0.03
	var srcs = [_geo_for(look["gender"])["arrays"][Mesh.ARRAY_VERTEX]]
	for vv in srcs:
		for q in vv:
			if q.y < ny:
				continue
			var d = Vector2(q.x - skull_c.x, q.z - skull_c.z)
			var l = d.length()
			if l < 0.01 or l > 0.25:
				continue
			var ty = by - drop * (1.0 - d.y / l) * 0.5
			if absf(q.y - ty) > 0.012:
				continue
			var k = int(floor((atan2(d.y, d.x) + PI) / TAU * bins)) % bins
			rad[k] = maxf(rad[k], l)
	for k in bins:
		var ang = (k + 0.5) / bins * TAU - PI
		if sin(ang) > 0.35 or rad[k] <= 0.0:
			rad[k] = maxf(rad[k], base[k]) if sin(ang) > 0.35 else base[k]   # ön (alın): yüz mesh'i ölçüsü
	var sm = rad.duplicate()
	for k in bins:
		sm[k] = maxf(rad[k], (rad[(k + bins - 1) % bins] + rad[k] * 2.0 + rad[(k + 1) % bins]) * 0.25)
	return sm


func _hitai_head(bc: Color) -> void:
	_band_ring_full()
	var by: float = band_ring[0] + 0.01   # göz kapağını kapatmasın
	var keep = band_ring
	if not _anime_hair_vs.is_empty():
		# anime saçı: bant alında başlar, arkaya doğru iner (kulak üstünden ense çıkıntısına); yatay halka büyük
		# kafatasının arkasında tepeden geçip "taç/kap" gibi duruyordu. Saç bu şeritte zaten kafaya bastırılı (maske yok)
		var ring = _tilted_ring(by, BAND_DROP)
		_hitai("Head", Vector3(skull_c.x, by, skull_c.z), ring, bc, 0.036, 0.037, 0.6, 0.0, Vector3(0.22, -1.0, -0.62), true, 0.15, 0.03, 0.011, BAND_DROP)
		return
	band_ring = [band_ring[0], _hair_wrapped_ring(by)]
	_hitai("Head", Vector3(skull_c.x, by, skull_c.z), band_ring[1], bc, 0.036, 0.037, 0.6, 0.008, Vector3(0.22, -1.0, -0.62))
	# saç maskesi: bant yüksekliğinde (öndeki eğim dahil) bandın dışına taşan saç kesilir -> bant saçın üstünde
	hair_mask_band(by - 0.004, 0.046, 0.008)
	band_ring = keep


## ------------------------------------------------------------------ alın koruyucu takılış tarzları (anime ref: refs/bands)
## Tek eşya (Alın Koruyucu), takılış oyuncunun seçimi: look["band_wear"]
const BAND_WEARS := ["alin", "kakashi", "zabuza", "sakura", "boyun", "bel", "kol", "kusak", "bandana", "yamato", "tobirama", "jiraiya", "kisame", "hiruzen", "kankuro", "kakuzu", "baki", "neji", "choji"]
var _band_kanji := ""
const BAND_WEAR_NAMES := {"alin": "Alında", "kakashi": "Göze Eğik", "zabuza": "Yana Yatık", "sakura": "Saç Bandı", "boyun": "Boyunda",
	"bel": "Belde", "kol": "Kolda", "kusak": "Göğüs Kuşağı", "bandana": "Bandana",
	"yamato": "Yanak Korumalı (Yamato/Hashirama)", "tobirama": "Geniş Plaka (Tobirama)", "jiraiya": "Boynuzlu 油 (Jiraiya)", "kisame": "Yukarı Bakan (Kisame)",
	"hiruzen": "Savaş Miğferi (Hiruzen)", "kankuro": "Kulaklı Başlık (Kankurō)", "kakuzu": "Başlık + Maske (Kakuzu)", "baki": "Yarım Peçe (Baki)",
	"neji": "Uzun Bağlı (Neji)", "choji": "Kulak Bezli (Chōji)"}


## Eğik düzlemde kafa (+ saç) çevresi: B yerel X/Z düzlemi bant düzlemi, Y normali; bins açı (yerel atan2(z, x) + PI)
func _plane_ring_head(p0: Vector3, B: Basis, bins := 48) -> PackedFloat32Array:
	AnimeHair._c = skull_c; AnimeHair._r = skull_r; AnimeHair._grid = _head_radial(); AnimeHair._band_y = -INF
	var rad = PackedFloat32Array()
	rad.resize(bins)
	for k in bins:
		var ang = (k + 0.5) / bins * TAU - PI
		var d = B * Vector3(cos(ang), 0, sin(ang))
		var lo = 0.0; var hi = 0.3
		for it in 22:   # yüzeyi ikili arama (içeride: kafa merkezine uzaklık < o yöndeki kafa yarıçapı)
			var t = (lo + hi) * 0.5
			var q = p0 + d * t
			var v = q - skull_c
			var inside = v.length() < AnimeHair._real_r(v.normalized())
			if inside:
				lo = t
			else:
				hi = t
		rad[k] = lo
	# bant KAFANIN şeklini izler (kullanıcı: "kafayı değil saçı baz almış"); saç kütlesi yalnız TEK, düzgün bir pay verir
	# (saçın kökteki kalınlığı ~ köklere yakın saç köşelerinin kafa yüzeyinden uzaklığının alt-orta değeri)
	var nrm = B.y.normalized()
	var offs = []
	for q in _anime_hair_vs:
		var v = q - p0
		if absf(v.dot(nrm)) > 0.01:
			continue
		var lx = v.dot(B.x.normalized()); var lz = v.dot(B.z.normalized())
		var l = Vector2(lx, lz).length()
		var k = int(floor((atan2(lz, lx) + PI) / TAU * bins)) % bins
		var o = l - rad[k]
		if o > 0.0 and o < 0.06:
			offs.append(o)
	var pad = 0.006
	if offs.size() > 8:
		offs.sort()
		pad = clampf(float(offs[int(offs.size() * 0.35)]) + 0.004, 0.006, 0.022)
	var sm = PackedFloat32Array()
	sm.resize(bins)
	for k in bins:
		sm[k] = (rad[(k + bins - 1) % bins] + rad[k] * 2.0 + rad[(k + 1) % bins]) * 0.25 + pad
	return sm


## Gövdede eğik düzlem çevresi (bel, kol, kuşak): düzleme yakın gövde köşeleri, p0'dan rmax içi
func _plane_ring_body(p0: Vector3, B: Basis, rmax: float, pad: float, bins := 36, xlim := 9.0) -> PackedFloat32Array:
	var rad = PackedFloat32Array()
	rad.resize(bins)
	var nrm = B.y.normalized(); var bx = B.x.normalized(); var bz = B.z.normalized()
	var vs: PackedVector3Array = _body_vs()
	for c in find_children("*", "MeshInstance3D", true, false):   # giysi kabukları + yaka/kemiğe takılı parçalar (yüksek yakada bant içeride kalıyordu)
		var nm = String(c.name)
		if not (c.mesh is ArrayMesh) or not c.visible or "Hair" in nm or "Face" in nm or "Eye" in nm or "Brow" in nm or nm == "Body" or c.get_parent() is Dangle:
			continue
		var xf = Transform3D.IDENTITY
		if c.skin == null:   # kemiğe takılı: model uzayına taşı (kemik dinlenme pozu)
			var n: Node = c
			while n != null and n != self:
				if n is Node3D:
					xf = (n as Node3D).transform * xf
				n = n.get_parent()
		vs = vs.duplicate()
		for si in c.mesh.get_surface_count():
			for q in c.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				var w = xf * q
				if absf((w - p0).dot(nrm)) < 0.02:
					vs.append(w)
	for q in vs:
		if absf(q.x - p0.x) > xlim:
			continue   # kuşak: kollar halkaya girmesin (omuzda dışarı fırlıyordu)
		var v = q - p0
		if absf(v.dot(nrm)) > 0.014:
			continue
		var lx = v.dot(bx); var lz = v.dot(bz)
		var l = Vector2(lx, lz).length()
		if l > rmax:
			continue
		var k = int(floor((atan2(lz, lx) + PI) / TAU * bins)) % bins
		rad[k] = maxf(rad[k], l)
	for it in 6:
		for k in bins:
			if rad[k] <= 0.0:
				rad[k] = maxf(rad[(k + 1) % bins], rad[(k + bins - 1) % bins])
	for k in bins:
		rad[k] = maxf(rad[k], rmax * 0.3) + pad
	return rad


## Gövdedeki alın koruyucu (boyun, bel, kol, kuşak): kıyafet tekniğiyle (SurfaceKit) beden kabuğuna DERİLİ bant + plaka + arma;
## her köşe en yakın kabuk köşesinin kemik ağırlıklarını taşır -> vücutla birlikte bükülür, kemiğe çakılı katı halka değil
func _band_skinned(p0: Vector3, B: Basis, ring: PackedFloat32Array, bc: Color, h: float, a_half: float, tails := Vector3.ZERO, tail_bone := "") -> void:
	var src: ArrayMesh = _shell_cache.get(look["gender"])
	if src == null or not _sk_begin(src):
		return
	var bins = ring.size()
	var r_at = func(ang: float) -> float: return ring[int(floor((wrapf(ang, -PI, PI) + PI) / TAU * bins)) % bins]
	var wd = B.y.normalized()
	var pts = []; var outs = []
	var n = 48
	for k in n:
		var ang = float(k) / n * TAU - PI
		var o = (B * Vector3(cos(ang), 0, sin(ang))).normalized()
		pts.append(p0 + o * r_at.call(ang))
		outs.append(o)
	_sk_band(pts, outs, wd, h, 0.005, bc, true)
	# metal plaka: ön yayı izleyen pahlı parçalar (kutu dizisi)
	var steel = Color(0.78, 0.8, 0.85)
	var front = PI * 0.5
	var m = 8
	for k in m:
		var a0 = front - a_half + 2.0 * a_half * k / m
		var a1 = front - a_half + 2.0 * a_half * (k + 1) / m
		var o0 = (B * Vector3(cos(a0), 0, sin(a0))).normalized(); var o1 = (B * Vector3(cos(a1), 0, sin(a1))).normalized()
		var q0 = p0 + o0 * (r_at.call(a0) + 0.007); var q1 = p0 + o1 * (r_at.call(a1) + 0.007)
		var om = (o0 + o1).normalized()
		_sk_box((q0 + q1) * 0.5, (q1 - q0) * 0.5, wd * h * 0.52, om * 0.0035, steel if k > 0 and k < m - 1 else steel.darkened(0.15))
	var plate_mi = _sk_end({})
	# arma: plakanın önünde dokulu, derili şerit
	if _sk_begin(src):
		_sk["ouv"] = PackedVector2Array()
		var sa = a_half * 0.62
		var sh = h * 0.62
		var base = 0
		for k in 11:
			var u = float(k) / 10.0
			var ang = front + sa - 2.0 * sa * u
			var o = (B * Vector3(cos(ang), 0, sin(ang))).normalized()
			var q = p0 + o * (r_at.call(ang) + 0.0115)
			for sy in [-1.0, 1.0]:
				var pp = q + wd * sh * 0.5 * sy
				_sk["ov"].append(pp); _sk["on"].append(o); _sk["oc"].append(Color.WHITE)
				_sk["ouv"].append(Vector2(u, 0.0 if sy > 0 else 1.0))
				var j = _sk_nearest(q)
				_sk["ob"].append_array(_sk["b"][j]); _sk["ow"].append_array(_sk["w"][j])
		for k in 10:
			var a = k * 2
			_sk["oi"].append_array(PackedInt32Array([a, a + 2, a + 3, a, a + 3, a + 1]))
		var smi = _sk_end({})
		if smi:
			var sm = StandardMaterial3D.new()
			sm.albedo_texture = symbol_texture(look["village"], look["band_style"] == "slashed")
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm.cull_mode = BaseMaterial3D.CULL_DISABLED
			smi.material_override = sm
	# arkada düğüm + iki sarkan uç (ikincil hareket)
	if tails != Vector3.ZERO and tail_bone != "":
		var back = -PI * 0.5
		var ob = (B * Vector3(cos(back), 0, sin(back))).normalized()
		var kp = p0 + ob * (r_at.call(back) + 0.012)
		var rv = MB.new()
		rv.add("sphere", kp, Vector3(0.026, 0.024, 0.016), bc.darkened(0.08), Vector3.ZERO, 7)
		_mesh_on(tail_bone, rv.build(Props.toon()), Transform3D.IDENTITY)
		for sx in [-1.0, 1.0]:
			dangle_strip(tail_bone, kp + Vector3(0.006 * sx, -0.004, 0) + ob * 0.004, Vector3(tails.x * sx, tails.y, tails.z), 0.14, 0.028, bc, 0.16, Vector3(1, 0, 0), 0.003)


## Hiruzen savaş miğferi (Striker Hiruzen_Helmet + anime): renk = eşya ya da alın koruyucu rengi
func _hiruzen_helmet(hg: Color) -> void:
	var hw = clampf(head_ab.size.x, 0.16, 0.26) if head_ab.size.x > 0.05 else 0.2
	# alın ortası, arkada enseye iner), alında KÖYÜN sembollü alın koruyucu plakası, kulak hizasından yanaklara yapışık
	# inen, halkalarla bağlı 4 zeytin zırh plakası
	_band_ring_full()
	var by = band_ring[0]
	var white: Color = hg   # miğfer rengi eşya renginden (boyanabilir; varsayılan beyaz)
	_helmet_shell(white, by + 0.03, 0.11)
	hair_mask_plane(Vector3.UP, Vector3(0, by - 0.02, 0))
	_hitai("Head", Vector3(skull_c.x, by + 0.014, skull_c.z), band_ring[1], white.darkened(0.06), 0.04, 0.042, 0.64, 0.004, Vector3.ZERO, true, 0.0, 0.0, 0.014)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var olive = Color(0.46, 0.45, 0.3)
	var iron = Color(0.16, 0.16, 0.15)
	var bvs = _body_vs()
	for sx in [1.0, -1.0]:
		var px = 0.0
		var pz_sum = 0.0; var pz_n = 0
		for q in bvs:   # kulak hizasında yanağın dış yüzü (plaka deriye yapışsın)
			if absf(q.y - (by - 0.05)) < 0.02 and signf(q.x - skull_c.x) == sx and q.z > skull_c.z - 0.03 and q.z < skull_c.z + 0.04:
				px = maxf(px, absf(q.x - skull_c.x)); pz_sum += q.z; pz_n += 1
		if px <= 0.0:
			px = hw * 0.5
		var pz = pz_sum / maxf(1.0, pz_n)
		var b = Basis(Vector3(0, 0, -sx), Vector3.UP, Vector3(sx, 0, 0))
		_box_basis(st, Vector3(skull_c.x + sx * (px + 0.012), by + 0.012, pz), b, Vector3(0.05, 0.03, 0.01), white.darkened(0.12))   # miğfer kulak kanadı
		for q in 4:
			var y = by - 0.022 - q * 0.046
			var c = Vector3(skull_c.x + sx * (px + 0.016 + q * 0.003), y, pz + 0.004)
			var bq = b.rotated(Vector3(0, 0, 1), sx * deg_to_rad(4.0 + q * 2.0))
			_box_basis(st, c, bq, Vector3(0.062, 0.042, 0.009), olive)
			_box_basis(st, c + bq.z * 0.0055 + bq.y * 0.015, bq, Vector3(0.058, 0.005, 0.002), olive.darkened(0.25))
			for t in [-1.0, 1.0]:
				_box_basis(st, c + bq.x * (t * 0.02) + bq.y * 0.024 + bq.z * 0.005, bq, Vector3(0.007, 0.012, 0.009), iron)
	st.generate_normals()
	var hm = _mesh_on("Head", st.commit(), Transform3D.IDENTITY)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/toon.gdshader")
	mat.set_shader_parameter("rim_amount", 0.2)
	hm.material_override = mat


func _band_wear(bc: Color, wear: String) -> void:
	var hw = clampf(head_ab.size.x, 0.16, 0.26) if head_ab.size.x > 0.05 else 0.2
	match wear:
		"boyun":   # ref Hinata: boynu saran bant, plaka gırtlakta, ensede düğüm
			var nk = _bp("Neck")
			var p0 = Vector3(nk.x, nk.y + 0.035, nk.z)
			_band_skinned(p0, Basis.IDENTITY, _plane_ring_body(p0, Basis.IDENTITY, 0.12, 0.006), bc, 0.032, 0.75, Vector3(0.25, -1.0, -0.5), "Neck")
		"bandana":
			_hitai_bandana(bc)
		"kakashi", "zabuza", "sakura":
			_band_ring_full()
			var B: Basis
			var p0: Vector3
			var ph = 0.037
			match wear:
				"kakashi":   # ref kakashi_4/5: sol gözü örten, sola doğru inen eğik bant; plaka gözün üstüne kaymış
					B = Basis(Vector3.UP, deg_to_rad(-22.0)) * Basis(Vector3(0, 0, 1), deg_to_rad(20.0))
					p0 = Vector3(skull_c.x, eye_center_model.y + 0.012, skull_c.z)
				"zabuza":   # ref zabuza_3/5: başın yanına yatık takılmış; plaka şakakta, bant karşı tarafta yukarı çıkar
					B = Basis(Vector3.UP, deg_to_rad(-75.0)) * Basis(Vector3(1, 0, 0), deg_to_rad(-24.0))
					p0 = Vector3(skull_c.x, band_ring[0] + 0.02, skull_c.z)
				"sakura":   # ref sakura_0/2/4: saç bandı gibi tepeden geçer, plaka tepe-önde, arkada saçın altından enseye iner
					B = Basis(Vector3(1, 0, 0), deg_to_rad(-58.0))
					p0 = skull_c + Vector3(0, 0.0, -0.005)
			var ring = _plane_ring_head(p0, B)
			_hitai("Head", p0, ring, bc, 0.036, ph, 0.6, 0.0, Vector3(0.22, -1.0, -0.62), true, 0.15 if wear != "sakura" else 0.1, 0.03, 0.004, 0.0, B)
		"bel":   # ref Ino / Gai: belde kemer gibi, plaka önde
			var hp = _bp("Hips")
			var sp = _bp("Spine")
			var p0 = hp.lerp(sp, 0.55)
			_band_skinned(p0, Basis.IDENTITY, _plane_ring_body(p0, Basis.IDENTITY, 0.3, 0.02), bc, 0.04, 0.42, Vector3(0.25, -1.0, -0.4), "Hips")   # 2 cm: üst giysinin eteği/kıvrımlarının üstünde
		"kol":   # ref Shikamaru: sol üst kolda, plaka dışa bakar
			var a = _bp("LeftUpperArm"); var b = _bp("LeftLowerArm")
			var ax = (a - b).normalized()   # dirsekten omuza: arma dik okunur (eskiden ters duruyordu)
			var side = Vector3(signf(a.x - _bp("Chest").x), 0, 0)   # kolun dış yanı (eskiden hep +X: sol kolda plaka gövdeye bakıyordu)
			var outv = (side - ax * ax.dot(side)).normalized()
			var B = Basis(ax.cross(outv).normalized(), ax, outv).orthonormalized()
			var p0 = a.lerp(b, 0.42)
			_band_skinned(p0, B, _plane_ring_body(p0, B, 0.09, 0.006), bc, 0.032, 0.8)
		"kusak":   # Gaara tarzı: sağ omuzdan sol kalçaya çapraz kuşak, plaka göğüste
			var ch = _bp("Chest")
			var B = Basis(Vector3(0, 0, 1), deg_to_rad(38.0))
			_band_skinned(ch, B, _plane_ring_body(ch, B, 0.4, 0.01, 36, 0.17), bc, 0.042, 0.3)
		"yamato":   # ref yamato_0/2/4 (Hashirama'nınkiyle aynı): plaka + iki yanda şakaktan çeneye inen metal yanak koruması, başı saran koyu başlık
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(bc.darkened(0.45), by + 0.02, 0.12, 0.012)
			hair_mask_plane(Vector3.UP, Vector3(0, by, 0))
			_hitai_head(bc)
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var steel = Color(0.76, 0.78, 0.83)
			var bvs = _body_vs()
			for sx in [1.0, -1.0]:
				var px = 0.0; var pz = 0.0; var pn = 0
				for q in bvs:
					if absf(q.y - (by - 0.06)) < 0.025 and signf(q.x - skull_c.x) == sx and q.z > skull_c.z + 0.03 and q.z < skull_c.z + 0.08:   # şakak-yanak (kulağın önü)
						px = maxf(px, absf(q.x - skull_c.x)); pz += q.z; pn += 1
				if px <= 0.0:
					px = hw * 0.5
				pz /= maxf(1.0, pn)
				var b = Basis(Vector3(0, 0, -sx), Vector3.UP, Vector3(sx, 0, 0)).rotated(Vector3(0, 0, 1), sx * deg_to_rad(5.0))
				_box_basis(st, Vector3(skull_c.x + sx * (px + 0.008), by - 0.065, pz + 0.006), b, Vector3(0.05, 0.12, 0.006), steel)
				_box_basis(st, Vector3(skull_c.x + sx * (px + 0.012), by - 0.065, pz + 0.006), b, Vector3(0.04, 0.008, 0.003), steel.darkened(0.25))
			st.generate_normals()
			var cm = st.commit()
			cm.surface_set_material(0, Props.toon())
			_mesh_on("Head", cm, Transform3D.IDENTITY)
		"tobirama":   # ref tobirama_3/4/5: alnı şakaklara kadar saran geniş, uzun plaka
			_band_ring_full()
			var by: float = band_ring[0] + 0.01
			_hitai("Head", Vector3(skull_c.x, by, skull_c.z), _tilted_ring(by, BAND_DROP) if not _anime_hair_vs.is_empty() else band_ring[1], bc, 0.04, 0.046, 1.15, 0.0, Vector3(0.22, -1.0, -0.62), true, 0.15, 0.03, 0.011, BAND_DROP if not _anime_hair_vs.is_empty() else 0.0)
		"jiraiya":   # ref jiraiya_2/3/4: büyük plaka, ortada 油, tepede iki küçük boynuz
			_band_ring_full()
			var by: float = band_ring[0] + 0.012
			_band_kanji = "油"
			_hitai("Head", Vector3(skull_c.x, by, skull_c.z), _tilted_ring(by, BAND_DROP) if not _anime_hair_vs.is_empty() else band_ring[1], bc, 0.04, 0.056, 0.62, 0.0, Vector3(0.22, -1.0, -0.62), true, 0.15, 0.03, 0.011, BAND_DROP if not _anime_hair_vs.is_empty() else 0.0)
			_band_kanji = ""
			var fr = _ring_r_at(PI * 0.5)
			var mk = MB.new()
			for sx in [-1.0, 1.0]:
				var hp = Vector3(skull_c.x + sx * 0.04, by + 0.045, skull_c.z + fr + 0.004)
				mk.add("cone", hp, Vector3(0.034, 0.05, 0.026), Color(0.78, 0.8, 0.85), Vector3(-8, 0, -sx * 18.0), 8)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
		"kisame":   # ref kisame_4: plaka alında yukarı bakar (öne-yukarı eğik), bant arkaya doğru iner
			_band_ring_full()
			var B = Basis(Vector3(1, 0, 0), deg_to_rad(-16.0))
			var p0 = Vector3(skull_c.x, band_ring[0] + 0.012, skull_c.z)
			_hitai("Head", p0, _plane_ring_head(p0, B), bc, 0.036, 0.04, 0.62, 0.0, Vector3(0.22, -1.0, -0.62), true, 0.15, 0.03, 0.004, 0.0, B)
		"hiruzen":
			_hiruzen_helmet(bc)
		"kankuro":   # ref kankuro: başı ve yanakları saran siyah kapüşon, tepede iki kedi kulağı, alında plaka
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(Color(0.09, 0.09, 0.11), by + 0.02, 0.24, 0.02, 0.0, 0.16)
			hair_mask_plane(Vector3.UP, Vector3(0, by, 0))
			_hitai("Head", Vector3(skull_c.x, by + 0.012, skull_c.z), band_ring[1], bc, 0.036, 0.037, 0.6, 0.0, Vector3.ZERO, true, 0.0, 0.0, 0.03)
			var tp = by
			for q in _body_vs():
				if absf(q.x - skull_c.x) < 0.05 and q.y > tp:
					tp = q.y
			var mk = MB.new()
			for sx in [-1.0, 1.0]:
				mk.add("cone", Vector3(skull_c.x + sx * hw * 0.42, tp + 0.03, skull_c.z - 0.01), Vector3(0.06, 0.07, 0.03), Color(0.09, 0.09, 0.11), Vector3(0, 0, -sx * 14.0), 4)
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
		"kakuzu":   # ref kakuzu_2/4: başı saran koyu başlık, gözlerin altından boynu örten maske, alında plaka
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(Color(0.2, 0.2, 0.22), by + 0.02, 0.26, 0.02, 0.0, 0.17)
			hair_mask_plane(Vector3.UP, Vector3(0, by, 0))
			_hitai("Head", Vector3(skull_c.x, by + 0.012, skull_c.z), band_ring[1], bc, 0.036, 0.037, 0.6, 0.0, Vector3.ZERO, true, 0.0, 0.0, 0.03)
			var fr = _ring_r_at(PI * 0.5)
			var mk = MB.new()
			mk.add("sphere", Vector3(skull_c.x, eye_center_model.y - 0.085, skull_c.z + fr * 0.5), Vector3(hw * 0.78, 0.12, fr * 1.0), Color(0.08, 0.08, 0.09), Vector3.ZERO, 14)   # burun kökünden çeneye maske
			_mesh_on("Head", mk.build(Props.toon()), Transform3D.IDENTITY)
		"baki":   # ref baki_0/1: başın üstünü saran beyaz bez, alında plaka, bandın sol yanından yüzün yarısını örten peçe
			_band_ring_full()
			var by = band_ring[0]
			_helmet_shell(Color(0.9, 0.89, 0.85), by + 0.012, 0.08, 0.02)
			hair_mask_plane(Vector3.UP, Vector3(0, by, 0))
			_hitai("Head", Vector3(skull_c.x, by + 0.012, skull_c.z), band_ring[1], bc, 0.036, 0.037, 0.6, 0.0, Vector3(0.22, -1.0, -0.62), true, 0.12, 0.03, 0.03)
			var fr = _ring_r_at(PI * 0.5)
			for k in 3:
				dangle_strip("Head", Vector3(skull_c.x + 0.02 + k * 0.022, by - 0.012, skull_c.z + fr + 0.02 - k * 0.012), Vector3(0.05, -1.0, 0.12), 0.16, 0.03, Color(0.92, 0.91, 0.87).darkened(0.03 * k), 0.4, Vector3(1, 0, 0), 0.003, null, 0.0)
		"neji":   # ref neji_0/3: alında, arkada belden aşağı uzun sarkan iki bağ
			_band_ring_full()
			var by: float = band_ring[0] + 0.01
			_hitai("Head", Vector3(skull_c.x, by, skull_c.z), _tilted_ring(by, BAND_DROP) if not _anime_hair_vs.is_empty() else band_ring[1], bc, 0.036, 0.037, 0.6, 0.0, Vector3(0.12, -1.0, -0.3), true, 0.34, 0.03, 0.011, BAND_DROP if not _anime_hair_vs.is_empty() else 0.0)
		"choji":   # ref choji_0/1 (Part 1): alında plaka, şakaklardan kulakları örterek sarkan iki uzun bez
			_hitai_head(bc)
			_band_ring_full()
			var by = band_ring[0]
			for sx in [-1.0, 1.0]:
				var r = _ring_r_at(PI if sx < 0 else 0.0)
				dangle_strip("Head", Vector3(skull_c.x + sx * (r + 0.012), by + 0.005, skull_c.z - 0.005), Vector3(sx * 0.1, -1.0, 0.0), 0.16, 0.055, bc, 0.3, Vector3(0, 0, 1), 0.004, null, 0.0)
		_:
			_hitai_head(bc)


## Boyun alın koruyucusu (Hinata tarzı): boynu saran bant, gırtlağın önünde kavisli plaka, ensede düğüm + iki kısa uç
func _hitai_neck(bc: Color) -> void:
	var ny = _bp("Neck").y + 0.035
	var bins = 24
	var rad = PackedFloat32Array()
	rad.resize(bins)
	var nk = _bp("Neck")
	for q in _body_vs():
		if absf(q.y - ny) > 0.012:
			continue
		var d = Vector2(q.x - nk.x, q.z - nk.z)
		if d.length() > 0.12:
			continue
		var k = int(floor((atan2(d.y, d.x) + PI) / TAU * bins)) % bins
		rad[k] = maxf(rad[k], d.length())
	for it in 4:
		for k in bins:
			if rad[k] <= 0.0:
				rad[k] = maxf(rad[(k + 1) % bins], rad[(k + bins - 1) % bins])
	for k in bins:
		rad[k] = maxf(rad[k], 0.04) + 0.006   # yakanın/gömleğin üstünde
	_hitai("Neck", Vector3(nk.x, ny, nk.z), rad, bc, 0.032, 0.034, 0.75, 0.0, Vector3(0.25, -1.0, -0.5))


## Bandana alın koruyucu (Izumo/Asuma): bant + plaka (ortak kurucu) ve bandın üstünde kafanın tepesini ve arkasını
## enseye kadar sıkıca saran kumaş başlık; altındaki saç kesilir (enseden/yanlardan taşan uçlar kalır).
func _hitai_bandana(cc: Color) -> void:
	_band_ring_full()
	var by: float = band_ring[0] + 0.01
	_hitai("Head", Vector3(skull_c.x, by, skull_c.z), band_ring[1], cc, 0.036, 0.037, 0.6, 0.008, Vector3(0.22, -1.0, -0.62))
	head_cap(cc, by + 0.016, 0.07)
	hair_mask_band(by - 0.004, 0.046, 0.008)


## Kumaş alın bandı (hachimaki, kafa bandajı, haydut bezi bandı): plakasız ortak bant; dy: alın bandı hizasına göre,
## saç maskesiyle saçın üstünde durur. Dönüş: bant merkezi y.
func cloth_band(cc: Color, dy := 0.0, bh := 0.04, tail_len := 0.24, tail_w := 0.032, tilt := 0.006, rpad := 0.011) -> float:
	_band_ring_full()
	if band_ring.is_empty():
		return skull_c.y
	var by: float = band_ring[0] + 0.01 + dy
	_hitai("Head", Vector3(skull_c.x, by, skull_c.z), band_ring[1], cc, bh, 0.0, 0.0, tilt, Vector3(0.25, -1.0, -0.6), false, tail_len, tail_w, rpad)
	hair_mask_band(by - absf(tilt) * 0.5, bh + absf(tilt) + 0.008, 0.008)
	return by


## Gövde kafasının gerçek tepesi (model y): şapkalar buna oturur (yüz mesh'inden ölçülen htop alçak kalıyordu)
func head_top() -> float:
	if _sk_key != "" and _top_cache.has(_sk_key):
		return _top_cache[_sk_key]
	var top = skull_c.y + skull_r.y
	if body_mesh != null and body_mesh.mesh != null:
		for q in _body_vs():
			if q.y > skull_c.y and absf(q.x) < 0.05:
				top = maxf(top, q.y)
	if _sk_key != "":
		_top_cache[_sk_key] = top
	return top


## Kapüşon (kafa kısmı, Head kemiğine): kafayı bol saran kumaş; önde yüz açıklığı (alından çeneye oval),
## yanlar ve arka çene hizasının altına iner (omuz eteği gövdeye derili ayrı parça). deep: "derin" = önü öne taşan,
## yüzü gölgeleyen; "hafif" = ince, kafaya yakın. Saç tamamen içeride (OutfitParts saçı gizler).
func hood(cc: Color, deep := "") -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	var pad = {"derin": 0.04, "hafif": 0.02}.get(deep, 0.03)
	var brow = eye_center_model.y + 0.05
	var y_lo = _bp("Neck").y + 0.02
	var top = head_top() + pad + 0.01
	var cen = Vector3(skull_c.x, 0, skull_c.z)
	# gövde kafa/boyun yarıçapı: 32 yön x yükseklik dilimleri (1.5 cm)
	var nb = 32
	var dy = 0.015
	var rmap = {}
	for q in _body_vs():
		if q.y < y_lo - 0.02:
			continue
		var d = Vector2(q.x - cen.x, q.z - cen.z)
		if d.length() > 0.2:
			continue
		var k = Vector2i(int(floor((atan2(d.y, d.x) + PI) / TAU * nb)) % nb, int(floor((q.y - y_lo) / dy)))
		rmap[k] = maxf(rmap.get(k, 0.0), d.length())
	if face_mi != null:
		for si in face_mi.mesh.get_surface_count():
			for v in face_mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				var q = _face_xf * v
				var d = Vector2(q.x - cen.x, q.z - cen.z)
				var k = Vector2i(int(floor((atan2(d.y, d.x) + PI) / TAU * nb)) % nb, int(floor((q.y - y_lo) / dy)))
				rmap[k] = maxf(rmap.get(k, 0.0), d.length())
	var rows = int(ceil((top - y_lo) / dy)) + 1
	var na = 40
	var grid = []
	var r_top_ref = 0.0
	for j in rows:
		var y = minf(y_lo + j * dy, top)
		var row = []
		for k in na + 1:
			var a = float(k) / na * TAU - PI
			var bk = int(floor((a + PI) / TAU * nb)) % nb
			var r = 0.0
			for jj in range(j - 1, j + 2):   # komşu dilimlerle yumuşat
				r = maxf(r, float(rmap.get(Vector2i(bk, jj), 0.0)))
			if r <= 0.0:
				r = 0.07
			r += pad
			# tepeye doğru kapan (yarım küre gibi), alnın üstünde kumaş bolluğu
			var tt = clampf((y - brow) / maxf(top - brow, 0.01), 0.0, 1.0)
			if tt > 0.0:
				r = r * sqrt(maxf(0.0, 1.0 - tt * tt)) + pad * 0.5 * (1.0 - tt)
			# derin kapüşon: önde alın hizasında öne taşan siper
			var df = absf(wrapf(a - PI * 0.5, -PI, PI))
			if deep == "derin" and df < 1.0:
				r += 0.035 * (1.0 - df) * clampf(1.0 - absf(y - brow) / 0.08, 0.0, 1.0)
			row.append(cen + Vector3(cos(a) * r, y, sin(a) * r))
		grid.append(row)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var chin = eye_center_model.y - 0.11
	for j in rows - 1:
		var y = y_lo + (j + 0.5) * dy
		for k in na:
			var a = (float(k) + 0.5) / na * TAU - PI
			var df = absf(wrapf(a - PI * 0.5, -PI, PI))
			# yüz açıklığı: alın hizasından çeneye oval
			var open_w = 0.0
			if y < brow + 0.015 and y > chin:
				var u = (y - chin) / (brow + 0.015 - chin)
				open_w = 0.95 * sqrt(clampf(1.0 - pow(u * 2.0 - 1.0, 2.0) * 0.55, 0.0, 1.0))
			elif y <= chin:
				open_w = 0.5
			if df < open_w:
				continue
			var q = [grid[j][k], grid[j][k + 1], grid[j + 1][k + 1], grid[j + 1][k]]
			var sh = 0.9 + 0.1 * float(j) / rows
			if open_w > 0.0 and df < open_w + 0.12:
				sh *= 0.8   # açıklık kenarı: katlı kenar gölgesi
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(cc * Color(sh, sh, sh))
				st.add_vertex(q[i])
			for i in [0, 2, 1, 0, 3, 2]:   # iç yüz (açıklıktan görünür, koyu): biraz içeride (dış yüzle titreşmesin)
				var c0 = Vector3(cen.x, q[i].y, cen.z)
				st.set_color(cc.darkened(0.45))
				st.add_vertex(c0 + (q[i] - c0) * 0.96)
	st.generate_normals()
	_mesh_on("Head", st.commit(), Transform3D.IDENTITY).material_override = Props.toon()


var cap_grid: Array = []   # son head_cap ızgarası [satır (alt->tepe)][açı] (kaburga/süs için)
var cap_cen := Vector3.ZERO


## Samuray kabutosu (ref: _tmp/ref_kabuto): kafaya oturan lake çanak (hachi) + dikey kaburgalar, alında siper (mabizashi),
## yanlardan/arkadan açılarak inen 4 kat lamel boyun koruması (shikoro) ve aralarında bağcık şeritleri, yüz yanlarında
## dışa kıvrık kanatlar (fukigaeshi), önde altın arma: hilal (varsayılan) ya da V boynuz (kuwagata).
func kabuto(cc: Color, crest := "") -> void:
	_band_ring_full()
	if band_ring.is_empty():
		return
	var by: float = band_ring[0] + 0.012
	var gold = Color(0.9, 0.72, 0.25)
	var lace = Color(0.85, 0.45, 0.15) if cc.r < 0.4 else Color(0.15, 0.12, 0.1)
	head_cap(cc, by, 0.02, 0.06, 0.028, 0.03, false)
	# kaburgalar: çanak boyunca 14 meridyen, hafif kabarık koyu şerit
	var mb = MB.new()
	var rows: int = cap_grid.size()
	var na: int = cap_grid[0].size() - 1
	for r in 14:
		var k = int(round(float(r) / 14.0 * na)) % na
		for j in rows - 2:
			var p0: Vector3 = cap_grid[j][k]; var p1: Vector3 = cap_grid[j + 1][k]
			var out = (p0 - cap_cen).normalized()
			mb.add_xf("box", Transform3D(Basis.looking_at(p1 - p0, out) * Basis.from_scale(Vector3(0.006, 0.004, p0.distance_to(p1) * 1.05)), (p0 + p1) * 0.5 + out * 0.002), cc.darkened(0.3))
	# tepe süsü (tehen): küçük halka
	var tp: Vector3 = cap_grid[rows - 1][0]
	mb.add("cyl", tp + Vector3(0, 0.004, 0), Vector3(0.03, 0.008, 0.03), gold, Vector3.ZERO, 10)
	var rad: PackedFloat32Array = band_ring[1]
	var bins = rad.size()
	var r_at = func(ang: float) -> float: return rad[int(floor((wrapf(ang, -PI, PI) + PI) / TAU * bins)) % bins] + 0.03
	var cen = Vector3(skull_c.x, by, skull_c.z)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quad = func(q: Array, col: Color) -> void:
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(col); st.add_vertex(q[i])
		for i in [0, 2, 1, 0, 3, 2]:
			st.set_color(col.darkened(0.35)); st.add_vertex(q[i])
	# siper: alın önünde öne-aşağı eğik dar yay
	for k in 16:
		var a0 = PI * 0.5 - 0.9 + 1.8 * k / 16.0
		var a1 = PI * 0.5 - 0.9 + 1.8 * (k + 1) / 16.0
		var w0 = 1.0 - pow(absf(a0 - PI * 0.5) / 0.9, 2.0) * 0.6
		var w1 = 1.0 - pow(absf(a1 - PI * 0.5) / 0.9, 2.0) * 0.6
		var i0 = cen + Vector3(cos(a0), 0, sin(a0)) * r_at.call(a0)
		var i1 = cen + Vector3(cos(a1), 0, sin(a1)) * r_at.call(a1)
		var o0 = cen + Vector3(cos(a0), 0, sin(a0)) * (r_at.call(a0) + 0.045 * w0) + Vector3(0, -0.02 * w0, 0)
		var o1 = cen + Vector3(cos(a1), 0, sin(a1)) * (r_at.call(a1) + 0.045 * w1) + Vector3(0, -0.02 * w1, 0)
		quad.call([i0, i1, o1, o0], cc.darkened(0.15))
	# shikoro: 4 kat, yüzün önü (±62°) açık, her kat aşağıda ve daha geniş; katlar arasında bağcık şeridi
	var open = 1.08
	for layer in 4:
		var ytop = by + 0.005 - layer * 0.03
		var ybot = ytop - 0.04
		var flare0 = 0.012 + layer * 0.022
		var flare1 = flare0 + 0.03
		var n = 30
		for k in n:
			var a0 = PI * 0.5 + open + (TAU - 2.0 * open) * k / n
			var a1 = PI * 0.5 + open + (TAU - 2.0 * open) * (k + 1) / n
			var d0 = Vector3(cos(a0), 0, sin(a0)); var d1 = Vector3(cos(a1), 0, sin(a1))
			var t0 = cen + d0 * (r_at.call(a0) + flare0) + Vector3(0, ytop - by, 0)
			var t1 = cen + d1 * (r_at.call(a1) + flare0) + Vector3(0, ytop - by, 0)
			var b0 = cen + d0 * (r_at.call(a0) + flare1) + Vector3(0, ybot - by, 0)
			var b1 = cen + d1 * (r_at.call(a1) + flare1) + Vector3(0, ybot - by, 0)
			quad.call([t0, t1, b1, b0], cc.darkened(0.08 * layer))
			# bağcık: katın alt kenarında ince renkli şerit
			var l0 = b0 + Vector3(0, 0.007, 0) + d0 * 0.0015; var l1 = b1 + Vector3(0, 0.007, 0) + d1 * 0.0015
			quad.call([l0, l1, b1 + d1 * 0.0015, b0 + d0 * 0.0015], lace)
		# fukigaeshi: üst katın iki ucu dışa kıvrık kanat
		if layer == 0:
			for sx in [-1.0, 1.0]:
				var a = PI * 0.5 + sx * open
				var d = Vector3(cos(a), 0, sin(a))
				var side = Vector3(0, 1, 0).cross(d) * (-sx)
				var p0 = cen + d * (r_at.call(a) + flare0) + Vector3(0, 0.005, 0)
				var pts = [p0, p0 + Vector3(0, -0.06, 0), p0 + Vector3(0, -0.06, 0) + d * 0.04 + side * 0.045, p0 + d * 0.035 + side * 0.05]
				quad.call(pts, cc.darkened(0.05))
				quad.call([pts[3], pts[2], pts[2] + d * 0.002 - side * 0.006, pts[3] + d * 0.002 - side * 0.006], gold)
	st.generate_normals()
	_mesh_on("Head", st.commit(), Transform3D.IDENTITY).material_override = Props.toon()
	# arma: alnın önünde altın hilal ya da V boynuz
	var fz = skull_c.z + r_at.call(PI * 0.5) + 0.012
	var base = Vector3(skull_c.x, by + 0.02, fz)
	if crest == "kuwagata":
		for sx in [-1.0, 1.0]:
			for k in 6:
				var t0 = float(k) / 6.0; var t1 = float(k + 1) / 6.0
				var p0 = base + Vector3(sx * (0.012 + t0 * 0.07), t0 * 0.17 + t0 * t0 * 0.02, 0.004 + t0 * 0.02)
				var p1 = base + Vector3(sx * (0.012 + t1 * 0.07), t1 * 0.17 + t1 * t1 * 0.02, 0.004 + t1 * 0.02)
				mb.add_xf("box", Transform3D(Basis.looking_at(p1 - p0, Vector3.BACK) * Basis.from_scale(Vector3(0.016 * (1.0 - t0 * 0.5), 0.005, p0.distance_to(p1) * 1.1)), (p0 + p1) * 0.5), gold)
	else:
		for k in 20:
			var u0 = -1.0 + 2.0 * k / 20.0; var u1 = -1.0 + 2.0 * (k + 1) / 20.0
			var p0 = base + Vector3(u0 * 0.15, 0.06 * u0 * u0 + 0.008, 0.004)
			var p1 = base + Vector3(u1 * 0.15, 0.06 * u1 * u1 + 0.008, 0.004)
			var wv = 0.004 + 0.016 * (1.0 - absf((u0 + u1) * 0.5))
			mb.add_xf("box", Transform3D(Basis.looking_at(p1 - p0, Vector3.BACK) * Basis.from_scale(Vector3(0.004, wv, p0.distance_to(p1) * 1.08)), (p0 + p1) * 0.5), gold)
	mb.add("sphere", base, Vector3(0.024, 0.024, 0.012), gold, Vector3.ZERO, 8)
	_mesh_on("Head", mb.build(Props.toon()), Transform3D.IDENTITY)


## ------------------------------------------------------------------ yüz kabuğu (maske, peçe, sargı, boya)
## Yüz + kafa + boyun yüzeyinin kafa ekseni etrafında (skull_c.x, skull_c.z) yön (a: atan2(z, x), önde PI/2) ve yükseklik
## başına yarıçapı. Yüz parçaları bu yüzeye oturur: havada durmaz, yüzün içine girmez.
var _fmap := {}
const FM_NA := 48
const FM_DY := 0.008


func _face_map() -> void:
	if not _fmap.is_empty():
		return
	if _sk_key != "" and _fmap_cache.has(_sk_key):
		_fmap = _fmap_cache[_sk_key]
		return
	var pts = []
	var chin0 = eye_center_model.y - 0.1
	if face_mi != null:
		for si in face_mi.mesh.get_surface_count():
			for v in face_mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				var fq = _face_xf * v
				if fq.y > chin0 - 0.01:   # çene altı (yatay yüzey) haritayı disk gibi açıyordu: orada yalnız boyun
					pts.append(fq)
	var chest_y = _bp("UpperChest").y + 0.05
	if body_mesh != null and body_mesh.mesh != null:
		for q in _body_vs():
			if q.y > chest_y:
				pts.append(q)
	var chin = eye_center_model.y - 0.1
	for q in pts:
		var d = Vector2(q.x - skull_c.x, q.z - skull_c.z)
		# çenenin altında yalnız boyun (omuz/trapez köşeleri maskeyi disk gibi açıyordu)
		if d.length() > (0.2 if q.y > chin else 0.075):
			continue
		var k = Vector2i(int(floor((atan2(d.y, d.x) + PI) / TAU * FM_NA)) % FM_NA, int(floor(q.y / FM_DY)))
		_fmap[k] = maxf(_fmap.get(k, 0.0), d.length())
	if _sk_key != "":
		_fmap_cache[_sk_key] = _fmap


## Yüzey yarıçapı (komşu yön/yükseklik hücreleriyle yumuşatılmış en dış değer)
func face_r(a: float, y: float) -> float:
	_face_map()
	var fa = (wrapf(a, -PI, PI) + PI) / TAU * FM_NA - 0.5
	var fy = y / FM_DY - 0.5
	var a0 = int(floor(fa)); var y0 = int(floor(fy))
	var ta = fa - a0; var ty = fy - y0
	var acc = 0.0; var wsum = 0.0
	for da in [0, 1]:
		for dy in [0, 1]:
			var r = 0.0
			for ey in [-1, 0, 1]:
				for ea in [-1, 0, 1]:
					r = maxf(r, float(_fmap.get(Vector2i(posmod(a0 + da + ea, FM_NA), y0 + dy + ey), 0.0)))
			if r <= 0.0:
				continue
			var w = (ta if da == 1 else 1.0 - ta) * (ty if dy == 1 else 1.0 - ty)
			acc += r * w; wsum += w
	return acc / wsum if wsum > 0.0001 else maxf(skull_r.x, 0.07)


func face_pt(a: float, y: float, pad: float) -> Vector3:
	var r = face_r(a, y) + pad
	return Vector3(skull_c.x + cos(a) * r, y, skull_c.z + sin(a) * r)


## Yüzeye oturan kabuk parçası: a_c merkezli ±a_half yay, y0..y1 arası; tilt(a) -> y kayması, hole(a, y) -> true ise boş.
## İki yüzlü (iç yüz koyu); kenarlar hafif koyu. Dönüş: Head'e takılan mesh örneği.
func face_patch(cc: Color, a_c: float, a_half: float, y0: float, y1: float, pad: float, hole := Callable(), tilt := Callable(), na := 32, ny := 10, edge_dark := 0.12, two_side := true) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid = []
	for j in ny + 1:
		var row = []
		for k in na + 1:
			var a = a_c - a_half + 2.0 * a_half * k / na
			var y = lerpf(y0, y1, float(j) / ny) + (float(tilt.call(a)) if tilt.is_valid() else 0.0)
			row.append(face_pt(a, y, pad))
		grid.append(row)
	for j in ny:
		for k in na:
			var a = a_c - a_half + 2.0 * a_half * (k + 0.5) / na
			var y = lerpf(y0, y1, (j + 0.5) / ny)
			if hole.is_valid() and hole.call(a, y):
				continue
			var q = [grid[j][k], grid[j][k + 1], grid[j + 1][k + 1], grid[j + 1][k]]
			var edge = j == 0 or j == ny - 1 or (a_half < PI - 0.01 and (k == 0 or k == na - 1))
			var col = cc.darkened(edge_dark) if edge else cc
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(col); st.add_vertex(q[i])
			if two_side:
				for i in [0, 2, 1, 0, 3, 2]:
					var c0 = Vector3(skull_c.x, q[i].y, skull_c.z)
					st.set_color(cc.darkened(0.4)); st.add_vertex(c0 + (q[i] - c0) * 0.985)
	st.generate_normals()
	var mi = _mesh_on("Head", st.commit(), Transform3D.IDENTITY)
	mi.material_override = Props.toon()
	return mi


## Yüz yüzeyi üzerinde (a, y) yolu boyunca ince kabarık şerit (bıyık, sarmal oluk, boya çizgisi, kayış)
func face_line(cc: Color, path: Array, w: float, pad: float) -> void:
	if path.size() < 2:
		return
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in path.size() - 1:
		var p0: Vector2 = path[i]; var p1: Vector2 = path[i + 1]
		var c0 = face_pt(p0.x, p0.y, pad); var c1 = face_pt(p1.x, p1.y, pad)
		var nrm = (c0 - Vector3(skull_c.x, c0.y, skull_c.z)).normalized()
		var side = (c1 - c0).cross(nrm).normalized() * w * 0.5
		var q = [c0 - side, c1 - side, c1 + side, c0 + side]
		for k in [0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2]:
			st.set_color(cc); st.add_vertex(q[k])
	st.generate_normals()
	_mesh_on("Head", st.commit(), Transform3D.IDENTITY).material_override = Props.toon()


## Göz merkezi yönleri (a, y): sağ göz = karakterin sağı (-X)
func eye_a(right: bool) -> float:
	var ex = eye_center_model.x + 0.034 * (-1.0 if right else 1.0)
	var ez = face_r(PI * 0.5, eye_center_model.y)
	return atan2(ez, ex)


## Yüz eşyaları (yüz kabuğuna oturan yeni sürümler). true = işlendi (eski kurucular atlanır).
func face_item(fs: String, fg: Color) -> bool:
	if face_mi == null:
		return false
	var ey = eye_center_model.y
	var nose_y = ey - 0.032        # burun kemeri (maske üst kenarı)
	var chin = ey - 0.115
	var neck_y = _bp("Neck").y + 0.04   # boyun dibinde trapez başlıyor: alt kenar biraz yukarıda
	var F = PI * 0.5
	var dark = Color(0.08, 0.08, 0.1)
	var white = Color(0.94, 0.92, 0.86)
	match fs:
		"cloth":
			# bez maske (Kakashi tarzı): burun kemerinden boyna, başı tam saran sıkı kumaş; üst kenarda katlı bant
			face_patch(fg, F, PI, neck_y, nose_y, 0.008, Callable(), Callable(), 48, 14)
			face_patch(fg.darkened(0.12), F, PI, nose_y - 0.012, nose_y + 0.002, 0.008, Callable(), Callable(), 48, 2, 0.0)
		"pece":
			# çöl peçesi: burun ve ağzı örten ince kumaş, arkada bağlı; çenenin altından göğse sarkan bol uç (rüzgârda uçuşur)
			face_patch(fg, F, PI, chin - 0.012, nose_y, 0.006, Callable(), Callable(), 48, 10)
			face_patch(fg.darkened(0.1), F, PI, nose_y - 0.01, nose_y + 0.002, 0.009, Callable(), Callable(), 48, 2, 0.0)
			var cp = face_pt(F, chin - 0.008, 0.008)
			dangle_strip("Head", cp, Vector3(0, -1, 0.25), 0.16, 0.12, fg, 0.2, Vector3(1, 0, 0), 0.003)
			var bp = face_pt(-F, nose_y - 0.02, 0.012)
			for sx in [-1.0, 1.0]:
				dangle_strip("Head", bp + Vector3(0.008 * sx, 0, 0), Vector3(0.2 * sx, -1, -0.4), 0.14, 0.03, fg, 0.15, Vector3(1, 0, 0), 0.003)
		"bandaj_alt", "tam_bandaj":
			# sargılar: üst üste binen, hafif eğik bandaj turları (her tur ayrı şerit, kenarları koyu); tam sargıda göz yarıkları
			var full = fs == "tam_bandaj"
			var top = (ey + 0.075) if full else nose_y + 0.004
			var bc = white if fg.get_luminance() < 0.35 else fg
			var n = 8 if full else 5
			var ar = eye_a(true); var al = eye_a(false)
			var eyes = func(a: float, y: float) -> bool: return full and absf(y - ey) < 0.017 and (absf(wrapf(a - ar, -PI, PI)) < 0.2 or absf(wrapf(a - al, -PI, PI)) < 0.2)
			for k in n:
				var y1 = lerpf(top, neck_y, float(k) / n) + 0.004
				var y0 = lerpf(top, neck_y, float(k + 1) / n) - 0.004
				var sgn = 1.0 if k % 2 == 0 else -1.0
				var tl = func(a: float) -> float: return sgn * 0.006 * cos(a)
				face_patch(bc.darkened(0.03 * (k % 3)), F, PI, y0, y1, 0.005 + 0.0025 * (k % 2), eyes, tl, 48, 3, 0.15)
			# sargının altında kalan saç taşmasın
			hair_mask_slab(neck_y, top + 0.004, Vector2(skull_c.x, skull_c.z), face_r(0.0, ey) + 0.008, face_r(F, ey) + 0.008)
			var ep = face_pt(-F + 0.4, neck_y + 0.02, 0.012)
			dangle_strip("Head", ep, Vector3(0.1, -1, -0.3), 0.1, 0.022, bc, 0.15, Vector3(1, 0, 0), 0.003)
		"mempo", "demir_yarim_maske":
			# mempo: burnun altından çeneye lake yarım yüz zırhı, burun siperi, bıyık kabartması, ağız yarığı, boğaz koruması (3 kat)
			var steel = fs == "demir_yarim_maske"
			var mc = Color(0.62, 0.65, 0.7) if steel else fg
			face_patch(mc, F, 1.3, chin - 0.012, nose_y - 0.006, 0.012, Callable(), Callable(), 28, 9, 0.2)
			face_patch(mc.darkened(0.08), F, 0.16, nose_y - 0.014, nose_y + 0.012, 0.016, Callable(), Callable(), 6, 4, 0.2)   # burun siperi
			var my = ey - 0.075
			face_line(dark, [Vector2(F - 0.3, my), Vector2(F - 0.1, my + 0.003), Vector2(F + 0.1, my + 0.003), Vector2(F + 0.3, my)], 0.006, 0.0135)   # ağız yarığı
			if not steel:
				for sx in [-1.0, 1.0]:   # bıyık: ağzın üstünden yanlara kıvrılan kabartma
					face_line(Color(0.9, 0.88, 0.8), [Vector2(F + sx * 0.05, my + 0.014), Vector2(F + sx * 0.2, my + 0.01), Vector2(F + sx * 0.38, my - 0.006)], 0.006, 0.015)
				for k in 3:   # boğaz koruması: çenenin altından boyna inen katlar
					var yt = chin - 0.006 - k * 0.022
					face_patch(mc.darkened(0.1 + k * 0.06), F, 1.15 - k * 0.05, yt - 0.026, yt, 0.022 + k * 0.012, Callable(), Callable(), 22, 2, 0.25)
					face_line(Color(0.85, 0.45, 0.15), [Vector2(F - 1.05, yt - 0.024), Vector2(F, yt - 0.024), Vector2(F + 1.05, yt - 0.024)], 0.004, 0.024 + k * 0.012)
			else:
				for sx in [-1.0, 1.0]:
					for k in 3:   # perçinler
						face_line(Color(0.4, 0.4, 0.45), [Vector2(F + sx * 0.75, ey - 0.06 - k * 0.018), Vector2(F + sx * 0.78, ey - 0.06 - k * 0.018)], 0.008, 0.015)
			# arkaya giden bağ ipi
			face_patch(dark, F, PI, my - 0.004, my + 0.004, 0.007, func(a, _y): return absf(wrapf(a - F, -PI, PI)) < 1.3, Callable(), 40, 1, 0.0, false)
		"spiral_maske":
			# sarmal maske (ref: Tobi): yüzün tamamını örten turuncu düz maske, sağ gözde tek delik, delikten dışa açılan sarmal oluk
			var ar = eye_a(true)
			var ty = ey + 0.004
			var top = ey + 0.085
			var hole = func(a: float, y: float) -> bool: return pow(wrapf(a - ar, -PI, PI) * 0.09 / 0.016, 2.0) + pow((y - ty) / 0.016, 2.0) < 1.0
			var orange = Color(0.93, 0.5, 0.12)
			face_patch(orange, F, 1.0, chin + 0.012, top, 0.014, hole, Callable(), 40, 22, 0.1)
			var path = []
			for i in 120:
				var th = i * 0.16
				var r = 0.018 + th * 0.0055
				path.append(Vector2(ar + cos(th) * r / 0.09, ty + sin(th) * r))
			var clipped = []
			for pnt in path:
				if pnt.y > chin + 0.016 and pnt.y < top - 0.006 and absf(wrapf(pnt.x - F, -PI, PI)) < 0.94:
					clipped.append(pnt)
				elif clipped.size() > 1:
					face_line(orange.darkened(0.4), clipped, 0.004, 0.0155)
					clipped = []
			if clipped.size() > 1:
				face_line(orange.darkened(0.4), clipped, 0.004, 0.0155)
			# kenar ipi: maskeyi başa bağlar
			face_patch(dark, F, PI, ey + 0.02, ey + 0.028, 0.01, func(a, _y): return absf(wrapf(a - F, -PI, PI)) < 1.3, Callable(), 40, 1, 0.0, false)
		"gas", "gaz_maskesi":
			# gaz maskesi: burun-ağzı örten kauçuk yüz parçası, iki yanda aşağı-öne bakan filtre kutusu, ortada valf, başa kayış
			var rub = Color(0.2, 0.22, 0.2) if fs == "gas" else Color(0.25, 0.27, 0.3)
			face_patch(rub, F, 1.05, chin - 0.01, nose_y + 0.006, 0.016, Callable(), Callable(), 26, 9, 0.2)
			var mb = MB.new()
			var vp = face_pt(F, ey - 0.07, 0.03)
			mb.add("cyl", vp, Vector3(0.04, 0.03, 0.04), dark, Vector3(-75, 0, 0), 10)
			for sx in [-1.0, 1.0]:
				var a = F + sx * 0.62
				var cpn = face_pt(a, ey - 0.075, 0.035)
				var out = (cpn - Vector3(skull_c.x, cpn.y, skull_c.z)).normalized()
				mb.add_xf("cyl", Transform3D(Basis.looking_at(out + Vector3(0, -0.6, 0), Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(0.05, 0.05, 0.05)), cpn), Color(0.45, 0.47, 0.42), 12)
				mb.add_xf("cyl", Transform3D(Basis.looking_at(out + Vector3(0, -0.6, 0), Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(0.054, 0.01, 0.054)), cpn + (out + Vector3(0, -0.6, 0)).normalized() * 0.026), dark, 12)
			_mesh_on("Head", mb.build(Props.toon()), Transform3D.IDENTITY)
			face_patch(dark, F, PI, ey - 0.012, ey - 0.002, 0.01, func(a, _y): return absf(wrapf(a - F, -PI, PI)) < 1.0, Callable(), 40, 1, 0.0, false)
			if fs == "gaz_maskesi":   # yağmur tipi: göz camları da var
				for right in [true, false]:
					var ea = eye_a(right)
					face_patch(Color(0.55, 0.75, 0.7), ea, 0.3, ey - 0.02, ey + 0.022, 0.012, Callable(), Callable(), 8, 4, 0.5)
		"solunum_maskesi":
			# samuray solunum maskesi: ağız-burun üstünde çelik plaka, yatay nefes yarıkları, iki yandan enseye kıvrılan boğumlu hortum
			var stc = Color(0.32, 0.34, 0.38)
			face_patch(stc, F, 1.1, chin - 0.008, nose_y - 0.002, 0.014, Callable(), Callable(), 26, 9, 0.2)
			for k in 4:
				var yy = ey - 0.06 - k * 0.014
				face_line(dark, [Vector2(F - 0.35, yy), Vector2(F, yy), Vector2(F + 0.35, yy)], 0.004, 0.0155)
			for sx in [-1.0, 1.0]:
				var hp = []
				for i in 14:
					var t = float(i) / 13.0
					hp.append(Vector2(F + sx * (0.85 + t * 1.6), ey - 0.07 - t * 0.04))
				for i in 13:   # boğumlu hortum: kısa halka parçaları
					face_line(Color(0.22, 0.22, 0.25) if i % 2 == 0 else Color(0.4, 0.42, 0.46), [hp[i], hp[i + 1]], 0.018, 0.03)
		"goz_bandi":
			# göz bandı: sağ gözün üstünde yüze oturan siyah yama + yamadan şakağın üstünden enseye çapraz ince kayış
			var ar = eye_a(true)
			face_patch(fg if fg.get_luminance() < 0.3 else dark, ar, 0.27, ey - 0.024, ey + 0.026, 0.008, Callable(), Callable(), 10, 6, 0.25)
			var sp = []
			for i in 33:
				var t = float(i) / 32.0
				sp.append(Vector2(ar - t * TAU * 0.98, lerpf(ey + 0.022, ey + 0.05, sin(t * PI * 0.5)) - t * t * 0.02))
			face_line(dark, sp, 0.008, 0.016)
		"savas_boyasi":
			# savaş boyası: yanaklarda göz altından inen iki çizgi + alında çentik (yüz yüzeyine oturur, havada değil)
			var red = Color(0.78, 0.1, 0.1)
			for right in [true, false]:
				var ea = eye_a(right)
				var sx = 1.0 if right else -1.0   # dışa doğru (sağ göz büyük açı tarafında)
				for k in 2:
					var a0 = ea + sx * (0.02 + k * 0.1)
					face_line(red, [Vector2(a0, ey - 0.022), Vector2(a0 + sx * 0.06, ey - 0.06)], 0.007, 0.0012)
			face_line(red, [Vector2(F - 0.14, ey + 0.06), Vector2(F, ey + 0.045), Vector2(F + 0.14, ey + 0.06)], 0.006, 0.0012)
		_:
			return false
	return true


## Kafaya oturan kumaş başlık (bandana, haydut bezi, sarık, kapüşon tepesi...): alt kenar önde edge_y, arkada back_drop kadar
## enseye iner; yüzey her yönde gövde kafasının en az 1.2 cm dışında (kafa derisi içinden çıkmaz). Altındaki saç kesilir.
## puff: tepede kabarıklık, pad: halkadan dışarı pay. Dönüş: mesh örneği.
func head_cap(cc: Color, edge_y: float, back_drop: float, puff := 0.04, pad := 0.011, top_pad := 0.012, mask := true) -> MeshInstance3D:
	_band_ring_full()
	var rad: PackedFloat32Array = band_ring[1]
	var bins = rad.size()
	var cen = Vector3(skull_c.x, band_ring[0], skull_c.z)
	var top = skull_c.y + skull_r.y
	for q in _body_vs():
		if q.y > cen.y and absf(q.x) < 0.05:
			top = maxf(top, q.y)
	top += top_pad
	var r_at = func(ang: float) -> float: return rad[int(floor((wrapf(ang, -PI, PI) + PI) / TAU * bins)) % bins] + pad
	# gövde kafasının yön başına en dış noktası: 24 yön x 8 yükseklik
	var hmax = {}
	var neck_y = _bp("Neck").y + 0.05
	for q in _body_vs():
		if q.y < edge_y - back_drop - 0.03 or q.y < neck_y:
			continue
		var d = q - cen
		var hk = Vector2i(int(floor((atan2(d.z, d.x) + PI) / TAU * 24)) % 24, clampi(int(floor((atan2(d.y, Vector2(d.x, d.z).length()) + PI * 0.5) / PI * 8)), 0, 7))
		hmax[hk] = maxf(hmax.get(hk, 0.0), d.length())
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var na = 40
	var nr = 10
	var ring = []
	for j in nr + 1:
		var t = float(j) / nr
		var row = []
		for k in na + 1:
			var a = float(k) / na * TAU - PI
			var back = maxf(0.0, -sin(a))
			var y0 = edge_y - back * back_drop
			var r0 = r_at.call(a) - back * 0.012
			var e = t * PI * 0.5
			var r = r0 * cos(e) * (1.0 + puff * sin(e * 2.0))
			var y = y0 + (top - y0) * sin(e)
			var dv = Vector3(cos(a) * r, y - cen.y, sin(a) * r)
			var hk = Vector2i(int(floor((atan2(dv.z, dv.x) + PI) / TAU * 24)) % 24, clampi(int(floor((atan2(dv.y, Vector2(dv.x, dv.z).length()) + PI * 0.5) / PI * 8)), 0, 7))
			var need = float(hmax.get(hk, 0.0)) + 0.012
			if dv.length() < need:
				dv = dv.normalized() * need
			row.append(cen + dv)
		ring.append(row)
	for j in nr:
		for k in na:
			var q = [ring[j][k], ring[j][k + 1], ring[j + 1][k + 1], ring[j + 1][k]]
			var sh = 1.0 - 0.1 * float(j) / nr
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(cc * Color(sh, sh, sh))
				st.add_vertex(q[i])
	st.generate_normals()
	cap_grid = ring
	cap_cen = cen
	var mi = _mesh_on("Head", st.commit(), Transform3D.IDENTITY)
	mi.material_override = Props.toon()
	if mask:
		# başlığın altında kalan saç kesilir: önde alt kenar, arkada ense hizası düzlemi
		var fz = skull_c.z + r_at.call(PI * 0.5)
		var bz = skull_c.z - r_at.call(-PI * 0.5)
		var pf = Vector3(0, edge_y - 0.036, fz)
		var pb = Vector3(0, edge_y - back_drop + 0.01, bz)
		var v = pb - pf
		var nrm = Vector3(0, -v.z, v.y).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		hair_mask_plane(nrm, pf)
	return mi


## Ortak alın koruyucu kurucusu (kafa/boyun): cen merkezli rad[] halkası üstüne kumaş bant (içe kalın), önde kavisli plaka
## (pahlı kenar, perçinler, kazınmış arma), arkada düğüm + iki sarkan uç. tilt: önde aşağı eğim.
func _hitai(bone: String, cen: Vector3, rad: PackedFloat32Array, bc: Color, bh: float, ph: float, a_half: float, tilt_amt: float, tail_dir: Vector3, plate := true, tail_len := 0.15, tail_w := 0.03, rpad := 0.011, back_drop := 0.0, pb := Basis.IDENTITY) -> void:
	var bins = rad.size()
	var r_at = func(ang: float) -> float: return rad[int(floor((wrapf(ang, -PI, PI) + PI) / TAU * bins)) % bins]
	var tilt = func(ang: float) -> float: return -tilt_amt * maxf(0.0, sin(ang)) - back_drop * (1.0 - sin(ang)) * 0.5   # önde hafif aşağı (+Z = sin); back_drop: arkaya doğru iner (gerçek alın bandı)
	var p_of = func(ang: float, r: float, dy: float) -> Vector3: return cen + pb * Vector3(cos(ang) * r, dy + tilt.call(ang), sin(ang) * r)   # pb: eğik takılış (Kakashi/Zabuza/saç bandı/kol)
	# --- kumaş bant: kalınlıklı halka (dış yüz + üst/alt kenar), saçın üstünde
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = 48
	var cloth = bc
	for k in n:
		var a0 = float(k) / n * TAU - PI
		var a1 = float(k + 1) / n * TAU - PI
		var thin = not _anime_hair_vs.is_empty()   # anime saçı bandın altında kafaya bastırılır: bant ince kumaş (kullanıcı: kalın bant = "kap")
		var pad = 0.004 if thin else rpad
		var ro0 = r_at.call(a0) + pad; var ro1 = r_at.call(a1) + pad
		var depth = 0.004 if thin else 0.045   # eski saçlarda içe kalın: kesilen saçın yerinde boşluk görünmesin
		var ri0 = ro0 - depth; var ri1 = ro1 - depth
		var quads = [
			[p_of.call(a0, ro0, -bh * 0.5), p_of.call(a1, ro1, -bh * 0.5), p_of.call(a1, ro1, bh * 0.5), p_of.call(a0, ro0, bh * 0.5), cloth],
			[p_of.call(a0, ro0, bh * 0.5), p_of.call(a1, ro1, bh * 0.5), p_of.call(a1, ri1, bh * 0.5), p_of.call(a0, ri0, bh * 0.5), cloth.darkened(0.12)],
			[p_of.call(a0, ri0, -bh * 0.5), p_of.call(a1, ri1, -bh * 0.5), p_of.call(a1, ro1, -bh * 0.5), p_of.call(a0, ro0, -bh * 0.5), cloth.darkened(0.25)]]
		for q in quads:
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(q[4])
				st.add_vertex(q[i])
	st.generate_normals()
	var bmi = _mesh_on(bone, st.commit(), Transform3D.IDENTITY)
	bmi.material_override = Props.toon()
	var rv = MB.new()
	var front = PI * 0.5
	var plate_off = 0.0055 if not _anime_hair_vs.is_empty() else 0.013   # ince bantta plaka bandın yüzüne yapışık (kalın banttaki 1.3 cm havada kalıyordu)
	var rp = func(ang: float) -> float: return r_at.call(ang) + plate_off
	if plate:
		# --- metal plaka: alnın kavsini izleyen yay (önde ±0.5 rad), pahlı kenar
		var steel = Color(0.78, 0.8, 0.85)
		var ps = SurfaceTool.new()
		ps.begin(Mesh.PRIMITIVE_TRIANGLES)
		var m = 16
		for k in m:
			var a0 = front - a_half + 2.0 * a_half * float(k) / m
			var a1 = front - a_half + 2.0 * a_half * float(k + 1) / m
			var e0 = 1.0 if k == 0 else 0.0
			var e1 = 1.0 if k == m - 1 else 0.0
			# yüz: iç dikdörtgen (pah içi) + pah halkası (kenara doğru içe eğik)
			var t = 0.0045
			var bev = 0.004
			var rows = [[-ph * 0.5, 0.0], [-ph * 0.5 + bev, t], [ph * 0.5 - bev, t], [ph * 0.5, 0.0]]
			for r in 3:
				var y0 = rows[r][0]; var y1 = rows[r + 1][0]
				var d0 = rows[r][1]; var d1 = rows[r + 1][1]
				var col = steel if r == 1 else steel.darkened(0.18)
				var q = [p_of.call(a0, rp.call(a0) + d0, y0), p_of.call(a1, rp.call(a1) + d0, y0), p_of.call(a1, rp.call(a1) + d1, y1), p_of.call(a0, rp.call(a0) + d1, y1)]
				for i in [0, 1, 2, 0, 2, 3]:
					ps.set_color(col)
					ps.add_vertex(q[i])
			# uç kapakları
			for ec in [[e0, a0], [e1, a1]]:
				if ec[0] > 0.5:
					var aa: float = ec[1]
					var q2 = [p_of.call(aa, rp.call(aa), -ph * 0.5), p_of.call(aa, rp.call(aa) + t, -ph * 0.5 + bev), p_of.call(aa, rp.call(aa) + t, ph * 0.5 - bev), p_of.call(aa, rp.call(aa), ph * 0.5)]
					for i in [0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2]:
						ps.set_color(steel.darkened(0.25))
						ps.add_vertex(q2[i])
		ps.generate_normals()
		var pmi = _mesh_on(bone, ps.commit(), Transform3D.IDENTITY)
		pmi.material_override = Props.toon()
		# perçinler: dört köşe
		for sa in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var aa = front + sa * (a_half - 0.07)
				rv.add("sphere", p_of.call(aa, rp.call(aa) + 0.005, sy * (ph * 0.5 - 0.0075)), Vector3(0.006, 0.006, 0.006), steel.darkened(0.35), Vector3.ZERO, 6)
	# arkada düğüm: bandın üstünde iki küçük kumaş topak
	var back = -PI * 0.5
	var kp = p_of.call(back, r_at.call(back) + 0.014, 0.0)
	if tail_len > 0.0:
		rv.add("sphere", kp, Vector3(0.026, 0.024, 0.016), cloth.darkened(0.08), Vector3.ZERO, 7)
	_mesh_on(bone, rv.build(Props.toon()), Transform3D.IDENTITY)
	if plate and _band_kanji != "":   # Jiraiya: köy arması yerine 油
		var kl = Label3D.new()
		kl.text = _band_kanji
		kl.font = KageAttire._font()
		kl.font_size = 64
		kl.pixel_size = ph * 0.011
		kl.modulate = Color(0.12, 0.12, 0.14)
		kl.shaded = false
		kl.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		var kp0 = p_of.call(front, rp.call(front) + 0.0056, 0.0)
		var kdir = (pb * Vector3(0, 0, 1)).normalized()
		kl.transform = Transform3D(Basis.looking_at(-kdir, pb * Vector3.UP), kp0)
		_mesh_on(bone, ArrayMesh.new(), Transform3D.IDENTITY).add_child(kl)
	elif plate:
		# kazınmış arma: plakanın kavsine oturan dokulu şerit
		var ss = SurfaceTool.new()
		ss.begin(Mesh.PRIMITIVE_TRIANGLES)
		var sa_half = a_half * 0.62
		var sh = ph * 0.62
		for k in 10:
			var u0 = float(k) / 10.0; var u1 = float(k + 1) / 10.0
			var a0 = front + sa_half - 2.0 * sa_half * u0
			var a1 = front + sa_half - 2.0 * sa_half * u1
			var q = [[p_of.call(a0, rp.call(a0) + 0.0052, -sh * 0.5), Vector2(u0, 1)], [p_of.call(a1, rp.call(a1) + 0.0052, -sh * 0.5), Vector2(u1, 1)],
				[p_of.call(a1, rp.call(a1) + 0.0052, sh * 0.5), Vector2(u1, 0)], [p_of.call(a0, rp.call(a0) + 0.0052, sh * 0.5), Vector2(u0, 0)]]
			for i in [0, 1, 2, 0, 2, 3]:
				ss.set_uv(q[i][1])
				ss.add_vertex(q[i][0])
		ss.generate_normals()
		var smesh = ss.commit()
		var sm = StandardMaterial3D.new()
		sm.albedo_texture = symbol_texture(look["village"], look["band_style"] == "slashed")
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var smi = _mesh_on(bone, smesh, Transform3D.IDENTITY)
		smi.material_override = sm
	# iki kısa bağ ucu: düğümden enseye sarkar (ikincil hareket)
	for sx in ([-1.0, 1.0] if tail_len > 0.0 else []):
		dangle_strip(bone, kp + pb * Vector3(0.006 * sx, -0.004, -0.012), Vector3(tail_dir.x * sx, tail_dir.y, tail_dir.z), tail_len, tail_w, cloth, 0.16, pb * Vector3(1, 0, 0), 0.003)


## Kafanın arkası yüz mesh'inde yok: bant halkasına gövde mesh'inin (model uzayına çevrilmiş) kafa köşeleri de katılır
## (yoksa bant arkada kafanın içinde kalıyordu). skull_c/skull_r değişmez (saç tutamları onlara göre yerleşik).
var _ring_full := false
var _sk_key := ""
static var _ringfull_cache := {}   # yüz/cinsiyet/yaş -> tam bant halkası (gövde taraması her NPC'de tekrarlanmasın)
static var _top_cache := {}
static var _fmap_cache := {}
## Başın gerçek yüzeyini (kask kabuğuyla aynı ölçüm) saran bez şerit: y yüksekliğinde, h kalın, pad dışarı; tilt: yana eğim
func _skull_band(col: Color, y: float, h: float, pad: float, tilt := 0.0) -> MeshInstance3D:
	AnimeHair._c = skull_c; AnimeHair._r = skull_r; AnimeHair._grid = _head_radial(); AnimeHair._band_y = -INF
	var NA = 56
	var pts = []
	for k in NA + 1:
		var yw = float(k % NA) / NA * 360.0 - 180.0
		var yy = y + tilt * sin(deg_to_rad(yw))
		var rad = 0.08
		var pp = 0.0
		while pp < 150.0:
			var dd = AnimeHair._dir(yw, pp)
			var q = skull_c + dd * AnimeHair._real_r(dd)
			if q.y < yy:
				rad = Vector2(q.x - skull_c.x, q.z - skull_c.z).length()
				break
			pp += 2.0
		var dh = AnimeHair._dir(yw, 90.0)
		dh.y = 0.0
		dh = dh.normalized()
		pts.append([Vector3(skull_c.x, yy, skull_c.z) + dh * (rad + pad), dh])
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(col)
	for k in NA:
		var a0: Vector3 = pts[k][0]; var a1: Vector3 = pts[k + 1][0]
		var u = Vector3(0, h * 0.5, 0)
		var o = [a0 - u, a1 - u, a1 + u, a0 + u]
		for idx in [0, 2, 1, 0, 3, 2, 0, 1, 2, 0, 2, 3]:
			st.add_vertex(o[idx])
	st.generate_normals()
	var bm = st.commit()
	bm.surface_set_material(0, Props.toon())   # köşe rengi (varsayılan malzeme beyaz çiziyordu)
	return _mesh_on("Head", bm, Transform3D.IDENTITY)


## Alın bandı halkasının a açısındaki yarıçapı (a: PI*0.5 = ön, -PI*0.5 = arka; teuchi ile aynı dizinleme)
func _ring_r_at(a: float) -> float:
	_band_ring_full()
	if band_ring.is_empty():
		return 0.1
	var rr: PackedFloat32Array = band_ring[1]
	return float(rr[int(floor(wrapf(a + PI, 0.0, TAU) / TAU * rr.size())) % rr.size()])


func _band_ring_full() -> void:
	if _ring_full or band_ring.is_empty() or body_mesh == null or body_mesh.mesh == null:
		return
	_ring_full = true
	if _sk_key != "" and _ringfull_cache.has(_sk_key):
		band_ring = _ringfull_cache[_sk_key]
		return
	var by: float = band_ring[0]
	var rad: PackedFloat32Array = (band_ring[1] as PackedFloat32Array).duplicate()
	var bins = rad.size()
	for q in _body_vs():
		if absf(q.y - by) > 0.014 or q.y < _bp("Neck").y + 0.05:
			continue
		var d = Vector2(q.x - skull_c.x, q.z - skull_c.z)
		var k = int(floor((atan2(d.y, d.x) + PI) / TAU * bins)) % bins
		rad[k] = maxf(rad[k], d.length())
	band_ring = [by, rad]
	if _sk_key != "":
		_ringfull_cache[_sk_key] = band_ring


## ------------------------------------------------------------------ saç maskesi
## Başlıklar saçı bastırır: kayıtlı dilim/düzlem bölgesinde saç başlığın dışına taşmaz (shaders/hair_mask.gdshaderinc).
## Model uzayı (Y yukarı, +Z yüz). Dilim: y0..y1 arası, merkez (cx, cz) etrafında rx/rz elipsinin dışı kesilir.
var _hair_mats: Array = []   # [malzeme, mesh yerel -> model]
var _hm_slabs: Array = []    # [Vector4(y0, y1, rx, rz), Vector2(cx, cz)]
var _hm_planes: Array = []   # Vector4(n, d): dot(n, p) > d kesilir


func hair_mask_slab(y0: float, y1: float, c: Vector2, rx: float, rz: float) -> void:
	_hm_slabs.append([Vector4(y0, y1, rx, rz), c])


func hair_mask_plane(n: Vector3, through: Vector3) -> void:
	n = n.normalized()
	_hm_planes.append(Vector4(n.x, n.y, n.z, n.dot(through)))


## Başlık bandı için: kafa çevresi yarıçapları (band_ring) ölçüsünde elips, y'de h yüksekliğinde dilim
func hair_mask_band(y: float, h: float, pad := 0.004) -> void:
	_band_ring_full()
	var rx = maxf(skull_r.x, 0.06) + pad
	var rz = maxf(skull_r.z, 0.06) + pad
	if not band_ring.is_empty():
		var rad: PackedFloat32Array = band_ring[1]
		var bins = rad.size()
		# elips halkanın içinde kalsın (dışında kalırsa arada saç taşar): eksenlerdeki en küçük yarıçap
		var at = func(ang: float) -> float: return rad[int(floor((ang + PI) / TAU * bins)) % bins]
		rx = minf(at.call(0.0), at.call(PI - 0.001)) + pad
		# kafa ön-arka asimetrik (arka ~2x): elips merkezi kaydırılır
		var rf = at.call(PI * 0.5); var rb = at.call(-PI * 0.5)
		rz = (rf + rb) * 0.5 + pad
		hair_mask_slab(y - h * 0.5, y + h * 0.5, Vector2(skull_c.x, skull_c.z + (rf - rb) * 0.5), rx, rz)
		return
	hair_mask_slab(y - h * 0.5, y + h * 0.5, Vector2(skull_c.x, skull_c.z), rx, rz)


func _apply_hair_mask() -> void:
	if _hm_slabs.is_empty() and _hm_planes.is_empty():
		return
	for e in _hair_mats:
		var m: ShaderMaterial = e[0]
		m.set_shader_parameter("hm_on", true)
		m.set_shader_parameter("hm_xf", Projection(e[1] as Transform3D))
		for i in 2:
			if i < _hm_slabs.size():
				m.set_shader_parameter("hm_slab%d" % i, _hm_slabs[i][0])
				m.set_shader_parameter("hm_c%d" % i, _hm_slabs[i][1])
			if i < _hm_planes.size():
				m.set_shader_parameter("hm_plane%d" % i, _hm_planes[i])


## Hazır paketi (saç vb.) bir kemiğe takar
func add_dangle(bone: String, pack: Dictionary, mat: Material, model_xf: Transform3D, nm := "Dangle") -> Dangle:
	var d = Dangle.make(pack, mat)
	if d == null:
		return null
	d.mi.name = nm
	_attach(bone, model_xf).get_child(0).add_child(d)
	_dangles.append(d)
	return d


## Darbe/patlama: sarkan parçalar dünya yönünde savrulur
func dangle_kick(world_v: Vector3) -> void:
	for d in _dangles:
		if is_instance_valid(d):
			d.kick(world_v)


# ------------------------------------------------------------------ ikincil hareket sürücüsü
var _dangles: Array = []
var _dangle_acc := 0.0
var _dangle_fr := randi() % 6   # karakterler arasında yük dağılsın
var _dcol_bones := []   # [kemik, yarıçap, kemik uzayı ofseti]
const DANGLE_RANGE := 24.0


func _dangle_process(dt: float) -> void:
	if _dangles.is_empty() or skel == null:
		return
	var cam = get_viewport().get_camera_3d() if is_inside_tree() else null
	var d2 = cam.global_position.distance_squared_to(global_position) if cam != null else 0.0
	if d2 > DANGLE_RANGE * DANGLE_RANGE or not is_visible_in_tree():
		for d in _dangles:
			if is_instance_valid(d):
				d.reset()
		return
	# uzaktakiler seyrek güncellenir (birikmiş süreyle)
	_dangle_acc += dt
	_dangle_fr += 1
	var every = 1 if d2 < 16.0 else (2 if d2 < 100.0 else (3 if d2 < 324.0 else 4))   # 4 m içi her kare
	if _dangle_fr % every != 0:
		return
	dt = minf(_dangle_acc, 0.05)
	_dangle_acc = 0.0
	if _dcol_bones.is_empty():
		# gövde küreleri (model uzayı): kafa, boyun, omurga boyunca göğüs/sırt, kürek kemikleri, omuz, kol, kalça, kaba et, uyluk
		var hr = maxf(skull_r.x, skull_r.z)
		var defs = [["Head", hr * 0.95, skull_c], ["Neck", 0.06, null], ["Chest", 0.135, null], ["UpperChest", 0.13, null], ["Hips", 0.14, null]]
		var uc = skel.find_bone("UpperChest")
		if uc >= 0:
			for sx in [-1.0, 1.0]:
				defs.append(["UpperChest", 0.1, _grest(uc).origin + Vector3(0.085 * sx, 0.02, -0.035)])   # kürek kemiği
		var hb = skel.find_bone("Hips")
		for sd in ["Left", "Right"]:
			var sx = -1.0 if sd == "Left" else 1.0
			var ua = skel.find_bone(sd + "UpperArm")
			var la = skel.find_bone(sd + "LowerArm")
			if ua >= 0:
				defs.append([sd + "UpperArm", 0.07, null])
				if la >= 0:
					defs.append([sd + "UpperArm", 0.055, (_grest(ua).origin + _grest(la).origin) * 0.5])
					defs.append([sd + "LowerArm", 0.045, null])
			var ul = skel.find_bone(sd + "UpperLeg")
			var ll = skel.find_bone(sd + "LowerLeg")
			if ul >= 0:
				defs.append([sd + "UpperLeg", 0.09, _grest(ul).origin + Vector3(0, -0.04, -0.03)])   # kaba et
				if ll >= 0:
					defs.append([sd + "UpperLeg", 0.08, (_grest(ul).origin + _grest(ll).origin) * 0.5])
					defs.append([sd + "LowerLeg", 0.065, null])   # diz
					var ft = skel.find_bone(sd + "Foot")
					if ft >= 0:
						defs.append([sd + "LowerLeg", 0.055, (_grest(ll).origin + _grest(ft).origin) * 0.5])   # baldır
		for e in defs:
			var bi = skel.find_bone(e[0])
			if bi < 0:
				continue
			var g = _grest(bi)
			var at = g.origin if e[2] == null else (e[2] as Vector3)
			if e[2] == null and e[0] in ["Spine", "Chest", "UpperChest"]:
				at = g.origin + Vector3(0, 0.02, -0.015)
			_dcol_bones.append([bi, e[1], g.affine_inverse() * at, e[0] in ["Head", "Neck"]])   # kafa/boyun yumuşak: kafa derisine yatık saçı itmez
	var sxf = skel.global_transform
	var sc = sxf.basis.get_scale().x
	var cols = []
	for e in _dcol_bones:
		cols.append([sxf * (skel.get_bone_global_pose(e[0]) * (e[2] as Vector3)), float(e[1]) * sc, e[3]])
	var alive = []
	for d in _dangles:
		if is_instance_valid(d):
			d.step(dt, cols)
			alive.append(d)
	_dangles = alive


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
		var wear = String(look.get("band_wear", "alin")) if look.get("band_wear") != null else "alin"
		if wear == "sakura" and look.get("gender") == "m" and not look.get("own_hair", false):
			wear = "alin"   # NPC erkek: saç bandı (Sakura/Ino tarzı) kadınlarda
		if look["band_style"] == "neck":
			wear = "boyun"
		if wear != "alin" and not band_ring.is_empty():
			_band_wear(bc, wear)
		else:
			if band_ring.is_empty():
				band.add("cyl", Vector3.ZERO, Vector3(0.2, 0.034, 0.21), bc, Vector3.ZERO, 22)
				_mesh_on("Head", band.build(Props.toon()), Transform3D(Basis.IDENTITY, hc + Vector3(0, 0.025, 0)))
			else:
				_hitai_head(bc)
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
		# (Konoha: fermuar, cepler, yaka -> _vest_kit: yelek kabuğunun yüzeyinden derili 3B parçalar)
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
			0:   # Konoha: _vest_kit (yüzeye oturan derili cep/fermuar/yaka/omuzluk)
				pass

			1, 2, 3, 4, 12:   # Suna / Kiri / Kumo / Iwa / ANBU plaka: _vest_kit (yüzeye oturan derili parçalar)
				pass
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
	# bel çantası: kalça kemiğine yapışık katı kutu kumaşın/eteğin/paltonun içine giriyordu -> gövde kabuğunun arka yüzeyine
	# derili ince kapaklı çanta (kumaşla eğilir); beli/kalçayı örten giysi, etek ya da hakama varsa hiç takılmaz
	if not look.get("outer_style") in ["anbu_palto", "palto", "cuppe", "haori", "haori_uzun", "pelerin", "org_pelerin", "panco", "jinbaori", "mino", "yirtik", "kisa", "acik_ceket", "kiri_tunik", "bulut_etek", "kaya_gi", "suna_tunik", "sisme_yelek", "flamingo_elbise", "kapusonlu", "omuz_kazak", "uzun_ceket", "hirka", "onluk", "esofman_ceket", "kisa_haori", "kizil_palto", "hinata_ceket", "kirpik_kapusonlu", "yirtmacli_etek", "sargi_etek_uzun", "yilan_cubbe", "algi_ceket", "sargi_elbise", "onluk_elbise", "iki_ton_kimono", "turuncu_ceket", "kisa_bolero", "panel_etek", "uzun_panel_ust", "bel_ortusu", "kolsuz_palto", "kuyruklu_ceket", "kisa_kimono", "gunes_kimono", "genis_gomlek", "uzun_trench", "rikudo_cubbe", "yirtik_esofman", "kutlama_kimono", "kolsuz_kimono", "takim_yelek", "seytan_kapuson", "danzo_ortu", "delta_elbise", "kabarik_bluz", "kurbaga_kigurumi", "uzun_robe", "buyuk_kapusonlu", "kisa_kollu_kazak", "gelinlik", "sarma_mini", "inojin_ceket", "isshiki_palto", "itachi_tunik", "edo_cubbe", "kolsuz_trench", "jigen_cubbe", "sennin_yelek", "kaguya_kimono", "rokudaime_cubbe", "kawaki_palto", "kawaki_okul", "kawaki_ruro", "kukla_onluk", "kaguya_cubbe", "haku_yukata", "savas_cubbe", "mei_elbise", "hokage_haori", "bel_ceket", "cin_elbise", "sarada_elbise", "gezgin_palto", "yagura_ortu"] 			and int(look.get("skirt", 0)) == 0 and not look.get("hakama", false) and not look.get("pleat_skirt", false) and _sk_begin(_shell_cache.get(look["gender"])):
		var hy = _bp("Hips").y + 0.035
		var bc = Color(0.42, 0.33, 0.22)
		if _sk_plate(0.0, hy, 0.12, 0.075, 0.022, bc, 0.002, false):
			_sk_plate(0.0, hy + 0.028, 0.124, 0.024, 0.008, bc.darkened(0.18), 0.024, false)   # kapak
		_sk_end(_geo_for(look["gender"]))
	_thigh_holster()
	if look.get("leg_warmers") is Color:
		_leg_warmers(look["leg_warmers"])
	if look.get("neck_warmer") is Color:
		_neck_warmer(look["neck_warmer"])


# ------------------------------------------------------------------ silahlar: tutuş, kın, çekme/sokma
## Silah kını yeri: pouch = kunai çantası/kılıfı (görünmez), hip = sol kalçada kınlı kılıç (çapraz çekiş),
## back = sırtta çapraz (dev kılıçlar, sopalar), low_back = belin arkasında yatay, belt = yan kalçada asılı
const SHEATH_OF := {"blade": "pouch", "dual": "pouch", "claw": "pouch", "sickle": "belt", "sword": "hip", "heavy": "back", "staff": "back", "chain": "belt", "fan": "back"}
const SHEATH_ID := {"temari_ogi": "back", "mateki": "belt", "raijin": "belt", "tanto": "low_back", "ikiz_hancer": "low_back", "tonfa": "belt", "bashosen": "back", "yagura_sopa": "back", "kama": "back", "sai": "belt", "kiba": "back", "nodachi": "back", "kusanagi": "hip", "hiraishin_kunai": "belt", "kusarigama": "back", "fuma_shuriken": "back", "kyodai_shuriken": "back", "fuma_makimono": "back"}
## Kınlı kılıçlar: [kın başı z, kın ucu z, kalınlık, genişlik] (silah uzayında, kabza 0, namlu +Z)
const SAYA := {"katana": [0.075, 0.84, 0.042, 0.06], "wakizashi": [0.05, 0.6, 0.04, 0.055], "nodachi": [0.1, 1.38, 0.05, 0.11],
	"tanto": [0.06, 0.4, 0.045, 0.045], "chokuto": [0.13, 0.9, 0.05, 0.05]}
const SHEATH_DUR := 0.42
const KATANA_TIP_DOWN := -75.0
const BACK_TIP_UP := ["kama", "savas_cekici", "uc_tirpan", "mizrak", "kabutowari", "kusarigama"]

var weapons: Array = []     # [{id, side, kind, node, hand, sheath}]
var drawn := true           # silah elde mi (oyuncu: kınında başlar, saldırınca çekilir)
var _stowed := false        # mühür/jutsu sırasında eller boşalır, silah geçici olarak kına girer
var _sheath_t := -1.0
var _swapped := false
var rig: WeaponRig


const HAND_FRAME := ["tonfa", "pence", "chakra_bicak"]
const PAIR := ["tonfa", "pence", "senbon", "kiba"]   # çift el silahı: sağ elde takılıysa ve sol boşsa sol ele de aynısı (oyuncu ve NPC)


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
	var wr0 = look.get("weapon_r")   # silahsız karakterde null (başlangıçta kunai yok)
	if wr0 != null and String(wr0) in PAIR and (look.get("weapon_l") == null or String(look.get("weapon_l")) == ""):
		look["weapon_l"] = look["weapon_r"]
	for pair in [["weapon_r", "Right"], ["weapon_l", "Left"]]:
		var wid = look.get(pair[0])
		if wid == null or wid == "":
			continue
		var side: String = pair[1]
		var id = String(wid)
		if skel.find_bone(side + "Hand") < 0:
			continue
		var skin = String(look.get("weapon_skin_" + ("r" if side == "Right" else "l"), ""))   # kendi modeli olan özel silah (Hakkō Chakura Tō)
		var node: Node3D = null if skin != "" else SFProps.weapon_node(id)  # hayran modeli varsa (yoksa prosedürel)
		if node == null:
			var mi = MeshInstance3D.new()
			mi.mesh = weapon_mesh(skin if skin != "" else id)
			node = mi
		if id in HAND_FRAME and side == "Right":
			# tutuş çerçevesi sağ elde z etrafında 180° dönük: yönü ele göre olan silahlar (tonfa gövdesi dirseğe,
			# pençe el sırtına, kama bıçağı parmak eklemlerine) iki elde de aynı tarafa baksın
			var wrap = Node3D.new()
			wrap.add_child(node)
			# pençe: yalnız parmak yönü (x) ters çevrilir, el sırtı plakası (+y) sırtta kalır -> Y etrafında; diğerleri Z etrafında
			node.transform.basis = Basis(Vector3.UP, PI) if id == "pence" else Basis(Vector3.BACK, PI)
			node = wrap
		var hand: Node3D = _attach(side + "Hand", _grip_xf(side)).get_child(0)
		hand.add_child(node)
		if id == "hiraishin_kunai":
			node.scale = Vector3.ONE * 0.6   # gerçek kunai boyu (~40 cm)

		if id == "kusanagi":
			node.add_child(_kusa_ext())
		if id == "kama":
			for sx in [-1.0, 1.0]:   # halkaya bağlı kızıl kurdele (ikincil hareket)
				dangle_strip("", Vector3(0.0, 0.0, -0.36), Vector3(0.2 * sx, -0.4, -1.0), 0.4, 0.07, Color(0.7, 0.07, 0.12), 0.16, Vector3(0, 1, 0), 0.004, node)
		if id == "savas_cekici":
			# halkaya bağlı siyah kurdele: iki uç, rüzgârda/savuruşta dalgalanır (ikincil hareket)
			for sx in [-1.0, 1.0]:
				dangle_strip("", Vector3(0.0, 0.0, -0.2), Vector3(0.18 * sx, -0.3, -1.0), 0.34, 0.06, Color(0.08, 0.08, 0.1), 0.16, Vector3(0, 1, 0), 0.004, node)
		if id in KCHAIN and _kch.is_empty():
			_make_kchain(id)   # kusarigama: sap dibinden zincir + çan ağırlık; zincirli kunai: halkadan uzun zincir + ikinci kunai
		if SAYA.has(id):
			node.transform.basis = Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.RIGHT, deg_to_rad(KATANA_TIP_DOWN))
		if id == "raijin":
			node.add_child(_raijin_beam())
		if id == "ruzgar_bicak":
			node.add_child(_wind_ribbons())   # dönen rüzgar şeritleri (her kare döner, _wind_air)
		var kind = sheath_kind(id)
		weapons.append({"id": id, "side": side, "kind": kind, "node": node, "hand": hand, "sheath": _sheath_holder(kind, side, id, node)})
		if id in ["chakra_bicak", "sai"] and side == "Right" and skel.find_bone("LeftHand") >= 0:
			# Asuma'nın bıçaklı muştaları çift: sol ele de aynısı (sağ elde 180° çevrilmiş çerçeve, solda düz)
			var lm = MeshInstance3D.new()
			lm.mesh = weapon_mesh(id + "_sol")   # aynalı model (bıçak sol elde de serçe parmak ucundan)
			var lh: Node3D = _attach("LeftHand", _grip_xf("Left")).get_child(0)
			lh.add_child(lm)
			weapons.append({"id": id + "_sol", "side": "Left", "kind": "pouch", "node": lm, "hand": lh, "sheath": null})
		if id == "kabutowari" and side == "Right" and skel.find_bone("LeftHand") >= 0:
			# Kabutowari ikilisi: sol elde çekiç (kılıflıyken sol kalçada; balta sırtta), halkalar arası halat
			var hm = MeshInstance3D.new()
			hm.mesh = weapon_mesh("kabutowari_cekic")
			var lhand: Node3D = _attach("LeftHand", _grip_xf("Left")).get_child(0)
			lhand.add_child(hm)
			weapons.append({"id": "kabutowari_cekic", "side": "Left", "kind": "belt", "node": hm, "hand": lhand, "sheath": _sheath_holder("belt", "Left", "kabutowari_cekic", hm)})
			_make_rope()


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
				elif id == "savas_cekici":
					near_x = -0.035   # sap yarı kalınlığı: blok kafa (0.62 m) AABB'yi büyütüp sapı sırttan uzak tutuyordu
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
			xf = Transform3D(b, hp + Vector3(sx * 0.185, 0.05, 0.02))   # uyluğa yaslı (biraz dışarıda duruyordu)
		_:
			# belt: yan kalçada aşağı sarkar
			var hp = _grest(skel.find_bone("Hips")).origin
			var b = _frame(Vector3(sx * 0.12, -1.0, 0.18), Vector3(sx, 0, 0))
			xf = Transform3D(b, hp + Vector3(sx * 0.2, 0.1 - (0.12 if id == "raijin" else 0.0), 0.03))   # raijin kabzası kemerden aşağı sarkar
	if kind == "back" and id in ["fuma_shuriken", "kyodai_shuriken", "fuma_makimono"]:
		# yassı shurikenler sırta düz yaslanır (yassı yüz sırttan dışarı, kürek kemiklerinin arası); parşömen sırtta çapraz
		var ch2 = _grest(skel.find_bone("UpperChest")).origin
		var bz2 = _back_z(ch2.y - 0.06)
		var pad2 = 0.03 + (0.025 if look.get("vest") != null else 0.0) + (0.04 if look.get("outer_style") != null else 0.0)
		if id == "fuma_makimono":
			var bm = _frame(Vector3(-sx * 0.9, -0.45, 0.0), Vector3(0, 0, -1))
			xf = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)).rotated(Vector3.BACK, sx * 0.5), ch2 + Vector3(0, -0.1, minf(bz2, -0.08) - pad2 - 0.07))
		else:
			var big = id == "kyodai_shuriken"
			# model: yassı düzlem XY, kalınlık Z -> Z sırttan dışarı (-Z model), Y yukarı; kapalı Fūma sapı aşağıda
			var bb = Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))
			if not big:
				bb = bb.rotated(Vector3.BACK, PI + sx * 0.35)   # kapalı yelpaze: göbek halkası aşağıda, bıçaklar omuza doğru
			xf = Transform3D(bb, ch2 + Vector3(0, (0.0 if big else -0.08), minf(bz2, -0.08) - pad2 - (0.06 if big else 0.02)))
	var holder: Node3D = _attach("UpperChest" if kind == "back" else "Hips", xf).get_child(0)
	if kind == "back" and id in ["fuma_shuriken", "kyodai_shuriken", "fuma_makimono"]:
		_back_strap(sx)
	elif kind == "back" and id in ["bashosen", "samehada", "gunbai"]:
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
	if id == "kusanagi":
		# Kusanagi kını (ref kusanagi.png): ağız boyunca düz, süssüz simsiyah kın (iki ince oluk), sap dışarıda
		var km = MB.new()
		var kl = Color(0.08, 0.08, 0.1)
		km.add("box", Vector3(0, 0, 0.615), Vector3(0.03, 0.056, 0.95), kl)
		for sy in [-1.0, 1.0]:
			km.add("box", Vector3(0.0155, sy * 0.012, 0.615), Vector3(0.002, 0.004, 0.93), kl.lightened(0.12))
		var kmi = MeshInstance3D.new()
		kmi.mesh = km.build(Props.toon())
		holder.add_child(kmi)
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
	if id == "kusarigama" and kind == "belt":
		# kınlı hali (eski el orağı): zincir kalçada halka halka sarılı, orak sapı aşağı sarkar, ağırlık halkanın altında (sert zincir gövdeden fırlamasın)
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


## Tonfa: gövdesi ön kol boyunca dirseğe kilitlenir (WeaponRig.forearm_lock); elde dururken her karede uygulanır
const FOREARM_LOCK := {"tonfa": Vector3(-1, 0, 0)}   # mesh uzayında dirseğe giden gövde ekseni
func _register_forearm_lock() -> void:
	if rig == null:
		return
	rig.forearm_lock = {}
	for w in weapons:
		if not FOREARM_LOCK.has(w["id"]):
			continue
		var n: Node3D = w["node"]
		var holder: Node3D = w["hand"]
		var b: Basis = holder.transform.basis * n.transform.basis
		if not n is MeshInstance3D and n.get_child_count() > 0:
			b = b * (n.get_child(0) as Node3D).transform.basis   # sağ el çerçevesi (z etrafında 180°) sarmalayıcı
		rig.forearm_lock[w["side"]] = [b.orthonormalized(), FOREARM_LOCK[w["id"]]]


## Silahları duruma göre ele ya da kına yerleştir
func _place_weapons() -> void:
	_queue_shadow_trim()
	var in_hand = drawn and not _stowed
	if rig:
		rig.hold = {"Left": 0.0, "Right": 0.0}
	for w in weapons:
		var n: Node3D = w["node"]
		var tgt: Node3D = w["hand"] if (in_hand or w["sheath"] == null) else w["sheath"]
		if n.get_parent() != tgt:
			var sc = n.scale   # silahın kendi ölçeği (Hiraishin kunai 0.6) kına girip çıkarken korunur
			n.get_parent().remove_child(n)
			tgt.add_child(n)
			n.transform = Transform3D.IDENTITY
			n.scale = sc
		# kılıçlar elde: yassı yatmasın — kendi ekseninde 90° (ağız aşağı), uç biraz aşağı
		if SAYA.has(w["id"]):
			n.transform.basis = Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.RIGHT, deg_to_rad(KATANA_TIP_DOWN)) if n.get_parent() == w["hand"] else Basis.IDENTITY
		n.visible = in_hand or w["sheath"] != null
		if w["id"] == "fuma_shuriken" and n is MeshInstance3D:
			n.mesh = weapon_mesh("fuma_shuriken" if in_hand else "fuma_kapali")   # kında bıçaklar yelpaze gibi kapalı
		var beam = n.get_node_or_null("RaijinBeam")
		if beam:
			beam.visible = in_hand   # Raijin: ışın yalnız elde; belde yalnız kabza
		if w["id"] == "kusarigama" and w["sheath"] != null and w["kind"] == "belt":
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
	_update_rope()
	_update_kchain(dt)
	_wind_air(dt)
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


## Rüzgar bıçağı eldeyken: şeritler bıçak ekseninde döner, aralıklarla bıçağı saran ince rüzgar çizgileri uca doğru savrulur
var _wind_t := 0.0
func _wind_air(dt: float) -> void:
	for w in weapons:
		if w["id"] != "ruzgar_bicak":
			continue
		var n: Node3D = w["node"]
		if not is_instance_valid(n):
			return
		var rib = n.get_node_or_null("WindRibbons")
		if rib:
			rib.rotate_object_local(Vector3.BACK, dt * 7.0)
		if not (n.visible and n_in_hand(w) and n.is_visible_in_tree()):
			return
		_wind_t -= dt
		if _wind_t > 0.0:
			return
		_wind_t = 0.14
		# bıçağı saran sarmal hava çizgisi: o anki bıçak konumundan kökten uca, uçta açılıp kopar
		var xf = n.global_transform
		var ph = randf() * TAU
		var r0 = randf_range(0.07, 0.11)
		WindFX.streak(func(k: float) -> Vector3:
			var a = ph + k * TAU * 1.6
			var r = r0 * (1.0 - k * 0.6) + k * k * 0.25
			return xf * Vector3(cos(a) * r, sin(a) * r, lerpf(-0.05, 0.85, k)), randf_range(0.35, 0.5), 0.022, Color(0.85, 1.0, 0.93, 0.75), 0.0, 10)
		return


## Kabutowari halatı: balta ve çekiç sap halkaları arasında sarkan ip (yalnız ikisi de eldeyken görünür)
var _rope: Array = []
const ROPE_LEN := 1.7
const ROPE_SEG := 14


# ------------------------------------------------------------------ Kusarigama zinciri (Hanzō tipi, sickle.png)
## Sap dibinden sarkan fizikli zincir (verlet) + çan biçimli ağırlık. Kombo fırlatışları ucu tutturur: kchain_pin (ağırlık / uçan orak),
## kchain_start (başlangıç: varsayılan sap dibi; orak fırlatılınca el). Oyuncu ve düşman aynı (KeyedCombos).
const KCH_N := 16
const KCH_SEG := 0.048
var _kch: Array = []
var _kch_p := PackedVector3Array()
var _kch_o := PackedVector3Array()
var _kch_w: MeshInstance3D
var kchain_pin := Callable()
var kchain_start := Callable()
var kchain_hide_weight := false
var _kch_prev_a := Vector3.INF
var _kch_lh: Node3D   # sol el tutuşu: zincir sap dibinden sol ele gelir, kalanı sol elden sarkar
const KCH_HOLD := 6


## Fizikli zincirli silahlar: zincir başlangıcı (silah uzayı), halka boyu
const KCHAIN := {"kusarigama": [Vector3(0, 0, -0.39), 0.048], "zincirli_kunai": [Vector3(0, 0, -0.12), 0.1]}
var _kch_id := "kusarigama"


func _make_kchain(id := "kusarigama") -> void:
	_kch_id = id
	var mat = Props.toon_color(Color(0.12, 0.11, 0.15), 0.35)
	var tm = TorusMesh.new()
	tm.inner_radius = 0.012
	tm.outer_radius = 0.022
	tm.rings = 8
	tm.ring_segments = 4
	for k in KCH_N:
		var mi = MeshInstance3D.new()
		mi.mesh = tm
		mi.material_override = mat
		mi.top_level = true
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_kch.append(mi)
	_kch_w = MeshInstance3D.new()
	if id == "zincirli_kunai":
		# zincirin ucunda ikinci kunai: halkası zincire bağlı, ucu zincirden dışa bakar
		var km = MeshInstance3D.new()
		km.mesh = weapon_mesh("zk_ucu")
		km.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.105, 0))
		_kch_w.add_child(km)
	else:
		var b = MB.new()
		var dpur = Color(0.13, 0.11, 0.19)
		b.add("frustum", Vector3(0, -0.045, 0), Vector3(0.1, 0.085, 0.1), dpur, Vector3(0, 45, 0), 4)   # çan: aşağı genişleyen dört yüzlü
		b.add("box", Vector3(0, 0.0, 0), Vector3(0.04, 0.016, 0.04), dpur.lightened(0.1))
		b.add("torus", Vector3(0, 0.018, 0), Vector3(0.022, 0.022, 0.022), dpur, Vector3(90, 0, 0), 8)
		_kch_w.mesh = b.build(Props.toon())
	_kch_w.top_level = true
	add_child(_kch_w)
	if skel != null and skel.find_bone("LeftHand") >= 0:
		_kch_lh = _attach("LeftHand", _grip_xf("Left")).get_child(0)


## Ağırlığın (zincir ucunun) anlık dünya konumu
func kchain_tip() -> Vector3:
	if _kch_p.size() == KCH_N + 1:
		return _kch_p[KCH_N]
	return global_position + Vector3.UP


func _update_kchain(dt: float) -> void:
	if _kch.is_empty():
		return
	var w: Dictionary = {}
	for x in weapons:
		if x["id"] == _kch_id:
			w = x
	var n: Node3D = w.get("node") if not w.is_empty() else null
	var on = n != null and is_instance_valid(n) and is_visible_in_tree() and (n.visible or kchain_start.is_valid())
	for mi in _kch:
		mi.visible = on
	_kch_w.visible = on and not kchain_hide_weight
	if not on:
		return
	var a: Vector3 = kchain_start.call() if kchain_start.is_valid() else n.to_global(KCHAIN.get(_kch_id, KCHAIN["kusarigama"])[0])
	var KSEG: float = KCHAIN.get(_kch_id, KCHAIN["kusarigama"])[1]
	var pinned = kchain_pin.is_valid()
	var pin: Vector3 = kchain_pin.call() if pinned else Vector3.ZERO
	if _kch_p.size() != KCH_N + 1 or (_kch_p[1].distance_to(a) > 3.0 and not pinned):
		_kch_p.resize(KCH_N + 1)
		_kch_o.resize(KCH_N + 1)
		for k in KCH_N + 1:
			_kch_p[k] = a + Vector3.DOWN * KSEG * k
			_kch_o[k] = _kch_p[k]
	var seg = KSEG
	if pinned:
		seg = maxf(KSEG, a.distance_to(pin) / KCH_N * 1.03)
	# sol el zinciri tutar (elde, fırlatma yokken): sap dibi -> sol el gevşek, sol elden ağırlığa sarkar
	var hold = not pinned and not kchain_start.is_valid() and _kch_lh != null and is_instance_valid(_kch_lh) and n_in_hand(w)
	var lh: Vector3 = _kch_lh.global_position if hold else Vector3.ZERO
	var segh = maxf(KSEG, a.distance_to(lh) / KCH_HOLD * 1.08) if hold else seg
	var fixed := {0: a}
	if hold:
		fixed[KCH_HOLD] = lh
	if pinned:
		fixed[KCH_N] = pin
	# kında (sırtta): zincir sapa iki yerden bağlı, ağırlık sapın üst ucunda -> kısa iki sarkık halka; savrulup uzamaz
	var stow = _kch_id == "kusarigama" and not pinned and not kchain_start.is_valid() and not n_in_hand(w)
	if stow:
		fixed[KCH_N / 2] = n.to_global(Vector3(0.035, 0, -0.12))
		fixed[KCH_N] = n.to_global(Vector3(0.0, 0, 0.14))
	# kök hareketi tüm zincire taşınır (hızlı koşu/dönüşte zincir geride kalıp uzamasın), ivme payı kalır
	var da = a - _kch_prev_a if _kch_prev_a != Vector3.INF else Vector3.ZERO
	_kch_prev_a = a
	if da.length() < 3.0 and not pinned and not kchain_start.is_valid():
		var fk = 1.0 if stow else 0.75
		for k in range(1, KCH_N + 1):
			_kch_p[k] += da * fk
			_kch_o[k] += da * fk
	var h = clampf(dt, 0.001, 0.033)
	var floor_y = global_position.y + 0.03
	for k in range(1, KCH_N + 1):
		var p = _kch_p[k]
		var v = (p - _kch_o[k]) * (0.82 if stow else 0.97)
		_kch_o[k] = p
		p += v + Vector3.DOWN * 9.8 * h * h
		if p.y < floor_y:
			p.y = floor_y
		_kch_p[k] = p
	for it in (12 if stow else 8):
		for fk in fixed:
			_kch_p[fk] = fixed[fk]
		for k in KCH_N:
			var d = _kch_p[k + 1] - _kch_p[k]
			var L = d.length()
			if L < 0.0001:
				continue
			var diff = (L - (segh if hold and k < KCH_HOLD else seg)) / L
			var f0 = fixed.has(k)
			var f1 = fixed.has(k + 1)
			if f0 and f1:
				continue
			elif f0:
				_kch_p[k + 1] -= d * diff
			elif f1:
				_kch_p[k] += d * diff
			else:
				_kch_p[k] += d * diff * 0.5
				_kch_p[k + 1] -= d * diff * 0.5
	for fk in fixed:
		_kch_p[fk] = fixed[fk]
	for k in KCH_N:
		var p0: Vector3 = _kch_p[k]
		var p1: Vector3 = _kch_p[k + 1]
		var dv = p1 - p0
		var L = dv.length()
		if L < 0.0001:
			continue
		var dir = dv / L
		var e1 = dir.cross(Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT).normalized()
		var e2 = dir.cross(e1)
		if k % 2 == 1:
			var tmp = e1
			e1 = e2
			e2 = tmp
		var sl = L * 1.4 / 0.044   # halka boyu: segmentten biraz uzun (iç içe geçsin)
		_kch[k].global_transform = Transform3D(Basis(dir * sl, e1, e2 * 0.9), (p0 + p1) * 0.5)
	var up = (_kch_p[KCH_N - 1] - _kch_p[KCH_N]).normalized()
	var ex = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	_kch_w.global_transform = Transform3D(Basis(ex, up, ex.cross(up)), _kch_p[KCH_N] - up * 0.02)


func _make_rope() -> void:
	var mat = Props.toon_color(Color(0.5, 0.44, 0.38), 0.2)
	var cm = CylinderMesh.new()
	cm.top_radius = 0.012
	cm.bottom_radius = 0.012
	cm.height = 1.0
	cm.radial_segments = 6
	for k in ROPE_SEG:
		var mi = MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = mat
		mi.top_level = true
		add_child(mi)
		_rope.append(mi)


func _update_rope() -> void:
	if _rope.is_empty():
		return
	var ax: Dictionary = {}
	var hm: Dictionary = {}
	for w in weapons:
		if w["id"] == "kabutowari":
			ax = w
		elif w["id"] == "kabutowari_cekic":
			hm = w
	var on = not ax.is_empty() and not hm.is_empty() and n_in_hand(ax) and n_in_hand(hm) and (ax["node"] as Node3D).visible
	for mi in _rope:
		mi.visible = on
	if not on:
		return
	var a: Vector3 = (ax["node"] as Node3D).to_global(Vector3(0, 0, -0.2))
	var b: Vector3 = (hm["node"] as Node3D).to_global(Vector3(0, 0, -0.2))
	var d = a.distance_to(b)
	var sag = 0.5 * sqrt(maxf(0.0, ROPE_LEN * ROPE_LEN - d * d))   # gevşek ip aşağı sarkar
	var pts = []
	for k in ROPE_SEG + 1:
		var t = float(k) / ROPE_SEG
		pts.append(a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t))
	for k in ROPE_SEG:
		var p0: Vector3 = pts[k]
		var p1: Vector3 = pts[k + 1]
		var dv = p1 - p0
		var L = dv.length()
		if L < 0.0001:
			continue
		var y = dv / L
		var x = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		_rope[k].global_transform = Transform3D(Basis(x, y * L, x.cross(y)), (p0 + p1) * 0.5)   # yalnız kendi ekseninde uzar


## Kusanagi no Tsurugi (orochikusanagi.png): siyah topuz, beyaz sargılı sap (siyah bantlar), siyah boğaz; muhafız iki yana açılıp
## aşağı (ağız yönüne) kıvrılan pullu yılan gövdeleri, ortada mavi taş; düz, iki ağızlı, uca incelen çelik ağız (orta sırt).
## Kabza 0, ağız +Z, yassı yüz X.
static func _kusanagi(b: MB) -> void:
	# ref kusanagi.png: muhafızsız düz kılıç — uzun siyah sap (hafif oval), sapın ağza girdiği yerde ince metal boğaz + küçük pim,
	# ince uzun düz ağız (beyaz-gümüş, tek ağızlı, sırtta koyu çizgi), ucu eğik kesik (kiriha). Tutuş z=0, uç +Z ~1.08.
	var blk = Color(0.1, 0.1, 0.12)
	var steel = Color(0.88, 0.89, 0.9)
	var metal = Color(0.62, 0.63, 0.66)
	b.add("cyl", Vector3(0, 0, -0.04), Vector3(0.044, 0.32, 0.05), blk, Vector3(90, 0, 0), 12)          # uzun siyah sap
	b.add("cyl", Vector3(0, 0, -0.2), Vector3(0.046, 0.012, 0.052), blk.lightened(0.08), Vector3(90, 0, 0), 12)   # sap ucu
	b.add("cyl", Vector3(0, 0, 0.13), Vector3(0.036, 0.03, 0.04), metal, Vector3(90, 0, 0), 10)        # boğaz
	b.add("cyl", Vector3(0.019, 0, 0.13), Vector3(0.008, 0.004, 0.008), blk, Vector3(0, 0, 90), 6)     # pim
	# ağız: düz, sırt (+Y) kalın, keskin kenar (-Y) ince; uç eğik (keskin kenar uzun, sırt kısa)
	var bl = PackedVector2Array([Vector2(-0.016, 0.145), Vector2(0.017, 0.145), Vector2(0.017, 1.0), Vector2(-0.016, 1.08)])
	b.add_slab(bl, 0.01, steel, Transform3D.IDENTITY, func(q: Vector2) -> float: return 0.003 if q.x < -0.01 else 0.01, steel.darkened(0.15))
	b.add("box", Vector3(0, 0.012, 0.57), Vector3(0.011, 0.003, 0.84), steel.darkened(0.35))           # sırt çizgisi


## Kusanagi Chōtō: ağzın ucundan ileri uzayan ince çelik (boyu 1 m, ölçek.z ile uzar); varsayılan gizli
static func _kusa_ext() -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = "KusaExt"
	var b = MB.new()
	b.add_slab(PackedVector2Array([Vector2(-0.016, 0.0), Vector2(0.017, 0.0), Vector2(0.017, 0.92), Vector2(-0.016, 1.0)]), 0.01, Color(0.88, 0.89, 0.9))
	mi.mesh = b.build(Props.toon())
	mi.position = Vector3(0, 0, 1.0)
	mi.scale = Vector3(1, 1, 0.01)
	mi.visible = false
	return mi


## Hōmatsu Kiseru (utakatababa.png, Utakata'nın kabarcık borusu): bej bambu boru, aralıklı halka boğumlar; tutuş (z 0) ağızlığa
## yakın; arkada (−Z) dar ağızlık kupası (üflenen uç), önde (+Z) açılan çan (kabarcıklar buradan); ortada kırmızı ip püskül, iki
## beyaz boncuk. Toplam ~0.9 m.
static func _kiseru(b: MB) -> void:
	var tan = Color(0.82, 0.72, 0.5)
	var tan_d = tan.darkened(0.18)
	var red = Color(0.72, 0.25, 0.15)
	b.add("cyl", Vector3(0, 0, 0.24), Vector3(0.042, 0.74, 0.042), tan, Vector3(90, 0, 0), 12)          # boru z -0.13..0.61
	for z in [-0.08, 0.05, 0.2, 0.26, 0.42, 0.52]:
		b.add("cyl", Vector3(0, 0, z), Vector3(0.052, 0.02, 0.052), tan_d, Vector3(90, 0, 0), 12)    # boğumlar
	# ağızlık (dar uç, üflenen): küçük kupa
	b.add("cyl", Vector3(0, 0, -0.15), Vector3(0.04, 0.04, 0.04), tan, Vector3(90, 0, 0), 12)
	b.add_xf("cone", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90)) * Basis.from_scale(Vector3(0.07, 0.05, 0.07)), Vector3(0, 0, -0.19)), tan_d, 14)
	b.add("cyl", Vector3(0, 0, -0.205), Vector3(0.066, 0.012, 0.066), tan, Vector3(90, 0, 0), 14)
	# çan (kabarcık ucu): genişleyen koni, içi koyu
	b.add("cyl", Vector3(0, 0, 0.6), Vector3(0.05, 0.03, 0.05), tan_d, Vector3(90, 0, 0), 12)
	b.add_xf("cone", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90)) * Basis.from_scale(Vector3(0.17, 0.11, 0.17)), Vector3(0, 0, 0.665)), tan, 18)
	b.add("cyl", Vector3(0, 0, 0.712), Vector3(0.16, 0.012, 0.16), Color(0.35, 0.18, 0.12), Vector3(90, 0, 0), 18)   # çan içi (koyu)
	b.add("torus", Vector3(0, 0, 0.716), Vector3(0.17, 0.17, 0.17), tan_d, Vector3(90, 0, 0), 18)
	# kırmızı ip + püskül (ortada bağlı, aşağı sarkar) + iki beyaz boncuk
	b.add("cyl", Vector3(0, 0, 0.235), Vector3(0.042, 0.03, 0.042), red, Vector3(90, 0, 0), 12)
	b.add("box", Vector3(0, -0.11, 0.25), Vector3(0.012, 0.2, 0.012), red, Vector3(-10, 0, 0))
	b.add("box", Vector3(0, -0.13, 0.232), Vector3(0.01, 0.19, 0.01), red.darkened(0.15), Vector3(8, 0, 0))
	for k in 2:
		b.add("sphere", Vector3(0, -0.12 - k * 0.05, 0.245), Vector3(0.024, 0.024, 0.024), Color(0.95, 0.95, 0.92), Vector3.ZERO, 8)
	b.add("cone", Vector3(0, -0.24, 0.25), Vector3(0.022, 0.06, 0.022), red, Vector3(180, 0, 0), 6)


## Hiraishin Kunai (raijinbaba.png, Minato): siyah halka topuz, kanjili bej sargılı sap, siyah boğaz; üç dişli ağız —
## ortada uzun sivri diş, iki yanda dışa açılıp ileri kıvrılan hilal dişler; koyu çelik gövde, açık renk keskin iç kenarlar.
## Kabza 0, ağız +Z, dişler y-z düzleminde (yassı yüz X).
static func _hiraishin_kunai(b: MB) -> void:
	var blk = Color(0.1, 0.1, 0.11)
	var tan = Color(0.84, 0.68, 0.46)
	var steel = Color(0.2, 0.2, 0.23)
	var edge = Color(0.82, 0.84, 0.88)
	b.add("torus", Vector3(0, 0, -0.16), Vector3(0.088, 0.088, 0.088), blk, Vector3(0, 0, 90), 16)      # halka (küçültüldü) (y-z düzleminde)
	b.add("cyl", Vector3(0, 0, -0.11), Vector3(0.026, 0.03, 0.026), blk, Vector3(90, 0, 0), 10)    # halka boynu
	b.add("cyl", Vector3(0, 0, 0.0), Vector3(0.044, 0.2, 0.044), tan, Vector3(90, 0, 0), 10)       # sargılı sap
	for k in 4:   # kanji fırça izleri (sapın üstünde siyah)
		b.add("box", Vector3(0.0, 0.022, -0.06 + k * 0.04), Vector3(0.018, 0.004, 0.02), blk, Vector3(0, 0, 0))
		b.add("box", Vector3(0.0, -0.022, -0.05 + k * 0.04), Vector3(0.014, 0.004, 0.016), blk)
	for z in [-0.1, 0.1]:
		b.add("cyl", Vector3(0, 0, z), Vector3(0.048, 0.012, 0.048), blk, Vector3(90, 0, 0), 10)
	b.add("cyl", Vector3(0, 0, 0.12), Vector3(0.03, 0.03, 0.03), blk, Vector3(90, 0, 0), 10)        # boğaz
	# orta diş (y, z profil), kalınlık x
	var mid = PackedVector2Array([Vector2(-0.026, 0.125), Vector2(0.026, 0.125), Vector2(0.03, 0.17), Vector2(0.014, 0.33), Vector2(0.0, 0.48),
		Vector2(-0.014, 0.33), Vector2(-0.03, 0.17)])
	b.add_slab(mid, 0.012, steel, Transform3D.IDENTITY, func(q: Vector2) -> float: return 0.004 if absf(q.x) > 0.018 or q.y > 0.4 else 0.014, steel.lightened(0.2))
	# yan hilal dişler: boğazdan dışa açılır, ileri kıvrılarak sivrilir
	for sy in [-1.0, 1.0]:
		var o = [[0.02, 0.125], [0.07, 0.125], [0.125, 0.14], [0.165, 0.175], [0.18, 0.22], [0.172, 0.27], [0.15, 0.32],   # dış kenar (geniş hilal)
			[0.142, 0.268], [0.13, 0.225], [0.1, 0.19], [0.06, 0.172], [0.028, 0.168]]                         # iç (keskin) kenar
		var pts = PackedVector2Array()
		for q in o:   # yan dişler küçültüldü (eni 0.62x, boyu 0.7x)
			pts.append(Vector2(q[0] * 0.62 * sy, 0.125 + (q[1] - 0.125) * 0.7))
		b.add_slab(pts, 0.01, steel, Transform3D.IDENTITY, Callable(), steel.lightened(0.2))
		var ie = PackedVector2Array()   # iç keskin kenar açık şerit
		for q in [[0.15, 0.32], [0.142, 0.268], [0.13, 0.225], [0.1, 0.19], [0.06, 0.172], [0.03, 0.168], [0.034, 0.158], [0.066, 0.162], [0.108, 0.18], [0.142, 0.218], [0.155, 0.268]]:
			ie.append(Vector2(q[0] * 0.62 * sy, 0.125 + (q[1] - 0.125) * 0.7))
		b.add_slab(ie, 0.012, edge)


## Sai (sai.png): siyah sap + altın spiral kordon, metal topuz; korumadan iki yana çıkıp ileri kıvrılan yan dişler (yoku),
## uçları hafif dışa kalkık; uzun sekizgen krom ana kol (monouchi), küt uç. Kabza 0, ana kol +Z, yan dişler ±Y düzleminde.
static func _sai(b: MB) -> void:
	var chrome = Color(0.7, 0.72, 0.77)
	var chrome_d = Color(0.5, 0.52, 0.57)
	var blk = Color(0.08, 0.08, 0.09)
	var gold = Color(0.85, 0.68, 0.25)
	# sap + altın kordon
	b.add("cyl", Vector3(0, 0, -0.005), Vector3(0.036, 0.14, 0.036), blk, Vector3(90, 0, 0), 10)
	for k in 7:
		b.add("cyl", Vector3(0, 0, -0.065 + k * 0.019), Vector3(0.039, 0.004, 0.039), gold, Vector3(90 + 22, 0, 0), 10)
	# topuz: metal kapak, uçta yassı genişleyen
	b.add("cyl", Vector3(0, 0, -0.082), Vector3(0.04, 0.02, 0.04), chrome_d, Vector3(90, 0, 0), 10)
	b.add("cyl", Vector3(0, 0, -0.097), Vector3(0.05, 0.014, 0.034), chrome, Vector3(90, 0, 0), 10)
	# koruma göbeği
	b.add("sphere", Vector3(0, 0, 0.078), Vector3(0.042, 0.05, 0.05), chrome, Vector3.ZERO, 10)
	# ana kol: sekizgen, uca hafif incelen, küt sivri uç
	b.add("cyl", Vector3(0, 0, 0.32), Vector3(0.018, 0.48, 0.018), chrome, Vector3(90, 0, 0), 8)
	b.add("cone", Vector3(0, 0, 0.575), Vector3(0.018, 0.03, 0.018), chrome, Vector3(90, 0, 0), 8)
	# yan dişler: göbekten yana (±y) çıkıp kıvrılarak ileri (+z), uçta dışa kalkık
	var seg = func(a: Vector3, e: Vector3, r: float):
		var d = e - a
		var L = d.length()
		if L < 0.0001:
			return
		b.add_xf("cyl", Transform3D(Basis(Quaternion(Vector3.UP, d / L)) * Basis.from_scale(Vector3(r, L, r)), (a + e) * 0.5), chrome, 8)
		b.add("sphere", e, Vector3(r, r, r), chrome, Vector3.ZERO, 6)
	for sy in [-1.0, 1.0]:
		var pts = [Vector3(0, 0, 0.075), Vector3(0, sy * 0.035, 0.07), Vector3(0, sy * 0.065, 0.075), Vector3(0, sy * 0.078, 0.1),
			Vector3(0, sy * 0.078, 0.15), Vector3(0, sy * 0.082, 0.18), Vector3(0, sy * 0.095, 0.2)]
		for k in pts.size() - 1:
			seg.call(pts[k], pts[k + 1], 0.012 if k < 4 else 0.009)


## Asuma'nın bıçaklı muştası (knucles.png): parmak deliklerinden geçirilen yassı plaka (4 delik), üst kenarı basamaklı vuruş
## yüzü, serçe parmak ucundan kıvrılarak inen uzun hilal bıçak; koyu lacivert çelik, açık renk keskin kenar.
## Tutuş çerçevesi (HAND_FRAME): +x parmak yönü (eklemlerden ileri), +y el sırtı, z yumruk boyunca (parmak dizisi).
## Plaka (y, z) düzleminde, kalınlık x: delikler parmakların etrafında, bıçak yumruğun altından (avuç tarafı, -y) iner.
static func _trench_knife(b: MB, mirror: bool) -> void:
	var wind = false
	var mz = 1.0   # (sol elde z aynalamak bıçağı yukarı çeviriyordu; iki elin çerçevesi yalnız y ekseninde ters)
	var col = Color(0.27, 0.31, 0.5) if not wind else Color(0.3, 0.45, 0.55)
	var edge = Color(0.86, 0.88, 0.92)
	# asumababa.png: plaka yumruğun ön yüzünde, kol ile parmak dizisinin düzleminde (x, z); parmaklar delikleri avuç yönünde (-y) geçer,
	# basamaklı vuruş kenarı ileri (+x), bıçak serçe parmak ucundan (-z) yumruğun altına iner. Profil (u, v) -> (x = u, z = v), kalınlık y
	var xf = Transform3D(Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)), Vector3(0.0, 0.015 if mirror else -0.015, 0.0))   # sol elde çerçevenin y ekseni ters: plaka yine parmakların içinde
	var V = func(arr: Array) -> PackedVector2Array:
		var o = PackedVector2Array()
		for q in arr:
			o.append(Vector2(q[0], q[1] * mz))
		return o
	# parmak çubuğu: her biri TEK delikli dört dilim (çok delikli çokgen üçgenlenemiyordu)
	var cuts = [-0.066, -0.0265, 0.0005, 0.0275, 0.072]
	var holes = [-0.046, -0.013, 0.014, 0.046]
	for k in 4:
		var za = float(cuts[k]); var zb = float(cuts[k + 1])
		var sl = V.call([[-0.028, za], [0.036, za], [0.036, zb], [-0.028, zb]])
		b.add_slab(MB.hole(sl, Vector2(0.004, float(holes[k]) * mz), 0.0115, 10), 0.012, col, xf, Callable(), col.lightened(0.25))
	# basamaklı üst kenar (vuruş yüzü) çıkıntıları + işaret parmağı ucundaki sivri burun
	for bz in [[-0.052, -0.03], [0.012, 0.04]]:
		b.add_slab(V.call([[0.036, bz[0]], [0.047, bz[0] + 0.006], [0.047, bz[1] - 0.006], [0.036, bz[1]]]), 0.012, col, xf, Callable(), col.lightened(0.25))
	b.add_slab(V.call([[-0.028, 0.072], [0.036, 0.072], [0.004, 0.09]]), 0.012, col, xf, Callable(), col.lightened(0.25))
	# hilal bıçak: serçe parmak ucundan avuç tarafına (-y) kıvrılarak iner; kökte küçük çentik
	var blade = [[0.036, -0.066], [0.015, -0.105], [-0.02, -0.15], [-0.075, -0.2], [-0.16, -0.245], [-0.11, -0.19], [-0.07, -0.145],
		[-0.045, -0.105], [-0.04, -0.086], [-0.034, -0.08], [-0.028, -0.075], [-0.028, -0.066]]   # çubuğun devamı, uca doğru avuç tarafına kıvrılır
	b.add_slab(V.call(blade), 0.012, col, xf, Callable(), col.lightened(0.25))
	# keskin dış kenar şeridi (açık renk)
	var arc = [[0.036, -0.066], [0.015, -0.105], [-0.02, -0.15], [-0.075, -0.2], [-0.16, -0.245]]
	var band = []
	for q in arc:
		band.append([q[0] + 0.004, q[1] - 0.004])
	for k in range(arc.size() - 1, -1, -1):
		band.append([arc[k][0] - 0.004, arc[k][1] + (0.009 if k < arc.size() - 1 else 0.0)])
	b.add_slab(V.call(band), 0.014, edge, xf, Callable(), edge.darkened(0.15))
	if wind:   # rüzgar chakrası: bıçağın dışında ince yeşil-mavi ışıltı
		var glow = []
		for q in arc:
			glow.append([q[0] + 0.016, q[1] - 0.014])
		for k in range(arc.size() - 1, -1, -1):
			glow.append([arc[k][0] + 0.004, arc[k][1] - 0.004])
		b.add_slab(V.call(glow), 0.004, Color(0.6, 1.0, 0.85), xf)


## Rüzgar Chakra Bıçağı (ruzgarchakrabicagi.png): yalnız chakradan, yarı saydam açık yeşil kunai biçimli bıçak (baklava kesit,
## uca incelen), yumruğun içinde ince öz. İçinde kökten uca AKAN rüzgar bantları (wind_flow shader). Dönen sarmal şeritler ve
## halka ayrı düğüm (_wind_ribbons, CharacterModel her karede döndürür) + etrafta sürekli rüzgar çizgileri (_wind_air).
static var _wind_core_mat: ShaderMaterial
static var _wind_rib_mat: ShaderMaterial


static func _wind_mat(alpha: float, speed: float, bands: float, soft: float) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/wind_flow.gdshader")
	m.set_shader_parameter("base_alpha", alpha)
	m.set_shader_parameter("flow_speed", speed)
	m.set_shader_parameter("bands", bands)
	m.set_shader_parameter("edge_soft", soft)
	return m


static func _wind_blade(m: ArrayMesh) -> void:
	if _wind_core_mat == null:
		_wind_core_mat = _wind_mat(0.62, 1.6, 2.5, 0.08)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var put = func(p: Vector3, n: Vector3, uv: Vector2):
		st.set_normal(n)
		st.set_uv(uv)
		st.add_vertex(p)
	# bıçak: kesit baklava (genişlik y, kalınlık x); UV.x = boy (0 kök .. 1 uç), UV.y = çevre
	var prof = [[0.06, 0.012, 0.004], [0.1, 0.03, 0.008], [0.24, 0.05, 0.012], [0.45, 0.026, 0.007], [0.6, 0.0, 0.0]]
	for k in prof.size() - 1:
		var a = prof[k]; var e = prof[k + 1]
		var ring = func(q: Array) -> Array:
			return [Vector3(0, q[1], q[0]), Vector3(q[2], 0, q[0]), Vector3(0, -q[1], q[0]), Vector3(-q[2], 0, q[0])]
		var ra = ring.call(a); var re = ring.call(e)
		var ua = (float(a[0]) - 0.06) / 0.54; var ue = (float(e[0]) - 0.06) / 0.54
		for j in 4:
			var j2 = (j + 1) % 4
			var n = (ra[j2] - ra[j]).cross(re[j] - ra[j]).normalized()
			var va = float(j) / 4.0; var vb = float(j + 1) / 4.0
			for q in [[ra[j], ua, va], [ra[j2], ua, vb], [re[j2], ue, vb], [ra[j], ua, va], [re[j2], ue, vb], [re[j], ue, va]]:
				put.call(q[0], n, Vector2(q[1], 0.15 + q[2] * 0.7))
	# yumruğun içindeki ince öz
	for j in 6:
		var a0 = TAU * j / 6.0; var a1 = TAU * (j + 1) / 6.0
		var r = 0.012
		var p0 = Vector3(cos(a0) * r, sin(a0) * r, -0.08); var p1 = Vector3(cos(a1) * r, sin(a1) * r, -0.08)
		var q0 = Vector3(cos(a0) * r, sin(a0) * r, 0.07); var q1 = Vector3(cos(a1) * r, sin(a1) * r, 0.07)
		var n = Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0)
		for q in [[p0, 0.0, 0.2], [p1, 0.0, 0.8], [q1, 0.1, 0.8], [p0, 0.0, 0.2], [q1, 0.1, 0.8], [q0, 0.1, 0.2]]:
			put.call(q[0], n, Vector2(q[1], q[2]))
	st.commit(m)
	m.surface_set_material(m.get_surface_count() - 1, _wind_core_mat)


## Dönen rüzgar şeritleri + kabza halkası (UV.x boy boyunca akar, UV.y şerit eni)
static var _wind_rib_mesh: ArrayMesh
static func _wind_ribbons() -> MeshInstance3D:
	if _wind_rib_mesh == null:
		_wind_rib_mat = _wind_mat(0.5, 3.2, 2.0, 0.45)
		_wind_rib_mesh = ArrayMesh.new()
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var quad = func(a: Vector3, b2: Vector3, c: Vector3, d: Vector3, u0: float, u1: float):
			var n = (b2 - a).cross(d - a).normalized()
			for q in [[a, u0, 0.0], [b2, u1, 0.0], [c, u1, 1.0], [a, u0, 0.0], [c, u1, 1.0], [d, u0, 1.0]]:
				st.set_normal(n)
				st.set_uv(Vector2(q[1], q[2]))
				st.add_vertex(q[0])
		var N = 24
		for j in N:   # kabza halkası
			var a0 = TAU * j / N; var a1 = TAU * (j + 1) / N
			var R = 0.05
			quad.call(Vector3(cos(a0) * R, sin(a0) * R, -0.115), Vector3(cos(a1) * R, sin(a1) * R, -0.115),
				Vector3(cos(a1) * R * 1.25, sin(a1) * R * 1.25, -0.095), Vector3(cos(a0) * R * 1.25, sin(a0) * R * 1.25, -0.095), float(j) / N, float(j + 1) / N)
		for s2 in 3:   # üç sarmal şerit: kökten uca dönerek daralır, uçta açılıp kopar
			var ph = TAU * s2 / 3.0
			var M = 22
			for j in M:
				var t0 = float(j) / M; var t1 = float(j + 1) / M
				var pt = func(t: float, off: float) -> Vector3:
					var a = ph + t * TAU * 1.4
					var r = lerpf(0.08, 0.022, t) + off + (0.05 * t * t if s2 == 0 else 0.0)
					return Vector3(cos(a) * r, sin(a) * r, lerpf(-0.06, 0.66, t))
				quad.call(pt.call(t0, 0.0), pt.call(t1, 0.0), pt.call(t1, 0.012) + Vector3(0, 0, 0.022), pt.call(t0, 0.012) + Vector3(0, 0, 0.022), t0, t1)
		st.commit(_wind_rib_mesh)
		_wind_rib_mesh.surface_set_material(0, _wind_rib_mat)
	var mi = MeshInstance3D.new()
	mi.name = "WindRibbons"
	mi.mesh = _wind_rib_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


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


## Muşta bıçağı: parmak korumalı (D muhafız) savaş bıçağı — yumrukta sap, sapın önünde dört parmak deliği olan pirinç muşta
## kemeri (yumruk yüzünde dört kabarık topuz), kemer topuzdan çapraz korumaya bağlanır; çift ağızlı yaprak ağız (+Z), ortada oluk.
static func _musta(b: MB) -> void:
	var brass = Color(0.62, 0.5, 0.26)
	var steel = Color(0.7, 0.72, 0.77)
	var grip = Color(0.18, 0.12, 0.08)
	b.add("cyl", Vector3(0, 0, -0.03), Vector3(0.03, 0.12, 0.03), grip, Vector3(90, 0, 0), 10)   # ahşap sap
	for k in 4:
		b.add("cyl", Vector3(0, 0, -0.075 + k * 0.03), Vector3(0.033, 0.006, 0.033), grip.darkened(0.3), Vector3(90, 0, 0), 10)
	b.add("sphere", Vector3(0, 0, -0.1), Vector3(0.035, 0.035, 0.03), brass, Vector3.ZERO, 8)   # topuz
	b.add("box", Vector3(0, 0.022, 0.035), Vector3(0.024, 0.1, 0.016), brass)   # çapraz koruma (muşta kemerine bağlanır)
	b.add("box", Vector3(0, 0.03, -0.1), Vector3(0.02, 0.06, 0.014), brass)   # topuzdan kemere bağ
	# D muhafız (parmakların üstü, +Y tarafı): topuzdan korumaya kavisli kemer + dört parmak halkası
	var arc = PackedVector2Array()
	var inner = PackedVector2Array()
	for k in 13:
		var t = float(k) / 12.0
		var z = lerpf(-0.1, 0.035, t)
		var y = 0.056 + sin(t * PI) * 0.01
		arc.append(Vector2(y + 0.012, z))
		inner.append(Vector2(y - 0.004, z))
	var band = PackedVector2Array()
	for q in arc:
		band.append(q)
	for k in range(inner.size() - 1, -1, -1):
		band.append(inner[k])
	b.add_slab(band, 0.022, brass, Transform3D.IDENTITY, Callable(), brass.darkened(0.25))
	for k in 4:   # parmak halkaları (kemer ile sap arası) + yumruk yüzü topuzları
		var z = -0.072 + k * 0.032
		b.add("torus", Vector3(0, 0.036, z), Vector3(0.017, 0.017, 0.017), brass, Vector3(0, 0, 90), 10)
		b.add("sphere", Vector3(0, 0.072, z), Vector3(0.011, 0.011, 0.011), brass.lightened(0.15), Vector3.ZERO, 6)
	# çift ağızlı yaprak ağız
	var bl = PackedVector2Array([Vector2(0.012, 0.04), Vector2(0.022, 0.08), Vector2(0.024, 0.15), Vector2(0.016, 0.21), Vector2(0.0, 0.25),
		Vector2(-0.016, 0.21), Vector2(-0.024, 0.15), Vector2(-0.022, 0.08), Vector2(-0.012, 0.04)])
	b.add_slab(bl, 0.009, steel, Transform3D.IDENTITY, func(q: Vector2) -> float: return 0.009 if absf(q.x) < 0.01 else 0.003, steel.darkened(0.2))
	b.add("box", Vector3(0, 0, 0.13), Vector3(0.0095, 0.004, 0.15), steel.lightened(0.3))   # oluk parlaması


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
## Tonfa: yan kabza yumrukta (z ekseni, kumaş sargılı, ucunda topuz), ana gövde serçe parmak altında ön kol boyunca (-x: dirseğe
## doğru) uzanır; koyu cilalı ahşap, iki uçta koyu metal bilezik + yuvarlak başlık, kabza bağlantısında metal pul, gövdede ahşap damarı.
static func _tonfa(b: MB) -> void:
	var wood = Color(0.33, 0.21, 0.12)
	var dwood = Color(0.22, 0.14, 0.08)
	var metal = Color(0.25, 0.25, 0.28)
	var wrapc = Color(0.15, 0.13, 0.14)
	# yan kabza + sargı + topuz
	b.add("cyl", Vector3(0, 0, -0.035), Vector3(0.032, 0.16, 0.032), wood, Vector3(90, 0, 0), 10)
	for k in 5:
		b.add("torus", Vector3(0, 0, -0.07 + k * 0.022), Vector3(0.038, 0.02, 0.038), wrapc, Vector3(90, 0, 12 if k % 2 == 0 else -12), 8)
	b.add("sphere", Vector3(0, 0, 0.055), Vector3(0.045, 0.045, 0.03), dwood, Vector3.ZERO, 8)
	# ana gövde (ön kol boyunca): ön kolun dış yüzünde (kol + kolluk ~6 cm; eskiden 8.5 cm'de kolun içine gömülüyordu, yalnız kısa uç görünüyordu)
	var gz = -0.115
	b.add("cyl", Vector3(-0.14, 0, gz), Vector3(0.042, 0.56, 0.042), wood, Vector3(0, 0, 90), 12)
	for xx in [-0.36, -0.22, -0.05, 0.08]:   # ahşap damarı: koyu ince halkalar
		b.add("cyl", Vector3(xx, 0, gz), Vector3(0.0435, 0.006, 0.0435), dwood, Vector3(0, 0, 90), 12)
	for xx in [-0.4, 0.12]:   # uç bilezikleri + yuvarlak başlık
		b.add("cyl", Vector3(xx, 0, gz), Vector3(0.047, 0.04, 0.047), metal, Vector3(0, 0, 90), 12)
		b.add("sphere", Vector3(xx + (-0.03 if xx < 0 else 0.03), 0, gz), Vector3(0.042, 0.042, 0.042), dwood, Vector3.ZERO, 10)
	b.add("cyl", Vector3(0, 0, gz + 0.03), Vector3(0.05, 0.012, 0.05), metal, Vector3(90, 0, 0), 10)   # kabza pulu


## Yagura'nın sopası (ref yagurastaff.png): koyu mavi-gri, sekizgen kesitli, uca doğru hafif incelen uzun sopa; üst uçta küçük, alt uçta
## büyük ters (karşı yöne) kıvrık kanca; alt kancanın hemen üstünde 5 yapraklı mavi-yeşil çiçek (sarı göbek). Tutuş z=0 (sopanın alt
## üçte biri), üst uç +Z (~1.25 m), alt uç -Z (~0.45 m).
static func _yagura(b: MB) -> void:
	var dk = Color(0.2, 0.22, 0.3)
	var hi = Color(0.32, 0.34, 0.44)
	var z0 = -0.42
	var z1 = 1.22
	var n = 12
	for k in n:
		var t0 = float(k) / n; var t1 = float(k + 1) / n
		var r0 = lerpf(0.026, 0.017, t0); var r1 = lerpf(0.026, 0.017, t1)
		var za = lerpf(z0, z1, t0); var zb = lerpf(z0, z1, t1)
		b.add("cyl", Vector3(0, 0, (za + zb) * 0.5), Vector3(r0 + r1, zb - za + 0.002, r0 + r1), dk if k % 2 == 0 else dk.lightened(0.03), Vector3(90, 0, 0), 8)
	b.add("box", Vector3(0, 0.012, (z0 + z1) * 0.5), Vector3(0.006, 0.004, z1 - z0), hi)   # kenar parlaması
	# kancalar: üstte +Y'ye küçük, altta -Y'ye büyük (ters yön)
	var hook = func(base: Vector3, dirz: float, side: float, R: float, w: float) -> void:
		var steps = 10
		var prev = base
		for k in range(1, steps + 1):
			var a = PI * 1.15 * float(k) / steps
			var p = base + Vector3(0, side * R * (1.0 - cos(a)), dirz * R * sin(a))
			var d = p - prev
			var ww = w * (1.0 - 0.6 * float(k) / steps)
			b.add_xf("cyl", Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(ww, d.length() * 1.15, ww)), (p + prev) * 0.5), dk, 6)
			prev = p
	hook.call(Vector3(0, 0, z1), 1.0, 1.0, 0.035, 0.03)
	hook.call(Vector3(0, 0, z0), -1.0, -1.0, 0.07, 0.05)
	# çiçek: alt kancanın üstünde, sopanın yan yüzünde (x+), 5 yaprak
	var fc = Vector3(0.032, 0, z0 + 0.16)
	var petal = Color(0.55, 0.85, 0.78)
	for k in 5:
		var a = TAU * k / 5.0
		b.add("sphere", fc + Vector3(0.004, cos(a) * 0.062, sin(a) * 0.062), Vector3(0.014, 0.07, 0.07), petal, Vector3(rad_to_deg(a), 0, 0), 8)
	b.add("sphere", fc + Vector3(0.012, 0, 0), Vector3(0.018, 0.04, 0.04), Color(0.95, 0.82, 0.35), Vector3.ZERO, 8)


## Orak (ref orak.png): uzun siyah sap, altta gri sargılı tutuş + uçta halka (kızıl kurdele CharacterModel'de, sallanır), üstte gri
## sargı ve koyu blok baş; baştan -Y yönüne çıkıp sapa doğru (-Z) kıvrılan uzun hilal bıçak: koyu sırt, içte kızıl şerit, açık ağız.
## Tutuş z=0 (alt sargı), baş z~1.6. Profil x -> Y, y -> Z.
static func _orak(b: MB) -> void:
	var blk = Color(0.1, 0.1, 0.12)
	var gray = Color(0.66, 0.66, 0.7)
	var red = Color(0.7, 0.07, 0.12)
	b.add("cyl", Vector3(0, 0, 0.68), Vector3(0.05, 1.86, 0.05), blk, Vector3(90, 0, 0), 10)
	for k in 9:   # alt sargı (tutuş)
		b.add("cyl", Vector3(0, 0, -0.18 + k * 0.035), Vector3(0.058, 0.024, 0.058), gray if k % 2 == 0 else gray.darkened(0.25), Vector3(90, 0, 0), 10)
	for k in 6:   # üst sargı
		b.add("cyl", Vector3(0, 0, 1.3 + k * 0.035), Vector3(0.056, 0.024, 0.056), gray if k % 2 == 0 else gray.darkened(0.25), Vector3(90, 0, 0), 10)
	b.add("torus", Vector3(0, 0, -0.3), Vector3(0.11, 0.11, 0.08), blk, Vector3(0, 90, 0), 12)   # uç halkası
	b.add("box", Vector3(0, -0.04, 1.62), Vector3(0.07, 0.16, 0.11), blk.lightened(0.05))        # blok baş
	b.add("box", Vector3(0, -0.04, 1.62), Vector3(0.075, 0.12, 0.02), gray)                      # baş bandı
	# hilal bıçak
	var outer = [[-0.1, 1.66], [-0.35, 1.63], [-0.58, 1.5], [-0.76, 1.28], [-0.86, 1.02], [-0.9, 0.82]]
	var inner = [[-0.8, 0.98], [-0.68, 1.22], [-0.5, 1.4], [-0.28, 1.5], [-0.1, 1.55]]
	var pts = PackedVector2Array()
	for e in outer + inner:
		pts.append(Vector2(e[0], e[1]))
	b.add_slab(pts, 0.022, blk, Transform3D.IDENTITY, func(p: Vector2) -> float: return 0.022, blk.lightened(0.1))
	# kızıl şerit (iç tarafta, iki yüzde) + açık ağız çizgisi
	var rs = PackedVector2Array()
	for e in [[-0.14, 1.58], [-0.32, 1.54], [-0.54, 1.42], [-0.72, 1.22], [-0.82, 1.0], [-0.86, 0.86], [-0.8, 0.98], [-0.68, 1.22], [-0.5, 1.4], [-0.28, 1.5], [-0.12, 1.555]]:
		rs.append(Vector2(e[0], e[1]))
	b.add_slab(rs, 0.026, red, Transform3D.IDENTITY, func(p: Vector2) -> float: return 0.026, red.darkened(0.2))


## Pençe (ref claw.png): el sırtında koyu gri kavisli plaka (üç delik), parmak eklemlerinden ileri (+x) uzanan üç uzun hafif kavisli
## koyu bıçak (uca doğru incelir, üst kenarda açık çizgi), bıçak diplerinde parmak halkaları. Yumruk boyunca (z) dizilir.
static func _pence(b: MB) -> void:
	var dk = Color(0.15, 0.15, 0.17)
	var plate = Color(0.32, 0.32, 0.35)
	b.add("box", Vector3(-0.02, 0.048, 0.0), Vector3(0.11, 0.022, 0.1), plate)
	for k in 3:
		b.add("cyl", Vector3(-0.03 + (k % 2) * 0.03, 0.06, -0.025 + k * 0.025), Vector3(0.012, 0.004, 0.012), Color(0.08, 0.08, 0.09), Vector3.ZERO, 8)   # delikler
	b.add("box", Vector3(0.04, 0.035, 0.0), Vector3(0.035, 0.04, 0.095), dk)
	for k in 3:
		var z = (k - 1) * 0.03
		b.add("torus", Vector3(0.06, 0.015, z), Vector3(0.028, 0.028, 0.02), dk, Vector3(0, 0, 0), 8)   # parmak halkası
		var prev = Vector3(0.06, 0.04, z)
		for j in range(1, 9):
			var t = float(j) / 8.0
			var p = Vector3(0.06 + t * 0.42, 0.04 + 0.03 * sin(t * PI * 0.8) - t * t * 0.05, z * (1.0 + t * 0.25))
			var d = p - prev
			var w = 0.024 * (1.0 - t * 0.85) + 0.003
			b.add_xf("box", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.006, w, d.length() * 1.1)), (p + prev) * 0.5), dk)
			b.add_xf("box", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.007, 0.003, d.length() * 1.1)), (p + prev) * 0.5 + Vector3(0, w * 0.5, 0)), Color(0.55, 0.56, 0.6))
			prev = p


## Savaş çekici (ref savascekici.png): koyu çatlaklı blok kafa (kenarları pahlı), ortasında perçinli açık çelik bant, sapla
## kafa arasında kare yaka; uzun gri sargılı sap (sarmal sargı çizgileri), uçta halka (siyah kurdele CharacterModel'de, sallanır).
## Tutuş z=0 (sağ yumruk sapın alt ucunda), kafa +Z ucunda, kafanın uzun ekseni X.
static func _cekic(b: MB) -> void:
	var blk = Color(0.2, 0.2, 0.23)
	var band = Color(0.6, 0.62, 0.66)
	var wrapc = Color(0.62, 0.62, 0.66)
	b.add("cyl", Vector3(0, 0, 0.5), Vector3(0.062, 1.2, 0.062), wrapc.darkened(0.1), Vector3(90, 0, 0), 10)
	for k in 16:   # sarmal sargı çizgileri
		b.add("torus", Vector3(0, 0, -0.04 + k * 0.072), Vector3(0.07, 0.03, 0.07), wrapc.darkened(0.35), Vector3(90, 0, 14), 10)
	b.add("torus", Vector3(0, 0, -0.16), Vector3(0.14, 0.14, 0.1), blk, Vector3(0, 90, 0), 12)   # uç halkası
	b.add("cyl", Vector3(0, 0, -0.08), Vector3(0.075, 0.05, 0.075), blk, Vector3(90, 0, 0), 10)
	b.add("box", Vector3(0, 0, 1.12), Vector3(0.2, 0.2, 0.05), blk.lightened(0.05))   # kare yaka
	# blok kafa: ana gövde + pahlı kenarlar (her köşede yarım kutu)
	var hz = 1.36
	b.add("box", Vector3(0, 0, hz), Vector3(0.62, 0.42, 0.44), blk)
	for sx in [-1.0, 1.0]:
		b.add("box", Vector3(sx * 0.32, 0, hz), Vector3(0.04, 0.36, 0.38), blk.darkened(0.15))   # vuruş yüzü pahı
	b.add("box", Vector3(0, 0, hz), Vector3(0.13, 0.44, 0.46), band)   # çelik bant
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 0.0, 1.0]:
			b.add("sphere", Vector3(0, sy * 0.225, hz + sz * 0.15), Vector3(0.025, 0.012, 0.025), band.darkened(0.35), Vector3.ZERO, 6)
	for sz in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			b.add("sphere", Vector3(0, sy * 0.14, hz + sz * 0.235), Vector3(0.025, 0.025, 0.012), band.darkened(0.35), Vector3.ZERO, 6)
	# çatlaklar
	for c in [[0.2, 0.08, 20.0], [-0.18, -0.1, -35.0], [0.24, -0.12, 60.0]]:
		b.add("box", Vector3(c[0], c[1], hz + 0.222), Vector3(0.12, 0.006, 0.003), Color(0.08, 0.08, 0.09), Vector3(0, 0, c[2]))


## Zincirli kunai (ref zincirlikunai.png): büyük köşeli koyu kunai (elmas kesitli yaprak ağız), açık gri bantlı sap, sap ucunda halka.
## Tutuş z=0, uç +Z.
static func _zkunai(b: MB) -> void:
	var dk = Color(0.2, 0.2, 0.23)
	var lt = Color(0.65, 0.66, 0.7)
	b.add("cyl", Vector3(0, 0, -0.01), Vector3(0.03, 0.12, 0.03), dk, Vector3(90, 0, 0), 8)
	for k in 5:
		b.add("cyl", Vector3(0, 0, -0.055 + k * 0.022), Vector3(0.034, 0.012, 0.034), lt, Vector3(90, 0, 0), 8)
	b.add("torus", Vector3(0, 0, -0.105), Vector3(0.07, 0.07, 0.05), dk, Vector3(0, 90, 0), 10)
	b.add("cyl", Vector3(0, 0, 0.055), Vector3(0.036, 0.02, 0.036), dk, Vector3(90, 0, 0), 8)   # ağız bileziği (sapla ağzı birleştirir)
	# elmas kesitli ağız: tabanı sapa gömülü kısa boyun (dörtgen kesit), en geniş yer %30'da, uca sivri
	var L = 0.34
	var z0 = 0.04
	var w = 0.075
	var t = 0.028
	var nw = 0.016
	var nt = 0.012
	var ring0 = [Vector3(nw, 0, z0), Vector3(0, nt, z0), Vector3(-nw, 0, z0), Vector3(0, -nt, z0)]
	var ring1 = [Vector3(w, 0, z0 + L * 0.3), Vector3(0, t, z0 + L * 0.3), Vector3(-w, 0, z0 + L * 0.3), Vector3(0, -t, z0 + L * 0.3)]
	var tip = Vector3(0, 0, z0 + L)
	var base = Vector3(0, 0, z0 - 0.005)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 4:
		var k2 = (k + 1) % 4
		var shade = 1.0 if k % 2 == 0 else 0.78
		var col = dk.lightened(0.08) * Color(shade, shade, shade)
		for tri in [[ring0[k], ring1[k2], ring1[k]], [ring0[k], ring0[k2], ring1[k2]], [tip, ring1[k], ring1[k2]], [base, ring0[k2], ring0[k]]]:
			for v in tri:
				st.set_color(col)
				st.add_vertex(v)
	st.generate_normals()
	_mb_add_surface(b, st)


static func _mb_add_surface(b: MB, st: SurfaceTool) -> void:
	st.index()
	b.add_arrays(st.commit_to_arrays(), Transform3D.IDENTITY, Color(0.24, 0.24, 0.27))


## Fūma shuriken (ref fuumashuriken.png): göbek halkası z=0.09'da (el halkayı kavrar), düzlem XY (yassı yüz ±Z).
## Her bıçak: göbekten dışa uzanan, uca doğru yana kıvrılan orak; koyu çelik, içbükey kenarında açık bileylenmiş ağız şeridi.
## closed: dört bıçak aynı yöne yelpaze gibi üst üste (kın hâli).
static func _fuma(b: MB, closed: bool) -> void:
	var dark = Color(0.13, 0.13, 0.15)
	var edge = Color(0.82, 0.83, 0.86)
	var hub = Vector3(0, 0, 0.09)
	var R = 0.58
	var to_xy := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))   # profil (u: göbekten dışa, v: yan) -> (x=-v, y=u)
	for k in 4:
		var ang = TAU * k / 4.0 if not closed else deg_to_rad(-12.0 + k * 8.0)
		var rot = Basis(Vector3(0, 0, 1), ang)
		var zoff = (float(k) - 1.5) * 0.007 if closed else 0.0
		var n = 14
		var cen = []
		for i in n + 1:
			var t = float(i) / n
			var c = Vector2(0.07 + t * (R - 0.07), 0.32 * R * t * t)   # uca doğru yana kıvrılır (orak)
			var w = 0.21 * sin(PI * clampf(0.1 + t * 0.92, 0.0, 1.0)) * (1.0 - t * 0.25) + 0.03   # geniş orak gövde (ref)
			cen.append([c, w])
		var bl = PackedVector2Array()
		for e in cen:
			bl.append(e[0] + Vector2(0, -1) * e[1] * 0.5)
		for i in range(cen.size() - 1, -1, -1):
			bl.append(cen[i][0] + Vector2(0, 1) * cen[i][1] * 0.5)
		b.add_slab(bl, 0.012, dark, Transform3D(rot * to_xy, hub + Vector3(0, 0, zoff)), Callable(), dark.darkened(0.3))
		# bileylenmiş ağız: içbükey (kıvrılan) kenar boyunca açık şerit, iki yüzde
		for i in range(2, n):
			var p0: Vector2 = cen[i][0] + Vector2(0, 1) * float(cen[i][1]) * 0.36
			var p1: Vector2 = cen[i + 1][0] + Vector2(0, 1) * float(cen[i + 1][1]) * 0.36
			var mid = (p0 + p1) * 0.5
			var seg = p1 - p0
			var d3 = rot * Vector3(-seg.y, seg.x, 0)
			for sz in [-1.0, 1.0]:
				var wp = rot * Vector3(-mid.y, mid.x, 0) + hub + Vector3(0, 0, zoff + sz * 0.0065)
				b.add("box", wp, Vector3(seg.length() * 1.15, float(cen[i][1]) * 0.26, 0.002), edge, Vector3(0, 0, rad_to_deg(atan2(d3.y, d3.x))))
	# göbek halkası (el içinden geçer)
	b.add("torus", hub, Vector3(0.15, 0.15, 0.15), dark.lightened(0.05), Vector3(90, 0, 0), 14)
	b.add("cyl", hub, Vector3(0.1, 0.03 if not closed else 0.045, 0.1), dark, Vector3(90, 0, 0), 12)


## Dev shuriken (ref fumavaryasyon.png): 2.5 m düz kenarlı dört köşeli koyu yıldız, ortada halka girinti; tutuş göbekte (z=0.12)
static func _kyodai(b: MB) -> void:
	_w_star(b, Vector3(0, 0, 0.12), 1.25, 0.42, 4, Color(0.22, 0.21, 0.2), Color(0.1, 0.1, 0.1), 0.44)   # geniş gövdeli yıldız (ref)
	b.add("torus", Vector3(0, 0, 0.12), Vector3(0.32, 0.32, 0.32), Color(0.12, 0.12, 0.12), Vector3(90, 0, 0), 16)


## Kare Fūma (ref fumavaryasyon2.png): dört sivri köşeli kare yıldız, açık gri kalın çerçeve, koyu iç yüz, ortada delik
static func _fuma_kare(b: MB) -> void:
	var c = Vector3.ZERO
	var R = 0.55
	_w_star(b, c, R, R * 0.36, 4, Color(0.78, 0.79, 0.82), Color(0.3, 0.3, 0.32), 0.62)   # kareye yakın, köşeleri sivri (ref)
	# koyu iç yüz (iki yanda hafif kabarık)
	var to_xy := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
	var o := PackedVector2Array()
	for k in 4:
		var a = TAU * k / 4.0
		var a2 = TAU * (k + 0.5) / 4.0
		o.append(Vector2(sin(a), cos(a)) * R * 0.72)
		o.append(Vector2(sin(a2), cos(a2)) * R * 0.46)
	for sz in [-1.0, 1.0]:
		b.add_slab(o, 0.004, Color(0.3, 0.3, 0.33), Transform3D(to_xy, c + Vector3(0, 0, sz * 0.012)), Callable(), Color(0.25, 0.25, 0.28))
	b.add("torus", c, Vector3(0.16, 0.16, 0.16), Color(0.7, 0.71, 0.74), Vector3(90, 0, 0), 14)
	b.add("cyl", c, Vector3(0.1, 0.035, 0.1), Color(0.05, 0.05, 0.06), Vector3(90, 0, 0), 12)   # delik (koyu)


## Çağırma parşömeni: kalın rulo, iki uçta koyu kapak, ortada kırmızı mühür bağı (tutuş ortada, rulo ekseni X)
static func _makimono(b: MB) -> void:
	b.add("cyl", Vector3(0, 0, 0.05), Vector3(0.11, 0.42, 0.11), Color(0.92, 0.88, 0.76), Vector3(0, 0, 90), 14)
	for sx in [-1.0, 1.0]:
		b.add("cyl", Vector3(sx * 0.22, 0, 0.05), Vector3(0.125, 0.03, 0.125), Color(0.35, 0.2, 0.12), Vector3(0, 0, 90), 14)
	b.add("cyl", Vector3(0, 0, 0.05), Vector3(0.118, 0.04, 0.118), Color(0.75, 0.12, 0.1), Vector3(0, 0, 90), 14)


static func _w_star(b: MB, c: Vector3, R: float, w: float, n: int, steel: Color, hub: Color, ratio := -1.0) -> void:
	var to_xy := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))   # profil (u,v) -> dünya (x=-v, y=u)
	var r_in := R * (ratio if ratio > 0.0 else clampf(w / R, 0.26, 0.36))   # uçlar arası iç köşe
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


## Temari'nin Dev Yelpazesi (ref _tmp/temariref: "Giant Folding Fan", "Temari Riding Fan"): bej kâğıt, tırtıklı üst kenar,
## ince koyu kaburga çizgileri, alt kısımda açıkta kalan koyu kaburgalar, iki kenarda kalın siyah koruma çubuğu, kâğıtta üç
## büyük mor daire (ay). stage 0 kapalı (siyah kalın çubuk, ucunda bej kâğıt kenarı); 1/2/3 = birinci/ikinci/üçüncü aya kadar
## açık. Mafsal tutuşun hemen arkasında; sabit çubuk +Z boyunca, yelpaze +Y yönüne açılır (yüz ±X). Boy ~1.6 m.
static func _temari_fan(b: MB, stage: int) -> void:
	var P := Vector3(0, 0, -0.12)
	var R := 1.45
	var r0 := 0.52
	var blk := Color(0.08, 0.07, 0.07)
	var paper := Color(0.93, 0.87, 0.74)
	var rib := Color(0.36, 0.28, 0.22)
	var moon := Color(0.42, 0.18, 0.56)
	b.add("cyl", P, Vector3(0.09, 0.16, 0.09), Color(0.55, 0.52, 0.5), Vector3(0, 0, 90), 10)   # mafsal perçini
	if stage <= 0:
		b.add("box", P + Vector3(0, 0.0, 0.73), Vector3(0.12, 0.17, 1.66), blk)   # kapalı demet (koruma çubukları)
		b.add("box", P + Vector3(0, 0.0, 1.5), Vector3(0.1, 0.15, 0.1), paper.darkened(0.1))   # uçta görünen kâğıt kenarı
		for k in 4:
			b.add("box", P + Vector3(0.061, -0.06 + k * 0.04, 0.95), Vector3(0.004, 0.006, 1.0), Color(0.18, 0.16, 0.15))   # kaburga çizgileri
		return
	var A: float = deg_to_rad([0.0, 62.0, 118.0, 168.0][clampi(stage, 1, 3)])
	var dirf = func(a: float) -> Vector3: return Vector3(0, sin(a), cos(a))
	var pr = func(a: float, r: float) -> Vector2: return Vector2(sin(a) * r, P.z + cos(a) * r)   # profil (y, z)
	var n := maxi(3, int(rad_to_deg(A) / 11.0))
	# kâğıt: iç yay (r0) + tırtıklı dış kenar (her panelin ortası hafif içe)
	var o := PackedVector2Array()
	for k in n + 1:
		o.append(pr.call(A * k / n, r0))
	for k in range(n, 0, -1):
		for j in 4:
			var t := j / 4.0
			var a := A * (k - t) / n
			o.append(pr.call(a, R - 0.05 * sin(t * PI)))
	o.append(pr.call(0.0, R))
	b.add_slab(o, 0.024, paper, Transform3D.IDENTITY, Callable(), paper.darkened(0.25))
	# alt kısım: kâğıtsız koyu kaburga bölgesi
	var o2 := PackedVector2Array()
	for k in n + 1:
		o2.append(pr.call(A * k / n, 0.1))
	for k in range(n, -1, -1):
		o2.append(pr.call(A * k / n, r0 + 0.01))
	b.add_slab(o2, 0.04, blk, Transform3D.IDENTITY, Callable(), blk)
	# ince kaburga çizgileri (iki yüzde)
	for k in range(1, n):
		var a := A * k / n
		var c: Vector3 = P + dirf.call(a) * ((r0 + R - 0.06) * 0.5)
		for sx in [-1.0, 1.0]:
			b.add("box", c + Vector3(sx * 0.0135, 0, 0), Vector3(0.003, 0.012, R - 0.06 - r0), rib, Vector3(-rad_to_deg(a), 0, 0))
	# kalın siyah koruma çubukları (iki kenar)
	for a in [0.0, A]:
		var L := R + 0.14
		b.add("box", P + dirf.call(a) * (L * 0.5 - 0.12), Vector3(0.075, 0.075, L), blk, Vector3(-rad_to_deg(a), 0, 0))
	# mor aylar: açılan kısımda görünenler (birinci, ikinci, üçüncü ay)
	for ma in [30.0, 86.0, 140.0]:
		if deg_to_rad(ma + 9.0) <= A:
			b.add("cyl", P + dirf.call(deg_to_rad(ma)) * 1.0, Vector3(0.34, 0.032, 0.34), moon, Vector3(0, 0, 90), 18)


static func weapon_mesh(id: String) -> ArrayMesh:
	if _weapon_cache.has(id):
		return _weapon_cache[id]
	var b = MB.new()
	var steel = Color(0.72, 0.75, 0.8)
	var dark = Color(0.12, 0.12, 0.14)
	var wrap = Color(0.85, 0.82, 0.75)
	match id:
		"kunai":
			_kunai_mesh(b)
		"tanto":
			# kısa düz hançer-kılıç (ANBU tantōsu): hamonlu düz ağız ~30 cm, küçük siyah yuvarlak tsuba, altın habaki,
			# koyu kırmızı-siyah sargılı kısa tsuka, metal kashira
			_w_tsuka(b, -0.13, 0.02, 0.015, Color(0.32, 0.06, 0.07))
			_w_tsuba(b, 0.03, 0.028, Color(0.1, 0.1, 0.11))
			_w_blade(b, 0.035, 0.3, 0.026, 0.003, steel)
		"mateki":
			# Mateki (ref _tmp/dokiref/doki_3 "Demonic Flute"): uzun ince beyaz-lavanta yan flüt (~48 cm), iki ucunda kalın metal
			# halka, üfleme deliği + yedi parmak deliği (koyu), açık uç ağzı. Tutuş flütün ortasında (z=0): çalarken üfleme ucu
			# (-Z) elin solundan ağzın önüne gelir, gövde sağa uzanır (yan flüt gibi). Flüt -0.2..+0.28
			var fl = Color(0.88, 0.86, 0.94)
			var ring = Color(0.62, 0.6, 0.68)
			b.add("cyl", Vector3(0, 0, 0.04), Vector3(0.03, 0.48, 0.03), fl, Vector3(90, 0, 0), 14)
			for z in [-0.195, 0.275]:
				b.add("cyl", Vector3(0, 0, z), Vector3(0.036, 0.025, 0.036), ring, Vector3(90, 0, 0), 14)
			b.add("cyl", Vector3(0, 0, 0.28), Vector3(0.022, 0.01, 0.022), Color(0.15, 0.14, 0.18), Vector3(90, 0, 0), 12)   # açık uç
			b.add("sphere", Vector3(0, 0.015, -0.15), Vector3(0.012, 0.006, 0.016), Color(0.12, 0.1, 0.14), Vector3.ZERO, 6)   # üfleme deliği
			for k in 7:
				b.add("sphere", Vector3(0, 0.015, -0.06 + k * 0.042), Vector3(0.01, 0.005, 0.01), Color(0.15, 0.13, 0.18), Vector3.ZERO, 6)
		"temari_ogi", "temari_ogi_1", "temari_ogi_2", "temari_ogi_3":
			_temari_fan(b, int(id.substr(11)) if id.length() > 10 else 0)
		"hakko_chakura_to":
			# Hakkō Chakura Tō (ref refs/weapons/hakko_*.png, Narutopedia: "düz bıçaklı tantō, küçük yuvarlak siperlik"):
			# düz siyah sap (sargı görünmez), kalın küçük yuvarlak grimsi-lavanta tsuba, aynı renkte kutu habaki,
			# düz tek ağızlı parlak gümüş bıçak (~32 cm), koyu metal kashira
			var lav = Color(0.56, 0.53, 0.62)
			var blk = Color(0.07, 0.07, 0.08)
			b.add("cyl", Vector3(0, 0, -0.055), Vector3(0.032, 0.15, 0.03), blk, Vector3(90, 0, 0), 12)          # sap (hafif oval)
			for k in 4:   # sapta belli belirsiz sargı çıkıntıları (çizimde düz siyah: çok koyu)
				b.add("cyl", Vector3(0, 0, -0.115 + k * 0.035), Vector3(0.034, 0.006, 0.032), Color(0.12, 0.12, 0.13), Vector3(90, 0, 0), 12)
			b.add("cyl", Vector3(0, 0, -0.135), Vector3(0.036, 0.016, 0.034), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 12)   # kashira
			b.add("cyl", Vector3(0, 0, 0.027), Vector3(0.066, 0.014, 0.066), lav, Vector3(90, 0, 0), 20)          # yuvarlak kalın tsuba
			b.add("torus", Vector3(0, 0, 0.027), Vector3(0.068, 0.016, 0.068), lav.darkened(0.25), Vector3(90, 0, 0), 20)
			b.add("box", Vector3(0, 0, 0.043), Vector3(0.012, 0.03, 0.022), lav.lightened(0.1))                   # habaki (bıçak bileziği)
			_w_blade(b, 0.035, 0.32, 0.024, 0.0, Color(0.86, 0.88, 0.94))                                           # düz parlak bıçak
		"katana":
			_w_tsuka(b, -0.2, 0.05, 0.017, dark)
			_w_tsuba(b, 0.065, 0.045, Color(0.2, 0.18, 0.16))
			_w_blade(b, 0.075, 0.72, 0.032, 0.035, steel)
		"musta":
			_musta(b)
		"tonfa":
			_tonfa(b)
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
		"zincirli_kunai", "zk_ucu":
			_zkunai(b)   # zincirlikunai.png (zincir CharacterModel'de fizikli; zk_ucu = zincirin ucundaki ikinci kunai)
		"altin_kunai", "patlayici_kunai":
			var bl = Color(0.85, 0.7, 0.3) if id == "altin_kunai" else steel
			b.add("cyl", Vector3(0, 0, -0.02), Vector3(0.022, 0.1, 0.022), wrap if id != "altin_kunai" else dark, Vector3(90, 0, 0), 6)
			b.add("torus", Vector3(0, 0, -0.085), Vector3(0.05, 0.05, 0.05), dark, Vector3(90, 0, 0), 8)
			b.add("sphere", Vector3(0, 0, 0.1), Vector3(0.05, 0.012, 0.17), bl, Vector3.ZERO, 6)
			if id == "patlayici_kunai":
				b.add("box", Vector3(0, 0.0, -0.02), Vector3(0.04, 0.03, 0.1), Color(0.95, 0.92, 0.82))
				b.add("box", Vector3(0, 0.016, -0.02), Vector3(0.012, 0.002, 0.07), Color(0.75, 0.1, 0.1))

		"senbon":
			# parmak aralarında yelpaze gibi dört uzun ince iğne: arka uçta küçük halka, uçlar sivri, hafif parlak çelik
			for k in 4:
				var a = (k - 1.5) * 9.0
				var rot = Basis(Vector3.UP, deg_to_rad(a))
				var o = rot * Vector3(0, 0, 0.0) + Vector3((k - 1.5) * 0.012, 0, 0)
				b.add_xf("cyl", Transform3D(rot * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(0.0045, 0.22, 0.0045)), o + rot * Vector3(0, 0, 0.08)), Color(0.86, 0.88, 0.92), 5)
				b.add_xf("cone", Transform3D(rot * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(0.0045, 0.03, 0.0045)), o + rot * Vector3(0, 0, 0.205)), Color(0.95, 0.96, 0.98), 5)
				b.add_xf("torus", Transform3D(rot * Basis.from_scale(Vector3(0.012, 0.012, 0.012)), o + rot * Vector3(0, 0, -0.035)), Color(0.55, 0.56, 0.6), 6)
		"ikiz_hancer":
			b.add("cyl", Vector3(0, 0, -0.03), Vector3(0.028, 0.11, 0.028), Color(0.35, 0.22, 0.15), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.03), Vector3(0.08, 0.02, 0.015), steel)
			b.add("box", Vector3(0, 0, 0.14), Vector3(0.01, 0.04, 0.2), steel)
			b.add("cone", Vector3(0, 0, 0.26), Vector3(0.01, 0.045, 0.04), steel, Vector3(90, 0, 0), 4)
		"kama":
			_orak(b)   # orak.png: uzun saplı kızıl-siyah tırpan orak
		"pence":
			_pence(b)   # claw.png
		"chakra_bicak":
			_trench_knife(b, false)
		"chakra_bicak_sol":
			_trench_knife(b, true)   # sol el: sağın aynası (bıçak yine serçe parmak ucundan)
		"ruzgar_bicak":
			pass   # tamamen chakradan: yarı saydam yüzeyler build sonrası (_wind_blade)
		"wakizashi":
			# kısa kavisli yan kılıç: ~52 cm hamonlu ağız, koyu lacivert sargılı tsuka, bronz oval tsuba
			_w_tsuka(b, -0.17, 0.04, 0.016, Color(0.1, 0.12, 0.22))
			_w_tsuba(b, 0.052, 0.036, Color(0.45, 0.33, 0.18))
			_w_blade(b, 0.062, 0.52, 0.03, 0.022, steel)
		"nodachi":
			_w_tsuka(b, -0.32, 0.06, 0.019, dark)
			_w_tsuba(b, 0.075, 0.055, Color(0.45, 0.36, 0.2))
			_w_blade(b, 0.085, 1.22, 0.042, 0.055, steel)
		"savas_cekici":
			_cekic(b)   # savascekici.png
		"yagura_sopa":
			# çiçekli büyük kancalı uç VURAN uç (+Z, elden uzak); ele yakın taraf küçük kancalı uç
			var yb = MB.new()
			_yagura(yb)
			b.add_mesh(yb, Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * 1.45), Vector3(0, 0, 0.8 * 1.45)))   # ~2.4 m (ölçek mesh'te: kın kelepçeleri doğru yerde)   # Y ekseninde çevir: büyük kanca + çiçek -Y'de kalır (vuran yüz)
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
			# Hanzō tipi kusarigama (sickle.png): uzun sap — dipten beyaz bölmeli sargı, üstü koyu mor; tepede mor başlık; başlığın
			# altından +Y'ye çıkıp hafif yükselip uca doğru aşağı kıvrılan uzun orak (koyu mor gövde, iç/alt kavisli kenar beyaz keskin).
			# Tutuş z=0 (sargının üst yarısı); zincir sap dibinden (z=-0.39) fizikli sarkar, ucunda çan ağırlık (_update_kchain).
			var pur = Color(0.2, 0.17, 0.29)
			var dpur = Color(0.11, 0.09, 0.17)
			var wr = Color(0.9, 0.9, 0.93)
			b.add("cyl", Vector3(0, 0, -0.35), Vector3(0.044, 0.03, 0.044), dpur, Vector3(90, 0, 0), 10)   # dip başlığı
			b.add("torus", Vector3(0, 0, -0.375), Vector3(0.028, 0.028, 0.028), dpur, Vector3(0, 0, 90), 8)   # zincir halkası
			b.add("cyl", Vector3(0, 0, -0.03), Vector3(0.036, 0.62, 0.036), wr, Vector3(90, 0, 0), 10)   # beyaz sargı (-0.34..0.28)
			for k in 9:   # sargı bölmeleri (resimdeki ince eğik çizgiler)
				b.add("cyl", Vector3(0, 0, -0.3 + k * 0.066), Vector3(0.0375, 0.005, 0.0375), Color(0.6, 0.6, 0.66), Vector3(90 + (12 if k % 2 == 0 else -12), 0, 0), 10)
			b.add("cyl", Vector3(0, 0, 0.5), Vector3(0.034, 0.44, 0.034), pur, Vector3(90, 0, 0), 8)   # mor üst sap (0.28..0.72)
			b.add("box", Vector3(0, 0.005, 0.72), Vector3(0.048, 0.07, 0.11), dpur)   # tepe başlığı (orak kökü)
			var p_out = Vector2(0.03, 0.765)
			var c_out = Vector2(0.4, 0.82)
			var tipq = Vector2(0.63, 0.58)
			var qb = func(a: Vector2, c: Vector2, e: Vector2, t: float) -> Vector2: return a * (1.0 - t) * (1.0 - t) + c * 2.0 * t * (1.0 - t) + e * t * t
			var NB = 24
			var outer = []
			var inner = []
			var midl = []
			for j in NB + 1:
				var t = float(j) / NB
				var q: Vector2 = qb.call(p_out, c_out, tipq, t)
				var tg: Vector2 = (qb.call(p_out, c_out, tipq, minf(1.0, t + 0.01)) - qb.call(p_out, c_out, tipq, maxf(0.0, t - 0.01))).normalized()
				var nrm = Vector2(-tg.y, tg.x)
				if nrm.y > 0.0:
					nrm = -nrm   # iç (kavisli) kenar: sapın dibine doğru
				var wd = 0.11 * pow(maxf(0.0, 1.0 - pow(t, 2.2)), 0.7)
				outer.append(q)
				inner.append(q + nrm * wd)
				midl.append(q + nrm * wd * 0.55)
			var body = PackedVector2Array()
			for j in NB + 1:
				body.append(midl[j])
			for j in range(NB - 1, -1, -1):
				body.append(outer[j])
			b.add_slab(body, 0.013, pur, Transform3D.IDENTITY, Callable(), dpur)
			var edge = PackedVector2Array()
			for j in NB + 1:
				edge.append(inner[j])
			for j in range(NB - 1, -1, -1):
				edge.append(midl[j])
			b.add_slab(edge, 0.007, wr, Transform3D.IDENTITY, Callable(), Color(0.72, 0.72, 0.78))   # beyaz keskin kenar (incelen)
		"el_shuriken":
			b.add("cyl", Vector3(0, 0, 0.1), Vector3(0.03, 0.4, 0.03), dark, Vector3(90, 0, 0), 8)   # sap göbeğe kadar
			_w_star(b, Vector3(0, 0, 0.3), 0.34, 0.17, 4, Color(0.5, 0.52, 0.56), dark)
		"kubikiribocho":
			var kb = MB.new()
			MistSwords.build(id, kb)
			b.add_mesh(kb, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.02), Vector3.ZERO))   # ağız ~1.9 m + sap (kullanıcı: büyüt)
		"kiba":
			var kb2 = MB.new()
			MistSwords.build(id, kb2)
			b.add_mesh(kb2, Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.11)))   # el sapın ortasında (tsuba yumruğun önünde)
		"samehada", "samehada_acik", "hiramekarei", "hiramekarei_yari", "shibuki", "nuibari", "kabutowari", "kabutowari_cekic":
			MistSwords.build(id, b)   # Sis'in Yedi Kılıcı: referansla modellendi
		"chokuto":
			b.add("cyl", Vector3(0, 0, -0.08), Vector3(0.032, 0.22, 0.032), Color(0.85, 0.85, 0.85), Vector3(90, 0, 0), 8)
			b.add("box", Vector3(0, 0, 0.04), Vector3(0.05, 0.05, 0.02), dark)
			b.add("box", Vector3(0, 0, 0.5), Vector3(0.012, 0.03, 0.88), Color(0.85, 0.87, 0.9))
			b.add("cone", Vector3(0, 0, 0.97), Vector3(0.012, 0.06, 0.03), Color(0.85, 0.87, 0.9), Vector3(90, 0, 0), 4)
		"raijin":
			# Raijin no Ken (kaynak raijinornek.png): yalnız kabza — koyu gri-mor sap, ucunda yarıklı halka topuz, kısa bilezik,
			# kabzanın önünde yana kıvrılan hilal kanca muhafız. Ağız: kabzadan çıkan uzun sarı-yeşil ışın (ayrı parlayan düğüm).
			# kaynak duzeltknk.png: düz, hafif şişkin koyu gri sap (halka yok); dipte yassı üçgen delikli halka topuz;
			# önde bilezik ve bilezikten yukarı kalkıp ele doğru geri kıvrılan C kanca muhafız
			var hilt = Color(0.36, 0.36, 0.42)
			var dk2 = Color(0.22, 0.22, 0.27)
			b.add("cyl", Vector3(0, 0, -0.075), Vector3(0.036, 0.15, 0.036), hilt, Vector3(90, 0, 0), 12)
			b.add("sphere", Vector3(0, 0, -0.08), Vector3(0.042, 0.042, 0.09), hilt, Vector3.ZERO, 12)   # hafif şişkin tutma yeri
			b.add("cyl", Vector3(0, 0, -0.16), Vector3(0.03, 0.03, 0.03), dk2, Vector3(90, 0, 0), 10)
			# yassı üçgen halka topuz (yan yüzü dışa)
			var tri = PackedVector2Array([Vector2(-0.032, -0.165), Vector2(0.032, -0.165), Vector2(0.0, -0.225)])
			var hole = PackedVector2Array([Vector2(-0.016, -0.175), Vector2(0.016, -0.175), Vector2(0.0, -0.208)])
			b.add_slab(tri, 0.018, dk2)
			b.add_slab(hole, 0.022, Color(0.06, 0.06, 0.07))
			b.add("cyl", Vector3(0, 0, 0.012), Vector3(0.05, 0.035, 0.05), dk2, Vector3(90, 0, 0), 12)   # bilezik
			# C kanca muhafız: bilezikten +Y'ye kalkıp ele (-Z) doğru kıvrılan yay
			for k in 28:   # sık, üst üste binen parçalar: tek parça düzgün kanca (tespih gibi boncuklu değil)
				var t = k / 27.0
				var ang = lerpf(0.0, PI * 1.15, t)
				var r = 0.055
				var q = Vector3(0, sin(ang) * r + 0.012, 0.03 - (1.0 - cos(ang)) * r * 0.5 - t * 0.02)
				b.add("sphere", q, Vector3(0.02, 0.02, 0.02) * (1.0 - t * 0.35), dk2, Vector3.ZERO, 8)
			b.add("cyl", Vector3(0, 0, 0.04), Vector3(0.03, 0.025, 0.03), Color(0.95, 0.85, 0.4), Vector3(90, 0, 0), 10)   # ışın çıkış ağzı
		"fuma_shuriken":
			_fuma(b, false)   # fuumashuriken.png / acilmishali.png: halka göbek + 4 kavisli orak bıçak (açık)
		"fuma_kapali":
			_fuma(b, true)    # acilmamishaliholster.png: bıçaklar yelpaze gibi üst üste kapalı (kında)
		"kyodai_shuriken":
			_kyodai(b)        # fumavaryasyon.png: insandan büyük düz kenarlı dört köşeli yıldız
		"fuma_kare":
			_fuma_kare(b)     # fumavaryasyon2.png: ortası delik, açık çerçeveli kare shuriken (parşömenden çağrılır)
		"fuma_makimono":
			_makimono(b)      # çağırma parşömeni (elde/sırtta)
		"sai", "sai_sol":
			_sai(b)   # sai.png
		"hiraishin_kunai":
			_hiraishin_kunai(b)   # raijinbaba.png
		"homatsu_kiseru":
			_kiseru(b)   # utakatababa.png
		"kusanagi":
			_kusanagi(b)   # orochikusanagi.png
		"uc_tirpan":
			# üç bıçaklı kızıl tırpan (kaynak tirpan.png, ölçüler resimden metreye): tutuş z=0 (sağ yumruk sargının alt kısmında),
			# pommel z=-0.16; beyaz bez sargı -> kırmızı sap -> siyah boğaz -> üç beyaz bilezik (arkalarında koyu kırmızı takoz),
			# her bilezikten +Y yönüne çıkıp sapa doğru geri kıvrılan hilal bıçak (aşağı doğru büyür); dış kavisli kenar beyaz
			var o = -0.16
			var red = Color(0.5, 0.06, 0.07)
			var dred = Color(0.32, 0.03, 0.04)
			var wrapc = Color(0.9, 0.88, 0.84)
			var blk = Color(0.06, 0.05, 0.05)
			var edge = Color(0.93, 0.93, 0.91)
			b.add("cyl", Vector3(0, 0, o + 0.015), Vector3(0.05, 0.035, 0.05), red, Vector3(90, 0, 0), 10)   # pommel
			b.add("cyl", Vector3(0, 0, o + 0.31), Vector3(0.042, 0.56, 0.042), wrapc, Vector3(90, 0, 0), 10)   # sargı
			for k in 9:   # sargı sarımları (ince eğik çizgiler)
				b.add("cyl", Vector3(0, 0, o + 0.08 + k * 0.058), Vector3(0.0436, 0.004, 0.0436), Color(0.5, 0.48, 0.46), Vector3(90 + 16, 0, 0), 10)
			b.add("cyl", Vector3(0, 0, o + 0.875), Vector3(0.04, 0.57, 0.04), red, Vector3(90, 0, 0), 8)   # kırmızı sap
			b.add("cyl", Vector3(0, 0, o + 1.605), Vector3(0.04, 0.89, 0.04), blk, Vector3(90, 0, 0), 8)    # siyah boğaz + bilezik arası
			b.add("cyl", Vector3(0, 0, o + 2.065), Vector3(0.044, 0.04, 0.044), red, Vector3(90, 0, 0), 8)    # alt uç başlığı
			# [bilezik üst z, bilezik alt z, uç y, uç z] (pommelden metre)
			var BL = [[1.27, 1.47, 0.60, 0.92], [1.53, 1.73, 0.80, 1.15], [1.80, 2.03, 1.02, 1.39]]
			for bl in BL:
				var za = o + float(bl[0]); var zb = o + float(bl[1])
				var tip = Vector2(float(bl[2]), o + float(bl[3]))
				b.add("box", Vector3(0, 0, (za + zb) * 0.5), Vector3(0.052, 0.062, zb - za), wrapc)    # beyaz bilezik
				b.add("box", Vector3(0, -0.05, (za + zb) * 0.5 + 0.01), Vector3(0.034, 0.04, (zb - za) * 0.85), dred)   # arka takoz
				# hilal şerit (resim): dış (beyaz) kenar bilezik altından sapa dik çıkıp uca doğru sapa geri kıvrılır;
				# iç kenar dış kenara paralel kayar — kalınlık kökte bilezik boyu, ortada ~%75, uçta sivri
				var p_out = Vector2(0.03, zb - 0.01)
				var c_out = Vector2(0.46 * tip.x, zb + 0.005)
				var qb = func(a: Vector2, c: Vector2, e: Vector2, t: float) -> Vector2: return a * (1.0 - t) * (1.0 - t) + c * 2.0 * t * (1.0 - t) + e * t * t
				var N = 22
				var W0 = (zb - za) - 0.01
				var outer = []
				var inner = []
				for j in N + 1:
					var t = float(j) / N
					var q: Vector2 = qb.call(p_out, c_out, tip, t)
					var tg: Vector2 = (qb.call(p_out, c_out, tip, minf(1.0, t + 0.01)) - qb.call(p_out, c_out, tip, maxf(0.0, t - 0.01))).normalized()
					var nrm = Vector2(-tg.y, tg.x)
					if nrm.y > 0.0:
						nrm = -nrm   # sapın tutuş tarafına (-z) doğru
					outer.append(q)
					inner.append(q + nrm * W0 * pow(maxf(0.0, 1.0 - pow(t, 2.4)), 0.75))
				var body = PackedVector2Array()
				for j in N + 1:
					body.append(inner[j])
				for j in range(N - 1, -1, -1):
					body.append(outer[j])
				b.add_slab(body, 0.014, Color(0.42, 0.05, 0.06), Transform3D.IDENTITY, Callable(), dred)
				# beyaz keskin dış kenar: dış eğri boyunca içe doğru incelen şerit (gövdeden biraz kalın: iki yüzde de görünür)
				var strip = PackedVector2Array()
				var ins = []
				for j in N:
					var t = float(j) / N
					var w = minf(0.04 * (1.0 - t * 0.6), (inner[j] - outer[j]).length() * 0.3)
					ins.append(outer[j] + (inner[j] - outer[j]).normalized() * w)
				for j in N:
					strip.append(outer[j])
				strip.append(tip)
				for j in range(N - 1, -1, -1):
					strip.append(ins[j])
				b.add_slab(strip, 0.018, edge, Transform3D.IDENTITY, Callable(), Color(0.8, 0.8, 0.78))
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
			# göbek: eski beyaz göbek boyunda halka, ortası DELİK (deliğin arkasındaki gök mavi diye mavi disk yapılmıştı)
			b.add("torus", H, Vector3(0.15, 0.15, 0.15), white, Vector3(0, 0, 90), 20)
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
	if id == "shibuki":
		MistSwords.shibuki_tags(m)   # mühür kâğıtlı rulo: dokulu ayrı yüzey
	if id == "ruzgar_bicak":
		_wind_blade(m)   # rüzgar chakrasından bıçak: yarı saydam
	_weapon_cache[id] = m
	return m


## Kunai (kaynak ornekkunai.png): baklava kesitli yaprak bıçak (dört yüz: üst yüzler açık çelik, alt yüzler koyu — anime ışığı),
## orta sırt çizgisi, kısa boyun; sıkı sarılı koyu gri sap (boğumlu sargı), sonda kalın halka. Kabza 0, uç +Z, yassı yüz ±X.
## Raijin ışın ağzı: kabzadan +Z boyunca uzun, ince, uca doğru incelen sarı-yeşil ışın; beyaz parlak öz + yarı saydam hale
static func _raijin_beam() -> Node3D:
	var root = Node3D.new()
	root.name = "RaijinBeam"
	var L = 1.45
	for layer in [[0.016, 0.006, Color(1.0, 0.98, 0.8), 1.0], [0.045, 0.012, Color(1.0, 0.85, 0.1), 0.45], [0.085, 0.02, Color(1.0, 0.78, 0.05), 0.16]]:   # sapsarı
		var cm = CylinderMesh.new()
		cm.bottom_radius = layer[0]
		cm.top_radius = layer[1]
		cm.height = L
		cm.radial_segments = 10
		cm.rings = 1
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(layer[2], layer[3])
		m.emission_enabled = true
		m.emission = layer[2]
		m.emission_energy_multiplier = 2.0
		if layer[3] < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		cm.material = m
		var mi = MeshInstance3D.new()
		mi.mesh = cm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.rotation_degrees = Vector3(90, 0, 0)
		mi.position = Vector3(0, 0, 0.04 + L * 0.5)   # ışın çıkış ağzına yapışık
		root.add_child(mi)
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.3)
	light.light_energy = 0.8
	light.omni_range = 2.5
	light.position = Vector3(0, 0, 0.6)
	root.add_child(light)
	return root


static func _kunai_mesh(b: MB) -> void:
	var lite = Color(0.86, 0.88, 0.92)
	var mid = Color(0.58, 0.6, 0.65)
	var shade = Color(0.2, 0.21, 0.24)
	var z0 = 0.075; var zw = 0.125; var z1 = 0.285
	var w = 0.046; var t = 0.011
	var P = {"b": Vector3(0, 0, z0), "tip": Vector3(0, 0, z1), "u": Vector3(0, w, zw), "d": Vector3(0, -w, zw), "l": Vector3(t, 0, zw), "r": Vector3(-t, 0, zw)}
	var tri = func(a: Vector3, bb: Vector3, c: Vector3, col: Color):
		var n = (bb - a).cross(c - a).normalized()
		var base = b.verts.size()
		for q in [a, bb, c]:
			b.verts.append(q); b.normals.append(n); b.colors.append(col); b.uvs.append(Vector2.ZERO)
		b.idx.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 1]))
	# ön (+x) ve arka (-x) yüzler: üst yarı açık, alt yarı koyu; taban (kısa) ve uç (uzun) bölümleri
	for side in ["l", "r"]:
		var c_hi = lite if side == "l" else mid
		var c_lo = shade
		tri.call(P["tip"], P["u"], P[side], c_hi)
		tri.call(P["tip"], P[side], P["d"], c_lo)
		tri.call(P["b"], P["u"], P[side], c_hi.darkened(0.12))
		tri.call(P["b"], P[side], P["d"], c_lo.lightened(0.08))
	# boyun + sap (boğumlu sargı) + halka
	var grip = Color(0.25, 0.25, 0.28)
	b.add("cyl", Vector3(0, 0, 0.068), Vector3(0.022, 0.018, 0.022), mid, Vector3(90, 0, 0), 8)
	b.add("cyl", Vector3(0, 0, 0.0), Vector3(0.024, 0.12, 0.024), grip, Vector3(90, 0, 0), 8)
	for k in 7:
		b.add("torus", Vector3(0, 0, -0.05 + k * 0.016), Vector3(0.03, 0.022, 0.03), grip.lightened(0.12 if k % 2 == 0 else 0.0), Vector3(90, 0, 0), 8)
	b.add("torus", Vector3(0, 0, -0.088), Vector3(0.062, 0.05, 0.062), grip.darkened(0.15), Vector3(0, 90, 0), 12)


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
## Bekleme yönü model uzayında: [ağız yönü (+Z ön, +X karakterin solu), kalınlık ekseni ipucu]
const REST_DIR := {"kubikiribocho": [Vector3(-0.12, 0.42, -0.9), Vector3(-1, 0, 0)]}
static var REST_TILT_OF := {"samehada": Vector3(0, 0, 0), "gunbai": Vector3(0, 0, 0), "uc_tirpan": Vector3(0, 0, -164), "shibuki": Vector3(0, 0, 171.6), "kabutowari": Vector3(0, 0, 112.1)}   # tırpan: yalnız sap ekseni etrafında (bıçaklar sırtın arkasında aşağı sarkar), sap yönü kol pozundan   # gunbai: silah yumruğun içinden düz geçer; yönü kol pozu verir (w_gunbai)   # silaha özel bekleme eğimi (kafanın içinden geçmesin)
const REST_TILT := Vector3(-25.0, -55.0, 0.0)
const IDLE_GRIP := {"samehada": 0.3}
## kalın saplar: kabza avucun derinine (parmaklar sarabilsin; eskiden sap parmakların önünden geçiyordu) — tutucu uzayında
const GRIP_OFF := {"samehada": Vector3(0.025, 0, 0)}


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
		if REST_DIR.has(w["id"]) and on:
			# model uzayında sabit bekleme yönü (Kubikiribōchō omuzda: ağız geriye-yukarı, yassı yüz yana, sırtı omuzda)
			var rd: Array = REST_DIR[w["id"]]
			var want_g: Basis = (skel.global_transform.basis * FLIP.basis.inverse()).orthonormalized() * _frame(rd[0], rd[1])   # model uzayı (_grest) -> dünya
			var par_g: Basis = (n.get_parent() as Node3D).global_transform.basis.orthonormalized()
			var tq = (par_g.inverse() * want_g).get_rotation_quaternion()
			var q2 = n.transform.basis.get_rotation_quaternion().slerp(tq, minf(1.0, dt * 8.0))
			n.transform.basis = Basis(q2).scaled(n.transform.basis.get_scale())
			n.position = GRIP_OFF.get(w["id"], Vector3.ZERO)
			continue
		var rt: Vector3 = REST_TILT_OF.get(w["id"], REST_TILT)
		var tgt = Basis.from_euler(Vector3(deg_to_rad(rt.x), deg_to_rad(rt.y * sx), deg_to_rad(rt.z * sx))) if on else Basis.IDENTITY
		var cur_q = n.transform.basis.get_rotation_quaternion()
		var q = cur_q.slerp(tgt.get_rotation_quaternion(), minf(1.0, dt * (6.0 if on else 14.0)))
		n.transform.basis = Basis(q).scaled(n.transform.basis.get_scale())
		# bekleme tutuşu sapın ortasından (Samehada: kabza-gövde birleşimindeki disk eli kapatıyordu)
		n.position = GRIP_OFF.get(w["id"], Vector3.ZERO) + n.transform.basis.z.normalized() * float(IDLE_GRIP.get(w["id"], 0.0)) * n.transform.basis.get_scale().z


## anahtar animasyonlu silahlar: [tutuş kaydırma (yumruk sap boyunca ileri), iz başı z, iz ucu z, elden uca boy]
const KEY_WEAPON := {"temari_ogi": [0.0, 0.3, 1.4, 1.45], "samehada": [0.58, 0.45, 1.9, 1.95], "gunbai": [0.0, 0.85, 2.3, 2.4], "kunai": [0.0, 0.08, 0.3, 0.3], "raijin": [0.0, 0.1, 1.5, 1.5], "uc_tirpan": [0.0, 1.1, 1.95, 1.92], "shibuki": [0.0, 0.45, 1.3, 1.45], "kabutowari": [0.0, 0.3, 0.82, 0.85], "ruzgar_bicak": [0.0, 0.1, 0.6, 0.62], "hiraishin_kunai": [0.0, 0.14, 0.47, 0.48], "homatsu_kiseru": [0.1, 0.5, 0.72, 0.72], "kusanagi": [0.0, 0.21, 1.08, 1.09], "kusarigama": [0.0, 0.3, 0.8, 0.85], "fuma_shuriken": [0.0, 0.05, 0.6, 0.62], "kyodai_shuriken": [0.0, 0.1, 1.3, 1.3], "fuma_makimono": [0.0, 0.05, 0.25, 0.26], "nuibari": [0.0, 0.1, 1.62, 1.62], "savas_cekici": [0.0, 1.1, 1.58, 1.58], "zincirli_kunai": [0.0, 0.06, 0.38, 0.38], "bashosen": [0.0, 0.55, 1.4, 1.45], "kubikiribocho": [0.0, 0.3, 1.9, 1.9], "yagura_sopa": [0.0, 0.87, 1.77, 1.8], "kongo_asa": [0.0, 0.6, 1.25, 1.26], "yelpaze": [0.0, 0.2, 0.6, 0.62], "kama": [0.0, 1.0, 1.62, 1.64], "pence": [0.0, 0.1, 0.48, 0.48], "senbon": [0.0, 0.05, 0.22, 0.22], "hiramekarei": [0.0, 0.3, 1.3, 1.33], "bo": [0.0, 0.4, 0.95, 0.95], "kiba": [0.0, 0.2, 1.11, 1.15]}   # uzunluklar silahın kendi ölçeğiyle çarpılır


static var _kp_cache := {}


## Silahın iz/boy değerleri: tabloda varsa o, yoksa modelin kendi ölçüsünden (bıçak ucu = mesh'in +z sonu, iz başı = ucun %15'i).
## Eskiden tabloda olmayan her silah (wakizashi, katana, tantō, nodachi, chokutō, sai, muşta...) 0.5-1.8 m iz alıyordu:
## iz kılıca denk gelmiyor, ucundan taşıyordu.
static func weapon_kp(id: String, node: Node3D) -> Array:
	if KEY_WEAPON.has(id):
		return KEY_WEAPON[id]
	if _kp_cache.has(id):
		return _kp_cache[id]
	var end_z = 0.0
	var mis: Array = [node] if node is MeshInstance3D else node.find_children("*", "MeshInstance3D", true, false)
	for mi in mis:
		if (mi as MeshInstance3D).mesh:
			end_z = maxf(end_z, (mi as MeshInstance3D).mesh.get_aabb().end.z)
	if end_z <= 0.02:
		return [0.0, 0.5, 1.8, 2.0]
	var kp = [0.0, end_z * 0.15, end_z, end_z]
	_kp_cache[id] = kp
	return kp


var _edge_x := Vector3.ZERO   # gunbai: kenar önde savuruş için yüz normali (yumuşatılmış)


## Sol eldeki silahın ucunu ön kolun doğrultusuna (hafif yukarı) çevir: bilek döner, silah avuçta sabit kalır
func _left_follow_forearm(sk: Skeleton3D, w: Dictionary) -> void:
	var hb = sk.find_bone("LeftHand")
	var lb = sk.find_bone("LeftLowerArm")
	if hb < 0 or lb < 0:
		return
	var hp: Transform3D = sk.get_bone_global_pose(hb)
	var fore: Vector3 = (hp.origin - sk.get_bone_global_pose(lb).origin).normalized()
	var want = (fore + Vector3(0, 0.12, 0)).normalized()
	var holder: Node3D = w["hand"]
	var n: Node3D = w["node"]
	var pb: Basis = (hp.basis * holder.transform.basis * n.transform.basis).orthonormalized()
	var qh = Quaternion(pb.z.normalized(), want)
	var par = sk.get_bone_parent(hb)
	var parb: Basis = sk.get_bone_global_pose(par).basis if par >= 0 else Basis.IDENTITY
	sk.set_bone_pose_rotation(hb, (parb.inverse() * (Basis(qh) * hp.basis)).get_rotation_quaternion())


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
	for w0 in weapons:
		if w0["id"] in ["chakra_bicak", "pence"]:
			return   # muşta bıçak / pençe: yumruğa bağlı, bilek silaha göre çevrilmez (kol pozları yeter; pençenin ucu +x,
			# kılıç gibi +z'yi "blade"e çevirmek sağ eldeki pençeyi yan yatırıyordu, sol el hiç çevrilmiyordu)
		if w0["id"] == "sai_sol" and n_in_hand(w0):
			_left_follow_forearm(sk, w0)   # sol sai: ucu ön kol doğrultusunda (yumruk nereye uzanırsa oraya saplar)
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
			w["key_pos0"] = GRIP_OFF.get(w["id"], Vector3.ZERO)   # bekleme tutuş kaydırması anahtar animasyona taşınmasın
		if not w.has("trail") and is_inside_tree():
			var tr = SwordTrail.new()
			tr.node = n
			var kp0: Array = weapon_kp(String(w["id"]), n)
			tr.z0 = kp0[1]
			tr.z1 = kp0[2]
			get_tree().current_scene.add_child(tr)
			w["trail"] = tr
		var kp: Array = weapon_kp(String(w["id"]), n)   # [tutuş kaydırma, iz başı, iz ucu, boy]
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
		# EL SİLAHA UYAR: bileği, tutuş ekseni (avucun içinden geçen kabza ekseni) silahın yönüne gelecek kadar döndür.
		# Silah avuçta hep aynı yerde kalır (parmak ucuyla tutar gibi görünmez); kalan küçük fark silahta düzeltilir.
		var cur_z: Vector3 = pb.z
		var qh = Quaternion(cur_z.normalized(), z)
		var hpar = sk.get_bone_parent(hb)
		var parb: Basis = sk.get_bone_global_pose(hpar).basis if hpar >= 0 else Basis.IDENTITY
		var new_g: Basis = Basis(qh) * hp.basis
		sk.set_bone_pose_rotation(hb, (parb.inverse() * new_g).get_rotation_quaternion())
		hp = sk.get_bone_global_pose(hb)
		pb = (hp.basis * holder.transform.basis).orthonormalized()
		var x = Vector3.UP.cross(z)
		if x.length() < 0.1:
			x = Vector3.RIGHT
		x = x.normalized()
		if w["id"] == "gunbai" and overlay.key_roll < 45.0:
			# kenar önde: yüz normali savuruş düzlemine dik (yassı yüzle değil kenarla/köşeyle çarpar)
			var vel: Vector3 = overlay._key_bv
			var ex = z.cross(vel)
			if vel.length() > 1.5 and ex.length() > 0.05:
				if _edge_x != Vector3.ZERO and ex.dot(_edge_x) < 0.0:
					ex = -ex   # kenar düzlemi aynı; işaret dönünce 180° dönmesin
				_edge_x = _edge_x.slerp(ex.normalized(), 0.35) if _edge_x != Vector3.ZERO else ex.normalized()
			if _edge_x != Vector3.ZERO:
				x = (_edge_x - z * _edge_x.dot(z)).normalized()
		if w["id"] in ["uc_tirpan", "kusarigama"]:
			# tırpan / kusarigama: bıçak tarafı (+Y) savuruş yönünde önde — keskin beyaz dış kenar keser; sap ekseni etrafında hıza göre döner
			var tv: Vector3 = overlay._key_bv
			var tx = tv.cross(z)
			if tv.length() > 1.0 and tx.length() > 0.05:
				_edge_x = _edge_x.slerp(tx.normalized(), 0.3).normalized() if _edge_x != Vector3.ZERO and _edge_x.dot(tx.normalized()) > -0.9 else tx.normalized()
			var px = _edge_x - z * _edge_x.dot(z)
			if px.length() > 0.05:
				x = px.normalized()
		if w["id"] in ["shibuki", "kubikiribocho", "yagura_sopa", "kama"]:   # kubikiri: keskin kenar da -Y; yagura: büyük kanca + çiçek -Y
			# Shibuki: AĞIZ kenarı (kâğıtlı geniş taraf, silah -Y) savuruş yönünde önde — kılıç gibi kenarla vurur.
			# -Y hız yönünde => x = z × hız (dikey bileşen)
			var sv: Vector3 = overlay._key_bv
			var sp = sv - z * sv.dot(z)
			if sp.length() > 1.0:
				var ex = z.cross(sp.normalized()).normalized()
				_edge_x = _edge_x.slerp(ex, 0.3).normalized() if _edge_x != Vector3.ZERO and _edge_x.dot(ex) > -0.9 else ex
			var sx2 = _edge_x - z * _edge_x.dot(z)
			if sx2.length() > 0.05:
				x = sx2.normalized()
		var want = Basis(x, z.cross(x).normalized(), z)
		if overlay.key_roll != 0.0:
			want = want * Basis(Vector3.BACK, deg_to_rad(overlay.key_roll))   # sap ekseni etrafında (gunbai yüzü rakibe)
		var q = (pb.inverse() * want).get_rotation_quaternion()
		n.transform.basis = Basis(q).scaled(sc)
		n.position = w["key_pos0"] + n.transform.basis.z.normalized() * grip


func n_in_hand(w: Dictionary) -> bool:
	return is_instance_valid(w["node"]) and (w["node"] as Node3D).get_parent() == w["hand"]


func flash(amount: float) -> void:
	hit_flash = maxf(hit_flash, amount)


## Darbe tepkisi (dünya yönünde itiş): poz katmanında gövde/kafa savrulur
func react(world_dir: Vector3, amp: float, head := false, up := 0.0, heavy := 0.0) -> void:
	if overlay == null:
		return
	var d = global_transform.basis.inverse() * world_dir
	overlay.hit_react(d, amp, head, up, heavy)
	dangle_kick(world_dir.normalized() * (1.5 + amp * 3.0 + heavy * 4.0) + Vector3.UP * up * 2.0)


const STANCE_ID := {"samehada": "w_samehada", "gunbai": "w_gunbai", "raijin": "w_raijin", "uc_tirpan": "w_tirpan", "shibuki": "w_shibuki", "kabutowari": "w_kabuto", "ruzgar_bicak": "w_ruzgar", "kusanagi": "w_kusa", "kusarigama": "w_kgama", "kubikiribocho": "w_kubi"}
## bekleme duruşunda iki elle tutulan silahlar: sol el IK ile kabzaya, sağ elin altına (kabza ekseninde -Z)
static var TWO_HAND_IDLE := {"raijin": -0.1, "shibuki": 0.2}   # shibuki: sağ el sapın arka ucunda, sol el 0.2 önde (taramada sapa 4 mm oturdu)   # silaha özel duruş
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
	if anim:
		var tc = _time_comp()
		if absf(anim.speed_scale - _anim_speed * tc) > 0.001:
			anim.speed_scale = _anim_speed * tc
		if overlay:
			overlay.time_comp = tc
	# silah duruşu: beklerken/yürürken silaha göre kollar; saldırı, mühür ve ninja koşusunda kapanır
	_weapon_process(dt)
	if stance != "" and overlay:
		var on = drawn and not _stowed and overlay.key_t < 0.0 and current in ["idle", "walk", "jog", "run", "air", "fall", "sword_idle"] and overlay.weights.get("ninja_run", 0.0) < 0.5 and overlay.weights.get("leap", 0.0) < 0.3
		overlay.set_pose(stance, 1.0 if on else 0.0)
		if rig:
			var th = null
			for w in weapons:
				if w["side"] == "Right" and TWO_HAND_IDLE.has(w["id"]) and n_in_hand(w):
					th = w
			if th != null:
				rig.two_hand_node = th["node"]
				rig.two_hand_off = float(TWO_HAND_IDLE[th["id"]])
				rig.two_hand_w = move_toward(rig.two_hand_w, overlay.weights.get(stance, 0.0), dt * 8.0)
		if overlay.key_t < 0.0:
			_rest_tilt(on, dt)
	_key_blade()
	_dangle_process(dt)
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - dt * 5.0)
		for m in materials:
			m.set_shader_parameter("hit_flash", hit_flash)
