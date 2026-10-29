class_name BackItemsExt
extends RefCounted
## Genişletilmiş sırt / bel eşyaları (50 adet). OutfitParts.accessories eşleşmeyen back_item için buraya düşer.
## Her biri MB primitifleriyle kurulur; ch = UpperChest, hip = Hips dinlenme konumu. Sırt -Z yönünde.

const STEEL := Color(0.72, 0.74, 0.78)
const DARK := Color(0.12, 0.12, 0.14)
const WOOD := Color(0.42, 0.3, 0.18)
const PAPER := Color(0.93, 0.9, 0.8)
const LEATHER := Color(0.36, 0.24, 0.15)
const ROPE := Color(0.7, 0.6, 0.42)

const NAMES := {
	"dev_yelpaze": "Dev Savaş Yelpazesi", "kunai_kilif_seti": "Sırt Kunai Kılıf Seti", "ikiz_katana": "Çapraz İkiz Katana", "nodachi": "Nodachi",
	"genis_kesici": "Geniş Kesici Kılıç", "sargili_kilic": "Sargılı Dev Kılıç", "kusarigama_bel": "Belde Kusarigama", "bo_asa": "Bō Asası",
	"naginata": "Naginata", "yay_sadak": "Yay ve Sadak", "kukla_bohca": "Kukla Bohçası", "uc_parsomen": "Üçlü Parşömen Rafı",
	"yatay_parsomen": "Yatay Çağırma Parşömeni", "kurbaga_cuzdan": "Kurbağa Cüzdan", "ikiz_matara": "İkiz Su Matarası", "ilac_kutusu": "Tıbbi Ninja Kutusu",
	"hasir_rulo": "Hasır Uyku Rulosu", "flut_kemer": "Belde Flüt", "kemik_kilic": "Kemik Kılıç", "savas_baltasi": "Savaş Baltası",
	"ninjato": "Dik Ninjatō", "tetsubo": "Tetsubō", "shuriken_kesesi": "Shuriken Keseleri", "etiket_kemeri": "Patlayıcı Etiket Kemeri",
	"fener": "Bel Feneri", "ahsap_kalkan": "Ahşap Kalkan", "ikiz_fuma": "İkiz Fūma Shuriken", "shakujo": "Keşiş Asası (Shakujō)",
	"nobori": "Nobori Sancağı", "kristal_kure": "Kristal Küre Kutusu", "ikiz_tonfa": "İkiz Tonfa", "tessen_bel": "Belde Demir Yelpaze",
	"manriki": "Manriki Zinciri", "ikiz_kabak": "İkiz Kabak Matara", "furoshiki": "Furoshiki Bohçası", "harita_tupu": "Harita Tüpü",
	"kus_kafesi": "Haberci Kuş Kafesi", "puskullu_kilic": "Püsküllü Kılıç", "kunai_yelpaze": "Yelpaze Dizili Kunailer", "sirt_plakasi": "Zırhlı Sırt Plakası",
	"dis_kolye": "Hayvan Dişi Kolyesi", "can_kemeri": "Çan Kemeri", "ikiz_kama": "İkiz Kama", "sadak": "Ok Sadağı",
	"savas_cekici": "Savaş Çekici", "tilki_maske_bel": "Belde Tilki Maskesi", "murekkep_kutusu": "Mürekkep ve Fırça Kutusu", "chakra_bicaklari": "Belde Chakra Bıçakları",
	"zincir_bel": "Bele Sarılı Zincir", "bambu_matara": "Bambu Matara",
}


static func _blade(mb: MB, base: Vector3, length: float, w: float, rot: Vector3, steel := STEEL, grip := DARK, guard := true) -> void:
	var b = Basis.from_euler(rot * PI / 180.0)
	var up = b * Vector3.UP
	mb.add("box", base + up * (length * 0.5 + 0.12), Vector3(w * 0.25, length, w), steel, rot)
	mb.add("cone", base + up * (length + 0.12 + w * 0.4), Vector3(w * 0.25, w * 0.8, w), steel, rot, 4)
	mb.add("cyl", base + up * 0.06, Vector3(0.028, 0.16, 0.028), grip, rot, 6)
	if guard:
		mb.add("cyl", base + up * 0.13, Vector3(0.07, 0.012, 0.07), Color(0.6, 0.5, 0.2), rot, 8)


static func _scroll(mb: MB, pos: Vector3, length: float, r: float, rot: Vector3, col := PAPER, cap := Color(0.6, 0.15, 0.12)) -> void:
	mb.add("cyl", pos, Vector3(r * 2.0, length, r * 2.0), col, rot, 10)
	var b = Basis.from_euler(rot * PI / 180.0)
	var up = b * Vector3.UP
	for s in [-1.0, 1.0]:
		mb.add("cyl", pos + up * s * length * 0.5, Vector3(r * 2.3, 0.025, r * 2.3), cap, rot, 10)


static func _pouch(mb: MB, pos: Vector3, size: Vector3, col: Color) -> void:
	mb.add("box", pos, size, col)
	mb.add("box", pos + Vector3(0, size.y * 0.35, 0), size * Vector3(1.05, 0.3, 1.05), col.darkened(0.2))


static func build(m: CharacterModel, kind: String, bc: Color, ch: Vector3, hip: Vector3, toon: Material) -> bool:
	var mb = MB.new()
	var bone = "UpperChest"
	var at = ch + Vector3(0, -0.1, -0.2)
	match kind:
		"dev_yelpaze":
			for k in 7:
				mb.add("box", Vector3((k - 3) * 0.06, 0.3, 0), Vector3(0.055, 0.85, 0.02), bc if k % 2 == 0 else PAPER, Vector3(0, 0, (k - 3) * 4.0))
			for k in 3:
				mb.add("sphere", Vector3(-0.12 + k * 0.12, 0.55, 0.015), Vector3(0.08, 0.08, 0.01), Color(0.65, 0.4, 0.75), Vector3.ZERO, 10)
			mb.add("cyl", Vector3(0, -0.12, 0), Vector3(0.05, 0.12, 0.05), DARK, Vector3.ZERO, 8)
			at = ch + Vector3(0.05, -0.15, -0.2)
		"kunai_kilif_seti":
			mb.add("box", Vector3(0, 0, 0), Vector3(0.3, 0.32, 0.03), LEATHER)
			for k in 5:
				mb.add("cone", Vector3(-0.12 + k * 0.06, 0.22, 0.01), Vector3(0.025, 0.14, 0.008), STEEL, Vector3.ZERO, 4)
				mb.add("torus", Vector3(-0.12 + k * 0.06, 0.12, 0.012), Vector3(0.03, 0.03, 0.03), DARK, Vector3(90, 0, 0), 8)
			for k in 2:
				mb.add("box", Vector3(0, -0.06 + k * 0.12, 0.018), Vector3(0.32, 0.025, 0.01), bc)
		"ikiz_katana":
			for s in [-1.0, 1.0]:
				mb.add("box", Vector3(0, 0.1, 0), Vector3(0.05, 0.85, 0.035), bc, Vector3(0, 0, 32 * s))
				mb.add("cyl", Vector3(-0.21 * s, 0.36, 0), Vector3(0.08, 0.015, 0.08), Color(0.6, 0.5, 0.2), Vector3(0, 0, 32 * s), 8)
				mb.add("cyl", Vector3(-0.25 * s, 0.45, 0), Vector3(0.03, 0.22, 0.03), DARK, Vector3(0, 0, 32 * s), 6)
		"nodachi":
			mb.add("box", Vector3(0, 0.2, 0), Vector3(0.055, 1.35, 0.04), bc, Vector3(0, 0, -25))
			mb.add("cyl", Vector3(0.3, 0.83, 0), Vector3(0.03, 0.32, 0.03), DARK, Vector3(0, 0, -25), 6)
			mb.add("cyl", Vector3(0.24, 0.7, 0), Vector3(0.08, 0.015, 0.08), Color(0.6, 0.5, 0.2), Vector3(0, 0, -25), 8)
			mb.add("box", Vector3(0, 0.25, 0.022), Vector3(0.06, 0.05, 0.01), Color(0.8, 0.15, 0.12), Vector3(0, 0, -25))
		"genis_kesici":
			mb.add("box", Vector3(0, 0.2, 0), Vector3(0.36, 1.0, 0.03), STEEL, Vector3(0, 0, -12))
			mb.add("cyl", Vector3(0.05, 0.5, 0.0), Vector3(0.16, 0.035, 0.16), DARK, Vector3(90, 0, -12), 14)
			mb.add("cyl", Vector3(-0.08, -0.38, 0), Vector3(0.035, 0.25, 0.035), DARK, Vector3(0, 0, -12), 6)
		"sargili_kilic":
			mb.add("cyl", Vector3(0, 0.2, 0), Vector3(0.2, 1.1, 0.14), bc, Vector3(0, 0, -15), 10)
			for k in 7:
				mb.add("cyl", Vector3(-0.0 + k * 0.022, -0.25 + k * 0.14, 0), Vector3(0.21, 0.03, 0.15), PAPER, Vector3(0, 0, -15 + (k % 2) * 12), 10)
			mb.add("cyl", Vector3(-0.12, -0.45, 0), Vector3(0.04, 0.22, 0.04), DARK, Vector3(0, 0, -15), 6)
		"kusarigama_bel":
			bone = "Hips"
			at = hip + Vector3(0.2, 0.0, -0.02)
			mb.add("cyl", Vector3(0, 0, 0), Vector3(0.035, 0.24, 0.035), WOOD, Vector3.ZERO, 6)
			mb.add("box", Vector3(0.06, 0.12, 0), Vector3(0.14, 0.035, 0.01), STEEL, Vector3(0, 0, -20))
			for k in 3:
				mb.add("torus", Vector3(0, -0.05 - k * 0.025, 0.02), Vector3(0.12, 0.12, 0.12), Color(0.4, 0.4, 0.44), Vector3(70, 0, 0), 12)
		"bo_asa":
			mb.add("cyl", Vector3(0, 0.25, 0), Vector3(0.045, 1.6, 0.045), bc, Vector3(0, 0, 28), 8)
			for s in [-1.0, 1.0]:
				mb.add("cyl", Vector3(-0.37 * s, 0.25 + 0.7 * s, 0), Vector3(0.05, 0.08, 0.05), DARK, Vector3(0, 0, 28), 8)
		"naginata":
			mb.add("cyl", Vector3(0, 0.3, 0), Vector3(0.04, 1.5, 0.04), bc, Vector3(0, 0, -22), 8)
			mb.add("box", Vector3(0.36, 1.06, 0), Vector3(0.06, 0.4, 0.015), STEEL, Vector3(0, 0, -30))
			mb.add("cyl", Vector3(0.3, 0.93, 0), Vector3(0.06, 0.03, 0.06), Color(0.6, 0.5, 0.2), Vector3(0, 0, -22), 8)
		"yay_sadak":
			mb.add("torus", Vector3(0.05, 0.15, 0.02), Vector3(0.9, 0.9, 0.08), bc, Vector3(0, 90, 0), 18)
			mb.add("cyl", Vector3(-0.1, 0.05, -0.03), Vector3(0.12, 0.55, 0.12), LEATHER, Vector3(0, 0, 18), 10)
			for k in 4:
				mb.add("cyl", Vector3(-0.17 + k * 0.03, 0.38, -0.03), Vector3(0.012, 0.3, 0.012), WOOD, Vector3(0, 0, 18), 4)
				mb.add("cone", Vector3(-0.2 + k * 0.03, 0.55, -0.03), Vector3(0.03, 0.06, 0.008), Color(0.95, 0.95, 0.95), Vector3(0, 0, 18), 3)
		"kukla_bohca":
			mb.add("cyl", Vector3(0, 0.15, 0), Vector3(0.36, 0.9, 0.3), bc, Vector3(0, 0, 8), 10)
			for k in 5:
				mb.add("cyl", Vector3(0.01 * k, -0.2 + k * 0.18, 0), Vector3(0.38, 0.03, 0.32), PAPER, Vector3(0, 0, 8 + (k % 2) * 16), 10)
			mb.add("sphere", Vector3(0.06, 0.62, 0), Vector3(0.12, 0.08, 0.1), WOOD, Vector3.ZERO, 8)
		"uc_parsomen":
			mb.add("box", Vector3(0, 0, 0), Vector3(0.32, 0.04, 0.12), WOOD)
			mb.add("box", Vector3(0, 0.36, 0), Vector3(0.32, 0.04, 0.12), WOOD)
			for k in 3:
				_scroll(mb, Vector3(-0.11 + k * 0.11, 0.18, 0), 0.4, 0.045, Vector3.ZERO, PAPER, [Color(0.6, 0.15, 0.12), Color(0.15, 0.3, 0.6), Color(0.2, 0.5, 0.25)][k])
		"yatay_parsomen":
			_scroll(mb, Vector3(0, 0.0, 0), 0.75, 0.09, Vector3(0, 0, 90), bc, Color(0.55, 0.12, 0.1))
			mb.add("box", Vector3(0, 0, 0.09), Vector3(0.4, 0.03, 0.01), Color(0.6, 0.15, 0.12))
			at = ch + Vector3(0, -0.28, -0.2)
		"kurbaga_cuzdan":
			bone = "Hips"
			at = hip + Vector3(-0.19, 0.0, 0.05)
			mb.add("sphere", Vector3.ZERO, Vector3(0.12, 0.1, 0.07), Color(0.3, 0.6, 0.3), Vector3.ZERO, 10)
			for s in [-1.0, 1.0]:
				mb.add("sphere", Vector3(0.03 * s, 0.05, 0.03), Vector3(0.025, 0.025, 0.02), Color(0.95, 0.95, 0.9), Vector3.ZERO, 6)
				mb.add("sphere", Vector3(0.03 * s, 0.05, 0.04), Vector3(0.012, 0.012, 0.01), DARK, Vector3.ZERO, 6)
			mb.add("box", Vector3(0, -0.01, 0.036), Vector3(0.07, 0.006, 0.004), DARK)
		"ikiz_matara":
			bone = "Hips"
			at = hip + Vector3(0, 0.0, -0.12)
			for s in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.1 * s, 0, 0), Vector3(0.09, 0.2, 0.09), bc, Vector3.ZERO, 10)
				mb.add("cyl", Vector3(0.1 * s, 0.12, 0), Vector3(0.035, 0.04, 0.035), WOOD, Vector3.ZERO, 6)
		"ilac_kutusu":
			mb.add("box", Vector3(0, 0, 0), Vector3(0.32, 0.36, 0.14), bc)
			mb.add("box", Vector3(0, 0.0, -0.072), Vector3(0.18, 0.05, 0.005), Color(0.85, 0.15, 0.12))
			mb.add("box", Vector3(0, 0.0, -0.072), Vector3(0.05, 0.18, 0.005), Color(0.85, 0.15, 0.12))
			mb.add("box", Vector3(0, 0.19, 0), Vector3(0.12, 0.03, 0.04), DARK)
		"hasir_rulo":
			mb.add("cyl", Vector3(0, 0.25, 0), Vector3(0.18, 0.55, 0.18), Color(0.78, 0.68, 0.45), Vector3(0, 0, 90), 12)
			for s in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.18 * s, 0.25, 0), Vector3(0.19, 0.025, 0.19), ROPE.darkened(0.3), Vector3(0, 0, 90), 12)
		"flut_kemer":
			bone = "Hips"
			at = hip + Vector3(0.18, 0.02, -0.05)
			mb.add("cyl", Vector3.ZERO, Vector3(0.03, 0.4, 0.03), bc, Vector3(0, 0, 70), 8)
			for k in 4:
				mb.add("cyl", Vector3(-0.08 + k * 0.05, 0.03 - k * 0.018, 0.015), Vector3(0.012, 0.004, 0.012), DARK, Vector3(90, 0, 0), 6)
		"kemik_kilic":
			mb.add("cone", Vector3(0, 0.3, 0), Vector3(0.09, 1.0, 0.05), Color(0.97, 0.95, 0.88), Vector3(0, 0, -18), 6)
			for k in 4:
				mb.add("sphere", Vector3(0.05 - k * 0.025, -0.15 + k * 0.08, 0), Vector3(0.08, 0.05, 0.06), Color(0.95, 0.93, 0.85), Vector3.ZERO, 6)
		"savas_baltasi":
			mb.add("cyl", Vector3(0, 0.15, 0), Vector3(0.04, 1.0, 0.04), WOOD, Vector3(0, 0, 25), 8)
			mb.add("box", Vector3(-0.32, 0.6, 0), Vector3(0.28, 0.22, 0.03), STEEL, Vector3(0, 0, 25))
			mb.add("cone", Vector3(-0.47, 0.55, 0), Vector3(0.12, 0.24, 0.03), STEEL, Vector3(0, 0, 115), 4)
		"ninjato":
			mb.add("box", Vector3(0, 0.15, 0), Vector3(0.05, 0.75, 0.035), bc)
			mb.add("box", Vector3(0, 0.6, 0), Vector3(0.11, 0.025, 0.06), DARK)
			mb.add("cyl", Vector3(0, 0.72, 0), Vector3(0.03, 0.22, 0.03), DARK, Vector3.ZERO, 6)
			mb.add("box", Vector3(0, 0.3, 0.02), Vector3(0.06, 0.05, 0.01), ROPE)
		"tetsubo":
			mb.add("cyl", Vector3(0, 0.2, 0), Vector3(0.09, 1.0, 0.09), DARK, Vector3(0, 0, -20), 10)
			for k in 12:
				var a = k * TAU / 6.0
				mb.add("cone", Vector3(cos(a) * 0.05 - (0.08 + k * 0.025) * 0.34, 0.35 + (k % 6) * 0.08, sin(a) * 0.05), Vector3(0.025, 0.05, 0.025), STEEL, Vector3(0, -rad_to_deg(a), 90), 4)
		"shuriken_kesesi":
			bone = "Hips"
			at = hip + Vector3(0, 0.02, -0.13)
			for s in [-1.0, 0.0, 1.0]:
				_pouch(mb, Vector3(0.11 * s, 0, 0), Vector3(0.09, 0.1, 0.06), bc)
				for j in 4:
					mb.add("cone", Vector3(0.11 * s + cos(j * 1.57) * 0.02, 0.07, sin(j * 1.57) * 0.02 - 0.03), Vector3(0.015, 0.04, 0.004), STEEL, Vector3(0, -j * 90, -90), 3)
		"etiket_kemeri":
			bone = "Hips"
			at = hip + Vector3(0, 0.05, 0)
			mb.add("torus", Vector3.ZERO, Vector3(0.38, 0.38, 0.3), bc, Vector3(0, 0, 0), 16)
			for k in 10:
				var a = k * TAU / 10.0
				mb.add("box", Vector3(cos(a) * 0.17, -0.06, sin(a) * 0.13), Vector3(0.05, 0.11, 0.004), PAPER, Vector3(0, -rad_to_deg(a) + 90, 0))
				mb.add("box", Vector3(cos(a) * 0.172, -0.06, sin(a) * 0.132), Vector3(0.012, 0.07, 0.003), Color(0.75, 0.1, 0.1), Vector3(0, -rad_to_deg(a) + 90, 0))
		"fener":
			bone = "Hips"
			at = hip + Vector3(0.21, -0.05, -0.04)
			mb.add("cyl", Vector3(0, 0, 0), Vector3(0.11, 0.15, 0.11), Color(0.95, 0.85, 0.6), Vector3.ZERO, 10)
			for s in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0, 0.08 * s, 0), Vector3(0.09, 0.02, 0.09), DARK, Vector3.ZERO, 10)
			mb.add("box", Vector3(0, 0.0, 0.056), Vector3(0.04, 0.06, 0.004), Color(0.75, 0.15, 0.1))
			mb.add("cyl", Vector3(0, 0.13, 0), Vector3(0.008, 0.06, 0.008), DARK, Vector3.ZERO, 4)
		"ahsap_kalkan":
			mb.add("cyl", Vector3(0, 0, 0), Vector3(0.48, 0.03, 0.48), bc, Vector3(90, 0, 0), 18)
			mb.add("torus", Vector3(0, 0, -0.01), Vector3(0.5, 0.5, 0.5), STEEL.darkened(0.3), Vector3(90, 0, 0), 18)
			mb.add("sphere", Vector3(0, 0, -0.03), Vector3(0.1, 0.1, 0.05), STEEL, Vector3.ZERO, 10)
			at = ch + Vector3(0, -0.12, -0.22)
		"ikiz_fuma":
			for s in [-1.0, 1.0]:
				var c0 = Vector3(0.14 * s, 0.05 + 0.1 * s, 0)
				mb.add("cyl", c0, Vector3(0.08, 0.03, 0.08), DARK, Vector3(90, 0, 0), 8)
				for j in 4:
					var a = j * 90.0 + 45.0 * s
					mb.add("box", c0 + Vector3(cos(deg_to_rad(a)), sin(deg_to_rad(a)), 0) * 0.12, Vector3(0.2, 0.05, 0.01), STEEL, Vector3(0, 0, a))
		"shakujo":
			mb.add("cyl", Vector3(0, 0.3, 0), Vector3(0.025, 1.55, 0.025), bc, Vector3(0, 0, 22), 6)
			mb.add("torus", Vector3(-0.3, 1.0, 0), Vector3(0.18, 0.22, 0.18), Color(0.75, 0.6, 0.25), Vector3(0, 0, 22), 14)
			for k in 4:
				mb.add("torus", Vector3(-0.38 + k * 0.05, 0.92 + (k % 2) * 0.04, 0), Vector3(0.06, 0.06, 0.06), Color(0.75, 0.6, 0.25), Vector3(90, 0, 0), 8)
		"nobori":
			mb.add("cyl", Vector3(0, 0.55, 0), Vector3(0.022, 1.6, 0.022), WOOD, Vector3.ZERO, 6)
			mb.add("box", Vector3(0.09, 0.8, 0), Vector3(0.17, 1.0, 0.005), bc)
			mb.add("box", Vector3(0.09, 1.3, 0), Vector3(0.2, 0.02, 0.01), WOOD)
			for k in 3:
				mb.add("box", Vector3(0.09, 1.1 - k * 0.22, 0.004), Vector3(0.08, 0.08, 0.002), PAPER)
		"kristal_kure":
			mb.add("box", Vector3(0, 0, 0), Vector3(0.3, 0.3, 0.26), WOOD)
			mb.add("sphere", Vector3(0, 0.22, 0), Vector3(0.18, 0.18, 0.18), Color(0.7, 0.85, 1.0, 1.0), Vector3.ZERO, 14)
			mb.add("cyl", Vector3(0, 0.15, 0), Vector3(0.16, 0.03, 0.16), Color(0.6, 0.5, 0.2), Vector3.ZERO, 12)
		"ikiz_tonfa":
			bone = "Hips"
			at = hip + Vector3(0, 0.0, -0.1)
			for s in [-1.0, 1.0]:
				mb.add("box", Vector3(0.13 * s, 0, 0), Vector3(0.04, 0.45, 0.04), bc, Vector3(0, 0, 10 * s))
				mb.add("cyl", Vector3(0.13 * s + 0.04 * s, 0.12, -0.04), Vector3(0.03, 0.12, 0.03), bc.darkened(0.2), Vector3(90, 0, 0), 6)
		"tessen_bel":
			bone = "Hips"
			at = hip + Vector3(0.19, 0.04, 0.02)
			mb.add("box", Vector3.ZERO, Vector3(0.05, 0.32, 0.03), DARK, Vector3(0, 0, 8))
			for k in 4:
				mb.add("box", Vector3(0.0, -0.1 + k * 0.07, 0.016), Vector3(0.052, 0.008, 0.004), Color(0.75, 0.6, 0.25), Vector3(0, 0, 8))
		"manriki":
			bone = "Hips"
			at = hip + Vector3(-0.2, -0.02, 0)
			for k in 6:
				mb.add("torus", Vector3(0, -k * 0.012, 0), Vector3(0.14, 0.14, 0.14), Color(0.42, 0.42, 0.46), Vector3(90, k * 15, 0), 12)
			mb.add("cyl", Vector3(0, -0.11, 0), Vector3(0.04, 0.08, 0.04), STEEL, Vector3.ZERO, 6)
		"ikiz_kabak":
			bone = "Hips"
			at = hip + Vector3(0.2, 0.0, -0.05)
			for s in [0.0, 1.0]:
				mb.add("sphere", Vector3(0, -0.06 - s * 0.1, -s * 0.06), Vector3(0.12, 0.13, 0.12), bc, Vector3.ZERO, 10)
				mb.add("sphere", Vector3(0, 0.04 - s * 0.1, -s * 0.06), Vector3(0.08, 0.08, 0.08), bc, Vector3.ZERO, 10)
			mb.add("cyl", Vector3(0, 0.1, 0), Vector3(0.012, 0.12, 0.012), ROPE, Vector3.ZERO, 4)
		"furoshiki":
			mb.add("sphere", Vector3(0, 0, 0), Vector3(0.4, 0.32, 0.3), bc, Vector3.ZERO, 12)
			mb.add("sphere", Vector3(0, 0.17, 0), Vector3(0.12, 0.08, 0.1), bc.darkened(0.15), Vector3.ZERO, 8)
			for k in 6:
				mb.add("box", Vector3(-0.15 + k * 0.06, 0.0, -0.13), Vector3(0.02, 0.3, 0.005), bc.lightened(0.25))
		"harita_tupu":
			_scroll(mb, Vector3(0, 0.2, 0), 0.65, 0.05, Vector3(0, 0, -30), bc, LEATHER)
			mb.add("box", Vector3(0, 0.2, 0.05), Vector3(0.03, 0.6, 0.01), LEATHER, Vector3(0, 0, -30))
		"kus_kafesi":
			for k in 8:
				var a = k * TAU / 8.0
				mb.add("cyl", Vector3(cos(a) * 0.11, 0, sin(a) * 0.11), Vector3(0.008, 0.3, 0.008), WOOD, Vector3.ZERO, 4)
			for s in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0, 0.15 * s, 0), Vector3(0.25, 0.02, 0.25), WOOD, Vector3.ZERO, 10)
			mb.add("sphere", Vector3(0, -0.02, 0), Vector3(0.08, 0.07, 0.11), Color(0.85, 0.85, 0.9), Vector3.ZERO, 8)
			mb.add("cone", Vector3(0, -0.01, 0.065), Vector3(0.02, 0.03, 0.02), Color(0.95, 0.75, 0.2), Vector3(90, 0, 0), 4)
		"puskullu_kilic":
			mb.add("box", Vector3(0, 0.15, 0), Vector3(0.05, 0.85, 0.035), bc, Vector3(0, 0, 30))
			mb.add("cyl", Vector3(-0.25, 0.58, 0), Vector3(0.03, 0.22, 0.03), DARK, Vector3(0, 0, 30), 6)
			mb.add("cone", Vector3(-0.32, 0.65, 0), Vector3(0.06, 0.18, 0.06), Color(0.85, 0.15, 0.12), Vector3(0, 0, 180), 8)
			mb.add("sphere", Vector3(-0.31, 0.72, 0), Vector3(0.04, 0.04, 0.04), Color(0.75, 0.6, 0.25), Vector3.ZERO, 6)
		"kunai_yelpaze":
			for k in 9:
				var a = (k - 4) * 14.0
				var d = Vector3(sin(deg_to_rad(a)), cos(deg_to_rad(a)), 0)
				mb.add("cone", d * 0.28, Vector3(0.035, 0.22, 0.01), STEEL, Vector3(0, 0, -a), 4)
				mb.add("cyl", d * 0.12, Vector3(0.012, 0.1, 0.012), DARK, Vector3(0, 0, -a), 4)
			mb.add("box", Vector3(0, 0.02, 0), Vector3(0.24, 0.06, 0.03), LEATHER)
		"sirt_plakasi":
			mb.add("box", Vector3(0, 0, 0), Vector3(0.38, 0.42, 0.03), bc)
			for k in 4:
				mb.add("box", Vector3(0, -0.15 + k * 0.1, -0.017), Vector3(0.36, 0.015, 0.008), bc.darkened(0.35))
			for s in [-1.0, 1.0]:
				for j in 3:
					mb.add("sphere", Vector3(0.16 * s, -0.15 + j * 0.15, -0.018), Vector3(0.02, 0.02, 0.01), STEEL, Vector3.ZERO, 6)
			at = ch + Vector3(0, -0.12, -0.17)
		"dis_kolye":
			for k in 14:
				var a = TAU * k / 14
				var p = Vector3(sin(a) * 0.15, 0.06 + 0.11 * cos(a) * (1.0 if cos(a) > 0.0 else 0.0), cos(a) * 0.13 + 0.01)
				mb.add("cone", p, Vector3(0.022, 0.06, 0.016), Color(0.95, 0.92, 0.82), Vector3(180, 0, 0), 4)
			at = ch + Vector3(0, -0.02, 0.0)
		"can_kemeri":
			bone = "Hips"
			at = hip + Vector3(0, 0.05, 0)
			mb.add("torus", Vector3.ZERO, Vector3(0.38, 0.38, 0.3), bc, Vector3.ZERO, 16)
			for k in 6:
				var a = PI + (k - 2.5) * 0.4
				mb.add("sphere", Vector3(cos(a) * 0.17, -0.05, sin(a) * 0.13), Vector3(0.035, 0.035, 0.035), Color(0.85, 0.7, 0.25), Vector3.ZERO, 8)
		"ikiz_kama":
			bone = "Hips"
			at = hip + Vector3(0, 0.0, -0.12)
			for s in [-1.0, 1.0]:
				mb.add("cyl", Vector3(0.12 * s, 0, 0), Vector3(0.025, 0.25, 0.025), WOOD, Vector3(0, 0, 25 * s), 6)
				mb.add("box", Vector3(0.12 * s + 0.08 * s, 0.1, 0), Vector3(0.14, 0.03, 0.008), STEEL, Vector3(0, 0, -15 * s))
		"sadak":
			mb.add("cyl", Vector3(0, 0.05, 0), Vector3(0.13, 0.6, 0.13), bc, Vector3(0, 0, -15), 10)
			for k in 6:
				mb.add("cyl", Vector3(0.08 + (k % 3) * 0.025, 0.42, (k / 3) * 0.03 - 0.015), Vector3(0.01, 0.3, 0.01), WOOD, Vector3(0, 0, -15), 4)
				mb.add("cone", Vector3(0.12 + (k % 3) * 0.025, 0.58, (k / 3) * 0.03 - 0.015), Vector3(0.03, 0.06, 0.006), Color(0.9, 0.2, 0.15), Vector3(0, 0, -15), 3)
		"savas_cekici":
			mb.add("cyl", Vector3(0, 0.1, 0), Vector3(0.04, 0.95, 0.04), WOOD, Vector3(0, 0, 20), 8)
			mb.add("cyl", Vector3(-0.16, 0.55, 0), Vector3(0.16, 0.3, 0.16), DARK, Vector3(0, 0, 110), 10)
			for s in [-1.0, 1.0]:
				mb.add("cyl", Vector3(-0.16 + 0.14 * s, 0.55 + 0.05 * s, 0), Vector3(0.17, 0.02, 0.17), STEEL, Vector3(0, 0, 110), 10)
		"tilki_maske_bel":
			bone = "Hips"
			at = hip + Vector3(0.2, -0.02, 0.03)
			mb.add("sphere", Vector3.ZERO, Vector3(0.16, 0.19, 0.06), Color(0.96, 0.95, 0.92), Vector3.ZERO, 10)
			for s in [-1.0, 1.0]:
				mb.add("cone", Vector3(0.05 * s, 0.1, 0), Vector3(0.04, 0.07, 0.02), Color(0.96, 0.95, 0.92), Vector3(0, 0, -20 * s), 4)
				mb.add("box", Vector3(0.035 * s, 0.02, 0.03), Vector3(0.04, 0.008, 0.003), Color(0.8, 0.1, 0.1), Vector3(0, 0, 20 * s))
			mb.add("cone", Vector3(0, -0.04, 0.035), Vector3(0.03, 0.06, 0.02), Color(0.96, 0.95, 0.92), Vector3(90, 0, 0), 4)
		"murekkep_kutusu":
			bone = "Hips"
			at = hip + Vector3(-0.19, 0.0, -0.03)
			mb.add("box", Vector3.ZERO, Vector3(0.08, 0.14, 0.06), bc)
			for k in 3:
				mb.add("cyl", Vector3(-0.02 + k * 0.02, 0.12, 0), Vector3(0.012, 0.12, 0.012), WOOD, Vector3.ZERO, 4)
				mb.add("cone", Vector3(-0.02 + k * 0.02, 0.19, 0), Vector3(0.016, 0.03, 0.016), DARK, Vector3.ZERO, 4)
		"chakra_bicaklari":
			bone = "Hips"
			at = hip + Vector3(0, 0.0, -0.11)
			for s in [-1.0, 1.0]:
				mb.add("box", Vector3(0.12 * s, 0.0, 0), Vector3(0.06, 0.18, 0.02), LEATHER)
				mb.add("torus", Vector3(0.12 * s, 0.12, 0.0), Vector3(0.06, 0.06, 0.06), STEEL, Vector3(90, 0, 0), 8)
				mb.add("cone", Vector3(0.12 * s, -0.12, 0), Vector3(0.04, 0.1, 0.01), STEEL, Vector3(180, 0, 0), 4)
		"zincir_bel":
			bone = "Hips"
			at = hip + Vector3(0, 0.02, 0)
			for k in 18:
				var a = k * TAU / 18.0
				mb.add("torus", Vector3(cos(a) * 0.18, sin(k * 1.3) * 0.02, sin(a) * 0.14), Vector3(0.05, 0.05, 0.035), Color(0.45, 0.45, 0.5), Vector3((k % 2) * 90.0, -rad_to_deg(a), 0), 8)
		"bambu_matara":
			bone = "Hips"
			at = hip + Vector3(0.2, 0.0, -0.06)
			mb.add("cyl", Vector3.ZERO, Vector3(0.07, 0.3, 0.07), Color(0.55, 0.65, 0.3), Vector3.ZERO, 10)
			for s in [-1.0, 0.0, 1.0]:
				mb.add("cyl", Vector3(0, 0.1 * s, 0), Vector3(0.075, 0.015, 0.075), Color(0.45, 0.52, 0.22), Vector3.ZERO, 10)
			mb.add("cyl", Vector3(0, 0.17, 0), Vector3(0.03, 0.04, 0.03), WOOD, Vector3.ZERO, 6)
		_:
			return false
	m._mesh_on(bone, mb.build(toon), Transform3D(Basis.IDENTITY, at))
	return true
