extends Node
## Oyuncu üzerindeki geçici etkiler (autoload "Buffs"): Raiton zırhı, Henge, asker hapı, Sennin modu...

var active = {}  # ad -> {t, mods}
## Şu an jutsu atan (Jutsu.execute ayarlar): düşman/klon/çağrı bir buff jutsusu atınca buff ONA gider, oyuncuya değil
## (eskiden düşmanın Doton Doryūkatsu vb. buff'ı oyuncuya yazılıyordu)
var caster: Node = null


## Güç modu jutsuları: biri açılınca diğerleri ve Sennin / göz / kapı / canavar modları kapanır (üst üste binmez)
const MODE_GROUP := ["hachimon", "hachimon_3", "kairiki_muso", "barion", "chi_no_juin", "kama", "kyubi_chakura", "rikudo_no_jutsu",
	"rikudo_senjutsu", "rikudo_sennin", "sennin_modo", "yoton_chakura", "cho_modo", "gyojin", "kuyruk_ortusu", "tenseigan_modo",
	"jugo_ofke", "raiton_chakura_modo", "hakuja_shintai", "cho_baika", "baika", "raiton_armor", "juin1", "juin2", "hakuja", "yamata"]


func add(name: String, dur: float, mods: Dictionary) -> void:
	if caster != null and is_instance_valid(caster) and not (caster is Player):
		if caster.has_method("add_buff"):
			caster.add_buff(name, dur, mods)
		return
	if name in MODE_GROUP and not active.has(name):
		clear_modes(name)
		var pl = Game.player
		if pl and is_instance_valid(pl) and pl.get("combat") and pl.combat.get("modes"):
			pl.combat.modes.exclusive("jutsu")
	active[name] = {"t": dur, "mods": mods}


func clear_modes(keep: String = "") -> void:
	for k in active.keys():
		if k != keep and k in MODE_GROUP:
			active.erase(k)


func remove(name: String) -> void:
	active.erase(name)


func has(name: String) -> bool:
	return active.has(name)


## Buff anahtarı -> ekranda görünen ad (yoksa anahtar)
const NAMES := {"summon_tank": "Çağrının Koruması", "beast": "Kuyruklu Canavar Pelerini", "bijuu_asit": "Asit (zayıf düştün)", "suna_tate": "Kum Kalkanı",
	"yoton_yoroi": "Lav Zırhı", "hane": "Kanat Hızı", "shindenshin_no_jin": "Zihin Ağı", "bubun_baika": "Kısmi Genişleme", "cho_baika": "Süper Genişleme",
	"karori": "Kalori Kontrolü", "cho_modo": "Kelebek Modu", "shikyaku": "Dört Ayak", "karamatsu": "Kemik Kalkanı", "gosuiwan": "Güçlü Kol",
	"henge_ash": "Kül Örtüsü", "hien": "Uçan Kırlangıç", "sameodori": "Köpekbalığı Dansı", "suna_no_yoroi": "Kum Zırhı", "sabaku_arashi": "Kum Fırtınası",
	"kakogan": "Dev Yumruk", "koka": "Sertleşme", "eyes": "Dōjutsu", "susanoo": "Susanoo", "nakil": "Göz Nakli (iyileşme)", "raiton_armor": "Yıldırım Zırhı",
	"henge": "Henge", "baika": "Genişleme", "bone_armor": "Kemik Zırhı", "suika": "Su Beden (Suika)", "kirigakure": "Sis Gizlenmesi", "entenka": "Ateş Kalkanı",
	"kusanagi": "Kusanagi", "juin1": "Lanetli Mühür I", "juin2": "Lanetli Mühür II", "hakuja": "Ak Yılan Sennin Modu", "yamata": "Sekiz Başlı Yılan",
	"gates": "Sekiz Kapı", "sage": "Sennin Modu", "susanoo_shield": "Susanoo Kalkanı", "uzmanlik": "Uzmanlık", "pill": "Asker Hapı", "shrine": "Tapınak Lütfu",
	"bbq": "Yakiniku Gücü", "kabutowari": "Zırh Kırıldı", "tapinak": "Tapınak Lütfu", "asker_hapi": "Asker Hapı"}
const DESCS := {"henge": "Düşmanlar seni fark etmez", "kirigakure": "Görünmezsin", "susanoo_shield": "Neredeyse tüm hasar engellenir"}
const LABELS := {"melee": "Yakın dövüş", "jutsu": "Jutsu hasarı", "speed": "Hız", "reach": "Menzil", "armor": "Alınan hasar", "katon": "Katon", "suiton": "Suiton", "fuuton": "Fūton", "raiton": "Raiton", "doton": "Doton"}


## "Yakın dövüş +30%, Hız +15%" — mods sözlüğünden; "_desc" ek açıklama
static func describe(mods: Dictionary) -> String:
	var parts = []
	for k in mods:
		if LABELS.has(k):
			var v = float(mods[k])
			parts.append("%s %s%d%%" % [LABELS[k], "+" if v >= 1.0 else "-", int(round(absf(v - 1.0) * 100.0))])
	if mods.has("_desc"):
		parts.append(String(mods["_desc"]))
	if mods.has("stealth") and not mods.has("_desc"):
		parts.append("Gizlisin")
	return ", ".join(parts)


## HUD satırları: [başlık, açıklama, kalan sn (-1 süresiz)]
func lines() -> Array:
	var out = []
	for n in active:
		var b = active[n]
		var d = describe(b["mods"])
		var base = n.split("_")[0] + "_"
		if d == "":
			d = DESCS.get(n, DESCS.get(base, ""))
		if d == "":
			continue
		var title = String(b["mods"].get("_name", NAMES.get(n, n.replace("_", " ").capitalize())))
		if n.begins_with("dome_"):
			title = "Kubbe Kalkanı"
		elif n.begins_with("stealth_"):
			title = "Gizlenme"
		elif n.begins_with("counter_"):
			title = "Karşı Koyma"
		out.append([title, d, float(b["t"]) if float(b["t"]) < 9000.0 else -1.0])
	return out


func mod(key: String) -> float:
	var v = 1.0
	for b in active.values():
		if b["mods"].has(key):
			v *= float(b["mods"][key])
	return v


func _process(dt: float) -> void:
	if Game.paused:
		return
	for k in active.keys():
		active[k]["t"] -= dt
		if active[k]["t"] <= 0.0:
			if k == "henge" and Game.player:
				Jutsu.end_henge(Game.player)
			active.erase(k)
