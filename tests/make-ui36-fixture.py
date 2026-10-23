"""Private UI and audio fixtures; no user mod files are modified."""
from pathlib import Path
import sys, math, wave, struct

root = Path(sys.argv[1]).resolve()
sound = root / 'mod/sound'
sound.mkdir(parents=True)
with wave.open(str(sound / 'test.wav'), 'wb') as output:
    output.setparams((2, 2, 44100, 0, 'NONE', 'not compressed'))
    output.writeframes(b''.join(struct.pack('<hh', *(int(12000*math.sin(2*math.pi*440*i/44100)),)*2) for i in range(88200)))
(sound / 'original.bin').write_bytes((sound / 'test.wav').read_bytes())
(root/'editor/ftebroom/ui36.cfg').write_text(f'''exec ftebroom.cfg
set ftebroom_skip_setup 1
set ftebroom_test_import_root "{(root/'mod').as_posix()}"
in 7 ftebroom_test_desktop ui36
in 9 screenshot retro-dark36.png
in 10 ftebroom_test_desktop light36
in 12 screenshot modern-light36.png
in 13 ftebroom_test_desktop audio36open
in 16 screenshot sound36.png
in 17 ftebroom_test_desktop audio36save
in 23 ftebroom_test_desktop audio36check
in 24 ftebroom_test_desktop maps36
in 26 quit force
''', encoding='utf-8')
