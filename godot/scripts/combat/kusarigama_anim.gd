extends RefCounted
## Hanzō tipi kusarigama (sickle.png): uzun saplı orak + sap dibinden zincir + çan ağırlık. ORTA MENZİL silahı:
## orak uzun sapla kancalar ve çeker, ağırlık zincirle düz fırlatılır, baş üstünde döndürülüp geniş çember çizer,
## orak zincirle fırlatılıp hedefin arkasından kancalanır ve geri çekilir; bitiriş: zincir hedefe dolanır, çekilir, dev orak biçmesi.
## Zincir/ağırlık/uçan orak etkileri KeyedCombos (oyuncu + düşman aynı). Her adımda geri çekiş + ayak işi (BK -> ST -> L).

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_READY := {"RightUpperArm": Vector3(-0.25, -0.88, 0.4), "RightLowerArm": Vector3(0.15, -0.1, 0.98)}
const R_HIGH := {"RightUpperArm": Vector3(-0.5, 0.65, -0.55), "RightLowerArm": Vector3(-0.1, 0.9, 0.4)}        # sağ omzun üstü-arkası
const R_OVER := {"RightUpperArm": Vector3(-0.2, 0.95, 0.1), "RightLowerArm": Vector3(0.1, 0.95, 0.25)}         # baş üstünde (döndürme)
const R_REACH := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}             # kol öne uzanmış
const R_PULL := {"RightUpperArm": Vector3(-0.35, -0.75, -0.55), "RightLowerArm": Vector3(-0.05, 0.1, 1)}       # yumruk kalçaya çekilmiş
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const R_LOWEND := {"RightUpperArm": Vector3(0.25, -0.5, 0.82), "RightLowerArm": Vector3(0.85, -0.3, 0.4)}      # sol kalçaya inmiş
const R_LEFT := {"RightUpperArm": Vector3(0.2, -0.3, 0.93), "RightLowerArm": Vector3(0.9, 0.1, 0.4)}
const R_WIDE := {"RightUpperArm": Vector3(-0.95, -0.05, 0.3), "RightLowerArm": Vector3(-0.85, -0.1, 0.5)}      # sağa yatay açık
const R_UP := {"RightUpperArm": Vector3(-0.15, 0.7, 0.7), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_HAUL := {"LeftUpperArm": Vector3(0.35, -0.7, -0.6), "LeftLowerArm": Vector3(-0.1, 0.0, 1)}             # zinciri yakalayıp kalçaya çeker
const L_WIDE := {"LeftUpperArm": Vector3(0.95, -0.2, 0.2), "LeftLowerArm": Vector3(0.85, -0.2, 0.45)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RDY = Vector3(-0.15, 0.55, 0.82)   # sap önde yukarı: orak başın önünde yukarıda, zincir dipten sarkar
	return [
		# 1 Kama Gari: orak sağ omzun üstüne-arkaya kalkar, ağırlık geride (bekle) -> büyük adımla uzun sap öne iner, orak hedefin
		#   arkasına kancalanır -> sap kalçaya çekilip rakip öne sürüklenir (pull)
		{"len": 0.85, "hit": 0.42, "keys": [
			_t(0.0, 0.34, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.15, 0.4, -24, -10, Vector3(-0.2, 0.8, -0.56), R_HIGH, L_POINT, BK),
			_t(0.3, 0.42, -27, -12, Vector3(-0.2, 0.78, -0.6), R_HIGH, L_POINT, BK),
			_t(0.36, 0.4, -10, 4, Vector3(-0.1, 0.6, 0.5), R_HIGH, L_POINT, ST),
			_t(0.42, 0.52, 12, 22, Vector3(-0.05, -0.15, 0.98), R_REACH, L_BACK, L),
			_t(0.6, 0.46, -4, -8, Vector3(-0.1, 0.3, 0.95), R_PULL, L_HAUL, BK),
			_t(0.85, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 2 Fundō Uchi: sap aşağı-geriye savrulur (zincir arkada sarkar) -> sap öne-yukarı kırbaçlanır, ağırlık düz hedefe uçar ve zincir
		#   gövdesine dolanıp sersemletir; kullanıcı zinciri gergin tutup geri yaslanır -> çözülür, ağırlık döner
		{"len": 1.3, "hit": 0.3, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.44, -20, -8, Vector3(-0.3, -0.5, -0.8), R_LOW, L_POINT, BK),
			_t(0.22, 0.45, -22, -9, Vector3(-0.3, -0.45, -0.84), R_LOW, L_POINT, BK),
			_t(0.3, 0.42, 14, 16, Vector3(0.0, 0.7, 0.7), R_REACH, L_BACK, L),
			_t(0.5, 0.44, 4, -6, Vector3(0.0, 0.65, 0.75), R_PULL, L_HAUL, BK),   # zincir dolandı: gergin tutar, geri yaslanır
			_t(0.9, 0.44, 2, -8, Vector3(0.0, 0.65, 0.75), R_PULL, L_HAUL, BK),
			_t(1.08, 0.4, 4, 2, Vector3(-0.1, 0.6, 0.78), R_READY, L_GUARD, ST),
			_t(1.3, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 3 Kusari Senpū: orak başın üstüne kalkar, ağırlık baş üstünde döner (gövde dönüşle burulur) -> kol yana açılır, ağırlık
		#   gövdenin çevresinde geniş çember çizer (çoklu vuruş)
		{"len": 1.3, "hit": 0.22, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.4, -18, -6, Vector3(0.0, 0.95, 0.2), R_OVER, L_WIDE, W),
			_t(0.34, 0.42, 22, 0, Vector3(0.1, 0.95, 0.1), R_OVER, L_WIDE, CR),
			_t(0.5, 0.44, -24, 4, Vector3(-0.4, 0.6, 0.6), R_WIDE, L_WIDE, W),
			_t(0.72, 0.46, 30, 6, Vector3(-0.5, 0.5, 0.7), R_WIDE, L_WIDE, CR),
			_t(0.94, 0.46, -30, 6, Vector3(-0.5, 0.5, 0.7), R_WIDE, L_WIDE, W),
			_t(1.08, 0.42, 10, 4, Vector3(-0.2, 0.6, 0.75), R_READY, L_GUARD, ST),
			_t(1.3, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 4 Kama Nage: orak başın üstünden geriye kurulur (uzun bekleme) -> fırlatılır (el boş, kol uzanmış), zincirle hedefin arkasından
		#   kancalanır -> sol el zinciri yakalar, iki kolla kalçaya çekilir (rakip sürüklenir) -> orak ele döner
		{"len": 1.15, "hit": 0.34, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.16, 0.4, -30, -12, Vector3(-0.3, 0.75, -0.6), R_HIGH, L_POINT, BK),
			_t(0.28, 0.42, -34, -14, Vector3(-0.3, 0.72, -0.63), R_HIGH, L_POINT, BK),
			_t(0.34, 0.46, 16, 20, Vector3(0.0, 0.3, 0.95), R_REACH, L_POINT, L),
			_t(0.62, 0.44, 12, 16, Vector3(0.0, 0.3, 0.95), R_REACH, L_POINT, L),
			_t(0.72, 0.46, -10, -14, Vector3(0.0, 0.3, 0.95), R_PULL, L_HAUL, BK),
			_t(0.9, 0.44, -14, -16, Vector3(0.0, 0.3, 0.95), R_PULL, L_HAUL, BK),
			_t(1.15, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 5 Ashi Gari -> Kachiage: çömelip uzun sapla bacakları süpürür (alçak sağdan sola) -> sol altta toplanır -> orak alttan yukarı
		#   kancalayıp havaya kaldırır (launch)
		{"len": 0.8, "hit": 0.44, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.12, 0.66, -22, 16, Vector3(-0.6, -0.45, 0.65), R_LOW, L_BACK, W),
			_t(0.24, 0.68, 22, 18, Vector3(0.65, -0.45, 0.6), R_LEFT, L_BACK, LL),
			_t(0.34, 0.68, 24, 18, Vector3(0.6, -0.5, 0.62), R_LOWEND, L_BACK, LL),
			_t(0.44, 0.28, 0, -10, Vector3(0.05, 0.95, 0.3), R_UP, L_POINT, L),
			_t(0.8, 0.36, 2, 4, RDY, R_READY, L_GUARD, W),
		]},
		# 6 Shinigami Gari (bitiriş): ağırlık fırlatılıp hedefe dolanır (on_start), sol el zinciri kalçaya çeker (rakip sürüklenir) ->
		#   orak başın üstünden sağ-arkaya kurulur (uzun duraksama) -> çapraz aşağı dev biçme, gövde öne çöker -> ağırlıkla devam
		{"len": 1.35, "hit": 0.8, "keys": [
			_t(0.0, 0.36, 0, 4, RDY, R_READY, L_GUARD, W),
			_t(0.14, 0.4, 10, 10, Vector3(0.0, 0.6, 0.8), R_REACH, L_POINT, L),
			_t(0.3, 0.44, -10, -14, Vector3(-0.1, 0.6, 0.78), R_PULL, L_HAUL, BK),
			_t(0.46, 0.44, -12, -15, Vector3(-0.1, 0.6, 0.78), R_PULL, L_HAUL, BK),
			_t(0.6, 0.42, -36, -14, Vector3(-0.3, 0.8, -0.52), R_HIGH, L_POINT, BK),
			_t(0.72, 0.43, -40, -16, Vector3(-0.3, 0.78, -0.55), R_HIGH, L_POINT, BK),
			_t(0.75, 0.42, -20, 0, Vector3(-0.1, 0.7, 0.4), R_HIGH, L_POINT, ST),
			_t(0.8, 0.6, 24, 26, Vector3(0.4, -0.55, 0.73), R_LOWEND, L_BACK, L),
			_t(0.98, 0.62, 30, 24, Vector3(0.7, -0.6, 0.3), R_LOWEND, L_BACK, L),
			_t(1.35, 0.36, 4, 4, RDY, R_READY, L_GUARD, W),
		]},
	]
