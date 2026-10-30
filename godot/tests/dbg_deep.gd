extends Node
## Daha derin dostluk: kişilik + konu seçimi, hediye tercihleri, antrenman, rütbe şartı, İlişkiler kartı
var main: Node


func _opts_labels(o: Array) -> Array:
	return o.map(func(x): return x["label"])


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 1
	Game.profile["ryo"] = 5000
	var v = ClanResident.new()
	v.clan = "nara"
	v.vid = "konoha"
	v.given = "Nara Shun"
	v.display_override = v.given
	v.role = "nurse"
	v.look_extra = ClanWorld.clan_look("nara", "chunin", "konoha", false, "adult")
	main.actors.add_child(v)
	v.global_position = pl.global_position + Vector3(2, 0, 0)
	await get_tree().create_timer(0.3).timeout
	Friends._meet(v)
	var id = String(v.get_meta("friend_id"))
	var f: Dictionary = Friends.all()[id]
	print("DEEP start bond=", f["bond"], " opts=", _opts_labels(Friends._friend_opts(id, v)))
	print("DEEP trait=", f["trait"], " like gift=", Friends.GIFTS[f["gift_like"]][0])
	# 3 sohbet (her konu bir kez): kişilik ortaya çıkar
	for k in 3:
		f["last_talk"] = 0.0
		var tp = Friends.TOPICS[k]
		var tr: Dictionary = Friends.TRAITS[f["trait"]]
		var b0 = int(f["bond"])
		f["last_talk"] = Time.get_unix_time_from_system()
		f["talks"] = int(f.get("talks", 0)) + 1
		var kind = "like" if tp[0] in tr["like"] else ("hate" if tp[0] in tr["hate"] else "neutral")
		Friends.add_bond(id, {"like": 5, "neutral": 1, "hate": -5}[kind], true)
		print("DEEP talk ", tp[0], " -> ", kind, " bond ", b0, "->", f["bond"])
	print("DEEP trait known=", Friends.trait_known(f))
	f["bond"] = 60
	f["rank"] = 2
	print("DEEP rank gate opts=", _opts_labels(Friends._friend_opts(id, v)))
	Game.profile["rank"] = 2
	print("DEEP rank ok opts=", _opts_labels(Friends._friend_opts(id, v)))
	f["gift_known"] = f["gift_like"]
	Menus.clear()
	Menus._friend_i = 0
	Menus.ninja_menu(main, "relations")
	await get_tree().create_timer(1.0).timeout
	await main.shot("deep_card")
	get_tree().quit()
