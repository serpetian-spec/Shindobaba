class_name HouseKit
extends RefCounted
## Detaylı Japon/Konoha evleri: başlangıçta N şablon üretilir, MultiMesh ile çoğaltılır.
## Her şablon 3 parça: duvarlar (duvar rengiyle boyanır), çatı (çatı rengiyle), detaylar (kendi renkleri).
## Şablon yerel uzayı: taban merkezi (0,0,0), ön cephe -Z (yerel kuzey değil, "sokağa bakan" taraf).

const WOOD := Color(0.42, 0.28, 0.18)
const DARK := Color(0.2, 0.15, 0.12)
const SHOJI := Color(0.95, 0.92, 0.82)
const GLASS := Color(0.55, 0.72, 0.85)
const STONE := Color(0.55, 0.53, 0.5)

static var templates: Array = []   # her biri: {walls, roof, detail, w, d, h, roof_top}


static func ensure(count := 28) -> void:
	if not templates.is_empty():
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = 4242
	for i in count:
		templates.append(_make(rng, i))


static func _make(rng: RandomNumberGenerator, i: int) -> Dictionary:
	var w = rng.randf_range(8.0, 13.0)
	var d = rng.randf_range(7.0, 11.0)
	var floors = [1, 2, 2, 2, 3, 3][rng.randi() % 6]
	var fh = 3.6
	var h = floors * fh + 0.5
	var walls = MB.new()
	var roof = MB.new()
	var det = MB.new()
	var cols = []  # ek çarpışmalar: [merkez, boyut, x ekseni eğimi (derece)]
	var white = Color(1, 1, 1)
	# temel
	det.add("box", Vector3(0, 0.25, 0), Vector3(w + 0.4, 0.5, d + 0.4), STONE)
	# kat kat duvarlar (üst katlar hafif içeride) + kat kirişleri
	for f in floors:
		var inset = 0.0 if f == 0 else 0.25 * f
		var y0 = 0.5 + f * fh
		walls.add("box", Vector3(0, y0 + fh * 0.5, 0), Vector3(w - inset, fh, d - inset), white)
		det.add("box", Vector3(0, y0 + fh - 0.12, 0), Vector3(w - inset + 0.22, 0.26, d - inset + 0.22), WOOD)
		# köşe direkleri
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				det.add("box", Vector3(sx * (w - inset) * 0.5, y0 + fh * 0.5, sz * (d - inset) * 0.5), Vector3(0.24, fh, 0.24), WOOD)
		# pencereler: ön ve yanlar
		var nwin = maxi(1, int((w - inset) / 3.2))
		for k in nwin:
			var x = -(w - inset) * 0.5 + (k + 0.5) * (w - inset) / nwin
			if f == 0 and absf(x) < 1.6:
				continue  # kapı alanı
			_window(det, Vector3(x, y0 + fh * 0.55, -(d - inset) * 0.5), 0.0, rng)
			if rng.randf() < 0.6:
				_window(det, Vector3(x, y0 + fh * 0.55, (d - inset) * 0.5), 180.0, rng)
		for sx in [-1.0, 1.0]:
			if rng.randf() < 0.7:
				_window(det, Vector3(sx * (w - inset) * 0.5, y0 + fh * 0.55, rng.randf_range(-d * 0.2, d * 0.2)), 90.0 * sx, rng)
	# kapı: sürgülü shoji + noren ya da ahşap kapı
	var shop = rng.randf() < 0.45
	var drng = RandomNumberGenerator.new()  # ayrı tohum: şablonların geri kalanı değişmesin
	drng.seed = 9000 + i
	DoorKit.jp_template(det, -d * 0.5, 0.5, shop, drng)
	if shop:
		var nc = [Color(0.15, 0.25, 0.55), Color(0.75, 0.15, 0.12), Color(0.2, 0.35, 0.25), Color(0.5, 0.2, 0.45)][rng.randi() % 4]
		for k in 3:
			det.add("box", Vector3(-0.72 + k * 0.72, 0.5 + 2.25, -d * 0.5 - 0.22), Vector3(0.66, 0.8, 0.03), nc)
		# dükkân tabelası (dikey) + kâğıt fenerler
		det.add("box", Vector3(w * 0.5 - 0.5, 0.5 + 2.6, -d * 0.5 - 0.3), Vector3(0.7, 2.2, 0.12), Color(0.92, 0.88, 0.75))
		for k in 3:
			det.add("box", Vector3(w * 0.5 - 0.5, 0.5 + 3.3 - k * 0.6, -d * 0.5 - 0.38), Vector3(0.36, 0.3, 0.03), DARK)
		for sx in [-1.0, 1.0]:
			det.add("sphere", Vector3(sx * 1.6, 0.5 + 2.5, -d * 0.5 - 0.45), Vector3(0.45, 0.6, 0.45), Color(0.9, 0.2, 0.15), Vector3.ZERO, 8)
			det.add("box", Vector3(sx * 1.6, 0.5 + 2.83, -d * 0.5 - 0.45), Vector3(0.3, 0.08, 0.3), DARK)
		# ön tente
		det.add("box", Vector3(0, 0.5 + 3.05, -d * 0.5 - 0.8), Vector3(w * 0.75, 0.12, 1.5), nc.darkened(0.1), Vector3(-14, 0, 0))
	# balkon
	if floors >= 2 and rng.randf() < 0.45:
		var by = 0.5 + fh
		det.add("box", Vector3(0, by, -d * 0.5 - 0.7), Vector3(w * 0.6, 0.18, 1.4), WOOD)
		for k in 7:
			det.add("box", Vector3(-w * 0.3 + k * w * 0.1, by + 0.5, -d * 0.5 - 1.35), Vector3(0.08, 0.9, 0.08), WOOD.lightened(0.1))
		det.add("box", Vector3(0, by + 0.95, -d * 0.5 - 1.35), Vector3(w * 0.62, 0.1, 0.1), WOOD)
		cols.append([Vector3(0, by, -d * 0.5 - 0.7), Vector3(w * 0.6, 0.25, 1.4), 0.0])
	# dış merdiven (yan cephe)
	if floors >= 2 and rng.randf() < 0.3:
		for k in 10:
			det.add("box", Vector3(w * 0.5 + 0.7, 0.5 + k * fh / 10.0, -d * 0.3 + k * d * 0.06), Vector3(1.3, 0.16, 0.7), DARK.lightened(0.15))
		det.add("box", Vector3(w * 0.5 + 1.35, 0.5 + fh * 0.6, 0.0), Vector3(0.08, 0.9, d * 0.7), DARK, Vector3(-25, 0, 0))
		var run = d * 0.54; var rise = fh * 0.9
		cols.append([Vector3(w * 0.5 + 0.7, 0.5 + rise * 0.5, -d * 0.03), Vector3(1.3, 0.25, sqrt(run * run + rise * rise)), -rad_to_deg(atan2(rise, run))])
	# boru + çiçek saksıları
	if rng.randf() < 0.35:
		det.add("cyl", Vector3(-w * 0.5 - 0.15, h * 0.5, d * 0.25), Vector3(0.22, h, 0.22), Color(0.55, 0.57, 0.6), Vector3.ZERO, 6)
	if rng.randf() < 0.4:
		for k in 3:
			det.add("box", Vector3(-1.6 + k * 1.6 + 2.0, 0.5 + 0.3, -d * 0.5 - 0.45), Vector3(0.8, 0.45, 0.4), Color(0.6, 0.38, 0.25))
			det.add("sphere", Vector3(-1.6 + k * 1.6 + 2.0, 0.5 + 0.75, -d * 0.5 - 0.45), Vector3(0.8, 0.6, 0.5), Color(0.35, 0.6, 0.25), Vector3.ZERO, 6)
	# çatı
	var top_w = w - 0.25 * (floors - 1)
	var top_d = d - 0.25 * (floors - 1)
	var rtype = rng.randi() % 3
	var roof_top = h
	match rtype:
		0:  # Japon beşik çatı, geniş saçak
			var rh = 2.4 + top_d * 0.12
			roof.add("prism", Vector3(0, h + rh * 0.5, 0), Vector3(top_w + 2.0, rh, top_d + 2.0), white)
			det.add("box", Vector3(0, h + 0.06, 0), Vector3(top_w + 2.2, 0.16, top_d + 2.2), DARK)
			det.add("box", Vector3(0, h + rh + 0.12, 0), Vector3(0.45, 0.32, top_d + 2.2), DARK)
			for sz in [-1.0, 1.0]:  # mahya uçları
				det.add("box", Vector3(0, h + rh + 0.3, sz * (top_d * 0.5 + 1.0)), Vector3(0.6, 0.5, 0.4), DARK)
			roof_top = h + rh
		1:  # Konoha yuvarlak çatı (yarım silindir)
			var rr = top_d * 0.5 + 0.6
			var rise = clampf(top_d * 0.16, 1.1, 1.7)
			roof.add_xf("halfcyl", Transform3D(Basis.from_scale(Vector3(top_w + 0.8, rise * 2.0, top_d + 1.2)), Vector3(0, h + 0.1, 0)), white, 16)
			det.add("box", Vector3(0, h + 0.05, 0), Vector3(top_w + 1.0, 0.2, top_d + 1.3), DARK)  # saçak bandı
			roof_top = h + 0.1 + rise
		2:  # düz çatı: korkuluk + su tankı
			roof.add("box", Vector3(0, h + 0.2, 0), Vector3(top_w + 0.6, 0.4, top_d + 0.6), white)
			for sx in [-1.0, 1.0]:
				det.add("box", Vector3(sx * (top_w * 0.5 + 0.25), h + 0.75, 0), Vector3(0.15, 0.7, top_d + 0.6), WOOD.lightened(0.2))
			det.add("box", Vector3(0, h + 0.75, top_d * 0.5 + 0.25), Vector3(top_w + 0.6, 0.7, 0.15), WOOD.lightened(0.2))
			var tx = rng.randf_range(-top_w * 0.25, top_w * 0.25)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					det.add("box", Vector3(tx + sx * 0.8, h + 1.0, sz * 0.8), Vector3(0.15, 1.6, 0.15), DARK)
			det.add_grad("cyl", Vector3(tx, h + 2.6, 0), Vector3(2.6, 2.2, 2.6), Color(0.7, 0.74, 0.78), Color(0.5, 0.53, 0.58), Vector3.ZERO, 14)
			det.add("cyl", Vector3(tx, h + 3.8, 0), Vector3(2.8, 0.25, 2.8), Color(0.45, 0.47, 0.5), Vector3.ZERO, 14)
			roof_top = h + 0.4
	# yan ek bina
	if rng.randf() < 0.3:
		var aw = w * 0.4; var ad = d * 0.55; var ah = 3.2
		walls.add("box", Vector3(-w * 0.5 - aw * 0.5 + 0.1, 0.5 + ah * 0.5, d * 0.1), Vector3(aw, ah, ad), white)
		roof.add("prism", Vector3(-w * 0.5 - aw * 0.5 + 0.1, 0.5 + ah + 0.6, d * 0.1), Vector3(aw + 1.0, 1.2, ad + 1.0), white)
		_window(det, Vector3(-w * 0.5 - aw * 0.5, 0.5 + ah * 0.55, d * 0.1 - ad * 0.5), 0.0, rng)
		cols.append([Vector3(-w * 0.5 - aw * 0.5 + 0.1, (0.5 + ah + 0.6) * 0.5, d * 0.1), Vector3(aw, 0.5 + ah + 0.6, ad), 0.0])
	return {"walls": walls.build(), "roof": roof.build(), "detail": det.build(), "w": w, "d": d, "h": h, "roof_top": roof_top, "cols": cols}


static func _window(b: MB, p: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var r = Basis(Vector3.UP, deg_to_rad(yaw))
	var fwd = r * Vector3(0, 0, -1)
	var right = r * Vector3(1, 0, 0)
	var shoji = rng.randf() < 0.5
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.5, 1.35, 0.12)), p + fwd * 0.05), WOOD)
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.3, 1.15, 0.06)), p + fwd * 0.09), SHOJI if shoji else GLASS)
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(0.05, 1.15, 0.04)), p + fwd * 0.12), DARK)
	b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.3, 0.05, 0.04)), p + fwd * 0.12), DARK)
	if shoji:
		for k in [-1.0, 1.0]:
			b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(1.3, 0.03, 0.04)), p + fwd * 0.12 + Vector3(0, k * 0.3, 0)), DARK)
	if rng.randf() < 0.35:  # küçük saçak
		b.add_xf("box", Transform3D(Basis(right, deg_to_rad(18)) * r * Basis.from_scale(Vector3(1.8, 0.1, 0.7)), p + Vector3(0, 0.85, 0) + fwd * 0.35), Color(0.35, 0.3, 0.28))
	elif rng.randf() < 0.3:  # kepenkler
		for sx in [-1.0, 1.0]:
			b.add_xf("box", Transform3D(r * Basis.from_scale(Vector3(0.35, 1.3, 0.06)), p + right * sx * 0.95 + fwd * 0.08), WOOD.lightened(0.1))


## Bir köy için yerleştirici: evleri toplar, sonunda MultiMesh'leri ve çarpışmaları kurar
class Placer:
	var parent: Node3D
	var key := ""
	var walls := {}   # şablon -> [[xform, color]]
	var roofs := {}
	var dets := {}
	var body: StaticBody3D
	var view := 1500.0

	func _init(p: Node3D, k: String) -> void:
		parent = p
		key = k
		HouseKit.ensure()
		body = StaticBody3D.new()
		body.collision_layer = 1   # sahneye finish()'te eklenir (bkz. Builder._init)

	## pos: Godot dünya (taban merkezi), yaw: derece (Builder yerel yaw), ön cephe sokağa
	var pack_items := {}   # mesh -> [Transform3D]
	var recs: Array = []   # WorldDamage kayıtları (yanma / yıkılma)
	var pack_chance := 0.0  # 0..1: bu oranda ev hazır modelden (renkli Japon kasaba evi)

	func add(pos: Vector3, yaw: float, wall_col: Color, roof_col: Color, rng: RandomNumberGenerator, scale := 1.0) -> Dictionary:
		if pack_chance > 0.0 and rng.randf() < pack_chance:
			var hs: Array = AssetLib.town_houses()
			if not hs.is_empty():
				var e: Array = hs[rng.randi() % hs.size()]
				var sz: Vector3 = e[1]
				var xf2 = Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)).scaled(Vector3.ONE * scale), pos)
				if not pack_items.has(e[0]):
					pack_items[e[0]] = []
				pack_items[e[0]].append(xf2)
				var cs2 = CollisionShape3D.new()
				var sh2 = BoxShape3D.new()
				sh2.size = Vector3(sz.x * 0.9, sz.y, sz.z * 0.9) * scale
				cs2.shape = sh2
				cs2.transform = Transform3D(xf2.basis.orthonormalized(), pos + Vector3(0, sz.y * 0.5 * scale, 0))
				body.add_child(cs2)
				if key != "" and not key.begins_with("yolkenari"):
					if not Builder.roof_points.has(key):
						Builder.roof_points[key] = []
					Builder.roof_points[key].append(pos + Vector3(0, sz.y * scale, 0))
				return {"w": sz.x, "d": sz.z, "h": sz.y * 0.8, "roof_top": sz.y}
		var ti = rng.randi() % HouseKit.templates.size()
		var t: Dictionary = HouseKit.templates[ti]
		var xf = Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw) + PI).scaled(Vector3.ONE * scale), pos)
		var rec = {"pos": pos, "basis": xf.basis, "ti": ti, "scale": scale, "wall": wall_col, "roof": roof_col, "body": body, "mm": [], "shapes": []}
		recs.append(rec)
		for pair in [[walls, wall_col], [roofs, roof_col], [dets, Color(1, 1, 1)]]:
			var dict: Dictionary = pair[0]
			if not dict.has(ti):
				dict[ti] = []
			dict[ti].append([xf, pair[1], rec])
		# çarpışma: gövde + çatı
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = Vector3(t["w"], t["h"], t["d"]) * scale
		cs.shape = sh
		cs.transform = Transform3D(xf.basis.orthonormalized(), pos + Vector3(0, t["h"] * 0.5 * scale, 0))
		body.add_child(cs)
		var rc = CollisionShape3D.new()
		var rs = BoxShape3D.new()
		rs.size = Vector3(t["w"] + 0.6, maxf(0.4, (t["roof_top"] - t["h"]) * 0.6), t["d"] * 0.7) * scale
		rc.shape = rs
		rc.transform = Transform3D(xf.basis.orthonormalized(), pos + Vector3(0, (t["h"] + (t["roof_top"] - t["h"]) * 0.3) * scale, 0))
		body.add_child(rc)
		rec["shapes"] = [cs, rc]
		for c in t.get("cols", []):  # yan ek bina, balkon, dış merdiven
			var ec = CollisionShape3D.new()
			var es = BoxShape3D.new()
			es.size = c[1] * scale
			ec.shape = es
			ec.transform = Transform3D(xf.basis.orthonormalized() * Basis(Vector3.RIGHT, deg_to_rad(c[2])), pos + xf.basis * c[0])
			body.add_child(ec)
			rec["shapes"].append(ec)
		if key != "" and not key.begins_with("yolkenari"):   # iş parçacığında kurulan yol kenarı evleri paylaşılan sözlüğe yazmaz
			if not Builder.roof_points.has(key):
				Builder.roof_points[key] = []
			Builder.roof_points[key].append(pos + Vector3(0, t["roof_top"] * scale, 0))
		return t

	func finish() -> void:
		if is_instance_valid(body) and body.get_parent() == null and is_instance_valid(parent):
			parent.add_child(body)
		for pm in pack_items:
			var xfs: Array = pack_items[pm]
			var cells2 = {}
			for x in xfs:
				var c2 = Vector2i(int(floor(x.origin.x / 160.0)), int(floor(x.origin.z / 160.0)))
				if not cells2.has(c2):
					cells2[c2] = []
				cells2[c2].append(x)
			# yakın: tam model, orta: %12, uzak: %3 (hazır evler çok detaylı)
			var lv = [[pm, 0.0, 110.0], [AssetLib.lod(pm, 0.12), 110.0, 450.0], [AssetLib.lod(pm, 0.03), 450.0, 1500.0]]
			for c2 in cells2:
				var arr: Array = cells2[c2]
				for l in lv:
					var mm = MultiMesh.new()
					mm.transform_format = MultiMesh.TRANSFORM_3D
					mm.use_colors = true
					mm.mesh = l[0]
					mm.instance_count = arr.size()
					for i in arr.size():
						mm.set_instance_transform(i, arr[i])
						mm.set_instance_color(i, Color.WHITE)
					var mmi = MultiMeshInstance3D.new()
					mmi.layers = 2
					mmi.multimesh = mm
					mmi.visibility_range_begin = l[1] * float(Game.settings["view"])
					mmi.visibility_range_begin_margin = 15.0 if l[1] > 0.0 else 0.0
					mmi.visibility_range_end = l[2] * float(Game.settings["view"])
					mmi.visibility_range_end_margin = 30.0
					mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
					if l[1] > 0.0:
						mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					parent.add_child(mmi)
		pack_items.clear()
		for pair in [[walls, "walls"], [roofs, "roof"], [dets, "detail"]]:
			var dict: Dictionary = pair[0]
			for ti in dict:
				var items: Array = dict[ti]
				# 160 m'lik hücrelere böl (görünürlük kırpma için)
				var cells = {}
				for it in items:
					var c = Vector2i(int(floor(it[0].origin.x / 160.0)), int(floor(it[0].origin.z / 160.0)))
					if not cells.has(c):
						cells[c] = []
					cells[c].append(it)
				for c in cells:
					var arr: Array = cells[c]
					var mm = MultiMesh.new()
					mm.transform_format = MultiMesh.TRANSFORM_3D
					mm.use_colors = true
					mm.mesh = HouseKit.templates[ti][pair[1]]
					mm.instance_count = arr.size()
					for i in arr.size():
						mm.set_instance_transform(i, arr[i][0])
						mm.set_instance_color(i, arr[i][1])
						arr[i][2]["mm"].append([mm, i, pair[1], arr[i][0]])
					var mmi = MultiMeshInstance3D.new()
					mmi.layers = 2
					mmi.multimesh = mm
					mmi.material_override = Props.toon()
					mmi.visibility_range_end = view * float(Game.settings["view"])
					mmi.visibility_range_end_margin = 60.0
					mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
					parent.add_child(mmi)
		if not recs.is_empty():
			WorldDamage.register_houses(recs)
			recs = []
