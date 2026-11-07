class_name Shinigami
extends Node3D
## Shinigami (Shiki Fūjin; ref _tmp/shikiref "Shinigami Infobox", "Reaper death seal"): insanın kat kat üstünde yarı saydam,
## çökük, şeytani yüzlü hayalet — uzun dağınık beyaz saç (önüne dökülür), saçtan çıkan iki kırmızı boynuz, mor ten, kırmızı yarık
## gözler, ağzında yatay tantō; iki yana açtığı kollarıyla yenlerini perde gibi tuttuğu geniş beyaz kimono; sol elinde kırmızı
## tespih; mühürlerken kolunda lanet işaretleri. Bacak yok (kimono aşağıda solar). Ön -Z, boy ~6.5 m.

const H := 6.5
const ROBE := Color(0.82, 0.82, 0.86)
const HAIR := Color(0.88, 0.88, 0.9)
const SKIN := Color(0.42, 0.33, 0.48)
const HORN := Color(0.8, 0.15, 0.15)

var mat: StandardMaterial3D
var seal_arm: Node3D        # sağ kol (mühürleyen): lanet işaretleri burada görünür
var seal_marks: MeshInstance3D
var alpha := 0.0


static func spawn(parent: Node, at: Vector3, yaw: float) -> Shinigami:
	var s = Shinigami.new()
	parent.add_child(s)
	s.global_position = at
	s.rotation.y = yaw
	return s


func _ready() -> void:
	mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1, 1, 1, 0.0)
	_build()
	scale = Vector3.ONE * (H / 6.5)


func _mi(parent: Node3D, b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(mat)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _build() -> void:
	var b = MB.new()
	# kimono gövdesi: omuzdan aşağı genişleyen, altta açık uçlu (bacak yok)
	Loft.tube(b, [Vector3(0, 0.4, 0.1), Vector3(0, 2.0, 0.05), Vector3(0, 3.6, 0.0), Vector3(0, 4.6, 0.0)], [Vector2(1.5, 0.9), Vector2(1.25, 0.75), Vector2(1.05, 0.62), Vector2(0.75, 0.48)], ROBE, 18, 4, false, true)
	# iki yana açılmış kollar + kolların altından perde gibi sarkan geniş yenler (ref: kimonoyu iki yana açar)
	for s in [-1.0, 1.0]:
		Loft.tube(b, [Vector3(s * 0.7, 4.45, 0.0), Vector3(s * 1.7, 4.55, -0.05), Vector3(s * 2.7, 4.6, -0.1)], [0.36, 0.42, 0.48], ROBE, 10, 3)
		# yen paneli: koldan aşağı uzanan geniş kumaş (dörtgen + alt kenarı kavisli)
		for k in 7:
			var x0 = lerpf(0.7, 2.75, k / 6.0) * s
			var x1 = lerpf(0.7, 2.75, (k + 1) / 6.0) * s
			var y_bot0 = 1.0 + sin(k / 6.0 * PI) * 0.3
			var y_bot1 = 1.0 + sin((k + 1) / 6.0 * PI) * 0.3
			var yb = (y_bot0 + y_bot1) * 0.5
			b.add("box", Vector3((x0 + x1) * 0.5, (4.52 + yb) * 0.5, 0.07), Vector3(absf(x1 - x0) + 0.02, 4.52 - yb, 0.05), ROBE.darkened(0.04 * (k % 2)))
		# eller: mor, kemikli parmaklar yenin ucunu kavrar
		Loft.blob(b, Vector3(s * 2.85, 4.6, -0.12), Vector3(s, 0, 0), 0.4, [Vector2(0.13, 0.08), Vector2(0.17, 0.1), Vector2(0.14, 0.08), Vector2(0.07, 0.05)], SKIN, 8)
		for f in 4:
			BeastRig.limb(b, Vector3(s * 3.05, 4.62 + (f - 1.5) * 0.06, -0.15), Vector3(s * 3.15, 4.45 + (f - 1.5) * 0.06, -0.25), 0.03, 0.02, SKIN, 5)
	# boyun + uzun çökük yüz (mor), kırmızı yarık gözler, çıkık elmacık
	Loft.blob(b, Vector3(0, 4.7, -0.12), Vector3(0, 1, -0.1), 1.25, [Vector2(0.22, 0.2), Vector2(0.3, 0.28), Vector2(0.26, 0.25), Vector2(0.15, 0.15)], SKIN, 12)
	for s in [-1.0, 1.0]:
		b.add("box", Vector3(s * 0.13, 5.38, -0.47), Vector3(0.22, 0.07, 0.05), Color(0.95, 0.08, 0.08), Vector3(0, 0, s * -25))   # kırmızı yarık göz
		b.add("sphere", Vector3(s * 0.15, 5.25, -0.43), Vector3(0.12, 0.08, 0.06), SKIN.darkened(0.2), Vector3.ZERO, 6)   # çökük yanak gölgesi
	# ağızda yatay tantō: sap solda, bıçak sağda (ref)
	b.add("box", Vector3(-0.45, 5.0, -0.48), Vector3(0.5, 0.08, 0.08), Color(0.2, 0.15, 0.12))
	b.add("cyl", Vector3(-0.18, 5.0, -0.48), Vector3(0.16, 0.03, 0.16), Color(0.55, 0.5, 0.35), Vector3(0, 0, 90), 8)
	b.add("box", Vector3(0.38, 5.0, -0.48), Vector3(1.05, 0.07, 0.02), Color(0.85, 0.87, 0.92))
	_mi(self, b)
	# saç: başın çevresinde dağınık sivri yele + önden ve yanlardan beline kadar dökülen uzun tutamlar
	var hb = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 4401
	for k in 46:
		var a = rng.randf() * TAU
		var base = Vector3(cos(a) * 0.28, 5.55 + rng.randf_range(-0.1, 0.3), sin(a) * 0.25)
		var dir = Vector3(cos(a), rng.randf_range(0.0, 0.9), sin(a)).normalized()
		var L = rng.randf_range(0.6, 1.2)
		Loft.tube(hb, [base, base + dir * L * 0.5, base + dir * L], [0.09, 0.06, 0.005], HAIR, 5, 2)
	for k in 26:   # uzun dökülen tutamlar (yüzün iki yanından gövdenin önüne)
		var side = -1.0 if k % 2 == 0 else 1.0
		var x = side * rng.randf_range(0.3, 0.65)   # yüzün iki yanından (ortadaki uzun mor yüz açık kalır — ref)
		var z = rng.randf_range(-0.28, 0.15)
		var top = Vector3(x * 0.6, 5.7, z * 0.5)
		var mid = Vector3(x * 1.15, 4.5, z - 0.2)
		var bot = Vector3(x * 1.2 + rng.randf_range(-0.1, 0.1), rng.randf_range(2.4, 3.4), z - 0.35)
		Loft.tube(hb, [top, mid, bot], [0.07, 0.08, 0.01], HAIR.darkened(0.04 * (k % 3)), 5, 3)
	for s in [-1.0, 1.0]:   # iki kırmızı boynuz (saçtan yukarı-dışa)
		Loft.tube(hb, [Vector3(s * 0.18, 5.85, 0.0), Vector3(s * 0.35, 6.2, -0.02), Vector3(s * 0.38, 6.5, -0.08)], [0.07, 0.05, 0.01], HORN, 6, 3)
	_mi(self, hb)
	# sol elde kırmızı tespih (sarkan boncuk dizisi)
	var bb = MB.new()
	for k in 22:
		var q = k / 21.0
		bb.add("sphere", Vector3(-3.05 + sin(q * PI) * 0.05, 4.5 - q * 1.1, -0.2 + sin(q * PI * 2.0) * 0.05), Vector3(0.07, 0.07, 0.07), Color(0.7, 0.12, 0.12), Vector3.ZERO, 6)
	_mi(self, bb)
	# mühürleyen sağ kol üstündeki lanet işaretleri (başta gizli)
	var mb = MB.new()
	for k in 14:
		var x = lerpf(0.9, 2.7, k / 13.0)
		mb.add("box", Vector3(x, 4.6 + (k % 2) * 0.12, -0.42), Vector3(0.08, 0.2, 0.02), Color(0.08, 0.06, 0.1), Vector3(0, 0, (k % 3 - 1) * 30))
	seal_marks = _mi(self, mb)
	seal_marks.visible = false


func fade(to: float, dur: float) -> void:
	var tw = create_tween()
	tw.tween_method(func(a: float):
		alpha = a
		mat.albedo_color = Color(1, 1, 1, a), alpha, to, dur)


func show_seal(on: bool) -> void:
	seal_marks.visible = on


## Kolun çıktığı yer (ağız altı, gövde önü)
func belly() -> Vector3:
	return global_transform * Vector3(0, 3.2, -0.6)
