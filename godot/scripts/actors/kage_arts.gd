class_name KageArts
extends RefCounted
## Köy lideri (Kage) dövüşü: sıradan jōnin değil. Dövüş başında köyüne özgü modu açar (Raikage Raiton no Yoroi,
## Kazekage kum zırhı, Tsuchikage taş deri + hafiflik, Mizukage buhar zırhı, Hokage Senjutsu), canı yarıya inince
## "Kage'nin kararlılığı" ile ikinci kez güçlenir ve en ağır jutsusunu hemen atar. Jutsu listesi köyün doğasının A/S
## teknikleri + klanının en üst teknikleri (Orgs._raid_kage). Enemy._physics_process her karede tick() çağırır.

const VILLAGE_ELEMENTS := {"konoha": ["katon", "fuuton"], "suna": ["fuuton", "doton"], "kiri": ["suiton", "katon"],
	"kumo": ["raiton"], "iwa": ["doton", "katon"]}
## mod: isim, aura rengi, buff (oyuncu Buffs anahtarları), opsiyonel jutsu (köyün kanon mod jutsusu)
const MODES := {
	"kumo": {"name": "Raiton no Yoroi", "col": Color(0.55, 0.8, 1.0), "mods": {"speed": 1.4, "armor": 0.6, "melee": 1.3}, "jutsu": "raiton_armor"},
	"suna": {"name": "Suna no Yoroi", "col": Color(0.85, 0.72, 0.45), "mods": {"armor": 0.5, "jutsu": 1.2}, "jutsu": "suna_no_yoroi"},
	"iwa": {"name": "Kajūgan / Doton: Ganchūrō", "col": Color(0.7, 0.62, 0.5), "mods": {"armor": 0.5, "melee": 1.25}, "jutsu": ""},
	"kiri": {"name": "Futton: Kōmu no Yoroi", "col": Color(0.9, 0.95, 1.0), "mods": {"armor": 0.6, "jutsu": 1.3}, "jutsu": ""},
	"konoha": {"name": "Senpō: Sennin Mōdo", "col": Color(1.0, 0.6, 0.2), "mods": {"armor": 0.65, "melee": 1.35, "jutsu": 1.35, "speed": 1.15}, "jutsu": ""},
}


static func wants(e: Enemy) -> bool:
	return e.has_meta("kage_of")


## Kage'nin jutsu listesi: köy doğasının en üst (A/S) genel teknikleri (özel şartı olmayan, saldırı biçimli)
static func village_jutsu(vid: String, n := 5) -> Array:
	var els: Array = VILLAGE_ELEMENTS.get(vid, ["katon"])
	var pool = []
	for id in Data.jutsu:
		var j = Data.jutsu[id]
		if not j is Dictionary or not String(j.get("element", "")) in els or int(j.get("tier", 0)) < 4:
			continue
		var lr = String(j.get("learn", ""))
		if String(j.get("need", "")) != "" or not (lr == "" or lr.begins_with("trainer")):
			continue   # yalnız hocadan öğrenilen genel teknikler (göz/Susanoo/sage/bijū/klan şartlıları değil)
		if lr.begins_with("trainer:") and lr.substr(8) != vid and lr.substr(8) != "":
			continue   # köyün kendi hocasının tekniği (Kumo: Raiton Sandāgeto, Kaminarimon...)
		if String(j.get("shape", "")) in ["utility", "sensor", "stealth", "transform", "clone", "heal", "buff", "mode", "teleport"]:
			continue
		pool.append(id)
	pool.shuffle()
	pool.sort_custom(func(x, y): return int(Data.jutsu[x].get("tier", 0)) > int(Data.jutsu[y].get("tier", 0)))
	return pool.slice(0, n)


static func tick(e: Enemy, _dt: float) -> void:
	if e.dead:
		return
	var t = e.target
	if t == null or not is_instance_valid(t) or t.is_dead() or e.state in ["hitstun", "knockdown", "cast"]:
		return
	var vid = String(e.get_meta("kage_of"))
	if not e.get_meta("kage_mode", false) and e.global_position.distance_to(t.global_position) < 35.0:
		_open_mode(e, vid, t)
		return
	if not e.get_meta("kage_resolve", false) and e.hp < e.max_hp * 0.5:
		_resolve(e, t)


static func _open_mode(e: Enemy, vid: String, t: Node3D) -> void:
	e.set_meta("kage_mode", true)
	var m: Dictionary = MODES.get(vid, MODES["konoha"])
	var jid = String(m.get("jutsu", ""))
	if jid != "" and Data.jutsu.has(jid):
		Jutsu.execute(e, jid, t)   # köyün kanon mod jutsusu (oyuncuyla aynı görünüş)
	e.add_buff("kage_mode", 9999.0, m["mods"])
	FX.aura(e, m["col"], 1.3, Vector3(0, 0.9, 0), 0.0)
	e.model.play("cast_out", 0.05, 1.0, true)
	Combat.popup_text(e.global_position + Vector3.UP * 2.6, String(m["name"]) + "!", m["col"].lightened(0.3))
	Hud.banner(e.display_name.split(" — ")[0], "%s açtı!" % m["name"], m["col"])
	if Game.world:
		Game.world.env.add_shake(0.4)


## Can yarıda: Kage pes etmez — ikinci güçlenme, saldırganlık artar, en ağır jutsu hemen
static func _resolve(e: Enemy, t: Node3D) -> void:
	e.set_meta("kage_resolve", true)
	e.add_buff("kage_resolve", 9999.0, {"armor": 0.8, "melee": 1.2, "jutsu": 1.2, "speed": 1.1})
	e.arch["aggr"] = float(e.arch.get("aggr", 0.7)) * 1.4
	e.skill = minf(0.98, e.skill + 0.08)
	Hud.banner(e.display_name.split(" — ")[0], "Köyümü sana bırakmayacağım!", Color(1, 0.45, 0.3))
	var js: Array = e.arch.get("jutsu", [])
	var best = ""
	for id in js:
		if best == "" or int(Data.jutsu.get(id, {}).get("tier", 0)) > int(Data.jutsu.get(best, {}).get("tier", 0)):
			best = id
	if best != "":
		e.jcd.erase(best)
		Jutsu.execute(e, best, t)
		e.jcd[best] = Game.now() + Combat.jutsu_cd(Data.jutsu.get(best, {}))
