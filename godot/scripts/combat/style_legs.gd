extends RefCounted
## Dövüş tarzları için canlı bacak pozları (kalas gibi düz bacak YOK): dizler hep bükük, ayaklar kaydırılmış (sol önde),
## ağırlık aktarımı (arkaya yüklenme / öne adım), arka ayak topuğu kalkarak dönen kalça (pivot). +X karakterin solu, +Z önü.

const FIGHT := {   # dövüş duruşu: sol ayak önde, iki diz bükük, arka ayak yarım döner
	"LeftUpperLeg": Vector3(0.18, -0.82, 0.55), "LeftLowerLeg": Vector3(0.05, -0.97, -0.15), "LeftFoot": Vector3(0.05, -0.45, 0.89),
	"RightUpperLeg": Vector3(-0.2, -0.9, -0.3), "RightLowerLeg": Vector3(-0.05, -0.8, -0.6), "RightFoot": Vector3(-0.25, -0.55, 0.8)}
const SHIFT := {   # kurulum: ağırlık arka bacakta (diz derin), ön ayak hafif, topuk yerde
	"LeftUpperLeg": Vector3(0.18, -0.92, 0.35), "LeftLowerLeg": Vector3(0.05, -0.85, 0.5), "LeftFoot": Vector3(0.05, -0.15, 0.99),
	"RightUpperLeg": Vector3(-0.2, -0.7, -0.68), "RightLowerLeg": Vector3(-0.05, -0.95, -0.3), "RightFoot": Vector3(-0.25, -0.5, 0.83)}
const STEPIN := {   # öne adım: ön diz kalkık ileri, arka bacak iter (topuk kalkık)
	"LeftUpperLeg": Vector3(0.15, -0.5, 0.85), "LeftLowerLeg": Vector3(0.05, -0.97, 0.22), "LeftFoot": Vector3(0.05, -0.55, 0.83),
	"RightUpperLeg": Vector3(-0.2, -0.82, -0.53), "RightLowerLeg": Vector3(-0.05, -0.6, -0.8), "RightFoot": Vector3(-0.1, -0.92, 0.38)}
const PIVOT := {   # sağ yumruk/avuç vuruşu: arka (sağ) topuk kalkıp içe döner, ön diz bükük taşır
	"LeftUpperLeg": Vector3(0.2, -0.72, 0.66), "LeftLowerLeg": Vector3(0.05, -0.98, -0.1), "LeftFoot": Vector3(0.05, -0.45, 0.89),
	"RightUpperLeg": Vector3(-0.15, -0.95, -0.25), "RightLowerLeg": Vector3(-0.05, -0.82, -0.57), "RightFoot": Vector3(0.1, -0.85, 0.5)}
const PIVOT_L := {   # sol vuruş: ön (sol) bacak geri çekilip döner, sağ öne geçer
	"LeftUpperLeg": Vector3(0.15, -0.95, -0.25), "LeftLowerLeg": Vector3(0.05, -0.82, -0.57), "LeftFoot": Vector3(-0.1, -0.85, 0.5),
	"RightUpperLeg": Vector3(-0.2, -0.72, 0.66), "RightLowerLeg": Vector3(-0.05, -0.98, -0.1), "RightFoot": Vector3(-0.05, -0.45, 0.89)}
const LOW := {   # alçak geniş duruş (Jūken, ağır vuruşlar): iki diz derin bükük, ayaklar açık
	"LeftUpperLeg": Vector3(0.45, -0.6, 0.66), "LeftLowerLeg": Vector3(0.1, -0.92, -0.38), "LeftFoot": Vector3(0.2, -0.4, 0.89),
	"RightUpperLeg": Vector3(-0.45, -0.65, -0.62), "RightLowerLeg": Vector3(-0.1, -0.9, -0.42), "RightFoot": Vector3(-0.35, -0.5, 0.79)}
const HOP := {   # sekme/havalanış: iki diz toplanmış
	"LeftUpperLeg": Vector3(0.18, -0.4, 0.9), "LeftLowerLeg": Vector3(0.05, -0.9, -0.43), "LeftFoot": Vector3(0.05, -0.5, 0.86),
	"RightUpperLeg": Vector3(-0.18, -0.6, 0.78), "RightLowerLeg": Vector3(-0.05, -0.85, -0.52), "RightFoot": Vector3(-0.05, -0.5, 0.86)}
