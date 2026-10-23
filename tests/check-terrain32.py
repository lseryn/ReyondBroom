from pathlib import Path
import sys, runpy, re, math
root=Path(sys.argv[1]);geometry=runpy.run_path('tests/check-map-roundtrip.py')['geometry']
a,ca,pa=geometry(root/'mod/maps/combined.map');b,cb,pb=geometry(root/'mod/maps/saved-combined.map')
assert len(a)==len(b) and ca==cb and pa==pb and pa, 'Existing map objects lost'
for before,after in zip(a,b):
 assert len(before)==len(after)
 for n,d in before:
  normal,dist=min(after,key=lambda p:math.dist(p[0],n))
  assert math.dist(n,normal)<1e-6 and abs(d-dist)<.005
text=(root/'mod/maps/saved-combined.map').read_text()
for name in ['_segmentsize','_minxsegment','_maxxsegment','_minysegment','_maxysegment']:
 assert text.count('"'+name+'"')==1, 'Duplicated terrain bounds'
print('PASS: existing brushes, patches and entities survive terrain creation and repeated saves')
