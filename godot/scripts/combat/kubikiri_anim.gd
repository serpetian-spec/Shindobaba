extends RefCounted
## Kubikiribōchō kombosu (Zabuza tarzı): dev satır, tek elle omuzdan; ağır silah ritmi — omuzdan kalkış -> uzun bekleme ->
## tüm gövdeyle tek ağır kesik -> ağız bedeni sürükler -> omza geri. Yaratıcı kanon hareketleri: kafa kesme yatay biçmesi,
## kılıcı fırlatıp ağaç/yere saplama, kılıcın üstünden atlayıp tekme (Zabuza'nın kılıcı dayanak yapması), dönerek çift biçme.
## 1 omuzdan çapraz iniş, 2 yatay boyun biçmesi (kubikiri), 3 alttan yükselen biçme, 4 dönen çift biçme,
## 5 kılıcı dayanak yapıp tekme, 6 Kubikiri Nage (bitiriş): baş üstünden dev iniş, yere saplanır, şok dalgası.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_REST := {"RightUpperArm": Vector3(-0.45, -0.6, 0.66), "RightLowerArm": Vector3(0.25, 0.75, 0.6)}        # omuzda
const R_HIGH := {"RightUpperArm": Vector3(-0.45, 0.85, -0.3), "RightLowerArm": Vector3(-0.15, 0.9, -0.4)}       # baş üstü-arkası
const R_DOWN := {"RightUpperArm": Vector3(0.2, -0.4, 0.9), "RightLowerArm": Vector3(0.5, -0.55, 0.65)}         # sol kalçaya inmiş (çapraz)
const R_BACK_R := {"RightUpperArm": Vector3(-0.95, 0.2, -0.25), "RightLowerArm": Vector3(-0.7, 0.4, -0.55)}    # sağ-arkaya açık (yatay kurulum)
const R_ACROSS := {"RightUpperArm": Vector3(0.45, 0.15, 0.88), "RightLowerArm": Vector3(0.95, 0.2, 0.2)}       # sola savrulmuş (boyun hizası)
const R_LOWBACK := {"RightUpperArm": Vector3(-0.35, -0.9, -0.25), "RightLowerArm": Vector3(-0.15, -0.75, 0.6)}
const R_UP := {"RightUpperArm": Vector3(-0.1, 0.75, 0.65), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}
const R_WIDE := {"RightUpperArm": Vector3(-0.98, 0.0, 0.15), "RightLowerArm": Vector3(-0.95, 0.05, 0.3)}
const R_PLANT := {"RightUpperArm": Vector3(-0.15, -0.6, 0.78), "RightLowerArm": Vector3(0.0, -0.9, 0.4)}       # kılıç önde yere saplı (dayanak)
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.8, 0.5), "LeftLowerArm": Vector3(-0.1, -0.1, 0.99)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}
const L_BACK := {"LeftUpperArm": Vector3(0.5, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_SEAL := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(-0.6, 0.45, 0.66)}           # tek el mühür (Zabuza)
const KICK := {"RightUpperLeg": Vector3(-0.1, 0.1, 0.99), "RightLowerLeg": Vector3(-0.05, 0.05, 1), "RightFoot": Vector3(0, 0.6, 0.8)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.5, lean * 1.4, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	var RST = Vector3(-0.12, 0.42, -0.9)   # omuzda: ağız geriye-yukarı
	return [
		# 1 Kesa Giri: omuzdan baş üstüne kalkar (bekle) -> sağ omuzdan sol kalçaya çapraz ağır iniş, gövde öne çöker
		{"len": 1.0, "hit": 0.46, "keys": [
			_t(0.0, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
			_t(0.2, 0.4, -14, -14, Vector3(-0.2, 0.7, -0.7), R_HIGH, L_POINT, BK),
			_t(0.38, 0.42, -16, -16, Vector3(-0.2, 0.7, -0.7), R_HIGH, L_POINT, BK),
			_t(0.46, 0.56, 22, 26, Vector3(0.5, -0.6, 0.6), R_DOWN, L_BACK, L),
			_t(0.66, 0.58, 26, 24, Vector3(0.55, -0.7, 0.45), R_DOWN, L_BACK, L),
			_t(1.0, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
		]},
		# 2 Kubikiri: ağız sağ-arkaya yatay açılır, gövde iyice burulur -> boyun hizasında geniş yatay biçme
		{"len": 1.05, "hit": 0.48, "keys": [
			_t(0.0, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
			_t(0.22, 0.44, -40, -6, Vector3(-0.8, 0.3, -0.5), R_BACK_R, L_POINT, BK),
			_t(0.4, 0.46, -44, -8, Vector3(-0.8, 0.3, -0.5), R_BACK_R, L_POINT, BK),
			_t(0.48, 0.46, 10, 12, Vector3(-0.2, 0.2, 0.96), R_WIDE, L_BACK, ST),
			_t(0.58, 0.48, 40, 16, Vector3(0.9, 0.2, 0.35), R_ACROSS, L_BACK, L),
			_t(0.78, 0.46, 48, 14, Vector3(0.9, 0.1, 0.3), R_ACROSS, L_BACK, L),
			_t(1.05, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
		]},
		# 3 Kiri Age: ağız yerde geride (çömel) -> alttan öne-yukarı yükselen biçme, rakip havaya kalkar
		{"len": 0.95, "hit": 0.44, "keys": [
			_t(0.0, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
			_t(0.2, 0.7, -22, 20, Vector3(0, -0.7, -0.7), R_LOWBACK, L_POINT, BK),
			_t(0.36, 0.72, -24, 22, Vector3(0, -0.7, -0.7), R_LOWBACK, L_POINT, BK),
			_t(0.44, 0.26, 8, -14, Vector3(0, 0.9, 0.4), R_UP, L_BACK, L),
			_t(0.62, 0.24, 6, -16, Vector3(0, 0.95, 0.25), R_UP, L_BACK, L),
			_t(0.95, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
		]},
		# 4 Kaiten Giri: ağız yana açık, gövde tam tur döner (iki ağır yatay biçme)
		{"len": 1.2, "hit": 0.36, "extra_hits": [0.7], "extra_radius": 2.8, "keys": [
			_t(0.0, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
			_t(0.18, 0.46, -30, 4, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_GUARD, BK),
			_t(0.36, 0.48, 70, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_GUARD, CR),
			_t(0.56, 0.48, 180, 8, Vector3(-0.9, 0.1, 0.3), R_WIDE, L_GUARD, W),
			_t(0.72, 0.48, 40, 10, Vector3(0.9, 0.1, 0.3), R_ACROSS, L_GUARD, L),
			_t(1.2, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
		]},
		# 5 Tsuka Geri: kılıcı önüne saplar (dayanak), kabzaya asılıp gövdesini kaldırır -> çift ayakla tekme, sonra çekip omza
		{"len": 1.05, "hit": 0.5, "keys": [
			_t(0.0, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
			_t(0.2, 0.5, 0, 20, Vector3(0, -0.95, 0.3), R_PLANT, L_SEAL, L),
			_t(0.36, 0.3, 0, -10, Vector3(0, -0.95, 0.3), R_PLANT, L_SEAL, W),
			_t(0.5, 0.2, 0, -26, Vector3(0, -0.95, 0.3), R_PLANT, L_BACK, KICK),
			_t(0.68, 0.24, 0, -20, Vector3(0, -0.95, 0.3), R_PLANT, L_BACK, KICK),
			_t(0.82, 0.4, 0, 8, Vector3(0, -0.9, 0.4), R_PLANT, L_GUARD, W),
			_t(1.05, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
		]},
		# 6 Kubikiri Nage (bitiriş): sıçrar, havada baş üstünde iki tur döndürür -> dev iniş, ağız yere saplanır, şok dalgası
		# 6 Kirigakure Kubikiri (bitiriş, Zabuza): tek el mühür -> sis yayılır, sisin içinde kaybolur, rakibin ARKASINDA belirir
		#   (KeyedCombos) -> omuzdan sağ-arkaya açılıp boyun hizasında tek ağır yatay biçme
		{"len": 1.5, "hit": 0.92, "keys": [
			_t(0.0, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
			_t(0.16, 0.36, 0, -2, RST, R_REST, L_SEAL, W),
			_t(0.5, 0.38, 0, -4, RST, R_REST, L_SEAL, W),
			_t(0.66, 0.46, -44, -6, Vector3(-0.8, 0.3, -0.5), R_BACK_R, L_POINT, BK),
			_t(0.86, 0.48, -50, -8, Vector3(-0.8, 0.3, -0.5), R_BACK_R, L_POINT, BK),
			_t(0.92, 0.5, 30, 14, Vector3(0.9, 0.2, 0.35), R_ACROSS, L_BACK, L),
			_t(1.12, 0.48, 50, 14, Vector3(0.9, 0.1, 0.3), R_ACROSS, L_BACK, L),
			_t(1.5, 0.36, 0, 4, RST, R_REST, L_GUARD, W),
		]},
	]
