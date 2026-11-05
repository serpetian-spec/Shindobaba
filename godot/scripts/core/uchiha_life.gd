class_name UchihaLife
extends RefCounted
## Uchiha klan yaşamı (kanon, Narutopedia "Naka Shrine" / "Stone Tablet"):
## - Naka Tapınağı: ana salonda sağdan yedinci tataminin altındaki mühür taşı (ortasında Sharingan) — yalnız Uchiha ya da
##   Sharingan taşıyan açabilir; altında klanın gizli toplantı yeri.
## - Taş tablet: Altı Yol'un Bilgesi yazdı (sonradan Kara Zetsu bazı satırları değiştirdi). Sharingan ve Mangekyō KISMEN,
##   Rinnegan TAMAMEN okur. Okunan her katman günlüğe yazılır, profile kaydedilir (pr.flags.naka_read = en yüksek katman).


## Takılı/doğuştan gözlere göre okuma katmanı: 0 okuyamaz, 1 Sharingan, 2 Mangekyō/Ebedi, 3 Rinnegan
static func tablet_tier(pr: Dictionary) -> int:
	var best = 0
	var look: Dictionary = pr.get("look", {})
	for k in ["eye_r", "eye_l"]:
		var e = look.get(k)
		if e == null:
			continue
		var kind = int(e.get("kind", 0))
		best = maxi(best, {1: 1, 4: 2, 5: 2, 6: 3}.get(kind, 0))
	return best


static func can_open_seal(pr: Dictionary) -> bool:
	return String(pr.get("clan", "")) == "uchiha" or tablet_tier(pr) >= 1


static func interact(kind: String) -> void:
	var pr: Dictionary = Game.profile
	var inst = Interiors.inst
	match kind:
		"naka_tatami":
			if not can_open_seal(pr):
				Hud.dialog("Naka Tapınağı", "Tatamiyi kaldırdın: altında taş bir kapak var, ortasına Sharingan oyulmuş bir mühür. Mühür kıpırdamıyor — bu kapıyı yalnız Uchiha kanı ya da Sharingan açar.", [])
				return
			Hud.dialog("Naka Tapınağı", "Sağdan yedinci tatamiyi kaldırdın. Altında ortasında Sharingan oyulu mühür taşı var. Mühürleri yaptın; taş gürleyerek kaydı, aşağı inen merdiven göründü.", [
				{"label": "Gizli toplantı yerine in", "cb": func():
					Sfx.play("earth", Game.player.global_position, 0.7, 0.6)
					if inst:
						inst.goto_local(Interiors.NAKA_X, 4.0, 0.0, "Naka Tapınağı — Gizli Toplantı Yeri")},
				{"label": "Vazgeç", "cb": func(): pass}])
		"naka_up":
			if inst:
				inst.goto_local(-2.85, 7.2, 180.0, "Naka Tapınağı")
		"naka_tablet":
			read_tablet(pr)


static func read_tablet(pr: Dictionary) -> void:
	var tier = tablet_tier(pr)
	var flags: Dictionary = pr.get_or_add("flags", {})
	if tier == 0:
		Hud.dialog("Taş Tablet", "Taşın yüzü baştan aşağı oyulmuş yazıyla dolu, ama çizgiler gözünün önünde kayıyor; tek bir harfini bile seçemiyorsun. Bu yazı yalnız belirli gözlerle okunur.", [])
		return
	var pages: Array = [
		"[Sharingan ile] Satırların bir kısmı netleşiyor:\n\n\"Uchiha, Altı Yol'un Bilgesi'nin büyük oğlu Indra'nın soyudur.\"\n\n\"Mangekyō, insanın en yakınını kaybetmesinin acısıyla uyanır.\"\n\n\"Sharingan, sahibine ve çevresindekilere felaket getirebilir.\"\n\nGerisi gözünün önünde bulanık kalıyor.",
	]
	if tier >= 2:
		pages.append("[Mangekyō ile] Daha önce bulanık olan satırlar açılıyor:\n\n\"Mangekyō kullanıldıkça ışığını yitirir; sonunda karanlık gelir. Soydaşının Mangekyō'sunu alan için ışık bir daha sönmez.\"\n\n\"Mangekyō'nun gözü, kuyruklu canavarları bile boyun eğdirir.\"\n\nMadara'nın bedenine dair satırlar da var... ama tabletin en derin kısmı hâlâ kapalı.")
	if tier >= 3:
		pages.append("[Rinnegan ile] Taşın tamamı okunuyor:\n\n\"Tek bir tanrı denge arayışıyla yin ve yang'a bölündü; karşıt iki güç birlikte her şeyi var eder.\"\n\nKaguya'nın Tanrı Ağacı'nın meyvesini yiyişi, Altı Yol'un Bilgesi'nin On Kuyruk'u kendi bedenine mühürleyişi, Ay'ın doğuşu...\n\n\"Ay'a yansıyan göz — Mugen Tsukuyomi — Uchiha'yı kurtaracaktır.\"\n\nTuhaf: bu son satırın oyması ötekilerden daha yeni görünüyor.")
	if tier < 3:
		pages.append("Tabletin kalanı gözüne kapalı. %s" % ("Mangekyō uyandığında daha fazlasını okuyabilirsin." if tier == 1 else "Bütününü yalnız Rinnegan okuyabilir."))
	_page(pages, 0)
	var prev = int(flags.get("naka_read", 0))
	if tier > prev:
		flags["naka_read"] = tier
		var notes = {1: "Naka Tapınağı'nın altındaki taş tableti Sharingan ile okudum: Mangekyō en yakınını kaybetmenin acısıyla uyanırmış.",
			2: "Tabletin Mangekyō'yla açılan kısmı: ışığı sönmeyen göz için soydaşın Mangekyō'su gerekir; Mangekyō kuyruklu canavarlara boyun eğdirir.",
			3: "Tableti Rinnegan ile baştan sona okudum. Mugen Tsukuyomi'den söz eden satır ötekilerden yeni oyulmuş gibi..."}
		for k in range(prev + 1, tier + 1):
			Journal.add(String(notes[k]), "milestone")
		Hud.banner("UCHİHA TABLETİ", ["", "Sharingan ile okunan satırlar", "Mangekyō'nun sırları", "Tabletin tamamı"][tier], Color(0.85, 0.15, 0.15))
		Game.save_game()


static func _page(pages: Array, i: int) -> void:
	var opts: Array = []
	if i + 1 < pages.size():
		opts.append({"label": "Okumaya devam et", "cb": func(): _page(pages, i + 1)})
	Hud.dialog("Taş Tablet", String(pages[i]), opts)
