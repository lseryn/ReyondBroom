"""Configure a disposable editor installation for real AD/LibreQuake switch tests."""
from pathlib import Path
import sys
editor, ad, libre = map(lambda p: Path(p).resolve(), sys.argv[1:])
for mod in (ad, libre):
    if not (mod / "pak0.pak").is_file():
        raise SystemExit(f"Missing mod archive: {mod}")
(editor / "ftebroom-project.txt").write_text(ad.as_posix(), encoding="utf-8")
(editor / "ftebroom-game-profile.txt").write_text('2 0 "" "" "" "" 1 0 ""\n')
(editor / "ftebroom-quake1.txt").write_text(f'"" "{ad.as_posix()}" "" "" 1 0 "" 0\n')
commands = ['set ftebroom_skip_setup 1', 'exec ftebroom.cfg', 'in 5 ftebroom_test_model_registry']
for i, mod in enumerate((ad, libre) * 3):
    t = 8 + i * 12
    commands += [f'in {t} set ftebroom_test_import_root "{mod.as_posix()}"',
                 f'in {t+1} ftebroom_test_desktop mods63load',
                 f'in {t+4} ftebroom_test_desktop mods63check',
                 f'in {t+8} ftebroom_test_desktop mods63model',
                 f'in {t+9} screenshot mods63-{i}.png']
commands += ['in 82 ftebroom_test_model_registry', 'in 84 quit force']
(editor / 'ftebroom/mods63.cfg').write_text('\n'.join(commands) + '\n', encoding='utf-8')
