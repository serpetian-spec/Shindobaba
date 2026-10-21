class_name Stats
extends RefCounted
## Profil (sözlük) üzerinden türetilmiş değerler.


static func max_hp(p: Dictionary) -> float:
	var v = 100.0 + (int(p.get("level", 1)) - 1) * 14.0
	if "vit1" in p.get("skills", []):
		v += 40.0
	if p.get("clan", "") == "senju":
		v += 40.0
	return v


static func max_chakra(p: Dictionary) -> float:
	var v = 80.0 + (int(p.get("level", 1)) - 1) * 10.0
	if "nin2" in p.get("skills", []):
		v += 50.0
	if p.get("clan", "") == "uzumaki":
		v += 60.0
	return v


static func melee_mult(p: Dictionary) -> float:
	var m = 1.0 + (int(p.get("level", 1)) - 1) * 0.04
	var s: Array = p.get("skills", [])
	if "tai1" in s: m += 0.2
	if "tai4" in s: m += 0.3
	if p.get("clan", "") in ["none", "akimichi"]: m += 0.15
	m *= Buffs.mod("melee")
	return m


static func jutsu_mult(p: Dictionary) -> float:
	var m = 1.0 + (int(p.get("level", 1)) - 1) * 0.05
	if "nin4" in p.get("skills", []): m += 0.3
	return m
