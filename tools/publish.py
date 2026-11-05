"""Ana exe'yi GitHub'a yayınlar (build.py main sonunda otomatik çağrılır; elle: python tools/publish.py).
  - Kaynak kod  -> serpetian-spec/shinobi-yolu        (private)  git push
  - Exe sürümü  -> serpetian-spec/shinobi-yolu-surum  (public)   release vX.Y.Z + ShinobiYolu.exe
Arkadaşın oyunu açılışta public sürüm reposuna bakar ve kendini günceller (godot/scripts/core/updater.gd).
gh girişi yoksa sessizce atlar.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GH = os.path.join(ROOT, 'tools', 'ext', 'gh', 'bin', 'gh.exe')
OWNER = 'serpetian-spec'
SRC = OWNER + '/shinobi-yolu'
REL = OWNER + '/shinobi-yolu-surum'
EXE = os.path.join(ROOT, 'Oyun', 'ShinobiYolu.exe')


def gh(*args, check=False):
    return subprocess.run([GH, *args], capture_output=True, text=True, encoding='utf-8', errors='replace', check=check)


def git(*args):
    return subprocess.run(['git', *args], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')


def ensure_repos():
    if gh('repo', 'view', SRC).returncode != 0:
        gh('repo', 'create', SRC, '--private', '--description', 'Shinobi Yolu - açık dünya ninja aksiyon RPG (Godot 4)', check=True)
        print('repo açıldı:', SRC)
    if gh('repo', 'view', REL).returncode != 0:
        gh('repo', 'create', REL, '--public', '--add-readme', '--description', 'Shinobi Yolu oyun sürümleri: Releases kısmından ShinobiYolu.exe indir. Oyun açılışta buradan kendini günceller.', check=True)
        print('repo açıldı:', REL)


def main():
    if not os.path.exists(GH) or gh('auth', 'status').returncode != 0:
        print('GitHub: gh girişi yok, yayın atlandı')
        return
    version = open(os.path.join(ROOT, 'VERSION')).read().strip()
    ensure_repos()
    # kaynak kod
    url = 'https://github.com/%s.git' % SRC
    if git('remote', 'get-url', 'origin').returncode != 0:
        git('remote', 'add', 'origin', url)
    r = git('push', 'origin', 'HEAD:main')
    print('GitHub kod:', 'gönderildi' if r.returncode == 0 else 'HATA ' + r.stderr.strip()[-300:])
    # exe sürümü
    tag = 'v' + version
    if gh('release', 'view', tag, '--repo', REL).returncode == 0:
        print('GitHub sürüm: %s zaten var' % tag)
        return
    notes = git('log', '-1', '--format=%B').stdout.strip()
    notes = '\n'.join(l for l in notes.splitlines() if not l.startswith('Co-Authored-By'))
    r = gh('release', 'create', tag, EXE, '--repo', REL, '--title', 'Shinobi Yolu ' + tag, '--notes', notes or tag)
    print('GitHub sürüm:', ('yayınlandı ' + r.stdout.strip()) if r.returncode == 0 else 'HATA ' + r.stderr.strip()[-300:])


if __name__ == '__main__':
    main()
