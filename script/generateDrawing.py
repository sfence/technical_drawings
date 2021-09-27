#!/bin/python

import sys
from PIL import Image

if (len(sys.argv)!=3) and (len(sys.argv)!=4):
  print("Usage: generateDrawing.py picture_file output_file [ignore_color]")
  exit();

img = Image.open(sys.argv[1]);
rgb = img.convert("RGB");
width, height = rgb.size

if width!=height:
  print("Input picture is not square. Cannot be protected.")
  exit();

# ignor black by default
ignore_color = "000000"
if (len(sys.argv)==4):
  ignore_color = sys.argv[3]
print("Use ignore color: #{}".format(ignore_color))

drawing = "return {\n"
palette = {}
next_index = 1

palette[ignore_color] = 0

drawing = "{}  res = {},\n".format(drawing, height)
drawing = "{}  grid = {{\n".format(drawing)
for y in range(height):
  drawing = "{}    {{".format(drawing)
  for x in range(width):
    color = rgb.getpixel((x,y));
    color = "{0:02X}{1:02X}{2:02X}".format(color[0], color[1], color[2])
    if not color in palette:
      palette[color] = next_index
      next_index = next_index + 1
    index = palette[color];
    drawing = "{}{},".format(drawing, index)
  drawing = "{}}},\n".format(drawing)

drawing = "{}  }}\n".format(drawing)
drawing = "{}}}\n".format(drawing)

output_file = open(sys.argv[2], "w");
output_file.write(drawing);
output_file.close();

