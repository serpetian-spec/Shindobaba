class_name Susanoo
extends Node3D
## Susanoo: iki göz de Mangekyō/Ebedi Mangekyō iken V basılı. Ustalıkla kademe atlar:
## 1 Kaburga (omurga, kaburgalar, tek kol)  2 İskelet (kafatası, iki kol, parmaklar)
## 3 İnsansı (kaslı üst gövde, zırh, yüz, silah)  4 Zırhlı Savaşçı (tam beden)  5 Mükemmel Susanoo (devasa, kanatlı)
## Gerçek iskelet + gövde (CharacterModel) kullanır: oyuncuyla birlikte animasyon yapar.
## Özelleştirme (profile["susanoo"]): renk, zırh stili, yüz, silah, kanat, tercih edilen kademe.

const TIER_NAMES := ["", "Kaburga", "İskelet", "İnsansı", "Zırhlı Savaşçı", "Mükemmel Susanoo"]
const TIER_HEIGHT := [0.0, 2.05, 7.0, 16.0, 36.0, 78.0]   # 1: oyuncuyu saran kaburga .. 5: kuyruklu canavar boyunda Mükemmel Susanoo
## Kullanıcının Susanoo içindeki yeri (Susanoo boyuna oran): 3-4 göğüs, 5 alındaki mücevher (animedeki gibi)
const USER_SEAT := [0.0, 0.0, 0.0, 0.2, 0.64, 0.86]   # 3: kalça yere gömülü olduğundan göğüs alçakta
const ARMORS := ["Samuray", "Keşiş Cübbesi", "İblis Dikenleri"]
const FACES := ["Tengu", "Oni Boynuzlu", "Vizörlü Savaşçı"]
const WEAPONS := {"kilic": "Kılıç", "yay": "Yay ve Ok", "kalkan": "Kalkan", "mizrak": "Mızrak", "yok": "Silahsız"}
const COLORS := [[0.55, 0.35, 1.0], [0.25, 0.55, 1.0], [1.0, 0.35, 0.2], [0.3, 0.9, 0.5], [1.0, 0.8, 0.25], [0.95, 0.3, 0.6], [0.25, 0.95, 0.95], [0.85, 0.85, 0.95]]
const MASTERY_STEPS := [0.0, 0.0, 40.0, 120.0, 220.0, 400.0]   # kademe için gereken ustalık (sn)
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
	if not (kr in [4, 5] and kl in [4, 5]):
		return 0
	# Ebedi Mangekyō: tam beden (Zırhlı Savaşçı / Mükemmel Susanoo) hemen açık; Mangekyō ustalıkla en fazla İnsansı'ya çıkar
	if kr == 5 and kl == 5:
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


## Renk/kenar rengi/yoğunluk/parlaklık/akış: malzemeye uygula (menüde kaydırınca anında görünür)
func apply_look() -> void:
	if mat == null:
		return
	mat.set_shader_parameter("col", color())
	var rc: Array = cfg.get("rim_color", cfg.get("color", COLORS[0]))
	mat.set_shader_parameter("rim_col", Color(rc[0], rc[1], rc[2]))
	mat.set_shader_parameter("density", float(cfg.get("density", 1.0)))
	mat.set_shader_parameter("glow", float(cfg.get("glow", 1.0)))
	mat.set_shader_parameter("flow_speed", float(cfg.get("flow", 1.0)))


func build(pr: Dictionary, preview_tier := -1, follow_model: CharacterModel = null) -> void:
	cfg = config(pr)
	follow = follow_model
	tier = preview_tier if preview_tier > 0 else maxi(1, cur_tier(pr))
	for ch in get_children():
		ch.queue_free()
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/susanoo.gdshader")
	apply_look()
	var armor = int(cfg.get("armor", 0))
	var look = {"gender": "m", "age": "adult", "top_style": "uzun", "pants_style": "ninja", "hair_style": "kısa", "band": null, "sleeves": true,
		"vest": Color.WHITE if (tier >= 3 and armor != 1) else null}
	if tier >= 3 and armor == 1:
		look["outer_style"] = "palto"
		look["outer"] = Color.WHITE
	if tier >= 3 and cfg.get("weapon", "kilic") in ["kilic", "mizrak"]:
		look["weapon_r"] = "nodachi" if cfg.get("weapon", "kilic") == "kilic" else "mizrak"
	body = CharacterModel.new()
	add_child(body)
	body.setup(look)
	body.play("idle")
	# tüm parçalara susanoo malzemesi; kademeye göre gövde görünürlüğü
	var cut = 0.0
	if tier == 3:
		cut = 0.98   # üst gövde: kalçanın altı yok
	mat.set_shader_parameter("cut_y", cut)
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if tier <= 2:
			mi.visible = false
		var nm = String(mi.name).to_lower()
		if nm.contains("eye") or nm.contains("brow") or nm.contains("hair"):
			mi.visible = false
	if tier <= 2:
		_skeleton()
	_details(armor)
	_glow_eyes()
	_aura()
	scale = Vector3.ONE * (TIER_HEIGHT[tier] / 1.8)
	# İnsansı (üst gövde): kalça yere gömülü, gövde kullanıcının etrafında yerden yükselir (havada asılı durmasın)
	position.y = -0.95 * TIER_HEIGHT[tier] / 1.8 if tier in [2, 3] else 0.0   # iskelet + İnsansı: bacak yok, bel yerde


## Kemik "çubukları": gerçek iskeletten, kemiğe bağlı (animasyonla oynar)
func _skeleton() -> void:
	var sk = body.skel
	var bp = func(n: String) -> Vector3: return sk.get_bone_global_rest(sk.find_bone(n)).origin
	var back = Vector3(0, 0, -0.28) if tier == 1 else Vector3.ZERO   # kademe 1: omurga oyuncunun sırtının arkasında
	var stick = func(a: String, b: String, r: float) -> void:
		if sk.find_bone(a) < 0 or sk.find_bone(b) < 0:
			return
		var off = back if a in ["Hips", "Spine", "Chest", "UpperChest", "Neck"] else Vector3.ZERO
		var pa: Vector3 = bp.call(a) + off; var pb: Vector3 = bp.call(b) + off
		var m = MB.new()
		var d = pb - pa
		var basis = Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(r, d.length(), r))
		m.add_xf("cyl", Transform3D(basis, (pa + pb) * 0.5), Color.WHITE, 8)
		m.add("sphere", pb, Vector3.ONE * r * 1.5, Color.WHITE, Vector3.ZERO, 8)
		_on(a, m)
	for pair in BONES:
		stick.call(pair[0], pair[1], 0.07 if tier >= 2 else 0.05)
	var sides = ["Right"] if tier == 1 else ["Right", "Left"]
	for sd in sides:
		for pair in ARM_BONES:
			stick.call(sd + pair[0], sd + pair[1], 0.06 if tier >= 2 else 0.075)
		if tier >= 2:
			for f in FINGERS:
				stick.call(sd + "Hand", sd + f + "Proximal", 0.02)
				stick.call(sd + f + "Proximal", sd + f + "Intermediate", 0.018)
				stick.call(sd + f + "Intermediate", sd + f + "Distal", 0.016)
	# kaburgalar: göğüs kemiğine bağlı kavisli yaylar
	var ch: Vector3 = bp.call("Chest") + back
	var ribs = MB.new()
	var wide = 3.0 if tier == 1 else 1.0
	for i in 6:
		var y = (-0.12 + i * 0.075) * (2.0 if tier == 1 else 1.0)
		var w = (0.19 - absf(i - 2.5) * 0.012) * wide
		for k in 9:
			var a0 = lerpf(-PI * 0.95, PI * 0.95, float(k) / 9.0)
			var a1 = lerpf(-PI * 0.95, PI * 0.95, float(k + 1) / 9.0)
			var zc = w * 0.55 if tier == 1 else 0.02   # kademe 1: kaburga kafesinin merkezi oyuncunun göğsü
			var p0 = Vector3(sin(a0) * w, y - absf(sin(a0)) * 0.03, -cos(a0) * w * 0.8 + zc)
			var p1 = Vector3(sin(a1) * w, y - absf(sin(a1)) * 0.03, -cos(a1) * w * 0.8 + zc)
			var d = p1 - p0
			var rt = 0.03 if tier == 1 else 0.022
			ribs.add_xf("cyl", Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(rt, d.length(), rt)), ch + (p0 + p1) * 0.5), Color.WHITE, 5)
	_on("Chest", ribs)
	if tier >= 2:
		var hd: Vector3 = bp.call("Head")
		var skull = MB.new()
		skull.add("sphere", hd + Vector3(0, 0.12, 0.0), Vector3(0.24, 0.26, 0.27), Color.WHITE, Vector3.ZERO, 12)
		skull.add("box", hd + Vector3(0, 0.0, 0.07), Vector3(0.16, 0.06, 0.12), Color.WHITE)  # çene
		for sx in [-1.0, 1.0]:
			skull.add("sphere", hd + Vector3(0.05 * sx, 0.12, 0.12), Vector3(0.06, 0.05, 0.03), Color(0.2, 0.2, 0.2), Vector3.ZERO, 6)
		_on("Head", skull)


## Animedeki imza: kafatası/maske gözlerinde parlayan sarı ışık (kendi malzemesi, Susanoo renginden bağımsız)
static var _eye_mat: StandardMaterial3D
func _glow_eyes() -> void:
	if _eye_mat == null:
		_eye_mat = StandardMaterial3D.new()
		_eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_eye_mat.albedo_color = Color(1.0, 0.92, 0.45)
		_eye_mat.emission_enabled = true
		_eye_mat.emission = Color(1.0, 0.85, 0.3) * 2.5
	var hd: Vector3 = body.skel.get_bone_global_rest(body.skel.find_bone("Head")).origin
	var m = MB.new()
	for sx in [-1.0, 1.0]:
		var ep = hd + Vector3(0.052 * sx, 0.12, 0.125 if tier <= 2 else 0.14)
		m.add("sphere", ep, Vector3(0.05, 0.022, 0.02), Color.WHITE, Vector3(0, 0, -18 * sx), 8)
	if body.skel.find_bone("Head") < 0:
		return
	var mi = body._mesh_on("Head", m.build(null), Transform3D.IDENTITY)
	mi.material_override = _eye_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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


## Zırh, yüz, silah, kanat parçaları (kemiklere bağlı)
func _details(armor: int) -> void:
	if tier < 3:
		_skull_details()
		return
	var sk = body.skel
	var bp = func(n: String) -> Vector3: return sk.get_bone_global_rest(sk.find_bone(n)).origin
	var w = Color.WHITE
	var uc: Vector3 = bp.call("UpperChest")
	var ch: Vector3 = bp.call("Chest")
	var hp: Vector3 = bp.call("Hips")
	var nk: Vector3 = bp.call("Neck")
	var hd: Vector3 = bp.call("Head")
	# ---- göğüs zırhı (dō): gövdeyi saran kalın kabuk + yatay plaka bantları (insan gövdesini gizler)
	var t = MB.new()
	Loft.tube(t, [hp + Vector3(0, 0.08, 0.0), ch + Vector3(0, 0.0, 0.01), uc + Vector3(0, 0.06, 0.0), nk + Vector3(0, -0.02, -0.01)],
		[Vector2(0.2, 0.15), Vector2(0.23, 0.17), Vector2(0.27, 0.19), Vector2(0.17, 0.13)], w, 16, 3, true, true)
	for k in 5:
		var y = lerpf(hp.y + 0.12, uc.y + 0.06, k / 4.0)
		var rw = lerpf(0.21, 0.27, k / 4.0)
		t.add_xf("torus", Transform3D(Basis.from_scale(Vector3(rw * 2.1, 0.06, rw * 1.55)), Vector3(0, y, 0.01)), w, 18)
	# göğüste dikey orta sırt ve yaka plakası
	t.add("box", Vector3(0, (ch.y + uc.y) * 0.5, 0.19), Vector3(0.05, 0.3, 0.04), w)
	Loft.tube(t, [uc + Vector3(-0.2, 0.12, 0.02), nk + Vector3(0, 0.02, 0.12), uc + Vector3(0.2, 0.12, 0.02)], [0.04, 0.05, 0.04], w, 8, 3)
	# magatama kolyesi: boyunda halka + aşağı sarkan virgül taşları
	for k in 7:
		var a = lerpf(-1.1, 1.1, k / 6.0)
		var mp = nk + Vector3(sin(a) * 0.16, -0.08 - cos(a) * 0.04, cos(a) * 0.14)
		t.add("sphere", mp, Vector3(0.045, 0.045, 0.03), w, Vector3.ZERO, 8)
		t.add("cone", mp + Vector3(0.02 * sin(a), -0.04, 0), Vector3(0.025, 0.06, 0.02), w, Vector3(0, 0, 30 * sin(a)), 5)
	if armor == 1:   # keşiş: geniş kalın yaka halkası + dua tespihi
		t.add_xf("torus", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-20)) * Basis.from_scale(Vector3(0.55, 0.12, 0.45)), nk + Vector3(0, -0.04, 0.0)), w, 20)
	_on("Chest", t)
	# ---- omuz plakaları (ōsode): her omuzda 4 katmanlı, dışa ve aşağı açılan büyük dikdörtgen plakalar
	for sd in ["Left", "Right"]:
		var sx = 1.0 if sd == "Left" else -1.0
		var ua: Vector3 = bp.call(sd + "UpperArm")
		var m = MB.new()
		match armor:
			0, 1:
				for k in 4:
					var pc = ua + Vector3((0.05 + k * 0.01) * sx, 0.1 - k * 0.065, 0.0)
					m.add("box", pc, Vector3(0.26 - k * 0.01, 0.05, 0.3), w, Vector3(0, 0, -(28 + k * 6) * sx))
				m.add("sphere", ua + Vector3(0.02 * sx, 0.1, 0), Vector3(0.2, 0.12, 0.22), w, Vector3.ZERO, 10)   # omuz topu
			2:   # iblis: dikenli kubbe omuzluk
				m.add("sphere", ua + Vector3(0.03 * sx, 0.08, 0), Vector3(0.24, 0.18, 0.26), w, Vector3.ZERO, 10)
				for k in 4:
					m.add("cone", ua + Vector3((0.02 + k * 0.045) * sx, 0.16, -0.06 + k * 0.04), Vector3(0.04, 0.2, 0.04), w, Vector3(0, 0, -30 * sx), 6)
		_on(sd + "UpperArm", m)
		# kol koruyucu (kote): önkolu saran kalın plaka + bilek halkası; el: zırhlı pençe parmaklar
		var la: Vector3 = bp.call(sd + "LowerArm")
		var lh: Vector3 = bp.call(sd + "Hand")
		var g = MB.new()
		Loft.tube(g, [la.lerp(lh, 0.1), la.lerp(lh, 0.55), la.lerp(lh, 0.95)], [0.075, 0.085, 0.07], w, 10, 2, true, true)
		g.add_xf("torus", Transform3D(Basis(Quaternion(Vector3.UP, (lh - la).normalized())) * Basis.from_scale(Vector3(0.2, 0.05, 0.2)), la.lerp(lh, 0.92)), w, 12)
		for k in 3:
			g.add("cone", la.lerp(lh, 0.2 + k * 0.25) + Vector3(0.05 * sx, 0.04, 0), Vector3(0.025, 0.07, 0.025), w, Vector3(0, 0, -60 * sx), 5)
		_on(sd + "LowerArm", g)
		var hm = MB.new()
		hm.add("sphere", lh + Vector3(0.05 * sx, -0.02, 0.0), Vector3(0.11, 0.08, 0.12), w, Vector3.ZERO, 8)
		_on(sd + "Hand", hm)
	# ---- bel eteği (kusazuri): tam bedende kalçadan sarkan plaka perdeleri; kaburgadan daha zırhlı görünür
	if tier >= 4:
		var kz = MB.new()
		for k in 7:
			var a = lerpf(-PI * 0.9, PI * 0.9, k / 6.0)
			var c0 = hp + Vector3(sin(a) * 0.2, -0.08, cos(a) * 0.15)
			for r in 3:
				kz.add_xf("box", Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(-10 - r * 3)) * Basis.from_scale(Vector3(0.13, 0.08, 0.025)), c0 + Vector3(sin(a) * r * 0.015, -r * 0.075, cos(a) * r * 0.012)), w, 1)
		_on("Hips", kz)
		for sd in ["Left", "Right"]:   # baldır ve diz koruyucu
			var ll: Vector3 = bp.call(sd + "LowerLeg")
			var ft: Vector3 = bp.call(sd + "Foot")
			var lg = MB.new()
			Loft.tube(lg, [ll.lerp(ft, 0.05), ll.lerp(ft, 0.5), ll.lerp(ft, 0.95)], [0.09, 0.085, 0.07], w, 10, 2, true, true)
			lg.add("sphere", ll + Vector3(0, 0.02, 0.06), Vector3(0.12, 0.1, 0.08), w, Vector3.ZERO, 8)
			_on(sd + "LowerLeg", lg)
	# ---- yüz maskesi + miğfer: insan kafasını tamamen örter
	var f = MB.new()
	f.add("sphere", hd + Vector3(0, 0.11, 0.01), Vector3(0.27, 0.29, 0.3), w, Vector3.ZERO, 14)   # kafa kabuğu
	match int(cfg.get("face", 0)):
		0:   # tengu: uzun burun, keskin kaşlar, ağız yarığı
			f.add("cone", hd + Vector3(0, 0.08, 0.2), Vector3(0.05, 0.2, 0.05), w, Vector3(80, 0, 0), 8)
			for sx in [-1.0, 1.0]:
				f.add("box", hd + Vector3(0.06 * sx, 0.165, 0.15), Vector3(0.09, 0.02, 0.03), w, Vector3(0, 0, -20 * sx))
			f.add("box", hd + Vector3(0, 0.0, 0.15), Vector3(0.1, 0.015, 0.02), Color(0.2, 0.2, 0.2))
		1:   # oni: iki boynuz, dişler, çatık kaş
			for sx in [-1.0, 1.0]:
				f.add("cone", hd + Vector3(0.08 * sx, 0.3, 0.02), Vector3(0.045, 0.24, 0.045), w, Vector3(15, 0, -22 * sx), 6)
				f.add("cone", hd + Vector3(0.04 * sx, -0.005, 0.15), Vector3(0.02, 0.05, 0.02), w, Vector3(180, 0, 0), 5)
				f.add("box", hd + Vector3(0.06 * sx, 0.165, 0.15), Vector3(0.1, 0.025, 0.03), w, Vector3(0, 0, -28 * sx))
		2:   # vizörlü savaşçı: yatay vizör, alında dikey tepelik
			f.add("box", hd + Vector3(0, 0.12, 0.15), Vector3(0.24, 0.045, 0.05), w)
			f.add("cone", hd + Vector3(0, 0.32, -0.02), Vector3(0.025, 0.2, 0.18), w, Vector3.ZERO, 4)
	if tier >= 4:   # miğfer (kabuto): yanlara açılan boyun koruması + alında hilal tepelik (kuwagata)
		for k in 3:
			f.add_xf("torus", Transform3D(Basis.from_scale(Vector3(0.38 + k * 0.05, 0.05, 0.36 + k * 0.05)), hd + Vector3(0, 0.08 - k * 0.05, -0.02)), w, 16)
		for sx in [-1.0, 1.0]:
			f.add("cone", hd + Vector3(0.09 * sx, 0.33, 0.1), Vector3(0.03, 0.26, 0.03), w, Vector3(10, 0, -38 * sx), 5)
	_on("Head", f)
	# ---- sırt: omuzlardan yukarı savrulan zırh/alev pelerini (siluet: insan değil savaşçı ruh)
	var bk = MB.new()
	for k in 5:
		var a = lerpf(-0.9, 0.9, k / 4.0)
		bk.add("cone", uc + Vector3(sin(a) * 0.25, 0.18 + cos(a) * 0.05, -0.18), Vector3(0.07, 0.35 - absf(a) * 0.08, 0.03), w, Vector3(-25, 0, -rad_to_deg(a) * 0.6), 5)
	_on("UpperChest", bk)
	# ---- sol el silahları
	var wp = String(cfg.get("weapon", "kilic"))
	if wp in ["yay", "kalkan"]:
		var lh: Vector3 = bp.call("LeftHand")
		var m2 = MB.new()
		if wp == "yay":
			for k in 10:
				var a0 = lerpf(-1.2, 1.2, k / 10.0); var a1 = lerpf(-1.2, 1.2, (k + 1) / 10.0)
				var p0 = Vector3(0.1, sin(a0) * 0.55, cos(a0) * 0.18 - 0.18); var p1 = Vector3(0.1, sin(a1) * 0.55, cos(a1) * 0.18 - 0.18)
				var d = p1 - p0
				m2.add_xf("cyl", Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(0.025, d.length(), 0.025)), lh + (p0 + p1) * 0.5), w, 5)
		else:   # Yata Aynası: halkalı kalkan, ortada üç tomoe sarmalı
			m2.add("cyl", lh + Vector3(0.12, 0, 0.05), Vector3(0.6, 0.04, 0.6), w, Vector3(0, 0, 90), 20)
			m2.add_xf("torus", Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3(0.62, 0.06, 0.62)), lh + Vector3(0.15, 0, 0.05)), w, 20)
			for k in 3:
				var a = TAU * k / 3.0
				m2.add("sphere", lh + Vector3(0.16, sin(a) * 0.12, 0.05 + cos(a) * 0.12), Vector3(0.03, 0.07, 0.07), w, Vector3.ZERO, 8)
		_on("LeftHand", m2)
	# ---- kanatlar + taç (mükemmel)
	if tier >= 5 and cfg.get("wings", true):
		var wm = MB.new()
		for sx in [-1.0, 1.0]:
			for k in 8:
				var ang = deg_to_rad(-15 + k * 13)
				var length = 0.95 - k * 0.05
				var pos = uc + Vector3((0.15 + cos(ang) * length * 0.5) * sx, 0.15 + sin(ang) * length * 0.5, -0.2)
				wm.add("box", pos, Vector3(length, 0.1, 0.02), w, Vector3(0, 12 * sx, rad_to_deg(ang) * sx))
				wm.add("cone", pos + Vector3(cos(ang) * length * 0.5 * sx, sin(ang) * length * 0.5, 0), Vector3(0.05, 0.12, 0.02), w, Vector3(0, 0, rad_to_deg(ang) * sx - 90 * sx), 4)
		_on("UpperChest", wm)
		var cr = MB.new()
		for k in 5:
			cr.add("cone", hd + Vector3((k - 2) * 0.05, 0.4 + (0.04 if k == 2 else 0.0), -0.02), Vector3(0.025, 0.12 + (0.06 if k == 2 else 0.0), 0.025), w, Vector3.ZERO, 5)
		_on("Head", cr)


## İskelet kademeleri: boynuzlu kafatası, çene ve diş sırası, kalın omuz kemikleri
func _skull_details() -> void:
	if tier < 2:
		return
	var sk = body.skel
	var hd: Vector3 = sk.get_bone_global_rest(sk.find_bone("Head")).origin
	var w = Color.WHITE
	var m = MB.new()
	m.add("cone", hd + Vector3(0.0, 0.32, 0.06), Vector3(0.045, 0.2, 0.045), w, Vector3(20, 0, 0), 6)   # alında tek boynuz
	for sx in [-1.0, 1.0]:
		m.add("box", hd + Vector3(0.06 * sx, 0.17, 0.13), Vector3(0.09, 0.025, 0.03), w, Vector3(0, 0, -22 * sx))   # çatık kaş kemiği
		m.add("sphere", hd + Vector3(0.1 * sx, 0.04, 0.06), Vector3(0.05, 0.08, 0.08), w, Vector3.ZERO, 6)   # elmacık
	for k in 7:
		m.add("cone", hd + Vector3((k - 3) * 0.022, 0.02, 0.135), Vector3(0.012, 0.035, 0.012), w, Vector3(180, 0, 0), 4)   # üst dişler
	_on("Head", m)


func _on(bone: String, m: MB) -> void:
	if body.skel.find_bone(bone) < 0:
		return
	var mi = body._mesh_on(bone, m.build(null), Transform3D.IDENTITY)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Dev savuruş (sol tık). Hasar ve menzil kademeyle büyür.
func swipe(owner_f: Node3D, dir: Vector3) -> void:
	swing_t = 0.0
	body.play(["slash_a", "slash_b", "hook"].pick_random() if tier >= 3 else "hook", 0.05, 1.3, true)
	var reach = TIER_HEIGHT[tier] * 0.6
	var pt = owner_f.global_position + Vector3.UP * TIER_HEIGHT[tier] * 0.35 + dir * reach
	Combat.hit_sphere(owner_f, pt, 1.2 + tier * 0.9, {"dmg": 22.0 * tier * Stats.melee_mult(Game.profile), "knock": 12.0 + tier * 4.0, "launch": 4.0, "kind": "heavy", "dir": dir})
	FX.impact(pt, color(), 0.8 + tier * 0.3)
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
			for i in 8:
				Combat.hit_sphere(owner_f, base + dir * (3.0 + i * 3.0), 2.0 + tier * 0.4, {"dmg": 30.0 * tier, "knock": 18.0, "kind": "heavy", "dir": dir})
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
			for i in 5:
				Combat.hit_sphere(owner_f, base + dir * (2.0 + i * 2.5), 1.6, {"dmg": 40.0 * tier, "knock": 22.0, "launch": 6.0, "kind": "heavy", "dir": dir})
	Sfx.play("boom", base, 0.8, 0.6)


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
	mi.material_override = mat
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


func _process(dt: float) -> void:
	if body == null:
		return
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
	if swing_t >= 0.0:
		swing_t += dt
		if swing_t > 0.6:
			swing_t = -1.0
	elif follow and is_instance_valid(follow) and follow.current != "":
		body.play(follow.current, 0.2, follow.anim.speed_scale if follow.anim else 1.0)
