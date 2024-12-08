from PIL import Image

def generate_arena_ram_mem(image_path, mem_output_path, image_output_path):
    # Open the image
    img = Image.open(image_path).convert("RGB")
    width, height = img.size
    red_pixel_count = 0

    # Create a new black image to mark red pixels
    output_img = Image.new("RGB", (width, height), (0, 0, 0))
    output_pixels = output_img.load()

    # Create a list for memory values
    mem_contents = []

    # Process each pixel
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            if r > 200 and g < 15 and b < 15:  # Check if the pixel is red (ff0000)
                red_pixel_count += 1

                # Encode the (x, y) position into a 32-bit value
                value = (x << 9) | y
                mem_contents.append(value)

                # Mark the red pixel in the output image
                output_pixels[x, y] = (255, 255, 255, 255)  # Highlight white red in the new image

                # make the opaqueness of the red pixel 50%


    # Write the contents to a `.mem` file
    with open(mem_output_path, "w") as mem_file:
        for value in mem_contents:
            mem_file.write(f"{value:08x}\n")  # Write each value as an 8-digit hexadecimal

    # Save the output image
    output_img.save(image_output_path)

    print(f"Generated .mem file with {red_pixel_count} red pixels.")
    print(f"Image with highlighted red pixels saved to {image_output_path}")

if __name__ == "__main__":
    # Replace these paths with your own
    image_path = "../png_files/redPent.jpg"
    mem_output_path = "../CPU/arena_ram_init.mem"
    image_output_path = "../png_files/red_pixels_marked.jpg"
    
    generate_arena_ram_mem(image_path, mem_output_path, image_output_path)
    print(f"Memory initialization file saved to {mem_output_path}")
