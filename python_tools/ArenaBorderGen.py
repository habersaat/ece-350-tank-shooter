from PIL import Image

def find_red_pixels(image_path, output_path):
    # Open the image
    img = Image.open(image_path).convert("RGB")
    width, height = img.size
    red_pixel_locations = []
    red_pixel_count = 0

    # Create a new black image to write the red pixels
    red_image = Image.new("RGB", (width, height), (0, 0, 0))
    red_pixels = red_image.load()
    offset = 0
    instructions = []

    # Process each pixel
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            if r > 200 and g < 35 and b < 35:  # Check if the pixel is red (ff0000)
                red_pixel_locations.append((x, y))
                red_pixel_count += 1
                red_pixels[x, y] = (255, 0, 0)  # Set red pixels in the new image

                # Create an instruction to write the x value to $r10
                instruction1 = "addi $r10, $r0, " + str(x)
                instructions.append(instruction1)

                # Create an instruction to left shift $r10 by 9
                instruction2 = "sll $r10, $r10, 9"
                instructions.append(instruction2)

                # Write the y value to $r11
                instruction3 = "addi $r11, $r0, " + str(y)
                instructions.append(instruction3)

                # Create an instruction to write the y value to $10 by using "or"
                instruction4 = "or $r10, $r10, $r11"
                instructions.append(instruction4)

                # Write the value of $r10 to the memory location offset
                instruction5 = "sw $r10, " + str(offset) + "($r28)"
                instructions.append(instruction5)
                offset += 1

    # Write the instructions to a file
    with open("instructions.txt", "w") as f:
        for instruction in instructions:
            f.write(instruction + "\n")

    # Save the output image
    red_image.save(output_path)
    return red_pixel_locations, red_pixel_count

if __name__ == "__main__":
    # Replace 'your_image.jpg' with the path to your image file
    image_path = "../png_files/redPent.jpg"
    output_path = "../png_files/red_pixels_only.jpg"
    
    red_pixels, count = find_red_pixels(image_path, output_path)
    print(f"Total red pixels: {count}")
    print(f"Red-only image saved to {output_path}")