from PIL import Image

def generate_arena_ram_mem(image_path, output_path):
    # Open the image
    img = Image.open(image_path).convert("RGB")
    width, height = img.size
    red_pixel_count = 0

    # Create a list for memory values
    mem_contents = []

    # Process each pixel
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            if r > 200 and g < 35 and b < 35:  # Check if the pixel is red (ff0000)
                red_pixel_count += 1

                # Encode the (x, y) position into a 32-bit value
                value = (x << 9) | y
                mem_contents.append(value)

    # Write the contents to a `.mem` file
    with open(output_path, "w") as mem_file:
        for value in mem_contents:
            mem_file.write(f"{value:08x}\n")  # Write each value as an 8-digit hexadecimal

    print(f"Generated .mem file with {red_pixel_count} red pixels.")

if __name__ == "__main__":
    # Replace 'your_image.jpg' with the path to your image file
    image_path = "../png_files/redPent.jpg"
    output_path = "arena_ram_init.mem"
    
    generate_arena_ram_mem(image_path, output_path)
    print(f"Memory initialization file saved to {output_path}")