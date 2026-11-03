"""Oyundaki jutsuların kanon olup olmadığını Naruto Fandom'dan doğrular.
Her jutsu adı (romaji) için wiki araması yapılır; dönen sayfaların bilgi kutusundaki romaji/kanji adıyla
karşılaştırılır. Sonuç: _tmp/canon_check.json  {id: {"canon": bool, "page": str, "name": str}}
Önbellekli (tekrar çalıştırınca kaldığı yerden)."""
import json, io, os, re, sys, time, unicodedata, urllib.parse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "_tmp", "canon_check.json")
API = "https://naruto.fandom.com/api.php"
UA = {"User-Agent": "NarutoFanGameCanonCheck/1.0"}


def norm(s):
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    s = s.lower()
    s = re.sub(r"\(.*?\)", "", s)
    s = re.sub(r"no jutsu$", "", s.strip())
    return re.sub(r"[^a-z]", "", s)


PRE = ["katon", "suiton", "futon", "fuuton", "raiton", "doton", "enton", "hyoton", "mokuton", "yoton", "futton", "jiton", "bakuton",
	"shakuton", "ranton", "jinton", "meiton", "inton", "yinton", "yangton", "onmyoton", "susanoo", "sharingan", "magen", "genjutsu",
	"ninpo", "kuchiyosenojutsu", "kuchiyose", "hiden", "senpo", "fuinjutsu", "fuin", "kinjutsu", "hijutsu"]


def strip_pre(s):
    changed = True
    while changed:
        changed = False
        for p in PRE:
            if s.startswith(p) and len(s) > len(p) + 3:
                s = s[len(p):]
                changed = True
    return s


def get(params):
    params["format"] = "json"
    url = API + "?" + urllib.parse.urlencode(params)
    for k in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=20) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception:
            time.sleep(1.5)
    return {}


def romaji_of(title):
    d = get({"action": "parse", "page": title, "prop": "wikitext", "redirects": 1})
    w = d.get("parse", {}).get("wikitext", {}).get("*", "")
    names = []
    for key in ["romaji", "kanji", "unnamed jutsu", "english tv", "viz manga"]:
        for m in re.finditer(r"\|\s*" + key + r"\s*=\s*([^\n|]+)", w, re.I):
            names.append(m.group(1))
    return names, w[:200]


def check(name, jid):
    base = re.sub(r"\(.*?\)", "", name).strip()
    target = norm(base)
    if not target:
        return {"canon": False, "page": "", "why": "boş ad"}
    d = get({"action": "query", "list": "search", "srsearch": base, "srlimit": 5})
    titles = [r["title"] for r in d.get("query", {}).get("search", [])]
    for t in titles[:4]:
        names, _ = romaji_of(t)
        for n in names:
            nn = norm(n)
            if nn and (nn == target or strip_pre(nn) == strip_pre(target)):
                return {"canon": True, "page": t, "match": n.strip()}
    return {"canon": False, "page": titles[0] if titles else "", "why": "romaji eşleşmedi"}


def main():
    game = json.load(io.open(os.path.join(ROOT, "godot", "data", "jutsu.json"), encoding="utf-8"))
    full = json.load(io.open(os.path.join(ROOT, "research", "jutsu_full.json"), encoding="utf-8"))["jutsu"]
    known = {x["id"] for x in full}
    res = json.load(io.open(OUT, encoding="utf-8")) if os.path.exists(OUT) else {}
    todo = [k for k, v in game.items() if isinstance(v, dict) and not k.startswith("_") and k not in known and k not in res]
    only = sys.argv[1:]
    if only:
        todo = [k for k in todo if any(k.startswith(o) or o in k for o in only)]
    print("kontrol edilecek:", len(todo))
    for i, k in enumerate(todo):
        res[k] = dict(check(game[k].get("name", k), k), name=game[k].get("name", k), learn=game[k].get("learn", ""))
        if i % 10 == 0:
            io.open(OUT, "w", encoding="utf-8").write(json.dumps(res, ensure_ascii=False, indent=1))
            print(i, k, res[k]["canon"], flush=True)
    io.open(OUT, "w", encoding="utf-8").write(json.dumps(res, ensure_ascii=False, indent=1))
    print("bitti", sum(1 for v in res.values() if v["canon"]), "kanon /", len(res))


if __name__ == "__main__":
    main()
