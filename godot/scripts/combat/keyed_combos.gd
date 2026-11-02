extends RefCounted
## ELLE YAPILMIŞ SİLAH KOMBOLARI — TEK KAYIT. Oyuncu (PlayerCombat) ve yapay zekâ (Enemy) ikisi de buradan okur:
## yeni bir silah animasyonu (X_anim.gd, steps() -> 5-6 adım) yalnız buraya eklenir, düşmanlar da otomatik kullanır.
## [adım betiği, hız çarpanı]
const TABLE := {
	"samehada": [preload("res://scripts/combat/samehada_anim.gd"), 1.3],
	"gunbai": [preload("res://scripts/combat/gunbai_anim.gd"), 1.05],   # ağır silah ritmi
	"kunai": [preload("res://scripts/combat/kunai_anim.gd"), 1.0],
	"raijin": [preload("res://scripts/combat/raijin_anim.gd"), 1.0],
	"uc_tirpan": [preload("res://scripts/combat/tirpan_anim.gd"), 1.0],
}
## iki elli adımlarda sol elin sağ yumruktan sap boyunca uzaklığı
const TWO_OFF := {"uc_tirpan": 0.42}


static func has(id: String) -> bool:
	return TABLE.has(id)


static func steps(id: String) -> Array:
	return TABLE[id][0].steps()


static func speed(id: String) -> float:
	return float(TABLE[id][1])


static func two_off(id: String) -> float:
	return float(TWO_OFF.get(id, 0.32))
