"""Check rendered thumbnail colors, not merely successful model/image handles."""
from PIL import Image
import sys

image = Image.open(sys.argv[1]).convert('RGB')
# Entity thumbnails occupy the inspector on the right in the fixture layout.
pixels = list(image.crop((920, 140, 1270, 600)).getdata())
colors = {
    'MD3 red surface': lambda r, g, b: r > 150 and g < 70 and b < 90,
    'MD3 green surface': lambda r, g, b: g > 150 and r < 70 and b < 100,
    'MDL yellow skin': lambda r, g, b: r > 130 and g > 130 and b < 100,
    'MDL blue skin': lambda r, g, b: b > 130 and r < 100 and g < 100,
}
for label, match in colors.items():
    count = sum(match(*pixel) for pixel in pixels)
    assert count > 30, (label, count)
    print('PASS:', label, count, 'pixels')
