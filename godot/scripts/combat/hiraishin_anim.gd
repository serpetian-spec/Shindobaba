extends RefCounted
## Hiraishin Kunai (raijinbaba.png, Minato): tek el, hafif ve çok hızlı. Kanon: kunai/isabet hedefe Hiraishin işareti (shiki) koyar;
## Hiraishin no Jutsu ile işaretin yanında sarı flaşla belirir. Kombo: kesik + işaretleme, sonra ışınlanıp arkadan vuruşlar
## (ışınlanma KeyedCombos.on_start "blink"; adım başında hedefin arkasında belirir). Ayak işi + belirgin geri çekiş her vuruşta.

const S = preload("res://scripts/combat/samehada_anim.gd")

const R_REV := {"RightUpperArm": Vector3(-0.35, -0.8, 0.45), "RightLowerArm": Vector3(0.15, -0.1, 0.98)}       # bel önü hazır
const R_COCK := {"RightUpperArm": Vector3(-0.6, 0.2, -0.75), "RightLowerArm": Vector3(-0.2, 0.75, 0.6)}       # kulak arkası kurulu
const R_SLASH_END := {"RightUpperArm": Vector3(0.25, -0.5, 0.82), "RightLowerArm": Vector3(0.85, -0.3, 0.4)}  # sol kalçaya inmiş
const R_STAB := {"RightUpperArm": Vector3(-0.05, -0.05, 1), "RightLowerArm": Vector3(0.0, -0.03, 1)}
const R_CHAMBER := {"RightUpperArm": Vector3(-0.3, -0.6, -0.75), "RightLowerArm": Vector3(-0.05, -0.05, 1)}
const R_LOW := {"RightUpperArm": Vector3(-0.35, -0.9, 0.2), "RightLowerArm": Vector3(-0.1, -0.6, 0.8)}
const R_UP := {"RightUpperArm": Vector3(-0.2, 0.6, 0.78), "RightLowerArm": Vector3(0.0, 0.9, 0.4)}
const R_WIDE := {"RightUpperArm": Vector3(-0.95, -0.1, 0.3), "RightLowerArm": Vector3(-0.85, -0.2, 0.5)}
const L_SEAL := {"LeftUpperArm": Vector3(0.25, -0.6, 0.75), "LeftLowerArm": Vector3(-0.6, 0.65, 0.45)}      # sol el göğüs önünde tek el mühür
const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.75, 0.55), "LeftLowerArm": Vector3(-0.2, 0.3, 0.93)}
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(t, crouch, yaw * 1.4, lean * 1.3, blade.normalized(), S._a(r, l), legs)


static func steps() -> Array:
	var W = S.LEG_WIDE
	var L = S.LEG_LUNGE
	var LL = S.mirror(S.LEG_LUNGE)
	var BK = S.LEG_BACK
	var ST = S.LEG_STEP
	var CR = S.LEG_CROSS
	return [
		# 1 Işık Kesiği: kunai kulak arkasına kurulur (ağırlık geride) -> adımla çapraz aşağı keser (işaret bırakır)
		{"len": 0.5, "hit": 0.24, "keys": [
			_t(0.0, 0.36, 0, 4, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
			_t(0.1, 0.4, -24, -8, Vector3(-0.3, 0.85, -0.4), R_COCK, L_POINT, BK),
			_t(0.17, 0.41, -26, -9, Vector3(-0.3, 0.85, -0.42), R_COCK, L_POINT, BK),
			_t(0.21, 0.4, -8, 4, Vector3(-0.1, 0.4, 0.9), R_COCK, L_POINT, ST),
			_t(0.24, 0.48, 18, 18, Vector3(0.55, -0.55, 0.62), R_SLASH_END, L_BACK, L),
			_t(0.5, 0.38, 4, 6, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
		]},
		# 2 İşaret Saplaması: hazneye geri çekip düz saplar (hedef işaretlenir)
		{"len": 0.5, "hit": 0.26, "keys": [
			_t(0.0, 0.38, 4, 6, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
			_t(0.12, 0.42, -24, -8, Vector3(0, -0.02, 1), R_CHAMBER, L_POINT, BK),
			_t(0.19, 0.43, -25, -9, Vector3(0, -0.02, 1), R_CHAMBER, L_POINT, BK),
			_t(0.26, 0.5, 18, 20, Vector3(0, -0.03, 1), R_STAB, L_BACK, L),
			_t(0.5, 0.38, 4, 6, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
		]},
		# 3 Arkadan Hiraishin: tek el mühür -> sarı flaş, hedefin ARKASINDA belirir (adım başında) -> sırtına yatay kesik
		{"len": 0.6, "hit": 0.3, "keys": [
			_t(0.0, 0.4, 0, 2, Vector3(0.2, -0.2, 0.96), R_REV, L_SEAL, W),
			_t(0.08, 0.5, 10, 10, Vector3(0.9, 0.05, -0.4), R_SLASH_END, L_SEAL, CR),
			_t(0.2, 0.5, 30, 6, Vector3(0.9, 0.05, -0.42), R_SLASH_END, L_BACK, CR),
			_t(0.24, 0.46, 10, 10, Vector3(0.6, 0.05, 0.8), R_SLASH_END, L_BACK, ST),
			_t(0.3, 0.5, -26, 18, Vector3(-0.95, 0.0, 0.3), R_WIDE, L_POINT, LL),
			_t(0.6, 0.38, -6, 6, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
		]},
		# 4 Yükselen Kesik: alçakta çömelip kurulur -> yukarı biçer (havaya)
		{"len": 0.55, "hit": 0.28, "keys": [
			_t(0.0, 0.38, -6, 6, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
			_t(0.14, 0.68, -16, 20, Vector3(-0.3, -0.85, 0.4), R_LOW, L_BACK, W),
			_t(0.22, 0.7, -17, 21, Vector3(-0.3, -0.85, 0.42), R_LOW, L_BACK, W),
			_t(0.28, 0.28, 10, -10, Vector3(0.1, 0.9, 0.4), R_UP, L_POINT, L),
			_t(0.55, 0.38, 2, 4, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
		]},
		# 5 Çifte Flaş: havadaki hedefin yanında belirir (flaş) -> iki hızlı çapraz kesik
		{"len": 0.62, "hit": 0.22, "extra_hits": [0.38], "extra_radius": 2.2, "keys": [
			_t(0.0, 0.38, 2, 4, Vector3(0.2, -0.2, 0.96), R_REV, L_SEAL, W),
			_t(0.08, 0.4, -20, -6, Vector3(-0.3, 0.85, -0.4), R_COCK, L_SEAL, BK),
			_t(0.22, 0.46, 16, 16, Vector3(0.55, -0.55, 0.62), R_SLASH_END, L_BACK, L),
			_t(0.3, 0.42, 16, 4, Vector3(0.6, 0.75, -0.2), R_UP, L_BACK, L),
			_t(0.38, 0.48, -16, 16, Vector3(-0.55, -0.6, 0.6), R_WIDE, L_POINT, LL),
			_t(0.62, 0.38, -4, 6, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
		]},
		# 6 Hiraishin Giri (bitiriş): mühür, kunai geride; hedefin çevresinde üç flaşla belirip keser (on_strike) -> sonda önüne
		# döner, derin saplama
		{"len": 1.0, "hit": 0.66, "keys": [
			_t(0.0, 0.38, 0, 4, Vector3(0.2, -0.2, 0.96), R_REV, L_SEAL, W),
			_t(0.2, 0.44, -20, -10, Vector3(0, -0.02, 1), R_CHAMBER, L_SEAL, BK),
			_t(0.36, 0.46, -22, -12, Vector3(0, -0.02, 1), R_CHAMBER, L_SEAL, BK),
			_t(0.42, 0.5, 20, 18, Vector3(0.55, -0.55, 0.62), R_SLASH_END, L_BACK, L),
			_t(0.5, 0.5, -20, 18, Vector3(-0.95, 0.0, 0.3), R_WIDE, L_POINT, LL),
			_t(0.58, 0.45, -24, -6, Vector3(0, -0.02, 1), R_CHAMBER, L_POINT, BK),
			_t(0.66, 0.62, 16, 28, Vector3(0, -0.03, 1), R_STAB, L_BACK, L),
			_t(1.0, 0.4, 0, 6, Vector3(0.2, -0.2, 0.96), R_REV, L_GUARD, W),
		]},
	]
