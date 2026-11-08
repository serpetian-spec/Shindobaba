class_name KageArts
extends RefCounted
## Köy lideri (Kage) dövüşü: Kage her zaman köyünün GÜÇLÜ klanlarından biridir (Kage.succeed) ve dövüş başında
## KENDİ KLANININ modunu oyunun gerçek sistemleriyle açar: Uchiha Mangekyō + Susanoo, Hyūga Byakugan, Chinoike Ketsuryūgan,
## Senju Sennin Mōdo + Mokuton, Sabaku kum zırhı + Sabaku Fuyū, Jūgo öfke formu, Hōzuki Gōsuiwan, Yotsuki Raiton no Yoroi...
## Canı yarıya inince ikinci kez güçlenir ve en ağır jutsusunu hemen atar. Enemy._physics_process her karede tick() çağırır.

const VILLAGE_ELEMENTS := {"konoha": ["katon", "fuuton"], "suna": ["fuuton", "doton"], "kiri": ["suiton", "katon"],
	"kumo": ["raiton"], "iwa": ["doton", "katon"]}
## Kage olabilecek güçlü klanlar (köye göre)
const STRONG := {"konoha": ["senju", "uchiha", "hyuga", "uzumaki", "namikaze", "sarutobi"], "suna": ["sabaku", "shirogane"],
	"kiri": ["terumi", "yuki", "kaguya", "hozuki", "karatachi"], "kumo": ["yotsuki", "chinoike"], "iwa": ["kamizuru", "jugo"]}
## klan modu: göz (EnemyArts), açılışta atılan klan jutsuları, buff, aura rengi, ad
const CLAN_MODE := {
	"uchiha": {"name": "Mangekyō Sharingan — Susanoo", "eye": 4, "susanoo": true, "mods": {"armor": 0.75}, "col": Color(0.85, 0.1, 0.12)},
	"hyuga": {"name": "Byakugan — Jūken", "eye": 2, "mods": {"melee": 1.4, "armor": 0.8}, "col": Color(0.75, 0.85, 1.0)},
	"chinoike": {"name": "Ketsuryūgan", "eye": 3, "mods": {"jutsu": 1.3, "armor": 0.8}, "col": Color(0.8, 0.1, 0.15)},
	"senju": {"name": "Senpō: Sennin Mōdo", "mods": {"armor": 0.6, "melee": 1.35, "jutsu": 1.35, "speed": 1.15}, "col": Color(1.0, 0.6, 0.2),
		"add": ["mokuton_jukai_kotan", "mokuton_mokuryu_no_jutsu", "mokuton_daijurin_no_jutsu", "mokuton_mokujoheki"]},
	"sabaku": {"name": "Suna no Yoroi", "cast": ["suna_no_yoroi", "sabaku_fuyu"], "mods": {"armor": 0.55}, "col": Color(0.85, 0.72, 0.45)},
	"jugo": {"name": "Senninka (Jūgo öfkesi)", "cast": ["jugo_ofke"], "mods": {"melee": 1.3, "armor": 0.7}, "col": Color(0.95, 0.55, 0.2)},
	"hozuki": {"name": "Gōsuiwan", "cast": ["suiton_gosuiwan_no_jutsu"], "mods": {"armor": 0.7, "melee": 1.25}, "col": Color(0.5, 0.75, 1.0)},
	"yotsuki": {"name": "Raiton no Yoroi", "cast": ["raiton_armor"], "mods": {"speed": 1.35, "armor": 0.65, "melee": 1.3}, "col": Color(0.55, 0.8, 1.0)},
	"shirogane": {"name": "Chikamatsu Jikki", "cast": ["shirohigi_jikki_chikamatsu_no_shu"], "mods": {"armor": 0.8}, "col": Color(0.75, 0.75, 0.85)},
	"kamizuru": {"name": "Kamizuru Hachi", "cast": ["kamizuru_hachi"], "mods": {"armor": 0.8}, "col": Color(0.95, 0.8, 0.3)},
}


static func wants(e: Enemy) -> bool:
	return e.has_meta("kage_of")


## Kage'nin jutsu listesi: köy doğasının en üst (A/S) genel teknikleri (hocadan öğrenilen, özel şartı olmayan, saldırı biçimli)
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
			continue
		if String(j.get("shape", "")) in ["utility", "sensor", "stealth", "transform", "clone", "heal", "buff", "mode", "teleport"]:
			continue
		pool.append(id)
	pool.shuffle()
	pool.sort_custom(func(x, y): return int(Data.jutsu[x].get("tier", 0)) > int(Data.jutsu[y].get("tier", 0)))
	return pool.slice(0, n)


## Kage kurulumu (spawn sonrası): klan modunun ekleri (Senju Mokuton'u), gözler
static func prepare(e: Enemy, clan: String) -> void:
	var m: Dictionary = CLAN_MODE.get(clan, {})
	for id in m.get("add", []):
		if Data.jutsu.has(id) and not id in e.arch["jutsu"]:
			(e.arch["jutsu"] as Array).push_front(id)
	if int(m.get("eye", 0)) > 0:
		Eyes.give_enemy_eyes(e, int(m["eye"]), 3)


static func tick(e: Enemy, _dt: float) -> void:
	if e.dead:
		return
	var t = e.target
	if t == null or not is_instance_valid(t) or t.is_dead() or e.state in ["knockdown", "cast"]:
		return
	if not e.get_meta("kage_mode", false) and e.global_position.distance_to(t.global_position) < 35.0:
		_open_mode(e, t)
		return
	if not e.get_meta("kage_resolve", false) and e.hp < e.max_hp * 0.5:
		_resolve(e, t)


static func _open_mode(e: Enemy, t: Node3D) -> void:
	e.set_meta("kage_mode", true)
	var clan = String(e.arch.get("clan", ""))
	var m: Dictionary = CLAN_MODE.get(clan, {"name": "", "mods": {"armor": 0.75, "melee": 1.2, "jutsu": 1.2}, "col": Color(1, 0.85, 0.5)})
	for jid in m.get("cast", []):
		if Data.jutsu.has(jid):
			Jutsu.execute(e, jid, t)   # klanın kendi mod tekniği (oyuncudakiyle aynı görünüş)
	if int(m.get("eye", 0)) in [4, 5]:
		EnemyArts.ms_open(e)
	if m.get("susanoo", false) and not e.has_meta("ea_susanoo"):
		EnemyArts._susanoo(e)
	e.add_buff("kage_mode", 9999.0, m["mods"])
	FX.aura(e, m["col"], 1.3, Vector3(0, 0.9, 0), 0.0)
	if String(m["name"]) != "":
		Combat.popup_text(e.global_position + Vector3.UP * 2.6, String(m["name"]) + "!", m["col"].lightened(0.3))
		Hud.banner(e.display_name.split(" — ")[0], "%s!" % m["name"], m["col"])
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
