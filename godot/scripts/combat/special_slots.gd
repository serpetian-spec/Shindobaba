class_name SpecialSlots
extends RefCounted
## Göz (dōjutsu) ve kuyruklu canavar teknikleri jutsu slotlarına konabilir: Data.jutsu'ya sanal girdiler
## ("virtual": "eye:sag" / "eye:sol" / "bijuu:0..2"). Slottan basınca ilgili sistem tetiklenir; gerekli durum
## (gözler açık / pelerin seviyesi) yoksa atmaz ve sebebini söyler. Eskiden Z/X ve R/T/C tuşlarına bağlıydı.

const EYE_IDS := ["goz_sag", "goz_sol"]
const BIJUU_IDS := ["bijuu_t0", "bijuu_t1", "bijuu_t2"]
const SUS_IDS := ["susanoo_t0", "susanoo_t1", "susanoo_t2"]


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
	var mt = Susanoo.max_tier(pr)
	for i in 3:
		var id = SUS_IDS[i]
		var td: Array = Susanoo.TECHS[i]
		if mt >= int(td[3]):
			Data.jutsu[id] = {"name": String(td[0]), "cost": int(td[1]), "cd": float(td[2]), "element": "", "category": "dojutsu", "canon_rank": "S",
				"seals": [], "virtual": "susanoo:%d" % i, "desc": "Susanoo tekniği. Susanoo açıkken (V basılı) ve en az %s kademesinde slottan kullanılır." % Susanoo.TIER_NAMES[int(td[3])]}
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
	if v.begins_with("susanoo:") and m.eyes and m.eyes.susanoo and is_instance_valid(m.eyes.susanoo_node):
		return float(m.eyes.susanoo_node.tech_cd[int(v.substr(8))])
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
	if v.begins_with("susanoo:"):
		var i = int(v.substr(8))
		var ey: Eyes = m.eyes
		var td: Array = Susanoo.TECHS[i]
		if ey == null or not ey.susanoo or not is_instance_valid(ey.susanoo_node):
			Hud.msg("%s için önce Susanoo'yu aç (V basılı)." % td[0], Color(0.75, 0.6, 1.0))
			return true
		var sn: Susanoo = ey.susanoo_node
		if sn.tier < int(td[3]):
			Hud.msg("%s için en az %s kademesi gerekli." % [td[0], Susanoo.TIER_NAMES[int(td[3])]], Color(0.75, 0.6, 1.0))
			return true
		if sn.tech_cd[i] > 0.0:
			Hud.msg("%s hazır değil (%.0f sn)" % [td[0], sn.tech_cd[i]], Color(0.9, 0.8, 0.6))
			return true
		if p.chakra < float(td[1]):
			Hud.msg("Yeterli chakra yok.", Color(0.6, 0.7, 1))
			return true
		p.chakra -= float(td[1])
		sn.tech_cd[i] = float(td[2])
		var lt = p.combat.lock_target
		var aim = lt.global_position if lt and is_instance_valid(lt) and not lt.is_dead() else p.aim_point()
		sn.tech(p, i, aim)
		Combat.popup_text(p.global_position + Vector3.UP * Susanoo.TIER_HEIGHT[sn.tier] * 0.9, td[0], sn.color())
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
