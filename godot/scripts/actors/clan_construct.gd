class_name ClanConstruct
extends CharacterBody3D
## Klan çağrıları (hayvan sözleşmesi olmayanlar): savaş kuklası (chakra iplikleriyle), mürekkep canavarı,
## taş golem, dev eşek arısı. Sahibinin yanında durur, en yakın düşmana saldırır, süresi bitince dağılır.

var kind := "puppet"
var team = "player"
var radius = 0.45
var height = 1.6
var max_hp = 120.0
var hp = 120.0
var dead = false
var owner_f: Node3D = null
var tgt: Node3D = null
var dmg := 10.0
var life := 22.0
var cd := 0.5
var facing := 0.0
var speed := 13.0
var vis: Node3D
var threads: Array = []
var lunge_t := 0.0
var slot := 0


## c: çağıran, kind: puppet/ink/golem/bee, n: adet, d: jutsu verisi (hasar/kademe için)
static func spawn(c: Node3D, k: String, n: int, d: Dictionary) -> Array:
	var out = []
	var tier = int(d.get("tier", 2))
	var base = JutsuEngine.base_dmg(c, d)
	var fd: Vector3 = c.face_dir() if c.has_method("face_dir") else -c.global_transform.basis.z
	var side = fd.cross(Vector3.UP).normalized()
	for i in n:
		var u = ClanConstruct.new()
		u.kind = k
		u.owner_f = c
		u.team = c.team
		u.slot = i
		u.dmg = base * {"puppet": 0.45, "ink": 0.35, "golem": 0.9, "bee": 0.25, "beetle": 0.3}.get(k, 0.4)
		u.life = 18.0 + tier * 3.0
		c.get_tree().current_scene.add_child(u)
		var off = side * ((i - (n - 1) * 0.5) * 2.4) + fd * (2.5 + (2.0 if k == "golem" else 0.0))
		var p = c.global_position + off
		p.y = Game.ground_height(p.x, p.z) + (2.5 if k == "bee" else 0.0)
		u.global_position = p
		u.facing = atan2(-fd.x, -fd.z)
		u._appear()
		out.append(u)
	return out


func _ready() -> void:
	add_to_group("fighters")
	add_to_group("clan_construct")
	collision_layer = 4
	collision_mask = 1
	match kind:
		"golem":
			radius = 1.3; height = 4.6; max_hp = 420.0; speed = 7.5
		"bee":
			radius = 0.5; height = 1.0; max_hp = 50.0; speed = 17.0
		"ink":
			radius = 0.6; height = 1.4; max_hp = 70.0; speed = 16.0
		"beetle":
			radius = 0.7; height = 1.0; max_hp = 90.0; speed = 12.0
		_:
			max_hp = 150.0
	hp = max_hp
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = radius
	cap.height = maxf(height, radius * 2.0 + 0.01)
	cs.shape = cap
	cs.position.y = height * 0.5
	add_child(cs)
	vis = Node3D.new()
	add_child(vis)
	var mi = MeshInstance3D.new()
	mi.mesh = _build_mesh()
	vis.add_child(mi)
	if kind == "puppet":
		for k in 3:
			var th = MeshInstance3D.new()
			var cm = CylinderMesh.new()
			cm.top_radius = 0.012
			cm.bottom_radius = 0.012
			cm.height = 1.0
			cm.radial_segments = 4
			th.mesh = cm
			th.material_override = JutsuEngine.glow_mat(Color(0.45, 0.85, 1.0), 0.85)
			th.top_level = true
			add_child(th)
			threads.append(th)


func _build_mesh() -> ArrayMesh:
	var b = MB.new()
	match kind:
		"puppet":
			# savaş kuklası (özgün tasarım): kambur, uzun boylu; kapüşonlu yırtık pelerin, menteşeli uzun çeneli lake maske,
			# üç gözlü yüz, eklem topları ve metal bantlı segmentli kollar, ek kol çifti, bileklerde bıçaklar, sırttan çıkan segmentli bıçaklı kuyruk
			var wd = Color(0.66, 0.48, 0.32)
			var wd2 = Color(0.52, 0.36, 0.24)
			var dk = Color(0.2, 0.14, 0.1)
			var lac = Color(0.55, 0.1, 0.12)
			var metal = Color(0.72, 0.74, 0.78)
			var cl = Color(0.16, 0.14, 0.2)
			var face = Color(0.93, 0.9, 0.84)
			# gövde: öne eğik göğüs fıçısı + bel + kalça (metal bant halkaları)
			Loft.tube(b, [Vector3(0, 0.72, 0.02), Vector3(0, 0.95, 0.0), Vector3(0, 1.25, -0.06), Vector3(0, 1.45, -0.1)], [Vector2(0.17, 0.13), Vector2(0.14, 0.11), Vector2(0.24, 0.17), Vector2(0.2, 0.15)], wd, 14, 3, true, true)
			for y in [0.9, 1.12, 1.32]:
				b.add("torus", Vector3(0, y, -0.04), Vector3(0.44 if y > 1.0 else 0.32, 0.06, 0.32 if y > 1.0 else 0.25), metal, Vector3.ZERO, 14)
			b.add("box", Vector3(0, 1.22, -0.2), Vector3(0.22, 0.24, 0.04), lac)   # göğüs plakası
			b.add("cyl", Vector3(0, 1.22, -0.22), Vector3(0.09, 0.02, 0.09), metal, Vector3(90, 0, 0), 10)
			# baş: lake maske, üç göz, uzun menteşeli çene, kapüşon
			var hc = Vector3(0, 1.66, -0.14)
			b.add_grad("sphere", hc + Vector3(0, 0, -0.04), Vector3(0.34, 0.36, 0.32), face, face.darkened(0.15), Vector3.ZERO, 12)
			b.add("box", hc + Vector3(0, -0.21, -0.08), Vector3(0.22, 0.17, 0.22), face.darkened(0.08), Vector3(12, 0, 0))   # uzun çene
			b.add("box", hc + Vector3(0, -0.15, -0.195), Vector3(0.2, 0.015, 0.02), dk)   # çene menteşe çizgisi
			for sx in [-1.0, 0.0, 1.0]:
				var ep = hc + Vector3(0.085 * sx, 0.03 + (0.08 if sx == 0.0 else 0.0), -0.205 + (0.01 if sx == 0.0 else 0.0))
				b.add("sphere", ep, Vector3(0.075, 0.06, 0.04), Color(0.06, 0.05, 0.06), Vector3.ZERO, 8)
				b.add("sphere", ep + Vector3(0, 0, -0.012), Vector3(0.025, 0.025, 0.012), Color(1.0, 0.25, 0.2), Vector3.ZERO, 6)
			for sx in [-1.0, 1.0]:
				b.add("box", hc + Vector3(0.11 * sx, -0.07, -0.205), Vector3(0.012, 0.12, 0.01), lac, Vector3(0, 0, 18 * sx))   # yanak boyası
			Loft.tube(b, [hc + Vector3(0, -0.14, 0.17), hc + Vector3(0, 0.12, 0.14), hc + Vector3(0, 0.24, 0.2), hc + Vector3(0, 0.12, 0.4)], [Vector2(0.25, 0.23), Vector2(0.23, 0.25), Vector2(0.17, 0.16), Vector2(0.02, 0.02)], cl, 14, 3, true, false)   # kapüşon başın arkasında, yüz açık   # kapüşon
			# pelerin: omuzlardan dizlere yırtık kenarlı
			for k in 9:
				var a = deg_to_rad(-120.0 + k * 30.0)
				var top = Vector3(sin(a) * 0.26, 1.42, cos(a) * 0.2 + 0.02)
				var L = 0.65 + 0.18 * float(k % 3)
				b.add_xf("box", Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(-10)) * Basis.from_scale(Vector3(0.2, L, 0.02)), top + Vector3(sin(a) * 0.06, -L * 0.5, cos(a) * 0.05)), cl.lightened(0.03 * (k % 2)))
			# kollar: omuz topu, segmentli üst kol + bant, dirsek topu, ön kol, bilek bıçağı, pençe parmaklar
			for pair in [[1.0, 0.0], [-1.0, 0.0], [1.0, 1.0], [-1.0, 1.0]]:
				var sx: float = pair[0]
				var extra = pair[1] > 0.5
				var sh = Vector3(0.3 * sx, 1.34 - (0.24 if extra else 0.0), -0.04 + (0.08 if extra else 0.0))
				var el = sh + Vector3(0.16 * sx, -0.3, -0.12 if not extra else 0.0)
				var wr = el + Vector3(0.06 * sx, -0.06, -0.36)
				b.add("sphere", sh, Vector3.ONE * (0.12 if not extra else 0.09), dk, Vector3.ZERO, 8)
				Loft.tube(b, [sh, el], [0.065 if not extra else 0.05, 0.055], wd2, 8, 1)
				b.add("torus", sh.lerp(el, 0.5), Vector3.ONE * 0.14, metal, Vector3(0, 0, 60 * sx), 10)
				b.add("sphere", el, Vector3.ONE * 0.09, dk, Vector3.ZERO, 8)
				Loft.tube(b, [el, wr], [0.05, 0.042], wd, 8, 1)
				for f in 3:
					b.add("cone", wr + Vector3((f - 1) * 0.03, -0.02, -0.06), Vector3(0.02, 0.12, 0.02), dk, Vector3(-80, 0, 0), 4)
				b.add_xf("cone", Transform3D(Basis.looking_at((wr - el).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3(0.06, 0.6, 0.012)), wr + (wr - el).normalized() * 0.32), metal, 4)   # bilek bıçağı
			# bacaklar: ince, eklemli, uçları sivri (kukla süzülür)
			for sx in [-1.0, 1.0]:
				var hp = Vector3(0.12 * sx, 0.72, 0.02)
				var kn = hp + Vector3(0.04 * sx, -0.34, -0.06)
				var an = kn + Vector3(0, -0.3, 0.05)
				b.add("sphere", hp, Vector3.ONE * 0.1, dk, Vector3.ZERO, 8)
				Loft.tube(b, [hp, kn, an], [0.06, 0.05, 0.035], wd2, 8, 2)
				b.add("sphere", kn, Vector3.ONE * 0.08, dk, Vector3.ZERO, 8)
				b.add("cone", an + Vector3(0, -0.06, -0.03), Vector3(0.05, 0.14, 0.05), dk, Vector3(180, 0, 0), 5)
			# sırttan çıkan segmentli kuyruk + ucunda zehirli bıçak
			var prev = Vector3(0, 1.1, 0.16)
			for k in 7:
				var nxt = prev + Vector3(0, 0.12 + k * 0.02, 0.14 - k * 0.03)
				b.add("sphere", prev, Vector3.ONE * (0.08 - k * 0.006), dk if k % 2 == 0 else metal, Vector3.ZERO, 8)
				Loft.tube(b, [prev, nxt], [0.045 - k * 0.004, 0.04 - k * 0.004], wd, 6, 1)
				prev = nxt
			b.add("cone", prev + Vector3(0, 0.12, -0.08), Vector3(0.08, 0.3, 0.03), Color(0.5, 0.7, 0.45), Vector3(-30, 0, 0), 4)   # zehirli uç (yeşilimsi)
		"ink":
			# mürekkep aslanı: kapkara gövde, beyaz fırça çizgisi yele ve gözler
			var ink = Color(0.05, 0.05, 0.07)
			b.add("sphere", Vector3(0, 0.75, 0.1), Vector3(0.7, 0.62, 1.25), ink, Vector3.ZERO, 10)
			b.add("sphere", Vector3(0, 1.05, -0.62), Vector3(0.62, 0.6, 0.6), ink, Vector3.ZERO, 10)
			b.add("torus", Vector3(0, 1.05, -0.5), Vector3(0.78, 0.6, 0.78), Color(0.92, 0.92, 0.9), Vector3(80, 0, 0), 14)
			b.add("box", Vector3(0, 0.9, -0.95), Vector3(0.32, 0.22, 0.3), ink)
			for sx in [-1.0, 1.0]:
				b.add("sphere", Vector3(0.15 * sx, 1.12, -0.9), Vector3(0.09, 0.06, 0.04), Color(0.95, 0.95, 0.9), Vector3.ZERO, 6)
				b.add("cone", Vector3(0.22 * sx, 1.38, -0.55), Vector3(0.12, 0.2, 0.1), ink, Vector3.ZERO, 5)
				for fz in [-0.35, 0.45]:
					b.add("cyl", Vector3(0.24 * sx, 0.28, fz), Vector3(0.16, 0.56, 0.16), ink, Vector3.ZERO, 6)
			b.add("cyl", Vector3(0, 0.95, 0.85), Vector3(0.06, 0.7, 0.06), ink, Vector3(-60, 0, 0), 5)
			b.add("sphere", Vector3(0, 1.22, 1.12), Vector3(0.16, 0.16, 0.16), Color(0.92, 0.92, 0.9), Vector3.ZERO, 6)
		"golem":
			# taş dev (özgün Doton golemi): kambur kaslı gövde, yere değen dev kollar, omuzlara gömülü küçük baş,
			# üst üste binen kaya zırh plakaları, plakalar arasında parlayan chakra lav çatlakları, sırtta yosun ve dikitler
			var st = Color(0.58, 0.54, 0.48)
			var st2 = Color(0.46, 0.43, 0.38)
			var dk = Color(0.3, 0.28, 0.25)
			var mo = Color(0.36, 0.5, 0.26)
			var lava = Color(1.0, 0.62, 0.18)
			var rock = func(_t: float, a: float, d: Vector3) -> Color:
				# kaya dokusu: üstte açık, altta koyu; dağınık koyu benekler
				var band = floor((d.y + 1.0) * 2.5) / 5.0   # sert cel kademeleri (bulanık leke yok)
				var c = st2.lerp(st, band)
				if absf(sin(a * 5.0 + _t * 11.0)) < 0.05:
					return dk   # ince kaya çatlağı çizgisi
				return c
			# gövde: geniş göğüs kafesi, öne kambur sırt, dar bel, ağır kalça (pürüzsüz tek parça kütle)
			Loft.tube(b, [Vector3(0, 1.35, 0.05), Vector3(0, 1.75, 0.0), Vector3(0, 2.45, -0.15), Vector3(0, 3.2, -0.05), Vector3(0, 3.55, 0.25)],
				[Vector2(0.62, 0.5), Vector2(0.52, 0.44), Vector2(0.85, 0.66), Vector2(0.95, 0.75), Vector2(0.6, 0.5)], st, 22, 4, true, true, rock)
			# omuzlara gömülü küçük baş: alnı çıkık, çene kalın, parlayan göz yarıkları ve ağız çatlağı
			var hc = Vector3(0, 3.62, -0.6)
			Loft.tube(b, [hc + Vector3(0, -0.25, 0.2), hc + Vector3(0, 0.0, 0.0), hc + Vector3(0, 0.1, -0.2)], [Vector2(0.42, 0.38), Vector2(0.4, 0.36), Vector2(0.3, 0.24)], st2, 16, 3, true, true, rock)
			b.add("boulder", hc + Vector3(0, 0.24, -0.2), Vector3(0.82, 0.26, 0.38), st, Vector3(-10, 0, 0), 3)   # çıkık alın
			for sx in [-1.0, 1.0]:
				b.add("box", hc + Vector3(0.14 * sx, 0.06, -0.36), Vector3(0.18, 0.05, 0.04), lava, Vector3(0, 0, 12 * sx))   # göz yarığı
				b.add("sphere", hc + Vector3(0.14 * sx, 0.06, -0.33), Vector3(0.12, 0.08, 0.05), lava.lightened(0.3), Vector3.ZERO, 6)
			b.add("box", hc + Vector3(0, -0.2, -0.34), Vector3(0.36, 0.035, 0.04), lava.darkened(0.15))   # ağız çatlağı
			b.add("boulder", hc + Vector3(0, -0.3, -0.25), Vector3(0.5, 0.25, 0.3), st2, Vector3(15, 0, 0), 4)   # kalın çene
			# omuz zırhları: üst üste 3 kaya plakası + sivri dikit
			for sx in [-1.0, 1.0]:
				var sh = Vector3(1.05 * sx, 3.15, 0.0)
				for k in 3:
					b.add("boulder", sh + Vector3((0.3 + 0.14 * k) * sx, 0.25 - k * 0.22, k * 0.1), Vector3(1.15 - k * 0.2, 0.6 - k * 0.08, 1.05 - k * 0.15), st.lerp(st2, k * 0.3), Vector3(k * 12, k * 30 * sx, -20 * sx), k + 1)
				b.add("cone", sh + Vector3(0.1 * sx, 0.55, 0.15), Vector3(0.22, 0.7, 0.22), dk, Vector3(-15, 0, -25 * sx), 6)
				b.add("cone", sh + Vector3(-0.25 * sx, 0.45, 0.35), Vector3(0.16, 0.5, 0.16), dk, Vector3(-30, 0, -10 * sx), 6)
				# dev kol: kalın üst kol, dirsek kayası, aşağı genişleyen ön kol, yere değen dev yumruk
				var el = sh + Vector3(0.35 * sx, -1.05, -0.2)
				var wr = el + Vector3(0.05 * sx, -1.0, -0.35)
				Loft.tube(b, [sh, sh.lerp(el, 0.5) + Vector3(0.1 * sx, 0, 0), el], [0.42, 0.46, 0.36], st, 16, 3, true, true, rock)
				b.add("boulder", el + Vector3(0.1 * sx, 0, 0.1), Vector3(0.55, 0.5, 0.55), st2, Vector3(0, 0, 0), 5)
				Loft.tube(b, [el, el.lerp(wr, 0.5), wr], [0.38, 0.5, 0.58], st, 16, 3, true, true, rock)
				for f in 4:
					var fp = wr + Vector3((f - 1.5) * 0.24, -0.35, -0.2 + absf(f - 1.5) * 0.08)
					b.add("boulder", fp, Vector3(0.28, 0.4, 0.3), st2.lerp(dk, 0.2), Vector3(-20, 0, 0), 6 + f)   # kalın parmaklar
				b.add("boulder", wr + Vector3(0.0, -0.1, 0.15), Vector3(0.75, 0.55, 0.6), st, Vector3.ZERO, 7)   # yumruk sırtı
				# kolda lav çatlakları
				for k in 3:
					b.add("box", sh.lerp(wr, 0.25 + k * 0.25) + Vector3(0.05 * sx, 0, -0.42), Vector3(0.04, 0.35, 0.03), lava, Vector3(0, 0, 25 * sx * (1 if k % 2 else -1)))
				# kısa, kalın bacaklar + ayak kayası
				var hp = Vector3(0.55 * sx, 1.35, 0.1)
				var kn = hp + Vector3(0.12 * sx, -0.65, -0.1)
				Loft.tube(b, [hp, kn, Vector3(0.7 * sx, 0.25, 0.05)], [0.5, 0.42, 0.45], st2, 16, 3, true, true, rock)
				b.add("boulder", Vector3(0.72 * sx, 0.18, -0.12), Vector3(0.85, 0.4, 1.05), st2.darkened(0.1), Vector3.ZERO, 8)
				b.add("boulder", kn + Vector3(0, 0, -0.3), Vector3(0.5, 0.45, 0.35), st, Vector3.ZERO, 9)   # diz kayası
			# göğüs: büyük plaka + ortada parlayan chakra çekirdeği ve ondan yayılan çatlaklar
			b.add("boulder", Vector3(0, 2.75, -0.72), Vector3(1.35, 1.0, 0.55), st, Vector3(-8, 0, 0), 10)
			b.add("sphere", Vector3(0, 2.7, -0.98), Vector3(0.36, 0.36, 0.14), lava.lightened(0.2), Vector3.ZERO, 12)
			for k in 6:
				var a = k * TAU / 6.0 + 0.3
				b.add("box", Vector3(cos(a) * 0.42, 2.7 + sin(a) * 0.36, -0.99), Vector3(0.34, 0.035, 0.03), lava, Vector3(0, 0, rad_to_deg(a)))
			b.add("boulder", Vector3(0, 1.75, -0.6), Vector3(0.9, 0.5, 0.35), st2, Vector3.ZERO, 11)   # karın plakası
			# sırt: yosun örtüsü + sırt dikitleri
			b.add("sphere", Vector3(0, 3.3, 0.55), Vector3(1.6, 0.5, 0.9), mo, Vector3(25, 0, 0), 12)
			for k in 5:
				b.add("cone", Vector3((k - 2) * 0.32, 3.35 - absf(k - 2) * 0.12, 0.65 - absf(k - 2) * 0.05), Vector3(0.22, 0.6 - absf(k - 2) * 0.1, 0.22), dk, Vector3(35, 0, (k - 2) * -10), 6)
			for k in 7:
				b.add("sphere", Vector3(randf_range(-1.0, 1.0), randf_range(2.2, 3.4), randf_range(0.3, 0.75)), Vector3(0.25, 0.12, 0.2), mo.lightened(0.1), Vector3.ZERO, 6)
		"beetle":
			# dev parazit kınkanatlı: parlak kara kabuk, boynuzlu kafa, altı bacak
			var sh = Color(0.12, 0.14, 0.1)
			b.add("sphere", Vector3(0, 0.55, 0.15), Vector3(1.1, 0.7, 1.5), sh, Vector3.ZERO, 10)
			b.add("box", Vector3(0, 0.75, 0.15), Vector3(0.03, 0.3, 1.4), Color(0.3, 0.35, 0.22))
			b.add("sphere", Vector3(0, 0.5, -0.75), Vector3(0.6, 0.45, 0.5), sh.darkened(0.2), Vector3.ZERO, 8)
			b.add("cone", Vector3(0, 0.75, -1.05), Vector3(0.12, 0.6, 0.12), sh, Vector3(-60, 0, 0), 5)
			for sx in [-1.0, 1.0]:
				b.add("sphere", Vector3(0.18 * sx, 0.6, -0.95), Vector3(0.1, 0.08, 0.06), Color(0.85, 0.2, 0.1), Vector3.ZERO, 6)
				for fz in [-0.35, 0.15, 0.6]:
					b.add("cyl", Vector3(0.62 * sx, 0.3, fz), Vector3(0.07, 0.6, 0.07), sh, Vector3(0, 0, 55 * sx), 4)
		"bee":
			# dev eşek arısı: sarı-siyah çizgili karın, iğne, şeffafımsı kanatlar
			var y = Color(0.95, 0.75, 0.12)
			var k = Color(0.1, 0.08, 0.06)
			b.add("sphere", Vector3(0, 0, -0.45), Vector3(0.36, 0.34, 0.36), k, Vector3.ZERO, 8)
			b.add("sphere", Vector3(0, 0, 0), Vector3(0.38, 0.36, 0.5), y.darkened(0.2), Vector3.ZERO, 8)
			for i in 4:
				b.add("sphere", Vector3(0, -0.04, 0.4 + i * 0.16), Vector3(0.42 - i * 0.06, 0.4 - i * 0.06, 0.2), y if i % 2 == 0 else k, Vector3.ZERO, 8)
			b.add("cone", Vector3(0, -0.05, 1.05), Vector3(0.07, 0.35, 0.07), k, Vector3(90, 0, 0), 5)
			for sx in [-1.0, 1.0]:
				b.add("sphere", Vector3(0.14 * sx, 0.06, -0.62), Vector3(0.12, 0.14, 0.1), Color(0.6, 0.1, 0.05), Vector3.ZERO, 6)
				b.add("box", Vector3(0.45 * sx, 0.25, -0.05), Vector3(0.75, 0.02, 0.3), Color(0.85, 0.92, 1.0), Vector3(0, 10 * sx, 15 * sx))
	return b.build(Props.toon())


func _appear() -> void:
	var p = global_position + Vector3.UP * height * 0.5
	match kind:
		"ink":
			FX.burst(p, {"amount": 26, "life": 0.6, "size": 0.7, "vmin": 2, "vmax": 6, "add": false, "colors": [Color(0.05, 0.05, 0.08), Color(0.05, 0.05, 0.08, 0)]})
			VFX.shockwave(global_position + Vector3.UP * 0.05, Color(0.1, 0.1, 0.12), 5.0, 0.35, false)
		"golem":
			VFX.cracks(global_position, 5.0)
			FX.impact(global_position, Color(0.6, 0.5, 0.4), 1.6)
			if Game.world:
				Game.world.env.add_shake(0.8)
		"bee":
			FX.burst(p, {"amount": 14, "life": 0.4, "size": 0.4, "vmin": 2, "vmax": 5, "colors": [Color(1, 0.85, 0.3), Color(1, 0.8, 0.2, 0)]})
		_:
			FX.smoke_puff(p, 1.2, 16)
			VFX.shockwave(global_position + Vector3.UP * 0.05, Color(0.5, 0.85, 1.0), 4.0, 0.3, false)
	vis.scale = Vector3.ONE * 0.2
	var tw = create_tween()
	tw.tween_property(vis, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_dead() -> bool:
	return dead


func face_dir() -> Vector3:
	return Vector3(-sin(facing), 0, -cos(facing))


func apply_status(_n: String, _d: float) -> void:
	pass


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	var d: float = info.get("dmg", 5.0)
	hp -= d
	Combat.damage_number(global_position + Vector3.UP * (height + 0.3), d, Color(1, 0.6, 0.5))
	if hp <= 0.0:
		vanish()


func vanish() -> void:
	if dead:
		return
	dead = true
	var p = global_position + Vector3.UP * height * 0.5
	match kind:
		"ink":   # mürekkep birikintisine dağılır
			FX.burst(p, {"amount": 30, "life": 0.7, "size": 0.8, "vmin": 2, "vmax": 7, "add": false, "colors": [Color(0.04, 0.04, 0.06), Color(0.04, 0.04, 0.06, 0)]})
		"golem":
			FX.impact(p, Color(0.55, 0.5, 0.42), 1.8)
			FX.smoke_puff(p, 2.0, 18)
		"puppet":
			FX.burst(p, {"amount": 14, "life": 0.6, "size": 0.35, "vmin": 2, "vmax": 6, "add": false, "colors": [Color(0.6, 0.45, 0.3), Color(0.6, 0.45, 0.3, 0)]})
			FX.smoke_puff(p, 0.8, 10)
		_:
			FX.smoke_puff(p, 0.6, 8)
	queue_free()


func _physics_process(dt: float) -> void:
	if Game.paused or dead:
		return
	life -= dt
	cd -= dt
	if life <= 0.0 or owner_f == null or not is_instance_valid(owner_f):
		vanish()
		return
	if tgt == null or not is_instance_valid(tgt) or tgt.is_dead():
		tgt = Combat.nearest_enemy(self, 32.0)
	var wish = Vector3.ZERO
	var reach = radius + (2.2 if kind == "golem" else 1.0)
	if lunge_t > 0.0:
		lunge_t -= dt
		wish = face_dir() * speed * 2.2
	elif tgt:
		var v = tgt.global_position - global_position
		v.y = 0
		var d = v.length() - tgt.radius - radius
		facing = atan2(-v.x, -v.z)
		if d > reach:
			wish = v.normalized() * speed
		elif cd <= 0.0:
			_attack(v.normalized())
	else:
		var side = owner_f.global_transform.basis.x
		var home = owner_f.global_position + side * (2.2 + slot * 1.6) * (1.0 if slot % 2 == 0 else -1.0)
		var v = home - global_position
		v.y = 0
		if v.length() > 2.0:
			wish = v.normalized() * minf(speed, v.length() * 3.0)
			facing = atan2(-v.x, -v.z)
	velocity.x = wish.x
	velocity.z = wish.z
	if kind == "bee":
		var gy = Game.ground_height(global_position.x, global_position.z) + 2.3 + sin(Time.get_ticks_msec() * 0.006 + slot) * 0.3
		velocity.y = (gy - global_position.y) * 6.0
	else:
		velocity.y -= 30.0 * dt
	move_and_slide()
	if kind != "bee":
		var g = Game.ground_height(global_position.x, global_position.z)
		if global_position.y < g:
			global_position.y = g
			velocity.y = 0
	vis.rotation.y = facing
	# yürüyüş/kanat titreşimi
	var tm = Time.get_ticks_msec() * 0.001
	match kind:
		"golem":
			vis.position.y = absf(sin(tm * 5.0)) * 0.12 if wish.length() > 1.0 else 0.0
			vis.rotation.z = sin(tm * 2.5) * 0.03
		"bee":
			vis.position.y = sin(tm * 30.0) * 0.03
		"puppet":
			vis.rotation.z = sin(tm * 9.0) * 0.08   # ipe asılı sallanma
			vis.position.y = 0.1 + sin(tm * 4.0) * 0.06
		_:
			vis.position.y = absf(sin(tm * 12.0)) * 0.14 if wish.length() > 1.0 else 0.0
	_update_threads()


func _attack(dir: Vector3) -> void:
	var pt = global_position + Vector3.UP * height * 0.45 + dir * (radius + 0.9)
	match kind:
		"golem":
			# iki yumruğunu yere indirir: şok dalgası + çatlaklar
			cd = 1.8
			var at = global_position + dir * (radius + 1.6)
			get_tree().create_timer(0.35).timeout.connect(func():
				if dead:
					return
				VFX.cracks(at, 4.0)
				VFX.shockwave(at + Vector3.UP * 0.1, Color(0.75, 0.62, 0.45), 9.0, 0.35, false)
				FX.impact(at, Color(0.6, 0.5, 0.4), 1.4)
				Combat.hit_sphere(self, at + Vector3.UP * 0.8, 3.2, {"dmg": dmg, "knock": 12.0, "launch": 7.0, "kind": "heavy", "element": "doton", "hitstop": 0.06})
				Sfx.play("boom", at, 0.7)
				if Game.world:
					Game.world.env.add_shake(0.5))
			var tw = create_tween()
			tw.tween_property(vis, "rotation:x", -0.35, 0.3)
			tw.tween_property(vis, "rotation:x", 0.25, 0.08)
			tw.tween_property(vis, "rotation:x", 0.0, 0.3)
		"bee":
			# dalış + iğne: zehir (yanma gibi sürekli hasar) ve yavaşlatma
			cd = 1.1
			lunge_t = 0.18
			if not Combat.hit_sphere(self, pt, 1.0, {"dmg": dmg, "knock": 2.0, "kind": "light", "burn": 2.5}).is_empty():
				FX.hit_spark(pt, Color(0.75, 1.0, 0.3), 0.6)
		"ink", "beetle":
			cd = 0.9
			lunge_t = 0.22
			if not Combat.hit_sphere(self, pt, 1.2, {"dmg": dmg, "knock": 5.0, "kind": "light"}).is_empty():
				FX.burst(pt, {"amount": 10, "life": 0.4, "size": 0.45, "vmin": 2, "vmax": 5, "add": false, "colors": [Color(0.04, 0.04, 0.06), Color(0.04, 0.04, 0.06, 0)]})
				Sfx.play("punch", pt, 1.2, 0.6)
		_:
			# kukla: bıçaklı kollarla çift kesik, arada zehirli senbon yaylımı
			cd = 0.8
			lunge_t = 0.15
			var got = Combat.hit_sphere(self, pt, 1.2, {"dmg": dmg, "knock": 4.0, "kind": "light", "burn": 1.5})
			FX.hit_spark(pt, Color(0.75, 0.95, 0.85), 0.7)
			if not got.is_empty():
				Sfx.play("slash", pt, 1.1, 0.6)
			if randf() < 0.3 and tgt:
				for i in 5:
					var a = (i - 2) * 0.12
					var dd = dir.rotated(Vector3.UP, a)
					var pr = Projectile.new()
					pr.shooter = self
					pr.vel = dd * 34.0
					pr.info = {"dmg": dmg * 0.3, "knock": 1.0, "kind": "light", "burn": 2.0}
					pr.life = 1.2
					pr.add_child(JutsuEngine.shape_mesh("needles", Color(0.6, 1.0, 0.45), 0.35, ""))
					get_tree().current_scene.add_child(pr)
					pr.global_position = global_position + Vector3.UP * 1.3 + dd * 0.6
					pr.look_at(pr.global_position + dd, Vector3.UP)


## Kukla: sahibinin parmaklarından kuklanın sırtına parlayan chakra iplikleri
func _update_threads() -> void:
	if threads.is_empty():
		return
	var hand: Vector3 = owner_f.global_position + Vector3.UP * 1.3 + owner_f.global_transform.basis.x * 0.3 - owner_f.global_transform.basis.z * 0.3
	for i in threads.size():
		var th: MeshInstance3D = threads[i]
		var a = hand + Vector3(0, 0, 0.06 * (i - 1))
		var b = global_position + Vector3.UP * (1.4 - i * 0.25) + Vector3(0.1 * (i - 1), 0, 0)
		var dvec = b - a
		var L = dvec.length()
		if L < 0.05 or L > 60.0:
			th.visible = false
			continue
		th.visible = true
		var y = dvec / L
		var x = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
		var z = x.cross(y)
		th.global_transform = Transform3D(Basis(x, y * L, z), (a + b) * 0.5)
