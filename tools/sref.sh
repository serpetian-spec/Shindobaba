#!/bin/sh
# Çağrı referans karşılaştırması: sh tools/sref.sh toad_boss 17 17 v1 ref1.png ref2.png ref3.png
M=$1; H=$2; LN=$3; V=$4; shift 4
cd "/d/Naruto 3D Game/godot" || exit 1
MODEL=$M H=$H LEN=$LN VER=$V timeout 400 ../tools/Godot_v4.7.2-stable_win64_console.exe --position -5000,-5000 --audio-driver Dummy --path . -- --test=res://tests/test_summon_ref.gd "--shots=D:/Naruto 3D Game/_tmp/kv" 2>&1 | grep -E "SCRIPT ERROR|Parse" -A3 | head
cd ..
ARGS=""
i=0
for s in front face side; do
	i=$((i + 1))
	eval R=\${$i}
	[ -n "$R" ] && ARGS="$ARGS $R _tmp/kv/${M}_${V}_$s.png"
done
python -I tools/ref_compare.py "Ekran görüntüleri/${M}_${V}_karsilastirma.png" $ARGS > /dev/null
for s in front face side back; do cp _tmp/kv/${M}_${V}_$s.png "Ekran görüntüleri/${M}_${V}_$s.png"; done
echo "Ekran görüntüleri/${M}_${V}_karsilastirma.png"
