class_name JuinForms
extends RefCounted
## Lanetli Mühür II beden biçimleri (ref: refs/juin/sheet.jpg, sheet2.jpg).
## Her parça bedenin kendi kemiğinden çıkar ve onunla yaşar: kanat sırt kemiğinde çırpar, ek kollar gerçek kolların
## pozunu izler, iri gövde gerçek kemik ölçeğiyle büyür (ayrı duran süs yok).

## Kanat parmakları: [açı (+Y'den dışa doğru, rad), boy]
const WING_F := [[-0.42, 1.0], [0.1, 1.42], [0.6, 1.55], [1.08, 1.36], [1.6, 0.95]]


## Sırt kanadı: dev bir el gibi — bilek sapı, avuç, beş kemik parmak ve aralarında yırtık kenarlı zar
static func wing_mesh(sx: float, tone: Color) -> ArrayMesh:
	var mb = MB.new()
	var palm = Vector2(0.28, 0.4)
	var web = tone.darkened(0.2)
	var out = PackedVector2Array()
	out.append(Vector2(-0.04, 0.0))
	out.append(Vector2(0.0, 0.3))
	var tips = []
	for f in WING_F:
		tips.append(palm + Vector2(sin(f[0]), cos(f[0])) * float(f[1]))
	for i in tips.size():
		out.append(tips[i])
		if i < tips.size() - 1:
			var am = (float(WING_F[i][0]) + float(WING_F[i + 1][0])) * 0.5
			var lm = (float(WING_F[i][1]) + float(WING_F[i + 1][1])) * 0.5 * 0.7
			out.append(palm + Vector2(sin(am - 0.13), cos(am - 0.13)) * lm * 1.07)   # yırtık zar kenarı
			out.append(palm + Vector2(sin(am), cos(am)) * lm * 0.9)
			out.append(palm + Vector2(sin(am + 0.12), cos(am + 0.12)) * lm * 1.03)
	out.append(palm + Vector2(0.3, -0.26))
	out.append(Vector2(0.1, -0.05))
	for i in out.size():
		out[i] = Vector2(out[i].x * sx, out[i].y)
	# levha (kalınlık, u, v) → kanat düzlemi XY, incelik Z
	mb.add_slab(out, 0.03, web, Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3.ZERO), Callable(), web.darkened(0.25))
	var p3 = func(q: Vector2, z: float) -> Vector3: return Vector3(q.x * sx, q.y, z)
	# bilek sapı: sırttan avuca
	Loft.tube(mb, [Vector3(0, -0.06, 0.05), Vector3(0.02 * sx, 0.12, -0.01), p3.call(palm, 0.0)], [0.085, 0.075, 0.07], [tone.darkened(0.1), tone, tone], 10, 3, true, true)
	for i in tips.size():
		var tip: Vector2 = tips[i]
		var mid = palm.lerp(tip, 0.5)
		Loft.tube(mb, [p3.call(palm, 0.0), p3.call(mid, 0.0), p3.call(palm.lerp(tip, 0.85), 0.0), p3.call(tip + (tip - palm).normalized() * 0.05, 0.0)],
			[0.06, 0.042, 0.026, 0.004], [tone, tone.lightened(0.06), tone, tone.darkened(0.3)], 8, 3, false, true)
		mb.add("sphere", p3.call(mid, 0.0), Vector3(0.052, 0.052, 0.052), tone.lightened(0.04), Vector3.ZERO, 8)   # boğum
	mb.add("sphere", p3.call(palm, 0.0), Vector3(0.11, 0.11, 0.08), tone, Vector3.ZERO, 10)
	return mb.build(Props.toon())


## Kanat çırpışı: kök sırt kemiğinde; yerde ağır ağır salınır, havada kuvvetle çırpar
class Flap extends Node3D:
	var sx := 1.0
	var who: Node3D
	var t := 0.0
	var amp := 0.05
	var mid := 0.0
	func _process(dt: float) -> void:
		var fly = is_instance_valid(who) and who.has_method("is_flying") and who.is_flying()
		t += dt * (8.5 if fly else 1.7)
		amp = lerpf(amp, 0.42 if fly else 0.05, minf(1.0, dt * 5.0))
		mid = lerpf(mid, 0.12 if fly else 0.0, minf(1.0, dt * 5.0))
		basis = Basis(Vector3.UP, sx * 0.32) * Basis(Vector3(0, 0, 1), sx * (-0.5 + mid + sin(t) * amp))


## Ek kol: kendi duruşunda bekler (dışa-öne açık, dirsek bükük); gerçek kol savrulunca onunla birlikte savrulur
class Arm extends Node3D:
	var sk: Skeleton3D
	var ua := -1
	var la := -1
	var rest_b := Basis.IDENTITY   # gerçek üst kolun dinlenme yönü (model uzayı)
	var idle_q := Quaternion.IDENTITY   # gerçek kolun bekleme pozu (ilk karede alınır): yalnız ondan sapma izlenir
	var have_idle := false
	var base := Basis.IDENTITY     # ek kolun kendi duruşu: +Y kol yönü, +Z öne
	var follow := 0.8
	var bend := 1.0
	var elbow: Node3D
	var q_s := Quaternion.IDENTITY
	var e_s := 0.0
	var grow := 0.05
	var t := 0.0
	func _process(dt: float) -> void:
		if not is_instance_valid(sk) or ua < 0 or la < 0:
			return
		t += dt
		var pq = (sk.get_bone_rest(ua).basis.get_rotation_quaternion().inverse() * sk.get_bone_pose_rotation(ua)).normalized()
		if not have_idle:
			idle_q = pq
			have_idle = true
		# bekleme pozundan sapma, model uzayına çevrilir (ek kolun kendi eksenlerinde uygulanabilsin)
		var dq = Quaternion(rest_b * Basis(pq * idle_q.inverse()) * rest_b.inverse()).normalized()
		var de = (sk.get_bone_rest(la).basis.get_rotation_quaternion().inverse() * sk.get_bone_pose_rotation(la)).normalized()
		var k = minf(1.0, dt * 13.0)
		q_s = q_s.slerp(Quaternion.IDENTITY.slerp(dq, follow), k)
		e_s = lerpf(e_s, clampf(de.get_angle(), 0.0, 1.6) * 0.45, k)
		basis = (Basis(q_s) * base).scaled(Vector3.ONE * grow)
		if is_instance_valid(elbow):
			elbow.basis = Basis(Vector3.RIGHT, bend - e_s * 0.6 + sin(t * 1.6 + bend * 7.0) * 0.05)


static func _arm_meshes(tone: Color, s: float) -> Array:
	var up = MB.new()
	var Lu = 0.25 * s
	up.add("sphere", Vector3.ZERO, Vector3.ONE * 0.058 * s, tone, Vector3.ZERO, 10)
	Loft.limb(up, Vector3.ZERO, Vector3(0, Lu, 0), 0.05 * s, 0.04 * s, [tone, tone.lightened(0.04), tone], 12, 1.22)
	var lo = MB.new()
	var Ll = 0.23 * s
	lo.add("sphere", Vector3.ZERO, Vector3.ONE * 0.043 * s, tone.darkened(0.06), Vector3.ZERO, 10)
	Loft.limb(lo, Vector3.ZERO, Vector3(0, Ll, 0), 0.042 * s, 0.029 * s, [tone, tone, tone.darkened(0.05)], 12, 1.18)
	# yumruk: avuç + dört boğum + başparmak
	var h = Vector3(0, Ll + 0.045 * s, 0)
	lo.add("sphere", h, Vector3(0.04, 0.05, 0.034) * s, tone, Vector3.ZERO, 10)
	for f in 4:
		lo.add("sphere", h + Vector3((f - 1.5) * 0.019, 0.034, 0.012) * s, Vector3(0.012, 0.016, 0.02) * s, tone.lightened(0.05), Vector3.ZERO, 6)
	Loft.tube(lo, [h + Vector3(0.036, -0.02, 0.0) * s, h + Vector3(0.05, 0.012, 0.014) * s, h + Vector3(0.03, 0.036, 0.03) * s], [0.013 * s, 0.012 * s, 0.008 * s], tone.darkened(0.04), 6, 2, true, true)
	return [up.build(Props.toon()), lo.build(Props.toon()), Lu]


## Döner: {"nodes": silinecek düğümler, "undo": gövdeyi eski hâline döndüren çağrı}
static func build(c: Node3D, form: String, skin: Color) -> Dictionary:
	var m = c.get("model")
	var res = {"nodes": [], "undo": Callable()}
	if m == null or not is_instance_valid(m) or m.skel == null:
		return res
	var sk: Skeleton3D = m.skel
	var tone = Color(CharacterModel.VROID_SKIN.r * skin.r, CharacterModel.VROID_SKIN.g * skin.g, CharacterModel.VROID_SKIN.b * skin.b)
	var chest_b = "UpperChest" if sk.find_bone("UpperChest") >= 0 else "Chest"
	var p_ch: Vector3 = m._grest(sk.find_bone(chest_b)).origin
	var mk = func(mesh: Mesh) -> MeshInstance3D:
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		return mi
	match form:
		"kanat":
			for sx in [1.0, -1.0]:   # model uzayı: +X karakterin solu, -Z sırt
				var ba = m._attach(chest_b, Transform3D.IDENTITY)
				var fl = Flap.new()
				fl.sx = sx
				fl.who = c
				fl.position = p_ch + Vector3(sx * 0.085, 0.05, -0.085)
				ba.get_child(0).add_child(fl)
				var mi = mk.call(wing_mesh(sx, tone))
				fl.add_child(mi)
				mi.scale = Vector3.ONE * 0.03
				var tw = mi.create_tween()
				tw.tween_property(mi, "scale", Vector3.ONE * 0.66, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				res["nodes"].append(ba)
		"boynuz":
			var sc: Vector3 = m.skull_c
			var sr: Vector3 = m.skull_r
			var cream = Color(0.93, 0.89, 0.78)
			var mb = MB.new()
			for hs in [[Vector3(0, 1, -0.2), 0.1, 0.034], [Vector3(0.62, 0.78, 0.0), 0.13, 0.04], [Vector3(-0.62, 0.78, 0.0), 0.13, 0.04],
					[Vector3(0.97, 0.22, 0.1), 0.15, 0.045], [Vector3(-0.97, 0.22, 0.1), 0.15, 0.045]]:
				var d: Vector3 = (hs[0] as Vector3).normalized()
				var L: float = hs[1]
				var r0: float = hs[2]
				var b0 = sc + Vector3(d.x * sr.x, d.y * sr.y, d.z * sr.z) * 0.78
				Loft.tube(mb, [b0, b0 + d * L * 0.55, b0 + d * L * 0.95 + Vector3.UP * L * 0.28, b0 + d * L * 1.05 + Vector3.UP * L * 0.7],
					[r0, r0 * 0.92, r0 * 0.6, 0.004], [tone.darkened(0.25), cream.darkened(0.12), cream, cream.lightened(0.1)], 10, 4, false, true)
			var ba = m._attach("Head", Transform3D.IDENTITY)
			var holder = Node3D.new()
			holder.position = sc
			ba.get_child(0).add_child(holder)
			var mi = mk.call(mb.build(Props.toon()))
			mi.position = -sc
			holder.add_child(mi)
			holder.scale = Vector3.ONE * 0.4
			holder.create_tween().tween_property(holder, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			res["nodes"].append(ba)
		"kaya":
			# gövde gerçek kemiklerle irileşir: omuz, göğüs, boyun, kol ve bacak kalınlaşır
			var ov = m.get("overlay")
			if ov != null:
				var o = {"b_arm": ov.b_arm, "b_leg": ov.b_leg, "b_chest": ov.b_chest, "b_rib": ov.b_rib, "b_neck": ov.b_neck}
				var k = {"b_arm": 1.6, "b_leg": 1.3, "b_chest": 1.3, "b_rib": 1.22, "b_neck": 1.35}
				m.create_tween().tween_method(func(u: float):
					if is_instance_valid(ov):
						for key in o:
							ov.set(key, float(o[key]) * lerpf(1.0, float(k[key]), u)), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				res["undo"] = func():
					if is_instance_valid(ov) and is_instance_valid(m):
						m.create_tween().tween_method(func(u: float):
							if is_instance_valid(ov):
								for key in o:
									ov.set(key, float(o[key]) * lerpf(float(k[key]), 1.0, u)), 0.0, 1.0, 0.35)
			# deri yumruları: omuz ve kolun üstünde, alında (ten rengi kubbeler, yarısı derinin içinde)
			var rng = RandomNumberGenerator.new()
			rng.seed = 77
			for side in ["Left", "Right"]:
				var ua = sk.find_bone(side + "UpperArm")
				var la = sk.find_bone(side + "LowerArm")
				var hd = sk.find_bone(side + "Hand")
				if ua < 0 or la < 0 or hd < 0:
					continue
				var pu: Vector3 = m._grest(ua).origin
				var pl: Vector3 = m._grest(la).origin
				var ph: Vector3 = m._grest(hd).origin
				for seg in [[side + "UpperArm", pu, pl, 0.026, [0.03, 0.2, 0.36]]]:
					var mb = MB.new()
					for u in seg[4]:
						var a = rng.randf_range(-0.9, 0.5)   # kolun üstü ile arkası arası
						var q: Vector3 = (seg[1] as Vector3).lerp(seg[2], float(u)) + Vector3(0, cos(a), sin(a) - 0.0) * float(seg[3])
						var r = rng.randf_range(0.024, 0.031)   # kol kemiği kalınlaşınca yumru da onunla büyür
						mb.add_grad("sphere", q, Vector3(r, r * 0.8, r), tone.lightened(0.1), tone.darkened(0.05), Vector3.ZERO, 8)
					var ba = m._attach(seg[0], Transform3D.IDENTITY)
					ba.get_child(0).add_child(mk.call(mb.build(Props.toon())))
					res["nodes"].append(ba)
			var sc: Vector3 = m.skull_c
			var sr: Vector3 = m.skull_r
			var mbh = MB.new()
			for d0 in [Vector3(0.0, 0.62, 0.78), Vector3(0.33, 0.6, 0.73), Vector3(-0.33, 0.6, 0.73), Vector3(0.55, 0.42, 0.72), Vector3(-0.55, 0.42, 0.72)]:
				var d: Vector3 = d0.normalized()
				mbh.add_grad("sphere", sc + Vector3(d.x * sr.x, d.y * sr.y, d.z * sr.z), Vector3(0.021, 0.018, 0.013), tone.lightened(0.1), tone, Vector3.ZERO, 8)
			var bah = m._attach("Head", Transform3D.IDENTITY)
			bah.get_child(0).add_child(mk.call(mbh.build(Props.toon())))
			res["nodes"].append(bah)
		"orumcek":
			for side in ["Left", "Right"]:
				var sx = 1.0 if side == "Left" else -1.0
				var ua = sk.find_bone(side + "UpperArm")
				var la = sk.find_bone(side + "LowerArm")
				if ua < 0 or la < 0:
					continue
				var rest: Transform3D = m._grest(ua)
				for k in 2:
					var s = 1.08 - k * 0.08
					var am = _arm_meshes(tone, s)
					var ba = m._attach(chest_b, Transform3D.IDENTITY)
					var arm = Arm.new()
					arm.sk = sk
					arm.ua = ua
					arm.la = la
					arm.rest_b = rest.basis.orthonormalized()
					var dir = (Vector3(sx * 0.85, -0.12, 0.5) if k == 0 else Vector3(sx * 0.55, -0.62, 0.56)).normalized()
					var zf = (Vector3(0, 0.25, 1) - dir * dir.dot(Vector3(0, 0.25, 1))).normalized()
					arm.base = Basis(dir.cross(zf).normalized(), dir, zf)
					arm.bend = 1.25 if k == 0 else 0.85
					arm.follow = 0.8 - 0.15 * k
					arm.position = rest.origin + Vector3(-sx * (0.03 + 0.01 * k), -0.09 - 0.1 * k, 0.0)
					ba.get_child(0).add_child(arm)
					arm.add_child(mk.call(am[0]))
					var el = Node3D.new()
					el.position = Vector3(0, float(am[2]), 0)
					arm.add_child(el)
					el.add_child(mk.call(am[1]))
					arm.elbow = el
					var tw = arm.create_tween()
					tw.tween_interval(0.08 * k)
					tw.tween_property(arm, "grow", 1.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					res["nodes"].append(ba)
	return res
