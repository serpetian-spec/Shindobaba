class_name KunaiAnim
## Düz kunai kombosu, 6 vuruş (kaynak yok — _tmp/ed/kunai_desc.md kendime anlatımı v2).
## Hafif silah: kısa geri çekme (0.06–0.1 sn) -> çok hızlı vuruş -> kısa devam; vuruşlar birbirine akar.
## Tutuş değişimi: 1-2 düz tutuş, 3-5 ters tutuş (bıçak ön kol boyunca geriye), 6 tekrar düz.

const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.92, 0.25), "LeftLowerArm": Vector3(0.0, -0.15, 1.0)}    # alçak doğal gard: ön kol bel hizasında öne (havada yüz önünde değil)
const L_REACH := {"LeftUpperArm": Vector3(0.2, -0.3, 0.93), "LeftLowerArm": Vector3(0.05, -0.1, 1)}       # mesafe için öne
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.55), "LeftLowerArm": Vector3(0.3, -0.6, -0.75)}
const L_SUPPORT := {"LeftUpperArm": Vector3(0.3, -0.85, 0.42), "LeftLowerArm": Vector3(-0.2, -0.3, 0.93)}      # çekiçte sol el aşağıda dengede

const R_READY := {"RightUpperArm": Vector3(-0.25, -0.9, 0.35), "RightLowerArm": Vector3(-0.1, -0.15, 1)}
const R_COCK := {"RightUpperArm": Vector3(-0.3, -0.95, -0.1), "RightLowerArm": Vector3(-0.15, -0.3, 0.94)}    # bilek geri, kalça yanında
const R_JAB := {"RightUpperArm": Vector3(-0.08, -0.25, 1), "RightLowerArm": Vector3(0.0, -0.15, 1)}
const R_OPEN := {"RightUpperArm": Vector3(-0.8, -0.4, 0.45), "RightLowerArm": Vector3(-0.85, 0.0, 0.5)}      # sağa açık
const R_LCHEST := {"RightUpperArm": Vector3(0.25, -0.5, 0.83), "RightLowerArm": Vector3(0.9, 0.1, 0.4)}
const R_LHIP := {"RightUpperArm": Vector3(0.25, -0.9, 0.35), "RightLowerArm": Vector3(0.75, -0.55, 0.35)}
const R_RSHOULDER := {"RightUpperArm": Vector3(-0.6, 0.35, 0.72), "RightLowerArm": Vector3(-0.45, 0.6, 0.65)}
const R_RLOW := {"RightUpperArm": Vector3(-0.7, -0.7, 0.2), "RightLowerArm": Vector3(-0.6, -0.6, 0.5)}       # sağ diz yanı
const R_LLOW := {"RightUpperArm": Vector3(0.2, -0.85, 0.5), "RightLowerArm": Vector3(0.8, -0.5, 0.35)}       # sol diz önü
const R_HAMMER := {"RightUpperArm": Vector3(-0.3, 0.9, 0.3), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}       # yumruk başın üstünde
const R_HAMMER_DN := {"RightUpperArm": Vector3(-0.1, -0.5, 0.86), "RightLowerArm": Vector3(0.0, -0.75, 0.66)}
const R_LHIGH := {"RightUpperArm": Vector3(0.1, 0.6, 0.8), "RightLowerArm": Vector3(0.6, 0.75, 0.25)}        # sol omuz üstü
const R_RHIGH := {"RightUpperArm": Vector3(-0.55, 0.6, 0.6), "RightLowerArm": Vector3(-0.4, 0.85, 0.35)}     # sağ omuz üstü


static func _k(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return SamehadaAnim._k(t, crouch, yaw, lean, blade, SamehadaAnim._a(r, l), legs)


static func steps() -> Array:
	var W = SamehadaAnim.LEG_WIDE
	var L = SamehadaAnim.LEG_LUNGE
	return [
		# 1: hızlı saplama
		{"len": 0.32, "hit": 0.12, "keys": [
			_k(0.0, 0.5, -8, 10, Vector3(0.0, 0.15, 1.0), R_READY, L_GUARD, W),
			_k(0.07, 0.5, -15, 6, Vector3(0.0, 0.1, 1.0), R_COCK, L_GUARD, W),
			_k(0.12, 0.6, 12, 20, Vector3(0.0, -0.05, 1.0), R_JAB, L_GUARD, L),
			_k(0.32, 0.55, 8, 15, Vector3(0.0, 0.05, 1.0), R_READY, L_GUARD, L),
		]},
		# 2: içeri kesiş sağdan sola (saplamanın dönüşünden açılır)
		{"len": 0.34, "hit": 0.13, "keys": [
			_k(0.0, 0.55, 8, 15, Vector3(0.0, 0.05, 1.0), R_READY, L_GUARD, L),
			_k(0.08, 0.5, -25, 8, Vector3(-0.9, 0.15, 0.4), R_OPEN, L_GUARD, W),
			_k(0.13, 0.55, 5, 15, Vector3(0.05, 0.1, 1.0), R_JAB, L_GUARD, L),
			_k(0.19, 0.55, 28, 14, Vector3(0.9, 0.05, 0.3), R_LCHEST, L_GUARD, L),
			_k(0.34, 0.5, 25, 10, Vector3(0.85, 0.05, 0.4), R_LCHEST, L_GUARD, L),
		]},
		# 3: tutuş çevirme (kunai ters döner) + ters tutuşla sol kalçadan sağ omza yükselen kesiş
		{"len": 0.38, "hit": 0.16, "keys": [
			_k(0.0, 0.5, 25, 10, Vector3(0.85, 0.05, 0.4), R_LCHEST, L_GUARD, L),
			_k(0.06, 0.55, 30, 12, Vector3(-0.3, -0.6, -0.75), R_LHIP, L_GUARD, L),    # ters tutuşa döndü: bıçak aşağı-geri
			_k(0.1, 0.55, 32, 12, Vector3(-0.3, -0.7, -0.65), R_LHIP, L_GUARD, L),
			_k(0.16, 0.45, -10, 6, Vector3(-0.2, -0.85, -0.5), R_JAB, L_GUARD, W),
			_k(0.22, 0.4, -28, 2, Vector3(-0.1, -0.6, -0.8), R_RSHOULDER, L_GUARD, W),
			_k(0.38, 0.45, -22, 6, Vector3(-0.05, -0.7, -0.7), R_RSHOULDER, L_GUARD, W),
		]},
		# 4: ters tutuşla çömelip bacak hizasında sağdan sola süpürme
		{"len": 0.38, "hit": 0.18, "keys": [
			_k(0.0, 0.45, -22, 6, Vector3(-0.05, -0.7, -0.7), R_RSHOULDER, L_GUARD, W),
			_k(0.1, 0.8, -30, 30, Vector3(-0.3, -0.85, -0.4), R_RLOW, L_REACH, L),
			_k(0.18, 0.85, 20, 35, Vector3(0.4, -0.85, -0.3), R_LLOW, L_REACH, L),
			_k(0.38, 0.8, 22, 32, Vector3(0.4, -0.85, -0.3), R_LLOW, L_GUARD, L),
		]},
		# 5: çömelmeden kalkıp küçük sıçrayışla yukarıdan aşağı ters tutuş çekiç saplaması (sol el bileği destekler)
		{"len": 0.42, "hit": 0.22, "keys": [
			_k(0.0, 0.8, 22, 32, Vector3(0.4, -0.85, -0.3), R_LLOW, L_GUARD, L),
			_k(0.12, 0.05, -5, -10, Vector3(0.0, -0.3, 0.95), R_HAMMER, L_SUPPORT, W),
			_k(0.16, 0.0, -5, -12, Vector3(0.0, -0.25, 0.97), R_HAMMER, L_SUPPORT, W),
			_k(0.22, 0.75, 8, 35, Vector3(0.0, -0.95, 0.3), R_HAMMER_DN, L_SUPPORT, L),
			_k(0.42, 0.6, 6, 22, Vector3(0.0, -0.9, 0.4), R_HAMMER_DN, L_GUARD, L),
		]},
		# 6: bitiriş — düz tutuşa dönüp X kesişi (sol-üstten sağ-alta, sağ-üstten sol-alta; ikincisinde vurur)
		{"len": 0.6, "hit": 0.27, "keys": [
			_k(0.0, 0.6, 6, 22, Vector3(0.0, -0.9, 0.4), R_HAMMER_DN, L_GUARD, L),
			_k(0.07, 0.45, 25, 0, Vector3(0.6, 0.6, 0.5), R_LHIGH, L_GUARD, W),          # düz tutuş, sol omuz üstü
			_k(0.13, 0.65, -20, 22, Vector3(-0.6, -0.6, 0.5), R_RLOW, L_GUARD, L),       # 1. çapraz
			_k(0.2, 0.5, -25, 6, Vector3(-0.6, 0.6, 0.5), R_RHIGH, L_GUARD, W),          # sağ omuz üstü
			_k(0.27, 0.75, 22, 28, Vector3(0.6, -0.6, 0.5), R_LLOW, L_BACK, L),          # 2. çapraz (vuruş)
			_k(0.42, 0.75, 24, 30, Vector3(0.6, -0.62, 0.48), R_LLOW, L_BACK, L),
			_k(0.6, 0.5, 0, 10, Vector3(0.0, 0.15, 1.0), R_READY, L_GUARD, W),
		]},
	]
