"""GDScript'ten fonksiyon / PANIM-PSTYLE anahtarı / json kaydı silme yardımcıları (klan kanon geçişleri için)."""
import io, json, re


def read(p):
    s = io.open(p, encoding='utf-8', newline='').read()
    return s, ('\r\n' if '\r\n' in s else '\n')


def write(p, s):
    io.open(p, 'w', encoding='utf-8', newline='').write(s)


def remove_funcs(p, names):
    """Üst düzey 'func NAME(' bloklarını, hemen üstündeki ## açıklama satırlarıyla birlikte siler."""
    s, nl = read(p)
    L = s.split(nl)
    out = []
    i = 0
    removed = []
    while i < len(L):
        m = re.match(r'^(static )?func ([A-Za-z0-9_]+)\(', L[i])
        if m and m.group(2) in names:
            # üstteki açıklama satırlarını geri al
            while out and out[-1].startswith('##'):
                out.pop()
            j = i + 1
            while j < len(L) and (L[j] == '' or L[j].startswith('\t') or L[j].startswith(' ')):
                j += 1
            # sondaki boş satırları koru (bir sonraki blokla aradaki boşluk)
            k = j
            while k > i + 1 and L[k - 1] == '':
                k -= 1
            removed.append(m.group(2))
            i = j
            # fazla boş satırı sınırla
            while out and out[-1] == '' and len(out) > 1 and out[-2] == '':
                out.pop()
            continue
        out.append(L[i])
        i += 1
    write(p, nl.join(out))
    return removed


def remove_dict_lines(p, ids):
    """PANIM gibi '"id": {...}' tek satırlık girişleri siler; PSTYLE gibi '"id": "stil",' satır içi anahtarları çıkarır."""
    s, nl = read(p)
    out = []
    for l in s.split(nl):
        st = l.lstrip()
        if any(st.startswith('"%s": {' % i) for i in ids):
            continue
        for i in ids:
            l = re.sub(r'"%s": "[^"]*", ?' % re.escape(i), '', l)
        out.append(l)
    write(p, nl.join(out))


def remove_json(p, ids, crlf=True):
    s, nl = read(p)
    if p.endswith('balance.json'):
        s = nl.join(l for l in s.split(nl) if not any(l.startswith('"%s":' % i) for i in ids))
    else:
        for i in ids:
            m = re.search(r'%s "%s": \{.*?%s \}(,?)' % (re.escape(nl), re.escape(i), re.escape(nl)), s, re.S)
            if m:
                s = s[:m.start()] + s[m.end():]
    json.loads(s)
    write(p, s)


def set_fields(p, jid, kv):
    s, nl = read(p)
    m = re.search(r'(%s "%s": \{)(.*?)(%s \})' % (re.escape(nl), re.escape(jid), re.escape(nl)), s, re.S)
    body = m.group(2)
    for k, v in kv.items():
        mm = re.search(r'(%s  "%s": )([^\r\n]*?)(,?)(?=%s)' % (re.escape(nl), k, re.escape(nl)), body)
        assert mm, (jid, k)
        body = body[:mm.start()] + mm.group(1) + json.dumps(v, ensure_ascii=False) + mm.group(3) + body[mm.end():]
    s = s[:m.start()] + m.group(1) + body + m.group(3) + s[m.end():]
    json.loads(s)
    write(p, s)


def add_aliases(p, pairs):
    s, nl = read(p)
    a = nl + ' "_aliases": {'
    i = s.index(a) + len(a)
    s = s[:i] + ''.join('%s  "%s": "%s",' % (nl, k, v) for k, v in pairs.items()) + s[i:]
    json.loads(s)
    write(p, s)
