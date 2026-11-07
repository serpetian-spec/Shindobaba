extends RefCounted
## Dövüş tarzları ortak poz kütüphanesi: yol/bijū tarzları aynı kol pozlarını ve bacak duruşlarını (style_legs) paylaşır.
## Kol pozu: {"RightUpperArm": yön, "RightLowerArm": yön} (samehada_anim._a ile birleşir). _t: anahtar kare.

const S = preload("res://scripts/combat/samehada_anim.gd")
const F = preload("res://scripts/combat/style_legs.gd")

const R_GUARD := {"RightUpperArm": Vector3(-0.35, -0.85, 0.35), "RightLowerArm": Vector3(0.1, 0.3, 0.95)}
const L_GUARD := {"LeftUpperArm": Vector3(0.35, -0.85, 0.35), "LeftLowerArm": Vector3(-0.1, 0.3, 0.95)}
const R_COCK := {"RightUpperArm": Vector3(-0.55, -0.4, -0.73), "RightLowerArm": Vector3(-0.1, 0.5, 0.86)}
const L_COCK := {"LeftUpperArm": Vector3(0.55, -0.4, -0.73), "LeftLowerArm": Vector3(0.1, 0.5, 0.86)}
const R_PUNCH := {"RightUpperArm": Vector3(-0.1, 0.0, 1), "RightLowerArm": Vector3(0.0, 0.05, 1)}
const L_PUNCH := {"LeftUpperArm": Vector3(0.1, 0.0, 1), "LeftLowerArm": Vector3(0.0, 0.05, 1)}
const R_REACH := {"RightUpperArm": Vector3(-0.08, 0.15, 1), "RightLowerArm": Vector3(0.0, 0.1, 1)}
const L_REACH := {"LeftUpperArm": Vector3(0.08, 0.15, 1), "LeftLowerArm": Vector3(0.0, 0.1, 1)}
const R_PALM := {"RightUpperArm": Vector3(-0.1, -0.1, 1), "RightLowerArm": Vector3(0.0, 0.2, 0.98)}       # avuç öne itilmiş
const L_PALM := {"LeftUpperArm": Vector3(0.1, -0.1, 1), "LeftLowerArm": Vector3(0.0, 0.2, 0.98)}
const R_BACK := {"RightUpperArm": Vector3(-0.6, -0.3, -0.75), "RightLowerArm": Vector3(-0.2, 0.2, -0.95)}
const L_BACK := {"LeftUpperArm": Vector3(0.6, -0.3, -0.75), "LeftLowerArm": Vector3(0.2, 0.2, -0.95)}
const R_HIGH := {"RightUpperArm": Vector3(-0.3, 0.95, -0.1), "RightLowerArm": Vector3(-0.1, 0.9, -0.4)}
const L_HIGH := {"LeftUpperArm": Vector3(0.3, 0.95, -0.1), "LeftLowerArm": Vector3(0.1, 0.9, -0.4)}
const R_SKY := {"RightUpperArm": Vector3(-0.15, 0.98, 0.1), "RightLowerArm": Vector3(-0.05, 1.0, 0.05)}
const L_SKY := {"LeftUpperArm": Vector3(0.15, 0.98, 0.1), "LeftLowerArm": Vector3(0.05, 1.0, 0.05)}
const R_SPREAD := {"RightUpperArm": Vector3(-0.95, 0.2, 0.2), "RightLowerArm": Vector3(-0.85, 0.35, 0.4)}
const L_SPREAD := {"LeftUpperArm": Vector3(0.95, 0.2, 0.2), "LeftLowerArm": Vector3(0.85, 0.35, 0.4)}
const R_SEAL := {"RightUpperArm": Vector3(-0.25, -0.7, 0.67), "RightLowerArm": Vector3(0.75, 0.3, 0.6)}
const L_SEAL := {"LeftUpperArm": Vector3(0.25, -0.7, 0.67), "LeftLowerArm": Vector3(-0.75, 0.3, 0.6)}
const R_GROUND := {"RightUpperArm": Vector3(-0.1, -0.75, 0.65), "RightLowerArm": Vector3(0.0, -0.95, 0.3)}
const L_GROUND := {"LeftUpperArm": Vector3(0.1, -0.75, 0.65), "LeftLowerArm": Vector3(0.0, -0.95, 0.3)}
const R_MOUTH := {"RightUpperArm": Vector3(-0.15, -0.45, 0.88), "RightLowerArm": Vector3(0.4, 0.88, 0.25)}
const L_HIP := {"LeftUpperArm": Vector3(0.2, -0.95, 0.15), "LeftLowerArm": Vector3(0.1, -0.6, 0.8)}
const R_THROW_BACK := {"RightUpperArm": Vector3(-0.6, 0.55, -0.55), "RightLowerArm": Vector3(-0.2, 0.8, 0.5)}
const R_THROW := {"RightUpperArm": Vector3(-0.1, 0.15, 0.98), "RightLowerArm": Vector3(0.05, 0.05, 1)}
const R_SWEEP_IN := {"RightUpperArm": Vector3(0.6, 0.1, 0.78), "RightLowerArm": Vector3(0.95, 0.15, 0.2)}
const R_SWEEP_OUT := {"RightUpperArm": Vector3(-0.95, 0.1, 0.3), "RightLowerArm": Vector3(-0.9, 0.15, 0.35)}
const R_UPPER := {"RightUpperArm": Vector3(-0.2, 0.3, 0.93), "RightLowerArm": Vector3(0.0, 0.95, 0.3)}       # aparkat
const R_LOW := {"RightUpperArm": Vector3(-0.3, -0.9, 0.2), "RightLowerArm": Vector3(0.2, -0.9, 0.3)}
const L_LOW := {"LeftUpperArm": Vector3(0.3, -0.9, 0.2), "LeftLowerArm": Vector3(-0.2, -0.9, 0.3)}
const R_DOWN := {"RightUpperArm": Vector3(-0.1, -0.6, 0.8), "RightLowerArm": Vector3(0.0, -0.98, 0.15)}       # yumruk yere iner

# tekme bacakları (style_legs ile aynı biçim)
const KICK_HIGH_R := {"RightUpperLeg": Vector3(-0.85, 0.35, 0.4), "RightLowerLeg": Vector3(-0.95, 0.2, 0.2), "LeftUpperLeg": Vector3(0.1, -0.98, 0.05), "LeftLowerLeg": Vector3(0.05, -0.98, -0.12)}
const KICK_LOW_L := {"LeftUpperLeg": Vector3(0.5, 0.1, 0.86), "LeftLowerLeg": Vector3(0.6, 0.1, 0.8), "RightUpperLeg": Vector3(-0.15, -0.95, 0.2), "RightLowerLeg": Vector3(-0.05, -0.98, -0.15)}
const KICK_UP_R := {"RightUpperLeg": Vector3(-0.05, 0.6, 0.8), "RightLowerLeg": Vector3(0.0, 0.95, 0.3), "LeftUpperLeg": Vector3(0.1, -0.98, 0.05), "LeftLowerLeg": Vector3(0.05, -0.98, -0.12)}   # dikey yukarı tekme
const KICK_FRONT_R := {"RightUpperLeg": Vector3(-0.05, 0.1, 1), "RightLowerLeg": Vector3(0.0, 0.05, 1), "LeftUpperLeg": Vector3(0.1, -0.98, 0.05), "LeftLowerLeg": Vector3(0.05, -0.98, -0.12)}


static func t(tm: float, crouch: float, yaw: float, lean: float, r: Dictionary, l: Dictionary, legs: Dictionary) -> Dictionary:
	return S._k(tm, crouch, yaw, lean, Vector3(0, 0, 1), S._a(r, l), legs)


## Hazır vuruş adımı: bekleme -> kurulum -> vuruş -> tutuş -> dönüş (zamanlar len'e oranlı)
static func step(length: float, hit: float, set_r: Dictionary, set_l: Dictionary, hit_r: Dictionary, hit_l: Dictionary, set_legs: Dictionary, hit_legs: Dictionary, yaw_set := 0.0, yaw_hit := 0.0, crouch := 0.4, lean := 10.0) -> Dictionary:
	return {"len": length, "hit": hit, "keys": [
		t(0.0, 0.35, 0, 4, R_GUARD, L_GUARD, F.FIGHT),
		t(hit * 0.5, crouch + 0.04, yaw_set, -lean * 0.4, set_r, set_l, set_legs),
		t(hit, crouch, yaw_hit, lean, hit_r, hit_l, hit_legs),
		t(hit + (length - hit) * 0.4, crouch, yaw_hit * 0.85, lean * 0.8, hit_r, hit_l, hit_legs),
		t(length, 0.35, 0, 4, R_GUARD, L_GUARD, F.FIGHT),
	]}
