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
		"toad_small", "toad_mid":
			_toad(out, model, h)
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
		"dog_small", "dog_pack", "wolf_giant":
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
	var bm = BeastModels.beast_material(surf, Color(0.86, 0.86, 0.84) if model.begins_with("slug") else Color(0.3, 0.26, 0.4))
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


# ------------------------------------------------------------------ kurbağalar (kendi modelimiz: geniş basık gövde, iri göz kubbeleri, kocaman ağız, katlanmış arka bacaklar)
static func _toad(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "hop"
	var main_c: Color = {"toad_small": Color(0.35, 0.68, 0.3), "toad_mid": Color(0.88, 0.52, 0.18), "toad_boss": Color(0.78, 0.3, 0.16)}[model]
	var belly = Color(0.97, 0.88, 0.64)
	var wart = main_c.darkened(0.25)
	var root: Node3D = out["root"]
	var W = h * 1.25   # gövde genişliği
	var L = h * 1.35   # gövde boyu
	var by = h * 0.5
	var skin = func(_t: float, a: float, d: Vector3) -> Color:
		if d.y < -0.25:
			return belly
		if sin(a * 5.0 + _t * 9.0) > 0.93:
			return wart
		return main_c.lerp(main_c.lightened(0.12), smoothstep(0.2, 0.9, d.y))
	var b = MB.new()
	# basık, öne doğru alçalan gövde
	Loft.tube(b, [Vector3(0, by + h * 0.02, L * 0.42), Vector3(0, by + h * 0.12, L * 0.12), Vector3(0, by + h * 0.12, -L * 0.18), Vector3(0, by + h * 0.02, -L * 0.42)],
		[Vector2(W * 0.38, h * 0.3), Vector2(W * 0.5, h * 0.44), Vector2(W * 0.5, h * 0.42), Vector2(W * 0.42, h * 0.3)], main_c, 22, 4, true, true, skin)
	# kocaman ağız çizgisi ve dudak
	var mz = -L * 0.46
	b.add("torus", Vector3(0, by - h * 0.02, mz + L * 0.12), Vector3(W * 0.84, h * 0.08, L * 0.36), main_c.darkened(0.35), Vector3.ZERO, 24)
	b.add("sphere", Vector3(0, by - h * 0.12, mz + L * 0.1), Vector3(W * 0.78, h * 0.24, L * 0.3), belly, Vector3.ZERO, 16)   # gırtlak kesesi
	# iri göz kubbeleri + göz kapağı + yatay göz bebeği
	for sx in [-1.0, 1.0]:
		var ec = Vector3(W * 0.28 * sx, by + h * 0.4, -L * 0.24)
		b.add_grad("sphere", ec, Vector3(h * 0.36, h * 0.32, h * 0.36), main_c.lightened(0.08), main_c.darkened(0.1), Vector3.ZERO, 14)
		b.add("sphere", ec + Vector3(0.02 * sx * h, h * 0.02, -h * 0.12), Vector3(h * 0.26, h * 0.24, h * 0.14), Color(1.0, 0.86, 0.3), Vector3.ZERO, 12)
		b.add("box", ec + Vector3(0.02 * sx * h, h * 0.02, -h * 0.19), Vector3(h * 0.16, h * 0.05, h * 0.02), Color(0.05, 0.03, 0.02))
		b.add("sphere", ec + Vector3(0, h * 0.12, -h * 0.05), Vector3(h * 0.3, h * 0.1, h * 0.28), main_c.darkened(0.15), Vector3(-15, 0, 0), 12)   # kaş/kapak
		b.add("sphere", Vector3(W * 0.12 * sx, by + h * 0.12, -L * 0.48), Vector3(h * 0.04, h * 0.03, h * 0.03), Color(0.08, 0.05, 0.04), Vector3.ZERO, 6)   # burun deliği
	# sırtta siğil sırası
	for i in 6:
		for sx in [-1.0, 1.0]:
			b.add("sphere", Vector3(W * (0.12 + 0.08 * (i % 2)) * sx, by + h * 0.44, -L * 0.1 + i * L * 0.09), Vector3.ONE * h * 0.07, wart, Vector3.ZERO, 6)
	_mesh(root, b)
	# ön kollar (kısa, perdeli el) ve katlanmış iri arka bacaklar: pivotlar zıplamada döner
	for side in [-1.0, 1.0]:
		var fa = _pivot(root, Vector3(W * 0.36 * side, by - h * 0.05, -L * 0.3))
		var am = MB.new()
		Loft.tube(am, [Vector3.ZERO, Vector3(W * 0.08 * side, -h * 0.22, -h * 0.08), Vector3(W * 0.1 * side, -by + h * 0.06, -h * 0.14)], [h * 0.12, h * 0.09, h * 0.07], main_c, 12, 3, true, true)
		for f in 4:
			var fd = Vector3((f - 1.5) * 0.35 * side + 0.3 * side, 0, -1).normalized()
			am.add("sphere", Vector3(W * 0.1 * side, -by + h * 0.03, -h * 0.14) + fd * h * 0.16, Vector3(h * 0.07, h * 0.03, h * 0.07), belly, Vector3.ZERO, 6)
		_mesh(fa, am)
		out["legs"].append(fa)
		var hl = _pivot(root, Vector3(W * 0.42 * side, by - h * 0.02, L * 0.3))
		var lm = MB.new()
		var knee = Vector3(W * 0.22 * side, h * 0.08, -h * 0.2)
		var ankle = Vector3(W * 0.12 * side, -by + h * 0.18, h * 0.12)
		Loft.tube(lm, [Vector3.ZERO, knee, ankle, Vector3(W * 0.14 * side, -by + h * 0.04, -h * 0.25)], [h * 0.24, h * 0.17, h * 0.1, h * 0.07], main_c, 14, 3, true, true, skin)
		for f in 4:
			var fd2 = Vector3((f - 1.5) * 0.4, 0, -1).normalized()
			lm.add("sphere", Vector3(W * 0.14 * side, -by + h * 0.03, -h * 0.28) + fd2 * h * 0.18, Vector3(h * 0.08, h * 0.03, h * 0.09), belly, Vector3.ZERO, 6)
		_mesh(hl, lm)
		out["legs"].append(hl)
	out["head"] = root
	var torso = Vector3(0, by + h * 0.1, 0)
	var head = Vector3(0, by + h * 0.3, -L * 0.3)
	match model:
		"toad_small":  # sırtta parşömen
			var s = MB.new()
			Loft.tube(s, [torso + Vector3(-h * 0.35, h * 0.45, h * 0.1), torso + Vector3(h * 0.35, h * 0.45, h * 0.1)], [h * 0.09, h * 0.09], Color(0.9, 0.85, 0.68), 10, 1)
			s.add("cyl", torso + Vector3(0, h * 0.45, h * 0.1), Vector3(h * 0.2, h * 0.25, h * 0.2), Color(0.75, 0.15, 0.12), Vector3(0, 0, 90), 10)
			_mesh(root, s)
		"toad_mid":  # kırmızı atkı + elde kılıç
			var s = MB.new()
			s.add("torus", head + Vector3(0, -h * 0.12, h * 0.25), Vector3(W * 0.7, h * 0.2, h * 0.6), Color(0.78, 0.12, 0.12), Vector3.ZERO, 18)
			Loft.tube(s, [head + Vector3(W * 0.2, -h * 0.15, h * 0.4), head + Vector3(W * 0.32, -h * 0.4, h * 0.7), head + Vector3(W * 0.3, -h * 0.7, h * 0.8)], [Vector2(0.12, 0.03) * h, Vector2(0.1, 0.03) * h, Vector2(0.08, 0.02) * h], Color(0.78, 0.12, 0.12), 8, 2)
			s.add("box", Vector3(W * 0.5, by + h * 0.1, -L * 0.6), Vector3(h * 0.05, h * 0.1, h * 1.2), Color(0.82, 0.84, 0.88), Vector3(-20, 0, 0))
			s.add("cyl", Vector3(W * 0.5, by + h * 0.3, -L * 0.1), Vector3(h * 0.06, h * 0.3, h * 0.06), Color(0.2, 0.12, 0.1), Vector3(70, 0, 0), 8)
			_mesh(root, s)
		"toad_boss":  # mavi yelek, sırtta çapraz kın, pipo, kaşta yara izi
			var v = MB.new()
			var vest = Color(0.18, 0.24, 0.45)
			Loft.tube(v, [torso + Vector3(0, -h * 0.1, L * 0.3), torso + Vector3(0, h * 0.05, 0), torso + Vector3(0, -h * 0.05, -L * 0.25)], [Vector2(W * 0.53, h * 0.47), Vector2(W * 0.55, h * 0.49), Vector2(W * 0.5, h * 0.44)], vest, 22, 2, false, false,
				func(_t: float, a: float, d: Vector3) -> Color: return Color(0.96, 0.86, 0.62) if d.y < -0.45 else vest)
			v.add("cyl", torso + Vector3(0, h * 0.5, h * 0.2), Vector3(h * 0.55, h * 0.04, h * 0.55), Color(0.95, 0.92, 0.85), Vector3.ZERO, 16)
			v.add("box", torso + Vector3(0, h * 0.53, h * 0.2), Vector3(h * 0.05, h * 0.02, h * 0.32), Color(0.1, 0.1, 0.1))
			v.add("box", torso + Vector3(0, h * 0.53, h * 0.15), Vector3(h * 0.24, h * 0.02, h * 0.05), Color(0.1, 0.1, 0.1))
			var k0 = torso + Vector3(-W * 0.4, h * 0.3, L * 0.35); var k1 = torso + Vector3(W * 0.35, h * 0.75, -L * 0.15)
			Loft.tube(v, [k0, k1], [Vector2(0.09, 0.05) * h, Vector2(0.08, 0.05) * h], Color(0.14, 0.09, 0.07), 8, 1)
			var hd = k1 + (k1 - k0).normalized() * h * 0.45
			Loft.tube(v, [k1, hd], [h * 0.05, h * 0.05], Color(0.62, 0.12, 0.1), 8, 1)
			v.add("cyl", k1, Vector3(h * 0.22, h * 0.03, h * 0.22), Color(0.78, 0.65, 0.25), Vector3(40, 0, -45), 12)
			Loft.tube(v, [Vector3(W * 0.3, by - h * 0.02, -L * 0.45), Vector3(W * 0.55, by + h * 0.05, -L * 0.75)], [h * 0.035, h * 0.035], Color(0.3, 0.2, 0.12), 8, 1)   # pipo
			v.add("cyl", Vector3(W * 0.57, by + h * 0.12, -L * 0.78), Vector3(h * 0.12, h * 0.16, h * 0.12), Color(0.3, 0.2, 0.12), Vector3.ZERO, 10)
			v.add("box", Vector3(-W * 0.28, by + h * 0.55, -L * 0.3), Vector3(h * 0.05, h * 0.3, h * 0.03), Color(0.2, 0.06, 0.05), Vector3(0, 0, 25))   # yara izi
			_mesh(root, v)
	out["mouth"] = Vector3(0, by + h * 0.05, -L * 0.5)


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


# ------------------------------------------------------------------ şahinler
static func _hawk(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "fly"
	var c = {"hawk_small": Color(0.55, 0.42, 0.3), "hawk_mount": Color(0.62, 0.5, 0.36), "hawk_giant": Color(0.3, 0.28, 0.32)}[model]
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.5, 0), Vector3(h * 0.6, h * 0.55, h * 1.5), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, h * 0.48, -h * 0.3), Vector3(h * 0.55, h * 0.55, h * 0.6), Color(0.92, 0.88, 0.8), Vector3.ZERO, 12)  # göğüs
	b.add("sphere", Vector3(0, h * 0.78, -h * 0.68), Vector3(h * 0.3, h * 0.3, h * 0.36), c.lightened(0.15), Vector3.ZERO, 12)
	b.add("cone", Vector3(0, h * 0.74, -h * 0.9), Vector3(h * 0.08, h * 0.18, h * 0.08), Color(0.95, 0.75, 0.2), Vector3(-110, 0, 0), 6)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.11 * sx, h * 0.83, -h * 0.8), Vector3(h * 0.06, h * 0.05, h * 0.04), Color(0.1, 0.08, 0.05), Vector3.ZERO, 6)
		b.add("box", Vector3(h * 0.11 * sx, h * 0.87, -h * 0.79), Vector3(h * 0.1, h * 0.02, h * 0.05), c.darkened(0.3), Vector3(0, 0, -15 * sx))
		b.add("cyl", Vector3(h * 0.15 * sx, h * 0.12, 0.0), Vector3(h * 0.05, h * 0.25, h * 0.05), Color(0.95, 0.75, 0.2), Vector3.ZERO, 6)
	for k in 5:  # kuyruk yelpazesi
		b.add("box", Vector3((k - 2) * h * 0.07, h * 0.45, h * 0.85), Vector3(h * 0.08, h * 0.03, h * 0.5), c.darkened(0.15), Vector3(0, (k - 2) * 12.0, 0))
	if model != "hawk_small":
		b.add("box", Vector3(0, h * 0.86, h * 0.05), Vector3(h * 0.4, h * 0.05, h * 0.45), Color(0.6, 0.15, 0.15))  # eyer
	_mesh(out["root"], b)
	for sx in [-1.0, 1.0]:
		var pv = _pivot(out["root"], Vector3(h * 0.3 * sx, h * 0.62, -h * 0.05))
		var wb = MB.new()
		for k in 6:
			wb.add("box", Vector3((0.3 + k * 0.32) * h * sx, -k * 0.02 * h, k * 0.07 * h), Vector3(h * 0.36, h * 0.04, h * (0.8 - k * 0.08)), c.darkened(0.05 * (k % 2)), Vector3(0, -8 * k * sx, 0))
			wb.add("box", Vector3((0.3 + k * 0.32) * h * sx, -k * 0.02 * h - h * 0.01, k * 0.07 * h + h * (0.4 - k * 0.04)), Vector3(h * 0.3, h * 0.03, h * 0.12), Color(0.95, 0.93, 0.88), Vector3(0, -8 * k * sx, 0))
		_mesh(pv, wb)
		out["wings"].append(pv)
	out["mouth"] = Vector3(0, h * 0.8, -h * 1.0)


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


static func _dog_proc(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "walk"
	var giant = model == "wolf_giant"
	var c = Color(0.62, 0.46, 0.3) if not giant else Color(0.5, 0.52, 0.58)
	var b = _quad(out, h, c, {"len": 1.15, "leg": 0.5, "snout": 0.3, "ear": 0.16 if not giant else 0.2, "heads": [0.0] if not giant else [-0.18, 0.18],
		"eye": Color(0.15, 0.1, 0.05) if not giant else Color(0.98, 0.78, 0.1), "tail": "bushy", "belly": c.lightened(0.3)})
	if not giant:
		var by = h * 0.62
		b.add("cyl", Vector3(0, by + h * 0.24, -h * 0.5), Vector3(0.3, 0.06, 0.3) * h, Color(0.2, 0.3, 0.5), Vector3(65, 0, 0), 12)  # alın bandı boyunda
		b.add("box", Vector3(0, by + h * 0.24, -h * 0.62), Vector3(0.12, 0.06, 0.02) * h, Color(0.8, 0.82, 0.86), Vector3(-25, 0, 0))
		Loft.tube(b, [Vector3(0, by + h * 0.12, h * 0.2), Vector3(0, by + h * 0.14, -h * 0.1), Vector3(0, by + h * 0.16, -h * 0.3)], [Vector2(0.21, 0.21) * h, Vector2(0.22, 0.24) * h, Vector2(0.23, 0.27) * h], Color(0.2, 0.3, 0.5), 16, 2, false, false,
			func(_t: float, a: float, _d: Vector3) -> Color: return Color(0.2, 0.3, 0.5) if sin(a) > -0.3 else c.lightened(0.3))  # yelek
	_mesh(out["root"], b)


static func _cat(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "walk"
	var giant = model == "cat_giant"
	var c = Color(0.1, 0.16, 0.45) if giant else Color(0.85, 0.58, 0.28)
	var b = _quad(out, h, c, {"len": 1.3, "leg": 0.5, "snout": 0.14, "ear": 0.2, "eye": Color(0.4, 0.95, 1.0) if giant else Color(0.95, 0.85, 0.2),
		"tail": "flame2" if giant else "thin", "belly": c.lightened(0.3) if not giant else Color(0.3, 0.5, 1.0), "mark": Color(0.03, 0.03, 0.1)})
	if giant:
		BeastModels._particles(out["root"], Vector3(h * 0.3, h * 0.3, h * 0.6), [Color(0.35, 0.6, 1.0, 0.9), Color(0.05, 0.05, 0.3, 0.0)], 60, h * 0.35, Vector3(0, h, 0), 0.8, true)
	else:
		Loft.tube(b, [Vector3(0, h * 0.75, h * 0.25), Vector3(0, h * 0.78, -h * 0.2)], [Vector2(0.2, 0.2) * h, Vector2(0.21, 0.23) * h], Color(0.25, 0.3, 0.2), 14, 2, false, false,
			func(_t: float, a: float, _d: Vector3) -> Color: return Color(0.25, 0.3, 0.2) if sin(a) > -0.3 else c.lightened(0.3))  # ninja yeleği
	for sx in [-1.0, 1.0]:  # bıyık
		for k in 2:
			b.add("box", Vector3(h * 0.12 * sx, h * 1.02 - k * h * 0.03, -h * 1.05), Vector3(0.22, 0.006, 0.006) * h, Color(0.95, 0.95, 0.95), Vector3(0, -15 * sx, (k - 0.5) * 10 * sx))
	_mesh(out["root"], b)


static func _weasel(out: Dictionary, h: float) -> void:
	out["anim"] = "walk"
	var c = Color(0.9, 0.84, 0.7)
	var b = _quad(out, h, c, {"len": 1.6, "leg": 0.32, "snout": 0.16, "ear": 0.08, "eye": Color(0.1, 0.05, 0.05), "tail": "bushy", "belly": Color(0.98, 0.96, 0.9), "mark": Color(0.45, 0.32, 0.2)})
	# sırtta orak + bandana
	Loft.tube(b, [Vector3(h * 0.05, h * 0.62, h * 0.2), Vector3(h * 0.2, h * 0.95, h * 0.15), Vector3(h * 0.3, h * 1.15, h * 0.0)], [h * 0.025, h * 0.025, h * 0.025], Color(0.35, 0.25, 0.15), 8, 2)
	Loft.tube(b, [Vector3(h * 0.3, h * 1.15, h * 0.0), Vector3(h * 0.15, h * 1.25, -h * 0.25), Vector3(-h * 0.05, h * 1.15, -h * 0.35)], [Vector2(0.015, 0.06) * h, Vector2(0.012, 0.07) * h, Vector2(0.005, 0.02) * h], Color(0.82, 0.84, 0.88), 8, 3, true, false)
	b.add("box", Vector3(0, h * 0.78, -h * 0.85), Vector3(0.3, 0.06, 0.25) * h, Color(0.2, 0.35, 0.6))
	_mesh(out["root"], b)


# ------------------------------------------------------------------ maymunlar
static func _monkey(out: Dictionary, model: String, h: float) -> void:
	out["anim"] = "biped"
	var king = model == "monkey_king"
	var fur = Color(0.62, 0.45, 0.3)
	var face = Color(0.9, 0.72, 0.6)
	var b = MB.new()
	Loft.tube(b, [Vector3(0, h * 0.3, h * 0.04), Vector3(0, h * 0.5, 0), Vector3(0, h * 0.68, -h * 0.03)], [Vector2(0.2, 0.17) * h, Vector2(0.24, 0.19) * h, Vector2(0.26, 0.2) * h], fur, 16, 3)
	Loft.tube(b, [Vector3(0, h * 0.74, h * 0.02), Vector3(0, h * 0.84, -h * 0.02), Vector3(0, h * 0.93, -h * 0.03)], [Vector2(0.15, 0.14) * h, Vector2(0.16, 0.15) * h, Vector2(0.12, 0.11) * h], fur, 16, 3)
	Loft.tube(b, [Vector3(0, h * 0.86, -h * 0.1), Vector3(0, h * 0.8, -h * 0.17)], [Vector2(0.11, 0.1) * h, Vector2(0.08, 0.06) * h], face, 12, 2)
	for sx in [-1.0, 1.0]:
		var ep = Vector3(h * 0.055 * sx, h * 0.88, -h * 0.14)
		b.add("sphere", ep, Vector3(0.04, 0.03, 0.02) * h, Color(0.95, 0.8, 0.2), Vector3.ZERO, 6)
		BeastModels._brow(b, ep, sx, h * 0.05, fur.darkened(0.4))
		b.add("sphere", Vector3(h * 0.15 * sx, h * 0.87, 0), Vector3(h * 0.07, h * 0.09, h * 0.035), face, Vector3.ZERO, 8)
		# bacaklar
		Loft.tube(b, [Vector3(h * 0.12 * sx, h * 0.32, 0), Vector3(h * 0.15 * sx, h * 0.17, -h * 0.05), Vector3(h * 0.13 * sx, h * 0.02, 0)], [h * 0.09, h * 0.07, h * 0.06], fur, 10, 3)
		b.add("sphere", Vector3(h * 0.13 * sx, h * 0.01, -h * 0.05), Vector3(0.1, 0.04, 0.16) * h, face.darkened(0.2), Vector3.ZERO, 8)
	if king:
		Loft.tube(b, [Vector3(0, h * 0.4, h * 0.02), Vector3(0, h * 0.55, 0), Vector3(0, h * 0.7, -h * 0.02)], [Vector2(0.27, 0.22) * h, Vector2(0.29, 0.23) * h, Vector2(0.3, 0.23) * h], Color(0.22, 0.22, 0.28), 16, 2, false, false)  # zırh
		b.add("cyl", Vector3(0, h * 1.0, -h * 0.02), Vector3(h * 0.2, h * 0.07, h * 0.2), Color(0.9, 0.75, 0.25), Vector3.ZERO, 12)  # taç
		for i in 9:
			var aa = lerpf(-2.2, 2.2, i / 8.0)
			BeastRig.claw(b, Vector3(sin(aa) * h * 0.2, h * 0.72, cos(aa) * h * 0.12), Vector3(sin(aa), -0.5, cos(aa) * 0.6), h * 0.12, h * 0.035, Color(0.95, 0.92, 0.88))  # beyaz yele
	_mesh(out["root"], b)
	for sx in [-1.0, 1.0]:
		var pv = _pivot(out["root"], Vector3(h * 0.25 * sx, h * 0.68, 0))
		var ab = MB.new()
		Loft.tube(ab, [Vector3.ZERO, Vector3(h * 0.06 * sx, -h * 0.28, -h * 0.03), Vector3(h * 0.05 * sx, -h * 0.58, -h * 0.06)], [h * 0.07, h * 0.055, h * 0.05], fur, 10, 3)
		ab.add("sphere", Vector3(h * 0.05 * sx, -h * 0.63, -h * 0.07), Vector3(0.08, 0.1, 0.07) * h, face.darkened(0.2), Vector3.ZERO, 8)
		_mesh(pv, ab)
		out["legs"].append(pv)
	var tail = _pivot(out["root"], Vector3(0, h * 0.35, h * 0.18))
	var tb = MB.new()
	Loft.tube(tb, [Vector3.ZERO, Vector3(0, h * 0.1, h * 0.25), Vector3(0, h * 0.35, h * 0.4), Vector3(0, h * 0.55, h * 0.3)], [h * 0.04, h * 0.035, h * 0.03, h * 0.015], fur, 8, 3)
	_mesh(tail, tb)
	out["tail"] = tail


static func _crows(out: Dictionary, h: float) -> void:
	out["anim"] = "flock"
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	for k in 9:
		var n = Node3D.new()
		n.position = Vector3(rng.randf_range(-2, 2), rng.randf_range(1.0, 3.0), rng.randf_range(-2, 2))
		out["root"].add_child(n)
		var b = MB.new()
		var c = Color(0.08, 0.08, 0.1)
		b.add("sphere", Vector3.ZERO, Vector3(0.22, 0.2, 0.42), c, Vector3.ZERO, 8)
		b.add("sphere", Vector3(0, 0.08, -0.22), Vector3(0.16, 0.15, 0.17), c, Vector3.ZERO, 8)
		b.add("cone", Vector3(0, 0.07, -0.34), Vector3(0.04, 0.1, 0.04), Color(0.2, 0.2, 0.22), Vector3(-90, 0, 0), 5)
		b.add("sphere", Vector3(0.05, 0.11, -0.28), Vector3(0.035, 0.035, 0.02), Color(0.85, 0.1, 0.1), Vector3.ZERO, 5)
		for sx in [-1.0, 1.0]:
			b.add("box", Vector3(0.25 * sx, 0.02, 0.02), Vector3(0.36, 0.02, 0.18), c, Vector3(0, 0, 10 * sx))
		_mesh(n, b)
		out["segments"].append(n)


# ------------------------------------------------------------------ semender
static func _salamander(out: Dictionary, h: float, length: float) -> void:
	out["anim"] = "walk"
	var c = Color(0.22, 0.2, 0.3)
	var spots = Color(0.95, 0.78, 0.2)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.45, 0), Vector3(h * 1.4, h * 0.75, length * 0.45), c, Vector3.ZERO, 16)
	b.add("sphere", Vector3(0, h * 0.5, -length * 0.3), Vector3(h * 1.3, h * 0.6, h * 1.3), c.lightened(0.05), Vector3.ZERO, 14)  # baş
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(h * 0.45 * sx, h * 0.75, -length * 0.33), Vector3(h * 0.22, h * 0.22, h * 0.18), Color(0.95, 0.85, 0.3), Vector3.ZERO, 8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 5
	for i in 22:
		b.add("sphere", Vector3(rng.randf_range(-0.55, 0.55) * h, h * 0.8, rng.randf_range(-0.2, 0.2) * length), Vector3.ONE * h * 0.12, spots, Vector3.ZERO, 6)
	b.add("cyl", Vector3(0, h * 0.85, 0), Vector3(h * 0.2, h * 0.3, h * 0.2), Color(0.5, 0.3, 0.55), Vector3.ZERO, 8)  # sis bezi
	_mesh(out["root"], b)
	var tail = _pivot(out["root"], Vector3(0, h * 0.4, length * 0.2))
	var tb = MB.new()
	tb.add("cone", Vector3(0, 0, length * 0.25), Vector3(h * 0.5, length * 0.55, h * 0.35), c, Vector3(90, 0, 0), 10)
	_mesh(tail, tb)
	out["tail"] = tail
	for p in [Vector3(-0.75, 0, -0.18), Vector3(0.75, 0, -0.18), Vector3(-0.75, 0, 0.14), Vector3(0.75, 0, 0.14)]:
		var pv = _pivot(out["root"], Vector3(p.x * h, h * 0.35, p.z * length))
		var lb = MB.new()
		lb.add("cyl", Vector3(p.x * h * 0.2, -h * 0.15, 0), Vector3(h * 0.25, h * 0.45, h * 0.25), c.darkened(0.1), Vector3(0, 0, 40 * signf(p.x)), 6)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.45, -length * 0.38)


# ------------------------------------------------------------------ kaplumbağa
static func _turtle(out: Dictionary, model: String, h: float, length: float) -> void:
	out["anim"] = "walk"
	if length <= 0.0:
		length = h * 1.6
	var shell = Color(0.3, 0.45, 0.32)
	var skin = Color(0.55, 0.62, 0.45)
	var b = MB.new()
	b.add("hemi", Vector3(0, h * 0.3, 0), Vector3(length * 0.9, h * 1.4, length), shell, Vector3.ZERO, 16)
	b.add("cyl", Vector3(0, h * 0.3, 0), Vector3(length * 0.95, h * 0.12, length * 1.05), shell.lightened(0.15), Vector3.ZERO, 16)
	for i in 7:  # altıgen plakalar
		var a = i * TAU / 6.0
		var pp = Vector3(cos(a), 0, sin(a)) * (length * 0.22 if i < 6 else 0.0)
		b.add("cyl", pp + Vector3(0, h * (0.92 if i == 6 else 0.82), 0), Vector3(length * 0.2, h * 0.08, length * 0.2), shell.darkened(0.15), Vector3.ZERO, 6)
	b.add("sphere", Vector3(0, h * 0.4, -length * 0.55), Vector3(h * 0.45, h * 0.4, h * 0.55), skin, Vector3.ZERO, 12)
	b.add("box", Vector3(0, h * 0.45, -length * 0.5), Vector3(h * 0.48, h * 0.1, h * 0.3), Color(0.65, 0.15, 0.15))  # alın bandı
	if model == "turtle_giant":
		for i in 4:  # sırtta küçük ağaçlar
			b.add("cone", Vector3((i - 1.5) * length * 0.15, h * 1.3, (i % 2 - 0.5) * length * 0.2), Vector3(length * 0.08, h * 0.35, length * 0.08), Color(0.2, 0.5, 0.25), Vector3.ZERO, 6)
	_mesh(out["root"], b)
	for p in [Vector3(-0.42, 0, -0.32), Vector3(0.42, 0, -0.32), Vector3(-0.42, 0, 0.32), Vector3(0.42, 0, 0.32)]:
		var pv = _pivot(out["root"], Vector3(p.x * length, h * 0.25, p.z * length))
		var lb = MB.new()
		lb.add("sphere", Vector3(0, -h * 0.1, 0), Vector3(h * 0.35, h * 0.35, h * 0.35), skin, Vector3.ZERO, 8)
		_mesh(pv, lb)
		out["legs"].append(pv)
	out["mouth"] = Vector3(0, h * 0.4, -length * 0.7)


static func _spider(out: Dictionary, h: float) -> void:
	out["anim"] = "spider"
	var c = Color(0.25, 0.2, 0.18)
	var b = MB.new()
	b.add("sphere", Vector3(0, h * 0.5, h * 0.45), Vector3(h * 1.0, h * 0.8, h * 1.1), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, h * 0.45, -h * 0.2), Vector3(h * 0.6, h * 0.45, h * 0.6), c.lightened(0.1), Vector3.ZERO, 12)
	b.add("box", Vector3(0, h * 0.86, h * 0.45), Vector3(h * 0.12, h * 0.04, h * 0.6), Color(0.85, 0.65, 0.15))
	for i in 6:
		b.add("sphere", Vector3((i % 3 - 1) * h * 0.1, h * 0.55 + (i / 3) * h * 0.07, -h * 0.48), Vector3.ONE * h * 0.06, Color(0.85, 0.1, 0.1), Vector3.ZERO, 6)
	_mesh(out["root"], b)
	for i in 8:
		var sx = -1.0 if i < 4 else 1.0
		var k = i % 4
		var pv = _pivot(out["root"], Vector3(h * 0.25 * sx, h * 0.5, -h * 0.35 + k * h * 0.15))
		var lb = MB.new()
		lb.add("cyl", Vector3(h * 0.35 * sx, h * 0.12, 0), Vector3(h * 0.06, h * 0.75, h * 0.06), c, Vector3(0, 0, -70 * sx), 5)
		lb.add("cyl", Vector3(h * 0.72 * sx, -h * 0.22, 0), Vector3(h * 0.05, h * 0.65, h * 0.05), c, Vector3(0, 0, 25 * sx), 5)
		_mesh(pv, lb)
		out["legs"].append(pv)
