class_name RaijinAnim
## Raijin Kılıcı kombosu, 6 vuruş (kaynak yok — _tmp/ed/raijin_desc.md kendime anlatımı).
## Tek elle iaidō ritmi: kısa net kurulma -> şimşek hızında vuruş -> bıçak bir an donar -> hızlı toparlanma.
## Anahtarlardaki "ext": ağız uzama çarpanı (saplamada chakra ağzı uzar).

const L_GUARD := {"LeftUpperArm": Vector3(0.3, -0.92, 0.25), "LeftLowerArm": Vector3(0.0, -0.15, 1.0)}
const L_AIM := {"LeftUpperArm": Vector3(0.15, -0.2, 0.97), "LeftLowerArm": Vector3(0.05, -0.05, 1)}
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.6, -0.55), "LeftLowerArm": Vector3(0.3, -0.6, -0.75)}
const L_UP := {"LeftUpperArm": Vector3(0.6, 0.7, 0.3), "LeftLowerArm": Vector3(0.4, 0.85, 0.3)}

const R_READY := {"RightUpperArm": Vector3(-0.25, -0.9, 0.35), "RightLowerArm": Vector3(-0.1, -0.15, 1)}
const R_LSHOULDER := {"RightUpperArm": Vector3(0.15, 0.2, 0.97), "RightLowerArm": Vector3(0.85, 0.5, 0.15)}
const R_RLOW := {"RightUpperArm": Vector3(-0.7, -0.7, 0.2), "RightLowerArm": Vector3(-0.6, -0.6, 0.5)}
const R_LLOW := {"RightUpperArm": Vector3(0.2, -0.85, 0.5), "RightLowerArm": Vector3(0.8, -0.5, 0.35)}
const R_RHIP := {"RightUpperArm": Vector3(-0.6, -0.8, -0.1), "RightLowerArm": Vector3(-0.5, -0.4, 0.75)}
const R_CHEST := {"RightUpperArm": Vector3(-0.35, -0.6, 0.72), "RightLowerArm": Vector3(0.4, 0.15, 0.9)}
const R_THRUST := {"RightUpperArm": Vector3(-0.08, -0.1, 1), "RightLowerArm": Vector3(0.0, -0.05, 1)}
const R_LHIGH := {"RightUpperArm": Vector3(0.1, 0.6, 0.8), "RightLowerArm": Vector3(0.6, 0.75, 0.25)}
const R_RHIGH := {"RightUpperArm": Vector3(-0.55, 0.6, 0.6), "RightLowerArm": Vector3(-0.4, 0.85, 0.35)}
const R_ABOVE := {"RightUpperArm": Vector3(-0.3, 0.95, 0.1), "RightLowerArm": Vector3(-0.05, 1, 0.1)}
const R_DOWN_FWD := {"RightUpperArm": Vector3(-0.15, -0.55, 0.82), "RightLowerArm": Vector3(0.0, -0.5, 0.86)}


static func _k(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary, ext := 1.0) -> Dictionary:
	var k = SamehadaAnim._k(t, crouch, yaw, lean, blade, SamehadaAnim._a(r, l), legs)
	k["ext"] = ext
	return k


static func steps() -> Array:
	var W = SamehadaAnim.LEG_WIDE
	var L = SamehadaAnim.LEG_LUNGE
	var G = L_GUARD
	return [
		# 1: kesa giri — sol omuzdan sağ-aşağı çapraz
		{"len": 0.42, "hit": 0.17, "keys": [
			_k(0.0, 0.45, 0, 8, Vector3(0.0, 0.2, 1.0), R_READY, G, W),
			_k(0.12, 0.4, 25, 2, Vector3(0.45, 0.75, -0.45), R_LSHOULDER, G, W),
			_k(0.17, 0.6, -18, 22, Vector3(-0.6, -0.55, 0.55), R_RLOW, G, L),
			_k(0.24, 0.62, -22, 24, Vector3(-0.65, -0.6, 0.45), R_RLOW, G, L),
			_k(0.42, 0.55, -18, 18, Vector3(-0.6, -0.55, 0.55), R_RLOW, G, L),
		]},
		# 2: ters yükselen kesiş — sağ alttan sol omza
		{"len": 0.4, "hit": 0.12, "keys": [
			_k(0.0, 0.55, -18, 18, Vector3(-0.6, -0.55, 0.55), R_RLOW, G, L),
			_k(0.07, 0.6, -25, 20, Vector3(-0.7, -0.6, 0.35), R_RLOW, G, L),
			_k(0.12, 0.45, 22, 6, Vector3(0.6, 0.6, 0.5), R_LHIGH, G, W),
			_k(0.2, 0.42, 26, 4, Vector3(0.55, 0.7, 0.45), R_LHIGH, G, W),
			_k(0.4, 0.42, 22, 4, Vector3(0.5, 0.65, 0.55), R_LHIGH, G, W),
		]},
		# 3: yatay bel kesişi — sağ kalçaya çek, sağdan sola
		{"len": 0.42, "hit": 0.18, "keys": [
			_k(0.0, 0.42, 22, 4, Vector3(0.5, 0.65, 0.55), R_LHIGH, G, W),
			_k(0.13, 0.5, -30, 10, Vector3(-0.95, 0.0, -0.3), R_RHIP, G, W),
			_k(0.18, 0.6, 5, 18, Vector3(0.1, -0.05, 1.0), R_THRUST, G, L),
			_k(0.24, 0.62, 30, 18, Vector3(0.95, -0.05, 0.2), R_LLOW, G, L),
			_k(0.42, 0.55, 26, 14, Vector3(0.9, 0.0, 0.35), R_LLOW, G, L),
		]},
		# 4: şimşek saplaması — göğse çek, sol el nişan; ileri sapla, ağız uzar ve geri kısalır
		{"len": 0.5, "hit": 0.19, "keys": [
			_k(0.0, 0.55, 26, 14, Vector3(0.9, 0.0, 0.35), R_LLOW, G, L),
			_k(0.13, 0.5, -15, 5, Vector3(0.0, 0.05, 1.0), R_CHEST, L_AIM, W),
			_k(0.19, 0.75, 12, 28, Vector3(0.0, 0.0, 1.0), R_THRUST, L_BACK, L, 2.1),
			_k(0.3, 0.75, 12, 28, Vector3(0.0, 0.0, 1.0), R_THRUST, L_BACK, L, 2.1),
			_k(0.38, 0.65, 8, 20, Vector3(0.0, 0.05, 1.0), R_THRUST, L_BACK, L, 1.0),
			_k(0.5, 0.5, 0, 10, Vector3(0.0, 0.2, 1.0), R_READY, G, W),
		]},
		# 5: ikili sekiz — sol üst -> sağ alt, sağ üst -> sol alt (ikincisi vurur)
		{"len": 0.5, "hit": 0.27, "keys": [
			_k(0.0, 0.5, 0, 10, Vector3(0.0, 0.2, 1.0), R_READY, G, W),
			_k(0.08, 0.45, 25, 2, Vector3(0.6, 0.6, 0.5), R_LHIGH, G, W),
			_k(0.14, 0.62, -20, 22, Vector3(-0.6, -0.6, 0.5), R_RLOW, G, L),
			_k(0.2, 0.5, -25, 6, Vector3(-0.6, 0.6, 0.5), R_RHIGH, G, W),
			_k(0.27, 0.72, 22, 26, Vector3(0.6, -0.6, 0.5), R_LLOW, L_BACK, L),
			_k(0.5, 0.65, 20, 22, Vector3(0.6, -0.6, 0.48), R_LLOW, G, L),
		]},
		# 6: Raijin düşüşü — başın üstüne kaldır (gökten yıldırım), derin hamleyle tepeden biç
		{"len": 0.75, "hit": 0.4, "keys": [
			_k(0.0, 0.65, 20, 22, Vector3(0.6, -0.6, 0.48), R_LLOW, G, L),
			_k(0.16, 0.2, -5, -10, Vector3(0.0, 1.0, 0.1), R_ABOVE, L_UP, W, 1.3),
			_k(0.32, 0.15, -6, -12, Vector3(0.0, 0.98, -0.2), R_ABOVE, L_UP, W, 1.3),
			_k(0.4, 0.8, 8, 38, Vector3(0.0, -0.6, 0.8), R_DOWN_FWD, L_BACK, L, 1.3),
			_k(0.58, 0.8, 8, 38, Vector3(0.0, -0.62, 0.78), R_DOWN_FWD, L_BACK, L, 1.0),
			_k(0.75, 0.55, 0, 15, Vector3(0.0, 0.1, 1.0), R_READY, G, W),
		]},
	]
