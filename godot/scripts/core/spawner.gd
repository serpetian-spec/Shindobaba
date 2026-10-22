extends Node
## Aktör oluşturma (autoload "Spawner"). Dünya kurulurken istekler sıraya alınır, oyun başlayınca yaratılır.

var pending: Array = []
var ready_to_spawn = false
## Karakter/kıyafet/saç sahneleri bellekte tutulur: referansı kalmayan glTF her NPC doğumunda
## diskten yeniden yükleniyordu (~120 ms takılma). Arka planda yüklenip burada saklanır.
const WARM_DIRS := ["res://assets/chars", "res://assets/chars/hair", "res://assets/anim"]
var cache: Dictionary = {}
var _loading: Array = []


func _ready() -> void:
	for d in WARM_DIRS:
		for f in ResourceLoader.list_directory(d):
			var path = d.path_join(f)
			if f.ends_with(".gltf") or f.ends_with(".glb") or f.ends_with(".png") or f.ends_with(".tres"):
				if ResourceLoader.load_threaded_request(path, "", true) == OK:
					_loading.append(path)
	for path in ["res://shaders/toon.gdshader"]:
		if ResourceLoader.load_threaded_request(path) == OK:
			_loading.append(path)


func _process(_dt: float) -> void:
	if _loading.is_empty():
		set_process(false)
		return
	for path in _loading.duplicate():
		var st = ResourceLoader.load_threaded_get_status(path)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			cache[path] = ResourceLoader.load_threaded_get(path)
			_loading.erase(path)
		elif st != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_loading.erase(path)


func dummy(pos: Vector3) -> void:
	pending.append(["dummy", pos])


func camp(pos: Vector3, kind: String, count: int) -> void:
	pending.append(["camp", pos, kind, count])


func flush(parent: Node3D) -> void:
	for p in pending:
		match p[0]:
			"dummy":
				var d = TrainingDummy.new()
				parent.add_child(d)
				d.global_position = p[1]
			"camp":
				for i in p[3]:
					var e = Enemy.new()
					e.setup(Enemy.archetype(p[2], i))
					parent.add_child(e)
					e.global_position = p[1] + Vector3(randf_range(-18, 18), 0, randf_range(-18, 18))
					e.home = e.global_position
	pending.clear()
