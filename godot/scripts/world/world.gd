class_name GameWorld
extends Node3D
## Tüm dünyayı kurar: ortam, arazi, deniz, bitki örtüsü (akışlı), köyler, yerler, vahşi doğa akışı, trafik, hayvanlar.

var env: Node3D
var terrain: Node3D
var vegetation: Node3D
var water: MeshInstance3D
var road_map: Node        # yerel yol dokusu + küçük harita (RoadMap)
var stream: Node3D        # yapılar + vahşi doğa noktaları akışı


func build(progress: Callable = Callable()) -> void:
	Game.world = self
	env = preload("res://scripts/world/environment.gd").new()
	env.name = "Env"
	add_child(env)
	_p(progress, 0.1, "Gökyüzü ve ışık")
	road_map = preload("res://scripts/world/road_map.gd").new()
	road_map.name = "RoadMap"
	add_child(road_map)
	terrain = preload("res://scripts/world/terrain.gd").new()
	terrain.name = "Terrain"
	add_child(terrain)
	_p(progress, 0.2, "Arazi")
	_make_sea()
	await get_tree().process_frame
	vegetation = preload("res://scripts/world/vegetation.gd").new()
	vegetation.name = "Vegetation"
	add_child(vegetation)
	_p(progress, 0.45, "Ormanlar")
	await get_tree().process_frame
	var sites = Node3D.new()
	sites.name = "Sites"
	add_child(sites)
	BuildSites.build_all(sites)
	BuildVillageStory.build_all(sites)  # her büyük köyde hikâye binaları + Aranıyor panosu
	ContractRealms.build_all(sites)  # gizli sözleşme diyarları (kurbağa/yılan/sümüklüböcek) + köy sözleşme ustaları
	KgPaths.build_all(sites)  # keşiş kulübesi (Hyōton), volkan krateri (Yōton), toz tapınağı (Jinton)
	LegendPaths.build_all(sites)  # Efsane Yolları: ustaların inleri (yılan ini, demirhane...)
	_p(progress, 0.85, "Köyler")
	await get_tree().process_frame
	stream = preload("res://scripts/world/world_stream.gd").new()
	stream.name = "WorldStream"
	add_child(stream)
	_p(progress, 0.95, "Yollar, tapınaklar, kayalıklar")
	var grass = preload("res://scripts/world/grass.gd").new()
	grass.name = "Grass"
	add_child(grass)
	var amb = preload("res://scripts/world/ambience.gd").new()
	amb.name = "Ambience"
	add_child(amb)
	var traffic = preload("res://scripts/world/road_traffic.gd").new()
	traffic.name = "RoadTraffic"
	add_child(traffic)
	var wild = preload("res://scripts/world/wildlife.gd").new()
	wild.name = "Wildlife"
	add_child(wild)
	Game.apply_graphics.call_deferred()  # kalite ayarı (gölge, çimen, NPC yoğunluğu)


func _p(cb: Callable, v: float, label: String) -> void:
	if cb.is_valid():
		cb.call(v, label)


func _make_sea() -> void:
	water = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(60000, 60000)
	pm.subdivide_width = 240
	pm.subdivide_depth = 240
	water.mesh = pm
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/water.gdshader")
	water.material_override = m
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.custom_aabb = AABB(Vector3(-30000, -20, -30000), Vector3(60000, 40, 60000))
	add_child(water)


func _process(_dt: float) -> void:
	# deniz düzlemi kamerayla gelir (77 km dünya); dalga desenleri dünya koordinatında kayar, 250 m adımla kenetlenir
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var c = cam.global_position
	water.global_position = Vector3(snappedf(c.x, 250.0), 0.0, snappedf(c.z, 250.0))
	# kara içinde (yakında deniz seviyesine inen zemin yoksa) deniz düzlemi kapalı: Suna gibi yüksek çöl
	# zemininin üstüne turkuaz desen olarak biniyordu. Kıyıda / gölde yakın alçak zemin olduğundan görünür kalır.
	if Engine.get_process_frames() % 20 == 0:
		var low = Game.terrain_height(c.x, c.z) < 6.0
		if not low:
			for k in 8:
				var a = TAU * k / 8.0
				if Game.terrain_height(c.x + cos(a) * 700.0, c.z + sin(a) * 700.0) < 6.0:
					low = true
					break
		water.visible = low
	# ufuk: dev dünya için uzak kırpma düzlemi
	if cam.far < 32000.0:
		cam.far = 32000.0


func get_time_of_day() -> float:
	return env.time_of_day
