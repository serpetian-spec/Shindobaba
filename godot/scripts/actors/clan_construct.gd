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
			# savaş kuklası (REFERANS: anime savaş kuklaları): gövdeyi saran geniş yırtık gri pelerin, pelerinden çıkan açık renk eklemli
			# ahşap kollar (yuvarlak eklem topları, segment çizgileri, yumruk eller), ince eklemli bacaklar; iki tip (slot'a göre):
			# A — diken diken koyu kahve saç, üç gözlü yüz, aşağı sarkan menteşeli çene ve dişler;  B — kızıl çift boynuz, uzun yassı yüz, sarı gözler, dişli uzun çene
			var wood = Color(0.8, 0.7, 0.62)
			var wood_d = Color(0.62, 0.52, 0.45)
			var joint = Color(0.5, 0.42, 0.36)
			var cloak = Color(0.5, 0.48, 0.47)   # sıcak gri (gölgede laciverte kaçmasın)
			var cloak_d = Color(0.38, 0.36, 0.35)
			var ink = Color(0.12, 0.1, 0.1)
			var horned = slot % 2 == 1
			var seg = func(mb: MB, a: Vector3, c: Vector3, r: float, n: int) -> void:
				# eklemli ahşap uzuv: n parça, aralarda koyu eklem topu ve segment çizgisi
				for k in n:
					var p0 = a.lerp(c, float(k) / n)
					var p1 = a.lerp(c, float(k + 1) / n)
					Loft.tube(mb, [p0.lerp(p1, 0.06), p1.lerp(p0, 0.06)], [r, r * 0.92], wood, 8, 1, true, true)
					mb.add("sphere", p1, Vector3.ONE * r * 1.25, joint, Vector3.ZERO, 8)
					mb.add("torus", p0.lerp(p1, 0.5), Vector3.ONE * r * 2.05, wood_d, Vector3(90, 0, 0), 8)
			# gövde (pelerin altında ahşap fıçı)
			Loft.tube(b, [Vector3(0, 0.8, 0.0), Vector3(0, 1.15, -0.02), Vector3(0, 1.45, -0.06)], [Vector2(0.17, 0.14), Vector2(0.2, 0.16), Vector2(0.18, 0.14)], wood_d, 12, 2, true, true)
			# geniş yırtık pelerin: omuzdan dizin altına kadar, gövdeyi saran çan; alt kenarı ve yanları tırtıklı şeritler
			Loft.tube(b, [Vector3(0, 1.52, -0.05), Vector3(0, 1.3, 0.0), Vector3(0, 0.9, 0.06), Vector3(0, 0.45, 0.1)],
				[Vector2(0.22, 0.18), Vector2(0.44, 0.34), Vector2(0.55, 0.42), Vector2(0.6, 0.46)], cloak, 22, 4, false, false,
				func(_t: float, a: float, _d: Vector3) -> Color: return cloak_d if fposmod(a * 3.0 + _t * 5.0, 1.0) < 0.15 else cloak)
			for k in 22:   # alt kenar: düzensiz sarkan yırtık şeritler
				var a = TAU * k / 22.0
				var L = 0.12 + 0.22 * fposmod(k * 0.618, 1.0)
				var top = Vector3(sin(a) * 0.6, 0.47, cos(a) * 0.46 + 0.1)
				b.add_xf("cone", Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(180.0 - 8.0)) * Basis.from_scale(Vector3(0.16, L, 0.025)), top + Vector3(0, -L * 0.5, 0)), cloak_d if k % 2 else cloak, 4)
			b.add("torus", Vector3(0, 1.5, -0.05), Vector3(0.38, 0.12, 0.32), cloak_d, Vector3.ZERO, 14)   # yaka
			# baş
			var hc = Vector3(0, 1.72, -0.1)
			if not horned:
				b.add("sphere", hc, Vector3(0.28, 0.32, 0.27), wood, Vector3.ZERO, 12)
				for k in 22:   # diken diken saç
					var a = fposmod(k * 0.618, 1.0) * TAU
					var up = fposmod(k * 0.37, 1.0)
					var d = Vector3(sin(a) * 0.9, 0.3 + up * 0.8, cos(a) * 0.7 + 0.25).normalized()
					if d.z < -0.45 and d.y < 0.6:
						continue   # yüzün önü açık
					BeastRig.claw(b, hc + d * 0.12, d, 0.16 + up * 0.08, 0.05, Color(0.32, 0.22, 0.16))
				for p in [Vector3(-0.07, 0.03, -0.25), Vector3(0.07, 0.03, -0.25), Vector3(0.0, 0.13, -0.24)]:   # üç göz (yüz yüzeyinde)
					b.add("sphere", hc + p, Vector3(0.075, 0.07, 0.03), Color(0.96, 0.95, 0.92), Vector3.ZERO, 8)
					b.add("sphere", hc + p + Vector3(0, 0, -0.015), Vector3(0.028, 0.028, 0.012), ink, Vector3.ZERO, 6)
				# sarkık çene: açık ağız, iki sıra diş
				b.add("box", hc + Vector3(0, -0.1, -0.12), Vector3(0.15, 0.05, 0.04), Color(0.28, 0.1, 0.1))
				b.add("box", hc + Vector3(0, -0.19, -0.1), Vector3(0.17, 0.08, 0.12), wood_d, Vector3(18, 0, 0))
				for t in 5:
					var x = (t - 2) * 0.03
					b.add("box", hc + Vector3(x, -0.08, -0.14), Vector3(0.022, 0.03, 0.01), Color(0.97, 0.96, 0.92))
					b.add("box", hc + Vector3(x, -0.15, -0.15), Vector3(0.022, 0.03, 0.01), Color(0.97, 0.96, 0.92))
			else:
				# uzun yassı yüz (öne-aşağı uzar), kızıl çift boynuz, sarı gözler, dişli çene, arkaya savrulan koyu saç
				Loft.tube(b, [hc + Vector3(0, 0.1, 0.06), hc + Vector3(0, 0.0, -0.08), hc + Vector3(0, -0.22, -0.18)], [Vector2(0.14, 0.15), Vector2(0.13, 0.12), Vector2(0.11, 0.09)], wood, 12, 3, true, true)
				for sx in [-1.0, 1.0]:
					Loft.tube(b, [hc + Vector3(0.08 * sx, 0.12, 0.0), hc + Vector3(0.2 * sx, 0.26, 0.04), hc + Vector3(0.18 * sx, 0.44, 0.0), hc + Vector3(0.1 * sx, 0.56, -0.04)], [0.035, 0.03, 0.022, 0.004], Color(0.62, 0.12, 0.12), 8, 3, true, true)
					b.add("sphere", hc + Vector3(0.06 * sx, 0.02, -0.12), Vector3(0.05, 0.03, 0.02), Color(0.95, 0.78, 0.2), Vector3(0, 0, -12 * sx), 6)
					b.add("sphere", hc + Vector3(0.062 * sx, 0.02, -0.13), Vector3(0.018, 0.022, 0.01), ink, Vector3.ZERO, 6)
				for t in 6:
					b.add("box", hc + Vector3((t - 2.5) * 0.028, -0.2, -0.235), Vector3(0.02, 0.035, 0.01), Color(0.97, 0.96, 0.92))
				b.add("box", hc + Vector3(0, -0.24, -0.23), Vector3(0.16, 0.012, 0.01), ink)
				for k in 10:   # arkaya savrulan koyu saç
					var a = lerpf(-1.4, 1.4, k / 9.0)
					BeastRig.claw(b, hc + Vector3(sin(a) * 0.1, 0.12, 0.08), Vector3(sin(a) * 0.4, 0.2, 1.0).normalized(), 0.28, 0.05, Color(0.1, 0.1, 0.12))
			# kollar: pelerinin önünden ve yanlarından çıkan altı eklemli kol (yumruk eller)
			for k in 6:
				var sx = -1.0 if k % 2 == 0 else 1.0
				var row = k / 2
				var sh = Vector3(0.28 * sx, 1.3 - row * 0.2, -0.12 + row * 0.04)
				var dir = Vector3(sx * (0.55 - row * 0.1), -0.15 - row * 0.12, -0.8).normalized()
				var L = 0.62 + row * 0.06
				seg.call(b, sh, sh + dir * L, 0.05, 3)
				var hand = sh + dir * (L + 0.06)
				b.add("box", hand, Vector3(0.1, 0.09, 0.11), wood, Vector3(0, rad_to_deg(atan2(dir.x, -dir.z)), 0))   # yumruk
				for f in 3:
					b.add("box", hand + dir * 0.05 + Vector3((f - 1) * 0.03, 0.02, 0), Vector3(0.024, 0.035, 0.03), wood_d, Vector3.ZERO)
			# bacaklar: pelerinin altından çıkan ince eklemli bacaklar (süzülür)
			for sx in [-1.0, 1.0]:
				var hp = Vector3(0.12 * sx, 0.78, 0.04)
				seg.call(b, hp, hp + Vector3(0.05 * sx, -0.4, -0.05), 0.055, 2)
				seg.call(b, hp + Vector3(0.05 * sx, -0.4, -0.05), hp + Vector3(0.06 * sx, -0.72, 0.02), 0.045, 2)
				b.add("box", hp + Vector3(0.06 * sx, -0.75, -0.04), Vector3(0.09, 0.05, 0.16), wood_d)
		"ink":
			# mürekkep aslanı (Chōjū Giga): fırça darbesiyle çizilmiş gibi kara gövde, beyaz kontur çizgileri,
			# sivri yele tutamları, açık ağız ve dişler, damlayan mürekkep, kıvrık fırça kuyruğu
			var ink = Color(0.04, 0.04, 0.06)
			var paper = Color(0.96, 0.95, 0.9)
			# gövde: öne yüklenmiş, karnı içe çekik yırtıcı silueti
			Loft.tube(b, [Vector3(0, 0.82, 0.62), Vector3(0, 0.88, 0.25), Vector3(0, 0.95, -0.15), Vector3(0, 1.05, -0.45)], [Vector2(0.3, 0.3), Vector2(0.26, 0.27), Vector2(0.34, 0.36), Vector2(0.32, 0.34)], ink, 16, 3, true, true)
			# yele: başın çevresinde dışa savrulan sivri fırça tutamları
			var hc = Vector3(0, 1.22, -0.72)
			for k in 16:
				var a = k * TAU / 16.0
				var d = Vector3(cos(a), sin(a), 0.35).normalized()
				b.add_xf("cone", Transform3D(Basis(Quaternion(Vector3.UP, d)) * Basis.from_scale(Vector3(0.12, 0.55 + 0.15 * (k % 2), 0.08)), hc + d * 0.32 + Vector3(0, 0, 0.12)), ink, 4)
			# baş + çene: geniş burun, açık ağız
			Loft.tube(b, [hc + Vector3(0, 0.02, 0.12), hc + Vector3(0, 0.02, -0.12), hc + Vector3(0, -0.04, -0.35)], [Vector2(0.27, 0.25), Vector2(0.25, 0.22), Vector2(0.16, 0.13)], ink, 14, 3, true, true)
			b.add("box", hc + Vector3(0, -0.2, -0.2), Vector3(0.24, 0.07, 0.3), ink, Vector3(18, 0, 0))   # alt çene (açık)
			for sx in [-1.0, 1.0]:
				b.add("sphere", hc + Vector3(0.13 * sx, 0.1, -0.24), Vector3(0.1, 0.06, 0.04), paper, Vector3(0, 0, -18 * sx), 6)   # beyaz göz
				b.add("box", hc + Vector3(0.13 * sx, 0.1, -0.265), Vector3(0.02, 0.05, 0.01), ink)
				b.add("box", hc + Vector3(0.14 * sx, 0.17, -0.2), Vector3(0.16, 0.02, 0.02), paper, Vector3(0, 0, 22 * sx))   # kaş fırça çizgisi
				for t in 2:
					b.add("cone", hc + Vector3((0.06 + t * 0.05) * sx, -0.1, -0.36), Vector3(0.025, 0.08, 0.025), paper, Vector3(180, 0, 0), 4)   # üst diş
				b.add("cone", hc + Vector3(0.18 * sx, 0.34, -0.02), Vector3(0.09, 0.2, 0.05), ink, Vector3(0, 0, -20 * sx), 4)   # kulak
			# gövdede beyaz fırça kontur çizgileri (kâğıt boşluğu)
			for k in 4:
				b.add("box", Vector3(0, 1.08 - k * 0.04, 0.4 - k * 0.3), Vector3(0.012, 0.025, 0.22), paper, Vector3(0, 0, 0))
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(0.335 * sx, 0.95, -0.1), Vector3(0.008, 0.025, 0.42), paper, Vector3(12, 0, 0))   # ince fırça kontur çizgisi
				b.add("box", Vector3(0.3 * sx, 0.88, 0.48), Vector3(0.008, 0.025, 0.28), paper, Vector3(-18, 0, 0))
				# bacaklar: kaslı üst bacak, ince bilek, pençe; uçlarından mürekkep damlası
				for fz in [-0.42, 0.52]:
					var top = Vector3(0.22 * sx, 0.85, fz)
					var knee = top + Vector3(0.03 * sx, -0.35, -0.05 if fz < 0 else 0.1)
					var paw = Vector3(0.24 * sx, 0.06, fz - 0.06)
					Loft.tube(b, [top, knee, paw], [0.16, 0.09, 0.08], ink, 10, 2, true, true)
					for f in 3:
						b.add("cone", paw + Vector3((f - 1) * 0.04, -0.03, -0.09), Vector3(0.025, 0.08, 0.025), paper, Vector3(-80, 0, 0), 4)   # pençe
					b.add("sphere", paw + Vector3(0, -0.04, 0.02), Vector3(0.12, 0.03, 0.12), ink, Vector3.ZERO, 8)   # damlayan mürekkep göleti
			# kuyruk: S kıvrımlı fırça darbesi, ucu dağınık püskül
			Loft.tube(b, [Vector3(0, 0.9, 0.62), Vector3(0, 1.15, 0.85), Vector3(0, 1.45, 0.8), Vector3(0, 1.6, 0.55)], [0.06, 0.05, 0.045, 0.03], ink, 8, 3, true, false)
			for k in 5:
				var a = deg_to_rad(-60 + k * 30)
				b.add_xf("cone", Transform3D(Basis(Vector3.RIGHT, -0.8) * Basis(Vector3.BACK, a) * Basis.from_scale(Vector3(0.05, 0.25, 0.05)), Vector3(0, 1.7, 0.5)), ink, 4)
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
			# dev parazit kınkanatlı (Kidaichū): ortadan ayrılan parlak kanat kınları, iri çatallı boynuz, segmentli altı bacak, antenler
			var sh = Color(0.1, 0.13, 0.09)
			var hi = Color(0.32, 0.42, 0.24)
			var dk = Color(0.05, 0.05, 0.04)
			var shell = func(_t: float, a: float, d: Vector3) -> Color:
				return hi if d.y > 0.75 else (sh if d.y > -0.2 else dk)
			for sx in [-1.0, 1.0]:   # iki ayrı kanat kını, aralarında yarık
				Loft.tube(b, [Vector3(0.2 * sx, 0.55, 0.85), Vector3(0.28 * sx, 0.7, 0.35), Vector3(0.27 * sx, 0.7, -0.15), Vector3(0.18 * sx, 0.6, -0.4)], [Vector2(0.24, 0.24), Vector2(0.3, 0.3), Vector2(0.3, 0.3), Vector2(0.22, 0.2)], sh, 14, 3, true, true, shell)
			b.add("box", Vector3(0, 0.88, 0.2), Vector3(0.03, 0.04, 1.2), dk)   # orta yarık
			Loft.tube(b, [Vector3(0, 0.5, -0.4), Vector3(0, 0.55, -0.62), Vector3(0, 0.52, -0.8)], [Vector2(0.4, 0.28), Vector2(0.38, 0.27), Vector2(0.28, 0.22)], sh, 14, 2, true, true, shell)   # göğüs kalkanı
			Loft.tube(b, [Vector3(0, 0.45, -0.8), Vector3(0, 0.42, -1.0)], [Vector2(0.24, 0.18), Vector2(0.2, 0.15)], dk, 12, 1)   # baş
			# çatallı boynuz
			Loft.tube(b, [Vector3(0, 0.5, -1.0), Vector3(0, 0.75, -1.35), Vector3(0, 1.05, -1.45)], [0.08, 0.06, 0.035], sh, 8, 3, true, false)
			for sx in [-1.0, 1.0]:
				b.add("cone", Vector3(0.08 * sx, 1.12, -1.45), Vector3(0.035, 0.18, 0.035), sh, Vector3(0, 0, -35 * sx), 5)
				b.add("sphere", Vector3(0.16 * sx, 0.48, -0.98), Vector3(0.07, 0.06, 0.05), Color(0.95, 0.3, 0.1), Vector3.ZERO, 6)   # göz
				Loft.tube(b, [Vector3(0.1 * sx, 0.5, -1.02), Vector3(0.22 * sx, 0.62, -1.25), Vector3(0.32 * sx, 0.6, -1.4)], [0.015, 0.012, 0.008], dk, 5, 2, true, false)   # anten
				b.add("cone", Vector3(0.12 * sx, 0.32, -1.06), Vector3(0.04, 0.16, 0.04), dk, Vector3(-60, 0, 25 * sx), 4)   # kıskaç
				for fz in [-0.6, -0.25, 0.15]:   # segmentli bacaklar (yukarı kıvrık diz)
					var hip = Vector3(0.28 * sx, 0.42, fz)
					var knee = hip + Vector3(0.32 * sx, 0.22, fz * 0.15)
					var foot = Vector3(0.75 * sx, 0.02, fz + fz * 0.25)
					Loft.tube(b, [hip, knee], [0.045, 0.035], dk, 6, 1)
					Loft.tube(b, [knee, foot], [0.035, 0.015], dk, 6, 1)
					b.add("sphere", knee, Vector3.ONE * 0.06, sh, Vector3.ZERO, 6)
		"bee":
			# dev eşek arısı: tüylü toraks, ince bel, sarı-siyah çizgili sivri karın, iğne, iri bileşik gözler, damarlı yarı saydam kanatlar
			var y = Color(0.98, 0.78, 0.12)
			var k = Color(0.08, 0.06, 0.05)
			Loft.tube(b, [Vector3(0, 0, -0.68), Vector3(0, 0.02, -0.5)], [Vector2(0.2, 0.18), Vector2(0.18, 0.17)], k, 12, 1)   # baş
			for sx in [-1.0, 1.0]:
				b.add("sphere", Vector3(0.14 * sx, 0.04, -0.62), Vector3(0.13, 0.17, 0.14), Color(0.55, 0.1, 0.06), Vector3(0, 0, -10 * sx), 8)   # bileşik göz
				Loft.tube(b, [Vector3(0.05 * sx, 0.14, -0.74), Vector3(0.12 * sx, 0.35, -0.88), Vector3(0.2 * sx, 0.42, -0.95)], [0.014, 0.012, 0.01], k, 5, 2, true, false)   # anten
				b.add("cone", Vector3(0.06 * sx, -0.12, -0.78), Vector3(0.03, 0.1, 0.03), y.darkened(0.3), Vector3(-30, 0, 20 * sx), 4)   # çene
			b.add_grad("sphere", Vector3(0, 0.03, -0.25), Vector3(0.42, 0.4, 0.46), y.darkened(0.25), k, Vector3.ZERO, 12)   # tüylü toraks
			b.add("cyl", Vector3(0, 0, 0.02), Vector3(0.1, 0.12, 0.1), k, Vector3(90, 0, 0), 8)   # ince bel
			var bands = 6
			for i in bands:
				var t = float(i) / (bands - 1)
				var r = lerpf(0.26, 0.07, t * t)
				b.add("sphere", Vector3(0, -0.04 - t * 0.12, 0.2 + t * 0.68), Vector3(r * 1.9, r * 1.8, 0.24), y if i % 2 == 0 else k, Vector3(-12, 0, 0), 10)
			b.add("cone", Vector3(0, -0.2, 1.02), Vector3(0.04, 0.3, 0.04), k, Vector3(100, 0, 0), 5)   # iğne
			for sx in [-1.0, 1.0]:
				for wi in 2:   # ön ve arka kanat çifti
					var wl = 0.85 - wi * 0.25
					b.add("box", Vector3((0.15 + wl * 0.5) * sx, 0.22 - wi * 0.02, -0.25 + wi * 0.22), Vector3(wl, 0.012, 0.3 - wi * 0.06), Color(0.82, 0.92, 1.0), Vector3(0, (8 + wi * 14) * sx, 12 * sx))
					b.add("box", Vector3((0.15 + wl * 0.5) * sx, 0.23 - wi * 0.02, -0.25 + wi * 0.22), Vector3(wl * 0.9, 0.014, 0.012), Color(0.35, 0.3, 0.25), Vector3(0, (8 + wi * 14) * sx, 12 * sx))   # damar
				for fz in [-0.35, -0.2, -0.05]:
					Loft.tube(b, [Vector3(0.12 * sx, -0.12, fz), Vector3(0.22 * sx, -0.3, fz + 0.05), Vector3(0.2 * sx, -0.5, fz + 0.15)], [0.025, 0.02, 0.012], k, 5, 2, true, false)
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
