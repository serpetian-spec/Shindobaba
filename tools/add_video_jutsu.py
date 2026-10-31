"""Video referanslı eksik jutsuları godot/data/jutsu.json'a ekler / günceller (build_data.py artık eski; jutsu.json doğrudan genişletiliyor).
Liste: tools/video_jutsu_list.py içindeki VIDEO_JUTSU. İsim "Romaji (Türkçe anlam)" -> name + meaning.
  python tools/add_video_jutsu.py
"""
import json, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COST = [5, 10, 18, 28, 42, 60]
CD = [3, 4, 6, 9, 14, 22]
LEVEL = [1, 2, 5, 10, 18, 28]
NRANK = [0, 0, 1, 2, 3, 3]
SHAPE_K = {'projectile': (1.0, 1.0), 'melee': (0.8, 0.8), 'aoe': (1.2, 1.3), 'bind': (1.0, 1.4), 'summon': (1.8, 3.0), 'buff': (1.2, 2.2),
           'clone': (1.2, 1.6), 'wall': (0.9, 1.5), 'field': (1.3, 1.8), 'beam': (1.4, 1.4), 'trap': (0.8, 1.2), 'teleport': (0.5, 0.4),
           'mode': (1.8, 3.0), 'rush': (0.9, 0.8), 'counter': (0.8, 1.2)}
ns = {}
exec(open(os.path.join(ROOT, 'tools', 'video_jutsu_list.py'), encoding='utf-8').read(), ns)
p = os.path.join(ROOT, 'godot', 'data', 'jutsu.json')
raw = open(p, 'rb').read()
crlf = b'\r\n' in raw
data = json.loads(raw.decode('utf-8'))
n_new = 0
for (jid, nm, en, el, ti, shape, learn, need, desc, sl) in ns['VIDEO_JUTSU']:
    m = re.match(r'^(.*?)\s*\((.*)\)\s*$', nm)
    name, meaning = (m.group(1), m.group(2)) if m else (nm, '')
    ck, dk = SHAPE_K.get(shape, (1.0, 1.0))
    els = [x for x in el.split('+') if x]   # "raiton+suiton": iki elementi de bilmek gerekir
    e = dict(id=jid, name=name, name_en=en, cost=int(round(COST[ti] * ck)), cd=round(CD[ti] * dk, 1), element=els[0] if els else '',
             elements=els, natures=els, clan=learn[5:] if learn.startswith('clan:') else '', level=LEVEL[ti], rank=NRANK[ti], learn=learn,
             desc=desc, seals=sl, canon_rank='EDCBAS'[ti], tier=ti,
             category='senjutsu' if learn.startswith('sage') else ('taijutsu' if 'taijutsu' in learn else 'ninjutsu'), shape=shape)
    if need:
        e['need'] = need
    if meaning:
        e['meaning'] = meaning
    if jid not in data:
        n_new += 1
    data[jid] = e
# var olan jutsulara kanon koşulu (gereken mod / canavar / elementler): EXTRA = {id: {alan: değer}}
for jid, fields in ns.get('EXTRA', {}).items():
    if jid in data:
        data[jid].update(fields)
for jid in ns.get('REMOVE', []):
    data.pop(jid, None)
txt = json.dumps(data, ensure_ascii=False, indent=1)
if crlf:
    txt = txt.replace('\n', '\r\n')
open(p, 'wb').write(txt.encode('utf-8'))
print('video jutsu: %d yeni, toplam %d' % (n_new, len(data)))
