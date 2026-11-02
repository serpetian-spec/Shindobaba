class_name TirpanAnim
## Üç Bıçaklı Tırpan kombosu, 6 vuruş (kaynak yok — _tmp/ed/tirpan_desc.md kendime anlatımı; her satır bir anahtar).
## Ağır silah: baş hep ARKADAN dolanır (uzun kurulma -> duraksama -> kalçadan açılan çok hızlı geniş yay -> baş bedeni sürükler ->
## yavaş toparlanma). Kılıç/Samehada hareketi ve dönüş yok. Yönler iskelet uzayında: +Z ön, +X karakterin solu, +Y yukarı.
## "blade": sağ yumruktan tırpan başına sap yönü. "two": adım boyunca sol el sapta (IK, sağ elin 42 cm ilerisinde).

const TWO_OFF := 0.42

# sağ el (yumruk sapın en ucunda, pommel yanında)
const R_HIP_BACK := {"RightUpperArm": Vector3(-0.35, -0.9, -0.25), "RightLowerArm": Vector3(-0.15, -0.75, 0.6)}   # sağ kalça yanı-arkası
const R_SIDE_LOW := {"RightUpperArm": Vector3(-0.75, -0.65, 0.05), "RightLowerArm": Vector3(-0.55, -0.45, 0.7)}   # sağda bel hizası
const R_BELLY := {"RightUpperArm": Vector3(-0.1, -0.85, 0.5), "RightLowerArm": Vector3(0.6, -0.2, 0.75)}          # karın önü
const R_LHIP := {"RightUpperArm": Vector3(0.3, -0.9, 0.3), "RightLowerArm": Vector3(0.8, -0.5, 0.3)}               # sol kalça önü
const R_LOW_FRONT := {"RightUpperArm": Vector3(-0.1, -0.8, 0.6), "RightLowerArm": Vector3(0.1, -0.7, 0.7)}        # önde diz hizası
const R_SH_UP := {"RightUpperArm": Vector3(-0.6, 0.6, 0.5), "RightLowerArm": Vector3(-0.2, 0.9, 0.4)}             # sağ omuz üstü
const R_ABOVE := {"RightUpperArm": Vector3(-0.3, 0.95, 0.1), "RightLowerArm": Vector3(-0.05, 1, 0.1)}             # başın üstü
const R_NAPE := {"RightUpperArm": Vector3(-0.8, 0.55, 0.1), "RightLowerArm": Vector3(0.45, 0.85, -0.2)}           # ense arkası (eller kafanın arkasında)
const R_FWD := {"RightUpperArm": Vector3(-0.05, 0.05, 1), "RightLowerArm": Vector3(0.0, 0.0, 1)}                  # kol tam ileri
const R_FWD_HIGH := {"RightUpperArm": Vector3(-0.1, 0.45, 0.9), "RightLowerArm": Vector3(0.0, 0.3, 0.95)}         # ileri-yukarı uzanmış
const R_CHEST := {"RightUpperArm": Vector3(-0.2, -0.4, 0.9), "RightLowerArm": Vector3(0.2, 0.1, 1)}               # göğüs önü
const R_EAR_BACK := {"RightUpperArm": Vector3(-0.8, 0.3, -0.45), "RightLowerArm": Vector3(0.3, 0.95, 0.1)}        # sağ kulağın arkası
const R_SIDE := {"RightUpperArm": Vector3(-1, 0.05, 0.1), "RightLowerArm": Vector3(-0.95, 0.0, 0.3)}              # sağa uzanmış
# sol el (iki elli adımlarda IK ile sapa gider; bu pozlar yalnız başlangıç/serbest el)
const L_DOWN := {"LeftUpperArm": Vector3(0.3, -0.9, 0.3), "LeftLowerArm": Vector3(0.1, -0.8, 0.6)}
const L_POINT := {"LeftUpperArm": Vector3(0.15, 0.05, 1), "LeftLowerArm": Vector3(0.05, 0.0, 1)}                  # rakibi gösterir
const L_BACK := {"LeftUpperArm": Vector3(0.55, -0.55, -0.6), "LeftLowerArm": Vector3(0.3, -0.6, -0.75)}           # geriye savrulmuş


static func _t(t: float, crouch: float, yaw: float, lean: float, blade: Vector3, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	# ağır baş bedeni taşır: burulma ve eğilme tarif açılarından belirgin (ham açılarda gövde dik kalıp kollarla sallıyor gibiydi)
	return SamehadaAnim._k(t, minf(1.0, crouch * 1.1), yaw * 1.5, lean * 1.4, blade.normalized(), SamehadaAnim._a(r, l), legs)


static func steps() -> Array:
	var W = SamehadaAnim.LEG_WIDE
	var L = SamehadaAnim.LEG_LUNGE
	return [
		# 1 Biçme: baş tam arkaya, gövde sağa burulu, geriye yaslı -> sağ yandan geçip önü bel hizasında biçer -> sol-arkaya savrulur
		{"len": 1.0, "hit": 0.44, "two": true, "keys": [
			_t(0.0, 0.3, -5, 0, Vector3(-0.5, 0.2, 0.84), R_BELLY, L_DOWN, W),
			_t(0.12, 0.38, -30, -6, Vector3(-0.75, -0.05, -0.65), R_HIP_BACK, L_DOWN, W),
			_t(0.30, 0.45, -55, -12, Vector3(-0.25, -0.12, -0.96), R_HIP_BACK, L_DOWN, W),
			_t(0.36, 0.46, -57, -13, Vector3(-0.22, -0.12, -0.97), R_HIP_BACK, L_DOWN, W),
			_t(0.40, 0.5, -25, 5, Vector3(-0.98, -0.1, 0.12), R_SIDE_LOW, L_DOWN, W),
			_t(0.44, 0.58, 12, 20, Vector3(0.1, -0.1, 0.99), R_BELLY, L_DOWN, L),
			_t(0.52, 0.62, 42, 26, Vector3(0.95, -0.12, 0.25), R_LHIP, L_DOWN, L),
			_t(0.68, 0.62, 58, 22, Vector3(0.7, -0.18, -0.68), R_LHIP, L_DOWN, L),
			_t(1.0, 0.48, 42, 10, Vector3(0.72, -0.22, -0.62), R_LHIP, L_DOWN, W),
		]},
		# 2 Bacak biçme: daha da sola-arkaya ve aşağı çeker, derin çömelir -> önden diz altında sağa biçer -> sağ-arkada alçakta biter
		{"len": 0.95, "hit": 0.40, "two": true, "keys": [
			_t(0.0, 0.48, 42, 10, Vector3(0.72, -0.22, -0.62), R_LHIP, L_DOWN, W),
			_t(0.22, 0.72, 68, 22, Vector3(0.55, -0.48, -0.68), R_LHIP, L_DOWN, W),
			_t(0.29, 0.74, 70, 23, Vector3(0.52, -0.5, -0.69), R_LHIP, L_DOWN, W),
			_t(0.35, 0.78, 40, 28, Vector3(0.88, -0.42, 0.22), R_LHIP, L_DOWN, W),
			_t(0.40, 0.82, 0, 32, Vector3(0.0, -0.48, 0.88), R_LOW_FRONT, L_DOWN, L),
			_t(0.48, 0.8, -35, 26, Vector3(-0.9, -0.4, 0.17), R_SIDE_LOW, L_DOWN, L),
			_t(0.62, 0.72, -50, 18, Vector3(-0.7, -0.38, -0.6), R_HIP_BACK, L_DOWN, L),
			_t(0.95, 0.5, -38, 8, Vector3(-0.7, -0.3, -0.64), R_HIP_BACK, L_DOWN, W),
		]},
		# 3 Kanca çekişi: baş sağ-arkadan yukarı kalkar (geriye yaslı) -> üstten öne atılıp rakibin arkasına düşer -> geriye yaslanıp çeker
		{"len": 0.95, "hit": 0.46, "two": true, "keys": [
			_t(0.0, 0.5, -38, 8, Vector3(-0.7, -0.3, -0.64), R_HIP_BACK, L_DOWN, W),
			_t(0.18, 0.38, -25, -15, Vector3(-0.3, 0.85, -0.42), R_SH_UP, L_DOWN, W),
			_t(0.28, 0.38, -26, -18, Vector3(-0.28, 0.86, -0.43), R_SH_UP, L_DOWN, W),
			_t(0.38, 0.48, 5, 15, Vector3(-0.05, 0.75, 0.66), R_FWD_HIGH, L_DOWN, L),
			_t(0.46, 0.55, 10, 28, Vector3(0.0, -0.12, 0.99), R_FWD, L_DOWN, L),
			_t(0.52, 0.55, 8, 26, Vector3(0.0, -0.18, 0.98), R_FWD, L_DOWN, L),
			_t(0.66, 0.55, -18, -18, Vector3(-0.12, -0.05, 0.99), R_HIP_BACK, L_DOWN, W),
			_t(0.95, 0.42, -10, -6, Vector3(-0.25, 0.35, 0.9), R_CHEST, L_DOWN, W),
		]},
		# 4 Gökten iniş: baş başın üstünden sırta sarkar, gövde geriye bükülür -> tam üstten indirip öndeki yere saplar -> saplı kalır -> söker
		{"len": 1.05, "hit": 0.45, "two": true, "chop": true, "keys": [
			_t(0.0, 0.42, -10, -6, Vector3(-0.25, 0.35, 0.9), R_CHEST, L_DOWN, W),
			_t(0.14, 0.38, -8, -10, Vector3(-0.1, 0.99, 0.05), R_ABOVE, L_DOWN, W),
			_t(0.28, 0.4, -10, -22, Vector3(-0.05, -0.35, -0.94), R_NAPE, L_DOWN, W),
			_t(0.34, 0.4, -10, -24, Vector3(-0.05, -0.4, -0.92), R_NAPE, L_DOWN, W),
			_t(0.40, 0.5, 0, 5, Vector3(0.0, 0.99, 0.12), R_ABOVE, L_DOWN, W),
			_t(0.45, 0.85, 5, 45, Vector3(0.0, -0.55, 0.84), R_LOW_FRONT, L_DOWN, L),
			_t(0.72, 0.85, 5, 44, Vector3(0.0, -0.56, 0.83), R_LOW_FRONT, L_DOWN, L),
			_t(0.82, 0.62, 0, 22, Vector3(0.0, -0.2, 0.98), R_BELLY, L_DOWN, L),
			_t(1.05, 0.5, 5, 15, Vector3(0.2, -0.35, 0.92), R_BELLY, L_DOWN, W),
		]},
		# 5 Yükselen biçme: saplı baş yerde sola-arkaya sürüklenir (alçak, sola burulu) -> aşağıdan çapraz sağ-üste biçer, beden yükselir
		{"len": 0.95, "hit": 0.40, "two": true, "keys": [
			_t(0.0, 0.5, 5, 15, Vector3(0.2, -0.35, 0.92), R_BELLY, L_DOWN, W),
			_t(0.12, 0.6, 35, 18, Vector3(0.8, -0.5, 0.3), R_LHIP, L_DOWN, W),
			_t(0.24, 0.66, 55, 20, Vector3(0.55, -0.45, -0.7), R_LHIP, L_DOWN, W),
			_t(0.30, 0.67, 56, 21, Vector3(0.53, -0.46, -0.71), R_LHIP, L_DOWN, W),
			_t(0.36, 0.6, 25, 15, Vector3(0.3, -0.55, 0.78), R_BELLY, L_DOWN, L),
			_t(0.40, 0.42, -10, 5, Vector3(-0.35, 0.3, 0.88), R_CHEST, L_DOWN, L),
			_t(0.48, 0.28, -30, -12, Vector3(-0.55, 0.8, 0.2), R_SH_UP, L_DOWN, W),
			_t(0.62, 0.3, -35, -15, Vector3(-0.45, 0.75, -0.5), R_SH_UP, L_DOWN, W),
			_t(0.95, 0.35, -32, -10, Vector3(-0.45, 0.72, -0.53), R_SH_UP, L_DOWN, W),
		]},
		# 6 Kan Hilali (tek el, en uzun menzil): sol el rakibi gösterir, baş sağ-üst-arkada -> kol tam uzanıp üst-sağdan alt-sola büyük çapraz
		{"len": 1.2, "hit": 0.46, "two": false, "keys": [
			_t(0.0, 0.35, -32, -10, Vector3(-0.45, 0.72, -0.53), R_SH_UP, L_DOWN, W),
			_t(0.26, 0.36, -50, -18, Vector3(-0.45, 0.35, -0.82), R_EAR_BACK, L_POINT, W),
			_t(0.34, 0.37, -52, -19, Vector3(-0.44, 0.34, -0.83), R_EAR_BACK, L_POINT, W),
			_t(0.40, 0.45, -20, 0, Vector3(-0.85, 0.45, 0.25), R_SIDE, L_POINT, W),
			_t(0.46, 0.65, 25, 35, Vector3(0.15, -0.35, 0.92), R_FWD, L_BACK, L),
			_t(0.56, 0.7, 50, 40, Vector3(0.85, -0.5, 0.15), R_LHIP, L_BACK, L),
			_t(0.78, 0.7, 60, 35, Vector3(0.65, -0.6, -0.45), R_LHIP, L_BACK, L),
			_t(1.2, 0.45, 25, 12, Vector3(0.6, -0.5, -0.6), R_LHIP, L_DOWN, W),
		]},
	]
