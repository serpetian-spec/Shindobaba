class_name SecretUnits
extends RefCounted
## Köylerin gizli birlikleri: ad (Japonca), karargâh mimarisi, iç mekân ve üniforma.
## Konoha: Anbu (Ansatsu Senjutsu Tokushu Butai). Kiri: Oinin Butai (avcı ninjalar, animede adı geçer).
## Suna, Kumo, Iwa, Ame: animede ayrı adı yok; köyün doğasına göre Japonca ad konuldu.

const UNITS := {
	"konoha": {"name": "Anbu", "kanji": "暗部", "full": "Ansatsu Senjutsu Tokushu Butai", "mask": ["anbu_kedi", "anbu_kurt", "anbu_kus", "anbu_ayi"],
		"wall": Color(0.24, 0.24, 0.27), "roof": Color(0.08, 0.08, 0.1), "acc": Color(0.75, 0.1, 0.12), "vest": Color(0.78, 0.78, 0.8), "cloth": Color(0.1, 0.1, 0.13)},
	"kiri": {"name": "Oinin Butai", "kanji": "追忍", "full": "Kirigakure Oinin Butai", "mask": ["anbu_kus", "anbu_kurt"],
		"wall": Color(0.36, 0.42, 0.46), "roof": Color(0.16, 0.24, 0.34), "acc": Color(0.3, 0.55, 0.75), "vest": Color(0.62, 0.7, 0.76), "cloth": Color(0.16, 0.24, 0.34)},
	"suna": {"name": "Sajin Butai", "kanji": "砂塵", "full": "Sunagakure Sajin Butai (Kum Fırtınası Birliği)", "mask": ["anbu_kedi", "anbu_kus"],
		"wall": Color(0.62, 0.5, 0.34), "roof": Color(0.4, 0.3, 0.2), "acc": Color(0.55, 0.3, 0.18), "vest": Color(0.82, 0.72, 0.52), "cloth": Color(0.36, 0.28, 0.2)},
	"kumo": {"name": "Raiun Butai", "kanji": "雷雲", "full": "Kumogakure Raiun Butai (Fırtına Bulutu Birliği)", "mask": ["anbu_kurt", "anbu_ayi"],
		"wall": Color(0.82, 0.83, 0.8), "roof": Color(0.2, 0.32, 0.55), "acc": Color(0.92, 0.75, 0.15), "vest": Color(0.9, 0.9, 0.86), "cloth": Color(0.18, 0.2, 0.26)},
	"iwa": {"name": "Ganpeki Butai", "kanji": "岩壁", "full": "Iwagakure Ganpeki Butai (Kaya Duvarı Birliği)", "mask": ["anbu_ayi", "anbu_kurt"],
		"wall": Color(0.46, 0.4, 0.34), "roof": Color(0.42, 0.18, 0.14), "acc": Color(0.6, 0.22, 0.15), "vest": Color(0.62, 0.2, 0.15), "cloth": Color(0.26, 0.22, 0.2)},
	"ame": {"name": "Kirisame Butai", "kanji": "霧雨", "full": "Amegakure Kirisame Butai (Çisenti Birliği)", "mask": ["anbu_kus"],
		"wall": Color(0.28, 0.3, 0.33), "roof": Color(0.18, 0.2, 0.22), "acc": Color(0.45, 0.4, 0.62), "vest": Color(0.4, 0.42, 0.48), "cloth": Color(0.2, 0.2, 0.24)},
}


static func of(vid: String) -> Dictionary:
	return UNITS.get(vid, UNITS["konoha"])


## Üniforma: koyu giysi + köy renginde zırh yelek + köyün maskesi
static func look(vid: String, i := 0) -> Dictionary:
	var u = of(vid)
	var L = Outfits.roll("anbu", vid)
	L["top"] = u["cloth"]; L["top2"] = u["cloth"]; L["pants"] = u["cloth"]
	L["vest"] = u["vest"]
	L["face_style"] = u["mask"][i % u["mask"].size()]
	return L


## Karargâh: köy mimarisinde iki katlı ana bina + avlu duvarı + kapı direkleri + kanji tabela + meşaleler + antrenman avlusu.
## (x, n): yerel merkez, yaw: ön cephe yönü. Kapı etkileşimi iç mekâna girer (oda "secret_hq").
static func build_hq(b: Builder, vid: String, x: float, n: float, yaw: float) -> void:
	var u = of(vid)
	var wall: Color = u["wall"]; var roof: Color = u["roof"]; var acc: Color = u["acc"]
	var g = b._ground_off(x, n, 18.0)
	var yo = b.yoff
	b.yoff = g.y
	var R = func(lx: float, ln: float) -> Vector2:
		var o = Builder.rot(lx, ln, yaw)
		return Vector2(x + o.x, n + o.y)
	# temel kaide (eğimde boşluk kalmasın)
	b.box(Vector3(x, (g.x - g.y) * 0.5 - 0.4, n), Vector3(34, g.y - g.x + 1.2, 28), wall.darkened(0.25), yaw)
	# avlu duvarı (önde kapı boşluğu)
	for e in [[0.0, 13.5, 34.0, 0.8], [-16.8, 0.0, 0.8, 27.0], [16.8, 0.0, 0.8, 27.0], [-11.0, -13.5, 12.0, 0.8], [11.0, -13.5, 12.0, 0.8]]:
		var q: Vector2 = R.call(e[0], e[1])
		b.box(Vector3(q.x, 2.0, q.y), Vector3(e[2], 4.0, e[3]), wall.darkened(0.12), yaw)
		b.box(Vector3(q.x, 4.15, q.y), Vector3(e[2] + 0.4, 0.3, e[3] + 0.6), roof, yaw, false)
	# ana bina: iki kat, koyu çatı
	var hq: Vector2 = R.call(0.0, 5.0)
	b.box(Vector3(hq.x, 3.0, hq.y), Vector3(20, 6, 12), wall, yaw)
	b.box(Vector3(hq.x, 6.3, hq.y), Vector3(22, 0.6, 14), roof, yaw, false)
	b.box(Vector3(hq.x, 8.6, hq.y), Vector3(15, 4.2, 9), wall.lightened(0.05), yaw)
	b.roof(Vector3(hq.x, 10.7, hq.y), Vector3(18, 3.4, 12), roof, yaw)
	# dar yarık pencereler
	for k in 6:
		var w: Vector2 = R.call(-7.5 + k * 3.0, 5.0 - 6.05)
		b.box(Vector3(w.x, 3.6, w.y), Vector3(0.9, 1.6, 0.2), Color(0.05, 0.05, 0.06), yaw, false)
	# kapı + kanji levha + maske arması
	var dq: Vector2 = R.call(0.0, 5.0 - 6.1)
	b.box(Vector3(dq.x, 1.6, dq.y), Vector3(2.6, 3.2, 0.3), Color(0.12, 0.1, 0.1), yaw, false)
	var sq: Vector2 = R.call(0.0, 5.0 - 6.2)
	b.box(Vector3(sq.x, 4.6, sq.y), Vector3(3.6, 1.2, 0.15), Color(0.92, 0.9, 0.85), yaw, false)
	b.kanji(Vector3(sq.x, 4.6, sq.y) + Vector3(0, 0, 0), String(u["kanji"]), 0.9, Color(0.1, 0.1, 0.12), yaw)
	var mq: Vector2 = R.call(0.0, 5.0 - 4.55)
	b.disc(Vector3(mq.x, 8.8, mq.y), 2.2, 0.2, Color(0.95, 0.95, 0.93), yaw, 16)
	# kapı direkleri + meşaleler (gece yanar)
	for sx in [-1.0, 1.0]:
		var pq: Vector2 = R.call(sx * 4.5, -13.5)
		b.box(Vector3(pq.x, 3.0, pq.y), Vector3(1.4, 6.0, 1.4), wall.darkened(0.2), yaw)
		b.box(Vector3(pq.x, 6.2, pq.y), Vector3(2.0, 0.4, 2.0), roof, yaw, false)
		var tq: Vector2 = R.call(sx * 3.4, -14.6)
		b.cyl(Vector3(tq.x, 1.6, tq.y), 0.15, 3.2, Color(0.3, 0.2, 0.12), false, 6)
		b.box(Vector3(tq.x, 3.4, tq.y), Vector3(0.5, 0.4, 0.5), Color(1.0, 0.85, 0.5), 0, false)   # ateş: toon gece parlaması
		Lights.add(b.w(Vector3(tq.x, 3.4, tq.y)))
	# avlu: antrenman kütükleri + hedef tahtaları
	for k in 4:
		var kq: Vector2 = R.call(-12.0 + k * 2.4, -6.0)
		b.cyl(Vector3(kq.x, 0.9, kq.y), 0.55, 1.8, Color(0.4, 0.28, 0.18), true, 8)
	for k in 2:
		var hq2: Vector2 = R.call(10.0 + k * 3.0, -6.0)
		b.disc(Vector3(hq2.x, 1.6, hq2.y), 1.5, 0.2, Color(0.9, 0.88, 0.84), yaw, 14)
		b.disc(Vector3(hq2.x, 1.6, hq2.y), 0.6, 0.25, acc, yaw, 12)
	b.yoff = yo
	var door: Vector2 = R.call(0.0, 5.0 - 7.5)
	var dy = b._ground_off(door.x, door.y, 1.0).y
	b.interact(Vector3(door.x, dy, door.y), 3.0, "enter", "[F] Gir: %s Karargâhı" % u["name"], {"room": "secret_hq", "vid": vid, "alias": "anbu", "out": b.w(Vector3(door.x, dy, door.y))})
	b.add_solid(b.w(Vector3(x, 0, n)), 17.5, 14.5, deg_to_rad(-yaw))
