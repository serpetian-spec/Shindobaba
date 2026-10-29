class_name FaceItemsExt
extends RefCounted
## Genişletilmiş yüz eşyaları (30 adet): ANBU hayvan maskeleri, festival/iblis maskeleri, solunum maskeleri, gözlükler, sargılar.
## OutfitParts.accessories eşleşmeyen face_style için buraya düşer. Baş kemiğine bağlanır (hc = baş merkezi).

const RED := Color(0.75, 0.1, 0.12)
const DARK := Color(0.08, 0.08, 0.1)
const WHITE := Color(0.96, 0.95, 0.92)
const STEEL := Color(0.62, 0.65, 0.7)

const NAMES := {
	"anbu_kurt": "ANBU Maskesi: Kurt", "anbu_baykus": "ANBU Maskesi: Baykuş", "anbu_ayi": "ANBU Maskesi: Ayı", "anbu_kartal": "ANBU Maskesi: Kartal",
	"anbu_tavsan": "ANBU Maskesi: Tavşan", "anbu_geyik": "ANBU Maskesi: Geyik", "anbu_kaplumbaga": "ANBU Maskesi: Kaplumbağa", "anbu_yarasa": "ANBU Maskesi: Yarasa",
	"anbu_kurbaga": "ANBU Maskesi: Kurbağa", "anbu_ejder": "ANBU Maskesi: Ejder", "oni": "Oni Maskesi", "hannya": "Hannya Maskesi", "tengu": "Tengu Maskesi",
	"kitsune_festival": "Festival Tilki Maskesi", "okame": "Okame Maskesi", "kok_maskesi": "Kök Birliği Maskesi", "spiral_maske": "Sarmal Maske",
	"avci_maske": "Sis Avcı Ninja Maskesi", "gaz_maskesi": "Yağmur Gaz Maskesi", "solunum_maskesi": "Samuray Solunum Maskesi", "bandaj_alt": "Alt Yüz Bandajı",
	"tam_bandaj": "Tam Yüz Sargısı", "yuvarlak_gozluk": "Yuvarlak Koyu Gözlük", "koruyucu_gozluk": "Turuncu Koruyucu Gözlük", "vizor": "Vizör Gözlük",
	"demir_yarim_maske": "Demir Yarım Maske", "savas_boyasi": "Savaş Boyası", "yuksek_pece": "Yüksek Yakalı Peçe", "tek_mercek": "Tek Mercek", "kemik_maske": "Kemik Kafatası Maske",
}


## ANBU taban maske: yüzü örten beyaz, hafif kavisli plaka, iki göz yarığı
static func _mask_base(mb: MB, col: Color) -> void:
	mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.17, 0.22, 0.07), col, Vector3.ZERO, 14)
	for sx in [-1.0, 1.0]:
		mb.add("box", Vector3(0.04 * sx, 0.035, 0.014), Vector3(0.035, 0.012, 0.006), DARK, Vector3(0, 0, -8 * sx))


static func build(m: CharacterModel, fs: String, fg: Color, hc: Vector3, hw: float, hh: float, hd: float, toon: Material) -> bool:
	var mb = MB.new()
	var ey = (m.eye_center_model.y if m.face_mi else hc.y - 0.03) - hc.y
	var at = hc + Vector3(0, -0.03, 0.085)   # tam yüz maskeleri
	match fs:
		"anbu_kurt":
			_mask_base(mb, fg)
			mb.add("cone", Vector3(0, -0.04, 0.05), Vector3(0.07, 0.1, 0.05), fg, Vector3(-80, 0, 0), 6)
			for sx in [-1.0, 1.0]:
				mb.add("cone", Vector3(0.07 * sx, 0.12, -0.02), Vector3(0.045, 0.09, 0.03), fg, Vector3(0, 0, -18 * sx), 4)
				mb.add("box", Vector3(0.05 * sx, 0.07, 0.03), Vector3(0.04, 0.006, 0.004), Color(0.3, 0.35, 0.6), Vector3(0, 0, 25 * sx))
		"anbu_baykus":
			_mask_base(mb, fg)
			for sx in [-1.0, 1.0]:
				mb.add("torus", Vector3(0.045 * sx, 0.035, 0.022), Vector3(0.07, 0.07, 0.07), Color(0.6, 0.45, 0.2), Vector3(90, 0, 0), 12)
				mb.add("cone", Vector3(0.07 * sx, 0.12, -0.01), Vector3(0.03, 0.06, 0.02), fg, Vector3(0, 0, -30 * sx), 4)
			mb.add("cone", Vector3(0, -0.01, 0.04), Vector3(0.025, 0.05, 0.02), Color(0.85, 0.65, 0.2), Vector3(-160, 0, 0), 4)
		"anbu_ayi":
			_mask_base(mb, fg)
			for sx in [-1.0, 1.0]:
				mb.add("sphere", Vector3(0.08 * sx, 0.11, -0.01), Vector3(0.05, 0.05, 0.02), fg, Vector3.ZERO, 8)
			mb.add("sphere", Vector3(0, -0.04, 0.045), Vector3(0.07, 0.05, 0.04), fg.darkened(0.05), Vector3.ZERO, 10)
			mb.add("sphere", Vector3(0, -0.025, 0.065), Vector3(0.025, 0.018, 0.01), DARK, Vector3.ZERO, 8)
			mb.add("box", Vector3(0, 0.09, 0.03), Vector3(0.008, 0.06, 0.004), RED)
		"anbu_kartal":
			_mask_base(mb, fg)
			mb.add("cone", Vector3(0, -0.02, 0.06), Vector3(0.05, 0.11, 0.04), Color(0.9, 0.7, 0.2), Vector3(-110, 0, 0), 6)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.06 * sx, 0.06, 0.025), Vector3(0.06, 0.012, 0.004), DARK, Vector3(0, 0, 20 * sx))
		"anbu_tavsan":
			_mask_base(mb, fg)
			for sx in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.035 * sx, 0.2, -0.02), Vector3(0.035, 0.18, 0.015), fg, Vector3(0, 0, -8 * sx), 8)
				mb.add("cyl", Vector3(0.035 * sx, 0.2, -0.01), Vector3(0.02, 0.14, 0.006), Color(0.95, 0.6, 0.7), Vector3(0, 0, -8 * sx), 8)
			mb.add("box", Vector3(0, -0.05, 0.04), Vector3(0.006, 0.03, 0.004), RED)
		"anbu_geyik":
			_mask_base(mb, fg)
			for sx in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.06 * sx, 0.17, -0.02), Vector3(0.012, 0.14, 0.012), Color(0.55, 0.42, 0.28), Vector3(0, 0, -25 * sx), 4)
				mb.add("cyl", Vector3(0.09 * sx, 0.2, -0.02), Vector3(0.01, 0.07, 0.01), Color(0.55, 0.42, 0.28), Vector3(0, 0, -60 * sx), 4)
				mb.add("box", Vector3(0.04 * sx, -0.01, 0.035), Vector3(0.006, 0.05, 0.004), Color(0.6, 0.4, 0.2))
		"anbu_kaplumbaga":
			_mask_base(mb, fg)
			for k in 6:
				var a = k * TAU / 6.0
				mb.add("box", Vector3(cos(a) * 0.04, 0.09 + sin(a) * 0.03, 0.03), Vector3(0.03, 0.005, 0.004), Color(0.3, 0.5, 0.3), Vector3(0, 0, rad_to_deg(a) + 90))
			mb.add("sphere", Vector3(0, -0.05, 0.04), Vector3(0.06, 0.035, 0.03), Color(0.35, 0.55, 0.35), Vector3.ZERO, 8)
		"anbu_yarasa":
			_mask_base(mb, Color(0.2, 0.2, 0.24))
			for sx in [-1.0, 1.0]:
				mb.add("cone", Vector3(0.08 * sx, 0.14, -0.01), Vector3(0.06, 0.12, 0.02), Color(0.2, 0.2, 0.24), Vector3(0, 0, -35 * sx), 3)
				mb.add("cone", Vector3(0.015 * sx, -0.07, 0.035), Vector3(0.012, 0.025, 0.008), WHITE, Vector3(180, 0, 0), 3)
		"anbu_kurbaga":
			_mask_base(mb, fg)
			for sx in [-1.0, 1.0]:
				mb.add("sphere", Vector3(0.06 * sx, 0.1, 0.0), Vector3(0.055, 0.05, 0.04), fg, Vector3.ZERO, 10)
				mb.add("sphere", Vector3(0.06 * sx, 0.1, 0.02), Vector3(0.02, 0.025, 0.01), DARK, Vector3.ZERO, 8)
			mb.add("box", Vector3(0, -0.05, 0.035), Vector3(0.11, 0.008, 0.004), Color(0.3, 0.6, 0.3))
		"anbu_ejder":
			_mask_base(mb, fg)
			for sx in [-1.0, 1.0]:
				mb.add("cone", Vector3(0.05 * sx, 0.14, -0.03), Vector3(0.02, 0.12, 0.02), Color(0.85, 0.7, 0.3), Vector3(-30, 0, -15 * sx), 4)
				mb.add("cyl", Vector3(0.07 * sx, -0.06, 0.02), Vector3(0.006, 0.14, 0.006), RED, Vector3(0, 0, 60 * sx), 4)
			mb.add("box", Vector3(0, 0.07, 0.03), Vector3(0.09, 0.008, 0.004), RED)
		"oni":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.19, 0.23, 0.08), Color(0.75, 0.12, 0.1), Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				mb.add("cone", Vector3(0.06 * sx, 0.15, -0.01), Vector3(0.035, 0.1, 0.035), Color(0.92, 0.88, 0.75), Vector3(0, 0, -15 * sx), 6)
				mb.add("box", Vector3(0.045 * sx, 0.04, 0.025), Vector3(0.04, 0.018, 0.006), Color(1.0, 0.85, 0.2), Vector3(0, 0, -15 * sx))
				mb.add("cone", Vector3(0.04 * sx, -0.07, 0.04), Vector3(0.018, 0.04, 0.015), WHITE, Vector3(0, 0, 0), 4)
			mb.add("box", Vector3(0, -0.06, 0.04), Vector3(0.1, 0.012, 0.006), DARK)
		"hannya":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.18, 0.23, 0.07), WHITE, Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				mb.add("cone", Vector3(0.07 * sx, 0.15, -0.02), Vector3(0.025, 0.12, 0.025), Color(0.85, 0.75, 0.4), Vector3(-20, 0, -28 * sx), 6)
				mb.add("box", Vector3(0.045 * sx, 0.04, 0.024), Vector3(0.04, 0.015, 0.005), Color(0.85, 0.7, 0.2), Vector3(0, 0, 20 * sx))
				mb.add("box", Vector3(0.05 * sx, 0.07, 0.02), Vector3(0.05, 0.006, 0.004), DARK, Vector3(0, 0, -25 * sx))
			mb.add("box", Vector3(0, -0.07, 0.035), Vector3(0.12, 0.03, 0.006), Color(0.6, 0.1, 0.1))
			for k in 5:
				mb.add("cone", Vector3(-0.04 + k * 0.02, -0.06, 0.04), Vector3(0.01, 0.02, 0.006), WHITE, Vector3(180, 0, 0), 3)
		"tengu":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.18, 0.22, 0.07), Color(0.75, 0.1, 0.1), Vector3.ZERO, 14)
			mb.add("cone", Vector3(0, -0.01, 0.09), Vector3(0.035, 0.16, 0.035), Color(0.75, 0.1, 0.1), Vector3(-90, 0, 0), 6)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.045 * sx, 0.05, 0.026), Vector3(0.045, 0.02, 0.005), WHITE, Vector3(0, 0, -20 * sx))
				mb.add("sphere", Vector3(0.05 * sx, -0.07, 0.025), Vector3(0.03, 0.04, 0.02), WHITE, Vector3.ZERO, 6)
		"kitsune_festival":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.17, 0.21, 0.07), WHITE, Vector3.ZERO, 14)
			mb.add("cone", Vector3(0, -0.04, 0.05), Vector3(0.06, 0.1, 0.04), WHITE, Vector3(-80, 0, 0), 6)
			for sx in [-1.0, 1.0]:
				mb.add("cone", Vector3(0.065 * sx, 0.12, -0.01), Vector3(0.05, 0.09, 0.03), WHITE, Vector3(0, 0, -22 * sx), 4)
				mb.add("cone", Vector3(0.065 * sx, 0.115, 0.004), Vector3(0.03, 0.06, 0.006), RED, Vector3(0, 0, -22 * sx), 4)
				mb.add("box", Vector3(0.045 * sx, 0.04, 0.026), Vector3(0.05, 0.008, 0.004), RED, Vector3(0, 0, 25 * sx))
				for k in 3:
					mb.add("box", Vector3(0.08 * sx, -0.02 - k * 0.015, 0.02), Vector3(0.04, 0.004, 0.003), Color(0.2, 0.2, 0.25), Vector3(0, 0, -10 * sx))
			mb.add("sphere", Vector3(0, 0.08, 0.026), Vector3(0.025, 0.025, 0.004), Color(0.95, 0.75, 0.2), Vector3.ZERO, 8)
		"okame":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.19, 0.22, 0.08), WHITE, Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				mb.add("sphere", Vector3(0.06 * sx, -0.03, 0.02), Vector3(0.05, 0.04, 0.02), Color(0.95, 0.6, 0.6), Vector3.ZERO, 8)
				mb.add("box", Vector3(0.045 * sx, 0.04, 0.03), Vector3(0.04, 0.006, 0.004), DARK, Vector3(0, 0, -15 * sx))
			mb.add("sphere", Vector3(0, -0.07, 0.03), Vector3(0.025, 0.012, 0.008), RED, Vector3.ZERO, 6)
			for sx in [-1.0, 1.0]:
				mb.add("sphere", Vector3(0.025 * sx, 0.1, 0.02), Vector3(0.025, 0.012, 0.004), DARK, Vector3.ZERO, 6)
		"kok_maskesi":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.17, 0.21, 0.07), WHITE, Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.045 * sx, 0.035, 0.015), Vector3(0.03, 0.01, 0.006), DARK)
			mb.add("box", Vector3(0, 0.1, 0.025), Vector3(0.06, 0.006, 0.004), DARK)
			mb.add("box", Vector3(0, -0.04, 0.03), Vector3(0.006, 0.05, 0.004), DARK)
		"spiral_maske":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.18, 0.22, 0.08), Color(0.92, 0.5, 0.12), Vector3.ZERO, 14)
			for k in 18:
				var a = k * 0.6
				var r = 0.012 + k * 0.0045
				mb.add("box", Vector3(0.04 + cos(a) * r, 0.03 + sin(a) * r, 0.03), Vector3(0.012, 0.004, 0.003), Color(0.55, 0.25, 0.05), Vector3(0, 0, rad_to_deg(a) + 90))
			mb.add("sphere", Vector3(0.04, 0.03, 0.03), Vector3(0.02, 0.02, 0.005), DARK, Vector3.ZERO, 8)
		"avci_maske":
			mb.add("sphere", Vector3(0, 0, -0.02), Vector3(0.17, 0.21, 0.07), WHITE, Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.045 * sx, 0.035, 0.015), Vector3(0.035, 0.008, 0.005), DARK, Vector3(0, 0, -8 * sx))
				for k in 3:
					mb.add("box", Vector3((0.02 + k * 0.025) * sx, 0.1, 0.022), Vector3(0.018, 0.005, 0.004), Color(0.6, 0.15, 0.15), Vector3(0, 0, 45 * sx))
			mb.add("box", Vector3(0, 0.11, 0.024), Vector3(0.006, 0.04, 0.004), Color(0.6, 0.15, 0.15))
		"gaz_maskesi":
			at = hc + Vector3(0, ey - 0.07, hd * 0.45)
			mb.add("sphere", Vector3(0, 0, 0), Vector3(0.13, 0.11, 0.08), Color(0.25, 0.27, 0.3), Vector3.ZERO, 12)
			mb.add("cyl", Vector3(0, -0.03, 0.05), Vector3(0.06, 0.05, 0.06), DARK, Vector3(-70, 0, 0), 10)
			for sx in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.06 * sx, -0.02, 0.02), Vector3(0.045, 0.035, 0.045), STEEL, Vector3(0, 0, 90), 10)
				mb.add("sphere", Vector3(0.04 * sx, 0.09, 0.0), Vector3(0.05, 0.045, 0.02), Color(0.4, 0.6, 0.55), Vector3.ZERO, 10)
		"solunum_maskesi":
			at = hc + Vector3(0, ey - 0.08, hd * 0.45)
			mb.add("hemi", Vector3(0, 0, 0), Vector3(0.14, 0.1, 0.1), Color(0.3, 0.32, 0.36), Vector3(90, 0, 0), 12)
			for sx in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.07 * sx, -0.06, -0.04), Vector3(0.025, 0.16, 0.025), Color(0.25, 0.25, 0.28), Vector3(40, 0, 20 * sx), 6)
				for k in 4:
					mb.add("torus", Vector3(0.07 * sx + 0.01 * sx * k, -0.03 - k * 0.025, -0.02 - k * 0.012), Vector3(0.035, 0.035, 0.035), STEEL, Vector3(40, 0, 20 * sx), 8)
			for k in 3:
				mb.add("box", Vector3(0, -0.01 - k * 0.018, 0.05), Vector3(0.08, 0.006, 0.006), STEEL)
		"bandaj_alt":
			at = hc + Vector3(0, ey - 0.09, 0.0)
			for k in 4:
				mb.add("cyl", Vector3(0, -k * 0.035, 0.005), Vector3(hw * 1.08 - k * 0.006, 0.03, hd * 1.03 - k * 0.006), WHITE.darkened(k * 0.04), Vector3(-8 + (k % 2) * 12, 0, 0), 18)
		"tam_bandaj":
			at = hc + Vector3(0, ey - 0.02, 0.0)
			for k in 6:
				mb.add("cyl", Vector3(0, 0.07 - k * 0.035, 0.0), Vector3(hw * 1.12, 0.032, hd * 1.08), WHITE.darkened(k * 0.03), Vector3(-6 + (k % 2) * 10, 0, (k % 3) * 4), 18)
			mb.add("box", Vector3(-0.04, 0.02, hd * 0.55), Vector3(0.05, 0.03, 0.004), Color(0.15, 0.1, 0.08))
		"yuvarlak_gozluk":
			at = hc + Vector3(0, ey + 0.005, hd * 0.52)
			for sx in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.042 * sx, 0, 0), Vector3(0.05, 0.006, 0.05), Color(0.05, 0.05, 0.08), Vector3(90, 0, 0), 14)
				mb.add("torus", Vector3(0.042 * sx, 0, 0.001), Vector3(0.055, 0.055, 0.04), DARK, Vector3(90, 0, 0), 14)
				mb.add("box", Vector3(0.09 * sx, 0, -0.06), Vector3(0.006, 0.006, 0.12), DARK)
			mb.add("box", Vector3(0, 0.005, 0.002), Vector3(0.03, 0.005, 0.005), DARK)
		"koruyucu_gozluk":
			at = hc + Vector3(0, ey + 0.005, hd * 0.5)
			for sx in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.042 * sx, 0, 0), Vector3(0.06, 0.03, 0.06), Color(0.95, 0.55, 0.15), Vector3(90, 0, 0), 14)
				mb.add("cyl", Vector3(0.042 * sx, 0, 0.016), Vector3(0.048, 0.004, 0.048), Color(0.7, 0.85, 0.95), Vector3(90, 0, 0), 14)
			mb.add("cyl", Vector3(0, 0, -hd * 0.5), Vector3(hw * 1.15, 0.02, hd * 1.05), Color(0.2, 0.2, 0.25), Vector3.ZERO, 18)
		"vizor":
			at = hc + Vector3(0, ey + 0.005, hd * 0.52)
			mb.add("box", Vector3(0, 0, 0), Vector3(0.15, 0.035, 0.01), Color(0.15, 0.25, 0.45), Vector3(-5, 0, 0))
			mb.add("box", Vector3(0, 0.02, 0), Vector3(0.16, 0.008, 0.012), STEEL)
			for sx in [-1.0, 1.0]:
				mb.add("box", Vector3(0.085 * sx, 0, -0.06), Vector3(0.008, 0.012, 0.12), STEEL)
		"demir_yarim_maske":
			at = hc + Vector3(0, ey - 0.08, hd * 0.47)
			mb.add("hemi", Vector3(0, 0, 0), Vector3(0.15, 0.1, 0.1), STEEL, Vector3(90, 0, 0), 12)
			for sx in [-1.0, 1.0]:
				for k in 3:
					mb.add("sphere", Vector3(0.06 * sx, -0.02 - k * 0.025, 0.03), Vector3(0.012, 0.012, 0.006), Color(0.45, 0.45, 0.5), Vector3.ZERO, 6)
			mb.add("box", Vector3(0, -0.01, 0.052), Vector3(0.006, 0.07, 0.006), Color(0.45, 0.45, 0.5))
		"savas_boyasi":
			at = hc + Vector3(0, ey - 0.03, hd * 0.5)
			for sx in [-1.0, 1.0]:
				for k in 2:
					mb.add("box", Vector3((0.06 + k * 0.012) * sx, -0.01 - k * 0.025, 0.0), Vector3(0.045, 0.008, 0.003), Color(0.8, 0.1, 0.1), Vector3(0, 20 * sx, 25 * sx))
				mb.add("box", Vector3(0.045 * sx, 0.055, -0.005), Vector3(0.03, 0.006, 0.003), Color(0.8, 0.1, 0.1), Vector3(0, 20 * sx, -15 * sx))
		"yuksek_pece":
			at = hc + Vector3(0, ey - 0.06, 0.0)
			mb.add("cyl", Vector3(0, -0.03, 0.01), Vector3(hw * 1.1, 0.14, hd * 1.05), fg, Vector3(-6, 0, 0), 20)
			mb.add("cyl", Vector3(0, 0.05, -0.02), Vector3(hw * 1.15, 0.05, hd * 1.1), fg.darkened(0.15), Vector3(-6, 0, 0), 20)
			mb.add("box", Vector3(0, -0.11, hd * 0.5), Vector3(hw * 0.7, 0.04, 0.01), fg.darkened(0.25))
		"tek_mercek":
			at = hc + Vector3(-0.042, ey + 0.005, hd * 0.53)
			mb.add("cyl", Vector3.ZERO, Vector3(0.05, 0.004, 0.05), Color(0.75, 0.85, 0.95), Vector3(90, 0, 0), 14)
			mb.add("torus", Vector3(0, 0, 0.001), Vector3(0.055, 0.055, 0.04), Color(0.8, 0.65, 0.25), Vector3(90, 0, 0), 14)
			mb.add("cyl", Vector3(-0.02, -0.07, -0.01), Vector3(0.004, 0.1, 0.004), Color(0.8, 0.65, 0.25), Vector3(0, 0, -10), 4)
		"kemik_maske":
			mb.add("sphere", Vector3(0, 0.01, -0.02), Vector3(0.18, 0.2, 0.08), Color(0.94, 0.92, 0.84), Vector3.ZERO, 14)
			for sx in [-1.0, 1.0]:
				mb.add("sphere", Vector3(0.045 * sx, 0.035, 0.02), Vector3(0.05, 0.045, 0.02), DARK, Vector3.ZERO, 10)
			mb.add("cone", Vector3(0, -0.015, 0.03), Vector3(0.025, 0.03, 0.01), DARK, Vector3(180, 0, 0), 3)
			for k in 6:
				mb.add("box", Vector3(-0.05 + k * 0.02, -0.07, 0.03), Vector3(0.012, 0.025, 0.006), Color(0.94, 0.92, 0.84).darkened(0.1))
		_:
			return false
	m._mesh_on("Head", mb.build(toon), Transform3D(Basis.IDENTITY, at))
	return true
