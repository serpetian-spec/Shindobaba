class_name BeastSus
extends Node3D
## Bijū + Susanoo: tam dönüşümdeki kuyruklu canavar, kullanıcının KENDİ Susanoo'sunu (seçtiği zırh / yüz / silah / renk, ulaştığı kademe)
## zırh olarak giyer. Susanoo'nun parça ağları (Susanoo._parts_cache) canavarın bağlantı noktalarına (baş, göğüs, kalça, kol, bacak)
## oturtulur; kuyruklar Susanoo plakasına bürünür. Kolu olmayan canavarda (Kurama, Matatabi, Kokuō, Chōmei) sırttan iki Susanoo
## kolu çıkar ve silahı onlar tutar. Bu düğüm canavar iskeletinin çocuğudur; silinince her şey eski hâline döner.

const ARM_BONES := ["UpperArm", "LowerArm", "Hand", "Thumb", "Index", "Middle", "Ring", "Little"]

var rig: BeastRig
var sn: Susanoo
var made: Array = []          # kurduğumuz düğümler
var restored: Array = []      # [MeshInstance3D, eski malzeme]
var back_arms: Array = []     # [{"sh": Node3D, "el": Node3D, "side": ±1, "base": Basis}]
var pmat: ShaderMaterial
var wmats: Array = []         # giyilen zırhın malzemeleri (et silik, plaka dolgun)
var t := 0.0
var stops: Array = []         # canavarın bağlantı noktaları (köşe toplarken sınır)


## Oyuncunun durumuna göre giydir / çıkar (Susanoo ya da tam dönüşüm açılıp kapanınca çağrılır)
static func sync(p: Node3D) -> void:
	if p == null or not is_instance_valid(p) or p.combat == null or p.combat.modes == null:
		return
	var eyes = p.combat.modes.eyes
	var cloak = p.combat.modes.cloak
	var rg: BeastRig = cloak.rig if cloak and is_instance_valid(cloak.rig) else null
	var s: Susanoo = eyes.susanoo_node if eyes and eyes.susanoo and is_instance_valid(eyes.susanoo_node) else null
	var cur: BeastSus = rg.get_node_or_null("BeastSus") if rg else null
	if rg and s:
		if cur and cur.sn == s:
			return
		if cur:
			cur.take_off()
		var b = BeastSus.new()
		b.name = "BeastSus"
		rg.add_child(b)
		b.wear(rg, s)
	else:
		if cur:
			cur.take_off()
		if eyes and is_instance_valid(eyes.susanoo_node):
			eyes.susanoo_node.visible = true


func take_off() -> void:
	for r in restored:
		if is_instance_valid(r[0]):
			r[0].material_overlay = r[1]
	for n in made:
		if is_instance_valid(n):
			n.queue_free()
	if is_instance_valid(sn):
		sn.visible = true
	name = "BeastSusOld"
	queue_free()


## Bağlantı noktasına ait ağların köşeleri (nokta uzayında). Alt düğümlere iner; başka bir bağlantı noktasına (stops), zayıf nokta /
## çarpışma düğümüne ve kendi kurduğumuz parçalara girmez. Canavarların kuruluşu farklıdır (Kurama'nın başı "yuz" alt düğümünde,
## Shukaku'nun gövdesi tümüyle kalçada), bu yüzden yalnız doğrudan çocuklara bakmak yetmez.
func _verts(pv: Node3D, _unused := 0) -> PackedVector3Array:
	var out := PackedVector3Array()
	if pv == null:
		return out
	var inv = pv.global_transform.affine_inverse()
	var stack: Array = pv.get_children()
	while not stack.is_empty():
		var ch = stack.pop_back()
		if ch in stops or ch in made or not (ch is Node3D):
			continue
		var nm = String(ch.name).to_lower()
		if nm.begins_with("weak") or nm.begins_with("carpisma"):
			continue
		if ch is MeshInstance3D and ch.mesh and ch.mesh.get_surface_count() > 0:
			var vs: PackedVector3Array = ch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var xf: Transform3D = inv * ch.global_transform
			var step = maxi(1, vs.size() / 500)
			for i in range(0, vs.size(), step):
				out.append(xf * vs[i])
		stack.append_array(ch.get_children())
	return out


## Köşelerin (ax) ekseni üzerindeki %8 - %92 aralığı: [merkez, yarı boy]
static func _span(vs: PackedVector3Array, ax: Vector3) -> Vector2:
	if vs.is_empty():
		return Vector2(0, 1)
	var a: Array = []
	for v in vs:
		a.append(v.dot(ax))
	a.sort()
	var lo: float = a[int(a.size() * 0.08)]
	var hi: float = a[mini(a.size() - 1, int(a.size() * 0.92))]
	return Vector2((lo + hi) * 0.5, maxf(0.05, (hi - lo) * 0.5))


func _put(parent: Node3D, mesh: Mesh, kind: int, xf: Transform3D) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xf
	mi.material_override = wmats[kind]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	made.append(mi)
	return mi


## Kutu eşlemesi: insan kutusu (merkez hc, yarı boy hh; eksenler X, Y, Z) -> canavar kutusu (eksenler rx, up, fr)
static func _box_xf(hc: Vector3, hh: Vector3, bc: Vector3, bh: Vector3, rx: Vector3, up: Vector3, fr: Vector3) -> Transform3D:
	var b = Basis(rx * (bh.x / hh.x), up * (bh.y / hh.y), fr * (bh.z / hh.z))
	return Transform3D(b, bc - b * hc)


## Uzuv eşlemesi: insan parçası A->B ekseni + dış yön ho -> canavar parçası (0 -> v), dış yön bo
static func _limb_xf(A: Vector3, B: Vector3, ho: Vector3, v: Vector3, bo: Vector3, sr: float, amax := 0.0) -> Transform3D:
	var a = (B - A).normalized()
	var o = (ho - a * ho.dot(a)).normalized()
	var tt = a.cross(o)
	var a2 = v.normalized()
	var o2 = bo - a2 * bo.dot(a2)
	if o2.length() < 0.05:
		o2 = Vector3.UP - a2 * a2.y
	o2 = o2.normalized()
	var t2 = a2.cross(o2)
	var sa = v.length() / maxf(0.001, (B - A).length())
	if amax > 0.0:
		sa = minf(sa, amax)   # omuz parçaları gövde ölçüsünü aşmaz: uzun kollu canavarda omuzluk kolun üst kısmını örter
	sr = minf(sr, sa * 1.3)   # uzuv kalın olsa da parça boyuna göre fazla genişlemez (omuz plakası pano gibi durmasın)
	var hb = Basis(a, o, tt)
	var b = Basis(a2 * sa, o2 * sr, t2 * sr) * hb.inverse()
	return Transform3D(b, -(b * A))


func wear(r: BeastRig, s: Susanoo) -> void:
	rig = r
	sn = s
	sn.visible = false
	var am: ShaderMaterial = sn.mat.duplicate()
	am.set_shader_parameter("flesh_a", 0.3)
	am.set_shader_parameter("density", 1.5)
	wmats = [am, sn.gmat, Susanoo._eye_mat]
	pmat = sn.bmat.duplicate()
	pmat.set_shader_parameter("force_kind", 0.8)
	var recs: Array = Susanoo._parts_cache.get(sn.parts_key, [])
	if rig.hips == null or rig.chest == null or rig.head == null:
		return
	stops = [rig.chest, rig.head]
	for a0 in rig.arms:
		stops.append(a0["sh"]); stops.append(a0["el"])
	for l0 in rig.legs:
		stops.append(l0["hip"]); stops.append(l0["kn"])
	for tl0 in rig.tails:
		if not tl0.is_empty():
			stops.append(tl0[0])
	# ---- gövde çerçevesi: omurga yönü (kalça -> göğüs), ön yüz (dik canavarda ileri, dört ayaklıda karın)
	var d = rig.chest.position.normalized() if rig.chest.position.length() > 0.01 else Vector3.UP
	var fw = Vector3(0, 0, -1)
	var f = fw - d * fw.dot(d)
	if f.length() < 0.35:
		f = Vector3(0, -1, 0) - d * (-d.y)
	f = f.normalized()
	var rx = d.cross(f).normalized()
	# göğüs kutusu
	var cv = _verts(rig.chest)
	var torso: Node3D = rig.chest
	var round_body = cv.size() < 30
	if round_body:
		torso = rig.hips
		cv = _verts(rig.hips)
	var sx_ = _span(cv, rx); var sy_ = _span(cv, d); var sz_ = _span(cv, f)
	var cc = rx * sx_.x + d * sy_.x + f * sz_.x
	var chh = Vector3(sx_.y, sy_.y, sz_.y) * 1.1
	var chest_xf = _box_xf(Vector3(0, 1.24, 0.0), Vector3(0.3, 0.24, 0.19), cc, chh, rx, d, f)
	# kalça kutusu
	var hv = _verts(rig.hips)
	var hx_ = _span(hv, rx); var hy_ = _span(hv, d); var hz_ = _span(hv, f)
	var hc = rx * hx_.x + d * (hy_.x + hy_.y * (-0.55 if round_body else 0.3)) + f * hz_.x
	var hsx = hx_.y / 0.25 * 1.12; var hsz = hz_.y / 0.19 * 1.12
	var hb = Basis(rx * hsx, d * (hsx + hsz) * 0.5, f * hsz)
	var hips_xf = Transform3D(hb, hc - hb * Vector3(0, 0.99, 0))
	# baş kutusu (baş her canavarda dik: yukarı Y, ileri -Z)
	var kv = _verts(rig.head)
	var kx = _span(kv, Vector3.RIGHT); var ky = _span(kv, Vector3.UP); var kz = _span(kv, Vector3(0, 0, -1))
	var ks = Vector3(kx.y / 0.12, ky.y / 0.175, kz.y / 0.135)
	var ku = pow(ks.x * ks.y * ks.z, 1.0 / 3.0)
	ks = Vector3(clampf(ks.x, 0.8 * ku, 1.4 * ku), clampf(ks.y, 0.8 * ku, 1.4 * ku), clampf(ks.z, 0.8 * ku, 1.4 * ku)) * 1.12
	var kb = Basis(Vector3.LEFT * ks.x, Vector3.UP * ks.y, Vector3(0, 0, -1) * ks.z)
	var head_xf = Transform3D(kb, Vector3(kx.x, ky.x, -kz.x) - kb * Vector3(0, 1.67, 0.015))
	if OS.get_environment("BSDBG") != "":
		print("BSDBG %s d=%s f=%s rx=%s | gogus n=%d c=%s h=%s | kalca n=%d c=%s | bas n=%d c=(%.2f,%.2f,%.2f) h=(%.2f,%.2f,%.2f) ks=%s" % [rig.id, d, f, rx, cv.size(), cc, chh, hv.size(), hc, kv.size(), kx.x, ky.x, -kz.x, kx.y, ky.y, kz.y, ks])
		for ch in rig.head.get_children():
			print("BSDBG   bas cocuk %s %s" % [ch.name, ch.get_class()])
	# ---- uzuvlar: kol (varsa gerçek kol; yoksa sırttan çıkan Susanoo kolları) ve bacaklar
	var arm_seg := {}    # "Left"/"Right" -> [üst düğüm, üst eşleme, alt düğüm, alt eşleme]
	var leg_seg: Array = []
	var arm_len := 0.0
	for sd in ["Left", "Right"]:
		var hsx2 = 1.0 if sd == "Left" else -1.0
		var bside = -hsx2   # insan solu (+X) canavarın -X yanına düşer (baş / gövde 180° dönük)
		var ua = sn._bp(sd + "UpperArm"); var la = sn._bp(sd + "LowerArm"); var lh = sn._bp(sd + "Hand")
		var sh: Node3D = null
		var el: Node3D = null
		for a in rig.arms:
			if signf(float(a["side"])) == bside:
				sh = a["sh"]; el = a["el"]
		if sh == null:
			# sırttan çıkan Susanoo kolu: omuz göğsün sırt tarafında, kol yukarı-dışa çıkıp ileri uzanır
			var L = maxf(chh.x, chh.y) * 1.25
			sh = Node3D.new()
			torso.add_child(sh)
			made.append(sh)
			sh.position = cc - f * chh.z * 0.85 + d * chh.y * 0.45 + Vector3(bside, 0, 0) * chh.x * 0.6
			var v1 = (-f * 0.55 + Vector3(bside, 0, 0) * 0.6 + Vector3.UP * 0.5).normalized() * L
			el = Node3D.new()
			sh.add_child(el)
			el.position = v1
			el.set_meta("v2", (Vector3(0, 0, -1) * 0.9 + Vector3.UP * 0.25 - Vector3(bside, 0, 0) * 0.12).normalized() * L * 1.15)
			back_arms.append({"sh": sh, "side": bside, "base": sh.basis})
		var v1b: Vector3 = el.position
		var v2b: Vector3 = el.get_meta("v2") if el.has_meta("v2") else _lower_vec(el, v1b)
		var out1 = Vector3(bside, 0, 0)
		var r1 = _radius(sh, v1b) if not sh in made else v1b.length() * 0.19
		var r2 = _radius(el, v2b) if not sh in made else v2b.length() * 0.17
		var x1 = _limb_xf(ua, la, Vector3.UP, v1b, out1, maxf(r1 / 0.085, v1b.length() / 0.22 * 0.45) * 1.1, pow(chh.x / 0.3 * chh.y / 0.24 * chh.z / 0.19, 1.0 / 3.0) * 0.8)
		var x2 = _limb_xf(la, lh, Vector3.UP, v2b, out1, maxf(r2 / 0.08, v2b.length() / 0.25 * 0.45) * 1.1)
		arm_seg[sd] = [sh, x1, el, x2]
		arm_len = maxf(arm_len, v2b.length())
		if sn.tier >= 4:
			for lg in rig.legs:
				if signf(float(lg["side"])) != bside:
					continue
				var hipn: Node3D = lg["hip"]; var kn: Node3D = lg["kn"]
				var ul = sn._bp(sd + "UpperLeg"); var ll = sn._bp(sd + "LowerLeg"); var ft = sn._bp(sd + "Foot")
				var lv1: Vector3 = kn.position
				var lv2 = _lower_vec(kn, lv1)
				var lx1 = _limb_xf(ul, ll, Vector3(0, 0, 1), lv1, Vector3(0, 0, -1), maxf(_radius(hipn, lv1) / 0.125, 0.2) * 1.08)
				var lx2 = _limb_xf(ll, ft, Vector3(0, 0, 1), lv2, Vector3(0, 0, -1), maxf(_radius(kn, lv2) / 0.095, 0.2) * 1.08)
				leg_seg.append([sd, hipn, lx1, kn, lx2])
	# ---- parçaları yerleştir
	for rc in recs:
		var bone: String = rc[0]
		var mesh: Mesh = rc[1]
		var kind: int = rc[2]
		if bone == "Head":
			_put(rig.head, mesh, kind, head_xf)
		elif bone in ["Chest", "UpperChest", "Neck", ""]:
			_put(torso, mesh, kind, chest_xf)
		elif bone == "Hips":
			_put(rig.hips, mesh, kind, hips_xf)
		else:
			var sd = "Left" if bone.begins_with("Left") else "Right"
			var rest = bone.substr(sd.length())
			if rest.begins_with("UpperArm") and arm_seg.has(sd):
				_put(arm_seg[sd][0], mesh, kind, arm_seg[sd][1])
			elif _is_arm(rest) and arm_seg.has(sd):
				_put(arm_seg[sd][2], mesh, kind, arm_seg[sd][3])
			else:
				for ls in leg_seg:
					if ls[0] != sd:
						continue
					if rest.begins_with("UpperLeg"):
						_put(ls[1], mesh, kind, ls[2])
					elif rest.begins_with("LowerLeg"):
						_put(ls[3], mesh, kind, ls[4])
	# ---- silah: Susanoo'nun silahı kolun ucunda (kolu olmayan canavarda sırt kollarında)
	var wm: Array = Susanoo.W_MODEL.get(String(sn.cfg.get("weapon", "kilic")), ["", ""])
	if sn.tier >= 3:
		for k in 2:
			if String(wm[k]) == "":
				continue
			var sd = "Right" if k == 0 else "Left"
			if not arm_seg.has(sd):
				continue
			var el2: Node3D = arm_seg[sd][2]
			var x2b: Transform3D = arm_seg[sd][3]
			var hand = x2b * sn._bp(sd + "Hand")
			var wmesh: Mesh = CharacterModel.weapon_mesh(String(wm[k]))
			if wmesh == null:
				continue
			var ws = arm_len / 0.25 * 0.5
			var up = (Vector3(0, 0, -1) * 0.75 + Vector3.UP * 0.66).normalized()
			var side = up.cross(Vector3.RIGHT).normalized()
			var wi = MeshInstance3D.new()
			wi.mesh = wmesh
			wi.transform = Transform3D(Basis(side.cross(up) * ws, up * ws, side * ws), hand)
			wi.material_override = pmat
			wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			el2.add_child(wi)
			made.append(wi)
	# ---- canavarın bütün bedeni Susanoo enerjisine bürünür (ince katman: altındaki canavar seçilir), kuyruklar plaka gibi boyanır
	var film: ShaderMaterial = sn.bmat.duplicate()
	film.set_shader_parameter("all_a", 0.3)
	var tail_nodes: Array = []
	for tl in rig.tails:
		for seg in tl:
			if is_instance_valid(seg):
				tail_nodes.append(seg)
	for mi in rig.find_children("*", "MeshInstance3D", true, false):
		if mi in made or not mi.is_visible_in_tree():
			continue
		var nm = String(mi.get_parent().name).to_lower()
		if nm.begins_with("weak") or nm.begins_with("carpisma"):
			continue
		var in_tail = false
		var q: Node = mi.get_parent()
		while q != null and q != rig:
			if q in tail_nodes:
				in_tail = true
				break
			q = q.get_parent()
		restored.append([mi, mi.material_overlay])
		mi.material_overlay = pmat if in_tail else film


static func _is_arm(rest: String) -> bool:
	for a in ARM_BONES:
		if rest.begins_with(a):
			return true
	return false


## Alt uzuv parçasının yönü ve boyu: düğümün kendi ağlarının en uzak ucuna doğru
func _lower_vec(n: Node3D, upper: Vector3) -> Vector3:
	var vs = _verts(n)
	if vs.is_empty():
		return upper
	var m = Vector3.ZERO
	for v in vs:
		m += v
	m /= vs.size()
	if m.length() < 0.01:
		return upper
	var ax = m.normalized()
	var sp = _span(vs, ax)
	return ax * maxf(0.2, sp.x + sp.y)


## Uzuv parçasının kalınlığı: köşelerin eksene ortalama uzaklığı
func _radius(n: Node3D, v: Vector3) -> float:
	var vs = _verts(n)
	if vs.is_empty():
		return v.length() * 0.2
	var ax = v.normalized()
	var s := 0.0
	var c := 0
	for q in vs:
		var along = q.dot(ax)
		if along < 0.0 or along > v.length():
			continue
		s += (q - ax * along).length()
		c += 1
	return s / c if c > 0 else v.length() * 0.2


func _process(dt: float) -> void:
	t += dt
	if not is_instance_valid(rig) or not is_instance_valid(sn):
		return
	if sn.visible:
		sn.visible = false
	# sırt kolları: hafif salınır, canavar vururken silahı öne savurur
	var k = sin(PI * clampf(rig.action_k(), 0.0, 1.0)) if rig.action != "" else 0.0
	for a in back_arms:
		var sh: Node3D = a["sh"]
		if not is_instance_valid(sh):
			continue
		var sway = sin(t * 1.3 + float(a["side"])) * 0.05
		sh.basis = (a["base"] as Basis) * Basis(Vector3.RIGHT, sway - k * 0.9) * Basis(Vector3.UP, -float(a["side"]) * k * 0.35)
