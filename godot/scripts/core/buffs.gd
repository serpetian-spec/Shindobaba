extends Node
## Oyuncu üzerindeki geçici etkiler (autoload "Buffs"): Raiton zırhı, Henge, asker hapı, Sennin modu...

var active = {}  # ad -> {t, mods}


func add(name: String, dur: float, mods: Dictionary) -> void:
	active[name] = {"t": dur, "mods": mods}


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
const LABELS := {"melee": "Yakın dövüş", "jutsu": "Jutsu hasarı", "speed": "Hız", "reach": "Menzil", "armor": "Alınan hasar"}


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
