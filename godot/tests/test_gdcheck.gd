extends Node
## Sözdizimi denetimi: tüm betikleri yükler (derleme hatası varsa motor "Parse Error" yazar) ve çıkar. Oyun başlatılmaz.
## Kullanım: python tools/gdcheck.py   (testleri de denetlemek için: python tools/gdcheck.py tests)
var main: Node
func _ready() -> void:
	var n = 0
	var t_start = Time.get_ticks_msec()
	var stack = ["res://scripts"]
	if "--gdc-tests" in OS.get_cmdline_user_args():
		stack.append("res://tests")   # eski testler bozuk olabilir: yalnız istenince
	while not stack.is_empty():
		var d: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(d):
			stack.append(d + "/" + sub)
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var s = load(d + "/" + f)
				n += 1
				if s == null or not (s is GDScript) or not (s as GDScript).can_instantiate():
					print("GDCHECK HATA ", d + "/" + f)
	print("GDCHECK betik=%d acilis=%d ms yukleme=%d ms" % [n, t_start, Time.get_ticks_msec() - t_start])
	get_tree().quit()
