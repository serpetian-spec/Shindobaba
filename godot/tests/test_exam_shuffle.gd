extends Node
## Yazılı sınav şıkları karışıyor mu: doğru cevap A/B/C/D'ye dağılmalı, doğru metin korunmalı
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	for name in ["ACADEMY", "CHUNIN"]:
		var pool: Array = Exams.ACADEMY_Q if name == "ACADEMY" else ChuninExam.QUIZ
		var cnt = [0, 0, 0, 0, 0]
		var orig_first = 0
		var bad = 0
		var dup = 0
		for q in pool:
			if int(q[2]) == 0:
				orig_first += 1
			var o: Array = q[1]
			for x in o:
				if o.count(x) > 1:
					dup += 1
		for r in 200:
			for q in ExamUI.shuffle_options(pool):
				cnt[int(q[2])] += 1
			for i in pool.size():
				var nq = ExamUI.shuffle_options([pool[i]])[0]
				if String(nq[1][int(nq[2])]) != String(pool[i][1][int(pool[i][2])]):
					bad += 1
		print("EXAM %s sorular=%d (orijinalde doğru=A: %d) dağılım A..E=%s yanlış_eşleşme=%d tekrar_şık=%d" % [name, pool.size(), orig_first, cnt, bad, dup])
	get_tree().quit()
