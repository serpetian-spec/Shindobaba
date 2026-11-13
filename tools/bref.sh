#!/bin/sh
# Canavar referans karşılaştırması: sh tools/bref.sh gyuki v1 ref1.png ref2.png ref3.png
#  -> Ekran görüntüleri/<canavar>_<sürüm>_karsilastirma.png (+ front/face/side/back)
B=$1; V=$2; shift 2
cd "/d/Naruto 3D Game/godot" || exit 1
BEAST=$B VER=$V timeout 400 ../tools/Godot_v4.7.2-stable_win64_console.exe --log-file "D:/Naruto 3D Game/_tmp/test_godot.log" --position -5000,-5000 --audio-driver Dummy --path . -- --test=res://tests/test_beast_ref.gd "--shots=D:/Naruto 3D Game/_tmp/kv" 2>&1 | grep -E "SCRIPT ERROR|Parse" -A3 | head
cd ..
ARGS=""
i=0
for s in front face side; do
	i=$((i + 1))
	eval R=\${$i}
	[ -n "$R" ] && ARGS="$ARGS $R _tmp/kv/${B}_${V}_$s.png"
done
python -I tools/ref_compare.py "Ekran görüntüleri/${B}_${V}_karsilastirma.png" $ARGS > /dev/null
for s in front face side back; do cp _tmp/kv/${B}_${V}_$s.png "Ekran görüntüleri/${B}_${V}_$s.png"; done
echo "Ekran görüntüleri/${B}_${V}_karsilastirma.png"
