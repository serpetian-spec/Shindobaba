#!/bin/sh
# Kurama referans karşılaştırması: sh tools/kref.sh v12  -> Ekran görüntüleri/kurama_v12_*.png
V=$1
ROOT="$(cd "$(dirname "$0")/.." && pwd -W)"
cd "$ROOT/godot" || exit 1
VER=$V timeout 400 ../tools/Godot_v4.7.2-stable_win64_console.exe --log-file "$ROOT/_tmp/test_godot.log" --position -5000,-5000 --audio-driver Dummy --path . -- --test=res://tests/test_kurama_ref.gd "--shots=$ROOT/_tmp/kv" 2>&1 | grep -E "SCRIPT ERROR|Parse" -A3 | head
cd ..
R=_tmp/ref/kurama
python -I tools/ref_compare.py "Ekran görüntüleri/kurama_${V}_karsilastirma.png" $R/Kurama2.png _tmp/kv/k_${V}_front.png $R/Kurama_Stares_Down.png _tmp/kv/k_${V}_face.png $R/Kurama_Sealed.png _tmp/kv/k_${V}_side.png > /dev/null
for s in front face side back; do cp _tmp/kv/k_${V}_$s.png "Ekran görüntüleri/kurama_${V}_$s.png"; done
echo "Ekran görüntüleri/kurama_${V}_karsilastirma.png"
