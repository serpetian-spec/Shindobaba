"""Jutsu hasar dengesi: tests/dbg_jdmg.gd ölçümünden (güç=1 atıcı, 7 sn toplam hasar) data/balance.json çarpanları.
Her jutsunun toplam hasarı kademesinin hedefine çekilir; jutsunun kendi karakterinden biraz kalır (üs 0.85).
  python tools/balance.py [_tmp/jutsu_dmg.json]
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, '_tmp', 'jutsu_dmg.json')
TARGET = [14.0, 22.0, 34.0, 50.0, 72.0, 100.0]   # kademe (E..S) başına bir atışın toplam hasarı (güç 1)
KEEP = 0.85
LO, HI = 0.3, 1.8

m = json.load(open(src, encoding='utf-8'))
out = {}
rows = []
for jid, r in m.items():
    d = float(r['dmg'])
    if d <= 0.5:
        continue
    t = max(0, min(5, int(r['tier'])))
    if d < TARGET[t] * 0.25:
        continue   # büyük olasılıkla ıskaladı (kukla ölçümü): güçlendirme yapma
    f = (TARGET[t] / d) ** KEEP
    f = max(LO, min(HI, f))
    if abs(f - 1.0) < 0.05:
        continue
    out[jid] = round(f, 3)
    rows.append((f, jid, t, d))
json.dump(out, open(os.path.join(ROOT, 'godot', 'data', 'balance.json'), 'w', encoding='utf-8'), indent=0, sort_keys=True)
rows.sort()
print('ölçülen', len(m), 'hasarlı', sum(1 for r in m.values() if r['dmg'] > 0.5), 'ayarlanan', len(out))
for f, jid, t, d in rows[:8] + rows[-8:]:
    print('%-40s kademe %d  ölçülen %7.1f  çarpan %.2f' % (jid, t, d, f))
