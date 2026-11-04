class_name SummonModels
extends RefCounted
## Çağırma hayvanlarının prosedürel modelleri. Modeller -Z'ye bakar, gerçek boyutta (metre) kurulur.
## Dönen sözlük: {"root": Node3D, "anim": tür ("hop", "slither", "crawl", "fly", "walk", "flock", "biped", "spider"),
##   "legs": [Node3D], "wings": [Node3D], "segments": [Node3D], "head": Node3D, "tail": Node3D, "mouth": Vector3 (yerel)}


static func build(model: String, h: float, length: float) -> Dictionary:
	var out = {"root": Node3D.new(), "anim": "walk", "legs": [], "wings": [], "segments": [], "head": null, "tail": null, "mouth": Vector3(0, h * 0.5, -h * 0.5)}
	# hayran modeli varsa onu kullan (assets/sketchfab)
	# hayran modelleri kaldırıldı: tüm çağrılar kendi prosedürel modellerimiz
	var sf = {}
	if not sf.is_empty():
		out["root"].add_child(sf["node"])
		var names: Array = sf["anims"]
		if sf["player"] and not names.is_empty():
			var pick = func(keys: Array) -> String:
				for nm in names:
					for k in keys:
						if String(nm).to_lower().contains(k):
							return nm
				return names[0]
			out["anim"] = "model"
			out["player"] = sf["player"]
			out["anims"] = {"idle": pick.call(["idle"]), "move": pick.call(["walk", "move", "gallop", "takeoff", "fly", "animation", "principal"]), "attack": pick.call(["attack"])}
		else:
			out["anim"] = "static"
		out["sf"] = sf["node"]
		var sz: Vector3 = sf["size"]
		out["mouth"] = Vector3(0, sz.y * 0.7, -sz.z * 0.45)
		if model == "snake_boss":
			_coil_anim(out, sf["node"], sz)
		return out
	match model:
		"toad_boss":
			_gamabunta(out, h)
		"toad_small":
			_toad(out, model, h)
		"toad_mid":
			_toad_mid(out, h)
		"snake_swarm":
			_snake_swarm(out, h)
		"snake_giant":
			# stilize toon yılan (gerçekçi kobra modeli oyunun cel tarzıyla çakışıyordu)
			var sg = toon_snake(out["root"], length, h, h * 0.19, Color(0.16, 0.12, 0.28), Color(0.95, 0.86, 0.6), Color(0.55, 0.3, 0.9), true)
			out["anim"] = "shader"
			out["mouth"] = sg["mouth"]
		"snake_boss":
			var sb = manda_snake(out["root"], length * 1.9, h, h * 0.42)   # Manda gibi upuzun (solucan değil); dururken çöreklenir
			out["anim"] = "shader"
			out["mouth"] = sb["mouth"]
		"slug_frag", "slug_acid", "slug_queen":
			_slug(out, model, h, length)
		"hawk_small", "hawk_mount", "hawk_giant":
			_hawk(out, model, h)
		"rin_dog":
			_rin_dog(out, h)
		"rin_centipede":
			_rin_centipede(out, h)
		"rin_crab":
			_rin_crab(out, h)
		"rin_rhino", "rin_ox", "rin_panda", "rin_chameleon":
			_rin_beast(out, model, h)
		"dog_small", "dog_pack", "wolf_giant", "wolf3_giant", "dog_giant":
			_dog(out, model, h)
		"monkey_small", "monkey_king":
			_monkey(out, model, h)
		"crow_flock":
			_crows(out, h)
		"salamander":
			_salamander(out, h, length)
		"turtle_small", "turtle_giant":
			_turtle(out, model, h, length)
		"weasel_trio":
			_weasel(out, h)
		"cat_small", "cat_giant":
			_cat(out, model, h, length)
		"spider":
			_spider(out, h)
		_:
			var b = MB.new()
			b.add("sphere", Vector3(0, h * 0.5, 0), Vector3.ONE * h, Color(0.6, 0.5, 0.4), Vector3.ZERO, 10)
			_mesh(out["root"], b)
	var surf = {"toad": 1, "snak": 1, "slug": 3, "hawk": 0, "dog_": 0, "wolf": 0, "monk": 0, "crow": 0, "sala": 1, "turt": 2, "weas": 0, "cat_": 0, "spid": 1}.get(model.substr(0, 4), 0)
	# beyaz sümüklüböcek gölgede maviye kaçıyordu: açık gölge tonu
	var bm = BeastModels.beast_material(surf, Color(0.86, 0.86, 0.84) if model.begins_with("slug") else (Color(0.66, 0.6, 0.56) if model.begins_with("monk") or model == "salamander" or model.begins_with("turt") or model.begins_with("weas") or model.begins_with("dog") or model.begins_with("wolf") or model == "toad_small" or model.begins_with("cat") else Color(0.3, 0.26, 0.4)))
	for mi in out["root"].find_children("*", "MeshInstance3D", true, false):
		if mi.material_override == null and mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) == Props.toon():
			mi.material_override = bm
	return out


static func _mesh(parent: Node3D, b: MB, at := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	mi.position = at
	parent.add_child(mi)
	return mi


static func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var n = Node3D.new()
	n.position = at
	parent.add_child(n)
	return n


# ------------------------------------------------------------------ CC0 hazır modeller (Quaternius, assets/packs): kurbağa, yılan, Shiba
## ref_h: modelin dinlenme pozundaki yüksekliği (ölçek için); recolor: malzeme adı -> renk; anims: idle/move/attack -> klip adı
const PACKS := {
	"frog": {"file": "res://assets/packs/frog.glb", "ref_h": 2.7, "anims": {"idle": "CharacterArmature|Idle", "move": "CharacterArmature|Jump", "attack": "CharacterArmature|Punch"}},
	"snake": {"file": "res://assets/packs/snake.glb", "ref_h": 3.0, "anims": {"idle": "SnakeArmature|Snake_Idle", "move": "SnakeArmature|Snake_Walk", "attack": "SnakeArmature|Snake_Attack"}},
	"shiba": {"file": "res://assets/packs/shiba.glb", "ref_h": 3.1, "anims": {"idle": "AnimalArmature|Idle", "move": "AnimalArmature|Gallop", "attack": "AnimalArmature|Attack"}},
}


static func _pack(out: Dictionary, key: String, h: float, recolor: Dictionary) -> Dictionary:
	var spec: Dictionary = PACKS[key]
	var inst: Node3D = (load(spec["file"]) as PackedScene).instantiate()
	var holder = Node3D.new()
	out["root"].add_child(holder)
	holder.add_child(inst)
	holder.rotation.y = PI          # Quaternius +Z'ye bakar, çağrılar -Z
	var k = h / float(spec["ref_h"])
	holder.scale = Vector3.ONE * k
	var bm = BeastModels.beast_material(1, Color(0.3, 0.26, 0.4))
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		for si in mi.mesh.get_surface_count():
			var sm = mi.mesh.surface_get_material(si)
			var nm = String(sm.resource_name) if sm else ""
			var col = recolor.get(nm, sm.albedo_color if sm is BaseMaterial3D else Color.WHITE)
			var m = ShaderMaterial.new()
			m.shader = load("res://shaders/beast.gdshader")
			m.set_shader_parameter("surface", 1)
			m.set_shader_parameter("stroke", 0.25)
			m.set_shader_parameter("shadow_tint", Color(0.3, 0.26, 0.4))
			m.set_shader_parameter("use_tint", true)
			m.set_shader_parameter("tint", col)
			mi.set_surface_override_material(si, m)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var anims: Dictionary = spec["anims"]
	if ap:
		for a in ["idle", "move"]:
			if ap.has_animation(anims[a]):
				ap.get_animation(anims[a]).loop_mode = Animation.LOOP_LINEAR
		if ap.has_animation(anims["idle"]):
			ap.play(anims["idle"])
	var sk: Skeleton3D = null
	for c in inst.find_children("*", "Skeleton3D", true, false):
		sk = c
	out["anim"] = "model"
	out["player"] = ap
	out["anims"] = anims
	return {"skel": sk, "scale": k, "holder": holder}


## Aksesuarı kemiğe bağlar: model_xf model (ölçeksiz, Quaternius) uzayında
static func _bone_mesh(pk: Dictionary, bone: String, b: MB, model_xf := Transform3D.IDENTITY) -> void:
	var sk: Skeleton3D = pk["skel"]
	if sk == null or sk.find_bone(bone) < 0:
		return
	var ba = BoneAttachment3D.new()
	ba.bone_name = bone
	sk.add_child(ba)
	var hold = Node3D.new()
	ba.add_child(hold)
	hold.transform = sk.get_bone_global_rest(sk.find_bone(bone)).affine_inverse() * model_xf
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	hold.add_child(mi)


static func _bone_pos(pk: Dictionary, bone: String) -> Vector3:
	var sk: Skeleton3D = pk["skel"]
	if sk == null or sk.find_bone(bone) < 0:
		return Vector3.ZERO
	return sk.get_bone_global_rest(sk.find_bone(bone)).origin


# ------------------------------------------------------------------ kurbağalar
## Kurbağalar (REFERANS: anime çağrı kurbağaları): oturur dik duruş — armut gövde, iri yuvarlak baş, kafanın çevresini dolanan geniş ağız çizgisi,
## tepede iri göz kubbeleri. Küçük haberci: sarı, gözün çevresinde turuncu boya, turuncu dudak, mavi yelek, göbekte turuncu sarmallar, mutlu kapalı gözler.
## Orta savaşçı: bordo-pembe, alında öne kıvrık boynuz, yüzü çaprazlayan koyu çizgiler, sol gözde yama, siyah haori, kolda file,
## bir elde iri kalkan, diğerinde çatallı dikenli mızrak (sasumata).
static func _toad(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "hop"
	var root: Node3D = out["root"]
	var mid = model == "toad_mid"
	var c = Color(0.9, 0.74, 0.4) if not mid else Color(0.6, 0.38, 0.42)
	var cd = Color(0.84, 0.66, 0.34) if not mid else Color(0.5, 0.3, 0.35)
	var mark = Color(0.95, 0.5, 0.15) if not mid else Color(0.3, 0.18, 0.2)
	var b = MB.new()
	var skin = func(_t: float, _a: float, d: Vector3) -> Color: return c if d.y > -0.4 else cd
	# armut gövde (oturur, hafif öne eğik)
	Loft.tube(b, [Vector3(0, h * 0.16, h * 0.1), Vector3(0, h * 0.38, h * 0.04), Vector3(0, h * 0.6, -h * 0.03)], [Vector2(0.4, 0.33) * h, Vector2(0.44, 0.36) * h, Vector2(0.36, 0.3) * h], c, 22, 4, true, true, skin)
	# baş: gövdeye kaynaşık iri yuvarlak
	var hc = Vector3(0, h * 0.82, -h * 0.1)
	b.add("sphere", hc, Vector3(0.78, 0.6, 0.7) * h, c, Vector3.ZERO, 18)
	b.add("sphere", hc + Vector3(0, -h * 0.14, -h * 0.08), Vector3(0.7, 0.36, 0.6) * h, c.lightened(0.04), Vector3.ZERO, 16)   # yanak / çene
	# geniş ağız: yüzün önünde yay biçimli dudak çizgisi
	for k in 15:
		var u = (k - 7) / 7.0
		var p = hc + Vector3(u * h * 0.33, -h * 0.16 + u * u * h * 0.07, -h * 0.4 + u * u * h * 0.13)
		b.add("box", p, Vector3(h * 0.06, h * 0.022, h * 0.03), mark if not mid else Color(0.25, 0.12, 0.14), Vector3(0, -u * 40.0, u * 18.0))
	b.add("sphere", hc + Vector3(0, -h * 0.02, -h * 0.4), Vector3(0.05, 0.03, 0.02) * h, cd.darkened(0.3), Vector3.ZERO, 6)   # burun deliği
	# gözler: tepede iki kubbe
	for sx in [-1.0, 1.0]:
		var ec = hc + Vector3(h * 0.2 * sx, h * 0.24, -h * 0.2)
		b.add("sphere", ec, Vector3(0.24, 0.2, 0.22) * h, c, Vector3.ZERO, 12)
		if not mid:
			# mutlu kapalı gözler (beyaz kubbe üstünde kavisli çizgi) + turuncu göz boyası
			b.add("sphere", ec + Vector3(0, h * 0.0, -h * 0.07), Vector3(0.18, 0.16, 0.1) * h, Color(0.98, 0.98, 0.96), Vector3.ZERO, 10)
			for q in 5:
				var u = (q - 2) / 2.0
				b.add("box", ec + Vector3(u * h * 0.05, h * 0.01 + (1.0 - u * u) * h * 0.02, -h * 0.125), Vector3(h * 0.04, h * 0.012, h * 0.01), Color(0.1, 0.08, 0.06), Vector3(0, 0, -u * 30.0))
			b.add("sphere", ec + Vector3(h * 0.08 * sx, -h * 0.06, -h * 0.08), Vector3(0.12, 0.08, 0.06) * h, mark, Vector3.ZERO, 8)
		else:
			# çatık, yatay bebekli sarı gözler
			b.add("sphere", ec + Vector3(0, -h * 0.01, -h * 0.07), Vector3(0.17, 0.12, 0.1) * h, Color(0.92, 0.88, 0.45), Vector3.ZERO, 10)
			b.add("box", ec + Vector3(0, -h * 0.01, -h * 0.125), Vector3(h * 0.1, h * 0.022, h * 0.01), Color(0.08, 0.06, 0.05))
			b.add("box", ec + Vector3(-h * 0.01 * sx, h * 0.06, -h * 0.09), Vector3(h * 0.18, h * 0.03, h * 0.04), c.darkened(0.2), Vector3(0, 0, 14 * sx))   # ağır kapak
	if mid:
		# alında öne kıvrık boynuz
		Loft.tube(b, [hc + Vector3(-h * 0.05, h * 0.32, -h * 0.05), hc + Vector3(-h * 0.08, h * 0.48, -h * 0.12), hc + Vector3(-h * 0.04, h * 0.56, -h * 0.26)], [h * 0.07, h * 0.05, h * 0.01], c.darkened(0.08), 10, 3, true, true)
		# yüzü çaprazlayan koyu çizgiler (gözden çeneye, iki yanda)
		for sx in [-1.0, 1.0]:
			Loft.tube(b, [hc + Vector3(h * 0.3 * sx, h * 0.22, -h * 0.18), hc + Vector3(h * 0.37 * sx, h * 0.02, -h * 0.25), hc + Vector3(h * 0.22 * sx, -h * 0.22, -h * 0.34), hc + Vector3(0, -h * 0.3, -h * 0.34)], [h * 0.022, h * 0.022, h * 0.022, h * 0.015], mark, 6, 3)
		b.add("box", hc + Vector3(h * 0.2, h * 0.23, -h * 0.29), Vector3(0.2, 0.14, 0.02) * h, Color(0.82, 0.78, 0.66), Vector3(0, 0, -10))   # göz yaması
	# giysi
	if not mid:
		var vest = Color(0.16, 0.26, 0.55)
		Loft.tube(b, [Vector3(0, h * 0.32, h * 0.05), Vector3(0, h * 0.5, 0.0), Vector3(0, h * 0.66, -h * 0.04)], [Vector2(0.45, 0.37) * h, Vector2(0.44, 0.36) * h, Vector2(0.39, 0.32) * h], vest, 22, 3, false, false,
			func(_t: float, _a: float, d: Vector3) -> Color: return c if (d.z < -0.5 and absf(d.x) < 0.55) else vest)
		for k in 2:   # göbekte turuncu sarmallar
			var sp = Vector3((k - 0.5) * h * 0.22, h * 0.28 + k * h * 0.06, -h * 0.4)
			for q in 10:
				var t = q / 9.0
				var aa = t * TAU * 1.2
				b.add("sphere", sp + Vector3(cos(aa) * t * h * 0.07, sin(aa) * t * h * 0.07, 0), Vector3.ONE * h * 0.03, mark, Vector3.ZERO, 5)
	else:
		var hao = Color(0.14, 0.13, 0.15)
		Loft.tube(b, [Vector3(0, h * 0.2, h * 0.07), Vector3(0, h * 0.45, h * 0.02), Vector3(0, h * 0.66, -h * 0.03)], [Vector2(0.46, 0.38) * h, Vector2(0.47, 0.39) * h, Vector2(0.4, 0.33) * h], hao, 22, 3, false, false,
			func(_t: float, _a: float, d: Vector3) -> Color: return c if (d.z < -0.6 and absf(d.x) < 0.42) else hao)
	_mesh(root, b)
	# kollar (pivot, zıplamada döner) ve katlanmış iri arka bacaklar
	for side in [-1.0, 1.0]:
		var fa = _pivot(root, Vector3(h * 0.38 * side, h * 0.55, -h * 0.12))
		var am = MB.new()
		var arm_c = c if not mid else Color(0.14, 0.13, 0.15)
		Loft.tube(am, [Vector3.ZERO, Vector3(h * 0.08 * side, -h * 0.22, -h * 0.12), Vector3(h * 0.06 * side, -h * 0.48, -h * 0.2)], [h * 0.11, h * 0.09, h * 0.075], arm_c, 12, 3, true, true)
		if mid:
			for k in 4:   # kolda file
				am.add("torus", Vector3(h * 0.07 * side, -h * (0.28 + k * 0.05), -h * 0.15), Vector3(0.17, 0.17, 0.17) * h, Color(0.35, 0.33, 0.35), Vector3(0, 0, 0), 8)
		for f in 4:   # perdeli parmaklar
			var fd = Vector3((f - 1.5) * 0.35, 0, -1).normalized()
			am.add("sphere", Vector3(h * 0.06 * side, -h * 0.52, -h * 0.22) + fd * h * 0.12, Vector3(h * 0.06, h * 0.03, h * 0.07), c.lightened(0.05), Vector3.ZERO, 6)
		if mid and side > 0.0:   # iri yuvarlak kalkan
			am.add_xf("cyl", Transform3D(Basis(Vector3.UP, deg_to_rad(-30)) * Basis(Vector3.FORWARD, deg_to_rad(90)) * Basis.from_scale(Vector3(h * 0.95, h * 0.08, h * 0.95)), Vector3(h * 0.2, -h * 0.3, -h * 0.35)), Color(0.88, 0.8, 0.6), 20)
			am.add_xf("torus", Transform3D(Basis(Vector3.UP, deg_to_rad(-30)) * Basis(Vector3.FORWARD, deg_to_rad(90)) * Basis.from_scale(Vector3(h * 0.72, h * 0.12, h * 0.72)), Vector3(h * 0.25, -h * 0.3, -h * 0.38)), Color(0.75, 0.66, 0.46), 18)
		if mid and side < 0.0:   # çatallı dikenli mızrak (sasumata)
			# mızrak çapraz tutulur: sap aşağı-geride, çatal yukarı-önde
			var s0 = Vector3(h * 0.06 * side, -h * 0.75, h * 0.35)
			var s1 = Vector3(h * 0.06 * side, h * 0.45, -h * 0.75)
			Loft.tube(am, [s0, s1], [h * 0.035, h * 0.035], Color(0.22, 0.24, 0.32), 8, 2)
			for k in 8:
				BeastRig.claw(am, s0.lerp(s1, 0.2 + k * 0.08), Vector3(0, 1 if k % 2 else -1, 0.3).normalized(), h * 0.06, h * 0.015, Color(0.22, 0.24, 0.32))
			for sx in [-1.0, 1.0]:   # U çatal
				var ax = (s1 - s0).normalized()
				Loft.tube(am, [s1, s1 + Vector3(sx * h * 0.14, 0, 0) + ax * h * 0.04, s1 + Vector3(sx * h * 0.16, 0, 0) + ax * h * 0.25], [h * 0.03, h * 0.028, h * 0.02], Color(0.22, 0.24, 0.32), 6, 2)
		_mesh(fa, am)
		out["legs"].append(fa)
		var hl = _pivot(root, Vector3(h * 0.36 * side, h * 0.22, h * 0.05))
		var lm = MB.new()
		Loft.tube(lm, [Vector3.ZERO, Vector3(h * 0.16 * side, h * 0.04, -h * 0.22), Vector3(h * 0.1 * side, -h * 0.16, -h * 0.06), Vector3(h * 0.12 * side, -h * 0.2, -h * 0.32)], [h * 0.2, h * 0.15, h * 0.09, h * 0.06], c, 12, 3, true, true, skin)
		for f in 4:
			var fd2 = Vector3((f - 1.5) * 0.4, 0, -1).normalized()
			lm.add("sphere", Vector3(h * 0.12 * side, -h * 0.21, -h * 0.34) + fd2 * h * 0.14, Vector3(h * 0.07, h * 0.03, h * 0.08), c.lightened(0.05), Vector3.ZERO, 6)
		_mesh(hl, lm)
		out["legs"].append(hl)
	out["head"] = root
	out["mouth"] = hc + Vector3(0, -h * 0.16, -h * 0.42)


## Savaşçı kurbağa (REFERANS): iri, dik duran; baş gövde kadar geniş (boyunsuz), pembe-eflatun deri, yüzü saran koyu zeytin maske şeridi
## (alındaki hilal boynuzun kökünden gözlerin çevresinden yanaklara inen geniş U), yanlarda ağır kapaklı sarı gözler (yatay bebek), geniş sırıtan ağız;
## koyu kahve kimono, file önkollar ve bilekte ip sargısı, uzun pembe pençeli parmaklar; sol kolda dev krem kubbe kalkan (kalın kenarlı),
## sağ elde kalın dikenli koyu yeşil gövdeli çatal mızrak (sasumata).
static func _toad_mid(out: Dictionary, h: float) -> void:
	out["anim"] = "hop"
	var root: Node3D = out["root"]
	var skin = Color(0.86, 0.45, 0.52)
	var skin_d = Color(0.7, 0.34, 0.42)
	var mask = Color(0.36, 0.34, 0.24)
	var robe = Color(0.3, 0.24, 0.2)
	var net = Color(0.25, 0.25, 0.27)
	var b = MB.new()
	# gövde: geniş armut, kimono içinde
	var bsp = [Vector3(0, h * 0.14, h * 0.08), Vector3(0, h * 0.36, h * 0.04), Vector3(0, h * 0.56, -h * 0.02), Vector3(0, h * 0.68, -h * 0.05)]
	var brd = [Vector2(0.42, 0.34) * h, Vector2(0.46, 0.37) * h, Vector2(0.42, 0.34) * h, Vector2(0.36, 0.3) * h]
	Loft.tube(b, bsp, brd, robe, 22, 4, true, false,
		func(_t: float, _a: float, d: Vector3) -> Color: return skin if (d.z < -0.7 and absf(d.x) < 0.22 and _t > 0.5) else (robe if d.y > -0.6 else skin_d))   # önde V yaka (pembe göğüs)
	# kimono yaka kenarı + kuşak
	for sx in [-1.0, 1.0]:
		Loft.tube(b, [Vector3(h * 0.08 * sx, h * 0.7, -h * 0.3), Vector3(h * 0.14 * sx, h * 0.55, -h * 0.39), Vector3(h * 0.1 * sx, h * 0.36, -h * 0.42)], [Vector2(0.04, 0.015) * h, Vector2(0.045, 0.015) * h, Vector2(0.04, 0.015) * h], robe.lightened(0.15), 6, 3)
	Loft.tube(b, [Vector3(-0.001, h * 0.32, h * 0.04), Vector3(0.001, h * 0.32, h * 0.04)], [Vector2(0.465, 0.375) * h, Vector2(0.465, 0.375) * h], Color(0.2, 0.16, 0.14), 22, 1, false, false)
	# baş: boyunsuz, gövde kadar geniş, öne hafif uzun; yüz kubbesi
	var hc = Vector3(0, h * 0.86, -h * 0.12)
	var hsp = [hc + Vector3(0, -h * 0.05, h * 0.22), hc + Vector3(0, h * 0.02, 0.0), hc + Vector3(0, -h * 0.02, -h * 0.2), hc + Vector3(0, -h * 0.1, -h * 0.3)]
	var hrd = [Vector2(0.4, 0.3) * h, Vector2(0.46, 0.33) * h, Vector2(0.42, 0.3) * h, Vector2(0.34, 0.24) * h]
	Loft.tube(b, hsp, hrd, skin, 24, 5, true, true, func(_t: float, _a: float, d: Vector3) -> Color: return skin if d.y > -0.5 else skin_d)
	# yüz kubbesi üzerinde nokta/normal (yüz parçalarını yüzeye oturtmak için)
	var dc: Vector3 = hsp[3]
	var dr = Vector3(hrd[3].x, hrd[3].y, h * 0.2)
	var dome = func(a: float, e: float, lift := 0.0) -> Vector3:
		var pp = Vector3(dr.x * cos(e) * sin(a), dr.y * sin(e), -dr.z * cos(e) * cos(a))
		var n = Vector3(pp.x / (dr.x * dr.x), pp.y / (dr.y * dr.y), pp.z / (dr.z * dr.z)).normalized()
		return dc + pp + n * lift
	# maske şeridi: boynuz kökünden gözlerin dışından yanaklara, çenenin altında birleşen geniş U
	for sx in [-1.0, 1.0]:
		var pts = []
		for k in 9:
			var t = k / 8.0
			pts.append(dome.call(sx * lerpf(0.25, 1.15, sin(t * PI * 0.5)), lerpf(1.05, -0.55, t), h * 0.012))
		var rr = []
		for k in 9:
			rr.append(Vector2(h * 0.075, h * 0.018))
		Loft.tube(b, pts, rr, mask, 6, 3, true, true)
	# alında öne kıvrılan hilal boynuz (deri renginde, koyu kenar)
	var h0 = hc + Vector3(0, h * 0.3, -h * 0.05)
	Loft.tube(b, [h0 + Vector3(0, 0, h * 0.06), h0 + Vector3(0, h * 0.12, -h * 0.02), h0 + Vector3(0, h * 0.18, -h * 0.16), h0 + Vector3(0, h * 0.14, -h * 0.3)],
		[Vector2(0.05, 0.12) * h, Vector2(0.045, 0.1) * h, Vector2(0.035, 0.06) * h, Vector2(0.01, 0.01) * h], [skin, skin, skin_d, mask], 10, 4, true, true)
	# gözler: yanlarda kubbe, sarı, yatay bebek, ağır üst kapak
	for sx in [-1.0, 1.0]:
		var ec = dome.call(sx * 0.95, 0.55, -h * 0.02)
		b.add("sphere", ec, Vector3(0.17, 0.14, 0.15) * h, skin, Vector3.ZERO, 12)
		var eo = ec + Vector3(h * 0.03 * sx, 0, -h * 0.05)
		b.add("sphere", eo, Vector3(0.13, 0.1, 0.08) * h, Color(0.92, 0.82, 0.32), Vector3(0, -30 * sx, 0), 10)
		b.add("box", eo + Vector3(h * 0.01 * sx, -h * 0.005, -h * 0.04), Vector3(h * 0.08, h * 0.018, h * 0.01), Color(0.08, 0.06, 0.05), Vector3(0, -30 * sx, 0))
		b.add("sphere", eo + Vector3(0, h * 0.04, h * 0.0), Vector3(0.15, 0.06, 0.1) * h, skin_d, Vector3(0, -30 * sx, -12 * sx), 10)   # ağır kapak
	# geniş sırıtan ağız: yüz kubbesinin altında yay, açık renk dudak çizgisi
	var mouth_pts = []
	var mrr = []
	var teeth_pts = []
	var trr = []
	for k in 11:
		var u = (k - 5) / 5.0
		mouth_pts.append(dome.call(u * 1.25, -0.2 + u * u * 0.32, h * 0.015))
		mrr.append(Vector2(h * 0.035, h * 0.012))
		teeth_pts.append(dome.call(u * 1.05, -0.32 + u * u * 0.3, h * 0.012))
		trr.append(Vector2(h * 0.045 * (1.0 - absf(u) * 0.6), h * 0.012))
	Loft.tube(b, teeth_pts, trr, Color(0.96, 0.95, 0.9), 4, 3, true, true)   # sırıtan dişler
	Loft.tube(b, mouth_pts, mrr, Color(0.28, 0.1, 0.14), 4, 3, true, true)
	b.add("sphere", dome.call(0.0, 0.25, h * 0.005), Vector3(0.04, 0.025, 0.02) * h, skin_d.darkened(0.3), Vector3.ZERO, 6)   # burun delikleri
	_mesh(root, b)
	# kollar: kimono kolu, file önkol, ip sargılı bilek, uzun pembe parmaklar (pençeli)
	for side in [-1.0, 1.0]:
		var fa = _pivot(root, Vector3(h * 0.4 * side, h * 0.6, -h * 0.08))
		var am = MB.new()
		var elbow = Vector3(h * 0.1 * side, -h * 0.2, -h * 0.12)
		var wrist = Vector3(h * 0.06 * side, -h * 0.3, -h * 0.4)
		Loft.tube(am, [Vector3.ZERO, elbow], [h * 0.13, h * 0.12], robe, 12, 2)
		Loft.tube(am, [elbow, wrist], [h * 0.085, h * 0.07], net, 10, 2, false, false,
			func(_t: float, a: float, _d: Vector3) -> Color: return net.lightened(0.35) if (int(_t * 10.0) + int((a + 4.0) * 4.0)) % 2 == 0 else skin_d)
		for k in 3:
			am.add("torus", wrist + (elbow - wrist).normalized() * h * (0.02 + k * 0.03), Vector3(0.17, 0.17, 0.17) * h, Color(0.55, 0.45, 0.32), Vector3(70, 0, 0), 10)   # ip sargısı
		am.add("sphere", wrist + Vector3(0, 0, -h * 0.05), Vector3(0.12, 0.08, 0.12) * h, skin, Vector3.ZERO, 8)   # el
		for f in 4:
			var fd = Vector3((f - 1.5) * 0.3, -0.3, -1).normalized()
			var p0 = wrist + Vector3(0, 0, -h * 0.08)
			Loft.tube(am, [p0, p0 + fd * h * 0.12], [h * 0.025, h * 0.02], skin, 6, 1)
			BeastRig.claw(am, p0 + fd * h * 0.12, (fd + Vector3(0, -0.6, 0)).normalized(), h * 0.05, h * 0.012, skin_d.darkened(0.2))
		if side > 0.0:
			# kalın dikenli çatal mızrak: referanstaki gibi göbeğin önünden çapraz — sap elde, çatal aşağı-sola-öne
			var grip = wrist + Vector3(0, 0, -h * 0.06)
			var ax = Vector3(-0.72, -0.12, -0.68).normalized()
			var s0 = grip - ax * h * 0.35
			var s1 = grip + ax * h * 1.0
			var club = Color(0.33, 0.38, 0.3)
			Loft.tube(am, [s0, grip, s1], [h * 0.05, h * 0.055, h * 0.07], club, 10, 2)
			for k in 12:   # gövde boyunca dikenler
				var q = grip.lerp(s1, 0.15 + k * 0.07)
				var aa = k * 2.1
				var nrm = (Vector3(cos(aa), 0, sin(aa)) - ax * Vector3(cos(aa), 0, sin(aa)).dot(ax)).normalized()
				BeastRig.claw(am, q, (nrm + ax * 0.3).normalized(), h * 0.13, h * 0.035, club.darkened(0.15))
			var side_v = ax.cross(Vector3.UP).normalized()
			for sx in [-1.0, 1.0]:   # U çatal
				Loft.tube(am, [s1, s1 + side_v * sx * h * 0.14 + ax * h * 0.04, s1 + side_v * sx * h * 0.16 + ax * h * 0.26], [h * 0.045, h * 0.04, h * 0.02], club, 8, 3, false, true)
		_mesh(fa, am)
		out["legs"].append(fa)
		# katlanmış arka bacaklar (pembe, perdeli pençeli)
		var hl = _pivot(root, Vector3(h * 0.38 * side, h * 0.22, h * 0.05))
		var lm = MB.new()
		Loft.tube(lm, [Vector3.ZERO, Vector3(h * 0.18 * side, h * 0.04, -h * 0.22), Vector3(h * 0.12 * side, -h * 0.16, -h * 0.06), Vector3(h * 0.14 * side, -h * 0.2, -h * 0.32)], [h * 0.2, h * 0.15, h * 0.09, h * 0.06], skin, 12, 3, true, true)
		for f in 4:
			var fd2 = Vector3((f - 1.5) * 0.4, 0, -1).normalized()
			Loft.tube(lm, [Vector3(h * 0.14 * side, -h * 0.2, -h * 0.32), Vector3(h * 0.14 * side, -h * 0.21, -h * 0.32) + fd2 * h * 0.16], [h * 0.03, h * 0.02], skin, 6, 1)
			BeastRig.claw(lm, Vector3(h * 0.14 * side, -h * 0.21, -h * 0.32) + fd2 * h * 0.16, (fd2 + Vector3(0, -0.5, 0)).normalized(), h * 0.05, h * 0.012, skin_d.darkened(0.2))
		_mesh(hl, lm)
		out["legs"].append(hl)
	# dev kubbe kalkan
	var sh = MB.new()
	# sol yanda dik duran uzun oval kubbe kalkan (kubbe dışa-öne bakar, üstü başı aşar, alt ucu yerde)
	var sc = Vector3(-h * 0.62, h * 0.72, -h * 0.12)
	var sb = Basis(Vector3.UP, deg_to_rad(-28.0)) * Basis(Vector3.BACK, deg_to_rad(90.0))
	sh.add_xf("hemi", Transform3D(sb * Basis.from_scale(Vector3(h * 1.4, h * 0.42, h * 0.95)), sc), Color(0.9, 0.85, 0.7), 24)
	sh.add_xf("torus", Transform3D(sb * Basis.from_scale(Vector3(h * 1.43, h * 0.5, h * 0.98)), sc), Color(0.78, 0.7, 0.52), 24)
	_mesh(root, sh)
	out["head"] = root
	out["mouth"] = dome.call(0.0, -0.25, 0.0)


## Gamabunta (kurbağa reisi): çömelik sumo duruşu, kiremit kırmızısı siğilli deri, koyu lacivert açık haori (beyaz yaka, göğüste beyaz arma),
## beyaz sarashi karın sargısı, iri baş: ağır kaş tümsekleri, yatay bebekli sarı gözler, gözden dudağa koyu kırmızı boya, kalın koyu kırmızı dudak,
## sol gözde yara izi, alında kırmızı sarmal; ağızda uzun ince kiseru pipo (altın halkalı), belde kısa kılıç (dosu)
static func _gamabunta(out: Dictionary, h: float) -> void:
	out["anim"] = "hop"
	var root: Node3D = out["root"]
	var c = Color(0.66, 0.4, 0.38); var cd = Color(0.5, 0.28, 0.28); var paint = Color(0.6, 0.08, 0.1); var lip = Color(0.45, 0.1, 0.13)
	var wart = Color(0.76, 0.5, 0.46); var vest = Color(0.16, 0.17, 0.3); var white = Color(0.95, 0.94, 0.9); var gold = Color(0.82, 0.72, 0.4)
	var skin = func(_t: float, _a: float, d: Vector3) -> Color:
		return c if d.y > -0.4 else cd
	var b = MB.new()
	# gövde: armut, hafif öne eğik (oturur gibi), dizlerin arasında
	var tsp = [Vector3(0, h * 0.18, h * 0.12), Vector3(0, h * 0.4, h * 0.04), Vector3(0, h * 0.64, -h * 0.04), Vector3(0, h * 0.78, -h * 0.08)]
	var trd = [Vector2(h * 0.36, h * 0.3), Vector2(h * 0.42, h * 0.34), Vector2(h * 0.38, h * 0.3), Vector2(h * 0.3, h * 0.25)]
	Loft.tube(b, tsp, trd, c, 24, 5, true, true, skin)
	# beyaz sarashi karın sargısı
	for k in 4:
		var y = h * (0.2 + k * 0.055)
		b.add_xf("torus", Transform3D(Basis.from_scale(Vector3(h * 0.86, h * 0.07, h * 0.7)), Vector3(0, y, h * 0.1 - k * h * 0.012)), white, 20)
	# haori: gövdeyi saran açık ceket (önü açık; beyaz yaka şeritleri), kısa kollar
	Loft.tube(b, [Vector3(0, h * 0.3, h * 0.06), Vector3(0, h * 0.56, -h * 0.01), Vector3(0, h * 0.78, -h * 0.07)], [Vector2(h * 0.47, h * 0.38), Vector2(h * 0.46, h * 0.37), Vector2(h * 0.42, h * 0.32)], vest, 24, 3, false, false,
		func(_t: float, _a: float, d: Vector3) -> Color: return c if (d.z < -0.82 and absf(d.x) < 0.32) else vest)   # önü açık: göğüs derisi görünür
	for sx in [-1.0, 1.0]:
		# beyaz yaka: boyundan göğsün önüne inen şerit
		Loft.tube(b, [Vector3(h * 0.12 * sx, h * 0.68, -h * 0.28), Vector3(h * 0.2 * sx, h * 0.56, -h * 0.4), Vector3(h * 0.26 * sx, h * 0.4, -h * 0.37)], [Vector2(h * 0.05, h * 0.02), Vector2(h * 0.05, h * 0.02), Vector2(h * 0.05, h * 0.02)], white, 6, 3)
		# göğüste beyaz arma (yuvarlak, içinde koyu sembol)
		b.add_xf("cyl", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(80)) * Basis.from_scale(Vector3(h * 0.12, h * 0.01, h * 0.12)), Vector3(h * 0.3 * sx, h * 0.55, -h * 0.33)), white, 16)
		b.add_xf("torus", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(80)) * Basis.from_scale(Vector3(h * 0.07, h * 0.02, h * 0.07)), Vector3(h * 0.3 * sx, h * 0.55, -h * 0.345)), vest, 12)
	# sırtta büyük beyaz arma
	b.add_xf("cyl", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-80)) * Basis.from_scale(Vector3(h * 0.26, h * 0.01, h * 0.26)), Vector3(0, h * 0.54, h * 0.42)), white, 20)
	b.add_xf("torus", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-80)) * Basis.from_scale(Vector3(h * 0.15, h * 0.03, h * 0.15)), Vector3(0, h * 0.54, h * 0.435)), vest, 14)
	# göğüste kırmızı alev boyası (haori arasından görünür)
	for k in 3:
		Loft.tube(b, [Vector3((k - 1) * h * 0.06, h * 0.46, -h * 0.4), Vector3((k - 1) * h * 0.08, h * 0.54, -h * 0.38), Vector3((k - 1) * h * 0.04, h * 0.6, -h * 0.33)], [Vector2(h * 0.02, h * 0.005), Vector2(h * 0.025, h * 0.005), Vector2(h * 0.005, h * 0.005)], paint, 4, 3)
	_mesh(root, b)
	# baş: iri, geniş, gövdeye gömülü
	var hd = _pivot(root, Vector3(0, h * 0.9, -h * 0.18))
	hd.rotation.x = deg_to_rad(-8.0)
	hd.scale = Vector3.ONE * 1.15
	var hb = MB.new()
	var ksp = [Vector3(0, -h * 0.02, h * 0.18), Vector3(0, h * 0.04, 0.0), Vector3(0, 0.0, -h * 0.16), Vector3(0, -h * 0.06, -h * 0.26)]
	var krd = [Vector2(h * 0.3, h * 0.24), Vector2(h * 0.36, h * 0.27), Vector2(h * 0.34, h * 0.26), Vector2(h * 0.3, h * 0.22)]
	Loft.tube(hb, ksp, krd, c, 24, 5, true, true, skin)
	# siğiller: başta ve kaşlarda yuvarlak tümsekler
	var rng = RandomNumberGenerator.new()
	rng.seed = 1717
	for i in 26:
		var d = BeastModels._tube_pt(ksp, krd, rng.randf_range(0.15, 0.85), rng.randf_range(0.4, PI - 0.4), 0.0)
		var w = h * rng.randf_range(0.018, 0.035)
		hb.add("sphere", d[0], Vector3(w, w * 0.6, w), wart, Vector3.ZERO, 8)
	# yüz = tüpün ön kubbesi (elipsoid); yüz parçaları bu yüzeye oturtulur
	var dc: Vector3 = ksp[3]; var dr = Vector3((krd[3] as Vector2).x, (krd[3] as Vector2).y, (krd[3] as Vector2).length() * 0.5)
	var dome = func(a: float, e: float, lift := 0.0) -> Array:
		var pp = Vector3(dr.x * cos(e) * sin(a), dr.y * sin(e), -dr.z * cos(e) * cos(a))
		var n = Vector3(pp.x / (dr.x * dr.x), pp.y / (dr.y * dr.y), pp.z / (dr.z * dr.z)).normalized()
		return [dc + pp + n * lift, n]
	var strip = func(pts: Array, w: float, col: Color) -> void:
		var rr2: Array = []
		for k in pts.size():
			rr2.append(Vector2(w * (0.35 + 0.65 * sin(PI * (k + 0.5) / pts.size())), h * 0.008))
		Loft.tube(hb, pts, rr2, col, 4, 3, true, true)
	# alında kırmızı sarmal
	var sw: Array = []
	for k in 10:
		var a = k * 0.8
		var rr = 0.16 * (1.0 - k / 12.0)
		sw.append(dome.call(sin(a) * rr, 0.95 + cos(a) * rr, h * 0.012)[0])
	strip.call(sw, h * 0.022, paint)
	for sx in [-1.0, 1.0]:
		# ağır kaş tümseği: gözün üstünde öne çıkık
		var bp = dome.call(0.62 * sx, 0.78, h * 0.03)
		hb.add_xf("sphere", Transform3D(Basis.looking_at(-(bp[1] as Vector3), Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-20 * sx)) * Basis.from_scale(Vector3(h * 0.17, h * 0.07, h * 0.1)), bp[0]), c.lightened(0.04), 12)
		# göz: kırmızı çerçeve, sarı iris, yatay koyu bebek, üst kapak (kızgın)
		var eg = dome.call(0.6 * sx, 0.5, 0.0)
		var nrm: Vector3 = ((eg[1] as Vector3) + Vector3(0, 0, -0.6)).normalized()
		var ep: Vector3 = (eg[0] as Vector3) + nrm * h * 0.02
		var eb = Basis.looking_at(-nrm, Vector3.UP)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(h * 0.16, h * 0.12, h * 0.05)), ep), paint, 12)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(h * 0.125, h * 0.095, h * 0.06)), ep + nrm * h * 0.006), Color(0.08, 0.04, 0.03), 12)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(h * 0.105, h * 0.08, h * 0.065)), ep + nrm * h * 0.01), Color(0.98, 0.82, 0.25), 12)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(h * 0.07, h * 0.018, h * 0.07)), ep + nrm * h * 0.014), Color(0.06, 0.03, 0.02), 8)
		hb.add_xf("sphere", Transform3D(eb * Basis(Vector3.BACK, deg_to_rad(14 * sx)) * Basis.from_scale(Vector3(h * 0.15, h * 0.035, h * 0.07)), ep + eb.y * h * 0.06 + nrm * h * 0.008), cd, 10)
		# gözden ağız köşesine inen koyu kırmızı boya şeridi + kaş üstü boya
		var pl: Array = []
		for k in 6:
			var u = k / 5.0
			pl.append(dome.call(lerpf(0.78, 1.15, u) * sx, lerpf(0.42, -0.18, u), h * 0.01)[0])
		strip.call(pl, h * 0.04, paint)
		var pb: Array = []
		for k in 5:
			var u = k / 4.0
			pb.append(dome.call(lerpf(0.3, 0.95, u) * sx, lerpf(0.62, 0.68, u), h * 0.012)[0])
		strip.call(pb, h * 0.018, paint)
		# burun delikleri
		hb.add("sphere", dome.call(0.14 * sx, 0.15, 0.0)[0], Vector3(h * 0.02, h * 0.012, h * 0.015), Color(0.2, 0.06, 0.06), Vector3.ZERO, 6)
	# kalın dudak: ağız yüzün önünden yanlara geriye uzanır
	var lp: Array = []
	for k in 15:
		var a = lerpf(-1.45, 1.45, k / 14.0)
		lp.append(dome.call(a, -0.28 + 0.12 * absf(a) / 1.45, h * 0.012)[0])
	var lr: Array = []
	lr.resize(lp.size())
	lr.fill(Vector2(h * 0.032, h * 0.022))
	Loft.tube(hb, lp, lr, lip, 8, 3, true, true)
	# alt dudak / çene altı kıvrımları
	for k in 2:
		var cl2: Array = []
		for q in 7:
			var a = lerpf(-0.7, 0.7, q / 6.0)
			cl2.append(dome.call(a, -0.55 - k * 0.18, h * 0.01)[0])
		strip.call(cl2, h * 0.012, cd)
	# sol gözde yara izi: kaştan yanağa açık renk çizik
	var sc: Array = []
	for k in 5:
		var u = k / 4.0
		sc.append(dome.call(lerpf(-0.42, -0.7, u), lerpf(1.0, 0.05, u), h * 0.014)[0])
	strip.call(sc, h * 0.022, wart.lightened(0.35))
	# kiseru pipo: ağzın sağ köşesinden öne-yana uzanan ince sap, altın halkalar, ucunda çanak
	var p0: Vector3 = dome.call(1.05, -0.22, h * 0.01)[0]
	var p1 = p0 + Vector3(h * 0.35, -h * 0.02, -h * 0.35)
	Loft.tube(hb, [p0, p1], [h * 0.012, h * 0.012], Color(0.35, 0.18, 0.1), 8, 2)
	for k in 3:
		var q = p0.lerp(p1, 0.1 + k * 0.4)
		hb.add_xf("cyl", Transform3D(Basis.looking_at((p1 - p0).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(h * 0.03, h * 0.025, h * 0.03)), q), gold, 10)
	hb.add_xf("cyl", Transform3D(Basis.from_scale(Vector3(h * 0.05, h * 0.05, h * 0.05)), p1 + Vector3(0, h * 0.02, 0)), gold, 12)   # çanak
	_mesh(hd, hb)
	out["head"] = hd
	# kollar: güçlü, yere dayalı, dört kalın parmak; haori kolu omuzda
	for side in [-1.0, 1.0]:
		var fa = _pivot(root, Vector3(h * 0.42 * side, h * 0.68, -h * 0.08))
		var am = MB.new()
		var el = Vector3(h * 0.14 * side, -h * 0.3, -h * 0.06)
		var wr = Vector3(h * 0.04 * side, -h * 0.63, -h * 0.24)
		Loft.tube(am, [Vector3.ZERO, el, wr], [h * 0.1, h * 0.085, h * 0.07], c, 12, 3, true, true, skin)
		Loft.tube(am, [Vector3(0, h * 0.04, 0), el * 0.55 + Vector3(0, h * 0.02, 0)], [Vector2(h * 0.15, h * 0.13), Vector2(h * 0.14, h * 0.12)], vest, 14, 2, true, true)   # haori kolu
		for f in 4:
			var fd = Vector3((f - 1.5) * 0.45, -0.25, -1).normalized()
			var f1 = wr + fd * h * 0.12
			Loft.tube(am, [wr, f1, f1 + Vector3(0, -h * 0.03, -h * 0.02)], [h * 0.035, h * 0.03, h * 0.035], c, 8, 2, true, true)
			am.add("sphere", f1 + Vector3(0, -h * 0.03, -h * 0.025), Vector3(h * 0.045, h * 0.025, h * 0.045), wart, Vector3.ZERO, 6)
		_mesh(fa, am)
		out["legs"].append(fa)
		# arka bacaklar: geniş açık çömelik (sumo), diz yukarıda-yanda, büyük perdeli ayak
		var hl = _pivot(root, Vector3(h * 0.3 * side, h * 0.22, h * 0.12))
		var lm = MB.new()
		var knee = Vector3(h * 0.32 * side, h * 0.12, -h * 0.12)
		var ankle = Vector3(h * 0.26 * side, -h * 0.18, h * 0.02)
		Loft.tube(lm, [Vector3.ZERO, knee, ankle], [h * 0.17, h * 0.13, h * 0.08], c, 14, 3, true, true, skin)
		for f in 4:
			var fd2 = Vector3((f - 1.5) * 0.45 + 0.3 * side, 0, -1).normalized()
			var f2 = ankle + Vector3(0, -h * 0.02, 0) + fd2 * h * 0.16
			Loft.tube(lm, [ankle + Vector3(0, -h * 0.02, 0), f2], [h * 0.04, h * 0.03], c, 8, 2, true, true)
			lm.add("sphere", f2, Vector3(h * 0.05, h * 0.025, h * 0.05), wart, Vector3.ZERO, 6)
		_mesh(hl, lm)
		out["legs"].append(hl)
	# belde kısa kılıç (dosu): sağ yanda, kın + sap, sarashiye sokulu
	var s = MB.new()
	var k0 = Vector3(h * 0.42, h * 0.24, -h * 0.08); var k1 = k0 + Vector3(-h * 0.05, -h * 0.1, h * 0.55)
	Loft.tube(s, [k0, k1], [Vector2(h * 0.04, h * 0.025), Vector2(h * 0.035, h * 0.022)], Color(0.3, 0.18, 0.1), 8, 1)
	s.add_xf("cyl", Transform3D(Basis.looking_at((k1 - k0).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(h * 0.07, h * 0.012, h * 0.07)), k0), gold, 12)
	Loft.tube(s, [k0, k0 - (k1 - k0).normalized() * h * 0.16], [h * 0.025, h * 0.025], Color(0.12, 0.1, 0.12), 8, 1)
	_mesh(root, s)
	out["mouth"] = Vector3(0, h * 0.7, -h * 0.5)


# ------------------------------------------------------------------ yılanlar (stilize toon; eski paket modeli kaldırıldı)
static func _snake(out: Dictionary, model: String, h: float, length: float) -> void:
	var boss = model == "snake_boss"
	var sg = toon_snake(out["root"], maxf(length, h * 6.0), h, h * 0.2, Color(0.5, 0.22, 0.8) if boss else Color(0.2, 0.42, 0.24), Color(0.97, 0.88, 0.62), Color(0.3, 0.1, 0.5) if boss else Color(0.1, 0.22, 0.1), boss)
	out["anim"] = "shader"
	out["mouth"] = sg["mouth"]


# ------------------------------------------------------------------ ninja köpekleri (kendi modelimiz)
static func _dog(out: Dictionary, model: String, h: float) -> void:
	_dog_proc(out, model, h)


# ------------------------------------------------------------------ yılanlar (stilize toon)
static func _snake_swarm(out: Dictionary, h: float) -> void:
	out["anim"] = "flock"
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	var pal = [[Color(0.25, 0.62, 0.3), Color(0.95, 0.9, 0.55), Color(0.1, 0.3, 0.12)], [Color(0.5, 0.28, 0.82), Color(0.96, 0.86, 0.66), Color(0.25, 0.1, 0.45)],
		[Color(0.9, 0.7, 0.15), Color(0.98, 0.95, 0.75), Color(0.45, 0.25, 0.05)]]
	for k in 6:
		var n = Node3D.new()
		n.position = Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
		out["root"].add_child(n)
		var c: Array = pal[k % 3]
		toon_snake(n, 1.7, h * 0.6, 0.075, c[0], c[1], c[2], false)
		out["segments"].append(n)


## Stilize toon yılan: tek parça gövde (yükselen boyun + yere yatan gövde, incelen kuyruk), krem karın, sırtta koyu baklava
## desenleri, iri anime gözleri, sivri dişler, isteğe bağlı kobra başlığı. beast.gdshader "sürünme" deformasyonu ve
## SnakeAnim ile canlanır (yanal sinüs dalgası, baş salınımı, ısırma atılışı, çatal dil). Ön -Z, taban y=0, uzunluk ortalı.
static func toon_snake(parent: Node3D, L: float, raise: float, r: float, back: Color, belly: Color, mark: Color, hood: bool) -> Dictionary:
	var holder = Node3D.new()
	parent.add_child(holder)
	var mb = MB.new()
	var z0 = -L * 0.5
	var hr = r * 1.25   # baş yarıçapı
	var pts = [Vector3(0, raise, z0 + hr * 1.2), Vector3(0, raise * 0.92, z0 + L * 0.07), Vector3(0, raise * 0.55, z0 + L * 0.15),
		Vector3(0, r * 1.3, z0 + L * 0.26), Vector3(0, r * 0.95, z0 + L * 0.4), Vector3(0, r * 0.9, z0 + L * 0.6), Vector3(0, r * 0.7, z0 + L * 0.8),
		Vector3(0, r * 0.35, z0 + L * 0.98)]
	var rads = [Vector2(r * 0.85, r * 0.8), Vector2(r * 0.9, r * 0.85), Vector2(r, r * 0.92), Vector2(r * 1.1, r * 0.95), Vector2(r * 1.15, r * 0.95),
		Vector2(r * 1.0, r * 0.88), Vector2(r * 0.6, r * 0.55), Vector2(r * 0.08, r * 0.08)]
	var col_fn = func(tt: float, a: float, d: Vector3) -> Color:
		if d.y < -0.35:
			return belly
		var band = absf(fposmod(tt * 16.0, 1.0) - 0.5) * 2.0
		var side = absf(sin(a))
		if band + (1.0 - side) * 0.6 < 0.55 and d.y > -0.1:
			return mark
		return back.lerp(back.lightened(0.18), clampf(d.y, 0.0, 1.0))
	Loft.tube(mb, pts, rads, back, 14, 4, false, true, col_fn)
	# baş: yassı, öne sivrilen; çene alt kısmı krem
	var hc = Vector3(0, raise, z0 + hr * 0.4)
	mb.add("sphere", hc, Vector3(hr * 2.0, hr * 1.25, hr * 2.6), back, Vector3.ZERO, 14)
	mb.add("sphere", hc + Vector3(0, -hr * 0.28, -hr * 0.2), Vector3(hr * 1.7, hr * 0.7, hr * 2.4), belly, Vector3.ZERO, 12)
	mb.add("sphere", hc + Vector3(0, hr * 0.15, -hr * 0.9), Vector3(hr * 1.2, hr * 0.8, hr * 1.4), back.lightened(0.08), Vector3.ZERO, 10)   # burun
	for sx in [-1.0, 1.0]:
		# iri anime gözü: sarı iris + dikey kara göz bebeği + parlama, üstünde kaş sırtı
		var ep = hc + Vector3(hr * 0.72 * sx, hr * 0.32, -hr * 0.35)
		mb.add("sphere", ep, Vector3(hr * 0.55, hr * 0.6, hr * 0.55), Color(1.0, 0.85, 0.15), Vector3.ZERO, 10)
		mb.add("sphere", ep + Vector3(hr * 0.12 * sx, 0, -hr * 0.05), Vector3(hr * 0.12, hr * 0.5, hr * 0.3), Color(0.05, 0.03, 0.05), Vector3.ZERO, 8)
		mb.add("sphere", ep + Vector3(hr * 0.2 * sx, hr * 0.15, -hr * 0.15), Vector3(hr * 0.12, hr * 0.12, hr * 0.12), Color(1, 1, 1), Vector3.ZERO, 6)
		mb.add("sphere", ep + Vector3(-hr * 0.05 * sx, hr * 0.28, 0), Vector3(hr * 0.6, hr * 0.2, hr * 0.6), back.darkened(0.25), Vector3(0, 0, 18 * sx), 8)
		# sivri diş
		mb.add("cone", hc + Vector3(hr * 0.35 * sx, -hr * 0.45, -hr * 1.05), Vector3(hr * 0.16, hr * 0.5, hr * 0.16), Color(0.98, 0.97, 0.92), Vector3(180, 0, 0), 6)
	if hood:
		# kobra başlığı: boynun arkasında açılan yelpaze, içi açık renk desenli
		var hp = Vector3(0, raise * 0.88, z0 + L * 0.085)
		mb.add("sphere", hp, Vector3(r * 4.2, r * 3.4, r * 0.9), back, Vector3(-12, 0, 0), 16)
		mb.add("sphere", hp + Vector3(0, 0, -r * 0.3), Vector3(r * 3.2, r * 2.6, r * 0.6), belly.lerp(mark, 0.25), Vector3(-12, 0, 0), 14)
		for sx in [-1.0, 1.0]:
			mb.add("sphere", hp + Vector3(r * 0.9 * sx, r * 0.4, -r * 0.55), Vector3(r * 0.8, r * 1.0, r * 0.2), mark, Vector3(-12, 0, 0), 10)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/beast.gdshader")
	mat.set_shader_parameter("surface", 1)
	mat.set_shader_parameter("stroke", 0.3)
	mat.set_shader_parameter("shadow_tint", Color(0.3, 0.22, 0.42))
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(mat)
	mi.material_override = mat
	holder.add_child(mi)
	var size = Vector3(r * 4.2 if hood else r * 2.4, raise + hr, L)
	var mouth = hc + Vector3(0, -hr * 0.2, -hr * 1.4)
	var an = SnakeAnim.new()
	an.name = "SnakeAnim"
	holder.add_child(an)
	an.setup(2, holder, [mat], size, Vector3.ZERO, mouth, hr * 1.6)
	return {"node": holder, "mouth": mouth, "anim": an}


## Yılan hükümdarı (REFERANS: Manda): tozlu mor-gri kalın gövde, kenarları tırtıklı koyu zeytin-kahve halka bantlar,
## sırt boyunca açık parlak şerit; zırh plakalı yassı iri baş, geriye savrulan dört boynuz (iki büyük alın, iki küçük yan),
## ağır kaş altında çekik yeşil göz, geniş açık ağız (kızıl-kahve iç, sivri dişler), kobra başlığı yok
static func manda_snake(parent: Node3D, L: float, raise: float, r: float) -> Dictionary:
	var holder = Node3D.new()
	parent.add_child(holder)
	var back = Color(0.44, 0.38, 0.46); var dark = Color(0.16, 0.15, 0.08); var hi = Color(0.8, 0.76, 0.8)
	var belly = Color(0.55, 0.48, 0.54); var mouth_c = Color(0.48, 0.22, 0.18); var tooth = Color(0.96, 0.95, 0.9)
	var mb = MB.new()
	var z0 = -L * 0.5
	var hr = r * 1.15   # baş yarıçapı
	var pts = [Vector3(0, raise, z0 + hr * 1.6), Vector3(0, raise * 0.9, z0 + L * 0.08), Vector3(0, raise * 0.5, z0 + L * 0.16),
		Vector3(0, r * 1.25, z0 + L * 0.27), Vector3(0, r * 1.0, z0 + L * 0.42), Vector3(0, r * 0.95, z0 + L * 0.6), Vector3(0, r * 0.7, z0 + L * 0.8),
		Vector3(0, r * 0.3, z0 + L * 0.985)]
	var rads = [Vector2(r * 0.95, r * 0.9), Vector2(r * 1.0, r * 0.95), Vector2(r * 1.1, r * 1.0), Vector2(r * 1.2, r * 1.05), Vector2(r * 1.22, r * 1.05),
		Vector2(r * 1.05, r * 0.92), Vector2(r * 0.62, r * 0.56), Vector2(r * 0.08, r * 0.08)]
	var col_fn = func(tt: float, a: float, d: Vector3) -> Color:
		if d.y < -0.45:
			return belly
		# tırtıklı kenarlı koyu bant: bant fazı açıya göre dalgalanır (fırça darbesi gibi)
		var ph = fposmod(tt * 19.0 + sin(a * 7.0 + tt * 40.0) * 0.06 + sin(a * 3.0) * 0.05, 1.0)
		if ph < 0.2:
			return dark
		if ph < 0.24 or ph > 0.97:
			return dark.lerp(back, 0.55)
		# sırtta açık parlak şerit
		if d.y > 0.82:
			return hi
		return back.lerp(back.lightened(0.12), clampf(d.y, 0.0, 1.0))
	Loft.tube(mb, pts, rads, back, 18, 6, false, true, col_fn)
	# ---- baş: yassı, geniş, öne doğru daralan; plaka dikişleri
	var hc = Vector3(0, raise, z0 + hr * 0.5)
	# uzun kama baş: arkası geniş, burun öne uzar ve basıklaşır
	var hsp = [hc + Vector3(0, 0.0, hr * 1.2), hc + Vector3(0, hr * 0.1, 0.0), hc + Vector3(0, 0.0, -hr * 1.3), hc + Vector3(0, -hr * 0.15, -hr * 2.6), hc + Vector3(0, -hr * 0.22, -hr * 3.2)]
	var hrd = [Vector2(hr * 1.0, hr * 0.62), Vector2(hr * 1.3, hr * 0.66), Vector2(hr * 1.15, hr * 0.52), Vector2(hr * 0.85, hr * 0.38), Vector2(hr * 0.45, hr * 0.22)]
	Loft.tube(mb, hsp, hrd, back, 18, 5, true, true, func(_t: float, _a: float, d: Vector3) -> Color: return back.lightened(0.06) if d.y > -0.2 else belly)
	var plates = [[0.0, 0.66, -0.2, 0.9], [0.0, 0.56, -1.2, 0.8], [0.45, 0.5, -0.6, 0.6], [-0.45, 0.5, -0.6, 0.6], [0.0, 0.4, -2.1, 0.6], [0.3, 0.38, -2.4, 0.4], [-0.3, 0.38, -2.4, 0.4], [0.3, 0.6, 0.5, 0.5], [-0.3, 0.6, 0.5, 0.5]]
	for pl in plates:   # zırh plakası çizgileri: baş yüzeyine oturan ince koyu dikişler
		var sp = BeastModels._tube_pt(hsp, hrd, clampf(0.5 - float(pl[2]) / 4.4, 0.05, 0.95), PI * 0.5 - float(pl[0]) * 0.9, hr * 0.01)
		mb.add_xf("box", Transform3D(Basis.looking_at(-(sp[1] as Vector3), Vector3(0, 0, -1)) * Basis(Vector3.BACK, deg_to_rad(35.0 * signf(float(pl[0]) + 0.001))) * Basis.from_scale(Vector3(hr * float(pl[3]), hr * 0.035, hr * 0.03)), sp[0]), dark, 1)
	for sx in [-1.0, 1.0]:
		# ağır kaş çıkıntısı
		mb.add("sphere", hc + Vector3(hr * 0.55 * sx, hr * 0.55, -hr * 0.45), Vector3(hr * 0.75, hr * 0.3, hr * 0.85), back.lightened(0.04), Vector3(0, 0, -14 * sx), 10)
		# çekik yeşil göz (kaşın altında, yana-öne bakar)
		var ep = hc + Vector3(hr * 0.88 * sx, hr * 0.34, -hr * 0.55)
		mb.add("sphere", ep, Vector3(hr * 0.7, hr * 0.32, hr * 0.5), Color(0.06, 0.05, 0.05), Vector3(0, -25 * sx, -10 * sx), 10)
		mb.add("sphere", ep + Vector3(hr * 0.07 * sx, 0, -hr * 0.03), Vector3(hr * 0.56, hr * 0.24, hr * 0.42), Color(0.4, 0.85, 0.65), Vector3(0, -25 * sx, -10 * sx), 10)
		mb.add("sphere", ep + Vector3(hr * 0.12 * sx, 0, -hr * 0.06), Vector3(hr * 0.08, hr * 0.22, hr * 0.36), Color(0.02, 0.02, 0.02), Vector3.ZERO, 6)
		# boynuzlar: alında büyük ve yanda küçük, geriye-yukarı savrulur, halka çizgili
		for h in 2:
			var h0 = hc + Vector3(hr * (0.45 + h * 0.5) * sx, hr * (0.6 - h * 0.15), hr * (0.1 + h * 0.3))
			var L2 = hr * (3.4 - h * 1.4)
			var hd = Vector3((0.3 + h * 0.55) * sx, 0.32 - h * 0.2, 1.0).normalized()   # geriye savrulur
			Loft.tube(mb, [h0, h0 + hd * L2 * 0.5 + Vector3(0, L2 * 0.08, 0), h0 + hd * L2], [hr * (0.26 - h * 0.08), hr * (0.17 - h * 0.05), hr * 0.02], [back.lightened(0.1), back.lightened(0.15), back.lightened(0.2)], 10, 3, true, false)
			for k in 3:
				mb.add_xf("torus", Transform3D(Basis.looking_at(hd, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3.ONE * hr * (0.42 - k * 0.1 - h * 0.12)), h0 + hd * L2 * (0.15 + k * 0.2)), dark.lerp(back, 0.4), 10)
	# ---- açık ağız: alt çene aşağı açılı, kızıl-kahve iç, üst ve alt sivri dişler, iki büyük zehir dişi
	var jc = hc + Vector3(0, -hr * 0.42, -hr * 1.3)
	mb.add_xf("sphere", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(16)) * Basis.from_scale(Vector3(hr * 1.7, hr * 0.32, hr * 3.6)), jc + Vector3(0, -hr * 0.2, 0)), belly, 12)   # alt çene
	mb.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(hr * 1.5, hr * 0.3, hr * 3.3)), jc + Vector3(0, hr * 0.06, -hr * 0.05)), mouth_c, 12)   # ağız içi
	for k in 9:
		var u = k / 8.0
		for sx in [-1.0, 1.0]:
			var tp = jc + Vector3(lerpf(0.75, 0.25, u) * hr * sx, hr * 0.2, lerpf(1.2, -1.7, u) * hr)
			var big = k == 7
			mb.add("cone", tp, Vector3(hr * (0.1 if not big else 0.16), hr * (0.22 if not big else 0.55), hr * 0.1), tooth, Vector3(180, 0, 0), 5)
			mb.add("cone", tp + Vector3(0, -hr * 0.3, hr * 0.15), Vector3(hr * 0.08, hr * 0.18, hr * 0.08), tooth, Vector3.ZERO, 5)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/beast.gdshader")
	mat.set_shader_parameter("surface", 1)
	mat.set_shader_parameter("stroke", 0.3)
	mat.set_shader_parameter("shadow_tint", Color(0.3, 0.24, 0.34))
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(mat)
	mi.material_override = mat
	holder.add_child(mi)
	var size = Vector3(r * 2.6, raise + hr, L)
	var mouth = hc + Vector3(0, -hr * 0.3, -hr * 3.0)
	var an = SnakeAnim.new()
	an.name = "SnakeAnim"
	holder.add_child(an)
	an.setup(2, holder, [mat], size, Vector3.ZERO, mouth, hr * 1.6)
	return {"node": holder, "mouth": mouth, "anim": an}


## Çöreklenmiş hayran modeli (Manda benzeri): boyun pivotu ve ağız ucu köşe noktalarından bulunur, SnakeAnim (mod 1) bağlanır
static func _coil_anim(out: Dictionary, node: Node3D, sz: Vector3) -> void:
	var H = sz.y
	var mats = []
	var tip = Vector3(0, H, 0)
	var best = INF
	var neck = Vector3.ZERO
	var nn = 0
	var inv = node.global_transform.affine_inverse() if node.is_inside_tree() else Transform3D.IDENTITY
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for si in mi.mesh.get_surface_count():
			var m = mi.get_surface_override_material(si)
			if m is ShaderMaterial and not m in mats:
				mats.append(m)
		# düğüm henüz ağaçta değil: yerel zinciri elle çarp
		var xf = Transform3D.IDENTITY
		var c: Node = mi
		var chain = []
		while c != node and c != null:
			chain.push_front(c)
			c = c.get_parent()
		for k in chain:
			xf = xf * (k as Node3D).transform
		var arr = mi.mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var step = maxi(1, vs.size() / 4000)
		for i in range(0, vs.size(), step):
			var v = xf * vs[i]
			if v.y > H * 0.82 and v.z < best:
				best = v.z
				tip = v
			if v.y > H * 0.38 and v.y < H * 0.5:
				neck += v
				nn += 1
	if nn > 0:
		neck /= nn
	neck.y = H * 0.42
	var an = SnakeAnim.new()
	an.name = "SnakeAnim"
	node.add_child(an)
	an.setup(1, node, mats, sz, neck, tip, H * 0.12)
	out["anim"] = "shader"
	out["mouth"] = tip



## Sümüklüböcekler (REFERANS: Katsuyu): beyaz gövdenin ön yarısı sütun gibi dikilir, arka yarısı yerde sivri kuyruğa iner;
## iki yanda başın tepesinden kuyruğa tırtıklı kenarlı turkuaz şerit, kalkık gövdenin önü açık nane, ince yatay kırışıklar,
## tabanda koyu kenar; kubbe başta iki ince göz sapı (yuvarlak gri gözler), kapalı kıvrık gözler ve küçük "w" ağız.
## Şifa parçacıkları aynı desenin yerde sürünen minik damla hali.
static func _slug(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "crawl"
	var raise = {"slug_frag": 0.0, "slug_acid": 0.6, "slug_queen": 1.0}[model]
	if model == "slug_frag":
		length = h * 2.6
	else:
		length = h * (1.7 if raise >= 1.0 else 2.2)   # referans: kuyruk boyu ≈ yüksekliğin 1.7 katı
	var white = Color(0.94, 0.96, 0.95)
	var mint = Color(0.84, 0.92, 0.89)
	var teal = Color(0.18, 0.52, 0.5) if model != "slug_acid" else Color(0.35, 0.62, 0.22)
	var rim = Color(0.72, 0.78, 0.76)
	var L = length
	var W = h * (0.31 if raise > 0.0 else 0.55)        # kalkık gövdenin yarı eni (referans: eni boyunun ~yarısı)
	var gh = W * (0.85 if raise > 0.0 else 0.75)       # yerdeki gövdenin yüksekliği
	var top = h if raise > 0.0 else gh * 1.6
	var pts = [Vector3(0, gh * 0.2, L * 0.5), Vector3(0, gh * 0.5, L * 0.3), Vector3(0, gh * 0.68, L * 0.06)]
	var rads = [Vector2(W * 0.12, gh * 0.12), Vector2(W * 0.62, gh * 0.5), Vector2(W * 0.86, gh * 0.72)]
	if raise > 0.0:
		pts += [Vector3(0, gh * 0.8 + top * 0.08, -L * 0.13), Vector3(0, lerpf(gh, top, 0.45), -L * 0.2), Vector3(0, lerpf(gh, top, 0.75), -L * 0.215), Vector3(0, top - W * 0.85, -L * 0.21)]
		# dik gövdenin ön-arka derinliği kubbeden az: kubbe (ve yüz) önde kalsın
		rads += [Vector2(W * 0.95, W * 0.78), Vector2(W, W * 0.74), Vector2(W * 0.96, W * 0.7), Vector2(W * 0.86, W * 0.66)]
	else:
		pts += [Vector3(0, gh * 0.72, -L * 0.2), Vector3(0, gh * 0.66, -L * 0.36)]
		rads += [Vector2(W * 0.9, gh * 0.75), Vector2(W * 0.7, gh * 0.62)]
	var col_fn = func(tt: float, a: float, d: Vector3) -> Color:
		if d.y < -0.55:
			return rim
		# ince yatay kırışıklar
		var wr = fposmod(tt * 60.0, 1.0) < 0.05
		var base = white
		if raise > 0.0 and d.z < -0.5 and tt > 0.55:
			base = mint   # kalkık gövdenin önü
		# yan şeritler: tırtıklı kenarlı bant (kalkık kısımda arka-yanlarda)
		# kalın, kesintisiz şerit: yanların üst yarısında (kalkık kısımda yan-arka), kenarı ince tırtıklı
		var jag = sin(tt * 220.0 + a * 3.0) * 0.025
		var side = absf(d.x)
		var up = d.y if raise <= 0.0 or tt < 0.45 else d.z   # dik kısımda sırt arkaya (+Z) bakar
		var band = side > 0.42 + jag and side < 0.86 + jag and up > -0.25
		if band and d.y > -0.4 and tt > 0.04:
			base = teal
		# başın tepesinde turkuaz yama (iki şerit burada birleşir)
		if tt > 0.86 and d.y > 0.55 and d.z > -0.3:
			base = teal
		return base.darkened(0.1) if wr else base
	var body = Node3D.new()
	out["root"].add_child(body)
	var b = MB.new()
	Loft.tube(b, pts, rads, white, 18, 6, false, true, col_fn)
	# taban kenarı: gövdenin altında yere yayılan koyu, hafif geniş şerit
	var fpts = [Vector3(0, 0.02 * h, L * 0.5), Vector3(0, 0.04 * h, L * 0.25), Vector3(0, 0.05 * h, 0.0), Vector3(0, 0.05 * h, -L * 0.2), Vector3(0, 0.04 * h, -L * (0.3 if raise > 0.0 else 0.38))]
	Loft.tube(b, fpts, [Vector2(W * 0.15, gh * 0.06), Vector2(W * 0.75, gh * 0.12), Vector2(W * 1.0, gh * 0.14), Vector2(W * 1.08, gh * 0.15), Vector2(W * 0.9, gh * 0.12)], rim, 14, 4, true, true)
	var hc: Vector3 = pts[pts.size() - 1]
	var hr = rads[rads.size() - 1].x
	if raise > 0.0:
		# kubbe baş: gövdenin tepesini yuvarlar (düz kesik değil)
		b.add("sphere", hc + Vector3(0, hr * 0.1, 0), Vector3(hr * 2.0, hr * 2.3, hr * 1.9), white, Vector3.ZERO, 22)
		b.add("sphere", hc + Vector3(0, hr * 0.9, hr * 0.2), Vector3(hr * 1.1, hr * 0.55, hr * 1.1), teal, Vector3.ZERO, 14)   # tepe yaması
	_mesh(body, b)
	out["segments"].append(body)
	# baş: kubbenin önünde yüz, tepesinde göz sapları
	var head = _pivot(out["root"], hc)
	var eb = MB.new()
	var ink = Color(0.12, 0.14, 0.14)
	# yüz kubbenin gövdeden taşan üst yarısında, yüzeyin hemen önünde (gövde tüpünün içine gömülmesin)
	var fy = -hr * 0.05 if raise > 0.0 else hr * 0.1
	var fz = -(hr * 0.95 * sqrt(maxf(0.0, 1.0 - pow(fy / (hr * 0.95), 2.0))) + hr * 0.03) if raise > 0.0 else -hr * 0.97
	for sx in [-1.0, 1.0]:
		# kapalı kıvrık göz: aşağı kıvrık yay + uçta küçük kıvrım
		for k in 7:
			var u = (k - 3) / 3.0
			eb.add("box", Vector3(sx * hr * (0.36 + u * 0.15), fy + hr * (0.1 - u * u * 0.08), fz + (absf(u) * 0.08 + 0.02) * hr), Vector3(hr * 0.09, hr * 0.035, hr * 0.04), ink, Vector3(0, 0, -u * 35.0 * sx))
		eb.add("torus", Vector3(sx * hr * 0.56, fy - hr * 0.02, fz + hr * 0.14), Vector3(hr * 0.12, hr * 0.12, hr * 0.12), ink, Vector3(80, 0, 0), 10)
		# göz sapı: tepeden dışa-yukarı ince sap, ucunda gri göz ve koyu halka
		var s0 = Vector3(sx * hr * 0.42, hr * 0.95, hr * 0.05)
		var sd = Vector3(sx * 0.45, 1.0, -0.15).normalized()
		var sl = hr * (1.2 if raise > 0.0 else 0.8)
		var mid = s0 + sd * sl * 0.5
		eb.add_xf("cyl", Transform3D(Basis(Quaternion(Vector3.UP, sd)) * Basis.from_scale(Vector3(hr * 0.14, sl, hr * 0.14)), mid), white, 8)
		var ep = s0 + sd * sl
		eb.add("sphere", ep, Vector3.ONE * hr * 0.4, Color(0.88, 0.9, 0.9), Vector3.ZERO, 12)
		eb.add("sphere", ep + Vector3(0, 0, -hr * 0.11), Vector3(hr * 0.16, hr * 0.16, hr * 0.1), Color(0.35, 0.4, 0.42), Vector3.ZERO, 8)
	# küçük "w" ağız
	for k in 4:
		var x = (k - 1.5) * hr * 0.13
		eb.add("box", Vector3(x, fy - hr * 0.02 + (0.03 if k % 2 else -0.03) * hr, fz - hr * 0.02), Vector3(hr * 0.15, hr * 0.045, hr * 0.04), ink, Vector3(0, 0, 40 if k % 2 else -40))
	_mesh(head, eb)
	out["head"] = head
	out["mouth"] = hc + Vector3(0, fy - hr * 0.12, fz)



## Şahinler (REFERANS: dev çağrı şahini): kahverengi gövde, açık renkli baş ve beyaz boğaz, gözden aşağı inen koyu "maske" çizgisi,
## sarı kancalı gaga ve göz halkası; çok geniş kanatlar — üstünde koyu kahve bantlar, uçta parmak gibi ayrılan uzun tüyler;
## sarı pullu ayaklar ve siyah pençeler, yelpaze kuyruk. Kanatlar gerçek profil (slab) olarak kurulur.
static func _hawk(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "fly"
	var brown = {"hawk_small": Color(0.6, 0.45, 0.33), "hawk_mount": Color(0.55, 0.4, 0.3), "hawk_giant": Color(0.5, 0.36, 0.27)}[model]
	var dark = Color(0.24, 0.16, 0.11)
	var light = Color(0.86, 0.76, 0.64)
	var white = Color(0.95, 0.93, 0.88)
	var yellow = Color(0.95, 0.78, 0.25)
	var b = MB.new()
	# gövde: kuyruk kökünden boyuna damla biçimi; altı açık ve çizgili
	var body_fn = func(tt: float, a: float, d: Vector3) -> Color:
		if d.y < -0.35:
			return light if fposmod(tt * 14.0 + a * 0.3, 1.0) > 0.18 else brown.darkened(0.1)   # göğüs/karın çizgileri
		return brown
	Loft.tube(b, [Vector3(0, h * 0.44, h * 0.62), Vector3(0, h * 0.48, h * 0.25), Vector3(0, h * 0.52, -h * 0.15), Vector3(0, h * 0.62, -h * 0.48), Vector3(0, h * 0.76, -h * 0.7)],
		[Vector2(0.09, 0.07) * h, Vector2(0.22, 0.2) * h, Vector2(0.26, 0.25) * h, Vector2(0.2, 0.2) * h, Vector2(0.14, 0.14) * h], brown, 20, 6, true, true, body_fn)
	# omuz kütlesi: kanat köklerini gövdeye bağlar
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.16 * sx, h * 0.63, -h * 0.22), Vector3(0.22, 0.17, 0.4) * h, brown, Vector3.ZERO, 12)
	# baş: açık renkli, beyaz boğaz, koyu maske çizgileri
	var hc = Vector3(0, h * 0.8, -h * 0.76)
	b.add("sphere", hc, Vector3(0.24, 0.22, 0.3) * h, light, Vector3.ZERO, 14)
	b.add("sphere", hc + Vector3(0, h * 0.05, h * 0.03), Vector3(0.24, 0.13, 0.3) * h, brown.lightened(0.1), Vector3.ZERO, 12)   # yassı tepe
	b.add("sphere", hc + Vector3(0, -h * 0.075, 0.0), Vector3(0.13, 0.08, 0.17) * h, white, Vector3.ZERO, 12)   # boğaz
	for sx in [-1.0, 1.0]:
		var ep = hc + Vector3(h * 0.105 * sx, h * 0.03, -h * 0.07)
		b.add("sphere", ep, Vector3(0.07, 0.07, 0.05) * h, yellow, Vector3.ZERO, 10)   # göz halkası
		b.add("sphere", ep + Vector3(h * 0.012 * sx, 0, -h * 0.012), Vector3(0.045, 0.045, 0.035) * h, Color(0.08, 0.06, 0.05), Vector3.ZERO, 8)
		b.add("box", ep + Vector3(h * 0.005 * sx, h * 0.035, 0.0), Vector3(h * 0.09, h * 0.02, h * 0.06), dark, Vector3(0, 0, -12 * sx))   # kaş
		# gözden aşağı inen koyu maske çizgisi (bıyık)
		Loft.tube(b, [ep + Vector3(h * 0.01 * sx, -h * 0.03, h * 0.0), ep + Vector3(h * 0.02 * sx, -h * 0.09, h * 0.02), ep + Vector3(h * 0.015 * sx, -h * 0.14, h * 0.05)],
			[h * 0.022, h * 0.02, h * 0.008], dark, 6, 2)
	# kancalı gaga: sarı ağız derisi + aşağı kıvrılan koyu uçlu gaga
	b.add("sphere", hc + Vector3(0, -h * 0.005, -h * 0.13), Vector3(0.1, 0.07, 0.07) * h, yellow, Vector3.ZERO, 8)
	Loft.tube(b, [hc + Vector3(0, 0.005 * h, -h * 0.14), hc + Vector3(0, -h * 0.005, -h * 0.22), hc + Vector3(0, -h * 0.06, -h * 0.27), hc + Vector3(0, -h * 0.11, -h * 0.25)],
		[Vector2(0.06, 0.055) * h, Vector2(0.045, 0.042) * h, Vector2(0.025, 0.025) * h, Vector2(0.005, 0.005) * h], [yellow, yellow, Color(0.25, 0.22, 0.2), Color(0.15, 0.13, 0.12)], 8, 3, true, true)
	# kuyruk yelpazesi: yatay açılan yedi tüy (kanatla aynı yatay profil düzlemi)
	var hor = Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1))
	for k in 7:
		var u = (k - 3) / 3.0
		var tb = PackedVector2Array([Vector2(-h * 0.05, 0.0), Vector2(h * 0.05, 0.0), Vector2(h * 0.075, h * 0.42), Vector2(0.0, h * 0.5), Vector2(-h * 0.075, h * 0.42)])
		b.add_slab(tb, h * 0.02, brown.darkened(0.12) if k % 2 else brown, Transform3D(Basis(Vector3.UP, -u * 0.38) * hor, Vector3(0, h * 0.43, h * 0.55)))
	if model != "hawk_small":
		b.add("box", Vector3(0, h * 0.82, h * 0.0), Vector3(h * 0.34, h * 0.04, h * 0.4), Color(0.6, 0.15, 0.15))   # eyer
	_mesh(out["root"], b)
	# ayaklar (ayrı pivot, animasyonlu): tüylü baldır, sarı pullu incik, yelpaze gibi AÇIK dört parmak (3 ön + 1 arka), kıvrık siyah pençeler
	for sx in [-1.0, 1.0]:
		var lp = _pivot(out["root"], Vector3(h * 0.1 * sx, h * 0.38, h * 0.02))
		var lb = MB.new()
		Loft.tube(lb, [Vector3.ZERO, Vector3(h * 0.02 * sx, -h * 0.08, -h * 0.02)], [h * 0.09, h * 0.07], brown.lightened(0.05), 10, 2)   # tüylü baldır
		var ank = Vector3(h * 0.03 * sx, -h * 0.26, -h * 0.05)
		Loft.tube(lb, [Vector3(h * 0.02 * sx, -h * 0.08, -h * 0.02), ank], [h * 0.04, h * 0.032], yellow, 8, 2)   # incik
		for k in 6:   # pul halkaları
			lb.add("torus", Vector3(h * 0.02 * sx, -h * 0.08, -h * 0.02).lerp(ank, k / 6.0), Vector3(0.085, 0.085, 0.085) * h, yellow.darkened(0.15), Vector3(0, 0, 0), 8)
		lb.add("sphere", ank, Vector3(0.07, 0.05, 0.07) * h, yellow, Vector3.ZERO, 8)
		for t in 4:
			var back = t == 3
			var aa = deg_to_rad(-38.0 + t * 38.0) if not back else PI
			var d0 = Vector3(sin(aa) * 0.9, -0.15, -cos(aa)).normalized()
			var p1 = ank + d0 * h * (0.12 if not back else 0.08)
			var p2 = p1 + (d0 + Vector3(0, -0.5, 0)).normalized() * h * (0.08 if not back else 0.06)
			Loft.tube(lb, [ank, p1, p2], [h * 0.03, h * 0.026, h * 0.02], yellow, 8, 2)
			BeastRig.claw(lb, p2, (d0 + Vector3(0, -1.2, 0)).normalized(), h * 0.09, h * 0.02, Color(0.08, 0.07, 0.07))
		_mesh(lp, lb)
		out["legs"].append(lp)
	# kanatlar: omuzdan profil, uçta parmak tüyleri, üstte koyu bantlar
	var W = h * 2.1   # tek kanat açıklığı (referansta açık kanatlar gövdenin kat kat genişi)
	for sx in [-1.0, 1.0]:
		var pv = _pivot(out["root"], Vector3(h * 0.14 * sx, h * 0.64, -h * 0.3))   # kök omuz kütlesinin içinde
		var wb = MB.new()
		# profil (açıklık s, kiriş c): kanat düzlemi yatay; yerel X = kalınlık (dünya Y), yerel Y = açıklık (±X), yerel Z = kiriş (+Z geri)
		# + yukarı V açısı (kanatlar önden bakınca görünsün, süzülme pozu)
		var xf = Transform3D(Basis(Vector3(0, 0, 1), sx * deg_to_rad(18.0)) * Basis(Vector3(0, -sx, 0), Vector3(sx, 0, 0), Vector3(0, 0, 1)), Vector3.ZERO)
		# geniş kanat: gövde yanında kiriş ≈ açıklığın yarısı, uca doğru daralır
		# kökte kiriş gövde boyu kadar (omuzdan kalçaya), uçta daralır
		var wing = [[0.0, -h * 0.02], [W * 0.3, -h * 0.2], [W * 0.62, -h * 0.18], [W * 0.8, -h * 0.05], [W * 0.82, h * 0.25], [W * 0.62, h * 0.62], [W * 0.32, h * 0.8], [W * 0.05, h * 0.62], [0.0, h * 0.5]]
		var wp = PackedVector2Array()
		for p in wing:
			wp.append(Vector2(p[0], p[1]))
		wb.add_slab(wp, h * 0.05, brown, xf, func(p: Vector2) -> float: return h * (0.05 if p.y < h * 0.05 else 0.025), brown.darkened(0.15))
		# parmak tüyleri: uçta beş ayrık uzun tüy
		for k in 5:
			var base = Vector2(W * (0.74 + k * 0.012), h * (-0.02 + k * 0.08))
			var ang = deg_to_rad(-6.0 + k * 13.0)
			var dv = Vector2(cos(ang), sin(ang))
			var nv = Vector2(-dv.y, dv.x)
			var fl = h * (0.85 - k * 0.07)
			var fw = h * 0.08
			var fp = PackedVector2Array([base - nv * fw, base + dv * fl * 0.85 - nv * fw * 0.7, base + dv * fl, base + dv * fl * 0.85 + nv * fw * 0.7, base + nv * fw])
			wb.add_slab(fp, h * 0.02, brown.darkened(0.25) if k % 2 == 0 else brown.darkened(0.15), xf)
		# arka kenar tüy uçları (tırtıklı)
		for k in 8:
			var s0 = W * (0.02 + k * 0.095)
			var c0 = lerpf(h * 0.78, h * 0.45, k / 7.0)
			wb.add_slab(PackedVector2Array([Vector2(s0, c0), Vector2(s0 + W * 0.09, c0), Vector2(s0 + W * 0.05, c0 + h * 0.12)]), h * 0.02, brown.darkened(0.08), xf)
		# üstte koyu kahve bantlar (kanadın ön-orta bölgesi boyunca ve dirsekte)
		var bar = PackedVector2Array([Vector2(W * 0.1, h * 0.0), Vector2(W * 0.64, -h * 0.06), Vector2(W * 0.68, h * 0.04), Vector2(W * 0.12, h * 0.14)])
		wb.add_slab(bar, h * 0.012, dark, Transform3D(xf.basis, xf.basis * Vector3(-h * 0.03 * sx, 0, 0)))
		var bar2 = PackedVector2Array([Vector2(W * 0.3, h * 0.36), Vector2(W * 0.58, h * 0.3), Vector2(W * 0.52, h * 0.44), Vector2(W * 0.28, h * 0.5)])
		wb.add_slab(bar2, h * 0.012, dark, Transform3D(xf.basis, xf.basis * Vector3(-h * 0.03 * sx, 0, 0)))
		_mesh(pv, wb)
		out["wings"].append(pv)
	out["mouth"] = hc + Vector3(0, -h * 0.03, -h * 0.22)


# ------------------------------------------------------------------ ortak dört ayaklı (köpek, kurt, kedi, gelincik): pürüzsüz Loft anatomisi
## p: {"len": gövde uzunluğu oranı, "leg": bacak boyu oranı, "snout": burun uzunluğu, "ear": kulak boyu, "heads": [x ofsetleri], "eye": göz rengi,
##     "tail": "bushy"|"thin"|"flame2", "belly": karın rengi, "mark": koyu işaret rengi}
static func _quad(out: Dictionary, h: float, c: Color, p: Dictionary) -> MB:
	var belly: Color = p.get("belly", c.lightened(0.25))
	var dk: Color = p.get("mark", c.darkened(0.45))
	var L = h * float(p.get("len", 1.2))
	var leg = h * float(p.get("leg", 0.5))
	var by = leg + h * 0.12
	var fur = func(_t: float, a: float, _d: Vector3) -> Color:
		return c.lerp(belly, smoothstep(-0.2, -0.85, sin(a)))
	var b = MB.new()
	# göğüs derin, bel ince, kalça yuvarlak
	Loft.tube(b, [Vector3(0, by + h * 0.04, L * 0.48), Vector3(0, by + h * 0.06, L * 0.18), Vector3(0, by + h * 0.04, -L * 0.12), Vector3(0, by + h * 0.12, -L * 0.42)],
		[Vector2(0.2, 0.2) * h, Vector2(0.17, 0.17) * h, Vector2(0.2, 0.24) * h, Vector2(0.22, 0.27) * h], c, 18, 4, true, true, fur)
	for hx in p.get("heads", [0.0]):
		var neck0 = Vector3(hx * h, by + h * 0.2, -L * 0.42)
		var hp = Vector3(hx * h * 1.2, by + h * 0.48, -L * 0.62)
		Loft.tube(b, [neck0, neck0.lerp(hp, 0.5) + Vector3(0, h * 0.04, 0), hp], [h * 0.15, h * 0.13, h * 0.12], c, 14, 3, true, true, fur)
		# kafa + burun (tek profil)
		var sn = float(p.get("snout", 0.3)) * h
		Loft.tube(b, [hp + Vector3(0, h * 0.02, h * 0.1), hp + Vector3(0, h * 0.03, -h * 0.06), hp + Vector3(0, -h * 0.03, -h * 0.06 - sn * 0.6), hp + Vector3(0, -h * 0.05, -h * 0.06 - sn)],
			[Vector2(0.15, 0.14) * h, Vector2(0.16, 0.15) * h, Vector2(0.09, 0.08) * h, Vector2(0.05, 0.045) * h], c, 16, 3, true, true, fur)
		b.add("sphere", hp + Vector3(0, -h * 0.03, -h * 0.07 - sn), Vector3(0.07, 0.05, 0.05) * h, Color(0.06, 0.05, 0.05), Vector3.ZERO, 8)  # burun ucu
		for sx in [-1.0, 1.0]:
			var ep = hp + Vector3(0.075 * sx * h, h * 0.05, -h * 0.13)
			b.add("sphere", ep, Vector3(0.07, 0.045, 0.04) * h, p.get("eye", Color(0.95, 0.75, 0.2)), Vector3(0, 0, -15 * sx), 8)
			b.add("sphere", ep + Vector3(0, 0, -h * 0.018), Vector3(0.018, 0.04, 0.02) * h, Color(0.05, 0.03, 0.03), Vector3.ZERO, 6)
			BeastModels._brow(b, ep, sx, h * 0.09, dk)
			# sivri kulak
			var e0 = hp + Vector3(0.09 * sx * h, h * 0.11, h * 0.02)
			Loft.tube(b, [e0, e0 + Vector3(0.03 * sx, float(p.get("ear", 0.16)) * 0.6, 0.02) * h, e0 + Vector3(0.05 * sx, float(p.get("ear", 0.16)), 0.04) * h], [Vector2(0.06, 0.03) * h, Vector2(0.04, 0.02) * h, Vector2(0.004, 0.004) * h], [c, c, dk], 10, 2, true, false)
			# yanak tüyü
			BeastRig.claw(b, hp + Vector3(0.12 * sx * h, -h * 0.04, h * 0.0), Vector3(sx, -0.3, 0.6), h * 0.1, h * 0.03, c)
		# dişler
		for sx in [-1.0, 1.0]:
			BeastRig.claw(b, hp + Vector3(0.035 * sx * h, -h * 0.07, -h * 0.06 - sn * 0.8), Vector3(0, -1, 0), h * 0.05, h * 0.012, Color(0.97, 0.95, 0.9))
	# sırt tüyü (cel)
	for i in 5:
		BeastRig.claw(b, Vector3(0, by + h * 0.24, -L * 0.3 + i * L * 0.12), Vector3(0, 1, 0.8), h * 0.12, h * 0.04, c.darkened(0.08))
	# bacaklar: üst bacak + incik + pati (pivot kalçada/omuzda; yürüyüşte döner)
	for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var front = q.z < 0
		var pv = _pivot(out["root"], Vector3(q.x * h * 0.13, by, q.z * L * (0.32 if front else 0.36)))
		var lb = MB.new()
		var knee = Vector3(q.x * h * 0.02, -leg * 0.5, (h * 0.05 if front else -h * 0.1))
		var paw = Vector3(q.x * h * 0.01, -by + h * 0.04, -h * 0.03)
		Loft.tube(lb, [Vector3.ZERO, knee, paw], [Vector2(0.09, 0.11) * h, Vector2(0.055, 0.06) * h, Vector2(0.045, 0.045) * h], c.darkened(0.05), 12, 3)
		lb.add("sphere", paw + Vector3(0, -h * 0.01, -h * 0.04), Vector3(0.11, 0.06, 0.14) * h, c.darkened(0.1), Vector3.ZERO, 10)
		for f in 3:
			BeastRig.claw(lb, paw + Vector3((f - 1) * h * 0.03, -h * 0.02, -h * 0.1), Vector3(0, -0.4, -1), h * 0.05, h * 0.012, Color(0.12, 0.1, 0.1))
		_mesh(pv, lb)
		out["legs"].append(pv)
	# kuyruk
	var tail = _pivot(out["root"], Vector3(0, by + h * 0.12, L * 0.5))
	var tb = MB.new()
	match String(p.get("tail", "bushy")):
		"bushy":
			Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.15, h * 0.25), Vector3(0, h * 0.35, h * 0.45), Vector3(0, h * 0.5, h * 0.55)], [h * 0.06, h * 0.11, h * 0.1, h * 0.02], [c, c, belly, belly], 12, 3, true, false)
		"thin":
			Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.2, h * 0.3), Vector3(0, h * 0.55, h * 0.4), Vector3(0, h * 0.75, h * 0.3)], [h * 0.05, h * 0.04, h * 0.035, h * 0.01], c, 10, 3, true, false)
		"flame2":
			for sx in [-1.0, 1.0]:
				Loft.tube(tb, [Vector3.ZERO, Vector3(sx * h * 0.12, h * 0.3, h * 0.25), Vector3(sx * h * 0.2, h * 0.7, h * 0.3), Vector3(sx * h * 0.15, h * 1.0, h * 0.2)], [h * 0.06, h * 0.07, h * 0.06, h * 0.01], [c, c, Color(0.35, 0.6, 1.0), Color(0.6, 0.85, 1.0)], 10, 3, true, false)
	_mesh(tail, tb)
	out["tail"] = tail
	out["mouth"] = Vector3(0, by + h * 0.45, -L * 0.62 - float(p.get("snout", 0.3)) * h)
	return b


## Ninkenler (REFERANS): küçük iz sürücü — tıknaz pug: kısa kalın bacaklar, iri yuvarlak baş, koyu kahve büyük burun-ağız, sarkık koyu kulaklar,
## ağır kapaklı uykulu gözler, alında kırışıklar; mavi kapüşonlu alın bandı (metal plaka), mavi yelek ve boyunda bağlı mavi fular, sargılı ön pati.
## Sürü — farklı renk ve aksesuarlı köpekler (bant, gözlük, sargı). Dev kurt — beyaz gür yeleli, iki başlı, kırmızı gözlü, açık dişli ağızlar,
## sinmiş saldırı duruşu, kıvrık uzun kuyruk, siyah pençeler.
static func _dog_proc(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "walk"
	match model:
		"dog_small":
			_pug(out, h, Color(0.8, 0.52, 0.3), true)
		"dog_pack":
			var cols = [Color(0.6, 0.6, 0.62), Color(0.45, 0.33, 0.22), Color(0.82, 0.8, 0.76), Color(0.3, 0.28, 0.3), Color(0.7, 0.55, 0.38)]
			var c: Color = cols.pick_random()
			var b = _quad(out, h, c, {"len": 1.1, "leg": 0.5, "snout": 0.26, "ear": 0.15, "eye": Color(0.12, 0.1, 0.08), "tail": "bushy", "belly": c.lightened(0.25)})
			var by = h * 0.62
			match randi() % 3:
				0:   # alın bandı boynunda
					b.add("cyl", Vector3(0, by + h * 0.24, -h * 0.5), Vector3(0.3, 0.06, 0.3) * h, Color(0.2, 0.3, 0.5), Vector3(65, 0, 0), 12)
					b.add("box", Vector3(0, by + h * 0.24, -h * 0.62), Vector3(0.12, 0.06, 0.02) * h, Color(0.8, 0.82, 0.86), Vector3(-25, 0, 0))
				1:   # koyu gözlük
					for sx in [-1.0, 1.0]:
						b.add("box", Vector3(h * 0.07 * sx, by + h * 0.52, -h * 0.82), Vector3(0.09, 0.04, 0.02) * h, Color(0.05, 0.05, 0.06))
				2:   # gövde sargısı
					for k in 4:
						b.add("torus", Vector3(0, by + h * 0.1, -h * 0.15 + k * h * 0.08), Vector3(0.44, 0.44, 0.44) * h, Color(0.94, 0.93, 0.9), Vector3(90, 0, 0), 12)
			_mesh(out["root"], b)
		"wolf_giant":
			_wolf2(out, h)
		"wolf3_giant":
			_wolf2(out, h, [-0.32, 0.0, 0.32])
		"dog_giant":
			_war_hound(out, h)


static func _pug(out: Dictionary, h: float, c: Color, gear: bool) -> void:
	var dark = Color(0.32, 0.2, 0.14)
	var blue = Color(0.16, 0.26, 0.55)
	var b = MB.new()
	# tıknaz gövde (oturur gibi), kısa kalın bacaklar
	Loft.tube(b, [Vector3(0, h * 0.35, h * 0.32), Vector3(0, h * 0.45, h * 0.05), Vector3(0, h * 0.55, -h * 0.2)], [Vector2(0.3, 0.28) * h, Vector2(0.34, 0.33) * h, Vector2(0.3, 0.3) * h], c, 18, 4, true, true,
		func(_t: float, _a: float, d: Vector3) -> Color: return c.lightened(0.15) if d.y < -0.4 else c)
	# baş: iri yuvarlak, gövdeye gömük boyun
	var hc = Vector3(0, h * 0.9, -h * 0.32)
	b.add("sphere", hc, Vector3(0.62, 0.58, 0.56) * h, c, Vector3.ZERO, 16)
	b.add("sphere", hc + Vector3(0, -h * 0.1, -h * 0.24), Vector3(0.4, 0.3, 0.2) * h, dark, Vector3.ZERO, 14)   # koyu ağız-burun maskesi
	b.add("sphere", hc + Vector3(0, -h * 0.02, -h * 0.33), Vector3(0.14, 0.09, 0.08) * h, Color(0.08, 0.06, 0.05), Vector3.ZERO, 10)   # burun
	b.add("box", hc + Vector3(0, -h * 0.17, -h * 0.33), Vector3(h * 0.2, h * 0.015, h * 0.02), Color(0.1, 0.06, 0.05), Vector3(0, 0, 0))   # ağız çizgisi
	for sx in [-1.0, 1.0]:
		var ep = hc + Vector3(h * 0.13 * sx, h * 0.08, -h * 0.25)
		b.add("sphere", ep, Vector3(0.12, 0.08, 0.06) * h, Color(0.96, 0.95, 0.92), Vector3.ZERO, 10)   # göz akı
		b.add("sphere", ep + Vector3(0, -h * 0.01, -h * 0.02), Vector3(0.05, 0.05, 0.03) * h, Color(0.08, 0.06, 0.05), Vector3.ZERO, 8)
		b.add("sphere", ep + Vector3(0, h * 0.025, -h * 0.005), Vector3(0.13, 0.05, 0.065) * h, c.darkened(0.15), Vector3(0, 0, -6 * sx), 10)   # ağır göz kapağı
		# sarkık koyu kulak
		Loft.tube(b, [hc + Vector3(h * 0.24 * sx, h * 0.18, -h * 0.02), hc + Vector3(h * 0.33 * sx, h * 0.08, -h * 0.04), hc + Vector3(h * 0.34 * sx, -h * 0.08, -h * 0.06)], [Vector2(0.05, 0.1) * h, Vector2(0.05, 0.12) * h, Vector2(0.03, 0.08) * h], dark, 8, 3)
	for k in 3:   # alın kırışıkları
		b.add("box", hc + Vector3(0, h * (0.18 + k * 0.035), -h * 0.24 + k * h * 0.01), Vector3(h * (0.16 - k * 0.03), h * 0.012, h * 0.01), c.darkened(0.3))
	if gear:
		# mavi kapüşonlu alın bandı + plaka
		Loft.tube(b, [hc + Vector3(-0.001, h * 0.14, 0), hc + Vector3(0.001, h * 0.14, 0)], [Vector2(0.32, 0.3) * h, Vector2(0.32, 0.3) * h], blue, 18, 1, false, false)
		b.add("box", hc + Vector3(0, h * 0.2, -h * 0.29), Vector3(0.22, 0.07, 0.02) * h, Color(0.75, 0.77, 0.8), Vector3(-15, 0, 0))
		b.add("sphere", hc + Vector3(0, h * 0.12, h * 0.08), Vector3(0.6, 0.45, 0.5) * h, blue, Vector3.ZERO, 12)   # kapüşon arkası
		# mavi yelek + boyunda bağlı fular
		Loft.tube(b, [Vector3(0, h * 0.42, h * 0.12), Vector3(0, h * 0.5, -h * 0.08), Vector3(0, h * 0.58, -h * 0.22)], [Vector2(0.31, 0.29) * h, Vector2(0.35, 0.34) * h, Vector2(0.31, 0.31) * h], blue, 18, 3, false, false,
			func(_t: float, _a: float, d: Vector3) -> Color: return blue if d.y > -0.35 else c.lightened(0.15))
		b.add("box", Vector3(0, h * 0.62, -h * 0.5), Vector3(0.2, 0.12, 0.04) * h, blue.darkened(0.15), Vector3(0, 0, 45))   # fular düğümü
		b.add("box", Vector3(0, h * 0.62, -h * 0.5), Vector3(0.2, 0.12, 0.04) * h, blue.darkened(0.15), Vector3(0, 0, -45))
	_mesh(out["root"], b)
	for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var pv = _pivot(out["root"], Vector3(q.x * h * 0.17, h * 0.32, q.z * h * 0.22))
		var lb = MB.new()
		Loft.tube(lb, [Vector3.ZERO, Vector3(q.x * h * 0.02, -h * 0.16, -h * 0.02), Vector3(q.x * h * 0.02, -h * 0.29, -h * 0.04)], [h * 0.09, h * 0.075, h * 0.07], c, 10, 3)
		lb.add("sphere", Vector3(q.x * h * 0.02, -h * 0.3, -h * 0.08), Vector3(0.13, 0.06, 0.15) * h, c.lightened(0.1), Vector3.ZERO, 8)
		if gear and q.x < 0.0 and q.z < 0.0:
			for k in 4:   # sargılı ön pati
				lb.add("torus", Vector3(q.x * h * 0.02, -h * 0.06 - k * h * 0.05, -h * 0.03), Vector3(0.19, 0.19, 0.19) * h, Color(0.96, 0.95, 0.92), Vector3(0, 0, 8 if k % 2 else -8), 8)
		_mesh(pv, lb)
		out["legs"].append(pv)
	var tail = _pivot(out["root"], Vector3(0, h * 0.5, h * 0.4))
	var tb = MB.new()
	Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.12, h * 0.06), Vector3(0, h * 0.14, -h * 0.04)], [h * 0.06, h * 0.05, h * 0.03], c, 8, 3)   # kıvrık kısa kuyruk
	_mesh(tail, tb)
	out["tail"] = tail
	out["mouth"] = hc + Vector3(0, -h * 0.15, -h * 0.34)


static func _wolf2(out: Dictionary, h: float, heads := [-0.22, 0.22]) -> void:
	var white = Color(0.96, 0.96, 0.97)
	var b = _quad(out, h, white, {"len": 1.25, "leg": 0.4, "snout": 0.34, "ear": 0.18, "heads": heads, "eye": Color(0.85, 0.15, 0.1), "tail": "bushy", "belly": white, "mark": Color(0.5, 0.5, 0.55)})
	var by = h * 0.4 + h * 0.12
	var L = h * 1.25
	# iri kaslı kütle: geniş göğüs, kambur omuzlar, kalça
	b.add("sphere", Vector3(0, by + h * 0.12, -L * 0.3), Vector3(0.62, 0.55, 0.6) * h, white, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, by + h * 0.08, L * 0.3), Vector3(0.5, 0.48, 0.5) * h, white, Vector3.ZERO, 14)
	for hx in heads:   # boyun yelesi: her baş için gür tüy kütlesi
		b.add("sphere", Vector3(hx * h, by + h * 0.3, -L * 0.5), Vector3(0.34, 0.36, 0.3) * h, white, Vector3.ZERO, 12)
	# gür beyaz yele: omuzlarda, boyunlarda ve sırtta kabarık tüy dikenleri
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	for i in 70:
		var t = rng.randf()
		var a = rng.randf_range(-1.4, 1.4)
		var z = lerpf(-L * 0.5, L * 0.4, t)
		var r = h * (0.24 if z < -L * 0.2 else 0.2)
		BeastRig.claw(b, Vector3(sin(a) * r, by + h * 0.08 + cos(a) * r, z), Vector3(sin(a) * 0.7, cos(a), 0.6).normalized(), h * rng.randf_range(0.12, 0.22), h * 0.04, white.darkened(0.04))
	# iki başta açık çene ve sivri dişler
	for hx0 in heads:
		var hx = float(hx0) * 0.92
		var hp = Vector3(hx * h * 1.2, by + h * 0.48, -L * 0.62)
		var sn = h * 0.34
		b.add("sphere", hp + Vector3(0, -h * 0.11, -h * 0.06 - sn * 0.7), Vector3(0.1, 0.03, 0.2) * h, Color(0.55, 0.15, 0.18), Vector3(15, 0, 0), 8)   # ağız içi
		Loft.tube(b, [hp + Vector3(0, -h * 0.09, -h * 0.02), hp + Vector3(0, -h * 0.15, -h * 0.06 - sn * 0.6), hp + Vector3(0, -h * 0.17, -h * 0.06 - sn * 0.9)], [Vector2(0.08, 0.04) * h, Vector2(0.06, 0.03) * h, Vector2(0.03, 0.02) * h], white, 10, 2, true, true)   # alt çene
		for sx in [-1.0, 1.0]:
			for k in 4:
				BeastRig.claw(b, hp + Vector3(sx * h * 0.035, -h * 0.07, -h * 0.08 - k * sn * 0.2), Vector3(0, -1, 0), h * 0.05, h * 0.012, Color(0.97, 0.96, 0.92))
				BeastRig.claw(b, hp + Vector3(sx * h * 0.03, -h * 0.15, -h * 0.1 - k * sn * 0.18), Vector3(0, 1, 0), h * 0.04, h * 0.01, Color(0.97, 0.96, 0.92))
	_mesh(out["root"], b)
	for lg in out["legs"]:   # kalın güçlü bacaklar, saldırı duruşunda yana açık
		lg.scale = Vector3(1.9, 1.0, 1.7)
	if out["tail"]:
		out["tail"].scale = Vector3.ONE * 1.6


## Chikushōdō Çok Başlı Dev Köpek (kanon, Pain): koyu kömür grisi, zırhsız, üç başlı (Cerberus), uzun bacaklı;
## gözleri mor Rinnegan, bedeni kara alıcılarla delik (alıcılar ve göz halkası _rinnegan_mark ile eklenir).
static func _rin_dog(out: Dictionary, h: float) -> void:
	var c = Color(0.2, 0.19, 0.22)
	var b = _quad(out, h, c, {"len": 1.2, "leg": 0.48, "snout": 0.3, "ear": 0.14, "heads": [-0.3, 0.0, 0.3], "eye": Color(0.72, 0.6, 0.95), "tail": "thin", "belly": c.lightened(0.12), "mark": c.darkened(0.3)})
	var by = h * 0.48 + h * 0.12
	var L = h * 1.2
	b.add("sphere", Vector3(0, by + h * 0.1, -L * 0.28), Vector3(0.6, 0.5, 0.6) * h, c, Vector3.ZERO, 14)
	for hx in [-0.3, 0.0, 0.3]:   # üç boyun
		b.add("sphere", Vector3(hx * h, by + h * 0.28, -L * 0.48), Vector3(0.26, 0.3, 0.26) * h, c, Vector3.ZERO, 10)
	_mesh(out["root"], b)
	_rin_eyes(out, h, [-0.3, 0.0, 0.3], by + h * 0.42, -L * 0.66, 0.06)


## Rinnegan gözleri (Pain'in çağrıları): her başta iki parlak lila göz, koyu halkalı; ışıksız (gölgede de seçilir)
static func _rin_eyes(out: Dictionary, h: float, heads: Array, y: float, z: float, sep: float) -> void:
	var eb = MB.new()
	for hx in heads:
		for sx in [-1.0, 1.0]:
			var p = Vector3(float(hx) * h + sx * sep * h, y, z)
			eb.add("sphere", p, Vector3(0.07, 0.06, 0.03) * h, Color(0.85, 0.78, 1.0), Vector3(0, sx * 30, 0), 8)
			eb.add("torus", p + Vector3(0, 0, -0.012 * h), Vector3(0.035, 0.035, 0.035) * h, Color(0.3, 0.18, 0.45), Vector3(90, sx * 30, 0), 10)
	var mi = MeshInstance3D.new()
	mi.mesh = eb.build(null)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	mi.material_override = m
	out["root"].add_child(mi)


## Dev Çıyan (kanon, Pain): uzun segmentli koyu gövde, turuncu yüz ve bacaklar, başından geçen alıcı, Rinnegan gözler
static func _rin_centipede(out: Dictionary, h: float) -> void:
	var b = MB.new()
	var body = Color(0.18, 0.12, 0.1)
	var ora = Color(0.9, 0.45, 0.12)
	var n = 14
	var seg = h * 0.55
	for i in n:
		var z = -h * 1.2 + i * seg
		var y = h * 0.42 + sin(i * 0.6) * h * 0.08
		var w = h * (0.42 - absf(i - 3.0) * 0.008)
		b.add("sphere", Vector3(0, y, z), Vector3(w * 2.0, w * 1.3, seg * 1.25), body, Vector3.ZERO, 12)
		b.add("box", Vector3(0, y + w * 0.6, z), Vector3(w * 1.7, w * 0.12, seg * 0.6), body.lightened(0.12))   # sırt plakası
		for sx in [-1.0, 1.0]:   # turuncu bacaklar
			Loft.tube(b, [Vector3(sx * w * 0.8, y - w * 0.2, z), Vector3(sx * w * 2.0, y + w * 0.3, z - seg * 0.1), Vector3(sx * w * 2.6, 0.0, z - seg * 0.25)], [h * 0.06, h * 0.045, h * 0.02], ora, 6, 2)
	var hz = -h * 1.2 - seg * 0.9
	var hy = h * 0.5
	b.add("sphere", Vector3(0, hy, hz), Vector3(h * 0.9, h * 0.6, h * 0.8), ora, Vector3.ZERO, 12)   # turuncu yüz
	for sx in [-1.0, 1.0]:   # çeneler (forcipule) ve antenler
		Loft.tube(b, [Vector3(sx * h * 0.25, hy - h * 0.15, hz - h * 0.3), Vector3(sx * h * 0.35, hy - h * 0.2, hz - h * 0.6), Vector3(sx * h * 0.12, hy - h * 0.2, hz - h * 0.8)], [h * 0.07, h * 0.05, h * 0.015], Color(0.25, 0.1, 0.08), 6, 2)
		Loft.tube(b, [Vector3(sx * h * 0.2, hy + h * 0.2, hz - h * 0.2), Vector3(sx * h * 0.6, hy + h * 0.7, hz - h * 0.6), Vector3(sx * h * 0.9, hy + h * 0.9, hz - h * 0.4)], [h * 0.03, h * 0.02, h * 0.008], body, 5, 2)
	b.add("cyl", Vector3(h * 0.1, hy + h * 0.3, hz), Vector3(h * 0.05, h * 0.9, h * 0.05), Color(0.05, 0.04, 0.06), Vector3(0, 0, 25), 6)   # başı delen alıcı
	_mesh(out["root"], b)
	_rin_eyes(out, h, [0.0], hy + h * 0.12, hz - h * 0.38, 0.18)
	out["mouth"] = Vector3(0, hy - h * 0.15, hz - h * 0.5)


## Dev Kabuklu (kanon, Pain): kırmızımsı zırhlı yengeç-istakoz; ağız çevresi ve altı beyaz, sekiz yengeç bacağı,
## iki iri kıskaç, sırtın altında çok sayıda iri diken (ortada en büyüğü), sırtta iki alıcı; Rinnegan gözler
static func _rin_crab(out: Dictionary, h: float) -> void:
	var b = MB.new()
	var red = Color(0.72, 0.22, 0.16)
	var white = Color(0.92, 0.9, 0.86)
	var by = h * 0.55
	b.add("sphere", Vector3(0, by, 0), Vector3(h * 1.9, h * 0.75, h * 1.5), red, Vector3.ZERO, 16)
	b.add("sphere", Vector3(0, by - h * 0.2, 0), Vector3(h * 1.7, h * 0.4, h * 1.3), white, Vector3.ZERO, 14)   # beyaz alt
	b.add("sphere", Vector3(0, by - h * 0.05, -h * 0.68), Vector3(h * 0.6, h * 0.35, h * 0.3), white, Vector3.ZERO, 10)   # ağız çevresi
	b.add("sphere", Vector3(0, by - h * 0.05, -h * 0.78), Vector3(h * 0.3, h * 0.15, h * 0.1), Color(0.05, 0.03, 0.03), Vector3.ZERO, 8)
	for k in 7:   # sırtın arkasında iri dikenler
		var a = (k - 3) * 0.32
		var big = k == 3
		BeastRig.claw(b, Vector3(sin(a) * h * 0.55, by + h * 0.2, h * 0.45 + cos(a) * h * 0.1), Vector3(sin(a) * 0.4, 1, 0.5), h * (0.9 if big else 0.45), h * (0.14 if big else 0.08), red.darkened(0.15))
	for sx in [-1.0, 1.0]:
		for k in 4:   # sekiz bacak
			var z = lerpf(-h * 0.3, h * 0.45, k / 3.0)
			Loft.tube(b, [Vector3(sx * h * 0.8, by - h * 0.1, z), Vector3(sx * h * 1.4, by + h * 0.25, z), Vector3(sx * h * 1.75, 0.0, z + h * 0.1)], [h * 0.09, h * 0.07, h * 0.03], red, 6, 2)
		# kıskaç
		var c0 = Vector3(sx * h * 0.7, by, -h * 0.55)
		var c1 = Vector3(sx * h * 1.1, by + h * 0.1, -h * 1.0)
		Loft.tube(b, [c0, c1], [h * 0.12, h * 0.14], red, 8, 2)
		b.add("sphere", c1 + Vector3(0, 0, -h * 0.25), Vector3(h * 0.45, h * 0.32, h * 0.6), red, Vector3.ZERO, 10)
		BeastRig.claw(b, c1 + Vector3(sx * h * 0.05, h * 0.05, -h * 0.5), Vector3(0, 0.2, -1), h * 0.4, h * 0.1, red.darkened(0.1))
		BeastRig.claw(b, c1 + Vector3(-sx * h * 0.05, -h * 0.08, -h * 0.45), Vector3(0, -0.2, -1), h * 0.3, h * 0.08, red.darkened(0.1))
	for q in [Vector3(-h * 0.4, by + h * 0.35, -h * 0.1), Vector3(h * 0.45, by + h * 0.3, h * 0.25)]:   # sırttaki alıcılar
		b.add("cyl", q, Vector3(h * 0.05, h * 0.7, h * 0.05), Color(0.05, 0.04, 0.06), Vector3(15, 0, 10), 6)
	_mesh(out["root"], b)
	for sx in [-1.0, 1.0]:   # sapı üstünde gözler
		var es = MB.new()
		Loft.tube(es, [Vector3(sx * h * 0.25, by + h * 0.25, -h * 0.6), Vector3(sx * h * 0.28, by + h * 0.5, -h * 0.65)], [h * 0.04, h * 0.035], red, 6, 2)
		_mesh(out["root"], es)
	_rin_eyes(out, h, [-0.28, 0.28], by + h * 0.55, -h * 0.7, 0.0)
	out["mouth"] = Vector3(0, by - h * 0.05, -h * 0.8)


## Chikushōdō'nun diğer kanon çağrıları: Dev Gergedan, Dev Öküz, Dev Panda, Dev Bukalemun (görünmezlik)
static func _rin_beast(out: Dictionary, model: String, h: float) -> void:
	var p := {}
	var c := Color(0.5, 0.5, 0.52)
	match model:
		"rin_rhino":
			c = Color(0.55, 0.53, 0.55)
			p = {"len": 1.5, "leg": 0.36, "snout": 0.32, "ear": 0.1, "heads": [0.0], "eye": Color(0.8, 0.7, 1.0), "tail": "thin", "belly": c.lightened(0.1), "mark": c.darkened(0.3)}
		"rin_ox":
			c = Color(0.42, 0.3, 0.22)
			p = {"len": 1.45, "leg": 0.42, "snout": 0.26, "ear": 0.12, "heads": [0.0], "eye": Color(0.8, 0.7, 1.0), "tail": "thin", "belly": c.lightened(0.15), "mark": c.darkened(0.35)}
		"rin_panda":
			c = Color(0.95, 0.95, 0.93)
			p = {"len": 1.15, "leg": 0.34, "snout": 0.16, "ear": 0.1, "heads": [0.0], "eye": Color(0.8, 0.7, 1.0), "tail": "thin", "belly": c, "mark": Color(0.1, 0.1, 0.12)}
		_:
			c = Color(0.38, 0.5, 0.36)
			p = {"len": 1.8, "leg": 0.22, "snout": 0.3, "ear": 0.02, "heads": [0.0], "eye": Color(0.8, 0.7, 1.0), "tail": "thin", "belly": c.lightened(0.2), "mark": c.darkened(0.25)}
	var b = _quad(out, h, c, p)
	var by = h * float(p["leg"]) + h * 0.12
	var L = h * float(p["len"])
	var head = Vector3(0, by + h * 0.3, -L * 0.62)
	match model:
		"rin_rhino":   # iri gövde, burun boynuzları
			b.add("sphere", Vector3(0, by + h * 0.12, 0), Vector3(0.75, 0.62, 1.2) * h, c, Vector3.ZERO, 14)
			BeastRig.claw(b, head + Vector3(0, -h * 0.02, -h * 0.28), Vector3(0, 1, -0.6), h * 0.3, h * 0.07, Color(0.85, 0.82, 0.75))
			BeastRig.claw(b, head + Vector3(0, h * 0.06, -h * 0.12), Vector3(0, 1, -0.3), h * 0.16, h * 0.05, Color(0.85, 0.82, 0.75))
		"rin_ox":   # kambur omuz, yana kıvrık boynuzlar
			b.add("sphere", Vector3(0, by + h * 0.2, -L * 0.25), Vector3(0.7, 0.66, 0.7) * h, c, Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				Loft.tube(b, [head + Vector3(sx * h * 0.1, h * 0.1, 0), head + Vector3(sx * h * 0.3, h * 0.12, -h * 0.02), head + Vector3(sx * h * 0.38, h * 0.3, -h * 0.1)], [h * 0.04, h * 0.03, h * 0.008], Color(0.88, 0.84, 0.72), 6, 2)
		"rin_panda":   # yuvarlak beyaz gövde; siyah bacak-omuz kuşağı, kulaklar, göz lekeleri
			b.add("sphere", Vector3(0, by + h * 0.15, 0), Vector3(0.85, 0.8, 1.0) * h, c, Vector3.ZERO, 14)
			b.add("sphere", Vector3(0, by + h * 0.22, -L * 0.15), Vector3(0.9, 0.5, 0.45) * h, Color(0.1, 0.1, 0.12), Vector3.ZERO, 12)
			for sx in [-1.0, 1.0]:
				b.add("sphere", head + Vector3(sx * h * 0.13, h * 0.17, h * 0.02), Vector3(0.11, 0.11, 0.06) * h, Color(0.1, 0.1, 0.12), Vector3.ZERO, 8)
				b.add("sphere", head + Vector3(sx * h * 0.07, h * 0.03, -h * 0.13), Vector3(0.09, 0.07, 0.04) * h, Color(0.1, 0.1, 0.12), Vector3.ZERO, 8)
		_:   # bukalemun: alçak uzun gövde, sırt sırtı, kıvrık kuyruk, çıkık gözler
			for k in 8:
				BeastRig.claw(b, Vector3(0, by + h * 0.3, lerpf(-L * 0.4, L * 0.35, k / 7.0)), Vector3(0, 1, 0.2), h * 0.12, h * 0.04, c.darkened(0.15))
	_mesh(out["root"], b)
	_rin_eyes(out, h, [0.0], head.y + h * 0.04, head.z - h * 0.16, 0.09)
	out["mouth"] = head + Vector3(0, -h * 0.05, -h * 0.25)





## Savaş ninkeni Kurogane (özgün): tek başlı dev kömür grisi köpek — kısa sert tüy, açık gri namlu ve göğüs, sol gözde dikey yara izi (kör, soluk göz),
## kırmızı lake zırh koşum (omuz plakaları, göğüs plakası, sırtta binek eyeri), boynunda çivili deri tasma ve metal alın plakası, kalın pençe sargıları.
static func _war_hound(out: Dictionary, h: float) -> void:
	var c = Color(0.24, 0.24, 0.27)
	var light = Color(0.62, 0.6, 0.58)
	var red = Color(0.62, 0.12, 0.1)
	var metal = Color(0.7, 0.72, 0.76)
	var leather = Color(0.3, 0.2, 0.13)
	var b = _quad(out, h, c, {"len": 1.15, "leg": 0.46, "snout": 0.3, "ear": 0.17, "eye": Color(0.95, 0.72, 0.2), "tail": "bushy", "belly": light, "mark": Color(0.1, 0.1, 0.12)})
	var by = h * 0.46 + h * 0.12
	var L = h * 1.15
	var hp = Vector3(0, by + h * 0.48, -L * 0.62)
	# kaslı omuz ve göğüs kütlesi
	b.add("sphere", Vector3(0, by + h * 0.1, -L * 0.3), Vector3(0.52, 0.5, 0.56) * h, c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, by - h * 0.02, -L * 0.36), Vector3(0.36, 0.34, 0.34) * h, light, Vector3.ZERO, 12)   # açık göğüs
	b.add("sphere", hp + Vector3(0, -h * 0.05, -h * 0.2), Vector3(0.16, 0.12, 0.2) * h, light, Vector3.ZERO, 10)   # açık namlu
	# sol gözde yara: dikey koyu çizik + soluk kör göz
	var ep = hp + Vector3(-0.075 * h, h * 0.05, -h * 0.135)
	b.add("sphere", ep + Vector3(0, 0, -h * 0.012), Vector3(0.072, 0.047, 0.04) * h, Color(0.72, 0.74, 0.76), Vector3(0, 0, 15), 8)
	b.add("box", ep + Vector3(-h * 0.005, 0, -h * 0.03), Vector3(0.018, 0.2, 0.012) * h, Color(0.42, 0.18, 0.18), Vector3(0, 0, 8))
	# metal alın plakası + çivili tasma
	b.add("box", hp + Vector3(0, h * 0.12, -h * 0.06), Vector3(0.17, 0.06, 0.02) * h, metal, Vector3(-30, 0, 0))
	var nk = Vector3(0, by + h * 0.34, -L * 0.52)
	b.add("torus", nk, Vector3(0.34, 0.34, 0.34) * h, leather, Vector3(70, 0, 0), 14)
	for k in 8:
		var a = k * TAU / 8.0
		var d = Vector3(cos(a), sin(a) * 0.35, sin(a) * 0.94).normalized()
		BeastRig.claw(b, nk + Vector3(cos(a) * h * 0.17, sin(a) * h * 0.06, sin(a) * h * 0.16), d, h * 0.05, h * 0.015, metal)
	# kırmızı lake zırh: omuz plakaları, göğüs plakası, sırt eyeri ve yan etekler
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * h * 0.24, by + h * 0.2, -L * 0.32), Vector3(0.09, 0.2, 0.28) * h, red, Vector3(0, 0, 25 * sx), 12)
		b.add("box", Vector3(sx * h * 0.2, by - h * 0.02, -L * 0.02), Vector3(0.02, 0.2, 0.42) * h, red.darkened(0.15), Vector3(0, 0, -12 * sx))
		for k in 3:   # etek plakalarının metal perçinleri
			b.add("sphere", Vector3(sx * h * 0.215, by + h * 0.04, -L * 0.15 + k * h * 0.14), Vector3.ONE * h * 0.025, metal, Vector3.ZERO, 6)
	b.add("box", Vector3(0, by + h * 0.04, -L * 0.48), Vector3(0.26, 0.24, 0.03) * h, red, Vector3(-25, 0, 0))
	b.add("box", Vector3(0, by + h * 0.22, -L * 0.02), Vector3(0.34, 0.05, 0.44) * h, red)   # eyer
	b.add("box", Vector3(0, by + h * 0.26, -L * 0.2), Vector3(0.26, 0.08, 0.04) * h, leather)   # eyer kaşı
	b.add("box", Vector3(0, by + h * 0.25, L * 0.17), Vector3(0.26, 0.06, 0.04) * h, leather)
	for z in [-L * 0.12, L * 0.1]:   # koşum kayışları
		b.add("torus", Vector3(0, by + h * 0.05, z), Vector3(0.44, 0.44, 0.44) * h, leather, Vector3(90, 0, 0), 14)
	_mesh(out["root"], b)
	for lg in out["legs"]:   # kalın bacaklar + bilekte beyaz sargı
		lg.scale = Vector3(1.6, 1.0, 1.5)
		var wb = MB.new()
		for k in 3:
			wb.add("torus", Vector3(0, -h * 0.36 - k * h * 0.035, -h * 0.02), Vector3(0.075, 0.075, 0.075) * h, Color(0.93, 0.92, 0.88), Vector3(0, 0, 8 if k % 2 else -8), 8)
		_mesh(lg, wb)
	if out["tail"]:
		out["tail"].scale = Vector3(1.1, 0.7, 0.75)   # kısa, alçak taşınan kuyruk


## Kediler (REFERANS): ninneko — açık kahve kabarık kedi, oturur; alında 忍 kanjisi, iri sivri kulaklar (pembe iç), kapalı gülümseyen gözler ve ":3" ağız,
## yanaklarda kabarık tüy, lavanta kimono (file iç gömlek, beyaz kuşak, kuşağa sıkışmış parşömen), gür kabarık kuyruk.
## Nekomata — dev beyaz gür tüylü kedi ruhu: siyah kaplan çizgileri, başta siyah tüy perçemi, sarı öfkeli gözler, sivri dişli sırıtış, iki kuyruk, pençeler.
static func _cat(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "walk"
	if model == "cat_giant":
		_nekomata(out, h)
		return
	var c = Color(0.8, 0.66, 0.55)
	var light = Color(0.93, 0.85, 0.76)
	var kimono = Color(0.62, 0.66, 0.8)
	var b = MB.new()
	# oturur gövde (kimonolu)
	Loft.tube(b, [Vector3(0, h * 0.12, h * 0.08), Vector3(0, h * 0.35, h * 0.02), Vector3(0, h * 0.58, -h * 0.02)], [Vector2(0.32, 0.3) * h, Vector2(0.3, 0.27) * h, Vector2(0.22, 0.2) * h], kimono, 18, 4, true, true,
		func(_t: float, _a: float, d: Vector3) -> Color: return (Color(0.45, 0.45, 0.48) if _t > 0.6 else light) if (d.z < -0.6 and absf(d.x) < 0.3) else kimono)   # önde file / tüy
	Loft.tube(b, [Vector3(-0.001, h * 0.3, h * 0.03), Vector3(0.001, h * 0.3, h * 0.03)], [Vector2(0.305, 0.275) * h, Vector2(0.305, 0.275) * h], Color(0.95, 0.94, 0.9), 18, 1, false, false)   # beyaz kuşak
	b.add("cyl", Vector3(h * 0.26, h * 0.36, -h * 0.12), Vector3(0.06, 0.32, 0.06) * h, Color(0.96, 0.94, 0.88), Vector3(0, 0, -15), 8)   # kuşakta parşömen
	# baş: iri yuvarlak, yanaklarda kabarık tüy
	var hc = Vector3(0, h * 0.82, -h * 0.04)
	b.add("sphere", hc, Vector3(0.46, 0.46, 0.44) * h, c, Vector3.ZERO, 18)
	b.add("sphere", hc + Vector3(0, -h * 0.08, -h * 0.16), Vector3(0.22, 0.14, 0.14) * h, light, Vector3.ZERO, 12)   # ağız çevresi
	for sx in [-1.0, 1.0]:
		BeastRig.claw(b, hc + Vector3(h * 0.21 * sx, -h * 0.06, -h * 0.05), Vector3(sx, -0.5, 0.1).normalized(), h * 0.1, h * 0.06, c)   # yanak tüyü (kısa)
		BeastRig.claw(b, hc + Vector3(h * 0.2 * sx, -h * 0.13, -h * 0.03), Vector3(sx * 0.7, -0.8, 0.1).normalized(), h * 0.09, h * 0.05, c)
		# iri sivri kulak + pembe iç
		var e0 = hc + Vector3(h * 0.14 * sx, h * 0.16, h * 0.0)
		Loft.tube(b, [e0, e0 + Vector3(h * 0.05 * sx, h * 0.16, -h * 0.01), e0 + Vector3(h * 0.07 * sx, h * 0.3, -h * 0.02)], [Vector2(0.1, 0.04) * h, Vector2(0.07, 0.03) * h, Vector2(0.004, 0.004) * h], c, 8, 2, true, false)
		b.add("box", e0 + Vector3(h * 0.05 * sx, h * 0.13, -h * 0.035), Vector3(0.07, 0.15, 0.01) * h, Color(0.95, 0.72, 0.7), Vector3(0, 0, -12 * sx))
		# kapalı gülümseyen göz (aşağı açık yay)
		for q in 5:
			var u = (q - 2) / 2.0
			b.add("box", hc + Vector3(h * 0.1 * sx + u * h * 0.035, h * 0.04 + (1.0 - u * u) * h * 0.02, -h * 0.215), Vector3(h * 0.03, h * 0.01, h * 0.01), Color(0.25, 0.15, 0.1), Vector3(0, 0, -u * 30.0))
		for w in 3:   # bıyık
			b.add("box", hc + Vector3(h * 0.2 * sx, -h * 0.06 - w * h * 0.025, -h * 0.17), Vector3(0.22, 0.005, 0.005) * h, Color(0.3, 0.2, 0.15), Vector3(0, -15 * sx, (w - 1) * 10 * sx))
	b.add("sphere", hc + Vector3(0, -h * 0.03, -h * 0.225), Vector3(0.05, 0.035, 0.03) * h, Color(0.55, 0.38, 0.32), Vector3.ZERO, 8)   # burun
	for q in 6:   # ":3" ağız
		var u = (q - 2.5) / 2.5
		b.add("box", hc + Vector3(u * h * 0.06, -h * 0.09 + absf(sin(u * PI)) * h * 0.012, -h * 0.215), Vector3(h * 0.025, h * 0.008, h * 0.01), Color(0.25, 0.15, 0.1), Vector3(0, 0, 25 if u < 0 else -25))
	_mesh(out["root"], b)
	var kj = Label3D.new()   # alında 忍 kanjisi
	kj.text = "忍"
	kj.font_size = 96
	kj.pixel_size = h * 0.0016
	kj.modulate = Color(0.32, 0.18, 0.1)
	kj.outline_size = 0
	kj.shaded = false
	kj.position = hc + Vector3(0, h * 0.13, -h * 0.215)
	kj.rotation.y = PI
	out["root"].add_child(kj)
	# ön patiler (kimono kolları) ve arka bacaklar
	for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var front = q.z < 0
		var pv = _pivot(out["root"], Vector3(q.x * h * 0.13, h * (0.42 if front else 0.18), q.z * h * 0.12))
		var lb = MB.new()
		var foot = Vector3(q.x * h * 0.02, -h * (0.4 if front else 0.16), -h * 0.1)
		Loft.tube(lb, [Vector3.ZERO, foot], [h * 0.08, h * 0.06], kimono if front else c, 10, 2)
		lb.add("sphere", foot + Vector3(0, -h * 0.01, -h * 0.03), Vector3(0.1, 0.06, 0.12) * h, light, Vector3.ZERO, 8)
		_mesh(pv, lb)
		out["legs"].append(pv)
	var tail = _pivot(out["root"], Vector3(0, h * 0.18, h * 0.3))
	var tb = MB.new()
	Loft.tube(tb, [Vector3.ZERO, Vector3(h * 0.08, h * 0.15, h * 0.2), Vector3(h * 0.12, h * 0.45, h * 0.25), Vector3(h * 0.06, h * 0.75, h * 0.15)], [h * 0.08, h * 0.14, h * 0.13, h * 0.03], c, 12, 3, true, false)   # gür kuyruk
	_mesh(tail, tb)
	out["tail"] = tail
	out["mouth"] = hc + Vector3(0, -h * 0.09, -h * 0.22)


## 忍 kanjisi (basit çizgilerle): üstte 刃, altta 心
static func _kanji_mark(b: MB, p: Vector3, s: float, col: Color) -> void:
	var strokes = [[Vector2(-0.5, 0.9), Vector2(0.4, 0.9)], [Vector2(0.4, 0.9), Vector2(0.3, 0.2)], [Vector2(-0.1, 1.0), Vector2(-0.5, 0.2)], [Vector2(0.05, 0.6), Vector2(0.2, 0.45)],
		[Vector2(-0.7, -0.2), Vector2(-0.6, -0.7)], [Vector2(-0.4, -0.1), Vector2(-0.3, -0.8)], [Vector2(-0.3, -0.8), Vector2(0.4, -0.8)], [Vector2(0.0, -0.1), Vector2(0.1, -0.3)], [Vector2(0.6, -0.2), Vector2(0.7, -0.5)]]
	for st in strokes:
		var a: Vector2 = st[0] * s
		var c2: Vector2 = st[1] * s
		var m = (a + c2) * 0.5
		var d = c2 - a
		b.add("box", p + Vector3(m.x, m.y, 0), Vector3(d.length() + s * 0.12, s * 0.14, s * 0.05), col, Vector3(0, 0, rad_to_deg(atan2(d.y, d.x))))


static func _nekomata(out: Dictionary, h: float) -> void:
	var white = Color(0.93, 0.94, 0.97)
	var stripe = Color(0.12, 0.12, 0.15)
	var b = _quad(out, h, white, {"len": 1.3, "leg": 0.5, "snout": 0.14, "ear": 0.22, "eye": Color(0.95, 0.85, 0.3), "tail": "thin", "belly": white, "mark": stripe})
	var by = h * 0.5 + h * 0.12
	var L = h * 1.3
	# siyah kaplan çizgileri: gövdenin yanlarında ve sırtında eğik koyu bantlar
	for k in 7:
		var z = -L * 0.35 + k * L * 0.12
		for sx in [-1.0, 1.0]:
			Loft.tube(b, [Vector3(sx * h * 0.05, by + h * 0.27, z), Vector3(sx * h * 0.19, by + h * 0.18, z + h * 0.04), Vector3(sx * h * 0.23, by + h * 0.02, z + h * 0.1)], [h * 0.025, h * 0.03, h * 0.01], stripe, 6, 3)
	# gür beyaz tüy: göğüs ve omuzlarda tutamlar
	var rng = RandomNumberGenerator.new()
	rng.seed = 13
	for i in 40:
		var a = rng.randf_range(-1.6, 1.6)
		var z = rng.randf_range(-L * 0.45, L * 0.1)
		BeastRig.claw(b, Vector3(sin(a) * h * 0.24, by + h * 0.05 + cos(a) * h * 0.24, z), Vector3(sin(a) * 0.6, cos(a) * 0.6 - 0.4, 0.5).normalized(), h * rng.randf_range(0.1, 0.2), h * 0.035, white)
	# başta siyah tüy perçemi + sivri dişli sırıtış
	var hp = Vector3(0, by + h * 0.48, -L * 0.62)
	for k in 9:
		var aa = lerpf(-1.2, 1.2, k / 8.0)
		BeastRig.claw(b, hp + Vector3(sin(aa) * h * 0.1, h * 0.12, h * 0.05), Vector3(sin(aa) * 0.8, 0.8, 0.5).normalized(), h * 0.16, h * 0.04, stripe)
	b.add("sphere", hp + Vector3(0, -h * 0.1, -h * 0.17), Vector3(0.16, 0.06, 0.08) * h, Color(0.55, 0.15, 0.2), Vector3.ZERO, 8)   # açık ağız
	for sx in [-1.0, 1.0]:
		for k in 3:
			BeastRig.claw(b, hp + Vector3(sx * h * (0.02 + k * 0.025), -h * 0.07, -h * 0.2 + k * h * 0.02), Vector3(0, -1, 0), h * 0.05, h * 0.012, Color(0.97, 0.96, 0.92))
	_mesh(out["root"], b)
	# ikinci kuyruk (çatallı: iki ince kuyruk)
	var t2 = _pivot(out["root"], Vector3(0, by + h * 0.12, L * 0.5))
	var tb = MB.new()
	Loft.tube(tb, [Vector3.ZERO, Vector3(-h * 0.25, h * 0.15, h * 0.3), Vector3(-h * 0.35, h * 0.5, h * 0.4), Vector3(-h * 0.25, h * 0.75, h * 0.3)], [h * 0.05, h * 0.045, h * 0.04, h * 0.01], white, 10, 3, true, false)
	_mesh(t2, tb)



## Orak gelincik (REFERANS): uzun ince beyaz gövde, yassı geniş baş, küçük yuvarlak kulaklar, koyu göz bandı (göz maskesi üzerinde bez),
## siyah gövde yeleği (kırmızı kenarlı, çapraz bağcıklı, altın kordonlu), sargılı ön kol, sırtta altın bilezikli uzun saplı dev orak, gür beyaz kuyruk.
static func _weasel(out: Dictionary, h: float) -> void:
	out["anim"] = "walk"
	var c = Color(0.94, 0.94, 0.92)
	var b = _quad(out, h, c, {"len": 2.0, "leg": 0.26, "snout": 0.1, "ear": 0.05, "eye": Color(0.1, 0.06, 0.05), "tail": "bushy", "belly": Color(0.98, 0.98, 0.96), "mark": Color(0.4, 0.36, 0.32)})
	var L = h * 2.0
	var by = h * 0.26 + h * 0.12
	# yelek: gövdenin ön-orta kısmını saran siyah bant, kırmızı kenarlar, sırtta çapraz kırmızı bağcık + altın kordon düğümü
	var vest_fn = func(tt: float, a: float, d: Vector3) -> Color:
		if tt < 0.06 or tt > 0.94:
			return Color(0.75, 0.12, 0.12)
		if d.y > 0.75 and absf(fposmod(tt * 9.0, 1.0) - 0.5) < 0.12:
			return Color(0.8, 0.15, 0.15)
		return Color(0.08, 0.08, 0.1) if d.y > -0.55 else c
	Loft.tube(b, [Vector3(0, by + h * 0.05, L * 0.12), Vector3(0, by + h * 0.06, -L * 0.12), Vector3(0, by + h * 0.1, -L * 0.36)],
		[Vector2(0.185, 0.185) * h, Vector2(0.215, 0.255) * h, Vector2(0.235, 0.285) * h], Color(0.08, 0.08, 0.1), 18, 6, false, false, vest_fn)
	for sx in [-1.0, 1.0]:   # altın kordon düğümü
		Loft.tube(b, [Vector3(0, by + h * 0.37, -L * 0.2), Vector3(h * 0.08 * sx, by + h * 0.4, -L * 0.17), Vector3(h * 0.05 * sx, by + h * 0.36, -L * 0.1)], [h * 0.012, h * 0.012, h * 0.008], Color(0.95, 0.78, 0.25), 6, 2)
	# göz bandı: başın çevresinde koyu yeşil-gri bez (gözlerin üstünden)
	var hp = Vector3(0, by + h * 0.48, -L * 0.62)
	# bant: gözleri kapatır (yüzün önünden eğik geçen geniş bez)
	Loft.tube(b, [hp + Vector3(-0.001, h * 0.05, -h * 0.06), hp + Vector3(0.001, h * 0.05, -h * 0.06)], [Vector2(0.175, 0.16) * h, Vector2(0.175, 0.16) * h], Color(0.3, 0.36, 0.28), 16, 2, false, false)
	b.add("box", hp + Vector3(0, h * 0.05, -h * 0.215), Vector3(0.3, 0.07, 0.02) * h, Color(0.3, 0.36, 0.28), Vector3(0, 0, -8))
	for sx in [-1.0, 1.0]:   # yuvarlak kulaklar (koyu iç)
		b.add("sphere", hp + Vector3(h * 0.12 * sx, h * 0.13, h * 0.04), Vector3(0.08, 0.08, 0.04) * h, c, Vector3.ZERO, 8)
		b.add("sphere", hp + Vector3(h * 0.12 * sx, h * 0.13, h * 0.025), Vector3(0.05, 0.05, 0.02) * h, Color(0.45, 0.36, 0.32), Vector3.ZERO, 6)
	# sırtta dev orak: sap gövdenin sırtına çapraz yaslanır (kuyruk kökünden omza), ağız omuz üstünde yukarı-geriye kıvrılır
	var s0 = Vector3(h * 0.12, by + h * 0.27, L * 0.36)
	var s1 = Vector3(-h * 0.06, by + h * 0.46, -L * 0.3)
	Loft.tube(b, [s0, (s0 + s1) * 0.5 + Vector3(0, h * 0.02, 0), s1], [h * 0.03, h * 0.03, h * 0.03], Color(0.2, 0.16, 0.12), 8, 2)
	var ax = (s1 - s0).normalized()
	for t in [0.06, 0.97]:   # altın bilezikler
		b.add_xf("cyl", Transform3D(Basis(Quaternion(Vector3.UP, ax)) * Basis.from_scale(Vector3(0.08, 0.12, 0.08) * h), s0.lerp(s1, t)), Color(0.92, 0.75, 0.3), 10)
	for k in 3:   # sırta bağlayan kayış
		b.add("box", s0.lerp(s1, 0.25 + k * 0.25) + Vector3(-h * 0.05, -h * 0.05, 0), Vector3(0.24, 0.025, 0.04) * h, Color(0.3, 0.22, 0.15), Vector3(0, 0, -20))
	# hilal ağız: profil (y yukarı, z geri) — sap ucundan yukarı çıkıp geriye doğru kıvrılan geniş kavis
	var blade = PackedVector2Array()
	for k in 10:
		var t = k / 9.0
		blade.append(Vector2(sin(t * 2.0) * h * 0.75, (1.0 - cos(t * 2.0)) * h * 0.75))   # dış (keskin) kenar
	for k in 10:
		var t = 1.0 - k / 9.0
		blade.append(Vector2(sin(t * 1.85) * h * 0.58 + h * 0.02, (1.0 - cos(t * 1.85)) * h * 0.58 + h * 0.06))   # iç kenar
	b.add_slab(blade, h * 0.02, Color(0.42, 0.43, 0.46), Transform3D(Basis.IDENTITY, s1), func(p: Vector2) -> float: return h * 0.025, Color(0.7, 0.72, 0.75))
	_mesh(out["root"], b)
	# sargılı ön sol kol
	var pv: Node3D = out["legs"][0]
	var wb = MB.new()
	for k in 5:
		wb.add("torus", Vector3(-h * 0.01, -h * 0.06 - k * h * 0.045, h * 0.02), Vector3(0.12, 0.12, 0.12) * h, Color(0.96, 0.95, 0.92), Vector3(0, 0, 8 if k % 2 else -8), 8)
	_mesh(pv, wb)



## Maymunlar (REFERANS: Maymun Kral): dik duran iri, geniş omuzlu, hafif kambur maymun; gri-kahve yüz, çıkık ağız, ağır kaş,
## açık renk yuvarlak gözler; yukarı-geriye kabaran diken diken beyaz yele ve göğse inen uzun beyaz sakal; metal plakalı alın bandı;
## turuncu-siyah kaplan desenli haori, omuzlarda krem kabarık kürk yaka, göğüste file iç gömlek, koyu yeşil kollar, beyaz kürk bilekler,
## koyu kırmızı kuşak, koyu pantolon. Genç maymun: aynı yapı, sade yelek, sakal yok.
static func _monkey(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "biped"
	var king = model == "monkey_king"
	var skin = Color(0.48, 0.42, 0.38)
	var face = Color(0.58, 0.5, 0.45)
	var white = Color(0.93, 0.93, 0.95)
	var cream = Color(0.92, 0.88, 0.74)
	var tiger = Color(0.92, 0.6, 0.18)
	var sleeve = Color(0.28, 0.3, 0.24)
	var pants = Color(0.2, 0.21, 0.2)
	var sash = Color(0.5, 0.12, 0.14)
	var fur = Color(0.55, 0.42, 0.3)   # genç maymun kürkü
	var b = MB.new()
	# kaplan deseni: tırtıklı yatay koyu bantlar
	var robe_fn = func(tt: float, a: float, d: Vector3) -> Color:
		if not king:
			return Color(0.35, 0.42, 0.3) if absf(d.x) > 0.25 or d.z > 0.0 else fur
		# önde V yaka: omuzdan kuşağa çapraz inen krem şerit, içinde üst göğüste file iç gömlek
		if d.z < -0.15:
			var lx = 0.05 + clampf(tt, 0.0, 1.0) * 0.36   # yakanın bu yükseklikteki yanal konumu (kuşakta ortada birleşir)
			var ax = absf(d.x)
			if absf(ax - lx) < 0.11:
				return cream
			if ax < lx - 0.085 and tt > 0.5:
				return Color(0.62, 0.62, 0.64) if (int(tt * 40.0) + int((d.x + 2.0) * 22.0)) % 2 == 0 else Color(0.4, 0.4, 0.43)
		var ph = fposmod(tt * 11.0 + sin(a * 4.0 + tt * 7.0) * 0.1, 1.0)
		return Color(0.12, 0.1, 0.08) if ph < 0.3 else tiger
	# gövde (kambur, göğüs geniş): kalçadan omza
	var bw = 1.0 if king else 0.85
	Loft.tube(b, [Vector3(0, h * 0.42, h * 0.03), Vector3(0, h * 0.55, 0.0), Vector3(0, h * 0.68, -h * 0.02), Vector3(0, h * 0.77, -h * 0.01)],
		[Vector2(0.2, 0.15) * h * bw, Vector2(0.24, 0.17) * h * bw, Vector2(0.28, 0.19) * h * bw, Vector2(0.22, 0.16) * h * bw], tiger, 32, 12, true, true, robe_fn)
	# haori eteği (kalçadan dize, önü açık)
	Loft.tube(b, [Vector3(0, h * 0.46, h * 0.02), Vector3(0, h * 0.36, h * 0.03), Vector3(0, h * 0.27, h * 0.03)],
		[Vector2(0.22, 0.17) * h * bw, Vector2(0.24, 0.18) * h * bw, Vector2(0.25, 0.19) * h * bw], tiger, 32, 8, false, false, robe_fn)
	# kuşak
	Loft.tube(b, [Vector3(-0.001, h * 0.45, h * 0.02), Vector3(0.001, h * 0.45, h * 0.02)], [Vector2(0.215, 0.165) * h * bw, Vector2(0.215, 0.165) * h * bw], sash if king else Color(0.3, 0.25, 0.2), 18, 1, false, false)
	if king:
		b.add("box", Vector3(h * 0.05, h * 0.4, -h * 0.17), Vector3(h * 0.06, h * 0.12, h * 0.03), sash.darkened(0.1), Vector3(0, 0, 10))   # kuşak düğümü sarkan uçlar
		b.add("box", Vector3(-h * 0.03, h * 0.39, -h * 0.17), Vector3(h * 0.05, h * 0.14, h * 0.03), sash, Vector3(0, 0, -8))
	# bacaklar: koyu pantolon, kısa ve hafif bükük; maymun ayakları
	for sx in [-1.0, 1.0]:
		Loft.tube(b, [Vector3(h * 0.1 * sx, h * 0.4, 0), Vector3(h * 0.12 * sx, h * 0.22, -h * 0.04), Vector3(h * 0.11 * sx, h * 0.05, 0.0)],
			[h * 0.085 * bw, h * 0.07 * bw, h * 0.055 * bw], pants, 10, 3)
		b.add("sphere", Vector3(h * 0.11 * sx, h * 0.025, -h * 0.05), Vector3(0.11, 0.05, 0.18) * h, skin, Vector3.ZERO, 8)
		for k in 3:   # ayak parmakları
			b.add("sphere", Vector3(h * (0.11 + (k - 1) * 0.03) * sx, h * 0.02, -h * 0.14), Vector3(0.03, 0.03, 0.05) * h, skin.darkened(0.1), Vector3.ZERO, 6)
	if king:
		# omuzlarda ve sırtta kabarık krem kürk (yaka); önde göğse inmez — orada V yaka şeridi var
		for k in 14:
			var aa = lerpf(-2.2, 2.2, k / 13.0) + PI   # arkadan iki yana
			var q = Vector3(sin(aa) * h * 0.22, h * 0.765, cos(aa) * h * 0.14)
			b.add("sphere", q, Vector3(0.16, 0.11, 0.13) * h, cream if k % 2 else cream.lightened(0.05), Vector3(0, rad_to_deg(aa), 0), 8)
		for sx in [-1.0, 1.0]:
			b.add("sphere", Vector3(h * 0.25 * sx, h * 0.74, -h * 0.03), Vector3(0.14, 0.13, 0.16) * h, cream, Vector3.ZERO, 8)   # omuz kürkü
	# baş: yüz öne eğik, çıkık ağız
	var hc = Vector3(0, h * 0.86, -h * 0.07)
	b.add("sphere", hc, Vector3(0.26, 0.27, 0.25) * h, skin, Vector3.ZERO, 14)
	b.add("sphere", hc + Vector3(0, -h * 0.02, -h * 0.09), Vector3(0.23, 0.21, 0.11) * h, face, Vector3.ZERO, 12)   # yüz maskesi
	b.add("sphere", hc + Vector3(0, -h * 0.055, -h * 0.12), Vector3(0.13, 0.09, 0.1) * h, face.lightened(0.05), Vector3.ZERO, 12)   # ağız çıkıntısı
	b.add("box", hc + Vector3(0, -h * 0.07, -h * 0.17), Vector3(h * 0.06, h * 0.006, h * 0.01), Color(0.15, 0.1, 0.1), Vector3(0, 0, 0))   # ağız çizgisi
	for sx in [-1.0, 1.0]:
		b.add("sphere", hc + Vector3(h * 0.022 * sx, -h * 0.03, -h * 0.165), Vector3(0.012, 0.008, 0.008) * h, Color(0.15, 0.1, 0.1), Vector3.ZERO, 6)   # burun delikleri
		var ep = hc + Vector3(h * 0.048 * sx, h * 0.02, -h * 0.13)
		b.add("sphere", ep, Vector3(0.05, 0.04, 0.025) * h, Color(0.92, 0.9, 0.82), Vector3.ZERO, 8)   # açık renk göz
		b.add("sphere", ep + Vector3(0, 0, -h * 0.01), Vector3(0.015, 0.015, 0.01) * h, Color(0.1, 0.08, 0.06), Vector3.ZERO, 6)
		BeastModels._brow(b, ep + Vector3(0, h * 0.01, h * 0.005), sx, h * 0.04, skin.darkened(0.25))   # ağır kaş
		b.add("sphere", hc + Vector3(h * 0.115 * sx, 0.0, -h * 0.01), Vector3(0.04, 0.06, 0.03) * h, face, Vector3.ZERO, 8)   # kulak
	if king:
		# alın bandı + metal plaka
		Loft.tube(b, [hc + Vector3(-0.001, h * 0.07, 0), hc + Vector3(0.001, h * 0.07, 0)], [Vector2(0.122, 0.122) * h, Vector2(0.122, 0.122) * h], Color(0.15, 0.15, 0.17), 18, 1, false, false)
		b.add("box", hc + Vector3(0, h * 0.072, -h * 0.12), Vector3(h * 0.1, h * 0.045, h * 0.012), Color(0.7, 0.72, 0.76))
		# gür beyaz yele: başın arkasında hacim + her yöne (yukarı, yanlara, geriye) yelpaze gibi açılan dikenler
		b.add("sphere", hc + Vector3(0, h * 0.06, h * 0.05), Vector3(0.3, 0.26, 0.26) * h, white, Vector3.ZERO, 12)
		for k in 34:
			var aa = lerpf(-PI * 0.95, PI * 0.95, fposmod(k * 0.618, 1.0))   # yüzün önü hariç her yön
			var up = fposmod(k * 0.37, 1.0)
			var dir = Vector3(sin(aa) * 1.1, 0.1 + up * 0.55, cos(aa) * 0.5 + 0.45).normalized()   # yanlara ve geriye açılan yele
			BeastRig.claw(b, hc + Vector3(sin(aa) * h * 0.1, h * 0.05 + up * h * 0.05, h * 0.04 + cos(aa) * h * 0.06), dir, h * (0.17 + up * 0.1), h * 0.05, white)
		# gür uzun sakal: yanaklardan çeneye geniş hacim, göğse inen sivri tutamlar
		b.add("sphere", hc + Vector3(0, -h * 0.1, -h * 0.08), Vector3(0.24, 0.16, 0.12) * h, white, Vector3.ZERO, 12)
		b.add("sphere", hc + Vector3(0, -h * 0.2, -h * 0.13), Vector3(0.2, 0.3, 0.09) * h, white, Vector3(-12, 0, 0), 12)   # göğse inen sakal hacmi
		for sx in [-1.0, 1.0]:
			b.add("sphere", hc + Vector3(h * 0.1 * sx, -h * 0.03, -h * 0.05), Vector3(0.08, 0.16, 0.1) * h, white, Vector3(0, 0, 15 * sx), 10)   # yanak favorisi
		for k in 15:
			var u = (k - 7) / 7.0
			var st = hc + Vector3(u * h * 0.1, -h * 0.25, -h * 0.15 + absf(u) * h * 0.03)
			BeastRig.claw(b, st, Vector3(u * 0.15, -1.0, -0.2).normalized(), h * (0.16 - absf(u) * 0.06), h * 0.05, white)
	_mesh(out["root"], b)
	# kollar (salınan pivotlar): koyu yeşil kol, önkolda file, beyaz kürk bilek, iri gri el
	for sx in [-1.0, 1.0]:
		var pv = _pivot(out["root"], Vector3(h * 0.27 * sx * bw, h * 0.72, -h * 0.01))
		var ab = MB.new()
		var arm_c = sleeve if king else fur
		Loft.tube(ab, [Vector3.ZERO, Vector3(h * 0.05 * sx, -h * 0.17, -h * 0.02), Vector3(h * 0.05 * sx, -h * 0.3, -h * 0.05)], [h * 0.085 * bw, h * 0.07 * bw, h * 0.06 * bw], arm_c, 10, 3)
		Loft.tube(ab, [Vector3(h * 0.05 * sx, -h * 0.3, -h * 0.05), Vector3(h * 0.04 * sx, -h * 0.44, -h * 0.08)], [h * 0.06 * bw, h * 0.05 * bw], Color(0.42, 0.42, 0.45) if king else fur, 10, 2, false, false,
			func(tt: float, a: float, _d: Vector3) -> Color: return (Color(0.55, 0.55, 0.58) if (int(tt * 8.0) + int((a + 4.0) * 5.0)) % 2 == 0 else Color(0.35, 0.35, 0.38)) if king else fur)
		if king:
			for k in 7:   # beyaz kürk bilek
				var aa = TAU * k / 7.0
				ab.add("sphere", Vector3(h * 0.04 * sx + cos(aa) * h * 0.045, -h * 0.45, -h * 0.08 + sin(aa) * h * 0.045), Vector3(0.05, 0.05, 0.05) * h, white, Vector3.ZERO, 6)
		ab.add("sphere", Vector3(h * 0.04 * sx, -h * 0.52, -h * 0.09), Vector3(0.09, 0.11, 0.08) * h, skin, Vector3.ZERO, 8)   # el
		_mesh(pv, ab)
		out["legs"].append(pv)
	if not king:   # genç maymunun kuyruğu
		var tail = _pivot(out["root"], Vector3(0, h * 0.35, h * 0.18))
		var tb = MB.new()
		Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.1, h * 0.25), Vector3(0, h * 0.35, h * 0.4), Vector3(0, h * 0.55, h * 0.3)], [h * 0.04, h * 0.035, h * 0.03, h * 0.015], fur, 8, 3)
		_mesh(tail, tb)
		out["tail"] = tail
	out["mouth"] = hc + Vector3(0, -h * 0.06, -h * 0.17)


## Karga sürüsü (REFERANS: genjutsu kargaları): koyu arduvaz-siyah gövde, iri kalın hafif kıvrık siyah gaga, kırmızı göz;
## açık süzülen kanatlar (ayrık uç tüyleri), kama kuyruk. Sürüde boyları ve kanat açıları hafif farklı.
static func _crows(out: Dictionary, h: float) -> void:
	out["anim"] = "flock"
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	var body_c = Color(0.27, 0.27, 0.31)   # arduvaz grisi (simsiyah değil)
	var wing_c = Color(0.2, 0.2, 0.24)
	var beak_c = Color(0.07, 0.07, 0.08)
	for k in 11:
		var n = Node3D.new()
		n.position = Vector3(rng.randf_range(-2.4, 2.4), rng.randf_range(1.0, 3.2), rng.randf_range(-2.4, 2.4))
		out["root"].add_child(n)
		var s = rng.randf_range(0.42, 0.58)   # gövde boyu (m)
		var b = MB.new()
		Loft.tube(b, [Vector3(0, 0, s * 0.55), Vector3(0, s * 0.02, s * 0.15), Vector3(0, s * 0.05, -s * 0.2), Vector3(0, s * 0.12, -s * 0.42)],
			[Vector2(0.05, 0.03) * s, Vector2(0.17, 0.16) * s, Vector2(0.19, 0.18) * s, Vector2(0.13, 0.13) * s], body_c, 12, 3, true, false)
		var hc = Vector3(0, s * 0.16, -s * 0.5)
		b.add("sphere", hc, Vector3(0.26, 0.24, 0.3) * s, body_c, Vector3.ZERO, 10)
		# iri kalın gaga: kökte yüksek, uca doğru incelip hafif aşağı kıvrılır
		Loft.tube(b, [hc + Vector3(0, 0.0, -s * 0.1), hc + Vector3(0, -s * 0.01, -s * 0.24), hc + Vector3(0, -s * 0.05, -s * 0.36)],
			[Vector2(0.095, 0.11) * s, Vector2(0.06, 0.07) * s, Vector2(0.006, 0.006) * s], beak_c, 8, 3, true, true)
		for sx in [-1.0, 1.0]:
			b.add("sphere", hc + Vector3(s * 0.1 * sx, s * 0.04, -s * 0.06), Vector3(0.05, 0.05, 0.035) * s, Color(0.05, 0.05, 0.06), Vector3.ZERO, 6)   # siyah boncuk göz (Sharingan değil)
		# kama kuyruk
		b.add_slab(PackedVector2Array([Vector2(-s * 0.06, 0.0), Vector2(s * 0.06, 0.0), Vector2(s * 0.12, s * 0.38), Vector2(0.0, s * 0.44), Vector2(-s * 0.12, s * 0.38)]), s * 0.02, wing_c,
			Transform3D(Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)), Vector3(0, s * 0.01, s * 0.45)))
		# açık kanatlar: V açılı profil + uçta dört ayrık tüy
		var W = s * rng.randf_range(1.0, 1.2)
		var dih = rng.randf_range(8.0, 24.0)
		for sx in [-1.0, 1.0]:
			var xf = Transform3D(Basis(Vector3(0, 0, 1), sx * deg_to_rad(dih)) * Basis(Vector3(0, -sx, 0), Vector3(sx, 0, 0), Vector3(0, 0, 1)), Vector3(s * 0.12 * sx, s * 0.08, -s * 0.1))
			b.add_slab(PackedVector2Array([Vector2(0, -s * 0.1), Vector2(W * 0.5, -s * 0.13), Vector2(W * 0.78, -s * 0.05), Vector2(W * 0.78, s * 0.14), Vector2(W * 0.45, s * 0.3), Vector2(0, s * 0.32)]), s * 0.025, wing_c, xf)
			for f in 4:
				var base = Vector2(W * 0.72, -s * 0.03 + f * s * 0.05)
				var ang = deg_to_rad(-5.0 + f * 14.0)
				var dv = Vector2(cos(ang), sin(ang))
				var nv = Vector2(-dv.y, dv.x)
				var fl = s * (0.42 - f * 0.04)
				b.add_slab(PackedVector2Array([base - nv * s * 0.035, base + dv * fl - nv * s * 0.015, base + dv * fl * 1.05, base + dv * fl + nv * s * 0.015, base + nv * s * 0.035]), s * 0.015, wing_c.darkened(0.2), xf)
		_mesh(n, b)
		out["segments"].append(n)


# ------------------------------------------------------------------ semender
## Semender (REFERANS: dev zehirli semender): dev, alçak, uzun gövde; çok geniş yassı baş, tepede minik gözler, kafanın çevresini
## dolanan çok geniş ağız (açık dudak çizgisi); gri-lavanta siğilli sırt, açık renk alt; kısa kalın bacaklar ve yayık parmaklar;
## kalın uzun kuyruk. Sırtta zehir sisi bezi.
static func _salamander(out: Dictionary, h: float, length: float) -> void:
	out["anim"] = "walk"
	var back = Color(0.5, 0.48, 0.57)
	var belly = Color(0.74, 0.72, 0.76)
	var wart = Color(0.38, 0.36, 0.44)
	var L = length * 0.62   # gövde + baş (kuyruk ayrı)
	var b = MB.new()
	var fn = func(tt: float, a: float, d: Vector3) -> Color:
		return belly if d.y < -0.3 else back
	# gövde: arkadan (kuyruk kökü) öne; baş geniş ve yassı
	# ön kısım yukarı kalkık (baş ön bacakların üstünde yükselir)
	Loft.tube(b, [Vector3(0, h * 0.45, L * 0.5), Vector3(0, h * 0.55, L * 0.25), Vector3(0, h * 0.65, 0.0), Vector3(0, h * 0.82, -L * 0.22), Vector3(0, h * 0.95, -L * 0.38), Vector3(0, h * 0.95, -L * 0.5)],
		[Vector2(0.55, 0.36) * h, Vector2(0.7, 0.44) * h, Vector2(0.74, 0.47) * h, Vector2(0.78, 0.46) * h, Vector2(0.82, 0.42) * h, Vector2(0.72, 0.32) * h], back, 24, 6, false, true, fn)   # animedeki gibi yassı, şişman değil
	# geniş ağız çizgisi: başın ön ve yanlarını dolanan açık dudak bandı + koyu yarık
	var mz = -L * 0.38
	for k in 15:
		var u = (k - 7) / 7.0
		var px = u * h * 1.05
		var pz = -L * 0.56 + absf(u) * absf(u) * L * 0.2
		b.add("sphere", Vector3(px, h * 0.72, pz), Vector3(h * 0.32, h * 0.22, h * 0.28), belly.lightened(0.08), Vector3(0, -u * 50.0, 0), 8)   # kalın açık dudak bandı
		b.add("box", Vector3(px, h * 0.8, pz - h * 0.08), Vector3(h * 0.26, h * 0.04, h * 0.06), Color(0.22, 0.16, 0.2), Vector3(0, -u * 50.0, 0))   # ağız yarığı
	# minik gözler tepede, öne-yana
	for sx in [-1.0, 1.0]:
		var ep = Vector3(h * 0.55 * sx, h * 1.38, -L * 0.42)
		b.add("sphere", ep, Vector3(0.3, 0.22, 0.28) * h, back.lightened(0.08), Vector3.ZERO, 10)   # göz tümseği
		b.add("sphere", ep + Vector3(h * 0.06 * sx, h * 0.07, -h * 0.07), Vector3(0.12, 0.1, 0.1) * h, Color(0.12, 0.1, 0.1), Vector3.ZERO, 8)
	# siğiller: sırtta ve başta düzensiz tümsekler
	var rng = RandomNumberGenerator.new()
	rng.seed = 5
	for i in 46:
		var z = rng.randf_range(-0.45, 0.48) * L
		var a = rng.randf_range(-1.2, 1.2)
		var rr = h * 0.9
		var cy = lerpf(h * 0.55, h * 0.9, clampf(-z / (L * 0.5), 0.0, 1.0))
		b.add("sphere", Vector3(sin(a) * rr * 0.95, cy + cos(a) * h * 0.55, z), Vector3.ONE * h * rng.randf_range(0.07, 0.15), wart if i % 3 else back.darkened(0.1), Vector3.ZERO, 6)
	b.add("sphere", Vector3(0, h * 1.28, L * 0.0), Vector3(0.35, 0.18, 0.5) * h, Color(0.55, 0.38, 0.6), Vector3.ZERO, 10)   # zehir sisi bezi
	_mesh(out["root"], b)
	# kalın uzun kuyruk (yanlardan basık)
	var tail = _pivot(out["root"], Vector3(0, h * 0.42, L * 0.48))
	var tb = MB.new()
	Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.0, length * 0.15), Vector3(0, -h * 0.05, length * 0.3), Vector3(0, -h * 0.12, length * 0.42)],
		[Vector2(0.6, 0.4) * h, Vector2(0.42, 0.36) * h, Vector2(0.24, 0.25) * h, Vector2(0.03, 0.05) * h], back, 14, 4, false, true, fn)
	_mesh(tail, tb)
	out["tail"] = tail
	# kısa kalın bacaklar, yana açık, yayık parmaklar
	for p in [Vector3(-1, 0, -0.26), Vector3(1, 0, -0.26), Vector3(-1, 0, 0.3), Vector3(1, 0, 0.3)]:
		var sx = p.x
		var front = p.z < 0.0
		var hy = h * (0.75 if front else 0.42)
		var pv = _pivot(out["root"], Vector3(sx * h * 0.85, hy, p.z * L))
		var lb = MB.new()
		# ön bacaklar uzun ve dik (kalkık gövdeyi taşır), arka bacaklar kısa ve yana açık
		Loft.tube(lb, [Vector3.ZERO, Vector3(sx * h * 0.3, -hy * 0.4, -h * 0.05), Vector3(sx * h * 0.45, -hy + h * 0.02, -h * 0.05)], [h * 0.28, h * 0.22, h * 0.17], back, 10, 3)
		for t in 5:
			var aa = deg_to_rad(-60.0 + t * 30.0)
			var dirt = Vector3(sin(aa) * sx * 0.6 + sx * 0.3, 0, -cos(aa)).normalized()
			Loft.tube(lb, [Vector3(sx * h * 0.45, -hy + h * 0.02, -h * 0.05), Vector3(sx * h * 0.45, -hy, -h * 0.05) + dirt * h * 0.3], [h * 0.08, h * 0.05], belly.darkened(0.1), 6, 2, false, true)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.8, -L * 0.58)



## Kaplumbağalar (REFERANS): dev ada kaplumbağası — kabuğu orman gibi sık, uzun sivri dikenlerle kaplı gri-yeşil kubbe, yosun lekeleri,
## yaşlı buruşuk uykulu baş, kürek bacaklar; küçük ninja kaplumbağası — kırmızı kabuk, altın sarmal desenler ve altın kenar, kırmızı pullu deri,
## çatık sarı gözler, alnında plakalı mavi bant, kolunda turuncu bant, beyaz pençeler.
static func _turtle(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "walk"
	var giant = model == "turtle_giant"
	if length <= 0.0 or not giant:
		length = h * 1.7
	var L = length
	var shell = Color(0.42, 0.5, 0.4) if giant else Color(0.58, 0.24, 0.28)   # bordo (parlak kırmızı değil)
	var rim = Color(0.5, 0.56, 0.6) if giant else Color(0.92, 0.72, 0.25)
	var skin = Color(0.58, 0.62, 0.55) if giant else Color(0.66, 0.3, 0.33)
	var dark = Color(0.32, 0.36, 0.3) if giant else Color(0.36, 0.12, 0.14)
	var b = MB.new()
	# kabuk kubbesi + kenar halkası + karın plakası
	var sh = h * (0.95 if giant else 0.85)
	b.add("hemi", Vector3(0, h * 0.35, 0), Vector3(L * 0.95, sh * 1.9, L), shell, Vector3.ZERO, 22)
	b.add("cyl", Vector3(0, h * 0.35, 0), Vector3(L * 1.0, h * 0.14, L * 1.06), rim, Vector3.ZERO, 22)
	b.add("sphere", Vector3(0, h * 0.3, 0), Vector3(L * 0.9, h * 0.25, L * 0.98), rim.darkened(0.15), Vector3.ZERO, 16)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	if giant:
		# sık sivri dikenler: kubbe yüzeyinde, dışa ve yukarı; arada yosun lekeleri
		for i in 230:
			var a = rng.randf() * TAU
			var r = sqrt(rng.randf()) * 0.95
			var nx = cos(a) * r
			var nz = sin(a) * r
			var ny = sqrt(maxf(0.0, 1.0 - r * r))
			var p = Vector3(nx * L * 0.475, h * 0.35 + ny * sh * 0.95, nz * L * 0.5)
			var dir = Vector3(nx * 0.55, 1.0, nz * 0.55).normalized()
			var ln = h * rng.randf_range(0.35, 0.8) * (0.6 + ny * 0.6)
			BeastRig.claw(b, p, dir, ln, h * rng.randf_range(0.05, 0.09), Color(0.74, 0.78, 0.68).lerp(Color(0.42, 0.55, 0.4), rng.randf()))
			if i % 2 == 0:
				b.add("sphere", p + Vector3(0, h * 0.03, 0), Vector3(0.22, 0.08, 0.22) * h * rng.randf_range(0.8, 1.5), Color(0.25, 0.45, 0.22), Vector3.ZERO, 6)   # yosun
	else:
		# kabuk plakası dikişleri (koyu meridyenler + halka) ve yüzeye oturan iri altın sarmallar
		var surf = func(r: float, a: float) -> Vector3:
			return Vector3(cos(a) * r * L * 0.475, h * 0.35 + sqrt(maxf(0.0, 1.0 - r * r)) * sh * 0.95, sin(a) * r * L * 0.5)
		for i in 6:
			var a = TAU * i / 6.0 + 0.5
			for k in 8:
				var r = 0.15 + k * 0.1
				b.add("sphere", surf.call(r, a), Vector3(0.035, 0.035, 0.035) * h * 1.6, dark, Vector3.ZERO, 5)
		for k in 18:
			b.add("sphere", surf.call(0.45, TAU * k / 18.0), Vector3(0.035, 0.035, 0.035) * h * 1.6, dark, Vector3.ZERO, 5)
		for i in 6:
			var a = TAU * i / 6.0
			var c0 = 0.66
			for k in 14:   # sarmal: merkezden dışa açılan altın nokta dizisi (kabuk yüzeyinde)
				var t = k / 13.0
				var aa = t * TAU * 1.4
				var q = Vector2(cos(a) * c0, sin(a) * c0) + Vector2(cos(aa), sin(aa)) * t * 0.17
				b.add("sphere", surf.call(minf(0.97, q.length()), atan2(q.y, q.x)), Vector3(0.08, 0.04, 0.08) * h, rim, Vector3.ZERO, 6)
		for k in 14:
			var t = k / 13.0
			var aa = t * TAU * 1.4
			b.add("sphere", surf.call(t * 0.17, aa), Vector3(0.08, 0.04, 0.08) * h, rim, Vector3.ZERO, 6)
	_mesh(out["root"], b)
	# baş: dev olanı yaşlı ve uykulu, küçüğü çatık kaşlı ve alın bantlı
	var head = _pivot(out["root"], Vector3(0, h * 0.42, -L * (0.52 if giant else 0.46)))
	var hb = MB.new()
	var hc = Vector3(0, h * 0.08, -h * 0.5)
	if giant:
		Loft.tube(hb, [Vector3(0, -h * 0.05, L * 0.08), Vector3(0, h * 0.0, -h * 0.15), Vector3(0, h * 0.06, -h * 0.4)], [h * 0.22, h * 0.2, h * 0.18], skin, 12, 3, false, false)
	else:
		# Kame: kısa kalın boyun, baş kabuğun hemen önünde (uzun boyun tuhaf duruyordu)
		Loft.tube(hb, [Vector3(0, -h * 0.04, h * 0.06), Vector3(0, h * 0.0, -h * 0.06), Vector3(0, h * 0.03, -h * 0.14)], [h * 0.25, h * 0.24, h * 0.22], skin, 12, 3, false, false)
		hc = Vector3(0, h * 0.06, -h * 0.26)
	hb.add("sphere", hc, Vector3(0.42, 0.34, 0.48) * h, skin, Vector3.ZERO, 14)
	hb.add("sphere", hc + Vector3(0, -h * 0.07, -h * 0.12), Vector3(0.34, 0.16, 0.3) * h, skin.lightened(0.12), Vector3.ZERO, 10)   # ağız/çene
	hb.add("box", hc + Vector3(0, -h * 0.05, -h * 0.25), Vector3(h * 0.22, h * 0.012, h * 0.03), Color(0.15, 0.1, 0.1))   # ağız çizgisi
	for sx in [-1.0, 1.0]:
		var ep = hc + Vector3(h * 0.13 * sx, h * 0.07, -h * 0.17)
		if giant:
			hb.add("sphere", ep, Vector3(0.1, 0.05, 0.06) * h, skin.darkened(0.2), Vector3.ZERO, 8)   # uykulu kapalı göz
			hb.add("box", ep + Vector3(0, h * 0.02, -h * 0.02), Vector3(h * 0.12, h * 0.012, h * 0.03), dark, Vector3(0, 0, -8 * sx))
			for w in 3:   # buruşukluk
				hb.add("box", hc + Vector3(h * 0.16 * sx, -h * 0.02 - w * h * 0.04, -h * 0.05), Vector3(h * 0.02, h * 0.012, h * 0.1), dark, Vector3(0, 0, 20 * sx))
		else:
			hb.add("sphere", ep, Vector3(0.09, 0.07, 0.05) * h, Color(0.95, 0.8, 0.25), Vector3.ZERO, 8)
			hb.add("sphere", ep + Vector3(0, 0, -h * 0.02), Vector3(0.03, 0.04, 0.02) * h, Color(0.1, 0.05, 0.05), Vector3.ZERO, 6)
			hb.add("box", ep + Vector3(-h * 0.01 * sx, h * 0.06, 0), Vector3(h * 0.12, h * 0.025, h * 0.03), Color(0.95, 0.75, 0.2), Vector3(0, 0, 20 * sx))   # çatık kaş
	if not giant:
		Loft.tube(hb, [hc + Vector3(-0.001, h * 0.12, 0), hc + Vector3(0.001, h * 0.12, 0)], [Vector2(0.215, 0.245) * h, Vector2(0.215, 0.245) * h], Color(0.15, 0.25, 0.55), 14, 1, false, false)   # alın bandı
		hb.add("box", hc + Vector3(0, h * 0.12, -h * 0.25), Vector3(h * 0.16, h * 0.07, h * 0.02), Color(0.72, 0.74, 0.78))
	# pul deseni
	for i in 14:
		var aa = rng.randf() * TAU
		hb.add("sphere", hc + Vector3(cos(aa) * h * 0.2, h * 0.05 + sin(aa) * h * 0.12, rng.randf_range(-0.1, 0.15) * h), Vector3.ONE * h * 0.05, dark, Vector3.ZERO, 5)
	_mesh(head, hb)
	if not giant:
		head.scale = Vector3.ONE * 1.35   # küçük ninja kaplumbağasının başı iri (yüzüyle birlikte büyür)
	out["head"] = head
	# bacaklar: dev — kürek; küçük — kısa kalın, beyaz pençe
	for p in [Vector3(-1, 0, -0.32), Vector3(1, 0, -0.32), Vector3(-1, 0, 0.3), Vector3(1, 0, 0.3)]:
		var sx = p.x
		var pv = _pivot(out["root"], Vector3(sx * L * 0.42, h * 0.32, p.z * L))
		var lb = MB.new()
		if giant:
			Loft.tube(lb, [Vector3.ZERO, Vector3(sx * h * 0.25, -h * 0.12, -h * 0.05), Vector3(sx * h * 0.35, -h * 0.3, -h * 0.1)], [Vector2(0.26, 0.2) * h, Vector2(0.3, 0.14) * h, Vector2(0.24, 0.1) * h], skin, 10, 3)
		else:
			Loft.tube(lb, [Vector3.ZERO, Vector3(sx * h * 0.12, -h * 0.15, 0), Vector3(sx * h * 0.15, -h * 0.3, -h * 0.02)], [h * 0.14, h * 0.12, h * 0.11], skin, 10, 3)
			for c in 3:
				lb.add("cone", Vector3(sx * h * 0.15 + (c - 1) * h * 0.05, -h * 0.31, -h * 0.12), Vector3(0.035, 0.07, 0.035) * h, Color(0.96, 0.95, 0.9), Vector3(-90, 0, 0), 5)
			if p.z < 0.0 and sx > 0.0:
				Loft.tube(lb, [Vector3(sx * h * 0.12 - 0.001, -h * 0.13, 0), Vector3(sx * h * 0.12 + 0.001, -h * 0.13, 0)], [h * 0.135, h * 0.135], Color(0.95, 0.5, 0.15), 10, 1, false, false)   # turuncu kol bandı
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.42, -L * 0.52) + hc + Vector3(0, -h * 0.05, -h * 0.25)




## Dev örümcek (REFERANS): kömür siyahı tüylü gövde, iri oval karın; karnın iki yanında ve ortasında turuncu alev/kaplan çizgileri;
## kafa göğüste iki sıra kırmızı göz (ön dört iri), iki kısa kalın çene dişi (keliser); sekiz uzun eklemli tüylü bacak,
## ucunda kıvrık gümüş-beyaz pençe. Bacaklar dirsekten yukarı kalkıp yere iner.
static func _spider(out: Dictionary, h: float) -> void:
	out["anim"] = "spider"
	var c = Color(0.16, 0.16, 0.19)
	var orange = Color(0.92, 0.5, 0.18)
	var claw_c = Color(0.85, 0.87, 0.9)
	var b = MB.new()
	# karın: iri oval, arkada; turuncu alev çizgileri
	var abd_fn = func(tt: float, a: float, d: Vector3) -> Color:
		# karnın üstünde iki uzun turuncu bant (kenarları alev gibi tırtıklı), ortası siyah
		var side = absf(d.x)
		var jag = sin(tt * 22.0) * 0.035 + sin(tt * 9.0 + 1.0) * 0.03
		if d.y > -0.25 and side > 0.3 + jag and side < 0.72 + jag * 0.4 and tt > 0.08 and tt < 0.94:
			return orange
		return c
	Loft.tube(b, [Vector3(0, h * 0.52, h * 0.05), Vector3(0, h * 0.62, h * 0.35), Vector3(0, h * 0.64, h * 0.75), Vector3(0, h * 0.52, h * 1.05), Vector3(0, h * 0.42, h * 1.15)],
		[Vector2(0.18, 0.16) * h, Vector2(0.48, 0.42) * h, Vector2(0.55, 0.46) * h, Vector2(0.36, 0.32) * h, Vector2(0.06, 0.06) * h], c, 22, 8, true, true, abd_fn)
	# göğüs (sefalotoraks) + kafa
	Loft.tube(b, [Vector3(0, h * 0.5, h * 0.05), Vector3(0, h * 0.52, -h * 0.22), Vector3(0, h * 0.48, -h * 0.48)],
		[Vector2(0.3, 0.22) * h, Vector2(0.34, 0.26) * h, Vector2(0.24, 0.2) * h], c.lightened(0.04), 18, 4, true, true)
	# kırmızı gözler: ön sırada dört iri, arkada iki küçük
	for k in 4:
		var x = (k - 1.5) * h * 0.1
		b.add("sphere", Vector3(x, h * 0.62 + absf(k - 1.5) * h * 0.0, -h * 0.5), Vector3.ONE * h * (0.08 if k in [1, 2] else 0.06), Color(0.9, 0.08, 0.1), Vector3.ZERO, 8)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * h * 0.08, h * 0.7, -h * 0.42), Vector3.ONE * h * 0.05, Color(0.9, 0.08, 0.1), Vector3.ZERO, 6)
		# keliserler: aşağı-öne kalın çene dişleri, uçta gümüş
		Loft.tube(b, [Vector3(sx * h * 0.07, h * 0.48, -h * 0.58), Vector3(sx * h * 0.08, h * 0.36, -h * 0.66), Vector3(sx * h * 0.05, h * 0.26, -h * 0.64)], [h * 0.06, h * 0.045, h * 0.02], [c, c, claw_c], 8, 2, true, true)
	# tüy dokusu: gövdede kısa diken tutamları
	var rng = RandomNumberGenerator.new()
	rng.seed = 9
	for i in 60:
		var t = rng.randf()
		var a = rng.randf_range(-1.6, 1.6)
		var z = lerpf(h * 0.1, h * 1.05, t)
		var r = h * (0.18 + sin(t * PI) * 0.36)
		var p = Vector3(sin(a) * r, h * 0.58 + cos(a) * r * 0.85, z)
		BeastRig.claw(b, p, Vector3(sin(a), cos(a), 0.4).normalized(), h * 0.07, h * 0.012, c.darkened(0.2))
	_mesh(out["root"], b)
	# sekiz bacak: göğsün yanlarından; üst bölüm yukarı-dışa, dirsek yüksekte, alt bölüm yere iner, ucunda gümüş pençe
	for i in 8:
		var sx = -1.0 if i < 4 else 1.0
		var k = i % 4
		var pv = _pivot(out["root"], Vector3(h * 0.2 * sx, h * 0.5, -h * 0.4 + k * h * 0.15))
		var lb = MB.new()
		var lc = Color(0.3, 0.3, 0.34)   # bacaklar koyu gri (gövde kömür siyahı)
		var fan = deg_to_rad(-55.0 + k * 35.0)   # ön bacaklar öne, arka bacaklar geriye yayılır
		var out_dir = Vector3(sx * cos(fan), 0, sin(fan)).normalized()
		var knee = out_dir * h * 0.75 + Vector3(0, h * 0.45, 0)
		var foot = out_dir * h * 1.45 + Vector3(0, -h * 0.5, 0)
		Loft.tube(lb, [Vector3.ZERO, knee * 0.5 + Vector3(0, h * 0.05, 0), knee], [h * 0.13, h * 0.13, h * 0.11], lc, 10, 3)
		Loft.tube(lb, [knee, knee.lerp(foot, 0.5) + out_dir * h * 0.05, foot], [h * 0.11, h * 0.09, h * 0.065], lc, 10, 3)
		for f in 14:   # kalın tüy tutamları (iki yana)
			var q = (Vector3.ZERO.lerp(knee, f / 6.0) if f < 7 else knee.lerp(foot, (f - 7) / 7.0))
			var sd = Vector3(0, 1, 0).cross(out_dir).normalized() * (1.0 if f % 2 else -1.0)
			BeastRig.claw(lb, q, (sd + Vector3(0, 0.5, 0) + out_dir * 0.4).normalized(), h * 0.14, h * 0.035, lc.darkened(0.35))
		# iri gümüş orak pençe: ayaktan dışa çıkıp aşağı kıvrılır
		var cmid = foot + out_dir * h * 0.25 + Vector3(0, h * 0.08, 0)
		Loft.tube(lb, [foot, cmid, cmid + out_dir * h * 0.15 + Vector3(0, -h * 0.22, 0)], [h * 0.06, h * 0.045, h * 0.006], claw_c, 8, 4, true, true)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.38, -h * 0.66)


