"""Generate the native catalog and OFL CJK subset (requires fonttools==4.60.1)."""
from pathlib import Path
import argparse, hashlib, json
from fontTools import subset
from fontTools.ttLib import TTFont

parser=argparse.ArgumentParser()
parser.add_argument('--font',type=Path,required=True,help='Pinned NotoSansCJKjp-Regular.otf; see runtime/fonts/README.md')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
assert hashlib.sha256(args.font.read_bytes()).hexdigest()=='68a3fc98800b2a27b371f2fb79991daf3633bd89309d4ffaa6946fd587f375b5'
rows=[line.split('|') for line in (root/'localization/ui.tsv').read_text(encoding='utf-8').splitlines() if line]
assert all(len(row)==7 and all(row) for row in rows)
assert len({row[0] for row in rows})==len(rows),'Duplicate English key'
(root/'native/ftebroom_translations.inc').write_text('\n'.join('{'+','.join(json.dumps(value,ensure_ascii=False) for value in row)+'},' for row in rows)+'\n',encoding='utf-8')
font=TTFont(args.font)
options=subset.Options()
options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*']
worker=subset.Subsetter(options=options)
worker.populate(text=''.join(value for row in rows for value in row)+'EnglishРусскийDeutschFrançais简体中文日本語Español')
worker.subset(font)
names={1:'FTEBroom CJK',2:'Regular',3:'FTEBroom-CJK-Subset',4:'FTEBroom CJK Regular',6:'FTEBroom-CJK-Regular',16:'FTEBroom CJK',17:'Regular'}
for entry in font['name'].names:
    if entry.nameID in names: entry.string=names[entry.nameID].encode(entry.getEncoding())
font.save(root/'runtime/fonts/FTEBroom-CJK.otf')
print(f'Generated {len(rows)} localized labels and CJK subset')
