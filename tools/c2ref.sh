#!/bin/sh
# C2 ejderi referans karşılaştırması: sh tools/c2ref.sh v1 -> _tmp/c2/c2_v1_sheet.png
V=$1
cd "/d/Naruto 3D Game/godot" || exit 1
mkdir -p ../_tmp/c2
BAKE_ANY=1 VER=$V timeout 300 ../tools/Godot_v4.7.2-stable_win64_console.exe --position 9000,0 --audio-driver Dummy --resolution 1280x720 --path . -- --test=res://tests/test_c2_ref.gd "--shots=D:/Naruto 3D Game/_tmp/c2" 2>&1 | grep -E "SCRIPT ERROR|Parse Error" -A3 | head -20
cd ..
python -I - "$V" <<'PY'
import sys
from PIL import Image
V=sys.argv[1]; H=400
def fit(p):
    im=Image.open(p).convert("RGB"); return im.resize((int(im.width*H/im.height),H))
rows=[[fit("_tmp/ref/c2/C2_Dragon.png"),fit(f"_tmp/c2/c2_{V}_ref.png")],[fit("_tmp/ref/c2/C2_Guided_Missile.png"),fit(f"_tmp/c2/c2_{V}_front.png")],[fit("_tmp/ref/c2/C2_Mines.png"),fit(f"_tmp/c2/c2_{V}_face.png")],[fit(f"_tmp/c2/c2_{V}_side.png"),fit(f"_tmp/c2/c2_{V}_top.png")],]
W=max(sum(i.width for i in r)+6 for r in rows)
sh=Image.new("RGB",(W,(H+6)*len(rows)),(20,20,20))
for k,r in enumerate(rows):
    x=0
    for i in r: sh.paste(i,(x,k*(H+6))); x+=i.width+6
sh.save(f"_tmp/c2/c2_{V}_sheet.png"); print(sh.size)
PY
