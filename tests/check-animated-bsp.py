"""Compare the static-camera BSP surface region, excluding animated UI elements."""
from pathlib import Path
import sys
from PIL import Image, ImageChops, ImageStat
root=Path(sys.argv[1])
a=Image.open(root/'build-bsp.png').convert('RGB').crop((200,230,800,650))
b=Image.open(root/'build-bsp-animated.png').convert('RGB').crop((200,230,800,650))
mean=sum(ImageStat.Stat(ImageChops.difference(a,b)).mean)/3
assert mean>3, f'BSP shader stayed static: mean difference {mean}'
print(f'PASS: shader animation with a stationary camera; pixel difference {mean:.2f}')
