extends Node3D
## Bitki örtüsü (akışlı): oyuncu çevresinde 256 m'lik parçalar arka plan iş parçacıklarında deterministik üretilir
## (tohum = parça koordinatı). Yakında tam model, uzakta LOD; Ateş Ülkesi'nde 40-70 m'lik dallı dev ağaçlar.
## Oyuncunun çevresindeki ağaçlara gerçek çarpışma: gövde + dev orman ağaçlarında dallar -> dallarda koşulur.

const CH := 256.0
const NEAR_FULL := 420.0      # tam model görünürlüğü
const FAR_R := 2300.0         # en uzak parça
const DETAIL_R := 700.0       # bu mesafeden yakın parçalar tam kontrolle (eğim, küçük bitkiler) üretilir
const SMALL := [8, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20]    # küçük bitkiler / yer örtüsü: sadece yakında
const CONVEX := [4, 11]
const MAX_TASKS := 2
const MAX_BUILDS_PER_FRAME := 1
const INSTALL_BUDGET_US := 1500   # karede en fazla bu kadar kurulum (takılma olmasın)
const FAR_A := 1000.0          # bu mesafeden sonra yalnız seyreltilmiş vekil ağaçlar
const PROXY_T := [0, 1, 5, 9]
const DMAX := 0.02            # aday yoğunluğu (m² başına)

## biyom -> [yoğunluk / m², tipler]  (0 geniş ağaç, 1 çam, 2 kuru ağaç, 3 kaktüs, 4 kaya, 5 dev ağaç, 6 bambu,
## 7 palmiye, 8 çalı, 9 Konoha orman ağacı (dev, dallı), 10 eğrelti, 11 büyük kaya kümesi, 12 çiçek öbeği)
## 13 devrik kütük, 14 mantar, 15 uzun çimen, 16 saz, 17 kuru çalı, 18 meyveli çalı, 19 yosunlu kaya, 20 karlı kaya
const DENS := {2: [0.0125, [9, 9, 9, 9, 9, 0, 0, 8, 10, 10, 12, 6, 13, 14, 15, 18, 19, 15]], 4: [0.0035, [2, 2, 0, 8, 10, 16, 19, 14, 15]],
	5: [0.0032, [4, 11, 1, 8, 19, 17, 19, 15, 19]], 6: [0.0035, [0, 8, 6, 12, 12, 15, 15, 16, 18]], 7: [0.007, [0, 9, 8, 12, 12, 10, 15, 15, 18, 13, 19, 15, 12, 12, 12, 15]],
	8: [0.0055, [1, 1, 1, 1, 4, 20, 20, 20, 17]], 9: [0.0045, [1, 1, 4, 11, 8, 19, 20, 1]], 10: [0.0045, [2, 2, 0, 8, 10, 16, 16, 14, 13]],
	3: [0.0024, [3, 3, 4, 11, 17, 17, 17, 17, 4, 3]], 1: [0.0012, [7, 8, 15, 7]]}

var meshes = {}
var lods = {}
## görünen gövde yarıçapları (çarpışma görselle birebir olsun: ayak havada kalmasın)
var radii = {0: 0.38, 1: 0.36, 2: 0.3, 3: 0.36, 4: 1.0, 5: 3.2, 6: 0.0, 7: 0.25, 8: 0.0, 9: Props.FOREST_TRUNK_R, 10: 0.0, 11: 1.0, 12: 0.0,
	13: 0.0, 14: 0.0, 15: 0.0, 16: 0.0, 17: 0.0, 18: 0.0, 19: 0.0, 20: 0.0}
var convex = {}
var var_count = {}     # tip -> varyant sayısı (iş parçacıkları okur)
var bodies: Array[StaticBody3D] = []
var body_tree: Array = []   # gövde -> atanmış ağaç kimliği
var chunks := {}        # Vector2i -> {node, detail: bool, trees: Array}
var tasks := {}         # Vector2i -> [task_id, detail, result holder]
var ready_q: Array = []
var queued := {}        # ready_q'daki anahtarlar (tekrar istenmesin)
var last_cell = Vector2i(999999, 999999)
var _mutex := Mutex.new()
var _specials: Array = []   # [x, y(harita), iç r, dış r, tip, yoğunluk]
var _hrock := Vector4.ZERO   # Hokage Kayası (x0, x1, yüz hattı harita y, tepe): yar yüzünde bitki yok
var _walls: Array = []      # [x, y(harita), sur yarıçapı]: sur boyunca ağaçsız şerit (dev ağaçlar sura/kapıya giriyordu)


func _ready() -> void:
	for t in 21:
		# prosedürel bitki örtüsü (hazır model ağaçlar doğal durmuyordu, kaldırıldı): yakın tam model + uzak LOD
		meshes[t] = [[Props.vegetation_mesh(t), null]]
		var_count[t] = 1
		if t == 12:   # çiçek öbekleri: 6 farklı tür (öbek öbek, her öbekte tek tür)
			meshes[t] = []
			for v in Props.FLOWER_KINDS:
				meshes[t].append([Props.flower_mesh(v), null])
			var_count[t] = Props.FLOWER_KINDS
		lods[t] = Props.vegetation_lod(t)
	for t in CONVEX:
		convex[t] = []
		for v in meshes[t]:
			convex[t].append((v[0] as ArrayMesh).create_convex_shape(true, true))
	# köy çevresi orman halkaları + özel ormanlar
	for v in Game.world_info["villages"]:
		if v["id"] in ["konoha", "kusa", "taki", "tani"]:
			_specials.append([float(v["x"]), float(v["y"]), float(v["r"]) + 30.0, float(v["r"]) + 700.0, 9, 0.009])
	for v in Game.world_info["villages"]:
		var hr: Dictionary = v.get("hokage_rock", {})
		if not hr.is_empty():
			_hrock = Vector4(float(hr["x0"]), float(hr["x1"]), float(hr["y"]), float(hr["top"]))
		if v["id"] == "konoha":
			_walls.append([float(v["x"]), float(v["y"]), float(v["r"]) - 40.0])
		elif BuildSites.RING_WALLS.has(v["id"]) or not (v.get("gates", []) as Array).is_empty():
			_walls.append([float(v["x"]), float(v["y"]), float(v["r"]) * 0.95])
	for l in Game.world_info["landmarks"]:
		match l["id"]:
			"forest_death":
				_specials.append([float(l["x"]), float(l["y"]), 0.0, float(l["r"]), 5, 0.0009])
				_specials.append([float(l["x"]), float(l["y"]), 0.0, float(l["r"]), 9, 0.004])
			"nara_forest":
				_specials.append([float(l["x"]), float(l["y"]), 0.0, float(l["r"]), 9, 0.012])
	# yakın ağaç çarpışma havuzu: her gövde 1 silindir + 6 dal kutusu
	for k in 70:
		var sb = StaticBody3D.new()
		sb.collision_layer = 1
		var cs = CollisionShape3D.new()
		cs.shape = CylinderShape3D.new()
		cs.set_meta("cyl", cs.shape)
		sb.add_child(cs)
		for br in Props.FOREST_BRANCHES:
			var bc = CollisionShape3D.new()
			bc.shape = BoxShape3D.new()
			sb.add_child(bc)
		sb.position = Vector3(0, -2000, 0)
		add_child(sb)
		bodies.append(sb)
		body_tree.append(null)


func _focus() -> Vector3:
	if Game.player:
		return Game.player.global_position
	var cam = get_viewport().get_camera_3d()
	return cam.global_position if cam else Vector3.ZERO


func _process(_dt: float) -> void:
	var p := _focus()
	var view = float(Game.settings["view"])
	var far_r = FAR_R * clampf(view, 0.5, 1.6)
	var pc := Vector2(p.x, p.z)
	# 1) tamamlanan işleri al
	for key in tasks.keys():
		var t: Array = tasks[key]
		if WorkerThreadPool.is_task_completed(t[0]):
			WorkerThreadPool.wait_for_task_completion(t[0])
			ready_q.append([key, t[1], t[2]])
			queued[key] = t[1]
			tasks.erase(key)
	# 2) hazır parçaları zaman bütçesiyle sahneye ekle (en yakın önce; sıralama yerine doğrusal seçim)
	var t0 := Time.get_ticks_usec()
	while not ready_q.is_empty() and Time.get_ticks_usec() - t0 < INSTALL_BUDGET_US:
		var bi := 0
		var bd := 1e18
		for i in ready_q.size():
			var d := _cdist(ready_q[i][0], pc)
			if d < bd:
				bd = d
				bi = i
		var r: Array = ready_q[bi]
		ready_q.remove_at(bi)
		queued.erase(r[0])
		if bd <= far_r + CH:
			_install(r[0], r[1], r[2])
	# 3) gerekli parçaları iste, uzaktakileri sil
	var ck := Vector2i(floori(p.x / CH), floori(p.z / CH))
	var rad := int(ceil(far_r / CH)) + 1
	var want: Array = []
	for dz in range(-rad, rad + 1):
		for dx in range(-rad, rad + 1):
			var k := ck + Vector2i(dx, dz)
			var d := _cdist(k, pc)
			if d > far_r:
				continue
			var need_detail := d < DETAIL_R
			var have = chunks.get(k)
			if have != null and (have["detail"] or not need_detail):
				continue
			if tasks.has(k) and (tasks[k][1] or not need_detail):
				continue
			if queued.has(k) and (queued[k] or not need_detail):
				continue
			want.append([d, k, need_detail])
	want.sort_custom(func(a, b): return a[0] < b[0])
	for w in want:
		if tasks.size() >= MAX_TASKS:
			break
		var holder := {}
		var key: Vector2i = w[1]
		var det: bool = w[2]
		var id = WorkerThreadPool.add_task(_generate.bind(key, det, holder), false, "veg")
		tasks[key] = [id, det, holder]
	for k in chunks.keys():
		if _cdist(k, pc) > far_r + CH * 1.5:
			chunks[k]["node"].queue_free()
			chunks.erase(k)


func _cdist(k: Vector2i, pc: Vector2) -> float:
	return Vector2((k.x + 0.5) * CH, (k.y + 0.5) * CH).distance_to(pc)


## İş parçacığında: parçanın bitkilerini deterministik üretir -> holder["buf"][tip] = MultiMesh tamponu
func _generate(key: Vector2i, detail: bool, holder: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(key.x, key.y, 7177))
	var cx := (key.x + 0.5) * CH
	var cz := (key.y + 0.5) * CH
	var bufs := {}
	var trees := []
	var cands := int(DMAX * CH * CH)
	var area_scale := 1.0 / DMAX
	for i in cands:
		var x := key.x * CH + rng.randf() * CH
		var z := key.y * CH + rng.randf() * CH
		var u := rng.randf()
		var pick := rng.randf()
		var sc_r := rng.randf()
		var yaw := rng.randf() * TAU
		var b := Game.biome_at(x, z)
		var row = DENS.get(b)
		var dens := 0.0
		var types: Array = []
		if row != null:
			dens = row[0]
			types = row[1]
		var my := -z
		for sp in _specials:
			var d := Vector2(x - sp[0], my - sp[1]).length()
			if d > sp[2] and d < sp[3] and b != 11 and b < 13:
				dens = maxf(dens, sp[5])
				types = [sp[4], sp[4], 9, 0, 10, 8] if sp[4] == 5 else [9, 9, 9, 0, 10, 8]
		if dens <= 0.0:
			continue
		var clear := Game._wh_vn(x / 260.0, z / 260.0, 11) * 0.6 + Game._wh_vn(x / 130.0, z / 130.0, 12) * 0.4
		var local := 0.35 + 1.3 * Game._wh_vn(x / 400.0, z / 400.0, 13)
		var t: int = types[int(pick * types.size()) % types.size()]
		# açıklıklar yalnız ağaçları seyreltir; yer örtüsü (çalı, kaya, çimen, çiçek) açıklıkta da azalarak sürer
		var cf := smoothstep(0.3, 0.42, clear)
		if not t in [0, 1, 2, 5, 9, 6, 7]:
			cf = 0.4 + 0.6 * cf
		if u > dens * area_scale * local * cf:
			continue
		if not detail and t in SMALL:
			continue
		var wet := Game.wet_at(x, z)
		if wet > 0.4:
			# su kenarı: saz ve kamış
			if detail and wet < 0.8 and rng.randf() < 0.5:
				t = 16
			else:
				continue
		if radii[t] > 0.0 or t in [9, 5, 0, 1, 2, 4]:
			var near_wall := false
			for wl in _walls:
				var wd: float = absf(Vector2(x - wl[0], my - wl[1]).length() - wl[2])
				if wd < (75.0 if t in [9, 5] else 28.0):
					near_wall = true
					break
			if near_wall:
				continue
		if not Roadside.is_clear(x, -z, 11.0 if t in [9, 5] else (3.0 if t in [0, 1, 2] else 0.0), 0.35 if t in SMALL else 1.0):
			continue
		var rdist := Game.road_dist(x, z)
		if rdist < (16.0 if t in [9, 5] else (3.5 if t in [15, 12, 19, 14] else 8.0)):
			continue
		var h := Game.terrain_height(x, z)
		if h < (0.15 if t == 16 else 0.8):
			continue
		# eğim filtresi detaylı/uzak üretimde AYNI olmalı: yoksa yaklaşınca parça yeniden kurulurken ağaçlar kaybolur
		var hx := Game.terrain_height(x + 2.0, z) - h
		var hz := Game.terrain_height(x, z + 2.0) - h
		var sl := Vector2(hx, hz).length() / 2.0
		if sl > 1.1:
			continue
		if _hrock.w > 0.0 and sl > 0.22 and x > _hrock.x - 700.0 and x < _hrock.y + 700.0 and my > _hrock.z - 80.0 and my < _hrock.z + 320.0:
			continue   # Hokage Kayası yüzü: duvardan ağaç çıkmasın
		if t in [9, 0] and sl > 0.7:
			t = 4
		var s := lerpf(0.8, 1.3, sc_r)
		if t == 9:
			s = lerpf(1.5, 2.6, sc_r)   # anime ölçeği: 40-70 m dev orman ağaçları
		elif t == 5:
			s = lerpf(0.9, 1.4, sc_r)
		elif t == 12:
			s = lerpf(1.6, 2.4, sc_r)   # çiçek öbekleri uzaktan da renk lekesi olarak görünsün
		var col := 1.0 + (rng.randf() - 0.5) * 0.2
		var nv: int = var_count.get(t, 1)
		var vi := int(rng.randf() * nv) % nv
		# yer örtüsü: düzgün serpme yerine doğal öbekler; her öbekte tek tür
		if t in [8, 10, 12, 15, 18]:
			var patch := Game._wh_vn(x / 38.0, z / 38.0, 20 + t)
			var need := (0.46 if t == 12 else 0.62) if t in [12, 18] else 0.5   # çiçek öbekleri daha sık (çayırlar boş durmasın)
			if b == 2 and t in [12, 18]:
				need = 0.74   # orman zemininde çiçek az
			if patch < need:
				continue
			vi = int(Game._wh_vn(x / 90.0, z / 90.0, 40 + t) * 7.0) % nv
		var bk := t * 100 + vi
		if not bufs.has(bk):
			bufs[bk] = PackedFloat32Array()
		var c := cos(yaw) * s
		var sn := sin(yaw) * s
		var ox := x - cx
		var oz := z - cz
		# MultiMesh tamponu: 3x4 satır düzeni + renk
		bufs[bk].append_array([c, 0.0, sn, ox, 0.0, s, 0.0, h - 0.3, -sn, 0.0, c, oz, col, 1.0 + (col - 1.0) * 0.6, 1.0 - (col - 1.0) * 0.4, 1.0])
		if t == 12:
			# çiçek tarlası: aynı türden 5 öbek daha çevresine (tek tek kayboluyordu; çayırda renk lekesi olsun)
			for k in 5:
				var fx := x + rng.randf_range(-7.0, 7.0)
				var fz := z + rng.randf_range(-7.0, 7.0)
				var fh := Game.terrain_height(fx, fz)
				var fy := rng.randf() * TAU
				var fc := cos(fy) * s
				var fs := sin(fy) * s
				bufs[bk].append_array([fc, 0.0, fs, fx - cx, 0.0, s, 0.0, fh - 0.3, -fs, 0.0, fc, fz - cz, col, 1.0, 1.0, 1.0])
		if detail and radii[t] > 0.0:
			trees.append([x, h, z, s, yaw, t, vi])
	holder["buf"] = bufs
	holder["trees"] = trees


var _trunk_cache := {}   # parça -> ağaç listesi (görev/olay noktası seçimi için; parça kurulu olmasa da deterministik üretilir)
## (x, z) çevresinde pad mesafede ağaç gövdesi var mı (dev orman ağaçlarının kök yayılımı dahil)
func trunk_near(x: float, z: float, pad := 2.0) -> bool:
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var key = Vector2i(floori((x + dx * 30.0) / CH), floori((z + dz * 30.0) / CH))
			var trees: Array
			if chunks.has(key) and chunks[key]["detail"]:
				trees = chunks[key]["trees"]
			else:
				if not _trunk_cache.has(key):
					var h := {}
					_generate(key, true, h)
					_trunk_cache[key] = h.get("trees", [])
				trees = _trunk_cache[key]
			for tr in trees:
				var t: int = int(tr[5])
				var r: float = float(radii.get(t, 0.0)) * (float(tr[3]) if t != 9 else 1.0)
				if t in [9, 5]:
					r = r * 3.2 + 1.5   # dev ağaç kökleri gövdeden dışarı yayılır
				if Vector2(float(tr[0]) - x, float(tr[2]) - z).length() < r + pad:
					return true
	return false


func _install(key: Vector2i, detail: bool, holder: Dictionary) -> void:
	if not holder.has("buf"):
		return
	var old = chunks.get(key)
	if old != null:
		old["node"].queue_free()
	var node := Node3D.new()
	node.position = Vector3((key.x + 0.5) * CH, 0, (key.y + 0.5) * CH)
	add_child(node)
	var view = float(Game.settings["view"])
	var bufs: Dictionary = holder["buf"]
	var lod_done := {}
	for bk in bufs:
		var t: int = int(bk) / 100
		var vi: int = int(bk) % 100
		var buf: PackedFloat32Array = bufs[bk]
		var n := buf.size() / 16
		if n == 0:
			continue
		var pv: Array = meshes[t][mini(vi, meshes[t].size() - 1)]
		var near_end = (NEAR_FULL if not t in SMALL else (240.0 if t in [13, 19, 20, 17] else 130.0)) * view
		if t in [5, 11, 4, 9]:
			near_end = 650.0 * view
		var has_lod = lods[t] != null
		if pv.size() >= 3 and pv[1] != null and not t in SMALL:
			# hazır model: yakında tam detay, orta mesafede basitleştirilmiş, en uzakta çok basit kopya
			var full_end = (75.0 if t in [0, 1, 2, 8, 6] else (110.0 if t == 9 else 140.0)) * view
			# yapraklı ağaçlarda orta kopya (seyreltilmiş yaprak kartları) 260 m'ye kadar; ötesi opak vekil
			var mid_end = (260.0 if t in [0, 1] else 420.0) * view
			var a = _mmi(node, pv[0], buf, n, 0.0, full_end)
			# gölgeyi tam model değil basit kopya atar (yaprak alfa-kesme + binlerce üçgen x 4 gölge katmanı GPU'yu boğuyordu)
			a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not t in [8, 10, 12, 14, 15, 18, 19]:
				# yapraklı ağaçlar: gölge opak vekilden (alfa-kesmeli yaprak gölgesi 4 katmanda çok pahalı)
				var sh = _mmi(node, _proxy(t) if t in PROXY_T else pv[2], buf, n, 0.0, full_end)
				sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			var m2 = _mmi(node, pv[1], buf, n, full_end, mid_end)
			m2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not t in [8, 10, 12, 14, 15, 18, 19]:
				# uzak: 420-1000 m arası pakete ait basit kopya (tümü), ötesi sadece büyük ağaçlar için seyreltilmiş ucuz vekil
				var far_a = FAR_A * view
				# yapraklı ağaçlarda uzak kopya opak vekil (yaprak kartları uzakta pahalı ve basitleştirince bozuluyor)
				var m3 = _mmi(node, _proxy(t) if t in PROXY_T else pv[2], buf, n, mid_end, far_a if t in PROXY_T else FAR_A * 0.75 * view)
				m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				if t in PROXY_T:
					var sub := _subsample(buf, n, 3)
					var m4 = _mmi(node, _proxy(t), sub, sub.size() / 16, far_a, FAR_R * 1.2 * view)
					m4.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			var a = _mmi(node, pv[0], buf, n, 0.0, near_end if has_lod or t in SMALL else FAR_R * 1.2 * view)
			a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if not t in SMALL else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if has_lod and not lod_done.has(t):
			lod_done[t] = true
			var all_buf := PackedFloat32Array()
			for bk2 in bufs:
				if int(bk2) / 100 == t:
					all_buf.append_array(bufs[bk2])
			var lb = _mmi(node, lods[t], all_buf, all_buf.size() / 16, near_end, FAR_R * 1.2 * view)
			lb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunks[key] = {"node": node, "detail": detail, "trees": holder.get("trees", [])}
	if detail:
		# ağaç tamponlarının CPU kopyası: WorldDamage örnekleri GPU'dan geri okumadan (takılmasız) gizler/karartır
		var wb := {}
		for bk in bufs:
			if int(bk) / 100 in WorldDamage.TREE_T:
				wb[int(bk)] = bufs[bk]
		chunks[key]["wdbufs"] = wb
	last_cell = Vector2i(999999, 999999)  # çarpışma havuzunu tazele
	WorldDamage.veg_installed(key, node)   # yanmış/devrilmiş ağaçlar yeni örneklerde de öyle kalsın


## Her n'inci örnek (uzak mesafe seyreltme; deterministik)
static func _subsample(buf: PackedFloat32Array, n: int, step: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in range(0, n, step):
		out.append_array(buf.slice(i * 16, i * 16 + 16))
	return out


var _proxies := {}
## Çok uzak ağaç vekili: ~30 üçgen (gövde yok; koyu tepe + tek renk taç)
func _proxy(t: int) -> ArrayMesh:
	if _proxies.has(t):
		return _proxies[t]
	var b = MB.new()
	match t:
		1:
			b.add_grad("cone", Vector3(0, 7.5, 0), Vector3(5.4, 13, 5.4), Color(0.2, 0.42, 0.3), Color(0.07, 0.2, 0.14), Vector3.ZERO, 5)
		5:
			b.add_grad("sphere", Vector3(0, 52, 0), Vector3(34, 20, 34), Color(0.22, 0.42, 0.2), Color(0.06, 0.16, 0.07), Vector3.ZERO, 4)
			b.add("cyl", Vector3(0, 22, 0), Vector3(5.0, 44, 5.0), Color(0.3, 0.2, 0.14), Vector3.ZERO, 3)
		9:
			b.add_grad("sphere", Vector3(0, Props.FOREST_TRUNK_H - 4.0, 0), Vector3(22, 16, 22), Color(0.32, 0.6, 0.24), Color(0.1, 0.26, 0.1), Vector3.ZERO, 4)
			b.add("cyl", Vector3(0, Props.FOREST_TRUNK_H * 0.4, 0), Vector3(Props.FOREST_TRUNK_R * 2.0, Props.FOREST_TRUNK_H * 0.8, Props.FOREST_TRUNK_R * 2.0), Color(0.36, 0.25, 0.17), Vector3.ZERO, 3)
		_:
			b.add_grad("sphere", Vector3(0, 7.0, 0), Vector3(8.5, 7.0, 8.5), Color(0.34, 0.6, 0.24), Color(0.12, 0.3, 0.12), Vector3.ZERO, 4)
	var m = b.build(Props.foliage())
	_proxies[t] = m
	return m


func _mmi(parent: Node3D, mesh: Mesh, buf: PackedFloat32Array, n: int, begin: float, end: float) -> MultiMeshInstance3D:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = n
	mm.buffer = buf
	var mmi = MultiMeshInstance3D.new()
	mmi.layers = 2
	mmi.multimesh = mm
	mmi.visibility_range_begin = begin
	mmi.visibility_range_begin_margin = 25.0 if begin > 0.0 else 0.0
	mmi.visibility_range_end = end
	mmi.visibility_range_end_margin = 40.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mmi)
	return mmi


func _physics_process(_dt: float) -> void:
	if Game.player == null:
		return
	var p = Game.player.global_position
	var c = Vector2i(int(floor(p.x / 16.0)), int(floor(p.z / 16.0)))
	if c == last_cell:
		return
	last_cell = c
	var near: Array = []
	var ck := Vector2i(floori(p.x / CH), floori(p.z / CH))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch = chunks.get(ck + Vector2i(dx, dz))
			if ch == null:
				continue
			for tr in ch["trees"]:
				var d2 = Vector2(tr[0] - p.x, tr[2] - p.z).length_squared()
				if d2 < 90.0 * 90.0 and not WorldDamage.gone.has(Vector3i(int(tr[0] * 10.0), int(tr[2] * 10.0), int(tr[5]))):
					near.append([d2, tr])
	near.sort_custom(func(a, b): return a[0] < b[0])
	near = near.slice(0, bodies.size())
	var want := {}
	for e in near:
		var tr: Array = e[1]
		want[Vector3i(int(tr[0] * 10.0), int(tr[2] * 10.0), int(tr[5]))] = tr
	# hâlâ yakında olan ağaçların gövdelerine dokunma; serbest kalanları yeni ağaçlara ver
	var free_b: Array = []
	for k in bodies.size():
		var id = body_tree[k]
		if id != null and want.has(id):
			want.erase(id)
		else:
			body_tree[k] = null
			free_b.append(k)
	var todo: Array = want.keys()
	for k in free_b:
		var sb = bodies[k]
		if todo.is_empty():
			if sb.position.y > -1000.0:
				sb.position = Vector3(0, -2000, 0)
			continue
		var tid = todo.pop_back()
		body_tree[k] = tid
		var tr: Array = want[tid]
		var t: int = tr[5]
		var s: float = tr[3]
		var yaw: float = tr[4]
		sb.global_transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(tr[0], tr[1] - 0.3, tr[2]))
		var trunk: CollisionShape3D = sb.get_child(0)
		if t in CONVEX:
			trunk.shape = convex[t][mini(int(tr[6]) if tr.size() > 6 else 0, convex[t].size() - 1)]
			trunk.scale = Vector3.ONE * s
			trunk.position = Vector3(0, 0.3, 0)
			for b in Props.FOREST_BRANCHES.size():
				(sb.get_child(b + 1) as CollisionShape3D).disabled = true
			continue
		trunk.shape = trunk.get_meta("cyl")
		trunk.scale = Vector3.ONE
		var sh: CylinderShape3D = trunk.shape
		var h = 10.0 * s
		match t:
			9: h = Props.FOREST_TRUNK_H * s
			5: h = 60.0 * s
			4: h = 2.2 * s
			11: h = 4.5 * s
			1: h = 9.0 * s
			0: h = 6.5 * s
		sh.radius = radii[t] * s
		sh.height = h
		trunk.position = Vector3(0, h * 0.5, 0)
		for b in Props.FOREST_BRANCHES.size():
			var bc: CollisionShape3D = sb.get_child(b + 1)
			bc.disabled = t != 9
			if t == 9:
				var br: Array = Props.FOREST_BRANCHES[b]
				var a = deg_to_rad(br[1])
				var L: float = br[2]
				var d = Vector3(sin(a), 0, cos(a))
				(bc.shape as BoxShape3D).size = Vector3(1.4, 0.8, L) * s
				bc.transform = Transform3D(Basis(Vector3.UP, a), (d * (Props.FOREST_TRUNK_R + L * 0.5) + Vector3(0, br[0], 0)) * s)


## Bir noktada yüklenmiş en yakın ağaçlar (başka sistemler için: ör. hayvanlar, kamp yerleşimi)
func is_ready_around(p: Vector3) -> bool:
	return chunks.has(Vector2i(floori(p.x / CH), floori(p.z / CH)))
