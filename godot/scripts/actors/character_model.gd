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
	_paint_body()
	_cloth_details()
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


# ------------------------------------------------------------------ kıyafet (vücuttan türetilen kumaş katmanları)
## Bölge kodları: 0 ten, 10 omuz/üst kol, 11 göğüs, 12 bel, 13 ön kol, 14 bilek,
## 20 kalça, 21 uyluk, 22 baldır, 23 baldır altı, 30 ayak, 40 boyun
## Renk yuvaları (vertex COLOR.r = yuva * 0.1, toon shader palette_mode): 0 ten, 1 üst, 2 üst-vurgu, 3 alt, 4 sargı, 5 yelek
const TOP_STYLES := {"tisort": "Kısa Kollu Tişört", "uzun": "Uzun Kollu Ninja Gömleği", "ceket": "Fermuarlı Ceket", "yakali": "Yüksek Yakalı Gömlek"}
const PANTS_STYLES := {"ninja": "Ninja Pantolonu", "sort": "Diz Altı Şort", "sivil": "Uzun Pantolon"}

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
	# kalça/kalça arkası: süper kahraman modelinin iri kalçasını küçült (geriye taşma ve genişlik)
	var hb = skel.find_bone("Hips")
	var hp = skel.get_bone_global_rest(hb).origin if hb >= 0 else Vector3(0, 0.95, -0.04)
	for i in v.size():
		var q = v[i]
		if absf(q.x) > 0.3:
			continue
		var w = 1.0 - clampf(absf(q.y - (hp.y - 0.08)) / 0.26, 0.0, 1.0)
		w = w * w * (3.0 - 2.0 * w)
		if w <= 0.0:
			continue
		if q.z < hp.z:
			q.z = hp.z + (q.z - hp.z) * (1.0 - 0.45 * w)
		q.x *= 1.0 - 0.1 * w
		v[i] = q
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
	var g = {"arrays": arr, "regions": regions, "weld": weld, "wpos": wpos, "wadj": wadj, "wnrm": wnrm, "per": per, "tex": src_tex}
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
	return PackedColorArray([Color(L["skin"]), Color(L["top"]), Color(L["top2"]), Color(L["pants"]), Color(L["wraps"]), Color(vest), Color(L["sandal"]), Color(0.12, 0.1, 0.1)])


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
	var bp = func(n: String) -> Vector3: return skel.get_bone_global_rest(skel.find_bone(n)).origin
	mat.set_shader_parameter("rig_a", Vector4(bp.call("LeftUpperArm").x, bp.call("LeftLowerArm").x, bp.call("LeftHand").x, bp.call("Neck").y))
	mat.set_shader_parameter("rig_b", Vector4(bp.call("Hips").y, bp.call("LeftLowerLeg").y, bp.call("LeftFoot").y, bp.call("UpperChest").y))
	if g["tex"]:
		mat.set_shader_parameter("tex", g["tex"])
	mat.set_shader_parameter("tint", Color(look["skin"]))
	var f = look.get("face")
	if f is String:
		f = FACES.get(f, FACES["normal"])
	if not f is Array or f.size() < 5:
		f = random_face()
		look["face"] = f
	mat.set_shader_parameter("face_a", Vector4(f[0], f[1], f[2], f[3]))
	mat.set_shader_parameter("face_b", Vector4(f[4], FACE_MARKS.get(look.get("face_mark", "yok"), 0), 0, 0))
	if eyes_mesh:
		var ec = eyes_mesh.get_aabb().get_center()
		mat.set_shader_parameter("face_ref", Vector4(0, ec.y, ec.z, 0))
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
	body_mesh.set_surface_override_material(0, _cloth_mat(0))
	var shell_mat = _cloth_mat(1)
	_add_shell(_shell_cache[key], shell_mat)
	var vest_mat = null
	if look["vest"] != null:
		vest_mat = _cloth_mat(2)
		_add_shell(_shell_cache[key + "|vest"], vest_mat)
	_cloth_rings(g, shell_mat, vest_mat)


## Kollarda manşet, belde gömlek eteği, paçada büzgü: kıyafete gerçek kalınlık/katman verir
static var _ring_cache := {}
func _cloth_rings(g: Dictionary, mat: ShaderMaterial, vest_mat) -> void:
	var bp = func(n: String) -> Vector3: return skel.get_bone_global_rest(skel.find_bone(n)).origin
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
static func _ring_mesh(g: Dictionary, axis: int, value: float, side: float, extra: float, thick: float, shift: Vector3, neck_y: float) -> ArrayMesh:
	var wpos: PackedVector3Array = g["wpos"]
	var pts = []
	for p in wpos:
		if absf(p[axis] - value) > 0.012:
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
	var ub = Vector3.BACK
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
	var normal_axis = Vector3.RIGHT if axis == 0 else Vector3.UP
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


## Sandalet (açık burunlu taban + kayışlar), yaka, fermuar, bel bağı
func _cloth_details() -> void:
	var ts = top_style()
	var sc: Color = look["sandal"]
	for side in ["Left", "Right"]:
		var fb = skel.find_bone(side + "Foot")
		var tb = skel.find_bone(side + "Toes")
		if fb < 0:
			continue
		var fp = skel.get_bone_global_rest(fb).origin
		var tp = skel.get_bone_global_rest(tb).origin if tb >= 0 else fp + Vector3(0, -0.06, 0.12)
		var fwd = Vector3(tp.x - fp.x, 0, tp.z - fp.z).normalized()
		var yaw = atan2(fwd.x, fwd.z)
		var s = MB.new()
		var heel = Vector3(fp.x, 0.012, fp.z) - fwd * 0.06
		var sole_len = (Vector2(tp.x, tp.z) - Vector2(heel.x, heel.z)).length() + 0.07
		var mid = heel + fwd * sole_len * 0.5
		var bs = Basis(Vector3.UP, yaw)
		s.add_xf("box", Transform3D(bs * Basis.from_scale(Vector3(0.095, 0.022, sole_len)), mid), sc.darkened(0.25))
		# üst kayışlar: ayak üstü + bilek arkası
		s.add_xf("box", Transform3D(bs * Basis.from_scale(Vector3(0.1, 0.03, 0.045)), Vector3(fp.x, 0.055, fp.z) + fwd * 0.07), sc)
		s.add_xf("box", Transform3D(bs * Basis.from_scale(Vector3(0.09, 0.075, 0.03)), Vector3(fp.x, 0.06, fp.z) - fwd * 0.055), sc)
		_mesh_on(side + "Foot", s.build(Props.toon()), Transform3D.IDENTITY)
	var neck = skel.find_bone("Neck")
	if neck >= 0 and ts in ["yakali", "ceket"] and look["vest"] == null:
		var np = skel.get_bone_global_rest(neck).origin
		var c = MB.new()
		var cc: Color = look["top"] if ts == "yakali" else look["top2"]
		c.add("cyl", Vector3(0, 0.035, 0.0), Vector3(0.15, 0.12, 0.15), cc, Vector3.ZERO, 16)
		if ts == "ceket":
			c.add("box", Vector3(0, 0.03, 0.074), Vector3(0.012, 0.09, 0.006), Color(0.85, 0.85, 0.85))
		_mesh_on("Neck", c.build(Props.toon()), Transform3D(Basis.IDENTITY, np))
	if ts == "ceket" and look["vest"] == null:
		var cb = skel.find_bone("UpperChest")
		if cb >= 0:
			var cp = skel.get_bone_global_rest(cb).origin
			var z = MB.new()
			z.add("box", Vector3(0, -0.12, 0.13), Vector3(0.012, 0.42, 0.01), Color(0.85, 0.85, 0.85), Vector3(-6, 0, 0))
			_mesh_on("UpperChest", z.build(Props.toon()), Transform3D(Basis.IDENTITY, cp))
	# bel bağı (pantolon kemeri)
	var hb = skel.find_bone("Hips")
	if hb >= 0:
		var hp = skel.get_bone_global_rest(hb).origin
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
	"diken": "Hair_Buzzed", "kısa": "Hair_SimpleParted", "uzun": "Hair_Long",
	"atkuyruğu": "Hair_Buzzed", "kase": "Hair_Buzzed", "dağınık": "Hair_Buzzed",
}
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
	if style in ["diken", "dağınık", "kase", "atkuyruğu"]:
		for row in [[8.0, 5], [30.0, 9], [55.0, 12], [80.0, 14], [102.0, 12]]:
			for i in row[1]:
				var yw = 360.0 * (float(i) + 0.5) / row[1] + row[0]
				var wy = wrapf(yw, -180.0, 180.0)
				if row[0] > 70.0 and absf(wy) < 60.0:
					continue  # alın/yüz açık
				var a = at.call(yw, row[0])
				var n: Vector3 = a[1]
				var flow = (Vector3(0, -0.55, -1.0) - n * n.dot(Vector3(0, -0.55, -1.0)))
				if flow.length() < 0.05:
					flow = Vector3(0, -1, 0) - n * n.y
				var root = c + n * r * 0.86
				_clump(st, root, (flow.normalized() + n * 0.25).normalized(), -n * 0.15, rng.randf_range(0.1, 0.14), 0.08, 0.32)
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
			for i in 9:
				var a = at.call(rng.randf_range(-80, 80), rng.randf_range(15, 60))
				_clump(st, a[0], (a[1] + Vector3(0, 0.1, 0.0)).normalized(), Vector3(0, -0.3, 0), 0.1, 0.06)
			for sx in [-1.0, 1.0]:  # yüzü çerçeveleyen uzun perçemler
				var a = at.call(62.0 * sx, 62.0)
				_clump(st, a[0], Vector3(0.15 * sx, -1, 0.25).normalized(), Vector3(0, -0.1, 0.05), 0.2, 0.045)
			bangs.call(3, 25.0, 0.12, 0.045)
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
	var file: String = HAIR_FILES.get(look["hair_style"], "Hair_SimpleParted")
	if female and file == "Hair_Buzzed":
		file = "Hair_BuzzedFemale"
	var hs: PackedScene = load("res://assets/chars/hair/%s.gltf" % file)
	if hs:
		var hn = hs.instantiate()
		var ba = _attach("Head", Transform3D.IDENTITY)
		ba.get_child(0).add_child(hn)
		for mi in hn.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = hair_mat
		var hk = "%s|%s" % [look["hair_style"], file]
		if not _hair_cache.has(hk):
			var ab = _scalp(file, hn)
			_hair_cache[hk] = _hair_clumps(look["hair_style"], ab.get_center() + Vector3(0, -ab.size.y * 0.12, 0), ab.size * 0.5)
		var cm = ShaderMaterial.new()
		cm.shader = load("res://shaders/toon.gdshader")
		cm.set_shader_parameter("tint", hair_col)
		cm.set_shader_parameter("rim_amount", 0.6)
		cm.set_shader_parameter("spec_amount", 0.3)
		materials.append(cm)
		var cl = _mesh_on("Head", _hair_cache[hk], Transform3D.IDENTITY)
		cl.material_override = cm
	if look.get("beard", false) and not female:
		var bs: PackedScene = load("res://assets/chars/hair/Hair_Beard.gltf")
		if bs:
			var bn = bs.instantiate()
			_attach("Head", Transform3D.IDENTITY).get_child(0).add_child(bn)
			for mi in bn.find_children("*", "MeshInstance3D", true, false):
				mi.material_override = hair_mat
	# --- alın koruyucu
	if look["band"] != null and look["band_style"] != "none":
		var band = MB.new()
		var bc: Color = look["band"]
		if look["band_style"] == "neck":
			band.add("torus", Vector3.ZERO, Vector3(0.24, 0.24, 0.24), bc, Vector3.ZERO, 16)
			_mesh_on("Neck", band.build(Props.toon()), Transform3D(Basis.IDENTITY, skel.get_bone_global_rest(skel.find_bone("Neck")).origin + Vector3(0, 0.03, 0)))
		else:
			band.add("cyl", Vector3.ZERO, Vector3(0.205, 0.075, 0.228), bc, Vector3.ZERO, 18)
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
		var hp = skel.get_bone_global_rest(hb).origin
		var sx = 1.0 if pair[1] == "Left" else -1.0
		_mesh_on(pair[1] + "Hand", weapon_mesh(String(wid)), Transform3D(Basis.IDENTITY, hp + Vector3(0.075 * sx, -0.015, 0.01)))
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


func flash(amount: float) -> void:
	hit_flash = maxf(hit_flash, amount)


func _process(dt: float) -> void:
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - dt * 5.0)
		for m in materials:
			m.set_shader_parameter("hit_flash", hit_flash)
