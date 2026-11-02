class_name MistSwords
extends RefCounted
## Sis'in Yedi Kılıcı — referanslara bakılarak modellendi (naruto.fandom: her kılıcın kendi sayfası + "Seven Ninja Swords").
## Silah yerel ekseni: tutuş noktası orijin, ağız +Z boyunca, ağzın yassı yüzü X'e bakar, keskin kenar -Y.

const IDS := ["kubikiribocho", "samehada", "kiba", "hiramekarei", "shibuki", "nuibari", "kabutowari"]


static func build(id: String, b: MB) -> void:
	match id:
		"kubikiribocho": _kubikiri(b)
		"samehada": _samehada_wrapped(b)   # varsayılan: beyaz bezlere sarılı (Storm / anime)
		"samehada_acik": _samehada(b)        # açılmış mod: pullu canlı kılıç (moda bağlanacak)
		"kiba": _kiba(b)
		"hiramekarei": _hiramekarei(b)
		"shibuki": _shibuki(b)
		"nuibari": _nuibari(b)
		"kabutowari": _kabutowari(b)


## (x, y) kesit noktaları -> add_slab profili; slab Basis(z, y, -x) ile kullanılır (profil.y = -x)
static func _xy_to_yz(pts: PackedVector2Array) -> PackedVector2Array:
	var o = PackedVector2Array()
	for p in pts:
		o.append(Vector2(p.y, -p.x))
	return o


static func _v(arr: Array) -> PackedVector2Array:
	var out = PackedVector2Array()
	for p in arr:
		out.append(Vector2(p[0], p[1]))
	return out


## Sargılı sap: koyu öz + çapraz sargı bantları
static func _grip(b: MB, z0: float, z1: float, r: float, core: Color, wrapc: Color, bands := 6) -> void:
	b.add("cyl", Vector3(0, 0, (z0 + z1) * 0.5), Vector3(r * 2.0, z1 - z0, r * 2.0), core, Vector3(90, 0, 0), 10)
	for k in bands:
		var z = lerpf(z0 + 0.02, z1 - 0.02, (k + 0.5) / bands)
		b.add("torus", Vector3(0, 0, z), Vector3(r * 2.25, r * 1.4, r * 2.25), wrapc, Vector3(90, 0, 18 if k % 2 == 0 else -18), 10)


## Kubikiribōchō: dev satır — düz uzun keskin alt kenar, geniş kare uç, uca yakın yuvarlak delik,
## sapın dibinde sırtta yarım ay oyuk; kısa sargılı sap
static func _kubikiri(b: MB) -> void:
	var steel = Color(0.56, 0.58, 0.62)
	var sp = 0.07          # sırt çizgisi (y)
	# uzun ve görece ince ağız (boy/en ≈ 4.5); uçta keskin kenar sırttan daha ileri uzanır, uç yüzü eğik ve hafif kavisli
	var pts = [[-0.03, 0.04], [-0.26, 0.08], [-0.36, 0.18], [-0.37, 0.9], [-0.385, 1.6], [-0.375, 1.78], [-0.33, 1.86], [-0.25, 1.86],
		[-0.12, 1.79], [-0.02, 1.72], [sp, 1.66], [sp, 0.42]]
	var c = Vector2(sp, 0.27)
	var r = 0.15
	for k in range(1, 12):   # yarım ay oyuk (sırttan içeri)
		var t = PI * k / 12.0
		pts.append([c.x - sin(t) * r, c.y + cos(t) * r])
	pts.append([sp, 0.12])
	pts.append([0.03, 0.04])
	var outline = MB.hole(_v(pts), Vector2(-0.19, 1.6), 0.1, 20)
	b.add_slab(outline, 0.03, steel, Transform3D.IDENTITY, func(p: Vector2) -> float: return 0.006 if p.x < -0.33 else 0.03, steel.darkened(0.25))
	_grip(b, -0.36, 0.04, 0.032, Color(0.12, 0.12, 0.14), Color(0.32, 0.3, 0.34), 7)
	b.add("sphere", Vector3(0, 0, -0.38), Vector3(0.07, 0.07, 0.05), Color(0.2, 0.2, 0.22), Vector3.ZERO, 8)


## Samehada (sargılı, anime/Storm): uca doğru kalınlaşan kalın sopa, spiral beyaz bez sargısı (bantlar arası ince gri çizgi,
## yer yer bez katmanı kabarık), ucu açıkta koyu mavi pullu yuvarlak baş; örgülü sap ve kafatası topuz aynı
static func _samehada_wrapped(b: MB) -> void:
	# kaynak boyleolacak.png: sargılı gövde sapa doğru hafifçe incelir, altta bezin ucu dışa açılır;
	# sargının altından uzun, koyu lacivert, kıllı/dikenli pullu kısım çıkar (kubbe değil — gövdenin ~1/3'ü kadar uzun)
	var cloth = Color(0.94, 0.94, 0.92)
	var shade = Color(0.78, 0.79, 0.82)
	var R = 0.21
	var FL = 0.55   # yassı kesit (videoda uçtan bakınca geniş, ince oval): ince yüz sırta yaslanır (x)
	var z0 = 0.06
	var z1 = 1.15
	var n = 12
	for k in n:
		var t = (k + 0.5) / n
		var z = lerpf(z0, z1, t)
		var r = lerpf(R * 0.74, R, t)
		b.add("cyl", Vector3(0, 0, z), Vector3(r * 2.0 * FL, (z1 - z0) / n * 1.02, r * 2.0), shade, Vector3(90, 0, 0), 16)
		b.add("cyl", Vector3(0, 0, z), Vector3(r * 2.1 * FL, (z1 - z0) / n * 0.86, r * 2.1), cloth, Vector3(90 + (7.0 if k % 2 == 0 else -5.0), 0, 0), 16)
	b.add("cyl", Vector3(0, 0, z1 + 0.02), Vector3(R * 2.35 * FL, 0.06, R * 2.35), cloth, Vector3(90, 0, 0), 16)
	var sc = Color(0.18, 0.2, 0.36)
	var z2 = 1.85
	b.add("cyl", Vector3(0, 0, (z1 + z2) * 0.5), Vector3(R * 1.7 * FL, z2 - z1, R * 1.7), sc, Vector3(90, 0, 0), 14)
	b.add("sphere", Vector3(0, 0, z2), Vector3(R * 1.7 * FL, R * 1.7, R * 0.9), sc, Vector3.ZERO, 12)
	var rows = 12
	for k in rows:
		var z = lerpf(z1 + 0.04, z2 + 0.02, float(k) / (rows - 1))
		var rr = R * 0.85 * (1.0 - 0.25 * pow(float(k) / (rows - 1), 2.0))
		var cnt = 14
		for i in cnt:
			var a2 = TAU * (i + (k % 2) * 0.5) / cnt + k * 0.13
			var radial = Vector3(cos(a2) * FL, sin(a2), 0)
			var d = (Vector3(cos(a2), sin(a2), 0) * 0.75 + Vector3(0, 0, 0.66)).normalized()
			var tng = Vector3(-sin(a2), cos(a2), 0)
			var ln = 0.1 + 0.03 * ((i + k) % 3)
			b.add_xf("cone", Transform3D(Basis(tng * 0.05, d * ln, tng.cross(d).normalized() * 0.02), radial * rr + Vector3(0, 0, z) + d * ln * 0.35), sc.lightened(0.1 * ((i + k) % 2)), 3)
	# sap: uzun ince ten rengi çubuk + halkalar (önceki sap), ucunda küçük beyaz kurukafa (kaynak: samehadauc.png)
	var pole = Color(0.82, 0.68, 0.45)
	b.add("cyl", Vector3(0, 0, 0.04), Vector3(R * 1.6 * FL, 0.06, R * 1.6), cloth, Vector3(90, 0, 0), 14)
	b.add("cyl", Vector3(0, 0, -0.32), Vector3(0.055, 0.7, 0.055), pole, Vector3(90, 0, 0), 10)
	for k in 6:
		b.add("torus", Vector3(0, 0, -0.08 - k * 0.1), Vector3(0.065, 0.06, 0.065), pole.darkened(0.2), Vector3(90, 0, 0), 10)
	# kurukafa (küçük): sapın ucunda; tepesi sapın tersine (-Z), yüzü dışa (+X). Göz çukurları gömülü
	var bone = Color(0.96, 0.95, 0.9)
	var hole = Color(0.1, 0.09, 0.1)
	var k0 = 0.7
	var c0 = Vector3(0, 0, -0.71)
	b.add("sphere", c0, Vector3(0.12, 0.11, 0.12) * k0, bone, Vector3.ZERO, 16)
	b.add("box", c0 + Vector3(0.012, 0, 0.055) * k0, Vector3(0.062, 0.066, 0.04) * k0, bone)
	for sy in [-1.0, 1.0]:
		b.add("sphere", c0 + Vector3(0.046, sy * 0.023, -0.004) * k0, Vector3(0.024, 0.028, 0.028) * k0, hole, Vector3.ZERO, 10)
	b.add("box", c0 + Vector3(0.052, 0, 0.024) * k0, Vector3(0.008, 0.012, 0.014) * k0, hole)
	for i in 3:
		b.add("box", c0 + Vector3(0.0435, -0.015 + i * 0.015, 0.062) * k0, Vector3(0.003, 0.004, 0.026) * k0, hole)



## Samehada: canlı kılıç — üst üste binmiş mor-mavi pul dikenleriyle kaplı kalın gövde, uçta dişli ağız;
## örgülü sarı-bej sap, ucunda küçük kafatası
static func _samehada(b: MB) -> void:
	var sc = Color(0.3, 0.32, 0.52)
	var sc2 = Color(0.22, 0.23, 0.4)
	var L = 1.45
	# gövde özü (sapa doğru incelir, uca doğru genişler)
	for k in 8:
		var z = 0.08 + k * 0.18
		var rr = lerpf(0.12, 0.3, clampf(k / 5.0, 0.0, 1.0)) * (0.8 if k == 7 else 1.0)
		b.add("sphere", Vector3(0, 0, z), Vector3(rr * 2.0, rr * 1.7, 0.36), sc2, Vector3.ZERO, 12)
	# pullar: halka halka, geriye-dışa yatık yassı dikenler (her halka bir öncekini yarı örter)
	for k in 15:
		var z = 0.05 + k * 0.095
		var rr = lerpf(0.12, 0.3, clampf(k / 9.0, 0.0, 1.0))
		var n = 7 + int(rr * 24.0)
		for i in n:
			var a = TAU * (i + (k % 2) * 0.5) / n
			var radial = Vector3(cos(a), sin(a) * 0.85, 0)
			var d = (radial * 0.75 - Vector3(0, 0, 0.65)).normalized()   # dışa ve sapa doğru
			var tng = Vector3(-sin(a), cos(a), 0).normalized()
			var bz = tng.cross(d).normalized()
			var ln = 0.14 + rr * 0.45
			var xf = Transform3D(Basis(tng * 0.17, d * ln, bz * 0.03), radial * rr + Vector3(0, 0, z + 0.04) + d * ln * 0.4)
			b.add_xf("cone", xf, sc if (i + k) % 3 else sc2, 4)
	# uç: diş dizili ağız
	var mz = L + 0.06
	b.add("sphere", Vector3(0, 0, mz - 0.05), Vector3(0.5, 0.44, 0.24), sc2, Vector3.ZERO, 12)
	b.add("box", Vector3(0, -0.02, mz + 0.05), Vector3(0.42, 0.1, 0.04), Color(0.45, 0.08, 0.12))
	for i in 13:
		var x = lerpf(-0.19, 0.19, i / 12.0)
		b.add("cone", Vector3(x, 0.025, mz + 0.03), Vector3(0.025, 0.06, 0.02), Color(0.96, 0.95, 0.9), Vector3(180, 0, 0), 4)
		b.add("cone", Vector3(x + 0.012, -0.065, mz + 0.03), Vector3(0.025, 0.06, 0.02), Color(0.96, 0.95, 0.9), Vector3.ZERO, 4)
	# örgülü sap
	var braid = Color(0.82, 0.68, 0.38)
	for k in 12:
		var z = -0.04 - k * 0.04
		b.add("box", Vector3(0, 0, z), Vector3(0.07, 0.05, 0.05), braid, Vector3(0, 0, 40 if k % 2 == 0 else -40))
	b.add("cyl", Vector3(0, 0, -0.27), Vector3(0.05, 0.48, 0.05), braid.darkened(0.25), Vector3(90, 0, 0), 8)
	# kafatası topuz
	var bone = Color(0.94, 0.92, 0.86)
	b.add("sphere", Vector3(0, 0, -0.55), Vector3(0.08, 0.08, 0.09), bone, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(0.022 * sx, 0.015, -0.592), Vector3(0.025, 0.028, 0.02), Color(0.1, 0.1, 0.1), Vector3.ZERO, 6)


## Kiba: ikiz yıldırım kılıcı — ince uzun ağız, iki kenarda geriye dönük dikenler, yuvarlak tsuba, sargılı sap
static func _kiba(b: MB) -> void:
	var st = Color(0.68, 0.76, 0.88)
	var w = 0.026
	var pts = [[w, 0.06]]
	for z0 in [0.5, 0.88]:   # +y kenarı: iki büyük geri dönük diken
		pts += [[w, z0 - 0.02], [w + 0.14, z0 - 0.2], [w + 0.02, z0 + 0.05]]
	pts += [[w * 0.6, 1.0], [0.0, 1.1], [-w * 0.6, 1.0]]
	for z0 in [0.72, 0.3]:   # -y kenarı (aralı)
		pts += [[-w - 0.02, z0 + 0.05], [-w - 0.14, z0 - 0.2], [-w, z0 - 0.02]]
	pts += [[-w, 0.06]]
	b.add_slab(_v(pts), 0.014, st, Transform3D.IDENTITY, Callable(), st.darkened(0.2))
	b.add("box", Vector3(0, 0, 0.55), Vector3(0.004, 0.01, 0.9), Color(0.9, 0.95, 1.0))   # ortada parlak oluk
	b.add("cyl", Vector3(0, 0, 0.04), Vector3(0.12, 0.02, 0.12), Color(0.18, 0.2, 0.26), Vector3(90, 0, 0), 14)   # tsuba
	_grip(b, -0.22, 0.03, 0.026, Color(0.15, 0.17, 0.24), Color(0.35, 0.4, 0.55), 5)


## Hiramekarei: çift saplı geniş yaprak-balık ağzı (koyu), uca yakın iki delik, dipte geri kıvrılan yüzgeç kanca
static func _hiramekarei(b: MB) -> void:
	var dk = Color(0.13, 0.15, 0.24)
	var pts = [[0.03, 0.02], [0.12, 0.12], [0.24, 0.4], [0.29, 0.72], [0.26, 1.05], [0.16, 1.32], [0.03, 1.48], [-0.07, 1.44],
		[-0.19, 1.25], [-0.27, 0.95], [-0.29, 0.62], [-0.24, 0.32], [-0.16, 0.16],
		# yüzgeç kanca: alt kenardan geriye ve aşağı kıvrılır
		[-0.24, 0.1], [-0.34, -0.02], [-0.33, -0.12], [-0.26, -0.06], [-0.18, 0.02], [-0.06, 0.02]]
	var o = _v(pts)
	o = MB.hole(o, Vector2(0.05, 1.27), 0.04, 12)
	o = MB.hole(o, Vector2(-0.07, 1.14), 0.035, 12)
	b.add_slab(o, 0.04, dk, Transform3D.IDENTITY, func(p: Vector2) -> float: return 0.012 if absf(p.x) > 0.22 else 0.045, dk.lightened(0.2))
	b.add("box", Vector3(0, 0, 0.75), Vector3(0.048, 0.02, 1.0), dk.lightened(0.12))   # orta sırt
	var wr = Color(0.86, 0.84, 0.78)
	_grip(b, -0.4, 0.02, 0.022, Color(0.2, 0.2, 0.22), wr, 5)
	for sx in [-1.0, 1.0]:   # çift sap
		b.add("cyl", Vector3(0, 0.05 * sx, -0.19), Vector3(0.04, 0.42, 0.04), wr.darkened(0.1), Vector3(90, 0, 0), 8)


## Shibuki: patlayıcı parşömen kılıcı — geniş düz ağız, sırtında koca parşömen rulosu, yüzü sıra sıra patlayıcı etiketlerle kaplı
## SHIBUKI — tüm kaynaklardan ortak sonuç (bombakilici, ornek2-5, boyleolmaliydi, yukardanbakis, Sketchfab "Shibuki"):
## - sap ~0.4 m ince spiral sargılı, rulo ekseninden çıkar (sağ yumruk arka uçta z 0, sol el 0.2 önde)
## - kalın koyu mor rulo (Ø0.2, ~0.9 m), uçlarında açık gri bantlar; sap tarafında gri disk, uçta gri disk + koyu mil topuzu
## - HER ŞEY rulo ekseninden geçen TEK DÜZ DÜZLEMDE (x = 0): AĞIZ (-Y, vuran kenar) geniş ince gri çerçeve + içinde gevşek duran
##   爆 kâğıt tabakası; SIRT (+Y) dar çerçeve, onun içinde de 爆 kâğıdı; rulonun mor dış bezi sırt tarafını sarar
## - çerçeve yan plakaları düzlemde yassı, kökte geniş uca doğru daralan (ornek5'teki "damla" bunun perspektifi)
const SH_Z0 := 0.41   # rulo başı
const SH_Z1 := 1.31   # rulo sonu


static func _shibuki(b: MB) -> void:
	var met = Color(0.62, 0.63, 0.67)
	var dk = met.darkened(0.3)
	var lt = met.lightened(0.12)
	var roll = Color(0.2, 0.17, 0.25)
	var cloth = Color(0.3, 0.24, 0.36)
	var z0 = SH_Z0; var z1 = SH_Z1; var zm = (z0 + z1) * 0.5
	# sap (z -0.05..0.34) + pommel + boğaz bileziği
	b.add("cyl", Vector3(0, 0, 0.145), Vector3(0.04, 0.39, 0.04), Color(0.82, 0.82, 0.82), Vector3(90, 0, 0), 10)
	for k in 11:
		b.add("cyl", Vector3(0, 0, -0.03 + k * 0.034), Vector3(0.044, 0.008, 0.044), Color(0.4, 0.4, 0.43), Vector3(90 + 28, 0, 0), 10)
	b.add("cyl", Vector3(0, 0, -0.065), Vector3(0.05, 0.03, 0.05), met, Vector3(90, 0, 0), 10)
	b.add("cyl", Vector3(0, 0, 0.35), Vector3(0.07, 0.04, 0.07), met, Vector3(90, 0, 0), 12)
	# rulo + uç bantları + disk kapaklar + mil topuzu
	b.add("cyl", Vector3(0, 0, zm), Vector3(0.2, z1 - z0, 0.2), roll, Vector3(90, 0, 0), 20)
	for z in [z0 + 0.03, z1 - 0.03]:
		b.add("cyl", Vector3(0, 0, z), Vector3(0.214, 0.06, 0.214), lt, Vector3(90, 0, 0), 20)
	for z in [z0 - 0.025, z1 + 0.025]:
		b.add("cyl", Vector3(0, 0, z), Vector3(0.24, 0.05, 0.24), met, Vector3(90, 0, 0), 22)
		b.add("torus", Vector3(0, 0, z), Vector3(0.24, 0.24, 0.24), lt, Vector3(90, 0, 0), 22)
	b.add("cyl", Vector3(0, 0, z1 + 0.08), Vector3(0.085, 0.07, 0.085), Color(0.12, 0.1, 0.14), Vector3(90, 0, 0), 12)   # mil topuzu
	# çerçeveler (x = 0 düzleminde): yan plakalar kökte geniş (diske kaynaklı), dışa doğru daralır; dış çubuk
	for fr in [[-1.0, 0.48], [1.0, 0.17]]:   # -Y: geniş kâğıtlı AĞIZ (vuran taraf); +Y: dar sırt (o da kâğıtlı)
		var sg = float(fr[0]); var L = float(fr[1])
		for zs in [[z0 - 0.025, 1.0], [z1 + 0.025, -1.0]]:
			var zc = float(zs[0]); var zi = float(zs[1])   # zi: rulonun içine doğru
			# yan plaka profili (y, z): kökte 0.09 geniş, uçta 0.04
			var pl = [[sg * 0.06, zc - zi * 0.025], [sg * 0.06, zc + zi * 0.065], [sg * L, zc + zi * 0.04], [sg * (L + 0.02), zc - zi * 0.025]]
			b.add_slab(_v(pl), 0.018, met, Transform3D.IDENTITY, Callable(), dk)
			b.add("sphere", Vector3(0.011, sg * (L - 0.03), zc + zi * 0.01), Vector3(0.012, 0.012, 0.012), dk, Vector3.ZERO, 6)
			b.add("sphere", Vector3(-0.011, sg * (L - 0.03), zc + zi * 0.01), Vector3(0.012, 0.012, 0.012), dk, Vector3.ZERO, 6)
		b.add_slab(_v([[sg * (L - 0.02), z0 - 0.05], [sg * (L + 0.02), z0 - 0.05], [sg * (L + 0.02), z1 + 0.05], [sg * (L - 0.02), z1 + 0.05]]), 0.018, met, Transform3D.IDENTITY, Callable(), dk)
		b.add("box", Vector3(0, sg * (L + 0.02), zm), Vector3(0.008, 0.006, z1 - z0 + 0.1), dk)   # dış kenar çizgisi
	# rulonun mor dış bezi: rulonun sırt tarafını (+Y) saran ince örtü (kanat yok: sırtta da mühür kâğıdı var)
	for k in 9:
		var a = deg_to_rad(-60.0 + k * 15.0)
		b.add_xf("box", Transform3D(Basis(Vector3.BACK, a + PI * 0.5) * Basis.from_scale(Vector3(0.03, 0.008, z1 - z0 - 0.14)), Vector3(cos(a) * 0.104, sin(a) * 0.104, zm)), cloth)


## Shibuki'nin dokulu parçası: -Y çerçevesinde gevşek duran 爆 kâğıt tabakası (çerçeveye tam yapışık değil, hafif kalkık/sarkık)
static var _tag_mat: ShaderMaterial
static func shibuki_tags(m: ArrayMesh) -> void:
	if _tag_mat == null:
		_tag_mat = ShaderMaterial.new()
		_tag_mat.shader = load("res://shaders/toon.gdshader")
		_tag_mat.set_shader_parameter("use_vertex_color", false)
		_tag_mat.set_shader_parameter("tex", load("res://assets/weapons/shibuki_tags.png"))
		_tag_mat.set_shader_parameter("rim_amount", 0.1)
		_tag_mat.set_shader_parameter("tint", Color(0.86, 0.85, 0.83))
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z0 = SH_Z0 + 0.07; var z1 = SH_Z1 - 0.07
	# [x ofseti fonksiyonu yerine sabit kavis], ağız: rulodan teğet, çerçevenin hafif önünde gevşek; sırt: dar düz şerit
	var sheets = []
	var M = 6
	var wide = []
	for k in M + 1:
		var t = float(k) / M
		wide.append(Vector2(-0.07 * (1.0 - t) - 0.016 - 0.014 * sin(t * PI), -0.07 - t * 0.39))   # (x, y)
	sheets.append([wide, 0.6])
	var back = []
	for k in 3:
		var t = float(k) / 2.0
		back.append(Vector2(0.06 * (1.0 - t) + 0.012, 0.075 + t * 0.085))
	sheets.append([back, 0.13])
	for sh in sheets:
		var pts: Array = sh[0]
		var uw = float(sh[1])
		var n = pts.size() - 1
		for sd in [1.0, -1.0]:
			for k in n:
				var pa: Vector2 = pts[k]; var pb: Vector2 = pts[k + 1]
				var nrm = Vector3(pb.y - pa.y, -(pb.x - pa.x), 0).normalized() * sd
				var o = nrm * 0.002
				var q = [Vector3(pa.x, pa.y, z0) + o, Vector3(pb.x, pb.y, z0) + o, Vector3(pb.x, pb.y, z1) + o, Vector3(pa.x, pa.y, z1) + o]
				var u0 = uw * k / n; var u1 = uw * (k + 1) / n
				var uv = [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1.15), Vector2(u0, 1.15)]
				for order in [[0, 2, 1, 0, 3, 2], [0, 1, 2, 0, 2, 3]]:
					for i in order:
						st.set_normal(nrm)
						st.set_uv(uv[i])
						st.add_vertex(q[i])
	st.commit(m)
	m.surface_set_material(m.get_surface_count() - 1, _tag_mat)


## Nuibari: uzun ince iğne-kılıç; sapın dibindeki iğne gözünden sarkan tel
static func _nuibari(b: MB) -> void:
	var st = Color(0.82, 0.84, 0.88)
	b.add("cyl", Vector3(0, 0, 0.78), Vector3(0.028, 1.5, 0.028), st, Vector3(90, 0, 0), 8)
	b.add("cone", Vector3(0, 0, 1.6), Vector3(0.028, 0.18, 0.028), st, Vector3(90, 0, 0), 8)
	b.add("cyl", Vector3(0, 0, 0.02), Vector3(0.07, 0.02, 0.07), Color(0.3, 0.3, 0.34), Vector3(90, 0, 0), 10)
	_grip(b, -0.36, 0.01, 0.025, Color(0.22, 0.22, 0.25), Color(0.6, 0.6, 0.65), 7)
	b.add("torus", Vector3(0, 0, -0.42), Vector3(0.08, 0.08, 0.08), st, Vector3(0, 90, 0), 10)   # iğne gözü
	# tel: gözden sarkıp kıvrılarak uzanır
	var p = Vector3(0, -0.03, -0.45)
	for k in 14:
		var q = p + Vector3(sin(k * 0.6) * 0.05, -0.06, -0.03)
		var mid = (p + q) * 0.5
		var d = q - p
		b.add_xf("cyl", Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(0.006, d.length(), 0.006)), mid), Color(0.85, 0.86, 0.9), 4)
		p = q


## Kabutowari: zincirle bağlı ikili — elde geniş ağızlı balta, saptan sarkan zincirin ucunda tuğla örgülü çekiç
static func _kabutowari(b: MB) -> void:
	var st = Color(0.74, 0.72, 0.74)
	_grip(b, -0.16, 0.66, 0.028, Color(0.7, 0.66, 0.6), Color(0.52, 0.48, 0.42), 9)
	var ax = [[0.03, 0.5], [-0.06, 0.48], [-0.22, 0.4], [-0.48, 0.34], [-0.58, 0.52], [-0.6, 0.78], [-0.52, 1.0], [-0.26, 0.92], [-0.06, 0.82], [0.03, 0.8]]
	b.add_slab(_v(ax), 0.04, st, Transform3D.IDENTITY, func(p: Vector2) -> float: return 0.008 if p.x < -0.5 else 0.045, st.darkened(0.25))
	b.add("box", Vector3(0, 0.07, 0.65), Vector3(0.06, 0.1, 0.3), st.darkened(0.15))   # arka topuz
	b.add("torus", Vector3(0, 0, -0.2), Vector3(0.07, 0.07, 0.07), Color(0.4, 0.4, 0.42), Vector3(90, 0, 0), 8)
	# zincir: sapın dibinden aşağı sarkar
	var p = Vector3(0, -0.02, -0.24)
	for k in 9:
		b.add("torus", p, Vector3(0.05, 0.05, 0.05), Color(0.42, 0.42, 0.45), Vector3(90 * (k % 2), 0, 90 * ((k + 1) % 2)), 6)
		p += Vector3(0, -0.055, -0.01)
	# çekiç: yatay namlu, yüzü tuğla örgüsü
	var hc = p + Vector3(0, -0.19, 0)
	var hm = Color(0.7, 0.64, 0.62)
	b.add("cyl", hc, Vector3(0.34, 0.42, 0.34), hm, Vector3(90, 0, 0), 16)
	for ring in 5:
		for k in 10:
			var a = TAU * (k + (ring % 2) * 0.5) / 10.0
			b.add_xf("box", Transform3D(Basis(Vector3.BACK, a) * Basis.from_scale(Vector3(0.014, 0.1, 0.078)), hc + Vector3(cos(a) * 0.172, sin(a) * 0.172, -0.17 + ring * 0.085)),
				hm.lightened(0.15) if (k + ring) % 2 else hm.darkened(0.08))
	for z in [-0.21, 0.21]:
		b.add("cyl", hc + Vector3(0, 0, z), Vector3(0.36, 0.03, 0.36), hm.darkened(0.3), Vector3(90, 0, 0), 16)
	b.add("cyl", hc + Vector3(0, 0.2, 0), Vector3(0.05, 0.14, 0.05), Color(0.35, 0.3, 0.25), Vector3.ZERO, 8)   # çekiç sapı kökü
