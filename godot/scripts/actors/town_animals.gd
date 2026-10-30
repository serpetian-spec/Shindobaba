class_name TownAnimals
extends RefCounted
## Köy hayvanları (sokak kedisi, köpek, yük öküzü): SummonModels._quad gövde yapıcısıyla detaylı model
## (göğüs-bel-kalça gövde, kulak, göz + bebek, kaş, burun, diş, eklemli bacak, kuyruk) + türe özel ayrıntılar.
## Dönüş: {root, legs: [pivot], tail} — yürürken bacak / kuyruk salınımı çağıran tarafta.

const CAT_COATS := [   # [ana renk, karın, desen rengi, desen: 0 düz, 1 tekir çizgi, 2 benekli (calico), 3 smokin]
	[Color(0.95, 0.6, 0.25), Color(0.98, 0.9, 0.78), Color(0.75, 0.4, 0.15), 1],
	[Color(0.16, 0.16, 0.18), Color(0.2, 0.2, 0.22), Color(0.1, 0.1, 0.12), 0],
	[Color(0.95, 0.94, 0.92), Color(0.98, 0.97, 0.95), Color(0.9, 0.55, 0.25), 2],
	[Color(0.55, 0.52, 0.5), Color(0.82, 0.8, 0.76), Color(0.32, 0.3, 0.3), 1],
	[Color(0.15, 0.15, 0.17), Color(0.96, 0.96, 0.94), Color(0.96, 0.96, 0.94), 3],
]
const DOG_COATS := [   # shiba, akita beyazı, siyah-kahve, gri kurt köpeği
	[Color(0.85, 0.52, 0.25), Color(0.97, 0.92, 0.82)],
	[Color(0.95, 0.94, 0.9), Color(0.98, 0.97, 0.95)],
	[Color(0.18, 0.15, 0.13), Color(0.75, 0.52, 0.3)],
	[Color(0.55, 0.55, 0.57), Color(0.85, 0.85, 0.86)],
]


static func cat(rng: RandomNumberGenerator, ribbon := false) -> Dictionary:
	var out = {"root": Node3D.new(), "legs": [], "tail": null, "head": null, "mouth": Vector3.ZERO, "wings": [], "segments": [], "anim": "walk"}
	var coat: Array = CAT_COATS[rng.randi() % CAT_COATS.size()]
	var c: Color = coat[0]
	var h = 0.48
	var b: MB = SummonModels._quad(out, h, c, {"len": 1.35, "leg": 0.42, "snout": 0.12, "ear": 0.24,
		"eye": [Color(0.95, 0.8, 0.25), Color(0.35, 0.75, 0.4), Color(0.4, 0.65, 0.95)][rng.randi() % 3], "tail": "thin", "belly": coat[1], "mark": coat[2]})
	var by = h * 0.42 + h * 0.12
	var L = h * 1.35
	match int(coat[3]):
		1:   # tekir: sırtta enine koyu çizgiler + alında M
			for k in 6:
				b.add("box", Vector3(0, by + h * 0.2, -L * 0.3 + k * L * 0.12), Vector3(h * 0.36, h * 0.03, h * 0.05), coat[2], Vector3(0, 0, 0))
		2:   # calico: turuncu ve koyu lekeler
			for k in 4:
				var lc: Color = coat[2] if k % 2 == 0 else Color(0.2, 0.18, 0.18)
				b.add("sphere", Vector3(rng.randf_range(-0.08, 0.08), by + h * 0.12, rng.randf_range(-L * 0.3, L * 0.35)), Vector3(h * 0.32, h * 0.18, h * 0.34), lc, Vector3.ZERO, 8)
		3:   # smokin: beyaz göğüs ve patiler
			b.add("sphere", Vector3(0, by - h * 0.05, -L * 0.38), Vector3(h * 0.34, h * 0.32, h * 0.3), coat[1], Vector3.ZERO, 8)
	# bıyıklar
	var hp = Vector3(0, by + h * 0.48, -L * 0.62)
	for sx in [-1.0, 1.0]:
		for k in 3:
			b.add("box", hp + Vector3(sx * h * 0.12, -h * 0.05 + k * h * 0.02, -h * 0.13), Vector3(h * 0.22, h * 0.006, h * 0.006), Color(0.95, 0.95, 0.92), Vector3(0, sx * 10, sx * (k - 1) * 8))
	if ribbon:   # kayıp kedi görevi: boynunda kırmızı kurdele
		b.add("torus", Vector3(0, by + h * 0.28, -L * 0.48), Vector3(h * 0.42, h * 0.42, h * 0.42), Color(0.8, 0.15, 0.2), Vector3(70, 0, 0), 12)
		b.add("sphere", Vector3(0, by + h * 0.22, -L * 0.58), Vector3(h * 0.12, h * 0.1, h * 0.06), Color(0.95, 0.8, 0.2), Vector3.ZERO, 6)
	SummonModels._mesh(out["root"], b)
	if out["tail"]:
		out["tail"].scale = Vector3(0.8, 1.15, 0.8)   # ince uzun, yukarı kıvrık kedi kuyruğu
	return out


static func dog(rng: RandomNumberGenerator) -> Dictionary:
	var out = {"root": Node3D.new(), "legs": [], "tail": null, "head": null, "mouth": Vector3.ZERO, "wings": [], "segments": [], "anim": "walk"}
	var coat: Array = DOG_COATS[rng.randi() % DOG_COATS.size()]
	var c: Color = coat[0]
	var h = 0.68
	var b: MB = SummonModels._quad(out, h, c, {"len": 1.2, "leg": 0.5, "snout": 0.26, "ear": 0.16, "eye": Color(0.18, 0.12, 0.08), "tail": "bushy", "belly": coat[1], "mark": c.darkened(0.35)})
	var by = h * 0.5 + h * 0.12
	var L = h * 1.2
	var hp = Vector3(0, by + h * 0.48, -L * 0.62)
	# açık renk namlu + göğüs (shiba / akita deseni), dil, kırmızı tasma
	b.add("sphere", hp + Vector3(0, -h * 0.05, -h * 0.17), Vector3(h * 0.16, h * 0.1, h * 0.18), coat[1], Vector3.ZERO, 8)
	b.add("sphere", Vector3(0, by - h * 0.02, -L * 0.36), Vector3(h * 0.3, h * 0.3, h * 0.26), coat[1], Vector3.ZERO, 8)
	b.add("box", hp + Vector3(0, -h * 0.13, -h * 0.24), Vector3(h * 0.05, h * 0.012, h * 0.08), Color(0.85, 0.35, 0.4), Vector3(25, 0, 0))
	b.add("torus", Vector3(0, by + h * 0.3, -L * 0.48), Vector3(h * 0.36, h * 0.36, h * 0.36), [Color(0.75, 0.15, 0.12), Color(0.2, 0.35, 0.65), Color(0.25, 0.5, 0.3)][rng.randi() % 3], Vector3(70, 0, 0), 12)
	SummonModels._mesh(out["root"], b)
	if out["tail"]:
		out["tail"].rotation.x = -0.9   # sırtına kıvrık kuyruk (shiba)
	return out


## Yük öküzü: iri kaslı gövde, omuz hörgücü, geniş alın, yana kıvrık boynuzlar, burun halkası, boyunduruk, sırt örtüsü
static func ox() -> Dictionary:
	var out = {"root": Node3D.new(), "legs": [], "tail": null, "head": null, "mouth": Vector3.ZERO, "wings": [], "segments": [], "anim": "walk"}
	var c = Color(0.42, 0.29, 0.19)
	var h = 1.55
	var b: MB = SummonModels._quad(out, h, c, {"len": 1.35, "leg": 0.42, "snout": 0.24, "ear": 0.08, "eye": Color(0.15, 0.1, 0.08), "tail": "thin", "belly": c.lightened(0.12), "mark": c.darkened(0.4)})
	var by = h * 0.42 + h * 0.12
	var L = h * 1.35
	var hp = Vector3(0, by + h * 0.48, -L * 0.62)
	b.add("sphere", Vector3(0, by + h * 0.12, -L * 0.25), Vector3(h * 0.55, h * 0.5, h * 0.62), c, Vector3.ZERO, 12)   # kaslı göğüs
	b.add("sphere", Vector3(0, by + h * 0.3, -L * 0.3), Vector3(h * 0.32, h * 0.22, h * 0.36), c.darkened(0.05), Vector3.ZERO, 10)   # omuz hörgücü
	b.add("sphere", Vector3(0, by + h * 0.08, L * 0.3), Vector3(h * 0.48, h * 0.44, h * 0.48), c, Vector3.ZERO, 10)   # kalça
	b.add("sphere", hp + Vector3(0, -h * 0.02, -h * 0.12), Vector3(h * 0.28, h * 0.22, h * 0.3), c.lightened(0.05), Vector3.ZERO, 10)   # geniş alın
	b.add("sphere", hp + Vector3(0, -h * 0.07, -h * 0.28), Vector3(h * 0.2, h * 0.14, h * 0.12), Color(0.55, 0.45, 0.42), Vector3.ZERO, 8)   # namlu
	b.add("torus", hp + Vector3(0, -h * 0.1, -h * 0.34), Vector3(h * 0.08, h * 0.08, h * 0.08), Color(0.75, 0.62, 0.3), Vector3(0, 90, 0), 10)   # burun halkası
	for sx in [-1.0, 1.0]:   # yana sonra yukarı kıvrık boynuz
		Loft.tube(b, [hp + Vector3(sx * h * 0.12, h * 0.1, -h * 0.05), hp + Vector3(sx * h * 0.26, h * 0.12, -h * 0.02), hp + Vector3(sx * h * 0.32, h * 0.24, -h * 0.06)],
			[h * 0.035, h * 0.025, h * 0.008], Color(0.9, 0.86, 0.74), 8, 3, true, false)
	# boyunduruk (ahşap kiriş + boyun kayışları) + sırtta dokuma örtü
	b.add("box", Vector3(0, by + h * 0.42, -L * 0.42), Vector3(h * 0.9, h * 0.07, h * 0.1), Color(0.5, 0.35, 0.22))
	for sx in [-1.0, 1.0]:
		b.add("box", Vector3(sx * h * 0.2, by + h * 0.3, -L * 0.42), Vector3(h * 0.03, h * 0.28, h * 0.06), Color(0.3, 0.22, 0.15))
	b.add("box", Vector3(0, by + h * 0.25, L * 0.02), Vector3(h * 0.62, h * 0.04, h * 0.7), Color(0.65, 0.2, 0.18))
	b.add("box", Vector3(0, by + h * 0.252, L * 0.02), Vector3(h * 0.5, h * 0.042, h * 0.5), Color(0.9, 0.82, 0.55))
	SummonModels._mesh(out["root"], b)
	for lg in out["legs"]:
		lg.scale = Vector3(1.5, 1.0, 1.4)   # kalın bacaklar
	return out
