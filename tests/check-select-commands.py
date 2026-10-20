from pathlib import Path
import sys,re
p=Path(sys.argv[1]);log=(p/'qconsole.log').read_text(errors='replace')
assert 'FTEBROOM_SELECT_COMMAND_FAIL' not in log,log
names=re.findall(r'fb_select_expect\(.*?,"([a-z0-9_]+)"\);',(Path(__file__).parents[1]/'qc/fb_select_commands_tests.qc').read_text())
for name in names: assert 'FTEBROOM_SELECT_COMMAND_PASS '+name in log,name
assert len(names)>=12
print('PASS:',len(names),'selection command checks')
