"""Reject incomplete or resized benchmark captures before comparing FPS."""
from PIL import Image
import sys
images = [Image.open(path).convert('RGB') for path in sys.argv[1:]]
assert len(images) == 2
assert images[0].size == images[1].size, 'Window dimensions changed between runs'
for image in images:
    assert any(high - low > 64 for low, high in image.getextrema()), 'Blank render capture'
print('PASS: nonblank benchmark captures at matching resolution', images[0].size)
