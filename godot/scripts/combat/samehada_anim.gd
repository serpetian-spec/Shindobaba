class_name SamehadaAnim
## Kisame Samehada kombosu (kaynak: _tmp/ref_water/kisame.mp4 0:00-0:04, 10 fps kare kare).
## Her adım: süre, vuruş anı ve poz anahtarları. Yönler iskelet uzayında: +Z karakterin önü, +X karakterin solu, +Y yukarı.
## "blade": Samehada'nın uç yönü (silah bu yöne çevrilir); "b": kemik -> yön; crouch/yaw/spine/neck: gövde.

const LEG_WIDE := {"LeftUpperLeg": Vector3(0.22, -1, 0.05), "LeftLowerLeg": Vector3(0.05, -1, 0.0), "LeftFoot": Vector3(0.05, -0.45, 0.9),
	"RightUpperLeg": Vector3(-0.22, -1, 0.05), "RightLowerLeg": Vector3(-0.05, -1, 0.0), "RightFoot": Vector3(-0.05, -0.45, 0.9)}
# sağ ayak önde derin hamle (videoda itiş/vuruş anları)
const LEG_LUNGE := {"RightUpperLeg": Vector3(-0.2, -0.35, 0.92), "RightLowerLeg": Vector3(-0.05, -1, -0.05), "RightFoot": Vector3(-0.05, -0.4, 0.92),
	"LeftUpperLeg": Vector3(0.22, -0.6, -0.77), "LeftLowerLeg": Vector3(0.1, -0.75, -0.65), "LeftFoot": Vector3(0.1, -0.9, 0.4)}


static func _k(t: float, crouch: float, yaw: float, spine: float, blade: Vector3, arms: Dictionary, legs: Dictionary) -> Dictionary:
	if legs == LEG_LUNGE:
		crouch = maxf(crouch, 0.85)   # videoda Kisame hamlelerde çok alçak (uyluk yataya yakın) ve gövde öne eğik
		spine = spine * 1.6
	# gövde eğimi kemik yönüyle (öne eğilme açısı): bel < göğüs, kafa ileri bakar
	var lean = deg_to_rad(spine)
	var b = {}   # sıra önemli: önce gövde, sonra kollar/bacaklar (gövde dönünce kol yönleri bozulmasın)
	b["Spine"] = Vector3(0, cos(lean * 0.6), sin(lean * 0.6))
	b["Chest"] = Vector3(0, cos(lean), sin(lean))
	b["Neck"] = Vector3(0, cos(lean * 0.5), sin(lean * 0.5))
	b["Head"] = Vector3(0, 1, 0.05)
	b.merge(arms)
	b.merge(legs)
	return {"t": t, "crouch": crouch, "hips_yaw": yaw, "spine": 0.0, "neck": 0.0, "blade": blade, "b": b}


static func steps() -> Array:
	return [
		# 1 (0.5-1.5, sırttan alma yok): kılıç arkada sarkarak atılış, alçak hamlede kılıcı yatay ileri sokup matkap gibi tutar, geri çeker
		{"len": 0.88, "hit": 0.15, "keys": [
			_k(0.0, 0.5, -15, 30, Vector3(-0.35, -0.3, -0.88), {"RightUpperArm": Vector3(-0.35, -0.75, -0.55), "RightLowerArm": Vector3(-0.25, -0.6, -0.75),
				"LeftUpperArm": Vector3(0.3, -0.4, 0.85), "LeftLowerArm": Vector3(0.1, -0.2, 0.97)}, LEG_LUNGE),
			_k(0.14, 0.62, 15, 22, Vector3(0.0, 0.0, 1.0), {"RightUpperArm": Vector3(-0.15, -0.08, 1), "RightLowerArm": Vector3(-0.03, 0.0, 1),
				"LeftUpperArm": Vector3(0.12, -0.15, 1), "LeftLowerArm": Vector3(-0.3, 0.0, 0.95)}, LEG_LUNGE),
			_k(0.68, 0.62, 15, 22, Vector3(0.03, 0.03, 1.0), {"RightUpperArm": Vector3(-0.13, -0.05, 1), "RightLowerArm": Vector3(-0.03, 0.02, 1),
				"LeftUpperArm": Vector3(0.12, -0.12, 1), "LeftLowerArm": Vector3(-0.3, 0.02, 0.95)}, LEG_LUNGE),
			_k(0.88, 0.3, 0, 8, Vector3(-0.1, 0.45, 0.88), {"RightUpperArm": Vector3(-0.5, -0.4, 0.75), "RightLowerArm": Vector3(-0.2, 0.3, 0.93),
				"LeftUpperArm": Vector3(0.6, -0.6, 0.5), "LeftLowerArm": Vector3(0.3, -0.4, 0.85)}, LEG_WIDE),
		]},
		# 2 (1.5-1.9): kılıcı başın üstünden arkaya kaldırır, öne-aşağı çapraz indirir
		{"len": 0.55, "hit": 0.28, "keys": [
			_k(0.0, 0.2, -10, -10, Vector3(0.0, 0.55, -0.83), {"RightUpperArm": Vector3(-0.3, 0.85, 0.25), "RightLowerArm": Vector3(-0.1, 0.6, -0.8),
				"LeftUpperArm": Vector3(0.65, -0.3, 0.7), "LeftLowerArm": Vector3(0.3, -0.1, 0.95)}, LEG_WIDE),
			_k(0.13, 0.25, -20, -12, Vector3(0.3, -0.45, -0.84), {"RightUpperArm": Vector3(-0.2, 0.95, -0.15), "RightLowerArm": Vector3(0.1, 0.35, -0.93),
				"LeftUpperArm": Vector3(0.7, -0.2, 0.68), "LeftLowerArm": Vector3(0.4, 0.0, 0.92)}, LEG_WIDE),
			_k(0.28, 0.55, 20, 30, Vector3(0.1, -0.45, 0.88), {"RightUpperArm": Vector3(-0.25, -0.3, 0.92), "RightLowerArm": Vector3(-0.1, -0.4, 0.9),
				"LeftUpperArm": Vector3(0.6, -0.5, -0.6), "LeftLowerArm": Vector3(0.3, -0.6, -0.75)}, LEG_LUNGE),
			_k(0.55, 0.5, 25, 28, Vector3(0.45, -0.6, 0.66), {"RightUpperArm": Vector3(-0.05, -0.5, 0.86), "RightLowerArm": Vector3(0.2, -0.5, 0.84),
				"LeftUpperArm": Vector3(0.6, -0.5, -0.6), "LeftLowerArm": Vector3(0.3, -0.6, -0.75)}, LEG_LUNGE),
		]},
		# 3 (2.0-2.4): sağdan sola alçak yatay süpürme, gövde öne eğilip sola döner
		{"len": 0.5, "hit": 0.22, "keys": [
			_k(0.0, 0.3, -35, 10, Vector3(-1.0, 0.15, 0.1), {"RightUpperArm": Vector3(-1, 0.0, 0.1), "RightLowerArm": Vector3(-0.9, 0.05, 0.4),
				"LeftUpperArm": Vector3(0.5, -0.4, 0.75), "LeftLowerArm": Vector3(0.2, -0.2, 0.95)}, LEG_WIDE),
			_k(0.22, 0.5, 0, 25, Vector3(0.0, -0.1, 1.0), {"RightUpperArm": Vector3(-0.3, -0.15, 0.94), "RightLowerArm": Vector3(-0.05, -0.1, 1),
				"LeftUpperArm": Vector3(0.7, -0.5, -0.4), "LeftLowerArm": Vector3(0.4, -0.6, -0.6)}, LEG_LUNGE),
			_k(0.5, 0.6, 35, 32, Vector3(0.9, -0.35, 0.2), {"RightUpperArm": Vector3(0.3, -0.25, 0.9), "RightLowerArm": Vector3(0.8, -0.15, 0.55),
				"LeftUpperArm": Vector3(0.75, -0.45, -0.45), "LeftLowerArm": Vector3(0.45, -0.6, -0.6)}, LEG_LUNGE),
		]},
		# 4 (2.5-2.9): dik durup kılıcı sağ omuzdan yukarı-arkaya kaldırır (sol kol öne), tepeden geçirip baş hizasında öne vurur (büyük parlama)
		{"len": 0.6, "hit": 0.32, "keys": [
			_k(0.0, 0.1, -15, -15, Vector3(0.1, 0.6, -0.8), {"RightUpperArm": Vector3(-0.25, 0.9, -0.3), "RightLowerArm": Vector3(0.0, 0.4, -0.92),
				"LeftUpperArm": Vector3(0.3, 0.0, 1), "LeftLowerArm": Vector3(0.1, 0.0, 1)}, LEG_WIDE),
			_k(0.18, 0.15, -10, -12, Vector3(0.0, 1.0, 0.05), {"RightUpperArm": Vector3(-0.2, 1, 0.1), "RightLowerArm": Vector3(-0.1, 1, 0.0),
				"LeftUpperArm": Vector3(0.3, 0.05, 1), "LeftLowerArm": Vector3(0.1, 0.05, 1)}, LEG_WIDE),
			_k(0.32, 0.5, 15, 25, Vector3(0.0, 0.05, 1.0), {"RightUpperArm": Vector3(-0.15, 0.15, 1), "RightLowerArm": Vector3(-0.05, 0.05, 1),
				"LeftUpperArm": Vector3(0.6, -0.4, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}, LEG_LUNGE),
			_k(0.6, 0.5, 18, 28, Vector3(0.05, -0.2, 1.0), {"RightUpperArm": Vector3(-0.12, 0.05, 1), "RightLowerArm": Vector3(-0.03, -0.1, 1),
				"LeftUpperArm": Vector3(0.6, -0.45, -0.6), "LeftLowerArm": Vector3(0.3, -0.5, -0.8)}, LEG_LUNGE),
		]},
		# 5 (3.0-3.9): kılıç sağ-yukarıda, dönerek alçak süpürme, sonra aşağıdan yukarı savurup rakibi havaya fırlatır, biter (sırta koyma yok)
		{"len": 0.62, "hit": 0.5, "keys": [
			_k(0.0, 0.2, 0, 0, Vector3(-0.5, 0.8, 0.2), {"RightUpperArm": Vector3(-0.5, 0.8, 0.2), "RightLowerArm": Vector3(-0.4, 0.9, 0.0),
				"LeftUpperArm": Vector3(0.6, -0.4, 0.65), "LeftLowerArm": Vector3(0.3, -0.2, 0.93)}, LEG_WIDE),
			_k(0.2, 0.5, -70, 30, Vector3(-0.9, -0.3, -0.3), {"RightUpperArm": Vector3(-0.95, -0.3, 0.0), "RightLowerArm": Vector3(-0.9, -0.3, -0.3),
				"LeftUpperArm": Vector3(0.8, -0.3, 0.5), "LeftLowerArm": Vector3(0.5, -0.2, 0.85)}, LEG_LUNGE),
			_k(0.4, 0.7, 0, 32, Vector3(0.0, -0.5, 0.86), {"RightUpperArm": Vector3(-0.2, -0.6, 0.78), "RightLowerArm": Vector3(-0.05, -0.55, 0.83),
				"LeftUpperArm": Vector3(0.7, -0.5, -0.5), "LeftLowerArm": Vector3(0.4, -0.6, -0.7)}, LEG_LUNGE),
			_k(0.5, 0.3, 10, -10, Vector3(-0.1, 0.95, 0.3), {"RightUpperArm": Vector3(-0.2, 0.95, 0.2), "RightLowerArm": Vector3(-0.1, 1, 0.1),
				"LeftUpperArm": Vector3(0.7, -0.5, -0.5), "LeftLowerArm": Vector3(0.4, -0.6, -0.7)}, LEG_WIDE),
			_k(0.62, 0.3, 8, -5, Vector3(-0.15, 0.85, 0.5), {"RightUpperArm": Vector3(-0.25, 0.85, 0.45), "RightLowerArm": Vector3(-0.1, 0.9, 0.4),
				"LeftUpperArm": Vector3(0.7, -0.5, -0.5), "LeftLowerArm": Vector3(0.4, -0.6, -0.7)}, LEG_WIDE),
		]},
	]
