class_name Stats
extends RefCounted
## Profil (sözlük) üzerinden türetilmiş değerler.


## Klan pasif bonusu (data/clans.json "bonus": hp, chakra düz; melee, jutsu, speed oran)
static func clan_bonus(p: Dictionary, key: String) -> float:
	return float(Data.clans.get(p.get("clan", "none"), {}).get("bonus", {}).get(key, 0.0))


static func max_hp(p: Dictionary) -> float:
	var v = 100.0 + (int(p.get("level", 1)) - 1) * 14.0
	if "vit1" in p.get("skills", []):
		v += 40.0
	return v + Gear.stat(p, "hp") + clan_bonus(p, "hp")


static func max_chakra(p: Dictionary) -> float:
	var v = 80.0 + (int(p.get("level", 1)) - 1) * 10.0
	if "nin2" in p.get("skills", []):
		v += 50.0
	return v + Gear.stat(p, "chakra") + clan_bonus(p, "chakra")


static func melee_mult(p: Dictionary) -> float:
	var m = 1.0 + (int(p.get("level", 1)) - 1) * 0.04
	var s: Array = p.get("skills", [])
	if "tai1" in s: m += 0.2
	if "tai4" in s: m += 0.3
	m += clan_bonus(p, "melee")
	m *= Buffs.mod("melee") * (1.0 + Gear.stat(p, "melee"))
	return m


static func jutsu_mult(p: Dictionary) -> float:
	var m = 1.0 + (int(p.get("level", 1)) - 1) * 0.05
	if "nin4" in p.get("skills", []): m += 0.3
	m += clan_bonus(p, "jutsu")
	m *= Buffs.mod("jutsu")
	return m
