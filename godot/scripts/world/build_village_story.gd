class_name BuildVillageStory
extends RefCounted
## Hikâyenin her büyük köyde oynanabilmesi için: Akademi, antrenman alanı, gözetleme kulesi, hastane, ANBU binası
## (Konoha dışındaki büyük köylerde, köyün hemen dışında bir yerleşke) + her büyük köyde Aranıyor Panosu (Bingo Kitabı).
## Konumlar köy merkezine göredir; dünya ölçeği değişse de çalışır.

const STYLE := {
	"suna": {"wall": Color(0.84, 0.72, 0.52), "roof": Color(0.72, 0.58, 0.4), "accent": Color(0.35, 0.55, 0.35), "label": "Suna"},
	"kiri": {"wall": Color(0.62, 0.68, 0.72), "roof": Color(0.3, 0.42, 0.55), "accent": Color(0.25, 0.45, 0.65), "label": "Kiri"},
	"kumo": {"wall": Color(0.88, 0.88, 0.86), "roof": Color(0.35, 0.5, 0.7), "accent": Color(0.85, 0.75, 0.3), "label": "Kumo"},
	"iwa": {"wall": Color(0.62, 0.52, 0.42), "roof": Color(0.5, 0.28, 0.22), "accent": Color(0.6, 0.3, 0.2), "label": "Iwa"},
}


static func build_all(parent: Node3D) -> void:
	# köyler akışla (yakına gelince) kurulabildiği için panolar görev masası belirince eklenir
	var w = BoardWatcher.new()
	w.name = "BountyBoards"
	w.parent3d = parent
	parent.add_child(w)
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var v = Game.village(vid)
		if v.is_empty():
			continue
		if STYLE.has(vid):
			_compound(parent, v, STYLE[vid])


## Önemli yapılar köyün içine DAĞITILIR (tek yerleşkede kümelenmez): her biri kendi açısında ve uzaklığında, kapı yollarından
## uzak, birbirinden en az MIN_SEP m. Konumlar köy kimliğiyle tohumlanır (her açılışta aynı). Evler her yapının çevresine girmez.
const INSIDE := ["suna", "kiri", "kumo", "iwa"]
const MIN_SEP := 110.0
## yapı -> evlerin girmeyeceği yarıçap (avlu ve çevresi dahil)
const CLEAR := {"stadium": 92.0, "academy": 62.0, "training": 34.0, "lookout": 24.0, "hospital": 34.0, "anbu": 40.0}


static func _sites(v: Dictionary) -> Dictionary:
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r = float(v.get("r", 250))
	var gates: Array = v.get("gates", [])
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(String(v.get("id", "")) + "_yapilar")
	var out = {}
	var taken: Array = []
	var inside = String(v.get("id", "")) in INSIDE
	var keys = []
	for key in ["stadium", "academy", "hospital", "anbu", "training", "lookout"]:
		var best = Vector2.INF
		var best_score = -1e9
		for k in 60:
			var a = rng.randf_range(0.0, 360.0)
			var ring = r * rng.randf_range(0.32, 0.72) if inside else r + rng.randf_range(60.0, 140.0)
			var gate_d = 180.0
			for g in gates:
				gate_d = minf(gate_d, absf(fmod(a - float(g) + 540.0, 360.0) - 180.0))
			if gate_d < 14.0:
				continue   # kapıdan merkeze giden ana cadde üstüne kurulmaz
			var rad = deg_to_rad(a)
			var p = c + Vector2(sin(rad), cos(rad)) * ring
			var h0 = Game.terrain_height(p.x, -p.y)
			if h0 < 1.0:
				continue
			var po = p - c
			if String(v.get("id", "")) == "kiri" and absf(po.x) < r * 0.8 and po.y > r * 0.15:
				continue   # Kiri'nin kuzey gölü
			var sep = 1e9
			var ok = true
			for qi in taken.size():
				var dq = p.distance_to(taken[qi])
				sep = minf(sep, dq)
				# yapıların kendi boşlukları birbirine girmesin (stadyum büyük)
				if dq < maxf(MIN_SEP, float(CLEAR[key]) + float(CLEAR[keys[qi]]) + 15.0):
					ok = false
			if not ok:
				continue
			var var_h = 0.0
			for o in [Vector2(40, 0), Vector2(-40, 0), Vector2(0, 30), Vector2(0, -30)]:
				var_h += absf(Game.terrain_height(p.x + o.x, -(p.y + o.y)) - h0)
			var score = minf(gate_d, 50.0) - var_h * 2.0 + minf(sep, 300.0) * 0.05 + rng.randf() * 10.0
			if score > best_score:
				best_score = score
				best = p
		if best == Vector2.INF:
			best = c + Vector2(r * 0.5, 0).rotated(taken.size() * 1.3)
		taken.append(best)
		keys.append(key)
		out[key] = best
	return out


## Eski kayıtların / başka kodların beklediği tek nokta: akademi
static func _site(v: Dictionary) -> Vector2:
	return _sites(v)["academy"]


static func _compound(parent: Node3D, v: Dictionary, sty: Dictionary) -> void:
	var sites = _sites(v)
	var wall: Color = sty["wall"]; var roof: Color = sty["roof"]; var acc: Color = sty["accent"]
	var vn: String = v["name"]
	# --- Akademi binası + avlu kuklaları
	var p: Vector2 = sites["academy"]
	var base = Game.terrain_height(p.x, -p.y)
	var b = Builder.new(parent, p.x, p.y, base, "Story_%s_akademi" % v["id"])
	var ay = Game.terrain_height(p.x, -p.y) - base
	b.box(Vector3(0, ay + 1.0, 0), Vector3(30, 2.0 + 4.0, 15), wall.darkened(0.25))  # temel
	b.box(Vector3(0, ay + 6.5, 0), Vector3(28, 9, 13), wall)
	b.roof(Vector3(0, ay + 11.0, 0), Vector3(31, 4.5, 16), roof)
	b.box(Vector3(0, ay + 3.5, -6.6), Vector3(3.2, 5.0, 0.4), Color(0.3, 0.22, 0.15), 0.0, false)
	b.disc(Vector3(0, ay + 9.0, -6.7), 3.2, 0.3, acc)
	for i in 6:
		b.box(Vector3(-11 + i * 4.4, ay + 7.5, -6.6), Vector3(2.0, 1.6, 0.3), Color(0.55, 0.72, 0.85), 0.0, false)
	b.interact(Vector3(0, ay, -8.0), 4, "enter", "[F] Gir: %s Ninja Akademisi" % vn, {"room": "academy", "alias": "academy", "vid": v["id"], "out": b.w(Vector3(0, ay, -9.5))})
	var arng = RandomNumberGenerator.new()
	arng.seed = hash(v["id"] + "_akademi")
	AcademyGrounds.dress(b, 0.0, -6.5, 30.0, 44.0, arng, {"vid": v["id"], "climate": {"suna": "desert", "iwa": "dry", "kumo": "dry"}.get(v["id"], "green"),
		"flag": acc, "roof": roof, "bw": 28.0, "scale": 0.6, "flag_kanji": {"suna": "砂", "kiri": "霧", "kumo": "雲", "iwa": "岩"}.get(v["id"], "忍")})
	for i in 4:
		b.lantern(-12 + i * 8, -12)
	b.finish()
	# --- antrenman alanı (ayrı yerde)
	p = sites["training"]
	base = Game.terrain_height(p.x, -p.y)
	b = Builder.new(parent, p.x, p.y, base, "Story_%s_antrenman" % v["id"])
	var g = func(x: float, n: float) -> float:
		return Game.terrain_height(p.x + x, -(p.y + n)) - base
	for i in 10:
		var a = TAU * i / 10.0
		b.cyl(Vector3(cos(a) * 13, g.call(cos(a) * 13, sin(a) * 13) + 1.0, sin(a) * 13), 0.5, 2.0 + 4.0, Color(0.45, 0.33, 0.2), true, 6)
	for i in 3:
		Spawner.dummy(b.w(Vector3(-5 + i * 5, g.call(-5 + i * 5, 0), 0)))
	b.interact(Vector3(0, g.call(0, -12), -12), 6, "training", "[F] Antrenman yap (chakra kontrolü)")
	b.finish()
	# --- gözetleme kulesi (duvar koşusuyla tırmanılır, 40 m)
	p = sites["lookout"]
	base = Game.terrain_height(p.x, -p.y)
	b = Builder.new(parent, p.x, p.y, base, "Story_%s_kule" % v["id"])
	b.cyl(Vector3(0, 19.0, 0), 9.0, 42.0, wall.darkened(0.15), true, 14)
	b.cyl(Vector3(0, 40.6, 0), 14.0, 1.2, roof, true, 16)
	for k in 8:
		var a = TAU * k / 8.0
		b.box(Vector3(cos(a) * 6.6, 41.8, sin(a) * 6.6), Vector3(1.2, 1.2, 1.2), roof.darkened(0.2), rad_to_deg(a), true)
	b.interact(Vector3(0, 41.3, 0), 8, "lookout", "[F] Köyü seyret (kayıt)")
	b.finish()
	# --- hastane
	p = sites["hospital"]
	base = Game.terrain_height(p.x, -p.y)
	b = Builder.new(parent, p.x, p.y, base, "Story_%s_hastane" % v["id"])
	b.box(Vector3(0, 0.5, 0), Vector3(18, 3.0, 12), wall.darkened(0.25))
	b.box(Vector3(0, 4.5, 0), Vector3(17, 7, 11), Color(0.92, 0.92, 0.9))
	b.roof(Vector3(0, 8.0, 0), Vector3(19, 3.0, 13), Color(0.75, 0.2, 0.2))
	b.disc(Vector3(0, 5.5, -5.6), 2.4, 0.3, Color(0.85, 0.15, 0.15))
	b.box(Vector3(0, 2.4, -5.6), Vector3(3.0, 4.4, 0.4), Color(0.3, 0.22, 0.15), 0.0, false)   # kapı
	b.interact(Vector3(0, 0, -7.0), 4, "enter", "[F] Gir: %s Hastanesi" % vn, {"room": "hospital", "vid": v["id"], "out": b.w(Vector3(0, 0, -9.0))})
	for i in 3:
		b.lantern(-6 + i * 6, -10)
	b.finish()
	# --- Chūnin Sınavı final stadyumu (köyün renginde)
	p = sites["stadium"]
	base = Game.terrain_height(p.x, -p.y)
	b = Builder.new(parent, p.x, p.y, base, "Story_%s_stadyum" % v["id"])
	var srng = RandomNumberGenerator.new()
	srng.seed = hash(v["id"] + "_stadyum")
	var kdir = rad_to_deg(atan2(float(v["x"]) - p.x, float(v["y"]) - p.y))   # Kage locası köy merkezine bakan tarafta
	Stadium.build(b, 0.0, 0.0, 0.0, Stadium.style_for(String(v["id"])), srng, kdir)
	b.finish()
	# --- ANBU / Kage muhafızları karargâhı
	p = sites["anbu"]
	base = Game.terrain_height(p.x, -p.y)
	b = Builder.new(parent, p.x, p.y, base, "Story_%s_anbu" % v["id"])
	SecretUnits.build_hq(b, String(v["id"]), 0.0, 0.0, 0.0)   # köyün gizli birliği: kendi mimarisinde karargâh + iç mekân
	b.finish()


## Görev masasının yanında Aranıyor panosu
static func _bounty_board(parent: Node3D, v: Dictionary) -> void:
	var c = Vector2(float(v["x"]), float(v["y"]))
	var best = {}
	var bd = float(v.get("r", 250)) * 1.2
	for it in Interact.items:
		if (it["kind"] != "mission_board" and it.get("alias", "") != "mission_board") or it.get("interior", false):
			continue
		var d = Game.to_map(it["pos"]).distance_to(c)
		if d < bd:
			bd = d; best = it
	var at: Vector2
	if best.is_empty():
		at = c + Vector2(12, -20)
	else:
		at = Game.to_map(best["pos"]) + Vector2(16, -13)  # Kage meydanında merdivenin yanı
	var base = Game.terrain_height(at.x, -at.y)
	var b = Builder.new(parent, at.x, at.y, base, "Bounty_%s" % v["id"])
	b.cyl(Vector3(-1.4, 1.4, 0), 0.22, 2.8 + 1.0, Color(0.35, 0.25, 0.15), true, 6)
	b.cyl(Vector3(1.4, 1.4, 0), 0.22, 2.8 + 1.0, Color(0.35, 0.25, 0.15), true, 6)
	b.box(Vector3(0, 2.1, 0), Vector3(3.4, 1.8, 0.2), Color(0.5, 0.38, 0.24), 0.0, true)
	b.roof(Vector3(0, 3.1, 0), Vector3(3.9, 0.6, 0.9), Color(0.3, 0.2, 0.15))
	for i in 4:
		b.box(Vector3(-1.1 + i * 0.75, 2.15, -0.12), Vector3(0.55, 0.75, 0.02), Color(0.92, 0.88, 0.76), 0.0, false)
		b.box(Vector3(-1.1 + i * 0.75, 2.3, -0.135), Vector3(0.3, 0.25, 0.01), Color(0.7, 0.15, 0.12), 0.0, false)
	b.interact(Vector3(0, 0, -1.5), 4, "bounty_board", "[F] Aranıyor Panosu (Bingo Kitabı)")
	b.finish()


## Görev masası etkileşimi ortaya çıkınca (köy akışla yüklenince) yanına Aranıyor panosu kurar
class BoardWatcher extends Node:
	var parent3d: Node3D
	var done := {}
	var t := 0.0

	func _process(dt: float) -> void:
		t -= dt
		if t > 0.0:
			return
		t = 2.0
		for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
			if done.has(vid):
				continue
			var v = Game.village(vid)
			if v.is_empty():
				done[vid] = true
				continue
			var c = Vector2(float(v["x"]), float(v["y"]))
			for it in Interact.items:
				if (it["kind"] == "mission_board" or it.get("alias", "") == "mission_board") and not it.get("interior", false) and Game.to_map(it["pos"]).distance_to(c) < float(v.get("r", 250)) * 1.2:
					BuildVillageStory._bounty_board(parent3d, v)
					done[vid] = true
					break
