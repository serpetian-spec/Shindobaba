#!/bin/sh
# Açık geliştirme sunucusuna komut gönder: tools/dev.sh komut.gd  (sunucu yoksa önce: tools/dev.sh start)
D="/d/Naruto 3D Game/_tmp/dev"
cd "/d/Naruto 3D Game"
case "$1" in
  start)
    mkdir -p "$D"; rm -f "$D/ready.txt" "$D/done.txt" "$D/cmd.gd"
    nohup tools/Godot_v4.7.2-stable_win64_console.exe --log-file "D:/Naruto 3D Game/_tmp/test_godot.log" --path godot --audio-driver Dummy -- --test=res://tests/dev_server.gd "--shots=D:/Naruto 3D Game/_tmp/shots/dev" > "$D/log.txt" 2>&1 &
    i=0; while [ ! -f "$D/ready.txt" ] && [ $i -lt 240 ]; do sleep 1; i=$((i+1)); done
    echo "sunucu hazir ($i sn)";;
  stop)
    echo quit > "$D/cmd.gd";;
  *)
    rm -f "$D/done.txt"; n0=$(wc -l < "$D/log.txt")
    cp "$1" "$D/cmd.gd"
    i=0; while [ ! -f "$D/done.txt" ] && [ $i -lt 300 ]; do sleep 1; i=$((i+1)); done
    echo "[$(cat "$D/done.txt" 2>/dev/null || echo zaman_asimi)]"
    tail -n +$((n0+1)) "$D/log.txt" | grep -v "Unreferenced\|at: unref\|UVs are required\|generate_tangents\|GDScript backtrace\|^\s*\[[0-9]\]" ;;
esac
