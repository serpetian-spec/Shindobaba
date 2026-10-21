class_name GameWorld
extends Node3D
## Tüm dünyayı kurar: ortam, arazi, deniz, bitki örtüsü, köyler, yerler.

var env: Node3D
var terrain: Node3D
var vegetation: Node3D
var water: MeshInstance3D


func build(progress: Callable = Callable()) -> void:
	Game.world = self
	env = preload("res://scripts/world/environment.gd").new()
	env.name = "Env"
	add_child(env)
	_p(progress, 0.1, "Gökyüzü ve ışık")
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
	_p(progress, 0.95, "Köyler")


func _p(cb: Callable, v: float, label: String) -> void:
	if cb.is_valid():
		cb.call(v, label)


func _make_sea() -> void:
	water = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(12000, 12000)
	pm.subdivide_width = 200
	pm.subdivide_depth = 200
	water.mesh = pm
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/water.gdshader")
	water.material_override = m
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	water.position = Vector3(250, 0.0, -640)


func get_time_of_day() -> float:
	return env.time_of_day
