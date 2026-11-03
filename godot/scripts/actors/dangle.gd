class_name Dangle
extends Node3D
## İkincil hareket (saç tutamı, bant kuyruğu, örgü, uzun saç, kumaş ucu...): sabit bir mesh'in sarkan kısımları
## küçük bir iskelete derilenir, iskeletin zincirleri Verlet fiziğiyle (kusarigama zinciri gibi) sürülür.
## Kök (zincirin ilk noktası) bu düğüme sabittir: düğüm bir kemiğe takılıysa saç/kumaş o kemikle gelir, uçları gecikir,
## yerçekimiyle sarkar, koşuda/düşüşte hava sürtünmesiyle savrulur, darbe ve rüzgârla oynar, gövde kürelerinin içine girmez.
## Kurulum: Dangle.build(mesh, chains, assign) -> önbelleklenebilir paket; Dangle.make(paket, malzeme) -> düğüm.
## CharacterModel her kare step() çağırır (yalnız kameraya yakınken).

static var wind := Vector3.ZERO      # dünya rüzgârı (ivme, m/s²): hava durumu / fırtına ayarlar
static var _gusts: Array = []        # [konum, yön*güç, yarıçap, bitiş zamanı] (Fūton vb. ani esinti)

var skel: Skeleton3D
var mi: MeshInstance3D
var chains: Array = []     # [{rest: PackedVector3Array (yerel), b0: ilk kemik, stiff, damp, grav, drag, len: PackedFloat32Array}]
var _p: Array = []         # her zincir için dünya noktaları
var _o: Array = []         # önceki kare noktaları
var _live := false
var _t := 0.0
var ext_root := -1                 # >= 0: dış iskelet modu (kemikler karakter iskeletine eklendi, kök bu kemiği izler)
var ext_rest_inv := Transform3D.IDENTITY
var _nbr: Array = []               # dilim zincirleri için komşu zincir indeksleri


## Dilim zincirlerinin ("sec", "nsec") komşularını bul
func _link() -> void:
	_nbr = []
	var by = {}
	for ci in chains.size():
		if chains[ci].has("sec"):
			by[int(chains[ci]["sec"])] = ci
	if by.size() < 2:
		return
	for ci in chains.size():
		var nb = []
		if chains[ci].has("sec"):
			var sn = int(chains[ci]["nsec"])
			for dsec in [-1, 1]:
				var j = by.get(posmod(int(chains[ci]["sec"]) + dsec, sn), -1)
				if j >= 0 and j != ci and not j in nb:
					nb.append(j)
		_nbr.append(nb)


## mesh: sabit ArrayMesh (yerel uzay). chains: [{pts: PackedVector3Array, stiff, damp, grav, drag}]
## assign(i, v) -> [[zincir, s], ...] (en çok 2 zincir; s = zincir boyunca kesirli nokta indeksi; boş = sabit kök)
## ve w: zincir ağırlığı. Dönüş: {"mesh", "chains", "skin", "nb"}.
static func build(mesh: ArrayMesh, chain_defs: Array, assign: Callable) -> Dictionary:
	var out = {"mesh": null, "chains": [], "nb": 1}
	var b0 = 1
	for c in chain_defs:
		var pts: PackedVector3Array = c["pts"]
		if pts.size() < 2:
			continue
		var cc = c.duplicate()
		cc["b0"] = b0
		b0 += pts.size()
		out["chains"].append(cc)
	out["nb"] = b0
	if out["chains"].is_empty():
		return {}
	var am = ArrayMesh.new()
	for si in mesh.get_surface_count():
		var arr = mesh.surface_get_arrays(si)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones = PackedInt32Array(); var weights = PackedFloat32Array()
		bones.resize(v.size() * 4); weights.resize(v.size() * 4)
		for i in v.size():
			var asg: Array = assign.call(i, v[i], si)
			var ent = []   # [kemik, ağırlık]
			var tot_w = 0.0
			for a in asg:
				var ci: int = a[0]
				if ci < 0 or ci >= out["chains"].size():
					continue
				var ch: Dictionary = out["chains"][ci]
				var n: int = ch["pts"].size()
				var s = clampf(float(a[1]), 0.0, float(n - 1))
				var k = mini(int(floor(s)), n - 2)
				var f = s - k
				var w = float(a[2]) if a.size() > 2 else 1.0
				ent.append([ch["b0"] + k, w * (1.0 - f)])
				ent.append([ch["b0"] + k + 1, w * f])
				tot_w += w
			if tot_w < 1.0:
				ent.append([0, 1.0 - tot_w])
			ent.sort_custom(func(x, y): return x[1] > y[1])
			var sum = 0.0
			for k in 4:
				if k < ent.size():
					sum += ent[k][1]
			for k in 4:
				bones[i * 4 + k] = ent[k][0] if k < ent.size() else 0
				weights[i * 4 + k] = (ent[k][1] / maxf(sum, 0.0001)) if k < ent.size() else 0.0
		arr[Mesh.ARRAY_BONES] = bones
		arr[Mesh.ARRAY_WEIGHTS] = weights
		var fmt = mesh.surface_get_format(si)
		var cmask = 0
		for c in 4:
			cmask |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << (Mesh.ARRAY_FORMAT_CUSTOM_BASE + c * Mesh.ARRAY_FORMAT_CUSTOM_BITS)
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, fmt & cmask)
		am.surface_set_material(si, mesh.surface_get_material(si))
	out["mesh"] = am
	var skin = Skin.new()
	skin.add_bind(0, Transform3D.IDENTITY)
	for ch in out["chains"]:
		var pts: PackedVector3Array = ch["pts"]
		for k in pts.size():
			skin.add_bind(ch["b0"] + k, Transform3D(Basis.IDENTITY, -pts[k]))
	out["skin"] = skin
	return out


static func make(pack: Dictionary, mat: Material = null) -> Dangle:
	if pack.is_empty():
		return null
	var d = Dangle.new()
	d.name = "Dangle"
	d.skel = Skeleton3D.new()
	d.add_child(d.skel)
	d.skel.add_bone("root")
	for ch in pack["chains"]:
		var pts: PackedVector3Array = ch["pts"]
		var lens = PackedFloat32Array()
		for k in pts.size():
			var bi = d.skel.add_bone("c%d" % (ch["b0"] + k))
			d.skel.set_bone_rest(bi, Transform3D(Basis.IDENTITY, pts[k]))
			d.skel.set_bone_pose_position(bi, pts[k])
			if k > 0:
				lens.append(pts[k].distance_to(pts[k - 1]))
		var c = ch.duplicate()
		c["rest"] = pts
		c["len"] = lens
		d.chains.append(c)
	d._link()
	d.mi = MeshInstance3D.new()
	d.mi.mesh = pack["mesh"]
	d.mi.skin = pack["skin"]
	d.skel.add_child(d.mi)
	d.mi.skeleton = NodePath("..")
	if mat:
		d.mi.material_override = mat
	return d


## Dış iskelet modu: zincir kemikleri sk'ye zaten eklendi (defs[i]["b0"] = ilk kemik, pts iskelet uzayında);
## kök çerçevesi root_bone'u izler (etek kalçayla gelir). Mesh deri ağırlıkları çağıran tarafta.
static func make_ext(sk: Skeleton3D, root_bone: int, defs: Array) -> Dangle:
	var d = Dangle.new()
	d.name = "DangleExt"
	d.skel = sk
	d.ext_root = root_bone
	d.ext_rest_inv = sk.get_bone_global_rest(root_bone).affine_inverse()
	for ch in defs:
		var pts: PackedVector3Array = ch["pts"]
		var lens = PackedFloat32Array()
		for k in range(1, pts.size()):
			lens.append(pts[k].distance_to(pts[k - 1]))
		var c = ch.duplicate()
		c["rest"] = pts
		c["len"] = lens
		d.chains.append(c)
	d._link()
	return d


## Ani esinti (Fūton, patlama): yarıçap içindeki tüm sarkan parçalara itme
static func gust(pos: Vector3, push: Vector3, radius: float, dur := 0.6) -> void:
	_gusts.append([pos, push, radius, Time.get_ticks_msec() / 1000.0 + dur, 0.0])


## Patlama: merkezden dışa itme
static func blast(pos: Vector3, strength: float, radius: float, dur := 0.35) -> void:
	_gusts.append([pos, Vector3.ZERO, radius, Time.get_ticks_msec() / 1000.0 + dur, strength])


## Darbe: tüm noktalara anlık hız (dünya, m/s)
func kick(v: Vector3) -> void:
	if not _live:
		return
	for ci in chains.size():
		var o: PackedVector3Array = _o[ci]
		for k in range(1, o.size()):
			o[k] -= v * (0.016 * (0.4 + 0.6 * float(k) / (o.size() - 1)))
		_o[ci] = o


func reset() -> void:
	_live = false


## cols: [[dünya merkezi, yarıçap], ...]
func step(dt: float, cols: Array) -> void:
	if chains.is_empty() or not is_visible_in_tree() or skel == null:
		return
	var xf = skel.global_transform
	var inv = xf.affine_inverse()
	if ext_root >= 0:
		xf = xf * skel.get_bone_global_pose(ext_root) * ext_rest_inv
	var h = clampf(dt, 0.001, 0.033)
	_t += h
	if not _live or (_p.size() > 0 and (_p[0][0] as Vector3).distance_to(xf * (chains[0]["rest"] as PackedVector3Array)[0]) > 1.5):
		_p.clear(); _o.clear()
		for ch in chains:
			ch.erase("_lq")
			ch.erase("_rv")
			ch.erase("_ra")
			var pw = PackedVector3Array()
			for q in ch["rest"]:
				pw.append(xf * q)
			_p.append(pw)
			_o.append(pw.duplicate())
		_live = true
	var sc = xf.basis.get_scale().x
	var now = Time.get_ticks_msec() / 1000.0
	var ext = wind
	if not _gusts.is_empty():
		var keep = []
		for g in _gusts:
			if now < g[3]:
				keep.append(g)
				var dv = xf.origin - (g[0] as Vector3)
				var dd = dv.length()
				if dd < g[2]:
					ext += (g[1] as Vector3) * (1.0 - dd / g[2])
					if g[4] > 0.0 and dd > 0.01:
						ext += dv / dd * float(g[4]) * (1.0 - dd / g[2])
		_gusts = keep
	for ci in chains.size():
		var ch: Dictionary = chains[ci]
		var rest: PackedVector3Array = ch["rest"]
		var lens: PackedFloat32Array = ch["len"]
		var p: PackedVector3Array = _p[ci]
		var o: PackedVector3Array = _o[ci]
		var n = rest.size()
		# kökten uca sertlik azalır (kök başı izler, uç gecikip kıvrılır); hız sönümü güçlü (yay gibi zıplamasın)
		var s_root = float(ch.get("stiff", 0.3))
		var s_tip = float(ch.get("stiff_tip", s_root * 0.4))
		var damp = pow(float(ch.get("damp", 0.82)), h * 60.0)
		var grav = Vector3.DOWN * 9.8 * float(ch.get("grav", 0.2))
		var drag = float(ch.get("drag", 1.0))
		var air = float(ch.get("air", 0.6))
		var follow = float(ch.get("follow", 0.65))
		var flut = 0.75 + 0.25 * sin(_t * 4.3 + ci * 1.7)
		var col_from = int(ch.get("col_from", 2))
		var cr = float(ch.get("col_r", 0.015))
		var prev_root: Vector3 = p[0]
		p[0] = xf * rest[0]
		o[0] = p[0]
		# kök hareketinin büyük kısmı doğrudan taşınır (konum + dönüş): yalnız kalan pay gecikme olur
		var rq = xf.basis.get_rotation_quaternion()
		var lq: Quaternion = ch.get("_lq", rq)
		ch["_lq"] = rq
		# konum tam taşınır (sabit hızla koşarken saç bayrak gibi geride kalmaz); dönüşün follow kadarı taşınır.
		# gecikme/savrulma yalnız kökün İVMESİNDEN gelir (kalkışta geriye, duruşta öne) + hava direnci
		var part = Quaternion.IDENTITY.slerp((rq * lq.inverse()).normalized(), follow)
		if absf(rq.dot(lq)) > 0.999995:
			var dl = p[0] - prev_root
			for k in range(1, n):
				p[k] += dl
				o[k] += dl
		else:
			for k in range(1, n):
				p[k] = p[0] + part * (p[k] - prev_root)
				o[k] = p[0] + part * (o[k] - prev_root)
		var hr = maxf(dt, 0.001)   # gerçek kare süresi (takılmada kırpılmış h ile hız şişmesin)
		var rvel = (p[0] - prev_root) / hr
		if rvel.length() > 14.0:
			rvel = rvel.normalized() * 14.0
		var lv: Vector3 = ch.get("_rv", rvel)
		ch["_rv"] = rvel
		var ra: Vector3 = (ch.get("_ra", Vector3.ZERO) as Vector3).lerp((rvel - lv) / maxf(hr, 0.016), 0.3)   # süzülmüş ivme (adım sarsıntısı zıplatmasın)
		ch["_ra"] = ra
		var racc = Vector3(ra.x, ra.y * 0.35, ra.z)
		if racc.length() > 40.0:
			racc = racc.normalized() * 40.0
		var inertia = float(ch.get("inertia", 0.8))
		# yalnız zincire erişebilecek küreler (saç bacak kürelerine bakmaz)
		# zincirin dinlenme sınır küresi (merkez + yarıçap) — hareket payıyla
		if not ch.has("_bc"):
			var bc = Vector3.ZERO
			for q in rest:
				bc += q
			bc /= n
			var br = 0.0
			for q in rest:
				br = maxf(br, q.distance_to(bc))
			ch["_bc"] = bc
			ch["_br"] = br
		var bcw: Vector3 = xf * (ch["_bc"] as Vector3)
		var brw = float(ch["_br"]) * sc * 1.6 + cr + 0.04
		var near = []
		for c in cols:
			if bcw.distance_to(c[0]) < brw + float(c[1]):
				near.append(c)
		ch["_near"] = near
		# kare süresine göre sertlik dizisi (önbellek)
		var stv: PackedFloat32Array = ch.get("_stv", PackedFloat32Array())
		if stv.size() != n or absf(float(ch.get("_sth", 0.0)) - h) > 0.002:
			stv = PackedFloat32Array()
			stv.resize(n)
			for k in range(1, n):
				stv[k] = 1.0 - pow(1.0 - lerpf(s_root, s_tip, float(k - 1) / maxf(n - 2, 1)), h * 60.0)
			ch["_stv"] = stv
			ch["_sth"] = h
		var soft = false
		for c in near:
			if c[2]:
				soft = true
		var prev_rp = Vector3.ZERO
		for k in range(1, n):
			var stiff = stv[k]
			var cur = p[k]
			var vel = (cur - o[k]) / h
			o[k] = cur
			var acc = grav + ext * flut - vel * drag - rvel * air - racc * inertia
			cur += vel * h * damp + acc * h * h
			# şekil hafızası: üst parçanın şimdiki yönüne göre (dalga gibi bükülür, tahta gibi tek parça dönmez)
			var seg = xf.basis * (rest[k] - rest[k - 1])
			var tgt = p[k - 1] + seg
			if k >= 2:
				# üst parçanın yön değişimini (ucuz yaklaşım) bu parçaya da kısmen aktar
				var cp = (p[k - 1] - p[k - 2]).normalized()
				tgt += (cp - prev_rp) * (seg.length() * 0.6)
			prev_rp = seg.normalized()
			cur = cur.lerp(tgt, stiff)
			# boy sabit
			var dv = cur - p[k - 1]
			var L = dv.length()
			if L > 0.00001:
				cur = p[k - 1] + dv * (lens[k - 1] * sc / L)
			if k >= col_from:
				var rw = xf * rest[k] if soft else Vector3.ZERO   # yumuşak küre (kafa/boyun): dinlenme konumu zaten içerdeyse (kafa derisine yatık saç) o kadar içeri izin ver
				for c in near:
					var cc: Vector3 = c[0]
					var rr = float(c[1]) + cr
					if c[2]:
						rr = minf(rr, rw.distance_to(cc))
					var dc = cur - cc
					var dl = dc.length()
					if dl < rr and dl > 0.00001:
						cur = cc + dc * (rr / dl)
			p[k] = cur
		_p[ci] = p
		_o[ci] = o
	# komşu dilim bağı (etek, uzun saç): bir dilim tek başına sivri kanat gibi kalkmasın, kumaş bütün olarak oynasın
	if _nbr.size() == chains.size():
		var offs = []
		for ci in chains.size():
			var rest: PackedVector3Array = chains[ci]["rest"]
			var o2 = PackedVector3Array()
			for k in rest.size():
				o2.append(_p[ci][k] - xf * rest[k])
			offs.append(o2)
		for ci in chains.size():
			var nb: Array = _nbr[ci]
			if nb.is_empty():
				continue
			var ch: Dictionary = chains[ci]
			var rest: PackedVector3Array = ch["rest"]
			var cpl = float(ch.get("couple", 0.5))
			var cr = float(ch.get("col_r", 0.015))
			var p: PackedVector3Array = _p[ci]
			for k in range(1, rest.size()):
				var avg = Vector3.ZERO
				var cnt = 0
				for j in nb:
					if k < (offs[j] as PackedVector3Array).size():
						avg += offs[j][k]
						cnt += 1
				if cnt == 0:
					continue
				var cur = xf * rest[k] + offs[ci][k].lerp(avg / cnt, cpl)
				for c in ch["_near"]:
					if c[2]:
						continue
					var cc: Vector3 = c[0]
					var rr = float(c[1]) + cr
					var dc = cur - cc
					var dl = dc.length()
					if dl < rr and dl > 0.00001:
						cur = cc + dc * (rr / dl)
				p[k] = cur
			_p[ci] = p
	for ci in chains.size():
		var ch: Dictionary = chains[ci]
		var rest: PackedVector3Array = ch["rest"]
		var n = rest.size()
		var p: PackedVector3Array = _p[ci]
		# kemikler: nokta konumu + dinlenme yönünden şimdiki yöne dönüş
		var b0: int = ch["b0"]
		var lp = PackedVector3Array()
		for k in n:
			lp.append(inv * p[k])
		for k in n:
			var a = mini(k, n - 2)
			var rd = (rest[a + 1] - rest[a]).normalized()
			var cd = (lp[a + 1] - lp[a]).normalized()
			var q = Quaternion.IDENTITY
			if rd.dot(cd) < 0.99999:
				q = Quaternion(rd, cd) if rd.dot(cd) > -0.999 else Quaternion(Vector3.UP, PI)
			skel.set_bone_pose_position(b0 + k, lp[k])
			skel.set_bone_pose_rotation(b0 + k, q)


# ------------------------------------------------------------------ kurulum yardımcıları

## Polyline üzerinde en yakın nokta: [kesirli indeks, uzaklık]
static func project(pts: PackedVector3Array, v: Vector3) -> Array:
	var best = 0.0
	var bd = 1e9
	for k in pts.size() - 1:
		var a = pts[k]; var b = pts[k + 1]
		var ab = b - a
		var t = clampf((v - a).dot(ab) / maxf(ab.length_squared(), 1e-8), 0.0, 1.0)
		var d = v.distance_to(a + ab * t)
		if d < bd:
			bd = d
			best = k + t
	# uç ötesi: son segmentin uzantısı
	return [best, bd]


## Uzun saç (VRoid saç mesh'i): kök yüksekliğinin altında kalan kısmı yatay dilimlerde zincirlere böler.
## to_model: mesh yerel -> model uzayı (Y yukarı, +Z yüz); center: kafa merkezi (model). Dönüş build() paketi ya da {}.
## Dilim zincirleri (uzun saç, etek): kök yüksekliğinin altında kalan köşeler yatay dilimlere ayrılır, her dilimde aşağı inen zincir.
## mv_list: yüzey başına köşe konumları (zincir uzayında: Y yukarı). Dönüş {defs, assign(i, si) -> [[zincir, s, ağırlık]...]} ya da {}.
static func sector_chains(mv_list: Array, center: Vector3, root_y: float, opts := {}) -> Dictionary:
	var nsec = int(opts.get("sectors", 6))
	var npt = int(opts.get("points", 5))
	var min_len = float(opts.get("min_len", 0.1))
	var miny = 1e9
	for mv in mv_list:
		for p in mv:
			miny = minf(miny, p.y)
	if root_y - miny < min_len:
		return {}
	var yaw_of = func(p: Vector3) -> float: return wrapf(atan2(p.x - center.x, p.z - center.z), 0.0, TAU)
	var sec_min = []
	for s in nsec:
		sec_min.append(root_y)
	for mv in mv_list:
		for p in mv:
			if p.y < root_y:
				var s = int(yaw_of.call(p) / TAU * nsec) % nsec
				sec_min[s] = minf(sec_min[s], p.y)
	var defs = []
	var sec_chain = []
	for s in nsec:
		if root_y - sec_min[s] < min_len:
			sec_chain.append(-1)
			continue
		var span = root_y - sec_min[s]
		var sums = []
		for k in npt:
			sums.append([Vector3.ZERO, 0])
		for mv in mv_list:
			for p in mv:
				if p.y >= root_y + 0.02 or p.y < sec_min[s] - 0.001:
					continue
				if int(yaw_of.call(p) / TAU * nsec) % nsec != s:
					continue
				var k = clampi(int(round((root_y - p.y) / span * (npt - 1))), 0, npt - 1)
				sums[k][0] += p
				sums[k][1] += 1
		var pts = PackedVector3Array()
		var last = Vector3.ZERO
		for k in npt:
			var y = root_y - span * float(k) / (npt - 1)
			var q: Vector3
			if sums[k][1] > 0:
				q = sums[k][0] / sums[k][1]
			elif k > 0:
				q = last + Vector3(0, -span / (npt - 1), 0)
			else:
				var a = (float(s) + 0.5) / nsec * TAU
				q = center + Vector3(sin(a), 0, cos(a)) * 0.09
			q.y = y
			last = q
			pts.append(q)
		sec_chain.append(defs.size())
		var dd = opts.get("def", {}).duplicate()
		if opts.get("auto", false):
			dd = CharacterModel.hair_profile(span)   # saçın ortak profili (tutamlarla aynı)
			dd["col_r"] = 0.035
		dd["pts"] = pts
		dd["sec"] = s
		dd["nsec"] = nsec
		defs.append(dd)
	if defs.is_empty():
		return {}
	var fade = float(opts.get("fade", 0.06))
	var assign = func(i: int, si: int) -> Array:
		var p: Vector3 = mv_list[si][i]
		if p.y > root_y + fade:
			return []
		var y = yaw_of.call(p) / TAU * nsec - 0.5
		var s0 = int(floor(y))
		var f = y - s0
		var res = []
		for e in [[posmod(s0, nsec), 1.0 - f], [posmod(s0 + 1, nsec), f]]:
			var ci = sec_chain[e[0]]
			if ci < 0 or e[1] <= 0.001:
				continue
			var span = root_y - sec_min[e[0]]
			res.append([ci, clampf((root_y - p.y) / span * (npt - 1), 0.0, npt - 1.0), e[1]])
		if res.is_empty():
			return []
		var tw = 0.0
		for r in res:
			tw += r[2]
		var fw = clampf((root_y + fade - p.y) / (fade * 2.0), 0.0, 1.0)   # kökte yumuşak geçiş
		for r in res:
			r[2] = r[2] / tw * fw
		return res
	return {"defs": defs, "assign": assign}


## Uzun saç (VRoid saç mesh'i): to_model: mesh yerel -> model uzayı (Y yukarı, +Z yüz); center: kafa merkezi (model).
static func sectors(mesh: ArrayMesh, to_model: Transform3D, center: Vector3, root_y: float, opts := {}) -> Dictionary:
	var allv = []
	for si in mesh.get_surface_count():
		var v: PackedVector3Array = mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
		var mv = PackedVector3Array()
		mv.resize(v.size())
		for i in v.size():
			mv[i] = to_model * v[i]
		allv.append(mv)
	var o = opts.duplicate()
	o["def"] = {"stiff": 0.32, "stiff_tip": 0.14, "damp": 0.8, "grav": 0.4, "drag": 1.0, "air": 0.15, "follow": 0.65, "col_r": 0.035, "col_from": 1}
	o["auto"] = true
	var sc = sector_chains(allv, center, root_y, o)
	if sc.is_empty():
		return {}
	var inv = to_model.affine_inverse()
	for d in sc["defs"]:
		var lp = PackedVector3Array()
		for q in d["pts"]:
			lp.append(inv * q)
		d["pts"] = lp
	var asg: Callable = sc["assign"]
	return build(mesh, sc["defs"], func(i, _v, si): return asg.call(i, si))
