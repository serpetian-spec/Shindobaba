class_name Stadium
extends RefCounted
## Chūnin Sınavı final stadyumu (referans: Konoha stadyumu): eğimli, dikey nervürlü yüksek dış duvar (köy rengi), içte tribün
## basamakları ve gri iç duvar, kenarı ağaçlı çim/kum saha; bir yanda katlı çatılı ana bina + Kage locası, karşısında giriş kapısı.
## Builder ile kurulur (Konoha köy kurulumunda; diğer köylerde final günü çalışma anında).

const R_FIELD := 58.0
const R_OUT := 78.0

## stil: {"outer": dış duvar rengi, "rib": nervür, "inner": iç duvar, "roof": çatı, "wall": ana bina duvarı, "field": saha, "trees": bool}
static func style_for(vid: String) -> Dictionary:
	match vid:
		"suna":
			return {"outer": Color(0.78, 0.62, 0.42), "rib": Color(0.62, 0.48, 0.32), "inner": Color(0.72, 0.62, 0.48), "roof": Color(0.66, 0.5, 0.34), "wall": Color(0.88, 0.8, 0.64), "field": Color(0.86, 0.74, 0.52), "trees": false}
		"kiri":
			return {"outer": Color(0.42, 0.5, 0.56), "rib": Color(0.3, 0.37, 0.43), "inner": Color(0.55, 0.6, 0.62), "roof": Color(0.28, 0.4, 0.55), "wall": Color(0.82, 0.85, 0.86), "field": Color(0.5, 0.58, 0.5), "trees": true}
		"kumo":
			return {"outer": Color(0.82, 0.82, 0.8), "rib": Color(0.62, 0.64, 0.66), "inner": Color(0.7, 0.72, 0.72), "roof": Color(0.3, 0.45, 0.68), "wall": Color(0.92, 0.92, 0.9), "field": Color(0.62, 0.6, 0.55), "trees": false}
		"iwa":
			return {"outer": Color(0.55, 0.45, 0.36), "rib": Color(0.42, 0.33, 0.26), "inner": Color(0.6, 0.53, 0.46), "roof": Color(0.5, 0.28, 0.22), "wall": Color(0.75, 0.66, 0.56), "field": Color(0.58, 0.5, 0.4), "trees": false}
	return {"outer": Color(0.62, 0.32, 0.24), "rib": Color(0.48, 0.24, 0.18), "inner": Color(0.56, 0.6, 0.54), "roof": Color(0.8, 0.6, 0.38), "wall": Color(0.95, 0.93, 0.88), "field": Color(0.5, 0.66, 0.36), "trees": true}


## cx, cn: Builder yerel koordinatı (stadyum merkezi); gy: zemin yüksekliği (yerel); kage_dir: Kage locasının yönü (derece, 0 = yerel kuzey)
static func build(b: Builder, cx: float, cn: float, gy: float, sty: Dictionary, rng: RandomNumberGenerator, kage_dir := 0.0) -> void:
	var outer: Color = sty["outer"]; var rib: Color = sty["rib"]; var inner: Color = sty["inner"]
	var roofc: Color = sty["roof"]; var wallc: Color = sty["wall"]
	var seg = 64
	var gate_a = kage_dir + 180.0
	# saha
	b.box(Vector3(cx, gy + 0.05, cn), Vector3(R_FIELD * 2.0, 0.1, R_FIELD * 2.0), sty["field"], 0, false)
	for k in seg:
		var a = k * 360.0 / seg
		var rad = deg_to_rad(a)
		var dv = Vector2(sin(rad), cos(rad))
		var gate = absf(fmod(a - gate_a + 540.0, 360.0) - 180.0) < 6.0
		# iç duvar (saha kenarı, 7 m)
		if not gate:
			var pi = dv * (R_FIELD + 0.6)
			b.box(Vector3(cx + pi.x, gy + 4.5, cn + pi.y), Vector3(2.0 * PI * R_FIELD / seg + 0.35, 9.0, 1.2), inner, a)
		# tribün basamakları (iç duvarın üstünden dışa yükselir)
		for t in 6:
			var ro = R_FIELD + 2.2 + t * 2.4
			var pt = dv * ro
			b.box(Vector3(cx + pt.x, gy + 9.4 + t * 1.6, cn + pt.y), Vector3(2.0 * PI * ro / seg + 0.3, 0.8, 2.6), inner.lightened(0.12) if t % 2 == 0 else inner, a)
		# dış duvar: eğimli (dışa yatık), yüksek; dikey nervürler
		var po = dv * R_OUT
		if not gate:
			b.box(Vector3(cx + po.x, gy + 11.5, cn + po.y), Vector3(2.0 * PI * R_OUT / seg + 0.4, 23.0, 2.2), outer, a, true, Vector3(-8, 0, 0))
			if k % 2 == 0:
				var pr = dv * (R_OUT + 1.3)
				b.box(Vector3(cx + pr.x, gy + 11.0, cn + pr.y), Vector3(0.8, 22.0, 0.8), rib, a, false, Vector3(-8, 0, 0))
			b.box(Vector3(cx + po.x, gy + 23.4, cn + po.y), Vector3(2.0 * PI * R_OUT / seg + 0.5, 0.8, 3.0), rib.darkened(0.1), a, false)   # taç kuşağı
	# saha kenarında ağaç halkası (referans: iç duvarın dibinde ağaçlar)
	if sty.get("trees", true):
		for k in 22:
			var a2 = TAU * k / 22.0 + rng.randf_range(-0.08, 0.08)
			if absf(fmod(rad_to_deg(a2) - gate_a + 540.0, 360.0) - 180.0) < 12.0:
				continue
			var tr = R_FIELD - rng.randf_range(3.0, 6.0)
			b.tree(cx + sin(a2) * tr, cn + cos(a2) * tr, rng.randf_range(0.8, 1.15), rng, gy)
	# ana bina + Kage locası (kage_dir yönünde, dış duvarın üstünde)
	var kd = Vector2(sin(deg_to_rad(kage_dir)), cos(deg_to_rad(kage_dir)))
	# referans: ana bina duvarın ARKASINDA, stadyumdan yüksek; üç kanat, her biri geniş saçaklı katlı çatılı
	var hb = kd * (R_OUT + 10.0)
	var hx = cx + hb.x; var hn = cn + hb.y
	var yaw_b = kage_dir + 180.0
	for side in [-1.0, 0.0, 1.0]:
		var wing_w = 26.0 if side == 0.0 else 22.0
		var wh = 30.0 if side == 0.0 else 26.0
		var o2 = Builder.rot(side * 25.0, side * side * -3.0, yaw_b)
		b.box(Vector3(hx + o2.x, gy + wh * 0.5, hn + o2.y), Vector3(wing_w, wh, 20.0), wallc, yaw_b)
		for k in 5:   # pencere sırası (sahaya bakan yüz)
			var o = Builder.rot(side * 25.0 - wing_w * 0.35 + k * wing_w * 0.175, -10.1 + side * side * -3.0, yaw_b)
			b.box(Vector3(hx + o.x, gy + wh - 6.0, hn + o.y), Vector3(2.6, 2.4, 0.2), Color(0.32, 0.28, 0.24), yaw_b, false)
		b.roof(Vector3(hx + o2.x, gy + wh + 2.6, hn + o2.y), Vector3(wing_w + 5.0, 5.0, 25.0), roofc, yaw_b)   # geniş saçak
	var o6 = Builder.rot(0.0, 0.0, yaw_b)
	b.box(Vector3(hx + o6.x, gy + 37.0, hn + o6.y), Vector3(14.0, 6.0, 12.0), wallc, yaw_b)   # orta kanat ikinci kat
	b.roof(Vector3(hx + o6.x, gy + 42.2, hn + o6.y), Vector3(19.0, 4.4, 16.0), roofc, yaw_b)
	# Kage locası: sahaya bakan çatılı balkon, iki koltuk
	var bp = kd * (R_FIELD + 4.0)
	var bx0 = cx + bp.x; var bn0 = cn + bp.y
	b.box(Vector3(bx0, gy + 12.0, bn0), Vector3(12.0, 0.6, 6.0), wallc.darkened(0.1), kage_dir + 180.0)
	b.roof(Vector3(bx0, gy + 17.0, bn0), Vector3(13.0, 2.4, 7.0), Color(0.72, 0.18, 0.15), kage_dir + 180.0)
	for side in [-1.0, 1.0]:
		var o3 = Builder.rot(side * 2.0, 0.5, kage_dir + 180.0)
		b.box(Vector3(bx0 + o3.x, gy + 13.0, bn0 + o3.y), Vector3(1.6, 1.4, 1.4), Color(0.6, 0.15, 0.12), kage_dir + 180.0, false)   # koltuk
		var o4 = Builder.rot(side * 5.6, -2.6, kage_dir + 180.0)
		b.box(Vector3(bx0 + o4.x, gy + 14.4, bn0 + o4.y), Vector3(0.4, 4.4, 0.4), Color(0.3, 0.2, 0.14), kage_dir + 180.0)
	# giriş kapısı (karşı taraf): çatılı kapı
	var gd = Vector2(sin(deg_to_rad(gate_a)), cos(deg_to_rad(gate_a)))
	var gp = gd * (R_OUT + 2.0)
	b.roof(Vector3(cx + gp.x, gy + 9.5, cn + gp.y), Vector3(16.0, 3.0, 6.0), Color(0.72, 0.18, 0.15), gate_a)
	for side in [-1.0, 1.0]:
		var o5 = Builder.rot(side * 6.5, 0.0, gate_a)
		b.box(Vector3(cx + gp.x + o5.x, gy + 4.5, cn + gp.y + o5.y), Vector3(1.2, 9.0, 1.2), Color(0.35, 0.22, 0.15), gate_a)
