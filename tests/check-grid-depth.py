"""Check that a distant wall grid does not bleed over a nearer pillar."""
from pathlib import Path
from PIL import Image
import sys

root = Path(sys.argv[1])
image = Image.open(root / "grid-depth.png").convert("RGB")
# The 640x480 fixture puts the blue pillar in the centre of the 3D viewport.
pixels = list(image.crop((120, 280, 210, 380)).getdata())
blue = sum(b > 100 and b > r * 1.3 and b > g * 1.2 for r, g, b in pixels)
assert blue > 280, f"distant grid covers the near pillar: only {blue} blue pixels"
print(f"PASS: {blue} unobstructed pillar pixels")
