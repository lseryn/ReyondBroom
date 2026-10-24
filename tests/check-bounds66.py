"""Check blue group bounds are hidden by an opaque foreground brush."""
from pathlib import Path
import sys
from PIL import Image
root=Path(sys.argv[1])
counts=[]
for name in ('covered','exposed'):
    image=Image.open(root/f'bounds66-{name}.png').convert('RGB').crop((3,240,780,750))
    pixels=image.get_flattened_data() if hasattr(image,'get_flattened_data') else image.getdata()
    counts.append(sum(b>60 and b>r*1.6 and b>g*1.3 for r,g,b in pixels))
assert counts[0] < 5, ('Bounds visible through wall',counts)
assert counts[1] > 40, ('Exposed bounds missing',counts)
print('PASS: group bounds depth occlusion; covered/exposed blue pixels:',counts)
