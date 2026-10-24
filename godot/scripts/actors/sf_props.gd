class_name SFProps
extends RefCounted
## Sketchfab hayran modellerinden silah ve aksesuarlar (assets/sketchfab, git'e girmez; yoksa prosedürel model kullanılır).
## Silah düğümü sözleşmesi (CharacterModel.weapon_mesh ile aynı): kabza başlangıçta (0,0,0), namlu +Z yönünde.
## len: metre cinsinden toplam uzunluk; flip: modelin uzun ekseninde kabza ters uçtaysa; grip: elin tuttuğu yer (kabza ucundan oran);
## roll: namlunun düzlemini çevirmek için uzun eksen etrafında derece; tint: dokuyu koruyarak renk çarpanı

const WEAPONS := {
	"kunai": {"file": "kunai_yanez", "len": 0.3, "grip": 0.18},
	"altin_kunai": {"file": "kunai_yanez", "len": 0.32, "grip": 0.18, "tint": Color(1.0, 0.82, 0.45)},
	"zincirli_kunai": {"file": "kunai_yanez", "len": 0.3, "grip": 0.18},
	"patlayici_kunai": {"file": "kunai_explosive", "len": 0.34, "grip": 0.33, "flip": true},
	"tanto": {"file": "tanto_game_ready", "len": 0.45, "grip": 0.15, "flip": true},   # sapından tutulsun (ters tutuluyordu)
	"wakizashi": {"file": "tanto_game_ready", "len": 0.7, "grip": 0.13, "flip": true},
	"kama": {"file": "kama_yanez", "len": 0.55, "grip": 0.22, "pca": false, "yaw": 33.0, "handle": 0.55, "roll": 180.0},
	# muşta/chakra bıçağı: halkalar parmaklara geçer (tutuş halkaların ortası), bıçak başparmak tarafında (+Z)
	"musta": {"file": "trench_knives", "len": 0.3, "grip": 0.3, "flip": true},
	"chakra_bicak": {"file": "trench_knives", "len": 0.33, "grip": 0.3, "flip": true},
	"ruzgar_bicak": {"file": "trench_knives", "len": 0.33, "grip": 0.3, "flip": true, "tint": Color(0.6, 0.85, 1.0), "glow": Color(0.4, 0.8, 1.0)},
	"mizrak": {"file": "naginata_lowpoly", "len": 2.1, "grip": 0.35},
	"el_shuriken": {"file": "big_shuriken", "len": 0.95, "grip": 0.5, "center": true, "pca": false},
	"fuma_shuriken": {"file": "fuma_shuriken", "len": 1.15, "grip": 0.5, "center": true, "pca": false},
	"yelpaze": {"file": "tessen_lowpoly", "len": 0.75, "grip": 0.1, "pca": false},
	"gunbai": {"file": "gunbai_bluue", "len": 1.5, "grip": 0.2},
	"chokuto": {"file": "kusanagi_multipain", "len": 1.0, "grip": 0.12},
	"kubikiribocho": {"file": "kubikiribocho_ezequiel", "len": 1.75, "grip": 0.1, "flip": true},
	"samehada": {"file": "samehada", "len": 1.6, "grip": 0.12},
	"kiba": {"file": "kiba_swords", "len": 0.95, "grip": 0.12, "first_half": true},
	"hiramekarei": {"file": "hiramekarei", "len": 1.6, "grip": 0.08},
	"shibuki": {"file": "shibuki", "len": 1.35, "grip": 0.1},
	"nuibari": {"file": "nuibari", "len": 1.8, "grip": 0.1},
	"kabutowari": {"file": "kabutowari", "len": 0.95, "grip": 0.15, "pca": false},
	"uc_tirpan": {"file": "triple_scythe_lowpoly", "len": 1.7, "grip": 0.3, "pca": false},
	"sai": {"file": "sai", "len": 0.5, "grip": 0.15},
}

## Fırlatılan aletler (Projectile.tool görseli): uzunluk metre
const THROWN := {"kunai": {"file": "kunai_yanez", "len": 0.3, "center": true}, "tag": {"file": "kunai_explosive", "len": 0.32, "center": true}}

static var _cache := {}


static func _path(file: String) -> String:
	var p = "res://assets/sketchfab/%s/%s.glb" % [file, file]
	return p if ResourceLoader.exists(p) else ""


static func has_weapon(id: String) -> bool:
	return WEAPONS.has(id) and _path(WEAPONS[id]["file"]) != ""


## Model uzayındaki görünür mesh sınırları
static func _bounds(root: Node3D) -> AABB:
	var ab = AABB(); var first = true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf = Transform3D.IDENTITY
		var c: Node = mi
		while c != root and c != null:
			xf = (c as Node3D).transform * xf
			c = c.get_parent()
		var a = xf * mi.get_aabb()
		ab = a if first else ab.merge(a)
		first = false
	return ab


## Hazır (önbellekli) sahneden bağımsız örnek döner: kabza (0,0,0), namlu +Z, toon malzeme
static func weapon_node(id: String, defs := WEAPONS) -> Node3D:
	if not defs.has(id):
		return null
	var d: Dictionary = defs[id]
	var p = _path(d["file"])
	if p == "":
		return null
	var key = "%s|%s" % [id, d["file"]]
	if not _cache.has(key):
		_cache[key] = _prepare(load(p) as PackedScene, d)
	var proto: Node3D = _cache[key]
	return proto.duplicate() if proto else null


static func _prepare(ps: PackedScene, d: Dictionary) -> Node3D:
	if ps == null:
		return null
	var inst: Node3D = ps.instantiate()
	var ap = inst.find_child("AnimationPlayer", true, false)
	if ap:
		ap.get_parent().remove_child(ap)
		ap.free()
	var ab = _bounds(inst)
	if ab.size == Vector3.ZERO:
		inst.free()
		return null
	if d.get("first_half", false):
		# çift silah: yalnız ilk yarıyı (x ekseninin bir tarafı) göster
		var mid = ab.get_center().x
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var a = _bounds_single(inst, mi)
			if a.get_center().x > mid:
				mi.visible = false
		ab = _bounds_visible(inst)
	# uzun ekseni bul ve +Z'ye çevir
	var axis = 0
	if ab.size.y >= ab.size.x and ab.size.y >= ab.size.z:
		axis = 1
	elif ab.size.z >= ab.size.x and ab.size.z >= ab.size.y:
		axis = 2
	var rot = Basis.IDENTITY
	match axis:
		0: rot = Basis(Vector3.UP, -PI * 0.5)        # +X -> +Z
		1: rot = Basis(Vector3.RIGHT, PI * 0.5)      # +Y -> +Z
	# model kendi uzayında çapraz duruyorsa (ör. kunai, Kubikiribōchō) AABB ekseni yanlış: gerçek uzun ekseni (PCA) +Z'ye oturt
	var pts: PackedVector3Array = _points(inst) if (d.get("pca", true) or d.has("handle")) else PackedVector3Array()
	var tilted = d.has("handle") and pts.size() > 8
	if pts.size() > 8:
		var av: Vector3 = [Vector3.RIGHT, Vector3.UP, Vector3.BACK][axis]
		var e = _principal(pts)
		if d.get("pca", true) and e != Vector3.ZERO and absf(e.dot(av)) < cos(deg_to_rad(8.0)):
			if e.dot(av) < 0.0:
				e = -e
			rot = rot * Basis(Quaternion(e, av))
			tilted = true
	if d.get("flip", false):
		rot = Basis(Vector3.UP, PI) * rot
	# L biçimli silahlar (kama): kabza ekseni AABB'ye göre yatık; elle düzeltme (derece, Y ve X etrafında)
	if d.has("yaw"):
		rot = Basis(Vector3.UP, deg_to_rad(float(d["yaw"]))) * rot
	if d.has("pitch"):
		rot = Basis(Vector3.RIGHT, deg_to_rad(float(d["pitch"]))) * rot
	rot = Basis(Vector3.BACK, deg_to_rad(float(d.get("roll", 0.0)))) * rot
	var holder = Node3D.new()
	var pivot = Node3D.new()
	holder.add_child(pivot)
	pivot.add_child(inst)
	pivot.transform.basis = rot
	var ab2 = _pts_aabb(Transform3D(rot, Vector3.ZERO), pts) if tilted else Transform3D(rot, Vector3.ZERO) * ab  # dönmüş sınırlar
	var length = ab2.size.z
	var k = float(d["len"]) / maxf(length, 0.0001)
	pivot.scale = Vector3.ONE * k
	pivot.transform.basis = rot.scaled(Vector3.ONE * k)
	# kabza ucu z=0'a, eksen ortası x/y=0'a; tutma noktası (grip) orijine
	var ab3 = _pts_aabb(pivot.transform, pts) if tilted else pivot.transform * ab
	var grip_z = ab3.position.z + ab3.size.z * float(d.get("grip", 0.1))
	if d.get("center", false):
		grip_z = ab3.get_center().z
	var cx = ab3.get_center().x
	var cy = ab3.get_center().y
	if d.has("handle") and tilted:
		# eksen ortası yerine kabza bölümünün ortası (kama: bıçak yana taşar, el kabzayı tutmalı)
		var zl = ab3.position.z + ab3.size.z * float(d["handle"])
		var acc = Vector3.ZERO
		var n = 0
		for p in pts:
			var q = pivot.transform * p
			if q.z <= zl:
				acc += q
				n += 1
		if n > 0:
			cx = acc.x / n
			cy = acc.y / n
	pivot.position = Vector3(-cx, -cy, -grip_z)
	_toon(inst, d.get("tint", null), d.get("glow", null))
	return holder


## Görünür meshlerin köşe noktaları (model uzayında, en fazla ~6000 örnek)
static func _points(root: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var mis = root.find_children("*", "MeshInstance3D", true, false)
	var total = 0
	for mi in mis:
		if mi.visible and mi.mesh:
			for si in mi.mesh.get_surface_count():
				total += (mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var stride = maxi(1, total / 6000)
	for mi in mis:
		if not mi.visible or mi.mesh == null:
			continue
		var xf = Transform3D.IDENTITY
		var c: Node = mi
		while c != root and c != null:
			xf = (c as Node3D).transform * xf
			c = c.get_parent()
		for si in mi.mesh.get_surface_count():
			var vs: PackedVector3Array = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
			for i in range(0, vs.size(), stride):
				out.append(xf * vs[i])
	return out


## Nokta bulutunun ana ekseni (kovaryansın en büyük öz vektörü, kuvvet yöntemi)
static func _principal(pts: PackedVector3Array) -> Vector3:
	var m = Vector3.ZERO
	for p in pts:
		m += p
	m /= float(pts.size())
	var xx = 0.0; var yy = 0.0; var zz = 0.0; var xy = 0.0; var xz = 0.0; var yz = 0.0
	for p in pts:
		var q = p - m
		xx += q.x * q.x; yy += q.y * q.y; zz += q.z * q.z
		xy += q.x * q.y; xz += q.x * q.z; yz += q.y * q.z
	var v = Vector3(0.577, 0.578, 0.579)
	for it in 40:
		var n = Vector3(xx * v.x + xy * v.y + xz * v.z, xy * v.x + yy * v.y + yz * v.z, xz * v.x + yz * v.y + zz * v.z)
		if n.length() < 1e-12:
			return Vector3.ZERO
		v = n.normalized()
	return v


static func _pts_aabb(xf: Transform3D, pts: PackedVector3Array) -> AABB:
	var ab = AABB(xf * pts[0], Vector3.ZERO)
	for p in pts:
		ab = ab.expand(xf * p)
	return ab


static func _bounds_single(root: Node3D, mi: MeshInstance3D) -> AABB:
	var xf = Transform3D.IDENTITY
	var c: Node = mi
	while c != root and c != null:
		xf = (c as Node3D).transform * xf
		c = c.get_parent()
	return xf * mi.get_aabb()


static func _bounds_visible(root: Node3D) -> AABB:
	var ab = AABB(); var first = true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible:
			continue
		var a = _bounds_single(root, mi)
		ab = a if first else ab.merge(a)
		first = false
	return ab


## StandardMaterial -> oyunun toon shader'ı (doku + renk korunur, anime gölge ve kenar ışığı)
static func _toon(n: Node, tint = null, glow = null) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for si in mi.mesh.get_surface_count():
			var sm = mi.get_active_material(si)
			var m = ShaderMaterial.new()
			m.shader = load("res://shaders/toon.gdshader")
			m.set_shader_parameter("use_vertex_color", false)
			m.set_shader_parameter("rim_amount", 0.45)
			m.set_shader_parameter("spec_amount", 0.35)
			var col = Color.WHITE
			if sm is BaseMaterial3D:
				col = sm.albedo_color
				if sm.albedo_texture:
					m.set_shader_parameter("tex", sm.albedo_texture)
			if tint != null:
				col = col * Color(tint)
			m.set_shader_parameter("tint", col)
			if glow != null:
				m.set_shader_parameter("emission_color", Color(glow.r, glow.g, glow.b, 0.6))
			mi.set_surface_override_material(si, m)


## Aksesuarlar (Gear görsel karşılıkları): bone = takılacak kemik, size = en uzun kenar (m),
## off = referans noktasına (kafa merkezi / üst göğüs) göre konum, rot = modeli yüz (+Z) yönüne çeviren derece
const ACCESSORIES := {
	"hokage_sapka": {"file": "hokage_hat", "bone": "Head", "size": 0.4, "off": Vector3(0, 0.1, -0.01)},
	"hasir_sapka": {"file": "akatsuki_hat", "bone": "Head", "size": 0.5, "off": Vector3(0, 0.02, 0.0)},
	"anbu_kedi": {"file": "anbu_mask", "bone": "Head", "size": 0.22, "off": Vector3(0, -0.01, 0.11), "rot": Vector3(0, 180, 0)},
	"kitsune": {"file": "kitsune_mask", "bone": "Head", "size": 0.27, "off": Vector3(0, -0.005, 0.12), "rot": Vector3(0, 180, 0)},   # öne: karakterin burnu maskeyi deliyordu
	"tengu": {"file": "tengu_mask", "bone": "Head", "size": 0.25, "off": Vector3(0, -0.01, 0.13)},
	"oni": {"file": "oni_mask_samurai", "bone": "Head", "size": 0.2, "off": Vector3(0, -0.05, 0.1)},
	"su_kabagi": {"file": "gourd_doverlock", "bone": "UpperChest", "size": 0.55, "off": Vector3(0, -0.12, -0.2)},
	"sake_kabagi": {"file": "sake_gourd", "bone": "Hips", "size": 0.22, "off": Vector3(0.17, -0.04, 0.02)},
	"dev_parsomen": {"file": "water_scroll", "bone": "UpperChest", "size": 0.7, "off": Vector3(0, -0.1, -0.2)},
}
## Gear look değeri -> aksesuar
const HEAD_MAP := {"kasa": "hasir_sapka", "kage": "hokage_sapka"}
const FACE_MAP := {"anbu_kedi": "anbu_kedi", "kitsune": "kitsune", "tengu": "tengu", "oni": "oni"}
const BACK_MAP := {"parsomen": "dev_parsomen", "kabak": "su_kabagi", "sake": "sake_kabagi"}


static func has_accessory(id: String) -> bool:
	return ACCESSORIES.has(id) and _path(ACCESSORIES[id]["file"]) != ""


## Aksesuar düğümü: merkezi orijinde, en uzun kenarı size metre (yönü defs'teki "rot" ile ayarlanır)
static func accessory_node(id: String) -> Node3D:
	if not has_accessory(id):
		return null
	var d: Dictionary = ACCESSORIES[id]
	var key = "acc|" + id
	if not _cache.has(key):
		var ps = load(_path(d["file"])) as PackedScene
		var inst: Node3D = ps.instantiate() if ps else null
		if inst == null:
			_cache[key] = null
		else:
			var ap = inst.find_child("AnimationPlayer", true, false)
			if ap:
				ap.get_parent().remove_child(ap)
				ap.free()
			var holder = Node3D.new()
			var pivot = Node3D.new()
			holder.add_child(pivot)
			pivot.add_child(inst)
			var rot: Vector3 = d.get("rot", Vector3.ZERO)
			pivot.rotation_degrees = rot
			var ab = pivot.transform * _bounds(inst)
			var k = float(d["size"]) / maxf(maxf(ab.size.x, ab.size.y), maxf(ab.size.z, 0.0001))
			pivot.scale = Vector3.ONE * k
			ab = pivot.transform * _bounds(inst)
			pivot.position = -ab.get_center()
			_toon(inst, d.get("tint", null))
			_cache[key] = holder
	var proto: Node3D = _cache[key]
	return proto.duplicate() if proto else null


## Yer/yapı modelleri: en uzun yatay kenar size metre, taban y=0, ortası orijinde; yaw: modelin önünü -Z'ye çeviren derece
const PLACES := {
	"ichiraku": {"file": "ichiraku_benjamin", "size": 9.5, "yaw": 0.0},
}
## İncelenmiş, iyi görünen ama henüz dünyaya yerleştirilmemiş yer modelleri (dünya ajanı için; pakete girmesi için PLACES'e "file" ile eklenmeli):
## torii -> torii_game_asset (7 m), tas_fener -> stone_lantern_sahir (0.9 m), kopru -> wood_bridge (12 m), komainu -> komainu_guard (2.4 m),
## pagoda -> shrine_pagoda (5 m), sakura -> sakura_tree_lowpoly (7 m), cay_evi -> zen_tea_house, ramen_ic -> ramen_shop_lowpoly (iç mekân)


static func has_place(id: String) -> bool:
	return PLACES.has(id) and _path(PLACES[id]["file"]) != ""


static func place_node(id: String) -> Node3D:
	if not has_place(id):
		return null
	var d: Dictionary = PLACES[id]
	var key = "place|" + id
	if not _cache.has(key):
		var ps = load(_path(d["file"])) as PackedScene
		var inst: Node3D = ps.instantiate() if ps else null
		if inst == null:
			_cache[key] = null
		else:
			var holder = Node3D.new()
			var pivot = Node3D.new()
			holder.add_child(pivot)
			pivot.add_child(inst)
			pivot.rotation.y = deg_to_rad(float(d.get("yaw", 0.0)))
			var ab = pivot.transform * _bounds(inst)
			var k = float(d["size"]) / maxf(maxf(ab.size.x, ab.size.z), 0.0001)
			pivot.scale = Vector3.ONE * k
			ab = pivot.transform * _bounds(inst)
			pivot.position = Vector3(-ab.get_center().x, -ab.position.y, -ab.get_center().z)
			_toon(inst)
			_cache[key] = holder
	var proto: Node3D = _cache[key]
	return proto.duplicate() if proto else null

