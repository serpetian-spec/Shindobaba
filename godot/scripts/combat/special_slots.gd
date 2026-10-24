class_name SpecialSlots
extends RefCounted
## Göz (dōjutsu) ve kuyruklu canavar teknikleri jutsu slotlarına konabilir: Data.jutsu'ya sanal girdiler
## ("virtual": "eye:sag" / "eye:sol" / "bijuu:0..2"). Slottan basınca ilgili sistem tetiklenir; gerekli durum
## (gözler açık / pelerin seviyesi) yoksa atmaz ve sebebini söyler. Eskiden Z/X ve R/T/C tuşlarına bağlıydı.

const EYE_IDS := ["goz_sag", "goz_sol"]
const BIJUU_IDS := ["bijuu_t0", "bijuu_t1", "bijuu_t2"]


## Oyuncunun şu an sahip olduğu özel teknikleri Data.jutsu'ya yazar; artık sahip olmadıklarını siler. Kimlik listesi döner.
static func refresh(pr: Dictionary) -> Array:
	var out: Array = []
	for i in 2:
		var side = "sag" if i == 0 else "sol"
		var slot = "sag_goz" if i == 0 else "sol_goz"
		var g = Gear.equipped(pr, slot)
		var k = 0 if g.is_empty() else int(Gear.item(g["id"]).get("eye", {}).get("kind", 0))
		var id = EYE_IDS[i]
		if k > 0 and Eyes.SKILLS.has(k):
			var sk: Array = Eyes.SKILLS[k][i]
			Data.jutsu[id] = {"name": "%s (%s göz)" % [sk[0], "sağ" if i == 0 else "sol"], "cost": int(sk[1]), "cd": float(sk[2]), "element": "",
				"category": "dojutsu", "canon_rank": "S" if k >= 4 else "A", "seals": [], "virtual": "eye:" + side,
				"desc": "%s gözünün tekniği. Gözler açıkken (V) slottan kullanılır." % Eyes.KINDS.get(k, "Göz")}
			out.append(id)
		else:
			Data.jutsu.erase(id)
	var bid = TailedBeasts.player_jinchuriki() if TailedBeasts else ""
	var tl: Array = BijuuArts.techs(bid) if bid != "" else []
	for i in 3:
		var id = BIJUU_IDS[i]
		if i < tl.size():
			var t: Dictionary = tl[i]
			Data.jutsu[id] = {"name": String(t["name"]), "cost": int(t.get("cost", 0)), "cd": float(t.get("cd", 6.0)), "element": "",
				"category": "bijuu", "canon_rank": "S", "seals": [], "virtual": "bijuu:%d" % i,
				"desc": "%s tekniği. Jinchūriki pelerini (X) en az %s iken slottan kullanılır." % [String(BeastModels.INFO.get(bid, {}).get("name", bid)).split(" — ")[0], BeastCloak.NAMES[BeastCloak.TECH_NEED[i]]]}
			out.append(id)
		else:
			Data.jutsu.erase(id)
	return out


## Sanal tekniğin kalan bekleme süresi (HUD slot göstergesi)
static func cooldown(p: Player, jid: String) -> float:
	var v = String(Data.jutsu.get(jid, {}).get("virtual", ""))
	var m = p.combat.modes if p and p.combat else null
	if m == null:
		return 0.0
	if v.begins_with("eye:") and m.eyes:
		return float(m.eyes.cd.get(v.substr(4), 0.0))
	if v.begins_with("bijuu:") and m.cloak:
		var l = BijuuArts.techs(m.cloak.beast_id())
		var i = int(v.substr(6))
		if i < l.size():
			return float(m.cloak.tech_cd.get(l[i]["key"], 0.0))
	return 0.0


## Slottan sanal teknik kullan: true = ele alındı (normal jutsu akışı çalışmaz)
static func cast(p: Player, jid: String) -> bool:
	var j: Dictionary = Data.jutsu.get(jid, {})
	var v = String(j.get("virtual", ""))
	if v == "":
		return false
	var m = p.combat.modes if p.combat else null
	if m == null:
		return true
	if v.begins_with("eye:"):
		var ey: Eyes = m.eyes
		if ey == null or not ey.active:
			Hud.msg("%s için önce gözlerini aç (V)." % String(j["name"]).split(" (")[0], Color(1, 0.55, 0.5))
			return true
		ey.use_skill(v.substr(4))
		return true
	if v.begins_with("bijuu:"):
		var cl: BeastCloak = m.cloak
		var i = int(v.substr(6))
		if cl == null or cl.level <= 0:
			Hud.msg("%s için önce chakra pelerinini aç (X)." % String(j["name"]), Color(1, 0.7, 0.4))
			return true
		cl._tech(i)
		return true
	return true
