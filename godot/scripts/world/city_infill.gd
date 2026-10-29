class_name CityInfill
extends RefCounted
## Köylerin evler arası boş arsaları: iklime göre küçük yaşam köşeleri (sandık/fıçı yığını, el arabası, odun yığını,
## sebze bahçesi + korkuluk, kurutma rafı, depo kulübesi, su kulesi / sarnıç, kapalı tezgâh, antrenman kazıkları,
## yol kenarı sunağı, kardan adam...). CityLandscape.dress sonunda çağrılır; MultiMesh (Ctx.put) ile çizilir.
## Ayrıca her evin kapı önü ve her arsa köylü noktası olarak kaydedilir: köylüler ara sokaklara, avlulara dağılır.

const VL = preload("res://scripts/world/village_life.gd")
const WOOD := Color(0.5, 0.35, 0.22)
const WOOD_D := Color(0.33, 0.23, 0.15)
const WOOD_L := Color(0.68, 0.52, 0.34)
const CLAY := Color(0.76, 0.5, 0.32)
const SAND := Color(0.8, 0.68, 0.5)
const CLOTH := [Color(0.82, 0.3, 0.25), Color(0.25, 0.42, 0.7), Color(0.9, 0.85, 0.7), Color(0.35, 0.55, 0.35), Color(0.6, 0.35, 0.6)]

static var lots_by := {}   # köy -> [dünya noktası] (köylü noktaları)
static var done := {}      # arsa doldurma bitmiş köyler
static var _m := {}

## iklim -> [arsa türü, ağırlık]
const LOTS := {
	"green": [["crates", 3], ["cart", 2], ["woodpile", 2], ["garden", 3], ["shed", 2], ["tower", 1], ["stall", 2], ["training", 2], ["hokora", 1], ["laundry2", 2], ["drying", 1]],
	"mist": [["crates", 3], ["cart", 1], ["drying", 3], ["shed", 2], ["boat", 2], ["stall", 2], ["training", 1], ["hokora", 1], ["woodpile", 1]],
	"rock": [["crates", 3], ["cart", 3], ["shed", 2], ["ore", 3], ["stall", 2], ["training", 2], ["hokora", 1], ["woodpile", 1]],
	"desert": [["pots", 4], ["cart", 2], ["cistern", 2], ["rugs", 3], ["mudshed", 3], ["stall", 2], ["cactus", 2], ["training", 1]],
	"rain": [["crates", 4], ["shed", 3], ["pipes", 3], ["cart", 1], ["stall", 1], ["drying", 1]],
	"snow": [["woodpile", 4], ["crates", 2], ["shed", 3], ["sled", 2], ["snowman", 1], ["drying", 2], ["hokora", 1]],
}


static func _pick(rng: RandomNumberGenerator, lst: Array) -> String:
	var tot = 0
	for e in lst:
		tot += int(e[1])
	var r = rng.randi() % tot
	for e in lst:
		r -= int(e[1])
		if r < 0:
			return e[0]
	return lst[0][0]


# ------------------------------------------------------------------ meshler
static func mesh(name: String) -> Mesh:
	if _m.has(name):
		return _m[name]
	var b = MB.new()
	var leafy := false
	match name:
		"crate":
			b.add_grad("box", Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.9), WOOD_L, WOOD)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(0, 0.45, sx * 0.455), Vector3(0.92, 0.12, 0.02), WOOD_D)
				b.add("box", Vector3(sx * 0.455, 0.45, 0), Vector3(0.02, 0.12, 0.92), WOOD_D)
			b.add("box", Vector3(0, 0.45, 0.457), Vector3(0.1, 0.9, 0.02), WOOD_D, Vector3(0, 0, 45))
		"barrel":
			b.add_grad("cyl", Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.7), WOOD_L, WOOD, Vector3.ZERO, 12)
			for y in [0.18, 0.82]:
				b.add("cyl", Vector3(0, y, 0), Vector3(0.74, 0.07, 0.74), Color(0.3, 0.3, 0.32), Vector3.ZERO, 12)
			b.add("cyl", Vector3(0, 1.0, 0), Vector3(0.6, 0.02, 0.6), WOOD_D, Vector3.ZERO, 12)
		"sack":
			b.add_grad("sphere", Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.55), Color(0.85, 0.78, 0.6), Color(0.62, 0.55, 0.4), Vector3.ZERO, 8)
			b.add("cyl", Vector3(0, 0.62, 0), Vector3(0.16, 0.14, 0.16), Color(0.7, 0.62, 0.45), Vector3.ZERO, 6)
		"cart":   # iki tekerlekli el arabası (ön -z)
			b.add_grad("box", Vector3(0, 0.85, 0), Vector3(1.4, 0.12, 2.0), WOOD_L, WOOD)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 0.68, 1.1, 0), Vector3(0.06, 0.45, 2.0), WOOD)
				b.add("cyl", Vector3(sx * 0.8, 0.55, 0.2), Vector3(1.1, 0.08, 1.1), WOOD_D, Vector3(0, 0, 90), 14)
				b.add("cyl", Vector3(sx * 0.83, 0.55, 0.2), Vector3(0.22, 0.1, 0.22), Color(0.3, 0.3, 0.32), Vector3(0, 0, 90), 8)
				b.add("box", Vector3(sx * 0.45, 0.75, -1.6), Vector3(0.08, 0.08, 1.4), WOOD_D, Vector3(-12, 0, 0))
			b.add("box", Vector3(0, 1.1, 1.0), Vector3(1.4, 0.45, 0.06), WOOD)
			b.add("cyl", Vector3(0, 0.55, 0.2), Vector3(0.08, 1.6, 0.08), WOOD_D, Vector3(0, 0, 90), 6)
		"logs":   # odun yığını + üstte eğik saçak
			for row in 3:
				for i in 5 - row:
					b.add_grad("cyl", Vector3(-0.85 + row * 0.2 + i * 0.4, 0.2 + row * 0.36, 0), Vector3(0.38, 1.6, 0.38), WOOD_L, WOOD, Vector3(90, 0, 0), 8)
					b.add("cyl", Vector3(-0.85 + row * 0.2 + i * 0.4, 0.2 + row * 0.36, 0.81), Vector3(0.3, 0.02, 0.3), Color(0.85, 0.72, 0.5), Vector3(90, 0, 0), 8)
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.25, 0.9, -0.7), Vector3(0.1, 1.8, 0.1), WOOD_D)
				b.add("box", Vector3(sx * 1.25, 1.2, 0.7), Vector3(0.1, 2.4, 0.1), WOOD_D)
			b.add("box", Vector3(0, 2.15, 0), Vector3(2.8, 0.06, 1.9), Color(0.42, 0.3, 0.22), Vector3(-15, 0, 0))
		"stump":  # kesme kütüğü + saplı balta
			b.add_grad("cyl", Vector3(0, 0.3, 0), Vector3(0.75, 0.6, 0.75), WOOD, WOOD_D, Vector3.ZERO, 10)
			b.add("cyl", Vector3(0, 0.61, 0), Vector3(0.68, 0.02, 0.68), Color(0.85, 0.72, 0.5), Vector3.ZERO, 10)
			b.add("cyl", Vector3(0.1, 0.9, 0), Vector3(0.05, 0.75, 0.05), WOOD_L, Vector3(0, 0, 25), 6)
			b.add("box", Vector3(-0.02, 0.62, 0), Vector3(0.22, 0.14, 0.03), Color(0.55, 0.57, 0.6), Vector3(0, 0, 25))
		"garden":  # 4x3 m sebze tarhı: toprak sıraları + filizler + lahanalar
			b.add("box", Vector3(0, 0.08, 0), Vector3(4.0, 0.16, 3.0), Color(0.36, 0.25, 0.16))
			for i in 5:
				var z = -1.2 + i * 0.6
				b.add("box", Vector3(0, 0.2, z), Vector3(3.8, 0.12, 0.28), Color(0.42, 0.3, 0.2))
				for j in 7:
					var x = -1.6 + j * 0.53
					if i % 2 == 0:
						b.add_grad("sphere", Vector3(x, 0.38, z), Vector3(0.36, 0.28, 0.36), Color(0.55, 0.8, 0.4), Color(0.25, 0.5, 0.2), Vector3.ZERO, 6)
					else:
						b.add("cone", Vector3(x, 0.42, z), Vector3(0.16, 0.42, 0.16), Color(0.35, 0.65, 0.3), Vector3.ZERO, 4)
			leafy = true
		"scarecrow":
			b.add("box", Vector3(0, 1.0, 0), Vector3(0.08, 2.0, 0.08), WOOD_D)
			b.add("box", Vector3(0, 1.45, 0), Vector3(1.4, 0.07, 0.07), WOOD_D)
			b.add("box", Vector3(0, 1.3, 0), Vector3(0.6, 0.6, 0.25), Color(0.55, 0.35, 0.3))
			b.add("sphere", Vector3(0, 1.85, 0), Vector3(0.36, 0.36, 0.34), Color(0.9, 0.84, 0.66), Vector3.ZERO, 8)
			b.add("cone", Vector3(0, 2.1, 0), Vector3(0.9, 0.22, 0.9), Color(0.85, 0.72, 0.38), Vector3.ZERO, 10)
		"lowfence":   # 4 m alçak bambu/ahşap çit
			for i in 3:
				b.add("box", Vector3(-2.0 + i * 2.0, 0.4, 0), Vector3(0.08, 0.8, 0.08), WOOD_D)
			for y in [0.3, 0.62]:
				b.add("box", Vector3(0, y, 0), Vector3(4.0, 0.05, 0.05), Color(0.72, 0.66, 0.4))
		"shed":   # 3x3 m depo kulübesi (kapı -z)
			b.add_grad("box", Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 3.0), WOOD_L, WOOD)
			for i in 6:
				b.add("box", Vector3(-1.25 + i * 0.5, 1.2, -1.51), Vector3(0.04, 2.3, 0.02), WOOD_D)
			b.add("box", Vector3(0, 0.95, -1.53), Vector3(1.0, 1.8, 0.04), WOOD_D)
			b.add("box", Vector3(0.35, 0.95, -1.56), Vector3(0.08, 0.08, 0.04), Color(0.7, 0.62, 0.3))
			for sz in [-1.0, 1.0]:
				b.add("box", Vector3(0, 2.7, sz * 0.85), Vector3(3.5, 0.1, 1.9), Color(0.34, 0.27, 0.24), Vector3(sz * 24.0, 0, 0))
			b.add("box", Vector3(0, 3.05, 0), Vector3(3.6, 0.12, 0.14), WOOD_D)
		"mudshed":   # çöl: kubbeli küçük kerpiç depo
			b.add_grad("cyl", Vector3(0, 1.1, 0), Vector3(3.0, 2.2, 3.0), SAND.lightened(0.05), SAND.darkened(0.15), Vector3.ZERO, 14)
			b.add_grad("sphere", Vector3(0, 2.2, 0), Vector3(3.0, 1.6, 3.0), SAND.lightened(0.08), SAND.darkened(0.1), Vector3.ZERO, 14)
			b.add("box", Vector3(0, 0.85, -1.45), Vector3(0.9, 1.6, 0.2), Color(0.3, 0.2, 0.14))
			b.add("box", Vector3(0, 1.75, -1.5), Vector3(1.4, 0.08, 0.5), Color(0.75, 0.3, 0.25))
			b.add("cyl", Vector3(0.9, 2.2, -1.1), Vector3(0.3, 0.3, 0.3), Color(0.2, 0.15, 0.12), Vector3(90, 0, 0), 8)
		"tower":   # ahşap su kulesi (Konoha çatıları gibi)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					b.add("box", Vector3(sx * 0.9, 1.8, sz * 0.9), Vector3(0.16, 3.6, 0.16), WOOD_D)
			b.add("box", Vector3(0, 1.4, 0), Vector3(2.0, 0.08, 0.08), WOOD_D, Vector3(0, 0, 50))
			b.add("box", Vector3(0, 1.4, 0), Vector3(0.08, 0.08, 2.0), WOOD_D, Vector3(50, 0, 0))
			b.add("box", Vector3(0, 3.6, 0), Vector3(2.3, 0.12, 2.3), WOOD)
			b.add_grad("cyl", Vector3(0, 4.6, 0), Vector3(2.0, 1.9, 2.0), Color(0.62, 0.66, 0.7), Color(0.4, 0.44, 0.48), Vector3.ZERO, 14)
			for y in [3.95, 5.3]:
				b.add("cyl", Vector3(0, y, 0), Vector3(2.05, 0.08, 2.05), Color(0.3, 0.3, 0.32), Vector3.ZERO, 14)
			b.add("cone", Vector3(0, 5.85, 0), Vector3(2.2, 0.6, 2.2), Color(0.35, 0.38, 0.42), Vector3.ZERO, 14)
		"cistern":   # çöl: büyük kil sarnıç + kapak
			b.add_grad("sphere", Vector3(0, 1.0, 0), Vector3(2.2, 2.0, 2.2), CLAY, CLAY.darkened(0.3), Vector3.ZERO, 14)
			b.add("cyl", Vector3(0, 2.0, 0), Vector3(0.9, 0.3, 0.9), CLAY.darkened(0.1), Vector3.ZERO, 12)
			b.add("cyl", Vector3(0, 2.17, 0), Vector3(1.0, 0.06, 1.0), WOOD, Vector3.ZERO, 12)
			b.add("box", Vector3(1.2, 0.45, 0), Vector3(0.35, 0.9, 0.35), SAND.darkened(0.1))
		"stall":   # kapalı tezgâh: tezgâh + direkler + kumaş tente + sandıklar
			b.add_grad("box", Vector3(0, 0.5, 0), Vector3(2.6, 1.0, 1.0), WOOD_L, WOOD)
			for sx in [-1.25, 1.25]:
				b.add("box", Vector3(sx, 1.25, 0.45), Vector3(0.1, 2.5, 0.1), WOOD_D)
				b.add("box", Vector3(sx, 1.1, -0.45), Vector3(0.1, 2.2, 0.1), WOOD_D)
			b.add("box", Vector3(0, 2.35, 0), Vector3(2.9, 0.06, 1.5), Color(0.82, 0.3, 0.25), Vector3(14, 0, 0))
			for i in 5:
				b.add("box", Vector3(-1.16 + i * 0.58, 2.36, 0.01), Vector3(0.29, 0.065, 1.5), Color(0.95, 0.92, 0.85), Vector3(14, 0, 0))
			b.add("box", Vector3(0, 1.0, 0), Vector3(2.4, 0.04, 0.9), Color(0.72, 0.68, 0.6))
			for i in 4:
				b.add_grad("sphere", Vector3(-0.9 + i * 0.6, 1.12, 0.05), Vector3(0.4, 0.22, 0.4), [Color(0.9, 0.5, 0.2), Color(0.85, 0.2, 0.2), Color(0.5, 0.75, 0.3), Color(0.95, 0.85, 0.3)][i], Color(0.4, 0.3, 0.2), Vector3.ZERO, 7)
		"posts":   # antrenman kazıkları + hedef tahtası
			for i in 3:
				b.add_grad("cyl", Vector3(-1.4 + i * 1.4, 0.8, 0), Vector3(0.36, 1.6, 0.36), WOOD_L, WOOD, Vector3.ZERO, 10)
				b.add("cyl", Vector3(-1.4 + i * 1.4, 1.1, 0), Vector3(0.4, 0.2, 0.4), Color(0.85, 0.8, 0.65), Vector3.ZERO, 10)
			b.add("box", Vector3(0, 1.2, 1.4), Vector3(0.1, 2.4, 0.1), WOOD_D)
			b.add("cyl", Vector3(0, 1.8, 1.36), Vector3(1.2, 0.1, 1.2), Color(0.9, 0.86, 0.75), Vector3(90, 0, 0), 16)
			b.add("cyl", Vector3(0, 1.8, 1.3), Vector3(0.8, 0.02, 0.8), Color(0.8, 0.2, 0.18), Vector3(90, 0, 0), 16)
			b.add("cyl", Vector3(0, 1.8, 1.28), Vector3(0.36, 0.02, 0.36), Color(0.95, 0.95, 0.9), Vector3(90, 0, 0), 12)
			for k in 3:
				b.add("box", Vector3(-0.2 + k * 0.18, 1.7 + k * 0.08, 1.15), Vector3(0.03, 0.03, 0.35), Color(0.3, 0.3, 0.32), Vector3(0, 0, 0))
		"hokora":   # yol kenarı küçük sunak + tasma + adak
			b.add_grad("box", Vector3(0, 0.3, 0), Vector3(1.0, 0.6, 0.8), Color(0.66, 0.63, 0.58), Color(0.46, 0.44, 0.41))
			b.add("box", Vector3(0, 0.95, 0), Vector3(0.7, 0.7, 0.6), WOOD)
			b.add("box", Vector3(0, 0.95, -0.31), Vector3(0.4, 0.5, 0.02), Color(0.15, 0.1, 0.08))
			for sz in [-1.0, 1.0]:
				b.add("box", Vector3(0, 1.42, sz * 0.25), Vector3(1.0, 0.06, 0.6), Color(0.35, 0.28, 0.25), Vector3(sz * 28.0, 0, 0))
			b.add("box", Vector3(0, 1.28, -0.32), Vector3(0.8, 0.04, 0.04), Color(0.9, 0.85, 0.7))
			for k in 3:
				b.add("box", Vector3(-0.2 + k * 0.2, 1.15, -0.33), Vector3(0.06, 0.2, 0.01), Color(0.98, 0.98, 0.95))
			b.add("cyl", Vector3(0.3, 0.66, -0.45), Vector3(0.16, 0.1, 0.16), Color(0.85, 0.85, 0.82), Vector3.ZERO, 8)
			b.add("sphere", Vector3(-0.28, 0.68, -0.45), Vector3(0.14, 0.14, 0.14), Color(0.9, 0.55, 0.2), Vector3.ZERO, 6)
		"drying":   # kurutma rafı: balık / ot demetleri
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.3, 0.9, 0), Vector3(0.1, 1.8, 0.1), WOOD_D)
			for y in [1.2, 1.7]:
				b.add("box", Vector3(0, y, 0), Vector3(2.7, 0.05, 0.05), WOOD)
				for i in 7:
					b.add_grad("sphere", Vector3(-1.1 + i * 0.36, y - 0.25, 0), Vector3(0.12, 0.42, 0.06), Color(0.75, 0.72, 0.65), Color(0.45, 0.42, 0.38), Vector3.ZERO, 5)
		"rugs":   # çöl: renkli halılar asılı ip
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 1.6, 1.15, 0), Vector3(0.12, 2.3, 0.12), WOOD_D)
			b.add("box", Vector3(0, 2.2, 0), Vector3(3.3, 0.05, 0.05), WOOD)
			for i in 3:
				b.add("box", Vector3(-1.05 + i * 1.05, 1.5, 0), Vector3(0.95, 1.3, 0.03), CLOTH[i])
				b.add("box", Vector3(-1.05 + i * 1.05, 1.5, 0.02), Vector3(0.6, 0.12, 0.01), CLOTH[(i + 2) % 5])
				b.add("box", Vector3(-1.05 + i * 1.05, 1.2, 0.02), Vector3(0.6, 0.12, 0.01), CLOTH[(i + 3) % 5])
		"pots":   # çöl: küp ve testi öbeği
			for k in 5:
				var a = k * 1.3
				var s = 0.6 + (k % 3) * 0.2
				b.add_grad("sphere", Vector3(cos(a) * 0.6, 0.4 * s, sin(a) * 0.6), Vector3(0.7, 0.85, 0.7) * s, CLAY.lightened(0.05 * k), CLAY.darkened(0.3), Vector3.ZERO, 9)
				b.add("cyl", Vector3(cos(a) * 0.6, 0.82 * s, sin(a) * 0.6), Vector3(0.3, 0.14, 0.3) * s, CLAY.darkened(0.15), Vector3.ZERO, 8)
		"cactus":   # saksıda kaktüs + taş kenar
			b.add("cyl", Vector3(0, 0.25, 0), Vector3(1.4, 0.5, 1.4), Color(0.72, 0.6, 0.45), Vector3.ZERO, 10)
			b.add_grad("cyl", Vector3(0, 1.3, 0), Vector3(0.45, 2.0, 0.45), Color(0.4, 0.6, 0.32), Color(0.2, 0.38, 0.18), Vector3.ZERO, 8)
			b.add_grad("cyl", Vector3(0.38, 1.4, 0), Vector3(0.28, 0.7, 0.28), Color(0.4, 0.6, 0.32), Color(0.2, 0.38, 0.18), Vector3(0, 0, -70), 7)
			b.add_grad("cyl", Vector3(0.55, 1.75, 0), Vector3(0.26, 0.6, 0.26), Color(0.4, 0.6, 0.32), Color(0.2, 0.38, 0.18), Vector3.ZERO, 7)
			leafy = true
		"boat":   # ters çevrilmiş küçük kayık + kürek
			b.add_grad("sphere", Vector3(0, 0.35, 0), Vector3(1.3, 0.7, 3.6), WOOD_L, WOOD_D, Vector3(180, 0, 0), 12)
			b.add("box", Vector3(0.9, 0.15, 0.3), Vector3(0.1, 0.06, 2.2), WOOD, Vector3(0, 15, 0))
			b.add("box", Vector3(0.95, 0.15, 1.35), Vector3(0.26, 0.04, 0.5), WOOD, Vector3(0, 15, 0))
		"ore":   # kaya köyü: cevher / taş blok yığını + kazma
			for k in 6:
				var a = k * 1.1
				b.add_grad("box", Vector3(cos(a) * 0.7, 0.3 + (k % 2) * 0.35, sin(a) * 0.5), Vector3(0.8, 0.6, 0.6), Color(0.62, 0.55, 0.48), Color(0.4, 0.35, 0.3), Vector3(0, k * 25, 0))
			b.add("cyl", Vector3(0.9, 0.6, -0.6), Vector3(0.05, 1.1, 0.05), WOOD_L, Vector3(0, 0, 40), 6)
			b.add("box", Vector3(0.55, 1.0, -0.6), Vector3(0.7, 0.07, 0.07), Color(0.5, 0.52, 0.55), Vector3(0, 0, 40))
		"pipes":   # yağmur köyü: boru yığını + varil
			for i in 4:
				b.add_grad("cyl", Vector3(-0.6 + i * 0.4, 0.2 + (i % 2) * 0.35, 0), Vector3(0.36, 2.6, 0.36), Color(0.55, 0.57, 0.6), Color(0.32, 0.34, 0.36), Vector3(90, 0, 0), 10)
			b.add_grad("cyl", Vector3(1.2, 0.5, 0.6), Vector3(0.7, 1.0, 0.7), Color(0.45, 0.5, 0.55), Color(0.28, 0.3, 0.33), Vector3.ZERO, 10)
		"sled":   # kızak + odun
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx * 0.45, 0.1, 0), Vector3(0.08, 0.08, 2.0), WOOD_D)
				b.add("box", Vector3(sx * 0.45, 0.2, -1.05), Vector3(0.08, 0.3, 0.1), WOOD_D, Vector3(-40, 0, 0))
			b.add("box", Vector3(0, 0.35, 0), Vector3(1.0, 0.08, 1.8), WOOD_L)
			for i in 3:
				b.add("cyl", Vector3(-0.3 + i * 0.3, 0.55, 0), Vector3(0.26, 1.5, 0.26), WOOD, Vector3(90, 0, 0), 7)
		"snowman":
			b.add_grad("sphere", Vector3(0, 0.55, 0), Vector3(1.1, 1.0, 1.1), Color(0.98, 0.98, 1.0), Color(0.75, 0.8, 0.88), Vector3.ZERO, 10)
			b.add_grad("sphere", Vector3(0, 1.35, 0), Vector3(0.8, 0.75, 0.8), Color(0.98, 0.98, 1.0), Color(0.75, 0.8, 0.88), Vector3.ZERO, 10)
			b.add_grad("sphere", Vector3(0, 1.95, 0), Vector3(0.55, 0.52, 0.55), Color(0.98, 0.98, 1.0), Color(0.75, 0.8, 0.88), Vector3.ZERO, 10)
			b.add("cone", Vector3(0, 1.95, -0.35), Vector3(0.1, 0.3, 0.1), Color(0.95, 0.5, 0.15), Vector3(-90, 0, 0), 6)
			b.add("box", Vector3(0, 1.62, 0), Vector3(0.7, 0.12, 0.7), Color(0.8, 0.2, 0.2))
			for sx in [-1.0, 1.0]:
				b.add("sphere", Vector3(sx * 0.12, 2.02, -0.25), Vector3(0.06, 0.06, 0.06), Color(0.08, 0.08, 0.1), Vector3.ZERO, 5)
			b.add("cyl", Vector3(0, 2.3, 0), Vector3(0.36, 0.3, 0.36), Color(0.15, 0.15, 0.18), Vector3.ZERO, 10)
	var m: Mesh = b.build(Props.foliage() if leafy else Props.toon())
	_m[name] = m
	return m


# ------------------------------------------------------------------ yerleştirme
## Bir arsa öbeği kur (x, n merkez; yaw derece). Dönüş: köylünün durabileceği ön nokta (yerel)
static func _lot(c, kind: String, x: float, n: float, yaw: float) -> Vector2:
	var rng: RandomNumberGenerator = c.rng
	var at = func(lx: float, ln: float) -> Vector2:
		var o = Builder.rot(lx, ln, yaw)
		return Vector2(x + o.x, n + o.y)
	var put = func(m: String, lx: float, ln: float, dyaw := 0.0, s := 1.0, dist := 260.0) -> void:
		var q: Vector2 = at.call(lx, ln)
		c.put(mesh(m), q.x, q.y, yaw + dyaw, Vector3.ONE * s, dist)
	match kind:
		"crates":
			for k in rng.randi_range(2, 4):
				var q = Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-0.8, 0.8))
				put.call("crate", q.x, q.y, rng.randf_range(-20, 20), rng.randf_range(0.85, 1.1))
			put.call("crate", 0.0, 0.0, 15.0, 0.8)
			for k in rng.randi_range(1, 3):
				put.call("barrel", 1.8 + k * 0.75, rng.randf_range(-0.5, 0.5), rng.randf() * 360.0)
			put.call("sack", -1.9, 0.6, rng.randf() * 360.0)
			var q2: Vector2 = at.call(0.3, 0.0)
			c.solid_box(q2.x, q2.y, Vector3(3.2, 1.0, 1.8), yaw)
		"cart":
			put.call("cart", 0.0, 0.0)
			for k in 2:
				put.call("sack", 0.3 * k - 0.15, 0.3 * k, rng.randf() * 360.0, 0.9)
			put.call("barrel", 1.8, 1.0, rng.randf() * 360.0)
			var q3: Vector2 = at.call(0.0, 0.0)
			c.solid_box(q3.x, q3.y, Vector3(1.8, 1.4, 2.4), yaw)
		"woodpile":
			put.call("logs", 0.0, 0.8)
			put.call("stump", 1.0, -1.2, rng.randf() * 360.0)
			var q4: Vector2 = at.call(0.0, 0.8)
			c.solid_box(q4.x, q4.y, Vector3(2.6, 1.6, 1.8), yaw)
		"garden":
			put.call("garden", 0.0, 0.0, 0.0, 1.0, 220.0)
			for sz in [-1.0, 1.0]:
				put.call("lowfence", 0.0, sz * 1.8)
			put.call("lowfence", 2.3, 0.0, 90.0, 0.85)
			if rng.randf() < 0.6:
				put.call("scarecrow", 0.6, 0.3, rng.randf_range(-30, 30))
			return at.call(-2.8, 0.0)
		"shed":
			put.call("shed", 0.0, 0.0, 0.0, 1.0, 420.0)
			var q5: Vector2 = at.call(0.0, 0.0)
			c.solid_box(q5.x, q5.y, Vector3(3.1, 2.6, 3.1), yaw)
			put.call("barrel", 2.1, -0.6, rng.randf() * 360.0)
			return at.call(0.0, -2.8)
		"mudshed":
			put.call("mudshed", 0.0, 0.0, 0.0, 1.0, 420.0)
			var q6: Vector2 = at.call(0.0, 0.0)
			c.solid_cyl(q6.x, q6.y, 1.6, 3.0)
			put.call("pots", 2.4, 0.5, rng.randf() * 360.0, 0.8)
			return at.call(0.0, -2.8)
		"tower":
			put.call("tower", 0.0, 0.0, 0.0, 1.0, 520.0)
			var q7: Vector2 = at.call(0.0, 0.0)
			c.solid_box(q7.x, q7.y, Vector3(2.1, 3.0, 2.1), yaw)
			put.call("crate", 1.8, -1.4, 30.0)
		"cistern":
			put.call("cistern", 0.0, 0.0, 0.0, 1.0, 420.0)
			var q8: Vector2 = at.call(0.0, 0.0)
			c.solid_cyl(q8.x, q8.y, 1.1, 2.0)
			put.call("pots", -1.9, 0.6, rng.randf() * 360.0, 0.7)
		"stall":
			put.call("stall", 0.0, 0.0, 0.0, 1.0, 320.0)
			put.call("crate", -1.9, 0.6, 10.0, 0.8)
			put.call("barrel", 1.9, 0.5, 0.0, 0.9)
			var q9: Vector2 = at.call(0.0, 0.0)
			c.solid_box(q9.x, q9.y, Vector3(2.7, 1.1, 1.1), yaw)
			return at.call(0.0, -1.6)
		"training":
			put.call("posts", 0.0, 0.0, 0.0, 1.0, 260.0)
			return at.call(0.0, -1.8)
		"hokora":
			put.call("hokora", 0.0, 0.0)
			var q10: Vector2 = at.call(0.0, 0.0)
			c.solid_box(q10.x, q10.y, Vector3(1.0, 1.4, 0.8), yaw)
			return at.call(0.0, -1.6)
		"laundry2":
			c.put(CityLandscape.mesh("laundry"), at.call(0.0, 0.0).x, at.call(0.0, 0.0).y, yaw, Vector3.ONE, 220.0)
			c.put(CityLandscape.mesh("laundry"), at.call(0.0, 1.4).x, at.call(0.0, 1.4).y, yaw, Vector3.ONE, 220.0)
			put.call("barrel", 2.2, 0.6, 0.0, 0.8)
		"drying":
			put.call("drying", 0.0, 0.0)
			put.call("barrel", 1.8, 0.8, 0.0, 0.8)
		"rugs":
			put.call("rugs", 0.0, 0.0)
			put.call("pots", 2.4, -0.4, rng.randf() * 360.0, 0.8)
		"pots":
			put.call("pots", 0.0, 0.0, rng.randf() * 360.0)
			put.call("pots", 1.6, 0.8, rng.randf() * 360.0, 0.75)
		"cactus":
			put.call("cactus", 0.0, 0.0, rng.randf() * 360.0, rng.randf_range(0.8, 1.1))
			put.call("cactus", 1.8, 0.6, rng.randf() * 360.0, rng.randf_range(0.6, 0.85))
			var q11: Vector2 = at.call(0.0, 0.0)
			c.solid_cyl(q11.x, q11.y, 0.7, 2.0)
		"boat":
			put.call("boat", 0.0, 0.0, 0.0, 1.0, 260.0)
			put.call("barrel", 1.6, -1.4, 0.0, 0.8)
		"ore":
			put.call("ore", 0.0, 0.0, rng.randf() * 360.0)
			put.call("cart", 2.4, 0.4, 90.0)
			var q12: Vector2 = at.call(0.8, 0.0)
			c.solid_box(q12.x, q12.y, Vector3(4.0, 1.2, 2.0), yaw)
		"pipes":
			put.call("pipes", 0.0, 0.0)
			put.call("crate", -1.8, 0.4, 20.0)
			var q13: Vector2 = at.call(0.0, 0.0)
			c.solid_box(q13.x, q13.y, Vector3(3.2, 1.0, 2.6), yaw)
		"sled":
			put.call("sled", 0.0, 0.0)
			put.call("logs", 0.0, 2.2, 0.0, 0.8)
		"snowman":
			put.call("snowman", 0.0, 0.0, rng.randf_range(-40, 40))
	return at.call(0.0, -2.4)


## Köyün boş arsalarını doldur + kapı önleri/arsalar köylü noktası
static func fill(c, rad: float) -> void:
	var b: Builder = c.b
	var vid: String = c.vid
	var lots: Array = []
	lots_by[vid] = lots
	# kapı önleri (Konoha kendi kurulumunda kaydeder)
	if vid != "konoha":
		if not VL.doors.has(vid):
			VL.doors[vid] = []
		for h in b.houses:
			var hd = float(h[3]) * 0.5
			var o = Builder.rot(0.0, -hd - 2.0, float(h[4]))
			var q = Vector2(float(h[0]) + o.x, float(h[1]) + o.y)
			VL.doors[vid].append(b.w(Vector3(q.x, c.ground(q.x, q.y), q.y)))
	# ev ızgarası (24 m): arsa yalnız bir evin yakınına konur (öbekler boş meydanlara zincirleme yayılmasın)
	var hg := {}
	for h in b.houses:
		var k = Vector2i(floori(float(h[0]) / 24.0), floori(float(h[1]) / 24.0))
		if not hg.has(k):
			hg[k] = []
		hg[k].append(Vector2(float(h[0]), float(h[1])))
	var tbl: Array = LOTS.get(c.climate, LOTS["green"])
	var step = 13.0 if rad < 900.0 else 15.0
	var rng: RandomNumberGenerator = c.rng
	var placed = 0
	var x = -rad
	while x <= rad:
		var n = -rad
		while n <= rad:
			var px = x + rng.randf_range(-3.0, 3.0)
			var pn = n + rng.randf_range(-3.0, 3.0)
			n += step
			if Vector2(px, pn).length() > rad * 0.93 or rng.randf() < 0.3:
				continue
			# köyün içinde mi (22 m içinde ev var) ve arsa boş mu
			var near_h = Vector2.INF
			var kc = Vector2i(floori(px / 24.0), floori(pn / 24.0))
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					for hp in hg.get(kc + Vector2i(dx, dz), []):
						if hp.distance_to(Vector2(px, pn)) < near_h.distance_to(Vector2(px, pn)):
							near_h = hp
			if near_h == Vector2.INF or near_h.distance_to(Vector2(px, pn)) > 22.0:
				continue
			var wp: Vector2 = c.wxz(px, pn)
			if not c.open(px, pn, 3.2, 6.5):
				continue
			# yol yakınsa yola dön; değilse sırtını en yakın eve ver
			var rn: Array = c.road_near(wp)
			var dl: Vector2 = (c.loc(rn[1]) - Vector2(px, pn)) if rn[0] < 30.0 else (Vector2(px, pn) - near_h)
			var yaw = rad_to_deg(atan2(-dl.x, -dl.y))
			var kind = _pick(rng, tbl)
			var front: Vector2 = _lot(c, kind, px, pn, yaw)
			lots.append(b.w(Vector3(front.x, c.ground(front.x, front.y), front.y)))
			placed += 1
			if c.busy():
				await c.rest()
				if c.dead:
					return
		x += step
	done[vid] = true
	print("Arsa %s: %d öbek, %d kapı" % [vid, placed, VL.doors.get(vid, []).size()])
