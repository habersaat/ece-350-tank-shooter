# Use image processing package
import os
import csv
import sys

try:
    from PIL import Image
except ImportError:
    response = input("This script requires the image processing package, Pillow. \nWould you like to download it? (y/n) ")
    if response.strip().lower() == "y":
        os.system("pip3 install pillow")
    else:
        sys.exit()

if len(sys.argv) != 2:
    print("Usage: PictoCSV.py FileName.jpg")
    sys.exit()

imageName = sys.argv[1]
path = ""

# Open the image
file = Image.open(imageName)

# Quantize image to 256 colors
img = file.quantize(256)
pixels = img.load()

# Convert the palette to RGB444
pal = img.getpalette()  # Get palette in 8-bit per channel
colors = []
for i in range(0, len(pal), 3):
    r_4bit = pal[i] >> 4
    g_4bit = pal[i + 1] >> 4
    b_4bit = pal[i + 2] >> 4
    colors.append(f"{r_4bit:X}{g_4bit:X}{b_4bit:X}")

# Write the palette to a CSV file
with open(path + "colors.csv", "w") as csvFile:
    writer = csv.writer(csvFile)
    for n in range(0, len(colors), 8):
        writer.writerow(colors[n:n + 8])

# Write the image pixel data to a CSV file
with open(path + "image.csv", "w") as csvFile:
    writer = csv.writer(csvFile)
    for y in range(img.size[1]):
        row = []
        for x in range(img.size[0]):
            # Get the palette index for the pixel and use the corresponding RGB444 color
            row.append(colors[pixels[x, y]])
        writer.writerow(row)