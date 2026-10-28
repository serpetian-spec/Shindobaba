extends Node
## Dünya hasarı (autoload "WorldDamage"): jutsu ve büyük saldırılar ağaçları yakar, devirir, eğer; evleri tutuşturur ve yıkar.
## Girdi: Combat.hit_sphere ve Projectile çarpmaları -> impact(konum, yarıçap, info).
## Ağaçlar Vegetation MultiMesh örnekleridir: örnek gizlenir/karartılır, yerine vekil (devrilen ağaç, kömürleşmiş gövde) konur.
## Evler HouseKit.Placer MultiMesh örnekleridir: kayıtla bulunur, yanar (renk kararır), yıkılınca moloz yığını + çarpışma kalır.
## Her şey REGEN saniye sonra (oyuncu uzaktayken) eski hâline döner; dünya kalıcı olarak harabeye dönmez.

const FIRE := ["katon", "yoton", "shakuton", "bakuton"]
const WATER := ["suiton", "futton", "hyoton"]
const WIND := ["fuuton", "jinton"]
const REGEN := 300.0           # saniye: yıkılan/yanan şeyler geri gelir
const REGEN_DIST := 90.0       # oyuncu bu mesafeden uzaktayken
const MAX_BLAZE := 10          # aynı anda görünen yangın
const MAX_FALL := 24           # devrilmiş ağaç vekili
const MAX_CHAR := 160          # kömürleşmiş gövde vekili
const MAX_DOWN := 12           # yıkık ev
const MAX_BEND := 40           # rüzgârla eğilen ağaç
const HCELL := 32.0            # ev ızgarası
const TCELL := 16.0            # ağaç ızgarası (parça içi)
const CHARCOAL := Color(0.16, 0.13, 0.12)
const TREE_T := [0, 1, 2, 3, 5, 7, 9]
## tip -> [toplam boy, taç merkezi y, taç yarıçapı, gövde yarıçapı] (ölçek 1)
const TREE_GEOM := {0: [10.0, 7.2, 3.2, 0.38], 1: [12.0, 6.5, 2.6, 0.36], 2: [8.0, 5.5, 2.0, 0.3], 3: [4.2, 2.5, 0.8, 0.36],
	5: [70.0, 52.0, 17.0, 3.2], 7: [9.0, 8.0, 2.5, 0.25], 9: [32.0, 22.0, 10.0, 1.05]}

var trees := {}        # ağaç kimliği (Vector3i) -> durum
var gone := {}         # devrilen ağaçlar (Vegetation çarpışma havuzu bunları atlar)
var active := []       # yanan / yanık / yıkık ev kayıtları (her karede yalnız bunlar dolaşılır)
var hgrid := {}        # Vector2i -> [ev kaydı]
var blazes: Array = []
var bends: Array = []
var _pending: Array = []
var _mutex := Mutex.new()
var _recent := {}      # tekrar eden çarpmaları süz (ışın/alan her kare çağırır)
var _now := 0.0
var _body: StaticBody3D
var _char_meshes := {}
var _stump_mesh: ArrayMesh
var _rubble_meshes := {}
var _mats := {}
var _chunk_mms := {}   # parça -> dizinlenmiş MultiMesh'ler (parça yeniden kurulunca CPU kopyaları bırakılır)
var _down := 0
var _fall := 0
var _char := 0


# ------------------------------------------------------------------ giriş
func fire_el(el: String) -> bool:
	return el in FIRE


## Çarpma: savaş sistemi her alan/mermi vuruşunda çağırır. Ucuz: küçük vuruşlar hemen döner.
func impact(pos: Vector3, radius: float, info: Dictionary, normal := Vector3.ZERO) -> void:
	if Game.world == null or Game.player == null:
		return
	var el: String = info.get("element", "")
	var dmg: float = float(info.get("dmg", 0.0))
	var heavy: bool = info.get("kind", "") == "heavy"
	var fire: bool = el in FIRE or info.has("burn")
	var water: bool = el in WATER
	var wind: bool = el in WIND
	var force := dmg * (1.0 if heavy else 0.4) + radius * 4.0
	if fire:
		force *= 0.5     # ateş devirmez, yakar
	if force < 12.0 and not fire and not water:
		return
	if pos.distance_to(Game.player.global_position) > 400.0:
		return
	# aynı yerde aynı kare grubunda tekrar eden çağrıları birleştir
	var rk = Vector3i(int(pos.x / 2.0), int(pos.y / 2.0), int(pos.z / 2.0))
	var last = _recent.get(rk)
	if last != null and _now - float(last[0]) < 0.15 and float(last[1]) >= force:
		return
	_recent[rk] = [_now, force]
	if water:
		_extinguish(pos, radius * 1.6 + 2.0)
		return
	# ağaç yalnız güçlü tekniklerle devrilir (B-rank üstü jutsu, dev vuruşlar: bijuu, çağrı, Susanoo); sıradan jutsu/yumruk devirmez
	var tier := int(info.get("tier", -1))
	var strong := tier >= 3 or (tier < 0 and dmg >= 150.0) or float(info.get("topple", 0.0)) > 0.0
	_hit_trees(pos, radius, fire, wind, force if strong else minf(force, 11.0), dmg)
	_hit_houses(pos, radius, fire, force, dmg)
	if fire and normal != Vector3.ZERO and absf(normal.y) < 0.6:
		_wall_scorch(pos, normal, clampf(radius * 1.4, 1.5, 5.0))


## Uçan büyük ateş mermisi yol boyunca yalayıp geçtiği ağaçları/evleri tutuşturur
func graze(pos: Vector3, radius: float, info: Dictionary) -> void:
	if Engine.get_physics_frames() % 6 != 0:
		return
	var inf = info.duplicate()
	inf["kind"] = "light"
	impact(pos, radius, inf)


# ------------------------------------------------------------------ ağaçlar
func _veg() -> Node:
	return Game.world.vegetation if Game.world else null


func _tid(tr: Array) -> Vector3i:
	return Vector3i(int(tr[0] * 10.0), int(tr[2] * 10.0), int(tr[5]))


## Parçanın ağaç listesini 16 m ızgaraya böl (bir kez; parça sözlüğünde saklanır)
func _tgrid(ch: Dictionary) -> Dictionary:
	if ch.has("wd_grid"):
		return ch["wd_grid"]
	var g := {}
	for tr in ch["trees"]:
		if not int(tr[5]) in TREE_T:
			continue
		var k = Vector2i(floori(tr[0] / TCELL), floori(tr[2] / TCELL))
		if not g.has(k):
			g[k] = []
		g[k].append(tr)
	ch["wd_grid"] = g
	return g


func _trees_near(pos: Vector3, reach: float) -> Array:
	var veg = _veg()
	var out: Array = []
	if veg == null:
		return out
	var CH: float = veg.CH
	var c0 = Vector2i(floori((pos.x - reach) / CH), floori((pos.z - reach) / CH))
	var c1 = Vector2i(floori((pos.x + reach) / CH), floori((pos.z + reach) / CH))
	for cx in range(c0.x, c1.x + 1):
		for cz in range(c0.y, c1.y + 1):
			var ch = veg.chunks.get(Vector2i(cx, cz))
			if ch == null or not ch["detail"]:
				continue
			var g = _tgrid(ch)
			for gx in range(floori((pos.x - reach) / TCELL), floori((pos.x + reach) / TCELL) + 1):
				for gz in range(floori((pos.z - reach) / TCELL), floori((pos.z + reach) / TCELL) + 1):
					var lst = g.get(Vector2i(gx, gz))
					if lst != null:
						out.append_array(lst)
	return out


func _hit_trees(pos: Vector3, radius: float, fire: bool, wind: bool, force: float, dmg: float) -> void:
	var reach = radius + (24.0 if wind else 12.0)
	var lst = _trees_near(pos, reach)
	if lst.is_empty():
		return
	var veg = _veg()
	for tr in lst:
		var t: int = tr[5]
		var s: float = tr[3]
		var geo: Array = TREE_GEOM[t]
		var top: float = tr[1] + geo[0] * s
		if pos.y < tr[1] - 3.0 or pos.y > top + 3.0:
			continue
		var dxz = Vector2(tr[0] - pos.x, tr[2] - pos.z).length()
		var canopy: float = geo[2] * s if pos.y > tr[1] + geo[1] * s * 0.55 else 0.0
		var r_eff = radius * (2.4 if wind else 1.0)
		if dxz > r_eff + geo[3] * s + canopy * 0.8 + (1.0 if fire else 0.3):
			continue
		var id = _tid(tr)
		var st = trees.get(id)
		var big = t in [5, 9]
		var need = 70.0 if big else 30.0
		if t == 3:
			need = 18.0
		if not fire and force >= need and (st == null or st["state"] != "fall"):
			_topple(id, tr, pos, force, st)
		elif fire and dmg >= 5.0:
			if st == null:
				_ignite_tree(id, tr, 0)
		elif wind and force >= 12.0 and st == null:
			_bend(id, tr, pos, clampf(force / need, 0.25, 0.9))
	veg.last_cell = Vector2i(999999, 999999)


## Ağacın bütün MultiMesh örnekleri (yakın, LOD, uzak vekil): [[mm, i, asıl dönüşüm, asıl renk]]
func _instances(tr: Array) -> Array:
	var veg = _veg()
	if veg == null:
		return []
	var CH: float = veg.CH
	var key = Vector2i(floori(tr[0] / CH), floori(tr[2] / CH))
	var ch = veg.chunks.get(key)
	if ch == null or not is_instance_valid(ch["node"]):
		return []
	var node: Node3D = ch["node"]
	var idx: Dictionary
	if node.has_meta("wd_idx"):
		idx = node.get_meta("wd_idx")
	else:
		idx = _index_chunk(node, ch.get("wdbufs", {}))
		node.set_meta("wd_idx", idx)
		var mms := {}
		for lst in idx.values():
			for e in lst:
				mms[e[0]] = true
		_chunk_mms[key] = mms.keys()
	var cx = (key.x + 0.5) * CH
	var cz = (key.y + 0.5) * CH
	var k = Vector2i(roundi((tr[0] - cx) * 8.0), roundi((tr[2] - cz) * 8.0))
	var out: Array = []
	for e in idx.get(k, []):
		if e.size() < 3:
			var src: PackedFloat32Array = _mmcpu[e[0]]
			e.append(src.slice(e[1] * 16, e[1] * 16 + 16))
		out.append(e)
	return out


var _mmcpu := {}     # MultiMesh -> CPU tampon kopyası (yazılır, karede bir kez bütün olarak yüklenir)
var _dirty := {}
var _mesh_t := {}    # ağaç mesh'i -> tip


## Parçanın ağaç MultiMesh'lerini CPU tamponlarından dizinle (MultiMesh.buffer okumak GPU'yu bekletir)
func _index_chunk(node: Node3D, wdbufs: Dictionary) -> Dictionary:
	if _mesh_t.is_empty():
		var veg = _veg()
		for t in TREE_T:
			for v in veg.meshes[t]:
				for m in v:
					if m != null:
						_mesh_t[m] = t
			if veg.lods.get(t) != null:
				_mesh_t[veg.lods[t]] = t
	var idx := {}
	for c in node.get_children():
		if not c is MultiMeshInstance3D:
			continue
		var mm: MultiMesh = c.multimesh
		if mm == null or not _mesh_t.has(mm.mesh):
			continue
		var src = wdbufs.get(int(_mesh_t[mm.mesh]) * 100)
		if src == null or src.size() / 16 != mm.instance_count:
			continue   # seyreltilmiş uzak kopya vb.: dokunulmaz
		var buf: PackedFloat32Array = src
		_mmcpu[mm] = buf.duplicate()
		for i in mm.instance_count:
			var o := i * 16
			var k = Vector2i(roundi(buf[o + 3] * 8.0), roundi(buf[o + 11] * 8.0))
			if not idx.has(k):
				idx[k] = [[mm, i]]
			else:
				idx[k].append([mm, i])
	return idx


## 16 değeri (3x4 dönüşüm + renk) CPU kopyasına yaz; yükleme _flush'ta
func _put(mm: MultiMesh, i: int, v: PackedFloat32Array) -> void:
	if not _mmcpu.has(mm):
		return
	var a: PackedFloat32Array = _mmcpu[mm]
	_mmcpu[mm] = PackedFloat32Array()   # tek sahip kalsın: kopyalamadan yerinde yazılır
	for j in 16:
		a[i * 16 + j] = v[j]
	_mmcpu[mm] = a
	_dirty[mm] = true


func _flush() -> void:
	for mm in _dirty:
		if _mmcpu.has(mm):
			mm.buffer = _mmcpu[mm]
	_dirty.clear()


func _set_hidden(inst: Array, hidden: bool) -> void:
	for e in inst:
		var v: PackedFloat32Array = e[2].duplicate()
		if hidden:
			for j in [0, 1, 2, 4, 5, 6, 8, 9, 10]:
				v[j] *= 0.001
		_put(e[0], e[1], v)


func _set_char(inst: Array, f: float) -> void:
	for e in inst:
		var v: PackedFloat32Array = e[2].duplicate()
		var c = Color(v[12], v[13], v[14], v[15]).lerp(Color(0.2, 0.15, 0.13, 1.0), f)
		v[12] = c.r; v[13] = c.g; v[14] = c.b
		_put(e[0], e[1], v)


## Vegetation parçayı yeniden kurunca (LOD / yaklaşma) hasar durumunu yeni örneklere uygula
func veg_installed(key: Vector2i, _node: Node3D) -> void:
	for mm in _chunk_mms.get(key, []):
		_mmcpu.erase(mm)
		_dirty.erase(mm)
	_chunk_mms.erase(key)
	var veg = _veg()
	if veg == null or trees.is_empty():
		return
	var CH: float = veg.CH
	for id in trees:
		var st: Dictionary = trees[id]
		var tr: Array = st["tr"]
		if Vector2i(floori(tr[0] / CH), floori(tr[2] / CH)) != key:
			continue
		st["inst"] = _instances(tr)
		match st["state"]:
			"fall", "char":
				_set_hidden(st["inst"], true)
			"burn":
				_set_char(st["inst"], st.get("charf", 0.0))


func _ignite_tree(id: Vector3i, tr: Array, gen: int) -> void:
	var t: int = tr[5]
	var s: float = tr[3]
	var geo: Array = TREE_GEOM[t]
	var inst = _instances(tr)
	var st = {"tr": tr, "state": "burn", "t": _now, "inst": inst, "gen": gen, "charf": 0.0}
	trees[id] = st
	var base = Vector3(tr[0], tr[1], tr[2])
	var dur = randf_range(9.0, 13.0) * (0.55 if _raining() else 1.0)
	if t in [5, 9]:
		dur *= 1.5
	st["dur"] = dur
	if blazes.size() < MAX_BLAZE:
		# alev dilleri: gövdeyi tırmanır (yer yer iki yanda), dal uçlarında ve tacın içinde öbekler; tek dev "yumurta" değil, çok sayıda sivri dil
		var pts: Array = []
		var cy: float = geo[1] * s
		var cr: float = geo[2] * s
		var trr: float = geo[3] * s
		var climb = minf(cy, 22.0)
		var nt = clampi(int(climb / 3.2), 2, 6)
		for k in nt:
			var y = 0.6 + climb * (k + 0.3) / nt
			var a = randf() * TAU
			var fw = clampf(trr * 2.4, 1.0, 3.2) * randf_range(0.8, 1.15)
			pts.append([Vector3(cos(a) * trr * 0.8, y, sin(a) * trr * 0.8), fw])
			if trr > 0.8 and k % 2 == 0:
				pts.append([Vector3(-cos(a) * trr * 0.8, y + 1.2, -sin(a) * trr * 0.8), fw * 0.8])
		if t == 9:
			var yaw: float = tr[4]
			for br in Props.FOREST_BRANCHES:
				if pts.size() >= 13:
					break
				var a2 = deg_to_rad(br[1]) + yaw
				var L: float = br[2]
				var tip = Vector3(sin(a2), 0, cos(a2)) * (Props.FOREST_TRUNK_R + L * 0.8) * s + Vector3.UP * br[0] * s
				pts.append([tip, randf_range(2.2, 3.0)])
		var nc = 3 if t in [5, 9] else 3
		for k in nc:
			var a = TAU * k / nc + randf() * 0.8
			var rr = cr * randf_range(0.2, 0.6)
			pts.append([Vector3(cos(a) * rr, cy + randf_range(-0.2, 0.45) * cr, sin(a) * rr), clampf(cr * 0.45, 1.6, 4.0)])
		st["blaze"] = _blaze(base, pts, clampf(cr * 0.7, 2.0, 7.0), dur, cy + cr * 0.6, false, minf(climb * 0.6, 12.0))
	else:
		FX.burst(base + Vector3.UP * geo[1] * s, {"cel": true, "amount": 8, "life": 1.2, "size": 2.2 * s, "radius": geo[2] * s * 0.5,
			"vmin": 1, "vmax": 3, "gravity": Vector3(0, 2, 0), "colors": [Color(1, 0.6, 0.15, 1), Color(0.3, 0.27, 0.25, 0.7), Color(0.2, 0.2, 0.2, 0)]})


func _tree_burnt(id: Vector3i, st: Dictionary) -> void:
	var tr: Array = st["tr"]
	st["state"] = "char"
	st["t"] = _now
	_set_char(st["inst"], 0.0)
	_set_hidden(st["inst"], true)
	if _char >= MAX_CHAR:
		_restore_oldest("char")
	_char += 1
	var mi = MeshInstance3D.new()
	mi.mesh = _char_mesh(int(tr[5]))
	mi.layers = 2
	get_tree().current_scene.add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, tr[4]).scaled(Vector3.ONE * tr[3]), Vector3(tr[0], tr[1] - 0.3, tr[2]))
	st["proxy"] = mi
	# yere düşen kül ve kıvılcım
	var geo: Array = TREE_GEOM[int(tr[5])]
	FX.burst(Vector3(tr[0], tr[1] + geo[1] * tr[3], tr[2]), {"cel": true, "amount": 10, "life": 1.6, "size": 1.6 * tr[3], "radius": geo[2] * tr[3] * 0.6,
		"vmin": 0.5, "vmax": 2.0, "gravity": Vector3(0, -2, 0), "outline_col": Color(0.1, 0.08, 0.08),
		"colors": [Color(0.25, 0.22, 0.2, 1), Color(0.18, 0.16, 0.15, 0.8), Color(0.15, 0.14, 0.14, 0)]})


## Devirme: örnek gizlenir, aynı mesh'li vekil kökünden (ya da kırılma noktasından) darbe yönüne yıkılır
func _topple(id: Vector3i, tr: Array, from: Vector3, force: float, st) -> void:
	var t: int = tr[5]
	var s: float = tr[3]
	var geo: Array = TREE_GEOM[t]
	var charred := false
	if st != null:
		charred = st["state"] in ["char", "burn"]
		_free_tree_visual(st)
	if _fall >= MAX_FALL:
		_restore_oldest("fall")
	_fall += 1
	var inst = _instances(tr)
	_set_hidden(inst, true)
	var nst = {"tr": tr, "state": "fall", "t": _now, "inst": inst}
	trees[id] = nst
	gone[id] = true
	var base = Vector3(tr[0], tr[1] - 0.3, tr[2])
	var d = Vector3(tr[0] - from.x, 0, tr[2] - from.z)
	if d.length() < 0.1:
		d = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	d = d.normalized()
	var axis = Vector3.UP.cross(d).normalized()
	var cut = (1.1 + randf() * 0.6) * s if t != 3 else 0.3
	var pivot = Node3D.new()
	get_tree().current_scene.add_child(pivot)
	pivot.global_position = base + Vector3.UP * cut
	var mi = MeshInstance3D.new()
	mi.layers = 2
	mi.mesh = _char_mesh(t) if charred else _veg().meshes[t][0][0]
	pivot.add_child(mi)
	mi.transform = Transform3D(Basis(Vector3.UP, tr[4]).scaled(Vector3.ONE * s), Vector3.DOWN * cut)
	nst["proxy"] = pivot
	# kırılan kütük
	if t != 3:
		var stump = MeshInstance3D.new()
		stump.mesh = _stump()
		stump.layers = 2
		get_tree().current_scene.add_child(stump)
		var tr_r: float = geo[3] * s
		stump.global_transform = Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(tr_r, cut, tr_r)), base)
		nst["stump"] = stump
		VFX.debris(pivot.global_position, Color(0.55, 0.4, 0.26), 8, 7.0, 0.3 * sqrt(s))
	var h: float = geo[0] * s
	var dur = clampf(0.9 + sqrt(h) * 0.28, 1.2, 3.2) * (0.75 if force > 60.0 else 1.0)
	var maxa = deg_to_rad(randf_range(84.0, 89.0))
	var tw = pivot.create_tween()
	tw.tween_method(func(x: float):
		if is_instance_valid(pivot):
			pivot.quaternion = Quaternion(axis, maxa * x * x)
	, 0.0, 1.0, dur)
	tw.tween_callback(func():
		if not is_instance_valid(pivot):
			return
		var land = base + d * h * 0.62
		land.y = Game.ground_height(land.x, land.z)
		FX.dust(land, 2.2 * sqrt(s))
		FX.dust(base + d * h * 0.3, 1.6 * sqrt(s))
		VFX.shockwave(land + Vector3.UP * 0.2, Color(0.78, 0.7, 0.56), 4.0 + h * 0.25, 0.4)
		if not charred and t != 3:
			FX.burst(land + Vector3.UP * geo[2] * s * 0.5, {"amount": int(14 + s * 6), "life": 2.2, "tex": FX.tex_leaf, "size": 0.55 * sqrt(s), "radius": geo[2] * s * 0.7,
				"vmin": 1.5, "vmax": 5.0, "gravity": Vector3(0, -2.5, 0), "spin": 220.0, "add": false,
				"colors": [Color(0.42, 0.72, 0.28, 1), Color(0.35, 0.6, 0.22, 1), Color(0.3, 0.5, 0.2, 0)]})
		Sfx.play("earth", land, 0.8, 0.7 if h > 15.0 else 1.0)
		if Game.world and Game.world.env and Game.player and land.distance_to(Game.player.global_position) < 60.0:
			Game.world.env.add_shake(clampf(h * 0.012, 0.15, 0.6))
	)
	tw.tween_method(func(x: float):
		if is_instance_valid(pivot):
			pivot.quaternion = Quaternion(axis, maxa - sin(x * PI) * deg_to_rad(4.0))
	, 0.0, 1.0, 0.35)
	Sfx.play("wind" if force < 50.0 else "boom", pivot.global_position, 0.6)


## Rüzgâr: örnek dönüşümü sönümlü salınımla eğilir (Daitoppa ormanı yatırır)
func _bend(id: Vector3i, tr: Array, from: Vector3, amp: float) -> void:
	if bends.size() >= MAX_BEND:
		return
	for b in bends:
		if b["id"] == id:
			b["t"] = 0.0
			b["amp"] = maxf(b["amp"], amp)
			return
	var d = Vector3(tr[0] - from.x, 0, tr[2] - from.z)
	if d.length() < 0.1:
		return
	var axis = Vector3.UP.cross(d.normalized()).normalized()
	bends.append({"id": id, "inst": _instances(tr), "axis": axis, "amp": amp, "t": 0.0})


func _free_tree_visual(st: Dictionary) -> void:
	for k in ["blaze", "proxy", "stump"]:
		var n = st.get(k)
		if n != null and is_instance_valid(n):
			if k == "blaze":
				_end_blaze(n, true)
			else:
				n.queue_free()
		st.erase(k)
	if st["state"] == "char":
		_char -= 1
	elif st["state"] == "fall":
		_fall -= 1


func _restore_tree(id: Vector3i) -> void:
	var st = trees.get(id)
	if st == null:
		return
	_free_tree_visual(st)
	_set_hidden(st.get("inst", []), false)
	_set_char(st.get("inst", []), 0.0)
	trees.erase(id)
	gone.erase(id)
	var veg = _veg()
	if veg:
		veg.last_cell = Vector2i(999999, 999999)


func _restore_oldest(state: String) -> void:
	var best = null
	var bt = 1e18
	for id in trees:
		if trees[id]["state"] == state and float(trees[id]["t"]) < bt:
			bt = trees[id]["t"]
			best = id
	if best != null:
		_restore_tree(best)


# ------------------------------------------------------------------ evler
## HouseKit.Placer kayıtları (iş parçacığından da gelebilir: sıraya alınır, ana iş parçacığında ızgaraya girer)
func register_houses(recs: Array) -> void:
	_mutex.lock()
	_pending.append_array(recs)
	_mutex.unlock()


func _drain() -> void:
	if _pending.is_empty():
		return
	_mutex.lock()
	var p = _pending
	_pending = []
	_mutex.unlock()
	for rec in p:
		var k = Vector2i(floori(rec["pos"].x / HCELL), floori(rec["pos"].z / HCELL))
		if not hgrid.has(k):
			hgrid[k] = []
		hgrid[k].append(rec)


func _houses_near(pos: Vector3, reach: float) -> Array:
	var out: Array = []
	for cx in range(floori((pos.x - reach) / HCELL), floori((pos.x + reach) / HCELL) + 1):
		for cz in range(floori((pos.z - reach) / HCELL), floori((pos.z + reach) / HCELL) + 1):
			var k = Vector2i(cx, cz)
			var lst = hgrid.get(k)
			if lst == null:
				continue
			var alive: Array = []
			for rec in lst:
				if is_instance_valid(rec["body"]):
					alive.append(rec)
					out.append(rec)
			if alive.size() != lst.size():
				hgrid[k] = alive
	return out


## Noktanın ev kutusuna uzaklığı (m)
func _house_dist(rec: Dictionary, p: Vector3) -> float:
	var b: Basis = rec["basis"]
	var l = b.inverse() * (p - rec["pos"])
	var t: Dictionary = HouseKit.templates[rec["ti"]]
	var dx = maxf(absf(l.x) - t["w"] * 0.5, 0.0)
	var dz = maxf(absf(l.z) - t["d"] * 0.5, 0.0)
	var dy = maxf(l.y - t["roof_top"], 0.0) + maxf(-l.y, 0.0)
	return Vector3(dx, dy, dz).length() * float(rec["scale"])


## Kayıttaki MultiMesh örnekleri hâlâ sahnede mi? (Konoha 160 m hücreleri sonradan 480 m'de birleştirir -> yeni MultiMesh'te aynı dönüşümü bul)
func _resolve(rec: Dictionary) -> void:
	if rec.get("resolved", false):
		return
	rec["resolved"] = true
	var parent = rec["body"].get_parent()
	if parent == null:
		return
	var t: Dictionary = HouseKit.templates[rec["ti"]]
	var live := {}
	for c in parent.get_children():
		if c is MultiMeshInstance3D and c.multimesh != null:
			live[c.multimesh] = true
	for e in rec["mm"]:
		if live.has(e[0]):
			continue
		var xf: Transform3D = e[3]
		var key = Vector3i(roundi(xf.origin.x * 10.0), roundi(xf.origin.y * 10.0), roundi(xf.origin.z * 10.0))
		for c in parent.get_children():
			if not c is MultiMeshInstance3D or c.multimesh == null or c.multimesh.mesh != t[e[2]]:
				continue
			var mm: MultiMesh = c.multimesh
			var org: Dictionary = _origins(mm)
			if org.has(key):
				e[0] = mm
				e[1] = org[key]
				break


## MultiMesh örnek konumu -> dizin (bir kez; tampondan, hızlı)
func _origins(mm: MultiMesh) -> Dictionary:
	if mm.has_meta("wd_org"):
		return mm.get_meta("wd_org")
	var d := {}
	var buf := mm.buffer
	var stride := 16 if mm.use_colors else 12
	for i in mm.instance_count:
		var o := i * stride
		d[Vector3i(roundi(buf[o + 3] * 10.0), roundi(buf[o + 7] * 10.0), roundi(buf[o + 11] * 10.0))] = i
	mm.set_meta("wd_org", d)
	return d


func _hit_houses(pos: Vector3, radius: float, fire: bool, force: float, dmg: float) -> void:
	_drain()
	if hgrid.is_empty():
		return
	for rec in _houses_near(pos, radius + 14.0):
		# güçlü darbenin şok dalgası da yıkar (Rasengan hedefi duvara gömer)
		if _house_dist(rec, pos) > radius * 1.3 + 1.6 + (clampf(force / 30.0, 0.0, 3.5) if not fire else 0.0):
			continue
		_resolve(rec)
		var st: String = rec.get("state", "")
		if st == "down":
			continue
		if fire and dmg >= 5.0:
			# ısı birikir (aynı alevin her karesi değil, ayrı isabetler sayılır)
			if _now - float(rec.get("heat_t", -9.0)) > 0.6:
				rec["heat_t"] = _now
				rec["heat"] = float(rec.get("heat", 0.0)) + dmg
			if st == "":
				_ignite_house(rec)
		elif force >= 46.0 and not _protected(rec):
			_collapse(rec, pos, false)
		elif force >= 20.0:
			# sarsıntı: toz ve kiremit dökülür
			var top = rec["pos"] + Vector3.UP * HouseKit.templates[rec["ti"]]["h"] * float(rec["scale"])
			VFX.debris(top, rec["roof"].darkened(0.2), 6, 6.0, 0.3)
			FX.dust(Vector3(pos.x, rec["pos"].y, pos.z), 1.2)


## Dükkân, ev, görev yeri gibi girilebilen/etkileşimli binalar yıkılmaz (yalnız yanar ve kararır)
func _protected(rec: Dictionary) -> bool:
	if rec.has("prot"):
		return rec["prot"]
	var t: Dictionary = HouseKit.templates[rec["ti"]]
	var r = maxf(t["w"], t["d"]) * 0.6 * float(rec["scale"]) + 3.0
	var p: Vector3 = rec["pos"]
	var prot := false
	for it in Interact.items:
		var ip: Vector3 = it["pos"]
		if absf(ip.x - p.x) < r and absf(ip.z - p.z) < r:
			prot = true
			break
	rec["prot"] = prot
	return prot


func _part_col(rec: Dictionary, part: String) -> Color:
	return rec["wall"] if part == "walls" else (rec["roof"] if part == "roof" else Color.WHITE)


func _house_char(rec: Dictionary, f: float) -> void:
	for e in rec["mm"]:
		var c: Color = _part_col(rec, e[2])
		e[0].set_instance_color(e[1], c.lerp(CHARCOAL if e[2] != "roof" else Color(0.1, 0.09, 0.09), f))


func _house_hidden(rec: Dictionary, hidden: bool) -> void:
	for e in rec["mm"]:
		var xf: Transform3D = e[3]
		e[0].set_instance_transform(e[1], Transform3D(xf.basis.scaled(Vector3.ONE * 0.001), xf.origin) if hidden else xf)
	for sh in rec["shapes"]:
		if is_instance_valid(sh):
			sh.set_deferred("disabled", hidden)


func _ignite_house(rec: Dictionary) -> void:
	if not rec in active:
		active.append(rec)
	rec["state"] = "burn"
	rec["t"] = _now
	rec["charf"] = 0.0
	var t: Dictionary = HouseKit.templates[rec["ti"]]
	var sc = float(rec["scale"])
	var dur = randf_range(13.0, 17.0) * (0.6 if _raining() else 1.0)
	rec["dur"] = dur
	if blazes.size() >= MAX_BLAZE:
		return
	# alevler: çatı sırtı + cephe pencerelerinden dışarı taşan diller (yerel uzay: ön cephe -Z, tabanda)
	var b: Basis = rec["basis"]
	var w: float = t["w"]; var d: float = t["d"]; var h: float = t["h"]; var rt: float = t["roof_top"]
	var pts: Array = []
	for k in 3:
		var lx = lerpf(-w * 0.35, w * 0.35, k / 2.0)
		pts.append([b * Vector3(lx, rt - 0.4, randf_range(-0.2, 0.2) * d), 2.6 * sc + randf() * 0.8])
	for k in 3:
		var side = 1.0 if k % 2 == 0 else -1.0
		pts.append([b * Vector3(randf_range(-0.35, 0.35) * w, h * randf_range(0.35, 0.8), side * (d * 0.5 + 0.3)), 1.6 * sc])
	pts.append([b * Vector3(w * 0.5 + 0.3, h * 0.5, 0), 1.5 * sc])
	rec["blaze"] = _blaze(rec["pos"], pts, maxf(w, d) * 0.45 * sc, dur, rt * sc + 1.0, true)
	Sfx.play("fire", rec["pos"], 0.9, 0.8)


func _house_burnt(rec: Dictionary) -> void:
	rec.erase("blaze")
	if float(rec.get("heat", 0.0)) >= 24.0 and not _protected(rec) and _down < MAX_DOWN:
		_collapse(rec, rec["pos"] + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), true)
	else:
		rec["state"] = "scorch"
		rec["t"] = _now
		_house_char(rec, 0.75)


## Yıkım: sarsıntı -> duvarlar çöker, çatı yamulup iner -> toz bulutu -> moloz yığını (çarpışmalı)
func _collapse(rec: Dictionary, from: Vector3, burnt: bool) -> void:
	if _down >= MAX_DOWN:
		return
	_down += 1
	if not rec in active:
		active.append(rec)
	var blz = rec.get("blaze")
	rec["state"] = "down"
	rec["t"] = _now
	var t: Dictionary = HouseKit.templates[rec["ti"]]
	var sc = float(rec["scale"])
	var h: float = t["h"]
	var w: float = t["w"]; var d: float = t["d"]
	var charf = 0.85 if burnt else float(rec.get("charf", 0.0))
	_house_hidden(rec, true)
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_transform = Transform3D(rec["basis"], rec["pos"])
	rec["proxy"] = root
	var parts := {}
	for part in ["walls", "roof", "detail"]:
		var mi = MeshInstance3D.new()
		mi.mesh = t[part]
		mi.layers = 2
		var c = _part_col(rec, part).lerp(CHARCOAL, charf)
		mi.material_override = _tint_mat(c)
		root.add_child(mi)
		parts[part] = mi
	var away = (rec["pos"] - from)
	away.y = 0
	away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
	var lax = (rec["basis"].inverse() * Vector3.UP.cross(away)).normalized()
	var wp = rec["pos"]
	var foot = maxf(w, d) * sc
	# 1) sarsıntı
	var tw = root.create_tween()
	for k in 4:
		tw.tween_property(root, "position", root.position + Vector3(randf_range(-0.25, 0.25), 0, randf_range(-0.25, 0.25)), 0.06)
	tw.tween_property(root, "position", root.position, 0.06)
	VFX.debris(wp + Vector3.UP * h * sc * 0.6, rec["wall"].lerp(CHARCOAL, charf), 14, 9.0, 0.5)
	VFX.debris(wp + Vector3.UP * h * sc, rec["roof"].lerp(CHARCOAL, charf), 10, 8.0, 0.4)
	Sfx.play("boom", wp, 0.9, 0.7)
	# 2) çöküş
	var fall = 1.15
	tw.tween_callback(func():
		for p in ["walls", "detail"]:
			var m: MeshInstance3D = parts[p]
			var t2 = m.create_tween().set_parallel(true)
			t2.tween_property(m, "scale", Vector3(1.08, 0.1, 1.08), fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t2.tween_property(m, "rotation", lax * deg_to_rad(randf_range(4.0, 9.0)), fall)
		var r: MeshInstance3D = parts["roof"]
		var t3 = r.create_tween().set_parallel(true)
		t3.tween_property(r, "position", Vector3(0, -h * 0.86, 0) + rec["basis"].inverse() * away * 1.2 / sc, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t3.tween_property(r, "rotation", lax * deg_to_rad(randf_range(14.0, 22.0)) + Vector3(0, deg_to_rad(randf_range(-8, 8)), 0), fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		for k in 3:
			var a = TAU * k / 3.0
			FX.dust(wp + Vector3(cos(a), 0, sin(a)) * foot * 0.5, 2.0 * sqrt(sc))
	)
	tw.tween_interval(fall * 0.85)
	# 3) toz bulutu + moloz
	tw.tween_callback(func():
		var gp = Vector3(wp.x, rec["pos"].y + 0.3, wp.z)
		VFX.shockwave(gp, Color(0.8, 0.72, 0.6), foot * 1.6, 0.55)
		FX.burst(gp + Vector3.UP * 1.5, {"cel": true, "amount": 26, "life": 2.6, "size": foot * 0.42, "radius": foot * 0.45,
			"vmin": 2.0, "vmax": 7.0, "dir": Vector3.UP, "spread": 75.0, "damp": 2.2, "gravity": Vector3(0, 0.6, 0), "spin": 40.0,
			"outline_col": Color(0.3, 0.25, 0.2), "rough": 0.38,
			"colors": [Color(0.86, 0.79, 0.67, 1), Color(0.76, 0.69, 0.6, 0.9), Color(0.7, 0.65, 0.58, 0.0)] if not burnt else
				[Color(0.45, 0.4, 0.37, 1), Color(0.3, 0.28, 0.27, 0.9), Color(0.22, 0.21, 0.21, 0.0)],
			"scale_curve": [[0.0, 0.4], [0.25, 1.0], [1.0, 1.3]]})
		VFX.debris(gp + Vector3.UP, Color(0.42, 0.3, 0.2), 16, 11.0, 0.55)
		Sfx.play("earth", gp, 1.0, 0.6)
		if Game.world and Game.world.env and Game.player and gp.distance_to(Game.player.global_position) < 70.0:
			Game.world.env.add_shake(0.55)
		if is_instance_valid(root):
			var rub = MeshInstance3D.new()
			rub.mesh = _rubble(rec["ti"], rec["wall"].lerp(CHARCOAL, charf), rec["roof"].lerp(Color(0.1, 0.09, 0.09), charf))
			rub.layers = 2
			root.add_child(rub)
			rub.scale = Vector3(1, 0.2, 1)
			rub.create_tween().tween_property(rub, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			parts["walls"].visible = false
			parts["detail"].visible = false
			# çatı bütün halde yere oturmasın: toz bulutunun altında ezilip molozun içine gömülür
			var r2: MeshInstance3D = parts["roof"]
			var t4 = r2.create_tween().set_parallel(true)
			t4.tween_property(r2, "scale", Vector3(1.15, 0.2, 1.15), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t4.tween_property(r2, "position:y", r2.position.y - 0.6, 0.45)
			t4.chain().tween_callback(func(): r2.visible = false)
	)
	# moloz çarpışması (üstüne çıkılabilir)
	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(w * 0.85, 1.6, d * 0.85) * sc
	cs.shape = bs
	_body_node().add_child(cs)
	cs.global_transform = Transform3D(Basis(rec["basis"].get_rotation_quaternion()), rec["pos"] + Vector3.UP * 0.8 * sc)
	rec["rubble_cs"] = cs
	if blz != null and is_instance_valid(blz):
		# yanan moloz: alevler alçalır ve bir süre sürer
		var tongues: Node3D = blz.get_meta("tongues")
		if tongues:
			tongues.create_tween().tween_property(tongues, "position:y", -h * sc * 0.7, fall)
		blz.set_meta("end", _now + 10.0)
	elif burnt:
		_smolder(rec["pos"] + Vector3.UP * 1.5, foot * 0.25, 22.0)


func _restore_house(rec: Dictionary) -> void:
	for k in ["proxy", "rubble_cs", "blaze"]:
		var n = rec.get(k)
		if n != null and is_instance_valid(n):
			if k == "blaze":
				_end_blaze(n, true)
			else:
				n.queue_free()
		rec.erase(k)
	if rec.get("state", "") == "down":
		_down -= 1
		_house_hidden(rec, false)
	_house_char(rec, 0.0)
	rec["state"] = ""
	rec["heat"] = 0.0
	active.erase(rec)


# ------------------------------------------------------------------ yangın
## Alev dilleri (paylaşılan erime malzemesi) + duman sütunu + kıvılcım + titreyen ışık
func _blaze(at: Vector3, pts: Array, smoke_r: float, dur: float, smoke_y: float, house := false, low_smoke := -1.0) -> Node3D:
	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = at
	var tongues = Node3D.new()
	root.add_child(tongues)
	root.set_meta("tongues", tongues)
	var m = VFX.mat_fire("fire", 2.6, 2.0, 0.46, 1.2, 0.18, Vector3.UP, true)
	m.set_shader_parameter("tongue", 1.0)
	var delay := 0.0
	for p in pts:
		# her noktada 2 dil: biri kalın gövde, biri yana yatık ince uç (anime alev silüeti)
		for j in 2:
			var mi = MeshInstance3D.new()
			mi.mesh = _flame_mesh()
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			tongues.add_child(mi)
			var sz: float = p[1] * (1.0 if j == 0 else 0.62)
			var full = Vector3(sz * 0.8, sz * (2.3 if j == 0 else 2.8), sz * 0.8)
			mi.position = p[0] + (Vector3.ZERO if j == 0 else Vector3(randf_range(-0.5, 0.5), 0.35, randf_range(-0.5, 0.5)) * sz)
			mi.rotation = Vector3(randf_range(-0.12, 0.12), randf() * TAU, randf_range(-0.12, 0.12) + (0.0 if j == 0 else randf_range(-0.3, 0.3)))
			mi.position.y += full.y * 0.3
			mi.scale = full * 0.1
			var tw = mi.create_tween()
			tw.tween_interval(delay + randf() * 0.3)
			tw.tween_property(mi, "scale", full, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.12   # alev aşağıdan yukarı yayılır
	var smoke = _loop({"amount": 18 if house else 12, "life": 5.0 if house else 3.8, "size": smoke_r * (1.2 if house else 1.0),
		"radius": smoke_r * 0.5, "vmin": 2.5, "vmax": 5.0, "gravity": Vector3(0.6, 2.2, 0.3), "damp": 0.4, "spin": 25.0,
		"outline_col": Color(0.12, 0.1, 0.1), "rough": 0.36, "glow": 0.9,
		"colors": [Color(0.42, 0.36, 0.33, 0.0), Color(0.32, 0.29, 0.28, 0.95), Color(0.24, 0.23, 0.23, 0.85), Color(0.2, 0.2, 0.21, 0.0)],
		"scale_curve": [[0.0, 0.4], [0.3, 1.0], [1.0, 1.8]]})
	root.add_child(smoke)
	smoke.position = Vector3.UP * smoke_y
	if low_smoke > 0.0:
		var sm2 = _loop({"amount": 8, "life": 3.0, "size": smoke_r * 0.8, "radius": smoke_r * 0.3, "vmin": 2.0, "vmax": 4.0, "gravity": Vector3(0.4, 2.0, 0.2),
			"damp": 0.4, "spin": 25.0, "outline_col": Color(0.12, 0.1, 0.1), "rough": 0.36, "glow": 0.9,
			"colors": [Color(0.45, 0.38, 0.34, 0.0), Color(0.34, 0.3, 0.29, 0.85), Color(0.25, 0.24, 0.24, 0.0)], "scale_curve": [[0.0, 0.4], [0.3, 1.0], [1.0, 1.6]]})
		root.add_child(sm2)
		sm2.position = Vector3.UP * low_smoke
	var emb = _loop({"amount": 14, "life": 1.6, "tex": FX.tex_spark, "size": 0.6, "radius": smoke_r * 0.6, "vmin": 2.0, "vmax": 6.0,
		"gravity": Vector3(0, 3.0, 0), "damp": 0.8, "add": true, "colors": [Color(1, 0.85, 0.4, 1), Color(1, 0.45, 0.1, 0.8), Color(0.8, 0.2, 0.05, 0)]})
	root.add_child(emb)
	emb.position = Vector3.UP * (low_smoke if low_smoke > 0.0 else smoke_y * 0.7)
	var lit := 0
	for b in blazes:
		if b.has_meta("light"):
			lit += 1
	if lit < 4:
		var l = OmniLight3D.new()
		l.light_color = Color(1, 0.55, 0.2)
		l.light_energy = 0.0
		l.omni_range = smoke_r * 3.0 + 8.0
		l.shadow_enabled = false
		root.add_child(l)
		l.position = Vector3.UP * smoke_y * 0.55
		l.create_tween().tween_property(l, "light_energy", 1.8, 1.2)
		root.set_meta("light", l)
	root.set_meta("mat", m)
	root.set_meta("end", _now + dur)
	blazes.append(root)
	return root


func _end_blaze(b: Node3D, fast := false) -> void:
	blazes.erase(b)
	if not is_instance_valid(b):
		return
	var m: ShaderMaterial = b.get_meta("mat")
	var tw = b.create_tween()
	tw.tween_method(func(x: float): m.set_shader_parameter("alpha_cut", x), 0.0, 1.1, 0.4 if fast else 1.6)
	for c in b.get_children():
		if c is GPUParticles3D:
			c.emitting = false
		elif c is OmniLight3D:
			b.create_tween().tween_property(c, "light_energy", 0.0, 1.0)
	tw.tween_interval(0.5 if fast else 4.5)
	tw.tween_callback(b.queue_free)


## Su jutsusu yangını söndürür: buhar bulutu
func _extinguish(pos: Vector3, r: float) -> void:
	for b in blazes.duplicate():
		if is_instance_valid(b) and b.global_position.distance_to(pos) < r + 6.0:
			b.set_meta("end", _now)
			FX.burst(b.global_position + Vector3.UP * 3.0, {"cel": true, "amount": 14, "life": 1.8, "size": 3.0, "radius": 2.5, "vmin": 2, "vmax": 5,
				"gravity": Vector3(0, 3, 0), "outline_col": Color(0.5, 0.55, 0.6), "colors": [Color(1, 1, 1, 0.95), Color(0.92, 0.94, 0.96, 0.7), Color(0.9, 0.92, 0.95, 0)]})
			Sfx.play("water", b.global_position, 0.6)


func _smolder(at: Vector3, r: float, dur: float) -> void:
	var p = _loop({"amount": 8, "life": 3.5, "size": r * 1.4, "radius": r, "vmin": 1.0, "vmax": 2.5, "gravity": Vector3(0.4, 1.6, 0.2),
		"damp": 0.3, "outline_col": Color(0.15, 0.13, 0.13), "glow": 0.9,
		"colors": [Color(0.4, 0.37, 0.35, 0.0), Color(0.35, 0.33, 0.32, 0.8), Color(0.3, 0.3, 0.3, 0.0)], "scale_curve": [[0.0, 0.5], [1.0, 1.6]]})
	get_tree().current_scene.add_child(p)
	p.global_position = at
	var tw = p.create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func(): p.emitting = false)
	tw.tween_interval(4.0)
	tw.tween_callback(p.queue_free)


func _raining() -> bool:
	return Game.world != null and Game.world.env != null and String(Game.world.env.weather) == "yağmur"


# ------------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	_now += dt
	if Game.world == null:
		return
	_drain()
	if _recent.size() > 256:
		_recent.clear()
	# yangınlar: ağaç/ev kararır, süre bitince kömür / yıkım; ağaçtan ağaca sınırlı yayılım
	for id in trees.keys():
		var st = trees.get(id)
		if st == null or st["state"] != "burn":
			continue
		var f = clampf((_now - float(st["t"])) / float(st["dur"]), 0.0, 1.0)
		if absf(f - float(st["charf"])) > 0.08:
			st["charf"] = f
			_set_char(st["inst"], f * 0.9)
		if f >= 1.0:
			var b = st.get("blaze")
			if b != null:
				_end_blaze(b)
				st.erase("blaze")
			_tree_burnt(id, st)
		elif not _raining() and int(st["gen"]) < 3 and st.has("blaze") and f > 0.3 and not st.has("spread"):
			st["spread"] = true
			_spread(st)
	_drain_houses()
	_prune()
	for b in blazes.duplicate():
		if not is_instance_valid(b):
			blazes.erase(b)
			continue
		if _now >= float(b.get_meta("end")):
			_end_blaze(b)
		elif b.has_meta("light"):
			var l: OmniLight3D = b.get_meta("light")
			if is_instance_valid(l) and l.light_energy > 1.0:
				l.light_energy = 1.6 + sin(_now * 17.0 + b.get_instance_id()) * 0.25 + sin(_now * 7.3) * 0.15
	_update_bends(dt)
	_flush()
	# yenilenme
	if Engine.get_process_frames() % 30 == 0 and Game.player:
		var pp: Vector3 = Game.player.global_position
		for id in trees.keys():
			var st = trees[id]
			if st["state"] != "burn" and _now - float(st["t"]) > REGEN:
				var tr: Array = st["tr"]
				if Vector2(tr[0] - pp.x, tr[2] - pp.z).length() > REGEN_DIST:
					_restore_tree(id)
		for rec in active.duplicate():
			if not is_instance_valid(rec["body"]):
				active.erase(rec)   # bölge akıştan çıktı
				for k in ["proxy", "rubble_cs", "blaze"]:
					var n = rec.get(k)
					if n != null and is_instance_valid(n):
						n.queue_free()
				if rec.get("state", "") == "down":
					_down -= 1
			elif rec.get("state", "") in ["down", "scorch"] and _now - float(rec["t"]) > REGEN and rec["pos"].distance_to(pp) > REGEN_DIST:
				_restore_house(rec)


func _drain_houses() -> void:
	for rec in active.duplicate():
		if rec.get("state", "") != "burn" or not is_instance_valid(rec["body"]):
			continue
		var f = clampf((_now - float(rec["t"])) / float(rec["dur"]), 0.0, 1.0)
		if absf(f - float(rec["charf"])) > 0.06:
			rec["charf"] = f
			_house_char(rec, f * 0.8)
		if f >= 1.0:
			var b = rec.get("blaze")
			if b != null and is_instance_valid(b):
				_end_blaze(b)
			_house_burnt(rec)


## Akıştan çıkan bölgelerin ev kayıtlarını azar azar temizle (MultiMesh'leri bellekte tutmasın)
var _prune_keys: Array = []
func _prune() -> void:
	if _prune_keys.is_empty():
		if Engine.get_process_frames() % 120 != 0:
			return
		_prune_keys = hgrid.keys()
	for n in mini(48, _prune_keys.size()):
		var k = _prune_keys.pop_back()
		var lst = hgrid.get(k)
		if lst == null:
			continue
		var alive: Array = []
		for rec in lst:
			if is_instance_valid(rec["body"]):
				alive.append(rec)
		if alive.is_empty():
			hgrid.erase(k)
		elif alive.size() != lst.size():
			hgrid[k] = alive


func _spread(st: Dictionary) -> void:
	var tr: Array = st["tr"]
	var geo: Array = TREE_GEOM[int(tr[5])]
	var r = geo[2] * tr[3] * 1.8 + 4.0
	var p = Vector3(tr[0], tr[1], tr[2])
	var n := 0
	for o in _trees_near(p, r):
		if n >= 2 or blazes.size() >= MAX_BLAZE:
			break
		if Vector2(o[0] - tr[0], o[2] - tr[2]).length() > r:
			continue
		var oid = _tid(o)
		if trees.has(oid) or randf() > 0.45:
			continue
		n += 1
		var g = int(st["gen"]) + 1
		get_tree().create_timer(randf_range(0.5, 2.5)).timeout.connect(func():
			if not trees.has(oid):
				_ignite_tree(oid, o, g))


func _update_bends(dt: float) -> void:
	for b in bends.duplicate():
		b["t"] += dt
		var t: float = b["t"]
		# hızlı yatma, sonra sönümlü salınım
		var a = b["amp"] * (smoothstep(0.0, 0.18, t) * exp(-t * 1.3) * cos(maxf(t - 0.18, 0.0) * 5.5))
		var R = Basis(b["axis"], a)
		for e in b["inst"]:
			var o: PackedFloat32Array = e[2]
			var v: PackedFloat32Array = o.duplicate()
			if t <= 3.5:
				var nb = R * Basis(Vector3(o[0], o[4], o[8]), Vector3(o[1], o[5], o[9]), Vector3(o[2], o[6], o[10]))
				v[0] = nb.x.x; v[1] = nb.y.x; v[2] = nb.z.x
				v[4] = nb.x.y; v[5] = nb.y.y; v[6] = nb.z.y
				v[8] = nb.x.z; v[9] = nb.y.z; v[10] = nb.z.z
			_put(e[0], e[1], v)
		if t > 3.5:
			bends.erase(b)


# ------------------------------------------------------------------ yardımcı görseller
func _body_node() -> StaticBody3D:
	if _body == null or not is_instance_valid(_body):
		_body = StaticBody3D.new()
		_body.collision_layer = 1
		get_tree().current_scene.add_child(_body)
	return _body


func _loop(cfg: Dictionary) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.amount = cfg.get("amount", 12)
	p.lifetime = cfg.get("life", 3.0)
	p.explosiveness = 0.0
	p.randomness = 0.4
	p.fixed_fps = 30
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = cfg.get("radius", 1.0)
	pm.direction = Vector3.UP
	pm.spread = 25.0
	pm.initial_velocity_min = cfg.get("vmin", 1.0)
	pm.initial_velocity_max = cfg.get("vmax", 3.0)
	pm.gravity = cfg.get("gravity", Vector3.ZERO)
	pm.damping_min = cfg.get("damp", 0.5)
	pm.damping_max = cfg.get("damp", 0.5) * 1.5
	pm.scale_min = 0.6; pm.scale_max = 1.1
	pm.angle_min = 0; pm.angle_max = 360
	pm.angular_velocity_min = -cfg.get("spin", 0.0); pm.angular_velocity_max = cfg.get("spin", 0.0)
	pm.color_ramp = FX._gradient(cfg.get("colors", [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	pm.scale_curve = FX._curve(cfg.get("scale_curve", [[0.0, 0.6], [0.3, 1.0], [1.0, 1.2]]))
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2.ONE * cfg.get("size", 1.0)
	if cfg.has("tex"):
		q.size = Vector2(0.12, 0.6) * cfg.get("size", 1.0)
		pm.particle_flag_align_y = true
		q.material = FX._draw_mat(cfg["tex"], true, BaseMaterial3D.BILLBOARD_DISABLED)
	else:
		q.material = VFX.mat_puff(cfg.get("glow", 1.0), 0.0, cfg.get("outline_col", Color(0.2, 0.18, 0.18)), cfg.get("rough", 0.34), 0.3)
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-30, -10, -30), Vector3(60, 60, 60))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emitting = true
	return p


var _flame: SphereMesh
func _flame_mesh() -> SphereMesh:
	if _flame == null:
		_flame = SphereMesh.new()
		_flame.radius = 0.5
		_flame.height = 1.0
		_flame.radial_segments = 14
		_flame.rings = 8
	return _flame


func _tint_mat(c: Color) -> ShaderMaterial:
	var k = c.to_html()
	if _mats.has(k):
		return _mats[k]
	var m: ShaderMaterial = Props.toon().duplicate()
	m.set_shader_parameter("tint", c)
	_mats[k] = m
	if _mats.size() > 64:
		_mats.clear()
		_mats[k] = m
	return m


## Kömürleşmiş ağaç: yapraksız kara gövde + kırık dallar (yer yer kor)
func _char_mesh(t: int) -> ArrayMesh:
	if _char_meshes.has(t):
		return _char_meshes[t]
	var b = MB.new()
	var geo: Array = TREE_GEOM[t]
	var c = Color(0.13, 0.11, 0.1)
	var ember = Color(0.95, 0.35, 0.08)
	var th: float = geo[1] + geo[2] * 0.3
	var tr: float = geo[3] * 2.0
	if t == 3:
		b.add("cyl", Vector3(0, 1.6, 0), Vector3(0.6, 3.2, 0.6), c, Vector3.ZERO, 8)
	else:
		b.add_grad("cyl", Vector3(0, th * 0.5, 0), Vector3(tr, th, tr), Color(0.2, 0.17, 0.15), c, Vector3.ZERO, 8)
		var rng = RandomNumberGenerator.new()
		rng.seed = 900 + t
		var nb = 4 if t != 7 else 0
		if t in [5, 9]:
			nb = 7
		for i in nb:
			var y = th * rng.randf_range(0.45, 0.95)
			var a = rng.randf() * 360.0
			var L = geo[2] * rng.randf_range(0.5, 0.9)
			var d = Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
			var bw = tr * 0.35
			b.add("cyl", Vector3(0, y, 0), Vector3(bw, L, bw), c, Vector3(0, a, rng.randf_range(40.0, 60.0)), 5)
			b.add("sphere", Vector3(0, y, 0) + d * tr * 0.5, Vector3(bw * 1.3, bw * 0.6, bw * 1.3), ember, Vector3.ZERO, 5)
		# kor çatlakları
		for i in 3:
			var y2 = th * (0.2 + i * 0.22)
			b.add("sphere", Vector3(tr * 0.48, y2, 0).rotated(Vector3.UP, i * 2.1), Vector3(tr * 0.12, tr * 0.5, tr * 0.12), ember, Vector3.ZERO, 4)
	var m = b.build(Props.toon())
	_char_meshes[t] = m
	return m


## Kırık kütük (birim: yarıçap 1, boy 1; tepesi sivri kıymıklı)
func _stump() -> ArrayMesh:
	if _stump_mesh:
		return _stump_mesh
	var b = MB.new()
	var bark = Color(0.4, 0.27, 0.17)
	b.add("cyl", Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 2.0), bark, Vector3.ZERO, 8)
	var wood = Color(0.86, 0.72, 0.5)
	for i in 5:
		var a = i * TAU / 5.0
		b.add("cone", Vector3(cos(a) * 0.55, 1.15, sin(a) * 0.55), Vector3(0.6, 0.5 + (i % 3) * 0.2, 0.6), wood, Vector3.ZERO, 4)
	b.add("cyl", Vector3(0, 1.0, 0), Vector3(1.85, 0.06, 1.85), wood, Vector3.ZERO, 8)
	_stump_mesh = b.build(Props.toon())
	return _stump_mesh


## Moloz yığını (şablon başına): kırık duvar parçaları, kiremit levhaları, kırık kirişler, taşlar
func _rubble(ti: int, wall: Color, roof: Color) -> ArrayMesh:
	var key = "%d_%s_%s" % [ti, wall.to_html(), roof.to_html()]
	if _rubble_meshes.has(key):
		return _rubble_meshes[key]
	var t: Dictionary = HouseKit.templates[ti]
	var w: float = t["w"]; var d: float = t["d"]
	var b = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(key)
	var wood = Color(0.38, 0.26, 0.17).lerp(wall, 0.2 if wall.v > 0.3 else 0.6)
	for i in 34:
		var u = Vector2(rng.randf_range(-0.5, 0.5) * w, rng.randf_range(-0.5, 0.5) * d)
		var center = 1.0 - clampf(Vector2(u.x / (w * 0.5), u.y / (d * 0.5)).length(), 0.0, 1.0)
		var y = rng.randf_range(0.0, 1.0) * (0.4 + center * 1.6)
		var pick = rng.randf()
		var col = wall if pick < 0.45 else (roof if pick < 0.75 else HouseKit.STONE.lerp(wall, 0.3 if wall.v > 0.3 else 0.7))
		var sz = Vector3(rng.randf_range(0.6, 2.4), rng.randf_range(0.25, 0.9), rng.randf_range(0.6, 2.0))
		if pick >= 0.45 and pick < 0.75:
			sz = Vector3(rng.randf_range(1.5, 3.2), 0.18, rng.randf_range(1.2, 2.4))   # kiremit levhası
		b.add("box", Vector3(u.x, y, u.y), sz, col.lightened(0.08).darkened(rng.randf() * 0.12),
			Vector3(rng.randf_range(-35, 35), rng.randf() * 360.0, rng.randf_range(-35, 35)), 4)
	for i in 6:
		var u2 = Vector2(rng.randf_range(-0.4, 0.4) * w, rng.randf_range(-0.4, 0.4) * d)
		var L = rng.randf_range(2.5, 4.5)
		b.add("box", Vector3(u2.x, L * 0.3, u2.y), Vector3(0.28, L, 0.28), wood, Vector3(rng.randf_range(-55, 55), rng.randf() * 360.0, rng.randf_range(-20, 20)), 4)
	# taban: düşük toprak/moloz tümseği
	b.add_grad("sphere", Vector3(0, 0.0, 0), Vector3(w * 1.05, 1.6, d * 1.05), wall.darkened(0.15), Color(0.5, 0.44, 0.36), Vector3.ZERO, 8)
	var m = b.build(Props.toon())
	_rubble_meshes[key] = m
	return m


## Özel binalara (yıkılmaz) ateş isabeti: duvarda yanık izi
func _wall_scorch(pos: Vector3, normal: Vector3, r: float) -> void:
	var dec = Decal.new()
	dec.texture_albedo = _scorch_tex()
	dec.size = Vector3(r * 2.0, 2.0, r * 2.0)
	dec.cull_mask = 0xFFFFF
	get_tree().current_scene.add_child(dec)
	var up = normal.normalized()
	var side = up.cross(Vector3.UP).normalized() if absf(up.y) < 0.9 else Vector3.RIGHT
	dec.global_transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), pos)
	var tw = dec.create_tween()
	tw.tween_interval(40.0)
	tw.tween_property(dec, "modulate:a", 0.0, 4.0)
	tw.tween_callback(dec.queue_free)
	var all = get_tree().get_nodes_in_group("scorch")
	dec.add_to_group("scorch")
	if all.size() > 24:
		all[0].queue_free()


var _stex: ImageTexture
func _scorch_tex() -> ImageTexture:
	if _stex == null:
		var n = 64
		var img = Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d = Vector2(x - n * 0.5, y - n * 0.5).length() / (n * 0.5)
				var a = clampf(1.0 - d, 0.0, 1.0)
				a = a * a * (0.7 + 0.3 * sin(x * 0.7) * cos(y * 0.9))
				img.set_pixel(x, y, Color(0.06, 0.04, 0.03, clampf(a * 1.4, 0.0, 0.85)))
		_stex = ImageTexture.create_from_image(img)
	return _stex
