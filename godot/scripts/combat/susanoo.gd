class_name Susanoo
extends Node3D
## Susanoo: iki göz de Mangekyō/Ebedi Mangekyō iken V basılı. Ustalıkla kademe atlar:
## 1 Kaburga (omurga, kaburgalar, tek kol)  2 İskelet (kafatası, iki kol, parmaklar)
## 3 İnsansı (kaslı üst gövde, zırh, yüz, silah)  4 Zırhlı Savaşçı (tam beden)  5 Mükemmel Susanoo (devasa, kanatlı)
## Gerçek iskelet + gövde (CharacterModel) kullanır: oyuncuyla birlikte animasyon yapar.
## Özelleştirme (profile["susanoo"]): renk, zırh stili, yüz, silah, kanat, tercih edilen kademe.

const TIER_NAMES := ["", "Kaburga", "İskelet", "İnsansı", "Zırhlı Savaşçı", "Mükemmel Susanoo"]
const TIER_HEIGHT := [0.0, 2.05, 9.5, 16.0, 36.0, 78.0]   # 1: oyuncuyu saran kaburga .. 5: kuyruklu canavar boyunda Mükemmel Susanoo
## Kullanıcının Susanoo içindeki yeri (Susanoo boyuna oran): 3-4 göğüs, 5 alındaki mücevher (animedeki gibi)
const USER_SEAT := [0.0, 0.0, 0.0, 0.2, 0.64, 0.86]   # 3: kalça yere gömülü olduğundan göğüs alçakta
const ARMORS := ["Samuray", "Keşiş Cübbesi", "İblis Dikenleri"]
const FACES := ["Tengu", "Oni Boynuzlu", "Vizörlü Savaşçı"]
const WEAPONS := {"kilic": "Kılıç", "yay": "Yay ve Ok", "kalkan": "Kalkan", "mizrak": "Mızrak", "yok": "Silahsız"}
const COLORS := [[0.55, 0.35, 1.0], [0.25, 0.55, 1.0], [1.0, 0.35, 0.2], [0.3, 0.9, 0.5], [1.0, 0.8, 0.25], [0.95, 0.3, 0.6], [0.25, 0.95, 0.95], [0.85, 0.85, 0.95]]
const MASTERY_STEPS := [0.0, 0.0, 480.0, 1500.0, 3000.0, 6000.0]   # kademe için gereken ustalık (Susanoo açıkken DÖVÜŞTE geçen sn): 8 dk, 25 dk, 50 dk, 100 dk
const BONES := [["Hips", "Spine"], ["Spine", "Chest"], ["Chest", "UpperChest"], ["UpperChest", "Neck"], ["Neck", "Head"]]
const ARM_BONES := [["Shoulder", "UpperArm"], ["UpperArm", "LowerArm"], ["LowerArm", "Hand"]]
const FINGERS := ["Thumb", "Index", "Middle", "Ring", "Little"]

var tier = 1
var cfg := {}
var mat: ShaderMaterial
var body: CharacterModel
var follow: CharacterModel     # oyuncunun modeli (animasyon eşleme)
var swing_t = -1.0


static func config(pr: Dictionary) -> Dictionary:
	if not pr.has("susanoo"):
		pr["susanoo"] = {"color": COLORS[0], "armor": 0, "face": 0, "weapon": "kilic", "wings": true, "mastery": 0.0, "tier_pref": 5}
	return pr["susanoo"]


## Göz türlerine ve ustalığa göre ulaşılabilen en yüksek kademe
static func max_tier(pr: Dictionary) -> int:
	var r = Gear.equipped(pr, "sag_goz"); var l = Gear.equipped(pr, "sol_goz")
	if r.is_empty() or l.is_empty():
		return 0
	var kr = int(Gear.item(r["id"]).get("eye", {}).get("kind", 0)); var kl = int(Gear.item(l["id"]).get("eye", {}).get("kind", 0))
	# iki göz de Mangekyō soyundan olmalı; biri Rinnegan olabilir (Sasuke gibi) ama en az biri Mangekyō/EMS
	if not (kr in [4, 5, 6] and kl in [4, 5, 6] and (kr in [4, 5] or kl in [4, 5])):
		return 0
	# Ebedi Mangekyō (+ Rinnegan): tam beden (Zırhlı Savaşçı / Mükemmel Susanoo) hemen açık; Mangekyō ustalıkla en fazla İnsansı'ya çıkar
	if kr in [5, 6] and kl in [5, 6]:
		return 5
	var m = float(config(pr).get("mastery", 0.0))
	var cap = 3
	var t = 1
	for i in range(2, 6):
		if m >= MASTERY_STEPS[i]:
			t = i
	return mini(t, cap)


static func cur_tier(pr: Dictionary) -> int:
	return mini(max_tier(pr), int(config(pr).get("tier_pref", 5)))


func color() -> Color:
	var c: Array = cfg.get("color", COLORS[0])
	return Color(c[0], c[1], c[2])


## Parça türleri (köşe renginin r kanalı; g = ton): susanoo.gdshader bunlara göre boyar
const K_FLESH := Color(1, 1, 1)        # chakra eti
const K_PLATE := Color(0.8, 1, 1)      # zırh plakası (ızgara çizgili)
const K_BONE := Color(0.6, 1, 1)       # kemik (açık, dolgun)
const K_LINE := Color(0.4, 1, 1)       # açık çizgi (sarmal, kenar şeridi, mücevher)
const K_DARK := Color(0.15, 1, 1)      # koyu oyuk (göz çukuru, ağız içi, başlık gölgesi)

var bmat: ShaderMaterial     # gövde ağı (köşe rengi tür taşımaz)
var gmat: ShaderMaterial     # hayalet et (iskelet kademelerinde kemikleri saran soluk beden)
var amat: ShaderMaterial     # alev silueti (şişirilmiş arka yüz kabuğu)
var _rec: Array = []
static var _parts_cache := {}   # kademe|zırh|yüz|silah|kanat -> [[kemik, ağ, malzeme türü]]: ikinci açılışta ağlar yeniden kurulmaz


static func _t(c: Color, tone: float) -> Color:
	return Color(c.r, tone, 1.0)


## Renk/kenar rengi/yoğunluk/parlaklık/akış: malzemelere uygula (menüde kaydırınca anında görünür)
func apply_look() -> void:
	if mat == null:
		return
	var rc: Array = cfg.get("rim_color", cfg.get("color", COLORS[0]))
	for m in [mat, bmat, gmat, amat]:
		if m == null:
			continue
		m.set_shader_parameter("col", color())
		m.set_shader_parameter("rim_col", Color(rc[0], rc[1], rc[2]))
		m.set_shader_parameter("density", float(cfg.get("density", 1.0)))
		m.set_shader_parameter("glow", float(cfg.get("glow", 1.0)))
		m.set_shader_parameter("flow_speed", float(cfg.get("flow", 1.0)))


func build(pr: Dictionary, preview_tier := -1, follow_model: CharacterModel = null) -> void:
	cfg = config(pr)
	follow = follow_model
	tier = preview_tier if preview_tier > 0 else maxi(1, cur_tier(pr))
	for ch in get_children():
		ch.queue_free()
	_ba.clear()
	_fxm = null
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/susanoo.gdshader")
	bmat = ShaderMaterial.new()
	bmat.shader = mat.shader
	bmat.set_shader_parameter("vcol", 0.0)
	gmat = ShaderMaterial.new()
	gmat.shader = load("res://shaders/susanoo_ghost.gdshader")
	amat = ShaderMaterial.new()
	amat.shader = load("res://shaders/susanoo_aura.gdshader")
	amat.set_shader_parameter("shell", 0.05 if tier >= 3 else 0.07)
	if tier >= 3:   # etli / zırhlı kademeler: alev silueti gövdenin ve zırhın kenarından
		mat.next_pass = amat
		bmat.next_pass = amat
	else:           # iskelet kademeleri: alev silueti kemikleri saran hayalet etten
		gmat.next_pass = amat
	apply_look()
	if _eye_mat == null:
		_eye_mat = StandardMaterial3D.new()
		_eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_eye_mat.albedo_color = Color(1.0, 0.92, 0.45)
		_eye_mat.emission_enabled = true
		_eye_mat.emission = Color(1.0, 0.85, 0.3) * 2.5
	var armor = int(cfg.get("armor", 0))
	var look = {"gender": "m", "age": "adult", "top_style": "uzun", "pants_style": "ninja", "hair_style": "kısa", "band": null, "sleeves": true}
	if tier >= 3 and cfg.get("weapon", "kilic") in ["kilic", "mizrak"]:
		look["weapon_r"] = "nodachi" if cfg.get("weapon", "kilic") == "kilic" else "mizrak"
	body = CharacterModel.new()
	add_child(body)
	body.setup(look)
	body.play("idle")
	# kademeye göre gövde görünürlüğü
	var cut = 0.0
	if tier == 3:
		cut = 0.98   # üst gövde: kalçanın altı yok
	for m in [mat, bmat, amat]:
		m.set_shader_parameter("cut_y", cut)
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = bmat
		# override altında kullanılmayan yüzey malzemeleri (VRoid yüzü 7 yüzey): Susanoo silinirken "material is null" uyarısı veriyordu
		if mi.mesh:
			for si in mi.mesh.get_surface_count():
				mi.set_surface_override_material(si, null)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if tier <= 2:
			mi.visible = false
		var nm = String(mi.name).to_lower()
		if nm.contains("eye") or nm.contains("brow") or nm.contains("hair"):
			mi.visible = false
	# dev oranlar: omuzlar dışa açılır, kollar uzar, eller büyür (gerçek kemikler)
	if tier >= 2 and body.overlay:
		body.overlay.grow = {"LeftShoulder": 1.32, "RightShoulder": 1.32, "LeftHand": 1.3, "RightHand": 1.3, "Head": 0.95}
	var key = "%d|%d|%d|%s|%s" % [tier, armor, int(cfg.get("face", 0)), String(cfg.get("weapon", "kilic")), str(cfg.get("wings", true))]
	if not _parts_cache.has(key):
		_rec = []
		_parts(armor)
		_parts_cache[key] = _rec
	for r in _parts_cache[key]:
		_place(r[0], r[1], r[2])
	_aura()
	scale = Vector3.ONE * (TIER_HEIGHT[tier] / 1.8)
	# İnsansı (üst gövde): kalça yere gömülü, gövde kullanıcının etrafında yerden yükselir (havada asılı durmasın)
	position.y = -0.95 * TIER_HEIGHT[tier] / 1.8 if tier in [2, 3] else 0.0   # iskelet + İnsansı: bacak yok, bel yerde


func _bp(n: String) -> Vector3:
	var i = body.skel.find_bone(n)
	return body.skel.get_bone_global_rest(i).origin if i >= 0 else Vector3.ZERO


func _on(bone: String, m: MB, kind := 0) -> void:
	if m.is_empty():
		return
	_rec.append([bone, m.build(null), kind])


func _place(bone: String, mesh: Mesh, kind: int) -> void:
	var mi: MeshInstance3D
	if bone == "":   # kemiğe değil iskeletin kendisine bağlı (animasyonla oynamaz)
		mi = MeshInstance3D.new()
		mi.mesh = mesh
		body.skel.add_child(mi)
	elif body.skel.find_bone(bone) < 0:
		return
	else:
		mi = body._mesh_on(bone, mesh, Transform3D.IDENTITY)
	mi.material_override = [mat, gmat, _eye_mat][kind]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ------------------------------------------------------------------ ağ yardımcıları
## Dikey tüp (gövde, bacak): yarıçap Vector2(x, z)
static func _vtube(mb: MB, pts: Array, rad: Array, col, seg := 14, sub := 3) -> void:
	Loft.tube(mb, pts, rad, col, seg, sub, true, true, Callable(), Vector3.BACK)


## Uçları topuzlu kemik
static func _shaft(mb: MB, a: Vector3, b: Vector3, r: float, col := K_BONE) -> void:
	var up = Vector3.BACK if absf((b - a).normalized().y) > 0.9 else Vector3.UP
	Loft.tube(mb, [a, a.lerp(b, 0.14), a.lerp(b, 0.5), a.lerp(b, 0.86), b], [r * 1.45, r * 0.9, r * 0.8, r * 0.9, r * 1.45], col, 8, 2, true, true, Callable(), up)


## Kıvrılarak sivrilen diken / boynuz / alev tutamı
static func _spike(mb: MB, base: Vector3, dir: Vector3, length: float, r: float, col: Color, bend := Vector3.ZERO, flat := 1.0) -> void:
	var d = dir.normalized()
	var up = Vector3.BACK if absf(d.y) > 0.9 else Vector3.UP
	Loft.tube(mb, [base, base + d * length * 0.5 + bend * length * 0.22, base + d * length + bend * length],
		[Vector2(r * flat, r), Vector2(r * 0.62 * flat, r * 0.62), Vector2(0.004, 0.004)], col, 6, 3, true, true, Callable(), up)


## Yassı yaprak (tüy, etek plakası, kuşak ucu): a kökten b uca, en geniş yeri w, düzlem normali nrm
static func _blade(mb: MB, a: Vector3, b: Vector3, w: float, nrm: Vector3, col: Color, root_w := 0.55, tip_cut := 0.0) -> void:
	var d = b - a
	var side = d.cross(nrm).normalized() * w
	var base = mb.verts.size()
	var vs = [a - side * root_w, a + side * root_w, a.lerp(b, 0.62) + side, b + side * tip_cut, b - side * tip_cut, a.lerp(b, 0.62) - side]
	for v in vs:
		mb.verts.append(v)
		mb.normals.append(nrm)
		mb.colors.append(col)
		mb.uvs.append(Vector2.ZERO)
	mb.idx.append_array([base, base + 1, base + 2, base, base + 2, base + 5, base + 5, base + 2, base + 3, base + 5, base + 3, base + 4])


## Parametrik yüzey yaması: fn(u, v) -> Vector3 (u, v 0..1)
static func _patch(mb: MB, fn: Callable, nu: int, nv: int, col: Color) -> void:
	var base = mb.verts.size()
	var P: Array = []
	for j in nv + 1:
		for i in nu + 1:
			P.append(fn.call(float(i) / nu, float(j) / nv))
	for j in nv + 1:
		for i in nu + 1:
			var a: Vector3 = P[j * (nu + 1) + mini(i + 1, nu)] - P[j * (nu + 1) + maxi(i - 1, 0)]
			var b: Vector3 = P[mini(j + 1, nv) * (nu + 1) + i] - P[maxi(j - 1, 0) * (nu + 1) + i]
			var n = a.cross(b)
			mb.verts.append(P[j * (nu + 1) + i])
			mb.normals.append(n.normalized() if n.length() > 1e-9 else Vector3.UP)
			mb.colors.append(col)
			mb.uvs.append(Vector2(float(i) / nu, float(j) / nv))
	for j in nv:
		for i in nu:
			var a0 = base + j * (nu + 1) + i
			var b0 = a0 + nu + 1
			mb.idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])


## Kaburga kafesi: arkadan (omurga) öne kıvrılan yassı kaburga bantları. closed: önde göğüs kemiğine kavuşur
static func _ribs(mb: MB, c: Vector3, R: float, Rz: float, y0: float, y1: float, n: int, gap: float, band: float, drop: float, closed: bool) -> void:
	for i in n:
		var f = float(i) / maxf(1.0, n - 1)
		var y = lerpf(y0, y1, f)
		var w = lerpf(1.0, 0.72, f * f) * (0.86 + 0.14 * sin(PI * f))
		for sx in [-1.0, 1.0]:
			var pts: Array = []
			var rr: Array = []
			for k in 9:
				var u = k / 8.0
				var ang = lerpf(0.1, PI * (1.0 - gap), u)   # 0 = arka
				pts.append(c + Vector3(sx * sin(ang) * R * w, y - drop * pow(u, 1.4), -cos(ang) * Rz * w))
				var tp = 1.0 if closed else (1.0 - 0.6 * smoothstep(0.7, 1.0, u))
				rr.append(Vector2(band * 0.32, band * tp))
			Loft.tube(mb, pts, rr, K_BONE, 6, 2)


## Omurga: üst üste omurlar + geriye bakan dikensi çıkıntılar
static func _spine(mb: MB, x: float, z: float, y0: float, y1: float, n: int, r: float) -> void:
	for i in n:
		var y = lerpf(y0, y1, float(i) / maxf(1.0, n - 1))
		mb.add("sphere", Vector3(x, y, z), Vector3(r * 2.3, (y1 - y0) / n * 1.05, r * 2.0), K_BONE, Vector3.ZERO, 8)
		_spike(mb, Vector3(x, y, z - r * 0.6), Vector3(0, -0.25, -1), r * 1.7, r * 0.45, K_BONE)


# ------------------------------------------------------------------ kademeler
func _parts(armor: int) -> void:
	var face = int(cfg.get("face", 0))
	match tier:
		1:
			_tier_ribs()
		2:
			_tier_skeleton(face)
		_:
			_tier_body(armor, face)
	_glow_eyes()


## 1. kademe: kullanıcıyı saran dev kaburga kafesi (Madara'nın kaburgası: yassı geniş bantlar, arkada omurga)
func _tier_ribs() -> void:
	var m = MB.new()
	_ribs(m, Vector3(0, 0, 0.04), 0.74, 0.62, 0.42, 1.98, 6, 0.2, 0.075, 0.24, false)
	_spine(m, 0.0, -0.58, 0.16, 2.16, 17, 0.07)
	_on("", m)


## 2. kademe: iskelet (Sasuke / Itachi'nin ilk hâli): kafatası, kapalı kaburga, köprücük, kol ve parmak kemikleri; çevresinde soluk chakra eti
func _tier_skeleton(face: int) -> void:
	var m = MB.new()
	_ribs(m, Vector3(0, 0, 0.0), 0.2, 0.175, 1.07, 1.4, 6, 0.05, 0.026, 0.045, true)
	_vtube(m, [Vector3(0, 1.0, 0.165), Vector3(0, 1.2, 0.185), Vector3(0, 1.4, 0.14)], [Vector2(0.03, 0.016), Vector2(0.038, 0.018), Vector2(0.03, 0.016)], K_BONE, 8, 2)   # göğüs kemiği
	_on("Chest", m)
	var sp = MB.new()
	_spine(sp, 0.0, -0.13, 0.86, 1.5, 10, 0.045)
	_on("Chest", sp)
	var cl = MB.new()
	for sx in [-1.0, 1.0]:
		_shaft(cl, Vector3(0.025 * sx, 1.42, 0.135), Vector3(0.2 * sx, 1.455, 0.0), 0.02)   # köprücük
		_patch(cl, func(u, v): return Vector3(sx * (0.07 + 0.13 * u), 1.44 - 0.2 * v * (0.4 + 0.6 * u), -0.15 - 0.02 * sin(PI * u)), 4, 4, K_BONE)   # kürek kemiği
	_shaft(cl, Vector3(0, 1.44, -0.06), Vector3(0, 1.58, 0.0), 0.035)   # boyun omurları
	_on("UpperChest", cl)
	for sd in ["Left", "Right"]:
		var sx = 1.0 if sd == "Left" else -1.0
		var ua = _bp(sd + "UpperArm"); var la = _bp(sd + "LowerArm"); var lh = _bp(sd + "Hand")
		var a = MB.new()
		_shaft(a, ua, la, 0.036)
		a.add("sphere", ua, Vector3.ONE * 0.12, K_BONE, Vector3.ZERO, 8)
		_on(sd + "UpperArm", a)
		var b = MB.new()
		_shaft(b, la + Vector3(0, 0, 0.022), lh + Vector3(0, 0, 0.018), 0.022)
		_shaft(b, la + Vector3(0, 0, -0.022), lh + Vector3(0, 0, -0.018), 0.022)
		b.add("sphere", la, Vector3.ONE * 0.1, K_BONE, Vector3.ZERO, 8)
		_spike(b, la, Vector3(-sx * 0.3, 0, -1), 0.1, 0.03, K_BONE)   # dirsek çıkıntısı
		_on(sd + "LowerArm", b)
		var h = MB.new()
		h.add("sphere", lh + Vector3(0.035 * sx, 0, 0), Vector3(0.085, 0.035, 0.085), K_BONE, Vector3.ZERO, 8)
		_on(sd + "Hand", h)
		_finger_bones(sd, sx, K_BONE, 0.0105)
		# hayalet et: kolları saran soluk beden
		var g1 = MB.new()
		Loft.limb(g1, ua, la, 0.1, 0.085, K_FLESH)
		_on(sd + "UpperArm", g1, 1)
		var g2 = MB.new()
		Loft.limb(g2, la, lh + Vector3(0.1 * sx, 0, 0), 0.09, 0.075, K_FLESH)
		_on(sd + "LowerArm", g2, 1)
	var sk = MB.new()
	_skull(sk, face)
	_on("Head", sk)
	var g = MB.new()
	_vtube(g, [Vector3(0, 0.9, 0), Vector3(0, 1.15, 0), Vector3(0, 1.38, 0), Vector3(0, 1.5, 0)], [Vector2(0.24, 0.2), Vector2(0.27, 0.23), Vector2(0.33, 0.22), Vector2(0.16, 0.14)], K_FLESH, 16, 3)
	_on("Chest", g, 1)
	var gh = MB.new()
	gh.add("sphere", Vector3(0, 1.68, 0.02), Vector3(0.36, 0.44, 0.4), K_FLESH, Vector3.ZERO, 14)
	for k in 7:   # başın arkasında alev tutamları
		var a2 = lerpf(-1.9, 1.9, k / 6.0)
		_spike(gh, Vector3(sin(a2) * 0.12, 1.8, -cos(a2) * 0.12), Vector3(sin(a2) * 0.5, 0.8, -cos(a2) * 0.5 - 0.1), 0.18 + 0.06 * (k % 2), 0.05, K_FLESH, Vector3(0, 0.3, -0.2))
	_on("Head", gh, 1)


## Parmak kemikleri (gerçek parmak kemiklerine bağlı) + uçta pençe
func _finger_bones(sd: String, sx: float, col: Color, r: float) -> void:
	for f in FINGERS:
		var chain: Array = []   # bu parmağın var olan kemikleri (başparmakta ara kemik olmayabilir)
		for sg in ["Metacarpal", "Proximal", "Intermediate", "Distal"]:
			if body.skel.find_bone(sd + f + sg) >= 0:
				chain.append(sd + f + sg)
		for i in chain.size():
			var a = _bp(chain[i])
			var m = MB.new()
			if i < chain.size() - 1:
				_shaft(m, a, _bp(chain[i + 1]), r, col)
			else:
				var d = (a - _bp(chain[i - 1])) * 0.9 if i > 0 else Vector3(0.025 * sx, 0, 0)
				_shaft(m, a, a + d * 0.55, r, col)
				_spike(m, a + d * 0.5, d + Vector3(0, -0.012, 0), d.length() * 1.5, r * 1.25, K_BONE, Vector3(0, -0.45, 0))   # pençe
			_on(chain[i], m)
		if not chain.is_empty() and not String(chain[0]).ends_with("Metacarpal"):   # el tarağı
			var m2 = MB.new()
			_shaft(m2, _bp(sd + "Hand") + Vector3(0.02 * sx, 0, 0), _bp(chain[0]), r * 0.95, col)
			_on(sd + "Hand", m2)


## İnsan kafası kesiti (çeneden tepeye): [y, yarı genişlik, yarı derinlik, merkez z]. Bütün kademelerin kafası bu biçimden çıkar;
## kafa kemiği ayrıca küçültülür (animede Susanoo'nun başı geniş omuzlara göre küçük, insan oranında).
const HEAD_PROF := [[1.495, 0.035, 0.04, 0.075], [1.54, 0.075, 0.085, 0.045], [1.6, 0.105, 0.115, 0.025], [1.67, 0.12, 0.13, 0.015],
	[1.74, 0.122, 0.138, 0.005], [1.8, 0.105, 0.125, 0.0], [1.845, 0.06, 0.08, -0.005]]


static func _head_shell(m: MB, col: Color) -> void:
	var pts: Array = []
	var rr: Array = []
	for p in HEAD_PROF:
		pts.append(Vector3(0, p[0], p[3]))
		rr.append(Vector2(p[1], p[2]))
	_vtube(m, pts, rr, col, 18, 3)


## Kafa yüzeyinin ön yüzünde nokta (x, y) + dışa pay
static func _hp(x: float, y: float, lift := 0.0) -> Vector3:
	var a = HEAD_PROF[0]
	var b = HEAD_PROF[HEAD_PROF.size() - 1]
	for i in HEAD_PROF.size() - 1:
		if y >= HEAD_PROF[i][0] and y <= HEAD_PROF[i + 1][0]:
			a = HEAD_PROF[i]
			b = HEAD_PROF[i + 1]
			break
	var t = clampf((y - a[0]) / maxf(0.0001, b[0] - a[0]), 0.0, 1.0)
	var rx = lerpf(a[1], b[1], t); var rz = lerpf(a[2], b[2], t); var cz = lerpf(a[3], b[3], t)
	return Vector3(x, y, cz + rz * sqrt(maxf(0.0, 1.0 - pow(x / rx, 2.0))) + lift)


## Kafatası (Sasuke'nin iskelet Susanoo'su): insan kafatası, iri göz çukurları, üçgen burun boşluğu, düz diş sırası.
## yüz 0 = şakaklardan yana açılıp yukarı kıvrılan yassı boynuzlar (Sasuke), 1 = alında iki kısa boynuz, 2 = tepede sivri ibik (Madara)
func _skull(m: MB, face: int) -> void:
	_head_shell(m, K_BONE)
	for sx in [-1.0, 1.0]:
		m.add("sphere", _hp(0.05 * sx, 1.665, -0.014), Vector3(0.078, 0.062, 0.04), K_DARK, Vector3(0, 0, -8 * sx), 10)   # göz çukuru
		Loft.tube(m, [_hp(0.07 * sx, 1.62, 0.004), _hp(0.105 * sx, 1.63, 0.006), Vector3(0.122 * sx, 1.65, 0.03)], [0.011, 0.012, 0.008], K_BONE, 6, 2)   # elmacık
	m.add("cone", _hp(0, 1.613, -0.004), Vector3(0.03, 0.042, 0.02), K_DARK, Vector3.ZERO, 3)   # burun boşluğu
	_patch(m, func(u, v): return _hp(lerpf(-0.064, 0.064, u), lerpf(1.528, 1.582, v), 0.004), 8, 1, K_DARK)   # diş aralığı
	for k in 8:   # sıkılmış düz dişler: üst ve alt sıra
		var x = (k - 3.5) * 0.0155
		m.add("box", _hp(x, 1.5685, 0.007), Vector3(0.0125, 0.021, 0.008), K_BONE)
		m.add("box", _hp(x, 1.5425, 0.007), Vector3(0.0125, 0.021, 0.008), K_BONE)
	match face:
		0:
			for sx in [-1.0, 1.0]:
				_spike(m, Vector3(0.105 * sx, 1.745, 0.0), Vector3(sx, 0.3, 0), 0.2, 0.055, K_BONE, Vector3(-0.1 * sx, 0.95, 0), 0.35)
		1:
			for sx in [-1.0, 1.0]:
				_spike(m, Vector3(0.05 * sx, 1.815, 0.07), Vector3(0.3 * sx, 1, 0.2), 0.12, 0.02, K_BONE)
		2:
			_vtube(m, [Vector3(0, 1.8, 0.0), Vector3(0, 1.92, -0.01), Vector3(0, 2.06, -0.03)], [Vector2(0.1, 0.115), Vector2(0.07, 0.085), Vector2(0.006, 0.006)], K_BONE, 12, 3)


## Animedeki imza: kafatası / maske gözlerinde parlayan sarı ışık (kendi malzemesi, Susanoo renginden bağımsız)
static var _eye_mat: StandardMaterial3D
func _glow_eyes() -> void:
	if tier == 1:
		return
	var m = MB.new()
	for sx in [-1.0, 1.0]:
		if tier == 2:
			m.add("sphere", _hp(0.05 * sx, 1.665, 0.004), Vector3(0.05, 0.034, 0.012), Color.WHITE, Vector3(0, 0, -8 * sx), 10)
		else:
			m.add("sphere", _hp(0.052 * sx, 1.667, 0.005), Vector3(0.046, 0.015, 0.01), Color.WHITE, Vector3(0, 0, -17 * sx), 8)
	_on("Head", m, 2)


## Yüzlü baş (kademe 3-5): insan oranında kafa. hooded: yüz başlığın gölgesinde (koyu), gagalı dar kukuleta.
## yüz 0 = Tengu (uzun burun, alında altıgen mücevher), 1 = Oni (kısa boynuzlar, azı dişleri), 2 = sivri külahlı savaşçı (Madara)
func _head(m: MB, face: int, hooded: bool, crest: bool) -> void:
	var skin = K_DARK if hooded else K_FLESH
	_head_shell(m, skin)
	if not hooded:
		for sx in [-1.0, 1.0]:
			Loft.tube(m, [_hp(0.012 * sx, 1.676, 0.006), _hp(0.055 * sx, 1.697, 0.008), _hp(0.106 * sx, 1.728, 0.003)],
				[Vector2(0.01, 0.009), Vector2(0.013, 0.011), Vector2(0.005, 0.005)], _t(K_FLESH, 0.8), 6, 3)   # çatık kaş
			m.add("sphere", _hp(0.052 * sx, 1.667, -0.009), Vector3(0.064, 0.027, 0.03), K_DARK, Vector3(0, 0, -17 * sx), 8)   # göz yarığı
			# burun kenarından ağzın yanına inen çizgi (Kakashi / Madara'nın Susanoo'sundaki yüz çizgileri)
			Loft.tube(m, [_hp(0.022 * sx, 1.628, 0.003), _hp(0.052 * sx, 1.59, 0.003), _hp(0.05 * sx, 1.538, 0.003)], [0.0035, 0.0035, 0.0035], K_LINE, 4, 3)
	# ağız: dar koyu yarık + sivri dişler, köşelerde azı dişi
	var mp = func(u: float) -> Vector3:
		var q = 2.0 * u - 1.0
		return _hp(0.062 * q, 1.556 + 0.018 * q * q, 0.003)
	var mpts: Array = []
	var mr: Array = []
	for k in 7:
		mpts.append(mp.call(k / 6.0))
		mr.append(Vector2(0.006, 0.006 + 0.01 * sin(PI * k / 6.0)))
	Loft.tube(m, mpts, mr, K_DARK, 6, 2)
	for k in 7:
		var p: Vector3 = mp.call((k + 0.5) / 7.0)
		var fang = 1.5 if k in [0, 6] else 1.0
		m.add("cone", p + Vector3(0, 0.004, 0.006), Vector3(0.011, 0.016 * fang, 0.008), K_BONE, Vector3(180, 0, 0), 4)
		if k < 6:
			var p2: Vector3 = mp.call((k + 1.0) / 7.0)
			m.add("cone", p2 + Vector3(0, -0.01, 0.005), Vector3(0.01, 0.014, 0.008), K_BONE, Vector3.ZERO, 4)
	match face:
		0:
			if not hooded:
				var nb = _hp(0, 1.65, -0.01)
				Loft.tube(m, [nb, nb + Vector3(0, -0.006, 0.1), nb + Vector3(0, -0.035, 0.2)], [0.022, 0.019, 0.008], K_FLESH, 8, 3)   # tengu burnu
				m.add("cyl", _hp(0, 1.765, 0.004), Vector3(0.05, 0.012, 0.05), K_LINE, Vector3(82, 0, 0), 6)                    # altıgen mücevher
		1:
			for sx in [-1.0, 1.0]:
				if not hooded:
					_spike(m, _hp(0.05 * sx, 1.8, -0.01), Vector3(0.35 * sx, 1, 0.2), 0.16, 0.022, K_BONE, Vector3(0.1 * sx, 0.3, -0.2))
				_spike(m, _hp(0.058 * sx, 1.553, 0.002), Vector3(0.1 * sx, 1, 0.15), 0.04, 0.009, K_BONE)
			if not hooded:
				var nb2 = _hp(0, 1.65, -0.005)
				Loft.tube(m, [nb2, nb2 + Vector3(0, -0.025, 0.022), nb2 + Vector3(0, -0.045, 0.012)], [0.011, 0.018, 0.013], K_FLESH, 6, 2)
		2:
			if not hooded:
				# sivri külah: alından yukarı uzayan dilimli taç (Madara'nın insansı Susanoo'su)
				_vtube(m, [Vector3(0, 1.78, 0.0), Vector3(0, 1.93, -0.01), Vector3(0, 2.12, -0.03)], [Vector2(0.115, 0.13), Vector2(0.085, 0.1), Vector2(0.006, 0.006)], _t(K_FLESH, 0.9), 14, 3)
				for k in 5:
					var x0 = (k - 2) * 0.04
					Loft.tube(m, [_hp(x0, 1.73, 0.004), Vector3(x0 * 0.75, 1.93, 0.094 - absf(x0) * 0.25), Vector3(0, 2.12, -0.02)], [0.004, 0.004, 0.003], K_LINE, 4, 3)
				var nb3 = _hp(0, 1.65, -0.005)
				Loft.tube(m, [nb3, nb3 + Vector3(0, -0.03, 0.02), nb3 + Vector3(0, -0.045, 0.01)], [0.009, 0.014, 0.01], K_FLESH, 6, 2)
			_spike(m, Vector3(0, 1.5, 0.08), Vector3(0, -1, 0.2), 0.07, 0.022, skin)
	if hooded:
		# dar kukuleta: yüzü açıkta bırakır, tepesi alnın önüne sarkan gaga (Sasuke / Itachi'nin zırhlı Susanoo'su)
		var hood = func(u: float, v: float) -> Vector3:
			var ang = lerpf(-2.2, 2.2, u)
			var top = smoothstep(0.6, 1.0, v)
			var r = (0.152 + 0.022 * sin(PI * v)) * (1.0 - 0.9 * top * top)
			return Vector3(sin(ang) * r, lerpf(1.46, 1.91, v), 0.008 - cos(ang) * r * 1.08 + top * 0.04)
		_patch(m, hood, 18, 9, _t(K_FLESH, 0.92))
		for u in [0.0, 1.0]:
			var ep: Array = []
			var er: Array = []
			for k in 7:
				ep.append(hood.call(u, k / 7.0))
				er.append(0.007)
			Loft.tube(m, ep, er, K_LINE, 5, 2)
		Loft.tube(m, [Vector3(0, 1.86, -0.03), Vector3(0, 1.885, 0.09), Vector3(0, 1.84, 0.2), Vector3(0, 1.755, 0.27)],
			[Vector2(0.11, 0.05), Vector2(0.085, 0.04), Vector2(0.045, 0.026), Vector2(0.005, 0.005)], K_FLESH, 10, 4)   # gaga
		m.add("cyl", Vector3(0, 1.918, 0.1), Vector3(0.05, 0.012, 0.05), K_LINE, Vector3(20, 0, 0), 6)   # tepedeki altıgen mücevher
	elif face != 2:
		# yukarı ve geriye taranmış dikenli alev saçı (Kakashi / Shisui'nin Susanoo'su)
		for k in 13:
			var a = lerpf(-2.4, 2.4, k / 12.0)
			_spike(m, Vector3(sin(a) * 0.095, 1.79, -cos(a) * 0.1), Vector3(sin(a) * 0.45, 1.0, -cos(a) * 0.45 - 0.25), 0.13 + 0.07 * (k % 2), 0.04,
				_t(K_FLESH, 0.85), Vector3(0, 0.3, -0.2), 0.5)
		for k in 5:
			var x1 = (k - 2) * 0.04
			_spike(m, _hp(x1, 1.795, -0.02), Vector3(x1 * 2.0, 1.0, 0.12), 0.2 - absf(x1) * 1.4, 0.035, _t(K_FLESH, 0.85), Vector3(0, 0.2, -0.25), 0.5)
	if crest:   # Mükemmel Susanoo: alın plakası + iki ince tepelik
		_patch(m, func(u, v): return _hp(lerpf(-0.09, 0.09, u), lerpf(1.722, 1.782, v), 0.006), 6, 1, K_PLATE)
		for sx in [-1.0, 1.0]:
			_spike(m, _hp(0.03 * sx, 1.78, 0.004), Vector3(0.7 * sx, 0.75, 0.05), 0.2, 0.013, K_LINE, Vector3(-0.15 * sx, 0.6, 0), 0.5)
		if face != 0:
			m.add("cyl", _hp(0, 1.752, 0.01), Vector3(0.04, 0.012, 0.04), K_LINE, Vector3(82, 0, 0), 6)


## Omuz kubbesinin üstünde sarmal çizgi (animedeki alev sarmalı)
static func _spiral(m: MB, c: Vector3, R: float, hgt: float, turns: float, sgn: float) -> void:
	var pts: Array = []
	var rr: Array = []
	for k in 17:
		var t = k / 16.0
		var ang = t * TAU * turns * sgn
		var q = R * (1.0 - t * 0.92)
		pts.append(c + Vector3(cos(ang) * q, hgt * sqrt(maxf(0.02, 1.0 - pow(q / (R * 1.08), 2.0))) + 0.004, sin(ang) * q * 1.12))
		rr.append(0.008)
	Loft.tube(m, pts, rr, K_LINE, 5, 2)


## Kademe 3-5: etli / zırhlı beden. 3 = İnsansı (kaslı üst gövde, açık iblis yüzü), 4 = Zırhlı (gagalı başlık, tam beden zırh),
## 5 = Mükemmel (açık tengu yüzü, yele, tepelik, uzun etek, tüylü kanatlar). zırh 0 = samuray plakaları, 1 = keşiş cübbesi + tespih, 2 = iblis dikenleri
func _tier_body(armor: int, face: int) -> void:
	var hp = _bp("Hips"); var nk = _bp("Neck")
	var plated = tier >= 4
	# ---- gövde
	var t = MB.new()
	_vtube(t, [Vector3(0, 0.98, 0.0), Vector3(0, 1.16, 0.01), Vector3(0, 1.34, 0.0), Vector3(0, 1.47, -0.005)],
		[Vector2(0.215, 0.165), Vector2(0.245, 0.185), Vector2(0.335, 0.215), Vector2(0.16, 0.14)], K_PLATE if plated else K_FLESH, 18, 3)
	if plated:
		# göğüs plakası kenarı + orta sırt
		_vtube(t, [Vector3(0, 1.1, 0.188), Vector3(0, 1.26, 0.208), Vector3(0, 1.4, 0.19)], [Vector2(0.014, 0.01), Vector2(0.014, 0.01), Vector2(0.014, 0.01)], K_LINE, 5, 2)
		for sx in [-1.0, 1.0]:
			Loft.tube(t, [Vector3(0.0, 1.44, 0.16), Vector3(0.14 * sx, 1.4, 0.192), Vector3(0.265 * sx, 1.33, 0.13), Vector3(0.3 * sx, 1.25, 0.0)], [0.011, 0.011, 0.011, 0.011], K_LINE, 5, 3)
	else:
		for sx in [-1.0, 1.0]:   # göğüs kasları + kaburga çizgileri
			t.add("sphere", Vector3(0.125 * sx, 1.35, 0.172), Vector3(0.24, 0.14, 0.085), K_FLESH, Vector3.ZERO, 10)
			for k in 4:
				var y = 1.07 + k * 0.05
				Loft.tube(t, [Vector3(0.04 * sx, y - 0.015, 0.183), Vector3(0.15 * sx, y, 0.14), Vector3(0.232 * sx, y + 0.03, 0.02)], [0.007, 0.008, 0.006], K_LINE, 4, 3)
		_vtube(t, [Vector3(0, 1.0, 0.172), Vector3(0, 1.15, 0.187), Vector3(0, 1.27, 0.19)], [Vector2(0.007, 0.006), Vector2(0.007, 0.006), Vector2(0.007, 0.006)], K_LINE, 4, 2)
	# boyun
	_vtube(t, [Vector3(0, 1.42, 0.0), Vector3(0, 1.56, 0.01)], [Vector2(0.085, 0.085), Vector2(0.07, 0.07)], _t(K_FLESH, 0.85), 10, 2)
	if armor != 2:   # magatama kolyesi (keşişte iri tespih)
		var big = 1.5 if armor == 1 else 1.0
		for k in 9:
			var a = lerpf(-1.25, 1.25, k / 8.0)
			var q = Vector3(sin(a) * 0.19, 1.4 - cos(a) * 0.06, 0.06 + cos(a) * 0.125)
			t.add("sphere", q, Vector3(0.04, 0.04, 0.03) * big, K_LINE, Vector3.ZERO, 6)
			if armor == 0:
				t.add("cone", q + Vector3(0.012 * sin(a), -0.03, 0.0), Vector3(0.02, 0.045, 0.016), K_LINE, Vector3(0, 0, 180 + 30 * sin(a)), 4)
	_on("Chest", t)
	# ---- sırt: omurga dikenleri (kanat yoksa)
	var uc = MB.new()
	if not (tier >= 5 and cfg.get("wings", true)):
		for k in 5:
			_spike(uc, Vector3(0, 1.1 + k * 0.085, -0.17), Vector3(0, 0.45, -1), 0.13 + 0.03 * sin(k * 1.3), 0.03, K_BONE if armor == 2 else _t(K_FLESH, 0.8), Vector3(0, 0.4, 0), 0.5)
	# ---- kollar
	for sd in ["Left", "Right"]:
		var sx = 1.0 if sd == "Left" else -1.0
		var ua = _bp(sd + "UpperArm"); var la = _bp(sd + "LowerArm"); var lh = _bp(sd + "Hand")
		var a = MB.new()
		Loft.limb(a, ua + Vector3(0.02 * sx, 0, 0), la, 0.09, 0.07, K_FLESH)
		# omuz kubbesi + sarmal
		var dc = ua + Vector3(0.04 * sx, 0.04, 0.0)
		a.add("sphere", dc, Vector3(0.34, 0.25, 0.37), _t(K_FLESH, 0.92), Vector3.ZERO, 14)
		_spiral(a, dc, 0.125, 0.125, 1.6, sx)
		var lames = 0 if tier == 3 and armor != 0 else (2 if armor == 1 or tier == 3 else 3)
		for k in lames:   # ōsode: dışa ve aşağı açılan katmanlı plakalar
			var kk = float(k)
			var lam = func(u: float, v: float) -> Vector3:
				var ang = lerpf(-1.15, 1.15, u)
				var rad = 0.175 + kk * 0.016 + v * 0.035
				return Vector3(ua.x + sx * (0.02 + kk * 0.038 + cos(ang) * rad * 0.8 + v * 0.05), ua.y + 0.055 - kk * 0.072 - v * 0.105 + cos(ang) * 0.02, sin(ang) * rad * 1.15)
			_patch(a, lam, 8, 2, _t(K_PLATE, 1.0 if k % 2 == 0 else 0.82))
			var ep: Array = []
			var er: Array = []
			for q in 7:
				ep.append(lam.call(q / 6.0, 1.0))
				er.append(0.007)
			Loft.tube(a, ep, er, K_LINE, 4, 2)
		if armor == 2:   # iblis: omuzdan fışkıran kemik dikenler
			for k in 4:
				_spike(a, dc + Vector3((0.0 + k * 0.03) * sx, 0.07, -0.08 + k * 0.05), Vector3(0.45 * sx, 1, (k - 1.5) * 0.25), 0.2 + 0.05 * (k % 2), 0.035, K_BONE, Vector3(0.3 * sx, 0, 0))
		_on(sd + "UpperArm", a)
		# önkol: kol koruyucu + dirsek dikeni
		var b = MB.new()
		var gcol = K_PLATE if (plated or armor == 0) else K_FLESH
		Loft.tube(b, [la.lerp(lh, 0.04), la.lerp(lh, 0.45), la.lerp(lh, 0.97)], [0.082, 0.1, 0.07], gcol, 12, 3)
		b.add_xf("torus", Transform3D(Basis(Vector3.FORWARD, PI * 0.5) * Basis.from_scale(Vector3(0.21, 0.045, 0.21)), la.lerp(lh, 0.95)), K_LINE, 12)
		_spike(b, la + Vector3(0, 0, -0.03), Vector3(-sx * 0.5, 0.1, -1), 0.15, 0.04, K_BONE if armor == 2 else gcol, Vector3.ZERO, 0.6)
		if armor == 2:
			for k in 3:
				_spike(b, la.lerp(lh, 0.25 + k * 0.25) + Vector3(0, 0.04, -0.04), Vector3(-sx * 0.4, 0.6, -0.8), 0.11, 0.025, K_BONE)
		_on(sd + "LowerArm", b)
		# el: el üstü plakası + kalın parmaklar ve pençeler
		var h = MB.new()
		h.add("sphere", lh + Vector3(0.045 * sx, 0.004, 0.0), Vector3(0.115, 0.06, 0.105), gcol, Vector3.ZERO, 8)
		_on(sd + "Hand", h)
		_finger_bones(sd, sx, K_FLESH, 0.0135)
	_on("UpperChest", uc)
	# ---- baş
	var f = MB.new()
	_head(f, face, tier == 4, tier >= 5)
	_on("Head", f)
	if tier == 4:   # başlığın omuzlara inen pelerini (alt kenarı alev dilli)
		var mt = MB.new()
		var mant = func(u: float, v: float) -> Vector3:
			var ang = u * TAU
			return Vector3(sin(ang) * lerpf(0.19, 0.47, v), lerpf(1.53, 1.36, v) - 0.045 * v * absf(sin(ang * 5.0)) - 0.04 * v * absf(sin(ang)), -0.01 + cos(ang) * lerpf(0.16, 0.3, v))
		_patch(mt, mant, 30, 3, _t(K_FLESH, 0.8))
		var hem: Array = []
		var hr: Array = []
		for k in 31:
			hem.append(mant.call(k / 30.0, 1.0))
			hr.append(0.008)
		Loft.tube(mt, hem, hr, K_LINE, 4, 1)
		_on("UpperChest", mt)
	# ---- bel kuşağı, etek, bacaklar (tam beden)
	if tier >= 4:
		var kz = MB.new()
		kz.add_xf("torus", Transform3D(Basis.from_scale(Vector3(0.5, 0.13, 0.39)), Vector3(0, 1.02, 0.005)), _t(K_FLESH, 0.62), 18)   # obi
		kz.add("sphere", Vector3(0.07, 1.02, 0.185), Vector3(0.09, 0.07, 0.05), _t(K_FLESH, 0.62), Vector3.ZERO, 6)                  # düğüm
		for k in 2:
			_blade(kz, Vector3(0.07, 1.0, 0.19), Vector3(0.05 + k * 0.07, 0.72 - k * 0.05, 0.2), 0.03, Vector3(0, 0.1, 1).normalized(), _t(K_FLESH, 0.62), 0.5, 0.6)
		var long = 0.52 if tier >= 5 else 0.42
		if armor == 1:   # keşiş: önü yırtmaçlı uzun cübbe eteği
			var robe = func(u: float, v: float) -> Vector3:
				var ang = lerpf(-2.95, 2.95, u)
				return Vector3(sin(ang) * lerpf(0.2, 0.3, v), 1.0 - v * (long + 0.08) - 0.02 * v * absf(sin(ang * 6.0)), -cos(ang) * lerpf(0.155, 0.25, v))
			_patch(kz, robe, 26, 4, _t(K_FLESH, 0.75))
			var hem2: Array = []
			var hr2: Array = []
			for k in 27:
				hem2.append(robe.call(k / 26.0, 1.0))
				hr2.append(0.008)
			Loft.tube(kz, hem2, hr2, K_LINE, 4, 1)
		else:            # kusazuri: belden sarkan plaka perdeleri
			for k in 8:
				var a = TAU * (k + 0.5) / 8.0
				var out = Vector3(sin(a), 0, cos(a))
				var tg = Vector3(cos(a), 0, -sin(a))
				var top = Vector3(sin(a) * 0.22, 0.99, cos(a) * 0.17)
				for r in 3:
					var rr = float(r)
					var pl = func(u: float, v: float) -> Vector3:
						var d = (rr + v) / 3.0
						return top + out * (0.1 * d + 0.012 * rr) + Vector3(0, -long * d, 0) + tg * (u - 0.5) * 2.0 * (0.07 + 0.03 * d) + out * 0.015 * sin(PI * u)
					_patch(kz, pl, 3, 1, _t(K_PLATE, 1.0 if (r + k) % 2 == 0 else 0.82))
				if armor == 2:
					_spike(kz, top + out * 0.1 + Vector3(0, -long, 0), out + Vector3(0, -1.2, 0), 0.1, 0.025, K_BONE)
		_on("Hips", kz)
		for sd in ["Left", "Right"]:
			var sx = 1.0 if sd == "Left" else -1.0
			var ul = _bp(sd + "UpperLeg"); var ll = _bp(sd + "LowerLeg"); var ft = _bp(sd + "Foot"); var toe = _bp(sd + "Toes")
			var th = MB.new()   # hakama: bol paça
			_vtube(th, [ul + Vector3(0, -0.02, 0), ul.lerp(ll, 0.5), ll + Vector3(0, 0.03, 0)], [Vector2(0.125, 0.13), Vector2(0.125, 0.13), Vector2(0.1, 0.105)], _t(K_FLESH, 0.75), 12, 3)
			_on(sd + "UpperLeg", th)
			var lg = MB.new()   # suneate: baldır zırhı + diz kapağı
			_vtube(lg, [ll + Vector3(0, -0.02, 0), ll.lerp(ft, 0.45), ft + Vector3(0, 0.03, 0)], [Vector2(0.088, 0.092), Vector2(0.096, 0.102), Vector2(0.07, 0.075)], K_PLATE, 12, 3)
			lg.add("sphere", ll + Vector3(0, 0.0, 0.06), Vector3(0.13, 0.12, 0.09), K_PLATE, Vector3.ZERO, 8)
			_spike(lg, ll + Vector3(0, 0.03, 0.08), Vector3(0, 1, 0.35), 0.11, 0.035, K_BONE if armor == 2 else K_PLATE, Vector3.ZERO, 0.6)
			_on(sd + "LowerLeg", lg)
			var fm = MB.new()
			Loft.tube(fm, [ft + Vector3(0, -0.01, -0.05), ft + Vector3(0, -0.045, 0.07), toe + Vector3(0, -0.07, 0.07)], [Vector2(0.07, 0.07), Vector2(0.08, 0.058), Vector2(0.062, 0.036)], _t(K_FLESH, 0.8), 10, 3)
			_on(sd + "Foot", fm)
	# ---- sol el silahları
	var wp = String(cfg.get("weapon", "kilic"))
	if wp in ["yay", "kalkan"]:
		var lh: Vector3 = _bp("LeftHand")
		var m2 = MB.new()
		if wp == "yay":   # uzun asimetrik yay (yumi) + kiriş
			var bp2: Array = []
			var br: Array = []
			for k in 11:
				var a0 = lerpf(-1.25, 1.25, k / 10.0)
				bp2.append(lh + Vector3(sin(a0) * 0.44 + 0.03, 0.0, 0.2 - cos(a0) * 0.16))
				br.append(0.022 - 0.014 * absf(a0) / 1.25)
			Loft.tube(m2, bp2, br, K_FLESH, 6, 2)
			_shaft(m2, bp2[0], bp2[10], 0.004, K_LINE)
		else:   # Yata Aynası: kalkan diski, kenar halkası, ortada üç tomoe + sarmal
			var sc = _bp("LeftLowerArm").lerp(lh, 0.7) + Vector3(0, 0.1, 0)
			m2.add("cyl", sc, Vector3(0.6, 0.03, 0.6), _t(K_FLESH, 0.85), Vector3.ZERO, 24)
			m2.add_xf("torus", Transform3D(Basis.from_scale(Vector3(0.62, 0.07, 0.62)), sc), K_LINE, 24)
			m2.add_xf("torus", Transform3D(Basis.from_scale(Vector3(0.38, 0.03, 0.38)), sc + Vector3(0, 0.016, 0)), K_LINE, 20)
			for k in 3:
				var a = TAU * k / 3.0
				m2.add("sphere", sc + Vector3(sin(a) * 0.09, 0.018, cos(a) * 0.09), Vector3(0.07, 0.022, 0.07), K_LINE, Vector3.ZERO, 8)
				m2.add("sphere", sc + Vector3(sin(a + 0.6) * 0.115, 0.018, cos(a + 0.6) * 0.115), Vector3(0.04, 0.018, 0.04), K_LINE, Vector3.ZERO, 6)
		_on("LeftHand" if wp == "yay" else "LeftLowerArm", m2)
	# ---- kanatlar (Mükemmel Susanoo)
	if tier >= 5 and cfg.get("wings", true):
		var wm = MB.new()
		_wings(wm)
		_on("UpperChest", wm)


## Tüylü kanatlar (Kakashi / Sasuke'nin Mükemmel Susanoo'su): omuzdan yukarı-dışa uzanan kanat kemiği, üç sıra üst üste binen tüy
func _wings(m: MB) -> void:
	for sx in [-1.0, 1.0]:
		var cp = [Vector3(0.1 * sx, 1.4, -0.2), Vector3(0.75 * sx, 2.0, -0.36), Vector3(1.55 * sx, 2.14, -0.44), Vector3(2.3 * sx, 1.82, -0.48)]
		var L = func(s: float) -> Vector3:
			var q = clampf(s, 0.0, 0.9999) * 3.0
			var i = int(q)
			return Loft._cr(cp[maxi(0, i - 1)], cp[i], cp[i + 1], cp[mini(3, i + 2)], q - i)
		Loft.tube(m, cp, [0.075, 0.062, 0.045, 0.015], _t(K_FLESH, 0.8), 8, 4)
		# [tüy sayısı, kökte boy, uçta boy, kemikten aşağı kayma, ton]: üstte kısa örtü tüyleri, altta uzun uçuş tüyleri
		var rows = [[15, 0.26, 0.3, 0.0, 1.0], [15, 0.28, 0.34, 0.17, 0.84], [16, 0.3, 0.4, 0.34, 1.0], [16, 0.36, 0.55, 0.52, 0.84], [17, 0.5, 1.0, 0.72, 1.0]]
		for r in rows.size():
			var rw = rows[r]
			var n = int(rw[0])
			for i in n:
				var s = (i + 0.5) / n
				var dir = Vector3(sx * lerpf(0.04, 0.9, s * s), -1.0, 0.0).normalized()
				var fall = float(rw[3]) * lerpf(1.0, 0.75, s)
				var base: Vector3 = L.call(s) + dir * fall + Vector3(0, 0, 0.012 * (rows.size() - r))
				var ln = lerpf(float(rw[1]), float(rw[2]), s) * (0.9 + 0.2 * fposmod(sin(i * 12.9898 + r * 78.233) * 43758.5453, 1.0))
				var w = 2.4 / n * 0.62
				var tone = float(rw[4]) * (1.0 if i % 2 == 0 else 0.88)
				var last = r == rows.size() - 1
				_blade(m, base, base + dir * ln, w if not last else w * 0.85, Vector3(0, 0, 1), _t(K_FLESH, tone), 0.8, 0.0 if last else 0.55)
				if last:
					for zz in [0.004, -0.004]:   # uçuş tüyünün sapı (iki yüzden de görünür)
						_blade(m, base + Vector3(0, 0, zz), base + dir * ln * 0.94 + Vector3(0, 0, zz), 0.006, Vector3(0, 0, 1), K_LINE, 1.0, 0.4)


## Alev aurası: gövdenin çevresinden yukarı savrulan chakra alevleri (Susanoo'nun silueti) + İnsansı kademede yere değen alev tabanı
func _aura() -> void:
	var h = TIER_HEIGHT[tier] / scale.x if scale.x > 0.0 else 1.8   # yerel (ölçeksiz) boy: model 1.8
	h = 1.8
	var pp = GPUParticles3D.new()
	pp.amount = 40 + tier * 10
	pp.lifetime = 1.1
	pp.local_coords = true
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	var ext = Vector3(0.42, 0.55, 0.3) if tier >= 3 else Vector3(0.34, 0.45, 0.26)
	pm.emission_box_extents = ext
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.35
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0, 0.6, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.2, Color(1, 1, 1, 0.75))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var gt = GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	pp.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(0.12, 0.3)
	var fm = StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.vertex_color_use_as_albedo = true
	fm.albedo_texture = EyeTrail._dot()
	fm.albedo_color = Color(color().r * 0.6, color().g * 0.6, color().b * 0.6, 0.22)   # çok sayıda örtüşen alev beyaza doymasın
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = fm
	pp.draw_pass_1 = q
	pp.position = Vector3(0, (0.95 if tier != 3 else 1.25) * (1.0 if tier >= 3 else 1.0), 0)
	pp.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 5, 4))
	pp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pp)
	if tier in [2, 3]:   # yere yapışık iskelet/İnsansı: bel hizasında yerden yükselen alev tabanı
		var bp2 = pp.duplicate()
		var pm2: ParticleProcessMaterial = pm.duplicate()
		pm2.emission_box_extents = Vector3(0.55, 0.06, 0.4)
		pm2.initial_velocity_min = 0.5
		pm2.initial_velocity_max = 1.1
		bp2.process_material = pm2
		bp2.position = Vector3(0, 0.98, 0)
		bp2.amount = 50
		add_child(bp2)


## Dev savuruş (sol tık). Hasar ve menzil kademeyle büyür.
func swipe(owner_f: Node3D, dir: Vector3) -> void:
	swing_t = 0.0
	body.play(["slash_a", "slash_b", "hook"].pick_random() if tier >= 3 else "hook", 0.05, 1.3, true)
	var H = TIER_HEIGHT[tier]
	var reach = maxf(3.0, H * 0.75)
	# savuruş önündeki yelpaze alanın tamamına iner (yerdeki küçük hedef dahil)
	var gp = owner_f.global_position
	var info = {"dmg": 16.0 * tier * Stats.melee_mult(Game.profile), "knock": 12.0 + tier * 4.0, "launch": 4.0, "kind": "heavy", "dir": dir}
	get_tree().create_timer(0.18 if tier < 3 else 0.3).timeout.connect(func():
		if is_instance_valid(owner_f):
			Combat.hit_zone(owner_f, gp, dir, reach, 75.0, H * 1.1, info)
			for k in 3:
				var q = gp + dir.rotated(Vector3.UP, deg_to_rad((k - 1) * 40.0)) * reach * 0.6
				q.y = Game.jutsu_floor(q.x, q.z)
				FX.impact(q + Vector3.UP * 0.5, color(), 0.8 + tier * 0.3)
			if tier >= 3:
				FX.ring(gp + Vector3.UP * 0.4 + dir * reach * 0.4, color(), reach * 0.6, 0.35)
				if Game.world:
					Game.world.env.add_shake(0.2 + tier * 0.1))
	var pt = gp + Vector3.UP * H * 0.35 + dir * reach * 0.6
	Sfx.play("whoosh", pt, 0.6, 0.8)


## Silah özel saldırısı (sağ tık): kılıç dalgası / ok / kalkan / mızrak
func special(owner_f: Node3D, dir: Vector3) -> void:
	var wp = String(cfg.get("weapon", "kilic"))
	if tier < 3 or wp == "yok":
		swipe(owner_f, dir)
		return
	swing_t = 0.0
	var base = owner_f.global_position + Vector3.UP * TIER_HEIGHT[tier] * 0.35
	match wp:
		"kilic":
			body.play("slash_c", 0.05, 1.2, true)
			Combat.hit_zone(owner_f, owner_f.global_position, dir, 24.0 + TIER_HEIGHT[tier] * 1.2, 22.0, TIER_HEIGHT[tier] * 1.1, {"dmg": 30.0 * tier, "knock": 18.0, "kind": "heavy", "dir": dir})
			FX.ring(base + dir * 6.0, color(), 6.0 + tier, 0.4, false, dir)
		"yay":   # Susanoo oku: yaydan dev chakra oku fırlar, yolu boyunca vurur, ucunda patlar
			body.play("throw", 0.05, 1.0, true)
			var reach = 40.0 + TIER_HEIGHT[tier] * 2.0
			_fly_bolt(owner_f, base, dir, reach, TIER_HEIGHT[tier] * 0.5, 0.35, {"dmg": 45.0 * tier, "knock": 10.0, "kind": "heavy", "dir": dir}, 1.4 + tier * 0.3)
			FX.speed_lines(base, dir)
		"kalkan":
			body.play("block", 0.05, 1.0, true)
			Buffs.add("susanoo_shield", 3.0, {"armor": 0.05})
			FX.ring(base, color(), 5.0, 0.6, false, dir)
		"mizrak":   # mızrak saplaması: önde uzanan dev chakra mızrak ucu
			body.play("jab", 0.05, 1.0, true)
			_fly_bolt(owner_f, base, dir, 6.0 + TIER_HEIGHT[tier] * 0.6, TIER_HEIGHT[tier] * 0.35, 0.12, {}, 0.0)
			Combat.hit_zone(owner_f, owner_f.global_position, dir, 6.0 + TIER_HEIGHT[tier] * 0.8, 14.0, TIER_HEIGHT[tier] * 1.1, {"dmg": 40.0 * tier, "knock": 22.0, "launch": 6.0, "kind": "heavy", "dir": dir})
	Sfx.play("boom", base, 0.8, 0.6)


## Mükemmel Susanoo / Zırhlı Savaşçı teknikleri (slottan): 0 Yasaka Magatama yağmuru, 1 Dev Kılıç Yarması, 2 Göğü Yaran Ok Yağmuru
const TECHS := [["Yasaka no Magatama", 60.0, 10.0, 4], ["Susanoo: Kılıç Yarması", 80.0, 14.0, 4], ["Susanoo: Gök Okları", 120.0, 22.0, 5]]
var tech_cd := [0.0, 0.0, 0.0]


func tech(owner_f: Node3D, i: int, aim: Vector3) -> void:
	var H = TIER_HEIGHT[tier]
	var base = owner_f.global_position + Vector3.UP * H * 0.55
	var dir = (aim - base)
	dir.y = clampf(dir.y, -dir.length() * 0.4, dir.length() * 0.2)
	dir = dir.normalized() if dir.length() > 0.1 else -owner_f.global_transform.basis.z
	swing_t = 0.0
	match i:
		0:   # Yasaka Magatama: elden dönen magatama çarkları fışkırır, yelpaze gibi yayılıp hedefi döver
			body.play("throw", 0.05, 1.0, true)
			for k in 9:
				var a = deg_to_rad(lerpf(-28.0, 28.0, k / 8.0))
				var d2 = dir.rotated(Vector3.UP, a)
				get_tree().create_timer(k * 0.06).timeout.connect(func():
					if is_instance_valid(owner_f):
						_magatama(owner_f, base + d2 * H * 0.2, d2, 30.0 + H * 1.2))
		1:   # Dev kılıç yarması: kılıç yukarıdan iner, önünde yer yarılır, uzun hilal dalga ilerler
			body.play("slash_c", 0.05, 0.8, true)
			get_tree().create_timer(0.35).timeout.connect(func():
				if not is_instance_valid(owner_f):
					return
				var gp = owner_f.global_position
				for k in 14:
					var q = gp + dir * (H * 0.3 + k * H * 0.12)
					q.y = Game.jutsu_floor(q.x, q.z)
					get_tree().create_timer(k * 0.04).timeout.connect(func():
						FX.impact(q + Vector3.UP * 0.5, color(), H * 0.05)
						FX.ring(q + Vector3.UP * 0.3, color(), H * 0.16, 0.5)
						Combat.hit_sphere(owner_f, q + Vector3.UP * 2.0, H * 0.08 + 2.0, {"dmg": 70.0 * tier, "knock": 30.0, "launch": 10.0, "kind": "heavy", "dir": dir}))
				FX.ring(base + dir * H * 0.5, color(), H * 0.6, 0.45, false, dir)
				_crescent(owner_f, owner_f.global_position + Vector3.UP * H * 0.25, dir, H * 2.2)
				if Game.world:
					Game.world.env.add_shake(1.2))
		2:   # Gök okları: göğe çekilen yaydan yükselen oklar hedef bölgeye yağmur gibi iner
			body.play("throw", 0.05, 0.8, true)
			var zone = aim
			zone.y = Game.jutsu_floor(zone.x, zone.z)
			for k in 18:
				var off = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * (6.0 + H * 0.12)
				var land = zone + off
				var from = land + Vector3(randf_range(-4, 4), 60.0 + H, randf_range(-4, 4))
				get_tree().create_timer(0.4 + k * 0.07).timeout.connect(func():
					if is_instance_valid(owner_f):
						_fly_bolt(owner_f, from, (land - from).normalized(), from.distance_to(land), H * 0.25, 0.35, {}, 0.0)
						get_tree().create_timer(0.35).timeout.connect(func():
							FX.impact(land + Vector3.UP, color(), H * 0.05)
							FX.ring(land + Vector3.UP * 0.3, color(), H * 0.1, 0.4)
							Combat.hit_sphere(owner_f, land + Vector3.UP, 5.0 + H * 0.04, {"dmg": 55.0 * tier, "knock": 16.0, "launch": 6.0, "kind": "heavy"})))
	Sfx.play("boom", base, 0.7, 0.7)


## Dönen magatama çarkı: üç virgül + halka, ileri uçar, yolu boyunca vurur
func _magatama(owner_f: Node3D, from: Vector3, dir: Vector3, dist: float) -> void:
	var mb = MB.new()
	var R = maxf(2.0, TIER_HEIGHT[tier] * 0.06)
	mb.add_xf("torus", Transform3D(Basis.from_scale(Vector3(R * 2.0, R * 0.3, R * 2.0)), Vector3.ZERO), Color.WHITE, 16)
	for k in 3:
		var a = TAU * k / 3.0
		mb.add("sphere", Vector3(cos(a), 0, sin(a)) * R * 0.55, Vector3(R * 0.45, R * 0.25, R * 0.45), Color.WHITE, Vector3.ZERO, 10)
		mb.add("cone", Vector3(cos(a + 0.6), 0, sin(a + 0.6)) * R * 0.7, Vector3(R * 0.2, R * 0.5, R * 0.1), Color.WHITE, Vector3(90, rad_to_deg(-a), 0), 6)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	mi.material_override = _fx_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = from
	var end = from + dir * dist
	var tw = mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "global_position", end, 0.7)
	tw.tween_property(mi, "rotation:y", TAU * 4.0, 0.7)
	var n = int(dist / 4.0)
	for k in n:
		var q = from + dir * (k * 4.0)
		get_tree().create_timer(0.7 * k / maxf(1.0, n)).timeout.connect(func():
			if is_instance_valid(owner_f):
				Combat.hit_sphere(owner_f, q, R + 1.0, {"dmg": 26.0 * tier, "knock": 8.0, "kind": "heavy", "dir": dir}))
	tw.chain().tween_callback(func():
		FX.impact(end, color(), R * 0.8)
		mi.queue_free())


## Fırlatılan chakra (magatama, ok, hilal): gövdeden çok daha yoğun ve parlak, uzaktan seçilsin
var _fxm: ShaderMaterial
func _fx_mat() -> ShaderMaterial:
	if _fxm == null:
		_fxm = mat.duplicate()
		_fxm.next_pass = null
		_fxm.set_shader_parameter("density", 4.0)
		_fxm.set_shader_parameter("glow", 2.2)
	return _fxm


## Hilal chakra dalgası: yere dik dev yay, ileri süzülür, yolundakileri biçer
func _crescent(owner_f: Node3D, from: Vector3, dir: Vector3, dist: float) -> void:
	var H = TIER_HEIGHT[tier]
	var mb = MB.new()
	var pts: Array = []
	var rr: Array = []
	for k in 13:
		var a = lerpf(-1.2, 1.2, k / 12.0)
		pts.append(Vector3(sin(a) * H * 0.35, cos(a) * H * 0.35 - H * 0.15, -cos(a) * H * 0.08))
		rr.append(Vector2(H * 0.02 * (1.0 - absf(a) / 1.3) + 0.2, H * 0.05 * (1.0 - absf(a) / 1.3) + 0.3))
	Loft.tube(mb, pts, rr, Color.WHITE, 8, 3)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	mi.material_override = _fx_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from)
	var tw = mi.create_tween()
	tw.tween_property(mi, "global_position", from + dir * dist, 0.9)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.05, 0.2)
	tw.tween_callback(mi.queue_free)
	for k in 10:
		var q = from + dir * (dist * k / 10.0)
		get_tree().create_timer(0.9 * k / 10.0).timeout.connect(func():
			if is_instance_valid(owner_f):
				Combat.hit_sphere(owner_f, q, H * 0.2, {"dmg": 60.0 * tier, "knock": 25.0, "launch": 8.0, "kind": "heavy", "dir": dir}))


## Uçan chakra oku / mızrak ucu: Susanoo malzemesinden uzun gövde + sivri uç; yol boyunca vurur, sonda patlama
func _fly_bolt(owner_f: Node3D, from: Vector3, dir: Vector3, dist: float, length: float, dur: float, hit: Dictionary, hit_r: float) -> void:
	var mb = MB.new()
	var L = maxf(2.0, length)
	mb.add_xf("cyl", Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(L * 0.04, L, L * 0.04)), Vector3(0, 0, -L * 0.5)), Color.WHITE, 8)
	mb.add_xf("cone", Transform3D(Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3(L * 0.12, L * 0.25, L * 0.12)), Vector3(0, 0, -L * 1.1)), Color.WHITE, 8)
	for sx in [-1.0, 1.0]:   # tüyler
		mb.add_xf("box", Transform3D(Basis(Vector3.FORWARD, sx * 0.5) * Basis.from_scale(Vector3(L * 0.12, L * 0.01, L * 0.18)), Vector3(0, 0, -L * 0.05)), Color.WHITE, 1)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	mi.material_override = _fx_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from)
	var end = from + dir * dist
	var tw = mi.create_tween()
	tw.tween_property(mi, "global_position", end, dur)
	if not hit.is_empty():
		var n = int(dist / 3.5)
		for i in n:
			Combat.hit_sphere(owner_f, from + dir * (4.0 + i * 3.5), hit_r, hit)
		tw.tween_callback(func():
			FX.impact(end, color(), 1.5 + tier * 0.5)
			Combat.hit_sphere(owner_f, end, hit_r * 3.0, hit))
	tw.tween_property(mi, "scale", Vector3.ONE * 0.05, 0.15)
	tw.tween_callback(mi.queue_free)


# ================================================================== Susanoo JUTSULARI (gerçek Susanoo)
## Susanoo teknikleri ayrı / geçici bir Susanoo yaratmaz: sahibinin GERÇEK Susanoo'sunu kullanır (oyuncu: V ile açtığı,
## kendi özelleştirdiği, ustalık kademesindeki; düşman: kendi Susanoo'su). Kapalıysa teknik onu açar ve açık kalır.
## Efektler Susanoo'nun elinden / ağzından çıkar, kolları hedefe göre pozlanır, boyu kademeyle büyür.
## Kanon kademe şartı: Totsuka / Yata / yay / magatama İnsansı Susanoo'da (Itachi, Sasuke), Indora'nın Oku Mükemmel Susanoo'da.
const JUTSU_TIER := {"susanoo": 1, "amaterasu_entenka": 1, "susanoo_kobushi": 2, "yasaka_no_magatama": 3, "enton_yasaka_no_magatama": 3,
	"totsuka_no_tsurugi": 3, "yata_no_kagami": 3, "susanoo_kagutsuchi_no_yumiya": 3, "susanoo_chidori": 3,
	"susanoo_gokakyu": 3, "susanoo_hozan": 3, "susanoo_tsukumo": 3, "indora_no_ya": 5,
	"kamui_shuriken": 3, "kyoso_enbu": 3}
var act_t = 0.0      # jutsu hareketi sürüyor (kullanıcı animasyonu eşlenmez)
var posed = false


static func need_tier(jid: String) -> int:
	return int(JUTSU_TIER.get(jid, 0))


## Oyuncu atmadan önce: Susanoo bu tekniği yapabilir mi (boş = evet, değilse nedeni)
static func gate_msg(jid: String, jname: String) -> String:
	var need = need_tier(jid)
	if need <= 0:
		return ""
	var mt = max_tier(Game.profile)
	if mt <= 0:
		return "%s Susanoo'nun tekniği: iki gözün de Mangekyō olmalı." % jname
	if mt < need:
		return "%s için Susanoo en az %d. kademe (%s) olmalı — Susanoo ustalığın henüz %d. kademede." % [jname, need, TIER_NAMES[need], mt]
	return ""


## Tekniği yapacak GERÇEK Susanoo (yoksa null: teknik atılmaz). Oyuncu: kapalıysa açılır. Düşman: kendi Susanoo'su
## (Ebedi Mangekyō sahibi gerekirse Mükemmel Susanoo'ya büyür).
static func of(c: Node3D, jid := "") -> Susanoo:
	if c == null or not is_instance_valid(c):
		return null
	var need = maxi(1, need_tier(jid))
	var sn: Susanoo = null
	if c == Game.player:
		var cb = c.get("combat")
		var ey = cb.modes.eyes if cb and cb.modes else null
		if ey == null:
			return null
		if ey.susanoo and not is_instance_valid(ey.susanoo_node):
			ey.susanoo = false   # model yenilenince Susanoo düğümü gitmiş: yeniden açılsın
		if not ey.susanoo:
			ey._start_susanoo()
		if ey.susanoo and is_instance_valid(ey.susanoo_node):
			sn = ey.susanoo_node
		if sn and sn.tier < need:
			Hud.msg("Susanoo kademe tercihin düşük (%d): bu teknik %d. kademe ister." % [sn.tier, need], Color(1, 0.6, 0.5))
			return null
	elif c is Enemy:
		var kind = int(c.get_meta("eyes").get("kind", 0)) if c.has_meta("eyes") else 0
		var cur = c.get_meta("ea_susanoo") if c.has_meta("ea_susanoo") else null
		if (cur == null or not is_instance_valid(cur)) and kind in [4, 5] and (kind == 5 or float(c.get_meta("ms_blind", 0.0)) < 1.0):
			EnemyArts._susanoo(c)
			cur = c.get_meta("ea_susanoo") if c.has_meta("ea_susanoo") else null
		if cur and is_instance_valid(cur) and cur.tier < need and kind == 5:
			cur.build(EnemyArts.random_susanoo(c), need, c.get("model"))
		if cur and is_instance_valid(cur) and cur.tier >= need:
			sn = cur
	if sn == null or sn.body == null or sn.body.skel == null:
		return null
	sn.warm_bones()
	return sn


func h() -> float:
	return TIER_HEIGHT[tier]


## Dünya yönü -> iskelet uzayı yönü (PoseOverlay cast_pose bu uzayda çalışır)
func sk_dir(w: Vector3) -> Vector3:
	return (body.skel.global_transform.basis.inverse() * w).normalized()


## Kemiğin SON pozdaki dünya konumu: BoneAttachment3D poz katmanı (PoseOverlay kol pozları) uygulandıktan sonra güncellenir
## (get_bone_global_pose katmansız animasyon pozunu veriyordu: el yerin altında hesaplanıyordu)
var _ba := {}
func bone_at(bone: String) -> Vector3:
	var sk = body.skel
	var bi = sk.find_bone(bone)
	if bi < 0:
		return global_position + Vector3.UP * h() * 0.6
	var ba = _ba.get(bone)
	if ba == null or not is_instance_valid(ba):
		ba = BoneAttachment3D.new()
		ba.bone_name = bone
		sk.add_child(ba)
		_ba[bone] = ba
		return sk.global_transform * sk.get_bone_global_pose(bi).origin
	return (ba as Node3D).global_position


## Kemiğe bağlı düğüm (son pozu izler, Susanoo ölçeğiyle büyür): Entenka alevleri vb. buna eklenir
func attach(bone: String) -> Node3D:
	if body == null or body.skel == null or body.skel.find_bone(bone) < 0:
		return null
	bone_at(bone)
	return _ba.get(bone)


## Jutsu başlamadan kemik izleyicilerini hazırla (ilk karede de doğru konum)
func warm_bones() -> void:
	for b in ["RightHand", "LeftHand", "RightMiddleProximal", "LeftMiddleProximal", "RightUpperArm", "LeftUpperArm", "LeftLowerArm", "RightLowerArm", "Head"]:
		bone_at(b)


## Avuç ortası (bilek ile orta parmak kökü arası)
func hand(right := true) -> Vector3:
	var s = "Right" if right else "Left"
	var a = bone_at(s + "Hand")
	if body.skel.find_bone(s + "MiddleProximal") >= 0:
		return a.lerp(bone_at(s + "MiddleProximal"), 0.7)
	return a


## Ağız (kafa kemiğinin önü)
func mouth(fwd: Vector3) -> Vector3:
	return bone_at("Head") + fwd * h() * 0.06 - Vector3.UP * h() * 0.01


## Animasyonla hareket (savuruş, fırlatma) — kullanıcı animasyonu hold sn boyunca eşlenmez
func perform(anim: String, speed := 1.0, hold := 0.8) -> void:
	swing_t = -1.0
	act_t = maxf(act_t, hold)
	body.play(anim, 0.06, speed, true)


## Kol pozu (dünya yönleriyle): cp = {"arms": [[kemik, dünya yönü], ...], "spine", "twist", "neck"}; hold sn sürer
func pose(cp: Dictionary, hold: float, snap := false) -> void:
	if body.overlay == null:
		return
	var out = cp.duplicate()
	var arms = []
	for a in cp.get("arms", []):
		arms.append([a[0], sk_dir(a[1])])
	out["arms"] = arms
	body.overlay.cast_pose = out
	if snap:
		body.overlay.snap("cast", 1.0)
	else:
		body.overlay.set_pose("cast", 1.0)
	body.overlay.speed = 7.0
	swing_t = -1.0
	act_t = maxf(act_t, hold)
	posed = true


## Kolun üç kemiği aynı yöne (uzanmış kol) ya da üst kol / ön kol ayrı yönlere
static func arm(right: bool, upper: Vector3, lower := Vector3.ZERO, hand_d := Vector3.ZERO) -> Array:
	var s = "Right" if right else "Left"
	var lo = lower if lower != Vector3.ZERO else upper
	return [[s + "UpperArm", upper], [s + "LowerArm", lo], [s + "Hand", hand_d if hand_d != Vector3.ZERO else lo]]


## Susanoo'nun kendi silahı (kılıç / mızrak) teknik süresince gizlenir (el başka bir şey tutuyor)
func hide_weapons(dur: float) -> void:
	# görünürlük _place_weapons'ta yenilendiği için katman maskesi sıfırlanır (hiçbir kamera çizmez), sonra geri verilir
	var hidden = []
	for w in body.weapons:
		for root in [w.get("node"), w.get("sheath")]:
			if root == null or not is_instance_valid(root):
				continue
			var geos = (root as Node).find_children("*", "GeometryInstance3D", true, false)
			if root is GeometryInstance3D:
				geos.append(root)
			for m in geos:
				if m.layers != 0:
					hidden.append([m, m.layers])
					m.layers = 0
	get_tree().create_timer(dur).timeout.connect(func():
		for hm in hidden:
			if is_instance_valid(hm[0]):
				hm[0].layers = hm[1])


## Efekt düğümü teknik boyunca Susanoo'nun bir noktasına bağlı kalır: at_fn() konum, look_fn() yön (Vector3, boşsa yön değişmez)
func follow_fx(n: Node3D, dur: float, at_fn: Callable, look_fn := Callable(), up := Vector3.UP) -> void:
	var upd = func(_x: float):
		if not (is_instance_valid(n) and is_instance_valid(self) and n.is_inside_tree()):
			return
		n.global_position = at_fn.call()
		if look_fn.is_valid():
			var d: Vector3 = look_fn.call()
			if d.length() > 0.001 and absf(d.normalized().dot(up.normalized())) < 0.995:
				n.global_basis = Basis.looking_at(d, up).scaled(n.global_basis.get_scale())
	upd.call(0.0)
	n.create_tween().tween_method(upd, 0.0, 1.0, dur)


## Susanoo malzemesinden parlak parça (gövdeden yoğun: uzaktan seçilsin)
func chakra_mesh(mb: MB, extra_glow := 1.0) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	var m = _fx_mat()
	if extra_glow != 1.0:
		m = m.duplicate()
		m.set_shader_parameter("glow", 2.2 * extra_glow)
		m.set_shader_parameter("density", 4.0 * extra_glow)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Susanoo renginde akan sıvı-alev malzemesi (Totsuka'nın ruh kılıcı, Chidori'nin çekirdeği)
func flame_mat(core := Color(1, 1, 1)) -> ShaderMaterial:
	var m = VFX.mat_fire("fire", 3.2, 2.2, 0.3, 1.7, 0.18, Vector3(0, 0, 1), true)
	var c = color()
	m.set_shader_parameter("c_core", core)
	m.set_shader_parameter("c_hot", c.lightened(0.55))
	m.set_shader_parameter("c_mid", c.lightened(0.15))
	m.set_shader_parameter("c_edge", c.darkened(0.2))
	m.set_shader_parameter("c_line", c.darkened(0.65))
	m.set_shader_parameter("streak", 0.6)
	m.set_shader_parameter("inner_lines", 0.6)
	return m


var face_owner: Node3D   # verilirse Susanoo her kare sahibinin baktığı yöne döner (geçici Susanoo teknikleri)


func _process(dt: float) -> void:
	if body == null:
		return
	if face_owner and is_instance_valid(face_owner) and "facing" in face_owner:
		rotation.y = face_owner.facing
	# yere gömülü kademeler (iskelet/İnsansı): zeminin altı çizilmez (ayaklar yerden görünmesin)
	if mat and tier in [2, 3] and get_parent() is Node3D:
		mat.set_shader_parameter("ground_y", (get_parent() as Node3D).global_position.y - 0.15)
	# vuruş animasyonundaki ileri adım (kalça kayması) Susanoo'yu kullanıcıdan öne taşımasın: yerinde vurur
	var sk = body.skel
	var hb = sk.find_bone("Hips") if sk else -1
	if hb >= 0:
		# kalçanın dinlenme pozuna göre yatay kayması (iskelet uzayı) -> body uzayına çevir, tersini uygula
		var d: Vector3 = sk.get_bone_global_pose(hb).origin - sk.get_bone_global_rest(hb).origin
		# body uzayındaki kayma: kalçanın global konumu ile dinlenme konumu arasındaki fark (body yerel)
		var cur = body.to_local(sk.global_transform * sk.get_bone_global_pose(hb).origin) - body.position
		var rest = body.to_local(sk.global_transform * sk.get_bone_global_rest(hb).origin) - body.position
		var dd = cur - rest
		body.position = Vector3(-dd.x, 0.0, -dd.z)
	for k in tech_cd.size():
		tech_cd[k] = maxf(0.0, tech_cd[k] - dt)
	if act_t > 0.0:
		# jutsu hareketi (Totsuka saplaması, yay germe...): kullanıcının animasyonu eşlenmez, poz bitince bırakılır
		act_t -= dt
		if act_t <= 0.0 and posed and body.overlay:
			body.overlay.set_pose("cast", 0.0)
			posed = false
	elif swing_t >= 0.0:
		swing_t += dt
		if swing_t > 0.6:
			swing_t = -1.0
	elif follow and is_instance_valid(follow) and follow.current != "":
		var pl = get_parent()
		var flying = pl != null and pl.has_method("is_flying") and pl.is_flying()
		if flying and tier >= 4:
			# uçuş: süzülme pozu (kollar hafif açık, gövde öne eğik), koşu animasyonu yok
			body.play("air", 0.3, 0.4)
			if body.overlay:
				body.overlay.set_pose("leap", 0.8)
			var hv = Vector3(pl.velocity.x, 0, pl.velocity.z).length() if "velocity" in pl else 0.0
			body.rotation.x = lerpf(body.rotation.x, -clampf(hv / 40.0, 0.0, 0.45), minf(1.0, dt * 3.0))
		else:
			if body.overlay:
				body.overlay.set_pose("leap", 0.0)
			body.rotation.x = lerpf(body.rotation.x, 0.0, minf(1.0, dt * 4.0))
			# dev adım: kullanıcı küçük adımlarla koşarken dev beden aynı döngüyü oynarsa bir adımda kalıyordu —
			# animasyonu boyla yavaşlat (adım boyu ~ ölçek), ağır ve görkemli yürüsün
			var sp = follow.anim.speed_scale if follow.anim else 1.0
			var k = clampf(3.0 / maxf(1.0, scale.x), 0.12, 1.0) if follow.current in ["walk", "jog", "run"] else 1.0
			body.play(follow.current, 0.25, sp * k)
