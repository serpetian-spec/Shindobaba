class_name Susanoo
extends Node3D
## Susanoo: iki göz de Mangekyō/Ebedi Mangekyō iken V basılı. Ustalıkla kademe atlar:
## 1 Kaburga (omurga, kaburgalar, tek kol)  2 İskelet (kafatası, iki kol, parmaklar)
## 3 İnsansı (kaslı üst gövde, zırh, yüz, silah)  4 Zırhlı Savaşçı (tam beden)  5 Mükemmel Susanoo (devasa, kanatlı)
## Gerçek iskelet + gövde (CharacterModel) kullanır: oyuncuyla birlikte animasyon yapar.
## Özelleştirme (profile["susanoo"]): renk, zırh stili, yüz, silah, kanat, tercih edilen kademe.

const TIER_NAMES := ["", "Kaburga", "İskelet", "İnsansı", "Zırhlı Savaşçı", "Mükemmel Susanoo"]
const TIER_HEIGHT := [0.0, 2.05, 4.8, 7.5, 13.0, 34.0]   # 1: oyuncunun etrafını saran kaburga (kafasının üstünde değil)
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
	var m = float(config(pr).get("mastery", 0.0))
	var cap = 5 if (kr == 5 and kl == 5) else 3
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
	scale = Vector3.ONE * (TIER_HEIGHT[tier] / 1.8)


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


## Zırh, yüz, silah, kanat parçaları (kemiklere bağlı)
func _details(armor: int) -> void:
	if tier < 3:
		return
	var sk = body.skel
	var bp = func(n: String) -> Vector3: return sk.get_bone_global_rest(sk.find_bone(n)).origin
	var w = Color.WHITE
	# omuz zırhı
	for sd in ["Left", "Right"]:
		var sx = 1.0 if sd == "Left" else -1.0
		var ua: Vector3 = bp.call(sd + "UpperArm")
		var m = MB.new()
		match armor:
			0:
				for k in 3:
					m.add("box", ua + Vector3(0.04 * sx, 0.06 - k * 0.05, 0), Vector3(0.2, 0.035, 0.22), w, Vector3(0, 0, -22 * sx))
			1:
				m.add("sphere", ua + Vector3(0.02 * sx, 0.04, 0), Vector3(0.18, 0.12, 0.2), w, Vector3.ZERO, 10)
			2:
				for k in 3:
					m.add("cone", ua + Vector3((0.02 + k * 0.05) * sx, 0.08, -0.04 + k * 0.04), Vector3(0.035, 0.16, 0.035), w, Vector3(0, 0, -35 * sx), 6)
		_on(sd + "UpperArm", m)
		var la: Vector3 = bp.call(sd + "LowerArm")
		var g = MB.new()
		g.add("cyl", la + Vector3(0.12 * sx, 0, 0), Vector3(0.09, 0.16, 0.09), w, Vector3(0, 0, 90), 8)
		_on(sd + "LowerArm", g)
	# yüz
	var hd: Vector3 = bp.call("Head")
	var f = MB.new()
	match int(cfg.get("face", 0)):
		0:
			f.add("cone", hd + Vector3(0, 0.1, 0.2), Vector3(0.035, 0.16, 0.035), w, Vector3(80, 0, 0), 6)
			f.add("box", hd + Vector3(0, 0.25, 0.02), Vector3(0.22, 0.04, 0.24), w)
		1:
			for sx in [-1.0, 1.0]:
				f.add("cone", hd + Vector3(0.08 * sx, 0.3, 0.02), Vector3(0.035, 0.2, 0.035), w, Vector3(15, 0, -22 * sx), 6)
		2:
			f.add("box", hd + Vector3(0, 0.12, 0.13), Vector3(0.2, 0.035, 0.04), w)
			f.add("cone", hd + Vector3(0, 0.3, -0.02), Vector3(0.02, 0.18, 0.16), w, Vector3.ZERO, 4)
	_on("Head", f)
	# sol el silahları
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
		else:
			m2.add("cyl", lh + Vector3(0.12, 0, 0.05), Vector3(0.5, 0.04, 0.5), w, Vector3(0, 0, 90), 16)
			m2.add("sphere", lh + Vector3(0.15, 0, 0.05), Vector3(0.1, 0.1, 0.1), w, Vector3.ZERO, 8)
		_on("LeftHand", m2)
	# kanatlar + taç (mükemmel)
	if tier >= 5 and cfg.get("wings", true):
		var uc: Vector3 = bp.call("UpperChest")
		var wm = MB.new()
		for sx in [-1.0, 1.0]:
			for k in 7:
				var ang = deg_to_rad(-10 + k * 14)
				var length = 0.85 - k * 0.05
				var pos = uc + Vector3((0.15 + cos(ang) * length * 0.5) * sx, 0.15 + sin(ang) * length * 0.5, -0.18)
				wm.add("box", pos, Vector3(length, 0.09, 0.02), w, Vector3(0, 12 * sx, rad_to_deg(ang) * sx))
		_on("UpperChest", wm)
		var cr = MB.new()
		for k in 5:
			cr.add("cone", hd + Vector3((k - 2) * 0.05, 0.33 + (0.04 if k == 2 else 0.0), -0.02), Vector3(0.025, 0.12 + (0.06 if k == 2 else 0.0), 0.025), w, Vector3.ZERO, 5)
		_on("Head", cr)


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
		"yay":
			body.play("throw", 0.05, 1.0, true)
			for i in 14:
				Combat.hit_sphere(owner_f, base + dir * (4.0 + i * 3.5), 1.4, {"dmg": 45.0 * tier, "knock": 10.0, "kind": "heavy", "dir": dir})
			FX.speed_lines(base, dir)
		"kalkan":
			body.play("block", 0.05, 1.0, true)
			Buffs.add("susanoo_shield", 3.0, {"armor": 0.05})
			FX.ring(base, color(), 5.0, 0.6, false, dir)
		"mizrak":
			body.play("jab", 0.05, 1.0, true)
			for i in 5:
				Combat.hit_sphere(owner_f, base + dir * (2.0 + i * 2.5), 1.6, {"dmg": 40.0 * tier, "knock": 22.0, "launch": 6.0, "kind": "heavy", "dir": dir})
	Sfx.play("boom", base, 0.8, 0.6)


func _process(dt: float) -> void:
	if body == null:
		return
	if swing_t >= 0.0:
		swing_t += dt
		if swing_t > 0.6:
			swing_t = -1.0
	elif follow and is_instance_valid(follow) and follow.current != "":
		body.play(follow.current, 0.2, follow.anim.speed_scale if follow.anim else 1.0)
