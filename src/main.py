import sys
import os
import random
from ursina import Ursina, window, mouse, application, Entity, Vec3, invoke, color

from naruto import build_info

app = Ursina(title=f'Shinobi Yolu - Konoha  v{build_info.VERSION}' + (' [TEST]' if build_info.BUILD == 'test' else ''),
             development_mode=False, borderless=False, vsync=True)
window.color = color.black
window.fps_counter.enabled = build_info.BUILD != 'main'
window.exit_button.enabled = False

# Ctrl basılıyken 'control-w' gibi birleşik tuşlar oluşmasın (Ctrl = zıplama)
from panda3d.core import ModifierButtons
application.base.mouseWatcherNode.set_modifier_buttons(ModifierButtons())
application.base.buttonThrowers[0].node().set_modifier_buttons(ModifierButtons())

from naruto import state
from naruto.world import World
from naruto.player import Player
from naruto.actors import TrainingDummy, Villager
from naruto.hud import HUD

world = World()
player = Player(world.spawn)
hud = HUD()
for p in world.dummy_spots:
    TrainingDummy(p)
for _ in range(18):
    Villager(random.choice(world.road_points) + Vec3(random.uniform(-2, 2), 0, 0))

mouse.locked = True
hud.message('Konoha\'ya hoş geldin, genin! ESC: kontroller', '#ffd08a', 6)


class Controls(Entity):
    def input(self, key):
        if key == 'escape':
            hud.toggle_pause()
        elif key == 'q' and application.paused:
            application.quit()

    def update(self):
        state.world.phys.separate_bodies()


Controls()

# otomatik test: ekran görüntüsü alıp kapanır
if '--shot' in sys.argv:
    out = sys.argv[sys.argv.index('--shot') + 1]
    script = sys.argv[sys.argv.index('--shot') + 2] if len(sys.argv) > sys.argv.index('--shot') + 2 else ''

    def shot(name):
        from panda3d.core import Filename
        application.base.win.saveScreenshot(Filename.fromOsSpecific(os.path.join(out, name + '.png')))

    exec(open(script, encoding='utf8').read()) if script else None
    if not script:
        invoke(shot, 'main', delay=3)
        invoke(application.quit, delay=3.5)

app.run()
