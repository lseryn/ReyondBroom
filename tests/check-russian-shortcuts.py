"""Compile the actual X11 layout fallback and check legacy/Unicode keysyms."""
from pathlib import Path
import subprocess,sys,tempfile,re
root=Path(sys.argv[1]);cc=sys.argv[2] if len(sys.argv)>2 else 'cc'
s=(root/'engine/gl/gl_vidlinuxglx.c').read_text(encoding='utf-8')
start=s.index('static int X11_RussianShortcut(');end=s.index('\nstatic void X_KeyEvent',start);function=s[start:end]
assert 'key = X11_RussianShortcut(keysym);' in s
assert 'IN_KeyEvent(0, pressed, key, unichar[i]);' in s
# Independent expected mappings from standard Russian and US keyboard rows.
letters='ёйцукенгшщзхъфывапролджэячсмитьбю'
keys="`qwertyuiop[]asdfghjkl;'zxcvbnm,."
headers=[Path('/usr/include/X11/keysymdef.h'),Path('C:/msys64/mingw64/include/X11/keysymdef.h')]
defs=next(p for p in headers if p.is_file()).read_text(encoding='utf-8')
checks=[]
for letter,key in zip(letters,keys):
 for char in (letter,letter.upper()):
  symbol=re.search(r'#define XK_\w+\s+(0x\w+)\s+/\* U\+'+f'{ord(char):04X}'+r'\b',defs).group(1)
  checks.append(f'assert(X11_RussianShortcut({symbol})=={ord(key)});')
  checks.append(f'assert(X11_RussianShortcut(0x{0x1000000|ord(char):08x})=={ord(key)});')
checks += ['assert(X11_RussianShortcut(0)==0);','assert(X11_RussianShortcut(0xffe3)==0);','assert(X11_RussianShortcut(0x01004e00)==0);','assert(X11_RussianShortcut(97)==0);']
with tempfile.TemporaryDirectory(prefix='ftebroom-layout-') as directory:
 p=Path(directory);source=p/'test.c';binary=p/'test.exe'
 source.write_text('#include <assert.h>\n#include <stdio.h>\n'+function+'\nint main(void){'+''.join(checks)+'puts("PASS: 132 Russian keysyms, modifier/Latin/CJK isolation; IME text path preserved");}\n',encoding='utf-8')
 subprocess.run([cc,'-std=c99','-Wall','-Wextra','-Werror',str(source),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True,timeout=10)
