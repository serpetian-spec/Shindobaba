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


## Köy dışında yolları/kapıları kesmeyen, düz bir yer seç
static func _site(v: Dictionary) -> Vector2:
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r = float(v.get("r", 250))
	var gates: Array = v.get("gates", [])
	var best = c + Vector2(r + 80, 0)
	var best_score = -1e9
	for k in 16:
		var a = k * 22.5
		var gate_d = 180.0
		for g in gates:
			gate_d = minf(gate_d, absf(fmod(a - float(g) + 540.0, 360.0) - 180.0))
		var rad = deg_to_rad(a)
		var p = c + Vector2(sin(rad), cos(rad)) * (r + 80.0)
		var h0 = Game.terrain_height(p.x, -p.y)
		if h0 < 1.0:
			continue
		var var_h = 0.0
		for o in [Vector2(45, 0), Vector2(-45, 0), Vector2(0, 35), Vector2(0, -35)]:
			var_h += absf(Game.terrain_height(p.x + o.x, -(p.y + o.y)) - h0)
		var score = minf(gate_d, 60.0) - var_h * 2.0
		if score > best_score:
			best_score = score
			best = p
	return best


static func _compound(parent: Node3D, v: Dictionary, sty: Dictionary) -> void:
	var p = _site(v)
	var base = Game.terrain_height(p.x, -p.y)
	var b = Builder.new(parent, p.x, p.y, base, "Story_%s" % v["id"])
	var g = func(x: float, n: float) -> float:
		return Game.terrain_height(p.x + x, -(p.y + n)) - base
	var wall: Color = sty["wall"]; var roof: Color = sty["roof"]; var acc: Color = sty["accent"]
	var vn: String = v["name"]
	# --- Akademi binası + avlu kuklaları
	var ay = g.call(0, 0)
	b.box(Vector3(0, ay + 1.0, 0), Vector3(30, 2.0 + 4.0, 15), wall.darkened(0.25))  # temel
	b.box(Vector3(0, ay + 6.5, 0), Vector3(28, 9, 13), wall)
	b.roof(Vector3(0, ay + 11.0, 0), Vector3(31, 4.5, 16), roof)
	b.box(Vector3(0, ay + 3.5, -6.6), Vector3(3.2, 5.0, 0.4), Color(0.3, 0.22, 0.15), 0.0, false)
	b.disc(Vector3(0, ay + 9.0, -6.7), 3.2, 0.3, acc)
	for i in 6:
		b.box(Vector3(-11 + i * 4.4, ay + 7.5, -6.6), Vector3(2.0, 1.6, 0.3), Color(0.55, 0.75, 0.9), 0.0, false)
	b.interact(Vector3(0, ay, -9), 8, "academy", "[F] Akademi hocasıyla konuş (%s Akademisi)" % vn)
	for i in 4:
		Spawner.dummy(b.w(Vector3(-15 + i * 10, g.call(-15 + i * 10, -24), -24)))
	# --- antrenman alanı
	var tx = 46.0
	var ty = g.call(tx, -6)
	for i in 10:
		var a = TAU * i / 10.0
		b.cyl(Vector3(tx + cos(a) * 13, ty + 1.0, -6 + sin(a) * 13), 0.5, 2.0 + 4.0, Color(0.45, 0.33, 0.2), true, 6)
	for i in 3:
		Spawner.dummy(b.w(Vector3(tx - 5 + i * 5, g.call(tx - 5 + i * 5, -6), -6)))
	b.interact(Vector3(tx, ty, -18), 6, "training", "[F] Antrenman yap (chakra kontrolü)")
	# --- gözetleme kulesi (duvar koşusuyla tırmanılır, 40 m)
	var lx = -48.0
	var ly = g.call(lx, 0)
	b.cyl(Vector3(lx, ly + 19.0, 0), 9.0, 42.0, wall.darkened(0.15), true, 14)
	b.cyl(Vector3(lx, ly + 40.6, 0), 14.0, 1.2, roof, true, 16)
	for k in 8:
		var a = TAU * k / 8.0
		b.box(Vector3(lx + cos(a) * 6.6, ly + 41.8, sin(a) * 6.6), Vector3(1.2, 1.2, 1.2), roof.darkened(0.2), rad_to_deg(a), true)
	b.interact(Vector3(lx, ly + 41.3, 0), 8, "lookout", "[F] Köyü seyret (kayıt)")
	# --- hastane
	var hy = g.call(0, 34)
	b.box(Vector3(0, hy + 0.5, 34), Vector3(18, 3.0, 12), wall.darkened(0.25))
	b.box(Vector3(0, hy + 4.5, 34), Vector3(17, 7, 11), Color(0.92, 0.92, 0.9))
	b.roof(Vector3(0, hy + 8.0, 34), Vector3(19, 3.0, 13), Color(0.75, 0.2, 0.2))
	b.disc(Vector3(0, hy + 5.5, 28.4), 2.4, 0.3, Color(0.85, 0.15, 0.15))
	b.interact(Vector3(0, hy, 26), 6, "hospital", "[F] Hastane: iyileş (ücretsiz)")
	# --- ANBU / Kage muhafızları karargâhı
	var uy = g.call(44, 34)
	b.box(Vector3(44, uy + 0.5, 34), Vector3(12, 3.0, 12), Color(0.2, 0.2, 0.22))
	b.box(Vector3(44, uy + 4.0, 34), Vector3(11, 6, 11), Color(0.25, 0.25, 0.28))
	b.roof(Vector3(44, uy + 7.0, 34), Vector3(12, 2.4, 12), Color(0.12, 0.12, 0.14))
	b.interact(Vector3(44, uy, 27), 5, "anbu", "[F] ANBU Karargâhı (%s)" % vn)
	# fenerler ve ağaçlar
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(v["id"])
	for i in 6:
		b.lantern(-20 + i * 12, -12)
	b.finish()


## Görev masasının yanında Aranıyor panosu
static func _bounty_board(parent: Node3D, v: Dictionary) -> void:
	var c = Vector2(float(v["x"]), float(v["y"]))
	var best = {}
	var bd = float(v.get("r", 250)) * 1.2
	for it in Interact.items:
		if it["kind"] != "mission_board":
			continue
		var d = Game.to_map(it["pos"]).distance_to(c)
		if d < bd:
			bd = d; best = it
	var at: Vector2
	if best.is_empty():
		at = c + Vector2(12, -20)
	else:
		at = Game.to_map(best["pos"]) + Vector2(7, -3)
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
				if it["kind"] == "mission_board" and Game.to_map(it["pos"]).distance_to(c) < float(v.get("r", 250)) * 1.2:
					BuildVillageStory._bounty_board(parent3d, v)
					done[vid] = true
					break
